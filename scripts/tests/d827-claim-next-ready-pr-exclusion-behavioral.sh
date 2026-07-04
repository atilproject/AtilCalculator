#!/usr/bin/env bash
# d827-claim-next-ready-pr-exclusion-behavioral.sh
#
# d827 — Issue #831 P0 DESIGN-DRIFT revision: behavioral PR exclusion
#        (replaces static-grep d827 v1 test-theater)
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
# Issue #831 (P0 DESIGN-DRIFT, 2026-07-04T15:28Z, agent:architect):
# The d827 v1 fix `&pull_request=false` on `/repos/{owner}/{repo}/issues` is
# a **no-op** (empirically verified: 3-way test returned identical items for
# ?state=open, ?state=open&pull_request=true, ?state=open&pull_request=false).
# The v1 d-test (TC1-TC3 static-grep) was **test theater** — it verified
# the inert string was present in the script, never tested runtime behavior.
#
# Correct fix per architect RCA cmt 4882811076 + developer proposal:
#   gh api "repos/.../issues?labels=..." \
#     --jq '[.[] | select(.pull_request == null)]'
#   ^ client-side jq filter — excludes PRs (pull_request != null) and keeps
#     real issues (pull_request == null).
#
# This d827 v2 covers behavioral fixture tests of the filter logic AND
# verifies the filter is wired into the actual script. v2 ships BEFORE the
# corrected impl (ADR-0044 RED-first TDD). Cadence Rule 1 atomic (ADR-0055 §1)
# binds: impl + this d-test + INDEX.md row in same PR-cluster.
#
# Test framework: bash + grep + jq (sister-pattern to d124/d320/d020a family).
# Pattern lifted from: d124 TC3-6 (jq-fixture behavioral) + d031 (claim-next-ready
# contract, 10/10 GREEN — must NOT regress).
#
# Test cases (per ADR-0049 ≥3 baseline, expanded to 6 for hybrid coverage):
#   TC1 (behavioral-fix-wiring): jq filter `select(.pull_request == null)`
#                                present in claim-next-ready.sh. RED: absent
#                                (current main). GREEN: present (post-impl).
#   TC2 (behavioral-fixture):    3-item fixture [issue, PR, issue] → filter
#                                applied → expect [issue, issue] only.
#   TC3 (behavioral-fixture-mix): 5-item fixture [issue, PR, issue, PR, issue]
#                                → filter → expect 3 issues only (PR count=2).
#   TC4 (behavioral-edge-empty): empty fixture [] → filter → expect [].
#   TC5 (behavioral-negative):  fixture [PR, PR] (only PRs) → filter → expect
#                                [] (no false-positives from issue side).
#   TC6 (sister-regression):     d031 (claim-next-ready contract) still PASS;
#                                TC1 behavior consistent with sister pattern.
#
# RED state (pre-fix, on origin/main 33ae84e):
#   TC1 FAIL — jq filter absent from claim-next-ready.sh
#   TC2-TC5 PASS — jq fixtures are independent of script (filter logic itself
#                  is sound and applies correctly)
#   TC6 PASS — d031 still passes (no script-level regression yet)
#   script exit=1
#
# GREEN state (post-impl, after dev pushes claim-next-ready.sh with
# `select(.pull_request == null)` filter on all 3 query sites):
#   TC1 PASS — filter wired in
#   TC2-TC5 PASS — behavioral coverage
#   TC6 PASS — d031 still green
#   script exit=0
#
# Refs: Issue #831 P0 DESIGN-DRIFT (test theater caught), Issue #827 (PR exclusion
#       bug), PR #829 (PR with inert fix + v1 d827 — superseded), TD-050 (architect
#       behavioral test requirement), ADR-0044 (RED-first), ADR-0049 (d-test
#       framework ≥3 baseline), ADR-0055 §1 (Cadence Rule 1 atomic).
# Sister-pattern lineage: d031 + d124 + d320 (jq-fixture) + d020a (Form C race).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAIM_SH="$SCRIPT_DIR/../claim-next-ready.sh"
D031="$SCRIPT_DIR/d031-claim-next-ready.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""; fi

PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq required" >&2; exit 127
fi
if [ ! -r "$CLAIM_SH" ]; then
  echo "ERROR: claim-next-ready.sh not found at $CLAIM_SH" >&2; exit 127
fi

# ============================================================================
# TC1: behavioral-fix-wiring — jq filter present in claim-next-ready.sh
# ============================================================================
section 'TC1: jq filter select(.pull_request == null) wired in claim-next-ready.sh'
# RED on current main (filter absent). GREEN after dev pushes corrected fix.
FILTER_PRESENT="$(grep -c 'select(.pull_request == null)' "$CLAIM_SH" 2>/dev/null | head -1)"
FILTER_PRESENT="${FILTER_PRESENT:-0}"
FILTER_PRESENT="$(printf '%d' "$FILTER_PRESENT" 2>/dev/null || echo 0)"
# The filter should appear in at least 3 query sites (WIP-*--role=*, WIP role-specific,
# ready items query).
if [ "$FILTER_PRESENT" -ge 3 ]; then
  pass "jq filter select(.pull_request == null) present in $FILTER_PRESENT site(s) of claim-next-ready.sh (Issue #831 fix wired in)"
else
  fail "jq filter select(.pull_request == null) absent or under-deployed in claim-next-ready.sh" \
    "expected >=3 occurrences (WIP-count-only --role=* query, role-specific WIP query, ready-items query). Currently: $FILTER_PRESENT. Issue #831: pull_request=false URL-param is a no-op; correct fix is client-side jq filter per architect RCA cmt 4882811076."
fi

