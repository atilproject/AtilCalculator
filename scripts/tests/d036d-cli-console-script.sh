#!/usr/bin/env bash
# d036d-cli-console-script.sh — hermetic regression test for STORY-316
# (installable `atilcalc` console-script in pyproject.toml).
#
# Why this test exists
# --------------------
# Issue #316 spec: `pip install atilcalc` (or `pip install -e .[dev]` in dev)
# must create an `atilcalc` console-script entry on PATH so users can run
# `atilcalc 0.1 + 0.2` instead of `python -m atilcalc 0.1 + 0.2`.
#
# The contract has two halves:
#   (a) pyproject.toml declarative half — `[project.scripts]` section with
#       `atilcalc = "atilcalc.cli:main"` entry. This is the source of truth.
#   (b) Install verification half — after `pip install -e .[dev]`, `which atilcalc`
#       returns a path. Sister pytest test in tests/cli/test_console_script.py
#       (skipped when not installed — same portable pattern as d036a/b/c).
#
# This d-test covers half (a) hermetically (no install required) so the
# TDD red is observable on a fresh checkout BEFORE `pip install` has been run.
#
# Sister test: tests/cli/test_console_script.py (pytest, install-dependent).
#
# Test cases (6 TCs, Issue #382 / PR #381 obs #381.2 framing + Issue #890 extension):
#   TC1: pyproject.toml has [project.scripts] section (declarative half preflight)
#   TC2: [project.scripts] has `atilcalc = "atilcalc.cli:main"` entry
#   TC3: [project.scripts] atilcalc entry's module path resolves (src/atilcalc/cli/__init__.py
#       has `def main(` callable)
#   TC4: pyproject.toml [project] section has `name = "atilcalc"` (PEP 621 package metadata)
#   TC5: pyproject.toml [build-system] section present (PEP 517 build backend declaration)
#   TC6: src/atilcalc/cli/__init__.py has `if __name__ == "__main__":` entry-point block
#       (sister-pattern to console-script entry; allows `python -m atilcalc.cli` fallback)
#
# Framing: 6 TCs (≥5 ADR-0049 baseline). TC1-TC3 cover console-script contract;
# TC4-TC6 cover PEP 621 + entry-point sister invariants.
# Issue #382 obs #381.2 disambiguation. Issue #890 dev-lane d-test expansion
# (cluster 9 dev-lane below-baseline d-tests per Issue #883 v5 audit).
#
# Exit code: 0 = all pass, 1 = at least one fail.
#
# Run standalone: bash scripts/tests/d036d-cli-console-script.sh
#
# TDD status (this PR): RED on master — TC2/TC3 fail because [project.scripts]
# is not present. Turns GREEN once dev adds the [project.scripts] entry.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PYPROJECT="$REPO_ROOT/pyproject.toml"
CLI_MODULE="$REPO_ROOT/src/atilcalc/cli/__init__.py"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi

PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- TC1: preflight — pyproject.toml exists + [project.scripts] section ---
section "TC1: pyproject.toml exists + has [project.scripts] section"
if [[ ! -f "$PYPROJECT" ]]; then
  fail "TC1: pyproject.toml not found at $PYPROJECT" "TDD-red: pyproject.toml must exist"
  printf "\n${B}==== SUMMARY ====${D}\n  ${G}PASS${D}: %d\n  ${R}FAIL${D}: %d\n" "$PASS" "$FAIL"
  exit 1
fi
if grep -qE '^\[project\.scripts\]' "$PYPROJECT"; then
  pass "TC1: pyproject.toml exists + [project.scripts] section present"
else
  fail "TC1: [project.scripts] section MISSING" "expected: [project.scripts] section header in pyproject.toml. Issue #316 §How sub-task 1."
fi

# --- TC2: [project.scripts] has atilcalc = "atilcalc.cli:main" entry ---
section "TC2: [project.scripts] has atilcalc = \"atilcalc.cli:main\" entry"
# Match the assignment line, tolerating whitespace + quoting variants.
if grep -EqE '^[[:space:]]*atilcalc[[:space:]]*=[[:space:]]*["'"'"']atilcalc\.cli:main["'"'"']' "$PYPROJECT"; then
  pass "TC2: atilcalc = \"atilcalc.cli:main\" entry present"
