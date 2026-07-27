# Sprint 35 Pre-GO Org-Wide Readiness Audit and Gap-Closing Plan

> **Status:** **OWNER REVIEW REQUIRED — NO IMPLEMENTATION AUTHORIZED**
>
> **Owner directive:** "Bu audit sadece durum tespiti, ben okumadan hiçbir aksiyon alma." → Read, comment, route to team review. No PR merges, no new issues, no template/launcher mutation before owner GO.
>
> **Audit date:** 2026-07-27
> **Branch:** `audit/sprint-35-org-readiness` (off `origin/main` @ `4793fea`)
> **Evidence method:** Read-only REST audit (`gh api` over REST, no GraphQL dependency), local default-branch clones of all 5 live repos at HEAD, byte-equivalence diff for parity, fresh local execution of 41 d-tests in the template clone.

---

## 0. TL;DR — owner-facing answer table

| # | Question | Verdict | Confidence | Evidence section |
|---|---|---|---|---|
| **Q1** | Can `dev-studio-template` currently create and run any private project in `atilproject`? | **READY-PENDING-FIRST-EXECUTION** | MEDIUM | §1 |
| **Q2** | Have all non-calculator scripts/processes/doctrine/agents been transferred from AtilCalculator to template/launcher? | **NO — 3 P0 + 12 P1 gaps remain** | HIGH | §2 |
| **Q3** | Is self-hosted-runner migration 100% complete? Do any GitHub-hosted runner paths remain? | **NOT 100%** — 2 specific gaps | HIGH | §3 |
| **Q4** | If template is complete, what else should be added now that focus is template-only? | See §4 — 4 recommended additions | MEDIUM | §4 |
| **Q5** | Is `dev-studio-launcher` still ready to create a new fully featured project? | **READY, with caveats** | HIGH | §5 |
| **Q6** | Detailed `new-project-steps` runbook | Delivered as sibling file: `new-project-steps.md` | HIGH | §6 |
| **Q7** | Is GitHub's live `dev-studio-template` actually updated? Why might files still look old? | **YES live + matched**; per-file aging listed | HIGH | §7 |

**Owner decision required:** GO / NO-GO on Sprint 35 execution. See §8 decision register.

---

## 1. Q1 — Private-project readiness (template)

### Proven (live evidence, 2026-07-27)

- **`is_template=true`** on `atilproject/dev-studio-template` (REST `/repos/.../dev-studio-template`).
- **Org permits private repos**: `atilproject` org plan = `team`, `private_repos: 999999`, `owned_private_repos: 2`, `members_can_create_private_repositories: true`.
- **Launcher forwards `--private`** to `gh repo create --template atilproject/dev-studio-template --private --clone` (verified `new-project.sh:222, 333`).
- **`dev-studio-init.sh`** renders 8 placeholders, writes `PROJECT_TOKEN` via `gh secret set` with live HTTP 200 health check, dispatches `secret-canary.yml` and polls up to 90s — all verified on current `main` HEAD `0db078f`.
- **`disposable-bootstrap-test.yml`** is structurally complete: 2 jobs (public + private), private job gated `if: ${{ inputs.run_private == 'true' }}` + secret gate. Sister d-test `d-s34-004-disposable-bootstrap-test.sh` exits 0 with 10/10 GREEN locally.
- **Sister-pattern byte-equivalence** for 16 canonical scripts (`claim-next-ready.sh`, `bootstrap-labels.sh`, `bootstrap-project-board.sh`, `event-log.sh`, etc.) — TPL copies are byte-identical to AtilCalculator canonical sources per `d-s34-002-*-byte-equivalence.sh` GREEN.
- **Live CI on template HEAD `0db078f`**: `Lint & Test (d-tests)` + `CI` GREEN; `Deploy to production` RED (owner-gated by missing Variables — **expected**, ADR-0078 RCA in place; per ADR-0078 KILLED escalation).
- **On-server freshness**: fresh-clone `scripts/dev-studio-init.sh` MD5 (`d083064e9d94806e4f9626a2341a117e`) matches `https://raw.githubusercontent.com/.../dev-studio-init.sh` byte-for-byte; on-server content SHA `6d74c23b5415e2ecf9b4cc387400ec506eeca258` agrees. The owner is **not** looking at stale files; local view equals live `main`.

### Unproven / NOT VERIFIED end-to-end

- **`disposable-bootstrap-test.yml` workflow has ZERO recorded runs** on `main` (`gh api .../actions/workflows/320908746/runs?per_page=100` → `total_count: 0`). The workflow file was created `2026-07-26T21:16:35+03:00` and the d-test for its structure passes — but the workflow itself has never been invoked through `workflow_dispatch`.
- **No fresh real disposable repo was created or observed** during this audit. We did not trigger `gh workflow run`; doing so would mutate GitHub and was out of scope.
- **`OWNER_DISPOSABLE_PRIVATE_TOKEN` + `ATILPROJECT_DISPOSABLE_TOKEN` org secrets** state is unverifiable from this audit (admin scope required). Workflow has well-defined failure modes (private job bails on absent secret), but their *current* state in the org is unverified.
- **First disposable private run** has never succeeded in CI history. To upgrade from MEDIUM → HIGH confidence, owner must run `gh workflow run disposable-bootstrap-test.yml -f run_private=true` once and observe a green run.
- **`v1.0.1` is a draft GitHub Release**; `v1.0.1` tag is 96 commits behind `main`; `v1.1.0` tag is 36 commits behind. Anyone pinning to a tag will not see the current workflow + d-test.

