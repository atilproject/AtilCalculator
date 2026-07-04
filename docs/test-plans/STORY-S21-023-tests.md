# Test Plan: STORY-S21-023 — Fresh-Clone Validation (≥2 clones, d-test reports)

> **Status**: TDD-RED draft (PM lane validation, ADR-0044 RED-first analog)
> **Story**: [#653](https://github.com/atilproject/AtilCalculator/issues/653) — agent:product-manager, status:in-progress (Sprint 21 Wave 5 / Sprint 24 W1 cluster post-PR #830 merge)
> **Author**: @product-manager, 2026-07-04T18:53Z (cycle post-#830 owner-squash-merge)
> **Lane**: PM (author + validator) + tester (sign-off on d-test reports per ADR-0044) + architect (d320+d124 ownership per Issue #798 RCA) + developer (d-test script impl if any)
> **Sister-pattern**: d124 (stale-verdict-filter-scope, Issue #798), d320 (stale-verdict-filter, Issue #798), d058 (claim-next-ready work-stream regression)
> **D-test target**: validation procedure uses **existing** d-tests d124 + d320 (PR #830 = ADR-0024 amendment acceptance test target); PM does NOT create new d-test impls — PM authors validation harness + captures reports

## Story origin

**Issue #653** (STORY-S21-023, Fresh-Clone Validation, 3sp carry from Sprint 21) — closed Sprint 21 with AC1+AC2+AC3 pending validation. Re-opened 2026-07-04 cycle ~#4243 as **PM lane owner-steward** per Sprint 24 §Outcome criteria verdict (owner verdict 2026-07-04T18:51:17Z): "(a) PM CLAIM".

> **Cluster context**: This validation is the **acceptance test for PR #830 (ADR-0024 stale-verdict-supersede)**, which closed Issue #828 (P2 bug) and unblocked Bug #827 cluster. PR #830 merged to main at 18:46:13Z (commit `0cb10b2`, owner squash per ADR-0031). The two d-test impls that gate PR #830's correctness — `d124-stale-verdict-filter-scope.sh` (8 TCs) and `d320-stale-verdict-filter.sh` (3 TCs) — must GREEN on **≥ 2 fresh clones** per AC1+AC2.

## Scope

### In scope

- **AC1 validation harness**: procedure to clone AtilCalculator to a throwaway workdir, run `bash scripts/dev-studio-init.sh`, run full d-test suite (with emphasis on d124 + d320), capture exit codes + report artifacts.
- **AC2 throwaway-repo harness**: procedure to create a fresh GitHub repo (`atilcan65/dev-studio-template-smoke`) with AtilCalculator as the source-of-truth, run init.sh + d-test suite, capture artifacts.
- **AC3 report-capture + attach**: procedure to harvest d-test stdout/stderr + exit-code matrices into canonical report files; attach to Sprint 21 close.md as evidence.
- **d124 + d320 acceptance gates**: explicit emphasis on these two d-tests (PR #830 acceptance) — **must both emit GREEN** on every fresh clone for AC1+AC2 to be valid.
- **Cross-clone diff verification**: tc ensures both clones emit identical d-test results (sister-pattern: d068 cross-clone agreement).

### Out of scope

- Production-usage clones (real downstream consumers) — Sprint 22+ per Issue #653 §Out of scope.
- Third-party clone adoption metrics — Sprint 22+ adoption metric per close.md §Adoption.
- New d-test script implementations (d124, d320 already exist; PM authors **validation harness only**).
- Performance benchmarking — validation = correctness, not perf (sister-pattern to STORY-S21-022 §Performance).
- Cross-OS compatibility (Linux/macOS) — Linux-only target per ADR-0017 + this story is Linux host validation.

## Acceptance Criteria mapping

| AC | Description | Test cases |
|---|---|---|
| **AC1** | PM runs `bash scripts/dev-studio-init.sh` on AtilCalculator copy → all d-tests pass | TC1, TC2 (d-test matrix GREEN, d124 + d320 emphasized) |
| **AC2** | PM creates throwaway repo `atilcan65/dev-studio-template-smoke` + runs init → all d-tests pass | TC3, TC4 (full GitHub round-trip + d-tests GREEN, d124 + d320 emphasized) |
| **AC3** | PM captures d-test reports from both clones, attaches to Sprint 21 close.md | TC5, TC6 (artifact harvest + canonical attach with content hash) |

## Test Cases

### TC1: AC1 — Local-clone validation harness (AtilCalculator copy)

**Setup**: clean tmp dir `${FRESH_CLONE_TMP}/local`; AtilCalculator source HEAD = `0cb10b2` (PR #830 merged).

**Steps**:
1. Copy AtilCalculator to tmp: `git clone --depth 1 https://github.com/atilproject/AtilCalculator.git ${FRESH_CLONE_TMP}/local`
2. Verify HEAD == `0cb10b2`: `cd ${FRESH_CLONE_TMP}/local && git rev-parse HEAD`
3. Verify clean working tree: `git status --porcelain | wc -l` → must be `0`
4. Run init: `bash scripts/dev-studio-init.sh` (no-arg = current dir)
5. Capture init exit code `${INIT_EXIT_LOCAL:?}` (must be `0`)
6. Verify rendered files exist: `.claude/CLAUDE.md`, `.claude/agents/orchestrator.md`, `CLAUDE.md`, `systemd/` (sample)
7. Run d-test matrix: `bash scripts/tests/d058-claim-next-ready-wip-workstream.sh > ${REPORT_LOCAL}/d058.stdout 2> ${REPORT_LOCAL}/d058.stderr; echo $? > ${REPORT_LOCAL}/d058.exit` (per d-test)
8. **Critical**: explicitly run d124 + d320 with same capture pattern
9. Aggregate: every d-test exit code in `${REPORT_LOCAL}/dtest-exit-matrix.txt`

**Expected**: `${INIT_EXIT_LOCAL}` = 0; **all d-tests GREEN** including `${D124_EXIT_LOCAL}` = 0 and `${D320_EXIT_LOCAL}` = 0. Sister-pattern: d058 §sister-test authorship; d068 cross-clone invariant.

### TC2: AC1 — d124 + d320 spec-correctness on local-clone

**Setup**: post-TC1 setup (local clone has d124+d320 d-test impls on disk).

**Steps**:
1. Read d124 source: `head -100 scripts/tests/d124-stale-verdict-filter-scope.sh`
2. Verify d124 declares ≥3 TCs (ADR-0049 baseline): `grep -cE '^### TC[0-9]+' scripts/tests/d124-stale-verdict-filter-scope.sh` ≥ 3 (actual = 8 per current source — well above baseline)
3. Read d320 source: `head -100 scripts/tests/d320-stale-verdict-filter.sh`
4. Verify d320 declares ≥3 TCs: `grep -cE '^### TC[0-9]+' scripts/tests/d320-stale-verdict-filter.sh` ≥ 3 (current = 3, exactly baseline)
5. Run d124 standalone: `bash scripts/tests/d124-stale-verdict-filter-scope.sh` → exit 0
6. Run d320 standalone: `bash scripts/tests/d320-stale-verdict-filter.sh` → exit 0
7. Sister-pattern check: `d012-stale-verdict-schema.sh` + `d319-verdict-by-tdd-red-exclusion.sh` both still GREEN (no regression)

**Expected**: Both d124 + d320 GREEN; sister-pattern d012 + d319 unchanged (regression guard). Sister-pattern lineage: d296/d319/d320 (peer-poke + verdict-by-RED-exclusion + stale-verdict-filter) family.

### TC3: AC2 — Throwaway-repo validation harness (full GitHub round-trip)

**Setup**: PM-owned personal GitHub namespace `atilcan65`; throwaway repo name `dev-studio-template-smoke` (per Issue #653 body §AC2).

**Steps**:
1. Pre-flight: verify repo does NOT pre-exist: `gh repo view atilcan65/dev-studio-template-smoke 2>&1 | grep -q 'Not Found'` → must succeed
2. Create throwaway repo: `gh repo create atilcan65/dev-studio-template-smoke --public --description "STORY-S21-023 AC2 fresh-clone validation harness"`
3. Add AtilCalculator as remote source: `git remote add template https://github.com/atilproject/AtilCalculator.git`
4. Push main branch: `git push template main --force` (single-branch minimal transfer)
5. Clone throwaway: `cd ${FRESH_CLONE_TMP} && git clone https://github.com/atilcan65/dev-studio-template-smoke.git remote`
6. Verify clean: `cd remote && git status --porcelain | wc -l` → 0
7. Verify HEAD == AtilCalculator `0cb10b2`: `git rev-parse HEAD`
8. Run init: `bash scripts/dev-studio-init.sh`
9. Capture init exit code `${INIT_EXIT_REMOTE:?}` (must be `0`)
10. Run full d-test matrix (same pattern as TC1 step 7-8)
11. **Critical**: d124 + d320 GREEN per `${D124_EXIT_REMOTE}` + `${D320_EXIT_REMOTE}`

**Expected**: `${INIT_EXIT_REMOTE}` = 0; full d-test matrix GREEN; specifically d124 + d320 = 0; GitHub round-trip preserved source HEAD (no drift). Sister-pattern: TC1 local-clone contract applied to GitHub round-trip.

### TC4: AC2 — Cross-clone agreement (d068 invariant)

**Setup**: post-TC1 + TC3 (both clones validated, d-test exit matrices captured).

**Steps**:
1. Diff d-test exit matrices: `diff ${REPORT_LOCAL}/dtest-exit-matrix.txt ${REPORT_REMOTE}/dtest-exit-matrix.txt` → must be empty (proves identical d-test behavior across clones)
2. Diff d124 stdout: `diff ${REPORT_LOCAL}/d124.stdout ${REPORT_REMOTE}/d124.stdout` → empty
3. Diff d320 stdout: `diff ${REPORT_LOCAL}/d320.stdout ${REPORT_REMOTE}/d320.stdout` → empty
4. Hash both clones' rendered outputs: `find . -type f -not -path './.git/*' | sort | xargs sha256sum | sha256sum > ${CLONE_HASH}` for each clone → must match
5. Sister-pattern assertion: identical rendered output + identical d-test results = identical behavior

**Expected**: All diffs empty; cloned hashes match. **This is the cross-clone agreement test** — proves the template is deterministic across clones (sister-pattern: d068 cross-clone invariant if exists, else ADR-0050 §init idempotency).

### TC5: AC3 — Report capture (artifact canonicalization)

**Setup**: post-TC1+TC3+TC4 (both clones validated + cross-clone agreement verified).

**Steps**:
1. Aggregate local-clone reports: `find ${REPORT_LOCAL} -type f -name '*.txt' -o -name '*.stdout' -o -name '*.stderr' | sort > ${REPORT_LOCAL}/ARTIFACT_INDEX.txt`
2. Aggregate remote-clone reports: same for `${REPORT_REMOTE}`
3. Generate combined report: `cat ${REPORT_LOCAL}/ARTIFACT_INDEX.txt ${REPORT_REMOTE}/ARTIFACT_INDEX.txt > ${COMBINED_REPORT_DIR}/ARTIFACT_INDEX.txt`
4. Hash artifacts for canonical attach: `cat ${COMBINED_REPORT_DIR}/ARTIFACT_INDEX.txt | xargs sha256sum > ${COMBINED_REPORT_DIR}/ARTIFACT_HASHES.txt`
5. Verify d124 + d320 explicitly captured: `grep -E 'd124|d320' ${COMBINED_REPORT_DIR}/ARTIFACT_INDEX.txt` → must list both (.stdout, .stderr, .exit)
6. Verify all d-test exit codes captured: `for d in scripts/tests/d*.sh; do basename "$d" .sh; done | sort > ${EXPECTED_DTEST_LIST}; diff ${EXPECTED_DTEST_LIST} <(grep -oE 'd[0-9]+[a-z]?-?[a-z]*' ${COMBINED_REPORT_DIR}/ARTIFACT_INDEX.txt | sort -u)` → empty

**Expected**: All d-test artifacts captured + indexed + hashed. Canonical attach-ready.

### TC6: AC3 — Sprint 21 close.md attachment (canonical evidence)

**Setup**: post-TC5 (artifacts harvested); Sprint 21 close.md path = `docs/sprints/sprint-21/close.md` (per ADR-0013 + repo layout).

**Steps**:
1. Locate close.md: `ls docs/sprints/sprint-21/close.md` → must exist
2. Append validation section: edit close.md to add `## STORY-S21-023 Fresh-Clone Validation Evidence` section with:
   - Headline: "≥ 2 fresh clones validated; d124 + d320 GREEN on both"
   - Embedded artifact index (from `${COMBINED_REPORT_DIR}/ARTIFACT_INDEX.txt`)
   - Cross-clone hash comparison: TC4 results
   - Per-clone init exit: `${INIT_EXIT_LOCAL}` = 0, `${INIT_EXIT_REMOTE}` = 0
   - Per-clone d124/d320 GREEN badges
3. Commit + PR the close.md update
4. Verify PR merged to main per ADR-0031 owner squash
5. Final check: `git log --oneline docs/sprints/sprint-21/close.md` shows commit referencing #653

**Expected**: close.md contains validation evidence section; PR merged; commit reference to #653 visible. Definition-of-Done sister-pattern per CLAUDE.md.

## Adversarial Probes (per tester doctrine)

### Input validation
- `${FRESH_CLONE_TMP}` non-existent dir → harness must `mkdir -p` first, not silent failure
- AtilCalculator HEAD != `0cb10b2` (e.g., on stale main) → harness must WARN + refuse to proceed (PR #830 acceptance invalid without PR #830 in HEAD)
- Throwaway repo `dev-studio-template-smoke` pre-exists → harness must cleanup or refuse (no clobber)

### Auth & Permissions
- `gh repo create` requires `repo` scope on `PROJECT_TOKEN` — harness must pre-flight check
- `git push --force` to personal namespace — must verify namespace is PM's (atilcan65) not org-wide
- No GitHub Actions on throwaway repo (intentional — we're testing manual local init, not CI)

### State & Concurrency
- Two PM sessions run TC1+TC3 in parallel → tmp dirs use `mktemp -d` unique names, throwaway repo creation is idempotent on `--force` push
- Init rerun on same clone (TC1 idempotency sister) → must succeed + match first-run hash
- Throwaway repo deleted mid-run → harness must error clearly, not silently

### Data
- Empty target dir → TC1 still works
- Target dir with 1000+ existing files (polluted) → init may error or work; harness captures result
- d124 + d320 source missing (corrupt clone) → harness must detect missing files, not skip TC2 silently
- Sprint 21 close.md missing → TC6 must error + open missing-close tracking issue (sister-pattern: d135)

## Performance Concerns

- TC1 (local clone + init + full d-test matrix): target < 5min wall time, include `time` reports in capture
- TC3 (GitHub round-trip + init + d-test matrix): target < 10min wall time (network-bound)
- TC4 (diff operations): must complete < 30s (file IO only)
- TC5+TC6 (report + close.md ops): target < 1min total

## Regression Risk

- **PR #830 (ADR-0024 stale-verdict-supersede) correctness** → TC2 explicit d124+d320 GREEN gate. If d124 fails, PR #830 acceptance is invalid (regression back to Issue #798 RCA pattern).
- **`scripts/dev-studio-init.sh` non-idempotency** → TC1 idempotency sister-check (rerun must produce no diff). Sister-pattern to STORY-S21-022 TC3.
- **Cross-clone non-determinism (init.sh $RANDOM/date/UUID usage)** → TC4 cross-clone hash must match. Sister-pattern to ADR-0050 §init idempotency guarantee.
- **Throwaway-repo namespace collision** → TC3 pre-flight check; orphan-throwaway from prior failed runs must be cleaned.

## Sister-patterns

- **d058** (claim-next-ready work-stream awareness) — TC1 d-test matrix structure (per-d-test stdout/stderr/exit capture) lifted from d058 §TC10.
- **d068** (cross-clone agreement, if exists) — TC4 directly mirrors cross-clone invariant contract.
- **d124 + d320** (PR #830 acceptance tests, Issue #798 RCA) — TC1/TC2/TC3 critical emphasis on these d-tests.
- **d296 + d319 + d012** (peer-poke + verdict-by-RED-exclusion + stale-verdict-schema sisters) — sister-pattern lineage invoked via d320 sister test authorship.
- **ADR-0044** (RED-first TDD) — d124 + d320 shipped RED pre-PR #830, GREEN post-merge; PM's TC1+TC3 re-validate.
- **ADR-0049** (d-test framework ≥3 sister-pattern baseline) — d124 (8 TCs) + d320 (3 TCs) both meet baseline; PM's TC1-TC6 (6 TCs) are validation TC not d-test impl.
- **ADR-0012** (4-cat label invariant) — #653 carries 4 labels (type:feature + agent:product-manager + cc:orchestrator + cc:human etc.) — validated at issue open, must persist through PR cycle.
- **ADR-0050** (init idempotency) — TC1 idempotency check + TC4 cross-clone hash sister-lineage.
- **Sprint 24 SCAFFOLD §Outcome criteria** — owner verdict 2026-07-04T18:51:17Z rendered PM as steward of #653; this test plan = PM's first authoritative artifact.

## Definition of Done

1. TC1+TC2+TC3+TC4+TC5+TC6 all GREEN
2. d124 + d320 GREEN on **both** clones (local + throwaway) — explicit non-negotiable acceptance
3. Cross-clone d-test matrix diff = empty (TC4)
4. Sprint 21 close.md contains validation evidence section (TC6)
5. close.md update PR merged to main per ADR-0031 owner squash
6. Throwaway repo `dev-studio-template-smoke` kept public post-validation as ongoing smoke-test anchor (or deleted, per owner preference — flag in PR body)
7. CI green on main post-merge
8. No new P0/P1 bugs filed against validation harness within 24h of merge

## Lane handoff sequence

1. **Pre-validation** (this doc): PM lane authors test plan + RED-state validation harness
2. **Implementation/dev-owner**: developer lane has zero direct impl — d124/d320 are arch lane (architect fixed per PR #830), tester signs off per sister-pattern
3. **Validation execution**: PM lane runs TC1+TC2+TC3+TC4+TC5+TC6 on local + throwaway clones
4. **Report generation**: PM lane produces ${COMBINED_REPORT_DIR}/ with all artifacts (TC5)
5. **close.md attach**: PM lane edits close.md + opens PR (TC6)
6. **Sign-off**: tester lane verifies d124+d320 GREEN on both clones per TC1+TC3, GREEN-flip attestation per ADR-0044
7. **Owner squash**: per ADR-0031, owner merges close.md update PR

## PM lane accountability (cycle post-#830 owner-squash-merge)

Per Sprint 24 SCAFFOLD §Outcome criteria verdict 2026-07-04T18:51:17Z (owner verdict "PM CLAIM"):

- PM is **author + validator** for this story per Issue #653 §Lane
- PM does **NOT** delegate validation to developer/tester (lane discipline, ADR-0049)
- PM does **NOT** unilaterally modify d124 + d320 source (out-of-lane; arch owns per ADR-0049)
- PM DOES author this test plan, run all 6 TCs, capture reports, attach to close.md
- WIP cap = 2 (ADR-0038 §Layer 2): #816 + #653 = at-cap; #653 = this claim

🤖 _Generated with [Claude Code](https://claude.com/claude-code) — 2026-07-04T18:53Z PM test plan authoring (cycle post-#830 merge, Issue #653 PM-steward verdict)_
