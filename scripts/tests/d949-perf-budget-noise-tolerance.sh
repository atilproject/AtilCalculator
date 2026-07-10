#!/usr/bin/env bash
# d949-perf-budget-noise-tolerance.sh — TestClient infra noise-tolerance regression guard
# (Issue #949 P3 perf flake, sister-pattern to d112/d113/d115)
#
# Why this test exists
# --------------------
# Issue #949 (perf flake: test_arithmetic_p99_under_50ms_still_holds p99=502.52ms on
# PR #947 run 29034705305 + p99=814.78ms on PR #946 run 29038023427, both over the
# 500ms CI budget with BUDGET_MULTIPLIER=10) revealed that the strict `< budget`
# assertion in the perf test is fighting against TestClient infra overhead (pytest-cov
# 2x + ThreadPoolExecutor overhead), not engine perf regression.
#
# Local measurements (5 readings on same machine, --no-cov):
#   - Engine-only evaluate("0.1 + 0.2") direct call: p99 = 0.37ms (no regression — mpmath
#     not in arithmetic path per Issue #728 sys.modules guard)
#   - TestClient HTTP + pytest infra: p99 = 346-565ms (variance 220ms)
#   - CI: 502-814ms (github-hosted runner variability)
#
# Per PR #836 RCA + d112 sister-pattern (TD-046-extension): the right fix is
# (a) noise tolerance factor in the perf test (catches real engine regressions but
# ignores TestClient infra variance), and (b) bump github-hosted multiplier to match
# self-hosted (6.0 → 16.0 to absorb pytest-cov 2x overhead per Issue #949 §Sister-pattern
# analysis). TD-049 (perf-test isolation in no-cov CI job) is the permanent fix but
# deferred to Sprint 27 per conftest.py commentary.
#
# 5 TCs (≥5 baseline per ADR-0049 d-test framework):
#   TC1: conftest.py exports BUDGET_NOISE_TOLERANCE constant (currently absent → RED)
#   TC2: conftest.py _BUDGET_MULTIPLIER_MAP['github-hosted'] = 16.0 (sister-pattern
#        to self-hosted 6.0 + pytest-cov 2x headroom per PR #836 RCA)
#   TC3: tests/api/test_evaluate_transcendental.py imports BUDGET_NOISE_TOLERANCE
#        from conftest (currently absent → RED)
#   TC4: tests/api/test_evaluate_transcendental.py::test_arithmetic_p99_under_50ms_still_holds
#        uses `effective_budget_ms * BUDGET_NOISE_TOLERANCE` (currently strict < → RED)
#   TC5: scripts/tests/INDEX.md has d949 row (Cadence Rule 1 atomic per ADR-0055)
#
# Sister-pattern: d112 (conftest env-var precedence, Issue #949 §Sister-pattern),
# d100 (Sprint 22 PIVOT env-aware perf budgets), d113 (markdown internal link guard —
# same Issue #949 sister). ≥3 sister-pattern coverage per ADR-0049 §Sister-pattern
# (TC1+TC2+TC4 cover the 3 fix tiers: source export + map value + test application).
#
# Pre-impl RED state (main d02e1e8):
#   - TC1 FAIL: BUDGET_NOISE_TOLERANCE not exported from conftest
#   - TC2 FAIL: github-hosted multiplier is 1.0 (should be 16.0)
#   - TC3 FAIL: test file does not import BUDGET_NOISE_TOLERANCE
#   - TC4 FAIL: test file uses strict `< effective_budget_ms` (no tolerance)
#   - TC5 FAIL: scripts/tests/INDEX.md has no d949 row
#   → 5/5 FAIL in RED state per ADR-0044 RED-first discipline.
#
# Post-impl GREEN state:
#   - All 5 TCs PASS
#   → 5/5 PASS in GREEN state.
#
# Usage:
#   bash d949-perf-budget-noise-tolerance.sh --self-test
#
# Exit codes:
#   0 — all 5 PASS (GREEN state — noise tolerance landed)
#   1 — at least one FAIL (RED state — fix incomplete)
#   2 — preflight failure (python3 missing, conftest.py missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFTEST_PATH="${REPO_ROOT}/tests/conftest.py"
TEST_FILE_PATH="${REPO_ROOT}/tests/api/test_evaluate_transcendental.py"
INDEX_PATH="${REPO_ROOT}/scripts/tests/INDEX.md"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""
fi

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Pre-flight (ADR-0049 sister-pattern — preflight checks first)
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required for conftest resolution" >&2; exit 2; }
[ -f "$CONFTEST_PATH" ] || { echo "ERROR: conftest.py not found at $CONFTEST_PATH" >&2; exit 2; }
[ -f "$TEST_FILE_PATH" ] || { echo "ERROR: test_evaluate_transcendental.py not found at $TEST_FILE_PATH" >&2; exit 2; }
[ -f "$INDEX_PATH" ] || { echo "ERROR: scripts/tests/INDEX.md not found at $INDEX_PATH" >&2; exit 2; }

if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: $0 --self-test" >&2
  exit 2
fi

printf "${B}d949 self-test (Issue #949 P3 perf flake noise-tolerance guard, 5 TCs ≥5 baseline per ADR-0049)${D}\n"
printf "${B}==============================================================================${D}\n"
printf "  Conftest:       %s\n" "$CONFTEST_PATH"
printf "  Test file:      %s\n" "$TEST_FILE_PATH"
printf "  INDEX.md:       %s\n" "$INDEX_PATH"
printf "  Sister-pattern: d112 (conftest env-var precedence), d100 (env-aware perf budgets),\n"
printf "                  d113 (markdown internal link guard), PR #836 (pytest-cov RCA)\n"
printf "  RED-first:      pre-impl TC1-TC5 all FAIL (Issue #949 §Proposed fix);\n"
printf "                  GREEN 5/5 PASS post-fix lands.\n\n"

