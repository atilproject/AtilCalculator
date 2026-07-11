#!/usr/bin/env bash
# d065-dual-channel-enforcement.sh — ADR-0033 dual-channel enforcement regression test (5 TCs).
#
# Why this test exists
# --------------------
# Sprint 17 P1 incident (PR #598 reviewer feedback cmt 4826486795) flagged
# that scripts/notify.sh must HARD-ENFORCE dual-channel (-w -r) from tmux
# context — otherwise peer tmux panes never wake, agent-watch loops starve,
# and the system silently degrades to Telegram-only delivery. RETRO-012 §2a
# codifies the doctrine; this d-test is the regression guard.
#
# ADR-0033 (Issue #221, Issue #320, owner directive 2026-06-25):
#   - tmux-context callers (agents in tmux panes, owner in tmux session)
#     MUST use dual-channel (-w -r <role>)
#   - Direct notify.sh from tmux without -w -r → exit 2 (loud failure)
#   - Bypass options: scripts/ping.sh <role>, TMUX='', or non-tmux shell
#
# d065 = 4 TCs (TC1-TC4) programmatic enforcement via bash + fake-curl factory
# (sister-pattern to d064-cluster-lag.sh — both bash + fake-tool regression
# tests against shipped infra scripts).
# Post-S28-008 LEGACY-REMOVE: TC5 (legacy scripts/ping.sh wrapper bypass) REMOVED
# since ping.sh is gone. peer-poke.sh now provides the wrapper surface (see d296).
#
# Sister-pattern family (d-test lineage, ADR-0049):
#   - d058 (Issue #505 ADR-0038 §Work-Stream Awareness impl)
#   - d061 (RETRO-009 §3 post-squash label hygiene)
#   - d062 (Issue #552 AC2 watcher patch dual mechanism)
#   - d063 (RETRO-011 §1 stale-cc deadlock-breaker)
#   - d064 (ADR-0059 §1 cluster-squash batch-lag detection — direct sister, same week)
#
# 4 TCs (per STORY-S18-004 design doc §API contract + Issue #607 AC2 + RETRO-012 §2a):
#   TC1: tmux context WITHOUT -w -r → exit 2 (dual-channel hard-enforce, RETRO-012 §2a)
#   TC2: tmux context WITH -w -r <role> → exit 0 (proper usage path)
#   TC3: non-tmux context WITHOUT -w -r → exit 0 (backward compat for legacy + non-tmux shells)
#   TC4: -w without -r → exit 2 (orphan wake detection, ADR-0033 baseline)
# (TC5 = legacy scripts/ping.sh <role> wrapper bypass — REMOVED in S28-008 LEGACY-REMOVE
#  since ping.sh is gone. peer-poke.sh covers the same surface; see d296 for peer-poke tests.)
#
# Usage:
#   bash d065-dual-channel-enforcement.sh --self-test     # run inline fixture (4 TCs)
#
# Exit codes:
#   0 — all PASS (TC1-TC4 green, dual-channel enforcement active)
#   1 — at least one FAIL (RED state — enforcement missing OR fixture bug)
#   2 — preflight failure (missing tool, etc.)
#
# RED-first discipline (ADR-0044):
#   Pre-impl: TC1 PASS only if notify.sh exists; TC2-TC5 FAIL (impl missing or buggy)
#   Post-impl: all 4 TCs must PASS (TC5 removed in S28-008)
#   RETRO-012 §2a codifies: notify.sh impl shipped via PR #598 squash bf1e237,
#     so post-impl state is GREEN if all 4 TCs pass.
#
# Run standalone: bash scripts/tests/d065-dual-channel-enforcement.sh --self-test

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NOTIFY_SH="${REPO_ROOT}/scripts/notify.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; Y=""; B=""; D=""
fi

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Pre-flight
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required" >&2; exit 2; }

# Self-test mode
if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: bash $0 --self-test" >&2
  exit 2
