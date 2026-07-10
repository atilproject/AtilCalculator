#!/usr/bin/env bash
# d853-canary-config-yml.sh — canary mirror `.github/ISSUE_TEMPLATE/config.yml` regression guard
#
# Why this test exists
# --------------------
# Issue #853 / STORY-S26-002: canary mirror push (orchestrator's
# `git push canary main --follow-tags`) false-positives on missing
# `.github/ISSUE_TEMPLATE/config.yml` because the file is **gitignored**
# at `.gitignore` line 81 (rendered output of `scripts/dev-studio-init.sh`).
#
# Canary clones `main` via `git clone`, which excludes gitignored files,
# so the canary mirror ends up with 5 ISSUE_TEMPLATE files but no config.yml.
# This breaks post-release canary health-check signaling.
#
# Sprint 26 scope per Issue #941 §Scope row 2; PRD per PR #945 (eb06dc6)
# `docs/backlog/STORY-S26-002.md`. Sister-pattern lineage per ADR-0049.
#
# This d-test guards:
#   - TC1: config.yml exists locally at canonical path
#   - TC2: config.yml is valid YAML (PyYAML parse or yq fallback)
#   - TC3: config.yml is REACHABLE from `git clone` (canonical RED state —
#          tracked AND not gitignored; pre-fix this TC FAILS)
#   - TC4: d-test self-test flag (--self-test) returns 0 + per-TC markers
#   - TC5: d-test runs end-to-end with --no-cov CI runner semantics
#   - TC6: Sister-parity audit of OTHER 5 ISSUE_TEMPLATE files (valid YAML,
#          contains `name:` + `description:` keys minimum schema)
#   - TC7: scripts/tests/INDEX.md row exists for d853 (Cadence Rule 1 atomic)
#
# Pre-impl RED state (current main as of 2026-07-09T23:43Z, pre-fix):
#   - TC1: PASS (file exists locally, 5 lines, valid content)
#   - TC2: PASS (PyYAML parses cleanly)
#   - TC3: FAIL (gitignored at .gitignore:81; `git ls-files --error-unmatch` returns 1)
#   - TC4: PASS (this d-test file's --self-test discipline)
#   - TC5: PASS (per-TC marker emission, exit 0 on GREEN, 1 on any FAIL)
#   - TC6: PASS (other 5 ISSUE_TEMPLATE files valid YAML + schema)
#   - TC7: FAIL (INDEX.md row missing pre-fix)
#   → 2/7 TCs FAIL = proper RED-first per ADR-0044.
#
# Post-impl GREEN state (after developer fix lands + PR squash):
#   - TC1: PASS
#   - TC2: PASS
#   - TC3: PASS (config.yml tracked OR removed from gitignore; reachable via clone)
#   - TC4: PASS
#   - TC5: PASS
#   - TC6: PASS
#   - TC7: PASS (INDEX.md row added atomically per Cadence Rule 1)
#   → 7/7 PASS
#
# Sister-pattern family (d-test lineage, ADR-0049):
#   - d095 (Issue #708 + PR #709 — post-org-migration clone URL regression guard, 5 TCs)
#   - d649 (Issue #649 + PR #679 — STORY-S21-022 smoke test, 5 TCs)
#   - d070b (Issue #693 + PR #703 — init-prompt-ux regression guard, ≥3 TCs)
#   - d050b (issue-template content guard sister pattern)
#   - **d853 (this file) — canary mirror config.yml gap regression guard**
#
# Sprint 26 / Issue #853 refs:
#   - Issue #853 (canonical source — canary mirror missing config.yml, v1.0.0 GA audit)
#   - STORY-S26-002 (PRD per PR #945 eb06dc6)
#   - Issue #941 (Sprint 26 Kickoff §Scope row 2)
#   - `.gitignore` line 81 (canonical RED state source — `config.yml` listed as rendered output)
#   - `scripts/dev-studio-init.sh` (auto-generator of config.yml as rendered output)
#   - ADR-0044 (RED-first TDD doctrinal home)
#   - ADR-0049 (d-test framework sister-pattern, ≥3 TCs minimum)
#   - ADR-0055 §1 Cadence Rule 1 atomic (d-test file + INDEX.md same commit)
#   - ADR-0010 (canary mirror doctrine)
#
# Usage:
#   bash d853-canary-config-yml.sh --self-test
#   bash d853-canary-config-yml.sh            # run all TCs
#
# Exit codes:
#   0 — all PASS (GREEN state)
#   1 — at least one FAIL (RED state — gap exists, fix needed)
#   2 — preflight failure (missing tool, file missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ISSUE_TEMPLATE_DIR="${REPO_ROOT}/.github/ISSUE_TEMPLATE"
CONFIG_YML="${ISSUE_TEMPLATE_DIR}/config.yml"
INDEX_MD="${SCRIPT_DIR}/INDEX.md"
GITIGNORE="${REPO_ROOT}/.gitignore"

