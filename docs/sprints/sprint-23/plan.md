# Sprint 23 Plan — Cluster close + Sprint 21 carry-over execution

> **Sprint window**: 2026-06-30 → 2026-07-13 (2 weeks)
> **Author**: orchestrator (cycle ~#3070)
> **Source issue**: #735 [Sprint 23 Kickoff] Cluster close + Sprint 21 carry-over execution
> **Owner verdict**: ASAP on Issue #733 (Q2 scope-change decision)

## Sprint goal

Close the **Sprint 22 PIVOT P3 close cluster** (PR #732 ADR-0019 amend 3 + ADR-0019 amend 4 + cascade PRs #679/#704/#694) and execute **Sprint 21 carry-over stories** (sub-stories of #689/#690 closed by Issue #733 owner verdict Q1). Restart delivery cadence post-PIVOT.

## Committed stories (9 stories, ~32sp)

| Story | sp | Lane | Pre-condition | Status |
|---|---|---|---|---|
| #633 (S21-019 ONBOARDING.md) | 3sp | dev | d093 d-test shipped (PR #694 d093, 3/3 GREEN on rebased 3a4cf3b) | ready |
| #636 (S21-003a) | 3sp | dev | d070a extends d070 | ready |
| #693 (S21-003b) | 2sp | dev | d070b extends d070a | ready |
| #651 (S21-004) | 3sp | dev + owner | d080 (cross-lane ci.yml step) | needs d080 |
| #635 (S21-005) | 3sp | dev | d091 (renamed d081) | ready |
| #638 (S21-006) | 3sp | dev + owner | d082 (AC4 owner pre-approval .claude/) | needs owner |
| #639 (S21-007) | 2sp | dev | d083 sister-pattern d090 | ready |
| #724 (d094 slot collision) | 1sp | dev | rename PR #709's d094 to d097 | **PR #738 in flight** |
| #652 (S21-020 ONBOARDING.md content) | 6sp | PM | fast-track Sprint 23 | PM parked |
| #653 (S21-023 Fresh-Clone Validation) | 3sp | PM/Tester lane TBD | PM lane carry-over per Issue #740 triage (owner verdict pending on lane transfer) | lane-ambiguous |

**Total**: ~32sp (slightly over 25-30sp target, owner ASAP accepted per Issue #733 Q1). **Pending owner verdict: +3sp if #653 lane transfer approved → 35sp**.

## Active cascade at Sprint 23 start

| Item | Owner | Status | ETA | Note |
|---|---|---|---|---|
| PR #732 (ADR-0019 amend 3, markdown fix) | dev + owner squash | ✅ merged | done | md fix |
| PR #679 (d069 v2) | tester re-🟢 + owner squash | ✅ merged | done | dual-verdict cleared cycle #3067 |
| PR #704 (d070) | tester re-🟢 + owner squash | ✅ merged | done | dual-verdict cleared cycle #3067 |
| PR #694 (d093) | tester re-🟢 + owner squash | ✅ merged | done | dual-verdict cleared cycle #3067 |
| PR #741 (ADR-0019 amend 4) | arch + tester 🟢 + owner squash | ✅ merged | done | post-#732-squash |
| PR #743 (ADR-0019 amend 5) | arch + owner squash | ✅ merged | done | forward-ref to #741 (cascade) |
| PR #738 (Issue #724 d094→d097) | dev + owner squash | ✅ merged | done | d094→d097 rename + Lint&Test fix |
| PR #749 (Issue #739 URL hygiene) | arch + owner squash | ✅ merged | done | docs/decisions/ URL hygiene |
| PR #753 (d069 WORKFLOW_FILES) | dev + owner squash | ✅ merged | done | sprint sister |
| **PR #742 (d117 Sprint 23 env-var gate)** | **dev + owner squash** | **✅ merged** | **done (2026-07-02T13:37:50Z, 294d809629)** | **Sprint 23 dev lane workhorse — final cascade close** |

**Cluster cascade: 10/10 closed ✅** (PR #732 → #694/#704/#738 → #741/#743 → #679/#749/#750/#751/#753 → **#742**)

## Lane posture (cycle ~#3070, refreshed ~#3188)

- **dev**: WIP=0 cluster closed (cycle #3188). Sprint 23 dev story cluster **ready to claim**: #633 / #636 / #693 / #635 / #639 (dev lane). Stories #651 (d080) + #638 (.claude/ soul) need owner pre-approval. #724 closed via PR #738.
- **tester**: 3 PR cluster re-verdict complete (cycle #3067 dual-verdict cleared); free for new work. Issue #740 IMMEDIATE actions #2/#3 prerequisites met (PR #679 + #704 squashed); awaiting PM flip.
- **arch**: ADR-0019 amend 5 (#743) merged; URL hygiene (#749) merged; #707 Option C hysteresis spec ready for status:ready flip.
- **PM**: #652 parked (awaiting unblock); Issue #740 in flight (Sprint 21 hygiene + Sprint 24 mapping); auto-pinged cycle #3188 for #637/#666 promotion.
- **orchestrator**: ceremony authored (this file); cluster-squash wave 10/10 closed; Issue #735 cascade-closure comment posted; sprint-22 close.md still pending (risk #6).

## Risks (8 identified)

1. **Issue #728 cascade length** — #741 → #743 → #738/#742 → next ADR. Owner squash pace is the bottleneck. ✅ **RESOLVED** (cascade 10/10 closed cycle ~#3188).
2. **PR #738 Lint & Test flakiness** — `SUBPROCESS_TIMEOUT_S=1` default too short for cold-start. PR #743 amend-5 fixes via env-var gate. ✅ **RESOLVED** (PR #738 squash-merged).
3. **PR #743 INDEX.md merge conflict** — both #741 and #743 modify `docs/decisions/INDEX.md` (+1/-1 each adjacent). Owner must rebase #743 after #741 lands. ✅ **RESOLVED** (PR #743 squash-merged).
4. **Sprint 23 capacity 32sp > 25-30sp target** — owner ASAP-accepted but worth monitoring week 1 burn. ⚠️ **+3sp if #653 lane transfer approved (35sp)**.
5. **PM #652 fast-track** — 6sp, largest single story; needs PM unblock if #652 parking extends. **#653 (3sp) PM lane carry-over adds → Sprint 23 total 35sp if owner verdicts lane transfer**.
6. **d080 cross-lane ci.yml step** — owner pre-approval required per ADR-0010 (soul-level decision).
7. **.claude/agents/** owner merge gate for S21-006 — soul file changes need explicit owner approval.
8. **Stale-issue detector noise** — issues #739, #724 flagged but work IS in flight via PRs; dev/arch to update issue bodies. ✅ **#739 closed via PR #749/#750/#751; #724 closed via PR #738**.

## Sprint 24 candidate mapping (PM triage cycle ~#3180)

PM has posted 14 backlog stories triage table (Issue #740 cmt 4866444696). Pending owner verdict:

- **9 decommission candidates**: #634, #640, #641, #643, #644, #646, #647, #650, #654 (all covered by existing work per PM local audit)
- **Sprint 24 PM-lane-visible scope** (~3.7sp): #645 P0 PR Template (1sp, MISSING), #648 P1 CONTRIBUTING.md (0.5sp, MISSING), #649 P2 Smoke Test Script (0.5sp), #642 P2 Scripts Parameterized audit (0.5sp), TD-038 PM slice (~0.5sp), Issue #707 hysteresis (~0.7sp)
- **Sprint 23 PM lane carry-over**: #653 (Fresh-Clone Validation, 3sp) — **lane ambiguity** (PM claims but labels say agent:tester; owner verdict needed)

Orchestrator pinged owner with full triage context cycle ~#3188. Sprint 24 plan author cycle TBD per owner verdict.

## Definition of Done (sprint-level)

1. All 9 Sprint 23 stories ship per acceptance criteria
2. PR cluster closes cleanly: #732 ✅ → #741 squash → #743 squash → #679/#704/#694 squash
3. PM coordination body well-tracked (Issue #733 + #724 + #652)
4. No new P0/P1 bugs filed against cluster PRs within 24h
5. Repo vars `BUDGET_MULTIPLIER=5` + `SUBPROCESS_TIMEOUT_S=10` documented in README + CHANGELOG.md
6. Sprint 22 close-out documented in `docs/sprints/sprint-22/close.md` ✅ **RESOLVED cycle ~#3188** ([close.md shipped](../sprint-22/close.md), 12 closeout PRs catalogued)

## Doctrine compliance

- **§PM lane definition (Sprint 13+ LOCKED)** — PM = docs/sprints/souls cc patterns, ORCH = sprint plan author ✅
- **§Issue #708 precedent** — Sprint 21 default carry-over executed per Q1 verdict ✅
- **§Eskalasyon istisnaları** — Sprint 23 scope-change = HUMAN escalation (Q2 owner verdict ASAP) ✅
- **§Pre-verdict cross-check (Issue #430)** — ground truth re-queried before plan authoring (cycle ~#3070) ✅
- **§4-cat invariant (ADR-0012)** — birth contract applied to this plan

## Ceremonies

- **Daily standup**: 09:00 Europe/Istanbul (auto + manual trigger)
- **Mid-sprint check**: 2026-07-06 (week 1 close) — burn rate vs 32sp capacity
- **Sprint review + retro**: 2026-07-13 (week 2 close) — `docs/sprints/sprint-23/close.md` + `RETRO-NNN.md`

## Cascade hand-off (current cycle ~#3188, post-cluster-close)

**Cluster-squash wave**: ✅ 10/10 closed (PR #732 → #694/#704/#738 → #741/#743 → #679/#749/#750/#751/#753 → #742). Owner squash cadence resolved.

**Next sprint coordination** (orchestrator lane):
1. **Issue #740 PM IMMEDIATE actions** — PM auto-pinged cycle #3188; awaiting PM flip on #637 + #666 (tester will then claim d069/d070 d-tests).
2. **Issue #707 → status:ready** — orchestrator flip after arch Option C hysteresis spec ready (no arch action yet).
3. **Sprint 23 dev claim cluster** — #633/#636/#693/#635/#639 dev-ready; awaiting owner/PM ack before triggering dev claim (sprint-coordination, not lane-trigger).
4. **Story #651 / #638 owner pre-approval** — pre-approval request to owner pending.
5. **Sprint 22 close.md** — orchestrator lane, post-cascade; author this week.

**Agent-gated** (no owner action):
- Sprint 23 stories #633/#636/#693/#635/#639 ready to claim by dev lane (post-PM/owner ACK)
- Story #651 dev prep (d080 draft)
- Story #638 owner pre-approval needed for `.claude/agents/` soul file

---

*Authored by orchestrator cycle ~#3070 (2026-07-02T11:55+03:00). Source issue: #735. Cascade snapshot: cycle #3068 + #3069 + #3070.*