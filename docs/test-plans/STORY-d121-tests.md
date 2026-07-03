# Test Plan: STORY-d121-d-test — Cross-User Env Var Pattern d-test

> **Source**: Pre-draft by @tester (this doc), drafted cycle ~#3351 in response to PR #773 (ADR-0064) CHANGES REQUESTED verdict (cmt 4871079396) + F-5 follow-up (cmt 4871123330) + F-6 critical finding (cmt 4871138817). The follow-up user story issue (e.g., `STORY-d121-d-test: cross-user env-var pattern d-test (6 TCs)`) is the future home per path-B recommendation in cmt 4871079396.
>
> **Author**: @tester (this pre-draft).
> **Implementer (when story lands)**: @developer (impl side: `scripts/deploy-runner.sh` `ATC_SERVICE_USER:-$USER` env var resolution + `--print-resolved-atc-service-user` test-mode flag) + @tester (d121 d-test itself).
> **TDD discipline**: per ADR-0044 RED-first + ADR-0049 d-test framework (≥3 TCs baseline; d121 = 6 TCs exceeds baseline). **CRITICAL precondition**: PR #764 (RCA-17 AC4 user fix) MUST land on main BEFORE d121 implementation begins — otherwise the canonical 3-tier pattern doesn't exist to test. Per F-6 critical finding (cmt 4871138817), PR #764 is currently OPEN (mergedAt: null), so d121 cannot author until that merges.

## Scope

### In scope

- 3-tier canonical precedence chain for cross-user env vars (ADR-0064 §Decision):
  - **Tier 1**: Workflow YAML `vars.ATC_SERVICE_USER` repo variable (operator-set override)
  - **Tier 2**: Workflow YAML hardcoded default `ATC_SERVICE_USER: ${{ vars.ATC_SERVICE_USER || 'atilcan' }}`
  - **Tier 3**: Script-side shell fallback `${ATC_SERVICE_USER:-$USER}` in `scripts/deploy-runner.sh`
- Reversibility: `<1 day` refactor (delete vars + workflow entry + script fallback = pattern gone)
- Sister-pattern coverage: env-var precedence family ≥4 (d109 + d112 + d117 + d121) per ADR-0049 baseline

### Out of scope

- The workflow YAML change for Tier 1 + Tier 2 (`vars.ATC_SERVICE_USER` repo var + deploy.yml env block): human-only territory per file ownership matrix (`docs/decisions/ADR-0064-cross-user-env-var-pattern.md` §File ownership); owner-gated Issue #765 follow-up
- Multi-tenant generalization (e.g., `ATC_LOG_DIR`, `ATC_CONFIG_OWNER` per Sprint 24+)
- The deploy-runner.sh Tier 3 implementation itself (`${ATC_SERVICE_USER:-$USER}` fallback) — owned by PR #764 (refs #763). PR #764 must MERGE before d121 starts; if PR #764 is still OPEN at d121 start, file a sister-blocker issue
- Generalization to other scripts (e.g., `scripts/run-server.sh`, `scripts/install.sh`)

## Test Cases (mapping to ADR-0064 §d-test sister-pattern 6-TC table)

### TC-1: Tier 1 — repo var set, overrides workflow default

**Setup**: `vars.ATC_SERVICE_USER=runner-vm-user` set on repo (per env-specific override scenario, e.g., runner VM where runner user IS the service owner).

**Steps**:
1. Set `vars.ATC_SERVICE_USER=runner-vm-user` on repo
2. Workflow YAML env block evaluates `ATC_SERVICE_USER: ${{ vars.ATC_SERVICE_USER || 'atilcan' }}` → resolves to `'runner-vm-user'`
3. `scripts/deploy-runner.sh --dry-run --print-resolved-atc-service-user` (or via wrapper env-injection) reads `$ATC_SERVICE_USER=runner-vm-user`
4. Script logs `ATC_SERVICE_USER resolved to: runner-vm-user`

**Expected**: d121 asserts the resolved value equals `runner-vm-user` (Tier 1 take precedence over Tier 2 'atilcan' default).

