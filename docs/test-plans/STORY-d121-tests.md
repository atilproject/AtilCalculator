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

## Test Cases — actual d121 d-test (5 logical TCs / 7 PASS calls)

> **Scope drift note (cycle ~#3371 finalization)**: The original pre-draft (cycle ~#3351) mapped to ADR-0064 §d-test sister-pattern **6-TC table** (Tier 1 + Tier 2 + Tier 3 = 6 ACs across the 3-tier chain). Final d-test shipped with **5 logical TCs** (7 PASS calls, since TC3 splits into TC3a/TC3b/TC3c) covering **only Tier 3 (script-side `${ATC_SERVICE_USER:-$USER}` fallback in `scripts/deploy-runner.sh`)**. **Reason for scope reduction**: Tier 1 (repo var `vars.ATC_SERVICE_USER`) + Tier 2 (workflow YAML hardcoded default) live in `.github/workflows/deploy.yml` which is **owner-gated territory per file ownership matrix** (sister-pattern to `.github/workflows/` lane — `agent:` owner only). d121 stays in tester lane (scripts/tests/) and covers the **regression-guard half** of the 3-tier chain. Tier 1+2 testing deferred to a separate owner-gated d-test (Issue #765 follow-up, owner responsibility).
>
> **Mapping table** (pre-draft 6-TC table → shipped 5-TC d-test):
>
> | Pre-draft AC | Tier | d121 TC | Coverage |
> |---|---|---|---|
> | TC-1 (Tier 1 repo var overrides) | Tier 1 | — | ❌ NOT TESTED (owner-gated territory; sister Issue #765) |
> | TC-2 (Tier 2 workflow default) | Tier 2 | — | ❌ NOT TESTED (owner-gated territory; sister Issue #765) |
> | TC-3 (Tier 3 script fallback to $USER) | Tier 3 | TC3b | ✓ POSIX unset semantics |
> | TC-4 (Tier 3 env-injection wins) | Tier 3 | TC3a | ✓ POSIX env-injection semantics |
> | TC-5 (Tier 1/2 empty-string handling) | Tier 3 (empty variant) | TC3c | ✓ POSIX `:-` empty-as-unset semantics |
> | TC-6 (end-to-end systemd unit ownership) | Tier 3 | TC4 | ✓ Defensive: empty ATC_SERVICE_USER does NOT cause `sudo -u ""` failure |
> | (sister-pattern coverage) | meta | TC5 | ✓ d109 + d112 + d117 d-tests remain on main (≥3 baseline per ADR-0049) |
> | (canonical literal presence) | Tier 3 | TC1 | ✓ file-grep `${ATC_SERVICE_USER:-$USER}` in deploy-runner.sh |
> | (canonical invocation presence) | Tier 3 | TC2 | ✓ file-grep `sudo -u "${ATC_SERVICE_USER:-$USER}"` in deploy-runner.sh |

### TC1: deploy-runner.sh contains canonical `${ATC_SERVICE_USER:-$USER}` literal

**Setup**: `scripts/deploy-runner.sh` shipped with PR #764's RCA-17 AC4 user fix (Tier 3 impl).

**Steps**:
1. Read `scripts/deploy-runner.sh` from working tree
2. Grep for canonical `${ATC_SERVICE_USER:-$USER}` literal (with optional non-colon form `${ATC_SERVICE_USER-$USER}` per ADR-0064 §Canonical script-side fallback)
3. Assert ≥1 match

**Expected**: d121 PASSES iff PR #764 has merged AND the canonical fallback literal is present (post-#764 GREEN state). Pre-#764 RED state: TC1 FAILs (literal missing on main 8d9540b).

### TC2: deploy-runner.sh contains `sudo -u "${ATC_SERVICE_USER:-$USER}"` invocation

**Setup**: Same as TC1.

**Steps**:
1. Grep for canonical `sudo -u "${ATC_SERVICE_USER:-$USER}"` invocation in deploy-runner.sh
2. Assert ≥1 match

**Expected**: d121 PASSES iff PR #764 has merged AND canonical invocation form is present. Pre-#764 RED state: TC2 FAILs.

### TC3a: POSIX `${VAR:-DEFAULT}` semantics — env-injection wins (`ATC_SERVICE_USER=foo`)

**Setup**: Operator scenario where ATC_SERVICE_USER is set via env injection (e.g., workflow env block, shell export).

**Steps**:
1. Run `ATC_SERVICE_USER=foo bash -c 'printf "%s" "${ATC_SERVICE_USER:-$USER}"'`
2. Assert output equals `'foo'`

**Expected**: POSIX `${VAR:-DEFAULT}` semantics: env-injected value wins, NOT $USER fallback.

### TC3b: POSIX `${VAR:-DEFAULT}` semantics — unset falls back to `$USER`

**Setup**: ATC_SERVICE_USER unset (Tier 1+2 don't fire).

**Steps**:
1. Run `unset ATC_SERVICE_USER; bash -c 'printf "%s" "${ATC_SERVICE_USER:-$USER}"'`
2. Assert output equals `$USER` (current shell user)

**Expected**: Tier 3 safe fail-open to runner identity (`$USER`). If runner user IS the service owner, deploy succeeds; if not, deploy fails CLEAN with `unit not found` (NOT corrupts).

### TC3c: POSIX `${VAR:-DEFAULT}` semantics — empty string falls back to `$USER`

**Setup**: `ATC_SERVICE_USER=""` (operator sets empty string — pathological case, GH Actions evaluates unset vars as empty).

**Steps**:
1. Run `ATC_SERVICE_USER= bash -c 'printf "%s" "${ATC_SERVICE_USER:-$USER}"'`
2. Assert output equals `$USER`

**Expected**: POSIX `:-` (with colon) treats empty as unset → safe fail-open to `$USER`. Note: `${VAR-DEFAULT}` (no colon) does NOT fall back on empty — different semantics. ADR-0064 §Canonical script-side fallback uses `${VAR:-DEFAULT}` (colon form), so empty falls back.

### TC4: Defensive — empty `ATC_SERVICE_USER` does NOT cause `sudo -u ""` failure

**Setup**: Operator scenario where ATC_SERVICE_USER is empty (could be from GH Actions evaluating unset vars as empty, or operator misconfiguration).

**Steps**:
1. Simulate empty ATC_SERVICE_USER
2. Verify `${ATC_SERVICE_USER:-$USER}` falls back to $USER (NOT empty)
3. Defensive cross-check: `sudo -u "$RESOLVED_USER" id` exits 0 (RESOLVED_USER is non-empty)

**Expected**: Defensive against the `sudo -u ""` failure pathology — Tier 3 fallback fires BEFORE sudo invocation, so the resolved user is always non-empty.

### TC5: Sister-pattern coverage — d109 + d112 + d117 d-tests remain on main

**Setup**: Sister-pattern coverage invariant per ADR-0049 (≥3 sister d-tests per family).

**Steps**:
1. Verify `scripts/tests/d109-*.sh`, `scripts/tests/d112-*.sh`, `scripts/tests/d117-*.sh` all exist on main
2. Assert env-var precedence family has ≥3 members

**Expected**: d121 adds 4th member to the env-var precedence family — d109 (BUDGET_MULTIPLIER env block) + d112 (conftest env-var precedence) + d117 (ATILCALC_EVALUATE_PERSIST env-var gate) + d121 (ATC_SERVICE_USER 3-tier resolution).

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
