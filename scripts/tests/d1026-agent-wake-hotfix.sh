#!/usr/bin/env bash
# d1026-agent-wake-hotfix.sh — Sprint 29 W2 agent-wake.sh 3-fix hotfix d-test
#
# Doctrinal contract (≥5 TCs baseline per ADR-0049 + `docs/sprints/current/plan.md`
#   "≥5 TCs behavioral, ≥3 TCs hygiene/docs"):
#   TC0: bash -n syntactic self-check (preflight)
#   TC1: Fix 1 (log honesty) — agent-wake.sh exits 1 when tmux send-keys
#        returns non-zero (mock via PATH shim)
#   TC2: Fix 1 (log honesty) — error log line contains role=<ROLE>,
#        pane=<pane_id>, rc=<N> context
#   TC3: Fix 2 (pane_id lookup) — orchestrator → <session>:0.0 by pane_index
#        (NOT title match; title-match fails because real pane titles are
#        descriptive, not UPPERCASE)
#   TC4: Fix 2 (pane_id lookup) — deterministic role→pane_index map
#        (orchestrator=0, product-manager=1, architect=2, developer=3,
#        tester=4, human=5)
#   TC5: Fix 3 (capture-pane verify) — post-send capture-pane runs against
#        target pane and succeeds within 1s timeout
#   TC6: Fix 3 (capture-pane verify) — verification grep matches wake text
#        prefix; on match exit 0, on mismatch exit 1
#
# Doctrinal home: Issue #1062 (Phase A — this PR) + Issue #1061 (cluster
#   coord) + Issue #1063 (Phase B impl, blocked) + Issue #93 (template
#   sister mirror) + Issue #94 (template impl sister).
#
# RED-first per ADR-0044: TC1, TC2, TC5, TC6 FAIL pre-impl on current
#   `|| exit 0` masking bug + missing capture-pane verify. TC3, TC4 FAIL
#   pre-impl on title-match fragility (titles are descriptive, not UPPERCASE
#   roles) — fallback `${session}:main.0` is the wrong format (`:0.0` is
#   canonical). TC0 PASS-by-self.
# Post-impl (Fix 1 + Fix 2 + Fix 3 in Issue #1063): all 6 TCs GREEN.
#
# Cadence Rule 1 atomic (ADR-0055 §1): this d-test file + INDEX.md entry
#   land in same commit. Sister-pattern per d1024/d1025 (S29 ping-env-
#   decoupling family) + d058 (fake-session isolation).
#
# Sister-patterns (≥3 per ADR-0049):
#   - d1024 (S29 ping-env-decoupling — fake-tmux-session fixture pattern,
#     same PATH-shim approach for mocked tmux failures)
#   - d1025 (template sister of d1024 — same 5-TC structure, same exit-code
#     matrix semantics)
#   - d058 (work-stream aware — owner-mercy-gate fake-session isolation,
#     no live peer pane touched)
#   - d296 (peer-poke argv + usage discipline — argv shape consistency)
#   - d320 (architect-authored stale-verdict contract — exit-code + stderr
#     structure conventions)
#
# Cross-refs:
#   - ADR-0033 (dual-channel doctrine — the doctrine these fixes preserve)
#   - ADR-0044 (RED-first TDD doctrinal home)
#   - ADR-0049 (d-test framework ≥5 TCs baseline)
#   - ADR-0055 §1 (Cadence Rule 1 atomic)
#   - ADR-0059 (cluster-squash — d1026 ships BEFORE Issue #1063 impl)
#   - TD-068b (Issue #935 — WAKE_KEYS_GAP_SEC env override, test fixture
#     tolerance window)
#   - ADR-0031 (owner merge gate — only human squash-merges impl PR)

set -euo pipefail

# Test fixture: PATH-shim for `tmux` to enable mocked failure modes
# (send-keys fail) and deterministic behavior across all 6 TCs. When the
# PATH shim is in effect, the real tmux binary is NOT invoked — every TC
# is hermetic and parallelizable. Live peer panes are NEVER touched (per
# d058 sister-pattern: owner-mercy-gate isolation).

