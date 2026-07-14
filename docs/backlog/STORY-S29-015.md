# STORY-S29-015: Re-render `new-projectsteps.md` + audit doc §10 (final, EXPANDED per Phase 2 #9)

> **PM-authored from `docs/sprints/sprint-29/00-plan.md` §3 S29-015** (PM grooming cycle ~#1566 per [ORCH→PM] dual-channel wake 2026-07-14T21:03:32+03:00 carrying owner directive 21:02+03).
> **Sprint 29 sizing:** S effort (1 PR). EXPANDED per Phase 2 #9 to include CLAUDE.md dual-path resolution.

## User Story

As **the next-project-bootstrap operator**,
I want **`new-projectsteps.md` and the sprint audit doc to reflect post-Sprint-29 reality (Step 5b obsolete, dual-path CLAUDE.md resolution documented)**,
So that **future projects follow a current, drift-free bootstrap and audit trail**.

## Why now

Post-portage, the manual Step 5b workaround is being auto-applied by S29-013 — leaving it in new-projectsteps.md invites the operator to perform a redundant no-op patch. Tag discipline references (v1.0.1) are outdated once Sprint 29 closes. The audit doc's "Post-Sprint-29 update checklist" was a self-aware sunset that has now elapsed. Phase 2 #9 added CLAUDE.md dual-path resolution: both root `CLAUDE.md.tmpl` (newer, canonical) and `.claude/CLAUDE.md.tmpl` must render to final forms for downstream-project compatibility.

## Acceptance Criteria

- **AC1** — `new-projectsteps.md` Step 5b removed (replaced with "auto-applied at Step 3 by S29-013 launcher patch").
- **AC2** — Tag discipline section updated: v1.0.1 → current HEAD tag post-Sprint-29-close; "stale" notes removed.
- **AC3** — Audit doc §10.2 updated: "Sprint 29 plan EXECUTED (2026-07-27)" + link to `docs/sprints/sprint-29/00-plan.md` + link to `docs/sprints/sprint-29/01-portage-verify.md` (S29-014 verification report).
- **AC4** — Post-Sprint-29 update checklist removed from the audit doc (self-aware sunset realized — the doc no longer has sunset conditions because the sunset happened).
- **AC5** — **CLAUDE.md dual-path resolution** (Phase 2 #9): `dev-studio-init.sh` renders BOTH paths:
   - Root `CLAUDE.md.tmpl` (newer canonical, commit 737b846e) → downstream `CLAUDE.md` at project root.
   - `.claude/CLAUDE.md.tmpl` (same content + Sprint 28 SOUL AMENDs per S29-017) → downstream `.claude/CLAUDE.md`.
   - Both paths rendered for downstream-project compatibility (init can be invoked multiple times; idempotency contract from ADR-0050).
- **AC6** — d-test (existing, re-run): `scripts/tests/d113-markdown-internal-links.sh` validates re-rendered links (e.g., Sprint 29 plan + S29-014 report).

## Out of scope

- Re-rendering every doc (only new-projectsteps.md + audit doc §10 scope; sister-pattern ADR-0050 governs broader cadence).
- Removing the `.claude/CLAUDE.md.tmpl` source (per Phase 2 #9, both paths retained; not deprecated).

## Open questions

- [ ] **Architect**: is the dual-path render idempotent on re-init? PM recommendation: yes, both renders guard with "skip if exists + same SHA" per ADR-0050 contract. Confirm before merge.
- [ ] **Owner**: ratification on tag discipline section contents (target tag string + release notes excerpt).

## Dependencies

- **Upstream:** S29-013 (Step 5b must be auto-applied); S29-014 (verification report must exist); S29-017 (soul .md.tmpl re-author for dual-path content parity).
- **Downstream:** Sprint 29 close ceremony (this story IS the final close doc-update); Sprint 30 backlog derivation (Sprint 30 inherits the post-portage audit baseline).

## Metrics of success

- **Leading:** `d113-markdown-internal-links.sh` GREEN in CI.
- **Leading:** owner-ratification on tag discipline section content.
- **Lagging:** no operator reports "Step 5b still references manual sed" in the 4 weeks post-Sprint-29.

## Sizing

- **Hint:** S effort (1 PR).
- **Final:** S (per plan.md §3 table; expanded per Phase 2 #9 but content was already 80% authorable).

## Lane

- **Author:** orchestrator (docs/ lane per file ownership matrix; docs/sprints/ + docs/ top-level)
- **Reviewer:** architect (9-Lens per ADR-0045; render path doctrine check)
- **Tester:** tester (d113 link validation per ADR-0044)
- **PM:** @product-manager (story author + sprint close facilitation)

## Sprint 29 Context

- **Epic:** E3 — Verification (final doc update)
- **Wave:** Wave 3 (final, last story before close ceremony)
- **Source-of-truth:** `docs/sprints/sprint-29/00-plan.md` §3 S29-015

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
