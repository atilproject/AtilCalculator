# STORY-S28-015: ADR-0057 Closes anchor strict-format CI gate (closes #984 + #988 + #972 manual-close family)

> **Sprint 28 ID mapping**: Issue #994 ID = `TD-XXX`; PM canonical ID = `STORY-S28-015`
> **Origin**: Sprint 28 W3 grooming, surfaced by orchestrator at 2026-07-11T09:02Z (cycle ~1729)
> **Architect ack**: 2026-07-11T09:06:28Z — architect lane WIP=0/2 after W2 cluster ship

## User Story
As **a repository maintainer who relies on cross-repo-close auto-fire for sprint closeouts**,
I want **`.github/workflows/label-check.yml` (or new `closes-format-check.yml`) to validate every `Closes ...` line in PR bodies against the strict ADR-0057 format**,
So that **PRs with non-strict anchors fail CI before merge (preventing the manual-close counter from growing past its current value of 4 since the #785 family)**.

## Why now
Sprint 28 W3 (doctrine enforcement gap closure). TD-068 + TD-069 sister-tickets superseded by this unified CI gate. Architect has explicit W3 capacity (lane WIP=0/2 post-W2 cluster ship at cycle ~819). Manual-close cost is measurable (4 closes since #785 family) and growing — the format-drift incident in tmpl#67 (`Closes S28-004 (Issue #984)` parenthetical-without-owner) is the latest live instance.

## Acceptance Criteria
- **AC1** — GIVEN a PR opened with body containing `Closes ...` WHEN the CI gate runs THEN every `Closes` line matches one of:
  - `^Closes\s+(https://github\.com/[^/]+/[^/]+/issues/\d+|#\d+|atilcan65/[^/]+#\d+)$` (strict)
  - OR markdown link variant `^Closes\s+\[#[0-9]+\]\(https://github\.com/[^/]+/[^/]+/issues/\d+\)$`
- **AC2** — GIVEN a PR with a non-compliant Closes line WHEN CI gate runs THEN a comment is posted listing the offending line(s) AND the `closes-format-check` workflow fails (block-merge mode) — per team decision in #994 follow-up comment.
- **AC3** — GIVEN PRs already merged with non-strict format (tmpl#67 live instance, 3 other manual-closes since #785) WHEN the gate lands THEN no new manual-close incidents accrue for ≥14 days (verifiable via Issues list filtered by `closed_by:orchestrator`).
- **AC4** — GIVEN the merged gate WHEN cross-repo-close auto-fire on a strict-format PR runs THEN no regression (tmpl#66 / calc#992 / tmpl#65 baseline strict-format PRs continue to auto-close their targets).

## Out of scope
- Backfilling already-merged non-strict PRs (gate is forward-only enforcement)
- Migrating existing issues to strict format (parenthetical-without-owner variants remain readable)
- Modifying the 4-cat label invariant (label-check.yml orthogonal concern)
- Implementing a pre-commit hook (CI gate is the scope per #994)

## Open questions
- [ ] Block-merge vs warn-only mode for first 7 days? → owner: owner (architect recommends block-merge from day 1 per #994 body)
- [ ] Should `closes-format-check.yml` be a new workflow file or a step appended to existing `label-check.yml`? → owner: architect
- [ ] Sister-pattern extension: lint rule in `.github/PULL_REQUEST_TEMPLATE.md` hinting strict format? → deferred to Sprint 29+ backlog
- [ ] Watchlist for the `Closes [text](#N)` markdown link variant acceptance — needs explicit regex char-class coverage → owner: architect

## Mockups / references
- Issue #994 (source — TD-XXX ticket, owner:architect)
- ADR-0057 (the doctrine being enforced — already exists, soft enforcement today)
- Live instance table in #994 body (tmpl#67 the 1 failure, 4 successes baseline)
- Sister-pattern: Issue #984 + #988 + #972 manual-close family (cross-watchdog triggers)
- `scripts/tests/` d-test framework sister-pattern (≥5 TCs for gate acceptance)

## Dependencies
- **Upstream**: ADR-0057 already accepted; architect ack at 09:06:28Z
- **Downstream**: All future PRs (Sprint 28 W3+) inherit the gate; manual-close counter should plateau

## Metrics of success
- **Leading**: gate merged to `main`, ≥5 d-test TCs passing (one per regex variant + one negative TC + one regression TC)
- **Lagging**: manual-close counter stays ≤4 for ≥14 days post-merge (verifiable via `gh issue list --search "closed by orchestrator manual"`)

## Cross-references
- Issue #994 (parent — TD-XXX ticket, agent:architect)
- ADR-0057 (enforcement source — strict format mandate)
- Issue #984 (live instance — tmpl#67 manual-close trigger)
- Issue #988 (sister-ticket — manual-close family)
- Issue #972 (sister-ticket — manual-close family)
- Issue #785 (manual-close counter origin)
- RETRO-018 W6 (cross-watchdog sister-pattern)