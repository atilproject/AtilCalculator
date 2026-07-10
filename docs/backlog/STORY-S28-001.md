# STORY-S28-001: PORT RETRO-018 W6 amend block to canonical orchestrator tmpl

> **Sprint 28 ID mapping**: Issue #974 ID = `SL-01`; PM canonical ID = `STORY-S28-001`
> **Naming-scheme drift**: Per §20.0 audit-baseline.md, the canonical scheme is `S28-W1-NN` (8 W1 stories reserved). Issue #974 kickoff uses old `SL-/S-/TD-` prefixes; PM STORY files use sprint-prefixed `STORY-S28-NNN` per existing backlog pattern (S21-/S26-). **§21 follow-up**: orchestrator to apply §20.0 scheme at kickoff-of-kickoff.

## User Story
As an **orchestrator agent in any new project bootstrapped from `dev-studio-template`**,
I want **my soul file to include the W6 cross-agent push authority amend block (from RETRO-018)**,
So that **I correctly enforce branch-ownership matrix + cross-agent push authority without re-deriving it from cycle history**.

## Why now
Sprint 28 wave 1 (CRITICAL — gap closure). The W6 amend codifies the doctrine lesson from Sprint 26 cycle ~#5103 (orchestrator misroute on #853 cluster-cascade rebase). Without this port, every new project orchestrator will re-derive W6 from RETRO-018 = systemic doctrine loss across templates.

## Acceptance Criteria
- **AC1** — GIVEN the canonical tmpl `dev-studio-template/.claude/agents/orchestrator.md.tmpl` (1506 LOC source) WHEN a fresh project runs `bash scripts/dev-studio-init.sh` THEN the rendered `.claude/agents/orchestrator.md` contains the W6 amend block (3 SOUL AMEND blocks total: W6 + #389 + #414).
- **AC2** — GIVEN the rendered `.claude/agents/orchestrator.md` WHEN I grep for `W6 amend` THEN I see ≥1 match with `RETRO-018` cited as origin.
- **AC3** — GIVEN the orchestrator soul post-port WHEN I read §Dispatch Discipline step 8 THEN it reads: "Branch-ownership matrix check + cross-agent push authority (W6 per RETRO-018)" — matches calc's `.claude/agents/orchestrator.md` §Dispatch Discipline step 8 verbatim.

## Out of scope
- Implementing W6 enforcement logic (doctrine codification only, no code)
- Modifying `peer-poke.sh` or `notify.sh` (separate stories: S28-007/S28-008)
- Branch protection config (TD-069 separately handled in PR #964, closed)

## Open questions
- [ ] Does the canonical tmpl currently have 0/3 amend blocks (need full port) or 1-2/3 (need partial port)? → owner: architect (cycle ~768 verified via PM 5th-pass)
- [ ] Should the W6 amend block reference Issue #389 explicitly or stay general? → owner: architect (depends on SL-01a ordering)

## Mockups / references
- PR #967 cmt 4938118016 (PM 5th-pass reconciliation, §6.4 SL-01 canonical tmpl reframe)
- PR #967 §6.2 audit-baseline.md (3 amend blocks gap analysis)
- RETRO-018 W6 (origin doctrine)

## Dependencies
- **Upstream**: PR #967 squash-merge (so audit-baseline.md is on main as source-of-truth)
- **Downstream**: S28-005 (re-render — must run AFTER S28-001 + S28-002 + S28-004 ports land in canonical tmpl)

## Metrics of success
- **Leading**: amend-block count in canonical tmpl = 3/3 post-port (vs 0/3 pre-port, per audit §6.2)
- **Lagging**: next-new-project orchestrator cycle behavior matches calc orchestrator (W6 enforcement active)

## Cross-references
- Issue #974 (Sprint 28 Kickoff, top-14 SL-01)
- Issue #972 (Path-Verify Doctrine codification, owner picked option a)
- PR #967 commit df7f213 (PM 5th-pass SL-01 reframe)
- ADR-0012 (4-cat label invariant on all 14 stories)
- ADR-0015 (atomic 4-flag handoff for sprint scope)