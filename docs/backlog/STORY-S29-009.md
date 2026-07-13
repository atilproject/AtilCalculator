# STORY-S29-009: Forward-port 3 missing scripts/ sub-dirs (kickoff/, post-squash/, pre-push/)

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-009`; PM canonical ID = `STORY-S29-009`; Issue #1034
> **Origin**: Sprint 29 W2 grooming, surfaced by Issue #1030 (Wave 2 dispatch)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.Wave 2 / S29-009

## User Story
As **a downstream project owner who wants full agent workflow on day-1**,
I want **3 missing scripts/ sub-dirs ported: `kickoff/` (5 agent txt files), `post-squash/` (cluster-lag-detector + label-hygiene), `pre-push/` (branch-base-check)**,
So that **downstream projects inherit the agent kickoff family + post-squash cleanup cluster + pre-push branch-base protection that AtilCalculator developed over 28 sprints.**

## Why now
Sprint 29 W2 (independent sub-dir port per plan §5). Template scripts/ currently has only top-level files + `tests/` + `install/`. Missing the agent kickoff family (5 txt files for orchestrator/PM/arch/dev/tester) + post-squash cleanup cluster + pre-push branch-base check.

## Acceptance Criteria (per plan §3.S29-009)

- **AC1** — 3 sub-dirs ported:
  - `kickoff/` — 5 agent txt files: orchestrator, PM, arch, dev, tester (agent-specific kickoff prompts)
  - `post-squash/` — `cluster-lag-detector.sh` + `label-hygiene.sh` (sister-pattern of AtilCalculator post-squash cluster)
  - `pre-push/` — `branch-base-check.sh` (per AtilCalculator CLAUDE.md §branch protection; pre-push hook pattern)
- **AC2** — AtilCalculator-specific `install/systemd/dev-studio-watcher@.service` NOT ported (template has its own systemd); AtilCalculator-specific `ops/` (vm-hardening) NOT ported.
- **AC3** — Each sub-dir's README (if any) updated to template-canonical language.

## Done means
Sub-dirs present in template; pre-push hook usable (per AtilCalculator CLAUDE.md §branch protection).

## Out of scope
- Renaming or re-architecting sub-dir layout (port-only; preserve AtilCalculator structure)
- Adding new scripts inside sub-dirs (port-only)
- Systemd integration (template has its own systemd; AC2 forbids porting AtilCalculator's systemd file)

## Open questions
- [ ] **kickoff/ txt file content**: Each agent txt file has kickoff prompts specific to that role (orchestrator runs first, etc.). Should they be 1:1 copied from AtilCalculator or adapted to template-canonical agent-roles? → owner: orchestrator + PM
- [ ] **pre-push/ hook installation**: How does the template install the pre-push hook on downstream init? Via `dev-studio-init.sh` or manual? → owner: developer
- [ ] **post-squash/ cluster scope**: `cluster-lag-detector.sh` monitors labels across repos; does template need to mirror the cluster config (multi-repo state)? → owner: developer + orchestrator

## Mockups / references
- `docs/sprints/sprint-29/00-plan.md` §3 Wave 2 / S29-009 (3 ACs canonical)
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.4 (Q2 sub-dir gap)
- AtilCalculator `scripts/kickoff/`, `scripts/post-squash/`, `scripts/pre-push/` (port-source)
- AtilCalculator CLAUDE.md §branch protection (pre-push doctrine)

## Dependencies
- **Upstream**: None (independent sub-dir port)
- **Downstream**: S29-014 (verify-portage)

## Metrics of success
- **Leading**: 1 PR merged to template main; AC1-AC3 met; kickoff txt files render in `dev-studio-init.sh` (if applicable)
- **Lagging**: Sub-dir coverage parity (template 5 sub-dirs → 8 sub-dirs post-portage)

## Cross-references
- Issue #1034 (this story, opened cycle ~#1307)
- Issue #1030 (Wave 2 dispatch parent)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-009
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.4
- AtilCalculator CLAUDE.md §branch protection
- Sister-pattern: AtilCalculator `scripts/kickoff/`, `scripts/post-squash/`, `scripts/pre-push/`
