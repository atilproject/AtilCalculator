#!/usr/bin/env bash
# d862-agent-watch-orch-lens-fix.sh — Issue #862 RCA regression test
#   (orchestrator label_change lens `_q: unbound variable` + dedup collapse pathology)
#
# Why this test exists
# --------------------
# Issue #862 surfaced that `scripts/agent-watch.sh:query_board_changes()` orchestrator
# path (lines 1418-1432) does:
#
#   gh issue list --state all --limit 50 --json number,title,url,updatedAt,labels,state
#   echo "$_q" | jq "..."
#
# but `_q` is never assigned (only the bare `gh issue list` STDOUT goes to the outer
# `board="..."` capture). This causes:
#   1. `_q: unbound variable` stderr leak (shell with `set -u` aborts; without, echoes
#      empty string → `[]` from jq)
#   2. Outer `board` captures raw gh JSON + `[]` → `jq -s 'add | unique_by(.id)'`
#      collapses the raw gh array (no `.id` field) to ONE entry keyed by `null`
#      = the most-recently-updated issue
#   3. That one bogus event has no `.id` → `processed_event_ids` cannot dedup →
#      orchestrator wakes on the same most-recent issue EVERY poll
#
# Fix (developer lane): replace `gh issue list ...` with `gh_all_repos _q gh issue list ...`
# in the orchestrator path, matching the 7 sister call sites (lines 590, 630, 669, 698,
# 1044, 1103, 1396).
#
# Test framework: bash + grep + jq + behavioral fixture (extract query_board_changes
# from source, mock gh, set ROLE=orchestrator, run + assert).
# ADR-0044 RED-first TDD: pre-impl on main HEAD expected to FAIL on TC1+TC2 (static-grep
# capture pattern absent) AND TC3 (stderr leak) AND TC5 (collapse). TC4 may pass
# coincidentally if `add | unique_by(.id)` happens to collapse correctly. Post-impl
# expected: all 5 PASS.
#
# Sister-pattern lineage:
#   - d020a (claim Form C, 5 TCs, fake-gh factory)
#   - d058 (claim WIP workstream, 9 TCs, fake-gh factory)
#   - d064 (cluster-lag, 5 TCs, ADR-0059)
#   - d052 (agent-watch hardening T1-T4, static-grep)
#   - d046a (ADR-0046 §A literal-form guard, static-grep)
#   - d094 (label query bash/jq sync — pattern reference per Issue #862 body)
#
# Refs: Issue #862 (P2 BUG, orchestrator RCA), arch 9-Lens co-pilot cmt (PR comment
#       thread), dev claim cmt, ADR-0036 §Part A (role-aware label change visibility),
#       ADR-0044 (RED-first TDD), ADR-0049 (d-test framework ≥3 baseline + ≥5 with
#       sister-pattern), ADR-0055 §1 (Cadence Rule 1 atomic — d-test + INDEX.md row
#       + impl same PR cluster).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WATCH_SH="${REPO_ROOT}/scripts/agent-watch.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""
fi

PASS=0; FAIL=0
declare -a FAILURES
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); FAILURES+=("$1"); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Pre-flight
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required for d862" >&2; exit 127; }
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required for d862" >&2; exit 127; }
[ -f "$WATCH_SH" ] || { echo "ERROR: agent-watch.sh not found at $WATCH_SH" >&2; exit 127; }

# ============================================================================
# TC1: orchestrator path uses `gh_all_repos _q gh issue list` (capture pattern)
# ============================================================================
section "TC1: orchestrator path uses gh_all_repos _q capture (matches 7 sister call sites)"
# The fix replaces bare `gh issue list ...` with `gh_all_repos _q gh issue list ...`.
# Verify the capture pattern is present in the orchestrator path (lines ~1418-1432).
ORCH_CAPTURE_FOUND=0
# Extract lines around the orchestrator path (after the `if [ "$ROLE" != "orchestrator" ]` branch)
# and check for gh_all_repos _q capture.
ORCH_LINES=$(awk '/if \[ "\$ROLE" != "orchestrator" \]; then/,/^}/' "$WATCH_SH" | tail -n +2)
if echo "$ORCH_LINES" | grep -qE 'gh_all_repos _q gh issue list'; then
  ORCH_CAPTURE_FOUND=1
fi
if [ "$ORCH_CAPTURE_FOUND" = "1" ]; then
  pass "TC1 — orchestrator path captures gh output into _q (gh_all_repos _q pattern present, post-fix)"
