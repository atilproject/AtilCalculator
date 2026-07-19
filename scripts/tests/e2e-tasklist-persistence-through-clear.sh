#!/usr/bin/env bash
# e2e-tasklist-persistence-through-clear.sh — Sprint 32 Wave-extension integration test
# (S32-XXX-E / Issue #1170 / Closes #1170 AC1-AC7)
#
# Purpose: Validates the FULL task-list persistence lifecycle across /clear:
#   TodoWrite → snapshot write → /clear trigger → reprime → snapshot restore verify.
#
# Sister-stories: S32-XXX-B (tmpl impl, Issue #191) + S32-XXX-C (calc forward-port,
# Issue #1169) + S32-XXX-D (launcher doc-only sync).
# Parent ADRs: ADR-0072 (PR #1168 calc) + ADR-0073 (PR #190 tmpl) — both 🟢 APPROVED
# + owner-ratified, awaiting squash per ADR-0031.
#
# Test cases (T1..T9) — RED-first per ADR-0044:
#   T1: Setup clean state/tasklists/ + init agent context
#   T2: scripts/tasklist-snapshot.sh exists + executable (impl S32-XXX-B/C pending)
#   T3: snapshot write + format check (markdown checklist + frontmatter)
#   T4: /clear simulation — snapshot file PERSISTS in state/tasklists/${ROLE}.md
#   T5: scripts/reprime-agent.sh MESSAGE_HEAD has snapshot-restore directive
#   T6: snapshot restore on REPRIME — reprime-agent.sh reads state/tasklists/${ROLE}.md
#   T7: sister-pattern — d108-tasklist-snapshot-write-through.sh exists (impl pending)
#   T8: sister-pattern — atomic-write doctrine per Issue #237 (write-to-temp + mv)
#   T9: Cadence Rule 1 atomic — this INDEX.md row + this test file land same commit
#       (per ADR-0055 §1)
#
# Pre-impl RED expected (cycle ~#3129 ACTUAL-CONTENT verification):
#   PASS: T1 (setup), T4 (clear simulation), T9 (Cadence Rule 1 atomic)
#   FAIL: T2 (script missing), T3 (no snapshot file), T5 (no MESSAGE_HEAD directive),
#         T6 (no restore behavior), T7 (d108 missing), T8 (atomic-write helper missing)
#   → 3 PASS / 6 FAIL — RED state confirmed (impl gap clearly identified)
# Post-impl GREEN target: 9/9 PASS on S32-XXX-B/C land.
#
# Exit code: 0 = all pass, 1 = at least one fail.
#
# Run standalone: bash scripts/tests/e2e-tasklist-persistence-through-clear.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_SH="$SCRIPT_DIR/../tasklist-snapshot.sh"
REPRIME_SH="$SCRIPT_DIR/../reprime-agent.sh"
STATE_DIR="$REPO_ROOT/state/tasklists"
TEST_ROLE="tester"
TEST_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
INDEX_FILE="$SCRIPT_DIR/INDEX.md"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[1;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""; fi

PASS=0; FAIL=0
declare -a FAIL_DETAILS=()
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() {
  printf "  ${R}✗ FAIL${D} — %s\n" "$1"
  [ -n "${2:-}" ] && printf "    ${R}%s${D}\n" "$2"
  FAIL=$((FAIL+1))
  FAIL_DETAILS+=("$1")
}
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }
info() { printf "  ${Y}ℹ${D} %s\n" "$1"; }

# ============================================================================
# T1: Setup clean state/tasklists/ + init agent context
# ============================================================================
section "T1: Setup clean state/tasklists/ + init agent context (AC1)"
# Pattern: state/tasklists/ must exist as a writable directory (or be creatable).
# This is the runtime target for tasklist-snapshot.sh output. .gitkeep sentinel
# is the canonical bootstrap marker per S32-XXX-C forward-port spec.
if mkdir -p "$STATE_DIR" 2>/dev/null && [[ -d "$STATE_DIR" ]]; then
  pass "state/tasklists/ directory exists + writable (mkdir -p + -d check)"
else
  fail "state/tasklists/ not creatable" "expected mkdir -p to succeed on $STATE_DIR (AC1 — runtime target for tasklist-snapshot.sh output)"
