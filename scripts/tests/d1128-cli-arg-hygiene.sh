#!/usr/bin/env bash
# d1128 — cli-arg-hygiene (Claude Code 2.1.207 --agent flag removal)
#
# Sister-pattern to template `d0984-cli-arg-hygiene` (atilproject/dev-studio-template
# Issue #89 / PR #108, MERGED 2026-07-15T10:43:55Z). AtilCalculator-side sister for
# ADR-0061 (CLI 2.1.207 breaking change --agent flag removal).
#
# RED-first TDD contract (ADR-0044): this d-test asserts the POST-fix state.
#   - RED on origin/main (--agent "${role}" present at line ~149)
#   - GREEN on PR #1132 branch (--agent flag removed by impl)
#   - Stays GREEN after PR #1132 merges to main
#
# Sister-cluster ordering (ADR-0059 cluster-squash):
#   1. This d-test PR (tester, Closes #1128) — RED on main, GREEN on PR #1132
#   2. PR #1132 (developer, Closes #1129) — byte-stable fix
#   3. ADR-0061 PR (architect, design memo) — backref traceability
#
# Owner: scripts/dev-studio-start.sh (heredoc line ~149) — @developer impl lane,
#        scripts/tests/d1128-cli-arg-hygiene.sh — @tester test lane per
#        CLAUDE.md file-ownership matrix.
#
# Usage:
#   bash scripts/tests/d1128-cli-arg-hygiene.sh            # run self-test inline (no args)
#   bash scripts/tests/d1128-cli-arg-hygiene.sh --self-test # explicit self-test mode
#   bash scripts/tests/d1128-cli-arg-hygiene.sh --bash-n     # bash -n syntactic check only

set -uo pipefail

PASS=0
FAIL=0
INFO=0
EXIT_CODE=0

# Color codes (only when stdout is a tty)
if [ -t 1 ]; then
  R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; B='\033[0;34m'; D='\033[0m'
else
  R=''; G=''; Y=''; B=''; D=''
fi

section() { printf "\n${B}==== %s ====${D}\n" "$*"; }
pass()    { printf "  ${G}✓ PASS${D} — %s\n" "$*"; PASS=$((PASS + 1)); }
fail()    { printf "  ${R}✗ FAIL${D} — %s\n    reason: %s\n" "$1" "$2"; FAIL=$((FAIL + 1)); EXIT_CODE=1; }
info()    { printf "  ${Y}ℹ INFO${D} — %s\n" "$*"; INFO=$((INFO + 1)); }

# ============================================================================
# Mode dispatch
# ============================================================================

case "${1:-}" in
  --bash-n)
    bash -n "${BASH_SOURCE[0]}" && echo "d1128 bash -n OK" && exit 0
    echo "d1128 bash -n FAIL" >&2; exit 1
    ;;
  --help|-h)
    sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# *//'
    exit 0
    ;;
esac

# ============================================================================
# TC0: bash -n syntactic self-check (hygiene pre-flight)
# ============================================================================
section "TC0: bash -n syntactic self-check"
if bash -n "${BASH_SOURCE[0]}" 2>/dev/null; then
  pass "bash -n syntactic check passes (script is valid bash)"
else
  fail "bash -n syntactic check" "script has bash syntax errors"
  echo "d1128 RED (preflight failed) — script syntax broken"
  exit 1
fi

# ============================================================================
# Pre-flight: locate target file
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="$REPO_ROOT/scripts/dev-studio-start.sh"

if [ ! -f "$TARGET" ]; then
  fail "preflight" "target file missing: $TARGET"
  echo "d1128 RED (preflight failed)"
  exit 1
fi

# ============================================================================
# TC1: Single-grep for the claude bootstrap invocation line returns exactly 1
# ============================================================================
section "TC1: Single-grep for claude bootstrap invocation returns 1 line (no duplicate flag pattern)"

# Pattern: line starts with `claude ` and contains `--dangerously-skip-permissions`.
# Exclude pure comment lines.
matches="$(grep -nE '^claude --dangerously-skip-permissions' "$TARGET" 2>/dev/null || true)"
non_comment_matches="$(printf '%s\n' "$matches" | grep -vE '^[0-9]+:#' || true)"
non_comment_count="$(printf '%s\n' "$non_comment_matches" | grep -c . || true)"
# Normalize: if non_comment_matches is empty, count = 0
if [ -z "$non_comment_matches" ]; then
  non_comment_count=0
fi

if [ "$non_comment_count" -eq 1 ]; then
  pass "single-grep returns 1 line for claude bootstrap invocation (no duplicate flag pattern)"
else
  fail "TC1 — single-grep returns multiple or zero lines" \
    "expected 1, got $non_comment_count. Lines: $(printf '%s' "$non_comment_matches" | head -3 | tr '\n' '|')"
fi

# ============================================================================
# TC2: That 1 line does NOT contain ` --agent "${role}"` substring
# ============================================================================
section 'TC2: invocation line does NOT contain ` --agent "${role}"` (ADR-0061 / CLI 2.1.207 breaking change)'

INVOCATION_LINE="$(printf '%s\n' "$non_comment_matches" | head -1)"
LINE_NUM="$(printf '%s' "$INVOCATION_LINE" | cut -d: -f1)"

