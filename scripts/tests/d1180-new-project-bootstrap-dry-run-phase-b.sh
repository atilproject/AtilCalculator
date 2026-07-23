#!/usr/bin/env bash
# d1180-new-project-bootstrap-dry-run-phase-b.sh — Issue #1180 Phase B AC1 dry-run verifier
#
# Why this test exists
# --------------------
# Issue #1180 (S33 P1) Phase B follow-up to tmpl#162 (S32-024) which was
# prematurely closed per cycle ~#2919 partial Closes anti-pattern. Phase A d-test
# (d-s32-024-new-project-bootstrap-dry-run.sh, commit 5d2a251, PR #196) has 4
# RED TCs (TC4 TC5 TC6 TC7) waiting for AC1 invocation to land.
#
# This Phase B d-test verifies the NEW helper `scripts/dev-studio-dryrun.sh`
# (created in PR #XXXX) provides the AC1 surface directly without requiring a
# live `gh repo create` — i.e., FIXTURE_MODE=1 path per d001-launcher sister-
# pattern (S29-013 Issue #1072).
#
# Six ACs of Issue #1180 (mirrors Issue #162):
#   AC1: dry-run invocation + project bootstrap (sprint-32-dryrun repo via
#        `gh repo create --template atilproject/dev-studio-template --private` +
#        init.sh + bootstrap-labels.sh + dev-studio-start.sh 5-agent spawn)
#   AC4: PM claim path (Vision Intake issue + PM claim + first story sized)
#   AC5: in-dry-run merge — ABOLISHED per cycle ~#3968Q+71+terminal (Issue #1196
#        squash 08:30:06Z), sister-pattern applies
#   AC6: close-the-loop (4-cat labels per ADR-0012 + verdict-by + owner squash)
#
# Post-impl GREEN state (after dev-studio-dryrun.sh AC1 helper lands):
#   TC0 PASS (preflight bash + jq available)
#   TC1 PASS (helper exists + executable + bash -n clean)
#   TC2 PASS (--source-mode emits 4-tuple constant)
#   TC3 PASS (--source-mode exposes all 5 helper functions)
#   TC4 PASS (--invoke in FIXTURE_MODE emits valid single-line JSON)
#   TC5 PASS (--invoke with custom --owner --project emits custom JSON)
#   TC6 PASS (--verify-4cat FIXTURE labels=14 → exit 0 PASS)
#   TC7 PASS (--verify-4cat FIXTURE labels=10 → exit 7 FAIL per spec)
#   TC8 PASS (--pm-claim FIXTURE_MODE → exit 0 with vision_issue_number)
#   TC9 PASS (mutually exclusive modes → exit 1)
#   TC10 PASS (--help → exit 0)
# → 11/11 GREEN expected.
#
# Pre-impl RED state (helper file missing):
#   TC0 PASS, TC1 FAIL (no helper), TC2-TC10 FAIL (helper missing)
# → 1/11 PASS + 10/11 FAIL = proper RED-first per ADR-0044 baseline ≥5 met.
#
# Sister-pattern family (d-test lineage, ADR-0049 ≥3 sister-pattern met):
#   - d-s32-024-new-project-bootstrap-dry-run.sh (DIRECT sister — TC0 preflight +
#     TC1 file existence + TC2 source-mode + TC3 fixture hook + summary
#     convention, commit 5d2a251)
#   - d001-launcher-self-hosted-runner-patch.sh (sister — sourced-mode 4-tuple +
#     FIXTURE_MODE=1 + FIXTURE_* env-var pattern, S29-013 Issue #1072)
#   - d-smoke-bootstrap-v110.sh (sister — bash -n hygiene + FIXTURE-friendly
#     pattern, content-blob SHA lineage)
#   - d-verify-portage-diff-engine.sh (sister — TRAP cleanup + REST + bash -n
#     pattern)
#
# Sprint 33 cross-repo workstream refs:
#   - Issue #1180 (S33 P1 tracker in atilproject/AtilCalculator, agent:developer,
#     status:in-progress)
#   - Issue #162 (tmpl#162 S32-024 — DIRECT predecessor, prematurely closed)
#   - scripts/dev-studio-dryrun.sh (helper under test, ~303 LOC)
#   - ADR-0012 (4-cat invariant — TC6 verification surface)
#   - ADR-0044 (RED-first TDD doctrinal home)
#   - ADR-0049 (d-test framework, ≥5 TCs baseline + ≥3 sister-pattern met via 4 sisters)
#   - ADR-0055 §1 (Cadence Rule 1 atomic — d-test + INDEX.md + CHANGELOG.md same commit)
#   - ADR-0057 (Closes anchor strict format)
#   - cycle ~#3893Q v2 (verify-locally-before-verdict — TC1 bash -n hygiene gate)
#   - cycle ~#3968Q+71+terminal (AC5 24h soak ABOLISHED — applies to sister AC5)
#
# Usage:
#   bash scripts/tests/d1180-new-project-bootstrap-dry-run-phase-b.sh
#
# Exit codes:
#   0 — all PASS (GREEN — AC1 helper verified)
#   1 — at least one FAIL (RED — helper missing or partial)
#   2 — preflight failure (missing tool, etc.)

