#!/usr/bin/env bash
# d1191-conventional-commits-agent-prefix.sh — Conventional Commits linter agent-prefix
# whitelist regression test (≥5 TCs per ADR-0049 + Cadence Rule 1 atomic per ADR-0055 §1).
#
# Why this test exists
# --------------------
# Issue #1191 — Sprint 33 P1 follow-up (carry-over #8 of Issue #1171).
# PR #1188 (tester soul amend) hit Conventional Commits CI FAILURE at 16:41:00Z with
# error: `Unknown release type "tester" found in pull request title`. Soul amend PRs
# conventionally use `<role>(<area>):` format (e.g. `tester(soul): ...`) but the
# `amannn/action-semantic-pull-request@v5` linter only whitelisted standard types
# (feat|fix|chore|docs|...). This d-test codifies the resolution: agent-prefixed
# types MUST be in the `types:` block on `.github/workflows/ci.yml`.
#
# Owner-ratified scope per ADR-0055 §1 Cadence Rule 2 dispatch (orchestrator peer-poke
# 2026-07-20T20:31:37+03:00): whitelist agent-prefixed types OR `<role>(<area>): ` regex
# pattern. Implementation chose Option A (whitelist) for explicitness and forward-compat.
#
# 5 TCs (per ADR-0049 ≥5 TCs invariant + Cadence Rule 1 atomic per ADR-0055 §1):
#   TC1: All 5 agent role names present in `.github/workflows/ci.yml` `types:` block
#        (architect, orchestrator, product-manager, developer, tester)
#   TC2: `.github/workflows/ci.yml` `conventional-commits` job still pins action to
#        `amannn/action-semantic-pull-request` (no surprise upgrades)
#   TC3: Each agent name appears in the `types:` block (not in `subject-pattern` or
#        other action config fields) — checked via section header proximity
#   TC4: `types:` block preserves the existing 10 standard types (feat|fix|chore|docs|
#        refactor|test|ci|perf|build|revert) — additive change, no regressions
#   TC5: Sample agent-prefixed PR title parses cleanly through simulated linter regex
#        (mock check: `<agent>(<scope>): <desc>` should match `<agent>` as type)
#
# Sister-pattern to:
#   - d165-s32-027-d-hybrid.sh (PR #195 / 10 HYBRID amendments regression test)
#   - ADR-0049 (d-test ≥5 TCs baseline)
#   - ADR-0055 §1 (Cadence Rule 1 atomic — single commit per docs/decisions/INDEX.md row + impl + d-test)
#   - Issue #1191 (Sprint 33 P1 carry-over #8)
#   - Cycle ~#3958Q+323 PR #1179 verdict pattern (content-correct + CI infra gap = render verdict with caveat)
#   - ADR-0057 (amendment-via-parent pattern — agent prefix whitelist is a CI workflow amendment)
#
# Run: bash scripts/tests/d1191-conventional-commits-agent-prefix.sh
# Exit code: 0 = all pass, 1 = at least one fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CI_YML="$REPO_ROOT/.github/workflows/ci.yml"
INDEX_MD="$REPO_ROOT/scripts/tests/INDEX.md"

# --- test framework ---
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

PASS=0; FAIL=0
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- pre-flight ---
if [ ! -r "$CI_YML" ]; then
  echo "ERROR: ci.yml not found at $CI_YML" >&2
  exit 127
fi

# Agent roles per file ownership matrix (CLAUDE.md Team section)
AGENTS=(architect orchestrator product-manager developer tester)

# ============================================================================
section "TC1: All 5 agent role names present in ci.yml 'types:' block"
TC1_FAIL=0
for agent in "${AGENTS[@]}"; do
  # Look for '<agent>' on its own line within the 'types:' block. The block is
  # bounded by 'types: |' and the next non-indented line, but for simplicity
  # we check that '<agent>' appears at least once inside the types section.
  if grep -qE "^[[:space:]]+${agent}\$" "$CI_YML"; then
    pass "agent role '${agent}' present in ci.yml types block"
  else
    fail "TC1 ${agent}" "agent role '${agent}' NOT in ci.yml types block — Issue #1191 AC1 NOT met"
    TC1_FAIL=1
  fi
done
if [ "$TC1_FAIL" -eq 0 ]; then
  pass "All 5 agent role names (architect, orchestrator, product-manager, developer, tester) present in types: block"
fi

# ============================================================================
section "TC2: ci.yml 'conventional-commits' job still pins amannn/action-semantic-pull-request"
# Anti-pattern: surprise upgrades to v6 may break the types-block format.
# TC2 ensures the action pin is preserved (Issue #1191 amendment must NOT migrate
# the action version).
TC2_FAIL=0
if grep -qE "amannn/action-semantic-pull-request@[a-f0-9]{40}" "$CI_YML"; then
  PIN=$(grep -oE "amannn/action-semantic-pull-request@[a-f0-9]{40}" "$CI_YML" | head -1)
  pass "ci.yml still pins amannn/action-semantic-pull-request (${PIN}) — no surprise upgrade"
else
  fail "TC2" "amannn/action-semantic-pull-request pin not found or not pinned to SHA — Issue #1191 must NOT migrate action version"
  TC2_FAIL=1
fi

