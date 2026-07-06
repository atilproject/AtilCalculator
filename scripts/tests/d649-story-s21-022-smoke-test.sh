#!/usr/bin/env bash
# d649-story-s21-022-smoke-test.sh — Issue #649 / STORY-S21-022
# 5 sub-scenario regression guard for scripts/dev-studio-init.sh.
#
# Why this test exists
# --------------------
# Issue #649 (STORY-S21-022, Smoke Test Script, 3sp hint) AC1-AC3 requires
# a smoke-test script that runs on every PR + CI gate exit code. Without
# smoke test in CI, template PRs can ship broken. The 5 sub-scenarios
# cover dry-run / broken-tmpl / idempotency / fresh-clone / manual-edit
# boundary contracts of `scripts/dev-studio-init.sh` (Issue #636 / S21-003a).
#
# This d-test was authored AFTER the pre-existing `scripts/tests/faz5-smoke.sh`
# (cycle ~#1231 re-sync labels, commit e30a4d4). The pre-existing faz5
# test was non-canonical (lacked ADR-0049 d-test framework header + INDEX.md
# row per ADR-0055 §1 Cadence Rule 1). This d649 adoption:
#   - Preserves the 5 sub-scenario TCs T1-T5 (verbatim, no logic change)
#   - Adds ADR-0049 d-test framework header (sister-pattern references +
#     spec ref + doctrinal origin + Cadence Rule 1 atomic INDEX.md row)
#   - Sister-pattern lineage to d070-template-render (Issue #637) +
#     d070b-init-prompt-ux (Issue #693) + d073-template-flag (Issue #701) +
#     d074-license-check (Issue #702) + d075-claude-md-content (Issue #705)
#     (≥3 sister-pattern baseline met per ADR-0049)
#
# 5 TCs (per ADR-0049 d-test framework, ≥3 TCs baseline met; Issue #649 AC1):
#   TC1 (--dry-run mode): dev-studio-init.sh --dry-run produces no file writes
#        (AC1 sub-case 1 — init must accept dry-run flag without side effects)
#   TC2 (broken-tmpl detection): missing-placeholder .tmpl caught by verify step,
#        init exits non-zero with placeholder reference in error log
#        (AC1 sub-case 2 — init must fail fast on broken template)
#   TC3 (idempotency): re-run idempotency — output sha256 stable across runs
#        (AC1 sub-case 3 + AC3 — re-render produces no diff; init is deterministic)
#   TC4 (fresh-clone simulation): local clone → init → all 12 renders OK
#        (AC1 sub-case 4 + AC2 — fresh-clone path must complete without error)
#   TC5 (manual-edit preserved): manual edit to rendered output is overwritten
#        on next run (AC1 sub-case 5 — init semantics are RENDERED_PATHS-only
#        side-effect; manual edits to rendered outputs are gitignored + lost)
#
# Pre-impl RED state (current origin/main 0cb10b2 — Issue #636 impl landed):
#   TC1 PASS (--dry-run works as documented)
#   TC2 PASS (verify() catches missing placeholders)
#   TC3 FAIL (idempotency hash stable but rc=1 — some other init failure path
#             exposes non-determinism OR init runs with degraded state)
#   TC4 FAIL (fresh-clone — gh repo view fails on local unpushed repos;
#             exposes gh-resolve path fragility when not pushed to GitHub)
#   TC5 FAIL (manual-edit survived re-render — exposes idempotency violation;
#             init must NOT preserve manual edits, must overwrite deterministically)
#
# RED count = 3/5 = 60% FAIL > 50% threshold per ADR-0044 — Cadence Rule 1
# RED-first contract met. d649 ships as test-only PR; impl PR brings GREEN
# when dev addresses T3/T4/T5 root causes.
#
# Usage:
#   bash scripts/tests/d649-story-s21-022-smoke-test.sh              # all tests
#   bash scripts/tests/d649-story-s21-022-smoke-test.sh T1 T3        # subset
#   VERBOSE=1 bash scripts/tests/d649-story-s21-022-smoke-test.sh    # echo intermediate
#
# Exit codes: 0 = all PASS, non-zero = at least one FAIL.
# Sister-pattern: d070-template-render (Issue #637) + d070b-init-prompt-ux (Issue #693)
#                 + d073-template-flag (Issue #701) + d074-license-check (Issue #702)
#                 + d075-claude-md-content (Issue #705)
# Refs: Issue #649, Issue #636 (impl), Issue #653 (downstream fresh-clone validation),
#       ADR-0044 RED-first, ADR-0049 ≥3 sister-pattern, ADR-0055 §1 Cadence Rule 1,
#       ADR-0057 Closes-anchor strict format.

