# STORY-S29-002: Move v1.0.1 tag to current template HEAD + add v0.3.0 tag to launcher HEAD

> **Sprint 29 ID mapping**: Issue ID = `STORY-S29-002`; PM canonical ID = `STORY-S29-002`
> **Origin**: Sprint 29 W1 grooming, surfaced by orchestrator dual-channel wake 2026-07-13T11:31:41+03:00 (cycle ~1193)
> **Source-of-truth**: `docs/sprints/sprint-29/00-plan.md` §3.S29-002 (commit `56e42da`, 2026-07-13)

## User Story
As **a downstream project owner who wants to pin to a known-good template version**,
I want **the `v1.0.1` tag on `dev-studio-template` to point at the current HEAD (`43592c24`, post-Sprint-28-forward-port) AND a new `v0.3.0` tag on `dev-studio-launcher` HEAD (`b0d820da`)**,
So that **`git checkout v1.0.1` and `git checkout v0.3.0` actually reflect live state (no stale-tag drift), preserving v1.0.0 and v0.2.0 as historical anchors**.

## Why now
Sprint 29 W1 (tag discipline restored). Sprint 28 audit §9.3 confirmed owner's intuition: v1.0.1 tag at `62aec11b` (2026-07-09) is 6 PRs behind HEAD `43592c24` (2026-07-11). Launcher HEAD `b0d820da` claims v0.3 in commit message but no tag exists. Owner directive #1 ("v1.0.1 ile devam") ratifies force-move. Trivial effort (2 commands), but owner-merge-gated per CLAUDE.md (destructive git ops).

## Acceptance Criteria
- **AC1** — `git ls-remote --tags atilproject/dev-studio-template | grep v1.0.1` returns object SHA = current HEAD `43592c24`.
- **AC2** — `git ls-remote --tags atilproject/dev-studio-launcher | grep v0.3` returns non-empty (v0.3.0 tag exists at HEAD `b0d820da`).
- **AC3** — Existing v1.0.0 / v0.2.0 tags preserved (only the live "current" tags move forward; legacy tags stay as historical anchors).
- **AC4** — Force-push is explicitly authorized in PR description (`This PR force-moves v1.0.1 tag to current HEAD; v1.0.0 preserved as historical anchor; rationale: owner directive #1 'v1.0.1 ile devam'`).
- **AC5** — Tag-move PR closes a single issue / links to `00-plan.md` §S29-002 (cross-traceability).

## Out of scope
- Introducing v1.0.2 / v1.1.0 tags (owner directive #1 explicitly rejects this)
- Cherry-picking individual commits from Sprint 28 forward-port series (tag move captures them all)
- Modifying tag-protection rules on GitHub side (deferred to Sprint 30+ per audit §9.4)

## Open questions
- [ ] Force-push authorization mechanism: PR approval + owner squash-merge per ADR-0031? Or owner direct push to tags ref? → owner: architect (destructive ops need explicit confirmation)
- [ ] Should v0.3.0 tag be annotated (recommended for releases) or lightweight? → owner: orchestrator

## Mockups / references
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §9.1, §9.2, §9.3, §9.4 (audit evidence + recommendation)
- AtilCalculator tag discipline precedent (PRs #63, #967)

## Dependencies
- **Upstream**: None (pure git tag ops)
- **Downstream**: S29-014 (verification report cites tag discipline restored per §9.3 verdict flip), S29-015 (new-projectsteps.md tag discipline section update)

## Metrics of success
- **Leading**: Both tag moves verified via `gh api /repos/.../git/refs/tags` + `/git/tags/<name>`
- **Lagging**: Audit doc §9.3 verdict updates from "🔴 owner intuition confirmed" to "✅ tag discipline restored"

## Cross-references
- Issue #1011 (Sprint 29 KICKOFF)
- `docs/sprints/sprint-29/00-plan.md` §3.S29-002
- `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md` §9, §6.2 B-01, B-02
- ADR-0031 (owner merge gate — destructive ops)
- Owner directive #1 ("v1.0.1 ile devam") ratified 2026-07-13 cycle ~#1159
- Sister-pattern: AtilCalculator tag discipline (PRs #63, #967)