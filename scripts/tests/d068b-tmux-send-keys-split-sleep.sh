#!/usr/bin/env bash
# d068b-tmux-send-keys-split-sleep.sh — regression test for Issue #935 (TD-068b)
#
# Why this test exists
# --------------------
# Issue #935 (TD-068b): tmux peer-poke / re-prime paths send text+Enter in a
# single `tmux send-keys` invocation (or in adjacent send-keys WITHOUT a sleep
# gap). When text and Enter arrive in the same tmux handler tick, long wake
# prompts may land in pane buffer as raw text without being submitted to
# Claude Code. Owner-observed symptom: pasted payloads treated as single
# literal keystrokes instead of typed-then-submitted prompts.
#
# Fix pattern per Issue #935 §Acceptance criteria:
#   - Two SEPARATE `tmux send-keys` invocations (text on line N, Enter on line N+1+)
#   - `sleep 0.5` between text send-keys and Enter send-keys
#
# 5 call sites per Issue #935 §Investigation findings:
#   1. scripts/reprime-agent.sh:144   — "/clear" Enter            (was BUNDLED)
#   2. scripts/reprime-agent.sh:160   — "/compact" Enter          (was BUNDLED)
#   3. scripts/agent-wake.sh:67-68    — split (no sleep)          (was split, flaky)
#   4. scripts/reprime-agent.sh:226-228 — paste-buffer + Enter    (was split, flaky)
#   5. scripts/agent-watch.sh:1494-1495 — split (no sleep)        (was split, flaky)
#
# TDD contract (≥5 TCs per ADR-0049, sister-pattern to d024):
#   TC1: No bundled text+Enter on a single send-keys line in any of the 3 scripts
#   TC2: Each text send-keys is followed by `sleep 0.5` before the Enter send-keys
#   TC3: reprime-agent.sh:144 — /clear split into two lines + sleep 0.5
#   TC4: reprime-agent.sh:160 — /compact split into two lines + sleep 0.5
#   TC5: agent-wake.sh:67-68 — sleep 0.5 inserted between text and Enter
#   TC6: agent-watch.sh:1494-1495 — sleep 0.5 inserted between text and Enter
#   TC7: No regression on existing Escape sequences (preserve sleep 1 + sleep 2 timings)
#   TC8: SMOKE — scripts parse cleanly (bash -n) — no shell syntax errors introduced
#
# RED-first expected: TC1, TC3, TC4 FAIL pre-fix (bundled sites exist).
#                     TC2, TC5, TC6, TC7, TC8 PASS pre-fix (sleep 0.5 absent = "no broken pattern" + smoke OK).
# GREEN expected: all 8 PASS post-fix.
#
# Sister-patterns:
#   - d024-agent-wake.sh (ADR-0033 dual-channel wake regression guard)
#   - d068-td067-combined.sh (Issue #927 TD-067b d-test sister-pattern)
#   - d015 + d031 (≥5 TCs baseline + auto-claim sister)
#   - TD-068 / Issue #920 (state-file-axis fix sister)
#
# Run: bash scripts/tests/d068b-tmux-send-keys-split-sleep.sh
# Exit: 0 = all pass, 1 = at least one fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENT_WAKE="$REPO_ROOT/scripts/agent-wake.sh"
AGENT_WATCH="$REPO_ROOT/scripts/agent-watch.sh"
REPRIME="$REPO_ROOT/scripts/reprime-agent.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""; fi

PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- preflight ---
for f in "$AGENT_WAKE" "$AGENT_WATCH" "$REPRIME"; do
  if [ ! -f "$f" ]; then
    printf "${R}ERROR: script missing: %s${D}\n" "$f" >&2
    exit 4
  fi
done

