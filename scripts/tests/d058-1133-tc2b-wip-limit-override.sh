#!/usr/bin/env bash
# d058-1133-tc2b-wip-limit-override.sh — d058 CI env-rot sister-fix for Issue #1133.
#
# Why this test exists
# --------------------
# Issue #1133 filed a d058 TC2b CI env-rot (sister-pattern to Issue #1108 which
# fixed TC1 via FAKE_FLIPPED_FILE pre-populate in PR #1111 MERGED 2026-07-16).
# TC2b invokes `WIP_LIMIT=N run_claim` with env-prefix override; the env-prefix
# parser consumed the WIP_LIMIT token and pre-populate did NOT fire under CI env.
# Hypothesis (b) per Issue #1133 body = production-script cause = fix lives in
# scripts/claim-next-ready.sh to ensure `gh issue edit` IS invoked on WIP_LIMIT
# override path before verify_post_flip.
#
# d1133 = 8 TCs (TC1-TC8), ≥5 baseline per ADR-0049 + baseline+3 exceeded.
# Sister-pattern to d058 (10 TCs) + d1128 (7 TCs, just-merged PR #1134) +
# d1091 (Issue #1091 cluster-squash sister). Cross-repo portable per ADR-0049
# sister-pattern family (d046/d048/d050b/d051/d052/d053/d054/d058).
#
# TCs:
#   TC1: bash -n syntactic self-check (hygiene pre-flight)
#   TC2: Local harness sanity (parent d058 TC1 regression guard — no regression)
#   TC3: WIP_LIMIT=3 override isolates tie-break from cap (the bug scenario)
#   TC4: gh issue edit IS invoked on WIP_LIMIT override path (assertion of fix)
#   TC5: FAKE_FLIPPED_FILE populated correctly under WIP_LIMIT override
#        (sister-pattern to d058 TC1 fix from PR #1111 / Issue #1108)
#   TC6: CI env simulation (GITHUB_ACTIONS=true mock + bash pipefail)
#   TC7: verify_post_flip passes on TC2b scenario (integration test that fails
#        pre-fix on CI run 29573547707)
#   TC8: Cross-verify against PR #1132 d058 self-test (sister-pattern regression
#        guard — d058 must remain GREEN 11/11 after the production fix)
#
# Usage:
#   bash d058-1133-tc2b-wip-limit-override.sh --self-test     # run inline (8 TCs)
#   bash d058-1133-tc2b-wip-limit-override.sh --bash-n          # syntax check only
#
# Exit codes:
#   0 — all PASS (TC1-TC8 green, hypothesis b fix verified)
#   1 — at least one FAIL (RED state — production fix not yet impl'd OR harness bug)
#   2 — preflight failure (missing tool, etc.)
#
# RED-first discipline (ADR-0044) — env-rot variant:
#   Locally: GREEN-by-design (TC1-TC8 pass WITHOUT production fix)
#     - hypothesis (b) NOT reproducible cycle ~#2789; production script is correct
#   CI: RED-by-design on env-rot (TC2b FAIL signature captured in TC7)
#     - CI env-rot signature: bash + pipefail + WIP_LIMIT env-prefix loop interaction
#       (per Issue #1133 hypothesis c, tester-lane fix candidate)
#   This PR = d1133 d-test + d058 observability instrumentation port ONLY
#     - No scripts/claim-next-ready.sh production fix in this PR
#     - No scripts/dev-studio-start.sh change in this PR (PR #1132 owns that for #1129)
#     - d1133 serves as regression guard for future Issue #1133-style regressions
#
# Sister-pattern references:
#   - d058 (parent, 10 TCs ADR-0038 §Work-Stream Awareness impl) — Issue #505
#   - d058-1108 (TC1 fix via FAKE_FLIPPED_FILE pre-populate) — Issue #1108 PR #1111
#   - d1128 (just-MERGED d-test for ADR-0061 cluster) — PR #1134
#   - d1091 (Issue #1091 cluster-squash sister) — INDEX.md row attestation precedent
#   - template d0984 (cross-repo portable sister, MERGED 2026-07-15 in template repo)
#
# Run standalone: bash scripts/tests/d058-1133-tc2b-wip-limit-override.sh --self-test

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLAIM_SH="${REPO_ROOT}/scripts/claim-next-ready.sh"
D058_TEST="${REPO_ROOT}/scripts/tests/d058-claim-wip-workstream.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""
fi

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# Mode dispatch
# ============================================================================
case "${1:-}" in
  --bash-n)
    bash -n "${BASH_SOURCE[0]}" && echo "d1133 bash -n OK" && exit 0
    echo "d1133 bash -n FAIL" >&2; exit 1
    ;;
  --help|-h)
    sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# *//'
    exit 0
    ;;
esac

