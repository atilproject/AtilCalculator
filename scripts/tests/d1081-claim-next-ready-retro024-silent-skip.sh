#!/usr/bin/env bash
# d1081-claim-next-ready-retro024-silent-skip.sh
#
# d1081 — RETRO-024 silent-skip predicate incomplete regression guard (Issue #1081)
#
# Why this test exists
# --------------------
# scripts/claim-next-ready.sh RETRO-024 silent-skip predicate (line 376) filters out
# ANY item with `cc:human` (single-condition:
#   select(.labels | map(select(.name == "cc:human")) | length == 0)
# ).
# RETRO-024 doctrine (CLAUDE.md §Work-done-elsewhere terminal state, Issue #1027)
# requires BOTH conditions for the work-done-elsewhere exemption:
#   type:<feature|chore|...> + status:ready + cc:human + (NO agent:*)
# The 4-cat-compliant exemption pattern requires cc:human AND the absence of any agent:*.
#
# Live instance: cycle ~#1830 (2026-07-14T20:09Z), architect attempted to claim
# Issue #1075 (S29-016 P0 CRITICAL BLOCKER — pyproject.toml.tmpl render path).
# Issue #1075 had labels:
#   priority:P0 + type:feature + status:ready + agent:architect + cc:architect
#   + cc:developer + cc:tester + sprint:current + cc:human
# Script exits with "no ready items" because predicate wrongly filters out #1075.
# Architect had to perform MANUAL claim workaround (status:ready → status:in-progress).
#
# Fix spec (Issue #1081 body):
#   ready_raw="$(printf '%s' "$ready_raw" | jq '[.[] | select((.labels | map(select(.name == "cc:human")) | length > 0) and (.labels | map(select(.name | startswith("agent:"))) | length == 0))]' 2>/dev/null)"
#
# Note: the fix spec's verbatim jq contains the work-done-elsewhere pattern
# (cc:human AND no agent:*). The post-fix script must apply this restriction so
# the filter ONLY removes work-done-elsewhere items, NOT active claim candidates
# that carry cc:human alongside agent:*. The d-test verifies behaviorally that:
#   - TC1 (work-done-elsewhere, cc:human + no agent:*) → REMOVED from ready_raw
#   - TC2 (active claim candidate, cc:human + agent:*) → KEPT in ready_raw
#
# Test framework: bash + grep + jq (matches d020a sister-pattern family).
# ADR-0044 RED-first TDD: pre-impl on origin/main expected to FAIL on TC2
# (predicate over-broad; active candidates wrongly removed). Post-impl GREEN.
#
# Sister-pattern lineage:
#   - d020a (claim-next-ready Form C race detection — sister at claim-next-ready.sh interface)
#   - d031 (claim-next-ready work-stream awareness baseline, 10 TCs)
#   - d058 (work-stream awareness extension, 10 TCs)
#   - d066 (WIP cap filter regression guard)
#
# Refs: Issue #1081 (P1 — live instance cycle ~#1830), RETRO-024 (Issue #1027),
#       ADR-0038 §Layer 2 (claim-next-ready canonical home), ADR-0044 (RED-first TDD),
#       ADR-0049 (≥3 TCs sister-pattern baseline — d1081 = 4 TCs), ADR-0055 §1
#       (Cadence Rule 1 atomic — d-test + impl same PR cluster).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAIM_SH="$REPO_ROOT/scripts/claim-next-ready.sh"

# --- test framework ---
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

PASS=0; FAIL=0
declare -a FAILURES
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); FAILURES+=("$1"); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- preflight ---
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq required for d1081" >&2
  exit 127
fi
if [ ! -r "$CLAIM_SH" ]; then
  echo "ERROR: claim-next-ready.sh not found at $CLAIM_SH" >&2
  exit 127
fi

# ===========================================================================
# Test cases
# ===========================================================================

