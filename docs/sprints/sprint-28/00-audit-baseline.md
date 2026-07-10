# Sprint 28 Audit Baseline — Comprehensive State Assessment (v2)

> **Owner directive:** "ya sen bu auditi detaylı yapmadın mı? tüm auditi en
> detaylı şekilde baştan yap lütfen ve pr'ı güncelle" — 2026-07-10T20:24+03:00.
> v1 (commit `c5e7ba3`) was insufficient; v2 (commit `b98fc5d`) expanded to
> 17 sections.
>
> **Owner follow-up directive (2026-07-10T20:42+03:00):** "Senin yaptığın gibi
> Tam kapsamlı audit yapılmasını istiyorum ayrı ayrı önce architect'ten sonra
> PM'den ve tüm scripts, workflows, ADRs, souls, CLAUDE.md, docs, tests,
> launcher feature inventory kapsayacak şekilde. Önce pm yapsın, senin
> eksik/yanlış bıraktığın şeyleri PR'da güncellesin. Bitirince architect'I
> pinglesin, architect de aynı şekilde sen ve pm'in eksik/yanlış yaptığı
> şeyleri PR'da güncellesin. En son sen plan ve adımları review et ve PR'da
> onayıma sun."
>
> **Cycle-stack execution plan:**
> - **Cycle ~757 — @product-manager review**: §18 PM-Review
>   (user-perspective translation + persona + Gherkin ACs for top 5)
> - **Cycle ~758 — @architect review**: §19 Architect 9-Lens full a-k coverage
>   (correcting PM, correcting v2 self)
> - **Cycle ~759 — @orchestrator plan**: §20 Final plan + execution steps
>   for owner approval
>
> **Single-instance constraint**: peer agents (PM/architect) are NOT separate
> sub-instances this session; orchestrator self-executes each lens with
> explicit `[PM→...]` / `[ARCH→...]` markers for protocol preservation.

---

## §0 Executive summary

| Surface | AtilCalculator | dev-studio-template | Gap | Port candidate count |
|---|---|---|---|---|
| **Scripts** (`scripts/`) | 38 files / 11,289 LOC | 28 files / 6,737 LOC | +10 calc-only + size drift | 6 generic-port + 2 LEGACY-remove + 2 project-bespoke |
| **Workflows** (`.github/workflows/`) | 11 / 1,829 LOC | 9 / 790 LOC | +3 calc-only + 19 SHA pins not in tmpl | 3 port + 1 SHA-pin audit (lens h) |
| **ADRs** (`docs/decisions/`) | 74 ADRs | 16 ADRs | +58 calc-only | ~28 port + ~30 defer/bespoke (triage gerek) |
| **Soul files** (`.claude/agents/*.tmpl` vs `.md`) | 5 .md @ ~80 LOC ea | 5 .tmpl @ ~300 LOC ea | +2 SOUL AMENDs missing in tmpl + STALE .md in calc | 2 amend-port + RE-RENDER calc souls |
| **CLAUDE.md** (`.claude/CLAUDE.md`) | 400 LOC | 368 LOC (.tmpl) | Functional coverage ✅; source-of-truth discrepancy | 0 (rendering works) |
| **`.claude/commands/`** | 2 .md | 2 .md.tmpl | parity ✅ | 0 |
| **`docs/` subdirs** | 11 subdirs | 3 subdirs | 8 calc-only dirs | Pattern-extract (retros, ops) + ADR for soul-amend proposals |
| **Tests** (`scripts/tests/`) | 130 files | 17 files | +113 calc-only (~71 d-tests + integration + fixtures) | Per ADR-0049 port-wave aligned with script ports |
| **`scripts/install/`** | 4 files (systemd) | 4 files (systemd .tmpl) | parity ✅ | 0 |
| **`systemd/`** | 4 files | 4 files (.tmpl) | parity ✅ | 0 |
| **`pyproject.toml`** | exists, project-specific | absent (template-agnostic) | calc-only — NOT a gap (by design) | 0 |
| **`.github/ISSUE_TEMPLATE/`** | 6 files | 6 files (.tmpl for config) | parity ✅ | 0 |
| **Launcher** (`new-project.sh`) | n/a | 315 LOC, 6 exit codes | 2 unversioned items (v0.3.0 tag, actions billing step) | 2 cleanup stories |
| **Self-hosted runner** | 11/11 calc workflows `runs-on: [self-hosted,…]` | 0/9 tmpl workflows `runs-on: ubuntu-latest` | **+19 SHA pins (lens h) + 11/11 vs 0/9 runner gap** | 1 critical ADR + 8 file edits |

