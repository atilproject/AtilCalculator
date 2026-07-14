#!/usr/bin/env bash
# d1020-s29-010-workflow-port-parity.sh — S29-010 workflow port-parity cross-repo d-test
#
# Doctrinal contract (≥3 TCs hygiene/docs baseline per `docs/sprints/current/plan.md`
#   "≥5 TCs behavioral, ≥3 TCs hygiene/docs" — sister-pattern to d1018):
#   TC0: bash -n syntactic self-check (preflight, sister-pattern d1018)
#   TC1: AC4 — yaml-syntax per workflow (4 sub-checks; python3+pyyaml parse)
#   TC2: AC3 + AC4 — 4-tuple-presence per workflow (4 sub-checks;
#                     design §Data model canonical: `runs-on: [self-hosted, Linux, X64, atilproject]`)
#   TC3: AC4 — SHA-pin-presence per workflow (4 sub-checks;
#                    TD-028 generalized via R-3 mitigation: every `uses: actions/<name>@<ref>`
#                    MUST use a 40-char SHA, not moving tag `@v4` / `@main` / `@latest`)
#   TC4: AC4 — env.PROJECT_NAME parameterization per workflow (4 sub-checks;
#                    arch verdict on Issue #1050 Option B: post-squash.yml has R-1
#                    parameterization (`env.PROJECT_NAME` derived from
#                    `github.event.repository.name`); other 3 workflows are verbatim
#                    ports WITHOUT parameterization → vacuously pass.
#                    Sub-check 1: PROJECT_NAME block present + derived from GitHub
#                      context (github.event.repository.name | github.repository |
#                      github.repository_owner)
#                    Sub-check 2: PROJECT_NAME referenced at least once via
#                      `${{ env.PROJECT_NAME }}`
#                    Vacuous (3/4 sub-checks for d050b-dispatch, lint-and-test, deploy.yml).)
#
# Scope (4 workflows per design AC1 forward-port + AC2 render, Issue #1035):
#   - d050b-dispatch.yml (port, Issue #440 / ADR-0049 d050b runtime validator)
#   - lint-and-test.yml  (port, Issue #508 + #611 / ADR-0059 CI integration)
#   - post-squash.yml    (port, Issue #605 / ADR-0059 cluster-lag detector)
#   - deploy.yml         (render from deploy.yml.tmpl per OWNER APPROVAL — AC2)
#
# RED-first per ADR-0044: all 12 sub-checks FAIL pre-impl (template has 8 workflows,
#   missing all 4 in scope). GREEN post-impl when 4 themed impl PRs land per AC1+AC2.
#
# Cadence Rule 1 atomic (ADR-0055 §1): this d-test file + INDEX.md entry
# land in same commit.
#
# Cross-repo auth: requires PROJECT_TOKEN (ADR-0014, scope: repo:read on
#   atilproject org) for `gh api repos/atilproject/dev-studio-template/...`.
#   SCOPE NOTE: design does not enumerate this requirement explicitly; d-test
#   runner must be invoked with PROJECT_TOKEN in env (deferred to impl PR).
#   Sister-pattern cite: d1018 line 26-29 (same PROJECT_TOKEN envelope).
#
# Reference: Issue #1035 (STORY-S29-010), docs/designs/STORY-S29-010-design.md
#   (PR #1047, ✅ squash-merged 2026-07-13T19:58:36Z, commit d0cf929).

set -euo pipefail

TEMPLATE_REPO="atilproject/dev-studio-template"
WORKFLOWS_DIR=".github/workflows"

# 4 workflows in scope (design AC1+AC2). Sister-pattern to d1018 EXPECTED_BASE_ADRS array.
EXPECTED_WORKFLOWS=(
    "d050b-dispatch.yml"
    "lint-and-test.yml"
    "post-squash.yml"
    "deploy.yml"
)

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

# Sister-pattern to d1018 fetch helper: fetches workflow content from template
# repo via gh api, robust to 404 envelope (NOT empty — gh returns JSON envelope).
fetch_workflow() {
    local wf="$1"
    local content
    content=$(gh api "repos/${TEMPLATE_REPO}/contents/${WORKFLOWS_DIR}/${wf}" \
        -H "Accept: application/vnd.github.raw" 2>/dev/null || true)
    # 404 envelope detection (sister-pattern to d1018 TC4/TC5)
    if [ -z "$content" ] || \
       [[ "$content" == *"\"message\":\"Not Found\""* ]] || \
       [[ "$content" == *"\"status\":\"404\""* ]]; then
        return 1
    fi
    printf '%s' "$content"
    return 0
}

