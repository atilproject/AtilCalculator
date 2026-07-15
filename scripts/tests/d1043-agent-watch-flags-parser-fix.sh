#!/usr/bin/env bash
# d1043-agent-watch-flags-parser-fix.sh — gap-closing sister to d1041+d1042
#
# Per Issue #1086 (acıl owner directive 2026-07-15T07:30Z+, "sistem çalışmıyor"):
# PR #1085 introduced --org/--repo flag parser paths that crash at runtime:
#
#   Bug A: scripts/agent-watch.sh:143 — MODE="${2:---once}" positional grab
#          captures the flag string when --repo/--org follows <role> directly.
#          Result: "Unknown mode: --repo" / "Unknown mode: --org" at line 2158,
#          exit 2.
#
#   Bug B: scripts/agent-watch.sh:373 — `for r in "${REPOS[@]:-}"` with empty
#          REPOS[] expands to ONE empty string. `_seen_repos[""]` triggers
#          bash 5.2+ "bad array subscript" error. Result: silent crash,
#          REPOS[] never populated for org-scan path.
#
# Both bugs were not caught by d1041 (which exercises AGENT_WATCH_ORG env-var
# path, not --org flag path). Dispatch spec TC1 ("--org atilproject produces
# REPOS[] of 5 non-archived repos") was a dispatch-spec, not a delivered TC.
# This d-test codifies the regression guard for both flag paths.
#
# Sister-pattern lineage:
#   d1041 (PR #1085 — org-scan + 180s cadence, env-var-only coverage)
#   d1042 (PR #1085 sister — line 339 REPOS[0] guard, length-guard pattern origin)
#   Issue #1086 (this d-test's spec origin)
#
# Test cases (≥5 per ADR-0049; this d-test = 7):
#   TC1: RED — `agent-watch.sh developer --org atilproject` does not error
#        with "bad array subscript" (Bug B regression guard)
#   TC2: RED — `agent-watch.sh developer --repo X --org Y` does not error
#        with "Unknown mode: --repo" (Bug A regression guard)
#   TC3: Fix shape — line 143 MODE detection walks argv (not positional ${2:-})
#   TC4: Fix shape — line 373 REPOS[] dedup uses length-guard pattern
#   TC5: Happy path — --repo X --once exits 0 (regression guard)
#   TC6: --org Y --loop recognized without parse error (MODE=loop detection)
#   TC7: Backward compat — --repo=X form (no space) works
#
# Exit code: 0 = all pass, 1 = at least one fail.
#
# TDD status: RED-first verified on PR #1085 HEAD. Apply fix → all GREEN.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_SH="$SCRIPT_DIR/../agent-watch.sh"

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
else
  GREEN=''; RED=''; NC=''
fi

PASS=0; FAIL=0; TESTS=0

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

[ -x "$WATCH_SH" ] || { echo "ERROR: $WATCH_SH not executable" >&2; exit 2; }

# TC1: RED — `agent-watch.sh developer --org atilproject` does not crash with
# `bad array subscript`. Pre-fix: RED (Bug B fires at line 373, REPOS[] never
# populated for org-scan path). Post-fix: GREEN (length-guard skips empty array).
run_tc "TC1" "--org <org> alone does not error with 'bad array subscript' (Bug B)" '
  OUT=$(cd /tmp && env -u GITHUB_REPO -u AGENT_WATCH_REPOS -u AGENT_WATCH_ORG \
        bash "'"$WATCH_SH"'" developer --org atilproject --once 2>&1 || true)
  if echo "$OUT" | grep -qF "bad array subscript"; then
    echo "FAIL: line 373 _seen_repos crash reproduces — empty REPOS[] + default-expansion triggers bash 5.2+ fatal"
  else
    echo "PASS"
  fi
'

# TC2: RED — `agent-watch.sh developer --repo X --org Y` does not error with
# "Unknown mode: --repo". Pre-fix: RED (Bug A fires at line 2158, exit 2).
# Post-fix: GREEN (MODE walker finds --once/--loop correctly through argv).
run_tc "TC2" "--repo X --org Y does not error with \"Unknown mode: --repo\" (Bug A)" '
  OUT=$(cd /tmp && env -u GITHUB_REPO -u AGENT_WATCH_REPOS -u AGENT_WATCH_ORG \
        bash "'"$WATCH_SH"'" developer --repo atilcan65/AtilCalculator --org atilproject --once 2>&1 || true)
  if echo "$OUT" | grep -qE "Unknown mode: --(repo|org)"; then
    echo "FAIL: line 143 MODE=\${2:-...} positional grab captures --repo/--org flag string instead of --once/--loop"
  else
    echo "PASS"
  fi
