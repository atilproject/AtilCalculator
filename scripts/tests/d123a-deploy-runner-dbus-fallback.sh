#!/usr/bin/env bash
# d123a-deploy-runner-dbus-fallback.sh — Issue #820 INCIDENT-3 P0
#   deploy-runner.sh D-Bus user-bus unavailable → nohup+setsid fallback
#   per ADR-0010 supplement scope (architect disposition cmt 4881824175).
#
# Why this test exists
# --------------------
# Issue #820 (P0 incident, deploy+smoke deterministic FAIL on runner-vm-5
# since 2026-07-04T11:10:36Z). Root cause: `systemctl --user start` fails
# with "Failed to connect to bus: No medium found" because runner-vm-5
# lacks the D-Bus user-session preconditions (dbus-user-session pkg +
# loginctl enable-linger + XDG_RUNTIME_DIR). uvicorn itself runs fine,
# but the deploy script's hard-fail at the `systemctl --user stop/start`
# blocks production deploy.
#
# Per architect disposition §Dev b1 hotfix scope (cmt 4881824175), the
# fix refactors deploy-runner.sh lines 380-388 (preflight) +
# 476-477 (stop) + 497-498 (start) into 3 branches:
#   - Branch A canonical: `systemctl --user` succeeds + unit registered
#     → preserved (current path), exit 0 on GREEN.
#   - Branch B D-Bus fallback: `systemctl --user` fails with class
#     "Failed to connect to bus" / "No medium found" / "Connection refused"
#     → emit `<!-- adr-0010-supplement-silent-skip -->` audit marker per
#       ADR-0045 lens d + fall back to nohup+setsid canonical pattern
#       (operational reality per ADR-0027 §136 retro-ratification) + exit 0.
#   - Branch C unit-missing hard fail: D-Bus OK + unit not registered
#     → exit 7 (RCA-14 invariant preserved unchanged).
#
# Why "supplement" not "new ADR" (per architect rationale cmt 4881824175):
#   - ADR-0010 is the canonical home for `systemctl --user` as canonical
#     per-project watcher + service mechanism. D-Bus / XDG_RUNTIME_DIR /
#     linger preconditions belong in ADR-0010 supplement, not new ADR.
#   - ADR-0027 §136 EXPLICITLY flagged ADR-0010 supplement as Sprint 4
#     backlog — Issue #820 P0 surfaces it as unblock trigger.
#   - A new ADR would create amend complexity for existing ADR-0010
#     §Acceptance test references.
#
# Sister-pattern (≥3 per ADR-0049):
#   - d017 (RCA-12 cross-user port-8000, Issue #168) — sister, port-PID
#     etime check NOT removed by this refactor (defense-in-depth backstop).
#   - d122 (RCA-20 run-server.sh uv extra web, Issue #771) — sister,
#     shell-script-side defense.
#   - d123 (RCA-19 uvicorn cold-start, Issue #785) — sister, paired
#     `wait_for_uvicorn_ready` helper not removed by this refactor.
#   - d123a (NEW — this PR) = D-Bus user-bus fallback path.
#   ≥3 baseline met (d017 + d122 + d123 + d123a = 4 sisters).
#
# Pre-impl RED state (current origin/main c2fad70, deploy-runner.sh v9.2):
#   - TC2 FAIL — Branch B D-Bus error pattern detection literal NOT in
#     deploy-runner.sh (script currently fails hard at `systemctl --user`
#     stop/start calls without distinguishing D-Bus vs unit-missing class).
#   - TC3 PASS-by-coincidence — RCA-14 unit-missing exit 7 path already
#     present (line 386 preflight + line 558 AC4 active-state check).
#   - TC4 PASS-by-coincidence — Branch A canonical `systemctl --user
#     start atilcalc-web.service` already present.
#   - TC5 FAIL — `<!-- adr-0010-supplement-silent-skip -->` audit marker
#     literal NOT in script (silent path observation absent).
#   - TC6 PASS-by-coincidence — defense-in-depth (wait_for_uvicorn_ready +
#     RCA-12 ss/etime cross-user check) intact in v9.2.
#   → expected pre-impl: 2/7 FAIL (TC2 + TC5 RED); TC3+TC4+TC6+TC7
#   PASS-by-coincidence (or FAIL if refactor incidentally breaks).
#
# Post-impl GREEN state (after this PR merges):
#   - TC2 PASS — Branch B D-Bus error pattern detection + nohup+setsid
#     fallback command present.
#   - TC3 PASS — RCA-14 unit-missing exit 7 path preserved.
#   - TC4 PASS — Branch A canonical `systemctl --user` start preserved.
#   - TC5 PASS — silent_skip audit marker literal present (Branch B path).
#   - TC6 PASS — defense-in-depth (d123 + d017) intact (refactor must NOT
#     regress wait_for_uvicorn_ready or RCA-12 ss/etime check).
#   → 7/7 PASS in GREEN state per ADR-0044 GREEN contract.
#
# Sister slot: d123a = next free slot post-d123. Slot allocation
# pattern (Issue #113 + ADR-0055 §1): d-tests numbered in roughly
# PR-discovery order. Sister-pattern family: d017 (RCA-12), d122
# (RCA-20), d123 (RCA-19 cold-start), d123a (RCA-21 D-Bus supplement).
#
# Run standalone:  bash scripts/tests/d123a-deploy-runner-dbus-fallback.sh --self-test
#
# Exit codes:
#   0 — all 7 PASS (GREEN state — 3-branch refactor landed, defense-in-depth
#       preserved, silent_skip marker present)
#   1 — at least one FAIL (RED state — refactor incomplete)
#   2 — preflight failure (deploy-runner.sh missing, bash ≥4 missing, etc.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEPLOY_RUNNER="${REPO_ROOT}/scripts/deploy-runner.sh"

