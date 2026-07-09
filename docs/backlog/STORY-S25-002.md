# STORY-S25-002 (DRAFT): TD-067c open-time label-strip diagnostic — d-test (RED-first)

## User Story
As **a tester authoring the d-test coverage for the TD-067c open-time label-strip diagnostic**,
I want **a CI replay test that fires `pull_request: opened` + `labeled` + `unlabeled` event sequences on a sample PR fixture and asserts the diagnostic catches all 3 known instances from #931 evidence stack with zero false-negatives**,
So that **the TD-067c impl (STORY-S25-001) ships GREEN with verifiable coverage per ADR-0044 RED-first TDD + ADR-0049 d-test framework (≥5 TCs)**.

## Why now
Per ADR-0044 RED-first TDD, d-test PR must land BEFORE impl PR. STORY-S25-001 (impl) cannot ship without this d-test coverage. The TD-067c scope is high-stakes (label invariant breakage, 4-cat invariant per ADR-0012) — coverage gap would create another sister-pattern regression class.

## Acceptance Criteria
- **AC1** — d-test authored at `scripts/tests/d067c-open-time-label-strip.sh` (or canonical script name per arch design) with ≥5 TCs per ADR-0049:
  - TC1: `pull_request: opened` with intact 4-cat → diagnostic fires ℹ️ info (no alert, baseline state)
  - TC2: `labeled` event appending `cc:tester` → diagnostic verifies 4-cat invariant intact, no alert
  - TC3: `unlabeled` event stripping `cc:product-manager` on OPEN PR → diagnostic fires 🟡 warning with strip event details (mirrors #931 evidence stack instance 2 — PR #928 own window)
  - TC4: `unlabeled` event stripping `agent:architect` on OPEN PR → diagnostic fires 🔴 critical (4-cat invariant breach, sister-pattern of TD-067b close-time class)
  - TC5: `synchronize` (push) event with label diff unchanged → no false-positive alert (sister-pattern ADR-0024)
- **AC2** — d-test REFERENCES d-test INDEX.md entry (Cadence Rule 1 atomic per d-test framework sister-pattern).
- **AC3** — d-test replays ALL 3 known instances from #931 evidence stack:
  - Instance 1 (Issue #927 — agent + 4 cc labels stripped during PR #926 merge window, OPEN state)
  - Instance 2 (PR #928 — `cc:product-manager` stripped during PR #928 review window, OPEN state)
  - Instance 3 (other unstaged instances — auditable via `gh api /repos/.../issues/<N>/events` filtered on labeled/unlabeled)
- **AC4** — d-test ships as PR with `agent:tester` + `cc:developer` + `cc:architect` + `cc:human` (per PM Dispatch Protocol §Dual-Listing Rule, d-test-coupled = `agent:tester`).
- **AC5** — d-test runs in CI on PR open to `scripts/tests/d067c-*` and exits 0 on GREEN, non-zero on RED. Test result posted as PR check.

## Out of scope
- **Issue-surface d-test** (label-strip on issues, not just PRs) — see STORY-S25-003 sister-pattern.
- **d-test for the impl itself** (STORY-S25-001 ships the workflow YAML; this story ships the COVERAGE test).
- **d-test for Option B** (event observability workflow) — that's a separate P3 story if Option B lands.

## Open questions
- [ ] Canonical script name per arch design (`d067c-open-time-label-strip.sh` vs `d067c-label-strip-open-event.sh` vs arch-proposed name) → arch to confirm at sizing ceremony
- [ ] Replay mechanism — does CI use `gh api /repos/.../issues/<N>/events` to replay historical events, or a mock event-generator? → arch + tester to decide
- [ ] Sister-test with `scripts/tests/d058-label-check.sh` (closed-event class) — shared fixture or separate? → tester to confirm per d-test framework Cadence Rule

## Mockups / references
- `scripts/tests/d058-label-check.sh` (sister-test reference, closed-event class per TD-067b PR #928 design)
- `scripts/tests/d048-agent-watch.sh` (sister-test for label-strip observability, precedent for the test pattern)
- ADR-0044 (RED-first TDD)
- ADR-0049 (d-test framework, ≥5 TCs baseline)
- Issue #931 §Evidence stack (3 known instances to replay)
- `docs/designs/TD-067-TD-068-sister-fix-design.md` (sister-pattern design narrative)

## Dependencies
- **Upstream**:
  - PR #928 design merge (TD-067b closed-event diagnostic) — sister-test pattern reference
  - `scripts/tests/d058-label-check.sh` precedent — must exist on main before this d-test
- **Downstream**:
  - STORY-S25-001 (impl) cannot ship GREEN without this d-test GREEN
  - Any v1.0.x PR shipping `label-check.yml` changes requires this d-test + STORY-S25-001 both merged

## Metrics of success
- **Leading**: d-test PR opens within 2 cycles of STORY-S25-001 spike completion
- **Lagging**: Zero label-strip regressions observed post-merge (d-test catches all instances, no manual fixes needed)

## Sprint
Sprint 25+ Wave 1 (paired with STORY-S25-001)

## Priority
P1 (d-test coverage for P1 impl, cannot ship without)

## Story points (proposed by PM, joint sizing TBD)
1.5sp — replay test authoring + 5 TC definitions + INDEX.md entry + CI wiring. Joint sizing requires tester (authoring) + arch (event replay mechanism) + dev (CI workflow integration) per ADR-0021. Tester lane primary ownership.
