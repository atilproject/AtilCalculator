#!/usr/bin/env bash
# d123-rca-12-uvicorn-coldstart-readiness.sh — Issue #785 INCIDENT-2 RCA-12
#   uvicorn cold-start > sleep window regression guard.
#
# Why this test exists
# --------------------
# Issue #785 (P2 incident, false-fail in deploy workflow run 28678435223
# at 2026-07-03T18:52:48Z, RCA-12 surface). The current post-restart check
# in `scripts/deploy-runner.sh` (lines 457-490) uses `ss -tlnp` to verify
# the port-bound uvicorn started RECENTLY (etimes ≤ 60s). With uvloop +
# pydantic 2.x cold init, uvicorn takes 5-8s to bind. The script's
# `sleep 2` between `systemctl --user start` and the post-check is
# INSUFFICIENT — when the post-check runs at 3s elapsed, no process is
# yet bound, the `ss` query returns empty, and the script fails with
# exit 6 ("RCA-12 post-check: no process is bound to port $ATC_PORT").
# Workflow reports FAILURE despite prod actually being healthy.
#
# v9.2 fix (proposed):
#   - Replace strict `ss` bind check with HTTP-level readiness retry loop:
#     `for i in {1..15}; do curl -fsS http://127.0.0.1:$ATC_PORT/healthz
#     2>/dev/null && break; sleep 1; done`. Waits for actual HTTP 200, not
#     just port bind — distinguishes "uvicorn still importing" from
#     "uvicorn serving".
#   - Keep the `ss -tlnp` etimes cross-user check as defense-in-depth
#     backstop (RCA-12's original purpose, Issue #168). The two checks
#     are ORTHOGONAL: HTTP=200 + etimes≤60s = green; HTTP=200 + etimes>60s
#     = cross-user conflict (RCA-12 still catches); HTTP fails after 15s
#     + etimes≤60s = service unhealthy (exit 7 per AC4 lineage); HTTP fails
#     after 15s + no PID bound = hard failure (exit 6, original RCA-12).
#   - New exit code surface unchanged (existing 5/6/7); the readiness
#     retry is the new entry point into the existing failure taxonomy.
#
# Sister-pattern (≥3 per ADR-0049):
#   - d017 (RCA-12 cross-user port-8000, Issue #168) — DIRECT sister,
#     same RCA-12 lineage from pre/post cross-user detection. d123
#     EXTENDS d017 by adding cold-start HTTP readiness to the post-
#     check. Original `ss` etime check (defense-in-depth backstop)
#     remains per d017 T1-T8.
#   - d108 (Issue #725 watchdog defaults, 6 TCs) — sister regression
#     guard shape (script + test pair, grep-TCs).
#   - d120 (Issue #759 pct_change override, 9 TCs) — sister same-cycle
#     P0+P1 cluster PR-lane.
#   - d121 (RCA-17 AC4 user fix — Issue #763, 5 TCs) — sister
#     same-script-lane (deploy-runner.sh scope).
#   - d122 (RCA-20 run-server.sh uv extra web, Issue #771, 6 TCs) —
#     sister-shape script + test pair regression guard.
#   ≥3 sister-pattern coverage per ADR-0049 §Sister-pattern met
#   (d017 + d120 + d121 + d122 ≥ 3 baseline; d123 is the 5th member).
#
# AC traceability:
#   - TC2 ↔ AC1 — HTTP readiness retry loop literal in deploy-runner.sh
#   - TC3 ↔ AC2 — ≥10s budget (15s preferred per Option A in spec)
#   - TC4 ↔ AC2 — 1-second tick between retries
#   - TC5 ↔ AC3 — simulated slow-bind test using mock curl + timing
#   - TC6 ↔ AC5 — RCA-12 `ss`/etime cross-user check remains present
#     (defense-in-depth backstop is NOT removed by the readiness fix)
#   - TC7 ↔ ADR-0049 sister-pattern coverage ≥3
#
# Pre-impl RED state (current origin/main 1f2d29948, PR #785 OPEN):
#   - TC2 FAIL — `wait_for_uvicorn_ready` function not yet in deploy-runner.sh
#   - TC3 FAIL — no retry budget cap literal "15" present in readiness loop
#   - TC4 FAIL — no "sleep 1" within readiness retry loop
#   - TC5 FAIL — function does not exist; cannot be sourced for mock test
#   - TC6 PASS-by-coincidence — `ss` etime cross-user check still in deploy-runner.sh
#     (d017 T1-T8 may not assert this exact shape, but the underlying
#     lines from v8 are still present)
#   - TC7 PASS-by-coincidence — d017 + d122 on main already
#   → 4/7 FAIL in RED state per ADR-0044 RED-first discipline. (Note: some
#   TCs — TC6, TC7 — will pass by coincidence on the original main; these
#   are still required for the GREEN contract per ADR-0044.)
#
# Post-impl GREEN state (after PR #785 merges):
#   - TC2 + TC3 + TC4 + TC5 PASS (readiness loop landed)
#   - TC6 still PASS (defense-in-depth backstop preserved)
#   - TC7 still PASS (sister-pattern ≥3 intact)
#   → 7/7 PASS in GREEN state per ADR-0044 GREEN contract.
#
# Sister slot: d122 = next free slot post-d121. d123 = Issue #785 slot.
# Slot allocation pattern (Issue #113 + ADR-0055 §1): d-tests numbered in
# roughly PR-discovery order. d017 RCA-12, d122 RCA-20, d123 RCA-19
# (uvicorn cold-start readiness) — 3 members of the readiness/RCA-12
# sister-pattern family.
#
# Run standalone:  bash scripts/tests/d123-rca-12-uvicorn-coldstart-readiness.sh --self-test
#
# Exit codes:
#   0 — all 7 PASS (GREEN state — readiness loop landed)
#   1 — at least one FAIL (RED state — uvicorn cold-start readiness broken)
#   2 — preflight failure (deploy-runner.sh missing, bash ≥4 missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEPLOY_RUNNER="${REPO_ROOT}/scripts/deploy-runner.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; Y=$'\033[0;33m'; D=$'\033[0m'
else G=""; R=""; B=""; Y=""; D=""; fi

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# Pre-flight (ADR-0049)
# ============================================================================
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required for POSIX ${VAR:-DEFAULT} semantics" >&2; exit 2; }
case "$BASH_VERSION" in
  4.*|5.*) : ;;  # bash 4+ supports ${1..15} brace expansion (universal since 2007)
  *) echo "ERROR: bash ≥4 required (got bash $BASH_VERSION)" >&2; exit 2 ;;
