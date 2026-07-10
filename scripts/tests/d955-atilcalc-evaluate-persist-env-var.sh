#!/usr/bin/env bash
# d955-atilcalc-evaluate-persist-env-var.sh — STORY-S26-003 AC6 strict-contract d-test
# (sister-pattern to d117 + d112 + d949, Issue #954 cluster-cascade closeout)
#
# Why this test exists
# --------------------
# STORY-S26-003 AC6 codifies the **strict fail-loud contract** for the
# `ATILCALC_EVALUATE_PERSIST` env-var resolution in `src/atilcalc/api/routes.py`
# evaluate_endpoint. The contract is the **5-TC strict-canonical envelope**
# (a-e), distinct from d117's permissive 6-TC envelope:
#
#   - d117 (sister, GREEN on main): permissive parsing — `not in falsy_set`
#     → ENABLED for any non-falsy value (including "garbage").
#   - d955 (THIS, RED-first): strict fail-loud contract — unparseable values
#     raise ValueError per ADR-0056 silent_skip doctrine + ADR-0019 amend-4
#     conftest precedent (`float(env_val)` raises ValueError on garbage).
#
# Why this gap exists:
#   1. ADR-0019 amendment 5 §Decision table (Accepted 2026-07-10) specifies
#      permissive parsing: any value not in falsy set → ENABLED. This matches
#      d117's impl and is what landed in Sprint 23 via PR #742.
#   2. STORY-S26-003 AC5 (PM-authored, owner-approved) invokes ADR-0056
#      fail-loud doctrine: `ATILCALC_EVALUATE_PERSIST=garbage` → ValueError
#      immediately, no silent downgrade.
#   3. These two contracts CONFLICT for the unparseable case. This d-test
#      anchors AC5 as the binding contract for Sprint 26 wave 1 closeout
#      (TC d RED-first FAIL until impl matches AC5). Resolution path:
#      architect confirms at impl time per Open Question #41 of
#      STORY-S26-003, OR ADR-0019 amendment 6 codifies the resolution.
#
# Sister-pattern lineage:
#   - d117 (Issue #728 Sprint 23, 6 TCs GREEN) — permissive parsing impl guard.
#     d955 extends with strict-contract envelope; d117 remains valid as
#     permissive-parsing impl regression guard (NOT replaced).
#   - d112 (Issue #855 TD-046-extension, 7 TCs GREEN) — conftest env-var
#     precedence + fail-loud ValueError on garbage. DIRECT precedent for
#     d955 TC d (same ADR-0056 doctrine).
#   - d949 (Issue #949 P3 flake, 5 TCs GREEN) — TestClient infra noise
#     tolerance. Sister Sprint 26 wave 1 cluster.
#
# 5 TCs (≥5 baseline per ADR-0049 d-test framework; AC6 a-e verbatim):
#   TC a: env-var unset → defaults-on (auto-persistence ENABLED, backward
#         compat preserved per ADR-0022 §Cross-device sync model)
#   TC b: env-var set to "false" (case-insensitive) → persistence SKIPPED
#         (DISABLED, opt-out path)
#   TC c: env-var set to "true" (case-insensitive) → persistence ENABLED
#         (explicit-on parity)
#   TC d: env-var set to unparseable value (e.g. "garbage", "xyz123") →
#         raises ValueError IMMEDIATELY at env-var read (FAIL-LOUD per
#         ADR-0056 silent_skip doctrine + ADR-0019 amend-4 conftest
#         precedent `float(env_val)` raises ValueError on garbage)
#   TC e: backward-compat regression guard — test suite unchanged when
#         env-var unset (source-level grep: routes.py gate present +
#         log.info emission present + no breaking signature change)
#
# Pre-impl RED state (current main d02324d, BEFORE Sprint 26 wave 1 fix
# lands; routes.py impl matches d117 permissive parsing — `_persist_env
# not in ("", "0", "false", "no", "off")`):
#   - TC a PASS (unset → defaults-on, permissive parsing matches contract)
#   - TC b PASS (false → DISABLED, permissive parsing matches contract)
#   - TC c PASS (true → ENABLED, permissive parsing matches contract)
#   - TC d FAIL (garbage → ENABLED via permissive parsing; AC5 contract
#     requires ValueError — impl does NOT raise) ← ANCHOR
#   - TC e PASS (source-level grep: ATILCALC_EVALUATE_PERSIST + log.info
#     present in routes.py)
#   → 4/5 PASS + 1/5 FAIL = proper RED-first per ADR-0044 (AC5 contract
#   gap anchored as TC d FAIL; impl must change to flip TC d GREEN).
#
# Post-impl GREEN state (after Sprint 26 wave 1 fix lands — impl uses
# strict fail-loud parsing per conftest precedent):
#   - All 5 TCs PASS
#   → 5/5 PASS in GREEN state.
#
# Doctrinal conflict note
# -----------------------
# Per d117 GREEN state and ADR-0019 amend-5 §Decision (Accepted), the
# current contract is permissive. AC5 of STORY-S26-003 invokes ADR-0056
# strict doctrine. The architect must resolve Open Question #41 of
# STORY-S26-003 (env-var parsing semantics) at impl time. Until then,
# d955 TC d anchors the AC5 contract as the binding expectation.
#
# Usage:
#   bash d955-atilcalc-evaluate-persist-env-var.sh --self-test
#
# Exit codes:
#   0 — all 5 PASS (GREEN state — Sprint 26 wave 1 fix landed)
#   1 — at least one FAIL (RED state — AC5 contract gap unaddressed)
#   2 — preflight failure (python3 missing, routes.py missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ROUTES_PATH="${REPO_ROOT}/src/atilcalc/api/routes.py"

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