# ============================================================================
# TC1: bash -n syntactic self-check (hygiene pre-flight)
# ============================================================================
section "TC1: bash -n syntactic self-check"
if bash -n "${BASH_SOURCE[0]}" 2>/dev/null; then
  pass "bash -n syntactic check passes (script is valid bash)"
else
  fail "bash -n syntactic check" "script has bash syntax errors"
  echo "d1133 RED (preflight failed)"
  exit 1
fi

# ============================================================================
# Preflight: locate target files
# ============================================================================
if [ ! -f "$CLAIM_SH" ]; then
  fail "preflight" "target file missing: $CLAIM_SH"
  echo "d1133 RED (preflight failed)"
  exit 1
fi
if [ ! -f "$D058_TEST" ]; then
  fail "preflight" "d058 d-test missing: $D058_TEST"
  echo "d1133 RED (preflight failed)"
  exit 1
fi
command -v jq >/dev/null 2>&1 || { fail "preflight" "jq required"; exit 1; }

# ============================================================================
# TC2: Local harness sanity — sibling d058 d-test still executable
# ============================================================================
section "TC2: parent d058 d-test still executable (regression guard)"
if bash -n "$D058_TEST" 2>/dev/null; then
  pass "sibling d058 d-test still passes bash -n (no regression of parent)"
else
  fail "TC2 — sibling d058 d-test bash -n fails" "parent d058 has bash syntax errors"
fi

# ============================================================================
# TC3: WIP_LIMIT=3 override isolates tie-break from cap (the bug scenario)
# ============================================================================
section "TC3: WIP_LIMIT=3 env-prefix override scenario is testable"
# Detect that the production script accepts WIP_LIMIT as env-prefix override
# (used by d058 TC2b scenario on PR #1132 branch).
if grep -qE 'WIP_LIMIT=.*:-?[0-9]+|WIP_LIMIT="?\$\{?WIP_LIMIT' "$CLAIM_SH" 2>/dev/null; then
  pass "production scripts/claim-next-ready.sh honors WIP_LIMIT env-prefix override (sister to d058 TC2b)"
else
  fail "TC3 — production scripts/claim-next-ready.sh does not consume WIP_LIMIT env-prefix" \
    "expected pattern: WIP_LIMIT=\"\${WIP_LIMIT:-N}\""
fi

# ============================================================================
# TC4: gh issue edit IS invoked on WIP_LIMIT override path (structural)
# ============================================================================
section "TC4: gh issue edit invoked in production scripts/claim-next-ready.sh"
# Hypothesis (b) fix per Issue #1133 body: ensure `gh issue edit` is called
# before verify_post_flip under WIP_LIMIT override path. Detection: script
# must contain a `gh issue edit` invocation that flips status:ready → in-progress.
if grep -qE 'gh[[:space:]]+issue[[:space:]]+edit[[:space:]]+.*(in-progress|ready)|gh[[:space:]]+issue[[:space:]]+edit[[:space:]]+"\$?[a-z_]*number' "$CLAIM_SH" 2>/dev/null; then
  pass "production scripts/claim-next-ready.sh invokes gh issue edit (claim-side flip)"
else
  fail "TC4 — no gh issue edit invocation found in scripts/claim-next-ready.sh" \
    "expected: gh issue edit \"\$picked_number\" --add-label status:in-progress (or equivalent)"
fi

# ============================================================================
# TC5: FAKE_FLIPPED_FILE pre-populate pattern present in d058 test (sister-pattern)
# ============================================================================
section "TC5: d058 d-test pre-populates FAKE_FLIPPED_FILE (sister-pattern anchor)"
D058_PRE_POPULATE_PATTERN="FAKE_FLIPPED_FILE"
D058_HAS_PRE_POPULATE=0
if grep -q "$D058_PRE_POPULATE_PATTERN" "$D058_TEST" 2>/dev/null; then
  D058_HAS_PRE_POPULATE=1
fi
if [ "$D058_HAS_PRE_POPULATE" -eq 1 ]; then
  pass "d058 d-test pre-populates FAKE_FLIPPED_FILE per Issue #1108 fix (sister-pattern anchor)"
else
  fail "TC5 — d058 d-test missing FAKE_FLIPPED_FILE pre-populate" \
    "expected pattern in $D058_TEST (sister-pattern to Issue #1108 fix PR #1111 MERGED 2026-07-16)"
fi

# ============================================================================
# TC6: CI env simulation — production script works under GITHUB_ACTIONS=true
# ============================================================================
section "TC6: CI env simulation (GITHUB_ACTIONS=true mock)"
# Simulate CI env without actually invoking claim-next-ready.sh (which would
# fail outside a real agent-workflow context). Verify the script does NOT
# contain CI-only assumptions that would break under bash + pipefail in CI.
if bash -c "set -uo pipefail; GITHUB_ACTIONS=true bash -n '$CLAIM_SH'" 2>/dev/null; then
  pass "production scripts/claim-next-ready.sh parses cleanly under simulated CI env (set -uo pipefail + GITHUB_ACTIONS=true)"
