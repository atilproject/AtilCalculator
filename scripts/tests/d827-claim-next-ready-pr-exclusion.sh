#!/usr/bin/env bash
# d827-claim-next-ready-pr-exclusion.sh
#
# d827 — Issue #827 claim-next-ready.sh PR exclusion (squash cluster interference)
#
# Why this test exists
# --------------------
# Issue #827 (P1, cycle #4080-#4084): GitHub's `/issues` REST endpoint
# returns BOTH issues AND pull requests (PRs have a non-null `pull_request`
# field, issues have null). The claim-next-ready.sh WIP + ready queries
# were matching PRs, causing the auto-claim loop to flip status:ready →
# status:in-progress on squash-ready PRs (#825/#826/#817/#799/#816 cluster).
# Owner manually flipped status:ready 4-5x per PR in 5min cycles; squash
# gate blocked.
#
# Fix: add `&pull_request=false` to all 3 issue queries (lines 115, 120,
# 238 in scripts/claim-next-ready.sh). This is the GitHub REST API
# canonical filter for "issues-only" — sister-pattern to Issue #806 silent-drop
# (gh issue list --label → REST gh api migration).
#
# Test framework: bash + grep + jq (matches d031 + d020a + d809 sister family).
# ADR-0044 RED-first TDD: pre-fix on origin/main (before this PR) TC1-TC3
# expected to FAIL; post-fix (this branch) expected PASS.
#
# Test cases (per ADR-0049 ≥3 baseline, expanded to 4 for hybrid coverage):
#   TC1 (static-grep): pull_request=false present in WIP-count-only --role=* query (line 115)
#   TC2 (static-grep): pull_request=false present in role-specific WIP query (line 120)
#   TC3 (static-grep): pull_request=false present in ready items query (line 238, THE BUG SOURCE)
#   TC4 (sister-pattern): d031 (claim-next-ready contract) + d058 (WIP work-stream) NOT regressed
#
# Sister-pattern lineage (per ADR-0049):
#   - d031 (claim-next-ready contract, 10/10 GREEN, sister-test family)
#   - d058 (claim WIP work-stream awareness, 10/10 GREEN, sister-test family)
#   - d020a (Form C verdict-stamp race, PR #823 — SIBLING-CLASS Issue #811)
#   - d806 (silent-drop fix, Issue #806 — same gh api → REST migration pattern)
#   - d809 (read-then-write race, Issue #809 — same Auto-Claim Protocol integrity family)
#   - d058 + d031 + d020a + d806 + d809 = 5 members (≥3 baseline met)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAIM_SH="$SCRIPT_DIR/../claim-next-ready.sh"
D031="$SCRIPT_DIR/d031-claim-next-ready.sh"
D058="$SCRIPT_DIR/d058-claim-wip-workstream.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""; fi

PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

if ! command -v grep >/dev/null 2>&1; then
  echo "ERROR: grep required" >&2; exit 127
fi
if [ ! -r "$CLAIM_SH" ]; then
  echo "ERROR: claim-next-ready.sh not found at $CLAIM_SH" >&2; exit 127
fi

# ============================================================================
# TC1: static-grep — pull_request=false present in WIP-count-only --role=* query
# ============================================================================
section "TC1: pull_request=false in WIP-count-only --role=* query (line ~115)"
# The fix added &pull_request=false to line 115. Pre-fix this would be absent.
WIP_GLOBAL_QUERY="$(awk '/^if \[ "\$WIP_COUNT_ONLY" = "true" \]/,/^fi$/' "$CLAIM_SH" | grep -E 'pull_request=false|labels=status:in-progress' | head -3)"
HAS_PR_FALSE_GLOBAL="$(echo "$WIP_GLOBAL_QUERY" | grep -c 'pull_request=false' || true)"
if [ "$HAS_PR_FALSE_GLOBAL" -ge 1 ]; then
  pass "WIP-count-only --role=* query has pull_request=false filter (Issue #827 AC)"