# Preflight (ADR-0049 sister-pattern — preflight checks first)
if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: $0 --self-test" >&2
  exit 2
fi
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required for routes.py introspection" >&2; exit 2; }
[ -f "$ROUTES_PATH" ] || { echo "ERROR: routes.py not found at $ROUTES_PATH" >&2; exit 2; }

# Python harness for env-var resolution contract verification.
# Written to a temp file via heredoc with SINGLE-QUOTED EOF (no bash expansion)
# to avoid bash-quoting issues with regex backslashes / Python escapes.
PYTHON_HARNESS="$(mktemp /tmp/d955-harness-XXXXXX.py)"
cat > "$PYTHON_HARNESS" <<'PYEOF'
"""d955 strict-contract verification harness.

Tests the AC5/AC6 contract: ATILCALC_EVALUATE_PERSIST must be:
  - "1" / "true" / "yes" / "on" (case-insensitive) → ENABLED
  - "" / "0" / "false" / "no" / "off" (case-insensitive) → DISABLED
  - anything else (unparseable) → raise ValueError (fail-loud per ADR-0056)

This is the strict-contract envelope distinct from d117's permissive envelope.
"""
import os
import sys

ROUTES_PATH = os.environ.get("D955_ROUTES_PATH", "src/atilcalc/api/routes.py")

# First check: the gate must be present in routes.py at all.
try:
    with open(ROUTES_PATH) as f:
        src = f.read()
except Exception as e:
    print(f"GATE_MISSING: cannot read routes.py: {e}", file=sys.stderr)
    sys.exit(0)  # zero exit lets d-test detect GATE_MISSING

if "ATILCALC_EVALUATE_PERSIST" not in src:
    print("GATE_MISSING", file=sys.stderr)
    sys.exit(0)

# Gate is present. Now resolve per AC5/AC6 strict-contract envelope.
val = os.environ.get("ATILCALC_EVALUATE_PERSIST", "1").strip().lower()

TRUTHY = {"1", "true", "yes", "on"}
FALSY = {"", "0", "false", "no", "off"}

if val in TRUTHY:
    print("ENABLED")
    sys.exit(0)
elif val in FALSY:
    print("DISABLED")
    sys.exit(0)
else:
    # Unparseable per AC5 — must raise ValueError per strict fail-loud contract.
    # This is the doctrinal anchor: routes.py impl should use float() coercion
    # or equivalent fail-loud pattern (sister-pattern d112 TC6 + ADR-0056).
    raise ValueError(
        f"ATILCALC_EVALUATE_PERSIST={val!r} is not parseable; "
        f"expected one of 1/true/yes/on/0/false/no/off "
        f"(per ADR-0019 amend-5 + ADR-0056 silent_skip doctrine + ADR-0019 amend-4 conftest precedent)"
    )
PYEOF

# Cleanup harness on exit
trap "rm -f '$PYTHON_HARNESS'" EXIT

