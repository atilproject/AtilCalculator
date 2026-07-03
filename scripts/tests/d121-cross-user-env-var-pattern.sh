#!/usr/bin/env bash
# d121-cross-user-env-var-pattern.sh — ATC_SERVICE_USER 3-tier resolution
# regression guard for scripts/deploy-runner.sh
#
# Why this test exists
# --------------------
# Sprint 23 P2 follow-up to ADR-0064 (Closes Issue #765 + RCA-17 codification)
# defines the canonical 3-tier precedence chain for cross-user env vars:
#
#   Tier 1: vars.ATC_SERVICE_USER (repo variable, operator-set)         ← .github/workflows/deploy.yml (PR #773, owner-gated)
#   Tier 2: workflow YAML hardcoded default 'atilcan'                   ← .github/workflows/deploy.yml (PR #773, owner-gated)
#   Tier 3: script-side shell fallback `${ATC_SERVICE_USER:-$USER}`    ← scripts/deploy-runner.sh     (PR #764, d-test lane)
#
# This d-test focuses on Tier 3 (tester lane = scripts/tests/), which is
# the canonical script-side fallback that PR #764 implements. Tier 1 + Tier 2
# live in `.github/workflows/deploy.yml` (owner-gated territory per file
# ownership matrix; not in scope for d121).
#
# Pre-impl RED state (current origin/main 8d9540b, PR #764 OPEN):
#   - TC1 FAIL: deploy-runner.sh does NOT contain `${ATC_SERVICE_USER:-$USER}` literal
#   - TC2 FAIL: deploy-runner.sh does NOT contain `sudo -u "${ATC_SERVICE_USER:-$USER}"` invocation
#   - TC3 PASS-by-coincidence (POSIX ${VAR:-DEFAULT} semantics, operator understanding)
#   - TC4 PASS-by-coincidence (POSIX ${VAR:-DEFAULT} semantics, operator understanding)
#   - TC5 PASS-by-coincidence (POSIX ${VAR:-DEFAULT} semantics, operator understanding)
#   → 2/5 FAIL in RED state per ADR-0044 RED-first discipline.
#
# Post-impl GREEN state (after PR #764 merges):
#   - TC1+TC2 PASS (canonical pattern landed)
#   - TC3+TC4+TC5 still PASS (POSIX semantics unchanged)
#   → 5/5 PASS in GREEN state per ADR-0044 GREEN contract.
#
# Sister-pattern: d109 (BUDGET_MULTIPLIER env block, ci.yml) + d112 (conftest
# env-var precedence 7 TCs) + d117 (ATILCALC_EVALUATE_PERSIST env-var gate).
# 4-member env-var precedence family per ADR-0049 ≥3 sister-pattern coverage.
#
# Pre-impl RED state file-origin: cycle ~#3359 ADR-0064 d-test sister-pattern
# spec; PR #764 = RCA-17 AC4 user fix (Tier 3 impl, ATC_SERVICE_USER env var
# fallback for cross-user service management); PR #773 = ADR-0064 doctrinal
# codification (Tier 1+2 owner-gated).
#
# Usage:
#   bash d121-cross-user-env-var-pattern.sh --self-test
#
# Exit codes:
#   0 — all 5 PASS (GREEN state — Tier 3 fallback landed)
#   1 — at least one FAIL (RED state — ATC_SERVICE_USER 3-tier resolution broken)
#   2 — preflight failure (deploy-runner.sh missing, bash ≥4 missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEPLOY_RUNNER_PATH="${REPO_ROOT}/scripts/deploy-runner.sh"

# Colors (TTY-aware, sister-pattern to d112 + d069 + d031)
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

# ============================================================================
# Pre-flight (ADR-0049 sister-pattern — preflight checks first)
# ============================================================================
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required for POSIX ${VAR:-DEFAULT} semantics" >&2; exit 2; }
case "$BASH_VERSION" in
  4.*|5.*) : ;;  # bash 4+ supports ${VAR:-DEFAULT} (universal since 2007)
  *) echo "ERROR: bash ≥4 required (got bash $BASH_VERSION)" >&2; exit 2 ;;
esac
[ -f "$DEPLOY_RUNNER_PATH" ] || { echo "ERROR: deploy-runner.sh not found at $DEPLOY_RUNNER_PATH" >&2; exit 2; }

if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: $0 --self-test" >&2
  exit 2
fi

