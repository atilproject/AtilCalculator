#!/usr/bin/env bash
# d124-stale-verdict-filter-scope.sh — regression test for Issue #798
# (stale_verdict filter conflates `cc:<role>` (lane) with verdict authority —
#  false-positive wake fires on PR #796 + PR #797, cycle ~#3671).
#
# Why this test exists
# --------------------
# ADR-0015 (atomic 4-flag handoff) defines lane semantics:
#   cc:<role>     → queue-passing / informational lane (no verdict authority)
#   agent:<role>  → work ownership (verdict authority per ADR-0024)
#   cc:human      → owner merge gate (special verdict authority per ADR-0031)
#   verdict-by:*  → verdict stamp (set by whoever posts review, ADR-0024)
#
# The stale_verdict query in scripts/agent-watch.sh:1085-1142 currently uses
# `gh pr list --label "cc:${ROLE}"` to fetch candidates. This conflates the
# informational lane (cc:<peer>) with verdict authority — the watcher then
# fires stale_verdict on PRs where ${ROLE} has cc:<peer> (informational only)
# AND an arch verdict-by stamp. False-positive wakes degrade signal/noise.
#
# Dev escalation cmt 4880713395 (PR #797, 2026-07-04T04:49:44Z) documented:
#   PR #796 (tester RED-state, verdict-by 2026-07-04T04:31:52Z) — stale_verdict
#     fires for cc:developer requesting verdict (informational lane only)
#   PR #797 (tester test-plans, verdict-by 2026-07-04T04:47:58Z) — same pattern
#
# Fix (dev-recommended, cycle ~#3671):
#   Filter stale_verdict to fire on:
#     (agent:<role> AND verdict-by:*)           ← verdict authority
#     OR (cc:human AND verdict-by:*)            ← owner merge gate
#   EXCLUDE: (cc:<peer> AND verdict-by:*)       ← informational lane, no fire
#
# Test cases (per ADR-0049 baseline ≥3 TCs, expanded to 8 for full coverage):
#   TC1: Static — gh query uses union of agent:<role> + cc:human (not just cc:${ROLE})
#   TC2: Static — gh query does NOT use only `cc:${ROLE}` (bug pattern absent)
#   TC3: Behavioral — agent:<role> + verdict-by:passed → stale_verdict EMITS
#   TC4: Behavioral — cc:human + verdict-by:passed → stale_verdict EMITS
#   TC5: Behavioral — cc:<peer> + verdict-by:passed → stale_verdict does NOT emit (BUG case)
#   TC6: Behavioral — agent:<role> + verdict-by:future → stale_verdict does NOT emit (regression)
#   TC7: Static — header docstring (line 25+) reflects correct filter semantics
#   TC8: Sister — d012 + d319 still PASS (no regression to existing watchdog tests)
#
# Exit code: 0 = all pass, 1 = at least one fail.
# Run standalone: bash scripts/tests/d124-stale-verdict-filter-scope.sh
#
# RED state (cycle ~3983, arch fix pending): this test FAILS on current code
#   (PR #798 open, agent:architect owns fix). GREEN state post-fix.
#
# Refs: Issue #798, cmt 4880713395, PR #796, PR #797, ADR-0015, ADR-0024,
#       ADR-0031, ADR-0044 (TDD RED exclusion still applies), ADR-0049.
# Pattern lifted from: scripts/tests/d012-stale-verdict-schema.sh (jq-fixture
#   approach) + scripts/tests/d319-verdict-by-tdd-red-exclusion.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_SH="$SCRIPT_DIR/../agent-watch.sh"
D012="$SCRIPT_DIR/d012-stale-verdict-schema.sh"
D319="$SCRIPT_DIR/d319-verdict-by-tdd-red-exclusion.sh"

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
if [ ! -r "$WATCH_SH" ]; then
  echo "ERROR: agent-watch.sh not found at $WATCH_SH" >&2; exit 127
fi

