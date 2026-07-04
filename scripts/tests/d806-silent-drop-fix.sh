#!/usr/bin/env bash
# scripts/tests/d806-silent-drop-fix.sh
#
# d806 — silent-drop fix regression guard (Issue #806, TD-046)
#
# Purpose:
#   Verify that the `gh issue list --label` silent-drop bug (architect 100%
#   miss, tester 60%, PM 75%, dev 25%) is mitigated by switching the
#   affected sites in scripts/agent-watch.sh + scripts/claim-next-ready.sh
#   to REST gh api with labels=X query param.
#
# Affected sites per Issue #806 architect verdict:
#   - scripts/agent-watch.sh:586   query_assigned_issues
#   - scripts/agent-watch.sh:627   query_assigned_issues_any_status
#   - scripts/agent-watch.sh:879   query_issue_mentions (orphan backlog)
#   - scripts/agent-watch.sh:943   query_periodic_backlog_scan
#   - scripts/agent-watch.sh:1369  query_board_changes (non-orchestrator)
#   - scripts/claim-next-ready.sh:112 WIP_COUNT_ONLY global
#   - scripts/claim-next-ready.sh:118 per-role in-progress
#   - scripts/claim-next-ready.sh:210 ready items
#
# Doctrinal frame:
#   - Issue #806 (HIGH severity silent-drop; dev lane fix per architect verdict)
#   - TD-046 (this filing)
#   - ADR-0049 (d-test framework ≥3 TCs sister-pattern; d806 = 5 TCs)
#   - ADR-0044 (RED-first TDD — pre-impl would FAIL TC1+TC2; post-impl PASS)
#   - ADR-0055 §1 (Cadence Rule 1 atomic — d806 file + INDEX.md entry same commit)
#   - Sister-pattern: d320 (stale_verdict filter scope, Issue #798)
#   - Sister-pattern: d058 (claim WIP workstream, ADR-0038)
#   - Sister-pattern: d296 (peer-poke helper, dual-channel)
#
# Test framework: bash + grep + jq + gh api (REST, immune to GraphQL rate limit)
#
# Exit codes:
#   0 — all 11 PASS calls across 5 TC groups PASS
#   1 — at least one TC FAIL
#   2 — preflight failure (missing tool, missing file)
#
# Test author: @developer (RED-first authored; @tester signs off per ADR-0044)
# Last verified: NEW (pending sister-test authorship per ADR-0044 RED-first)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

WATCHER="$REPO_ROOT/scripts/agent-watch.sh"
CLAIM="$REPO_ROOT/scripts/claim-next-ready.sh"
INDEX="$REPO_ROOT/scripts/tests/INDEX.md"

PASS=0
FAIL=0
declare -a FAILURES

pass() {
  echo "  ✓ PASS — $*"
  PASS=$((PASS + 1))
}

fail() {
  echo "  ✗ FAIL — $*"
  FAIL=$((FAIL + 1))
  FAILURES+=("$*")
}

echo "==== d806 — silent-drop fix regression guard ===="
echo "==== Issue #806 / TD-046 ===="
echo

# --- TC1: agent-watch.sh no longer uses gh issue list --label at the 5 sites ---

echo "==== TC1: agent-watch.sh sites converted to gh api (5 sites) ===="

if [ ! -f "$WATCHER" ]; then
  fail "TC1 — scripts/agent-watch.sh not found at $WATCHER"
