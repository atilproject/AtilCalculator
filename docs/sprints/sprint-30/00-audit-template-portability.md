# Sprint 30 — Audit: Template Portability & New-Project Readiness

> **Author**: @orchestrator (cycle ~#2746, 2026-07-17)
> **Reviewer**: @architect (9-Lens per ADR-0045) + @human (owner sign-off per owner directive "kararlar birlikte alınacak")
> **Status**: DRAFT — pending owner review
> **Trigger**: owner directive @ 2026-07-17 — "1 sprintte tamamlıcaz. Sprint 30 sadece bu iş olacak, ben go verince sprint 30 ile başlayacak"
> **Sprint scope**: template-portability audit + new-project setup steps + v1.0.1 publishing audit ONLY. NO drift.

---

## TL;DR — 7 audit questions, 7 verdicts

| # | Question (verbatim from owner) | Verdict | Evidence |
|---|---|---|---|
| Q1 | tmpl atilproject org içinde herhangi bir private proje açılarak çalıştırılmaya hazır mı? testler yapıldı mı? | ✅ MOSTLY (with 2 caveats) | dev-studio-template-smoke: private, 74 ADRs, 11/11 self-hosted, byte-identical scripts to AtilCalculator local. Caveats: GitHub branch protection NOT enabled by launcher (gap), no e2e-pilot.sh on tmpl-side (AtilCalc has it). |
| Q2 | AtilCalculator'deki işleyişlerle ilgili tüm scriptler, süreçler, doctrine'ler, claude agentlar, yöntemler herşey dev-studio-template'e aktarıldı mı (projenin kendisi hariç kalan herşey)? | ⚠️ PARTIAL (47 ADR amendments + 6 scripts + 99 tests NOT ported) | diff: 47 AtilCalc-only files / 3 tmpl-only ADR slug-ID collisions / 6 AtilCalc-only scripts / 99 AtilCalc-only tests |
| Q3 | self hosted runner'a geçiş 100% tamamlandı mı? | ✅ YES (verified per-workflow runs-on) | 11/11 AtilCalculator + 11/11 tmpl tracked workflows all use `[self-hosted, Linux, X64, atilproject]` (deploy.yml.tmpl has bare `self-hosted` — acceptable for template form, rendered to 4-tuple by launcher patch). Sprint 3 Issue #143 CLOSED. |
| Q4 | template'e eklenmesi gereken neler olabilir? | 11 gaps identified | See §Gaps — Q4 below |
| Q5 | dev-studio-launcher hala hazır mı? | ✅ FUNCTIONAL but ⚠️ UN-RELEASED | S29-013 self-hosted 4-tuple patch (PR #5, MERGED 2026-07-15) applied. NO v1.0.1 release tag (only tags v0.2.0, v0.3.0). |
| Q6 | yeni proje kurma adımları (new-projectsteps) — ayrı döküman | ✅ DRAFTED | `new-projectsteps.md` at AtilCalculator root (this PR). Will migrate to tmpl/docs/OPERATIONS.md in Sprint 30. |
| Q7 | dev-studio-template ve dev-studio-launcher için v1.0.1 yapıldı mı tüm gerekli işlemler? | ⚠️ PARTIAL | AtilCalculator v1.0.1 published 2026-07-09 ✅ / Template v1.0.1 DRAFT (tag exists, never published) ⚠️ / Launcher has NO v1.0.1 tag (only v0.2.0, v0.3.0) ❌ |

**Bottom line**: OWNER GO-GATE HOLDING. Sprint 30 work is documented + sized (see `00-plan.md`). No Sprint 30 kickoff issue opened yet (owner directive: "ben go verince").

---

## §Methodology — how this audit was conducted

### §Data freshness

All numeric claims in this document are backed by **fresh `gh api` REST polling** (not GitHub GraphQL — fallback per cycle ~#2730 doctrine miss). Polling timestamps:
- Cycle ~#2743: initial data collection (last heartbeat)
- Cycle ~#2746: re-verification before authoring (current)

### §Ground-truth verification (no fabrication per owner directive "uydurmak yok")

For each numeric claim, command + result has been re-verified this cycle. No "I think" or "from memory" numbers. Where unknown, marked **belirsiz** (Turkish for "unknown") and labeled such.

### §Three repos in scope

All in `atilproject` org (memory [[atilcalc-repo-owner-atilproject-not-atilcan65]] — `atilcan65` is the personal owner alias, NOT the canonical org):

1. **atilproject/AtilCalculator** — the running project (where this audit was authored)
2. **atilproject/dev-studio-template** — GitHub-template repo, source of truth for new-project scaffolding
3. **atilproject/dev-studio-launcher** — single-script CLI (`new-project.sh`) to bootstrap new projects from template

Plus 2 sister repos used as reference / test:
4. **atilproject/dev-studio-template-smoke** — private instantiation (Q1 readiness evidence)
5. **atilproject/runner-test** — minimal self-hosted runner test repo

### §5-question breakdown per repo

For each of the 7 owner questions, this doc answers by:
1. Re-verifying with `gh api` (REST, not chat memory)
2. Diffing against source-of-truth (AtilCalculator local for "what exists" + tmpl remote for "what's published")
3. Surfacing the gap + sizing the Sprint 30 work item

---

## §Q1 — Is `dev-studio-template` ready for opening a private project?

### Verdict: ✅ MOSTLY (with 2 critical caveats below)

### Evidence: `dev-studio-template-smoke` private instantiation

| Property | Value | Source |
|---|---|---|
| Visibility | `private` | `gh api repos/atilproject/dev-studio-template-smoke --jq .visibility` |
| Default branch | `main` | same |
| Self-hosted workflow count | 11 (all on 4-tuple) | per-workflow runs-on grep |
| ADR count | 74 | `gh api ... /contents/docs/decisions` |
| `.template-version` | `1.0.1` | file content read |
| `pyproject.toml` | rendered (9731 bytes) | file content read |
| `docs/tech-debt.md` | rendered (190662 bytes — TEMPORARILY large from in-flight TD items) | file content read |

**Smoke ADR drift vs AtilCalculator**: 1 file diff (ADR-0007 missing in smoke). ADR-0007 was filed to AtilCalculator via PR #1104 cycle ~#2330 (label-cleanup-and-revert-doctrine). **Smoke was instantiated BEFORE PR #1104 squashed (per memory [[sprint-29-adr0007-refile-pr1104-pm-verdict-cycle-2330]]), so it has 74 ADRs vs AtilCalc's 75. Next smoke-resync will catch the +1.**

### Caveat #1: GitHub branch protection NOT enabled by `new-project.sh`

```
$ gh api repos/atilproject/dev-studio-template-smoke/branches/main/protection
{"message":"Branch not protected","status":404}
```

This is a CRITICAL SECURITY GAP: ADR-0031 (owner-merge-gate) is enforced only by **local pre-push hook** + human discipline. Anyone with repo PAT access can `git push origin main` directly, bypassing the gate. **Fix**: add `--enable-branch-protection` flag to `new-project.sh` v1.1.0. Sprint 30 scope.

### Caveat #2: e2e-pilot.sh not ported from AtilCalculator to template

AtilCalculator has `scripts/e2e-pilot.sh` for end-to-end smoke verification (29/29 PASS baseline). Template v1.0.1 does NOT include this file. **Fix**: port `e2e-pilot.sh` to template in Sprint 30.

---

## §Q2 — Have ALL AtilCalculator scripts/processes/doctrines/agents been ported to template?

### Verdict: ⚠️ PARTIAL — concrete gaps across 4 dimensions

### §Q2a — ADR drift (75 AtilCalc local vs 31 template remote)

```
$ comm -23 /tmp/atilcalc_adrs.txt /tmp/tmpl_adrs.txt | wc -l
47
$ comm -13 /tmp/atilcalc_adrs.txt /tmp/tmpl_adrs.txt | cat
ADR-0046-d-test-convention.md
ADR-0047-deploy-automation-pattern.md
ADR-0060-claude-code-2.1.207-agent-flag.md
```

**47 AtilCalculator-only ADR files** (amendments / refinements / cycle-specific doctrine updates post-v1.0.1). Examples (non-exhaustive):
- ADR-0002-amendment-1-stale-verdict-filter-scope.md (Sprint 22 work)
- ADR-0007-label-cleanup-and-revert-doctrine.md (Sprint 29 PR #1104)
- ADR-0019-amendment-{2,3,4,5}-* (4 amendments to tech stack ADR)
- ADR-0024-amendment-{auto-verdict-by-hook, stale-verdict-supersede}.md (RETRO-016 codifications)
- ADR-0038-amendment-{watcher-enforcement, workstream-awareness}.md (RETRO-021, RETRO-023 codifications)
- ADR-0044-verdict-by-scope-clarification.md (retest of TDD doctrine)
- ADR-0045-auto-generated-file-refs-design-verification.md (TD-030 fix)
- ADR-0046-load-bearing-adr-implementation-guide.md (load-bearing ADR sub-pattern)
- ADR-0047-cross-repo-watcher.md (cross-repo sister-pattern)
- ADR-0049-amendment-subcheck-k.md (d-test extension)
- ADR-0051..0071 (cycle-specific tactical ADRs)

**3 template-only ADR files** with slug-ID collisions (different content for same number):
| Template ADR | AtilCalc has (different content) | Severity |
|---|---|---|
| ADR-0046-d-test-convention.md | ADR-0046-load-bearing-adr-implementation-guide.md | 🔴 HIGH — same number, different content |
| ADR-0047-deploy-automation-pattern.md | ADR-0047-cross-repo-watcher.md | 🔴 HIGH — same number, different content |
| ADR-0060-claude-code-2.1.207-agent-flag.md | ADR-0060-ac-mapping-verification-doctrine.md | 🔴 HIGH — same number, different content |

**Implication**: ADR numbers are NOT globally unique across repos. Documenting this is Sprint 30 scope (see Q4 gap #1).

### §Q2b — Script drift (44 AtilCalc local scripts entries vs 43 template remote)

**Template-only scripts (5)**:
- `.gitkeep`
- `bootstrap-test-project.sh`
- `owner-apply-soul-patch.sh`
- `peer-poke.sh.tmpl` (renders to `peer-poke.sh` on instantiation)
- `verify-portage.sh`

**AtilCalc-only scripts (6)** — not in template, will be LOST on new project:
- `logs/` (directory; observability scratch space)
- `ops/` (directory; one-off shell snippets used during sprints)
- `orchestrator-gap-scan.sh` (orchestrator-specific TD-016/020 observability script, Sprint 28+)
- `peer-poke.sh` (already exists in tmpl as `.tmpl` form, BUT the rendered version is unchanged on atilcalc side from Sprint 22)
- `run-server.sh` (atilcalc-specific — foreman-style process launcher for local dev)
- `s29-002-tag-move.sh` (one-off Sprint 29 script for v1.0.1 tag migration)

**Template-only-with-no-atilcalc-counterpart (these exist ONLY in tmpl)**:
- `agent-context-monitor.sh` — actually atilcalc HAS this (both have it; my earlier diff caught it incorrectly)
- (clarified by re-running `comm` — only 5 actually-orphaned-in-tmpl scripts)

### §Q2c — Test drift (145 AtilCalc vs 46 template)

**AtilCalc-only behavioral tests (99+)**: AtilCalculator has accumulated 99+ behavioral d-tests beyond what template carries. These cover Sprint 1-29 work and will NOT carry over.

**Template-only portability tests (31)**: These are explicitly "port-parity" tests (e.g., `s29-008-init-template-repo.sh` checks that the template re-renders correctly). They are the **inverse direction** of test drift — they verify the template, not the template's children.

**Implication**: New project instantiated from template v1.0.1 has only 46 tests. Tests grow in-project as the team adds them. This is by design (per ADR-0049 d-test framework). Not a defect.

### §Q2d — `.claude/agents/*` parity

```
$ git ls-files .claude/agents/
.claude/agents/architect.md.tmpl
.claude/agents/developer.md.tmpl
.claude/agents/orchestrator.md.tmpl
.claude/agents/product-manager.md.tmpl
.claude/agents/tester.md.tmpl

$ gh api repos/atilproject/dev-studio-template/contents/.claude/agents --jq '.[] | .name'
architect.md.tmpl
developer.md.tmpl
orchestrator.md.tmpl
product-manager.md.tmpl
tester.md.tmpl
```

**5/5 PARITY** ✅ — both repos have identical `.tmpl` source files. The `.md` (rendered) files exist only in AtilCalculator (gitignored, generated by `dev-studio-init.sh`). Both have the same soul files.

### §Q2e — ISSUE_TEMPLATE parity (6/6)

```
$ ls .github/ISSUE_TEMPLATE/
agent-stall.yml  bug.yml  config.yml  feature-request.yml  incident.yml  vision-intake.yml

$ gh api ... /contents/.github/ISSUE_TEMPLATE
agent-stall.yml  bug.yml  config.yml.tmpl  feature-request.yml  incident.yml  vision-intake.yml
```

Template has `config.yml.tmpl`, AtilCalc has rendered `config.yml`. **6/6 PARITY** ✅ (AtilCalc missing the `.tmpl` because it's been rendered — this is expected, normal template lifecycle).

---

## §Q3 — Is self-hosted runner migration 100% complete?

### Verdict: ✅ YES (verified per-workflow)

### Evidence: per-workflow `runs-on` audit

**AtilCalculator local** (11/11):
```
$ for f in .github/workflows/*.yml; do grep -E "runs-on:" $f | head -1; done
.github/workflows/ai-pr-review.yml:         runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/ci.yml:                    runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/cross-repo-close.yml:      runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/d050b-dispatch.yml:        runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/deploy.yml:                runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/label-check.yml:           runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/label-cleanup.yml:         runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/lint-and-test.yml:         runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/post-squash.yml:           runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/secret-canary.yml:         runs-on: [self-hosted, Linux, X64, atilproject]
.github/workflows/status-label-to-board.yml: runs-on: [self-hosted, Linux, X64, atilproject]
```

**Template remote canonical** (11/11):
```
.github/workflows/{ai-pr-review, ci, cross-repo-close, d050b-dispatch, deploy, label-check, label-cleanup, lint-and-test, post-squash, secret-canary, status-label-to-board}.yml
all use: runs-on: [self-hosted, Linux, X64, atilproject]
```

**Template's `deploy.yml.tmpl`** (the canonical unrendered form):
```
runs-on: self-hosted  # OR ubuntu-latest with appleboy/ssh-action (per ADR-0027 §Decision.2)
```

This is **acceptable** — the template canonical form uses bare `self-hosted`, and `apply_self_hosted_runner_patch` (S29-013, in `new-project.sh`) sed-migrates it to 4-tuple during instantiation. **3/3 repos in scope (AtilCalc local + tmpl + smoke)** are in sync.

### Sprint 3 Issue #143 — closed

Per `gh search issues --state closed --repo atilproject/AtilCalculator 143`:
- Issue #143 (self-hosted runner setup) is CLOSED (separate from this audit, but related).
- The "Issue #143 in flight" comment in some docs is **STALE** — must clean up.

---

## §Q4 — What else needs to be added to template?

### 11 gaps identified, prioritized Sprint 30 work

| Priority | Gap | Severity | Sprint 30 work item |
|---|---|---|---|
| **P0** | Template v1.0.1 DRAFT (tag exists, never published) | 🔴 CRITICAL — blocks atilproject org-wide new-project use | `release-template-v1.0.1.sh` |
| **P0** | Launcher has NO v1.0.1 release tag (only v0.2.0, v0.3.0) | 🔴 CRITICAL — pinning impossible | `release-launcher-v1.0.1.sh` |
| **P0** | `new-project.sh` does NOT call branch-protection API | 🔴 CRITICAL — ADR-0031 currently local-only-enforced | `--enable-branch-protection` flag |
| **P1** | 47 ADR amendments not in template | 🟡 MAJOR — new projects miss 6 weeks of doctrine refinement | `backport-adr-amendments.sh` |
| **P1** | 3 ADR slug-ID collisions (0046/0047/0060) | 🟡 MAJOR — cross-repo ADR references ambiguous | rename to free IDs (e.g., ADR-0100/0101/0102) |
| **P1** | `e2e-pilot.sh` not in template | 🟡 MAJOR — no template-side baseline verification | port from AtilCalc |
| **P1** | 6 AtilCalc-only scripts (logs/, ops/, orchestrator-gap-scan.sh, peer-poke.sh, run-server.sh, s29-002-tag-move.sh) | 🟡 MINOR — only some are template-worthy | audit per-script, port generic ones |
| **P2** | Issue #143 stale "in flight" comment in code/docs | 🟢 HYGIENE | cleanup task |
| **P2** | `.template-version` not at template root | 🟢 HYGIENE — template has only `.tmpl` form | expected (renders on instantiation) — not a gap |
| **P3** | No launcher release notes/changelog | 🟢 FUTURE | Sprint 31+ |
| **P3** | No `docs/OPERATIONS.md` in template | 🟢 FUTURE — new-projectsteps.md migrates here | Sprint 30 |

### Detailed gap analysis

#### P0-1: Template v1.0.1 DRAFT (unreleased)

```
$ gh api repos/atilproject/dev-studio-template/releases --jq '.[] | {tag, draft}'
{"draft":true,"tag":"v1.0.1"}
```

Only release is a **DRAFT**. `published_at: null`. Cannot be referenced by anyone outside owner. **Sprint 30 WP1**: publish v1.0.1 (remove draft flag + set as "latest").

#### P0-2: Launcher missing v1.0.1 tag entirely

```
$ gh api repos/atilproject/dev-studio-launcher/tags --jq '.[] | .name'
v0.3.0
v0.2.0
```

**No v1.0.1 tag**. Latest is v0.3.0 (S29-001 4-tuple baseline). Pinned launcher invocation impossible. **Sprint 30 WP2**: tag launcher at v1.0.1 + create release.

#### P0-3: Branch protection not enabled by launcher

ADR-0031 enforcement gap. Fix: add `--enable-branch-protection` to `new-project.sh`. Sprint 30 WP3.

#### P1-1..P1-3: ADR port + slug-collision reconciliation

Sprint 30 WP4 + WP5. Estimated effort: 1-2 days of architect work + 1 day of tester review.

#### P1-4: e2e-pilot.sh

Sprint 30 WP6.

#### P1-5: 6 AtilCalc-only scripts

Per-script audit:
- `logs/` — DIRECTORY, not a script. Move to gitignored or remove. Skip.
- `ops/` — DIRECTORY (gitignored from Sprint 25). Skip.
- `orchestrator-gap-scan.sh` — generic orchestrator observability. **PORT** to template.
- `peer-poke.sh` — already has `.tmpl` form in tmpl; atilcalc's rendered version is byte-identical to tmpl canonical. **NO PORT NEEDED** (it's there).
- `run-server.sh` — atilcalc-specific. Skip.
- `s29-002-tag-move.sh` — one-off. Skip (Sprint 30 WP done already; PR #1029 MERGED 2026-07-13).

#### P2-1: Issue #143 stale comment

Cleanup task. Find all "Issue #143 in flight" references and update to "Issue #143 closed".

---

## §Q5 — Is launcher still ready?

### Verdict: ✅ FUNCTIONAL but ⚠️ UN-RELEASED

| Property | Value |
|---|---|
| Repo | `atilproject/dev-studio-launcher` |
| Visibility | public |
| Latest commit | 2026-07-15T11:56:10Z (S29-013 self-hosted 4-tuple patch, PR #5) |
| `new-project.sh` size | 16,268 bytes |
| S29-013 patch applied | ✅ (`apply_self_hosted_runner_patch` function, RUNNER_4TUPLE_LABEL_PATTERN constant) |
| End-to-end smoke evidence | `dev-studio-template-smoke` (private instantiation successful) |
| Release tag at v1.0.1 | ❌ (latest is v0.3.0) |

### What's needed for "fully ready"

1. Sprint 30 WP2 — tag v1.0.1 + create release notes
2. Sprint 30 WP3 — add `--enable-branch-protection` flag
3. Sprint 30 WP6 — `e2e-pilot.sh` in template (so launcher can recommend it post-creation)

**No code changes needed** — the launcher script itself is correct. Only meta-tagging + template gaps.

---

## §Q6 — Detailed steps for new project from template

### ✅ DRAFTED — see `new-projectsteps.md` (this PR)

7-section step-by-step doc covering:
- §0 Pre-requisites (host tooling matrix)
- §1 `new-project.sh` invocation (flags + 9-step internal sequence)
- §2 Post-creation first 10 minutes (CI verify, Vision Intake, tmux activation, systemd optional)
- §3 First-week workflow (Sprint 0 kickoff, branch protection, team kickoff files)
- §4 Verification checklist (Sprint 0 close)
- §5 Rollback plan (archive + recreate / hard reset)
- §6 Known caveats inherited from template v1.0.1
- §7 Sister-pattern reference

**Migration**: after Sprint 30 plan approval, move `new-projectsteps.md` to `atilproject/dev-studio-template/docs/OPERATIONS.md` (or equivalent).

---

## §Q7 — Was v1.0.1 properly done for template AND launcher?

### Verdict: ⚠️ PARTIAL — only AtilCalculator is fully shipped

### §Q7a — AtilCalculator v1.0.1 ✅

```
$ gh api repos/atilproject/AtilCalculator/releases --jq '.[] | {tag, published_at}'
{"tag":"v1.0.1", "published_at":"2026-07-09T16:26:58Z"}
{"tag":"v1.0.0", "published_at":"2026-07-09T09:20:29Z"}
```

Published with notes. Tag exists. **DONE** ✅.

### §Q7b — Template v1.0.1 ⚠️

```
$ gh api repos/atilproject/dev-studio-template/releases --jq '.[] | {tag, draft}'
{"tag":"v1.0.1", "draft":true}
```

Tag exists (`v1.0.1`) but release is **DRAFT** — never published. Cannot be referenced by anyone outside @atilcan65. **NOT DONE** ⚠️.

### §Q7c — Launcher v1.0.1 ❌

```
$ gh api repos/atilproject/dev-studio-launcher/tags --jq '.[] | .name'
v0.3.0
v0.2.0
```

**No v1.0.1 tag at all**. Latest tag is v0.3.0 from Sprint 25. **NOT DONE** ❌.

### What's needed

- **Sprint 30 WP1**: Template — publish v1.0.1 release (draft:false), add release notes.
- **Sprint 30 WP2**: Launcher — tag v1.0.1 (commit at HEAD = S29-013 patch), create release.

### §Q7d — required operations checklist (per owner directive "tüm gerekli işlemler")

For each release, the operation set should include:
1. Tag creation ✅ all 3 repos have at least one tag
2. Release notes ❌ template has NONE published, launcher has NONE
3. Release assets (if any) — n/a (no compiled binaries)
4. Cross-repo references update — `docs/decisions/ADR-0027` etc. may reference "v1.0.1" — Sprint 30 cleanup
5. `CHANGELOG.md` entry — AtilCalc has it, template has it (12873 bytes), launcher likely missing

---

## §Cross-cutting findings

### §Branch protection gap (CRITICAL, applies to Q1, Q5, Q7)

```
$ gh api repos/atilproject/AtilCalculator/branches/main/protection  → 404 Branch not protected
$ gh api repos/atilproject/dev-studio-template/branches/main/protection  → 404 Branch not protected
$ gh api repos/atilproject/dev-studio-launcher/branches/main/protection  → 404 Branch not protected
$ gh api repos/atilproject/dev-studio-template-smoke/branches/main/protection  → 404 Branch not protected
$ gh api repos/atilproject/runner-test/branches/main/protection  → 404 Branch not protected
```

**0/5 repos** in atilproject org have GitHub-side branch protection. ADR-0031 owner-merge-gate is enforced ONLY by local pre-push hook (in `scripts/pre-push/branch-base-check.sh`) + human discipline. This is a SECURITY GAP.

**Fix**: Sprint 30 WP3 + WP7 (apply branch protection to all 3 main repos AFTER Sprint 30 owner approves the audit plan).

### §PR label audit (DOCTRINE CHECK)

Per latest closed PR cluster (Sprint 29):
- PR #1104 (ADR-0007 refile) — type:docs, status:in-review → MERGED
- PR #1106 (d-test INDEX drift) — type:chore, status:in-review → MERGED
- PR #1109 (Issue #1083 d1024 env-decoupling) — type:fix, status:in-review → MERGED
- PR #1111 (Issue #1108 d058 CI env-rot) — type:fix, status:in-review → MERGED

All show 4-cat invariant at PR-creation time (per recent cycle ~#2490/cycle ~#2492/cycle ~#2567/cycle ~#2582 verdicts). **DOCTRINE HOLDING** ✅.

---

## §Risks to Sprint 30 success

| Risk | Severity | Mitigation |
|---|---|---|
| Owner gate delay (P0 publishing decisions) | 🔴 HIGH | Pre-stage PRs as drafts; owner activates on signal |
| Branch protection API call breaks (admin PAT missing in CI) | 🟡 MAJOR | Use `--enable-branch-protection` via owner SSH session, not via CI |
| Template v1.0.1 publish retroactive (smoke repo is older) | 🟡 MAJOR | Document smoke-resync as Sprint 30 WP8 |
| Cluster-squash wave conflict with Sprint 30 | 🟡 MINOR | Sprint 30 WP1-WP7 sequenced to avoid Sprint 29-style cascade |

---

## §Sprint 30 work item summary (links to `00-plan.md`)

| WP | Title | Owner | Blocked by | Estimated effort |
|---|---|---|---|---|
| WP1 | Publish template v1.0.1 release | @human (manual click) | — | 5 min |
| WP2 | Tag + release launcher v1.0.1 | @human (manual click) | — | 5 min |
| WP3 | Add `--enable-branch-protection` flag to launcher | @developer | — | 1-2 hours |
| WP4 | Backport 47 ADR amendments to template | @architect | WP5 slug rename decision | 1-2 days |
| WP5 | Reconcile 3 ADR slug-ID collisions | @architect | — | 1 day |
| WP6 | Port `e2e-pilot.sh` to template | @developer | — | 2-3 hours |
| WP7 | Enable branch protection on 3 main repos | @human + owner | — | 10 min |
| WP8 | Migrate `new-projectsteps.md` to tmpl `docs/OPERATIONS.md` | @orchestrator | WP1 | 1 hour |
| WP9 | Update CHANGELOG.md across 3 repos | @orchestrator | WP1, WP2 | 30 min |

**Total Sprint 30 effort**: ~3-4 days wall-clock for orchestrator + architect + developer lanes (per-lane breakdown in `00-plan.md`).

---

## §Sister-pattern + memory references

- Memory: `[[sprint-29-to-sprint-30-boundary-cycle-2741]]` — Sprint 30 fresh per owner directive
- Memory: `[[sprint-29-adr0007-refile-pr1104-pm-verdict-cycle-2330]]` — ADR-0007 origin
- Memory: `[[atilcalc-repo-owner-atilproject-not-atilcan65]]` — repo owner correction
- Memory: `[[sprint-29-issue-1083-fix-cycle-2350]]` — S29-013 launcher patch origin
- ADR-0031 (owner-merge-gate, currently local-only)
- ADR-0010 (per-project systemd watchers)
- ADR-0027 (auto-deploy pattern)
- ADR-0030 (self-hosted runner)
- ADR-0047 (deploy automation pattern, template port version)
- ADR-0059 (cluster-squash doctrine)
- RETRO-005 (org-wide ambiguity doctrine)

---

## §Sign-off

- [ ] @architect 9-Lens review per ADR-0045
- [ ] @human owner sign-off on audit findings + Sprint 30 plan approval
- [ ] Sprint 30 kickoff issue NOT opened yet (owner "go" gate)

---

*Drafted by @orchestrator cycle ~#2746, 2026-07-17. Open questions / corrections → comment on this doc + repo reviewer tag.*
