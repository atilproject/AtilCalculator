# STORY-S28-006: Append 28th ADR to docs/decisions/INDEX.md (or close superseded entries)

> **Sprint 28 ID mapping**: Issue #974 ID = `SL-04`; PM canonical ID = `STORY-S28-006`

## User Story
As an **architect agent drafting a new ADR in any new project bootstrapped from `dev-studio-template`**,
I want **`docs/decisions/INDEX.md.tmpl` to accurately reflect 28+ ADRs (currently 27 — missing ADR-0058 pre-allocation for Sprint 28)**,
So that **I don't write ADR-0058 unaware that it's reserved for workflow SHA-pin enforcement, avoiding mid-sprint renumbering**.

## Why now
Sprint 28 wave 1 (low-risk, 0.5sp, fast). ADR pre-allocation map per §20.1 audit-baseline reserves ADR-0058..ADR-0071 (14 slots) for Sprint 28 audit-fix ADRs. Without INDEX.md refresh, mid-sprint ADR renumbering risk = A-19.7.

## Acceptance Criteria
- **AC1** — GIVEN the canonical tmpl `docs/decisions/INDEX.md.tmpl` WHEN I list ADR entries THEN I see all 28+ ADRs (1-27 existing + 0058-0071 reserved per §20.1).
- **AC2** — GIVEN the INDEX.md WHEN I grep for `ADR-0058` THEN I see it listed with topic = "Workflow SHA-pin enforcement (lens h, TD-028 close-out)".
- **AC3** — GIVEN the INDEX.md WHEN I run a script that validates ADR-number uniqueness THEN no duplicate numbers; reserved range ADR-0058..0071 marked as `[RESERVED — Sprint 28]`.

## Out of scope
- Authoring new ADR content (this story is INDEX.md refresh only)
- Closing superseded ADRs (deferred to Sprint 29+)

## Open questions
- [ ] Should the tmpl's INDEX.md use a YAML frontmatter or pure markdown table? → owner: architect
- [ ] Is the `[RESERVED]` marker language consistent with existing precedent? → owner: architect

## Mockups / references
- PR #967 §20.1 audit-baseline.md (ADR pre-allocation map)
- ADR-0058 through ADR-0071 (Sprint 28 audit-fix ADR reservations)

## Dependencies
- **Upstream**: PR #967 squash-merge (audit-baseline source-of-truth)
- **Downstream**: ADR-0058, ADR-0059, ADR-0074, ADR-0061 (W1 stories that consume these ADR numbers)

## Metrics of success
- **Leading**: ADR count in tmpl INDEX.md = 28+ (vs 27 pre-refresh)
- **Lagging**: no mid-sprint ADR renumbering during Sprint 28 (verifiable via git log on docs/decisions/)

## Cross-references
- Issue #974 (top-14 SL-04)
- §20.1 ADR pre-allocation map (14 reserved slots)