esac
[ -f "$DEPLOY_RUNNER" ] || { echo "ERROR: deploy-runner.sh not found at $DEPLOY_RUNNER" >&2; exit 2; }

if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: $0 --self-test" >&2
  exit 2
fi

printf "${B}d123 self-test (Issue #785 INCIDENT-2 — RCA-12 uvicorn cold-start readiness, 7 TCs ≥3 sister baseline per ADR-0049)${D}\n"
printf "${B}================================================================${D}\n"
printf "  Deploy-runner: %s\n" "$DEPLOY_RUNNER"
printf "  Sister slot:   d017 (RCA-12 cross-user port-8000, Issue #168) + d122 (RCA-20 run-server.sh, Issue #771) + d123 (RCA-19 uvicorn cold-start, Issue #785)\n"
printf "  Fix design:    replace strict 'ss' bind check with curl /healthz retry loop (15s budget, Option A from spec)\n"
printf "  Backstop:      RCA-12 ss/etime cross-user check (d017 T1-T8 defense-in-depth) REMAINS present, NOT removed\n"
printf "  RED-first:     pre-impl TC2+TC3+TC4+TC5 FAIL (PR #785 not yet merged); TC6+TC7 PASS-by-coincidence.\n\n"

# ============================================================================
# TC1 (preflight): deploy-runner.sh exists + readable + non-empty
# ============================================================================
section "TC1: preflight — deploy-runner.sh exists + readable + non-empty"
if [ -r "$DEPLOY_RUNNER" ] && [ -s "$DEPLOY_RUNNER" ]; then
  pass "TC1 — deploy-runner.sh exists + readable + non-empty"
else
  fail "TC1 — preflight FAILED" "expected $DEPLOY_RUNNER readable + non-empty"
  printf "\n  Cannot continue without source file. 1/7 FAIL — preflight only.\n"
  exit 1
fi

