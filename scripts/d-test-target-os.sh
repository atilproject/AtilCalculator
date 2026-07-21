#!/usr/bin/env bash
# d-test-target-os.sh — pattern:CI_OS_DEP multi-OS target override helper
#
# Why this helper exists
# ----------------------
# Per Issue #1199 (S33-008, ADR-0073 §10 action item row 4), env-dep d-tests
# must pass on both ubuntu-latest AND macos-latest runners without false-positive
# env-rot failures (cycle ~#3853 d058 TC1 env-rot classification).
#
# This helper provides:
#   - Default OS auto-detection via `uname -s` (linux → Linux, darwin → macOS)
#   - Explicit --target-os=<linux|darwin> override (sister-flag pattern)
#   - Honor pre-set TARGET_OS env var when no flag given (env-var override)
#   - Precedence: --target-os flag > TARGET_OS env > `uname -s` auto-detect
#   - Validation: unknown target OS → exit 2 with explicit error
#
# Sister-pattern lineage (d-test framework, ADR-0049):
#   - d058 TC11 (CLAIM_NEXT_READY_LOCK_FILE env-var-driven override)
#   - d069 (WORKFLOW_FILES env-var-driven parameterization)
#   - d109 (ci.yml BUDGET_MULTIPLIER env-block)
#   - d115 (ci.yml SUBPROCESS_TIMEOUT_S env-block)
#
# Usage:
#   bash scripts/d-test-target-os.sh                       # auto-detect via uname
#   bash scripts/d-test-target-os.sh --target-os=linux     # override to linux class
#   bash scripts/d-test-target-os.sh --target-os=darwin    # override to darwin class
#   TARGET_OS=linux bash scripts/d-test-target-os.sh       # env-var override
#
# Exit codes:
#   0 — TARGET_OS resolved (printed as "linux" or "darwin")
#   2 — invalid --target-os value or invalid runtime state
#
# Output (single line):
#   <resolved-target-os>
#
# Part of Sprint 33 P2 cluster (Issue #1199 + Issue #1200) per owner directive
# 2026-07-21T09:55Z reframing Sprint 34 P2 → Sprint 33 P2 cluster.

set -uo pipefail

# Defaults
TARGET_OS="${TARGET_OS:-}"
TARGET_OS_FLAG=""
FLAG_ERROR=""

# Parse args (sister-pattern to d115 SUBPROCESS_TIMEOUT_S env-block parsing)
for arg in "$@"; do
  case "$arg" in
    --target-os=*)
      TARGET_OS_FLAG="${arg#--target-os=}"
      ;;
    --target-os=*)
      TARGET_OS_FLAG="${arg#--target-os=}"
      ;;
    --help|-h)
      printf 'Usage: %s [--target-os=<linux|darwin>] [TARGET_OS=<val>]\n' "$0" >&2
      printf 'Resolves and prints the target OS class for env-dep d-test gating.\n' >&2
      exit 0
      ;;
    *)
      FLAG_ERROR="unknown argument: $arg"
      ;;
  esac
done

if [ -n "$FLAG_ERROR" ]; then
  printf '%s\n' "$FLAG_ERROR" >&2
  exit 2
fi

# Resolution precedence (ADR-0049 env-var-driven override discipline):
#   1. --target-os flag (explicit caller intent)
#   2. TARGET_OS env var (CI runner-set override)
#   3. `uname -s` auto-detection (default)

if [ -n "$TARGET_OS_FLAG" ]; then
  RESOLVED="$TARGET_OS_FLAG"
elif [ -n "$TARGET_OS" ]; then
  RESOLVED="$TARGET_OS"
else
  UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
  case "$UNAME_S" in
    Linux|linux)
      RESOLVED="linux"
      ;;
    Darwin|darwin)
      RESOLVED="darwin"
      ;;
    *)
      printf 'uname -s returned unsupported value: %s\n' "$UNAME_S" >&2
      exit 2
      ;;
  esac
fi

# Validate resolved value (defense against typo / wrong-class injection)
case "$RESOLVED" in
  linux|darwin)
    printf '%s\n' "$RESOLVED"
    exit 0
    ;;
  *)
    printf 'invalid target OS class: %s (must be linux or darwin)\n' "$RESOLVED" >&2
    exit 2
    ;;
esac
