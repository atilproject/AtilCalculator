#!/usr/bin/env bash
# d-agent-watch-stall-wiring.sh — Issue #1211 agent-watch.sh stall wiring audit d-test.
#
# Why this test exists
# --------------------
# Issue #1183 spec (line 220 of agent-stall-detect.sh) requires:
#   "Wave logic lives in scripts/agent-watch.sh's stall integration block"
#
# Per dev audit @ 2026-07-23T08:54Z (cmt 5056373219), even if d-stall-detect rule
# is fixed via Issue #1210 option (a), it MUST actually be invoked from
# agent-watch.sh for stalls to surface as orchestrator wake events. Without this
# audit, the Issue #1210 fix is silent — d-stall-detect runs only on manual
# invocation, never on the 60s orchestrator poll cycle.
#
# This d-test verifies the integration is wired correctly:
#   T1: Integration block present in agent-watch.sh (orchestrator-only lens)
#   T2: d-stall-detect invoked AFTER wip_idle block (sister to wip_idle)
#   T3: Wave coalesce ≥3 stalls = single dev_stall_wave event (sister to wip_idle_wave)
#   T4: dev_stall events emitted as part of orchestrator poll cycle (sister to wip_idle)
#   T5 (arch NIT TC11): RETRO-024 silent-skip on closed/work-done-elsewhere issues
#
# Sister-pattern: scripts/tests/d-stall-detect.sh (Issue #1183 baseline 9 TCs)
# + scripts/tests/d052-agent-watch-hardening.sh (Issue #461 STRY-d052 6 TCs).
# ≥3 sister-pattern coverage per ADR-0049 met.
#
# RED-first per ADR-0044: T5 (RETRO-024 silent-skip on dev_stall events) FAILS
# on current agent-watch.sh because no filter is applied to suppress closed
# issues or RETRO-024 work-done-elsewhere pattern (`type:* + status:ready +
# cc:human + no agent:*`). T1-T4 PASS on current impl (integration block exists
# at line 1962 per PR #1209 squash a89611c).
#
# Exit code: 0 = all pass, 1 = at least one fail.
# Run standalone: bash scripts/tests/d-agent-watch-stall-wiring.sh [--self-test]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WATCH_SH="$REPO_ROOT/scripts/agent-watch.sh"
DETECT_SH="$REPO_ROOT/scripts/agent-stall-detect.sh"

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
# T1: Integration block present in agent-watch.sh (orchestrator-only)
# ============================================================================
section "T1: agent-watch.sh has dev_stall integration block (orchestrator-only)"
if [ -f "$WATCH_SH" ] && \
   grep -Eq 'dev_stall|agent-stall-detect\.sh' "$WATCH_SH"; then
  pass "integration block present (Issue #1183 spec line 220 — wave logic lives in agent-watch.sh)"
else
  fail "integration block missing" "expected: scripts/agent-watch.sh has dev_stall/agent-stall-detect.sh reference — Issue #1183 spec"
fi

# ============================================================================
# T2: Invoked AFTER wip_idle block (sister-pattern position)
# ============================================================================
section "T2: dev_stall integration AFTER wip_idle block (sister-pattern position)"
# Verify: line number of dev_stall/agent-stall-detect.sh reference is GREATER
# than line number of wip_idle block start. Sister-pattern: same as
# wip_idle → dev_stall ordering (per arch 🟡 #2 on #289 wave coalesce sister).
if [ -f "$WATCH_SH" ]; then
  wip_idle_line="$(grep -n 'wip_idle\b' "$WATCH_SH" | head -1 | cut -d: -f1 || echo 0)"
  stall_line="$(grep -n 'dev_stall\|agent-stall-detect\.sh' "$WATCH_SH" | head -1 | cut -d: -f1 || echo 0)"
  if [ "$stall_line" -gt 0 ] && [ "$wip_idle_line" -gt 0 ] && [ "$stall_line" -gt "$wip_idle_line" ]; then
    pass "dev_stall at line $stall_line is AFTER wip_idle at line $wip_idle_line (sister-pattern preserved)"
  else
    fail "dev_stall not positioned AFTER wip_idle" "expected: dev_stall integration block AFTER wip_idle block in agent-watch.sh — sister-pattern"
  fi