SCRIPT_DIR_D1026="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_D1026="$(cd "${SCRIPT_DIR_D1026}/../.." && pwd)"
AGENT_WAKE_SH="${REPO_ROOT_D1026}/scripts/agent-wake.sh"

PASS=0
FAIL=0

check() {
    local label="$1"
    local result="${2:-FAIL}"
    local detail="${3:-}"
    if [ "$result" = "PASS" ]; then
        echo "  ✅ $label"
        PASS=$((PASS+1))
    else
        echo "  ❌ $label: $detail"
        FAIL=$((FAIL+1))
    fi
}

require_dependencies() {
    local missing=0
    if ! command -v bash >/dev/null 2>&1; then
        echo "FATAL: bash not found in PATH" >&2
        missing=1
    fi
    if [ ! -f "$AGENT_WAKE_SH" ]; then
        echo "FATAL: required script missing: $AGENT_WAKE_SH" >&2
        missing=1
    fi
    [ "$missing" -eq 0 ] || exit 2
}

# create_tmux_shim <shim_dir> <send_keys_rc> <capture_pane_text>
#   Creates a PATH-shim `tmux` binary in <shim_dir>/tmux that:
#     - has-session → exit 0
#     - list-panes  → echo 6 panes with DESCRIPTIVE (non-UPPERCASE) titles
#                    so title-match always fails (forcing Fix 2 test path)
#     - send-keys   → exit <send_keys_rc> (0 = success, 1 = failure)
#     - capture-pane → echo <capture_pane_text> (for Fix 3 verification)
#     - everything else → exit 0
create_tmux_shim() {
    local shim_dir="$1"
    local send_keys_rc="$2"
    local capture_pane_text="$3"
    mkdir -p "$shim_dir"
    cat > "${shim_dir}/tmux" <<EOF
#!/bin/bash
case "\$1" in
  has-session)
    exit 0
    ;;
  list-panes)
    # Output: pane_id + descriptive title per pane (NO UPPERCASE role names).
    # This forces title-match to fail in current agent-wake.sh, exercising
    # the Fix 2 test path (pane_index lookup vs fallback).
    cat <<'EOP'
%0 Some descriptive orchestrator work pane
%1 Product manager pane with descriptive label
%2 Architect pane arbitrary title
%3 Developer pane arbitrary descriptive title
%4 Tester pane arbitrary title
%5 Owner/human pane arbitrary
EOP
    ;;
  send-keys)
    # Log target for inspection (used by TC3/TC4 to verify pane_id format)
    echo "SENDKEYS \$@" >> /tmp/d1026-spy.log
    exit ${send_keys_rc}
    ;;
  capture-pane)
    # Used by TC5/TC6 verification path
    echo "${capture_pane_text}"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
    chmod +x "${shim_dir}/tmux"
}

# Verify a pane_id format from spy log
# Returns PASS if spy log shows send-keys target = expected_format
verify_sendkeys_target() {
    local session="$1"
    local expected_format="$2"  # e.g. ":0.0" or ":main.0"
    local spy_log="${3:-/tmp/d1026-spy.log}"
    [ -f "$spy_log" ] || { echo "FAIL: spy log missing"; return 1; }
    if grep -qF "${session}${expected_format}" "$spy_log"; then
        return 0
    fi
    echo "FAIL: spy log missing '${session}${expected_format}': $(cat "$spy_log")"
    return 1
}

require_dependencies

# -------------------------------------------------------------------------
# TC0 (preflight): bash -n syntactic validity of this d-test file
# -------------------------------------------------------------------------
if bash -n "$0" 2>/dev/null; then
    check "TC0 (bash -n self-check)" "PASS"
else
    check "TC0 (bash -n self-check)" "bash syntax error"
    exit 1
fi

# -------------------------------------------------------------------------
# TC1: Fix 1 (log honesty) — agent-wake.sh exits 1 when send-keys fails
# -------------------------------------------------------------------------
echo ""
echo "TC1: Fix 1 (log honesty) — exit 1 on send-keys fail"
SHIM_DIR_TC1=$(mktemp -d)
rm -f /tmp/d1026-spy.log
create_tmux_shim "$SHIM_DIR_TC1" 1 "irrelevant"
TC1_EXIT=$(PATH="${SHIM_DIR_TC1}:$PATH" \
    TMUX_SESSION="fake-session-$$" \
    bash "$AGENT_WAKE_SH" orchestrator "test d1026 tc1 send-keys fail probe" \
    2>/dev/null; echo $?)