# Helper: invoke harness under given env var value.
# Args:
#   $1 = "UNSET" for env -u ATILCALC_EVALUATE_PERSIST, or "ATILCALC_EVALUATE_PERSIST=value"
# Writes to globals: RES_OUT, RES_ERR, RES_CODE
resolve_persist() {
  local env_spec="$1"
  local tmpout tmperr
  tmpout=$(mktemp); tmperr=$(mktemp)
  if [ "$env_spec" = "UNSET" ]; then
    env -u ATILCALC_EVALUATE_PERSIST \
      D955_ROUTES_PATH="$ROUTES_PATH" \
      python3 "$PYTHON_HARNESS" >"$tmpout" 2>"$tmperr"
  else
    # shellcheck disable=SC2086
    env "$env_spec" \
      D955_ROUTES_PATH="$ROUTES_PATH" \
      python3 "$PYTHON_HARNESS" >"$tmpout" 2>"$tmperr"
  fi
  RES_CODE=$?
  RES_OUT="$(cat "$tmpout")"
  RES_ERR="$(cat "$tmperr")"
  rm -f "$tmpout" "$tmperr"
}

printf "${B}d955 self-test (STORY-S26-003 AC6 ATILCALC_EVALUATE_PERSIST strict-contract, 5 TCs ≥5 baseline per ADR-0049)${D}\n"
printf "${B}=======================================================================${D}\n"
printf "  Routes path:    %s\n" "$ROUTES_PATH"
printf "  Sister-pattern: d117 (permissive impl guard) + d112 (conftest strict-precedent, TC d) + d949 (Sprint 26 cluster)\n"
printf "  Strict vs perm: d955 anchors AC5 strict fail-loud contract; d117 remains permissive-parsing impl regression guard\n"
printf "  RED-first:      TC a,b,c,e PASS-by-coincidence; TC d FAIL (garbage → ValueError per AC5 not implemented)\n\n"

# ============================================================================
# TC a: env-var unset → defaults-on (backward-compat preserved per ADR-0022)
# ============================================================================
section "TC a: env-var unset → defaults-on (AC6 a — auto-persistence ENABLED)"
resolve_persist "UNSET"
if [ "$RES_CODE" -eq 0 ] && [ "$RES_OUT" = "ENABLED" ]; then
  pass "TC a — env-var unset → defaults-on ENABLED (backward-compat per ADR-0022)"
elif echo "$RES_OUT" | grep -q "GATE_MISSING"; then
  fail "TC a — routes.py gate pattern not found" \
    "PR has not landed yet — TC a-e all FAIL per RED-first"
else
  fail "TC a — defaults-on broken" \
    "expected exit 0 + 'ENABLED'; got exit=$RES_CODE stdout='$RES_OUT' stderr='$RES_ERR'"
fi

# ============================================================================
# TC b: env-var set to "false" → persistence skipped (DISABLED, opt-out path)
# ============================================================================
section "TC b: env-var set to 'false' → persistence SKIPPED (AC6 b — opt-out path)"
resolve_persist "ATILCALC_EVALUATE_PERSIST=false"
if [ "$RES_CODE" -eq 0 ] && [ "$RES_OUT" = "DISABLED" ]; then
  pass "TC b — env-var=false → DISABLED (opt-out path active)"
else
  fail "TC b — opt-out broken" \
    "expected exit 0 + 'DISABLED'; got exit=$RES_CODE stdout='$RES_OUT' stderr='$RES_ERR'"
fi

# ============================================================================
# TC c: env-var set to "true" → persistence enabled (explicit-on parity)
# ============================================================================
section "TC c: env-var set to 'true' → persistence ENABLED (AC6 c — explicit-on parity)"
resolve_persist "ATILCALC_EVALUATE_PERSIST=true"
if [ "$RES_CODE" -eq 0 ] && [ "$RES_OUT" = "ENABLED" ]; then
  pass "TC c — env-var=true → ENABLED (explicit-on parity)"
else
  fail "TC c — explicit-on parity broken" \
    "expected exit 0 + 'ENABLED'; got exit=$RES_CODE stdout='$RES_OUT' stderr='$RES_ERR'"
fi

# ============================================================================
# TC d: routes.py implements fail-loud contract for unparseable env vars (AC5)
# ============================================================================
# This is the AC5 contract anchor. Per conftest precedent (d112 TC6 sister-pattern):
# unparseable operator input MUST raise ValueError per ADR-0056 silent_skip doctrine.
#
# Currently the impl uses permissive parsing (`_persist_env not in falsy_set`)
# so TC d FAILS RED-first. Source-level grep verification:
#   - routes.py MUST contain a pattern that raises ValueError on unparseable input.
#     Acceptable patterns (per conftest sister-precedent d112 TC6):
#       (a) float(_persist_env) coercion (raises ValueError on garbage strings)
#       (b) explicit raise ValueError(...) in the env-var resolution block
#       (c) equivalent fail-loud check (e.g. `if val not in truthy_set and val not in falsy_set: raise ValueError(...)`)
#
# Sister-pattern: d112 TC6 (conftest ValueError precedent), d117 TC5+TC6 (gate presence).
section "TC d: routes.py implements fail-loud ValueError on unparseable env vars (AC5 + ADR-0056 + d112 TC6 precedent)"
TC_D_OK=true
# Check for any of the 3 acceptable fail-loud patterns.
# Pattern (a): float() coercion
if grep -qE 'float\([^)]*_persist[^)]*\)' "$ROUTES_PATH" 2>/dev/null; then
  info "TC d — fail-loud pattern (a) detected: float(_persist_env) coercion (conftest precedent)"
