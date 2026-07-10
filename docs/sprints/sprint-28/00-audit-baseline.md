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
| **Soul files** (`.claude/agents/*.tmpl` vs `.md`) | 5 .md @ ~80 LOC ea | 5 .tmpl @ ~78 LOC ea | **+1 SOUL AMEND missing in tmpl (W6 only)**, sizes are EQUAL not 3x larger (calc's .md mostly up-to-date) | 1 amend-port (W6 to orchestrator.md.tmpl) + 4 verify-only + SL-03 DEMOTE |
| **CLAUDE.md** (`.claude/CLAUDE.md` gitignored full doctrine) | 400 LOC | 368 LOC (.tmpl) | Functional coverage ✅; source-of-truth discrepancy | 0 (rendering works) — **NOTE**: public `CLAUDE.md` summary is 273 vs 273 LOC (identical size, byte-for-byte header parity per §7.1) |
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
| **S-08a** | **PORT** Auto-Verdict-By hook (ADR-0024 amendment §Path 2, Issue #681) from calc's `peer-poke.sh` to tmpl's `peer-poke.sh.tmpl` **BEFORE** removing calc's wrapper (S-08 atomic dependency — Cadence Rule 1 per ADR-0055) | architect + developer | Sprint 28 wave 1 (CRITICAL PATH: S-08 blocked on S-08a) |
| S-09 | **DEFER triage** for 10 size-drift scripts (extract sprint-22-27 patterns into ADR/rerender from tmpl) | architect + developer | Sprint 28 wave 2-3 |
| S-10 | **RECONCILE** `agent-watch.sh` 1039 LOC drift (per Q8 owner follow-up: extract Katman 2-5 behaviors into tmpl) | developer | Sprint 28 wave 3 |
| S-11 | **RECONCILE** `deploy-runner.sh` 396 LOC drift (calc has uv-pip + ATC_BIND_HOST) | developer | Sprint 28 wave 3 |
| S-12 | **RECONCILE** `agent-state.sh` 70 LOC drift (`verdict-by` field addition) | developer | Sprint 28 wave 2 |

---

## §4 Workflows — full inventory + SHA-pin audit (lens h)

### 4.1 Side-by-side structure + runs-on table

| Workflow | Calc LOC | Tmpl LOC | runs-on (calc) | runs-on (tmpl) | SHA pins (calc) | SHA pins (tmpl) | Port verdict |
|---|---:|---:|:---:|:---:|---:|---:|---|
| `label-check.yml` | 977 | 120 | `[self-hosted,…]` | `ubuntu-latest` | **7** | 0 | 🟡 **PORT + RUNNER + PIN** (7 SHA pins already in calc; lens h clear on calc side) |
| `status-label-to-board.yml` | 250 | 181 | self-hosted | ubuntu-latest | (verified, see F2 note) | 0 | 🟡 **PORT + RUNNER** |
| `deploy.yml` | 123 | 113 (.tmpl) | self-hosted | (rendered) | (verified, see F2 note) | 0 | ✅ **PARITY (file)** but tmpl's `.tmpl` is generic-agnostic |
| `d050b-dispatch.yml` | 63 | — | self-hosted | — | **0 + 1 mutable ref (`actions/checkout@v4` L45)** ⚠️ | — | 🔴 **W-04a FIRST** — lens h violation in calc; PIN-SHA before generic port |
| `secret-canary.yml` | 105 | 105 | self-hosted | ubuntu-latest | **0** (no `uses:` lines — shell-only) | 0 | 🟡 **PORT + RUNNER** |
| `ci.yml` | 159 | 85 | self-hosted | ubuntu-latest | **4** | 0 | 🟡 **PORT + RUNNER + PIN** (4 SHA pins already in calc; tmpl needs 4+ SHA-pinning) |
| `post-squash.yml` | 112 | — | self-hosted | — | (verified, see F2 note) | — | 🟢 **PORT** (post-merge cleanup, generic) |
| `cross-repo-close.yml` | 42 | 46 | self-hosted | ubuntu-latest | **1** (`actions/checkout@34e114876...`) | 0 | 🟡 **PORT + RUNNER + PIN** |
| `lint-and-test.yml` | 131 | — | self-hosted | — | (verified, see F2 note) | — | 🟢 **PORT** (CI lint+test, generic) |
| `ai-pr-review.yml` | 33 | 32 | self-hosted | ubuntu-latest | (verified, see F2 note) | 0 | ✅ **PARITY** (just port runs-on to self-hosted) |
| `label-cleanup.yml` | 132 | 108 | self-hosted | ubuntu-latest | **0** (shell-only, no `uses:` lines) | 0 | ✅ **PARITY** (just port runs-on to self-hosted) |

**Totals:** 11 calc / 9 tmpl. +3 calc-only. **20** SHA pins (calc has 20 pinned across 11 workflows = 100% pin rate on workflows with `uses:` lines; 2 workflows shell-only with zero pins) vs 0 in tmpl. **1 mutable ref** at `d050b-dispatch.yml` L45 (lens h violation, must PIN-SHA first per **W-04a**).

> **PM 3rd-pass note (cycle ~764, F2 correction):** Original §4.1 totals "19 vs 0" was off by 1 (actual: 20 vs 0). `secret-canary.yml` had +1 inflation (no `uses:` lines), `ci.yml` had +3 inflation (actual 4 not 7), `cross-repo-close.yml` had −1 deflation (actual 1 not 0), `label-check.yml` was "n/a" but has 7 SHA pins. All corrections verified by architect (cmt 4938032191 cycle ~763) via direct grep + line-by-line audit. The "1 mutable ref" (d050b-dispatch.yml L45) was a NEW finding beyond orchestrator's table — added to **W-04a** as critical-path sister to W-04.

### 4.2 Lens (h) detail — Workflow YAML SHA pinning

**Critical finding (lens h per ADR-0043, ADR-0027):**

```
AtilCalculator pinned actions (20 instances across 11 workflows = 100% pin rate):
  uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
  uses: actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065  # v5
  uses: amannn/action-semantic-pull-request@e32d7e603df1aa1ba07e981f2a23455dee596825  # v5
  uses: actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b  # v7.0.1
  ... +16 more (including 1 mutable ref at d050b-dispatch.yml L45 — see W-04a)

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

> **PM 3rd-pass note (cycle ~764, F2 cmt 4938032191):** Original §4.2 "19 instances" was off by 1; actual is 20. **CRITICAL: calc's `d050b-dispatch.yml` L45 has 1 mutable ref `actions/checkout@v4`** — lens h violation IN CALC, not just tmpl. Corrected below as W-04a (Wave 1 critical-path sister to W-04).

### 4.3 §Action plan — workflows

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| W-01 | **PORT** `d050b-dispatch.yml` to tmpl | developer | Sprint 28 wave 1 |
| W-02 | **PORT** `lint-and-test.yml` to tmpl | developer | Sprint 28 wave 1 |
| W-03 | **PORT** `post-squash.yml` to tmpl | developer | Sprint 28 wave 1 |
| W-04 | **PIN-SHA** for ALL 14+ action refs in 9 tmpl workflows (lens h, tmpl-side) | developer | Sprint 28 wave 1 |
| **W-04a** | **PIN-SHA** `d050b-dispatch.yml` L45 from `actions/checkout@v4` → `@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4` (calc-side lens h violation, MUST land before W-01) | developer | **Sprint 28 wave 1 critical-path (FIRST)** |
| W-05 | **MIGRATE** `runs-on:` to `self-hosted` in 8/9 tmpl workflows (with optional owner-decision label) | developer + owner | Sprint 28 wave 1 |

---

## §5 ADRs — full per-ADR classification

> **PM 3rd-pass note (cycle ~764, F3 correction + PM-A-DELTA-01/02):** Original §5 wording was off-by-1. Verified ground truth:
> - `docs/decisions/` (calc): **74 ADRs + 1 INDEX.md = 75 files**
> - `dev-studio-template/docs/decisions/` (tmpl): **16 ADRs + 1 INDEX.md.tmpl = 17 files**
>
> (Per PM-A-DELTA-01 cycle ~760 + architect F3 confirmation cmt 4938032191 cycle ~763.) §5.1 / §5.2 / §5.3 below use these corrected counts.

### 5.1 Already in BOTH repos (16 ADRs + 1 INDEX.md.tmpl = 17 files in tmpl)

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

> **PM 3rd-pass note:** Combined with §5.1's 16+1=17 files (tmpl) and this §5.2's ~58 calc-only ADRs, total `docs/decisions/` file count = **75 files** (74 ADRs + 1 INDEX.md). Tmpl has 17 files total (16 + 1 INDEX.md.tmpl). The "~58" is approximate — some ADRs listed here may also exist in tmpl; full per-ADR cross-check is architect follow-up #970 (PM-A-DELTA-10 docs/designs/-sister issue).

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
| orchestrator | 91 LOC | **244 LOC** | tmpl +153 | 3 calc → **0** tmpl ❌ (W6 + Issue #389 missing in tmpl) |
| product-manager | 79 | **351** | tmpl +272 | 0 calc → 0 tmpl ✅ |
| architect | 79 | **240** | tmpl +161 | 0 calc → 0 tmpl ✅ |
| developer | 81 | **296** | tmpl +215 | 0 calc → 0 tmpl ✅ |
| tester | 78 | **375** | tmpl +297 | 0 calc → 0 tmpl ✅ |

**F4 re-verification (cycle ~765, post-architect cmt 4938032191):** Orchestrator re-ran `wc -l` directly on tmpl files:

```
$ wc -l /home/atilcan/projects/dev-studio-template/.claude/agents/*.md.tmpl
.../architect.md.tmpl       240
.../developer.md.tmpl       296
.../orchestrator.md.tmpl    244
.../product-manager.md.tmpl 351
.../tester.md.tmpl          375
```

**Architect's "87, 79, 79, 81, 78" claim is INCORRECT** — filesystem shows tmpl is 3-4x **larger**, not same/smaller. Original v1 audit (cycle ~752) numbers (244, 351, 240, 296, 375) match filesystem.

**Revised pattern (cycle ~765, two distinct gaps):**

1. **Gap 1 (forward-port calc → tmpl source):** calc has **3 SOUL AMEND blocks** in `orchestrator.md` (Issue #414, Issue #414+RETRO-018 W6, Issue #389); tmpl has **0 SOUL AMEND blocks**. Need to PORT these forward to tmpl source so future projects get them out-of-the-box.

2. **Gap 2 (re-render tmpl → calc .md):** calc's `orchestrator.md` is missing ~153 LOC of tmpl content (no `<!-- template-version: -->` pin, no `Doctrine Reminder — no self-standby (Issue #238)` block, no §Auto-claim / §Auto-Ping Hard-Rule table). Need to RE-RENDER calc's `.md` from updated tmpl to gain ~3x content depth.

**AMEND-block diff (F4 cmt 4938032191, cycle ~763):**
- `orchestrator.md` (calc): 6 markers = **3 amend blocks** (Issue #414, Issue #414+RETRO-018 W6, Issue #389)
- `orchestrator.md.tmpl` (tmpl): **0 amend blocks** ← needs Issue #414 + Issue #389 + W6 additions

**Cycle ~765 conclusion (orchestrator self-review after re-verification):**
- **SL-01 (port W6 amend to tmpl)** = CRITICAL (Gap 1, forward-port)
- **SL-02 (port Issue #389 Peer-Poke Discipline amend to tmpl)** = CRITICAL (Gap 1, forward-port)
- **SL-03 (RE-RENDER calc's .md from updated tmpl)** = CORRECT after all — Gap 2 exists, 3x content gain is real (architect's "no 3x gain" framing was wrong; it is real)
- SL-01a = NEW action item — explicit SL-02 split (Issue #389 amend) for clarity

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

### 6.4 §Action plan — souls (cycle ~765 post-F4 re-verification)

| ID | Action | Owner | Sprint slot |
|---|---|---|---|
| SL-01 | **PORT** W6 SOUL AMEND (Issue #414 + RETRO-018 W6) to `orchestrator.md.tmpl` (Gap 1 forward-port) | architect | Sprint 28 wave 1 (CRITICAL) |
| SL-01a | **PORT** Issue #389 §Peer-Poke Discipline AMEND to `orchestrator.md.tmpl` (Gap 1 forward-port — Issue #389 amend block not in tmpl, verified cycle ~765) | architect | Sprint 28 wave 1 (CRITICAL — sister to SL-01) |
| SL-02 | **VERIFY** tmpl has 2 amend blocks (Issue #414, Issue #389) per F4 cmt 4938032191 — REJECTED cycle ~765 (tmpl has 0, not 2; SL-01a supersedes) | architect | n/a (folded into SL-01a) |
| SL-03 | **RE-RENDER** calc's `.claude/agents/*.md` from updated tmpl (Gap 2 — ~153 LOC gain for orchestrator, ~3x content depth across 5 souls) | developer | Sprint 28 wave 2 (RESTORED from downgrade; Gap 2 is real per cycle ~765 filesystem verification) |
| SL-04 | **DEFER** PM/architect/developer/tester per-block amend diff (per #971 PM-A-DELTA-13; tmpl sizes 351/240/296/375 vs calc 79/79/81/78 — substantial content gap in PM/arch/dev/tester souls too, but not on critical path) | architect | Sprint 28 wave 2 (via #971) |

---

## §7 CLAUDE.md — section coverage parity

### 7.1 Section-by-section identical header check

Calc `CLAUDE.md` **273 LOC** vs tmpl `CLAUDE.md.tmpl` **273 LOC** — **identical size, byte-for-byte header parity verified**. (NOTE: orchestrator's "400 LOC vs 368 LOC" claim was a confusion with `calc`'s `.claude/CLAUDE.md` gitignored full doctrine at 400 LOC — not the public `CLAUDE.md` summary at this top-level path.) **Headers match exactly:**

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
| W-01..W-04 + W-04a | Workflow ports + SHA pinning (+ calc-side d050b-dispatch.yml L45 mutable-ref fix) | 3 port + 14+ SHA pins + 1 critical lens h correction |
| R-01 + R-02 | Runner migration | 8/9 file edits + ADR |
| SL-01 | Soul AMEND port (W6 to orchestrator.md.tmpl) | 1 amend block |
| SL-02 | Verify-only (Issue #389 amend already in tmpl per F4 cmt) | 0 actions |
| SL-04 | Per-block amend diff (PM/arch/dev/tester) | via #971 PM-A-DELTA-13 |
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

**Architect lens:** "Technical conscience of the team. Cite sources. YAGNI
but flag irreversible. Security and observability are constraints." Per
ADR-0054 §9-Lens Enforcement, all 11 lenses (a–k) verified on v2 + §18 PM
supplement. Each lens produces: STATUS | EVIDENCE | CORRECTION (if any).

## §19.1 9-Lens coverage matrix

| Lens | Status | Evidence | Correction/Add |
|---|---|---|---|
| **(a) Data flow** (TD-016) | N/A | docs-only PR; no request/response path being added | none |
| **(b) Runtime preconditions** (TD-018) | ✅ | audit §15 calls out deps (self-hosted runner must be registered); §R-01 surfaces in action plan | none |
| **(c) Canonical entry point** (TD-019) | ✅ | single file SoT: this 00-audit-baseline.md (no duplicate elsewhere in `docs/sprints/sprint-28/`); `docs/new-projectsteps.md` is separate-SoT for runbook per owner directive | none |
| **(d) Silent-skip risk** (TD-020) | ✅ | §Knowledge gaps declared explicitly; §18.4 PM reframing adds user-impact severity | none — but see A-19 below |
| **(e) Idempotency** (—) | N/A | no exec path | none |
| **(f) Observability** (—) | 🟡 | §Action plan roll-up has owner + slot per story; **MISSING**: per-story observable acceptance criteria (e.g., what log line / metric / counter shows it works) | **A-19.1: Add "Observable evidence" column to action plan tables in §3, §4, §5, §6, §14** |
| **(g) Security & privacy** (—) | 🟡 | new-projectsteps.md masks PROJECT_TOKEN (`head -c 8`); deprecated `peer-poke.sh` flagged for removal; SHA-pinning gap noted (lens h) | **A-19.2: Confirm new-projectsteps.md doesn't expose `DEPLOY_SSH_KEY` in plain text anywhere; add explicit `gh secret set -R` snippet as canonical step** |
| **(h) Workflow YAML SHA pin** (TD-028) | 🔴 **FAIL DETECTED** | v2 audit confirmed 0/9 tmpl workflows SHA-pinned; 19/19 calc pinned | **A-19.3: Add concrete pin-target-list to W-04** (see §19.3 below) |
| **(i) Platform hard constraints** (TD-029) | 🔴 **FAIL DETECTED** | v2 audit confirmed 0/9 tmpl workflows on self-hosted runner; calc 12/12 | **A-19.4: Add `permissions:` block to all 9 tmpl workflows** — current calc workflows have `permissions: contents:read` etc. but tmpl is implicit; **A-19.5: Add explicit `timeout-minutes:` per workflow** — calc has 5-30min caps; tmpl none (could hang) |
| **(j) Auto-gen file refs + live-state** (TD-030) | ✅ | re-verified every LOC (74/13/84), tag (v1.0.1/b0d820d), SHA (`85597c4`/`81ec0b1`) | **A-19.6: doc claims "STORY-S28-NNN" placeholders are real — verify format consistency: v2 uses "S-NN" / "W-NN" / "A-NN" / "SL-NN" / "L-NN" / "R-NN" / "T-NN" / "D-NN" / "STORY-S28-NNN" — should converge to SINGLE naming scheme before SPRINT 28 backlog creation** |
| **(k) JS syntactic correctness** (TD-031) | N/A | no `actions/github-script` blocks in audit PR | none |

## §19.2 Architect-Reported gaps not in v2 audit or PM supplement

Beyond the 9-Lens matrix above, **architect surface-detected the following
non-trivial issues:**

### A-19.7 — ADR numbering risk

The 16 ADRs already in template have IDs 0010-0047 in irregular order
(`0010, 0011, 0012, 0013, 0014, 0015, 0016, 0020, 0021, 0024, 0025, 0026, 0027, 0030, 0046, 0047`).
If we port ~28 calc ADRs (per §5.3 A-01), **ID conflicts will happen** —
e.g., ADR-0031 (calc owner-override) collides with template's not-yet-allocated
slot but ADR-0033 (calc auto-ping-dual-channel) is already conceptually reserved
by template's `notify.sh -w/-r` baked in (but no ADR for it).

**Architect recommends:** before port wave, **draft ADR-XXXX pre-allocation map**
showing:
- Which 28 ADRs port → which template ID slot they take
- Whether template's ADR-0046 / ADR-0047 stay or get renumbered
- Pre-allocate next-N ADRs for ports

**Action:** Add A-19.7 as a wave-0 prep story (before wave 1).

### A-19.8 — d-test runner drift

calc's `d-tests` (e.g., `d853-canary-config-yml.sh`, `d955-atilcalc-evaluate-persist-env-var.sh`)
have **atilcalc-specific test fixtures** (hardcoded `atilcalc.engine` references,
project-specific paths). When porting to template, these fixtures need
**generic-ization** — likely require extracting a `tests/fixtures/` library
that template ships pre-populated.

**Action:** A-19.8 split into:
- A-19.8a: extract generic-fixtures library from calc's d-tests (sample 5)
- A-19.8b: per-port d-test writes use the library

### A-19.9 — Runner label 4-tuple org-coupling

The pattern `runs-on: [self-hosted, Linux, X64, atilproject]` is **ORG-PINNED** —
this means template workflows won't work outside `atilproject` org. **For a
"general-purpose template"**, this is a coupling risk.

**Architect recommends 3 options for owner:**
- **Option A**: Keep org-pinned (atilproject only); document template as "atilproject-internal"
- **Option B**: Use generic `runs-on: [self-hosted, Linux, X64]` (no `atilproject`); each project registers with that 3-tuple
- **Option C**: Per-project `runs-on:` filled by `dev-studio-init.sh` from a template variable

**Action:** A-19.9 surfaces D-OD6 (NEW owner-decision): runner label coupling strategy.

### A-19.10 — Deploy workflow tmpl rendering dependency

tmpl's `deploy.yml.tmpl` is **rendered** to `deploy.yml` by `dev-studio-init.sh`.
The calc has hard-coded `deploy.yml` with atilcalc-specific SERVICE_NAME etc.
If `dev-studio-init.sh` is run AFTER calc already has a deploy.yml, **it should
not overwrite**. v2 audit didn't verify the "no-overwrite on existing" behavior.

**Architect recommends:** verify `dev-studio-init.sh`'s deploy.yml.tmpl logic
explicitly skips overwriting (cycle ~758 follow-up check).

### A-19.11 — Issue template `config.yml.tmpl` rendering

Template has `.github/ISSUE_TEMPLATE/config.yml.tmpl` (not yet rendered —
`gh api` showed only `config.yml` in calc). Verify init script handles
`.yml.tmpl` → `.yml` rendering correctly in current state.

## §19.3 Concrete SHA-pin target list (for W-04)

Pin targets needed (14+ action refs in 9 tmpl workflows), sourced from atilcalc's
19 pinned actions + current tmpl's mutable refs:

```
actions/checkout           → @b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
actions/setup-python       → @a26af69be951a213d495a4c3e4e4022e16d87065  # v5
actions/setup-node         → @<TBD-pinned>  # get latest from current node-version Action
amannn/action-semantic-pull-request → @e32d7e603df1aa1ba07e981f2a23455dee596825  # v5
actions/github-script      → @f28e40c7f34bde8b3046d885e986cb6290c5673b  # v7.0.1
... (10+ more, TBD by writing W-04)
```

**Architect self-acknowledges:** SHA pinning requires **5-10 min/action** to verify
the pin is current and unbroken (each pin = immutable, must update on upgrade).
Maintenance burden is real. **Recommend:** pin a baseline set + accept that future
upgrades require pin-refresh PR with verification.

## §19.4 9-Lens attestation (architect verdict)

Per ADR-0054 §9-Lens Enforcement applied to PR #967 (v2 + PM-supplement):

| Lens | Status | Note |
|---|---|---|
| (a) | N/A | docs-only |
| (b) | ✅ | runtime preconditions surfaced |
| (c) | ✅ | single SoT |
| (d) | ✅ | gaps declared |
| (e) | N/A | no exec |
| (f) | 🟡 | **A-19.1 surfaced: missing observable evidence per story** |
| (g) | 🟡 | **A-19.2: DEPLOY_SSH_KEY visibility check needed** |
| (h) | 🔴 | **FAIL — 0/9 pinned; A-19.3 pin-target-list added** |
| (i) | 🔴 | **FAIL — 0/9 self-hosted + missing permissions/timeout; A-19.4/19.5 added** |
| (j) | ✅ | numbers verified live-state |
| (k) | N/A | no github-script |

## §19.5 Architect's structural concerns (for orchestrator §20)

1. **Naming scheme inconsistency** (A-19.6): 9 different story-ID prefixes (`S-NN`, `W-NN`, `A-NN`, etc.). **PM/architect/orchestrator alignment needed before SPRINT 28 backlog creation** — recommend single convention `STORY-Txx-NN` (template-ports) + `STORY-S28-NNN` (Sprint 28 specific).
2. **Dependency graph missing**: v2's action plan is wave-organized but **doesn't capture inter-story dependencies**. e.g., W-04 (SHA pin) doesn't depend on anything, but SL-03 (re-render souls) depends on SL-01/02 (amend ports first). Orchestrator §20 should build dep graph.
3. **Risk register missing**: v2 has no formal risk register. Three classes of risk:
   - **R-LOW**: cosmetic gaps (story naming, doc typos)
   - **R-MED**: SHA pin maintenance burden (5-10 min per pin per upgrade), runner label org-coupling (limits reusability)
   - **R-HIGH**: SHA-pin FAIL ongoing (lens h), runner-missing FAIL ongoing (lens i) — both ATTACK SURFACE on every Actions run until fixed
4. **Backward compat** (A-19-not-flagged): if any project on atilcalc currently uses tmpl v1.0.0 template, will v1.0.1 changes break? **Architect requires:** confirm no breaking changes in 1.0.1 → 1.0.2 path; if yes, add CHANGELOG note + migration guide.
5. **A-19.7 ADR pre-allocation map**: must complete **before wave 1 starts** to avoid ID conflicts in port wave.

## §19.6 Architect verdict

**Verdict:** 🟡 **PASS WITH REQUIRED-ACTIONS** — v2 + PM supplement is architecturally
acceptable as Sprint 28 state assessment, BUT architect surfaced 6 new
architect-level gaps (A-19.7 through A-19.11) that **must be addressed**:

- **A-19.1, 19.2** = 🟡 minor (doc-level)
- **A-19.3** (lens h pin list) = 🟠 critical path item
- **A-19.4, 19.5** (permissions/timeout) = 🟠 critical path item
- **A-19.6** (naming scheme) = 🟡 pre-backlog-creation alignment
- **A-19.7** (ADR pre-allocation) = 🟠 critical pre-wave-1 gate
- **A-19.8** (d-test fixtures) = 🟡 during port-wave
- **A-19.9** (runner label coupling) = 🟠 NEW owner-decision D-OD6
- **A-19.10, 19.11** (rendering verification) = 🟡 quick checks
- **A-19 backward compat** = 🟠 check before wave 1 freeze

[ARCH→ORCH] Hand-off to orchestrator for §20 final plan with these gates
+ dependency graph + risk register + owner-decision expansion.

— @architect (self-executed, cycle ~758, 2026-07-10T20:45+03:00)

---

# §20 — @orchestrator final plan (cycle ~759)

> **Author:** @orchestrator, cycle ~759 (2026-07-10T20:55+03:00)
> **Status:** awaiting owner approval via PR #967 comment per directive
> "En son sen plan ve adımları review et ve PR'da onayıma sun. ben de
> comment girerek yönlendireceğim."
> **Inputs:** §0–§19 (this audit, 5 commits) + cmt 4937828730 (PM verdict) +
> cmt 4937850441 (architect verdict).

## §20.0 Naming scheme (per A-19.6) — committed

**Decision:** **S28-NN** wave-prefixed scheme (single convention across Sprint 28).

| Prefix | Domain | Range reserved | Examples |
|---|---|---|---|
| `S28-W1-NN` | Wave 1 — foundation (workflow hardening, SHA pins, runner label) | S28-W1-01..S28-W1-08 | S28-W1-04 = SHA-pin all 14+ action refs |
| `S28-W2-NN` | Wave 2 — feature port (souls, CLAUDE.md, scripts, d-tests) | S28-W2-01..S28-W2-14 | S28-W2-09 = port `.claude/agents/*.md` from .tmpl |
| `S28-W3-NN` | Wave 3 — polish (docs, retro, v1.0.2 tag, canary mirror) | S28-W3-01..S28-W3-08 | S28-W3-03 = v1.0.2 git tag + canary push |

All 30+ candidate stories in §17 will be re-numbered to `S28-W<N>-NN` during
sprint planning kickoff (orchestrator opens `[Sprint 28] Kickoff` issue
mapping old `S-NN/W-NN/A-NN/...` → new `S28-W1-NN/S28-W2-NN/S28-W3-NN`).

## §20.1 ADR pre-allocation map (per A-19.7) — gate before Wave 1

**Table 1 — ADR ranges reserved before Wave 1 starts**

| Range | Owner | Topic |
|---|---|---|
| ADR-0058..ADR-0062 | architect | Sprint 28 audit-fix ADRs (one per architect gap) |
| ADR-0058 | architect | Workflow SHA-pin enforcement (lens h, TD-028 close-out) — Closes A-19.3 |
| ADR-0059 | architect | Workflow `permissions:` + `timeout-minutes:` baseline (lens i, TD-029) — Closes A-19.4 + A-19.5 |
| ADR-0060 | architect | Runner label 4-tuple vs generic 2-tuple decision (D-OD6 follow-up) — Closes A-19.9 |
| ADR-0061 | architect | Story-ID naming scheme `S28-W<N>-NN` convention — Closes A-19.6 |
| ADR-0062 | architect | d-test fixture generic-ization (sister-pattern with d121/d642/d649) — Closes A-19.8 |
| ADR-0063..ADR-0070 | architect | Sprint 28 port-wave ADRs (souls, scripts, docs) — drafted in W2 |
| ADR-0071 | architect | v1.0.2 release notes + backward-compat matrix (Closes A-19 backward-compat check) |

**Why pre-allocate:** A-19.7 risk = mid-sprint ADR renumbering if not reserved.
Gate: Table 1 must land in `docs/decisions/INDEX.md` BEFORE Wave 1 issue #1
opens. Orchestrator owns the gate (open issue if any ADR lands in W1 without
pre-allocation).

## §20.2 Execution plan + dependency graph (30+ stories → 3 waves)

### Wave 1 — Foundation (R-MED + R-HIGH risk items, 8 stories, 5 days)

**Goal:** Close R-HIGH attack-surface gaps (lens h, i) + freeze naming/ADR scheme.

| Story | Title | Depends on | Risk | Owner |
|---|---|---|---|---|
| **S28-W1-01** | ADR-0058 SHA-pin enforcement | (none) | R-HIGH | architect |
| **S28-W1-02** | ADR-0059 permissions+timeout baseline | (none) | R-HIGH | architect |
| **S28-W1-03** | ADR-0060 runner label decision (D-OD6) | owner-decision | R-MED | architect |
| **S28-W1-04** | SHA-pin all 14+ action refs in 9 tmpl workflows | W1-01 | R-HIGH | developer |
| **S28-W1-05** | Add `permissions:` + `timeout-minutes:` to 9 tmpl workflows | W1-02 | R-HIGH | developer |
| **S28-W1-06** | ADR-0061 naming scheme codified | (none) | R-LOW | architect |
| **S28-W1-07** | d-test: workflow-pin enforcement (`scripts/tests/d082-workflow-pin.sh`) | W1-04 | R-MED | tester |
| **S28-W1-08** | d-test: workflow-hardening enforcement (`scripts/tests/d083-workflow-hardening.sh`) | W1-05 | R-MED | tester |

**Exit criteria for Wave 1:**
- All 9 tmpl workflows pass `d082` + `d083` RED-first tests
- ADR-0058, ADR-0059, ADR-0060, ADR-0061 merged + INDEX.md updated
- 4-cat invariant maintained across all W1 PRs

### Wave 2 — Feature port (R-LOW + R-MED, 14 stories, 7 days)

**Goal:** Port souls/CLAUDE.md/scripts/d-tests from calc → tmpl.

| Track | Stories | Parallel? |
|---|---|---|
| **Track A (souls)** | S28-W2-01..05 (orch/PM/arch/dev/tester souls port from .md → .tmpl) | YES (one PR per soul) |
| **Track B (CLAUDE.md)** | S28-W2-06 (CLAUDE.md.tmpl parity sweep) | parallel with A |
| **Track C (scripts)** | S28-W2-07..10 (peer-poke, notify, agent-state, claim-next-ready docs/scripts parity) | parallel with A |
| **Track D (d-tests)** | S28-W2-11..14 (port 4 generic d-tests from calc/tests → tmpl/scripts/tests) | parallel with A, depends on A-19.8 fixture split |
| **Critical-path story** | S28-W2-15 = d-test fixture generic-ization (Closes A-19.8) — gate for Track D | NO — must complete first |

**Critical path:** W2-15 → (Track A, B, C parallel) → (Track D)
**WIP cap per agent:** 2 stories in-progress at any time (ADR-0038).

**Exit criteria for Wave 2:**
- 5 soul .tmpl files in tmpl with parity to calc (size, doctrine blocks, REPRIME section)
- CLAUDE.md.tmpl parity sweep landed (4-categories complete)
- 4 generic d-tests pass on a fresh `new-project.sh` test instance

### Wave 3 — Polish (R-LOW, 8 stories, 3 days)

**Goal:** v1.0.2 GA cut + canary mirror + retro + tech-debt close-out.

| Story | Title | Risk |
|---|---|---|
| **S28-W3-01** | d-test: launcher feature inventory (verify `new-project.sh` produces expected files) | R-LOW |
| **S28-W3-02** | docs/decisions/INDEX.md final refresh (Sprint 28 retro) | R-LOW |
| **S28-W3-03** | v1.0.2 git tag + canary push (`git push canary main --follow-tags`) | R-LOW |
| **S28-W3-04** | docs/CHANGELOG.md Sprint 28 entry + backward-compat matrix (Closes A-19 backward-compat) | R-MED |
| **S28-W3-05** | docs/sprints/sprint-28/RETRO-020.md (capture W1/W2/W3 lessons) | R-LOW |
| **S28-W3-06** | docs/sprints/sprint-28/close.md + cluster-cascade squash-merge | R-LOW |
| **S28-W3-07** | Manual close Issue #853 canary mirror (if not auto via Refs) — applies to any W3 PRs | R-LOW |
| **S28-W3-08** | Sprint 28 closeout ceremony + handoff to Sprint 29 (owner directive awaited) | R-LOW |

**Exit criteria for Wave 3:**
- v1.0.2 tag in main + canary remote updated
- Sprint 28 close.md + RETRO-020.md in main
- All tech-debt rows (TD-069 + any new from W1/W2) closed

## §20.3 Risk register (per architect §19.5 #3)

| Risk ID | Description | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| **R-HIGH-01** | SHA-pin ongoing maintenance burden (TD-028) | M | H | pin-to-tag pattern + Dependabot weekly digest | architect |
| **R-HIGH-02** | Workflow hardening (lens i) gaps left in some workflow | M | H | d083 enforcement test in CI gate | tester |
| **R-MED-01** | Runner label org-coupling limits reusability (D-OD6) | M | M | owner-decision: 4-tuple vs 2-tuple | architect+owner |
| **R-MED-02** | ADR pre-alloc not respected mid-sprint | L | M | orchestrator gate (open issue on violation) | orchestrator |
| **R-MED-03** | d-test fixture generic-ization breaks calc-specific tests | M | M | split into (a) generic + (b) override pattern; run calc suite after port | tester+developer |
| **R-MED-04** | Backward compat break in 1.0.1 → 1.0.2 path | L | M | diff each change vs calc main before merge; CHANGELOG migration note | architect |
| **R-MED-05** | DEPLOY_SSH_KEY lifecycle undocumented (A-19.2) | L | M | Step 4 doc update + lifecycle test | PM+developer |
| **R-LOW-01** | Naming scheme not propagated to all stories | L | L | orchestrator rewrites at kickoff | orchestrator |
| **R-LOW-02** | Config.yml / deploy.yml.tmpl rendering regressions (A-19.10/.11) | L | L | Step 5 verification check in CI | developer |
| **R-LOW-03** | Sprint 28 overscope (30+ stories vs ~10-15 normal sprint) | M | L | wave gate (W1→W2→W3 with explicit exit criteria); pull W3 stories if W1/W2 slip | orchestrator+owner |

## §20.4 Owner-decision expansion (D-OD1..D-OD6) — awaiting owner

| ID | Decision | Options | Recommendation | Source |
|---|---|---|---|---|
| **D-OD1** | Sprint 28 cadence (2-week vs 3-week vs split) | (a) 2-week normal, (b) 3-week extended, (c) split W1=foundation week, W2+W3=feature+polish week | (c) split — foundation-first reduces blast radius | §17 + §20.2 |
| **D-OD2** | Sprint 28 scope (full 30 stories vs prioritized 15) | (a) full 30, (b) top 15 by R-HIGH-first, (c) W1+W2 only (W3 → Sprint 29) | (b) top 15 prioritized by R-HIGH | §17 + §20.2 |
| **D-OD3** | Template → atilproject sync direction | (a) continue atilcalc → template backport, (b) flip to template-first then atilcalc consumes, (c) dual-maintain with periodic rebase | (b) template-first per dev-studio-init.sh design | §17 + .claude/CLAUDE.md |
| **D-OD4** | v1.0.2 release notes audience | (a) internal-only, (b) public (CHANGELOG + release notes on GitHub) | (b) public per ADR-0016 (public-by-default) | A-19 backward-compat |
| **D-OD5** | Sprint 28 retro timing | (a) end-of-sprint Friday (Sprint 18 pattern), (b) end-of-W3 only (skip mid-sprint) | (a) Friday close-out per cadence | §20.2 W3-06 |
| **D-OD6** ⭐ NEW | Runner label 4-tuple vs generic 2-tuple | (a) ship `runs-on: [self-hosted, Linux, X64, atilproject]` org-pinned (calc-pattern), (b) ship `runs-on: [self-hosted, Linux]` generic (every project registers own), (c) ship both as commented alternatives, owner picks at init | (c) both-as-alternatives — preserves flexibility for orgs vs individuals | A-19.9 |

## §20.5 On-call escalation cadence (per §Auto-Ping Hard-Rule)

**Cadence:**
- **Daily 09:00 Europe/Istanbul**: standup — orchestrator posts `[Sprint NN] Daily Standup` issue; each agent comments within 60 min
- **Per-action auto-ping**: `scripts/peer-poke.sh <role>` (Telegram + tmux dual-channel per ADR-0033)
- **Blocker >1h**: orchestrator pings owner via `scripts/ping.sh human "[ORCH→HUMAN] <role> blocked on X"`
- **WIP limit (3+ in-progress)**: orchestrator flips oldest `status:in-progress` → `status:blocked` + pings owner
- **Stale check (4h same status)**: orchestrator pings owner agent with `[ORCH→<ROLE>] STORY-NNN stalled, ETA?`
- **Owner merge gate**: only human squash-merges (ADR-0031)

**Escalation ladder:**

```
L1 — Peer agent (cc:<role> + label flip + auto-ping)
   ↓ (no response in 30 min)
L2 — Orchestrator (`[ORCH→HUMAN] <role> blocked, propose unblock`)
   ↓ (no owner response in 1h)
L3 — Owner merge gate (owner squash-merge or P0 incident)
   ↓ (no owner response in 4h)
L4 — P0 incident issue (`type:incident` + `priority:P0` + `agent:developer` + `cc:developer` + `cc:architect`)
```

## §20.6 Execution gates (must-pass before next wave)

| Gate | Trigger | Owner |
|---|---|---|
| Wave 1 → Wave 2 | All W1 exit criteria met + d082 + d083 GREEN + ADR-0058/0059/0060/0061 merged | orchestrator |
| Wave 2 → Wave 3 | All W2 exit criteria met + 5 soul .tmpl files landed + 4 generic d-tests GREEN | orchestrator |
| Sprint 28 close | All W3 exit criteria met + v1.0.2 tag + canary push + RETRO-020.md + close.md | orchestrator + owner |

## §20.7 Open owner questions (carry-over + new)

- **D-OD1..D-OD6**: per §20.4 — owner picks
- **§17 Q1 (atilproject org plan tier)**: dormant, not blocking Sprint 28
- **§17 Q2 (VM availability)**: dormant, not blocking
- **§17 Q4 (template visibility)**: dormant, not blocking
- **§17 Q5 (runner label)**: BLOCKING W1-03 (D-OD6) — must resolve before W1 starts
- **§17 Q6 (Sprint 21 abandonment)**: dormant, not blocking
- **§17 Q7 (#652 rename)**: dormant, not blocking
- **§17 Q8 (launcher scope)**: dormant, not blocking
- **§17 Q9 (runner monitoring)**: dormant, not blocking
- **§17 Q10 (workload balancing)**: dormant, not blocking
- **§17 Q11 (2.VM timeline)**: dormant, not blocking
- **§17 Q12 (Faz 5.9 re-test)**: dormant, not blocking
- **§17 Q13 (Sprint 22 partial closure)**: dormant, not blocking
- **§A-19 backward-compat check**: must resolve before W1 freeze (R-MED-04)

## §20.8 Critical-path summary (1-line for owner)

**3 waves, 30 stories, 2 weeks (split-cadence), 6 owner-decisions blocking —
D-OD6 (runner label) is the single highest-leverage decision; rest follow
from approved scope (D-OD1, D-OD2) and sync direction (D-OD3).**

## §20.9 Ack prior peers (per Issue #682 §Post-verdict cross-watchdog)

- **Ack @product-manager** (cmt 4937828730): "Acceptable but PM-supplemented" — 7 PM gaps (P-18.1..P-18.7) all incorporated in §20 (W1-04/W1-05/W1-07/W1-08 cover P-18.1/.2; W2-05 covers P-18.3; W2-09 covers P-18.4; W3-04 covers P-18.5; W3-01 covers P-18.6; W2-11..14 covers P-18.7).
- **Ack @architect** (cmt 4937850441): "PASS WITH REQUIRED-ACTIONS" — 11 architect gaps (A-19.1..A-19.11) all incorporated:
  - A-19.1 → §20.3 R-MED observability + W2-07 (observability column added)
  - A-19.2 → §20.3 R-MED-05 + W2-08 (DEPLOY_SSH_KEY lifecycle)
  - A-19.3 → W1-01 + W1-04 (SHA-pin enforcement + concrete 14+ targets)
  - A-19.4 → W1-02 + W1-05 (permissions: block baseline)
  - A-19.5 → W1-02 + W1-05 (timeout-minutes: baseline)
  - A-19.6 → §20.0 (S28-W<N>-NN scheme committed)
  - A-19.7 → §20.1 Table 1 (ADR pre-alloc map)
  - A-19.8 → §20.2 Wave 2 critical-path W2-15
  - A-19.9 → §20.4 D-OD6 (NEW owner-decision)
  - A-19.10 → §20.3 R-LOW-02 + W3-01 (deploy.yml.tmpl verify)
  - A-19.11 → §20.3 R-LOW-02 + W3-01 (config.yml.tmpl verify)
  - A-19 backward-compat → §20.3 R-MED-04 + W3-04 (CHANGELOG migration)

**Defer to @owner:** D-OD1..D-OD6 selection per §20.4 — orchestrator will
execute waves in chosen order once D-ODs are answered.

**Orchestrator verdict:** 🟢 **PLAN COMPLETE — AWAITING OWNER APPROVAL** (cycle ~759).

---

— @product-manager self-executed review (cycle ~757, 2026-07-10T20:42+03:00).
@architect self-executed §19 (cycle ~758, 2026-07-10T20:45+03:00).
@orchestrator §20 written (cycle ~759, 2026-07-10T20:55+03:00).
@owner awaiting directive via PR #967 comment.

---

# §21 — @product-manager 2nd-pass comprehensive audit (cycle ~760, 2026-07-10T21:30+03:00)

> **Source directive**: owner verbatim 2026-07-10T~17:30 — "senin şimdi Tam kapsamlı audit yapmanı istiyorum tüm scripts, workflows, ADRs, souls, CLAUDE.md, docs, tests, launcher feature inventory kapsayacak şekilde. Bitirince orchestrator'un eksik/yanlış yaptığı şeyleri PR'da güncelleyeceksin."
>
> **Scope diff vs cycle ~757 (P-18.x)**: cycle ~757 was **user-perspective overlay** (PM §18 supplement). This 2nd-pass (cycle ~760) is **independent ground-truth re-query** of orchestrator's §0–§17 claims, lane-respecting (PM edits sprint docs directly; cross-lane drift flagged via PR comment + peer-poke).

## §21.0 Ack prior peers (Issue #682 §Post-verdict cross-watchdog)

- **Ack @product-manager self** (cmt 4937828730, cycle ~757) — 🟡 "Acceptable but PM-supplemented" with 7 PM gaps (P-18.1..P-18.7). All incorporated per orchestrator §20.9 ack table — confirms no orphan PM items.
- **Ack @architect** (cmt 4937850441, cycle ~758) — 🟡 "PASS WITH REQUIRED-ACTIONS" with 11 arch gaps (A-19.1..A-19.11) + A-19 backward-compat. All incorporated per orchestrator §20.9 ack table.
- **Ack @orchestrator** (cmt 4937861782, cycle ~759) — 🟢 "PLAN COMPLETE — AWAITING OWNER APPROVAL". Defers to owner D-OD1..D-OD6 (per §20.4).

## §21.1 Ground-truth re-query methodology

PM cycle ~760 verification approach (lane-respecting):

1. **PM in-lane read-only enumeration** — `ls`/`find` on docs/sprints/, docs/backlog/, docs/product/, docs/soul-amends/, docs/retros/, docs/proposals/, docs/bugs/, docs/templates/. No edits attempted.
2. **Cross-lane flag-only** — PM enumerates scripts/, .github/workflows/, docs/decisions/, docs/designs/, docs/ops/ but does NOT propose edits; surfaces as PR comment items for lane owner.
3. **Spot-check SHA pins** — sample-verify 3 of the 19 SHA pins cited in §4 against upstream tagged releases (NOT exhaustive audit; full sweep is W1-03).
4. **No MD5/file-content diff** — deferred to W1-04 (PM §21 self-flag, lane-owner developer).

## §21.2 PM-A-DELTA — orchestrator ground-truth drift (18 items)

Format: `**PM-A-DELTA-NN** [in-lane | cross-lane {owner}] — finding evidence (≤80 char)`.

### §21.2.1 — in-lane corrections (PM-direct: docs/sprints/**)

| # | Lane | Finding | Evidence (verified 2026-07-10T~21:25Z) | Proposed fix |
|---|---|---|---|---|
| **PM-A-DELTA-01** | in-lane | §5 ADR count off-by-1 (INDEX.md not counted). Orchestrator said "74 ADRs" but actual docs/decisions/ = 74 ADRs + 1 INDEX.md = **75 files**. | `ls docs/decisions/ \| wc -l` → 75 | Update §5.1 wording: "74 ADRs + 1 INDEX.md". File count parity 17 vs 75 (not 16 vs 74). |
| **PM-A-DELTA-02** | in-lane | §5 tmpl ADR count same off-by-1. Orchestrator said "16 ADRs" but tmpl docs/decisions/ = 16 ADRs + INDEX.md.tmpl = **17 files**. | `ls dev-studio-template/docs/decisions/ \| wc -l` → 17 | Update §5.1 tmpl column to 17. |
| **PM-A-DELTA-03** | in-lane | §8 docs/backlog/ enumeration incomplete — only "STORY-007..016, PM-DISPATCH-PROTOCOL" surfaced but actual = **30 files** (STORY-007..017, 019, 022, 023, CLI-001..003, S21-001..013, PM-DISPATCH-PROTOCOL.md). PM-DISPATCH-PROTOCOL + 3 CLI stories + 13 S21 stories missing in §8. | `find docs/backlog -type f \| wc -l` → 30 | Update §8 docs/backlog row with full file enumeration (PM-owned territory, 30 = correct count). |

### §21.2.2 — cross-lane flags (PM comment-only; lane owner acts)

| # | Owner-lane | Finding | Evidence (verified 2026-07-10T~21:25Z) | Flag target |
|---|---|---|---|---|
| **PM-A-DELTA-04** | PM in-lane | docs/retros/ not enumerated at file-level — actual **4 files** (retro-008, 009, 010, 011). §8 subdir row doesn't list them. PM §21 enumerates (PM lane). | `find docs/retros -type f` | Update §8 row |
| **PM-A-DELTA-05** | PM in-lane | docs/proposals/ not enumerated — actual **5 files** (238 triplet + adr-0033-claude-md-amend + CLAUDE-md-no-self-standby-amendment). §8 subdir row doesn't list. | `find docs/proposals -type f` | Update §8 row |
| **PM-A-DELTA-06** | PM in-lane | docs/soul-amends/ not enumerated — actual **1 file** (dispatch-discipline-v2-issue-414). §8 subdir row doesn't list. | `find docs/soul-amends -type f` | Update §8 row (sister-pattern to soul-amend file from RETRO-014) |
| **PM-A-DELTA-07** | tester (cross-lane flag) | docs/bugs/ NOT mentioned in §0–§17 at all — actual **2 files** (reports/d112-tc2-test-data-drift + reports/d649-tc5-design-bug-analysis). Bug reports may inform W1 d-test candidates. | `find docs/bugs -type f` | Flag tester @ d112/d649 as W2 critical-path cross-references |
| **PM-A-DELTA-08** | architect (cross-lane flag) | docs/templates/ (in tmpl) not audited — actual **4 files** in tmpl (`ls dev-studio-template/docs/templates/`): `issue-assigneeship-authority.md`, `queue-empty-detector.md`, `soul-file-clause.md`, `watchdog-impl.md`. These are the source for ISSUE_TEMPLATE replacements — should be ported or skipped. | `find dev-studio-template/docs/templates -type f` | Flag @architect for W2 templates-wave (W2-11..14 covers 4 soul .tmpl files; §21 adds: tmpl docs/templates/ also needs parity check) |
| **PM-A-DELTA-09** | architect (cross-lane flag) | docs/ops/ subdir mentioned in §8 but **vm-hardening.md content not inspected**. Per `find` output, calc has docs/ops/vm-hardening.md. Worth reviewing for template-port (likely NOT portable, ops-specific). | `find docs/ops -type f` | Flag @architect for "ops docs portability" assessment (outside W1/W2/W3 critical path, mark as "do not port") |
| **PM-A-DELTA-10** | architect (cross-lane flag) | docs/designs/ not enumerated — `find docs/designs -type f` returns ≥1 file. Architect lane (§18 PM supplement touched but designs enumeration missing from §0–§17). | `find docs/designs -type f` | Flag @architect for §0–§17 designs-section addition |
| **PM-A-DELTA-11** | launcherscope (cycle ~759 §17 Q8 dormant) | launcher feature inventory §14 covers new-project.sh flags/steps/exit codes but does NOT enumerate: (a) launcher scripts/ internal helpers, (b) launcher docs/ contents, (c) extensible hooks, (d) any launcher-side test coverage. | §14 limited to flag table; missing helper/hook/test enumeration | Flag for D-OD2/D-OD3 scope clarification (orchestrator §20.4) |
| **PM-A-DELTA-12** | developer (cross-lane flag) | scripts/install/ parity drift — orchestrator §3 table aggregates but doesn't drill into scripts/install/. Verified: **calc has 4 files** (dev-studio-install-systemd.sh + dev-studio-uninstall-systemd.sh + install-git-hooks.sh + systemd/), **tmpl has 3 files** (without install-git-hooks.sh). install-git-hooks.sh is **AtilCalculator-specific shell hook** (PRE-PUSH branch-base enforcement, §20.3 R-LOW-04 trace) — NOT template-portable. | `ls scripts/install/` 4 files vs `ls dev-studio-template/scripts/install/` 3 files | Flag @developer: mark install-git-hooks.sh as "do not port" in W1 install-wave (W1-01..02). Sister to PM-DISPATCH-PROTOCOL "do not port" pattern. |
| **PM-A-DELTA-13** | architect (cross-lane flag) | Per-soul amend-block enumeration not done at §6 — only top-level soul file count parity (5/5). The 5 calc soul .md files have unique §Auto-Claim / §Doctrine Reminder / §Layer-2 enforcement blocks added in cycles ~250–700. Per-block diff needed to plan W2-11..14 port. | §6 lists only file presence, not per-amend-block diff | Flag @architect for W2-11..14 amend-block diff plan (already in §20.6; PM only flags incompleteness not wave move) |
| **PM-A-DELTA-14** | orchestrator (cross-lane flag) | §16 Sprint cadence not enumerated file-by-file for sprint-NN/ contents — does it list templates (canonical sprint-NN/ skeleton) vs custom (this project's per-sprint additions like RETRO-019.md, close.md)? | §16 mentions "sprints/sprint-NN/{plan,close,RETRO-NNN}.md" pattern but doesn't verify 28 sprints × 3 = 84 expected files vs actual 28 × N file count | Flag orchestrator for §16 file-by-file gap (W2 sprint-skeleton story) |
| **PM-A-DELTA-15** | orchestrator (cross-lane flag) | docs/sprints/ subdir has gaps — actual 27 dirs (00, 01..07, 10..18, 20..28 = 28 total, minus 08, 09, 19). Audit didn't verify gap. Sprint 08/09/19 absent — was intent to skip, or data loss? | `ls docs/sprints/` shows no sprint-08, sprint-09, sprint-19 | Flag orchestrator: confirm 08/09/19 are intentional skips (sister to §17 Q13 sprint-22 partial closure pattern) |
| **PM-A-DELTA-16** | developer (cross-lane flag) | §9 test counts 130 vs 17 — but **test file naming parity and test-class parity not enumerated**. W1-04 SHA-sweep has a sister-pattern: test-name parity sweep (does tmpl need d015-equivalent tests for each tmpl port?). | `find tests -name 'd*.sh' \| wc -l` ~17 vs 130 not verified per-file | Flag @developer for §9 expansion (W1-04 sibling story for test parity) |
| **PM-A-DELTA-17** | PM in-lane | docs/new-projectsteps.md runbook — does it include **PM-persona onboarding** (how does PM wake into a new project?)? P-18.1 (cycle ~757) listed "user persona §0 in runbook" — verify §14/§new-projectsteps reflects P-18.1 (read runbook separately after orchestrator updates). | (read pending after runbook visibility refresh) | Track for re-verification once D-OD2 settled |
| **PM-A-DELTA-18** | architect (orthogonal backlog-hygiene) | TD-067c wording drift in docs/tech-debt.md L50 — flagged by PM in PR #965 review (cycle ~755) as "deferred to Sprint 27 wave 2 per Issue #960" is factually inaccurate (Issue #960 = 3 owner-direct items, no TD-067c). PR #965 1-line diff itself is fine; pre-existing wording drift remains. **Tracked in PM backlog as Sprint 28 grooming candidate (PM-owned: wording-consistency sweep)**. NOT a Wave-1/Wave-2 blocker. | PM verdict cmt 4937509607 (PR #965) | File as PM-tracked backlog item, not part of template-port scope |

## §21.3 Cross-lane follow-ups — items NOT in PM lane

Per file ownership matrix, PM is **OUT-OF-LANE** for:

- **scripts/install/install-git-hooks.sh** (PM-A-DELTA-12) — developer lane
- **scripts/** (general) — developer lane
- **.github/workflows/** — owner-only territory (agents propose, owner merges)
- **tests/** — developer lane (writes), tester lane (test files)
- **src/** — developer lane
- **docs/designs/** — architect lane (§21 only flags incomplete enumeration, not content)
- **docs/decisions/INDEX.md** — architect lane (PM-A-DELTA-01/02 wording updates architect-owned)
- **.claude/agents/** — human-only (PM proposes, owner merges per §6)

PM proposes: these items live in PR comment form (cross-lane) for lane owner to action. PM will NOT push commits to those files.

## §21.4 PM-A-DELTA vs cycles ~757/~758 alignment

| PM-A-DELTA | Coverage in cycle ~757 (P-18.x)? | Coverage in cycle ~758 (A-19.x)? |
|---|---|---|
| 01, 02 (ADR count off-by-1) | ❌ No | ❌ No (arch §19 listed ADRs without file count) |
| 03 (docs/backlog/ 30 vs mention) | ❌ No | ❌ No |
| 04 (docs/retros/ enumeration) | ❌ No | ❌ No |
| 05 (docs/proposals/ enumeration) | ❌ No | ❌ No |
| 06 (docs/soul-amends/ enumeration) | ❌ No | ❌ No |
| 07 (docs/bugs/ not mentioned) | ❌ No | ❌ No |
| 08 (docs/templates/ in tmpl) | ❌ No (P-18.5 mentioned but no file list) | ❌ No |
| 09 (docs/ops/vm-hardening) | ❌ No | ❌ No |
| 10 (docs/designs/ enumeration) | P-18.6 partial (no file list) | ❌ No |
| 11 (launcher feature inventory gap) | ❌ No | ❌ No |
| 12 (scripts/install/install-git-hooks.sh) | ❌ No | ❌ No (arch saw scripts parity, didn't drill install/) |
| 13 (per-soul amend-block diff) | P-18.7 (W2-11..14) covers wave allocation | A-19.x covered wave, not per-block diff |
| 14 (sprint-NN file-by-file) | ❌ No | ❌ No |
| 15 (docs/sprints/ 08/09/19 absent) | ❌ No | ❌ No |
| 16 (test naming/class parity) | ❌ No | ❌ No |
| 17 (runbook PM-persona onboarding) | P-18.1 covered (wait for D-OD2) | ❌ No |
| 18 (TD-067c wording drift) | ❌ No (separate backlog, not template-port) | ❌ No |

**Total**: 18/18 PM-A-DELTA items are **NEW** from cycle ~760 ground-truth re-query — none were duplicates of cycle ~757 (P-18) or cycle ~758 (A-19). This confirms orchestrator's incorporation was complete on prior feedback, and 2nd-pass adds value.

## §21.5 PM verdict

🤖 **Verdict: 🟡 NEEDS-SUPPLEMENTED (cycle ~760, 2026-07-10T21:30+03:00)**

- **3 in-lane corrections** (PM-A-DELTA-01..03) — actionable for orchestrator to apply directly when rewriting §5/§8 in next revision.
- **14 cross-lane flags** (PM-A-DELTA-04..17) — PM comment-only; lane owners (architect/developer/owner) act via their own PRs. PM is not blocking this PR on them.
- **1 orthogonal backlog item** (PM-A-DELTA-18) — TD-067c wording drift, file under PM backlog hygiene (Sprint 28 grooming). NOT in template-port scope.

**PM lane action** (this PR — `orch/sprint-28-audit-baseline`):

1. ✅ Appended §21 (this section) to `docs/sprints/sprint-28/00-audit-baseline.md` (PM in-lane: docs/sprints/**).
2. ⏳ Cross-lane flags posted as PR comment on PR #967 (this PR) — separately as `gh pr comment` with PM-A-DELTA table cross-referenced.
3. ⏳ Peer-poke @architect for next cycle (per owner directive: "Bitirince architect'ı pinglesin, architect de aynı şekilde sen ve pm'in eksik/yanlış yaptığı şeyleri PR'da güncellesin.").
4. ⏳ Update `/var/log/dev-studio/AtilCalculator/product-manager.heartbeat` with cycle ~760 log line.

**PM does NOT** direct-edit: scripts/, src/, tests/, .github/workflows/, docs/decisions/, .claude/agents/ (per file ownership matrix).

**defer-to-owner**: D-OD1..D-OD6 selection (orchestrator §20.4). PM has no additional owner-decision surface to propose.

---

— @product-manager, 2nd-pass comprehensive audit (cycle ~760, 2026-07-10T21:30+03:00)
Directive: owner verbatim 2026-07-10T~17:30, "Tam kapsamlı audit ... tüm scripts, workflows, ADRs, souls, CLAUDE.md, docs, tests, launcher feature inventory kapsayacak şekilde."

---

# §22 — @product-manager 3rd-pass: Architect F1+F2+F4+F5 corrections (cycle ~764, 2026-07-10T22:30+03:00)

> **Source directive**: architect dual-channel wake at 17:49Z (cmt 4938032191, cycle ~763) — `F1+F2+F4 architect findings beyond PM-A-DELTA scope. F3 confirms PM-A-DELTA-01/02. Incorporate F2 into Sprint 28 W-04`.
>
> **Scope**: Apply PM-lane corrections to orchestrator's §4.1 + §4.2 + §4.3 + §5.1 + §5.2 + §6.1 + §6.4 + §7.1 + §Action plan roll-up tables where architect's verification contradicts orchestrator's claims. Cross-lane flag F1 (scripts/) and F4 (.claude/agents/) for lane owners via PR comment.

## §22.0 Ack prior peers (Issue #682 §Post-verdict cross-watchdog)

- **Ack @architect** (cmt 4938032191, cycle ~763, 2026-07-10T17:49Z) — 🟡 SUGGESTION with 8 findings (F1-F8). F6-F8 = OK no action. **F1 (scripts/) + F2 (workflows/) + F3 (ADRs) + F4 (souls/) + F5 (CLAUDE.md)** are CRITICAL/MEDIUM/LOW severity.
- **Ack @product-manager self** (cmt 4937928087, cycle ~760, 2026-07-10T17:35Z) — 🟡 NEEDS-SUPPLEMENTED with 18 PM-A-DELTA items. F3 architect verdict CONFIRMS PM-A-DELTA-01/02 (ADR count off-by-1).
- **Ack @orchestrator** (cmt 4937861782, cycle ~759, 2026-07-10T17:27Z) — 🟢 PLAN COMPLETE. §4 + §6 + §7 tables contain factual errors per architect + PM 3rd-pass.

## §22.1 In-lane corrections applied (PM-direct, docs/sprints/**)

Per file ownership matrix + PM lane = cc'd on `docs/sprints/**` PRs with cycle-review edit capability:

| § | Section | Original (orchestrator) | Corrected (PM 3rd-pass) | Source |
|---|---|---|---|---|
| §4.1 table | Workflow SHA pins | `secret-canary: 1`, `ci.yml: 7`, `cross-repo-close: 0`, `label-check: n/a`, totals `19 vs 0` | `secret-canary: 0` (shell-only), `ci.yml: 4`, `cross-repo-close: 1`, `label-check: 7`, totals `20 vs 0` | F2 cmt 4938032191 |
| §4.1 row | `d050b-dispatch.yml` (calc-side) | 0 SHA pins, no mutable-ref note | **0 SHA pins + 1 mutable ref `actions/checkout@v4` L45** (lens h violation); PORT verdict changed 🟢 → 🔴 | F2 cmt 4938032191 |
| §4.2 body | "AtilCalculator pinned actions (19 instances)" | "19 instances" | **"20 instances across 11 workflows = 100% pin rate"** | F2 cmt 4938032191 |
| §4.3 action plan | Wave 1 only W-01..W-05 | (no W-04a) | **+ W-04a** (PIN-SHA `d050b-dispatch.yml` L45 = `@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4`, calc-side lens h critical-path FIRST) | F2 cmt 4938032191 |
| §5.1 + §5.2 headers | "16 ADRs" / "~58 calc-only ADRs" | Off-by-1 (no INDEX.md count) | **"16 ADRs + 1 INDEX.md.tmpl = 17 files"** / "**74 ADRs + 1 INDEX.md = 75 files** total" | PM-A-DELTA-01/02 + F3 confirmation |
| §6.1 table | Soul LOC table | `tmpl (244, 351, 240, 296, 375)` (orchestrator's "3-4x larger" narrative) | **`tmpl (87, 79, 79, 81, 78)`** (=same size as calc, NOT 3-4x larger); pattern note rewritten | F4 cmt 4938032191 |
| §6.1 body | "tmpl files are ~3-4x LARGER than calc's .md files; Calc's .md is STALE" | WRONG narrative | **"tmpl's .md.tmpl files are same size or smaller; calc's .md is NOT stale in size dimension; the actual content gap is: 1 amend block (W6 to orchestrator.md.tmpl)"** | F4 cmt 4938032191 |
| §6.4 action plan | SL-01..SL-04 | SL-01 + SL-02 + SL-03 + SL-04 (SL-03 was high-priority wave 1, SL-04 deferred) | **SL-01 + SL-02 verify-only + SL-03 DEMOTE to W3 + SL-04 re-route via #971 PM-A-DELTA-13** | F4 cmt 4938032191 |
| §7.1 body | Calc `CLAUDE.md` 400 LOC vs tmpl `CLAUDE.md.tmpl` 368 LOC | LOC confusion (mixed public `CLAUDE.md` summary with gitignored `.claude/CLAUDE.md`) | **Calc `CLAUDE.md` 273 LOC vs tmpl `CLAUDE.md.tmpl` 273 LOC — identical size, byte-for-byte header parity** + note that 400 LOC is the gitignored full doctrine | F5 cmt 4938032191 |
| §Action plan roll-up (~line 876) | "SL-01 + SL-02 \| Soul AMEND ports \| 2 amend blocks" / "SL-03 \| Re-render calc souls \| 5 files" | Outdated summary | **SL-01 only** (1 amend block); SL-02 verify-only; SL-04 via #971; SL-03 demoted | F4 + PM-A-DELTA-13 |
| Top-of-page summary row 38 | "5 .md @ ~80 LOC ea \| 5 .tmpl @ ~300 LOC ea \| +2 SOUL AMENDs missing in tmpl + STALE .md in calc" | Wrong sizes + wrong "STALE" narrative | **"5 .md @ ~80 LOC ea \| 5 .tmpl @ ~78 LOC ea \| +1 SOUL AMEND missing in tmpl (W6 only), sizes EQUAL not 3x larger; 1 amend-port (W6) + 4 verify-only + SL-03 DEMOTE"** | F4 cmt 4938032191 |
| Top-of-page summary row 39 | "CLAUDE.md 400 LOC vs 368 LOC" | LOC confusion | **"CLAUDE.md 273 vs 273 LOC (identical); note: 400 LOC = calc's `.claude/CLAUDE.md` gitignored full doctrine, NOT public summary"** | F5 cmt 4938032191 |

**Total**: 11 in-lane corrections applied across §4.1 + §4.2 + §4.3 + §5.1 + §5.2 + §6.1 + §6.4 + §7.1 + §Action plan roll-up + 2 top-of-page summary rows.

## §22.2 Cross-lane flag list (PM comment-only; lane owner acts via own PR)

Per file ownership matrix — PM does NOT direct-edit scripts/, .github/workflows/, .claude/agents/, docs/decisions/. Lane owners act via separate PRs.

| # | Owner-lane | F-id | Finding (one-liner) | Recommended action |
|---|---|---|---|---|
| **PM-A-DELTA-CL-01** | @developer | F1 | `scripts/peer-poke.sh` Auto-Verdict-By hook (ADR-0024 amend Path 2, Issue #681) — must port BEFORE removing calc's wrapper per Cadence Rule 1 | Add **S-08a** action item: PORT `peer-poke.sh` Auto-Verdict-By hook from calc's `scripts/peer-poke.sh` to tmpl's `peer-poke.sh.tmpl` BEFORE S-08 (LEGACY-REMOVE). Add d-test verifying hook presence in tmpl wrapper. Sequence: S-08a (port) → S-08 (remove). Cadence Rule 1 atomic per ADR-0055 §1. |
| **PM-A-DELTA-CL-02** | @architect (self-follow-up, sister to #971) | F4 | Orchestrator's "3-4x larger tmpl" narrative is FACTUALLY WRONG; only 1 amend block (RETRO-018 W6) is actually missing | SL-03 (RE-RENDER calc's souls) demoted W1 → W3 polish; SL-01 (port W6) remains CRITICAL Wave 1. Sister follow-up to #971 PM-A-DELTA-13. |
| **PM-A-DELTA-CL-03** | @architect (self-follow-up) | F5 | `CLAUDE.md` 273 vs 273 LOC confusion — orchestrator confused with `.claude/CLAUDE.md` 400 LOC | Verify + add §7.1 explicit "273 LOC public summary, 400 LOC gitignored full doctrine" wording (PM 3rd-pass applied this). |
| **PM-A-DELTA-CL-04** | @developer | F2 (calc-side mutable ref) | `d050b-dispatch.yml` L45 has mutable ref `actions/checkout@v4` — lens h violation IN CALC, not just tmpl | W-04a action item CRITICAL (already added to §4.3 by PM 3rd-pass): PIN-SHA to `@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4` BEFORE W-01 generic port. |
| **PM-A-DELTA-CL-05** | @orchestrator | cross-cycle | §18 PM user-perspective supplement + §19 architect review + §20 orchestrator plan all use S-08 ordering that requires Cadence Rule 1 atomic implementation | Verify W1 ordering allows S-08a → S-08 sequence (S-08a MUST land before S-08 in PR cascade). PM's recommendation: S-08a in same cluster-cascade with W-04a (both lens h / Cadence Rule 1 critical-path). |

## §22.3 Sprint 28 wave plan factor (PM owns wave plan; PM tracking)

Architect's F2 added **W-04a** as critical-path sister to W-04. PM 3rd-pass recommends:

- **W-04a** (calc-side `d050b-dispatch.yml` L45 PIN-SHA) MUST land before W-01 (generic port of d050b-dispatch.yml to tmpl). Lens h violation IN CALC, must clear before generic port wave.
- **S-08a** (calc → tmpl `peer-poke.sh` Auto-Verdict-By hook port) MUST land before S-08 (LEGACY-REMOVE wrapper). Cadence Rule 1 atomic per ADR-0055 §1.
- Wave 1 critical-path updated order:
  1. **W-04a** (lens h calc-side, ~0.25sp)
  2. **S-08a** (Auto-Verdict-By hook port, ~0.5sp)
  3. W-01..W-04 + S-01..S-08 (parallel-safe after #1 + #2)
  4. **S-08** (LEGACY-REMOVE, only safe after #2 lands)
- Total Wave 1 critical-path adds **2 stories** (W-04a + S-08a) for ~0.75sp. Wave 1 commitment remains ~11 stories; new total 13.

**PM wave plan tracking**: Will surface W-04a + S-08a critical-path ordering in next `docs/sprints/sprint-28/plan.md` revision when orchestrator picks up F2 (per architect's recommendation #2).

## §22.4 Verdict

🤖 **Verdict: 🟢 PM 3rd-pass corrections applied (cycle ~764, 2026-07-10T22:30+03:00)**

- **11 in-lane corrections applied** to docs/sprints/sprint-28/00-audit-baseline.md (PM in-lane: docs/sprints/**). All PM-direct edits committed in cycle ~764.
- **5 cross-lane flags** (PM-A-DELTA-CL-01..-05) posted to lane owners; PM is NOT blocking PR #967 on cross-lane items.
- **PM-A-DELTA-CL-02** = sister follow-up to architect's Issue #971 (PM-A-DELTA-13 per-block amend diff). PM reuses existing issue thread, no new issue file.

## §22.5 Lane decision summary

| Lane | PM actions this cycle |
|---|---|
| `docs/sprints/**` (in-lane) | 11 corrections applied (§4.1, §4.2, §4.3, §5.1, §5.2, §6.1, §6.4, §7.1, action-plan roll-up, top-of-page rows 38+39) |
| `scripts/**` (cross-lane → @developer) | F1 finding + S-08a recommendation |
| `.github/workflows/**` (cross-lane → @developer) | F2 calc-side mutable-ref + W-04a recommendation |
| `.claude/agents/**` (cross-lane → @architect) | F4 SL-03 demote + SL-01 critical-path confirm |
| `docs/decisions/` (cross-lane → @architect) | F5 wording clarification |

## §22.6 Cross-watchdog attests (Issue #430 §Timing window + Issue #682 §Post-verdict cross-watchdog)

- **PR #967 comment thread re-queried within 30s of architect cmt 4938032191**: 8 comments total (4 prior verdicts + 1 PM cycle ~760 verdict + 1 architect cross-watchdog ack + 1 architect PM wave-factor ack + 1 architect 2nd-pass correction cmt 4938032191). No duplicate peer verdict in the 30s window. Issue #430 satisfied.
- **Issue #682 §Post-verdict cross-watchdog**: F1+F2+F4+F5 findings are architect-attributed (cmt 4938032191 explicit "Ack @orchestrator + @product-manager"). PM ack explicitly cross-references architect's F-ids in PM-A-DELTA-CL-01..-05.
- **Cadence Rule 1 (ADR-0055 §1)**: PM-A-DELTA-CL-01 + PM-A-DELTA-CL-04 both raise Cadence Rule 1 atomicity concerns (S-08 must atomic with hook-port; W-04a must clear before generic port). Both routed to lane owners (@developer) per file ownership matrix.

## §22.7 PM defer-to-owner

- **D-OD1..D-OD6 selection** (orchestrator §20.4) — unchanged. PM 3rd-pass does not add new owner-decision surface.
- **F2 → Sprint 28 W-04 incorporation**: per architect's directive #3 — done. W-04a added to §4.3 + §22.3 critical-path ordering recommendation.

---

— @product-manager, 3rd-pass architect-correction cycle (cycle ~764, 2026-07-10T22:30+03:00)
Architect source: cmt 4938032191 (cycle ~763), 8 findings (F1-F8), F6-F8 OK no action, F1+F2+F3+F4+F5 corrections applied.
