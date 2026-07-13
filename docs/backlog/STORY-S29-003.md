# STORY-S29-003: Update launcher + README URLs (atilcan65 → atilproject)

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-003`; PM canonical ID = `STORY-S29-003`
> **Origin**: Sprint 29 W1 grooming, surfaced by orchestrator dual-channel wake 2026-07-13T11:31:41+03:00 (cycle ~1193)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.S29-003 (commit `56e42da`, 2026-07-13)

## User Story
As **a downstream project owner who reads the launcher README and copy-pastes install commands**,
I want **all `atilcan65/dev-studio-*` URLs in the launcher (`new-project.sh` + `README.md`) replaced with `atilproject/dev-studio-*` URLs**,
So that **the README points at the new canonical org (matches Sprint 28 org-migration precedent) and avoids confusion between legacy `atilcan65` and current `atilproject` namespaces**.

## Why now
Sprint 29 W1 (trivial hygiene, XS effort). Sprint 28 audit §7.2 identified 6 stale `atilcan65` URLs in launcher README + 1 in `new-project.sh` line 19. Both function correctly via GitHub alias but document-hygiene needs update. Sister-pattern: AtilCalculator `d095 post-org-migration-clone-urls.sh` (post-org-migration URL hygiene precedent).

## Acceptance Criteria
- **AC1** — `new-project.sh` line 19 changes to `TEMPLATE_REPO="atilproject/dev-studio-template"` + `DEFAULT_OWNER="atilproject"`.
- **AC2** — `new-project.sh --help` output reflects `atilproject` defaults.
- **AC3** — Launcher README replaces all `atilcan65/dev-studio-template` and `atilcan65/dev-studio-launcher` URLs with `atilproject/...` URLs.
- **AC4** — ADR-0016 link in README resolves to new canonical (atilproject) URL.
- **AC5** — d-test (new, ≥3 TCs): `scripts/tests/s29-003-url-hygiene.sh` greps launcher for any residual `atilcan65` references, fails on match.

## Out of scope
- Renaming the launcher repo itself (atilproject/dev-studio-launcher is already canonical)
- Touching AtilCalculator URLs (AtilCalculator's own clone URLs already migrated per Sprint 28 d095)
- Updating any docs/ sub-pages that reference atilcan65 (deferred to Sprint 30+ doc sweep)

## Open questions
- [ ] Should launcher log a deprecation warning if user invokes with old `atilcan65/dev-studio-template` URL explicitly? → owner: developer (backward-compat consideration)
- [ ] README "Setup (one-time)" git clone URL: stay backward-compat or hard-cut? → owner: developer

## Mockups / references
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §7.2 (stale references table)
- AtilCalculator `scripts/tests/d095-post-org-migration-clone-urls.sh` (sister-pattern)
- Launcher file: `atilproject/dev-studio-launcher/new-project.sh` (line 19 hardcoded)

## Dependencies
- **Upstream**: None (URL hygiene is independent)
- **Downstream**: None (cosmetic change)

## Metrics of success
- **Leading**: PR merged to launcher main, AC1-AC5 met, d-test green
- **Lagging**: Zero `atilcan65` references remain in launcher (verifiable via `grep -r atilcan65 atilproject/dev-studio-launcher/`)

## Cross-references
- Issue #1011 (Sprint 29 KICKOFF)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-003
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §7.2, §6.2 B-04, B-05
- d095 (sister-pattern: post-org-migration clone URL hygiene)
- ADR-0016 (public-by-default visibility)