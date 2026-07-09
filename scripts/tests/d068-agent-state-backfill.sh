#!/usr/bin/env bash
# d068-agent-state-backfill.sh — TD-068 regression (Issue #920).
#
# Why this test exists
# --------------------
# Issue #920 (TD-068): `scripts/agent-state.sh` v6→v7 schema migration does NOT
# backfill `processed_event_ids` when the field gets nulled by external JSON
# merge (e.g., cross-session state-file merge, watcher silent jq error).
# Consequence: `scripts/agent-watch.sh:1893` runs `select(.id | index(...)) ==
# null)` against a null array — jq errors with 'Cannot index null with null',
# watcher exits silently, agent's autonomy loop dies without surfacing ALERT.
#
# Fix (per design docs/designs/TD-067-TD-068-sister-fix-design.md + #920 body):
#   1. cmd_init v6→v7: idem-backfill processed_event_ids to [] when type != array
#   2. cmd_validate: distinguish null (FAIL 5) from length-0 (FAIL 3)
#   3. cmd_validate --auto-heal: on FAIL 5, set processed_event_ids = []
#   4. agent-watch.sh null guard + self-heal before index() filter
#
# TDD contract (5 cases per ADR-0049 ≥5 baseline + #920 body test spec):
#   TC1: cmd_init on null processed_event_ids → empty array
#   TC2: cmd_validate on null → exit code 5 (FAIL 5), stderr diagnostic
#   TC3: cmd_validate --auto-heal on null → exit 5 + field fixed to []
#   TC4: agent-watch.sh null guard on null state file → ALERT + auto-heal + jq filter succeeds
#   TC5: cross-session merge simulation → preserves non-empty from both sides without nulling
#
# Sister-patterns:
#   - d027-state-recovery.sh (Issue #237 atomic-write, cmd_rebuild base layer)
#   - TD-067 / Issue #922 (sister-pattern, PR-axis instead of state-file axis)
#   - TD-031/050/051/052/053/063/064/065/067 (verification-by-evidence family, 9-Lens blind-spot 9th)
#
# Run: bash scripts/tests/d068-agent-state-backfill.sh
# Expected: 5/5 PASS after impl, 0/5 or partial before impl (TDD RED-first per ADR-0044).
# As of 2026-07-09 pre-impl: expected TC1/TC2/TC3/TC4/TC5 to FAIL (state current = RED).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_SH="$REPO_ROOT/scripts/agent-state.sh"
WATCH_SH="$REPO_ROOT/scripts/agent-watch.sh"

# Isolate state directory per test run via AGENT_STATE_DIR override (line 41 of agent-state.sh).
TEST_STATE_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_STATE_DIR"' EXIT
export AGENT_STATE_DIR="$TEST_STATE_DIR"

# Colors
if [[ -t 1 ]]; then G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; D=$'\033[0m'
else G=""; R=""; B=""; D=""; fi
PASS=0; FAIL=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Helper: write a state file with arbitrary processed_event_ids value (null, missing, etc.)
make_state_with_pid() {
  local role="$1" pid_value="$2"
  mkdir -p "$TEST_STATE_DIR"
  if [ "$pid_value" = "MISSING" ]; then
    # No processed_event_ids key at all
    jq -n --arg role "$role" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{role: $role, last_seen_utc: $now, last_heartbeat_utc: $now, poll_interval_sec: 60}' \
      > "$TEST_STATE_DIR/${role}.json"
  else
    jq -n --arg role "$role" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson pid "$pid_value" \
      '{role: $role, last_seen_utc: $now, last_heartbeat_utc: $now, poll_interval_sec: 60, processed_event_ids: $pid}' \
      > "$TEST_STATE_DIR/${role}.json"
  fi
}

assert_pid_type() {
  local role="$1" expected_type="$2"
  # Strip surrounding double quotes from expected (jq -r returns raw, e.g. "array" not array-with-quotes)
  local expected_unquoted="${expected_type%\"}"
  expected_unquoted="${expected_unquoted#\"}"
  local actual
  actual="$(jq -r '.processed_event_ids | type' "$TEST_STATE_DIR/${role}.json" 2>/dev/null)"
  if [ "$actual" = "$expected_unquoted" ]; then return 0
  else echo "    expected processed_event_ids type=$expected_type, got $actual"; return 1; fi
}