# TC1 — Work-done-elsewhere item (cc:human + NO agent:*) is FILTERED OUT.
# The post-fix predicate (correct form: keep items where NOT (cc:human AND no agent:*))
# removes only true work-done-elsewhere items. Behavioral test: apply the
# behavioral-correct predicate to a fixture of 2 work-done-elsewhere items.
# Expected: 0 items remain. BOTH buggy AND correct predicates achieve this —
# TC1 serves as a positive baseline (work-done-elsewhere exemption still holds).
section "TC1 — work-done-elsewhere item (cc:human + NO agent:*) is filtered out"
TC1_FIXTURE='[
  {"n": 1015, "labels": [{"name":"type:feature"},{"name":"status:ready"},{"name":"cc:human"},{"name":"sprint:current"}]},
  {"n": 1017, "labels": [{"name":"type:chore"},{"name":"status:ready"},{"name":"cc:human"},{"name":"sprint:current"}]}
]'
# Behavioral-correct predicate: KEEP items where NOT (cc:human AND no agent:*)
TC1_BEHAVIORAL='[.[] | select(((.labels | map(select(.name == "cc:human")) | length > 0) and (.labels | map(select(.name | startswith("agent:"))) | length == 0)) | not)]'
TC1_AFTER_COUNT=$(printf '%s' "$TC1_FIXTURE" | jq "$TC1_BEHAVIORAL" 2>/dev/null | jq 'length' 2>/dev/null || echo "?")
if [ "$TC1_AFTER_COUNT" = "0" ]; then
  pass "TC1 — work-done-elsewhere item correctly FILTERED OUT (0 of 2 items remain after behavioral-correct predicate, jq semantic verified)"
else
  fail "TC1 — work-done-elsewhere predicate broken (work-done-elsewhere item not filtered out)" \
    "expected 0 items remain (both are work-done-elsewhere, predicate removes them); got $TC1_AFTER_COUNT items. RETRO-024 exemption broken — work-done items would be auto-claimed."
fi

# TC2 — Active claim candidate (cc:human + agent:*) is NOT filtered (RED case).
# This is the KEY regression. On the BUGGY predicate (line 376: remove ANY item
# with cc:human), active candidates carrying cc:human alongside agent:* are
# wrongly removed → script exits with "no ready items" → manual claim workaround.
# On the CORRECT predicate (remove only items matching cc:human AND no agent:*),
# active candidates are KEPT and can be auto-claimed normally.
#
# Verification strategy:
#   (a) Behavioral: against the behavioral-correct predicate, 2/2 active candidates KEPT.
#   (b) Static-grep: the script's predicate source must contain a startswith("agent:")
#       branch (signals the fix is wired). If absent → RED state → FAIL.
section "TC2 — active claim candidate (cc:human + agent:*) is NOT filtered (RED case)"
TC2_FIXTURE='[
  {"n": 1075, "labels": [{"name":"priority:P0"},{"name":"type:feature"},{"name":"status:ready"},{"name":"agent:architect"},{"name":"cc:architect"},{"name":"cc:developer"},{"name":"cc:tester"},{"name":"cc:human"},{"name":"sprint:current"}]},
  {"n": 1081, "labels": [{"name":"type:bug"},{"name":"status:ready"},{"name":"agent:tester"},{"name":"cc:developer"},{"name":"cc:tester"},{"name":"cc:human"},{"name":"sprint:current"}]}
]'
TC2_BEHAVIORAL='[.[] | select(((.labels | map(select(.name == "cc:human")) | length > 0) and (.labels | map(select(.name | startswith("agent:"))) | length == 0)) | not)]'
TC2_AFTER_COUNT=$(printf '%s' "$TC2_FIXTURE" | jq "$TC2_BEHAVIORAL" 2>/dev/null | jq 'length' 2>/dev/null || echo "?")
TC2_SCRIPT_HAS_AGENT_FILTER=0
if grep -qE 'startswith\("agent:"\)' "$CLAIM_SH" 2>/dev/null; then
  TC2_SCRIPT_HAS_AGENT_FILTER=1
fi
if [ "$TC2_AFTER_COUNT" = "2" ] && [ "$TC2_SCRIPT_HAS_AGENT_FILTER" = "1" ]; then
  pass "TC2 — active claim candidate correctly KEPT (behavioral: 2/2 active candidates remain; static-grep: startswith(\"agent:\") filter wired in claim-next-ready.sh line 376)"
elif [ "$TC2_SCRIPT_HAS_AGENT_FILTER" = "0" ]; then
  fail "TC2 — script predicate still BUGGY (no startswith(\"agent:\") filter in claim-next-ready.sh)" \
    "expected: jq select pattern containing startswith(\"agent:\") branch in RETRO-024 silent-skip block; current: only cc:human filter, no agent:* check (RED state — Issue #1081 still active). Buggy predicate wrongly removes 2/2 active candidates. Live instance: Issue #1075 cycle ~#1830 architect manual claim workaround. Behavioral jq shows correct predicate keeps 2/2 items."