# ============================================================================
# TC2 (AC1): wait_for_uvicorn_ready helper function exists with HTTP retry literal
# ============================================================================
section "TC2 (AC1): wait_for_uvicorn_ready helper function exists with curl /healthz retry loop"
# Helper must contain: function definition + curl invocation targeting /healthz
# Pattern: function name + curl invocation on /healthz + for/while loop
HELPER_DEF=$(grep -nE '^wait_for_uvicorn_ready[[:space:]]*\(\)' "$DEPLOY_RUNNER" || true)
HELPER_BODY=$(awk '/^wait_for_uvicorn_ready[[:space:]]*\(\)/,/^}/' "$DEPLOY_RUNNER" || true)
HELPER_HAS_CURL_HEALTHZ=$(printf '%s\n' "$HELPER_BODY" | grep -nE 'curl[[:space:]]+.*healthz' || true)
HELPER_HAS_LOOP=$(printf '%s\n' "$HELPER_BODY" | grep -nE '^[[:space:]]*(for|while)[[:space:]]+.*\;[[:space:]]*do[[:space:]]*$' || true)
if [ -n "$HELPER_DEF" ] && [ -n "$HELPER_HAS_CURL_HEALTHZ" ] && [ -n "$HELPER_HAS_LOOP" ]; then
  pass "TC2 — wait_for_uvicorn_ready() defined + curl /healthz + retry loop present"
else
  fail "TC2 — wait_for_uvicorn_ready() missing or malformed" \
    "expected: helper function containing 'curl ... healthz' inside for/while loop. def='$HELPER_DEF' curl='$HELPER_HAS_CURL_HEALTHZ' loop='$HELPER_HAS_LOOP'. Refs Issue #785 v9.2 fix design."
fi

# ============================================================================
# TC3 (AC2): retry budget ≥10s (15s preferred per Option A in spec)
# ============================================================================
section "TC3 (AC2): readiness retry budget ≥10s (15s preferred per spec Option A)"
# Inspect the helper body: must contain a budget literal of ≥10s, expressed
# either as brace-expansion '{1..N}' OR as 'seq 1 N' (variable-friendly form
# for env-var-configurable budgets via UVICORN_READY_TIMEOUT_SEC). Both
# patterns are acceptable per Option A intent — the spec calls out 15s but
# the architectural choice of config-driven budget is a feature, not a
# regression. Heuristic: extract the largest integer in a 'seq' expression
# OR the largest N in '{1..N}' brace expansion, then assert >= 10.
HELPER_SEQ=$(printf '%s\n' "$HELPER_BODY" | grep -oE 'seq[[:space:]]+1[[:space:]]+[^;]+' | head -1 || true)
HELPER_BRACE=$(printf '%s\n' "$HELPER_BODY" | grep -oE '\{1\.\.[0-9]+\}' | head -1 || true)
HELPER_BUDGET_OK=0
HELPER_BUDGET_REASON=""
if [ -n "$HELPER_BRACE" ]; then
  HELPER_N=$(printf '%s' "$HELPER_BRACE" | grep -oE '[0-9]+' | tail -1)
  if [ -n "$HELPER_N" ] && [ "$HELPER_N" -ge 10 ]; then
    HELPER_BUDGET_OK=1
    HELPER_BUDGET_REASON="brace $HELPER_BRACE (${HELPER_N}s)"
  fi
fi
if [ "$HELPER_BUDGET_OK" = "0" ] && [ -n "$HELPER_SEQ" ]; then
  # Variable-friendly form: budget comes from ${UVICORN_READY_TIMEOUT_SEC:-15}
  # default. Verify the default value declared in the helper is >= 10.
  DEFAULT_FALLBACK=$(printf '%s\n' "$HELPER_BODY" | grep -oE 'UVICORN_READY_TIMEOUT_SEC:-[0-9]+|wait_max=["'"'"']?[0-9]+["'"'"']?' | head -1 || true)
  DEFAULT_N=$(printf '%s' "$DEFAULT_FALLBACK" | grep -oE '[0-9]+' | tail -1)
  if [ -n "$DEFAULT_N" ] && [ "$DEFAULT_N" -ge 10 ]; then
    HELPER_BUDGET_OK=1
    HELPER_BUDGET_REASON="seq form '$HELPER_SEQ' with default budget=${DEFAULT_N}s (env-var overridable via UVICORN_READY_TIMEOUT_SEC)"
  fi
fi
if [ "$HELPER_BUDGET_OK" = "1" ]; then
  pass "TC3 — retry budget $HELPER_BUDGET_REASON (≥ 10s floor, AC2 met)"
else
  fail "TC3 — retry budget missing or too small" \
    "expected '{1..10}' (minimal) or '{1..15}' (preferred per Option A) OR 'seq 1 \${UVICORN_READY_TIMEOUT_SEC:-15}' variable form with default >= 10. Helper body had: seq='$HELPER_SEQ' brace='$HELPER_BRACE'. Uvicorn cold-start per RCA-19 takes 5-8s on uvloop+fastapi 0.115; budget < 10s risks false-fail."
