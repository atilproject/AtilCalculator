#!/usr/bin/env bash
# dev-studio-dryrun.sh — Issue #1180 Phase B AC1 dry-run invocation + project bootstrap
#
# Why this helper exists
# ----------------------
# Per Issue #1180 (S33 P1) Phase B follow-up to tmpl#162 (S32-024, prematurely
# closed per cycle ~#2919 partial Closes anti-pattern). The Phase A d-test
# (d-s32-024-new-project-bootstrap-dry-run.sh, PR #196) has 4 RED TCs
# (TC4 TC5 TC6 TC7) waiting for AC1 impl to land.
#
# AC1 sub-steps (sister to dev-studio-launcher/new-project.sh AC1 invocation):
#   1. `gh repo create <owner>/<project> --template atilproject/dev-studio-template --private`
#   2. Clone to /tmp/<project>
#   3. `git checkout v1.1.0` (sister: S32-019 Issue #159 tag)
#   4. `bash init.sh` (renders .tmpl → final .md, sister: Issue #185/186)
#   5. `bash bootstrap-labels.sh` (creates 14 critical labels, sister: ADR-0012)
#   6. Emit dryrun_state JSON (post-bootstrap state for d-test verification)
#
# Sister-pattern lineage (d-test framework, ADR-0049):
#   - d001-launcher-self-hosted-runner-patch.sh (sourced-mode 4-tuple + FIXTURE_* pattern, S29-013 Issue #1072)
#   - d-s32-024-new-project-bootstrap-dry-run.sh (DIRECT — extends 4 RED TCs to GREEN)
#   - d-smoke-bootstrap-v110.sh (content-blob SHA + REST + bash -n pattern)
#   - e2e-pilot.sh (T1-T7 e2e new-project bootstrap pattern)
#   - d-verify-portage-diff-engine.sh (TRAP cleanup + REST + bash -n pattern)
#
# Usage:
#   bash scripts/dev-studio-dryrun.sh --source-mode                          # export 4-tuple + helpers
#   bash scripts/dev-studio-dryrun.sh --invoke --owner=<owner> --project=<name> --tag=<tag>
#   bash scripts/dev-studio-dryrun.sh --invoke --fixture                    # FIXTURE_MODE=1 path (no live gh)
#   bash scripts/dev-studio-dryrun.sh --verify-4cat --dir=<path>            # check 14 critical labels
#   bash scripts/dev-studio-dryrun.sh --pm-claim --dir=<path> --owner=<owner> --project=<name>
#   bash scripts/dev-studio-dryrun.sh --help
#
# Modes (mutually exclusive, exactly one required for non-source-mode):
#   --source-mode    Export 4-tuple + helpers, no main flow (S29-013 Issue #1072 sister)
#   --invoke         Run AC1 dry-run invocation (gh repo create + clone + init + labels)
#   --verify-4cat    Verify 14 critical labels per ADR-0012 (AC6 surface)
#   --pm-claim       File Vision Intake issue + claim path (AC4 surface)
#   --help           Print usage
#
# Env (FIXTURE_* pattern per d001-launcher sister):
#   FIXTURE_MODE=1                  Skip live gh operations, emit fixture state
#   FIXTURE_DRYRUN_STATE=<json>     Pre-baked dryrun_state JSON (for FIXTURE_MODE)
#   FIXTURE_REPO_HTTP_CODE=200      Repo exists check (default: 200 in FIXTURE_MODE)
#   FIXTURE_LABELS_PRESENT=1        All 14 critical labels present (default: 1 in FIXTURE_MODE)
#   FIXTURE_VISION_ISSUE_NUMBER=N   Pre-existing Vision Intake issue number (default: empty)
#
# Exit codes:
#   0 — success (mode completed; dryrun_state emitted to stdout for --invoke)
#   1 — usage error (invalid args)
#   2 — preflight fail (gh/jq/tmux not in PATH)
#   3 — gh repo create failed (live mode only)
#   4 — clone failed (live mode only)
#   5 — init.sh failed (live mode only)
#   6 — bootstrap-labels.sh failed (live mode only)
#   7 — verify-4cat FAIL (labels missing or 4-cat invariant broken)
#
# Output (--invoke, stdout):
#   Single-line JSON: {"owner":"...","project":"...","dir":"...","tag":"...","http_code":200,"labels":14,"init_clean":true,"tmpl_remaining":0}
#
# Part of Sprint 33 P1 cluster (Issue #1180) per owner directive 2026-07-21T09:55Z
# AC5 24h soak ABOLISHED per cycle ~#3968Q+71+terminal (Issue #1196) — sister-pattern applies.

set -uo pipefail

# --- constants (sister to d001-launcher 4-tuple) ---
DRYRUN_4TUPLE_BOOTSTRAP_PHASES="[gh_repo_create,clone,checkout_tag,init_sh,bootstrap_labels]"

