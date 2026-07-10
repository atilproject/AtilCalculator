# STORY-S28-004: PORT Issue #414 dispatch-discipline amend block to canonical orchestrator tmpl (third amend-block port)

> **Sprint 28 ID mapping**: Issue #974 ID = `SL-02a`; PM canonical ID = `STORY-S28-004`

## User Story
As an **orchestrator agent in any new project bootstrapped from `dev-studio-template`**,
I want **my soul file to include the Issue #414 §Dispatch Discipline amend block (6-step cross-agent verification)**,
So that **I correctly enforce ground-truth re-query within 30s window + peer-flag ack in verdict header (per Issue #430 + Issue #682)**.

## Why now
Sprint 28 wave 1 (CRITICAL — third amend-block port). Issue #414 codifies the 6-step doctrine; without it in canonical tmpl, new-project orchestrators will skip ground-truth re-query = silent verdict drift (PR #460 / #462 / #465 / #679 LIVE INSTANCES).

## Acceptance Criteria
- **AC1** — GIVEN the canonical tmpl orchestrator soul WHEN I read §Dispatch Discipline THEN I see 6 numbered steps: (1) comments-vs-reviews cross-check, (2) label freshness check, (3) CI status check, (4) cross-peer consensus re-query within 30s, (5) doctrinal cite, (6) pre-verdict cross-check.
- **AC2** — GIVEN the soul WHEN I grep for `30s` (timing window) THEN I see ≥1 match per §Timing window doctrine (Issue #430).
- **AC3** — GIVEN the canonical tmpl WHEN I read §Post-verdict cross-watchdog THEN I see Issue #682 ack-pattern: `Ack <prior-peer-role>: [<flag verbatim> | "No prior peer verdict found"]`.

## Out of scope
- Implementing dispatch-discipline checks in code (doctrine codification only)
- Modifying the verification scripts (separately handled)

## Open questions
- [ ] Is Issue #414 amend block currently in calc's `.claude/agents/orchestrator.md` (post-PR #962)? → owner: architect (verify pre-port)
- [ ] Should §Post-verdict cross-watchdog (Issue #682) be co-located with §Dispatch Discipline or split into §Watchdog? → owner: architect

## Mockups / references
- PR #967 cmt 4938118016 (PM 5th-pass, NEW SL-02a added per architect cycle ~767)
- Issue #414 (origin, RETRO-005 #26 codification)
- Issue #430 (PM §Pre-verdict cross-check)
- Issue #682 (architect §Post-verdict cross-watchdog)
- docs/CLAUDE.md §Dispatch Discipline (full doctrine summary)

## Dependencies
- **Upstream**: PR #967 squash-merge; PR #962 (W6 amend block already merged, sister-pattern reference)
- **Downstream**: S28-005 (re-render — must follow)

## Metrics of success
- **Leading**: amend-block count in canonical tmpl = 3/3 post-port (vs 2/3 after S28-001 + S28-002)
- **Lagging**: next-new-project orchestrator cycle behavior matches calc (6-step dispatch active)

## Cross-references
- Issue #974 (top-14 SL-02a)
- Issue #414, Issue #430, Issue #682 (origin doctrines)
- ADR-0038 (sister-pattern WIP cap enforcement)
- PR #962 (W6 amend precedent)