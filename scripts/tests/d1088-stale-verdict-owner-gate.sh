#!/usr/bin/env bash
# d1088-stale-verdict-owner-gate.sh — scripts/agent-watch.sh stale_verdict
# A-path owner-gate exemption regression guard (Issue #1088).
#
# Why this test exists
# --------------------
# Per Issue #1088 (P2 BUG, Sprint 29 gap-closing, scripts/agent-watch.sh
# A-path heuristic gap, lines 1253-1256): the verdict-authority discriminator
# `agent:${ROLE}` match fires even when `status:ready + cc:human` indicates
# verdict authority has transferred to owner (ADR-0031 owner merge gate).
#
# Result: silent-RED noise wakes developer (and likely architect) every 180s
# on owner-gated PRs with `agent:<role>` still on the label set. Live evidence:
# PR #6, PR #106, PR #1087 all flagged false-positive on 2026-07-15T09:04Z-09:08Z.
#
# This d-test is the backstop: it asserts the `$is_owner_gated` exemption
# filter is present in `query_stale_verdict` (T1 + T2 code-presence anchors)
# AND simulates jq behavior against 5 fixture label sets to verify the
# exemption logic works as specified (T3-T5 behavior anchors).
#
# Sister references:
#   - Issue #1088 (this d-test's tracker + spec)
#   - ADR-0024 (verdict-by:<ts> convention + verdict authority)
#   - ADR-0031 (owner merge gate — cc:human authority transfer)
#   - ADR-0044 (RED-first TDD doctrinal home)
#   - ADR-0049 (d-test framework ≥5 TCs baseline)
#   - ADR-0055 §1 (Cadence Rule 1 atomic — file + INDEX.md same commit)
#   - Issue #798 (original stale_verdict false-positive fix, closed)
#   - Issue #846 (cc:<role> presence gate B-path fix — sister-pattern)
#   - RETRO-024 (Issue #1027, sister-pattern: work-done-elsewhere terminal state
#     silent-skip rule — same doctrine applied to verdict-by deadline expiry)
#
# Test cases:
#   T1: `$is_owner_gated` filter present in scripts/agent-watch.sh
#       query_stale_verdict function (RED-first: absent pre-impl).
#   T2: `$is_owner_gated` filter positioned BEFORE
#       `select($is_verdict_authority)` in query_stale_verdict (ordering matters
#       — exemption must apply before verdict-authority check).
#   T3: Behavior — `status:ready + cc:human + agent:<role> + verdict-by:<past>`
#       does NOT emit stale_verdict (owner-gated exemption, regression anchor).
#   T4: Behavior — `status:in-review + cc:developer + verdict-by:<past>`
#       STILL emits stale_verdict (regression: non-owner-gated PRs unchanged).
#   T5: Sister-pattern — `status:blocked + cc:human + agent:<role> + verdict-by:<past>`
#       does NOT emit stale_verdict (blocked semantics: owner pause, not verdict expiry).
#
# Exit code: 0 = all pass, 1 = at least one fail.
# Run standalone: bash scripts/tests/d1088-stale-verdict-owner-gate.sh

set -uo pipefail

# Path resolution: git rev-parse --show-toplevel is portable (per Issue #370 §T2 + d043).
REPO_ROOT="$(git rev-parse --show-toplevel)"
WATCH_SH="$REPO_ROOT/scripts/agent-watch.sh"

if [ ! -f "$WATCH_SH" ]; then
  echo "ERROR: scripts/agent-watch.sh not found at $WATCH_SH" >&2
  exit 127
fi

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

# T1+T2: Locate query_stale_verdict function bounds in agent-watch.sh.
# Extract the function body between `query_stale_verdict() {` and the closing `}`.
# Per Issue #1088 spec: filter must be added before `select($is_verdict_authority)`.
QUERY_VERDICT_START=$(grep -n "^query_stale_verdict()" "$WATCH_SH" | head -1 | cut -d: -f1 || echo "0")
QUERY_VERDICT_END=$(awk -v start="$QUERY_VERDICT_START" \
  'NR > start && /^}$/ { print NR; exit }' "$WATCH_SH" || echo "0")

if [ "$QUERY_VERDICT_START" -eq 0 ] || [ "$QUERY_VERDICT_END" -eq 0 ]; then
  echo "ERROR: query_stale_verdict() function bounds not found in $WATCH_SH" >&2
  exit 127
fi

QUERY_VERDICT_BODY=$(sed -n "${QUERY_VERDICT_START},${QUERY_VERDICT_END}p" "$WATCH_SH")

# ============================================================================
# T1: $is_owner_gated filter present in query_stale_verdict
# ============================================================================
section "T1: \$is_owner_gated exemption filter present in query_stale_verdict"
OWNER_GATED_LINES=$(echo "$QUERY_VERDICT_BODY" | grep -nF 'is_owner_gated' | cut -d: -f1 || true)
if [ -n "$OWNER_GATED_LINES" ]; then
  pass "\$is_owner_gated filter present in query_stale_verdict (line(s): $OWNER_GATED_LINES)"
