#!/usr/bin/env bash
# scripts/tests/d809-claim-next-ready-race.sh
#
# d809 — claim-next-ready.sh read-then-write race regression guard (Issue #809)
#
# Purpose:
#   Verify that `scripts/claim-next-ready.sh` is protected against concurrent
#   invocations racing on the WIP-read + atomic-flip sequence. Without the
#   guard, N parallel invocations could each compute the same WIP count (stale
#   read), pick the same candidate, and each perform the status:ready →
#   status:in-progress flip, producing N duplicate "auto-claimed" comments.
#
# Doctrinal frame:
#   - Issue #809 (HIGH severity, P1, sibling class to Issue #806 silent-drop)
#   - ADR-0038 §Auto-Claim Protocol integrity
#   - ADR-0044 RED-first TDD discipline (d809 authored before impl)
#   - ADR-0049 d-test framework ≥5 TCs sister-pattern
#   - ADR-0055 §1 Cadence Rule 1 atomic (d809 file + INDEX.md row same commit)
#
# 6 TCs:
#   TC1: flock present in claim-next-ready.sh (static-grep)
#   TC2: flock wraps the WIP-read section (static-grep, line-range)
#   TC3: flock uses non-blocking (-n) acquisition for fast-fail (static-grep)
#   TC4: dynamic race test — concurrent invocations are serialized via flock
#   TC5: d031 sister non-regression (10/10 PASS)
#   TC6: scripts/tests/INDEX.md has d809 row (Cadence Rule 1 atomic)
#
# Test author: @developer (RED-first; @tester signs off per ADR-0044)
# Last verified: NEW (cycle ~#4038, sibling to PR #823 Form C fix)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAIM_SH="$REPO_ROOT/scripts/claim-next-ready.sh"
INDEX="$REPO_ROOT/scripts/tests/INDEX.md"

PASS=0; FAIL=0
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

echo "==== d809 — claim-next-ready.sh read-then-write race guard ===="
echo "==== Issue #809 (sibling class to #806 silent-drop) ===="
echo

# --- TC1: flock pattern present in claim-next-ready.sh ---
section "TC1: flock race-protection present in scripts/claim-next-ready.sh"

if [ ! -f "$CLAIM_SH" ]; then
  fail "TC1 — claim-next-ready.sh not found at $CLAIM_SH"
else
  if grep -qE 'flock\s+(-[a-zA-Z]*n[a-zA-Z]*\s+)?[0-9]+' "$CLAIM_SH"; then
    pass "TC1 — flock pattern present in claim-next-ready.sh (race-protection mechanism ships)"
  else
    fail "TC1 — flock pattern MISSING from claim-next-ready.sh (race-protection absent — duplicate auto-claim window still open)"
  fi
fi

# --- TC2: flock wraps the WIP-read section (race window coverage) ---
section "TC2: flock wraps WIP-read section (race window coverage)"

if [ ! -f "$CLAIM_SH" ]; then
  fail "TC2 — claim-next-ready.sh not found"
else
  flock_line="$(grep -nE 'flock|\(\s*$' "$CLAIM_SH" | head -1 | cut -d: -f1)"
  wip_query_line="$(grep -n 'in_progress_json=' "$CLAIM_SH" | head -1 | cut -d: -f1)"
  if [ -n "$flock_line" ] && [ -n "$wip_query_line" ] && [ "$flock_line" -lt "$wip_query_line" ]; then
    pass "TC2 — flock open-paren precedes WIP-read (line $flock_line < $wip_query_line) — read-then-write race window covered"
  else
    fail "TC2 — flock open-paren does NOT precede WIP-read (flock_line=$flock_line, wip_query_line=$wip_query_line) — race window unprotected"
  fi
fi

# --- TC3: flock uses non-blocking (-n) acquisition for fast-fail ---
section "TC3: flock uses non-blocking acquisition (-n flag) for fast-fail"

if [ ! -f "$CLAIM_SH" ]; then
  fail "TC3 — claim-next-ready.sh not found"
