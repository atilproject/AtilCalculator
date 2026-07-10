# STORY-S26-003 (DRAFT): ADR-0019 amendment 5 — ATILCALC_EVALUATE_PERSIST env-var precedence contract (Issue #954 closeout)

## User Story

As **an operator running the engine on a self-hosted CI runner** (where mechanical disk IO is slow and `persistence.insert_record(...)` in the auto-persistence block of `POST /api/evaluate` bleeds into the arithmetic perf budget, surfacing as `test_arithmetic_p99_under_50ms_still_holds` FAIL p99 502-815ms over the 500ms ceiling at `BUDGET_MULTIPLIER=10.0`),
I want **a documented `ATILCALC_EVALUATE_PERSIST` env-var precedence contract (ADR-0019 amendment 5) that lets me disable auto-persistence on the perf-critical path with a single env-var override**,
So that **the arithmetic perf test stays green on self-hosted runners without requiring a `BUDGET_MULTIPLIER` raise — a permanent perf fix per the owner directive "kalıcı fix olsun" (Issue #954, P1, owner-approved Wave 1 full)**.

## Why now

- **Issue #954** filed 2026-07-10 by developer (cluster-cascade post-PR-#938). `test_arithmetic_p99_under_50ms_still_holds` FAILs on **3 open PRs** in CI: PR #946 (arch/TD-067c design, p99=814.78ms), PR #947 (test/d296, p99=502.52ms), PR #948 (test/d067c, p99=724.50ms). All over the 500ms ceiling (`BUDGET_MULTIPLIER=10.0 × 50ms`).
- **Local bench: PASS** (1/1 in 9.38s). The failure is **CI environment overhead (pytest-cov instrumentation + mechanical disk IO + cumulative multiplier)**, NOT a code regression. Same failure would appear on `main` itself per dev's PR #948 ground-truth verification.
- **Owner-approved Wave 1 full** per orchestrator peer-poke 2026-07-10T09:32:39+03: amendment ships in **Sprint 26**, not Sprint 27. This is a **permanent fix** (per owner directive 2026-07-01 "olur beklerim ama kalıcı fix olsun" originally given for the Sprint 23 PR #742 cluster — the same root cause class has resurfaced via Issue #954).
- **ADR-0019 amendment 5 is already drafted** (status: Proposed, dated 2026-07-01, drafted by architect in 9-lens review cycle ~#1942). Reused, not rewritten. The Sprint 26 work is **status flip Proposed → Accepted + impl gap closure + d-test RED-first** — not new ADR drafting.
- **Sister-pattern**: STORY-S26-001 (d296 d-test gap-closure, tester lane, 0.5sp post-Issue-#943 reconciliation) + STORY-S26-002 (canary config.yml, developer lane, 0.5sp). All three S26 stories together = 2.0sp, fits Sprint 26 capacity.

## Acceptance Criteria

- **AC1** — ADR-0019 amendment 5 PR opened by architect, status: `Proposed → Accepted` (per ADR-0012 status transitions, owner squash gate per file ownership matrix).
- **AC2** — `ATILCALC_EVALUATE_PERSIST` env-var implemented in `src/atilcalc/api/routes.py` per amendment 5 §Decision.1 (env-var precedence + 3-tier fallback) — **opt-out semantics** (NOT opt-in, per amendment 5 §"Why opt-out (NOT opt-in)?").
- **AC3** — GIVEN `ATILCALC_EVALUATE_PERSIST=false`, WHEN `POST /api/evaluate` is called, THEN `persistence.insert_record(...)` is **NOT** called (auto-persistence block at `src/atilcalc/api/routes.py:343` is skipped).
- **AC4** — GIVEN `ATILCALC_EVALUATE_PERSIST` is **unset**, WHEN `POST /api/evaluate` is called, THEN default behavior preserved (backward compat — auto-persistence ON, current behavior unchanged).
- **AC5** — GIVEN `ATILCALC_EVALUATE_PERSIST=garbage` (unparseable), WHEN the env var is read, THEN `ValueError` is raised immediately per ADR-0056 silent_skip doctrine (lens d) — fail-loud, no silent downgrade.
- **AC6** — d-test ≥5 TCs authored + GREEN (per ADR-0049 ≥5 baseline + ADR-0044 RED-first): (a) env-var unset → defaults-on (auto-persistence active), (b) env-var set to `"false"` → persistence skipped, (c) env-var set to `"true"` → persistence enabled, (d) unparseable env-var raises ValueError, (e) backward compat regression guard (test suite unchanged when env-var unset).
- **AC7** — Issue #954 perf drift resolved: `test_arithmetic_p99_under_50ms_still_holds` passes in CI on self-hosted runner with `ATILCALC_EVALUATE_PERSIST=false` override (cluster-cascade unblocker for PRs #946, #947, #948).
- **AC8** — Sister-pattern: amendment 5 reused as-is from Sprint 23 cycle ~#1942 (no doctrinal divergence; only status flip Proposed → Accepted + impl gap closure + d-test authoring).

## Out of scope

- **`BUDGET_MULTIPLIER` env-var amendment** — already covered by ADR-0019 amendment 4 conftest env-var precedence (separate concern, sister-pattern).
- **`SUBPROCESS_TIMEOUT_S` amendment** — sister-pattern to BUDGET_MULTIPLIER, also covered by amendment 4.
- **Sprint 27+ ADR-0019 amendment 6** — next amendment cycle, NOT in Sprint 26 scope.
- **`evaluate_endpoint` performance optimization beyond env-var gate** — would require engine re-architecture (e.g., async persistence, batched inserts), separate ADR.
- **Hardcoded-true default behavior** — amendment 5 is opt-OUT, not opt-in. Behavior preservation for the unset case is the contract per amendment 5 §Decision "What stays unchanged".
- **PR #742 re-merge** — Sprint 23 original carrier. Sprint 26 work uses amendment 5 as-is; PR #742 is historical reference only.
- **Engine-side lazy-persistence** (deferred-persist, write-behind cache) — separate architectural concern, not in amendment 5 scope.

## Open questions

- [x] Sprint 26 capacity check: 0.5sp (S26-001 reconciled) + 0.5sp (S26-002) + 1.0sp (S26-003 proposed) = 2.0sp total. Original Sprint 26 capacity 2.0sp (per Issue #941 §Scope). Confirmed fits. → owner confirmed via orchestrator peer-poke "Wave 1 full"
- [ ] Env-var parsing semantics: case-sensitive? Whitespace-trim? Empty-string treated as "unset" or "unparseable"? → architect to confirm at impl time (sister-pattern: amendment 4 conftest precedent at `tests/conftest.py:113-158`)
- [ ] d-test file: extend existing d949 (perf budget noise tolerance, 6 TCs GREEN per Issue #949/PR #951) with env-var TC, OR new d-test `d954-evaluate-persist-env-var.sh`? → tester to confirm at sizing
- [ ] CI workflow wiring: how does `ATILCALC_EVALUATE_PERSIST=false` get set in `.github/workflows/ci.yml` for the self-hosted runner path? → architect + dev to confirm (sister-pattern: amendment 4 conftest env-var precedence at `ci.yml` Test step)

## Mockups / references

- **Issue #954** — [Help] test_arithmetic_p99_under_50ms_still_holds FAIL on 3 PRs + env-specific perf drift post-mpmath integration (P1, dev-filed, arch decision = amendment 5 in Sprint 26)
- **ADR-0019 amendment 5** (already drafted): `docs/decisions/ADR-0019-amendment-5-evaluate-persist-env-var-gate.md` — full context, decision, rationale, consequences. Reused as-is.
- **ADR-0019 amendment 4** (sister-pattern, conftest env-var precedence contract): `docs/decisions/ADR-0019-amendment-4-conftest-env-var-precedence.md` — 3-tier canonical precedence chain (env var > runner detection > hardcoded map) + fail-loud ValueError contract. The `ATILCALC_EVALUATE_PERSIST` env-var gate uses the same contract.
- **ADR-0056** silent_skip doctrine (lens d — fail-loud over silent downgrade, used in AC5)
- **ADR-0017** §engine ↔ UI separation (the env-var gate preserves this — engine still has zero I/O, the API layer just doesn't call persistence on the perf-critical path)
- **ADR-0044** RED-first TDD (d-test authored BEFORE impl, AC6)
- **ADR-0049** d-test framework ≥5 TCs baseline (AC6)
- **ADR-0045** 9-Lens pre-publish gate (amendment 5 already passed cycle ~#1942)
- **ADR-0012** 4-cat label invariant
- **Issue #728** (Sprint 22 perf-regression origin, original owner directive "kalıcı fix olsun" 2026-07-01)
- **Issue #949 + PR #951** (adjacent scope: TestClient infra noise, MERGED 2026-07-10T05:48:18Z — sister-fix for infra-noise-tolerance, NOT for arithmetic perf)
- **PR #742** (Sprint 23 original carrier for amendment 5, may be re-opened or new PR opened for Sprint 26)
- **PR #945** (Sprint 26 grooming PM-curated, MERGED 2026-07-10T06:26:36Z) — sister-story `docs/backlog/STORY-S26-001.md` + `STORY-S26-002.md`
- **PR #946, #947, #948** (TD-067c design + d296 d-test + d067c d-test — cluster-cascade unblockers for this story)

## Dependencies

- **Upstream**:
  - Issue #954 (P1 bug, dev-filed, arch decision)
  - ADR-0019 amendment 5 (architect-drafted, status: Proposed, dated 2026-07-01)
  - PR #945 (Sprint 26 grooming, MERGED 2026-07-10T06:26:36Z — provides S26-001/S26-002 context)
  - Issue #941 (Sprint 26 Kickoff)
  - Sister-pattern: ADR-0019 amendment 4 (conftest env-var precedence contract)
  - PR #951 (TestClient infra noise sister-fix, MERGED 2026-07-10T05:48:18Z)
  - Issue #949 (resolved by PR #951 — adjacent scope, NOT arithmetic)
- **Downstream**:
  - PRs #946, #947, #948 — unblocked by `ATILCALC_EVALUATE_PERSIST=false` CI override (cluster-cascade resumes)
  - Story #931 (TD-067c) — PR #946 design closeout requires the perf bleed to be fixed
  - Sprint 26 plan.md (orchestrator lane, already published)
  - Issue #949 closure (orchestrator lane per ADR-0013)
  - Sprint 26 acceptance criteria #4 (v1.0.1 release published + canary mirror sync verified, Issue #941) — unblocked by Sprint 26 perf-cluster closeout

## Metrics of success

- **Leading**: ADR-0019 amendment 5 status: `Accepted` (PR merged by owner)
- **Leading**: `ATILCALC_EVALUATE_PERSIST` env-var gate impl merged + d-test ≥5 TCs GREEN
- **Leading**: Issue #954 closed (perf drift resolved)
- **Leading**: PRs #946, #947, #948 cluster-cascade unblocked (squash-chain resumes)
- **Lagging**: Zero new env-var-related bugs filed within 30 days post-merge (fail-loud contract holds)
- **Lagging**: `BUDGET_MULTIPLIER` returns to baseline (no further cascade bumps needed)

## Sprint

Sprint 26 (Wave 1 full, owner-approved 2026-07-10T09:32:39+03 per orchestrator peer-poke)

## Priority

P1 (per Issue #954 P1 + owner approval "Wave 1 full" + architect decision = amendment ships in Sprint 26)

## Story points (proposed by PM, joint sizing TBD)

1.0sp — ADR amendment 5 already drafted (no doctrinal work), env-var gate impl is small (~50-100 LoC in `src/atilcalc/api/routes.py` per amendment 5 §Decision.1), d-test standard (≥5 TCs, AC6). Sister to S26-001 reconciled 0.5sp — slightly larger due to env-var gate impl + d-test, fits in 1.0sp reclaimed capacity from S26-001 reconciliation (sprint total 2.0sp = original capacity).

Joint sizing requires architect (env-var contract) + developer (impl) + tester (d-test RED-first) per ADR-0021.
