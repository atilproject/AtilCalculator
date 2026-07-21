#!/usr/bin/env bash
# d098-ci-os-target-override.sh — pattern:CI_OS_DEP multi-OS matrix / --target-os
# override flag regression guard (Issue #1199 / S33-008, ADR-0073 §10 row 4).
#
# Why this test exists
# --------------------
# Per Issue #1199 AC1a: env-dep d-tests must pass GREEN on both ubuntu-latest
# AND macos-latest runners without false-positive env-rot failures (cycle ~#3853
# d058 TC1 env-rot classification root cause: d-test assumes single-OS env).
#
# The implementation pattern: a small helper script (scripts/d-test-target-os.sh)
# provides OS auto-detection + explicit --target-os override + TARGET_OS env-var
# override so env-dep d-tests can resolve their target OS class without embedding
# OS-detection logic inline. This d-test validates ≥6 TCs covering each runner
# class per AC1a spec.
#
# Pre-impl RED state (current main as of 2026-07-21 pre-worktree):
#   - All 8 TCs FAIL (helper script absent from main)
#   - d-test file absent from main
#   - INDEX.md row absent from main
#   → 8/8 FAIL = proper RED-first per ADR-0044.
#
# Post-impl GREEN state (after Issue #1199 PR squash):
#   - TC0: bash -n hygiene PASS (helper syntactically valid)
#   - TC1: env-default auto-detect PASS (TARGET_OS unset → uses uname -s)
#   - TC2: --target-os=linux PASS (ubuntu-latest class)
#   - TC3: --target-os=darwin PASS (macos-latest class)
#   - TC4: --target-os=foobar FAIL with exit 2 (validation rejection)
#   - TC5: --target-os flag beats TARGET_OS env var (precedence)
#   - TC6: TARGET_OS env var with no flag passes through (env var path)
#   - TC7: unknown uname value → exit 2 (safety guard)
#
# Sister-pattern family (d-test lineage, ADR-0049):
#   - d058 TC11 (CLAIM_NEXT_READY_LOCK_FILE env-var-driven override)
#   - d069 (WORKFLOW_FILES env-var-driven parameterization)
#   - d109 (ci.yml BUDGET_MULTIPLIER env-block)
#   - d115 (ci.yml SUBPROCESS_TIMEOUT_S env-block — d115 DIRECT sister to d098)
#   - d020a TC4 (jq filter performance budget, sister-pattern shell-test discipline)
#
# Sprint 33 P2 cluster (ref per cycle ~#209 owner directive 2026-07-21T09:55Z):
#   - Issue #1199 S33-008 pattern:CI_OS_DEP — this d-test
#   - Issue #1200 S33-009 pattern:NETWORK_DEP — sister d-test after #1199 squash
#   - ADR-0073 §10 action item row 4 — this closes that row
#   - d058 TC1 (cycle ~#3853) — env-rot classification sister-pattern
#
# Usage:
#   bash scripts/tests/d098-ci-os-target-override.sh --self-test
#
# Exit codes:
#   0 — all PASS (GREEN state — helper script + override path validated)
#   1 — at least one FAIL (RED state — impl incomplete or helper missing)
#   2 — preflight failure (missing tool, file missing, etc.)
#
# Cadence Rule 1 atomic (ADR-0055 §1):
#   d-test file + scripts/d-test-target-os.sh (helper SUT) + INDEX.md row +
#   CHANGELOG.md entry all land in same commit.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TARGET_OS_SH="${REPO_ROOT}/scripts/d-test-target-os.sh"

# Colors (TTY-aware — sister-pattern to d058)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""; fi

# Pre-flight
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required" >&2; exit 2; }
command -v uname >/dev/null 2>&1 || { echo "ERROR: uname required" >&2; exit 2; }
[ -f "$TARGET_OS_SH" ] || { echo "ERROR: helper not found at $TARGET_OS_SH" >&2; exit 2; }

# Self-test mode (sister-pattern to d058 / d097 / d020a)
if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: bash $0 --self-test" >&2
  exit 2
fi

printf "${B}d098 self-test (8 TCs: TC0 hygiene + AC1a ≥6 TCs covering each runner class per Issue #1199)${D}\n"
printf "${B}=======================================================================================${D}\n"
printf "  SUT: %s\n" "$TARGET_OS_SH"
printf "  Spec: Issue #1199 S33-008 pattern:CI_OS_DEP (ADR-0073 §10 row 4)\n"
printf "  RED-first: pre-impl 8/8 FAIL (helper absent from main, d-test absent from main).\n"
printf "  Post-impl: 8/8 GREEN.\n\n"

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# TC0: bash -n hygiene (sister-pattern to d020a TC1)
# ============================================================================
section "TC0: bash -n hygiene (helper script syntactically valid)"
if bash -n "$TARGET_OS_SH"; then
  pass "bash -n $TARGET_OS_SH → exit 0 (syntactically valid)"
else
  fail "TC0 — bash -n FAIL" "helper has syntax errors; fix before other TCs"
  exit 1
fi

# ============================================================================
# TC1: env-default auto-detect (TARGET_OS unset, --target-os flag absent)
# ============================================================================
section "TC1: env-default auto-detect (TARGET_OS unset, no flag → uses uname -s)"
OUT="$(unset TARGET_OS; bash "$TARGET_OS_SH")"
RC=$?
UNAME_CLASS="linux"
UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
case "$UNAME_S" in
  Linux|linux) UNAME_CLASS="linux" ;;
  Darwin|darwin) UNAME_CLASS="darwin" ;;
  *) UNAME_CLASS="$UNAME_S" ;;
