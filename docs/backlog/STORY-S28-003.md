# STORY-S28-003: Forward-port agent-watch.sh + claim-next-ready.sh to tmpl scripts (sister-pattern)

> **Sprint 28 ID mapping**: Issue #974 ID = `SL-02`; PM canonical ID = `STORY-S28-003`

## User Story
As a **Project Founder bootstrapping a new project from `dev-studio-template`**,
I want **the canonical tmpl `scripts/` directory to ship with `agent-watch.sh` + `claim-next-ready.sh` (already in calc, but missing from tmpl)**,
So that **my new project's 5-agent team gets the full autonomy loop out-of-the-box without waiting for me to hand-port each script**.

## Why now
Sprint 28 wave 1 (foundation). These scripts are the runtime backbone of the 5-agent autonomy loop (ADR-0002). Without them in tmpl, every new project's agents poll GitHub manually or skip the queue entirely.

## Acceptance Criteria
- **AC1** — GIVEN the canonical tmpl `dev-studio-template/scripts/` WHEN I list `.sh` files (excluding `install/` + `tests/`) THEN I see `agent-watch.sh` + `claim-next-ready.sh` (each with sibling d-test in `scripts/tests/`).
- **AC2** — GIVEN a fresh project cloned from tmpl WHEN I run `bash scripts/agent-watch.sh product-manager` THEN output JSON matches the schema in calc's `scripts/agent-watch.sh` (polled_at_utc + new_events[] + next_poll_sec).
- **AC3** — GIVEN `claim-next-ready.sh` WHEN I run it with `WIP=2/2` THEN exit code 3 (hard cap, no claim) — ADR-0038 §Layer 2 spec compliance.
- **AC4** — GIVEN a fresh project WHEN I list `scripts/tests/` THEN I see at minimum `d038-auto-claim.sh` (sister-pattern from calc) GREEN in CI.

## Out of scope
- Forward-porting other scripts (separate stories for `peer-poke.sh` = S28-007, `notify.sh` retirement = S28-008)
- Adding new d-tests beyond d038 baseline (covered in S28-013 d-test regression)

## Open questions
- [ ] Should `agent-watch.sh` + `claim-next-ready.sh` use tmpl-relative paths or calc-relative paths? → owner: developer (path-resolution review)
- [ ] Is the calc `agent-state/` directory structure (per agent) preserved in tmpl? → owner: architect

## Mockups / references
- PR #967 §3 audit-baseline.md (scripts inventory + classification)
- ADR-0002 (autonomy loop)
- ADR-0038 (auto-claim protocol)

## Dependencies
- **Upstream**: PR #967 squash-merge (source-of-truth)
- **Downstream**: S28-005 (re-render — non-blocking; tmpl scripts are runtime, not doctrine-rendered)

## Metrics of success
- **Leading**: `agent-watch.sh` + `claim-next-ready.sh` count in tmpl scripts/ = 2 (vs 0 pre-port, per audit §3)
- **Lagging**: new-project agent poll cadence matches calc (60s default, 15s burst-mode)

## Cross-references
- Issue #974 (top-14 SL-02)
- ADR-0002, ADR-0038 (doctrines)
- audit-baseline.md §3 (scripts inventory gap)