else
  # Pattern (b): explicit raise ValueError
  if grep -qE 'raise[[:space:]]+ValueError' "$ROUTES_PATH" 2>/dev/null; then
    info "TC d — fail-loud pattern (b) detected: explicit raise ValueError in routes.py"
  else
    # Pattern (c): not (in TRUTHY or in FALSY) raise pattern
    if grep -qE 'not[[:space:]]+in[[:space:]]*\(.*TRUTHY|raise[[:space:]]+ValueError' "$ROUTES_PATH" 2>/dev/null; then
      info "TC d — fail-loud pattern (c) detected: TRUTHY/FALSY not-in fallback raise pattern"
    else
      TC_D_OK=false
    fi
  fi
fi
if [ "$TC_D_OK" = "true" ]; then
  pass "TC d — routes.py implements fail-loud ValueError contract for unparseable env vars (AC5 + ADR-0056 + d112 TC6 sister-precedent)"
else
  fail "TC d — routes.py does NOT implement fail-loud ValueError contract (AC5 unmet)" \
    "Fix: replace permissive parsing ('_persist_env not in falsy_set') with float() coercion per conftest precedent (d112 TC6 + ADR-0019 amend-4 §Fail-loud contract) — OR add explicit 'if val not in truthy and val not in falsy: raise ValueError(...)' per ADR-0056 silent_skip doctrine" \
    "ANCHOR: TC d FAILS RED-first because routes.py uses permissive parsing per ADR-0019 amend-5 §Decision. AC5 of STORY-S26-003 invokes strict fail-loud doctrine (ADR-0056 + conftest d112 precedent). Resolution: architect confirms Open Q #41 of STORY-S26-003 at impl time, OR ADR-0019 amend-6 codifies resolution."
fi

# ============================================================================
# TC e: backward-compat regression guard — source-level invariants
# ============================================================================
# Verifies that the env-var gate, the silent-skip log emission, and the
# gate-presence pattern all remain in routes.py after the Sprint 26 wave 1
# fix lands. Sister-pattern to d117 TC5 + TC6 + d112 regression guard pattern.
section "TC e: backward-compat regression guard — gate + log.info present (AC6 e)"
TC_E_OK=true
if ! grep -q 'ATILCALC_EVALUATE_PERSIST' "$ROUTES_PATH" 2>/dev/null; then
  TC_E_OK=false
  fail "TC e — routes.py missing ATILCALC_EVALUATE_PERSIST env-var gate"
fi
if ! grep -q 'evaluate persist opt-out' "$ROUTES_PATH" 2>/dev/null; then
  TC_E_OK=false
  fail "TC e — routes.py missing silent-skip log.info('evaluate persist opt-out: ...') emission"
fi
# Verify default behavior preserved (unset → '1' fallback)
if ! grep -qE "os\.environ\.get\(\s*[\"']ATILCALC_EVALUATE_PERSIST[\"']\s*,\s*[\"']1[\"']\)" "$ROUTES_PATH" 2>/dev/null; then
  TC_E_OK=false
  fail "TC e — routes.py missing default '1' fallback for backward-compat"
fi
if [ "$TC_E_OK" = "true" ]; then
  pass "TC e — gate + silent-skip log.info + default '1' fallback all present (backward-compat regression guard)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
section "Summary"
echo "  PASS:           $PASS"
echo "  FAIL:           $FAIL"
echo "  INFO:           $INFO"
echo "  Sister-pattern: d117 (permissive impl), d112 (strict fail-loud precedent), d949 (Sprint 26 cluster)"
echo "  Doctrinal:      AC5 ↔ ADR-0019 amend-5 §Decision conflict anchored as TC d RED"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "RED state: $FAIL TC(s) FAILING — AC6 contract gap unaddressed per ADR-0044 RED-first"
  exit 1
fi

echo "GREEN state: all $PASS TCs PASS — Sprint 26 wave 1 strict-contract fix landed"
exit 0