#!/usr/bin/env bash
# d-test-reconcile-live.sh — pattern:NETWORK_DEP mock-first + RECONCILE_LIVE_TOKEN toggle
#
# Why this helper exists
# ----------------------
# Per Issue #1200 (S33-009, ADR-0073 §10 action item row 5), env-dep d-tests
# must default to mock-first execution without requiring real API tokens,
# with an explicit RECONCILE_LIVE_TOKEN env override for live API reconciliation.
# Sister-pattern to d058 TC1 env-rot classification (cycle ~#3853) — tests
# should NOT silently depend on real network state.
#
# Resolution precedence (ADR-0049 env-var-driven override discipline):
#   1. RECONCILE_LIVE_TOKEN=1 → "live" mode (real API call, with 429 retry)
#   2. RECONCILE_LIVE_TOKEN unset/empty → "mock" mode (canned payload, default)
#   3. RECONCILE_LIVE_TOKEN=<other> → "mock" mode (only "1" enables live)
#
# silent_skip log emission per ADR-0056:
#   When mock mode is active, a silent_skip line is emitted to the d099 log
#   to make the mock usage observable in observability logs (no silent fallback).
#
# Sister-pattern lineage (d-test framework, ADR-0049):
#   - d058 TC11 (CLAIM_NEXT_READY_LOCK_FILE env-var-driven override)
#   - d069 (WORKFLOW_FILES env-var-driven parameterization)
#   - d098 (--target-os flag + TARGET_OS env-var override — DIRECT sister)
#   - cycle ~#3642B REST fallback (gh api .../comments for GraphQL exhaustion)
#   - ADR-0056 silent_skip log emission (mock observability doctrine)
#
# Usage:
#   bash scripts/d-test-reconcile-live.sh                # outputs "mock" (default)
#   RECONCILE_LIVE_TOKEN=1 bash scripts/d-test-reconcile-live.sh   # outputs "live"
#   bash scripts/d-test-reconcile-live.sh --check        # checks + emits silent_skip log
#
# Exit codes:
#   0 — mode resolved (printed: "mock" or "live")
#   2 — invalid RECONCILE_LIVE_TOKEN value (anything other than unset/empty/"1")
#
# Output (single line):
#   mock | live
#
# Part of Sprint 33 P2 cluster (Issue #1199 + Issue #1200) per owner directive
# 2026-07-21T09:55Z reframing Sprint 34 P2 → Sprint 33 P2 cluster scope.

set -uo pipefail

# Parse args (sister-pattern to d098 helper)
CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --check)
      CHECK_ONLY=1
      ;;
    --help|-h)
      printf 'Usage: %s [--check] [RECONCILE_LIVE_TOKEN=1]\n' "$0" >&2
      printf 'Resolves mode: "mock" (default) or "live" (when RECONCILE_LIVE_TOKEN=1).\n' >&2
      printf 'With --check, emits silent_skip log per ADR-0056 when mock active.\n' >&2
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

# Resolution (mock-first default, explicit live opt-in per AC2a TC1+TC2)
case "${RECONCILE_LIVE_TOKEN:-}" in
  1)
    MODE="live"
    ;;
  ""|0)
    MODE="mock"
    ;;
  *)
    printf 'invalid RECONCILE_LIVE_TOKEN value: %s (must be unset, empty, 0, or 1)\n' "$RECONCILE_LIVE_TOKEN" >&2
    exit 2
    ;;
esac

# silent_skip log emission per ADR-0056 (only when --check AND mock mode)
if [ "$CHECK_ONLY" = "1" ] && [ "$MODE" = "mock" ]; then
  LOG_DIR="${D_TEST_LOG_DIR:-/var/log/dev-studio/AtilCalculator}"
  if [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR" 2>/dev/null; then
    printf '%s silent_skip mode=mock helper=scripts/d-test-reconcile-live.sh test_pid=%d\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$$" >> "$LOG_DIR/d099.silent_skip.log" 2>/dev/null || true
  fi
fi

printf '%s\n' "$MODE"
exit 0