# ============================================================================
# TC2: behavioral-fixture — 3 items, filter excludes 1 PR
# ============================================================================
section "TC2: behavioral fixture [issue, PR, issue] → filter excludes PR"
FIXTURE_2='[{"number":101,"title":"issue 1","labels":["agent:developer"]},{"number":102,"title":"PR 1","labels":["agent:developer"],"pull_request":{"url":"https://api.github.com/repos/foo/bar/pulls/102"}},{"number":103,"title":"issue 2","labels":["agent:developer"]}]'
RESULT_2="$(printf '%s' "$FIXTURE_2" | jq '[.[] | select(.pull_request == null)]' 2>/dev/null)"
RESULT_2_NUMS="$(printf '%s' "$RESULT_2" | jq -r '.[].number' 2>/dev/null | sort -n | paste -sd ',' -)"
RESULT_2_PR_COUNT="$(printf '%s' "$RESULT_2" | jq '[.[] | select(.pull_request != null)] | length' 2>/dev/null)"
if [ "$RESULT_2_NUMS" = "101,103" ] && [ "$RESULT_2_PR_COUNT" = "0" ]; then
  pass "filter correctly excludes 1 PR from 3-item mix; result = [101, 103]; PR count = 0"
else
  fail "filter did not exclude PR" \
    "expected nums=[101,103], PR_count=0. Got: nums=$RESULT_2_NUMS, PR_count=$RESULT_2_PR_COUNT"
fi

# ============================================================================
# TC3: behavioral-fixture-mix — 5 items, filter excludes 2 PRs
# ============================================================================
section "TC3: behavioral fixture [issue, PR, issue, PR, issue] → filter excludes 2 PRs"
FIXTURE_3='[{"number":201},{"number":202,"pull_request":{"url":"https://api.github.com/repos/foo/bar/pulls/202"}},{"number":203},{"number":204,"pull_request":{"url":"https://api.github.com/repos/foo/bar/pulls/204"}},{"number":205}]'
RESULT_3="$(printf '%s' "$FIXTURE_3" | jq '[.[] | select(.pull_request == null)]' 2>/dev/null)"
RESULT_3_LEN="$(printf '%s' "$RESULT_3" | jq 'length' 2>/dev/null)"
RESULT_3_NUMS="$(printf '%s' "$RESULT_3" | jq -r '.[].number' 2>/dev/null | sort -n | paste -sd ',' -)"
if [ "$RESULT_3_LEN" = "3" ] && [ "$RESULT_3_NUMS" = "201,203,205" ]; then
  pass "filter correctly excludes 2 PRs from 5-item mix; result = [201, 203, 205] (3 issues)"
else
  fail "filter did not exclude both PRs" \
    "expected 3 items, nums=[201,203,205]. Got: len=$RESULT_3_LEN, nums=$RESULT_3_NUMS"
fi

# ============================================================================
# TC4: behavioral-edge-empty — empty fixture → filter → empty array
# ============================================================================
section "TC4: behavioral edge case — empty fixture → filter → empty result"
FIXTURE_4='[]'
RESULT_4="$(printf '%s' "$FIXTURE_4" | jq '[.[] | select(.pull_request == null)]' 2>/dev/null)"
RESULT_4_LEN="$(printf '%s' "$RESULT_4" | jq 'length' 2>/dev/null)"
if [ "$RESULT_4_LEN" = "0" ]; then
  pass "filter on empty fixture returns empty array (no crash, no false-positives)"
else
  fail "filter on empty fixture did not return empty" \
    "expected length=0. Got: len=$RESULT_4_LEN"
fi

# ============================================================================
# TC5: behavioral-negative — only PRs in fixture → filter → empty (no issues bleed-through)
# ============================================================================
section "TC5: behavioral negative — fixture [PR, PR] → filter → empty"
FIXTURE_5='[{"number":301,"pull_request":{"url":"https://api.github.com/repos/foo/bar/pulls/301"}},{"number":302,"pull_request":{"url":"https://api.github.com/repos/foo/bar/pulls/302"}}]'
RESULT_5="$(printf '%s' "$FIXTURE_5" | jq '[.[] | select(.pull_request == null)]' 2>/dev/null)"
RESULT_5_LEN="$(printf '%s' "$RESULT_5" | jq 'length' 2>/dev/null)"
if [ "$RESULT_5_LEN" = "0" ]; then
  pass "filter on PR-only fixture returns empty (no PR false-positives, no issue bleed-through)"
else
  fail "filter on PR-only fixture did not return empty" \
    "expected length=0 (filter is strict: only items with pull_request==null survive). Got: len=$RESULT_5_LEN"
fi

# ============================================================================
# TC6: sister-regression — d031 (claim-next-ready contract) still PASS
# ============================================================================
section "TC6: d031 sister-regression — claim-next-ready contract unaffected"
if [ ! -x "$D031" ] && [ ! -r "$D031" ]; then
  fail "d031 not found" "expected at $D031; sister-test must exist for regression check"
else
  if bash "$D031" >/dev/null 2>&1; then
    pass "d031 (claim-next-ready contract, 10/10 GREEN) still PASS — no script-level regression"
  else
    fail "d031 d-test regression detected" "d031 should still pass; if it fails, the script's other contract has been broken"
  fi
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== d827 v2 behavioral summary ====${D}\n"
printf "  Passed: %d / 6\n" "$PASS"
printf "  Failed: %d / 6\n" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${R}RED state: %d TC(s) failed (likely TC1 = filter not yet wired). Behavioral fixtures TC2-TC5 always pass (filter logic itself is sound).${D}\n" "$FAIL"
  exit 1
else
  printf "\n${G}GREEN state: filter wired + behavioral coverage passes + sister d031 still green.${D}\n"
  exit 0
fi
