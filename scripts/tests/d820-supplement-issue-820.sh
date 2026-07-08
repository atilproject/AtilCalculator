#!/usr/bin/env bash
# d820 — ADR-0010 supplement (Issue #820 P0 INCIDENT) regression anchor
# ARCH LANE — see Issue #820 + cmt 4881824175 + cmt 4881832463
#
# Marker reformat (Issue #889 Option 1, 2026-07-08): TC1:..TC11: markers
# prepended to each pass/fail message so audit-dtests.sh recognises them
# via the ADR-0049 regex. Functional contract unchanged (11/11 PASS preserved).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADR_0010="$REPO_ROOT/docs/decisions/ADR-0010-per-project-watchers.md"
PASS=0; FAIL=0; declare -a FAILURES
pass() { echo "  ✓ $*"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $*"; FAIL=$((FAIL + 1)); FAILURES+=("$*"); }
echo "==== d820 — ADR-0010 supplement (Issue #820) ===="
echo "  11 TCs (TC1 §Supp-X preconditions codification + TC2 dbus-user-session+loginctl+XDG_RUNTIME_DIR composite + TC3 §Supp-Y three-class detection + TC4 Branch A/B/C composite + TC5 Branch C HARD FAIL exit 7 RCA-14 preserved + TC6 §Supp-W silent_skip observability + TC7 adr-0010-supplement-silent-skip audit marker + TC8 ADR-0045 lens d anchoring + TC9 §Supp-Runner three options + TC10 Option A RECOMMENDED + TC11 Option C EXPLICITLY AVOIDED)"
grep -q "§Supp-X" "$ADR_0010" && pass "TC1: §Supp-X section present" || fail "TC1: §Supp-X MISSING"
(grep -q "dbus-user-session" "$ADR_0010" && grep -q "loginctl enable-linger" "$ADR_0010" && grep -q "XDG_RUNTIME_DIR" "$ADR_0010") && pass "TC2: Three preconditions (dbus-user-session + linger + XDG_RUNTIME_DIR)" || fail "TC2: Three preconditions incomplete"
grep -q "§Supp-Y" "$ADR_0010" && pass "TC3: §Supp-Y section present" || fail "TC3: §Supp-Y MISSING"
(grep -q "Branch A" "$ADR_0010" && grep -q "Branch B" "$ADR_0010" && grep -q "Branch C" "$ADR_0010") && pass "TC4: Three branches A/B/C documented" || fail "TC4: Three branches incomplete"
grep -q "HARD FAIL exit 7" "$ADR_0010" && pass "TC5: Branch C HARD FAIL exit 7 (RCA-14 preserved)" || fail "TC5: Branch C HARD FAIL exit 7 not documented"
grep -q "§Supp-W" "$ADR_0010" && pass "TC6: §Supp-W section present" || fail "TC6: §Supp-W MISSING"
grep -q "adr-0010-supplement-silent-skip" "$ADR_0010" && pass "TC7: Audit marker pattern documented" || fail "TC7: Audit marker missing"
grep -q "ADR-0045 lens d" "$ADR_0010" && pass "TC8: Lensed under ADR-0045 lens d" || fail "TC8: ADR-0045 lens d reference missing"
grep -q "§Supp-Runner" "$ADR_0010" && pass "TC9: §Supp-Runner section present" || fail "TC9: §Supp-Runner MISSING"
grep -q "RECOMMENDED" "$ADR_0010" && pass "TC10: Option A recommended primary" || fail "TC10: Option A canonical recommendation not explicit"
grep -q "EXPLICITLY AVOIDED" "$ADR_0010" && pass "TC11: Option C explicitly avoided" || fail "TC11: Option C avoidance not explicit"
echo "Passed: $PASS / Failed: $FAIL"
[[ $FAIL -gt 0 ]] && exit 1
echo "All d820 TCs PASS"
exit 0
