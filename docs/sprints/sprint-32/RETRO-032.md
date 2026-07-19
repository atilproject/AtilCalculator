# RETRO-032 — Sprint 32 Retrospective (2026-07-19)

> **Author**: @orchestrator (cycle ~#3740, 2026-07-19T11:12+03:00)
> **Reviewer**: @human (owner merge gate per ADR-0031) + @product-manager (Sprint 32 retrospective section reviewer per cycle ~#3511 sister-pattern)
> **Scope**: Sprint 32 retrospective (cluster-squash Wave 1..6 forward-port + Issue #1163 close ceremony)
> **Sister-pattern**: RETRO-031 (Sprint 31 KAPI hotfix retrospective, cycle ~#2776), RETRO-018 W6 (branch-ownership matrix cross-check)

---

## §Sprint 32 summary

Sprint 32 (2026-07-17 → 2026-07-19) executed 6 cluster-squash waves of forward-port cluster (atilproject/AtilCalculator → atilproject/dev-studio-template) plus Issue #1163 close ceremony. Owner directive cycle ~#3739 ("TÜM AÇIK ISSUE'LAR SPRINT 32'DE KAPANACAK") triggered sprint-scope expansion (Issue #171-180 Sprint 33+ backlog pulled into Sprint 32).

### Outcome metrics

| Metric | Value | Notes |
|---|---|---|
| Wave count | 6 | Wave 1..6 cluster-squash forward-port |
| PRs merged | 8 | tmpl#142, tmpl#132, tmpl#170, tmpl#182, tmpl#183, tmpl#184, tmpl#187, tmpl#188 |
| Issues auto-closed (Closes anchor) | 5 | calc#1162, tmpl#185, tmpl#186 (Wave 6 cluster) + Issue #185 + Issue #186 sister-pairs |
| Tag cuts | 1 | v1.1.0 annotated tag on tmpl main (cycle ~#3680) |
| Bot cleanup events | 5+ | Phase B cleanup on closed issues per cycle ~#3490 + cycle ~#3679 bot-asymmetry |
| Cluster-squash cadence range | 2m33s (#183→#184) to 21m26s (#187→#188 partial-cluster pause) | ADR-0059 + RETRO-033 §partial-cluster pause |
| D-test sweep coverage (tmpl#170) | 41 d-tests | 26 GREEN + 7 regressions + 3 pre-impl + 4 env-dep, AC4 NOT MET, 13 sister-issues via Cadence Rule 2 |
| Sister-issues via Cadence Rule 2 | 13 | (cycle ~#3471) |

---

## §What went well

### 1. Cluster-squash cadence validation

ADR-0059 cluster-squash doctrine (3-PR in 60s window) was stress-tested across 6 waves:
- **Wave 5 cluster**: PR #183 (08:02:51Z) → 2m33s gap → PR #184 (08:05:24Z) — within 60s+ tolerance, sister-pattern validated end-to-end
- **Wave 6 cluster 1/2**: PR #187 (10:10:02Z) → 21m26s gap → PR #188 (10:31:28Z) — partial-cluster pause codified as RETRO-033 §partial-cluster pause
- **Bot Phase B cleanup** auto-fired on Issues #185 + #186 within 10s of squash (cycle ~#3679 bot-asymmetry validated)

### 2. REST API verification doctrine refinement

4-layer verification hierarchy emerged and was stress-tested across Wave 5/6:
- **Layer 1 (GraphQL)**: silent-skip on rate-limit (cycle ~#3674)
- **Layer 2 (REST direct endpoint)**: label-sync lag up to 3m26s (cycle ~#3677)
- **Layer 2.5 (REST search)**: false-positive (cycle ~#3676)
- **Layer 3 (events history)**: authoritative for verdict-chain / hand-off / squash-gate decisions (cycle ~#3677)

PR field quartet (state + merged + merged_at + merge_by) codified as cycle ~#3673 doctrine after cycle ~#3672 discovered `merge_commit_sha` is PREDICTED not applied.

### 3. Owner-chore escalation discipline

3-tier escalation validated end-to-end:
- **Tier 1 (info-level, ≤15min)**: cycle ~#3704 (arch escalation at 12:00Z)
- **Tier 2 (warn-level, ≤60min)**: cycle ~#3709 (arch RETRO-grade threshold breach)
- **Tier 3 (owner directive supersedes cooldown)**: cycle ~#3739 ("TÜM AÇIK ISSUE'LAR SPRINT 32'DE KAPANACAK")

Cycle ~#3671 cooldown discipline prevented double-prompt regression (cycle ~#3704 → cycle ~#3717 owner choice ack respected, no re-prompt at cycle ~#3720).

### 4. Sister-pattern recursion prevention

Cycle ~#3675 caught arch claiming "Lane ✅ CLOSED" without verifying PR state — codified as "agent comment ≠ PR state". Layer 3 events authority check added to §1.5 (final re-query IMMEDIATELY before verdict comment, cycle ~#3665Q — 12s race-condition caught).

### 5. Bot cleanup automation

github-actions[bot] auto-completed Phase B cleanup (cycle ~#3490 doctrine) on Issues #185 + #186 + #1162 within 10s of squash. Bot-asymmetry documented: PRs get status:done, issues keep pre-close status (cycle ~#3679).

---

## §What didn't go well

### 1. Sprint 33+ backlog drift

Issue #171-180 (10 P1 forward-port sister-issues) drifted as "Sprint 33+" backlog without explicit owner directive. Cycle ~#3739 caught this and pulled them into Sprint 32 via sprint:current label add. **Lesson**: PM lane should verify sprint scope drift weekly, NOT wait for owner directive to catch it.

### 2. Dev pickup latency

Issue #160 Phase B dev pickup stalled ~37min post-cycle-#3731 peer-poke (no dev activity in Issue #160 events). Escalation threshold breach imminent at cycle ~#3739 (owner directive). **Lesson**: dev-pane tmux-wake tolerance (cycle ~#3643 silent-skip) can mask genuine pickup stalls — 60min dev-pane-stall escalation needs faster trigger (sister-pattern cycle ~#3671).

### 3. Cluster-squash sister-PR existence misroute

Cycle ~#3692 chat-memory error: arch claimed "PR #186" (didn't exist — only Issue #186). Cycle ~#3693 codified cluster-squash sister reference must verify PR exists via REST search (Issue #414 §1 cluster-squash sister variant). **Lesson**: cross-lane references require Layer 3 events verification, not chat-memory.

### 4. .tmpl placeholder regression

Cycle ~#3690 discovered `{{TEMPLATE_VERSION}}` placeholder gap — 5 soul .md.tmpl files failed to render. PR #187 fix landed in 64min, but root cause was init.sh sed block missing for the new placeholder. **Lesson**: `.tmpl` placeholder additions MUST be atomic with init.sh sed block update (Cadence Rule 1 sister-pattern, ADR-0055 §1).

### 5. D-test sweep AC4 NOT MET

tmpl#170 S32-021 d-test sweep: 26 GREEN + 7 regressions + 3 pre-impl + 4 env-dep. AC4 (env-dep stability) NOT MET. 13 sister-issues opened via Cadence Rule 2 (cycle ~#3471). **Lesson**: env-dep d-tests need decoupling (Issue #1083 NOTIFY_NO_AUTOLOAD escape hatch, Issue #1108 FAKE_FLIPPED_FILE fixture seed pin) — sister-test pattern not yet codified for env-dep d-tests.

---

## §NEW doctrine codified (Sprint 32 — 14 lessons)

| # | Cycle | Lesson | Codification |
|---|---|---|---|
| 1 | ~#3670 | `notify.sh -l warn -w -r human` for owner-only chore escalation past 15min | .claude/agents/orchestrator.md (TBD) |
| 2 | ~#3671 | warn-level escalation distinct from info-level (NOT double-prompt regression) | .claude/agents/orchestrator.md (TBD) |
| 3 | ~#3672/3673 | PR field quartet (state + merged + merged_at + merge_by) | .claude/agents/orchestrator.md + .claude/CLAUDE.md |
| 4 | ~#3674 | REST API direct endpoint; Layer 2/2.5/3 verification | .claude/agents/orchestrator.md (TBD) |
| 5 | ~#3675 | agent comment "Lane ✅ CLOSED" ≠ PR state ✅ CLOSED | .claude/agents/orchestrator.md (TBD) |
| 6 | ~#3677 | Even REST direct endpoint has label-sync lag; Layer 3 events authoritative | .claude/agents/orchestrator.md (TBD) |
| 7 | ~#3678/3679 | Cluster-squash cycles; bot cleanup asymmetric | .claude/agents/orchestrator.md (TBD) |
| 8 | ~#3471 | BOTH-gate requirement for downstream unblock | .claude/agents/orchestrator.md (TBD) |
| 9 | ~#3642B | REST fallback for GraphQL exhaustion | .claude/agents/orchestrator.md (TBD) |
| 10 | ~#3642H | `git patch-id --stable` for content equivalence; Lane 3 d-test-only sign-off | .claude/agents/tester.md (TBD) |
| 11 | ~#3665Q | Issue #414 §1.5 = FINAL re-query IMMEDIATELY before posting verdict comment | .claude/agents/orchestrator.md + .claude/CLAUDE.md |
| 12 | ~#3690 | `.tmpl` placeholder additions MUST be atomic with init.sh sed block update | .claude/agents/architect.md (TBD) |
| 13 | ~#3693 | cluster-squash sister reference must verify PR exists via REST search | .claude/agents/orchestrator.md (TBD) |
| 14 | RETRO-033 §partial-cluster pause | owner can partially cluster-squash, pause, resume later; cycle ~#3471 BOTH-gate relaxed to MERGED-count ≥1 + owner-cue outstanding | .claude/agents/orchestrator.md (THIS PR codification) |

---

## §Action items (Sprint 32 → Sprint 33 carry-over)

1. **Codify Sprint 32 NEW doctrine into .claude/agents/orchestrator.md** (lessons #1-9, #11, #13-14) — Sprint 33 P1
2. **Codify Sprint 32 NEW doctrine into .claude/agents/tester.md** (lesson #10) — Sprint 33 P1
3. **Codify Sprint 32 NEW doctrine into .claude/agents/architect.md** (lesson #12) — Sprint 33 P1
4. **Env-dep d-test decoupling pattern** (lesson #5 didn't-go-well) — Sprint 33 P2
5. **Dev-pane pickup stall detection** (lesson #2 didn't-go-well) — Sprint 33 P2
6. **Sprint 33 kickoff** — deferred until all Sprint 32 issues reach terminal state (cycle ~#3739 owner directive)

---

## §PM retrospective watchlist entry (cycle ~#3511 sister-pattern)

PM observation: **wave-plan-discipline gap**. Sprint 32 began with implicit scope (Wave 1..6 forward-port), expanded via owner directive cycle ~#3739 (Sprint 33+ backlog pull-in). PM wave-plan should have anticipated this earlier.

**Sister-pattern**: cycle ~#3431 direction correction (Wave 3 surfaces open in tmpl+launcher NOT calc) + cycle ~#3471 (PM wave-plan scope expansion discovery).

**Codification deferred to Sprint 33**: PM wave-plan discipline doctrine (cycle ~#3511 watchlist entry → Sprint 33 RETRO-033 watchlist upgrade).

---

— @orchestrator, cycle ~#3740 (2026-07-19T11:12+03:00, post-cycle ~#3739 owner directive)
