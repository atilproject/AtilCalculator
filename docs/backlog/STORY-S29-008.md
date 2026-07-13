# STORY-S29-008: Forward-port 5-7 missing top-level scripts (Phase 2 corrected count)

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-008`; PM canonical ID = `STORY-S29-008`; Issue #1033
> **Origin**: Sprint 29 W2 grooming, surfaced by Issue #1030 (Wave 2 dispatch)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.Wave 2 / S29-008

## User Story
As **a downstream project owner who wants full agent workflow automation on day-1**,
I want **5-7 universal top-level scripts ported as a single batched PR (audit-project-refs.sh, cross-repo-scan.sh, proactive-board-scan.sh + 4 others) with AtilCalculator-specific paths parameterized to `atilproject` org**,
So that **scripts-directory parity rises from 33 → 38-40 (≥90% parity) and downstream projects inherit the agent hygiene + cross-repo + board-proactive automation that AtilCalculator developed over 28 sprints.**

## Why now
Phase 2 expansion per arch v3 audit §G (S29-008 revision). Orchestrator's original count understated (claimed "38+", corrected to 43 per arch v3 §B-2). Template scripts count = 33. Per plan §3: "Missing universal: `agent-watch-verdicts.sh`, `audit-project-refs.sh`, `cross-repo-scan.sh`, `lint-notify-invocations.sh`, `proactive-board-scan.sh`, `strip-cascade-labels.sh`, `init-template-repo.sh`."

## Acceptance Criteria (per plan §3.S29-008, Phase 2 expansion)

- **AC1** — **(corrected per arch v3 §G):** 5-7 universal scripts ported as a single PR. **Explicit list**: `audit-project-refs.sh`, `cross-repo-scan.sh`, `proactive-board-scan.sh` + 4 others from orchestrator's original S29-008 list (`agent-watch-verdicts.sh`, `lint-notify-invocations.sh`, `strip-cascade-labels.sh`, `init-template-repo.sh`).
- **AC2** — Project-specific scripts (`run-server.sh`, `ops/apply-vm-hardening.sh`) NOT ported (stay in AtilCalculator; calc-engine / vm-specific).
- **AC3** — Each ported script has any AtilCalculator-specific paths/IDs parameterized (or pointed at `atilproject` org as canonical).
- **AC4** — d-test (per-port, ≥3 TCs each per ADR-0049): syntax-check + help-text output + idempotency check.

## Done means
5-7 universal scripts ported; per-script d-tests green; scripts-directory parity ≥90% (33 → 38-40).

## Out of scope
- Porting scripts with calc-engine-specific logic (run-server.sh, apply-vm-hardening.sh stay AtilCalc)
- Refactoring existing template scripts (port-only; no edits to existing 33)
- Adding new scripts unique to template (port-only)

## Open questions
- [ ] **Path parameterization strategy**: Glob/regex replacement of `atilcan65` → `atilproject` in each script, or runtime `${ORG}` env var with default? → owner: developer (sister-pattern: AtilCalculator d095 `post-org-migration-clone-urls.sh`)
- [ ] **Credential secrets handling**: Some scripts may need `PROJECT_TOKEN` or other secrets — token-mode handling similar to existing template scripts? → owner: developer
- [ ] **Idempotency check pattern for each script**: What constitutes "idempotent" for, e.g., `audit-project-refs.sh`? Read-only idempotent or re-runnable without state corruption? → owner: developer

## Mockups / references
- `docs/sprints/sprint-29/00-plan.md` §3 Wave 2 / S29-008 (4 ACs canonical)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.4 (Q2 scripts gap)
- arch v3 audit §B-2 Error 2 (orchestrator miscount 38+ → 43 corrected), §G S29-008 revision
- AtilCalculator `scripts/` (43 files; port-source 7)
- d095 `post-org-migration-clone-urls.sh` (path-parameterization sister-pattern)
- ADR-0049 (d-test framework ≥3 TCs baseline)

## Dependencies
- **Upstream**: None (independent scripts port)
- **Downstream**: S29-014 (verify-portage)

## Metrics of success
- **Leading**: 1 batched PR merged to template main; AC1-AC4 met; per-script d-test green
- **Lagging**: Scripts directory parity ≥90% (33 → 38-40); per-script idempotency verified

## Cross-references
- Issue #1033 (this story, opened cycle ~#1307)
- Issue #1030 (Wave 2 dispatch parent)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-008
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.4
- arch v3 audit (cmt 4955154223 @ 2026-07-13T06:42:02Z on PR #1008)
- ADR-0049 (d-test framework)
- Sister-pattern: d095 `post-org-migration-clone-urls.sh`
