# STORY-S24-003 (DRAFT): Post-cut RETRO entry — PM lens on v1.0.0 GA cut path-drift episode

## User Story
As **@product-manager** writing RETRO entries for Sprint 24,
I want **a dedicated PM-lens retrospective on the v1.0.0 GA cut path-drift episode** (PR #921 / vision.md vs. glossary.md),
So that **Sprint 25+ PM lane carries forward the lesson "verify shipped artifacts match vision claims before declaring GA ready"**.

## Why now
The path-drift episode (vision.md line 120 claimed `docs/product/glossary.md` while reality was `docs/glossary.md`) was discovered 3 minutes AFTER Steps 3+4 of #917 executed (tag + canary push). PM recommended merge-before-cut (Option 1); owner chose override (Option 2 implicit by execution timing). This is a real lesson:
- PM discovered the drift DURING #918+#919 merge verification
- PM should have caught this in pre-cut validation (Issue #917 §Pre-cut verification table)

This is a systemic gap in PM pre-cut checklist. Needs retro entry + future-checklist update.

## Acceptance Criteria
- **AC1** — RETRO entry posted as comment on Sprint 24 plan.md (orchestrator lane, but PM contributes per cross-lane pattern) AND as a new `docs/sprints/sprint-24/RETRO-NNN-pm-path-drift.md` (PM-owned per file ownership matrix).
- **AC2** — RETRO entry contains: episode summary (timeline T-3min discovery to PR #921), root cause analysis (PM pre-cut checklist did not include "vision claim vs shipped reality diff"), PM-side fix proposal (add "vision claim verification" to PM pre-cut checklist + template-render check).
- **AC3** — RETRO entry cross-refs: PR #921, Issue #917, Issue #867 (Template v1.0 GA Scope source), TD-067 (sister-pattern filed by orchestrator).
- **AC4** — Sister-pattern noted: this is a category "vision↔shipped drift" (sister to "changelog↔release drift" sister-pattern in #918+#919, and "doc↔doc link drift" sister-pattern in TD-054 docs-tree ID/path drift fix).

## Out of scope
- Authoring the actual pre-cut checklist template (separate STORY-S24-004 candidate).
- Closing PR #921 (owner-only).

## Open questions
- [ ] Is there a higher-level "RETRO-NNN.md" template in this project, or do we author standalone? → PM pre-flight: `ls docs/sprints/sprint-*/RETRO-*`.

## Mockups / references
- PR #921 (the path-drift fix PR)
- Issue #917 (Template v1.0.0 GA cut)
- TD-067 (orchestrator-filed sister-pattern)
- Issue #867 (PM consultation that added §Template v1.0 GA Scope to vision.md)
- TD-054 (arch sister-pattern: docs-tree ID/path drift)

## Dependencies
- Upstream: PR #921 status (still open as of 2026-07-09T09:25Z)
- Downstream: PM pre-cut checklist update (separate STORY if PM proceeds)

## Metrics of success
- **Leading**: RETRO entry posted within 3 cycles (~15 min).
- **Lagging**: Sprint 25 PM lane starts with updated pre-cut checklist template.

## Sprint
Sprint 24 §Phase 3 (post-cut sister-handoff)

## Priority
P3 (process improvement, not blocking any delivery)

## Story points (proposed by PM, joint sizing TBD)
0.25sp — single retrospective write, no impl.