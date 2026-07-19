# ADR-0066 — tmux-wake Fix 4b (lenient capture-pane verify + hierarchical exit code)

- **Status:** Proposed (Sprint 31 P1 cluster-squash Path A v26 step 1/3, Issue #1138)
- **Date:** 2026-07-17
- **Deciders:** @architect (doctrine + ADR author per file ownership matrix `docs/decisions/`), @tester (d-test d1138 ≥5 TCs RED-first per ADR-0044), @developer (impl in `scripts/agent-wake.sh` per file ownership matrix `scripts/`), @atilcan65 (owner squash gate per ADR-0031)
- **Parent ADR:** none (additive evolution, no amendment)
- **Closes:** Issue #1138 AC1 (ADR-0066 PR MERGED — gap-fill between ADR-0065 cpython-3-12-13 and ADR-0067 multi-reviewer-wake per @orchestrator coordination cmt on Issue #1138 cycle ~#2862)
- **Sister-patterns:**
  - [ADR-0033-dual-channel-peer-poke](./ADR-0033-auto-ping-dual-channel.md) — dual-channel doctrine (preserve contract)
  - [ADR-0024-verdict-by-discipline](./ADR-0024-stale-verdict-watchdog-schema.md) — auto-verdict-by hook precedent for §Cross-cutting concern
  - [ADR-0044-red-first-tdd](./ADR-0044-verdict-by-scope-clarification.md) — d-test RED sequencing (Fix 4b preceded by d1138 d-test, not vice-versa)
  - [ADR-0049-d-test-framework](./ADR-0049-behavioral-workflow-test-framework.md) — d-test structure (≥5 TCs, sister-pattern)
  - [ADR-0055-d-test-id-uniqueness-sub-pattern-matrix](./ADR-0055-d-test-id-uniqueness-sub-pattern-matrix.md) — Cadence Rule 1 atomic (d-test + INDEX.md row same commit)
  - [ADR-0059-cluster-squash-batch-lag-detection](./ADR-0059-cluster-squash-batch-lag-detection.md) — cluster-squash doctrine (ADR + d-test + impl 3-PR atomic squash window)
  - RETRO-027 (cadence-rule-2-retroactive-close-doctrine) — sister-pattern on cluster-squash + retroactive close on Cadence Rule 2 violation (historical sister-pattern; ADR-0061 KAPI hotfix dispatch removed 2026-07-19 per tmpl#164 Phase 2 — duplicate of tmpl ADR-0060)

## §Context

`scripts/agent-wake.sh` (the dual-channel tmux-wake component of `scripts/peer-poke.sh` per ADR-0033) currently implements **Fix 3** (Issue #1063 hotfix) for capture-pane post-send verify:

```bash
# Fix 3 (Issue #1063): capture-pane post-send verify
MSG_PREFIX="${MSG%%$'\n'*}"
if [ "${#MSG_PREFIX}" -gt 80 ]; then
  MSG_PREFIX="${MSG_PREFIX:0:80}"
fi
if timeout 1 tmux capture-pane -t "$pane_id" -p 2>/dev/null | grep -qF "$MSG_PREFIX"; then
  # verified
  exit 0
fi
# not verified — exit 1
verify_rc=0
timeout 1 tmux capture-pane -t "$pane_id" -p 2>/dev/null | grep -qF "$MSG_PREFIX" || verify_rc=$?
echo "ERROR: capture-pane verify failed for role=$ROLE pane=$pane_id rc=$verify_rc (no match for prefix: $MSG_PREFIX)" >&2
exit 1
```

**Problem statement** (owner-observed, cycle ~#2861 directive; Sprint 31 cycles ~#2855, ~#2857, ~#2858, ~#2861):

> "tmuxdan mesaj atıldığında failed zannediliyor ancak ben mesajların atıldığını ve fail olmadığını görüyorum" — messages ARE being sent (Telegram + GitHub artefact path always works), but the script reports FAIL → audit log noise.

**Live evidence table** (from Issue #1138 body):

| Cycle | Pane | Send-keys | Verify | Telegram | GitHub artefact | Net wake |
|---|---|---|---|---|---|---|
| ~#2855 | dev %3 | OK | FAIL | OK | cmt 5004803619 fired | ✅ peer woke via pr_comment_mention |
| ~#2857 | arch %2 | OK | FAIL | OK | n/a (compensation posted) | ✅ peer woke via compensating pr_comment |
| ~#2858 | tester %4 | OK | FAIL | OK | n/a (compensation posted) | ✅ peer woke via pr_comment_mention |
| ~#2858 | dev %3 | OK | FAIL | OK | n/a (compensation posted) | ✅ peer woke via pr_comment_mention |
| ~#2858 | PM %1 | OK | FAIL | OK | n/a (compensation posted) | ✅ peer woke via pr_comment_mention |
| ~#2861 | PM %1 | OK | FAIL | OK | n/a (compensation posted) | ✅ peer woke via pr_comment_mention |

**6/6 false-failures, 6/6 actual delivery success via GitHub artefact path.** Script reporting is wrong, delivery is correct.

**Root cause analysis:**
1. **Timeout too tight** (hardcoded `timeout 1`): pane render lag on busy hosts exceeds 1s → capture-pane returns empty or stale content
2. **Prefix too long** (full 80-char `MSG_PREFIX`): whitespace/render drift in pane content (e.g., terminal width wrap, ANSI escape sequences in multi-line messages) corrupts literal-match
3. **Exit code undifferentiated**: send-keys OK + verify OK = exit 0, send-keys OK + verify FAIL = exit 1, send-keys FAIL = exit 1 — caller (notify.sh) cannot distinguish "definite failure" from "uncertain delivery" because both exit 1

## §Decision

Apply **Fix 4b** to `scripts/agent-wake.sh` (additive evolution Fix 3 → Fix 4; preserves dual-channel contract per ADR-0033):

### D1. Configurable verify timeout (sister-pattern d068b `WAKE_KEYS_GAP_SEC`)

```bash
# Before
timeout 1 tmux capture-pane ...

# After
timeout "${WAKE_VERIFY_TIMEOUT_SEC:-3}" tmux capture-pane ...
```

- Default 3s (covers host render lag)
- `WAKE_VERIFY_TIMEOUT_SEC` env override (sister-pattern: `WAKE_KEYS_GAP_SEC` from d068b sleep discipline, Issue #935)

### D2. Lenient prefix match (whitespace/render-drift tolerant)

```bash
# Before
MSG_PREFIX="${MSG%%$'\n'*}"
if [ "${#MSG_PREFIX}" -gt 80 ]; then
  MSG_PREFIX="${MSG_PREFIX:0:80}"
fi
if timeout 1 tmux capture-pane ... | grep -qF "$MSG_PREFIX"; then ...

# After
# Fixed 16-char sentinel — robust against whitespace/render drift, terminal width wrap, ANSI escapes
VERIFY_SENTINEL="🔔 INBOX (dual-c"
timeout "${WAKE_VERIFY_TIMEOUT_SEC:-3}" tmux capture-pane ... | grep -qF "$VERIFY_SENTINEL" && ...
```

- Hardcoded 16-char sentinel `"🔔 INBOX (dual-c"` — covers `notify.sh -w -r <role>` prefix that **every** peer-poke / agent-watch wake uses
- Drops dynamic `MSG_PREFIX` first-line extraction (was the source of multi-line pollution per [[peer-poke-multiline-tmux-fail]] memory)
- Decoupled from message content → render-drift immune

### D3. Hierarchical exit code (3-tier rc semantics)

| Scenario | Exit code | Stderr | Audit log signature |
|---|---|---|---|
| send-keys OK + verify OK | **0** | — | `Wake verified: role=X pane=Y` |
| send-keys OK + verify FAIL | **0** | WARN | `WARN: Wake injected but verify uncertain for role=X pane=Y (pane may have scrolled past MSG_PREFIX; text sent via send-keys)` |
| send-keys FAIL | **1** | ERROR | `ERROR: send-keys returned rc=N for pane=Y role=X` |

Caller (notify.sh) rc semantics preserved: **exit 0 = delivered OR delivery-uncertain-but-sent, exit 1 = definite failure**.

**Rationale**: GitHub artefact path (`pr_comment_mention`, Issue #1138 body live evidence: 6/6 cycles) is the primary wake channel per ADR-0033. tmux pane wake is the **secondary** deliverability channel. If send-keys succeeded but verify can't confirm pane state, the text was injected — the dual-channel contract is intact even if capture-pane can't see it. False-positive audit logs (6/6 cycles) are worse than accurate uncertainty.

### D4. Log discrimination (WARN vs ERROR separation)

Owner greppable inspection: `grep "WARN: Wake injected but verify uncertain"` vs `grep "ERROR: send-keys returned"`. This enables:
- Audit of how often verify-uncertain events occur (was 100% in Sprint 31; post-Fix 4b should drop to ~0% with 3s timeout)
- Hard failure detection still works (send-keys FAIL → exit 1)

## §Number conflict note

Issue #1138 body originally specified **"ADR-0062"** in AC1 + cluster-squash Path A v26 inventory, but ADR-0062 is **TAKEN** by `docs/decisions/ADR-0062-amendment-layer-5-label-change-verdict-gate.md` (Sprint 22 P2, Layer 5 Label-Change Event Verdict-Gate Extension, unrelated topic).

**Renumber resolution (cycle ~#2862)** — @orchestrator coordination call on Issue #1138 cmt 5005153756 selected **ADR-0066 (gap-fill)** over ADR-0072 (next free integer). Rationale:
- ADR-0066 is a **real gap in sequence** (verified `ls docs/decisions/` — ADR-0065 cpython-3-12-13 → ADR-0067 multi-reviewer-wake with 0066 missing)
- Gap-fill maintains numerical density (no orphaned gaps in `INDEX.md` reading order)
- Lower integer = earlier INDEX.md reading order, which benefits newcomers scanning the catalog top-down

**Architect honour (cycle ~#2867)**: ADR file + INDEX.md row + branch name + PR title all renumbered to ADR-0066. Branch rename: `arch/adr-0072-tmux-wake-fix-4b` → `arch/adr-0066-tmux-wake-fix-4b`. Single amend commit (no doctrinal content change — only the integer identifier per Issue #1138 body coordination).

## §Why NOT Fix 4a (paste-buffer for multi-line)

Owner pushback (cycle ~#2861 directive): "ben mesajların gidişinde hic sorun görmedim" — multi-line send-keys DOES submit each line as a separate bash command (pane pollution), but the actual wake path (GitHub artefact `pr_comment_mention` per ADR-0002) is unaffected. So Fix 4a is preventive for a problem that has not been observed in production.

**Out of scope for this ADR.** Defer to future Issue if/when owner observes a real multi-line pathology. [[peer-poke-multiline-tmux-fail]] memory is the doctrinal record of the deferred-work item.

## §Alternatives considered

- **(A) Drop verify entirely (always exit 0 after send-keys OK)**: Rejected — removes ALL audit signal, including legitimate send-keys failures. D3's WARN tier is the principled middle ground.
- **(B) Tighten verify (extend MSG_PREFIX to full message body, multiple capture-pane attempts)**: Rejected — addresses wrong problem (verify IS working, just for stale content). Doesn't address the real issue: send-keys OK + verify FAIL ≠ definite failure.
- **(C) Switch from grep -F to regex with whitespace tolerance**: Rejected — adds complexity without addressing root cause (sentinel-based match D2 is simpler and more robust).

## §Consequences

### Positive
- Audit log accuracy improves dramatically: WARN/ERROR separation lets owner greppable inspect which wakes were uncertain vs failed
- Caller (notify.sh) rc semantics preserved (backward-compatible)
- Dual-channel contract per ADR-0033 preserved (GitHub artefact path is primary; tmux pane verify is secondary)
- Configurable timeout via env override (sister-pattern with `WAKE_KEYS_GAP_SEC` d068b) allows per-host tuning
- Sentinel-based prefix (D2) is render-drift immune; addresses [[peer-poke-multiline-tmux-fail]] symptom as a side effect (no longer derives prefix from MSG content)

### Negative
- EXIT 0 on verify-FAIL means caller scripts that *only* check `$?` will miss the WARN signal — must be paired with stderr capture (`2>&1` + grep WARN) for accurate audit
- Default 3s timeout is longer than current 1s — minor latency increase on failure-path detection (acceptable trade for accuracy)

### Neutral
- No change to MSG content (still passes the full multi-line message to send-keys; Fix 4a would address this but is out of scope)
- No change to `peer-poke.sh` wrapper or `notify.sh` Telegram mirror
- Sister-pattern with d068b `WAKE_KEYS_GAP_SEC` env override — same naming convention, different concern (sleep gap vs verify timeout)

## §Implementation contract

- **Location:** `scripts/agent-wake.sh` (lines 97-118, Fix 3 verify block)
- **Test:** d-test `scripts/tests/d1138-agent-wake-fix-4b-lenient-verify.sh` (≥5 TCs per ADR-0049 + ADR-0044 RED-first)
  - TC1: WAKE_VERIFY_TIMEOUT_SEC override applied (env var honored)
  - TC2: VERIFY_SENTINEL=16 chars `"🔔 INBOX (dual-c"` (literal match, no MSG derivation)
  - TC3: send-keys OK + verify OK → exit 0 (preserved)
  - TC4: send-keys OK + verify FAIL → exit 0 + stderr WARN (hierarchical)
  - TC5: send-keys FAIL → exit 1 + stderr ERROR (preserved)
  - TC6: bash -n syntactic validity (shellcheck baseline per ADR-0049)
- **Impl PR contract:** `Closes #1138` strict anchor (ADR-0057), `agent:developer` + `cc:tester` + `needs-tester-signoff` (ADR-0012 birth contract)
- **Cadence Rule 1 atomic:** this ADR + `scripts/tests/INDEX.md` row registered same commit (ADR-0055 §1)
- **Cluster-squash inventory update:** `docs/sprints/current/plan.md` Path A v26 row addition (architect-owned per file ownership matrix `docs/sprints/current/`)

## §Cross-cutting concerns

- **Auto-Verdict-By hook (ADR-0024 amendment §Path 2)**: Fix 4b does NOT modify peer-poke.sh's `_pair_verdict_by` function or the Layer 5 label-check.yml auto-add path. Unaffected.
- **Sister cluster-squash Path A v25 inventory**: PR #1137 (RETRO-027 closeout, Closes #1130) is in `status:ready` owner-squash-pending. Fix 4b cluster (Path A v26) is the next wave, dependent on owner-squash-cue per ADR-0031.
- **Template forward-port**: Sister-pattern discipline requires `atilproject/dev-studio-template` `scripts/agent-wake.sh` to receive the same fix. Per Cadence Rule 2 (RETRO-027), forward-port happens AFTER AtilCalculator cluster-squash completes (separate cycle, separate PR on template repo).

## §Open questions

- **Q1** ~~Does @orchestrator select ADR-0072 (next free) or ADR-0066 (gap-fill) for the renumbering? — peer-poke sent, awaiting ack~~ **RESOLVED cycle ~#2867** — @orchestrator selected ADR-0066 (gap-fill, cycle ~#2862 cmt 5005153756); this ADR file + INDEX.md row + branch name + PR title all renumbered to ADR-0066 in single amend commit.
- **Q2**: Does @tester prefer 5-TC baseline (TC1-TC5 above) or expanded 9-TC coverage (TC1-TC9 sister-pattern with d081/d296 d-test framework)? — defer to tester lane
- **Q3**: Should the WARN log line include `MSG_PREFIX` content for diagnostic purposes, or only role/pane? — defer to tester/owner review

## §References

- Issue #1138 (this ADR author directive + cluster-squash Path A v26 inventory)
- Issue #1063 Fix 3 (current capture-pane verify — additive evolution 3 → 4)
- Issue #935 / d068b (sleep discipline + env-override naming pattern)
- Issue #221 / ADR-0033 (dual-channel doctrine)
- Issue #1130 RETRO-027 (sister cluster-squash pattern, Cadence Rule 2 retroactive-close)
- Cycle ~#2855/2857/2858/2861 (live evidence, 6/6 false-failures)
- [[peer-poke-multiline-tmux-fail]] memory (Fix 4a deferral justification)
- [[gh-label-create-100char-desc-limit-cycle-2414]] memory (verdict-by label creation discipline)
