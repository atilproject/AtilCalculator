#!/usr/bin/env bash
# d1066-notify-stderr-surface.sh
#
# d1066 — Issue #1066 observability regression guard: notify.sh:154 swallows
#         agent-wake.sh stderr via `2>/dev/null` — defeats the structured-error
#         logs introduced by agent-wake.sh 3-fix hotfix (PR #1065, Issue #1064).
#
# Why this test exists
# --------------------
# scripts/notify.sh line 154:
#   if "$SCRIPT_DIR_NOTIFY/agent-wake.sh" "$ROLE" "$WAKE_PROMPT" 2>/dev/null; then
#     echo "Wake injected: role=$ROLE"
#   else
#     WAKE_RESULT=1
#     echo "ERROR: tmux-wake failed for role=$ROLE" >&2
#   fi
#
# Defect shape (Issue #1066 body):
#   1. `2>/dev/null` on line 154 swallows agent-wake.sh structured stderr:
#      - "ERROR: send-keys returned rc=$tmux_rc for pane=$pane_id role=$ROLE"
#        (Fix 1 log honesty, PR #1065)
#      - "ERROR: capture-pane verify failed for role=$ROLE pane=$pane_id
#        rc=$verify_rc (no match for prefix: $MSG_PREFIX)" (Fix 1+2)
#   2. Notify.sh caller only sees the less-informative line 158
#      ("ERROR: tmux-wake failed for role=$ROLE") without diagnostic context
#   3. Ops debugging tmux-wake failures cannot root-cause from logs alone
#
# Live instance: architect NIT #2 on PR #1065 (cmt 4970211783) — flagged as
# observability gap that defeats the whole purpose of agent-wake.sh Fix 1's
# log honesty. Filed per gap-close-on-exit hygiene.
#
# TC list (6 per ADR-0049 ≥5 baseline):
#   TC0 bash -n syntactic self-check (PASS pre/post hygiene)
#   TC1 happy path — agent-wake exits 0, "Wake injected" emitted (PASS pre/post)
#   TC2 structured-error propagates — agent-wake's stderr visible to caller (RED pre, GREEN post)
#   TC3 combined visibility — agent-wake fail → notify line 158 + agent-wake stderr both surface (RED pre, GREEN post)
#   TC4 line 154 syntactic check — does NOT contain `2>/dev/null` (architect NIT specific, RED pre, GREEN post)
#   TC5 Cadence Rule 1 atomic — INDEX.md has d1066 row (ADR-0055 §1)
#
# Run: bash scripts/tests/d1066-notify-stderr-surface.sh
# Exit: 0 = all pass, 1 = at least one fail.
#
# Sister-pattern lineage:
#   - d1082 (Issue #1089 BUG regression guard — same scripts/* impl lane,
#     same ADR-0049 ≥5 TCs baseline, same TC0+TC5 cadence structure, same
#     RETRO-005 #26 stderr-surface hygiene)
#   - d1025 (Issue #1083 Sprint 29 agent-wake-hotfix — same scripts/agent-wake.sh
#     structured-error surface doctrine, PR #1065 sister-pattern)
#   - d037 (notify-deprecation — same scripts/notify.sh doctrinel surface)
#   - d024 (agent-wake — original tmux-wake d-test, foundational)
#
# Refs: Issue #1066 (P3 chore, agent:developer — cycle ~#2190 orchestrator Sprint 29 W3 wave
#       dispatch, gap-closing scope per owner directive #3), Issue #1065 + PR #1065
#       (agent-wake.sh 3-fix hotfix origin, cmt 4970211783 architect NIT #2),
#       ADR-0033 (Issue #221 dual-channel doctrine — peer tmux panes must wake),
#       ADR-0044 (RED-first TDD doctrinal home — TC2-4 RED pre-impl),
#       ADR-0049 (≥5 TCs baseline — d1066 = 6 TCs met),
#       ADR-0055 §1 (Cadence Rule 1 atomic — d-test + INDEX.md row + impl same PR cluster),
#       ADR-0059 (cluster-squash doctrine — AtilCalculator impl + tmpl sister-PR),
#       RETRO-005 #26 hygiene (stderr surface, no `2>/dev/null` on final attempt
#       OR deterministic paths that defeat structured logging).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NOTIFY_SH="$REPO_ROOT/scripts/notify.sh"
INDEX_MD="$SCRIPT_DIR/INDEX.md"

