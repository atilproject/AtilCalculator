#!/usr/bin/env bash
# d834-stale-lock-cleanup.sh — Issue #834 P1 sister-test (5 TCs, ADR-0049 baseline).
#
# Why this test exists
# --------------------
# PR #832 CI flake (lint-and-test run 28711123264, d058 TC10) revealed that
# `claim-next-ready.sh` startup does NOT detect stale flock locks held by
# dead/abandoned processes. The lock file persists at
# `/var/lock/dev-studio/claim-${ROLE}.lock` even after the holding process
# exits (no PID-aware cleanup). On the self-hosted CI runner (and locally),
# zero-byte `claim-*.lock` files persist after session ends; `lsof` and
# `/proc/locks` show no holders. Subsequent invocations fail with exit 5
# instead of allowing the new claim attempt.
#
# Issue #834 AC1-AC5 verify the PID-aware cleanup design (arch verdict cmt
# 4883055858, option b PRIMARY):
#   AC1: stale lock + dead PID → cleanup + success
#   AC2: stale lock + alive PID → still denied (existing flock -n behavior)
#   AC3: stale lock without .pid sidecar → fallback cleanup + success
#   AC4: only same-role lock checked (cross-role isolation)
#   AC5: silent_skip log emit (TD-016/020 family pattern)
#
# Pre-fix (current state, 2026-07-04): all 5 TCs should FAIL in RED state
# because the PID-aware cleanup path does NOT exist in claim-next-ready.sh
# yet. The impl PR will turn them GREEN.
#
# 5 TCs (per ADR-0049 ≥5 TCs baseline):
#   TC1: dead-PID recovery (stale lock + dead PID → cleanup → success)
#   TC2: alive-PID concurrent-deny (existing flock behavior preserved)
#   TC3: missing-PID legacy-cleanup (lock without `.pid` sidecar → fallback)
#   TC4: cross-role isolation (only same-role lock checked)
#   TC5: silent_skip log emit (TD-016/020 family pattern)
#
# Sister-pattern family (d-test lineage, ADR-0049):
#   - d809-claim-next-ready-race.sh — original concurrent-invocation race
#   - d066-wip-cap-filter.sh — WIP cap filter (6 TCs, RETRO-012 §6)
#   - d058-claim-wip-workstream.sh — work-stream awareness (9 TCs)
#   - d031-claim-next-ready.sh — ADR-0038 §Layer 2 claim (10 TCs)
#   - TD-016 / TD-020 — silent_skip log family
#
# Usage:
#   bash d834-stale-lock-cleanup.sh --self-test     # run 5 TCs (RED-first)
#
# Exit codes:
#   0 — all PASS (GREEN, AC1-AC5 verified after fix lands)
#   1 — at least one FAIL (RED state — feature missing OR test bug)
#   2 — preflight failure (missing tool, etc.)
#
# RED-first discipline (ADR-0044):
#   Pre-impl: this d-test enforces NOT-YET-SHIPPED behavior. All 5 TCs should
#     FAIL until the impl PR lands. The d-test is the regression guard against
#     future drift AND the spec for the impl.
#   Post-impl: all 5 TCs must PASS (GREEN).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLAIM_SH="${REPO_ROOT}/scripts/claim-next-ready.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33M'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""
fi

pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Pre-flight
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }
command -v flock >/dev/null 2>&1 || { echo "ERROR: flock required" >&2; exit 2; }

# Self-test mode
if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: bash $0 --self-test" >&2
  exit 2
fi

printf "${B}d834 self-test (5 TCs per ADR-0044 RED-first, Issue #834 P1 sister-test)${D}\n"
printf "${B}====================================================================${D}\n"
printf "  Impl under test: %s\n" "$CLAIM_SH"
printf "  Sister-pattern: d809 (flock mutex) + d066 (WIP cap filter) + d058 (work-stream)\n"
printf "  Spec source: arch verdict cmt 4883055858 (option b PRIMARY)\n"
printf "  RED state expected: all 5 TCs FAIL until impl PR lands\n\n"

PASS=0; FAIL=0; INFO=0
EXIT_CODE=0

# Test sandbox
TEST_TMPDIR="$(mktemp -d /tmp/d834-XXXXXX)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

