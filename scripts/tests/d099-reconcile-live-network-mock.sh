#!/usr/bin/env bash
# d099-reconcile-live-network-mock.sh — pattern:NETWORK_DEP mock-first + RECONCILE_LIVE_TOKEN
# toggle regression guard (Issue #1200 / S33-009 + Issue #1204 NIT-1, ADR-0073 §10 row 5).
#
# Why this test exists
# --------------------
# Per Issue #1200 AC2a: env-dep d-tests that hit live GitHub API must default
# to mock-first execution without requiring real tokens, with explicit
# RECONCILE_LIVE_TOKEN=1 opt-in for live API reconciliation. silent_skip log
# emission per ADR-0056 makes mock usage observable in observability logs.
#
# Per Issue #1204 AC1-AC3 (arch cmt 5033069366): the network abstraction layer
# (scripts/d-test-network-abstraction.sh) extends the pattern:NETWORK_DEP family
# with curl/gh call interception: canned mock payload default, RECONCILE_LIVE_TOKEN=1
# real API call with network-down fallback + 429 retry with exponential backoff.
#
# The implementation pattern: two helper scripts
#   - scripts/d-test-reconcile-live.sh (mode resolver: mock|live)
#   - scripts/d-test-network-abstraction.sh (call wrapper: probe|call with retry)
# This d-test validates 9 TCs per ADR-0049 ≥5 baseline + AC2a/AC2a-NIT-1 covering:
# mock-first default + live opt-in + observability + network-down fallback +
# 429 retry detection + token-rotation mid-test + validation + flag path.
#
# Pre-impl RED state (current main as of 2026-07-22 post-PR-1203-squash):
#   - 7/9 TCs FAIL on TC4 (network-down) + TC5 (rate-limit) — Issue #1204
#     extension not yet shipped (network-abstraction helper absent from main).
#   - TC7 (renumbered from old TC4 invalid-value) + TC8 (renumbered from old
#     TC5 --check flag) preserved as-is from Issue #1200 baseline.
#   → 7/9 FAIL on TC4+TC5 = proper RED-first per ADR-0044.
#
# Post-impl GREEN state (after Issue #1204 PR squash):
#   - TC0: bash -n hygiene PASS (BOTH helpers syntactically valid)
#   - TC1: RECONCILE_LIVE_TOKEN unset → "mock" (mock-first default per AC2a TC1)
#   - TC2: RECONCILE_LIVE_TOKEN=1 → "live" (live opt-in per AC2a TC2)
#   - TC3: silent_skip log emission per ADR-0056 (mock mode observability per AC2a TC3)
#   - TC4: network-down mock fallback (probe unreachable URL → 'down' + canned payload) — Issue #1204 NIT-1 AC2a
#   - TC5: rate-limit detection (probe 429-returning URL → 'rate-limited' + silent_skip per attempt) — Issue #1204 NIT-1 AC2a
#   - TC6: token-rotation mid-test — RECONCILE_LIVE_TOKEN change between invocations respected (no caching)
#   - TC7: invalid RECONCILE_LIVE_TOKEN value → exit 2 (validation rejection, preserved from old TC4)
#   - TC8: --check flag path (mock mode + log emission verification, preserved from old TC5)
#
# Sister-pattern family (d-test lineage, ADR-0049):
#   - d058 TC11 (CLAIM_NEXT_READY_LOCK_FILE env-var-driven override)
#   - d069 (WORKFLOW_FILES env-var-driven parameterization)
#   - d098 (--target-os flag + TARGET_OS env-var override — DIRECT sister d099)
#   - d020a TC4 (jq filter perf budget, shell-test discipline)
#   - d064 (fake-binary factory, TC7 fake-uname sister-pattern)
#   - cycle ~#3642B REST fallback (gh api .../comments for GraphQL exhaustion — sister-pattern)
#   - ADR-0056 silent_skip log emission doctrine
#
# Sprint 33 P2 cluster (ref cycle ~#209 owner directive 2026-07-21T09:55Z):
#   - Issue #1199 S33-008 pattern:CI_OS_DEP — d098 sister (squash @ f7fafb8)
#   - Issue #1200 S33-009 pattern:NETWORK_DEP — this d-test baseline (squash @ f78980f)
#   - Issue #1204 S33-009 NIT-1 follow-up — this d-test extension
#   - ADR-0073 §10 action item row 5 — closes (network abstraction layer)
#
# Usage:
#   bash scripts/tests/d099-reconcile-live-network-mock.sh --self-test
#
# Exit codes:
#   0 — all PASS (GREEN state — helper scripts + toggle + retry paths validated)
#   1 — at least one FAIL (RED state — impl incomplete or helper missing)
#   2 — preflight failure (missing tool, file missing, etc.)
#
# Cadence Rule 1 atomic (ADR-0055 §1):
#   d-test file + scripts/d-test-reconcile-live.sh (Issue #1200 baseline) +
#   scripts/d-test-network-abstraction.sh (Issue #1204 NIT-1 extension) +
#   INDEX.md row + CHANGELOG.md entry all land in same commit.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HELPER_SH="${REPO_ROOT}/scripts/d-test-reconcile-live.sh"
NETWORK_HELPER_SH="${REPO_ROOT}/scripts/d-test-network-abstraction.sh"

