# STORY-S28-014: Path-Verify Doctrine finalize — Issue #972 close-out (architect-led, in-progress)

> **Sprint 28 ID mapping**: Issue #974 ID = `Path-Verify doc`; PM canonical ID = `STORY-S28-014`

## User Story
As **any agent (architect/developer/tester) verifying claims about template-vs-project gaps in any future audit**,
I want **the Path-Verify Doctrine codified (Issue #972 owner-decision = option (a) soul amend)**,
So that **I correctly verify against the CANONICAL tmpl path (`/home/atilcan/projects/dev-studio-template/...`), NOT the project-local mirror (`AtilCalculator/.claude/...`), preventing the PM cycle ~766 LIVE INSTANCE from repeating**.

## Why now
Sprint 28 wave 3 (doctrine codification, 0.5sp, sister to S28-011/S28-012 audit-fix ADRs). Owner has picked option (a) per Issue #972 ("soul amend"). Architect has flipped status:ready → status:in-progress (cycle ~769+).

## Acceptance Criteria
- **AC1** — GIVEN Issue #972 owner-decision = option (a) WHEN architect drafts soul amend block THEN text matches architect's proposed wording verbatim (per Issue #972 body).
- **AC2** — GIVEN the soul amend block WHEN merged into `.claude/agents/architect.md` + `.claude/agents/developer.md` + `.claude/agents/tester.md` (3 files, parallel to RETRO-018 W6 + Issue #389 + Issue #414 precedents) THEN each file contains the Path-Verify block.
- **AC3** — GIVEN Issue #972 WHEN I check the issue status THEN it's `status:done` (Closes #972) with the merge commit hash cited.
- **AC4** — GIVEN the merged Path-Verify block WHEN next architect + developer + tester cycle runs a template audit THEN ground-truth verification uses canonical tmpl path (verifiable via audit-methodology section in next audit).

## Out of scope
- Implementing tooling to enforce Path-Verify (doctrine codification only)
- Modifying `.claude/agents/product-manager.md` (PM isn't a verification-agent for template audits; PM is consumer)

## Open questions
- [ ] Should the Path-Verify block cite PM cycle ~766 LIVE INSTANCE verbatim? → owner: architect (already proposed in Issue #972 body)
- [ ] Does the soul amend need PM ack comment first (since PM cycle ~769 ack is the cross-watchdog live-instance cite)? → owner: architect

## Mockups / references
- Issue #972 (source, owner picked option a)
- PR #967 cmt 4938092177 (PM cycle ~766 self-correction — LIVE INSTANCE)
- PR #967 cmt 4938118016 (PM cycle ~768 architect-ack reconciliation)
- Issue #414, RETRO-018 W6 (soul amend precedents — sister-pattern)

## Dependencies
- **Upstream**: Issue #972 owner-decision (already accepted cycle ~769+)
- **Downstream**: All future template audits (Sprint 29+) inherit the doctrine

## Metrics of success
- **Leading**: Path-Verify block present in 3/3 soul files (architect + developer + tester)
- **Lagging**: zero path-verify incidents in next template audit (verifiable via audit-history regression)

## Cross-references
- Issue #974 (top-14 Path-Verify doc)
- Issue #972 (parent — owner-decision)
- PR #967 cmt 4938092177 (LIVE INSTANCE)
- RETRO-018 W6, Issue #414 (sister-pattern precedents)