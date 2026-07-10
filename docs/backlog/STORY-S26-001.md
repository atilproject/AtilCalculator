# STORY-S26-001 (DRAFT): d-test ≥5 TC baseline gap-closure — d296 (3 → ≥5 TCs)

## User Story

As **a tester maintaining the d-test framework's ≥5 TC baseline (ADR-0049) and Cadence Rule 1 atomic discipline (ADR-0055 §1)**,
I want **the single remaining below-baseline d-test (d296-peer-poke-helper.sh, 3 TCs → ≥5 TCs) expanded with +2 TCs covering idempotency edge cases not in the original v3-authoring scope**,
So that **the d-test framework's audit signal clears post-cluster #890 closure (5 of the original 6 closed via PRs #885/#892/#894/#895/#896/#897/#898/#899/#913/#914), per Issue #877 §tester lane follow-up row + Issue #943 authoritative audit (117 d-test files, 116 PASS / 1 FAIL)**.

## Why now

Per orchestrator wake 2026-07-09T19:28:38Z (Sprint 26 kickoff FIRING, release v1.0.1 published, Issue #941 status:in-progress), Sprint 26 scope included "d-test gap-closure (P2, tester, 6 d-tests below ≥5 TC baseline per #877 §tester lane follow-up row)".

**Reconciliation landed 2026-07-09T16:30Z (cycle ~#5095, Issue #943 tester audit):** the Issue #877 estimate of "6 d-tests below baseline" is **OUTDATED post-cluster #890**. Tester's authoritative audit (/tmp/audit-dtests.sh — 117 d-test files, counts unique TC/C/T/TU/F markers per file, threshold ≥5) shows:

| Audit result | Count |
|---|---|
| Total d-test files | 117 |
| PASS (≥5 TCs) | 116 |
| FAIL (<5 TCs) | **1** |

The single remaining below-baseline d-test is `scripts/tests/d296-peer-poke-helper.sh` (3 TCs → needs +2 TCs).

The other 5 d-tests from the Issue #877 estimate have been closed by cluster #890 d-test expansion PRs (now ≥5 TCs): d046a, d046b, d050b, d095, d097, d052, d036d, d820, d070b, d091, d093, d100, d105, d320, d048.

## Scope (1 d-test below ≥5 baseline, per Issue #943 tester audit 2026-07-09T16:30Z)

| # | d-test | Current TCs | After | Path | Why below |
|---|---|---|---|---|---|
| 1 | d296 | 3 (T1, T2, T3) | ≥5 (+2 minimum) | `scripts/tests/d296-peer-poke-helper.sh` | Authored at 3-TC scope (Issue #296 + `docs/peer-poke-spec.md` §Deliverable 1 acceptance). Needs +2 TCs covering idempotency edge cases (e.g. duplicate ping suppression, missing-script exit code, malformed args regression guard, multi-role load). |

Audit method: `/tmp/audit-dtests.sh` (counts unique TC/C/T/TU/F markers per d-test file). Tester authoritative. PM 2026-07-09T16:30Z reconciles against Issue #943 ground truth.

## Acceptance Criteria

- **AC1** — `scripts/tests/d296-peer-poke-helper.sh` extends from 3 TCs to ≥5 TCs (add 2 TCs minimum, per Issue #943 + ADR-0049 ≥5 baseline). Per ADR-0055 §1 Cadence Rule 1 atomic.
- **AC2** — d-test expansion follows RED-first TDD (ADR-0044): pre-impl ≥1 new TC FAILS by design (new TC targets the gap), post-impl all 5+ TCs PASS.
- **AC3** — Each new TC has a sister-pattern reference (per ADR-0049 §Sister-pattern). New TCs follow existing TCs in the same file's narrative (no orphan TCs).
- **AC4** — d-test INDEX.md row updated atomically with file changes (single PR for this d-test, per ADR-0046 small-commits + ADR-0055 §1 Cadence Rule 1).
- **AC5** — CI integration sequencing per d058/d296/d320/d806 sister-pattern: d296 CI integration considered in same PR if d296 is the next-in-sequence (follow Issue #890 cluster sequencing). If not next, defer to follow-up PR.
- **AC6** — Post-PR: 117 d-test files audited; d296 ≥5 TCs; no new baseline violations in adjacent sister-tests (no regression to OTHER d-tests).
- **AC7** — Issue #943 closed (`status:done` transition handled by orchestrator per ADR-0013).

## Out of scope

- **CI integration** of d296 (deferred to follow-up PR per d058/d296/d320/d806 sequencing — separate concern from TC count)
- **d-test count audit of OTHER d-tests** (only d296 named in §Scope; broader audit = separate STORY, Issue #877 v6 audit cycle)
- **d-test deprecation** of any d-test (no d-test being removed, only d296 expanded)
- **TC content review** of OTHER d-tests (only d296 new TCs reviewed)
- **STORY-S26-001 supersession** — the canonical Sprint 26 entry is now this reconciled STORY (Issue #943 is the underlying source-of-truth issue, STORY is the backlog record).

## Open questions

- [x] Reconciliation of original "6 d-tests" estimate vs audited "1 d-test" ground truth → **RESOLVED 2026-07-09T16:30Z, Issue #943 audit**. This STORY tracks d296 alone.
- [ ] +2 new TCs cover idempotency edge cases (e.g. duplicate ping suppression, missing-script exit code) → tester to confirm specific edge cases at sizing
- [ ] CI integration of d296 in same PR vs follow-up per d058/d296/d320/d806 sequencing → tester+orchestrator to confirm at sizing

## Mockups / references

- **Issue #943** — Sprint 26 d-test ≥5 TC baseline gap-closure — d296 (tester authoritative source, 2026-07-09T16:30Z)
- Issue #877 §tester lane follow-up row (canonical source, retro estimate of 6 — now reconciled to 1 via cluster #890)
- Issue #883 v5 audit (parent, closed 2026-07-08T05:24:56Z)
- Issue #890 + cluster (#885/#892/#894/#895/#896/#897/#898/#899/#913/#914) — dev-lane d-test cluster expansion precedent (5 of original 6 closed here)
- Issue #941 (Sprint 26 Kickoff §Scope row 3 — original 6-d-test scope, now reconciled to 1)
- `scripts/tests/INDEX.md` (d-test registry, Cadence Rule 1 atomic)
- Issue #296 + `docs/peer-poke-spec.md` §Deliverable 1 (d296 original 3-TC authoring scope)
- d058 (first d-test CI-integrated, 10 TCs sister-pattern)
- d020a (5 TCs sister-pattern, Issue #890 cycle ~#4033 P1 fix)
- ADR-0044 (RED-first TDD)
- ADR-0049 (d-test framework ≥5 TCs baseline)
- ADR-0055 §1 (Cadence Rule 1 atomic)

## Dependencies

- **Upstream**:
  - Issue #877 §tester lane follow-up row (canonical source, retro estimate)
  - Issue #883 v5 audit (parent, closed)
  - Issue #890 cluster (sister-pattern — 9 d-tests expanded to ≥5 baseline in dev lane, closed 5 of 6)
  - Issue #943 tester audit (authoritative ground truth, reconciled to 1 d-test)
  - Local PM audit 2026-07-09T16:30Z (cross-check against Issue #943 ground truth)
- **Downstream**:
  - CI integration follow-up PR (sister-pattern d058/d296/d320/d806 sequencing)
  - Issue #877 v6 audit (next baseline gap-closure wave)
  - Future Issue #943 closure (orchestrator lane per ADR-0013)

## Metrics of success

- **Leading**: d296 reaches ≥5 TCs in single PR cycle (Issue #943 AC1)
- **Leading**: 0 regressions to other 116 d-tests (no new <5 baseline elsewhere)
- **Leading**: Issue #943 closed post-PR-merge (orchestrator lane)
- **Lagging**: Issue #877 §tester lane follow-up row fully cleared, no further d-test below baseline in next audit

## Sprint
Sprint 26 (per Issue #941 §Scope row 3, reconciled via Issue #943 tester audit 2026-07-09T16:30Z)

## Priority
P2 (per Issue #941 §Scope row 3)

## Story points (proposed by PM, joint sizing TBD per ADR-0021)

Proposed: **0.5sp — single d-test (d296) expansion with +2 TCs + INDEX.md row + Issue #943 closure**.

PM proposes 0.5sp based on:
- Issue #890 sister-pattern (9 d-tests expanded in dev lane, ~0.3sp each)
- d296 specific scope: pure d-test expansion (no impl), 2 new TCs at ~0.2sp each = 0.4sp
- INDEX.md row + Issue #943 closure = 0.1sp

Joint sizing requires:
- **tester** (d-test authoring, RED-first TCs, count verification)
- **architect** (Cadence Rule 1 atomic verification, INDEX.md structure)
- **developer** (any file-move / refactor cost — likely 0 here, all in-place)
- **owner ratification** (PR merge gate)

Tester lane primary ownership per Issue #113 label-authority.

## Reconciliation history (2026-07-09T16:30Z cycle ~#5095)

| Time | Source | Claim | Reconciliation status |
|---|---|---|---|
| 2026-07-09T15:30Z | Issue #877 retro | 6 d-tests below ≥5 baseline | ORIGINAL estimate (pre-cluster #890) |
| 2026-07-09T16:30Z | Issue #943 tester audit | 1 d-test below baseline (d296) | AUTHORITATIVE ground truth, supersedes #877 estimate |
| 2026-07-09T18:30Z (this STORY) | PM STORY-S26-001 reconciliation | Track d296 alone | RECONCILED — STORY reflects #943 ground truth |

Reconciliation rationale: Issue #877 was a sprint-22 retro estimate (pre-cluster #890 d-test expansion PRs). Cluster #890 closed 5 of the original 6 d-tests. Tester's Issue #943 audit is the post-cluster authoritative source. STORY-S26-001 reconciles to Issue #943.

### Reconciliation notes

- **STORY-S26-001 scope reduction**: 6 d-tests → 1 d-test (d296)
- **SP re-estimate**: 1.5sp (6 d-tests) → 0.5sp (1 d-test)
- **Sprint 26 capacity re-allocation**: 1.0sp reclaimed (1.5sp - 0.5sp) — orchestrator can re-fill at sizing ceremony or defer to Sprint 27
- **Issue #943 status**: stays `status:in-progress` (tester owns lane per ADR-0038 §Layer 2; STORY-S26-001 is the PM-side record, Issue #943 is the tester-side tracking issue)
- **No scope drift to Sprint 26 framework**: still tester lane, still P2, still gap-closure theme — only scope volume corrected

---

**Filed by:** @product-manager, 2026-07-09T16:35Z (initial grooming) → 2026-07-09T18:30Z (reconciliation per Issue #943 tester audit, cycle ~#5095)

**Refers to:**
- Issue #941 (Sprint 26 Kickoff, source of scope)
- Issue #943 (tester authoritative audit, reconciliation source)
- Issue #877 (retro source, supersession documented)
- Issue #890 (cluster expansion precedent, 5 of 6 closed)
