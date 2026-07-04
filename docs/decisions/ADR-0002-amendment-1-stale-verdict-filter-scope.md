# ADR-0002 amendment 1 — stale_verdict filter scope (verdict-authority lanes only)

> **Status**: Proposed
> **Date**: 2026-07-04
> **Deciders**: @architect (proposing) + @developer (RCA verification) + @tester (sister-test) + @atilcan65 (owner approve)
> **Amends**: [ADR-0002](./ADR-0002-autonomy-loop.md) §Event Model + scripts/agent-watch.sh line 1085-1142
> **Issue**: [#798](https://github.com/atilproject/AtilCalculator/issues/798) (dev escalation cycle ~#3671, cmt 4880713395)

---

## Context

[ADR-0002](./ADR-0002-autonomy-loop.md) §Event Model established the `stale_verdict` event kind, implemented in `scripts/agent-watch.sh` line 1085-1142 (`query_stale_verdict`). The current filter scope is `(cc:<role> AND verdict-by:<ts> past deadline)` — implemented at the bash level as `gh pr list --label "cc:${ROLE}"` followed by jq selection on `verdict-by:*` presence.

The filter was authored under the assumption that `cc:<role>` indicates verdict expectation for that role. **This assumption is wrong under current doctrine:**

| Label | Per ADR | Semantics |
|---|---|---|
| `cc:<role>` | [ADR-0015](./ADR-0015-atomic-agent-handoff.md) | Queue-passing / informational lane / **no verdict authority** |
| `agent:<role>` | [ADR-0012](./ADR-0012-required-label-set.md) | Work ownership / verdict authority per [ADR-0024](./ADR-0024-stale-verdict-watchdog-schema.md) |
| `cc:human` | [ADR-0031](./ADR-0031-owner-merge-gate.md) | Owner merge gate / special verdict authority |
| `verdict-by:<ts>` | [ADR-0024](./ADR-0024-stale-verdict-watchdog-schema.md) | Verdict stamp (set by whoever posts review) |

**Live instances observed** (cycle ~#3671):
- PR #796 (tester RED-state capture, head 3c4ee14, `verdict-by:2026-07-04T04:31:52Z` arch stamp) — `cc:developer` informational lane + arch verdict stamp → stale_verdict watcher fires for `cc:developer` requesting verdict from dev
- PR #797 (tester test-plans, head 5c432c3, `verdict-by:2026-07-04T04:47:58Z` arch stamp) — same pattern

Both: tester-owned DRAFT capture docs PRs. Dev has no verdict authority (per file ownership matrix + ADR-0015 lane discipline). Watcher incorrectly assumes `cc:<role>` = verdict authority.

## Decision

**The `stale_verdict` filter MUST scope to verdict-authority lanes ONLY:**

```
stale_verdict fires for ROLE iff:
  (agent:ROLE AND verdict-by:<ts> past deadline)
  OR
  (cc:human AND verdict-by:<ts> past deadline)
```

Where ROLE = the agent's role (e.g., `architect`, `developer`, `tester`).

**Verdict authority doctrine** (codified per ADR-0024 + ADR-0031):
- `agent:<role>` lanes carry verdict authority (PR owner is the verdict source)
- `cc:human` lane carries owner-merge verdict authority (ADR-0031 owner merge gate)
- `cc:<peer>` lanes carry NO verdict authority — they are informational only (ADR-0015 queue-passing)

**Concrete filter change** (in `scripts/agent-watch.sh` line 1090):

```bash
# BEFORE (current — INCORRECT):
gh pr list --label "cc:${ROLE}" --state open --limit 50 ...

# AFTER (corrected — verdict-authority lanes only):
# Filter logic in jq: agent:<role> OR cc:human + verdict-by:* past deadline.
# gh pr list can stay broad; jq applies the verdict-authority gate.
gh pr list \
  --label "agent:${ROLE}" \
  --label "cc:human" \
  --state open \
  --limit 50 \
  --json number,title,url,updatedAt,headRefOid,labels,files,statusCheckRollup
```

(Note: `gh pr list --label X --label Y` is AND semantics. For OR semantics, omit `--label` filter and let jq apply the gate — see POC in design doc.)

## Rationale

1. **Doctrine alignment**: ADR-0015 (`cc:<role>` = informational) + ADR-0024 (`verdict-by:<ts>` = verdict stamp) + ADR-0031 (`cc:human` = owner merge gate) are authoritative. The current filter contradicts them.

2. **Live evidence**: PR #796 + #797 false-positive fires demonstrate the doctrine drift in production. Without fix, every tester-owned docs PR with arch verdict-by will fire a false-positive stale_verdict for dev (and vice-versa for arch on tester-owned docs PRs with dev peer-acks).

3. **Reversibility > correctness**: The fix is a 1-line filter scope change + sister-test. High reversibility if doctrine needs further amendment.

4. **YAGNI**: Don't touch sister-watchers (`stale_cc`, `missing_expectation`) — separate concerns, separate fixes (TD-006, TD-027 sister families).

5. **Architect lane stewardship**: Per ADR-0002, architect stewards the autonomy-loop script. This is in-lane.

## Alternatives considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **A. Surgical filter fix only** (this amendment) | Minimal blast radius; preserves event ID format; sister-test guards regression | Doesn't address sister-watchers (`missing_expectation` same pattern) | **CHOSEN** — surgical, doctrine-aligned |
| B. Refactor `agent-watch.sh` watchers family | Cleaner architecture; addresses sister-watchers | Higher blast radius; out of scope for #798 P2; architect proposes separate ADR | Deferred (separate ADR if needed) |
| C. Disable `stale_verdict` entirely | Eliminates false-positives | Loses genuine stale verdict detection (regression on owner merge gate wake) | Rejected — overcorrection |
| D. Filter to `agent:<role>` only (drop `cc:human`) | Simpler logic | Breaks owner-merge-gate stale check (dev lane for owner-pr) | Rejected — owner squash gate still needs stale check per ADR-0031 |
| E. Add `cc:<role>` opt-in via new label (e.g., `verdict-expected:architect`) | Explicit verdict expectation | Verbose; contradicts ADR-0015 lane discipline | Rejected — over-engineering |

## Consequences

**Positive**:
- Eliminates false-positive stale_verdict fires on `cc:<peer>` informational lanes
- Aligns filter with ADR-0015 + ADR-0024 + ADR-0031 doctrine
- Preserves event ID format + dedup ring compatibility (no agent-state.sh schema change)
- Sister-test guards regression
- Owner merge gate (`cc:human`) stale check preserved

**Negative**:
- Strict narrowing: PRs that previously fired stale_verdict for `cc:<peer>` will now NOT fire (intended, but may surface as "missing wake" if any consumer relied on the old behavior — none identified in current code)
- Documentation drift: any docs/PR comments referencing the old `(cc:<role> AND verdict-by:*)` semantics need update (sister PR or follow-up)
- `missing_expectation` watcher (line 1144+) has same deviation pattern — deferred, separate fix path

**Follow-up tickets** (filed in #798 acceptance criteria):
- Apply same correction to `query_missing_expectation` line 1144+ (same lane-discriminator logic)
- Add label-check workflow CI lint advisory for `cc:<peer> AND verdict-by:*` forbidden combo
- Update `docs/designs/` cross-references to stale_verdict semantics (if any)

## Acceptance criteria

- [ ] AC-1: `scripts/agent-watch.sh` `query_stale_verdict` filter scoped to `(agent:<role> AND verdict-by:<ts>) OR (cc:human AND verdict-by:<ts>)`
- [ ] AC-2: Existing event ID format preserved (`stale-verdict-<n>-<sha7>-b<bucket>`)
- [ ] AC-3: Sister-test `scripts/tests/d320-stale-verdict-filter.sh` ≥3 TCs per [ADR-0049](./ADR-0049-d-test-framework.md):
  - TC1: PR with `cc:<peer>` + `verdict-by:*` past deadline does NOT fire stale_verdict for that peer
  - TC2: PR with `agent:<role>` + `verdict-by:*` past deadline DOES fire stale_verdict for that role
  - TC3: PR with `cc:human` + `verdict-by:*` past deadline DOES fire stale_verdict (owner merge gate)
- [ ] AC-4: `docs/decisions/INDEX.md` entry added for this amendment
- [ ] AC-5: PR opened by architect; cc:developer + cc:tester for sister-lane ack; owner squash gate per [ADR-0031](./ADR-0031-owner-merge-gate.md)
- [ ] AC-6: All CI checks GREEN (label-check, lint, d-test framework per [ADR-0049](./ADR-0049-d-test-framework.md))
- [ ] AC-7: No false-positive stale_verdict fires for 24h post-fix on synthetic PR (regression validation)

## Sister-patterns

- [ADR-0015](./ADR-0015-atomic-agent-handoff.md) — `cc:<role>` informational lane doctrine
- [ADR-0024](./ADR-0024-stale-verdict-watchdog-schema.md) — `verdict-by:<ts>` verdict stamp semantics
- [ADR-0021](./ADR-0021-docs-pr-convention.md) — docs PR convention (same lane-discipline family)
- [ADR-0031](./ADR-0031-owner-merge-gate.md) — owner merge gate (`cc:human` verdict authority)
- [ADR-0045](./ADR-0045-9-lens-pre-publish.md) — 9-Lens framework applied to design doc
- [ADR-0049](./ADR-0049-d-test-framework.md) — d-test ≥3 TCs sister-pattern
- [TD-006](../tech-debt.md) — multi-role bulk label hygiene (same lane-discipline family)
- [TD-027](../tech-debt.md) — wake_nudge event IDs TTL-filter (sister concern)
- Issue #430 — §Pre-verdict cross-check (adjacent doctrine)
- Issue #682 — §Post-verdict cross-watchdog (adjacent doctrine)
- Issue #798 — this amendment's filing issue
- PR #458 squash fbf92be — d051 amendment family (parallel lane-discipline concern)

---

*Proposed 2026-07-04T04:55Z by @architect (cycle ~#3673). Pending: dev RCA verification + tester sister-test authorship + owner approve.*

— @architect