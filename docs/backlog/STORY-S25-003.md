# STORY-S25-003 (DRAFT): TD-067c sister-pattern — Issue-surface label-strip observability (P3 bonus)

## User Story
As **a label-strip diagnostic maintainer**,
I want **the TD-067c diagnostic to ALSO fire on `issues: opened` + `labeled` + `unlabeled` events on the Issue surface (not just PR surface)**,
So that **the sister-pattern regression class catches label-strip on issues too** (per Issue #931 §Sister-pattern observability bonus, out-of-scope but worth noting).

## Why now
Issue #931 body §Recommendation explicitly notes: "the SAME pattern likely affects `issue:` events too. Sprint 25+ design phase should consider unified label-strip observability across PR + Issue surfaces." This is a P3 sister-pattern, separate from STORY-S25-001/002 (P1 PR-surface coverage). It's the natural follow-up once PR-surface lands and proves the pattern.

## Acceptance Criteria
- **AC1** — GIVEN a GitHub Issue with 4-cat invariant label set at `issues: opened`, WHEN any subsequent `issues: labeled` or `issues: unlabeled` event strips an `agent:*` or `cc:*` label while the issue is OPEN, THEN the same diagnostic from STORY-S25-001 fires (with sister-test pattern from STORY-S25-002 extended to `gh api /repos/.../issues/<N>/events`).
- **AC2** — GIVEN the PR-surface TD-067c diagnostic lands GREEN, WHEN Issue-surface extension ships, THEN both share the same workflow YAML with parameterized event triggers (PR vs Issue), no workflow duplication.
- **AC3** — d-test extends STORY-S25-002 with 2 additional TCs (TC6 Issue-surface labeled with strip, TC7 Issue-surface unlabeled with strip).
- **AC4** — Post-merge, both PR + Issue surfaces have parity label-strip observability — single dashboard / single alert path.

## Out of scope
- **Comment-event observability** (label-strip via PR review comment edits) — out-of-scope, separate sister-pattern if observed.
- **Auto-remediation** — same as STORY-S25-001 §Out of scope.
- **Cross-repo observability** (canary mirror, future PIVOT infrastructure) — deferred to v1.1 per Issue #931 deferred scope.

## Open questions
- [ ] Should this ship SAME PR as STORY-S25-001 (combined PR) or SEPARATE PR (sequential)? → arch + owner to decide at sizing ceremony
- [ ] Workflow event trigger parameterization syntax (`on: { pull_request: {...}, issues: {...} }`) — YAML pattern? → arch to confirm
- [ ] Sister-test pattern — extend `d067c-open-time-label-strip.sh` with Issue-surface TCs, or new `d067c-issue-surface.sh`? → tester to decide per d-test framework Cadence Rule

## Mockups / references
- Issue #931 §Sister-pattern observability bonus (origin)
- STORY-S25-001 (PR-surface impl, primary)
- STORY-S25-002 (PR-surface d-test, primary)
- cmt 4924770275 on PR #928 (arch side-finding origin — Issue-surface hypothesis noted there)

## Dependencies
- **Upstream**:
  - STORY-S25-001 (PR-surface impl) merged — workflow structure reference
  - STORY-S25-002 (PR-surface d-test) merged — sister-test pattern reference
- **Downstream**:
  - Any v1.0.x PR shipping `label-check.yml` changes needs all 3 STORIES + their d-tests merged

## Metrics of success
- **Leading**: Issue-surface ships same sprint as PR-surface (or +1 sprint if deferred)
- **Lagging**: Zero new label-strip regressions observed on either surface post-merge for ≥30 days (alert volume = 0 in CI logs)

## Sprint
Sprint 25+ Wave 1 (paired with STORY-S25-001/002 if combined-PR, else Sprint 25 Wave 2)

## Priority
P3 (sister-pattern bonus, can defer to Wave 2)

## Story points (proposed by PM, joint sizing TBD)
0.5sp — workflow YAML extension + 2 TC additions + d-test extension. Joint sizing requires arch (event trigger parameterization) + dev (impl) + tester (d-test extension).