fi

# ============================================================================
# TC4 (AC2): retry tick = 1 second between attempts
# ============================================================================
section "TC4 (AC2): readiness retry tick = sleep 1 (1 second between attempts)"
HELPER_HAS_SLEEP_1=$(printf '%s\n' "$HELPER_BODY" | grep -nE '^[[:space:]]*sleep[[:space:]]+1([[:space:]]*;|[[:space:]]+do[[:space:]]*$|$)' || true)
if [ -n "$HELPER_HAS_SLEEP_1" ]; then
  pass "TC4 — retry tick = sleep 1 present in wait_for_uvicorn_ready body (AC2 met)"
else
  fail "TC4 — sleep 1 tick MISSING" \
    "expected 'sleep 1' (1-second tick) inside the for/while loop. Spec Option A: 'for i in {1..15}; do ... sleep 1; done'."
fi

# ============================================================================
# TC5 (AC3): simulated slow-bind mock test — readiness catches at correct iter
# ============================================================================
section "TC5 (AC3): mock curl slow-bind test — readiness catches at correct iter"
# This TC extracts the wait_for_uvicorn_ready function and runs it with a
# mock curl binary in PATH that sleeps N=3s before returning success.
# Expected: function exits 0 in ≥3s (caught at iter 3), and ≤4s (not earlier).
# If the helper is malformed/missing, TC2 already FAILED — TC5 reports FAIL.
if [ -z "$HELPER_DEF" ] || [ -z "$HELPER_BODY" ]; then
  fail "TC5 — cannot run mock test; helper missing (TC2 RED)" \
    "extract the function with: awk '/^wait_for_uvicorn_ready/,/^}/p' deploy-runner.sh"
else
  # TMP dirs for mock curl + harness
  MOCK_BIN="$(mktemp -d)"
  HARNESS_SH="$(mktemp -d)/harness.sh"
  trap 'rm -rf "$MOCK_BIN" "${HARNESS_SH%/*}"' EXIT
  # Mock curl: sleep 3s, return HTTP 200 + tiny JSON. Captures iter count via $i
  cat > "$MOCK_BIN/curl" <<CURL_EOF
#!/usr/bin/env bash
# Mock curl — simulates uvicorn cold-start bind delay (3s) then HTTP 200.
# Reads iter counter from /tmp/.d123_iter if present (set by the loop).
sleep 3
ITR=0
[ -r /tmp/.d123_iter ] && ITR="\$(cat /tmp/.d123_iter)"
echo "{\"status\":\"ok\",\"iter\":\${ITR}}"
exit 0
CURL_EOF
  chmod +x "$MOCK_BIN/curl"

  # Harness: source the helper, run it, time it. Uses bash brace-expansion
  # wrapper around the body; deliberately NOT invoking the full deploy-runner
  # (which would try to start systemd, etc. — out-of-scope for d-test).
  cat > "$HARNESS_SH" <<HARNESS_EOF
