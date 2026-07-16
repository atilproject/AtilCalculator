# RETRO-029 — Sprint 29 Retrospective (2026-07-16)

> **Author**: @product-manager (cycle ~#2341, delegated per cycle ~#2324 orchestrator directive)
> **Reviewer**: @orchestrator + @architect (9-Lens per ADR-0045) + @tester (lessons-learned) + @human (owner merge gate per ADR-0031)
> **Status**: DRAFT — pending multi-lane peer review + owner squash per ADR-0031
> **RETRO number**: 029 (next sequential after RETRO-024 #1027 + RETRO-025 #1038 + RETRO-026 #1097 + RETRO-027 #1045)
> **Sister-pattern**: docs/sprints/sprint-03/RETRO-003.md (file structure + content convention)

## Sprint 29 outcomes summary

Sprint 29 executed a **cluster-squash wave at scale** (11/11 PRs MERGED same-day by owner squash, ADR-0059 proven across 2 repos) plus 1 PR (#1104 ADR-0007 refile) pending squash. Sprint scope absorbed Sprint 30 entirely per cycle ~#2257 (scope-shift final). Sister-cluster cadence (tmpl AtilCalc + tmpl gap-fix) RESTORED at cycle ~#2340.

### What worked

1. **Cluster-squash doctrine (ADR-0059) at scale** — 11/11 PRs MERGED same-day by atilcan65 squash across 2 repos:
   - AtilCalc 6/6 gap-closing (PR #1095/1096/1098/1099/1100/1101) — cycle ~#2252
   - tmpl 3/3 sister-cluster (PR #113/114/115) — cycle ~#2226 GATE 1 UNLOCK
   - tmpl 2/2 gap-fix sister-cluster (PR #118/119) — cycle ~#2356 + cycle ~#2340
2. **Issue #414 §Dispatch Discipline + RETRO-005 #26** — 6-step pre-flight proven across PR #1095/1098/1100/1099/1101/119. PM/arch verdict-by discipline validated.
3. **Cycle ~#2252 cluster-squash doctrine refinement** — "same-day owner squash" doctrine codified (commits a-f merged within 3-4 hour window).
4. **Cycle ~#2259 anti-hallucination doctrine** — never cite ADR/Issue/PR from memory; always gh verify. Caught ADR-0007 file MISSING gap (cycle ~#2326 surface) → architect refile PR #1104 cycle ~#2330.
5. **Cycle ~#2334 isDraft:true sister-pattern** — blocker-flip rhythm for ADR docs PRs (PR #1104 flipped within ~30s of PM peer-poke, same as tmpl PR #118+#119 cycle ~#2331).
6. **PM lane coordination under owner-unresponsive gap-time** — cycle ~#2326 best-default election doctrine (Option A full-run, ADR-0007 reversible in 1 commit, owner can override post-sprint).
7. **RETRO-024 work-done-elsewhere terminal state** — `type:<*> + status:ready + cc:human + NO agent:*` invariant exception for cross-repo sister-PR work. Reflexive 4-cat repair silently-skips these. Two live instances (Issue #1015, #1017) — RETRO-022 regression prevented.
8. **Cycle ~#2342 8/8 escalation with ground-truth verification first** — peer-poke human w/ escalation framing after 8 consecutive wake_nudges on squash-READY PR. Caught dev isDraft-flip "just in time" pattern.
9. **Sprint 30 GATE 1 UNLOCK (cycle ~#2226)** — tmpl sister-cluster completion unblocked Sprint 30 3-repo portage scope (launcher + tmpl backport + AtilCalculator sister-cascade).
10. **parser-leniency GitHub auto-close refinement (cycle ~#2252 + cycle ~#2330)** — `Fixes Issue #N` non-canonical form DOES auto-close with 1-3 min delay. ADR-0057 strict form (`Closes #N`) still preferred for predictability, but missing canonical anchor ≠ auto-close-failure.

### What didn't work / lessons learned

1. **D-test PR cluster-squash gap (cycle ~#2173 doctrine)** — original cluster-squash inventory per ADR-0059 omitted d-test PRs. PM surfaced pattern → ADRs-must-include-d-tests added to cluster-squash inventory checklist. Risk if missed: cluster-squash doctrine broken because d-test sister-pair missing from owner squash bundle.
2. **Cluster-squash sister-cluster cadence broken (cycle ~#2356)** — owner split 2-PR cluster (PR #118 first, PR #119 second). cadence-bottleneck emerged (PR #118 MERGED 09:54:20Z → origin/main advanced → PR #119 CONFLICTING → dev rebase required). Lesson: for 2-PR clusters with same verification pattern, owner should merge atomically; otherwise dev must rebase mid-cluster.
3. **Branch contamination cycles ~#2165 + ~#2341** — multi-session continuity reuses peer branches with uncommitted files. PM session landed on architect's branch with 2 uncommitted PM-authored files (01-portage-verify.md + s29-017-soul-amend-lineage.md). Solution: stash → fresh branch off origin/main → pop stash. Doctrine [[pm-branch-fork-discipline]] codified.
4. **Cycle ~#2306-#2311 text-only heartbeat discipline gap** — PM heartbeat entries without tool calls. Per [[heartbeat-edit-discipline-no-skip]] doctrine, every wake needs Edit tool call (Bash append satisfies discipline). Refined: any tool call is sufficient.
5. **Cycle ~#2228 + ~#2297 ADR-0057 hallucination (PR-specific, not blanket)** — PM (me) cycle ~#2228 cited PR #1099 anchor gap based on pre-compaction memory. Orchestrator retraction at cycle ~#2297 was correct. PR-SPECIFIC lesson: never generalize anchor NITs across sister-PRs without per-PR `closingIssuesReferences` REST check.
6. **Cycle ~#2270 STOP-and-HOLD pattern** — PM held cycle ~#2270 STOP due to perceived peer-busy state. Lesson: STOP only when explicit (a) human instruction, (b) dependency block, (c) heartbeat/reprime SOP step — NOT self-justified "peer seems busy".
7. **Cycle ~#2330 squash-READY PARTIALLY ACCURATE claim** — architect claim "PR #1104 squash-READY" missed isDraft:true blocker. PM verdict posted with explicit caveat + isDraft flip ping. Lesson: re-verify all 5/5 squash-READY conditions (verdict-by + status:ready + MERGEABLE + isDraft:false + cc:human) before posting claim.
8. **Cycle ~#2340 PR #119 squash signal missed in earlier cycles ~#2331-#2333** — PM dispatched squash-READY signal cycle ~#2331, then escalated 8/8 cycle ~#2339. Owner squash signal arrived cycle ~#2340 (1 cycle after 8/8 escalation). Timing tight but doctrine held: escalate, don't silent-skip.
9. **Cycle ~#2324 orchestrator directive "PM starts close.md + RETRO"** — directive ACTIVE but PM deferred execution across multiple pickup cycles. Lesson: when orchestrator delegates, execute within next pickup cycle, not later. Authoring executed cycle ~#2341 (17 cycles after directive).
10. **Sprint 29 W3 PM deliverable list 5/7 items incomplete at sprint close** — per memory [[sprint-29-w3-pm-deliverable-list]]:
    - ✅ S29-014 verify-portage evidence (in-flight cycle ~#2326, AC4 chain-pending)
    - 🟡 Retro facilitation agenda (this doc, DRAFT)
    - 🟡 PM grooming of #109 (S29-013-FU, Sprint 30+ scope)
    - 🟡 PM-authored content for #1077 (S29-018, owner sprint-close signal pending)
    - 🟡 PM-authored content for #1078 (S29-019, arch lane delivered via PR #1095)

## Sister-patterns surfaced (carry to Sprint 30+)

1. **Cycle ~#2259 anti-hallucination** — `gh search` + `ls docs/decisions/` before any ADR/Issue/PR cite. Extends to **references**, not just implementations.
2. **Cycle ~#2334 isDraft:true sister-pattern** — docs PRs need explicit isDraft:false flip before squash-READY claim is complete.
3. **Cycle ~#2342 8/8 escalation pattern** — escalate after 8 consecutive wake_nudges; ground-truth verify FIRST; tmux pane %5 + Telegram mirror.
4. **Cycle ~#2326 PM Option A best-default election** — owner unresponsive gap-time → PM picks best-default (reversible in 1 commit).
5. **Cycle ~#2252 cluster-squash parser-leniency** — `Fixes Issue #N` form auto-closes with 1-3 min delay; ADR-0057 strict form preferred but not enforced.
6. **Cycle ~#2356 sister-cluster cadence atomicity** — 2-PR clusters should squash atomically to avoid rebase cascade.

## Tech-debt carry-over (Sprint 30+ scope, NOT Sprint 29)

Per file ownership matrix, these are @architect lane:

- **d-number allocation protocol gap** (memory [[d-number-allocation-protocol-gap]]) — Sprint 30+ TD; d-numbers informal/sequential + race-prone; 4 candidate solutions; architect authority per ADR-0049
- **verdict-by:developer label hygiene gap** (memory [[verdict-by-developer-label-hygiene-gap]]) — Sprint 30+ TD; only verdict-by:architect + verdict-by:tester exist; cross-lane dev verdict has no machine-parseable label per Issue #681
- **Pre-push cross-repo worktree gap** (memory [[pre-push-cross-repo-worktree-gap]]) — Sprint 30+ TD; scripts/pre-push/branch-base-check.sh checks origin/main regardless of worktree upstream; Option 3 (auto-detect) most ergonomic
- **Verdict-by supersession multi-peer chain** (memory [[verdict-by-supersession-multi-peer-chain]]) — Sprint 30+ TD; PR #1095 has verdict-by:PM+tester but NO verdict-by:architect; 3 amendment options
- **Pattern A vs Pattern B d-test cluster doctrine** (memory [[sprint-29-pattern-a-vs-pattern-b-dtest-cluster-doctrine]]) — Sprint 30+ TD; Pattern A (single-PR) vs Pattern B (two-PR) doctrine gap from PR #115 race; ADR-0059 architecture call needed
- **Pre-compaction memory hallucination lesson** (memory [[sprint-29-adr0060-hallucination-lesson]]) — always `gh` verify ADR/Issue/PR numbers per-PR; PR-SPECIFIC anchor checks, not blanket generalization

## Sprint 30 readiness checklist

Per memory [[sprint-30-3-repo-portage-gate-1]] cycle ~#2226 + cycle ~#2257:

- [x] **GATE 1 UNLOCK** (tmpl sister-cluster 3/3 MERGED cycle ~#2226)
- [x] **tmpl gap-fix sister-cluster cadence RESTORED** (cycle ~#2340)
- [ ] **PR #1104 squash** (still pending, ADR-0007 ratification chain)
- [ ] **Issue #1073 AC4 PM Option A full-run** (cycle ~#2326 election, chain-pending PR #1104 squash)
- [ ] **Sprint 30 backlog freeze** (orchestrator cycle ~#2340 close ceremony window open)
- [ ] **Sprint 30 PM lane placement** (per [[sprint-30-pm-lane-placement-decisions]] cycle ~#1988 — non-gap-closing scope ONLY)

## Cross-lane lessons

### For @architect
- **ADR file management** — gaps in `docs/decisions/` (ADR-0003 → ADR-0010 gap) are dangerous anti-hallucination traps. Recommend ADR index freshness audit per Sprint close.
- **docs PR (type:docs) squash-READY** — when claiming squash-READY, verify ALL 5 conditions (verdict-by + status:ready + MERGEABLE + isDraft:false + cc:human). isDraft:true is often missed.

### For @developer
- **Cluster-squash pre-rebase** — when PR is in a cluster and sister-PR merges first, dev must rebase before squash-READY claim. Cycle ~#2361 recovery pattern.
- **D-test PR cluster inclusion** — d-test PRs are cluster-squash members per ADR-0059 inventory. Don't omit from PR inventory.

### For @tester
- **RETRO-024 silent-skip pattern** — Issue #1081 BUG RETRO-024 predicate incomplete is Sprint 30+ scope. Currently silently-skipping items with both `agent:* + cc:human`.
- **D-test INDEX drift** — Issue #1102 HYGIENE: 9+ legacy d-test files missing INDEX.md rows. Cadence Rule 1 violation per ADR-0055.

### For @orchestrator
- **PM lane coordination under owner-unresponsive gap-time** — consider PM delegation for sprint close ceremony work when owner gate is open. Cycle ~#2324 directive + cycle ~#2341 execution.
- **Sister-cluster cadence atomicity** — owner should squash 2-PR clusters atomically to avoid rebase cascade. Communicate this in owner-pings.

### For @human (owner)
- **Squash gate SLA** — Sprint 29 cycle ~#2252 + cycle ~#2340 both showed ~3-4 hour squash latency from squash-READY signal to actual squash. Sister-cluster cadence broken if squash delayed beyond cluster-cascade window.
- **PR #1104 squash** — ADR-0007 refile squash-READY since cycle ~#2331 (8/8 escalation cycle ~#2339). 5+ hour delay.

## Sister-pattern lineage

- [[sprint-29-cluster-squash-actual-final-completion-2026-07-16]] cycle ~#2324 — 9/9 PRs same-day MERGED
- [[sprint-29-pm-lane-coordination-cycle-2393]] — PM coordination 3-part plan (gap-time + close.md+RETRO + NO premature finalization)
- [[sprint-29-pm-anti-hallucination-adr0007-gap-cycle-2396]] — ADR-0007 stale-cite surface
- [[sprint-29-tmpl-cluster-squash-ready-2026-07-16]] cycle ~#2334 — tmpl 5/5 squash-READY
- [[sprint-29-tmpl-cluster-8-8-escalation-cycle-2342]] — 8/8 threshold doctrine
- [[sprint-29-tmpl-cluster-partial-merge-pr118-cycle-2356]] — sister-cluster cadence broken pattern
- [[sprint-29-tmpl-cluster-recovery-pr119-cycle-2361]] — silent dev rebase pattern
- [[sprint-29-issue-1091-stale-label-hygiene-cycle-2359]] — Issue #1091 stale-label hygiene
- [[sprint-29-pattern-a-vs-pattern-b-dtest-cluster-doctrine]] — Pattern A vs B doctrine gap
- [[sprint-29-adr0007-refile-pr1104-pm-verdict-cycle-2330]] — PM verdict 🟢 on ADR-0007 refile

## Sign-off

- [ ] @orchestrator review + co-sign
- [ ] @architect review + 9-Lens per ADR-0045
- [ ] @tester review (lessons-learned cross-check)
- [ ] @human squash gate per ADR-0031
- [ ] Project card Done flip by orchestrator post-merge

---

*Drafted cycle ~#2341 by @product-manager per cycle ~#2324 orchestrator directive. Awaiting multi-lane peer review + owner squash.*