# ============================================================================
# TC1: conftest.py exports BUDGET_NOISE_TOLERANCE constant
# ============================================================================
section "TC1: conftest.py exports BUDGET_NOISE_TOLERANCE constant"
if grep -qE "^BUDGET_NOISE_TOLERANCE[[:space:]]*[:=]" "$CONFTEST_PATH"; then
  pass "TC1 — conftest.py exports BUDGET_NOISE_TOLERANCE (module-level constant, sourced from test_evaluate_transcendental.py)"
else
  fail "TC1 — BUDGET_NOISE_TOLERANCE not exported from conftest.py" \
    "expected line matching '^BUDGET_NOISE_TOLERANCE[:space:][:space:]*[:=]' in $CONFTEST_PATH"
fi

# ============================================================================
# TC2: _BUDGET_MULTIPLIER_MAP['github-hosted'] = 16.0 (sister to self-hosted 6.0)
# ============================================================================
section "TC2: _BUDGET_MULTIPLIER_MAP['github-hosted'] = 16.0 (pytest-cov 2x + TestClient headroom)"
# Extract value from _BUDGET_MULTIPLIER_MAP dict — grep the line, parse float
GH_VALUE=$(grep -A4 "^_BUDGET_MULTIPLIER_MAP" "$CONFTEST_PATH" | grep '"github-hosted"' | head -1 | sed -E 's/.*"github-hosted":[[:space:]]*([0-9.]+).*/\1/')
if [ "$GH_VALUE" = "16.0" ]; then
  pass "TC2 — github-hosted multiplier is 16.0 (sister-pattern to self-hosted 6.0 + pytest-cov 2x headroom per PR #836 RCA + Issue #949 §Proposed fix)"
else
  fail "TC2 — github-hosted multiplier is not 16.0" \
    "expected 16.0; got '$GH_VALUE'. Sister-pattern to self-hosted 6.0 (line ~123-127); pytest-cov 2x overhead per PR #836 + Issue #949 absorb."
fi

# ============================================================================
# TC3: tests/api/test_evaluate_transcendental.py imports BUDGET_NOISE_TOLERANCE
# ============================================================================
section "TC3: test file imports BUDGET_NOISE_TOLERANCE from conftest"
if grep -qE "from tests.conftest import .*BUDGET_NOISE_TOLERANCE" "$TEST_FILE_PATH"; then
  pass "TC3 — test_evaluate_transcendental.py imports BUDGET_NOISE_TOLERANCE from tests.conftest (sister-pattern d112 TC1 import contract)"
else
  fail "TC3 — BUDGET_NOISE_TOLERANCE not imported in test file" \
    "expected 'from tests.conftest import ..., BUDGET_NOISE_TOLERANCE' in $TEST_FILE_PATH"
fi

# ============================================================================
# TC4: test_arithmetic_p99_under_50ms_still_holds uses noise-tolerance factor
# ============================================================================
section "TC4: test_arithmetic_p99_under_50ms_still_holds applies noise tolerance (not strict <)"
# Extract body of test_arithmetic_p99_under_50ms_still_holds via awk (more robust than grep -A with subshell).
# `next` on the start line prevents the END pattern from matching the START pattern's line
# (e.g. "def test_arithmetic..." starts with "    def [alpha]_" which would terminate the range immediately).
TEST_BODY=$(awk '
  /^    def test_arithmetic_p99_under_50ms_still_holds/ { f=1; next }
  f && /^    def [a-zA-Z_]/ { f=0; exit }
  f
' "$TEST_FILE_PATH")
if echo "$TEST_BODY" | grep -qE "BUDGET_NOISE_TOLERANCE|NOISE_TOLERANCE|effective_budget_ms[[:space:]]*\*[[:space:]]*1\\."; then
  pass "TC4 — arithmetic perf test applies noise tolerance factor (5% sister-pattern to PR #836 RCA + Issue #949 §Proposed fix Option A)"
else
  fail "TC4 — arithmetic perf test uses strict < without noise tolerance" \
    "expected assertion referencing BUDGET_NOISE_TOLERANCE or *1.05-style factor in test_arithmetic_p99_under_50ms_still_holds body"
fi

# ============================================================================
# TC5: scripts/tests/INDEX.md has d949 row (Cadence Rule 1 atomic per ADR-0055)
# ============================================================================
section "TC5: scripts/tests/INDEX.md has d949 row (Cadence Rule 1 atomic)"
if grep -qE "^## d949 " "$INDEX_PATH"; then
  pass "TC5 — scripts/tests/INDEX.md has d949 row header (Cadence Rule 1 atomic per ADR-0055 §1 — d-test file + INDEX.md same commit)"
else
  fail "TC5 — scripts/tests/INDEX.md has no d949 row" \
    "expected '^## d949 ' header in $INDEX_PATH (sister-pattern to d112/d113 Cadence Rule 1 atomic)"
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "  PASS:           %d\n" "$PASS"
printf "  FAIL:           %d\n" "$FAIL"
printf "  INFO:           %d\n" "$INFO"
printf "  Conftest:       %s\n" "$CONFTEST_PATH"
printf "  Test file:      %s\n" "$TEST_FILE_PATH"
printf "  INDEX.md:       %s\n" "$INDEX_PATH"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${R}RED state: %d TC(s) FAILING — Issue #949 noise-tolerance fix incomplete per ADR-0044 RED-first${D}\n" "$FAIL"
  exit 1
fi

printf "\n${G}GREEN state: all 5 TCs PASS — Issue #949 noise-tolerance fix landed${D}\n"
exit 0