# --- test framework ---
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

PASS=0; FAIL=0
declare -a FAILURES
if [[ -t 1 ]]; then
  G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else
  G=""; R=""; B=""; D=""
fi
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); FAILURES+=("$1"); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# --- preflight ---
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq required for d1066" >&2
  exit 127
fi
if [ ! -r "$NOTIFY_SH" ]; then
  echo "ERROR: notify.sh not found at $NOTIFY_SH" >&2
  exit 127
fi

# --- mock notify.sh test harness ---
# notify.sh calls "$SCRIPT_DIR_NOTIFY/agent-wake.sh" (absolute path computed
# via `cd "$(dirname "${BASH_SOURCE[0]}")"`). To mock agent-wake.sh,
# we copy notify.sh into TEST_TMPDIR + put mock agent-wake.sh alongside.
# notify.sh's $SCRIPT_DIR_NOTIFY then resolves to TEST_TMPDIR and invokes
# our mock.
TEST_NOTIFY_SH="$TEST_TMPDIR/notify.sh"
TEST_AGENT_WAKE_SH="$TEST_TMPDIR/agent-wake.sh"
MOCK_AGENT_WAKE_LOG="$TEST_TMPDIR/agent-wake.log"
: > "$MOCK_AGENT_WAKE_LOG"

cp "$NOTIFY_SH" "$TEST_NOTIFY_SH"
chmod +x "$TEST_NOTIFY_SH"

cat > "$TEST_AGENT_WAKE_SH" <<'MOCK_EOF'
#!/usr/bin/env bash
LOG="${MOCK_AGENT_WAKE_LOG}"
echo "$@" >> "$LOG"
case "${MOCK_AGENT_WAKE_MODE:-ok}" in
  ok)
    echo "Wake injected (mock)"
    exit 0
    ;;
  send_keys_error)
    # Mirrors agent-wake.sh Fix 1 structured error: send-keys non-zero exit
    echo "ERROR: send-keys returned rc=1 for pane=%1 role=tester" >&2
    exit 1
    ;;
  capture_pane_error)
    # Mirrors agent-wake.sh Fix 1+2 structured error: capture-pane verify fail
    echo "ERROR: capture-pane verify failed for role=tester pane=%1 rc=1 (no match for prefix: test)" >&2
    exit 1
    ;;
esac
MOCK_EOF
chmod +x "$TEST_AGENT_WAKE_SH"

# Helper: run notify.sh (mock copy) in -w -r wake mode with controlled env.
# Focus on tmux-wake path (TELEGRAM env unset → Telegram delivery skipped
# per AC1 Option B / Issue #1053). TMUX='' to bypass tmux-context check.
run_notify_wake() {
  : > "$MOCK_AGENT_WAKE_LOG"
  : > "$TEST_TMPDIR/stdout.log"
  : > "$TEST_TMPDIR/stderr.log"
  MOCK_AGENT_WAKE_MODE="$1" \
  TMUX='' \
  TELEGRAM_BOT_TOKEN='' \
  TELEGRAM_CHAT_ID='' \
    bash "$TEST_NOTIFY_SH" -l info -w -r tester "test message" \
    >"$TEST_TMPDIR/stdout.log" 2>"$TEST_TMPDIR/stderr.log"
  return $?
}

# ===========================================================================
# Test cases
# ===========================================================================

# TC0 — bash -n syntactic self-check (hygiene per ADR-0049 baseline).
section "TC0 — bash -n syntactic self-check"
if bash -n "$NOTIFY_SH" 2>/dev/null; then
  pass "TC0 — bash -n syntactic check PASS (notify.sh syntactically valid)"
