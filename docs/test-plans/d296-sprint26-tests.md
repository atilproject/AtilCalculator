# Test Plan: d296 — peer-poke.sh T4 + T5 expansion (Sprint 26 gap-closure)

> **Status**: TDD-RED draft (tester lane, ADR-0044 RED-first)
> **Story**: [#943](https://github.com/atilproject/AtilCalculator/issues/943) — agent:tester, status:in-progress (Sprint 26)
> **Author**: @tester, 2026-07-09T16:35Z
> **Lane**: tester (sign-off per ADR-0044) + architect (TC design lens) + developer (impl-feasibility review)
> **Sister-pattern**: d038 (ping-wrapper, similar 2-arg shape), d081 (auto-verdict-by hook, also tests peer-poke.sh)
> **D-test target**: `scripts/tests/d296-peer-poke-helper.sh` (currently 3 TCs; need ≥5 per ADR-0049)

## Context

**Issue #877 retro + Issue #941 Sprint 26 Kickoff** flagged d-test gap-closure as a Sprint 26 tester-lane work item. The original Issue #877 estimate of "6 d-tests below baseline" was outdated post-cluster #890 (PRs #885, #892, #894, #895, #896, #897, #898, #899, #913, #914). True audit (cycle ~#5095, `/tmp/audit-dtests.sh`) shows **1 d-test below baseline**: `d296-peer-poke-helper.sh` (3 TCs: T1, T2, T3).

This test plan specifies the **2 additional TCs** (T4, T5) needed to bring d296 to ≥5 baseline per **ADR-0049**.

## Scope

### In scope

- T4: `peer-poke.sh human "msg"` invokes notify.sh with `-l info -w -r human` (sister-pattern d038 T4 gap)
- T5: `peer-poke.sh` propagates notify.sh's exit code (sister-pattern: `exec` discipline regression sentinel)
- T4 + T5 must follow existing d296 style: section() + pass/fail pattern, mock notify.sh capture
- Cadence Rule 1 atomic (ADR-0055): T4 + T5 additions + `scripts/tests/INDEX.md` row update = same commit

### Out of scope (parking lot for Sprint 27+)

- Negative test for invalid role (e.g., `peer-poke.sh not-a-role "msg"`) — Issue #296 spec doesn't define role allowlist enforcement; only 5 known roles are tested in T1. Defer to Sprint 27+ if needed.
- Test for `peer-poke.sh human` — T1 already tests 5 known roles, human not in the list per ADR-0033 + Issue #296 scope. Defer.
- Test for `--help`/`-h` flag — not in Issue #296 spec. Defer.
- Multiple-invocation idempotency test — beyond Issue #296 scope (sister-pattern d081 covers verdict-by idempotency).
- Peer-poke Auto-Verdict-By hook tests (d081) — already covered by separate d-test; not within d296 scope.
- Refactoring d296's T1 from "5 roles" to "5 roles + human" — out of scope, no AC for it.

## Acceptance Criteria mapping

| AC | Description | Test cases |
|---|---|---|
| **AC1** | d296 has ≥5 TCs (3 existing + 2 new) | T1, T2, T3, **T4 (NEW)**, **T5 (NEW)** |
| **AC2** | T4 covers `human` role (sister-pattern d038 T4); T5 covers exit code propagation | T4, T5 |
| **AC3** | d296 INDEX.md row updated (Cadence Rule 1 atomic per ADR-0055) | INDEX.md edit (same commit) |
| **AC4** | d296 PR ships with full 4-cat label invariant (ADR-0012) | PR labels |
| **AC5** | All 5 TCs GREEN post-impl (TDD red→green per ADR-0044) | PR check status |

## Test Cases

### TC1 (existing): peer-poke.sh argv capture for 5 roles

**Setup**: mock notify.sh installed at `$SCRIPT_DIR/notify.sh` (captures full argv to MOCK_LOG).

**Steps**:
1. For role in [orchestrator, product-manager, architect, developer, tester]:
   - Truncate MOCK_LOG
   - Run `peer-poke.sh <role> "test message"`
   - Grep MOCK_LOG for `-l info -w -r <role>`
2. Anti-pattern check: grep for `-l <role>` not preceded by `info` (broken form)

**Expected**: All 5 roles pass; anti-pattern check passes (no broken form).

### TC2 (existing): missing args → exit 2 + usage to stderr

**Setup**: peer-poke.sh exists + executable.

**Steps**:
1. Run `peer-poke.sh` (no args) → expect exit 2 + "usage" in stderr
2. Run `peer-poke.sh developer` (role only) → expect exit 2

**Expected**: Both invocations exit 2; usage line printed to stderr in case 1.

### TC3 (existing): bash -n lint

**Setup**: peer-poke.sh exists.

**Steps**:
1. Run `bash -n scripts/peer-poke.sh`

**Expected**: Exit 0 (syntactically valid).

### TC4 (NEW): `peer-poke.sh human "msg"` → invokes notify.sh with `-l info -w -r human`

**Setup**: peer-poke.sh exists + executable; mock notify.sh installed.

**Steps**:
1. Truncate MOCK_LOG
2. Run `peer-poke.sh human "test message for human at $(date +%s)"` (capture stdout/err)
3. Grep MOCK_LOG for `-l info -w -r human`
4. Verify anti-pattern check passes (no `-l human` broken form)

**Expected**: MOCK_LOG contains `-l info -w -r human`; peer-poke.sh invokes notify.sh with dual-channel flags.

**Why sister-pattern**: `scripts/ping.sh` (d038 sister) supports `human` role (its usage line lists 6 roles including human). `scripts/peer-poke.sh` usage line lists only 5 roles (no human). T4 closes that gap — even though peer-poke.sh doesn't list human in usage, the impl has NO role-validation (no allowlist enforcement), so `human` should work. If a future commit adds role validation that excludes `human`, T4 will RED as a regression sentinel.

**Implementation reality** (per dev review cmt 4927XXXXX):
- T4 functionally GREEN on current impl — peer-poke.sh has no role allowlist; it just `exec`s notify.sh with `-r $ROLE`. notify.sh supports human (lines 19/81/111). agent-wake.sh has human=pane 5.
- T4's test verifies the FUNCTIONAL behavior (notify.sh gets called with -l info -w -r human), which already works.
- **Follow-up impl fix** (developer lane, separate PR): peer-poke.sh line 123 usage list shows 5 roles but should list 6 (add '| human'). This is a 1-line docs/UX fix, NOT required for T4 to pass. Dev confirmed "fold into d296 PR scope OK" — but tester doctrine = test code only, so this becomes a separate dev PR linked to Issue #943.

### TC5 (NEW): peer-poke.sh propagates notify.sh exit code

**Setup**: peer-poke.sh exists + executable; MOCK notify.sh that exits 1 (and logs argv).

**Steps**:
1. Set up mock notify.sh to write to MOCK_LOG then `exit 1`
2. Truncate MOCK_LOG
3. Run `peer-poke.sh orchestrator "test message"` → capture exit code
4. Verify MOCK_LOG contains `-l info -w -r orchestrator`
5. Verify peer-poke.sh exit code is 1 (not 0)

**Expected**: peer-poke.sh exit code = 1; MOCK_LOG shows notify.sh was called.

**Why this matters**: peer-poke.sh uses `exec` on notify.sh (line 135). `exec` replaces the process, so notify.sh's exit code IS peer-poke.sh's exit code. If a future refactor changes `exec` to `$()` or drops exit code, callers using `set -e` or `if peer-poke.sh; then` will silently succeed when peer-poke failed. T5 is a regression sentinel.

**Implementation reality** (per dev review cmt 4927XXXXX):
- T5 GREEN on current impl — `exec` replaces the process, so notify.sh's exit code IS peer-poke.sh's exit code.
- T5's test mocks notify.sh to exit 1, runs peer-poke.sh, asserts exit 1. Works as-is.
- No impl change needed.

## Cross-refs

- **Issue #943** — Sprint 26 d-test gap-closure tracking issue
- **Issue #941** — Sprint 26 Kickoff
- **Issue #296** — peer-poke.sh original spec (3-TC scope at origin)
- **Issue #320** — RCA for broken -l <role> syntax (peer-poke.sh closes this footgun)
- **`docs/peer-poke-spec.md` §Deliverable 1** — Reference impl + acceptance (3 TCs; expansion to 5+ TCs is this story)
- **ADR-0044** — RED-first TDD (test plan + RED d-test BEFORE impl)
- **ADR-0049** — d-test framework, ≥5 TCs baseline
- **ADR-0055** — Cadence Rule 1 atomic (d-test file + INDEX.md entry same commit)
- **ADR-0033** — Dual-channel peer-poke doctrine (the script under test)
- **ADR-0038** — Auto-Claim Protocol §Layer 2
- **ADR-0012** — 4-cat label invariant
- **d038** — sister-test for `scripts/ping.sh` (identical wrapper, slightly different arg-edges)
- **d081** — sister-test for Auto-Verdict-By hook on peer-poke.sh
- **`scripts/peer-poke.sh` line 41-43** — Doctrinal contract (3 TCs) explicitly mentioned in source comments

## Notes for developer (impl-feasibility review)

**Dev verdict (received 2026-07-09T19:39:22+03)**:
- T4: 1-line impl change needed (peer-poke.sh line 123 — add ' | human' to usage role list). 1-line docs/UX fix, NOT required for T4 to GREEN. Dev suggested folding into d296 PR scope, but tester doctrine = test code only. → **Separate dev PR, linked to Issue #943**.
- T5: NO impl change. `exec` propagates exit code; T5 just exercises it.
- Sister d038 T4 alignment OK (Cadence Rule 2 sister-pattern).

**Test plan implications**:
- T4 + T5 are TEST COVERAGE gap-closures, not impl changes. The d296 PR is test-only.
- Follow-up dev PR (separate, after d296 lands) updates peer-poke.sh usage line.
- d296 PR will GREEN on T4 + T5 immediately (both pass on current impl) — confirms the gap was in tests, not code.

— @tester, 2026-07-09T16:35Z, AC3 of Issue #943, ADR-0044 RED-first TDD plan
