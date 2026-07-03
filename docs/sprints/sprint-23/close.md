# Sprint 23 Close-Out — Cluster-Squash Closure + Sprint 21 Carry-Over Execution (cycle ~#3435 PRE-DRAFT)

> **Status:** 📝 **PRE-DRAFT** (cycle ~#3435, 2026-07-03) — pending owner verdicts on Issue #769 (3 categories) + Issue #740 close-out + 3 docs PR squash. Will be finalized post-#778/#779/#780 squash wave + owner verdict cascade.
>
> **Author:** orchestrator (pre-draft, awaiting owner verdicts + post-squash state)
> **Source:** Sprint 23 plan (PR #780, frozen cycle ~#3070 author) + cluster-squash closure (cycle ~#3417) + Issue #740 PM disposition + Issue #769 PM disposition

## Sprint 23 at a glance

| Metric | Value | Source |
|---|---|---|
| Sprint dates | 2026-06-30 → 2026-07-13 (2 weeks) | plan.md §Sprint window |
| Sprint mode | Cluster close + Sprint 21 carry-over execution (post-Sprint 22 PIVOT close-out) | plan.md §Sprint goal |
| Capacity | ~32sp (owner ASAP accepted) | plan.md §Committed stories |
| Stories committed | 9 (8 dev lane + 1 PM lane) | plan.md §Committed stories |
| Cluster-squash closure | **5/5 PRs squash-merged cycle ~#3417** | this file §Cluster-squash closure |
| Sprint 21 carry-over closure | **4/4 PRs squash-merged** | this file §Sprint 21 carry-over |
| Sprint 23 dev cluster closure | **8/8 stories CLOSED** | this file §Sprint 23 dev cluster |
| Critical fixes (this session) | 3 (rebase + cross-PR link + inverse link) | this file §Critical fixes |

## Cluster-squash closure (5/5 cycle ~#3417, 2026-07-03T16:00:31Z)

| # | PR | Squash SHA | Merged | Purpose | Cluster role |
|---|---|---|---|---|---|
| 1 | #772 | 1c79f28 | 2026-07-03T15:09:15Z | RCA-20 scripts/run-server.sh uv-run venv missing uvicorn --extra web (Closes #771) | dev impl+d122 atomic |
| 2 | #764 | 2d3d926 | 2026-07-03T15:22:38Z | RCA-17 AC4 user fix `${ATC_SERVICE_USER:-$USER}` (refs #763) | dev fix |
| 3 | #775 | 14f87e1 | 2026-07-03T15:27:25Z | d121 cross-user env-var pattern d-test (refs #774 + #764) | sister-pattern d-test |
| 4 | #770 | 48f8a12 | 2026-07-03T16:00:19Z | Sprint 24 candidate mapping + 9 decom-pending + #653 carry (refs #767) | PM contribution FIRST |
| 5 | #773 | 60d234f | 2026-07-03T16:00:30Z | ADR-0064 cross-user env-var pattern (Closes #765 + RCA-17 codification) | arch ADR |

**Auto-closes via Closes anchors**: Issue #771 (PR #772), Issue #765 (PR #773)
**Manual close**: Issue #774 (refs not Closes, PR #775)

## Sprint 21 carry-over closure (4/4)

| # | PR | Squash SHA | Purpose |
|---|---|---|---|
| 1 | #694 | d9c4d3d | d093 TEMPLATE-README polish regression guard (S21-019 AC1+AC2+AC3) |
| 2 | #704 | 323f62f | d070 template-render regression guard (Closes #637) |
| 3 | #679 | (squash cycle #3067) | d069 verdict-emoji-gate workflow (Issue #666 supersede) |
| 4 | #738 | (squash cycle #3411) | d094→d097 rename + Lint&Test fix (Issue #724 slot collision) |

## Sprint 23 dev cluster (8/8 CLOSED)

| Story | Pre-condition (per plan.md) | Closed via |
|---|---|---|
| #633 (S21-019 ONBOARDING.md) | d093 shipped via PR #694 | PR #694 squash |
| #636 (S21-003a) | d070a | PM hygiene cycle ~#3228+ |
| #693 (S21-003b) | d070b | PM hygiene cycle ~#3228+ |
| #635 (S21-005) | d091 | PM hygiene cycle ~#3228+ |
| #639 (S21-007) | d083 sister-pattern d090 | PM hygiene cycle ~#3228+ |
| #651 (S21-004) | d080 cross-lane ci.yml (owner pre-approval) | PR #742 env-var gate |
| #638 (S21-006) | d082 AC4 owner pre-approval .claude/ | PM hygiene cycle ~#3228+ |
| #724 (d094 slot collision) | rename to d097 | PR #738 squash |

**Sprint 23 dev lane workhorse**: PR #742 (d117 Sprint 23 env-var gate, squash cycle ~#3417, 294d809629)

## Sprint 23 docs PRs (3 pending owner squash — cycle ~#3435)

| # | PR | Head SHA | Status | Purpose |
|---|---|---|---|---|
| 1 | #778 | 47a93bd | status:ready, mergeable=True, all 5/5 CI green | Sprint 22 PIVOT close-out (orphan-shipping) |
| 2 | #780 | 866d087 | status:ready, mergeable=True, all 5/5 CI green | Sprint 23 plan ship (frozen cycle ~#3070 record) |
| 3 | #779 | b292f3a | status:ready, mergeable=True, all 13/13 CI green | Sprint 24 plan scaffold (SCAFFOLD — owner-verdict advisory) |

**Merge order forced by cross-PR link resolution**: #778 → #780 → #779

## Critical fixes this session (cycle ~#3429-#3431, 3 fixes in 4 min)

### Fix 1: PR #778 rebase gap (cycle ~#3429)

PR #778 branched from stale main `8d9540b` (pre-cluster-squash). vs origin/main (`60d234f`), PR #778 would have DELETED on squash:
- docs/backlog.json (-222 lines, PR #770 refresh)
- docs/decisions/ADR-0064-cross-user-env-var-pattern.md (-298 lines, PR #773 ADR)
- docs/decisions/INDEX.md (-1 line)
- 3 docs/sprints/sprint-23/observations/cycle-3349/3359/3363-...md (-404 lines)
- docs/tech-debt.md (-4 lines)

**Total**: -929 lines would have been reverted on squash.

**Fix**: `git merge origin/main` into docs/sprint-22-close-shipping + force-push. Post-fix: head_sha=`7965610`, base=`60d234f`, 1 file +139 lines.

### Fix 2: PR #780 forward cross-PR link (cycle ~#3430)

PR #780 Lint & Test FAILURE on markdown link `close.md shipped → ../sprint-22/close.md` referencing PR #778 content (not on PR #780 branch).

**Fix**: commit `866d087` replaces markdown link with PR reference `see PR #778`. Force-pushed. All 5/5 CI green.

### Fix 3: PR #778 inverse cross-PR link (cycle ~#3431)

PR #778 Lint & Test FAILURE on inverse markdown link `../sprint-23/plan.md → ../sprint-23/plan.md` referencing PR #780 content (not on PR #778 branch).

**Fix**: commit `47a93bd` replaces markdown link with PR reference `PR #780 (ships post-this-PR)`. Force-pushed. All 5/5 CI green.

## Outstanding owner verdicts (cycle ~#3435, advisory pending)

### Issue #769 — Sprint 24 backlog lane commitments (3 categories)

1. **9 decommission candidates** (#634, #640, #641, #643, #644, #646, #647, #650, #654) — PM rec: CLOSE all (cycle ~#3228 lens audit confirms coverage by existing artifacts)
2. **#653 lane transfer** (tester → PM) — PM rec: PM lane (Fresh-Clone Validation is operational, not d-test impl per ADR-0044)
3. **#649 partial-coverage** — PM rec: Keep 0.5sp (Smoke Test Script gap-closure)

### Issue #740 — Sprint 21 backlog hygiene + Sprint 24 candidate mapping

PM Option (a) close-out proposal cycle ~#3384, STRENGTHENED cycle ~#3390 + ORCH peer observation cycle ~#3425 (cid 4877990954). All IMMEDIATE actions resolved via cluster-squash.

### Owner merge queue

- PR #778 (Sprint 22 close-out) — `gh pr merge 778 --squash --delete-branch`
- PR #780 (Sprint 23 plan ship) — `gh pr merge 780 --squash --delete-branch`
- PR #779 (Sprint 24 plan scaffold) — `gh pr merge 779 --squash --delete-branch`

### Runner VM restart (cycle #3411 aborted)

8 actions.runner services confirmed ACTIVE on host github-runner (192.168.1.197), 16GiB RAM verified. User opted to handle manually.

## Definition of Done (Sprint 23, per plan.md)

| # | Criterion | Status |
|---|---|---|
| 1 | All 9 Sprint 23 stories ship per acceptance criteria | ✅ Stories CLOSED (8/8 dev + #652 fast-track parked) |
| 2 | PR cluster closes cleanly: #732 ✅ → #741 squash → #743 squash → #679/#704/#694 squash | ✅ ALL CLOSED pre-cycle-#3070 |
| 3 | PM coordination body well-tracked (Issue #733 + #724 + #652) | ✅ Issue #724 closed via PR #738, #733 resolved, #652 parked |
| 4 | No new P0/P1 bugs filed against cluster PRs within 24h | ✅ T+24h check PASSED (cycle ~#3417) |
| 5 | Repo vars `BUDGET_MULTIPLIER=5` + `SUBPROCESS_TIMEOUT_S=10` documented in README + CHANGELOG.md | ⏳ PENDING — verify post-docs-PR-squash |
| 6 | Sprint 22 close-out documented in `docs/sprints/sprint-22/close.md` | ✅ SHIPPED via PR #778 |

## Doctrine compliance

- **§PM lane definition (Sprint 13+ LOCKED)** — PM = docs/sprints/souls cc patterns, ORCH = sprint plan author ✅
- **§Issue #708 precedent** — Sprint 21 default carry-over executed per Q1 verdict ✅
- **§Eskalasyon istisnaları** — Sprint 23 scope-change = HUMAN escalation (Q2 owner verdict ASAP) ✅
- **§Pre-verdict cross-check (Issue #430)** — ground truth re-queried before plan authoring ✅
- **§4-cat invariant (ADR-0012)** — birth contract applied
- **§Post-verdict cross-watchdog (Issue #682)** — second-pass peer flag ack in verdict header ✅
- **§Auto-verdict-by hook (ADR-0024 amendment)** — verdict-by:<ts> stamps present ✅
- **§Closes-anchor strict format (ADR-0057)** — Closes auto-closes, Refs manual ✅
- **§no-self-standby (Issue #238)** — substantive work each cycle ✅

## RETRO-017 watchlist entries (pre-draft)

1. **Pre-merge rebase check** (Issue #430 sister-pattern) — author MUST verify `git diff origin/main..HEAD` shows ONLY intended diff before declaring owner-squash-ready. Sister-pattern to §Pre-verdict cross-check + §Post-verdict cross-watchdog.
2. **Forward cross-PR link check** — author MUST verify all relative markdown links point to files existing on the PR's branch (or on main, post-merge). Inverse: forward references to other open PRs.
3. **Inverse cross-PR link check** — symmetric: PR #778 ↔ PR #780 each reference the other. Owner merge order forced.
4. **Stale-local-main trap** — local `main` ref can lag `origin/main` by multiple commits after squash wave. Always verify against `origin/main`, not local main.
5. **§Auto-Ping Hard-Rule** — avoid over-pinging (4 pings in 8 min triggers doctrine review). Use selective, contextual pings.

— @orchestrator, cycle ~#3435 pre-draft, 2026-07-03T19:50+03:00