# STORY-S28-005: RE-RENDER calc's `.claude/agents/*.md` from updated tmpl (Gap 2, sister-pattern)

> **Sprint 28 ID mapping**: Issue #974 ID = `SL-03`; PM canonical ID = `STORY-S28-005`

## User Story
As **Atil (current owner of atilcalc)**,
I want **a re-render of calc's `.claude/agents/*.md` files from the now-updated canonical tmpl (after S28-001 + S28-002 + S28-004 ports land)**,
So that **calc's agents pick up the 3 amend blocks + the new scripts (peer-poke.sh pattern) without manual copy-paste**.

## Why now
Sprint 28 wave 2 (CRITICAL — closes Gap 2 of the 2-gap architecture). Gap 1 = forward-port doctrine to canonical tmpl (S28-001/002/004). Gap 2 = re-render project-local mirrors from updated tmpl (this story). Without Gap 2 closure, the canonical tmpl updates don't reach calc's runtime agents.

## Acceptance Criteria
- **AC1** — GIVEN the canonical tmpl orchestrator.md.tmpl is updated post-S28-001+002+004 (3 amend blocks present) WHEN I run `bash scripts/dev-studio-init.sh` in atilcalc THEN calc's `.claude/agents/orchestrator.md` is regenerated with the 3 amend blocks matching tmpl verbatim.
- **AC2** — GIVEN the re-render WHEN I diff calc's `.claude/agents/orchestrator.md` vs the canonical tmpl's render-output THEN the only differences are: (a) hand-edits preserved per calc-specific override file, (b) sprint-22 Q-cluster-specific amendments (if any).
- **AC3** — GIVEN the re-render WHEN I run `wc -l .claude/agents/*.md` THEN total LOC is ~408 (vs ~404 pre-render), reflecting the 3 new amend blocks.

## Out of scope
- Adding NEW hand-edits to calc's `.claude/agents/*.md` (this story is re-render only; net-new doctrine = S28-001/002/004)
- Forward-porting to other projects (atilcalc only for Sprint 28)

## Open questions
- [ ] Does calc have an `.override.md` file per agent that survives re-render? → owner: architect (verify override pattern)
- [ ] Should sprint-22 Q-cluster amendments (calc-specific) survive the re-render or be re-evaluated? → owner: orchestrator

## Mockups / references
- PR #967 §6.1 + §6.4 audit-baseline.md (Gap 1 + Gap 2 architecture clarification)
- PM 5th-pass cmt 4938118016 (architecture note: canonical tmpl → local mirror → .md render chain)

## Dependencies
- **Upstream (CRITICAL)**: S28-001, S28-002, S28-004 must all merge BEFORE this story (Cadence Rule 1 atomic per ADR-0055)
- **Downstream**: S28-010 (CLAUDE.md reconcile — depends on this re-render)

## Metrics of success
- **Leading**: calc `.claude/agents/orchestrator.md` amend-block count = 3/3 post-render (vs 3/3 pre-render, but now from tmpl-sourced not hand-edited)
- **Lagging**: calc agent behavior post-re-render matches tmpl-design intent (no regression on Sprint 26 cycles)

## Cross-references
- Issue #974 (top-14 SL-03)
- ADR-0055 §1 (Cadence Rule 1 atomic)
- Issue #971 (PM-A-DELTA-13 per-soul amend-block diff plan — sister-pattern)