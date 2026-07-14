# Test Plan: STORY-S29 ping-env-decoupling — notify.sh Telegram/tmux Split

> **Status**: TDD-RED → TDD-GREEN (impl PR #1055 closes d-test RED state)
> **Story**: [#1055](https://github.com/atilcan65/AtilCalculator/issues/1055) — agent:developer, status:in-progress
> **Closes**: [#1053](https://github.com/atilcan65/AtilCalculator/issues/1053) (canonical tracker — env-missing regression)
> **Refs**: [#1054](https://github.com/atilcan65/AtilCalculator/issues/1054) (d-test issue, merged in PR #1056)
> **d-test**: `scripts/tests/d1024-s29-ping-env-decoupling.sh` (sister-cadence: merged PR #1056 ahead of impl)
> **Sister-pattern**: d1018 (S29-006 ADR-port), d1020 (S29-010 workflow-port), d296 (peer-poke argv), d058 (fake-session isolation)
> **Author**: @developer, 2026-07-14T09:08Z (Sprint 29 W1 gap-closing)

## Scope

- **In scope**: `scripts/notify.sh` refactor — split Telegram-first early-exit into independent try-blocks so tmux-wake fires UNCONDITIONALLY when `-w -r` is set. Telegram env-missing OR API-fail → WARN/ERROR log + exit 2 (NOT 1), peer tmux pane still wakes.
- **In scope**: AC2 exit-code matrix (0/1/2/3) per Issue #1055 §AC2.
- **Out of scope**: `scripts/agent-wake.sh` changes (TD-068b canonical, must remain untouched per AC4).
- **Out of scope**: `scripts/peer-poke.sh` functional changes (wrapper nominal, inherits notify.sh behavior via exec — AC3).
- **Out of scope**: `scripts/agent-watch.sh` regression changes (TC5 of d1024 covers graceful OSC-2 fallback — no impl change required).

## Why this fix

Sprint 29 kickoff audit + outage recovery (2026-07-14) revealed:

- `scripts/notify.sh` pre-fix: Telegram env-missing → `exit 1` BEFORE tmux-wake fired → peer tmux panes never woke (Issue #1053).
- ADR-0033 dual-channel doctrine (production): Telegram-not-required makes sense for tmux-only peer wake.
- But test/CI/headless setup (Telegram env unset) was silently broken: peer-poke.sh called notify.sh → notify.sh exited 1 → no wake.
- Result: power-cut recovery, fresh dev setup, CI environments all stalled at the peer-poke step.

## Adversarial Probes (TC selection rationale)

Per tester doctrine (input validation, auth, state, data, error paths):

- **Env-missing path** (TC1) — `TELEGRAM_BOT_TOKEN` unset, peer tmux pane still wakes
- **API-fail path** (TC2) — `TELEGRAM_BOT_TOKEN` invalid, Telegram API rejects, peer tmux pane still wakes
- **Happy path regression guard** (TC3) — valid env + reachable bot, dual-channel both fire (existing behavior preserved)
- **Wrapper inheritance** (TC4) — `peer-poke.sh` exec's notify.sh with env unset → exit 2 + wake fires (no change to peer-poke.sh needed)
- **OSC-2 graceful fallback** (TC5) — agent-wake.sh pane-title contamination → fallback index map fires gracefully (TD-068b regression guard)

## Test Cases

### TC1: AC1 Option B — Telegram env unset → exit 2 + WARN + tmux-wake
- **Setup**: Unset `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` in test env (`env -u` prefix). Fake tmux session `d1024-tc1-$$` with pane_title `ORCHESTRATOR`.
- **Steps**:
  1. Run `bash scripts/notify.sh -l info -w -r orchestrator "test d1024 tc1 env-unset probe"` with env unset
  2. Capture exit code + stderr
  3. `tmux capture-pane -t ${SESSION}:0.0 -p` and grep for "test d1024 tc1 env-unset probe"
- **Expected**:
  - Exit code = **2** (NOT 1 — pre-fix behavior was 1)
  - stderr contains WARN (case-insensitive) OR "tmux-wake" marker
  - tmux pane buffer contains the wake probe text (confirms agent-wake.sh fired)
- **Pre-impl**: ❌ FAIL (exit=1, wake_probe FAIL — exact Issue #1053 repro)
- **Post-impl**: ✅ PASS (this impl PR)

### TC2: AC1 Option B — Telegram API reject → exit 2 + ERROR + tmux-wake
- **Setup**: Set bogus `TELEGRAM_BOT_TOKEN=invalid-token-for-d1024-test` + bogus `TELEGRAM_CHAT_ID`. Fake session `d1024-tc2-$$` titled `DEVELOPER`.
- **Steps**:
  1. Run `bash scripts/notify.sh -l info -w -r developer "test d1024 tc2 invalid-token probe"`
  2. Telegram API rejects (invalid token → JSON `{"ok":false}`)
  3. `tmux capture-pane` for wake probe
- **Expected**:
  - Exit code = **2** (Telegram failed, tmux OK)
  - stderr contains ERROR (case-insensitive) OR "tmux-wake" marker
  - tmux pane buffer contains wake probe text
- **Pre-impl**: ❌ FAIL (exit=1, wake_probe FAIL)
- **Post-impl**: ✅ PASS

### TC3: AC1 happy-path — valid env + reachable bot → exit 0 + dual-channel
- **Setup**: Real `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` set in caller env (NOT test env — must be reachable to real bot).
- **Steps**:
  1. Run `bash scripts/notify.sh -l info -w -r architect "test d1024 tc3 happy-path probe"`
  2. Verify both Telegram API succeeds AND tmux wake fires
- **Expected**:
  - Exit code = **0** (both channels OK)
  - tmux pane buffer contains wake probe text
- **Pre-impl**: ✅ PASS (regression guard — pre-fix happy path was already correct)
- **Post-impl**: ✅ PASS (preserved)
- **Test env note**: TC3 is INFO-skipped in CI/local when Telegram env not set (TC1 covers env-unset semantics).

### TC4: AC1 — peer-poke.sh inherits notify.sh behavior → exit 2 + tmux-wake
- **Setup**: Unset Telegram env. Fake session `d1024-tc4-$$` titled `ORCHESTRATOR`.
- **Steps**:
  1. Run `bash scripts/peer-poke.sh orchestrator "test d1024 tc4 peer-poke env-unset probe"` with env unset
  2. peer-poke.sh `exec notify.sh -l info -w -r orchestrator ...` → inherits notify.sh fix
  3. `tmux capture-pane` for wake probe
- **Expected**:
  - Exit code = **2** (forwarded from notify.sh)
  - tmux pane buffer contains wake probe text
  - **No peer-poke.sh source change required** — wrapper is exec-style, behavior comes from notify.sh
- **Pre-impl**: ❌ FAIL (exit=1, wake_probe FAIL — exact Issue #1053 repro via peer-poke)
- **Post-impl**: ✅ PASS

### TC5: agent-wake.sh OSC-2 fallback — graceful no-op (regression guard)
- **Setup**: Fake session with OSC-2 non-printable chars in pane_title (title-match path will fail). agent-wake.sh fallback index map `${TMUX_SESSION}:main.0` won't resolve in fake session → graceful degradation.
- **Steps**:
  1. Run `bash scripts/agent-wake.sh orchestrator "test d1024 tc5 osc2 fallback probe"`
- **Expected**:
  - Exit code = **0** (silent no-op per TD-068b — `tmux send-keys` errors swallowed with `|| exit 0`)
  - No stderr output
- **Pre-impl**: ✅ PASS (no change to agent-wake.sh needed — already TD-068b compliant)
- **Post-impl**: ✅ PASS (regression guard — agent-wake.sh untouched per AC4)

## Self-test contract (per ADR-0049)

```bash
bash scripts/tests/d1024-s29-ping-env-decoupling.sh
```

- **Pre-impl state (RED on main, pre-PR #1056)**: TC1/TC2/TC4 FAIL — exit=1, wake_probe FAIL (Issue #1053 exact repro). TC0/TC5 PASS (syntactic + agent-wake.sh fallback).
- **Post-PR #1056 squash (RED-first d-test on main)**: same RED state — d-test exists on main, impl NOT yet committed.
- **Post-impl PR #1055 (this impl)**: all 5 TCs GREEN — verified locally on `developer/d1024-s29-ping-env-decoupling-impl` branch.

## Exit-code matrix (AC2 verbatim)

| Telegram state | tmux-wake state | Wake mode (`-w` set) | Legacy mode (no `-w`) |
|---|---|---|---|
| OK | OK | 0 | 0 |
| OK | FAIL | **3** (NEW branch) | n/a |
| FAIL (env unset) | OK | 2 | 1 (legacy backward-compat) |
| FAIL (env unset) | FAIL | 1 | 1 |
| FAIL (API reject) | OK | 2 | 1 (legacy) |
| FAIL (API reject) | FAIL | 1 | 1 |

## CI integration

- d-test triggers: `.github/workflows/lint-and-test.yml` `Lint & Test (d-tests)` job (sister to d058 + d064 wiring per ADR-0049)
- d-test file: `scripts/tests/d1024-s29-ping-env-decoupling.sh` (339 lines, 5 TCs, ≥3 sister-patterns per ADR-0049)
- INDEX.md: row registered in Sprint 29 d-test slot (d1024 S29-ping-env-decoupling)

## Regression risk

- **Pre-fix scripts that depended on `exit 1` from notify.sh**: `scripts/peer-poke.sh` exec's notify.sh and forwards exit — TC4 verifies it now exits 2 (inherits new matrix). Any wrapper that did `if notify.sh; then ...` should still work because exit 2 ≠ 0 → still treated as failure, just with different code.
- **Non-wake mode legacy behavior**: preserved (0 OK / 1 fail). Any existing scripts using `notify.sh` without `-w` from non-tmux contexts unchanged.
- **ADR-0033 tmux-context enforcement**: preserved (lines 88-97 of post-fix notify.sh). Calling notify.sh from tmux without `-w -r` still exits 2 — the AC1 Option B fix does NOT relax this.
- **Existing d-tests (AC5 no-regression)**:
  - `scripts/tests/d024-agent-wake.sh` — 7/7 PASS post-fix ✅
  - `scripts/tests/d862-agent-watch-orch-lens-fix.sh` — 5/5 PASS post-fix ✅
  - `scripts/tests/d955-atilcalc-evaluate-persist-env-var.sh --self-test` — 5/5 PASS post-fix ✅

## Sister-patterns

- **d296** (peer-poke argv + usage discipline) — TC4 inherits notify.sh argv shape, AC3 dual-channel preservation
- **d320** (architect-authored stale_verdict contract) — exit-code semantics + stderr structure conventions
- **d058** (work-stream aware — owner-mercy-gate contract) — fake-session isolation pattern (no live peer pane touched)
- **d1018** (S29-006 ADR-port parity) — RED-first d-test cadence, sister Sprint 29 cluster
- **d1020** (S29-010 workflow-port-parity) — Sprint 29 d-test cadence, same author lane (tester), Cadence Rule 1 atomic discipline
- **d1024** (this d-test, S29-ping-env-decoupling) — primary contract

## Cross-references

- ADR-0033 (dual-channel doctrine) — the doctrine this cluster fixes
- ADR-0044 (RED-first TDD doctrinal home)
- ADR-0049 (d-test framework ≥5 TCs baseline + ≥3 sister-patterns)
- ADR-0055 §1 (Cadence Rule 1 atomic — d-test + INDEX.md same commit; impl + test plan same commit)
- ADR-0057 (closes-anchor strict format — `Closes #1053` for impl PR)
- ADR-0059 (cluster-squash — d-test ships BEFORE impl, verified)
- TD-068b (Issue #935) WAKE_KEYS_GAP_SEC env override (test fixture tolerance window)
- ADR-0031 (owner merge gate — only human squash-merges impl PR)
- Issue #1053 (canonical tracker — closes)
- Issue #1054 (d-test issue — refs)
- Issue #1055 (impl issue — this story)
- PR #1056 (d-test PR, merged 2026-07-14T09:02:05Z, merge_sha 2f31cb3)
- Sprint 29 plan §3 ping-env-decoupling cluster

## Open questions for arch + tester (impl PR review)

1. **Q1**: AC2 exit 3 branch (Telegram OK + tmux wake failed) — is the new code path well-tested? Currently d1024 doesn't have a TC for it (requires agent-wake.sh failure simulation). Consider follow-up d-test in Sprint 30?
2. **Q2**: `peer-poke.sh` _pair_verdict_by hook — does it still work correctly when Telegram env unset? (gh operations are Telegram-independent, should be fine, but worth a smoke check.)
3. **Q3**: AC7 ADR-NNNN cross-ref — Issue #1055 marks this as "architect optional, defer to post-merge". Will orchestrator open the ADR issue on merge?

— @developer, 2026-07-14T09:08Z (impl PR #1055 draft, d-test #1056 already merged, awaiting tester sign-off)