# Colors (TTY-aware)
if [[ -t 1 ]]; then G=$'\033[0;32m'; R=$'\033[0;31m'; B=$'\033[1m'; Y=$'\033[0;33m'; D=$'\033[0m'
else G=""; R=""; B=""; Y=""; D=""; fi

PASS=0; FAIL=0; INFO=0
pass() { printf "  ${G}✓ PASS${D} — %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${R}✗ FAIL${D} — %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${R}%s\n" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${Y}ℹ INFO${D} — %s\n" "$1"; INFO=$((INFO+1)); }
section() { printf "\n${B}==== %s ====${D}\n" "$1"; }

# ============================================================================
# Pre-flight (ADR-0049)
# ============================================================================
command -v bash >/dev/null 2>&1 || { echo "ERROR: bash required" >&2; exit 2; }
case "$BASH_VERSION" in
  4.*|5.*) : ;;
  *) echo "ERROR: bash ≥4 required (got bash $BASH_VERSION)" >&2; exit 2 ;;
esac
[ -f "$DEPLOY_RUNNER" ] || { echo "ERROR: deploy-runner.sh not found at $DEPLOY_RUNNER" >&2; exit 2; }

if [ "${1:-}" != "--self-test" ]; then
  echo "Usage: $0 --self-test" >&2
  exit 2
fi

printf "${B}d123a self-test (Issue #820 INCIDENT-3 — RCA-21 D-Bus user-bus fallback, 7 TCs ≥3 sister baseline per ADR-0049)${D}\n"
printf "${B}================================================================${D}\n"
printf "  Deploy-runner: %s\n" "$DEPLOY_RUNNER"
printf "  Sister slot:   d017 (RCA-12 cross-user port-8000, Issue #168) + d122 (RCA-20 run-server.sh, Issue #771) + d123 (RCA-19 cold-start, Issue #785) + d123a (RCA-21 D-Bus supplement, Issue #820)\n"
printf "  Fix design:    3-branch refactor — Branch A canonical (preserved) / Branch B D-Bus→nohup+setsid fallback (with adr-0010-supplement-silent-skip audit marker) / Branch C unit-missing RCA-14 hard-fail exit 7 (preserved)\n"
printf "  Doctrinal:     ADR-0010 supplement (NOT new ADR) per architect disposition cmt 4881824175. ADR-0027 §136 retro-ratification — nohup+setsid is operational reality.\n"
printf "  RED-first:     pre-impl TC2 + TC5 FAIL (3-branch refactor not yet landed); TC3+TC4+TC6 PASS-by-coincidence.\n\n"

