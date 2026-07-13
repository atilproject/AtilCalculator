# STORY-S29-010: Forward-port 3 missing workflows + render deploy.yml from .tmpl

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-010`; PM canonical ID = `STORY-S29-010`; Issue #1035
> **Origin**: Sprint 29 W2 grooming, surfaced by Issue #1030 (Wave 2 dispatch)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.Wave 2 / S29-010
> **⚠️ HUMAN-ONLY TERRITORY:** `.github/workflows/` ownership per CLAUDE.md §File ownership matrix — arch proposes, owner approves (esp. AC2 deploy.yml render)

## User Story
As **a downstream project owner who wants full CI matrix + deploy pipeline on day-1**,
I want **3 missing workflows ported (`d050b-dispatch.yml`, `lint-and-test.yml`, `post-squash.yml`) + `deploy.yml` rendered from `deploy.yml.tmpl`**,
So that **template workflow count = 12 (8 stock + 4 new/rendered), all self-hosted (post-S29-001 migration), and `deploy.yml` is ready for production use downstream.**

## Why now
Sprint 29 W2 (per plan §5 dependency on S29-001 — new workflows must inherit the self-hosted 4-tuple migration). Sprint 28 audit §4.5 (Q2 workflows gap) + §5.3 (smoke repo's stock workflows). `deploy.yml.tmpl` exists but unrendered → owner-merge-gated per file ownership matrix.

## Acceptance Criteria (per plan §3.S29-010)

- **AC1** — 3 workflow files ported:
  - `d050b-dispatch.yml` (peer-poke dispatch auto-routing)
  - `lint-and-test.yml` (consolidated lint + test runner)
  - `post-squash.yml` (post-merge cleanup + sync)
- **AC2** — `deploy.yml.tmpl` rendered to `deploy.yml` per **OWNER APPROVAL** (per CLAUDE.md §File ownership matrix — `.github/workflows/` is human-only territory; orchestrator proposes, owner approves). **Owner-decision needed at W2 start**.
- **AC3** — All 4 newly-added/updated workflows pass through S29-001's `runs-on: [self-hosted, Linux, X64, atilproject]` migration (post S29-001 squash-merge to main).
- **AC4** — Per-workflow d-test (≥3 TCs each per ADR-0049): each workflow YAML lints + has ≥1 sample PR validating CI fires correctly on self-hosted runner.

## Done means
Template workflows count = 12 (8 stock + 4 new/rendered); all self-hosted; deploy.yml ready for production use.

## Out of scope
- Modifying existing 8 stock workflows (already migrated to self-hosted via S29-001)
- Adding brand-new workflows not in the 3+1 list
- Renaming workflow files (`.github/workflows/` ownership prohibits rename without owner approval per file ownership matrix)

## Open questions
- [ ] **Owner-decision:** Approve `deploy.yml` render from `deploy.yml.tmpl` at W2 start? (human-only territory per file ownership matrix — **arch proposes, owner approves**) → owner: atilcan65
  - **Default assumption if no objection by W2 mid-sprint:** approve (per owner directive #2 ratification pattern = "approve when no objection by execution time")
- [ ] **`d050b-dispatch.yml` semantic ID**: What does `d050b` mean? Sister-pattern to d050 (existing)? → owner: orchestrator + architect (verify naming convention per ADR-0055)
- [ ] **`lint-and-test.yml` consolidation scope**: Does this consolidate 2+ existing workflows into 1, or is it a new standalone? → owner: developer + architect (workflow architecture call)

## Mockups / references
- `docs/sprints/sprint-29/00-plan.md` §3 Wave 2 / S29-010 (4 ACs canonical)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.5 (Q2 workflows gap), §5.3 (smoke repo's stock workflows)
- AtilCalculator `.github/workflows/` (11 files; port-source 3)
- `deploy.yml.tmpl` (template's parameterized source)
- ADR-0047 (deploy pattern)
- CLAUDE.md §File ownership matrix (`.github/workflows/` = human-only territory)
- ADR-0055 (d-test ID uniqueness — for `d050b-dispatch.yml` ID slot)

## Dependencies
- **Upstream**: S29-001 (self-hosted 4-tuple migration; new workflows inherit)
- **Downstream**: S29-014 (verify-portage)

## Metrics of success
- **Leading**: PR merged to template main (arch PR + owner approve for AC2); AC1-AC4 met; per-workflow d-test green on self-hosted runner
- **Lagging**: Workflow count parity (template 8 → 12 post-portage); deploy.yml production-ready

## Cross-references
- Issue #1035 (this story, opened cycle ~#1307)
- Issue #1030 (Wave 2 dispatch parent)
- Issue #1013 (S29-001 — upstream blocker)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-010, §7 (owner-approval requirements)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.5
- CLAUDE.md §File ownership matrix (`.github/workflows/` human-only territory)
- ADR-0047 (deploy pattern), ADR-0055 (d-test ID uniqueness)
- Sister-pattern: AtilCalculator `.github/workflows/` (all 11 self-hosted via Sprint 27 migration)
