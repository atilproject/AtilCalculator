# RETRO-034 — Sprint 34 Retrospective (Forward-Port + Disposable Bootstrap + New-Project-Steps)

> **Author**: @orchestrator (cycle ~#3968Q+972, 2026-07-26T22:46+03)
> **Scope**: Sprint 34 forward-port 23/23 SHIPPED-functional + S34-004 + S34-006 twin-squash
> **Status**: Filed for Sprint 35 backlog pickup

## Sprint 34 in numbers

- 23/23 forward-port stories SHIPPED-functional ✅
- 17 cluster-squashes (CS#22-#37 inclusive, ledger TERMINAL)
- 5 stories closed Lane 0 (S34-001 + S34-003 + S34-004 + S34-005 + S34-006)
- 5 NEW DOCTRINE codified mid-sprint
- 4 doctrine refinements
- 4 retro lessons (this file)

## Retro lesson 1 — Sprint scope discipline pays off

Sprint 34 started with 7 stories (#1220-#1227). Mid-sprint owner directive cycle ~#3968Q+930 redefined scope to "gap-closing only, no new work" and killed the ADR-0078 escalation as "meaningless right now".

Result: 23/23 forward-port SHIPPED-functional + 2 sprint-extras (S34-004 + S34-006) on time. Scope discipline was the single biggest contributor to throughput.

**How to apply**: When owner says "gap-closing only" or "scope-locked", DO NOT add new stories mid-sprint even if TIER 1 escalations surface. The scope discipline IS the throughput engine.

## Retro lesson 2 — Cross-repo work-done-elsewhere pattern is now mature

5 Lane 0 closes this sprint:
- #1221 (S34-001) — PR #1228 + #1219 in same-repo
- #1223 (S34-003) — PR #17 in sister-repo (launcher)
- #1224 (S34-004) — PR #224 in sister-repo (template)
- #1226 (S34-006) — PR #225 + #18 in sister-repo (template + launcher)
- #1231 — pre-existing close cycle ~#459

The cycle ~#3968Q+459 RETRO-024 NEW DOCTRINE is now battle-tested. The Lane 0 close pattern with 4-cat INVARIANT (agent:human ADDED) preserves board hygiene without breaking cross-repo work semantics.

**Sub-doctrine gap surfaced**: RETRO-024 reservation (terminal Closes reserved for future row 280 same-repo PR) vs cycle ~#459 Lane 0 close are DIFFERENT patterns for different issue types:
- **Lane 0 close**: terminal stories (single PR, work done elsewhere)
- **RETRO-024 reservation**: umbrella stories (multiple child stories, terminal Closes in future comprehensive PR)

**How to apply**: Before Lane 0 closing a cross-repo issue, ASK: is this an umbrella? If yes, RETRO-024 reservation. If no, Lane 0 close.

## Retro lesson 3 — Twin-squash is the standard for sister-repo doc mirrors

3 twin-squashes this sprint:
- CS#25+#26 (PR #17 + #215) — IMMEDIATE 5s gap
- CS#36+#37 (PR #225 + #18) — IMMEDIATE 11s gap

The IMMEDIATE twin-squash pattern (cycle ~#3968Q+685 doctrine refinement) is now the standard for sister-repo doc mirrors. The cadence range 8min-9h17min accommodates both IMMEDIATE (5-11s) and STANDALONE (>60s gap) cluster-squash windows.

**How to apply**: When dispatching sister-repo doc mirror work, expect IMMEDIATE twin-squash within 5-15s of canonical home squash. TIER 1 escalation should mention "twin-squash cluster" not "single PR" to set owner expectations.

## Retro lesson 4 — 4-cat invariant enforcement gap on launcher repo

PR #17 (S34-003 SQUASH-MERGED) and PR #18 (S34-006 mirror OPEN) both have incomplete 4-cat — no agent:* label. Sister-pattern consistent, but doctrine gap: PR #17 was merged without 4-cat enforcement, perpetuating the gap to PR #18.

Root cause: label-check.yml may have launcher-repo exception, OR PR #17 was squash-merged with retro-fix per cycle ~#3968Q+414 PR-self-blocking CI doctrine.

**Action**: Sprint 35 backlog pickup — file ADR-NNNN for ADR-0012 label-check enforcement evolution, audit all launcher repo PRs for 4-cat gap, decide on retroactive fix vs future-only enforcement.

## Carry-over lessons (NEW DOCTRINE filed Sprint 35 backlog)

1. **cycle ~#3968Q+911** — Owner-squash-witness signal (peer witnesses squash content within 60s of owner squash per ADR-0031)
2. **cycle ~#3968Q+933** — Lane 3 re-query arch verdict COMMENT content (not just verdict-by timestamp label) before 5-flag atomic
3. **cycle ~#3968Q+940** — Investigate before framing anomaly as hallucination (NEW DOCTRINE candidate)
4. **cycle ~#3968Q+941** — Multi-remote awareness STRIKE 2 (`git push tmpl-official` for cross-repo PRs)

## Sprint 35 — recommendations

1. **Pick up Sprint 35 backlog** — 5 NEW DOCTRINE filings + ADR-0012 enforcement evolution + Deploy FAILURE RCA follow-up
2. **Row 280 dispatch** — terminal Closes anchor for #1222 (S34-002 umbrella) per RETRO-024 reservation
3. **ADR-0078 owner Variables config** — 5 vars needed for Deploy FAILURE resolution

## Anti-patterns (avoid in Sprint 35+)

- ❌ Push to wrong remote without `git remote -v` first (cycle ~#3968Q+687 STRIKE 2)
- ❌ Frame ground-truth anomaly as hallucination without investigating (cycle ~#3968Q+940)
- ❌ Apply Lane 3 verdict-by without re-querying arch verdict COMMENT content (cycle ~#3968Q+933)
- ❌ Lane 0 close umbrella issues (use RETRO-024 reservation instead)
- ❌ Add new stories mid-sprint without owner scope relaxation (cycle ~#3968Q+930 scope discipline)

🤖 Generated with [Claude Code](https://claude.com/claude-code)