# ============================================================================
# TC1 (preflight): deploy-runner.sh exists + readable + non-empty
# ============================================================================
section "TC1: preflight — deploy-runner.sh exists + readable + non-empty"
if [ -r "$DEPLOY_RUNNER" ] && [ -s "$DEPLOY_RUNNER" ]; then
  pass "TC1 — deploy-runner.sh exists + readable + non-empty"
else
  fail "TC1 — preflight FAILED" "expected $DEPLOY_RUNNER readable + non-empty"
  printf "\n  Cannot continue without source file. 1/7 FAIL — preflight only.\n"
  exit 1
fi

# ============================================================================
# TC2 (AC1 / arch TC1): Branch B D-Bus error pattern detection + nohup+setsid
# fallback command present in deploy-runner.sh
# ============================================================================
section "TC2 (AC1): Branch B D-Bus error pattern detection + nohup+setsid fallback"
# Per architect spec: detect "Failed to connect to bus" / "No medium found" /
# "Connection refused" output class from `systemctl --user` calls, then fall
# back to nohup+setsid canonical pattern (operational reality per ADR-0027 §136).
# This is the new code path that d123a uniquely enforces.
HAS_DBUS_ERR_PATTERN=$(grep -nE '(Failed[[:space:]]+to[[:space:]]+connect[[:space:]]+to[[:space:]]+bus|No[[:space:]]+medium[[:space:]]+found|Connection[[:space:]]+refused)' "$DEPLOY_RUNNER" || true)
HAS_NOHUP_SETSID_FALLBACK=$(grep -nE 'nohup[[:space:]]+(.*setsid|setsid[[:space:]]+)?(.*uvicorn|\./|\.venv/bin/uvicorn)' "$DEPLOY_RUNNER" || true)
if [ -n "$HAS_DBUS_ERR_PATTERN" ] && [ -n "$HAS_NOHUP_SETSID_FALLBACK" ]; then
  pass "TC2 — Branch B D-Bus error detection + nohup/setsid uvicorn fallback literal present"
else
  fail "TC2 — Branch B D-Bus fallback path MISSING" \
    "expected: (i) D-Bus error class literal matching 'Failed to connect to bus' / 'No medium found' / 'Connection refused' (ii) nohup+setsid uvicorn fallback command. Pattern='$HAS_DBUS_ERR_PATTERN' fallback='$HAS_NOHUP_SETSID_FALLBACK'. Refs arch disposition §Dev b1 hotfix scope (cmt 4881824175)."
fi

# ============================================================================
# TC3 (AC2 / arch TC2): Branch C RCA-14 unit-missing exit 7 path PRESERVED
# ============================================================================
section "TC3 (AC2): Branch C RCA-14 unit-missing hard-fail exit 7 preserved"
# Critical: the refactor must NOT accidentally lose the unit-missing hard-fail.
# Both preflight (atilcalc-web.service not registered) and AC4 (service not
# active after restart) must keep exit 7. The existing line 386 + line 558
# already do this; the refactor must NOT regress them.
HAS_PREFLIGHT_EXIT_7=$(grep -nE 'fail[[:space:]]+.*systemd.*unit[[:space:]]+NOT[[:space:]]+registered.*7' "$DEPLOY_RUNNER" || true)
HAS_AC4_EXIT_7=$(grep -nE 'fail[[:space:]]+.*not[[:space:]]+active.*7|RCA-14.*7' "$DEPLOY_RUNNER" || true)
if [ -n "$HAS_PREFLIGHT_EXIT_7" ] && [ -n "$HAS_AC4_EXIT_7" ]; then
  pass "TC3 — RCA-14 unit-missing exit 7 path preserved (preflight + AC4 both intact; AC2 met)"
