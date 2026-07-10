# Sprint 28 Audit Baseline — dev-studio-template & dev-studio-launcher feature parity

> **Purpose:** Owner-requested (2026-07-10) state-of-template audit before Sprint 28
> scope lock. **THIS IS STATE ASSESSMENT ONLY — NO ACTIONS TAKEN.** Every gap
> listed below is a candidate for Sprint 28 backlog after owner review.
>
> **Method:** Orchestrator's own audit, run cycle ~742–~743
> (2026-07-10T20:05+03:00). Files inspected via `ls` / `git log` /
> `wc -l` / `grep` against local working copies:
> - `~/projects/AtilCalculator` (HEAD = 85597c4)
> - `~/projects/dev-studio-template` (HEAD = 81ec0b1, tag v1.0.1)
> - `~/dev-studio-launcher` (HEAD = b0d820d, no v0.3.0 tag)
>
> Cross-checked against `gh api repos/atilproject/*` (REST, GraphQL rate-limited).
> **No git push to template or launcher.** Findings are observations only.

---

## Question 1 — Is dev-studio-template ready to launch as a private project in atilproject org?

### State assessment

**Org check:** `gh api /orgs/atilproject/members` → only `atilcan65` is a member
(per REST API snapshot cycle ~742). Single-member org = owner can create private
repos directly.

**Template structure:** Present and intact. The repository at
`atilproject/dev-studio-template` (HEAD 81ec0b1, tag v1.0.1, last push
2026-07-09T15:53Z) exposes the full scaffold: `scripts/` (31) +
`.claude/{agents,commands}/` (5 soul .tmpl + 2 command .tmpl) + `docs/{decisions,
templates}/` (16 ADRs + 4 templates) + `src/` + `tests/` + `systemd/` +
`pyproject.toml`.

**Launcher `--private` flag:** Present and documented in
`~/dev-studio-launcher/new-project.sh` (commit `b0d820d`, README "v0.3.0"
changelog row). README §Prerequisites warns: `PROJECT_TOKEN canary uses GitHub
Actions, which is paid on private repos. If init fails with 'job not'…`.

**What I CAN verify from the audit:**
- Template structure is present and matches ADR-0013 status-label-to-board + ADR-0014 PROJECT_TOKEN.
- Launcher syntax supports `--private` with the right warning.
- Org membership supports private repo creation (owner-only org today).

**What I CANNOT verify ("bilmiyorum"):**
- Whether the bootstrap actually finishes successfully on a private repo end-to-end. This requires a real dry-run with `PROJECT_TOKEN` injected + a fresh `atilproject/<new-project>` repo + observing `dreg-post-restart-label-guard.sh` and `d046-deploy-runner-env-validation.sh` pass.
- Whether existing org-level Actions billing limit is configured (Actions quota on private repos = metered, must be ≥ canary burn rate).
- Whether the canary remote (`dev-studio-template-smoke`) mirrors successfully into private-repo Actions minutes budget.

### Action items (proposed for owner review — NOT EXECUTED)

| # | Item | Owner | Sprint slot |
|---|------|-------|-------------|
| 1.1 | Sprint 28 STORY: `dry-run-launch-private.sh` — bash harness that runs `new-project.sh <scratch> --private` against a temp atilproject org private repo, verifies init + bootstrap + label-check + dreg + d046 all green. | developer | Sprint 28 wave 1 |
| 1.2 | Owner-confirm Actions billing limit on atilproject org before running 1.1. | owner (escalation) | pre-Sprint-28 wave 1 |
| 1.3 | Decision: keep template default visibility `public` (ADR-0016) OR flip to `private-by-default` for org-pinning. Currently `public`; launcher reflects this. | owner (escalation) | Sprint 28 plan-finalize |

---

## Question 2 — Are ALL AtilCalculator processes/scripts/doctrines/agents ported to dev-studio-template?

### State assessment

**NO. Substantial gaps.**