fi

printf "${B}d065 self-test (4 TCs per ADR-0033 dual-channel enforcement, RETRO-012 §2a)${D}\n"
printf "${B}========================================================================${D}\n"
printf "  Impl under test: %s\n" "$NOTIFY_SH"
printf "  Fixture: fake-curl factory (mocks Telegram API for offline test)\n"
printf "  Sister-pattern: d064-cluster-lag.sh (ADR-0059, same week)\n"
printf "  RED-first: post-impl all 4 TCs must PASS (TC5 ping.sh wrapper bypass REMOVED in S28-008).\n\n"

PASS=0; FAIL=0; INFO=0
EXIT_CODE=0

# Test sandbox
TEST_TMPDIR="$(mktemp -d /tmp/d065-XXXXXX)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

# ============================================================================
# fake-curl factory — mocks `curl -s -X POST https://api.telegram.org/...`
# Returns '{"ok":true}' so notify.sh exits 0 cleanly (after dual-channel check)
# ============================================================================
# Usage: install_fake_curl <fake_bin_dir>
install_fake_curl() {
  local fake_bin="$1"
  mkdir -p "$fake_bin"

  cat > "$fake_bin/curl" <<'CURL_EOF'
#!/usr/bin/env bash
# fake-curl: minimal curl mock for d065 tests
# Echoes Telegram API success response so notify.sh exits 0
echo '{"ok":true,"result":{"message_id":12345}}'
exit 0
CURL_EOF
  chmod +x "$fake_bin/curl"
}

# Helper: run notify.sh with isolated env + fake-curl + TELEGRAM stubs
# Args: fake_bin, tmux_value ("" or "/tmp/fake.sock,12345,0"), extra_flags..., message
run_notify() {
  local fake_bin="$1"; shift
  local tmux_value="$1"; shift
  local extra_args=("$@")

  local notify_out_file="$TEST_TMPDIR/notify_out_$$_$RANDOM.txt"
  TMUX="$tmux_value" \
    PATH="$fake_bin:$PATH" \
    TELEGRAM_BOT_TOKEN="fake-bot-token-for-test" \
    TELEGRAM_CHAT_ID="12345" \
    bash "$NOTIFY_SH" "${extra_args[@]}" "test message body" \
    > "$notify_out_file" 2>&1
  local rc=$?
  NOTIFY_OUT="$(cat "$notify_out_file")"
  rm -f "$notify_out_file"
  return $rc
}

# ============================================================================
# TC1: tmux context WITHOUT -w -r → exit 2 (dual-channel hard-enforce)
# ============================================================================
section "TC1: tmux context WITHOUT -w -r → exit 2 (dual-channel hard-enforce per RETRO-012 §2a)"
if [ ! -f "$NOTIFY_SH" ]; then
  fail "TC1 — notify.sh not found" \
    "expected $NOTIFY_SH (impl not yet written per ADR-0044 RED-first)"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc1"
  install_fake_curl "$state/fake_bin"
  # Simulate tmux context with a non-empty TMUX var; no -w -r
  run_notify "$state/fake_bin" "/tmp/fake.sock,12345,0"

  if [ $? -ne 2 ]; then
    fail "TC1 — expected exit 2 (dual-channel enforcement blocks tmux callers w/o -w -r)" \
      "got rc=$? out=$NOTIFY_OUT. RETRO-012 §2a requires hard-enforce."
    EXIT_CODE=1
  elif ! echo "$NOTIFY_OUT" | grep -q "ADR-0033"; then
    fail "TC1 — expected error message referencing ADR-0033 dual-channel" \
      "got: $NOTIFY_OUT. Error message must teach caller the fix."
    EXIT_CODE=1
  else
    pass "TC1 — tmux without -w -r → exit 2 + ADR-0033 error (dual-channel enforced)"
  fi
fi

