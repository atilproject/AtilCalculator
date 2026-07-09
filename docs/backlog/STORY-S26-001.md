# STORY-S26-001 (DRAFT): d-test ≥5 TC baseline gap-closure — 6 d-tests below ADR-0049 floor

## User Story

As **a tester maintaining the d-test framework's ≥5 TC baseline (ADR-0049) and Cadence Rule 1 atomic discipline (ADR-0055 §1)**,
I want **a single umbrella d-test expansion PR that brings all 6 currently-below-baseline d-tests up to ≥5 TCs (or documents why a smaller TC count is justified)**,
So that **the d-test framework's audit signal stays clean per Issue #877 §tester lane follow-up row + Issue #883 v5 audit sister-pattern (Issue #890 dev-lane cluster expansion precedent)**.

## Why now

Per orchestrator wake 2026-07-09T19:28:38Z (Sprint 26 kickoff FIRING, release v1.0.1 published, Issue #941 status:in-progress), Sprint 26 scope includes "d-test gap-closure (P2, tester, 6 d-tests below ≥5 TC baseline per #877 §tester lane follow-up row)". Issue #877 §tester lane follow-up row = canonical source. Issue #883 v5 audit closed 2026-07-08T05:24:56Z (parent), Issue #890 dev-lane d-test cluster already expanded 9 d-tests to ≥5 baseline (sister-pattern precedent). Sprint 26 picks up the remaining 6.

## Scope (6 d-tests below ≥5 baseline, per local audit 2026-07-09T16:30Z)

| # | d-test | Current TCs | Path | Why below |
|---|---|---|---|---|
| 1 | d120 | 1 | `scripts/tests/d120-context-watchdog-pct-change-override.sh` | Single-axis coverage, no edge cases |
| 2 | d106 | 3 | `scripts/tests/d106-soul-template-version-pin.sh` | Soul-version mismatch is multi-state, needs ≥5 |
| 3 | d319 | 3 | `scripts/tests/d319-verdict-by-tdd-red-exclusion.sh` | RED-exclusion semantics need more TCs |
| 4 | d043 | 3 | `scripts/tests/d043-platform-constraint-linter-ext.sh` | Platform-constraint surface is broad |
| 5 | d296 | 3 | `scripts/tests/d296-peer-poke-helper.sh` | peer-poke idempotency needs edge cases |
| 6 | d067 | 4 | `scripts/tests/d067-proactive-scan-per-role-overflow.sh` | WIP-overflow is multi-role, needs ≥5 |

Local audit method: `grep -cE "^#\s+(TC?)[0-9]+:" scripts/tests/d*.sh` and filter `<5`. Test author to verify each count at sizing ceremony.

## Acceptance Criteria

- **AC1** — Each of the 6 d-tests in §Scope has ≥5 TCs (per ADR-0049 ≥5 baseline) post-PR. Counts documented in INDEX.md row per Cadence Rule 1 atomic (ADR-0055 §1).
- **AC2** — d-test expansions follow RED-first TDD (ADR-0044): pre-impl ≥1 TC FAILS by design (new TCs target the gap), post-impl all PASS.
- **AC3** — Each new TC has a sister-pattern reference (per ADR-0049 §Sister-pattern). New TCs follow existing TCs in the same file's narrative (no orphan TCs).
- **AC4** — d-test INDEX.md updated atomically with file changes (single PR per d-test, per ADR-0046 small-commits + ADR-0055 §1 Cadence Rule 1).
- **AC5** — CI integration path documented per d058/d890 sister-pattern: which d-test goes into `.github/workflows/lint-and-test.yml` next, with sequencing rationale (Issue #890 cluster sequencing).
- **AC6** — Post-PR: 6 d-tests all meet baseline; no new baseline violations in adjacent sister-tests (no regression to OTHER d-tests).
- **AC7** — d-test scope audit (`scripts/tests/INDEX.md` row + d-test count + sister-pattern refs) updated in same PR; Cadence Rule 1 atomic verified.

## Out of scope

- **CI integration** of the 6 d-tests (deferred to follow-up PR per d058/d296/d320/d806 sequencing — not part of TC count, separate concern)
- **d-test count audit of OTHER d-tests** (only the 6 named in §Scope; broader audit = Issue #877 follow-up audit, separate STORY)
- **d-test deprecation** of any d-test (no d-test is being removed, only expanded)
- **TC content review** (only counts are checked; TC semantic correctness is per-tester-lane at sizing)

## Open questions

- [ ] Are the 6 d-tests the COMPLETE list per Issue #877 §tester lane follow-up row, or are there more (post-audit) → tester to confirm at sizing
- [ ] Local audit count vs Index.md count may diverge for some d-tests (INDEX.md shows post-Issue-#890-expansion state) → tester to verify ground truth
- [ ] Should the 6 d-test expansions ship as 1 umbrella PR (Cadence Rule 1 atomic umbrella) or 6 small PRs (ADR-0046 small-commits per d-test) → arch+tester to decide
- [ ] Sequencing with #931 (TD-067c) d-test (S25-002) — does S26-001 land before/after S25-002? → orch+tester to decide
- [ ] Per d-test expansion: 0.25sp or 0.5sp each (6 × 0.5sp = 3.0sp, or 6 × 0.25sp = 1.5sp) — tester proposes at sizing

## Mockups / references

- Issue #877 §tester lane follow-up row (canonical source)
- Issue #883 v5 audit (parent, closed 2026-07-08T05:24:56Z)
- Issue #890 dev-lane d-test cluster (sister-pattern — 9 d-tests expanded to ≥5 baseline in dev lane)
- Issue #941 (Sprint 26 Kickoff §Scope row 3)
- `scripts/tests/INDEX.md` (d-test registry, Cadence Rule 1 atomic)
- d058 (first d-test CI-integrated, 10 TCs sister-pattern)
- d020a (5 TCs sister-pattern, Issue #890 cycle ~#4033 P1 fix)
- ADR-0044 (RED-first TDD)
- ADR-0049 (d-test framework ≥5 TCs baseline)
- ADR-0055 §1 (Cadence Rule 1 atomic)
- ADR-0059 (cluster-squash doctrine — applies if 1-umbrella-PR path chosen)

## Dependencies

- **Upstream**:
  - Issue #877 (tester follow-up audit source)
  - Issue #883 v5 audit (parent, closed)
  - Issue #890 sister-pattern (dev-lane cluster expansion precedent)
  - Local audit ground truth (PM 2026-07-09T16:30Z, may diverge from INDEX.md — tester to verify)
- **Downstream**:
  - CI integration follow-up PR (sister-pattern d058/d296/d320/d806 sequencing)
  - Future Issue #877 v6 audit (next baseline gap-closure wave)

## Metrics of success

- **Leading**: 6 d-tests in §Scope all reach ≥5 TCs in single PR cycle
- **Leading**: 0 regressions to other d-tests (no new <5 baseline elsewhere)
- **Lagging**: Issue #877 §tester lane follow-up row cleared, no further d-test below baseline surfaced in next audit

## Sprint
Sprint 26 (per Issue #941 §Scope row 3)

## Priority
P2 (per Issue #941 §Scope row 3)

## Story points (proposed by PM, joint sizing TBD per ADR-0021)

Proposed: **1.5sp — single umbrella PR with 6 d-test expansions (avg 0.25sp per d-test)**.

PM proposes 1.5sp based on Issue #890 sister-pattern (9 d-tests expanded in dev lane, ~0.3sp each). Joint sizing requires:
- **tester** (d-test authoring, count verification, RED-first TCs)
- **architect** (Cadence Rule 1 atomic verification, INDEX.md structure)
- **developer** (any file-move / refactor cost — likely 0 here, all in-place)
- **owner ratification**

Tester lane primary ownership per Issue #113 label-authority.