Gap categories (with concrete evidence):

#### A. Scripts — AtilCalculator has **15 entries NOT in template**

Set-difference `ls scripts/` calc (44) − template (31):

| File | In calc? | In tmpl? | Likely template-port candidate? |
|---|---|---|---|
| `agent-watch-verdicts.sh` | ✅ | ❌ | 🟡 (subset of `agent-watch.sh`, depends on verdict-by: labels) |
| `audit-project-refs.sh` | ✅ | ❌ | 🟢 (generic git audit, no project coupling) |
| `cross-repo-scan.sh` | ✅ | ❌ | 🟢 (sister of `cross-repo-close.sh`, generic) |
| `init-template-repo.sh` | ✅ | ❌ | 🔴 (project-bespoke, NOT port) |
| `lint-notify-invocations.sh` | ✅ | ❌ | 🟢 (linter over notify.sh callers) |
| `logs/` (dir) | ✅ | ❌ | 🟡 (log aggregation, defer) |
| `ops/` (dir) | ✅ | ❌ | 🟡 (depends on content) |
| `orchestrator-gap-scan.sh` | ✅ | ❌ | 🟢 (orchestrator auto-scan) |
| `peer-poke.sh` | ✅ | ❌ | 🔴 (LEGACY — ADR-0033 supersedes; should be REMOVED from calc too) |
| `ping.sh` | ✅ | ❌ | 🔴 (LEGACY wrapper of notify.sh; remove from calc) |
| `post-squash/` (dir) | ✅ | ❌ | 🟡 (post-merge cleanup hooks, generic) |
| `pre-push/` (dir) | ✅ | ❌ | 🟢 (git hooks, generic) |
| `proactive-board-scan.sh` | ✅ | ❌ | 🟢 (orchestrator, project-agnostic) |
| `run-server.sh` | ✅ | ❌ | 🔴 (atilcalc HTTP surface bespoke, NOT port) |
| `strip-cascade-labels.sh` | ✅ | ❌ | 🟢 (generic, sister to label-cleanup) |

🟢 = clear port, 🟡 = evaluate, 🔴 = project-bespoke or LEGACY.

**Template-only (in tmpl, missing calc):** `bootstrap-test-project.sh`, `owner-apply-soul-patch.sh`. Both are template-rendered scaffolding (calc would have older versions under different names).

#### B. ADRs — AtilCalculator has **75 ADRs, template has only 16**. ~59 ADRs gap.

Template's ADR list (`ls docs/decisions/`):
ADR-0010, 0011, 0012, 0013, 0014, 0015, 0016, 0020, 0021, 0024, 0025, 0026, 0027, 0030, 0046, 0047.

Calc's ADR list (`ls docs/decisions/ | wc -l` → 75) covers 75 entries from ADR-0001 onward including sprint-26/27 doctrine (e.g., ADR-0031 owner-merge-gate, ADR-0033 dual-channel-peer-poke, ADR-0038 auto-claim, ADR-0044 RED-first TDD, ADR-0045 9-lens, ADR-0049 d-test framework, ADR-0057 Closes anchor, ADR-0065 cpython-asyncio fix, ADR-0068 j4-tester, ADR-0070/71 diagnostics, plus many more).

**Not all 59 need to be ported.** Many are atilcalc-specific (engine perf,
CPython asyncio, J4 tester exception). Template-relevant subset (educated guess):
- ADR-0001, 0002, 0017 (tech-stack), 0022 (?), 0031, 0033, 0034 (?), 0038,
  0039 (?), 0040, 0044, 0045, 0049, 0054, 0057 — to be triaged one-by-one
  (Rule #1: only port doctrine that's truly template-agnostic, not project
  smell).

#### C. Soul files — Template `.claude/agents/orchestrator.md.tmpl` missing 2 SOUL AMENDs

Diff shows template orchestrator.tmpl **MUST BE UPDATED** with:

