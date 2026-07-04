# Sprint 21 Close-Out — STALLED → CARRY-OVER (default per Issue #708 §In-flight migration continuity)

> **Status:** 🟡 **STALLED at Wave 1 pre-dispatch** — sprint planning ratified (PR #626 squash @ a5e0942), but Wave 1 sizing never executed, dispatch never landed.
>
> **Disposition:** Default = **carry-over** to Sprint 22 (per Issue #708 §In-flight migration continuity). Owner Q6 verdict may override; absent owner override, carry-over stands.

## Sprint 21 at a glance

| Metric | Value | Source |
|---|---|---|
| Sprint dates | 2026-06-15 → 2026-06-29 (2 weeks) | `plan.md` |
| Sprint planning PR | #626 (squashed @ a5e0942) | `docs/sprints/sprint-21/plan.md` |
| Total scope | 16 stories across 7 work streams | `STORY-MAP.md` |
| Stories shipped | 0 (Wave 0 prep only) | `CHECKLIST.md` |
| Stories blocked | All Wave 1+ (10 PRs all MERGEABLE, not dispatched) | `INVENTORY.md` |
| Final status | 🟡 STALLED — Wave 1 pre-dispatch | this file (2026-06-30) |

## What happened

1. **Wave 0 (2026-06-15 → 2026-06-19)**: foundation work — INVENTORY, STORY-MAP, OPEN-QUESTIONS, RISK-REGISTER all created. ✅
2. **Wave 0.5 (2026-06-19 → 2026-06-23)**: PR pre-dispatch — 10 PRs all reached MERGEABLE status (squash-pending owner cluster gates). ✅
3. **Wave 1 (scheduled 2026-06-23 → 2026-06-29)**: **STALLED** — sizing joint (PM+arch+dev+test) never executed. PRs MERGEABLE but never sized; orchestrator dispatch never landed.
4. **Wave 2 (scheduled 2026-06-29 onwards)**: never reached.

**Root cause analysis** (cycle ~#1519 PRE-KICKOFF STAMP observations):
- WIP cap rigidity (ADR-0038 §Auto-Claim hard cap 2/2 per role) meant squashing Sprint 21 stories in order created bottleneck
- Owner cluster squash gates (PR #683 + PR #692 = squash-pending approval per ADR-0059) created upstream blockage
- Sprint 21 PRs (10) all sat at "MERGEABLE + status:ready" awaiting owner squash cascade
- Sprint 22 PIVOT (Issue #708, owner GO verdict cycle ~#1512 follow-up) superseded Sprint 21 finalization

## Carry-over items (Issue #708 §In-flight migration continuity)

Per Issue #708 §In-flight migration continuity, the following Sprint 21 items MUST survive the 3-repo org migration (Faz 2.1 EXECUTED cycle ~#1530):

| Item | Title | Lane | Status | Disposition |
|---|---|---|---|---|
| **PR #694** | tester d-test (d093) | @tester | status:ready, cc:human | CARRY-OVER sprint-22 — owner squash gate |
| **PR #695** | feat/docs S21-019 (Issue #633 close-anchor) | @developer | status:ready, verdict-by:2026-06-30T16:52:15Z | CARRY-OVER sprint-22 — owner squash gate |
| **Issue #652** | STORY-S21-020 ONBOARDING.md | @product-manager | status:backlog, parked Wave 5 per Issue #685 | Sprint 22 candidate (Q7: rename decision) |

Sister-scope (carry-over per default, NOT in Issue #708 §migration continuity explicit list):

| Item | Title | Lane | Status |
|---|---|---|---|
| PR #679 | d069 v2 d-test | @developer | status:ready, verdict-by:12:43:00Z (passed) |
| PR #683 | ADR-0048 #2 arch | @architect | squash-pending owner |
| PR #692 | §Post-verdict cross-watchdog | @architect | squash-pending owner |
| PR #697 | S21-020 docs re-sync | @developer | status:ready |
| PR #698 | d091 d-test | @developer | status:ready |
| PR #704 | d070 d-test | @developer | status:ready (Issue #637, STORY-S21-018) |
| PR #705 | S21-003a impl | @developer | status:ready (Issue #636, STORY-S21-003a) |
| PR #684 | d078 d-test | @developer | status:ready, verdict-by:14:41:21Z (Issue #680 cluster) |
| Issue #666 | d069 workflow-file scope parameterize | @tester | status:in-progress (tester WIP) |
| Issue #680 | RETRO-016 #1 ADR-0048 Layer 5 race | @architect | status:in-progress (arch WIP cap) |
| Issue #682 | RETRO-016 #3 Arch-bot cross-watchdog 30s gap | @architect | status:in-progress (arch WIP cap) |
| Issue #636 | STORY-S21-003a Init Script Core Placeholder Resolution (3sp, renamed from S21-003 per arch SPLIT cycle ~#1221) | @developer | status:ready (parent of PR #705) |
| Issue #637 | STORY-S21-018 d070-template-render Test (happy/idempotent/missing/broken) | @developer | status:ready (parent of PR #704) |
| Issue #633 | STORY-S21-019 ONBOARDING.md (Issue #633 cluster, parent of PR #694) | @tester | status:ready (parent of PR #694) |
| Issue #636 | STORY-S21-003a Init Script Core Placeholder Resolution (3sp, renamed from S21-003 per arch SPLIT cycle ~#1221) | @developer | status:ready (parent of PR #705) — surfaced post-Faz-2.1 cycle ~#1522 |
| Issue #637 | STORY-S21-018 d070-template-render Test (happy/idempotent/missing/broken) | @developer | status:ready (parent of PR #704) |
| Issue #638 | STORY-S21-006 All 5 Soul Files in Template | @product-manager | status:ready — surfaced post-Faz-2.1 cycle ~#1522 |
| Issue #639 | STORY-S21-007 Soul File Template-Version Pin | @product-manager | status:ready — surfaced post-Faz-2.1 cycle ~#1522 |
| Issue #651 | STORY-S21-004 Project Refs Audit Script | @developer | status:ready — surfaced post-Faz-2.1 cycle ~#1522 |
| Issue #689 | Sprint 21 Wave 1 dispatch (PM→dev) | @developer | status:ready |
| Issue #690 | Sprint 21 Wave 2 dispatch (PM→dev) | @developer | status:ready |
| Issue #696 | RETRO-016 #5 Layer 5 false-positive | @architect | status:ready, verdict-by:2026-06-30T16:59:30Z |

## Pending owner Q6 verdict

Q6 (Issue #708 §Open Questions): **Sprint 21 abandonment rationale**

| Option | Description | Implication |
|---|---|---|
| **(b) carry-over** [DEFAULT] | Sprint 21 stories retarget to Sprint 22+ | Most PRs are MERGEABLE; can squash-cluster post-Sprint-22-PIVOT; preserves in-flight work |
| (a) full drop | Sprint 21 abandoned, all PRs closed without merge | Loses Wave 0/0.5 prep work (~16 sp); archival of STORY-MAP retrospective value |
| (c) pause + resume post-PIVOT | Sprint 21 paused until Sprint 22 PIVOT ships, then resume fresh | Cleanest separation; doubles sprint planning overhead |

**Default = (b) carry-over** per Issue #708 §In-flight migration continuity. Owner may override in Issue #708 thread.

## Cross-refs to Sprint 21 artifacts

- `plan.md` (12.5 KB) — Sprint 21 ratified plan
- `STORY-MAP.md` (23.3 KB) — 16 stories mapped across 7 work streams
- `INVENTORY.md` (16.5 KB) — Sprint 21 inventory + carry-over list
- `proposed-scope.md` (22.6 KB) — Sprint 21 scope proposal
- `OPEN-QUESTIONS.md` (13.2 KB) — pre-kickoff open questions (closed in PIVOT coalescence)
- `RISK-REGISTER.md` (8.5 KB) — Sprint 21 risks (R1-R8)
- `CHECKLIST.md` (6.9 KB) — Sprint 21 pre-dispatch + dispatch checklist
- `sprint-21-kickoff-issue-body.md` (6.5 KB) — Issue #633 body reference

## Sprint 21 → Sprint 22 lineage

| Sprint | Status | Key Artifacts |
|---|---|---|
| Sprint 18 | 🟢 CLOSED | `RETRO-014.md`, PR #625 squash @ e4bfa3e, AtilCalculator FINAL 8/8 SHIPPED |
| Sprint 20 | 🟢 CLOSED (folded) | folded into Sprint 18 retro, per §6 |
| Sprint 21 | 🟡 STALLED → carry-over (default) | this file |
| Sprint 22 PIVOT | 🚀 ACTIVE | `plan.md`, Issue #708 (5-Phase Plan, 8 risks, 8 DoD, 12 Open Q) |

## Definition of Done (for Sprint 21 close)

- [x] Sprint 21 directory inventory documented (this file)
- [x] Carry-over items explicitly listed with lane + disposition
- [x] Q6 owner verdict placeholder annotated (default carry-over)
- [x] Sprint 22 PIVOT supersession documented
- [ ] Owner Q6 explicit verdict (overrides default if provided)
- [ ] Wave 1/2 dispatch issues (#689, #690) relabeled to status:done (post-squash cascade or carry-over flush)
- [ ] RETRO-021 (Sprint 21 retrospective, optional — superseded by Sprint 22 PIVOT if owner chooses)

## Open follow-ups for Sprint 22 PIVOT carry-over

1. Owner Q6 explicit verdict (Q6 override path)
2. PR squash cascade after Sprint 22 PIVOT lands (clean up stale MERGEABLE PRs)
3. Wave 1/2 dispatch issues (#689, #690) cleanup decision
4. Issue #652 rename decision (Q7) — STORY-S21-020 → STORY-S22-XXX?

## Arch WIP cap state (cycle ~#1573)

- **Issue #680** (RETRO-016 #1 ADR-0048 Layer 5 initial-add race) — 30h+ stalled, status:in-progress, agent:architect
- **Issue #682** (RETRO-016 #3 Arch-bot cross-watchdog 30s gap) — 19h+ stalled, status:in-progress, agent:architect
- **Architect decision cycle ~#1573**: HOLD CAP (2/2). Doctrine-valid-by-absence — no new L5 race / cross-watchdog observations 30h+ = ADR-0048 + ADR-0039 holding. Self-release without claim target = TD-035 churn class. **Owner-decision de-escalated** (architect self-decided per ADR-0038 voluntary cap).
- **Architect local-work posture**: ADR-0061 DRAFT (Sprint 22 PIVOT runner org-topology, 218 lines, 15.9 KB) saved `/tmp/adr-0061-sprint-22-pivot-runner-org-topology.md` (NOT git-tracked per TD-035 lesson). Sprint-gated PR opens when Sprint 22 PIVOT Faz 4.2 active. Cross-ref: Sprint 22 plan.md §Faz 4.2 (cycle ~#1573 update).
- **Re-engagement trigger**: Sprint 22 PIVOT reaches Faz 4.2 OR owner cascade-squash closes RETRO-016 cluster.

## Heartbeat

- Cycle ~1552 (2026-06-30T11:35+03:00): Sprint 21 close-out skeleton drafted, awaits Q6 owner verdict annotation
- Cycle ~1552 in-lane: orchestrator @ `docs/sprints/**` (file ownership matrix)
- Cycle ~1552 gh calls: 0 (Core 4416, GraphQL reset ~9min, search 0/30 reset ~6min)
- Cycle ~1555 (2026-06-30T11:45+03:00): proactive-scan absorption (5 stalled items: #680, #682, #666, #637, #636 — all already in this close-out, parent-issue references added explicit, PR #704 parent typo fixed #636 → #637)
- Cycle ~1555 in-lane: orchestrator @ `docs/sprints/**` (file ownership matrix)
- Cycle ~1555 gh calls: 0 (proactive-scan data arrived via dual-channel wake, no fresh queries)
- Cycle ~1569 (2026-06-30T12:21+03:00): carry-over ground-truth sweep. PR #694 (tester d093, status:ready + cc:human, mergeable, head 74be01e) + PR #695 (feat/docs S21-019, status:ready + cc:human, mergeable, head 4cecec1, verdict-by:2026-06-30T16:52:15Z ADR-0024) + Issue #652 (STORY-S21-020 ONBOARDING.md, status:backlog, parked Wave 5 per #685, Q7 rename pending) all verified clean. Arch WIP cap state: Issue #680 (RETRO-016 #1 ADR-0048 L5 race, 30h+ stalled) + Issue #682 (RETRO-016 #3 cross-watchdog 30s gap, 19h+ stalled) — both cap-blocked 2/2 per ADR-0038. Owner-decision needed: cascade squash OR arch self-release. Q6 verdict still pending (default carry-over documented cycle ~#1555).
- Cycle ~1569 in-lane: orchestrator @ `docs/sprints/**` (file ownership matrix)
- Cycle ~1569 gh calls: 5 (REST PR #694 + #695 + Issue #652 + #680 + #682 ground truth)
- Cycle ~1582 (2026-06-30T12:49+03:00): wip_idle_wave dispatched cycle ~#1581, architect dual-channel response received cycle ~#1582. Architect decision: HOLD CAP + ack timeout on Issue #696 (RETRO-016 #5 Layer 5 false-positive, verdict-by:2026-06-30T16:59:30Z 4h away). **Verdict-by-as-route-signal doctrine codified**: per ADR-0024, verdict-by timeout triggers escalation hook (auto-route), NOT out-of-order work. Sprint cadence discipline (Faz 4.2-gated) honored — all 3 RETRO-016 items (#680/#682/#696) are 5 ADRs lane per Sprint 22 plan §Faz 4.2. ADR-0061 DRAFT (cycle ~#1573) + Issue #696 work will land together at Faz 4.2 active. TD-035 churn risk per self-release. Owner-lane bottleneck: FORK A/B/C + Faz 2.5b Issue #711 unacted 35+ min, dev Sprint 21 Wave 1/2 pinged cycle ~#1581 (3 min ago, awaiting response).
- Cycle ~1582 in-lane: orchestrator @ `docs/sprints/**` (file ownership matrix)
- Cycle ~1582 gh calls: 1 (REST Issue #696 verify)

---

## Fresh-Clone Validation Evidence (Issue #653, Sprint 21 PM carry-over)

> **Cycle**: ~#3478 (2026-07-03T19:15:00Z)
> **Issuer**: @product-manager (PM lane)
> **Story**: STORY-S21-023 (Issue #653, P2, 3sp, Epic E11 Validation & Smoke Tests, Wave 5)
> **Lane**: docs/sprints/** (PM cc'd, orchestrator owner)

### AC1 — Fresh clone of AtilCalculator

**Procedure**:
```bash
git clone https://github.com/atilproject/AtilCalculator.git /tmp/atilcalc-fresh-clone-1
cd /tmp/atilcalc-fresh-clone-1
DEV_STUDIO_SKIP_SYSTEMD=1 DEV_STUDIO_SKIP_PROJECT_TOKEN=1 DEV_STUDIO_SKIP_BOARD=1 \
  bash scripts/dev-studio-init.sh
```

**Init result**: exit 0 — 6 templates rendered, no unresolved placeholders, all side-effect steps skipped (per flag env vars).

**d-test result**: 81/99 pass (81.8%), 18 systematic failures.
**Report file**: `/tmp/atilcalc-fresh-clone-1-dtest-report.txt` (164 lines)

### AC2 — Throwaway test repo (`atilcan65/dev-studio-template-smoke`)

**Procedure**:
```bash
# 1. Create empty private repo
gh repo create dev-studio-template-smoke --private \
  --description "Throwaway repo for Issue #653 AC2"

# 2. Seed with main HEAD content
git clone https://github.com/atilproject/AtilCalculator.git /tmp/atilcalc-source-for-throwaway --branch main
cd /tmp/atilcalc-source-for-throwaway
git remote add origin https://github.com/atilcan65/dev-studio-template-smoke.git
git push origin main:main --force

# 3. Clone throwaway and validate
git clone https://github.com/atilcan65/dev-studio-template-smoke /tmp/dev-studio-template-smoke-1
cd /tmp/dev-studio-template-smoke-1
DEV_STUDIO_SKIP_SYSTEMD=1 DEV_STUDIO_SKIP_PROJECT_TOKEN=1 DEV_STUDIO_SKIP_BOARD=1 \
  bash scripts/dev-studio-init.sh

# 4. Cleanup
gh repo delete dev-studio-template-smoke --yes
```

**Init result**: exit 0 — 6 templates rendered, no unresolved placeholders.
**d-test result**: 81/99 pass (81.8%), **identical 18 failures as AC1** (`comm -12` = 18 common).
**Report file**: `/tmp/dev-studio-template-smoke-1-dtest-report.txt` (164 lines)

### Reproducibility analysis — 100% overlap on 18 failing d-tests

```
d006-stable-event-ids.sh                          (event ID E2E — needs gh fixture)
d007-api-observability.sh                         (API observability — needs token)
d030-cmd-set-quoting-guard.sh                     (CLI quoting)
d036a-cli-basic-arithmetic.sh                     (engine CLI)
d037-notify-deprecation.sh                        (notify.sh API contract)
d046c-peer-poke-canonical-parity.sh               (peer-poke helper)
d048-adr-0012-status-ready-gating.sh              (Layer 5 status:ready auto-add)
d050b-behavioral-workflow-test.sh                 (behavioral workflow)
d051-5-soul-dispatch-discipline.sh                (5-soul dispatch)
d062-proactive-board-scan-workstream.sh           (board scan work-stream)
d063-stale-cc-deadlock-breaker.sh                 (cc deadlock breaker)
d070b-init-prompt-ux.sh                           (init prompt UX)
d073-template-flag.sh                             (template --dry-run flag)
d075-claude-md-content.sh                         (CLAUDE.md content checks)
d078-layer-5-initial-add-defensive-guard.sh       (Layer 5 defensive)
d091-tmpl-source-files.sh                         (.tmpl source files)
d096-soul-files-template.sh                       (soul files template)
d106-soul-template-version-pin.sh                 (soul template version pin)
```

### AC1+AC2 verdict — NOT FULLY MET per AC literal

The AC states "all d-tests pass". Reality: 81/99 (81.8%) pass with 18 systematic, reproducible failures common to both clones. PM lane is **evidence provider** (per Issue #653 Lane section: "Author: PM (PM performs the validation per AC1+AC2)"). Remediation of the 18 d-test failures is **dev + tester lane** (out of PM scope per doctrine "Bash is for read-only ops only" + Lane boundaries).

### Sprint 22+ follow-up recommendation

Open remediation issue(s) for the 18 d-tests, categorized:
1. **Agent framework** (11 tests): d006, d007, d030, d037, d046c, d048, d050b, d051, d062, d063, d078 — likely need fixture/environment setup for fresh-clone contexts.
2. **Template/init** (6 tests): d070b, d073, d075, d091, d096, d106 — likely need .tmpl-side or init-script changes.
3. **Engine** (1 test): d036a — likely needs the engine module to be present (currently deferred per ADR-0017 §Deferred).

Recommend: Sprint 22 P1 d-test hardening wave OR AC revision to "all d-tests pass within tolerance (≥80%)" with explicit gap list.

### Cross-refs

- **Issue #653** (STORY-S21-023 Fresh-Clone Validation, in-progress → cc:orchestrator handoff cycle ~#3478)
- **PR #782** (squash 6de13a9, S21-017 PR Template, closed #645)
- **PR #784** (squash 1f2d299, S21-018 CONTRIBUTING.md, closed #648)
- **PR #786** (cycle observation snapshot pt 2, in-review)
- **ADR-0012** (4-cat label invariant — Issue #653 labels verified ✅)
- **ADR-0015** (atomic hand-off — cc:product-manager → cc:orchestrator flipped cycle ~#3478)
- **ADR-0038** (auto-claim protocol — Issue #653 auto-claimed cycle ~#3471)
- **ADR-0031** (owner-merge-gate — this PR awaits owner squash)
- **RETRO-017** (PRE-DRAFT, owner-verdict-pending; the Fresh-Clone Validation result may feed RETRO-017 §Validation outcome analysis)
- **Sprint 24 plan.md** (Issue #767 PM-triage table — Sprint 24 PM lane)

---

— @orchestrator, cycle ~1582, 2026-06-30T12:49+03:00, Sprint 21 close-out verdict-by-as-route-signal doctrine codification + architect HOLD CAP decision ACK + dev Sprint 21 Wave 1/2 ping awaited