### Q1 binary verdict

**VERDICT: USABLE for private project creation**, confidence **MEDIUM**.

The structural chain (`is_template=true` → launcher `--private` flag → `gh repo create ... --private` → `dev-studio-init.sh` render + `PROJECT_TOKEN` write + canary dispatch) is **fully in place on `main`**, verified by direct content + REST + d-test 10/10. The *private bootstrap path itself* is **structurally correct but NOT VERIFIED** end-to-end in CI history. Confidence: "READY-PENDING-FIRST-EXECUTION", not "PROVEN-IN-CI".

---

## 2. Q2 — Fresh forward-port parity (AtilCalculator → template + launcher)

### Counts (default-branch byte comparison)

| Metric | AtilCalculator | dev-studio-template | dev-studio-launcher |
|---|---|---|---|
| Operational files (after exclusion of `src/atilcalc/**`, `tests/{api,cli,engine,integration,web,docs}/`, calculator docs, `.dev-studio/`, worktrees, runtime state) | 282 | 268 | 12 |
| Files with AC equivalent (after `.tmpl` normalization) | — | 112 / 268 (41.8%) | 6 / 12 (50.0%) |

### P0 gaps (block canonical-template parity)

| # | Gap | Direction | Owner action |
|---|---|---|---|
| **P0-1** | **`.claude/CLAUDE.md.tmpl` was deleted from AtilCalculator** in `f6c2a9c0 chore: render templates and bootstrap project`. Was tracked through 2026-07-17 (commit `6b022d5c`). Canonical TPL still carries it. `dev-studio-init.sh` cannot re-render `.claude/CLAUDE.md` from a canonical source inside this repo. | back-port TPL → AC | restore `.tmpl` from canonical TPL HEAD |
| **P0-2** | **5 `.claude/agents/*.md.tmpl` files in AC are STALE** — missing the **Issue #287 ARCHIVE-CALL block (§Doctrine Reminder — no self-standby, 38 lines)** that canonical TPL carries. Any downstream project cloned from AC's current state will not get the doctrine reminder. Affected: `architect.md.tmpl`, `developer.md.tmpl`, `orchestrator.md.tmpl`, `product-manager.md.tmpl`, `tester.md.tmpl`. | back-port TPL → AC | pull canonical `.tmpl` for each role from TPL HEAD |
| **P0-3** | **`scripts/owner-apply-soul-patch.sh` is in TPL but MISSING in AC** — owner-only verifier that ensures Issue #287 Doctrine Reminder is in all 4 shared soul `.tmpl` files. Without it in AC, the P0-2 stale-tmpl problem has no enforcement gate at AC. | back-port TPL → AC | pull canonical script from TPL HEAD |

### P1 gaps (stale forward-port drift, silent divergence)

| # | Gap | Direction | Severity |
|---|---|---|---|
| **P1-1** | 5 `.claude/agents/*.md` (rendered) files in AC lack the **Issue #972 SOUL AMEND block** (Path-Verify Doctrine, sister-pattern TD-016/030). The rendered `.md` files are downstream — but they're what agents read first per ADR-0002 autonomy loop. | back-port TPL → AC | P1 |
| **P1-2** | `scripts/agent-stall-detect.sh` lives in AC, missing in TPL. Forward-port candidate (sprint 22 pivot followup, has d-stall-detect d-test). | forward-port AC → TPL | P1 |
| **P1-3** | `scripts/install/install-git-hooks.sh` lives in AC, missing in TPL. Sprint 22 pivot followup. | forward-port AC → TPL | P1 |
| **P1-4** | All **11 `.github/workflows/*.yml`** in AC diverge from canonical TPL. Workflows run on every PR — silent divergence accumulates hidden risk. Sister-pattern d-tests in TPL (`d-deploy-path-guard.sh`, `d-platform-constraint-linter.sh`) document the gap TPL-side only. | back-port TPL → AC | P1 |
| **P1-5** | `systemd/dev-studio-health.service.tmpl` lives in TPL but missing in AC (only `.timer` present). | back-port TPL → AC | P1 |
| **P1-6** | `.github/LABEL-TAXONOMY.md` (canonical label taxonomy doc) lives in TPL, missing in AC. | back-port TPL → AC | P1 |
| **P1-7** | `scripts/agent-state.sh`, `scripts/agent-watch.sh`, `scripts/deploy-runner.sh`, `scripts/dev-studio-init.sh`, `scripts/init-template-repo.sh`, `scripts/install/dev-studio-install-systemd.sh`, `scripts/notify.sh`, `scripts/ops/apply-vm-hardening.sh`, `scripts/orchestrator-gap-scan.sh`, `scripts/orchestrator-status-flip.sh`, `scripts/post-restart-label-guard.sh`, `scripts/post-squash/cluster-lag-detector.sh`, `scripts/proactive-board-scan.sh`, `scripts/status-action-driver.sh` — all diverge from canonical TPL. Sister d-tests in TPL document the gap. | back-port TPL → AC | P1 |
| **P1-8** | Sister-test d-tests in `scripts/tests/` (e.g., `d024-agent-wake.sh`, `d031-claim-next-ready.sh`, `d068b-tmux-send-keys-split-sleep.sh`, `e2e-pilot.sh`, `wip-idle-detect.sh`) diverge — TPL has older test; AC has newer. | back-port TPL → AC | P1 |

