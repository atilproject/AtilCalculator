# STORY-S29-011: Verify ISSUE_TEMPLATE content parity + ADR-0012 4-cat compliance (REFRAMED XS per owner #7)

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-011`; PM canonical ID = `STORY-S29-011`; Issue #1036
> **Origin**: Sprint 29 W2 grooming, surfaced by Issue #1030 (Wave 2 dispatch)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.Wave 2B / S29-011 (REFRAMED per Phase 2 owner directive #7)

## User Story
As **a downstream project owner who wants issue-template parity on day-1**,
I want **content-parity verification of all 6 ISSUE_TEMPLATEs (agent-stall.yml, bug.yml, config.yml.tmpl, feature-request.yml, incident.yml, vision-intake.yml) + ADR-0012 4-cat section compliance validation + drift capture**,
So that **drift between AtilCalculator issue templates and template defaults is captured explicitly (drift report) + drift-prevention is enforced at template level (4-cat section compliance) without claiming to "port 7 templates" (which the original S29-011 implied incorrectly).**

## Why now
Orchestrator miscount correction (claimed 0/7 ISSUE_TEMPLATEs in template, actual = 6/6). **Phase 2 owner directive #7** reframed S29-011 from `port 7 templates (S)` → `content parity + 4-cat compliance (XS)`. Arch v3 audit §B Error 1 captured the original miscount. Reframing prevents wasted effort on a non-gap.

## Acceptance Criteria (per plan §3.S29-011, REFRAMED)

- **AC1** — Content parity verification for all 6 ISSUE_TEMPLATEs — diff `atilcan65/AtilCalculator/.github/ISSUE_TEMPLATE/*.yml` vs `atilproject/dev-studio-template/.github/ISSUE_TEMPLATE/*.yml` (and `*.tmpl` variants). Document drift in `docs/sprints/sprint-29/s29-011-template-drift.md`.
- **AC2** — Each template has ADR-0012 4-cat section (type/status/agent/cc checkboxes or pre-fills). Update templates that lack 4-cat section.
- **AC3** — d-test (new, ≥3 TCs per ADR-0049): validates each template YAML frontmatter + 4-cat section presence.
- **AC4** — **(Phase 2 reduction rationale):** Original S29-011 "port 7 templates" scope was based on orchestrator miscount; reframed to XS (content-parity + drift-prevention + 4-cat compliance). **No new template files created.**

## Done means
All 6 ISSUE_TEMPLATEs in template have content-parity with AtilCalculator + 4-cat label section compliance verified; d-test green; drift report captured.

## Out of scope
- Adding new templates (per AC4 — reframing forbids new template creation)
- Removing existing templates (drift-prevention, not template-cull)
- Renaming templates (template-canonical names preserved)

## Open questions
- [ ] **Drift report format**: `docs/sprints/sprint-29/s29-011-template-drift.md` — markdown table or full content-diff? Per AtilCalculator convention (RETRO-007 watchlist) = frontmatter-only diff (≤120 lines). → owner: PM (template format confirmation)
- [ ] **4-cat section format**: Checkboxes vs pre-fills — which convention holds for template? AtilCalculator templates use pre-fills + auto-label only on creation. → owner: developer + architect
- [ ] **d-test atomic-per-template or all-in-one**: 1 d-test per template (6 d-tests, ≥3 TCs each = 18 TCs total) or 1 d-test per template-batch (≥3 TCs each = 3 batches)? Per ADR-0049 ≥3 TCs baseline. → owner: tester

## Mockups / references
- `docs/sprints/sprint-29/00-plan.md` §3 Wave 2B / S29-011 (4 ACs canonical, REFRAMED)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §6.3 C-08 (Category C: gap-closing)
- arch v3 audit §B Error 1 (orchestrator miscount: claimed 0/7, actual 6/6)
- AtilCalculator `.github/ISSUE_TEMPLATE/` (6 templates)
- Template `.github/ISSUE_TEMPLATE/` (6 templates, same set)
- ADR-0012 (4-cat label set in templates)
- RETRO-007 watchlist (drift report format convention)

## Dependencies
- **Upstream**: None (independent content-parity check)
- **Downstream**: S29-014 (verify-portage)

## Metrics of success
- **Leading**: 1 PR merged to template main; AC1-AC4 met; d-test green; drift report published
- **Lagging**: All 6 ISSUE_TEMPLATEs have content-parity with AtilCalculator; 4-cat label section compliance verified per template

## Cross-references
- Issue #1036 (this story, opened cycle ~#1307)
- Issue #1030 (Wave 2 dispatch parent)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-011 (REFRAMED), §1.1 (Phase 2 owner #7)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §6.3 C-08
- arch v3 audit (cmt 4955154223 @ 2026-07-13T06:42:02Z on PR #1008) §B Error 1
- ADR-0012 (4-cat label set)
- RETRO-007 watchlist (drift report format)
- Sister-pattern: AtilCalculator `.github/ISSUE_TEMPLATE/` (6 templates)
