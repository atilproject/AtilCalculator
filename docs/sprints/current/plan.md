# Current Sprint — Pointer

> **Active sprint:** **Sprint 34 — AtilCalculator → template/launcher forward-port (audit gap-closing)** (cycle ~#3968Q+320, 2026-07-24T20:39+03:00, post-PR #1218 SQUASH-MERGE)
>
> 📄 **Sprint 34 plan source:** [`docs/sprints/sprint-34/00-plan.md`](../sprint-34/00-plan.md) (orchestrator-seeded, awaiting PM Lane 1 review + amendment per cadence rule "PM owns the wave plan"; 7 STORIES / 3 WAVES / ~25-30 SP, audit gap-closing focus)
> 📄 **Sprint 34 audit baseline (PR #1218):** [`docs/sprints/sprint-34/00-audit-template-launcher.md`](../sprint-34/00-audit-template-launcher.md) — SQUASH-MERGED 2026-07-24T17:34:14Z (commit `44246b4`); 3/3 reviewer consensus (PM Lane 1 🟢 + Arch Lane 2 PRIMARY 9-Lens 🟢 + Tester Lane 3 🔵 N/A doc-only per cycle ~#3642H)
> 📄 **Sprint 33 closeout:** [`docs/sprints/sprint-33/close.md`](../sprint-33/close.md) — MERGED via PR #1216 (commit `74ead05`, 2026-07-24T05:56:53Z)
> 📄 **Sprint 33 retro (RETRO-033):** [`docs/sprints/sprint-33/RETRO-033.md`](../sprint-33/RETRO-033.md) — 19 NEW doctrine lessons captured
> 📄 **Sprint 32 closeout:** [Issue #1171](https://github.com/atilproject/AtilCalculator/issues/1171) — SQUASH-MERGED 2026-07-20T16:07:23Z (commit `a93a586`); cluster-squash 4/4 (PR #194+#195+#196+#1179)
> 📄 **Sprint 32 retro (RETRO-032):** 19 NEW doctrine lessons captured (lessons #1-14 base + #15-19 Wave 8+ evolution), 13 carry-over items in Sprint 33 scope

---

## Mode

🟢 **SPRINT 34 EXECUTE — AUDIT GAP-CLOSING (single-direction, scope-locked)**

- **Owner-ratified**: 2026-07-24T20:39+03:00 ("ok mergeledim başlayın, tum bu işler sprint 34e yapılacak, başka iş yapılmayacak bu sprinte")
- **Owner GO signal**: 2026-07-24 (post-PR #1218 squash-merge sha `44246b4`)
- **Capacity cap**: 4-5 PRs/cluster-squash per day, 5 agents in parallel lanes
- **Scope boundary**: AtilCalculator → template + launcher forward-port (audit gap-closing sequence steps 2-8 = 7 stories). OUT: any other work, any reverse-direction propagation, any out-of-matrix impl
- **Sister-repo workstreams** (3 repos): template + launcher + calc (single-direction A→T+L only)
- **Tag discipline**: launcher `v0.5.0` target (S34-003); template version pending parity matrix approval (S34-001)
- **Scope-lock supersession**: Owner directive 2026-07-24T20:39Z supersedes 2026-07-21T09:55Z Sprint 34-forbidden directive per cycle ~#3968Q+313 NEW DOCTRINE (owner scope authority: newer directive supersedes)

---

## Story inventory (7 stories, 3 waves)

| Wave | Scope | Stories | Status |
|---|---|---|---|
| **Wave 1 — Foundation** | Parity matrix construction (artifact-by-artifact classification) | S34-001 | `status:ready` (Wave 1 GO) |
| **Wave 2 — Feature** | Template forward-port + Launcher forward-port + Bootstrap test infra | S34-002 / S34-003 / S34-004 | pending Wave 1 close |
| **Wave 3 — Polish** | Runner tuple resolution + Verified new-project-steps doc + Sprint 34 close | S34-005 / S34-006 / S34-007 | pending Wave 2 close |

---

## Owner merge gate queue (TIER 1 — ADR-0031 blocking)

| PR | Repo | Story | State | Test status | Action |
|---|---|---|---|---|---|
| **#1216** | atilproject/AtilCalculator | Sprint 33 close ceremony | ✅ squash-merged @ 05:56:53Z (commit `74ead05`) | n/a (docs) | ✅ done |
| **#1218** | atilproject/AtilCalculator | Sprint 34 audit baseline | ✅ squash-merged @ 17:34:14Z (commit `44246b4`) | n/a (docs) | ✅ done — Sprint 34 EXEC UNBLOCKED |
| (Wave 1) | atilproject/AtilCalculator | Sprint 34 plan.md + kickoff issue | ⏳ IN PROGRESS (this PR + issue chain) | n/a (docs pointer) | ORCH 4-cat label set, PM Lane 1 review pending |

---

## Sprint 34 active issues

- **[Sprint 34] Kickoff** (atilproject/AtilCalculator) — orchestrator opening NOW, 4-cat labels per ADR-0012
- **S34-001** — Parity matrix construction (architect-led, L effort, Wave 1) — orchestrator opening NOW
- **S34-002** — Template forward-port impl (developer-led, XL effort, Wave 2) — pending S34-001
- **S34-003** — Launcher forward-port impl (developer-led, XL effort, Wave 2) — pending S34-001
- **S34-004** — Disposable bootstrap test infra (developer + owner gate, M effort, Wave 2) — pending S34-002/003
- **S34-005** — Runner tuple resolution (owner-gated, S effort, Wave 3) — pending S34-002/003
- **S34-006** — Verified new-project-steps doc (PM-led, M effort, Wave 3) — pending S34-004/005
- **S34-007** — Sprint 34 close + retro (orchestrator-led, S effort, Wave 3) — pending S34-001..006

---

## Sister-repo workstreams (RETRO-023 cluster, 3 repos, single-direction)

- **`atilproject/dev-studio-template`** (target v1.x.x) — primary Sprint 34 target (forward-port from AtilCalculator per parity matrix `equivalent`/`divergent` rows)
- **`atilproject/dev-studio-launcher`** (target v0.5.0) — secondary target (version contract + tests + docs forward-port)
- **`atilproject/AtilCalculator`** — source repo (no impl work, only docs/sprints/ artifacts for Sprint 34)

---

## Doctrine reference (Sprint 34 active)

- **ADR-0012** — 4-cat label invariant (every Issue/PR: type + status + agent + cc)
- **ADR-0015** — Atomic 4-flag handoff (add add remove remove order)
- **ADR-0017** — Python 3.11+ stack (unchanged)
- **ADR-0024** — Verdict-by discipline (`verdict-by:<role>:<ts>` convention)
- **ADR-0031** — Owner merge gate (only human squash-merges)
- **ADR-0033** — Dual-channel peer-poke (Telegram + tmux pane wake)
- **ADR-0038** — Auto-Claim WIP cap (2/2 per role)
- **ADR-0044** — RED-first TDD (tester before dev)
- **ADR-0045** — 9-Lens pre-publish gate (architect Lane 2 PRIMARY)
- **ADR-0049** — d-test framework (≥5 TCs behavioral, ≥3 TCs hygiene/docs)
- **ADR-0055** — Cadence Rule 1 atomic (sister-pattern d-test commits with impl)
- **ADR-0057** — Closes anchor strict format (`Closes #N` vs `Refs #N`)
- **ADR-0059** — Cluster-squash batch-merge (≤60s owner-squash window per cycle ~#3258 cap)
- **RETRO-018 W6** — Branch-ownership matrix (cross-agent push authority NOT in doctrine)
- **RETRO-024** — Work-done-elsewhere exception (cross-repo terminal state — N/A for Sprint 34 active work)
- **RETRO-027** — Cadence Rule 2 retroactive-close precondition (PR-persistence + Closes-anchor required)
- **cycle ~#3642H** — Lane 3 N/A on doc-only PRs
- **cycle ~#3968Q+186** — 2-lane ack pattern scope: CLUSTER DOCS ONLY (single-file audit exempt)
- **cycle ~#3968Q+226** — 600s productive-idleness storm-watch baseline
- **cycle ~#3968Q+244** — Arch verdict cc: auto-pair skipped (orchestrator 2-flag atomic fix post-verdict)
- **cycle ~#3968Q+277** — 4h+ idle escalation matrix
- **cycle ~#3968Q+313** — Owner scope authority (newer directive supersedes — Sprint 34 framing NOW valid)
- **cycle ~#3968Q+3921Q+/~#3922Q** — Post-verdict commit doctrine (verdict-by preserved as historical evidence)

---

— @orchestrator, 2026-07-24T20:39+03:00 (cycle ~#3968Q+320, post-PR #1218 SQUASH-MERGE, Sprint 34 EXECUTION KICKOFF)
