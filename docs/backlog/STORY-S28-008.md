# STORY-S28-008: LEGACY-REMOVE peer-poke.sh + ping.sh from calc (after S-08a port)

> **Sprint 28 ID mapping**: Issue #974 ID = `S-08`; PM canonical ID = `STORY-S28-008`

## User Story
As **Atil (current owner of atilcalc)**,
I want **the legacy `scripts/peer-poke.sh` + `scripts/ping.sh` removed from calc after S28-007 S-08a has ported the Auto-Verdict-By hook to tmpl**,
So that **calc's agent invocation surface is single-source (tmpl) without duplicate / shadowing peer-poke paths**.

## Why now
Sprint 28 wave 2 (cleanup, post-S28-007 port). Cadence Rule 1 atomic per ADR-0055: S-08a (port hook to tmpl) → S-08 (remove calc's wrapper) — sequence MUST be preserved. Removing calc's wrapper before S-08a would orphan the Auto-Verdict-By hook.

## Acceptance Criteria
- **AC1** — GIVEN S28-007 has merged (Auto-Verdict-By hook present in tmpl peer-poke.sh.tmpl) WHEN I remove calc's `scripts/peer-poke.sh` + `scripts/ping.sh` THEN calc agents that invoke peer-poke transitively reach tmpl's version (via the `scripts/peer-poke.sh` → tmpl-rendered symlink or path-resolution).
- **AC2** — GIVEN the removal WHEN I grep calc's `.claude/agents/*.md` for `scripts/peer-poke.sh` THEN references resolve to tmpl path (no broken refs).
- **AC3** — GIVEN the removal WHEN I run `bash scripts/peer-poke.sh` in calc THEN output JSON matches tmpl schema (verdict-by:<ts> field present).

## Out of scope
- Removing notify.sh (different retirement path; peer-poke is dual-channel replacement per ADR-0033)
- Modifying calc-specific agent soul files (those are part of S28-005 re-render)

## Open questions
- [ ] Should calc's `scripts/peer-poke.sh` be a symlink to tmpl's or a fully-copied file? → owner: developer
- [ ] Is `ping.sh` used by any human-facing script (vs agent-only)? → owner: developer (audit usages)

## Mockups / references
- ADR-0033 (peer-poke dual-channel doctrine)
- ADR-0055 §1 (Cadence Rule 1 atomic)
- PM-A-DELTA-CL-01 (PM §21 S-08a ordering critical-path finding)

## Dependencies
- **Upstream (HARD GATE)**: S28-007 S-08a MUST land first (Cadence Rule 1 atomic)
- **Downstream**: S28-013 d-test regression (verifies no broken peer-poke references)

## Metrics of success
- **Leading**: calc's `scripts/peer-poke.sh` + `scripts/ping.sh` removed (file count delta = -2)
- **Lagging**: post-removal, calc agent peer-wake cycles work identically to pre-removal (no behavioral regression)

## Cross-references
- Issue #974 (top-14 S-08)
- ADR-0033, ADR-0055 (doctrines)
- S28-007 (S-08a upstream gate)
- PM-A-DELTA-CL-01, PM-A-DELTA-CL-05 (PM §21 cadence findings)