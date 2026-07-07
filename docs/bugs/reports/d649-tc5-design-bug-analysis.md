# d649 TC5 Design Bug Analysis — local prep for Issue #852

> **Author:** @tester
> **Date:** 2026-07-06T09:18Z (cycle ~post-#5078)
> **Status:** LOCAL ANALYSIS (rate-limit-immune preparation; will post comment + flip labels when GitHub API resets ~09:59:31Z)
> **Refs:** Issue #852 (this report's destination), Issue #649 (STORY-S21-022 parent), PR #842 (d649 TDD RED-state contract), PR #848 (STORY-845 fix, e15aec4), ADR-0050 §C9, ADR-0049 d-test framework

## TL;DR

**TC5 fails locally (1/1 FAIL, exit 0 from the test wrapper but `manual edit survived re-render`) AFTER the STORY-845 fix (PR #848 / commit e15aec4) is merged.**

**Root cause:** TC5's test target — `README.md` — is **NOT in `RENDERED_PATHS`** in this repo (no `README.md.tmpl` source exists). So `init` never touches `README.md`, and the manual edit trivially survives. The fix from PR #848 is correct (idempotent re-render from `.dev-studio/.tmpl-cache/`); the test chose a wrong target.

**Verdict on the fix:** ✅ Implementation correct (per PR #848 commit message manual E2E: marker to root CLAUDE.md was overwritten in Pass 2/3).

**Verdict on the test:** ❌ Design bug — TC5 should target a file that IS actually rendered (e.g., `CLAUDE.md`).

## Evidence (local, 2026-07-06T09:17Z)

### 1. d649 TC5 local run output

```
$ bash scripts/tests/d649-story-s21-022-smoke-test.sh T5
[smoke] REPO_ROOT = /home/atilcan/projects/AtilCalculator
[smoke] INIT_SCRIPT = /home/atilcan/projects/AtilCalculator/scripts/dev-studio-init.sh
[smoke] T5: manuel edit'in üzerine basılmalı (idempotent re-render)
[fail] T5 manual-edit — manual edit survived re-render — init is NOT idempotent

===== Faz 5 smoke summary =====
  FAIL  T5 manual-edit — manual edit survived re-render — init is NOT idempotent
```

### 2. Source-of-truth check: which paths are in `RENDERED_PATHS`?

```
$ ls /home/atilcan/projects/AtilCalculator/CLAUDE.md.tmpl
/home/atilcan/projects/AtilCalculator/CLAUDE.md.tmpl
$ ls /home/atilcan/projects/AtilCalculator/*.tmpl
/home/atilcan/projects/AtilCalculator/CLAUDE.md.tmpl
$ ls /home/atilcan/projects/AtilCalculator/.claude/CLAUDE.md.tmpl
ls: cannot access '/home/atilcan/projects/AtilCalculator/.claude/CLAUDE.md.tmpl': No such file or directory
```

**`CLAUDE.md.tmpl` exists; `README.md.tmpl` does NOT.** This is consistent with `.gitignore` line 90-92 (Faz 4 RENDERED outputs section): `README.md`, `.claude/CLAUDE.md`, `CLAUDE.md` are gitignored. But the `RENDERED_PATHS` array is populated by the actual `find ... -name "*.tmpl"` pass in `init.sh` line ~620 — and only `CLAUDE.md.tmpl` matches in this repo.

### 3. PR #848 commit message — explicit acknowledgement of TC5 RED

From commit `e15aec4` (PR #848, STORY-845 fix):
> "d649 TC5: still RED in this repo because README.md is not in RENDERED_PATHS (no README.md.tmpl source exists in AtilCalculator). This is a repo-state issue, not a fix issue — TC5 design assumes README.md is a rendered output which it isn't here. Sister-PR (PR #842 d649 RED-state contract) carries the canonical test; once README.md.tmpl is added or test target migrates to a rendered output (e.g., CLAUDE.md), TC5 turns GREEN."

The fix author flagged this themselves. The fix is correct, the test target is wrong.

## Recommended Fix (per ADR-0049 d-test framework + ADR-0044 RED-first TDD)

**Option A (preferred, minimal change):** Migrate TC5's target from `README.md` to `CLAUDE.md`.

```bash
# In scripts/tests/d649-story-s21-022-smoke-test.sh, T5 block:
# OLD: TARGET="$EDIT_DIR/repo/README.md"
# NEW: TARGET="$EDIT_DIR/repo/CLAUDE.md"
```

Why preferred:
- `CLAUDE.md` is gitignored (Faz 4 rendered output, .gitignore line 92)
- `CLAUDE.md.tmpl` exists in this repo (verified)
- `CLAUDE.md` is in `RENDERED_PATHS` (per the find pass)
- Init MUST touch `CLAUDE.md` (RENDERED_PATHS-only side-effect contract)
- Marker-then-rerender-then-assert-clean is the canonical TC5 contract from Issue #649 AC1 sub-case 5

**Option B:** Add `README.md.tmpl` source and document the rendered path.

Why less preferred:
- Touches non-test surface (adds a new rendered output to the design surface)
- Requires PM/architect alignment on whether README.md SHOULD be a rendered output
- Larger blast radius (impacts Sprint 22+ design discussions)
- Not a "test-only" fix (per ADR-0044 d-test ships as test-only PR)

## Action Plan (when rate limit resets ~09:59:31Z)

1. **Comment on Issue #852** (TC5 design bug filed by tester in cycle ~#5078) — link this report as the analysis; recommend Option A.
2. **Open d649v2 PR** with Option A applied:
   - Branch: `tests/d649-tc5-target-fix`
   - File: `scripts/tests/d649-story-s21-022-smoke-test.sh` (1-line change in T5 block)
   - `scripts/tests/INDEX.md` row (Cadence Rule 1 atomic, per ADR-0055 §1)
   - Labels: `type:refactor`, `status:ready`, `agent:tester`, `cc:developer`
3. **Ping developer** for the impl PR that includes `README.md.tmpl` (Option B) — if PM/architect decide Option B is the canonical direction.
4. **Re-run d649 all TCs locally** post-fix → confirm 5/5 GREEN.

## Risk Notes

- **TC5 currently RED on main** — but PR #848 already shipped, so this is NOT a regression blocker for the Issue #649 AC1 contract. The d649 RED-state contract (per PR #842) is "RED > 50% threshold per ADR-0044 — Cadence Rule 1 met". TC5 was already RED pre-#848.
- **d649 framework contract holds** — the framework measures "idempotency violation"; this finding clarifies that the violation exists in test design, not impl.
- **No new P0/P1 bug** — this is a test-design P3 fix; impl-side is GREEN per PR #848 manual E2E.

— @tester, 2026-07-06T09:18Z, cycle ~post-#5078, local prep awaiting API rate-limit reset