else
  fail "TC3 — RCA-14 unit-missing exit 7 path REGRESSED" \
    "expected both 'fail ... systemd unit NOT registered ... exit 7' preflight AND 'fail ... not active ... 7' AC4 check. preflight='$HAS_PREFLIGHT_EXIT_7' ac4='$HAS_AC4_EXIT_7'. If missing, the refactor accidentally dropped the unit-missing invariant — refuse this regression (Issue #820 owner decision only goes b1 = Branch B supplement; b3 = runner provisioning)."
fi

# ============================================================================
# TC4 (AC3 / arch TC3): Branch A canonical `systemctl --user start` preserved
# ============================================================================
section "TC4 (AC3): Branch A canonical systemctl --user path preserved"
# When D-Bus is OK + unit registered, the script MUST use `systemctl --user
# start atilcalc-web.service` (canonical ADR-0010 path). Refactor must NOT
# regress this — the canonical path is still the GREEN state when
# preconditions are met.
HAS_SYSTEMCTL_USER_START=$(grep -nE 'systemctl[[:space:]]+--user[[:space:]]+start[[:space:]]+atilcalc-web\.service' "$DEPLOY_RUNNER" || true)
HAS_SYSTEMCTL_USER_STOP=$(grep -nE 'systemctl[[:space:]]+--user[[:space:]]+stop[[:space:]]+atilcalc-web\.service' "$DEPLOY_RUNNER" || true)
if [ -n "$HAS_SYSTEMCTL_USER_START" ] && [ -n "$HAS_SYSTEMCTL_USER_STOP" ]; then
  pass "TC4 — Branch A canonical systemctl --user start + stop preserved (AC3 met)"
else
  fail "TC4 — Branch A canonical path REGRESSED" \
    "expected both 'systemctl --user stop atilcalc-web.service' (pre-deploy) AND 'systemctl --user start atilcalc-web.service' (post-deploy). Refactor must keep both canonical calls. start='$HAS_SYSTEMCTL_USER_START' stop='$HAS_SYSTEMCTL_USER_STOP'."
fi

# ============================================================================
# TC5 (ADR-0045 lens d): silent_skip audit marker literal in script
# ============================================================================
section "TC5 (ADR-0045 lens d): <!-- adr-0010-supplement-silent-skip --> audit marker"
# Per architect spec, Branch B must emit the silent_skip audit marker
# when fallback triggers. Without this marker, the supplement path is
# SILENT in CI logs — only deploy-script exit code 0 vs 7 distinguishes
# paths. ADR-0045 lens d observability requires the marker literal.
HAS_SILENT_SKIP_MARKER=$(grep -nE 'adr-0010-supplement-silent-skip' "$DEPLOY_RUNNER" || true)
if [ -n "$HAS_SILENT_SKIP_MARKER" ]; then
  pass "TC5 — silent_skip audit marker literal '<!-- adr-0010-supplement-silent-skip -->' present (per ADR-0045 lens d; observability restored for supplement path)"
else
  fail "TC5 — silent_skip audit marker MISSING" \
    "expected '<!-- adr-0010-supplement-silent-skip -->' literal in deploy-runner.sh (emitted on Branch B D-Bus fallback trigger). Without the marker, the supplement path is SILENT — observability regression per ADR-0045 lens d. Refs arch disposition §Supp-W (cmt 4881824175)."
fi

