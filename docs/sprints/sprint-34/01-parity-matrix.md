# Sprint 34 W1 — Parity Matrix Snapshot (S34-001)

> **Source-of-truth:** [`docs/decisions/ADR-0075-template-launcher-parity-matrix.md`](../../decisions/ADR-0075-template-launcher-parity-matrix.md) (architect lane, this snapshot is the sprint-side mirror per AC3)
> **Story:** S34-001 (audit gap-closing sequence step 2)
> **Status:** PROPOSED (architect draft, awaiting Lane 2 docs verdict chain per ADR-0045)
> **Date:** 2026-07-24
> **Author:** @architect (Claude Code / MiniMax-M3)

## Sprint-side mirror

This file is the **sprint-side mirror** of the ADR-0075 parity matrix per AC3 ("Matrix published as `docs/decisions/ADR-NNNN-template-launcher-parity-matrix.md` (architect lane) + appended to `docs/sprints/sprint-34/01-parity-matrix.md` snapshot").

The full classification rationale + per-artifact tables lives in [ADR-0075](../../decisions/ADR-0075-template-launcher-parity-matrix.md). This snapshot provides:

1. Sprint-scoped executive summary (W2 implementation gating)
2. Class tally (rolled-up counts)
3. Sister-pattern cross-references (S32-024 Phase B + RETRO-033)

## Executive summary

PR #1218 audit (Sprint 34 step 1, SQUASH-MERGED 2026-07-24T17:34:14Z sha `44246b4`) identified that the "100% ready" state is **not proven**. S34-001 is the **gating artifact** — the parity matrix that defines W2 implementation scope:

- ~310 artifacts classified into 5 classes (equivalent / divergent / missing / calculator-only / unknown)
- ~50 `equivalent` → S34-002 trivial sync
- ~60 `divergent` → S34-002 forward-port AtilCalc patches
- ~170 `missing` → S34-002 forward-port from AtilCalc
- ~25 `calculator-only` → NO-OP per audit "must not be copied"
- ~5 `unknown` → DEFER to S34-004 evidence

**S34-002/003 W2 implementation scope:** ONLY ship rows where class is `equivalent`/`divergent`/`missing`. Calculator-only + unknown are explicitly out of scope.

## Class tally (rolled up)

| Class | Count | S34-002/003 action |
|---|---|---|
| `equivalent` | ~50 | Trivial sync (low risk) |
| `divergent` | ~60 | Forward-port AtilCalc patches (medium risk) |
| `missing` | ~170 | Forward-port from AtilCalc (medium risk, large surface) |
| `calculator-only` | ~25 | NO-OP (excluded per audit) |
| `unknown` | ~5 | DEFER to S34-004 evidence |
| **Total** | **~310** | |

## Per-section class breakdown

See [ADR-0075](../../decisions/ADR-0075-template-launcher-parity-matrix.md) for full per-artifact tables. Summary:

| § | Section | equivalent | divergent | missing | calculator-only | unknown |
|---|---|---|---|---|---|---|
| A | `.claude/` template layer | 5 | 0 | 2 | 2 | 0 |
| B | `scripts/` layer | ~36 | ~36 | 9 | 0 | 1 |
| C | `scripts/tests/` d-test layer | 1 | 0 | ~150 | ~6+ | 0 |
| D | `docs/decisions/` ADR index | 0 | ~10 | ~14 | 3 | 0 |
| E | Process/operations/context/peer-poke docs | 3 | 0 | 0 | 5 | 0 |
| F | `.github/workflows/` | 5 | 6 | 0 | 0 | 0 |
| G | `.github/ISSUE_TEMPLATE/` + PR template + LABEL-TAXONOMY | 6 | 0 | 1 | 1 | 0 |
| H | `systemd/install` assets | 0 | 2 | 0 | 2 | 0 |
| I | Runner/watcher/task-list/reprime/label/stall-detection | 0 | 5 | 2 | 1 | 0 |
| J | Launcher-facing setup docs | 1 | 0 | 1 | 3 | 0 |

## Sister-patterns

- **S32-024 Phase B summary** (template-side port) — Sprint 32 template-side portage baseline, sister-pattern for this sprint's forward-port direction (AtilCalc → template, NOT reverse)
- **RETRO-033** (Sprint 33 closeout retro) — 19 NEW doctrine lessons + 13 carry-over items inherited by Sprint 34; ADR-0075 respects cycle ~#3968Q+313 owner scope authority + cycle ~#3968Q+226 productive idleness
- **PR #1215** (d-agent-watch-stall-wiring) + **PR #1206/#1207** (d-stall-detect) — Sprint 33 sister-PRs that created the `missing` scripts/d-tests this matrix now classifies for forward-port
- **PR #1218** (Sprint 34 audit) — single-file audit precedent, 9-Lens 9/9 GREEN; this matrix builds on its "must not be copied" filter

## Sprint 34 W2 implementation gating

Per S34-001 AC4 + S34-002 AC1 + S34-003 AC1, the matrix is the **gating artifact** for W2:

> "Each `equivalent`/`divergent` row from S34-001 matrix becomes one PR (Cadence Rule 1 atomic per ADR-0055 §1 — d-test ≥6 TCs + INDEX.md row + CHANGELOG entry single commit)." — S34-002 AC1

This means ~280 forward-port PRs (`equivalent` + `divergent` + `missing`) is the S34-002 sizing estimate, which exceeds the plan's XL sizing. **Owner scope-change approval may be needed** if the actual PR count diverges significantly from this estimate (per file ownership matrix scope-change = owner gate).

## Next steps

1. **Lane 2 docs verdict chain** on this matrix (architect PRIMARY per cycle ~#3968Q+251, 9-Lens per ADR-0045)
2. **Tester Lane 3 d-test-only sign-off** per cycle ~#3642H (doc-only exemption)
3. **PM Lane 1 acceptance** (per S34-001 AC4 — PM is matrix co-author for user-impact classification)
4. **Owner squash** per ADR-0031 (status:ready with reviewer consensus 3/3)
5. **S34-002 W2 kickoff** (after matrix lands — developer lane opens branches per matrix rows)

## Cross-references

- ADR-0075 (full matrix): `docs/decisions/ADR-0075-template-launcher-parity-matrix.md`
- Sprint 34 plan (PR #1219, status:ready): `docs/sprints/sprint-34/00-plan.md`
- PR #1218 audit (sha 44246b4): `docs/sprints/sprint-34/00-audit-template-launcher.md`
- Issue #1221 (STORY-S34-001, priority:P1, status:in-progress): sprint story
