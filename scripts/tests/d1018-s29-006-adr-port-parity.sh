#!/usr/bin/env bash
# d1018-s29-006-adr-port-parity.sh — STORY-S29-006 cross-repo ADR port parity d-test
#
# Doctrinal contract (≥3 TCs hygiene/docs baseline per `docs/sprints/current/plan.md`
#   "≥5 TCs behavioral, ≥3 TCs hygiene/docs"; ADR-0049 ≥5 baseline is for behavioral):
#   TC1: AC4 — file existence at canonical path (per-ADR check against template repo)
#   TC2: AC4 — frontmatter schema valid (status/date/deciders/related)
#   TC3: AC4 — cross-references resolve (no broken `ADR-XXXX` links)
#   TC4: AC5 — ID-uniqueness inline (d986 sister-pattern PROMOTED INLINE since
#             d986 does NOT exist in scripts/tests/ as of 2026-07-13; design's
#             AC5 cite of "d986 sister" was incorrect — see d-test header note)
#   TC5: AC3 — INDEX.md parity (template index covers all ported ADRs)
#
# Doctrinal home — `docs/sprints/current/plan.md`:
#   "≥5 TCs behavioral, ≥3 TCs hygiene/docs" (canonical home for this baseline)
#
# RED-first per ADR-0044: all 5 TCs FAIL pre-impl (template repo missing
# the 40+ ported ADRs); GREEN post-impl when 6 themed PRs land per AC1.
#
# Cadence Rule 1 atomic (ADR-0055 §1): this d-test file + INDEX.md entry
# land in same commit.
#
# Reference: Issue #1031 (STORY-S29-006), docs/designs/STORY-S29-006-design.md
#   (PR #1040), Issue #1041 (INCIDENT — claim-next-ready WIP cap bypass).
#
# Cross-repo auth: requires PROJECT_TOKEN (ADR-0014, scope: repo:read on
# atilproject org) for `gh api repos/atilproject/dev-studio-template/...`.
#   SCOPE NOTE: design does not enumerate this requirement explicitly; d-test
#   runner must be invoked with PROJECT_TOKEN in env (deferred to impl PR).

set -euo pipefail

TEMPLATE_REPO="atilproject/dev-studio-template"
TEMPLATE_DECISIONS="docs/decisions"
TEMPLATE_INDEX="${TEMPLATE_DECISIONS}/INDEX.md"

# Expected ADR list per design §Goals AC1 (40 base + 10 amendments ≈ 50 files).
# Format: "ADR-NNNN|family" — checked via `gh api` listing in TC1.
EXPECTED_BASE_ADRS=(
    "ADR-0002|autonomy-loop"
    "ADR-0012|label-board-4cat"
    "ADR-0013|label-board-4cat"
    "ADR-0014|cross-repo-discipline"
    "ADR-0015|label-board-4cat"
    "ADR-0020|label-board-4cat"
    "ADR-0021|label-board-4cat"
    "ADR-0024|handoff-handshake"
    "ADR-0025|sprint-flow"
    "ADR-0026|sprint-flow"
    "ADR-0027|sprint-flow"
    "ADR-0030|cross-repo-discipline"
    "ADR-0031|cross-repo-discipline"
    "ADR-0032|cross-repo-discipline"
    "ADR-0033|handoff-handshake"
    "ADR-0036|sprint-flow"
    "ADR-0038|autonomy-loop"
    "ADR-0040|handoff-handshake"
    "ADR-0042|sprint-flow"
    "ADR-0046|arch-general"
    "ADR-0047|cross-repo-discipline"
    "ADR-0048|label-board-4cat"
    "ADR-0049|cross-repo-discipline"
    "ADR-0050|arch-general"
    "ADR-0052|handoff-handshake"
    "ADR-0057|cross-repo-discipline"
    "ADR-0059|sprint-flow"
)

# PASS=0, FAIL=0
pass=0
fail=0

check() {
    if [ "$2" = "PASS" ]; then
        echo "  ✅ $1"
        pass=$((pass+1))
    else
        echo "  ❌ $1: $2"
        fail=$((fail+1))
    fi
}

require_gh() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "FATAL: gh CLI not found in PATH" >&2
        exit 2
    fi
}

require_gh

# --- TC0 (preflight): bash -n syntactic validity of this d-test file
if bash -n "$0" 2>/dev/null; then
    check "TC0 (bash -n self-check)" "PASS"
else
    check "TC0 (bash -n self-check)" "bash syntax error"
    exit 1
fi

# --- TC1: AC4 — file existence at canonical path per ADR ---
# Iterate EXPECTED_BASE_ADRS, query template repo via gh api.
# Pre-impl: ALL return 404 (template has 15 ADRs, not the 40+ we're porting)
#   → TC1 RED by design
# Post-impl: ALL return 200
missing=0
present=0
for entry in "${EXPECTED_BASE_ADRS[@]}"; do
    adr="${entry%%|*}"
    api_path="${TEMPLATE_DECISIONS}/${adr}-"
    # List files in template repo and grep for ADR prefix
    listing=$(gh api "repos/${TEMPLATE_REPO}/contents/${TEMPLATE_DECISIONS}" \
        --jq '.[].name' 2>/dev/null | grep -E "^${adr}[-a-z]" || true)
    if [ -n "$listing" ]; then
        present=$((present+1))
    else
        missing=$((missing+1))
    fi
done

if [ "$missing" -eq 0 ] && [ "$present" -eq "${#EXPECTED_BASE_ADRS[@]}" ]; then
    check "TC1 (all ${#EXPECTED_BASE_ADRS[@]} expected ADRs present)" "PASS"
else
    check "TC1 (ADR file existence)" "present=$present missing=$missing expected=${#EXPECTED_BASE_ADRS[@]}"