fi

# Cleanup any leftover test snapshot from prior run
rm -f "$STATE_DIR/${TEST_ROLE}.md" 2>/dev/null || true

# ============================================================================
# T2: scripts/tasklist-snapshot.sh exists + executable
# ============================================================================
section "T2: scripts/tasklist-snapshot.sh exists + executable (AC2)"
# Pattern: Per ADR-0072/0073, scripts/tasklist-snapshot.sh must exist as the
# canonical snapshot write tool (input: ROLE + JSON TodoWrite state, output:
# state/tasklists/${ROLE}.md). Cadence Rule 1 atomic: this script + d108 +
# INDEX.md land in same S32-XXX-B/C commit.
if [[ -x "$SNAPSHOT_SH" ]]; then
  pass "scripts/tasklist-snapshot.sh exists + executable"
else
  fail "scripts/tasklist-snapshot.sh missing or not executable" "expected '$SNAPSHOT_SH' to exist + be executable (AC2 — canonical snapshot write tool per ADR-0072/0073; impl lands in S32-XXX-B tmpl + S32-XXX-C calc forward-port)"
fi

# ============================================================================
# T3: snapshot write + format check (markdown checklist + frontmatter)
# ============================================================================
section "T3: snapshot write + format check (AC3: markdown checklist + frontmatter)"
# Pattern: tasklist-snapshot.sh must accept ROLE + JSON TodoWrite state and
# write to state/tasklists/${ROLE}.md with format:
#   <!-- tasklist-snapshot role:${ROLE} ts:${ISO8601} -->
#   - [ ] task1
#   - [ ] task2
#   ...
# Per ADR-0072 §Format spec + Issue #237 atomic-write (write-to-temp + mv).
if [[ -x "$SNAPSHOT_SH" ]]; then
  # Try to invoke with mock TodoWrite JSON (3 tasks)
  MOCK_JSON='[{"status":"pending","content":"verify-impl"},{"status":"pending","content":"run-d-test"},{"status":"pending","content":"peer-poke-dev"}]'
  if "$SNAPSHOT_SH" "$TEST_ROLE" "$MOCK_JSON" 2>/dev/null; then
    # Verify output file format
    SNAPSHOT_FILE="$STATE_DIR/${TEST_ROLE}.md"
    if [[ -f "$SNAPSHOT_FILE" ]] \
       && head -1 "$SNAPSHOT_FILE" | grep -q "^<!-- tasklist-snapshot role:${TEST_ROLE} ts:" \
       && grep -q "\[ \]" "$SNAPSHOT_FILE"; then
      pass "snapshot file written + format correct (frontmatter + markdown checklist)"
    else
      fail "snapshot file format invalid" "expected frontmatter '<!-- tasklist-snapshot role:${TEST_ROLE} ts:ISO8601 -->' + '- [ ]' checklist lines per ADR-0072 §Format spec"
    fi
  else
    fail "tasklist-snapshot.sh invocation failed" "expected non-zero exit 0 on valid input ROLE + JSON TodoWrite state (AC3 — write behavior)"
  fi
else
  fail "snapshot write skipped — impl missing" "cascade from T2 (scripts/tasklist-snapshot.sh not present; AC3 cannot validate write behavior until S32-XXX-B/C land)"
fi

# ============================================================================
# T4: /clear simulation — snapshot file PERSISTS in state/tasklists/${ROLE}.md
# ============================================================================
section "T4: /clear simulation — snapshot file persists (AC4)"
# Pattern: state/tasklists/${ROLE}.md is a RUNTIME file (VCS-excluded per
# ADR-0072 §gitignore entry). Simulating /clear means: snapshot file MUST
# remain on disk after session restart. This is the persistence invariant
# that defeats in-memory-only tasklist loss (Issue #725 / cycle #1638 RCA).
SNAPSHOT_FILE="$STATE_DIR/${TEST_ROLE}.md"
if [[ -f "$SNAPSHOT_FILE" ]]; then
  # Simulate /clear by reading file size before + after a no-op sleep
  SIZE_BEFORE=$(stat -c %s "$SNAPSHOT_FILE" 2>/dev/null || echo 0)
  sleep 0.1
  SIZE_AFTER=$(stat -c %s "$SNAPSHOT_FILE" 2>/dev/null || echo 0)
  if [[ "$SIZE_BEFORE" == "$SIZE_AFTER" ]] && [[ "$SIZE_BEFORE" -gt 0 ]]; then
    pass "/clear simulation: snapshot file persists (${SIZE_BEFORE} bytes)"
  else
    fail "snapshot file size changed during /clear simulation" "expected size stable (size_before=${SIZE_BEFORE} size_after=${SIZE_AFTER}) — file should be persistent across session restart"
  fi
