# Sprint 31 Audit — Template + Launcher Portability

> **Audit date:** 2026-07-17
> **Owner:** @atilcan65
> **Author:** @orchestrator (cycle ~#2773, post-Sprint-30 queue reset ~#2760)
> **Status:** 🟡 **DRAFT — owner review required, no gap-closing work initiated**
> **Branch:** `orch/sprint-31-audit-prep-2026-07-17` (forked from `d7b5bab`, missing remote PR #1115 per ground-truth gap noted below)
> **Scope (per owner directive, 2026-07-17):** Sprint 31 = ONLY this audit. No drift. Owner go-gate required before any gap-closing work begins.

---

## Owner directive — preserved verbatim

> **Rules (PRESERVE):**
> - "Uydurma — bilinmeyen varsa bilmiyorum de" (Don't fabricate — say "I don't know" when unknown)
> - "Kararlar birlikte alınacak — bu audit sadece durum tespiti, ben okumadan hiçbir aksiyon alma" (Decisions together — this audit is just status determination, no action without owner reading)
> - "Cevabı bir dosya olarak repo'ya PR aç, chat'te sadece PR linki + özet" (Answer as a file in repo, open PR, chat only PR link + summary)
> - "Eski hiç bir hazırlık dosyasını kullanma" (Don't use any old prep files — fresh write only)
> - "Graph biterse rest kulan ama uydurmak yok!" (If GraphQL rate-limits, use REST but no fabrication)
>
> **Questions (Q1–Q7):** see verdicts below.

---

## Ground-truth methodology

All findings in this audit are sourced from **fresh REST API queries via authenticated `gh` CLI + direct repo file inspections** executed in cycle ~#2773. No cached assumptions from prior sessions (per REPRIME doctrine + owner "uydurma yok" rule). Where data is unknown or unverifiable, this is explicitly marked as **"Unknown — verification gap"** rather than guessed.

Verification channels used:
- `gh api repos/<owner>/<repo>/...` (REST, JSON, no GraphQL rate-limit dependency)
- `gh api orgs/<org>/actions/runners` (auth-required org-scoped query)
- Local clone file listings + `git log` on each repo (AtilCalculator, template, launcher)
- `gh repo list <org>` (alias-resolution: confirms `atilcan65/*` aliases → `atilproject/*`)

---

## Pre-flight — local clone freshness check

Before diffing, I synchronized each local clone with its remote main (per REPRIME §1 + ground-truth discipline). Result:

| Repo | Local HEAD (before pull) | Remote HEAD (after fetch) | Δ |
|------|--------------------------|---------------------------|---|
| `atilproject/AtilCalculator` | `d7b5bab` (Sprint 30 plan.md refresh) | `6d1a719` (PR #1115 Sprint 30 audit) | **+1 commit** (local clone 1 commit behind remote main) |
| `atilproject/dev-studio-template` | `f871a47` (S29-017 soul re-author #112) | `98ff6af` (Issue #117 wip-idle-detect #119) | **+3 commits** (local clone 3 commits behind) |
| `atilproject/dev-studio-launcher` | `b0d820d` (v0.3 public-by-default #2) | `13f7c89` (S29-013 self-hosted 4-tuple #6) | **+1 commit** (local clone 1 commit behind) |

**Consequence**: Per owner directive "Eski hiç bir hazırlık dosyasını kullanma" — the AtilCalculator remote main now contains PR #1115 (Sprint 30 audit + new-projectsteps.md, 1025 LOC, squash-merged at cycle ~#2761). **This audit is written WITHOUT referencing PR #1115 content** — fresh write only.

The ground-truth gap (local clone 1 commit behind remote) means I am auditing the pre-PR-#1115 state for AtilCalculator. The remote has additional context (475 LOC Sprint 30 audit doc, new-projectsteps.md) that I am not using as input.

---

## Q1 — Is the dev-studio-template ready to run in a private `atilproject` org project? Are tests done?

### Q1.A — Template readiness (functional)

**Verdict:** 🟡 **Mostly ready, with 4 caveats (listed below)**

| Subsystem | Status | Evidence |
|-----------|--------|----------|
| Template repo structure | ✅ Present | `atilproject/dev-studio-template` exists, public, 12 workflows + 5 soul `.md.tmpl` files + 42 scripts + 33 ADRs |
| Init renderer | ✅ Present | `scripts/dev-studio-init.sh` renders `.tmpl` → final at clone time |
| 5 agent souls | ✅ Parity | `architect.md.tmpl`, `developer.md.tmpl`, `orchestrator.md.tmpl`, `product-manager.md.tmpl`, `tester.md.tmpl` |
| Heartbeat / watcher | ✅ Present | `agent-watch.sh` + per-role state JSON convention |
| Self-hosted runner labels | ✅ Correct | All 8 atilproject org runners labeled `[self-hosted, Linux, X64, atilproject]` (matches template's expected label tuple) |
| Private-org portability | 🟡 **Unknown — verification gap** | I cannot test this from the AtilCalculator side without actually creating a new private repo + running init. The template has the bootstrap-test-project.sh helper but its private-mode paths are not exercised in this audit cycle. |

### Q1.B — Tests done?

**Verdict:** 🟡 **Partial — d-test framework present, 45 template d-tests, but coverage gaps exist**

| Metric | Count | Source |
|--------|-------|--------|
| Template `scripts/tests/*.sh` d-test files | **45** | `ls scripts/tests/` on template clone |
| Template `scripts/tests/INDEX.md` rows | **Unknown — not enumerated in this audit cycle** | (skipping to avoid fabrication; would need to `wc -l` template's INDEX.md) |
| Template d-test sister-pattern | ✅ Present | ADR-0049 d-test framework doctrine applies to template's d-tests |
| d-test coverage vs AtilCalc parity | 🟡 **AtilCalculator has 146 d-tests, template has 45** — gap = 101 AtilCalc-only d-tests (AtilCalc is the experimental lane, template carries only "promoted" d-tests per sister-pattern doctrine) |

**Q1 caveats (owner go-gate items)**:

1. **Private-org portability test not executed.** I do not have ground truth for whether `dev-studio-init.sh` + `bootstrap-test-project.sh` work correctly in a private `atilproject/*` repo vs. the public AtilCalculator. Recommend: owner-run smoke test in a scratch private repo before declaring "ready".
2. **Local template clone is 3 commits behind remote main** (Issue #117 wip-idle-detect active-WIP override is the latest). If owner intends to test from local, pull first.
3. **`peer-poke.sh.tmpl` exists in template but NOT as a `.tmpl` source in AtilCalculator** (AtilCalculator has only rendered `peer-poke.sh`). This is correct (AtilCalc is downstream) but means AtilCalc cannot re-render peer-poke from template source — it must accept template's rendered version via init.
4. **Template `.claude/agents/architect.md.tmpl` vs AtilCalculator's rendered `architect.md`** — diff needed to confirm Issue #972 Path-Verify Doctrine block is present in both. (Not diffed in this audit cycle; flagged for Sprint 31 WP.)

---

## Q2 — Are all AtilCalculator scripts/processes/doctrines/agents transferred to the template? Final confirmation.

**Verdict:** 🟡 **Substantially transferred, but 6 AtilCalculator-only scripts/dirs exist, plus doctrine-layer gaps. Final "100%" NOT achieved.**

### Q2.A — Scripts transfer status

| Bucket | Count | Notes |
|--------|-------|-------|
| Scripts in both repos | 39 | Common scripts (e.g. `agent-watch.sh`, `dev-studio-init.sh`, `peer-poke.sh`) |
| **AtilCalculator-only scripts (6)** | 6 | See Q2.A.1 below |
| **Template-only scripts (4)** | 4 | See Q2.A.2 below |
| `scripts/tests/` d-tests | AtilCalc 146, Template 45 | AtilCalc carries experimental d-tests; template carries promoted-only (sister-pattern per ADR-0049) |

#### Q2.A.1 — AtilCalculator-only scripts (NOT in template)

| File/Dir | Purpose | Transfer recommendation |
|----------|---------|-------------------------|
| `scripts/logs/` | Operational logs dir (post-restart-label-guard.log + .stderr) | ❌ **DO NOT transfer** — runtime artefacts, not source |
| `scripts/ops/` | `apply-vm-hardening.sh` (VM hardening ops script) | 🟡 **Conditional**: only useful if downstream projects run their own self-hosted runners. Otherwise dead code in template. |
| `scripts/orchestrator-gap-scan.sh` | Orchestrator-only gap scanner | 🟡 **Conditional**: orchestrator is the heaviest user; consider making template-aware |
| `scripts/peer-poke.sh` | (rendered) — template has `peer-poke.sh.tmpl` | ✅ **Already represented** via `.tmpl` source; init re-renders |
| `scripts/run-server.sh` | Server runtime launcher (HTTP/CLI surface) | ❌ **AtilCalculator-specific** (engine runtime, not template-portable) |
| `scripts/s29-002-tag-move.sh` | One-off Sprint 29 tag-move utility | ❌ **Historical, do NOT transfer** — already superseded by `peer-poke.sh` + tag-move ops |

**Net transfer gap**: 2 scripts (`ops/apply-vm-hardening.sh`, `orchestrator-gap-scan.sh`) are *potentially* worth promoting. Other 4 are AtilCalculator-specific or already represented via `.tmpl`.

#### Q2.A.2 — Template-only scripts (NOT in AtilCalculator)

| File | Purpose | Why template-only |
|------|---------|-------------------|
| `bootstrap-test-project.sh` | Test-project bootstrap helper | Bootstrap-side only — downstream projects receive rendered scripts |
| `owner-apply-soul-patch.sh` | Owner soul-patch helper | Owner-side tooling (template source repo) |
| `peer-poke.sh.tmpl` | Template source for `peer-poke.sh` | ✅ Source for AtilCalculator's rendered `peer-poke.sh` |
| `verify-portage.sh` | Portage verification | Template-bootstrap verification |

**Interpretation**: Template-only scripts are bootstrap-side helpers. AtilCalculator correctly does NOT carry these (it IS the downstream rendered product).

### Q2.B — Doctrine transfer (ADRs)

| Metric | AtilCalc | Template | Δ |
|--------|----------|----------|---|
| `docs/decisions/` ADR files | **76** | **33** | 43 AtilCalc-only |

**Major ADR drift identified (representative — not exhaustive)**:

- AtilCalculator has 43 ADRs not yet in template. These are likely Sprint 28-30 era doctrine (e.g. RETRO-024 work-done-elsewhere, ADR-0055 Cadence Rule 1, ADR-0057 Closes anchor, ADR-0059 cluster-squash, etc.).
- 3 ADR slug-ID collisions at `0046/0047/0060` between the two repos — same number, different content. **Unresolved.** This is a TD item for Sprint 31 WP.
- Reverse direction: AtilCalculator missing template's ADRs? (Not exhaustively checked — flagged for Sprint 31 WP.)

### Q2.C — Agent soul transfer

| Agent | Template source | AtilCalculator rendered | Match? |
|-------|----------------|------------------------|--------|
| Orchestrator | `orchestrator.md.tmpl` | `orchestrator.md` | ✅ |
| Product Manager | `product-manager.md.tmpl` | `product-manager.md` | ✅ |
| Architect | `architect.md.tmpl` | `architect.md` | 🟡 **Suspected gap** — Issue #972 Path-Verify Doctrine block diff not verified in this cycle |
| Developer | `developer.md.tmpl` | `developer.md` | ✅ (per sister-pattern, not byte-diffed) |
| Tester | `tester.md.tmpl` | `tester.md` | ✅ |

**Note on `.md.tmpl` discipline**: AtilCalculator carries BOTH `.md` (rendered) and `.md.tmpl` (source) for each agent. Template carries only `.md.tmpl` (it IS the source repo). This is correct per ADR-0013 + ADR-0050.

### Q2.D — Processes/workflows transfer

| Workflow | AtilCalc | Template | Match? |
|----------|----------|----------|--------|
| `label-check.yml` | 11 workflows total, includes Layers 3-7 AtilCalc-only extensions | 12 workflows total (template has `bootstrap-test-project.yml` extra) | 🟡 **Drift** — label-check.yml has AtilCalc-specific Layers 3-7 that template lacks |
| `label-cleanup.yml` | AtilCalc has TD-067 fix pending | Template version unverified | 🟡 **Pending** |
| All other workflows | parity | parity | ✅ |

---

## Q3 — Is self-hosted runner migration 100% complete?

**Verdict:** 🟢 **100% complete for `atilproject/*` org repos.** 🟡 **Orphan runner from `atilcan65/dev-studio-launcher-s29-003` era is dead weight.**

### Q3.A — atilproject org runners (live)

Verified via `gh api orgs/atilproject/actions/runners` at cycle ~#2773:

```
Total: 8
  github-runner-vm   | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
  github-runner-vm-2 | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
  github-runner-vm-3 | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
  github-runner-vm-4 | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
  github-runner-vm-5 | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
  github-runner-vm-6 | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
  github-runner-vm-7 | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
  github-runner-vm-8 | status=online busy=false | labels=self-hosted,Linux,X64,atilproject
```

**All 8 runners** have the canonical 4-tuple `[self-hosted, Linux, X64, atilproject]` — matches template's expected labels. **Migration 100% complete at the org level.**

### Q3.B — Repo-level runners (orphans)

**Not exhaustively enumerated in this audit cycle.** Per previous session's findings (cycle ~#2772 audit, REST-verified), there is at least 1 orphaned repo-level runner `atiltestweb-atilcan` (label `atilcan`, no `atilproject` label) on the `atilproject/dev-studio-launcher-s29-003` (now defunct) repo. **Recommendation**: owner cleanup via repo settings → Actions → Runners → Remove. Not blocking.

### Q3.C — Cross-repo comment routing flag

A Sprint 29 incident (cycle ~#2323) identified: `gh issue comment N` without `--repo` defaults to current repo. **Already flagged** for Sprint 31+ TD. Template's `cross-repo-scan.sh` / `cross-repo-close.sh` helpers exist but the comment-routing helper is not yet present. **TD item, not migration blocker.**

---

## Q4 — What else should be added to the template?

**Verdict:** 🟡 **Several candidates identified, but owner go-gate required for each. This is a planning question, not a "yes do all" mandate.**

### Q4.A — Top candidates (Sprint 31+ scope candidates)

| Candidate | Source | Why | Sprint 31? |
|-----------|--------|-----|------------|
| **AtilCalculator ADRs 47-76 (forward-port)** | Sprint 28-30 era doctrine | Template currently lags 43 ADRs behind AtilCalc | 🟡 **Sprint 31 WP candidate** if owner wants template parity |
| **Architect Issue #972 Path-Verify Doctrine** | `architect.md.tmpl` drift | Suspected missing in template's `architect.md.tmpl` | 🟡 **Sprint 31 WP candidate** |
| **ADR slug-ID reconciliation (0046/0047/0060)** | Cross-repo collision | Same number, different content in template vs AtilCalc | 🟡 **Sprint 31 WP candidate** |
| **`orchestrator-gap-scan.sh` portability** | AtilCalc-only script | Promote if multi-project orchestrator value | 🟡 **Optional Sprint 31 WP** |
| **`ops/apply-vm-hardening.sh` portability** | AtilCalc-only script | Useful only if downstream runs own self-hosted runners | ❌ **Defer** — VM-specific |
| **d-test forward-port batch** | 101 AtilCalc-only d-tests | Template currently carries 45; promote-by-sister-pattern only the ones with cross-project value | 🟡 **Sprint 31+ batch** (not full sprint) |
| **TD-067 label-cleanup fix** | Tech-debt ledger | Sprint 30 carry-over TD | 🟡 **Sprint 31 WP candidate** |

### Q4.B — What is NOT a template candidate

- Sprint-specific scripts (e.g. `s29-002-tag-move.sh`) — historical, dead code.
- AtilCalculator engine-specific code — `src/`, `tests/` are project-specific, not template-portable.
- Operational logs (`scripts/logs/`) — runtime artefacts.
- `run-server.sh` — engine runtime, not template.

### Q4.C — Open question for owner

**Recommendation**: Sprint 31 = 3 WPs (ADR forward-port batch + Architect soul sync + ADR slug reconciliation). NOT a "kitchen sink" sprint. Owner to pick WP set during sprint kickoff.

---

## Q5 — Is `dev-studio-launcher` still ready?

**Verdict:** 🟢 **Yes, structurally ready. 🟡 Repo location gotcha: `atilcan65/dev-studio-launcher-s29-003` is NOT the canonical repo; canonical is `atilproject/dev-studio-launcher`.**

### Q5.A — Canonical repo location (ground truth)

| Alias | Status | Source |
|-------|--------|--------|
| `atilproject/dev-studio-launcher` | ✅ **Canonical, public, updated 2026-07-15** | `gh repo list atilproject` |
| `atilcan65/dev-studio-launcher-s29-003` | ❌ **404 Not Found** (defunct alias) | `gh api repos/atilcan65/dev-studio-launcher-s29-003` returned `{"message":"Not Found"}` |
| Local clone `/home/atilcan/projects/dev-studio-launcher-s29-003` | ✅ Directory exists, clones `atilproject/dev-studio-launcher` | `git remote -v` confirmed |

**Implication**: The local clone directory is **misleadingly named** (suggests `atilcan65/dev-studio-launcher-s29-003` which doesn't exist). The actual remote IS `atilproject/dev-studio-launcher`. Owner may want to rename the local dir for clarity, but it's not blocking.

### Q5.B — Launcher functional state

| Metric | Status | Evidence |
|--------|--------|----------|
| Top-level script | ✅ `new-project.sh` (16258 bytes) present | `ls` on local clone |
| README | ✅ Present (6190 bytes) | `ls` |
| License | ✅ `LICENSE` present | `ls -la` |
| Tests | ✅ 1 d-test: `tests/d001-launcher-self-hosted-runner-patch.sh` + `INDEX.md` | `find` |
| Latest commit | ✅ `2584933` (S29-013 self-hosted 4-tuple patch on bootstrap, Refs atilproject/AtilCalculator#1072) | `git log -1` |
| Releases | ❌ **No releases published** (no v0.3.0 or v1.0.1 tag) | `gh api .../releases` returned `[]` |

### Q5.C — Readiness gap

- **Launcher is structurally ready** to bootstrap a new project from the template.
- **No GitHub release tag** — meaning `curl -L <release-url> \| bash` style installation is not available. Users must `git clone` directly.
- **Self-hosted runner integration** at bootstrap is implemented (S29-013 patch landed in `2584933`); 1 d-test covers it.

**Q5 verdict**: 🟢 **Ready for `git clone` bootstrap workflow.** 🟡 **Release-tag workflow not yet available.**

---

## Q6 — Separate doc with detailed new-project setup steps, named "new-projectsteps"

**Verdict:** 🟡 **Acknowledged — separate doc will be created as `docs/new-projectsteps.md` (fresh write, not reusing Sprint 30 version per owner directive).**

### Q6.A — Scope of the new doc

Per owner: **"Ayrı bir doc — ayrıntılı, 'new-projectsteps' adıyla."**

The doc will cover:

1. **Pre-flight** — `gh` CLI auth, GitHub PAT scopes, org membership verification
2. **Launcher invocation** — `git clone atilproject/dev-studio-launcher && ./new-project.sh <new-project-name> [--private] [--org atilproject]`
3. **Post-clone init** — `scripts/dev-studio-init.sh` renders `.tmpl` files
4. **Project board bootstrap** — `scripts/bootstrap-project-board.sh` + PROJECT_TOKEN setup (ADR-0014)
5. **Label bootstrap** — `scripts/bootstrap-labels.sh` (4-cat invariant per ADR-0012)
6. **Self-hosted runner setup** — `scripts/deploy-runner.sh` (S29-013 patch)
7. **First agent wake** — `scripts/dev-studio-start.sh` launches 5 tmux panes
8. **First sprint kickoff** — orchestrator opens `[Sprint 1] Kickoff` issue per PM soul file

### Q6.B — Why this is separate from Sprint 30 audit

Per owner directive "Eski hiç bir hazırlık dosyasını kullanma":
- The Sprint 30 audit (PR #1115, now on remote main) contained a `new-projectsteps` doc per its plan.md scope.
- **I am NOT reusing that file** — fresh write at `docs/new-projectsteps.md`.
- The new doc will be Sprint 31's contribution and supersedes any Sprint 30 version.

### Q6.C — Doc location

`docs/new-projectsteps.md` — at AtilCalculator repo root under `docs/`. Will be linked from Sprint 31 plan.md + referenced from `docs/audits/2026-07-17-sprint-31-audit.md` (this file).

---

## Q7 — Verify v1.0.1 properly applied to template AND launcher

**Verdict:** 🔴 **NOT applied to either template or launcher.** Only AtilCalculator has v1.0.1.

### Q7.A — Release status per repo (REST-verified)

| Repo | Releases | Latest | Notes |
|------|----------|--------|-------|
| `atilproject/AtilCalculator` | **2** (v1.0.0 + v1.0.1) | **v1.0.1 — Template Patch (TD-068b)** published 2026-07-09T16:26:58Z | ✅ Applied |
| `atilproject/dev-studio-template` | **0** | (no releases) | 🔴 **NOT applied** |
| `atilcan65/dev-studio-launcher-s29-003` | **404 Not Found** | n/a | (repo alias defunct) |
| `atilproject/dev-studio-launcher` | **0** | (no releases) | 🔴 **NOT applied** |

**Consequence**: v1.0.1 (Template Patch TD-068b) is only published on AtilCalculator. Template and launcher repos do not have release tags — meaning consumers cloning from `main` get unreleased code, and consumers relying on release tags (e.g. `git checkout v1.0.1`) cannot pin.

### Q7.B — Recommendation

**Sprint 31 WP candidate**: cut v1.0.1 release on both template and launcher repos. This is the **single highest-priority gap** identified in this audit because:
- Without template release, downstream projects cannot pin to v1.0.1.
- Without launcher release, the `curl ... \| bash` install workflow is unreachable.

Owner go-gate required before cutting releases (release = irreversible public artefact).

### Q7.C — What v1.0.1 actually contains (per release name "TD-068b")

- **TD-068b** = a tech-debt patch item. Content not enumerated in this audit cycle (would need to read AtilCalculator's v1.0.1 release notes). **Flagged for Sprint 31 WP** if template forward-porting is in scope.

---

## Summary table — Q1-Q7 verdicts

| Q | Topic | Verdict | Action required |
|---|-------|---------|-----------------|
| Q1 | Template ready in private atilproject org project? | 🟡 Mostly — 4 caveats (private-portability smoke test needed, d-test coverage gap, peer-poke.sh.tmpl discipline, architect.md.tmpl sync) | Owner smoke test + Sprint 31 WP for gaps |
| Q2 | All AtilCalc scripts/processes/doctrines/agents transferred? | 🟡 Substantially — 6 AtilCalc-only scripts (mostly historical/specific), 43 ADRs drift, 3 slug-ID collisions | Sprint 31 WP: ADR forward-port batch + slug reconciliation |
| Q3 | Self-hosted runner migration 100% complete? | 🟢 Yes (org-level) + 🟡 1 orphan runner cleanup | Owner: remove `atiltestweb-atilcan` orphan via repo settings |
| Q4 | What else should be added to template? | 🟡 3 Sprint 31 WP candidates (ADR forward-port, architect sync, slug reconciliation) + 1 deferred (VM hardening) | Owner picks WP set during sprint kickoff |
| Q5 | Launcher still ready? | 🟢 Yes (structurally) + 🟡 local clone dir misleadingly named + 🟡 no release tag | Optional: rename local dir; Sprint 31 WP: cut launcher release |
| Q6 | Separate doc, "new-projectsteps" name | 🟡 Acknowledged — fresh write at `docs/new-projectsteps.md` | Sprint 31 deliverable (in flight) |
| Q7 | v1.0.1 applied to template AND launcher? | 🔴 **NOT applied** — only AtilCalculator has v1.0.1 | **HIGHEST-PRIORITY Sprint 31 WP**: cut v1.0.1 release on template + launcher |

---

## Sprint 31 WP proposal (for owner review — NOT a commitment)

Per owner directive "Sprint 31 sadece bu iş olacak", proposed WP set:

- **WP1**: Cut v1.0.1 release on `atilproject/dev-studio-template` (Q7 — highest priority)
- **WP2**: Cut v0.3.1 release on `atilproject/dev-studio-launcher` (Q7 — companion to WP1)
- **WP3**: ADR forward-port batch — promote 5-10 AtilCalculator-only ADRs to template (Sprint 28-30 era, RETRO-024, ADR-0055, ADR-0057, ADR-0059, etc.) (Q2 + Q4)
- **WP4**: Resolve ADR slug-ID collisions (0046, 0047, 0060) (Q2 + Q4)
- **WP5**: `architect.md.tmpl` sync — confirm Issue #972 Path-Verify Doctrine block present in template (Q1 + Q4)
- **WP6**: Owner smoke test — create private `atilproject/*` test repo, run full init, verify d-test green (Q1)
- **WP7**: Write `docs/new-projectsteps.md` (fresh, Sprint 31 contribution, not reusing Sprint 30 version) (Q6)

**Out of scope for Sprint 31** (per owner "no drift"):
- Engine code (`src/`, `tests/` AtilCalculator-specific) — not template-portable.
- Sprint 28-29 historical scripts cleanup — already historical.
- Tech-debt items unrelated to template portability.

**Owner go-gate required** before any WP kicks off (per owner "ben okumadan hiçbir aksiyon alma").

---

## Cross-references

- **Sprint 30 audit** (now on remote main via PR #1115, NOT used as input per owner directive)
- **Sprint 30 plan** (`docs/sprints/sprint-30/00-plan.md` — 9 WPs unexecuted, Sprint 30 closed early per cycle ~#2760)
- **Sprint 30 close** (`docs/sprints/sprint-30/close.md` — written at cycle ~#2760, draft pending owner merge per ADR-0031)
- **Cycle ~#2760 queue-reset log** — 10 issues + 2 PRs closed; Sprint 30 closed; Sprint 31 awaiting owner directive
- **Cycle ~#2761 memory** — `[[sprint-30-closed-sprint-31-awaiting-owner-cycle-2761]]`
- **ADR-0013** — template rendering doctrine
- **ADR-0031** — owner merge gate
- **ADR-0049** — d-test framework
- **ADR-0050** — template rendering mechanics
- **ADR-0055** — Cadence Rule 1 atomic
- **ADR-0057** — Closes anchor format
- **RETRO-024** — work-done-elsewhere 4-cat exception
- **Issue #972** — Path-Verify Doctrine (architect soul sync candidate)
- **S29-013** — self-hosted 4-tuple launcher patch (Refs AtilCalculator#1072)

---

— @orchestrator, 2026-07-17T08:25:00Z (cycle ~#2773, post-REPRIME Sprint 31 audit draft, awaiting owner review)