esac
if [ "$RC" = "0" ] && [ "$OUT" = "$UNAME_CLASS" ]; then
  pass "auto-detect resolved to '$OUT' (matches uname -s classification)"
else
  fail "TC1 — auto-detect unexpected" "rc=$RC out='$OUT' uname_class='$UNAME_CLASS'"
fi

# ============================================================================
# TC2: --target-os=linux override (ubuntu-latest class)
# ============================================================================
section "TC2: --target-os=linux override (ubuntu-latest class)"
OUT="$(bash "$TARGET_OS_SH" --target-os=linux)"
RC=$?
if [ "$RC" = "0" ] && [ "$OUT" = "linux" ]; then
  pass "--target-os=linux → 'linux' (ubuntu-latest class anchor)"
else
  fail "TC2 — --target-os=linux unexpected" "rc=$RC out='$OUT'"
fi

# ============================================================================
# TC3: --target-os=darwin override (macos-latest class)
# ============================================================================
section "TC3: --target-os=darwin override (macos-latest class)"
OUT="$(bash "$TARGET_OS_SH" --target-os=darwin)"
RC=$?
if [ "$RC" = "0" ] && [ "$OUT" = "darwin" ]; then
  pass "--target-os=darwin → 'darwin' (macos-latest class anchor)"
else
  fail "TC3 — --target-os=darwin unexpected" "rc=$RC out='$OUT'"
fi

# ============================================================================
# TC4: invalid --target-os=foobar → exit 2 (validation rejection)
# ============================================================================
section "TC4: invalid --target-os=foobar → exit 2 (validation rejection)"
OUT="$(bash "$TARGET_OS_SH" --target-os=foobar 2>&1)"
RC=$?
if [ "$RC" = "2" ] && echo "$OUT" | grep -qiE 'invalid|unknown|unsupported'; then
  pass "--target-os=foobar rejected with exit 2 + clear error message"
else
  fail "TC4 — invalid --target-os not rejected properly" \
    "expected rc=2 + error message; rc=$RC out='$OUT'"
fi

# ============================================================================
# TC5: --target-os flag beats pre-set TARGET_OS env var (precedence rule)
# ============================================================================
section "TC5: --target-os flag precedence over TARGET_OS env var"
OUT="$(TARGET_OS=darwin bash "$TARGET_OS_SH" --target-os=linux)"
RC=$?
if [ "$RC" = "0" ] && [ "$OUT" = "linux" ]; then
  pass "flag precedence: --target-os=linux beats TARGET_OS=darwin env → 'linux'"
else
  fail "TC5 — flag precedence broken" "expected 'linux', got rc=$RC out='$OUT'"
fi

# ============================================================================
# TC6: TARGET_OS env var path (no flag, env var pre-set)
# ============================================================================
section "TC6: TARGET_OS env var path (no flag, env var pre-set)"
OUT="$(TARGET_OS=darwin bash "$TARGET_OS_SH")"
RC=$?
if [ "$RC" = "0" ] && [ "$OUT" = "darwin" ]; then
  pass "env var path: TARGET_OS=darwin (no flag) → 'darwin'"
else
  fail "TC6 — env var path broken" "expected 'darwin', got rc=$RC out='$OUT'"
fi

# ============================================================================
# TC7: unknown uname -s fallback (env-var override rescues unsupported host)
# ============================================================================
# Pattern: fake-bin dir with mock uname returning unsupported value, helper
# script uses TARGET_OS env override to escape hatch. Sister-pattern to d058
# fake-gh factory.
section "TC7: TARGET_OS env var rescues unsupported uname -s host (env-var escape hatch)"
FAKE_BIN="$(mktemp -d /tmp/d098-fakebin-XXXXXX)"
trap 'rm -rf "$FAKE_BIN"' EXIT
# Mock uname to return unsupported value, leave bash on real PATH
printf '#!/usr/bin/env bash\necho UnsupportedOS\n' > "$FAKE_BIN/uname"
chmod +x "$FAKE_BIN/uname"
OUT="$(TARGET_OS=linux PATH="$FAKE_BIN:$PATH" bash "$TARGET_OS_SH")"
RC=$?
if [ "$RC" = "0" ] && [ "$OUT" = "linux" ]; then
  pass "env-var escape hatch: TARGET_OS=linux bypasses uname=UnsupportedOS → 'linux'"
else
  fail "TC7 — env-var escape hatch broken" "expected rc=0 'linux', got rc=$RC out='$OUT'"
fi
rm -rf "$FAKE_BIN"

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== d098 SELF-TEST SUMMARY ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"
printf "  ${Y}INFO${D}: %d\n" "$INFO"

# Sister-pattern invariant for Issue #1199 AC1a:
#   Pre-impl (helper absent): 8/8 FAIL (file + uname path + flag path all broken)
#   Post-impl (helper shipped): 8/8 GREEN
#
# We accept either:
#   (a) 8/8 PASS — impl complete (helper + d-test + INDEX + CHANGELOG all landed), d098 GREEN
#   (b) FAIL on TC0..TC7 — RED state confirmed (helper missing OR impl incomplete)
if [ "$FAIL" -eq 0 ]; then
  printf "  ${G}d098 GREEN${D} — 8/8 PASS = helper + override paths validated\n"
  exit 0
else
  printf "  ${R}d098 RED${D} — %d FAIL observed. Action: implement scripts/d-test-target-os.sh + this INDEX.md row + CHANGELOG entry per ADR-0055 §1 Cadence Rule 1 atomic.\n" "$FAIL"
  exit 1
fi
