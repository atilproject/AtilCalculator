#!/usr/bin/env bash
# d127-td-067-transient-regex-preserve.sh — Issue #922 TD-067 regression guard
# (label-cleanup.yml TRANSIENT_REGEX narrowing preserves agent:* + cc:* on PR close)
#
# Why this test exists
# --------------------
# Sprint 24+ LIVE INSTANCE: PRs #918 + #919 (sister GA cut PRs, both squash-merged)
# had agent:* + cc:* labels STRIPPED by .github/workflows/label-cleanup.yml on
# pull_request: closed event (root cause: TRANSIENT_REGEX='^(cc:|agent:|needs-)|^agent-stall$'
# matched agent: and cc: prefixes).
#
# Fix: narrow TRANSIENT_REGEX to '^(needs-)|^agent-stall$' — agent:* + cc:*
# labels are PRESERVED on closed PRs. needs-* + agent-stall still removed
# (preserved transient-cleanup behavior). Status labels still advance via
# separate STATUS_ADVANCE_REGEX (unchanged).
#
# 5 TCs (1 baseline preservation + 4 TD-067 fix assertions, RED-first per ADR-0044).
# Pre-impl expected: 1 PASS (TC1 baseline) + 4 FAIL (TC2-TC5 violations of fix intent).
# Post-impl expected: 5 PASS (all TCs green).
#
# Test pattern: sister-pattern to d067-proactive-scan + d062 source-grep regression.
# No mock complexity — pure source inspection verifies the regex is correctly
# narrowed. Behavioral verification happens in production via squash-merge
# integration testing (tester probes 1, 3, 6 per issue #922 cmt 4923610102).
#
# Doctrine anchors:
# - ADR-0012 (4-cat label invariant) — preserved on closed PRs
# - ADR-0009 §10.3 (pr_labeled wake audit) — preserved on closed PRs
# - ADR-0038 (auto-claim protocol) — depends on pr_labeled wake
# - ADR-0044 TDD RED contract
# - ADR-0049 d-test framework (≥5 baseline)
# - ADR-0055 §1 Cadence Rule 1 atomic (d-test + INDEX.md entry in same PR)
# - ADR-0057 §Closes-vs-Refs Intent Rule (Refs #922, not Closes #922 — partial scope)
# - Issue #922 (TD-067 doctrinal home)
# - docs/designs/TD-067-TD-068-sister-fix-design.md (design contract)
# - RETRO-016 sister-pattern lineage (post-action invariant break, silent)
# - d067 (TD-068 sister-test, Issue #920 state-file-axis fix) — direct sister on
#   TD-067+TD-068 sister-pattern classification per design doc §Sister-pattern lineage
# - d046a/d046b (label-check sister-pattern source-grep regression guard family)
# - d048 (4-cat invariant sister-pattern, status:ready gating)
#
# ID clash resolution per ADR-0055 §sub-pattern remediation: d067 prefix is
# taken by d067-proactive-scan-per-role-overflow.sh (Sprint 18 P1, Issue #610).
# d127 = next available slot in post-Sprint 18 d-test family naming range.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/label-cleanup.yml"

# TTY-aware color setup (sister-pattern to d058/d062/d066/d067)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""
fi

PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Preflight
[ -f "$WORKFLOW_FILE" ] || { echo "ERROR: label-cleanup.yml not found" >&2; exit 2; }

# Self-test mode (RED-first per ADR-0044)
if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: bash $0 --self-test" >&2
  exit 2
fi

# ------------------------------------------------------------------
# Extract TRANSIENT_REGEX from the workflow file
# ------------------------------------------------------------------
EXTRACTED_REGEX=$(grep -oE "TRANSIENT_REGEX='[^']+'" "$WORKFLOW_FILE" | head -1 | sed -E "s/TRANSIENT_REGEX='([^']+)'/\1/")

if [ -z "$EXTRACTED_REGEX" ]; then
  echo "ERROR: TRANSIENT_REGEX not found in $WORKFLOW_FILE" >&2
  exit 2
fi

printf "${B}Extracted TRANSIENT_REGEX${D}: ${Y}%s${D}\n" "$EXTRACTED_REGEX"

# Helper: test if a label matches the TRANSIENT_REGEX (= "transient" → would be stripped)
matches_transient() {
  local label="$1"
  [[ "$label" =~ $EXTRACTED_REGEX ]]
}

# ================================================================
# TC1 — Baseline: needs-* labels ARE matched (preserved behavior)
# ================================================================
section "TC1: needs-* labels remain transient (preserved behavior)"
if matches_transient "needs-tester-signoff"; then
  pass "needs-tester-signoff still matched (transient cleanup preserved)"
else
  fail "needs-tester-signoff NOT matched" "Regression: needs-* transient behavior lost"