### TC-2: Tier 2 — repo var unset, workflow YAML default fires

**Setup**: `vars.ATC_SERVICE_USER` UNSET (operator has not configured per-env override).

**Steps**:
1. Empty repo var → GH Actions evaluates `${{ vars.ATC_SERVICE_USER }}` to empty string (NOT null)
2. Workflow YAML env block evaluates `ATC_SERVICE_USER: ${{ vars.ATC_SERVICE_USER || 'atilcan' }}` → `'' || 'atilcan'` resolves to `'atilcan'`
3. Script reads `$ATC_SERVICE_USER=atilcan` from env
4. Script logs `ATC_SERVICE_USER resolved to: atilcan`

**Expected**: d121 asserts the resolved value equals `atilcan` (Tier 2 fires on empty-string override, NOT just on null — this is the GH Actions `||` empty-handling idiom).

### TC-3: Tier 3 — repo var unset + workflow YAML missing + script fallback to `$USER`

**Setup**: Both `vars.ATC_SERVICE_USER` unset AND `.github/workflows/deploy.yml` `env:` block missing (or hasn't been added yet — pre-Issue #765 follow-up state).

**Steps**:
1. `vars.ATC_SERVICE_USER` unset (same as TC-2)
2. Workflow YAML env block absent (pre-#765 state)
3. Script reads `$ATC_SERVICE_USER` from env — env unset
4. `${ATC_SERVICE_USER:-$USER}` shell fallback resolves to `$USER` (e.g., `gh-actions-runner` on prod runner VM)
5. Script logs `ATC_SERVICE_USER resolved to: gh-actions-runner`

**Expected**: d121 asserts the resolved value equals `$USER` (Tier 3 fails open to runner identity; script will report `unit not found` if service is not owned by runner user — fails CLEAN, NOT corrupts).

### TC-4: Tier 3 — env var direct override (script-side injection)

**Setup**: `ATC_SERVICE_USER=runner-test` directly set in deploy job env (operator-side override via `os.environ` or `env:` block without repo var).

**Steps**:
1. `vars.ATC_SERVICE_USER` unset (Tier 1 does not fire)
2. Workflow YAML env block absent OR does not declare ATC_SERVICE_USER (Tier 2 does not fire)
3. Script shell receives `ATC_SERVICE_USER=runner-test` via env injection
4. `${ATC_SERVICE_USER:-$USER}` resolves to `'runner-test'` (env injection beats `$USER` fallback)
5. Script logs `ATC_SERVICE_USER resolved to: runner-test`

**Expected**: d121 asserts the resolved value equals `runner-test` (env injection at script layer beats `$USER` fallback).

### TC-5: Tier 1/2 edge — empty-string handling (GH Actions evaluates unset var as empty)

**Setup**: `vars.ATC_SERVICE_USER=""` (operator explicitly sets empty string — pathological case).

**Steps**:
1. Empty repo var → GH Actions evaluates `${{ vars.ATC_SERVICE_USER }}` to `''`
2. Workflow YAML env block evaluates `ATC_SERVICE_USER: ${{ vars.ATC_SERVICE_USER || 'atilcan' }}` → `'' || 'atilcan'` resolves to `'atilcan'` (GH Actions `||` empty-handling)
3. Script reads `$ATC_SERVICE_USER=atilcan` from env
4. Script logs `ATC_SERVICE_USER resolved to: atilcan`

**Expected**: d121 asserts empty-string repo var evaluates to `atilcan`, NOT empty (GH Actions `||` idiom correctly treats empty as falsy and falls back to default).

### TC-6: End-to-end — cross-check systemd unit ownership matches `ATC_SERVICE_USER`

**Setup**: Prod-like environment where `atilcan` owns `atilcalc-web.service` systemd unit (per ADR-0010).

**Steps**:
1. `vars.ATC_SERVICE_USER` unset, workflow YAML env declares `ATC_SERVICE_USER: ${{ vars.ATC_SERVICE_USER || 'atilcan' }}`
2. Script resolves `ATC_SERVICE_USER=atilcan`
3. Script executes `sudo -u atilcan systemctl --user status atilcalc-web.service`
4. Cross-check: the unit is actually owned by `atilcan` (per ADR-0010)

**Expected**: d121 asserts `sudo -u $ATC_SERVICE_USER systemctl --user status atilcalc-web.service` exits 0 (unit is owned by the resolved user). This is the end-to-end cross-check that the 3-tier resolution chose the RIGHT user (not just any user).

## Adversarial Probes

### Input validation (Tier 3 edge cases)

- `ATC_SERVICE_USER=""` (empty) → `${ATC_SERVICE_USER:-$USER}` evaluates to `'' ` (POSIX `${VAR:-DEFAULT}` does NOT fall back on empty string — empty string is a valid value!). The `:`-less form `${VAR-$USER}` DOES fall back, but `$VAR:-` is intentional here. **Disagreement**: ADR §Canonical script-side fallback uses `${ATC_SERVICE_USER:-$USER}` which keeps empty as-is, NOT falling back. d121 needs TCX for: empty-string preservation vs fallback-to-$USER.
  - Resolution: `${VAR:-DEFAULT}` treats empty as the default (POSIX behavior). To fall back on empty, use `${VAR-DEFAULT}` (no colon). The ADR uses `${VAR:-DEFAULT}` per the bash idiom — verify this is intentional or if it should be `${VAR-DEFAULT}`. **d121 should test whichever the ADR commits to.**

- `ATC_SERVICE_USER=root` → script will try `sudo -u root systemctl --user status ...` — different semantics. d121 may add TC for: special user handling.

- `ATC_SERVICE_USER=../../etc/passwd` (path traversal) → `sudo -u ../../etc/passwd` will fail-loud (ps lookup fails, exit non-zero). Defense in depth: d121 verifies the resolved value passes `id -u` check.

- `ATC_SERVICE_USER=$(malicious command)` → shell expansion happens at assignment time, NOT at use time. d121 verifies the value is treated as a literal string by `sudo -u`, not as a shell expression.

### Auth & permissions

- Logged-out run context (no D-Bus session) → `systemctl --user status ...` returns `Failed to connect to bus` → d121 exit code matches documented failure mode.

- Wrong role (deploy runner user != orchestrator user) — N/A; deploy is runner-only.

- Expired token / no token — N/A; deploy uses self-hosted runner credentials, no GitHub token.

### State & concurrency

- 2 concurrent deploys (parallel DEPLOY-001 runs) — distinct `vars.ATC_SERVICE_USER` and distinct script invocations. d121 verifies no shared state between invocations (env vars are per-process).

- Repo var changed mid-deploy (operator edits Settings during a long-running deploy) — d121 verifies the deploy captures the value AT START (idempotent env capture), not at end.

### Data

- Very long `ATC_SERVICE_USER` value (1000+ chars) — d121 verifies graceful failure (id lookup fails, exit non-zero), no buffer overflow.

- Unicode in username (Turkish `ğ`, emoji, NULL byte) — d121 verifies `id -u` failure path is graceful.

## Performance Concerns

- **d121 self-test runtime**: bash + (6 TCs × subprocess invoke) + variable resolution — should complete <5s. d121 should self-time and fail-loud if >30s (sister-pattern d070 TC6 AC3 runtime envelope).

- **No new infrastructure**: d121 invokes deploy-runner.sh in dry-run mode; does NOT spin up a real uvicorn server, does NOT require systemd, does NOT require `$ATC_SERVICE_USER=atilcan` to be valid. Mockable.

- **Cache invalidation**: d121 re-tests every poll — env vars are per-invocation, no caching concern.

## Regression Risk

This d-test is in the env-var precedence family. Sister regression risk:
- **d109** (BUDGET_MULTIPLIER env block, RED-first) — d121's empty-string handling (TC5) is sister to d112 TC6 (fail-loud on garbage). Misalignment on empty vs garbage policy would be a regression.
- **d112** (conftest env-var precedence, 7 TCs) — sister-pattern of d121. Reuses `env` injection pattern from d112 TC1/TC7. Same resolution framework.
- **d117** (ATILCALC_EVALUATE_PERSIST env-var gate) — sister-pattern to d121 (truthy/falsy Boolean family vs cross-user identity family). Distinct semantics, but same env-var-driven test discipline.
- **PR #722 / d107** (install-git-hooks.sh) — orthogonal; no shared surface.
- **PR #750 / d116** (TD-038 scripts lane drift) — d121 file should land without `atilcan65` URL refs (Category A MIGRATE scope per d116 TC1); dev lane + reviewer must verify.

## d-test file skeleton (for impl reviewer)

```bash
#!/usr/bin/env bash
# d121-cross-user-env-var-pattern.sh — cross-user env-var precedence
# regression guard for scripts/deploy-runner.sh:497
# Sister-pattern: d109 (ci.yml BUDGET_MULTIPLIER) + d112 (conftest env-var
# precedence 7 TCs) + d117 (ATILCALC_EVALUATE_PERSIST env-var gate).
#
# Sister-pattern lineage for ATC_SERVICE_USER resolution (3-tier):
#   Tier 1: vars.ATC_SERVICE_USER (repo variable, operator-set)
#   Tier 2: workflow YAML hardcoded default 'atilcan'
#   Tier 3: script-side ${ATC_SERVICE_USER:-$USER} fallback
#
# 6 TCs (≥3 baseline per ADR-0049; 6 exceeds baseline):
#   TC1: Tier 1 — vars.ATC_SERVICE_USER=runner-vm-user → resolves to runner-vm-user
#   TC2: Tier 2 — vars.ATC_SERVICE_USER unset → resolves to 'atilcan' (workflow default)
#   TC3: Tier 3 — vars.X unset + workflow missing + $USER fallback (e.g., gh-actions-runner)
#   TC4: Tier 3 env-injection — ATC_SERVICE_USER=runner-test → resolves to runner-test
#   TC5: empty-string handling — vars.ATC_SERVICE_USER="" → resolves to 'atilcan' (empty→default)
#   TC6: end-to-end — sudo -u $ATC_SERVICE_USER systemctl --user status exits 0
#
# Pre-impl RED state: file missing (TC1-TC6 all FAIL by preflight).
# Post-impl GREEN state: 6/6 PASS.
#
# Usage:
#   bash d121-cross-user-env-var-pattern.sh --self-test
#
# Exit codes:
#   0 — all 6 PASS (GREEN state — Tier 3 fallback landed in deploy-runner.sh:497)
#   1 — at least one FAIL (RED state — 3-tier resolution broken)
#   2 — preflight failure (deploy-runner.sh missing, ATC_SERVICE_USER pattern
#       absent from deploy-runner.sh:497, python3/bash missing, etc.)
```

(Sister-pattern to d112 — same `--self-test` flag + TTY-aware color + `section`/`pass`/`fail`/`info` helpers.)

## Cadence Rule 1 atomic (ADR-0055 §1)

Per ADR-0055 §1: d121 d-test file + `scripts/tests/INDEX.md` entry + Cadence Rule 1 row land in same commit. INDEX entry should reference the **corrected** sister-pattern family (d109 + d112 + d117 + d121), NOT the ADR-0064 misattribution (d113 instead of d117 per F-5).

## Pre-condition: PR #764 must merge first

**CRITICAL** per F-6 critical finding (cmt 4871138817): PR #764 is currently OPEN (`mergedAt: null`, headRefName: `RCA-17-deploy-runner-ac4-user-fix`). The Tier 3 canonical pattern (`${ATC_SERVICE_USER:-$USER}`) does NOT exist on `origin/main` (`git show origin/main:scripts/deploy-runner.sh | grep -c ATC_SERVICE_USER` → 0). **d121 cannot meaningfully run its TCs until PR #764 merges.**

When filing the d121 follow-up issue (per path B from cmt 4871079396), the issue body MUST reference F-6 and state the precondition: "blocked on PR #764 merge — d121 TCs depend on Tier 3 pattern being on main."

🤖 Generated with [Claude Code](https://claude.com/claude-code) — @tester, pre-draft cycle ~#3351, 2026-07-02T23:00Z
