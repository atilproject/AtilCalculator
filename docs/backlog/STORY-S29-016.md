# STORY-S29-016: pyproject.toml.tmpl + LICENSE.tmpl + .template-version render path (CRITICAL BLOCKER)

> **PM-authored from `docs/sprints/sprint-29/00-plan.md` §3 S29-016** (PM grooming cycle ~#1566 per [ORCH→PM] dual-channel wake 2026-07-14T21:03:32+03:00 carrying owner directive 21:02+03).
> **Sprint 29 sizing:** **L effort — LOAD-BEARING CRITICAL per arch v3 audit §C Gap 1.** Owner directive #6 confirmed MIT default; this story blocks owner goal "launcher creates projects with full features".

## User Story

As **a downstream-project operator bootstrapped from the template**,
I want **`dev-studio-init.sh` to render `pyproject.toml` + `LICENSE` + `.template-version` files at downstream project init**,
So that **I can run `pip install -e .[dev]`, `pytest`, `ruff`, `mypy` immediately, my project has a license file, and drift detection works**.

## Why now

Template currently has NO `pyproject.toml` (REST `/contents/pyproject.toml` → 404). AtilCalculator has a 9731B pyproject.toml. Downstream projects created via the launcher cannot run `pip install -e .[dev]`, `pytest`, `ruff`, `mypy`, or define `src/` package structure without pyproject.toml. This blocks owner goal "launcher creates projects with full features" and is flagged as **arch v3 audit §C Gap 1 — CRITICAL BLOCKER**. LICENSE absence puts projects in license-ambiguous territory. `.template-version` is the drift-detection marker that prevents downstream projects from being stranded on stale template revisions.

## Acceptance Criteria

- **AC1** — New template file `pyproject.toml.tmpl` (parameterized: name, version, deps). Mirror AtilCalculator's pyproject.toml structure (PEP 621 metadata, dev-deps group, pytest config, ruff config, mypy config) with `{{project_name}}`, `{{project_description}}`, `{{version}}` placeholders.
- **AC2** — New template file `LICENSE.tmpl` (MIT per AtilCalculator pattern; license choice confirmed by owner Phase 2 directive #6 default — owner did not push back on MIT):
   ```
   MIT License
   Copyright (c) {{year}} {{owner}}
   ...
   ```
- **AC3** — New template file `.template-version.tmpl` (drift-prevention marker; rendered to `.template-version` at init):
   ```
   {{template_version}}  # e.g., "1.0.1-post-sprint-29"
   ```
- **AC4** — `dev-studio-init.sh` updated to render all 3 templates → final files at downstream init. **Idempotent**: re-running `dev-studio-init.sh` does not corrupt existing final files (sister-pattern to existing `.claude/CLAUDE.md.tmpl` render path per ADR-0050). Re-init must skip-if-up-to-date, never overwrite user-customized final files.
- **AC5** — d-test (new, ≥3 TCs per ADR-0049): `scripts/tests/s29-016-pyproject-license-template-version.sh` validates:
   - (a) pyproject.toml.tmpl presence + PEP 621 schema (placeholder substitution succeeds)
   - (b) LICENSE.tmpl presence + MIT content match
   - (c) `.template-version.tmpl` presence + drift-detection logic (template_version is set; downstream can compare)
   - (d) dry-run `pip install -e .[dev]` after render succeeds (no missing setup.py / setup.cfg conflict)
- **AC6** — Sister to `.claude/CLAUDE.md.tmpl` render path (ADR-0050 load-bearing ADR doctrine); same idempotency + dry-run contract. Cascade implication: S29-015 AC5 dual-path render requires this story's render path to be verified first.

## Out of scope

- License choice beyond MIT (other licenses deferred to per-project PR after Sprint 30+).
- Auto-generating `.gitignore` (already exists in template; this story does not modify).
- CI workflow changes (S29-010 already covered workflow ports).

## Open questions

- [ ] **Architect**: confirm PEP 621 placeholder syntax (`{{var}}` vs PEP 621's native `[project] name = "..."` literal). PM recommendation: `{{var}}` for clarity but arch's PEP 621 `name = ...` literal may be more idiomatic.
- [ ] **Owner**: confirm MIT choice + acceptable Copyright text template wording.
- [ ] **Architect**: confirm `.template-version` location (project root vs `docs/`). PM recommendation: project root for discoverability, mirrors `.template-gitignore` convention.

## Dependencies

- **Upstream:** S29-001 (template render doctrine, sister to `.claude/CLAUDE.md.tmpl` render path).
- **Downstream:** S29-014 (verification — S29-016 must land for d-test verification to be meaningful); S29-015 AC5 (dual-path CLAUDE.md render references this story's render path contract).

## Metrics of success

- **Leading:** d-test (AC5) GREEN in CI.
- **Leading:** downstream dry-run `pip install -e .[dev]` exits 0 on a freshly-rendered project.
- **Lagging:** first 3 launcher-provisioned projects run ruff/pytest/mypy without manual intervention.

## Sizing

- **Hint:** L effort (3 template files + render path + d-test).
- **Final:** L (load-bearing CRITICAL per arch v3 §C Gap 1 — owner goal blocker).

## Lane

- **Author:** architect (template render doctrine + PEP 621 design + idempotency contract)
- **Reviewer:** architect (9-Lens per ADR-0045; sister-pattern check to ADR-0050)
- **Co-owner:** developer (PEP 621 metadata + d-test per ADR-0044 RED-first)
- **Tester:** tester (d-test per ADR-0044 + dry-run verification per AC5(d))
- **PM:** @product-manager (story author + Sprint 29 close facilitation)
- **Owner squash gate:** per ADR-0031 (load-bearing CRITICAL → human merge)

## Sprint 29 Context

- **Epic:** E4 — Template Render Path (Wave 2C, CRITICAL BLOCKER)
- **Wave:** Wave 2C (parallel with Wave 2B)
- **Source-of-truth:** `docs/sprints/sprint-29/00-plan.md` §3 S29-016

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
