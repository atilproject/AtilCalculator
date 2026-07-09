# Sprint 26 Plan — TD-067c design + d296 gap-closure + v1.0.1 patch (post-GA)

> **Sprint window**: 2026-07-09 → 2026-07-22 (2 weeks, kicking off post-template v1.0.1 release)
> **Author**: @orchestrator (cycle ~#5095, 2026-07-09T19:38+03:00)
> **Source issues**: #941 [Sprint 26] Kickoff + #943 d-test gap-closure tracker + #931 TD-067c + #853 canary gap
> **Source data**: arch cmt 4927095731 (Wave 1 deferral on #931) + arch cmt 4927243051 (🟢 APPROVED Sprint 26 scope) + tester cmt 4927382970 (true audit results)
> **Status**: 🟡 **DRAFT → ACTIVE** (cycle ~#5095 part 4, 2026-07-09T19:50Z) — scope firm from #941 + #943 + arch verdict + PM curation (PR #937); joint sizing ceremony pending (per PM cmt 4926058363 §Sizing coordination); arch design phase **DONE** (PR #946 open)

## Sprint goal

> Drive template hardening past v1.0.1 patch release: TD-067c open-time label-strip diagnostic + d296 ≥5 TC baseline gap-closure + canary mirror config.yml restore.

**Outcome criteria**:
- **OC1**: #931 (TD-067c) — design doc + ADR + tech-debt row update + d-test design landed; impl PR opens in Sprint 26 OR Sprint 27 (per arch bandwidth)
- **OC2**: #943 (d296) — `scripts/tests/d296-peer-poke-helper.sh` extended from 3 TCs to ≥5 TCs; `scripts/tests/INDEX.md` Cadence Rule 1 atomic (per ADR-0055); test plan authored at `docs/test-plans/d296-sprint26-tests.md`
- **OC3**: #853 (canary ISSUE_TEMPLATE/config.yml) — manual restoration OR mirror fix per owner territory (ADR-0031)
- **OC4**: Sprint 26 close.md + RETRO-018 authored at sprint close (Friday of week 2)
- **OC5**: No new P0/P1 bugs filed against Sprint 26 scope

## Committed stories (final ~5.0sp scope, joint sizing pending)

| Issue | Story | Priority | Lane (owner) | sp (proposed) | Source |
|---|---|---|---|---|---|
| [#931](https://github.com/atilcan65/AtilCalculator/issues/931) | **TD-067c — Open-time label-strip diagnostic** | P1 | architect | ~4.0sp (PM cmt 4926058363 split: S25-001 2.0sp impl + S25-002 1.5sp d-test + S25-003 0.5sp bonus, combined impl PR per arch S3) | PR #937 docs curation + Issue #931 filing + arch cmt 4927095731 |
| [#943](https://github.com/atilcan65/AtilCalculator/issues/943) | **d296 ≥5 TC baseline gap-closure** | P2 | tester | ~0.5sp (tester cmt 4927382970 + issue body §Story points) | Issue #877 retro + STORY-882 test plan + tester true audit 16:30Z |
| [#853](https://github.com/atilcan65/AtilCalculator/issues/853) | **canary mirror ISSUE_TEMPLATE/config.yml** | P3 | developer (+ cc:human per ADR-0031) | ~0.5-1.0sp (PM cmt 4926058363 §Sizing defer-to-dev) | Issue #841 AC4 surface 4 gap |
| (orchestration) | **Sprint 26 close + RETRO-018** | P3 | orchestrator | ~0.5sp | Standard sprint close ceremony |

**Total committed**: ~5.0-5.5sp (~4.0 + 0.5 + ~0.75 + 0.5)

### Sprint 26 author lane deliverables (per arch verdict cmt 4927243051)

For **#931 (TD-067c)**, architect lane owns 4 deliverables (per arch verdict §Lane flips):

1. **Design doc** `docs/designs/TD-067c-open-time-design.md` (sister to `docs/designs/TD-067-TD-068-sister-fix-design.md`, PR #928)
2. **ADR** `docs/decisions/ADR-NNNN-td-067c-open-diagnostic.md` (sister to ADR-0070 TD-067b) — ~0.25sp
3. **tech-debt.md** TD-067c row update (carry from Wave 1 deferral + 4th evidence instance)
4. **d-test contract** `scripts/tests/d296b-td067c-open-time-label-strip.sh` (sister-test to d296/d058, RED-first per ADR-0044) — coord with tester per joint sizing

### Sprint 26 wave 1 progress (cycle ~#5095 part 4, 2026-07-09T19:50Z)

| Step | Status | Lane | Artifact | Notes |
|---|---|---|---|---|
| Wave 1 step 1: TD-067c design phase | ✅ **LANDED** | architect | PR #946 (draft, +572/-2, 4 files) | c8b29718c8 on `arch/td-067c-design-issue-931`. 9-Lens pre-publish attestation per ADR-0045 ✅. 4 LIVE INSTANCES evidence stack. Sister-pattern to TD-067b Layer 6 (PR #938). Awaiting owner squash gate per ADR-0031. |
| Wave 1 step 1.5: S26-001 d296 gap-closure PR | ⛔ **BLOCKED** | tester | PR #947 (draft, +813/-6, 7 files) | Cross-lane structural issue: 4 architect-lane files (ADR-0071 + design doc + INDEX.md + tech-debt.md) DUPLICATED from PR #946. Arch 🔴 BLOCK verdict; tester needs PR shape fix (rebase/stack/replace per arch Options 1-3). d-test code itself GREEN per arch 9-Lens. cmt 4927581490 orch ACK; cmt 4927510XXX arch BLOCK. |
| Wave 1 step 2: S26-002 d-test RED-first | ⏳ **NEXT** | tester | `scripts/tests/d067c-open-time-label-strip.sh` (≥5 TCs, sister d058 fixture pattern) | Per ADR-0044 RED-first. TC1-TC7 enumerated in design doc §AC. Mock event generator sister d058 (NOT historical `gh api` replay per cmt 4927243051 #2). After #947 PR shape fix lands. |
| Wave 1 step 3: S26-001 impl PR | ⏳ **WAITING** | developer | `.github/workflows/label-check.yml` edits (3 distinct guards: actor check, synchronize no-op diff gate, canonical step if: gate) | After d-test lands per ADR-0044 RED-first. Owner squash gate per ADR-0031 (`.github/workflows/` human-only territory). |
| PM reconciliation on #945 | ⏳ **PENDING** | PM | STORY-S26-001 1.5sp/6 d-tests → 0.5sp/1 d-test d296 per tester #943 audit | cmt 4927477514 (orch review on PR #945) flagged the stale estimate. PM response pending. |
| Owner squash gate | ⏸️ **PENDING** | human | PR #946 → main | Per ADR-0031. Designer-only territory (workflow YAML touches `.github/workflows/`). |

### d296 sister-pattern scope (per #943 §Acceptance criteria)

For **#943 (d296 gap-closure)**, tester lane owns:

- **AC1**: `scripts/tests/d296-peer-poke-helper.sh` extends from 3 TCs (T1/T2/T3) to ≥5 TCs (add T4/T5 minimum)
- **AC2**: New TCs cover additional edge cases (T4 = extra positional args; T5 = empty role OR empty msg case)
- **AC3**: Test plan authored at `docs/test-plans/d296-sprint26-tests.md` before TC additions (per ADR-0044 RED-first)
- **AC4**: `scripts/tests/INDEX.md` row for d296 updated (Cadence Rule 1 atomic per ADR-0055)
- **AC5**: d296 PR ships with `agent:tester` + `cc:developer` + `cc:architect` + `cc:orchestrator` (per ADR-0012 4-cat)

## Capacity & WIP cap

- **Orchestrator**: 5-agent squad coordination + Sprint 26 close ceremony (light load, owner of plan.md + close.md)
- **Architect**: heavy (4 deliverables for #931, plus pre-publish gate per ADR-0045 9-Lens)
- **Tester**: moderate (#943 d296 gap + #931 d-test contract coordination)
- **Developer**: light (#853 canary, but owner-territory adjacent per ADR-0031)
- **Product Manager**: idle (deferred per #941 §Out-of-scope — PM backsprint toward Sprint 27 grooming)

**WIP cap**: per ADR-0038 §Layer 2 (1 in-progress per role). Tester's claim is WIP=1/2 (auto-claimed via REST post-GQL rate-limit reset, see cmt 4927382970).

## Dependencies

- **#931 (TD-067c) arch design phase** → unblocked by Sprint 26 kickoff (Issue #941 fired)
- **#931 (TD-067c) impl PR** → depends on arch design doc + ADR landing (Sprint 26 mid-point target)
- **#943 (d296) test plan + PR** → depends on arch review of T4/T5 design rationale (per #943 §AC2)
- **#853 (canary)** → owner-territory population per ADR-0031 (orchestrator can flag, owner executes)
- **Release v1.0.2** (if Sprint 26 ships cluster) → depends on PR-cluster merge cadence + owner release publish

## Risks (per orchestrator triage, cycle ~#5095)

- **R1 (Medium)**: Arch bandwidth for 4 #931 deliverables + Sprint 27 prep — mitigated by S25-001+S25-003 combined PR per arch S3 suggestion
- **R2 (Low)**: Tester's WIP=1/2 means #931 d-test coordination waits until #943 closes — mitigated by parallel work (architect + tester are different lanes)
- **R3 (Low)**: Sprint 26 plan.md pending owner ratification (advisory per cycle #3190 owner directive) — accepted, in flight
- **R4 (Low)**: Cluster #890 already closed 5 of #877's "6 below-baseline" d-tests — sister-finding per tester cmt 4927382970 narrows Sprint 26 scope considerably

## Acceptance criteria (Sprint 26 close)

1. ✅ #931 (TD-067c) — design doc + ADR + tech-debt row landed in `docs/decisions/` + `docs/designs/` + `docs/tech-debt.md`
2. ✅ #943 (d296) — `scripts/tests/d296-peer-poke-helper.sh` ≥5 TCs, INDEX.md Cadence Rule 1 atomic, test plan + PR merged
3. ✅ #853 (canary config.yml) — config.yml restored on canary mirror (owner territory)
4. ✅ Sprint 26 close.md + RETRO-018 authored on sprint close (Friday week 2)
5. ✅ No new P0/P1 bugs filed against Sprint 26 scope (24h post-merge window)
6. ⏸️ v1.0.2 release publish (only if cluster PRs land)

## Cross-refs

- **Issue #941** — Sprint 26 Kickoff (status:in-progress since 2026-07-09T16:28:59Z)
- **Issue #943** — d296 gap-closure tracking issue (tester lane, opened 2026-07-09T16:32:52Z)
- **Issue #931** — TD-067c P1 (status:ready, arch lane, design phase DONE in PR #946)
- **PR #946** — TD-067c design contract (draft, arch, 9 labels 4-cat ✅, cmt 4927509639 orch ACK)
- **Issue #853** — canary config.yml P3 (status:backlog, dev lane)
- **Issue #939** — Sprint 25+ Wave 1 deferral (CLOSED 2026-07-09T16:00:27Z, source of TD-067c → Sprint 26 inheritance)
- **Issue #877** — Phase 2 audit, §tester lane follow-up row (CLOSED, parent of #943 d296 gap)
- **PR #937** — Sprint 25+ Wave 1 PM-curated grooming artifacts (3 STORY-S25-001/002/003 files, Sprint 26 inheritance)
- **PR #942** — v1.0.1 Grup C re-render (squash-merged 16:26:15Z, merge commit d02e1e8) — v1.0.1 release 2026-07-09T16:26:58Z
- **Release v1.0.1** — https://github.com/atilcan65/AtilCalculator/releases/tag/v1.0.1
- **cmt 4927095731** — arch Wave 1 deferral cross-reference on #931 (correct arch cmt, doc-staleness fix from arch verdict)
- **cmt 4927052273** — arch original (STALE) Wave 1 deferral (replaced by 4927095731 per arch verdict doc-staleness fix)
- **cmt 4927243051** — arch 🟢 APPROVED verdict on Sprint 26 scope (Issue #941)
- **cmt 4927382970** — tester self-claim + true audit results for #943
- **cmt 4927476368** — orch ACK on #931 (arch design delivery)
- **cmt 4927477514** — orch review on PR #945 (STORY-S26-001 🟡 reconciliation, STORY-S26-002 🟢 APPROVED)
- **cmt 4927509639** — orch ACK on PR #946 (Sprint 26 wave 1 step 1 ✅)
- **PR #944** — current/plan.md refresh cycle ~#5094 (orchestrator, owner squash gate)
- **PR #945** — PM-curated STORY-S26-001/002 (orchestrator review: S26-001 🟡 reconciliation, S26-002 🟢 APPROVED)
- **PR #946** — TD-067c design contract (arch, draft, owner squash gate)
- **PR #947** — d296 gap-closure (tester, draft, BLOCKED — PR shape fix needed)
- **cmt 4927243051** — arch 🟢 APPROVED verdict on Sprint 26 scope (Issue #941)
- **cmt 4927382970** — tester self-claim + true audit results for #943
- **PR #944** — current/plan.md refresh cycle ~#5094 (orchestrator, owner squash gate)
- **ADR-0012** — 4-cat label invariant
- **ADR-0015** — atomic 4-flag hand-off
- **ADR-0031** — owner squash gate
- **ADR-0038** — Auto-Claim Protocol §Layer 2
- **ADR-0044** — RED-first TDD
- **ADR-0045** — 9-Lens pre-publish gate
- **ADR-0049** — d-test framework (≥5 TCs baseline)
- **ADR-0055** — Cadence Rule 1 atomic
- **RETRO-016** — trace cleanliness doctrine (sister-pattern for doc-staleness flag)

## Lane discipline (Sprint 13+ LOCKED)

- PM lane = docs/sprints/souls PRs, NOT scripts/ refactors (per [ORCH→PM-CLARIFY-ACK] @ 22:42:21+03:00)
- Sprint 26 plan.md = **orchestrator lane** per file ownership matrix
- Architect lane owns #931 (4 deliverables)
- Tester lane owns #943 (5 ACs)
- Developer lane owns #853 (1 deliverable)
- PM = idle (per #941 §Out-of-scope, backsprint toward Sprint 27 grooming)

## Sizing ceremony (PM coordination slot)

Per PM cmt 4926058363 §Sizing coordination + PM doctrine "Never estimate alone":

- **Proposed sizes**: 4.0sp (931) + 0.5sp (943) + 0.5-1.0sp (853) + 0.5sp (close) = ~5.0-5.5sp
- **Joint sizing ceremony needed**: arch + dev + tester + owner ratification
- **Slot**: suggest Sprint 26 Day 1 standup (per orchestrator dual-channel poke when arch bandwidth opens)

## Sub-tracking

- **#943 (d296)**: tester owns, currently `status:in-progress` per self-claim (cmt 4927382970)
- **#931 (TD-067c)**: architect owns design, currently `status:ready` per orchestrator flip (16:28:59Z)
- **#853 (canary)**: developer owns, currently `status:backlog` — unblock path = owner territory population per ADR-0031
- **#941 (Sprint 26 Kickoff)**: orchestrator owns, currently `status:in-progress` — flips to `status:done` at sprint close

— @orchestrator, 2026-07-09T19:50+03:00, cycle ~#5095 part 4, post-PR-#946-design-DONE (arch lane closed, 4 lanes deconflicted from #941 + #943 + #931 + #853, peer-poking dev+tester for wave 1 step 2/3)