# ============================================================================
# TC1: No bundled text+Enter on a single send-keys line
# ============================================================================
# Per Issue #935 AC: NO call site has text and Enter in the SAME send-keys.
# Bundled pattern: tmux send-keys ... "TEXT" Enter   (both on one line)
section "TC1: No bundled text+Enter in any of the 3 scripts"
bundled_count=0
bundled_sites=""
for f in "$AGENT_WAKE" "$AGENT_WATCH" "$REPRIME"; do
  # Match: tmux send-keys ... "TEXT" Enter (text immediately followed by Enter, quoted or not)
  # Allow whitespace variants but NOT newline between text and Enter.
  hits=$(grep -nE 'tmux send-keys.*\bEnter\b' "$f" 2>/dev/null \
    | grep -vE '^\s*$' || true)
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Bundled = Enter appears on SAME LINE as a quoted/bare text payload
    # Heuristic: line contains both a quoted text payload ("..." or '...') AND Enter on same line,
    # OR line has text token + Enter on same line.
    # We exclude lines where Enter is the ONLY argument (just bare "Enter") and lines with -l flag.
    if echo "$line" | grep -qE 'tmux send-keys.*"(/|/)[a-z]+".*Enter|tmux send-keys.*'"'"'/(/|/)[a-z]+'"'"'.*Enter'; then
      bundled_count=$((bundled_count + 1))
      bundled_sites="${bundled_sites}${f}:${line#*:}  "
    fi
  done <<< "$hits"
done
if [ "$bundled_count" -eq 0 ]; then
  pass "no bundled text+Enter sites in 3 scripts"
else
  fail "found $bundled_count bundled text+Enter site(s)" "sites: $bundled_sites"
fi

# ============================================================================
# TC2: text send-keys is followed by `sleep 0.5` before Enter send-keys
# ============================================================================
# Per Issue #935 AC: ALL split sites have `sleep 0.5` between text and Enter.
# Pattern check: for each text send-keys line, look at next 5 lines for
#   `sleep 0.5` AND then a `tmux send-keys ... Enter` line.
section "TC2: sleep 0.5 between text send-keys and Enter send-keys (all 5 sites)"
# Extract text send-keys sites (the text line, not the Enter line). These have -l flag or quoted text.
text_site_count=0
sites_with_sleep=0
sites_missing_sleep=""
for f in "$AGENT_WAKE" "$AGENT_WATCH" "$REPRIME"; do
  # Get text lines (those that have -l or quoted /command), excluding Escape sites
  # (Escape sites are dialog-dismissal, not text+Enter payload delivery).
  text_lines=$(grep -nE 'tmux send-keys.*(-l |"[^"]+"|'"'"'[^'"'"']+'"'"')' "$f" 2>/dev/null \
    | grep -v 'Enter' \
    | grep -v 'Escape' \
    | head -10)
  while IFS= read -r tline; do
    [ -z "$tline" ] && continue
    lineno="${tline%%:*}"
    text_site_count=$((text_site_count + 1))
    # Look at next 5 lines for `sleep 0.5` AND `tmux send-keys ... Enter`
    next_block=$(sed -n "$((lineno+1)),$((lineno+5))p" "$f")
    if echo "$next_block" | grep -qE 'sleep 0\.5' \
       && echo "$next_block" | grep -qE 'tmux send-keys.*Enter'; then
      sites_with_sleep=$((sites_with_sleep + 1))
    else
      sites_missing_sleep="${sites_missing_sleep}${f}:${lineno}  "
    fi
  done <<< "$text_lines"
done
if [ "$text_site_count" -eq 0 ]; then
  fail "no text send-keys sites found in 3 scripts" "expected ≥5 sites per Issue #935 §Investigation findings"
elif [ "$sites_with_sleep" -eq "$text_site_count" ]; then
  pass "all $sites_with_sleep text send-keys sites have sleep 0.5 before Enter"
else
  fail "$((text_site_count - sites_with_sleep)) of $text_site_count text send-keys sites missing sleep 0.5" "missing: $sites_missing_sleep"
fi

# ============================================================================
# TC3: reprime-agent.sh — /clear split into two send-keys + sleep 0.5
# ============================================================================
section "TC3: reprime-agent.sh — /clear split + sleep 0.5"
# Per Issue #935: line 144 had bundled `tmux send-keys ... "/clear" Enter`.
# Post-fix: text send-keys line + sleep 0.5 line + Enter send-keys line.
clear_text=$(grep -nE 'tmux send-keys.*"/clear"' "$REPRIME" 2>/dev/null | grep -v 'Enter' | head -1)
clear_enter_nearby=false
if [ -n "$clear_text" ]; then
  clear_lineno="${clear_text%%:*}"
  next_block=$(sed -n "$((clear_lineno+1)),$((clear_lineno+3))p" "$REPRIME")
  if echo "$next_block" | grep -qE 'sleep 0\.5'; then
    clear_enter_nearby=true
  fi