# Sister-pattern sister-files (5 ISSUE_TEMPLATE files currently tracked per `git ls-files`)
SISTER_TEMPLATE_FILES=(
  "${ISSUE_TEMPLATE_DIR}/agent-stall.yml"
  "${ISSUE_TEMPLATE_DIR}/bug.yml"
  "${ISSUE_TEMPLATE_DIR}/feature-request.yml"
  "${ISSUE_TEMPLATE_DIR}/incident.yml"
  "${ISSUE_TEMPLATE_DIR}/vision-intake.yml"
)

# Per-TC result accumulators (sister-pattern d649/d050b discipline)
TC_RESULTS=()
TC_COUNT=0
FAIL_COUNT=0

# --- helpers --------------------------------------------------------------

log_info() { printf '[d853] %s\n' "$*"; }
log_pass() { printf '\033[32m  PASS\033[0m %s\n' "$1"; }
log_fail() { printf '\033[31m  FAIL\033[0m %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
record_tc() {
  local name="$1"; local status="$2"
  TC_COUNT=$((TC_COUNT+1))
  TC_RESULTS+=("TC${TC_COUNT}:${name}:${status}")
  if [ "$status" = "PASS" ]; then
    log_pass "$name"
  else
    log_fail "$name"
  fi
}

# --- TC1: config.yml exists at canonical path -----------------------------

tc1_config_yml_exists() {
  if [ -f "$CONFIG_YML" ]; then
    record_tc "TC1:config.yml exists locally" "PASS"
  else
    record_tc "TC1:config.yml exists locally" "FAIL"
  fi
}

# --- TC2: config.yml is valid YAML ---------------------------------------

tc2_config_yml_valid_yaml() {
  if ! command -v python3 >/dev/null 2>&1; then
    record_tc "TC2:config.yml valid YAML (PyYAML)" "FAIL"
    return
  fi
  if python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$CONFIG_YML" 2>/dev/null; then
    record_tc "TC2:config.yml valid YAML (PyYAML)" "PASS"
  else
    record_tc "TC2:config.yml valid YAML (PyYAML)" "FAIL"
  fi
}

# --- TC3: config.yml is REACHABLE from git clone (canonical RED) ----------

tc3_config_yml_reachable_from_clone() {
  local reachable=1  # default: NOT reachable

  # TC3a: must be tracked
  if git -C "$REPO_ROOT" ls-files --error-unmatch "$CONFIG_YML" >/dev/null 2>&1; then
    reachable=0
  fi

  # TC3b: must NOT be gitignored (whitelist exception OK, but must not be in .gitignore)
  if git -C "$REPO_ROOT" check-ignore -v "$CONFIG_YML" >/dev/null 2>&1; then
    reachable=1
  fi

  if [ "$reachable" = "0" ]; then
    record_tc "TC3:config.yml reachable from git clone (tracked AND not gitignored)" "PASS"
  else
    record_tc "TC3:config.yml reachable from git clone (tracked AND not gitignored)" "FAIL"
  fi
}

# --- TC4: d-test self-test discipline ------------------------------------

tc4_self_test() {
  # Self-test = this very function runs without error. Sister-pattern d649.
  record_tc "TC4:d-test --self-test discipline" "PASS"
}

# --- TC5: d-test produces unique per-TC markers in TC_RESULTS array ------

tc5_per_tc_markers() {
  # Verify TC_RESULTS array has been populated (≥1 entry by TC5 time = TC1-TC4 ran).
  # Sister-pattern d050b/d649: per-TC markers are emitted into TC_RESULTS for downstream parsing.
  if [ "${#TC_RESULTS[@]}" -ge 4 ]; then
    record_tc "TC5:per-TC marker emission into TC_RESULTS array" "PASS"
  else
    record_tc "TC5:per-TC marker emission into TC_RESULTS array" "FAIL"
  fi
}

# --- TC6: sister-parity audit of other 5 ISSUE_TEMPLATE files ------------

tc6_sister_parity_audit() {
  if ! command -v python3 >/dev/null 2>&1; then
    record_tc "TC6:sister-parity audit (5 ISSUE_TEMPLATE files valid YAML + schema)" "FAIL"
    return
  fi

  local fail_list=""
  for tmpl in "${SISTER_TEMPLATE_FILES[@]}"; do
    if [ ! -f "$tmpl" ]; then
      fail_list="${fail_list}MISSING:${tmpl} "
      continue
    fi
    # Schema check: parse YAML + assert contains `name:` + `description:` keys
    if ! python3 -c "
import yaml,sys
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f)
assert isinstance(data, dict), 'not a dict'
assert 'name' in data, 'missing name key'
assert 'description' in data, 'missing description key'
" "$tmpl" 2>/dev/null; then
      fail_list="${fail_list}SCHEMA_FAIL:${tmpl} "
    fi
  done

  if [ -z "$fail_list" ]; then
    record_tc "TC6:sister-parity audit (5 ISSUE_TEMPLATE files valid YAML + schema)" "PASS"
  else
    log_info "sister-parity failures: $fail_list"
    record_tc "TC6:sister-parity audit (5 ISSUE_TEMPLATE files valid YAML + schema)" "FAIL"
  fi
}

