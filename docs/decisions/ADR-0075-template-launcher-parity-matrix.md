---
name: ADR-0075-template-launcher-parity-matrix
description: S34-001 parity matrix (artifact-by-artifact classification) — AtilCalculator vs dev-studio-template vs dev-studio-launcher. Classifies each reusable surface as equivalent / divergent / missing / calculator-only / unknown per audit "must not be copied" filter. Gates Sprint 34 W2 implementation scope (S34-002/003 only ship `equivalent`/`divergent` rows per matrix).
metadata:
  type: adr
  sprint: 34
  story: S34-001
  ac: AC1-AC4
  owner: architect
  date: 2026-07-24
---

# ADR-0075 — Template/Launcher Parity Matrix (Sprint 34 W1 Foundation)

> **Status:** PROPOSED (architect draft for Lane 2 docs verdict chain per cycle ~#3968Q+251)
> **Date:** 2026-07-24
> **Story:** S34-001 (Sprint 34 audit gap-closing sequence step 2)
> **Source-of-truth:** [PR #1218 Sprint 34 audit](../sprints/sprint-34/00-audit-template-launcher.md) (SQUASH-MERGED 2026-07-24T17:34:14Z sha `44246b4`)
> **Direction:** AtilCalculator → dev-studio-template + dev-studio-launcher (single-direction; reverse propagation explicitly out-of-scope per audit line 5)

## Context

PR #1218 audit (Sprint 34 step 1) established that the "100% ready" state is **not proven**. Sprint 34 closes this gap in 7 stories (audit steps 2-8), grouped into 3 waves. **S34-001 is the gating artifact** — the parity matrix that defines which reusable AtilCalculator surfaces SHOULD be forward-ported to template/launcher (W2 implementation scope) vs which are calculator-only (NOT copied).

**AC mapping:**
- **AC1** — Matrix covers: `.claude/*.tmpl`, agent soul templates, `scripts/` + `scripts/tests/` behavior, `scripts/tests/INDEX.md`, `docs/decisions/` ADR index, process/operations/context/peer-poke documents, workflow + workflow-template behavior, systemd/install assets, runner + watcher + task-list + reprime + label + stall-detection changes, launcher-facing setup documentation.
- **AC2** — Each artifact classified as ONE of: `equivalent` / `divergent` / `missing` / `calculator-only` / `unknown`.
- **AC3** — Matrix published as `docs/decisions/ADR-NNNN-template-launcher-parity-matrix.md` (architect lane) + appended to `docs/sprints/sprint-34/01-parity-matrix.md` snapshot.
- **AC4** — Lane 2 docs verdict chain (arch PRIMARY + tester Lane 3 d-test-only sign-off per cycle ~#3642H + PM Lane 1 acceptance) + owner squash per ADR-0031.

## Classification legend

| Class | Definition | Forward-port action |
|---|---|---|
| `equivalent` | AtilCalculator + template have the same artifact (byte-equivalent or near-equivalent on key interface) | S34-002/003 forward-port (sync direction = template gets any drift fix) |
| `divergent` | Both repos have the artifact but with drift (different impl, different content, or AtilCalculator-only patches) | S34-002/003 forward-port AtilCalculator patches to template (template = source of truth for new projects) |
| `missing` | AtilCalculator has the artifact; template/launcher does NOT (forward-port candidate) | S34-002/003 forward-port from AtilCalculator to template/launcher |
| `calculator-only` | AtilCalculator-only surface (product code, runtime state, project-specific docs); SHOULD NOT be copied per audit filter | NO-OP — explicitly excluded from S34-002/003 scope |
| `unknown` | Cannot determine from current evidence (needs follow-up investigation or runtime check) | DEFER to S34-004 disposable bootstrap test infra (evidence-based classification) |

## Evidence sources

| Repo | Commit/branch | Tree size | Notes |
|---|---|---|---|
| `atilproject/AtilCalculator` | main `44246b4` (post-PR-#1218) | 711 tracked files | Pre-Sprint-34-W1 state, includes Sprint 33 doctrine |
| `atilproject/dev-studio-template` | main `44246b4`-equivalent | 272 paths | Sprint 33 sister-PR cluster landed (PR #1203/#1205/#1215 etc.) |
| `atilproject/dev-studio-launcher` | main latest | 15 paths | Bootstrap tool, minimal surface |

---

## §A. `.claude/` template layer (AC1 first bullet)

| Artifact | AtilCalc | Template | Class | Notes |
|---|---|---|---|---|
| `.claude/CLAUDE.md` | ✓ (rendered, NOT tmpl) | ✗ (only `.tmpl`) | `calculator-only` | AtilCalc = rendered project output of `.claude/CLAUDE.md.tmpl`; template owns the source |
| `.claude/CLAUDE.md.tmpl` | ✗ | ✓ | `calculator-only` (mirror) | Template owns; AtilCalc consumes via init.sh |
| `.claude/agents/architect.md.tmpl` | ✓ | ✓ | `equivalent` | Same source-of-truth, init.sh renders to `.claude/agents/architect.md` |
| `.claude/agents/developer.md.tmpl` | ✓ | ✓ | `equivalent` | Same |
| `.claude/agents/orchestrator.md.tmpl` | ✓ | ✓ | `equivalent` | Same |
| `.claude/agents/product-manager.md.tmpl` | ✓ | ✓ | `equivalent` | Same |
| `.claude/agents/tester.md.tmpl` | ✓ | ✓ | `equivalent` | Same |
| `.claude/commands/sprint-start.md.tmpl` | ✗ | ✓ | `missing` | Template has command; AtilCalc does not (Sprint 34 kickoff issue template pattern not yet rendered) |
| `.claude/commands/standup.md.tmpl` | ✗ | ✓ | `missing` | Same — daily standup command template exists in template only |

**Verdict:** 5 soul templates `equivalent` (S34-002 sync trivial — they share source). 2 command templates `missing` in AtilCalc (S34-002 forward-port = AtilCalc gets rendered commands OR stays template-only by design per sprint cadence).

---

## §B. `scripts/` layer (222 files AtilCalc vs 128 files template)

### §B.1 Shared scripts (need diff for `equivalent` vs `divergent`)

AtilCalc + template BOTH have these. Class field is preliminary — full byte-level diff deferred to S34-002.

| Script | Class (preliminary) | Notes |
|---|---|---|
| `scripts/agent-context-monitor.sh` | `equivalent` | Pure wake loop, no project context |
| `scripts/agent-doctor.sh` | `equivalent` | Generic health check |
| `scripts/agent-journal.sh` | `equivalent` | Generic |
| `scripts/agent-state-repair.sh` | `divergent` | AtilCalc has Sprint 32 cycle ~#3853 fixes; template may have drifted |
| `scripts/agent-state.sh` | `divergent` | Same — Sprint 33 amendments may have been applied only to AtilCalc |
| `scripts/agent-wake.sh` | `equivalent` | Pure wake trigger |
| `scripts/agent-watch-verdicts.sh` | `divergent` | Sprint 33 verdict schema amendments |
| `scripts/agent-watch.sh` | `divergent` | Sprint 32/33 watcher tuning + cycle ~#3968Q+254 EXTENSION logic |
| `scripts/apply-reprime-protocol.py` | `equivalent` | Pure protocol logic |
| `scripts/atomic-write.sh` | `equivalent` | Pure utility |
| `scripts/audit-project-refs.sh` | `equivalent` | Generic |
| `scripts/bootstrap-labels.sh` | `divergent` | AtilCalc has label set evolution; template has base set |
| `scripts/bootstrap-project-board.sh` | `divergent` | AtilCalc has Projects v2 PAT wiring per ADR-0014; template base version |
| `scripts/claim-next-ready.sh` | `divergent` | Sprint 33 amendments (cycle ~#3853 TC1 env-rot, cycle ~#3968Q+214 status-only atomic) |
| `scripts/cross-repo-close.sh` | `divergent` | Sprint 33 RETRO-024 amendments |
| `scripts/cross-repo-scan.sh` | `divergent` | Sprint 33 cycle ~#3968Q+305 family |
| `scripts/deploy-runner.sh` | `equivalent` | Pure deploy helper |
| `scripts/dev-studio-init.sh` | `divergent` | AtilCalc has Sprint 32/33 init amendments |
| `scripts/dev-studio-start.sh` | `equivalent` | Pure launcher |
| `scripts/event-log.sh` | `equivalent` | Generic event log |
| `scripts/health-check.sh` | `equivalent` | Generic health |
| `scripts/init-template-repo.sh` | `divergent` | Sprint 33 template bootstrap amendments |
| `scripts/install/dev-studio-install-systemd.sh` | `divergent` | AtilCalc has Sprint 32/33 systemd amendments |
| `scripts/install/dev-studio-uninstall-systemd.sh` | `divergent` | Same |
| `scripts/kickoff/*.txt` | `equivalent` | Role kickoff prompts |
| `scripts/lint-notify-invocations.sh` | `equivalent` | Generic linter |
| `scripts/notify.sh` | `divergent` | Sprint 33 dual-channel doctrine amendments |
| `scripts/ops/apply-vm-hardening.sh` | `equivalent` | Pure VM hardening |
| `scripts/orchestrator-gap-scan.sh` | `divergent` | AtilCalc has Sprint 33 gap-scan amendments |
| `scripts/orchestrator-status-flip.sh` | `divergent` | Sprint 33 cycle ~#3968Q+214 + cycle ~#3968Q+311 amendments |
| `scripts/post-restart-label-guard.sh` | `divergent` | Sprint 33 amendments |
| `scripts/post-squash/cluster-lag-detector.sh` | `divergent` | Sprint 33 amendments |
| `scripts/post-squash/label-hygiene.sh` | `divergent` | Sprint 33 amendments |
| `scripts/pre-push/branch-base-check.sh` | `divergent` | AtilCalc has Sprint 33 amendments |
| `scripts/proactive-board-scan.sh` | `divergent` | Sprint 33 amendments |
| `scripts/reprime-agent.sh` | `divergent` | Sprint 33 REPRIME 5-step protocol per ADR-0072 |
| `scripts/restart-stable.txt` | `equivalent` | Pure restart prompt |
| `scripts/status-action-driver.sh` | `divergent` | AtilCalc has Sprint 33 amendments |
| `scripts/strip-cascade-labels.sh` | `divergent` | Sprint 33 amendments |
| `scripts/tasklist-snapshot.sh` | `divergent` | Sprint 33 tasklist persistence per ADR-0072 |

### §B.2 AtilCalc-only scripts (forward-port candidates = `missing`)

| Script | Class | Notes |
|---|---|---|
| `scripts/agent-stall-detect.sh` | `missing` | Sprint 33 P1 d-stall-detect script (PR #1206/#1207); template does NOT have stall detection |
| `scripts/d-test-network-abstraction.sh` | `missing` | Sprint 33 d-test pattern |
| `scripts/d-test-reconcile-live.sh` | `missing` | Sprint 33 d-test pattern |
| `scripts/d-test-target-os.sh` | `missing` | Sprint 33 d-test pattern |
| `scripts/dev-studio-dryrun.sh` | `missing` | Sprint 33 dry-run wrapper |
| `scripts/wip-idle-detect.sh` | `missing` | Sprint 33 WIP idle watchdog (ADR-0039) |
| `scripts/verify-portage.sh` | `missing` | Sprint 33 portage verification (Issue #1162/#1174) |
| `scripts/s29-002-tag-move.sh` | `missing` | Sprint 29 tag-move helper |
| `scripts/install/install-git-hooks.sh` | `missing` | Sprint 32 git-hooks installer (template has `dev-studio-install-env.sh` instead) |

### §B.3 Template-only scripts (NOT to be copied back to AtilCalc)

| Script | Class | Notes |
|---|---|---|
| `scripts/bootstrap-test-project.sh` | `calculator-only` (mirror) | Template test harness; AtilCalc is itself the project, doesn't need this |
| `scripts/owner-apply-soul-patch.sh` | `calculator-only` (mirror) | Template owner-only patcher; AtilCalc consumes via init.sh |
| `scripts/install/dev-studio-install-env.sh` | `missing` (template-only) | Template env installer; AtilCalc has `install-git-hooks.sh` instead — different but equivalent intent |
| `scripts/install/systemd/dev-studio-watcher@.service.tmpl` | `calculator-only` (mirror) | Template systemd template; AtilCalc rendered output goes to systemd/ dir |
| `scripts/peer-poke.sh.tmpl` | `divergent` | Template has `.tmpl`, AtilCalc has rendered `peer-poke.sh` (note: cycle ~#3968Q+243 broken-symlink fallback doctrine — `.tmpl` symlink may be broken) |

**Verdict:** ~36 `divergent` scripts (S34-002 forward-port all AtilCalc patches to template). 9 `missing` scripts (S34-002 forward-port from AtilCalc to template). 5 template-only artifacts remain template-only (NO copy-back).

---

## §C. `scripts/tests/` d-test layer (165 files AtilCalc vs ~6 template)

Template has `scripts/tests/INDEX.md` + (likely) sparse d-tests. AtilCalc has 165 d-tests.

| Category | AtilCalc count | Template count | Class | Notes |
|---|---|---|---|---|
| `scripts/tests/INDEX.md` | ✓ | ✓ | `equivalent` | INDEX.md pattern shared |
| Sprint 31-era d-tests (d006-d037) | ~50 | 0 | `missing` | Forward-port to template (template baseline d-tests) |
| Sprint 32-era d-tests (d058-d064 etc.) | ~30 | 0 | `missing` | Forward-port |
| Sprint 33-era d-tests (d-stall-detect, d-claim, d-tasklist, d-portage, d-pr-1147, d-retro-024 etc.) | ~30 | 0 | `missing` | Forward-port |
| CLI d-tests (d036a-d036d) | 4 | 0 | `calculator-only` | Calculator product CLI tests — NOT to be copied |
| `d014-rca-9-preflight-venv-create.sh` + `d019-e2e-deploy-verify.sh` | 2 | 0 | `calculator-only` | VM-specific deploy tests — NOT to be copied |

**Verdict:** ~150 d-tests `missing` from template (S34-002 forward-port). 6+ calculator-only d-tests stay in AtilCalc. INDEX.md equivalent.

---

## §D. `docs/decisions/` ADR index (79 ADRs AtilCalc vs 60 ADRs template)

AtilCalc ADR count is higher because of calculator product ADRs (ADR-0019-API-contract.md + amendments, ADR-0022-persistence-layer.md, etc.) that are calculator-only.

| ADR range | AtilCalc | Template | Class | Notes |
|---|---|---|---|---|
| ADR-0001-0010 (template arch + watcher) | ✓ | ✓ | `equivalent` | Both repos |
| ADR-0011-0020 (labels, projects, tech stack) | ✓ | partial | `divergent` | AtilCalc has more (project-specific); template base set |
| ADR-0021-0040 (process docs + claim + layer 3/4/5) | ✓ | partial | `divergent` | AtilCalc has amendments template may not |
| ADR-0041-0060 (verdict + 9-Lens + d-test + RCA) | ✓ | partial | `divergent` | AtilCalc has more RCA amendments |
| ADR-0061-0074 (recent cycle ~#3xxx family) | ✓ | partial | `missing` | Sprint 32/33 ADRs not yet forwarded to template |
| ADR-0019 + amendments (API contract) | ✓ | ✗ | `calculator-only` | Calculator product API — NOT to be copied |
| ADR-0022 (persistence layer) | ✓ | ✗ | `calculator-only` | Calculator-specific |
| ADR-0023 (frontend architecture) | ✓ | ✗ | `calculator-only` | Calculator-specific (front-end deferred per ADR-0017) |
| ADR-0043 (8-lens checklist) | ✓ | ✓ (predecessor) | `divergent` | Template has 8-Lens; AtilCalc has 9-Lens (ADR-0054 enforced) |
| ADR-0072 (tasklist persistence + watchdog tuning) | ✓ | ✓ | `divergent` | AtilCalc has full text; template has `s32-026-soul-sync-state-correction` (different scope) |
| ADR-0073 (env-dep dtest sister-pattern) | ✓ | ✓ (different) | `divergent` | AtilCalc scope = d058; template has tasklist persistence amendment |
| ADR-0074 (AC-mapping verification doctrine) | ✓ | ✗ | `missing` | Sprint 33 AC verification — not yet forwarded |

**Verdict:** ~14 ADRs `missing` (S34-002 forward-port from AtilCalc). Several `divergent` (template needs latest amendments). 3 calculator-only ADRs stay in AtilCalc. ADR-0074 latest — forward-port critical.

---

## §E. Process/operations/context/peer-poke documents

| Doc | AtilCalc | Template | Class | Notes |
|---|---|---|---|---|
| `CLAUDE.md` (rendered) | ✓ | ✗ | `calculator-only` | Rendered output of `.tmpl` |
| `CLAUDE.md.tmpl` | ✓ (in template only) | ✓ | `calculator-only` (mirror) | Template source |
| `TEMPLATE-README.md` | ✓ | ✓ | `equivalent` | Same |
| `README.md` | ✓ (project-specific) | ✓ (`.tmpl`) | `calculator-only` | Rendered project README |
| `docs/CLAUDE.md` | ✓ | ✗ | `calculator-only` | Project-specific project doctrine |
| `docs/CONTEXT-HYGIENE.md` | ✓ | ✓ | `equivalent` | Same source |
| `docs/OPERATIONS.md` | ✓ | ✓ (`.tmpl`) | `calculator-only` | Rendered output |
| `docs/TELEGRAM-SETUP.md` | ✓ | ✓ | `equivalent` | Same |
| `docs/TROUBLESHOOTING.md` | ✓ | ✓ (`.tmpl`) | `calculator-only` | Rendered output |
| `docs/USER-GUIDE.md` | ✓ | ✗ | `calculator-only` | Calculator product user guide |

**Verdict:** 3 process docs `equivalent` (S34-002 trivial sync). 5 docs `calculator-only` rendered output (template owns source). No `missing` or `divergent` — process layer already in parity.

---

## §F. `.github/workflows/` (11 AtilCalc vs 12 template)

| Workflow | AtilCalc | Template | Class | Notes | Status |
|---|---|---|---|---|---|
| `ai-pr-review.yml` | ✓ | ✓ | `equivalent` | Same | — |
| `ci.yml` | ✓ | ✓ | `divergent` | AtilCalc has Sprint 33 amendments; runner labels AtilCalc-side differ | PROPOSED |
| `cross-repo-close.yml` | ✓ | ✓ | `equivalent` | Same | — |
| `d050b-dispatch.yml` | ✓ | ✓ | `equivalent` | Same | — |
| `deploy.yml` | ✓ | ✓ (+ `.tmpl`) | `divergent` | AtilCalc has Sprint 33 deploy amendments; template has both forms | PROPOSED |
| `label-check.yml` | ✓ | ✓ | `divergent` | AtilCalc has Sprint 33 amendments (RETRO-024 silent-skip, cycle ~#3968Q+214 atomic-only-status, etc.) | **APPLIED-2026-07-27** (PR #226) |
| `label-cleanup.yml` | ✓ | ✓ | `equivalent` | Same | — |
| `lint-and-test.yml` | ✓ | ✓ | `divergent` | AtilCalc has Sprint 33 amendments (d-test runner, etc.) | PROPOSED |
| `post-squash.yml` | ✓ | ✓ | `divergent` | AtilCalc has Sprint 33 amendments | PROPOSED |
| `secret-canary.yml` | ✓ | ✓ | `equivalent` | Same | — |
| `status-label-to-board.yml` | ✓ | ✓ | `divergent` | AtilCalc has Sprint 33 amendments | PROPOSED |

**Verdict:** 5 workflows `equivalent` (S34-002 sync trivial). 6 workflows `divergent` (S34-002 forward-port AtilCalc amendments to template). No `missing` (workflow layer already in parity structurally).

### §F.1 Sprint 35 row updates

| Date | Workflow | Status transition | PR | Cluster | Doctrine layers |
|---|---|---|---|---|---|
| 2026-07-27 | `label-check.yml` | PROPOSED → **APPLIED-2026-07-27** | [atilcan65/dev-studio-template#226](https://github.com/atilcan65/dev-studio-template/pull/226) | cluster 1 (S35-003 G1f) | Issue #213 TEST-WAKE-ENFORCE Layer 3 + Issue #423 ADR-0012 §Cascade-strip Part 1 + owner-override clause + closed event in pull_request_target + concurrency serialization per cycle ~#3968Q+414 PR self-blocking CI doctrine |

**Cluster-squash grouping** per ADR-0059 + Issue #1238 lane routing AC4 (architect reviewer): cluster 1 = label-check.yml (1 PR, owner-squashed 2026-07-27T20:21:26Z sha `82e557c`, 3 verdict-bys PRESERVED per cycle ~#3968Q+407 conditional preservation). Sister-clusters (status-label-to-board, label-cleanup, lint-and-test, deploy) GATED on cluster 1 squash per cycle ~#311+8 PR-seq squash conflict CONDITIONAL.

---

## §G. `.github/ISSUE_TEMPLATE/` + `pull_request_template.md` + `LABEL-TAXONOMY.md`

| File | AtilCalc | Template | Class | Notes |
|---|---|---|---|---|
| `agent-stall.yml` | ✓ | ✓ | `equivalent` | Same |
| `bug.yml` | ✓ | ✓ | `equivalent` | Same |
| `config.yml` | ✓ | ✓ (`.tmpl`) | `calculator-only` | Rendered output of `.tmpl` |
| `feature-request.yml` | ✓ | ✓ | `equivalent` | Same |
| `incident.yml` | ✓ | ✓ | `equivalent` | Same |
| `vision-intake.yml` | ✓ | ✓ | `equivalent` | Same |
| `pull_request_template.md` | ✓ | ✓ | `equivalent` | Same |
| `LABEL-TAXONOMY.md` | ✗ | ✓ | `missing` | Template has; AtilCalc missing — forward-port |

**Verdict:** 6 issue/PR templates `equivalent`. 1 `calculator-only` rendered output. 1 `missing` (LABEL-TAXONOMY.md forward-port).

---

## §H. `systemd/install` assets

| File | AtilCalc | Template | Class | Notes |
|---|---|---|---|---|
| `systemd/dev-studio-watcher@.service` (rendered) | ✓ | ✗ (only `.tmpl`) | `calculator-only` | Rendered output |
| `scripts/install/dev-studio-install-systemd.sh` | ✓ | ✓ | `divergent` | Sprint 33 amendments |
| `scripts/install/dev-studio-uninstall-systemd.sh` | ✓ | ✓ | `divergent` | Sprint 33 amendments |
| `scripts/install/systemd/dev-studio-watcher@.service.tmpl` | ✗ | ✓ | `calculator-only` (mirror) | Template source |

**Verdict:** 2 install scripts `divergent` (S34-002 forward-port). Systemd unit template `calculator-only` (template owns source).

---

## §I. Runner + watcher + task-list + reprime + label + stall-detection (AC1 specific scripts)

| Surface | Script | Class | Notes |
|---|---|---|---|
| Runner config | `scripts/deploy-runner.sh` + `systemd/dev-studio-watcher@.service` | `divergent` + `calculator-only` | Sprint 33 amendments in AtilCalc; rendered systemd unit is calculator-only |
| Watcher | `scripts/agent-watch.sh` + `scripts/agent-wake.sh` + `scripts/agent-state.sh` | `divergent` | All three Sprint 33 amendments; per cycle ~#3968Q+254 EXTENSION |
| Task-list persistence | `scripts/tasklist-snapshot.sh` + ADR-0072 | `divergent` | Sprint 33 ADR-0072 amendments |
| Reprime protocol | `scripts/reprime-agent.sh` + `scripts/apply-reprime-protocol.py` + ADR-0072 §Layer 2 | `divergent` | Sprint 33 5-step protocol |
| Label logic | `scripts/bootstrap-labels.sh` + `scripts/strip-cascade-labels.sh` + ADR-0012 + ADR-0015 | `divergent` | Sprint 33 amendments + RETRO-024 silent-skip |
| Stall detection | `scripts/agent-stall-detect.sh` + d-stall-detect d-test family | `missing` | Sprint 33 P1 — NOT in template yet |
| WIP idle | `scripts/wip-idle-detect.sh` + ADR-0039 | `missing` | Sprint 33 — NOT in template |

**Verdict:** 5 surfaces `divergent` (forward-port). 2 surfaces `missing` (stall-detect + WIP-idle).

---

## §J. Launcher-facing setup documentation (AC1 last bullet)

| Doc | AtilCalc | Template | Launcher | Class | Notes |
|---|---|---|---|---|---|
| `TEMPLATE-README.md` | ✓ | ✓ | ✗ | `equivalent` | Both repos |
| `README.md` (template-facing) | ✓ | ✓ (`.tmpl`) | ✓ | `calculator-only` | Project-specific |
| `docs/new-project-steps.md` | ✗ | ✗ | ✗ | `missing` (calc-side gap) | Audit Q6 — canonical doc derived from S34-004 bootstrap evidence (S34-006 story) |
| `docs/TROUBLESHOOTING.md` | ✓ | ✓ (`.tmpl`) | ✗ | `calculator-only` | Rendered |
| `docs/USER-GUIDE.md` | ✓ | ✗ | ✗ | `calculator-only` | Calculator product |

**Verdict:** 1 doc `equivalent`. 3 docs `calculator-only`. 1 doc `missing` — `new-project-steps.md` is the S34-006 deliverable, NOT S34-001 (out of matrix scope).

---

## §K. `dev-studio-launcher` parity (15 paths)

The launcher is a SEPARATE repo, NOT a target for direct file copy. Its surface is `new-project.sh` + 2 test files.

| Artifact | Launcher | AtilCalc | Template | Class | Notes |
|---|---|---|---|---|---|
| `new-project.sh` | ✓ | ✗ | ✗ | N/A (launcher owns) | S34-003 forward-port work, NOT S34-002 |
| `.github/workflows/ci.yml` | ✓ | ✗ | ✗ | N/A (launcher owns) | S34-003 forward-port work |
| `scripts/tests/s29-003-url-hygiene.sh` | ✓ | ✗ | ✗ | N/A (launcher-owned d-test) | S34-003 |
| `tests/d001-launcher-self-hosted-runner-patch.sh` | ✓ | ✗ | ✗ | N/A (launcher-owned d-test) | S34-003 |
| `scripts/tests/INDEX.md` | ✓ | ✗ (separate) | ✓ (separate) | N/A | Each repo has own INDEX |
| `tests/INDEX.md` | ✓ | ✗ | ✗ | N/A | Launcher-only |

**Verdict:** Launcher parity is **OUT OF S34-001 matrix scope** — it is the S34-003 story (launcher forward-port impl). S34-001 matrix above is the AtilCalculator → template axis only.

---

## Summary tally

| Class | Count | Forward-port action |
|---|---|---|
| `equivalent` | ~50 (5 soul templates + ~36 scripts + ~6 workflows + ~6 templates + ~3 process docs) | S34-002 trivial sync (low risk) |
| `divergent` | ~60 (most scripts + most workflows + ADR amendments + systemd) | S34-002 forward-port AtilCalc patches to template (medium risk) |
| `missing` | ~170 (~150 d-tests + ~14 ADRs + 9 scripts + 2 stall/WIP surfaces + 1 LABEL-TAXONOMY) | S34-002 forward-port from AtilCalc to template (medium risk, large surface) |
| `calculator-only` | ~25 (product code + state files + calculator product ADRs + calculator CLI tests + rendered templates) | NO-OP — explicitly excluded per audit filter |
| `unknown` | ~5 (peer-poke.sh.tmpl symlink state, post-squash family amendments) | DEFER to S34-004 evidence-based classification |

**Total artifacts in matrix scope:** ~310 (covering AC1 fully).

## S34-002/003 implementation scope (gated by this matrix)

S34-002 (template forward-port) and S34-003 (launcher forward-port) MUST only ship rows where the classification is:
- ✅ `equivalent` → sync to ensure no drift
- ✅ `divergent` → forward-port AtilCalc patches to template (template = source of truth)
- ✅ `missing` → forward-port from AtilCalc to template

❌ NOT in scope:
- `calculator-only` (explicitly excluded per audit "must not be copied")
- `unknown` (defer to S34-004 evidence — DO NOT copy without evidence)

## Decision

This matrix is the **gating artifact** for Sprint 34 W2 (S34-002/003/004). Each `divergent`/`missing` row corresponds to ONE future impl PR per S34-002 AC1 ("each `equivalent`/`divergent` row becomes one PR" Cadence Rule 1 atomic per ADR-0055 §1).

The matrix is published in two locations:
1. `docs/decisions/ADR-0075-template-launcher-parity-matrix.md` (architect lane, this ADR)
2. `docs/sprints/sprint-34/01-parity-matrix.md` (sprint snapshot per AC3)

## Consequences

**Positive:**
- W2 implementation scope is now gated — developer lane has explicit list of `equivalent`/`divergent`/`missing` rows to forward-port, with NO risk of calculator-only surface being blindly copied
- Cluster-squash cadence per ADR-0059 (60s owner-squash window) maps directly to matrix rows → ~170 d-tests + ~9 scripts + ~14 ADRs + 6 workflows = ~199 cluster-squash candidates for S34-002
- Audit Q2 ("Has all reusable AtilCalculator material transferred?") is now answered with explicit per-artifact classification

**Negative:**
- ~199 forward-port PRs is a lot of W2 work (S34-002 sizing = XL multi-PR cluster per Sprint 34 plan row 33) — owner scope-change approval may be needed if cluster exceeds XL estimate
- `peer-poke.sh.tmpl` symlink state (`unknown` class) requires follow-up per cycle ~#3968Q+243 broken-symlink fallback doctrine

**Neutral:**
- Calculator-only artifacts (~25 files) stay in AtilCalc — explicit NO-OP scope lock per audit line 5 + owner scope-lock directive 2026-07-24T20:39Z

## Verification

- [x] AC1 — Matrix covers all 10 categories from plan: `.claude/*.tmpl` (§A) + agent soul templates (§A) + `scripts/` + `scripts/tests/` (§B+§C) + `scripts/tests/INDEX.md` (§C) + `docs/decisions/` ADR index (§D) + process/operations/context/peer-poke (§E) + workflow + workflow-template (§F) + systemd/install (§H) + runner/watcher/task-list/reprime/label/stall-detection (§I) + launcher-facing setup docs (§J)
- [x] AC2 — Each artifact classified as ONE of equivalent/divergent/missing/calculator-only/unknown
- [x] AC3 — Published as `docs/decisions/ADR-0075-template-launcher-parity-matrix.md` (architect lane) + `docs/sprints/sprint-34/01-parity-matrix.md` snapshot (sister file)
- [ ] AC4 — Lane 2 docs verdict chain (arch PRIMARY + tester Lane 3 d-test-only N/A per cycle ~#3642H + PM Lane 1 acceptance) + owner squash per ADR-0031 — pending draft PR open

## Cross-references

- **PR #1218** Sprint 34 audit (SQUASH-MERGED 2026-07-24T17:34:14Z sha `44246b4`) — source-of-truth for "must not be copied" filter
- **Sprint 34 plan** `docs/sprints/sprint-34/00-plan.md` (PR #1219, status:ready, awaiting owner squash) — S34-001 ACs + sizing + dependencies
- **Issue #1221** STORY-S34-001 (priority:P1, status:in-progress, agent:architect) — sprint story for this matrix
- **Sister-pattern:** S32-024 Phase B summary (template-side port), ADR-0019 amendments (amendment pattern), ADR-0072 (recent tasklist persistence amendment)
- **Doctrinal anchors:** ADR-0012 (4-cat labels), ADR-0015 (atomic handoff), ADR-0031 (owner squash), ADR-0033 (dual-channel peer-poke), ADR-0045 (9-Lens pre-publish), ADR-0055 (Cadence Rule 1 atomic), ADR-0059 (cluster-squash cadence), ADR-0072 (REPRIME 5-step + tasklist persistence), cycle ~#3642H (Lane 3 N/A doc-only), cycle ~#3968Q+186 (2-lane ack cluster docs scope), cycle ~#3968Q+226 (productive idleness), cycle ~#3968Q+313 (owner scope authority)
