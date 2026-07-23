#!/usr/bin/env bash
# d-test-network-abstraction.sh — pattern:NETWORK_DEP curl/gh call interception
# layer (Issue #1204 NIT-1, arch cmt 5033069366, ADR-0073 §10 row 5).
#
# Why this helper exists
# ----------------------
# Per Issue #1204 AC1: env-dep d-tests that exercise curl/gh API calls must
# provide a network abstraction layer with:
#   - Default: returns canned mock payload (no real network, no token required)
#   - RECONCILE_LIVE_TOKEN=1: forwards to real API
#   - network-down: detects unreachable (curl RC 6/7 or HTTP 000), falls back
#     to canned payload + emits silent_skip log per ADR-0056
#   - 429 retry: detects rate limit (HTTP 429), retries with exponential
#     backoff (1s/2s/4s), max 3 attempts; emits silent_skip per attempt
#
# Sister-pattern lineage (d-test framework, ADR-0049):
#   - d058 TC11 (CLAIM_NEXT_READY_LOCK_FILE env-var-driven override)
#   - d069 (WORKFLOW_FILES env-var-driven parameterization)
#   - d098 (--target-os flag + TARGET_OS env-var override)
#   - d099 (--check flag + RECONCILE_LIVE_TOKEN toggle — DIRECT sister)
#   - d064 (fake-binary factory, TC7 fake-uname sister-pattern)
#   - cycle ~#3642B REST fallback (gh api .../comments for GraphQL exhaustion)
#   - ADR-0056 silent_skip log emission doctrine
#
# Usage:
#   bash scripts/d-test-network-abstraction.sh --probe --url=<URL> [--check]
#   bash scripts/d-test-network-abstraction.sh --call --url=<URL> [--check]
#
# Modes:
#   --probe: resolve network state only (outputs: mock|live|down|rate-limited)
#   --call:  perform call with retry (outputs: response body OR canned payload)
#
# RECONCILE_LIVE_TOKEN:
#   unset/empty/0 → mock mode (no actual network call, canned payload)
#   1             → live mode (real API call with 429 retry + backoff)
#
# Exit codes:
#   0 — success (mock | live | down | canned payload emitted)
#   2 — invalid args / unrecoverable error
#   3 — rate-limited after max retries (429 exhausted)
#
# silent_skip log emission per ADR-0056:
#   When --check flag is set, emits silent_skip log entry on:
#     - mock mode invocation (mode=mock)
#     - network-down fallback (mode=down + url=<URL>)
#     - 429 retry attempts (mode=rate-limited + attempt=<N> + url=<URL>)
#
# Part of Sprint 33 P2 cluster (Issue #1199 + Issue #1200) per owner directive
# 2026-07-21T09:55Z. NIT-1 follow-up per arch verdict cmt 5033069366 on PR #1203.

set -uo pipefail

CHECK_ONLY=0
PROBE_ONLY=0
CALL_ONLY=0
URL=""

for arg in "$@"; do
  case "$arg" in
    --check)
      CHECK_ONLY=1
      ;;
    --probe)
      PROBE_ONLY=1
      ;;
    --call)
      CALL_ONLY=1
      ;;
    --url=*)
      URL="${arg#--url=}"
      ;;
    --help|-h)
      printf 'Usage: %s --probe|--call --url=<URL> [--check]\n' "$0" >&2
      printf 'Modes: --probe (resolve state) | --call (perform call with retry)\n' >&2
      printf 'Env: RECONCILE_LIVE_TOKEN=1 for live mode (default: mock)\n' >&2
      printf 'With --check, emits silent_skip log per ADR-0056.\n' >&2
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

[ -n "$URL" ] || { printf '--url=<URL> required\n' >&2; exit 2; }
if [ "$PROBE_ONLY" = "0" ] && [ "$CALL_ONLY" = "0" ]; then
  printf 'specify --probe or --call mode\n' >&2
  exit 2
fi

# Resolution precedence (mock-first default per ADR-0073 §10 row 5):
case "${RECONCILE_LIVE_TOKEN:-}" in
  1)
    LIVE_MODE=1
    ;;
  ""|0)
    LIVE_MODE=0
    ;;
  *)
    printf 'invalid RECONCILE_LIVE_TOKEN value: %s (must be unset, empty, 0, or 1)\n' "$RECONCILE_LIVE_TOKEN" >&2
    exit 2
    ;;
