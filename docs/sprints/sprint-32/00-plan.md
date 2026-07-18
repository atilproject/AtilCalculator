# Sprint 32 Plan — dev-studio-template + dev-studio-launcher Finalize

> **Plan author:** @orchestrator (cycle ~#3221, post-REPRIME)
> **Plan source:** Audit at `atilproject/dev-studio-template` PR #126 (sha `bcad543`, draft, awaiting owner read)
> **Plan target files:** `atilproject/dev-studio-template` (primary) + `atilcan65/dev-studio-launcher` (secondary) + `atilcan65/AtilCalculator` (forward-port surface)
> **Plan cadence:** 2 weeks / 10 working days, mirrors Sprint 31 close ceremony
> **Trigger:** Owner directive 2026-07-18T10:01+0300 — "Sprint 32 sadece bu iş olacak, 1 sprintte tamamlıcaz"

---

## Context — why this sprint exists

Owner directive on 2026-07-18 mandated: **Sprint 32 is exclusively dev-studio-template + dev-studio-launcher finalize work**. This is the first sprint where the focus shifts from feature-development (AtilCalculator product) to **infrastructure-finalize** (the meta-template that bootstraps new projects).

The audit at PR #126 (385 lines, cycle ~#3218) identified **Top 6 gaps blocking template-finalize**:

1. **P0** — `scripts/orchestrator-gap-scan.sh` ABSENT from template (calc has 8514 bytes since 2026-07-14)
2. **P0** — Orchestrator soul file Δ=+5500B in calc — Cadence Rule 2 + RETRO-018 + RETRO-027 + Issue #414 amendments missing from template
3. **P1** — Architect soul file Δ=+1440B in calc — recent amendments missing
4. **P1** — Stale `atilcan65` refs in 3 template docs (README.md.tmpl, LABEL-TAXONOMY.md, TEMPLATE_NOTES.md)
5. **P1** — Template CHANGELOG.md frozen at v1.0.1 (2026-07-09); main is 12+ commits ahead, no new release tag
6. **P1** — Template ci.yml uses `actions/checkout@v4` (not SHA-pinned); lacks Python detection that calc's ci.yml has

Audit also identified:
- **~40 ADRs missing from template** (need triage: doctrine vs calc-specific)
- **Calc-side forward-port gaps** (template has files calc lacks: `scripts/install/dev-studio-install-env.sh`, `scripts/install/systemd/`, plus template has `scripts/tests/INDEX.md` which calc is missing)
- **Launcher gap**: no CI workflow, no CI integration for `tests/d001-launcher-self-hosted-runner-patch.sh`
- **`docs/new-project-steps.md` missing** in template (Q6 owner request)

**Self-hosted runner = owner-managed, NOT a Sprint 32 gap** (owner has 8-runner pool at 192.168.1.197; will be wired to template-launched private projects per directive 2026-07-18T10:30+0300).

**Outcome**: After Sprint 32, `atilproject/dev-studio-template` reaches a v1.1.0 tag, `atilcan65/dev-studio-launcher` reaches v0.4.0 with CI, and `atilcan65/AtilCalculator` has full forward-port parity (no remaining template→calc drift). New projects can bootstrap in 1 `new-project.sh` invocation with full feature parity to AtilCalculator's Sprint 31 state.

---

## §0 — Sprint Goal (North Star)

**dev-studio-template v1.1.0 + dev-studio-launcher v0.4.0 ship with feature-parity to AtilCalculator's Sprint 31 doctrine baseline, full d-test coverage, CI-green on main, and an end-to-end verified new-project bootstrap dry-run.**

Sprint DoD success criterion: A new private project can be created via `dev-studio-launcher/new-project.sh` (or equivalent) referencing `atilproject/dev-studio-template@v1.1.0`, run `dev-studio-init.sh`, have all 5 agents wake in tmux, file a Vision Intake issue, claim it, and execute a minimal feature through the full PM → Arch → Dev → Tester pipeline — all within the sprint window.

Sprint boundary:
- **IN scope**: template finalize, launcher finalize, calc forward-port, `new-project-steps.md`, tag v1.1.0, RETRO-032
- **OUT of scope**: AtilCalculator feature work, new product features, any self-hosted runner registration (owner task), calc-only refactors not template-relevant

---

## §1 — Owner Decisions Ratified

| # | Topic | Decision | Implementation |
|---|---|---|---|
| 1 | Sprint 32 scope | EXCLUSIVELY template + launcher finalize, 1 sprint | This plan; no other work accepted during sprint window |
| 2 | Self-hosted runner | OWNER-MANAGED (8-runner pool at 192.168.1.197); not a Sprint 32 gap; orchestrator MUST NOT ping owner | Architecture: orchestrator notes in audit only |
| 3 | Issue #123 label fix | CANCELLED (was 4-cat violation on Issue #123); Sprint 32 creates NEW issues with proper labels per ADR-0012 birth contract | S32-024 includes 4-cat-verified new-project bootstrap |
| 4 | PR target | TEMPLATE repo (not calc) for audit file | Already done at PR #126 |
| 5 | Plan mode | Permitted for Sprint 32 plan refinement | This plan |
| 6 | Dispatch timing | AFTER plan mode done (this plan is the gate) | Sprint 32 dispatch happens post-ExitPlanMode approval |
| 7 | Sprint 32 GO signal | Owner explicitly types "go" — not auto-triggered | Owner will signal in chat; orchestrator awaits verbatim |
| 8 | Cluster-squash | Liberal use of ADR-0059 batch-merge (per Sprint 31 Path A v26 precedent, 15-sec window) | S32-025 finalization story batch-merges all sprint docs |

---

## §2 — Sprint Capacity + Boundary

| Field | Value |
|---|---|
| Length | 2 weeks / 10 working days |
| Capacity cap | 4-5 PRs/cluster-squash per day, all 5 agents in parallel lanes |
| Scope boundary | IN: template finalize, launcher finalize, calc forward-port, new-project-steps.md, v1.1.0/v0.4.0 tags, RETRO-032. OUT: any AtilCalculator feature work |
| DoD | Per `CLAUDE.md §Definition of Done`: all 6 items (AC tests, PR-merge+approval, CI-green, docs-updated, board-moved, no P0/P1 bugs in 24h) |
| Anti-pattern guard | (a) No `Sprint 32` issue/PR opens without 4-cat labels per ADR-0012 birth contract; (b) No PR self-merge per ADR-0031; (c) No soul-file edits outside human approval per file ownership matrix |

---

## §3 — Story Inventory (24 stories, 6 waves)

> AC counts follow ADR-0049 (≥5 TCs for behavioral stories; ≥3 TCs for hygiene/docs). Each story has 4-cat labels (type + status + agent + cc) per ADR-0012.

### Wave 1 — Discovery (Day 1-2, architect + orchestrator)

#### S32-001 — ARCH: Full doctrine diff (ADRs, soul files, scripts, workflows)
- **Agent**: @architect
- **CC**: @orchestrator
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: Full ADR diff (calc 71 files vs template 31 files) classified as doctrine-port or calc-specific
  - AC2: Soul file diff (orchestrator +5500B, architect +1440B) amendment-by-amendment
  - AC3: Scripts diff (45 calc vs 44 template) classified
  - AC4: Workflows diff (11 calc vs 11 template + deploy.yml.tmpl) hardened gaps listed
  - AC5: Output doc committed as `docs/sprints/sprint-32/01-diff-classification.md`
- **Sister-pattern**: ADR-0050 (pre-merge 4-cat verification)
- **Done-Means**: Diff doc merged to template `docs/sprints/sprint-32/01-diff-classification.md` with row-per-file classification table
- **D-test**: None (discovery phase, no behavior change)
- **Deps**: None
- **Cluster**: Standalone (architect lane)

#### S32-002 — DEV: Baseline portage report
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: `bash scripts/verify-portage.sh --report /tmp/portage-sprint-32-baseline.txt` exits 0
  - AC2: Report saved at `/tmp/portage-sprint-32-baseline.txt` with ≥1 line per gap category
  - AC3: Report copy committed to `docs/sprints/sprint-32/02-portage-baseline.md` (sanitized, no secrets)
  - AC4: Gap count matches audit's "Top 6 + ~40 ADRs" rough order of magnitude
  - AC5: Report includes d-test parity summary
- **Sister-pattern**: `s29-005-verify-portage.sh` (template local)
- **Done-Means**: Portage baseline doc merged; pre-Sprint-32 gap state frozen
- **D-test**: None
- **Deps**: None
- **Cluster**: Standalone (developer lane)

### Wave 2 — Template gap-closure (Day 3-6, architect + developer + tester)

#### S32-003 — ARCH: Port doctrine-critical ADRs (cluster-squash batch)
- **Agent**: @architect
- **CC**: @developer, @tester, @product-manager
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: List of ADRs to port (from S32-001 AC1 doctrine-classified set) ≥10 ADRs selected
  - AC2: Each ADR PR has `Closes #<calc-ADR-issue>` anchor where applicable + `Refs ADR-NNNN` body links
  - AC3: ADRs landed in single owner-squash batch per ADR-0059 (≤15-sec owner-squash window)
  - AC4: `docs/decisions/INDEX.md` updated with new ADR entries
  - AC5: 1 ADR-0050 4-cat pre-merge verification per ADR passes
- **Sister-pattern**: Sprint 31 cluster-squash Path A v26 (3-PR atomic, cycle ~#2944 precedent)
- **Done-Means**: All selected ADRs merged to template `main` in 1 cluster-squash batch
- **D-test**: None (ADR text-only, behavior unchanged)
- **Deps**: S32-001
- **Cluster**: CANDIDATE for cluster-squash (ADR-0059)

#### S32-004 — ARCH: Sync orchestrator soul file (+5500B amendments)
- **Agent**: @architect
- **CC**: @product-manager
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: All 4 amend blocks from calc orchestrator.md.tmpl present in template (RETRO-018 W6, Issue #414, Issue #389, KAPI hotfix, Cadence Rule 2 retroactive-close)
  - AC2: File size delta matches calc (+5500B ±10%)
  - AC3: `diff` between calc .tmpl and template .tmpl shows 0 substantive diff after sync
  - AC4: One SOUL AMEND BEGIN/END block per cycle (preserve provenance)
  - AC5: PR body lists each amend block by header + cycle origin
- **Sister-pattern**: d075 (CLAUDE.md.tmpl full doctrine content, 7 TCs) sister
- **Done-Means**: `.claude/agents/orchestrator.md.tmpl` in template matches calc byte-for-byte (modulo repo-specific paths)
- **D-test**: d096 (S21-006 soul files template coverage, 5 TCs) — pre-existing, must remain GREEN
- **Deps**: S32-001
- **Cluster**: CANDIDATE for cluster-squash with S32-005

#### S32-005 — ARCH: Sync architect soul file (+1440B amendments)
- **Agent**: @architect
- **CC**: @product-manager
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: All recent amend blocks from calc architect.md.tmpl present in template
  - AC2: File size delta matches calc (+1440B ±10%)
  - AC3: 9-Lens pre-publish gate (ADR-0045) coverage comments intact
  - AC4: PR body lists each amend block by header + cycle origin
  - AC5: Sister-pattern with S32-004 (same commit, cluster-squash atomicity)
- **Sister-pattern**: S32-004
- **Done-Means**: `.claude/agents/architect.md.tmpl` in template matches calc byte-for-byte (modulo repo-specific paths)
- **D-test**: Existing d096 covers architect too
- **Deps**: S32-001
- **Cluster**: CANDIDATE for cluster-squash with S32-004

#### S32-006 — DEV: Port orchestrator-gap-scan.sh + d-test
- **Agent**: @developer
- **CC**: @tester, @orchestrator
- **Type/Status**: `type:feature` + `status:ready`
- **ACs** (≥5):
  - AC1: `scripts/orchestrator-gap-scan.sh` present in template, byte-equal to calc's 8514B version (modulo path substitutions)
  - AC2: New d-test `scripts/tests/d-orchestrator-gap-scan-port.sh` with ≥5 TCs covering all 4 detection kinds (orphan scripts, label hygiene, link rot, cross-repo drift)
  - AC3: d-test exits 0 in GREEN state, 1 in RED state
  - AC4: `scripts/tests/INDEX.md` row added per Cadence Rule 1 atomic (ADR-0055 §1)
  - AC5: `scripts/orchestrator-gap-scan.sh --help` outputs usage matching calc
- **Sister-pattern**: Issue #235 (4 detection kinds); Sprint 31 d-test pattern (ADR-0049)
- **Done-Means**: Script + d-test + INDEX row all merged atomically
- **D-test**: NEW — `d-orchestrator-gap-scan-port.sh` ≥5 TCs
- **Deps**: S32-001
- **Cluster**: CANDIDATE for cluster-squash (ADR-0059)

#### S32-007 — DEV: Fix stale `atilcan65` refs in template docs
- **Agent**: @developer
- **CC**: @product-manager
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: `README.md.tmpl` — 0 `atilcan65/dev-studio-template` references remain (all → `atilproject/dev-studio-template`)
  - AC2: `.github/LABEL-TAXONOMY.md` — 0 `atilcan65/AtilCalculator` references remain
  - AC3: `TEMPLATE_NOTES.md` — 0 `atilcan65/AtilCalculator` references remain (4 known stale refs)
  - AC4: All URL replacements preserve anchor fragments and code-block content
  - AC5: `grep -r "atilcan65" docs/ README.md.tmpl TEMPLATE_NOTES.md .github/LABEL-TAXONOMY.md` returns 0 lines (excluding git history)
- **Sister-pattern**: Sprint 29 launcher URL-hygiene fix (PR #4, sha b1355be)
- **Done-Means**: All 3 doc files committed in 1 PR, grep returns 0
- **D-test**: None (docs-only)
- **Deps**: None
- **Cluster**: Standalone

#### S32-008 — DEV: SHA-pin template workflows (defense-in-depth per ADR-0027)
- **Agent**: @developer
- **CC**: @tester, @architect
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: All `actions/checkout@v4` references replaced with SHA-pinned versions (40-char hex)
  - AC2: All `actions/setup-python@v5` references SHA-pinned
  - AC3: All other `actions/*@v*` references SHA-pinned (full inventory in PR body)
  - AC4: `.github/workflows/lint-and-test.yml`, `ci.yml`, `label-check.yml`, `label-cleanup.yml`, `status-label-to-board.yml`, `post-squash.yml`, `d050b-dispatch.yml`, `secret-canary.yml`, `cross-repo-close.yml`, `ai-pr-review.yml`, `deploy.yml` all updated
  - AC5: CI green after SHA pin (no behavior change, just version hardening)
- **Sister-pattern**: ADR-0027 §Threat model (Sprint 14 hardening)
- **Done-Means**: All workflows SHA-pinned, CI green
- **D-test**: None (config-only)
- **Deps**: None
- **Cluster**: Standalone (developer lane)

#### S32-009 — DEV: Add Python detection to template ci.yml
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:feature` + `status:ready`
- **ACs** (≥5):
  - AC1: `ci.yml` detects `pyproject.toml` and runs `ruff check` + `mypy` + `pytest`
  - AC2: Conditional logic preserves existing JS/Node detection (template is JS-aware too)
  - AC3: Python detection runs ONLY if `pyproject.toml` present (no-op for non-Python projects)
  - AC4: CI green on template main with Python detection
  - AC5: Documentation comment in ci.yml explains detection pattern (sister to calc ci.yml)
- **Sister-pattern**: calc `.github/workflows/ci.yml` (Python+Node detection precedent)
- **Done-Means**: ci.yml updated, CI green
- **D-test**: None (CI workflow logic)
- **Deps**: None
- **Cluster**: Standalone

### Wave 3 — Calc forward-port (Day 4-6, developer)

#### S32-010 — DEV: Forward-port `scripts/install/dev-studio-install-env.sh` to calc
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: `scripts/install/dev-studio-install-env.sh` present in calc, byte-equal to template's version (modulo path substitutions)
  - AC2: Script is executable (`chmod +x` applied)
  - AC3: Runs in `--dry-run` mode without error
  - AC4: Test invocation logs visible (no actual install in test)
  - AC5: Sister-pattern row added to calc `scripts/tests/INDEX.md` if d-test exists
- **Sister-pattern**: Template `scripts/install/dev-studio-install-env.sh` (Telegram env-provisioning helper, PR #114, merged 2026-07-15 in template)
- **Done-Means**: File present in calc, executable, dry-run clean
- **D-test**: Pre-existing in template (`d1028-s29-install-env-telegram.sh`); re-run on calc to confirm
- **Deps**: None
- **Cluster**: CANDIDATE for cluster-squash with S32-011

#### S32-011 — DEV: Forward-port `scripts/install/systemd/dev-studio-watcher@.service.tmpl` to calc
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: `scripts/install/systemd/dev-studio-watcher@.service.tmpl` present in calc
  - AC2: Template variables (`{{PROJECT_NAME}}`, etc.) preserved
  - AC3: Sister-pattern with calc's systemd install pattern (if any)
  - AC4: PR body lists path-substitution deltas vs template
  - AC5: systemd unit renders correctly via `dev-studio-init.sh --dry-run`
- **Sister-pattern**: Template `scripts/install/systemd/` directory (added 2026-07-15)
- **Done-Means**: File present, renders cleanly
- **D-test**: None (template file only)
- **Deps**: None
- **Cluster**: CANDIDATE for cluster-squash with S32-010

#### S32-012 — DEV: Create calc `scripts/tests/INDEX.md` (mirror template)
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: `scripts/tests/INDEX.md` exists in calc, ≥50 entries (mirror template's 49 + calc-specific)
  - AC2: Each entry follows INDEX row schema (Story, Source-of-truth sister, Test file, TCs, Sister-pattern, Run, Cross-references)
  - AC3: INDEX references all 50+ d-test files in `scripts/tests/`
  - AC4: Header references RETRO-008 §11 + ADR-0049 + ADR-0055 §1
  - AC5: `grep -c '^## d' scripts/tests/INDEX.md` matches `ls scripts/tests/d*.sh | wc -l` (or close)
- **Sister-pattern**: Template `scripts/tests/INDEX.md` (99744 B, established in Sprint 28)
- **Done-Means**: INDEX.md merged, row count matches d-test file count
- **D-test**: Pre-existing d-tests verified by INDEX.md cross-references
- **Deps**: None
- **Cluster**: Standalone

#### S32-013 — DEV: Create calc `.github/workflows/lint-and-test.yml` (mirror template)
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:feature` + `status:ready`
- **ACs** (≥5):
  - AC1: `.github/workflows/lint-and-test.yml` exists in calc, structure mirrors template's (2 jobs, self-hosted 4-tuple)
  - AC2: First job runs `bash scripts/tests/d031-claim-next-ready.sh --self-test`
  - AC3: Second job runs `bash scripts/tests/d058-claim-wip-workstream.sh --self-test` (calc has d058; template substitutes dreg — calc should use d058 since it has it)
  - AC4: SHA-pinned `actions/checkout` (per ADR-0027, sister to S32-008)
  - AC5: Workflow triggers on push to main + PR open/sync
- **Sister-pattern**: Template `.github/workflows/lint-and-test.yml` (6224 B, established in Sprint 29 PR-B/4)
- **Done-Means**: Workflow merged, CI green on next push
- **D-test**: Both d031 + d058 GREEN per workflow log
- **Deps**: None
- **Cluster**: Standalone

### Wave 4 — Launcher finalize (Day 6-8, developer + tester)

#### S32-014 — DEV: Add CI workflow to launcher
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:feature` + `status:ready`
- **ACs** (≥5):
  - AC1: `.github/workflows/ci.yml` exists in launcher, runs `bash tests/d001-launcher-self-hosted-runner-patch.sh --self-test`
  - AC2: `.github/workflows/lint-and-test.yml` exists (or ci.yml subsumes it)
  - AC3: SHA-pinned actions per ADR-0027
  - AC4: Workflow triggers on push to main + PR open/sync
  - AC5: CI green on launcher main (assuming d001 passes)
- **Sister-pattern**: Template + calc `.github/workflows/lint-and-test.yml` (sister-pattern established)
- **Done-Means**: Launcher has CI, runs d001 d-test
- **D-test**: d001-launcher-self-hosted-runner-patch.sh runs in CI
- **Deps**: None
- **Cluster**: CANDIDATE for cluster-squash with S32-015

#### S32-015 — TESTER: CI-integrate d001 d-test (ADR-0044 RED-first)
- **Agent**: @tester
- **CC**: @developer, @architect
- **Type/Status**: `type:feature` + `status:ready`
- **ACs** (≥5):
  - AC1: `tests/d001-launcher-self-hosted-runner-patch.sh` exits 0 in GREEN state
  - AC2: d-test runs in CI on launcher (via S32-014 workflow)
  - AC3: ≥5 TCs covering: runner 4-tuple pattern, env-var substitution, idempotency, fail-state handling, multi-platform skip
  - AC4: `--self-test` flag pattern matches template sister (d031, d1138)
  - AC5: ARCH 🟢 + TESTER 🟢 verdicts on PR
- **Sister-pattern**: d031-claim-next-ready.sh, d1138-template-agent-wake-fix-4b.sh, dreg-post-restart-label-guard.sh (all template sisters)
- **Done-Means**: d-test GREEN in CI, PR approved
- **D-test**: d001 itself
- **Deps**: None
- **Cluster**: CANDIDATE for cluster-squash with S32-014

#### S32-016 — DEV: Bump launcher to v0.4.0
- **Agent**: @developer
- **CC**: @product-manager, @orchestrator
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: `CHANGELOG.md` updated with v0.4.0 entry listing S32-014 + S32-015 features
  - AC2: Tag `v0.4.0` cut on launcher main after CI green
  - AC3: Release notes draft committed at `docs/releases/v0.4.0.md`
  - AC4: README updated with "TESTED with template v1.1.0" badge (gated on template v1.1.0 cut)
  - AC5: `TEMPLATE_REPO` constant pinned to `atilproject/dev-studio-template` (sister to v1.1.0)
- **Sister-pattern**: Template CHANGELOG.md release-train pattern
- **Done-Means**: Tag v0.4.0 cut on launcher main, release notes published
- **D-test**: None (release-only)
- **Deps**: S32-014, S32-015
- **Cluster**: Standalone (release tag)

### Wave 5 — Docs + Tag (Day 8-9, PM + developer)

#### S32-017 — PM: Write `docs/new-project-steps.md` in template
- **Agent**: @product-manager
- **CC**: @developer, @tester, @orchestrator
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: 12 sections per audit Q6 (Prerequisites, PROJECT_TOKEN, clone launcher, new-project.sh, init render, label seed, Telegram, systemd, runner registration, Vision Intake, tmux agents, d-test verify)
  - AC2: Each section has copy-pasteable bash commands
  - AC3: "What could go wrong" notes per section
  - AC4: Links to relevant ADRs (ADR-0002, ADR-0012, ADR-0031, ADR-0033)
  - AC5: Reviewed by developer + tester for technical accuracy
- **Sister-pattern**: Sprint 29 `02-template-launcher-audit-2026-07-13.md` (calc reference doc style)
- **Done-Means**: new-project-steps.md merged, ready for owner handoff
- **D-test**: None (docs-only)
- **Deps**: None
- **Cluster**: Standalone

#### S32-018 — DEV: Update template CHANGELOG.md to v1.1.0
- **Agent**: @developer
- **CC**: @product-manager
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: `[Unreleased]` section closed; v1.1.0 entry added with all Sprint 32 features
  - AC2: PR-by-PR changelog entries (S32-003 ADRs, S32-004+S32-005 soul sync, S32-006 gap-scan, etc.)
  - AC3: Sister-pattern: matches calc `CHANGELOG.md` style
  - AC4: Sprint 29-31 entries backfilled (per audit gap #5 finding)
  - AC5: Date stamp = sprint close date
- **Sister-pattern**: Sprint 31 close.md + calc CHANGELOG.md precedent
- **Done-Means**: CHANGELOG.md updated, ready for tag
- **D-test**: None (docs-only)
- **Deps**: S32-003 through S32-013 merged
- **Cluster**: Standalone

#### S32-019 — DEV: Cut tag v1.1.0 on template main
- **Agent**: @developer
- **CC**: @orchestrator
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: All Wave 2 + Wave 3 PRs MERGED to template main
  - AC2: CI green on template main (all 11 workflows)
  - AC3: `git tag -a v1.1.0 -m "Sprint 32 finalize"` executed on main HEAD
  - AC4: `git push origin v1.1.0` succeeds
  - AC5: Tag visible at `https://github.com/atilproject/dev-studio-template/releases/tag/v1.1.0`
- **Sister-pattern**: Sprint 28 v1.0.1 tag precedent
- **Done-Means**: v1.1.0 tag cut and pushed
- **D-test**: None (release-only)
- **Deps**: S32-018
- **Cluster**: Standalone (release tag, NOT batch-merge)

#### S32-020 — DEV: Verify smoke repo is at v1.1.0 (Q7 verification)
- **Agent**: @developer
- **CC**: @tester
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: `gh repo view atilproject/dev-studio-template-smoke --json pushedAt` shows date ≥ v1.1.0 tag date
  - AC2: `git -C <smoke-clone> log --oneline | head -20` includes v1.1.0-era commits
  - AC3: Smoke repo's `scripts/tests/INDEX.md` (if present) matches template v1.1.0 INDEX.md
  - AC4: Verification report committed at `docs/sprints/sprint-32/03-smoke-verify.md`
  - AC5: Tester cross-check verifies smoke repo HEAD sha equals template main HEAD sha
- **Sister-pattern**: Audit Q7 verification methodology
- **Done-Means**: Smoke verification doc merged, propagation confirmed
- **D-test**: None (verification-only)
- **Deps**: S32-019
- **Cluster**: Standalone

### Wave 6 — Verification + Close (Day 9-10, tester + dev + orchestrator)

#### S32-021 — TESTER: Full d-test sweep on template
- **Agent**: @tester
- **CC**: @developer, @architect
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: All 49+ existing d-tests GREEN on template main (HEAD = v1.1.0 tag)
  - AC2: All new d-tests from S32-006, S32-013, S32-014 GREEN
  - AC3: Run command: `for t in scripts/tests/d*.sh scripts/tests/s29-*.sh; do bash "$t" --self-test || echo "FAIL: $t"; done | tee /tmp/dtest-sweep.log`
  - AC4: 0 FAIL lines in sweep log
  - AC5: Sweep report committed at `docs/sprints/sprint-32/04-dtest-sweep.md`
- **Sister-pattern**: Sprint 31 close verification (cycle ~#3062 precedent)
- **Done-Means**: Sweep report merged, all d-tests GREEN
- **D-test**: All d-tests (the sweep IS the verification)
- **Deps**: S32-019
- **Cluster**: Standalone

#### S32-022 — DEV: Re-run `scripts/verify-portage.sh` (expect 0 gaps)
- **Agent**: @developer
- **CC**: @tester, @architect
- **Type/Status**: `type:chore` + `status:ready`
- **ACs** (≥5):
  - AC1: `bash scripts/verify-portage.sh --report /tmp/portage-sprint-32-final.txt` exits 0
  - AC2: Report shows 0 gaps in doctrine-critical categories
  - AC3: Report copy committed at `docs/sprints/sprint-32/05-portage-final.md`
  - AC4: Delta vs baseline (S32-002) shows all gaps closed
  - AC5: Delta report covers ~40 ADRs (from S32-001 classification) all ported or calc-specific (with rationale)
- **Sister-pattern**: S32-002 (baseline), `s29-005-verify-portage.sh`
- **Done-Means**: Final portage doc merged, 0 critical gaps
- **D-test**: verify-portage.sh itself
- **Deps**: S32-021
- **Cluster**: Standalone

#### S32-023 — ORCH: Sprint 32 close ceremony (close.md + RETRO-032.md)
- **Agent**: @orchestrator
- **CC**: @architect, @tester, @product-manager, @human
- **Type/Status**: `type:docs` + `status:ready`
- **ACs** (≥5):
  - AC1: `docs/sprints/sprint-32/close.md` written following Sprint 31 close.md pattern (Outcome, What landed, Owner-squash batches, Carry-over, Open tech-debt, ACs matrix, DoD checklist, Lessons learned)
  - AC2: `docs/sprints/sprint-32/RETRO-032.md` written following RETRO-031 pattern (Outcomes summary, What worked, What didn't, Sister-patterns surfaced, Tech-debt carry-over)
  - AC3: Both docs merged in cluster-squash with v1.1.0 tag PR (per ADR-0059)
  - AC4: All carry-over issues closed or explicitly marked Sprint 33+ scope
  - AC5: Owner squash-merge per ADR-0031
- **Sister-pattern**: Sprint 31 close.md (10433 B) + RETRO-031.md (8574 B) pattern
- **Done-Means**: Close + RETRO merged, Sprint 32 DONE-ready
- **D-test**: None (docs-only)
- **Deps**: S32-022
- **Cluster**: CANDIDATE for final cluster-squash with v1.1.0 tag

#### S32-024 — DEV: New project bootstrap dry-run
- **Agent**: @developer
- **CC**: @tester, @orchestrator
- **Type/Status**: `type:feature` + `status:ready`
- **ACs** (≥5):
  - AC1: Test private repo created via `dev-studio-launcher/new-project.sh` referencing `atilproject/dev-studio-template@v1.1.0`
  - AC2: `dev-studio-init.sh` renders all templates cleanly (no errors)
  - AC3: All 5 agents wake in tmux (`dev-studio-start.sh start`)
  - AC4: Vision Intake issue filed, claimed via auto-claim (ADR-0038)
  - AC5: Dry-run report committed at `docs/sprints/sprint-32/06-dryrun-report.md`
- **Sister-pattern**: E2E pilot (`scripts/tests/e2e-pilot.sh`)
- **Done-Means**: Dry-run report merged, end-to-end bootstrap verified
- **D-test**: e2e-pilot.sh (extended for Sprint 32 path)
- **Deps**: S32-023
- **Cluster**: Standalone (final verification)

---

## §4 — Sister-pattern risks (per RETRO-007 watchlist + Sprint 31 lessons)

| # | Risk | Mitigation |
|---|---|---|
| 1 | Cadence Rule 2 violation (ADR-0055 §1) | Each ADR PR + d-test + INDEX.md row = single commit; per ADR-0059 cluster-squash, sister PRs batched together |
| 2 | Cadence Rule 2 retroactive-close precondition (RETRO-027) | If a gap fix already exists in working-tree without PR, follow restart-survivability test (git fetch origin main + git show origin/main:<file>) |
| 3 | Issue #123 4-cat violation recurrence | All Sprint 32 PRs/Issues created with full 4-cat labels per ADR-0012 birth contract — never "fix later" |
| 4 | Cluster-squash inventory miss | ADR-0059 inventory must include d-test PRs (per cycle ~#2954 doctrine amendment) |
| 5 | Cross-repo workstream drift (RETRO-023) | Sprint 32 work spans 3 repos (template + launcher + calc); owner-merge-gate per ADR-0031 enforced on all final merges |
| 6 | ADR-number hallucination (cycle ~#2832) | All ADR-NNNN references verified via `gh api` REST + `git ls-tree origin/main docs/decisions/`; never cited from memory |
| 7 | GraphQL rate-limit hit (cycle ~#2799) | Use `gh api` REST + curl + jq + Bearer token fallback when GraphQL rate-limited |
| 8 | Self-hosted runner race (RETRO-018 W6) | Sprint 32 plan explicitly excludes runner setup; owner-managed per directive 2026-07-18T10:30+0300 |
| 9 | Owner-squash lag | Owner squash-merge is on critical path; ORCH signals owner via `scripts/peer-poke.sh human` at end of each wave |
| 10 | Sprint scope creep | Wave boundaries enforced; any new work explicitly added via owner directive in Issue tracker |

---

## §5 — Critical files to modify

> Pattern repeats across many files; representative paths listed.

### Template (`atilproject/dev-studio-template`)
- `.claude/agents/orchestrator.md.tmpl` (S32-004) — soul sync +5500B
- `.claude/agents/architect.md.tmpl` (S32-005) — soul sync +1440B
- `scripts/orchestrator-gap-scan.sh` (S32-006) — NEW port
- `scripts/tests/d-orchestrator-gap-scan-port.sh` (S32-006) — NEW d-test
- `scripts/tests/INDEX.md` (S32-006, S32-012, S32-014) — INDEX row additions
- `README.md.tmpl` (S32-007) — stale URL fix
- `.github/LABEL-TAXONOMY.md` (S32-007) — stale URL fix
- `TEMPLATE_NOTES.md` (S32-007) — stale URL fix
- `.github/workflows/*.yml` (S32-008) — SHA-pin
- `.github/workflows/ci.yml` (S32-009) — Python detection
- `docs/decisions/INDEX.md` (S32-003) — ADR index updates
- `docs/decisions/ADR-NNNN-*.md` (S32-003) — ~20 ported ADRs
- `CHANGELOG.md` (S32-018) — v1.1.0 entry
- `docs/new-project-steps.md` (S32-017) — NEW 12-step guide
- `docs/sprints/sprint-32/{01..06}-*.md` (S32-001, S32-002, S32-020, S32-021, S32-022, S32-024) — sprint artifacts
- `docs/sprints/sprint-32/close.md` (S32-023) — sprint close
- `docs/sprints/sprint-32/RETRO-032.md` (S32-023) — retro

### Calc (`atilcan65/AtilCalculator`)
- `scripts/install/dev-studio-install-env.sh` (S32-010) — forward-port
- `scripts/install/systemd/dev-studio-watcher@.service.tmpl` (S32-011) — forward-port
- `scripts/tests/INDEX.md` (S32-012) — NEW mirror
- `.github/workflows/lint-and-test.yml` (S32-013) — NEW mirror

### Launcher (`atilcan65/dev-studio-launcher`)
- `.github/workflows/ci.yml` (S32-014) — NEW
- `tests/d001-launcher-self-hosted-runner-patch.sh` (S32-015) — CI-integrated
- `CHANGELOG.md` (S32-016) — v0.4.0 entry
- `docs/releases/v0.4.0.md` (S32-016) — NEW release notes

---

## §6 — Sister-PR anchor discipline (ADR-0057 strict)

Per cycle ~#2919 + cycle ~#2921 lessons:
- `Closes #N` = strict anchor, triggers auto-close on merge
- `Closes #N AC1` = partial anchor (problematic, see RETRO-031 L9)
- `Refs #N` = reference only, no auto-close

**Sprint 32 rule**:
- For atomic 4-cat issues (e.g., S32-006 + d-test + INDEX row = 1 story): use `Closes #<story-issue>` only on the IMPL PR; d-test PR uses `Refs #<story-issue>` + `Closes #<dtest-issue>` (separate d-test issue per ADR-0049)
- For multi-PR cluster-squash: each PR uses `Closes #<its-own-issue>` + `Refs #<sister-issues>`
- For docs PRs (S32-007, S32-017, S32-018): use `Refs #<audit-PR-126>` since these are part of Sprint 32 but not closing the audit itself

---

## §7 — Verification

### End-to-end verification
1. **All 24 stories merged** to their respective `main` branches (template + launcher + calc)
2. **v1.1.0 tag cut on template main** (S32-019)
3. **v0.4.0 tag cut on launcher main** (S32-016)
4. **All 49+ d-tests GREEN on template** (S32-021)
5. **`scripts/verify-portage.sh` reports 0 critical gaps** (S32-022)
6. **New project bootstrap dry-run successful** (S32-024)
7. **RETRO-032.md + close.md merged** (S32-023)
8. **Owner squash-merge cascade** (final, per ADR-0031)

### Per-story verification (commands)

| Story | Verification command |
|---|---|
| S32-001 | `gh api repos/atilproject/dev-studio-template/contents/docs/sprints/sprint-32/01-diff-classification.md` (200 OK) |
| S32-002 | `ls -la /tmp/portage-sprint-32-baseline.txt` (exists) |
| S32-003 | `gh pr list --state merged --label "type:docs" --repo atilproject/dev-studio-template --limit 20` (≥10 ADR PRs) |
| S32-004 | `diff <(curl -s https://raw.githubusercontent.com/atilcan65/AtilCalculator/main/.claude/agents/orchestrator.md.tmpl) <(curl -s https://raw.githubusercontent.com/atilproject/dev-studio-template/main/.claude/agents/orchestrator.md.tmpl) | wc -l` (small diff) |
| S32-005 | (similar to S32-004 for architect) |
| S32-006 | `bash scripts/tests/d-orchestrator-gap-scan-port.sh --self-test` (exits 0) |
| S32-007 | `grep -r "atilcan65" docs/ README.md.tmpl TEMPLATE_NOTES.md .github/LABEL-TAXONOMY.md` (0 lines) |
| S32-008 | `grep -rE "actions/.*@v[0-9]+" .github/workflows/` (0 lines) |
| S32-009 | `gh actions-list` shows Python detection in ci.yml |
| S32-010 | `bash scripts/install/dev-studio-install-env.sh --dry-run` (exits 0) |
| S32-011 | `ls scripts/install/systemd/dev-studio-watcher@.service.tmpl` (exists) |
| S32-012 | `grep -c '^## d' scripts/tests/INDEX.md` matches `ls scripts/tests/d*.sh | wc -l` |
| S32-013 | `gh workflow list --repo atilcan65/AtilCalculator` shows `Lint & Test (d-tests)` |
| S32-014 | `gh workflow list --repo atilcan65/dev-studio-launcher` shows `CI` |
| S32-015 | `gh actions-list --repo atilcan65/dev-studio-launcher` shows d001 test runs |
| S32-016 | `git -C /tmp/dev-studio-launcher tag -l` shows `v0.4.0` |
| S32-017 | `gh api repos/atilproject/dev-studio-template/contents/docs/new-project-steps.md` (200 OK) |
| S32-018 | `grep -A 5 "v1.1.0" CHANGELOG.md` shows entry |
| S32-019 | `git ls-remote --tags origin | grep v1.1.0` shows sha |
| S32-020 | `gh api repos/atilproject/dev-studio-template-smoke` shows recent push |
| S32-021 | `for t in scripts/tests/d*.sh scripts/tests/s29-*.sh; do bash "$t" --self-test; done | grep -c FAIL` (0) |
| S32-022 | `grep -c "GAP" /tmp/portage-sprint-32-final.txt` (0 critical) |
| S32-023 | `gh api repos/atilproject/dev-studio-template/contents/docs/sprints/sprint-32/close.md` (200 OK) |
| S32-024 | Test repo at `atilcan65/dev-studio-sprint-32-smoke` shows 5-agent wake + Vision Intake claim |

### Sister-pattern verification
- All 5 agents (PM, Arch, Dev, Tester, Orch) ack via `[<ROLE>→ORCH] S32-NNN ack` peer-poke per ADR-0033
- Owner squash-merge cascade verified per Sprint 31 Path A v26 (15-sec window)
- Cluster-squash inventory checklist per ADR-0059 (sister-pattern d-test PRs included)

---

## §8 — Owner sign-off pending

Per owner directive 2026-07-18T10:01+0300: **Sprint 32 EXECUTION awaits owner GO signal** ("ben go verince sprint 32 ile başlayacak başka bir iş sprint 32 a alınmıcak"). This plan is the dispatch-prep phase, not execution.

When owner signals "go":
1. ORCH opens Sprint 32 kickoff issue with 4-cat labels (type:chore + status:ready + agent:orchestrator + cc:product-manager)
2. ORCH dispatches team via `scripts/peer-poke.sh` per ADR-0033 (architect → S32-001+S32-003+S32-004+S32-005; developer → S32-002+S32-006..S32-013+S32-016+S32-018..S32-020+S32-022+S32-024; tester → S32-015+S32-021; PM → S32-017)
3. Sprint 32 begins Wave 1 → Wave 6 per this plan

---

## §9 — What this plan does NOT do (per audit + owner directives)

- ❌ Register self-hosted runners (owner-managed per directive 2026-07-18T10:30+0300)
- ❌ Fix Issue #123 labels (CANCELLED per directive 2026-07-18T10:30+0300; Sprint 32 creates new issues with proper labels)
- ❌ Run AtilCalculator feature work (out of scope per "Sprint 32 sadece bu iş olacak")
- ❌ Modify `.github/workflows/` in template without arch verdict (per file ownership matrix, arch reviews + owner merges)
- ❌ Edit `.claude/CLAUDE.md` template without owner approval (file ownership matrix)
- ❌ Cite ADR-NNNN numbers from memory (per cycle ~#2832 doctrine, all references must be verified via `gh api` REST)

---

## §10 — Plan approval request

This plan is presented to the owner via ExitPlanMode. Approval gates:
1. Owner reads audit PR #126 (template repo, draft)
2. Owner reads this plan file
3. Owner approves via plan mode exit
4. ORCH opens kickoff issue + dispatches team (Sprint 32 prep, not execution)
5. Owner signals "go" in chat
6. Sprint 32 EXECUTION begins

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)