'

# TC3: Fix shape — line 143 area must use argv walker, not positional ${2:-...}
run_tc "TC3" "line 143 MODE detection uses argv walker (not positional grab)" '
  if awk "NR>=140 && NR<=175" "'"$WATCH_SH"'" | grep -qF "MODE=\"\${2:---once\"}"; then
    echo "FAIL: line 143 still uses MODE=\${2:-...} positional grab — Bug A unfixed"
  elif awk "NR>=140 && NR<=175" "'"$WATCH_SH"'" | grep -qF "case \"\$_arg\" in"; then
    echo "PASS"
  else
    echo "FAIL: no argv walker (case \$_arg in) detected at lines 140-175"
  fi
'

# TC4: Fix shape — line 373 area uses length-guard pattern, not bare ${REPOS[@]:-}
run_tc "TC4" "line 373 REPOS[] dedup uses length-guard (not bare \${REPOS[@]:-})" '
  if awk "NR>=380 && NR<=395" "'"$WATCH_SH"'" | grep -qF "for r in \"\${REPOS[@]:-}\""; then
    echo "FAIL: bare \${REPOS[@]:-} still used at lines 380-395 — empty REPOS[] + assoc-array key crash (Bug B unfixed)"
  elif awk "NR>=380 && NR<=395" "'"$WATCH_SH"'" | grep -qF "if [ \"\${#REPOS[@]}\" -gt 0 ]"; then
    echo "PASS"
  else
    echo "FAIL: no length-guard (\${#REPOS[@]} -gt 0) detected at lines 380-395"
  fi
'

# TC5: Happy path — --repo X --once exits 0 (regression guard)
run_tc "TC5" "--repo X --once exits 0 (happy-path regression guard)" '
  OUT=$(cd /tmp && env -u GITHUB_REPO -u AGENT_WATCH_REPOS -u AGENT_WATCH_ORG \
        bash "'"$WATCH_SH"'" developer --repo atilcan65/AtilCalculator --once 2>&1 || true)
  if echo "$OUT" | grep -qE "Unknown mode|bad array subscript|REPOS\[0\]: unbound"; then
    echo "FAIL: --repo X --once should exit clean but got error: $(echo "$OUT" | head -3)"
  else
    echo "PASS"
  fi
'

# TC6: --org Y --loop recognized without parse error
run_tc "TC6" "--org Y --loop recognized without parse error (MODE=loop detection)" '
  OUT=$(timeout 2 bash "'"$WATCH_SH"'" developer --org atilproject --loop 2>&1 || true)
  if echo "$OUT" | grep -qE "Unknown mode|bad array subscript"; then
    echo "FAIL: --org Y --loop should parse clean but got error: $(echo "$OUT" | head -3)"
  else
    echo "PASS"
  fi
'

# TC7: --repo=X form (no space) works — backward compat with flag-equality syntax
run_tc "TC7" "--repo=X form (no space) works (backward-compat regression guard)" '
  OUT=$(cd /tmp && env -u GITHUB_REPO -u AGENT_WATCH_REPOS -u AGENT_WATCH_ORG \
        bash "'"$WATCH_SH"'" developer --repo=atilcan65/AtilCalculator --once 2>&1 || true)
  if echo "$OUT" | grep -qE "Unknown mode|bad array subscript|REPOS\[0\]: unbound"; then
    echo "FAIL: --repo=X should parse clean but got error: $(echo "$OUT" | head -3)"
  else
    echo "PASS"
  fi
'

echo
echo "================================================="
if [ "$FAIL" -eq 0 ]; then
  printf "${GREEN}d1043-agent-watch-flags-parser-fix: %d/%d PASS${NC}\n" "$PASS" "$TESTS"
  exit 0
else
  printf "${RED}d1043-agent-watch-flags-parser-fix: %d/%d PASS (%d FAIL)${NC}\n" "$PASS" "$TESTS" "$FAIL"
  exit 1
fi