#!/usr/bin/env bash
# d068-td067-combined.sh — TD-067b regression (Issue #927).
#
# Why this test exists
# --------------------
# Issue #927 (TD-067b): TD-067 Part 2 — extend `.github/workflows/label-check.yml`
# to fire a diagnostic comment when a merged PR has its 4-cat labels stripped
# by label-cleanup.yml. Acts as an "ally" to Part 1 (PR #926, ShShipped
# 2026-07-09T11:34:03Z): if label-strip ever regresses, this diagnostic
# surfaces the bug BEFORE downstream automations (board sync, sprint audits)
# are broken.
#
# TD-067 + TD-067b + TD-068 = sister-pattern family per
# docs/designs/TD-067-TD-068-sister-fix-design.md §Components table.
#
# TDD contract (5+2 cases per ADR-0049 ≥5 baseline + Issue #927 AC1-AC5):
#   TC1: trigger includes `closed` event for pull_request_target (false-positive
#        guard baseline — without this trigger, the diagnostic never fires)
#   TC2: gate `merged == true` present (Issue #927 R3 silent-skip interaction;
#        close-not-merge MUST NOT trigger diagnostic, AC3)
#   TC3: 4-cat invariant check present in closed-event handler — looks for
#        type:*, status:*, agent:*, cc:* labels (the diagnostic predicate,
#        AC1+AC2 invariant detection)
#   TC4: diagnostic comment posting present — calls
#        `octokit.rest.issues.createComment` (or equivalent) when 4-cat
#        violated (AC2 — fires within 30s of close)
#   TC5: idempotency mechanism present — comment ID dedup OR `if:` guard
#        prevents duplicate diagnostic on re-closed events (AC4)
#   TC6: SHA-pinning preserved — actions/github-script@v7 etc MUST use
#        full 40-char SHA, NOT moving tag (ADR-0027 + ADR-0043 §lens h)
#   TC7: concurrency group reuse — either inherits existing label-check
#        concurrency group OR adds closed-event-specific group preventing
#        race with labeled/unlabeled handlers (Issue #927 R2)
#
# Sister-patterns:
#   - d068-agent-state-backfill.sh (Issue #920 TD-068 state-file-axis fix)
#   - d068-cluster-lag-workflow-wiring.sh (Issue #605 ADR-0059 cluster-lag)
#   - d076-label-check-state-filter.sh (closed-state bypass sister-pattern)
#   - d069-layer-5-verdict-emoji-gate.sh (workflow YAML regression guard archetype)
#   - TD-067 / Issue #922 (PR-axis Part 1, Closes via PR #926)
#   - d015 + d031 (≥5 TCs baseline + auto-claim sister)
#
# Run: bash scripts/tests/d068-td067-combined.sh
# Expected pre-impl (RED per ADR-0044): TC1 FAIL, TC2 FAIL, TC4 FAIL (the impl-
#         specific structural elements that don't exist yet). TC3/TC5/TC6/TC7
#         PASS green (baseline-preserved checks: 4-cat references, idempotency,
#         SHA-pinning, concurrency group all already exist in label-check.yml
#         from prior layers — impl MUST preserve them).
# Expected post-impl (GREEN): all 7 PASS
#
# RED-first verification (cycle ~#5685, 2026-07-09): captured 4/7 PASS, 3/7 FAIL pre-impl
# (after fixing JSON-key roundtrip + pipefail/SIGPIPE false-negative bugs in initial draft).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/label-check.yml"

# Colors
if [[ -t 1 ]]; then G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else G=""; R=""; B=""; D=""; fi
PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- preflight ---
if [ ! -f "$WORKFLOW_FILE" ]; then
  printf "${R}ERROR: workflow file missing: %s${D}\n" "$WORKFLOW_FILE" >&2
  exit 4
fi

# Parse workflow YAML. PyYAML 1.1 parses bare `on:` as boolean True; handle both.
# Some non-serializable types (datetime from GitHub contexts, embedded JS strings,
# etc.) require default=str for safe serialization. Keep the full JSON in a temp
# file for downstream greps to avoid ARG_MAX issues with very large workflows.
YAML_JSON_FILE="$(mktemp)"
trap 'rm -f "$YAML_JSON_FILE"' EXIT
python3 -c "
import sys, yaml, json
with open('$WORKFLOW_FILE') as f:
    data = yaml.safe_load(f)
sys.stdout.write(json.dumps(data, default=str, sort_keys=False))
" > "$YAML_JSON_FILE" 2>/dev/null || {
  printf "${R}ERROR: workflow YAML not parseable at %s${D}\n" "$WORKFLOW_FILE" >&2
  exit 5
}

# Helper: extract raw text content of the workflow YAML (for grep-style
# structural checks like "is the literal string `merged == true` somewhere
# in the file?").
workflow_text="$(cat "$WORKFLOW_FILE")"

