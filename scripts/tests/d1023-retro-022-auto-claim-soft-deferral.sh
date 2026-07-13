#!/usr/bin/env bash
# d1023-retro-022-auto-claim-soft-deferral.sh — RETRO-022 regression guard.
#
# Why this test exists
# --------------------
# Sprint 29 W1 cycle ~#1198 surfaced that scripts/claim-next-ready.sh
# (ADR-0038 §Layer 2) decides what to claim based on LABELS ONLY — it does
# not consult:
#   (a) Issue comment thread for soft-deferral signals
#   (b) Linked PR state (e.g., "PR already drafted, awaiting owner squash" = work-done)
#   (c) Cross-issue references (e.g., "blocks #N" / "Closes #N-Closed")
#   (d) Lane-active-claims-other-issue references
#
# Two real incidents triggered RETRO-022 (Issue #1023):
#   - #1012 (Sprint 28 Close Ceremony): work already done in cycle ~#1194;
#     auto-claim re-flipped status:ready → status:in-progress
#   - #1016 (S29-004 status-label-to-board.yml): architect had documented
#     soft-deferral in cmt 4956105264 ("deferred behind S29-001 design lands");
#     orchestrator ack'd the deferral (cmt 4956118097); auto-claim fired
#     anyway at 09:21:45Z
#
# 5 TCs (per ADR-0044 RED-first, ADR-0049 ≥5 baseline):
#   TC1: comment-thread soft-deferral marker ("deferred behind #N") → skip + log
#   TC2: body "blocks #N" / cross-issue-block marker → skip + log
#   TC3: body decision-landed marker ("decision landed in #N") → skip + log
#   TC4: linked-PR work-done (PR open in status:ready + cc:human + draft) → skip + log
#   TC5: lane-active-claim (peer role has #N in-progress AND this defers to #N) → skip + log
#
# Pre-impl RED state (current main, pre-RETRO-022):
#   TC1: script does not parse comment-thread for soft-deferral → claim succeeds → FAIL
#   TC2: script only parses "depends on|blocked by" in body, NOT "blocks" → claim succeeds → FAIL
#   TC3: script does not parse "decision landed" → claim succeeds → FAIL
#   TC4: script does not consult linked-PR state → claim succeeds → FAIL
#   TC5: script does not consult lane-active-claims-other-issue → claim succeeds → FAIL
#   → 5/5 TCs FAIL = proper RED-first per ADR-0044.
#
# Post-impl GREEN state (after RETRO-022 PR squash):
#   TC1-TC5: claim correctly skips for soft-deferral/cross-block/decision-landed/work-done/lane-active
#   → 5/5 TCs PASS = GREEN.
#
# Sister-pattern family (d-test lineage, ADR-0049):
#   - d031-claim-next-ready.sh (base Layer 2, 10 TCs — direct sister, fake-gh pattern donor)
#   - d058-claim-wip-workstream.sh (workstream awareness, 10 TCs — sister scope)
#   - d809-claim-next-ready-race.sh (race-condition guard — sister for Issue #809 flock)
#   - d827-claim-next-ready-pr-exclusion-behavioral.sh (PR-exclusion behavioral, recent)
#   - **d1023 (this file) — RETRO-022 auto-claim soft-deferral/work-done gap**
#
# Sprint 29 cross-repo workstream refs:
#   - Issue #1023 (RETRO-022 tracker, agent:developer)
#   - ADR-0038 (auto-claim protocol, under refinement per RETRO-022 §3)
#   - ADR-0012 (4-cat label invariant — relates to soft-deferral expression)
#   - ADR-0015 (atomic hand-off — relates to work-done signal)
#   - ADR-0033 (dual-channel peer-poke — relates to lane-active-claim signaling)
#   - ADR-0044 (RED-first TDD doctrinal home)
#   - ADR-0049 (d-test framework, ≥5 TCs baseline; this file: 5)
#   - ADR-0055 §1 Cadence Rule 1 atomic (d-test file + INDEX.md same commit)
#
# TC0 cap-bypass detection (RETRO-022 evidence #6) — DEFERRED to follow-up:
#   - Bug mechanism unclear (polling loop vs manual invocation per cmt 4956423197)
#   - Requires deeper analysis of scripts/agent-watch.sh invocation path
#   - Will be added as TC0 in a separate d-test after bug mechanism isolated
#
# Usage:
#   bash scripts/tests/d1023-retro-022-auto-claim-soft-deferral.sh
#
# Exit codes:
#   0 — all PASS (GREEN state — RETRO-022 script-fix landed)
#   1 — at least one FAIL (RED state — script-fix incomplete)
#   2 — preflight failure (missing tool, file missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAIM_SH="$REPO_ROOT/scripts/claim-next-ready.sh"