else
  fail "TC1 — orchestrator path missing gh_all_repos _q capture" \
    "expected 'gh_all_repos _q gh issue list' in orchestrator path (lines ~1418-1432); current main has bare 'gh issue list' (RED state per ADR-0044)"
fi

# ============================================================================
# TC2: orchestrator path does NOT have bare `gh issue list` without capture
# ============================================================================
section "TC2: orchestrator path does NOT have bare gh issue list without capture"
# Inverse of TC1: verify the BUGGY pattern is gone.
BARE_GH_FOUND=0
# Look for `gh issue list` (NOT preceded by `_q` or capture syntax) within the orchestrator
# path region.
if echo "$ORCH_LINES" | grep -qE '^\s*gh issue list'; then
  BARE_GH_FOUND=1
fi
if [ "$BARE_GH_FOUND" = "0" ]; then
  pass "TC2 — no bare gh issue list in orchestrator path (capture pattern enforced)"
else
  fail "TC2 — bare gh issue list still in orchestrator path" \
    "expected: no bare 'gh issue list' without capture; current: bare call present (RED state — _q unbound pathology)"
fi

# ============================================================================
# TC3: stderr silence — sourcing query_board_changes with mocked gh emits no `_q: unbound`
# ============================================================================
section "TC3: stderr silence (no _q: unbound variable leak)"
# Set up a fake gh binary in PATH that returns a controlled JSON fixture.
# Extract query_board_changes from agent-watch.sh, source it with ROLE=orchestrator,
# call it, capture stderr, assert no `_q: unbound` line.
TEST_TMPDIR="$(mktemp -d /tmp/d862-XXXXXX)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

FAKE_BIN="$TEST_TMPDIR/bin"
mkdir -p "$FAKE_BIN"

# Build fake gh that returns a JSON array of 3 issues when called as
# `gh issue list --state all --limit 50 --json ...` (orchestrator path).
# All 3 issues have updatedAt AFTER LAST_SEEN so they should all surface.
cat > "$FAKE_BIN/gh" <<'FAKE_GH_EOF'
#!/usr/bin/env bash
# Detect orchestrator-path call shape: `gh issue list --state all --limit 50 --json ...`
if [ "$1" = "issue" ] && [ "$2" = "list" ]; then
  cat <<'GH_JSON_EOF'
[
  {"number": 800, "title": "Issue A", "updatedAt": "2026-07-01T10:00:00Z", "labels": [{"name":"agent:tester"}], "state": "open"},
  {"number": 801, "title": "Issue B", "updatedAt": "2026-07-01T11:00:00Z", "labels": [{"name":"agent:developer"}], "state": "open"},
  {"number": 802, "title": "Issue C", "updatedAt": "2026-07-01T12:00:00Z", "labels": [{"name":"agent:architect"}], "state": "open"}
]
GH_JSON_EOF
  exit 0
fi
# Fallback: empty array (defensive — should not be hit in orchestrator path)
echo "[]"
FAKE_GH_EOF
chmod +x "$FAKE_BIN/gh"

# Extract BOTH query_board_changes AND gh_all_repos from agent-watch.sh.
# The dev's fix at line 1423 (matches 7 sister call sites L590, L630, L669, L698,
# L1044, L1103, L1396) replaces bare `gh issue list` with `gh_all_repos _q gh issue list`.
# gh_all_repos is defined at L290-305 (close sibling in same file), so the fixture
# needs to source it too — otherwise the post-fix invocation emits
# 'gh_all_repos: command not found' on stderr, masking the real `_q: unbound variable`
# pathology that RED-state captures.
EXTRACTED_FUNC="$TEST_TMPDIR/query_board_changes.sh"
awk '/^query_board_changes\(\) \{/,/^\}/' "$WATCH_SH" > "$EXTRACTED_FUNC"

GH_ALL_REPOS_FUNC="$TEST_TMPDIR/gh_all_repos.sh"
awk '/^gh_all_repos\(\) \{/,/^\}/' "$WATCH_SH" > "$GH_ALL_REPOS_FUNC"

# Sanity check extraction (both functions required for GREEN state)
if [ ! -s "$EXTRACTED_FUNC" ]; then
  fail "TC3 — could not extract query_board_changes from agent-watch.sh" \
    "expected function definition lines 1384-1433; extraction empty (file structure changed?)"
  exit 1
fi
if [ ! -s "$GH_ALL_REPOS_FUNC" ]; then
  fail "TC3 — could not extract gh_all_repos from agent-watch.sh" \
    "expected function definition lines 286-305; extraction empty (file structure changed?)"
  exit 1