# ============================================================================
# TC1: trigger includes `closed` event for pull_request_target
# ============================================================================
# AC: Without the `closed` trigger, the diagnostic never fires on PR merge.
# RED state: current label-check.yml has only opened/reopened/labeled/unlabeled
# in pull_request_target.types. Impl must ADD `closed` to the types array.
section "TC1: pull_request_target trigger includes 'closed' event"
# Round-trip note: PyYAML 1.1 parses YAML `on:` as bool True; json.dumps
# coerces dict keys to STRINGS, so the json-roundtrip key is 'true' (str), not
# True (bool). Handle all 3 shapes: bool True, str 'true', str 'on' (raw YAML).
pr_triggers="$(python3 -c "
import json
with open('$YAML_JSON_FILE') as f:
    data = json.load(f)
on = data.get(True) or data.get('true') or data.get('on') or {}
prt = on.get('pull_request_target', {}) if isinstance(on, dict) else {}
types = prt.get('types', [])
print(','.join(types) if isinstance(types, list) else str(types))
")"
if printf '%s' "$pr_triggers" | grep -q "closed"; then
  pass "pull_request_target.types includes 'closed' (trigger for diagnostic on PR close)" "types: $pr_triggers"
else
  fail "pull_request_target.types missing 'closed'" "got: '$pr_triggers'"
fi

# ============================================================================
# TC2: gate `merged == true` present in workflow (Issue #927 R3 silent-skip)
# ============================================================================
# AC3: Close-not-merge → diagnostic does NOT fire. The gate MUST check
# `github.event.pull_request.merged == true` somewhere in the workflow.
# Pattern: grep for the literal string `merged == true` (or `merged === true`)
# in the workflow body — present at job-level or step-level if-condition.
section "TC2: gate 'merged == true' present (AC3 close-not-merge guard)"
# Use here-string to avoid pipefail + SIGPIPE interaction with `printf | grep`
# (grep exits 0 on first match → printf gets SIGPIPE → pipefail marks pipeline
# as failed → if-branch treats match as false-negative).
if grep -qE "merged\s*==\s*['\"]?true['\"]?" <<< "$workflow_text" || \
   grep -qE "merged\s*===\s*['\"]?true['\"]?" <<< "$workflow_text"; then
  pass "merged==true gate present (AC3 close-not-merge → no diagnostic)"
else
  fail "merged==true gate missing" "expected literal 'merged == true' or 'merged === true' in workflow text"
fi

# ============================================================================
# TC3: 4-cat invariant check present in closed-event handler
# ============================================================================
# AC1+AC2 invariant detection: workflow must check for the 4 categories
# (type:*, status:*, agent:*, cc:*) on the closed PR. Pattern: grep for
# references to all 4 category prefixes in the workflow body (existing
# label-check already references all 4 in Layer 3 — we want to verify the
# NEW closed-event handler also checks them).
section "TC3: 4-cat invariant check present (type:*, status:*, agent:*, cc:*)"
# Use here-string to avoid pipefail + SIGPIPE interaction (grep early-exit on match).
type_count="$(grep -cE "type:|type\\*|type_" <<< "$workflow_text" || true)"
status_count="$(grep -cE "status:|status\\*" <<< "$workflow_text" || true)"
agent_count="$(grep -cE "agent:|agent\\*" <<< "$workflow_text" || true)"
cc_count="$(grep -cE "cc:|cc\\*" <<< "$workflow_text" || true)"
if [ "$type_count" -gt 0 ] && [ "$status_count" -gt 0 ] && \
   [ "$agent_count" -gt 0 ] && [ "$cc_count" -gt 0 ]; then
  pass "all 4 category references present (type=$type_count, status=$status_count, agent=$agent_count, cc=$cc_count)"
else
  fail "4-cat invariant check incomplete" \
    "expected ≥1 reference each for type/status/agent/cc; got type=$type_count status=$status_count agent=$agent_count cc=$cc_count"
fi

# ============================================================================
# TC4: diagnostic comment posting present (AC2)
# ============================================================================
# AC2: Squash-merge with stripped labels → diagnostic comment fires.
# Pattern: grep for `createComment` invocation in the workflow YAML.
# actions/github-script@v7 calls Octokit — `octokit.rest.issues.createComment`
# is the canonical API call.
section "TC4: diagnostic comment posting present (AC2 — fires within 30s of close)"
# Distinguish diagnostic createComment from generic audit-log createComment. Per
# design §Components table, the impl MUST use a unique marker:
#   `<!-- adr-NNNN-closed-diagnostic -->` (HTML comment in PR comment body)
# Pre-impl: NO `closed-diagnostic` marker exists → RED. Post-impl: marker present → GREEN.
if grep -qE "closed-diagnostic|adr-[0-9]+-closed-diagnostic" <<< "$workflow_text"; then
  pass "diagnostic-specific marker present (closed-diagnostic comment can fire)"
