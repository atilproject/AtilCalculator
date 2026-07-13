# STORY-S29-005: scripts/verify-portage.sh — concrete portage-gap detection recipe

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-005`; PM canonical ID = `STORY-S29-005`
> **Origin**: Sprint 29 W1 grooming, surfaced by orchestrator dual-channel wake 2026-07-13T11:31:41+03:00 (cycle ~1193)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.S29-005 (commit `56e42da`, 2026-07-13)

## User Story
As **the orchestrator running Sprint 29 verification (S29-014)**,
I want **`scripts/verify-portage.sh` in the dev-studio-template repo that renders the template to a fresh private repo + diffs against AtilCalculator + cleans up + emits a concrete gap report**,
So that **S29-014 can re-run this script at sprint-end and the audit doc's "60% portage gap" claim can be re-verified (or falsified) with concrete numbers, not estimates**.

## Why now
Sprint 29 W1 (script authoring; the consumer S29-014 runs it at sprint-end). Sprint 28 audit §4.6 explicitly proposed this verification recipe but did NOT execute it (would need owner-ratified Actions billing + scratch repo). Owner ratification pending — script itself is uncontroversial; the EXECUTION creates + deletes a real repo.

## Acceptance Criteria
- **AC1** — `scripts/verify-portage.sh` exists in dev-studio-template repo with these steps:
  1. Render template via `new-project.sh` to a scratch private repo (`/tmp/<scratch-name>` or similar)
  2. Run `scripts/tests/e2e-pilot.sh` in the scratch repo
  3. Diff `scripts/`, `.github/workflows/`, `docs/decisions/`, `.claude/` between scratch repo and AtilCalculator reference
  4. Capture diff output to `verify-portage-report.txt`
  5. Cleanup: `rm -rf` scratch + `gh repo delete` scratch repo
- **AC2** — Script is idempotent (re-runs without corrupting state; cleanup is bulletproof).
- **AC3** — Script has dry-run mode (`--dry-run` flag) that prints what it WOULD do without creating real repos or running diffs.
- **AC4** — Script output format is parseable: emits machine-readable JSON summary at end (gap count by category: ADRs, d-tests, scripts, workflows) + human-readable text report.
- **AC5** — d-test (new, ≥5 TCs per ADR-0049): `scripts/tests/s29-005-verify-portage.sh` validates script syntax, dry-run mode, JSON output schema, cleanup idempotency, error-handling on missing dependencies.
- **AC6** — Script README block (inline `## verify-portage` comment in script header) documents: prerequisites (gh auth, jq, PROJECT_TOKEN optional), expected output format, exit codes, owner-ratification requirement for full execution.

## Out of scope
- Auto-executing verify-portage.sh (orchestrator runs it manually in S29-014)
- Modifying the audit doc (S29-015 handles doc updates)
- Adding CI integration (out of scope — script is operator-driven)

## Open questions
- [ ] Should the scratch repo use --private or --public? --private better simulates production, --public avoids Actions billing concerns → owner: developer
- [ ] Should the diff include only files in AtilCalculator but NOT in scratch (forward-port gap) OR also files in scratch but NOT in AtilCalculator (template-overreach)? → owner: developer

## Mockups / references
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.6 (proposed recipe, pseudo-code)
- AtilCalculator `scripts/dev-studio-init.sh` (sister-pattern: init script)
- AtilCalculator `scripts/tests/e2e-pilot.sh` (sister-pattern: smoke test)

## Dependencies
- **Upstream**: None (script authoring is independent)
- **Downstream**: S29-014 (orchestrator runs script at sprint-end, captures output to `docs/sprints/sprint-29/01-portage-verify.md`)

## Metrics of success
- **Leading**: PR merged to template main, AC1-AC6 met, d-test green
- **Lagging**: S29-014 execution reports ≤ 5% residual gap (per Sprint 29 success criterion)

## Cross-references
- Issue #1011 (Sprint 29 KICKOFF)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-005, §6.3 (success criterion: ≤ 5% residual)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.6 (recipe source)
- ADR-0049 (d-test framework ≥5 TCs)
- Sister-pattern: dev-studio-init.sh (init), e2e-pilot.sh (smoke)