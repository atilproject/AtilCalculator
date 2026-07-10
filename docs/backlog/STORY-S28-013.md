# STORY-S28-013: d-test regression suite for d050b + d063 + d082 sister-patterns (≥3 TCs each)

> **Sprint 28 ID mapping**: Issue #974 ID = `d-test regression`; PM canonical ID = `STORY-S28-013`

## User Story
As a **tester agent maintaining `dev-studio-template`'s d-test framework**,
I want **d-test regression coverage for the new sister-pattern d-tests (d050b dispatch-discipline + d063 verdict-supersede + d082 workflow-pin + d083 workflow-hardening)**,
So that **Sprint 28 architecture changes don't silently regress pre-existing sprint-tested behavior (RETRO-016 #3 LIVE INSTANCE: PR #679 tester missed arch L5 race)**.

## Why now
Sprint 28 wave 3 (tester-lane, R-MED). Per ADR-0049 (d-test framework) + ADR-0044 (RED-first TDD): every doctrine codification needs ≥3 TCs as regression defense. Sprint 28 introduces 4 new sister-pattern tests; each must have ≥3 TCs.

## Acceptance Criteria
- **AC1** — GIVEN the d050b dispatch-discipline d-test WHEN I run `bash scripts/tests/d050b-dispatch-discipline.sh` THEN ≥3 TCs PASS (covers: §Timing window 30s, §Pre-verdict cross-check comments+reviews, §Post-verdict cross-watchdog peer-flag ack).
- **AC2** — GIVEN d063 verdict-supersede d-test WHEN run THEN ≥3 TCs PASS (covers: stale-verdict detection, verdict-by:<ts> label atomicity, RETRO-016 #2 pattern).
- **AC3** — GIVEN d082 workflow-pin d-test WHEN run THEN ≥3 TCs PASS (covers: 0 mutable refs, SHA-pin pattern detection, false-positive negative test).
- **AC4** — GIVEN d083 workflow-hardening d-test WHEN run THEN ≥3 TCs PASS (covers: permissions block presence, timeout-minutes range check, calc-vs-tmpl parity diff).
- **AC5** — GIVEN all 4 d-tests WHEN I list `scripts/tests/` THEN each has sister-pattern structure (RED-first per ADR-0044) + ≥3 TCs + ≥1 negative test.

## Out of scope
- Authoring new d-tests beyond the 4 sister-patterns (Sprint 28 scope is regression coverage only)
- Implementing the d-test framework itself (per ADR-0049)

## Open questions
- [ ] Which test runner shells the d-test framework supports (bash only? pytest-style?)? → owner: tester
- [ ] Should the d-tests pass on fresh-project clone (no calc-specific assumptions)? → owner: tester (template-portability)

## Mockups / references
- ADR-0044 (RED-first TDD)
- ADR-0049 (d-test framework, ≥5 TCs doctrine)
- ADR-0058, ADR-0059 (parent ADRs whose close-out these tests verify)

## Dependencies
- **Upstream (CRITICAL)**: S28-011 (TD-029) + S28-012 (TD-028) must land first — d082/d083 cannot test code that doesn't exist
- **Downstream**: Sprint 29 d-test framework expansion

## Metrics of success
- **Leading**: 4/4 d-tests have ≥3 TCs each (vs current: 0/4 with structure)
- **Lagging**: CI green on tmpl-repo's `scripts/tests/d*` invocations post-Sprint 28

## Cross-references
- Issue #974 (top-14 d-test regression)
- ADR-0044, ADR-0049 (doctrines)
- S28-011, S28-012 (upstream gate)