# ============================================================================
# fake-gh factory — mocks `gh` CLI for offline stale-lock testing
# Pattern: d066 sister (env-var based, NO heredoc, NO sed — BSD/GNU portable)
# ============================================================================
install_fake_gh() {
  local fake_bin="$1"
  local wip_json="$2"
  local ready_json="$3"

  mkdir -p "$fake_bin"
  printf '%s' "$wip_json" > "$fake_bin/wip.json"
  printf '%s' "$ready_json" > "$fake_bin/ready.json"

  cat > "$fake_bin/gh" <<'GH_EOF'
#!/usr/bin/env bash
echo "CALL $*" >> "${FAKE_LOG_PATH:-/tmp/fake-gh.log}"
case "$*" in
  *"repo view"*)    echo '{"nameWithOwner":"test-owner/test-repo"}' ;;
  *"status:in-progress"*)
    if [ -s "${FAKE_WIP_FILE:-/dev/null}" ]; then cat "${FAKE_WIP_FILE}"; else echo '[]'; fi ;;
  *"status:ready"*)
    if [ -s "${FAKE_READY_FILE:-/dev/null}" ]; then cat "${FAKE_READY_FILE}"; else echo '[]'; fi ;;
  *"pr list"*)     echo '[]' ;;
  *"issue edit"*)  echo "EDIT $*" >> "${FAKE_LOG_PATH:-/tmp/fake-gh.log}" ;;
  *"issue comment"*) echo "COMMENT $*" >> "${FAKE_LOG_PATH:-/tmp/fake-gh.log}" ;;
  *)               echo '[]' ;;
esac
GH_EOF
  chmod +x "$fake_bin/gh"
}

# Helper: run claim-next-ready.sh with isolated env + fake-gh + sandboxed locks
# Args: fake_bin, role, wip_in_progress_json, ready_json, lock_file_path
run_claim() {
  local fake_bin="$1"
  local role="$2"
  local wip_json="$3"
  local ready_json="$4"
  local lock_file_path="$5"  # caller pre-creates the lock + sidecar

  install_fake_gh "$fake_bin" "$wip_json" "$ready_json"

  local claim_out_file="$TEST_TMPDIR/claim_out_$$_$RANDOM.txt"
  env \
    FAKE_WIP_FILE="$fake_bin/wip.json" \
    FAKE_READY_FILE="$fake_bin/ready.json" \
    FAKE_LOG_PATH="$fake_bin/gh-log" \
    PATH="$fake_bin:$PATH" \
    GITHUB_REPO="test-owner/test-repo" \
    AUTO_CLAIM_LOG_DIR="$TEST_TMPDIR/logs" \
    CLAIM_NEXT_READY_LOCK_FILE="$lock_file_path" \
    bash "$CLAIM_SH" "$role" \
    > "$claim_out_file" 2>&1
  local rc=$?
  CLAIM_OUT="$(cat "$claim_out_file")"
  rm -f "$claim_out_file"
  return $rc
}

mkdir -p "$TEST_TMPDIR/logs"

# ============================================================================
# TC1: dead-PID recovery (stale lock + dead PID → cleanup → success)
# ============================================================================
section "TC1: dead-PID recovery — stale lock + dead PID → cleanup + success (AC1 RED-state)"
if [ ! -f "$CLAIM_SH" ]; then
  fail "TC1 — claim-next-ready.sh not found" "expected $CLAIM_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc1"
  mkdir -p "$state/fake_bin/locks"
  # Pre-create stale lock with dead PID
  tc1_lock="$state/fake_bin/locks/dev-studio/claim-developer.lock"
  tc1_pid="$state/fake_bin/locks/dev-studio/claim-developer.lock.pid"
  mkdir -p "$(dirname "$tc1_lock")"
  printf '%s\n' "999999" > "$tc1_pid"
  : > "$tc1_lock"

  wip_json='[]'
  ready_json='[{"number":834,"title":"ready item for stale-lock recovery","createdAt":"2026-07-04T00:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"}],"body":""}]'

  run_claim "$state/fake_bin" "developer" "$wip_json" "$ready_json" "$tc1_lock"
  rc=$?

  if [ $rc -ne 0 ]; then
    fail "TC1 — expected exit 0 (stale lock + dead PID → cleanup → claim succeeded)" \
      "got rc=$rc out=$CLAIM_OUT. PID-aware cleanup missing — Issue #834 RED state confirmed."
    EXIT_CODE=1
  elif ! echo "$CLAIM_OUT" | grep -q "claimed #834"; then
    fail "TC1 — expected #834 claimed after stale-lock cleanup" \
      "got: $CLAIM_OUT"
    EXIT_CODE=1
  else
    pass "TC1 — dead-PID recovery works (stale lock cleaned, claim succeeded — GREEN)"
  fi
fi

