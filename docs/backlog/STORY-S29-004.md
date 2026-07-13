# STORY-S29-004: Fix status-label-to-board.yml (disable OR create Projects v2 board)

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-004`; PM canonical ID = `STORY-S29-004`
> **Origin**: Sprint 29 W1 grooming, surfaced by orchestrator dual-channel wake 2026-07-13T11:31:41+03:00 (cycle ~1193)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.S29-004 (commit `56e42da`, 2026-07-13)

## User Story
As **a template owner who doesn't want CI noise from a perpetually-failing workflow**,
I want **the `status-label-to-board.yml` workflow on `dev-studio-template` to either (a) be disabled (since template has no Projects v2 board) OR (b) be configured with a real Projects v2 board**,
So that **the template repo's CI is 100% green (no false failures from a workflow that tries to mutate a non-existent board)**.

## Why now
Sprint 29 W1 (low-risk hygiene fix). Sprint 28 audit §3.1 evidence: template's own `status-label-to-board.yml` has been failing in CI history (2026-07-11 13:48:41Z, 13:48:40Z runs both FAIL). Root cause: workflow tries to push label updates to a non-existent Projects v2 board on template repo. Sister-pattern: AtilCalculator uses this workflow with a real board.

## Acceptance Criteria
- **AC1** — Decision made and documented: (a) disable workflow (option chosen if no board needed) OR (b) create Projects v2 board + configure workflow (option chosen if board needed). Decision recorded in PR description.
- **AC2** — If option (a) chosen: workflow file deleted OR `if: false` added; commit + push; CI run on next PR shows workflow NOT triggered (verified via Actions tab).
- **AC3** — If option (b) chosen: Projects v2 board created on template repo, board ID added to repo secret/variable, workflow configured, CI run on next PR shows workflow SUCCESS.
- **AC4** — d-test (new, ≥3 TCs): validates the workflow's effective behavior — if disabled, file absent OR has `if: false`; if active, references a valid board ID.
- **AC5** — Decision rationale captured in `docs/sprints/sprint-29/s29-004-decision-record.md` (or inline in PR description if brevity preferred).

## Out of scope
- Migrating status-label-to-board.yml from template to a different name (out of scope per audit §6.2 B-06)
- Creating a Projects v2 board on dev-studio-launcher (launcher doesn't use board)
- Changing AtilCalculator's workflow (AtilCalculator has a working board — no fix needed)

## Open questions
- [ ] (a) vs (b) decision: does template need a board for its own sprint tracking, or is this workflow purely for downstream-project compatibility? → owner: architect (lane owner)
- [ ] If (b) chosen: who maintains the template repo's board? → owner: architect

## Mockups / references
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §3.1 (CI failure table), §6.2 B-06
- AtilCalculator `.github/workflows/status-label-to-board.yml` (working reference)
- ADR-0013 (status-label → board sync doctrine)
- ADR-0014 (PROJECT_TOKEN PAT for board sync)

## Dependencies
- **Upstream**: None
- **Downstream**: None (orthogonal hygiene fix)

## Metrics of success
- **Leading**: PR merged, decision rationale captured, d-test green
- **Lagging**: Template's Actions tab shows 0 failures for status-label-to-board.yml (verifiable via Actions runs filtered by workflow name)

## Cross-references
- Issue #1011 (Sprint 29 KICKOFF)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-004
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §3.1, §6.2 B-06
- ADR-0013 (status-label → board sync)
- ADR-0014 (PROJECT_TOKEN PAT for board sync)