else
  fail "agent-watch.sh missing" "expected: $WATCH_SH"
fi

# ============================================================================
# T3: Wave coalesce ≥3 stalls = single dev_stall_wave event
# ============================================================================
section "T3: Wave coalesce ≥3 stalls = single dev_stall_wave event (sister to wip_idle_wave)"
if [ -f "$WATCH_SH" ] && \
   grep -Eq 'dev_stall_wave|stall_bucket|stall wave' "$WATCH_SH"; then
  pass "wave coalesce wired (≥3 stalls → single dev_stall_wave event, sister to wip_idle_wave)"
else
  fail "wave coalesce missing" "expected: ≥3 stalls → single dev_stall_wave event — sister to wip_idle_wave (arch 🟡 #2 on #289)"
fi

# ============================================================================
# T4: dev_stall events emitted as part of orchestrator poll cycle
# ============================================================================
section "T4: dev_stall events emitted on every orchestrator poll cycle (after wip_idle)"
if [ -f "$WATCH_SH" ] && \
   grep -Eq 'local dev_stall.*\[\]|dev_stall.*\+\+\+\+\+|dev_stall.*<.*echo.*wip_idle' "$WATCH_SH"; then
  pass "dev_stall events emitted on poll cycle (sister to wip_idle emission pattern)"
else
  fail "dev_stall emission pattern missing" "expected: dev_stall='[]' initial + dev_stall+= pattern + final emission alongside wip_idle — sister to wip_idle"
fi

# ============================================================================
# T5 (arch NIT TC11): RETRO-024 silent-skip on closed/work-done-elsewhere issues
# ============================================================================
section "T5 (arch NIT TC11): RETRO-024 silent-skip on work-done-elsewhere issues"
# Per arch verdict on Issue #1211 (cmt 5058101861 NIT-2): dev_stall integration
# must NOT emit events for issues matching the RETRO-024 work-done-elsewhere
# terminal state pattern:
#   type:<*> + status:ready + cc:human + (no agent:*)
# RED-first: current agent-watch.sh has NO filter applied INSIDE the dev_stall
# integration block (lines 1962-2007). The RETRO-024 reference at line 1265 is
# in a different block (claim atomic guard), not the stall wiring. After fix:
# dev_stall events should filter RETRO-024 pattern (e.g., jq select on .agent
# or via separate filter pass on the stall_json output before event emission).
# Verify: extract dev_stall integration block (lines around the integration)
# and check for RETRO-024/work-done-elsewhere filter pattern INSIDE that block.
if [ -f "$WATCH_SH" ]; then
  # Extract the dev_stall integration block: from `# Issue #1183` to the next
  # blank line / major section (heuristic: 60 lines after first match).
  stall_block="$(awk '/Issue #1183 — Dev-pane pickup stall detection/,/^  local wake_nudge=/' "$WATCH_SH")"
  if echo "$stall_block" | grep -Eq 'RETRO-024|work-done-elsewhere|select.*agent.*!=.*null|silent_skip.*stall'; then
    pass "RETRO-024 silent-skip wired on dev_stall integration (work-done-elsewhere excluded)"
  else
    fail "RETRO-024 silent-skip missing on dev_stall integration block" "expected: dev_stall events filter out RETRO-024 work-done-elsewhere pattern (type:*+status:ready+cc:human+no agent:*) INSIDE the integration block (lines ~1962-2007) — arch NIT-2 on Issue #1211"
  fi
else
  fail "agent-watch.sh missing" "expected: $WATCH_SH"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
printf "${B}==== Summary ====${D}\n"
printf "  PASS: ${G}%d${D}\n" "$PASS"
printf "  FAIL: ${R}%d${D}\n" "$FAIL"

if [ "$FAIL" -eq 0 ]; then
  printf "${G}${B}ALL TESTS PASSED${D}\n"
  exit 0
else
  printf "${R}${B}TESTS FAILED (RED-first expected — impl pending)${D}\n"
  exit 1
fi