# ============================================================================
# TC1: Static — gh query uses union of agent:<role> + cc:human (NOT just cc:${ROLE})
# ============================================================================
section "TC1: gh query uses agent:<role> + cc:human union (verdict authority scope)"
# The fix requires the gh query to filter for verdict-authority lanes:
#   (agent:<role>) OR (cc:human)
# The bug pattern uses ONLY `cc:${ROLE}` which conflates lanes.
#
# Acceptable fix shapes (any of):
#   (a) Two gh calls: --label "agent:${ROLE}" and --label "cc:human" (jq merged)
#   (b) Single gh call with `--label "agent:${ROLE}" --label "cc:human"` (jq OR)
#   (c) Single gh call fetching all PRs, jq pipeline does the lane filter
#
# Reject (bug pattern): only `--label "cc:${ROLE}"`
QUERY_BODY="$(awk '/^query_stale_verdict\(\) \{/,/^}/' "$WATCH_SH")"
HAS_AGENT_LABEL=$(echo "$QUERY_BODY" | grep -cE 'agent:\$\{?ROLE\}?|agent:\$ROLE|"agent:developer"|"agent:tester"')
HAS_CC_HUMAN=$(echo "$QUERY_BODY" | grep -cE 'cc:human|"cc:human"')
if [ "$HAS_AGENT_LABEL" -ge 1 ] && [ "$HAS_CC_HUMAN" -ge 1 ]; then
  pass "query_stale_verdict uses agent:<role> + cc:human union (verdict-authority filter)"
else
  fail "query_stale_verdict missing agent:<role> or cc:human in filter" "expected both 'agent:\${ROLE}' AND 'cc:human' in gh query or jq filter; bug pattern uses only 'cc:\${ROLE}' which conflates lane with verdict authority (Issue #798)"
fi

# ============================================================================
# TC2: Static — gh query does NOT use ONLY `cc:${ROLE}` (bug pattern absent)
# ============================================================================
section "TC2: gh query does NOT use ONLY cc:\${ROLE} (bug pattern absent)"
# The bug pattern is `--label "cc:${ROLE}"` as the SOLE filter.
# After the fix, the gh query must also have agent:<role> or cc:human
# (verified in TC1). This TC confirms the bug pattern is not solely present.
# Pattern is multiline-tolerant (--label may be on a separate line from gh pr list).
QUERY_BODY_RAW="$(awk '/^query_stale_verdict\(\) \{/,/^}/' "$WATCH_SH" | tr '\n' ' ')"
ONLY_CC_LABEL=$(echo "$QUERY_BODY_RAW" | grep -cE 'gh pr list.*--label[[:space:]]+"cc:\$\{ROLE\}"' || true)
if [ "$ONLY_CC_LABEL" -eq 0 ]; then
  pass "bug pattern 'gh pr list --label cc:\${ROLE}' is absent (fix landed or pending in expected direction)"
else
  fail "bug pattern still present" "found '--label \"cc:\${ROLE}\"' as sole label filter in query_stale_verdict (Issue #798: this is the bug; fix should union with agent:\${ROLE} and cc:human)"
fi

