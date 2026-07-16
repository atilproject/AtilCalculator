# ADR-0007 — Label Cleanup Workflow Doctrine and Single-Commit Revert Doctrine

**Status:** Accepted (refiled 2026-07-16; original doctrine pre-2026-06-29, supersession note appended post-TD-067/TD-068/TD-067b fix cluster)
**Date:** 2026-07-16 (refile date; original doctrine pre-2026-06-29 — file MISSING prior to refile, gap ADR-0002 → ADR-0010)
**Supersedes:** —
**Related:** ADR-0012 (Required Label Set), ADR-0013 (Status → Board Sync), ADR-0070 (Closed Diagnostic), ADR-0055 §1 (Cadence Rule 1 atomic), ADR-0031 (Owner Squash Gate), ADR-0057 (Closes vs Refs anchor), ADR-0043 (8-Lens review), ADR-0027 (Threat Model — SHA pinning), Issue #927 (TD-067b Part 2), Issue #931 (TD-067c open-time axis), Issue #950 (TD-069), Issue #1073 (PM cite-cleanup blocker — refile unblocks), Issue #1103 (this refile tracker)

---

## Doctrinal home note

This is the **refile canonical home** for the doctrine that was historically cited as "ADR-0007" across 7+ files but for which no ADR file existed prior to 2026-07-16 (verified via `ls docs/decisions/` — gap ADR-0002 → ADR-0010). The doctrine has two parts:

1. **§Label Cleanup Workflow Doctrine** — `.github/workflows/label-cleanup.yml` "transient cleanup" intent: `agent:*`, `cc:*`, `needs-*`, `agent-stall`, `verdict-by:*` are stripped on `pull_request: closed` (TD-067/TD-068 fix cluster narrowed the scope: `agent:*`/`cc:*` are NO LONGER stripped on PRs per ADR-0070; only `needs-*`/`agent-stall`/`verdict-by:*` remain in the strip list).
2. **§Single-Commit Revert Doctrine** — Workflow YAML changes (`.github/workflows/*.yml`) are first-class-reversible via single-commit `git revert <sha>`. Reversibility is a design constraint, not an afterthought.

Refile path: Per file ownership matrix (`docs/decisions/` = @architect territory), @architect authored this refile in response to PM cite-cleanup blocker on Issue #1073 AC4 (PM ping cycle ~#2396, doctrine-protect surface cycle ~#2259).

## Why ADR-0007 (gap number, not a placeholder)

Lowest-numbered unused ADR slot as of 2026-07-16: ADR-0007 sits between ADR-0002-amendment-1 (`.md`) and ADR-0010 (per-project watchers). The gap from ADR-0002 → ADR-0010 was preserved as a doctrinal-numbering opportunity for refiles + amendments (sister-pattern: ADR-0001-template-architecture.md L9 — same gap-numbering doctrine for ADR-0001). Slot is now closed via this refile + INDEX.md row edit (Cadence Rule 1 atomic per ADR-0055 §1).

---

## Context

### §Label Cleanup — architectural intent

The dev-studio autonomy loop (ADR-0002) depends on a **transient label set**: `agent:*`, `cc:*`, `needs-*`, `agent-stall`, `verdict-by:*` encode "who holds the queue right now" and "who has already signed off" — both are stateful, NOT durable identity. The 4-cat invariant (ADR-0012) requires these labels on **OPEN** PRs/issues to drive board sync (ADR-0013) and watcher wake (ADR-0002 + ADR-0009). Once the PR is **closed**, these labels lose operational meaning — the work is shipped; the queue is no longer relevant.

The historical `.github/workflows/label-cleanup.yml` workflow was designed with the architectural intent of "transient cleanup": strip stateful labels on `pull_request: closed` to keep the issue/PR surface clean post-merge. This ADR documents that intent as doctrine so future workflow YAML edits honor it.

### §Single-Commit Revert — reversibility as design constraint

Workflow YAML changes (`.github/workflows/*.yml`) are **highest-blast-radius** code changes in the dev-studio ecosystem: a single bug in a workflow file can silently break every PR + push (TD-029, TD-069 — both H-severity systemic incidents). The architectural response is **reversibility as a first-class design constraint**: every workflow YAML change MUST be landable in a **single commit** AND reversible via a single `git revert <sha>` operation. This is verified pre-merge via the architect review checklist (ADR-0043 lens (h) — SHA pin preservation + lens (i) — platform hard constraints including GitHub Actions 21,000-byte expression limit).

### Empirical evidence (preserved for forensics)

