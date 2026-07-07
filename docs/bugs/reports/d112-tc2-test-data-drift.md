# d112 TC2 Test-Data Drift — sister-pattern to Issue #852, FIX SHIPPED

> **Author:** @tester
> **Date filed:** 2026-07-06T09:25Z
> **Date fixed:** 2026-07-06T12:42Z (cycle ~#5080)
> **Status:** ✅ FIX SHIPPED — PR #856 (https://github.com/atilproject/AtilCalculator/pull/856), branch `tests/d112-tc2-test-data-drift`, HEAD `19148c3`, self-signed APPROVED per Issue #414 §Dispatch Discipline + RETRO-005 #26. Terminal handoff state (`status:ready + cc:human`), awaiting owner merge gate. Issue #855 will auto-close on merge per `Closes #855` anchor.
> **Severity:** P3 (test drift, not impl regression; d-test RED-state framing works, but the expected literal value drifted)
> **Refs:** Issue #852 (sister), ADR-0019-amendment-3 (BUDGET_MULTIPLIER doctrinal home), TD-046 (BUDGET_MULTIPLIER precedence), TD-049 (perf-test isolation future work), d112, d121 (sister-pattern), d109 (sister-pattern), d117 (sister-pattern), `tests/conftest.py` line 117-127

## TL;DR

`tests/conftest.py` bumped `BUDGET_MULTIPLIER` self-hosted map value from `2.0` → `6.0` (cycle ~#4249, RCA for self-hosted VM perf variance under pytest-cov). But `scripts/tests/d112-conftest-env-var-precedence.sh` TC2 still hardcodes the OLD expected value `2.0 10.0`. So d112 TC2 fails locally with `6.0 10.0` (current impl) ≠ `2.0 10.0` (test expectation).

**Sister-pattern to Issue #852** (d649 TC5 design bug, where test target `README.md` not in `RENDERED_PATHS`).

## Evidence (local, 2026-07-06T09:25Z)

### 1. d112 local run

```
$ bash scripts/tests/d112-conftest-env-var-precedence.sh --self-test
==== TC2: env unset, RUNNER_ENV=self-hosted → 2.0 / 10.0 (Sprint 22 PIVOT canonical baseline) ====
  ✗ FAIL — TC2 — self-hosted map fallback broken
    expected '2.0 10.0' (exit 0); got exit=0 stdout='6.0 10.0' stderr=''

==== Summary ====
  PASS: 6
  FAIL: 1
```

### 2. conftest.py current canonical value

`tests/conftest.py` lines 117-127:
```python
# Bumped 2.0 → 6.0 to absorb the
# ~13x slowdown observed on self-hosted VM (local: p99 ~35ms; CI: p99 446ms
# with BUDGET_MULTIPLIER=5 → 250ms budget, failing). The 6.0 baseline
# mirrors the env var override that's currently operational on this repo
# (vars.BUDGET_MULTIPLIER=5 set 2026-06-30, future work: isolate perf tests
# in a no-cov CI job to remove the 2x coverage overhead — see TD-049).
_BUDGET_MULTIPLIER_MAP = {
    "self-hosted": 6.0,
    "github-hosted": 1.0,
    "local": 1.0,
}
```

### 3. Live conftest import (sanity check)

```
$ unset BUDGET_MULTIPLIER SUBPROCESS_TIMEOUT_S; RUNNER_ENV=self-hosted python3 -c "
import sys; sys.path.insert(0, 'tests')
import conftest
print('multiplier:', conftest.BUDGET_MULTIPLIER)
print('timeout:', conftest.SUBPROCESS_TIMEOUT_S)
"
multiplier: 6.0
timeout: 10.0
```

### 4. Sister-pattern coverage (env-var precedence family)

| d-test | Local result | Notes |
|---|---|---|
| d109 (BUDGET_MULTIPLIER env block) | 8/8 PASS ✅ | TC1-TC8 all GREEN (CI workflow env block landed) |
| d112 (conftest env-var precedence) | 6/7 PASS, 1 FAIL ❌ | TC2 FAIL — `2.0` expectation vs `6.0` impl |
| d117 (ATILCALC_EVALUATE_PERSIST gate) | 6/6 PASS ✅ | Sprint 23 dev lane env-var gate landed |
| d121 (cross-user ATC_SERVICE_USER) | 7/7 PASS ✅ | PR #764 ATC_SERVICE_USER fallback landed |

## Recommended Fix (test-only per ADR-0044)

Update `scripts/tests/d112-conftest-env-var-precedence.sh` TC2 expectation from `2.0 10.0` → `6.0 10.0` (canonical Sprint 22 PIVOT Faz 1.2 baseline per `tests/conftest.py` line 117-127).

Optionally add a sister-TC (TC8 or new TC) that documents the 2.0 → 6.0 bump history per the comment in conftest.py line 117-122.

Plus: also update `scripts/tests/INDEX.md` row for d112 to reflect the new expected value.

## Risk Notes

- **Impl is correct** — the 6.0 multiplier was a deliberate bump (cycle ~#4249) per ADR-0019-amendment-3 doctrinal chain. The "broken" is in the test, not the impl.
- **d112 sister-pattern to d109/d117/d121** — when this fix lands, all 4 env-var precedence d-tests will be GREEN locally.
- **Not a CI-blocker** — d112's contract holds (precedence chain correct, fail-loud on garbage env, etc.); only the expected literal value drifted.

## Action Plan (when rate limit resets ~09:59:31Z)

1. **File a sister-issue** to Issue #852: "d112 TC2 test-data drift — BUDGET_MULTIPLIER expected 2.0 but impl is 6.0" — or comment on existing issue if one exists.
2. **Open d112v2 PR** (test-only, 1-line expectation update + INDEX.md row refresh + Cadence Rule 1 atomic per ADR-0055 §1).
3. **Cross-link to Issue #852** as sister-pattern in both the PR description and INDEX.md row.
4. **Re-run all 4 env-var d-tests** locally post-fix → confirm 4/4 GREEN families.

— @tester, 2026-07-06T09:25Z, local finding awaiting API rate-limit reset for GitHub artifacts