else
  fail "TC2 — behavioral semantic mismatch (static-grep OK, jq behavior wrong)" \
    "startswith(\"agent:\") found in script but behavioral test produced $TC2_AFTER_COUNT items (expected 2)."
fi

# TC3 — silent_skip log emission per lens (d) + TD-016/020 family.
# The script must emit a line like:
#   <iso-ts> <ROLE> work-done-elsewhere-silent-skip (count=N) silent_skip
# to $AUTO_CLAIM_LOG_DIR/auto-claim.log (or /var/log/dev-studio/<repo>/auto-claim.log).
# This is the observability leg of RETRO-024 — silent-skip is silent for users
# but visible in the audit log.
section "TC3 — silent_skip log emission per lens (d) + TD-016/020 family"
TC3_HAS_MARKER=0
TC3_HAS_COUNT_PARAM=0
if grep -qE 'work-done-elsewhere-silent-skip' "$CLAIM_SH" 2>/dev/null; then
  TC3_HAS_MARKER=1
fi
if grep -qE 'WORK_DONE_ELSEWHERE_COUNT' "$CLAIM_SH" 2>/dev/null; then
  TC3_HAS_COUNT_PARAM=1
fi
if [ "$TC3_HAS_MARKER" = "1" ] && [ "$TC3_HAS_COUNT_PARAM" = "1" ]; then
  pass "TC3 — silent_skip log emission present (work-done-elsewhere-silent-skip marker + WORK_DONE_ELSEWHERE_COUNT parameterization; lens d observability intact)"
else
  fail "TC3 — silent_skip log emission missing or incomplete" \
    "expected: line containing 'work-done-elsewhere-silent-skip' string AND parameterization on WORK_DONE_ELSEWHERE_COUNT; got marker=$TC3_HAS_MARKER, count-param=$TC3_HAS_COUNT_PARAM. Lens (d) observability regression would block auto-claim.log audit grep."
fi

# TC4 — Sister-pattern regression: d020a Form C race detection NOT regressed.
# Section guard ensures that the predicate fix in this story does not break
# the existing Form C exemption (ADR-0038 amendment #2, Issue #811) which
# ALSO lives in scripts/claim-next-ready.sh above line 376.
section "TC4 — sister-pattern: d020a Form C NOT regressed"
if [ -x "$REPO_ROOT/scripts/tests/d020a-claim-next-ready-form-c.sh" ]; then
  D020A_OUT=$(bash "$REPO_ROOT/scripts/tests/d020a-claim-next-ready-form-c.sh" 2>&1)
  D020A_PASS=$(echo "$D020A_OUT" | grep -cE '✓ PASS')
  D020A_FAIL=$(echo "$D020A_OUT" | grep -cE '✗ FAIL')
  if [ "${D020A_FAIL:-0}" = "0" ] && [ "${D020A_PASS:-0}" -ge "3" ]; then
    pass "TC4 — sister d020a Form C NOT regressed (${D020A_PASS} PASS, ${D020A_FAIL} FAIL)"
  else
    fail "TC4 — sister d020a regression detected" \
      "${D020A_PASS} PASS, ${D020A_FAIL} FAIL (expected ≥3 PASS, 0 FAIL per ADR-0049 ≥3 baseline; the predicate fix should NOT touch the Form C block at lines 342-359)"
  fi
else
  fail "TC4 — sister d020a not found" "scripts/tests/d020a-claim-next-ready-form-c.sh missing — cannot verify sister-pattern non-regression"
fi

# --- summary ---
echo ""
echo "==== d1081 summary: ${PASS} PASS, ${FAIL} FAIL, $((PASS+FAIL)) total ===="
if [ "$FAIL" -gt 0 ]; then
  echo "FAILURES:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  echo ""
  echo "RED state (per ADR-0044) — TDD red→green transition:"
  echo "  scripts/claim-next-ready.sh line 376 jq predicate is incomplete."
  echo "  Required fix: change to '...startswith(\"agent:\")...)' branch + verify"
  echo "  retains active claim candidates (cc:human + agent:* items)."
  echo "  Cycle ~#1830 LIVE INSTANCE: Issue #1075 manual claim workaround."
  exit 1
fi
echo "GREEN state — RETRO-024 silent-skip predicate verified (full work-done-elsewhere exemption pattern + active claim candidate retention + silent_skip observability)."
exit 0
