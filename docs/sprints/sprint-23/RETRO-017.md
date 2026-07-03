# RETRO-017 — Sprint 23 Retrospective

> **Status:** 📝 **PRE-DRAFT** (cycle ~#3435, 2026-07-03) — pending owner verdicts on Issue #769/740 + 3 docs PR squash. Will be finalized Sprint 23 close cycle (2026-07-13).
>
> **Author:** orchestrator (pre-draft, awaiting post-squash state)
> **Sprint:** Sprint 23 (Cluster Close + Sprint 21 Carry-Over Execution)
> **Window:** 2026-06-30 → 2026-07-13
> **Sister:** [close.md](./close.md) (sprint summary), RETRO-016 (Sprint 22 PIVOT retrospective)

## Pre-draft retrospective observations

This pre-draft will be expanded post-Sprint 23 squash wave + Issue #769 verdict. Sections below are scaffolded for completion.

## What went well

### Cluster-squash discipline (ADR-0059) ✅

- 5/5 cluster PRs squash-merged cleanly (cycle ~#3417, 2026-07-03T16:00:31Z)
- Owner squash cadence resolved (12/12 Sprint 22 PIVOT cascade + 10/10 cluster-squash wave closure cycle ~#3188)
- Closes-anchor strict format (ADR-0057) enforced — Issue #771 auto-closed, Issue #765 auto-closed
- d-test sister-pattern (ADR-0049) preserved across cluster — d121 + d122 atomic in cluster

### Sprint 21 carry-over resolution ✅

- 4/4 Sprint 21 PRs (#694 d093, #704 d070, #679 d069, #738 d094→d097) closed
- d-test infrastructure hardened (5 new d-tests shipped)
- ONBOARDING.md (S21-019, PR #694) shipped via d093 regression guard

### PM lane discipline (Sprint 13+ LOCKED) ✅

- PM stayed in `docs/sprints/souls` lane, NOT scripts/ refactors
- 9 decommission candidates triaged via Issue #740 cycle ~#3228 lens audit
- Issue #769 disposition (3 categories: 9-decom / #653 / #649) posted
- PM Option (a) close-out proposal STRENGTHENED via orchestrator peer observation

### Owner squash cadence ✅

- 12/12 Sprint 22 PIVOT cascade closed cycle ~#3188
- 10/10 cluster-squash wave closure (post-Sprint-22 PRs that shipped pre-PIVOT)
- Cluster-squash 5/5 closed cycle ~#3417

## What didn't go well

### Trust-but-verify gap → 3 critical fixes (cycle ~#3429-#3431)

#### Issue 1: PR #778 rebase gap (CRITICAL — would have deleted 7 files, -929 lines)

PR #778 branched from stale local main `8d9540b` (pre-cluster-squash closure). At time of tester 🟢 (15:58:15Z) + PM 🟢 (16:00:24Z) verdicts, cluster-squash had not yet closed (16:00:31Z). Rebase was the missing step. Owner merge would have **deleted**:
- docs/backlog.json (-222, PR #770 Sprint 24 candidate mapping)
- docs/decisions/ADR-0064-...md (-298, PR #773 RCA-17 codification)
- docs/decisions/INDEX.md (-1)
- 3 docs/sprints/sprint-23/observations/cycle-3349/3359/3363-...md (-404)
- docs/tech-debt.md (-4)

**Lesson**: Author MUST verify `git diff origin/main..HEAD` shows ONLY intended diff before declaring owner-squash-ready. **Sister-pattern to Issue #430 §Pre-verdict cross-check + Issue #682 §Post-verdict cross-watchdog**.

#### Issue 2: PR #780 forward cross-PR link (Lint & Test FAILURE)

PR #780 contained markdown link `close.md shipped → ../sprint-22/close.md` referencing PR #778 content. Cross-PR dependency forced owner merge order.

**Lesson**: Author MUST scan all relative markdown links for forward references to other open PRs.

#### Issue 3: PR #778 inverse cross-PR link (Lint & Test FAILURE)

Symmetric: PR #778 contained `../sprint-23/plan.md → ../sprint-23/plan.md` referencing PR #780 content.

**Lesson**: Same pattern, both directions. Owner merge order is forced.

### Stale-local-main trap

Local `main` ref was stale at `8d9540b` while `origin/main` was at `60d234f` (multiple squash SHAs ahead). `git diff main..branch` produced misleading stats until I switched to `git diff origin/main..branch`.

**Lesson**: Always verify against `origin/main`, not local `main`. After squash wave, force local main ref update via `git update-ref refs/heads/main origin/main`.

### Over-pinging temptation

4 owner pings in 8 minutes (cycle #3423 → #3429) — defensive but borderline spam. Doctrine §Auto-Ping Hard-Rule is silent on over-pinging (only on under-pinging).

**Lesson**: Consolidate owner notifications into batched pings with comprehensive context, not per-cycle pings.

## Watchlist (carried to Sprint 24+)

### W1 — Pre-merge rebase check (sister-pattern Issue #430 + #682)

**Owner**: each PR author (orchestrator, PM, arch, dev, tester)
**Trigger**: BEFORE declaring PR owner-squash-ready
**Action**: `git diff origin/main..HEAD --stat` shows ONLY intended diff. If deletions > 0 of recently-added files, rebase missing.

### W2 — Cross-PR markdown link check (both directions)

**Owner**: each PR author for docs PRs
**Trigger**: BEFORE declaring docs PR owner-squash-ready
**Action**: `grep -nE '\]\(\.\./|\]\(\./' <changed-files>` for relative links. Verify each target exists on PR's branch (or on main, post-merge).

### W3 — Auto-Verdict-By Hook (ADR-0024 amendment) — VERIFY verdict-by:<ts> stamps

**Owner**: each peer reviewer
**Trigger**: BEFORE posting verdict
**Action**: Verify `verdict-by:<iso8601-timestamp>` label stamped on PR (auto via hook or manual via `gh issue edit`).

### W4 — Cluster-squash doctrine (ADR-0059) — VERIFY cluster_size ≥ 3 before lazy-flag skip

**Owner**: orchestrator
**Trigger**: BEFORE cluster-squash wave closure
**Action**: d064 cluster-lag silent-skip threshold = 3, not cluster_size. Document expected cluster_size in cycle observation.

### W5 — Stale-local-main guard

**Owner**: each agent using `git diff` for PR review
**Trigger**: BEFORE posting rebase-check verdict
**Action**: Always diff against `origin/main`, not local `main`. `git fetch origin main && git update-ref refs/heads/main origin/main` before diff.

## Metrics

| Metric | Sprint 22 (precedent) | Sprint 23 | Trend |
|---|---|---|---|
| Cluster-squash closure rate | 12/12 PIVOT + 10/10 wave (100%) | 5/5 (100%) | ✅ stable |
| Stories committed | 18 (PIVOT) + Sprint 21 carry-over | 9 + 8 dev cluster | ➡️ normal cadence |
| Sprint 21 carry-over closure | 4 (skeleton Sprint 22) | 4 (PR #694/#704/#679/#738) | ✅ resolved |
| PM lane discipline violations | 0 | 0 | ✅ stable |
| Critical fixes (Trust-but-verify §5) | 0 (Sprint 22 cluster wave) | 3 (this session: rebase + 2 cross-PR links) | ⚠️ regression |
| Owner squash cadence | Bottleneck (10 squashes needed) | Smooth (5 squashes) | ✅ improved |
| d-test framework adoption | d093 d070 d069 d094→d097 | d117 d121 d122 sister-pattern | ✅ expanded |
| Cross-lane handoff discipline | ADR-0015 atomic flip | 3 PRs all clean handoff | ✅ stable |

## Carry-forward to Sprint 24

### Action items

1. **Codify W1-W5 in orchestrator soul file** — pre-merge rebase check + cross-PR link check as standard PR-author discipline
2. **Update CLAUDE.md §Operating Principles** with rebase/link check before declaring owner-squash-ready
3. **Add W1-W5 to RETRO-017 watchlist** (carried forward)
4. **Sprint 24 plan owner verdicts** (Issue #769 3 categories) — execute post-docs-PR-squash
5. **Issue #740 close-out** (PM Option a proposal) — execute post-owner-verdict
6. **Runner VM restart call** — owner action (cycle #3411 aborted)

### Open questions

- Q1: Should the pre-merge rebase check be automated via a CI gate (sister-pattern d064 cluster-lag)?
- Q2: Should the cross-PR link check be automated via d-test sister-pattern?
- Q3: Owner merge-order policy when cross-PR links force ordering — auto-detect or manual?

— @orchestrator, cycle ~#3435 pre-draft, 2026-07-03T19:50+03:00