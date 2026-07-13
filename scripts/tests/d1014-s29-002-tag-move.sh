#!/usr/bin/env bash
# d1014-s29-002-tag-move.sh — Sister d-test for scripts/s29-002-tag-move.sh
#                            (Cadence Rule 1 atomic, ADR-0055 §1)
#
# Doctrinal contract (5 TCs per ADR-0049):
#   TC1: argv routing — verify|commands|all produce distinct behavior
#   TC2: missing/invalid argv → exit 2 + usage to stderr
#   TC3: bash -n syntactically valid
#   TC4: SHA literals embedded match Issue #1014 plan.md spec
#   TC5: script never invokes force-push-with-lease (owner-only territory)

set -euo pipefail

SCRIPT="scripts/s29-002-tag-move.sh"
[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT not found"; exit 1; }
[ -x "$SCRIPT" ] || { echo "FAIL: $SCRIPT not executable"; exit 1; }

pass=0
fail=0

check() {
    if [ "$2" = "PASS" ]; then
        echo "  ✅ $1"
        pass=$((pass+1))
    else
        echo "  ❌ $1: $2"
        fail=$((fail+1))
    fi
}

# TC3: bash -n syntactic validity
if bash -n "$SCRIPT" 2>/dev/null; then
    check "TC3 (bash -n)" "PASS"
else
    check "TC3 (bash -n)" "bash syntax error"
fi

# Capture all three mode outputs
out_verify=$(bash "$SCRIPT" verify 2>&1 || true)
out_commands=$(bash "$SCRIPT" commands 2>&1 || true)
out_all=$(bash "$SCRIPT" all 2>&1 || true)

# Count per mode:
#   verify output should contain "Target SHA verification" but NOT "Commands for owner"
#   commands output should contain "Commands for owner" but NOT "Target SHA verification"
#   all output should contain BOTH

v_has_target=$(echo "$out_verify" | grep -c "Target SHA verification" || true)
v_has_owner=$(echo "$out_verify" | grep -c "Commands for owner" || true)
c_has_target=$(echo "$out_commands" | grep -c "Target SHA verification" || true)
c_has_owner=$(echo "$out_commands" | grep -c "Commands for owner" || true)
a_has_target=$(echo "$out_all" | grep -c "Target SHA verification" || true)
a_has_owner=$(echo "$out_all" | grep -c "Commands for owner" || true)

# TC1a: verify mode → contains target, does NOT contain owner-commands
if [ "$v_has_target" -ge 1 ] && [ "$v_has_owner" -eq 0 ]; then
    check "TC1a (verify contains target, no owner-commands)" "PASS"
else
    check "TC1a (verify contains target, no owner-commands)" "target=$v_has_target owner=$v_has_owner"
fi

# TC1b: commands mode → contains owner-commands, does NOT contain target
if [ "$c_has_owner" -ge 1 ] && [ "$c_has_target" -eq 0 ]; then
    check "TC1b (commands contains owner, no target)" "PASS"
else
    check "TC1b (commands contains owner, no target)" "owner=$c_has_owner target=$c_has_target"
fi

# TC1c: all mode → contains both
if [ "$a_has_target" -ge 1 ] && [ "$a_has_owner" -ge 1 ]; then
    check "TC1c (all = verify + commands)" "PASS"
else
    check "TC1c (all = verify + commands)" "target=$a_has_target owner=$a_has_owner"
fi

# TC2: missing argv → exit 2 + usage to stderr
err_output=$(bash "$SCRIPT" 2>&1 >/dev/null) || err_exit=$?
err_exit=${err_exit:-0}
if [ "$err_exit" -eq 2 ] && echo "$err_output" | grep -qi "Usage"; then
    check "TC2 (missing argv → exit 2 + usage)" "PASS"
else
    check "TC2 (missing argv → exit 2 + usage)" "exit=$err_exit no_usage"
fi

# TC2b: invalid argv → exit 2 + usage to stderr
err_output2=$(bash "$SCRIPT" bogus 2>&1 >/dev/null) || err_exit2=$?
err_exit2=${err_exit2:-0}
if [ "$err_exit2" -eq 2 ] && echo "$err_output2" | grep -qi "Usage"; then
    check "TC2b (invalid argv → exit 2 + usage)" "PASS"
else
    check "TC2b (invalid argv → exit 2 + usage)" "exit=$err_exit2 no_usage"
fi

# TC4: SHA literals embedded match Issue #1014 plan.md spec
if grep -qF "43592c24c838247e4ef0125de571c43dd42149ea" "$SCRIPT" && \
   grep -qF "b0d820da6b9cced6ae224e7db97d9cd31bece00b" "$SCRIPT"; then
    check "TC4 (SHA literals match plan.md)" "PASS"
else
    check "TC4 (SHA literals match plan.md)" "SHA literal missing"
fi

# TC5: script never invokes force-push-with-lease (owner-only territory)
# comment-aware: strip lines starting with # before checking
non_comment=$(grep -v '^[[:space:]]*#' "$SCRIPT" | grep -v '^[[:space:]]*$' || true)
if ! echo "$non_comment" | grep -q "force-with-lease\|force-push-with-lease"; then
    check "TC5 (no force-push flag in code)" "PASS"
else
    check "TC5 (no force-push flag in code)" "FORBIDDEN flag in code"
fi

echo ""
echo "==================================="
echo "d1014-s29-002-tag-move: $pass pass, $fail fail"
echo "==================================="
[ "$fail" -eq 0 ] || exit 1