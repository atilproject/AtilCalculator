# STORY-S24-001 (DRAFT): PM-lane answerable Sprint 22 advisory Q triage

## User Story
As **@atilcan65 (owner)** reviewing Sprint 22 advisory carry-over,
I want **a Q→lane mapping of the 11 open Sprint 22 advisory questions (Q1/Q2/Q4-Q12, Q3 closed)**,
So that **I can quickly decide which Q's land in PM lane for direct answer vs. deferral vs. cross-lane hand-off**.

## Why now
Sprint 24 §Phase 3 sister-handoff (per #916 + orchestrator dual-channel wake 2026-07-09T09:25Z) put PM on backlog lane. Sprint 22 advisory Q's have been open since Sprint 22 close (2026-07-02T13:37:50Z) — 7+ days. Owner can act faster with a lane pre-classification than scanning 11 Q's cold.

## Acceptance Criteria
- **AC1** — Given Issue tracking the 11 Q's, When PM produces the mapping comment, Then each Q (Q1, Q2, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12) has a lane classification (PM-direct / PM-defer-to-other-lane / owner-only / not-actionable).
- **AC2** — For PM-direct Q's, draft 1-line answer per Q ready for owner review (≤10 words each).
- **AC3** — For PM-defer-to-other-lane Q's, identify target role + reference to relevant ADR/Issue.
- **AC4** — Output posted as comment on #916 (PM-lane ACTIVE thread) + cross-ref to this STORY.
- **AC5** — Mapping is ≤2 pages, scannable in ≤30 seconds by owner.

## Out of scope
- Deciding answers for Q's outside PM lane (architect/dev/tester Q's) — PM only flags, does not author.
- Closing the underlying Q issues — owner-only per ADR-0031.

## Open questions
- [ ] Where are the Q1-Q12 original Issues located? (search needed in PM pre-flight) → PM to investigate before AC1.

## Mockups / references
- Sprint 22 close.md (docs/sprints/sprint-22/close.md)
- Issue #711 (Sprint 22 PIVOT close-out)
- #916 §Sprint 22 advisory carry-over reference

## Dependencies
- Upstream: none (PM-owned, can start now)
- Downstream: owner's Sprint 24 scope refinement (after mapping delivered)

## Metrics of success
- **Leading**: Mapping comment posted within 5 cycles (~25 min) of this STORY creation.
- **Lagging**: Owner closes ≥3 advisory Q's within 24h of mapping delivery.

## Sprint
Sprint 24 §Phase 3 (post-cut sister-handoff)

## Priority
P2 (post-cut hygiene, not blocking Sprint 24 delivery)

## Story points (proposed by PM, joint sizing TBD)
0.5sp — mostly PM-side research + 1 mapping doc; no impl work.