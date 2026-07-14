# STORY-S29-019: 6 top-level docs files .tmpl render (Phase 2 NEW)

> **PM-authored from `docs/sprints/sprint-29/00-plan.md` §3 S29-019** (PM grooming cycle ~#1566 per [ORCH→PM] dual-channel wake 2026-07-14T21:03:32+03:00 carrying owner directive 21:02+03).
> **Sprint 29 sizing:** M effort (Phase 2 NEW). Multi-lane co-owned.

## User Story

As **a downstream-project operator using the template**,
I want **6 top-level docs files (`USER-GUIDE.md`, `glossary.md`, `index-cadence.md`, `new-projectsteps.md`, `peer-poke-spec.md`, `tech-debt.md`) to render at init via `dev-studio-init.sh`**,
So that **my project inherits the universal docs scaffold (PM user-guide + universal cadence + peer-poke spec + tech-debt ledger)**.

## Why now

Template docs/ top-level files: 4 (.gitkeep, CONTEXT-HYGIENE.md, OPERATIONS.md.tmpl, TELEGRAM-SETUP.md, TROUBLESHOOTING.md.tmpl). AtilCalculator docs/ top-level files: 12 (CLAUDE.md, CONTEXT-HYGIENE.md, OPERATIONS.md, TELEGRAM-SETUP.md, TROUBLESHOOTING.md, USER-GUIDE.md, backlog.json, glossary.md, index-cadence.md, new-projectsteps.md, peer-poke-spec.md, tech-debt.md). Gap = 6 port-worthy files. Arch v3 audit §C Gap 8 flagged this coverage gap (4 vs 12). Without these, downstream projects have no canonical universal scaffold.

## Acceptance Criteria

- **AC1** — 6 top-level docs files added to template (as `.tmpl` where parameterized):
   - `docs/USER-GUIDE.md.tmpl` (PM-owned content; placeholder for project-specific customizations)
   - `docs/glossary.md.tmpl` (orchestrator-owned; universal terms — agent roles, ADR, d-test, etc.)
   - `docs/index-cadence.md.tmpl` (orchestrator-owned; universal cadence rules — daily standup, heartbeat cadence)
   - `docs/new-projectsteps.md.tmpl` (orchestrator-owned; mirrors PR #1008's new-projectsteps.md; becomes the canonical post-Sprint-29 version per S29-015)
   - `docs/peer-poke-spec.md.tmpl` (orchestrator-owned; universal peer-poke communication spec per ADR-0033; CRITICAL)
   - `docs/tech-debt.md.tmpl` (architect-owned; tech-debt ledger skeleton, mirror of AtilCalculator's docs/tech-debt.md)
- **AC2** — Each file has minimal but functional content (not empty stubs). `USER-GUIDE.md.tmpl` has ≥ 1-2 sections minimum (placeholder for project customization).
- **AC3** — `dev-studio-init.sh` updated to render all 6 `.tmpl` files → `.md` at downstream project init (sister-pattern to S29-016 + S29-018 render paths).
- **AC4** — Multi-lane co-CC per lane ownership matrix (CLAUDE.md §File ownership matrix):
   - PM on `USER-GUIDE.md.tmpl`
   - orchestrator on `glossary.md.tmpl` + `index-cadence.md.tmpl` + `new-projectsteps.md.tmpl` + `peer-poke-spec.md.tmpl`
   - architect on `tech-debt.md.tmpl`
- **AC5** — d-test (admin-level): file-existence + content-shape (≥ 1 section heading per file per AC2 minimum).

## Out of scope

- Porting `docs/glossary.md` content fully (orchestrator lane — defer to Sprint 30+ glossary refresh).
- Per-project customization of USER-GUIDE (this story ships the skeleton; content is project-specific).

## Open questions

- [ ] **Architect**: confirm `docs/tech-debt.md.tmpl` content scope (full mirror of AtilCalculator's `docs/tech-debt.md`, or skeleton with key sections only — sections: Overview, Active, Closed-by-Sprint).
- [ ] **Orchestrator**: confirm `peer-poke-spec.md.tmpl` content matches the current `peer-poke-spec.md` at AtilCalculator (sister-pattern ADR-0033 cross-check).

## Dependencies

- **Upstream:** S29-016 (render path doctrine — `dev-studio-init.sh` updates cascade); S29-018 (sub-dir siblings); ADR-0033 (peer-poke spec is the source for `peer-poke-spec.md.tmpl`).
- **Downstream:** Sprint 30+ doc adoption + glossary refresh; downstream-project operator onboarding.

## Metrics of success

- **Leading:** d-test (AC5) GREEN in CI.
- **Leading:** downstream dry-run shows all 6 `.md` files rendered at init.
- **Leading:** PM lane co-review of `USER-GUIDE.md.tmpl` ratified; orchestrator lane co-review of `peer-poke-spec.md.tmpl` ratified (sister-pattern match).

## Sizing

- **Hint:** M effort (6 files + multi-lane review).
- **Final:** M (per plan.md §3 table; multi-lane coordination is the bulk).

## Lane

- **Author:** architect (template render doctrine + multi-lane coordination + content-shape consistency)
- **Reviewer:** architect (9-Lens per ADR-0045; sister-pattern to AtilCalculator's 12 top-level docs)
- **Co-CC:** orchestrator (5 of 6 files: glossary/index-cadence/new-projectsteps/peer-poke-spec — all docs/ lane content); PM (`USER-GUIDE.md.tmpl` only — PM-owned content per file ownership matrix)
- **Tester:** tester (d-test per ADR-0044; admin-level per AC5)
- **Owner squash gate:** per ADR-0031 (template-load-bearing)

## Sprint 29 Context

- **Epic:** E6 — Doc Structure Portage (Wave 2B parallel)
- **Wave:** Wave 2B (parallel with Wave 2C)
- **Source-of-truth:** `docs/sprints/sprint-29/00-plan.md` §3 S29-019

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
