#!/usr/bin/env bash
# d642-scripts-parameterized.sh — Issue #642 / STORY-S21-010 (Scripts Parameterized)
#                              d-test RED-first per ADR-0044
#
# Why this test exists
# --------------------
# Without parameterization, scripts reference AtilCalculator paths in a different
# project (clone-and-use fails). The audit script (S21-004 / Issue #651, sister
# d-test d105) catches hardcoded refs but does NOT verify the substitution
# pattern itself (AC2). This d-test complements d105 by:
#   - Asserting AC1 audit-script coverage AT scripts/ level (TC1 happy + TC2 negative)
#   - Asserting AC2 substitution-shape regression: ≥1 script uses correct
#     parameterization pattern AND 0 active-code hardcoded refs (TC3, TC4)
#   - Asserting AC2 live-call contract: gh repo view resolves to current repo name (TC5)
#   - Asserting AC3 ~/.dev-studio-env generation with required keys (TC6, TC7)
#   - Asserting AC3 cross-clone behavior: env vars reflect throwaway repo, not
#     hardcoded "AtilCalculator" (TC8)
#   - Asserting AC3 chmod 600 amendment per arch 9-Lens (g) HIGH (TC9)
#
# 9 TCs (per ADR-0049 ≥5 baseline, plus 3-TC amendment per ARCH stamp cmt 4898766162):
#   TC1: AC1 audit happy-path — `audit-project-refs.sh scripts/` exits 0
#   TC2: AC1 audit negative-injection — fixture with hardcoded `AtilCalculator` audit exits 1
#   TC3: AC2 substitution-shape — ≥1 script uses `$(gh repo view ...)` OR `${GITHUB_REPO}` pattern
#   TC4: AC2 negative-shape — 0 hardcoded `AtilCalculator`/`atilcan65` in active code
#   TC5: AC2 live-call — `$(gh repo view --json name -q .name)` resolves to current repo
#   TC6: AC3 env-file generation — `${HOME}/.dev-studio-env` exists after init run
#   TC7: AC3 env-vars present — file contains GITHUB_OWNER, GITHUB_REPO, HUMAN_OWNER_NAME (non-empty)
#   TC8: AC3 cross-clone — env vars reflect throwaway repo, not AtilCalculator
#   TC9: AC3 chmod 600 (arch lens g HIGH amendment) — file permissions = `stat -c %a` = 600
#
# Pre-impl RED state (Issue #642 impl not yet landed):
#   - TC1: FAIL — audit finds 230 hardcoded refs in scripts/, exits 1 (impl needed)
#   - TC2: PASS — audit catches hardcoded refs (d105 already covers this aspect)
#   - TC3: FAIL — no scripts use parameterization pattern (impl needed)
#   - TC4: FAIL — 230 hardcoded refs exist (impl needed)
#   - TC5: PASS — gh CLI works regardless of scripts/ state (baseline already works)
#   - TC6: FAIL — init script doesn't generate ~/.dev-studio-env (impl needed)
#   - TC7: FAIL — file doesn't exist (TC6 dependent)
#   - TC8: FAIL — env-file generation not present (impl needed)
#   - TC9: FAIL — chmod 600 not yet wired (impl needed)
#   → Most TCs FAIL = proper RED-first per ADR-0044. Sprint 24+ impl lands GREEN.
#
# Post-impl GREEN state (after Issue #642 impl lands + AC3 chmod 600 amendment):
#   - TC1: PASS — audit exits 0 (no hardcoded refs after parameterization)
#   - TC2: PASS — negative-injection still caught (regression-protected)
#   - TC3: PASS — ≥1 script uses correct substitution pattern
#   - TC4: PASS — 0 hardcoded refs in active code (allow only in fixture/comments)
#   - TC5: PASS — gh CLI resolves correctly
#   - TC6: PASS — ~/.dev-studio-env generated
#   - TC7: PASS — all 3 required keys present + non-empty
#   - TC8: PASS — cross-clone env vars reflect throwaway repo
#   - TC9: PASS — file permissions = 600 (arch lens g closure)
#   → 9/9 GREEN.
#
# Sister-pattern family (d-test lineage, ADR-0049):
#   - d105-audit-project-refs.sh (S21-004 #651, direct parent — audit script itself)
#   - d112-conftest-env-var-precedence.sh (Issue #855 sister — env-var precedence)
#   - d649-story-s21-022-smoke-test.sh (S21-022 — fresh-clone validation sister)
#   - d070a (S21-003a #636, init script sister)
#   - d019-e2e-deploy-verify.sh (env-state fixture sister)
#   - d080 (cross-lane ci.yml step, Sprint 23 plan §Committed stories)
#
# Sprint 24 dispatch refs:
#   - Issue #642 (impl, agent:developer, status:in-progress post-4-of-4 ratification)
#   - PM sizing stamp cmt id 4898738106 (5 pts, lane discipline flag agent:tester→agent:developer)
#   - Dev sizing stamp cmt id 4898757701 (5 pts ACCEPT)
#   - Test stamp cmt id 4898764000 (5 pts CONFIRM + 9-TC scope expansion)
#   - Arch 9-Lens stamp cmt id 4898766162 (5 pts AGREE + 3 HIGH flags for impl PR: d silent-skip, g chmod 600 [amended into AC3], j live-state attestation)
#   - PM 4-of-4 ratification cmt id 4898772542 (status:ready→in-progress flip after ratification)
#   - ADR-0019 (BUDGET_MULTIPLIER doctrinal home, sister-pattern for env-var precedence)
#   - ADR-0044 (RED-first TDD doctrinal home)
#   - ADR-0049 (d-test framework ≥5 baseline, d642 = 9 TCs)
#   - ADR-0055 §1 (Cadence Rule 1 atomic — d-test file + INDEX.md row same commit)
#   - ADR-0012 (4-cat label invariant on d-test PR per type:feature + status:in-review + agent:tester + cc:developer + needs-tester-signoff)
#   - ADR-0045 §9-Lens (lens g = security & privacy = chmod 600 HIGH flag — amended into AC3 by PM ratification)
#
# Usage:
#   bash scripts/tests/d642-scripts-parameterized.sh --self-test
#
# Exit codes:
#   0 — all PASS (GREEN state — Issue #642 impl lands with all ACs verified)
#   1 — at least one FAIL (RED state — impl not yet landed, sister-PR d-test ships first)
#   2 — preflight failure (missing tool, file missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AUDIT_SCRIPT="${REPO_ROOT}/scripts/audit-project-refs.sh"
DEV_STUDIO_INIT="${REPO_ROOT}/scripts/dev-studio-init.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then
  R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[34m'; D=$'\033[0m'
else
  R=""; G=""; Y=""; B=""; D=""
fi

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# Preflight
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required" >&2; exit 2; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git required" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI required (for TC5 live-call)" >&2; exit 2; }
command -v stat >/dev/null 2>&1 || { echo "ERROR: stat required (for TC9 chmod 600)" >&2; exit 2; }

if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: $0 --self-test" >&2
  exit 2
fi

printf "${B}d642 self-test (9 TCs per Issue #642 + ADR-0044 RED-first)${D}\n"
printf "${B}=================================================================${D}\n"
printf "  Sister-plan:       docs/test-plans/STORY-S21-010-tests.md (8 TCs)\n"
printf "  Sister-d-test:     d105 (audit-project-refs.sh)\n"
printf "  RED-first:         pre-impl most TCs FAIL (impl not yet landed)\n"
printf "  Post-impl:         all 9 TCs must PASS\n"
printf "  AC3 chmod 600:     Per arch 9-Lens (g) amendment, ratified by PM 4-of-4\n\n"

# ============================================================================
# TC1: AC1 — `audit-project-refs.sh scripts/` exits 0 (clean state)
# ============================================================================
section "TC1: AC1 — Audit on scripts/ exits 0 (clean state, AC1 happy-path)"

if [ ! -x "$AUDIT_SCRIPT" ]; then
  fail "preflight — scripts/audit-project-refs.sh missing or not executable" "run: chmod +x scripts/audit-project-refs.sh"
else
  bash "$AUDIT_SCRIPT" scripts/ > /tmp/d642-tc1.out 2>&1
  TC1_EXIT=$?
  if [ "$TC1_EXIT" -eq 0 ]; then
    pass "TC1 — audit exits 0 (zero hardcoded refs in scripts/)"
  else
    TC1_HITS=$(grep -oE '[0-9]+ hardcoded' /tmp/d642-tc1.out | head -1 || echo "unknown")
    fail "TC1 — audit must exit 0 after parameterization" "currently exits $TC1_EXIT with $TC1_HITS; expected 0"
  fi
fi

# ============================================================================
# TC2: AC1 — Audit-injection fixture → exit 1 (negative path still works)
# ============================================================================
section "TC2: AC1 — Audit-injection fixture exits 1 (negative path regression)"

TC2_TMP=$(mktemp -d)
trap 'rm -rf "$TC2_TMP"' EXIT
TC2_GIT="$TC2_TMP/repo"
mkdir -p "$TC2_GIT"
(
  cd "$TC2_GIT"
  git init -q
  git config user.email "test@test"
  git config user.name "Test"
  mkdir -p scripts
  echo 'echo "AtilCalculator"' > scripts/fixture-bad.sh
  git add -A
  git commit -q -m "fixture with hardcoded ref"
)
bash "$AUDIT_SCRIPT" "$TC2_GIT" > /dev/null 2>&1
TC2_EXIT=$?

if [ "$TC2_EXIT" -eq 1 ]; then
  pass "TC2 — audit-injection fixture exits 1 (regression-protected: catches hardcoded refs)"
else
  fail "TC2 — audit must exit 1 on fixture with hardcoded ref" "expected exit 1, got exit $TC2_EXIT"
fi

# ============================================================================
# TC3: AC2 — ≥1 script uses parameterization pattern (substitution-shape)
# ============================================================================
section "TC3: AC2 — Substitution-shape regression (≥1 script uses correct pattern)"

# Sister-pattern to d649 anchor test: grep for parameterization pattern
TC3_PATTERN='\$\(gh repo view --json name -q \.name\)|\$\{GITHUB_REPO\}|\$\{GITHUB_OWNER\}|\$\{HUMAN_OWNER_NAME\}'
TC3_HITS=$(grep -rEln "$TC3_PATTERN" scripts/ 2>/dev/null | wc -l)

if [ "$TC3_HITS" -ge 1 ]; then
  pass "TC3 — ≥1 script uses parameterization pattern (found $TC3_HITS)"
else
  fail "TC3 — no script uses correct parameterization pattern" "expected ≥1 script with 'gh repo view' or env-var pattern"
fi

# ============================================================================
# TC4: AC2 — 0 hardcoded AtilCalculator/atilcan65 in active code (negative)
# ============================================================================
section "TC4: AC2 — 0 hardcoded refs in active code paths (allow fixture/comments only)"

# Find matches but exclude: comments, fixture files, audit script itself, README, log paths,
# AND scripts/tests/ (d-test fixtures legitimately contain hardcoded refs as test data —
# see Issue #872 design-drift #5 CRITICAL — without this exclusion TC4 reports 161 false
# positives from scripts/tests/ even with a perfect impl).
#
# Filter order matters: do PATH-based exclusions first (on `path:line:content` form),
# THEN strip prefix, THEN filter comments. Reversing the order breaks path filters
# (audit-project-refs.sh's own internal regex patterns would be counted as hits).
TC4_HITS=$(grep -rEn 'AtilCalculator|atilcan65' scripts/ 2>/dev/null \
  | grep -vE 'audit-project-refs\.sh:|scripts/tests/|kickoff/|agent-state/|var/log/dev-studio/' \
  | sed -E 's/^[^:]+:[0-9]+://' \
  | grep -vE '^\s*#|fixture' \
  | wc -l)

if [ "$TC4_HITS" -eq 0 ]; then
  pass "TC4 — 0 hardcoded refs in active code paths"
else
  fail "TC4 — found $TC4_HITS hardcoded refs in active code" "expected 0 after parameterization"
fi

# ============================================================================
# TC5: AC2 — `$(gh repo view --json name -q .name)` resolves to current repo
# ============================================================================
section "TC5: AC2 — Live-call contract (gh repo view resolves correctly)"

# Sister-pattern: this is the canonical parameterization invocation
TC5_RESOLVED=$(gh repo view --json name -q .name 2>/dev/null || echo "GITHUB_API_ERROR")

if [ "$TC5_RESOLVED" = "AtilCalculator" ] || [ "$TC5_RESOLVED" = "atilcalculator" ]; then
  pass "TC5 — gh repo view resolves to current repo name ($TC5_RESOLVED)"
elif [ "$TC5_RESOLVED" = "GITHUB_API_ERROR" ]; then
  info "TC5 — gh API not available (skip; this TC is environment-dependent)"
else
  fail "TC5 — gh repo view returned unexpected value" "got: $TC5_RESOLVED (expected AtilCalculator in AtilCalculator clone)"
fi

# ============================================================================
# TC6: AC3 — ~/.dev-studio-env generated after dev-studio-init.sh run
# ============================================================================
section "TC6: AC3 — env-file generation (init creates ~/.dev-studio-env)"

# Use a tmp HOME to avoid clobbering real ~/.dev-studio-env
TC6_HOME=$(mktemp -d)
trap 'rm -rf "$TC2_TMP" "$TC6_HOME"' EXIT

# Issue #872 design-drift #2 HIGH: stub gh auth config in tmp HOME so init's preflight
# (which runs `gh auth status`) doesn't hard-fail. Copy real hosts.yml if present,
# else seed with empty YAML so gh CLI accepts the home as authenticatable.
mkdir -p "$TC6_HOME/.config/gh"
if [ -f "$HOME/.config/gh/hosts.yml" ]; then
  cp "$HOME/.config/gh/hosts.yml" "$TC6_HOME/.config/gh/hosts.yml"
else
  printf 'github.com:\n  user: stub\n  oauth_token: stub\n  protocol: https\n' \
    > "$TC6_HOME/.config/gh/hosts.yml"
fi

# Issue #872 cycle ~#5078+1 NEW (7th defect, discovered after PR #875 preflight fix
# landed): init's resolve_values calls `git config user.name` and hard-fails with
# "{{HUMAN_OWNER_NAME}} is empty" when unset. With isolated HOME=$TC6_HOME, no
# git config user.name is available, so init stops before write_dev_studio_env.
# Sister-pattern to gh auth stub above: seed a minimal gitconfig so resolve_values
# can populate HUMAN_OWNER_NAME from local git config, allowing the env-file to be
# written. This is a TEST design gap (not an impl bug — the impl correctly fails
# loud on missing user.name; the test must provide it in its isolated HOME).
# Use HOME=$TC6_HOME for git config --global so the stub lands in $TC6_HOME/.gitconfig
# (init's resolve_values reads from the env's HOME, not the test's HOME).
HOME="$TC6_HOME" git config --global user.name "Test User" 2>/dev/null
HOME="$TC6_HOME" git config --global user.email "test@test.local" 2>/dev/null

if [ ! -x "$DEV_STUDIO_INIT" ]; then
  fail "TC6 — dev-studio-init.sh missing or not executable" "expected $DEV_STUDIO_INIT"
else
  # Run init (no flags supported per dev-studio-init.sh header) with isolated HOME
  HOME="$TC6_HOME" bash "$DEV_STUDIO_INIT" > /tmp/d642-tc6.out 2>&1 || true
  TC6_ENV_FILE="$TC6_HOME/.dev-studio-env"

  if [ -f "$TC6_ENV_FILE" ]; then
    pass "TC6 — ~/.dev-studio-env generated at $TC6_ENV_FILE"
  else
    TC6_OUT=$(head -3 /tmp/d642-tc6.out 2>/dev/null | tr '\n' ' ' || echo "")
    fail "TC6 — ~/.dev-studio-env not generated" "init output: $TC6_OUT"
  fi
fi

# ============================================================================
# TC7: AC3 — ~/.dev-studio-env contains required env vars (non-empty)
# ============================================================================
section "TC7: AC3 — env-vars present (GITHUB_OWNER, GITHUB_REPO, HUMAN_OWNER_NAME non-empty)"

if [ -f "${TC6_HOME:-}/.dev-studio-env" ]; then
  # Issue #872 design-drift #3 MEDIUM: impl writes `export GITHUB_OWNER="..."` (env-file
  # best practice for `. file` sourcing). Match the `export` prefix.
  TC7_OWNER=$(grep -E '^export GITHUB_OWNER=' "${TC6_HOME}/.dev-studio-env" | sed 's/^export GITHUB_OWNER=//' || echo "")
  TC7_REPO=$(grep -E '^export GITHUB_REPO=' "${TC6_HOME}/.dev-studio-env" | sed 's/^export GITHUB_REPO=//' || echo "")
  TC7_HUMAN=$(grep -E '^export HUMAN_OWNER_NAME=' "${TC6_HOME}/.dev-studio-env" | sed 's/^export HUMAN_OWNER_NAME=//' || echo "")

  if [ -n "$TC7_OWNER" ] && [ -n "$TC7_REPO" ] && [ -n "$TC7_HUMAN" ]; then
    pass "TC7 — all 3 required env vars present (OWNER=$TC7_OWNER, REPO=$TC7_REPO, HUMAN=$TC7_HUMAN)"
  else
    fail "TC7 — missing required env vars" "OWNER=[$TC7_OWNER] REPO=[$TC7_REPO] HUMAN=[$TC7_HUMAN]"
  fi
else
  fail "TC7 — ~/.dev-studio-env file missing (TC6 dependent)"
fi

# ============================================================================
# TC8: AC3 — Cross-clone behavior (env vars reflect throwaway repo)
# ============================================================================
section "TC8: AC3 — Cross-clone env vars reflect throwaway repo (not AtilCalculator)"

# Issue #872 design-drift #4 HIGH: original TC8 ran init in this (AtilCalculator) repo
# with isolated HOME, then asserted env vars != AtilCalculator — but they ARE AtilCalculator
# (correctly derived from local origin), so check failed by design.
# Fix: create a throwaway git repo with a different name, run init there, verify env-file
# contains the THROWAWAY repo's name (proves parameterization, not hardcoding).
TC8_REPO=$(mktemp -d)
trap 'rm -rf "$TC2_TMP" "$TC6_HOME" "$TC8_REPO"' EXIT

# Init throwaway repo with a recognizable non-AtilCalculator name
TC8_REPO_NAME="d642-fixture-$RANDOM"
( cd "$TC8_REPO" \
  && git init -q -b main \
  && git config user.email "fixture@test" \
  && git config user.name "fixture" \
  && git remote add origin "https://github.com/test-owner/${TC8_REPO_NAME}.git" \
  && echo "fixture" > README.md \
  && git add README.md \
  && git commit -q -m "fixture init" )

# Stub gh auth in fixture HOME so init preflight passes
TC8_HOME=$(mktemp -d)
mkdir -p "$TC8_HOME/.config/gh"
if [ -f "$HOME/.config/gh/hosts.yml" ]; then
  cp "$HOME/.config/gh/hosts.yml" "$TC8_HOME/.config/gh/hosts.yml"
else
  printf 'github.com:\n  user: stub\n  oauth_token: stub\n  protocol: https\n' \
    > "$TC8_HOME/.config/gh/hosts.yml"
fi

# Copy dev-studio-init.sh into the throwaway repo so init can resolve REPO_ROOT
cp "$DEV_STUDIO_INIT" "$TC8_REPO/dev-studio-init.sh"
chmod +x "$TC8_REPO/dev-studio-init.sh"

# Run init in throwaway repo context
( cd "$TC8_REPO" && HOME="$TC8_HOME" bash ./dev-studio-init.sh > /tmp/d642-tc8.out 2>&1 || true )

TC8_ENV_FILE="$TC8_HOME/.dev-studio-env"
if [ ! -f "$TC8_ENV_FILE" ]; then
  TC8_OUT=$(head -3 /tmp/d642-tc8.out 2>/dev/null | tr '\n' ' ' || echo "")
  fail "TC8 — ~/.dev-studio-env not generated in throwaway repo" "init output: $TC8_OUT"
else
  # Extract values (impl uses `export VAR="..."` form — see TC7 fix #3)
  TC8_OWNER_VAL=$(grep -E '^export GITHUB_OWNER=' "$TC8_ENV_FILE" | sed 's/^export GITHUB_OWNER=//' | tr -d '"' || echo "")
  TC8_REPO_VAL=$(grep -E '^export GITHUB_REPO=' "$TC8_ENV_FILE" | sed 's/^export GITHUB_REPO=//' | tr -d '"' || echo "")

  if [ "$TC8_REPO_VAL" = "$TC8_REPO_NAME" ]; then
    pass "TC8 — env vars reflect throwaway repo (OWNER=$TC8_OWNER_VAL, REPO=$TC8_REPO_VAL matches fixture)"
  else
    fail "TC8 — env vars did not reflect throwaway repo" \
      "expected REPO=$TC8_REPO_NAME, got OWNER=$TC8_OWNER_VAL REPO=$TC8_REPO_VAL"
  fi
fi

# ============================================================================
# TC9: AC3 — chmod 600 amendment per arch 9-Lens (g) HIGH flag
# ============================================================================
section "TC9: AC3 — chmod 600 (arch lens g HIGH amendment, ratified by PM 4-of-4)"

if [ -f "${TC6_HOME:-}/.dev-studio-env" ]; then
  TC9_PERMS=$(stat -c %a "${TC6_HOME}/.dev-studio-env" 2>/dev/null || echo "STAT_ERROR")

  if [ "$TC9_PERMS" = "600" ]; then
    pass "TC9 — ~/.dev-studio-env permissions = 600 (owner read/write only, arch lens g closure)"
  else
    fail "TC9 — file permissions not 600" "expected 600 (owner-only per arch lens g), got: $TC9_PERMS"
  fi
else
  fail "TC9 — ~/.dev-studio-env file missing (TC6 dependent)"
fi

# ============================================================================
# Summary
# ============================================================================
section "Summary"
printf "  ${G}PASS: %d${D}  ${R}FAIL: %d${D}  ${Y}INFO: %d${D}\n\n" "$PASS" "$FAIL" "$INFO"

if [ "$FAIL" -gt 0 ]; then
  printf "${R}✗ RED state — at least one TC failed (Issue #642 impl needed)${D}\n"
  exit 1
fi

printf "${G}✓ GREEN state — all 9 AC1+AC2+AC3(chmod 600) TCs verified (Issue #642 impl lands)${D}\n"
exit 0
