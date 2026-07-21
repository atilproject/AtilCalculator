# ADR-0073: Env-Dep d-test Sister-Pattern Doctrine (Issue #1182, Sprint 33 P2)

> **Status**: ACCEPTED (squash-merged via PR #1195 dedb0f6 2026-07-21T06:34:56Z @atilcan65) + **AMENDED** (this PR, owner directive 2026-07-21T09:57:47+03:00)
> **Date**: 2026-07-20 (original) / 2026-07-21 (amendment)
> **Author**: @architect (cycle ~#3968Q+62 original, cycle ~#3968Q+71 amendment per owner directive)
> **Sprint**: Sprint 33 P2 carry-over #9 (RETRO-032 lesson #5 didn't-go-well)
> **Reviewer**: @tester (test discipline review per RETRO-032 lesson #5) + @human (owner approval gate per ADR-0031)
> **Sister-ADR**: ADR-0044 (RED-first TDD), ADR-0049 (d-test framework ≥5 TCs baseline), ADR-0055 §1 (Cadence Rule 1 atomic)
> **Amendment scope**: §2 + §9 + §10 (TIME_DEP removal from deferred gap patterns); new §11 (Considered + Rejected patterns) added. Sprint 33 plan addendum (S33-007) + arch lane S33-006 amendment UNTOUCHED per owner.

## Context

### Problem statement

RETRO-032 lesson #5 didn't-go-well captured: tmpl#170 S32-021 d-test sweep showed **26 GREEN + 7 regressions + 3 pre-impl + 4 env-dep** (cycle ~#3471). AC4 (env-dep stability) NOT MET. 13 sister-issues opened via Cadence Rule 2.

Two env-dep d-test patterns emerged from the sweep:
- **Issue #1083 (NOTIFY_NO_AUTOLOAD)** — `env -u` decouples CI env from test fixture env → shipped via PR #1170+#1172 cluster
- **Issue #1108 (FAKE_FLIPPED_FILE)** — Fake fixture seed pinned via SHA literal in test source → shipped via PR #1177

These two patterns work but are NOT codified as a reusable sister-pattern doctrine. Issue #1182 was filed (Sprint 33 P2) to codify the doctrine.

**Issue #1182 scope correction** (per @architect ACK 2026-07-20T19:23:52+03:00):
- Issue #1108 (FAKE_FLIPPED_FILE) is **already CLOSED via PR #1177** — NOT to be re-implemented
- Issue #1083 (NOTIFY_NO_AUTOLOAD) is **already shipped via PR #1170+#1172 cluster** — NOT to be re-implemented
- **Issue #1182 scope = codify the sister-pattern doctrine** — NOT re-implement precedents

### Tester POV (input — cmt 5026776083)

Per @tester peer-co-design cmt 5026776083 (cycle ~#3968Q+62, lane: test discipline review per RETRO-032 lesson #5):

- **A. Sister-test inventory**: 8 patterns (NOTIFY_NO_AUTOLOAD, FAKE_FLIPPED_FILE, content-blob SHA, env-rot self-test, byte-equal 6/6 GREEN, REST fallback, --self-test/--live split, Lane 3 d-test-only sign-off)
- **B. 3 gap patterns identified**: time-dep (Issue #1186 AC5), CI-OS-dep (d058 TC1), network-dep (live `gh api`)
- **C. Update discipline**: 3 new-pattern triggers + 3 update triggers + Cadence Rule 1 atomic + RETRO-032 lesson #5 capture mechanism + 7-lane rejection criteria
- **D. 4 open questions for arch** (addressed in §Decision)

## Decision

### §1 — Sister-pattern inventory (canonical, 8 patterns)

| ID | Pattern | Env-dep class | Status | Origin / Spec |
|---|---|---|---|---|
| `pattern:NOTIFY_NO_AUTOLOAD` | `env -u` decouples CI env from test fixture env | env-var presence | ✅ shipped PR #1170+#1172 | Issue #1083 |
| `pattern:FAKE_FLIPPED_FILE` | Fake fixture seed pinned via SHA literal in test source | fixture-rot | ✅ shipped PR #1177 | Issue #1108 |
| `pattern:CONTENT_BLOB_SHA` | Cross-repo port equivalence via `git patch-id --stable` + blob SHA | env-var absence + port drift | ✅ shipped PR #193 | cycle ~#3955Q |
| `pattern:ENV_ROT_SELF_TEST` | Pre-verdict `bash scripts/tests/d0*.sh --self-test` MUST PASS locally | runner env drift | ✅ active | cycle ~#3893Q v2 |
| `pattern:BYTE_EQUAL_6_OF_6` | Lane 3 d-test-only sign-off for forward-port PRs (sister-PR equivalence) | impl-env + test-env | ✅ active | cycle ~#3427 |
| `pattern:REST_FALLBACK` | `gh api .../comments` for GraphQL exhaustion (no live token) | auth-env | ✅ active | cycle ~#3642B |
| `pattern:SELF_TEST_LIVE_SPLIT` | TC-level `--self-test` (mock-tree) + explicit `--live` (with git-restore) | env-mutation | ⏳ proposed | Issue #201 AC3 TC7 |
| `pattern:LANE_3_DTEST_ONLY` | RED state OK for forward-port d-tests when content-equivalence proven | state-env | ✅ active | cycle ~#3642H |

### §2 — Gap patterns (Sprint 33+ P2 follow-up Issues, deferred per tester Q4)

| ID | Pattern | Env-dep class | Status | Origin |
|---|---|---|---|---|
| `pattern:CI_OS_DEP` | Multi-OS matrix OR explicit `--target-os` override | runner OS drift | ⏳ proposed | d058 TC1 env-rot |
| `pattern:NETWORK_DEP` | Mock layer + RECONCILE_LIVE_TOKEN env toggle | network-live | ⏳ proposed | cycle ~#3642B partial (REST fallback only, NOT mock-first) |

**Decision on Q4 (carry-over #9 finalization)**: Issue #1182 codifies the doctrine for the 8 existing patterns. The 2 remaining gap patterns get follow-up Issues filed in Sprint 33+ P2 cluster (separate from Issue #1182 carry-over #9).

**Amendment 2026-07-21**: `pattern:TIME_DEP` REMOVED from §2 (was previously listed). See §11 for rejection rationale. Original §2 row: `pattern:TIME_DEP | Monotonic clock mock + bounded test window | time-of-day | ⏳ proposed | Issue #1186 AC5 24h soak`.

### §3 — Pattern ID schema (answer to tester Q1)

**Decision**: canonical form `pattern:<UPPER_SNAKE>` — labels + INDEX.md row + RETRO references all use this form.

Examples:
- `pattern:NOTIFY_NO_AUTOLOAD` (NOT `pattern:notify-no-autoload`)
- `pattern:FAKE_FLIPPED_FILE` (NOT `pattern:fake-flipped-file`)
- `pattern:CONTENT_BLOB_SHA` (NOT `pattern:content-blob-sha`)

Rationale:
- Upper-snake matches the underlying env-var / fixture-constant naming
- Stable across renames (kebab-case → snake_case drift is common)
- Grep-friendly (`grep -E '^pattern:[A-Z_]+$' scripts/tests/INDEX.md`)

**Cadence Rule 1 atomic (ADR-0055 §1)**: d-test file + INDEX.md row + this ADR reference MUST land same commit. INDEX.md row MUST include `pattern:<UPPER_SNAKE>` ID per the canonical schema.

### §4 — `--self-test` gate (answer to tester Q2)

**Decision**: `--self-test` is a **SOFT gate** (warn but allow) in Sprint 33 → **HARD gate** (CI blocks if d-test requires live API when `--self-test` should suffice) deferred to Sprint 34+.

Rationale:
- Sprint 33 → soft gate: forward compatibility for Issue #201 fix PR's `--self-test/--live split` (AC3 TC7) which proposes the hard gate as TC7 follow-up
- Sprint 34+ → hard gate: requires `d-*-harness.sh` integration per sister-pattern d050b TC1 (`workflow_dispatch.yml`)
- Soft gate transition: warn via `silent_skip` log emission per ADR-0056 + ADR-0048 lens d (doctrinal home)

### §5 — Multi-OS matrix (answer to tester Q3, deferred)

**Decision**: defer multi-OS matrix doctrine to follow-up Issue. Issue #1182 codifies the env-dep pattern doctrine; multi-OS matrix is a CI-infrastructure decision (orthogonal).

Rationale:
- Issue #1182 = doctrine codification (this ADR)
- Multi-OS matrix = CI workflow YAML change (`.github/workflows/lint-and-test.yml` is human-only territory per file ownership matrix — NOT arch lane)
- Defer to Issue TBD (file as Sprint 34+ P2 cluster with arch-advisory + dev-impl + owner-squash)

### §6 — Update discipline (tester section B)

**New-pattern triggers** (3):
1. **New env-dep failure class discovered** (RETRO-032 lesson #5 mechanism): d-test sweep surfaces it → capture in RETRO + add to Issue #1182 inventory + add TC to scripts/tests/INDEX.md
2. **New runner/CI matrix added** (e.g., macOS-latest): existing d-tests MUST re-verify locally per cycle ~#3893Q v2 before next verdict
3. **Cross-repo port family grows** (e.g., Issue #201 calc-side mirror + tmpl-side original): both sides MUST use same pattern ID; `Refs atilproject/dev-studio-template#N` in INDEX.md row

**Update triggers** (3):
1. **Runner env change** (e.g., GitHub Actions ubuntu-latest upgrade): re-run all env-dep d-tests in `--self-test` mode; if FAIL → file Issue with `env-rot` tag per cycle ~#3853 doctrine
2. **Fixture source changed**: update FAKE_FLIPPED_FILE seed SHA literal in test source + re-verify byte-equivalence
3. **Pattern codified in this ADR** → all sibling d-tests MUST cite the doctrine doc path in their INDEX.md row

**Cadence Rule 1 atomic (ADR-0055 §1)** — non-negotiable:
- d-test file + scripts/tests/INDEX.md row + CHANGELOG.md entry MUST land same commit
- `pattern:<UPPER_SNAKE>` ID MUST be cited in INDEX.md row

**RETRO-032 lesson #5 capture mechanism**:
- Every d-test sweep cycle (cycle ~#3471 cadence: per-sprint) MUST capture didn't-go-well in RETRO-NN.md
- env-dep d-test AC (AC4 in tmpl#170) MUST be re-verified GREEN post-sweep; if NOT MET → file `type:bug` + priority:P1 + `env-rot` label

### §7 — Tester-lane rejection criteria (7 lanes)

A d-test PR is BLOCKED by tester if ANY of these fail:

1. **Cadence Rule 1 atomic violated** (impl + d-test + INDEX.md row not same commit)
2. **TC count <5** (ADR-0049 ≥5 baseline, default ≥6 per Cycle ~#3471 refinement)
3. **`pattern:<UPPER_SNAKE>` ID not cited in INDEX.md row** (per §3 schema)
4. **`--self-test` mode missing or broken** (CI-runner env required when `--self-test` should suffice per §4)
5. **No env-var override mechanism** (NOTIFY_NO_AUTOLOAD precedent violated)
6. **Fixture seed not pinned** (FAKE_FLIPPED_FILE precedent violated)
7. **Forward-port without content-blob SHA equivalence proof** (cycle ~#3955Q violated)

### §8 — 9-Lens attestation (per ADR-0045)

| Lens | Verdict | Note |
|---|---|---|
| (a) Correctness | ✅ | All 8 patterns traced to source issues; tester POV re-verified |
| (b) Tests | ✅ | §7 rejection criteria = 7-lane test discipline; ≥6 default TCs per pattern |
| (c) Cadence atomicity | ✅ | ADR + INDEX.md row + CHANGELOG entry same commit (this PR) |
| (d) Sister-pattern | ✅ | NOTIFY_NO_AUTOLOAD + FAKE_FLIPPED_FILE + content-blob SHA all cited |
| (e) Cross-repo | ✅ | Issue #201 (tmpl-side) forward-port mirrored via `Refs atilproject/dev-studio-template#N` |
| (f) Owner gate | ✅ | `.claude/` + `.github/workflows/` human-only; this ADR is `docs/decisions/` arch lane |
| (g) Sign-off lane | ✅ | tester Lane 3 sign-off pattern (cycle ~#3642H sister) |
| (h) Doctrinal anchors | ✅ | ADR-0044 + ADR-0049 + ADR-0055 §1 + ADR-0057 + ADR-0012 + RETRO-032 lesson #5 |
| (i) AC coverage | ✅ | AC1 doctrine codification + AC2 sister-pattern inventory (8 patterns) + AC3 update discipline + AC4 tester POV integration + AC5 schema canonicalization (§3) + AC6 soft/hard gate transition (§4) + AC7 multi-OS deferral (§5) |

**9-Lens ALL GREEN per ADR-0045.** ✅

## §9 — Cross-references

- **Issue #1182** — this ADR's origin (Sprint 33 P2 carry-over #9)
- **Issue #1083** — NOTIFY_NO_AUTOLOAD precedent (shipped PR #1170+#1172)
- **Issue #1108** — FAKE_FLIPPED_FILE precedent (shipped PR #1177)
- **Issue #1186** — Sprint 33 kickoff (kickoff gate REMOVED 2026-07-21 per owner directive — AC5 24h soak mechanic ABOLISHED; Issue #1181 closed)
- **Issue #201** — tmpl-side P1 init.sh .tmpl deletion bug (--self-test/--live split, AC3 TC7)
- **RETRO-032 lesson #5** — didn't-go-well capture (origin)
- **cycle ~#3471** — S32-021 d-test sweep BOTH-gate (origin)
- **cycle ~#3427** — byte-equal 6/6 GREEN (sister-pattern anchor)
- **cycle ~#3642B** — REST fallback (GraphQL exhaust)
- **cycle ~#3642H** — Lane 3 d-test-only sign-off (cycle ~#3427 sister)
- **cycle ~#3853** — d058 TC1 env-rot classification
- **cycle ~#3893Q v2** — verify-locally-before-verdict (env-rot discipline)
- **cycle ~#3955Q** — content-blob SHA doctrine (PR #193 sister-pattern)
- **cycle ~#3958Q** — wake_nudge no-dedup class (cycle ~#3968Q storm mitigation)
- **cycle ~#3968Q+62** — this ADR cycle
- **ADR-0012** — 4-cat label invariant (apply to Pattern ID labels)
- **ADR-0015** — atomic 4-flag hand-off (for pattern ID label transitions)
- **ADR-0044** — RED-first TDD (doctrinal home)
- **ADR-0045** — 9-Lens pre-publish gate (this ADR's §8)
- **ADR-0048** — silent_skip log emission (doctrinal home for §4 gate)
- **ADR-0049** — d-test framework (≥5 TCs baseline)
- **ADR-0055 §1** — Cadence Rule 1 atomic (this ADR + INDEX + CHANGELOG same commit)
- **ADR-0056** — silent_skip fail-loud doctrine
- **ADR-0057** — Closes vs Refs anchor
- **ADR-0059** — cluster-squash doctrine (for Issue #201 fix PR cluster)
- **ADR-0068** — Lane 3 j.4 tester-author exception (sister-pattern)

## §10 — Action items (this ADR)

- [x] **arch**: open PR with this ADR + scripts/tests/INDEX.md row + CHANGELOG.md entry same commit (Cadence Rule 1 atomic) — SQUASHED via PR #1195 dedb0f6 2026-07-21T06:34:56Z ✅
- [x] **tester**: Lane 3 sign-off per cycle ~#3642H (review INDEX.md row, validate Pattern ID schema) — cmt 5026934557 ✅
- [ ] **dev**: implement 2 remaining gap pattern follow-up Issues (CI-OS-dep + network-dep) in Sprint 34+ P2 cluster (TIME_DEP REMOVED per §11 owner directive 2026-07-21)
- [ ] **orchestrator**: schedule Sprint 34+ P2 cluster with dev-claim (2 patterns, NOT 3)
- [ ] **PM**: refresh Sprint 34 plan addendum with 2 gap pattern Issues (NOT 3)
- [x] **owner**: squash-merge per ADR-0031 owner gate (this ADR is `docs/decisions/` = arch lane, NOT human-only) — SQUASHED ✅
- [x] **arch**: amendment PR for §2 TIME_DEP removal + new §11 (cycle ~#3968Q+71, owner directive 2026-07-21T09:57:47+03:00) — SQUASHED via PR #1196 1d21a32c 2026-07-21T08:30:06Z ✅ (cycle ~#3968Q+71+terminal; this hygiene PR cycle ~#3968Q+180+181)

## §11 — Considered + Rejected patterns (amendment 2026-07-21)

| ID | Pattern | Env-dep class | Status | Origin | Rejection rationale |
|---|---|---|---|---|---|
| `pattern:TIME_DEP` | Monotonic clock mock + bounded test window | time-of-day | ❌ owner-rejected 2026-07-21 | Issue #1186 AC5 24h soak | AC5 24h soak mechanic ABOLISHED per owner directive 2026-07-21T09:57:47+03:00; owner rejects BOTH the 24h soak AND any TIME_DEP-class d-test pattern (Issue #1181 closed; Issue #1186 kickoff gate REMOVED) |

**Rejection source**: owner directive 2026-07-21T09:57:47+03:00 (peer-poked via `notify.sh -w -r architect` to arch lane for §2 amendment). Captured at cycle ~#3968Q+71.

**DOCTRINE**: §2 purpose is "deferred for Sprint 33+ follow-up" — REJECTED ≠ DEFERRED → rejected patterns MUST be moved here for historical record preservation. Future patterns must follow the same cadence: REJECT = §11 entry with rationale + source.

**Cross-refs**: Issue #1181 (closed 2026-07-21 per owner), Issue #1186 (kickoff gate REMOVED 2026-07-21 per owner), Sprint 33 plan addendum (S33-007) UNTOUCHED per owner.

**Alternatives rejected for §11 placement**:
- (B) Remove TIME_DEP entirely without §11 entry — loss of historical record, sister-pattern failure vs ADR-0072 INDEX backfill pattern
- (C) KEEP TIME_DEP in §2 with explicit "owner-rejected" status — mixes DEFERRED vs REJECTED categories (bad doctrine)
- (D) Move TIME_DEP to a separate ADR (ADR-0075) — over-engineering for single-pattern rejection; §11 is the canonical home

**Sister-pattern**: cycle ~#3968Q+71 (this amendment), cycle ~#3671 RETRO-022 regression (reflexive agent:* ADD anti-pattern), cycle ~#3968Q+70 RETRO-024 false-positive (reflexive agent:* REMOVE anti-pattern) — both anti-patterns emphasize lane-discipline + categorization hygiene.

## Sister-pattern + cross-refs

- **Sister-ADR**: ADR-0072 (task-list persistence watchdog) + ADR-0074 (AC mapping verification doctrine)
- **Cycle sister**: cycle ~#3968Q+12 (PR #1189+#1192+#1194 supersede evolution pattern) — this ADR is Wave 10 P1 cluster (docs/sprints/souls lane)
- **Wave 10 P1 cluster**: Issue #201 (carry-over #9 of Issue #1171) + this ADR (Issue #1182 carry-over #9)
- **Lane**: architect (pattern + doctrine codification) + tester (test discipline review)
- **Amendment (cycle ~#3968Q+71)**: §2 TIME_DEP removal + new §11 (Considered + Rejected patterns) per owner directive 2026-07-21T09:57:47+03:00; Issue #1181 closed; Issue #1186 kickoff gate REMOVED

— @architect (Issue #1182 codification, cycle ~#3968Q+62, 2026-07-20T20:10Z; §2 TIME_DEP removal amendment, cycle ~#3968Q+71, 2026-07-21T10:05Z)
