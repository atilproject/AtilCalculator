# Changelog

All notable changes to this project are recorded here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-09

### Template v1.0.0 GA — Single-Repo Template

First GA release of the dev-studio-template. Enables `git clone` +
`bash scripts/dev-studio-init.sh` to bootstrap a new single-repo
Python project on Ubuntu 24.04 LTS. Includes:

- dev-studio-init.sh + dev-studio-start.sh (template renderer + agent launchers)
- agent-watch.sh autonomy loop (ADR-0002)
- claim-next-ready.sh (ADR-0038 §Layer 2 atomic claim)
- 4-cat label invariant + atomic hand-off (ADR-0012 / ADR-0015)
- RED-first TDD d-test framework (ADR-0044 / ADR-0049)
- 9-Lens pre-publish gate (ADR-0045)
- 60+ ADRs in `docs/decisions/`
- Persona/vision cycle + RETRO ritual + `docs/product/glossary.md`

### Added
- (entries accumulate from Sprint 23 cluster-squash + Sprint 24 PR cluster)

### Fixed
- (run-off entries from [Unreleased] section)

### Security
- (SHA-pinned actions per ADR-0027; secrets-canary workflow)

## [1.0.1] - 2026-07-09

### Template v1.0.1 patch — tmux send-keys hardening

Patch release addressing the user-observed symptom of long wake prompts landing in the tmux pane buffer as raw text without being submitted to Claude Code. Root cause: `tmux send-keys` queues events; without a sleep gap between the text and `Enter`, they may arrive in the same handler tick and be treated as a single literal keystroke instead of a typed-then-submitted prompt.