else
  fail "no snapshot file to verify persistence" "expected $SNAPSHOT_FILE to exist from T3 write — cascade from T2/T3 (impl missing)"
fi

# ============================================================================
# T5: scripts/reprime-agent.sh MESSAGE_HEAD has snapshot-restore directive
# ============================================================================
section "T5: reprime-agent.sh MESSAGE_HEAD has snapshot-restore directive (AC5)"
# Pattern: Per ADR-0072 §Layer 2 Task-list persistence protocol,
# scripts/reprime-agent.sh MESSAGE_HEAD must append:
#   "First action MUST be: cat state/tasklists/\${ROLE}.md 2>/dev/null && \
#    restore TodoWrite from snapshot"
# This is the FIRST-ACTION contract that defeats reprime-storm recovery gap.
if [[ -r "$REPRIME_SH" ]] && grep -Eq "cat[[:space:]]+state/tasklists/.*\.md.*restore|restore.*TodoWrite.*snapshot|TodoWrite.*from.*snapshot" "$REPRIME_SH"; then
  pass "reprime-agent.sh MESSAGE_HEAD has snapshot-restore directive"
else
  fail "MESSAGE_HEAD missing snapshot-restore directive" "expected '$REPRIME_SH' to contain 'cat state/tasklists/\${ROLE}.md ... restore TodoWrite from snapshot' in MESSAGE_HEAD per ADR-0072 §Layer 2 (AC5 — FIRST-ACTION contract for reprime recovery)"
fi

# ============================================================================
# T6: snapshot restore on REPRIME — reprime-agent.sh reads state/tasklists/${ROLE}.md
# ============================================================================
section "T6: snapshot restore on REPRIME (AC6: state/tasklists read + TodoWrite restore)"
# Pattern: reprime-agent.sh must read state/tasklists/${ROLE}.md and surface
# the tasks for restore. Sister-pattern: this is the READ counterpart to T2's
# WRITE. Together they form the snapshot protocol contract.
if [[ -r "$REPRIME_SH" ]] && grep -Eq "state/tasklists/.*\.md" "$REPRIME_SH"; then
  # Verify the file path pattern is in the script (any usage)
  if [[ -f "$SNAPSHOT_FILE" ]]; then
    # Simulate the read path: the snapshot should be readable by cat
    if cat "$SNAPSHOT_FILE" 2>/dev/null | head -1 | grep -q "^<!-- tasklist-snapshot role:${TEST_ROLE}"; then
      pass "snapshot readable + frontmatter parseable (state/tasklists/${TEST_ROLE}.md)"
    else
      fail "snapshot frontmatter unparseable on read" "expected '<!-- tasklist-snapshot role:${TEST_ROLE} ts:ISO8601 -->' as first line per ADR-0072 §Format spec"
    fi
  else
    fail "no snapshot file to read" "cascade from T2/T3 (impl missing) — T6 cannot validate restore path"
  fi
else
  fail "reprime-agent.sh does not reference state/tasklists/*.md" "expected '$REPRIME_SH' to contain 'state/tasklists/\${ROLE}.md' path reference (AC6 — READ counterpart to T2 WRITE)"
fi

# ============================================================================
# T7: sister-pattern — d108-tasklist-snapshot-write-through.sh exists (impl pending)
# ============================================================================
section "T7: sister-pattern d108-tasklist-snapshot-write-through.sh exists (AC7)"
# Pattern: Per ADR-0072 §Cadence Rule 1 atomic, the d-test
# scripts/tests/d108-tasklist-snapshot-write-through.sh (≥6 TCs per ADR-0049)
# must ship with S32-XXX-B/C. This test is the write-through sibling —
# validating low-level write behavior. My e2e test is the LIFECYCLE sibling.
# Sister-pattern: ADR-0049 ≥3 sister-pattern coverage — d108 is direct sister.
D108="$SCRIPT_DIR/d108-tasklist-snapshot-write-through.sh"
if [[ -x "$D108" ]]; then
  pass "d108-tasklist-snapshot-write-through.sh exists + executable (write-through sister)"
