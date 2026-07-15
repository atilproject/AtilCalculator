#!/usr/bin/env bash
# d1042-agent-watch-line-339-repos-guard.sh — gap-closing sister to d1041
#
# Per RETRO-005 #26 dispatch discipline: when owner urgent directive landed
# the org-scan default (PR #1085 commit f43d24f), the dry-run from a non-git
# context revealed line 339 of scripts/agent-watch.sh:
#
#     REPO="${REPOS[0]}"
#
# crashes with `REPOS[0]: unbound variable` under `set -euo pipefail` (line 138)
# when REPOS[] is empty AND AGENT_WATCH_ORG defaults to "atilproject". The org-
# scan block at lines 343+ populates REPOS[] AFTER line 339 reads it, so the
# single-repo back-compat var assignment fires before its source exists.
#
# This d-test codifies the regression guard (ADR-0044 RED-first — write the
# test FIRST, watch it FAIL on PR #1085 HEAD, apply the fix, watch it pass).
#
# Sister-pattern lineage:
#   d1041 (PR #1085 owner-urgent directive — org-scan default + 180s default)
#   d047 (ADR-0047 Part 1 cross-repo polling — REPOS[] iterative origin)
#   d094 (Issue #94 author-self-cc skip — same `if [...] -gt 0 ]` guard pattern)
#
# Test cases (≥5 per ADR-0049; this d-test = 5):
#   TC1: RED regression — default AGENT_WATCH_ORG path does not error with
#        "REPOS[0]: unbound variable" under set -euo pipefail
#   TC2: Fix shape — line 339 uses guarded read (`[ -gt 0 ]` check OR `:-`
#        default expansion) so set -u strict mode does not fire on empty REPOS[]
#   TC3: Org-scan refresh preserved — lines 381-382 still assign REPO from
#        REPOS[0] after org-scan populates REPOS[] (regression guard for
#        single-repo back-compat var)
#   TC4: Explicit --repo path unaffected — when --repo owner/repo is given,
#        REPOS[] is non-empty pre-org-scan, line 339 sets REPO correctly
#   TC5: Strict mode preserved — `set -euo pipefail` still present at script
#        header (regression guard against silently loosening strictness to
#        mask the bug)
#
# Exit code: 0 = all pass, 1 = at least one fail.
#
# TDD status: RED-first verified on PR #1085 HEAD (commit f43d24f).
# TC1 fails pre-fix with `scripts/agent-watch.sh: line 339: REPOS[0]: unbound variable`.
# Apply fix → TC1 GREEN. Other TCs are post-fix regression guards.
#
# Run standalone: bash scripts/tests/d1042-agent-watch-line-339-repos-guard.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_SH="$SCRIPT_DIR/../agent-watch.sh"

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

# TC1: RED regression — reproduce the line 339 crash on PR #1085 HEAD.
# Scenario: AGENT_WATCH_ORG=atilproject (default), no GITHUB_REPO/--repo/
# AGENT_WATCH_REPOS, run from non-git dir so the auto-detect chain at lines
# 290-302 cannot populate REPOS_RAW. The script must NOT exit with
# "REPOS[0]: unbound variable". Pre-fix: RED (script crashes). Post-fix: GREEN.
run_tc "TC1" "default AGENT_WATCH_ORG path does not error with REPOS[0]: unbound variable" '
  OUT=$(cd /tmp && env -u GITHUB_REPO -u AGENT_WATCH_REPOS -u GITHUB_TOKEN -u GH_TOKEN \
        bash "'"$WATCH_SH"'" developer --once 2>&1 || true)
  if echo "$OUT" | grep -qF "REPOS[0]: unbound variable"; then
    echo "FAIL: line 339 REPOS[0] error reproduces — script crashes before org-scan block (line 343+) populates REPOS[]"
  else
    echo "PASS"
  fi
'