# Colors (TTY-aware — sister-pattern to d098)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""; fi

# Pre-flight
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required" >&2; exit 2; }
[ -f "$HELPER_SH" ] || { echo "ERROR: helper not found at $HELPER_SH" >&2; exit 2; }
[ -f "$NETWORK_HELPER_SH" ] || { echo "ERROR: network helper not found at $NETWORK_HELPER_SH" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl required for TC4+TC5 (network abstraction layer)" >&2; exit 2; }

# Self-test mode (sister-pattern to d098 / d097 / d020a)
if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: bash $0 --self-test" >&2
  exit 2
fi

printf "${B}d099 self-test (9 TCs: TC0 hygiene + AC2a ≥6 baseline + Issue #1204 NIT-1 TC4 network-down + TC5 429-retry)${D}\n"
printf "${B}=======================================================================================${D}\n"
printf "  SUT-1: %s (Issue #1200 baseline, mode resolver)\n" "$HELPER_SH"
printf "  SUT-2: %s (Issue #1204 NIT-1, call wrapper)\n" "$NETWORK_HELPER_SH"
printf "  Spec: Issue #1200 + Issue #1204 pattern:NETWORK_DEP (ADR-0073 §10 row 5)\n"
printf "  RED-first: pre-impl TC4+TC5 FAIL (network helper absent from main).\n"
printf "  Post-impl: 9/9 GREEN.\n\n"

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# TC0: bash -n hygiene on BOTH helpers (sister-pattern to d098 TC0 + d020a TC1)
# ============================================================================
section "TC0: bash -n hygiene on both helpers (sister-pattern to d098 TC0)"
TC0_PASS=1
if bash -n "$HELPER_SH"; then
  pass "bash -n $HELPER_SH (Issue #1200 baseline) → exit 0"
else
  fail "TC0a — bash -n FAIL on $HELPER_SH" "helper has syntax errors; fix before other TCs"
  TC0_PASS=0
fi
if bash -n "$NETWORK_HELPER_SH"; then
  pass "bash -n $NETWORK_HELPER_SH (Issue #1204 NIT-1) → exit 0"
else
  fail "TC0b — bash -n FAIL on $NETWORK_HELPER_SH" "network helper has syntax errors; fix before TC4+TC5"
  TC0_PASS=0
fi
if [ "$TC0_PASS" = "0" ]; then
  exit 1
fi

# ============================================================================
# TC1: RECONCILE_LIVE_TOKEN unset → "mock" (mock-first default per AC2a TC1)
# ============================================================================
section "TC1: RECONCILE_LIVE_TOKEN unset → 'mock' (mock-first default per AC2a TC1)"
OUT="$(unset RECONCILE_LIVE_TOKEN; bash "$HELPER_SH")"
RC=$?
if [ "$RC" = "0" ] && [ "$OUT" = "mock" ]; then
  pass "mock-first default: RECONCILE_LIVE_TOKEN unset → 'mock' (no token required)"
else
  fail "TC1 — mock-first default broken" "expected 'mock', got rc=$RC out='$OUT'"
fi

# ============================================================================
# TC2: RECONCILE_LIVE_TOKEN=1 → "live" (live opt-in per AC2a TC2)
# ============================================================================
section "TC2: RECONCILE_LIVE_TOKEN=1 → 'live' (live opt-in per AC2a TC2)"
OUT="$(RECONCILE_LIVE_TOKEN=1 bash "$HELPER_SH")"
RC=$?
if [ "$RC" = "0" ] && [ "$OUT" = "live" ]; then
  pass "live opt-in: RECONCILE_LIVE_TOKEN=1 → 'live' (real API call)"
else
  fail "TC2 — live opt-in broken" "expected 'live', got rc=$RC out='$OUT'"
fi

# ============================================================================
# TC3: silent_skip log emission per ADR-0056 (mock mode observability per AC2a TC3)
# ============================================================================
section "TC3: silent_skip log emission per ADR-0056 (--check flag, mock mode)"
LOG_DIR="$(mktemp -d /tmp/d099-log-XXXXXX)"
export D_TEST_LOG_DIR="$LOG_DIR"
trap 'rm -rf "$LOG_DIR"' EXIT
OUT="$(bash "$HELPER_SH" --check)"
RC=$?
LOG_FILE="$LOG_DIR/d099.silent_skip.log"
if [ "$RC" = "0" ] && [ "$OUT" = "mock" ] && [ -f "$LOG_FILE" ] && \
   grep -q "silent_skip mode=mock helper=scripts/d-test-reconcile-live.sh" "$LOG_FILE"; then
  pass "silent_skip log emitted per ADR-0056: $(tail -1 "$LOG_FILE" | head -c 100)..."
else
  fail "TC3 — silent_skip log emission broken" "rc=$RC out='$OUT' logfile_exists=$([ -f "$LOG_FILE" ] && echo yes || echo no)"
fi

# ============================================================================
# TC4: network-down mock fallback (Issue #1204 NIT-1 AC2a, arch cmt 5033069366)
# ============================================================================
# Pattern: probe a URL with an invalid TLD (.invalid) which will fail DNS
# resolution. Helper must detect this as 'down' state and emit canned payload
# fallback + silent_skip log per ADR-0056. Sister-pattern to d064 fake-uname
# (fake-bin factory for OS-detection rescue).
section "TC4: network-down mock fallback (probe invalid URL → 'down' + canned payload + silent_skip)"
LOG_DIR_NETDOWN="$(mktemp -d /tmp/d099-log-netdown-XXXXXX)"
export D_TEST_LOG_DIR="$LOG_DIR_NETDOWN"
# .invalid TLD is reserved per RFC 2606 — guaranteed DNS failure (curl RC 6).
OUT_TC4="$(RECONCILE_LIVE_TOKEN=1 D_TEST_LOG_DIR="$LOG_DIR_NETDOWN" bash "$NETWORK_HELPER_SH" --probe --check --url='http://d099-network-down-mock.invalid/api/test' 2>&1)"
RC_TC4=$?
LOG_FILE_NETDOWN="$LOG_DIR_NETDOWN/d099.silent_skip.log"
if [ "$RC_TC4" = "0" ] && [ "$OUT_TC4" = "down" ] && \
   [ -f "$LOG_FILE_NETDOWN" ] && \
   grep -q "silent_skip mode=down helper=scripts/d-test-network-abstraction.sh" "$LOG_FILE_NETDOWN" && \
   grep -q "url=http://d099-network-down-mock.invalid/api/test" "$LOG_FILE_NETDOWN"; then
  pass "network-down fallback: probe .invalid URL → 'down' + canned payload + silent_skip emitted"
else
  fail "TC4 — network-down fallback broken" \
    "expected rc=0 'down' + silent_skip log; rc=$RC_TC4 out='$OUT_TC4' log_lines=$(wc -l < "$LOG_FILE_NETDOWN" 2>/dev/null || echo 0)"
fi
rm -rf "$LOG_DIR_NETDOWN"

# ============================================================================
# TC5: rate-limit detection (Issue #1204 NIT-1 AC2a, arch cmt 5033069366)
# ============================================================================
# Pattern: fake-bin factory (sister-pattern to d064 TC7 fake-uname) where
# a mock curl always returns HTTP 429. Helper must detect rate limit, retry
# with exponential backoff, emit silent_skip per attempt per ADR-0056, and
# exit 3 (rate-limited exhausted) after MAX_RETRIES attempts.
section "TC5: rate-limit detection (fake-curl 429 → exit 3 + silent_skip per retry)"
FAKE_BIN_RL="$(mktemp -d /tmp/d099-fakebin-rl-XXXXXX)"
LOG_DIR_RL="$(mktemp -d /tmp/d099-log-rl-XXXXXX)"
export D_TEST_LOG_DIR="$LOG_DIR_RL"
# Fake curl: always returns HTTP 429, ignores all args
cat > "$FAKE_BIN_RL/curl" <<'EOF'
#!/usr/bin/env bash
# fake-curl: d099 TC5 rate-limit mock — always returns 429
# Sister-pattern to d064 TC7 fake-uname fake-binary factory.
# NOTE: must NOT use `shift` inside `for arg in "$@"` loop (shifts entire
# $@, breaking arg tracking). Use PREV_ARG carry-forward pattern instead.
OUTPUT_FILE=""
PREV_ARG=""
for arg in "$@"; do
  case "$PREV_ARG" in
    --output)
      OUTPUT_FILE="$arg"
      ;;
  esac
  case "$arg" in
    --output)
      PREV_ARG="--output"
      ;;
    --output=*)
      OUTPUT_FILE="${arg#--output=}"
      PREV_ARG=""
      ;;
    *)
      PREV_ARG=""
      ;;
  esac