# ============================================================================
# TC2: tmux context WITH -w -r <role> → exit 0 (proper usage)
# ============================================================================
section "TC2: tmux context WITH -w -r developer → exit 0 (proper dual-channel)"
if [ ! -f "$NOTIFY_SH" ]; then
  fail "TC2 — notify.sh not found" \
    "expected $NOTIFY_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc2"
  install_fake_curl "$state/fake_bin"
  # TMUX set + -w -r developer → proper dual-channel path
  run_notify "$state/fake_bin" "/tmp/fake.sock,12345,0" "-l" "info" "-w" "-r" "developer"

  if [ $? -ne 0 ]; then
    fail "TC2 — expected exit 0 on proper dual-channel usage" \
      "got rc=$? out=$NOTIFY_OUT. -w -r developer from tmux must succeed."
    EXIT_CODE=1
  elif ! echo "$NOTIFY_OUT" | grep -q "Wake injected: role=developer"; then
    fail "TC2 — expected 'Wake injected: role=developer' confirmation" \
      "got: $NOTIFY_OUT. Dual-channel must echo the wake injection."
    EXIT_CODE=1
  else
    pass "TC2 — tmux with -w -r developer → exit 0 + wake injected (proper dual-channel)"
  fi
fi

# ============================================================================
# TC3: non-tmux context WITHOUT -w -r → exit 0 (backward compat)
# ============================================================================
section "TC3: non-tmux context WITHOUT -w -r → exit 0 (backward compat for legacy/non-tmux shells)"
if [ ! -f "$NOTIFY_SH" ]; then
  fail "TC3 — notify.sh not found" \
    "expected $NOTIFY_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc3"
  install_fake_curl "$state/fake_bin"
  # Empty TMUX + no -w -r → backward compat path (legacy scripts, owner regular shell)
  run_notify "$state/fake_bin" "" "-l" "info"

  if [ $? -ne 0 ]; then
    fail "TC3 — expected exit 0 on non-tmux context without -w -r" \
      "got rc=$? out=$NOTIFY_OUT. Non-tmux callers must not be blocked (backward compat)."
    EXIT_CODE=1
  else
    pass "TC3 — non-tmux without -w -r → exit 0 (backward compat preserved)"
  fi
fi

# ============================================================================
# TC4: -w without -r → exit 2 (orphan wake detection)
# ============================================================================
section "TC4: -w without -r → exit 2 (orphan wake detection, ADR-0033 baseline)"
if [ ! -f "$NOTIFY_SH" ]; then
  fail "TC4 — notify.sh not found" \
    "expected $NOTIFY_SH"
  EXIT_CODE=1
else
  state="$TEST_TMPDIR/tc4"
  install_fake_curl "$state/fake_bin"
  # Non-tmux (to isolate from TC1 enforcement) but with -w and no -r → orphan wake
  run_notify "$state/fake_bin" "" "-l" "info" "-w"

  if [ $? -ne 2 ]; then
    fail "TC4 — expected exit 2 on -w without -r" \
      "got rc=$? out=$NOTIFY_OUT. Orphan wake (no target role) must fail loud."
    EXIT_CODE=1
  elif ! echo "$NOTIFY_OUT" | grep -q "requires -r"; then
    fail "TC4 — expected error message about missing -r" \
      "got: $NOTIFY_OUT. Error must point to the fix (add -r <role>)."
    EXIT_CODE=1
  else
    pass "TC4 — -w without -r → exit 2 (orphan wake blocked)"
  fi
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
printf "  INFO: %d\n" "$INFO"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${R}RED state: %d TC(s) FAILING — enforcement missing or buggy per ADR-0044 RED-first${D}\n" "$FAIL"
  exit 1
fi

printf "\n${G}GREEN state: all 4 TCs PASS — dual-channel enforcement active (RETRO-012 §2a codification, post-S28-008 LEGACY-REMOVE)${D}\n"
exit 0