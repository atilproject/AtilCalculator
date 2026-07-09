#!/usr/bin/env bash
# d067c-open-time-label-strip.sh — TD-067c RED-first regression (Issue #931).
#
# Why this test exists
# --------------------
# Issue #931 (TD-067c): TD-067b Part 2 extends .github/workflows/label-check.yml
# with a CLOSED-event Layer 6 diagnostic (PR #938 squash @ 4975c22, ADR-0070).
# TD-067c adds the OPEN-time Layer 7 sister-pattern — fires on PR/Issue
# opened|reopened|labeled|unlabeled|synchronize to catch label-strips that
# occur while the PR is still OPEN (4 known instances per Issue #931 §Evidence
# stack; PR #933 = live instance detected 12:40:53Z during sister-pattern cycle).
#
# Sister-pattern lineage:
#   - TD-067 / Issue #922 (PR-axis Part 1, Closes via PR #926)
#   - TD-067b / Issue #927 (close-axis fix, Layer 6 — PR #938 squash merged)
#   - TD-067c / Issue #931 (open-axis sister, THIS test — Layer 7)
#   - TD-068 / Issue #920 (state-file-axis fix sister)
#   - d068-td067-combined.sh (close-axis d-test sister — DIRECT, same workflow,
#     same diagnostic predicate archetype)
#   - docs/designs/TD-067-TD-068-sister-fix-design.md §Components
#
# TDD contract (9 cases per ADR-0049 ≥5 baseline + dev review additions at PR #946 cmt 4665103514):
#   TC1: pull_request opened|reopened triggers exist (Layer 7 open-time entry)
#   TC2: issues opened|reopened|labeled|unlabeled triggers exist (Issue surface unification)
#   TC3: pull_request synchronize (push) trigger exists (R2 false-positive gate precursor)
#   TC4: open-diagnostic marker present (idempotency sister of TD-067b)
#   TC5: maintainer actor check present — atilcan65 OR github-actions[bot] info-downgrade
#   TC6: synchronize diff-gate sentinel — diff preserves 4-cat = silent_skip, breaks = comment
#   TC7: concurrency group parameterized for PR + Issue surfaces (R1 mitigation)
#   TC8: SHA-pinning preserved on all actions/* usages (40-char hex, ADR-0027)
#   TC9: open-time 4-cat baseline check (NOT-done status + agent present + cc present)
#
# Sister-patterns:
#   - d068-td067-combined.sh (DIRECT — closed-axis sister, same workflow, 7 TCs)
#   - d127-td-067-transient-regex-preserve.sh (TD-067 Part 1 TRANSIENT_REGEX sister)
#   - d015 + d031 (≥5 TCs baseline + auto-claim sister-pattern)
#   - ADR-0012 (4-cat invariant being protected — Layer 7 catch point)
#   - ADR-0044 (RED-first TDD doctrinal home)
#   - ADR-0049 (d-test framework, ≥5 TCs baseline — d067c = 9 TCs exceeds by 4)
#   - ADR-0055 §1 (Cadence Rule 1 atomic — d-test file + INDEX.md row same commit)
#
# Run: bash scripts/tests/d067c-open-time-label-strip.sh
# Expected pre-impl (RED per ADR-0044): TC1+TC3+TC4+TC5+TC6 FAIL (open-time triggers,
#         open-diagnostic marker, maintainer actor check, synchronize diff-gate).
#         TC2+TC7+TC8+TC9 PASS green (baseline-preserved: issues trigger, parameterized
#         concurrency, SHA-pinning, baseline check signatures all already exist).
# Expected post-impl (GREEN): all 9 PASS.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/label-check.yml"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi
PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# Preflight: workflow file present + parseable
# ============================================================================
section 'Preflight: workflow YAML parseable'
if [ ! -f "$WORKFLOW_FILE" ]; then
  printf "${R}ERROR: workflow file missing: %s${D}\n" "$WORKFLOW_FILE" >&2
  exit 4