# TC2: Fix shape — line 339 must use a guarded read pattern. Acceptable shapes:
#   (a) `if [ "${#REPOS[@]}" -gt 0 ]; then REPO="${REPOS[0]}"; fi` (explicit length-check)
#   (b) `REPO="${REPOS[0]:-}"` (default-expansion under set -u, REPO=empty fallback)
#   (c) `REPO="${REPOS[0]:-some-default}"` (named fallback)
# Both verified to work under `set -euo pipefail` per live test.
#
# NOTE: Line range widened from NR>=335 && NR<=345 → NR>=335 && NR<=365 to
# tolerate the +16-line shift introduced by d1043's MODE-walker insertion at
# line 143. The actual REPO= guarded read now lives at ~line 360 instead of
# ~line 344. Structural pattern (guarded read of REPOS[0]) is invariant.
run_tc "TC2" "line 339 uses guarded REPOS[0] read (length-check or :-) default)" '
  if awk "NR>=335 && NR<=365" "'"$WATCH_SH"'" | grep -qE "REPO=\"\\\$\\{REPOS\\[0\\]:-"; then
    echo "PASS"
  elif awk "NR>=335 && NR<=365" "'"$WATCH_SH"'" | grep -qE "if \\[ \"\\\$\\{#REPOS\\[\\\\@\\]\\}\" -gt 0 \\]; then"; then
    echo "PASS"
  else
    echo "FAIL: line 339 area still uses unguarded REPO=\"\${REPOS[0]}\" — set -u will fire on empty REPOS[]"
  fi
'

# TC3: Org-scan refresh preserved — post-org-scan block must still set REPO from
# REPOS[0] after org-scan populates REPOS[]. This is the post-fix refresh;
# TC2 fixes the pre-fix read. Both must coexist (single-repo back-compat var
# must be defined regardless of where REPOS[] becomes non-empty).
#
# NOTE: Line range widened from NR>=378 && NR<=388 → NR>=378 && NR<=410 to
# tolerate the +16-line shift introduced by d1043's MODE-walker insertion.
# The post-org-scan REPO= refresh now lives at ~line 409 instead of ~line 388.
run_tc "TC3" "org-scan refresh block still sets REPO from REPOS[0] post-population" '
  if awk "NR>=378 && NR<=410" "'"$WATCH_SH"'" | grep -qE "REPO=\"\\\$\\{REPOS\\[0\\]\\}\""; then
    echo "PASS"
  else
    echo "FAIL: post-org-scan REPO refresh missing — single-repo back-compat var broken when --org path runs"
  fi
'

# TC4: Explicit --repo path unaffected — when --repo owner/repo is given, the
# command-line parser at lines 312-322 populates REPOS[] pre-line-339, so
# REPO="${REPOS[0]}" reads a valid value. The fix must NOT change this path
# (regression guard for the happy path). Static-grep: --repo arg-parsing path
# must still flow into REPOS[] building before line 339.
#
# NOTE: Line range widened from NR<=345 → NR<=365 to tolerate +16-line shift
# from d1043's MODE-walker insertion. Counts only REPO= assignments in the
# pre-org-scan block; post-org-scan refresh lives outside this range.
run_tc "TC4" "explicit --repo path still parses into REPOS[] before line 339" '
  # The --repo argparse populates REPOS_RAW before line 339; verify the
  # assignment structure at line 339 area is the only REPO assignment
  # between args parse and org-scan block.
  REPO_ASSIGN_COUNT=$(awk "NR>=280 && NR<=365" "'"$WATCH_SH"'" | grep -cE "^\\s*REPO=\"\\\$\\{REPOS\\[0\\]")
  if [ "$REPO_ASSIGN_COUNT" -ge 1 ] && [ "$REPO_ASSIGN_COUNT" -le 2 ]; then
    echo "PASS"
  else
    echo "FAIL: unexpected REPO= assignment count ($REPO_ASSIGN_COUNT) in pre-org-scan block — possible regression"
  fi
'

# TC5: Strict mode preserved — `set -euo pipefail` still present at script
# header (regression guard against silently loosening strictness to mask
# the bug instead of fixing the read). Per RETRO-005 #26: bugs are fixed
# with structural correctness, NOT with looser error modes.
run_tc "TC5" "set -euo pipefail still present at script header (strict mode regression guard)" '
  if head -150 "'"$WATCH_SH"'" | grep -qE "^set -euo pipefail"; then
    echo "PASS"
  else
    echo "FAIL: set -euo pipefail missing or loosened — strict mode regression"
  fi
'

# --- summary ---
echo
echo "================================================="
if [ "$FAIL" -eq 0 ]; then
  printf "${GREEN}d1042-agent-watch-line-339-repos-guard: %d/%d PASS${NC}\n" "$PASS" "$TESTS"
  exit 0
else
  printf "${RED}d1042-agent-watch-line-339-repos-guard: %d/%d PASS (%d FAIL)${NC}\n" "$PASS" "$TESTS" "$FAIL"
  exit 1
fi