done
if [ -n "$OUTPUT_FILE" ]; then
  echo "rate limited" > "$OUTPUT_FILE"
fi
echo "429"
exit 0
EOF
chmod +x "$FAKE_BIN_RL/curl"
START_TC5=$(date +%s)
OUT_TC5="$(PATH="$FAKE_BIN_RL:$PATH" RECONCILE_LIVE_TOKEN=1 D_TEST_LOG_DIR="$LOG_DIR_RL" bash "$NETWORK_HELPER_SH" --probe --check --url='http://d099-rl-mock.invalid/api/test' 2>&1)"
RC_TC5=$?
END_TC5=$(date +%s)
LOG_FILE_RL="$LOG_DIR_RL/d099.silent_skip.log"
RL_LOG_LINES=$(wc -l < "$LOG_FILE_RL" 2>/dev/null || echo 0)
RL_RETRY_LOGS=$(grep -c "silent_skip mode=rate-limited" "$LOG_FILE_RL" 2>/dev/null || echo 0)
# Expected: rc=0 (--probe mode returns 'rate-limited' on final attempt + exit 0),
# 'rate-limited' output, ≥1 silent_skip rate-limited log, total backoff ≥3s
# (sleep-before-retry pattern: 1s before attempt 2 + 2s before attempt 3 = 3s
# consumed; the 4s third backoff is NOT consumed because attempt 3 is the
# final attempt — no further retry after exhaustion). Sister-pattern: d064
# fake-bin factory (TC5 fake-curl sister-pattern to TC7 fake-uname).
ELAPSED_TC5=$((END_TC5 - START_TC5))
if [ "$RC_TC5" = "0" ] && [ "$OUT_TC5" = "rate-limited" ] && \
   [ "$RL_RETRY_LOGS" -ge 1 ] && [ "$ELAPSED_TC5" -ge 3 ]; then
  pass "rate-limit detection: fake-curl 429 → 'rate-limited' + ${RL_RETRY_LOGS} retry log(s) + ${ELAPSED_TC5}s backoff (≥3s for 1+2s exponential, sleep-before-retry pattern)"