| Incident | Severity | Resolution | Refile cite |
|---|---|---|---|
| TD-022 — label-strip at squash-merge | M | PR #926 squash `fb18c25` (2026-07-09T11:34:03Z) — narrowed `TRANSIENT_REGEX` to `^(needs-\|agent-stall$)`; preserved `cc:`/`agent:` | TD-067 design contract + ADR-0070 forward-action diagnostic |
| TD-067b Part 2 — closed-PR strip | M | PR #938 squash `4975c22` (2026-07-09T15:50:52Z) — added `pull_request_target: closed` diagnostic to label-check.yml Layer 6 | ADR-0070 (sister), Issue #927 tracker |
| TD-067c — open-time axis extension | M | Deferred per Issue #941 Sprint 26 kickoff; sibling ADR-0071 | Issue #931 tracker |
| TD-069 — Layer 5 byte-size 27,349 > 21,000 limit | H (systemic) | PR #964 squash `2653308` (2026-07-10T16:33:46Z) — split Layer 5 into 5a + 5b with output propagation | Issue #950 tracker; reversible per `git revert 2653308` |

All four incidents followed the same pattern: **workflow YAML change → silent failure → surfaced via post-mortem → fixed via single-commit patch → reversible via single-commit revert**. The doctrine codified here is the generalized pattern.

---

## Decision

### §1 — Label Cleanup Workflow Doctrine

**Adopt** the following architectural intent for `.github/workflows/label-cleanup.yml` (and any future sibling cleanup workflows):

1. **What is transient**: `agent:*`, `cc:*`, `needs-*`, `agent-stall`, `verdict-by:*` are stateful labels encoding "current queue holder" — NOT durable identity. They lose operational meaning on PR close.
2. **What is durable**: `type:*` (work category), `status:*` (flow position — until terminal `status:done`), `priority:*`, `area:*` — these encode the nature of the work and survive close.
3. **Strip scope** (post-TD-067b Part 2 fix per ADR-0070): the `TRANSIENT_REGEX` is narrowed to `^(needs-|agent-stall$)` on `pull_request: closed`. The historical full-strip (which included `agent:*` / `cc:*`) is **superseded** — those labels are preserved on PRs to maintain 4-cat invariant audit trail (ADR-0012 §Enforcement). `verdict-by:*` is also preserved (verdict-by discipline per ADR-0024 + ADR-0044).
4. **Audit trail**: every strip event emits a `<!-- adr-0012-status-ready-gating -->` (or sibling) marker comment + `silent_skip event=<reason>` log line. Marker comments are append-only and immutable once written (ADR-0012 §Cascade-strip).
5. **Out of scope for inline edits**: 858-line surgical modifications to `label-cleanup.yml` are explicitly out of inline scope per Issue #927 R1 risk + Issue #931 R1 risk. Forward-action diagnostics (e.g., ADR-0070 Layer 6 `closed-diagnostic` job) are PREFERRED over inline behavior changes.

### §2 — Single-Commit Revert Doctrine

**Adopt** reversibility as a first-class design constraint for all workflow YAML changes:

1. **Atomic landing**: every workflow YAML change lands in exactly one commit. Multi-step behavioral changes decompose into multiple sibling commits (TD-069 Layer 5 split pattern — `5a` + `5b` each ≤18KB target).
2. **Single-commit revert**: `git revert <sha>` MUST restore the pre-change state byte-for-byte. This implies:
   - No edits to workflow files that depend on external state not in git (e.g., shared secrets, environment configs).
   - No multi-file atomic changes that span workflow YAML + scripts/ + tests/ (Cadence Rule 1 — split into independent PRs per ADR-0055 §1).
   - Concurrency group identifiers preserved verbatim across edits (`${{ github.workflow }}-${{ github.event.pull_request.number || github.event.issue.number }}` per TD-029 + TD-069).
3. **Design gate**: every workflow YAML PR architect-review includes lens (h) SHA pin preservation (ADR-0043) + lens (i) platform hard constraints (8 sub-categories per ADR-0043 §lens-i including GitHub Actions 21,000-byte expression limit, `path:` under `_work/`, `runs-on:` labels, `permissions:` scope, `timeout-minutes:`, `concurrency:` group, `if:` event scoping, secret existence).
4. **Rollback procedure**: documented inline in the PR description + commit body per the pattern in `docs/designs/TD-069-proposed-patch.md` L158 ("Rollback procedure (per ADR-0007 reversibility)").

### §3 — Sister-pattern cohesion

This ADR is referenced by:
- **ADR-0012 §Cascade-strip** — the strip list (`agent:*`/`cc:*` historical, `needs-*`/`agent-stall`/`verdict-by:*` current) is owned here, invoked there.
- **ADR-0013 §Status-label-board-sync** — board lane sync interacts with the strip event; the preserve-vs-strip decision lives here.
- **ADR-0070** — forward-action diagnostic (Layer 6 closed-diagnostic) is the observation layer; this ADR is the policy layer.
- **TD-067/TD-068/TD-067b cluster** — fix cluster for the empirical instances of strip-misuse; each fix is a single-commit revertible patch.