fi

# Source both functions with required globals set, run the FULL outer pipeline that the
# orchestrator uses (board="$(query_board_changes)" + jq -s 'add | unique_by(.id)').
STDERR_FILE="$TEST_TMPDIR/stderr_capture.txt"
STDOUT_FILE="$TEST_TMPDIR/stdout_capture.txt"
(
  export PATH="$FAKE_BIN:$PATH"
  export ROLE="orchestrator"
  export LAST_SEEN="2000-01-01T00:00:00Z"
  export REPO="atilcan65/AtilCalculator"
  # shellcheck disable=SC1090
  # Source gh_all_repos first (line 290), then query_board_changes (line 1384), then
  # populate REPOS[] (required by gh_all_repos, line 295).
  source "$GH_ALL_REPOS_FUNC"
  source "$EXTRACTED_FUNC"
  REPOS=("$REPO")
  # Simulate the full outer pipeline that orchestrator's poll_once runs:
  #   board="$(query_board_changes)"
  #   echo "$board" | jq -s 'add | unique_by(.id)'
  board="$(query_board_changes 2>"$STDERR_FILE")"
  printf '%s' "$board" | jq -s 'add | unique_by(.id)' > "$STDOUT_FILE" 2>> "$STDERR_FILE" || true
)

# Check stderr for `_q: unbound`
if grep -qE '_q: unbound variable|unbound variable' "$STDERR_FILE"; then
  fail "TC3 — _q: unbound variable stderr leak detected" \
    "expected: clean stderr; current: $(head -1 "$STDERR_FILE") (RED state — bare gh issue list not captured into _q)"
else
  pass "TC3 — stderr clean (no _q: unbound variable leak, capture pattern working)"
fi

# ============================================================================
# TC4: outer pipeline produces 3 events with 3 unique IDs (no null-collapse)
# ============================================================================
section "TC4: outer pipeline produces 3 events with 3 unique IDs (no null-collapse)"
# Parse stdout: should be 3 events with 3 unique IDs after add|unique_by(.id).
# BUG behavior: outer pipeline collapses 3 raw gh entries (no .id field) to 1 entry
# keyed by null → 1 event in new_events.
EVENT_COUNT=$(jq 'length' "$STDOUT_FILE" 2>/dev/null || echo "0")
UNIQUE_IDS=$(jq '[.[].id] | unique | length' "$STDOUT_FILE" 2>/dev/null || echo "0")

if [ "$EVENT_COUNT" = "3" ] && [ "$UNIQUE_IDS" = "3" ]; then
  pass "TC4 — outer pipeline returns 3 events with 3 unique IDs (no null-collapse, post-fix)"
else
  fail "TC4 — outer pipeline collapse detected" \
    "expected: 3 events with 3 unique IDs; current: count=$EVENT_COUNT, unique_ids=$UNIQUE_IDS (RED state — null-id collapse to 1 most-recent entry)"
fi

# ============================================================================
# TC5: N=3 distinct updated_at timestamps surface as 3 events (temporal collapse guard)
# ============================================================================
section "TC5: 3 distinct updated_at timestamps produce 3 events (no temporal collapse)"
# Stricter check than TC4: verify that 3 distinct updatedAt timestamps produce
# 3 distinct events, not 1 collapsed most-recently-updated entry.
DISTINCT_TIMESTAMPS=$(jq -r '[.[].updated_at] | unique | length' "$STDOUT_FILE" 2>/dev/null || echo "0")
if [ "$DISTINCT_TIMESTAMPS" = "3" ]; then
  pass "TC5 — 3 distinct updated_at timestamps produce 3 events (no temporal collapse)"
else
  fail "TC5 — temporal collapse detected" \
    "expected: 3 distinct updated_at; current: $DISTINCT_TIMESTAMPS (RED state — outer pipeline collapses raw gh array to 1 most-recent entry)"
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== SUMMARY (d862 — Issue #862 orchestrator label_change lens fix) ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf "  ${R}Failures${D}:\n"
  for f in "${FAILURES[@]}"; do
    printf "    - %s\n" "$f"
  done
  printf "\n${R}RED state confirmed${D} — impl fix in scripts/agent-watch.sh orchestrator path required (developer lane).\n"
  exit 1
fi
printf "\n${G}GREEN state confirmed${D} — orchestrator path capture pattern + dedup working correctly.\n"
exit 0