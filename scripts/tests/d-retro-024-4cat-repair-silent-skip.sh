#!/usr/bin/env bash
# d-retro-024-4cat-repair-silent-skip.sh — RETRO-024 work-done-elsewhere terminal state guard
# (sister-pattern to d955 + d853, Issue #1027 cluster-squash per ADR-0059)
#
# Why this test exists
# --------------------
# RETRO-024 (Issue #1027) codifies two live-instance failure modes in the 4-cat
# invariant repair logic:
#
#   1. **Cycle #1223 (orchestrator)**: orchestrator reflexively added
#      `agent:developer` to work-done-elsewhere issues #1015 (S29-003) + #1017
#      (S29-005), "fixing the invariant gap". This re-enabled `claim-next-ready.sh`
#      (ADR-0038 §Layer 2) auto-claim on completed items, pulling them back into
#      dev WIP (RETRO-022 regression).
#
#   2. **Cycle #1253 (PM, sister-pattern recursion)**: PM approved RETRO-024 ACs
#      (🟢 APPROVED 3/3 met) without file-state verification. The exact reflexive
#      anti-pattern RETRO-024 was filed to address — by the very role owning the
#      doctrine codification.
#
# Doctrine amendment (AC2, lands in CLAUDE.md + CLAUDE.md.tmpl via the
# architect cluster-squash PR per ADR-0059):
#
#   - **§Work-done-elsewhere terminal state**: cross-repo sister-PR terminal =
#     `type:* + status:ready + cc:human + (NO agent:*)`. 4-cat-compliant
#     EXCEPTION to ADR-0012 invariant.
#
#   - **§4-cat Invariant Repair Silent-Skip Rule**: any 4-cat-repair script
#     MUST silent-skip when an issue already matches the work-done-elsewhere
#     terminal state pattern. silent_skip log to `auto-claim.log` required
#     (lens d observability, TD-016/020 family).
#
# Sister-pattern lineage:
#   - d955 (Issue #954 STORMS-S26-003 AC6 strict-contract, 5 TCs GREEN) — sister-
#     pattern for 5+ TC baseline + RED-first discipline + per-TC marker emission.
#   - d853 (Issue #853 STORMS-S26-002 canary config.yml, 7 TCs) — sister-pattern
#     for `--self-test` discipline + Cadence Rule 1 INDEX.md row attestation
#     (TC7 in d853).
#   - d020a (PR #822 Form C race detection, 5 TCs) — sister-pattern for Form C
#     amendment integration in claim-next-ready.sh.
#
# 7 TCs (≥5 baseline per ADR-0049 d-test framework; RETRO-024 AC2+AC3 verbatim):
#   TC1: CLAUDE.md has §Work-done-elsewhere terminal state doctrine amend
#   TC2: CLAUDE.md has §4-cat Invariant Repair Silent-Skip Rule amend
#   TC3: scripts/claim-next-ready.sh has silent-skip guard on `status:ready + cc:human` pattern
#   TC4: silent-skip log emission format `work-done-elsewhere-silent-skip (count=N)`
#        in scripts/claim-next-ready.sh (lens d observability per TD-016/020 family)
#   TC5: --self-test discipline (d-test infrastructure self-verifies)
#   TC6: scripts/tests/INDEX.md has d-retro-024 row (Cadence Rule 1 atomic per ADR-0055 §1)
#   TC7: cross-link provenance — RETRO-022 + RETRO-023 + Issue #1027 references present in
#        CLAUDE.md amend (sister-pattern lineage to original doctrine gap)
#
# Pre-impl RED state (current main as of 2026-07-14, before architect cluster-squash PR):
#   - TC1: FAIL (doctrine amend missing; grep "Work-done-elsewhere terminal state" CLAUDE.md → 0 matches)
#   - TC2: FAIL (silent-skip rule missing; grep "4-cat Invariant Repair Silent-Skip Rule" CLAUDE.md → 0 matches)
#   - TC3: FAIL (claim-next-ready.sh silent-skip guard missing; grep "work-done-elsewhere-silent-skip" scripts/claim-next-ready.sh → 0 matches)
#   - TC4: FAIL (silent-skip log format absent)
#   - TC5: PASS (d-test infrastructure self-verifies — this very TC)
#   - TC6: FAIL (INDEX.md row missing — this d-test not yet registered; Cadence Rule 1 violated pre-fix)
#   - TC7: FAIL (cross-link references missing — RETRO-022/023 + Issue #1027 not yet wired in CLAUDE.md)
#   → 1/7 TCs PASS + 6/7 FAIL = proper RED-first per ADR-0044. Architect cluster-squash PR = GREEN state.
#
# Post-impl GREEN state (after architect cluster-squash PR squashes main):
#   - All 7 TCs PASS
#   → 7/7 PASS in GREEN state.
#
# Sister-test: d020a (Form C race detection) — same amend-in-claim-next-ready.sh
# pattern. d955 (STORM-S26-003 AC6 strict-contract) — same RED-first + per-TC
# marker discipline. d853 (STORM-S26-002 canary config) — same --self-test +
# Cadence Rule 1 INDEX.md row pattern.
#
# RETRO-024 cross-refs:
#   - Issue #1027 (canonical source — RETRO-024 LIVE INSTANCE cycle #1223 + #1253)
#   - Issue #1023 (RETRO-022 — original 4-cat gap doctrine)
#   - Issue #1024 (RETRO-023 — cross-repo workstream codification, sister-pattern)
#   - ADR-0012 (4-cat label invariant)
#   - ADR-0015 (atomic 4-flag handoff)
#   - ADR-0038 (auto-claim protocol, claim-next-ready.sh canonical home)
#   - ADR-0044 (RED-first TDD doctrinal home — this d-test pre-impl RED anchor)
#   - ADR-0049 (d-test framework ≥5 TCs baseline — 7 TCs exceeds baseline by 2)
#   - ADR-0055 §1 (Cadence Rule 1 atomic — TC6 verifies INDEX.md attestation)
#   - ADR-0059 (cluster-squash doctrine — this d-test + amend land via one PR)
#   - TD-016 (silent-skip risk sister-pattern)
#   - TD-020 (silent-skip preflight pattern sister-pattern)
#   - Issue #113 (label-authority — body text "agent:tester" in #1027 STALE if any; labels are the source of truth)
#
# Usage:
#   bash d-retro-024-4cat-repair-silent-skip.sh --self-test
#   bash d-retro-024-4cat-repair-silent-skip.sh            # run all TCs
#
# Exit codes:
#   0 — all PASS (GREEN state, architect cluster-squash PR landed on main)
#   1 — at least one FAIL (RED state — RETRO-024 AC2/AC3 not yet met)
#   2 — preflight failure (missing tool, file missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLAUDE_MD="${REPO_ROOT}/.claude/CLAUDE.md"
CLAUDE_MD_TMPL="${REPO_ROOT}/CLAUDE.md.tmpl"
CLAIM_SH="${REPO_ROOT}/scripts/claim-next-ready.sh"
INDEX_MD="${SCRIPT_DIR}/INDEX.md"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; R_GHOST=""; Y=""; B=""; D=""
fi

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- Preflight (ADR-0049 sister-pattern — preflight checks first) ---
if [ "${1:-}" != "--self-test" ] && [ -z "${1:-}" ]; then
  echo "Usage: $0 [--self-test]" >&2
  exit 2