if [ -z "$INVOCATION_LINE" ]; then
  fail "TC2 — no invocation line found" \
    "TC1 must pass before TC2 can run (no candidate line to inspect)"
elif printf '%s' "$INVOCATION_LINE" | grep -qF ' --agent "${role}"'; then
  fail "TC2 — --agent flag still present on invocation line" \
    "line $LINE_NUM contains '--agent \"\${role}\"'. ADR-0061 / CLI 2.1.207 breaking change requires removal. Line: $INVOCATION_LINE"
else
  pass "--agent flag absent (post-fix state confirmed, ADR-0061 enforced)"
fi

# ============================================================================
# TC3: That 1 line DOES contain `--append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md"`
# ============================================================================
section 'TC3: invocation line DOES contain --append-system-prompt-file (agent identity wired correctly)'

if [ -z "$INVOCATION_LINE" ]; then
  fail "TC3 — no invocation line found" "TC1 must pass before TC3 can run"
elif printf '%s' "$INVOCATION_LINE" | grep -qF -- '--append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md"'; then
  pass "--append-system-prompt-file present (agent identity wired correctly via .claude/agents/*.md)"
else
  fail "TC3 — --append-system-prompt-file substring missing" \
    "line $LINE_NUM does not contain expected substring. Line: $INVOCATION_LINE"
fi

# ============================================================================
# TC4: Invocation is on the canonical line (line ~149) — drift tolerance ±2
# ============================================================================
section "TC4: invocation line is at canonical ~149 (byte-stable, drift tolerance ±2)"

# Canonical line is 149 in dev-studio-start.sh per Issue #1128 spec.
# Drift tolerance ±2 to allow sprint-planning header offsets.
EXPECTED_LINE=149
DRIFT_TOLERANCE=2

if [ -z "$LINE_NUM" ]; then
  fail "TC4 — no invocation line found" "TC1 must pass before TC4 can run"
elif [ "$LINE_NUM" -ge $((EXPECTED_LINE - DRIFT_TOLERANCE)) ] && [ "$LINE_NUM" -le $((EXPECTED_LINE + DRIFT_TOLERANCE)) ]; then
  pass "invocation on line $LINE_NUM (canonical ~$EXPECTED_LINE, drift ±${DRIFT_TOLERANCE} tolerated)"
else
  fail "TC4 — invocation on wrong line" \
    "expected line ~$EXPECTED_LINE (±$DRIFT_TOLERANCE), got $LINE_NUM. Check if dev-studio-start.sh was reorganized."
fi

# ============================================================================
# TC5: Sister-pattern byte-stable with template d0984 (cross-repo portability)
# ============================================================================
section "TC5: Sister-pattern byte-stable with template d0984 (cross-repo portability)"

# Canonical post-fix line (byte-stable across template + AtilCalculator per Issue #1128 §AC5):
#   claude --dangerously-skip-permissions --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "\$KICKOFF_PROMPT"
CANONICAL_LINE='claude --dangerously-skip-permissions --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "\$KICKOFF_PROMPT"'

# Strip the line-number prefix from INVOCATION_LINE (format: "149:...")
ACTUAL_LINE="$(printf '%s' "$INVOCATION_LINE" | cut -d: -f2-)"

if [ -z "$ACTUAL_LINE" ]; then
  fail "TC5 — no invocation line found" "TC1 must pass before TC5 can run"
elif [ "$ACTUAL_LINE" = "$CANONICAL_LINE" ]; then
  pass "canonical pattern byte-stable with template d0984 (cross-repo portable)"
else
  fail "TC5 — pattern drift from template d0984 canonical" \
    "expected: $CANONICAL_LINE | got: $ACTUAL_LINE"
fi

# ============================================================================
# TC6: Cadence Rule 1 atomic — INDEX.md row present for d1128 (ADR-0055 §1)
# ============================================================================
section "TC6: scripts/tests/INDEX.md has d1128 row (Cadence Rule 1 atomic, ADR-0055 §1)"

INDEX_FILE="$REPO_ROOT/scripts/tests/INDEX.md"
if [ -f "$INDEX_FILE" ] && grep -qE '\| \*\*d1128\*\*' "$INDEX_FILE"; then
  pass "INDEX.md has d1128 row (Cadence Rule 1 atomic attestation)"
else
  fail "TC6 — INDEX.md missing d1128 row" \
    "d1128 row must be added per ADR-0055 §1 (sister-pattern d1082 TC6 + d1081 INDEX.md row). Cadence Rule 1 atomic — INDEX.md row + this file land in same commit."
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== d1128 SELF-TEST SUMMARY ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"
printf "  ${Y}INFO${D}: %d\n" "$INFO"

if [ "$FAIL" -eq 0 ]; then
  printf "  ${G}d1128 GREEN${D} — cli-arg-hygiene confirmed (post-fix state, ADR-0061 enforced)\n"
  exit 0
else
  printf "  ${Y}d1128 RED${D} — %d TC(s) failing. RED on origin/main expected; GREEN post-PR #1132 merge.\n" "$FAIL"
  exit 1
fi