require_gh

# --- TC0 (preflight): bash -n syntactic validity of this d-test file
if bash -n "$0" 2>/dev/null; then
    check "TC0 (bash -n self-check)" "PASS"
else
    check "TC0 (bash -n self-check)" "bash syntax error"
    exit 1
fi

# --- TC1: AC4 — yaml-syntax per workflow (4 sub-checks) ---
# python3 + pyyaml parse check. Pre-impl: 0/4 (all 4 missing). Post-impl: 4/4.
yaml_ok=0
yaml_total=0
for wf in "${EXPECTED_WORKFLOWS[@]}"; do
    yaml_total=$((yaml_total+1))
    if ! content=$(fetch_workflow "$wf"); then
        continue  # 404 or empty → stays not-ok
    fi
    # python3+pyyaml.safe_load_all parses multi-doc YAML (workflows may have
    # multiple YAML docs separated by ---). Single-doc also works.
    if printf '%s\n' "$content" | python3 -c "
import sys, yaml
docs = list(yaml.safe_load_all(sys.stdin))
# Each doc must be non-None (None = empty doc, OK for templates), or a dict
for d in docs:
    if d is not None and not isinstance(d, dict):
        sys.exit(1)
" 2>/dev/null; then
        yaml_ok=$((yaml_ok+1))
    fi
done

if [ "$yaml_ok" -eq "$yaml_total" ] && [ "$yaml_total" -gt 0 ]; then
    check "TC1 (yaml-syntax for $yaml_total workflows)" "PASS"
else
    check "TC1 (yaml-syntax)" "ok=$yaml_ok total=$yaml_total (pre-impl: missing = not-ok)"
fi

# --- TC2: AC3 + AC4 — 4-tuple-presence per workflow (4 sub-checks) ---
# Canonical 4-tuple per S29-001 baseline (PR #73 squash-merged 2026-07-13T14:20:32Z):
#   runs-on: [self-hosted, Linux, X64, atilproject]
# Pre-impl: 0/4 (4 missing). Post-impl: 4/4.
four_tuple='runs-on: [self-hosted, Linux, X64, atilproject]'
tuple_ok=0
tuple_total=0
for wf in "${EXPECTED_WORKFLOWS[@]}"; do
    tuple_total=$((tuple_total+1))
    if ! content=$(fetch_workflow "$wf"); then
        continue
    fi
    # grep -F (literal) — bracketed list is exact match (no regex metas active)
    if printf '%s\n' "$content" | grep -qF "$four_tuple"; then
        tuple_ok=$((tuple_ok+1))
    fi
done

if [ "$tuple_ok" -eq "$tuple_total" ] && [ "$tuple_total" -gt 0 ]; then
    check "TC2 (4-tuple present in $tuple_total workflows)" "PASS"
else
    check "TC2 (4-tuple-presence)" "ok=$tuple_ok total=$tuple_total"
fi

# --- TC3: AC4 — SHA-pin-presence per workflow (4 sub-checks, TD-028) ---
# Every `uses: <action>@<ref>` line where <action> is actions/* or
# atilproject/* (custom actions) MUST use a 40-char SHA, NOT moving tag.
# docker://... refs and local ./path refs are NOT SHA-pinnable (TD-028 scope
# = actions/* only); they are excluded from the SHA-pin requirement.
#
# Algorithm:
#   1. Extract all lines matching `^\s*uses:` (with optional comment tail).
#   2. Filter to lines whose action prefix is in the SHA-pin-scope set.
#   3. Each remaining line MUST have `@[0-9a-f]{40}` (40-char SHA).
#
# Pre-impl: 0/4 (all 4 missing). Post-impl: 4/4.
sha_ok=0
sha_total=0
for wf in "${EXPECTED_WORKFLOWS[@]}"; do
    sha_total=$((sha_total+1))
    if ! content=$(fetch_workflow "$wf"); then
        continue
    fi
    # Extract uses: lines; ignore comment-only lines (pure whitespace + #).
    uses_lines=$(printf '%s\n' "$content" | grep -E '^\s*uses:' || true)
    if [ -z "$uses_lines" ]; then
        # No uses: at all (e.g. dispatch-only workflow) → vacuously SHA-ok.
        sha_ok=$((sha_ok+1))
        continue
    fi
    # Filter to SHA-pin-scope uses: only those starting with actions/ or
    # atilproject/ (custom org actions). docker://, ./local, etc. excluded.
    pinable=$(printf '%s\n' "$uses_lines" | \
        grep -E 'uses:\s*(actions|atilproject|atilcan)/' || true)
    if [ -z "$pinable" ]; then
        # No SHA-pin-scope uses → vacuously ok.
        sha_ok=$((sha_ok+1))
        continue
    fi
    # Every pinable line MUST have @<40-char-hex> (anchored at end of ref,
    # allowing trailing whitespace + comment).
    bad=$(printf '%s\n' "$pinable" | \
        grep -vE '@[0-9a-f]{40}([[:space:]]|$)' || true)
    if [ -z "$bad" ]; then
        sha_ok=$((sha_ok+1))
    fi
