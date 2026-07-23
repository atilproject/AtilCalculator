#!/usr/bin/env bash
# agent-stall-detect.sh — Issue #1183 Dev-pane pickup stall detection.
#
# Detects developer-lane stalls: an issue with `agent:developer + status:in-progress`
# that has had no PR opened in >24h. Per RETRO-032 lesson #2 (Sprint 32 final wave
# dev pane went silent for ~36h after claiming S32-019 cluster — root cause was
# tmux pane on the wrong working directory + no recovery signal).
#
# Detection rule (PR-driven, Issue #1183 spec):
#   STALL iff: issue has `agent:developer` + `status:in-progress` + state=open
#              AND no PR linked to issue (any state) in last `threshold` hours
#              AND issue `updatedAt` is older than `threshold` hours
#
# NOT-stall signals (edge cases, sister to wip-idle-detect signal 5):
#   1. Linked PR found in last threshold hours (open or merged) — active work
#   2. Issue has `status:in-review` label — PR already up, awaiting verdict
#   3. Issue has `status:blocked` label — legitimate block, not stall
#
# Out of scope (deferred to Sprint 34+ per Issue #1183 sister-issues):
#   - Cross-role stall detection (PM/arch/tester stalls)
#   - Auto-claim rescue (re-assign stalled issue via claim-next-ready.sh)
#   - Stall root-cause classification (env-rot vs cwd-boundary vs pane-silence)
#
# Usage:
#   bash scripts/agent-stall-detect.sh                      # scan dev lane, default 24h threshold
#   bash scripts/agent-stall-detect.sh --threshold 48      # override 24h threshold (debug)
#   bash scripts/agent-stall-detect.sh --role developer     # explicit role (single-lane today)
#   bash scripts/agent-stall-detect.sh --dry-run           # print stalls without notify emission
#
# Output (stdout): JSON array
#   [ {"issue":1180, "title":"...", "stall_hours":25, "linked_pr":null, "last_pr_min":-1}, ... ]
#
# Exit codes:
#   0  scan completed (regardless of stall count)
#   1  usage error (invalid role, missing --)
#   2  gh API error (network/auth/jq failure)
#   3  preflight fail (gh/jq not in PATH)
#
# Env:
#   STALL_DETECT_THRESHOLD_HOURS  override threshold hours (default: 24, Issue #1183 spec)
#   GITHUB_REPO                   override repo (default: gh repo view)
#   DRY_RUN                       when set, skip notify.sh emission (default: unset)
#
# Reference: Issue #1183 spec + RETRO-032 lesson #2 + scripts/wip-idle-detect.sh
#            (sister-pattern, signal-driven 30m threshold, all 5 roles).

set -uo pipefail

ROLE_FLAG=""
THRESHOLD_HOURS="${STALL_DETECT_THRESHOLD_HOURS:-24}"
DRY_RUN="${DRY_RUN:-}"

# --- arg parse ---
while [ $# -gt 0 ]; do
  case "$1" in
    --role)         ROLE_FLAG="$2"; shift 2 ;;
    --threshold)    THRESHOLD_HOURS="$2"; shift 2 ;;
    --dry-run)      DRY_RUN="1"; shift ;;
    -h|--help)
      sed -n '2,30p' "$0"; exit 0 ;;
    *)
      echo "usage: agent-stall-detect.sh [--role <role>] [--threshold <hours>] [--dry-run]" >&2
      echo "  role: developer (default; only lane currently in scope per Issue #1183 spec)" >&2
      exit 1
      ;;
  esac
done

# --- preflight ---
command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI required" >&2; exit 3; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 3; }

# --- repo detection ---
# Sister-pattern: wip-idle-detect.sh repo detection — but with env-pollution
# guard (Issue #1183 cycle ~#3968Q+213 sister): GITHUB_REPO may be set to a
# bare name (e.g., "AtilCalculator") from earlier session contamination. Only
# accept GITHUB_REPO if it contains "/" (i.e., looks like owner/name).
REPO=""
if [ -n "${GITHUB_REPO:-}" ] && [[ "${GITHUB_REPO}" == *"/"* ]]; then
  REPO="${GITHUB_REPO}"
