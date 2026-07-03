#!/usr/bin/env bash
# d122-uvicorn-in-subprocess-venv.sh — regression guard for Issue #771
# (scripts/run-server.sh:33 — `uv run python` creates uvicorn-less venv;
# blocks PR #770 owner-merge gate + CI Lint & Test on any tests/web/ branch).
#
# Bug class defended against (Issue #771 root cause):
#   - scripts/run-server.sh:33 uses bare `uv run python` which creates a fresh
#     venv at .venv on every invocation, installs ONLY the project + declared
#     runtime deps (atilcalc + mpmath = 2 packages per failure log), and
#     OMITS the [web] optional-dependencies group that contains
#     fastapi==0.115.6 + uvicorn[standard]==0.32.1 (pinned per ADR-0017).
#   - Result: any caller invoking scripts/run-server.sh gets
#     `No module named uvicorn` when the subprocess tries
#     `python -m uvicorn atilcalc.api.main:app`.
#   - Verified cross-branch (Issue #771 RCA): main HEAD 8d9540b, RCA-17
#     branch, pm/sprint-24-backlog-refresh all exhibit the bug.
#
# Fix (Option A, tester-approved per Issue #771):
#   - scripts/run-runner.sh:33 changes from `uv run python` →
#     `uv run --extra web python` (1-line change, closes gap at source)
#   - Sister precedent: d018-rca-14-uvicorn-orphan-kill.sh (uvicorn lifecycle
#     discipline, RCA-14) — d122 closes the OTHER uvicorn lifecycle gap
#     (lifecycle hygiene + [web]-extra-injection)
#
# Test cases (TC1..TC5) — verify Option A fix is in place:
#   TC1: scripts/run-server.sh contains canonical `uv run --extra web python`
#        literal (file-grep deterministic, the actual fix marker)
#   TC2: `uv run --extra web python -c "import uvicorn; print(uvicorn.__version__)"`
#        exits 0 and prints ≥0.32.1 (pre-condition: [web] extra resolves uvicorn)
#   TC3: scripts/run-server.sh does NOT contain bare `uv run python` (regression
#        guard — the buggy pattern is REPLACED, not just supplemented)
#   TC4: `uv --version` reports ≥ 0.4 (pre-condition: --extra flag requires
#        uv 0.4+; uv 0.11.26 on this runner confirms it)
#   TC5: sister-pattern coverage — d018 (uvicorn orphan kill) + d121 (env-var
#        pattern) + d109 (env-var block) all exist on main, ≥3 sister-pattern
#        baseline per ADR-0049 met (env-var family + uvicorn-lifecycle family)
#
# Exit code: 0 = all PASS (GREEN), 1 = at least one FAIL (RED), 2 = preflight
# failure (uv not installed, scripts/run-server.sh missing, etc.)
#
# Run standalone: bash scripts/tests/d122-uvicorn-in-subprocess-venv.sh
# Pre-impl RED state on origin/main 8d9540b (Issue #771 OPEN):
#   - TC1 FAIL: scripts/run-server.sh contains bare `uv run python` (not `uv run --extra web python`)
#   - TC3 FAIL: scripts/run-server.sh contains buggy `uv run python` literal
#   - TC2 PASS-by-design: `uv run --extra web python -c "import uvicorn"` works if [web] extra resolves
#   - TC4 PASS-by-design: uv 0.4+ check passes on any modern runner
#   - TC5 PASS-by-design: sister d018/d121/d109 already on main
#   → 2/5 FAIL in RED state per ADR-0044 RED-first discipline.
#
# Post-impl GREEN state (after Option A fix lands):
#   - TC1 PASS: canonical `uv run --extra web python` literal in scripts/run-server.sh:33
#   - TC3 PASS: bare `uv run python` literal absent (replaced)
#   - TC2 PASS: uvicorn importable via [web] extra
#   - TC4 PASS: uv version check still passes
#   - TC5 PASS: sister-pattern coverage maintained
#   → 5/5 PASS in GREEN state per ADR-0044 GREEN contract.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SERVER_SH="$SCRIPT_DIR/../run-server.sh"
PYPROJECT_TOML="$SCRIPT_DIR/../../pyproject.toml"

# Colors (TTY-aware)
if [[ -t 1 ]]; then G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else G=""; R=""; B=""; D=""; fi

PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# Preflight
# ============================================================================
if [ ! -r "$RUN_SERVER_SH" ]; then
  echo "ERROR: scripts/run-server.sh not found at $RUN_SERVER_SH" >&2
  exit 2
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "ERROR: uv not on PATH (required for TC2 + TC4). Install uv first." >&2
  exit 2
fi

if [ ! -r "$PYPROJECT_TOML" ]; then
  echo "ERROR: pyproject.toml not found at $PYPROJECT_TOML" >&2
  exit 2
fi

# ============================================================================
# Test cases TC1..TC5
# ============================================================================