esac

emit_silent_skip() {
  # emit_silent_skip <mode> [extra_fields...]
  # Sister-pattern to d-test-reconcile-live.sh silent_skip emission
  local mode="$1"
  shift
  local extra=""
  if [ "$#" -gt 0 ]; then
    extra=" $*"
  fi
  if [ "$CHECK_ONLY" = "1" ]; then
    local log_dir="${D_TEST_LOG_DIR:-/var/log/dev-studio/AtilCalculator}"
    if [ -d "$log_dir" ] || mkdir -p "$log_dir" 2>/dev/null; then
      printf '%s silent_skip mode=%s helper=scripts/d-test-network-abstraction.sh test_pid=%d%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$mode" "$$" "$extra" >> "$log_dir/d099.silent_skip.log" 2>/dev/null || true
    fi
  fi
}

if [ "$LIVE_MODE" = "0" ]; then
  # Mock mode: canned payload, no network call (sister-pattern to d-test-reconcile-live.sh)
  emit_silent_skip "mock"
  if [ "$PROBE_ONLY" = "1" ]; then
    printf 'mock\n'
  else
    printf 'canned-payload-{"url":"%s","mock":true}\n' "$URL"
  fi
  exit 0
fi

# Live mode: probe URL via curl with retry (network-down fallback + 429 backoff)
CURL_BODY_FILE="$(mktemp -t d099-curl-body-XXXXXX)"
MAX_RETRIES=3
ATTEMPT=1

while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
  HTTP_CODE=$(curl --silent --max-time 5 --output "$CURL_BODY_FILE" --write-out '%{http_code}' "$URL" 2>/dev/null)
  CURL_RC=$?

  # Network-down detection: curl RC 6 (couldn't resolve host) or 7 (couldn't connect)
  # OR HTTP_CODE 000 (no response received). Sister-pattern to d064 fake-bin tests.
  if [ "$CURL_RC" -ne 0 ] && { [ "$CURL_RC" -eq 6 ] || [ "$CURL_RC" -eq 7 ] || [ "$HTTP_CODE" = "000" ]; }; then
    emit_silent_skip "down" "url=$URL"
    if [ "$PROBE_ONLY" = "1" ]; then
      printf 'down\n'
    else
      printf 'canned-payload-{"url":"%s","network_down":true}\n' "$URL"
    fi
    rm -f "$CURL_BODY_FILE"
    exit 0
  fi

  case "$HTTP_CODE" in
    2*)
      # Success: 2xx response, output body (or 'live' for --probe mode)
      if [ "$PROBE_ONLY" = "1" ]; then
        printf 'live\n'
      else
        cat "$CURL_BODY_FILE"
      fi
      rm -f "$CURL_BODY_FILE"
      exit 0
      ;;
    429)
      # Rate-limited: emit silent_skip per ADR-0056, backoff exponentially
      emit_silent_skip "rate-limited" "attempt=$ATTEMPT url=$URL"
      if [ "$ATTEMPT" -eq "$MAX_RETRIES" ]; then
        # Exhausted retries: --probe → 'rate-limited' + exit 0; --call → exit 3
        if [ "$PROBE_ONLY" = "1" ]; then
          printf 'rate-limited\n'
          rm -f "$CURL_BODY_FILE"
          exit 0
        fi
        rm -f "$CURL_BODY_FILE"
        exit 3
      fi
      # Exponential backoff: 1s, 2s, 4s
      sleep $((1 << (ATTEMPT - 1)))
      ATTEMPT=$((ATTEMPT + 1))
      continue
      ;;
    *)
      # Other HTTP error (4xx/5xx not 429)
      printf 'http error: %s (curl_rc=%d)\n' "$HTTP_CODE" "$CURL_RC" >&2
      rm -f "$CURL_BODY_FILE"
      exit 2
      ;;
  esac
done

# Unreachable (should not happen — MAX_RETRIES bounds the loop)
rm -f "$CURL_BODY_FILE"
exit 2