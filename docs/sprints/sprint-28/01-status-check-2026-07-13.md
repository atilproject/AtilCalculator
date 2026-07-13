# Sprint 28 Status Check — template + launcher audit (cycle ~1153, 2026-07-13)

> **Owner directive (2026-07-13T05:44Z, cycle ~1153):** "Bir kaç sorum var — sırasıyla
> cevapla. Kararlar birlikte alınacak — bu audit sadece durum tespiti, ben okumadan
> hiçbir aksiyon alma. Cevabı bir dosya olarak repo'ya PR aç, chat'te sadece PR linki
> + özet."
>
> **Scope:** Status check ONLY. No action taken without owner ratification.
> **Sources:** `gh api` REST queries (rate-limit safe) + `docs/sprints/sprint-28/00-audit-baseline.md`
> (already merged via PR #967) + local repo files. REST bucket has 4500+ remaining;
> GraphQL exhausted (deferred).
>
> **Read alongside:** [00-audit-baseline.md](00-audit-baseline.md) (the comprehensive
> Sprint 28 audit, merged 2026-07-10). This doc is a **delta check** as of 2026-07-13.

---

## §0 TL;DR — owner questions (Q1-Q7) at a glance

| # | Owner question | Status | Verdict |
|---|---|---|---|
| Q1 | Template ready to launch as a private project in atilproject org? | 🟡 PARTIAL | Org + 8 self-hosted runners + `--private` flag exist. Missing: R-01 (runs-on migration), W-04 (SHA pinning), owner Actions billing confirmation, e2e private dry-run |
| Q2 | All AtilCalculator scripts/processes/doctrines/agents ported to template? | 🟡 ~45-55% parity (improving) | At audit time (~7/10): 35-45%. Souls amended 0/5 → now 3/5 (RETRO-018 W6 + Issue #389 + Issue #414 landed 2026-07-11). Other categories unchanged since audit |
| Q3 | Self-hosted runner migration 100% complete? | ✅ AtilCalculator: 100% / ❌ Template: 0% | AtilCalculator all 11 workflows self-hosted. Template all 7 non-`.tmpl` workflows STILL on `ubuntu-latest`. **R-01 NOT YET LANDED on template.** Org has 8 self-hosted runners registered (online, idle) |
| Q4 | What could be added to template (scope expansion)? | 📋 Listed | `pyproject.toml.tmpl`, `RUNNER-SETUP.md`, retro/story templates, soul-amend template. ~6 candidate stories (Q-04..Q-09) per §Action plan roll-up |
| Q5 | Is dev-studio-launcher still ready? | 🟡 YES-BUT (stale) | `b0d820d` (2026-06-17), no `v0.3.0` tag (only `v0.2.0`), no pre-flight for `--private` + no Actions billing step, no `RUNNER-SETUP.md`. Functional flags work, but L-01 (tag) + L-02 (pre-flight) + L-03 (RUNNER-SETUP) pending |
| Q6 | new-projectsteps runbook | ✅ DELIVERED (refresh recommended) | `docs/new-projectsteps.md` exists (14488 bytes, 404 lines, 2026-07-10). Has 10-step detailed process. **Drift:** still references `atilcan65/dev-studio-launcher` URL (line 396) and stale HEADs (template 81ec0b1 — actual 43592c2; launcher b0d820d — unchanged) |
| Q7 | Is 1.0.1 + necessary work really complete? | 🟡 PARTIAL launcher / ❌ INCOMPLETE template | Template `v1.0.1` tag exists at SHA `81ec0b1` (Jun 2026 stamp). **But** template HEAD has moved past `v1.0.1` (current `43592c2`, 2026-07-11) without a new tag. Feature parity still ~45-55%. Launcher `v0.3.0` tag NOT YET CREATED (commit message says "v0.3" but no tag — highest tag is `v0.2.0`) |

---

## §1 Evidence — REST API queries (cycle ~1153)

### 1.1 Org: `atilproject` (not `atilcan65`)

| Resource | Value | Source |
|---|---|---|
| AtilCalculator remote | `https://github.com/atilproject/AtilCalculator.git` | `git remote get-url origin` |
| Canary remote | `https://github.com/atilproject/dev-studio-template-smoke.git` | `git remote get-url canary` |
| Owner token scopes | `admin:enterprise, admin:org, repo, project, workflow, write:network_configurations` | `gh auth status` |
| Org ID | `297704630` | `gh api /orgs/atilproject` |

> **Drift noted:** `CLAUDE.md` (this repo's project doctrine) still references
> `github.com/atilcan65/AtilCalculator` in some places. **d095**
> (`scripts/tests/d095-post-org-migration-clone-urls.sh`) covers the URL
> migration. Status: **not fully verified** for this repo's `CLAUDE.md` content
> in this status check — defer to a follow-up audit cycle.

### 1.2 Template: `atilproject/dev-studio-template`

| Field | Value | Source |
|---|---|---|
| Visibility | `public` | `gh api /repos/atilproject/dev-studio-template` |
| License | `null` (no LICENSE file) | same |
| `is_template` | `true` | same |
| Created | `2026-06-12T14:21:57Z` | same |
| HEAD commit | `43592c2` (2026-07-11T08:57:33Z) | `gh api /commits` |
| Latest tag | `v1.0.1` at SHA `81ec0b1` | `gh api /tags` |
| Open issues | 0 | same |
| Default branch | `main` | same |

**Soul AMEND state (template, 2026-07-13):**

| Block | Landed on template? | Commit |
|---|---|---|
| RETRO-018 W6 amend | ✅ YES | PR #64 (S28-001) |
| Issue #389 amend | ✅ YES | PR #66 (S28-002) |
| Issue #414 amend | ✅ YES | PR #67 (S28-004) |
| PM/arch/dev/tester amend blocks | ❓ Not verified in this delta (deferred to follow-up) | — |

> **Compared to audit-baseline §17 Q2 (2026-07-10):** audit said "Souls: 0/5
> AMEND blocks PARITY (0%)". As of 2026-07-13, orchestrator.md.tmpl has 3/3
> amend blocks for orchestrator role. **Parity improved for orchestrator
> specifically.** Other 4 roles (PM/arch/dev/tester) — not re-audited in this
> delta check.

**Workflow `runs-on:` state (template, 2026-07-13):**

| Workflow | runs-on | Source |
|---|---|---|
| `label-check.yml` | `ubuntu-latest` | `gh api /contents/.github/workflows/label-check.yml` (raw) |
| `status-label-to-board.yml` | `ubuntu-latest` | same |
| `ai-pr-review.yml` | `ubuntu-latest` | same |
| `ci.yml` | `ubuntu-latest` (×2 — duplicate file) | same |
| `label-cleanup.yml` | `ubuntu-latest` | same |
| `secret-canary.yml` | `ubuntu-latest` | same |
| `cross-repo-close.yml` | `ubuntu-latest` | same |
| `deploy.yml.tmpl` | (rendered with self-hosted — not directly verified) | `.tmpl` extension |

**SHA pinning (template):** ⚠️ **NONE** — all `uses: actions/*@v4` (mutable tags). Same
finding as audit-baseline §4.2 (W-04 surfacing).

### 1.3 Launcher: `atilproject/dev-studio-launcher`

| Field | Value | Source |
|---|---|---|
| Visibility | `public` | `gh api /repos/atilproject/dev-studio-launcher` |
| License | MIT | same |
| `is_template` | `false` | same |
| Created | `2026-06-14T09:19:33Z` | same |
| Pushed | `2026-06-17T06:49:34Z` (~26 days dormant) | same |
| HEAD commit | `b0d820d` (2026-06-17) | `gh api /commits` |
| Latest tag | `v0.2.0` at SHA `49b9e7c` | `gh api /tags` |
| `v0.3.0` tag | ❌ **NOT created** | same |
| File count | 4 (`.gitignore`, `LICENSE`, `README.md`, `new-project.sh`) | `gh api /contents/` |

> **Drift noted (commit message vs reality):** commit `b0d820d` is titled
> `feat(v0.3): public-by-default visibility, --private opt-in (ADR-0016) (#2)`.
> The commit message says "v0.3" but **no git tag `v0.3.0` exists**. The
> audit-baseline §14.6 / L-01 already flagged this. **Confirmed still unfixed.**

### 1.4 Self-hosted runners (org-level)

| Runner | OS | Status | Labels | Busy |
|---|---|---|---|---|
| `github-runner-vm` | Linux | online | `[self-hosted, Linux, X64, atilproject]` | false |
| `github-runner-vm-2` | Linux | online | same | false |
| `github-runner-vm-3` | Linux | online | same | false |
| `github-runner-vm-4` | Linux | online | same | false |
| `github-runner-vm-5` | Linux | online | same | false |
| `github-runner-vm-6` | Linux | online | same | false |
| `github-runner-vm-7` | Linux | online | same | false |
| `github-runner-vm-8` | Linux | online | same | false |

**Total: 8/8 self-hosted runners online + idle. Org-level registration.
AtilCalculator flows into these (verified by 100% self-hosted migration per
audit-baseline §15.1).** Template workflows would also flow here IF they used
`runs-on: [self-hosted, Linux, X64, atilproject]` — they don't, yet.

**Implication for Q3 owner concern:** "Self-hosted runner'a geçiş 100% tamamlandı mı?
private repo açacağımızdan self hosted runner dışındaki runner'lar limitli olacak ondan
self hosted runner'ımızı kullanması gerek?"

- ✅ **Org-level self-hosted runners: 100% ready** (8 runners, online, idle, 4-tuple labels)
- ✅ **AtilCalculator self-hosted migration: 100%** (11/11 workflows self-hosted)
- ❌ **Template self-hosted migration: 0%** (7/7 non-`.tmpl` workflows on `ubuntu-latest`)

**Conclusion:** If owner opens a NEW private project TODAY using the launcher with
`--private` flag, that project's workflows will run on `ubuntu-latest` (Actions
minutes billed). **R-01 migration to template is BLOCKING for `--private` use case.**

---

## §2 Per-question detail (Q1-Q7)

### Q1 — Is dev-studio-template ready to launch as a private project?

**Verdict: 🟡 PARTIAL.** (Same as audit-baseline §17 Q1 — delta has not improved
this verdict materially because R-01 + W-04 are still pending.)

**What works:**
- ✅ Org `atilproject` exists, owner-only membership
- ✅ Launcher `--private` flag exists (since `b0d820d`)
- ✅ Template structure intact (`.claude/`, `scripts/`, `.github/workflows/`, etc.)
- ✅ 8 self-hosted runners org-level, all online + idle
- ✅ AtilCalculator's self-hosted pattern proven (`[self-hosted, Linux, X64, atilproject]`)
- ✅ PROJECT_TOKEN canary script exists (`secret-canary.yml`)

**What blocks "ready for private" verdict:**
- ❌ Template workflows on `ubuntu-latest` (R-01) — will burn Actions minutes
- ❌ No SHA pinning on template workflows (W-04) — supply-chain mutable refs
- ❌ Owner Actions billing on atilproject org: **UNKNOWN** (need `gh api /orgs/atilproject/settings/billing/actions` to verify — not run in this delta)
- ❌ E2E private dry-run: **NOT RUN** (audit-baseline §Knowledge gaps)
- ❌ No `RUNNER-SETUP.md` in template (L-03 pending) — owner has no docs to register runner for a NEW private project

**Required to call "ready" (per audit-baseline §17 Q1):**
1. R-01 (8/9 template workflows → self-hosted)
2. R-02 (ADR for self-hosted default)
3. W-04 (SHA pin all actions refs)
4. L-03 (RUNNER-SETUP.md guide)
5. Owner Actions billing confirmation (D-OD1)
6. E2E private dry-run with PROJECT_TOKEN

### Q2 — All AtilCalculator scripts/processes/doctrines/agents ported to template?

**Verdict: 🟡 ~45-55% parity** (improved from audit-baseline's 35-45% by 3
orchestrator soul amend ports).

**Delta since 2026-07-10 audit:**
- ✅ Orchestrator.md.tmpl: 3 amend blocks ported (RETRO-018 W6, Issue #389, Issue #414)
- ✅ S28-005 re-render landed (PR #995) — `.claude/agents/orchestrator.md.tmpl` re-rendered into AtilCalculator
- ✅ S28-008 LEGACY-REMOVE landed (PR #992) — `peer-poke.sh` symlink + `ping.sh` deletion
- ✅ S28-006 ADR pre-allocation landed (PR #68) — ADR-0058..0071 reserved

**NOT improved since 2026-07-10:**
- Scripts parity: 12/38 PARITY (32%) per audit §3.1 — no progress visible in this delta
- Workflows parity: 8/11 PARITY (73%) per audit §4.1 — R-01 NOT LANDED on template
- ADRs parity: 16/74 PARITY (22%) per audit §5.1 — A-01 (28 ADR port wave) NOT STARTED
- Tests parity: 13/130 PARITY (10%) per audit §9 — T-01/T-02 NOT STARTED
- Launcher: 5/6 PARITY (83%) per audit §14 — L-01 (tag), L-02 (pre-flight), L-03 (RUNNER-SETUP) all pending

**Detailed gap clusters** (per audit-baseline §3-§9 tables, NOT RE-AUDITED in this delta):
- `scripts/agent-watch.sh` 1039 LOC drift (S-10, wave 3)
- 28 ADRs to port (A-01, wave 2)
- 71+ d-tests to port (T-01 + T-02, wave 2)
- Soul AMEND blocks for PM/arch/dev/tester (SL-04 per audit §22.9 — not visible in template yet)

### Q3 — Self-hosted runner migration 100% complete?

**Verdict:**
- ✅ **AtilCalculator: 100% (11/11 workflows)** — confirmed by audit-baseline §15.1
- ✅ **Org-level runners: 8/8 online + idle** — confirmed by `gh api /orgs/atilproject/actions/runners` 2026-07-13
- ❌ **Template: 0% (0/7 non-`.tmpl` workflows)** — confirmed by raw workflow inspection 2026-07-13

**Owner's concern (verbatim):** "private repo açacağımızdan self hosted runner dışındaki
runner'lar limitli olacak ondan self hosted runner'ımızı kullanması gerek? 100% her
şey çalışıyor değil mi self hosted runner ile, diğer runner aktif kalınca limite
vuracak."

**Answer:** Org-level runners are 100% ready + idle. AtilCalculator is 100% migrated.
**Template is NOT migrated** — but **template is NOT yet in production for any
private project** (only smoke test on `dev-studio-template-smoke`, which is public).
So today there is NO active Actions billing risk from template's `ubuntu-latest`.

**Tomorrow's risk:** As soon as owner runs `new-project.sh --private <name>`, the
new project's workflows will run on `ubuntu-latest`. With org-level self-hosted
runners available, this is wasted Actions minutes (double payment). **R-01 is the
corrective action.**

**Caveat on "100% çalışıyor mu" — known unknowns:**
- Template's `deploy.yml.tmpl` uses `runs-on:` field — raw content not inspected in this delta. Audit-baseline §15.1 noted it as "generic" (presumed self-hosted after render).
- `actions/checkout@v4`, `actions/setup-node@v4`, etc. on ubuntu-latest will run, just billed.
- 8 runners org-level is capacity-overprovisioned; 1-2 would suffice for org-wide private projects.

### Q4 — What could be added to template (scope expansion)?

**Verdict: 📋 Listed** (per audit-baseline §17 Q4 + §Action plan roll-up wave 3).

**Beyond Q2/Q3 gaps:**
- `pyproject.toml.tmpl` — placeholder for project-specific tech-stack rendering (audit-baseline §12 noted as "maybe a small gap")
- `RUNNER-SETUP.md` (L-03) — post-init guide for self-hosted runner registration per new project
- `docs/templates/RETRO-NNN.template.md` — retro-writing pattern (template's role: provide patterns)
- `docs/templates/STORY-XXX-tests.template.md` — test plan convention
- `docs/templates/SOUL-AMEND-proposal.template.md` — soul-amend proposal format
- `docs/templates/ISSUE_TEMPLATE/index.md.tmpl` — consolidating ISSUE_TEMPLATE behavior

**~6 candidate stories (Q-04..Q-09)** per audit-baseline §Action plan roll-up wave 3:
- Q-04: pyproject.toml.tmpl
- Q-05: RUNNER-SETUP.md
- Q-06..Q-09: TBD (audit-baseline §Knowledge gaps admits "full audit would take 2-3 more cycles")

**Sprint scope decision (D-OD5):** "Sprint 28 = pure gap-closure, or include 1-2 new features?"
— **AWAITING OWNER DECISION.**

### Q5 — Is dev-studio-launcher still ready?

**Verdict: 🟡 YES-BUT (stale).**

**What works (verified 2026-07-13):**
- ✅ `new-project.sh` (10386 bytes, 4 files in repo: `.gitignore`, `LICENSE`, `README.md`, `new-project.sh`)
- ✅ `--public` / `--private` flags (since commit `b0d820d`)
- ✅ `--owner`, `--dir`, env var overrides (`$DEV_STUDIO_HOME`)
- ✅ 6 distinct exit codes (0/1/2/3/4/5/6) per audit-baseline §14.5
- ✅ 4 explicit steps performed: gh repo create + clone + dev-studio-init + bootstrap-labels

**What's stale:**
- ❌ No `v0.3.0` tag (commit message says "v0.3", but highest tag is `v0.2.0`)
- ❌ Last push 2026-06-17 (~26 days dormant; not stale per se, but no tag = no version pin)
- ❌ No pre-flight check for `--private` + no Actions billing step (L-02 pending)
- ❌ No `RUNNER-SETUP.md` guide (L-03 pending)

**Drift note:** One commit message (`b0d820d`) cites `atilcan65/dev-studio-template`
in URL — should be `atilproject/dev-studio-template` post-org-migration. **d095
d-test covers this** but commit history may not have been re-written.

### Q6 — new-projectsteps runbook

**Verdict: ✅ DELIVERED (refresh recommended).**

**Current state:** `docs/new-projectsteps.md` exists in this repo (14488 bytes,
404 lines, written 2026-07-10 22:15). It is **delivered as part of PR #967
(audit-baseline)**, per §17 Q6.

**Drift detected in this delta:**
| Line | Current text | Correct value (as of 2026-07-13) |
|---|---|---|
| Line 8 | "Template HEAD = `81ec0b1` (tag `v1.0.1`)" | Template HEAD = `43592c2`; tag `v1.0.1` still at `81ec0b1` (no new tag) |
| Line 8 | "Launcher HEAD = `b0d820d` (no v0.3.0 tag yet)" | ✅ still correct |
| Line 396 | `https://github.com/atilcan65/dev-studio-launcher` | `https://github.com/atilproject/dev-studio-launcher` |
| Line 169-216 | "Self-hosted runner — Section references audit Q3" | Audit-baseline §15 confirms R-01 NOT YET LANDED — `RUNNER-SETUP.md` (L-03) still pending |

**Recommendation:** Refresh `docs/new-projectsteps.md` in a follow-up PR. Mark
as **docs/audit lane (PM/arch cc)** not scripts lane.

### Q7 — Is 1.0.1 + necessary work really complete?

**Verdict: 🟡 PARTIAL launcher / ❌ INCOMPLETE template.**

**Template:**
- ✅ `v1.0.1` tag exists at SHA `81ec0b1` (legacy stamp from earlier cycle)
- ✅ Template HEAD has advanced to `43592c2` (2026-07-11) with 3 soul amend ports + ADR pre-allocation
- ❌ **No `v1.0.2` (or similar) tag** for post-amend work
- ❌ Feature parity still ~45-55% (per Q2 above)

**Launcher:**
- ✅ `v0.2.0` tag exists at SHA `49b9e7c` (initial + parent-dir change)
- ❌ Commit `b0d820d` says "v0.3" but no `v0.3.0` tag — **L-01 PENDING**
- ❌ No pre-flight for `--private` (L-02 PENDING)
- ❌ No RUNNER-SETUP.md guide (L-03 PENDING)

**Necessary work remaining** (per audit-baseline §17 Q7):
1. R-01 (8 workflow runs-on migrations on template)
2. R-02 (ADR for self-hosted default)
3. W-04 (SHA pin ~14+ action refs)
4. A-01 (28 ADR port wave)
5. T-01 + T-02 (~71 d-test port wave)
6. S-01..S-12 (script ports + LEGACY removes)
7. SL-01..SL-04 (soul amend blocks for non-orchestrator roles)
8. L-01..L-03 (launcher v0.3.0 tag + pre-flight + RUNNER-SETUP)
9. D-01..D-03 (pattern-port templates)
10. Q-04..Q-09 (template scope expansion)

**Total: ~30 stories (per audit-baseline §Action plan roll-up)**

---

## §3 Knowledge gaps declared (bilmiyorum)

Per audit-baseline §Knowledge gaps convention. This delta check did not re-run:
- **E2E private dry-run** — would need owner-confirmed Actions billing + scratch repo
- **SHA pin count delta** — template workflows still use `@v4` tags but exact count not enumerated
- **PM/arch/dev/tester soul AMEND state on template** — only orchestrator verified
- **Owner Actions billing on atilproject org** — `gh api /orgs/atilproject/settings/billing/actions` not called (billing scope may need re-auth)
- **`deploy.yml.tmpl` runs-on rendered output** — `.tmpl` extension, rendered by `dev-studio-init.sh`; raw inspect skipped
- **SHA of `dev-studio-template-smoke`** — canary remote exists but not cloned locally for diff

These are all `bilmiyorum` — would need follow-up cycles.

---

## §4 Recommended action plan (owner ratification pending)

### 4.1 Owner-decisions required (D-OD1..D-OD5)

Per audit-baseline §Action plan roll-up. **NOT RATIFIED in this status check — defer to owner.**

| ID | Decision | Status |
|---|---|---|
| D-OD1 | Actions billing limit on atilproject org? (Free / Paid / N/A?) | 🟡 UNKNOWN — verify via `gh api /orgs/atilproject/settings/billing/actions` |
| D-OD2 | Template default visibility = public (ADR-0016), or flip to private-by-default? | 🟡 UNRATIFIED |
| D-OD3 | Template `runs-on:` default strategy? (org-pinned / org-generic / per-project) | 🟡 UNRATIFIED — needs R-02 ADR |
| D-OD4 | Strategy = template-parity closure (a) vs freeze-and-pivot (b) vs dual-track (c)? | 🟡 UNRATIFIED — Sprint 28 scope gate |
| D-OD5 | Sprint 28 = pure gap-closure, or include 1-2 new features? | 🟡 UNRATIFIED — Sprint 28 scope gate |

### 4.2 Sprint 28 wave 1 candidates (re-cite, NOT new actions)

Per audit-baseline §Action plan roll-up wave 1 (11 stories). State:
- ✅ S28-001 (W6 port) — landed (PR #64)
- ✅ S28-002 (#389 port) — landed (PR #66)
- ✅ S28-004 (#414 port) — landed (PR #67)
- ✅ S28-005 (re-render orchestrator.md.tmpl) — landed (PR #995)
- ✅ S28-006 (ADR pre-allocate) — landed (PR #68)
- ✅ S28-008 (LEGACY-REMOVE peer-poke/ping) — landed (PR #992)
- 🟡 S28-003 (forward-port scripts) — in-progress (per `docs/sprints/current/plan.md`)
- 🟡 S28-007..S28-015 — various states (S28-015 closes-format-check.yml landed per `bd15e9f`)
- ❌ R-01, R-02 (runner migration + ADR) — NOT STARTED
- ❌ W-04 (SHA pinning) — NOT STARTED
- ❌ L-01 (launcher v0.3.0 tag) — NOT STARTED

### 4.3 New follow-ups from this delta check (proposed, NOT started)

| ID | Action | Sprint slot |
|---|---|---|
| F-01 | **REFRESH** `docs/new-projectsteps.md` — fix drift: atilcan65 → atilproject URL (line 396), template HEAD `81ec0b1` → `43592c2` | Sprint 29 (after wave 1 closes) |
| F-02 | **VERIFY** `CLAUDE.md` (this repo) — d095 d-test URL migration completeness for `atilcan65` → `atilproject` references | Sprint 29 |
| F-03 | **AUDIT** non-orchestrator soul AMEND state on template (PM/arch/dev/tester) | Sprint 29 |
| F-04 | **RATIFY** D-OD1..D-OD5 owner-decisions (carry-over from §Action plan roll-up) | Owner — pre-Sprint 28 wave 2 |
| F-05 | **ENUMERATE** SHA pin count delta on template workflows (audit-baseline §4.2 W-04) | Sprint 29 |
| F-06 | **CLONE** `dev-studio-template-smoke` and diff against `dev-studio-template` main — confirm smoke parity | Sprint 29 |
| F-07 | **VERIFY** `deploy.yml.tmpl` rendered runs-on — what does `dev-studio-init.sh` substitute for `runs-on:` in this file? | Sprint 28 wave 1 (with R-01) |

### 4.4 Re-issued Q4 candidates (template scope expansion)

Per Q4 above, no new actions proposed in this delta. **Defer Q-04..Q-09 to a
follow-up audit cycle** (audit-baseline §Knowledge gaps admits incomplete).

---

## §5 Sprint 28 status (live on main)

| Layer | Status |
|---|---|
| Sprint 28 plan source | `docs/sprints/sprint-28/00-audit-baseline.md` (no `plan.md`; the audit IS the plan) |
| Sprint 28 kickoff | Issue #974 (open, in-progress, agent:orchestrator) |
| W1 launched | 6 STORY issues (#981-#986), 3 in-progress (per `docs/sprints/current/plan.md`) |
| Stories merged | S28-001, 002, 004, 005, 006, 008, 015 (partial) |
| Stories pending | S28-003 (forward-port scripts, in-progress); S28-007..014 partial |
| Owner merge gate | 1 PR awaiting owner squash (PR #979 Path-Verify SOUL AMEND, draft) |
| Sprint 28 mode | 🟢 LIVE on main + W1 launched + W2 pending |

---

## §6 Cross-references

- [00-audit-baseline.md](00-audit-baseline.md) — comprehensive Sprint 28 audit (PR #967, merged)
- [docs/new-projectsteps.md](../new-projectsteps.md) — runbook (existing, drift detected)
- [docs/sprints/current/plan.md](../current/plan.md) — sprint pointer
- `git remote get-url origin` — `https://github.com/atilproject/AtilCalculator.git`
- `gh api /repos/atilproject/dev-studio-template` — template metadata
- `gh api /repos/atilproject/dev-studio-launcher` — launcher metadata
- `gh api /orgs/atilproject/actions/runners` — 8 self-hosted runners

---

— @orchestrator, 2026-07-13T05:44Z (cycle ~1153), status check per owner
directive 2026-07-13. **No action taken without owner ratification.**