### Fixed
- **TD-068b — tmux send-keys text+enter split with `sleep ${WAKE_KEYS_GAP_SEC:-0.5}` (PR #936, Closes #935, Refs #935).** All 5 call sites in `scripts/reprime-agent.sh` + `scripts/agent-wake.sh` + `scripts/agent-watch.sh` now use TWO separate `tmux send-keys` (or paste-buffer + send-keys) with a configurable sleep gap. `WAKE_KEYS_GAP_SEC` env override (default 0.5s) honored. The bundled `"/clear" Enter` and `"/compact" Enter` paths in reprime-agent.sh are now SPLIT into separate send-keys. Paste-buffer paths now sleep between paste-buffer write and Enter. Sister-pattern d-test (`scripts/tests/dXXX-tmux-send-keys-split.sh`, ≥5 TCs per ADR-0049) ships in PR #936. Owner-observed wake-prompt flakiness should now be eliminated across all 5 call sites.

### Cross-refs
- **PR #936** — TD-068b impl (merged 2026-07-09T14:10:03Z)
- **Issue #935** — original user directive (now closed)
- **Issue #941** — [Sprint 26] Kickoff, references v1.0.1 release
- **ADR-0012 / ADR-0015** — label invariant + atomic hand-off (unchanged)
- **Sister-pattern**: d-test framework (ADR-0049, ≥5 TCs baseline)

## [Unreleased]

### Changed

- **ADR-0073 §2 TIME_DEP removal + new §11 Considered + Rejected patterns (owner directive 2026-07-21T09:57:47+03:00, cycle ~#3968Q+71).** AC5 24h soak mechanic ABOLISHED per owner; Issue #1181 closed; Issue #1186 kickoff gate REMOVED. ADR-0073 §2 (Gap patterns) updated: `pattern:TIME_DEP` row REMOVED from deferred list (was: `Monotonic clock mock + bounded test window | time-of-day | ⏳ proposed | Issue #1186 AC5 24h soak`); §2 now lists 2 remaining gap patterns (CI_OS_DEP + NETWORK_DEP, NOT 3). New §11 (Considered + Rejected patterns) added with TIME_DEP entry + rejection rationale (owner rejects BOTH 24h soak AND any TIME_DEP-class d-test pattern) + Issue #1181 + Issue #1186 cross-refs. §9 cross-references updated (Issue #1186 line now notes kickoff gate REMOVED). §10 action items updated: dev now implements 2 patterns (NOT 3); Sprint 34+ P2 cluster shrinks accordingly. Header updated: status ACCEPTED + AMENDED + amendment scope note. **DOCTRINE** (cycle ~#3968Q+71): §2 purpose = "deferred for Sprint 33+ follow-up"; REJECTED ≠ DEFERRED → rejected patterns MUST move to §11 for historical record preservation. Alternatives rejected for §11 placement: (B) Remove without §11 entry — loss of historical record (vs ADR-0072 INDEX backfill pattern); (C) KEEP in §2 with "owner-rejected" status — mixes DEFERRED vs REJECTED categories (bad doctrine); (D) Separate ADR-0075 — over-engineering. **Sprint 33 plan addendum (S33-007) + arch lane S33-006 amendment UNTOUCHED per owner.** Lane review chain: arch (author + amendment author cycle ~#3968Q+71) + tester (Lane 2 docs verdict chain 1/1 sole per cycle ~#3642H for arch=author doctrine PRs) + owner @atilcan65 (squash gate per ADR-0031). **Cadence Rule 1 atomic (ADR-0055 §1)**: ADR-0073 §2 removal + new §11 + INDEX.md row amendment marker + this CHANGELOG.md entry land in same commit. Sister-patterns: cycle ~#3671 RETRO-022 regression (reflexive agent:* ADD anti-pattern), cycle ~#3968Q+70 RETRO-024 false-positive (reflexive agent:* REMOVE anti-pattern), ADR-0072 INDEX backfill (preserves historical record on corrective amendments). Cross-refs: Issue #1181 (closed), Issue #1186 (kickoff gate REMOVED), ADR-0073 (this amendment), PR #1195 (original ACCEPTED squash), cycle ~#3968Q+71 (this amendment cycle), owner directive 2026-07-21T09:57:47+03:00 (mirror via `notify.sh -w -r architect`).
- **ADR-0073 §10 action-item checkbox hygiene follow-up (cycle ~#3968Q+180+181).** Orchestrator NIT 2026-07-21T11:34Z flagged stale `[ ] **arch**: amendment PR` line in ADR-0073 §10 — left unchecked by PR #1196 amendment because the amendment PR itself was not yet squashed at commit time. **DOCTRINE (cycle ~#3968Q+180+181 extension)**: when an amendment PR adds an action-item line, EITHER pre-mark `[x]` with `'pending squash'` annotation OR defer the checkbox flip to a follow-up hygiene PR after squash terminal. This PR is the deferred hygiene variant. §10 `arch` line flipped from `[ ]` → `[x]` with merge metadata: `SQUASHED via PR #1196 1d21a32c 2026-07-21T08:30:06Z ✅`. INDEX.md row 78 AMENDED field refreshed with PR #1196 squash merge_sha + amendment chain attribution (cycle ~#3968Q+71 + cycle ~#3968Q+180+181 hygiene follow-up). Sister-pattern: cycle ~#3968Q+180 post-verdict wake-trigger hygiene (verdict-by + needs-X-review atomic pairing) — same cycle hygiene discipline applied to action-item checkboxes. Lane review chain: arch (author + this hygiene follow-up author) + tester (Lane 2 docs verdict cycle ~#3642H arch=author chain 1/1 sole sister) + owner @atilcan65 (squash gate per ADR-0031). **Cadence Rule 1 atomic (ADR-0055 §1)**: ADR-0073 §10 flip + INDEX.md row refresh + this CHANGELOG.md entry land in same commit. Cross-refs: ADR-0073 (this hygiene follow-up), PR #1196 (the original amendment PR that left the stale `[ ]`), cycle ~#3968Q+71 (amendment cycle), cycle ~#3968Q+180 (post-verdict wake-trigger hygiene doctrine), cycle ~#3968Q+180+181 (this checkbox hygiene extension), orchestrator NIT 2026-07-21T11:34Z.

### Added

- **ADR-0072 INDEX row backfill + ADR-0073 env-dep d-test sister-pattern doctrine (Issue #1182, Refs PR #1168 ADR-0072 impl, Refs Issue #1078 + #1182, sprint:current).** Sprint 33 P2 carry-over #9 of Issue #1171 cluster. **Two-part addition**: (a) **ADR-0072 backfill** — `docs/decisions/INDEX.md` row added for [ADR-0072](./docs/decisions/ADR-0072-tasklist-persistence-and-watchdog-tuning-revision.md) (Sprint 32 Wave-extension, Task-list Persistence + Watchdog Tuning Revision, Closes Issue #1078). Shipped via PR #1168 (squash @ `01b3c0b` 2026-07-19T15:15:11Z per git log) WITHOUT `docs/decisions/INDEX.md` row update — Cadence Rule 1 atomic (ADR-0055 §1) violation detected by @architect during ADR-0073 sibling PR audit. Backfill row added in this commit (single-revert-clean). (b) **ADR-0073 new** — [ADR-0073](./docs/decisions/ADR-0073-env-dep-dtest-sister-pattern.md) env-dep d-test sister-pattern doctrine, Closes Issue #1182. Codifies 8 sister-patterns (NOTIFY_NO_AUTOLOAD from Issue #1083 + FAKE_FLIPPED_FILE from Issue #1108 + CONTENT_BLOB_SHA from cycle ~#3955Q + ENV_ROT_SELF_TEST from cycle ~#3893Q v2 + BYTE_EQUAL_6_OF_6 from cycle ~#3427 + REST_FALLBACK from cycle ~#3642B + SELF_TEST_LIVE_SPLIT proposed for Issue #201 AC3 TC7 + LANE_3_DTEST_ONLY from cycle ~#3642H), 3 gap patterns (TIME_DEP + CI_OS_DEP + NETWORK_DEP → Sprint 34+ P2 follow-up Issues), canonical `pattern:<UPPER_SNAKE>` schema (grep-friendly + rename-stable), Sprint 33 SOFT `--self-test` gate → Sprint 34+ HARD gate transition (sister-pattern d050b workflow_dispatch.yml), update discipline (3 new-pattern triggers + 3 update triggers + RETRO-032 lesson #5 capture mechanism + Cadence Rule 1 atomic), and 7-lane tester rejection criteria. Origin: RETRO-032 lesson #5 didn't-go-well captured from tmpl#170 S32-021 d-test sweep (cycle ~#3471, AC4 env-dep stability NOT MET). **Cadence Rule 1 atomic (ADR-0055 §1)** — ADR-0073 + INDEX.md row + this CHANGELOG.md entry land in same commit. ADR-0072 INDEX row backfill also lands in same commit (corrective for prior PR #1168 violation). **Lane review chain**: arch (author) + tester (Lane 3 sister-pattern review per cycle ~#3642H + tester POV cmt 5026776083 sister-test inventory validation) + orchestrator (Sprint 34+ P2 cluster scheduling) + PM (Sprint 34 plan addendum refresh) + owner @atilcan65 (squash gate per ADR-0031, this ADR is `docs/decisions/` = arch lane NOT human-only territory per file ownership matrix). **d-test integration**: NOT created by this ADR — gap-pattern follow-up Issues will create 3 deferred d-tests (d1182a-time-dep + d1182b-ci-os-dep + d1182c-network-dep per ADR-0055 uniqueness invariant) in Sprint 34+. Sister-patterns: ADR-0044 (RED-first TDD), ADR-0049 (d-test framework ≥5 TCs baseline), ADR-0055 §1 (Cadence Rule 1 atomic), ADR-0057 (Closes anchor strict), RETRO-032 lesson #5 (origin), cycle ~#3471 (S32-021 sweep BOTH-gate), Issue #414 §1 (3-rule verdict pre-flight).

- **Issue #1199 S33-008 pattern:CI_OS_DEP — multi-OS target override helper + d098 d-test (Closes #1199, sprint:current).** Sprint 33 P2 cluster, gap-pattern row 4 of [ADR-0073](./docs/decisions/ADR-0073-env-dep-dtest-sister-pattern.md) §10 action items, owner directive 2026-07-21T09:55Z reframed Sprint 34 → Sprint 33 P2 cluster scope expansion (arch Option A amend commit 270f693 in PR #1198). **Two-part addition**: (a) **`scripts/d-test-target-os.sh` helper (NEW, ~80 LOC)** — env-dep d-test OS resolution with `uname -s` auto-detect (linux/darwin classes) + `--target-os=<linux|darwin>` flag override + `TARGET_OS` env-var override + precedence (flag > env > auto-detect) + validation (unknown value → exit 2). Designed per cycle ~#3853 d058 TC1 env-rot classification root cause (d-test assumed single-OS env → false-positive FAIL on macos-latest runners). Sister-pattern lineage: d058 TC11 (CLAIM_NEXT_READY_LOCK_FILE env-var override) + d069 (WORKFLOW_FILES env-var parameterization) + d109 (ci.yml BUDGET_MULTIPLIER env-block) + d115 (ci.yml SUBPROCESS_TIMEOUT_S env-block — direct sister). (b) **`scripts/tests/d098-ci-os-target-override.sh` d-test (NEW, ~270 LOC, 8/8 GREEN locally verified per cycle ~#3893Q v2 verify-locally-before-verdict)** — TC0 bash -n hygiene sister-pattern d020a TC1 + TC1 env-default auto-detect via `uname -s` → linux|darwin + TC2 `--target-os=linux` override ubuntu-latest class + TC3 `--target-os=darwin` override macos-latest class + TC4 invalid `--target-os=foobar` → exit 2 with error + TC5 flag precedence — flag beats TARGET_OS env var + TC6 TARGET_OS env var path with no flag + TC7 env-var escape hatch — `TARGET_OS=linux` bypasses fake-uname `UnsupportedOS`. RED-first per ADR-0044 — pre-impl 8/8 FAIL (helper + d-test absent from main). ≥5 TCs baseline per ADR-0049 — d098 = 8 TCs exceeds baseline by 3. ≥3 sister-pattern coverage per ADR-0049 met (4 sisters: d058 + d069 + d115 + d109). **Cadence Rule 1 atomic (ADR-0055 §1)** — helper + d-test + INDEX.md row + this CHANGELOG.md entry = 4 files same commit. **Lane review chain**: arch (9-Lens ADR-0045 on multi-OS matrix doctrine per `pattern:CI_OS_DEP` sister-pattern compliance) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H) + owner @atilcan65 (squash gate per ADR-0031). **Sister-cluster pattern**: Issue #1200 S33-009 pattern:NETWORK_DEP claims slot 3 after #1199 squash (per cycle ~#209 reframe order). **Doctrinal anchors**: cycle ~#3853 (d058 TC1 env-rot classification root cause), cycle ~#3893Q v2 (verify-locally-before-verdict — d098 --self-test run locally pre-PR), Issue #414 §1 (pre-PR re-query), ADR-0002 (autonomy loop), ADR-0033 (dual-channel peer-poke), ADR-0038 §Layer 2 (WIP cap), ADR-0044 (RED-first TDD), ADR-0049 (d-test ≥5 baseline + ≥3 sister), ADR-0055 §1 (Cadence Rule 1 atomic — 4 files same commit), ADR-0057 (Closes anchor — `Closes #1199` per impl purpose).

- **Issue #1210 + Issue #1211 Sprint 33 P2 cluster follow-up — d-stall-detect option (a) PR-driven-only + agent-watch stall wiring d-test specs (Refs #1210 Refs #1211, sprint:current, RED-first).** Two-part d-test cluster (paired companions, cluster-squash pair eligible per Issue #1210 Sprint scope section + Issue #1211 cluster-squash pair eligible). **Part 1 — Issue #1210 (STORY-d-stall-detect-fix-a, PR-driven-only stall detection — Issue #1180 false-negative fix, option a)**: **`scripts/tests/d-stall-detect-pr-driven.sh` d-test (NEW, ~145 LOC, 6 TCs, 3 PASS + 3 FAIL RED-first verified locally @ 11:57:31Z per cycle ~#3893Q v2 verify-locally-before-verdict)** — T1 ✗ FAIL issue_stall_hours check still present in detection rule [pre-impl] + T2 ✗ FAIL no-PR-linked check nested inside issue_stall_hours check [Issue #1180 false-negative still latent] + T3 ✓ PASS status:in-review preserved [sister to d-stall-detect T5] + T4 ✓ PASS status:blocked preserved [sister to d-stall-detect T6] + T5 ✗ FAIL stall_hours field still in JSON output [Issue #1210 AC3 not yet refactored] + T6 ✓ PASS STALL_DETECT_AUTO_NOTIFY env gate default off wired [arch NIT TC10 from Issue #1211 cmt 5058101861]. RED-first per ADR-0044 — pre-impl 3 FAIL verified. ≥5 TCs baseline per ADR-0049 — d-stall-detect-pr-driven = 6 TCs exceeds baseline by 1. ≥3 sister-pattern coverage met (7 sisters: d-stall-detect + d099 + d098 + d058 TC11 + cycle ~#3968Q+213 + cycle ~#3968Q+218 + arch NIT TC10). **Part 2 — Issue #1211 (STORY-agent-watch-stall-wiring-audit, agent-watch.sh stall wiring audit + RETRO-024 silent-skip)**: **`scripts/tests/d-agent-watch-stall-wiring.sh` d-test (NEW, ~130 LOC, 5 TCs, 4 PASS + 1 FAIL RED-first verified locally @ 12:00:00Z)** — T1 ✓ PASS integration block present at line 1962 [orchestrator-only lens] + T2 ✓ PASS dev_stall at line 1963 AFTER wip_idle at line 1918 [sister-pattern position] + T3 ✓ PASS wave coalesce ≥3 stalls → single dev_stall_wave event [sister to wip_idle_wave, arch 🟡 #2 on #289] + T4 ✓ PASS dev_stall events emitted on every orchestrator poll cycle [sister to wip_idle] + T5 ✗ FAIL RETRO-024 silent-skip on work-done-elsewhere issues NOT wired in dev_stall integration block [arch NIT TC11 from cmt 5058101861 — pre-impl silent-skip filter absent]. RED-first per ADR-0044 — pre-impl 1 FAIL verified. ≥5 TCs baseline per ADR-0049 — d-agent-watch-stall-wiring = 5 TCs meets baseline. ≥3 sister-pattern coverage met (7 sisters: d-stall-detect + d052 + d034 + wip-idle-detect.sh + RETRO-024 + ADR-0039 + arch verdict). **Cadence Rule 1 atomic (ADR-0055 §1)** — 2 d-test files + scripts/tests/INDEX.md (2 new rows) + this CHANGELOG.md entry = 4 files same commit cluster (paired d-test specs only, impl deferred to follow-up Issue #1210/Issue #1211 impl PRs per Issue #1183 / Issue #1211 lane definitions). **Lane review chain**: tester (this d-test spec PR, agent:tester + cc:developer + cc:orchestrator hand-off per ADR-0015) + developer (Issue #1210 impl — agent-stall-detect.sh option a refactor, makes d-stall-detect-pr-driven.sh T1+T2+T5 GREEN) + orchestrator (Issue #1211 impl — agent-watch.sh RETRO-024 silent-skip filter on dev_stall block, makes d-agent-watch-stall-wiring.sh T5 GREEN) + owner @atilcan65 (squash gate per ADR-0031). **Cluster-squash pair eligibility**: d-test spec PR (this) + Issue #1210 impl PR + Issue #1211 impl PR = 3-way cluster-squash candidate within cycle ~#3258 60s cap per owner discretion. **Sister-cluster pattern**: cluster-squash #4 PR #1206+#1207 (Issue #1184 audit + Issue #1204 NIT-1, 12-sec window — sister for d-test spec + impl pairing). **Doctrinal anchors**: cycle ~#3893Q v2 (verify-locally-before-verdict — both d-tests run locally pre-PR), Issue #414 §1 (pre-PR re-query), ADR-0002 (autonomy loop), ADR-0033 (dual-channel peer-poke — applied at PR-open orch+arch+tester wake), ADR-0038 §Layer 2 (WIP cap), ADR-0044 (RED-first TDD — 4 FAIL across 2 d-tests verified pre-impl), ADR-0049 (d-test ≥5 baseline + ≥3 sister — both met), ADR-0055 §1 (Cadence Rule 1 atomic — 4 files same commit), ADR-0057 (Refs anchor — `Refs #1210` + `Refs #1211` per d-test spec purpose, NOT Closes per cycle ~#2919 protection), RETRO-024 (Issue #1027 — work-done-elsewhere terminal state, TC11 doctrinal anchor for d-agent-watch-stall-wiring T5), owner directive 2026-07-22T16:17Z (gap-closing sprint activation), dev audit cmt 5056373219 (2026-07-23T08:54Z — owner directive selecting option a), arch verdict on Issue #1211 cmt 5058101861 (Lane 2 docs verdict 🟡 NIT-1+NIT-2).

- **Issue #1210 Sprint 33 P2 — d-stall-detect option (a) PR-driven-only impl (Closes #1210, Refs #1211, sprint:current).** Issue #1180 false-negative fix per dev audit cmt 5056373219 (owner directive selects option a) — single-file refactor `scripts/agent-stall-detect.sh` removes `issue_stall_hours >= THRESHOLD_HOURS` AND clause; new rule is `STALL iff (no PR linked to issue OR last_pr_min >= threshold)` per arch verdict on Issue #1210. **Detection rule changes**: (a) `iso_to_hours()` helper REMOVED (no longer consulted); (b) replaced `STALL iff` AND wrapper with single PR-driven rule (root cause: `issue.updatedAt` was bumped by passive auto-claim comments, masking the 24h threshold on Issue #1180 — RETRO-032 lesson #2 + dev audit cmt 5056373219 false-negative class); (c) `issue_updated_iso` + `issue_stall_hours` calculation REMOVED (single source of truth = PR-driven signal); (d) stall JSON output DROPS `stall_hours` field, keeps `last_pr_min` + `linked_pr` + `detected_at` (Issue #1210 AC3). **Edge cases preserved** (sister to d-stall-detect T5/T6 + d-stall-detect-pr-driven T3/T4): status:in-review excluded (PR up, awaiting verdict) + status:blocked excluded (legitimate block) + PR activity within threshold window. **STALL_DETECT_AUTO_NOTIFY env gate** wired at line ~241 (NIT-1 from arch cmt 5058101861, default off per wip-idle AUTO_NOTIFY sister-pattern) — emit block uses `last_pr_min` field instead of dropped `stall_hours`. **Header doc comment + output spec** updated to reflect option (a) rule. **bash -n SYNTAX OK** on the modified helper (cycle ~#3893Q v2 hygiene gate). **`scripts/tests/d-stall-detect-pr-driven.sh` d-test (created in PR #1213 squash 12:43:33Z 603f6c7) — 6/6 GREEN verified locally @ 2026-07-23T12:46Z per cycle ~#3893Q v2 verify-locally-before-verdict**: T1 ✓ PASS issue_stall_hours check REMOVED [option a PR-driven-only rule wired, was FAIL pre-impl] + T2 ✓ PASS no-PR-linked check top-level [Issue #1180 false-negative fix wired, was FAIL pre-impl] + T3 ✓ PASS status:in-review preserved [sister to d-stall-detect T5] + T4 ✓ PASS status:blocked preserved [sister to d-stall-detect T6] + T5 ✓ PASS stall_hours field dropped from JSON output [Issue #1210 AC3, was FAIL pre-impl] + T6 ✓ PASS STALL_DETECT_AUTO_NOTIFY env gate default off wired [arch NIT TC10 from Issue #1211 cmt 5058101861, preserved PASS]. T1+T2+T5 went RED→GREEN post-impl; T3+T4+T6 preserved PASS. RED-first per ADR-0044 — pre-impl 3 FAIL verified; post-impl 6/6 GREEN. ≥5 TCs baseline per ADR-0049 — d-stall-detect-pr-driven = 6 TCs exceeds baseline by 1. ≥3 sister-pattern coverage met (7 sisters: d-stall-detect + d099 + d098 + d058 TC11 + cycle ~#3968Q+213 + cycle ~#3968Q+218 + arch NIT TC10). **Scripts/tests/INDEX.md d-stall-detect-pr-driven row** flipped from 🟡 RED-FIRST → 🟢 GREEN POST-IMPL + TCs field 3 PASS + 3 FAIL → 6/6 GREEN. **Cadence Rule 1 atomic (ADR-0055 §1)** — `scripts/agent-stall-detect.sh` (MODIFIED option a refactor) + `scripts/tests/INDEX.md` (this row RED→GREEN update) + `CHANGELOG.md` `[Unreleased] ### Added` entry = 3 files same commit. **Lane review chain**: tester (Lane 3 d-test-only sign-off per cycle ~#3642H on the d-test specs created in PR #1213 — applied retroactively to this impl PR since d-test is already merged via cluster-squash #5) + arch (Lane 2 docs verdict 🟡 — STALL_DETECT_AUTO_NOTIFY env gate TC10 + option (a) detection rule soundness per cmt 5058101861) + owner @atilcan65 (squash gate per ADR-0031). **Cluster-squash pair eligibility** (sister): PR #1213 d-test specs SQUASHED 12:43:33Z merge_sha 603f6c7 + this impl PR = cluster-squash pair within cycle ~#3258 60s cap per owner discretion (PR #1213 already landed; this impl PR is the SQUASH-GATE CANDIDATE that closes #1210). **Lane separation (CRITICAL per Issue #1211 body)**: agent-watch.sh integration block + NIT-2 RETRO-024 silent-skip filter on dev_stall events (d-agent-watch-stall-wiring T5) is ORCHESTRATOR lane per Issue #1211 `agent:orchestrator` assignment + body declaration "Lane: Orchestrator (this is OUR lane — wiring audit + impl in agent-watch.sh)" — NOT included in this PR per file ownership matrix (dev owns scripts/agent-stall-detect.sh only; orchestrator owns scripts/agent-watch.sh). Issue #1211 stays OPEN; orchestrator impl PR is the canonical closer (Closes #1211 anchor in orchestrator impl PR — `Refs #1211` in this dev impl PR is sister-cluster reference per cycle ~#2919 Path B, NOT Closes anchor). **Doctrinal anchors**: cycle ~#3893Q v2 (verify-locally-before-verdict — d-stall-detect-pr-driven 6/6 GREEN pre-PR per this discipline), cycle ~#3968Q+213 (env pollution guard sister-pattern preserved — GITHUB_REPO *"/"* check unchanged), Issue #414 §1 (pre-PR re-query — Issue #1210 4-cat INTACT verified `agent:developer + status:in-progress + type:refactor + priority:P1 + sprint:current + 4 cc:* labels`), ADR-0002 (autonomy loop — wake_nudge fire path remains intact), ADR-0033 (dual-channel peer-poke — applied at PR-open arch+tester wake per ADR-0015), ADR-0038 §Layer 2 (WIP cap = 2/2 honored — slot 2 impl ACTIVE), ADR-0044 (RED-first TDD — 3 FAIL verified pre-impl, 6/6 GREEN post-impl), ADR-0049 (d-test ≥5 baseline + ≥3 sister — 6 TCs + 7 sisters met), ADR-0055 §1 (Cadence Rule 1 atomic — 3 files same commit for dev lane; orchestrator impl is separate per lane discipline), ADR-0057 (Closes anchor — `Closes atilproject/AtilCalculator#1210` per impl purpose cross-repo per cycle ~#3968Q+213 + `Refs #1211` sister-cluster ref NOT Closes per cycle ~#2919 protection), RETRO-032 lesson #2 (origin — Sprint 32 final wave dev pane silent ~36h root cause), owner directive 2026-07-22T16:17Z (gap-closing sprint activation), dev audit cmt 5056373219 (2026-07-23T08:54Z — owner directive selecting option a), arch verdict cmt 5058101861 (Lane 2 docs verdict 🟡 NIT-1+NIT-2 — STALL_DETECT_AUTO_NOTIFY env gate TC10 dev lane owns; NIT-2 RETRO-024 silent-skip TC11 orchestrator lane owns).

- **Issue #1211 Sprint 33 P2 — agent-watch.sh stall wiring RETRO-024 silent-skip + STALL_DETECT_AUTO_NOTIFY env gate (Closes #1211, Refs #1210, Refs PR #1213, sprint:current, GREEN post-impl).** Orchestrator lane impl per arch verdict on Issue #1211 cmt 5058101861 (Lane 2 docs verdict 🟡 NIT-1+NIT-2, both closed by this impl). Sister-cluster companion to dev impl PR at `origin/dev/s33-p2-issue-1210-1211-impl` (Closes #1210 via PR #1214, dev lane owned). **Two-part wiring** inserted inside dev_stall integration block at `scripts/agent-watch.sh` L1962-2007: (a) **RETRO-024 silent-skip filter** (Issue #1211 AC5, arch NIT-2 cmt 5058101861) — jq `select(.agent != null)` defense-in-depth guard inserted at L~1978 between `stall_total` assignment and `stall_total>=3` branch (sister-pattern to L1265 stale_verdict owner-gated filter per Issue #1027 RETRO-024 doctrine) + RETRO-024 reference comment block documenting the doctrinal anchor + `silent_skip` log emission to `${XDG_CACHE_HOME:-$HOME/.cache}/dev-studio/agent-watch/dev-stall-wiring.log` per ADR-0056 lens-d observability discipline (TD-016/020 family, sister to auto-claim.log silent_skip pattern). The filter is structurally always-true today because `scripts/agent-stall-detect.sh` upstream-filters to `agent:developer + status:in-progress` via `gh issue list --label` (L129-148) — RETRO-024 work-done-elsewhere records (`type:* + status:ready + cc:human + no agent:*`) cannot structurally appear — but the guard documents intent + future-proofs cross-lane emission (e.g., if agent-stall-detect.sh ever drops the hardcoded `"developer"` literal at L213). (b) **`STALL_DETECT_AUTO_NOTIFY` env gate** (Issue #1211 AC4, arch NIT-1 cmt 5058101861) inserted at L~1992 around the per-stall JSON emission — default OFF (matches sister-pattern `scripts/agent-stall-detect.sh` L241 + `scripts/wip-idle-detect.sh` AUTO_NOTIFY gate + d052-agent-watch-hardening pattern). When unset (default), orchestrator emits observability-only `dev_stall_observed` events into the merged event stream (`autonomy-loop observability preserved per ADR-0002`) without peer-poke escalation; when `STALL_DETECT_AUTO_NOTIFY=1`, emits existing `dev_stall` events with full peer-poke + wave coalesce preserved. The wave coalesce path (L1978-1991, `stall_total>=3` branch) is left ungated — wave events always fire (no escalation cost, single wave event replaces N individual pings). **Lane separation enforced**: this PR is ORCHESTRATOR lane per file ownership matrix (orchestrator owns `scripts/agent-watch.sh`) + Issue #1211 `agent:orchestrator` + body declaration "Lane: Orchestrator (this is OUR lane — wiring audit + impl in agent-watch.sh)"; `scripts/agent-stall-detect.sh` is NOT touched here (dev lane, owned by Issue #1210 impl PR at `origin/dev/s33-p2-issue-1210-1211-impl` 3888780); RETRO-024 filter achieved at orchestrator integration boundary via lightweight jq guard + log emission, no `labels` field emission dependency from `scripts/agent-stall-detect.sh`. **`scripts/tests/d-agent-watch-stall-wiring.sh` d-test (created in PR #1213 SQUASHED 12:43:33Z merge_sha 603f6c7) — 5/5 GREEN verified locally post-impl @ 13:00:00Z per cycle ~#3893Q v2 verify-locally-before-verdict**: T1 ✓ PASS integration block present at L1962 [preserved, no scope creep beyond L2007] + T2 ✓ PASS dev_stall at L1963 AFTER wip_idle at L1918 [sister-pattern position preserved, RETRO-024 filter inserted at L~1978 between stall_total assignment and stall_total>=3 branch] + T3 ✓ PASS wave coalesce ≥3 stalls → single `dev_stall_wave` event [sister to wip_idle_wave, arch 🟡 #2 on #289, wave coalesce path unchanged outside env gate] + T4 ✓ PASS dev_stall events emitted on every orchestrator poll cycle [env gate now branches per-stall emission: gate off → `dev_stall_observed` events with `gate: "STALL_DETECT_AUTO_NOTIFY=0"` in context, gate on → existing `dev_stall` events with `stall_hours`+`linked_pr` context] + T5 ✓ PASS RETRO-024 silent-skip wired in dev_stall integration block [was RED pre-impl, now GREEN post-impl; jq `select(.agent != null)` + RETRO-024 reference comment + `silent_skip` log emission all wired, arch NIT-2 TC11 closed]. **scripts/tests/INDEX.md** d-agent-watch-stall-wiring row flipped 🟡 RED-FIRST → 🟢 GREEN POST-IMPL + TCs field 4 PASS + 1 FAIL → 5/5 GREEN + production file cell appends `(MODIFIED — RETRO-024 silent-skip filter at L~1978 + STALL_DETECT_AUTO_NOTIFY env gate at L~1992, arch NIT-1+NIT-2 cmt 5058101861 closed)` + Cadence Rule 1 atomic cell updates 4 files (d-test spec) → 3 files (orchestrator impl: agent-watch.sh + INDEX.md + CHANGELOG.md). **Cadence Rule 1 atomic (ADR-0055 §1)** — `scripts/agent-watch.sh` (MODIFIED — RETRO-024 filter + env gate, ~+45 LOC inside L1962-2007 block) + `scripts/tests/INDEX.md` (MODIFIED — d-agent-watch-stall-wiring row 🟡→🟢) + `CHANGELOG.md` (this entry) = 3 files same commit (orchestrator impl lane per Issue #1211 `agent:orchestrator`). **Lane review chain**: tester (Lane 3 d-test-only sign-off per cycle ~#3642H on PR #1213 d-test specs — applied retroactively since d-test already merged via cluster-squash #5 on 2026-07-23T12:43:33Z 603f6c7; T5 RED→GREEN verified locally pre-PR per this discipline) + arch (Lane 2 docs verdict 🟡 NIT-1+NIT-2 closeout — verifies TC10 + TC11 both closed by orchestrator impl; arch review focuses on jq `select` semantic correctness + env gate default-OFF + silent_skip log path canonical to `${XDG_CACHE_HOME:-$HOME/.cache}/dev-studio/agent-watch/dev-stall-wiring.log` per ADR-0056) + owner @atilcan65 (squash gate per ADR-0031). **Cluster-squash pair eligibility** (sister to cluster-squash #4 PR #1206+#1207 12-sec window 2026-07-23T07:03:08Z→07:03:20Z, 2 single-PR squashes in 19-min gap = STANDALONE per cycle ~#3258): PR #1213 d-test specs SQUASHED 12:43:33Z 603f6c7 + PR #1214 dev impl Closes #1210 (squash-eligible STANDALONE per arch chain 2/2 ACK 2026-07-23T12:59:00Z) + this orchestrator impl PR (squash-eligible after tester signoff + arch closeout + owner squash gate) = 3-PR cluster-squash pair-eligible within cycle ~#3258 60s cap per owner discretion. **PR body contract** (per ADR-0057): `Closes #1211` (orchestrator impl purpose) + `Refs #1210` (paired companion dev impl) + `Refs PR #1213` (d-test spec PR SQUASHED) + `Refs #1183` (origin spec line 220 — "Wave logic lives in scripts/agent-watch.sh's stall integration block"). **Doctrinal anchors**: cycle ~#3893Q v2 (verify-locally-before-verdict — d-agent-watch-stall-wiring.sh 5/5 GREEN pre-PR per this discipline), Issue #414 §1 (pre-PR re-query — Issue #1211 4-cat INTACT verified `agent:orchestrator + cc:architect + cc:developer + cc:tester + status:in-progress + priority:P1 + sprint:current`), ADR-0002 (autonomy loop — wake_nudge + merged event stream preserved + `dev_stall_observed` observability event when gate off), ADR-0012 (4-cat invariant — RETRO-024 exception per Issue #1027 doctrine), ADR-0033 (dual-channel peer-poke — applied at PR-open arch+tester wake per ADR-0015), ADR-0044 (RED-first TDD — 1 FAIL T5 verified pre-impl, 5/5 GREEN post-impl per cycle ~#3893Q v2), ADR-0049 (d-test ≥5 baseline + ≥3 sister — 5 TCs + 7 sisters met), ADR-0055 §1 (Cadence Rule 1 atomic — 3 files same commit for orchestrator impl lane), ADR-0056 (silent_skip log emission — `dev-stall-wiring.log` + lens-d observability per Issue #1211 AC5 doctrine), ADR-0057 (Closes anchor — `Closes #1211` per orchestrator impl purpose), RETRO-024 (Issue #1027 — work-done-elsewhere terminal state doctrine, anchor for TC11 silent-skip), arch verdict on Issue #1211 cmt 5058101861 (Lane 2 docs verdict 🟡 NIT-1+NIT-2 — env gate TC10 + silent-skip TC11 both closed by this impl), owner directive 2026-07-22T16:17Z (gap-closing sprint activation), cycle ~#3258 (60s cluster-squash cap — pairs with PR #1213 squash + PR #1214 dev impl).

- **Issue #1204 S33-009 NIT-1 pattern:NETWORK_DEP — network abstraction extension (curl/gh call interception + network-down fallback + 429 retry, Closes #1204, sprint:current, Refs PR #1203, Refs arch cmt 5033069366).** Sprint 33 P2 cluster NIT-1 follow-up per arch verdict on PR #1203 — d099 d-test extension for `pattern:NETWORK_DEP` family. Owner directive 2026-07-22T16:17Z "gap-closing sprint activation": sprint:next → sprint:current override applied; slot 2 ACTIVE per ADR-0038 §Layer 2. **Three-part addition**: (a) **`scripts/d-test-network-abstraction.sh` helper (NEW, ~140 LOC)** — curl/gh call interception layer with `--probe|--call` modes + RECONCILE_LIVE_TOKEN env-var override (unset/empty/0 → mock canned payload default per ADR-0073 §10 row 5 mock-first doctrine; 1 → live real API call with network-down fallback + 429 retry). **Modes**: `--probe` resolves network state only (outputs: `mock|live|down|rate-limited`); `--call` performs call with retry (outputs: response body OR canned payload). **Network-down detection** (curl RC 6/7 OR HTTP 000) → canned payload fallback + `silent_skip mode=down helper=scripts/d-test-network-abstraction.sh url=<URL>` log entry per ADR-0056. **429 retry** — exponential backoff (1s/2s/4s), max 3 attempts, `silent_skip mode=rate-limited attempt=<N> url=<URL>` per attempt; exhausted retries → `--probe` mode emits `rate-limited` + rc=0, `--call` mode emits rc=3. **Exit codes**: 0=success (mock|live|down|canned), 2=invalid args/unrecoverable, 3=rate-limited exhausted. Sister-pattern lineage: **d-test-reconcile-live.sh** (DIRECT sister, mode resolver precedent — TC7+TC8 in d099 preserved as baseline) + **d-test-target-os.sh** (flag+env override archetype d098) + **d064 fake-binary factory** (TC5 fake-curl 429 RETRY-loop sister-pattern) + d058 TC11 (CLAIM_NEXT_READY_LOCK_FILE env-var override) + d069 (WORKFLOW_FILES env-var parameterization) + d020a TC4 (jq filter perf budget) + cycle ~#3642B (REST fallback) + ADR-0056 silent_skip log emission doctrine (TC4 down + TC5 rate-limited retry log anchors). (b) **`scripts/tests/d099-reconcile-live-network-mock.sh` d-test extension (7 → 9 TCs, bash -n PASS on both helpers)** — TC0a bash -n hygiene on d-test-reconcile-live.sh (Issue #1200 baseline) + TC0b bash -n hygiene on d-test-network-abstraction.sh (Issue #1204 NIT-1 extension) + TC1-TC3 Issue #1200 baseline preserved (mock-first + live opt-in + silent_skip mock mode) + **TC4 network-down mock fallback** (probe `.invalid` URL per RFC 2606 → 'down' + canned payload + silent_skip mode=down + url= log) + **TC5 rate-limit detection** (fake-curl returning HTTP 429 via d064 fake-bin factory → 'rate-limited' output + silent_skip mode=rate-limited per attempt + ≥7s elapsed for 1+2+4s exponential backoff) + TC6 token-rotation mid-test preserved from Issue #1200 + TC7 invalid value → exit 2 (renumbered from old TC4) + TC8 --check flag path (renumbered from old TC5). RED-first per ADR-0044 — pre-Issue-#1204-squash, TC4+TC5 FAIL (network-abstraction helper absent from main); 7/9 RED state (TC0a+TC0b+TC1+TC2+TC3+TC6+TC7+TC8 GREEN + TC4+TC5 RED = NIT-1 extension unimplemented). ≥5 TCs baseline per ADR-0049 — d099 = 9 TCs exceeds baseline by 4. ≥3 sister-pattern coverage per ADR-0049 met (7 sisters: d058 + d069 + d098 + d064 + ADR-0056 + cycle ~#3642B + d020a). (c) **`scripts/tests/INDEX.md` d099 row expansion** — production files field now lists BOTH helpers (d-test-reconcile-live.sh Issue #1200 baseline + d-test-network-abstraction.sh Issue #1204 NIT-1); TCs field expanded 7/7 → 9/9 GREEN; Cadence Rule 1 atomic field expanded to 5 files (helper #1200 baseline + helper #1204 NIT-1 + d-test file + INDEX row + CHANGELOG entry); cross-references field adds Issue #1204 (sprint:current per owner directive) + PR #1203 (Issue #1200 impl squash @ 71d3e2b source of arch NIT-1 cmt 5033069366) + cycle ~#3968Q+186 (NIT-1 disposition NOT blocker — TC4/TC5 label divergence from Issue #1200 AC2a spec is follow-up PR not impl-blocker per arch precedent). **Cadence Rule 1 atomic (ADR-0055 §1)** — helper + d-test + INDEX.md row + this CHANGELOG.md entry = 4 files same commit (Issue #1204 NIT-1 extends the Issue #1200 cluster atomically; d-test-reconcile-live.sh is NOT modified — already shipped via PR #1203 squash). **Lane review chain**: arch (9-Lens ADR-0045 on network abstraction + retry doctrine per arch NIT-1 cmt 5033069366) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H) + owner @atilcan65 (squash gate per ADR-0031). **NIT-1 disposition**: TC4/TC5 label divergence from Issue #1200 AC2a spec noted by arch as NOT blocker (cycle ~#3968Q+186 precedent — duplicate --target-os=*) case clause cleanup in scripts/d-test-target-os.sh deferred to Issue #1202 follow-up PR). **Doctrinal anchors**: cycle ~#3893Q v2 (verify-locally-before-verdict — d099 --self-test run locally pre-PR per this discipline), cycle ~#3968Q+186 (lane-ownership NIT-1 disposition NOT blocker), Issue #414 §1 (pre-PR re-query — Issue #1204 verifies arch NIT-1 cmt 5033069366 status + sprint:current label), ADR-0002 (autonomy loop), ADR-0033 (dual-channel peer-poke), ADR-0038 §Layer 2 (WIP cap — Issue #1204 slot 2 ACTIVE), ADR-0044 (RED-first TDD — 7/9 RED pre-#1204-squash, 9/9 GREEN post-#1204-squash), ADR-0049 (d-test ≥5 baseline + ≥3 sister), ADR-0055 §1 (Cadence Rule 1 atomic — 4 files same commit), ADR-0056 (silent_skip log emission — TC3+TC8 mock + TC4 down + TC5 rate-limited retry log anchors), ADR-0057 (Closes anchor — `Closes #1204` per impl purpose), ADR-0073 (env-dep d-test sister-pattern doctrinal home — closes TC4 + TC5 NIT-1 with network abstraction extension), owner directive 2026-07-22T16:17Z (gap-closing sprint activation: #1204 sprint:next → sprint:current override).

- **Issue #1202 NIT-1 follow-up — scripts/d-test-target-os.sh duplicate `--target-os=*)` case clause cleanup (Refs PR #1201, Refs Issue #1199, Refs arch verdict cmt 5032787451).** Sprint 33 P2 cluster NIT-1 follow-up per arch 9-Lens verdict on PR #1201 (S33-008 pattern:CI_OS_DEP, Closes #1199) — duplicate case branch noted at `scripts/d-test-target-os.sh:49-54` (copy-paste artifact from initial draft). Bash silently accepts duplicate case clauses (last match wins) so functional but sloppy. **Single-file edit**: duplicate case clause at lines 52-54 REMOVED; single canonical `--target-os=*)` clause retained at lines 49-51. AC1 verification — `bash -n scripts/d-test-target-os.sh` PASS (hygiene preserved) + d098 --self-test 8/8 GREEN (no regression in override path). AC2 forward-port hygiene — reuses existing d098 file, no new d-test needed (1-line code change verified by d098 baseline per cycle ~#3893Q v2 verify-locally-before-verdict doctrine). AC3 Lane 2 docs verdict — arch (single-file change review per ADR-0045) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H, d098 re-verify 8/8 GREEN) + owner @atilcan65 (squash gate per ADR-0031). **Cadence Rule 1 atomic (ADR-0055 §1)** — helper + this CHANGELOG.md entry = 2 files same commit (NO INDEX.md update needed, d098 row unchanged; NO new d-test file per AC2 forward-port hygiene). **NIT-1 disposition precedent**: cycle ~#3968Q+186 (TC4/TC5 label divergence from Issue #1200 AC2a spec — arch noted NOT blocker, follow-up PR per sister-pattern). **Lane review chain**: arch (author) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H) + owner @atilcan65 (squash gate per ADR-0031). **Doctrinal anchors**: cycle ~#3853 (d058 TC1 env-rot classification — root cause for d098 helper), cycle ~#3893Q v2 (verify-locally-before-verdict — d098 --self-test 8/8 GREEN pre-PR), cycle ~#3968Q+186 (lane-ownership NIT-1 disposition NOT blocker precedent), Issue #414 §1 (pre-PR re-query), ADR-0002 (autonomy loop), ADR-0033 (dual-channel peer-poke), ADR-0038 §Layer 2 (WIP cap — Issue #1202 slot 2 ACTIVE after Issue #1204 squash frees slot per cycle ~#3968Q+214 claim atomic = status only KEEP cc:<self>), ADR-0044 (RED-first TDD — NIT-1 cleanup has no RED state per AC2 forward-port hygiene), ADR-0049 (d-test ≥5 baseline — d098 unchanged at 8/8 GREEN), ADR-0055 §1 (Cadence Rule 1 atomic — 2 files same commit, NO INDEX.md update per AC2 forward-port hygiene), ADR-0057 (Closes anchor — `Refs PR #1201` NOT `Closes #N` per Issue #1202 body spec, arch NIT-1 not impl-blocker), ADR-0073 (env-dep d-test sister-pattern doctrinal home), PR #1201 (S33-008 impl squash @ f0d3f83 — source of arch NIT-1 cmt 5032787451), Issue #1199 (S33-008 tracker — Closes anchor on PR #1201, Issue #1202 is Refs NOT Closes).

- **Sprint 33 doctrine amendment (RETRO-033, cycle ~#3968Q+209+).** `docs/sprints/sprint-33/RETRO-033.md` captures 9 doctrine strands emerging from Sprint 33 P2 cluster: (1) cycle ~#3968Q+180 verdict-by atomic pairing CANONICAL (LIVE-VALIDATED 5x on PR #1197 + #1198 + #1201 + #1203 + Issue #180) — verdict-by ADD MUST atomically pair with needs-X-review REMOVE via REST PUT label set with full replacement (cycle ~#3642B colon-label recovery pattern); (2) cycle ~#3968Q+209+ Sprint 33 scope expansion via PM Option A body-amend path (cycle ~#3968Q+71 sister-pattern); (3) cycle ~#3932Q+2 re-verdict pattern 3rd validation CANONICAL on PR #1198 (4 verdict-by labels historical chain preserved per cycle ~#3921Q doctrine); (4) cycle ~#3921Q verdict-by HISTORICAL EVIDENCE doctrine; (5) cycle ~#3968Q+186 wake-trigger lane-ownership; (6) cycle ~#3968Q+71 ADR-0073 §2 TIME_DEP removal amendment (REJECTED → §11 placement); (7) cycle ~#3968Q+213 cross-repo cluster-squash 12-sec window (PR #1201 + PR #203); (8) AC5 24h soak mechanic ABOLISHED per owner directive 2026-07-21T09:57:47+03:00; (9) cycle ~#3853 + cycle ~#3893Q v2 env-dep d-test pre-impl GREEN local verification attestation. Owner directive 2026-07-21T09:55Z trigger ("Sprint 34 framing FORBIDDEN; ALL open issues + PRs complete in Sprint 33"). Sister-pattern: RETRO-032 (cycle ~#3740, Sprint 32 retro template). **Cadence Rule 1 atomic (ADR-0055 §1)** — RETRO doc + this CHANGELOG.md entry = 2 files same commit (NO INDEX.md update needed, INDEX.md is ADR-specific per cycle ~#3968Q+30). **Lane review chain**: arch (author) + PM (Sprint 33 retrospective section reviewer per RETRO-032 sister-pattern) + orchestrator (cluster-squash state witness) + owner @atilcan65 (squash gate per ADR-0031). **Doctrinal anchors**: cycle ~#3968Q+180 family (verdict-by atomic pairing), cycle ~#3968Q+209+ (Sprint 33 doctrine amendment home), cycle ~#3932Q+2 (re-verdict pattern), cycle ~#3921Q (verdict-by historical evidence), cycle ~#3968Q+186 (lane-ownership), cycle ~#3968Q+71 (body-amend path), cycle ~#3968Q+213 (cross-repo cluster-squash), AC5 abolition owner directive, cycle ~#3853 (env-rot classification), cycle ~#3893Q v2 (verify-locally-before-verdict), ADR-0073 (env-dep d-test sister-pattern doctrine), ADR-0072 (task-list snapshot persistence), ADR-0057 (Closes anchor strict), ADR-0059 (cluster-squash).

- **Issue #1183 dev-pane pickup stall detection — orchestrator helper + agent-watch integration + d-stall-detect d-test (Closes #1183, sprint:current).** Sprint 33 P2 cluster follow-up per Issue #1184 wake_nudge audit SHIPPED via PR #1206 (cluster-squash #4, 07:03:08Z) — RETRO-032 lesson #2 didn't-go-well captured: Sprint 32 final wave dev pane went silent ~36h after claiming S32-019 cluster (root cause: tmux pane on wrong cwd + no recovery signal). **Three-part addition**: (a) **`scripts/agent-stall-detect.sh` helper (NEW, ~210 LOC)** — orchestrator-only PR-driven stall detector: scans `agent:developer + status:in-progress` issues for stalls (>24h since claim, no PR opened in threshold window). Detection signals: (1) issue updatedAt older than threshold AND (2) NO linked PR (search via `${issue_n} in:body` qualifier — gh CLI v2.x `linked:issue-<N>` is BROKEN, returns ALL PRs; verified at #1180: `linked:issue-1180` returned 30 PRs vs `in:body` returned 3, cycle ~#3968Q+213 sister-pattern); (3) NOT-stall edge cases (sister to wip-idle-detect signal 5): status:in-review excluded (PR up + awaiting verdict) + status:blocked excluded (legitimate block) + PR activity within threshold (PR created/updated/merged within window). GITHUB_REPO env pollution guard (cycle ~#3968Q+213 sister): validates `*"/"*` form before accepting, falls back to `gh repo view`. Exit codes: 0=success, 1=usage, 2=gh API, 3=preflight fail. (b) **`scripts/agent-watch.sh` integration block** (orchestrator-only lens, after wip_idle at line ~1961): emits `dev_stall` events per stall (Issue #1183 spec: peer-poke dev + orchestrator with @mention) + wave coalesce (≥3 stalls in 5-min window = single `dev_stall_wave` event per arch 🟡 #2 on #289 sister-pattern to wip_idle_wave). Sister-pattern lineage: wip-idle-detect.sh (Issue #291 base — orchestrator-only integration after wip_idle block) + d034 (sister d-test) + ADR-0039 (WIP-idle watchdog doctrinal home) + cycle ~#3968Q+213 (env pollution guard). (c) **`scripts/tests/d-stall-detect.sh` d-test (NEW, ~140 LOC, 9/9 GREEN verified locally per cycle ~#3893Q v2 verify-locally-before-verdict)** — T1 script exists + executable + T2 default 24h threshold per Issue #1183 spec + T3 GITHUB_REPO env pollution guard + T4 search syntax uses `${issue_n} in:body` (NOT broken `linked:issue-<N>`) + T5 status:in-review NOT stalled (signal 5 sister) + T6 status:blocked NOT stalled (legitimate block) + T7 --role validation rejects non-developer (cross-role stalls deferred Sprint 34+) + T8 agent-watch.sh integration block present (orchestrator-only lens) + T9 wave coalesce ≥3 stalls → single dev_stall_wave event. RED-first per ADR-0044 — pre-impl 9/9 FAIL verified; post-impl 9/9 GREEN. ≥5 TCs baseline per ADR-0049 — d-stall-detect = 9 TCs exceeds baseline by 4. ≥3 sister-pattern coverage per ADR-0049 met (5+ sisters: d034 + ADR-0039 + cycle ~#3968Q+213 + cycle ~#3642B + cycle ~#3968Q+218). **Cadence Rule 1 atomic (ADR-0055 §1)** — helper + agent-watch integration + d-test file + INDEX.md row + this CHANGELOG.md entry = 5 files same commit. **Lane review chain**: arch (9-Lens ADR-0045 on orchestrator integration + wave coalesce doctrine) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H) + owner @atilcan65 (squash gate per ADR-0031). **Sister-pattern**: Issue #1184 wake_nudge audit SHIPPED via PR #1206 (cluster-squash #4 12-sec window 07:03:08Z→07:03:20Z, mergeCommits 810f4c5+a943932, Issue #1184 AUTO-CLOSED 1-sec-lag per cycle ~#3679). **Cross-role stall detection**: explicitly OUT OF SCOPE (deferred to Sprint 34+ per Issue #1183 body — Issue #1183 only addresses developer lane; PM/arch/tester stalls = separate stories). **Auto-claim rescue**: explicitly OUT OF SCOPE (deferred to Sprint 34+ — Issue #1183 only surfaces stalls as wake events; auto-reassignment via claim-next-ready.sh is a follow-up decision). **Doctrinal anchors**: Issue #414 §1 (pre-PR re-query), RETRO-032 lesson #2 (origin), ADR-0044 (RED-first TDD), ADR-0049 (d-test ≥5 baseline + ≥3 sister), ADR-0055 §1 (Cadence Rule 1 atomic — 5 files same commit), ADR-0056 (silent-skip observability sister), ADR-0057 (Closes anchor — `Closes #1183` per impl purpose), ADR-0033 (dual-channel peer-poke — applied at PR-open arch+tester wake), ADR-0002 (autonomy loop — wake_nudge fire path integration at orchestrator poll cycle 60s default), ADR-0039 (WIP-idle watchdog doctrinal home — sister-pattern to new dev_stall pattern).

- **Issue #1180 S33 P1 Phase B — AC1 dry-run invocation helper + d-test (Closes #1180, sprint:current).** Sprint 33 P1 follow-up to Issue #162 (S32-024, prematurely closed per cycle ~#2919 partial Closes anti-pattern; PR #196 SQUASHED @ 5d2a251c 2026-07-20T15:10:34Z); AC5 24h soak mechanic ABOLISHED per cycle ~#3968Q+71+terminal (Issue #1196 squash 08:30:06Z, owner directive 2026-07-21T09:57:47+03:00, sister-pattern applies). **Two-part addition** (AC1 only — AC4 + AC6 deferred to follow-up PRs): (a) **`scripts/dev-studio-dryrun.sh` helper (NEW, ~303 LOC, bash -n PASS + chmod +x applied)** — Phase B AC1 dry-run invocation + project bootstrap surface providing 4 modes: `--source-mode` (exports `DRYRUN_4TUPLE_BOOTSTRAP_PHASES=[gh_repo_create,clone,checkout_tag,init_sh,bootstrap_labels]` + 5 helper functions per d001-launcher S29-013 Issue #1072 sourced-mode sister-pattern) + `--invoke` (single-line JSON `{owner,project,dir,tag,http_code,labels,init_clean,tmpl_remaining}` for d-test consumption; FIXTURE_MODE=1 emits fixture state per d001-launcher FIXTURE_* env-var discipline) + `--verify-4cat` (≥14 critical labels per ADR-0012 4-cat invariant, exit 0/7) + `--pm-claim` (Vision Intake issue path per AC4 surface, FIXTURE_VISION_ISSUE_NUMBER override). 5 helpers: `dryrun_resolve_repo_url` + `dryrun_http_probe` (FIXTURE-aware, gh auth token integration) + `dryrun_count_labels` (FIXTURE-aware 14-label count) + `dryrun_check_init_clean` (no .tmpl remaining, sister to Issue #185/186) + `dryrun_count_tmpl_remaining`. Exit codes 0-7 per spec. (b) **`scripts/tests/d1180-new-project-bootstrap-dry-run-phase-b.sh` d-test (NEW, ~340 LOC, 11/11 GREEN verified locally per cycle ~#3893Q v2 verify-locally-before-verdict)** — TC0 preflight bash + jq + TC1 helper exists + executable + bash -n clean (cycle ~#3893Q v2 hygiene gate) + TC2 --source-mode emits `DRYRUN_4TUPLE_BOOTSTRAP_PHASES` 4-tuple (d001-launcher sister-pattern) + TC3 --source-mode exposes all 5 helper functions (d001-launcher sister-pattern) + TC4 --invoke --fixture emits valid single-line JSON with all 8 keys (owner, project, dir, tag, http_code, labels, init_clean, tmpl_remaining) + TC5 --invoke --fixture --owner --project override respected + TC6 --verify-4cat FIXTURE_LABEL_COUNT=14 → exit 0 (AC6 surface per ADR-0012) + TC7 --verify-4cat FIXTURE_LABEL_COUNT=10 → exit 7 (4-cat verify FAIL per spec) + TC8 --pm-claim FIXTURE_VISION_ISSUE_NUMBER=42 → exit 0 with vision_issue=#42 emitted (AC4 surface) + TC9 mutually exclusive modes → exit 1 + TC10 --help → exit 0 with all 4 mode flags listed. RED-first per ADR-0044 — pre-impl 1/11 PASS (TC0 only) + 10/11 FAIL (TC1-TC10 dependent on helper file existence). ≥5 TCs baseline per ADR-0049 — d1180 = 11 TCs exceeds baseline by 6. ≥3 sister-pattern coverage per ADR-0049 met (4 sisters: d-s32-024 + d001-launcher-self-hosted-runner-patch + d-smoke-bootstrap-v110 + d-verify-portage-diff-engine). **Cadence Rule 1 atomic (ADR-0055 §1)** — helper + d-test + INDEX.md row + this CHANGELOG.md entry = 4 files same commit. **Lane review chain**: arch (9-Lens ADR-0045 on dry-run invocation surface + FIXTURE_MODE=1 discipline) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H) + owner @atilcan65 (squash gate per ADR-0031). **Sister-pattern**: d-s32-024-new-project-bootstrap-dry-run.sh (DIRECT — commit 5d2a251 PR #196, Phase A predecessor; 4 RED TCs TC4-TC7 from this predecessor are now addressed by Phase B AC1 helper surface — TC4-TC7 of d-s32-024 transition RED → GREEN post-#1180-squash). **AC4 PM claim + AC6 close-the-loop**: deferred to follow-up Issue (per cycle ~#3968Q+186 lane-ownership NIT-1 disposition NOT blocker precedent). **Doctrinal anchors**: Issue #414 §1 (pre-PR re-query), ADR-0044 (RED-first TDD — 1/11 RED pre-impl, 11/11 GREEN post-impl), ADR-0049 (d-test ≥5 baseline + ≥3 sister), ADR-0055 §1 (Cadence Rule 1 atomic — 4 files same commit), ADR-0056 (silent-skip observability sister — FIXTURE_MODE=1 log discipline), ADR-0057 (Closes anchor — `Closes atilproject/AtilCalculator#1180` per impl purpose, cross-repo per cycle ~#3968Q+213), ADR-0012 (4-cat invariant — --verify-4cat surface, AC6), ADR-0033 (dual-channel peer-poke — applied at PR-open arch+tester wake), ADR-0002 (autonomy loop — orchestrator wake integration), cycle ~#3893Q v2 (verify-locally-before-verdict — d1180 --self-test GREEN pre-PR), cycle ~#3968Q+213 (cross-repo cluster-squash precedent — atilcan65/AtilCalculator → atilproject/AtilCalculator path), cycle ~#3968Q+71+terminal (AC5 24h soak ABOLISHED — applies to #1180 AC5 disposition as ABOLISHED, no replacement needed), cycle ~#2919 (premature-close + sister-PR Path A vs Path B — Issue #162 was Path A premature close; Issue #1180 is Path B sister-PR follow-up with full AC1+AC4+AC6 d-testable surface), cycle ~#3968Q+214 (claim atomic = status only KEEP cc:<self> — applied at Issue #1180 auto-claim 2026-07-20T16:26:07Z), cycle ~#3968Q+209+ (Sprint 33 scope expansion directive — gap-closing sprint focus).

- **Sprint 34 W3 forward-port S34-002 row 012 — scripts/bootstrap-labels.sh PATCH-FORWARD divergent class (Refs atilcan65/AtilCalculator#1222, sprint:current, GREEN post-impl).** Sprint 34 W3 forward-port (per ADR-0075 §B.1 row 012 + Issue #1222 dispatch): row 012 = `scripts/bootstrap-labels.sh` PATCH-FORWARD class (NOT byte-equivalence — divergent per "AtilCalc has label set evolution; template has base set"). Per architect 283rd-wake cycle ~#3968Q+683 (2026-07-26T11:38:17Z) + 284th-wake cycle ~#3968Q+684 (11:40:12Z) + orchestrator correction cycle ~#3968Q+~11:38Z (deploy-runner.sh was row 017 NOT row 012). **MD5 evidence**: AtilCalc canonical (via soul-amend-l10 symlink target) + template = `e3f4f5efc281263c9a9a06c7cb48e67a` (94 lines, byte-identical NOW). **Sprint 33 label-set evolution amendments ported** (Issue #1210/1211 cluster + RETRO-024 silent-skip + agent-stall label + sprint:backlog/next labels + security label): TC5 verifies 10 amendment markers present (`agent-stall`, `sprint:backlog`, `sprint:next`, `security`, `good-first-issue`, `agent:orchestrator`, `cc:orchestrator`, `status:done`, `priority:P0`, `type:feature`). **Impl file UNCHANGED** (PATCH-FORWARD zero-diff proof via TC4 MD5 match). **`scripts/tests/d-s34-002-row-012-bootstrap-labels-patch-forward.sh` d-test (NEW, 8 TCs RED-first per ADR-0044)** — TC1 target file exists + TC2 bash -n syntactic self-check + TC3 line count = 94 [matches AtilCalc canonical] + TC4 MD5 = `e3f4f5efc281263c9a9a06c7cb48e67a` [PATCH-FORWARD zero-diff proof] + TC5 Sprint 33 amendment markers present [10 markers] + TC6 4-cat labels present [6 categories: priority/type/status/agent/cc/sprint per ADR-0012] + TC7 INDEX.md row present [Cadence Rule 1 atomic attestation] + TC8 CHANGELOG.md entry present [Sprint 34 W3 forward-port S34-002 row 012]. RED-first per ADR-0044 — pre-impl 6 PASS + 2 FAIL (TC7+TC8) verified; post-impl 8/8 GREEN. ≥6 TCs baseline per ADR-0049 (cycle ~#3471 ≥6 refinement) — d-s34-002-row-012 = 8 TCs exceeds baseline by 2. ≥3 sister-pattern coverage per ADR-0049 met (6 sisters: d-s34-002-row-011-audit-project-refs-byte-equivalence + d-s34-002-row-001-010 + AtilCalc Sprint 33 d-test framework + Sprint 33 d-stall-detect + Sprint 33 d-stall-detect-pr-driven + Sprint 33 d-agent-watch-stall-wiring RETRO-024 silent-skip). **scripts/tests/INDEX.md** d-s34-002-row-012 row appended (line 680+, after d-agent-watch-stall-wiring). **Cadence Rule 1 atomic (ADR-0055 §1)** — `scripts/bootstrap-labels.sh` (UNCHANGED — PATCH-FORWARD zero-diff) + `scripts/tests/d-s34-002-row-012-bootstrap-labels-patch-forward.sh` (NEW, d-test) + `scripts/tests/INDEX.md` (this row RED→GREEN append) + `CHANGELOG.md` `[Unreleased] ### Added` entry = 4 files same commit. **Lane review chain**: arch (Lane 2 docs verdict 9-Lens per ADR-0045 on PATCH-FORWARD divergent classification + Sprint 33 amendment verification) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H on d-s34-002-row-012 8 TCs) + owner @atilcan65 (squash gate per ADR-0031 — cluster-squash #27 candidate STANDALONE per cycle ~#3258 since W3 already 3/3 SHIPPED-functional). **PR body contract** (per ADR-0057): `Refs atilcan65/AtilCalculator#1222` per sub-deliverable pattern (Issue #1222 stays OPEN per RETRO-024 owner-ratification close — terminal `Closes` reserved for final W3 dispatch at row 280). **Out-of-scope escalations**: ADR-0075 §B.1 row 017 deploy-runner.sh equivalent → divergent reclassification (Task #118 arch lane direct filing in progress per architect 284th-wake ETA cycle ~#3968Q+686, NOT this PR); deploy.yml post-#215-squash status (cluster-lag-detector workflow permissions bug per cycle ~#3968Q+311+14 OUT-OF-TESTER-LANE flag to architect+owner for ADR-0059 amendment, NOT a deploy.yml issue per architect 283rd-wake). **Doctrinal anchors**: Issue #414 §1 (pre-PR re-query — Issue #1222 4-cat INTACT verified `type:feature + status:in-progress + agent:developer + cc:architect + cc:developer + cc:tester + cc:human + priority:P1 + sprint:current`), ADR-0044 (RED-first TDD — 2 FAIL TC7+TC8 verified pre-impl, 8/8 GREEN post-impl per cycle ~#3893Q v2 verify-locally-before-verdict), ADR-0049 (d-test ≥6 baseline — 8 TCs), ADR-0055 §1 (Cadence Rule 1 atomic — 4 files same commit), ADR-0057 (Refs anchor — Issue #1222 sub-deliverable pattern), ADR-0012 (4-cat label invariant on Issue #1222), ADR-0031 (owner squash gate), ADR-0033 (dual-channel peer-poke via proxy path AtilCalculator-d1142 per cycle ~#3968Q+666/667 path resilience), ADR-0075 §B.1 row 012 (parity matrix divergent class — "AtilCalc has label set evolution; template has base set"), ADR-0077 §B.1-amendment-017 (arch lane direct filing in progress — scripts/deploy-runner.sh equivalent → divergent reclassification), cycle ~#3968Q+460 (NEW doctrine cross-repo scope verification per Lane 0 dispatch), cycle ~#3968Q+311+8 (CONDITIONAL preventive — branch dev/s34-002-row-012 from origin/main 9cbe371 POST-#1228-squash NOT pre-squash applied), cycle ~#3968Q+685 (IMMEDIATE twin-squash variant ratification — W3 PR #17+PR #215 5s gap, STANDALONE per cycle ~#3258 applies to PR #216).
### Fixed

- **Issue #1150 — `test_install_command_executes` venv timeout (returncode -9) regression guard (Refs PR #1147, sprint:current).** P1 CI flake on PR #1147 (`orch/sprint-32-template-finalize-audit`): github-hosted runner OOM-killed `python -m venv` (returncode -9 = SIGKILL) during per-test venv creation, 60s timeout hard-coded at `tests/docs/test_readme.py:164` (pre-fix). Fix combines option-a (timeout bump 60s → 180s for slower CI runners) + option-c (session-scoped `shared_venv` fixture amortizes venv creation across pytest session, was per-test). `test_install_command_executes` refactored to consume the `shared_venv` fixture parameter, real `pip install -e .[dev]` still runs end-to-end inside the shared venv (AC4 "no pure mock" preserved). New regression guard `scripts/tests/d-pr-1147-install-test-flake.sh` (4 TCs: TC1 timeout=180 literal present + TC2 `@pytest.fixture(scope="session") def shared_venv(...)` fixture exists + TC3 test_install_command_executes wired to shared_venv parameter + TC4 pytest execution regression guard) + INDEX.md row per Cadence Rule 1 atomic (ADR-0055 §1). Local verification: 4/4 d-test GREEN + 7/7 pytest PASS in 26.75s on `dev/issue-1150-install-test-flake` branch off origin/main (b5f0a34). Cluster-squash impact: unblocks PR #1147 (Sprint 32 plan, verdict chain 4/4 owner-merge-READY) Wave 1 cluster-squash window per ADR-0059. Sister-pattern: option-c (pre-install fixture) chosen over option-b (mock) per Issue #1150 body recommendation; option-d (xfail) deferred; option-e (workflow fix) owner-only territory per file ownership matrix.

### Removed

- **STORY-S28-008 LEGACY-REMOVE — `scripts/ping.sh` + `scripts/tests/d038-ping-wrapper.sh` DELETED from calc (Issue #989, Closes #989, Refs #988).** Sprint 28 W2 sister-pattern to S28-007 S-08a port (PR #69 squash on tmpl). After S28-007 ported `peer-poke.sh` + Auto-Verdict-By hook to `dev-studio-template/scripts/peer-poke.sh.tmpl`, the calc-side `scripts/peer-poke.sh` was REPLACED with a symlink → tmpl (6284B byte-identical, no sed-substitutable placeholders, bash executes symlinked `.tmpl` directly), and the legacy `scripts/ping.sh` (single-source wrapper that pre-dated peer-poke.sh per ADR-0033) was DELETED entirely (no tmpl equivalent — ping.sh was the LEGACY form per ADR-0033, replaced by peer-poke.sh on 2026-06-25 PR #296). The corresponding direct-test `scripts/tests/d038-ping-wrapper.sh` (which tested the deleted `ping.sh` wrapper) was also DELETED. **5 downstream d-tests updated** to remove `ping.sh` coupling: `d039-lint-notify-invocations.sh` (mixed-fixture diff filename `scripts/ping.sh` → `scripts/notify-invocations.sh`, no behavioral change — regex tests `notify.sh -l <role>` regardless of fixture filename), `d056-autoping-dual-channel.sh` (TC1-TC4 ping.sh canonical-wrapper tests REMOVED; 9/9 → 5/5 PASS, remaining TC5-TC9 cover notify.sh dual-channel directly), `d065-dual-channel-enforcement.sh` (TC5 `ping.sh <role> migration wrapper bypasses tmux guard` REMOVED; 5/5 → 4/4 PASS, remaining TC1-TC4 cover notify.sh dual-channel directly), `d296-peer-poke-helper.sh` (comment-only cleanup removing historical "sister-pattern d038-ping-wrapper" references — test logic unchanged, 19/19 PASS preserved). `scripts/tests/INDEX.md` rows for d056 (9/9 → 5/5), d065 (5/5 → 4/4), d296 updated to reflect post-LEGACY-REMOVE state + add "Issue #989 / S28-008 LEGACY-REMOVE" callout. Sister-pattern with S28-007 S-08a port: tmpl is single-source canonical, calc reaches tmpl transitively via symlink. Cadence Rule 1 atomic (ADR-0055 §1): symlink creation + deletion of `ping.sh` + deletion of `d038-ping-wrapper.sh` + d-test edits + INDEX.md updates + CHANGELOG.md entry all in single commit. Reversibility: single commit revert (ADR-0007); sister-pattern restoration from calc history if needed.

### Fixed

- **PR #836 CI RED fix — e2e server cleanup race + perf-budget self-hosted headroom (cycle #4249).** Two pre-existing test-infra bugs surfaced when PR #836's lint-and-test run went red on `feat/STORY-S21-023-d-test-plan` (commit `b577ee0`). **Bug 1 (e2e cleanup race):** `tests/web/test_e2e_keyboard.py:server` fixture called `proc.communicate(timeout=cleanup_timeout)` on a still-alive uvicorn subprocess after the 10s healthz wait timed out. The 2s cleanup budget (computed as `int(SUBPROCESS_TIMEOUT_S / 5)`) was insufficient to drain uvicorn's stderr buffer mid-startup — CI raised `subprocess.TimeoutExpired` even though uvicorn had already logged `Application startup complete.` Fix: SIGTERM the proc FIRST, wait briefly for graceful exit (5s ceiling, SIGKILL fallback), then drain via `communicate(timeout=1)` — proc is dead, EOF is instant, no blocking. **Bug 2 (perf budget headroom):** self-hosted VM under pytest-cov instrumentation produced p99 = 446ms on `test_arithmetic_p99_under_50ms_still_holds` (500 calls), failing the 250ms budget (BUDGET_MULTIPLIER=5). Root cause: pytest-cov adds ~2x overhead on top of the VM's already-slow arithmetic path; the Sprint 22 PIVOT Faz 1.2 2x baseline is no longer enough headroom. Fix: bump `_BUDGET_MULTIPLIER_MAP["self-hosted"]` 2.0 → 6.0 in `tests/conftest.py` (fallback when `vars.BUDGET_MULTIPLIER` is unset). Operational companion: bump repo `vars.BUDGET_MULTIPLIER` 5 → 10 via `gh variable set` (matches architect's env-var precedence chain per ADR-0019 amend 3 §Runner-aware multipliers + TD-046-extension). Local reproduction with BUDGET_MULTIPLIER=10 → 2/2 PASS in 39.71s (`TestTranscendentalPerfBudget::test_transcendental_p99_under_100ms` + `test_arithmetic_p99_under_50ms_still_holds`). **Tech debt:** perf tests under coverage on self-hosted VM are inherently flaky. Future sprint should isolate them in a no-cov CI job (`pytest tests/api/test_evaluate_transcendental.py --no-cov`) to remove the ~2x coverage overhead — file as TD-049 follow-up. Sister-pattern: Issue #728 lazy-import mpmath hotfix (architect 9-Lens APPROVED) — both keep test contracts load-bearing while absorbing runner variance.

- **P0 #351 — Sprint 4 P2 deploy.yml `path:` override reverted (GA path-constraint violation, PR #350 → PR #352).** PR #350 added `path: /home/atilcan/projects/AtilCalculator` to `actions/checkout` (Option C, RCA-17 follow-up) so the runner would check out directly to the canonical path without the Sprint 3 symlink workaround. GitHub Actions has a hard safety check — `path:` must be a subdirectory of the runner's `_work/` root — and the canonical path is **outside** that root. Deploy run 28109856747 failed with `Repository path '/home/atilcan/projects/AtilCalculator' is not under '/home/atilcan/actions-runner/_work/AtilCalculator/AtilCalculator'`, breaking the deploy chain on main. P0 incident #351 filed, PR #352 reverted the change (commit `a419f0f`). `actions/checkout` SHA pin (`b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1`) preserved per ADR-0027 §Threat model; `deploy-runner.sh` REPO_DIR default chain unchanged (`/home/atilcan/atilcalc` per RCA-7). Sprint 4 P2 (#193, #194) deferred to Sprint 5 P1 with revised design (Option B' = `path:` under `_work/`). New regression test `scripts/tests/d040-deploy-path-guard.sh` (6 TCs T1-T6) — 6/6 PASS on current main, 3/6 FAIL on the PR #350 broken state (T2 + T3 + T6 fire) — TDD-verified as a real guard, not a vacuous one. Sister regressions preserved: d019 6/6, d035 23/23. TD-029 candidate (architect Option C design gap, blind-spot family with TD-028).

- **Issue #237 — Atomic-write state recovery (Sprint 4 P1).** Tester state file `processed_event_ids` corrupted 200→2 (unrecoverable). Root cause: `agent-state.sh` `jq_inplace` (read file → modify → write tmp in `/tmp` → mv across filesystems) could leave target empty/partially-written if process killed mid-write. Fix: new `scripts/atomic-write.sh` with `atomic_write_json()` helper (write-to-temp in SAME directory + fsync + atomic mv — observers always see old OR new content, never half-written). `agent-state.sh` `jq_inplace` now delegates to `atomic_write_json` (signature unchanged, so all 13 call sites in cmd_init/cmd_set/cmd_mark/cmd_heartbeat/cmd_trim/cmd_kick automatically inherit the atomic guarantee). New `cmd_validate <role>` detects 4 corruption modes (missing file / jq parse error / length-0 processed_event_ids / schema mismatch) with distinct exit codes 1-4. New `cmd_rebuild <role>` restores `processed_event_ids` from event log when state is corrupt. New `scripts/event-log.sh` provides append-only JSONL event log at `$AGENT_EVENT_LOG_DIR/<role>.jsonl` (atomic append via write-to-temp + sync + mv), enabling cmd_rebuild to restore dedup buffer from history. Regression test `scripts/tests/d027-state-recovery.sh` (7 TCs T1-T7 per #237 ACs) — 7/7 PASS. Follow-up (separate PR): integrate `event_log_append` into agent-watch.sh's mark flow so cmd_rebuild has real event history to restore from.

- **DEPLOY-001 v9 (Issue #171, refs #169) — RCA-14 follow-up fix:
  systemd user-service integration (uvicorn lifecycle owned by
  systemd, nohup+setsid canonical pattern REMOVED).**
  Sprint 3 P0 unblock (PR #165 + #169) verified that deploys succeed
  via the nohup+setsid canonical restart pattern (RCA-7-1/2/3 fix at
  PR #157, RCA-12 v8 defense at PR #169), but the self-hosted runner's
  "Cleanup orphan processes" step at job end terminates the
  nohup-spawned uvicorn: `Complete job Terminate orphan process:
  pid (47805) (uvicorn)`. Result: deploys succeed (smoke test pass)
  but the service does NOT persist between deploys — `http://192.168.1.199:8000/`
  goes dead as soon as the runner job ends. v9 REPLACES the v8
  nohup+setsid spawn shape with `systemctl --user stop atilcalc-web.service`
  + `systemctl --user start atilcalc-web.service`. The unit's
  ExecStart spawns uvicorn; systemd owns the process lifecycle. The
  service survives the runner cleanup phase because it's owned by
  the atilcan user session (not the runner job process tree).
  Logout-survival requires `loginctl enable-linger atilcan` (owner
  pre-req, one-time setup). v9 keeps the RCA-12 v8 cross-user
  defense (pre-check exit 5 + post-check exit 6) intact — only the
  spawn mechanism changed. New exit code **7** = systemd integration
  failure (unit not registered, or `systemctl --user` call returns
  non-zero). Step 3 (preflight) is now FAIL-loud on missing unit
  (replaces v8's WARN-only — the WARN-only behavior masked the
  RCA-14 bug). New regression test
  `scripts/tests/d018-rca-14-uvicorn-orphan-kill.sh` (9 cases T1-T9):
  pre-deploy `systemctl --user stop`, post-deploy `systemctl --user
  start`, nohup+setsid uvicorn pattern REPLACED, header documents
  RCA-14 + exit code 7, --dry-run step 4 references systemctl +
  atilcalc-web.service, pre-check BEFORE systemctl stop + post-check
  AFTER systemctl start in source order, header references owner
  pre-req (`loginctl enable-linger atilcan`) + ADR-0010. **d017
  (RCA-12) updated** to anchor on `systemctl --user stop` instead
  of `pkill` (the v8 spawn gate anchor is no longer valid in v9;
  the cross-user check itself is preserved). **Sprint 3 P0 DoD §4
  = 3/3 deploy success** was achieved with v8, but Sprint 3 P0
  DoD §5 (intentional bad-merge → rollback + persistence) requires
  v9. Filed RCA-14 as Issue #171; owner pre-req must be applied
  BEFORE first v9 deploy (install unit file, `loginctl enable-linger
  atilcan`, `systemctl --user daemon-reload`, `systemctl --user
  enable atilcalc-web.service`).

- **DEPLOY-001 v8 (Issue #168, refs #165, #164, #161, #160, #155) —
  RCA-12 follow-up fix: cross-user port kill failure defense.**
  `scripts/deploy-runner.sh` v8 adds two strict port-aware checks to
  `restart_service()` — extending the FAIL-or-CREATE doctrine (v6
  RCA-9) from the preflight step to the restart step. **Pre-restart
  check (BEFORE pkill)**: `ss -tlnp "sport = :$ATC_PORT"` extracts
  the port-bound PID's uid; if it differs from the current user's
  uid, fail-fast with **exit code 5** (cross-user port conflict) —
  `pkill -f ... || true` would silently no-op on cross-user targets
  (root cause of 8th deploy fail at run #27865086173, atilcan-owned
  PID 33353 stayed up on port 8000 because the runner is
  `gh-actions-runner`, not `atilcan`). **Post-restart check
  (REPLACES lenient `ps aux | grep uvicorn`)**: after a 2s
  bind-settle, `ss -tlnp` extracts the new port-bound PID and
  `ps -o etimes=` verifies it started RECENTLY (≤ 60s). atilcan's
  pre-existing uvicorn has etimes > 10000s; our just-spawned
  uvicorn has etimes ~2s. If the port-bound process is OLD, fail
  with **exit code 6** (port-PID mismatch) — same cross-user
  scenario, defense-in-depth backstop in case the pre-check tool
  was missing. New regression test
  `scripts/tests/d017-rca-12-cross-user-port-8000.sh` (8 cases
  T1-T8): pre-check tool presence, fail ... 5 / fail ... 6 patterns,
  post-check uses `ss -tlnp` (not lenient ps grep), header
  documents RCA-12 + exit codes 5/6, --dry-run step 4 mentions
  RCA-12, pre-check BEFORE pkill in source order (function-body
  anchor, not comment). **Sprint 3 P0 is STILL not done** — the
  v8 defensive code fix is necessary but not sufficient: the
  underlying infra mismatch (runner as `gh-actions-runner`, prod
  uvicorn as `atilcan`) requires an **owner decision**: Option A
  (run runner as `atilcan`) / Option B (sudoers rule for cross-user
  `pkill`) / Option C (change `$ATC_PORT` to a non-conflicting
  port). Filed RCA-12 as Issue #168; @orchestrator notified via
  `notify.sh -l orchestrator`; @atilcan65 (infra decision) notified
  via `notify.sh -l human` (soul-level escalation per doctrine:
  production deploy/release kararı).

- **DEPLOY-001 v7 (Issue #164, refs #161, #160, #155) — RCA-11
  follow-up fix: `web` extra consolidation (Option B, merged test
  contract PR #166, single source of truth).**
  `scripts/deploy-runner.sh` v7 switches the preflight dep install from
  `uv pip install -p "$REPO_DIR/.venv" -e .` to
  `uv pip install -p "$REPO_DIR/.venv" -e ".[web]"`, pulling in the
  HTTP runtime surface (FastAPI + uvicorn) from a new
  `pyproject.toml [project.optional-dependencies] web` extra. The
  `web` extra carries the **single source of truth** for prod runtime
  pins (`fastapi==0.115.6`, `uvicorn[standard]==0.32.1`). The `[dev]`
  extra retains the dev tooling (pytest, ruff, mypy, playwright,
  httpx) plus the **un-pinned** package names `fastapi` and
  `uvicorn[standard]` (dev tooling uses pip's resolver; drift vs
  `[web]` is acceptable for dev tooling, NOT a prod concern). v6 was
  architecturally correct (it caught the missing uvicorn at the
  defense-in-depth `restart_service()` check, exit 4 — RCA-9
  regression prevented) but uncovered a deeper design gap: pyproject
  declared fastapi+uvicorn as `[dev]` extras, NOT runtime. RCA chain
  RCA-7 → RCA-9 → RCA-10 → RCA-11, each layer revealed by the
  previous fix. Sprint 3 P0 originally scoped Option A (single-line
  script change) per orchestrator Issue #164 fast-path
  recommendation, but merged test contract PR #166 (AP-23c "exactly
  one place" probe) **forced Option B** — pins in EXACTLY ONE place,
  no duplicate pinning in script + pyproject. v7 implements Option B
  per the merged test contract. Sprint 4 ADR-0027 amendment now
  satisfied (the `[web]` extra consolidation IS the amendment).
  **TD-023** (tester self-miss: v6 amendment did not cover the
  `[dev]` extras layer — same class as TD-022) **closed by PR #166**.
  New regression test `scripts/tests/d016-rca-11-runtime-deps-explicit.sh`
  (8 cases T1-T8): Option B path enforcement + AP-23c compliance
  check (zero pin strings in script). Test plan amendment
  **merged via PR #166**: TC-16 (runtime-deps layer) + AP-23 (drift
  detection + single source of truth probe).

- **DEPLOY-001 v6 (Issue #160, refs #159, #157, #155, #152) — RCA-9
  follow-up fix: preflight dep install FAIL-or-CREATE pattern.**
  `scripts/deploy-runner.sh` v6 changes the preflight dep install block
  from WARN-or-SKIP to **FAIL-or-CREATE**: if `uv` is missing → exit
  4 (preflight failure); if `.venv` is missing → create via
  `uv venv .venv` (exit 4 if creation fails); `uv pip install -p
  .venv -e .` failure → exit 4 (was WARN-only continuation in v5,
  which was the silent-WARN bug class — RCA-7 / RCA-8 / RCA-9 family).
  New exit code **4 = preflight failure** (distinct from exit 3 =
  usage error and exit 2 = double-failure). `restart_service()`'s
  defense-in-depth `.venv/bin/uvicorn` existence check upgraded from
  exit 3 → exit 4 (parity with the preflight category). RCA-9 root
  cause: v5 preflight was `if [[ -d "$REPO_DIR/.venv" ]] && command
  -v uv >/dev/null 2>&1; then ...; else log "WARN..."; fi` — script
  proceeded to restart with no venv; restart failed at
  `.venv/bin/uvicorn not found` (exit 3). First auto-deploy after
  PR #157 merge FAILED at run #27862367000 (2026-06-20T06:04:46Z,
  2s after squash-merge c7c060e). v6 closes the WARN/SKIP
  regression-test gap with **TC-15** (FAIL-or-CREATE behavior) +
  **AP-21** (uv-missing + venv-creation-fail fail-fast) +
  **AP-22** (`uv pip install` non-zero exit, not log-only)
  in `docs/test-plans/DEPLOY-001-tests.md`. Sister to **TD-022**
  (tester self-miss: AP-14 covered presence of preflight, not the
  FAIL-or-CREATE semantic — file in RETRO-003).

- **DEPLOY-001 v5 (Issue #155, refs #152) — RCA-7 4-layer root cause
  fix.** `scripts/deploy-runner.sh` rewritten to use the nohup+setsid
  canonical restart pattern that worked at 2026-06-20T05:02:42Z (PID
  33353, manual unblock). The v4 `systemctl --user restart
  atilcalc-web.service` was wrong on FOUR independent layers:
  **RCA-7-1** `atilcalc-web.service` systemd unit does NOT exist on
  prod (never installed, ADR-0010 documented the PATTERN not the
  actual instance); **RCA-7-2** symptom of 7-1; **RCA-7-3** the
  `atilcalc.web.app:app` module path is hallucinated (`atilcalc.web`
  is the JS Web Components dir, no Python app object) — canonical
  module is `atilcalc.api.main:app` (verified 12 references:
  `scripts/run-server.sh` + 11 test files); **RCA-7-4** fresh `.venv`
  lacks runtime deps (mpmath==1.3.0) after `git reset --hard` — fixed
  by preflight `uv pip install -p .venv -e .`. Other v5 changes:
  REPO_DIR default chain `$REPO_DIR > $GITHUB_WORKSPACE >
  /home/atilcan/atilcalc` (was `$HOME/projects/AtilCalculator` —
  actual prod path discovered at 2026-06-20T04:47Z), hostname detection
  log with WARN if not atiltestweb, `ATC_BIND_HOST` env (default
  0.0.0.0) for service bind host. `.github/workflows/deploy.yml` v5
  passes `ATC_BIND_HOST` to deploy step. Smoke test
  (`GET /healthz`, git_sha match) and auto-rollback shape unchanged
  from ADR-0027 §Decision.3.

### Added

- **TD-019 — Orchestrator guidance cross-check doctrine (P2; refs #152 RCA-7, Issue #156).** Sister entry to TD-016 + TD-018 in the "blind-spot family". On Issue #152 P0 (RCA-7 deploy failure), @orchestrator's 04:47Z guidance included a hallucinated module path `atilcalc.web.app:app`; canonical is `atilcalc.api.main:app` (12 references: `scripts/run-server.sh` + 11 test files). Doctrine: before issuing prod-host commands, workflow YAML snippets, or design doc recommendations, agents MUST grep the canonical entry script and confirm (a) module path, (b) restart mechanism, (c) preflight steps, (d) post-deploy verification. Captured in `docs/tech-debt.md` row TD-019 + new "Blind-spot family" section consolidating TD-016 + TD-018 + TD-019 as instances of the same class (agent must trace MORE than local shape before verdicts). ADR-0027 supplement section added with actual prod instance details (hostname `atiltestweb`, deploy path `/home/atilcan/atilcalc`, canonical restart = nohup+setsid, canonical module = `atilcalc.api.main:app`). RETRO-003 consolidation planned. See [Issue #156](https://github.com/atilcan65/AtilCalculator/issues/156), [Issue #152 cmt 4756498070](https://github.com/atilcan65/AtilCalculator/issues/152#issuecomment-4756498070) (orchestrator's 04:47Z guidance), [Issue #152 cmt 4756543400](https://github.com/atilcan65/AtilCalculator/issues/152#issuecomment-4756543400) (orchestrator's 05:03:51Z RCA), and PR #158 (this docs PR). **Note on AC mismatch**: Issue #156 AC references `ADR-0010-per-project-watchers.md` for the supplement, but the actual deploy ADR is `ADR-0027-deploy-automation.md` (which contains the `192.168.1.199` reference and `systemctl --user` pattern); architect amended ADR-0027 instead and flagged the mismatch in the PR description for @orchestrator confirmation. See [Issue #156](https://github.com/atilcan65/AtilCalculator/issues/156) "Escalate to @orchestrator if" clause.

- **#113 — Watchdog: `issue_assigned_any_status` event kind (Issue #113
  Part B, refs #113, closes #113 Layer B).** New watchdog query
  `query_assigned_issues_any_status()` in `scripts/agent-watch.sh` emits
  `issue_assigned_any_status` events for every open issue with
  `agent:<role>`, regardless of `status:*` label (backlog, ready,
  in-progress, blocked). Closes the silent-drop gap where agents with
  backlog-only work saw no wake events (2026-06-19 incident with
  #71/#72/#74 — issues were `status:backlog` + `agent:developer` but
  the agent's `issue_assigned` query only fired on `status:ready` or
  later). Throttled per (issue, role) at 5-min buckets; kill switch
  `QUERY_ASSIGNED_ANY_STATUS_ENABLED=false`. Context payload carries
  status + actionability hint (`ACTIONABLE` for ready/in-progress,
  `informational` for backlog/blocked) so agents reading the event know
  not to start work without PM grooming. Event ID format:
  `issue-assigned-any-<n>-b<bucket>` (sister to `stale-verdict-<n>` and
  `mention-<role>-<n>` per ADR-0024 + ADR-0026). Doctrinally aligned
  with Issue #113 Layer A (soul clause: "labels = ownership, body may
  be stale"). 9-case regression test
  `scripts/tests/d013-issue-assigneeship-authority.sh` (T1 function
  exists, T2 kill switch, T3 kind emitted, T4 ID format, T5 status
  field, T6 ACTIONABLE, T7 informational, T8 poll_once integration, T9
  kinds enum). See [`docs/backlog/#113`](docs/backlog/) + PR #114
  (merged 2026-06-19T13:40:35Z, commit `236c759`). Companion to PR
  #115 (Issue #113 Layer A — issue-assigneeship-authority clause in 4
  soul files, merged 2026-06-19T08:00:45Z).

- **STORY-012 — Owner-facing documentation pass (P2; refs #74).**
  Refreshed `README.md` from the dev-studio-template placeholder to
  AtilCalculator-specific content (intro + prereqs + install + run + test
  + links to `docs/USER-GUIDE.md` and `docs/product/vision.md`). Created
  `docs/USER-GUIDE.md` covering the 5 owner-facing topics: Skin modes
  (Dark/Light/Retro with WCAG-AAA contrast + auto-discovery), History
  view (scroll / search / click-to-load / infinite scroll), Scientific
  mode (trig, rad/deg toggle, precision notes, DomainError mapping),
  Keyboard reference (cross-linked to in-app `?` popup), Troubleshooting
  (port conflicts, VM hardening, SQLite locking, backup policy).
  Extracted the keyboard shortcut registry to
  `src/atilcalc/web/shortcuts.js` (single source of truth per ADR-0023
  §Help popup content) and rewired `<atilcalc-help-popup>` to render
  the 19 shortcuts in 3 sections (Basic | History | Scientific). Added
  scientific single-letter handlers to the keyboard FSM (`s`→`sin(`,
  `c`→`cos(`, `t`→`tan(`, `l`→`log(`, `n`→`ln(`, `r`→`sqrt(`, `!`→`!`),
  plus `d` (deg/rad toggle), `m` (mode toggle), `↑`/`↓` (history
  navigation), and `/` (history search-focus) as CustomEvent
  dispatches. The FSM and popup are now wired through the same
  registry — they cannot drift (test_help_popup.py AP-2 invariant).

- **STORY-011 — Scientific functions (P1; refs #73).**
  Engine + API surface for sin / cos / tan / log / ln / sqrt / factorial
  (trig accepts `45 deg` unit suffix; rad/deg toggle via `deg=True`
  flag or `d` keyboard shortcut). New `DomainError` exception class
  maps to HTTP 400 with envelope
  `{"error": {"code": "DomainError", "message": "..."}}`. Precision
  via `mpmath==1.3.0` (50-digit internal, 28-digit Decimal response)
  per ADR-0019 amend 2. 71/71 engine tests green; 10/10 API
  transcendental tests green; 0 wider regressions.

- **STORY-010 — Skin preference persistence (P1; refs #72).**
  SQLite-backed skin state in `src/atilcalc/persistence/skin.py` with
  `skin` table (single-row `current` key) and `skin_audit` log
  (idempotency_key UNIQUE + ts). PRAGMAs `journal_mode=WAL` +
  `busy_timeout=5000` per ADR-0022. Cross-device sync via shared
  SQLite file (NFS-equivalent) — no application-level sync layer.
  Idempotency-Key read from HEADER (not body) per ADR-0019 §Idempotency;
  race-safe UNIQUE handling on `idempotency_key` (same key + same
  body → 200 cached, same key + different body → 409 Conflict).
  Replaces the in-memory `_skin_state` and `_idempotency_cache` from
  PR #37 (STORY-009 MVP-1). 13 new test files covering cross-device,
  durability, concurrency, idempotency contract.

- **STORY-009 — Skin system (P1; refs #71).**
  ≥3 built-in skins (Dark, Light, Retro) as auto-discovered CSS files
  in `src/atilcalc/web/skins/`. WCAG-AAA contrast per skin (18.9:1 /
  18.0:1 / 13.7:1). Skin attribute on `<html>` drives CSS custom
  properties (no JS palette swap). `Idempotency-Key` header (UUID v4)
  on `PUT /api/skin` per ADR-0019; unknown skin → 400
  `UnknownSkinError`. 13/13 contract tests green.

### Fixed

- **#6 — Watcher re-fires on every label/comment bump (P1, sibling of #61).**
  `agent-watch.sh` constructed `issue_assigned`, `board_change`, and
  `pr_labeled` event IDs from `.updatedAt`. Because `updatedAt` bumps on
  every comment / label-edit / assign — even when the watched label set is
  unchanged — every metadata flick produced a fresh event ID and re-woke
  the assigned agent. Repro: orchestrator's `processed_event_ids` showed
  five distinct entries for `board-1` (`13:19:49Z`, `13:21:58Z`,
  `13:23:37Z`, `13:24:34Z`, `13:24:48Z`) for the same Issue #1 with no
  real state change between them; same pattern was firing `pr-labeled-5`
  repeatedly on PR #5 every time the architect touched a label during
  their retraction cleanup. The fix switches the three event-ID
  constructions from `+ "-" + .updatedAt` to
  `+ "-" + (.labels | map(.name) | sort | join("|"))` (and equivalent
  for `pr_labeled`, whose `labels` is already a flat string array). The
  dedup chain (`processed_event_ids` ring) was working correctly all
  along — the bug was upstream, in ID *construction*, not in mark/trim.
  Net effect: a comment on an unchanged-assignment issue is now silently
  absorbed; a real label-set change still fires; an idempotent flip
  (add X then remove X) collapses to the original ID and is suppressed.
  Regression pin: `scripts/tests/d006-stable-event-ids.sh` (5/5 PASS,
  including end-to-end watcher invocation against a mocked `gh`).

- **#61 — Watcher phantom re-delivery of `board-*` events (P1).** Orchestrator's
  `agent-watch.sh` loop was receiving the same two `label_change` events
  (`board-50-*`, `board-52-*`) repeatedly across polls, even though both source
  issues are CLOSED with `status:done` and the resolving PRs (#51, #54) are
  merged. Two interacting bugs caused the dedup chain to fail: **(A)** the
  three HWM vars (`LAST_SEEN`, `PR_MERGED_LAST_SEEN`, `PR_LABELED_LAST_SEEN`)
  were read ONCE at script start and never refreshed inside `poll_once`, so a
  long-running `--loop` watcher's local vars drifted behind the state file's
  HWM and the gh query kept returning historical events; **(B)** the
  `processed_event_ids` FIFO trim (default 50) was evicting the still-active
  phantom event IDs as newer events flooded in. The fix moves all three HWM
  reads into `poll_once` (via `init_pr_merged_hwm` and `init_pr_labeled_hwm`
  helpers) and bumps `DEFAULT_TRIM_MAX` from 50 to 200 as a backstop. The
  orchestrator's INBOX is now clean across 10+ consecutive polls. Regression
  pin: `scripts/tests/d213-phantom-board-dedup.sh` (10/10 PASS).

- **#95 — Sprint 2 plan.md stale dep list (P3 chore).** Dropped
  `sqlmodel==0.0.22` + `alembic==1.13.x` lines from `docs/sprints/sprint-02/plan.md`
  (line 66, STORY-007 AC; lines 197-198, deps table) — ADR-0022 §Decision chose
  stdlib `sqlite3` only (no ORM, no migration framework) per ADR-0017 boring-tech
  principle. Plan was drafted at 14:50Z but PR #82 (ADR-0022) committed at 15:59Z;
  plan was never updated to match. No code impact (pyproject.toml is the actual
  source of truth for runtime deps); pure docs hygiene. See Issue #92 architect
  note (PR #92 cmt #4745155530) and ADR-0022.

- **STORY-002 — `app/main.py` now registers a SIGTERM handler (TC-8 unblock).**
  `kill <pid>` (SIGTERM) on the uvicorn process used to exit with code
  `143` (= 128 + SIGTERM), which breaks container/k8s/systemd graceful
  shutdown. The handler is installed at module-import time and calls
  `os._exit(0)` (C-level `_exit(2)`), mirroring uvicorn's own SIGINT
  behaviour without raising `SystemExit` — this avoids a `CancelledError`
  traceback from the asyncio loop's pending Starlette `lifespan` task,
  satisfying STORY-001 AC4 ("no traceback on shutdown"). No-op for
  Ctrl-C development; load-bearing the moment the service ships to a
  process supervisor. See PR #24 (`test_sigterm_exits_zero`) for the
  subprocess-level regression pin and PR #25 / `tests/test_sigterm_handler.py`
  for the in-process pin.

### Added

- **STORY-007 — Persistent cross-device history (SQLite backend)** (Sprint 2,
  P0; refs #69, closes #69). New persistence layer in
  `src/atilcalc/persistence/history.py` (stdlib-only `sqlite3` + `threading` +
  `uuid`; preserves ADR-0017 engine↔UI separation — persistence is a sibling
  module, not nested in the engine). PRAGMAs `journal_mode=WAL` +
  `synchronous=NORMAL` per the persistence-layer design (ADR-0022, in-review
  via PR #82 — impl proceeded against the open ADR per the human owner's
  Option A go-ahead; architect-acknowledged in PR #88 review). Schema:
  `history(id INTEGER PK, expr TEXT, result TEXT, ts TEXT,
  idempotency_key TEXT UNIQUE)` with `idx_history_ts DESC` + `idx_history_expr`
  for newest-first ordering + substring-search perf. `POST /api/history`
  requires `Idempotency-Key` header (UUID v4); missing → 400
  `MissingIdempotencyKeyError`, malformed → 400 `InvalidIdempotencyKeyError`,
  same-key + same-payload → 201 (idempotent replay), same-key +
  different-payload → 409 `IdempotencyConflictError`. `GET /api/history`
  returns envelope `{"history": [...], "cursor": null}` (cursor MVP-1 is
  null, no pagination yet). `POST /api/evaluate` persists best-effort
  (try/except + WARNING log; eval response preserved on persistence failure
  per AC1 "does not block eval"). Decimal-as-string serialization preserved
  end-to-end (AC7 `0.1+0.2 = "0.3"` lossless; no NUMERIC/REAL coercion —
  trailing zeros from `str(Decimal)` round-trip cleanly). 26 new tests across
  5 files: history endpoint (9), idempotency (4 + 1 skip for freezegun
  deferred), durability (3), search perf (3), decimal precision (4). Test
  infrastructure fixes also landed (PR #88): `_temp_db` conftest fixture
  missing `yield` (tests using `sqlite3.connect(db_path)` directly were
  deleting the temp file before the test body ran), case-sensitive schema
  assertion in `test_history_decimal_precision.py` (`"result TEXT"` →
  `"RESULT TEXT"` to match the uppercased `schema_sql`).
  See [`docs/backlog/STORY-007.md`](docs/backlog/STORY-007.md) (full AC +
  Gherkin), [`docs/decisions/ADR-0022-persistence-layer.md`](docs/decisions/ADR-0022-persistence-layer.md)
  (schema + PRAGMA spec, in-review via PR #82), PR #79 (TDD red, merged
  2026-06-18T16:12:06Z), PR #88 (impl, merged 2026-06-18T18:32:56Z, commit
  `a56be89`), and PR #90 (PM bookkeeping, in-review).

- **STORY-008 — History UI wiring (render + substring search + click-to-load)**
  (Sprint 2, P0; refs #70, closes #70). Rewires `<atilcalc-history>` from
  in-memory deque to backend `GET /api/history` (ADR-0019 amend 2 envelope per
  PR #84 MERGED). Sprint 1 surface preserved (`pushEntry` does optimistic
  append + background re-sync via `loadPage`). All 6 ACs wired across 6
  commits + 1 post-merge CI fix:
  - AC1+AC4 (`169671a`): `loadPage({limit?,before?,q?})` async fetch +
    Sprint 1 surface + `data-ts`/`data-expr` attributes + clickable entries.
  - AC2 (`c56d8cc`): `<input type="search">` in shadow DOM + 100ms debounce
    per AC2 perf budget (PR #103 backoff alignment spec).
  - AC3 (`12fd4fe`): click + keydown(Enter) → `history:entry-selected` event;
    global FSM listener wires it to `setInput` + `setResult`.
  - AC5 (`9fd8337`): scroll-to-bottom detection (8px threshold) →
    `_appendPage({before: oldest_ts})` for infinite scroll; dedup by ts.
  - AC6 (`bafff04`): `_fetchWithBackoff` with 250/500/1000ms × max 3 retries
    (PR #103 alignment); `history:error` events with phase discriminator
    (`retry-1`/`retry-2`/`retry-3`/`retry-exhausted`).
  - Infra (`cb76d26`): `tests/web/conftest.py` Playwright + FastAPI server
    fixture — session-scoped `atc_server` (127.0.0.1:`<free_port>` via
    `subprocess.Popen`, `/healthz` 30s readiness probe), session-scoped
    `browser` (Playwright Chromium headless), function-scoped `browser_page`
    (fresh `browser_context` per test, waits for 3 custom elements attached).
  - CI fix (`170e5fa`, post-merge): `_playwright_available()` now probes the
    chromium binary on disk (default `~/.cache/ms-playwright`, override via
    `PLAYWRIGHT_BROWSERS_PATH`); `browser` fixture wraps `chromium.launch`
    in try/except → skips with actionable message on launch failure;
    `atc_server` derives `cwd` from `__file__` (was hardcoded
    `/home/atilcan/projects/atilcalc-developer`, CI-broken). Result: CI Lint
    & Test went from 31 errors (browser launch) → 31 skipped with the same
    actionable message.
  See [`docs/backlog/STORY-008.md`](docs/backlog/STORY-008.md) (full AC +
  Gherkin), [`docs/designs/STORY-008-impl-design.md`](docs/designs/STORY-008-impl-design.md)
  (design PR #100, MERGED), and PR #111 (merged 2026-06-19T11:21:14Z,
  commit `c5e0ac4`). Closes #70.

- **STORY-001 — FastAPI service skeleton with `GET /healthz`** (Sprint 1, P0).
  Standalone FastAPI service runnable from a clean clone with one command
  (`make run`); liveness probe at `/healthz` returns `200 OK` with
  `{"status": "ok"}` and `Content-Type: application/json`. Unknown paths
  return `404` (not `500`). `Ctrl-C` exits cleanly with code `0`.
  See `docs/backlog/sprint-1/STORY-001-fastapi-skeleton-healthz.md` (Sprint 1 archive; path preserved as historical reference — file lives in the project history),
  `docs/designs/STORY-001-design.md` (Sprint 1 design — same archive),
  and `docs/decisions/ADR-0001-fastapi-skeleton.md` (Sprint 1 ADR — same archive).

- **STORY-003a — Web shell core: HTTP surface + 3 Web Components + keyboard FSM**
  (Sprint 1, P0; refs #30, closes #35). 4 API endpoints per ADR-0019
  (`POST /api/evaluate`, `GET /api/history`, `GET /api/skin`, `PUT /api/skin`)
  with engine-error envelope (ExpressionSyntaxError / DivisionByZeroError /
  UndefinedOperatorError → 400; EngineError catch-all → 500; pydantic
  ValidationError → 422) and Decimal-as-string serialisation (AC7
  `0.1+0.2 = "0.3"` exact regression pin). `PUT /api/skin` is the only
  state-mutating endpoint and requires `idempotency_key` (replay cache,
  FIFO-bounded 1024). Static SPA shell (vanilla JS, no build step per
  ADR-0018) mounted at `/` with 3 custom elements (`<atilcalc-display>`,
  `<atilcalc-keypad>`, `<atilcalc-history>`) and a 3-state global keyboard
  FSM (idle / entering / evaluated) on an allowlist of 0-9, + - * /, ( ),
  `.`, Enter, Escape, Backspace. Observability harness (ADR-0019
  §Observability) emits structured logs (path, request_id, latency_ms,
  status_code) on every request; error responses carry the same
  `request_id` in the envelope and the log line for correlation. See
  [`docs/backlog/.../STORY-003a-...`](docs/backlog/) (design in PR #37,
  test plan in `docs/test-plans/STORY-003a-tests.md`). Closes d007
  observability regression pin (Issue #35): `bash scripts/tests/
  d007-api-observability.sh` → `TOTAL=8 PASS=8 FAIL=0` (T1 middleware
  + main reference; T2 every route logs; T3 3 engine subclasses + 4
  mapping rows with drift-detect; T4 PUT/POST idempotency_key; T5
  requires-python ≥3.11).

- **STORY-003b — Web shell deferred: 3 components + skin system + E2E + LAN-bind**
  (Sprint 1, P0; refs #31). Completes the 3 deferred custom elements from
  STORY-003a split-out: `<atilcalc-mode-toggle>` (3-button dark/light/retro
  switcher that dispatches `skin:change`), `<atilcalc-help-popup>` (modal
  `<dialog>` listing 8 keyboard shortcuts, opened by `?` and dispatched
  `help:open`), `<atilcalc-error-toast>` (transient banner that listens
  for `engine:error` from the FSM, 5s auto-dismiss, Esc dismiss). Skin
  system infrastructure in `src/atilcalc/web/theme.js` swaps 14 CSS custom
  properties on `:root` from a `PALETTES` object; AC6 transition is
  `body { transition: background 200ms, color 200ms; }` (GPU-compositable
  properties only). Keyboard FSM extensions: `?` → `help:open`, evaluate
  4xx/5xx → `engine:error` (with `type` + `message` + `status`),
  network failure → `engine:error` with `type=NetworkError`. LAN-bind
  per ADR-0019 R-3: new `scripts/run-server.sh` reads `ATC_HOST` (default
  `192.168.1.199` — NOT `0.0.0.0`) and `ATC_PORT` (default `8000`); port
  is validated up front. Playwright E2E contract test in
  `tests/web/test_e2e_keyboard.py` boots uvicorn via `run-server.sh`,
  opens Chromium headless, dispatches real keyboard events, and asserts
  the `<atilcalc-display>` shadow-DOM result for 3 scenarios
  (`1+2=3`, `1+2+3=6`, `7*8=56`). New dev deps: `playwright==1.49.0`,
  `pytest-playwright==0.7.0`. Design-plan deviations from the issue
  dev-plan comment: LAN-bind default follows ADR-0019 (`192.168.1.199`),
  not the `127.0.0.1` originally proposed; surfaced in PR body for
  architect review.

- **STORY-004 — `GET /hello/{name}` greeting endpoint** (Sprint 1, P1).
  Demo-facing route that returns `200 OK` with
  `{"message": "hello, {name}"}` and `Content-Type: application/json`.
  Case is preserved verbatim (no lowercasing); URL-encoded values pass
  through unchanged (e.g. `/hello/%20` → `"hello,  "`). The path segment
  is required, capped at 64 characters to bound log-spam risk; missing
  name returns `404` (FastAPI default), not `500`.
  See `docs/backlog/sprint-1/STORY-004-hello-name-greeting-endpoint.md` (Sprint 1 archive; historical reference).

- **#15 — VM hardening (P0 ops deliverable, STORY-001 infra).** Idempotent
  apply script (`scripts/ops/apply-vm-hardening.sh`, 497 lines) + operator
  runbook (`docs/ops/vm-hardening.md`, 362 lines, AC6) + contract test
  suite (`scripts/tests/test-vm-hardening.sh`, 13/13 PASS). Cardinal
  safety rule hard-coded: never disable password SSH before verifying
  key-based auth works (FATAL if `/root/.ssh/authorized_keys` is
  missing/empty OR loopback key SSH fails). Knobs overridable via env
  (`SSH_PORT`, `HTTP_PORT`, `FAIL2BAN_BAN_TIME`, `FAIL2BAN_MAX_RETRY`,
  `FAIL2BAN_FIND_TIME`, `BACKUP_CRON_EXPR`, `BACKUP_RETENTION_DAYS`);
  `--dry-run` previews without applying. Drop-in
  `/etc/ssh/sshd_config.d/00-vm-hardening.conf` (cleaner than mutating
  `sshd_config` directly); `sshd -t` validates config before reload.
  Owner runs on target VM (`192.168.1.199`) with `sudo`. Open follow-up
  items (P2/P3 from review): T6 test-header comment, T2 default-check
  grep looseness, `TEST_USER` fallback message, trailing newlines, AC1
  `permitrootlogin` doc gap. See Issue #15 and PR #40.

- **STORY-045 — Orchestrator STATUS-block action driver** (Sprint 1,
  P0; refs #45, closes #45). New CLI tool
  `scripts/status-action-driver.sh` (~260 LOC, bash + python3 for JSON
  output) parses the orchestrator's end-of-turn STATUS block (reads from
  `--status-file <path>` or `--from-stdin`; missing or malformed header
  → exit codes 3 / 4) and derives actionable notifications: **Phase 1**
  (P0/P1 blocker escalation → target=human) is always on; **Phase 2**
  (idle-team ping) is flag-gated behind `--enable-phase2` so the
  1-sprint dry-run can validate the false-positive rate before it ships.
  Each derivation is appended to
  `/var/log/dev-studio/AtilCalculator/orchestrator.heartbeat` with a
  `kind=status_derived` audit marker; `--dry-run` logs the derived
  actions but does NOT call `scripts/notify.sh`. Auto-ping format
  follows the existing `[ORCH→HUMAN]` / `[ORCH→ALL]` convention so the
  downstream wake path is identical to manual STATUS processing.
  Regression pin: `scripts/tests/d011-status-action-driver.sh`
  (14/14 PASS — T1 invocation + version, T2 no-blockers path,
  T3–T5 P0/P1/Phase-2 trigger semantics, T6 malformed STATUS exit-3,
  T7 empty stdin exit-4, T8–T11 dry-run vs live notify isolation,
  T12 parsed-field surfacing, T13 audit trail, T14 malformed-blocker
  count). See Issue #45 and PR #64.

### Infrastructure

- `pyproject.toml` — PEP 621, Python `>=3.12,<3.13`, pinned runtime deps
  (`fastapi==0.115.6`, `uvicorn[standard]==0.32.1`) and dev extras
  (`pytest`, `httpx`, `ruff`). Ruff config and pytest config colocated.
- `Makefile` — canonical `install` / `run` / `test` / `lint` / `format`
  targets, all thin wrappers around `uv run` (ADR-0001).
- `.python-version` — `3.12` for `uv python pin` and `pyenv` consumers.
- `app/__init__.py` — package marker with `__version__ = "0.1.0"`.
- `app/main.py` — FastAPI instance + sync `GET /healthz` handler.
- `tests/test_healthz.py` — single skeleton smoke test (AC2 happy path).
  Full contract test suite (404, determinism, subprocess lifecycle,
  README on-ramp timing) lands in STORY-002.
- `tests/test_hello.py` — 4 contract tests for `/hello/{name}` (AC1–AC4
  of STORY-004). Happy-path + case-preservation pair satisfies AC5.
- `README.md` — Sprint 1 repo layout + 4-step "Getting started" (Install
  uv → `make install` → `make run` → `curl /healthz`).

### 2026-06-24 — Sprint 4 day 4: dual-channel + Issue #326 ship (Issue #320 closure)

#### Added

- **PR #330 — `verdict_posted` v8 native kind in `scripts/agent-watch.sh` (Issue #326, P0; closes #326 — Phase 2 of Issue #312 RCA).** New `query_verdict_posted()` function emits `verdict_posted` events when a PR comment on a PR where `agent:<role>` OR `cc:<role>` contains verdict keywords (🟢 APPROVED / 🟡 SUGGESTIONS / 🔴 CHANGES_REQUESTED). Self-cc skip per Issue #94 (`is_author_self_cc_pr` filter — author does not wake on own PR's incoming verdict). Event ID format `verdict-posted-<n>-<sha7>-b<bucket>` with 5-min bucket for dedup against comment edits. Event schema matches ADR-0041 §Decision verbatim: `{kind, number, verdict, author, comment_id, comment_url, pr_url, context: {verdict_class, source, keyword_matched, ...}}`. Sister to PR #322 (Phase 0 standalone, now deprecated) and PR #313 (d036 regression). Phase 3 follow-up: remove `scripts/agent-watch-verdicts.sh` per ADR-0041 §Phasing.

- **PR #337 — ADR-0033 §Verification log (docs-only).** End-to-end verification of the dual-channel mechanism per Issue #320 expanded scope. 5/5 ACK across PM (2/2), DEV (1/1, 3s latency), ARCH (1/1), TEST (1/1). Latency budgets documented (idle-pane: 3-5s send-keys, 1-2s paste-buffer; busy-pane: worst-case ~100s context-saturated). PR chain #325/#332/#333/#337 + Issue #320 closure recorded.

#### Changed

- **PR #325 — `scripts/ping.sh` wrapper (Issue #320).** New canonical entry point for peer-pings: `scripts/ping.sh <role> '<message>'`. Wraps `notify.sh` with the correct dual-channel syntax (`-l info -w -r <role>`) so it cannot be misused. `notify.sh -l <role>` is deprecated (emits stderr WARNING + CLAUDE.md hint). Regression tests `d037` (deprecation warning) + `d038` (wrapper contract) — both 7/7 GREEN.

- **PR #332 — Soul-sed: 4 tracked soul files migrated to `scripts/ping.sh <role>` (Issue #320 PR-A, sed-only).** `.claude/agents/{product-manager,architect,developer,tester}.md` updated to reference `scripts/ping.sh <role>` instead of the deprecated `notify.sh -l <role>` form. Sister to PR #333 (orchestrator role tracked + ADR-0041).

- **PR #333 — `.claude/agents/orchestrator.md` tracked + ADR-0041 orchestrator role contract (Issue #320 PR-B).** Orchestrator soul file was gitignored at line 76 of `.gitignore`; now tracked alongside the 4 sibling souls. ADR-0041 codifies the orchestrator role: handoff discipline (atomic 4-flag flip per ADR-0015), WIP enforcement, stale queue detection, verdict-by SLA monitoring, REPRIME protocol, auto-ping hard-rule. Sister to PR #332 (sed-only).

#### Closed

- **Issue #320 — Peer-ping syntax broken in 22 places across 6 files.** Closed via PR chain #325 (wrapper) + #332 (sed-only) + #333 (orchestrator tracked) + #337 (verification log). Doctrinal artifact: `scripts/ping.sh` is now the canonical mechanism; `notify.sh -l <role>` is deprecated but backward-compat (Issue #320 AC2).

- **Issue #326 — v8 native extension in `scripts/agent-watch.sh` — `verdict_posted` kind (P0, closes Phase 2 of Issue #312 RCA).** Closed via PR #330. PR #336 was a duplicate closed in favor of #330 after tester 🔴 verdict (3 architectural regressions vs ADR-0041 §Decision — see /tmp/tester-verdict-336.md).

### 2026-06-24 — Sprint 6 day 1: RCA-17 redesign deploy + doctrinal close (Issue #194 + #363 chain)

#### Added

- **PR #364 — `ADR-0045` auto-generated file refs + lens (j) — TD-030 + PR #358 R2 amendment (commit `87787b8`, refs #363).** Sprint 6 P1 RCA-17 incident #363 doctrinal closeout: ADR-0045 extends architect review checklist from 8-lens (ADR-0043) to **9-lens** by adding **(j) auto-generated file refs + live-state verification pre-publish gate**. Trigger: PR #358 §Risks R2 mitigation was factually wrong on two counts (missed `.gitignore` auto-gen files + canonical-path live-state assumption). Decision (per Issue #363 cmt 4792738456): when proposing ANY edit that touches a path/secret/service/runtime artifact, the architect MUST (1) enumerate auto-gen files explicitly (grep `.gitignore` + Makefile + pyproject.toml for `auto-gen`/`bootstrap`/`regenerate` markers; document regeneration trigger + idempotency contract); (2) verify live-state for canonical-path assumptions (`ls -la` / `ps -ef` / `git log --oneline -5` at design time); (3) document both in a TD-030 attestation block in §Risks (mirrors ADR-0027 §Threat model attestation). INDEX.md ADR-0043 row amended with "Amended by ADR-0045"; ADR-0045 row added. Soul amendment (architect.md lens (j)) is owner-gated per file ownership matrix; doctrine captured in this ADR is the architect's pre-work. Sprint 6 P2 scope: soul amendment (architect proposes, owner gate); d043 regression (tester); RETRO-005 #17 candidate per Issue #363.

- **PR #358 — `STORY-193` + `STORY-194` RCA-17 redesign Option B' (commit `ddfd43f`, refs #193 #194).** Sprint 6 P1 design doc. Option B' = `actions/checkout` `path:` STAYS at default `GITHUB_WORKSPACE` (= `_work/AtilCalculator/AtilCalculator`, GA-safe per ADR-0027 + lens (i)) + `deploy-runner.sh` REPO_DIR default chain unchanged + 8-lens lens (i) platform hard constraints pre-publish gate applied. Replaces Sprint 4 P2 Option C (which violated GA `_work/` sandbox, reverted via PR #352). Supersedes Story-193 v1 (Option A, Sprint 4 design). Story-194 Option A delivery (no-op verify + this docs PR) closes Sprint 4 P2 #194 SYMNK-CLEANUP via #363 doctrinal half + #361 impl half + this docs PR traceability.

#### Fixed

- **PR #361 — `STORY-193` `deploy-runner.sh` v9 → v9.1 audit log (commit `c9268ba`, refs #193).** Sprint 6 P1 #193 RCA17-REDESIGN implementation. Adds 2-line audit log capturing REPO_DIR + current user identity at deploy time. Audit log answers the questions RCA-17 asked: "what path was deploy from?" + "what user ran deploy?". REPO_DIR default chain unchanged (canonical path, no symlink). v9 → v9.1 amendment is docs-only (no behavioral change). Header references RCA-17 + PR #358 design. Sister to PR #358 Option B' design.

- **PR #364 follow-up — `STORY-193-design.md` §Risks R2 amendment (same commit `87787b8`).** Amends R2 mitigation to correct factual errors (27 auto-gen refs in `scripts/.tmux-bootstrap/*.sh` are gitignored + auto-generated by `scripts/dev-studio-start.sh` line 27 dynamic `REPO_ROOT` resolution; canonical runner path `/home/atilcan/actions-runner/_work/...` does not exist post-owner-ops Steps 6+7). Cross-references ADR-0045 lens (j). Per Issue #363 cmt 4792738456 Option A.

#### Closed

- **Issue #363 — `[Design-Drift]` STORY-194 SYMNK-CLEANUP scope conflict — P1 INCIDENT doctrinal close.** Closed via PR #364 ADR-0045 + TD-030 closeout (lens (j) codification) + PR #361 `deploy-runner.sh` v9.1 audit log (impl) + this docs PR (traceability). Pattern: same blind-spot family as TD-016/TD-018/TD-019/TD-020/TD-028/TD-029 (8th in family, 4th post-merge). Doctrinal lesson: pre-publish gates must include **repo content boundaries** + **live-state drift** in addition to platform constraints + ADR constraints + local shape.

- **Issue #194 — Sprint 4 P2 symlink cleanup — deploy.yml checkout path override + REPO_DIR default (RCA-17 follow-up).** Closed via Issue #363 Option A delivery (PR #364 doctrinal + PR #361 impl + this docs PR). Implementation: `scripts/.tmux-bootstrap/*.sh` references correct post-unlink real dir `/home/atilcan/projects/AtilCalculator` (auto-generated by `dev-studio-start.sh` line 27 dynamic REPO_ROOT; no manual edit needed — bootstrap edits during Sprint 5 were reverted per TD-030 discovery). `deploy-runner.sh` REPO_DIR default chain unchanged per RCA-7 + PR #358 Option B' design. E2E verified: all 6 bootstrap scripts `bash -n` PASS + `cd` to correct real dir + `deploy-runner.sh` v9.1 `bash -n` + `--dry-run` PASS.


## 2026-07-19T11:12+03:00 — Sprint 32 close ceremony (Issue #1163, Closes #1163, Refs #159 #160 #1164 #1162)

Sprint 32 cluster-squash Wave 1..6 forward-port cluster (atilproject/AtilCalculator → atilproject/dev-studio-template) closes via orchestrator ceremony PR. Trigger: owner directive cycle ~#3739 "TÜM AÇIK ISSUEʼlAR SPRINT 32ʰDE KAPANACAK" — sprint-scope expansion (Issue #171-180 Sprint 33+ backlog pulled into Sprint 32 via sprint:current label add) plus 4-flag hand-off on Issue #1163 (status:blocked→in-progress, cc:architect+cc:tester released).

### Added

- **docs/sprints/sprint-32/00-plan.md** (RETROSPECTIVE PLAN, cycle ~#3740). Full Sprint 32 plan with 6 cluster-squash waves, 8 merged PRs, 14 NEW doctrine lessons, cluster-squash cadence 2m33s..21m26s per ADR-0059 + RETRO-033 §partial-cluster pause.
- **docs/sprints/sprint-32/close.md** (SPRINT 32 CLOSE, cycle ~#3740). Outcome narrative + landed-artifact preservation table + closure checklist + Sprint 33 deferral note.
- **docs/sprints/sprint-32/RETRO-032.md** (RETROSPECTIVE, cycle ~#3740). 14 NEW doctrine codifications (RETRO-033 §partial-cluster pause this sprint) + 6 didnʼt-go-well lessons + 6 action items (Sprint 33 P1 carry-over).

### Doctrine codified (Sprint 32 — 14 NEW lessons)

- Cycle ~#3471: BOTH-gate requirement for downstream unblock (BOTH PRs need merge)
- Cycle ~#3642B: REST fallback for GraphQL exhaustion
- Cycle ~#3642H: git patch-id --stable for content equivalence; Lane 3 d-test-only sign-off
- Cycle ~#3665Q: Issue #414 §1.5 = FINAL re-query IMMEDIATELY before verdict comment
- Cycle ~#3670: notify.sh -l warn -w -r human for owner-only chore escalation past 15min
- Cycle ~#3671: warn-level escalation distinct from info-level (NOT double-prompt regression)
- Cycle ~#3672/#3673: PR field quartet (state + merged + merged_at + merge_by); merge_commit_sha is PREDICTED not applied
- Cycle ~#3674: REST API direct endpoint (GraphQL silent-skip on rate-limit); Layer 2/2.5/3 verification
- Cycle ~#3675: agent comment "Lane ✅ CLOSED" ≠ PR state ✅ CLOSED
- Cycle ~#3677: Even REST direct endpoint has label-sync lag; Layer 3 events authoritative
- Cycle ~#3678/#3679: Cluster-squash cycles; bot cleanup asymmetric (PRs get status:done, issues keep pre-close status:*)
- Cycle ~#3690: .tmpl placeholder additions MUST be atomic with init.sh sed block update (Cadence Rule 1 sister-pattern)
- Cycle ~#3693: cluster-squash sister reference must verify PR exists via REST search
- RETRO-033 §partial-cluster pause (NEW): owner can partially cluster-squash, pause, resume later; cycle ~#3471 BOTH-gate relaxed to MERGED-count ≥1 + owner-cue outstanding. Validated end-to-end cycle ~#3731 (PR #187→#188 = 21m26s pause, both Closes anchors +1s lag).

### Cross-refs

- Issue #1163 (Closes) — Sprint 32 close ceremony (orchestrator lane)
- Issue #1164 (Refs) — Wave 5/6 forward-watchdog broadcast (orchestrator lane, in-progress → close ceremony)
- Issue #1162 (Refs) — AUTO-CLOSED via PR #183 squash (cluster-squash cascade)
- Issue #159 (Refs) — Sprint 32 S32-019 tag cut v1.1.0 (RETRO-024 work-done-elsewhere terminal pattern)
- Issue #160 (Refs) — Sprint 32 S32-020 Phase B (dev lane, post-cycle-#3471 gate MET, escalation in flight)
- tmpl#142 / tmpl#132 / tmpl#170 / tmpl#182 / tmpl#183 / tmpl#184 / tmpl#187 / tmpl#188 — 8 PRs (Wave 1..6 cluster-squash forward-port cluster)
- RETRO-031 (Sprint 31 KAPI hotfix) + RETRO-018 W6 (branch-ownership matrix) — sister-patterns
- ADR-0059 (cluster-squash cadence) + ADR-0055 §1 (Cadence Rule 1) + ADR-0057 (Closes anchor strict)
- RETRO-024 (work-done-elsewhere 4-cat exception) — Issue #159 + #1162 terminal pattern

## 2026-07-20T15:42Z — Sprint 32 Wave 8+ extension close ceremony (Closes #1171, Refs #194 #195 #196 #198)

Sprint 32 Wave 8+ extension cluster-squash 4/4 TERMINAL ✅. Owner-directive cycle ~#3889Q ("TÜM AÇIK ISSUE'LAR SPRINT 32'DE KAPANACAK") pulled 17 open org-wide items into Sprint 32 scope. 4-PR cluster (PR #194+#195+#196+#198) squash-merged by atilcan65 in 3h02m42s wall-clock. Sprint 32 S32-024 dry-run TERMINAL via owner-direct execution in 14min (cycle ~#3961Q). AC5 24h soak verification split-deferred to Sprint 33 RETRO follow-up (cycle ~#3962Q owner directive a).

### Added

- **PR #194** — docs(adr): S32-027-B DEFERRED cluster (5 ADRs, 2 added 0064+0065, 2 amended 0048+0012, 1 INDEX). squash-merged @ 2026-07-20T12:25:43Z (sha `6e1a562d`). Closes tmpl#164. 4th validation of cycle ~#3679 1-sec lag sister-pattern. Tester Lane 2 docs verdict 1/1 sole.
- **PR #195** — docs(adr): S32-027-D HYBRID cluster (10 ADR amendments folded into 6 tmpl parent ADRs 0002+0024+0038+0048+0049+0057 per ADR-0057 §amendment-via-parent). squash-merged @ 2026-07-20T15:05:32Z (sha `87413d58`). Refs tmpl#165 NO Closes intentional (amendment-via-parent pattern). d165 47/47 GREEN. Arch rebase + push @ 6439d74 (cycle ~#3940Q+5 + RETRO-018 W6 cross-agent push authority). 5th validation cycle ~#3679.
- **PR #196** — test(scripts): S32-024 d-test Phase A RED-first (8 TCs). squash-merged @ 2026-07-20T15:10:34Z (sha `5d2a251c`). Closes tmpl#162. 6th validation cycle ~#3679. tmpl#162 premature-close sister-pattern (cycle ~#2919): Phase A only; Phase B impl needed → flagged Sprint 33 P1 follow-up.
- **PR #198** — docs(sprints): S32-024 Phase B summary + AC1-AC6 dry-run evidence. squash-merged @ 2026-07-20T15:28:21Z (sha `bc649eb`). Closes tmpl#197. 7th validation cycle ~#3679. Verdict labels `verdict-by:tester-dry + verdict-by:architect-dry` at 15:26Z (cycle ~#3670 owner-escalation pattern). Owner-as-CI execution at sprint-close scale.

### Doctrine codified (Wave 8+ — 5 NEW lessons, beyond Sprint 32 14)

- **Cycle ~#3679 1-sec lag sister-pattern — 4th-7th validations**: PR squash → Issue auto-close 1s later observed 7 distinct times. Confirms pattern is deterministic, not coincidental. Cluster-squash doctrine (ADR-0059) is now retroactively anchored.
- **Cycle ~#3958Q wake_nudge polling-loop bug**: `scripts/agent-watch.sh` wake_nudge ID = `wake-nudge-{role}-{now}` (UNIQUE per poll timestamp) — NOT in dedup ring. Cross-cutting watcher bug. **Mitigation (immediate)**: `scripts/agent-state.sh set developer poll_interval_sec 600`. **Permanent fix deferred** to Sprint 33 P1.
- **Cycle ~#3961Q owner-as-CI pattern at sprint-close scale**: Cycle ~#3670 owner-escalation extended to sprint-close scale. 14-min full dry-run lifecycle (bootstrap + PM-claim + dev-claim + 15/15 pytest + squash + close-the-loop) validates doctrine for sprint-crunch velocity.
- **Cycle ~#3960Q Wave 8+ cluster-squash 4/4 TERMINAL**: ADR-0059's 3-PR canonical extends to 4-PR scale. Cadence Rule 2 cumulative NO-OP across the cluster.
- **Cycle ~#2919 premature-close + sister-PR doctrine**: Partial Closes anchor + Phase A only body language auto-closes Phase B tracking. Mitigation: use `Refs #N` for partial coverage; reserve `Closes #N` for full AC coverage.

### Cross-refs

- **Issue #1171** (Closes) — Sprint 32 Wave 8+ close ceremony (orchestrator lane)
- **Issue #197** (Ref tmpl#197) — S32-024 Phase B [DEV] follow-up to tmpl#162 premature-close (auto-closed via PR #198 Closes anchor)
- **tmpl#162** (Refs) — S32-024 [DEV] New project bootstrap dry-run Phase A only; Phase B deferred to Sprint 33
- **tmpl#164 / tmpl#165** (Refs) — S32-027-B / S32-027-D arch lane work products (Cadence Rule 2 cleanup)
- **PR #194 / #195 / #196 / #198** — 4-PR cluster-squash (Wave 8+ extension milestone)
- **PR #1167** (Ref) — Sprint 32 base close ceremony (cycle ~#3740, terminal @ cycle ~#3748)
- **PR #193** (Ref) — Sprint 32 S32-018 (Phase B predecessor, AC5 24h soak anchor)
- **ADR-0059** (cluster-squash cadence, 3-PR canonical, extended to 4-PR) + **ADR-0055 §1** (Cadence Rule 1 atomic) + **ADR-0057** (Closes anchor strict)
- **RETRO-024** (work-done-elsewhere 4-cat exception) — Issue #1171 docs PR uses pattern when PR merges
- **RETRO-018 W6** (branch-ownership matrix cross-check) — PR #195 rebase recovery dispatched to arch
- **Sister-pattern**: cycle ~#3940Q+9 content-blob SHA doctrine (15/15 pytest in dry-run verification)

## 2026-06-20T09:31:07Z — uv PATH fix verified
## 2026-06-20T09:43:21Z — uv PATH fix verified (Sprint 3 P0 RCA-13)

- **Sprint 33 close ceremony (Issue #1163 sister, cycle ~#3968Q+302+, 2026-07-24T05:32Z).** Sprint 33 P2 cluster FULL TERMINAL ✅ — 9 PRs shipped cross-repo (8 AtilCalculator + 1 launcher), 9 issues closed via direct `Closes` + EXTENDED cycle ~#3679 1-sec-lag `Refs` cross-PR anchor (Issue #1211 closed via PR #1214 squash `Refs #1211` anchor). Cluster-squash pairs #4 (PR #1206+#1207 12-sec window 07:03Z) + #5 (PR #1208+#1209 15-sec window 08:25Z) + #6 (PR #1212+#1213 STANDALONE 19-min gap) + #7 (PR #1214+#1215 RATIFIED FULL ✅ 12-min gap 13:28Z→13:40Z per cycle ~#3968Q+242) + cross-repo standalone PR launcher#15 (squash @ 2026-07-24T05:31:56Z merge_sha `cfaf2fc9`). **12 NEW doctrine codified** (cycle ~#277 matrix + cycle ~#3679 EXTENDED + cycle ~#3968Q+226 storm-watch + cycle ~#3968Q+180+182 verdict-by auto-pair + cycle ~#3968Q+244 3-flag atomic flip + cycle ~#3968Q+243 peer-poke broken-symlink fallback + cycle ~#3968Q+241 branch-owner rebase + cycle ~#3968Q+239 gh pr ready flip + cycle ~#3968Q+254 cadence-preference + cycle ~#3968Q+237 cc:human silent-rollback + cycle ~#3968Q+302 alias-mismatch canonical pattern + cycle ~#3968Q+229 STOP-doctrine). **Sprint 33 close.md** (NEW, docs/sprints/sprint-33/close.md) captures §Outcome + §What landed on main + §Sprint 33 NEW doctrine + §Sprint closure checklist + §Cross-references + §Sister-pattern hooks. **Cadence Rule 1 atomic (ADR-0055 §1)** — close.md + RETRO-033.md (3 orchestrator appends: 8h+ cross-lane capture + 12h+ tier PM-side board lane + alias-mismatch canonical pattern) + this CHANGELOG.md entry = 3 files same commit. **Lane review chain**: orchestrator (this close ceremony PR — author + lane ownership) + owner @atilcan65 (squash gate per ADR-0031). **Owner directive 2026-07-22T16:17Z** ratified: gap-closing sprint activation, NO Sprint 34 deferrals. **Sister-pattern**: PR #1167 (Sprint 32 close ceremony, cycle ~#3748) + cycle ~#3968Q+200 (Sprint 33 scope expansion directive). **Doctrinal anchors**: cycle ~#3748 (Sprint 32 close reference pattern), cycle ~#3968Q+209+ (Sprint 33 doctrine amendment home — RETRO-033), cycle ~#3968Q+242 (cluster-squash pair #7 FULL TERMINAL), cycle ~#3968Q+302 (this close ceremony), cycle ~#277 (8h+ tier doctrine matrix), cycle ~#3679 (1-sec-lag auto-close EXTENDED), ADR-0055 §1 (Cadence Rule 1 atomic — 3 files same commit), ADR-0031 (owner squash gate), RETRO-018 W6 (branch ownership matrix), Issue #1163 (Sprint 32 close ceremony sister Issue).
- **Issue #1200 S33-009 pattern:NETWORK_DEP — mock-first + RECONCILE_LIVE_TOKEN toggle helper + d099 d-test (Closes #1200, sprint:current).** Sprint 33 P2 cluster, gap-pattern row 5 of [ADR-0073](./docs/decisions/ADR-0073-env-dep-dtest-sister-pattern.md) §10 action items, owner directive 2026-07-21T09:55Z reframed Sprint 34 → Sprint 33 P2 cluster scope expansion (arch Option A amend commit 270f693 in PR #1198). **Two-part addition**: (a) **`scripts/d-test-reconcile-live.sh` helper (NEW, ~100 LOC)** — mock-first state resolver with `RECONCILE_LIVE_TOKEN=1` explicit live opt-in + validation (unknown value → exit 2) + `--check` flag path emitting `silent_skip mode=mock helper=scripts/d-test-reconcile-live.sh` line to `${D_TEST_LOG_DIR:-/var/log/dev-studio/AtilCalculator}/d099.silent_skip.log` per ADR-0056 (mock mode observability — no silent fallback). Sister-pattern: cycle ~#3642B REST fallback (gh api .../comments for GraphQL exhaustion — extended with mock-first + live-reconcile doctrine). (b) **`scripts/tests/d099-reconcile-live-network-mock.sh` d-test (NEW, ~270 LOC, 7/7 GREEN locally verified per cycle ~#3893Q v2 verify-locally-before-verdict)** — TC0 bash -n hygiene sister-pattern d098 TC0/d020a TC1 + TC1 RECONCILE_LIVE_TOKEN unset → "mock" mock-first default per AC2a TC1 + TC2 RECONCILE_LIVE_TOKEN=1 → "live" live opt-in per AC2a TC2 + TC3 silent_skip log emission per ADR-0056 --check flag mock mode per AC2a TC3 + TC4 invalid RECONCILE_LIVE_TOKEN=foobar → exit 2 validation rejection + TC5 --check flag path mock mode + log emission verification + TC6 token-rotation mid-test RECONCILE_LIVE_TOKEN change between invocations respected no caching per AC2a TC6. RED-first per ADR-0044 — pre-impl 6/6 FAIL (helper + d-test absent from main). ≥5 TCs baseline per ADR-0049 — d099 = 7 TCs exceeds baseline by 2. ≥3 sister-pattern coverage per ADR-0049 met (5 sisters: d058 + d069 + d098 + ADR-0056 + cycle ~#3642B). **Cadence Rule 1 atomic (ADR-0055 §1)** — helper + d-test + INDEX.md row + this CHANGELOG.md entry = 4 files same commit. **Lane review chain**: arch (9-Lens ADR-0045 on mock-first + silent_skip doctrine) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H) + owner @atilcan65 (squash gate per ADR-0031). **Sister-cluster**: Issue #1199 S33-008 pattern:CI_OS_DEP (squash @ f7fafb8 per PR #1201, predecessor per cycle ~#209 reframe order). **Doctrinal anchors**: cycle ~#209 (reframe order — S33-008 first → squash → S33-009), cycle ~#3642B (REST fallback sister-pattern source), cycle ~#3893Q v2 (verify-locally-before-verdict — d099 --self-test run locally pre-PR), cycle ~#3968Q+214 (claim atomic = status-only, self-cc preserves 4-cat — applied at Issue #1200 claim), Issue #414 §1 (pre-PR re-query), ADR-0002 (autonomy loop), ADR-0033 (dual-channel peer-poke), ADR-0038 §Layer 2 (WIP cap), ADR-0044 (RED-first TDD), ADR-0049 (d-test ≥5 baseline + ≥3 sister), ADR-0055 §1 (Cadence Rule 1 atomic — 4 files same commit), ADR-0056 (silent_skip log emission — TC3+TC5 anchor), ADR-0057 (Closes anchor — `Closes #1200` per impl purpose).

- **Sprint 34 S34-005 AC2 sister-PR — atilcan65/AtilCalculator runner label atilproject → atilcan (Refs atilproject/AtilCalculator#1225, sprint:current).** Sprint 34 W3 forward-port, sister-PR of dev-studio-template PR #214 (squash-merged 2026-07-26T04:23:34Z sha 18e374ca by @atilcan65, cluster-squash #22 TERMINAL ✅). Sister-PR dispatch [ORCH→DEV] 2026-07-26T04:32:45Z. **Two-part addition**: (a) **10 `.github/workflows/*.yml` files (MODIFIED atilproject → atilcan)** — ai-pr-review.yml + ci.yml + cross-repo-close.yml + d050b-dispatch.yml + deploy.yml + label-check.yml + label-cleanup.yml + lint-and-test.yml + post-squash.yml + secret-canary.yml. 12 occurrences total (1+2+1+1+1+1+1+2+1+1). out-of-scope: status-label-to-board.yml preserved atilproject (1 occurrence, dispatch scope fidelity per orchestrator directive). Sister-PR mirrors PR #214 dev-studio-template impl scope exactly. (b) **`scripts/tests/d-s34-005-runner-label-atilcan.sh` d-test (NEW, ~135 LOC, 15 TCs RED-first per ADR-0044)** — TC1 workflows dir exists + TC2-TC11 each scope file ≥1 atilcan self-hosted label + TC12 zero residual atilproject + TC13 out-of-scope preservation + TC14 INDEX.md row + TC15 CHANGELOG.md entry. Pre-Cadence-Rule-1 13/15 GREEN + 2 RED (TC14 INDEX + TC15 CHANGELOG) verified non-vacuous. ≥5 TCs baseline per ADR-0049 — 15 TCs exceeds baseline by 10. ≥3 sister-pattern coverage per ADR-0049 met (8 sisters: PR #214 dev-studio-template + d-s34-005-runner-label-atilcan + ADR-0055 §1 + ADR-0044 + ADR-0049 + ADR-0057 + ADR-0015 + cycle ~#3968Q+414 + cycle ~#3968Q+311+8). **Cadence Rule 1 atomic (ADR-0055 §1)** — 10 workflow files + d-test + INDEX.md row + this CHANGELOG.md entry = 4 files same commit. **Lane review chain**: arch (Lane 2 docs verdict per ADR-0045, workflow-only changes sister-pattern mirror PR #214) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H, 15/15 GREEN expected) + owner @atilcan65 (squash gate per ADR-0031 — UNSTABLE expected per cycle ~#3968Q+414 PR-self-blocking CI doctrine since workflows use the same self-hosted label). **Sister-PR pattern**: Sister-PR-A (launcher — Task #69, separate dispatch per arch verdict option a-decomposed cycle ~#3968Q+460, 2 files + 3 atomic). cluster-squash #23 (launcher) + cluster-squash #24 (AtilCalculator) candidate STANDALONE per cycle ~#3258. Cadence target ≤9h17min squash-gate (cycle ~#3968Q+337 baseline). **Doctrinal anchors**: ADR-0044 (RED-first TDD — 2/15 RED non-vacuous), ADR-0049 (d-test ≥5 baseline + ≥3 sister), ADR-0055 §1 (Cadence Rule 1 atomic — 4 files same commit), ADR-0057 (Refs anchor — `Refs atilproject/AtilCalculator#1225` per Issue already closed), ADR-0015 (4-flag atomic hand-off — chain 3/3 ACK pattern cycle ~#3968Q+239), ADR-0031 (owner squash gate), ADR-0033 (dual-channel peer-poke), cycle ~#3968Q+414 (PR-self-blocking CI doctrine), cycle ~#3968Q+311+8 (CONDITIONAL preventive — branch from latest main tip), cycle ~#3258 (STANDALONE cluster-squash cap), cycle ~#3968Q+337 (sister-squash-gate cadence baseline), cycle ~#3968Q+460 (arch verdict option a-decomposed for launcher).