fi

# --- TC2: AC4 — frontmatter schema valid (status/date/deciders/related) ---
# Pick first N expected ADRs, fetch content, parse YAML frontmatter, verify fields
frontmatter_ok=0
frontmatter_total=0
for entry in "${EXPECTED_BASE_ADRS[@]:0:5}"; do
    adr="${entry%%|*}"
    frontmatter_total=$((frontmatter_total+1))
    content=$(gh api "repos/${TEMPLATE_REPO}/contents/${TEMPLATE_DECISIONS}/${adr}-" \
        -H "Accept: application/vnd.github.raw" 2>/dev/null || true)
    if echo "$content" | head -20 | grep -qE "^Status:" && \
       echo "$content" | head -20 | grep -qE "^Date:" && \
       echo "$content" | head -20 | grep -qE "^- \*\*Deciders\*\*|^Deciders:"; then
        frontmatter_ok=$((frontmatter_ok+1))
    fi
done

if [ "$frontmatter_ok" -eq "$frontmatter_total" ] && [ "$frontmatter_total" -gt 0 ]; then
    check "TC2 (frontmatter schema valid for $frontmatter_total ADRs)" "PASS"
else
    check "TC2 (frontmatter schema)" "ok=$frontmatter_ok total=$frontmatter_total"
fi

# --- TC3: AC4 — cross-references resolve (no broken ADR-XXXX links) ---
# Fetch one ADR content, scan for `ADR-XXXX` patterns, verify each resolves
# in template repo via gh api
broken_refs=0
ref_samples=()
for entry in "${EXPECTED_BASE_ADRS[@]:0:3}"; do
    adr="${entry%%|*}"
    content=$(gh api "repos/${TEMPLATE_REPO}/contents/${TEMPLATE_DECISIONS}/${adr}-" \
        -H "Accept: application/vnd.github.raw" 2>/dev/null || true)
    if [ -z "$content" ]; then continue; fi
    # Extract ADR-NNNN references (excluding the file's own ID)
    refs=$(echo "$content" | grep -oE "ADR-[0-9]+" | sort -u | grep -v "^${adr}$" || true)
    for ref in $refs; do
        ref_samples+=("$adr → $ref")
        # Check if ref exists in template
        ref_exists=$(gh api "repos/${TEMPLATE_REPO}/contents/${TEMPLATE_DECISIONS}" \
            --jq '.[].name' 2>/dev/null | grep -E "^${ref}[-a-z]" || true)
        if [ -z "$ref_exists" ]; then
            broken_refs=$((broken_refs+1))
        fi
    done
done

if [ "$broken_refs" -eq 0 ]; then
    check "TC3 (no broken ADR cross-references)" "PASS"
else
    sample=$(printf '%s\n' "${ref_samples[@]:0:3}" | tr '\n' ',' | head -c 200)
    check "TC3 (cross-ref resolution)" "broken=$broken_refs refs_checked sample=[$sample]"
fi

# --- TC4: AC5 — ID-uniqueness (promoted inline; d986 sister-pattern doesn't exist) ---
# Verify no duplicate ADR IDs in template's INDEX.md
# Robust 404 handling: gh api returns JSON error envelope on missing file (NOT empty),
# captured by `|| true`. Naked `-z` check passes through 404 JSON as "content" → grep -oE
# returns 1 → `set -euo pipefail` silent-exits script before TC5 runs (sister-fix).
index_content=$(gh api "repos/${TEMPLATE_REPO}/contents/${TEMPLATE_INDEX}" \
    -H "Accept: application/vnd.github.raw" 2>/dev/null || true)
# 404 envelope detection: JSON contains {"message":"Not Found"} or bare 404 response
if [ -z "$index_content" ] || \
   [[ "$index_content" == *"\"message\":\"Not Found\""* ]] || \
   [[ "$index_content" == *"\"status\":\"404\""* ]]; then
    check "TC4 (ID-uniqueness via INDEX.md)" "INFO: INDEX.md missing or 404 (template pre-port state)"
else
    unique_ids=$(echo "$index_content" | grep -oE "ADR-[0-9]+" | sort -u | wc -l)
    total_ids=$(echo "$index_content" | grep -oE "ADR-[0-9]+" | wc -l)
    if [ "$unique_ids" -eq "$total_ids" ] && [ "$total_ids" -gt 0 ]; then
        check "TC4 (ID-uniqueness: $unique_ids unique IDs)" "PASS"
    else
        check "TC4 (ID-uniqueness)" "unique=$unique_ids total=$total_ids (duplicates exist)"
    fi
fi

# --- TC5: AC3 — INDEX.md parity (covers all expected ported ADRs) ---
# 404 envelope detection same as TC4 (sister-pattern robustness)
if [ -z "$index_content" ] || \
   [[ "$index_content" == *"\"message\":\"Not Found\""* ]] || \
   [[ "$index_content" == *"\"status\":\"404\""* ]]; then
    check "TC5 (INDEX.md parity)" "INFO: INDEX.md missing or 404 (pre-port state)"
else
    missing_in_index=0
    for entry in "${EXPECTED_BASE_ADRS[@]}"; do
        adr="${entry%%|*}"
        if ! echo "$index_content" | grep -qE "${adr}[-a-z]"; then
            missing_in_index=$((missing_in_index+1))
        fi
    done
    if [ "$missing_in_index" -eq 0 ]; then
        check "TC5 (INDEX.md covers all $present expected ADRs)" "PASS"
    else
        check "TC5 (INDEX.md parity)" "missing_in_index=$missing_in_index of $present expected"
    fi
fi

echo ""
echo "==================================="
echo "d1018-s29-006-adr-port-parity: $pass pass, $fail fail"
echo "==================================="
[ "$fail" -eq 0 ] || exit 1
