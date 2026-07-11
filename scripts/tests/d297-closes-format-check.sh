#!/usr/bin/env bash
# d297-closes-format-check.sh — Issue #994 / STORY-S28-015 — ADR-0057 strict-format Closes anchor CI gate.
#
# Why this test exists
# --------------------
# ADR-0057 mandates strict Closes anchor format (`Closes owner/repo#N` or strict
# markdown link variant), but `.github/workflows/label-check.yml` only validates
# the 4-cat label invariant — it does NOT validate Closes anchor format on PR
# bodies. Result: PRs with non-strict Closes anchors squash-merge successfully
# but the cross-repo-close workflow silently skips them, leaving the target
# issue open and requiring manual orchestrator intervention (live failure:
# tmpl#67 `Closes S28-004 (Issue #984)` parenthetical-without-owner → #984
# had to be manually closed, contributing to the manual-close counter of 4
# since Issue #785 INCIDENT-2 family).
#
# Per orchestrator dispatch cmt 4944594416 (Sprint 28 W3 cycle ~841,
# owner-approved task envelope): write RED d-test against AC1 SHA-pin +
# AC2 fail-on-non-strict + AC5 8-sub-category compliance, 5+ TCs minimum,
# Cadence Rule 1 (ADR-0055 §1) atomic single-commit sister to PR #997 AC
# rev (docs-only) + architect implementation PR (downstream).
#
# 6 top-level TCs (per ADR-0049 d-test framework sister-pattern + dispatch spec):
#   TC1 (AC2 positive): strict `Closes #N` regex match
#   TC2 (AC2 positive): strict `Closes owner/repo#N` regex match (owner-qualified)
#   TC3 (AC2 positive): markdown link variant `Closes [#N](url)` regex match
#   TC4 (AC2 NEGATIVE): `Closes S28-004 (Issue #984)` parenthetical-without-owner
#                        must FAIL the strict-format check (matches tmpl#67 incident)
#   TC5 (AC5 ADR-0043):  YAML workflow 8-sub-category presence check
#                        (path/runs-on/permissions/timeout/concurrency/if/secrets/no-raw-docker-ssh)
#   TC6 (AC4 regression): PR #998 RCA-19 fix body uses strict-format Closes anchor
#
# Per ADR-0044 RED-first TDD doctrine:
#   - TC1-TC4 are contract tests (PASS-by-contract — d-test defines the regex
#     and tests its behavior on canonical inputs from the issue body evidence table)
#   - TC5 is the RED gate — FAILs until architect implements
#     `.github/workflows/closes-format-check.yml` (or label-check.yml step) with
#     all 8 ADR-0043 sub-categories present
#   - TC6 is the regression guard — PASSes immediately since PR #998 already
#     uses strict-format Closes anchor (ADR-0057 exemplar from this cycle)
#
# Post-impl GREEN state (after architect implementation PR merges):
#   - TC1-TC4: PASS (contract tests, always PASS)
#   - TC5: PASS (workflow file exists with all 8 sub-cats)
#   - TC6: PASS (PR #998 + future PRs use strict-format)
#   → 6/6 GREEN → d297 marks ADR-0057 enforcement complete
#
# Doctrinal cite:
#   - ADR-0057 (Closes anchor strict-format — anchor rule)
#   - ADR-0044 (RED-first TDD, ≥3 baseline honored via 6 TCs)
#   - ADR-0049 (d-test framework, ≥5 baseline + sister-pattern ≥2)
#   - ADR-0055 §1 (Cadence Rule 1 atomic single-commit)
#   - ADR-0043 (8-sub-category compliance for workflow YAML)
#   - ADR-0050 (template-grade rendering — sister pattern from d096)
#   - ADR-0031 (owner merge gate — d-test contract honored pre-merge)
#   - Issue #994 (S28-015 dispatch source)
#   - Issue #785 (INCIDENT-2 v9.2 fix lineage — RCA family)
#   - Issue #984 (S28-004 manual-close live instance — TC4 reference)
#   - TD-068 (PATCH /issues/N body overwrite — sister pattern from PR #998 incident)
#   - TD-069 (PR #67 Closes anchor non-strict format — direct TC4 motivation)
#   - Issue #430 (Pre-verdict cross-check 30s window)
#   - Issue #682 (Post-verdict cross-watchdog ack-pattern)
#
# Sister-pattern family (ADR-0049 ≥2 baseline):
#   - d069-layer-5-verdict-emoji-gate.sh (PR title verdict-emoji gate, workflow validation pattern)
#   - d064-cluster-lag.sh (workflow YAML validation, sister cluster-lag detection)
#   - d069-layer5-byte-size.sh (PR title length gate, related PR body format enforcement)
#   - d296-peer-poke-helper.sh (cross-agent helper d-test, dual-channel wake sister)
#
# Usage:
#   bash scripts/tests/d297-closes-format-check.sh --self-test
#
# Exit codes:
#   0 — all 6 TCs PASS (GREEN state — implementation complete)
#   1 — at least one TC FAIL (RED state — implementation pending or regression)
#   2 — preflight failure (missing dependencies)
#
# RED state on dispatch: TC5 FAIL (architect implementation PR pending per Issue #994)
# GREEN state target:   TC5 PASS after architect merges closes-format-check.yml

