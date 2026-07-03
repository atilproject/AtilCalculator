# Contributing to AtilCalculator

> **Status**: 📝 DRAFT (cycle ~#3471, 2026-07-03, Issue #648 PR)
> **Story**: STORY-S21-021 (Issue #648, P1, 0.5sp)
> **Author**: @product-manager
> **Reviewer**: @architect (doctrine-change review gate accuracy)
> **Tester**: developer-self (markdown lint)

Thanks for your interest in contributing to AtilCalculator! This document describes the review process so your PR lands cleanly.

## Review process — 4 gates

Every PR passes through 4 gates before merge. The order is enforced by the GitHub PR template (`.github/pull_request_template.md`).

### Gate 1 — PR template (mandatory)

Every PR must use the project's [PR template](.github/pull_request_template.md). The template includes:

- **Summary** — what the PR does, why
- **Doctrine impact** — does it touch `docs/decisions/` (ADRs), `.claude/` (soul files), `.github/workflows/` (CI)?
- **ADR cross-ref** — list every ADR the PR references or modifies (full table in template)
- **Test plan** — unit + integration + d-test sibling (when applicable)
- **Owner checklist** — owner approval, CI green, labels correct, pre-merge grep clean

**Skip the template = CI label-check FAIL** (`.github/workflows/label-check.yml` enforces 4-cat invariant per [ADR-0012](docs/decisions/ADR-0012-required-label-set.md)).

### Gate 2 — ADR requirement for doctrine changes

If your PR modifies any of:

- `docs/decisions/ADR-NNNN-*.md` — proposing a new ADR or amending an existing one
- `.claude/agents/*.md` — agent soul files (PM lane cc'd, owner merges)
- `.claude/CLAUDE.md` — top-level doctrine file (orchestrator lane, owner merges)
- `.github/workflows/*.yml` — CI configuration (architect + tester draft, owner merges)

…then your PR must:

1. **Reference an existing ADR** in the PR body's ADR cross-ref table (per Gate 1 PR template §ADR cross-ref) — if the PR adds/modifies a rule documented in an existing ADR (label discipline, auto-ping, autonomy loop, etc.), cite the affected ADR
2. **Pass architect 9-Lens review** — architect verifies all 10 lenses (a-j) per [ADR-0045](docs/decisions/ADR-0045-auto-generated-file-refs-design-verification.md) (which codifies lens j) + [ADR-0043](docs/decisions/ADR-0043-8-lens-architect-review-checklist.md) (8-lens base) + [ADR-0054](docs/decisions/ADR-0054-9lens-enforcement.md) (9th lens enforcement)
3. **Document the doctrine impact** in the PR body (per PR template §Doctrine impact)

Doctrine changes are **owner-merge-gate only** per [ADR-0031](docs/decisions/ADR-0031-owner-override-doctrine.md) (Owner-Override PR Merge Doctrine).

### Gate 3 — d-test requirement (sister-pattern)

Per [ADR-0049](docs/decisions/ADR-0049-behavioral-workflow-test-framework.md) (Behavioral Workflow Test Framework), every doctrine-touching PR must include a **d-test sister-pattern**:

- ≥ 5 test cases (TCs) per d-test
- Tests must fail BEFORE the change is applied (RED-first)
- Tests must pass AFTER the change is applied (GREEN)
- Tests must remain in place to prevent regression

**When d-test is required** (sister-pattern examples):

- ADR-0017 (tech stack) PRs — verify the stack guard still triggers
- [ADR-0064](docs/decisions/ADR-0064-cross-user-env-var-pattern.md) (cross-user env-var) PRs — verify env-var pattern works across user boundaries
- ADR-0050 (pre-merge 4-cat verification) PRs — verify the 4-cat invariant still holds

**When d-test is NOT required**:

- Pure documentation PRs (e.g., typo fixes in non-doctrine docs)
- Chore PRs (deps update, tooling version bumps)
- Refactor PRs that don't change behavior

### Gate 4 — Owner approval gate

Per [ADR-0031](docs/decisions/ADR-0031-owner-override-doctrine.md), the **human owner** (`@atilcan65`) is the final merge authority for:

- All PRs that touch `.github/workflows/`, `.claude/`, `docs/decisions/`
- All PRs labeled `status:ready` (CI-green, peer-reviewed)
- All sprint close-out PRs (sprint-NN/close.md, RETRO-NNN.md)

Owner approval is posted as a PR review comment with `verdict-by:<ts>` stamp (per [ADR-0024](docs/decisions/ADR-0024-stale-verdict-watchdog-schema.md) verdict-by convention + [ADR-0044](docs/decisions/ADR-0044-verdict-by-scope-clarification.md) §TDD RED exclusion). Squash-merge is owner-only — agents MUST NOT merge their own PRs (per `.claude/CLAUDE.md §Things agents must NEVER do`).

## Review routing — CODEOWNERS

Per **AC2**, review routing uses the [CODEOWNERS file](.github/CODEOWNERS). GitHub auto-requests review from the CODEOWNERS-matched owners when a PR touches their paths.

**Current CODEOWNERS state** (`.github/CODEOWNERS`, 4 lines):

```gitignore
# Default owner for everything
* @atilcan65

# Architecture-critical paths
.github/             @atilcan65
.claude/             @atilcan65
docs/ARCHITECTURE-*  @atilcan65
```

In practice this means **the human owner is the default reviewer for every PR**, with explicit ownership for architecture-critical paths (`.github/`, `.claude/`, `docs/ARCHITECTURE-*`).

For non-architecture PRs, the per-lane `cc:*` labels handle review routing (see [ADR-0015](docs/decisions/ADR-0015-atomic-agent-handoff.md) Atomic Agent Hand-off):

- `cc:architect` — on docs/decisions/, docs/designs/, .github/workflows/ PRs
- `cc:developer` — on src/, tests/, scripts/ PRs
- `cc:tester` — on tests/, docs/bugs/, .github/workflows/ PRs
- `cc:product-manager` — on docs/sprints/, docs/product/, docs/backlog/, .claude/agents/ PRs
- `cc:orchestrator` — on docs/sprints/, sprint ceremony PRs
- `cc:human` — on status:ready PRs (owner merge gate)

> **Sprint 24 follow-up**: A richer CODEOWNERS table (lane-specific owners) is planned per [Issue #740](docs/product/vision.md) PM-triage table. Until that lands, the `cc:*` label discipline is the source of truth for review routing.

## Decision log — ADRs

Per **AC3**, all architectural decisions are tracked in [`docs/decisions/INDEX.md`](docs/decisions/INDEX.md). This is the canonical reference for:

- **Process doctrine** — 4-cat invariant, handoff discipline, auto-ping, autonomy loop
- **Architecture choices** — tech stack, design patterns, deployment topology
- **Operational patterns** — peer-poke, claim-next-ready, agent-watch loop

If you're proposing a change that affects any ADR, **read the ADR first** and reference it in your PR body. If no ADR exists for your change, propose one in parallel (see Gate 2).

## Quick checklist for contributors

Before opening a PR:

- [ ] Read [PR template](.github/pull_request_template.md) — fill every section
- [ ] Read relevant ADR(s) in [`docs/decisions/INDEX.md`](docs/decisions/INDEX.md)
- [ ] Run pre-merge grep locally: `grep -nE '\]\(\./|\]\(\.\./' <changed-files> || echo "clean"`
- [ ] Run d-test if doctrine-touching (RED-first, ≥ 5 TCs)
- [ ] Request review via CODEOWNERS path pattern (or `cc:*` labels if CODEOWNERS not yet rendered)
- [ ] Squash-merge is owner-only — do NOT self-merge

After PR opens:

- [ ] Watch CI — `.github/workflows/label-check.yml` + `.github/workflows/ci.yml` + d-tests
- [ ] Address reviewer 🟡 suggestions + 🟢 sign-offs
- [ ] Wait for owner squash (Gate 4)

## Out of scope

- Per-contributor CLA (not yet adopted)
- Code style guide (`pyproject.toml` `[tool.ruff]` + `mypy --strict`) — applies once the engine module lands per [ADR-0017](docs/decisions/ADR-0017-tech-stack.md) §Deferred; today no engine module exists, so lint/typecheck guides apply only to test scaffolding under `tests/`

---

**Cross-refs**:

- [PR template](.github/pull_request_template.md) — Gate 1 (Story #645, S21-014)
- [ADR-0012](docs/decisions/ADR-0012-required-label-set.md) — Required Label Set on Issue/PR Creation (4-cat invariant)
- [ADR-0015](docs/decisions/ADR-0015-atomic-agent-handoff.md) — Atomic Agent Hand-off (preserve 4-category invariant)
- [ADR-0024](docs/decisions/ADR-0024-stale-verdict-watchdog-schema.md) — Stale-Verdict Watchdog Schema (verdict-by convention)
- [ADR-0031](docs/decisions/ADR-0031-owner-override-doctrine.md) — Owner-Override PR Merge Doctrine (Gate 4)
- [ADR-0043](docs/decisions/ADR-0043-8-lens-architect-review-checklist.md) — 8-Lens Architect Review Checklist (Gate 2 base)
- [ADR-0044](docs/decisions/ADR-0044-verdict-by-scope-clarification.md) — Verdict-By:* SLA Scope Clarification (TDD RED exclusion)
- [ADR-0045](docs/decisions/ADR-0045-auto-generated-file-refs-design-verification.md) — lens (j) auto-generated file refs verification (Gate 2)
- [ADR-0049](docs/decisions/ADR-0049-behavioral-workflow-test-framework.md) — Behavioral Workflow Test Framework (Gate 3 d-test framework)
- [ADR-0054](docs/decisions/ADR-0054-9lens-enforcement.md) — 9th lens enforcement
- [ADR-0057](docs/decisions/ADR-0057-closes-anchor-guard.md) — Closes-anchor guard (parser-friendly issue close formats)
- [ADR-0064](docs/decisions/ADR-0064-cross-user-env-var-pattern.md) — Cross-User Env Var Pattern (Gate 3 sister-pattern example)
- [docs/decisions/INDEX.md](docs/decisions/INDEX.md) — full ADR index (AC3)

**Story**: STORY-S21-021, Issue #648, Sprint 24 PM lane.

🤖 Generated with [Claude Code](https://claude.com/claude-code)