#!/usr/bin/env bash
# d-stall-detect-pr-driven.sh — Issue #1210 dev-stall option (a) PR-driven-only fix d-test.
#
# Why this test exists
# --------------------
# Issue #1183 d-stall-detect detection rule produced a FALSE-NEGATIVE on Issue
# #1180 dev-pane stall (P1, 64h no PR opened) because `issue.updatedAt` was bumped
# by passive auto-claim comments, masking the 24h threshold. Per dev audit @
# 2026-07-23T08:54Z (cmt 5056373219), owner directive selects **option (a)**: drop
# the `issue_stall_hours >= threshold` check, rely solely on PR-driven signal
# (no PR linked OR `last_pr_min >= threshold`). This d-test verifies option (a)
# behavior is wired correctly:
#
#   STALL iff: no PR linked to issue  OR  last_pr_min >= threshold
#   (NOT-stall signals preserved: status:in-review / status:blocked exclusions)
#
# Sister-pattern: scripts/tests/d-stall-detect.sh (Issue #1183 baseline 9 TCs).
# This d-test EXTENDS coverage with TC10-TC15 for the option (a) refactor +
# arch NIT TC10 (STALL_DETECT_AUTO_NOTIFY env gate default off per Issue #1211
# arch verdict). Sister-pattern to cycle ~#3968Q+213 env pollution guard.
#
# RED-first per ADR-0044: pre-impl these TCs FAIL on current
# scripts/agent-stall-detect.sh (which still uses `issue_stall_hours >= threshold`
# AND clause + retains `stall_hours` JSON field + does not have option (a)
# `no PR linked OR last_pr_min >= threshold` rule).
#
# Exit code: 0 = all pass, 1 = at least one fail.
# Run standalone: bash scripts/tests/d-stall-detect-pr-driven.sh [--self-test]
#   --self-test mode verifies the test file itself runs cleanly (used in CI pre-check).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DETECT_SH="$REPO_ROOT/scripts/agent-stall-detect.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi

PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# T1: Detection rule is PR-driven-only — drops issue_stall_hours check
# ============================================================================
section "T1: Detection rule uses PR-driven-only signal (Issue #1210 option a)"
# AFTER (Issue #1210): STALL iff `no PR linked OR last_pr_min >= threshold`
# Verify: detection rule does NOT have `issue_stall_hours.*-ge.*THRESHOLD_HOURS`
# nested AND clause. The current impl uses BOTH issue_stall_hours AND last_pr_min
# which produces false-negative on Issue #1180 pattern.
if [ -f "$DETECT_SH" ] && \
   ! grep -Eq 'if\s*\[\s*"\$issue_stall_hours"\s*-ge\s*"\$THRESHOLD_HOURS"\s*\]' "$DETECT_SH"; then
  pass "issue_stall_hours >= threshold AND clause REMOVED (option a PR-driven-only rule wired)"
else
  fail "issue_stall_hours check still present" "expected: STALL iff (no PR linked OR last_pr_min >= threshold), no issue_stall_hours AND clause — Issue #1210 option a fix"
fi

# ============================================================================
# T2: Issue #1180 pattern (no PR linked, regardless of comment activity age) — STALL
# ============================================================================
section "T2: Issue #1180 pattern — no PR linked → STALL (false-negative fix)"
# Issue #1180 had no PR opened for 64h; passive auto-claim comment bumped
# updatedAt, masking the stall. Option (a) fix: no PR linked = STALL regardless
# of issue.updatedAt. Verify: rule has STALL check that is NOT nested inside
# `if [ "$issue_stall_hours" -ge` — must be top-level (independent of staleness).
# After option (a): last_pr_min == -1 OR last_pr_min >= threshold → STALL.
# RED-first: current impl has `last_pr_min -eq -1` nested inside issue_stall_hours check.
if [ -f "$DETECT_SH" ] && \
   ! grep -B1 'last_pr_min.*-eq.*-1' "$DETECT_SH" 2>/dev/null | grep -q 'issue_stall_hours.*-ge'; then
  pass "no-PR-linked branch is top-level (Issue #1180 false-negative fix wired)"
