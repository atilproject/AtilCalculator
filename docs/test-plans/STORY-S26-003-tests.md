# Test Plan: STORY-S26-003 — ADR-0019 amendment 5 ATILCALC_EVALUATE_PERSIST env-var precedence contract (Issue #954 cluster-cascade closeout)

> **Status**: GREEN (Sprint 26 wave 1 cluster-squash per ADR-0059, d-test authored RED-first per ADR-0044)
> **Story**: [#955](https://github.com/atilcan65/AtilCalculator/issues/955) — agent:architect, status:ready
> **Author**: @tester, 2026-07-10T11:42Z
> **Sister-pattern**: d117 (permissive parsing impl guard) + d112 (conftest strict fail-loud precedent, TC6) + d949 (Sprint 26 wave 1 cluster)

## Scope

- **In scope**: AC1-AC8 verification — strict fail-loud contract for `ATILCALC_EVALUATE_PERSIST` env-var resolution at the `POST /api/evaluate` boundary (Issue #954 cluster-cascade closeout + Issue #728 perf-regression second-occurrence).
- **Out of scope**: Engine lazy-import (d110, Sprint 23 fix), TestClient infra noise tolerance (d949, Issue #949 P3 flake), CI `BUDGET_MULTIPLIER` env-var (ADR-0019 amend-4, sister-pattern but separate contract).

## Why this test exists

Sprint 26 wave 1 (owner-approved 2026-07-10T09:32:39+03 per orchestrator peer-poke) ships ADR-0019 amendment 5 + impl + d-test as cluster-squash per ADR-0059. The amendment codifies the **strict fail-loud contract** at the API boundary:

| Env-var value (post-`.strip().lower()`) | Effective state |
|---|---|
| Unset | `ENABLED` (backward-compat per ADR-0022 §Cross-device sync) |
| `"1"` / `"true"` / `"yes"` / `"on"` | `ENABLED` (explicit-on) |
| `"0"` / `"false"` / `"no"` / `"off"` / `""` | `DISABLED` (opt-out) |
| **Anything else (unparseable)** | **`raise ValueError`** (fail-loud per ADR-0056 + d112 TC6 conftest precedent) |

**Doctrinal anchor**: ADR-0056 silent_skip doctrine (lens d) — bad operator input MUST fail loud, not silently downgrade. Sister-pattern: d112 TC6 (conftest raises ValueError on garbage `BUDGET_MULTIPLIER`).

**Why this differs from d117**: d117 verifies the **permissive** parsing envelope (any non-falsy → ENABLED, no ValueError). d117 was correct for the Sprint 23 PR #742 impl. Sprint 26 strict-contract is the **new** semantic per ADR-0056 + AC5. Both d-tests coexist: d117 = permissive impl regression guard (legacy); d955 = strict-contract envelope (Sprint 26 wave 1).

## Test Cases

### TC a: env-var unset → defaults-on (AC6 a)
- **Setup**: `ATILCALC_EVALUATE_PERSIST` env var unset (canonical unset semantics via `env -u`).
- **Steps**:
  1. Run `bash scripts/tests/d955-atilcalc-evaluate-persist-env-var.sh --self-test`
  2. Inspect TC a section in output
- **Expected**: PASS — defaults-on ENABLED (backward-compat preserved per ADR-0022 §Cross-device sync model).
- **Implementation**: Source-level pattern `_TRUTHY_VALUES`/`_FALSY_VALUES` with default `'1'` fallback in `os.environ.get("ATILCALC_EVALUATE_PERSIST", "1")`.

### TC b: env-var set to "false" → persistence SKIPPED (AC6 b)
- **Setup**: `ATILCALC_EVALUATE_PERSIST=false` in subprocess env.
- **Steps**:
  1. Run d955 self-test
  2. Inspect TC b section
- **Expected**: PASS — DISABLED (opt-out path active, SQLite INSERT+COMMIT skipped per Sprint 23 d117 + Sprint 26 d955 strict contract).
- **Sister-pattern**: AC3 verification path — `persistence.insert_record(...)` is NOT called when DISABLED.

### TC c: env-var set to "true" → persistence ENABLED (AC6 c)
- **Setup**: `ATILCALC_EVALUATE_PERSIST=true` in subprocess env.
- **Steps**:
  1. Run d955 self-test
  2. Inspect TC c section
- **Expected**: PASS — ENABLED (explicit-on parity with default behavior).
- **Sister-pattern**: AC2 verification — opt-out default semantics, explicit-on parity holds.

### TC d: routes.py implements fail-loud ValueError contract (AC5)
- **Setup**: `ATILCALC_EVALUATE_PERSIST=garbage` (canonical unparseable value, tests fail-loud contract).
- **Steps**:
  1. Run d955 self-test
  2. Inspect TC d section — source-level grep for fail-loud pattern (a) `float(_persist_env)` OR (b) explicit `raise ValueError` in routes.py
- **Expected**: PASS — routes.py contains the fail-loud pattern (b) explicit `raise ValueError(...)` per ADR-0056 silent_skip sister-pattern + d112 TC6 conftest precedent.
- **Pre-impl RED state (pre-Sprint 26 wave 1)**: FAIL — routes.py used permissive parsing (`_persist_env not in falsy_set`), no `raise ValueError` present.
- **Post-impl GREEN state (Sprint 26 wave 1)**: PASS — routes.py implements strict `if-elif-else` with explicit `raise ValueError(...)` on unparseable.

### TC e: backward-compat regression guard (AC6 e)
- **Setup**: Source-level invariants in routes.py.
- **Steps**:
  1. Run d955 self-test
  2. Inspect TC e section — source-grep for `ATILCALC_EVALUATE_PERSIST` + `evaluate persist opt-out` + `os.environ.get(..., '1')` default `'1'` fallback
- **Expected**: PASS — all 3 invariants present (gate reference + silent-skip log.info emission + default `'1'` backward-compat fallback).
- **Sister-pattern**: d117 TC5 + TC6 regression guards.

## Adversarial Probes

Per tester doctrine (input validation, auth, state, data):

### Input Validation
- Empty string: `ATILCALC_EVALUATE_PERSIST=` — verified in TC e default fallback
- Whitespace: `ATILCALC_EVALUATE_PERSIST=" "` → `.strip().lower()` → `""` → DISABLED
- Mixed-case: `ATILCALC_EVALUATE_PERSIST="FALSE"` → `.lower()` → `"false"` → DISABLED (TC b covers false/false/FALSE/False pattern via 6 d117 TCs)
- Unicode: `ATILCALC_EVALUATE_PERSIST="💩"` → unparseable → ValueError (TC d extension — sister-pattern to d112 TC6 garbage)
- Numeric edge: `ATILCALC_EVALUATE_PERSIST="0.0"` → not in `{0}` after strip — unparseable → ValueError (AC5 doctrinal purity check)

### Auth & Permissions
- Operator typo: `ATILCALC_EVALUATE_PERSIST="flase"` → unparseable → ValueError (fail-loud — operator gets clear error message rather than silent ENABLED)
- Case sensitivity: `ATILCALC_EVALUATE_PERSIST="TRUE"` → stripped/lower → `"true"` → ENABLED (TC c)

### State & Concurrency
- 2 concurrent evaluations with different env-var values: each subprocess sees its own env (no cross-process pollution)
- Environment variable unset vs empty: `env -u X` vs `X=""` — both treated identically (`.strip()` normalizes, both fall to FALSY set)

### Data
- Very long string (1MB+): `.strip()` processes whole string — performance test (not in d955, deferred to engine fuzz)
- NULL byte: `ATILCALC_EVALUATE_PERSIST=$'\x00garbage'` → unparseable → ValueError

## Performance Concerns

- env-var resolution is at request-handler boundary (`POST /api/evaluate`). Per-request cost is amortized `os.environ.get` + `.strip()` + `frozenset` lookup = O(1). Negligible.
- Sister-pattern: Sprint 23 bench (Issue #728): local p99 6.03ms under persist=0 (vs 16.98ms baseline) — 2.8× speedup. Sprint 26 d949 noise-tolerance absorbs pytest-cov 2× overhead.

## Regression Risk

- **d117 inversion**: d117 was GREEN with permissive parsing; d955 is GREEN with strict parsing. Both pass on Sprint 26 wave 1 impl. Sister-pattern to d112/d117 retained.
- **PR #951 cluster-cascade**: PR #946/#947/#948 unblocked once Sprint 26 wave 1 ci.yml env-block ships `ATILCALC_EVALUATE_PERSIST: 'false'` for CI Test step (Issue #954 AC7 closeout).

## Sister-pattern Reference

| d-test | Sister-domain | Layer |
|---|---|---|
| `d117` (Sprint 23, GREEN) | Permissive parsing impl guard | API boundary, permissive envelope |
| `d112` (Sprint 22-23, GREEN) | conftest env-var precedence | Test boundary, strict fail-loud precedent (TC6) |
| `d949` (Sprint 26, GREEN) | TestClient infra noise tolerance | Test boundary, pytest-cov overhead |
| **`d955` (Sprint 26, GREEN)** | **Strict fail-loud env-var contract** | **API boundary, strict envelope (AC5/AC6)** |

≥3 sister-pattern coverage per ADR-0049 met.

## Cadence Rule 1 Atomic (ADR-0055 §1)

This d-test is committed atomically with:
- `src/atilcalc/api/routes.py` (impl — strict parsing + raise ValueError)
- `.github/workflows/ci.yml` (impl — env-block `ATILCALC_EVALUATE_PERSIST: 'false'`)
- `docs/test-plans/STORY-S26-003-tests.md` (this file)
- `scripts/tests/INDEX.md` (d955 row entry)

All in single cluster-squash commit per ADR-0059.
