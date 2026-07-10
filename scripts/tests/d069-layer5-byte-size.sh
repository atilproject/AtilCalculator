#!/usr/bin/env bash
# d069-layer5-byte-size.sh — TD-069 byte-size regression guard
# Per ADR-0055 §1 (Cadence Rule 1 atomic) + ADR-0049 (≥5 TCs baseline)
# Sister-pattern: d069 (verdict-gate structural regression), d095 (post-org-migration clone URL)
# Doctrinal home: Issue #950 (TD-069 systemic bug)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/label-check.yml"
GHA_EXPRESSION_LIMIT=21000

# TC_RESULTS array for per-TC marker emission (ADR-0049 §Per-TC marker pattern)
TC_RESULTS=()

pass_tc() { TC_RESULTS+=("PASS:$1:$2"); echo "  ✓ PASS — $1 — $2"; }
fail_tc() { TC_RESULTS+=("FAIL:$1:$2"); echo "  ✗ FAIL — $1 — $2"; }

# YAML parse + verify script body byte sizes
parse_script_bodies() {
    python3 -c "
import yaml, sys
doc = yaml.safe_load(open('${WORKFLOW_FILE}'))
job = doc['jobs']['label-check']
for step in job['steps']:
    name = step.get('name', '?')
    script = step.get('with', {}).get('script', '')
    if script:
        print(f'{name}\t{len(script.encode(\"utf-8\"))}')
"
}

echo "[d069-byte-size] starting — TD-069 byte-size regression guard"
echo "[d069-byte-size] REPO_ROOT=${REPO_ROOT}"
echo "[d069-byte-size] WORKFLOW_FILE=${WORKFLOW_FILE}"
echo

# --- TC1: Layer 5 step count check (must be ≥2: 5a + 5b) ---
L5_COUNT=$(grep -cE "^      - name: Layer 5(a|b) " "${WORKFLOW_FILE}" || echo 0)
if [[ "${L5_COUNT}" -ge 2 ]]; then
    pass_tc "TC1" "Layer 5 split landed (${L5_COUNT} sub-steps found, expect ≥2)"
else
    fail_tc "TC1" "Layer 5 NOT split — only ${L5_COUNT} Layer 5 sub-step(s) found"
fi

# --- TC2: Layer 5a script body < 21K (the systemic bug guard) ---
L5A_BYTES=$(parse_script_bodies | grep -E "Layer 5a" | awk -F'\t' '{print $2}')
if [[ -z "${L5A_BYTES}" ]]; then
    fail_tc "TC2" "Layer 5a script body NOT FOUND in workflow"
elif [[ "${L5A_BYTES}" -lt "${GHA_EXPRESSION_LIMIT}" ]]; then
    pass_tc "TC2" "Layer 5a script body = ${L5A_BYTES} bytes (limit ${GHA_EXPRESSION_LIMIT})"
else
    fail_tc "TC2" "Layer 5a script body = ${L5A_BYTES} bytes EXCEEDS ${GHA_EXPRESSION_LIMIT} limit"
fi

# --- TC3: Layer 5b script body < 21K ---
L5B_BYTES=$(parse_script_bodies | grep -E "Layer 5b" | awk -F'\t' '{print $2}')
if [[ -z "${L5B_BYTES}" ]]; then
    fail_tc "TC3" "Layer 5b script body NOT FOUND in workflow"
elif [[ "${L5B_BYTES}" -lt "${GHA_EXPRESSION_LIMIT}" ]]; then
    pass_tc "TC3" "Layer 5b script body = ${L5B_BYTES} bytes (limit ${GHA_EXPRESSION_LIMIT})"
else
    fail_tc "TC3" "Layer 5b script body = ${L5B_BYTES} bytes EXCEEDS ${GHA_EXPRESSION_LIMIT} limit"
fi

# --- TC4: Monolithic Layer 5 step REMOVED (the split must eliminate the original) ---
MONO_COUNT=$( (grep -cE "^      - name: Layer 5 — status:ready auto-add gating" "${WORKFLOW_FILE}" 2>/dev/null || true) | head -1 )
MONO_COUNT="${MONO_COUNT:-0}"
if [[ "${MONO_COUNT}" -eq 0 ]]; then
    pass_tc "TC4" "monolithic Layer 5 step REMOVED (split landed)"
else
    fail_tc "TC4" "monolithic Layer 5 step still present (count=${MONO_COUNT})"
fi

