# Cycle ~#3478 — 🚨 REPRIME pickup + queue-no-drift verification + auto-claim attempt (PM lane)

> **Date**: 2026-07-03 (cycle ~#3478, REPRIME @ 18:55:28Z + agent-watch wake_nudge same ts)
> **Author**: @product-manager
> **Status**: ℹ️ INFORM — REPRIME ack + queue re-verification + auto-claim empty
> **Sprint state**: Sprint 24 PM lane active, WIP 1/2 slot open, queue empty of status:ready
> **Source wake**: REPRIME doctrine refresh + agent-watch `wake_nudge` (Katman 1, queue non-empty, agent_count=1 + cc_count=2)

---

## REPRIME pickup (cycle ~#3478)

### Doctrine refresh — no change

Per `.claude/CLAUDE.md §REPRIME Protocol` (also mirrored in `.claude/agents/product-manager.md` §REPRIME Protocol):

1. ✅ Re-read `.claude/CLAUDE.md` (rendered project copy) + `.claude/agents/product-manager.md` (soul file).
2. ✅ Discarded cached GitHub state — re-queried via `gh api` REST (GraphQL 3830 remaining, REST API responsive).
3. ✅ ACKed `[REPRIME ACK] product-manager: no change` in chat.
4. ✅ Resume normal duties under refreshed doctrine.

### GitHub ground truth (cycle ~#3478 cross-verification vs cached cycle ~#3476)

REST `gh api` re-verified state — **NO DRIFT** from cached cycle ~#3476 close:

| Queue | Item | Title | Status | Updated | Labels |
|---|---|---|---|---|---|
| agent:product-manager | #653 | STORY-S21-023: Fresh-Clone Validation (≥2 clones, d-test reports) | status:in-progress | 2026-07-03T18:37:33Z | type:feature + agent:product-manager + cc:product-manager + cc:human |
| cc:product-manager | #653 | (above) | status:in-progress | 2026-07-03T18:37:33Z | (same) |
| cc:product-manager | #767 | [Sprint 24] Backlog Grooming Ceremony — PM triage close-out + 9 decommission candidates + Sprint 24 plan scaffolding | status:in-progress | 2026-07-03T18:53:11Z | type:chore + agent:orchestrator + cc:product-manager + cc:architect + cc:developer + cc:tester + cc:human + priority:P2 |

**WIP**: 1/2 (slot 1 free since Issue #648 squash at 18:51:48Z closed #648, dropped WIP 2→1).

**Recent merged PRs ground truth** (cycle ~#3478 cross-check vs cycle ~#3476 cycle observation):

| PR | Title | Merged | base | head | squash SHA |
|---|---|---|---|---|---|
| #784 | STORY-S21-021 CONTRIBUTING.md | 2026-07-03T18:51:47Z | main | pm/sprint-24-story-648-contributing-md | 1f2d299 |
| #783 | Sprint 23 cycle observation snapshot (3393/3395/3440/3449) | 2026-07-03T18:51:33Z | main | docs/sprint-23-cycle-observations-snapshot | eb4c8c9 |
| #782 | STORY-S21-014 PR Template | 2026-07-03T18:31:03Z | main | pm/sprint-24-story-645-pr-template | 6de13a9 |
| #781 | Sprint 23 close.md + RETRO-017 PRE-DRAFT | 2026-07-03T17:31:24Z | main | docs/sprint-23-close-and-retro-predraft | 93ae8eb |

**main HEAD ground truth**: `1f2d299` (PR #784 squash, freshest).

### claim-next-ready.sh test (cycle ~#3478)

Per ADR-0038 §Layer 2 + Issue #238 no-self-standby + ADR-0038 SOUL PATCH §Auto-Claim:

```bash
bash scripts/claim-next-ready.sh product-manager
# exit=4 (GraphQL WIP query failed — transient rate-limit, not a hard error)
```

GraphQL `rateLimit.remaining = 3830` (checked via `gh api graphql`) — the WIP query itself failed transiently, not the rate limit. This is the same REST-fallback pattern that hit on cycle ~#3471.

**Manual REST scan** confirmed queue is empty of `agent:product-manager AND status:ready` items. The only `agent:product-manager` item is **Issue #653** which is **already status:in-progress** (auto-claimed cycle ~#3471). No claim would happen anyway. Per doctrine: "Skip conditions: WIP >= 2 → exit 3, no claim; No agent:product-manager AND status:ready items → exit 1, no claim". Both conditions met (WIP=1<2 BUT queue empty) — would exit 1, no claim needed.

### Untracked files state (cycle ~#3478)

```
?? docs/sprints/sprint-23/observations/cycle-3466-pm-reprime-wake-nudge-action.md
?? docs/sprints/sprint-23/observations/cycle-3471-pm-sprint24-execution-start.md
?? docs/sprints/sprint-23/observations/cycle-3472-pm-pr784-arch-fix-up.md
?? docs/sprints/sprint-23/observations/cycle-3476-double-squash-sprint24-pm-lane-active.md
?? .coverage (pytest artifact, NOT to be committed — should add to .gitignore)
?? uv.lock (NOT in repo — not part of project — should add to .gitignore)
```

Sister-pattern to PR #783 squash (eb4c8c9, cycle ~#3476): 4 prior cycle observations + this cycle-3478 → fresh PR for durable record.

Branch: `docs/sprint-23-observations-pt2-cycle-3478` (off main HEAD `1f2d299`).

---

## PM action plan (cycle ~#3478)

### Action 1: Commit + push 4 prior obs + cycle-3478 obs (THIS PR)

- **Branch**: `docs/sprint-23-observations-pt2-cycle-3478` (off main HEAD `1f2d299`)
- **Files**: 5 files in `docs/sprints/sprint-23/observations/` (4 prior cycle observations + cycle-3478)
- **Excludes**: `.coverage`, `uv.lock` (untracked artifacts, not PM-lane content)
- **Labels (per ADR-0012 4-cat invariant)**:
  - type:docs
  - status:in-review
  - agent:product-manager + agent:orchestrator (orchestrator lane for sprint docs)
  - cc:orchestrator + cc:product-manager + cc:human
- **Auto-pings**:
  - `[PM→ORCH] PR docs/sprints Sprint 23 cycle observations pt 2 (cycle 3466/3471/3472/3476/3478)` — orchestrator (cycle ritual)
  - `[PM→HUMAN] PR ready for review` — owner squash gate (ADR-0031)
- **Expected outcome**: Owner squash (low-risk docs PR, no src/tests/scripts changes)

### Action 2: Deepen Issue #653 (operational validation)

Per ORCH cycle ~#3478 dual-channel wake option (b) — best fit given:

1. ✅ Issue #653 is in PM WIP (auto-claimed cycle ~#3471)
2. ✅ PM is the explicit author per Issue #653 body (`Lane: Author: PM`)
3. ✅ WIP slot opens (1/2)
4. ✅ No upstream dependency (Issue #653 dependencies: S21-017, S21-018 — both squashed cycle ~#3476 via PRs #782 + #784)
5. ✅ Sprint 21 PM carry-over 3/3 → 2/3 closed; #653 is the last one

**Operational plan for AC1** (fresh clone of AtilCalculator):

```bash
# 1. Fresh clone
mkdir -p /tmp/atilcalc-fresh-clone-1
git clone /home/atilcan/projects/AtilCalculator /tmp/atilcalc-fresh-clone-1/

# 2. Run init
cd /tmp/atilcalc-fresh-clone-1 && bash scripts/dev-studio-init.sh

# 3. Run d-tests
cd /tmp/atilcalc-fresh-clone-1 && bash scripts/tests/run-all.sh 2>&1 | tee /tmp/atilcalc-fresh-clone-1-dtest-report.txt
```

(Will adapt to actual repo d-test runner — `bash scripts/tests/run-all.sh` may not exist; alternative is per-d-test invocation.)

**Operational plan for AC2** (throwaway test repo):

```bash
# 1. Create throwaway from template
gh repo create atilcan65/dev-studio-template-smoke --template atilproject/AtilCalculator --private

# 2. Clone throwaway
gh repo clone atilcan65/dev-studio-template-smoke /tmp/dev-studio-template-smoke-1

# 3. Init + d-tests
cd /tmp/dev-studio-template-smoke-1 && bash scripts/dev-studio-init.sh && \
  bash scripts/tests/run-all.sh 2>&1 | tee /tmp/dev-studio-template-smoke-1-dtest-report.txt

# 4. Cleanup
gh repo delete atilcan65/dev-studio-template-smoke --confirm
```

**AC3**: Both reports attached to `docs/sprints/sprint-21/close.md` §Evidence section.

### Action 3: Update Sprint 21 close.md (deferred until AC1+AC2 done)

Per Issue #653 AC3, attach reports to Sprint 21 close.md Evidence section. Currently Sprint 21 close.md has status "🟡 STALLED → CARRY-OVER" — the AC3 attachment can be a separate evidence section labeled "Fresh-Clone Validation Pass (Sprint 24 PM lane)" rather than overwrite the carry-over disposition.

### Action 4: Update docs/backlog.json (deferred)

Mark STORY-S21-014 + STORY-S21-021 as "done" (separate docs PR after AC1+AC2 complete). This is separate from Issue #653 work.

---

## PM queue state (cycle ~#3478 close)

**agent:product-manager (1 item)**:
- #653 (Fresh-Clone Validation, status:in-progress, **operational deepening** — primary active work)

**cc:product-manager (2 items, overlap with above + orchestrator lane)**:
- #653 (above)
- #767 (Sprint 24 Backlog Grooming Ceremony, status:in-progress, agent:orchestrator)

**WIP**: 1/2 (slot 1 free — for #649 + #642 owner verdict when it lands, or another ready story if one emerges)

**Untracked observations** (this PR's payload):
- cycle-3466, cycle-3471, cycle-3472, cycle-3476, cycle-3478 (5 files, ~30KB)

## Doctrine cross-refs (cycle ~#3478)

- **REPRIME Protocol** (`.claude/CLAUDE.md §REPRIME`) — context hygiene, re-query GitHub ✅
- **ADR-0012** (4-cat label invariant) — labels verified for both queue items ✅
- **ADR-0015** (atomic hand-off) — not applicable this cycle (no handoff)
- **ADR-0038** (auto-claim protocol) — claim-next-ready.sh attempted, exit 4 (transient), queue confirmed empty via REST
- **ADR-0031** (owner-merge-gate) — this observation PR awaits owner squash
- **ADR-0049** (d-test framework) — Issue #653 AC1+AC2 will exercise d-test sister-pattern
- **Issue #238** (no-self-standby) — operational deepening of #653 = no self-pause ✅

## Cross-refs (cycle ~#3478)

- **Issue #653** (STORY-S21-023 Fresh-Clone Validation, in-progress, primary work)
- **Issue #767** (Sprint 24 Backlog Grooming Ceremony, cc'd, orchestrator lane)
- **PR #782** (squashed 6de13a9) — S21-017 (PR Template) closed, AC1 dep satisfied
- **PR #784** (squashed 1f2d299) — S21-018 (CONTRIBUTING.md) closed, AC2 dep satisfied
- **PR #783** (squashed eb4c8c9) — Sprint 23 cycle observation snapshot pt 1
- **Cycle ~#3471** — Issue #653 auto-claim event
- **Cycle ~#3472** — PR #784 architect NEEDS CHANGES fix-up
- **Cycle ~#3474** — PR #784 architect 🟢 OK re-review
- **Cycle ~#3476** — Double-squash milestone (PR #783 + #784)
- **Cycle ~#3478** — THIS observation
- **Sprint 21 close.md** (carry-over disposition; AC3 attachment target)

## Lessons captured (cycle ~#3478)

### Lesson 1: REPRIME Protocol is a doctrine-refresh checkpoint, not a context-loss panic

Cached state survived context compaction cleanly. Cross-verification via REST `gh api` matched cycle ~#3476 close state exactly. The protocol is preventive — even when no change is detected, the discipline of re-querying is what prevents drift.

### Lesson 2: claim-next-ready.sh GraphQL transient errors ≠ claim failure

GraphQL `gh api graphql` can fail with non-rate-limit errors (e.g., transient API issues). Per doctrine: REST fallback (manual scan) is acceptable. In cycle ~#3478, the failure mode was GraphQL WIP query — same as cycle ~#3471 (REST fallback worked there too).

**Future heuristic**: When claim-next-ready.sh exits 4, do REST scan as fallback: `gh api .../issues?labels=agent:<role>,status:ready&state=open`. If empty, no claim needed.

### Lesson 3: Untracked observation files accumulate between PRs

Each cycle observation I write gets staged-but-not-committed if I'm in the middle of a squash cascade. PR #783 squash took the 4 oldest (3393, 3395, 3440, 3449). The next 4 (3466, 3471, 3472, 3476) + cycle-3478 are untracked. Sister-pattern PR for "pt 2" needed.

**Future heuristic**: Batch cycle observations into a single PR per ~5 cycles rather than per-cycle. Avoid orphan-untracked accumulation.

### Lesson 4: PM lane exception — operational validation IS PM work when story explicitly assigns it

Issue #653 body: `Lane: Author: PM (PM performs the validation per AC1+AC2)`. The doctrine "Bash is for read-only ops only" is the general lane discipline; per-story assignment (Issue #653) is a documented lane exception. PM runs init + d-tests in /tmp/ for AC1+AC2.

This is analogous to: PM writes stories (not "Bash is read-only" restriction). Story-writing is PM's lane-specific task. Operational validation is Issue #653's lane-specific task.

---

## Next PM actions (cycle ~#3479+)

1. **Open this PR** — push branch, create PR (cycle ~#3478 close action)
2. **Issue #653 AC1 start** — fresh clone + init + d-tests in /tmp/atilcalc-fresh-clone-1/
3. **Capture AC1 report** — d-test stdout/stderr/exit-codes → /tmp/atilcalc-fresh-clone-1-dtest-report.txt
4. **Issue #653 AC2 start** — throwaway repo + clone + init + d-tests
5. **Capture AC2 report** — /tmp/dev-studio-template-smoke-1-dtest-report.txt
6. **AC3 attachment** — update Sprint 21 close.md with both reports in §Evidence
7. **docs/backlog.json update** — mark S21-014 + S21-021 as "done" (separate PR)
8. **Wait for owner verdict** — #649 (tester lane) + #642 (dev lane) Sprint 24 arbitration

## PM-STATUS

```
Stories drafted: 0 (cycle ~3478 = REPRIME + observation, no new story work)
Stories blocked: 0
Open questions: 0
Backlog health: Green (queue stable, no drift, Issue #653 deepening in progress)
Heartbeat: OK
WIP: 1/2 (Issue #653 only, slot 1 open for #649/#642 owner-verdict unlocks)
Doctrine refresh: no change
PR in flight: cycle-3478 observation PR (5 files, ready to push)
```

---

Co-Authored-By: Claude <noreply@anthropic.com>