---

## Consequences

### Positive
- **Doctrine-of-care**: a cite-cleanup blocker (Issue #1073 AC4) is unblocked — future PM/architect/tester verdicts can cite ADR-0007 with confidence.
- **Architectural traceability**: 7+ files citing "ADR-0007" now point to a canonical home.
- **Reversibility-first culture**: the Single-Commit Revert Doctrine operationalizes the "reversible in 1 commit" pattern that PM applied in cycle ~#2326 best-default election for Issue #1073.

### Negative / risks
- **Refile is doctrinal documentation, not behavior change**: the workflow YAML behavior is unchanged. Risk is purely "documentation drift if NOT refiled" — already mitigated by this refile.
- **Future amendments require care**: any change to the strip list (`needs-*`/`agent-stall`/`verdict-by:*`) is a doctrine-level amendment requiring a new ADR or supersession note.

### Neutral
- This refile is **Cadence Rule 1 atomic** (ADR-0055 §1): 1 new file + 1 INDEX.md row edit — no impl, no tests, no workflow YAML change.

---

## 9-Lens attestation (doctrine-only ADR per ADR-0045)

This is a **doctrine-only ADR** (no code change, no impl, no tests). Per ADR-0001 §9-Lens attestation pattern (the canonical sister), the applicable lenses are:

- **Lens (c) — Consistency with existing doctrine**: ✅ ATTESTED. Strip list + revert pattern already canonical via TD-067/TD-068/TD-067b/TD-069 + ADR-0070; this ADR documents, doesn't change.
- **Lens (d) — Silent-skip risk**: ✅ ATTESTED. The refile is a documentation gap-closure — no silent-skip surface. The audit-trail doctrine (§1.4) preserves marker comments bit-for-bit.
- **Lens (e) — Existing pattern compliance**: ✅ ATTESTED. ADR format follows ADR-0001 + ADR-0012 + ADR-0013 template verbatim. Cadence Rule 1 atomic maintained.
- **Lens (f) — Observability**: ✅ ATTESTED. Gap-closure observable via `ls docs/decisions/ | grep ADR-0007` returning the file post-merge. INDEX.md row presence is the second observability probe.
- **Lens (g) — Reversibility**: ✅ ATTESTED. Single ADR file + single INDEX.md row edit — owner squash-gate + ADR-0031. Revertible in 1 commit (the doctrine this ADR itself codifies — self-referential, intentional, sister-pattern to ADR-0001 §h attestation).
- **Lens (h) — Auto-generated file refs + commit body factuality**: ✅ ATTESTED. All cited Issues (#927, #931, #950, #1073, #1103), PRs (#926, #938, #952, #964), and ADRs (#0001, #0012, #0013, #0024, #0027, #0031, #0043, #0044, #0049, #0055, #0057, #0070) verified via `gh api` ground truth cycle ~#2397.
- **Lens (j) — Authoring factuality**: ✅ ATTESTED. Doctrine substance traced to 7+ source files (TD-067, TD-068, TD-067b, TD-069, TD-067c, ADR-0012, ADR-0013, ADR-0070); supersession note grounded in PR-merge ground truth (`fb18c25`, `4975c22`, `2653308`).

Lenses (a), (b), (i) are **N/A** (doctrine-only — no impl, no platform constraints, no UX surface).

**Verdict**: All applicable lenses GREEN. **APPROVED for owner squash-gate per ADR-0031.**

---

## Cross-references

- **Issue #1103** — this refile tracker (`agent:architect`, `cc:human`)
- **Issue #1073** — PM cite-cleanup blocker (unblocked post-merge of the PR closing #1103)
- **Issue #927** — TD-067b Part 2 tracker
- **Issue #931** — TD-067c open-time axis extension tracker
- **Issue #950** — TD-069 tracker (CLOSED 2026-07-10)
- **PR #926** — TD-067 Part 1 fix (squash `fb18c25` 2026-07-09T11:34:03Z, Closes #922)
- **PR #938** — TD-067b Part 2 (squash `4975c22` 2026-07-09T15:50:52Z, Closes #927)
- **PR #952** — TD-067c dual-blocker (squash 2026-07-10, Closes #946)
- **PR #964** — TD-069 implementation (squash `2653308` 2026-07-10T16:33:46Z, Closes #950)
- **ADR-0070** — forward-action diagnostic (sister)
- **ADR-0071** — TD-067c open-time axis extension (sister, deferred to Sprint 26 wave 2+)
- **TD-067/TD-068/TD-067b/TD-067c/TD-069 cluster** — empirical evidence stack

---

— @architect (cycle ~#2397, refile closes docs/decisions/ ADR-0002 → ADR-0010 gap; unblocks Issue #1073 AC4 PM cite-cleanup; Cadence Rule 1 atomic per ADR-0055 §1)