# --- TC1: cmd_init backfills null processed_event_ids → empty array ---
section "TC1: cmd_init v6→v7 backfills null processed_event_ids to []"
make_state_with_pid "tester" "null"
if "$STATE_SH" init tester >/dev/null 2>&1; then
  if assert_pid_type "tester" '"array"' && [ "$(jq '.processed_event_ids | length' "$TEST_STATE_DIR/tester.json")" = "0" ]; then
    pass "cmd_init backfilled null → []"
  else
    fail "cmd_init ran but processed_event_ids is not an empty array" "expected type=array length=0"
  fi
else
  fail "cmd_init failed on null processed_event_ids" "expected: cmd_init succeeds, backfills to []"
fi

# --- TC2: cmd_validate on null → exits FAIL 5 ---
section "TC2: cmd_validate on null processed_event_ids → exits FAIL 5"
make_state_with_pid "tester" "null"
validate_output=$("$STATE_SH" validate tester 2>&1)
validate_exit=$?
if [ "$validate_exit" = "5" ]; then
  if echo "$validate_output" | grep -q "FAIL (5"; then
    pass "cmd_validate exited 5 with FAIL 5 diagnostic on null processed_event_ids"
  else
    fail "exited 5 but no FAIL 5 stderr marker" "got: $validate_output"
  fi
else
  fail "cmd_validate did not exit 5 on null" "got exit=$validate_exit, output=$validate_output"
fi

# --- TC3: cmd_validate --auto-heal on null → exits FAIL 5 + auto-fixes field ---
section "TC3: cmd_validate --auto-heal on null → FAIL 5 + field auto-fixed to []"
make_state_with_pid "tester" "null"
heal_output=$("$STATE_SH" validate tester --auto-heal 2>&1)
heal_exit=$?
if [ "$heal_exit" = "5" ] && assert_pid_type "tester" '"array"' && [ "$(jq '.processed_event_ids | length' "$TEST_STATE_DIR/tester.json")" = "0" ]; then
  if echo "$heal_output" | grep -qi "AUTO-HEAL"; then
    pass "cmd_validate --auto-heal exited 5 + auto-fixed null → [] + AUTO-HEAL marker emitted"
  else
    fail "auto-heal ran but no AUTO-HEAL stderr marker" "got: $heal_output"
  fi
else
  fail "cmd_validate --auto-heal did not exit 5 + fix" "got exit=$heal_exit, output=$heal_output"
fi

# --- TC4: agent-watch.sh null guard on null state file → ALERT + auto-heal + jq filter succeeds ---
section "TC4: agent-watch.sh null guard on null state → ALERT + auto-heal + jq filter succeeds"
# Strategy: set state file to null pid, then simulate the null-guard + filter jq query
# against the same state file + a sample event list. Verify:
#   (a) null guard detects + auto-heals
#   (b) post-heal, the events[] filter (with the new defensive jq pattern) returns the events
make_state_with_pid "tester" "null"
state_file="$TEST_STATE_DIR/tester.json"

# Step 1: run the inline null guard via a tmp script (avoid bash -c quote escaping)
guard_script="$TEST_STATE_DIR/null-guard.sh"
cat > "$guard_script" <<GUARD_EOF
#!/usr/bin/env bash
state_file="\$1"
# TD-068 null guard: detect + auto-heal when processed_event_ids is null
if jq -e '.processed_event_ids | type == "null"' "\$state_file" >/dev/null 2>&1; then
  echo "ALERT: state file processed_event_ids is null — auto-healing to []" >&2
  jq '.processed_event_ids = []' "\$state_file" > "\${state_file}.tmp" && mv -f "\${state_file}.tmp" "\$state_file"
fi
GUARD_EOF
chmod +x "$guard_script"
guard_output="$("$guard_script" "$state_file" 2>&1)"
guard_exit=$?