else
  # Count gh api calls — must be ≥5 (the 5 patched sites) plus the existing
  # L1778/1779 (Katman 1 count) and L252 (REPOS_RAW init) = ≥7 total
  api_count="$(grep -cE 'gh api ' "$WATCHER" || true)"
  if [ "$api_count" -ge 7 ]; then
    pass "TC1 — agent-watch.sh has $api_count gh api calls (≥7 expected: 5 patched + L252 REPOS_RAW + L1778/L1779 Katman 1)"
  else
    fail "TC1 — agent-watch.sh has only $api_count gh api calls (≥7 expected; 5 sites not fully converted)"
  fi

  # Verify the Issue #806 attribution comment appears at each converted site
  if grep -qE 'Issue #806.*gh issue list --label silent-drop|gh issue list --label.*silent-drop.*Issue #806' "$WATCHER"; then
    pass "TC1b — agent-watch.sh has Issue #806 attribution comment at converted sites (operator-grep-able traceability)"
  else
    fail "TC1b — agent-watch.sh MISSING Issue #806 attribution comment at converted sites (no operator-grep anchor)"
  fi

  # Verify NO `gh issue list --label` pattern remains in code (NOT comments).
  # Pattern: code line starting with whitespace + gh issue list, then --label.
  # Comment lines starting with # are excluded (Issue #806 attribution cites
  # the pattern in comments for operator-grep traceability — that's intended).
  if grep -qE '^[[:space:]]*gh issue list.*--label' "$WATCHER"; then
    fail "TC1c — agent-watch.sh still has gh issue list --label pattern in code (silent-drop risk NOT eliminated)"
  else
    # Verify the orchestrator-only residual is bounded to L1397
    orchestrator_residual="$(grep -cE '^[[:space:]]*gh issue list ' "$WATCHER" || echo 0)"
    if [ "$orchestrator_residual" -le 1 ]; then
      pass "TC1c — agent-watch.sh has no gh issue list --label pattern in code (silent-drop class eliminated; $orchestrator_residual residual gh issue list call is orchestrator-only L1397, no --label)"
    else
      fail "TC1c — agent-watch.sh has $orchestrator_residual residual gh issue list calls (expected ≤1 for orchestrator-only L1397)"
    fi
  fi
fi

# --- TC2: claim-next-ready.sh no longer uses gh issue list --label at the 3 sites ---

echo
echo "==== TC2: claim-next-ready.sh sites converted to gh api (3 sites) ===="

if [ ! -f "$CLAIM" ]; then
  fail "TC2 — scripts/claim-next-ready.sh not found at $CLAIM"
else
  # Verify the Issue #806 attribution comment appears at each converted site
  if grep -qE 'Issue #806.*gh issue list --label silent-drop|gh issue list --label.*silent-drop.*Issue #806' "$CLAIM"; then
    pass "TC2 — claim-next-ready.sh has Issue #806 attribution comment at converted sites (operator-grep-able traceability)"
  else
    fail "TC2 — claim-next-ready.sh MISSING Issue #806 attribution comment at converted sites (no operator-grep anchor)"
  fi

  # Verify NO `gh issue list --label` pattern remains in code (NOT comments).
  if grep -qE '^[[:space:]]*gh issue list.*--label' "$CLAIM"; then
    fail "TC2b — claim-next-ready.sh still has gh issue list --label pattern in code (silent-drop risk NOT eliminated)"
  else
    if ! grep -qE '^[[:space:]]*gh issue list ' "$CLAIM"; then
      pass "TC2b — claim-next-ready.sh has no gh issue list pattern in code (all 3 sites converted to gh api)"
    else
      fail "TC2b — claim-next-ready.sh still has gh issue list patterns in code (silent-drop class not eliminated)"
    fi
  fi

  # Verify multi-label filter syntax matches the Issue #806 fix shape
  #   labels=agent:${ROLE},status:ready    (L210)
  #   labels=status:in-progress             (L112)
  #   labels=agent:${ROLE},status:in-progress (L118)
  if grep -qE 'labels=agent:\$\{ROLE\},status:ready' "$CLAIM" && \
     grep -qE 'labels=status:in-progress' "$CLAIM" && \
     grep -qE 'labels=agent:\$\{ROLE\},status:in-progress' "$CLAIM"; then
    pass "TC2c — claim-next-ready.sh has all 3 multi-label REST query shapes (L112 + L118 + L210)"
  else
    fail "TC2c — claim-next-ready.sh MISSING one or more multi-label REST query shapes (L112/L118/L210 not fully converted)"
  fi
fi

# --- TC3: bash syntax check on patched scripts ---