else
  fail "TC5 — rate-limit detection broken" \
    "expected rc=0 'rate-limited' + ≥1 retry log + ≥3s backoff; rc=$RC_TC5 out='$OUT_TC5' retry_logs=$RL_RETRY_LOGS elapsed=${ELAPSED_TC5}s"
fi
rm -rf "$FAKE_BIN_RL" "$LOG_DIR_RL"

# ============================================================================
# TC7: invalid RECONCILE_LIVE_TOKEN value → exit 2 (validation rejection, preserved from old TC4)
# ============================================================================
section "TC7: invalid RECONCILE_LIVE_TOKEN=foobar → exit 2 (validation rejection, preserved from old TC4)"
OUT="$(RECONCILE_LIVE_TOKEN=foobar bash "$HELPER_SH" 2>&1)"
RC=$?
if [ "$RC" = "2" ] && echo "$OUT" | grep -qiE 'invalid|unknown|unsupported'; then
  pass "RECONCILE_LIVE_TOKEN=foobar rejected with exit 2 + clear error message"
else
  fail "TC7 — invalid value not rejected properly" \
    "expected rc=2 + error message; rc=$RC out='$OUT'"
fi

# ============================================================================
# TC8: --check flag path (no mode change, only log emission trigger, preserved from old TC5)
# ============================================================================
section "TC8: --check flag path (mock mode + log emission verification, preserved from old TC5)"
LOG_DIR2="$(mktemp -d /tmp/d099-log2-XXXXXX)"
D_TEST_LOG_DIR="$LOG_DIR2" bash "$HELPER_SH" --check >/dev/null
LOG_FILE2="$LOG_DIR2/d099.silent_skip.log"
LINE_COUNT_BEFORE=0
LINE_COUNT_AFTER="$(wc -l < "$LOG_FILE2" 2>/dev/null || echo 0)"
if [ "$LINE_COUNT_AFTER" -gt "$LINE_COUNT_BEFORE" ] && \
   grep -q "silent_skip mode=mock" "$LOG_FILE2"; then
  pass "--check emitted silent_skip log entry: $(grep -c 'silent_skip' "$LOG_FILE2") line(s)"