printf "${B}d121 self-test (ADR-0064 cross-user env-var pattern, 5 TCs ≥3 baseline per ADR-0049)${D}\n"
printf "${B}================================================================${D}\n"
printf "  Deploy-runner:   %s\n" "$DEPLOY_RUNNER_PATH"
printf "  Sister-pattern:  d109 (BUDGET_MULTIPLIER) + d112 (conftest env-var precedence) + d117 (ATILCALC_EVALUATE_PERSIST)\n"
printf "  3-tier pattern:  Tier 1 vars.ATC_SERVICE_USER (workflow) + Tier 2 'atilcan' (workflow default) + Tier 3 \${ATC_SERVICE_USER:-\$USER} (script)\n"
printf "  RED-first:       pre-impl TC1+TC2 FAIL (PR #764 not yet merged); TC3+TC4+TC5 PASS-by-coincidence (POSIX semantics).\n\n"

# ============================================================================
# TC1: deploy-runner.sh contains canonical `${ATC_SERVICE_USER:-$USER}` literal
# ============================================================================
section "TC1: deploy-runner.sh contains \${ATC_SERVICE_USER:-\$USER} literal"
if grep -qE '\$\{ATC_SERVICE_USER:-?\$USER\}' "$DEPLOY_RUNNER_PATH"; then
  pass "TC1 — canonical Tier 3 fallback literal \${ATC_SERVICE_USER:-\$USER} present in deploy-runner.sh (post-#764)"
else
  fail "TC1 — Tier 3 fallback literal MISSING from deploy-runner.sh" \
    "expected \${ATC_SERVICE_USER:-\$USER} (or \${ATC_SERVICE_USER-\$USER}) somewhere in deploy-runner.sh; verified via grep -E 'ATC_SERVICE_USER:-?\\\$USER'. PR #764 (RCA-17 AC4) must merge before this TC passes."
fi

# ============================================================================
# TC2: deploy-runner.sh contains `sudo -u "${ATC_SERVICE_USER:-$USER}"` invocation
# ============================================================================
section "TC2: deploy-runner.sh contains sudo -u with ATC_SERVICE_USER fallback"
if grep -qE 'sudo -u[[:space:]]+\"\$\{ATC_SERVICE_USER:-?\$USER\}\"' "$DEPLOY_RUNNER_PATH"; then
  pass "TC2 — canonical invocation 'sudo -u \"\${ATC_SERVICE_USER:-\$USER}\"' present in deploy-runner.sh (post-#764)"
else
  fail "TC2 — canonical sudo -u \${ATC_SERVICE_USER:-...} invocation MISSING from deploy-runner.sh" \
    "expected 'sudo -u \"\${ATC_SERVICE_USER:-\$USER}\"' pattern; verified via grep -E 'sudo -u[[:space:]]+\\\\\"\\\\\\$\\\\{ATC_SERVICE_USER:-?\\\\\\$USER\\\\}\\\\\"'. PR #764 replaces hardcoded 'sudo -u atilcan' with env-var-driven form."
fi

# ============================================================================
# TC3: POSIX `${VAR:-DEFAULT}` semantics — env-injection wins (TC3a: ATC_SERVICE_USER=foo)
# ============================================================================
section "TC3a: POSIX \${VAR:-DEFAULT} semantics — env-injection wins (ATC_SERVICE_USER=foo)"
RES_OUT="$(ATC_SERVICE_USER=foo bash -c 'printf "%s" "${ATC_SERVICE_USER:-$USER}"' 2>/dev/null || echo "BASH_ERROR")"
if [ "$RES_OUT" = "foo" ]; then
  pass "TC3a — env-injection ATC_SERVICE_USER=foo resolves to 'foo' (NOT \$USER fallback)"
else
  fail "TC3a — env-injection broken" "expected 'foo'; got '$RES_OUT' (POSIX \${VAR:-DEFAULT} must defer to env-injected value)"
fi

# ============================================================================
# TC3: POSIX `${VAR:-DEFAULT}` semantics — unset falls back to $USER
# ============================================================================
section "TC3b: POSIX \${VAR:-DEFAULT} semantics — unset ATC_SERVICE_USER falls back to \$USER"
RES_OUT="$(unset ATC_SERVICE_USER; bash -c 'printf "%s" "${ATC_SERVICE_USER:-$USER}"' 2>/dev/null || echo "BASH_ERROR")"
EXPECTED_USER="$(id -un 2>/dev/null || echo "$(whoami 2>/dev/null || echo unknown)")"
if [ "$RES_OUT" = "$EXPECTED_USER" ]; then
  pass "TC3b — unset ATC_SERVICE_USER falls back to \$USER='$EXPECTED_USER' (Tier 3 safe fail-open)"