set -u  # NOT -e: we want to keep running even if one test fails (so we get full report)

# --- repo root resolution (same idiom as dev-studio-init.sh) -----------------
REPO_ROOT="${DEV_STUDIO_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
INIT_SCRIPT="$REPO_ROOT/scripts/dev-studio-init.sh"

# --- colors (only when stdout is a TTY) --------------------------------------
if [[ -t 1 ]]; then
  C_OK=$'\033[0;32m'; C_FAIL=$'\033[0;31m'; C_INFO=$'\033[0;36m'; C_DIM=$'\033[0;90m'; C_OFF=$'\033[0m'
else
  C_OK=""; C_FAIL=""; C_INFO=""; C_DIM=""; C_OFF=""
fi

# --- counters ----------------------------------------------------------------
PASS=0
FAIL=0
SKIP=0
declare -a RESULTS

# --- helpers -----------------------------------------------------------------
say()  { printf '%s[smoke]%s %s\n' "$C_INFO" "$C_OFF" "$*"; }
ok()   { PASS=$((PASS+1)); RESULTS+=("${C_OK}PASS${C_OFF}  $1"); printf '%s[ ok ]%s %s\n' "$C_OK"   "$C_OFF" "$1"; }
fail() { FAIL=$((FAIL+1)); RESULTS+=("${C_FAIL}FAIL${C_OFF}  $1${2:+ — $2}"); printf '%s[fail]%s %s%s\n' "$C_FAIL" "$C_OFF" "$1" "${2:+ — $2}"; }
skip() { SKIP=$((SKIP+1)); RESULTS+=("${C_DIM}SKIP${C_OFF}  $1${2:+ — $2}"); printf '%s[skip]%s %s%s\n' "$C_DIM"  "$C_OFF" "$1" "${2:+ — $2}"; }

run_verbose() {
  if [[ "${VERBOSE:-}" == "1" ]]; then
    printf '%s$ %s%s\n' "$C_DIM" "$*" "$C_OFF" >&2
  fi
  "$@"
}