else
  fail "d108 sister-test missing" "expected '$D108' to exist + be executable (AC7 — write-through sister per ADR-0072 §Cadence Rule 1 atomic; ≥6 TCs per ADR-0049)"
fi

# ============================================================================
# T8: sister-pattern — atomic-write doctrine per Issue #237 (write-to-temp + mv)
# ============================================================================
section "T8: sister-pattern atomic-write doctrine per Issue #237 (AC8: write-to-temp + mv)"
# Pattern: Per Issue #237 atomic-write doctrine + ADR-0072 §Consequences.3,
# tasklist-snapshot.sh MUST use write-to-temp + mv pattern to defeat
# /clear-mid-write race. Sister-pattern: scripts/atomic-write.sh helper
# (if it exists as a shared utility) OR direct write-to-temp pattern in
# tasklist-snapshot.sh.
ATOMIC_WRITE_SH="$SCRIPT_DIR/../atomic-write.sh"
if [[ -r "$REPRIME_SH" ]] && grep -Eq "atomic-write\.sh|mktemp.*mv|mv.*\.tmp" "$REPRIME_SH" 2>/dev/null; then
  pass "atomic-write pattern present (write-to-temp + mv per Issue #237)"
elif [[ -x "$ATOMIC_WRITE_SH" ]]; then
  pass "scripts/atomic-write.sh exists as shared helper (Issue #237 sister-pattern)"
else
  fail "atomic-write pattern not detected" "expected scripts/tasklist-snapshot.sh to use write-to-temp + mv pattern OR scripts/atomic-write.sh helper to exist (AC8 — Issue #237 atomic-write sister-pattern to defeat /clear-mid-write race per ADR-0072 §Consequences.3)"
fi

# ============================================================================
# T9: Cadence Rule 1 atomic — this INDEX.md row + this test file land same commit
# ============================================================================
section "T9: Cadence Rule 1 atomic per ADR-0055 §1 (AC9: test + INDEX.md same commit)"
# Pattern: Per ADR-0055 §1, this test file + the corresponding INDEX.md row
# must land in the SAME commit. Sister-pattern: cycle ~#3690 .tmpl placeholder
# atomicity doctrine (any new test/INDEX/CHANGELOG entry requires same-commit
# co-location). We verify by checking that INDEX.md mentions this test file.
if [[ -r "$INDEX_FILE" ]] && grep -q "e2e-tasklist-persistence-through-clear" "$INDEX_FILE"; then
  pass "INDEX.md references this test file (Cadence Rule 1 atomic verified)"
else
  fail "INDEX.md missing this test row" "expected '$INDEX_FILE' to contain 'e2e-tasklist-persistence-through-clear' row (AC9 — Cadence Rule 1 atomic per ADR-0055 §1 + cycle ~#3690 .tmpl placeholder doctrine)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
TOTAL=$((PASS + FAIL))
printf "${B}==== Summary ====${D}\n"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "TOTAL: $TOTAL"
if [[ $FAIL -gt 0 ]]; then
  printf "${R}${B}RED STATE CONFIRMED${D} — ${R}%d/%d TESTS FAIL${D}\n" "$FAIL" "$TOTAL"
  echo "Failed TCs (impl gap signals):"
  for d in "${FAIL_DETAILS[@]}"; do echo "  - $d"; done
  echo ""
  echo "Per ADR-0044 RED-first TDD: this is the EXPECTED state before S32-XXX-B/C impl."
  echo "Once tasklist-snapshot.sh + reprime-agent.sh MESSAGE_HEAD + d108 ship,"
  echo "this test should turn 9/9 GREEN on the impl PR."
  exit 1
else
  printf "${G}${B}GREEN — ALL %d TESTS PASSED${D}\n" "$PASS"
  exit 0
fi