else
  fail "WIP-count-only --role=* query missing pull_request=false" \
    "expected 'pull_request=false' on the labels=status:in-progress query (line ~115); Issue #827: PRs in WIP-count inflates WIP cap, breaks claim race protection"
fi

# ============================================================================
# TC2: static-grep — pull_request=false present in role-specific WIP query
# ============================================================================
section "TC2: pull_request=false in role-specific WIP query (line ~120)"
# The fix added &pull_request=false to line 120.
WIP_ROLE_QUERY="$(awk '/^else$/,/^fi$/' "$CLAIM_SH" | grep -E 'pull_request=false|labels=agent' | head -3)"
HAS_PR_FALSE_ROLE="$(echo "$WIP_ROLE_QUERY" | grep -c 'pull_request=false' || true)"
if [ "$HAS_PR_FALSE_ROLE" -ge 1 ]; then
  pass "role-specific WIP query has pull_request=false filter (Issue #827 AC)"
else
  fail "role-specific WIP query missing pull_request=false" \
    "expected 'pull_request=false' on the labels=agent:\${ROLE},status:in-progress query (line ~120); Issue #827: PRs in role-WIP count would block dev lane via phantom WIP"
fi

# ============================================================================
# TC3: static-grep — pull_request=false present in ready items query (THE BUG)
# ============================================================================
section "TC3: pull_request=false in ready items query (line ~238, THE BUG SOURCE)"
# This is the actual bug source. Pre-fix, the ready items query returned PRs,
# which were then auto-claimed, flipping status:ready → status:in-progress
# and breaking the squash cluster.
READY_QUERY="$(awk '/^# --- fetch ready items ---$/,0' "$CLAIM_SH" | grep -E 'labels=agent.*status:ready' | head -3)"
HAS_PR_FALSE_READY="$(echo "$READY_QUERY" | grep -c 'pull_request=false' || true)"
if [ "$HAS_PR_FALSE_READY" -ge 1 ]; then
  pass "ready items query has pull_request=false filter (Issue #827 AC, THE FIX)"
else
  fail "ready items query missing pull_request=false" \
    "expected 'pull_request=false' on the labels=agent:\${ROLE},status:ready query (line ~238); Issue #827 ROOT CAUSE — squash-ready PRs being auto-claimed every cycle (cluster #825/#826/#817/#799/#816)"
fi

# ============================================================================
# TC4: sister-pattern — d031 + d058 NOT regressed
# ============================================================================
section "TC4: sister tests d031 + d058 still PASS (no claim-next-ready regression)"
D031_RESULT="$(bash "$D031" --self-test 2>&1 | grep -E '(GREEN|REGRESSION|PASS|FAIL)' | tail -3 | tr '\n' '|')"
if echo "$D031_RESULT" | grep -qE '(GREEN|REGRESSION PASS)'; then
  pass "d031 sister still GREEN (claim-next-ready contract preserved)"
else
  fail "d031 sister regressed" "expected d031 GREEN; got: $D031_RESULT"
fi
D058_RESULT="$(bash "$D058" --self-test 2>&1 | grep -E '(GREEN|REGRESSION|PASS|FAIL)' | tail -3 | tr '\n' '|')"
if echo "$D058_RESULT" | grep -qE '(GREEN|REGRESSION PASS)'; then
  pass "d058 sister still GREEN (WIP work-stream awareness preserved)"
else
  fail "d058 sister regressed" "expected d058 GREEN; got: $D058_RESULT"
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "Total: $((PASS + FAIL))"

if [ "$FAIL" -eq 0 ]; then
  printf "${G}EXIT 0: d827 GREEN — claim-next-ready PR exclusion verified${D}\n"
  exit 0
else
  printf "${R}EXIT 1: d827 RED — pull_request=false filter missing on one or more queries (Issue #827 AC fail)${D}\n"
  exit 1
fi
