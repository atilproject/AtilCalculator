# RETRO-024 — Work-done-elsewhere terminal state + 4-cat Invariant Repair Silent-Skip Rule

> **Status:** Codified (architect cluster-squash PR open per ADR-0059 + ADR-0055 §1)
> **Sprint:** 28 (post-close lightweight retro, ratified 2026-07-14 cycle ~#1506)
> **Date:** 2026-07-14
> **Author:** @architect (per `docs/decisions/**` + `docs/designs/**` lane in file ownership matrix)
> **Doctrinal home:** Issue #1027 (cross-link canonical)
> **Sister-pattern:** RETRO-022 (Issue #1023, original 4-cat gap doctrine), RETRO-023 (Issue #1024, cross-repo workstream codification)

---

## §1 — Context

RETRO-024 codifies **two distinct but coupled live-instance failure modes** in the 4-cat invariant repair logic surfaced during Sprint 28 + Sprint 29 W1-W2:

### 1.1 Cycle #1223 — Orchestrator reflexive 4-cat repair (work-done-elsewhere re-pull)

**Symptom:** Orchestrator reflexively added `agent:developer` to work-done-elsewhere issues **#1015 (STORY-S29-003)** + **#1017 (STORY-S29-005)**, "fixing the invariant gap". This re-enabled `scripts/claim-next-ready.sh` (ADR-0038 §Layer 2) auto-claim on **already-completed items**, pulling them back into dev WIP — visible churn + ghost work on already-shipped PRs.

**Root cause:** The 4-cat invariant (ADR-0012) does NOT have an explicit EXCEPTION clause for cross-repo sister-PR work. Reflexive repair scripts (orchestrator hygiene loop, `gh issue edit` autofix) blindly add `agent:*` to any issue missing one, including work-done-elsewhere terminal states.

**Doctrine gap:** No codification of "what does an AtilCalculator issue look like when its work is tracked via a sister PR in another repo?"

### 1.2 Cycle #1253 — PM reflexive AC-verify approval (sister-pattern recursion)

**Symptom:** Product Manager approved RETRO-024 ACs (🟢 APPROVED 3/3 met) **without file-state verification**. The exact reflexive anti-pattern RETRO-024 was filed to address — by the very role owning the doctrine codification.

**Root cause:** Approval heuristics that count AC bullets without verifying file-state (file exists on disk, has expected content, lives at canonical path, is in git index) are themselves reflexive. They mirror the orchestrator 4-cat repair reflex.

**Doctrine gap:** No codification of "silent-skip" behavior for 4-cat-repair scripts when an issue already matches a known terminal state pattern.

### 1.3 Coupled failure mode

The two cycles share a root cause: **lack of codified silent-skip behavior for known terminal-state patterns**. Both reflect reflexive "complete the invariant" reflexes that ignore the possibility that the invariant has an EXCEPTION clause.

---

## §2 — Doctrine codified

Two amendments to `.claude/CLAUDE.md` + `CLAUDE.md.tmpl` §Handoff Label Discipline (insertion point: after `### Terminal hand-off (Done)`, before `### Label semantik sözlüğü`):

### 2.1 §Work-done-elsewhere terminal state (RETRO-024 amendment)

Canonical terminal state for cross-repo sister-PR work (per RETRO-023, Issue #1024):

```
type:<feature|chore|...> + status:ready + cc:human + (NO agent:*)
```

**Why 4-cat-compliant:** The issue has a clear `cc:human` merge gate (owner squash-merge gate per ADR-0031); the absent `agent:*` signals "work tracked elsewhere, do NOT auto-claim". This is a **4-cat-compliant EXCEPTION** to the universal ADR-0012 invariant.

**Anti-patterns prevented:**
- ❌ Reflexive `agent:developer` addition by 4-cat-repair scripts (cycle #1223)
- ❌ `claim-next-ready.sh` re-claiming completed work (RETRO-022 regression class)
- ❌ PM reflexive AC-verify approval without file-state check (cycle #1253)

### 2.2 §4-cat Invariant Repair Silent-Skip Rule (RETRO-024)

Any 4-cat-repair script (orchestrator hygiene loop, `gh issue edit` reflexive fix, post-PR-script label normalization) **MUST silent-skip** when an issue's current labels already match the work-done-elsewhere terminal state pattern.

**Implementation gate:** `scripts/claim-next-ready.sh` (auto-claim, ADR-0038 §Layer 2) and any future 4-cat-repair helper MUST filter `status:ready + cc:human` items from their result sets BEFORE the next claim/repair step. `silent_skip` log emission to `auto-claim.log` is required (lens d observability, TD-016/020 family sister-pattern).

**Log format:**
```
_wd_now_iso $ROLE work-done-elsewhere-silent-skip (count=N) silent_skip
```

---

## §3 — Implementation gate

### 3.1 `scripts/claim-next-ready.sh` filter step (RETRO-024 AC3)

Inserted after Form C handling, before ready_count computation:

```bash
# --- RETRO-024 silent-skip on work-done-elsewhere terminal state (Issue #1027) ---
WORK_DONE_ELSEWHERE_COUNT=$(printf '%s' "$ready_raw" | \
  jq '[.[] | select(.labels | map(select(.name == "cc:human")) | length > 0)] | length' \
  2>/dev/null || echo 0)
if [ "${WORK_DONE_ELSEWHERE_COUNT:-0}" -gt 0 ]; then
  ready_raw="$(printf '%s' "$ready_raw" | \
    jq '[.[] | select(.labels | map(select(.name == "cc:human")) | length == 0)]' \
    2>/dev/null)"
  # log emission per TD-016/020 family (lens d observability)
fi
```

### 3.2 `scripts/tests/d-retro-024-4cat-repair-silent-skip.sh` (RETRO-024 AC3 d-test, 7 TCs)

Sister-pattern to `d955` (STORY-S26-003 strict-contract) + `d853` (STORY-S26-002 canary config.yml) + `d020a` (Form C race detection). RED-first per ADR-0044 — pre-impl 6/7 FAIL (TC5 PASS-by-self); post-impl 7/7 GREEN. Cadence Rule 1 atomic per ADR-0055 §1 — file + INDEX.md row + CLAUDE.md amend + claim-next-ready.sh impl all land in same architect cluster-squash PR.

---

## §4 — Cluster-squash PR scope (one PR, all coupled ACs per ADR-0059)

| File | AC | Type |
|---|---|---|
| `.claude/CLAUDE.md` | AC2 doctrine amend (rendered) | doc |
| `CLAUDE.md.tmpl` | AC2 doctrine amend (source — ADR-0013 + ADR-0050) | doc |
| `scripts/claim-next-ready.sh` | AC3 impl: silent-skip filter + log emission | impl |
| `scripts/tests/d-retro-024-4cat-repair-silent-skip.sh` | AC3 d-test: 7 TCs RED-first | test |
| `scripts/tests/INDEX.md` | Cadence Rule 1 atomic per ADR-0055 §1 | doc |
| `docs/sprints/sprint-28/RETRO-024.md` | this file (cross-link + LIVE INSTANCE record) | doc |

All in **one architect PR** per ADR-0059 cluster-squash doctrine + ADR-0055 §1 Cadence Rule 1 atomic. 4-cat labels per ADR-0012: `type:docs` + `status:in-review` + `agent:architect` + `cc:developer` + `cc:tester` + `cc:product-manager`.

---

## §5 — Sister-pattern lineage

| Source | Relation | Anchor |
|---|---|---|
| **RETRO-022 (Issue #1023)** | Direct sister | Original 4-cat gap doctrine — `claim-next-ready.sh` re-flip on completed work; 3+ live instances at author |
| **RETRO-023 (Issue #1024)** | Direct sister | Cross-repo workstream codification — sister-PR terminal state pattern recognition |
| **ADR-0012** | Parent | 4-cat label invariant — the contract RETRO-024 amends with EXCEPTION |
| **ADR-0015** | Sibling | Atomic 4-flag handoff — applies OUTSIDE the work-done-elsewhere terminal state |
| **ADR-0038** | Anchor | Auto-claim protocol, §Layer 2 — the implementation home for silent-skip |
| **ADR-0044** | Doctrinal | RED-first TDD — d-test BEFORE impl, verified via d-retro-024 6/7 FAIL baseline |
| **ADR-0049** | Doctrinal | d-test framework ≥5 TCs — d-retro-024 = 7 TCs exceeds baseline by 2 |
| **ADR-0055 §1** | Doctrinal | Cadence Rule 1 atomic — d-test + INDEX.md row + impl same commit |
| **ADR-0059** | Doctrinal | Cluster-squash doctrine — RETRO-024 ships as ONE PR with all coupled ACs |
| **d955** | Sister-test | STORY-S26-003 strict-contract, 5 TCs GREEN — same cluster-squash + RED-first + per-TC marker pattern |
| **d853** | Sister-test | STORY-S26-002 canary config.yml, 7 TCs GREEN — same Cadence Rule 1 INDEX.md row in TC7 + --self-test in TC4 |
| **d020a** | Sister-test | Form C race detection, 5 TCs GREEN — same amend-in-claim-next-ready.sh pattern |
| **TD-016** | Sister-TD | Silent-skip risk observability discipline |
| **TD-020** | Sister-TD | Silent-skip preflight pattern (stale-lock-cleanup log line shape) |
| **Issue #113** | Doctrinal | Label-authority — labels > body text; work-done-elsewhere terminal state has NO `agent:*` label, this is INTENTIONAL per the EXCEPTION |

---

## §6 — Cross-references

- **Issue #1027** — RETRO-024 doctrinal home (orchestrator hand-off cycle ~#1506, 2026-07-14T00:36Z)
- **Issue #1023** — RETRO-022 (4-cat gap origin)
- **Issue #1024** — RETRO-023 (cross-repo workstream codification)
- **Issue #113** — Label-authority doctrine (the foundational invariant RETRO-024 EXCEPTIONs)
- **`.claude/CLAUDE.md`** §Handoff Label Discipline — §Work-done-elsewhere terminal state + §4-cat Invariant Repair Silent-Skip Rule subsections
- **`CLAUDE.md.tmpl`** §Handoff Label Discipline — source for re-render (ADR-0013 + ADR-0050)
- **`scripts/claim-next-ready.sh`** — silent-skip filter impl + `_wd_now_iso ... work-done-elsewhere-silent-skip (count=N) silent_skip` log emission
- **`scripts/tests/d-retro-024-4cat-repair-silent-skip.sh`** — 7 TCs d-test, sister-pattern to d955/d853/d020a
- **`scripts/tests/INDEX.md`** — Cadence Rule 1 atomic row (this PR)
- **`/var/log/dev-studio/AtilCalculator/auto-claim.log`** — runtime audit log (lens d observability)

---

*Authored 2026-07-14 cycle ~#1506 by @architect. Cluster-squash PR open per ADR-0059 + ADR-0055 §1. Owner squash-merge gate per ADR-0031.*