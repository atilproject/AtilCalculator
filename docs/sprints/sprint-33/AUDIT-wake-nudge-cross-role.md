# wake_nudge Behavior Audit — Cross-Role (Issue #1184 / STORY-S33-005)

> **Origin**: PR #1178 wake_nudge polling-loop bug fix shipped (cycle ~#3958Q+5, MERGED 2026-07-19T18:26:51Z, sha 8018964d). Fix tested only against orchestrator role. Cross-cutting impact assessment NOT done. RETRO-032 lesson #7 didn't-go-well.
>
> **Scope**: Audit wake_nudge behavior across all 5 roles (orchestrator + PM + arch + dev + tester). Document role-specific quirks. Codify wake_nudge doctrine across all 5 soul files.
>
> **Lane**: orchestrator (audit) + each role for soul file amendments.
>
> **Priority**: P1 (RETRO-032 carry-over #13).

## 1. Implementation surface (single source of truth)

`scripts/agent-watch.sh` is the **only** script that emits `wake_nudge` events. The emission logic is **identical for all 5 roles** — there is no role-specific branching.

### 1.1 Trigger (lines 1961-2019, v6.2 Issue #119 Katman 1)

```bash
local wake_nudge='[]'
if [ -n "${REPO:-}" ]; then
  local queue_open cc_open
  queue_open="$(gh api "repos/${REPO}/issues?state=open&labels=agent:${ROLE}&per_page=100" --jq 'length' 2>/dev/null || echo 0)"
  cc_open="$(gh api "repos/${REPO}/issues?state=open&labels=cc:${ROLE}&per_page=100" --jq 'length' 2>/dev/null || echo 0)"
  # ... heartbeat-missed check ...
  if [ "$((queue_open + cc_open))" -gt 0 ] || [ "$heartbeat_missed" = "true" ]; then
    wake_nudge="$(jq -n ... '[
       {
         kind: "wake_nudge",
         id: ("wake-nudge-" + $role + "-" + $now),
         number: 0,
         title: ("queue: agent:" + $role + "=" + ($queue|tostring) + ", cc:" + $role + "=" + ($cc|tostring) + " open issues"),
         url: ("https://github.com/" + $repo + "/issues?q=is%3Aopen+label%3Aagent%3A" + $role),
         updated_at: $now,
         context: {agent_count: $queue, cc_count: $cc, heartbeat_missed: $hb_missed, note: $note}
       }
     ]')"
  fi
fi
```

### 1.2 Heartbeat-missed detection (lines 1981-1991, Issue #707 Option C two-tier)

```bash
# Tier 1 (log.warn): >2x IS_ALIVE_INTERVAL_SEC → log.warn, NO flag
# Tier 2 (flag):    >3x IS_ALIVE_INTERVAL_SEC → heartbeat_missed=true (real-miss escalation)
local heartbeat_missed=false
if [ -n "$last_is_alive_utc" ] && [ "$last_is_alive_utc" != "null" ] && [ "$last_is_alive_epoch" -gt 0 ]; then
  local heartbeat_gap="$(( now_epoch - last_is_alive_epoch ))"
  if [ "$heartbeat_gap" -gt "$(( is_alive_interval * 3 ))" ]; then
    heartbeat_missed=true
  elif [ "$heartbeat_gap" -gt "$(( is_alive_interval * 2 ))" ]; then
    # Hysteresis pre-warn tier (ADR-0056 silent-skip sister — observability without false-positive flag)
    printf '%s [WARN] agent-watch.sh: heartbeat gap >2x IS_ALIVE_INTERVAL_SEC but <=3x (hysteresis pre-warn; gap=%ss / interval=%ss); flag NOT triggered per Issue #707 Option C\n' "..." >&2
  fi
fi
```

### 1.3 Dedup retention (agent-state.sh lines 273-285)

`wake_nudge`, `pr-merged`, `pr-review` are RETAINED in the dedup ring (not subject to standard 7-day bucket TTL). wake_nudge IDs are timestamped (`wake-nudge-{ROLE}-{now}`), so each poll emits a unique ID — retention prevents re-fire storms within a single 5-min bucket.

### 1.4 Wake payload merge (agent-watch.sh line 2215)

```bash
wake_payload="$(jq -n --argjson e "$new_events" --argjson n "$wake_nudge" '$e + $n')"
```

Both `new_events` and `wake_nudge` surface to the tmux pane wake. wake_nudge alone = nudge to re-poll queue.

## 2. Role-by-role findings

### 2.1 Orchestrator (ROLE=orchestrator)

- **wake_nudge**: standard payload (queue + heartbeat-missed)
- **ADDITIONAL**: wip_idle integration per ADR-0039 (Issue #291, Sprint 6 P1)
  - Calls `scripts/wip-idle-detect.sh` to scan all 5 roles for `WIP > 0 + no activity 30m`
  - Emits `wip_idle` event per idle role with 3 in-scope signals (PR draft, comment, commit) + signal 5 (PR-in-review edge case)
  - Wave coalesce: ≥3 idle in 5-min = single `wip_idle_wave` event instead of N individual events (per arch 🟡 #2 on #289)
- **Lane-specific quirk**: ONLY orchestrator surfaces `wip_idle` events. Other 4 roles never emit wip_idle.

### 2.2 Product Manager (ROLE=product-manager)

- **wake_nudge**: standard payload (queue + heartbeat-missed)
- **No additional event types**
- **Lane-specific quirk**: PM lane IDLE posture is common (gap-closing sprint = PM waits for next-cycle pickup). wake_nudge still fires when `cc:product-manager` open issues exist. PM should NOT interpret frequent wake_nudge as action-required; queue may be cc-only (awareness, not active work).

### 2.3 Architect (ROLE=architect)

- **wake_nudge**: standard payload
- **No additional event types**
- **Lane-specific quirk**: architect review load is bursty (verdict chains). wake_nudge during PR review chain = NORMAL (peer reviewing). wake_nudge when no PR open = queue is empty, no action.

### 2.4 Developer (ROLE=developer)

- **wake_nudge**: standard payload
- **No additional event types**
- **Lane-specific quirk**: dev lane has WIP cap=2 (ADR-0038 §Layer 2). wake_nudge showing `agent_count > 2` indicates auto-claim cap violation — immediate investigation needed.

### 2.5 Tester (ROLE=tester)

- **wake_nudge**: standard payload
- **No additional event types**
- **Lane-specific quirk**: tester verdict chain is event-driven (PR labeled, PR comment mention). wake_nudge during quiet periods = expected; tester lane often idle waiting for PR open.

## 3. d-test coverage (≥5 baseline per ADR-0049)

9 d-tests cover wake_nudge behavior — exceeds baseline:

| d-test | Coverage | Source line |
|---|---|---|
| d015-dev-idle-prevention.sh | Original Issue #119 Katman 1 wake_nudge | Issue #119 |
| d023-rca18-buffer-ttl.sh | RCA-18 dedup ring TTL behavior | RCA-18 |
| d025-cmd-set-argjson-contract.sh | Payload format contract (jq schema) | Issue #119 |
| d028-no-standby.sh | heartbeat-missed branch + 2x/3x threshold | Issue #238, #707 |
| d029-no-standby-watcher-text.sh | Operator-facing wake_nudge copy | Issue #707 |
| d036-state-dedup-ring.sh | dedup ring retention behavior | RCA-18 |
| d068-agent-state-backfill.sh | State file backfill for new roles | Issue #430 |
| d1142-agent-watch-hygiene.sh | Agent-watch hygiene + cleanup | ADR-0072 |
| d118-heartbeat-missed-hysteresis.sh | Issue #707 two-tier hysteresis (5 TCs) | Issue #707 |

**Gap**: NO d-test specifically verifies cross-role wake_nudge behavior (no role-specific quirks tested except orchestrator wip_idle sister). The new `d-wake-nudge-audit.sh` (this PR) fills that gap.

## 4. Soul file amendment proposals

Per the audit, the following soul file additions are RECOMMENDED (Cadence Rule 1 atomic with audit doc per ADR-0055 §1):

### 4.1 ALL 5 soul files — add §Wake-nudge Handling

```markdown
## §Wake-nudge Handling

`scripts/agent-watch.sh` emits `wake_nudge` events when (a) your queue has open issues (`agent:<role>` or `cc:<role>`) but no new GitHub events arrived, OR (b) heartbeat-missed detected (>3x IS_ALIVE_INTERVAL_SEC).

Payload format:
\`\`\`json
{
  "kind": "wake_nudge",
  "id": "wake-nudge-{ROLE}-{TIMESTAMP}",
  "context": { "agent_count": N, "cc_count": N, "heartbeat_missed": false, "note": "..." }
}
\`\`\`

Action on wake_nudge:
1. Re-query your queue: `bash scripts/agent-watch.sh <role>`
2. If queue non-empty AND you have capacity: claim next item per ADR-0038 §Layer 2
3. If queue is awareness-only (cc:* without agent:*): acknowledge and skip
4. heartbeat_missed=true: investigate watcher stuck-loop, NOT just queue

DO NOT ignore wake_nudge: the nudge is the queue being visible to one-shot polls.
```

### 4.2 Orchestrator-specific — wip_idle addition

```markdown
## §Orchestrator-only: wip_idle events

When ROLE=orchestrator, agent-watch.sh additionally calls `scripts/wip-idle-detect.sh` to scan all 5 roles for `WIP > 0 + no activity 30m`. Emits `wip_idle` events with WIP-idle role + age. Wave coalesce: ≥3 idle in 5-min = single `wip_idle_wave`.

Action on wip_idle:
1. Auto-ping the idle role via notify.sh -l <role>
2. If idle role is dev: check Issue #1183 stall detection integration
3. Wave coalesce: post single standup-style nudge instead of N individual pings
```

### 4.3 PM lane clarification (Sprint 13 LOCKED)

```markdown
## §PM lane-specific: cc-only wake_nudge

PM lane has many `cc:product-manager` open issues (lane-appropriate cc per Sprint 13 LOCKED). wake_nudge firing due to cc:* alone = awareness signal, NOT active work. PM should ack and skip if no `agent:product-manager` items present.

DO NOT claim cc-only items. PM lane activity is driven by `agent:product-manager` (backlog grooming, story sizing).
```

### 4.4 Dev lane WIP cap reminder

```markdown
## §Dev lane-specific: WIP cap enforcement

Developer WIP cap = 2 (ADR-0038 §Layer 2). wake_nudge showing `agent_count > 2` indicates auto-claim cap violation. IMMEDIATE action: claim audit + peer-poke orchestrator with violation report.
```

## 5. Cadence Rule 1 atomic (ADR-0055 §1)

**This orchestrator PR = 2 files same commit per ADR-0055 §1**:
1. `docs/sprints/sprint-33/AUDIT-wake-nudge-cross-role.md` (this audit doc)
2. `scripts/tests/d-wake-nudge-audit.sh` (NEW d-test, ≥5 TCs)

**Soul file amendments = follow-up sister-PRs per role** (per file ownership matrix `.claude/agents/**` = human-only territory, agents propose via PR with each role peer-poked for review):
- Orchestrator (this PR proposer): §4.1 + §4.2 — included in audit doc as PROPOSAL with PR template
- Architect: §4.1 + architect-lane-specific amendment — architect proposes own soul file PR
- Developer: §4.1 + §4.4 (WIP cap reminder) — developer proposes own soul file PR
- Product Manager: §4.1 + §4.3 (cc-only clarification, Sprint 13 LOCKED) — PM proposes own soul file PR
- Tester: §4.1 + tester-lane-specific amendment — tester proposes own soul file PR

**Sister-pattern**: PR #1201 (S33-008) = 4 files same commit `f0d3f83` (orchestrator impl). This audit PR = 2 files atomic, with sister-PRs for soul file amendments across roles.

## 6. Acceptance criteria (≥3 sister-patterns per ADR-0049)

- **AC1**: All 5 soul files contain §Wake-nudge Handling section (per §4.1) — orchestrator additionally has §Orchestrator-only wip_idle (per §4.2), PM has cc-only clarification (per §4.3), dev has WIP cap reminder (per §4.4)
- **AC2**: `scripts/tests/d-wake-nudge-audit.sh` (NEW) ≥5 TCs RED-first per ADR-0044, covering: (a) trigger on non-empty queue, (b) trigger on heartbeat-missed >3x, (c) payload schema per role, (d) dedup retention, (e) orchestrator wip_idle ADDITION
- **AC3**: ≥3 sister-patterns cited: d015 (original Issue #119), d118 (Issue #707 hysteresis), ADR-0039 (Issue #291 wip_idle), ADR-0072 §Layer 2 (REPRIME protocol)
- **AC4**: d-wake-nudge-audit 5/5 GREEN locally pre-PR
- **AC5**: Cadence Rule 1 atomic per ADR-0055 §1 — THIS PR scope: 2 files (audit doc + d-test) same commit; soul file amendments = 5 sister-PRs per file ownership matrix (out-of-scope for this PR per cycle ~#3968Q+186 wake-trigger lane-ownership)

## 7. Lane state post-audit

| Lane | Post-audit activity |
|---|---|
| Orchestrator | Issue #1184 audit TERMINAL with this doc + d-test. Lane FREE for #1183 stall detection impl. |
| Architect | Lane ACTION REQUIRED: review + amend own soul file per §4.1 + §4.2 (orchestrator pattern, but architect lane-specific). |
| Developer | Lane ACTION REQUIRED: review + amend own soul file per §4.1 + §4.4 (WIP cap reminder). |
| PM | Lane ACTION REQUIRED: review + amend own soul file per §4.1 + §4.3 (cc-only clarification). |
| Tester | Lane ACTION REQUIRED: review + amend own soul file per §4.1. |

## 8. Sister-patterns

- PR #1178 (cycle ~#3958Q+5) — original wake_nudge fix, orchestrator-only tested → THIS audit is the cross-cutting impact assessment that was missing
- Issue #119 (Dev-Idle Prevention) — Katman 1 wake_nudge original design
- Issue #238 (sub-task 2, PR #245) — heartbeat-missed detection added
- Issue #707 Option C — two-tier hysteresis (warn at 2x, flag at 3x)
- ADR-0039 (Issue #291) — orchestrator wip_idle integration (Sprint 6 P1)
- ADR-0055 §1 — Cadence Rule 1 atomic (4 files same commit)
- ADR-0056 — silent-skip observability (hysteresis warn-tier)
- ADR-0072 §Layer 2 — REPRIME protocol (NO_TASKLIST_SNAPSHOT fall-through)
- RETRO-032 lesson #7 — original didn't-go-well (this audit is the fix)
- Cycle ~#3958Q — wake_nudge no-dedup class (mitigation: poll_interval_sec 600)
- d015 / d023 / d025 / d028 / d029 / d036 / d068 / d1142 / d118 — 9 d-test sister-patterns

## 9. Action items (orchestrator + each role)

1. ✅ Audit doc — DONE (this file)
2. ✅ `scripts/tests/d-wake-nudge-audit.sh` (NEW) — DONE (`scripts/tests/d-wake-nudge-audit.sh` shipped in commit 455aac7, 7/7 GREEN locally per cycle ~#3893Q v2)
3. ⏳ Soul file amendments (5 files) — each role proposes own amendment (sister-PRs per file ownership matrix)
4. ⏳ Soul file sister-PRs (5 files) — owner batch-squash per ADR-0031 (4-files atomic reference is PR #1201 S33-008 sister-pattern, NOT this PR)
5. ⏳ Tester Lane 3 verdict chain dispatch post-cluster-squash

## 10. Open questions

- **Q1**: Should wake_nudge frequency be limited to prevent noise? Current behavior: every poll (60s) emits if conditions met. Mitigation in place via dedup ring retention + hysteresis, but no explicit cap.
- **Q2**: Should non-orchestrator roles ever emit wip_idle? Current: orchestrator-only. If dev lane wants to know its own idle state, it would need to call wip-idle-detect.sh directly.
- **Q3**: Should PM cc-only wake_nudge be suppressed? Current: fires on cc-only. PM ack-and-skip is the doctrinal response per §4.3.