# RED-first expectation: exit=1 (current `|| exit 0` masks → exit=0, FAIL)
if [ "$TC1_EXIT" = "1" ]; then
    check "TC1 (exit 1 on send-keys fail)" "PASS"
else
    check "TC1 (exit 1 on send-keys fail)" \
        "exit=$TC1_EXIT (expect 1 — current \`|| exit 0\` masks failure)"
fi
rm -rf "$SHIM_DIR_TC1"
rm -f /tmp/d1026-spy.log

# -------------------------------------------------------------------------
# TC2: Fix 1 (log honesty) — error log contains role=, pane=, rc= context
# -------------------------------------------------------------------------
echo ""
echo "TC2: Fix 1 (log honesty) — error log role=, pane=, rc= context"
SHIM_DIR_TC2=$(mktemp -d)
create_tmux_shim "$SHIM_DIR_TC2" 1 "irrelevant"
TC2_STDERR=$(mktemp)
PATH="${SHIM_DIR_TC2}:$PATH" \
    TMUX_SESSION="fake-session-$$" \
    bash "$AGENT_WAKE_SH" orchestrator "test d1026 tc2 error log probe" \
    2>"$TC2_STDERR" >/dev/null
TC2_STDERR_CONTENT=$(cat "$TC2_STDERR")
rm -f "$TC2_STDERR"
# RED-first expectation: stderr contains role=orchestrator AND pane=... AND rc=...
TC2_HAS_ROLE=$(echo "$TC2_STDERR_CONTENT" | grep -ciE "role[=: ]orchestrator" || true)
TC2_HAS_PANE=$(echo "$TC2_STDERR_CONTENT" | grep -ciE "pane[=: ]" || true)
TC2_HAS_RC=$(echo "$TC2_STDERR_CONTENT" | grep -ciE "rc[=: ][0-9]+" || true)
if [ "$TC2_HAS_ROLE" -gt 0 ] && [ "$TC2_HAS_PANE" -gt 0 ] && [ "$TC2_HAS_RC" -gt 0 ]; then
    check "TC2 (error log contains role+pane+rc)" "PASS"
else
    check "TC2 (error log contains role+pane+rc)" \
        "role=$TC2_HAS_ROLE pane=$TC2_HAS_PANE rc=$TC2_HAS_RC (stderr=$TC2_STDERR_CONTENT)"
fi
rm -rf "$SHIM_DIR_TC2"

# -------------------------------------------------------------------------
# TC3: Fix 2 (pane_id lookup) — orchestrator → <session>:0.0 by pane_index
# -------------------------------------------------------------------------
echo ""
echo "TC3: Fix 2 (pane_id lookup) — orchestrator → <session>:0.0 by pane_index"
SHIM_DIR_TC3=$(mktemp -d)
rm -f /tmp/d1026-spy.log
create_tmux_shim "$SHIM_DIR_TC3" 0 "irrelevant"
SESSION_TC3="d1026-tc3-$$"
PATH="${SHIM_DIR_TC3}:$PATH" \
    TMUX_SESSION="$SESSION_TC3" \
    bash "$AGENT_WAKE_SH" orchestrator "test d1026 tc3 pane_index probe" \
    >/dev/null 2>&1
# RED-first expectation: send-keys target = "<session>:0.0" (NOT "<session>:main.0")
# Pre-impl: title-match fails (descriptive titles) → fallback
# `${TMUX_SESSION}:main.0` is used (BUG). Post-impl: `:0.0` (CORRECT).
if verify_sendkeys_target "$SESSION_TC3" ":0.0"; then
    check "TC3 (orchestrator → :0.0 by pane_index)" "PASS"
else
    SPY_LOG=$(cat /tmp/d1026-spy.log 2>/dev/null || echo "no log")
    check "TC3 (orchestrator → :0.0 by pane_index)" \
        "send-keys target wrong format — spy log: $SPY_LOG"
