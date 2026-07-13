# STORY-S29-006: Forward-port 40+ universal ADRs + 10-12 amendments in 6 families

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-006`; PM canonical ID = `STORY-S29-006`; Issue #1031
> **Origin**: Sprint 29 W2 grooming, surfaced by Issue #1030 ([Sprint 29] Wave 1 closed — Wave 2 dispatch ready) at 2026-07-13T13:50:55Z (cycle ~#1306, post-Wave-1-closeout)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.Wave 2 / S29-006 (commit `fed3098`, 2026-07-13 merged via PR #1021 = sister design contract)

## User Story
As **a downstream project owner who wants canonical doctrine on day-1**,
I want **~40+ universal ADRs ported from AtilCalculator's `docs/decisions/` (74 entries) to template's `docs/decisions/` (16 entries), including 10-12 amendments across 6 universal ID families per ADR-0055 §Cadence Rule 1 atomic**,
So that **template ships with full doctrine parity (~95% coverage) and downstream projects inherit ADR-anchored references for d-test ports, workflow docs, and agent lane discipline — without cherry-picking from AtilCalculator piecemeal**.

## Why now
Sprint 29 W2 (Wave 2 dispatch — issue #1030). **ADR FIRST per owner directive #2** — S29-006 lands BEFORE S29-007 (d-test ports cite ADRs as their ADR-anchored reference per ADR-0055 §Cadence Rule 1). Load-bearing per Phase 2 owner directive #8 (10-12 amendments in 6 ID families expansion). Sprint 29 close depends on this (per §6 sprint DoD #5).

## Acceptance Criteria (per plan §3.S29-006)

- **AC1** — Diff `docs/decisions/` template HEAD vs AtilCalculator main; produce list of missing ADRs categorized as "universal port-worthy" (~40) vs "project-specific stay". Output: `docs/sprints/sprint-29/s29-006-adr-diff.md`.
- **AC2** — Universal ADRs ported in 3-4 themed PRs (themes suggested: agent-and-lane doctrine / verdict-and-board / cross-repo-and-runner / d-test-and-quality-gates). Each PR scoped to a single theme.
- **AC3** — Each ported ADR has its frontmatter updated to reflect template-repo provenance (cross-repo ADR references updated per ADR-0045 §Lens (j) — auto-generated file refs + live-state verification).
- **AC4** — `docs/decisions/INDEX.md` regenerated with both AtilCalculator-unique and template-unique ADRs visible (post-portage ADRs from AtilCalculator live in template, listed in template INDEX).
- **AC5** — d-test (new, ≥5 TCs per ADR-0049): `scripts/tests/s29-006-adr-port-parity.sh` asserts each ported ADR resolves its cross-references (no broken `ADR-XXXX` links).
- **AC6** — ADR-0024 namespace collision resolved: template's existing ADR-0024 (stale-verdict-watchdog-schema) + 2 amendments from AtilCalculator (auto-verdict-by-hook + stale-verdict-supersede) = 3 ADR-0024-* files matching AtilCalculator structure.
- **AC7** — **(Phase 2 expansion, owner directive #8):** **ADR amendments ported** from AtilCalculator for 6 universal ID families with multiple entries per ADR-0055 §Cadence Rule 1 atomic:
  - **0002**: autonomy-loop + amendment-1-stale-verdict-filter-scope (2 entries)
  - **0024**: stale-verdict-watchdog-schema + auto-verdict-by-hook + stale-verdict-supersede (3 entries)
  - **0038**: auto-claim + watcher-enforcement + workstream-awareness (3 entries; new family for template)
  - **0048**: status-ready-auto-add + 3 amendments (4 entries; new family for template)
  - **0049**: d-test framework + subcheck-k amendment (2 entries)
  - **0057**: closes-anchor + closes-vs-refs-intent amendment (2 entries)

  **Count reconciliation note (per orchestrator v3 verdict §H-4):** arch v3 audit said "12 amendment entries"; PM v3 verdict cross-check (REST `/contents/docs/decisions | jq | map | length`) shows 10. **Resolution:** S29-006 kickoff re-counts via fresh REST at execution time; AC7 commits to ≥10 amendment entries (upper bound 12 pending re-count). Per TD-016 silent-skip discipline, exact count deferred to kickoff.
- **AC8** — Sister-pattern post-mortem per d-test `d986-adr-index-uniqueness.sh`: no duplicate ADR numbers in template post-portage.

## Done means
~40+ ADRs + 10-12 amendments ported across 6 families; ADR INDEX parity ≥95%; d-test green. Audit doc §4.2 "58 missing" count drops to ≤5.

## Out of scope
- Adding new ADRs unique to template (port-only; no new doctrine in this story)
- Reorganizing existing template ADRs (0024 collision fix is the only edit on existing entries)
- Atomic-mass port to AtilCalculator's INDEX (template INDEX gets regenerated only)

## Open questions
- [ ] **Pure ADR vs annotated tag amendments**: For 6 ID families with multiple entries, should each entry be a separate file (`ADR-XXXX-<slug>.md`) or a sub-section in the main ADR file? Per ADR-0055 current convention = separate files. → owner: architect (confirm format holds)
- [ ] **ADR-0024 namespace collision resolution**: Should the original (template-side) ADR-0024 be renamed (e.g. `ADR-0024-template-original.md`) or kept as the canonical `ADR-0024-stale-verdict-watchdog-schema.md` matching AtilCalculator? → owner: architect
- [ ] **Cross-repo ADR ref update scope**: Which ADRs have cross-repo references that need updating (ACs AC3 + AC5)? Likely the 6 ID-family amendments have cross-repo references. → owner: architect

## Mockups / references
- `docs/sprints/sprint-29/00-plan.md` §3 Wave 2 / S29-006 (8 ACs canonical)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.2 (Q2 ADR gap)
- AtilCalculator `docs/decisions/INDEX.md` (74 entries; port-source ~40)
- ADR-0050 (load-bearing ADR doctrine)
- ADR-0045 §Lens (j) (auto-generated file refs + live-state verification)
- ADR-0055 §Cadence Rule 1 atomic (amendment porting discipline)
- ADRs from AtilCalculator amendments cluster (RETRO-024 #1027 ratifies this scope)

## Dependencies
- **Upstream**: None (ADR FIRST, independent)
- **Downstream**: S29-007 (d-test ports cite ADRs as their reference per ADR-0055 §Cadence Rule 1) → S29-014 (verify-portage)

## Metrics of success
- **Leading**: 3-4 themed PRs merged to template main; AC1-AC8 met; d-test `s29-006-adr-port-parity.sh` green on self-hosted runner
- **Lagging**: Audit doc §4.2 "58 missing" → ≤5 residual post-portage; ADR INDEX parity ≥95%

## Cross-references
- Issue #1031 (this story, opened cycle ~#1307)
- Issue #1030 (Wave 2 dispatch parent)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-006, §6.3 (success criterion ≤5)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.2 (audit source)
- ADR-0012 (4-cat invariant), ADR-0045 (9-Lens), ADR-0049 (d-test framework), ADR-0050 (load-bearing ADR), ADR-0055 §Cadence Rule 1 (amendment porting)
- Issue #1027 / RETRO-024 (4-cat-ratifies the silent-skip pattern that AC7-amendment-porting relies on)
- Sister-pattern: AtilCalculator ADR-0001 through ADR-0071 amendment lineage