# ============================================================================
# TC6 (defense-in-depth, sister-test regression guard): wait_for_uvicorn_ready
# helper + RCA-12 ss/etime check NOT removed by 3-branch refactor
# ============================================================================
section "TC6 (defense-in-depth): wait_for_uvicorn_ready + RCA-12 etime check NOT regressed"
# d123 (RCA-19 cold-start) and d017 (RCA-12 cross-user port) are orthogonal
# defenses. The 3-branch refactor targets only the `systemctl --user` path;
# it MUST NOT remove wait_for_uvicorn_ready (d123) or the ss/etime cross-user
# check (d017). Verify both intact.
HAS_WAIT_FOR_UVICORN_READY=$(grep -nE '^wait_for_uvicorn_ready[[:space:]]*\(\)' "$DEPLOY_RUNNER" || true)
HAS_SS_ETIME_CHECK=$(grep -nE 'ss[[:space:]]+-tlnpH?[[:space:]]+.*sport.*ATC_PORT|ss[[:space:]]+-tlnpH?[[:space:]]+"sport[[:space:]]*=[[:space:]]*:\$ATC_PORT"|new_etimes.*-gt.*60' "$DEPLOY_RUNNER" || true)
if [ -n "$HAS_WAIT_FOR_UVICORN_READY" ] && [ -n "$HAS_SS_ETIME_CHECK" ]; then
  pass "TC6 — wait_for_uvicorn_ready + RCA-12 ss/etime cross-user check intact (defense-in-depth NOT regressed)"
else
  fail "TC6 — defense-in-depth REGRESSED" \
    "expected: (i) wait_for_uvicorn_ready() helper definition (d123 backing), (ii) 'ss -tlnp sport = :\$ATC_PORT' OR 'new_etimes -gt 60' check (d017 RCA-12 backing). The 3-branch refactor must not touch these sister-test surfaces. wait='$HAS_WAIT_FOR_UVICORN_READY' ss='$HAS_SS_ETIME_CHECK'."
fi

# ============================================================================
# TC7 (ADR-0049 sister-pattern coverage ≥3): d017 + d122 + d123 baseline + d123a
# ============================================================================
section "TC7 (ADR-0049): sister-pattern ≥3 baseline coverage"
# Per ADR-0049, every new d-test must reference ≥3 sister-patterns. The b1
# hotfix scope has d017 + d122 + d123 (existing) + d123a (this PR) = 4.
# Verify deployment-script lineage mentions reference the sister family.
SISTER_REFS=$(grep -nE '# (d017|d122|d123|d123a)|\"d017\"|\"d122\"|\"d123\"|\"d123a\"' "$DEPLOY_RUNNER" || true)
SISTER_TEST_FILES=$(ls -1 "${REPO_ROOT}/scripts/tests/" 2>/dev/null | grep -E '^d017-.*\.sh$|^d122-.*\.sh$|^d123-.*\.sh$|^d123a-.*\.sh$' | sort -u || true)
SISTER_COUNT=$(printf '%s\n' "$SISTER_TEST_FILES" | grep -cE '^d(017|122|123|123a)-' || true)
if [ "$SISTER_COUNT" -ge 3 ]; then
  pass "TC7 — sister-pattern ≥3 baseline met (found ${SISTER_COUNT}: $(printf '%s' "$SISTER_TEST_FILES" | tr '\n' ' ')). ADR-0049 §Scope ≥3 met."
else
  fail "TC7 — sister-pattern coverage insufficient" \
    "expected ≥3 sister d-tests (d017 + d122 + d123 baseline + d123a this PR). Found ${SISTER_COUNT}: $(printf '%s' "$SISTER_TEST_FILES" | tr '\n' ' '). ADR-0049 §Sister-pattern minimum not met — refuse the PR until sister coverage lands."
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
TOTAL=$((PASS + FAIL))
printf "${B}==${D} d123a summary: ${PASS}/${TOTAL} PASS · ${FAIL} FAIL · ${INFO} INFO\n"
if [ "$FAIL" -eq 0 ]; then
  printf "${G}==${D} GREEN — 3-branch refactor + silent_skip marker + defense-in-depth intact\n"
  exit 0
else
  printf "${R}==${D} RED — refactor incomplete, see TC failures above\n"
  exit 1
fi
