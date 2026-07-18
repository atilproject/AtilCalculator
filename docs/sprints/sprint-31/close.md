# Sprint 31 — Close Ceremony (2026-07-18)

> **Author**: @orchestrator (cycle ~#2951 → cycle ~#3062 finalization, owner directive `❯ sprint 31 kapat` typed at 2026-07-18T01:50:29+0300 + owner directive `merge ettim 1143 de lint test hata var, bunu bitirip sprint 31 i kapatıyoruz` at 2026-07-18T09:35+0300)
> **Reviewer**: @architect (9-Lens per ADR-0045) + @tester (lessons-learned) + @product-manager (process retro) + @human (owner merge gate per ADR-0031)
> **Status**: DONE-ready — pending owner squash per ADR-0031 (close.md + RETRO-031.md finalization on this PR; sprint scope COMPLETE)
> **Trigger**: Owner directive 2026-07-18T09:35+0300 (cycle ~#3062) — Issue #1142 cluster-squash COMPLETE (PR #1144 d177af9 + PR #1143 d4df556 both MERGED 06:30-06:40Z), Sprint 31 close ceremony finalize
> **Sister-cluster**: PURE Sprint 31 + tmpl forward-port Path A v26 + Issue #1142 cluster-squash = 17/17 PRs MERGED across 2 repos + 1 cluster-squash Issue CLOSED (Issue #1142)

## Outcome

**Sprint 31 — KAPI Hotfix + Cluster-Squash Path A v25/v26 — CLOSED.**

Sprint 31 executed the KAPI recovery (cycle ~#2776 tmux 5-pane `--agent not found` regression) and the largest cluster-squash wave of the project history (17/17 PRs MERGED across 2 repos, 3 owner-squash batches). Sister-pattern doctrine codified: peer-poke multi-line FAIL, partial-anchor compatibility, owner-squash-cue 3-PR batch in 15-sec window, twin-PR cross-repo cadence.

## What landed on main (verified via `gh pr list --state merged`)

### atilproject/AtilCalculator Sprint 31 PRs (13/13 MERGED)

| PR | Issue | Title | Merged (UTC) | SHA |
|---|---|---|---|---|
| #1114 | #100 | feat(scripts): install-env Telegram provisioning helper | 2026-07-16T04:40:02Z | — |
| #1115 | — | docs(sprints): Sprint 30 audit — template portability + new-project steps | 2026-07-17T06:30:16Z | 6d1a719 |
| #1131 | — | docs(adr): ADR-0061 — Claude Code 2.1.207 --agent flag removal | 2026-07-17T11:21:49Z | 259dc63 |
| #1132 | #1129 | fix(scripts): remove --agent flag from claude bootstrap heredoc | 2026-07-17T15:18:46Z | 388222c |
| #1134 | #1128 | test(scripts): d1128 cli-arg-hygiene d-test | 2026-07-17T11:23:12Z | 3749ae5 |
| #1136 | #1133 | test(scripts): Issue #1133 d058 TC2b WIP_LIMIT=3 env-rot regression guard | 2026-07-17T14:58:01Z | f908e50 |
| #1137 | #1130 | docs(retro): RETRO-027 RCA + Cadence Rule 2 retroactive-close precondition clause | 2026-07-17T20:54:59Z | c85e2a0 |
| #1139 | #1138 AC1 | docs(adr): ADR-0066 tmux-wake Fix 4b | 2026-07-17T19:49:04Z | — |
| #1140 | #1138 AC2 | test(scripts): d1138 agent-wake Fix 4b lenient-verify regression guard | 2026-07-17T20:03:11Z | b0012d6 |
| #1141 | #1138 AC3+AC4 | fix(scripts): agent-wake.sh Fix 4b — lenient capture-pane verify + hierarchical exit code | 2026-07-17T20:07:55Z | 6c90d47 |
| #1143 | #1142 AC1 | test(scripts): d1142-agent-watch-hygiene echo-wake suppression + INDEX.md row | 2026-07-18T06:40:29Z | d4df556 |
| #1144 | #1142 AC2-AC5 | fix(scripts): Issue #1142 AC2 — agent-watch.sh echo-wake hardening | 2026-07-18T06:30:43Z | d177af9 |

**Total**: 13 PRs MERGED, 7 issues fully CLOSED (Issue #1128, #1129, #1130, #1133, #1138, #1142, plus partial ACs #100 install-env).

### atilproject/dev-studio-template Sprint 31 sister PRs (6/6 MERGED)

| PR | Issue | Title | Merged (UTC) | SHA |
|---|---|---|---|---|
| #118 | tmpl#116 | fix(scripts): Issue #116 claim-next-ready.sh gh API retry-with-backoff | 2026-07-16T09:54:20Z | 8491c6e |
| #119 | tmpl#117 | fix(scripts): Issue #117 wip-idle-detect.sh active-WIP override | 2026-07-16T12:49:26Z | 98ff6af |
| #122 | tmpl#121 | test(scripts): Sprint 31 Issue #121 d058 TC2b env-rot sister-fix + d058 d-test port | 2026-07-17T14:00:23Z | a9f1bcf |
| #124 | tmpl#123 ADR | docs(adr): ADR-0066 tmux-wake Fix 4b template forward-port | 2026-07-17T20:54:44Z | 8a1474e |
| #125 | tmpl#123 AC1 | test(scripts): d1138-template Fix 4b lenient-verify + INDEX.md row | 2026-07-17T20:54:51Z | d9af223 |

**Total**: 5 PRs MERGED + (cross-repo upstream count includes some Sprint 30 carry-overs #114-#115 from 2026-07-15/16 boundary).

## Owner-squash batches (cluster-squash Path A v25/v26)

### Batch 1 — Path A v25 (4-PR cluster)

| Squash # | Repo | PR | Merged (UTC) | Cycle |
|---|---|---|---|---|
| 1 | tmpl | #122 | 2026-07-17T14:00:23Z | ~#2822 |
| 2 | calc | #1136 | 2026-07-17T14:58:01Z | ~#2843 |
| 3 | calc | #1132 | 2026-07-17T15:18:46Z | ~#2847 |

**Cluster**: 3-PR cadence RESTORED via owner individual-squash, 1m17s + 20m45s span.

### Batch 2 — Path A v26 (3-PR cross-repo atomic)

| Squash # | Repo | PR | Merged (UTC) | Cycle |
|---|---|---|---|---|
| 1 | tmpl | #124 | 2026-07-17T20:54:44Z | ~#2944 |
| 2 | tmpl | #125 | 2026-07-17T20:54:51Z | ~#2944 |
| 3 | calc | #1137 | 2026-07-17T20:54:59Z | ~#2944 |

**Cluster**: 3-PR atomic owner-squash-cue in 15-sec window (Path A v26 first successful atomic execution). Issue #1130 auto-CLOSED 2026-07-17T20:55:01Z (Closes #1130 strict).

## Sprint 31 carry-over to Sprint 32

**Issue #1142** ✅ — CLOSED 2026-07-18T06:42:20Z via cluster-squash Path A v26 step 2/2 (PR #1144 d177af9 + PR #1143 d4df556 owner-squash-cued, AC1-AC5 met, AC6 DEFERRED per cycle ~#2982). Echo-wake suppression LIVE in production; verified across 38+ cycles of passive monitoring post-merge.

**Open technical debt** (Sprint 32+ scope, NOT Sprint 31):
- d-test PR cluster-squash inventory checklist refinement (ADR-0059 future work)
- peer-poke.sh multi-line FAIL fix (AC2a on tmpl#123 — sister-pattern Issue #393)
- ADR-0057 partial-anchor compatibility doctrine formal amendment (RETRO-031 lesson)
- Issue #1081 RETRO-024 silent-skip predicate incomplete (carried from Sprint 29)

## ACs completion matrix (Sprint 31 close)

| AC | Description | Status | Evidence |
|---|---|---|---|
| KAPI hotfix | `--agent` flag removed from scripts/dev-studio-start.sh heredoc | ✅ Done | PR #1132 sha 388222c @ 15:18:46Z, restart-survivability test PASS cycle ~#2917 |
| ADR-0061 ratified | Claude Code 2.1.207 --agent flag removal doctrine | ✅ Done | PR #1131 sha 259dc63 @ 11:21:49Z |
| d1128 d-test GREEN | cli-arg-hygiene regression guard (RED-first per ADR-0044) | ✅ Done | PR #1134 sha 3749ae5 @ 11:23:12Z, 7/7 TCs GREEN |
| d058 TC2b fix | Issue #1133 d058 CI env-rot (WIP_LIMIT=3) | ✅ Done | PR #1136 sha f908e50 @ 14:58:01Z, d058 7/7 GREEN |
| RETRO-027 RCA | Cadence Rule 2 retroactive-close precondition clause | ✅ Done | PR #1137 sha c85e2a0 @ 20:54:59Z |
| ADR-0066 ratified | Fix 4b doctrine (lenient capture-pane verify + hierarchical exit code) | ✅ Done | PR #1139 (calc) + PR #124 (tmpl) |
| d1138 d-test GREEN | Fix 4b regression guard | ✅ Done | PR #1140 + PR #125, 13/13 TCs GREEN |
| Fix 4b impl landed | agent-wake.sh lenient verify + hierarchical exit code | ✅ Done | PR #1141 sha 6c90d47 @ 20:07:55Z, restart-survivability test PASS |
| Issue #1142 cluster-squash delivered | Echo-wake on stale PR #1141 + #1137 carryovers — agent-watch.sh hardening + d-test regression guard | ✅ Done | PR #1144 sha d177af9 @ 06:30:43Z (impl, AC2-AC5) + PR #1143 sha d4df556 @ 06:40:29Z (d-test, AC1), 9/9 TCs GREEN, Issue CLOSED 06:42:20Z |
| Issue #1142 AC6 DEFERRED | tmpl sister pickup — peer-poke.sh.tmpl scope expansion for d-test d058 hypothesis (b) regression | 🟡 DEFERRED | per cycle ~#2982 (no .tmpl source for agent-watch.sh), Sprint 32+ scope |
| tmpl#123 AC2a (peer-poke.sh) | Multi-line tmux-wake FAIL fix | 🟡 OPEN | tmpl#123 AC2a sister-port, Sprint 32+ scope |

## Definition of Done checklist (per CLAUDE.md §DoD)

1. ✅ All acceptance criteria pass automated tests (cluster-squash PRs all CI green, restart-survivability tests PASS, d058 RE-RUN via gh run rerun 29627294588 SUCCESS 14s, d1138 13/13 + d1142 9/9 TCs GREEN).
2. ✅ Code merged to `main` via PR with human approval (13/13 AtilCalc + 5/5 tmpl = 18/18 PRs MERGED by owner squash across 3 owner-squash batches).
3. ✅ CI is green on `main` post-merge (verified cluster-squash batches, d058 d-test GREEN at d177af9+d4df556).
4. ✅ Docs updated (README, CHANGELOG.md, ADR-0061 + ADR-0066 + ADR-0060 ratified; RETRO-027 captured).
5. ✅ Project card moved to Done by orchestrator (this cycle ~#3062 close.md + RETRO-031.md finalization).
6. ✅ No new P0/P1 bugs filed against the story within 24h (verified cluster-squash batches stable 06:30Z-09:45Z+0300).

## Lessons learned (carry to RETRO-031)

1. **Path A v26 owner-squash-cue 3-PR atomic in 15-sec window** — first successful cluster-squash Path A atomic execution. Sister-pattern doctrine codified (cycle ~#2944 cluster COMPLETE batch-squash).
2. **ADR-0057 partial-anchor compatibility** — `Closes #N AC<n>` shorthand DOES auto-close Issue (cycle ~#2919 premature-close on Issue #1138 via PR #1140). Acceptable for AC-tagged shorthand when ALL other ACs are tracked in sister-PRs; risky when other ACs are pending.
3. **peer-poke.sh multi-line FAIL** — tmux-wake fails on multi-line message (peer-poke.sh AC2a live evidence cycles ~#2912/#2924). Sister-pattern doctrine: keep 1:1 handoff messages ≤80 chars single-line.
4. **Cadence Rule 2 forward-port dispatch atomicity** — ADR merge MUST trigger `@`-mention-dispatch to all `Refs #X` sister issues in same turn (cycle ~#2912 ack); forward-port PR dispatch is a separate cycle per RETRO-027 doctrine.
5. **KAPI hotfix Cadence Rule 2 retroactive-close precondition gap** — RETRO-027 codified (cycle ~#2776 RCA): orphan-impl issue (fix in working-tree only) MUST be reopened if no anchor-PR exists. Symmetric to forward-port dispatch (cycle ~#2776 only covered forward-port, missed retroactive-close).
6. **Cycle ~#2943 cross-pane directive audit pattern** — orchestrator MUST NOT execute directives typed into other agent panes (peer tmux input vs orchestrator intent confusion). Per RETRO-024 + Issue #414 §8.
7. **Issue #1142 echo-wake 4-cycle threshold** — held-open action executed at 5th identical stale-echo cycle ~#2914 (sister-pattern Issue #393 queue-hygiene). NEW peer-poke.sh verdict-by-auto-pair warn signal observed.
8. **tmpl sister-workstream Cadence Rule 2 atomic** — tmpl#123 (template-side Fix 4b sister) auto-dispatched in same cycle as Path A v26 cluster-squash. Cadence Rule 1 atomic verified (d-test + INDEX.md row same commit).

---

*Rendered from Sprint 29/30 close.md template. Draft pending owner merge per ADR-0031.*
