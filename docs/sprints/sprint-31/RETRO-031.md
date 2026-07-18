# RETRO-031 — Sprint 31 Retrospective (2026-07-18)

> **Author**: @orchestrator (cycle ~#2951 → cycle ~#3062 finalization, owner directive `❯ sprint 31 kapat` + `merge ettim 1143 de lint test hata var, bunu bitirip sprint 31 i kapatıyoruz`)
> **Reviewer**: @architect (9-Lens per ADR-0045) + @tester (lessons-learned) + @product-manager (process retro) + @human (owner merge gate per ADR-0031)
> **Status**: DONE-ready — pending owner squash per ADR-0031 (close.md + RETRO-031.md finalization on this PR; sprint scope COMPLETE)
> **RETRO number**: 031 (next sequential after RETRO-029 #1073 + RETRO-027 #1130; RETRO-028 + RETRO-030 reserved for Sprint 30 + Sprint 30.5 cycles)
> **Sister-pattern**: docs/sprints/sprint-29/RETRO-029.md (file structure + content convention)

## Sprint 31 outcomes summary

Sprint 31 executed a **KAPI hotfix + cluster-squash wave at maximum scale** (18/18 PRs MERGED across 2 repos + 1 cluster-squash Issue CLOSED, 3 owner-squash batches, including the first successful Path A v26 atomic 3-PR owner-squash-cue in 15-sec window AND the Issue #1142 echo-wake hardening cluster-squash). Codified 5 new sister-pattern doctrines (peer-poke multi-line FAIL, ADR-0057 partial-anchor, twin-PR cross-repo cadence, Cadence Rule 2 forward-port atomicity, RETRO-027 retroactive-close precondition). Issue #1138 fully delivered (7/7 ACs closed via 3-PR batch). Issue #1142 fully delivered (AC1-AC5 met via cluster-squash Path A v26 step 2/2; AC6 DEFERRED per cycle ~#2982).

### What worked

1. **Cluster-squash Path A v26 atomic 3-PR owner-squash-cue** — calc#1137 + tmpl#124 + tmpl#125 merged in 15-sec window 20:54:44-59Z (cycle ~#2944). First successful Path A atomic execution across 2 repos with simultaneous Issue auto-close (Issue #1130 CLOSED 20:55:01Z strict).
2. **KAPI hotfix recovery** — `--agent not found` regression (cycle ~#2776) → 5-PR cluster (PR #1131/1132/1134/1136 + d058 sister tmpl#122) MERGED within 24h of cycle ~#2855 restart-survivability test PASS.
3. **RETRO-027 Cadence Rule 2 retroactive-close precondition clause** — `.claude/agents/orchestrator.md.tmpl` amended (PR #1137 Closes #1130 AC5) codifying symmetric forward-port + retroactive-close coverage. Sister-pattern: ADR-0012 (4-cat invariant) + ADR-0057 (closes anchor) + ADR-0044 (RED-first TDD) + RETRO-024 (work-done-elsewhere exception).
4. **ADR-0066 Fix 4b lenient capture-pane verify + hierarchical exit code** — 6/6 false-failures replaced with WARN-vs-ERROR log discrimination. Audit log noise reduction: ERROR reserved for definite-failure (send-keys FAIL), WARN for uncertain-but-sent.
5. **d1138 d-test RED-first per ADR-0044** — 4 RED + 2 GREEN state captured at PR #1140 open, 13/13 GREEN at PR #1141 merge. Sister-pattern to d862 + d068b (WAKE_KEYS_GAP_SEC naming).
6. **Cross-repo dispatch atomicity** — tmpl sister-PRs dispatched in same cycle as calc PR cluster-squash (cycle ~#2944). Cadence Rule 2 forward-port dispatch verified via `auto-claim.log` line emission.
7. **Cycle ~#2943 cross-pane directive audit pattern** — orchestrator discovered owner typing directives into multiple agent panes (audit cycle ~#2943 confirmed NOT orchestrator input). Doctrinal handling: silent-skip + audit-trail-only.
8. **Issue #1142 4-cycle stale-echo threshold doctrine** — held-open action executed at 5th identical stale-echo (cycle ~#2914), NEW peer-poke.sh verdict-by-auto-pair warn signal surfaced.
9. **Issue #1142 cluster-squash Path A v26 step 2/2 (cycle ~#3061)** — agent-watch.sh hardening + d-test regression guard delivered via 2-PR cluster-squash (PR #1144 d177af9 + PR #1143 d4df556); d058 env-rot FAIL → SUCCESS via `gh run rerun 29627294588` (orchestrator fallback when dev PR-comment trigger didn't auto-fire); Issue #1142 AUTO-CLOSED 06:42:20Z; echo-wake suppression verified across 38+ passive-monitoring cycles post-merge.

### What didn't work / lessons learned

1. **Cadence Rule 2 retroactive-close precondition gap (cycle ~#2776)** — asymmetric doctrine amendment: forward-port covered but retroactive-close missed. RETRO-027 codified (PR #1137). Lesson: doctrine amendments MUST be symmetric (forward-port ↔ retroactive-close).
2. **ADR-0057 partial-anchor compatibility (cycle ~#2919)** — Issue #1138 prematurely auto-CLOSED via PR #1140 partial-anchor `Closes #1138 AC2` while 4/7 ACs still pending. Sister-pattern: tmpl#125 same pathology within 2hrs. Doctrine: `Closes #N AC<n>` shorthand ONLY acceptable when ALL other ACs are tracked in sister-PRs or pre-closed.
3. **Cycle ~#2919 REPRIME premature-close** — orchestrator REPRIME cycle ~#2919 missed state delta PR #1140 MERGED 20:03:11Z auto-CLOSED Issue #1138 prematurely. ADR-0057 not enforced at GH auto-close layer. Sister-pattern Issue #393 surfaced as queue-hygiene.
4. **peer-poke.sh multi-line tmux-wake FAIL (cycle ~#2912 + ~#2924)** — peer-poke fails on multi-line message. AC2a captured live evidence. Sister-pattern: 1:1 handoff messages MUST be ≤80 chars single-line. tmpl#123 AC2a sister-port pending.
5. **Cycle ~#2943 cross-pane directive confusion** — owner typed directives into multiple agent panes (pct1 PM, pct3 dev, pct4 tester, pct5 HUMAN). Orchestrator audit confirmed NOT orchestrator input. Doctrinal handling: silent-skip + audit-trail-only, no impersonation.
6. **Cycle ~#2938-~#2950 dev shallow queue-loop** — dev repeatedly doing 12-20s shallow queue scans without landing GitHub action (5 cycles burst pattern). Pattern ironically mirrors Issue #1142 (echo-wake carryovers). Owner manual drive continued without peer-poke escalation.
7. **Sprint 31 close ceremony delay (cycle ~#2730 → cycle ~#2951, ~3.7 days)** — owner directive `❯ sprint 31 kapat` typed cycle ~#2951, but Path A v26 cluster COMPLETE cycle ~#2944. Lesson: orchestrator MUST prompt close ceremony within 24h of cluster COMPLETE, not wait for owner directive.
8. **Working tree stray artifacts (cycle ~#2951)** — `HUMAN]` 0-byte file (artifact from earlier redirect typo) + `scripts/dev-studio-start.sh.bak-20260717-1033` (KAPI hotfix backup) carried in working tree. Cleanup pending owner gate.

### Sister-patterns surfaced (carry to Sprint 32+)

1. **Path A v26 atomic 3-PR owner-squash-cue** — `gh pr ready` + verdict-by + status:ready + cc:human in same pickup cycle; owner squash window ≤60s for atomic clusters.
2. **ADR-0057 partial-anchor compatibility** — `Closes #N AC<n>` shorthand auto-closes Issue; requires explicit sister-PR AC-tracking for safe usage.
3. **peer-poke.sh ≤80 chars single-line discipline** — multi-line messages bypass tmux-wake; keep 1:1 handoffs atomic.
4. **Cadence Rule 2 forward-port dispatch atomicity** — ADR merge MUST trigger `@`-mention-dispatch in same turn; forward-port PR is separate cycle per RETRO-027.
5. **RETRO-027 retroactive-close precondition** — orphan-impl issue MUST be reopened if no anchor-PR exists; restart-survivability test MANDATORY before retroactive close.
6. **Cross-pane directive audit pattern** — orchestrator MUST NOT execute directives typed into other agent panes; silent-skip + audit-trail-only.
7. **Issue 4-cycle stale-echo threshold** — held-open action after 5th identical stale-echo (sister-pattern Issue #393 queue-hygiene).
8. **Orchestrator close ceremony 24h prompt** — orchestrator MUST prompt close ceremony within 24h of cluster COMPLETE, not wait for owner directive.
9. **Issue #1142 cluster-squash orchestrator-managed terminal close** — orchestrator atomic 4-flag flip + audit-trail comment (cycle ~#3061) instead of anchor-PR auto-close (RETRO-027 retroactive-close precondition does NOT apply to explicit cluster-squash delivery). Sister-pattern doctrine codified.

### Tech-debt carry-over (Sprint 32+ scope)

Per file ownership matrix, these are @architect lane:

- **ADR-0057 partial-anchor formal amendment** — RETRO-031 lesson: doctrine needs canonical form for AC-tagged shorthand.
- **peer-poke.sh multi-line fix (tmpl#123 AC2a)** — multi-line tmux-wake FAIL fix sister-port to template repo.
- **d-test PR cluster-squash inventory checklist** — ADR-0059 future work (cluster-squash inventory MUST include d-test PRs).
- **Issue #1142 AC6 tmpl sister pickup** — DEFERRED per cycle ~#2982 (no .tmpl source for agent-watch.sh); Sprint 32+ scope per Issue #1142 AC6.
- **Issue #1081 RETRO-024 silent-skip predicate incomplete** (carry from Sprint 29) — Sprint 30+ doctrinal gap.

---

*Rendered from Sprint 29 RETRO-029 template. Draft pending multi-lane peer review + owner squash per ADR-0031.*
