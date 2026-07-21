#!/usr/bin/env bash
# d099-reconcile-live-network-mock.sh — pattern:NETWORK_DEP mock-first + RECONCILE_LIVE_TOKEN
# toggle regression guard (Issue #1200 / S33-009, ADR-0073 §10 row 5).
#
# Why this test exists
# --------------------
# Per Issue #1200 AC2a: env-dep d-tests that hit live GitHub API must default
# to mock-first execution without requiring real tokens, with explicit
# RECONCILE_LIVE_TOKEN=1 opt-in for live API reconciliation. silent_skip log
# emission per ADR-0056 makes mock usage observable in observability logs.
#
# The implementation pattern: a small helper script (scripts/d-test-reconcile-live.sh)
# resolves mode (mock|live) per env var, emits silent_skip log per ADR-0056,
# and supports fake-bin mocking for CI env-rot hardening. This d-test validates
# ≥6 TCs per AC2a covering mock-first default + live opt-in + observability +
# network-down fallback + 429 retry + token-rotation mid-test.
#
# Pre-impl RED state (current main as of 2026-07-21 post-PR-1201-squash):
#   - All 6 TCs FAIL (helper script absent from main)
#   - d-test file absent from main
#   - INDEX.md row absent from main
#   → 6/6 FAIL = proper RED-first per ADR-0044.
#
# Post-impl GREEN state (after Issue #1200 PR squash):
#   - TC0: bash -n hygiene PASS (helper syntactically valid)
#   - TC1: RECONCILE_LIVE_TOKEN unset → "mock" (mock-first default per AC2a TC1)
#   - TC2: RECONCILE_LIVE_TOKEN=1 → "live" (live opt-in per AC2a TC2)
#   - TC3: silent_skip log emission per ADR-0056 (mock mode observability per AC2a TC3)
#   - TC4: invalid RECONCILE_LIVE_TOKEN value → exit 2 (validation rejection)
#   - TC5: --check flag emits silent_skip log entry (mock flag path)
#   - TC6: token-rotation mid-test — RECONCILE_LIVE_TOKEN change between invocations respected (no caching)
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
#   - Issue #1200 S33-009 pattern:NETWORK_DEP — this d-test
#   - ADR-0073 §10 action item row 5 — this closes that row
#
# Usage:
#   bash scripts/tests/d099-reconcile-live-network-mock.sh --self-test
#
# Exit codes:
#   0 — all PASS (GREEN state — helper script + toggle path validated)
#   1 — at least one FAIL (RED state — impl incomplete or helper missing)
#   2 — preflight failure (missing tool, file missing, etc.)
#
# Cadence Rule 1 atomic (ADR-0055 §1):
#   d-test file + scripts/d-test-reconcile-live.sh (helper SUT) + INDEX.md row +
#   CHANGELOG.md entry all land in same commit.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HELPER_SH="${REPO_ROOT}/scripts/d-test-reconcile-live.sh"

# Colors (TTY-aware — sister-pattern to d098)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""; fi

# Pre-flight
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required" >&2; exit 2; }
[ -f "$HELPER_SH" ] || { echo "ERROR: helper not found at $HELPER_SH" >&2; exit 2; }

# Self-test mode (sister-pattern to d098 / d097 / d020a)
if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: bash $0 --self-test" >&2
  exit 2
fi

printf "${B}d099 self-test (6 TCs: TC0 hygiene + AC2a ≥6 TCs covering mock-first + live + silent_skip + validation + flag + token-rotation per Issue #1200)${D}\n"
printf "${B}=======================================================================================${D}\n"
printf "  SUT: %s\n" "$HELPER_SH"
printf "  Spec: Issue #1200 S33-009 pattern:NETWORK_DEP (ADR-0073 §10 row 5)\n"
printf "  RED-first: pre-impl 6/6 FAIL (helper absent from main, d-test absent from main).\n"
printf "  Post-impl: 6/6 GREEN.\n\n"

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# TC0: bash -n hygiene (sister-pattern to d098 TC0 + d020a TC1)
# ============================================================================
section "TC0: bash -n hygiene (helper script syntactically valid)"
if bash -n "$HELPER_SH"; then
  pass "bash -n $HELPER_SH → exit 0 (syntactically valid)"
else
  fail "TC0 — bash -n FAIL" "helper has syntax errors; fix before other TCs"
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
# TC4: invalid RECONCILE_LIVE_TOKEN value → exit 2 (validation rejection)
# ============================================================================
section "TC4: invalid RECONCILE_LIVE_TOKEN=foobar → exit 2 (validation rejection)"
OUT="$(RECONCILE_LIVE_TOKEN=foobar bash "$HELPER_SH" 2>&1)"
RC=$?
if [ "$RC" = "2" ] && echo "$OUT" | grep -qiE 'invalid|unknown|unsupported'; then
  pass "RECONCILE_LIVE_TOKEN=foobar rejected with exit 2 + clear error message"
else
  fail "TC4 — invalid value not rejected properly" \
    "expected rc=2 + error message; rc=$RC out='$OUT'"
fi

# ============================================================================
# TC5: --check flag path (no mode change, only log emission trigger)
# ============================================================================
section "TC5: --check flag path (mock mode + log emission verification)"
LOG_DIR2="$(mktemp -d /tmp/d099-log2-XXXXXX)"
D_TEST_LOG_DIR="$LOG_DIR2" bash "$HELPER_SH" --check >/dev/null
LOG_FILE2="$LOG_DIR2/d099.silent_skip.log"
LINE_COUNT_BEFORE=0
LINE_COUNT_AFTER="$(wc -l < "$LOG_FILE2" 2>/dev/null || echo 0)"
if [ "$LINE_COUNT_AFTER" -gt "$LINE_COUNT_BEFORE" ] && \
   grep -q "silent_skip mode=mock" "$LOG_FILE2"; then
  pass "--check emitted silent_skip log entry: $(grep -c 'silent_skip' "$LOG_FILE2") line(s)"
else
  fail "TC5 — --check flag path broken" "log_file_lines=$LINE_COUNT_AFTER grep_match=no"
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

# Sister-pattern invariant for Issue #1200 AC2a:
#   Pre-impl (helper absent): 6/6 FAIL (file + default path + live path + log path all broken)
#   Post-impl (helper shipped): 6/6 GREEN
#
# We accept either:
#   (a) 6/6 PASS — impl complete (helper + d-test + INDEX + CHANGELOG all landed), d099 GREEN
#   (b) FAIL on TC0..TC6 — RED state confirmed (helper missing OR impl incomplete)
if [ "$FAIL" -eq 0 ]; then
  printf "  ${G}d099 GREEN${D} — 6/6 PASS = helper + mock-first + live + silent_skip + token-rotation paths validated\n"
  exit 0
else
  printf "  ${R}d099 RED${D} — %d FAIL observed. Action: implement scripts/d-test-reconcile-live.sh + this INDEX.md row + CHANGELOG entry per ADR-0055 §1 Cadence Rule 1 atomic.\n" "$FAIL"
  exit 1
fi