fi
rm -rf "$SHIM_DIR_TC3"
rm -f /tmp/d1026-spy.log

# -------------------------------------------------------------------------
# TC4: Fix 2 (pane_id lookup) — deterministic role→pane_index map
#      (orchestrator=0, product-manager=1, architect=2, developer=3,
#       tester=4, human=5)
# -------------------------------------------------------------------------
echo ""
echo "TC4: Fix 2 (pane_id lookup) — deterministic role→pane_index map"
SHIM_DIR_TC4=$(mktemp -d)
rm -f /tmp/d1026-spy.log
create_tmux_shim "$SHIM_DIR_TC4" 0 "irrelevant"
SESSION_TC4="d1026-tc4-$$"
declare -A ROLE_INDEX_MAP=(
    ["orchestrator"]="0"
    ["product-manager"]="1"
    ["architect"]="2"
    ["developer"]="3"
    ["tester"]="4"
    ["human"]="5"
)
TC4_ALL_PASS=true
TC4_DETAIL=""
for ROLE in orchestrator product-manager architect developer tester human; do
    EXPECTED_INDEX="${ROLE_INDEX_MAP[$ROLE]}"
    EXPECTED_TARGET="${SESSION_TC4}:0.${EXPECTED_INDEX}"
    PATH="${SHIM_DIR_TC4}:$PATH" \
        TMUX_SESSION="$SESSION_TC4" \
        bash "$AGENT_WAKE_SH" "$ROLE" "test d1026 tc4 $ROLE probe" \
        >/dev/null 2>&1
    if ! grep -qF "$EXPECTED_TARGET" /tmp/d1026-spy.log; then
        TC4_ALL_PASS=false
        SPY_LOG=$(cat /tmp/d1026-spy.log 2>/dev/null | tr '\n' '|' | head -c 200)
        TC4_DETAIL="$ROLE → expected $EXPECTED_TARGET, spy log so far: $SPY_LOG"
        break
    fi
    # Reset spy log per role for cleaner failure attribution
    : > /tmp/d1026-spy.log
done
if [ "$TC4_ALL_PASS" = "true" ]; then
    check "TC4 (deterministic role→pane_index map)" "PASS"
else
    check "TC4 (deterministic role→pane_index map)" "$TC4_DETAIL"
fi
rm -rf "$SHIM_DIR_TC4"
rm -f /tmp/d1026-spy.log

# -------------------------------------------------------------------------
# TC5: Fix 3 (capture-pane verify) — post-send capture-pane runs within 1s
# -------------------------------------------------------------------------
echo ""
echo "TC5: Fix 3 (capture-pane verify) — capture-pane invoked post-send"
# Use a real fake tmux session (not a shim) so capture-pane works natively.
# Need capture-pane to be invoked — track via an extra log line in shim.
SHIM_DIR_TC5=$(mktemp -d)
cat > "${SHIM_DIR_TC5}/tmux" <<'EOF'
#!/bin/bash
echo "TMUX_CALL: $@" >> /tmp/d1026-tc5-call.log
case "$1" in
  has-session) exit 0 ;;
  list-panes)
    cat <<'EOP'
%0 Orchestrator pane descriptive title
%1 Product manager pane
%2 Architect pane
%3 Developer pane
%4 Tester pane
%5 Owner pane
EOP
    ;;
  send-keys) exit 0 ;;
  capture-pane) echo "fake pane content for verification" ;;
  *) exit 0 ;;
esac
EOF
chmod +x "${SHIM_DIR_TC5}/tmux"
rm -f /tmp/d1026-tc5-call.log
TC5_START=$(date +%s)
PATH="${SHIM_DIR_TC5}:$PATH" \
    TMUX_SESSION="fake-session-$$" \
    bash "$AGENT_WAKE_SH" orchestrator "test d1026 tc5 capture-pane probe" \
    >/dev/null 2>&1
TC5_ELAPSED=$(($(date +%s) - TC5_START))
# RED-first expectation: capture-pane was invoked (post-send verify present)
# Pre-impl: no capture-pane call → FAIL
if grep -qF "TMUX_CALL: capture-pane" /tmp/d1026-tc5-call.log && \
   [ "$TC5_ELAPSED" -le 2 ]; then
    check "TC5 (capture-pane invoked within 2s)" "PASS"