fi
if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi
if [ -z "$REPO" ] || [[ "$REPO" != *"/"* ]]; then
  echo "ERROR: cannot detect repo (got '$REPO'). Set GITHUB_REPO=owner/name." >&2
  exit 2
fi

# --- role list (Issue #1183 spec: developer-only; cross-role deferred to Sprint 34+) ---
ALL_ROLES="developer"
if [ -n "$ROLE_FLAG" ]; then
  case "$ROLE_FLAG" in
    developer) ROLES="$ROLE_FLAG" ;;
    *) echo "ERROR: invalid role: $ROLE_FLAG (only 'developer' in scope per Issue #1183)" >&2; exit 1 ;;
  esac
else
  ROLES="$ALL_ROLES"
fi

# --- helper: ISO timestamp → epoch hours (integer) ---
iso_to_hours() {
  local iso="$1"
  local now_epoch="$2"
  local iso_epoch
  iso_epoch="$(date -u -d "$iso" +%s 2>/dev/null || echo 0)"
  if [ "$iso_epoch" = "0" ]; then echo "-1"; return; fi
  echo $(( (now_epoch - iso_epoch) / 3600 ))
}

# --- helper: ISO timestamp → epoch minutes (for last_pr_min reporting) ---
iso_to_min() {
  local iso="$1"
  local now_epoch="$2"
  local iso_epoch
  iso_epoch="$(date -u -d "$iso" +%s 2>/dev/null || echo 0)"
  if [ "$iso_epoch" = "0" ]; then echo "-1"; return; fi
  echo $(( (now_epoch - iso_epoch) / 60 ))
}

now_epoch="$(date -u +%s)"
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
threshold_min=$(( THRESHOLD_HOURS * 60 ))