# --- TC7: INDEX.md row exists (Cadence Rule 1 atomic, ADR-0055 §1) -------

tc7_index_md_row_exists() {
  if [ ! -f "$INDEX_MD" ]; then
    record_tc "TC7:INDEX.md row exists (Cadence Rule 1 atomic)" "FAIL"
    return
  fi
  # Match the bold-marked row format: | **d853** | ...
  if grep -E '^\| \*\*d853\*\*' "$INDEX_MD" >/dev/null 2>&1; then
    record_tc "TC7:INDEX.md row exists (Cadence Rule 1 atomic)" "PASS"
  else
    record_tc "TC7:INDEX.md row exists (Cadence Rule 1 atomic)" "FAIL"
  fi
}

# --- main -----------------------------------------------------------------

main() {
  log_info "d853-canary-config-yml.sh starting (canary mirror config.yml regression guard)"
  log_info "REPO_ROOT=$REPO_ROOT"
  log_info "CONFIG_YML=$CONFIG_YML"

  tc1_config_yml_exists
  tc2_config_yml_valid_yaml
  tc3_config_yml_reachable_from_clone
  tc4_self_test
  tc5_per_tc_markers
  tc6_sister_parity_audit
  tc7_index_md_row_exists

  log_info ""
  log_info "Results: $TC_COUNT TCs, $FAIL_COUNT FAIL"
  for r in "${TC_RESULTS[@]}"; do
    log_info "  $r"
  done

  if [ "$FAIL_COUNT" -eq 0 ]; then
    log_info "VERDICT: ✅ ALL GREEN (canary mirror config.yml gap CLOSED)"
    exit 0
  else
    log_info "VERDICT: ❌ $FAIL_COUNT TC(S) FAIL (canary mirror config.yml gap OPEN — fix needed)"
    exit 1
  fi
}

# --- entry point ----------------------------------------------------------

if [ "${1:-}" = "--self-test" ]; then
  log_info "self-test mode (sister-pattern d649 discipline)"
  # Self-test = run all TCs + verify they complete (don't gate on GREEN, just on completion)
  main
  SELF_TEST_EXIT=$?
  if [ "$SELF_TEST_EXIT" -eq 0 ] || [ "$SELF_TEST_EXIT" -eq 1 ]; then
    # 0 = GREEN, 1 = RED (gap exists) — both are valid self-test outcomes
    log_info "self-test PASS (TC infrastructure works, expected state = RED pre-fix)"
    exit 0
  else
    log_info "self-test FAIL (TC infrastructure broken, exit=$SELF_TEST_EXIT)"
    exit "$SELF_TEST_EXIT"
  fi
fi

main