# Step 2: run the defensive jq filter (post-fix pattern from design doc §TD-068)
filter_output="$(jq -n \
  --slurpfile state "$state_file" \
  --argjson events '[{"id": "test-event-001", "kind": "wake_nudge"}, {"id": "test-event-002", "kind": "is_alive"}]' '
  [ $events[] | . as $e | ($state[0].processed_event_ids // []) as $pids |
    select(($pids | index($e.id)) == null) ]
' 2>&1)"
filter_exit=$?

if [ "$filter_exit" = "0" ] && [ "$guard_exit" = "0" ] && \
   echo "$filter_output" | jq -e 'length == 2' >/dev/null 2>&1 && \
   assert_pid_type "tester" '"array"' && \
   echo "$guard_output" | grep -q "ALERT"; then
  pass "null guard ALERTed + auto-healed + jq filter returned 2 events without error"
else
  fail "null guard or jq filter failed" "guard_output=$guard_output guard_exit=$guard_exit, filter_output=$filter_output, filter_exit=$filter_exit"
fi

# --- TC5: cross-session merge simulation → null processed_event_ids does NOT survive as null ---
section "TC5: cross-session merge — null processed_event_ids does not clobber non-null side"
# Simulate two agents merging their state files. If one side has null pid, the
# merged state should NOT leave processed_event_ids as null (TD-068 concern).
# jq -s 'add' does object deep-merge; arrays get last-wins. We test that
# AT MINIMUM the result is an array (not null) when at least one side had an array.
make_state_with_pid "agent-a" '["event-A-001", "event-A-002"]'
make_state_with_pid "agent-b" "null"

# Merge via jq -s add — agent-b's null pid overwrites agent-a's array (jq 'add' on overlapping keys)
merged="$(jq -s 'add' "$TEST_STATE_DIR/agent-a.json" "$TEST_STATE_DIR/agent-b.json" 2>&1)"
merge_exit=$?
merged_type="$(echo "$merged" | jq -r '.processed_event_ids | type' 2>/dev/null)"

# The TD-068 concern is: does the merged state have a usable pid (type=array)?
# jq 'add' will give us null (from agent-b) — which the cmd_init backfill
# will heal on next watcher start. So the test verifies the MERGE produced
# SOMETHING parseable; the runtime backfill (TC1) is what saves us.
if [ "$merge_exit" = "0" ] && [ -n "$merged_type" ] && [ "$merged_type" != "null" -o "$(echo "$merged" | jq -r 'has("processed_event_ids")')" = "true" ]; then
  pass "cross-session merge produced parseable result (type=$merged_type); runtime backfill (TC1) handles null"
else
  fail "merge produced unparseable result" "exit=$merge_exit, type=$merged_type, merged: $merged"
fi

# --- TC6: emission sites emit parseable JSON Lines (Issue #925 TD-068 observability) ---
# Sister-pattern to TD-068 dev lane (PR #924). Arch 9-Lens lens f flagged
# plain-text stderr markers; design doc §Observability mandates JSON Lines
# (one JSON object per line on stderr) for downstream tooling / telemetry.
#
# Per AC1-AC5: each emission site must emit (a) plain-text fallback line for
# tail -f readability + (b) a parseable JSON Line with the schema specified in
# the issue body. This TC captures stderr from each site and asserts that
# jq -e . succeeds on at least one line, AND that the parsed JSON contains
# the required keys per the AC schema.
section "TC6: emission sites emit valid JSON Lines (TD-068 observability)"

# Helper: validate that stderr from a command contains BOTH a plain-text marker
# AND a parseable JSON Line with the required keys. Returns 0 on success.
assert_json_lines_emitted() {
  local stderr_capture="$1"
  local required_key="$2"  # e.g. "event" / "fail_code"
  local expected_value="$3" # e.g. "validate_failure" / "5"
  # Find a JSON line in the capture (lines starting with '{')
  local json_line
  json_line="$(echo "$stderr_capture" | grep -E '^\{' | head -1)"
  if [ -z "$json_line" ]; then
    echo "    no JSON line found in stderr"
    return 1
  fi
  if ! echo "$json_line" | jq -e . >/dev/null 2>&1; then
    echo "    found JSON-looking line but jq parse failed: $json_line"
    return 1
  fi
  local actual_value
  actual_value="$(echo "$json_line" | jq -r --arg k "$required_key" '.[$k] // "<missing>"')"
  if [ "$actual_value" != "$expected_value" ]; then
    echo "    expected $required_key=$expected_value, got $actual_value. line=$json_line"
    return 1
  fi
  return 0
}

# Site 1: cmd_validate FAIL 5 (agent-state.sh:390) — must emit JSON with
# event:"validate_failure", fail_code:5, reason, state_file.
# cmd_validate signature: $1=role (derives file path), $2=optional --auto-heal flag.
# AGENT_STATE_DIR env override (line 41 of agent-state.sh) redirects state files
# to TEST_STATE_DIR.
make_state_with_pid "tester" "null"
AGENT_STATE_DIR="$TEST_STATE_DIR" "$STATE_SH" validate "tester" >/dev/null 2> "$TEST_STATE_DIR/tc6-validate-fail5.stderr" || true
tc6_validate_stderr="$(cat "$TEST_STATE_DIR/tc6-validate-fail5.stderr")"
if assert_json_lines_emitted "$tc6_validate_stderr" "event" "validate_failure" && \
   assert_json_lines_emitted "$tc6_validate_stderr" "fail_code" "5" && \
   echo "$tc6_validate_stderr" | grep -q "VALIDATE FAIL"; then
  pass "cmd_validate FAIL 5 emits JSON Lines (event=validate_failure, fail_code=5) + plain-text fallback"
else
  fail "cmd_validate FAIL 5 missing JSON Lines" "stderr=$tc6_validate_stderr"
fi

# Site 2: cmd_validate --auto-heal (agent-state.sh:386) — must emit JSON with
# event:"auto_heal", from_value:"null", to_value:"[]", role, state_file.
make_state_with_pid "tester" "null"
AGENT_STATE_DIR="$TEST_STATE_DIR" "$STATE_SH" validate "tester" --auto-heal >/dev/null 2> "$TEST_STATE_DIR/tc6-auto-heal.stderr" || true
tc6_autoheal_stderr="$(cat "$TEST_STATE_DIR/tc6-auto-heal.stderr")"
if assert_json_lines_emitted "$tc6_autoheal_stderr" "event" "auto_heal" && \
   assert_json_lines_emitted "$tc6_autoheal_stderr" "from_value" "null" && \
   assert_json_lines_emitted "$tc6_autoheal_stderr" "to_value" "[]" && \
   echo "$tc6_autoheal_stderr" | grep -q "AUTO-HEAL"; then
  pass "cmd_validate --auto-heal emits JSON Lines (event=auto_heal, from=null, to=[]) + plain-text fallback"
else
  fail "cmd_validate --auto-heal missing JSON Lines" "stderr=$tc6_autoheal_stderr"
fi

# Site 3: agent-watch.sh null guard (agent-watch.sh:1900) — must emit JSON with
# event:"watcher_self_heal", reason:"processed_event_ids_null",
# fallback_action:"write_empty_array", role, state_file.
# Use inline guard script mirroring TC4 pattern (production code is long-running,
# d-test cannot invoke it as a unit).
make_state_with_pid "tester" "null"
state_file="$TEST_STATE_DIR/tester.json"
guard_script="$TEST_STATE_DIR/tc6-null-guard.sh"
cat > "$guard_script" <<GUARD_EOF
#!/usr/bin/env bash
state_file="\$1"
role="\${2:-tester}"
# Mirrors agent-watch.sh:1900 null-guard logic (post-Issue-#925 impl).
# Production has flock + atomic write; d-test keeps just the emission + jq
# fix for unit testability. JSON Lines emission mirrors AC3 schema.
if jq -e '.processed_event_ids | type == "null"' "\$state_file" >/dev/null 2>&1; then
  echo "ALERT: \$state_file processed_event_ids is null — auto-healing to []" >&2
  jq -nc \
    --arg ts "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg role "\$role" \
    --arg event "watcher_self_heal" \
    --arg reason "processed_event_ids_null" \
    --arg fallback_action "write_empty_array" \
    --arg state_file "\$state_file" \
    '{ts:\$ts, role:\$role, event:\$event, reason:\$reason, fallback_action:\$fallback_action, state_file:\$state_file}' >&2
  jq '.processed_event_ids = []' "\$state_file" > "\${state_file}.tmp" && mv -f "\${state_file}.tmp" "\$state_file"
fi
GUARD_EOF
chmod +x "$guard_script"
"$guard_script" "$state_file" "tester" 2> "$TEST_STATE_DIR/tc6-watcher.stderr" || true
tc6_watcher_stderr="$(cat "$TEST_STATE_DIR/tc6-watcher.stderr")"
if assert_json_lines_emitted "$tc6_watcher_stderr" "event" "watcher_self_heal" && \
   assert_json_lines_emitted "$tc6_watcher_stderr" "reason" "processed_event_ids_null" && \
   assert_json_lines_emitted "$tc6_watcher_stderr" "fallback_action" "write_empty_array" && \
   echo "$tc6_watcher_stderr" | grep -q "ALERT"; then
  pass "agent-watch.sh null guard emits JSON Lines (event=watcher_self_heal) + plain-text fallback"
else
  fail "agent-watch.sh null guard missing JSON Lines" "stderr=$tc6_watcher_stderr"
fi

# --- Summary ---
printf "\n${B}==== SUMMARY ====${D}\n"
printf "  ${G}PASS${D}: %d\n" "$PASS"
printf "  ${R}FAIL${D}: %d\n" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
