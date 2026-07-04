# Cycle ~#3472 — 🚨 ARCH NEEDS CHANGES: PR #784 (7 broken ADR links + 3 🟡) — fix-up complete

> **Date**: 2026-07-03 (cycle ~#3472, post-ARCH-wake 18:42:40Z)
> **Author**: @product-manager
> **Status**: ✅ FIX-UP SHIPPED — 7 broken ADR filenames corrected + 3 suggestions applied, re-pinged architect
> **Issue**: PR #784 cycle state: NEEDS CHANGES → fix-up ready
> **Source wake**: dual-channel `notify.sh -w -r product-manager` ARCH cycle ~#3472

---

## ARCH feedback (cycle ~#3472)

Architect comment 4878693545 on PR #784: **NEEDS CHANGES**

### 🟢 OK (4-gate structure sound)
- Gate 1 PR template accurate
- Gate 2 ADR requirement correct scope
- Gate 3 d-test sister-pattern correct boundary
- Gate 4 owner squash gate correct (per ADR-0031)
- CODEOWNERS excerpt (4 lines) matches live state ✓

### 🔴 BLOCK (7 broken ADR links)

**All 7 ADR cross-refs in CONTRIBUTING.md pointed to NON-EXISTENT filenames**. Markdown-lint would fail.

| Cited (broken) | Actual (per INDEX.md) |
|---|---|
| `ADR-0012-4-cat-label-invariant.md` | `ADR-0012-required-label-set.md` |
| `ADR-0015-atomic-4-flag-hand-off.md` | `ADR-0015-atomic-agent-handoff.md` |
| `ADR-0031-owner-merge-gate.md` | `ADR-0031-owner-override-doctrine.md` |
| `ADR-0044-red-first-tdd.md` | `ADR-0044-verdict-by-scope-clarification.md` |
| `ADR-0045-9-lens-pre-publish.md` | `ADR-0045-auto-generated-file-refs-design-verification.md` |
| `ADR-0049-d-test-framework.md` | `ADR-0049-behavioral-workflow-test-framework.md` |
| `ADR-0057-closes-anchor-strict-format.md` | `ADR-0057-closes-anchor-guard.md` |

**Architect insight on grep coverage gap**:
> The PR W2 pre-PR grep was clean only because the regex ignores paths starting with docs/ (3-char prefix). Grep coverage gap: `test_markdown_lint::test_all_internal_links_resolve` catches these via full-tree resolve, but the local pre-PR grep does not.

Sister-pattern to PR #783 W2 cycle ~#3466: local pre-PR grep has coverage gaps. The full markdown-lint CI check is the authoritative one.

### 🟡 Suggestion 1 — Gate 2 "process contract" criterion testable

Architect recommended:
> "Any PR that adds/modifies a rule documented in an existing ADR (label discipline, auto-ping, autonomy loop, etc.) MUST cite the affected ADR in its PR body — per ADR cross-ref table in PR template."

This makes the criterion testable and points to PR template as canonical list.

### 🟡 Suggestion 2 — Gate 3 ADR-0064 hyperlink

ADR-0064 was squash-merged 2026-07-03 (PR #773). Adding hyperlink to Gate 3 sister-pattern list.

### 🟡 Suggestion 3 — Out-of-scope engine module

Both `pyproject.toml [tool.ruff]` + `mypy --strict` are forward-looking (engine module deferred per ADR-0017 §Deferred). Note as engine lands.

### 9-Lens attestation per architect

- (a) Data flow: N/A (pure docs)
- (b) Runtime preconditions: N/A
- (c) Canonical entry point: single doc ✓
- (d) Silent-skip risk: N/A
- (e) Idempotency: N/A
- (f) Observability: N/A
- (g) Security & privacy: CODEOWNERS routing only ✓
- (h) Workflow YAML SHA pin: N/A
- (i) Platform hard constraints: N/A
- **(j) Auto-gen file refs + live-state [ADR-0045]: VERIFIED** ✓

---

## PM fix-up actions (cycle ~#3472)

### Action 1: Fix all 7 ADR filenames (commit 965de5c)

Single commit replaced all 7 broken filenames with canonical from INDEX.md. Verified via:
- `grep -E "ADR-(0012-4|0015-4|0031-merge|0044-red|0045-9-lens|0049-d-test|0057-strict)" CONTRIBUTING.md` → 0 (all old names purged)
- `grep -cE "ADR-(0012-required|0015-atomic|0031-owner-override|0044-verdict-by|0045-auto-gen|0049-behavioral|0057-closes-anchor|0064-cross-user)" CONTRIBUTING.md` → 16 (all new names present)

### Action 2: Address 3 architect suggestions

| Suggestion | Application |
|---|---|
| 🟡 #1 Gate 2 testable | Removed "Any file that changes a process contract" line. Replaced with "PR must cite the affected ADR in PR body ADR cross-ref table". Added ADR-0043 (8-lens base) + ADR-0054 (9th lens enforcement) for full 9-Lens context. |
| 🟡 #2 ADR-0064 hyperlink | Added `docs/decisions/ADR-0064-cross-user-env-var-pattern.md` to Gate 3 sister-pattern list. Also added ADR-0050 (pre-merge 4-cat verification) as additional example. |
| 🟡 #3 Engine module deferred | Replaced "mypy --strict for engine module" with ADR-0017 §Deferred cross-ref. Noted engine doesn't exist yet; lint/typecheck guides apply only to `tests/` scaffolding. |

### Action 3: Side-effect discovery — ADR title vs concept

Architect cmt revealed that ADR-0044 actually describes **verdict-by SLA scope clarification** (not RED-first TDD as PM had assumed). The wrong citation was caught by the lens (j) live-state check.

PM had written: "Tests must fail BEFORE the change is applied (RED-first per ADR-0044)".
Correct interpretation: ADR-0044 §TDD RED exclusion clarifies which sub-states are exempt from verdict-by SLA — it's a verdict-by doctrine ADR, not a TDD methodology ADR.

Fix: Removed the conceptual mismatch. ADR-0044 now correctly cited in Gate 4 verdict-by exclusion context, not Gate 3 TDD methodology.

### Action 4: W2 pre-PR grep re-verified

`grep -nE '\]\(\./|\]\(\.\./' CONTRIBUTING.md` → 0 matches. Clean.

### Action 5: Commit + push + re-ping

- Commit: `965de5c docs: STORY-S21-021 CONTRIBUTING.md — fix 7 broken ADR links + 3 architect suggestions (PR #784 review)`
- Diffstat: CONTRIBUTING.md 24 insertions, 21 deletions (45 net line changes)
- Push: `b5a2283..965de5c pm/sprint-24-story-648-contributing-md`
- Architect re-ping: `[PM→ARCH] PR #784 fix-up ready`
- PR #784 comment: id 4878713585 with full fix matrix

---

## Lessons captured (cycle ~#3472)

### Lesson 1: ADR filenames must be verified against INDEX.md

PM had used "intuitive" filenames (e.g., `9-lens-pre-publish`, `red-first-tdd`, `d-test-framework`) based on common patterns. The actual filenames are determined by INDEX.md — the canonical reference.

**Future heuristic**: When writing ADR cross-refs, ALWAYS copy the exact filename from INDEX.md (or `ls docs/decisions/ | grep ADR-NNNN`). Never assume.

### Lesson 2: ADR titles ≠ concepts assumed by PM

PM had assumed ADR-0045 was "9-Lens Pre-Publish Gate" — actually it's "lens (j) Auto-Generated File Refs Verification". The 9-Lens framework is distributed across:
- ADR-0043 (8-lens base)
- ADR-0054 (9th lens enforcement)
- ADR-0045 (lens j specifically)

**Future heuristic**: When summarizing an ADR in a doc, read the actual `# ADR-NNNN` title line, don't guess from context.

### Lesson 3: Local pre-PR grep has coverage gaps

The W2 grep `grep -nE '\]\(\./|\]\(\.\./'` ignores 3-char prefixes like `docs/`, so it misses `docs/decisions/ADR-*.md` patterns. The CI `test_markdown_lint::test_all_internal_links_resolve` is the authoritative check.

**Future heuristic**: Don't rely solely on local W2 grep. Either:
1. Run the actual CI lint locally before push (if available)
2. Manually verify every relative link points to an existing file
3. Use absolute GitHub URLs (immune to renames)

### Lesson 4: W2 grep is local-only heuristic, CI is authoritative

Sister-pattern to PR #783 W2 cycle ~#3466. Both relied on the local grep; both missed broken links caught only by CI. The architect's lens (j) check is what caught PR #784's 7 broken links.

**Future pattern**: When architect finds broken links via 9-Lens lens (j), use that as the canonical source-of-truth over local heuristics.

---

## PM queue state (cycle ~#3472 close)

**WIP**: 2/2 (unchanged — Issue #648 + Issue #653 both in-progress)

**Issue #648**: PR #784 fix-up shipped, awaiting architect re-review verdict
**Issue #653**: auto-claimed cycle ~#3471, no work yet (waiting for slot to start)

**agent:product-manager queue**: 2 items (Issue #648, Issue #653)
**cc:product-manager queue**: 3 items (above + Issue #767)

## Next PM actions (cycle ~#3473+)

1. **Wait for architect re-review** on PR #784 (re-pinged cycle ~#3472)
2. **Address any further architect suggestions** (apply, push, re-ping loop)
3. **Start Issue #653 work** analysis — flesh out Fresh-Clone Validation scope (3sp, P2)
4. **Monitor PR #783 W2 fix** (dev lane, awareness only)

## Cross-refs

- **PR #784** (draft, NEEDS CHANGES → fix-up shipped)
- **Architect cmt 4878693545** (NEEDS CHANGES, cycle ~#3472)
- **PR #784 fix comment 4878713585** (cycle ~#3472)
- **docs/decisions/INDEX.md** (canonical ADR list)
- **ADR-0045** lens (j) Auto-Generated File Refs Verification
- **ADR-0044** Verdict-By:* SLA Scope Clarification (NOT RED-first TDD)
- **ADR-0064** Cross-User Env Var Pattern (Gate 3 sister-pattern)
- **Issue #648** (this story, PR #784 in flight)
- **Issue #653** (auto-claimed cycle ~#3471)

## PM-STATUS

```
Stories drafted: 1 (STORY-S21-021 → PR #784 NEEDS CHANGES → fix-up shipped)
Stories blocked: 0
Open questions: 0
Backlog health: Yellow (architect needs-changes applies to PM work product, recovery path defined)
Heartbeat: OK
WIP: 2/2 cap (Issue #648 + Issue #653)
```

---

Co-Authored-By: Claude <noreply@anthropic.com>