else
  fail "TC0 — bash -n syntactic check FAIL" "notify.sh has bash syntax error — RED pre-impl, must be fixed before any TCs run"
fi

# TC1 — happy path: agent-wake exits 0 → "Wake injected" emitted (no regression).
section "TC1 — happy path: agent-wake succeeds"
run_notify_wake "ok"
TC1_RC=$?
TC1_STDOUT_CONTENT=$(cat "$TEST_TMPDIR/stdout.log" 2>/dev/null || echo "")
if [ "$TC1_RC" -eq 0 ] && echo "$TC1_STDOUT_CONTENT" | grep -q "Wake injected"; then
  pass "TC1 — happy path: rc=0 + 'Wake injected' emitted (no regression)"
else
  fail "TC1 — happy path: rc=$TC1_RC, stdout='$TC1_STDOUT_CONTENT'" "expected rc=0 + stdout contains 'Wake injected'"
fi

# TC2 — structured-error propagates: when agent-wake emits structured error to
# its own stderr, the caller (notify.sh) must surface that error to its caller
# stderr too — NOT swallow via `2>/dev/null`.
# Pre-impl: FAIL (notify.sh:154 2>/dev/null swallows stderr → RED)
# Post-impl: PASS (2>/dev/null removed → agent-wake's stderr surfaces)
section "TC2 — structured-error propagates to notify.sh caller stderr"
run_notify_wake "send_keys_error" || true
TC2_STDERR_CONTENT=$(cat "$TEST_TMPDIR/stderr.log" 2>/dev/null || echo "")
# Expect agent-wake's "send-keys" structured error to be visible in notify.sh's
# caller stderr. Note: tmux-wake runs as PATH-resolved via TEST_TMPDIR, so the
# mock's stderr (when not swallowed) propagates directly to notify.sh's stderr.
if echo "$TC2_STDERR_CONTENT" | grep -q "send-keys"; then
  pass "TC2 — agent-wake's 'send-keys' structured error propagated to notify.sh caller stderr (observability restored)"
else
  fail "TC2 — agent-wake's structured error NOT visible in notify.sh caller stderr (got: '$TC2_STDERR_CONTENT')" "expected stderr contains 'send-keys' from agent-wake.sh | RED pre-impl (\`2>/dev/null\` swallows); GREEN post-impl (stderr surfaces)"
fi

# TC3 — combined visibility: when agent-wake fails, notify.sh should emit BOTH
# its own context error (line 158: "tmux-wake failed for role=$ROLE") AND
# preserve agent-wake's structured stderr. Currently, line 158 IS emitted but
# agent-wake's stderr is swallowed → half-observability.
# Pre-impl: FAIL (only line 158 surfaces; agent-wake's stderr lost → RED)
# Post-impl: PASS (both line 158 + agent-wake stderr surface → GREEN)
section "TC3 — combined visibility on agent-wake fail (notify line 158 + agent-wake stderr)"
run_notify_wake "capture_pane_error" || true
TC3_STDERR_CONTENT=$(cat "$TEST_TMPDIR/stderr.log" 2>/dev/null || echo "")
TC3_HAS_NOTIFY_CONTEXT=0
TC3_HAS_AGENT_WAKE_CONTEXT=0
if echo "$TC3_STDERR_CONTENT" | grep -q "tmux-wake failed"; then
  TC3_HAS_NOTIFY_CONTEXT=1
fi
if echo "$TC3_STDERR_CONTENT" | grep -q "capture-pane verify"; then
  TC3_HAS_AGENT_WAKE_CONTEXT=1
fi
if [ "$TC3_HAS_NOTIFY_CONTEXT" -eq 1 ] && [ "$TC3_HAS_AGENT_WAKE_CONTEXT" -eq 1 ]; then
  pass "TC3 — combined visibility: notify line 158 ('tmux-wake failed') AND agent-wake's 'capture-pane' structured error both surface"