fi
pass "workflow file present at $WORKFLOW_FILE"

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
pass "workflow YAML parsed to JSON"

# Raw text for grep-style structural checks (here-string avoids SIGPIPE/pipefail
# interaction with early-exit grep, per d068-td067-combined.sh sister-pattern).
workflow_text="$(cat "$WORKFLOW_FILE")"

# ============================================================================
# TC1: pull_request opened|reopened triggers exist (Layer 7 entry)
# ============================================================================
# AC: Without pull_request trigger (NOT pull_request_target), the open-time
# diagnostic never fires. Existing workflow only has pull_request_target; impl
# must ADD pull_request with opened/reopened types.
section 'TC1: pull_request (NOT pull_request_target) trigger for open-time events'
pr_triggers="$(python3 -c "
import json
with open('$YAML_JSON_FILE') as f:
    data = json.load(f)
on = data.get(True) or data.get('true') or data.get('on') or {}
pr = on.get('pull_request', {}) if isinstance(on, dict) else {}
prt = on.get('pull_request_target', {}) if isinstance(on, dict) else {}
print('PULL_REQUEST=' + (','.join(pr.get('types', [])) if isinstance(pr.get('types', []), list) else str(pr.get('types', ''))))
print('PULL_REQUEST_TARGET=' + (','.join(prt.get('types', [])) if isinstance(prt.get('types', []), list) else str(prt.get('types', ''))))
")"
pr_types="$(printf '%s\n' "$pr_triggers" | sed -n 's/^PULL_REQUEST=//p')"
prt_types="$(printf '%s\n' "$pr_triggers" | sed -n 's/^PULL_REQUEST_TARGET=//p')"
if [ -n "$pr_types" ] && printf '%s' "$pr_types" | grep -qE "(^|,)(opened|reopened)(,|$)"; then
  pass "pull_request.types includes opened/reopened (open-time entry point)"
  printf "    types: %s\n" "$pr_types"
else
  fail "pull_request.types missing opened/reopened" \
       "got: '$pr_types' (must add pull_request: opened|reopened to on: block — pull_request_target already has $prt_types)"
fi

# ============================================================================
# TC2: issues opened|reopened|labeled|unlabeled triggers exist (Issue surface)
# ============================================================================
# AC: Surface unification — single diagnostic covers both PR and Issue surfaces
# per design doc §Concurrency group design (R1 mitigation). Existing on: block
# already has issues: [opened, reopened, labeled, unlabeled]. This TC PASSes on
# main; verified for non-regression of architectural baseline.
section 'TC2: issues opened|reopened|labeled|unlabeled triggers (Issue surface unification)'
issues_triggers="$(python3 -c "
import json
with open('$YAML_JSON_FILE') as f:
    data = json.load(f)
on = data.get(True) or data.get('true') or data.get('on') or {}
issues = on.get('issues', {}) if isinstance(on, dict) else {}
types = issues.get('types', [])
print(','.join(types) if isinstance(types, list) else str(types))
")"
required=("opened" "reopened" "labeled" "unlabeled")
issues_ok=true
for t in "${required[@]}"; do
  if ! printf '%s' "$issues_triggers" | grep -qE "(^|,)${t}(,|$)"; then
    issues_ok=false
    fail "issues trigger missing type: $t" "got: '$issues_triggers'"
    break
  fi
done
if [ "$issues_ok" = true ]; then
  pass "issues.types includes all 4 expected types (opened|reopened|labeled|unlabeled)"
fi

# ============================================================================
# TC3: pull_request synchronize (push) trigger exists (R2 false-positive gate)
# ============================================================================
# AC: Without synchronize trigger, the diff-gate (TC6) has nothing to attach to.
# Per design R2 mitigation: synchronize events fire on every push; impl must
# compute pre vs post label diff and ONLY alert if 4-cat invariant breaks.
section 'TC3: pull_request synchronize (push) trigger for diff-gate'
if [ -n "$pr_types" ] && printf '%s' "$pr_types" | grep -qE "(^|,)synchronize(,|$)"; then
  pass "pull_request.types includes synchronize (diff-gate entry point)"
