# STORY-S29-014: Verify-portage execution against post-portage template

> **PM-authored from `docs/sprints/sprint-29/00-plan.md` §3 S29-014** (PM grooming cycle ~#1566 per [ORCH→PM] dual-channel wake 2026-07-14T21:03:32+03:00 carrying owner directive 21:02+03).
> **Sprint 29 sizing:** S effort (run script + read output). Sister-pattern to S29-005 (recipe script authoring).

## User Story

As **the sprint-closing owner**,
I want **the Sprint 28 audit doc's portage gap to be measured at ≤ 5% residual AFTER Sprint 29 closes**,
So that **the carry-over to Sprint 30+ is bounded and the template repro for downstream projects is empirically validated**.

## Why now

The Sprint 28 audit doc claims a ~60% portage gap (template missing many AtilCalculator assets). Without measurement, the gap-closing work this sprint cannot be ratified and Sprint 30+ may inherit unknown gap content. Measurement closes the feedback loop and produces a defensible "Sprint 29 done" definition.

## Acceptance Criteria

- **AC1** — Run `bash scripts/verify-portage.sh` (the script from S29-005) end-to-end against the post-portage template at template HEAD.
- **AC2** — Capture the output diff verbatim into `docs/sprints/sprint-29/01-portage-verify.md` (machine-readable + human-narrative sections; mirror S29-005's --machine-readable-json contract).
- **AC3** — Gap report shows ≤ 5% residual (≤ 5 ADRs + ≤ 5 d-tests + ≤ 5 scripts missing per the report). If > 5%, scope-violation detected → owner escalation + follow-up stories for Sprint 30+ (per architect audit protocol).
- **AC4** — Owner ratifies the verification report before Sprint 29 close (per ADR-0031 owner-merge-gate; ratification comment on the report doc).
- **AC5** — `docs/backlog/` updated with the gap items as TBD stories if residual > 0% (cannot exit Sprint 29 with un-tracked carry-over).

## Out of scope

- Comparing to non-template repos (AtilCalculator sister, dev-studio-launcher sister) — those are Sprint 30+ sister-pattern.
- Auto-fixing found gaps (script reports; fix is separate work via new stories or in-sprint patches).

## Open questions

- [ ] **Owner**: ratify the ≤ 5% threshold or set different (architect suggested 5% as "stable" per Sprint 28 audit §4.6).
- [ ] **Architect**: should the script be portable enough to run on dev-studio-launcher sister repo (deferred to Sprint 30+) or scoped strictly to template?

## Dependencies

- **Upstream:** S29-005 (script, DONE per Issue #1011), S29-006..S29-013 (all gap-closing stories must land first for the measurement to be meaningful).
- **Downstream:** Sprint 29 close ceremony (cannot close without this verification); Sprint 30 backlog (residual gap stories).

## Metrics of success

- **Leading:** `verify-portage.sh` exits 0 with `residual_pct <= 5.0` in machine-readable JSON.
- **Leading:** owner-ratification comment timestamped on `docs/sprints/sprint-29/01-portage-verify.md`.
- **Lagging:** residual gap items (> 5%) are all tracked in Sprint 30+ backlog with STORY IDs before Sprint 29 close ceremony.

## Sizing

- **Hint:** S effort (run script + read output).
- **Final:** S (per plan.md §3 table).

## Lane

- **Author:** developer (script execution + diff capture; mirrors S29-005 lane)
- **Reviewer:** architect (gap report ratification; 9-Lens per ADR-0045)
- **Tester:** developer-self (script verification)
- **PM:** @product-manager (story author + Sprint 29 close ceremony facilitation)

## Sprint 29 Context

- **Epic:** E3 — Verification
- **Wave:** Wave 3 (final week)
- **Source-of-truth:** `docs/sprints/sprint-29/00-plan.md` §3 S29-014

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
