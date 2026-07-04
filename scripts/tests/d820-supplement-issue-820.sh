#!/usr/bin/env bash
# d820 — ADR-0010 supplement (Issue #820 P0 INCIDENT) regression anchor
# ARCH LANE — see Issue #820 + cmt 4881824175 + cmt 4881832463
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADR_0010="$REPO_ROOT/docs/decisions/ADR-0010-per-project-watchers.md"
PASS=0; FAIL=0; declare -a FAILURES
pass() { echo "  ✓ $*"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $*"; FAIL=$((FAIL + 1)); FAILURES+=("$*"); }
echo "==== d820 — ADR-0010 supplement (Issue #820) ===="
grep -q "§Supp-X" "$ADR_0010" && pass "§Supp-X section present" || fail "§Supp-X MISSING"
(grep -q "dbus-user-session" "$ADR_0010" && grep -q "loginctl enable-linger" "$ADR_0010" && grep -q "XDG_RUNTIME_DIR" "$ADR_0010") && pass "Three preconditions (dbus-user-session + linger + XDG_RUNTIME_DIR)" || fail "Three preconditions incomplete"
grep -q "§Supp-Y" "$ADR_0010" && pass "§Supp-Y section present" || fail "§Supp-Y MISSING"
(grep -q "Branch A" "$ADR_0010" && grep -q "Branch B" "$ADR_0010" && grep -q "Branch C" "$ADR_0010") && pass "Three branches A/B/C documented" || fail "Three branches incomplete"
grep -q "HARD FAIL exit 7" "$ADR_0010" && pass "Branch C HARD FAIL exit 7 (RCA-14 preserved)" || fail "Branch C HARD FAIL exit 7 not documented"
grep -q "§Supp-W" "$ADR_0010" && pass "§Supp-W section present" || fail "§Supp-W MISSING"
grep -q "adr-0010-supplement-silent-skip" "$ADR_0010" && pass "Audit marker pattern documented" || fail "Audit marker missing"
grep -q "ADR-0045 lens d" "$ADR_0010" && pass "Lensed under ADR-0045 lens d" || fail "ADR-0045 lens d reference missing"
grep -q "§Supp-Runner" "$ADR_0010" && pass "§Supp-Runner section present" || fail "§Supp-Runner MISSING"
grep -q "RECOMMENDED" "$ADR_0010" && pass "Option A recommended primary" || fail "Option A canonical recommendation not explicit"
grep -q "EXPLICITLY AVOIDED" "$ADR_0010" && pass "Option C explicitly avoided" || fail "Option C avoidance not explicit"
echo "Passed: $PASS / Failed: $FAIL"
[[ $FAIL -gt 0 ]] && exit 1
echo "All d820 TCs PASS"
exit 0