fi
if [ -n "$clear_text" ] && [ "$clear_enter_nearby" = "true" ]; then
  pass "reprime-agent.sh /clear split + sleep 0.5 present"
else
  fail "reprime-agent.sh /clear not split or missing sleep 0.5" "expected text send-keys line + adjacent sleep 0.5 + Enter send-keys"
fi

# ============================================================================
# TC4: reprime-agent.sh — /compact split into two send-keys + sleep 0.5
# ============================================================================
section "TC4: reprime-agent.sh — /compact split + sleep 0.5"
compact_text=$(grep -nE 'tmux send-keys.*"/compact"' "$REPRIME" 2>/dev/null | grep -v 'Enter' | head -1)
compact_enter_nearby=false
if [ -n "$compact_text" ]; then
  compact_lineno="${compact_text%%:*}"
  next_block=$(sed -n "$((compact_lineno+1)),$((compact_lineno+3))p" "$REPRIME")
  if echo "$next_block" | grep -qE 'sleep 0\.5'; then
    compact_enter_nearby=true
  fi
fi
if [ -n "$compact_text" ] && [ "$compact_enter_nearby" = "true" ]; then
  pass "reprime-agent.sh /compact split + sleep 0.5 present"
else
  fail "reprime-agent.sh /compact not split or missing sleep 0.5" "expected text send-keys line + adjacent sleep 0.5 + Enter send-keys"
fi

# ============================================================================
# TC5: agent-wake.sh — sleep 0.5 between text and Enter
# ============================================================================
section "TC5: agent-wake.sh:67-68 — split + sleep 0.5 between text and Enter"
# Pattern: text send-keys on line N, sleep 0.5 on line N+1, Enter on line N+2
if [ ! -f "$AGENT_WAKE" ]; then
  fail "agent-wake.sh missing" "expected $AGENT_WAKE"
else
  # Find line number of `tmux send-keys -t "$pane_id" -l "$MSG"` (text send)
  text_line=$(grep -nE 'tmux send-keys.*-l.*"\$MSG"' "$AGENT_WAKE" 2>/dev/null | head -1)
  if [ -z "$text_line" ]; then
    fail "agent-wake.sh text send-keys (-l \"\$MSG\") missing" "expected pattern at line ~67"
  else
    text_lineno="${text_line%%:*}"
    # Check sleep 0.5 within next 3 lines
    next_block=$(sed -n "$((text_lineno+1)),$((text_lineno+3))p" "$AGENT_WAKE")
    if echo "$next_block" | grep -qE 'sleep 0\.5'; then
      pass "agent-wake.sh text send-keys (line $text_lineno) has sleep 0.5 within next 3 lines"
    else
      fail "agent-wake.sh missing sleep 0.5 between text and Enter" "expected 'sleep 0.5' within lines $((text_lineno+1))-$((text_lineno+3))"
    fi
  fi
fi

# ============================================================================
# TC6: agent-watch.sh — sleep 0.5 between text and Enter
# ============================================================================
section "TC6: agent-watch.sh:1494-1495 — split + sleep 0.5 between text and Enter"
if [ ! -f "$AGENT_WATCH" ]; then
  fail "agent-watch.sh missing" "expected $AGENT_WATCH"
else
  # Find text send-keys (line ~1494: tmux send-keys -t "$pane_id" -l "$prompt")
  text_line=$(grep -nE 'tmux send-keys.*-l.*"\$prompt"' "$AGENT_WATCH" 2>/dev/null | head -1)
  if [ -z "$text_line" ]; then
    fail "agent-watch.sh text send-keys (-l \"\$prompt\") missing" "expected pattern at line ~1494"
  else
    text_lineno="${text_line%%:*}"
    next_block=$(sed -n "$((text_lineno+1)),$((text_lineno+3))p" "$AGENT_WATCH")
    if echo "$next_block" | grep -qE 'sleep 0\.5'; then
      pass "agent-watch.sh text send-keys (line $text_lineno) has sleep 0.5 within next 3 lines"
    else
      fail "agent-watch.sh missing sleep 0.5 between text and Enter" "expected 'sleep 0.5' within lines $((text_lineno+1))-$((text_lineno+3))"
    fi
  fi
