# RETRO-035 — Sprint 35 Lessons Learned

> **Sprint**: Sprint 35 — New-Project Bootstrap Preflight Audit (2026-07-27 → 2026-07-29)
> **Author**: @orchestrator (Lane 4)
> **Audience**: future sprints, RETRO-036+ retroactive codification candidates
> **Cycle anchors**: ~#1105 (Lane 4 dev self-ACK), ~#1106 (cluster TERMINAL 3-gate), ~#1109 (NEW DOCTRINE RECURSIVE), ~#911 (owner-squash-witness), ~#940 (PROCESS-GAP)

---

## Top 5 NEW DOCTRINE formalized (Sprint 35)

### 1. cycle ~#1109 — RECURSIVE defect cascade pattern (9 layers deep)

**Discovery**: When a workflow runs RED at step N, you fix step N, re-trigger, and it goes RED again at step N+1 — but the cause is in step N's data flow leaking into step N+1.

**LIVE VALIDATION**: cluster #41 9-layer cascade (S35-004) — Issues #231 → #233 → #235 → #237 → #239 across 5 PRs (#232 #234 #236 #238 #240).

**Rule** (codified as RETRO-035 candidate #1):
- After each RED → fix → re-trigger cycle, do NOT assume the next RED is at the next sequential step.
- Investigate the previous step's data flow: did the fix change any state that propagates downstream?
- If a fix introduces a new credential / file / remote / flag, that flag itself can become a defect class.

**Sister-patterns**: TD-016 (silent-skip), TD-030 (auto-gen file refs), RETRO-024 (work-done-elsewhere).

### 2. cycle ~#1106 — cluster TERMINAL 3-gate

**Discovery**: "Cluster TERMINAL" was under-specified — it could mean (a) all PRs verdict 3/3 OR (b) verdict + mergeable OR (c) verdict + mergeable + Run GREEN.

**LIVE VALIDATION**: cluster #41 cascade close at 06:56:18-38Z was HELD per cycle ~#940 doctrine until Run GREEN; retroactively cluster TERMINAL once Run #10 GREEN arrived 07:15:32Z.

**Rule** (codified as RETRO-035 candidate #2):
- A cluster is TERMINAL only when ALL 3 gates pass:
  - (a) verdict chain 3/3 on all PRs
  - (b) all PRs mergeable=MERGEABLE+CLEAN
  - (c) downstream Run (workflow / CI / pipeline) GREEN
- Cascade close (10-issue close-out) is NOT the same as TERMINAL — cascade close can fire on (a)+(b) retroactively, but cluster TERMINAL requires (c) too.
- Cluster TERMINAL is the gating condition for cluster-squash (ADR-0059) and next-wave dispatch.

### 3. cycle ~#911 — owner-squash-witness (11th live validation)

**Discovery**: Peer agent must witness owner squash within 60s of merge to detect owner-squash-on-wrong-content (mistaken content vs intended fix).

**LIVE VALIDATION**: PR #240 squash at 06:43:43Z sha `1106ea0`, witness cmt posted at 06:45:07Z (cycle ~#911 11th validation).

**Rule** (codified as RETRO-035 candidate #3):
- After owner squash, peer (the lane-4 dev or orchestrator) MUST post a squash-witness cmt within 60s confirming:
  - mergeCommit: `<sha>` (short)
  - mergedAt: `<iso ts>`
  - mergedBy: `@<owner>`
  - verdict chain 3/3 PRESERVED per cycle ~#3968Q+407
  - squash-gate OPEN per ADR-0031
- If squash-witness cmt shows verdict chain broken, raise STRIKE flag immediately.

### 4. cycle ~#940 — PROCESS-GAP investigate-before-framing

**Discovery**: When a defect is observed, the natural impulse is to frame it as "X broke Y". The PROCESS-GAP doctrine says: investigate FIRST, frame SECOND. Often the framing was wrong, and the doctrine-correction is more important than the immediate fix.

**LIVE VALIDATION**: PR #240 cluster cascade close at 06:56:18-38Z — my orchestrator edit at ~06:19:30Z (Lane 4 hygiene) raced with tester's Lane 3 verdict; the PROCESS-GAP fix was to NOT remove tester's verdict (preserve per ADR-0024) and wait for Lane 2.

**Rule** (codified as RETRO-035 candidate #4):
- Before framing a defect, run ground-truth: re-query GitHub for current label state, recent comments, recent CI runs.
- If framing the defect would require violating another doctrine, that framing is WRONG. Find the doctrine-respecting framing.
- Honesty correction comments are mandatory when a prior framing is reversed (cycle ~#940 PROCESS-GAP formalized via PR #236 NIT BLOCKING cmt 5108641152).

### 5. cycle ~#311+22 — 5-flag atomic Lane 3 MUTEX (already formalized, Sprint 35 5th live validation)

**Discovery**: Lane 3 sign-off must atomically execute 5 flag operations in correct order, otherwise mutual exclusion violation on status:* labels.

**LIVE VALIDATION**: cluster #41 5 PRs × Lane 3 sign-off — all 5 PRs passed MUTEX (cycle ~#311+22 5th-9th live validations).

**Rule** (already formalized in ADR-0024 amendment #2):
1. REM `needs-tester-signoff`
2. REM `cc:tester`
3. CREATE+ADD `verdict-by:tester:<ts>`
4. ADD `status:ready`
5. REM `status:in-review`

---

## Sprint 35 deferred items (carry to Sprint 36+)

### RETRO-035 candidates (pre-existing)

1. **#29 — peer-poke.sh verify uncertain bug** (rc=1 sentinels fail on dev pane)
2. **#39 — arch MEMORY.md linter inherited bad pointer defect**
3. **#43 — Lane 4 dev verdict-by label not applied despite claim**

These are pre-Sprint-35 deferred items; carry to RETRO-036.

### New deferrals from Sprint 35

4. **Cycle ~#3968Q+941 multi-remote awareness STRIKE 2 NEW DOCTRINE formalization** (Issue #1250 — agent:architect backlog)
5. **Cycle ~#3968Q+940 PROCESS-GAP fix + 4-vs-5 carry-over orchestrator adjudication** (Issue #1249 — agent:architect backlog)
6. **Cycle ~#3968Q+933 Lane 3 re-query arch verdict COMMENT NEW DOCTRINE formalization** (Issue #1248 — agent:architect backlog)
7. **Cycle ~#3968Q+911 owner-squash-witness NEW DOCTRINE formalization** (Issue #1247 — agent:architect backlog)

These 4 ADR drafts are the architectural codification of Sprint 35's NEW DOCTRINE; they need to be written as proper ADRs in Sprint 36.

### Hygiene items (not blocking)

8. **AtilCalculator local main 2 commits behind origin** (owner acknowledged 2026-07-29, not blocking)
9. **Untracked soul files** (`.claude/agents/*.md`, `CLAUDE.md`, `docs/sprints/sprint-35/`) — owner pre-existing workflow, not blocking

---

## Sprint 35 NEW DOCTRINE — ready for ADR codification

| Cycle | One-liner | ADR candidate |
|---|---|---|
| ~#1105 | Lane 4 dev self-ACK on own PRs (verdict-by:developer:<ts>) | ADR-0076 candidate |
| ~#1106 | cluster TERMINAL 3-gate (verdict + mergeable + Run GREEN) | ADR-0077 candidate |
| ~#1109 | RECURSIVE defect cascade pattern (fix → re-trigger RED at next step → investigate data flow) | ADR-0078 candidate |
| ~#911 (formalized) | owner-squash-witness within 60s | ADR-0079 candidate |
| ~#940 (formalized) | PROCESS-GAP investigate-before-framing | ADR-0080 candidate |
| ~#941 | multi-remote awareness STRIKE 2 | ADR-0081 candidate |

---

## Sprint 35 highlights (PR-of-the-sprint)

**PR #240** — `fix(workflows): S35-004 Option H+I rm -rf /tmp/disposable + REST API teardown (Issue #239 9th-order fix, Run #9 RED 30427156219)`
- 4 files +99/-27
- SQUASH-MERGED 2026-07-29T06:43:43Z sha `1106ea0`
- 19/19 d-test GREEN (extended from ≥6 baseline per ADR-0049)
- cycle ~#911 11th squash-witness posted
- cluster #41 9-layer cascade TERMINAL ✅
- **Most-tested PR of Sprint 35** — survived 9-layer defect cascade + multiple Lane 2/3 verdict iterations

---

## Squad sign-off

- **PM Lane 1** (#1235): SPRINT 34 RESIDUAL VERIFICATION complete
- **Architect Lane 2** (#1236): PARITY MATRIX AUDIT complete
- **Developer + Architect reviewer** (#1238): GAP-CLOSING PATCHES complete
- **Tester + Dev RCA** (#1237): DISPOSABLE BOOTSTRAP complete
- **Owner-driven + Tester docs** (#1239): LIVE SMOKE complete
- **Owner + PM Lane 1 docs (delegated)** (#1240): GREEN-LIGHT CHECKLIST complete
- **Orchestrator + Owner squash** (#1241): CLOSE CEREMONY pending owner verbatim marker

---

**RETRO-035 captures 5 NEW DOCTRINE formalizations + 9 deferred items (4 ADR drafts + 3 pre-existing RETRO candidates + 2 hygiene).**

— @orchestrator (Lane 4), 2026-07-29T07:35Z, cycle ~#3968Q+1109 RECURSIVE 9-layer LIVE VALIDATION TERMINAL ✅