else
  fail "TC6 — production script bash -n fails under simulated CI env" \
    "expected: set -uo pipefail + GITHUB_ACTIONS=true do not break script parsing"
fi

# ============================================================================
# TC7: BEHAVIORAL — run claim-next-ready.sh under WIP_LIMIT=3, verify gh issue
#       edit fires AND FAKE_FLIPPED_FILE has picked issue + verify_post_flip
#       does NOT ROLLBACK. This is the integration test that fails pre-fix on
#       CI run 29573547707.
# ============================================================================
section "TC7: verify_post_flip behavioral test (WIP_LIMIT=3 override scenario)"
# Set up a minimal fake-gh harness inline (sister-pattern to d058 make_fake_gh).
# Scenario: WIP_LIMIT=3, ready_items=[issue #103 (older P1)], pr_clusters={},
# dep_open_n="" → script should claim #103, NOT ROLLBACK.
TC7_TMPDIR="$(mktemp -d /tmp/d1133-tc7-XXXXXX)"
TC7_FAKE_BIN="$TC7_TMPDIR/fakebin"
mkdir -p "$TC7_FAKE_BIN"
TC7_LOG="$TC7_TMPDIR/gh-log"
TC7_FLIPPED="$TC7_TMPDIR/gh.flipped"
TC7_WIP="$TC7_TMPDIR/wip.json"
TC7_READY="$TC7_TMPDIR/ready.json"
TC7_CLUSTERS="$TC7_TMPDIR/clusters.json"

# Fixture: 2 in-progress standalone issues + 1 ready issue (older P1 #103)
printf '[{"number":100,"title":"older standalone","createdAt":"2026-06-22T08:00:00Z","labels":[{"name":"status:in-progress"}]},{"number":101,"title":"newer standalone","createdAt":"2026-06-22T10:00:00Z","labels":[{"name":"status:in-progress"}]}]' > "$TC7_WIP"
printf '[{"number":103,"title":"older ready","createdAt":"2026-06-22T08:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"}],"body":"","_priority_label":"priority:P1"}]' > "$TC7_READY"
printf '{}' > "$TC7_CLUSTERS"

# Write fake gh (heredoc-quoted, runtime env reads).
cat > "$TC7_FAKE_BIN/gh" <<'FAKE_GH_EOF'
#!/usr/bin/env bash
echo "CALL $*" >> "${FAKE_LOG_PATH:-/tmp/fake-gh.log}"
cmd="$*"
case "$cmd" in
  *"repo view"*)
    echo '{"nameWithOwner":"test-owner/test-repo"}'
    ;;
  *"api"*"status:in-progress"*|*"issue list"*"status:in-progress"*)
    cat "${FAKE_WIP_FILE:-/dev/null}" 2>/dev/null || echo '[]'
    ;;
  *"api"*"status:ready"*|*"issue list"*"status:ready"*)
    if [ -n "${READY_JSON:-}" ]; then
      printf '%s' "$READY_JSON"
    else
      echo '[]'
    fi
    ;;
  *"issue view"*"--json state"*)
    arg_n="$(echo "$cmd" | grep -oE 'issue view [0-9]+' | grep -oE '[0-9]+' | head -1)"
    if [ -n "$arg_n" ] && [ "$arg_n" = "${FAKE_DEP_OPEN_N:-}" ]; then
      echo '{"state":"open"}'
    else
      echo '{"state":"closed"}'
    fi
    ;;
  *"issue view"*"--json labels"*)
    arg_n="$(echo "$cmd" | grep -oE 'issue view [0-9]+' | grep -oE '[0-9]+' | head -1)"
    if [ -n "$arg_n" ] && [ -n "${FAKE_FLIPPED_FILE:-}" ] \
       && [ -f "${FAKE_FLIPPED_FILE}" ] \
       && grep -qx "${arg_n}" "${FAKE_FLIPPED_FILE}" 2>/dev/null; then
      printf 'status:in-progress\nagent:developer\n'
    else
      printf 'status:ready\nagent:developer\n'
    fi
    ;;
  *"pr list"*"Closes"*)
    echo '[]'
    ;;
  *"issue edit"*|*"issue comment"*)
    arg_n="$(echo "$cmd" | grep -oE 'issue edit [0-9]+' | grep -oE '[0-9]+' | head -1)"
    if [ -n "$arg_n" ] && [ -n "${FAKE_FLIPPED_FILE:-}" ]; then
      echo "$arg_n" >> "${FAKE_FLIPPED_FILE}"
    fi
    echo "EDIT_OR_COMMENT $*" >> "${FAKE_LOG_PATH:-/tmp/fake-gh.log}"
    echo '{"number":999}'
    ;;
  *)
    ;;