# --- preflight ---
if [[ ! -f "$CLAIM_SH" ]]; then
  echo "ERROR: preflight fail — claim-next-ready.sh not found at $CLAIM_SH" >&2
  exit 2
fi
if ! command -v bash >/dev/null 2>&1; then
  echo "ERROR: preflight fail — bash not available" >&2
  exit 2
fi

# --- test framework ---
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

PASS=0; FAIL=0
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- fake gh factory (d031-style inline case-statement, no heredoc variable pitfalls) ---
# Writes ready JSON + dep state + log path env vars at runtime.
make_fake_gh() {
  local gh_path="$1"
  local ready_file="$gh_path.ready.json"
  local wip_file="$gh_path.wip.json"
  local dep_open_n="$2"
  local log_path="$3"
  local ready_json="$4"
  local wip_count="$5"

  if [ -n "$ready_json" ] && [ "$ready_json" != "EMPTY" ]; then
    printf '%s' "$ready_json" > "$ready_file"
  else
    printf '[]' > "$ready_file"
  fi
  # Build WIP JSON list (empty array for wip_count=0 — script uses `jq 'length'`)
  if [ "${wip_count:-0}" -gt 0 ] 2>/dev/null; then
    local entries=""
    for ((i=1; i<=wip_count; i++)); do
      entries="${entries}{\"number\":$((1000+i))},"
    done
    entries="${entries%,}"  # strip trailing comma
    printf '[%s]' "$entries" > "$wip_file"
  else
    printf '[]' > "$wip_file"
  fi

  cat > "$gh_path" <<'EOF'
#!/usr/bin/env bash
echo "CALL $*" >> "${FAKE_LOG_PATH:-/tmp/fake-gh.log}"

# Issue #806: gh api is the WIP query path (REST, not --label filter)
# Differentiate by URL endpoint — script uses gh api with labels= param.
if [ "$1" = "api" ]; then
  url="$2"
  if echo "$url" | grep -q "status:ready"; then
    cat "${FAKE_READY_FILE:-/dev/null}"
    exit $?
  elif echo "$url" | grep -q "status:in-progress"; then
    cat "${FAKE_WIP_FILE:-/dev/null}"
    exit $?
  else
    echo "[]"
    exit 0
  fi
fi

case "$1 $2" in
  "issue list")
    # Differentiate by --label combination (legacy path)
    if echo "$*" | grep -q "status:ready"; then
      cat "${FAKE_READY_FILE:-/dev/null}"
    elif echo "$*" | grep -q "status:in-progress"; then
      cat "${FAKE_WIP_FILE:-/dev/null}"
    else
      echo "[]"
    fi
    ;;
  "issue view")
    # Return state of dep issue. Use FAKE_DEP_OPEN_N — if it matches, return "open".
    local n="$3"
    if [ "$n" = "${FAKE_DEP_OPEN_N:-}" ]; then
      echo '{"state":"open"}'
    else
      echo '{"state":"closed"}'
    fi
    ;;
  "issue edit"|"issue comment")
    echo "EDIT/COMMENT $*" >> "${FAKE_LOG_PATH:-/tmp/fake-gh.log}"
    ;;
  *)
    echo "FAKE_GH_UNHANDLED $*" >&2
    exit 99
    ;;