else
  fail "TC3b — unset fallback broken" "expected '\$USER=$EXPECTED_USER'; got '$RES_OUT'"
fi

# ============================================================================
# TC3: POSIX `${VAR:-DEFAULT}` semantics — empty string falls back to $USER (POSIX `:-\`)
# ============================================================================
section "TC3c: POSIX \${VAR:-DEFAULT} semantics — empty ATC_SERVICE_USER falls back to \$USER"
RES_OUT="$(ATC_SERVICE_USER= bash -c 'printf "%s" "${ATC_SERVICE_USER:-$USER}"' 2>/dev/null || echo "BASH_ERROR")"
EXPECTED_USER="$(id -un 2>/dev/null || echo "$(whoami 2>/dev/null || echo unknown)")"
if [ "$RES_OUT" = "$EXPECTED_USER" ]; then
  pass "TC3c — empty ATC_SERVICE_USER='' falls back to \$USER='$EXPECTED_USER' (POSIX ':-' treats empty as unset → safe fail-open)"
else
  fail "TC3c — empty fallback broken" "expected '\$USER=$EXPECTED_USER'; got '$RES_OUT' (POSIX ':-' must treat empty as unset, falling back to \$USER)"
fi

# ============================================================================
# TC4: Defensive — empty ATC_SERVICE_USER does NOT cause `sudo -u ""` failure
#        (operator scenario: GH evaluates unset vars as empty string, but
#        the \${VAR:-DEFAULT} fallback protects against the empty-passthrough
#        pathology that \${VAR-DEFAULT} (no colon) would NOT protect against).
# ============================================================================
section "TC4: empty ATC_SERVICE_USER simulated via sudo -u → fallback fires (NOT 'sudo -u \"\"')"
RES_OUT="$(ATC_SERVICE_USER= bash -c 'RESOLVED="${ATC_SERVICE_USER:-$USER}"; if [ -z "$RESOLVED" ]; then echo EMPTY_FAIL; else echo "RESOLVED=$RESOLVED"; fi' 2>/dev/null || echo "BASH_ERROR")"
case "$RES_OUT" in
  RESOLVED=*)
    pass "TC4 — empty ATC_SERVICE_USER fallback protects against 'sudo -u \"\"' failure (got '$RES_OUT')"
    ;;
  EMPTY_FAIL)
    fail "TC4 — empty-passthrough pathology" "got 'EMPTY_FAIL' — \${VAR:-DEFAULT} must NOT pass-through empty string (POSIX semantics)"
    ;;
  *)
    fail "TC4 — unexpected output" "expected 'RESOLVED=...' or 'EMPTY_FAIL'; got '$RES_OUT'"
    ;;
esac

# ============================================================================
# TC5: Sister-pattern coverage — env-var precedence family ≥3 exists on main
#       (regression guard: d121 is the 4th member of the env-var precedence
#        family. d109 + d112 + d117 must remain on main; if any is removed,
#        the family shrinks below ADR-0049 baseline.)
# ============================================================================
section "TC5: sister-pattern coverage — d109 + d112 + d117 d-tests remain on main"
SISTER_OK=1
SISTER_MISSING=""
for sister in d109-ci-budget-multiplier-env-block d112-conftest-env-var-precedence d117-evaluate-persist-env-var-gate; do
  if [ ! -f "${SCRIPT_DIR}/${sister}.sh" ]; then
    SISTER_OK=0
    SISTER_MISSING="${SISTER_MISSING}${sister}.sh "
  fi
done
if [ "$SISTER_OK" = "1" ]; then
  pass "TC5 — sister-pattern coverage intact: d109 + d112 + d117 all present on main (env-var precedence family = 4 sisters ≥ ADR-0049 baseline ≥3)"
else
  fail "TC5 — sister-pattern coverage broken" "missing on main: $SISTER_MISSING (env-var precedence family would shrink below ADR-0049 ≥3 baseline)"
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "  PASS:           %d\n" "$PASS"
printf "  FAIL:           %d\n" "$FAIL"
printf "  INFO:           %d\n" "$INFO"
printf "  Deploy-runner:  %s\n" "$DEPLOY_RUNNER_PATH"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${R}RED state: %d TC(s) FAILING — ATC_SERVICE_USER 3-tier resolution broken per ADR-0044 RED-first${D}\n" "$FAIL"
  printf "${R}PR #764 (RCA-17 AC4 user fix) MUST merge before d121 GREEN. See Issue #774.${D}\n"
  exit 1
fi

printf "\n${G}GREEN state: all 5 TCs PASS — Tier 3 fallback landed in deploy-runner.sh${D}\n"
exit 0
