# STORY-S29-013: Launcher auto-applies self-hosted 4-tuple on bootstrap (per owner #5)

> **PM-authored from `docs/sprints/sprint-29/00-plan.md` §3 S29-013** (PM grooming cycle ~#1566 per [ORCH→PM] dual-channel wake 2026-07-14T21:03:32+03:00 carrying owner directive 21:02+03 — Sprint 29 ALL gap-closing, zero Sprint 30 parks).
> **Sprint 29 sizing:** S effort (1 PR to launcher). Load-bearing per owner directive #5 (self-hosted-only deployment default, not manual sed patch).

## User Story

As **an owner-operator using the launcher to bootstrap a new project**,
I want **the launcher to auto-apply the self-hosted-runner 4-tuple to all stock `.github/workflows/*.yml` on bootstrap (no manual sed step required)**,
So that **every new project ships with self-hosted-only CI by default and Step 5b of the manual new-projectsteps.md workaround becomes obsolete**.

## Why now

Current `new-projectsteps.md` Step 5b is a manual `sed -i` workaround the user runs post-bootstrap. Owner directive #5 elevates self-hosted-only to an automatic default. Manual workarounds are error-prone (user forgets → CI queues forever on missing self-hosted runner). Atomicizing the patch into the launcher bootstrap eliminates the manual risk and tightens the post-portage template invariant.

## Acceptance Criteria

- **AC1** — New step added to `new-project.sh` immediately after `bootstrap-labels.sh`: a function `apply_self_hosted_runner_patch()` that walks `.github/workflows/*.yml` and patches `runs-on: ubuntu-latest` (or absent `runs-on`) to the 4-tuple per Step 5b snippet.
- **AC2** — Idempotent: re-running on already-patched workflows is a no-op (re-run safe — only patches workflows still on `ubuntu-latest` or missing `runs-on`).
- **AC3** — Pre-flight `gh api repos/<owner>/<name>/actions/runners` check: if no self-hosted runners match the 4-tuple, emit a loud user-facing warning ("self-hosted runner not registered; CI will queue forever until registered"). Warning must be visible (not silent log line).
- **AC4** — d-test (new, ≥5 TCs per ADR-0049): patches idempotency + regex correctness + warning emission across all stock workflow files.
- **AC5** — `new-projectsteps.md` Step 5b removed; replaced with "auto-applied at Step 3; verify with `grep` if you want".

## Out of scope

- Adding self-hosted runner registration itself (out-of-launcher scope; deferred to ops playbook).
- Changing the 4-tuple values (owned by architect; per ADR-0017/0050 load-bearing doctrine).

## Open questions

- [ ] **Architect**: is the 4-tuple canonical source `.claude/CLAUDE.md.tmpl` or a separate constant in launcher config? PM recommendation: launcher constant for simplicity, but arch may want template-rendered to keep single-source.
- [ ] **Owner**: confirm warning text tone — explicit call-out vs GitHub Actions-style "::warning::" emit.

## Dependencies

- **Upstream:** S29-001 (template-side 4-tuple canonical pattern); AtilCalculator's existing self-hosted-only pattern (load-bearing sister).
- **Downstream:** S29-014 (verify-portage — needs S29-013 to land for verification to be meaningful); S29-015 (Step 5b deprecation in new-projectsteps.md).

## Metrics of success

- **Leading:** every new launcher-provisioned project has `runs-on: self-hosted...` 4-tuple on all stock workflows (verified by `grep` post-bootstrap).
- **Leading:** d-test ≥5 TCs per ADR-0049 GREEN in CI on launcher repo.
- **Lagging:** first 3 new launcher-provisioned projects ship without operator intervention on CI (no "why is my CI queued" questions).

## Sizing

- **Hint:** S effort (1 PR to launcher).
- **Final:** S (per plan.md §3 table; owner ratified per directive #5).

## Lane

- **Author:** developer (launcher scripts/ lane per file ownership matrix)
- **Reviewer:** architect (9-Lens per ADR-0045; matches S29-001 sister-pattern)
- **Tester:** tester (d-test per ADR-0044 RED-first)
- **PM:** @product-manager (story author)

## Sprint 29 Context

- **Epic:** E2 — Template Bootstrap Closure
- **Wave:** Wave 2B (gap-closing, parallel with Wave 2C)
- **Source-of-truth:** `docs/sprints/sprint-29/00-plan.md` §3 S29-013

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