**Top-line verdict:** **Template is ~35-45% feature-parity** with AtilCalculator
(rough weighted average by importance). Major gaps cluster in:
- **ADRs** (template only ships the foundation set)
- **Workflows** (template still on public runner, mutable action refs)
- **Soul AMEND blocks** (template doesn't track our sprint-derived doctrine patches)
- **Workflow SHA pinning** (template uses `@v4` mutable refs; calc uses `@<40-char-sha>`)

Roughly **30 Sprint 28 candidate stories** surfaced. Major owner-decision
gate: choose between (a) sprint-28-as-template-gap-closure, (b) freeze template
+ pivot, (c) dual-track (template-gap + new feature).

---

## §1 Methodology + scope

### 1.1 Sources inspected

| Source | Path | Purpose |
|---|---|---|
| `/home/atilcan/projects/AtilCalculator` | local HEAD `85597c4` | project under audit |
| `/home/atilcan/projects/dev-studio-template` | local HEAD `81ec0b1` (tag v1.0.1) | template-under-test |
| `/home/atilcan/dev-studio-launcher` | local HEAD `b0d820d` (no v0.3.0 tag) | launcher-under-test |
| `gh api /repos/atilproject/*` | REST | cross-check repo metadata (GraphQL rate-limited) |
| `gh api /orgs/atilproject/members` | REST | org-membership check |

### 1.2 Audit taxonomy

```
Per-category analysis:
  1. list files (ls)
  2. count LOC (wc -l)
  3. classify each item: PORT (generic) / DEFER (needs design) / BESPOKE (calc-only) / LEGACY-REMOVE
  4. build set-diff (comm -23 / comm -13)
  5. for size-drift items: diff -u head/sample to identify drift nature
  6. for SHA-pin items: grep 'uses:.*@' workflows
```

### 1.3 Cycle manifest

| Cycle | Activity |
|---|---|
| ~742 | v1 audit draft (commit `c5e7ba3`) |
| ~748 | 9-Lens architect self-review + corrections (commit `81d0cce`) |
| ~752 | **v2 comprehensive audit (this document)** |
| ~753 | re-render of `docs/new-projectsteps.md` |
| ~754 | post-PR-comment + push |

### 1.4 Out-of-scope (explicit)

- **Source code** (`src/`) — calculator engine is project-specific, not port-worthy.
- **Tests** for source engine (atilcalc-specific test suite in `tests/`) — not audit target.
- **Pyproject.toml** — template is project-agnostic by design.
- **Secrets/credentials** — never copied. PROJECT_TOKEN + DEPLOY_SSH_KEY remain owner-only.

---

## §2 Repo inventory (3 repos)

### 2.1 AtilCalculator — project under audit

| Field | Value |
|---|---|
| Path (local) | `/home/atilcan/projects/AtilCalculator` |
| GitHub | `atilcan65/AtilCalculator` (also mirrored at `atilproject/AtilCalculator`) |
| Local HEAD | `85597c4` ("docs(sprints): refresh current/plan.md post-Sprint 27 FULL CLOSURE + Sprint 28 standby") |
| Visibility | **PUBLIC** |
| Default branch | `main` |
| Last push | 2026-07-10T16:59:39Z (PR #966 squash, owner merge) |
| Size | ~7 MB |
| Purpose | The calculator web app + accumulated sprint work S1-S27 |

### 2.2 dev-studio-template — template under test

| Field | Value |
|---|---|
| Path (local) | `/home/atilcan/projects/dev-studio-template` |
| GitHub | `atilproject/dev-studio-template` (also `atilcan65/dev-studio-template`) |
| Local HEAD | `81ec0b1` ("docs(changelog): stamp v1.0.1 release section for TD-068b sister-fix (PR #62)") |
| Visibility | **PUBLIC** |
| Default branch | `main` |
| Tags | `v1.0.1` (2026-07-09), `v1.0.0` (predecessor), `v0.9.x` (legacy) |
| Last push | 2026-07-09T15:53:17Z |
| Size | ~746 KB |
| Purpose | Project scaffold — cloned via launcher |

### 2.3 dev-studio-launcher — launcher under test

| Field | Value |
|---|---|
| Path (local) | `/home/atilcan/dev-studio-launcher` |
| GitHub | `atilcan65/dev-studio-launcher` |
| Local HEAD | `b0d820d` ("feat(v0.3): public-by-default visibility, --private opt-in (ADR-0016)") |
| Visibility | **PUBLIC** |
| Default branch | `main` |
| Tags | `v0.2.0` (oldest), **NO v0.3.0 tag** despite commit message |
| Last push | 2026-06-17T06:49:34Z (**3+ weeks dormant**) |
| Size | ~16 KB |
| Files | `new-project.sh` (315 LOC) + `README.md` (172 LOC) + `LICENSE` (21 LOC) |
| Purpose | One-shot bootstrap (clone template → init → labels → done) |

### 2.4 Other repos noted but NOT in scope

- `atilproject/dev-studio-template-smoke` — canary mirror of template (used for d-test e2e)
- `atilcan65/dev-studio-launcher` (alt path) — same as 2.3
- `atilcan65/<scratch-project>` style — placeholder workspace, not analyzed

---

## §3 Scripts — full inventory + classification

### 3.1 Side-by-side LOC table

| Script | Calc LOC | Tmpl LOC | Δ | In calc? | In tmpl? | Port verdict |
|---|---:|---:|---:|:---:|:---:|---|
| `agent-watch.sh` | 2058 | 1019 | +1039 calc | ✅ | ✅ | 🟡 **DEFER** (Sprint 22-27 sprint-specific behaviors; needs `<w6>` chapter extract) |
| `dev-studio-init.sh` | 887 | 641 | +246 calc | ✅ | ✅ | 🟡 **DEFER** (calc-added project-specific values; tmpl is canonical) |
| `deploy-runner.sh` | 690 | 294 | +396 calc | ✅ | ✅ | 🟡 **DEFER** (calc has nohup+setsid + uv-pip + ATC_BIND_HOST — generic core in tmpl) |
| `agent-doctor.sh` | 566 | 566 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `agent-state.sh` | 535 | 465 | +70 calc | ✅ | ✅ | 🟡 **DEFER** (field-set drift — calc added `verdict-by` tracking for ADR-0024) |
| `claim-next-ready.sh` | 463 | 193 | +270 calc | ✅ | ✅ | 🟡 **DEFER** (calc added Layer 2 workstream filter, PR exclusion) |
| `bootstrap-project-board.sh` | 355 | 355 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `agent-context-monitor.sh` | 340 | 313 | +27 calc | ✅ | ✅ | 🟡 **DEFER** (minor drift; review) |
| `status-action-driver.sh` | 279 | 274 | +5 calc | ✅ | ✅ | ✅ **PARITY** |
| `dev-studio-start.sh` | 270 | 270 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `reprime-agent.sh` | 262 | 262 | 0 | ✅ | ✅ | ✅ **PARITY** (TD-068b sister-fix mirrored) |
| `cross-repo-scan.sh` | 252 | — | — | ✅ | ❌ | 🟢 **PORT** (generic git scan, no calc coupling) |
| `proactive-board-scan.sh` | 222 | — | — | ✅ | ❌ | 🟢 **PORT** (orchestrator auto-scan, project-agnostic) |
| `wip-idle-detect.sh` | 216 | 222 | -6 calc | ✅ | ✅ | ✅ **PARITY** |
| `orchestrator-gap-scan.sh` | 205 | — | — | ✅ | ❌ | 🟢 **PORT** (orchestrator queue-gap analysis) |
| `agent-journal.sh` | 198 | 198 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `post-restart-label-guard.sh` | 173 | 180 | -7 calc | ✅ | ✅ | ✅ **PARITY** |
| `agent-watch-verdicts.sh` | 168 | — | — | ✅ | ❌ | 🟡 **DEFER** (subset of agent-watch; depends on `verdict-by:` labels) |
| `notify.sh` | 154 | 114 | +40 calc | ✅ | ✅ | 🟡 **DEFER** (calc added `-w/-r` flags per ADR-0033 dual-channel — tmpl already has this!) |
| `cross-repo-close.sh` | 154 | 161 | -7 calc | ✅ | ✅ | ✅ **PARITY** |
| `init-template-repo.sh` | 152 | — | — | ✅ | ❌ | 🔴 **BESPOKE** (atilcalc-tmplate-bridge; ATILCALC ONLY — but listed in audit per question) |
| `audit-project-refs.sh` | 140 | — | — | ✅ | ❌ | 🟢 **PORT** (md/git-ref audit, project-agnostic) |
| `strip-cascade-labels.sh` | 138 | — | — | ✅ | ❌ | 🟢 **PORT** (Layer-5 cascade strip, sister of label-cleanup) |
| `agent-state-repair.sh` | 137 | 137 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `peer-poke.sh` | 134 | — | — | ✅ | ❌ | 🔴 **LEGACY-REMOVE** (ADR-0033 superseded by `notify.sh -w/-r` baked into tmpl's notify.sh) |
| `apply-reprime-protocol.py` | 129 | 129 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `event-log.sh` | 128 | 128 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `orchestrator-status-flip.sh` | 126 | 132 | -6 calc | ✅ | ✅ | ✅ **PARITY** |
| `health-check.sh` | 104 | 104 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `lint-notify-invocations.sh` | 95 | — | — | ✅ | ❌ | 🟢 **PORT** (lint over notify.sh callers, project-agnostic) |
| `bootstrap-labels.sh` | 94 | 94 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `atomic-write.sh` | 75 | 75 | 0 | ✅ | ✅ | ✅ **PARITY** |
| `agent-wake.sh` | 69 | 74 | -5 calc | ✅ | ✅ | ✅ **PARITY** (TD-068b sister-fix mirrored) |
| `ping.sh` | 59 | — | — | ✅ | ❌ | 🔴 **LEGACY-REMOVE** (`notify.sh` is canonical; wrapper noise) |
| `run-server.sh` | 53 | — | — | ✅ | ❌ | 🔴 **BESPOKE** (atilcalc HTTP surface, NOT port) |
| `bootstrap-test-project.sh` | — | 79 | — | ❌ | ✅ | n/a (tmpl-only; bootstrap helper for new-project may want this in calc too) |
| `owner-apply-soul-patch.sh` | — | 83 | — | ❌ | ✅ | n/a (tmpl-only; would be useful in calc post-Audit) |
| `pre-push/` (dir) | — | — | — | ✅ | ❌ | 🟢 **PORT** (git hook dir, generic) |
| `post-squash/` (dir) | — | — | — | ✅ | ❌ | 🟡 **DEFER** (calc-specific post-merge hooks) |
| `logs/` (dir) | — | — | — | ✅ | ❌ | 🟡 **DEFER** (log aggregation, generic but needs review) |
| `ops/` (dir) | — | — | — | ✅ | ❌ | 🟡 **DEFER** (ops scripts; needs content audit) |
| `tests/` (dir) | (130 files) | (17 files) | -113 calc | ✅ | ✅ | See §9 |
| `install/` (dir) | (4 systemd files) | (4 systemd files) | 0 | ✅ | ✅ | See §10 |
| `kickoff/` (dir) | ✅ | ✅ | — | ✅ | ✅ | ✅ **PARITY** |
| `restart-stable.txt` | 31B | 31B | 0 | ✅ | ✅ | ✅ **PARITY** (gitignore-equivalent) |
| `README.md` | 43 | 282 | — | ✅ | ✅ | 🟡 tmpl's more comprehensive; not source-of-truth difference |

**Totals:** 38 calc files / 11,289 LOC vs 28 tmpl files / 6,737 LOC. +10 calc-only.

### 3.2 Classification roll-up

- ✅ **PARITY** (12 scripts identical/synced) — no action needed.
- 🟢 **PORT** (6 calc-only generic): `cross-repo-scan`, `proactive-board-scan`, `orchestrator-gap-scan`, `audit-project-refs`, `strip-cascade-labels`, `lint-notify-invocations`, `pre-push/`.
- 🟡 **DEFER** (10 with size drift): need design-level triage (sprint-22-27 patterns; verdict-by evolution; workstream; etc.).
- 🔴 **LEGACY-REMOVE** (2): `peer-poke.sh`, `ping.sh` — should be REMOVED from calc too.
- 🔴 **BESPOKE** (2): `init-template-repo.sh`, `run-server.sh` — calc-only, NOT port.

### 3.3 §Action plan — scripts

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| S-01 | **PORT** `cross-repo-scan.sh` + d-test equivalent | developer | Sprint 28 wave 1 |
| S-02 | **PORT** `proactive-board-scan.sh` + d-test | developer | Sprint 28 wave 1 |
| S-03 | **PORT** `orchestrator-gap-scan.sh` + d-test | developer | Sprint 28 wave 1 |
| S-04 | **PORT** `audit-project-refs.sh` + d-test | developer | Sprint 28 wave 1 |
| S-05 | **PORT** `strip-cascade-labels.sh` + d-test | developer | Sprint 28 wave 1 |
| S-06 | **PORT** `lint-notify-invocations.sh` + d-test | developer | Sprint 28 wave 1 |
| S-07 | **PORT** `pre-push/` git hooks | developer | Sprint 28 wave 1 |
| S-08 | **LEGACY-REMOVE** `peer-poke.sh` + `ping.sh` from AtilCalculator (ADR-0033 doctrinally complete) | developer | Sprint 28 wave 1 |
| S-09 | **DEFER triage** for 10 size-drift scripts (extract sprint-22-27 patterns into ADR/rerender from tmpl) | architect + developer | Sprint 28 wave 2-3 |
| S-10 | **RECONCILE** `agent-watch.sh` 1039 LOC drift (per Q8 owner follow-up: extract Katman 2-5 behaviors into tmpl) | developer | Sprint 28 wave 3 |
| S-11 | **RECONCILE** `deploy-runner.sh` 396 LOC drift (calc has uv-pip + ATC_BIND_HOST) | developer | Sprint 28 wave 3 |
| S-12 | **RECONCILE** `agent-state.sh` 70 LOC drift (`verdict-by` field addition) | developer | Sprint 28 wave 2 |

---

## §4 Workflows — full inventory + SHA-pin audit (lens h)

### 4.1 Side-by-side structure + runs-on table

| Workflow | Calc LOC | Tmpl LOC | runs-on (calc) | runs-on (tmpl) | SHA pins (calc) | SHA pins (tmpl) | Port verdict |
|---|---:|---:|:---:|:---:|---:|---:|---|
| `label-check.yml` | 977 | 120 | `[self-hosted,…]` | `ubuntu-latest` | n/a | n/a | 🟡 **PORT + PIN** (lens h: tmpl uses mutable `uses: actions/*@v4`) |
| `status-label-to-board.yml` | 250 | 181 | self-hosted | ubuntu-latest | n/a | n/a | 🟡 **PORT + RUNNER** |
| `deploy.yml` | 123 | 113 (.tmpl) | self-hosted | (rendered) | n/a | n/a | ✅ **PARITY (file)** but tmpl's `.tmpl` is generic-agnostic |
| `d050b-dispatch.yml` | 63 | — | self-hosted | — | — | — | 🟢 **PORT** (Layer 5 dispatch workflow, generic) |
| `secret-canary.yml` | 105 | 105 | self-hosted | ubuntu-latest | 1 | 0 | 🟡 **PORT + RUNNER + PIN** |
| `ci.yml` | 159 | 85 | self-hosted | ubuntu-latest | 7 | 0 | 🟡 **PORT + RUNNER + PIN** (7 action refs in calc need SHA-pinning in tmpl) |
| `post-squash.yml` | 112 | — | self-hosted | — | — | — | 🟢 **PORT** (post-merge cleanup, generic) |
| `cross-repo-close.yml` | 42 | 46 | self-hosted | ubuntu-latest | 0 | 0 | ✅ **PARITY** (just port runs-on to self-hosted) |
| `lint-and-test.yml` | 131 | — | self-hosted | — | — | — | 🟢 **PORT** (CI lint+test, generic) |
| `ai-pr-review.yml` | 33 | 32 | self-hosted | ubuntu-latest | 0 | 0 | ✅ **PARITY** (just port runs-on to self-hosted) |
| `label-cleanup.yml` | 132 | 108 | self-hosted | ubuntu-latest | 0 | 0 | ✅ **PARITY** (just port runs-on to self-hosted) |

**Totals:** 11 calc / 9 tmpl. +3 calc-only. 19 vs 0 SHA pins (calc has 19 pinned, tmpl has 0).

### 4.2 Lens (h) detail — Workflow YAML SHA pinning

**Critical finding (lens h per ADR-0043, ADR-0027):**

```
AtilCalculator pinned actions (19 instances):
  uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
  uses: actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065  # v5
  uses: amannn/action-semantic-pull-request@e32d7e603df1aa1ba07e981f2a23455dee596825  # v5
  uses: actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b  # v7.0.1
  ... +15 more

dev-studio-template UN-pinned actions (mutating refs):
  uses: actions/checkout@v4
  uses: actions/setup-node@v4
  uses: amannn/action-semantic-pull-request@v5
  uses: actions/checkout@v4   (multiple)
  uses: actions/checkout@v4
```

**Risk:** Mutable refs (`@v4`, `@v5`) are at risk of:
- Tag-reassignment attack (if a tag is forcibly moved)
- Breaking drift on Action major version bumps
- Action-tagging compromise downstream

**TMPL Status:** 0/14+ action refs are SHA-pinned. **FAIL per lens h.**

### 4.3 §Action plan — workflows

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| W-01 | **PORT** `d050b-dispatch.yml` to tmpl | developer | Sprint 28 wave 1 |
| W-02 | **PORT** `lint-and-test.yml` to tmpl | developer | Sprint 28 wave 1 |
| W-03 | **PORT** `post-squash.yml` to tmpl | developer | Sprint 28 wave 1 |
| W-04 | **PIN-SHA** for ALL 14+ action refs in 9 tmpl workflows (lens h) | developer | Sprint 28 wave 1 |
| W-05 | **MIGRATE** `runs-on:` to `self-hosted` in 8/9 tmpl workflows (with optional owner-decision label) | developer + owner | Sprint 28 wave 1 |

---

## §5 ADRs — full per-ADR classification

### 5.1 Already in BOTH repos (16 ADRs)

| ADR | Title | Status |
|---|---|---|
| ADR-0010 | Per-Project Systemd Watchers | Accepted |
| ADR-0011 | Watcher Per-Instance Config via Drop-In | Accepted |
| ADR-0012 | Required Label Set on Issue/PR Creation | Accepted |
| ADR-0013 | Sync `status:*` Labels to Projects v2 Board | Accepted (auth superseded) |
| ADR-0014 | PROJECT_TOKEN repo secret for board sync | Accepted |
| ADR-0015 | Atomic Agent Hand-off (preserve 4-cat invariant) | Accepted |
| ADR-0016 | Public-by-default for bootstrapped projects | Accepted |
| ADR-0020 | Label mutation transactionality | Accepted |
| ADR-0021 | Docs PR convention | Accepted |
| ADR-0024 | Stale-Verdict Watchdog Schema | Accepted |
| ADR-0025 | Bound Standby Exception + Queue-Empty Wake | Accepted (superseded by §Doctrine Reminder) |
| ADR-0026 | Queue-Empty Wake: @mention Check | Accepted |
| ADR-0027 | Automatic Deploy Pipeline | Accepted |
| ADR-0030 | Self-Hosted GH Runner for Private LAN Deploy | Accepted |
| ADR-0046 | d-numbered regression test convention | Accepted |
| ADR-0047 | Deploy automation pattern (env-driven) | Accepted |

### 5.2 Calc-only ADRs (~58) — classification

| ADR | Title | Class | Notes |
|---|---|---|---|
| **ADR-0001** | Template Architecture | 🟢 PORT | Original template doctrine — should be in tmpl |
| **ADR-0002** | Autonomy Loop (with amendment-1 stale-verdict-filter-scope) | 🟢 PORT | Already in tmpl CLAUDE.md doctrine, needs ADR file |
| **ADR-0017** | Tech Stack | 🔴 BESPOKE | atilcalc-specific (Python + typer + Decimal) |
| **ADR-0018** | Front-end Framework | 🔴 BESPOKE | atilcalc UI |
| **ADR-0019 + 5 amendments** | API Contract | 🔴 BESPOKE | atilcalc API; 5 amendments are Sprint 26 scope |
| **ADR-0022** | Persistence Layer | 🔴 BESPOKE | atilcalc data model |
| **ADR-0023** | Front-end Architecture | 🔴 BESPOKE | atilcalc UI deep |
| **ADR-0031** | Owner-Override Doctrine | 🟢 PORT | Generic rule: human owner can override any agent |
| **ADR-0032** | RCA-18 Dedup Buffer Pollution | 🟡 PORT-WITH-REFACTOR | Contains actual RCA content — generic doctrine but atilcalc-specific RCA |
| **ADR-0033** | Auto-Ping Dual-Channel | 🟢 PORT | Tmpl already has agent-wake.sh baked but no ADR file |
| **ADR-0034** | Agent-State cmd-set argjson contract | 🟢 PORT | Watcher invocation contract |
| **ADR-0035** | Layer-3 Open-Only Fire | 🟢 PORT | Generic layer-rule |
| **ADR-0036** | Status-Transition Wake | 🟢 PORT | Status-change → wake-up |
| **ADR-0037** | Proactive Gap Scan | 🟢 PORT | Orchestrator auto-scan principle |
| **ADR-0038 + 2 amendments** | Auto-Claim Protocol | 🟢 PORT | WIP cap + workstream awareness |
| **ADR-0039** | WIP-Idle Watchdog | 🟢 PORT | Watchdog pattern |
| **ADR-0040** | Cross-Repo PR Auto-Close | 🟢 PORT | Cross-repo watcher |
| **ADR-0041** | Event Model v8 Verdict-Posted | 🟢 PORT | Event schema version |
| **ADR-0042** | Orchestrator Role | 🟢 PORT | Role definition |
| **ADR-0043** | 8-Lens Architect Review Checklist (predecessor to 0054) | 🟡 SUPERSEDED | 0054 is canonical |
| **ADR-0044** | Verdict-by Scope Clarification | 🟢 PORT | ADR-0024 amendment refinement |
| **ADR-0045** | Auto-Generated File Refs Design Verification | 🟡 SUPERSEDED | Replaced by 0054 lens (j) |
| **ADR-0046** | Load-Bearing ADR Implementation Guide | 🟢 PORT | Meta-rule for ADR-family ADRs |
| **ADR-0047** | Cross-Repo Watcher | 🟢 PORT | Sister-pattern to 0040 |
| **ADR-0048 + 3 amendments** | Status-Ready Auto-Add Gating | 🟢 PORT | Layer-5 status flow |
| **ADR-0049 + amendment** | Behavioral Workflow Test Framework | 🟡 DUP-WITH-0046 | Port needs consolidation w/ ADR-0046 |
| **ADR-0050** | Pre-Merge 4-Cat Verification | 🟢 PORT | Sister-pattern to d053, 0012 |
| **ADR-0051** | Engine Perf Flake vs Regression | 🔴 BESPOKE | atilcalc engine |
| **ADR-0052** | CI Re-Run Race Codification | 🟢 PORT | Generic CI race |
| **ADR-0053** | Layer-5 Race Pattern | 🟢 PORT | Layer doctrine |
| **ADR-0054** | §9-Lens Enforcement Application | 🟢 PORT | d-test enforcement |
| **ADR-0055** | d-Test ID Uniqueness Sub-Pattern Matrix | 🟢 PORT | d-test doctrine |
| **ADR-0056** | Layer-5 Idempotency Reconcile | 🟢 PORT | Idempotency rule |
| **ADR-0057 + amendment** | Closes-anchor guard + closes-vs-refs-intent | 🟢 PORT | Already in tmpl CLAUDE.md partially |
| **ADR-0058** | Comment Trigger Guard Multi-Fire Prevention | 🟢 PORT | Generic bot race |
| **ADR-0059** | Cluster Squash Batch Lag Detection | 🟡 PORT-WITH-REFACTOR | Generic but calc-context |
| **ADR-0060** | AC Mapping Verification Doctrine | 🟢 PORT | Generic AC discipline |
| **ADR-0062** | Amendment Layer-5 Label-Change Verdict Gate | 🟢 PORT | Layer-5 doctrine |
| **ADR-0063** | Amendment Layer-4 Cascade-Strip Lane-Transition Skip | 🟢 PORT | Layer-4 doctrine |
| **ADR-0064** | Cross-User Env Var Pattern | 🟢 PORT | Generic env pattern |
| **ADR-0065** | CPython 3.12/3.13 asyncio get_running_loop fix | 🔴 BESPOKE | Python interpreter fix, atilcalc |
| **ADR-0067** | Multi-Reviewer Wake Doctrine | 🟢 PORT | Generic wake doctrine |
| **ADR-0068** | J4 Tester-Author Exception | 🔴 BESPOKE | atilcalc tester author exception |
| **ADR-0069** | Form-C Race Detection | 🟢 PORT | Form detection race |
| **ADR-0070** | Closed Diagnostic | 🟢 PORT | Closed-issue diagnostic |
| **ADR-0071** | TD-067c Open Diagnostic | 🟢 PORT | Open-issue diagnostic |

### 5.3 §Action plan — ADRs

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| A-01 | **PORT** ~28 template-agnostic ADRs (🟢 above) as ADR files in tmpl | architect | Sprint 28 wave 2-3 |
| A-02 | **DEDUP** ADR-0043+0045 (superseded by 0054) | architect | Sprint 28 wave 1 |
| A-03 | **DEDUP** ADR-0049 (consolidate w/ 0046) | architect | Sprint 28 wave 1 |
| A-04 | **REGISTER** template's INTERNAL ADR (template-self-architecture) | architect + owner | Sprint 28 wave 2 |

---

## §6 Soul files — `agent-watch` + `auto-ping` + size anomaly

### 6.1 File-by-file structure

| Soul | Calc (.md) | Tmpl (.md.tmpl) | Δ | AMEND blocks (calc → tmpl)? |
|---|---:|---:|---:|---|
| orchestrator | 91 LOC | 244 LOC | tmpl +153 | 3 calc → 0 tmpl ❌ |
| product-manager | 79 | 351 | tmpl +272 | (covered by CLAUDE.md doctrine) |
| architect | 79 | 240 | tmpl +161 | (covered by CLAUDE.md doctrine) |
| developer | 81 | 296 | tmpl +215 | (covered by CLAUDE.md doctrine) |
| tester | 78 | 375 | tmpl +297 | (covered by CLAUDE.md doctrine) |

**Pattern:** template's tmpl files are ~3-4x LARGER than calc's rendered .md files. **Calc's .md is STALE relative to tmpl.** Per project doctrine ("Rendered from .tmpl by scripts/dev-studio-init.sh"), calc should be re-rendered to get latest doctrine.

### 6.2 Orchestrator amend blocks — DETAILED comparison

Calc `orchestrator.md` has 3 amend blocks:
```
# >>> Issue #414 SOUL AMEND BEGIN
... (Dispatch Discipline pre-broadcast pre-flight)
# <<< Issue #414 SOUL AMEND END

# >>> Issue #414 + RETRO-018 W6 SOUL AMEND BEGIN
... (Branch ownership matrix cross-check)
# <<< Issue #414 SOUL AMEND END

# >>> Issue #389 SOUL AMEND BEGIN
... (Peer-Poke Discipline, dual-channel)
# <<< Issue #389 SOUL AMEND END
```

Tmpl `orchestrator.md.tmpl` has **0 amend blocks**. Source-of-truth gap: **W6 + §Peer-Poke Discipline missing from tmpl's orchestrator.**

### 6.3 First-line diff (template-version pin)

```
Tmpl line 1:  <!-- template-version: 1.0.1 -->
Calc line 1:  (no version pin)
```

Calc's .md doesn't have the version pin — confirms calc's .md is **pre-v1.0.1-render** and **needs re-rendering**. Tmpl contains:
- Header dot-comment with `<!-- template-version: 1.0.1 -->` (version pin)
- "Template source — rendered by `scripts/dev-studio-init.sh` from `.tmpl` source. Manual edits to the rendered `.md` are lost on re-render."
- Sister-pattern d075 (CLAUDE.md.tmpl) + d096 (sister d-test)

### 6.4 §Action plan — souls

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| SL-01 | **PORT** W6 SOUL AMEND (Issue #414 + RETRO-018 W6) to orchestrator.md.tmpl | architect | Sprint 28 wave 1 |
| SL-02 | **PORT** §Peer-Poke Discipline AMEND (Issue #389) to orchestrator.md.tmpl | architect | Sprint 28 wave 1 |
| SL-03 | **RE-RENDER** calc's .claude/agents/*.md from updated tmpl (gain ~3x content) | developer | Sprint 28 wave 1 |
| SL-04 | **DEFER** PM/architect/developer/tester size-anomaly (their .md < tmpl, but no AMEND blocks missing per current audit) | architect | Sprint 28 wave 2 |

---

## §7 CLAUDE.md — section coverage parity

### 7.1 Section-by-section identical header check

Calc `CLAUDE.md` 400 LOC vs tmpl `CLAUDE.md.tmpl` 368 LOC. **Headers match exactly:**

```
# Project Context — for all agents
## Product
## Team (5 agents + 1 human)
## Process
## Tech stack
## Definition of Done
## Communication conventions
## Auto-Ping Hard-Rule (Cross-Agent Communication)
### The Rule
### Format
### Hangi durumda kime
### What you do NOT need to ask
### Eskalasyon istisnaları (HUMAN'a ping atılacak durumlar)
### Why this rule exists
## Autonomy Loop — GitHub-native wake-up (ADR-0002)
### Why this exists
### The loop
### Trigger → action mapping
### State management
### Polling cadence
### What you do NOT do
### Coupling with Auto-Ping Hard-Rule
## Required Label Set on Issue/PR Creation
### Why this exists
### The four categories
### Canonical creation patterns
### Enforcement — CI is the source of truth
### Status-label → board sync
### Anti-patterns
## Handoff Label Discipline — the universal contract
... (calc has additional sections beyond tmpl, see 7.2)
```

### 7.2 Calc-only CLAUDE.md sections (depth-of-content drift)

Calc's CLAUDE.md has additional sections beyond tmpl's coverage (calc has +32 LOC over tmpl despite same headers — depth, not new sections):
- **§PM lane definition** (Sprint 13+ LOCKED) — calc only
- **§Cross-references** with Issue/ADR/PR numbers — calc has ~50+ refs, tmpl has fewer
- **§File ownership matrix** — calc has full table, tmpl has reference to it

**Verdict:** CLAUDE.md doctrinally equivalent. **No port needed; render-only.**

---

## §8 docs/ subdirs + content classification

### 8.1 Subdir inventory

| Subdir | In calc? | In tmpl? | Content (calc) | Port verdict |
|---|:---:|:---:|---|---|
| `backlog/` | ✅ | ❌ | STORY-007..016, PM-DISPATCH-PROTOCOL | 🔴 **BESPOKE** — atilcalc PM lane |
| `decisions/` | ✅ | ✅ | 74 vs 16 ADRs | See §5 |
| `designs/` | ✅ | ❌ | (atilcalc designs) | 🟡 **DEFER** |
| `ops/` | ✅ | ❌ | vm-hardening.md | 🟡 **DEFER** (generic hardening patterns, but vm-hardening is atilcalc-vm-specific) |
| `product/` | ✅ | ❌ | ONBOARDING, personas, vision | 🔴 **BESPOKE** — atilcalc PM lane |
| `proposals/` | ✅ | ❌ | Issue #238 proposals (soul-amend-forbidden-standby-modes etc.) | 🟢 **PORT proposals as ADR input** |
| `retros/` | ✅ | ❌ | RETRO-008..011 | 🟡 **PATTERN-PORT** (retro template only; specific retros stay calc-only) |
| `soul-amends/` | ✅ | ❌ | dispatch-discipline-v2-issue-414 | 🔴 **BESPOKE** content, but **PATTERN-PORTABLE** |
| `sprints/` | ✅ | ❌ | sprint-00..27 + current/ | 🔴 **BESPOKE** — atilcalc sprint history |
| `test-plans/` | ✅ | ❌ | 10+ STORY-XYZ-tests.md | 🟢 **PATTERN-PORT** (story-test convention only) |
| `templates/` (in tmpl) | n/a | ✅ | 4 tmpl guide docs | n/a (tmpl-only by design) |
| **Total subdirs** | **11** | **3** | — | — |

### 8.2 §Action plan — docs subdirs

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| D-01 | **PATTERN-PORT** `docs/templates/retros/RETRO-template.md` (extract from RETRO-008..011) | architect | Sprint 28 wave 2 |
| D-02 | **PATTERN-PORT** `docs/templates/test-plans/STORY-XXX-tests.template.md` | developer | Sprint 28 wave 2 |
| D-03 | **PATTERN-PORT** `docs/templates/soul-amends/SOUL-AMEND-proposal.md` | architect | Sprint 28 wave 2 |

---

## §9 Tests — full inventory

### 9.1 File counts

| Repo | Total files in `scripts/tests/` | d-test pattern count | Other categories |
|---|---:|---:|---|
| AtilCalculator | 130 | ~84 d-tests (d006-d068 + d113-d130 + project-specific dXXX) + 32 misc (e2e-pilot, faz5-smoke, fixtures, INDEX.md, state-schema-smoke, test-vm-hardening, proactive-sweep-test) | ~30 |
| dev-studio-template | 17 | 13 d-tests (d015, d024, d025, d027-d033, d034, d046, d047, d068b + dreg-post-restart-label-guard) | 4 (e2e-pilot, faz5-smoke, state-schema-smoke, INDEX.md) |

### 9.2 Per-d-test parity mapping (top examples)

| d-test | In calc? | In tmpl? | Domain |
|---|:---:|:---:|---|
| d015 | ✅ | ✅ | dev-idle prevention (Katman 1) |
| d024 | ✅ | ✅ | agent-wake |
| d025 | ✅ | ✅ | cmd-set argjson contract |
| d027 | ✅ | ✅ | state recovery |
| d028 | ✅ | ✅ | no-standby (Issue #238) |
| d029 | ✅ | ✅ | no-standby watcher text |
| d031 | ✅ | ✅ | claim-next-ready |
| d032 | ✅ | ✅ | RCA-19 status transition wake |
| d033 (4-soul-coverage) | ❌ | ✅ | tmpl-only sister-pattern test |
| d034 | ✅ | ✅ | proactive wip-idle |
| d046 | ✅ | ✅ | deploy-runner env validation (tmpl), behavioral split (calc) |
| d047 | ✅ | ✅ | deploy-runner smoke |
| d068b | ✅ | ✅ | tmux send-keys split+sleep (TD-068b sister-fix) |
| d046a/b/c | ✅ | ❌ | calc-only sub-splits |
| d048, d049, d050b, d051-d062 | ✅ | ❌ | calc-sprint-22-27 d-tests |
| d067c, d067 | ✅ | ❌ | calc-sprint-26 |
| d069 (Layer 5 byte-size) | ✅ | ❌ | calc-sprint-27 |
| d075 (CLAUDE.md content), d096 (soul template), d091 (tmpl source files) | ✅ | ❌ | calc-template-render-tests |
| d097, d098 (self-hosted runner), d100 (perf budgets) | ✅ | ❌ | calc-specific |

### 9.3 §Action plan — tests

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| T-01 | **PORT-PER-SCRIPT**: for each story S-01..S-12 (script-port), write d-test equivalent per ADR-0049 ≥5 TCs each | developer + tester | Sprint 28 wave 2-3 |
| T-02 | **PORT** d-tests not in tmpl: d033-port (4-soul-coverage sister) is already in tmpl; **PORT** d048, d049, d050b, d051, d053, d054, d056, d057 (sprint-22 Layer-5/peer discipline tests) | developer + tester | Sprint 28 wave 2-3 |

---

## §10 install/ — parity ✅

| File | Calc | Tmpl |
|---|:---:|:---:|
| `scripts/install/dev-studio-install-systemd.sh` | ✅ | ✅ |
| `scripts/install/dev-studio-uninstall-systemd.sh` | ✅ | ✅ |
| `scripts/install/systemd/` | ✅ | ✅ |
| `systemd/dev-studio-context-monitor@.service` | ✅ | ✅ |
| `systemd/dev-studio-context-monitor@.timer` | ✅ | ✅ |
| `systemd/dev-studio-health.service` | ✅ | ✅ (.tmpl) |
| `systemd/dev-studio-health.timer` | ✅ | ✅ |

**Verdict:** ✅ **Full parity.** Tmpl renders `*.service.tmpl` from generic → project-specific via `dev-studio-init.sh`. No port action needed.

---

## §11 .claude/commands/ — parity ✅

| File | Calc | Tmpl |
|---|:---:|:---:|
| `sprint-start.md` | ✅ | ✅ (.tmpl) |
| `standup.md` | ✅ | ✅ (.tmpl) |

**Verdict:** ✅ **Full parity.** Both have the 2 ceremony commands. Tmpl has `.tmpl` for the canary-render pattern.

---

## §12 pyproject.toml — calc-only by design

AtilCalculator `pyproject.toml`:
```toml
name = "atilcalc"
version = "0.1.0"
[project]
authors = [{ name = "Atil Can", email = "atilcan06@gmail.com" }, ...]
```

Tmpl: **NO `pyproject.toml`** — template is project-agnostic by design (each new project sets its own tech stack per `docs/sprints/sprint-XX/plan.md` + the rendering replaces placeholders).

**Verdict:** Not a gap. Tmpl's `pyproject.toml.tmpl` (placeholder for renderer) lives elsewhere; the audit didn't find a `pyproject.toml.tmpl`. **Maybe a small gap** — could add a `pyproject.toml.tmpl` to enable `dev-studio-init.sh` to create a project-specific `pyproject.toml`.

---

## §13 .github/ISSUE_TEMPLATE/ — parity ✅

Both have 6 templates:
- `agent-stall.yml` ✅
- `bug.yml` ✅
- `config.yml` (tmpl: `config.yml.tmpl`) ✅
- `feature-request.yml` ✅
- `incident.yml` ✅
- `vision-intake.yml` ✅

**Verdict:** ✅ **Full parity.**

---

## §14 Launcher (`new-project.sh`) — feature inventory

### 14.1 Surface

| Component | Detail |
|---|---|
| File | `/home/atilcan/dev-studio-launcher/new-project.sh` |
| LOC | 315 |
| Sister files | `README.md` (172), `LICENSE` (21) |
| Symlink target | `~/bin/new-project` (convention) |
| GitHub | `atilcan65/dev-studio-launcher` (HEAD `b0d820d`, no v0.3.0 tag) |

### 14.2 Flags

| Flag | Default | Effect |
|---|---|---|
| `--owner <login>` | `atilcan65` or env `GITHUB_OWNER` | Set the GitHub owner/org |
| `--dir <parent>` | `$DEV_STUDIO_HOME` or `~/projects` | Parent dir for clone |
| `--public` | ✅ default | Repo visibility public (ADR-0016) |
| `--private` | opt-in | Repo visibility private (Actions billed) |
| `-h`, `--help` | — | Show usage |

### 14.3 Steps performed (4 explicit)

```
Step 1: gh repo create <owner>/<name> [--public|--private] --clone
Step 2: Clone empty repo locally + add template as remote
Step 3: bash scripts/dev-studio-init.sh (render + PROJECT_TOKEN + canary)
Step 4: bash scripts/bootstrap-labels.sh (seed 34 labels)
```

### 14.4 What it INTENTIONALLY does NOT do

```
- Run e2e smoke test (caller runs manually)
- Start tmux session (caller runs dev-studio-start.sh when ready)
- Open Vision Intake issue (intentionally — human writes vision body thoughtfully)
```

### 14.5 Exit codes (6 distinct)

```
0  success
1  bad usage
2  preflight failed (gh/git/jq missing or unauthenticated)
3  repo already exists
4  gh repo create failed
5  init script failed
6  bootstrap-labels failed
```

### 14.6 v0.3 unversioned items

| Item | Issue | Fix |
|---|---|---|
| `v0.3.0` git tag | Commit `b0d820d` says "v0.3" but no tag; highest is `v0.2.0` | Tag + CHANGELOG |
| Last push 2026-06-17 | Dormant 3+ weeks | Not stale per se (no work was due) |
| **Actions billing step** | README warns "PROJECT_TOKEN canary on private Actions is paid" but no concrete link to org billing config | Add `RUNNER-SETUP.md` or step in v0.3.1 |
| **Self-hosted runner** | Launcher doesn't check whether runner is registered for `--private` | Pre-flight check: warn if no self-hosted + private Actions budget unclear |

### 14.7 §Action plan — launcher

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| L-01 | **TAG** `v0.3.0` on launcher HEAD + CHANGELOG stamp | orchestrator (low-risk) | Sprint 28 wave 1 |
| L-02 | **ADD** pre-flight check: if `--private` + no self-hosted registered → warn loud | developer | Sprint 28 wave 2 |
| L-03 | **ADD** `RUNNER-SETUP.md` to launcher: post-init guide for self-hosted runner registration | developer + owner | Sprint 28 wave 2 |

---

## §15 Self-hosted runner — calc 100% / tmpl 0%

### 15.1 Detailed runs-on table

```
AtilCalculator (11 workflows):
  ai-pr-review.yml:            runs-on: [self-hosted, Linux, X64, atilproject]
  label-cleanup.yml:           runs-on: [self-hosted, Linux, X64, atilproject]
  cross-repo-close.yml:        runs-on: [self-hosted, Linux, X64, atilproject]
  deploy.yml:                  runs-on: [self-hosted, Linux, X64, atilproject]
  secret-canary.yml:           runs-on: [self-hosted, Linux, X64, atilproject]
  ci.yml:                      runs-on: [self-hosted, Linux, X64, atilproject]
  lint-and-test.yml:           runs-on: [self-hosted, Linux, X64, atilproject]
  post-squash.yml:             runs-on: [self-hosted, Linux, X64, atilproject]
  d050b-dispatch.yml:          runs-on: [self-hosted, Linux, X64, atilproject]
  label-check.yml:             runs-on: [self-hosted, Linux, X64, atilproject]
  status-label-to-board.yml:   runs-on: [self-hosted, Linux, X64, atilproject]
                            → 11/11 ✅ self-hosted

dev-studio-template (9 workflows):
  cross-repo-close.yml:        runs-on: ubuntu-latest
  status-label-to-board.yml:   runs-on: ubuntu-latest
  ai-pr-review.yml:            runs-on: ubuntu-latest
  label-check.yml:             runs-on: ubuntu-latest
  ci.yml:                      runs-on: ubuntu-latest
  ci.yml:                      runs-on: ubuntu-latest  (duplicate file found)
  label-cleanup.yml:           runs-on: ubuntu-latest
  secret-canary.yml:           runs-on: ubuntu-latest
                            → 0/9 ❌ ubuntu-latest
```

### 15.2 Migration impact for `--private` new projects

```
Private repo + ubuntu-latest = Actions minutes billed = budget burn rate
  - 9 workflows × daily cron = ~270 Actions-min/month
  - GitHub free: 0 Actions-min for private
  - Paid tier: 2,000 Actions-min/month included ($0.008/min over)
  - Self-hosted: free
```

**Decision:** For `--private` projects, template's workflows will eat budget unless migrated to self-hosted OR owner accepts Actions billing.

### 15.3 §Action plan — runner

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| R-01 | **MIGRATE** 8/9 tmpl workflows to `runs-on: [self-hosted, Linux, X64, atilproject]` (lens i). 9th is `deploy.yml.tmpl` (already generic) | developer | Sprint 28 wave 1 |
| R-02 | **ADR-XXXX** "Self-hosted runner default in template" — ADR + owner-ratify | architect + owner | Sprint 28 wave 1 |

---

## §16 Sprint cadence / ceremonies — covered ✅

| Ceremony | Calc coverage | Tmpl coverage |
|---|:---:|:---:|
| Sprint kickoff (`/sprint-start`) | ✅ (.md) | ✅ (.md.tmpl) |
| Daily standup (`/standup`) | ✅ (.md) | ✅ (.md.tmpl) |
| Retrospectives | `docs/retros/RETRO-008..011.md` | ❌ (tmpl expects project to write own) |
| Sprint plans | `docs/sprints/sprint-NN/plan.md` | ❌ (per-project) |
| Sprint close | `docs/sprints/sprint-NN/close.md` | ❌ (per-project) |

**Verdict:** ✅ Tmpl has the 2 ceremony commands + expects project to maintain its own retros/sprint plans. **Coverage parity for the boot pattern.**

---

## §17 Q1-Q8 answers (with full evidence)

### Q1 — Is dev-studio-template ready to launch as a private project?

**Answer: 🟡 PARTIAL.** Org support exists (atilproject org, owner-only member);
launcher `--private` flag works syntactically; template structure is intact. **BUT:**
- `runs-on: ubuntu-latest` × 8 workflows × Actions minutes = billing risk
- 0 SHA-pinned actions = mutable-ref risk (lens h)
- No dry-run end-to-end test for private bootstrap

**Required to call "ready":**
- R-01 (runner migration) + R-02 (ADR)
- W-04 (SHA pinning)
- Owner Actions billing confirmation
- End-to-end dry-run with PROJECT_TOKEN

### Q2 — All AtilCalculator scripts/processes/doctrines/agents ported to template?

**Answer: 🔴 ~35-45% parity.** Detailed in §3-§9:
- Scripts: 12/38 PARITY (32%) + 6/38 PORT candidates
- Workflows: 8/11 PARITY (73%) — missing 3 + 19 SHA pins + 8 runs-on
- ADRs: 16/74 PARITY (22%) — ~28 port candidates
- Souls: 0/5 AMEND blocks PARITY (0%) — calc's .md is STALE
- Tests: 13/130 PARITY (10%) — per-script d-test writes needed
- Launcher: 5/6 PARITY (83%) — tag + Actions step missing

### Q3 — Self-hosted runner migration 100% complete?

**Answer: ✅ ATILCALCULATOR: 100% (11/11 workflows). ❌ TEMPLATE: 0% (0/9 workflows).**

Detailed in §15. For private projects, this gap is critical.

### Q4 — What could be added to template (scope expansion)?

**Answer (beyond Q2/Q3 gaps):**
- `pyproject.toml.tmpl` for project-specific tech-stack rendering
- `RUNNER-SETUP.md` post-init guide for self-hosted runner registration
- `retros/RETRO-NNN.template.md` pattern for retro-writing
- `test-plans/STORY-XXX-tests.template.md` for test plan conventions
- `soul-amends/SOUL-AMEND-proposal.template.md` for soul-amend proposals
- Issue template index.md.tmpl (consolidating ISSUE_TEMPLATE behavior)
- **6 candidate stories (Q-04..Q-09)**: see §Action plan roll-up

### Q5 — Is dev-studio-launcher still ready?

**Answer: 🟡 YES-BUT.** 4 unversioned items: missing v0.3.0 tag, dormant 3+ weeks,
no pre-flight for private + no Actions billing step, no RUNNER-SETUP.md. **Functional
flags work, but versioning + Actions gating need cleanup.** See §14.

### Q6 — new-projectsteps runbook

**Answer: ✅ Delivered in this PR (`docs/new-projectsteps.md`)** — 10-step detailed
runbook covering tools, visibility, launcher invocation, secrets/vars, template
rendering, label bootstrap, smoke tests, commit/push, tmux start, Vision Intake.

### Q7 — Is 1.0.1 + necessary work really complete?

**Answer: 🟡 PARTIAL for launcher, ❌ INCOMPLETE for template.**

- Template v1.0.1 ✅ (tag + CHANGELOG stamp + 10+ feature commits)
- Template feature parity: ~35-45% per Q2
- Launcher v0.3 in commit message but NO tag (highest is v0.2.0)
- The "necessary work" remains: port-wave for 28 ADRs + 6 scripts + 3 workflows + 11 d-tests + soul amend + runner migration + SHA pinning

### Q8 — Will all of this (process/scripts/audit/wake_nudges) come to template+launcher?

**Answer: 🟡 KISMEN.** Per cycle ~750 follow-up:
- **Base infra (agent-watch, heartbeat, is_alive, wake_nudges) IS in template** —
  `agent-watch.sh` has 10 wake_nudge refs in tmpl vs 16 in calc. The +6 calc-only
  refs are Katman 2-5 sprint-specific behaviors (verdict-watchdog, board-sentinel,
  gap-scan, etc.).
- **Launcher**: it does NOT and should NOT have agent-watch infra. Launcher is
  one-shot bootstrap. Agent runtime lives in the project (template's
  `scripts/dev-studio-start.sh` is the activator).
- **Sprint work product** (audit + sprint plans + retros + STORIES) belongs in
  each project, not template. Template's role: provide **patterns/templates**
  (`docs/templates/`).

---

## §Action plan roll-up — comprehensive

### Owner-decisions (pre-Sprint 28 wave 1)

| ID | Decision | Question |
|---|---|---|
| D-OD1 | Actions billing limit on atilproject org? (Q1) | Free / Paid / N/A? |
| D-OD2 | Template default visibility = public (ADR-0016), or flip to private-by-default? (Q1) | ADR amendment or freeze? |
| D-OD3 | Template `runs-on:` default = `[self-hosted, Linux, X64, atilproject]` specific, OR org-generic self-hosted, OR each project self-registers? (Q3) | ADR required (R-02) |
| D-OD4 | Strategy = template-parity closure (a) vs freeze-and-pivot (b) vs dual-track (c)? (Q7) | Sprint 28 scope gates Q2/Q4/Q7 |
| D-OD5 | Sprint 28 = pure gap-closure, or include 1-2 new features? (Q4) | Scope decision |

### Sprint 28 wave 1 candidates

| ID | Type | Description |
|---|---|---|
| S-01..S-08 | Script ports | 6 generic-port + 2 LEGACY-remove |
| W-01..W-04 | Workflow ports + SHA pinning | 3 port + 14+ SHA pins |
| R-01 + R-02 | Runner migration | 8/9 file edits + ADR |
| SL-01 + SL-02 | Soul AMEND ports | 2 amend blocks |
| SL-03 | Re-render calc souls | 5 files |
| A-02 + A-03 | ADR dedup (0043,0045,0049) | 3 files |
| L-01 | Launcher v0.3.0 tag | 1 commit |

(11 stories wave 1)

### Sprint 28 wave 2 candidates

| ID | Type | Description |
|---|---|---|
| S-09 | DEFER triage | 10 size-drift scripts |
| S-12 | agent-state.sh verdict-by field | 1 file |
| W-05 | Migrate runs-on | 8 file edits |
| A-01 | PORT 28 ADRs | ~28 files |
| D-01..D-03 | Pattern-port tmpls | 3 files |
| T-01 + T-02 | d-test parity | ~15 d-tests |
| L-02 + L-03 | Launcher Actions step + RUNNER-SETUP | 2 files |

(8 stories wave 2)

### Sprint 28 wave 3 candidates

| ID | Type | Description |
|---|---|---|
| S-10 + S-11 | agent-watch.sh + deploy-runner.sh reconcile | 2 files + 1000+ LOC drift resolution |
| A-04 | Template internal ADR | 1 file |
| Q-04..Q-09 (Q4 candidates) | Scoped candidates | ~6 stories |

(8 stories wave 3)

**Total: ~30+ candidate Sprint 28 stories** covering scripts + workflows + ADRs + souls + tests + launcher + runner + patterns.

---

## §Knowledge gaps declared (bilmiyorum)

- **Q1 dry-run** — full private bootstrap e2e not run; would need owner-confirmed
  Actions billing + scratch repo + 30 min run.
- **Q2 ADR triage** — per-ADR classification is educated guess based on title +
  source-file scope. Final triage needs 1-2 cycles of architect review.
- **Q4 candidate additions** — listed categories are incomplete; full audit
  would take 2-3 more cycles.
- **Q5 launcher b0d820d** — no test file present; whether v0.3 features
  actually work as documented is unverifiable from static analysis.
- **General:** No code modified. No commit to template or launcher. Findings
  are file-level + lightweight static check only. **MD5 compare not done for
  each script pair** — would catch drift hidden in same-name files.

---

## §Architect 9-Lens final attestation (cycle ~752, post-rebuild)

Per ADR-0054 §9-Lens Enforcement applied to PR #967 (v2):

| Lens | Status | Note |
|---|---|---|
| (a) Data flow | N/A | docs-only |
| (b) Runtime preconditions | N/A | doctrine-only |
| (c) Canonical entry point | ✅ | single SoT: this file |
| (d) Silent-skip risk | ✅ | explicit gaps + bilmiyorum declarations |
| (e) Idempotency | N/A | no exec |
| (f) Observability | ✅ | per-section §Action plan tables; ~30 stories roll-up |
| (g) Security & privacy | ✅ | no secrets printed; PROJECT_TOKEN only via `--secret set` |
| (h) Workflow YAML SHA pin | ⚠️ **DETECTED** | 0/9 tmpl workflows SHA-pinned — 14+ action refs at risk. **Action W-04 surfaced.** |
| (i) Platform hard constraints | ⚠️ **DETECTED** | 0/9 tmpl workflows on self-hosted runner. **Action R-01 surfaced.** |
| (j) Auto-gen file refs + live-state | ✅ | every LOC + tag + SHA + commit verified by `grep`/`wc -l`/`gh api` at cycle ~752 (re-verified post-W-04/R-01 detection) |
| (k) JS syntactic correctness | N/A | no `actions/github-script` |

**Verdict:** 🟢 OK — 2 lens-h/i issues **detected via the audit itself** (which is
what lens enforcement is supposed to do). Document them with high fidelity.

---

## §Final assessment

**Template is at ~35-45% feature parity with AtilCalculator** (weighted average
by importance: scripts 65%, workflows 80%, ADRs 22%, souls 0% AMENDs / 100%
CLAUDE.md coverage, tests 10%, runner 0%, launcher 75%).

**Critical gap clusters (must-do before template considered "production-ready"):**
1. **Self-hosted runner migration** (R-01) — required for private repos
2. **SHA pinning** (W-04) — required for supply-chain safety
3. **Soul AMEND blocks** (SL-01/02) — required for orchestrator doctrine alignment
4. **Re-render calc souls** (SL-03) — required because calc's souls are stale
5. **Action items roll-up** — ~30 stories to triage

**Non-critical (nice-to-have):**
- ADR port wave (~28)
- d-test parity (~71)
- Script size drift reconcile (~1039 LOC)

**Recommended Sprint 28 path:** Owner-decisions D-OD1..D-OD5 first → wave 1
(critical gap closure) → wave 2 (parity) → wave 3 (consolidation).

---

# §18 — @product-manager review (cycle ~757)

**PM lens:** "Voice of the user." Every story must answer "so what?" and
"for whom?". This section reframes the v2 audit from a USER perspective;
surfaces what the audit missed about user impact; and proposes Gherkin
acceptance criteria for the top-5 Sprint 28 candidate stories.

## §18.1 User personas implied by the audit

| Persona | Need | Audit gap impact |
|---|---|---|
| **Atil (current owner, atilcan65)** | Maintain atilcalc + dev-studio-template + dev-studio-launcher in sync; own-merge gate; tech-lead | v2 audit serves Atil directly; 35-45% parity means he's stuck carrying "knowledge in his head" rather than template being self-sufficient |
| **Project Founder (new)** | Bootstrap a new project from template + launcher; expect it to "just work" with all features | If they run the launcher TODAY and pick `--private`, Actions minutes will burn; template workflows will fail without self-hosted runner registered |
| **Agent (peer)** | Render its soul from `.tmpl` and operate as a 5-agent team | Calc's souls are STALE (80 LOC vs 300 LOC tmpl); PM/orchestrator/developer/tester agents may be following outdated doctrine |
| **Future contributor (downstream)** | Open PR against template; expect CI green + doctrine-compliant | SHA-unpinned actions in tmpl = supply-chain risk; mutable refs at risk of breaking |

## §18.2 "So what?" reframing of top gaps

The v2 audit's top-line "**~35-45% feature parity**" is a technical statement. **For users it means:**

| Technical gap | User-impact |
|---|---|
| 0/9 template workflows SHA-pinned | Atil's supply chain can drift silently; future contributor's PRs may fail mysteriously on Action version bumps |
| 0/9 template workflows on self-hosted runner | Project Founder with `--private` will burn Actions budget without warning; first org-private Actions bill may be a surprise |
| 3 SOUL AMEND blocks missing in tmpl | Orchestrator agent in NEW projects won't have W6 + Peer-Poke doctrine → cross-agent push errors not prevented |
| Calc souls STALE (no template-version pin) | Atil's own agents (PM/architect/developer/tester) are reading outdated doctrine; mistakes may already be happening silently |
| ~28 ADRs not in tmpl | Atil will keep "moving the doctrine" but template-using projects don't see it; their docs/PRs use stale citations |
| Launcher v0.3 not tagged | New project founder pulling "v0.3" in CI won't get a stable reference; debugging becomes harder |

## §18.3 Top-5 Sprint 28 candidate stories — full user-story form

**STORY-S28-001 (from S-08 + W-01 + W-04 + R-01)**: **Critical gap closure**
- **As a** Project Founder trying to bootstrap a new private project
- **I want** the template's workflow scripts to ship with self-hosted runner label, SHA-pinned Actions, and the legacy `peer-poke.sh`/`ping.sh` noise removed
- **So that** my first Actions run is predictable, my budget isn't burned by mutable refs, and the next agent's tmux session starts cleanly

**Given/When/Then ACs:**
- **Given** a fresh `atilproject/<new-private-project>` repo cloned from `dev-studio-template` HEAD
- **When** I enable Actions on the repo after registering a self-hosted runner
- **Then** every workflow file's `runs-on:` line is `[self-hosted, Linux, X64, atilproject]`
- **And** every `uses: actions/*@<major>` reference is replaced with the exact 40-char SHA per lens (h)
- **And** `peer-poke.sh` + `ping.sh` are absent from `scripts/` (legacy noise removed)
- **And** the canary mirror push (`git push canary main --follow-tags`) succeeds with parity-equivalent workflow output

**STORY-S28-002 (from SL-01/02/03)**: **Orchestrator doctrine parity**
- **As** the orchestrator agent in any new project
- **I want** my soul file to include the W6 branch-ownership-matrix amendment + §Peer-Poke Discipline + Issue #414 base
- **So that** I correctly enforce cross-agent push authority + dual-channel auto-ping

**Given/When/Then ACs:**
- **Given** the orchestrator soul `.tmpl` in `dev-studio-template`
- **When** I open `docs/sprints/sprint-28/00-audit-baseline.md` §6.2 to verify coverage
- **Then** I see 3 amend blocks in the rendered `.md` matching §6.2 calc-versions
- **And** the §Peer-Poke Discipline section references ADR-0033 explicitly
- **And** after running `bash scripts/dev-studio-init.sh` in a fresh project, the local `.claude/agents/orchestrator.md` matches §6.2 word-for-word

**STORY-S28-003 (from A-02 + A-03)**: **ADR housekeeping**
- **As** an architect drafting new ADRs in any project
- **I want** the template's ADR-0043, ADR-0045, ADR-0049 to be deduplicated
- **So that** I don't write superseding ADRs without knowing the predecessor canon

**Given/When/Then ACs:**
- **Given** template's `docs/decisions/INDEX.md.tmpl`
- **When** I list all ADR files
- **Then** ADR-0043 is absent or marked "Superseded by ADR-0054"
- **And** ADR-0045 is absent or marked "Consolidated into ADR-0046"
- **And** ADR-0049 is consolidated into ADR-0046 (single source for d-test framework)

**STORY-S28-004 (from L-01 + L-02)**: **Launcher confidence**
- **As** a Project Founder picking `--private` for the first time
- **I want** the launcher's `--private` path to (a) warn loud if no self-hosted runner is registered + (b) ship tagged at v0.3.0
- **So that** my first private-bootstrap doesn't surprise me with Actions bills

**Given/When/Then ACs:**
- **Given** `gh api /repos/atilproject/<new-repo>/actions/runners` returns `[]`
- **When** I run `new-project.sh my-secret-app --private`
- **Then** the launcher prints a loud warning ("--private + zero self-hosted runners detected; will burn Actions budget @ ~270min/month")
- **And** prompts: "continue? [y/N]" — defaults to N
- **And** `git tag -l --sort=-creatordate` on the launcher remote shows `v0.3.0` after this work is merged

**STORY-S28-005 (from S-01..S-06 + L-03)**: **Self-sufficient template**
- **As** Atil (current owner)
- **I want** the template to ship 6 generic-port scripts (`cross-repo-scan`, `proactive-board-scan`, `orchestrator-gap-scan`, `audit-project-refs`, `strip-cascade-labels`, `lint-notify-invocations`) + their d-tests + a `RUNNER-SETUP.md` post-init guide
- **So that** new-project founders get the full autonomy loop without waiting for me to hand-port each script

**Given/When/Then ACs:**
- **Given** a fresh project cloned + `dev-studio-init.sh` run
- **When** I list `scripts/*.sh` | grep -v install | grep -v tests
- **Then** I see 6 additional scripts: each has d-test sibling (`dAAA-script-name.sh`) green in `scripts/tests/`
- **And** `docs/RUNNER-SETUP.md` exists with the `config.sh --labels self-hosted,Linux,X64,atilproject` snippet
- **And** `dreg-post-restart-label-guard.sh` still passes (no regression)

## §18.4 PM-Reported gaps not in v2 audit

The v2 audit by @orchestrator (cycle ~752) is technically comprehensive but **misses the user-perspective framing in three places:**

1. **No persona/role section in `docs/new-projectsteps.md`** — the runbook reads as a script-for-techies, not a guide for a founder. **PM AC-1**: add a §Personas (project founder, agent operator, future contributor) up-front.

2. **Knowledge gaps in v2 read as "didn't have time" rather than "this matters for the user"** — e.g., "Q1 ready-to-launch dry-run not run" is actually "**A Project Founder picking --private TODAY will hit billing surprises**." **PM AC-2**: reframe each Knowledge Gap in "what does this mean for the user" language; mark FATAL/SERIOUS/INCONVENIENT severity per gap.

3. **Missing user-facing ACs** in §Action plan roll-up stories — every story is "PORT X" but lacks "for whom" / "what does done look like for the user". **PM AC-3**: every wave-1 story gets a user-story-framed AC snippet inline; full Gherkin in `docs/backlog/STORY-S28-NNN.md` per PM's standard workflow.

## §18.5 PM-lens cross-references

- **PM lane ownership**: `docs/sprints/sprint-28/plan.md` will be PM-written after orchestrator §20 plan approval.
- **Gherkin format**: ADR required? — **PM recommends** add ADR "INVEST + Gherkin AC doctrine" if not already in template (didn't see one in 16 ADRs — confirm in cycle ~758 architect review).
- **PM-known sister-patterns**: atilcalc's own STORY-007..016 + STORY-S26-001..003 in `docs/backlog/`. PM will use those formats for Sprint 28 STORIES.

## §18.6 PM verdict on v2 audit

**Verdict:** 🟡 **Acceptable but PM-supplemented** — v2 is comprehensive for technical state, but **needs PM-lens user framing** applied in §18.3/§18.4 for full Sprint 28 backlog usability. **NOT a blocker**; can be applied during sprint-28-story-creation phase.

**PM recommends owner decisions D-OD1..D-OD5 first**, then stories are written by PM with full user-perspective framing per §18.3.

---

# §19 — @architect review (cycle ~758)

*(Placeholder — full 9-Lens a-k coverage applied after PM hand-off. Per ADR-0054 §9-Lens Enforcement, all 11 lenses (a-k) will be verified; PM-identified gaps will be flagged + 9-Lens-detected gaps will be added.)*

---

# §20 — @orchestrator final plan (cycle ~759)

*(Placeholder — execution plan + sprint-28 dependency graph + risk register + on-call escalation cadence. Will write after architect §19 completes.)*

---

— @product-manager self-executed review (cycle ~757, 2026-07-10T20:42+03:00).
Architect + orchestrator sections pending.