### P2/P3 gaps (cosmetic / informational)

- `docs/new-projectsteps.md` in AC is the AUTHORITATIVE 293-line source; `docs/new-project-steps.md` in TPL (222 lines) and LCH (154 lines) are derived/condensed. (P3, intentional mirror chain.)
- `scripts/tests/INDEX.md` exists in TPL under `scripts/tests/`; in AC under `scripts/tests/` too — but with different content (duplicate ownership with `docs/decisions/INDEX.md`). (P3.)
- `scripts/peer-poke.sh` (AC) vs `scripts/peer-poke.sh.tmpl` (TPL) — byte-equivalent but filename divergence. AC should arguably carry both forms. (P2.)

### Q2 binary verdict

**VERDICT: NOT 100% — 3 P0 + 12 P1 gaps remain.**

P0-1/2/3 are blockers for "AC can re-bootstrap itself from canonical template sources" — i.e., if AC needed to be re-rendered today via `dev-studio-init.sh`, it would produce stale doctrine without the Issue #287 ARCHIVE-CALL block. P1 gaps are silent-divergence accumulated across Sprints 22-34 that the sister-pattern d-test infrastructure documents but does not yet back-port.

---

## 3. Q3 — Self-hosted runner coverage

### Org-level inventory

`GET /orgs/atilproject/actions/runners` → 8 online runners in single runner-group id=1 ("Default", `visibility=all`, `allows_public_repositories=true`).

| ID | Name | Labels | Status |
|---|---|---|---|
| 6 | github-runner-vm | self-hosted, Linux, X64, atilproject, atilcan | online |
| 7 | github-runner-vm-2 | self-hosted, Linux, X64, atilproject, atilcan | online |
| 8-13 | vm-3 through vm-8 | (same 5-tuple) | online |

`GET /orgs/atilproject/actions/runner-groups` → only "Default". No additional groups.

### Per-repo `runs-on:` audit (default branches)

| Repo | Workflows | 4-tuple / self-hosted | GitHub-hosted | Conclusion |
|---|---|---|---|---|
| AtilCalculator | 11 (14 jobs) | 10 use `[self-hosted, Linux, X64, atilcan]`; 1 (`status-label-to-board.yml`) uses `[self-hosted, Linux, X64, atilproject]` | 0 | ✅ self-hosted 100% |
| dev-studio-template | 13 | 10 use `[...,atilcan]`; 2 use `[...,atilproject]`; `deploy.yml.tmpl` is unrendered template source; `disposable-bootstrap-test.yml` has 2 self-hosted jobs | 0 | ✅ self-hosted 100% |
| dev-studio-launcher | 1 (`ci.yml`) | — | **2 jobs on `ubuntu-latest`** | ❌ GitHub-hosted |
| dev-studio-template-smoke (private) | 11 | All 4-tuple self-hosted | 0 | ✅ self-hosted 100% |
| runner-test (private) | 2 | `[self-hosted, linux, atilproject]` + matrix `[1..8]` | 0 | ✅ self-hosted 100% (lowercase `linux` works case-insensitive) |

### Two specific gaps remain

| # | Gap | Severity | Fix |
|---|---|---|---|
| **G1** | `dev-studio-launcher/ci.yml` uses `ubuntu-latest` (2 jobs), consuming GitHub-hosted quota. **8/8 sampled runs** (2026-07-18 → 2026-07-26) executed on `GitHub Actions 10000009xx`. The S29-013 patch in `new-project.sh` patches *new repos it creates*, not the launcher repo itself. | **HIGH** — quota leak | forward-port the S29-013 patch *into* the launcher repo (so the launcher self-bootstraps), or hand-edit `ci.yml` to use 4-tuple. |
| **G2** | `d097-self-hosted-runner-migration.sh --self-test` TC2 is RED-stale: expected `[...,atilproject]` but 10/11 workflows now use `[...,atilcan]` per Sprint 34 S34-005 / PR #1230 (commit `47d5373b`). d097 needs an expected-label refresh. | **MEDIUM** — test contract drift | update d097 expected-label set to `[...,atilcan]` (or accept both as valid) |

### Other observations (not sprint-blocking)

- `status-label-to-board.yml` uses `[...,atilproject]` (1/11 AtilCalculator workflows) — works because vm runners carry both labels, but is inconsistent with sister workflows (drift).
- `atilcan65/*` user-private repos (`atilprojects`, `dev-studio-test-pilot-2`, `smoke-v110`, `sprint-32-dryrun`) **cannot access org runners**; jobs either cancel or fall back to GitHub-hosted. **Out of Sprint 35 scope** (not template/launcher work).
- `deploy.yml.tmpl` (template) contains single-string `runs-on: self-hosted` (NOT 4-tuple). When `init.sh` renders it, the canonical 4-tuple gets substituted; current rendered `deploy.yml` in TPL DOES use 4-tuple. **Render pipeline hides this** — keep `.tmpl` source canonical.
- `disposable-bootstrap-test.yml` private path has 4-tuple but workflow has zero recorded runs (same gap as Q1).

### Static tests

- `d097-self-hosted-runner-migration.sh --self-test`: TC1 ✅, TC2 ❌ (stale-RED per G2), TC3 ✅, TC4 ✅, TC5 ✅.
- `d041-platform-constraint-linter.sh`: 8/8 ✅.