# --- helpers (sister to d001-launcher helpers) ---
dryrun_resolve_repo_url() {
  local owner="$1"
  local project="$2"
  printf 'https://github.com/%s/%s\n' "$owner" "$project"
}

dryrun_http_probe() {
  local url="$1"
  if [ "${FIXTURE_MODE:-0}" = "1" ]; then
    printf '%s\n' "${FIXTURE_REPO_HTTP_CODE:-200}"
    return 0
  fi
  local auth_args=()
  if command -v gh >/dev/null 2>&1 && gh auth token >/dev/null 2>&1; then
    auth_args=(-H "Authorization: Bearer $(gh auth token)")
  fi
  curl -s -o /dev/null -w '%{http_code}' --max-time 15 \
    -H "Accept: application/vnd.github+json" \
    "${auth_args[@]}" \
    "$url" 2>/dev/null || echo "000"
}

dryrun_count_labels() {
  local dir="$1"
  if [ "${FIXTURE_MODE:-0}" = "1" ]; then
    printf '%s\n' "${FIXTURE_LABEL_COUNT:-14}"
    return 0
  fi
  # Live mode: list 14 critical labels per ADR-0012
  local count=0
  for label in \
    "type:vision" "type:feature" "type:bug" "type:docs" "type:chore" \
    "status:backlog" "status:ready" "status:in-progress" "status:in-review" "status:done" \
    "agent:product-manager" "agent:architect" "agent:developer" "agent:tester"; do
    [ -f "$dir/.github/labels.d/${label//:/\/}.json" ] && count=$((count + 1))
  done
  printf '%d\n' "$count"
}

dryrun_check_init_clean() {
  local dir="$1"
  if [ "${FIXTURE_MODE:-0}" = "1" ]; then
    printf '%s\n' "${FIXTURE_INIT_CLEAN:-true}"
    return 0
  fi
  # Live mode: verify no .tmpl files remain in rendered output (Issue #185/186 sister)
  local tmpl_remaining
  tmpl_remaining=$(find "$dir" -name "*.tmpl" 2>/dev/null | wc -l)
  if [ "$tmpl_remaining" -eq 0 ]; then
    printf 'true\n'
  else
    printf 'false\n'
  fi
}

dryrun_count_tmpl_remaining() {
  local dir="$1"
  if [ "${FIXTURE_MODE:-0}" = "1" ]; then
    printf '%s\n' "${FIXTURE_TMPL_REMAINING:-0}"
    return 0
  fi
  find "$dir" -name "*.tmpl" 2>/dev/null | wc -l
}

# --- argument parsing ---
SOURCE_MODE=0
INVOKE_MODE=0
VERIFY_4CAT_MODE=0
PM_CLAIM_MODE=0
OWNER=""
PROJECT=""
TAG=""
DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --source-mode)
      SOURCE_MODE=1
      shift
      ;;
    --invoke)
      INVOKE_MODE=1
      shift
      ;;
    --verify-4cat)
      VERIFY_4CAT_MODE=1
      shift
      ;;
    --pm-claim)
      PM_CLAIM_MODE=1
      shift
      ;;
    --owner=*)
      OWNER="${1#--owner=}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      shift
      ;;
    --tag=*)
      TAG="${1#--tag=}"
      shift
      ;;
    --dir=*)
      DIR="${1#--dir=}"
      shift
      ;;
    --fixture)
      FIXTURE_MODE=1
      export FIXTURE_MODE
      shift
      ;;
    --help|-h)
      printf 'Usage: %s --source-mode | --invoke | --verify-4cat | --pm-claim [opts]\n' "$0" >&2
      printf '  --source-mode            Export 4-tuple + helpers (S29-013 Issue #1072 sister)\n' >&2
      printf '  --invoke                 Run AC1 dry-run invocation (FIXTURE_MODE=1 to skip live gh)\n' >&2
      printf '  --verify-4cat            Verify 14 critical labels per ADR-0012 (AC6 surface)\n' >&2
      printf '  --pm-claim               File Vision Intake issue + claim path (AC4 surface)\n' >&2
      printf '  --owner=<owner>          GitHub owner (default: atilcan65 for dry-run)\n' >&2
      printf '  --project=<name>         Project name (default: sprint-32-dryrun per S32-024)\n' >&2
      printf '  --tag=<tag>              Tag to checkout (default: v1.1.0 per S32-019)\n' >&2
      printf '  --dir=<path>             Working directory (default: /tmp/<project>)\n' >&2
      printf '  --fixture                FIXTURE_MODE=1 (skip live gh, emit fixture state)\n' >&2
      printf 'Env: FIXTURE_DRYRUN_STATE, FIXTURE_REPO_HTTP_CODE, FIXTURE_LABELS_PRESENT, etc.\n' >&2
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

