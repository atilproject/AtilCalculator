# STORY-S29-001: Migrate 7 template stock workflows to self-hosted 4-tuple

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-001`; PM canonical ID = `STORY-S29-001`
> **Origin**: Sprint 29 W1 grooming, surfaced by orchestrator dual-channel wake 2026-07-13T11:31:41+03:00 (cycle ~1193)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.S29-001 (commit `56e42da`, 2026-07-13)

## User Story
As **a downstream project owner who wants to bootstrap a private repo on dev-studio-template without burning Actions-minutes**,
I want **each of the 7 stock template workflows (`ai-pr-review.yml`, `ci.yml`, `cross-repo-close.yml`, `label-check.yml`, `label-cleanup.yml`, `secret-canary.yml`, `status-label-to-board.yml`) to declare `runs-on: [self-hosted, Linux, X64, atilproject]`**,
So that **private repos run CI on self-hosted runners (zero Actions-minutes burn), matching AtilCalculator's 11/11 self-hosted pattern**.

## Why now
Sprint 29 W1 (load-bearing critical per owner directive #5). Sprint 28 audit §5.2 confirmed 7/8 template workflows still on `ubuntu-latest` — private repos would burn free-tier Actions minutes. S29-001 must land BEFORE S29-013 (launcher auto-apply 4-tuple) and BEFORE S29-007 (d-test ports need self-hosted runner reference). Sister-pattern: AtilCalculator's `.github/workflows/` (all 11 self-hosted via Sprint 27 priority migration).

## Acceptance Criteria
- **AC1** — For each of `{ai-pr-review.yml, ci.yml (lint-and-test + conventional-commits jobs), cross-repo-close.yml, label-check.yml, label-cleanup.yml, secret-canary.yml, status-label-to-board.yml}`, the `runs-on:` line reads exactly `runs-on: [self-hosted, Linux, X64, atilproject]` (4-tuple, not 3-tuple, not string).
- **AC2** — `deploy.yml.tmpl` keeps its existing `runs-on: self-hosted` (no regression; current behavior preserved).
- **AC3** — `grep -E "runs-on:" .github/workflows/ | sort -u` returns exactly 2 distinct values: `runs-on: [self-hosted, Linux, X64, atilproject]` and `runs-on: self-hosted`.
- **AC4** — At least 1 sample workflow opens a draft PR; CI fires on self-hosted runner (verify Actions run shows `runner.name: github-runner-vm*`); no `runs-on: ubuntu-latest` job executed.
- **AC5** — d-test (new, per ADR-0049 ≥5 TCs): `scripts/tests/s29-001-workflow-self-hosted.sh` validates 4-tuple on every `.github/workflows/*.yml` (NOT `*.tmpl`).
- **AC6** — Concurrency groups + secrets references unchanged (only `runs-on:` line modified, nothing else).
- **AC7** — Backward-compat note added to template README: "Self-hosted runner label requirements: `[self-hosted, Linux, X64, atilproject]`. Register with `./config.sh --labels self-hosted,Linux,X64,atilproject ...`."

## Out of scope
- Migrating workflows outside the 7 stock templates (new workflows from S29-010 are separate story)
- Adding new self-hosted runners to org (already 8 online per Sprint 28 audit §5.4)
- Changing the `deploy.yml.tmpl` runs-on (preserve existing `runs-on: self-hosted` per AC2)

## Open questions
- [ ] Are any template workflows intentionally on `ubuntu-latest` for security policy reasons (e.g., label-check.yml)? → owner: architect (per audit §5.5 bilmiyorum)
- [ ] Self-hosted runner registration documentation location: template README vs separate ops doc? → owner: architect

## Mockups / references
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §5.2 (audit evidence)
- AtilCalculator `.github/workflows/` (11/11 self-hosted — sister-pattern)
- ADR-0030 (self-hosted-runner LAN deploy doctrine)

## Dependencies
- **Upstream**: None (independent)
- **Downstream**: S29-007 (d-test ports cite self-hosted runner), S29-013 (launcher auto-applies 4-tuple), S29-010 (new workflows inherit 4-tuple)

## Metrics of success
- **Leading**: PR merged to template main, AC1-AC7 met, d-test green on self-hosted runner
- **Lagging**: Verification command `grep -L "runs-on: \[self-hosted, Linux, X64, atilproject\]" .github/workflows/*.yml | grep -v .tmpl` returns empty

## Cross-references
- Issue #1011 (Sprint 29 KICKOFF)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-001
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §5.2, §5.4, §6.2 B-03
- ADR-0030 (self-hosted-runner LAN deploy)
- ADR-0049 (d-test framework ≥5 TCs)
- Sister-pattern: AtilCalculator Sprint 27 priority self-hosted migration