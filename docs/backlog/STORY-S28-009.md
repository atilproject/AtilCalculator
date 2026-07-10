# STORY-S28-009: Mass-close 11 dormant Sprint 22 Q-cluster issues as `not_planned`

> **Sprint 28 ID mapping**: Issue #974 ID = `Sprint-22-Q`; PM canonical ID = `STORY-S28-009`

## User Story
As **Atil (current owner)** + **orchestrator (board-hygiene owner)**,
I want **the 11 dormant Sprint 22 Q-cluster issues (Q1, Q2, Q4-Q12) closed as `not_planned` per Issue #939 precedent**,
So that **the GitHub Project board's backlog lane is clean (no zombie Qs) and PM's grooming has accurate "real backlog" signal**.

## Why now
Sprint 28 wave 2 (PM hygiene, 2sp). Per D-OD2 default accepted: "Mass-close 11 dormant Q as `not_planned` (Issue #939 precedent)." Qs have been dormant since Sprint 22 closure (~6 sprints ago) and pollute the backlog lane view.

## Acceptance Criteria
- **AC1** — GIVEN the 11 Q-cluster issues (Q1, Q2, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12) WHEN I close them as `not_planned` THEN each issue has a closing comment citing Issue #939 precedent + Sprint 22 cycle origin.
- **AC2** — GIVEN the mass-close WHEN I query GitHub Project board backlog lane THEN 0/11 Q-cluster issues appear (clean).
- **AC3** — GIVEN the mass-close WHEN I diff sprint-22 retro references vs current issues THEN no broken Q-cluster references (or explicit deprecation note added to retro).

## Out of scope
- Re-opening any Q-cluster issue (this is terminal closure, no resurrection)
- Closing other dormant issues (deferred to Sprint 29+ hygiene sweep)

## Open questions
- [ ] Are any Q-cluster issues referenced by code or docs as TODOs? → owner: PM (grep for Q1-Q12 mentions)
- [ ] Should the closing comment be uniform across all 11, or per-issue contextual? → owner: orchestrator (efficiency vs context)

## Mockups / references
- Issue #939 (precedent — mass-close pattern)
- D-OD2 (owner-decision, accepted default)

## Dependencies
- **Upstream**: NONE (independent hygiene action)
- **Downstream**: Sprint 28 PM grooming output (cleaner backlog = better signal)

## Metrics of success
- **Leading**: Q-cluster issue count delta = -11
- **Lagging**: Project board backlog lane shrinks to actual Sprint 28-relevant items only

## Cross-references
- Issue #974 (top-14 Sprint-22-Q)
- Issue #939 (precedent)
- D-OD2 (owner-decision)