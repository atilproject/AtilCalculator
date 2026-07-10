# STORY-S28-012: Workflow SHA-pinning backport (full 40-char SHA required, TD-028)

> **Sprint 28 ID mapping**: Issue #974 ID = `TD-028`; PM canonical ID = `STORY-S28-012`

## User Story
As a **Project Founder using `dev-studio-template` workflows**,
I want **every `uses: actions/*@<ref>` in tmpl workflows replaced with exact 40-char SHA**,
So that **mutable refs can't silently drift (supply-chain attack surface: 0, vs current: 19/19 SHA-pinned in calc but 0/9 in tmpl)**.

## Why now
Sprint 28 wave 3 (TD-028 close-out, R-HIGH-01). Architect 9-Lens review (PR #967 §19.2 h): 0/9 tmpl workflows SHA-pinned = supply-chain risk for ANY new project bootstrapping from tmpl. Calc achieves 19/19 SHA-pinned. Backport = template parity + closes R-HIGH-01.

## Acceptance Criteria
- **AC1** — GIVEN canonical tmpl `.github/workflows/*.yml` (9 files) WHEN I grep for `uses: actions/.*@` THEN 0/9 use mutable refs (e.g., `@main`, `@v1`); all use exact 40-char SHA matching the `pin-to-tag` Dependabot pattern.
- **AC2** — GIVEN d082-workflow-pin.sh d-test WHEN run on tmpl THEN GREEN (no FAIL on mutable refs).
- **AC3** — GIVEN Dependabot config WHEN I list repos THEN `.github/dependabot.yml` exists with weekly digest for `github-actions` ecosystem.
- **AC4** — GIVEN ADR-0058 WHEN I list `docs/decisions/` THEN it's authored (lens h, TD-028 close-out).

## Out of scope
- Adding new workflow features (this is hardening only)
- Modifying calc workflows (calc is the source; tmpl catches up — calc already 19/19)

## Open questions
- [ ] What's the rotation cadence for SHA pins (Dependabot weekly vs monthly)? → owner: developer (R-HIGH-01 maintenance burden)
- [ ] Should SHA pins be auto-updated via Dependabot PRs or require manual review? → owner: architect (security vs velocity)

## Mockups / references
- PR #967 §19.2 + §19.3 audit-baseline.md (lens h FAIL + concrete SHA-pin target list)
- ADR-0058 (lens h enforcement, draft during W1)
- §20.1 ADR pre-allocation (ADR-0058 reserved)
- R-HIGH-01 (risk register entry)

## Dependencies
- **Upstream**: S28-006 (INDEX.md refresh — ADR-0058 entry must exist)
- **Downstream**: S28-013 d-test regression (d082 GREEN required)

## Metrics of success
- **Leading**: tmpl SHA-pin count = 19+/19 (vs 0/9 pre-backport per audit §4.1)
- **Lagging**: no supply-chain drift incidents in tmpl-projects post-backport

## Cross-references
- Issue #974 (top-14 TD-028)
- ADR-0058 (sister)
- PR #967 §19.3 (SHA-pin target list)
- R-HIGH-01 (risk)