else
    CALL_LOG=$(cat /tmp/d1026-tc5-call.log 2>/dev/null | tr '\n' '|' | head -c 300 || echo "no log")
    check "TC5 (capture-pane invoked within 2s)" \
        "elapsed=${TC5_ELAPSED}s, capture-pane missing — calls: $CALL_LOG"
fi
rm -rf "$SHIM_DIR_TC5"
rm -f /tmp/d1026-tc5-call.log

# -------------------------------------------------------------------------
# TC6: Fix 3 (capture-pane verify) — wake text prefix grep; exit 0 match, 1 mismatch
# -------------------------------------------------------------------------
echo ""
echo "TC6: Fix 3 (capture-pane verify) — wake text prefix grep"
# TC6a: capture-pane returns MATCHING text → exit 0
SHIM_DIR_TC6A=$(mktemp -d)
cat > "${SHIM_DIR_TC6A}/tmux" <<'EOF'
#!/bin/bash
case "$1" in
  has-session) exit 0 ;;
  list-panes)
    cat <<'EOP'
%0 Orchestrator pane descriptive title
%1 PM pane
%2 Arch pane
%3 Dev pane
%4 Tester pane
%5 Owner pane
EOP
    ;;
  send-keys) exit 0 ;;
  capture-pane) echo "test d1026 tc6 match probe FULL_TEXT" ;;
  *) exit 0 ;;
esac
EOF
chmod +x "${SHIM_DIR_TC6A}/tmux"
TC6A_EXIT=$(PATH="${SHIM_DIR_TC6A}:$PATH" \
    TMUX_SESSION="fake-session-$$" \
    bash "$AGENT_WAKE_SH" orchestrator "test d1026 tc6 match probe FULL_TEXT" \
    >/dev/null 2>&1; echo $?)
rm -rf "$SHIM_DIR_TC6A"

# TC6b: capture-pane returns NON-matching text → exit 1
SHIM_DIR_TC6B=$(mktemp -d)
cat > "${SHIM_DIR_TC6B}/tmux" <<'EOF'
#!/bin/bash
case "$1" in
  has-session) exit 0 ;;
  list-panes)
    cat <<'EOP'
%0 Orchestrator pane descriptive title
%1 PM pane
%2 Arch pane
%3 Dev pane
%4 Tester pane
%5 Owner pane
EOP
    ;;
  send-keys) exit 0 ;;
  capture-pane) echo "totally different content NOT matching the wake prefix" ;;
  *) exit 0 ;;
esac
EOF
chmod +x "${SHIM_DIR_TC6B}/tmux"
TC6B_EXIT=$(PATH="${SHIM_DIR_TC6B}:$PATH" \
    TMUX_SESSION="fake-session-$$" \
    bash "$AGENT_WAKE_SH" orchestrator "test d1026 tc6 mismatch probe FULL_TEXT" \
    >/dev/null 2>&1; echo $?)
rm -rf "$SHIM_DIR_TC6B"

# RED-first expectation (current behavior):
#   TC6a: exit 0 (shim send-keys succeeds → agent-wake.sh exits 0)
#   TC6b: exit 0 (BUG — no capture-pane verify, mismatch passes silently)
# Post-impl (with Fix 3 capture-pane verify):
#   TC6a: exit 0 (capture-pane shows match → verify passes)
#   TC6b: exit 1 (capture-pane shows mismatch → verify fails explicitly)
if [ "$TC6A_EXIT" = "0" ] && [ "$TC6B_EXIT" = "1" ]; then
    check "TC6 (capture-pane match/mismatch → exit 0/1)" "PASS"
else
    check "TC6 (capture-pane match/mismatch → exit 0/1)" \
        "match-case exit=$TC6A_EXIT (expect 0), mismatch-case exit=$TC6B_EXIT (expect 1) — pre-impl mismatch passes silently"
fi

# -------------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------------
echo ""
echo "==================================="
echo "d1026-agent-wake-hotfix: $PASS pass, $FAIL fail"
echo "==================================="
[ "$FAIL" -eq 0 ] || exit 1