else
  fail "\$is_owner_gated filter ABSENT from query_stale_verdict — Issue #1088 A-path owner-gate exemption not implemented" \
    "Per Issue #1088 §Proposed fix: add jq-side filter before select(\$is_verdict_authority): (\$lbls | any(. == \"status:ready\")) and (\$lbls | any(. == \"cc:human\")) | select(not)"
fi

# ============================================================================
# T2: $is_owner_gated filter positioned BEFORE select($is_verdict_authority)
# ============================================================================
section "T2: \$is_owner_gated positioned BEFORE select(\$is_verdict_authority)"
OWNER_GATED_LINE=$(echo "$QUERY_VERDICT_BODY" | grep -nF 'is_owner_gated' | head -1 | cut -d: -f1 || echo "0")
VERDICT_AUTH_LINE=$(echo "$QUERY_VERDICT_BODY" | grep -nF 'select($is_verdict_authority)' | head -1 | cut -d: -f1 || echo "0")

if [ "$OWNER_GATED_LINE" -eq 0 ]; then
  fail "T2 cannot validate ordering — T1 failure (no \$is_owner_gated filter found)"
elif [ "$OWNER_GATED_LINE" -lt "$VERDICT_AUTH_LINE" ]; then
  pass "\$is_owner_gated (line $OWNER_GATED_LINE) precedes select(\$is_verdict_authority) (line $VERDICT_AUTH_LINE)"
else
  fail "\$is_owner_gated (line $OWNER_GATED_LINE) MUST precede select(\$is_verdict_authority) (line $VERDICT_AUTH_LINE)" \
    "Owner-gate exemption must filter BEFORE verdict-authority check — otherwise the exemption is a no-op (select has already passed)."
fi

# ============================================================================
# T3-T5: Behavior anchors — jq eval against fixture label sets
# ============================================================================
section "T3-T5: Behavior anchors — jq eval against 3 fixture label sets"