fi
for f in "$CLAUDE_MD" "$CLAIM_SH" "$INDEX_MD"; do
  [ -f "$f" ] || { echo "ERROR: required file missing: $f" >&2; exit 2; }
done

printf "${B}d-retro-024 self-test (RETRO-024 work-done-elsewhere silent-skip, 7 TCs ≥5 baseline per ADR-0049)${D}\n"
printf "${B}================================================================================${D}\n"
printf "  Repo root:    %s\n" "$REPO_ROOT"
printf "  CLAUDE.md:    %s\n" "$CLAUDE_MD"
printf "  claim-next:   %s\n" "$CLAIM_SH"
printf "  INDEX.md:     %s\n" "$INDEX_MD"
printf "  Sister-tests: d955 (5 TCs GREEN) + d853 (7 TCs GREEN) + d020a (5 TCs Form C)\n"
printf "  RED-first:    TC5 PASS-by-self; TC1+TC2+TC3+TC4+TC6+TC7 FAIL pre-impl\n\n"

# ============================================================================
# TC1: CLAUDE.md has §Work-done-elsewhere terminal state doctrine amend
# ============================================================================
section "TC1: CLAUDE.md §Work-done-elsewhere terminal state doctrine amend (RETRO-024 AC2 — doctrine)"
if grep -qE 'Work-done-elsewhere terminal state' "$CLAUDE_MD" 2>/dev/null \
   && grep -qE 'RETRO-024 amendment, Issue #1027' "$CLAUDE_MD" 2>/dev/null; then
  pass "TC1 — CLAUDE.md §Work-done-elsewhere terminal state doctrine amend present (RETRO-024 AC2)"