# ============================================================================
section "TC3: Each agent name appears in 'types:' block (not subject-pattern or other fields)"
# The 'types:' block in YAML starts with `types: |` and lists one type per line.
# We extract the types block contents and verify each agent appears there.
TC3_FAIL=0
# Extract the types block: lines from 'types: |' to the next line with same or lower indentation.
TYPES_BLOCK=$(awk '
  /types:[[:space:]]+\|/ { in_block=1; next }
  in_block && /^[[:space:]]{12,}[a-zA-Z]/ { print; next }
  in_block && !/^[[:space:]]/ { in_block=0 }
' "$CI_YML")
if [ -z "$TYPES_BLOCK" ]; then
  fail "TC3" "could not extract 'types:' block from ci.yml — file structure unexpected"
  TC3_FAIL=1
else
  for agent in "${AGENTS[@]}"; do
    if echo "$TYPES_BLOCK" | grep -qE "^[[:space:]]*${agent}\$"; then
      pass "agent '${agent}' found inside the 'types:' block (not elsewhere)"
    else
      fail "TC3 ${agent}" "agent '${agent}' NOT found inside the 'types:' block — could be in wrong section"
      TC3_FAIL=1
    fi
  done
fi
if [ "$TC3_FAIL" -eq 0 ]; then
  pass "All 5 agent names correctly located inside the 'types:' block"
fi

# ============================================================================
section "TC4: Existing 10 standard types preserved (additive change, no regressions)"
# Issue #1191 must be additive only — the original whitelist must still cover
# the standard conventional commit types. This guards against an accidental
# rewrite that drops standard types in favor of agent types.
TC4_FAIL=0
STANDARD_TYPES=(feat fix chore docs refactor test ci perf build revert)
for std_type in "${STANDARD_TYPES[@]}"; do
  if echo "$TYPES_BLOCK" | grep -qE "^[[:space:]]*${std_type}\$"; then
    pass "standard type '${std_type}' preserved"
  else
    fail "TC4 ${std_type}" "standard type '${std_type}' NOT found in types block — regression (must be additive change)"
    TC4_FAIL=1
  fi
done
if [ "$TC4_FAIL" -eq 0 ]; then
  pass "All 10 standard types preserved (additive change, no regressions)"
fi

# ============================================================================
section "TC5: Sample agent-prefixed PR title parses cleanly through simulated linter regex"
# The action-semantic-pull-request v5 linter extracts the type from a PR title like
# `<type>[(scope)]: <description>` and checks if `<type>` is in the allowed types
# list. We simulate this with a bash native regex match (more reliable than sed
# for this case — sed substitution was unreliable due to escaping rules).
TC5_FAIL=0
SAMPLE_TITLE_TEMPLATE='%AGENT%(soul): RETRO-032 SOUL AMEND lesson test — does this match?'

for agent in "${AGENTS[@]}"; do
  sample_title="${SAMPLE_TITLE_TEMPLATE//\%AGENT\%/${agent}}"
  # Bash native regex match: capture agent name at start (with optional (scope))
  if [[ "$sample_title" =~ ^([a-zA-Z][a-zA-Z0-9-]*)\(.*\):[[:space:]]+(.*)$ ]]; then
    extracted_type="${BASH_REMATCH[1]}"
    if [ "$extracted_type" = "$agent" ]; then
      # Verify extracted type is in the types block
      if echo "$TYPES_BLOCK" | grep -qE "^[[:space:]]*${extracted_type}\$"; then
        pass "sample '${agent}(soul): ...' → extracted type '${extracted_type}' → whitelisted ✓"
      else
        fail "TC5 ${agent}" "extracted type '${extracted_type}' NOT in types block — linter would reject"
        TC5_FAIL=1
      fi
    else
      fail "TC5 ${agent}" "extracted type mismatch: got '${extracted_type}', expected '${agent}'"
      TC5_FAIL=1
    fi
  else
    fail "TC5 ${agent}" "could not match title pattern: '${sample_title}'"
    TC5_FAIL=1
  fi
done
if [ "$TC5_FAIL" -eq 0 ]; then
  pass "All 5 agent-prefixed sample PR titles parse cleanly and pass the simulated linter check"
fi

# ============================================================================
printf "\n${B}==== SUMMARY ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "d1191 REGRESSION FAILED — Conventional Commits agent-prefix whitelist not properly applied."
  echo "Fix scope:"
  echo "  - .github/workflows/ci.yml: 'types:' block MUST include all 5 agent role names:"
  echo "      architect"
  echo "      orchestrator"
  echo "      product-manager"
  echo "      developer"
  echo "      tester"
  echo "  - The existing 10 standard types (feat|fix|chore|docs|refactor|test|ci|perf|build|revert) MUST be preserved"
  echo "  - amannn/action-semantic-pull-request pin MUST be unchanged (no version migration)"
  echo "  - All agent names MUST appear inside the 'types: |' block, not elsewhere"
  echo "  - Sample agent-prefixed PR titles (e.g. 'tester(soul): ...') MUST extract '<agent>' as the type and pass the linter"
  exit 1
fi
echo
echo "d1191 REGRESSION PASS — Conventional Commits agent-prefix whitelist correctly applied per Issue #1191 / Sprint 33 P1 carry-over #8."
exit 0