else
  fail "pull_request.types missing synchronize" \
       "got: '$pr_types' (must add synchronize to enable TC6 diff-gate)"
fi

# ============================================================================
# TC4: open-diagnostic marker present (idempotency sister of TD-067b)
# ============================================================================
# AC: Diagnostic comment fires ONCE per deviation (not on every event) via
# marker-based bot comment dedup. Marker MUST be unique to open-time axis:
# adr-0071-open-diagnostic (sister to TD-067b's adr-0070-closed-diagnostic).
# Pre-impl: no open-diagnostic marker. Cross-check closed-diagnostic preserved.
section 'TC4: open-diagnostic marker (idempotency sister of TD-067b)'
if grep -qE "adr-0071-open-diagnostic|adr-[0-9]+-open-diagnostic" <<< "$workflow_text"; then
  pass "open-diagnostic marker present (comment dedup ready for open-time axis)"
else
  fail "open-diagnostic marker missing" \
       "expected 'adr-0071-open-diagnostic' or 'adr-NNNN-open-diagnostic' marker in workflow body (sister-pattern L108-110 dedup)"
fi
if grep -qE "adr-0070-closed-diagnostic|adr-[0-9]+-closed-diagnostic" <<< "$workflow_text"; then
  pass "closed-diagnostic (TD-067b) marker preserved (non-regression baseline)"
else
  fail "closed-diagnostic (TD-067b) marker MISSING — sister-pattern regression" \
       "expected 'adr-0070-closed-diagnostic' marker preserved from PR #938 squash @ 4975c22"
fi

# ============================================================================
# TC5: maintainer actor check present (R3 hostile-strip discrimination)
# ============================================================================
# AC: Owner atilcan65 + bot github-actions[bot] actor changes → info-level log,
# NO comment (distinguishes hostile strip from intentional maintainer reset /
# sprint planning). Per design §Step semantics + dev review TC8 (atilcan65
# info-downgrade, separate from bot actor).
section 'TC5: maintainer actor check (atilcan65 / github-actions[bot] info-downgrade)'
bot_check=false
owner_check=false
# Bot actor — must reference the actual GitHub Actions bot login (sister to Layer 1 L84-92
# `if (github.actor === 'github-actions[bot]')` precedent). NOT a URL/mention coincidence.
if grep -qE "github-actions\[bot\]|github_actions_bot|'github-actions\.bot'" <<< "$workflow_text"; then
  bot_check=true
fi
# Owner actor — must reference github.actor (the actual context object), with atilcan65 as
# comparison value. NOT just a URL mention (atilcan65 appears in URLs throughout, which
# is a false-positive trap).
if grep -qE "github\.actor\s*[!=]==\s*['\"]atilcan65['\"]|github\.actor.*atilcan65|context\.payload\.sender.*atilcan65" <<< "$workflow_text"; then
  owner_check=true
fi
if [ "$bot_check" = true ] && [ "$owner_check" = true ]; then
  pass "maintainer actor check covers BOTH atilcan65 + github-actions[bot] (R3 mitigation complete)"
elif [ "$bot_check" = true ]; then
  pass "github-actions[bot] actor check present (dev review TC5 partial — bot actor)"
  fail "atilcan65 owner actor check MISSING" \
       "dev review TC8 requires OWNER actor info-downgrade via github.actor comparison (not just bot)"
elif [ "$owner_check" = true ]; then
  pass "atilcan65 owner actor check present (dev review TC8 partial — owner actor)"
  fail "github-actions[bot] actor check MISSING" \
       "design §Step semantics requires bot actor info-downgrade"
else
  fail "maintainer actor check MISSING" \
       "expected both 'github-actions[bot]' AND 'github.actor == \"atilcan65\"' in workflow (design §R3 + dev review TC5+TC8)"