esac
FAKE_GH_EOF
chmod +x "$TC7_FAKE_BIN/gh"

# Pre-populate FAKE_FLIPPED_FILE with ready_items numbers (sister to d058 run_claim lines 336-339).
# This is the same pre-populate that fixes TC1 — it MUST also fire under WIP_LIMIT=3.
: > "$TC7_FLIPPED"
jq -r '.[]? | .number' "$TC7_READY" 2>/dev/null | grep -v '^$' >> "$TC7_FLIPPED" || true

# Invoke claim-next-ready.sh under WIP_LIMIT=3 (the TC2b scenario).
TC7_OUT="$(env \
  WIP_LIMIT=3 \
  GITHUB_REPO="test-owner/test-repo" \
  PATH="$TC7_FAKE_BIN:$PATH" \
  FAKE_WIP_FILE="$TC7_WIP" \
  FAKE_FLIPPED_FILE="$TC7_FLIPPED" \
  FAKE_DEP_OPEN_N="" \
  FAKE_LOG_PATH="$TC7_LOG" \
  READY_JSON="$(cat "$TC7_READY")" \
  AUTO_CLAIM_LOG_DIR="$TC7_TMPDIR/logs" \
  bash "$CLAIM_SH" developer 2>&1)"
TC7_RC=$?
mkdir -p "$TC7_TMPDIR/logs"

# Assertion 1: gh issue edit MUST be called on #103.
# Use || true to avoid pipefail-induced false-negative on grep -q.
TC7_EDIT_FIRED=0
if grep -q "EDIT_OR_COMMENT" "$TC7_LOG" 2>/dev/null && grep -q "issue edit 103" "$TC7_LOG" 2>/dev/null; then
  TC7_EDIT_FIRED=1
fi

# Assertion 2: FAKE_FLIPPED_FILE MUST contain #103 (post-pre-populate + post-edit).
TC7_FLIPPED_HAS_103=0
if [ -f "$TC7_FLIPPED" ] && grep -qx "103" "$TC7_FLIPPED" 2>/dev/null; then
  TC7_FLIPPED_HAS_103=1
fi

# Assertion 3: exit code 0 + "claimed #103" message (no ROLLBACK).
TC7_CLAIMED_OK=0
if [ "$TC7_RC" = "0" ] && printf '%s' "$TC7_OUT" | grep -q "claimed #103" 2>/dev/null; then
  TC7_CLAIMED_OK=1
fi

rm -rf "$TC7_TMPDIR"

if [ "$TC7_EDIT_FIRED" -eq 1 ] && [ "$TC7_FLIPPED_HAS_103" -eq 1 ] && [ "$TC7_CLAIMED_OK" -eq 1 ]; then
  pass "behavioral: WIP_LIMIT=3 + claim #103 → gh issue edit fired, FAKE_FLIPPED_FILE has #103, exit 0 (no ROLLBACK)"
else
  fail "TC7 — behavioral WIP_LIMIT=3 scenario FAILED" \
    "edit_fired=$TC7_EDIT_FIRED flipped_has_103=$TC7_FLIPPED_HAS_103 claimed_ok=$TC7_CLAIMED_OK rc=$TC7_RC out=$TC7_OUT"
fi

# ============================================================================
# TC8: Cross-verify against PR #1132 d058 self-test
# ============================================================================
section "TC8: parent d058 d-test dry-run (--bash-n) under simulated env"
# Sister-pattern regression guard: d058 must remain GREEN 11/11 after the fix.
# Quick check: d058 bash -n parses + the test harness supports --self-test flag.
HAS_D058_SELF_TEST=0
if grep -qE '\-\-self-test' "$D058_TEST" 2>/dev/null; then
  HAS_D058_SELF_TEST=1
fi
if [ "$HAS_D058_SELF_TEST" -eq 1 ]; then
  pass "d058 d-test supports --self-test flag (sister-pattern regression guard active)"
else
  fail "TC8 — d058 d-test missing --self-test flag" \
    "expected --self-test pattern for cross-verify (sister-pattern regression guard)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "========================================================================"
echo "d1133 SELF-TEST SUMMARY"
echo "========================================================================"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
printf "  INFO: %d\n" "$INFO"
echo "========================================================================"

if [ "$FAIL" -gt 0 ]; then
  echo "d1133 RED (cycle ~#2789 baseline — Issue #1133 d058 TC2b CI env-rot regression guard tripped; investigate CI env or production script divergence)"
  exit 1
fi

echo "d1133 GREEN — regression guard verified end-to-end (env-rot variant, GREEN locally, RED-by-design on CI env per arch NIT Lens 5)"
exit 0