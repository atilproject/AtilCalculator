# Test Plan: STORY-S21-022 — Smoke Test Script (5 sub-scenarios, CI gate)

> **Status**: TDD-RED draft (tester lane, ADR-0044 RED-first)
> **Story**: [#649](https://github.com/atilproject/AtilCalculator/issues/649) — agent:tester, status:backlog (Sprint 21 Wave 4)
> **Author**: @tester, 2026-07-04T04:30Z
> **Lane**: tester (sign-off per ADR-0044) + architect (CI integration per ADR-0012 label invariant) + developer (impl) + @product-manager (PM)
> **Sister-pattern**: d070a/b/c (template-render regression), d093 (TEMPLATE-README polish), d137 (init-script idempotency — if exists)
> **D-test target**: `scripts/tests/faz5-smoke.sh` (≥5 TCs per ADR-0049 baseline; this story = 5 sub-scenarios = 5 TCs)

## Scope

### In scope

- `scripts/tests/faz5-smoke.sh` shell script covering 5 sub-scenarios:
  - **Sub-scenario 1**: dry-run (no init — script invoked with `--dry-run` flag, must NOT mutate filesystem)
  - **Sub-scenario 2**: broken-tmpl (init fails — given a malformed `CLAUDE.md.tmpl`, init must exit non-zero with clear error)
  - **Sub-scenario 3**: idempotency (rerun OK — running init twice produces no diff vs running once)
  - **Sub-scenario 4**: fresh-clone (full init — given an empty target dir, init clones/scaffolds, exits 0)
  - **Sub-scenario 5**: manual-edit (init rerender preserves manual edits — given manually-edited rendered file, init rerender must NOT overwrite)
- `.github/workflows/ci.yml` smoke-test job — trigger on template-repo PRs
- Exit-code-as-gate discipline (CI red = no merge)

### Out of scope

- Network-based smoke (real GitHub clone) — Sprint 22+ per Issue #649 §Out of scope
- Performance benchmarking (smoke test = correctness, not perf)
- Cross-OS compatibility (Linux-only target per ADR-0017)
- The smoke-test implementation itself (developer lane); this doc covers the test contract

## Acceptance Criteria mapping

| AC | Description | Test cases |
|---|---|---|
| **AC1** | `scripts/tests/faz5-smoke.sh` covers 5 sub-scenarios | TC1, TC2, TC3, TC4, TC5 |
| **AC2** | Smoke test triggers in `.github/workflows/ci.yml` on template-repo PRs | TC6 |
| **AC3** | Exit code gates merge (CI red = no merge) | TC7 |

## Test Cases

### TC1: Sub-scenario 1 — dry-run (no filesystem mutation)

**Setup**: clean tmp dir `${SMOKE_TMP}/dry-run`; smoke script available.

**Steps**:
1. Run `bash scripts/tests/faz5-smoke.sh --dry-run --scenario=dry-run --workdir=${SMOKE_TMP}/dry-run`
2. Capture exit code `$?`
3. Snapshot filesystem state: `find ${SMOKE_TMP}/dry-run -type f | sort > ${SMOKE_TMP}/before.txt`
4. Run smoke test again (this time WITHOUT `--dry-run`)
5. Snapshot filesystem state again: `find ${SMOKE_TMP}/dry-run -type f | sort > ${SMOKE_TMP}/after.txt`
6. Compare: `diff ${SMOKE_TMP}/before.txt ${SMOKE_TMP}/after.txt` → must be empty

**Expected**: First run exits 0; filesystem snapshot unchanged. Second run (no --dry-run) creates expected files; `diff` between snapshot before/after = empty (proves dry-run made no changes).

### TC2: Sub-scenario 2 — broken-tmpl (init fails with clear error)

**Setup**: create malformed `CLAUDE.md.tmpl` with unclosed `${VAR}` placeholder; smoke test fixture copies it into `${SMOKE_TMP}/broken-tmpl/CLAUDE.md.tmpl`.

**Steps**:
1. Run `bash scripts/tests/faz5-smoke.sh --scenario=broken-tmpl --workdir=${SMOKE_TMP}/broken-tmpl`
2. Capture exit code `$?` and stderr
3. Assert exit code = non-zero (init failure)
4. Assert stderr contains substring like `error:` or `parse` or `template syntax`

**Expected**: Exit code != 0; stderr contains explicit error message (no silent failure). Sister-pattern to d070a (template-render handles malformed tmpl gracefully).

### TC3: Sub-scenario 3 — idempotency (rerun produces no diff)

**Setup**: clean tmp dir `${SMOKE_TMP}/idempotency`; init available.

**Steps**:
1. Run init: `bash scripts/dev-studio-init.sh --workdir=${SMOKE_TMP}/idempotency`
2. Snapshot: `find ${SMOKE_TMP}/idempotency -type f -exec sha256sum {} \; | sort > ${SMOKE_TMP}/run1.txt`
3. Run init again: `bash scripts/dev-studio-init.sh --workdir=${SMOKE_TMP}/idempotency`
4. Snapshot: `find ${SMOKE_TMP}/idempotency -type f -exec sha256sum {} \; | sort > ${SMOKE_TMP}/run2.txt`
5. Compare: `diff ${SMOKE_TMP}/run1.txt ${SMOKE_TMP}/run2.txt` → must be empty

**Expected**: Idempotent — running init twice produces no diff in file hashes. Sister-pattern to d137 (init-script idempotency if exists), d070a (template-render is idempotent).

### TC4: Sub-scenario 4 — fresh-clone (full init)

**Setup**: clean tmp dir `${SMOKE_TMP}/fresh-clone` (empty); smoke test fixture copies minimal git repo (or uses `--source=local`).

**Steps**:
1. Run `bash scripts/tests/faz5-smoke.sh --scenario=fresh-clone --workdir=${SMOKE_TMP}/fresh-clone --source=${PWD}`
2. Capture exit code `$?`
3. Assert exit code = 0
4. Verify expected files exist: `${SMOKE_TMP}/fresh-clone/CLAUDE.md`, `${SMOKE_TMP}/fresh-clone/scripts/dev-studio-init.sh`, `${SMOKE_TMP}/fresh-clone/.claude/agents/`
5. Verify file content sanity: `head -10 ${SMOKE_TMP}/fresh-clone/CLAUDE.md` contains "Project Context"

**Expected**: Exit 0; expected files exist; content sanity check passes. Sister-pattern to Issue #653 AC1+AC2 fresh-clone validation (PM lane).

### TC5: Sub-scenario 5 — manual-edit (rerender preserves manual edits)

**Setup**: tmp dir `${SMOKE_TMP}/manual-edit`; init produces baseline; user manually edits `CLAUDE.md` adding a custom section.

**Steps**:
1. Run init: `bash scripts/dev-studio-init.sh --workdir=${SMOKE_TMP}/manual-edit`
2. Snapshot baseline: `cp ${SMOKE_TMP}/manual-edit/CLAUDE.md ${SMOKE_TMP}/baseline-claude.md`
3. User manual edit: `echo "\n## My custom section\n\nThis is my manual addition." >> ${SMOKE_TMP}/manual-edit/CLAUDE.md`
4. Run init rerender: `bash scripts/dev-studio-init.sh --workdir=${SMOKE_TMP}/manual-edit --rerender`
5. Verify: `grep -q "My custom section" ${SMOKE_TMP}/manual-edit/CLAUDE.md` must succeed
6. Verify baseline preserved: `${SMOKE_TMP}/manual-edit/CLAUDE.md` still contains original content (e.g., "Project Context" heading)

**Expected**: Manual edits preserved through rerender. Sister-pattern to d070b (manual-edit preservation guard) + RETRO-007 §template-render overwrites manual edits anti-pattern.

### TC6: AC2 — `.github/workflows/ci.yml` integration

**Setup**: read `.github/workflows/ci.yml` from main HEAD.

**Steps**:
1. Verify job named `smoke-test` (or similar) exists in the workflow
2. Verify the job runs `bash scripts/tests/faz5-smoke.sh`
3. Verify trigger paths include `scripts/tests/faz5-smoke.sh` + `scripts/dev-studio-init.sh` + `CLAUDE.md.tmpl`
4. Verify trigger does NOT include only src/ paths (must cover template-repo changes)

**Expected**: Smoke test job wired into CI on template-repo PRs (paths: template-render-related files).

### TC7: AC3 — Exit code gates merge

**Setup**: synthesize a smoke-test failure (e.g., broken-tmpl from TC2).

**Steps**:
1. Open draft PR with broken-tmpl scenario fixture applied
2. Verify CI run: smoke-test job exits non-zero
3. Verify branch-protection rule: PR cannot be merged while smoke-test fails (read `.github/workflows/ci.yml` + repo settings)

**Expected**: Exit code != 0 → CI red → merge blocked per branch protection. Sister-pattern to existing branch protection rule on `ci.yml`.

## Adversarial Probes (per tester doctrine)

### Input validation
- Empty `--workdir` arg → must error, not silently default to `$PWD`
- Invalid `--scenario` (e.g., `nonexistent`) → must list valid scenarios in error message
- `--dry-run` combined with `--scenario=fresh-clone` (writes-then-no-writes) → must succeed with no net writes

### Auth & Permissions
- Smoke test running as non-owner user → no GitHub API calls needed (sub-scenario 4 uses `--source=local`, no clone)
- CI runs in fork-PR context → smoke test must NOT require repo secrets

### State & Concurrency
- Two parallel CI runs (race condition) → tmp dirs use `mktemp -d` with unique names (no shared state)
- Smoke test runs twice in same CI job (retry) → idempotent (TC3 covers)

### Data
- Empty target dir (already clean) → fresh-clone scenario works
- Target dir with 1000+ existing files (polluted) → must error clearly, not silently overwrite
- Target dir with `CLAUDE.md` already present → manual-edit scenario preserves; broken-tmpl scenario errors

## Performance Concerns

- Smoke test runtime: each sub-scenario must complete in <30s (CI total budget = 5min)
- Sub-scenario 4 (fresh-clone) may touch disk heavily — measure I/O via `time bash ...`
- 5 sub-scenarios running in parallel via `&` + `wait` — must not exceed 30s total wall time

## Regression Risk

- **`scripts/dev-studio-init.sh` breaking change** → smoke test catches via TC3 (idempotency) + TC4 (fresh-clone). Sister-pattern to Issue #653 AC1+AC2 (fresh-clone validation failure on Sprint 21).
- **`CLAUDE.md.tmpl` schema drift** → smoke test catches via TC4 (content sanity check) + TC5 (manual-edit preservation).
- **`.github/workflows/ci.yml` paths filter too narrow** → TC6 catches via trigger paths assertion. Sister-pattern to RETRO-006 workflow-script blind-spot family.

## Sister-patterns

- **d070a/b/c** (template-render regression) — sister d-test family, TC3 (idempotency) directly mirrors d070's contract
- **d093** (TEMPLATE-README polish regression guard) — TC5 (manual-edit) parallels d093's manual-edit contract
- **d137** (init-script idempotency, if exists) — TC3 (idempotency) is sister
- **ADR-0044** (RED-first TDD) — `faz5-smoke.sh` ships RED on main, GREEN post-impl per ADR-0044
- **ADR-0049** (d-test framework, ≥3 sister-pattern baseline) — 5 sub-scenarios = 5 TCs (exceeds baseline)
- **ADR-0012** (4-cat label invariant) — smoke-test PR must carry 4 labels (type:feature + status:* + agent:* + cc:*)
- **Issue #653** (Fresh-Clone Validation) — TC4 directly mirrors AC1+AC2 of #653; smoke-test = unit-level, #653 = e2e-level

## Definition of Done

1. All 5 sub-scenarios (TC1-TC5) covered by `scripts/tests/faz5-smoke.sh` with ≥5 TCs
2. `.github/workflows/ci.yml` wires smoke-test job on template-repo PR paths (TC6)
3. Exit-code-gates-merge discipline verified (TC7)
4. PR merged to main with owner squash per ADR-0031
5. CI green on main post-merge
6. TC7 branch-protection rule documented in README + CHANGELOG.md
7. Sprint 24 acceptance: AC1+AC2+AC3 of Issue #653 (Fresh-Clone Validation) re-validate with smoke test active

## Lane handoff sequence

1. **Pre-implementation** (this doc): tester lane writes test plan + RED-first contract
2. **Implementation**: developer lane writes `scripts/tests/faz5-smoke.sh` per TC1-TC5 contract
3. **CI integration**: developer + architect lane (architect = CI workflow territory) wire smoke-test into `.github/workflows/ci.yml` per TC6+TC7
4. **Sign-off**: tester lane verifies RED→GREEN on PR branch, ARCH verdict, owner squash per ADR-0031