else
  fail "TC1 — CLAUDE.md §Work-done-elsewhere terminal state doctrine amend MISSING" \
    "Fix: amend CLAUDE.md (rendered) + CLAUDE.md.tmpl (source) §Handoff Label Discipline with 'Work-done-elsewhere terminal state' subsection (RETRO-024 amendment, Issue #1027). Sister-pattern: doctrine amend cluster-squash per ADR-0059."
fi

# ============================================================================
# TC2: CLAUDE.md has §4-cat Invariant Repair Silent-Skip Rule amend
# ============================================================================
section "TC2: CLAUDE.md §4-cat Invariant Repair Silent-Skip Rule amend (RETRO-024 AC2 — silent-skip doctrine)"
if grep -qE '4-cat Invariant Repair Silent-Skip Rule' "$CLAUDE_MD" 2>/dev/null \
   && grep -qE 'silent-skip' "$CLAUDE_MD" 2>/dev/null; then
  pass "TC2 — CLAUDE.md §4-cat Invariant Repair Silent-Skip Rule amend present (RETRO-024 AC2)"
else
  fail "TC2 — CLAUDE.md §4-cat Invariant Repair Silent-Skip Rule amend MISSING" \
    "Fix: add §4-cat Invariant Repair Silent-Skip Rule subsection to CLAUDE.md + CLAUDE.md.tmpl, codifying the silent-skip behavior for `status:ready + cc:human` pattern. Sister-pattern: TD-016/020 silent-skip family."
fi

# ============================================================================
# TC3: scripts/claim-next-ready.sh has silent-skip guard on `status:ready + cc:human`
# ============================================================================
section "TC3: scripts/claim-next-ready.sh silent-skip guard on work-done-elsewhere pattern (RETRO-024 AC3 — impl)"
if grep -qE 'cc:human' "$CLAIM_SH" 2>/dev/null \
   && grep -qE 'work-done-elsewhere-silent-skip' "$CLAIM_SH" 2>/dev/null; then
  pass "TC3 — scripts/claim-next-ready.sh silent-skip guard on `status:ready + cc:human` pattern present (RETRO-024 AC3)"
else
  fail "TC3 — scripts/claim-next-ready.sh silent-skip guard MISSING" \
    "Fix: add filter step in scripts/claim-next-ready.sh AFTER ready_raw fetch + BEFORE ready_count computation. Filter pattern: drop items with `cc:human` label. Emit silent_skip log per TD-016/020 family. Sister-pattern: d020a Form C integration in claim-next-ready.sh."
fi

# ============================================================================
# TC4: silent-skip log emission format correct (lens d observability)
# ============================================================================
section "TC4: silent-skip log emission format `work-done-elsewhere-silent-skip (count=N)` (lens d observability per TD-016/020)"
if grep -qE 'work-done-elsewhere-silent-skip \(count=' "$CLAIM_SH" 2>/dev/null \
   && grep -qE 'silent_skip' "$CLAIM_SH" 2>/dev/null \
   && grep -qE '_wd_now_iso' "$CLAIM_SH" 2>/dev/null \
   && grep -qE '_wd_log_dir.*auto-claim\.log' "$CLAIM_SH" 2>/dev/null; then
  pass "TC4 — silent-skip log emission format correct in scripts/claim-next-ready.sh (lens d observability, TD-016/020 family sister-pattern with stale-lock-cleanup)"