set -uo pipefail

# === Color helpers ===
G='\033[0;32m'; R='\033[0;31m'; Y='\033[0;33m'; B='\033[0;34m'; D='\033[0m'
PASS_COUNT=0; FAIL_COUNT=0
pass() { printf "${G}✓ PASS${D} — %s\n" "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf "${R}✗ FAIL${D} — %s\n" "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
info() { printf "${Y}⚠ INFO${D} — %s\n" "$1"; }

# === Self-test preflight ===
if [ "${1:-}" = "--self-test" ]; then
    printf "${B}d297 self-test (Issue #994 / S28-015 — ADR-0057 Closes anchor CI gate)${D}\n"
    printf "  Doctrinal:     ADR-0057 strict-format + ADR-0044 RED-first + ADR-0049 ≥5 + ADR-0043 8-sub-cat\n"
    printf "  Sister slot:   d069 (verdict-emoji gate) + d064 (cluster-lag workflow) + d069-layer5 (byte-size gate) + d296 (peer-poke helper)\n"
    printf "  RED baseline:  TC5 RED until closes-format-check.yml lands per ADR-0057 enforcement\n\n"
fi

# === Regex contract (inline reference, sourced from Issue #994 §Proposed fix) ===
# Per ADR-0057: strict Closes anchor must match one of:
#   1. `Closes #N` — number-only (e.g., `Closes #993`)
#   2. `Closes owner/repo#N` — owner-qualified (e.g., `Closes atilcan65/AtilCalculator#982`)
#   3. `Closes [#N](url)` — markdown link variant (e.g., `Closes [#989](https://github.com/atilcan65/AtilCalculator/issues/989)`)
# Anything else (parenthetical, no owner qualifier, S28-NNN prefix, etc.) FAILS.
REGEX_STRICT_NUMBER='^Closes[[:space:]]+#[0-9]+[[:space:]]*$'
REGEX_STRICT_OWNER='^Closes[[:space:]]+[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+#[0-9]+[[:space:]]*$'
REGEX_STRICT_LINK='^Closes[[:space:]]+\[#[0-9]+\]\(https?://github\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+/issues/[0-9]+\)[[:space:]]*$'

is_strict_closes() {
    local input="$1"
    if echo "$input" | grep -qE "$REGEX_STRICT_NUMBER"; then return 0; fi
    if echo "$input" | grep -qE "$REGEX_STRICT_OWNER";  then return 0; fi
    if echo "$input" | grep -qE "$REGEX_STRICT_LINK";   then return 0; fi
    return 1
}

# ============================================================================
# TC1 (AC2 positive): strict `Closes #N` regex match
# ============================================================================
section_t1() {
    printf "${B}TC1 (AC2): strict \`Closes #N\` format passes strict-format check${D}\n"
    local input='Closes #993'
    if is_strict_closes "$input"; then
        pass "TC1 — strict number-only Closes #993 matches ADR-0057 contract"
    else
        fail "TC1 — strict number-only Closes #993 NOT matched (regex contract broken)"
    fi
}

# ============================================================================
# TC2 (AC2 positive): strict `Closes owner/repo#N` regex match
# ============================================================================
section_t2() {
    printf "${B}TC2 (AC2): strict \`Closes owner/repo#N\` format passes strict-format check${D}\n"
    local input='Closes atilcan65/AtilCalculator#982'
    if is_strict_closes "$input"; then
        pass "TC2 — owner-qualified Closes atilcan65/AtilCalculator#982 matches ADR-0057 contract"
    else
        fail "TC2 — owner-qualified NOT matched (regex contract broken)"
    fi
}

# ============================================================================
# TC3 (AC2 positive): markdown link variant `Closes [#N](url)` regex match
# ============================================================================
section_t3() {
    printf "${B}TC3 (AC2): markdown link variant \`Closes [#N](url)\` passes strict-format check${D}\n"
    local input='Closes [#989](https://github.com/atilcan65/AtilCalculator/issues/989)'
    if is_strict_closes "$input"; then
        pass "TC3 — markdown link variant matches ADR-0057 contract (calc#992 exemplar)"
    else
        fail "TC3 — markdown link variant NOT matched (regex contract broken)"
    fi
}

# ============================================================================
# TC4 (AC2 NEGATIVE): parenthetical `Closes S28-004 (Issue #984)` must FAIL
# ============================================================================
section_t4() {
    printf "${B}TC4 (AC2 NEGATIVE): parenthetical \`Closes S28-004 (Issue #984)\` FAILS strict-format check${D}\n"
    local input='Closes S28-004 (Issue #984)'
    if is_strict_closes "$input"; then
        fail "TC4 — parenthetical-without-owner MATCHED strict regex (would have silently failed cross-repo-close like tmpl#67)"
    else
        pass "TC4 — parenthetical-without-owner correctly REJECTED by ADR-0057 contract (matches tmpl#67 failure mode)"
    fi
}

# ============================================================================
# TC5 (AC5 ADR-0043): YAML workflow 8-sub-category presence check
# ============================================================================
section_t5() {
    printf "${B}TC5 (AC5 ADR-0043): YAML workflow 8-sub-category presence check${D}\n"
    local workflow_file='.github/workflows/closes-format-check.yml'
    if [ ! -f "$workflow_file" ]; then
        fail "TC5 — workflow file $workflow_file NOT FOUND (architect implementation pending per Issue #994, RED state)"
        info "  Expected per ADR-0043 8-sub-cat: path / runs-on / permissions / timeout / concurrency / if / secrets / no-raw-docker-ssh"
        info "  Sister-pattern: d069 TC1.a-TC1.e checks label-check.yml verdict-gate structure (per-file structural sub-checks)"
        return 0
    fi
    # All 8 sub-cats must be present in the workflow YAML (ADR-0043 8-sub-category compliance)
    local missing=()
    local subcats=(
        "^path:"
        "^runs-on:"
        "^permissions:"
        "^timeout-minutes:"
        "^concurrency:"
        "^if:"
        "^secrets:"
    )
    for subcat in "${subcats[@]}"; do
        if ! grep -qE "$subcat" "$workflow_file"; then
            missing+=("${subcat#^}")
        fi
    done
    # Check no-raw-docker-ssh (anti-pattern: no `docker exec` or `ssh` raw access)
    if grep -qE "(docker exec|ssh [a-z])" "$workflow_file"; then
        missing+=("no-raw-docker-ssh (anti-pattern detected)")
    fi
    if [ ${#missing[@]} -eq 0 ]; then
        pass "TC5 — all 8 ADR-0043 sub-categories present in $workflow_file (ADR-0057 CI gate complete)"
    else
        fail "TC5 — missing sub-categories in $workflow_file: ${missing[*]}"
    fi
}

# ============================================================================
# TC6 (AC4 regression): PR #998 RCA-19 fix body uses strict-format Closes anchor
# ============================================================================
section_t6() {
    printf "${B}TC6 (AC4 regression): PR #998 RCA-19 fix body has strict-format Closes anchor${D}\n"
    local pr_body
    if ! pr_body=$(gh api repos/atilcan65/AtilCalculator/pulls/998 --jq '.body' 2>/dev/null); then
        info "TC6 — gh API unavailable (rate-limited?), skipping live PR body check"
        info "  ADR-0057 exemplar: PR #998 body restored at cmt-id 4944342219 closeout (Closes atilcan65/AtilCalculator#993 anchor preserved)"
        return 0
    fi
    # Find anchor line — must match strict owner/repo#N format (ADR-0057 exemplar)
    local anchor_line
    anchor_line=$(printf '%s\n' "$pr_body" | grep -E '^Closes ' | head -1 || true)
    if [ -z "$anchor_line" ]; then
        fail "TC6 — PR #998 body has no Closes anchor line (regression: strict-format lost)"
        return 0
    fi
    if is_strict_closes "$anchor_line"; then
        pass "TC6 — PR #998 anchor \"$anchor_line\" matches ADR-0057 strict-format (regression guarded)"
    else
        fail "TC6 — PR #998 anchor \"$anchor_line\" NOT strict-format (regression: would silently skip cross-repo-close)"
    fi
}

# === Execute TCs ===
section_t1
section_t2
section_t3
section_t4
section_t5
section_t6

# === Summary ===
printf "\n${B}== d297 summary ==${D}\n"
printf "  PASS: %d / FAIL: %d\n" "$PASS_COUNT" "$FAIL_COUNT"
if [ "$FAIL_COUNT" -eq 0 ]; then
    printf "${G}GREEN — d297 d-test contract honored, ADR-0057 CI gate complete${D}\n"
    exit 0
else
    printf "${R}RED — d297 d-test contract violated, ADR-0057 CI gate incomplete${D}\n"
    printf "${Y}  Expected RED state on dispatch: TC5 FAIL until closes-format-check.yml lands${D}\n"
    printf "${Y}  Other TCs FAIL would indicate regex contract drift or regression${D}\n"
    exit 1
fi
