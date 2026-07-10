# Current Sprint — Pointer

> **Active sprint:** **Sprint 28 — LIVE on main (cycle ~781, 2026-07-10T22:30+03:00, post-4×squash-merge, owner triage pending on 3 items)**
>
> 📄 **Sprint 28 kickoff issue:** [Issue #974](https://github.com/atilcan65/AtilCalculator/issues/974) — full 3-wave plan inline, in-progress
> 📄 **Sprint 28 audit-baseline (MERGED):** [PR #967](https://github.com/atilcan65/AtilCalculator/pull/967) — squash-merged @ 18:57:07Z, commit `a02110c6`
> 📄 **Sprint 28 plan source:** [`docs/sprints/sprint-28/plan.md`](../sprint-28/plan.md) + [`docs/sprints/sprint-28/00-audit-baseline.md`](../sprint-28/00-audit-baseline.md) (both on main)
> 📄 **Sprint 27 closeout:** [`docs/sprints/sprint-27/close.md`](../sprint-27/close.md) — 3/3 work items shipped
> 📄 **Sprint 27 retro (RETRO-019):** [`docs/sprints/sprint-27/RETRO-019.md`](../sprint-27/RETRO-019.md) — W1 (premature closure) + W7 (events API scan) doctrine candidates
>
> **Mode:** 🟢 **SPRINT 28 LIVE ON MAIN** — HEAD `ff9eacc` (PR #977 squash-merge), 14 STORY files in `docs/backlog/`, all 4 launch PRs merged
>
> **Sprint board status:**
> - 🟢 Sprint 18, 20, 22, 23, 24, 25+, 26, 27 all CLOSED
> - 🟡 Sprint 21 STALLED (Q6 default carry-over per Issue #708, in D-OD2 mass-close scope)
> - 🟢 **Sprint 28 LIVE** — Issue #974 tracking; 4×PRs squash-merged; 1×PR awaiting owner merge
>
> **Active backlog:**
>
> | # | State | Title | Owner |
> |---|---|---|---|
> | #974 | open, status:in-progress, agent:orchestrator | [Sprint 28] Kickoff | @orchestrator (this cycle) |
> | #979 | open, draft, agent:architect | Path-Verify Doctrine SOUL AMEND (W3) | @architect (awaiting owner squash) |
> | #978 | open, status:backlog, agent:product-manager | PM-A-DELTA-CL-19 naming-scheme triage | @PM (awaiting owner a/b/c) |
> | #972 | open, status:in-progress, agent:architect | Path-Verify Doctrine codification | @architect (closes on #979 squash) |
> | #971 | open, status:backlog, agent:architect | per-soul amend-block diff plan | @architect (PM-A-DELTA-13) |
> | #970 | open, status:backlog, agent:architect | docs/designs/ file enumeration missing | @architect (PM-A-DELTA-10) |
> | #969 | open, status:backlog, agent:architect | docs/ops/vm-hardening.md portability | @architect (PM-A-DELTA-09) |
> | #968 | open, status:backlog, agent:architect | tmpl docs/templates/ parity check | @architect (PM-A-DELTA-08) |
>
> **Open PRs (1):**
>
> | PR | Author | Lane | State | Action |
> |---|---|---|---|---|
> | #979 | architect | .claude/agents + scripts/tests | draft, MERGEABLE, d972 GREEN 5/5 | **owner squash-merge** (Closes #972) |
>
> **Squash-merged today (4×PRs, 41s window 18:57:07Z → 18:57:48Z):**
>
> | PR | Title | Commit |
> |---|---|---|
> | #967 | Sprint 28 audit baseline + new-projectsteps runbook | `a02110c6` |
> | #975 | refresh current/plan.md post-Sprint 28 KICKOFF | `7e81cf1d` |
> | #976 | S-08a Auto-Verdict-By hook port design (W2) | `18c576a5` |
> | #977 | Sprint 28 PM grooming — 14 STORY files (S28-001..014, 12sp) | `ff9eacc6` |
>
> **Sprint 28 wave plan** (per Issue #974 + PR #967 §20):
>
> - **W1 Foundation** (4.5sp): SL-01, SL-01a, SL-02, SL-02a, SL-03, SL-04 — *dev lane blocked on PM opening 14 STORY GitHub issues*
> - **W2 Feature port** (4sp): S-08a (atomic dep — design merged via #976), S-08, Sprint-22-Q mass-close, CLAUDE.md reconcile
> - **W3 Polish** (3.5sp): TD-029, TD-028, d-test regression, Path-Verify doc (closes via PR #979 squash)
> - **Total**: 12sp, **8sp buffer**
>
> **Owner bottleneck (3 items awaiting triage):**
>
> 1. **Deploy run #29116380182** — step 3 "Deploy + smoke test + auto-rollback" FAILED at 19:00:47Z on `ff9eacc`. Auto-rollback within failing step (designed pattern). Owner decision on retry / post-mortem / prod-rollback needed.
> 2. **PR #979 squash-merge** — architect SOUL AMEND (3×.claude/agents/*.md.tmpl + d972 d-test 250 LOC), d972 GREEN 5/5, Closes #972 on squash. Owner merge gate per ADR-0031.
> 3. **PM-A-DELTA-CL-19 naming-scheme** (Issue #978 + cmt 4938295585 on #974) — owner a/b/c option: (a) keep existing sprint-prefix (PR #977 path), (b) migrate to SL-/S-/TD- prefix, (c) defer to retro.
>
> **Lane gap (PM pinged at 22:18+03:00, awaiting response):**
> W1 dev lane: 14 STORY files in `docs/backlog/` (merged via PR #977) but no corresponding GitHub issues opened. Per ADR-0002 + ADR-0038, dev lane cannot claim without issue cards. PM owns `docs/backlog/**` per file ownership matrix.
>
> **Fired actions (cycle ~769-~781):**
> - cmt 4938164239 (orchestrator synthesis, 6 D-OD matrix)
> - cmt 4938190859 (orchestrator clarifier, 11 owner-asks inventory)
> - Issue #974 opened (Sprint 28 kickoff, 9 labels per ADR-0012 4-cat invariant + cross-lane visibility)
> - Peer pings: PM (grooming), architect (W2/W3 + bucket-B), developer (W1/W2 lane), tester (W3 lane), human (squash-merge)
> - cmt 4938693081 (orchestrator spot-check on PR #979, d972 GREEN 5/5 ✅)
> - cmt 4938703997 (orchestrator STATUS on Issue #974, carry queue snapshot)
> - PM ping 22:18+03:00 (W1 dev-lane gap surfaced, lane = `docs/backlog/**`)
> - 4×PRs squash-merged (PRs #967/#975/#976/#977, cycle ~777, 41s window)
>
> **Dormant carry (Sprint 22/24/27):** 24 items, no action needed (owner-dormant per "yeni direktif için hazır olunca söyle")

— @orchestrator, 2026-07-10T22:30+03:00 (cycle ~781, post-4×squash-merge, post-PR #979 spot-check)
