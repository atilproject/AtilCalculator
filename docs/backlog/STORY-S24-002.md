# STORY-S24-002 (DRAFT): 9-decom verdict re-survey — PM backlog territory

## User Story
As **@atilcan65 (owner)** preparing Sprint 24 verdict rounds,
I want **a PM re-survey of the 9-decom verdict items (#634/#640/#641/#643/#644/#646/#647/#650/#654)**,
So that **I can confirm PM's CLOSE-all recommendation (per Sprint 24 plan.md §Owner verdict dependencies) is still valid against current ground truth**.

## Why now
Per Sprint 24 plan.md (docs/sprints/sprint-24/plan.md), PM recommended CLOSE all 9 items as "covered by existing artifacts". This was drafted cycle ~#3228. Sprint 24 hasn't started yet (window: 2026-07-14 → 2026-07-27); 5+ days have elapsed. Need to re-verify against current state:
- Are the existing artifacts still in place?
- Did anything change since the cycle-#3228 PM recs?
- Does the PM CLOSE-all verdict still hold or should it be amended?

## Acceptance Criteria
- **AC1** — For each of #634/#640/#641/#643/#644/#646/#647/#650/#654, verify the referenced "existing artifact" still exists and matches the original rationale.
- **AC2** — Produce a verdict table: ID | current state | PM recommendation (CLOSE / KEEP / ESCALATE) | rationale.
- **AC3** — Cross-check against docs/bugs/ (bug tracker) and current GitHub issue state for each of the 9.
- **AC4** — Output as comment on #916 (PM-lane ACTIVE thread) for owner verdict consolidation.
- **AC5** — If PM recs change from cycle-#3228 baseline, flag the drift explicitly with cause analysis.

## Out of scope
- Implementing fixes for items that aren't PM lane — only PM lens verification.
- Closing the 9 issues — owner verdict required per ADR-0031.

## Open questions
- [ ] Are there bug reports (#P0/P1) filed against any of the 9 items post-cycle-#3228? → PM pre-flight: `gh issue list --label priority:P0,P1 --state all --search "{issue-numbers}"`.

## Mockups / references
- Sprint 24 plan.md §Owner verdict dependencies
- Issue #767 (Sprint 24 PM lane source)
- PM Issue #740 cmt 4866444696 (cycle ~#3180 full triage table)
- Issue #877 §PM lane follow-up row (Issue #649 partial-coverage sister-pattern)

## Dependencies
- Upstream: docs/sprints/sprint-24/plan.md (DONE)
- Downstream: owner's 9-decom verdict round (after re-survey delivered)

## Metrics of success
- **Leading**: Re-survey table posted within 5 cycles (~25 min).
- **Lagging**: Owner confirms or amends PM recommendations within 24h.

## Sprint
Sprint 24 §Phase 3 (post-cut sister-handoff)

## Priority
P2 (verdict-prep, not blocking Sprint 24 start on 2026-07-14)

## Story points (proposed by PM, joint sizing TBD)
0.5sp — research + verification table; no impl.