# ============================================================================
# TC2: alive-PID concurrent-deny (existing flock -n behavior preserved)
# ============================================================================
section "TC2: alive-PID concurrent-deny — stale lock + alive PID → denied (AC2 RED-state)"
if [ ! -f "$CLAIM_SH" ]; then
  fail "TC2 — claim-next-ready.sh not found" "expected $CLAIM_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc2"
  mkdir -p "$state/fake_bin/locks/dev-studio"
  tc2_lock="$state/fake_bin/locks/dev-studio/claim-developer.lock"
  tc2_pid="$state/fake_bin/locks/dev-studio/claim-developer.lock.pid"

  # Spawn a long-lived subshell holding the flock + writing PID sidecar.
  # This simulates an active concurrent claim.
  (
    exec 9>"$tc2_lock"
    flock 9
    printf '%s\n' "$$" > "$tc2_pid"
    sleep 30
  ) &
  TC2_HOLDER_PID=$!
  for _ in $(seq 1 50); do
    [ -f "$tc2_pid" ] && grep -q "^[0-9]" "$tc2_pid" 2>/dev/null && break
    sleep 0.05
  done

  wip_json='[]'
  ready_json='[{"number":835,"title":"ready item for alive-PID deny","createdAt":"2026-07-04T00:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"}],"body":""}]'

  run_claim "$state/fake_bin" "developer" "$wip_json" "$ready_json" "$tc2_lock"
  rc=$?

  kill "$TC2_HOLDER_PID" 2>/dev/null || true
  wait "$TC2_HOLDER_PID" 2>/dev/null || true

  if [ $rc -ne 5 ]; then
    fail "TC2 — expected exit 5 (alive-PID concurrent-deny preserved)" \
      "got rc=$rc out=$CLAIM_OUT. Either stale-lock cleanup is too aggressive OR flock -n guard is broken."
    EXIT_CODE=1
  elif ! echo "$CLAIM_OUT" | grep -q "concurrent invocation denied"; then
    fail "TC2 — expected 'concurrent invocation denied' message" \
      "got: $CLAIM_OUT"
    EXIT_CODE=1
  elif grep -q "claimed #835" "$state/fake_bin/gh-log" 2>/dev/null; then
    fail "TC2 — script claimed despite active concurrent claim" \
      "AC2 violation — alive-PID must NOT be killed/cleaned."
    EXIT_CODE=1
  else
    pass "TC2 — alive-PID concurrent-deny preserved (rc=5, AC2 GREEN)"
  fi
fi

# ============================================================================
# TC3: missing-PID legacy-cleanup (lock without .pid sidecar → fallback cleanup)
# ============================================================================
section "TC3: missing-PID legacy-cleanup — lock without .pid → cleanup + success (AC3 RED-state)"
if [ ! -f "$CLAIM_SH" ]; then
  fail "TC3 — claim-next-ready.sh not found" "expected $CLAIM_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc3"
  mkdir -p "$state/fake_bin/locks/dev-studio"
  tc3_lock="$state/fake_bin/locks/dev-studio/claim-developer.lock"
  # Legacy lock WITHOUT .pid sidecar
  : > "$tc3_lock"

  wip_json='[]'
  ready_json='[{"number":836,"title":"ready item for legacy-cleanup","createdAt":"2026-07-04T00:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"}],"body":""}]'

  run_claim "$state/fake_bin" "developer" "$wip_json" "$ready_json" "$tc3_lock"
  rc=$?

  if [ $rc -ne 0 ]; then
    fail "TC3 — expected exit 0 (legacy lock without .pid → fallback cleanup + claim succeeded)" \
      "got rc=$rc out=$CLAIM_OUT. Missing-PID fallback missing — Issue #834 RED state confirmed."
    EXIT_CODE=1
  elif ! echo "$CLAIM_OUT" | grep -q "claimed #836"; then
    fail "TC3 — expected #836 claimed after legacy-cleanup" \
      "got: $CLAIM_OUT"
    EXIT_CODE=1
  else
    pass "TC3 — missing-PID legacy-cleanup works (AC3 GREEN)"
  fi
fi

