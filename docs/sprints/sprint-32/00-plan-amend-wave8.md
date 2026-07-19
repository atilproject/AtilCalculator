# Sprint 32 — Wave 8+ Scope-Override (Owner-Directive, cycle ~#3889Q)

> **Origin**: Owner directive @ 2026-07-19T17:49:00+03:00 — "bu işlern hepsini bu sprinte al, sprint 33 e istemiyorum, benim direktifim zaten hepsinin bu sprintte olmasıydı, override edilmiş. hemen al".
> **Supersedes**: Sprint 32 close ceremony (Issue #1163, PR #1167 MERGED @ 2026-07-19T11:36:50Z, cycle ~#3748 terminal) — Sprint 32 REOPENED as Wave 8+ extension.
> **PM lane ack**: peer-poke sent cycle ~#3889Q, awaiting acknowledgment per cycle ~#3511 reciprocity.

---

## Why this amendment exists

Sprint 32 closed terminal at cycle ~#3748 with 24 stories across 6 waves + Wave-extension impl chain (PR #1172 + #189 + #192 merged). Cluster-squash queue: 3/4 TERMINAL, PR #1173 deferred pending d058 env-rot fix (Issue #1174).

Owner-directive cycle ~#3889Q explicitly overrides Sprint 33+ deferral patterns on all remaining org-wide open gap-closing work. This is a **scope-owner directive** — Sprint scope changes are normally soul-level decisions per CLAUDE.md §Auto-Ping Hard-Rule, but owner-directive is the explicit exception.

---

## Scope inventory (17 open org-wide issues)

### P1 — BLOCKS existing work

| # | Issue | Title | Repo | Agent | Why P1 |
|---|---|---|---|---|---|
| 1 | [calc#1174](https://github.com/atilproject/AtilCalculator/issues/1174) | d058 CI env-rot regression on PR #1173 | AtilCalculator | tester | **Blocks PR #1173 squash** → unblocks Issue #1169 close |
| 2 | [tmpl#165](https://github.com/atilproject/dev-studio-template/issues/165) | S32-027-D: 10 HYBRID ADR amendments (calc→tmpl parent-§Amendments fold) | dev-studio-template | architect | Cadence Rule 2 cleanup (P1 sister-pattern) |
| 3 | [tmpl#164](https://github.com/atilproject/dev-studio-template/issues/164) | S32-027-B: 7 DEFERRED ADR renumberings (calc→tmpl gap-closing follow-up) | dev-studio-template | architect | Cadence Rule 2 cleanup (in-progress, P1) |

### P1 — Direct sprint scope (impl cluster)

| # | Issue | Title | Repo | Agent | Lane |
|---|---|---|---|---|---|
| 4 | [calc#1169](https://github.com/atilproject/AtilCalculator/issues/1169) | S32-XXX-C [DEV]: Task-list persistence + watchdog tuning forward-port (calc mirror) | AtilCalculator | developer | impl cluster (was Wave-extension, deferred d058) |
| 5 | [tmpl#162](https://github.com/atilproject/dev-studio-template/issues/162) | S32-024 [DEV]: New project bootstrap dry-run (end-to-end Sprint 32 verification) | dev-studio-template | developer | Q-cluster verification |
| 6 | [tmpl#160](https://github.com/atilproject/dev-studio-template/issues/160) | S32-020 [DEV]: Verify smoke repo (new project) bootstraps at v1.1.0 (Q7 verification) | dev-studio-template | developer | Phase B (was blocked) |

### P2 — S32-021 sister sweep (8 issues, owner-directive Sprint 32)

| # | Issue | Title | Lane |
|---|---|---|---|
| 7 | [tmpl#180](https://github.com/atilproject/dev-studio-template/issues/180) | S32-021 sister: d068b P1 — agent-wake.sh:87 env-override sleep forward-port | developer |
| 8 | [tmpl#179](https://github.com/atilproject/dev-studio-template/issues/179) | S32-021 sister: d028 P1 — agent-watch.sh queue check filters forward-port | developer |
| 9 | [tmpl#178](https://github.com/atilproject/dev-studio-template/issues/178) | S32-021 sister: d024 P1 — agent-wake.sh role→pane index map forward-port | developer |
| 10 | [tmpl#176](https://github.com/atilproject/dev-studio-template/issues/176) | S32-021 sister: Forward-port d-pr-1147-install-test-flake to tmpl (Issue #161 AC4 deferral) | developer |
| 11 | [tmpl#175](https://github.com/atilproject/dev-studio-template/issues/175) | S32-021 sister: d068b P1 — agent-wake.sh:87 env-override sleep forward-port (DUPE sister) | developer |
| 12 | [tmpl#174](https://github.com/atilproject/dev-studio-template/issues/174) | S32-021 sister: d028 P1 — agent-watch.sh queue check filters forward-port (DUPE sister) | developer |
| 13 | [tmpl#173](https://github.com/atilproject/dev-studio-template/issues/173) | S32-021 sister: d024 P1 — agent-wake.sh role→pane index map forward-port (DUPE sister) | developer |
| 14 | [tmpl#171](https://github.com/atilproject/dev-studio-template/issues/171) | S32-021 sister: Forward-port d-pr-1147-install-test-flake to tmpl (Issue #161 AC4 deferral DUPE) | developer |

> **DUPE warning**: tmpl#175/174/173/171 appear to be duplicates of tmpl#180/179/178/176 (Cycle ~#3471 d-test sweep). PM lane should dedupe before dev pickup — verify Issue bodies before dispatch.

### P2 — Orchestrator lane

| # | Issue | Title | Repo | Agent |
|---|---|---|---|---|
| 15 | [calc#1171](https://github.com/atilproject/AtilCalculator/issues/1171) | S32-XXX-F [ORCH]: RETRO + Sprint 32 close — Watchdog tuning + task-list persistence evolution capture | AtilCalculator | orchestrator |

### P3 — Launcher lane (deferred OK per lane priority)

| # | Issue | Title | Repo | Agent |
|---|---|---|---|---|
| 16 | [launcher#14](https://github.com/atilproject/dev-studio-launcher/issues/14) | S32-XXX-D [DEV]: Task-list persistence launcher doc-only sync (v0.4.0 → v0.4.1) | dev-studio-launcher | developer |

### PR-side (already-open impls, owner-decision gated)

| # | PR | Title | Repo | Agent | State |
|---|---|---|---|---|---|
| 17 | [calc#1173](https://github.com/atilproject/AtilCalculator/pull/1173) | feat(scripts): Issue #1169 S32-XXX-C task-list persistence + watchdog tuning forward-port | AtilCalculator | developer | OPEN, status:blocked (d058 fix pending) |

---

## Wave 8+ sequencing (priority-ordered, WIP cap=2 per ADR-0038)

### Wave 8.0 — Unblock existing cluster (1 story)

- **calc#1174** (d058 fix) → tester pickup → dev fix → re-verify → unblocks PR #1173 squash
- Critical path: tester → dev → re-verify → owner squash → Issue #1169 close
- Lane assignment: **tester** (1 slot)

### Wave 8.1 — Cadence Rule 2 cleanup (2 stories)

- **tmpl#165** (10 HYBRID ADR amendments, calc→tmpl parent-§Amendments fold) — architect
- **tmpl#164** (7 DEFERRED ADR renumberings, already in-progress) — architect
- Lane assignment: **architect** (1 slot, sequential)

### Wave 8.2 — Impl cluster re-engagement (3 stories)

- **calc#1169** (S32-XXX-C impl forward-port) — re-engages after Wave 8.0 d058 fix
- **tmpl#162** (S32-024 bootstrap dry-run)
- **tmpl#160** (S32-020 Q7 verify smoke repo)
- Lane assignment: **developer** (2 slots max, sequential after Wave 8.0)

### Wave 8.3 — S32-021 sister sweep (8 stories, sub-batched)

- **tmpl#180, #179, #178, #176** (unique sisters, dev lane)
- **tmpl#175, #174, #173, #171** (DUPE sisters — PM dedupe first, then dev lane)
- Lane assignment: **developer** (2 slots, sub-batched Wave 8.3.1 / 8.3.2 / 8.3.3 / 8.3.4)

### Wave 8.4 — Orchestrator lane (1 story)

- **calc#1171** (S32-XXX-F RETRO + Sprint 32 close evolution capture)
- Lane assignment: **orchestrator** (already in-progress)

### Wave 8.5 — Launcher lane (deferred per owner priority, 1 story)

- **launcher#14** (S32-XXX-D doc sync, P3)
- Lane assignment: **developer** (cross-repo, can run parallel with Wave 8.3)

---

## WIP cap awareness (ADR-0038 §Auto-Claim)

| Role | WIP cap | Current load | Wave 8+ assignment |
|---|---|---|---|
| tester | 2 | 1 (#1174) | #1174 slot 1 |
| developer | 2 | 1 (PR #1173 slot 1) | +#1169, #162, #160, +sisters (max 2 active) |
| architect | 2 | 0 | #165, #164 |
| orchestrator | 2 | 1 (#1171) | #1171 |
| product-manager | 2 | 0 | Sprint scope-change ack |

Dev lane is the **tightest constraint** — 4 unique stories + 8 sisters = must sub-batch across Waves 8.2 / 8.3.

---

## Acceptance criteria for Wave 8+ close

1. All 17 issues reach terminal `status:done` OR explicitly re-deferred with owner ack (cycle ~#3671 non-reflexive)
2. PR #1173 squash completes (after Wave 8.0 d058 fix) → Issue #1169 closes
3. Sprint 32 close.md + RETRO-032 updated to reflect Wave 8+ extension
4. Sprint 33 plan.md NOT authored until Wave 8+ closes (per cycle ~#3258 wave-vs-cluster-squash cadence)
5. WIP cap=2 respected across all lanes (no cap-break without explicit owner override)

---

## Sister-pattern / cross-references

- ADR-0038 §Auto-Claim (WIP cap=2)
- ADR-0044 RED-first TDD (tester before dev on d058 fix)
- ADR-0049 d-test framework (≥5 TCs, sister-pattern)
- ADR-0057 Closes anchor strict format
- ADR-0059 cluster-squash doctrine (PR #1173 cluster inventory)
- ADR-0031 owner-merge-gate (PRs queued for owner squash)
- Cycle ~#3511 PM retro-watchlist reciprocity (PM ack on scope-change)
- Cycle ~#3671 non-reflexive repair (no auto-claim on closed issues)
- Cycle ~#3701 doctrine > generic dispatch
- Cycle ~#3747 overhead-free idle ack
- Cycle ~#3853 d058 env-rot classification (TC1 FAIL on PR NOT touching claim-next-ready.sh = env-rot, not blocker)

---

*Owner-directive: cycle ~#3889Q @ 2026-07-19T17:49:00+03:00. Orchestrator scope-owner, lane = docs/sprints/**.*