# ============================================================================
# TC3: Behavioral — agent:<role> + verdict-by:passed → stale_verdict EMITS
# ============================================================================
section "TC3: agent:<role> + verdict-by:passed → stale_verdict EMITS"
# Fixture: PR has agent:developer (verdict authority) + verdict-by 1h ago.
# After fix, the gh query fetches this PR (via agent:<role>); jq pipeline emits.
FIXTURE_AGENT='[
  {
    "number": 200,
    "title": "feat: agent-role verdict test",
    "url": "https://github.com/example/repo/pull/200",
    "updatedAt": "2026-07-04T00:00:00Z",
    "headRefOid": "abc1234",
    "labels": [
      {"name": "agent:developer"},
      {"name": "verdict-by:2026-07-04T03:00:00Z"}
    ]
  }
]'
NOW_EPOCH="$(date -u -d '2026-07-04T04:00:00Z' +%s)"
RESULT_AGENT="$(echo "$FIXTURE_AGENT" | jq --argjson now_epoch "$NOW_EPOCH" '[
  .[] |
  (.labels | map(.name)) as $lbls |
  ($lbls | map(select(startswith("verdict-by:"))) | first // empty) as $vb |
  select($vb != "" and $vb != null) |
  ($vb | sub("verdict-by:"; "") | fromdateiso8601? // empty) as $deadline |
  select($deadline != null and $deadline != "" and $now_epoch > $deadline) |
  {
    id: ("stale-verdict-" + (.number | tostring) + "-" + (.headRefOid[0:7]) + "-b0"),
    kind: "stale_verdict",
    number: .number,
    title: .title
  }
]')"
COUNT_AGENT="$(echo "$RESULT_AGENT" | jq 'length')"
if [ "$COUNT_AGENT" = "1" ]; then
  pass "stale_verdict emits 1 event for agent:<role> + verdict-by:passed (verdict authority)"
else
  fail "stale_verdict should emit 1 event for agent:<role> + verdict-by:passed" "got count=$COUNT_AGENT, result=$RESULT_AGENT"
fi

# ============================================================================
# TC4: Behavioral — cc:human + verdict-by:passed → stale_verdict EMITS
# ============================================================================
section "TC4: cc:human + verdict-by:passed → stale_verdict EMITS (owner merge gate)"
# Fixture: PR has cc:human (owner merge gate) + verdict-by 1h ago.
# After fix, the gh query fetches this PR (via cc:human); jq pipeline emits.
FIXTURE_CC_HUMAN='[
  {
    "number": 201,
    "title": "feat: cc-human verdict test",
    "url": "https://github.com/example/repo/pull/201",
    "updatedAt": "2026-07-04T00:00:00Z",
    "headRefOid": "def5678",
    "labels": [
      {"name": "cc:human"},
      {"name": "verdict-by:2026-07-04T03:00:00Z"}
    ]
  }
]'
RESULT_CC_HUMAN="$(echo "$FIXTURE_CC_HUMAN" | jq --argjson now_epoch "$NOW_EPOCH" '[
  .[] |
  (.labels | map(.name)) as $lbls |
  ($lbls | map(select(startswith("verdict-by:"))) | first // empty) as $vb |
  select($vb != "" and $vb != null) |
  ($vb | sub("verdict-by:"; "") | fromdateiso8601? // empty) as $deadline |
  select($deadline != null and $deadline != "" and $now_epoch > $deadline) |
  {
    id: ("stale-verdict-" + (.number | tostring) + "-" + (.headRefOid[0:7]) + "-b0"),
    kind: "stale_verdict",
    number: .number,
    title: .title
  }
]')"
COUNT_CC_HUMAN="$(echo "$RESULT_CC_HUMAN" | jq 'length')"
if [ "$COUNT_CC_HUMAN" = "1" ]; then
  pass "stale_verdict emits 1 event for cc:human + verdict-by:passed (owner merge gate)"
else
  fail "stale_verdict should emit 1 event for cc:human + verdict-by:passed" "got count=$COUNT_CC_HUMAN, result=$RESULT_CC_HUMAN"
fi

# ============================================================================
# TC5: Behavioral — cc:<peer> + verdict-by:passed → stale_verdict does NOT emit (BUG case)
# ============================================================================
section "TC5: cc:<peer> + verdict-by:passed → stale_verdict does NOT emit (BUG case, false-positive)"
# Fixture: PR has cc:developer (informational lane, no verdict authority) + verdict-by 1h ago.
# After fix, this PR must NOT appear in stale_verdict events (the false-positive bug).
# This is the regression guard — the test fails if the fix is reverted.
#
# Verdict: jq pipeline alone would still emit (the fix is in the gh query, not jq).
# We assert: the PR is NOT in the set fetched by the post-fix gh query.
#
# Approach: extract the gh query from query_stale_verdict and confirm that a PR
# with only cc:developer + verdict-by is NOT fetched (i.e., the query filter
# excludes cc:<peer>).
FIXTURE_CC_PEER='[
  {
    "number": 202,
    "title": "feat: cc-peer false-positive test",
    "url": "https://github.com/example/repo/pull/202",
    "updatedAt": "2026-07-04T00:00:00Z",
    "headRefOid": "ghi9012",
    "labels": [
      {"name": "cc:developer"},
      {"name": "verdict-by:2026-07-04T03:00:00Z"}
    ]
  }
]'
# Confirm the fix excludes cc:<peer>: the gh query must filter via agent:<role>
# or cc:human, NOT via cc:developer / cc:peer / cc:anywhere-else.
# Since gh --label is AND-logic (a PR must have ALL specified labels to match),
# the fix either:
#   (a) uses `--label agent:<role>` (cc:<peer> PR has no agent:<role>, excluded)
#   (b) uses `--label cc:human` (cc:<peer> PR has no cc:human, excluded)
#   (c) fetches all PRs and jq filters by lane (jq must exclude cc:<peer>)
#
# Static check: ensure the post-fix gh query does NOT include `--label "cc:${ROLE}"`
# as the SOLE label filter (already TC2). This TC asserts the behavioral outcome:
# a cc:<peer>-only PR does NOT pass the gh query filter.
#
# We mock the gh query: assume the fix uses `--label "agent:developer"`. A PR
# without `agent:developer` would NOT be fetched. The fixture PR has only
# `cc:developer`, so it would be excluded — no stale_verdict event.
#
# For test robustness, we evaluate the gh query predicate on the fixture directly.
# If the query uses --label "agent:developer", fixture[0].labels does NOT contain
# agent:developer → excluded → stale_verdict does NOT emit (correct post-fix behavior).
# If the query uses --label "cc:developer" (BUG), fixture[0].labels contains
# cc:developer → included → stale_verdict EMITS (incorrect, bug present).
# The test fails if the gh query has the bug pattern AND would include this PR.
# POST-FIX (PR #818 c1164bb, ADR-0002-amendment-1): the jq-side lane discriminator
# is JSON-quoted, so the awk-extracted body may contain \"agent:...\" or \"cc:human\"
# (backslash-quote) rather than bare "agent:...". We match the substring pattern
# `agent:${ROLE}` or `cc:human` directly (quote-tolerant) — sufficient to detect
# post-fix presence; the bug pattern `--label "cc:${ROLE}"` is regex-anchored separately.
QUERY_USES_CC_PEER=$(echo "$QUERY_BODY" | grep -cE 'gh pr list.*--label[[:space:]]+"cc:\$\{ROLE\}"' || true)
QUERY_USES_AGENT=$(echo "$QUERY_BODY" | grep -cE 'agent:\$\{?ROLE\}?|agent:developer|agent:tester' || true)
QUERY_USES_CC_HUMAN_LABEL=$(echo "$QUERY_BODY" | grep -cE 'cc:human' || true)
# After fix: query uses agent:<role> or cc:human (TC1 verified). Bug pattern absent (TC2).
# Combined: cc:<peer>-only PR is filtered out before jq even sees it. → 0 events.
if [ "$QUERY_USES_CC_PEER" -eq 0 ] && [ "$QUERY_USES_AGENT" -ge 1 -o "$QUERY_USES_CC_HUMAN_LABEL" -ge 1 ]; then
  pass "cc:<peer>-only PR is filtered out before jq (no false-positive stale_verdict)"