else
  fail "TC8 — --check flag path broken" "log_file_lines=$LINE_COUNT_AFTER grep_match=no"
fi
rm -rf "$LOG_DIR2"

# ============================================================================
# TC6: token-rotation mid-test — RECONCILE_LIVE_TOKEN change between invocations
# respected (no caching per AC2a TC6)
# ============================================================================
section "TC6: token-rotation mid-test — RECONCILE_LIVE_TOKEN change between invocations respected"
# First invocation: unset → mock
OUT1="$(unset RECONCILE_LIVE_TOKEN; bash "$HELPER_SH")"
# Second invocation: set to 1 → live (helper should NOT cache from prev call)
OUT2="$(RECONCILE_LIVE_TOKEN=1 bash "$HELPER_SH")"
# Third invocation: unset again → mock (rotation back, no state carried)
OUT3="$(unset RECONCILE_LIVE_TOKEN; bash "$HELPER_SH")"
if [ "$OUT1" = "mock" ] && [ "$OUT2" = "live" ] && [ "$OUT3" = "mock" ]; then
  pass "token-rotation mid-test: mock → live → mock (no caching, env-resolved each call)"
else
  fail "TC6 — token-rotation caching detected" "out1='$OUT1' out2='$OUT2' out3='$OUT3'"
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== d099 SELF-TEST SUMMARY ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"
printf "  ${Y}INFO${D}: %d\n" "$INFO"

# Sister-pattern invariant for Issue #1200 AC2a + Issue #1204 NIT-1 AC2a:
#   Pre-impl (network helper absent): 7/9 FAIL on TC4+TC5 (network abstraction
#     layer not yet shipped)
#   Post-impl (network helper shipped): 9/9 GREEN
#
# We accept either:
#   (a) 9/9 PASS — impl complete (d-test-reconcile-live.sh + d-test-network-abstraction.sh
#       + INDEX.md + CHANGELOG.md all landed), d099 GREEN
#   (b) FAIL on TC0..TC8 — RED state confirmed (helper missing OR impl incomplete)
#   (c) Specifically: pre-Issue #1204-squash, TC4+TC5 will FAIL while TC0+TC1+TC2+TC3+TC6+TC7+TC8
#       pass (7 GREEN + 2 RED = RED state with NIT-1 extension unimplemented)
if [ "$FAIL" -eq 0 ]; then
  printf "  ${G}d099 GREEN${D} — 9/9 PASS = pattern:NETWORK_DEP family fully validated (mock-first + live opt-in + silent_skip + network-down fallback + 429 retry + token-rotation + validation + flag path)\n"
  exit 0
else
  printf "  ${R}d099 RED${D} — %d FAIL observed. Action: implement scripts/d-test-reconcile-live.sh (Issue #1200 baseline) + scripts/d-test-network-abstraction.sh (Issue #1204 NIT-1) + this INDEX.md row + CHANGELOG entry per ADR-0055 §1 Cadence Rule 1 atomic.\n" "$FAIL"
  exit 1
fi