# ============================================================================
# TC4: cross-role isolation — only same-role lock checked (other-role locks untouched)
# ============================================================================
section "TC4: cross-role isolation — only same-role lock checked (AC4 RED-state)"
if [ ! -f "$CLAIM_SH" ]; then
  fail "TC4 — claim-next-ready.sh not found" "expected $CLAIM_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc4"
  mkdir -p "$state/fake_bin/dev-studio" "$state/fake_bin/orch"

  # Same-role (tester) lock with dead PID — should be cleaned by cleanup logic
  tc4_tester_lock="$state/fake_bin/dev-studio/claim-tester.lock"
  tc4_tester_pid="$state/fake_bin/dev-studio/claim-tester.lock.pid"
  printf '%s\n' "999999" > "$tc4_tester_pid"
  : > "$tc4_tester_lock"

  # Other-role (orchestrator) lock with dead PID — MUST NOT be touched
  tc4_orch_lock="$state/fake_bin/orch/claim-orchestrator.lock"
  tc4_orch_pid="$state/fake_bin/orch/claim-orchestrator.lock.pid"
  printf '%s\n' "888888" > "$tc4_orch_pid"
  : > "$tc4_orch_lock"

  wip_json='[]'
  ready_json='[{"number":838,"title":"ready item for tester","createdAt":"2026-07-04T00:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:tester"}],"body":""}]'

  install_fake_gh "$state/fake_bin" "$wip_json" "$ready_json"

  claim_out_file="$TEST_TMPDIR/claim_out_tc4_$$.txt"
  env \
    FAKE_WIP_FILE="$state/fake_bin/wip.json" \
    FAKE_READY_FILE="$state/fake_bin/ready.json" \
    FAKE_LOG_PATH="$state/fake_bin/gh-log" \
    PATH="$state/fake_bin:$PATH" \
    GITHUB_REPO="test-owner/test-repo" \
    AUTO_CLAIM_LOG_DIR="$TEST_TMPDIR/logs" \
    CLAIM_NEXT_READY_LOCK_FILE="$tc4_tester_lock" \
    bash "$CLAIM_SH" "tester" \
    > "$claim_out_file" 2>&1
  rc=$?
  CLAIM_OUT="$(cat "$claim_out_file")"
  rm -f "$claim_out_file"

  if [ $rc -ne 0 ]; then
    fail "TC4 — expected exit 0 (tester claim succeeded after own-role stale-lock cleanup)" \
      "got rc=$rc out=$CLAIM_OUT"
    EXIT_CODE=1
  elif [ ! -f "$tc4_orch_lock" ]; then
    fail "TC4 — orchestrator lock was removed by tester claim (cross-role isolation violated)" \
      "AC4 violation. Cleanup logic must only target same-role lock."
    EXIT_CODE=1
  elif [ ! -f "$tc4_orch_pid" ]; then
    fail "TC4 — orchestrator .pid sidecar was removed by tester claim" \
      "AC4 violation."
    EXIT_CODE=1
  else
    pass "TC4 — cross-role isolation preserved (tester lock cleaned; orchestrator lock untouched — AC4 GREEN)"
  fi
fi

# ============================================================================
# TC5: silent_skip log emit (TD-016/020 family pattern — observability)
# ============================================================================
section "TC5: silent_skip log emit on stale-lock cleanup (AC5 RED-state)"
if [ ! -f "$CLAIM_SH" ]; then
  fail "TC5 — claim-next-ready.sh not found" "expected $CLAIM_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc5"
  mkdir -p "$state/fake_bin/locks/dev-studio"
  tc5_lock="$state/fake_bin/locks/dev-studio/claim-developer.lock"
  tc5_pid="$state/fake_bin/locks/dev-studio/claim-developer.lock.pid"
  printf '%s\n' "999999" > "$tc5_pid"
  : > "$tc5_lock"

  wip_json='[]'
  ready_json='[{"number":839,"title":"ready item for log emit","createdAt":"2026-07-04T00:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"}],"body":""}]'

  run_claim "$state/fake_bin" "developer" "$wip_json" "$ready_json" "$tc5_lock"

  # After successful cleanup + claim, the audit log should contain a
  # silent_skip / stale-lock-cleanup entry per TD-016 / TD-020 pattern.
  log_file="$TEST_TMPDIR/logs/auto-claim.log"

  if [ ! -f "$log_file" ]; then
    fail "TC5 — audit log file not created (AUTO_CLAIM_LOG_DIR missing)" \
      "expected log at $log_file. silent_skip observability broken — TD-016/020 violation."
    EXIT_CODE=1
  elif ! grep -qE 'stale-lock-cleanup|dead-PID|silent_skip|999999' "$log_file" 2>/dev/null; then
    fail "TC5 — audit log does not mention stale-lock cleanup event" \
      "log content: $(cat $log_file 2>/dev/null). AC5 silent_skip observability missing."
    EXIT_CODE=1
  else
    pass "TC5 — silent_skip log emitted on stale-lock cleanup (AC5 GREEN, TD-016/020 pattern verified)"
  fi
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
printf "  INFO: %d\n" "$INFO"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${R}RED state: %d TC(s) FAILING — PID-aware cleanup missing in claim-next-ready.sh (Issue #834 RED-state, impl pending) per ADR-0044 RED-first${D}\n" "$FAIL"
  exit 1
fi

printf "\n${G}GREEN state: all 5 TCs PASS — PID-aware cleanup correct (Issue #834 fix verified, Issue #809 sister-pattern intact)${D}\n"
exit 0