fi
if matches_transient "needs-architect-review"; then
  pass "needs-architect-review still matched (preserved behavior)"
else
  fail "needs-architect-review NOT matched" "Regression: needs-* transient behavior lost"
fi

# ================================================================
# TC2 — TD-067 fix: agent:* labels NOT matched (preserved on close)
# ================================================================
section "TC2: agent:* labels PRESERVED on PR close (TD-067 fix)"
if matches_transient "agent:developer"; then
  fail "agent:developer IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match agent:* prefix"
else
  pass "agent:developer NOT matched (PRESERVED on close)"
fi
if matches_transient "agent:architect"; then
  fail "agent:architect IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match agent:* prefix"
else
  pass "agent:architect NOT matched (PRESERVED on close)"
fi
if matches_transient "agent:tester"; then
  fail "agent:tester IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match agent:* prefix"
else
  pass "agent:tester NOT matched (PRESERVED on close)"
fi

# ================================================================
# TC3 — TD-067 fix: cc:* labels NOT matched (preserved on close)
# ================================================================
section "TC3: cc:* labels PRESERVED on PR close (TD-067 fix)"
if matches_transient "cc:human"; then
  fail "cc:human IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match cc:* prefix"
else
  pass "cc:human NOT matched (PRESERVED on close — owner merge gate attribution kept)"
fi
if matches_transient "cc:architect"; then
  fail "cc:architect IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match cc:* prefix"
else
  pass "cc:architect NOT matched (PRESERVED on close — review attribution kept)"
fi
if matches_transient "cc:developer"; then
  fail "cc:developer IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match cc:* prefix"
else
  pass "cc:developer NOT matched (PRESERVED on close — impl attribution kept)"
fi
if matches_transient "cc:tester"; then
  fail "cc:tester IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match cc:* prefix"
else
  pass "cc:tester NOT matched (PRESERVED on close — sign-off attribution kept)"
fi
if matches_transient "cc:orchestrator"; then
  fail "cc:orchestrator IS matched (will be STRIPPED on close)" \
       "TD-067 regression: TRANSIENT_REGEX must NOT match cc:* prefix"
else
  pass "cc:orchestrator NOT matched (PRESERVED on close — sprint coord kept)"
fi

# ================================================================
# TC4 — agent-stall label still matched (preserved behavior)
# ================================================================
section "TC4: agent-stall label still matched (preserved behavior)"
if matches_transient "agent-stall"; then
  pass "agent-stall still matched (preserved behavior)"
else
  fail "agent-stall NOT matched" "Regression: agent-stall transient behavior lost"
fi

# ================================================================
# TC5 — Other label categories PRESERVED (type:*, status:done, priority:*)
# ================================================================
section "TC5: Other label categories PRESERVED (type:*, status:done, priority:*)"
if matches_transient "type:bug"; then
  fail "type:bug IS matched (will be STRIPPED on close)" \
       "Regression: type:* is metadata, must NOT be in TRANSIENT_REGEX"
else
  pass "type:bug NOT matched (PRESERVED on close — type label kept)"
fi
if matches_transient "priority:P1"; then
  fail "priority:P1 IS matched (will be STRIPPED on close)" \
       "Regression: priority:* is metadata, must NOT be in TRANSIENT_REGEX"
else
  pass "priority:P1 NOT matched (PRESERVED on close — priority label kept)"
fi
if matches_transient "status:done"; then
  fail "status:done IS matched (will be STRIPPED on close — RECONTRADICTS STATUS_ADVANCE_REGEX behavior)" \
       "Regression: status:done is set BY this workflow, must not be matched by TRANSIENT_REGEX"
else
  pass "status:done NOT matched (PRESERVED on close — status label kept)"
fi
if matches_transient "verdict-by:2026-07-09T10:00:00Z"; then
  fail "verdict-by:* IS matched (will be STRIPPED on close)" \
       "Regression: verdict-by:* is audit metadata, must NOT be in TRANSIENT_REGEX"
else
  pass "verdict-by:* NOT matched (PRESERVED on close — verdict attribution kept)"
fi

# ================================================================
# SUMMARY
# ================================================================
section "SUMMARY"
printf "  ${B}PASS${D}: ${G}%d${D}\n" "$PASS"
printf "  ${B}FAIL${D}: ${R}%d${D}\n" "$FAIL"

if [ "$FAIL" -eq 0 ]; then
  printf "\n${G}${B}✅ ALL TESTS PASS${D} — TD-067 TRANSIENT_REGEX fix is correct.\n"
  exit 0
else
  printf "\n${R}${B}❌ %d TEST(S) FAIL${D} — TD-067 TRANSIENT_REGEX fix is incomplete or has regression.\n" "$FAIL"
  exit 1
fi