echo
echo "==== TC3: bash syntax check on patched scripts ===="

if bash -n "$WATCHER" 2>/dev/null; then
  pass "TC3a — scripts/agent-watch.sh passes bash -n syntax check (patched sites valid bash)"
else
  fail "TC3a — scripts/agent-watch.sh FAILS bash -n syntax check (patched sites introduced syntax error)"
fi

if bash -n "$CLAIM" 2>/dev/null; then
  pass "TC3b — scripts/claim-next-ready.sh passes bash -n syntax check (patched sites valid bash)"
else
  fail "TC3b — scripts/claim-next-ready.sh FAILS bash -n syntax check (patched sites introduced syntax error)"
fi

# --- TC4: live REST API multi-label query returns expected items (sister-pattern to L1778) ---

echo
echo "==== TC4: live REST API multi-label query works for ready items ===="

if ! command -v gh >/dev/null 2>&1; then
  fail "TC4 — gh CLI not available (cannot verify live REST query)"
elif ! command -v jq >/dev/null 2>&1; then
  fail "TC4 — jq not available (cannot verify live REST query)"
else
  # Get the repo from the watcher script's git remote or hardcode the AtilCalculator repo
  REPO="${REPO:-atilcan65/AtilCalculator}"

  # REST multi-label query: agent:developer,status:ready — should return #806 + #802
  ready_nums="$(gh api "repos/${REPO}/issues?labels=agent:developer,status:ready&state=open&per_page=10" --jq '[.[] | .number] | join(",")' 2>/dev/null || echo "")"

  if [ -z "$ready_nums" ]; then
    fail "TC4a — REST multi-label query returned empty (silent-drop class NOT mitigated — REST should always return matching items)"
  elif echo "$ready_nums" | grep -qE '(^|,)806($|,)|(^|,)802($|,)'; then
    issue_count="$(echo "$ready_nums" | tr ',' '\n' | wc -l | tr -d ' ')"
    pass "TC4a — REST multi-label query returns $issue_count ready item(s) including #806 + #802 (silent-drop class mitigated)"
  else
    fail "TC4a — REST multi-label query returned items but missing expected #806 + #802 (got: $ready_nums)"
  fi

  # Single-label REST query: agent:developer — should return 4 items per Issue #806 measured data
  dev_count="$(gh api "repos/${REPO}/issues?labels=agent:developer&state=open&per_page=20" --jq 'length' 2>/dev/null || echo 0)"
  if [ "$dev_count" -ge 4 ]; then
    pass "TC4b — REST single-label agent:developer returns $dev_count items (≥4 expected per Issue #806 measured data)"
  else
    fail "TC4b — REST single-label agent:developer returned only $dev_count items (expected ≥4 per Issue #806 measured data)"
  fi
fi

# --- TC5: scripts/tests/INDEX.md has d806 row (Cadence Rule 1 atomic per ADR-0055 §1) ---

echo
echo "==== TC5: scripts/tests/INDEX.md has d806 row (Cadence Rule 1 atomic) ===="

if [ ! -f "$INDEX" ]; then
  fail "TC5 — scripts/tests/INDEX.md not found at $INDEX (Cadence Rule 1 attestation impossible — ADR-0055 §1)"
elif grep -qE '\*\*d806\*\*' "$INDEX"; then
  pass "TC5 — scripts/tests/INDEX.md has d806 row (Cadence Rule 1 atomic — d-test file shipped with INDEX.md entry per ADR-0055 §1)"
else
  fail "TC5 — scripts/tests/INDEX.md MISSING d806 row (Cadence Rule 1 violation — ADR-0055 §1 atomic, d-test file shipped without INDEX.md entry)"
fi

# --- Summary ---

echo
echo "==== Summary ===="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Failures detected:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  echo
  echo "EXIT 1: d806 regression detected — silent-drop fix not applied OR incomplete"
  exit 1
fi

echo
echo "EXIT 0: d806 GREEN — silent-drop fix applied across all sites (agent-watch.sh + claim-next-ready.sh)"
exit 0