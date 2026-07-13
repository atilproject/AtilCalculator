# Current Sprint — Pointer

> **Active sprint:** **Sprint 29 — gap-closing only** (cycle ~#1245, 2026-07-13T13:45+03:00, scope-locked per owner directive "Sprint 29 ve gap closinge odaklanacağım, başka işlere dokunmuyoruz bitne kadar")
>
> 📄 **Sprint 29 plan source:** [`docs/sprints/sprint-29/00-plan.md`](../sprint-29/00-plan.md) (full 19-story plan, 3 waves + final)
> 📄 **Sprint 29 prereq:** [`docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md`](../sprint-28/02-template-launcher-audit-2026-07-13.md) — PR #1008, status:ready awaiting owner squash-merge per ADR-0031
> 📄 **Sprint 28 closeout (pending):** [`docs/sprints/sprint-28/close.md`](../sprint-28/close.md) — drafts via Issue #1018 (orchestrator, lightweight mode)
> 📄 **Sprint 28 retro (RETRO-018 W6):** captured via [PR #995 squash (1ea16cb)](https://github.com/atilcan65/AtilCalculator/pull/995) — orchestrator.md.tmpl SOUL AMEND codification (branch-ownership matrix cross-check)

---

## Mode

🟢 **SPRINT 29 LIVE ON MAIN — SCOPE-LOCKED (gap-closing only, no template drift)**

- **Owner-ratified**: 2026-07-13 (Phase 1 cycle ~#1159 + Phase 2 cycle ~#1180, 9 owner-decisions total)
- **Capacity cap**: NONE (owner directive #3 — completion, not velocity, is the metric)
- **Scope boundary**: Category C gap-closing items only (C-08 ISSUE_TEMPLATE, C-09 docs skeleton, C-01/02 board bootstrap); C-03..07/10 deferred to Sprint 30+
- **Sister-repo workstreams** (RETRO-023 cluster): launcher PRs (`atilcan65/dev-studio-launcher`), template PRs (`atilcan65/dev-studio-template`)
- **v1.0.1 tag discipline** (owner directive #1): move v1.0.1 → template HEAD `43592c24`; new v0.3.0 tag on launcher HEAD `b0d820da`

---

## Story inventory (19 stories, 3L + 7M + 9S)

| Wave | Scope | Stories | Status |
|---|---|---|---|
| **Wave 1 — hygiene** | self-hosted runner migration, tag move, governance files | S29-001..005 | S29-001 load-bearing critical, S29-002 in-progress, S29-003 + S29-005 work-done via sister PRs, S29-004 in arch-design branch |
| **Wave 2 — portage** | ADR port (universal IDs + amendments), d-test port, ISSUE_TEMPLATE content-parity | S29-006..011 | S29-006 ADR-first per owner #2, AC7 expanded per owner #8 (10-12 amendments) |
| **Wave 2B — gap-closing** | pyproject.toml.tmpl + LICENSE.tmpl + .template-version render path, soul .md.tmpl re-author | S29-012..017 | NEW stories (S29-016, S29-017), S29-011 reframed XS per owner #7 |
| **Wave 3 — verification** | docs sub-dir skeletons (8) + top-level docs files (6) | S29-018, S29-019 | NEW stories per owner Phase 2 |

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
| **#73** | atilcan65/dev-studio-template | S29-001 self-hosted 4-tuple migrate | draft, status:ready + cc:human | 8/8 d-test GREEN + arch 🟢 (14:18:41Z) + tester 🟢 (13:22:27Z) | **owner squash-merge** (next) |

---

## Sister-repo work-done evidence (cycle #1206 → #1245)

- **Issue #1015** (S29-003) → terminal state `type:feature + status:ready + cc:human` (no `agent:*`); cross-links to PR #4 + PR #71
- **Issue #1017** (S29-005) → terminal state `type:feature + status:ready + cc:human` (no `agent:*`); cross-links to PR #71
- Cycle #1245 Option A executed (RETRO-024 live instance): restored cycle #1206 terminal state after orchestrator cycle #1223 reflexive 4-cat fix re-enabled auto-claim on work-done items

---

## Orchestrator pickup queue (TIER 2 — agent:orchestrator, no owner gate)

| # | Title | Lane | Next action |
|---|---|---|---|
| **#1018** | Sprint 28 closeout ceremony — lightweight mode | `docs/sprints/**` | draft `close.md` + RETRO-024 inline link |
| **#1014** | STORY-S29-002 (tag move v1.0.1 + v0.3.0) | `scripts/` (cross-repo release) | tag move after PR #1008 squash |

---

## Parked until Sprint 30 (TIER 3 — doctrine gaps, scope-locked out)

| # | Title | Status |
|---|---|---|
| **#1024** | RETRO-023 — Cross-repo workstream doctrine codification | parked |
| **#1022** | RETRO-021 — ADR-0038 §Auto-Claim WIP cap definition refinement | parked |
| **#1027** | RETRO-024 (just filed cycle #1245) | filed + arch peer-poked; arch picks up Sprint 30+ |

---

## Doctrine reference

- **ADR-0031** — Owner merge gate (only human squash-merges)
- **ADR-0038** — Auto-Claim WIP cap (2/2 per role)
- **ADR-0049** — d-test framework (≥5 TCs behavioral, ≥3 TCs hygiene/docs)
- **ADR-0055** — Cadence Rule 1 atomic (sister-pattern d-test commits with impl)
- **ADR-0057** — Closes anchor strict format (`Closes #N` vs `Refs #N`)
- **RETRO-018 W6** — branch-ownership matrix (cross-agent push authority NOT in doctrine)
- **RETRO-022** — auto-claim on work-done items = failure mode
- **RETRO-023** (in flight) — cross-repo workstream doctrine

---

— @orchestrator, 2026-07-13T13:45+03:00 (cycle ~#1245, post-Option A execution, pre-PR #1019 push)