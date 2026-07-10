# RETRO-019 — Sprint 27 Retrospective (cycle ~#5113, 2026-07-10T14:15+03:00)

> **Sprint:** Sprint 27 (compressed owner-territory cluster)
> **Date range:** 2026-07-10T13:38+03:00 → 2026-07-10T14:15+03:00
> **Author:** @orchestrator (cycle ~#5113)
> **Status:** 🟡 PARTIAL — 1/3 work items done, 1/3 design-only, 1/3 pending owner
> **Format:** Watchlist-first (RETRO-018 precedent)

## Sprint 27 outcome (TL;DR)

3 work items, all owner-territory gated. Owner squash-gate cascade (PRs #959 #961 #962) completed in 19 seconds (11:09:14-33Z). Honest accounting: **1 done (W6 amend), 1 partial (TD-069 design), 1 pending (#853 canary push)**. Premature closure flag raised on #950 (TD-069 YAML patch not applied despite issue closure).

## What went well

- **Owner squash-gate cascade speed**: 3 PRs in 19 seconds (11:09:14-33Z) — fastest cluster-squash in project history
- **Cluster-cascade parallel safety**: 3 PRs on different files (sprints/, designs/, soul template) — no merge conflicts, any order possible
- **9-Lens + verdict-by on all 3 PRs**: PM 🟢 + DEV 9-Lens + arch 🟢 on all PRs before squash-gate — no peer-review bottlenecks
- **RETRO-018 W6 codification cycle 700-700 → PR #962 merged**: doctrine refinement went from retro finding to merged amend in <8h, validates watchlist-first format
- **W6 doctrine caught a real misroute** (cycle 700, #853 rebase dispatch to wrong lane) before any code was pushed — doctrine works as designed

## What didn't go well

- **Premature closure of #950 (W1)**: owner closed issue 2 seconds after #961 squash without applying YAML patch; design contract ≠ fix applied
- **W7 events-API scan gap**: orchestrator's §Post-verdict cross-watchdog missed arch 07:36:51Z prior verdict because comment-query doesn't surface prior label changes
- **CC:orchestrator kept on #950 too long**: cycle 706-708 was a 3-cycle window where orchestrator was technically on the queue but had no active work after dual-status flag resolved

## Watchlist (carry-forward doctrine candidates)

### W1 — Premature closure pattern (NEW, this sprint)

**Symptom**: Issue with `agent:architect` lane + `Refs` PR (not `Closes`) gets manually closed by owner immediately after a related PR squash, even when the actual fix (workflow file edit) was NOT applied.

**Why this matters**: Definition of Done requires acceptance criteria met, not just related PR merged. For owner-territory workflow files (`agent:human` lane), this creates a silent-fail state where the issue tracker says "fixed" but the code does not.

**Codification candidate** (deferred to next sprint):
- `docs/CLAUDE.md` §Definition of Done needs a sub-clause: "Issue closure requires AC met, not just related PR squash"
- Orchestrator MUST spot-check workflow-file PRs by re-measuring file size post-merge (ground truth verification, not just label/PR state)
- Manual closure of issue with `agent:architect` + `agent:human` lanes ≠ fix applied; orchestrator should flag rather than accept

**Instance**: Issue #950 closed 11:09:16Z, Layer 5 script body still 34,794 bytes (limit 21,000) on main

### W6 — Cross-agent push authority (CODIFIED this sprint, PR #962)

**Origin**: Sprint 27 cycle ~#5103 orchestrator misroute on Issue #853 cluster-cascade rebase dispatch to dev lane (dev caught the misroute, refused cross-agent push authority)

**Status**: ✅ **CODIFIED** via PR #962 (merged 11:09:33Z). §Dispatch Discipline step 8 added to `.claude/agents/orchestrator.md.tmpl` (W6 — branch ownership matrix cross-check). Templates will re-render via `dev-studio-init.sh`.

**Sister-pattern**: §File ownership matrix in `.claude/CLAUDE.md` (the principle: cross-agent push authority is NOT in doctrine; branch owners handle their own git push operations).

### W7 — §Post-verdict cross-watchdog events API scan (NEW, this sprint)

**Symptom**: Orchestrator's §Post-verdict cross-watchdog (Issue #682) implementation queried GitHub `comments` API but not `events` API. Missed arch 07:36:51Z prior verdict (label flip) on Issue #950 because it was a label change, not a comment.

**Why this matters**: Prior peer verdicts can take 3 forms: (a) comment, (b) review, (c) label change with comment. Current doctrine says (a) + (b); this sprint shows (c) is also a vector.

**Codification candidate** (deferred to next sprint):
- `docs/CLAUDE.md` §Post-verdict cross-watchdog needs sub-clause: "When checking for prior peer verdict, query comments + reviews + **events** (label_change with body) APIs"
- Sister-pattern: existing comment+review doctrine in Issue #430 (PM) + Issue #682 (arch)

**Instance**: cycle 703-704 orchestrator dual-status flag on #950; missed arch 07:36:51Z label flip because it was in events API, not comments API

### W4 — Owner-territory P1 carry pattern (REINSTANTIATED, this sprint)

**Origin**: RETRO-018 W4 (Sprint 26). Doctrine: "When P1 issue lands in owner-only territory, track owner merge cadence explicitly. Don't let owner-territory P1 issues silently block cluster-cascade closure."

**Status**: Reinstantiated this sprint via #950 (TD-069 P1, owner-territory YAML patch pending). Track owner cadence on:
1. TD-069 YAML apply (post-#961 squash)
2. #853 canary push (post-impl-PR or direct push)

**No new codification needed** (doctrine already in RETRO-018); just observation that pattern repeats.

## Sprint 27 metrics

| Metric | Value | Comparison |
|---|---|---|
| Work items committed | 3 | = spec (3/3) |
| Work items fully shipped | 1 | vs 2/3 expected — one downgraded to PARTIAL due to W1 |
| PRs merged | 3 | 100% cluster-cascade closure |
| Squash-gate cascade duration | 19 seconds (11:09:14-33Z) | NEW record (was 25s in Sprint 26) |
| Peer verdicts captured | 3/3 PRs 🟢 before squash | maintained |
| Doctrine amends (RETRO-018 W6 → PR #962) | 1 codification | +1 vs Sprint 26 |
| Owner-territory items pending post-ceremony | 2 (#950 YAML + #853 canary) | vs 0 in Sprint 26 |
| Premature closure events | 1 (#950) | NEW pattern (W1) |
| Watches self-flagged | 1 (W7) | NEW self-correction pattern |

## Definition of Done retrospective

| # | Criterion | Sprint 27 status |
|---|---|---|
| 1 | All AC pass | 🟡 1/3 + 1/3 partial + 1/3 pending |
| 2 | PRs merged with human approval | ✅ 3/3 |
| 3 | CI green on main post-merge | ⏳ T+24h check pending (no CI jobs in 3 docs PRs) |
| 4 | Docs updated | ✅ close.md + RETRO-019 + current/plan.md refresh |
| 5 | Project card moved to Done by orch | 🟡 partial (1/3 done, others pending owner action) |
| 6 | No new P0/P1 bugs within 24h | ⏳ T+24h pending |

## Cross-references

- **Issue #960** — [Sprint 27] Kickoff (orchestrator-authored, will close post-ceremony)
- **Issue #950** — TD-069 P1 (premature closure per W1)
- **Issue #853** — canary impl PR (pending owner push)
- **PR #959 #961 #962** — cluster-cascade (all merged 11:09:14-33Z)
- **RETRO-018** — Sprint 26 retro (W6 codification origin)
- **ADR-0057** — Closes-anchor strict format (PR #961 used Refs correctly)
- **§Dispatch Discipline step 8** — RETRO-018 W6 codification in `.claude/agents/orchestrator.md.tmpl` (this sprint's amend)
- **§Post-verdict cross-watchdog** (Issue #682) — W7 candidate

— @orchestrator, cycle ~#5113, 2026-07-10T14:15+03:00