fi

# ============================================================================
# TC6: synchronize diff-gate sentinel present (R2 false-positive mitigation)
# ============================================================================
# AC: Without diff-gate, every push fires a diagnostic comment (noise spam).
# The gate computes pre-event vs post-event label diff and ONLY alerts if 4-cat
# is broken. Pattern: grep for synchronize mention in STEP-level if: (not just
# trigger-level) + presence of diff-comparison logic.
section 'TC6: synchronize diff-gate sentinel (no alert on preserve-4-cat push)'
# Step-level if: must include synchronize to enter the diff-gate path.
# Pattern: if: ... && github.event.action == synchronize ... OR equivalent.
diff_gate_ok=false
if grep -qE "if:.*synchronize|action.*==.*synchronize" <<< "$workflow_text"; then
  diff_gate_ok=true
fi
# Also need diff comparison or label-set comparison logic.
diff_compare_ok=false
if grep -qE "diff|labelDiff|labelsDiff|compareLabels|labels.*before|labels.*after" <<< "$workflow_text"; then
  diff_compare_ok=true
fi
if [ "$diff_gate_ok" = true ] && [ "$diff_compare_ok" = true ]; then
  pass "synchronize diff-gate present (step-level if: + diff comparison logic)"
elif [ "$diff_gate_ok" = true ]; then
  pass "synchronize step-level if: present (TC6 partial — diff-gate entry)"
  fail "diff comparison logic MISSING" \
       "expected 'diff' or 'compareLabels' or 'labelsDiff' in workflow (TC6 complete — diff-preserves-4-cat silent_skip path)"
else
  fail "synchronize diff-gate MISSING" \
       "expected step-level if: synchronize + diff-comparison logic (R2 false-positive mitigation)"
fi

# ============================================================================
# TC7: concurrency group parameterized for PR + Issue surfaces
# ============================================================================
# AC: Issue events don't have pull_request.number, they have issue.number.
# Naive TD-067b form would compute label-check-undefined for Issue events
# (R1 mitigation per arch review cmt 4927052273 + cmt 4927243051). Existing
# workflow already uses parameterized form (post-PR-#938 retrofit); this TC
# verifies non-regression.
section 'TC7: concurrency group parameterized for PR + Issue (R1 mitigation)'
has_concurrency=false
has_param=false
if grep -qE "^concurrency:|^\s+concurrency:" <<< "$workflow_text"; then
  has_concurrency=true
fi
# Parameterized form: pull_request.number || issue.number
if grep -qE "pull_request\.number.*\|\|.*issue\.number|issue\.number.*\|\|.*pull_request\.number" <<< "$workflow_text"; then
  has_param=true
fi
if [ "$has_concurrency" = true ] && [ "$has_param" = true ]; then
  pass "concurrency group parameterized for PR + Issue (R1 mitigation preserved)"
else
  fail "concurrency group NOT parameterized for PR + Issue" \
       "expected 'concurrency:' + 'pull_request.number || issue.number' (R1 mitigation per arch review cmt 4927243051)"
fi

# ============================================================================
# TC8: SHA-pinning preserved on actions/* (ADR-0027 + ADR-0043 §lens h)
# ============================================================================
# AC: All uses: actions/... MUST reference full 40-char SHA, not moving tag.
# Existing workflow pins actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b
# (sister TD-067b Layer 6 attestation R4). Impl must PRESERVE this discipline
# for any new actions/* added.
section 'TC8: SHA-pinning preserved on actions/* (40-char hex after @)'
sha_pinned=true
uses_lines="$(grep -E '^\s*uses:\s*actions/' <<< "$workflow_text" || true)"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if ! grep -qE '@[a-f0-9]{40}(\s|$|#)' <<< "$line"; then
    sha_pinned=false
    fail "TC8 — actions/* missing 40-char SHA" "line: $line"
    break
  fi