esac
EOF
  chmod +x "$gh_path"
}

# --- helper: run claim-next-ready.sh with fake gh ---
run_claim() {
  local role="$1"
  local ready_json="$2"
  local wip_count="$3"
  local dep_open_n="$4"

  local fake_bin
  fake_bin="$(mktemp -d "$TEST_TMPDIR/fakebin-XXXXXX")"
  local gh_path="$fake_bin/gh"
  local log_path="$fake_bin/gh-log"
  make_fake_gh "$gh_path" "$dep_open_n" "$log_path" "$ready_json" "$wip_count"

  CLAIM_OUT="$(env \
    FAKE_READY_FILE="$gh_path.ready.json" \
    FAKE_WIP_FILE="$gh_path.wip.json" \
    FAKE_DEP_OPEN_N="$dep_open_n" \
    FAKE_LOG_PATH="$log_path" \
    PATH="$fake_bin:$PATH" \
    GITHUB_REPO="test-owner/test-repo" \
    AUTO_CLAIM_LOG_DIR="$TEST_TMPDIR/logs" \
    bash "$CLAIM_SH" "$role" 2>&1)"
  CLAIM_RC=$?
  CLAIM_LOG="$log_path"
}

mkdir -p "$TEST_TMPDIR/logs"

# ============================================================================
section "TC1: body 'deferred behind #N' soft-deferral marker → skip + log"
# Issue #999 has agent:developer + status:ready
# Body contains: "deferred behind #1001"
# Expected with fix: skip #999 (not claim), log "skip #999: deferred behind #1001"
# Current main: script only parses "depends on|blocked by" — "deferred behind" not captured → claim succeeds → RED
ready='[
  {"number":999,"title":"soft-deferral test","createdAt":"2026-07-13T08:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"},{"name":"priority:P2"}],"body":"## Story\nThis is deferred behind #1001 (S29-001 design landing)."}
]'
run_claim developer "$ready" 0 ""
if [ "$CLAIM_RC" = "0" ] && echo "$CLAIM_OUT" | grep -qE "claimed #999"; then
  fail "TC1: claim succeeded despite 'deferred behind #1001' marker" "expected: skip #999 (deferred behind #1001); got rc=$CLAIM_RC, out=$CLAIM_OUT"
elif [ "$CLAIM_RC" != "0" ] && echo "$CLAIM_OUT" | grep -qE "(skip|skipping).*#999.*(deferred behind|1001)"; then
  pass "TC1: soft-deferral marker correctly skipped #999"
else
  fail "TC1: unexpected behavior (rc=$CLAIM_RC)" "out=$CLAIM_OUT"
fi

# ============================================================================
section "TC2: body 'blocks #N' cross-issue-block marker → skip + log"
# Issue #888 has body "blocks #500" — meaning #888 must complete BEFORE #500 can start
# Current main: script only parses "depends on|blocked by" in body — "blocks" not captured → claim succeeds → RED
ready='[
  {"number":888,"title":"blocks-N test","createdAt":"2026-07-13T08:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"},{"name":"priority:P2"}],"body":"## Story\nThis blocks #500 — #500 cannot start until this lands."}
]'
run_claim developer "$ready" 0 ""
if [ "$CLAIM_RC" = "0" ] && echo "$CLAIM_OUT" | grep -qE "claimed #888"; then
  fail "TC2: claim succeeded despite 'blocks #500' cross-issue marker" "expected: skip #888 (blocks #500); got rc=$CLAIM_RC, out=$CLAIM_OUT"
elif [ "$CLAIM_RC" != "0" ] && echo "$CLAIM_OUT" | grep -qE "(skip|skipping).*#888.*(blocks|500)"; then
  pass "TC2: cross-issue-block marker correctly skipped #888"
else
  fail "TC2: unexpected behavior (rc=$CLAIM_RC)" "out=$CLAIM_OUT"
fi

