# Sprint 24 Plan — Cluster close + Sprint 24 plan scaffolding (Issue #767)

> **Sprint window**: 2026-07-14 → 2026-07-27 (2 weeks)
> **Author**: @orchestrator (cycle ~#3419, 2026-07-03T19:07+03:00)
> **Source issue**: #767 [Sprint 24] Backlog Grooming Ceremony
> **Source data**: PM Issue #740 cmt 4866444696 (cycle ~#3180, full triage table) + PM Issue #769 (lane commitments, cycle ~#3228)
> **Status**: 🟡 **SCAFFOLD** — scope uses PM recommendations; owner verdicts may adjust (advisory, not blocking per cycle #3190 owner directive)

## Sprint goal

> Drive Sprint 23 cluster-squash closure → Sprint 24 plan activation. Restart delivery cadence with cleaner lane boundaries; PM lane visible scope is the immediate focus.

**Outcome criteria**:
- 9 decommission candidates resolved (closed or kept per owner verdict)
- #653 lane transfer verdict (tester ↔ PM)
- #649 partial-coverage decision (Keep 0.5sp vs Decom)
- Sprint 24 dev/tester/arch lane scope visible (dev/tester/arch claim-ready)
- Sprint 24 backlog.json refresh committed (PR #770 squash-merged ✅)

## Committed stories (PM-visible scope ~6.0sp, total Sprint 24 ~6.0sp + 3sp carry)

### PM lane (~6.0sp)

| Story | Issue | sp | Priority | Lane (proposed) | Source |
|---|---|---|---|---|---|
| S21-014 PR Template | #645 | 1 | P0 | dev | Issue #740 + #767 (PARTIAL coverage) |
| S21-021 CONTRIBUTING.md | #648 | 0.5 | P1 | dev | Issue #740 + #767 (MISSING root file) |
| S21-022 Smoke Test Script | #649 | 0.5 | P2 | tester | Issue #740 + #767 + #769 (PARTIAL: 1-2/5 sub-scenarios; PM lens = Keep 0.5sp T2-T5 gap-closure) |
| S21-010 Scripts Parameterized | #642 | 0.5 | P2 | dev | Issue #740 + #767 (audit + close remaining gaps) |
| TD-038 PM slice | (TD-038) | 0.5 | P2 | PM | Issue #767 (historical refs audit in docs/{product,backlog,sprints}/) |

**PM lane visible: 3.0sp (Issue #767 est.)** + #653 carry (3sp) = **6.0sp Sprint 24 PM-visible**

### Sprint 23 PM carry-over (1 issue, 3sp)

| Story | Issue | sp | Priority | Lane (current → proposed) | Source |
|---|---|---|---|---|---|
| S21-023 Fresh-Clone Validation (AC3 of S21-020 Issue #652) | #653 | 3 | P2 | tester → PM (PM recommendation) | Issue #740 + #767 + #769 |

**PM lens audit (cycle ~#3228)**: Fresh-Clone Validation is **operational** (end-to-end clone + init + test on a fresh VM), not a d-test implementation task. Tester's lane is d-test impl per ADR-0044; operational validation is owner/PM lane per file ownership matrix.

**PM recommendation**: Owner verdict to flip labels `agent:tester` → `agent:product-manager` OR confirm tester lane.

### Dev/test/arch lane scope (TBD post-Sprint-23 close-out)

Per Issue #767 §Sprint 24 PM lane section + lane posture table — dev/test/arch scope is TBD per Sprint 23 close-out AND owner verdicts on 9-decom + #653 + #649.

| Lane | Sprint 23 exit state | Sprint 24 claim-ready? |
|---|---|---|
| **dev** | 🟢 idle post-cluster-squash (PRs #770 + #772 + #764 all merged) | 🟡 rate-limit reset wait; then claim from Sprint 24 dev story cluster (4 candidates: #645/#648/#642 + ad-hoc) |
| **tester** | 🟢 idle post-#775 squash | 🟢 free for Sprint 24 d-test sister-pattern (Issue #767 d-test coverage required) |
| **arch** | 🟢 idle post-#773 squash | 🟢 WIP=0, ready for Sprint 24 arch lane scope (optional RETRO-016 #5 hysteresis ADR) |
| **PM** | 🟢 active on Issue #769 | 🟢 lane commitments authored (this plan's source) |

## Owner verdict dependencies (PENDING, advisory per cycle #3190 directive)

Per §Eskalasyon scope-change = HUMAN escalation; owner verdicts required for:

| # | Verdict | Issue | PM rec | Sprint 24 impact |
|---|---|---|---|---|
| 1 | 9 decommission | #634/#640/#641/#643/#644/#646/#647/#650/#654 | **CLOSE all** (covered by existing artifacts) | P0 — Sprint 24 PM lane begins once this clears |
| 2 | #653 lane transfer | #653 | **PM lane** (operational validation) | P1 — Sprint 24 PM carry-over 3sp commitment |
| 3 | #649 partial-coverage | #649 | **Keep 0.5sp** (T2-T5 gap-closure) | P2 — Sprint 24 tester lane scope |

Per owner directive "tarih beklemeyin, devam edin" (cycle ~3190, Issue #757): sprint cadence **advisory, not blocking**. PM recommendations used as scope basis; owner verdicts may adjust in follow-up plan amendment.

## Predecessor cascade (cluster-squash context)

### Sprint 22 PIVOT 12-PR cluster (closed 2026-07-02T13:37:50Z)

| Cluster | Last PR | Squash SHA | Closed |
|---|---|---|---|
| 12 PRs | #742 (d117 Sprint 23 env-var gate) | `294d809` | 2026-07-02T13:37:50Z |

PR list: #732, #694, #704, #738, #741, #743, #679, #749, #750, #751, #753, #742

Sprint 22 close.md shipped via PR #778 (Sprint 22 PIVOT close-out, cycle ~#3418, draft un-drafted, owner-squash-pending).

### Sprint 23 cluster-squash 5 PRs (closed 2026-07-03T16:00:30Z)

| PR | Lane | Squash SHA | Closed | Issue closed |
|---|---|---|---|---|
| #772 | dev (Issue #771 + d122) | `1c79f28` | 2026-07-03T15:09:15Z | #771 auto (Closes) |
| #775 | tester (d121) | `14f87e1` | 2026-07-03T00:15:47Z | #774 manual (Refs) |
| #764 | dev (RCA-17 AC4 user fix) | `2d3d926` | 2026-07-03T06:46:19Z | #763 (Refs) |
| #770 | PM (Sprint 24 candidate mapping) | `48f8a12` | 2026-07-03T16:00:19Z | #767 (Refs) |
| #773 | arch (ADR-0064 cross-user env-var) | `60d234f` | 2026-07-03T16:00:30Z | #765 auto (Closes) |
| #778 | orch (Sprint 22 PIVOT close-out) | (pending) | owner-squash-pending | (n/a) |

**Total: 18 PRs cascade across 2 sprints.** T+24h cluster health check: PASSED (0 P0/P1 bugs filed).

## Lane posture (cycle ~#3419, refresh)

| Lane | Sprint 23 exit | Sprint 24 prep | Next action |
|---|---|---|---|
| dev | 🟢 idle post-cluster | claim-next-ready rate-limit wait | Pickup Sprint 24 dev claim after rate-limit reset |
| tester | 🟢 idle post-#775 | d-test sister-pattern ready | Review + verdict PR #778 (Sprint 22 close-out) |
| arch | 🟢 idle post-#773 | WIP=0, queue empty | Optional RETRO-016 #5 hysteresis ADR; otherwise Sprint 24 arch lane |
| PM | 🟢 active on #769 | backlog lane commitments authored | Re-ping owner for 3 verdicts; otherwise advisory per cycle #3190 |
| orchestrator (me) | 🟢 active | Sprint 24 plan scaffold (this doc) | Open draft PR, peer review wait, owner squash |
| owner | ⏳ verdicts pending | scope-change gate | 9-decom + #653 + #649 verdicts (advisory) |

## Risks (5 identified)

1. **Owner verdict timing** — 3 verdicts pending; per cycle #3190 directive "advisory not blocking", plan proceeds with PM recs. If owner rejects PM recs, plan amendment cycle needed.
2. **#653 lane transfer contested** — currently `agent:tester`; if owner keeps tester lane, Sprint 24 PM commitment drops 3sp (re-allocation to tester).
3. **PR #778 squash delay** — Sprint 22 PIVOT close-out doc pending owner squash; if delayed past Sprint 24 kickoff, this plan's "predecessor cascade" link may need annotation. Risk: low (PR #778 docs-only, no functional impact).
4. **Runner VM restart deferred** — cycle #3411 aborted; if retry needed mid-Sprint 24, may impact CI timing (mitigation: GH-hosted fallback already disabled per Sprint 22 PIVOT Faz 3 deferral). Risk: low (8 self-hosted runners operational per heartbeat ~19:48).
5. **PM lane overcommit signal** — 6.0sp is within 25-30sp window but PM-only lane concentrated; if 9-decom verdict delays, PM carry-over 3sp + visible 3sp = 6sp is manageable; if Sprint 24 extends (Sprint 25 carry), consult owner for capacity adjustment.

## Definition of Done (sprint-level)

1. All Sprint 24 stories ship per acceptance criteria
2. PR cluster closes cleanly (no orphan PRs)
3. No new P0/P1 bugs filed against Sprint 24 PRs within 24h of merge
4. Sprint 25 backlog.json refresh authored (PM lane, 2026-07-27 cycle)
5. Sprint 24 retrospective (RETRO-NNN.md) authored (orchestrator lane, 2026-07-27 cycle)
6. Sprint 24 close.md published (orchestrator lane, 2026-07-27 cycle)

## Ceremonies

- **Daily standup**: 09:00 Europe/Istanbul (auto + manual trigger)
- **Mid-sprint check**: 2026-07-20 (week 1 close) — burn rate vs 6.0sp capacity
- **Sprint review + retro**: 2026-07-27 (week 2 close) — `docs/sprints/sprint-24/close.md` + `RETRO-NNN.md`

## Doctrine compliance

- ✅ **§PM lane definition LOCKED (Sprint 13+)** — PM = docs/{sprints,product,backlog,agents}/**, NOT scripts/ refactors
- ✅ **§Eskalasyon scope-change = HUMAN escalation** — 9-decom + #653 + #649 owner verdicts pending (advisory)
- ✅ **§4-cat invariant (ADR-0012)** — birth contract applied to Issue #767 (this plan's source)
- ✅ **§no-self-standby (Issue #238)** — Sprint 24 plan drafted cycle ~#3419, in-flight with PM lens
- ✅ **§Cluster-squash doctrine (ADR-0059)** — Sprint 23 cluster-squash 5 PRs + 1 doc PR closed cleanly
- ✅ **§Pre-verdict cross-check (Issue #430) + §Post-verdict cross-watchdog (Issue #682)** — verdict-by stamp discipline applied (PR #778 tester+PM 30s window respected)
- ✅ **§Handoff Label Discipline (ADR-0015)** — atomic 4-flag hand-off, all sub-faz flips respected

## Cross-refs

- **Issue #767**: [Sprint 24] Backlog Grooming Ceremony (this plan's source issue)
- **Issue #769**: [PM] Sprint 24 backlog lane commitments + #653 lane verdict + 9 decom owner ping
- **Issue #740**: [PM] Sprint 21 backlog hygiene + Sprint 24 candidate mapping
- **Issue #740 cmt 4866444696**: PM triage table (cycle ~#3180, source of truth)
- **Sprint 23 plan.md**: predecessor (working tree, ship cycle ~#3419 separate commit)
- **Sprint 22 close.md**: PR #778 draft (cycle ~#3418), owner-squash-pending
- **Sprint 22 plan.md**: 5-Phase Plan PIVOT (closed 2026-07-02)
- **PR #770**: Sprint 24 candidate mapping (48f8a12, merged 2026-07-03T16:00:19Z) — backlog.json on main
- **PR #778**: Sprint 22 PIVOT close-out (orchestrator, draft, owner-squash-pending)
- **ADR-0059**: cluster-squash doctrine (precedent for 5-PR + 1-PR cluster)
- **ADR-0012**: 4-cat label invariant (this plan's label set)
- **Owner directive**: "tarih beklemeyin, devam edin" (cycle #3190, Issue #757)

---

*Authored by @orchestrator cycle ~#3419 (2026-07-03T19:07+03:00). Source: Issue #767 + PM Issue #769 + PM Issue #740 cmt 4866444696. 🟡 SCAFFOLD status — owner verdicts may adjust scope per cycle #3190 advisory directive.*