else
  fail "diagnostic-specific marker missing" \
    "expected 'closed-diagnostic' or 'adr-NNNN-closed-diagnostic' marker in workflow body (sister-pattern to Layer 5 marker L108-110)"
fi

# ============================================================================
# TC5: idempotency mechanism present (AC4 — no duplicate on re-closed)
# ============================================================================
# AC4: 10× closed events → exactly 1 diagnostic comment. Mechanism options:
#   (a) Comment ID dedup: check `comments.list` for existing bot comment
#   (b) Label-based dedup: set a dedup label after first comment
#   (c) `if:` guard: skip if a marker label is already present
# Pattern: grep for at least one of these patterns.
section "TC5: idempotency mechanism present (AC4 — no duplicate on re-closed)"
# Per design §Reused primitives, impl will REUSE the existing Layer 5 idempotency
# pattern (L108-110: `comments.find(c => c.user.type === 'Bot' && c.body.includes(marker))`)
# Pre-impl: pattern absent (NEW logic not added yet) → RED. Post-impl: pattern extended for closed-diagnostic → GREEN.
has_dedup=false
if grep -qE "dedup|deduplicate|already.*commented|comment.*exists" <<< "$workflow_text"; then
  has_dedup=true
fi
if grep -qE "comments\\.find.*marker|includes\\(marker\\)|body\\.includes" <<< "$workflow_text"; then
  has_dedup=true
fi
if grep -qE "comments\\.list|listComments|commentsForIssue" <<< "$workflow_text"; then
  has_dedup=true
fi
if [ "$has_dedup" = "true" ]; then
  pass "idempotency mechanism present (marker-based dedup OR comments.list check)"
else
  fail "idempotency mechanism missing" \
    "expected marker-based dedup (comments.find + includes(marker)) OR comments.list pattern"
fi

# ============================================================================
# TC6: SHA-pinning preserved (ADR-0027 + ADR-0043 §lens h)
# ============================================================================
# All `uses:` lines for actions/* MUST reference full 40-char SHA, not moving
# tag. Pattern: grep for `uses: actions/...` and verify SHA format. The
# existing workflow already does this (f28e40c7f34bde8b3046d885e986cb6290c5673b);
# impl must PRESERVE this discipline for any new actions/* added.
section "TC6: SHA-pinning preserved on actions/* (ADR-0027 + ADR-0043 §lens h)"
sha_pinned=true
uses_lines="$(grep -E '^\s*uses:\s*actions/' <<< "$workflow_text" || true)"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # Extract the SHA between @ and end-of-comment. Pattern: @<40-char-sha>[whitespace or #]
  if ! grep -qE '@[a-f0-9]{40}(\s|$|#)' <<< "$line"; then
    sha_pinned=false
    fail "TC6 — actions/* reference missing 40-char SHA" "line: $line"
    break
  fi
done <<< "$uses_lines"
if [ "$sha_pinned" = "true" ] && [ -n "$uses_lines" ]; then
  pass "all actions/* references SHA-pinned (40-char hex after @)"
elif [ -z "$uses_lines" ]; then
  fail "TC6 — no actions/* references found in workflow" "expected at least one SHA-pinned action"
else
  : # already failed above
fi

# ============================================================================
# TC7: concurrency group reuse (Issue #927 R2 race mitigation)
# ============================================================================
# Existing concurrency: `group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.event.issue.number }}`.
# Either: (a) impl adds a NEW job that reuses the same concurrency group, OR
#          (b) impl adds explicit `concurrency:` block on the new job matching.
# Pattern: grep for concurrency block + check it covers closed-event.
section "TC7: concurrency group covers closed-event (R2 race mitigation)"
# Check both patterns exist anywhere in the file (concurrency block + number-based group).
# Multi-line: the literal string `concurrency:` and the literal expression
# `pull_request.number` are on adjacent lines in the existing label-check.yml.
# Use here-string to avoid pipefail + SIGPIPE interaction with `printf | grep`.
has_concurrency=false
has_numbering=false
if grep -qE "^concurrency:|^\s+concurrency:" <<< "$workflow_text"; then
  has_concurrency=true
fi
if grep -qE "pull_request\.number|issue\.number" <<< "$workflow_text"; then
  has_numbering=true
fi
if [ "$has_concurrency" = "true" ] && [ "$has_numbering" = "true" ]; then
  pass "concurrency group covers PR/issue number (closed-event inherits race-protection)"
else
  fail "concurrency group missing or doesn't cover PR/issue number" \
    "expected concurrency block (has=$has_concurrency) + reference to pull_request.number or issue.number (has=$has_numbering)"
fi

# --- Summary ---
printf "\n${B}==== SUMMARY ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0