# --- main scan ---
stall_json="[]"
for role in $ROLES; do
  # Fetch WIP items for this role
  wip_issues="$(gh issue list \
    --repo "$REPO" \
    --label "agent:${role}" \
    --label "status:in-progress" \
    --state open \
    --limit 50 \
    --json number,title,updatedAt,labels 2>/dev/null)" || { echo "ERROR: gh API error (WIP query for $role)" >&2; exit 2; }

  for issue_n in $(echo "$wip_issues" | jq -r '.[].number'); do
    # Edge case 2: status:in-review → NOT stalled (PR up, awaiting verdict)
    has_in_review="$(echo "$wip_issues" | jq -r --argjson n "$issue_n" '.[] | select(.number == $n) | .labels[] | select(.name == "status:in-review") | .name' 2>/dev/null || echo "")"
    if [ -n "$has_in_review" ]; then
      continue
    fi

    # Edge case 3: status:blocked → NOT stalled (legitimate block)
    has_blocked="$(echo "$wip_issues" | jq -r --argjson n "$issue_n" '.[] | select(.number == $n) | .labels[] | select(.name == "status:blocked") | .name' 2>/dev/null || echo "")"
    if [ -n "$has_blocked" ]; then
      continue
    fi

    # Detection rule: PR-driven — find any PR linked to issue
    # Sister-pattern: wip-idle-detect.sh uses a `<N>:<ISSUE>` style search
    # qualifier for linked PRs but that approach is BROKEN in `gh` CLI v2.x
    # (returns ALL PRs instead of filtering). Cycle ~#3968Q+213 sister-pattern:
    # use `{N} in:body` search qualifier which correctly filters PRs whose body
    # references the issue number (covers Closes #N, Refs #N, Fixes #N, or any
    # body mention). Verified at AtilCalculator #1180: broken linked-search
    # returned 30 PRs vs in:body returned 3 PRs (correct).
    linked_pr_json="$(gh pr list \
      --repo "$REPO" \
      --state all \
      --search "${issue_n} in:body" \
      --json number,state,createdAt,updatedAt,mergedAt \
      --limit 20 2>/dev/null || echo '[]')"

    linked_pr_count="$(echo "$linked_pr_json" | jq 'length' 2>/dev/null || echo 0)"
    last_pr_min="-1"
    linked_pr_num="null"

    if [ "$linked_pr_count" -gt 0 ]; then
      # Find most recent PR activity (created/updated/merged), whichever is latest
      last_activity_iso="$(echo "$linked_pr_json" | jq -r '
        [.[] | (.mergedAt // .updatedAt // .createdAt)]
        | max
      ' 2>/dev/null || echo "")"
      if [ -n "$last_activity_iso" ] && [ "$last_activity_iso" != "null" ]; then
        last_pr_min="$(iso_to_min "$last_activity_iso" "$now_epoch")"
      fi
      # Most recent PR number for reporting
      linked_pr_num="$(echo "$linked_pr_json" | jq -r '
        sort_by(.createdAt) | reverse | .[0].number
      ' 2>/dev/null || echo "null")"
    fi

    # Get issue update time for stall_hours calc
    issue_updated_iso="$(echo "$wip_issues" | jq -r --argjson n "$issue_n" '.[] | select(.number == $n) | .updatedAt' 2>/dev/null || echo "")"
    issue_stall_hours="-1"
    if [ -n "$issue_updated_iso" ] && [ "$issue_updated_iso" != "null" ]; then
      issue_stall_hours="$(iso_to_hours "$issue_updated_iso" "$now_epoch")"
    fi

    # STALL iff:
    #   - issue updatedAt older than threshold
    #   - AND last_pr_min is missing (-1) OR older than threshold (in minutes)
    is_stalled="false"
    if [ "$issue_stall_hours" -ge "$THRESHOLD_HOURS" ]; then
      if [ "$last_pr_min" -eq "-1" ] || [ "$last_pr_min" -ge "$threshold_min" ]; then
        is_stalled="true"
      fi
    fi

    if [ "$is_stalled" = "true" ]; then
      issue_title="$(echo "$wip_issues" | jq -r --argjson n "$issue_n" '.[] | select(.number == $n) | .title' 2>/dev/null || echo "")"
      stall_json="$(echo "$stall_json" | jq \
        --argjson n "$issue_n" \
        --arg t "$issue_title" \
        --argjson sh "$issue_stall_hours" \
        --argjson lpm "$last_pr_min" \
        --argjson lpn "$linked_pr_num" \
        --arg now "$now_iso" \
        '. + [{
          issue: $n,
          title: $t,
          agent: "developer",
          status: "in-progress",
          stall_hours: $sh,
          last_pr_min: $lpm,
          linked_pr: $lpn,
          detected_at: $now
        }]')"
    fi
  done
done

# --- output ---
if [ -n "$DRY_RUN" ]; then
  echo "$stall_json" | jq .
  exit 0
fi

# Production: emit JSON for orchestrator's wake loop to consume
echo "$stall_json" | jq .

# Optional: trigger notify.sh if any stall detected (orchestrator integration)
# Per Issue #1183 spec: peer-poke developer + orchestrator (this script's caller
# is orchestrator, so we only notify dev). Wave coalesce: if ≥3 stalls, single
# `[ORCH→DEV] stall wave: #N1, #N2, #N3` instead of N individual pings. Wave
# logic lives in scripts/agent-watch.sh's stall integration block (coalesces
# across stalls before dispatching notify.sh). This helper emits per-stall
# JSON; the watcher is responsible for the wave.
stall_total="$(echo "$stall_json" | jq 'length' 2>/dev/null || echo 0)"
if [ "$stall_total" -ge 1 ] && [ "${STALL_DETECT_AUTO_NOTIFY:-0}" = "1" ]; then
  for issue_n in $(echo "$stall_json" | jq -r '.[].issue'); do
    stall_h="$(echo "$stall_json" | jq -r --argjson n "$issue_n" '.[] | select(.issue == $n) | .stall_hours')"
    notify_msg="[STALL-DETECT] dev lane: Issue #${issue_n} stalled ${stall_h}h (no PR opened in >${THRESHOLD_HOURS}h threshold)"
    bash "$(dirname "$0")/notify.sh" -l developer "$notify_msg" >/dev/null 2>&1 || true
  done
fi

exit 0