done

if [ "$sha_ok" -eq "$sha_total" ] && [ "$sha_total" -gt 0 ]; then
    check "TC3 (SHA-pin in $sha_total workflows)" "PASS"
else
    check "TC3 (SHA-pin)" "ok=$sha_ok total=$sha_total (TD-028: actions/* must use 40-char SHA)"
fi

# --- TC4: AC4 — env.PROJECT_NAME parameterization per workflow (4 sub-checks) ---
# Per arch verdict on Issue #1050 Option B, post-squash.yml has R-1
# parameterization (env.PROJECT_NAME derived from github.event.repository.name).
# Other 3 workflows are verbatim ports WITHOUT parameterization → vacuously pass.
#
# For each workflow:
#   - If `PROJECT_NAME: ${{ ... }}` line exists in env: block:
#     1. PROJECT_NAME value must derive from GitHub context
#        (github.event.repository.name | github.repository | github.repository_owner)
#     2. PROJECT_NAME must be referenced at least once via `${{ env.PROJECT_NAME }}`
#   - Else: vacuously pass (verbatim port, no R-1 expected)
#
# Pre-impl: 0/4 (all 4 missing). Post-impl: 4/4 (1 active for post-squash.yml
# + 3 vacuous for the other 3 verbatim ports).
param_ok=0
param_total=0
for wf in "${EXPECTED_WORKFLOWS[@]}"; do
    param_total=$((param_total+1))
    if ! content=$(fetch_workflow "$wf"); then
        continue
    fi
    # Check if PROJECT_NAME block exists in env (any indentation)
    if ! printf '%s\n' "$content" | grep -qE '^\s*PROJECT_NAME[[:space:]]*:[[:space:]]*\$\{\{'; then
        # No PROJECT_NAME in env block → vacuously pass (verbatim port, no R-1)
        param_ok=$((param_ok+1))
        continue
    fi
    # PROJECT_NAME present → verify derivation from GitHub context
    # Allowed: github.event.repository.name | github.repository | github.repository_owner
    if ! printf '%s\n' "$content" | grep -E '^\s*PROJECT_NAME[[:space:]]*:[[:space:]]*\$\{\{' | \
        grep -qE 'github\.(event\.repository\.name|repository|repository_owner)'; then
        continue
    fi
    # Verify PROJECT_NAME is referenced at least once via ${{ env.PROJECT_NAME }}
    if ! printf '%s\n' "$content" | grep -qE '\$\{\{[[:space:]]*env\.PROJECT_NAME[[:space:]]*\}\}'; then
        continue
    fi
    param_ok=$((param_ok+1))
done

if [ "$param_ok" -eq "$param_total" ] && [ "$param_total" -gt 0 ]; then
    check "TC4 (env.PROJECT_NAME parameterization in $param_total workflows)" "PASS"
else
    check "TC4 (parameterization)" "ok=$param_ok total=$param_total (arch verdict #1050 Option B: PROJECT_NAME from github.context + referenced via env.PROJECT_NAME)"
fi

echo ""
echo "==================================="
echo "d1020-s29-010-workflow-port-parity: $pass pass, $fail fail"
echo "==================================="
[ "$fail" -eq 0 ] || exit 1