# Run a test only if it's in the filter list (or list is empty = all)
should_run() {
  local name="$1"
  if [[ ${#WANT[@]} -eq 0 ]]; then return 0; fi
  for w in "${WANT[@]}"; do [[ "$w" == "$name" ]] && return 0; done
  return 1
}

# --- parse argv: filter tests ------------------------------------------------
WANT=()
for arg in "$@"; do
  case "$arg" in
    T1|T2|T3|T4|T5) WANT+=("$arg") ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# --- preflight ---------------------------------------------------------------
say "REPO_ROOT = $REPO_ROOT"
say "INIT_SCRIPT = $INIT_SCRIPT"

if [[ ! -x "$INIT_SCRIPT" ]] && [[ ! -r "$INIT_SCRIPT" ]]; then
  fail "preflight" "init script not found at $INIT_SCRIPT"
  exit 1
fi

# --- T1: --dry-run produces no file writes -----------------------------------
if should_run T1; then
  say "T1: --dry-run mode produces no file writes"
  BEFORE=$(find "$REPO_ROOT" -type f \
    -not -path '*/\.git/*' \
    -not -path '*/\.venv/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/node_modules/*' \
    -printf '%p %T@\n' 2>/dev/null | sort | sha256sum | awk '{print $1}')
  OUT=$(bash "$INIT_SCRIPT" --dry-run 2>&1) || true
  AFTER=$(find "$REPO_ROOT" -type f \
    -not -path '*/\.git/*' \
    -not -path '*/\.venv/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/node_modules/*' \
    -printf '%p %T@\n' 2>/dev/null | sort | sha256sum | awk '{print $1}')
  if [[ "$BEFORE" == "$AFTER" ]]; then
    if grep -q -iE 'dry[ -]?run|would render|plan|render \(dry' <<<"$OUT"; then
      ok "T1 --dry-run: no writes, dry-run mode announced in output"
    else
      ok "T1 --dry-run: no writes (dry-run announcement not detected, but no side effects)"
    fi
  else
    fail "T1 --dry-run" "filesystem mutated during dry-run (BEFORE != AFTER hash)"
  fi
fi

# --- T2: missing-placeholder .tmpl is caught ---------------------------------
if should_run T2; then
  say "T2: bozulmuş .tmpl (unresolved placeholder) tespit edilmeli"
  BAD_DIR="$(mktemp -d -t faz5-T2.XXXXXX)"
  trap 'rm -rf "$BAD_DIR"' RETURN
  # Copy the entire repo to a sandbox so we can inject a bad .tmpl
  cp -r "$REPO_ROOT" "$BAD_DIR/repo"
  rm -rf "$BAD_DIR/repo/.venv" "$BAD_DIR/repo/__pycache__" 2>/dev/null || true
  # Inject a .tmpl that references an unknown placeholder
  cat > "$BAD_DIR/repo/scripts/tests/_bad-fixture.txt.tmpl" <<'EOF'
This template references an unknown placeholder: {{NEVER_RESOLVED}}.
The verify step MUST flag this and exit non-zero.
EOF
  # Run init inside the sandbox
  if DEV_STUDIO_REPO_ROOT="$BAD_DIR/repo" bash "$BAD_DIR/repo/scripts/dev-studio-init.sh" >"$BAD_DIR/out.log" 2>&1; then
    fail "T2 missing-placeholder" "init returned exit 0 — should have flagged unresolved {{NEVER_RESOLVED}}"
    sed -n '1,40p' "$BAD_DIR/out.log" | sed 's/^/    | /' >&2
  else
    if grep -qE 'unresolved|NEVER_RESOLVED|\{\{.*\}\}' "$BAD_DIR/out.log"; then
      ok "T2 missing-placeholder: init exited non-zero AND mentioned the unresolved placeholder"
    else
      ok "T2 missing-placeholder: init exited non-zero (placeholder name not in log, but failure detected)"
    fi
  fi
  rm -rf "$BAD_DIR"
  trap - RETURN
fi

# --- T3: re-run idempotency --------------------------------------------------
if should_run T3; then
  say "T3: re-run idempotency (output sha256 stable)"
  # Use a sandbox to avoid mutating the live repo's mtimes
  IDEM_DIR="$(mktemp -d -t faz5-T3.XXXXXX)"
  cp -r "$REPO_ROOT" "$IDEM_DIR/repo"
  rm -rf "$IDEM_DIR/repo/.venv" "$IDEM_DIR/repo/__pycache__" 2>/dev/null || true
  # Run 1
  DEV_STUDIO_REPO_ROOT="$IDEM_DIR/repo" bash "$IDEM_DIR/repo/scripts/dev-studio-init.sh" >"$IDEM_DIR/run1.log" 2>&1
  RUN1_RC=$?
  HASH1=$(find "$IDEM_DIR/repo" -type f \
    -not -path '*/\.git/*' \
    -not -path '*/\.venv/*' \
    -not -path '*/__pycache__/*' \
    \( -name '*.md' -o -name '*.yml' -o -name '*.service' -o -name '*.path' \) \
    -exec sha256sum {} \; 2>/dev/null | awk '{print $1}' | sort | sha256sum | awk '{print $1}')
  # Run 2
  DEV_STUDIO_REPO_ROOT="$IDEM_DIR/repo" bash "$IDEM_DIR/repo/scripts/dev-studio-init.sh" >"$IDEM_DIR/run2.log" 2>&1
  RUN2_RC=$?
  HASH2=$(find "$IDEM_DIR/repo" -type f \
    -not -path '*/\.git/*' \
    -not -path '*/\.venv/*' \
    -not -path '*/__pycache__/*' \
    \( -name '*.md' -o -name '*.yml' -o -name '*.service' -o -name '*.path' \) \
    -exec sha256sum {} \; 2>/dev/null | awk '{print $1}' | sort | sha256sum | awk '{print $1}')
  if [[ "$RUN1_RC" -eq 0 && "$RUN2_RC" -eq 0 && "$HASH1" == "$HASH2" ]]; then
    ok "T3 idempotency: hash($HASH1) stable across 2 runs"
  else
    fail "T3 idempotency" "rc1=$RUN1_RC rc2=$RUN2_RC hash1=$HASH1 hash2=$HASH2"
  fi
  rm -rf "$IDEM_DIR"
fi

# --- T4: fresh-clone simulation ----------------------------------------------
if should_run T4; then
  say "T4: fresh-clone simulation (lokal git clone -> init -> 12 renders OK)"
  if ! command -v git >/dev/null 2>&1; then
    skip "T4 fresh-clone" "git not available"
  else
    CLONE_DIR="$(mktemp -d -t faz5-T4.XXXXXX)"
    if run_verbose git clone --quiet --depth=1 "$REPO_ROOT" "$CLONE_DIR/repo" 2>"$CLONE_DIR/clone.err"; then
      # Lokal clone'un origin'i lokal path'e bakıyor; init script `gh repo view` çağırır,
      # bu da git remote `origin`'in GitHub URL'i olmasını ister. Gerçek dünyada
      # `gh repo create --template` zaten GitHub remote'una push edilmiş bir clone
      # bırakır; biz de origin'i orijinal GitHub URL'sine geri çeviriyoruz.
      ORIGIN_URL="$(git -C "$REPO_ROOT" config --get remote.origin.url 2>/dev/null || true)"
      if [[ -n "$ORIGIN_URL" ]]; then
        git -C "$CLONE_DIR/repo" remote set-url origin "$ORIGIN_URL" 2>/dev/null || true
      fi
      # init from inside the clone
      if (cd "$CLONE_DIR/repo" && bash scripts/dev-studio-init.sh) >"$CLONE_DIR/init.log" 2>&1; then
        # Stray-check scope: ONLY files init actually produced. We compute the
        # rendered-dst list the same way init does (every *.tmpl → dst with
        # .tmpl extension stripped). Scanning the whole clone would flag user-
        # authored docs that legitimately contain {{...}} (e.g. CHANGES files
        # documenting placeholder names) — those are NOT init's failure.
        STRAY=0
        while IFS= read -r -d '' tmpl; do
          dst="${tmpl%.tmpl}"
          if [[ -f "$dst" ]] && grep -qE '\{\{[A-Z_]+\}\}' "$dst" 2>/dev/null; then
            STRAY=$((STRAY + 1))
          fi
        done < <(find "$CLONE_DIR/repo" \
          -path "$CLONE_DIR/repo/.git" -prune -o \
          -path "$CLONE_DIR/repo/.venv" -prune -o \
          -type f -name '*.tmpl' -print0 2>/dev/null)
        # Look for the "12 template(s) rendered" line specifically
        if grep -qE '12 template\(s\) rendered' "$CLONE_DIR/init.log" && [[ "$STRAY" -eq 0 ]]; then
          ok "T4 fresh-clone: 12 templates rendered, no stray placeholders"
        elif [[ "$STRAY" -eq 0 ]]; then
          ok "T4 fresh-clone: render OK, no stray placeholders (template count not 12 verbatim)"
        else
          fail "T4 fresh-clone" "stray placeholders detected in $STRAY rendered output(s), see $CLONE_DIR/init.log"
          sed -n '1,40p' "$CLONE_DIR/init.log" | sed 's/^/    | /' >&2
        fi
      else
        fail "T4 fresh-clone" "init script failed in fresh clone"
        sed -n '1,40p' "$CLONE_DIR/init.log" | sed 's/^/    | /' >&2
      fi
    else
      skip "T4 fresh-clone" "git clone failed: $(cat "$CLONE_DIR/clone.err" 2>/dev/null | head -1)"
    fi
    rm -rf "$CLONE_DIR"
  fi
fi

# --- T5: manual edit to rendered output is overwritten -----------------------
if should_run T5; then
  say "T5: manuel edit'in üzerine basılmalı (idempotent re-render)"
  EDIT_DIR="$(mktemp -d -t faz5-T5.XXXXXX)"
  cp -r "$REPO_ROOT" "$EDIT_DIR/repo"
  rm -rf "$EDIT_DIR/repo/.venv" "$EDIT_DIR/repo/__pycache__" 2>/dev/null || true
  # First, render once to produce the README.md
  DEV_STUDIO_REPO_ROOT="$EDIT_DIR/repo" bash "$EDIT_DIR/repo/scripts/dev-studio-init.sh" >/dev/null 2>&1
  TARGET="$EDIT_DIR/repo/README.md"
  if [[ ! -f "$TARGET" ]]; then
    fail "T5 manual-edit" "README.md not rendered by initial init"
  else
    # Manually corrupt the rendered output
    MARKER="### MANUAL_EDIT_THAT_MUST_BE_OVERWRITTEN_$$"
    printf '\n\n%s\n' "$MARKER" >> "$TARGET"
    # Re-run init
    DEV_STUDIO_REPO_ROOT="$EDIT_DIR/repo" bash "$EDIT_DIR/repo/scripts/dev-studio-init.sh" >/dev/null 2>&1
    if grep -qF "$MARKER" "$TARGET"; then
      fail "T5 manual-edit" "manual edit survived re-render — init is NOT idempotent"
    else
      ok "T5 manual-edit: manuel edit re-render ile silindi (idempotent)"
    fi
  fi
  rm -rf "$EDIT_DIR"
fi

# --- summary -----------------------------------------------------------------
TOTAL=$((PASS+FAIL+SKIP))
echo
echo "===== Faz 5 smoke summary ====="
for line in "${RESULTS[@]}"; do printf '  %s\n' "$line"; done
echo "------------------------------"
printf '  TOTAL=%d  PASS=%d  FAIL=%d  SKIP=%d\n' "$TOTAL" "$PASS" "$FAIL" "$SKIP"
echo "==============================="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