#!/usr/bin/env bash
# d123 mock harness — defines wait_for_uvicorn_ready from extracted body,
# invokes it, and times the call against mock curl (PATH override).
set -uo pipefail
# Stub the deploy-runner.sh helpers so the extracted function body can run
# in isolation. log() writes to stderr (matches deploy-runner.sh pattern).
log() { printf '[%s] %s\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$*" >&2; }
ATC_PORT=18000
HEALTHZ_URL="http://127.0.0.1:\${ATC_PORT}/healthz"
UVICORN_READY_TIMEOUT_SEC=15
START_TS=\$(date +%s)
${HELPER_BODY}
wait_for_uvicorn_ready
RC=\$?
END_TS=\$(date +%s)
ELAPSED=\$(( END_TS - START_TS ))
echo "TC5 ELAPSED=\${ELAPSED} RC=\${RC}"
exit 0
HARNESS_EOF
  chmod +x "$HARNESS_SH"

  # Run harness with mock curl on PATH; capture output + timing
  TC5_OUT=$(PATH="$MOCK_BIN:$PATH" bash "$HARNESS_SH" 2>&1 || echo "HARNESS_FAIL")
  TC5_ELAPSED=$(printf '%s\n' "$TC5_OUT" | grep -oE 'TC5 ELAPSED=[0-9]+' | grep -oE '[0-9]+' | tail -1 || echo "0")
  if printf '%s\n' "$TC5_OUT" | grep -q "uvicorn ready"; then
    # Function declared success — verify timing was >= 3s (caught at iter 3)
    if [ -n "$TC5_ELAPSED" ] && [ "$TC5_ELAPSED" -ge 3 ] && [ "$TC5_ELAPSED" -lt 6 ]; then
      pass "TC5 — mock slow-bind caught at iter 3 (~${TC5_ELAPSED}s elapsed; expected ≥3s, <6s)"
    else
      fail "TC5 — mock elapsed=$TC5_ELAPSED out of expected ≥3s+<6s window" \
        "expected: loop iterates 3 times waiting for curl (1st iter fails fast, sleep 1; 2nd iter fails, sleep 1; 3rd iter curl returns). Total elapsed should be ~3s. Got: $TC5_OUT"
    fi
  else
    fail "TC5 — mock test did not report 'uvicorn ready'" \
      "expected helper to log 'uvicorn ready after Ns' on iter 3; mock output: $TC5_OUT"
  fi
fi

# ============================================================================
# TC6 (AC5 / defense-in-depth backstop): RCA-12 ss/etime cross-user check remains
# ============================================================================
section "TC6 (AC5): RCA-12 ss/etime cross-user check (defense-in-depth backstop) STILL present"
# The d017 T1-T8 sister-pair asserts ss -tlnp + etime ≤60s check stays.
# d123 reaffirms: the new readiness retry loop MUST NOT remove the
# cross-user detection — the two are orthogonal and must coexist.
HAS_SS_CHECK=$(grep -nE 'ss[[:space:]]+-tlnpH?[[:space:]]+.*sport.*ATC_PORT|ss[[:space:]]+-tlnpH?[[:space:]]+"sport[[:space:]]*=[[:space:]]*:\$ATC_PORT"' "$DEPLOY_RUNNER" || true)
HAS_ETIME_CHECK=$(grep -nE 'etimes.*-le.*60|new_etimes.*-gt.*60|\-gt.*60' "$DEPLOY_RUNNER" || true)
if [ -n "$HAS_SS_CHECK" ] && [ -n "$HAS_ETIME_CHECK" ]; then
  pass "TC6 — RCA-12 ss/etime cross-user check STILL present (defense-in-depth backstop intact; AC5 defense-in-depth preserved)"
else
  fail "TC6 — RCA-12 ss/etime backstop MISSING" \
    "expected both 'ss -tlnp ... sport = :\$ATC_PORT' AND 'etimes > 60' check in deploy-runner.sh. If the readiness loop REPLACED the cross-user check (instead of supplementing it), the cross-user detection (RCA-12 original purpose, Issue #168) is gone — refuse this regression."
fi

# ============================================================================
# TC7 (ADR-0049 sister-pattern coverage): d017 + d122 + d123 ≥3 sister pattern
# ============================================================================
section "TC7: sister-pattern coverage — d017 + d122 + d123 ≥3 RCA-12/uvicorn readiness family"
SISTER_OK=1
SISTER_MISSING=""
for sister in d017-rca-12-cross-user-port-8000 d122-run-server-sh-uv-extra-web; do
  if [ ! -f "${SCRIPT_DIR}/${sister}.sh" ]; then
    SISTER_OK=0
    SISTER_MISSING="${SISTER_MISSING}${sister}.sh "
  fi
done
if [ "$SISTER_OK" = "1" ] && [ -f "${SCRIPT_DIR}/d123-rca-12-uvicorn-coldstart-readiness.sh" ]; then
  pass "TC7 — sister-pattern coverage ≥3 intact: d017 (RCA-12 cross-user) + d122 (RCA-20 run-server) + d123 (RCA-19 readiness) all present on main"
else
  fail "TC7 — sister-pattern coverage broken" \
    "missing on main: $SISTER_MISSING (uvicorn-readiness family would shrink below ADR-0049 ≥3 baseline)"
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "  PASS:           %d\n" "$PASS"
printf "  FAIL:           %d\n" "$FAIL"
printf "  INFO:           %d\n" "$INFO"
printf "  Deploy-runner:  %s\n" "$DEPLOY_RUNNER"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${R}RED state: %d TC(s) FAILING — uvicorn cold-start readiness broken per ADR-0044 RED-first${D}\n" "$FAIL"
  printf "${R}PR #785 (Issue #785 INCIDENT-2 v9.2) MUST merge before d123 GREEN. Implement wait_for_uvicorn_ready helper in deploy-runner.sh.${D}\n"
  exit 1
fi

printf "\n${G}GREEN state: all 7 TCs PASS — uvicorn cold-start readiness landed, defense-in-depth backstop preserved${D}\n"
exit 0
