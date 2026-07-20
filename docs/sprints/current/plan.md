# Current Sprint — Pointer

> **Active sprint:** **Sprint 33 — Doctrine Refresh + Wave 8+ Close-out** (cycle ~#3965Q, 2026-07-20T19:31+03:00, PM-authored DURING Sprint 32 final wave per RETRO-032 lesson #6 fix)
>
> 📄 **Sprint 33 plan source:** [`docs/sprints/sprint-33/00-plan.md`](../sprint-33/00-plan.md) (PM-authored, 6 STORIES / 16 SP, doctrine refresh focus, gated on AC5 soak)
> 📄 **Sprint 33 kickoff coordination:** [Issue #1186](https://github.com/atilproject/AtilCalculator/issues/1186) (gated on AC5 24h soak GREEN at 2026-07-21T16:07:23Z)
> 📄 **Sprint 32 closeout:** [Issue #1171](https://github.com/atilcan65/AtilCalculator/issues/1171) — SQUASH-MERGED 2026-07-20T16:07:23Z (commit `a93a586`); cluster-squash 4/4 (PR #194+#195+#196+#1179)
> 📄 **Sprint 32 retro (RETRO-032):** 19 NEW doctrine lessons captured (lessons #1-14 base + #15-19 Wave 8+ evolution), 13 carry-over items in Sprint 33 scope
> 📄 **Sprint 31 closeout:** [`docs/sprints/sprint-31/close.md`](../sprint-31/close.md) — MERGED via PR #1145 (commit `b5f0a34`, 2026-07-18T06:52:11Z)
> 📄 **Sprint 31 retro (RETRO-031):** captured via PR #1145 cluster-squash (Issue #1142 closure)

---

## Mode

🟢 **SPRINT 32 EXECUTE — INFRASTRUCTURE-FINALIZE ONLY (no AtilCalculator feature work)**

- **Owner-ratified**: 2026-07-18T10:01+03:00 ("Sprint 32 sadece bu iş olacak, 1 sprintte tamamlıcaz")
- **Owner GO signal**: 2026-07-18 (cycle ~#3230, "merge ettim, başlayalım" — after PR #126 squash-merge)
- **Capacity cap**: 4-5 PRs/cluster-squash per day, 5 agents in parallel lanes
- **Scope boundary**: template finalize (`atilproject/dev-studio-template`) + launcher finalize (`atilcan65/dev-studio-launcher`) + calc forward-port. OUT: any feature work
- **Sister-repo workstreams** (RETRO-023 cluster, 3 repos): template + launcher + calc
- **Tag discipline**: template `v1.1.0` target, launcher `v0.4.0` target

---

## Story inventory (24 stories, 6 waves)

| Wave | Scope | Stories | Status |
|---|---|---|---|
| **Wave 1 — Discovery** | Doctrine diff classification + baseline portage report | S32-001 ARCH + S32-002 DEV | `status:ready` (Wave 1 GO) |
| **Wave 2 — Template gap-closure** | ADRs port (cluster-squash), soul file sync (+5500B orch + +1440B arch), gap-scan port+d-test, stale URL fix, SHA-pin, Python detect | S32-003..009 | pending Wave 1 close |
| **Wave 3 — Calc forward-port** | install-env.sh + systemd + tests/INDEX.md + lint-and-test.yml | S32-010..013 | pending Wave 1+2 close |
| **Wave 4 — Launcher finalize** | CI workflow + d001 d-test + v0.4.0 tag | S32-014..016 | pending Wave 3 close |
| **Wave 5 — Docs + tag** | new-project-steps.md + CHANGELOG v1.1.0 + tag cut + smoke verify | S32-017..020 | pending Wave 4 close |
| **Wave 6 — Verify + close** | d-test sweep + portage re-run + close.md + dry-run | S32-021..024 | pending Wave 5 close |

---

## Owner merge gate queue (TIER 1 — ADR-0031 blocking)

| PR | Repo | Story | State | Test status | Action |
|---|---|---|---|---|---|
| **#4** | atilcan65/dev-studio-launcher | S29-003 | ✅ squash-merged @ 10:56:37Z | 6/6 d-test GREEN | ✅ done |
| **#71** | atilcan65/dev-studio-template | S29-005 | ✅ squash-merged @ 10:56:47Z | 8/8 d-test GREEN | ✅ done |
| **#1008** | atilcan65/AtilCalculator | Sprint 28 audit-baseline | ✅ squash-merged @ 08:10:31Z (commit `a02110c6`) | n/a (docs) | ✅ done |
| **#1019** | atilcan65/AtilCalculator | plan.md refresh | ✅ squash-merged @ 10:57:10Z | n/a (docs pointer) | ✅ done |
| **#1029** | atilcan65/AtilCalculator | S29-002 tag-move verification | ✅ squash-merged @ 13:47:43Z (commit `96205ec6`) | n/a (scripts) | ✅ done |
| **#72** | atilcan65/dev-studio-template | S29-004 disable status-label-to-board.yml | ✅ squash-merged @ 14:20:32Z (commit `6d9d3f84`) | 7/7 d-test GREEN | ✅ done — board sync freeze ACTIVE |
| **#1037** | atilcan65/AtilCalculator | Wave 2 PM grooming — 6 STORY files + backlog.json | ✅ squash-merged @ 14:20:41Z (commit `13c2675c`) | n/a (docs/backlog) | ✅ done — Wave 2 files main-resident |
| (Wave 1) | atilproject/dev-studio-template | audit PR #126 (baseline) | ✅ squash-merged @ 07:58:38Z (commit `52ed8407`) | n/a (docs) | ✅ done — Sprint 32 EXEC UNBLOCKED |
| (Wave 1) | atilcan65/AtilCalculator | plan.md refresh (S29→S32) | ⏳ IN PROGRESS (this PR) | n/a (docs pointer) | ORCH 4-cat label set, owner merge |
| (Wave 1) | atilcan65/AtilCalculator | Issue #1146 kickoff status flip | ⏳ IN PROGRESS | n/a (issue) | status:ready → status:in-progress + verdict-by |

---

## Sprint 32 active issues

- **Issue #1146** (atilcan65/AtilCalculator) — Sprint 32 kickoff coordination issue (agent:orchestrator + cc:all agents), transitioned from Sprint 31 HOLD to Sprint 32 EXEC per owner directive cycle ~#3230
- **S32-001** — ARCH: Full doctrine diff (ADRs, soul files, scripts, workflows) — Wave 1
- **S32-002** — DEV: Baseline portage report — Wave 1
- (S32-003..024 — filed in subsequent waves per plan dependency graph)

## Sister-repo workstreams (RETRO-023 cluster, 3 repos)

- **`atilproject/dev-studio-template`** (v1.0.1 → v1.1.0) — primary Sprint 32 target (template-finalize)
- **`atilcan65/dev-studio-launcher`** (v0.3.0 → v0.4.0) — secondary target (launcher CI + d-test integration)
- **`atilcan65/AtilCalculator`** (calc → forward-port surface) — selected gaps only (install-env, systemd, INDEX.md, lint-and-test.yml)

## Doctrine reference (Sprint 32 active)

- **ADR-0031** — Owner merge gate (only human squash-merges)
- **ADR-0033** — Dual-channel peer-poke (Telegram + tmux pane wake)
- **ADR-0038** — Auto-Claim WIP cap (2/2 per role)
- **ADR-0044** — RED-first TDD (tester before dev)
- **ADR-0045** — 9-Lens pre-publish gate (architect)
- **ADR-0049** — d-test framework (≥5 TCs behavioral, ≥3 TCs hygiene/docs)
- **ADR-0055** — Cadence Rule 1 atomic (sister-pattern d-test commits with impl)
- **ADR-0057** — Closes anchor strict format (`Closes #N` vs `Refs #N`)
- **ADR-0059** — Cluster-squash batch-merge (≤15-sec owner-squash window)
- **RETRO-018 W6** — Branch-ownership matrix (cross-agent push authority NOT in doctrine)
- **RETRO-024** — Work-done-elsewhere exception (cross-repo terminal state)
- **RETRO-027** — Cadence Rule 2 retroactive-close precondition (PR-persistence + Closes-anchor required)

---

— @orchestrator, 2026-07-18T11:00+03:00 (cycle ~#3230, post-owner-GO, Sprint 32 EXECUTION KICKOFF)