done <<< "$uses_lines"
if [ "$sha_pinned" = true ] && [ -n "$uses_lines" ]; then
  pass "all actions/* SHA-pinned (40-char hex after @)"
elif [ -z "$uses_lines" ]; then
  fail "TC8 — no actions/* references found in workflow" \
       "expected at least one SHA-pinned action (sister TD-067b L884 attestation)"
fi

# ============================================================================
# TC9: open-time 4-cat baseline check (NOT-done status + agent + cc)
# ============================================================================
# AC: Sister-pattern to TD-067b Layer 6 baseline check. Layer 6 expects
# status:done (post-cleanup) + agent/cc ABSENT. Layer 7 expects status:NOT-done
# (PR still open) + agent present + cc present. The 4-cat validation logic
# MUST distinguish Layer 7 PRESENCE-check from Layer 6 ABSENCE-check.
#
# Specific signal: Layer 7 needs the `not_done` baseline (status is one of
# backlog/ready/in-progress/in-review/blocked, NOT done). This is the
# sister-distinguishing feature from Layer 6 (which checks status == done).
section 'TC9: open-time 4-cat baseline check (status:not-done + agent/cc PRESENCE)'
# Sister-distinguishing signal 1: status NOT-done check (Layer 7 expects PR open).
# Pattern: `status !== 'done'`, `status != 'done'`, `!== 'done'`, or `=== 'done'` inverted.
# Word-bounded to avoid `success` → `ccess` false-positive (cc.*length sub-pattern).
has_not_done_status=false
if grep -qE "\bstatus\b\s*!==\s*['\"]done['\"]|\bstatus\b\s*!=\s*['\"]done['\"]|!\s*===\s*['\"]done['\"]|not\s+['\"]done['\"]" <<< "$workflow_text"; then
  has_not_done_status=true
fi
# Sister-distinguishing signal 2: agent/cc PRESENCE check (Layer 6 checks absence).
# Use word-bounded patterns to avoid `ccess ... removed.length` false-positive.
# Pattern: `\bagentLabels.length`, `\bccLabels.length`, `hasAgent(...)`, `hasCc(...)`.
has_presence_check=false
if grep -qE "\bagentLabels\.length|\bccLabels\.length|\bagentLabel\.length|\bccLabel\.length|hasAgent\(|hasCc\(|agents\.length\s*[!=]=\s*0|ccs\.length\s*[!=]=\s*0" <<< "$workflow_text"; then
  has_presence_check=true
fi
if [ "$has_not_done_status" = true ] && [ "$has_presence_check" = true ]; then
  pass "open-time 4-cat baseline checks PRESENCE (status not-done + agent present + cc present)"
elif [ "$has_not_done_status" = true ]; then
  pass "status not-done check present (TC9 partial — distinguishes open-time axis)"
  fail "agent/cc presence check MISSING" \
       "expected 'agentLabels.length' or 'ccLabels.length' or 'hasAgent(' pattern (Layer 7 sister-distinguishing signal)"
elif [ "$has_presence_check" = true ]; then
  pass "agent/cc presence check present (TC9 partial — Layer 7 PRESENCE signal)"
  fail "status not-done check MISSING" \
       "expected 'status !== done' or '!== done' (Layer 7 expects NOT-done; sister-distinguishing from Layer 6)"
else
  fail "open-time 4-cat baseline check MISSING" \
       "expected 'status !== done' + 'agentLabels.length/ccLabels.length' or 'hasAgent/hasCc' (Layer 7 sister-pattern)"
fi

# ============================================================================
# SUMMARY
# ============================================================================
printf "\n${B}==== SUMMARY ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"
printf "  Workflow file: %s\n" "$WORKFLOW_FILE"
echo ""
if [[ "$FAIL" -gt 0 ]]; then
  echo "SOME TESTS FAILED (RED-first state per ADR-0044 — impl not yet landed)"
  exit 1
fi
echo "ALL TESTS PASSED (d067c GREEN: TD-067c open-time diagnostic satisfied)"
exit 0