### Q3 binary verdict

**VERDICT: NOT 100%.** Three of four canonical paths (AtilCalculator, dev-studio-template, dev-studio-template-smoke, runner-test) are 100% self-hosted on real runners vm-2 through vm-8. Two specific gaps remain: (1) `dev-studio-launcher/ci.yml` consumes GitHub-hosted `ubuntu-latest` quota on every PR/push; (2) `d097` is stale-RED awaiting expected-label refresh.

---

## 4. Q4 — What else should be added now that focus is template-only

Since the user's directive locked Sprint 35 scope to **finalize** `dev-studio-template` and `dev-studio-launcher`, "additions" here mean **gap-closing follow-ups**, not new features.

### Recommended Sprint 35 in-scope additions (post-GO)

1. **First `gh workflow run disposable-bootstrap-test.yml -f run_private=true`** by owner → produces the missing end-to-end proof of the private path. Closes the MEDIUM confidence gap from Q1. **Owner action**, not agent action.
2. **Back-port 3 P0 + 12 P1 parity items** (Q2) to AtilCalculator, organized as Sprint 35 stories.
3. **Fix `dev-studio-launcher/ci.yml` self-hosted label** (Q3 gap G1) — single-commit chore forward-port.
4. **Refresh `d097` expected-label set** (Q3 gap G2) — single-line test contract update.
5. **Tag launcher `v0.5.0`** (Q5 — current README claims v0.5.1, latest tag is v0.4.0, no v0.5.0 tag exists).
6. **Add `OWNER_DISPOSABLE_PRIVATE_TOKEN` + `ATILPROJECT_DISPOSABLE_TOKEN` org secrets** (Q1) — owner-only territory per file ownership matrix; agent cannot set these.

### Out of Sprint 35 scope (recommended for Sprint 36+)

- **Publish `v1.1.0` GitHub Release** (currently a tag with no release). Sister-pattern release-process ADR is missing.
- **New `dev-studio-template-2.0` design** (PM-driven vision intake for template v2).
- **`atilcan65/*` user-private repo runner-access fix** — out of scope (not template/launcher).
- **HTTP / WASM / persistence surfaces** for AtilCalculator — separate ADRs.

---

## 5. Q5 — Launcher readiness

### Proven (live REST + local script execution)

