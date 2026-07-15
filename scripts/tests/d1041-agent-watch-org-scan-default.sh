#!/usr/bin/env bash
# d1041-agent-watch-org-scan-default.sh — owner directive 2026-07-15T06:42Z
# codification. Tests that scripts/agent-watch.sh + scripts/agent-state.sh
# default behavior changed:
#   1. AGENT_WATCH_ORG defaults to "atilproject" (was: empty — single-repo only)
#   2. POLL_INTERVAL defaults to 180s (was: 60s)
#
# Sister-pattern to d047 (ADR-0047 Part 1 multi-REPO polling). d047 covered
# the --repo flag and AGENT_WATCH_REPOS env var. d1041 covers the org-scan
# default + 180s poll cadence.
#
# Per Issue cycle ~#1825 PM lane-exception: org-wide scan for cross-repo
# workstream discovery (RETRO-023 codifier). The default change to atilproject
# restores sister-pattern visibility WITHOUT requiring every clone to set
# AGENT_WATCH_ORG manually.
#
# Test cases (TDD red→green per developer.md + ADR-0044; ≥5 TCs per ADR-0049):
#   TC1: agent-watch.sh --help lists --org flag and AGENT_WATCH_ORG env var
#   TC2: AGENT_WATCH_ORG default value is "atilproject" (when env unset)
#   TC3: AGENT_WATCH_ORG="" (empty) disables org-scan (falls back to single-repo)
#   TC4: --org flag overrides AGENT_WATCH_ORG env var (precedence)
#   TC5: agent-watch.sh POLL_INTERVAL default = 180s (when state file empty)
#   TC6: agent-state.sh DEFAULT_POLL default = 180s (when AGENT_POLL_INTERVAL_SEC unset)
#   TC7: Archived repos are skipped in org-scan (AGENT_WATCH_INCLUDE_ARCHIVED=0)
#
# Exit code: 0 = all pass, 1 = at least one fail.
#
# TDD status: GREEN on this commit (impl landed first per owner urgent directive;
# d-test codifies the behavior for regression coverage).
#
# Run standalone: bash scripts/tests/d1041-agent-watch-org-scan-default.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_SH="$SCRIPT_DIR/../agent-watch.sh"
STATE_SH="$SCRIPT_DIR/../agent-state.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; NC=''
fi

PASS=0
FAIL=0
TESTS=0

run_tc() {
  local tc_id="$1"; local desc="$2"; local body="$3"
  TESTS=$((TESTS + 1))
  local result
  if result="$(eval "$body" 2>&1)"; then
    if [ "$result" = "PASS" ]; then
      PASS=$((PASS + 1))
      printf "${GREEN}✅ %s${NC} %s\n" "$tc_id" "$desc"
    else
      FAIL=$((FAIL + 1))
      printf "${RED}❌ %s${NC} %s\n  result: %s\n" "$tc_id" "$desc" "$result"
    fi
  else
    FAIL=$((FAIL + 1))
    printf "${RED}❌ %s${NC} %s\n  error: %s\n" "$tc_id" "$desc" "$result"
  fi
}

# --- preflight: scripts exist and are executable ---
[ -x "$WATCH_SH" ] || { echo "ERROR: $WATCH_SH not executable" >&2; exit 2; }
[ -x "$STATE_SH" ] || { echo "ERROR: $STATE_SH not executable" >&2; exit 2; }

# TC1: --help lists --org flag and AGENT_WATCH_ORG env var
run_tc "TC1" "--help lists --org flag + AGENT_WATCH_ORG env var" '
  HELP_OUT="$(bash "$WATCH_SH" --help 2>&1)"
  if echo "$HELP_OUT" | grep -q "\-\-org <name>" && echo "$HELP_OUT" | grep -q "AGENT_WATCH_ORG"; then
    echo "PASS"
  else
    echo "FAIL: --org or AGENT_WATCH_ORG not in --help output"
  fi
'

