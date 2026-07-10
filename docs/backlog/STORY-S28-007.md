# STORY-S28-007: PORT Auto-Verdict-By hook (ADR-0024 §Path 2) from calc's peer-poke.sh to tmpl's peer-poke.sh.tmpl

> **Sprint 28 ID mapping**: Issue #974 ID = `S-08a`; PM canonical ID = `STORY-S28-007`

## User Story
As **any peer agent in a new project bootstrapped from `dev-studio-template`**,
I want **the Auto-Verdict-By hook (ADR-0024 amendment, Issue #681) to be present in tmpl's `peer-poke.sh.tmpl`**,
So that **peer-review ver自动 timestamps propagate to PR labels (`verdict-by:<ts>`), preventing the stale-verdict-supersede pattern (RETRO-016 #2)**.

## Why now
Sprint 28 wave 1 (CRITICAL — gates S28-008 LEGACY-REMOVE per Cadence Rule 1 atomic). Without S-08a port, removing calc's `peer-poke.sh` wrapper would orphan the Auto-Verdict-By hook = silent regression on RETRO-016 codification.

## Acceptance Criteria
- **AC1** — GIVEN the canonical tmpl `scripts/peer-poke.sh.tmpl` WHEN I grep for `verdict-by` THEN I see the Auto-Verdict-By hook pattern matching calc's `scripts/peer-poke.sh`.
- **AC2** — GIVEN tmpl peer-poke.sh.tmpl WHEN I run a fresh project clone + init.sh + `bash scripts/peer-poke.sh` THEN output JSON includes the `verdict-by:<ts>` field per ADR-0024.
- **AC3** — GIVEN the rendered tmpl peer-poke.sh WHEN a peer verdict is posted THEN PR label `verdict-by:<ts>` is added atomically with the verdict comment (no race window per RETRO-016).

## Out of scope
- Implementing new auto-verdict features (this is port-only, no new logic)
- Modifying calc's `peer-poke.sh` (this is forward-port to tmpl, calc remains source-of-truth pre-removal)

## Open questions
- [ ] Should the tmpl version include the d-test sister-pattern (e.g., d-test verifying hook presence)? → owner: tester
- [ ] Is the `verdict-by` label format backward-compatible with calc's existing usage? → owner: architect

## Mockups / references
- PR #967 §3 audit-baseline.md (scripts inventory)
- ADR-0024 §Path 2 (auto-verdict-by hook spec)
- Issue #681 (origin — RETRO-016 #2 codification)
- PM-A-DELTA-CL-01 (PM §21 finding: S-08a ordering critical-path)

## Dependencies
- **Upstream (HARD GATE)**: NONE — S-08a is the FIRST script port in Cadence Rule 1 chain
- **Downstream (HARD GATE)**: S28-008 S-08 LEGACY-REMOVE — MUST NOT land before S28-007 (Cadence Rule 1 atomic per ADR-0055 §1)

## Metrics of success
- **Leading**: tmpl peer-poke.sh.tmpl contains Auto-Verdict-By hook (vs absent pre-port)
- **Lagging**: new-project peer-verdict cycles don't show RETRO-016 stale-verdict-supersede pattern

## Cross-references
- Issue #974 (top-14 S-08a)
- ADR-0024, ADR-0055, ADR-0033 (doctrines)
- Issue #681, PM-A-DELTA-CL-01 (origin)