1. **`Issue #414 + RETRO-018 W6 SOUL AMEND`** (calc lines 61-63):
   "Branch ownership matrix cross-check — for any `[ORCH→<ROLE>]` directive
   containing `git rebase` / `git push --force-with-lease` / `git push`
   commands: verify `agent:*` label on target PR matches dispatched role."
   Source: PR #962 (calc `521c66e`, 2026-07-10).

2. **`Issue #389 SOUL AMEND` — §Peer-Poke Discipline — Dual-Channel Auto-Ping**
   (calc lines 65-92): The full §Peer-Poke Discipline doctrine explaining
   the `peer-poke.sh <role>` shape (Telegram + tmux). Currently template's
   CLAUDE.md.tmpl mentions `notify.sh -l <role>` (legacy single-channel) but
   doesn't codify the dual-channel pattern that ADR-0033 mandates.

#### D. Workflows — Template missing 3 workflow files calc has

| Workflow | In calc? | In tmpl? | Notes |
|---|---|---|---|
| `d050b-dispatch.yml` | ✅ | ❌ | 🟢 (event dispatch for d050, generic) |
| `lint-and-test.yml` | ✅ | ❌ | 🟢 (CI lint+test, generic) |
| `post-squash.yml` | ✅ | ❌ | 🟢 (post-merge cleanup hook, generic) |
| `label-check.yml`, `label-cleanup.yml`, `cross-repo-close.yml`, `status-label-to-board.yml`, `secret-canary.yml`, `ai-pr-review.yml`, `ci.yml`, `deploy.yml.tmpl` | ✅ | ✅ | all present (deploy.yml.tmpl is template version) |

#### E. Script size drift (proxy for feature drift)

- `agent-watch.sh`: tmpl 1019 LOC vs calc 2058 LOC (calc has **2x more**).
- `deploy-runner.sh`: tmpl 294 LOC vs calc 690 LOC (calc has **2.3x more**).
- `scripts/tests/`: tmpl 17 d-tests vs calc ~60+ d-tests. ~40+ test gaps.

### Action items (proposed for owner review — NOT EXECUTED)

