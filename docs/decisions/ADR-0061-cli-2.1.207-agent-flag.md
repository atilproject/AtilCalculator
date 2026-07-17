# ADR-0061: Claude Code 2.1.207 — Remove `--agent` Flag from Custom Agent Invocation (AtilCalculator sister to template ADR-0060)

**Status**: Proposed
**Date**: 2026-07-17
**Deciders**: @architect (doctrine + design memo per Cadence Rule 2 amendment cycle ~#2776), @developer (impl in `scripts/dev-studio-start.sh:149`), @tester (dNNNN-cli-arg-hygiene d-test RED-first per ADR-0044), @atilcan65 (owner squash gate per ADR-0031)
**Refs**: Template [ADR-0060](https://github.com/atilproject/dev-studio-template/blob/main/docs/decisions/ADR-0060-claude-code-2.1.207-agent-flag.md) (claude code breaking change home), template PR #97 (ADR-0060 docs, MERGED 2026-07-14T19:55:03Z), template PR #108 (d0984-cli-arg-hygiene d-test Closes #89, MERGED 2026-07-15T10:43:55Z), template PR #110 (impl fix Closes #90 Refs #89, MERGED 2026-07-15T10:51:53Z)
**Closes**: AtilCalculator sister issue (d-test RED — opening in this dispatch per Cadence Rule 2)

**Sister-patterns**:
- ADR-0012 (4-cat label invariant — sister issues follow)
- ADR-0015 (atomic 4-flag handoff — terminal merge gate)
- ADR-0024 (verdict-by time-anchor pattern)
- ADR-0044 (RED-first TDD — d-test pattern)
- ADR-0045 (9-Lens Review Checklist — arch verdict gate on impl PR)
- ADR-0049 (d-test framework — TC contract)
- ADR-0055 (Cadence Rule 1 atomic — this ADR + d-test + impl + INDEX row in cluster-squash, sister-pattern)
- ADR-0057 (Closes-anchor strict format)
- ADR-0059 (cluster-squash batch-lag detection — sister-pattern)
- ADR-0031 (owner squash gate — terminal hand-off)
- RETRO-023 (cross-repo workstream doctrine — forward-port target: AtilCalculator)
- RETRO-024 (work-done-elsewhere 4-cat exception)

> **§20.1 reservation note**: AtilCalculator ADR-0060 is already authored as "§AC Mapping Verification Doctrine" (15KB, 2026-07-01, Closes Issue #604). Per template ADR-0060 §20.1 reservation supersession note, ADR-0061 is the AtilCalculator sister number for this fix. The AC Mapping doctrine retains its canonical home as AtilCalculator ADR-0060; this ADR-0061 = claude-code-2.1.207 sister on AtilCalculator side.

## Context

### Orphan-impl cadence-rule gap (cycle ~#2776, owner directive 2026-07-17 ~08:34Z)

Template ADR-0060 + d0984 d-test + impl PR landed 2026-07-14/15 (PR #97, #108, #110, all MERGED). AtilCalculator sister-PR was NEVER opened — orphan-impl cadence gap. Owner manually applied the line-149 fix to AtilCalculator's `scripts/dev-studio-start.sh` 3 separate times across the 5-day window (revert storm from owner queue-resets + sprint-boundary cleanups). Persistence requested.

### Claude Code CLI 2.1.207 breaking change (2026-07-14 03:31 mtime)

Per template ADR-0060 §Context: Claude Code CLI 2.1.207 removed `--agent` custom agent discovery from `claude --help`. Built-in agents only; custom `.claude/agents/<role>.md` is exclusively loaded via `--append-system-prompt-file`. The `--agent` flag is now redundant and broken.

**AtilCalculator impact** (same class as template): 5 tmux panes (orch/pm/arch/dev/tester) launch via `scripts/dev-studio-start.sh:149`. Without the fix, all 5 panes fall back to shell with no soul identity loaded. Per-OS systemd user units still poll queues, but agents have no role-bound behavior.

### Byte-match verification (architect pre-flight, cycle ~#2754)

Verified working-tree `scripts/dev-studio-start.sh:149` fix in AtilCalculator repo is **byte-identical** to template PR #110's diff:

- **AtilCalculator working tree** (cycle ~#2754): `claude --dangerously-skip-permissions --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "\$KICKOFF_PROMPT"`
- **Template PR #110** (MERGED 2026-07-15T10:51:53Z): same line, `--agent "${role}"` removed, identity loaded via `--append-system-prompt-file` only

Code-only `diff` of `gh pr diff 110` vs `git diff HEAD scripts/dev-studio-start.sh` = BYTE-MATCH (template `+`/`-` lines = AtilCalculator `+`/`-` lines). Headers differ (template PR has full patch metadata), but the operative one-line change is identical.

### Cadence Rule 2 amendment (cycle ~#2776)

Orchestrator soul file `.claude/agents/orchestrator.md` carries the Cadence Rule 2 amendment (live since cycle ~#2776):

> **§Cadence Rule 2 — ADR Merge → Sister-Issue Dispatch Atomicity**: When ANY `docs/decisions/ADR-NNNN-*.md` PR merges to main (or sister-pattern RETRO/Issue body lists tracked sister issues), the SAME TURN MUST also `@`-mention-dispatch each listed sister issue to its `agent:*` owner — OR the turn is recorded as **INCOMPLETE** in `/var/log/dev-studio/AtilCalculator/auto-claim.log`.

This ADR is the AtilCalculator-side retroactive closure of the Cadence Rule 2 gap surfaced by template ADR-0060's orphan-impl chain.

## Decision

**Apply the line-149 fix to AtilCalculator's `scripts/dev-studio-start.sh` (persist via PR, not just working tree), and create the corresponding AtilCalculator sister-task graph (1 d-test issue + 1 impl issue) per Cadence Rule 2.**

### Diff spec (single line, line 149)

**Before** (broken on CLI ≥2.1.207):

```bash
claude --dangerously-skip-permissions --agent "${role}" --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "\$KICKOFF_PROMPT"
```

**After** (works on CLI ≥2.1.207):

```bash
claude --dangerously-skip-permissions --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "\$KICKOFF_PROMPT"
```

Single-line removal (1 token: ` --agent "${role}"`). No other changes needed — `--append-system-prompt-file` is the load-bearing identity mechanism.

### AtilCalculator sister-task graph (Cadence Rule 2 atomic)

| Task | Owner | Status | Depends on |
|---|---|---|---|
| This ADR (ADR-0061 design memo) | @architect | In progress | — |
| Sister issue A (dNNNN-cli-arg-hygiene d-test RED-first) | @tester | Opening this dispatch | This ADR merge-ready |
| Sister issue B (impl PR — remove `--agent` from heredoc, persist via PR) | @developer | Pending tester 🟢 | Sister issue A GREEN |
| Owner squash-merge | @atilcan65 | Pending all peer 🟢 | Sister issue B merge-ready |

### Sister-issue labeling discipline

Per ADR-0012 (4-cat invariant) + ADR-0015 (atomic 4-flag handoff) + RETRO-024 (work-done-elsewhere exception):

**Issue A (d-test, tester)**:
- `type:feature` + `priority:P1` + `status:ready` + `agent:tester` + `cc:tester`
- Sister-pattern: template #89 (labels: `type:feature`, `priority:P1`, `sprint:current`, `template-gap-close`)
- Body must reference `Closes #N` (per ADR-0057 parser-friendly format) where #N = this dispatch cycle's d-test sister issue

**Issue B (impl, developer)**:
- `type:fix` + `priority:P1` + `status:ready` + `agent:developer` + `cc:developer`
- Sister-pattern: template #90 (labels: `type:fix`, `priority:P1`, `sprint:current`, `template-gap-close`)
- Body must reference `Refs #M` (d-test sister issue, informational) + `Closes #N` (own closure)

### Cluster-squash pattern (ADR-0059 sister-pattern)

Per RETRO-029 (cluster-squash inventory) + ADR-0055 (Cadence Rule 1 atomic): the impl PR MUST contain this ADR + d-test + impl + INDEX.md row in the same cluster-squash (or sequential PRs within 60s squash window per ADR-0059). Avoids re-introducing the orphan-impl cadence gap.

### Alternatives considered

| Alternative | Pros | Cons | Decision |
|---|---|---|---|
| Don't persist (leave working-tree only) | Zero work | Re-revert on every queue-reset, same pathology | ❌ Rejected |
| Pin old CLI version (<2.1.207) | No code change | Security + feature regression, blocks future Claude Code features | ❌ Rejected |
| Wrapper script (translate `--agent` → `--append-system-prompt-file`) | Backward compatible | Extra layer, indirection, harder to debug, YAGNI | ❌ Rejected |
| **Persist via PR + Cadence Rule 2 sister-task graph** | Closes the orphan-impl gap doctrinally, single-token diff, already wired | None | ✅ **Adopted** |

## Consequences

### Positive

- ✅ AtilCalculator works on Claude Code CLI ≥2.1.207 (current main branch)
- ✅ Single-token change (low diff surface, easy to review)
- ✅ `--append-system-prompt-file` is already wired + smoke tested (owner manual fix verified prod)
- ✅ Closes the orphan-impl cadence-rule gap (Cadence Rule 2 amendment home)
- ✅ Sister-task graph follows template's working pattern (Issue #89 d-test → Issue #90 impl chain)

### Negative (accepted)

- ⚠️ Pane title match (`agent-watch.sh` line ~1468) fails every poll — fallback index map (window:main, panes 0-4 = orch/pm/arch/dev/tester) is the safety net, working as designed (per template ADR-0060 §Consequences)
- ⚠️ Sister-PR scope = AtilCalculator-only on this PR; if `dev-studio-launcher` symlinks to `dev-studio-start.sh`, separate sister-PR needed (verify in launcher audit-baseline)
- ⚠️ Pre-2.1.207 deployments that relied on the redundant `--agent` flag will see no functional change (silent warning, not error in older CLIs)
- ⚠️ Cadence Rule 2 retrospective lens — if this ADR is itself left orphan (impl PR doesn't land within 7 days), Sprint retro MUST file a RETRO entry capturing the gap (per Cadence Rule 2 §4)

### Neutral

- 🔄 Sister-pattern: ADR-0059 cluster-squash (Sprint 28 forward-port neighbor) — applies to this ADR's sister-task chain
- 🔄 d-test framework (ADR-0049) + RED-first (ADR-0044) — sister issue A follows dNNNN-cli-arg-hygiene pattern, lands atomic per ADR-0055 §1
- 🔄 Cross-repo workstream (RETRO-023) — template ADR-0060 → AtilCalculator ADR-0061 forward-port

## Future work (out of scope for this ADR)

- Pane targeting hardening (title match fragility under OSC-2 overrides) — Sprint 30+
- Sister-PR to `atilcan65/dev-studio-launcher` if `scripts/dev-studio-start.sh` is symlinked (verify in launcher audit-baseline)
- Backport to any pre-2.1.207 deployments that may have other `--agent`-dependent code paths
- Cadence Rule 2 RETRO entry: if sister-issue B impl doesn't land within 7 days of this ADR merge, Sprint retro MUST file per Cadence Rule 2 §4

## Reversibility

Reversible by reverting the single-token change (1 line in `scripts/dev-studio-start.sh`). Pre-2.1.207 versions of Claude Code silently ignored the redundant `--agent` flag (warning, not error), so rollback does NOT break older CLI deployments. Rollback risk: **negligible**.

## Cross-references

- **Template ADR-0060** — claude code breaking change home (template repo, MERGED 2026-07-14T19:55:03Z)
- **Template PR #97** — ADR-0060 docs (MERGED)
- **Template PR #108** — d0984-cli-arg-hygiene d-test (MERGED 2026-07-15T10:43:55Z, Closes #89)
- **Template PR #110** — impl fix (MERGED 2026-07-15T10:51:53Z, Closes #90 Refs #89)
- **Template Issue #89** — sister d-test task (CLOSED via PR #108)
- **Template Issue #90** — sister impl task (CLOSED via PR #110)
- **AtilCalculator PR #1085** (claimed sister-impl precedent in PR #110 body) — **DOCUMENTATION DEFECT**: PR #1085 was actually `agent-watch.sh org-scan default + 180s poll cadence`, unrelated to this fix. PR #110's body misreference noted in this ADR's Context §Byte-match verification.
- **Orchestrator soul `.claude/agents/orchestrator.md`** §Cadence Rule 2 amendment (cycle ~#2776)
- **ADR-0031** — owner squash gate (terminal hand-off)
- **ADR-0044** — RED-first TDD
- **ADR-0045** — 9-Lens Review Checklist
- **ADR-0049** — d-test framework
- **ADR-0055** — Cadence Rule 1 atomic
- **ADR-0057** — Closes-anchor strict format
- **ADR-0059** — cluster-squash batch-lag detection
- **RETRO-023** — cross-repo workstream doctrine
- **RETRO-024** — work-done-elsewhere 4-cat exception
- **Cycle ~#2776** — Cadence Rule 2 amendment home
- **Cycle ~#2754** — architect bootstrap pre-flight (this ADR drafted)

— @architect (cycle ~#2755, KAPI hotfix dispatch, Cadence Rule 2 amendment retroactive closure)