else
  fail "no-PR-linked check still nested inside issue_stall_hours check" "expected: STALL rule top-level, no-PR-linked branch independent of issue_stall_hours — Issue #1180 false-negative fix per Issue #1210 option a"
fi

# ============================================================================
# T3: status:in-review edge case preserved (NOT stalled — PR up + awaiting verdict)
# ============================================================================
section "T3: status:in-review edge case preserved (sister to d-stall-detect T5)"
if [ -f "$DETECT_SH" ] && grep -Eq 'has_in_review|status:in-review' "$DETECT_SH"; then
  pass "status:in-review edge case preserved (PR up + awaiting verdict = NOT stalled)"
else
  fail "status:in-review edge case missing" "expected: skip stall detection for issues with status:in-review label — sister to d-stall-detect T5"
fi

# ============================================================================
# T4: status:blocked edge case preserved (NOT stalled — legitimate block)
# ============================================================================
section "T4: status:blocked edge case preserved (sister to d-stall-detect T6)"
if [ -f "$DETECT_SH" ] && grep -Eq 'has_blocked|status:blocked' "$DETECT_SH"; then
  pass "status:blocked edge case preserved (legitimate block = NOT stalled)"
else
  fail "status:blocked edge case missing" "expected: skip stall detection for issues with status:blocked label — sister to d-stall-detect T6"
fi

# ============================================================================
# T5: Stall JSON output drops `stall_hours` field — keeps `last_pr_min` + `linked_pr`
# ============================================================================
section "T5: Stall JSON output drops stall_hours field (Issue #1210 AC3)"
# Per Issue #1210: drop `issue_stall_hours` field from stall JSON output,
# keep `last_pr_min` + `linked_pr`. Note: current impl names it `stall_hours`
# in JSON (not `issue_stall_hours`) but it's the same field semantically.
# Verify: stall_hours is NOT in the JSON .+ array template.
if [ -f "$DETECT_SH" ] && \
   ! grep -Eq 'stall_hours:.*\$sh|\.stall_hours' "$DETECT_SH"; then
  pass "stall_hours field dropped from JSON output (last_pr_min + linked_pr retained)"
else
  fail "stall_hours field still in JSON output" "expected: stall JSON drops stall_hours, keeps last_pr_min + linked_pr — Issue #1210 AC3"
fi

# ============================================================================
# T6 (arch NIT TC10): STALL_DETECT_AUTO_NOTIFY env gate default off + fires when set
# ============================================================================
section "T6 (arch NIT TC10): STALL_DETECT_AUTO_NOTIFY env gate default off"
# Per arch verdict on Issue #1211 (cmt 5058101861 NIT-1): verify d-stall-detect
# is silent when STALL_DETECT_AUTO_NOTIFY is UNSET (default), peer-poke fires
# when STALL_DETECT_AUTO_NOTIFY=1. Sister to wip-idle AUTO_NOTIFY pattern.
if [ -f "$DETECT_SH" ] && \
   grep -Eq 'STALL_DETECT_AUTO_NOTIFY.*:-0|STALL_DETECT_AUTO_NOTIFY.*=.*1' "$DETECT_SH"; then
  pass "STALL_DETECT_AUTO_NOTIFY env gate wired (default off, opt-in)"
else
  fail "STALL_DETECT_AUTO_NOTIFY env gate missing" "expected: STALL_DETECT_AUTO_NOTIFY:-0 default + =1 opt-in — arch NIT-1 on Issue #1211, sister to wip-idle AUTO_NOTIFY"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
printf "${B}==== Summary ====${D}\n"
printf "  PASS: ${G}%d${D}\n" "$PASS"
printf "  FAIL: ${R}%d${D}\n" "$FAIL"

if [ "$FAIL" -eq 0 ]; then
  printf "${G}${B}ALL TESTS PASSED${D}\n"
  exit 0
else
  printf "${R}${B}TESTS FAILED (RED-first expected — impl pending)${D}\n"
  exit 1
fi