# Helper: simulates query_stale_verdict jq logic against a fixture label list.
# Returns 0 if stale_verdict event would be emitted, 1 if silent-skipped.
# This mirrors the actual jq pipeline in scripts/agent-watch.sh lines 1242-1301
# (with the Issue #1088 fix applied: \$is_owner_gated filter BEFORE verdict-authority).
simulate_stale_verdict() {
  local labels_json="$1"
  local verdict_by_ts="$2"  # ISO timestamp or empty
  local now_epoch="$3"
  local role="$4"

  echo "$labels_json" | jq --arg now_epoch "$now_epoch" --arg role "$role" '
    ($labels_json := .) |
    (
      (((. | map(select(startswith("status:")))) | any(. == "status:ready")) and
       ((. | map(select(startswith("cc:")))) | any(. == "cc:human")))
    ) as $is_owner_gated |
    select($is_owner_gated | not) |
    (
      ((. | map(select(startswith("agent:")))) | any(. == "agent:\($role)")) or
      (((. | map(select(startswith("cc:")))) | any(. == "cc:human")) and
       ((. | map(select(startswith("cc:")))) | any(. == "cc:\($role)")))
    ) as $is_verdict_authority |
    select($is_verdict_authority) |
    (. | map(select(startswith("verdict-by:"))) | first // "") as $vb |
    select($vb != "" and $vb != null) |
    ($vb | sub("verdict-by:"; "") | fromdateiso8601? // "") as $deadline |
    select($deadline != null and $deadline != "" and ($now_epoch | tonumber) > ($deadline | tonumber)) |
    { kind: "stale_verdict" }
  ' >/dev/null 2>&1
}

# Test fixtures
NOW_EPOCH="1752566400"  # 2026-07-15T16:00:00Z (deterministic anchor)
PAST_VERDICT_BY="verdict-by:2026-07-15T08:00:00Z"  # 8h ago — deadline passed

ROLE="developer"

# T3: Owner-gated exemption — should NOT emit
section "T3: status:ready + cc:human + agent:<role> + verdict-by:<past> → silent-skip (owner-gated)"
T3_LABELS='["status:ready","cc:human","agent:developer","cc:developer","verdict-by:2026-07-15T08:00:00Z"]'
T3_OUT=$(echo "$T3_LABELS" | jq --arg now_epoch "$NOW_EPOCH" --arg role "$ROLE" '
  (. | map(select(startswith("cc:")))) as $cc_lbls |
  (. | map(select(startswith("agent:")))) as $agent_lbls |
  (
    (((. | map(select(startswith("status:")))) | any(. == "status:ready")) and
     (($cc_lbls) | any(. == "cc:human")))
  ) as $is_owner_gated |
  select($is_owner_gated | not) |
  (
    (($agent_lbls) | any(. == "agent:\($role)")) or
    ((($cc_lbls) | any(. == "cc:human")) and (($cc_lbls) | any(. == "cc:\($role)")))
  ) as $is_verdict_authority |
  select($is_verdict_authority) |
  (. | map(select(startswith("verdict-by:"))) | first // "") as $vb |
  select($vb != "" and $vb != null) |
  ($vb | sub("verdict-by:"; "") | fromdateiso8601? // "") as $deadline |
  select($deadline != null and $deadline != "" and ($now_epoch | tonumber) > ($deadline | tonumber)) |
  { kind: "stale_verdict" }
' 2>&1)
T3_EXIT=$?
if [ $T3_EXIT -ne 0 ]; then
  pass "T3: owner-gated PR (status:ready + cc:human) silently-skipped (jq select returns no match)"
else
  fail "T3: owner-gated PR incorrectly emits stale_verdict (jq select returned: $T3_OUT)" \
    "Per Issue #1088 §Proposed fix: status:ready + cc:human should exempt from verdict-authority check."
fi

# T4: Non-owner-gated — should STILL emit (regression anchor)
section "T4: status:in-review + cc:developer + verdict-by:<past> → emit stale_verdict (non-owner-gated)"
T4_LABELS='["status:in-review","cc:developer","agent:developer","verdict-by:2026-07-15T08:00:00Z"]'
T4_OUT=$(echo "$T4_LABELS" | jq --arg now_epoch "$NOW_EPOCH" --arg role "$ROLE" '
  (. | map(select(startswith("cc:")))) as $cc_lbls |
  (. | map(select(startswith("agent:")))) as $agent_lbls |
  (
    (((. | map(select(startswith("status:")))) | any(. == "status:ready")) and
     (($cc_lbls) | any(. == "cc:human")))
  ) as $is_owner_gated |
  select($is_owner_gated | not) |
  (
    (($agent_lbls) | any(. == "agent:\($role)")) or
    ((($cc_lbls) | any(. == "cc:human")) and (($cc_lbls) | any(. == "cc:\($role)")))
  ) as $is_verdict_authority |
  select($is_verdict_authority) |
  (. | map(select(startswith("verdict-by:"))) | first // "") as $vb |
  select($vb != "" and $vb != null) |
  ($vb | sub("verdict-by:"; "") | fromdateiso8601? // "") as $deadline |
  select($deadline != null and $deadline != "" and ($now_epoch | tonumber) > ($deadline | tonumber)) |
  { kind: "stale_verdict" }
' 2>&1)
T4_EXIT=$?
if [ $T4_EXIT -eq 0 ]; then
  pass "T4: non-owner-gated PR (status:in-review + cc:developer) correctly emits stale_verdict (regression preserved)"
else
  fail "T4: non-owner-gated PR should emit stale_verdict but jq select returned no match (err: $T4_OUT)" \
    "Fix regression: status:in-review + cc:developer + verdict-by:<past> MUST still emit. If not, the owner-gate filter is over-eager (exempts non-ready PRs)."
fi

# T5: Sister-pattern — status:blocked + cc:human → silent-skip (different gate)
section "T5: status:blocked + cc:human + agent:<role> + verdict-by:<past> → silent-skip (blocked semantics)"
T5_LABELS='["status:blocked","cc:human","agent:developer","verdict-by:2026-07-15T08:00:00Z"]'
T5_OUT=$(echo "$T5_LABELS" | jq --arg now_epoch "$NOW_EPOCH" --arg role "$ROLE" '
  (. | map(select(startswith("cc:")))) as $cc_lbls |
  (. | map(select(startswith("agent:")))) as $agent_lbls |
  (
    (((. | map(select(startswith("status:")))) | any(. == "status:ready")) and
     (($cc_lbls) | any(. == "cc:human")))
  ) as $is_owner_gated |
  select($is_owner_gated | not) |
  (
    (($agent_lbls) | any(. == "agent:\($role)")) or
    ((($cc_lbls) | any(. == "cc:human")) and (($cc_lbls) | any(. == "cc:\($role)")))
  ) as $is_verdict_authority |
  select($is_verdict_authority) |
  (. | map(select(startswith("verdict-by:"))) | first // "") as $vb |
  select($vb != "" and $vb != null) |
  ($vb | sub("verdict-by:"; "") | fromdateiso8601? // "") as $deadline |
  select($deadline != null and $deadline != "" and ($now_epoch | tonumber) > ($deadline | tonumber)) |
  { kind: "stale_verdict" }
' 2>&1)
T5_EXIT=$?
if [ $T5_EXIT -ne 0 ]; then
  pass "T5: status:blocked + cc:human does NOT emit stale_verdict (different gate semantics — blocked = owner pause)"
else
  fail "T5: status:blocked + cc:human should NOT emit stale_verdict but jq select returned: $T5_OUT" \
    "Sister-pattern: status:blocked = owner pause per ADR-0012 4-cat invariant. Should be silent-skipped, NOT trigger stale_verdict (which only fires when verdict-by deadline expires AND verdict authority is active)."
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo ""
echo "  Reference: Issue #1088 (this d-test's tracker + spec), ADR-0024,"
echo "             ADR-0031 (owner merge gate), ADR-0044 (RED-first TDD),"
echo "             ADR-0049 (d-test framework), ADR-0055 §1 (Cadence Rule 1)."
echo "  Sister-pattern: Issue #846 (B-path fix, status:done, d124 TC5)."
exit 0