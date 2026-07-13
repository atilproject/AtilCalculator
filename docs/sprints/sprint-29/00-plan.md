# Sprint 29 Plan — Template/Launcher Gap-Closure

> **Sprint:** 29
> **Owner-ratified:** 2026-07-13 (cycle ~#1159)
> **Orchestrator:** drafted 2026-07-13T06:25:00Z, refinement after owner 5-decision response
> **Prereq:** `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` (PR #1008, status:ready awaiting owner squash-merge per ADR-0031)

---

## §0 — Sprint Goal (North Star)

> **dev-studio-template reaches ~100% from-scratch deployable parity with
> AtilCalculator, on a self-hosted-runner-only deployment profile, with the
> v1.0.1 tag moved forward to current HEAD.**
>
> **Success criterion (sprint DoD):** A fresh private repo created via
> launcher (with post-portage template) runs CI 100% green on self-hosted
> runners, with all universal ADRs present, with all universal d-tests
> passing, with no Actions-minutes burn, with the v1.0.1 tag pointing at
> current HEAD.

**Sprint boundary (owner directive #3):**
- **All gap-closing actions in 29, NOTHING ELSE.**
- **No budget cap** — completion, not velocity, is the metric.

---

## §1 — Owner-Decisions Ratified (2026-07-13)

Owner responded 2026-07-13 with 5 explicit decisions:

| # | Topic | Decision | Implementation |
|---|---|---|---|
| 1 | Tag discipline | **"v1.0.1 ile devam"** — continue with v1.0.1; do NOT introduce v1.0.2 | Move (force-push) v1.0.1 tag to template current HEAD `43592c24` so the tag reflects live state. Re-tag launcher at HEAD `b0d820da` as v0.3.0. |
| 2 | Wave 2 priority | **ADR FIRST** (owner flip of arch opinion #4 which recommended d-tests-first) | S29-006 lands BEFORE S29-007. d-test ports cite ported ADRs as their ADR-anchored reference (per ADR-0055 §Cadence Rule 1). |
| 3 | Sprint 29 scope | **No cap, no other work in 29** | Sprint 29 is dedicated gap-closure; side-quests (C-03..07/10, sprint-archive scripts, agent-watch-verdicts refinements, etc.) deferred to Sprint 30+ |
| 4 | Category C scope | **Only gap-closing Category C items** | C-08 ISSUE_TEMPLATE port (gap: AtilCalc has 7, template has 0), C-09 docs/sprints/ skeleton (gap: template lacks sprint plan layout), C-01/02 launcher board bootstrap (gap: Step 6b manual). Others (C-03..07/10) → Sprint 30+ |
| 5 | Self-hosted-only deployment | **All template projects + launcher use self-hosted runner only, no Actions billing dependency** | (a) All 7 stock workflows migrate to `runs-on: [self-hosted, Linux, X64, atilproject]` (S29-001, now load-bearing critical); (b) Launcher auto-applies 4-tuple on bootstrap (eliminates Step 5b workaround in new-projectsteps.md, makes it redundant); (c) No template workflow ever burns Actions minutes on private repos |

---

## §2 — Sprint Capacity + Boundary

| Field | Value |
|---|---|
| Length | 2 weeks (2026-07-13 → 2026-07-27, Mon → Fri following week) |
| Capacity cap | **None** (owner directive #3) |
| Scope boundary | **Gap-closure only** (owner directive #3) |
| Definition of Done (sprint-level) | Sprint 28 audit doc §0 TL;DR table re-fetched post-portage: all gap percentages drop from ~60% to ≤5% residual |
| Anti-pattern guard | Stories that don't close an audit-finding gap go to Sprint 30+ regardless of perceived "small win" |

---

## §3 — Story Inventory (detailed)

> **Each story has Acceptance Criteria (ACs), sister-pattern refs, deps,
> and explicit Done-Means. AC counts follow ADR-0049 (≥5 TCs for behavioral
> stories; ≥3 TCs for hygiene/docs).**

---

### Wave 1 — Hygiene (Week 1, blocking)

#### **S29-001 — Migrate 7 template stock workflows to self-hosted 4-tuple**

| Field | Value |
|---|---|
| Effort | S (small, ~1 PR) |
| Owner agent | architect (per PM lane: `.github/workflows/**` = arch + tester draft + owner merge) |
| Audit ref | §5.2 (Q3 finding); §6.2 B-03 |
| Load-bearing | **YES** (owner directive #5 — sprint-blocks if not green) |
| Sister-pattern | AtilCalculator .github/workflows/*.yml (all 11 self-hosted); ADR-0030 (self-hosted-runner LAN deploy) |
| Source finding | 7/8 template stock workflows use `runs-on: ubuntu-latest`; only `deploy.yml.tmpl` is self-hosted. Private repos burn free-tier Actions minutes. |
| Blocks | S29-013 (launcher 4-tuple auto-apply) — needs 4-tuple as canonical pattern reference |

**Acceptance criteria:**
1. **AC1**: For each of `{ai-pr-review.yml, ci.yml (lint-and-test + conventional-commits jobs), cross-repo-close.yml, label-check.yml, label-cleanup.yml, secret-canary.yml, status-label-to-board.yml}`, the `runs-on:` line reads exactly `runs-on: [self-hosted, Linux, X64, atilproject]` (4-tuple, not 3-tuple, not string).
2. **AC2**: `deploy.yml.tmpl` keeps its existing `runs-on: self-hosted` (no regression; current behavior preserved).
3. **AC3**: `grep -E "runs-on:" .github/workflows/ | sort -u` returns exactly 2 distinct values: `runs-on: [self-hosted, Linux, X64, atilproject]` and `runs-on: self-hosted`.
4. **AC4**: At least 1 sample workflow opens a draft PR; CI fires on self-hosted runner (verify Actions run shows `runner.name: github-runner-vm*`); no `runs-on: ubuntu-latest` job executed.
5. **AC5**: d-test (new, per ADR-0049 ≥5 TCs): `scripts/tests/s29-001-workflow-self-hosted.sh` validates 4-tuple on every `.github/workflows/*.yml` (NOT `*.tmpl`).
6. **AC6**: Concurrency groups + secrets references unchanged (only `runs-on:` line modified, nothing else).
7. **AC7**: Backward-compat note added to template README: "Self-hosted runner label requirements: `[self-hosted, Linux, X64, atilproject]`. Register with `./config.sh --labels self-hosted,Linux,X64,atilproject ...`."

**Done means:** PR merged to template main, AC1-AC7 met, d-test green on self-hosted runner. AC verification command: `grep -L "runs-on: \[self-hosted, Linux, X64, atilproject\]" .github/workflows/*.yml | grep -v .tmpl` returns empty.

---

#### **S29-002 — Move v1.0.1 tag to current template HEAD + add v0.3.0 tag to launcher HEAD**

| Field | Value |
|---|---|
| Effort | S (trivial, 2 commands) |
| Owner agent | orchestrator (per docs/sprints/** + script PR lane) |
| Audit ref | §9 (Q7 finding); §6.2 B-01, B-02 |
| Sister-pattern | AtilCalculator tag discipline (`git tag -fa <name> <sha>` for force-forward); ADR-CLOSED semver policy (per Issue cluster precedent) |
| Source finding | Template v1.0.1 @ `62aec11b` (2026-07-09) is 6 PRs behind HEAD `43592c24` (2026-07-11, PRs #64-69 = Sprint 28 forward-port series). Launcher HEAD `b0d820da` claims v0.3 in commit message but no tag exists. |

**Acceptance criteria:**
1. **AC1**: `git ls-remote --tags atilproject/dev-studio-template | grep v1.0.1` returns object SHA = current HEAD `43592c24`.
2. **AC2**: `git ls-remote --tags atilproject/dev-studio-launcher | grep v0.3` returns non-empty (v0.3.0 tag exists at HEAD `b0d820da`).
3. **AC3**: Existing v1.0.0 / v0.2.0 tags preserved (only the live "current" tags move forward; legacy tags stay as historical anchors).
4. **AC4**: Force-push is explicitly authorized in PR description (`This PR force-moves v1.0.1 tag to current HEAD; v1.0.0 preserved as historical anchor; rationale: owner directive #1 'v1.0.1 ile devam'`).
5. **AC5**: Tag-move PR closes a single issue / links to `00-plan.md` §S29-002 (cross-traceability).

**Done means:** Both tag moves verified via `gh api /repos/.../git/refs/tags` + `/git/tags/<name>` (annotated tag resolves to commit SHA). Audit doc §9.3 verdict updates from "🔴 owner intuition confirmed" to "✅ tag discipline restored".

---

#### **S29-003 — Update launcher + README URLs (atilcan65 → atilproject)**

| Field | Value |
|---|---|
| Effort | XS (5 line changes) |
| Owner agent | developer (per launcher = scripts/ lane) |
| Audit ref | §7.2 (Q5 finding); §6.2 B-04, B-05 |
| Sister-pattern | d095 (`post-org-migration-clone-urls.sh`) — atilcan65→atilproject hygiene precedent in AtilCalculator |
| Source finding | Launcher `new-project.sh` line 19 hardcodes `atilcan65/dev-studio-template` + `DEFAULT_OWNER="atilcan65"`. Launcher README has 6 atilcan65 URLs (lines 3, 14, 16, 41, 50, etc.). Both function correctly via GitHub alias but document-hygiene needs update. |

**Acceptance criteria:**
1. **AC1**: `new-project.sh` line 19 changes to `TEMPLATE_REPO="atilproject/dev-studio-template"` + `DEFAULT_OWNER="atilproject"`.
2. **AC2**: `new-project.sh --help` output reflects `atilproject` defaults.
3. **AC3**: Launcher README replaces all `atilcan65/dev-studio-template` and `atilcan65/dev-studio-launcher` URLs with `atilproject/...` URLs.
4. **AC4**: ADR-0016 link in README resolves to new canonical (atilproject) URL.
5. **AC5**: d-test (new, ≥3 TCs): `scripts/tests/s29-003-url-hygiene.sh` greps launcher for any residual `atilcan65` references, fails on match.

**Done means:** PR merged to launcher main; new-project.sh + README atilcan65-free; d-test green.

---

#### **S29-004 — Fix template's status-label-to-board.yml (disable OR create Projects v2 board)**

| Field | Value |
|---|---|
| Effort | S (2-line YAML change OR 1 board-create API call) |
| Owner agent | architect (workflow lane) |
| Audit ref | §3.1 (Q1 finding); §6.2 B-06 |
| Sister-pattern | AtilCalculator status-label-to-board.yml (working version); ADR-0013 (board sync doctrine) |
| Source finding | Template's own status-label-to-board.yml fails because template repo has no Projects v2 board configured. Workflow tries to push label updates to non-existent project. |

**Acceptance criteria:**
1. **AC1**: Decide disable-vs-create (default: disable with documented rationale; create is fallback if owner prefers).
2. **AC2 (if disable)**: Workflow file gets a top-comment: `# Disabled for template repo — no Projects v2 board configured. Re-enable when downstream projects have their own board (see ADR-0013 + new-projectsteps Step 6b).` + workflow body wrapped in `if: false` or workflow file moved to `.disabled/`.
3. **AC2 (if create)**: Projects v2 board created via `gh project create --name "Template Triage"` + workflow job updated with new board ID.
4. **AC3**: Recent Actions run history (post-fix) shows: status-label-to-board.yml jobs succeeding OR marked as skipped/disabled, not failing.
5. **AC4**: At least 1 sister-issue filed: "Re-enable status-label-to-board.yml after downstream project boards are bootstrapped" (so the disable isn't forgotten).

**Done means:** Template repo's Actions tab no longer shows status-label-to-board.yml failing on issue events.

---

#### **S29-005 — Verify-portage recipe (executable, owner-runnable per §4.6)**

| Field | Value |
|---|---|
| Effort | S (1 script + 1 d-test) |
| Owner agent | developer (scripts lane) |
| Audit ref | §4.6 (Q2 verification recipe) |
| Sister-pattern | §4.6 bash script in audit doc (already drafted); ADR-0049 (d-test framework) |
| Source finding | Audit doc §4.6 has a bash recipe to render template + diff against AtilCalculator. It needs to be executable + version-controlled + d-tested. |

**Acceptance criteria:**
1. **AC1**: New script `scripts/verify-portage.sh` in template (executable, error codes 0/1).
2. **AC2**: Script accepts `--owner <owner>` + `--name <project-name>` + `--dir <parent>` flags; defaults match launcher's defaults.
3. **AC3**: Script flow: create private repo from template → run `e2e-pilot.sh` + `faz5-smoke.sh` + `state-schema-smoke.sh` → diff `scripts/`, `.github/workflows/`, `docs/decisions/`, `.claude/` against a configurable reference (default: `~/projects/AtilCalculator`) → emit gap report → cleanup via `gh repo delete --yes`.
4. **AC4**: d-test (new, ≥5 TCs per ADR-0049): `scripts/tests/s29-005-verify-portage.sh` validates script flags exist, syntax-check, dry-run mode (`--dry-run` flag), error code on missing deps.
5. **AC5**: Script documentation in `scripts/README.md` (or new doc): intended use = "after Sprint 29 Wave 2 lands, run this script to confirm portage gap ≤ 5%".
6. **AC6**: Script + d-test land in template via single PR.

**Done means:** `bash scripts/verify-portage.sh --help` works; `--dry-run` exits 0 without side effects.

---

### Wave 2 — Portage (Week 1-2, depends on Wave 1)

#### **S29-006 — Forward-port 40+ universal ADRs (ADR FIRST per owner #2)**

| Field | Value |
|---|---|
| Effort | L (large, batched as 3-4 PRs by theme) |
| Owner agent | architect (per docs/decisions/** lane) |
| Audit ref | §4.2 (Q2 ADR gap); §6.1A |
| Sister-pattern | AtilCalculator ADR-0001 through ADR-0071 (currently 74 entries; ~40 universal port-worthy); ADR-0050 (load-bearing ADR doctrine) |
| Source finding | Template ADRs (16): 0010, 0011, 0012, 0013, 0014, 0015, 0016, 0020, 0021, 0024, 0025, 0026, 0027, 0030, 0046, 0047. Missing: 0001, 0002, 0031, 0032-0045, 0048, 0049, 0050, 0052-0071 (~40 universal + a few project-specific duplicates). |

**Acceptance criteria:**
1. **AC1**: Diff `docs/decisions/` between template HEAD and AtilCalculator main; produce list of missing ADRs categorized as "universal port-worthy" vs "project-specific stay".
2. **AC2**: Universal ADRs ported in 3-4 themed PRs (themes suggested: agent-and-lane doctrine / verdict-and-board / cross-repo-and-runner / d-test-and-quality-gates).
3. **AC3**: Each ported ADR has its frontmatter updated to reflect template-repo provenance (cross-repo ADR references updated per ADR-0045 §Lens (j) — auto-generated file refs + live-state verification).
4. **AC4**: ADR INDEX.md regenerated with both AtilCalculator-unique and template-unique ADRs visible (post-portage ADRs from AtilCalculator live in template, listed in template INDEX).
5. **AC5**: d-test (new, ≥5 TCs per ADR-0049): `scripts/tests/s29-006-adr-port-parity.sh` asserts each ported ADR resolves its cross-references (no broken `ADR-XXXX` links).
6. **AC6**: ADR-0024 namespace collision resolved (template's existing ADR-0024 = stale-verdict-watchdog-schema; AtilCalculator amendments add 2 more = auto-verdict-by-hook + stale-verdict-supersede). Template ends up with 3 ADR-0024-* files matching AtilCalculator structure.
7. **AC7**: Sister-pattern post-mortem per d-test d986 (adr-index-uniqueness): no duplicate ADR numbers in template post-portage.

**Done means:** ~40+ ADRs ported; ADR INDEX parity ≥ 95%; d-test green. Audit doc §4.2 "58 missing" count drops to ≤ 5.

---

#### **S29-007 — Forward-port 80+ universal d-tests (AFTER S29-006 per owner #2)**

| Field | Value |
|---|---|
| Effort | L (large, batched as 5-6 PRs by theme) |
| Owner agent | developer (per scripts/tests/** lane) |
| Audit ref | §4.3 (Q2 d-test gap); §6.1A |
| Sister-pattern | AtilCalculator d-tests (131 files); ADR-0049 (d-test framework ≥5 TCs baseline); ADR-0055 (d-test ID uniqueness) |
| Source finding | Template d-tests (21 files); AtilCalculator has 131. Gap = ~110 (80+ universal port-worthy, ~25-30 project-specific stay). |

**Acceptance criteria:**
1. **AC1**: d-test ported in 5-6 themed PRs (themes suggested: agent-watch-behavioral / verdict-detection / cross-repo / label-invariant / issue-mirror / sprint-flow).
2. **AC2**: Each ported d-test runs green on self-hosted runner (post-S29-001 migration).
3. **AC3**: d-test ID uniqueness preserved (no collisions with template's existing IDs, per ADR-0055).
4. **AC4**: `scripts/tests/INDEX.md` regenerated with both AtilCalculator-unique and template-unique d-tests visible.
5. **AC5**: `bash scripts/tests/e2e-pilot.sh` exits 0 post-portage; `bash scripts/tests/faz5-smoke.sh` exits 0; `bash scripts/tests/state-schema-smoke.sh` exits 0.
6. **AC6**: Sister-pattern: each d-test maintains ≥3 TCs (hygiene-only docs PRs) or ≥5 TCs (behavioral workflow PRs) per ADR-0049.

**Done means:** ~80+ d-tests ported; INDEX parity ≥ 95%; e2e-pilot + faz5-smoke + state-schema-smoke green. Audit doc §4.3 "110 missing" count drops to ≤ 10.

---

#### **S29-008 — Forward-port 5+ missing top-level scripts**

| Field | Value |
|---|---|
| Effort | M (medium, 1 batched PR) |
| Owner agent | developer (scripts/ lane) |
| Audit ref | §4.4 (Q2 scripts gap) |
| Sister-pattern | AtilCalculator scripts/ (38+ files); project-specific filters: exclude `run-server.sh` (calc-engine specific), `ops/apply-vm-hardening.sh` (vm-specific) |
| Source finding | Template scripts: 33. AtilCalculator: 38+. Missing universal: `agent-watch-verdicts.sh`, `audit-project-refs.sh`, `cross-repo-scan.sh`, `lint-notify-invocations.sh`, `proactive-board-scan.sh`, `strip-cascade-labels.sh`, `init-template-repo.sh`. |

**Acceptance criteria:**
1. **AC1**: 5-7 universal scripts ported as a single PR.
2. **AC2**: Project-specific scripts (`run-server.sh`, `ops/apply-vm-hardening.sh`) NOT ported (stay in AtilCalculator).
3. **AC3**: Each ported script has any AtilCalculator-specific paths/IDs parameterized (or pointed at `atilproject` org as canonical).
4. **AC4**: d-test (per-port, ≥3 TCs each): syntax-check + help-text output + idempotency check.

**Done means:** Scripts ported; per-script d-tests green; scripts-directory parity ≥ 90%.

---

#### **S29-009 — Forward-port 3 missing scripts/ sub-dirs**

| Field | Value |
|---|---|
| Effort | M (medium, sub-dirs have multiple files) |
| Owner agent | developer (scripts/ lane) |
| Audit ref | §4.4 (Q2 sub-dir gap) |
| Sister-pattern | AtilCalculator sub-dirs: install/, kickoff/, post-squash/, pre-push/ |
| Source finding | Template scripts/: only top-level files + `tests/` + `install/`. Missing: kickoff/, post-squash/, pre-push/. |

**Acceptance criteria:**
1. **AC1**: 3 sub-dirs ported: `kickoff/` (5 agent txt files: orchestrator, PM, arch, dev, tester), `post-squash/` (cluster-lag-detector.sh + label-hygiene.sh), `pre-push/` (branch-base-check.sh).
2. **AC2**: AtilCalculator-specific `install/systemd/dev-studio-watcher@.service` NOT ported (template has its own systemd); AtilCalculator-specific `ops/` (vm-hardening) NOT ported.
3. **AC3**: Each sub-dir's README (if any) updated to template-canonical language.

**Done means:** Sub-dirs present in template; pre-push hook usable (per AtilCalculator CLAUDE.md §branch protection).

---

#### **S29-010 — Forward-port 3 missing workflows + render deploy.yml from .tmpl**

| Field | Value |
|---|---|
| Effort | M (medium) |
| Owner agent | architect (workflows lane) |
| Audit ref | §4.5 (Q2 workflows gap); §5.3 (smoke repo's stock workflows) |
| Sister-pattern | AtilCalculator workflows; ADR-0047 (deploy pattern); .github/workflows/ ownership matrix (human-only territory, owner approval required for rename) |
| Source finding | Template workflows: 8 (one `.tmpl`). Missing: `d050b-dispatch.yml`, `lint-and-test.yml`, `post-squash.yml`, plus render `deploy.yml` from `deploy.yml.tmpl` per owner approval. |

**Acceptance criteria:**
1. **AC1**: 3 workflow files ported: `d050b-dispatch.yml`, `lint-and-test.yml`, `post-squash.yml`.
2. **AC2**: `deploy.yml.tmpl` rendered to `deploy.yml` per owner approval (per CLAUDE.md §File ownership matrix — `.github/workflows/` is human-only territory; orchestrator proposes, owner approves).
3. **AC3**: All 4 newly-added/updated workflows pass through S29-001's `runs-on: [self-hosted, Linux, X64, atilproject]` migration.
4. **AC4**: Per-workflow d-test: each workflow YAML lints + has at least 1 sample PR to validate CI fires correctly.

**Done means:** Template workflows count = 12 (8 stock + 4 new/rendered); all self-hosted; deploy.yml ready for production use.

---

### Wave 2B — Gap-closing Category C (Week 2, parallel)

#### **S29-011 — Port 7 ISSUE_TEMPLATE from AtilCalculator (gap-closing)**

| Field | Value |
|---|---|
| Effort | S (1 PR) |
| Owner agent | developer (.github/ISSUE_TEMPLATE/ per PM-lane-adjacent) |
| Audit ref | §6.3 C-08 (Category C: gap-closing) |
| Sister-pattern | AtilCalculator `.github/ISSUE_TEMPLATE/` (7 templates: bug_report, feature_request, vision_intake, etc.); ADR-0012 (4-cat label set in templates) |
| Source finding | Template has NO `.github/ISSUE_TEMPLATE/` directory. AtilCalculator has 7 (per Q4 finding C-08). |

**Acceptance criteria:**
1. **AC1**: 7 issue templates ported (bug, feature, vision, story, retro, sprint, ?).
2. **AC2**: Each template has 4-cat label section per ADR-0012 (type/status/agent/cc checkboxes or pre-fills).
3. **AC3**: `gh issue create --template <name>` works in a downstream project post-portage.
4. **AC4**: d-test (new, ≥3 TCs): validates each template YAML frontmatter + 4-cat section presence.

**Done means:** `.github/ISSUE_TEMPLATE/` exists in template; 7 templates lint clean; downstream project owners see "Issue templates" choice in `gh issue create --help`.

---

#### **S29-012 — Add docs/sprints/ skeleton to template (gap-closing)**

| Field | Value |
|---|---|
| Effort | S (1 PR) |
| Owner agent | orchestrator (docs/sprints/** lane) |
| Audit ref | §6.3 C-09 (Category C: gap-closing) |
| Sister-pattern | AtilCalculator `docs/sprints/sprint-28/` + `current/plan.md` symlink; this very `00-plan.md` (Sprint 29 plan used as the template's bootstrap example) |
| Source finding | Template lacks `docs/sprints/` entirely. Downstream projects improvise sprint layout. |

**Acceptance criteria:**
1. **AC1**: `docs/sprints/skeleton.md` added (a fill-in-the-blanks sprint plan template).
2. **AC2**: `docs/sprints/current/plan.md.tmpl` added (renders to `current/plan.md` per `dev-studio-init.sh`).
3. **AC3**: Sprint closeout structure documented (`docs/sprints/sprint-NN/{plan.md, retrospective.md, close.md}`).
4. **AC4**: `dev-studio-init.sh` updated (if needed) to render the new skeleton.
5. **AC5**: d-test (new, ≥3 TCs): validates skeleton markdown frontmatter + 4 sections.

**Done means:** Downstream `new-project.sh` bootstraps a usable sprint skeleton; first `sprint-00/` follows the same shape.

---

#### **S29-013 — Launcher auto-applies self-hosted 4-tuple on bootstrap (per owner #5)**

| Field | Value |
|---|---|
| Effort | S (1 PR to launcher) |
| Owner agent | developer (launcher scripts/) |
| Audit ref | §6.2 B-03 (template side); §5.2 (Q3); owner directive #5 |
| Sister-pattern | S29-001 (template-side 4-tuple) + AtilCalculator's self-hosted-only pattern; new-projectsteps.md Step 5b (currently manual workaround — becomes obsolete) |
| Source finding | Current new-projectsteps.md Step 5b is a manual `sed -i` workaround applied by user post-bootstrap. Owner directive #5 makes self-hosted-runner-only an automatic default, not a manual patch. |

**Acceptance criteria:**
1. **AC1**: New step added to `new-project.sh` after bootstrap-labels.sh: `apply_self_hosted_runner_patch()` runs `sed -i` on all stock workflows per the Step 5b snippet.
2. **AC2**: New step is idempotent (re-run safe — only patches workflows still on `ubuntu-latest`).
3. **AC3**: `gh api repos/<owner>/<name>/actions/runners` check BEFORE the patch: if no runners match the 4-tuple, warn user loudly ("self-hosted runner not registered; CI will queue forever until registered").
4. **AC4**: d-test (new, ≥5 TCs): patch idempotency + regex correctness + warning emission.
5. **AC5**: new-projectsteps.md Step 5b removed (replaced with "auto-applied at Step 3; verify with `grep` if you want").

**Done means:** New `new-project.sh` bootstrap → every workflow self-hosted by default; no manual Step 5b needed; Sprint 29 plan check.

---

### Wave 3 — Verification (Week 2, final)

#### **S29-014 — Verify-portage execution against post-portage template**

| Field | Value |
|---|---|
| Effort | S (run script + read output) |
| Owner agent | orchestrator |
| Audit ref | §4.6 (Q2 verification); S29-005 (script) |
| Sister-pattern | S29-005 (recipe script) |
| Source finding | Sprint 28 audit doc claims ~60% portage gap. S29-014 verifies this drops to ≤ 5% residual. |

**Acceptance criteria:**
1. **AC1**: Run `bash scripts/verify-portage.sh` (from S29-005) end-to-end.
2. **AC2**: Capture output diff in `docs/sprints/sprint-29/01-portage-verify.md`.
3. **AC3**: Gap report shows ≤ 5% residual (≤ 5 ADRs + ≤ 5 d-tests + ≤ 5 scripts missing). If > 5%, open follow-up stories for Sprint 30+ (audit not complete → stay in 29 only if gap-closing; else Sprint 30).
4. **AC4**: Owner ratifies the verification report before Sprint 29 close (per ADR-0031 owner-merge-gate).

**Done means:** Sprint 29 closes with documented ≤ 5% residual gap; owner ratifies report.

---

#### **S29-015 — Re-render `new-projectsteps.md` + audit doc §10 (final)**

| Field | Value |
|---|---|
| Effort | S (1 PR) |
| Owner agent | orchestrator (docs/ lane) |
| Audit ref | Q6, Q7; this plan doc itself (Sprint 29 docs) |
| Sister-pattern | ADR-0050 (load-bearing ADR doctrine: docs re-render after doctrine changes); the doc's own §Post-Sprint-29 update checklist (drift-prevention pattern, arch obs #8) |
| Source finding | Post-portage, new-projectsteps.md Step 5b is obsolete (auto-applied by S29-013). Tag discipline references (v1.0.1 = current HEAD) update. Audit doc §10.2 plan committed. |

**Acceptance criteria:**
1. **AC1**: new-projectsteps.md Step 5b removed (auto-applied now).
2. **AC2**: Tag discipline section updated (v1.0.1 = current HEAD per S29-002; no "stale" notes).
3. **AC3**: Audit doc §10.2 updated: "Sprint 29 plan EXECUTED (2026-07-27)" + link to this 00-plan.md + link to S29-014 verification report.
4. **AC4**: Post-Sprint-29 update checklist removed (self-aware sunset per arch obs #8 — the doc no longer has sunset conditions because the sunset happened).
5. **AC5**: d-test (existing, re-run): `d113-markdown-internal-links.sh` to validate re-rendered links.

**Done means:** Sprint 29 docs reflect post-portage reality; sunset checklist disappears; one final PR merges to main.

---

## §4 — Sequencing (Wave diagram)

```
Week 1:
  S29-001 (workflow self-hosted, load-bearing) ─┐
  S29-002 (v1.0.1 tag move)                    ├─→ all 5 can run in parallel
  S29-003 (URL hygiene, trivial)               │
  S29-004 (status-label-to-board fix)          │
  S29-005 (verify-portage script)              │
                                              │
Week 1-2:                                     ▼
  S29-006 (40+ ADRs port, FIRST per #2)  ──→  S29-007 (80+ d-tests port, AFTER)
  S29-008 (scripts port)              ──┐
  S29-009 (sub-dirs port)             ──┼─→ parallel
  S29-010 (workflows + deploy.yml)    ──┘
                                       │
                                       │
Wave 2B (parallel with Wave 2):         │
  S29-011 (ISSUE_TEMPLATE port)        │
  S29-012 (docs/sprints/ skeleton)     │
  S29-013 (launcher self-hosted auto) ─┘ (depends on S29-001 4-tuple being defined)
                                          │
                                          │
Week 2 final:                             ▼
  S29-014 (verify-portage execution)  ←── [S29-006 + S29-007 + S29-008 + S29-009 + S29-010 + S29-011 + S29-012 + S29-013 all done]
  S29-015 (docs re-render)         ──→ AFTER S29-014

Sprint 29 close: 2026-07-27 (Fri)
Definition of Done: ALL ACs met + S29-014 report ratified by owner + S29-015 merged
```

---

## §5 — Dependency Graph (text)

```
S29-001 ─→ S29-013 ─→ S29-014 ─→ S29-015
       └─→ S29-007 (test ports need self-hosted runner reference)

S29-002 ── independent (pure git tag ops)

S29-003 ── independent (URL hygiene, no behavior change)

S29-004 ── independent (workflow self-disable OR board create)

S29-005 ── independent (script authoring; S29-014 is the consumer)

S29-006 ─→ S29-007 (ADR-anchored references per ADR-0055 §Cadence Rule 1)

S29-008 ── independent (script port, no other S29 deps)

S29-009 ── independent (sub-dir port, no other S29 deps)

S29-010 ── depends on S29-001 (new workflows inherit self-hosted 4-tuple)

S29-011 ── independent (YAML port, no runtime deps)

S29-012 ── depends on dev-studio-init.sh understanding new skeleton (small tweak in init script likely)

S29-013 ── depends on S29-001 (4-tuple is the canonical self-hosted pattern)

S29-014 ── depends on all Wave 1 + Wave 2 + Wave 2B done

S29-015 ── depends on S29-014 verification report
```

---

## §6 — Definition of Done (sprint-level)

Sprint 29 closes successfully when:

1. **All 15 stories** (S29-001 through S29-015) merged to respective repos (template / launcher / both).
2. **`bash scripts/verify-portage.sh` from S29-005** runs end-to-end against post-portage template + AtilCalculator reference, emits gap report with **≤ 5% residual**.
3. **`docs/sprints/sprint-29/01-portage-verify.md`** captures the S29-014 run output and is ratified by owner per ADR-0031.
4. **Audit doc §10** updated to reflect Sprint 29 outcomes (S29-015 closes the cycle).
5. **Template stock workflows = 100% self-hosted** (verified by `grep runs-on:` per S29-001 AC3).
6. **Tags restored** to live HEAD (v1.0.1 = template HEAD, v0.3.0 = launcher HEAD per S29-002).
7. **Sprint 30 plan drafted** (orchestrator, by Sprint 29 close) — captures deferred Category C items (C-03/04/05/06/07/10) and any residual > 5% gap from S29-014.

**Sprint 29 failure modes (early-warning signals):**
- Wave 1 hygiene items don't land in week 1 → Wave 2 can't validate against self-hosted-only profile
- S29-006 (ADRs) reveals insufficient cross-repo reference hygiene → S29-007 blocked until reference cleanup
- S29-010 deploy.yml render needs owner approval (per CLAUDE.md file ownership matrix) → if owner delays, Sprint 29 close slips
- Sprint 29 close (2026-07-27) hits before S29-014 verifiability → owner must decide to extend or close-with-exception

---

## §7 — Owner-Approval Requirements Mid-Sprint

| Story | Requires owner approval (per doctrine) |
|---|---|
| S29-001 | Architect PR review (per arch lane); CI gate enforces |
| S29-002 | **Yes — owner merges the tag-force-push PR** (destructive operation) |
| S29-003 | Trivial, dev lane |
| S29-004 | Optional — arch lane can decide disable vs create, owner informed |
| S29-005 | d-test coverage; orchestrator lane |
| S29-006..010 | Arch / dev lane; arch PR reviews |
| S29-010 specifically | **Yes — `.github/workflows/deploy.yml` is human-only territory** (per CLAUDE.md §File ownership matrix); arch proposes, owner approves the rename |
| S29-011..012 | Dev / orch lane; CC arch + PM per lane |
| S29-013 | Dev lane + orchestrator co-review (cross-repo launch + template behavior) |
| S29-014 | **Yes — owner ratifies verification report** (closes sprint) |
| S29-015 | Docs-only; PM cc per docs/sprints |

**Owner-decision checkpoints:**
- Day 3 of Sprint 29: Are Wave 1 hygiene items green? (If not, replan)
- Day 7 of Sprint 29: Are Wave 2 ADRs (S29-006) merged? (Sprint 29 cannot close without them)
- Day 9 of Sprint 29: Owner ratified S29-014 verification report?
- Day 10 of Sprint 29: Sprint 30 plan drafted + ratified?

---

## §8 — Cross-References

- **Audit source:** `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` (PR #1008, status:ready)
- **Owner-decisions response:** cycle ~#1160 (2026-07-13)
- **Companion operational doc:** `docs/new-projectsteps.md` (re-rendered post-Sprint-29 via S29-015)
- **AtilCalculator reference (port-source):**
  - `~/.claude/CLAUDE.md` (doctrine)
  - `docs/decisions/INDEX.md` (74 ADRs; ~40 universal port-worthy)
  - `scripts/tests/` (131 d-tests; ~80 universal port-worthy)
  - `.github/workflows/` (11 workflows; all self-hosted)
- **Self-hosted runner pattern:** `[self-hosted, Linux, X64, atilproject]` (8 runners online, verified 2026-07-13)
- **Sister-patterns:**
  - **S29-001** — AtilCalculator workflow self-hosted migration (was Sprint 27 priority)
  - **S29-002** — AtilCalculator tag discipline precedent (PRs #63 + #967)
  - **S29-006** — ADR-0050 (load-bearing ADR doctrine)
  - **S29-013** — new-projectsteps.md Step 5b workaround (becomes obsolete)

---

## §9 — Sprint 29 Retrospective Template (for close.md)

After Sprint 29 closes, sprint close doc should capture:

1. **Wave adherence:** Did each story land in its planned wave?
2. **Story count actual vs planned:** 15 stories planned; actual count from PRs merged.
3. **ADR / d-test / script / workflow deltas:** How many ported, how many residual?
4. **Self-hosted runner impact:** Did S29-001 + S29-013 actually achieve zero Actions-minutes burn on a private-repo downstream?
5. **Tag discipline restored:** Did owners stop seeing stale files (Q7 intuition)?
6. **Category C deferred items:** What got punted to Sprint 30+? Were they the right calls?
7. **Owner-decision calibration:** 5 owner-decisions all answered in 1 message — is that the new normal, or did we under-ask?
8. **Audit-of-audit self-check (per arch obs #3):** Was the F-08 candidate confirmed? Should it join the W3 retro cluster?

---

— @orchestrator, 2026-07-13T06:30:00Z (cycle ~#1159), Sprint 29 plan drafted
post owner 5-decision response. All 15 stories have detailed ACs per
ADR-0049. Sprint boundary: gap-closure only, no cap (owner directive #3).
Self-hosted-runner-only is load-bearing (owner directive #5). PR #1008
extended with this plan + audit-doc §10 link update.

Ready for Sprint 29 kickoff AFTER owner squash-merge of PR #1008 (per
ADR-0031). Sprint 29 start date: 2026-07-13 (immediate, parallel to merge)
or 2026-07-14 (next business day) — owner choice.
