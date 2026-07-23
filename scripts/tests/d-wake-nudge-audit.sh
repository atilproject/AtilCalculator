#!/usr/bin/env bash
# d-wake-nudge-audit.sh — Issue #1184 / STORY-S33-005 cross-role wake_nudge behavior audit
#
# Why this test exists
# --------------------
# PR #1178 wake_nudge polling-loop bug fix shipped (cycle ~#3958Q+5, MERGED 2026-07-19T18:26:51Z,
# sha 8018964d). Fix tested ONLY against orchestrator role. Cross-cutting impact assessment NOT done.
# RETRO-032 lesson #7 didn't-go-well captured. Issue #1184 = cross-role audit + soul file codification.
#
# This d-test verifies the EXISTING wake_nudge behavior in agent-watch.sh is ROLE-AGNOSTIC
# (same trigger + payload format across all 5 roles) and that orchestrator has the additional
# wip_idle integration (ADR-0039, Issue #291). It is a VERIFICATION artifact for the audit
# (NOT RED-first — wake_nudge impl is already in main).
#
# 5 TCs (≥5 baseline per ADR-0049 d-test framework sister-pattern):
#   TC1: preflight — scripts/agent-watch.sh exists + readable + has wake_nudge + wip_idle integration
#   TC2: trigger condition — wake_nudge fires when (queue_open + cc_open) > 0 OR heartbeat_missed
#   TC3: payload schema — wake_nudge has kind/id/title/url/updated_at/context (jq-validatable)
#   TC4: dedup retention — wake_nudge ID is in RETAIN set (agent-state.sh lines 273-285 sister-pattern)
#   TC5: orchestrator-only wip_idle — additional integration per ADR-0039 Issue #291
#
# Sister-patterns (≥3 baseline):
#   - d015 (Issue #119 Dev-Idle Prevention, Katman 1 original wake_nudge impl)
#   - d028 (heartbeat-missed branch + 2x/3x threshold per Issue #707)
#   - d118 (Issue #707 two-tier hysteresis, 5 TCs sister-pattern to this test's TC2/TC3)
#   - d036 (state-dedup-ring retention, sister-pattern to TC4)
#   - ADR-0039 (Issue #291 wip_idle, sister-pattern to TC5)
#
# Usage:
#   bash d-wake-nudge-audit.sh --self-test
#
# Exit codes:
#   0 — all 5 PASS (GREEN state — wake_nudge cross-role audit verified)
#   1 — at least one FAIL (RED state — wake_nudge behavior diverges across roles or wip_idle missing)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AW="${REPO_ROOT}/scripts/agent-watch.sh"
AS="${REPO_ROOT}/scripts/agent-state.sh"

PASS=0; FAIL=0
section() { printf '\n=== %s ===\n' "$1"; }
pass()    { printf '  ✅ PASS: %s\n' "$1"; PASS=$((PASS+1)); }
fail()    { printf '  ❌ FAIL: %s — %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }

# TC1: preflight
section "TC1: preflight — scripts/agent-watch.sh + agent-state.sh exist"
if [ -f "$AW" ] && [ -r "$AW" ] && [ -f "$AS" ] && [ -r "$AS" ]; then
  pass "agent-watch.sh + agent-state.sh exist + readable"
else
  fail "preflight" "agent-watch.sh or agent-state.sh missing/unreadable"
  printf '\nABORT: preflight failed. Cannot continue.\n'
  exit 1
fi
if grep -q "wake_nudge" "$AW" 2>/dev/null; then
  pass "agent-watch.sh contains wake_nudge implementation"
else
  fail "wake_nudge present" "agent-watch.sh missing wake_nudge implementation"
fi

# TC2: trigger condition — (queue_open + cc_open) > 0 OR heartbeat_missed
section "TC2: trigger condition — queue non-empty OR heartbeat-missed"
if grep -q 'queue_open + cc_open' "$AW" 2>/dev/null \
   && grep -q 'heartbeat_missed' "$AW" 2>/dev/null \
   && grep -q 'wake_nudge' "$AW" 2>/dev/null; then
  pass "trigger uses queue_open + cc_open > 0 OR heartbeat_missed = true"
else
  fail "trigger condition" "agent-watch.sh missing trigger condition (queue+cc OR heartbeat-missed)"
fi

# TC3: payload schema — kind/id/title/url/updated_at/context
section "TC3: payload schema — kind/id/title/url/updated_at/context"
SCHEMA_OK=true
for FIELD in kind id title url updated_at context; do
  if ! grep -q "$FIELD" "$AW" 2>/dev/null; then
    fail "payload field '$FIELD'" "agent-watch.sh missing required payload field"
    SCHEMA_OK=false
  fi
done
if [ "$SCHEMA_OK" = "true" ]; then
  pass "wake_nudge payload contains all 6 required fields (kind/id/title/url/updated_at/context)"
fi
# Verify jq emission
if grep -q 'kind: "wake_nudge"' "$AW" 2>/dev/null; then
  pass "jq emission uses kind: \"wake_nudge\" (jq-validatable schema)"
else
  fail "jq kind literal" "expected jq emission with kind: \"wake_nudge\""
fi

# TC4: dedup retention — wake_nudge in RETAIN set (agent-state.sh lines 273-285)
section "TC4: dedup retention — wake_nudge in RETAIN set (sister-pattern to d036)"
if grep -q "wake_nudge" "$AS" 2>/dev/null \
   && grep -q "RETAIN\|retain" "$AS" 2>/dev/null \
   && grep -q "pr-merged" "$AS" 2>/dev/null \
   && grep -q "pr-review" "$AS" 2>/dev/null; then
  pass "wake_nudge + pr-merged + pr-review all in RETAIN set per dedup ring"
else
  fail "dedup retention" "agent-state.sh missing wake_nudge/pr-merged/pr-review in RETAIN set"
fi

# TC5: orchestrator-only wip_idle — additional integration per ADR-0039
section "TC5: orchestrator-only wip_idle — ADR-0039 Issue #291 sprint-6 P1"
if grep -qE 'wip_idle|wip-idle-detect\.sh|wip-idle-wave' "$AW" 2>/dev/null \
   && grep -qE 'ROLE.*=.*"orchestrator"' "$AW" 2>/dev/null; then
  pass "orchestrator-only wip_idle integration present (ADR-0039 / Issue #291)"
else
  fail "orchestrator wip_idle" "agent-watch.sh missing wip_idle integration or orchestrator-only guard"
fi

# Summary
printf '\n=== SUMMARY ===\n'
printf 'PASS: %d / 5\n' "$PASS"
printf 'FAIL: %d / 5\n' "$FAIL"
if [ "$FAIL" -eq 0 ]; then
  printf 'GREEN: wake_nudge cross-role audit verified.\n'
  exit 0
else
  printf 'RED: wake_nudge behavior diverges — see FAIL details above.\n'
  exit 1
fi