| # | Item | Owner | Sprint slot |
|---|------|-------|-------------|
| 2.1 | STORY-T01: Port `audit-project-refs.sh`, `cross-repo-scan.sh`, `lint-notify-invocations.sh`, `orchestrator-gap-scan.sh`, `proactive-board-scan.sh`, `strip-cascade-labels.sh`, `pre-push/` → template. d-test each. | developer | Sprint 28 wave 1 |
| 2.2 | STORY-T02: Port `agent-watch-verdicts.sh` subset + `post-squash/` + `logs/`+`ops/` (after content review) → template. | developer | Sprint 28 wave 2 |
| 2.3 | STORY-T03: REMOVE `peer-poke.sh` + `ping.sh` from AtilCalculator (ADR-0033 supersedes; legacy noise). | developer | Sprint 28 wave 1 |
| 2.4 | STORY-T04: Port W6 SOUL AMEND (Issue #414 + RETRO-018 W6) to `orchestrator.md.tmpl`. | architect | Sprint 28 wave 1 |
| 2.5 | STORY-T05: Port §Peer-Poke Discipline (Issue #389 SOUL AMEND) to `orchestrator.md.tmpl` + `CLAUDE.md.tmpl`. | architect | Sprint 28 wave 1 |
| 2.6 | STORY-T06: ADR triage — for each calc ADR 0001-0071, classify (port + flag, defer, project-bespoke). Output: `docs/sprints/sprint-28/02-adr-port-triage.md`. | architect | Sprint 28 wave 1 |
| 2.7 | STORY-T07: Port 3 missing workflows (`d050b-dispatch.yml`, `lint-and-test.yml`, `post-squash.yml`) → template. | developer | Sprint 28 wave 2 |
| 2.8 | STORY-T08: d-test parity — for each ported script, port or write a d-test equivalent (≥5 TCs each per ADR-0049). | tester | Sprint 28 wave 2-3 |
| 2.9 | STORY-T09: Reconcile `agent-watch.sh` + `deploy-runner.sh` LOC drift (calc has more — port back if generic, split if project-bespoke). | developer | Sprint 28 wave 3 |

---

## Question 3 — Self-hosted runner migration 100% complete?

### State assessment

**AtilCalculator: YES, 100% complete.** All 12 workflow files grep'd:

```
$ grep "runs-on:" /home/atilcan/projects/AtilCalculator/.github/workflows/*.yml
ai-pr-review.yml:        runs-on: [self-hosted, Linux, X64, atilproject]
label-cleanup.yml:       runs-on: [self-hosted, Linux, X64, atilproject]
cross-repo-close.yml:    runs-on: [self-hosted, Linux, X64, atilproject]
deploy.yml:              runs-on: [self-hosted, Linux, X64, atilproject]
secret-canary.yml:       runs-on: [self-hosted, Linux, X64, atilproject]
ci.yml:                  runs-on: [self-hosted, Linux, X64, atilproject]
ci.yml:                  runs-on: [self-hosted, Linux, X64, atilproject]
lint-and-test.yml:       runs-on: [self-hosted, Linux, X64, atilproject]
post-squash.yml:         runs-on: [self-hosted, Linux, X64, atilproject]
d050b-dispatch.yml:      runs-on: [self-hosted, Linux, X64, atilproject]
label-check.yml:         runs-on: [self-hosted, Linux, X64, atilproject]
status-label-to-board.yml: runs-on: [self-hosted, Linux, X64, atilproject]
```

Every workflow on `runs-on: [self-hosted, Linux, X64, atilproject]`.

**Template: NO, 0% migrated.** All 8 workflow files grep'd:

```
$ grep "runs-on:" /home/atilcan/projects/dev-studio-template/.github/workflows/*.yml
ai-pr-review.yml:        runs-on: ubuntu-latest
ci.yml:                  runs-on: ubuntu-latest
ci.yml:                  runs-on: ubuntu-latest
cross-repo-close.yml:    runs-on: ubuntu-latest
label-check.yml:         runs-on: ubuntu-latest
label-cleanup.yml:       runs-on: ubuntu-latest
secret-canary.yml:       runs-on: ubuntu-latest
status-label-to-board.yml: runs-on: ubuntu-latest
```

Template workflows will FAIL on private repos because:
- Private repo + `runs-on: ubuntu-latest` = Actions usage billed
- Most users have low Actions budgets; private CI runs against monthly limit
- A private repo bootstrap will hit quota rapidly with 8 workflows × daily CRON runs
- **Atilcalculator's golden path uses self-hosted entirely — template doesn't inherit that**

### Action items (proposed for owner review — NOT EXECUTED)

| # | Item | Owner | Sprint slot |
|---|------|-------|-------------|
| 3.1 | STORY-T10: ADR-XXXX "Self-hosted runner as default in template" — draft + accept. Sister to AtilCalculator ADR-0030. Update all 8 template workflow files to `runs-on: [self-hosted, Linux, X64, atilproject]` (or org-generic label, owner-decide). | architect + owner | Sprint 28 wave 1 |
| 3.2 | STORY-T11: Template-only deprecation guide — when owner runs `new-project.sh`, post-init emit a `RUNNER-SETUP.md` listing the self-hosted runner registration commands (manual, owner-driven per ADR-0016). | developer + owner | Sprint 28 wave 2 |
| 3.3 | Owner-decide: do we add `runs-on: [self-hosted, Linux]`  generically to template (so any org's runner can pick up) OR keep template generic-public (each project self-registers)? | owner (escalation) | pre-Sprint-28 wave 1 |

---

## Question 4 — What could be added to template (since it's now the focus)?

### State assessment

Beyond question 2/3 gaps, candidate additions:

| Candidate | Source | Notes |
|---|---|---|
| `scripts/codex-runner.sh` (test runner / incident bot) | AtilCalculator | Mentioned in CLAUDE.md but the script itself was never committed (only conceptually referenced). |
| `.claude/agents/incident-bot.md` soul | Not in either repo | If we adopt a 6th agent (incident triage), need soul template. |
| `docs/sprints/souls/*.md.tmpl` | AtilCalculator-adjacent | Template has `.claude/commands/{sprint-start,standup}.md.tmpl` but no `docs/sprints/souls/` template skeleton. |
| Per-project ADR numbering helper (`scripts/next-adr-id.sh`) | latent need | calc manually maintains ADR-XXXX; an allocator script would help. |
| `scripts/peer-poke.sh` (dual-channel) | Inline in calc issue workflows | After ATR-0033 supersedes single-channel, port the canonical `peer-poke.sh` to template. |
| `scripts/health-check.sh` and `scripts/event-log.sh` rules | calc has these | verify if generic enough; port or generalize. |
| ADR canonical for queue-empty / watchdog schemas (ADR-0024/25/26 sister-patterns) | Port from calc | Template already has these. ✅ |

**What I CANNOT verify ("bilmiyorum"):** Whether AtilCalculator itself has been audited against the full `dev-studio-template` scope — there may be additional calc-only doctrinethat has equivalent template coverage but wasn't found via my set diff.

### Action items (proposed for owner review — NOT EXECUTED)

| # | Item | Owner | Sprint slot |
|---|------|-------|-------------|
| 4.1 | STORY-T12: Audit calc's `codex-runner.sh` reference vs actual existence; either port or remove from CLAUDE.md. | developer | Sprint 28 wave 2 |
| 4.2 | STORY-T13: `scripts/peer-poke.sh` (dual-channel) → template port. | developer | Sprint 28 wave 2 |
| 4.3 | Owner-decide: is the focus "make template 100% feature-parity" or "freeze template at current state and move on"? | owner (escalation) | pre-Sprint-28 wave 1 |

---

## Question 5 — Is dev-studio-launcher still ready?

### State assessment

**Yes, mostly. Two cleanup items.**

| Item | State |
|---|---|
| `new-project.sh` syntax | ✅ v0.3 features (`--public|--private`, default parent dir) all in place. |
| Launcher's `b0d820d` on remote | ✅ (no local/remote divergence). |
| `--private` flag works | ✅ (per README + script grep). |
| **v0.3.0 git tag** | ❌ NOT TAGGED. Last tag is v0.2.0. The b0d820d commit message says "v0.3" but the tag is missing. |
| **3-week dormant** | Last push was 2026-06-17T06:49:34Z → dormant 3+ weeks. Likely just because no new features; not a defect. |
| **DEPENDENCY on template** | Launcher clones `dev-studio-template.git`. If template is at v1.0.1, new projects bootstrap to v1.0.1 (✅, defaults). But questions 2-4 gaps mean template is **behind**, so new projects start with the gaps. |

### Action items (proposed for owner review — NOT EXECUTED)

| # | Item | Owner | Sprint slot |
|---|------|-------|-------------|
| 5.1 | Tag launcher's current HEAD (b0d820d) as `v0.3.0`. Add CHANGELOG row. | orchestrator (low-risk chore) | Sprint 28 wave 1 |
| 5.2 | Verify launcher handles AtilCalculator's org-edge-cases (e.g., self-hosted runner label match). Currently launcher is org-agnostic. | owner | post-Sprint-28 wave 3 |

---

## Question 6 — Detailed new-project setup doc

### State assessment

Already drafted as `docs/new-projectsteps.md` in this same branch/PR. See that file.

(Owner wanted this as a separate doc; located at repo root `docs/new-projectsteps.md`
per request, not inside `sprints/sprint-28/`.)

### Action items

| # | Item | Owner | Sprint slot |
|---|------|-------|-------------|
| 6.1 | Owner-review `docs/new-projectsteps.md` in PR. | owner | pre-Sprint-28 wave 1 |
| 6.2 | After approval, consider also embedding this doc in `~/dev-studio-launcher/README.md` as the canonical owner-facing runbook. | developer | Sprint 28 wave 3 |

---

## Question 7 — Is template REALLY at 1.0.1 and all "necessary work" done?

### State assessment

**Template v1.0.1: ✅ YES.**

- Tag exists: `v1.0.1` (latest in `git tag -l --sort=-creatordate`).
- CHANGELOG.md has `[1.0.1] - 2026-07-09` section stamp at commit `81ec0b1`.
- That CHANGELOG entry documents the TD-068b tmux send-keys split+sleep fix
  (5-site atomic patch, sister to AtilCalculator PR #936 squash `5c4e5784`).
- Pre-1.0.1 → 1.0.1 commit history shows 10+ feature/dock commits
  (`#39` Issue #238 doctrine, `#40/#41` soul amendments, ADR-0047 deploy pattern
  port, etc.) — content is substantive, not a vanity tag.

**Launcher v0.3.0: ⚠️ partial.**

- Source commit `b0d820d feat(v0.3): public-by-default visibility, --private opt-in` IS on remote main.
- **No `v0.3.0` tag** (highest tag is `v0.2.0`).
- CHANGELOG row for v0.3 — present in launcher's `README.md` (I read it above), but inconsistent with git tag.
- Last-push 3+ weeks old → dormant, not stale per se.

**Whether "all necessary work" is done: NO. Substantial gaps remain per Q1-Q5.**

The user's intent ("template tamamlandıysa") implies a completeness claim.
Per Q2/Q3/Q4: **template is NOT complete** as a private-repo bootstrap target.
It is complete as a public-repo bootstrap target (Q1 partial verification).

### Action items (proposed for owner review — NOT EXECUTED)

| # | Item | Owner | Sprint slot |
|---|------|-------|-------------|
| 7.1 | Decision: this audit reveals template IS NOT at 100% feature parity. Either (a) scope Sprint 28 to gap-closure, OR (b) accept partial + deprecate calc. Owner decider. | owner (escalation) | pre-Sprint-28 wave 1 |
| 7.2 | STORY-T14: Tag launcher v0.3.0 + add missing CHANGELOG entries for any other un-tagged-but-committed features. | orchestrator | Sprint 28 wave 1 |
| 7.3 | STORY-T15: Document template "stable checkpoint" plan — when IS template considered 1.0.2 / 1.1.0 / 2.0? | architect + owner | Sprint 28 wave 2 |

---

## Summary of action categories

- **Decision needed before Sprint 28 kickoff (owner escalation):** 1.2, 1.3, 3.3, 4.3, 7.1
- **Sprint 28 wave 1 candidates:** 1.1, 2.1, 2.3, 2.4, 2.5, 2.6, 3.1, 5.1, 7.2
- **Sprint 28 wave 2 candidates:** 2.2, 2.7, 2.8, 3.2, 4.1, 4.2, 7.3
- **Sprint 28 wave 3 candidates:** 2.9, 5.2, 6.2

Total: ~22 candidate stories. Owner to triage + scope-lock.

## Knowledge gaps declared

- **Q1** "ready to launch as private" requires end-to-end dry-run I did not run. **bilmiyorum.**
- **Q2** ADR port triage is educated guess; a single sweep of all 75 ADRs was not done in this cycle.
- **Q4** Candidate additions list is incomplete; full scope requires additional audit cycles.
- **Q5** Whether launcher's `b0d820d` self-test passed (no test file present, only script) is unverifiable from static analysis.
- **General:** No code was modified during audit. No commit to template or launcher. Findings are file-level only.

---

— @orchestrator, 2026-07-10T20:08+03:00, cycle ~742–~743