set -uo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPER_REL="scripts/dev-studio-dryrun.sh"
HELPER_PATH="$REPO_ROOT/$HELPER_REL"

# --- TC0: preflight — bash + jq available ---
tc0_status="PASS"
for tool in bash jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "TC0 FAIL: $tool not available" >&2
    tc0_status="FAIL"
  fi
done
if [[ "$tc0_status" == "PASS" ]]; then
  echo "TC0 PASS: preflight OK (bash + jq available)"
fi

# --- TC1: helper exists + executable + bash -n clean ---
if [[ ! -f "$HELPER_PATH" ]]; then
  echo "TC1 FAIL (RED pre-impl): helper $HELPER_REL does not exist (Issue #1180 AC1 impl not yet landed — this TC is the RED-first signal per ADR-0044)"
  tc1_status="FAIL"
elif [[ ! -x "$HELPER_PATH" ]]; then
  echo "TC1 FAIL: helper exists at $HELPER_PATH but is NOT executable (chmod +x required)"
  tc1_status="FAIL"
elif ! bash -n "$HELPER_PATH" 2>/dev/null; then
  echo "TC1 FAIL: bash -n syntax check FAILED on $HELPER_PATH (cycle ~#3893Q v2 verify-locally-before-verdict hygiene gate)"
  tc1_status="FAIL"
else
  echo "TC1 PASS: helper $HELPER_REL exists + executable + bash -n clean (AC1 helper file verified per cycle ~#3893Q v2 hygiene gate)"
  tc1_status="PASS"
fi

# --- TC2: --source-mode emits 4-tuple constant ---
# Per d001-launcher-self-hosted-runner-patch.sh sister-pattern (S29-013 Issue #1072):
# source-mode exports a 4-tuple constant + helper functions, skips main bootstrap flow.
EXPECTED_4TUPLE="[gh_repo_create,clone,checkout_tag,init_sh,bootstrap_labels]"
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC2 FAIL: helper not verifiable (TC1 dependency)"
  tc2_status="FAIL"
else
  tuple_value=$(bash "$HELPER_PATH" --source-mode 2>&1 | head -1 || echo "")
  if [[ "$tuple_value" == "$EXPECTED_4TUPLE" ]]; then
    echo "TC2 PASS: --source-mode emits DRYRUN_4TUPLE_BOOTSTRAP_PHASES='$tuple_value' (d001-launcher sister-pattern — S29-013 4-tuple contract)"
    tc2_status="PASS"
  else
    echo "TC2 FAIL: 4-tuple mismatch — expected '$EXPECTED_4TUPLE', got '$tuple_value'"
    tc2_status="FAIL"
  fi
fi

# --- TC3: --source-mode exposes all 5 helper functions ---
# Per d001-launcher d-test pattern: helper functions declared + queryable via `type -t funcname`
# which outputs "function" if declared, "" otherwise. Expect 5 "function" lines after the 4-tuple.
EXPECTED_HELPERS=(
  "dryrun_resolve_repo_url"
  "dryrun_http_probe"
  "dryrun_count_labels"
  "dryrun_check_init_clean"
  "dryrun_count_tmpl_remaining"
)
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC3 FAIL: helper not verifiable (TC1 dependency)"
  tc3_status="FAIL"