section "TC1: scripts/run-server.sh contains canonical 'uv run --extra web python' literal (Issue #771 Option A fix marker)"
if grep -Eq '^\s*PYTHON=\(uv run --extra web python\)' "$RUN_SERVER_SH"; then
  pass "scripts/run-server.sh contains canonical 'uv run --extra web python' PYTHON= assignment"
else
  fail "scripts/run-server.sh missing canonical 'uv run --extra web python' PYTHON= assignment" \
       "Issue #771 Option A fix: change line 33 from 'uv run python' to 'uv run --extra web python'"
fi

section "TC2: 'uv run --extra web python -c \"import uvicorn\"' resolves uvicorn ≥0.32.1 (pre-condition: [web] extra injects uvicorn)"
UVICORN_VERSION_OUTPUT="$(uv run --extra web python -c 'import uvicorn; print(uvicorn.__version__)' 2>&1 || true)"
if [[ "$UVICORN_VERSION_OUTPUT" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  # semver compare: require ≥0.32.1
  MAJOR="${UVICORN_VERSION_OUTPUT%%.*}"
  REST="${UVICORN_VERSION_OUTPUT#*.}"
  MINOR="${REST%%.*}"
  PATCH="${REST#*.}"
  if [[ "$MAJOR" -gt 0 ]] || \
     [[ "$MAJOR" -eq 0 && "$MINOR" -gt 32 ]] || \
     [[ "$MAJOR" -eq 0 && "$MINOR" -eq 32 && "$PATCH" -ge 1 ]]; then
    pass "uv run --extra web python resolves uvicorn ${UVICORN_VERSION_OUTPUT} (≥0.32.1 per ADR-0017)"
  else
    fail "uv run --extra web python resolves uvicorn ${UVICORN_VERSION_OUTPUT} but <0.32.1" \
         "ADR-0017 pins uvicorn[standard]==0.32.1; pyproject.toml [web] extra must be updated"
  fi
else
  fail "uv run --extra web python could not import uvicorn" \
       "stderr: ${UVICORN_VERSION_OUTPUT}"
fi

section "TC3: scripts/run-server.sh does NOT contain bare 'uv run python' (regression guard — buggy pattern REPLACED)"
if grep -Eq '^\s*PYTHON=\(uv run python\)' "$RUN_SERVER_SH"; then
  fail "scripts/run-server.sh still contains buggy bare 'uv run python' literal" \
       "Issue #771: replace 'uv run python' with 'uv run --extra web python' on line 33"
else
  pass "scripts/run-server.sh bare 'uv run python' absent (Option A fix applied)"
fi

section "TC4: uv --version ≥ 0.4 (pre-condition: --extra flag requires uv 0.4+)"
UV_VERSION="$(uv --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
if [[ -z "$UV_VERSION" ]]; then
  fail "uv --version returned no parseable version" "got: $(uv --version 2>&1)"
else
  MAJOR="${UV_VERSION%%.*}"
  REST="${UV_VERSION#*.}"
  MINOR="${REST%%.*}"
  if [[ "$MAJOR" -gt 0 ]] || [[ "$MAJOR" -eq 0 && "$MINOR" -ge 4 ]]; then
    pass "uv ${UV_VERSION} detected (≥ 0.4 required for --extra flag)"
  else
    fail "uv ${UV_VERSION} < 0.4 — --extra flag unavailable" \
         "Upgrade uv: 'pip install --upgrade uv' or use uv self-update"
  fi
fi

section "TC5: sister-pattern coverage — d018 (uvicorn orphan kill) + d121 (env-var pattern) + d109 (env-var block) all on main (≥3 baseline per ADR-0049)"
SISTER_COUNT=0
SISTER_DETAIL=""
for d in d018-rca-14-uvicorn-orphan-kill.sh d121-cross-user-env-var-pattern.sh d109-ci-budget-multiplier-env-block.sh; do
  if [ -r "$SCRIPT_DIR/$d" ]; then
    SISTER_COUNT=$((SISTER_COUNT + 1))
    SISTER_DETAIL="${SISTER_DETAIL}${d}✓ "
  else
    SISTER_DETAIL="${SISTER_DETAIL}${d}✗ "
  fi
done
if [[ "$SISTER_COUNT" -ge 3 ]]; then
  pass "sister-pattern coverage ${SISTER_COUNT}/3 met (${SISTER_DETAIL})"
else
  fail "sister-pattern coverage ${SISTER_COUNT}/3 < ADR-0049 ≥3 baseline" \
       "missing: ${SISTER_DETAIL}"
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "  PASS: ${G}%d${D}\n" "$PASS"
printf "  FAIL: ${R}%d${D}\n" "$FAIL"

if [[ "$FAIL" -gt 0 ]]; then
  printf "\n${R}RED state: %d TC(s) FAILING — Issue #771 Option A fix not yet applied to scripts/run-server.sh${D}\n" "$FAIL"
  exit 1
fi

printf "\n${G}GREEN state: all 5 TCs PASS — Issue #771 Option A fix landed, [web] extra injected into run-server.sh venv${D}\n"
exit 0