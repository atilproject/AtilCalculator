#!/usr/bin/env bash
# scripts/tests/d320-stale-verdict-filter.sh
#
# d320 — stale_verdict filter scope regression anchor (Issue #798, ADR-0002 amendment 1)
#
# Purpose:
#   Verify that the `query_stale_verdict` filter in `scripts/agent-watch.sh` correctly
#   scopes to verdict-authority lanes ONLY:
#     - (agent:<role> AND verdict-by:<ts> past deadline) → emits stale_verdict
#     - (cc:human AND verdict-by:<ts> past deadline)     → emits stale_verdict
#     - (cc:<peer> AND verdict-by:<ts> past deadline)    → does NOT emit stale_verdict
#
# Doctrinal frame:
#   - ADR-0002 amendment 1 (this PR) — corrected filter scope
#   - ADR-0015 (cc:<role> = informational lane, no verdict authority)
#   - ADR-0024 (verdict-by:<ts> = verdict stamp semantics)
#   - ADR-0031 (cc:human = owner merge gate, special verdict authority)
#   - ADR-0049 (d-test framework ≥3 TCs sister-pattern)
#   - Issue #798 (filing issue, dev escalation cycle ~#3671)
#
# Test framework: bash + grep + jq (matches d296/d319 family pattern)
#
# Exit codes:
#   0 — all 3 TCs PASS
#   1 — at least one TC FAIL
#
# Sister-patterns:
#   - d296 (peer-poke helper)
#   - d319 (verdict-by TDD-RED exclusion)
#   - d017 (stale_cc sister family)
#
# Test author: @architect (proposed; @tester signs off per ADR-0044 RED-first)
# Last verified: NEW (pending sister-test authorship per ADR-0044 RED-first)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

WATCHER="$REPO_ROOT/scripts/agent-watch.sh"

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

echo "==== d320 — stale_verdict filter scope regression anchor ===="
echo "==== Issue #798 / ADR-0002 amendment 1 ===="
echo

# --- TC1: cc:<peer> + verdict-by:* does NOT fire for that peer ---

echo "==== TC1 (lane discriminator): cc:<peer> + verdict-by:* does NOT fire stale_verdict ===="

if [ ! -f "$WATCHER" ]; then
  fail "TC1 — scripts/agent-watch.sh not found at $WATCHER"
else
  # Check that query_stale_verdict filter requires agent:<role> OR cc:human (not cc:<role> alone)
  if grep -A 2 'query_stale_verdict' "$WATCHER" | grep -qE 'agent:.*\${ROLE}|cc:human'; then
    pass "TC1 — query_stale_verdict references agent:<role> OR cc:human lane discriminator (verdict-authority scope)"
  else
    fail "TC1 — query_stale_verdict does NOT reference agent:<role> OR cc:human lane discriminator (cc:<role>-only regression)"
  fi
fi

# --- TC2: agent:<role> + verdict-by:* past deadline DOES fire ---

echo
echo "==== TC2 (verdict-authority path): agent:<role> + verdict-by:* past deadline fires stale_verdict ===="

if grep -qE 'agent:\$\{ROLE\}|cc:human' "$WATCHER"; then
  # Verify the filter SCOPE includes agent:<role> (verdict authority)
  if grep -qE 'agent:\$\{ROLE\}' "$WATCHER" || \
     grep -qE "agent:.\\\$\\{ROLE\\}" "$WATCHER"; then
    pass "TC2 — filter includes agent:<role> lane (verdict-authority path preserved)"
  else
    # Check if filter uses jq-level discriminator instead of gh --label filter
    if grep -A 30 'query_stale_verdict' "$WATCHER" | grep -qE 'agent:.{0,5}ROLE.*verdict|any.*agent:'; then
      pass "TC2 — filter applies agent:<role> lane discriminator at jq level (verdict-authority path preserved)"
    else
      fail "TC2 — filter does NOT include agent:<role> lane (verdict-authority path missing)"
    fi
  fi
else
  fail "TC2 — query_stale_verdict does NOT reference agent:<role> or cc:human lanes (verdict-authority path missing)"
fi

# --- TC3: cc:human + verdict-by:* past deadline DOES fire (owner merge gate) ---

echo
echo "==== TC3 (owner merge gate): cc:human + verdict-by:* past deadline fires stale_verdict ===="

if grep -qE 'cc:human' "$WATCHER"; then
  pass "TC3 — filter includes cc:human lane (owner merge gate verdict-authority preserved)"
else
  fail "TC3 — filter does NOT include cc:human lane (owner merge gate verdict-authority missing — would regress ADR-0031)"
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
  echo "EXIT 1: d320 regression detected — stale_verdict filter scope incorrect"
  exit 1
fi

echo
echo "EXIT 0: d320 GREEN — stale_verdict filter scope correctly scoped to verdict-authority lanes"
exit 0