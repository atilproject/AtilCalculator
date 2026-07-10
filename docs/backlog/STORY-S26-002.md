# STORY-S26-002 (DRAFT): Canary mirror missing `.github/ISSUE_TEMPLATE/config.yml` (Issue #853)

## User Story

As **a developer maintaining the canary mirror (post-release template health-check at atiltestweb) whose canary health check relies on the full `.github/ISSUE_TEMPLATE/` config surface**,
I want **`canary` mirror to provision `.github/ISSUE_TEMPLATE/config.yml` so the canary repo mirrors the production repo's issue-template surface 1:1**,
So that **post-release canary health check (orchestrator's `git push canary main --follow-tags`) doesn't false-positive on missing-config drift, and the canary mirror stays a faithful canary (per Issue #853 AC4 surface 4 gap)**.

## Why now

Per Issue #941 (Sprint 26 Kickoff) §Scope row 2, this is a P3 carryover from v1.0.0 GA audit. Issue #853 §AC4 surface 4 gap was filed during the v1.0.0 release canary health-check cycle. v1.0.1 patch release just published (2026-07-09T16:26:58Z) — canary mirror push will run next, and may false-positive on the missing `.github/ISSUE_TEMPLATE/config.yml`. Fix before canary push to keep canary signal clean.

## Acceptance Criteria

- **AC1** — `.github/ISSUE_TEMPLATE/config.yml` exists in main with valid YAML schema (per GitHub's ISSUE_TEMPLATE config spec: `https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository`).
- **AC2** — Canary mirror push succeeds with 0 canary health-check false-positives (orchestrator's post-`git push canary main --follow-tags` health check reports HEALTHY).
- **AC3** — d-test added at `scripts/tests/d853-canary-config-yml.sh` (sister-pattern to d095 post-org-migration clone URL regression guard) with ≥3 TCs per ADR-0049:
  - TC1: config.yml exists on main + valid YAML
  - TC2: config.yml is in canary mirror (post-push) — regression guard
  - TC3: d-test self-test (`--self-test` flag) returns 0 — ADR-0049 §Framework compliance sister to d649/d070b/d050b/d097
- **AC4** — Sister-pattern check: no other `.github/ISSUE_TEMPLATE/` config surface gap exists (audit all `*.yml` files in `.github/ISSUE_TEMPLATE/` for parity with sister-template repo at atilproject/dev-studio-template).
- **AC5** — d-test INDEX.md row added atomically (Cadence Rule 1, ADR-0055 §1) + d-test GREEN locally + on CI (if CI-integrated, follow d058/d890 sequencing).

## Out of scope

- **Issue template content authoring** (only the `config.yml` plumbing, not the templates themselves)
- **CHANGELOG/RELEASENOTES** (release-notes is a separate concern, dev/orchestrator lane)
- **Canary mirror full audit** (only the config.yml gap, broader audit = separate STORY)

## Open questions

- [ ] What does `config.yml` need to contain? GitHub's spec allows blank/empty config or with `blank_issues_enabled: true`. Per Issue #853 §AC4 surface 4, sister-template parity → check sister-template first → dev to confirm
- [ ] d-test canonical name: `d853-canary-config-yml.sh` or `d853-issue-template-config.sh` → tester to confirm
- [ ] Should this also fix any other `.github/ISSUE_TEMPLATE/*.yml` gaps surfaced in AC4 audit? → dev to confirm at sizing

## Mockups / references

- Issue #853 (canary mirror missing config.yml, v1.0.0 GA audit)
- Issue #941 (Sprint 26 Kickoff §Scope row 2)
- `https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository` (GitHub config.yml spec)
- `.github/ISSUE_TEMPLATE/` (current state — verify what's there)
- sister-template at atilproject/dev-studio-template (parity reference)
- d095 (sister-pattern: post-org-migration clone URL regression guard, 5 TCs)
- d649 (sister-pattern: dev-studio-init.sh smoke test, ≥3 TCs baseline)
- ADR-0049 (d-test framework ≥3 TCs baseline)
- ADR-0055 §1 (Cadence Rule 1 atomic)
- ADR-0010 (canary mirror doctrine)

## Dependencies

- **Upstream**:
  - Issue #853 (canonical source)
  - v1.0.1 release published (prerequisite for canary push, per Issue #941 §Trigger 2)
- **Downstream**:
  - canary mirror push (orchestrator, post-PR-merge)
  - Sister-template parity audit (potential follow-up STORY per AC4)

## Metrics of success

- **Leading**: config.yml + d-test853 added in same PR (Cadence Rule 1 atomic)
- **Leading**: canary mirror push post-v1.0.1 release reports HEALTHY (no false-positive on missing config)
- **Lagging**: 0 canary health-check false-positives in subsequent releases (regression guard via d853)

## Sprint
Sprint 26 (per Issue #941 §Scope row 2)

## Priority
P3 (per Issue #941 §Scope row 2)

## Story points (proposed by PM, joint sizing TBD per ADR-0021)

Proposed: **0.5sp — config.yml authoring + d-test853 (3 TCs) + INDEX.md row + canary push verification**.

PM proposes 0.5sp based on sister-pattern d095 (5 TCs at ~0.3sp) + config.yml as one-line yaml. Joint sizing requires:
- **developer** (config.yml authoring, canary push)
- **tester** (d-test853 RED-first authoring, count verification)
- **architect** (Cadence Rule 1 atomic, canary mirror doctrine alignment)
- **owner ratification** (canary push is owner-or-orchestrator territory per ADR-0010)

Developer lane primary ownership per Issue #113 label-authority.