- **HEAD:** `fdf8e8562442cf5e1e508502b921abdcdbe055f7` (PR #18, 2026-07-26T19:46:01Z, by @atilcan65, Sprint 34 S34-006 mirror of new-project-steps).
- **Visibility:** public; **default branch:** `main`.
- **Entrypoint:** `new-project.sh` (442 lines, syntax-validated via `bash -n`).
- **Real operator flags** verified from `new-project.sh:157-194`:
  - positional: `<project-name>` (regex `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`)
  - `--owner <owner>` (default `atilproject`)
  - `--dir <parent>` (default `$DEV_STUDIO_HOME` → `$HOME/projects`)
  - `--public` (default since v0.3.0)
  - `--private` (opt-in, gated by spending limit + PROJECT_TOKEN canary)
  - `-h`, `--help`
  - test-only: `--source-mode`, `--fixture-runner-count`, `--fixture-repo-root`
- **Local d-test results:**
  - `bash scripts/tests/d001-launcher-self-hosted-runner-patch.sh` → **7/7 PASS**
  - `bash scripts/tests/d002-launcher-visibility-policy.sh` → **7/7 PASS**
  - `bash scripts/tests/s29-003-url-hygiene.sh` → **5/6 PASS** (TC2 RED — intentional `atilcan65` cross-repo documentation links; script still exits 0; **test-honesty gap**)
  - `bash -n new-project.sh` → PASS
- **Bootstrap chain** verified:
  1. `gh repo create --template atilproject/dev-studio-template --public|--private --clone`
  2. `./scripts/dev-studio-init.sh` (render + PROJECT_TOKEN write + canary)
  3. `./scripts/bootstrap-labels.sh` (34 labels seeded per agent count; 31 per script inventory — see §6)
  4. Self-hosted-runner patch via `apply_self_hosted_runner_patch` (`new-project.sh:114-144`)
  5. Final rendered commit + push
- **Live CI on launcher HEAD**: 11/11 successful main runs (audit window 2026-07-18 → 2026-07-26).

### Unproven / caveats

- **No fresh real repository was created during this audit.** Live E2E `--private` not executed; the destructive path was not triggered.
- **Version drift**: README claims v0.5.1 in Versioning table + footer, but CHANGELOG has no `[0.5.1]` entry (latest is `[0.5.0]` + S34-006 in `[Unreleased]`), and no `v0.5.0` git tag exists — only `v0.4.0` is a published release tag. **Sprint 35 in-scope fix**: tag `v0.5.0` (commit `fdf8e85` or current main).
- **No template SHA/tag pinning**: each launcher run consumes whatever template `main` is at that time. (Template v1.1.0 tag is 36 commits behind main; downstream automation that pins to a tag will get older behavior.)
- **No Actions billing/spending-limit preflight** in the launcher — the `--private` warning at `new-project.sh:340-345` mentions spending limit but does not probe it via API.
- **No fresh real private E2E bootstrap** in CI history.
- **Branches reportedly unprotected** — needs owner confirmation; out of agent scope.
- **`git push` failure prints recovery guidance and continues with exit 0** — non-fatal design, but may mask failures.

### Q5 binary verdict

**VERDICT: READY for v0.5.0-feature-set private project creation, with caveats.**

The bootstrap code path is structurally complete and locally proven via d-tests. Full private end-to-end readiness remains NOT PROVEN. Version drift (README/CHANGELOG/tag) is the most visible launch-blocking cosmetic gap; fixing it (tagging v0.5.0) is a 5-minute owner action.

---

## 6. Q6 — Detailed `new-project-steps.md`

Delivered as sibling file: **`docs/sprints/sprint-35/new-project-steps.md`** (this same PR).

**Source:** Reconstructed from current `main` of both repos + live REST metadata captured 2026-07-27. **NOT** a copy of the canonical published `atilproject/dev-studio-template/docs/new-project-steps.md` or `atilcan65/AtilCalculator/docs/new-projectsteps.md`. Line numbers cited are stable for the PRs identified (`atilproject/dev-studio-template#225` and `atilproject/dev-studio-launcher#18`).

**Sections covered (24):** decision summary, prerequisites, gh auth + PAT, clone + symlink, self-hosted runner prereqs, launcher command + flags, what `new-project.sh` does step-by-step, `PROJECT_TOKEN` bootstrap, GitHub Project board setup, labels seeded by `bootstrap-labels.sh`, secrets + variables, self-hosted runner access + label matching, template init + render (`.tmpl` → final), systemd watchers, Telegram env provisioning, local checks, Actions verification, agent runtime startup, Vision Intake + first sprint kickoff, acceptance checklist, rollback/cleanup, troubleshooting, evidence sources, unresolved inputs.

**Unresolved inputs flagged (19 items, all marked `OWNER INPUT REQUIRED` or `NOT VERIFIED`):** project name, owner, parent dir, spending limit, runner host, PROJECT_TOKEN, Telegram creds; runner registration command, 6-vs-8 placeholder count, 31-vs-34 label count, status field option count (5 vs 6), watcher cadence (60s docs vs 180s code), `--non-interactive` flag mismatch, e2e-pilot PASS count, cluster-lag-detector permission fix propagation, `--private` extra prompts, WIP-cap semantics.

**Notable operational gaps observed (not in canonical doc):**

1. **Watcher default cadence is 180s, not 60s.** `scripts/agent-watch.sh` loop mode defaults to 180s; `CLAUDE.md` + canonical doc claim 60s.
2. **`status-label-to-board.yml` is currently DISABLED** (`if: false` per S29-004). Status labels do NOT auto-sync to the Project board right now; the script adds existing issues on creation, but new `status:*` label changes are silent.
3. **`--non-interactive` flag mismatch**: `disposable-bootstrap-test.yml` invokes `dev-studio-init.sh --non-interactive`, but the init parser rejects it (only accepts `--dry-run`, `--verbose`, `-h`). Disposable test may skip canary/board/systemd silently.
4. **`claim-next-ready.sh` WIP cap counts WORK STREAMS, not issues** (default `WIP_LIMIT=2`). Operators tracking "2 PRs per agent" are measuring the wrong unit.
5. **`dev-studio-start.sh` launches Claude with `--dangerously-skip-permissions`** — operator-visible side effect for private repos with sensitive content.
6. **6-pane tmux layout** confirmed (incl HUMAN pane); canonical doc's 5-pane description is stale.
7. **`cc:human` is NOT seeded** by `bootstrap-labels.sh`; only added manually by workflow/operators.

---

## 7. Q7 — Is GitHub's live `dev-studio-template` actually updated?

### Yes — live + matched

| Property | Value | Source |
|---|---|---|
| `pushed_at` | `2026-07-27T07:43:16Z` | REST `/repos/.../dev-studio-template` |
| `updated_at` | `2026-07-26T19:45:55Z` | (same) |
| HEAD SHA | `0db078f451681bd093b209f1de4de1198db0d47e` | (same) |
| `is_template` | `true` | (same) |
| Owner | `atilproject` (type `Organization`) | (same) |

**`pushed_at` is later than `updated_at` by ~12h** — indicating a newer push that hasn't updated any tracked metadata. The latest CI/canary runs are all under `head = 0db078f`.

### Byte-parity proof (local clone vs live raw)

| File | Local MD5 | Live content SHA | Status |
|---|---|---|---|
| `scripts/dev-studio-init.sh` | `d083064e9d94806e4f9626a2341a117e` | `6d74c23b5415e2ecf9b4cc387400ec506eeca258` | ✅ matches |
| `.github/workflows/disposable-bootstrap-test.yml` | `47a03d0f9dac3421de103e90f9b7b227` | (matching blob on server) | ✅ matches |

### Why might files still LOOK old to an observer?

1. **`v1.0.1` is the only GitHub Release tag an outside observer might see** — it's a `draft` release with `published_at: null`. The "latest release" badge in the GitHub UI shows nothing, making the repo appear unreleased.
2. **No published release for `v1.1.0`** (a tag exists at `401c22cd`, 36 commits behind `main`). A consumer pinning to `v1.1.0` would see a 36-commit-old template.
3. **Tag-recency gap**: `v1.1.0` is 36 commits behind `main`; `v1.0.1` is 96 commits behind. Anyone viewing tags-only will see stale content.
4. **`dev-studio-template-smoke`** (the public sister smoke repo) was last touched 2026-07-10 (TD-069 Layer 5 byte-size split), predating 6 weeks of forward-ports. Smoke runs are failing (`3 success / 11 failure` of 14 runs). Not a fresh-readiness proof.

### Q7 binary verdict

**VERDICT: YES live + matched.** Local clone byte-for-byte equals live raw download for the audited files. The "files look old" perception is from the **release-process gap** (draft/no-publish state of `v1.0.1` and `v1.1.0`), not from stale `main`. Fixing release-publication discipline is Sprint 35+ scope.

---

## 8. Owner decision register

| # | Decision | Options | Owner | Required before GO |
|---|---|---|---|---|
| **D1** | Sprint 34 vs Sprint 35 framing — directive says "Sprint 35" then "Sprint 34 ... GO verince Sprint 35." Sprint 34 is already terminal (CS#38 PR #1232 squash-merged 2026-07-26T20:09:08Z sha `4793fea`). | A: Treat audit as pre-GO for Sprint 35 execution. B: Treat as pre-GO for Sprint 34 (re-open?) — implausible, Sprint 34 is closed. C: Treat as organizational readiness milestone (no sprint). | @atilcan65 | ✅ REQUIRED |
| **D2** | Sprint 35 scope acceptance — confirm Sprint 35 is locked to (a) back-port 3 P0 + 12 P1 parity items from TPL → AC, (b) fix `dev-studio-launcher/ci.yml` self-hosted label, (c) refresh `d097`, (d) tag launcher v0.5.0, (e) first-time private disposable run. | A: Accept as drafted. B: Add/remove stories. C: Defer parity to Sprint 36. | @atilcan65 | ✅ REQUIRED |
| **D3** | First disposable private E2E run — owner must trigger `gh workflow run disposable-bootstrap-test.yml -f run_private=true` once and observe green run, OR accept MEDIUM confidence and defer to Sprint 35+ post-impl. | A: Owner runs it now (recommended). B: Defer to Sprint 35 W1. C: Skip and accept MEDIUM. | @atilcan65 | ✅ RECOMMENDED |
| **D4** | Sprint 35 story routing — parity gaps land in `atilproject/dev-studio-template` (canonical home) and `atilproject/AtilCalculator` (back-port), NOT `dev-studio-launcher` (launcher is operator-side, not doctrine-side). | A: Per file-ownership matrix above. B: Bundle into single mega-PR. C: Defer per-item. | @atilcan65 | ✅ REQUIRED |
| **D5** | Release-discipline — confirm Sprint 35 in-scope to publish `v1.1.0` GitHub Release for template and `v0.5.0` for launcher. | A: Yes. B: Defer to Sprint 36. | @atilcan65 | RECOMMENDED |
| **D6** | This audit document — approve as Sprint 35 kickoff baseline, or amend. | A: Approve. B: Amend (add/remove/correct). C: Reject (different scope). | @atilcan65 | ✅ REQUIRED |

---

## 9. One-sprint forward-only closure plan (post-GO)

### Wave 1 — Foundation (parity P0 + Q3 gaps)

| Story | Lane | Story ID | Description | Closes |
|---|---|---|---|---|
| S35-001 | architect (Lane 2) | TPL-001 | Restore `.claude/CLAUDE.md.tmpl` in AtilCalculator from canonical TPL HEAD. | Q2 P0-1 |
| S35-002 | architect (Lane 2) | TPL-002 | Back-port 5 `.claude/agents/*.md.tmpl` files from canonical TPL to AC (Issue #287 ARCHIVE-CALL block). | Q2 P0-2 |
| S35-003 | architect (Lane 2) | TPL-003 | Back-port `scripts/owner-apply-soul-patch.sh` from TPL to AC. | Q2 P0-3 |
| S35-004 | developer (Lane 3) | LCH-001 | Fix `dev-studio-launcher/ci.yml` 2 jobs to use `[self-hosted, Linux, X64, atilcan]`. | Q3 G1 |
| S35-005 | tester (Lane 3) | AC-001 | Update `d097` expected-label set to include both `[...,atilcan]` and `[...,atilproject]`. | Q3 G2 |

### Wave 2 — Feature (parity P1 back-port + ops follow-ups)

| Story | Lane | Story ID | Description | Closes |
|---|---|---|---|---|
| S35-006 | developer (Lane 3) | TPL-004 | Forward-port `scripts/agent-stall-detect.sh` from AC → TPL (with d-stall-detect d-test). | Q2 P1-2 |
| S35-007 | developer (Lane 3) | TPL-005 | Forward-port `scripts/install/install-git-hooks.sh` from AC → TPL. | Q2 P1-3 |
| S35-008 | architect + developer | TPL-006 | Back-port 11 `.github/workflows/*.yml` to TPL canonical (or document intentional divergence). | Q2 P1-4 |
| S35-009 | developer (Lane 3) | TPL-007 | Back-port `systemd/dev-studio-health.service.tmpl` to AC. | Q2 P1-5 |
| S35-010 | developer (Lane 3) | TPL-008 | Back-port `.github/LABEL-TAXONOMY.md` to AC. | Q2 P1-6 |
| S35-011 | developer (Lane 3) | AC-002 | Refresh 5 `.claude/agents/*.md` rendered files in AC to include Issue #972 SOUL AMEND block. | Q2 P1-1 |
| S35-012 | developer (Lane 3) | AC-003 | Sister-test port-parity: back-port latest `scripts/agent-state.sh`, `agent-watch.sh`, `deploy-runner.sh`, `dev-studio-init.sh`, `init-template-repo.sh`, `notify.sh`, etc. — sister d-test verifies. | Q2 P1-7/8 |

### Wave 3 — Polish (release + observability)

| Story | Lane | Story ID | Description | Closes |
|---|---|---|---|---|
| S35-013 | developer + orchestrator | LCH-002 | Tag launcher `v0.5.0` at current main HEAD. Update CHANGELOG `[0.5.0]` section. | Q5 version drift |
| S35-014 | developer + orchestrator | TPL-009 | Publish `v1.1.0` GitHub Release for template (was tagged, no release). | Q7 release gap |
| S35-015 | orchestrator (Lane 0) | LCH-003 | Document launcher README "29/29 PASS" claim against actual e2e-pilot TC count (currently unverified). | §6 unresolved #15 |
| S35-016 | owner-only | TPL-010 | First `gh workflow run disposable-bootstrap-test.yml -f run_private=true` and verify green run. | Q1 confidence upgrade |
| S35-017 | owner-only | AC-004 | Add `OWNER_DISPOSABLE_PRIVATE_TOKEN` + `ATILPROJECT_DISPOSABLE_TOKEN` org secrets. | Q1 unverified secrets |

### Target-repo routing (per directive)

| Story | Target repo | Lane |
|---|---|---|
| S35-001, S35-002, S35-003, S35-011, S35-012, S35-016 (orchestration), S35-017 (org-level) | `atilproject/AtilCalculator` | back-port |
| S35-004, S35-005, S35-013, S35-015 | `atilproject/dev-studio-launcher` | launcher |
| S35-006, S35-007, S35-008, S35-009, S35-010, S35-014, S35-016 (workload) | `atilproject/dev-studio-template` | forward-port / canonical refresh |

### Capacity & cadence

- **Sprint 35 length:** 2 weeks (per CLAUDE.md cadence).
- **Capacity:** 4-5 PRs/cluster-squash per day; 5 lanes in parallel.
- **WIP cap:** 2/2 per role (ADR-0038).
- **Cluster-squash:** ≤60s owner-squash window per ADR-0059.
- **Verdict chain:** arch 9-Lens Lane 2 PRIMARY → tester Lane 3 → orchestrator Lane 4 → owner squash.

---

## 10. Acceptance criteria (Sprint 35 exit gate)

A Sprint 35 story is "Done" only if all of:

1. ✅ Acceptance criteria pass automated tests (d-test sister-pattern contract).
2. ✅ Code merged to `main` via PR with owner squash-merge (ADR-0031).
3. ✅ CI is green on `main` post-merge.
4. ✅ Docs updated (README, CHANGELOG, ADR if applicable).
5. ✅ Project card moved to Done by orchestrator.
6. ✅ No new P0/P1 bugs filed against the story within 24h.

Sprint 35 sprint-level "Done" additionally requires:

7. ✅ All 17 stories (S35-001..017) terminal.
8. ✅ `disposable-bootstrap-test.yml` has at least one successful private-path run in CI history (closes Q1 confidence).
9. ✅ `dev-studio-launcher/ci.yml` 100% self-hosted on 4-tuple (closes Q3 G1).
10. ✅ `v0.5.0` launcher tag + `v1.1.0` template release published (closes Q5 + Q7).
11. ✅ 3 P0 + 12 P1 parity gaps all closed (closes Q2).
12. ✅ First-cycle Sprint 35 close ceremony + RETRO-035 filed.

---

## 11. Full-team review matrix

This audit PR is **DRAFT**, **NOT IMPLEMENTATION-AUTHORIZED**. Full-team review is requested per the owner directive "Sen bitirince ekip review etsin diye yönlendir."

| Reviewer | Lens | Asks |
|---|---|---|
| @product-manager | User-outcome / scope-fit | Does Sprint 35 lock the right scope? Any deferred items that block downstream consumer project creation? |
| @architect | 9-Lens (ADR-0045) | Are the Q2 P0/P1 classifications correct? Any sister-patterns missed? Is the file-ownership matrix respected? |
| @developer | Feasibility / sequencing | Are the 17 stories reasonable? Anything in target-repo routing that breaks single-direction discipline? |
| @tester | Acceptance / E2E / runner | Are ACs testable? What's the d-test contract for each story? |
| @owner (gate) | Scope approval | Decisions D1-D6 above. |

### Review routing (PR open)

- **PM** cc via `cc:product-manager` (PM-lane appropriate — docs/sprints/**).
- **Architect** cc via `cc:architect` + `needs-architect-review` (Lane 2 PRIMARY).
- **Developer** cc via `cc:developer` (Lane 3 candidate).
- **Tester** cc via `cc:tester` + `needs-tester-signoff` (Lane 3 sign-off).
- **Owner** via `cc:human` (merge gate).

---

## 12. Evidence appendix (cross-refs)

### Live REST captures (2026-07-27)

| Repository | Field | Value |
|---|---|---|
| `atilproject/dev-studio-template` | `is_template` | `true` |
| `atilproject/dev-studio-template` | `default_branch` | `main` |
| `atilproject/dev-studio-template` | `pushed_at` | `2026-07-27T07:43:16Z` |
| `atilproject/dev-studio-template` | HEAD SHA | `0db078f451681bd093b209f1de4de1198db0d47e` |
| `atilproject/dev-studio-launcher` | HEAD SHA | `fdf8e8562442cf5e1e508502b921abdcdbe055f7` |
| `atilproject/dev-studio-launcher` | latest tag | `v0.4.0` (no v0.5.0 tag exists) |
| `atilproject/AtilCalculator` | HEAD SHA (origin/main) | `4793fea18fedbde88a57b4551955905fdaae1945` |
| `atilproject/dev-studio-template` | `disposable-bootstrap-test.yml` runs | `total_count: 0` |
| `atilproject` org | runners | 8 online (vm-vm-8), all 5-tuple |
| `atilproject/dev-studio-template-smoke` | last commit | `b99b4e7` 2026-07-10 |

### Local d-test execution (template HEAD `0db078f`)

- 41 d-tests executed locally from fresh clone `/tmp/dev-studio-template-audit`
- **35 / 41 GREEN** (exit 0)
- **6 / 41 RED** (exit 1):
  - `d1025-s29-template-agent-wake-hotfix-port.sh` TC6 RED (Fix 3 capture-pane missing)
  - `d068b-tmux-send-keys-split-sleep.sh` TC2/TC5 RED (env-override sleep missing at `agent-wake.sh:83`)
  - `d1026-s29-template-env-decoupling-port-parity.sh` TC2/TC3/TC5 RED (pane-buffer verify path)
  - `d166-claim-next-ready-retro024-filter.sh` TC2/TC3/TC5 RED (ROLLBACK rc=6 vs expected silent-skip)
  - `d-pr-1147-install-test-flake.sh` 0/4 RED (fixture file missing in fresh clone)
  - `s29-001-workflow-self-hosted.sh` T2/T3/T5 RED (test contract drift vs file content)
  - `d-s32-024-new-project-bootstrap-dry-run.sh` TC6/TC7 RED (intentional pre-impl RED per test's own header — Issue #162)
  - `d-s34-002-deploy-runner-byte-equivalence.sh` missing (no such script)

### Local d-test execution (launcher HEAD `fdf8e85`)

- `d001-launcher-self-hosted-runner-patch.sh`: 7/7 PASS
- `d002-launcher-visibility-policy.sh`: 7/7 PASS
- `s29-003-url-hygiene.sh`: 5/6 PASS (TC2 RED — intentional `atilcan65` cross-repo docs links)
- `bash -n new-project.sh`: PASS

### Local clone byte-equivalence (parity audit)

- Local clones at `/tmp/parity-audit/{tpl,lch,cmp}/`
- 282 AC files vs 268 TPL files vs 12 LCH files classified (see §2 table)

### Sister-pattern d-tests (forward-port parity verification)

- 16 S34-002 byte-equivalence d-tests in TPL: all GREEN, confirm AC → TPL script parity (post S34-002 + S34-006 forward-ports).
- `d-s34-002-*-byte-equivalence.sh`: 8/8 GREEN each
- `d-s34-004-disposable-bootstrap-test.sh`: 10/10 GREEN
- `d-smoke-bootstrap-v110.sh`: 7/7 GREEN (live REST call against `atilcan65/smoke-v110`)

### Live CI evidence (template HEAD `0db078f`)

| Run | Created | Conclusion |
|---|---|---|
| `Lint & Test (d-tests)` 30217537814 | 2026-07-26T19:45:53Z | success |
| `CI` 30217537495 | 2026-07-26T19:45:50Z | success |
| `Deploy to production` 30217537467 | 2026-07-26T19:45:50Z | failure (owner-gated, expected) |

### Live CI evidence (AtilCalculator HEAD `4793fea`)

- 53 main runs returned; 27 success, 3 failure, 23 cancelled. The 3 failures are post-squash detector false-positives (per ADR-0078 RCA, fixed PR #223 + #225 S34-006).

### Live CI evidence (launcher HEAD `fdf8e85`)

- 11/11 successful main runs (full audit window 2026-07-18 → 2026-07-26). Per-run GitHub-hosted runner ID `10000009xx` confirms `ubuntu-latest` consumption (Q3 G1).

### Sprint 34 cross-refs

- **Sprint 34 TERMINAL ✅:** CS#38 PR #1232 squash-merged 2026-07-26T20:09:08Z sha `4793fea` by @atilcan65. Issue #1227 auto-CLOSED. 3 verdict-by PRESERVED post-squash = cycle ~#3968Q+407 60th instance NEW RECORD.
- **Sprint 34 carry-overs** (all → Sprint 35 backlog): S34-002 row 280 (terminal Closes anchor for #1222); ADR-0078 owner Variables config (5 vars); ADR-0012 label-check enforcement gap for launcher repo; cycle ~#3968Q+911 owner-squash-witness signal clarification; cycle ~#3968Q+940 NEW DOCTRINE; cycle ~#3968Q+933 NEW DOCTRINE.

---

## 13. Sister-pattern memory links

- [[sprint-34-terminal-cluster-squash-38-pr1232]] — Sprint 34 close ceremony context.
- [[cycle-3935q-memory-vs-reality-divergence]] — discipline for fresh-evidence audit over cached memory.
- [[sprint-35-owner-directive-org-wide-finalization]] — directive origin.

---

*Drafted 2026-07-27 by @orchestrator on branch `audit/sprint-35-org-readiness`. No template/launcher mutation performed. All evidence from live REST + fresh default-branch clones + local d-test execution.*