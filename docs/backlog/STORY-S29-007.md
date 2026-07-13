# STORY-S29-007: Forward-port 80+ universal d-tests (ADR-anchored)

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-007`; PM canonical ID = `STORY-S29-007`; Issue #1032
> **Origin**: Sprint 29 W2 grooming, surfaced by Issue #1030 (Wave 2 dispatch) at 2026-07-13T13:50:55Z
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.Wave 2 / S29-007

## User Story
As **a downstream project owner who wants behavioral coverage on day-1**,
I want **~80+ universal d-tests ported from AtilCalculator's `scripts/tests/` (131 files) to template's `scripts/tests/` (21 files), with d-test ID uniqueness preserved per ADR-0055 and each test running green on self-hosted runner**,
So that **template ships with full behavioral-coverage parity (~110 d-test gap closed to ≤10 residual) and downstream projects inherit the ADR-anchored test suite that ensures 4-cat invariant + d-test framework + sprint flow + cross-repo discipline.**

## Why now
**AFTER S29-006 per owner directive #2** (ADR FIRST — d-tests cite ADRs as their reference per ADR-0055 §Cadence Rule 1 atomic). Cannot port tests before ADRs land. Sprint 29 close depends on this (per §6 sprint DoD + §6.3 success criterion: ≥95% parity).

## Acceptance Criteria (per plan §3.S29-007)

- **AC1** — d-test ported in 5-6 themed PRs (themes suggested: agent-watch-behavioral / verdict-detection / cross-repo / label-invariant / issue-mirror / sprint-flow).
- **AC2** — Each ported d-test runs green on self-hosted runner (post-S29-001 migration to `runs-on: [self-hosted, Linux, X64, atilproject]`).
- **AC3** — d-test ID uniqueness preserved (no collisions with template's existing 21 IDs, per ADR-0055).
- **AC4** — `scripts/tests/INDEX.md` regenerated with both AtilCalculator-unique and template-unique d-tests visible.
- **AC5** — `bash scripts/tests/e2e-pilot.sh` exits 0 post-portage; `bash scripts/tests/faz5-smoke.sh` exits 0; `bash scripts/tests/state-schema-smoke.sh` exits 0.
- **AC6** — Sister-pattern: each d-test maintains ≥3 TCs (hygiene-only docs PRs) or ≥5 TCs (behavioral workflow PRs) per ADR-0049.

## Done means
~80+ d-tests ported; INDEX parity ≥95%; e2e-pilot + faz5-smoke + state-schema-smoke green. Audit doc §4.3 "110 missing" count drops to ≤10.

## Out of scope
- Adding new d-tests unique to template (port-only; no new behavioral coverage in this story)
- Performance tuning (d-test latency is not a Sprint 29 metric)
- CI integration in template (handled by S29-010 workflow port)

## Open questions
- [ ] **Which 80+ d-tests are universal vs project-specific?** Per arch v3 audit, ~80 universal + ~25-30 project-specific stay. → owner: developer (filter list)
- [ ] **d-test ADR reference validation**: For d-tests that cite ADRs (per ADR-0055 §Cadence Rule 1 atomic), how to detect stale references if S29-006 hasn't landed yet? → owner: developer + architect (gating dependency — S29-007 must run AFTER S29-006 PRs land)
- [ ] **Self-hosted runner reference test pattern**: Each ported d-test must run on self-hosted per AC2 — what's the canonical test pattern? → owner: developer (sister-pattern: AtilCalculator d-tests already passed self-hosted in Sprint 27)

## Mockups / references
- `docs/sprints/sprint-29/00-plan.md` §3 Wave 2 / S29-007 (6 ACs canonical)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.3 (Q2 d-test gap)
- AtilCalculator `scripts/tests/` (131 files; port-source ~80)
- ADR-0049 (d-test framework ≥5 TCs baseline)
- ADR-0055 (d-test ID uniqueness, sister-pattern)
- ADR-0055 §Cadence Rule 1 atomic (d-test ADR references)

## Dependencies
- **Upstream**: S29-006 (ADR FIRST — d-test ADR references must point at ported ADRs per ADR-0055 §Cadence Rule 1; owner directive #2)
- **Downstream**: S29-014 (verify-portage) — d-tests enable the verification

## Metrics of success
- **Leading**: 5-6 themed PRs merged to template main; AC1-AC6 met; all ported d-tests pass on self-hosted runner
- **Lagging**: Audit doc §4.3 "110 missing" → ≤10 residual post-portage; e2e-pilot + faz5-smoke + state-schema-smoke green; d-test INDEX parity ≥95%

## Cross-references
- Issue #1032 (this story, opened cycle ~#1307)
- Issue #1030 (Wave 2 dispatch parent)
- Issue #1031 (S29-006 — upstream blocker)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-007, §6.3 (success criterion)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.3 (audit source)
- ADR-0049 (d-test framework), ADR-0055 (d-test ID uniqueness + §Cadence Rule 1 atomic)
- Sister-pattern: AtilCalculator `scripts/tests/` (131 files; SPRT-027 d-test framework landed there)