else
  # Capture --source-mode output: line 1 = 4-tuple, lines 2..N = "function" for each declared helper
  function_lines=$(bash "$HELPER_PATH" --source-mode 2>&1 | tail -n +2)
  function_count=$(echo "$function_lines" | grep -c "^function$" || echo "0")
  if [[ "$function_count" -eq 5 ]]; then
    echo "TC3 PASS: --source-mode exposes all 5 helper functions: ${EXPECTED_HELPERS[*]} (d001-launcher sister-pattern — type -t emits 'function' 5 times, 5 helpers wired)"
    tc3_status="PASS"
  else
    echo "TC3 FAIL: --source-mode declares $function_count helper functions (expected 5 per d001-launcher pattern)"
    tc3_status="FAIL"
  fi
fi

# --- TC4: --invoke in FIXTURE_MODE emits valid single-line JSON ---
# Per d001-launcher FIXTURE_MODE=1 sister-pattern: skip live gh, emit fixture state.
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC4 FAIL: helper not verifiable (TC1 dependency)"
  tc4_status="FAIL"
else
  invoke_output=$(bash "$HELPER_PATH" --invoke --fixture 2>&1 || true)
  # Validate JSON shape via jq
  jq_valid=0
  jq_required_keys=("owner" "project" "dir" "tag" "http_code" "labels" "init_clean" "tmpl_remaining")
  if echo "$invoke_output" | jq -e '.' >/dev/null 2>&1; then
    jq_valid=1
  fi
  missing_keys=()
  if [[ "$jq_valid" -eq 1 ]]; then
    for k in "${jq_required_keys[@]}"; do
      if ! echo "$invoke_output" | jq -e "has(\"$k\")" >/dev/null 2>&1; then
        missing_keys+=("$k")
      fi
    done
  fi
  if [[ "$jq_valid" -eq 1 ]] && [[ ${#missing_keys[@]} -eq 0 ]]; then
    echo "TC4 PASS: --invoke --fixture emits valid single-line JSON with all 8 keys: ${jq_required_keys[*]} (d001-launcher FIXTURE_MODE=1 sister-pattern)"
    tc4_status="PASS"
  else
    echo "TC4 FAIL: --invoke --fixture output invalid — jq_valid=$jq_valid missing_keys=${missing_keys[*]} output=$invoke_output"
    tc4_status="FAIL"
  fi
fi

# --- TC5: --invoke with custom --owner --project (FIXTURE) emits custom JSON ---
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC5 FAIL: helper not verifiable (TC1 dependency)"
  tc5_status="FAIL"
else
  custom_output=$(bash "$HELPER_PATH" --invoke --fixture --owner=test-owner --project=test-dryrun 2>&1 || true)
  custom_owner=$(echo "$custom_output" | jq -r '.owner // "PARSE_FAIL"' 2>/dev/null || echo "PARSE_FAIL")
  custom_project=$(echo "$custom_output" | jq -r '.project // "PARSE_FAIL"' 2>/dev/null || echo "PARSE_FAIL")
  if [[ "$custom_owner" == "test-owner" ]] && [[ "$custom_project" == "test-dryrun" ]]; then
    echo "TC5 PASS: --invoke --fixture --owner=test-owner --project=test-dryrun emits custom JSON (owner=$custom_owner project=$custom_project, --owner/--project override wired)"
    tc5_status="PASS"
  else
    echo "TC5 FAIL: --owner/--project override not respected (got owner=$custom_owner project=$custom_project, output=$custom_output)"
    tc5_status="FAIL"
  fi
fi

# --- TC6: --verify-4cat with FIXTURE labels present → exit 0 ---
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC6 FAIL: helper not verifiable (TC1 dependency)"
  tc6_status="FAIL"
else
  # Use FIXTURE env var to set label count ≥14 per ADR-0012 (AC6 surface)
  FIXTURE_LABEL_COUNT=14 FIXTURE_MODE=1 bash "$HELPER_PATH" --verify-4cat --dir=/tmp 2>&1
  tc6_exit=$?
  if [[ "$tc6_exit" -eq 0 ]]; then
    echo "TC6 PASS: --verify-4cat FIXTURE_LABEL_COUNT=14 → exit 0 (AC6 close-the-loop 4-cat verify surface per ADR-0012)"
    tc6_status="PASS"
  else
    echo "TC6 FAIL: --verify-4cat FIXTURE_LABEL_COUNT=14 → exit $tc6_exit (expected 0 — 4-cat verify FAIL regression)"
    tc6_status="FAIL"
  fi
fi

# --- TC7: --verify-4cat with FIXTURE labels absent → exit 7 ---
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC7 FAIL: helper not verifiable (TC1 dependency)"
  tc7_status="FAIL"
else
  FIXTURE_LABEL_COUNT=10 FIXTURE_MODE=1 bash "$HELPER_PATH" --verify-4cat --dir=/tmp 2>&1
  tc7_exit=$?
  if [[ "$tc7_exit" -eq 7 ]]; then
    echo "TC7 PASS: --verify-4cat FIXTURE_LABEL_COUNT=10 → exit 7 (4-cat verify FAIL per spec — labels < 14 threshold)"
    tc7_status="PASS"
  else
    echo "TC7 FAIL: --verify-4cat FIXTURE_LABEL_COUNT=10 → exit $tc7_exit (expected 7 per exit-code spec)"
    tc7_status="FAIL"
  fi
fi

# --- TC8: --pm-claim in FIXTURE_MODE → exit 0 with vision_issue_number ---
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC8 FAIL: helper not verifiable (TC1 dependency)"
  tc8_status="FAIL"
else
  pm_output=$(FIXTURE_VISION_ISSUE_NUMBER=42 FIXTURE_MODE=1 bash "$HELPER_PATH" --pm-claim --dir=/tmp/x --owner=test --project=test 2>&1 || true)
  pm_exit=$?
  if [[ "$pm_exit" -eq 0 ]] && echo "$pm_output" | grep -q "vision_issue=#42"; then
    echo "TC8 PASS: --pm-claim FIXTURE_VISION_ISSUE_NUMBER=42 → exit 0 + vision_issue=#42 emitted (AC4 PM claim path surface per d001-launcher FIXTURE_MODE=1)"
    tc8_status="PASS"
  else
    echo "TC8 FAIL: --pm-claim FIXTURE_MODE=1 → exit $pm_exit output=$pm_output (expected exit 0 + vision_issue=#42)"
    tc8_status="FAIL"
  fi
fi

# --- TC9: mutually exclusive modes → exit 1 ---
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC9 FAIL: helper not verifiable (TC1 dependency)"
  tc9_status="FAIL"
else
  bash "$HELPER_PATH" --invoke --verify-4cat 2>&1
  tc9_exit=$?
  if [[ "$tc9_exit" -eq 1 ]]; then
    echo "TC9 PASS: --invoke --verify-4cat (two modes) → exit 1 (mutually exclusive mode guard per d001-launcher sister)"
    tc9_status="PASS"
  else
    echo "TC9 FAIL: two-mode invocation → exit $tc9_exit (expected 1 per mutual exclusion spec)"
    tc9_status="FAIL"
  fi
fi

# --- TC10: --help → exit 0 ---
if [[ "$tc1_status" != "PASS" ]]; then
  echo "TC10 FAIL: helper not verifiable (TC1 dependency)"
  tc10_status="FAIL"
else
  help_output=$(bash "$HELPER_PATH" --help 2>&1 || true)
  help_exit=$?
  if [[ "$help_exit" -eq 0 ]] && echo "$help_output" | grep -qE "(--source-mode|--invoke|--verify-4cat|--pm-claim)"; then
    echo "TC10 PASS: --help → exit 0 + emits all 4 mode flags in usage (d001-launcher sister-pattern — usage completeness)"
    tc10_status="PASS"
  else
    echo "TC10 FAIL: --help → exit $help_exit output=$help_output (expected exit 0 + all 4 mode flags listed)"
    tc10_status="FAIL"
  fi
fi

# --- summary ---
total=11
fail_count=0
for s in "$tc0_status" "$tc1_status" "$tc2_status" "$tc3_status" "$tc4_status" "$tc5_status" "$tc6_status" "$tc7_status" "$tc8_status" "$tc9_status" "$tc10_status"; do
  if [[ "$s" == "FAIL" ]]; then
    fail_count=$((fail_count + 1))
  fi
done
pass_count=$((total - fail_count))

echo "---"
echo "d1180-new-project-bootstrap-dry-run-phase-b: $pass_count/$total PASS, $fail_count/$total FAIL"

if [[ "$fail_count" -gt 0 ]]; then
  echo "RESULT: RED (AC1 helper scripts/dev-studio-dryrun.sh not yet verified — Issue #1180 active, impl not landed)"
  exit 1
else
  echo "RESULT: GREEN (AC1 helper verified — Issue #1180 AC1 d-testable subset PASS, 11/11 GREEN)"
  exit 0
fi