else
  fail "TC3 — combined visibility: notify context=$TC3_HAS_NOTIFY_CONTEXT, agent-wake context=$TC3_HAS_AGENT_WAKE_CONTEXT (expected both=1)" "stderr: '$TC3_STDERR_CONTENT' | RED pre-impl (only line 158 surfaces, agent-wake stderr swallowed); GREEN post-impl (both surface)"
fi

# TC4 — line syntactic check: the line that invokes agent-wake.sh must NOT
# contain `2>/dev/null`. Architect NIT #2 specific regression guard.
# Pre-impl: FAIL (`2>/dev/null` present on agent-wake.sh invocation → RED)
# Post-impl: PASS (`2>/dev/null` removed → GREEN)
section "TC4 — agent-wake.sh invocation line does NOT contain '2>/dev/null' (architect NIT #2)"
# Find the actual line that invokes agent-wake.sh (it's NOT always line 154,
# since the issue #1066 impl added a 4-line comment block above the invocation
# that shifts later agents to line ~158+). Dynamic line-finder ensures the test
# remains valid across impl iterations.
AGENT_WAKE_LINE="$(grep -n 'agent-wake.sh' "$NOTIFY_SH" | grep '"$SCRIPT_DIR_NOTIFY/agent-wake.sh"' | head -1 | cut -d: -f1)"
if [ -z "$AGENT_WAKE_LINE" ]; then
  # Fallback: any line invoking agent-wake.sh
  AGENT_WAKE_LINE="$(grep -n 'agent-wake.sh' "$NOTIFY_SH" | head -1 | cut -d: -f1)"
fi
AGENT_WAKE_INVOCATION="$(sed -n "${AGENT_WAKE_LINE}p" "$NOTIFY_SH" 2>/dev/null || echo "")"
if [ -n "$AGENT_WAKE_LINE" ] && echo "$AGENT_WAKE_INVOCATION" | grep -q "agent-wake.sh" && ! echo "$AGENT_WAKE_INVOCATION" | grep -q "2>/dev/null"; then
  pass "TC4 — line $AGENT_WAKE_LINE invokes agent-wake.sh WITHOUT '2>/dev/null' (architect NIT #2 fixed)"
else
  fail "TC4 — line $AGENT_WAKE_LINE invokes agent-wake.sh WITH '2>/dev/null' (architect NIT #2 unresolved)" "invocation line: '$AGENT_WAKE_INVOCATION' | RED pre-impl (\`2>/dev/null\` present on agent-wake invocation); GREEN post-impl"
fi

# TC5 — Cadence Rule 1 atomic (ADR-0055 §1): INDEX.md has d1066 row.
# Sister-pattern d1082 TC6 + d-retro-024 TC5 (INDEX.md row attestation).
section "TC5 — Cadence Rule 1 atomic (INDEX.md d1066 row present)"
if grep -q "d1066" "$INDEX_MD" 2>/dev/null; then
  pass "TC5 — scripts/tests/INDEX.md has d1066 row (Cadence Rule 1 atomic honored)"
else
  fail "TC5 — scripts/tests/INDEX.md missing d1066 row (Cadence Rule 1 atomic violation per ADR-0055 §1)" "Add d1066 row to INDEX.md in this commit per sister-pattern d1082 TC5"
fi

# ===========================================================================
# Summary
# ===========================================================================
printf "\n${B}==== Summary ====${D}\n"
printf "PASS: %d / %d\n" "$PASS" "$((PASS + FAIL))"
printf "FAIL: %d / %d\n" "$FAIL" "$((PASS + FAIL))"
if [ "$FAIL" -gt 0 ]; then
  printf "\n${R}Failed tests:${D}\n"
  for f in "${FAILURES[@]}"; do
    printf "  ${R}✗${D} %s\n" "$f"
  done
fi
printf "\n"
[ "$FAIL" -eq 0 ] || exit 1
