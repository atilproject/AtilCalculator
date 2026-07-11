#!/usr/bin/env bash
# dXXX-gh-api-endpoint-hygiene.sh — Issue #999 gh api POST /pulls/N footgun guardrail
#   Sister-d-test to d123 (RCA-12 d-test) + d056 (dual-channel enforcement) per ADR-0049.
#   ≥7 TCs RED-first per ADR-0049 §Sister-pattern baseline ≥3 met.
#
# Why this test exists
# --------------------
# Issue #999 LIVE INSTANCE (cycle ~834): tester attempted to POST verdict text as comment
# on PR #998 RCA-19 fix using `gh api -X POST /repos/X/Y/pulls/N -f body=X`. GitHub's REST
# API treats /pulls/N as a PATCH endpoint even when called with `-X POST` verb. Result:
# PR body was OVERWRITTEN, losing original Closes anchors. Sister-guardrail:
# S28-015 closes-format-check CI gate (Issue #994) catches the SYMPTOM (lost Closes).
# This d-test catches the CAUSE (endpoint semantics confusion) by verifying that all
# 4 agent soul files document the correct POST endpoint pattern (/issues/N/comments,
# NOT /pulls/N).
#
# AC traceability:
#   - TC1 ↔ AC1 — architect.md has the POST /pulls/N footgun warning
#   - TC2 ↔ AC1 — developer.md sister amend present
#   - TC3 ↔ AC1 — tester.md sister amend present
#   - TC4 ↔ AC1 — orchestrator.md sister amend present
#   - TC5 ↔ AC2 — correct endpoint pattern (/issues/N/comments) documented in architect.md
#   - TC6 ↔ AC2 — root cause explanation (PATCH semantics) in architect.md
#   - TC7 ↔ AC3 — negative test: no misleading footgun-example patterns in architect.md
#
# Sister-pattern (≥3 per ADR-0049):
#   - d056 (Issue #296 dual-channel enforcement) — direct sister (CLI hygiene discipline)
#   - d123 (Issue #785 INCIDENT-2 RCA-12) — direct sister (script + test pair regression)
#   - d075 (CLAUDE.md.tmpl full doctrine, 7 TCs) — sister (soul file content verification)
#   - d096 (S21-006 soul files template coverage, 5 TCs) — sister (soul file template test)
#   ≥3 sister-pattern coverage per ADR-0049 met (d056 + d123 + d075 + d096 + this d-test = 5 sisters)
#
# Pre-impl RED state (Issue #999 OPEN):
#   - TC1-TC4 FAIL — no soul files currently contain "POST /pulls/N" warning (verified cycle #5854)
#   - TC5 FAIL — no soul file documents /issues/N/comments as correct endpoint pattern
#   - TC6 FAIL — no soul file explains PATCH semantics root cause
#   - TC7 PASS (negative test will pass even pre-impl since no misleading examples exist)
#
# Test infra pattern: grep-based content presence checks on soul files. Pure read-only,
# no API calls. Idempotent. Sister-pattern to d075 (CLAUDE.md.tmpl full doctrine content
# verification, 7 TCs).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOUL_DIR="${REPO_ROOT}/.claude/agents"

PASS_COUNT=0
FAIL_COUNT=0
TC_NUM=0

check() {
    local description="$1"
    local result="$2"  # 0 = pass, 1 = fail
    TC_NUM=$((TC_NUM + 1))
    if [[ "$result" -eq 0 ]]; then
        echo "✅ TC${TC_NUM} PASS: ${description}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "❌ TC${TC_NUM} FAIL: ${description}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ===== TC1: architect.md has the POST /pulls/N footgun warning =====
TC1_DESC="architect.md contains 'POST /pulls/N' footgun warning"
if grep -q "POST /pulls/N" "${SOUL_DIR}/architect.md"; then
    check "$TC1_DESC" 0
else
    check "$TC1_DESC" 1
fi

# ===== TC2: developer.md sister amend present =====
TC2_DESC="developer.md contains 'POST /pulls/N' sister amend"
if grep -q "POST /pulls/N" "${SOUL_DIR}/developer.md"; then
    check "$TC2_DESC" 0
else
    check "$TC2_DESC" 1
fi

# ===== TC3: tester.md sister amend present =====
TC3_DESC="tester.md contains 'POST /pulls/N' sister amend"
if grep -q "POST /pulls/N" "${SOUL_DIR}/tester.md"; then
    check "$TC3_DESC" 0
else
    check "$TC3_DESC" 1
fi

# ===== TC4: orchestrator.md sister amend present =====
TC4_DESC="orchestrator.md contains 'POST /pulls/N' sister amend"
if grep -q "POST /pulls/N" "${SOUL_DIR}/orchestrator.md"; then
    check "$TC4_DESC" 0
else
    check "$TC4_DESC" 1
fi

# ===== TC5: correct endpoint pattern documented in architect.md =====
TC5_DESC="architect.md documents '/issues/{N}/comments' as correct endpoint pattern"
if grep -q "issues/{N}/comments" "${SOUL_DIR}/architect.md"; then
    check "$TC5_DESC" 0
else
    check "$TC5_DESC" 1
fi

# ===== TC6: root cause explanation (PATCH semantics) in architect.md =====
TC6_DESC="architect.md explains 'PATCH semantics' root cause"
if grep -q "PATCH semantics" "${SOUL_DIR}/architect.md"; then
    check "$TC6_DESC" 0
else
    check "$TC6_DESC" 1
fi

# ===== TC7: negative test — no misleading footgun-pattern examples =====
# Should NOT have copy-pasteable footgun patterns that could mislead readers
TC7_DESC="architect.md has no copy-pasteable 'POST /pulls/{N} -f body' footgun examples"
if ! grep -qE "POST /pulls/\{?N\}? -f body" "${SOUL_DIR}/architect.md"; then
    check "$TC7_DESC" 0
else
    check "$TC7_DESC" 1
fi

# ===== Summary =====
echo ""
echo "=== dXXX-gh-api-endpoint-hygiene.sh summary ==="
echo "PASS: ${PASS_COUNT} / ${TC_NUM}"
echo "FAIL: ${FAIL_COUNT} / ${TC_NUM}"

# Exit code reflects failure count (0 = all pass, non-zero = some failed)
if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo ""
    echo "❌ Pre-impl RED state confirmed (expected): TC1-TC6 FAIL (no soul file has the hygiene bullet yet)"
    echo "   TC7 may PASS or FAIL depending on whether copy-pasteable footgun examples exist"
    echo "   Post-impl expected: all 7 TCs PASS"
    exit 1
else
    echo ""
    echo "✅ Post-impl GREEN: all 7 TCs pass — soul file hygiene discipline codified"
    exit 0
fi