# --- TC5: SHA-pin preservation (lens h, ADR-0027) ---
SHA_PIN_COUNT=$(grep -c "f28e40c7f34bde8b3046d885e986cb6290c5673b" "${WORKFLOW_FILE}" || echo 0)
if [[ "${SHA_PIN_COUNT}" -ge 2 ]]; then
    pass_tc "TC5" "actions/github-script SHA-pin preserved (${SHA_PIN_COUNT} occurrences, expect ≥2: 5a + 5b)"
else
    fail_tc "TC5" "actions/github-script SHA-pin count = ${SHA_PIN_COUNT} (expect ≥2: 5a + 5b)"
fi

# --- TC6: 5a→5b output propagation (per TD-029 sister-pattern) ---
SET_OUTPUT_COUNT=$(grep -cE "core\.setOutput" "${WORKFLOW_FILE}" || echo 0)
OUTPUT_REF_COUNT=$(grep -cE "steps\.layer5a\.outputs\." "${WORKFLOW_FILE}" || echo 0)
if [[ "${SET_OUTPUT_COUNT}" -ge 7 ]] && [[ "${OUTPUT_REF_COUNT}" -ge 7 ]]; then
    pass_tc "TC6" "5a→5b output propagation: ${SET_OUTPUT_COUNT} setOutput + ${OUTPUT_REF_COUNT} steps.layer5a.outputs.* references"
else
    fail_tc "TC6" "5a→5b output propagation thin: setOutput=${SET_OUTPUT_COUNT} refs=${OUTPUT_REF_COUNT} (expect ≥7 each)"
fi

# --- TC7: Concurrency group preserved (L44-47 per design) ---
CONCURRENCY_OK=1
if ! grep -q "concurrency:" "${WORKFLOW_FILE}"; then
    CONCURRENCY_OK=0
fi
if [[ "${CONCURRENCY_OK}" -eq 1 ]]; then
    pass_tc "TC7" "workflow-level concurrency group preserved"
else
    fail_tc "TC7" "workflow-level concurrency group NOT found"
fi

# --- TC8: Audit-trail marker comments preserved (4 markers per design) ---
MARKER_COUNT=$(grep -cE "<!-- adr-0012-status-ready-gating(-skip|-reversal|-draft-skip)? -->" "${WORKFLOW_FILE}" || echo 0)
if [[ "${MARKER_COUNT}" -ge 4 ]]; then
    pass_tc "TC8" "audit-trail marker comments preserved (${MARKER_COUNT} occurrences, expect ≥4)"
else
    fail_tc "TC8" "audit-trail marker count = ${MARKER_COUNT} (expect ≥4)"
fi

# --- TC9: silent_skip log line count (≥4 per design: closed-state, bot-actor, status-removal, draft-pr, layer-5-skip) ---
SILENT_COUNT=$(grep -cE "silent_skip event=" "${WORKFLOW_FILE}" || echo 0)
if [[ "${SILENT_COUNT}" -ge 4 ]]; then
    pass_tc "TC9" "silent_skip log events preserved (${SILENT_COUNT} occurrences, expect ≥4)"
else
    fail_tc "TC9" "silent_skip log count = ${SILENT_COUNT} (expect ≥4)"
fi

# --- TC10: d-test --self-test flag (sister-pattern d649 discipline) ---
if [[ "${1:-}" == "--self-test" ]]; then
    SELF_TEST_OK=1
    for entry in "${TC_RESULTS[@]}"; do
        [[ "${entry}" == PASS:* ]] || SELF_TEST_OK=0
    done
    if [[ "${SELF_TEST_OK}" -eq 1 ]]; then
        echo
        echo "[d069-byte-size] SELF-TEST PASS — all TCs PASS in --self-test mode"
        exit 0
    else
        echo
        echo "[d069-byte-size] SELF-TEST FAIL — at least one TC FAILed in --self-test mode"
        exit 1
    fi
fi

echo
echo "[d069-byte-size] Results: ${#TC_RESULTS[@]} TCs, $(echo "${TC_RESULTS[@]}" | grep -o FAIL | wc -l) FAIL"
for entry in "${TC_RESULTS[@]}"; do
    echo "[d069-byte-size]   ${entry}"
done
PASS_COUNT=$(echo "${TC_RESULTS[@]}" | grep -o PASS | wc -l)
FAIL_COUNT=$(echo "${TC_RESULTS[@]}" | grep -o FAIL | wc -l)
echo
if [[ "${FAIL_COUNT}" -eq 0 ]]; then
    echo "[d069-byte-size] VERDICT: ✅ ALL GREEN (TD-069 byte-size limit CLOSED, both 5a+5b under 21K)"
    exit 0
else
    echo "[d069-byte-size] VERDICT: ❌ FAIL — TD-069 byte-size regression NOT fixed"
    exit 1
fi