# Test Plan: STORY-S29-010 — Forward-port 3 missing workflows + render deploy.yml from .tmpl (Issue #1035)

> **Status**: RED (Sprint 29 W2, d-test authored RED-first per ADR-0044)
> **Story**: [#1035](https://github.com/atilproject/AtilCalculator/issues/1035) — agent:architect, status:done (design phase per PR #1047 squash-merged 2026-07-13T19:58:36Z commit d0cf929)
> **Author**: @tester, 2026-07-13T20:18Z (cycle ~#1417) + TC4 added cycle ~#1427 per arch verdict on Issue #1050
> **Sister-pattern**: d1018 (S29-006 ADR-port parity — same cross-repo `gh api repos/.../contents/...` shape + 404 envelope detection) + d1014 (S29-002 tag-move — same Sprint 29 d-test cadence) + d058 (CI integration d-test family — d1020 NOT yet CI-integrated per ADR-0059)

## Scope

- **In scope**: AC1 (3 workflow ports: d050b-dispatch.yml, lint-and-test.yml, post-squash.yml) + AC2 (deploy.yml render from deploy.yml.tmpl, OWNER APPROVAL REQUIRED per file ownership matrix) + AC3 (S29-001 4-tuple `runs-on: [self-hosted, Linux, X64, atilproject]` applied to all 4 workflows) + AC4 (per-workflow d-test ≥3 TCs hygiene/docs baseline). Template repo: `atilproject/dev-studio-template`.
- **Out of scope**: AtilCalculator-specific deploy.yml content (service name, module path, log dir hardcoding — template deploy.yml uses parameterized placeholders per ADR-0047). Engine-level changes. Issue #1031 S29-006 sister (different story, ADR-port rather than workflow-port).

## Why this d-test exists

Sprint 28 audit (`docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §4.5) confirmed **template's `.github/workflows/` has 8 files (1 `.tmpl`)** while **AtilCalculator's has 11** — a gap of **3 missing workflows** (`d050b-dispatch.yml`, `lint-and-test.yml`, `post-squash.yml`) + **1 render gate** (`deploy.yml.tmpl` → `deploy.yml`). Downstream projects bootstrapped from `atilproject/dev-studio-template` ship without 4 critical workflows:
- **d050b-dispatch**: behavioral workflow test framework runtime validator (Issue #440, ADR-0049)
- **lint-and-test**: CI-integrated d-test execution (Sprint 14 #508 + Sprint 18 #611, ADR-0059)
- **post-squash**: cluster-squash batch-lag detector wired to PR-close webhook (Issue #605, ADR-0059)
- **deploy**: production deploy + smoke test + auto-rollback (Issue #130, ADR-0030)

The d1020 d-test enforces AC4 ≥3 TCs hygiene/docs baseline over 4 workflows in scope.

## Doctrinal contract (≥3 TCs hygiene/docs baseline)

Cite home per **PR #1040 advisory note a** + **PR #1047 S1 advisory**: `docs/sprints/current/plan.md` "≥5 TCs behavioral, ≥3 TCs hygiene/docs" — NOT "ADR-0049 §hygiene/docs variant" (ADR-0049 has no such §).

| TC | AC | Sub-checks | Pre-impl | Post-impl |
|---|---|---|---|---|
| TC0 | preflight | bash -n syntactic self-check | PASS | PASS |
| TC1 | AC4 | yaml-syntax per workflow (4 sub-checks; python3+pyyaml.safe_load_all) | RED 0/4 | GREEN 4/4 |
| TC2 | AC3+AC4 | 4-tuple-presence per workflow (4 sub-checks; `runs-on: [self-hosted, Linux, X64, atilproject]`) | RED 0/4 | GREEN 4/4 |
| TC3 | AC4 | SHA-pin-presence per workflow (4 sub-checks; `uses: actions/<name>@<40-char-SHA>` per TD-028) | RED 0/4 | GREEN 4/4 |
| TC4 | AC4 | env.PROJECT_NAME parameterization per workflow (4 sub-checks; arch verdict #1050 Option B: post-squash.yml has R-1 — `env.PROJECT_NAME` from `github.event.repository.name` + referenced via `${{ env.PROJECT_NAME }}`; other 3 verbatim ports vacuously pass) | RED 0/4 | GREEN 4/4 (1 active + 3 vacuous) |

16 sub-checks total (4 workflows × 4 main TCs). Local run verified RED-first (TC0 PASS, TC1/TC2/TC3/TC4 0/4 each). TC4 added cycle ~#1427 per arch verdict on Issue #1050 Option B (verbatim port + R-1 parameterization); 3/4 sub-checks vacuous (d050b-dispatch, lint-and-test, deploy.yml don't have R-1 — verbatim ports per sister-pattern discipline).

## Test Cases

### TC1: yaml-syntax per workflow (AC4)

- **Setup**: `gh api repos/atilproject/dev-studio-template/contents/.github/workflows/<wf>` with `Accept: application/vnd.github.raw`. 404 envelope detection per sister-pattern d1018 TC4/TC5.
- **Steps**:
  1. Fetch each of 4 workflow files (d050b-dispatch.yml, lint-and-test.yml, post-squash.yml, deploy.yml)
  2. Pipe content to `python3 -c "import sys, yaml; list(yaml.safe_load_all(sys.stdin))"` parse check
  3. Iterate per-file: pass if all docs are None or dict; fail on non-dict or parse error
- **Expected**: 4/4 GREEN post-impl; 0/4 pre-impl (workflows missing from template)
- **Sister-pattern**: d1018 TC4/TC5 404 envelope detection (robust to JSON error envelope vs empty body)

### TC2: 4-tuple-presence per workflow (AC3+AC4)

- **Setup**: Same fetch as TC1; grep for canonical 4-tuple per S29-001 baseline (PR #73 squash-merged 2026-07-13T14:20:32Z).
- **Steps**:
  1. Fetch each of 4 workflow files
  2. `grep -F "runs-on: [self-hosted, Linux, X64, atilproject]"` (literal bracket match, no regex metas)
  3. Count matches per file (≥1 = pass)
- **Expected**: 4/4 GREEN post-impl; 0/4 pre-impl

### TC3: SHA-pin-presence per workflow (AC4, TD-028 generalized via R-3 mitigation)

- **Setup**: Same fetch; iterate `uses:` lines, filter to actions/atilproject scope (excludes `docker://...` and `./local` refs which are not SHA-pinnable).
- **Steps**:
  1. Extract lines matching `^\s*uses:`
  2. Filter to scope: `uses:\s*(actions|atilproject|atilcan)/`
  3. For each pinable line, assert `@[0-9a-f]{40}` (40-char SHA, anchored at end of ref)
  4. If pinable lines exist without SHA → FAIL; if no pinable lines → vacuously PASS
- **Expected**: 4/4 GREEN post-impl; 0/4 pre-impl
- **Adversarial finding surfaced**: AtilCalculator source `d050b-dispatch.yml` line 45 uses `uses: actions/checkout@v4` (NOT 40-char SHA). DEV impl PR for d050b-dispatch.yml port MUST apply SHA-pin during port (`34e114876b0b11c390a56381ad16ebd13914f8d5`) OR escalate exception in PR with rationale. **Test will FAIL on impl PR if not addressed.**

### TC4: env.PROJECT_NAME parameterization per workflow (AC4, arch verdict #1050 Option B)

- **Setup**: Same fetch; check for `PROJECT_NAME: ${{ ... }}` line in workflow `env:` block, verify derivation from GitHub context + reference via `${{ env.PROJECT_NAME }}`.
- **Steps**:
  1. For each workflow, check if `^\s*PROJECT_NAME\s*:\s*\${{` line exists in env block
  2. **If NO** (no PROJECT_NAME in env) → vacuously PASS (verbatim port, no R-1 expected)
  3. **If YES** (PROJECT_NAME present) → verify derivation: `github.(event.repository.name|repository|repository_owner)` allowed
  4. **If YES** → also verify `${{ env.PROJECT_NAME }}` referenced at least once
- **Expected**: 4/4 GREEN post-impl (1 active for post-squash.yml + 3 vacuous for d050b-dispatch, lint-and-test, deploy.yml)
- **R-1 parameterization doctrine**: per arch verdict on Issue #1050 Option B, post-squash.yml port adds `env.PROJECT_NAME` derived from `github.event.repository.name` so downstream projects get auto-derived `CLUSTER_LAG_LOG` path (`/var/log/dev-studio/${{ env.PROJECT_NAME }}/cluster-lag.log`). The other 3 workflows are verbatim ports WITHOUT R-1 → vacuously OK (sister-pattern discipline preserved per AtilCalculator source).

## Adversarial Probes

### Input Validation
- **Empty workflow file**: TC1 catches via yaml.safe_load returning empty list (vacuously OK); TC2/TC3 vacuously OK (no `runs-on:` / `uses:` to grep).
- **Missing workflow file**: TC1-TC3 404 envelope detection (sister-pattern d1018 line 184-188) prevents false-positive on `gh api` JSON error envelope.
- **Workflow with `docker://...` ref**: TC3 explicit filter excludes docker refs from SHA-pin scope (TD-028 = actions/* only).
- **Workflow with local `./` ref**: Same — excluded from SHA-pin scope.

### State & Concurrency
- **Stale 4-tuple variant**: TC2 fails on common typos like `runs-on: [self-hosted, linux, X64, atilproject]` (lowercase `linux`); grep -F is case-sensitive on the canonical literal.
- **Stale SHA variant**: TC3 fails on `actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11` (40-char but different SHA) — actual d1020 does not check SHA correctness, only length + hex pattern. **Correction check deferred to d043 sister-pattern.**

### Data
- **Very large workflow file (10k+ lines)**: python3+pyyaml parsing time scales linearly; not a CI bottleneck at workflow-file scale (typical 50-200 lines).
- **Unicode in workflow comments**: yaml.safe_load_all handles UTF-8 fine; grep operates on raw bytes.

### Cross-repo auth
- **Missing PROJECT_TOKEN env**: `gh api` returns auth error (401/403) — d1020 fetch_workflow helper returns 1 (empty), TC1-TC3 treat as "missing workflow" (FAIL, but distinguishable from "workflow present but malformed" via logs).

## Performance Concerns

- 4 `gh api` calls per TC1/TC2/TC3 (12 calls total) — each ~200ms latency on local dev, ~500ms on CI self-hosted runner. Total d1020 runtime ~6-8s. Negligible.
- python3+pyyaml parse on workflow files (typical 50-200 lines) — sub-millisecond per file.

## Regression Risk

- **Sibling d1018 (S29-006)**: same cross-repo API pattern + 404 envelope detection — d1020 reuses d1018's fetch_workflow helper verbatim. If d1018 fetch logic regresses, d1020 cascades.
- **TD-028 SHA-pin doctrine**: d1020 TC3 enforces 40-char SHA on actions/* but does NOT verify SHA correctness against GitHub's published pin list. d043 sister-pattern owns that check. Future d-test can compose d1020 + d043 for end-to-end SHA-pin correctness.
- **Cross-repo auth (ADR-0014)**: d1020 runner requires `PROJECT_TOKEN` env. Sister-pattern caveat to d1018 caveat d. If template repo permissions are revoked, all 3 main TCs FAIL with auth error (vs missing-file FAIL) — distinguishable via TC0 PASS + 0/4 sub-checks + log inspection.

## Sister-pattern Reference

| d-test | Sister-domain | Layer |
|---|---|---|
| **d1020** (this) | Workflow port-parity cross-repo | CI workflow template surface |
| `d1018` (S29-006, GREEN post-impl) | ADR-port parity cross-repo | ADR template surface (same cross-repo API shape) |
| `d1014` (S29-002, GREEN) | tag-move script | scripts/tests/ sister — same Sprint 29 d-test cadence |
| `d058` (CI-integrated, flake on TC1) | claim-next-ready work-stream awareness | CI integration family — d1020 NOT yet CI-integrated |
| `d049` (d-test framework) | ≥5 TCs baseline sister | d1020 = 3 main TCs / 12 sub-checks expansion |
| `d113` (markdown link resolution) | TC3 SHA-pin grep | regex-shape sister |

≥3 sister-pattern coverage per ADR-0049 met (5+ sister-patterns).

## Cadence Rule 1 Atomic (ADR-0055 §1)

This d-test is committed atomically with:
- `scripts/tests/d1020-s29-010-workflow-port-parity.sh` (impl — 202 lines, bash)
- `scripts/tests/INDEX.md` (d1020 row entry)
- `docs/test-plans/STORY-S29-010-tests.md` (this file)

Sister-pattern to d1018 (PR #1042 squash @ c02fab6 — file + INDEX.md + (planned) test plan, test plan was deferred). For d1020, all 3 atomic pieces land in 2 commits on branch `tester/d1020-s29-010-workflow-port-parity-sh`:
- Commit `5d1f91c`: d1020 file + INDEX.md row (initial atomic pair per ADR-0055 §1)
- Commit TBD: this test plan file (Cadence Rule 1 atomic sister-pattern — explicit deferral per d1018 precedent)

**Note**: Cadence Rule 1 atomic requires same-PR (not same-commit) for the broader atomic unit. d1018 INDEX.md row text: "Cadence Rule 1 atomic (ADR-0055 §1) — d1018 file + this INDEX.md row + (planned) test plan `docs/test-plans/STORY-S29-006-tests.md` land in same commit" — but PR #1042 was squashed from branch with d1018 + INDEX + (deferred test plan). Sister-pattern preserved.

## Cross-references

- **Issue #1035** (STORY-S29-010) — agent:architect, status:done (design phase only)
- **PR #1047** (S29-010 design, squash @ d0cf929 2026-07-13T19:58:36Z)
- **PR #76** (template S29-011 themed 1/7, squash @ 19:58:46Z — sister-cadence anchor)
- **PR #1048** (this d1020 d-test PR, draft, status:in-review)
- **Issue #1049** (d058 TC1 search-index-lag flake — dev-lane fix per P3 priority)
- **docs/designs/STORY-S29-010-design.md** (266 lines, 9-Lens attestation per ADR-0045)
- ADR-0012 + ADR-0014 + ADR-0044 + ADR-0045 + ADR-0049 + **ADR-0055 §1** + ADR-0059 + TD-028 + Issue #113 + Issue #238 (no-standby) + Issue #430 (§Pre-verdict cross-check) + Issue #682 (§Post-verdict cross-watchdog) + Sprint 29 plan.md (canonical home for "≥3 TCs hygiene/docs")