# TC2: AGENT_WATCH_ORG default value is "atilproject" (when env unset)
# We can check this without running a full poll by inspecting the script source.
run_tc "TC2" "AGENT_WATCH_ORG defaults to \"atilproject\"" '
  if grep -qE "^AGENT_WATCH_ORG=\"\\\$\{AGENT_WATCH_ORG:-atilproject\}\"" "$WATCH_SH"; then
    echo "PASS"
  else
    echo "FAIL: AGENT_WATCH_ORG default = atilproject not found in script"
  fi
'

# TC3: AGENT_WATCH_ORG="" (empty) disables org-scan fallback.
# Implemented by checking the conditional logic: when --org flag empty AND
# AGENT_WATCH_ORG empty, the org-scan block must not fire. We check the source
# pattern: `[ -n "$ORG_FLAG" ] || [ -n "${AGENT_WATCH_ORG:-}" ]` wraps the org-scan.
run_tc "TC3" "Empty AGENT_WATCH_ORG disables org-scan" '
  if grep -qE "if \[ -n \"\\\$ORG_FLAG\" \] \|\| \[ -n \"\\\$\{AGENT_WATCH_ORG:-\}\" \]; then" "$WATCH_SH"; then
    echo "PASS"
  else
    echo "FAIL: org-scan guard condition not found"
  fi
'

# TC4: --org flag overrides AGENT_WATCH_ORG env var.
# Check precedence chain in REPOS_RAW resolution.
run_tc "TC4" "--org flag overrides AGENT_WATCH_ORG env var" '
  if grep -qE "ORG_FLAG=\"\\\$\{arg#--org=\}\"" "$WATCH_SH" \
     && grep -qE "ORG_RESOLVED=\"\\\$\{ORG_FLAG:-\\\$\{AGENT_WATCH_ORG\}\}\"" "$WATCH_SH"; then
    echo "PASS"
  else
    echo "FAIL: --org flag precedence not found in script"
  fi
'

# TC5: agent-watch.sh POLL_INTERVAL default = 180s (when state file empty)
run_tc "TC5" "agent-watch.sh POLL_INTERVAL default = 180s" '
  if grep -qE "POLL_INTERVAL=\"\\\$\{POLL_INTERVAL:-180\}\"" "$WATCH_SH"; then
    echo "PASS"
  else
    echo "FAIL: POLL_INTERVAL default 180 not found in agent-watch.sh"
  fi
'

# TC6: agent-state.sh DEFAULT_POLL default = 180s (when AGENT_POLL_INTERVAL_SEC unset)
run_tc "TC6" "agent-state.sh DEFAULT_POLL default = 180s" '
  if grep -qE "DEFAULT_POLL=\"\\\$\{AGENT_POLL_INTERVAL_SEC:-180\}\"" "$STATE_SH"; then
    echo "PASS"
  else
    echo "FAIL: DEFAULT_POLL default 180 not found in agent-state.sh"
  fi
'

# TC7: Archived repos skipped in org-scan (AGENT_WATCH_INCLUDE_ARCHIVED=0 default)
run_tc "TC7" "Archived repos skipped unless AGENT_WATCH_INCLUDE_ARCHIVED=1" '
  if grep -qF "[ \"\${AGENT_WATCH_INCLUDE_ARCHIVED:-0}\" != \"1\" ] && continue" "$WATCH_SH" \
     || grep -qF "\${AGENT_WATCH_INCLUDE_ARCHIVED:-0}" "$WATCH_SH" && grep -q "&& continue" "$WATCH_SH"; then
    echo "PASS"
  else
    echo "FAIL: archived-skip guard not found in org-scan loop"
  fi
'

# --- summary ---
echo
echo "================================================="
if [ "$FAIL" -eq 0 ]; then
  printf "${GREEN}d1041-agent-watch-org-scan-default: %d/%d PASS${NC}\n" "$PASS" "$TESTS"
  exit 0
else
  printf "${RED}d1041-agent-watch-org-scan-default: %d/%d PASS (%d FAIL)${NC}\n" "$PASS" "$TESTS" "$FAIL"
  exit 1
fi