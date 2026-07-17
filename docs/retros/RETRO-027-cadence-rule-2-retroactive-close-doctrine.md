# RETRO-027 — Cadence Rule 2 retroactive-close doctrine misapplication (cycle ~#2776 RCA)

> **Author:** @orchestrator (orchestrator lane, owner ratifies per ADR-0031)
> **Date:** 2026-07-17T15:35+03:00 = 12:35Z (post-Issue #1130 RCA, post-cluster-squash sub-cluster #2 wave v19 COMPLETE)
> **Scope:** Meta-postmortem for Cadence Rule 2 retroactive-close misapplication at cycle ~#2776; codifies the **Retroactive-Close Precondition** clause as the symmetric case to the original forward-port dispatch rule
> **Lane:** `docs/retros/RETRO-027-*.md` (orchestrator-owned retrospective lane per file ownership matrix — `.claude/agents/**` amendments close via the same PR per Cadence Rule 1 atomic, ADR-0055 §1)
> **Sister-pattern:** RETRO-024 (work-done-elsewhere 4-cat exception, exception-not-rule) + RETRO-022 (original 4-cat gap, Issue #1023) + RETRO-023 (cross-repo codification, Issue #1024)
> **Closes:** Issue #1130 (priority:P1, type:docs, agent:orchestrator, template-gap-close cluster)

## TL;DR

At cycle ~#2776 (2026-07-17 ~08:34Z), the Cadence Rule 2 SOUL AMEND was applied to the orchestrator's local soul file covering the **forward-port dispatch** case (ADR merge → sister issue @-mention same turn). The **symmetric case** — closing orphan-impl issues retroactively without a PR — was NOT preconditioned.

At cycle ~#~12:56 UTC, the gap surfaced: AtilCalculator Issue #1128 + #1129 were retroactively closed (cycle ~#2776 KAPI HOTFIX closure batch) without a PR. The fix lived ONLY in the local working tree (`scripts/dev-studio-start.sh:149` single-token `--agent` removal). At ~10:32 UTC, a tmux restart of all 5 panes FAILED with `--agent not found` Claude Code CLI error — the bug was live on main.

Recovery chain:
1. Owner directive cycle ~#~12:56 UTC: reopen Issues #1128 + #1129, re-sequence architect → tester → developer.
2. Architect opened ADR-0061 docs PR (`Closes #1128`, `Refs #1129`, Refs template ADR-0060 + sister PRs #97/#108/#110).
3. Tester landed PR #1134 d1128 d-test GREEN 7/7 (byte-equal to impl).
4. Developer landed PR #1132 impl (`Closes #1129`, `Refs #1128`) post-rebase onto PR #1136 d058 fix.
5. Owner-squashed PR #1131 + #1134 cluster-squash sub-cluster #2 wave v19.
6. Owner-squashed PR #1132 at 15:18:46Z (sha 388222c, cluster-squash Path A 4/5 DONE + 1/5 DEFERRED).
7. **This PR** (RETRO-027 RCA + Cadence Rule 2 retroactive-close precondition clause in `.claude/agents/orchestrator.md.tmpl` + this retro file) closes Issue #1130.

## §1 — What happened (cycle ~#2776 sequence)

### §1.1 — Discovery (08:34Z)

Owner directive @ 2026-07-17T08:34Z: "all 5 tmux panes broken on tmux restart — `--agent not found`". Root cause: Claude Code CLI 2.1.207 deprecated the `--agent` flag (renamed to `--append-system-prompt-file`); `scripts/dev-studio-start.sh:149` was the offending line:

```bash
claude --dangerously-skip-permissions --agent "${role}" ...    # bug
claude --dangerously-skip-permissions --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "$KICKOFF_PROMPT"  # fix
```

### §1.2 — Forward-port lane (08:51Z)

Template repo (`atilproject/dev-studio-template`) had landed the fix via 3 PRs:
- PR #97 (ADR-0060 — Claude Code 2.1.207 breaking change home, MERGED 2026-07-14T19:55:03Z)
- PR #108 (d-test for cli-arg-hygiene, MERGED 2026-07-14)
- PR #110 (impl `--agent` removal, MERGED 2026-07-15)

AtilCalculator sister work never opened. **Cadence Rule 2 amendment was triggered**: when ANY `docs/decisions/ADR-NNNN-*.md` PR merges to `main`, the SAME TURN must `@`-mention-dispatch each listed sister issue to its `agent:*` owner. **The rule covered FORWARD-PORT** — what to do when an ADR lands but sister work hasn't started. **It did NOT cover RETROACTIVE-CLOSE** — what to do when an orphan-impl issue is closed without a PR.

### §1.3 — Misapplied closure (09:48Z)

AtilCalculator Issues #1128 (KAPI d-test) + #1129 (KAPI impl) opened at 08:51Z. Same turn opened `docs/decisions/ADR-0061-claude-code-agent-flag-removal.md` as uncommitted architect draft (165 lines). At 09:48Z, both issues closed with rationale "Cadence Rule 2 retroactive closure (cycle ~#2776)". **NO PR was opened. The fix lived ONLY in the local working tree.**

The closure comment asserted the fix was "PR-persisted" but did NOT verify `origin/main:scripts/dev-studio-start.sh` byte-by-byte. It also asserted Closes-anchor compliance but did NOT cite any PR.

### §1.4 — Queue-reset cascade (09:57Z)

Owner directive "3 repodaki açık issue ve prları sil" force-closed all 3-repo queues. The closure was rolled into queue-reset comments but the retroactive preconditions were not actually met. The orphaned Issues #1128 + #1129 went CLOSED → stateReason=COMPLETED despite zero PR-persistence evidence.

### §1.5 — Restart failure (10:32Z)

Tmux restart of all 5 panes FAILED with `--agent not found`. The "fix" was local-only, not PR-persisted, not on `origin/main`. The CLI 2.1.207 deprecation was live on AtilCalculator's `scripts/dev-studio-start.sh:149` despite the closure comment claiming resolution.

## §2 — Root cause

The "retroactive close" doctrine (cycle ~#2776) was applied WITHOUT verifying its own preconditions:

1. **PR-persistence test failure**: `git show origin/main:scripts/dev-studio-start.sh` returned the buggy line 149 (--agent still present). Bug was live on main. The closure comment claimed "PR-persisted" without checking `origin/main`.
2. **Closes anchor absence**: No PR was opened against either issue. ADR-0057 Closes anchor format was not present in any commit/PR.
3. **Cadence Rule 2 amendment was incomplete**: The amendment added in cycle ~#2776 did NOT contain the retroactive-close precondition clause. It only covered the forward-port dispatch (ADR merge → sister issue @-mention same turn). It missed the symmetric case: already-implemented orphan closing without a PR.

### §2.1 — Why the gap existed

The original amendment was triggered by the forward-port cadence gap (template merged, AtilCalculator sister work never opened). The orchestrator authored the amendment in haste to close the immediate gap (owner manual fix applied 3 times to `scripts/dev-studio-start.sh:149`). The symmetric retroactive-close case was not enumerated because no orphan-impl closure had been attempted yet — the failure mode wasn't yet observed.

**Pattern**: Doctrine authored under time pressure often covers the immediate trigger but misses symmetric cases. Sister-pattern to RETRO-009 §3 (work-stream-count drift) — doctrine gap surfaced only after the bug-class re-manifested.

## §3 — Why this clause (the asymmetric fix)

The **Cadence Rule 2 retroactive-close precondition** clause codifies the symmetric case:

> An orphan-impl issue (issue for which the fix already exists in working-tree but no PR has been opened) can be retroactively closed **ONLY IF** BOTH preconditions are verified:
>
> 1. **(a) PR-persistence**: the fix is PR-persisted in `origin/main` (NOT just local working-tree). Verification: `git fetch origin main && git show origin/main:<file>` MUST contain the fix.
> 2. **(b) Closes anchor**: that PR body contains an ADR-0057 strict `Closes #<N>` anchor referencing the issue.
>
> **Retroactive close WITHOUT an anchor-PR is INVALID**; the issue MUST be reopened.
>
> **Restart-survivability test** (mandatory before retroactive close):
>
> ```bash
> git fetch origin main
> git show origin/main:<file> | grep -F '<expected fix line>'
> ```
>
> If the grep returns 0 lines → the fix is NOT in main → retroactive close forbidden → reopen + dispatch architect/tester/developer chain.

This clause is added to `.claude/agents/orchestrator.md.tmpl` (TRACKED source-of-truth — `.claude/agents/orchestrator.md` is gitignored per `.gitignore:88`, regenerated by `scripts/dev-studio-init.sh` from the `.tmpl`). The clause renders on every init re-render, so the doctrine persists across clean clones.

## §4 — Recovery chain (post-cycle ~#~12:56 UTC)

1. **Owner directive**: reopen orphan-impl issue + tag `agent:architect status:in-progress` on sister-implementer issue
2. **Architect** opens ADR-0061 docs PR (`Refs` template ADR-0060 + sister template PRs #97/#108/#110) — `Closes #1128`
3. **Architect** wakes tester with d-test spec (`Closes #N` for d-test issue)
4. **Tester** lands d-test GREEN (PR #1134, d1128 d-test, RED 5/7 → GREEN 7/7 byte-equal to PR #1132 impl)
5. **Orchestrator** wakes developer with impl spec (`Closes #N` for impl issue, `Refs #<d-test-issue>`) — Issue #1129
6. **Cluster-squash** 3-PR per ADR-0059 (ADR + d-test + impl) in same 60s owner-squash window
7. **This PR** (Cadence Rule 2 amendment docs PR, `.claude/agents/orchestrator.md.tmpl` + this RETRO-027 file) `Closes #1130`

The cluster-squash sub-cluster #2 wave v19 = 3/3 DONE (tmpl#122 + calc#1136 + calc#1132). Cadence: PR #1136 merge 14:58:01Z → PR #1132 squash 15:18:46Z = ~21min.

## §5 — Live evidence section

### §5.1 — Cluster cadence (timestamps)

| Time (UTC) | Event | Cycle | Source |
|---|---|---|---|
| 2026-07-14T19:55:03Z | Template ADR-0060 merged (Claude Code 2.1.207 deprecation home) | — | PR #97 squash @ (template) |
| 2026-07-14 | Template PR #108 (d-test) merged | — | PR #108 (template) |
| 2026-07-15 | Template PR #110 (impl) merged | — | PR #110 (template) |
| 2026-07-17T08:34Z | Owner directive: KAPI HOTFIX discovery (--agent not found on tmux restart) | ~#2776 | this cycle |
| 2026-07-17T08:51Z | Issues #1128 + #1129 opened under KAPI discovery; ADR-0061 uncommitted draft | ~#2776 | this cycle |
| 2026-07-17T09:48Z | Issues #1128 + #1129 closed retroactively without PR (MISAPPLIED Cadence Rule 2) | ~#2776 | this cycle |
| 2026-07-17T09:57Z | Owner directive: 3-repo queue-reset | ~#2787 | this cycle |
| 2026-07-17T10:32Z | Tmux restart of all 5 panes FAILED --agent not found | ~#2787 | this cycle |
| 2026-07-17T~12:56Z | Owner directive: reopen + re-sequence + retroactive-close precondition | ~#~12:56 | this cycle |
| 2026-07-17T11:21:49Z | ADR-0061 PR #1131 MERGED (sha a9f1bcf or similar, squash) | ~#2822 | PR #1131 |
| 2026-07-17T14:00:23Z | tmpl#122 sister-PR forward-port MERGED (sha a9f1bcf) | ~#2822 | PR #122 |
| 2026-07-17T14:58:01Z | calc#1136 d058 fix MERGED (sha f908e50) — Issue #1133 auto-CLOSED | ~#2843 | PR #1136 |
| 2026-07-17T15:18:46Z | calc#1132 --agent fix MERGED (sha 388222c) — Issue #1129 idempotent on already-CLOSED | ~#2855 | PR #1132 |
| 2026-07-17T~15:35Z | **This PR (RETRO-027 + Cadence Rule 2 .tmpl amendment) — Closes #1130** | ~#2857 | this PR |

### §5.2 — Restart-survivability test (post-recovery, this turn)

```bash
$ git fetch origin main
From https://github.com/atilproject/AtilCalculator
 * branch            main       -> FETCH_HEAD

$ git show origin/main:scripts/dev-studio-start.sh | sed -n '148,150p'
claude --dangerously-skip-permissions --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "\$KICKOFF_PROMPT"

$ curl -sf https://raw.githubusercontent.com/atilproject/dev-studio-template/main/scripts/dev-studio-start.sh | sed -n '148,150p'
claude --dangerously-skip-permissions --append-system-prompt-file "$REPO_ROOT/.claude/agents/${role}.md" "\$KICKOFF_PROMPT"
```

✅ **PASS** — atilcalc origin/main and template main byte-match on line 148-150 (`--agent` removed on both, replaced with `--append-system-prompt-file`). Restart-survivability doctrine satisfied post-recovery.

## §6 — Sister-pattern lineage

- **ADR-0012** (4-cat invariant) — labels hygienic; terminal handoff doctrine
- **ADR-0015** (atomic 4-flag hand-off) — ordering matters
- **ADR-0044** (RED-first TDD) — tester-before-dev sequencing
- **ADR-0049** (d-test framework) — ≥5 TCs per d-test
- **ADR-0055** (Cadence Rule 1 atomic) — `.tmpl` + `scripts/tests/INDEX.md` row registered same commit
- **ADR-0057** (Closes anchor strict format) — `Closes #<N>` vs `Refs #<N>`
- **ADR-0059** (cluster-squash) — multi-PR atomic squash window
- **RETRO-022** (original 4-cat gap, Issue #1023) — silent-skip carrier
- **RETRO-023** (cross-repo codification, Issue #1024) — sister-pattern codification precedent
- **RETRO-024** (work-done-elsewhere 4-cat exception) — exception-not-rule; sister-pattern, orthogonal (RETRO-024 = cross-repo sister-PR terminal state, this clause = orphan-impl misuse)

## §7 — Acceptance criteria closure (Issue #1130)

| AC | Description | Status | Evidence |
|---|---|---|---|
| AC1 | `docs/decisions/ADR-0061-cli-2.1.207-agent-flag.md` PR opened (Refs template ADR-0060 + sister template PRs #97/#108/#110) | ✅ DONE | PR #1131 MERGED 2026-07-17T11:21:49Z |
| AC2 | `scripts/tests/dNNNN-cli-arg-hygiene.sh` d-test PR (Closes #1128, Refs #1129) | ✅ DONE | PR #1134 MERGED (commit 3749ae5) — d1128 d-test GREEN 7/7 |
| AC3 | `scripts/dev-studio-start.sh` line 149 impl PR (Closes #1129, Refs #1128) | ✅ DONE | PR #1132 MERGED (sha 388222c @ 15:18:46Z) |
| AC4 | Cluster-squash 3-PR per ADR-0059 | ✅ DONE | tmpl#122 + calc#1136 + calc#1132 = sub-cluster #2 wave v19 3/3 |
| AC5 | docs PR amends `.claude/agents/orchestrator.md.tmpl` with Retroactive-Close Precondition clause (Closes #1130) | ✅ DONE | this PR — `.tmpl` amendment + this RETRO-027 file |
| AC6 | `docs/retros/RETRO-027-*.md` RCA file written | ✅ DONE | this file |
| AC7 | Restart-survivability test runs green post-cluster-squash (`git show origin/main:scripts/dev-studio-start.sh` line 149 byte-matches template) | ✅ DONE | §5.2 — atilcalc origin/main + template main byte-match line 148-150 |

All 7 ACs ✅ DONE. Issue #1130 ready for `Closes` anchor — auto-CLOSED on this PR merge.

## §8 — Lessons learned + carry-forward

1. **Doctrine authored under time pressure often covers the immediate trigger but misses symmetric cases**. The Cadence Rule 2 amendment cycle ~#2776 covered forward-port but missed retroactive-close. Future amendments: enumerate BOTH directions when codifying a cadence rule.

2. **Working-tree fix ≠ PR-persisted fix**. The KAPI HOTFIX cycle ~#2776 confused "I have the fix locally" with "the fix is on main". The restart-survivability test (`git show origin/main:<file>`) is mandatory for any retroactive close.

3. **Closes anchor ≠ orphan close**. An orphan-impl issue cannot be closed retroactively without an anchor-PR that `Closes` it. Issue closure comments without PR backing are invalid.

4. **Untracked drafts die**. The `docs/decisions/ADR-0061-claude-code-agent-flag-removal.md` orphan draft (165 lines, cycle ~#2776) was never committed — the actual merged ADR used a different slug (`ADR-0061-cli-2.1.207-agent-flag.md`). Lesson: draft must be committed within the same turn it's authored, or it loses to git-cleanup.

5. **Tmux-wake KAPI bug is a separate work-stream**. Even post-launch-path fix (PR #1132), runtime tmux-wake of dev pane=%3 still fails (cycle ~#2855 peer-poke). This is a sibling bug, not a regression of PR #1132. Carry-forward: separate issue + separate fix-scope.

## §9 — Cadence Rule 2 final form (after this amendment)

Two clauses, both in `.claude/agents/orchestrator.md.tmpl`:

1. **§Cadence Rule 2 — ADR Merge → Sister-Issue Dispatch Atomicity** (KAPI HOTFIX SOUL AMEND, cycle ~#2776): forward-port dispatch on ADR merge — SAME TURN must `@`-mention-dispatch sister issues.

2. **§Cadence Rule 2 (continued) — Retroactive-Close Precondition** (this amendment, cycle ~#~12:56Z): orphan-impl retroactive close — BOTH preconditions (PR-persistence + Closes anchor) verified before closure.

Both clauses survive via `.tmpl` re-render. Future Cadence Rule 2 amendments add clauses, never replace — append-only lineage.

## Cross-references

**Sister-patterns:**
- RETRO-024 (`docs/retros/retro-024.md`) — work-done-elsewhere 4-cat exception (orthogonal, exception-not-rule)
- RETRO-022 (`docs/retros/retro-022.md`) — original 4-cat gap (Issue #1023)
- RETRO-023 (`docs/retros/retro-023.md`) — cross-repo codification (Issue #1024)
- RETRO-009 (`docs/retros/retro-009.md`) — Sprint 14 codifications (sister-pattern: doctrine gap surfaced only after bug-class re-manifested)

**ADRs:**
- ADR-0012 (4-cat invariant), ADR-0015 (atomic 4-flag hand-off), ADR-0044 (RED-first TDD), ADR-0049 (d-test framework), ADR-0055 (Cadence Rule 1 atomic), ADR-0057 (Closes anchor), ADR-0059 (cluster-squash)

**Issues:**
- Issue #1130 (this issue, Closes on merge)
- Issue #1128 (KAPI d-test, Closes #1128 via PR #1134)
- Issue #1129 (KAPI impl, Closes #1129 via PR #1132)
- Issue #1133 (d058 fix, Closes #1133 via PR #1136)
- Issue #121 (sister-PR forward-port, Closes #121 via PR #122)

**PRs:**
- PR #1131 — ADR-0061 docs (Closes #1128, Refs #1129)
- PR #1134 — d1128 d-test (Closes #1128)
- PR #1136 — d058 fix (Closes #1133, Refs #1135)
- PR #1132 — --agent flag impl (Closes #1129, Refs #1128)
- PR #122 — sister-PR forward-port (Closes #121)
- **This PR** — RETRO-027 + Cadence Rule 2 .tmpl amendment (Closes #1130)

**Cycles:**
- ~#2776 (KAPI hotfix discovery + Cadence Rule 2 amendment home — partial)
- ~#2787 (3-repo queue-reset)
- ~#~12:56Z (owner KAPI HOTFIX TRUE gap-close directive, this cycle)
- ~#2822 (tmpl#122 MERGED)
- ~#2843 (calc#1136 MERGED, Issue #1133 auto-CLOSED)
- ~#2855 (calc#1132 squash-MERGED, Issue #1129 idempotent)
- ~#2857 (this PR, Closes #1130 — meta-postmortem)

---

— @orchestrator, 2026-07-17T15:35+03:00 = 12:35Z, RETRO-027 Cadence Rule 2 retroactive-close doctrine RCA (Closes #1130, cluster-squash sub-cluster #2 wave v19 COMPLETE, KAPI HOTFIX (cycle ~#2776) production-effective-COMPLETE post-recovery)