else
  fail "TC2: atilcalc = \"atilcalc.cli:main\" entry MISSING" "expected: atilcalc = \"atilcalc.cli:main\" under [project.scripts]. Issue #316 §How sub-task 1."
fi

# --- TC3: atilcalc.cli:main resolves to a real callable ---
section "TC3: atilcalc.cli module exposes a main() callable"
if [[ ! -f "$CLI_MODULE" ]]; then
  fail "TC3: src/atilcalc/cli/__init__.py not found at $CLI_MODULE" "Issue #316 AC depends on the CLI module + main() callable from PR #306 (STORY-CLI-001)"
else
  if grep -EqE '^def main\(' "$CLI_MODULE"; then
    pass "TC3: src/atilcalc/cli/__init__.py defines def main("
  else
    fail "TC3: src/atilcalc/cli/__init__.py does NOT define def main(" "Issue #316 AC: console-script entry must point to atilcalc.cli:main — module must expose it"
  fi
fi

# --- TC4: [project] section has name = "atilcalc" (PEP 621 package metadata) ---
section "TC4: pyproject.toml [project] section has name = \"atilcalc\""
# PEP 621: [project] table holds package metadata. The `name` field is required.
# Match the assignment line, tolerating whitespace + quoting variants.
if grep -EqE '^[[:space:]]*name[[:space:]]*=[[:space:]]*["'"'"']atilcalc["'"'"']' "$PYPROJECT"; then
  pass "TC4: pyproject.toml [project] has name = \"atilcalc\" (PEP 621 package metadata)"
else
  fail "TC4: pyproject.toml [project] name = \"atilcalc\" MISSING" "expected: name = \"atilcalc\" under [project] section per PEP 621. Issue #316 §How sub-task 2 + Issue #890 dev-lane d-test expansion (TC4 sister invariant)."
fi

# --- TC5: pyproject.toml has [build-system] section (PEP 517 build backend) ---
section "TC5: pyproject.toml has [build-system] section"
# PEP 517: [build-system] table declares the build backend (e.g., hatchling, setuptools, poetry).
# Required for pip to know how to build the package from source.
if grep -qE '^\[build-system\]' "$PYPROJECT"; then
  pass "TC5: pyproject.toml has [build-system] section (PEP 517 build backend declaration)"
else
  fail "TC5: pyproject.toml [build-system] section MISSING" "expected: [build-system] section header in pyproject.toml with build-backend (e.g., requires = [\"hatchling\"]). Issue #890 dev-lane d-test expansion (TC5 sister invariant)."
fi

# --- TC6: src/atilcalc/cli/__init__.py has __name__ == "__main__" block ---
section "TC6: atilcalc.cli module has __name__ == \"__main__\" entry-point block"
# Sister-pattern: console-script entry allows `atilcalc` cmd; __name__ block
# allows `python -m atilcalc.cli` fallback. Both must work for ISSUE #316 AC.
if [[ ! -f "$CLI_MODULE" ]]; then
  fail "TC6: src/atilcalc/cli/__init__.py not found at $CLI_MODULE" "TC6 prerequisite: CLI module must exist (TC3 dep)"
else
  if grep -EqE '^if __name__[[:space:]]*==[[:space:]]*["'"'"']__main__["'"'"']:' "$CLI_MODULE"; then
    pass "TC6: src/atilcalc/cli/__init__.py has if __name__ == \"__main__\": block (python -m atilcalc.cli fallback)"
  else
    fail "TC6: src/atilcalc/cli/__init__.py missing __main__ guard" "expected: 'if __name__ == \"__main__\":' block calling main() in src/atilcalc/cli/__init__.py. Issue #890 dev-lane d-test expansion (TC6 sister invariant)."
  fi
fi

printf "\n${B}==== SUMMARY ====${D}\n  ${G}PASS${D}: %d\n  ${R}FAIL${D}: %d\n" "$PASS" "$FAIL"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
