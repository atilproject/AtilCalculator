# STORY-S28-011: Workflow permissions + timeout-minutes hardening backport to tmpl (TD-029)

> **Sprint 28 ID mapping**: Issue #974 ID = `TD-029`; PM canonical ID = `STORY-S28-011`

## User Story
As a **Project Founder using `dev-studio-template` workflows in a fresh project**,
I want **every template workflow file to have explicit `permissions:` block + `timeout-minutes:` cap**,
So that **a misbehaving job doesn't run forever (no hang) + has least-privilege token scope (no over-broad `write-all` default)**.

## Why now
Sprint 28 wave 3 (TD-029 close-out). Per architect 9-Lens review (PR #967 §19.2 i): 0/9 tmpl workflows have explicit `permissions:`; tmpl has no `timeout-minutes:` cap. Calc has 12/12 explicit permissions + 5-30min caps. Backport = template parity.

## Acceptance Criteria
- **AC1** — GIVEN canonical tmpl `.github/workflows/*.yml` (9 files) WHEN I grep for `permissions:` THEN 9/9 have explicit `permissions: contents:read` (or equivalent least-privilege).
- **AC2** — GIVEN the 9 tmpl workflows WHEN I grep for `timeout-minutes:` THEN 9/9 have explicit cap (5-30min range per workflow type).
- **AC3** — GIVEN the d083-workflow-hardening.sh d-test WHEN run on tmpl THEN GREEN (no FAIL on permissions or timeout-minutes gaps).
- **AC4** — GIVEN ADR-0059 WHEN I list `docs/decisions/` THEN it's authored (lens i, TD-029 close-out).

## Out of scope
- Adding new workflow features (this is hardening only)
- Modifying calc workflows (calc is the source; tmpl catches up)

## Open questions
- [ ] What's the right default `timeout-minutes:` for CI workflows vs deploy workflows? → owner: developer (per-workflow-type calibration)
- [ ] Should the `permissions:` block be uniform or per-workflow-type? → owner: architect (lens i precedent)

## Mockups / references
- PR #967 §19.2 audit-baseline.md (lens i FAIL DETECTED)
- ADR-0059 (lens i baseline, draft during W1)
- §20.1 ADR pre-allocation (ADR-0059 reserved for this close-out)

## Dependencies
- **Upstream**: S28-006 (INDEX.md refresh — ADR-0059 entry must exist)
- **Downstream**: S28-013 d-test regression (d083 GREEN required)

## Metrics of success
- **Leading**: 9/9 tmpl workflows pass permissions + timeout-minutes checks (vs 0/9 pre-backport)
- **Lagging**: no timeout-induced billing surprises in tmpl-projects (Actions quota defended)

## Cross-references
- Issue #974 (top-14 TD-029)
- ADR-0059 (sister)
- PR #967 §19.2 (architect finding)