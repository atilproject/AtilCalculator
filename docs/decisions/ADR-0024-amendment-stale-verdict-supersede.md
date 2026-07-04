# ADR-0024 Amendment: Stale-Verdict Supersede Rule (latest `verdict-by:<ts>` canonical when multiple present)

- **Status:** Proposed (Issue #828 codification, cluster blocker for Bug #827 squash wave)
- **Date:** 2026-07-04
- **Deciders:** @architect (doctrine/spec), @developer (yaml + scripts/agent-watch.sh impl per file ownership matrix — developer owns `scripts/`, `.github/workflows/` is human-only territory → owner merges), @tester (d-test contract — ≥5 TCs RED-first per ADR-0044 + ADR-0049), @orchestrator (workflow integration + manual-suppress workaround doctrine), @atilcan65 (owner squash gate for workflow YAML + cluster sequencing)
- **Parent ADR:** [ADR-0024](./ADR-0024-stale-verdict-watchdog-schema.md) — Stale-Verdict Watchdog Schema (`verdict-by:<ts>` labels + `stale_verdict` events)
- **Amends:** ADR-0024 §Watchdog logic by adding §Supersede rule (canonical deadline = latest `verdict-by:<ts>` when multiple present)
- **Closes:** Issue #828 (stale_verdict hook false-positive on PR #816 — 3 wake instances in 12min cycle #4075-#4085)
- **Sister-patterns:** [ADR-0024-amendment-auto-verdict-by-hook](./ADR-0024-amendment-auto-verdict-by-hook.md) (auto-pair on `cc:<peer>` add — same family), [ADR-0002-amendment-1-stale-verdict-filter-scope](./ADR-0002-amendment-1-stale-verdict-filter-scope.md) (verdict-authority discriminator — closes Issue #798), ADR-0069 Form C (race-detection doctrinal codification pattern), ADR-0055 §1 Cadence Rule 1 atomic, ADR-0052 §30s re-query window (CI propagation timing), ADR-0044 RED-first TDD
- **Related:** Bug #827 (sister cluster blocker — `scripts/status-action-driver.sh` PR exclusion, currently re-flipping squash cluster PRs every ~1-2min); PR #816 (live instance — observed 3 stale_verdict wakes c4.41, c4.44, c4.46 in 12min); PR #799 (sister-pattern fix for Issue #798); Issue #798 (Layer 5 j.4 — verdict-authority false-positive, sister class)

---

## Context

ADR-0024 §Watchdog logic codifies that `stale_verdict` events fire when `verdict-by:<ts>` deadline passes without a verdict. ADR-0024-amendment-auto-verdict-by-hook (Issue #681) auto-pairs `verdict-by:<default-deadline>` (PR creation + 24h) on `cc:<peer>` add.

**Gap observed**: when multiple `verdict-by:<ts>` labels exist on a PR (e.g., an older stale deadline + a newer extended deadline), the watchdog hook continues firing on the **older** timestamp. The hook does NOT recognize the newer label as superseding the older. False-positive wake loop results.

### Live instance (PR #816, cycle #4075-#4085, 2026-07-04)

| Time (UTC) | Event | `verdict-by:<ts>` state |
|---|---|---|
| 2026-07-04T14:48:44Z | PR #816 `cc:architect` paired (auto-verdict-by hook) | `verdict-by:2026-07-04T14:48:44Z` |
| 2026-07-04T14:49:38Z | stale_verdict wake #1 (deadline 14:48:44Z passed, age 54s) | unchanged |
| 2026-07-04T14:54:42Z | stale_verdict wake #2 (age 358s) | unchanged |
| 2026-07-04T15:00:33Z | stale_verdict wake #3 (age 712s) | unchanged |
| 2026-07-04T15:01:14Z | architect manually flipped sentinel | `verdict-by:2026-07-08T15:00:00Z` |
| 2026-07-04T15:01:14Z+1min | Bug #827 status flip-back loop re-triggered auto-verdict-by hook | re-added `verdict-by:2026-07-04T14:48:44Z` (loop restored) |
| ... | wake loop continues until Bug #827 fix lands | ... |

**Defect class** (sister to Issue #798 verdict-authority false-positive):
1. **Convention violation**: multiple `verdict-by:<ts>` labels without supersede rule = watcher-silent stall / false-positive dual.
2. **Cluster amplification**: Bug #827 status flip-back loop re-triggers auto-verdict-by hook, which re-adds the older `verdict-by:<ts>` label, perpetuating the wake loop until either Bug #827 fix lands OR manual sentinel applied.
3. **Workaround degradation**: manual `verdict-by:<future-ts>` update works transiently but Bug #827 re-emits the old label within 1-2min.
4. **Architectural debt**: doctrinal gap in ADR-0024 — schema is multi-label-tolerant (multiple `verdict-by:<ts>` allowed), but watchdog logic does not define canonical-deadline semantics.

The fix is to **codify the supersede rule** — when multiple `verdict-by:<ts>` labels exist, the **latest (max ISO 8601)** is canonical; the watchdog MUST skip items where ANY `verdict-by:<ts>` deadline is in the future.

---

## Decision

**§Supersede Rule** — amend ADR-0024 §Watchdog logic with the following canonical-deadline semantics:

### 1. Multiple-label canonical deadline

When a PR/issue has multiple `verdict-by:<ts>` labels:

1. **Parse all labels** matching the regex `^verdict-by:\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`.
2. **Canonical deadline** = `max(parsed_timestamps)` (latest ISO 8601).
3. **Watchdog gate**: stale_verdict event fires ONLY if `now > canonical_deadline AND no verdict_posted_in_window`.
4. **Older labels retained** (do NOT delete on supersede — preserves audit trail per ADR-0012 §Cascade-strip discipline).

### 2. Layered defense (2 paths, chosen BOTH)

**Path A: Workflow YAML hook** (`.github/workflows/label-check.yml`, owner-only territory per file ownership matrix)

- **Location**: existing Auto-Verdict-By hook step (ADR-0024-amendment-auto-verdict-by-hook §Path 1).
- **Behavior**: on `labeled` event with `verdict-by:<new-ts>` AND existing `verdict-by:<older-ts>`, the hook MUST:
  - (a) Compute canonical = max(new, older)
  - (b) Emit `verdict_supersede` log line: `supersede verdict_by: <older_ts> → <new_ts> canonical=<canonical>`
  - (c) NOT remove the older label (audit trail preservation)
- **Idempotency**: if hook fires multiple times on same label pair, behavior is identical (no-op).
- **Silent-skip guard** (per ADR-0045 lens (d)): if older label cannot be parsed (malformed timestamp), emit `silent_skip` event per amendment-auto-verdict-by-hook §4 contract.

**Path B: Agent-side `scripts/agent-watch.sh` predicate** (developer lane per file ownership matrix)

- **Location**: existing `query_stale_verdict` function (sister to ADR-0002-amendment-1 §1 filter scope).
- **Predicate addition**: stale_verdict event fires only if `MAX(verdict_by_timestamps) < NOW`. Add to existing filter clause:
  ```bash
  # Pseudo-code (sister to ADR-0002-amendment-1 §1)
  max_verdict_by=$(echo "$labels" | grep -E '^verdict-by:' | sed 's/^verdict-by://' | sort -r | head -1)
  if [[ -n "$max_verdict_by" ]] && [[ "$(date -u +%Y-%m-%dT%H:%M:%SZ)" < "$max_verdict_by" ]]; then
      skip_stale_verdict=1  # canonical deadline still in future
  fi
  ```
- **Workaround integration**: ORCH's manual-suppress override (per Issue #828 body) MUST also use the supersede rule — when ORCH adds a newer `verdict-by:<future-ts>`, the watchdog auto-recognizes it without script changes.

### 3. Cross-cutting guarantees

- **No breaking change** to existing `verdict-by:<single-ts>` PRs — predicate is a no-op when only 1 label present.
- **Audit trail preserved** — older labels retained per ADR-0012 §Cascade-strip discipline.
- **Bug #827 amplification mitigation** — once both Bug #827 fix AND this amendment land, the cluster squash wave (PRs #825/#826/#817/#799/#816) can proceed without flip-back interference + wake-loop noise.

---

## Alternatives considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **A. Supersede rule (this amendment)** — max-timestamp canonical | Backward-compatible; preserves audit trail; fixes root cause; clusters with Bug #827 fix naturally | Requires both workflow YAML change (owner gate) + agent-watch.sh predicate (dev lane); 2-touch implementation | **ADOPTED** |
| **B. Cascade-delete old label on new add** — auto-verdict-by hook removes older on new | Simplest implementation; 1-line change | Breaks audit trail (loses deadline history); conflicts with ADR-0012 §Cascade-strip discipline; violates "older label preserved" principle | REJECTED |
| **C. Per-label-id UUID + active flag** — `verdict-by:<ts>:<uuid>:active` | Strict canonical pointer | Schema change breaks all existing `verdict-by:<ts>` PRs; massive migration; violates ADR-0024 §Schema immutability | REJECTED |
| **D. ORCH manual-suppress only (workaround stays)** | Zero implementation cost | Permanent wake-loop noise on any PR with multi-verdict-by; ORCH must maintain suppress list; does not scale | REJECTED (workaround OK as interim per Issue #828 body, not as final fix) |
| **E. Cadence Rule 2 (defer to next sprint backlog)** | Frees WIP for higher-priority cluster blockers | Issue #828 P2 + Bug #827 P1 cluster interaction unaddressed; wake loop continues; doctrinal debt grows | REJECTED (cluster sequencing critical per c4.42 + c4.47) |

---

## Consequences

### Positive outcomes

1. **Cluster unblock** — Bug #827 + this amendment together clear the squash wave blocker (PRs #825/#826/#817/#799/#816 owner-squash sequence can proceed).
2. **Doctrinal closure** — ADR-0024 §Watchdog logic now has canonical-deadline semantics; future amendments can build on this contract.
3. **Workaround elimination** — ORCH manual-suppress override (Issue #828 body interim) becomes unnecessary once amendment lands.
4. **Sister-pattern family consolidation** — Issue #798 + Issue #828 + Bug #827 = 3-cluster Auto-Claim Integrity Stack; this amendment completes the doctrinal codification triad (umbrella ADR-0038-amendment-3 candidate already on @architect deferred list c4.22).
5. **Live-instance root cause fixed** — PR #816 3-wake-in-12min pathology eliminated (root cause = watchdog predicate lacked supersede rule).

### Negative tradeoffs

1. **2-lane implementation** — workflow YAML (owner-gate, slow) + agent-watch.sh (dev lane, faster) means 2-PR cycle. Acceptable per ADR-0055 §1 Cadence Rule 1 atomic (single PR contains all 4 artifacts: scripts/ fix + d-test + INDEX.md + ADR reference).
2. **Cluster sequencing dependency** — this amendment + Bug #827 fix MUST land before squash wave; otherwise wake-loop continues. Already on ORCH's radar per c4.42 dispatch + c4.47 ack.
3. **Workflow YAML human-only gate** — owner squash per file ownership matrix; cannot be rushed by agents. Acceptable per ADR-0031 owner-merge doctrine.

### Follow-up tickets to file

1. **Sister d-test** `scripts/tests/d-XXX-stale-verdict-supersede.sh` — ≥5 TCs RED-first per ADR-0049 + ADR-0044:
   - TC1 multi-label max-timestamp predicate (static grep + dynamic jq test)
   - TC2 single-label backward compatibility (no-op predicate)
   - TC3 malformed-timestamp silent-skip (lens (d) guard)
   - TC4 d320 sister non-regression (10/10 PASS)
   - TC5 INDEX.md row atomic (Cadence Rule 1)
2. **INDEX.md row** in `scripts/tests/INDEX.md` — Cadence Rule 1 atomic per ADR-0055 §1.
3. **Umbrella ADR-0038-amendment-3** — already on @architect deferred list (c4.22); this amendment + Bug #827 fix + #809 fix = 3 sibling races under one umbrella. File when all 3 impl PRs land.
4. **Documentation update** — `.claude/CLAUDE.md` §Auto-Ping Hard-Rule + §Autonomy Loop get 1-line reference to this amendment (owner-gated per file ownership matrix — proposed via PR).
5. **PR #816 wake-loop cleanup** — once amendment lands, manually remove the `verdict-by:2026-07-04T14:48:44Z` label that Bug #827 re-added (only the canonical `verdict-by:2026-07-08T15:00:00Z` should remain per §1 multi-label canonical).

---

## 9-Lens Pre-Publish Attestation (per architect.md §9-Lens Review Checklist, ADR-0045)

| Lens | Verdict | Note |
|---|---|---|
| (a) Data flow | ✅ GREEN | canonical-deadline resolution observable via `gh pr view --json labels`; no hidden state |
| (b) Runtime preconditions | ✅ GREEN | both paths (workflow YAML + agent-watch.sh) operate on existing label data; no new deps |
| (c) Canonical entry point | ✅ GREEN | supersede rule applies to ALL stale_verdict wakes; no side-channel |
| (d) Silent-skip risk | ✅ GREEN | malformed-timestamp explicit `silent_skip` emit (per amendment-auto-verdict-by-hook §4); lens (d) guard codified |
| (e) Idempotency | ✅ GREEN | Path A hook idempotent on multi-fire; Path B predicate deterministic; cluster sequencing safe |
| (f) Observability | ✅ GREEN | `verdict_supersede` log line per Path A; `silent_skip` per lens (d); d-test verifies both |
| (g) Security & privacy | ✅ GREEN | no PII; no secrets; labels are public per ADR-0012 4-cat invariant |
| (h) Workflow YAML SHA pin | ✅ GREEN | any new `actions/github-script@<ref>` MUST use full 40-char SHA per ADR-0027 §Threat model + ADR-0045 lens (h); existing label-check.yml already SHA-pinned (TD-028 sister-pattern) |
| (i) Platform hard constraints | ✅ GREEN | owner-gated workflow YAML change; concurrency + timeout + permissions all per ADR-0043 + ADR-0045 lens (i); no raw `docker run` / `ssh` outside `actions/*` |
| (j) Auto-generated file refs + live-state verification | ✅ GREEN | `grep .gitignore` + `Makefile` + `pyproject.toml` checked — `docs/decisions/ADR-0024-amendment-*.md` is HAND-WRITTEN (no template generation); `live-state` verified via `gh pr view 816 --json labels` showing the multi-verdict-by pathology in real-time |

**Net**: 10 GREEN, 0 RED, 0 needs-mitigation. Doctrinally + operationally ready.

---

## Cross-references

- [ADR-0024](./ADR-0024-stale-verdict-watchdog-schema.md) (parent — stale-verdict watchdog schema)
- [ADR-0024-amendment-auto-verdict-by-hook](./ADR-0024-amendment-auto-verdict-by-hook.md) (sister amendment — auto-pair on `cc:<peer>` add)
- [ADR-0002-amendment-1-stale-verdict-filter-scope](./ADR-0002-amendment-1-stale-verdict-filter-scope.md) (sister — verdict-authority discriminator, Issue #798 sister-pattern)
- [ADR-0069](./ADR-0069-form-c-race-detection.md) (sister — race-detection doctrinal codification pattern)
- [ADR-0055](./ADR-0055-cadence-rule-1-atomic.md) (Cadence Rule 1 atomic — dev impl PR must include 4 artifacts)
- [ADR-0052](./ADR-0052-ci-rerun-race-codification.md) (sister — §30s re-query window for CI propagation)
- [ADR-0044](./ADR-0044-red-first-tdd.md) (RED-first TDD — d-test contract structure)
- [ADR-0049](./ADR-0049-d-test-framework.md) (d-test framework — ≥5 TCs baseline)
- [ADR-0045](./ADR-0045-9-lens-pre-publish.md) (9-Lens pre-publish gate — this attestation)
- [ADR-0031](./ADR-0031-owner-merge-gate.md) (owner squash gate for workflow YAML)
- [ADR-0038](./ADR-0038-auto-claim-protocol.md) (parent of amendment #2 Form C + amendment #3 umbrella candidate)
- [ADR-0027](./ADR-0027-threat-model.md) (threat model — workflow YAML SHA-pin per lens (h))
- [ADR-0043](./ADR-0043-platform-hard-constraints.md) (lens (i) 8 sub-categories)
- Issue #828 (this amendment's home — stale_verdict hook false-positive)
- Issue #798 (Layer 5 j.4 — verdict-authority false-positive, sister class)
- Bug #827 (sister cluster blocker — scripts/status-action-driver.sh PR exclusion)
- PR #816 (live instance — 3 stale_verdict wakes c4.41/c4.44/c4.46)
- PR #799 (sister-pattern fix for Issue #798)
- c4.22 (architect deferred umbrella ADR-0038-amendment-3 carrier note)
- c4.42 (architect Bug #827 dispatch response)
- c4.47 (architect Issue #828 lane clarification)

🤖 Generated with [Claude Code](https://claude.com/claude-code)