# Sprint 30 Plan — Gap-Closing Carry-Over

> **Sprint:** 30
> **Author:** @product-manager (cycle ~#2467)
> **Owner-directive:** cycle ~#2596 (CORRECTION — supersedes cycle ~#2593 framing)
> **Scope doctrine binding:** Sprint 30 = gap-closing ONLY. Owner directive verbatim: *"gap closing dışında hiç bir item istemiyorum"* (cycle ~#2596, 2026-07-16T20:14Z+03).
> **Cycle ~#2593 framing REJECTED:** Sprint 30 ≠ non-gap-closing. PM's earlier draft (vision intake, personas, RETRO-025, PM lane refinements) is **OUT OF SCOPE** per owner correction. Discarded.

---

## §0 — Sprint Goal (North Star)

> **Close the remaining Sprint 29 W3 backlog gap-closing items: 5 carry-over stories (#1078 #1072 #1073 #1075 #1032) that did not land in Sprint 29.**

**Sprint boundary (owner directive cycle ~#2596):**
- **Gap-closing ONLY** — no vision intake, no personas, no RETRO-025 codification, no PM lane refinements. Those are explicitly OUT OF SCOPE.
- **5-item carry-over scope** — locked.
- **4 closed items TERMINAL** — #1068 #1059 #1058 #1049 stay CLOSED with backlog state `closed-scope-cleanup`. NOT re-evaluable. NOT in Sprint 30 plan. (Per owner correction: "4 kapalı issue ... TEKRAR AÇMA, Sprint 30 plan'a DAHİL ETME".)

**Success criterion (sprint DoD):**
1. All 5 carry-over items (W1/W2/W3 below) reach `status:done` with PRs merged to main via owner squash per ADR-0031.
2. `docs/sprints/sprint-30/close.md` authored + RETRO-030 filed.
3. Sprint 31 plan authored (`docs/sprints/sprint-31/00-plan.md`).
4. `docs/sprints/current/plan.md` updated to point to Sprint 30 closeout + Sprint 31 launch.

---

## §1 — Owner Decision Audit (cycle ~#2593 → cycle ~#2596 reversal)

| Cycle | Owner said | PM interpreted | Reality |
|---|---|---|---|
| **#2593** | "gap closingle alakası olmayan herşeyi silebiliriz, gap closingle alakalı olanları da yapmamız gerek. önce analiz ve planı ver onayımla sileceksin" | Sprint 30 = non-gap-closing (per memory [[sprint-30-pm-lane-placement-decisions]]) | PM MISREAD. Owner meant: Sprint 30 = gap-closing items ONLY (those left over from Sprint 29 W3). |
| **#2596** (correction) | "Sprint 30 plan = gap-closing ONLY. 4 kapalı issue TERMINAL CLOSED. Sprint 30 framing = Sprint 29 W3 backlog gap-closing items only (#1078 #1072 #1073 #1075 #1032)" | (this plan) | Sprint 30 = these 5 items, gap-closing scope, nothing else. |

**Lesson:** PM's first-read of cycle ~#2593 collided with [[sprint-30-pm-lane-placement-decisions]] memory (which was based on cycle ~#1988 doctrine). The owner's actual intent (cycle ~#2596) overrides the doctrine-derived interpretation. Per CLAUDE.md §"Things agents must NEVER do" + Auto-Ping Hard-Rule, current-thread owner instruction is the highest-priority input. Memory anchors to past doctrine are advisory, not binding when owner explicitly corrects in current thread.

---

## §2 — Sprint 30 Scope: 5 Carry-Over Items (gap-closing ONLY)

| # | Story | Title | Priority | State | Lane | Wave |
|---|---|---|---|---|---|---|
| **#1075** | S29-016 | pyproject.toml.tmpl + LICENSE.tmpl + .template-version render path (CRITICAL BLOCKER) | **P0** | OPEN, status:ready, agent:developer | Dev | **W1** |
| **#1032** | S29-007 | Forward-port 80+ universal d-tests (ADR-anchored) | **P0** | OPEN, status:ready, agent:developer | Dev | **W1** |
| **#1072** | S29-013 | Launcher auto-applies self-hosted 4-tuple on bootstrap (per owner #5) | **P1** | OPEN, status:ready, cc:human | Dev (launcher repo) | **W2** |
| **#1073** | S29-014 | Verify-portage execution against post-portage template | **P1** | OPEN, status:in-progress, agent:product-manager | **PM** | **W2** |
| **#1078** | S29-019 | 6 top-level docs files .tmpl render (Phase 2 NEW) | **P2** | OPEN, status:ready, cc:human | PM (1/6) + Arch (5/6) | **W3** |

**Sprint 29 → Sprint 30 transition**: Sprint 29 W3 backlog contains these 5 gap-closing items that did NOT land in Sprint 29 (Sprint 29 was scope-locked gap-closing per owner directive #3, capacity cap = NONE, but cluster-squash 5/5 + close.md + RETRO-029 cycle ~#2558 completed the gap-closing portion of Sprint 29). Sprint 30 picks up the 5-item remainder.

---

## §3 — Wave Plan

### Wave 1 (Sprint 30 W1): P0 CRITICAL BLOCKERs

**Scope:** #1075 + #1032 — both P0, both dev lane, both script-side.

**Dependencies:**
- #1075 (pyproject.toml render path): per memory `Sprint-29-Issue-1108-d058-fixture-seed-pin-fix.md` and PR #105 (squash-merged 2026-07-14T20:51:19Z), the Phase B pyproject render path WAS partially shipped. #1075 may already be partially done — verify with dev lane at Sprint 30 W1 kickoff.
- #1032 (forward-port 80+ d-tests): ADR-anchored work, sister-pattern to Sprint 28/29 d-test ports. Dev lane owns.

**PM role (W1):** Stand by for dev lane; coordinate RETRO-024 hygiene pass on any new closed issues (cycle ~#2247 doctrine). PM does NOT execute script work.

### Wave 2 (Sprint 30 W2): P1 gap-closing

**Scope:** #1072 + #1073 — both P1, one dev (launcher repo), one PM (in-progress already).

**#1072 (S29-013 launcher self-hosted 4-tuple):**
- Cross-repo workstream: atilcan65/dev-studio-launcher repo
- Per `atilproject/dev-studio-template PR #73` (S29-001 sister-pattern): template-side 4-tuple already lives in `dev-studio-template/.github/workflows/*.yml.tmpl`
- Sprint 30 W2 = launcher side picks up the auto-apply pattern (RETRO-023 codifier workstream)
- Lane: dev (launcher repo), PM awareness-cc per Sprint 13+ PM lane LOCKED

**#1073 (S29-014 verify-portage execution):**
- PM lane, in-progress already (per the untracked `docs/sprints/sprint-29/01-portage-verify.md` DRAFT, 7978 bytes, dated 2026-07-16T19:06)
- Owner ratification REQUIRED before full run per the doc's own header (verify-portage.sh deletes GitHub repos + erases /tmp)
- Sprint 30 W2 = PM completes the doc, opens PM PR for owner review

**PM role (W2):** Execute #1073 (PM-authored verify-portage evidence PR); coordinate #1072 dev pickup.

### Wave 3 (Sprint 30 W3): P2 gap-closing polish

**Scope:** #1078 — 6 top-level docs files .tmpl render.

**Lane split:**
- **PM (1/6)**: `docs/USER-GUIDE.md.tmpl` ≥1-2 sections per AC1+AC2
- **Arch (5/6)**: remaining 5 top-level docs files (when arch lane engages — out-of-scope for PM to coordinate)

**PM role (W3):** Author USER-GUIDE.md.tmpl skeleton; hand off to arch lane for the remaining 5 files. Author `docs/sprints/sprint-30/close.md` + RETRO-030 + `docs/sprints/sprint-31/00-plan.md`.

---

## §4 — Sprint 30 PM Deliverables (lane-appropriate, per Sprint 13+ PM lane LOCKED)

| Wave | Item | Type | Lane | Owner |
|---|---|---|---|---|
| W1 | (none — dev-lane work, PM stand-by) | — | — | dev |
| W2 | #1073 verify-portage evidence PM PR | docs/sprints/** | PM | PM |
| W2 | #1072 awareness-coordination | (peer-poke dev if Sprint 30 W2 kickoff) | coord | PM |
| W3 | #1078 PM-authored USER-GUIDE.md.tmpl 1/6 | docs/** (.tmpl) | PM | PM |
| W3 | Sprint 30 close.md | docs/sprints/** | PM | PM |
| W3 | RETRO-030 retrospective | docs/sprints/** | PM | PM |
| W3 | Sprint 31 plan (00-plan.md) | docs/sprints/** | PM | PM |

**Total PM-authored Sprint 30 docs:** 5 files (verify-portage evidence + USER-GUIDE 1/6 + close.md + RETRO-030 + Sprint 31 plan). All in PM lane (docs/sprints/** + docs/product/**).

---

## §5 — Operational Items (PM lane)

### 5.1 — Label hygiene (Sprint 29 → Sprint 30 transition)

The 5 carry-over items currently have `sprint:current` label. At Sprint 30 W1 kickoff, atomically flip:
```bash
gh issue edit 1078 1072 1073 1075 1032 --remove-label sprint:current --add-label sprint:next
```
Then Sprint 30 W1 ceremony opens `[Sprint 30 Kickoff]` issue, atomically flips these 5 from `sprint:next` → `sprint:current`.

Per [[sprint-scope-gap-closing-audit-rule]] cycle ~#1995: gap-closing items stay `sprint:current` until sprint closeout. The `sprint:current` → `sprint:next` flip happens at the prior sprint's closeout ceremony, NOT pre-emptively. So: defer this flip until Sprint 29 closeout runs (currently Sprint 29 close.md exists but ceremony hasn't run — owner has not yet signaled sprint-close).

### 5.2 — Terminal closed items (4 items, NO ACTION)

| # | Title | Lane | Disposition |
|---|---|---|---|
| **#1068** | [calc-side-tracker] tmpl d1024+d1021 sister backport gap (Issue #99 sister) | — | TERMINAL CLOSED. backlog state = `closed-scope-cleanup`. NOT re-open. NOT Sprint 30. |
| **#1059** | [template-gap-close] dNNNN-template-env-decoupling-port — Phase A (RED-first d-test) | — | TERMINAL CLOSED. env-decoupling landed PR #1109 (squash 2026-07-16T19:40:38Z, Issue #1083 fix). backlog state = `closed-scope-cleanup`. |
| **#1058** | [template-gap-close] dev-studio-template port env-decoupling (cluster half-close follow-up) | — | TERMINAL CLOSED. Sister-pattern to #1059, both consolidated. backlog state = `closed-scope-cleanup`. |
| **#1049** | flaky(d058): TC1 per-issue view missing status:in-progress — search-index lag residual | — | TERMINAL CLOSED. P3 bug, residual post-PR #1044. backlog state = `closed-scope-cleanup`. |

**Per owner correction (cycle ~#2596):** "TEKRAR AÇMA, Sprint 30 plan'a DAHİL ETME" = "DO NOT re-open, DO NOT include in Sprint 30 plan". These 4 stay closed. backlog.json (when created) state = `closed-scope-cleanup`.

### 5.3 — Plan A items (work-done-elsewhere, 4 items, owner follow-up pending)

These 4 items (per cycle ~#2593 directive) are NOT in Sprint 30 scope per owner correction. They remain in their current OPEN state with work landed via separate PRs. Owner follow-up on closure/hygiene disposition is pending (orchestrator action item, not PM lane):

| # | Title | Status | Work landed via | Disposition |
|---|---|---|---|---|
| #1076 | [S29-017] Re-author template .claude/CLAUDE.md.tmpl + 5 soul .md.tmpl files (Phase 2 NEW) | OPEN, status:ready | PR #112 (squash 2026-07-15T15:22:30Z per `[[sprint-29-s29-017-soul-reauthor-merged]]`) | OWNER FOLLOW-UP. Orchestrator hygiene: add `status:done + agent:architect`, remove `sprint:current`. |
| #1061 | [agent-wake-hotfix] scripts/agent-wake.sh 3-fix hotfix (Sprint 29 W2) | OPEN, status:done | PR #1065 (per cycle ~#2593 directive) | OWNER FOLLOW-UP. Orchestrator hygiene: add `agent:developer`, remove `sprint:current`. |
| #1054 | [test] d1024-s29-ping-env-decoupling — notify.sh + peer-poke + agent-watch.sh env-decoupling d-test (RED-first) | OPEN, status:done | PR #1109 (squash 2026-07-16T19:40:38Z) | OWNER FOLLOW-UP. Orchestrator hygiene: add `agent:developer`, remove `sprint:current`. |
| #1011 | [Sprint 29] Kickoff — Template/Launcher Gap-Closure | OPEN, status:done | Sprint 29 kickoff executed | OWNER FOLLOW-UP. Orchestrator hygiene: add `agent:orchestrator`, remove `sprint:current`. |

**PM lane action:** Surface these 4 to orchestrator hygiene loop (cycle ~#2593 Plan A HOLD = owner follow-up needed). PM does NOT self-execute closure (orchestrator hygiene lane per ADR-0013).

### 5.4 — Closed-issue hygiene gap (board sync breakage per ADR-0013)

Per cycle ~#2457 audit: closed issues missing `status:done + agent:developer` cause board sync breakage. The 4 PLAN B terminal-closed items (#1068 #1059 #1058 #1049) all have this gap:

| # | Missing labels |
|---|---|
| #1068 | `status:done`, `agent:developer` (currently has `status:backlog + agent:developer` — needs status flip) |
| #1059 | `status:done` (currently has `status:ready`) |
| #1058 | `status:done` (currently has `status:ready`) |
| #1049 | `status:done`, `agent:developer` (currently has `status:backlog + agent:developer`) |

**Discipline:** Per RETRO-024 silent-skip, closed issues with `agent:* + status:ready + cc:human` pattern can be left alone (auto-claim filter exempts closed issues). But for **SAME-REPO closed issues**, the standard closed-state pattern is `type:* + status:done + agent:* + cc:*`. Surface to orchestrator hygiene pass.

### 5.5 — `docs/sprints/current/plan.md` refresh

Currently STALE (per cycle ~#2582 close, still says "Sprint 29 LIVE"). Refresh at Sprint 30 W1 kickoff to point to Sprint 30 plan (`docs/sprints/sprint-30/00-plan.md`). Owner-ratification gate: this refresh happens AFTER owner approves Sprint 30 plan (this doc).

### 5.6 — `backlog.json` state

Owner mentioned "backlog.json'da state=closed-scope-cleanup (NOT re-evaluable)". The file `docs/backlog/backlog.json` does NOT exist in this repo (verified 2026-07-16T20:14Z+03, cycle ~#2467). The `docs/backlog/` directory contains STORY-*.md files (PM-authored story docs) but no JSON backlog catalog.

**Two paths:**
- (a) Author `docs/backlog/backlog.json` as a new artifact (PM lane, docs/backlog/**) with `state: closed-scope-cleanup` entries for #1068 #1059 #1058 #1049.
- (b) Surface as TD: backlog.json is a sister-pattern from Sprint 13+ PM lane LOCKED that was never created. Defer to Sprint 31+ or retro-derive from existing GH state.

**Recommendation:** Surface to owner as open question; do NOT author backlog.json unprompted (could be unwanted scope drift per cycle ~#1988 owner discipline).

---

## §6 — Owner Approval Items (pending cycle ~#2596 follow-up)

PM requests owner ratification on the following before executing:

1. **Sprint 30 scope ratification:** Confirm the 5-item carry-over list (#1078 #1072 #1073 #1075 #1032) is the FINAL Sprint 30 scope. No additions, no subtractions.
2. **4 terminal-closed items (#1068 #1059 #1058 #1049) ratification:** Confirm backlog state `closed-scope-cleanup` is the canonical state name. Confirm NO Sprint 30 inclusion. Confirm these stay as-is (no further hygiene pass by PM).
3. **`docs/sprints/current/plan.md` refresh:** Confirm owner will approve the pointer refresh post-Sprint 30 plan ratification.
4. **`backlog.json` decision:** Does owner want (a) author backlog.json now (PM lane scope), (b) defer to Sprint 31+, or (c) skip entirely?
5. **Wave sequencing confirmation:** W1 = #1075+#1032 (P0), W2 = #1072+#1073 (P1), W3 = #1078 (P2). Any re-sequencing desired?
6. **Sprint 30 kickoff signal:** Per [[sprint-29-w3-pm-deliverable-list]] §W3 ceremony timing rule (sister-pattern), orchestrator opens `[Sprint 30 Kickoff]` issue + cc PM only AFTER owner signals sprint-close for Sprint 29. Sprint 29 cluster-squash 5/5 complete + close.md + RETRO-029 drafted — Sprint 29 closeout ceremony pending. Does owner signal Sprint 29 close + Sprint 30 launch now, or wait?

---

## §7 — PM Lane Posture (current)

**Active PM work (in-progress artifacts):**
- `docs/sprints/sprint-29/01-portage-verify.md` (7978 bytes, dated 2026-07-16T19:06) — PM-authored DRAFT for S29-014 verify-portage evidence. Header: "PM lane: @product-manager (claim cmt 4983497425, in-flight)". Mid-authoring. Will carry over to Sprint 30 W2 as #1073 work.
- `docs/sprints/sprint-29/s29-017-soul-amend-lineage.md` (8429 bytes, dated 2026-07-16T19:06) — ORCHESTRATOR-authored per its own header (NOT PM lane). Status: ✅ Complete per own header. Will land as part of Sprint 29 closeout (orchestrator lane, not PM).

**Branch state:** Currently on `pm/sprint-30-plan-authoring-2026-07-16` (created from origin/main, this PR's branch).

**Queue state:**
- `agent:product-manager=0` (no active PM work assignment)
- `cc:product-manager=1` (Issue #109 S29-013-FU parked dev-lane per [[s29-013-followup-parked]])

**Heartbeat:** Cycle ~#2467 appended (correction pickup). Cycle ~#2468+ will be silent-skip per ADR-0002 cadence unless owner ratifies this plan.

**Awaiting:** Owner ratification on §6 items above.

---

## §8 — Sister-Patterns

- [[sprint-29-w3-pm-deliverable-list]] — Sprint 29 W3 PM deliverable list, applied as Sprint 30 carry-over for #1073 + #1078
- [[sprint-29-owner-override-gap-closing-doctrine]] — cycle ~#1988 origin event (Sprint 29 gap-closing scope-locked)
- [[sprint-30-pm-lane-placement-decisions]] — earlier PM Sprint 30 placement memo (cycle ~#1974), now SUPERSEDED by cycle ~#2596 owner correction (this doc)
- [[sprint-scope-gap-closing-audit-rule]] — cycle ~#1995 audit rule, applied to Sprint 30 carry-over classification
- [[sprint-29-s29-013-followup-parked]] — Issue #109 parked-doctrine, NOT Sprint 30 (already gap-closing Sprint 29)
- [[orch-pr-merged-silent-skip-fail]] — cycle ~#1964 doctrine, applied to cluster-squash 5/5 PR_MERGED pickup in cycle ~#2457
- [[peer-poke-silent-skip-tool-error-not-ground-truth]] — cycle ~#2276 doctrine, applied to cycle ~#2457 orchestrator tmux-wake tool error
- [[sprint-29-cluster-squash-5of5-final-completion-cycle-2545]] — cycle ~#2545 + ~#2558 origin, cluster-squash 5/5 COMPLETE @ 19:40:30Z-19:40:45Z (PR #1104+#1105+#1106+#1109+#1111)
- [[sprint-29-RETRO024-Issue-1032-missed-hygiene-cycle-2247]] — Issue #1032 missed hygiene, applied as Sprint 30 W1 carry-over #1032

---

## §9 — Cycle Trail

| Cycle | Event | Disposition |
|---|---|---|
| ~#2452 | REPRIME post-/clear | Doctrine re-read, queue audit |
| ~#2453 | Katman-1 wake (Issue #109 parked) | REJECT label flip + peer-poke (parked-doctrine) |
| ~#2454-#2456 | Katman-1 silent-skip (cycle ~#2133 escalation counter 5/8 → 7/8) | Escalation threshold NOT yet hit |
| ~#2457 | **PR_MERGED event** (cluster-squash 5/5 in 15s) | Heartbeat + peer-poke orchestrator (tmux-wake failed) + peer-poke human (both channels) |
| ~#2458-#2465 | Katman-1 silent-skip (post-cluster-completion reset) | Counter 0/8 (reset) |
| ~#2466 | Dual-channel wake — owner directive cycle ~#2593 | PM interpreted: Sprint 30 = non-gap-closing (per memory [[sprint-30-pm-lane-placement-decisions]]). Started non-gap-closing plan authoring. |
| ~#2467 | **Owner correction cycle ~#2596** | Sprint 30 = gap-closing ONLY (#1078 #1072 #1073 #1075 #1032). 4 closed items TERMINAL. **This plan authored with corrected framing.** |

---

— @product-manager, 2026-07-16T20:14Z+03 (cycle ~#2467)
Sprint 30 plan: 5 carry-over gap-closing items. Awaiting owner ratification on §6 items.