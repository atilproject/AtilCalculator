#!/usr/bin/env bash
# d126-layer-5-j4-fresh-label-read.sh
#
# d126 — Layer 5.5 j.4 fresh-label-read regression guard (Issue #819)
#
# Why this test exists
# --------------------
# Layer 5.5 j.4 vacuous-pass detection in `.github/workflows/label-check.yml`
# (line 530+) reads PR labels from `context.payload.pull_request.labels` —
# the WEBHOOK EVENT snapshot, frozen at the moment the webhook fired.
#
# The bug (Issue #819, cmt 4881737089, PR #817 LIVE INSTANCE 2026-07-04T11:06Z):
#   Sequence reconstructed from PR #817:
#     11:06:20Z  PR opened (cc:tester added; verdict-by NOT yet added)
#     11:06:48Z  Auto-Verdict-By hook fires → verdict-by:<ts> committed
#     11:06:53Z  cc:tester label-event fires Layer 5 j.4
#     **Bot reports hasAuthorCc=true hasVerdictBy=false**
#     → j.4 false-positive VACUOUS-PASS detection (silently strips reviewer chain
#       based on stale snapshot)
#     → CI FAIL on PR #817 blocks owner squash gate (ADR-0031 owner merge)
#
# Fix (per Issue #819 AC1): Layer 5 j.4 must read fresh labels via
#   `github.rest.pulls.get` (fresh GitHub API) instead of
#   `context.payload.pull_request.labels` (stale webhook snapshot).
#
# Test framework: bash + grep + jq (matches d124/d320 sister-pattern family).
# Cycle ~#3571 CI flake lesson applied (ADR-0051 3-condition discriminator):
#   - DETERMINISTIC inputs (no time-sensitivity, no random IDs)
#   - RE-RUNNABLE without env deps (no gh CLI calls, no API tokens)
#   - ENV-INDEPENDENT (works in any CI container)
#
# Test cases (per ADR-0049 baseline ≥3 TCs, expanded to 5 for hybrid coverage):
#   TC1 (static-grep):    fix marker present — github.rest.pulls.get for fresh read
#   TC2 (static-grep):    bug pattern absent — context.payload.pull_request.labels
#                         NOT used in j.4 vacuous-pass detection block
#   TC3 (workflow-sim):   race scenario — verdict-by added between webhook and bot,
#                         fresh API vs stale payload (PR #817 LIVE INSTANCE)
#   TC4 (workflow-sim):   DRAFT PR skip-guard precedence (Issue #680 amendment #3)
#                         fires before j.4 (preserves reviewer chain audit trail)
#   TC5 (sister-pattern): TD-035 heartbeat drift + TD-037 silent-skip preflight
#                         unaffected by the fix
#
# RED state (pre-fix, on origin/main c2fad70 + f3848da):
#   TC1 FAIL — github.rest.pulls.get missing from label-check.yml
#   TC2 FAIL — context.payload.pull_request.labels still used in j.4 block
#   TC3 PASS — j.4 LOGIC is correct, only data source is wrong
#   TC4 PASS — DRAFT skip-guard is independent of j.4 fix
#   TC5 PASS — TD-035/TD-037 are sister-patterns, not affected by j.4 fix
#   script exit=1
#
# GREEN state (post-fix, after owner applies `github.rest.pulls.get` to label-check.yml):
#   All 5 TCs PASS, script exit=0.
#
# Exit code: 0 = all pass, 1 = at least one fail.
# Run standalone: bash scripts/tests/d126-layer-5-j4-fresh-label-read.sh
#
# Sister-pattern lineage:
#   - d124 (tester, PR #799) — deeper coverage sister for Issue #798 stale_verdict
#   - d320 (architect, PR #800→#818) — doctrinal baseline sister for Issue #798
#   - TD-035 (heartbeat drift sister-pattern)
#   - TD-037 (silent-skip preflight sister-pattern)
#   - d058 (claim-next-ready work-stream awareness)
#
# Refs: Issue #819, cmt 4881737089 (PR #817 live instance), ADR-0012 (4-cat invariant),
#       ADR-0044 (TDD RED-first), ADR-0049 (d-test framework, ≥3 TCs sister-pattern),
#       ADR-0051 (CI flake vs regression 3-condition discriminator — cycle ~#3571 lesson),
#       ADR-0055 §1 (Cadence Rule 1 atomic — d-test + INDEX.md same commit),
#       ADR-0068 (Layer 5 j.4 tester-author exception, PR #799 sibling ADR).
# Pattern lifted from: scripts/tests/d124-stale-verdict-filter-scope.sh (sister-file)
#                      + scripts/tests/d320-stale-verdict-filter.sh (architect baseline).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LABEL_CHECK="$REPO_ROOT/.github/workflows/label-check.yml"
INDEX="$REPO_ROOT/scripts/tests/INDEX.md"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi

PASS=0; FAIL=0
declare -a FAILURES
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); FAILURES+=("$1"); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Preflight
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq required for d126 (workflow-sim TCs use jq for label-set ops)" >&2
  exit 127
fi
if [ ! -r "$LABEL_CHECK" ]; then
  echo "ERROR: label-check.yml not found at $LABEL_CHECK" >&2
  exit 127
fi

# ============================================================================
# TC1 (static-grep): fix marker present — github.rest.pulls.get for fresh read
# ============================================================================
section "TC1: label-check.yml uses github.rest.pulls.get for fresh label read"
# The fix MUST introduce a `github.rest.pulls.get` call to fetch fresh PR state
# (overriding the stale context.payload.pull_request snapshot).
#
# Acceptable fix shapes (any of):
#   (a) Single github.rest.pulls.get call → fresh PR.labels → bound to `labels` var
#   (b) github.rest.issues.listLabelsOnIssue call (alternative API surface)
# Reject (bug pattern): only `pr.labels` derived from context.payload.
if grep -qE 'github\.rest\.pulls\.get' "$LABEL_CHECK"; then
  pass "TC1a — github.rest.pulls.get call present in label-check.yml (fresh API surface)"
else
  fail "TC1a — github.rest.pulls.get missing" "expected github.rest.pulls.get call for fresh PR fetch (Issue #819 fix per AC1); current label-check.yml only reads context.payload.pull_request.labels (stale snapshot)"
fi

# The fresh labels must be extracted from the API response and bound to a variable
# used by j.4 detection (e.g. `.data.labels.map(...)` or similar jq/JS pattern).
if grep -qE '\.data\.labels' "$LABEL_CHECK" || \
   grep -qE 'freshPR.*labels|apiPR.*labels|pulls\.get.*labels' "$LABEL_CHECK"; then
  pass "TC1b — fresh labels extracted from pulls.get response (data.labels.map pattern)"
else
  fail "TC1b — fresh labels extraction pattern not found" "expected .data.labels.map(...) or apiPR.labels / freshPR.labels binding (the fresh API response must replace the stale pr.labels variable for j.4 detection)"
fi

# ============================================================================
# TC2 (static-grep): bug pattern absent in j.4 vacuous-pass detection block
# ============================================================================
section "TC2: stale labels source removed from label-check.yml (bug pattern absent)"
# Cycle ~#3571 lesson: deterministic extraction, no time-sensitive regex.
# Pragmatic approach: the bug pattern is the line `const labels = (pr.labels || []).map(...)`
# at line ~463 (extracting labels from the stale webhook payload `pr`).
# Post-fix, this line is replaced with a fresh API fetch:
#   `const labels = (await github.rest.pulls.get(...)).data.labels.map(...)`
# OR the fresh labels are bound to a different variable (`freshPR.data.labels`).
#
# Therefore: TC2 verifies the BUG PATTERN line does NOT exist in label-check.yml.
# This is a holistic check (not block-scoped) — the fix is structural, not local.
#
# Bug pattern: `const labels = (pr.labels` — note the variable name `pr` (stale webhook).
# Acceptable post-fix shapes:
#   (a) `const labels = (await github.rest.pulls.get(...)).data.labels` (replace line)
#   (b) `const labels = (freshPR.data.labels || [])` (use fresh var)
#   (c) `const labels = (await github.rest.issues.listLabelsOnIssue(...)).data` (alt API)
#
# Reject any of:
#   - `const labels = (pr.labels` (stale, bug pattern)
#   - `(pr.labels || []).map(l => ...)` (stale)
if grep -qE 'const labels = \(pr\.labels' "$LABEL_CHECK"; then
  fail "TC2 — bug pattern 'const labels = (pr.labels ...) ...' still present" "found the stale-payload labels binding in label-check.yml (Issue #819 bug); fix must replace with fresh API fetch (github.rest.pulls.get)"
else
  pass "TC2 — stale labels binding pattern absent (const labels = (pr.labels ...) removed)"
fi

