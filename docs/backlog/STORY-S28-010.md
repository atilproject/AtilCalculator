# STORY-S28-010: Compare CLAUDE.md vs CLAUDE.md.tmpl post-W1 render (parity sweep)

> **Sprint 28 ID mapping**: Issue #974 ID = `CLAUDE.md reconcile`; PM canonical ID = `STORY-S28-010`

## User Story
As **Atil (current owner)**,
I want **a post-W1-render diff of `CLAUDE.md` (rendered) vs `CLAUDE.md.tmpl` (canonical)**,
So that **calc's project doctrine stays in sync with tmpl's source-of-truth after S28-001/002/004 ports land**.

## Why now
Sprint 28 wave 2 (PM hygiene, 0.5sp). After S28-005 re-render closes Gap 2, calc's `.claude/agents/*.md` will be tmpl-sourced. But `CLAUDE.md` itself has separate render logic + per-project hand-edits. This story surfaces + reconciles any drift.

## Acceptance Criteria
- **AC1** — GIVEN post-S28-005 re-render WHEN I `diff CLAUDE.md CLAUDE.md.tmpl` THEN the only diffs are: (a) per-project hand-edits (e.g., Issue #974 ID references, Sprint 28-specific URLs), (b) sprint-cycle-specific text.
- **AC2** — GIVEN the diff WHEN I categorize each delta THEN drift categories are: (a) acceptable per-project overrides, (b) missing-from-tmpl (candidate forward-port to canonical), (c) unintended drift (fix in render).
- **AC3** — GIVEN the categorized drift WHEN I file follow-up issues for (b) + (c) THEN each follow-up has a clear owner (architect for forward-port, developer for unintended drift).

## Out of scope
- Implementing drift fixes in this story (reconcile = analyze + file follow-ups)
- Modifying CLAUDE.md directly (architect/owner lane per file ownership matrix)

## Open questions
- [ ] Should the diff be human-readable or scripted (yaml/json output)? → owner: PM (presentation preference)
- [ ] Are there calc-specific sections in CLAUDE.md that should NOT exist in tmpl? → owner: architect (override pattern review)

## Mockups / references
- PR #967 §7 audit-baseline.md (CLAUDE.md section coverage parity)
- PM-A-DELTA-08 (PM §21 finding — CLAUDE.md locale drift)

## Dependencies
- **Upstream (CRITICAL)**: S28-005 RE-RENDER must complete first (Cadence Rule 1)
- **Downstream**: Sprint 29 backlog candidates (drift (b) + (c) become Sprint 29 input)

## Metrics of success
- **Leading**: diff output documented + categorized; 0/3 unintended-drift categories at end of story
- **Lagging**: Sprint 29 backlog has parity-sweep follow-up issues pre-populated

## Cross-references
- Issue #974 (top-14 CLAUDE.md reconcile)
- PR #967 §7 (audit findings)
- PM-A-DELTA-08, PM-A-DELTA-09, PM-A-DELTA-10 (PM §21 follow-ups)