fi

# ============================================================================
# TC7: No regression on existing Escape + sleep 1 + Enter sequences
# ============================================================================
# Per Issue #935 §Doctrinal motivation: only the text+Enter pair needs sleep 0.5.
# Existing Escape sequences (e.g., reprime-agent.sh:137, 156) use larger sleeps
# (sleep 1, sleep 2) for dialog dismissal — preserve those.
section "TC7: No regression — existing Escape + sleep 1 / sleep 2 timings preserved"
# Count occurrences of Escape send-keys and check adjacent sleep values.
escape_sites=$(grep -nE 'tmux send-keys.*Escape' "$REPRIME" 2>/dev/null | wc -l | tr -d ' ')
if [ "$escape_sites" -lt 2 ]; then
  fail "expected ≥2 Escape send-keys in reprime-agent.sh" "found $escape_sites (e.g., lines 137, 156)"
else
  # Verify each Escape send-keys has a sleep (any duration) on the next line
  well_paced=0
  while IFS= read -r tline; do
    [ -z "$tline" ] && continue
    lineno="${tline%%:*}"
    next_line=$(sed -n "$((lineno+1))p" "$REPRIME")
    if echo "$next_line" | grep -qE 'sleep [0-9]'; then
      well_paced=$((well_paced + 1))
    fi
  done <<< "$(grep -nE 'tmux send-keys.*Escape' "$REPRIME" 2>/dev/null)"
  if [ "$well_paced" -eq "$escape_sites" ]; then
    pass "all $escape_sites Escape send-keys have adjacent sleep (existing pacing preserved)"
  else
    fail "$((escape_sites - well_paced)) Escape send-keys lost adjacent sleep" "regression in dialog-dismissal pacing"
  fi
fi

# ============================================================================
# TC8: SMOKE — bash -n syntax check on all 3 scripts
# ============================================================================
section "TC8: bash -n syntax check on all 3 scripts (no shell errors introduced)"
syntax_ok=true
syntax_fail_msg=""
for f in "$AGENT_WAKE" "$AGENT_WATCH" "$REPRIME"; do
  if ! bash -n "$f" 2>/dev/null; then
    syntax_ok=false
    syntax_fail_msg="${syntax_fail_msg}${f} "
  fi
done
if [ "$syntax_ok" = "true" ]; then
  pass "all 3 scripts pass bash -n syntax check"
else
  fail "shell syntax errors in: $syntax_fail_msg" "bash -n rejected the modified script"
fi

# ============================================================================
# TC9: reprime-agent.sh — paste-buffer + Enter split with sleep 0.5
# ============================================================================
# Per Issue #935 site 4: paste-buffer line + Enter send-keys line need
# `sleep 0.5` between them. Pattern: tmux paste-buffer -t "$TARGET" line
# followed (within 5 lines) by sleep 0.5 AND tmux send-keys ... Enter line.
section "TC9: reprime-agent.sh — paste-buffer + Enter split with sleep 0.5"
paste_line=$(grep -nE 'tmux paste-buffer' "$REPRIME" 2>/dev/null | head -1)
if [ -z "$paste_line" ]; then
  fail "tmux paste-buffer call missing in reprime-agent.sh" "expected paste-buffer pattern at line ~226"
else
  paste_lineno="${paste_line%%:*}"
  next_block=$(sed -n "$((paste_lineno+1)),$((paste_lineno+5))p" "$REPRIME")
  if echo "$next_block" | grep -qE 'sleep 0\.5' \
     && echo "$next_block" | grep -qE 'tmux send-keys.*Enter'; then
    pass "reprime-agent.sh paste-buffer (line $paste_lineno) has sleep 0.5 before Enter send-keys"
  else
    fail "reprime-agent.sh missing sleep 0.5 between paste-buffer and Enter" "expected 'sleep 0.5' within lines $((paste_lineno+1))-$((paste_lineno+5)) followed by Enter send-keys"
  fi
fi

# --- summary ---
echo
printf "${B}Summary:${D} %d PASS, %d FAIL\n" "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0