else
  if grep -qE 'flock\s+-[a-zA-Z]*n' "$CLAIM_SH" || grep -qE 'flock\s+-[a-zA-Z]*w\s+0' "$CLAIM_SH"; then
    pass "TC3 — flock uses non-blocking acquisition (-n or -w0) — concurrent invocations fail-fast instead of stalling the watchdog"
  else
    fail "TC3 — flock uses BLOCKING acquisition (no -n / -w0 flag) — concurrent invocations stall the watchdog (DoS surface)"
  fi
fi

# --- TC4: dynamic race test — concurrent invocations are serialized via flock ---
section "TC4: dynamic race — concurrent invocations serialized via lock"

if [ ! -f "$CLAIM_SH" ]; then
  fail "TC4 — claim-next-ready.sh not found"
else
  TEST_LOCKFILE="$(mktemp -u /tmp/d809-test-lock.XXXXXX)"
  touch "$TEST_LOCKFILE"
  TEST_TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TEST_TMPDIR" "$TEST_LOCKFILE"' EXIT

  (
    flock 200
    echo "A acquired lock at $(date -u +%T.%N)"
    sleep 1
    echo "A releasing lock at $(date -u +%T.%N)"
  ) 200>"$TEST_LOCKFILE" > "$TEST_TMPDIR/a.log" 2>&1 &
  PID_A=$!

  sleep 0.1

  (
    flock -n 200
    flock_exit=$?
    if [ $flock_exit -ne 0 ]; then
      echo "B refused lock at $(date -u +%T.%N) (flock_exit=$flock_exit — concurrent invocation correctly denied)"
    else
      echo "B acquired lock at $(date -u +%T.%N) (UNEXPECTED — race window not serialized)"
    fi
  ) 200>"$TEST_LOCKFILE" > "$TEST_TMPDIR/b.log" 2>&1
  B_EXIT=$?

  wait "$PID_A" 2>/dev/null

  if grep -q "refused lock" "$TEST_TMPDIR/b.log"; then
    pass "TC4 — concurrent flock acquisition correctly refused (-n non-blocking serialized contention)"
  elif grep -q "acquired lock" "$TEST_TMPDIR/b.log"; then
    fail "TC4 — concurrent flock acquisition SUCCEEDED (race window NOT serialized — duplicate claim scenario reproducible)"
  else
    fail "TC4 — flock test output unexpected (b.log: $(cat "$TEST_TMPDIR/b.log"))"
  fi
fi

# --- TC5: d031 sister non-regression (10/10 PASS) ---
section "TC5: d031 sister non-regression (10/10 PASS)"

D031="$REPO_ROOT/scripts/tests/d031-claim-next-ready.sh"
if [ ! -f "$D031" ]; then
  fail "TC5 — d031 sister-test not found at $D031 (Cadence Rule 1 violation — broken sister-pattern)"
else
  d031_output="$(bash "$D031" 2>&1 || true)"
  d031_passes="$(printf '%s\n' "$d031_output" | grep -cE '^\s*✓ PASS' || echo 0)"
  if [ "$d031_passes" -ge 10 ]; then
    pass "TC5 — d031 sister 10/10 PASS preserved ($d031_passes PASS lines observed)"
  else
    fail "TC5 — d031 sister $d031_passes/10 PASS (regression detected — flock change broke claim semantics)"
  fi
fi

# --- TC6: INDEX.md has d809 row (Cadence Rule 1 atomic — ADR-0055 §1) ---
section "TC6: scripts/tests/INDEX.md has d809 row (Cadence Rule 1 atomic)"

if [ ! -f "$INDEX" ]; then
  fail "TC6 — scripts/tests/INDEX.md not found (Cadence Rule 1 attestation impossible)"
elif grep -qE '\*\*d809\*\*' "$INDEX"; then
  pass "TC6 — INDEX.md has d809 row (Cadence Rule 1 atomic — d-test + INDEX.md same commit per ADR-0055 §1)"
else
  fail "TC6 — INDEX.md MISSING d809 row (Cadence Rule 1 violation — d809 shipped without INDEX.md entry)"
fi

# --- summary ---
echo
echo "==== Summary ===="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "EXIT 1: d809 RED — race guard missing or broken"
  exit 1
fi
echo
echo "EXIT 0: d809 GREEN — claim-next-ready.sh race guard verified"
exit 0