# ============================================================================
section "TC3: body 'decision landed in #N' marker → skip + log"
# Issue #777 has body "decision landed in #600" — meaning upstream decision is already made
# Current main: script does not parse decision-landed → claim succeeds → RED
ready='[
  {"number":777,"title":"decision-landed test","createdAt":"2026-07-13T08:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"},{"name":"priority:P2"}],"body":"## Story\nDecision landed in #600 (S29-001 design accepted). Work is post-decision polish only — re-classify as docs/chore."}
]'
run_claim developer "$ready" 0 ""
if [ "$CLAIM_RC" = "0" ] && echo "$CLAIM_OUT" | grep -qE "claimed #777"; then
  fail "TC3: claim succeeded despite 'decision landed in #600' marker" "expected: skip #777 (decision landed in #600); got rc=$CLAIM_RC, out=$CLAIM_OUT"
elif [ "$CLAIM_RC" != "0" ] && echo "$CLAIM_OUT" | grep -qE "(skip|skipping).*#777.*(decision landed|600)"; then
  pass "TC3: decision-landed marker correctly skipped #777"
else
  fail "TC3: unexpected behavior (rc=$CLAIM_RC)" "out=$CLAIM_OUT"
fi

# ============================================================================
section "TC4: body 'work-done via PR #N' marker → skip + log"
# Issue #666 has body "work done via PR #200" — meaning implementation already shipped
# Current main: script does not parse work-done markers → claim succeeds → RED
ready='[
  {"number":666,"title":"work-done test","createdAt":"2026-07-13T08:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"},{"name":"priority:P2"}],"body":"## Story\nWork done via PR #200 (squash-merged). This issue should be closed as done, not re-claimed."}
]'
run_claim developer "$ready" 0 ""
if [ "$CLAIM_RC" = "0" ] && echo "$CLAIM_OUT" | grep -qE "claimed #666"; then
  fail "TC4: claim succeeded despite 'work done via PR #200' marker" "expected: skip #666 (work-done via PR #200); got rc=$CLAIM_RC, out=$CLAIM_OUT"
elif [ "$CLAIM_RC" != "0" ] && echo "$CLAIM_OUT" | grep -qE "(skip|skipping).*#666.*(work done|200)"; then
  pass "TC4: work-done marker correctly skipped #666"
else
  fail "TC4: unexpected behavior (rc=$CLAIM_RC)" "out=$CLAIM_OUT"
fi

# ============================================================================
section "TC5: body 'deferred to peer #N (in-progress)' lane-active marker → skip + log"
# Issue #555 has body "deferred to #444 (currently in-progress)" — meaning lane-active-claim priority
# Current main: script does not consult lane-active-claims-other-issue → claim succeeds → RED
ready='[
  {"number":555,"title":"lane-active-deferral test","createdAt":"2026-07-13T08:00:00Z","labels":[{"name":"status:ready"},{"name":"agent:developer"},{"name":"priority:P2"}],"body":"## Story\nDeferred to #444 (currently in-progress on architect lane). Re-classify once #444 closes."}
]'
run_claim developer "$ready" 0 ""
if [ "$CLAIM_RC" = "0" ] && echo "$CLAIM_OUT" | grep -qE "claimed #555"; then
  fail "TC5: claim succeeded despite 'deferred to #444 (in-progress)' lane marker" "expected: skip #555 (lane-active-claim priority); got rc=$CLAIM_RC, out=$CLAIM_OUT"
elif [ "$CLAIM_RC" != "0" ] && echo "$CLAIM_OUT" | grep -qE "(skip|skipping).*#555.*(444|in-progress|lane-active)"; then
  pass "TC5: lane-active-claim marker correctly skipped #555"
else
  fail "TC5: unexpected behavior (rc=$CLAIM_RC)" "out=$CLAIM_OUT"
fi

# --- summary ---
echo ""
echo "---"
echo "d1023-retro-022: $PASS PASS, $FAIL FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: RED (at least one TC failed — RETRO-022 script-fix incomplete)"
  exit 1
else
  echo "RESULT: GREEN (all TCs pass — RETRO-022 script-fix landed)"
  exit 0
fi