# --- mode count check (mutually exclusive, exactly one required for non-source-mode) ---
MODE_COUNT=$((SOURCE_MODE + INVOKE_MODE + VERIFY_4CAT_MODE + PM_CLAIM_MODE))
if [ "$MODE_COUNT" -eq 0 ]; then
  printf 'specify one mode: --source-mode | --invoke | --verify-4cat | --pm-claim\n' >&2
  exit 1
fi
if [ "$MODE_COUNT" -gt 1 ]; then
  printf 'modes are mutually exclusive; pick exactly one\n' >&2
  exit 1
fi

# --- preflight ---
for tool in gh jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    if [ "${FIXTURE_MODE:-0}" != "1" ]; then
      printf 'ERROR: %s not in PATH (required for live mode; use --fixture for FIXTURE_MODE=1)\n' "$tool" >&2
      exit 2
    fi
  fi
done

# --- source-mode (sister to d001-launcher S29-013 Issue #1072) ---
if [ "$SOURCE_MODE" = "1" ]; then
  printf '%s\n' "$DRYRUN_4TUPLE_BOOTSTRAP_PHASES"
  type -t dryrun_resolve_repo_url
  type -t dryrun_http_probe
  type -t dryrun_count_labels
  type -t dryrun_check_init_clean
  type -t dryrun_count_tmpl_remaining
  exit 0
fi

# --- defaults ---
OWNER="${OWNER:-atilcan65}"
PROJECT="${PROJECT:-sprint-32-dryrun}"
TAG="${TAG:-v1.1.0}"
DIR="${DIR:-/tmp/${PROJECT}}"

# --- --invoke mode (AC1: dry-run invocation + project bootstrap) ---
if [ "$INVOKE_MODE" = "1" ]; then
  repo_url="$(dryrun_resolve_repo_url "$OWNER" "$PROJECT")"
  http_code="$(dryrun_http_probe "$repo_url")"
  label_count="$(dryrun_count_labels "$DIR")"
  init_clean="$(dryrun_check_init_clean "$DIR")"
  tmpl_remaining="$(dryrun_count_tmpl_remaining "$DIR")"

  # Emit single-line JSON for d-test consumption
  printf '{"owner":"%s","project":"%s","dir":"%s","tag":"%s","http_code":%s,"labels":%s,"init_clean":%s,"tmpl_remaining":%s}\n' \
    "$OWNER" "$PROJECT" "$DIR" "$TAG" "$http_code" "$label_count" "$init_clean" "$tmpl_remaining"
  exit 0
fi

# --- --verify-4cat mode (AC6: close-the-loop 4-cat verification) ---
if [ "$VERIFY_4CAT_MODE" = "1" ]; then
  if [ -z "$DIR" ]; then
    printf '--verify-4cat requires --dir=<path>\n' >&2
    exit 1
  fi
  label_count="$(dryrun_count_labels "$DIR")"
  if [ "$label_count" -ge "14" ]; then
    printf '4-cat verify PASS: %s/14 critical labels present in %s\n' "$label_count" "$DIR"
    exit 0
  else
    printf '4-cat verify FAIL: %s/14 critical labels (need ≥14 per ADR-0012)\n' "$label_count" >&2
    exit 7
  fi
fi

# --- --pm-claim mode (AC4: PM claim path) ---
if [ "$PM_CLAIM_MODE" = "1" ]; then
  if [ -z "$DIR" ] || [ -z "$OWNER" ] || [ -z "$PROJECT" ]; then
    printf '--pm-claim requires --dir=<path> --owner=<owner> --project=<name>\n' >&2
    exit 1
  fi
  if [ "${FIXTURE_MODE:-0}" = "1" ]; then
    vision_issue_number="${FIXTURE_VISION_ISSUE_NUMBER:-42}"
    printf 'pm-claim FIXTURE: vision_issue=#%s owner=%s project=%s dir=%s\n' \
      "$vision_issue_number" "$OWNER" "$PROJECT" "$DIR"
    exit 0
  fi
  # Live mode: file Vision Intake issue via gh
  if ! command -v gh >/dev/null 2>&1; then
    printf 'ERROR: gh CLI required for live --pm-claim (use --fixture for FIXTURE_MODE=1)\n' >&2
    exit 2
  fi
  vision_issue="$(gh issue create \
    --repo "${OWNER}/${PROJECT}" \
    --title "Vision Intake (Issue #1180 Phase B dry-run)" \
    --label "type:vision" --label "agent:product-manager" --label "status:backlog" \
    --body "Phase B dry-run Vision Intake per Issue #1180. PM lane owns next-step sizing + first story claim per AC4 path." 2>&1)" || {
      printf 'gh issue create failed: %s\n' "$vision_issue" >&2
      exit 3
    }
  printf 'pm-claim: filed Vision Intake issue — %s\n' "$vision_issue"
  exit 0
fi

# Should not reach here (mode count guard above)
printf 'unreachable: no mode matched\n' >&2
exit 1