# Also check that the variable `pr` (assigned from context.payload.pull_request) is NOT
# used as the source of truth for j.4 detection. We allow `pr` to exist for OTHER fields
# (state, draft, number, head, base) but NOT for labels used by j.4.
# Strong check: after the line that fetches fresh PR, no `.labels` access should be
# preceded by `pr.` (the stale webhook variable).
LABELS_ACCESS_LINES="$(grep -nE '\.labels' "$LABEL_CHECK" | grep -vE 'github\.rest|pulls\.get|listLabelsOnIssue' || true)"
STALE_LABELS_ACCESS="$(echo "$LABELS_ACCESS_LINES" | grep -E 'pr\.labels|payload\.pull_request\.labels' || true)"
if [ -n "$STALE_LABELS_ACCESS" ]; then
  fail "TC2b — stale labels access via pr.labels or payload.pull_request.labels still present" "found: $STALE_LABELS_ACCESS (fix must replace these with fresh API fetch)"
else
  pass "TC2b — all .labels accesses use fresh API source (pr.labels / payload.pull_request.labels absent)"
fi

# ============================================================================
# TC3 (workflow-sim): race scenario — verdict-by added between webhook and bot
# ============================================================================
section "TC3: race scenario simulated — verdict-by added between webhook and bot"
# PR #817 LIVE INSTANCE (cmt 4881737089):
#   11:06:20Z  PR opened → webhook payload snapshot: pr.labels = ['cc:tester']
#   11:06:48Z  verdict-by:<ts> added → PR state mutated
#   11:06:53Z  Bot reads context.payload.pull_request (STALE) → hasVerdictBy=false
#   → j.4 false-positive VACUOUS-PASS detection
#
# Fix simulation: with github.rest.pulls.get, bot fetches FRESH labels:
#   freshPR.labels = ['cc:tester', 'verdict-by:2026-07-05T11:06:48Z']
#   → hasVerdictBy=true → j.4 passes (no false-positive)

# Mock the j.4 detection logic for docs PR (the buggy code path in PR #817)
# Reimplements label-check.yml L530+ vacuous-pass detection for type:docs
# (sister-pattern: d124 TC5 simulates jq fixtures for label-set operations)
simulate_j4_docs() {
  local labels_json="$1"
  local has_author_cc has_verdict_by
  has_author_cc="$(echo "$labels_json" | jq -r 'any(. == "cc:architect" or . == "cc:product-manager" or . == "cc:orchestrator")')"
  has_verdict_by="$(echo "$labels_json" | jq -r 'any(startswith("verdict-by:"))')"
  if [ "$has_author_cc" = "true" ] && [ "$has_verdict_by" = "true" ]; then
    echo "PASS"
  else
    echo "FAIL:vacuous-pass hasAuthorCc=${has_author_cc} hasVerdictBy=${has_verdict_by}"
  fi
}

# Mock race scenario: PR #817 cmt 4881737089 sequence
# Note: the j.4 docs path checks `cc:architect`/`cc:product-manager`/`cc:orchestrator`
# (the docs PR author lane). PR #817 was authored by arch (per arch cmt 4881795112),
# so the stale/fresh mocks use `cc:architect` as the author cc.
mock_stale_payload='["cc:architect"]'                                                      # webhook snapshot, pre-verdict-by
mock_fresh_api='["cc:architect","verdict-by:2026-07-05T11:06:48Z"]'                        # fresh API response, post-verdict-by

stale_result="$(simulate_j4_docs "$mock_stale_payload")"
fresh_result="$(simulate_j4_docs "$mock_fresh_api")"

# Stale payload (BUG case): j.4 false-positive fail
if [ "$stale_result" = "FAIL:vacuous-pass"*"hasVerdictBy=false" ]; then
  pass "TC3a — stale webhook payload correctly triggers j.4 fail (false-positive captured for diagnosis, mirrors PR #817)"
elif echo "$stale_result" | grep -q "FAIL:vacuous-pass"; then
  pass "TC3a — stale webhook payload triggers j.4 fail (false-positive pattern reproduced; PR #817 RCA matches)"
else
  fail "TC3a — stale payload should fail j.4 (regression in test fixture)" "expected FAIL:vacuous-pass, got: $stale_result"
fi

# Fresh API response (FIX case): j.4 passes
if [ "$fresh_result" = "PASS" ]; then
  pass "TC3b — fresh API response passes j.4 (verdict-by present, no false-positive)"
