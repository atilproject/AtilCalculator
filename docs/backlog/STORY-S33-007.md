# STORY-S33-007: dev-studio-init.sh .tmpl preservation fix — `.tmpl` source-of-truth invariant (Issue #201)

> **PM-authored from architect dual-channel wake** (Issue #201 carry-over #9 of Issue #1171 sister chain to Issue #1191) per [ARCH→PM] dual-channel wake 2026-07-20T21:01:04+03:00 + arch advisory 🟡 cmt 5025488624 (2026-07-20T18:00:44Z).
> **Sprint 33 sizing:** M effort (init.sh impl + d-test ≥5 TCs + INDEX.md row + CHANGELOG entry single commit per ADR-0055 §1 Cadence Rule 1 atomic).
> **Priority:** P1 (Sprint 33 P1, RETRO-032 carry-over #9 of Issue #1171)
> **Lane cluster:** Wave 10 P1 cluster — paired with Issue #1191 (carry-over #8) per arch advisory.

## User Story

As **a developer authoring a soul-amend PR via worktree + init.sh + branch cycle**,
I want **`scripts/dev-studio-init.sh` to preserve `.tmpl` source-of-truth files (the doctrine input files per `.claude/CLAUDE.md` rendering convention)**,
So that **every soul-amend PR cycle (`.claude/agents/*.tmpl` + `CLAUDE.md.tmpl`) can proceed safely in worktrees without manual `.tmpl` restore workarounds, and the doctrine source-of-truth is preserved across init.sh runs**.

## Why now

Sprint 32 close ceremony (Issue #1171) + Wave 8+ close-out surfaced Issue #1188 carry-over #7 (tester soul amend) hit the init.sh `.tmpl` deletion bug at 16:41:00Z. The PR was REOPENED via `git checkout HEAD -- .tmpl` manual workaround (cycle ~#3967 doctrine codified in PR #1188 Lane 2 docs verdict chain 2/2, verdict cmt 5024803286). Without a proper fix, **every soul-amend PR cycle in worktrees requires this manual restore** — a known foot-gun documented in Issue #201 §Mitigation Until Fixed.

Sister-pattern to RETRO-022 / Issue #1023 — same reflex-class damage ("helper passes destroy working state"). Sister-pattern to Issue #1188 carry-over #7 (already REOPENED for `.tmpl` restore).

Per file ownership matrix: `.claude/` directory = **human-only territory**. Any doctrine-source deletion (intentional or accidental via bot pass) is P1 by default because doctrine source-of-truth files are NOT recoverable from git history alone (uncommitted edits lost in worktree).

## Acceptance Criteria

- **AC1** (per arch NIT #1) — Run repro; `.claude/agents/*.tmpl` and `CLAUDE.md.tmpl` are NOT deleted by `bash scripts/dev-studio-init.sh`. `.md` files appear UNTRACKED (not staged, not committed-to-branch). Expected: `.tmpl` files retained as-is (source-of-truth); only `.md` files rendered as outputs.
- **AC2** — A soul-amend PR cycle (edit `tester.md.tmpl` → run init.sh → commit `tester.md.tmpl` → push → open PR → merge) works WITHOUT manual `.tmpl` restore. End-to-end CI green.
- **AC3** (per ADR-0044 RED-first) — Add d-test `d-init-sh-tmpl-preservation.sh` (≥5 TCs) covering TC1-TC5 for each `.tmpl` file survival under init.sh: TC1=`.claude/agents/architect.md.tmpl`, TC2=`.claude/agents/developer.md.tmpl`, TC3=`.claude/agents/orchestrator.md.tmpl`, TC4=`.claude/agents/product-manager.md.tmpl`, TC5=`.claude/agents/tester.md.tmpl` + TC6 `CLAUDE.md.tmpl` survival (≥6 TCs total).
- **AC4** (per ADR-0055 §1 Cadence Rule 1 atomic) — `scripts/tests/INDEX.md` d-test row added same commit.
- **AC5** (per ADR-0055 §2 Cadence Rule 2 cumulative) — `CHANGELOG.md` entry (`fix(scripts): ...`) added same commit.
- **AC6** (per arch NIT #4 — mitigation explicit) — Manual workaround `git checkout HEAD -- .claude/agents/*.tmpl CLAUDE.md.tmpl` no longer required for soul-amend PRs in any worktree. (Workaround documented in Issue #201 body §Mitigation Until Fixed.)
- **AC7** (per arch NIT #3 — root-cause confirmation) — Fix PR description identifies the specific line(s) in `scripts/dev-studio-init.sh` causing the .tmpl deletion (sed -i / mv / rm) + explains why the fix preserves .tmpl files. Per cycle ~#3893Q v2 env-rot discipline + RETRO-005 #26 anti-blindness, root-cause analysis is a fix PR deliverable.

## Out of scope

- Permanent fix to GitHub's `Closes #N ACk` partial-anchor behavior (Issue #1143 / ADR-0057 amendment candidate, separate workstream).
- Pre-fix mitigation codification in `.claude/CLAUDE.md` SOUL AMEND section as interim pattern (separate docs PR, NOT blocker for fix PR — but recommended parallel work).
- Sister-repo propagation to atilproject/AtilCalculator fork if divergence detected (Cadence Rule 2 cumulative NO-OP if tmpl-side fix is sufficient).

## Open questions

- [ ] **Architect**: confirm the impl approach (replace `mv .tmpl .md` with `cp .tmpl .md` + sed on copy; OR guard `rm` of `.tmpl` patterns; OR other root-cause-specific fix). Architect 9-Lens review recommended BEFORE dev impl per §4.4 Lane 2 chain.
- [ ] **Developer**: confirm d-test naming preference (`d-init-sh-tmpl-preservation.sh` per current Issue #201 vs `d-tmpl-preservation.sh` shorter sister-pattern to d058/d068b/d-pr-1147 cadence). Per arch NIT #2, either works; defer to developer preference.
- [ ] **Tester**: confirm Lane 3 d-test-only sign-off pattern (cycle ~#3642H byte-equal sufficient for d-test impl PRs) applies, OR escalate to full Lane 2 docs verdict chain.
- [ ] **Orchestrator**: confirm Wave 10 cluster-squash timing (Issue #1191 PR #1193 + Issue #201 fix PR at W1 close per ADR-0059) — both P1 infra bugs, both fixable in W1.

## Dependencies

- **Upstream:** Sprint 33 W1 starts 2026-07-21 (conditional on AC5 24h soak GREEN at 2026-07-21T16:07:23Z).
- **Sister-cluster:** Issue #1191 carry-over #8 (PR #1193 squash-pending); both P1 infrastructure fixes at Wave 10 cluster.
- **Sister-pattern:** Issue #1188 carry-over #7 already REOPENED for `.tmpl` restore via manual workaround per cycle ~#3967 (doctrine codified in PR #1188 Lane 2 docs verdict chain 2/2, verdict cmt 5024803286).
- **Sister-pattern:** Issue #1023 / RETRO-022 (reflex-class damage: helper passes destroy working state).

## Metrics of success

- **Leading:** d-init-sh-tmpl-preservation d-test ≥6 TCs GREEN (covering 5 `.tmpl` files + `CLAUDE.md.tmpl`).
- **Leading:** soul-amend PR cycle end-to-end works without `.tmpl` restore workaround (validated by opening a sample soul-amend PR in W1).
- **Lagging:** Sprint 33+ soul-amend PR cycle incidents due to init.sh `.tmpl` deletion = 0.

## Sizing

- **Hint:** M effort (init.sh impl fix + d-test ≥6 TCs + INDEX.md row + CHANGELOG entry per Cadence Rule 1 atomic).
- **Final:** M (per Issue #201 ACs + arch 4 NITs).

## Lane

- **Author:** developer (impl fix in `scripts/dev-studio-init.sh` + d-test + INDEX.md + CHANGELOG per Cadence Rule 1 atomic)
- **Reviewer:** architect (9-Lens review per ADR-0045 + root-cause confirmation per arch NIT #3) + tester (Lane 3 d-test-only sign-off per cycle ~#3642H)
- **Co-CC:** PM (cross-track carry-over #9 tracking), human (owner squash gate per ADR-0031 — `.github/workflows/` and `scripts/` are infra territory)
- **Owner squash gate:** per ADR-0031 (init.sh = infra territory)

## Sprint 33 Context

- **Epic:** E10 — Doctrine refresh + infra hardening
- **Wave:** Sprint 33 W1 (foundation) — Wave 10 cluster with Issue #1191
- **Source-of-truth:** Issue #201 + arch advisory cmt 5025488624 + Issue #1171 Wave 8+ close ceremony + RETRO-032 carry-over #9
- **Sister-pattern:** Issue #1188 carry-over #7 (already REOPENED via `.tmpl` restore workaround per cycle ~#3967)
- **Sister-pattern:** Issue #1023 / RETRO-022 (reflex-class damage doctrine)
- **Sister-cluster:** Issue #1191 carry-over #8 (Wave 10 P1 cluster per arch advisory)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
