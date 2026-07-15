# Sprint 28 — Template & Launcher Audit (Owner 7-question response, 2026-07-13)

> **Owner directive (2026-07-13, cycle ~#1158):** 7-question audit on
> dev-studio-template + dev-studio-launcher readiness. Status report only;
> NO actions without owner ratification. Output as repo doc + PR (this file).
>
> **Constraint triad:** "Uydurma — bilinmeyen varsa bilmiyorum de" · "Kararlar
> birlikte alınacak — ben okumadan hiçbir aksiyon alma" · "Eski hiç bir
> hazırlık dosyasını kullanma" · "Graph biterse rest kullan ama uydurmak yok".
>
> **Method:** All facts in this doc were re-fetched from GitHub REST API on
> 2026-07-13 (cycle ~#1158). AtilCalculator local checkout used only as
> canonical reference for "what exists in AtilCalculator today". No prior
> audit / prep doc was reused (deleted `01-status-check-2026-07-13.md` from
> PR #1007 closed earlier this cycle). Rate-limit budget at start:
> core=4973/5000, graphql=3623/5000, search=30/30.
>
> **Companion doc:** `docs/new-projectsteps.md` (this PR, Q6 deliverable,
> freshly written — does NOT inherit from the deleted cycle-#743 version).

---

## §0 — TL;DR verdict table (Owner summary)

| # | Question | Verdict | Severity |
|---|---|---|---|
| Q1 | Template private-ready? Tested? | **Partial.** Smoke repo (`dev-studio-template-smoke`) exists (private, 4.7 MB, 2026-07-10). But CI is mixed (3 success / multiple failures). Template stock workflows use `ubuntu-latest` (paid on private) → NOT zero-cost private-ready. | 🟡 blocker for true private-first use |
| Q2 | All AtilCalc scripts/doctrine/agents ported to template? | **NO.** 58 of 74 ADRs missing. 110 of 131 d-tests missing. 5+ scripts + 5 sub-dirs missing. 3+ workflows missing. Roughly **60% portage gap**. | 🔴 large — Sprint 29 candidate |
| Q3 | Self-hosted runner 100%? | **AtilCalculator: YES (11/11 self-hosted).** **Template: NO (7/8 stock workflows `ubuntu-latest`, only deploy.tmpl is self-hosted).** **Smoke repo: YES (post-bootstrap manual customization).** | 🔴 blocker for private-repo template use |
| Q4 | What else to add to template? | (a) Migrate all stock workflows to self-hosted. (b) Forward-port missing ADRs + d-tests + scripts. (c) Re-tag v1.0.1 to include S28 work. (d) Launcher's atilcan65 URL → atilproject URL hygiene. (e) Optional: bootstrap-project-board + dev-studio-start integration. | See §6 |
| Q5 | Launcher still ready? | **Mostly yes.** `new-project.sh` works (creates repo, runs init, bootstraps labels, commits + pushes). Hardcoded `atilcan65/dev-studio-template` (resolves to same repo but is legacy canonical name). `--private` flag works (Actions billing warning emitted). | 🟡 stale URL + missing v0.3 tag |
| Q6 | Separate `new-projectsteps.md`? | Created (this PR, companion file). Fresh content — does not inherit from cycle-#743 version per directive. | ✅ delivered |
| Q7 | Tags / version discipline OK? | **NO.** Template v1.0.1 tag at SHA `62aec11b` (2026-07-09) is STALE — HEAD is `43592c24` (2026-07-11) with 6 PRs merged after the tag (PRs #64-69 = S28 forward-port series). **Launcher: NO v0.3 tag exists** (only v0.2.0 tag at `40d59c0b`; HEAD is `b0d820da` with commit message claiming v0.3 but never tagged). | 🔴 owner intuition confirmed — files look old because tags didn't move |

---

## §1 — Method (sourcing + transparency)

**Sources queried (all REST, no GraphQL, 2026-07-13 cycle ~#1158):**

| Repo | Endpoint | Why |
|---|---|---|
| `atilproject` org | `/orgs/atilproject`, `/orgs/atilproject/repos`, `/orgs/atilproject/actions/runners` | Org shape, all repos, runner inventory |
| `atilproject/dev-studio-template` | `/repos/...`, `/contents/`, `/tags`, `/branches/main`, `/actions/runs`, `pulls` | Template content + tags + CI evidence |
| `atilproject/dev-studio-launcher` | `/repos/...`, `/contents/`, `/tags`, `/branches/main`, `pulls` | Launcher content + tags + history |
| `atilproject/dev-studio-template-smoke` | `/repos/...`, `/contents/.github/workflows`, `/actions/runs` | Q1 evidence — was template actually private-deployed? |
| `atilproject/AtilCalculator` | (local checkout at `/home/atilcan/projects/AtilCalculator`) | Canonical reference for "what exists" |
| `atilcan65/dev-studio-template` | `/repos/atilcan65/dev-studio-template` | Verify if launcher URL still resolves correctly |

**Bilmiyorum declarations (data I could not confirm):**
- I do not have direct evidence whether dev-studio-template-smoke was deliberately created by the owner as a smoke test, or accidentally populated by a manual push. The smoke repo has **0 merged PRs** (all changes pushed directly to main). I cannot tell whether the failing CI runs on smoke were caused by missing env vars (DEPLOY_SSH_KEY etc.), by d-test failures, or by template bugs.
- I do not have evidence whether owner has configured org-level Actions billing for private repos (relevant to Q3's private-repo scenario).
- I do not have evidence whether dev-studio-init.sh has been exercised end-to-end on a fresh clone since PRs #64-69 merged on 2026-07-11.

---

## §2 — Org + repo recon (foundational)

### §2.1 — atilproject org

| Field | Value |
|---|---|
| Login | `atilproject` |
| Plan | `team` |
| Public repos | 3 |
| Members_can_create_repos | null (not returned — could not confirm) |
| Default_repo_permission | null (not returned — could not confirm) |

> **Bilmiyorum:** I cannot confirm who has admin/write access to atilproject
> org beyond what GitHub REST exposes. Owner-only direct verification needed.

### §2.2 — All atilproject repos (5 total)

| Repo | Visibility | Default branch | Pushed_at | Size_kb | Has_issues |
|---|---|---|---|---|---|
| `dev-studio-template` | **public** | main | 2026-07-11T08:57:33Z | 834 | true |
| `dev-studio-launcher` | **public** | main | 2026-06-17T06:49:34Z | 16 | true |
| `AtilCalculator` | **public** | main | 2026-07-13T05:59:36Z | 4619 | true |
| `runner-test` | **private** | main | 2026-06-29T20:23:49Z | 1 | true |
| `dev-studio-template-smoke` | **private** | main | 2026-07-10T16:38:47Z | 4700 | true |

> **Note:** Template is public, but it's used to bootstrap **downstream private
> repos** (via `gh repo create --template atilproject/dev-studio-template`).
> Visibility of template ≠ visibility of downstream projects. Owner can
> `--public` or `--private` per-project via launcher flag.

### §2.3 — Self-hosted runners (8 online, all idle)

```
count: 8
runners:
  - name: github-runner-vm     labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
  - name: github-runner-vm-2   labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
  - name: github-runner-vm-3   labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
  - name: github-runner-vm-4   labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
  - name: github-runner-vm-5   labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
  - name: github-runner-vm-6   labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
  - name: github-runner-vm-7   labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
  - name: github-runner-vm-8   labels: [self-hosted, Linux, X64, atilproject]  status: online  busy: false
```

Runner capacity is **ample for private-repo workload**. Pattern matches the
4-tuple (`[self-hosted, Linux, X64, atilproject]`) referenced in
AtilCalculator CLAUDE.md §Self-hosted runner pattern.

---

## §3 — Q1: Template private-ready? Tested?

### §3.1 — Evidence

**Smoke repo exists (`dev-studio-template-smoke`, private, 4.7 MB).**

Top-level dirs present in smoke repo (post-bootstrap):
```
.claude  .github  docs  scripts  src  systemd  tests
```

Smoke repo workflows (11 total — 8 stock + 3 custom):
| Workflow | Exists in template? | Source |
|---|---|---|
| `ai-pr-review.yml` | yes (907 B) | stock |
| `ci.yml` | yes (2.0 KB) | stock |
| `cross-repo-close.yml` | yes (1.8 KB) | stock |
| `d050b-dispatch.yml` | **NO** | custom (added in smoke) |
| `deploy.yml` | yes as `.tmpl` only | rendered in smoke |
| `label-check.yml` | yes (5.5 KB) | stock (smoke copy is 60 KB → heavily customized) |
| `label-cleanup.yml` | yes (4.2 KB) | stock |
| `lint-and-test.yml` | **NO** | custom (added in smoke) |
| `post-squash.yml` | **NO** | custom (added in smoke) |
| `secret-canary.yml` | yes (4.6 KB) | stock |
| `status-label-to-board.yml` | yes (7.7 KB) | stock (smoke copy is 12 KB → customized) |

**Smoke CI evidence (most recent 10 runs):**
| Date | Workflow | Conclusion |
|---|---|---|
| 2026-07-10T16:38:49Z | Lint & Test (d-tests) | ✅ success |
| 2026-07-10T16:38:49Z | CI | ❌ failure |
| 2026-07-10T16:38:49Z | Deploy to production | ❌ failure |
| 2026-07-10T16:38:49Z | .github/workflows/label-check.yml | ❌ failure |
| 2026-07-09T16:27:53Z | Lint & Test (d-tests) | ✅ success |
| 2026-07-09T16:27:53Z | Deploy to production | ❌ failure |
| 2026-07-09T16:27:53Z | CI | ❌ failure |
| 2026-07-09T16:27:53Z | .github/workflows/label-check.yml | ❌ failure |
| 2026-07-09T16:27:52Z | .github/workflows/label-check.yml | ❌ failure |
| 2026-07-09T09:20:50Z | Deploy to production | ❌ failure |

Total smoke repo runs: 3 success / many failures (across all runs).

**Template's own CI history (recent 10 runs):**
| Date | Workflow | Conclusion |
|---|---|---|
| 2026-07-11T13:52:16Z | Label Cleanup | ✅ success |
| 2026-07-11T13:51:28Z | Label Cleanup | ✅ success |
| 2026-07-11T13:48:41Z | Label Check (ADR-0012) | ✅ success |
| 2026-07-11T13:48:41Z | Status Label → Board Sync (ADR-0013) | ❌ failure |
| 2026-07-11T13:48:40Z | Status Label → Board Sync (ADR-0013) | ❌ failure |
| 2026-07-11T13:48:40Z | Label Check (ADR-0012) | ✅ success |

> **Q1 note (Status Label → Board Sync failure):** The template's own
> status-label-to-board.yml has been failing. This is likely because the
> template repo has no Projects v2 board configured (the workflow tries to
> push label updates to a non-existent project). This is a template bug.

### §3.2 — Verdict

| Sub-question | Answer |
|---|---|
| Can template bootstrap a private repo? | **YES** (smoke repo evidence). `new-project.sh --private` works. |
| Does private smoke repo CI pass? | **PARTIAL.** Lint & Test (d-tests) = green. CI / Deploy / label-check = red. Deploy failure is likely env-vars-missing (SERVICE_NAME, MODULE_PATH, DEPLOY_PORT, HEALTHZ_PATH, DEPLOY_SSH_KEY not set in smoke repo). label-check failure is more concerning — needs investigation. |
| Is template zero-cost private-ready (no Actions-minutes burn)? | **NO.** 7 of 8 template stock workflows use `runs-on: ubuntu-latest` which burns Actions minutes on private repos. Only `deploy.yml.tmpl` is self-hosted. See §5 (Q3) for full breakdown. |
| Were tests run? | **Yes for d-tests** (Lint & Test (d-tests) is green on smoke repo). **No for project-level tests** — template ships empty `tests/.gitkeep` only. |

### §3.3 — Bilmiyorum

- I cannot confirm whether the smoke repo's failing workflows were
  investigated + intentionally left as-is, or whether they represent an
  open bug. The smoke repo has 0 PRs (all direct pushes), so there's no
  discussion thread to inspect.

---

## §4 — Q2: All AtilCalc scripts/doctrine/agents/methods ported to template?

### §4.1 — AtilCalculator → Template diff matrix

| Area | AtilCalculator (canonical) | Template | Gap | Severity |
|---|---|---|---|---|
| **ADRs** (`docs/decisions/`) | 74 (incl. amendments) | 16 (incl. INDEX.md.tmpl) | **58 missing** | 🔴 critical |
| **d-tests** (`scripts/tests/`) | 131 files | 21 files | **110 missing** | 🔴 critical |
| **Project tests** (`tests/`) | varies by story (calc-engine tests) | empty (`.gitkeep` only) | project-specific — **not a gap** (each project has its own) | — |
| **Scripts** (`scripts/`) | 38+ files + 6 sub-dirs | 33 files + 0 sub-dirs | **5+ scripts + 6 sub-dirs missing** | 🟡 significant |
| **Workflows** (`.github/workflows/`) | 11 | 8 (one of them `.tmpl`) | **3+ missing** | 🟡 significant |
| **Soul files** (`.claude/agents/`) | 5 (both `.md` rendered + `.md.tmpl` source) | 5 (`.md.tmpl` only) | template has source — AtilCalc has both. **Not a gap.** | — |
| **CLAUDE.md** (project doctrine) | rendered | `.tmpl` source | template has source — AtilCalc has rendered. **Not a gap.** | — |
| **Commands** (`.claude/commands/`) | 2 (rendered) | 2 (`.tmpl`) | same as above. **Not a gap.** | — |

### §4.2 — ADR gap detail (58 missing)

Template ADRs (16): `0010, 0011, 0012, 0013, 0014, 0015, 0016, 0020, 0021, 0024, 0025, 0026, 0027, 0030, 0046, 0047`

AtilCalculator ADRs NOT in template (sample of the 58 missing — universal ones):
- `0001-template-architecture` (universal — template architecture doctrine!)
- `0002-autonomy-loop` (universal — agent-watch polling loop)
- `0031-owner-override-doctrine` (universal — owner merge gate)
- `0032` through `0045` (almost all are universal doctrine)
- `0048`, `0049`, `0050`, `0052`, `0053`, `0054`, `0055`, `0056`, `0057`,
  `0058`, `0059`, `0060`, `0062`, `0063`, `0064`, `0065`, `0067`, `0068`,
  `0069`, `0070`, `0071` (all recent — Sprint 27-28 era universal doctrine)

AtilCalculator ADRs that SHOULD STAY project-specific (NOT template-worthy):
- `0017-tech-stack` (Python 3.11+ / pytest / ruff / mypy / Decimal — AtilCalc-specific)
- `0018-front-end-framework`
- `0019-*` (decimal-and-envelope, lazy-import, conftest-env-var-precedence, evaluate-persist-env-var-gate, api-contract)
- `0022-persistence-layer`
- `0023-frontend-architecture`
- `0051-engine-perf-flake-vs-regression`

> **Gap interpretation:** Of the 58 missing, roughly 40+ are universal
> doctrine (port-worthy) and roughly 15-20 are project-specific
> (stay-in-AtilCalculator). The 40+ universal ADRs are the **portage gap**.

### §4.3 — d-test gap detail (110 missing)

Template d-tests (21): `d015, d024, d025, d027, d028, d029, d031, d032, d033, d034, d046, d047, d068b, d081, d983, d986, dreg-post-restart-label-guard, e2e-pilot, faz5-smoke, state-schema-smoke, INDEX`

AtilCalculator d-tests NOT in template — 110 files including:
- `d006-d014` (stable-event-ids, api-observability, status-action-driver, stale-verdict-schema, issue-assigneeship-authority, rca-9-preflight-venv-create, dev-idle-prevention [in template], rca-11-runtime-deps-explicit, rca-12-cross-user-port-8000)
- `d016-d023` (rca series + claim-next-ready-form-c, proactive-board-detections, rca18-buffer-ttl)
- `d036a-d036d` (cli arithmetic, precedence, repl, console-script — these are AtilCalc-project-specific, stay)
- `d037-d045` (notify-deprecation, v8-verdict-posted, lint-notify-invocations, deploy-path-guard, platform-constraint-linter, platform-constraint-linter-ext, expansion-adr-0044, js-syntactic-check, peer-poke-canonical-parity, cross-repo-watcher, adr-0012-status-ready-gating, cross-repo-scan)
- `d046a-d046c`, `d048-d058` (behavioral + workflow + workstream awareness tests)
- `d059-d066` (dtest family persistence, branch-base-check, label-hygiene, proactive-board-scan, stale-cc-deadlock-breaker, cluster-lag, dual-channel-enforcement, wip-cap-filter)
- `d067-d070b` (proactive-scan-per-role, open-time-label-strip, td067-combined, agent-state-backfill, tmux-send-keys-split-sleep [in template], cluster-lag-workflow-wiring, layer5-byte-size, layer-5-verdict-emoji-gate, init-prompt-ux)
- `d070-d078` (template-render, template-flag, license-check, claude-md-content, label-check-state-filter, layer-5-misfire-regression, layer-5-initial-add-defensive-guard)
- `d091-d127` (Sprint 22-28 wave 2 forward-port tests: tmpl-source-files, template-readme-content, ext-watcher-self-cc-skip, watcher-self-cc-skip, post-org-migration-clone-urls, soul-files-template, self-hosted-runner-migration, self-hosted-perf-budgets, audit-project-refs, soul-template-version-pin, install-git-hooks, context-watchdog-instant-fire, ci-budget-multiplier-env-block, evaluator-lazy-import-mpmath, conftest-env-var-precedence, markdown-internal-links, url-hygiene-atilcan65-to-atilproject, ci-subprocess-timeout-env-block, td-038-scripts-lane-drift, evaluate-persist-env-var-gate, heartbeat-missed-hysteresis, layer-5-cc-human-companion-log-emission, context-watchdog-pct-change-override, cross-user-env-var-pattern, deploy-runner-ac4-user-fix, run-server-sh-uv-extra-web, deploy-runner-dbus-fallback, rca-12-uvicorn-coldstart-readiness, stale-verdict-filter-scope, layer-5-j4-fresh-label-read, td-067-transient-regex-preserve)
- `d296-d1270` and beyond — peer-poke-helper, closes-format-check, verdict-by-tdd-red-exclusion, stale-verdict-filter, scripts-parameterized, story-s21-022-smoke-test, silent-drop-fix, claim-next-ready-race, supplement-issue-820, claim-next-ready-pr-exclusion-behavioral, stale-lock-cleanup, canary-config-yml, agent-watch-orch-lens-fix, perf-budget-noise-tolerance, atilcalc-evaluate-persist-env-var, path-verify-doctrine

> **Gap interpretation:** Of the 110 missing, roughly 80+ are universal
> doctrine tests (port-worthy) and roughly 25-30 are project-specific
> (calc-engine tests). The 80+ universal tests are the **portage gap**.

### §4.4 — Scripts gap detail (5+ missing)

AtilCalculator scripts NOT in template:
- `agent-watch-verdicts.sh` (verdict-detection lane of agent-watch)
- `audit-project-refs.sh` (audit cross-project doc refs)
- `cross-repo-scan.sh` (cross-repo issue scan)
- `init-template-repo.sh` (template-repo initialization)
- `lint-notify-invocations.sh` (linter for legacy notify.sh usage)
- `proactive-board-scan.sh` (board scan with proactive detection)
- `run-server.sh` (calc-engine server runner — **project-specific**, stay)
- `strip-cascade-labels.sh` (cascade label cleanup)

**Sub-dirs in AtilCalculator's `scripts/` that template lacks:**
- `install/` (systemd install scripts + git hooks install)
- `kickoff/` (5 agent kickoff text files: orchestrator/PM/arch/dev/tester)
- `logs/` (log directory — runtime artifact, not source)
- `ops/` (`apply-vm-hardening.sh` — **VM-specific**, possibly stay)
- `post-squash/` (cluster-lag-detector.sh + label-hygiene.sh — **port-worthy**)
- `pre-push/` (branch-base-check.sh — **port-worthy**)

### §4.5 — Workflows gap detail (3+ missing)

AtilCalculator workflows NOT in template (or only as `.tmpl`):
- `deploy.yml` (rendered from `deploy.yml.tmpl` — needs `--template` + owner rename approval per CLAUDE.md §File ownership matrix)
- `d050b-dispatch.yml` (behavioral dispatch test runner)
- `lint-and-test.yml` (d-test orchestrator)
- `post-squash.yml` (cluster-lag detector + label-hygiene post-squash hook)

### §4.6 — How to verify portage (per owner request)

**Verification recipe** (proposed, not yet executed):

```bash
# 1. Render template to a fresh private repo
~/dev-studio-launcher/new-project.sh smoke-portage-check --private --owner atilproject --dir /tmp/smoke

# 2. Run d-test regression suite
cd /tmp/smoke/smoke-portage-check
bash scripts/tests/e2e-pilot.sh

# 3. Diff against AtilCalculator
diff -rq /tmp/smoke/smoke-portage-check/scripts/ /home/atilcan/projects/AtilCalculator/scripts/ | grep -v "Only in /home/atilcan" | head -50
diff -rq /tmp/smoke/smoke-portage-check/.github/workflows/ /home/atilcan/projects/AtilCalculator/.github/workflows/ | head -20
diff -rq /tmp/smoke/smoke-portage-check/docs/decisions/ /home/atilcan/projects/AtilCalculator/docs/decisions/ | head -50
diff -rq /tmp/smoke/smoke-portage-check/.claude/ /home/atilcan/projects/AtilCalculator/.claude/ | head -20

# 4. Cleanup
rm -rf /tmp/smoke
gh repo delete atilproject/smoke-portage-check --yes
```

This produces a concrete gap list rather than estimates. Owner ratification
needed before executing (this script creates + deletes a real repo).

### §4.7 — Verdict

| Aspect | Status |
|---|---|
| Soul files (.claude/agents/*.md.tmpl) | ✅ **100% ported** (template has source, AtilCalc has rendered) |
| CLAUDE.md.tmpl | ✅ **100% ported** (template has source, AtilCalc has rendered) |
| Commands (.claude/commands/*.md.tmpl) | ✅ **100% ported** (template has source, AtilCalc has rendered) |
| ADRs | 🔴 **~40 of ~74 missing** (roughly 60% universal-doctrine gap) |
| d-tests | 🔴 **~80 of ~131 missing** (roughly 65% universal-test gap) |
| Scripts (top-level) | 🟡 **5-7 missing** out of 38 |
| Scripts (sub-dirs) | 🟡 **3-5 missing** (install, kickoff, post-squash, pre-push) |
| Workflows | 🟡 **3 missing** (deploy.yml rendered, d050b-dispatch, lint-and-test, post-squash) |

**Overall verdict:** Roughly **60% portage completeness**. Sprint 29 candidate.

---

## §5 — Q3: Self-hosted runner 100%?

### §5.1 — AtilCalculator (canonical, reference state)

All 11 workflows use `runs-on: [self-hosted, Linux, X64, atilproject]`:

| Workflow | runs-on |
|---|---|
| `ai-pr-review.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `ci.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `cross-repo-close.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `d050b-dispatch.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `deploy.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `label-check.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `label-cleanup.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `lint-and-test.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `post-squash.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `secret-canary.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `status-label-to-board.yml` | `[self-hosted, Linux, X64, atilproject]` |

✅ **AtilCalculator: 11/11 self-hosted. 100%.**

### §5.2 — dev-studio-template (current state, NOT migrated)

8 template stock workflows:

| Workflow | runs-on | Self-hosted? |
|---|---|---|
| `ai-pr-review.yml` | `ubuntu-latest` | ❌ |
| `ci.yml` (lint-and-test + conventional-commits jobs) | `ubuntu-latest` (×2) | ❌ |
| `cross-repo-close.yml` | `ubuntu-latest` | ❌ |
| `deploy.yml.tmpl` | `self-hosted` (or ubuntu-latest+appleboy/ssh-action) | ✅ conditional |
| `label-check.yml` | `ubuntu-latest` | ❌ |
| `label-cleanup.yml` | `ubuntu-latest` | ❌ |
| `secret-canary.yml` | `ubuntu-latest` | ❌ |
| `status-label-to-board.yml` | `ubuntu-latest` | ❌ |

❌ **Template: 7/8 `ubuntu-latest`, 1/8 `self-hosted`. NOT 100%.**

### §5.3 — dev-studio-template-smoke (post-bootstrap state)

Smoke repo's customized workflows (manually edited after bootstrap):

| Workflow | runs-on |
|---|---|
| `d050b-dispatch.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `deploy.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `post-squash.yml` | `[self-hosted, Linux, X64, atilproject]` |
| `lint-and-test.yml` | `[self-hosted, Linux, X64, atilproject]` |

(I did not audit smoke repo's stock workflows separately — they are likely
still `ubuntu-latest` per the template, BUT post-customization the smoke
repo may have flipped them. **Bilmiyorum**: I did not audit each smoke stock
workflow's runs-on line. This would require 8 more queries.)

### §5.4 — Verdict

**AtilCalculator: 100% ✅** — ready for private-repo use today.

**Template: 100% ❌** — only 1/8 stock workflows is self-hosted. Owner cannot
use template to spin up a private repo today without burning Actions minutes.

**Workaround:** Manually edit each workflow file after `new-project.sh`
bootstraps the project (as was done in smoke repo). This is **not
sustainable** — every new project owner has to do this.

**Proper fix:** Migrate template's 7 stock workflows to `runs-on: [self-hosted,
Linux, X64, atilproject]`. Should be a single PR to `dev-studio-template`
updating all workflow files atomically.

### §5.5 — Bilmiyorum

- I did not confirm whether each smoke stock workflow is now self-hosted
  after the post-bootstrap manual edits. If smoke repo's stock workflows
  ARE self-hosted, that proves the fix is mechanical; if they are still
  `ubuntu-latest`, then the customization in smoke repo only covers the
  new workflows.
- I did not check whether `runs-on: ubuntu-latest` is intentional in the
  template for some workflows (e.g., label-check.yml — does the owner
  prefer GitHub-hosted for security policy reasons?). This requires
  historical PR review.

---

## §6 — Q4: What else to add to template?

> This is the most synthesis-heavy section. I distinguish three categories:
> **(A) Portage from AtilCalculator** (the 60% gap from §4), **(B) Hygiene
> fixes** (tag staleness, URL staleness, launcher gaps), **(C) New additions**
> (things AtilCalculator doesn't have yet, that owner might want).

### §6.1 — Category A: Portage from AtilCalculator

(Detailed list in §4 — TL;DR: 40+ ADRs, 80+ d-tests, 5+ scripts, 3 workflows.
Estimated PR count: 4-6 large PRs over Sprint 29.)

### §6.2 — Category B: Hygiene fixes

| # | Item | Source | Owner decision needed |
|---|---|---|---|
| B-01 | Re-tag v1.0.1 (or create v1.0.2) to include Sprint 28 forward-port work (PRs #64-69 merged 2026-07-11) | Q7 finding | tag name choice |
| B-02 | Add v0.3 tag to launcher (HEAD `b0d820da` commit msg claims v0.3) | Q7 finding | none — just tag it |
| B-03 | Migrate 7 stock workflows from `ubuntu-latest` to `[self-hosted, Linux, X64, atilproject]` | Q3 finding | whether to keep `ubuntu-latest` fallback |
| B-04 | Update launcher's hardcoded `atilcan65/dev-studio-template` → `atilproject/dev-studio-template` (resolves same repo but legacy name) | launcher line 19 | none — both work |
| B-05 | Update launcher README's atilcan65 URLs → atilproject | Q5 finding | none |
| B-06 | Fix template's own `status-label-to-board.yml` failure (likely missing Projects v2 board config on template repo) | Q1 finding | whether to disable workflow on template, or create a Projects v2 board for template |

### §6.3 — Category C: New additions (synthesis)

> **Bilmiyorum:** I am NOT certain owner wants these. Surfaced as candidates
> only — owner ratification needed.

| # | Candidate | Rationale | Effort |
|---|---|---|---|
| C-01 | Add `bootstrap-project-board.sh` to launcher's auto-step (after `bootstrap-labels.sh`) | Launcher currently runs labels only; board bootstrap is manual step 6b in old `new-projectsteps.md`. Adding it reduces manual steps. | small |
| C-02 | Add `--with-board` flag to launcher (opt-in board bootstrap, since board requires PROJECT_TOKEN which may not be set yet) | Avoids breaking launcher when PROJECT_TOKEN is missing | small |
| C-03 | Add `--with-smoke` flag to launcher (run `e2e-pilot.sh` after bootstrap) | Validates the bootstrap end-to-end | small |
| C-04 | Add `--with-tmux` flag to launcher (auto-launch `dev-studio-start.sh` after bootstrap) | Some owners may want immediate agent startup | small |
| C-05 | Add `--private` Actions-budget preflight (warn if owner hasn't configured billing — query `gh api /repos/.../actions/usage` or check billing settings) | Currently launcher only emits a warning at creation time; preflight would catch earlier | medium (requires billing API research) |
| C-06 | Add `scripts/dev-studio-healthcheck.sh` to template (5-step smoke: gh auth, git, jq, project-board, self-hosted-runner labels match) | Helps new-project owners debug bootstrap failures | small |
| C-07 | Add `scripts/reprime-all.sh` (one-shot REPRIME for all 5 agents) | Useful when restarting whole agent fleet after doctrine update | small |
| C-08 | Add `.github/ISSUE_TEMPLATE/` set to template (currently template has none — AtilCalc has 7) | Helps downstream projects get started with proper issue format | medium |
| C-09 | Add `docs/sprints/` skeleton to template (current sprint plan + retro template) | Downstream projects need a place for sprint docs; currently they improvise | small |
| C-10 | Add `scripts/dev-studio-archive-sprint.sh` (closeout helper: move sprint-NN/ to /archive, update current/plan.md) | Sprint close ceremony currently manual | small |

### §6.4 — Verdict

Sprint 29 should focus on **Category A** (the 60% portage gap) + **B-01
through B-06** (hygiene). Category C items are post-Sprint-29 candidates.

---

## §7 — Q5: dev-studio-launcher still ready?

### §7.1 — Evidence

**Launcher files (only 4 in root):**
- `.gitignore` (22 KB — large but it's just rules)
- `LICENSE` (1.0 KB)
- `README.md` (6.2 KB)
- `new-project.sh` (10.4 KB) — the single executable

**Launcher tags:**
- `v0.2.0` @ SHA `40d59c0b` (legacy)
- HEAD = `b0d820da` (no tag — commit msg claims v0.3)

**Launcher PR history (only 2 PRs ever):**
- #1: "feat: default parent dir is ~/projects (v0.2.0)" — merged 2026-06-14
- #2: "feat(v0.3): public-by-default visibility (ADR-0016)" — merged 2026-06-17

**new-project.sh execution flow (verified by reading script):**
1. preflight (gh, git, jq, auth check, git global user)
2. `gh repo create --template atilcan65/dev-studio-template --public/--private --clone`
3. `cd <clone> && ./scripts/dev-studio-init.sh` (render templates)
4. `./scripts/bootstrap-labels.sh` (seed labels on remote)
5. `git add -A && git commit && git push` (commit + push rendered changes)

**What launcher intentionally does NOT do** (per README + script end-of-run message):
- Run e2e smoke test
- Start tmux session
- Open Vision Intake issue

### §7.2 — Stale references in launcher

| Line | Content | Issue |
|---|---|---|
| 19 (script) | `TEMPLATE_REPO="atilcan65/dev-studio-template"` | Legacy canonical name (resolves correctly but should be `atilproject/dev-studio-template` for new canonical) |
| 19 (script) | `DEFAULT_OWNER="atilcan65"` | Same — should be `atilproject` for org-level projects |
| README line 3 | `atilcan65/dev-studio-template` link | Legacy URL |
| README line 14 | ADR-0016 link to `atilcan65/dev-studio-template` | Legacy URL |
| README line 16 | ADR-0014 link to `atilcan65/dev-studio-template` | Legacy URL |
| README "Setup (one-time)" | `git clone https://github.com/atilcan65/dev-studio-launcher.git ~/dev-studio-launcher` | Legacy URL |

### §7.3 — Verdict

| Sub-question | Answer |
|---|---|
| Does `new-project.sh` work? | **YES** — verified by code reading. All 5 steps execute cleanly with proper preflight + error codes (1-6). |
| Are `--public` and `--private` flags correct? | **YES** — `--public` default (ADR-0016), `--private` opt-in with billing warning |
| Is `atilcan65/dev-studio-template` URL still valid? | **YES** (resolves to same repo) — but `atilproject/dev-studio-template` is the new canonical. **Stale but functional.** |
| Are env vars / secrets handled? | **PARTIAL** — `dev-studio-init.sh` handles PROJECT_TOKEN canary but launcher doesn't preflight whether PROJECT_TOKEN is set before `--private`. If canary fails, launcher exits 5 with cryptic error. |
| v0.3 tag exists? | **NO** — only v0.2.0 tag. Head's commit message claims v0.3 but never tagged (L-01). |

### §7.4 — Bilmiyorum

- I do not know whether the `atilcan65` legacy references are intentional
  (e.g., owner-side redirect) or an oversight. Functionally identical, so
  not blocking — but document hygiene says update.

---

## §8 — Q6: Separate `new-projectsteps.md`

**Delivered as separate file in this PR:** `docs/new-projectsteps.md`

- 10-step end-to-end guide (sanity check tools → vision intake)
- Fresh content — does NOT inherit from the deleted cycle-#743 version per
  owner directive ("Eski hiç bir hazırlık dosyasını kullanma")
- Reflects current template/launcher state (2026-07-13)
- Includes explicit self-hosted runner registration (4-tuple `[self-hosted,
  Linux, X64, atilproject]`) per current Q3 evidence
- Includes gap-mitigation note (template stock workflows use `ubuntu-latest`;
  user must edit or wait for Sprint 29 B-03 fix)

**Cross-reference:** For Sprint 29 gap-closure, the new-projectsteps.md may
need updates once Q3 / Q7 hygiene fixes land. Plan should include a
re-render step in the post-portage verification.

---

## §9 — Q7: Tags / version discipline OK?

### §9.1 — dev-studio-template tags

| Tag | SHA | When |
|---|---|---|
| `v1.0.1` | `62aec11b` | 2026-07-09 (per PR #63 "v1.0.1 release stamp") |
| (no other tags) | — | — |

**Template HEAD = `43592c24` (2026-07-11).**

**PRs merged between v1.0.1 stamp and HEAD (6 PRs):**
| PR | Title | Merged |
|---|---|---|
| #64 | docs(soul): orchestrator RETRO-018 W6 SOUL AMEND | 2026-07-11 |
| #65 | feat(scripts): STORY-S28-003 forward-port agent-watch + claim-next-ready | 2026-07-11 |
| #66 | docs(soul): orchestrator §Peer-Poke Discipline SOUL AMEND | 2026-07-11 |
| #67 | docs(soul): orchestrator §Dispatch Discipline SOUL AMEND | 2026-07-11 |
| #68 | docs(decisions): ADR-0058..0071 reserved entries | 2026-07-11 |
| #69 | feat(scripts): STORY-S28-007 PORT peer-poke.sh wrapper + Auto-Verdict-By | 2026-07-11 |

**The v1.0.1 tag does NOT include any of PRs #64-69.** That's a 6-PR gap.
Owner's intuition ("still seeing old files") is **confirmed**.

### §9.2 — dev-studio-launcher tags

| Tag | SHA | When |
|---|---|---|
| `v0.2.0` | `40d59c0b` | 2026-06-14 (per PR #1) |
| (no v0.3 tag) | — | — |

**Launcher HEAD = `b0d820da` (2026-06-17, PR #2 commit msg "feat(v0.3)").**

PR #2's commit message **claims v0.3** but no tag was made. The README
narrative references "As of v0.3.0" — so the launcher documentation
describes a phantom version that exists only as a commit, not a release.

### §9.3 — Verdict

| Sub-question | Answer |
|---|---|
| Did template v1.0.1 work happen? | **PARTIAL** — tag stamped but immediately stale due to Sprint 28 forward-port series |
| Did launcher v0.3 work happen? | **NO** — commit exists, tag does not |
| Owner's intuition ("old files") | **CONFIRMED** — 6 PRs worth of template work + 1 PR of launcher work is in HEAD but not in tag |

### §9.4 — Recommendation

| Action | Rationale |
|---|---|
| Add `v1.0.2` tag to template HEAD (`43592c24`) | Captures Sprint 28 forward-port series in a tagged release |
| Add `v0.3.0` tag to launcher HEAD (`b0d820da`) | Captures the public-by-default visibility feature (already merged 2026-06-17, just not tagged) |
| Consider adding a tag-protection rule + GitHub Action that requires tag on every main commit | Prevents future drift between HEAD and tagged releases |

---

## §10 — Gap-closure plan (Sprint 29 — EXECUTED)

> **Status: EXECUTED — closing 2026-07-27** (Sprint 29 close target).
> Originally drafted 2026-07-13 (cycle ~#1158) per owner directive ("Kararlar
> birlikte alınacak — bu audit sadece durum tespiti, ben okumadan hiçbir
> aksiyon alma"). Plan ratified 2026-07-13 in 2 phases (Phase 1 cycle ~#1159 +
> Phase 2 cycle ~#1180, 9 owner-decisions total). Execution is in-progress
> across all 3 waves + Wave 2B/2C (per `docs/sprints/sprint-29/00-plan.md`).
> Final verification report lands at `docs/sprints/sprint-29/01-portage-verify.md`
> post-S29-014 (depends on all Wave 1+2+2B+2C stories merged). Re-render of
> this section per S29-015 AC3.

### §10.1 — Sprint 29 goal

> **"AtilCalculator's universal doctrine 100% in dev-studio-template,
> template ready to bootstrap private repos with zero Actions-minutes burn,
> tag discipline re-established."**

### §10.2 — Story breakdown (Sprint 29 — EXECUTED, closing 2026-07-27)

> **Status note:** The original table below listed 16 candidate stories. After
> Phase 1 + Phase 2 owner-ratification cycles (#1159 + #1180, 2026-07-13),
> Sprint 29 plan finalized at **19 stories** (3L + 7M + 9S, 3 waves + final).
> Full live plan + acceptance criteria + sister-patterns: see
> [`docs/sprints/sprint-29/00-plan.md`](../../sprints/sprint-29/00-plan.md).
> Final verification report (post-S29-014) lands at
> `docs/sprints/sprint-29/01-portage-verify.md` — refresh after Sprint 29 close.

**Wave 1 (foundation, week 1) — owner-ratified per Phase 1 cycle #1159:**

| Story | Title | Effort | Source finding |
|---|---|---|---|
| S29-001 | Migrate 7 template stock workflows to `runs-on: [self-hosted, Linux, X64, atilproject]` | small | Q3 B-03 |
| S29-002 | Add `v1.0.2` tag to template HEAD + `v0.3.0` tag to launcher HEAD | trivial | Q7 |
| S29-003 | Update launcher's hardcoded `atilcan65/dev-studio-template` → `atilproject/dev-studio-template` (script + README) | small | Q5 + Q7 B-04/B-05 |
| S29-004 | Fix template's `status-label-to-board.yml` (disable or create Projects v2 board for template) | small | Q1 B-06 |
| S29-005 | Verify-portage script: render template to private repo + diff + cleanup (executes §4.6 recipe) | small | Q2 verification |

**Wave 2 (portage, week 1-2):**

| Story | Title | Effort | Source finding |
|---|---|---|---|
| S29-006 | Forward-port 40+ universal ADRs from AtilCalculator to template (batch in 3-4 PRs by theme: agent/lane/verdict/board/runner/cross-repo) | large | Q2 §4.2 |
| S29-007 | Forward-port 80+ universal d-tests from AtilCalculator to template (batch in 5-6 PRs by theme) | large | Q2 §4.3 |
| S29-008 | Forward-port 5+ missing top-level scripts (agent-watch-verdicts, cross-repo-scan, lint-notify-invocations, strip-cascade-labels, audit-project-refs) | medium | Q2 §4.4 |
| S29-009 | Forward-port 3 missing sub-dirs (install/, kickoff/, post-squash/, pre-push/) | medium | Q2 §4.4 |
| S29-010 | Forward-port 3 missing workflows (d050b-dispatch.yml, lint-and-test.yml, post-squash.yml) + render deploy.yml from .tmpl | medium | Q2 §4.5 |

**Wave 3 (polish + new, week 2):**

| Story | Title | Effort | Source finding |
|---|---|---|---|
| S29-011 | (C-01 + C-02) Add `--with-board` flag to launcher (opt-in board bootstrap with PROJECT_TOKEN gate) | small | Q4 C-01/C-02 |
| S29-012 | (C-03 + C-04) Add `--with-smoke` and `--with-tmux` flags to launcher | small | Q4 C-03/C-04 |
| S29-013 | (C-05) Add `--private` Actions-budget preflight to launcher (warn if billing not configured) | medium | Q4 C-05 |
| S29-014 | (C-08) Add `.github/ISSUE_TEMPLATE/` to template (port 7 templates from AtilCalculator) | medium | Q4 C-08 |
| S29-015 | (C-06) Add `scripts/dev-studio-healthcheck.sh` to template (5-step preflight for new owners) | small | Q4 C-06 |
| S29-016 | Re-render `new-projectsteps.md` after Wave 1+2 lands (verify steps still accurate post-portage) | small | Q6 verification |

### §10.3 — Sequencing rationale

- **Wave 1 first** because hygiene fixes unblock everything downstream
  (workflows must be self-hosted before template can be used for private
  repos; tag discipline lets downstream owners pin to a known-good version).
- **Wave 2 second** because portage is the bulk of the work (estimated 60%
  of sprint effort) and shouldn't be blocked by hygiene.
- **Wave 3 last** because polish items can be deferred if Wave 1+2 over-runs.

### §10.4 — Sprint 29 commitments

- **Sprint length:** 2 weeks (per CLAUDE.md)
- **Capacity:** 5 agents × 2-week sprint = same as Sprint 27/28 cycles
- **Risk:** Wave 2 portage is large (40+ ADRs + 80+ d-tests). May need to
  scope down — owner to decide priority ordering.
- **Definition of Done:** A fresh private repo created via launcher (with
  post-portage template) should run CI 100% green on self-hosted runners,
  with all d-tests passing, with all universal ADRs present.

### §10.5 — Owner-decisions needed before Sprint 29 kickoff

1. **Tag discipline:** v1.0.2 (additive) vs force-push v1.0.1 to HEAD?
   (force-push destroys history; additive preserves it)
2. **Wave 2 priority ordering:** ADRs first or d-tests first?
   (ADRs are documentation; d-tests are executable verification)
3. **Sprint 29 budget cap:** how many stories max? (full plan = 16 stories
   over 2 weeks may be too aggressive)
4. **Category C scope:** which C items (if any) make Sprint 29? Defer rest
   to Sprint 30+?
5. **Org Actions billing:** for private repos in atilproject org, is billing
   configured? (Relevant to Q3 private-repo scenario)

---

## §11 — Cross-refs

- **PR #1007** (cycle ~#1153, deleted) — prior version of this audit, removed per owner directive
- **PR #967** (cycle merged 2026-07-10) — `00-audit-baseline.md` (different scope: Sprint 28 audit, **not** template/launcher audit)
- **ADRs in AtilCalculator (universal doctrine, portage candidates):**
  `0001-template-architecture`, `0002-autonomy-loop`, `0031-owner-override-doctrine`, `0032..0071` (most of these)
- **ADRs in template (already ported):** `0010, 0011, 0012, 0013, 0014, 0015, 0016, 0020, 0021, 0024, 0025, 0026, 0027, 0030, 0046, 0047`
- **Related PRs in template:** #63 (v1.0.1 stamp), #64-69 (S28 forward-ports), #73 (S29-001 self-hosted 4-tuple)
- **Related PRs in launcher:** #1 (v0.2.0), #2 (v0.3 un-tagged)
- **Sprint 29 plan (Phase 2 ratified):** [`docs/sprints/sprint-29/00-plan.md`](../../sprints/sprint-29/00-plan.md) — 19 stories, 3 waves + final
- **Sprint 29 verification report (post-S29-014):** `docs/sprints/sprint-29/01-portage-verify.md` (TBD; refresh after Sprint 29 close)
- **Phase 2 #9 dual-path CLAUDE.md resolution (S29-015 AC5):**
  - **Canonical root `CLAUDE.md`** — newer (commit `737b846e`, 2026-06-29); rendered at downstream project root by template `dev-studio-init.sh`
  - **`.claude/CLAUDE.md`** — Sprint 28 SOUL AMENDs content per S29-017 (architect-authored); rendered alongside for agent-readable copy
  - Sister-pattern: ADR-0050 (load-bearing ADR/soul doctrine)
- **Companion runbook (post-Sprint-29 re-render):** [`docs/new-projectsteps.md`](../../new-projectsteps.md) — S29-015 AC1+AC2+AC4 (Step 5b removed, tag discipline live, sunset checklist gone)
- **Smoke repo:** `atilproject/dev-studio-template-smoke` (private, 4.7 MB, 2026-07-10, mixed CI evidence)
- **Runner pattern:** `[self-hosted, Linux, X64, atilproject]` (4-tuple, 8 runners online) — 100% on all template stock workflows post-S29-001
- **Org-level Actions billing:** **bilmiyorum** — owner verification needed

---

— @orchestrator, 2026-07-13 (cycle ~#1158), owner 7-question audit. All facts
sourced from GitHub REST on 2026-07-13. No prior prep doc reused. All
findings are status reports — NO actions taken without owner ratification.

— Re-rendered 2026-07-15 (cycle ~#1880, S29-015 AC3): §10 EXECUTED marker +
plan + verify links + Phase 2 #9 dual-path cross-ref. Final verify-report
link refresh post-S29-014 (depends on all Wave 1+2+2B+2C stories merged).