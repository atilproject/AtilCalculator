# Test Plan: STORY-S21-010 — Scripts Parameterized (no AtilCalculator/atilcan65 refs)

> **Status**: TDD-RED draft (tester lane, ADR-0044 RED-first)
> **Story**: [#642](https://github.com/atilproject/AtilCalculator/issues/642) — agent:tester, status:backlog (Sprint 21 Wave 4)
> **Author**: @tester, 2026-07-04T04:30Z
> **Lane**: tester (audit-script coverage) + architect (9-Lens per ADR-0045) + developer (impl) + @product-manager (PM)
> **Sister-pattern**: STORY-S21-004 (audit-project-refs.sh, Issue #651), d-test d080 (cross-lane ci.yml step, per Sprint 23 plan §Committed stories)
> **D-test target**: `audit-project-refs.sh scripts/` (audit-script coverage per Issue #642 AC1)

## Scope

### In scope

- `scripts/audit-project-refs.sh` audit script (S21-004 sister) covering hardcoded `AtilCalculator` + `atilcan65` refs in `scripts/`
- Per-script parameterization: `$(gh repo view --json name -q .name)` or env vars (`${GITHUB_REPO}`, `${GITHUB_OWNER}`, `${HUMAN_OWNER_NAME}`)
- `scripts/dev-studio-init.sh` generates `~/.dev-studio-env` template per-project with required env vars
- Cross-clone validation: scripts run cleanly on a non-AtilCalculator clone (e.g., throwaway test repo)

### Out of scope

- Refactoring every script (only scripts with hardcoded refs touched per Issue #642 §Out of scope)
- Renaming `AtilCalculator` repo (Sprint 22+ per Issue #708 Sprint 22 PIVOT migration)
- Adopting a different package manager (uv vs pip debate — Sprint 22+)
- CLI entry-point changes (e.g., `atilcalc` binary rename — out of scope for Sprint 21)

## Acceptance Criteria mapping

| AC | Description | Test cases |
|---|---|---|
| **AC1** | `audit-project-refs.sh scripts/` returns exit 0 (0 hardcoded refs) | TC1, TC2 |
| **AC2** | Scripts use `$(gh repo view --json name -q .name)` or env vars (`${GITHUB_REPO}`) instead of hardcoded names | TC3, TC4, TC5 |
| **AC3** | `~/.dev-studio-env` template generated per-project with `GITHUB_OWNER`, `GITHUB_REPO`, `HUMAN_OWNER_NAME` | TC6, TC7, TC8 |

## Test Cases

### TC1: AC1 audit-script baseline — zero hardcoded refs in `scripts/`

**Setup**: clean checkout of main HEAD.

**Steps**:
1. Run `bash scripts/audit-project-refs.sh scripts/`
2. Capture exit code `$?`
3. Assert exit code = 0

**Expected**: Exit 0 means audit found 0 hardcoded `AtilCalculator` or `atilcan65` refs in `scripts/` (per AC1). Sister-pattern to Issue #651 d-test d080.

### TC2: AC1 audit-script negative — detects hardcoded refs

**Setup**: tmp dir `${PARAM_TMP}/audit-negative`; copy `scripts/audit-project-refs.sh` into it; create `scripts/dummy.sh` containing hardcoded `AtilCalculator`.

**Steps**:
1. `echo 'echo "AtilCalculator"' > ${PARAM_TMP}/audit-negative/scripts/dummy.sh`
2. Run `bash ${PARAM_TMP}/audit-negative/scripts/audit-project-refs.sh ${PARAM_TMP}/audit-negative/scripts/`
3. Capture exit code `$?` and stdout
4. Assert exit code != 0
5. Assert stdout contains `dummy.sh`

**Expected**: Audit script detects hardcoded ref, exits non-zero, identifies the file. Sister-pattern to RETRO-007 §hardcoded-refs drift family.

### TC3: AC2 — scripts use `$(gh repo view --json name -q .name)` or `${GITHUB_REPO}` env var

**Setup**: scan `scripts/*.sh` for parameterization pattern.

**Steps**:
1. Run `grep -lE '\$\(gh repo view --json name -q \.name\)|\$\{GITHUB_REPO\}|\$\{GITHUB_OWNER\}|\$\{HUMAN_OWNER_NAME\}' scripts/*.sh`
2. Assert ≥1 match (at least one script uses the parameterization pattern)
3. Read the matching script and verify it RESOLVES via the pattern (not just mentions it in a comment)

**Expected**: ≥1 script uses parameterization pattern. Sister-pattern to ADR-0064 cross-user env-var pattern (env-var resolution chain).

### TC4: AC2 negative — scripts do NOT use hardcoded `atilcan65` as default

**Setup**: scan `scripts/*.sh` for anti-pattern.

**Steps**:
1. Run `grep -nE 'atilcan65' scripts/*.sh`
2. Assert 0 matches (no script defaults to `atilcan65` as owner)
3. Run `grep -nE 'AtilCalculator' scripts/*.sh`
4. Assert 0 matches in active code paths (allow match only in fixture files or comments)

**Expected**: 0 hardcoded `atilcan65` or `AtilCalculator` refs in active code. Sister-pattern to TC2 audit-script negative test.

### TC5: AC2 — `gh repo view --json name -q .name` resolves correctly

**Setup**: in AtilCalculator clone (or any clone).

**Steps**:
1. Run `$(gh repo view --json name -q .name)`
2. Capture stdout
3. Assert stdout = `AtilCalculator` (the current repo name)

**Expected**: gh CLI resolves to current repo name. Sister-pattern: same pattern in throwaway test repo should resolve to that repo's name (not AtilCalculator).

### TC6: AC3 — `~/.dev-studio-env` template generated per-project

**Setup**: clean tmp HOME `${HOME_TMP}`; init script available.

**Steps**:
1. Run `HOME=${HOME_TMP} bash scripts/dev-studio-init.sh --non-interactive`
2. Check: `${HOME_TMP}/.dev-studio-env` exists
3. Assert file is generated (not a no-op)

**Expected**: Init generates `.dev-studio-env` per-project. Sister-pattern to ADR-0064 (cross-user env-var precedence).

### TC7: AC3 — `.dev-studio-env` contains required env vars

**Setup**: TC6 generated `${HOME_TMP}/.dev-studio-env`.

**Steps**:
1. Read `${HOME_TMP}/.dev-studio-env`
2. Assert contains `GITHUB_OWNER=` (with non-empty value)
3. Assert contains `GITHUB_REPO=`
4. Assert contains `HUMAN_OWNER_NAME=`
5. Optional: assert contains `export` keyword (POSIX shell source-able)

**Expected**: All 3 required vars present + non-empty. Sister-pattern to ADR-0064 env-var precedence Tier 1 (repo var) + Tier 2 (workflow YAML default).

### TC8: AC3 negative — env var values match the current project (not hardcoded)

**Setup**: throwaway test repo `${THROWAWAY_REPO}` (e.g., `atilcan65/dev-studio-template-smoke` per Issue #653 AC2).

**Steps**:
1. Clone `${THROWAWAY_REPO}` to `${THROWAWAY_TMP}`
2. Run `cd ${THROWAWAY_TMP} && HOME=${HOME_TMP} bash scripts/dev-studio-init.sh --non-interactive`
3. Read `${HOME_TMP}/.dev-studio-env`
4. Assert `GITHUB_OWNER=atilcan65` (or appropriate owner, NOT `atilproject`)
5. Assert `GITHUB_REPO=dev-studio-template-smoke` (NOT `AtilCalculator`)
6. Assert `HUMAN_OWNER_NAME=` matches the project's owner

**Expected**: Env vars reflect the throwaway repo, not AtilCalculator. Cross-clone validation per Issue #653 AC1+AC2.

## Adversarial Probes (per tester doctrine)

### Input validation
- Init run with no args → must error with usage, not silently generate broken env
- Init run in non-git dir → must error (gh repo view requires git context)
- Init run with `--non-interactive` but missing required env (e.g., `$USER` empty) → must error with explicit message

### Auth & Permissions
- Init run as non-owner user → env vars populated from gh CLI as that user (no leak of owner's PAT)
- Init run in fork-PR context → must NOT require write access (env-var gen is read-only)

### State & Concurrency
- Two parallel init runs in different HOME dirs → no shared state, no race
- Init run after manual deletion of `.dev-studio-env` → must regenerate cleanly

### Data
- Throwaway repo with unicode name (e.g., `AtilCalculator-α`) → env vars handle unicode correctly
- Throwaway repo with hyphenated name (e.g., `dev-studio-template-smoke`) → env vars preserve hyphens
- Throwaway repo name very long (≥50 chars) → env var file line breaks handled (no truncation)

## Performance Concerns

- `gh repo view --json name -q .name` invocation cost: ~200ms (API call). Acceptable for one-time init.
- `audit-project-refs.sh scripts/` runtime: must complete in <5s for `scripts/` directory (44+ scripts per Issue #640 S21-009)
- Idempotency check (TC1 rerun): same exit code, same output (no drift)

## Regression Risk

- **`scripts/dev-studio-init.sh` regression** → TC6+TC7+TC8 catch via env-var generation + cross-clone validation
- **`audit-project-refs.sh` false negative** → TC2 catches by introducing a hardcoded ref fixture
- **`gh` CLI breaking change** → TC5 catches by direct invocation; sister-pattern to RETRO-005 #22 (gh CLI API drift)
- **Hardcoded refs re-introduced** → TC4 catches via static grep; sister-pattern to RETRO-007 §hardcoded-refs drift
- **`.dev-studio-env` schema drift** → TC7 catches via required-env-var presence; sister-pattern to d109/d112/d117/d121 env-var precedence family

## Sister-patterns

- **STORY-S21-004** (audit-project-refs.sh, Issue #651) — direct sister, TC1+TC2 directly use this script
- **d-test d080** (cross-lane ci.yml step per Sprint 23 plan) — sister-pattern, audit-script runs in CI
- **ADR-0064** (cross-user env-var pattern) — TC6+TC7+TC8 mirror env-var precedence Tier 1+2+3
- **ADR-0012** (4-cat label invariant) — impl PR must carry 4 labels (type:refactor + status:* + agent:* + cc:*)
- **d070a/b/c** (template-render regression) — sister-pattern, env-var gen intersects template-render
- **Issue #653** (Fresh-Clone Validation) — TC8 directly mirrors AC2 of #653 (throwaway repo clone)
- **RETRO-007** §hardcoded-refs drift — TC4 addresses this drift category

## Definition of Done

1. `scripts/audit-project-refs.sh scripts/` exits 0 on main HEAD (TC1)
2. `scripts/audit-project-refs.sh scripts/` exits non-zero when given a fixture with hardcoded refs (TC2)
3. ≥1 script uses parameterization pattern `$(gh repo view ...)` or `${GITHUB_REPO}` env var (TC3)
4. 0 hardcoded `atilcan65` or `AtilCalculator` refs in active code paths (TC4)
5. `gh repo view --json name -q .name` resolves correctly (TC5)
6. `~/.dev-studio-env` template generated per-project with `GITHUB_OWNER`, `GITHUB_REPO`, `HUMAN_OWNER_NAME` (TC6+TC7)
7. Throwaway repo clone test: env vars reflect throwaway, not AtilCalculator (TC8)
8. PR merged to main with owner squash per ADR-0031
9. CI green on main post-merge
10. Cross-clone validation (Issue #653 AC2) re-validated with parameterized scripts

## Lane handoff sequence

1. **Pre-implementation** (this doc): tester lane writes test plan + audit-script coverage contract
2. **Implementation**: developer lane parameterizes scripts per AC2 + generates `.dev-studio-env` per AC3
3. **Audit-script hardening**: developer + architect (9-Lens per ADR-0045) harden `audit-project-refs.sh` per TC1+TC2
4. **Cross-clone validation**: PM lane runs Issue #653 AC1+AC2 with parameterized scripts
5. **Sign-off**: tester lane verifies all 8 TCs, ARCH verdict, owner squash per ADR-0031