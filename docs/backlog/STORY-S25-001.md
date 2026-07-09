# STORY-S25-001 (DRAFT): TD-067c open-time label-strip diagnostic — workflow fix (Option A)

## User Story
As **a peer reviewer watching a PR lose `agent:*` / `cc:*` labels during open state** (PM, arch, dev, tester),
I want **a `label-check.yml` workflow job that fires on `pull_request: opened` + `labeled` + `unlabeled` events and alerts if 4-cat invariant breaks during OPEN state**,
So that **sister-pattern of the closed-event diagnostic (TD-067b) catches the regression class before PR merge, not at owner squash gate**.

## Why now
Issue #931 (TD-067c) recorded 3 known open-time label-strip instances (Sprint 24 Phase 3 cluster), with arch cmt 4924770275 confirming sister-pattern of TD-067b. Current `label-check.yml` runs only on `pull_request: closed` (PR #928 design). TD-067b's diagnostic will fire ZERO alerts on the open-time strip class — gap confirmed by arch hypothesis + evidence stack. P1 priority per arch filing; v1.0.1 deferral means TD-067c lands in Sprint 25+ Wave 1 scope.

## Acceptance Criteria
- **AC1** — GIVEN a PR with 4-cat invariant label set at `pull_request: opened`, WHEN any subsequent `pull_request: labeled` or `pull_request: unlabeled` event strips an `agent:*` or `cc:*` label while the PR is still OPEN, THEN a PR comment thread alert fires with the strip event (label name, before/after count, event timestamp).
- **AC2** — GIVEN a PR in OPEN state with full 4-cat invariant, WHEN a `pull_request: synchronize` (push) event fires, THEN no false-positive alert (the invariant may have transient diffs during push that don't break 4-cat invariant).
- **AC3** — GIVEN the TD-067b closed-event diagnostic already exists in `label-check.yml` (PR #928 merge-pending), WHEN TD-067c impl lands, THEN both diagnostics share a concurrency group + reuse TD-067b's workflow structure (sister-pattern compatibility per #931 §Architectural hypothesis).
- **AC4** — GIVEN a CI replay test (d-test ≥5 TCs per ADR-0049), WHEN the replay fires `pull_request: opened` + `labeled` + `unlabeled` event sequences on a sample PR, THEN all 3 known instances from #931 evidence stack are caught by the diagnostic with zero false negatives.
- **AC5** — GIVEN a PR where a maintainer intentionally resets a transient `agent:*` label via `/remove-label` comment command, WHEN the diagnostic fires, THEN the alert is downgraded to ℹ️ info-level (not 🟡 warning) — distinguish hostile strip from intentional reset (sister-pattern of TD-067b alert-path design).

## Out of scope
- **Issue-surface unification** (open-time strip on issues, not just PRs) — see STORY-S25-003 (observability bonus, P3, separate sister-pattern).
- **Root-cause confirmation** — the architectural hypothesis (label-strip source = status-label-to-board.yml mirror race, peer-poke.sh sequencing, or GitHub-native propagation delay) requires Sprint 25+ design phase to confirm. This story implements Option A (workflow fix) per #931 recommendation, NOT Option B (event observability).
- **Auto-remediation** — diagnostic alerts only; auto-restoration of stripped labels is out-of-scope (would require GitHub bot auth, separate ADR).
- **`status:ready` rate-limit false-positives** — if 4-cat invariant is broken at PR-open (e.g., `agent:developer` set but no `type:*` set), that's TD-067b's closed-event territory, not TD-067c's open-time territory.

## Open questions
- [ ] Will d-test ≥5 TCs cover ALL of (a) `pull_request: opened` with intact 4-cat, (b) `labeled` with 4-cat strip, (c) `unlabeled` with 4-cat strip, (d) `synchronize` no false-positive, (e) maintainer `/remove-label` info downgrade? → owner + arch to confirm at sizing ceremony
- [ ] Concurrency-group naming: reuse TD-067b's `concurrency-group: label-check-${{ github.event.pull_request.number }}` or fork? → arch to confirm
- [ ] `pull_request: reopened` event handling — does TD-067b's diagnostic handle it? If not, TD-067c should add it → arch to confirm

## Mockups / references
- Issue #931 (TD-067c filing body, arch hypothesis, 5 ACs)
- PR #928 design doc (`docs/designs/TD-067-TD-068-sister-fix-design.md`)
- TD-067 sister-pattern lineage (Issue #931 §Sister-pattern lineage table)
- ADR-0012 (4-cat label invariant)
- ADR-0024 (verdict-by:<ts> discipline — sister-pattern for label-strip diagnostics)
- cmt 4924770275 on PR #928 (arch side-finding origin)
- cmt 4924848456 on Issue #927 (arch P3 decision + P1 follow-up flag)

## Dependencies
- **Upstream**:
  - PR #928 merge (TD-067b design) — sister-pattern reference for workflow structure
  - PR #926 merge ✅ (TD-067 close-time fix at fb18c25 — already on main)
  - Issue #934 (TD-067b Part 2 impl — arch lane, owner squash gate)
- **Downstream**:
  - STORY-S25-002 (d-test, RED-first per ADR-0044, must land BEFORE impl lands GREEN)
  - TD-066 sister-pattern (Issue #929, P2, Sprint 25+ Layer 2/3)
  - Any v1.0.x PR shipping `label-check.yml` changes needs to wait for STORY-S25-001 merge

## Metrics of success
- **Leading**: d-test ≥5 TCs authored + GREEN by end of Wave 1 sprint
- **Lagging**: Zero new open-time label-strip instances observed post-merge for ≥30 days (alert volume = 0 in CI logs)

## Sprint
Sprint 25+ Wave 1 (TD family + observability)

## Priority
P1 (sister-pattern of TD-067 family regression class; arch self-flag at PR #928 review)

## Story points (proposed by PM, joint sizing TBD)
2sp — workflow YAML change + alert path reuse + d-test stub coordination. Joint sizing requires arch (workflow structure) + dev (impl) + tester (d-test RED-first) per ADR-0021.