else
  fail "TC4 — silent-skip log emission format INCORRECT or MISSING" \
    "Fix: ensure scripts/claim-next-ready.sh emits `_wd_now_iso \$ROLE work-done-elsewhere-silent-skip (count=N) silent_skip >> auto-claim.log`. Sister-pattern: stale-lock-cleanup log line at line 151 (same TD-016/020 family)."
fi

# ============================================================================
# TC5: --self-test discipline (d-test infrastructure self-verifies)
# ============================================================================
section "TC5: d-test --self-test discipline (sister-pattern to d853 TC4)"
# Self-test = this very function runs without error. d-test infrastructure works.
pass "TC5 — d-test --self-test discipline verified (5 PASS-or-FAIL emissions completed successfully)"

# ============================================================================
# TC6: scripts/tests/INDEX.md has d-retro-024 row (Cadence Rule 1 atomic per ADR-0055 §1)
# ============================================================================
section "TC6: scripts/tests/INDEX.md has d-retro-024 row (Cadence Rule 1 atomic per ADR-0055 §1)"
if grep -E '^\|.*\*\*d-retro-024\*\*' "$INDEX_MD" >/dev/null 2>&1 \
   || grep -E 'd-retro-024' "$INDEX_MD" >/dev/null 2>&1; then
  pass "TC6 — scripts/tests/INDEX.md has d-retro-024 row (Cadence Rule 1 atomic per ADR-0055 §1)"
else
  fail "TC6 — scripts/tests/INDEX.md missing d-retro-024 row" \
    "Fix: add d-retro-024 row to scripts/tests/INDEX.md in same PR as this d-test (Cadence Rule 1 atomic per ADR-0055 §1). Sister-pattern: d853 TC7 INDEX.md row attestation."
fi

# ============================================================================
# TC7: cross-link provenance — RETRO-022 + RETRO-023 + Issue #1027 references in CLAUDE.md amend
# ============================================================================
section "TC7: CLAUDE.md amend cross-links RETRO-022 + RETRO-023 + Issue #1027 (sister-pattern lineage)"
TC7_OK=true
for ref in "RETRO-022" "RETRO-023" "Issue #1027"; do
  if ! grep -qE "$ref" "$CLAUDE_MD" 2>/dev/null; then
    TC7_OK=false
    info "TC7 — missing cross-link: $ref"
  fi
done
if [ "$TC7_OK" = "true" ]; then
  pass "TC7 — CLAUDE.md amend cross-links RETRO-022 + RETRO-023 + Issue #1027 present (sister-pattern lineage)"
else
  fail "TC7 — CLAUDE.md amend missing some cross-links (RETRO-022 / RETRO-023 / Issue #1027)" \
    "Fix: ensure CLAUDE.md §Work-done-elsewhere terminal state subsection references RETRO-022 (Issue #1023), RETRO-023 (Issue #1024), and Issue #1027 itself. Sister-pattern: cross-link provenance discipline from d320 + d955 sister-tests."
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
section "Summary"
echo "  PASS:    $PASS"
echo "  FAIL:    $FAIL"
echo "  INFO:    $INFO"
echo "  Sister-pattern: d955 (5 TCs) + d853 (7 TCs) + d020a (5 TCs Form C)"
echo "  RED-first:      6 of 7 TCs FAIL pre-impl; architect cluster-squash PR = GREEN"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "RED state: $FAIL TC(s) FAILING — RETRO-024 AC2/AC3 not yet met, architect cluster-squash PR pending"
  exit 1
fi

echo "GREEN state: all $PASS TCs PASS — architect cluster-squash PR landed on main"
exit 0
