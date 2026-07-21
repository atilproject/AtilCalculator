# Sprint 34 Plan Addendum — 2 gap pattern Issues (CI_OS_DEP + NETWORK_DEP)

> **PM-authored from architect dual-channel wake** (Issue #1182 carry-over #9 of Issue #1171 sister chain to Issue #1191) per [ARCH→PM] dual-channel wake 2026-07-21T08:30:06Z (cycle ~#3968Q+275 TERMINAL — PR #1196 SQUASH-MERGED ✅, merge_sha 1d21a32c) + ADR-0073 §10 PM action item explicitly cited.
> **Trigger**: ADR-0073 §10 action item row 4 ("PM: refresh Sprint 34 plan addendum with 2 gap pattern Issues (NOT 3)") + ADR-0073 §11 TIME_DEP rejection (owner directive 2026-07-21T09:57:47+03:00).
> **Sprint 34 sizing:** 2 follow-up Issues (P2 cluster, NOT 3) — each M effort (d-test ≥6 TCs + INDEX.md row + CHANGELOG entry single commit per ADR-0055 §1 Cadence Rule 1 atomic + d-test ≥6 TCs per ADR-0049 baseline + Cycle ~#3471 ≥6 refinement).
> **Priority:** P2 (Sprint 34 P2 cluster — sister-pattern to Wave 10 P1 cluster which shipped Sprint 33)
> **Lane cluster:** Sprint 34 P2 cluster — paired with arch ADR-0073 §10 checkbox hygiene fix PR (cycle ~#3968Q+180 extension doctrine, separate lane docs/decisions/).

## User Story

As **a developer authoring an env-dep d-test fix PR in Sprint 34+**,
I want **two distinct gap pattern doctrines codified (CI_OS_DEP + NETWORK_DEP) per ADR-0073 §10 with their follow-up Issues pre-groomed (sizing + AC + d-test naming + dependencies + lane expectations)**,
So that **dev-claim per ADR-0038 §Auto-Claim has ready-to-pickup Issues with full PM acceptance criteria + 9-Lens compatibility from arch + Lane 3 d-test-only sign-off compatibility from tester, eliminating the per-sprint PM-grooming stall on gap pattern follow-ups**.

## Why now

PR #1195 SQUASH-MERGED @ 2026-07-21T06:34:56Z sha dedb0f6 (Wave 10 P1 docs anchor — ADR-0073 env-dep d-test sister-pattern + ADR-0072 INDEX backfill) + PR #1196 SQUASH-MERGED @ 2026-07-21T08:30:06Z sha 1d21a32c (ADR-0073 §2 TIME_DEP removal + new §11 Considered+Rejected — owner directive amendment) — Sprint 33 P2 carry-over #9 TERMINAL ✅ for Issue #1182 doctrine codification.

Per ADR-0073 §10 explicit action item row 4: **"PM: refresh Sprint 34 plan addendum with 2 gap pattern Issues (NOT 3)"**. Time_DEP was REMOVED from §2 per §11 rejection (owner directive 2026-07-21T09:57:47+03:00 — owner rejects BOTH the 24h soak AND any TIME_DEP-class d-test pattern). Therefore Sprint 34 P2 cluster = **2 patterns, NOT 3**.

Sister-pattern to Issue #201 (S33-007) carry-over #9 sister cluster — same PM lane (docs/sprints/**) + same dev-claim mechanism + same d-test naming cadence + same Lane 2 docs verdict chain. Both PM plan addenda are PM-owned territory (per file ownership matrix docs/sprints/ = orchestrator lane, but PM lane-discipline per Sprint 13 LOCKED + RETRO-007 watchlist entry #9 grants PM authorship of plan addenda when originating from architect dual-channel wake or owner directive).

Per cycle ~#3968Q+60 PM forward-planning acceptance verdict (PR #1195 Lane 2 chain 3/3): "3 gap-pattern deferral accepted + Sprint 34 plan addendum signal INTACT for PM lane work" — explicit lane chain mention in PR body ratifies PM forward-planning authority for Sprint 34 addendum authorship.

## Acceptance Criteria

### AC1 — 2 follow-up Issues filed in Sprint 34 P2 cluster

- [ ] **Issue A — pattern:CI_OS_DEP** — Multi-OS matrix OR explicit `--target-os` override for env-dep d-tests (origin: d058 TC1 env-rot classification per cycle ~#3853)
  - Sizing: M (d-test ≥6 TCs + INDEX.md row + CHANGELOG entry + multi-OS matrix workflow OR explicit override mechanism per arch advisory)
  - Lane: developer (impl in `scripts/tests/d*.sh`) + architect (9-Lens on multi-OS matrix doctrine if `.github/workflows/` change) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H)
  - Sister-pattern: d058 TC1 (`/var/log/dev-studio/AtilCalculator/d058.env-rot.log`)
  - Owner squash gate: per ADR-0031 (CI infra territory if workflow change; scripts territory if env-only)
  - Out of scope: permanent fix to GitHub Actions multi-OS matrix (architect + owner decision per file ownership matrix `.github/workflows/` = human-only)
  - Acceptance: AC1a d-test GREEN on both `ubuntu-latest` AND `macos-latest` runners OR explicit `--target-os` override flag with ≥6 TCs covering each runner class
  - Acceptance: AC1b `scripts/tests/INDEX.md` row added per ADR-0055 §1 Cadence Rule 1 atomic, citing `pattern:CI_OS_DEP` ID per ADR-0073 §3 schema
  - Acceptance: AC1c `CHANGELOG.md` entry same commit (`feat(scripts): Sprint 34 P2-001 — pattern:CI_OS_DEP multi-OS matrix override`)
  - Acceptance: AC1d Lane 2 docs verdict chain (arch + tester) + owner squash per ADR-0031

- [ ] **Issue B — pattern:NETWORK_DEP** — Mock layer + RECONCILE_LIVE_TOKEN env toggle for env-dep d-tests (origin: cycle ~#3642B REST fallback partial — REST fallback ONLY, NOT mock-first)
  - Sizing: M (d-test ≥6 TCs + INDEX.md row + CHANGELOG entry + mock layer per ADR-0056 silent_skip fail-loud)
  - Lane: developer (impl in `scripts/tests/d*.sh`) + architect (9-Lens on mock-first doctrine) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H)
  - Sister-pattern: cycle ~#3642B REST fallback pattern (`gh api .../comments` for GraphQL exhaustion — sister-extend with mock-first + live-reconcile)
  - Owner squash gate: per ADR-0031 (scripts territory)
  - Out of scope: production HTTP client mock library adoption (separate ADR if pattern graduates beyond d-test scope)
  - Acceptance: AC2a d-test ≥6 TCs covering: TC1 mock-first default (no live token), TC2 RECONCILE_LIVE_TOKEN=1 enables live API call, TC3 silent_skip log emission per ADR-0056 when mock active, TC4 network-down mock fallback (mock returns canned payload), TC5 rate-limit detection (mock 429s + retry), TC6 token-rotation mid-test (mock handles gracefully)
  - Acceptance: AC2b `scripts/tests/INDEX.md` row added per ADR-0055 §1 Cadence Rule 1 atomic, citing `pattern:NETWORK_DEP` ID per ADR-0073 §3 schema
  - Acceptance: AC2c `CHANGELOG.md` entry same commit (`feat(scripts): Sprint 34 P2-002 — pattern:NETWORK_DEP mock-first + RECONCILE_LIVE_TOKEN toggle`)
  - Acceptance: AC2d Lane 2 docs verdict chain (arch + tester) + owner squash per ADR-0031

### AC2 — Addendum authored in `docs/sprints/sprint-34/00-plan-pm-addendum.md`

- [ ] Single-file PM plan addendum authored via worktree (cycle ~#3673 branch contamination pre-commit doctrine honored — isolated from arch's `docs/adr-0073-section-10-checkbox-hygiene` branch)
- [ ] Cadence Rule 1 atomic: addendum + this CHANGELOG.md entry same commit per ADR-0055 §1
- [ ] 4-cat label invariant on resulting PR per ADR-0012: `type:docs` + `status:ready` (after Lane 2 docs verdict chain) + `agent:product-manager` + `cc:human` + `cc:architect` + `cc:developer` + `cc:tester` + `cc:orchestrator` + `sprint:current` + `priority:P2`

### AC3 — Lane 2 docs verdict chain (PM-owned PR, sister-pattern to PR #1194 cycle ~#3968Q+24)

- [ ] arch 9-Lens 🟢 APPROVED (ADR-0045) per cycle ~#3674
- [ ] tester Lane 2 docs verdict 🟢 APPROVED per cycle ~#3675
- [ ] PM acceptance (implicit per Lane 2 docs verdict chain pattern — PM IS author, no self-verdict required)
- [ ] Owner squash gate per ADR-0031 (docs/sprints/ = orchestrator lane + PM authorship accepted = human squash)

### AC4 — Follow-up Issues auto-claimable per ADR-0038 §Layer 2

- [ ] Issue A + Issue B filed with `agent:developer` + `cc:developer` + `status:backlog` + `priority:P2` + `pattern:CI_OS_DEP` / `pattern:NETWORK_DEP` labels
- [ ] Auto-claim eligible for dev lane on next claim-next-ready.sh poll
- [ ] No `cc:human` (NOT work-done-elsewhere per RETRO-024 — these are forward work, not cross-repo terminal state)

## Out of scope

- **TIME_DEP gap pattern** — REJECTED per ADR-0073 §11 (owner directive 2026-07-21T09:57:47+03:00). Owner rejects BOTH the 24h soak AND any TIME_DEP-class d-test pattern. Do NOT file Issue C.
- **Multi-OS matrix permanent workflow change** — `.github/workflows/` = human-only territory per file ownership matrix. If Sprint 34 P2-001 Issue A requires `.github/workflows/lint-and-test.yml` change, escalate to architect + owner (separate ADR if pattern graduates beyond d-test scope).
- **Production HTTP client mock library adoption** — separate ADR if Sprint 34 P2-002 Issue B graduates beyond d-test scope.
- **Cycle ~#2919 doctrine amendment** — separate workstream (Task #20 pending, deferred to post-Sprint 33 W1 close). Partial-Closes title-text protection gap is a different problem class.

## Open questions

- [ ] **Architect**: confirm `pattern:CI_OS_DEP` impl approach (multi-OS matrix workflow addition vs `--target-os` override flag in d-test scripts). ADR-0073 §5 already deferred multi-OS matrix doctrine; this Issue is the follow-up. Recommend explicit override flag (lower infra change cost) but defer to arch 9-Lens.
- [ ] **Developer**: confirm d-test naming cadence (`d-sprint34-p2-001-ci-os-dep.sh` long form vs `d-ci-os-dep.sh` short form per d058/d068b sister-pattern). Defer to dev preference.
- [ ] **Developer**: confirm RECONCILE_LIVE_TOKEN env-var name (vs `LIVE_TOKEN_ENABLED` vs `NETWORK_LIVE=1` — different naming conventions exist in scripts/). Defer to dev preference + arch advisory.
- [ ] **Orchestrator**: confirm Sprint 34 P2 cluster-squash timing (W1 close per ADR-0059 vs mid-sprint vs W2). Both issues are dev-claim eligible immediately after PM addendum merges. Defer to orch WIP cap judgment.
- [ ] **Tester**: confirm Lane 3 d-test-only sign-off pattern (cycle ~#3642H byte-equal sufficient for env-dep d-test impl PRs) applies, OR escalate to full Lane 2 docs verdict chain.

## Dependencies

- **Upstream**: PR #1195 SQUASH-MERGED ✅ (ADR-0073 codification), PR #1196 SQUASH-MERGED ✅ (ADR-0073 §2 TIME_DEP removal + §11 Considered+Rejected). Both pre-conditions MET — Sprint 34 P2 cluster is unblocked.
- **Sister-pattern**: Issue #201 (S33-007) carry-over #9 cluster (PR #1194 + tmpl-side PR #202) — both SHIPPED. Same d-test naming + same Cadence Rule 1 atomic + same Lane 2 docs verdict chain apply.
- **Sister-pattern**: RETRO-022 / Issue #1023 (reflex-class damage doctrine) — additive only, no carry-over impact.
- **Doctrinal home**: ADR-0073 §10 action item (this addendum is the PM-side execution); ADR-0073 §11 (TIME_DEP rejection source); ADR-0073 §3 (pattern ID schema); ADR-0073 §4 (--self-test gate transition); ADR-0073 §5 (multi-OS matrix deferred = Issue A scope); ADR-0073 §6 (update discipline); ADR-0073 §7 (tester-lane rejection criteria).

## Metrics of success

- **Leading**: Issue A + Issue B filed in Sprint 34 P2 with full ACs + d-test naming + lane expectations pre-populated.
- **Leading**: Dev lane auto-claim eligible per ADR-0038 §Layer 2 immediately after PM addendum PR squash.
- **Leading**: 4-cat label invariant on Issues + addendum PR per ADR-0012 (verified by `.github/workflows/label-check.yml`).
- **Lagging**: Both issues reach terminal state (squash-merged + Closes anchor wired) by Sprint 34 close.
- **Lagging**: pattern:CI_OS_DEP + pattern:NETWORK_DEP rows in `scripts/tests/INDEX.md` cited per ADR-0073 §3 schema.

## Sizing

- **Hint**: 2 issues × M effort = 6 SP total (per Sprint 33 sizing precedent: S33-007 = 3 SP M; S33-003 = 3 SP M; S33-005 = 3 SP).
- **Final**: 6 SP (2 × M — consistent with Sprint 33 P2 cluster sizing).

## Lane

- **Author (addendum)**: @product-manager (this addendum)
- **Reviewer (addendum)**: @architect (9-Lens per ADR-0045) + @tester (Lane 2 docs verdict per cycle ~#3675)
- **Co-CC (addendum)**: @orchestrator (sprint cadence) + @human (owner squash gate per ADR-0031 — docs/sprints/ = orchestrator lane but PM authorship accepted)
- **Issue A author**: @developer (impl + d-test + INDEX.md + CHANGELOG per Cadence Rule 1 atomic)
- **Issue A reviewer**: @architect (9-Lens on multi-OS matrix doctrine if `.github/workflows/` change) + @tester (Lane 3 d-test-only sign-off per cycle ~#3642H)
- **Issue B author**: @developer (impl + d-test + INDEX.md + CHANGELOG per Cadence Rule 1 atomic)
- **Issue B reviewer**: @architect (9-Lens on mock-first doctrine) + @tester (Lane 3 d-test-only sign-off per cycle ~#3642H)
- **Owner squash gate**: per ADR-0031 (addendum = docs/sprints/ = human-only; Issue A impl = scripts = human-only if no workflow change; Issue B impl = scripts = human-only)

## Sprint 34 Context

- **Epic**: E11 — Env-dep d-test pattern graduation (sister-pattern to E10 doctrine refresh)
- **Wave**: Sprint 34 W1 (foundation) — gap pattern follow-ups from Sprint 33 P2 cluster TERMINAL ✅
- **Source-of-truth**: ADR-0073 §10 action item row 4 + ADR-0073 §11 TIME_DEP rejection + PR #1195 SQUASH-MERGED + PR #1196 SQUASH-MERGED + [ARCH→PM] dual-channel wake 2026-07-21T08:30:06Z
- **Sister-pattern**: Issue #201 (S33-007) carry-over #9 cluster (PR #1194 + tmpl-side PR #202) — both SHIPPED cycle ~#3968Q+55
- **Sister-pattern**: ADR-0073 §1 sister-pattern inventory (8 patterns) — Issue A + Issue B will be added as patterns #9 + #10 in subsequent ADR-0073 amendment if both reach terminal state in Sprint 34
- **Sister-pattern**: Issue #1191 (carry-over #8) + Issue #201 (carry-over #9) Wave 10 P1 cluster — same PM-lane forward-planning pattern

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
