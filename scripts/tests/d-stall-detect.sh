#!/usr/bin/env bash
# d-stall-detect.sh — Issue #1183 dev-pane pickup stall detection d-test.
#
# Why this test exists
# --------------------
# Issue #1183 spec: detect `agent:developer + status:in-progress` issues that
# have had no PR opened in >24h. RETRO-032 lesson #2 didn't-go-well: Sprint 32
# final wave dev pane went silent ~36h after claiming S32-019 cluster — root
# cause was tmux pane on wrong cwd + no recovery signal. The new helper
# `scripts/agent-stall-detect.sh` + integration block in `scripts/agent-watch.sh`
# surface stalls as wake events so orchestrator can peer-poke dev + (optional)
# auto-claim rescue.
#
# Sister-pattern: scripts/tests/d034-proactive-wip-idle.sh (wip-idle watchdog
# test, same author pattern). Both helpers are orchestrator-only integrations
# in agent-watch.sh after the wip_idle block.
#
# Exit code: 0 = all pass, 1 = at least one fail.
# Run standalone: bash scripts/tests/d-stall-detect.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DETECT_SH="$REPO_ROOT/scripts/agent-stall-detect.sh"
WATCH_SH="$REPO_ROOT/scripts/agent-watch.sh"

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
# T1: Helper script exists + executable
# ============================================================================
section "T1: scripts/agent-stall-detect.sh exists + executable (Issue #1183 impl)"
if [ -f "$DETECT_SH" ] && [ -x "$DETECT_SH" ]; then
  pass "agent-stall-detect.sh exists and is executable"
else
  fail "agent-stall-detect.sh missing or not executable" "expected: scripts/agent-stall-detect.sh (-x bit set) — Issue #1183 dev impl"
fi

# ============================================================================
# T2: Threshold default = 24 hours (Issue #1183 spec)
# ============================================================================
section "T2: Default threshold = 24h (Issue #1183 spec)"
if [ -f "$DETECT_SH" ] && grep -Eq 'STALL_DETECT_THRESHOLD_HOURS:-24|THRESHOLD_HOURS.*24|24.*hour' "$DETECT_SH"; then
  pass "default threshold = 24h (Issue #1183 spec)"
else
  fail "default threshold ≠ 24h" "expected: STALL_DETECT_THRESHOLD_HOURS:-24 in agent-stall-detect.sh — Issue #1183 24h threshold (vs wip-idle 30m signal-driven)"
fi

# ============================================================================
# T3: GITHUB_REPO env pollution guard (cycle ~#3968Q+213 sister)
# ============================================================================
section "T3: GITHUB_REPO env pollution guard (cycle ~#3968Q+213 sister)"
if [ -f "$DETECT_SH" ] && grep -Eq 'GITHUB_REPO.*\*"/"\*|cannot detect repo.*owner/name' "$DETECT_SH"; then
  pass "env pollution guard present (rejects bare-name GITHUB_REPO)"
else
  fail "env pollution guard missing" "expected: GITHUB_REPO validation rejecting bare names (cycle ~#3968Q+213 sister — earlier session contamination set GITHUB_REPO=AtilCalculator)"
fi

# ============================================================================
# T4: Search syntax uses `${issue_n} in:body` (NOT broken `linked:issue-N`)
# ============================================================================
section "T4: Search syntax uses '\${issue_n} in:body' (gh CLI v2.x fix)"
if [ -f "$DETECT_SH" ] && grep -Eq 'in:body' "$DETECT_SH" && ! grep -Eq 'linked:issue-' "$DETECT_SH"; then
  pass "search uses 'in:body' qualifier (broken 'linked:issue-N' rejected)"
else
  fail "wrong search syntax" "expected: \${issue_n} in:body (verified at AtilCalculator #1180 — linked:issue-N returned 30 PRs, in:body returned 3)"
fi

# ============================================================================
# T5: Edge case — status:in-review excluded from stall list (sister to signal 5)
# ============================================================================
section "T5: status:in-review edge case — NOT stalled (sister to wip-idle signal 5)"
if [ -f "$DETECT_SH" ] && grep -Eq 'has_in_review|status:in-review' "$DETECT_SH"; then
  pass "status:in-review edge case wired (PR up + awaiting verdict = NOT stalled)"
else
  fail "status:in-review edge case missing" "expected: skip stall detection for issues with status:in-review label (sister to wip-idle signal 5)"
fi

# ============================================================================
# T6: Edge case — status:blocked excluded from stall list
# ============================================================================
section "T6: status:blocked edge case — NOT stalled (legitimate block)"
if [ -f "$DETECT_SH" ] && grep -Eq 'has_blocked|status:blocked' "$DETECT_SH"; then
  pass "status:blocked edge case wired (legitimate block = NOT stalled)"
else
  fail "status:blocked edge case missing" "expected: skip stall detection for issues with status:blocked label"
fi

# ============================================================================
# T7: --role flag validation (rejects non-developer per Issue #1183 scope)
# ============================================================================
section "T7: --role validation (developer-only per Issue #1183 spec)"
if [ -f "$DETECT_SH" ] && grep -Eq 'only .developer. in scope|invalid role' "$DETECT_SH"; then
  pass "--role validation rejects non-developer (Issue #1183 scope)"
else
  fail "--role validation missing" "expected: --role flag accepts only 'developer' (cross-role stalls deferred to Sprint 34+ per Issue #1183)"
fi

# ============================================================================
# T8: agent-watch.sh integration block present (orchestrator-only, after wip_idle)
# ============================================================================
section "T8: agent-watch.sh integration block — orchestrator-only, after wip_idle"
if [ -f "$WATCH_SH" ] && grep -Eq 'dev_stall|agent-stall-detect.sh|Issue #1183.*stall detection' "$WATCH_SH"; then
  pass "agent-watch.sh integration block present (dev_stall events emitted by orchestrator only)"
else
  fail "agent-watch.sh integration block missing" "expected: scripts/agent-watch.sh has dev_stall detection after wip_idle block (orchestrator-only lens)"
fi

# ============================================================================
# T9: Wave coalesce — ≥3 stalls → dev_stall_wave event (sister to wip_idle_wave)
# ============================================================================
section "T9: Wave coalesce — ≥3 stalls = single dev_stall_wave event"
if [ -f "$WATCH_SH" ] && grep -Eq 'dev_stall_wave|stall_bucket|stall wave' "$WATCH_SH"; then
  pass "wave coalesce wired (≥3 stalls = single dev_stall_wave event per arch 🟡 #2 on #289)"
else
  fail "wave coalesce missing" "expected: ≥3 dev stalls in 5-min window = single dev_stall_wave event (sister to wip_idle_wave, arch 🟡 #2 on #289)"
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
  printf "${R}${B}TESTS FAILED${D}\n"
  exit 1
fi