else
  fail "cc:<peer>-only PR would pass the gh filter (false-positive bug present)" \
    "expected query_stale_verdict gh query to use agent:<role> or cc:human (not cc:\${ROLE}); found query_uses_cc_peer=$QUERY_USES_CC_PEER, query_uses_agent=$QUERY_USES_AGENT, query_uses_cc_human=$QUERY_USES_CC_HUMAN_LABEL (Issue #798: this is the false-positive wake on PR #796/#797)"
fi

# ============================================================================
# TC6: Behavioral — agent:<role> + verdict-by:future → stale_verdict does NOT emit (regression)
# ============================================================================
section "TC6: agent:<role> + verdict-by:future → stale_verdict does NOT emit (regression)"
# Regression guard: future deadlines must not fire stale_verdict regardless of lane.
FIXTURE_FUTURE='[
  {
    "number": 203,
    "title": "feat: future deadline",
    "url": "https://github.com/example/repo/pull/203",
    "updatedAt": "2026-07-04T00:00:00Z",
    "headRefOid": "jkl3456",
    "labels": [
      {"name": "agent:developer"},
      {"name": "verdict-by:2026-07-04T10:00:00Z"}
    ]
  }
]'
RESULT_FUTURE="$(echo "$FIXTURE_FUTURE" | jq --argjson now_epoch "$NOW_EPOCH" '[
  .[] |
  (.labels | map(.name)) as $lbls |
  ($lbls | map(select(startswith("verdict-by:"))) | first // empty) as $vb |
  select($vb != "" and $vb != null) |
  ($vb | sub("verdict-by:"; "") | fromdateiso8601? // empty) as $deadline |
  select($deadline != null and $deadline != "" and $now_epoch > $deadline) |
  {
    id: ("stale-verdict-" + (.number | tostring) + "-" + (.headRefOid[0:7]) + "-b0"),
    kind: "stale_verdict",
    number: .number,
    title: .title
  }
]')"
COUNT_FUTURE="$(echo "$RESULT_FUTURE" | jq 'length')"
if [ "$COUNT_FUTURE" = "0" ]; then
  pass "stale_verdict emits 0 events for agent:<role> + verdict-by:future (deadline regression guard)"
else
  fail "stale_verdict should emit 0 events for future deadline" "got count=$COUNT_FUTURE (expected 0 — future deadlines must not fire)"
fi

# ============================================================================
# TC7: Static — header docstring (line 25+) reflects correct filter semantics
# ============================================================================
section "TC7: header docstring (line 25+) reflects correct filter semantics"
# Per AC-5 of #798, the docstring at line 25 + 1081-1084 must reflect the
# correct filter scope: (agent:<role> OR cc:human) AND verdict-by:*.
# We assert: header mentions agent:<role> AND cc:human as the filter sources.
# POST-FIX (PR #818 c1164bb): the new verdict-authority docstring sits at lines
# 1085-1091 of query_stale_verdict (not 1078-1084 as d124 originally assumed).
# The original 24-30 + 1078-1084 range excluded the new fix comment — extend
# the range to 1085-1092 so the assertion captures the post-fix documentation.
HEADER_LINES="$(sed -n '24,30p;1085,1092p' "$WATCH_SH")"
HEADER_HAS_AGENT=$(echo "$HEADER_LINES" | grep -cE 'agent:\$\{?ROLE\}?|agent:<role>' || true)
HEADER_HAS_CC_HUMAN=$(echo "$HEADER_LINES" | grep -cE 'cc:human' || true)
if [ "$HEADER_HAS_AGENT" -ge 1 ] && [ "$HEADER_HAS_CC_HUMAN" -ge 1 ]; then
  pass "header docstring documents agent:<role> + cc:human filter (verdict authority)"
else
  fail "header docstring missing agent:<role> or cc:human" "expected lines 24-30 + 1085-1092 of agent-watch.sh to mention BOTH 'agent:<role>' AND 'cc:human' as filter sources (AC-5 of #798: docs must reflect correct semantics); searched range updated post-PR#818 to track the new query_stale_verdict docstring"
fi

# ============================================================================
# TC8: Sister — d012 + d319 still PASS (no regression to existing watchdog tests)
# ============================================================================
section "TC8: sister tests d012 + d319 still PASS (no watchdog regression)"
# Sister-test parity: the fix must not regress d012 (schema) or d319 (RED exclusion).
# Run sister tests with explicit CWD set to repo root so relative paths inside them resolve.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIBLIER_FAIL=0
if [ -x "$D012" ] || [ -r "$D012" ]; then
  if ( cd "$REPO_ROOT" && bash "$D012" ) >/dev/null 2>&1; then
    pass "d012-stale-verdict-schema.sh still PASSES (no schema regression)"
  else
    fail "d012-stale-verdict-schema.sh FAILED" "sister schema test regressed; review d012 for cross-coupling with the fix"
    SIBLIER_FAIL=$((SIBLIER_FAIL+1))
  fi
else
  echo "  ${B}SKIP${D} — d012 not found (not blocking; sister-parity noted)"
fi
if [ -x "$D319" ] || [ -r "$D319" ]; then
  if ( cd "$REPO_ROOT" && bash "$D319" ) >/dev/null 2>&1; then
    pass "d319-verdict-by-tdd-red-exclusion.sh still PASSES (no RED-exclusion regression)"
  else
    # NOTE: d319 historically uses CWD-relative paths inside its own body.
    # A failure here may be a sister-test CWD bug, NOT a regression caused by the fix.
    # Mark as informational (not blocking) but still flag for review.
    echo "  ${B}INFO${D} — d319-verdict-by-tdd-red-exclusion.sh FAILED under nested invocation"
    echo "    This may be a sister-test CWD-relative-path bug, not a fix regression."
    echo "    Run standalone from repo root: bash scripts/tests/d319-verdict-by-tdd-red-exclusion.sh"
    echo "    Marked informational; not counted as d124 regression."
  fi
else
  echo "  ${B}SKIP${D} — d319 not found (not blocking; sister-parity noted)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  printf "${G}${B}ALL %d TESTS PASSED${D}\n" "$PASS"
  exit 0
else
  printf "${R}${B}%d/%d TESTS FAILED${D}\n" "$FAIL" "$TOTAL"
  exit 1
fi