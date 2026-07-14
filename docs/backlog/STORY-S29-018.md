# STORY-S29-018: 8 docs sub-dir skeletons (Phase 2 expansion of S29-012)

> **PM-authored from `docs/sprints/sprint-29/00-plan.md` §3 S29-018** (PM grooming cycle ~#1566 per [ORCH→PM] dual-channel wake 2026-07-14T21:03:32+03:00 carrying owner directive 21:02+03).
> **Sprint 29 sizing:** S effort. S29-012 OBSOLETED — this story ABSORBS + EXPANDS S29-012 per arch v3 audit §G recommendation + owner directive #6.

## User Story

As **a downstream-project operator using the template**,
I want **`docs/{backlog,bugs,designs,product,retros,soul-amends,sprints,test-plans}/` sub-dir skeletons present at init (each with README + lane-specific .tmpl document templates)**,
So that **my project inherits lane-aligned doc structure from day one, not ad-hoc**.

## Why now

Template docs/ sub-dirs: 2 (decisions/, templates/). AtilCalculator docs/ sub-dirs: 11 (backlog, bugs, decisions, designs, ops, product, proposals, retros, soul-amends, sprints, test-plans). Gap = 9 sub-dirs. Per Phase 2 owner #6 directive, port 8 (skip ops/ + proposals/ which are AtilCalculator-specific). Without sub-dir skeletons, downstream projects have to manually create dirs + write READMEs before they can adopt lane-aligned doctrinel. This blocks sister-pattern doc-portage from S29-007 sister-pattern.

## Acceptance Criteria

- **AC1** — 8 docs sub-dir skeletons created in template, each with README documenting lane ownership + sibling-pattern + AC for content shape:
   - `docs/backlog/` (PM-owned, README + STORY-NNN.md.tmpl skeleton)
   - `docs/bugs/` (tester-owned, README + BUG-NNN.md.tmpl skeleton)
   - `docs/designs/` (architect-owned, README + DESIGN-NNN.md.tmpl skeleton)
   - `docs/product/` (PM-owned, README + vision.md.tmpl placeholder)
   - `docs/retros/` (orchestrator-owned, README + RETRO-NNN.md.tmpl skeleton)
   - `docs/soul-amends/` (orchestrator-owned, README — Sprint 28 introduced this; needs template-render)
   - `docs/sprints/` (orchestrator-owned — S29-012 original; README + plan.md.tmpl + close.md.tmpl)
   - `docs/test-plans/` (tester-owned, README + TEST-PLAN-NNN.md.tmpl skeleton)
- **AC2** — Each sub-dir README documents lane ownership + sibling-pattern + AC for content shape (≥ 1 section heading per README; non-empty).
- **AC3** — `dev-studio-init.sh` updated to render all 8 sub-dirs via `mkdir -p + render-template` (sister-pattern to existing `.claude/` render path per ADR-0050).
- **AC4** — Multi-lane co-CC per lane ownership matrix (CLAUDE.md §File ownership matrix): PM on backlog/product, tester on bugs/test-plans, architect on designs, orchestrator on retros/soul-amends/sprints.
- **AC5** — d-test (new, ≥3 TCs per ADR-0049): validates sub-dir presence + README shape + lane-ownership matrix consistency (sub-dir-to-lane mapping matches the table).

## Out of scope

- Porting `docs/ops/` and `docs/proposals/` sub-dirs (AtilCalculator-specific per Phase 2 owner #6 directive).
- Backfilling example content per sub-dir (README + skeleton only; example content is project-specific).

## Open questions

- [ ] **Architect**: confirm each sub-dir README includes a `## Lane ownership` section header for machine-parseable d-test (per AC5).
- [ ] **PM**: confirm PM lane ownership assertion for `docs/backlog/` and `docs/product/` per `CLAUDE.md §File ownership matrix` (currently PM-only) — multi-lane co-CC for product-related docs (vision/personas OK).

## Dependencies

- **Upstream:** S29-016 (render path doctrine — `dev-studio-init.sh` updates cascade to this story); S29-007 (sister-pattern — the d1021 themed PR forward-port pattern provides the precedent for sub-dir skeleton rendering).
- **Downstream:** Sprint 30+ docs re-render (after S29-015 close); downstream-project doc adoption.

## Metrics of success

- **Leading:** d-test (AC5) GREEN in CI.
- **Leading:** downstream dry-run `ls docs/backlog docs/bugs docs/designs docs/product docs/retros docs/soul-amends docs/sprints docs/test-plans` returns 8 entries.
- **Leading:** each sub-dir README has ≥ 1 section heading (machine-parseable).

## Sizing

- **Hint:** S effort (8 sub-dirs with README + skeleton files).
- **Final:** S (per plan.md §3 table; S29-012 absorbed + expanded).

## Lane

- **Author:** architect (template render doctrine + lane-ownership matrix consistency)
- **Reviewer:** architect (9-Lens per ADR-0045; sub-dir-to-lane mapping verification)
- **Co-CC:** orchestrator (docs/sprints/ + retros + soul-amends content); PM (backlog + product docs); tester (bugs + test-plans docs); developer (init-script render path per ADR-0050)
- **Tester:** tester (d-test per ADR-0044; lane-ownership consistency per AC5)
- **Owner squash gate:** per ADR-0031 (template-load-bearing)

## Sprint 29 Context

- **Epic:** E6 — Doc Structure Portage (Wave 2B parallel)
- **Wave:** Wave 2B (parallel with Wave 2C)
- **Source-of-truth:** `docs/sprints/sprint-29/00-plan.md` §3 S29-018 (S29-012 OBSOLETED)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
