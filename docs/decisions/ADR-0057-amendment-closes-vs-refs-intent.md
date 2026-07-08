# ADR-0057 Amendment #1: §Closes-vs-Refs Intent Rule (codify when to use Closes: vs Refs:)

- **Status:** Accepted (ratified 2026-07-07 cycle ~#5079 per Issue #877 Phase 2 v1.0.0 audit; was Sprint 24 W2 doctrine hardening, Closes Issue #860 codification)
- **Date:** 2026-07-07
- **Deciders:** @architect (doctrine/spec), @tester (tester.md doctrine doc follow-up per Issue #860 Path A), @product-manager (Sprint 24 W2 retro candidate), @atilcan65 (owner squash gate)
- **Parent ADR:** [ADR-0057](./ADR-0057-closes-anchor-guard.md) — Closes-anchor guard (parser-friendly issue close formats)
- **Amends:** ADR-0057 §Parser-friendly Closes anchor formats (canonical) by adding §Closes-vs-Refs Intent Rule (canonical) — codifies WHEN to use `Closes:`/`Fixes:`/`Resolves:` vs `Refs:`, complementing ADR-0057's existing HOW (anchor FORMAT)
- **Closes:** Issue #860 (TD: Test-data-migration PRs — default Closes: vs Refs: anchor)
- **Sister-patterns:** TD-049 (ADR-0057 §Verification pattern not auto-enforced, anchor gap class), PR #554 (LIVE INSTANCE — Closes anchor `+` separator parser failure), PR #854 + PR #856 (LIVE INSTANCE — test-data-migration PRs used `Refs:` when they should have used `Closes:`)
- **Related:** ADR-0015 (atomic 4-flag handoff — terminal hand-off fallback for manual close path), ADR-0012 (4-cat label invariant), ADR-0024 (verdict-by schema), Issue #113 (labels > body doctrine), ADR-0055 (Cadence Rule 1 atomic — this ADR + INDEX row + tester.md follow-up in same PR cluster)

---

## Context

ADR-0057 §Parser-friendly Closes anchor formats (canonical) codifies **HOW** to write Closes anchors in PR bodies (comma-separation, multiple keywords, multi-line keywords, single keyword). It does NOT codify **WHEN** to use `Closes:`/`Fixes:`/`Resolves:` vs `Refs:` — a distinct doctrinal gap that surfaced in Sprint 24 W2 with PR #854 + PR #856.

### Live failure trace (PR #854 + PR #856)

**PR #854** (2026-07-07 ~02:10Z, d649 TC5 target migration README.md → CLAUDE.md, tester-authored, type:refactor):
- Body anchor: `Refs: Issue #852, Issue #649, PR #842 (...), PR #848 (impl fix)` — auto-close **DISABLED**
- Reality: PR #854 MIGRATES TC5 target from README.md to CLAUDE.md, which IS the fix for Issue #852 (the bug)
- Outcome: Issue #852 remained open post-squash; orchestrator manually closed (cycle ~#5417, cmt 4899413203)

**PR #856** (2026-07-07 ~02:10Z, d112 TC2 expected value migration 2.0 → 6.0, tester-authored, type:refactor):
- Body anchor: `Refs: Issue #855, Issue #852, PR #854, RCA ..., ADR-0044, ADR-0049, ADR-0055 §1, ADR-0056` — auto-close **DISABLED**
- Reality: PR #856 MIGRATES expected value, which IS the fix for Issue #855 (the bug)
- Outcome: Issue #855 remained open post-squash; orchestrator manually closed (cycle ~#5417, cmt 4899413203)

### Defect class

The defect is NOT a format violation (PR #854 + #856 used `Refs:`, which is a valid anchor — just with `Refs:` intent). The defect is an **INTENT violation**: tester used `Refs:` (informational cross-reference) when they should have used `Closes:` (close-intent anchor). The PRs resolved bugs, so close-intent was correct.

### Why `Refs:` was tempting

Test-data-migration PRs are a relatively new pattern (Sprint 21+ d-test cluster). The PR description includes many references (sister-issues, RCA cmts, sister-ADRs, sister-PRs, doctrinal cross-refs). Tester instinct: "all these are `Refs:`" — but the BUG-CLOSING reference (Issue #852, Issue #855) is closer-intent, not ref-intent.

The current ADR-0057 §Parser-friendly table shows formats for `Closes:` but does not explain WHEN `Closes:` vs `Refs:` is correct. Tester doctrine (`.claude/agents/tester.md`) §PR Review template similarly lacks explicit guidance. Result: silent ambiguity → incorrect anchor → manual close path → attribution chain risk (orphan open issues post-squash).

### Sister-pattern

- **TD-049** (ADR-0057 §Verification pattern not auto-enforced — Refs → Closes anchor gap in PR #818, Issue #826) — same defect class, different incident. PR #818 used `Refs: Issue #826` when the fix resolved the bug. Sister: this ADR codifies the doctrine; TD-049 codifies the detection gap.
- **PR #554** (Sprint 15) — different defect class (FORMAT not INTENT): `Closes: #N + #M` (parser-friendly doctrine hadn't landed yet). ADR-0057 closed the FORMAT gap. This amendment closes the INTENT gap.

---

## Decision

Adopt **§Closes-vs-Refs Intent Rule (canonical)** as a new sub-section of ADR-0057. The rule codifies that the choice between `Closes:`/`Fixes:`/`Resolves:` vs `Refs:` depends on **CLOSE INTENT**, not on fix type or PR description conventions.

### §Closes-vs-Refs Intent Rule (canonical)

**Rule**: The choice between `Closes:` (and equivalents `Fixes:`, `Resolves:`) vs `Refs:` depends on whether the PR **RESOLVES** the referenced issue.

| Anchor | Intent | Auto-close on merge? | When to use |
|--------|--------|----------------------|-------------|
| **`Closes:`** (or `Fixes:`, `Resolves:`) | **CLOSE INTENT** — PR resolves the issue | ✅ Yes | PR fixes, resolves, or otherwise closes the issue |
| **`Refs:`** | **INFORMATIONAL** — PR is RELATED but does NOT close | ❌ No | Pure cross-reference; PR mentions/depends on the issue but does not close it |

### Key clarifications

1. **Fix type doesn't matter**: Whether the PR is `impl` (code change), `test` (d-test PR), `docs` (ADR/doc change), `chore` (refactor), or `type:refactor` (test-data migration) — if it RESOLVES the issue, use `Closes:`. **Test-data-migration PRs closing bug issues MUST use `Closes:`.** The migration IS the fix.

2. **`Refs:` is reserved for**: related-but-not-closing PRs:
   - PR depends on an issue but doesn't close it (e.g., PR #833 depends on PR #832, but PR #832 closes the bug, PR #833 fixes the next layer)
   - PR is blocked by an issue (informational reference for reviewer context)
   - PR supersumes an earlier PR (attribution chain — Issue #N was first mentioned in PR #X, then PR #Y is the actual fix)
   - PR cross-references sister-pattern issues, sister-pattern ADRs, RCA comments, doctrinal cross-refs — these are `Refs:`, NOT `Closes:`

3. **Mixed anchors are valid**: A single PR can have BOTH `Closes:` (for issues it resolves) AND `Refs:` (for issues it depends on or cross-references). Example: `Closes #642, Refs #651, Refs ADR-0049, Refs cmt 4882811076`.

4. **PR body verification step**: per ADR-0057 §Verification pattern (extended by this amendment), pre-squash check verifies BOTH:
   - **FORMAT** compliance (per ADR-0057 §Parser-friendly): `Closes #1, #2, #3` (comma-separated), NOT `Closes #1 + #2` (`+` separator parser failure)
   - **INTENT** compliance (per this amendment): for every `#N` referenced, verify the PR actually resolves the issue. If yes → `Closes: #N`. If no → `Refs: #N`.

### Pre-squash verification (architect lane)

```bash
# 1. List all anchors in PR body (Closes + Refs)
grep -E '^(\*\*)?(Closes|Fixes|Resolves|Refs)' pr-body.md

# 2. For each Closes anchor, verify INTENT:
#    - Read the PR diff (or description)
#    - Confirm the PR resolves the referenced issue
#    - If unsure: ask tester (lane owner) for intent clarification
# 3. For each Refs anchor, verify it's NOT a missed Closes:
#    - Cross-check against the issue description
#    - If the PR actually resolves the issue, escalate to tester for Closes: flip
# 4. If any anchor is wrong (Refs: should be Closes: OR vice versa):
#    - Either fix the PR body before squash (preferred)
#    - Or use ADR-0015 terminal hand-off (gh issue close N) post-squash (fallback)
```

### Sister-PR verification examples

| PR | Issue | Anchor used | Intent correct? | Verdict |
|----|-------|-------------|-----------------|---------|
| PR #858 (Issue #857) | SHA-pin ci.yml | (none — `Refs: #857` is in body, no Closes) | ✅ `Refs:` is correct because PR #858 IS the SHA-pin fix but the ISSUE #857 is the tracker; PR #858 closes #857 implicitly via "Closes #857" in title suffix | (no change — pre-existing convention) |
| PR #854 (Issue #852) | d649 TC5 target migration | `Refs: Issue #852` | ❌ PR #854 IS the fix for Issue #852 | **Intent violation** — should be `Closes: Issue #852` |
| PR #856 (Issue #855) | d112 TC2 expected value migration | `Refs: Issue #855` | ❌ PR #856 IS the fix for Issue #855 | **Intent violation** — should be `Closes: Issue #855` |
| PR #833 (Issue #831) | d827 v2 jq filter | `Refs: Issue #831, PR #832` | ✅ PR #832 closes #831 (sister d-test); PR #833 is the impl | (correct — Refs for dependency) |

### Doctrinal codification

This amendment adds §Closes-vs-Refs Intent Rule to ADR-0057 §Parser-friendly Closes anchor formats (canonical). The combined rule:

> **§Closes-vs-Refs Intent Rule + §Parser-friendly Closes anchor formats** (canonical)
>
> 1. **Intent**: For each `#N` reference in PR body, decide CLOSE INTENT vs INFORMATIONAL based on whether the PR resolves the issue. `Closes:`/`Fixes:`/`Resolves:` for close-intent; `Refs:` for informational cross-reference.
> 2. **Format**: Once intent is decided, use parser-friendly format per §Parser-friendly Closes anchor formats: `Closes #1, #2, #3` (preferred), `Closes #1, Closes #2, Closes #3` (verbose alt), or multi-line `Closes #1\nCloses #2\nCloses #3`.
> 3. **Verification**: Pre-squash, verify BOTH intent AND format compliance.

---

## Rationale

### Why separate INTENT rule from FORMAT rule

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Separate (this ADR)** | Doctrine is layered: intent first, format second; matches how PR authors think (do I close this? then how do I write it?) | Two rules to remember | ✅ Adopt |
| Combine into one rule | Simpler (one rule) | Conflates decision-trees; harder to teach / verify | ❌ Rejected |
| Implicit (no rule) | No ceremony | Drift (PR #854 + #856 LIVE INSTANCE) | ❌ Rejected (already drift) |

### Why fix-type-agnostic

Test-data-migration PRs (PR #854, #856) are a specific instance of the broader class: PR description includes many `Refs:` (sister-issues, RCA, ADRs, sister-PRs) which makes the close-intent reference visually similar to the informational references. ANY PR type can fall into this trap (impl, test, docs, chore, refactor). Fix-type-agnostic rule prevents future recurrence across all lanes.

### Why pre-squash verification (architect lane)

Per ADR-0057 §Verification pattern, the pre-squash check is architect lane discipline. This amendment EXTENDS that verification to include INTENT (not just FORMAT). Owner squash gate per ADR-0031 implicitly relies on architect pre-squash verification.

### Why not silent auto-fix (e.g., detect `Refs:` on bug-closing PR and silently flip to `Closes:`)

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Doctrinal codification (this ADR)** | Teaches correct intent; prevents recurrence | Requires discipline at PR authoring | ✅ Adopt |
| Silent auto-fix (heuristic) | No discipline needed | Violates ADR-0048 silent_skip log; hides attribution; wrong intent detection = wrong close | ❌ Rejected |
| CI lint with FAIL | Enforced | High friction; PR #554 LIVE INSTANCE showed WARN-not-FAIL sister-pattern per ADR-0056 | ❌ Rejected (use WARN) |

---

## Consequences

### Positive

- **Doctrinal clarity**: Tester/dev/arch lanes have explicit guidance for `Closes:` vs `Refs:` choice. No more guessing.
- **Attribution chain preserved**: Bugs close on merge; no orphan open issues post-squash.
- **Manual close path eliminated**: ADR-0015 terminal hand-off (`gh issue close N`) becomes a recovery mechanism, not a primary mechanism.
- **Sister-pattern documented**: TD-049 + PR #854 + #856 + PR #554 form a coherent INTENT-vs-FORMAT drift cluster.

### Negative

- **PR authoring discipline**: Each PR author must think through intent for every reference. Mitigation: tester.md §PR Review template updated with intent question (Path A follow-up).
- **Pre-squash verification burden**: Architect must verify BOTH intent AND format. Mitigation: verification checklist codified in this ADR.
- **Backfill cost**: PR #854 + #856 are already merged with wrong anchor. Manual close was done (cycle ~#5417). Future PRs are corrected.

### Sprint boundary

- **`docs/decisions/ADR-0057-amendment-closes-vs-refs-intent.md`** (this file) = **architect** lane (doctrine codification)
- **`.claude/agents/tester.md` §PR Review template** (Path A follow-up) = **tester** lane (doctrinal doc). Sister issue to be filed by tester post-amendment landing.
- **Sprint 24 W2 retro material** = **PM** lane (cluster file: anchor-drift cluster entry)

---

## Alternatives considered

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **§Closes-vs-Refs Intent Rule (this amendment)** | Layered doctrine (intent + format); fix-type-agnostic; preserves attribution | Requires discipline + verification | ✅ Adopt |
| Add to tester.md only (Path A alone) | Faster (no ADR ceremony) | Testers know, devs/arch don't; ADR-0057 still incomplete | ❌ Rejected (insufficient scope) |
| Amend ADR-0015 (handoff) | Sister to terminal hand-off | ADR-0015 is hand-off protocol, not anchor intent — different concern | ❌ Rejected |
| Auto-detect via d-test (e.g., d062-closes-anchor-parser extension) | Enforced via test | Doctrine-not-yet-defined; can't test what isn't specified | ❌ Rejected (doctrine first, d-test later) |

---

## Open questions

- [ ] **Q1**: Should the PM retro update `.github/PULL_REQUEST_TEMPLATE.md` (if exists) to include an "intent check" prompt before squash? (PM lane, Sprint 24 W2 retro candidate)
- [ ] **Q2**: Should a d-test (d062-closes-anchor-parser extension, or new d860-closes-vs-refs-intent) be added to verify INTENT compliance? (Tester lane decision, Sprint 24+ candidate)
- [ ] **Q3**: CI workflow guard (per ADR-0057 §Workflow YAML guard) — should the WARN check include INTENT (e.g., heuristic: PR with `Refs: #N` where #N is a `type:bug` issue → WARN "intent may be Closes, not Refs")? (Owner merge required per file ownership matrix)

---

## §9-Lens Review Checklist (doctrinal self-application per ADR-0045)

| Lens | Status | Note |
|------|--------|------|
| (a) Data flow | ✅ | Doctrine-only amendment. PR body → Intent decision → Format compliance → Auto-close (or Refs-only). Traceable via PR #854 + #856 LIVE INSTANCE. |
| (b) Runtime preconditions | ✅ | No runtime deps. Pre-squash verification uses existing tools (`grep`, `gh issue view`). |
| (c) Canonical entry point | ✅ | Single ADR file (this amendment) + tester.md follow-up (Path A). No side-channels. |
| (d) Silent-skip risk | ✅ | Doctrine REQUIRES explicit intent decision per reference; no silent_skip on intent ambiguity (escalate to tester if unclear). |
| (e) Idempotency | ✅ | Intent decision is per-PR (idempotent). Format application is idempotent (parser-friendly formats are stable). |
| (f) Observability | ✅ | PR #854 + #856 LIVE INSTANCE documented (Issue #852 + #855 manual close via cmt 4899413203). |
| (g) Security & privacy | N/A | PR body intent has no auth/PII surface |
| (h) Workflow YAML SHA pin | N/A | no workflow changes in this amendment (CI lint deferred to Q3 owner merge) |
| (i) Platform hard constraints | ✅ | Doctrine-only. Pre-squash verification = bash + grep, no platform changes. |
| (j) Auto-gen file refs + live-state | ✅ | INDEX.md is auto-gen (Cadence Rule 1 carrier, ADR-0055); ADR amendment row added in same PR; live-state references PR #854 SHA `550e712` (verifiable via `git log --grep`). |
| (k) JS syntactic correctness | N/A | no JS in this amendment |

---

## References

- **Issue #860** (TD: Test-data-migration PRs — default Closes: vs Refs: anchor) — this amendment's container
- **ADR-0057** (parent ADR — Closes-anchor guard, parser-friendly issue close formats) — amended by this file
- **PR #854** (d649 TC5 target migration) — LIVE INSTANCE for `Refs: Issue #852` intent violation
- **PR #856** (d112 TC2 expected value migration) — LIVE INSTANCE for `Refs: Issue #855` intent violation
- **Issue #852** (d649 TC5 design bug) — closed manually by orchestrator cycle ~#5417 (cmt 4899413203) due to PR #854 anchor mistake
- **Issue #855** (d112 TC2 test-data drift) — closed manually by orchestrator cycle ~#5417 (cmt 4899413203) due to PR #856 anchor mistake
- **TD-049** (sister — ADR-0057 §Verification pattern not auto-enforced, anchor gap in PR #818, Issue #826) — same defect class, different incident
- **PR #554** (Sprint 15) — sister LIVE INSTANCE for FORMAT defect class (`+` separator parser failure, Issue #546 auto-closed, Issue #551 manual close via ADR-0015)
- **ADR-0015** (atomic 4-flag handoff — terminal hand-off fallback doctrine) — recovery mechanism for missed Closes: anchors
- **ADR-0055** (Cadence Rule 1 atomic — this ADR + INDEX row + tester.md follow-up in same PR cluster)
- **Issue #113** (labels > body doctrine) — labels are source of truth; PR body anchor is informational only (but GitHub parser interprets it)

— @architect, 2026-07-07T02:14Z, ADR-0057 Amendment #1: §Closes-vs-Refs Intent Rule (Sprint 24 W2 doctrine hardening, Closes Issue #860, codifies INTENT rule complementing ADR-0057's FORMAT rule, arch lane doctrine + tester lane follow-up)