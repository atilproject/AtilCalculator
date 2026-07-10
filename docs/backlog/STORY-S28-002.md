# STORY-S28-002: PORT Issue #389 §Peer-Poke Discipline amend to canonical orchestrator tmpl

> **Sprint 28 ID mapping**: Issue #974 ID = `SL-01a`; PM canonical ID = `STORY-S28-002`

## User Story
As an **orchestrator agent in any new project bootstrapped from `dev-studio-template`**,
I want **my soul file to include the Issue #389 §Peer-Poke Discipline amend block**,
So that **I correctly invoke `scripts/peer-poke.sh` (dual-channel per ADR-0033) instead of legacy `notify.sh` (single-channel broken per ADR-0033)**.

## Why now
Sprint 28 wave 1 (CRITICAL — gap closure). Without §Peer-Poke Discipline in the canonical orchestrator tmpl, every new project orchestrator will use legacy `notify.sh` = peer tmux panes never wake = dead-team-mode.

## Acceptance Criteria
- **AC1** — GIVEN the canonical tmpl orchestrator WHEN I read the soul file THEN I see §Peer-Poke Discipline section with explicit reference to `scripts/peer-poke.sh` + ADR-0033 dual-channel doctrine.
- **AC2** — GIVEN the soul file WHEN I grep for `notify.sh` THEN matches are explicitly framed as LEGACY (no positive recommendation), per ADR-0033 retirement guidance.
- **AC3** — GIVEN a fresh `atilproject/<new-project>` repo WHEN I run `bash scripts/dev-studio-init.sh` THEN the rendered `.claude/agents/orchestrator.md` contains the §Peer-Poke Discipline block matching calc's `.claude/agents/orchestrator.md` (post-port text).

## Out of scope
- Deprecating `notify.sh` at the codebase level (handled separately in S28-008 LEGACY-REMOVE)
- Adding new peer-poke.sh features (in-scope only as part of S28-007 S-08a port)

## Open questions
- [ ] Is `peer-poke.sh` already in the canonical tmpl `scripts/` (per audit §3 inventory)? → owner: developer (verify pre-port)
- [ ] Should §Peer-Poke Discipline include the wake-prerequisite check (auto-ping format `[FROM→TO] <reason>` + link)? → owner: architect

## Mockups / references
- PR #967 cmt 4938118016 (PM 5th-pass SL-01a canonical reframe)
- ADR-0033 (dual-channel peer-poke doctrine)
- Issue #389 (origin — peer-poke discipline codification)

## Dependencies
- **Upstream**: PR #967 squash-merge (audit-baseline.md source-of-truth)
- **Downstream**: S28-005 (re-render — must follow this port)

## Metrics of success
- **Leading**: §Peer-Poke Discipline block present in canonical tmpl orchestrator post-port (vs absent pre-port)
- **Lagging**: new-project orchestrator invokes `peer-poke.sh` instead of `notify.sh` on first peer-wake event

## Cross-references
- Issue #974 (top-14 SL-01a)
- Issue #389 (origin)
- ADR-0033 (doctrine)
- Issue #972 (Path-Verify — sister-pattern port to canonical tmpl)