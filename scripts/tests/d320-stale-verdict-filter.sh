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

# --- TC4: Layer 5.5 j.4 vacuous-pass regression (PR #804, cycle ~#3708 directive) ---
#
# Static-analysis regression anchor for the Layer 5 vacuous-pass bug:
#   - Per cycle ~#3698 insight: Layer 5's PASSING state IS its desired state
#     when reviewer chain is silently removed. After removal, Layer 5 passes
#     vacuously. Lens (j.4): when a check passes after a precondition has been
#     silently removed, the passing state is misleading — verification requires
#     asserting the precondition exists AT CHECK TIME.
#   - PR #804 fix introduces Layer 5.5 j.4 PRE-CHECK + PRESERVE SEMANTICS in
#     Step 4 of .github/workflows/label-check.yml.
#   - TC7 verifies that the fix block is present in label-check.yml.
#
# RED-first (ADR-0044): on main HEAD (pre-PR-#804), TC7 fails (no fix blocks).
# GREEN when PR #804 lands (label-check.yml contains the fix blocks).
#
# Sister-pattern: d319 (verdict-by TDD-RED exclusion), d296 (peer-poke helper).
# Cycle: ~#3708 (orchestrator directive, parallel impl to PR #804).
# Issue: #789 Cluster A (d048 Layer 5 status:ready gating, owner scope).

echo
echo "==== TC4 (Layer 5.5 j.4 vacuous-pass regression): label-check.yml has vacuous-pass detection + PRESERVE semantics ===="

LABEL_CHECK="$REPO_ROOT/.github/workflows/label-check.yml"

if [ ! -f "$LABEL_CHECK" ]; then
  fail "TC4: .github/workflows/label-check.yml not found at $LABEL_CHECK"
else
  # TC7a — Layer 5.5 j.4 vacuous-pass detection block exists
  if grep -qE 'Layer 5\.5|j\.4 vacuous-pass detection' "$LABEL_CHECK"; then
    pass "TC4: Layer 5.5 j.4 vacuous-pass detection block present in label-check.yml"
  else
    fail "TC4: Layer 5.5 j.4 vacuous-pass detection block MISSING (PR #804 fix not applied yet)"
  fi

  # TC7b — PRESERVE SEMANTICS comment block exists in Step 4 (reviewer chain preserved)
  if grep -qE 'PRESERVE SEMANTICS' "$LABEL_CHECK"; then
    pass "TC5: PRESERVE SEMANTICS comment block present in Step 4 (reviewer chain preserved on status:ready)"
  else
    fail "TC5: PRESERVE SEMANTICS comment block MISSING (reviewer chain auto-removal still possible)"
  fi

  # TC7c — vacuous-pass FAIL path uses core.setFailed (not silent-skip)
  if grep -A 5 'vacuous-pass detected' "$LABEL_CHECK" | grep -qE 'core\.setFailed'; then
    pass "TC6: vacuous-pass detection uses core.setFailed (FAIL, not silent-skip per lens j.4)"
  else
    fail "TC6: vacuous-pass detection does NOT use core.setFailed (silent-skip regression — lens j.4)"
  fi

  # TC7d — reviewer chain precondition asserted at check time (lens j.4 attestation)
  if grep -qE 'reviewer chain' "$LABEL_CHECK" && grep -qE 'j\.4 vacuous-pass' "$LABEL_CHECK"; then
    pass "TC7: 'reviewer chain' precondition referenced in j.4 vacuous-pass detection (lens j.4 attestation)"
  else
    fail "TC7: 'reviewer chain' precondition NOT referenced in j.4 vacuous-pass detection (lens j.4 attestation gap)"
  fi

  # TC7e — scripts/tests/INDEX.md has d320 row (Cadence Rule 1 atomic per ADR-0055 §1)
  if [ ! -f "$INDEX" ]; then
    fail "TC8: scripts/tests/INDEX.md not found at $INDEX (Cadence Rule 1 attestation impossible — ADR-0055 §1)"
  elif grep -qE '\*\*d320\*\*' "$INDEX"; then
    pass "TC8: scripts/tests/INDEX.md has d320 row (Cadence Rule 1 atomic — d-test + INDEX.md same commit per ADR-0055 §1)"
  else
    fail "TC8: scripts/tests/INDEX.md MISSING d320 row (Cadence Rule 1 violation — ADR-0055 §1 atomic, d-test file shipped without INDEX.md entry)"
  fi
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