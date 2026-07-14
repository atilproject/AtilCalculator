# STORY-S29-017: Re-author template `.claude/CLAUDE.md.tmpl` + 5 soul `.md.tmpl` files

> **PM-authored from `docs/sprints/sprint-29/00-plan.md` §3 S29-017** (PM grooming cycle ~#1566 per [ORCH→PM] dual-channel wake 2026-07-14T21:03:32+03:00 carrying owner directive 21:02+03).
> **Sprint 29 sizing:** M effort (architect-authored content). Sister-pattern to ADR-0050 (load-bearing ADR/soul doctrine). Phase 2 #9 resolution: root `CLAUDE.md.tmpl` (newer, commit 737b846e, 2026-06-29) is canonical for `.claude/CLAUDE.md.tmpl` re-author.

## User Story

As **a downstream-project operator using the template**,
I want **the template's soul files (CLAUDE.md + 5 role soul files) to reflect Sprint 28 SOUL AMENDs (Issues #414, #430, #682 + ADR-0038 / ADR-0057 / ADR-0062/0063 etc.)**,
So that **I inherit current, not stale, doctrine — and my soul-coverage d-test passes**.

## Why now

Template `.claude/CLAUDE.md.tmpl` is ~2.3 KB behind AtilCalculator's root `CLAUDE.md.tmpl` (which is the canonical newer source per Phase 2 #9 resolution). Likely Sprint 28 SOUL AMENDs not yet templated. Soul files are load-bearing doctrine: stale doctrine in downstream projects means downstream agents operate on outdated patterns. Sister-pattern: orchestrator `.md.tmpl` may also drift from Sprint 28 SOUL AMENDs.

## Acceptance Criteria

- **AC1 (pre-work, orchestrator lane)** — Trace Sprint 27→28 SOUL AMEND lineage: produce Issue/PR list that added SOUL AMENDs to AtilCalculator's `.claude/*.md.tmpl` files. **Output:** `docs/sprints/sprint-29/s29-017-soul-amend-lineage.md` (executable item before S29-017 AC2).
- **AC2** — Re-author template `.claude/CLAUDE.md.tmpl` to mirror AtilCalculator root `CLAUDE.md.tmpl` (commit 737b846e, 2026-06-29) PLUS Sprint 28 SOUL AMENDs (per AC1 lineage). **Canonical source = root `CLAUDE.md.tmpl` per Phase 2 #9 "newer wins"**.
- **AC3** — Re-author 5 soul `.md.tmpl` files in template `.claude/agents/`:
   - `architect.md.tmpl` + Sprint 28 SOUL AMENDs (arch amendments — including arch 9-Lens per ADR-0045)
   - `developer.md.tmpl` + Sprint 28 SOUL AMENDs (dev dispatch discipline)
   - `orchestrator.md.tmpl` + Sprint 28 SOUL AMENDs (RETRO-018 W6 branch-ownership cross-check, Issue #414 §8 dispatch discipline, Issue #430 §Pre-verdict cross-check, Issue #682 §Post-verdict cross-watchdog)
   - `product-manager.md.tmpl` + Sprint 28 SOUL AMENDs (PM lane definition LOCKED since Sprint 13)
   - `tester.md.tmpl` + Sprint 28 SOUL AMENDs (TDD RED-first expansion)
- **AC4** — d-test (existing, re-run): `scripts/tests/soul-coverage.sh` (or equivalent) validates each soul file has the expected SOUL AMEND sections. Sister-pattern ADR-0055 (d-test ID uniqueness — re-run, not new ID).
- **AC5** — Sister-pattern: LSP-1 (load-bearing ADR/soul doctrine per ADR-0050). Content drift verification — git diff between AtilCalculator root `CLAUDE.md.tmpl` vs template `.claude/CLAUDE.md.tmpl` shows intentional (Sprint 28 SOUL AMEND additions), not stale.
- **AC6** — Document the "dual-path" reality in plan doc §E (post-Phase 2 #9 resolution): template `.claude/CLAUDE.md.tmpl` is the single canonical; AtilCalculator root `CLAUDE.md.tmpl` is also retained (for symlink-style init if downstream uses both).

## Out of scope

- Adding new SOUL AMENDs beyond Sprint 28's known set (deferred to Sprint 30+ amendments).
- Renaming any `.md.tmpl` files (file names are stable; only contents change).

## Open questions

- [ ] **Architect**: confirm canonical-source selection (root `CLAUDE.md.tmpl` vs `.claude/CLAUDE.md.tmpl`) for S29-017 AC2 — Phase 2 #9 says "newer wins", but downstream-project init flow needs clarity.
- [ ] **Orchestrator**: confirm AC1 lineage report completeness (covers Issues #414, #430, #682 + ADR-0038 / 0057 / 0062 / 0063 SOUL AMENDs) before triggering AC2 work.

## Dependencies

- **Upstream:** Sprint 28 SOUL AMEND lineage (Issues #414, #430, #682); ADRs -0038 / -0057 / -0062 / -0063; Phase 2 #9 dual-path resolution.
- **Downstream:** S29-015 AC5 (dual-path CLAUDE.md render references this story's re-authored content); Sprint 30+ sister-pattern docs re-renders.

## Metrics of success

- **Leading:** d-test (AC4) GREEN in CI on template repo.
- **Leading:** git diff AtilCalculator root `CLAUDE.md.tmpl` → template `.claude/CLAUDE.md.tmpl` shows only Sprint 28 SOUL AMEND additions (intentional, no stale drift).
- **Leading:** lineage report at `docs/sprints/sprint-29/s29-017-soul-amend-lineage.md` covers ≥ 4 Sprint 28 SOUL AMEND sources.

## Sizing

- **Hint:** M effort (architectural authorship; 6 file updates).
- **Final:** M (per plan.md §3 table; architectural content is the bulk).

## Lane

- **Author:** architect (architectural authorship + SOUL AMEND interpretation)
- **Reviewer:** architect (9-Lens per ADR-0045; ADR-0050 sister-pattern verification)
- **Co-owner:** orchestrator (AC1 lineage report + render path verification)
- **Tester:** tester (d-test per ADR-0044; soul-coverage re-run)
- **PM:** @product-manager (story author + Sprint 28 amendment history cross-check)

## Sprint 29 Context

- **Epic:** E5 — Soul Doctrine Closure (Wave 2C)
- **Wave:** Wave 2C (parallel with Wave 2B)
- **Source-of-truth:** `docs/sprints/sprint-29/00-plan.md` §3 S29-017

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
