# Sprint 27 Plan — TD-069 design contract + W6 doctrine amend + #853 canary carry (owner-territory cluster)

> **Sprint window**: 2026-07-10T13:38+03:00 → 2026-07-10T14:15+03:00 (compressed ceremony, ~37 min)
> **Author**: @orchestrator (cycle ~#5110, 2026-07-10T13:40+03:00)
> **Source issues**: #960 [Sprint 27] Kickoff + #950 (TD-069 P1) + #853 (canary mirror P3)
> **Source data**: owner directive 2026-07-10T13:38+03:00 ("ok bu 3ü yeter yeni story olmucak bunları bitirince ben yeni direktif vereceğim. sen baslat 27 yi") + Issue #950 prior tech-debt row (PR #952) + RETRO-018 W6 origin
> **Status**: 🟡 **FROZEN** (cycle ~#5110, 2026-07-10T13:38+03:00) — owner directive verbatim, no PM curation needed (3 owner-territory direct items)

## Sprint goal

> Resolve Sprint 26 carry-over with an **owner-territory cluster** + codify RETRO-018 W6 (cross-agent push authority) — no new PM-curated stories, no scope expansion.

**Outcome criteria**:

- **OC1**: #950 (TD-069 P1) — design contract in main (PR #961 squash, Refs #950) + W1 verdict on premature-closure flag (re-open + apply YAML OR keep closed + file follow-up)
- **OC2**: #853 (canary mirror P3) — impl PR opened + owner squash + ADR-0010 canary mirror push executed
- **OC3**: W6 doctrine codification — `.claude/agents/orchestrator.md.tmpl` §Dispatch Discipline step 8 amended (PR #962 squash, Closes W6)
- **OC4**: Sprint 27 close.md + RETRO-019 authored at ceremony time (PR #959 squash, Closes #941)
- **OC5**: No new P0/P1 bugs filed against Sprint 27 scope (T+24h check post-cluster-cascade)

## Committed stories (final ~1.5sp scope, owner-direct)

| # | Issue | Work item | Priority | Lane (owner) | sp | Source |
|---|---|---|---|---|---|---|
| 1 | [#950](https://github.com/atilcan65/AtilCalculator/issues/950) | **TD-069 design contract** (label-check.yml L461 Layer 5 expression-length) | P1 | architect (design) → owner (YAML apply) | ~0.5sp | Sprint 26 tech-debt row PR #952 + design contract `docs/designs/TD-069-proposed-patch.md` |
| 2 | [#853](https://github.com/atilcan65/AtilCalculator/issues/853) | **canary mirror ISSUE_TEMPLATE/config.yml** | P3 | developer (impl PR) + owner (squash + canary mirror push) | ~0.5sp | Issue #841 AC4 surface 4 gap (Sprint 24 W2 canary AC4 cycle #5070) |
| 3 | (doctrine) | **W6 §Dispatch Discipline step 8 amend** (RETRO-018 W6 codification) | P3 | orchestrator (propose) → owner (merge) | ~0.25sp | RETRO-018 W6 origin: Sprint 27 cycle ~#5103 orchestrator misroute on #853 cluster-cascade rebase + dev correction |
| (orchestration) | **Sprint 27 close + RETRO-019** | (ceremony) | P3 | orchestrator | ~0.25sp | Standard sprint close ceremony |

**Total committed**: ~1.5sp

## Sprint window — compressed cluster-cascade ceremony

Owner directive verbatim (2026-07-10T13:38+03:00):

> "ok bu 3ü yeter yeni story olmucak bunları bitirince ben yeni direktif vereceğim. sen baslat 27 yi"

This is a **no-curation cluster** — owner provided the 3 work items directly. No PM grooming needed (no user stories, no acceptance criteria authoring, no spec docs). Orchestrator's job:

1. Activate 3 work items in board (`status:ready` + lane assignment)
2. Dispatch owner-territory PRs (architect for #950 design, dev for #853 impl, orchestrator for W6 amend)
3. Owner squash-gate cascade (per ADR-0031)
4. Author close.md + RETRO-019 within ceremony window
5. Refresh `docs/sprints/current/plan.md`

## Cluster-cascade sequence (planned)

Per ADR-0031 owner squash-gate + ADR-0059 cluster-squash pattern:

| # | PR | Owner | Status | Notes |
|---|---|---|---|---|
| 1 | #961 — TD-069 design contract | architect → owner | draft → squash | Refs #950 (NOT Closes — design ≠ fix, per W1 doctrine) |
| 2 | #959 — Sprint 26 closeout ceremony + RETRO-018 | orchestrator → owner | draft → squash | Closes #941 (Sprint 26 kickoff) |
| 3 | #962 — W6 §Dispatch Discipline amend | orchestrator → owner | draft → squash | Codifies RETRO-018 W6 |

**Order**: any (parallel-safe — different files, no merge conflicts).

## Lane assignment

Per file ownership matrix + doctrine:

- **`docs/designs/`** → architect lane (PR #961)
- **`.claude/agents/`** → human-only territory, agents propose via PR (PR #962)
- **`docs/sprints/`** → orchestrator lane (PR #959 + close.md + RETRO-019)
- **`.github/workflows/`** → human-only territory, agents propose via PR (TD-069 YAML apply, owner squash-gate)

## Owner carry-over (post-ceremony)

After Sprint 27 squash-cascade, owner carry-over queue:

| # | Item | Lane | Source |
|---|---|---|---|
| 1 | TD-069 YAML apply on `.github/workflows/label-check.yml` | owner (workflow file edit) | `docs/designs/TD-069-proposed-patch.md` |
| 2 | #853 canary mirror impl PR push | owner (squash) + canary mirror doctrine (ADR-0010) | Issue #853 |
| 3 | Sprint 28 directive | owner (verbal/written) | "bunları bitirince ben yeni direktif vereceğim" |

## Watches / doctrine candidates (Sprint 27 expected entries)

- **W1**: Premature closure pattern (NEW, this sprint) — codification deferred
- **W6**: Cross-agent push authority (codified this sprint via PR #962)
- **W7**: §Post-verdict cross-watchdog events API scan (NEW, this sprint) — codification deferred
- **W4**: Owner-territory P1 carry pattern (reinstantiated, doctrine in RETRO-018)

## Doctrine compliance

- **§PM lane definition (Sprint 13+ LOCKED)** — PM not cc'd on Sprint 27 (no PM-curated stories)
- **§4-cat invariant (ADR-0012)** — all cluster PRs + issues birth-contract compliant
- **§Handoff Label Discipline (ADR-0015)** — atomic 4-flag flips on all handoffs
- **§Closes-anchor strict format (ADR-0057)** — Refs #950 in PR #961 (design ≠ fix)
- **§no-self-standby (Issue #238)** — substantive orchestrator cycles 700-712 documented
- **§Dispatch Discipline 6-step (Issue #414)** — ground truth re-queried before each broadcast
- **§File ownership matrix** — `.github/workflows/` + `.claude/agents/` correctly preserved as owner-only

— @orchestrator, cycle ~#5110, 2026-07-10T13:40+03:00 (Sprint 27 frozen plan, owner-direct cluster, 3 work items + ceremony)