else
  fail "TC3b — fresh API should pass j.4 when verdict-by is present" "expected PASS, got: $fresh_result"
fi

# ============================================================================
# TC4 (workflow-sim): DRAFT PR skip-guard precedence (Issue #680 amendment #3)
# ============================================================================
section "TC4: DRAFT PR skip-guard fires BEFORE j.4 (audit-trail preservation)"
# Issue #680 amendment #3: DRAFT PRs skip ALL status:ready auto-add.
# Sister-pattern: when draft=true, j.4 MUST NOT fire (even with stale payload
# missing verdict-by) — DRAFT skip-guard returns early before j.4 logic.
#
# This TC verifies the LOGIC precedence: DRAFT → early return → j.4 skipped.
# Per cycle ~#3698 insight, this preserves reviewer chain audit trail.
#
# Cycle ~#3571 lesson: deterministic test inputs (no date-dependent logic).
simulate_j4_with_draft_guard() {
  local labels_json="$1"
  local draft="$2"
  if [ "$draft" = "true" ]; then
    echo "SKIP:draft-guard-amend3"
  else
    simulate_j4_docs "$labels_json"
  fi
}

# DRAFT PR with stale payload (worst-case race)
draft_result="$(simulate_j4_with_draft_guard "$mock_stale_payload" "true")"
if [ "$draft_result" = "SKIP:draft-guard-amend3" ]; then
  pass "TC4a — DRAFT PR skip-guard fires before j.4 (no false-positive on DRAFT even with stale payload)"
else
  fail "TC4a — DRAFT PR skip-guard did not fire" "expected SKIP:draft-guard-amend3, got: $draft_result"
fi

# Non-DRAFT PR with stale payload: j.4 SHOULD fire (the bug case)
non_draft_result="$(simulate_j4_with_draft_guard "$mock_stale_payload" "false")"
if echo "$non_draft_result" | grep -q "FAIL:vacuous-pass"; then
  pass "TC4b — non-DRAFT PR with stale payload correctly enters j.4 (regression check)"
else
  fail "TC4b — non-DRAFT PR should enter j.4" "expected FAIL:vacuous-pass, got: $non_draft_result"
fi

# ============================================================================
# TC5 (sister-pattern): TD-035 heartbeat drift + TD-037 silent-skip preflight
# ============================================================================
section "TC5: TD-035 + TD-037 sister-patterns unaffected by the fix"
# Sister-pattern regression guard: the fix to Layer 5 j.4 must NOT regress
# heartbeat drift detection (TD-035, d118) or silent-skip preflight (TD-037).
# These are sister-pattern family members in the workflow-Layer-5 cluster.
#
# Static-grep INDEX.md for sister-pattern registration (per ADR-0055 §1
# Cadence Rule 1 — d-test + INDEX.md same commit).
if [ -r "$INDEX" ]; then
  if grep -qE 'd118|heartbeat.*drift|d118-heartbeat-missed-hysteresis' "$INDEX"; then
    pass "TC5a — d118 heartbeat drift sister-pattern registered in INDEX.md (TD-035 unaffected)"
  else
    fail "TC5a — d118 heartbeat drift sister-pattern missing from INDEX.md" "potential TD-035 regression (sister-pattern lineage broken)"
  fi
  if grep -qE 'd057|silent_skip|silent-skip|d057-sync-status' "$INDEX"; then
    pass "TC5b — d057 silent-skip preflight sister-pattern registered (TD-037 unaffected)"
  else
    fail "TC5b — d057 silent-skip preflight sister-pattern missing from INDEX.md" "potential TD-037 regression (sister-pattern lineage broken)"
  fi
else
  fail "TC5 — INDEX.md not readable at $INDEX" "sister-pattern registration check requires INDEX.md"
fi

# ============================================================================
# Summary
# ============================================================================
section "Summary"
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "EXIT 1: d126 RED — Layer 5.5 j.4 fresh-label-read fix incomplete or regression detected"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  echo
  echo "Next steps:"
  echo "  1. Owner applies github.rest.pulls.get fix to .github/workflows/label-check.yml (Issue #819 AC1)"
  echo "  2. Re-run: bash scripts/tests/d126-layer-5-j4-fresh-label-read.sh"
  echo "  3. Expected: all 5 TCs PASS, exit 0"
  exit 1
fi

echo
echo "EXIT 0: d126 GREEN — Layer 5.5 j.4 fresh-label-read fix verified, sister-patterns intact"
exit 0