# Test Plan: TD-067c Open-Time Label-Strip Diagnostic (Sprint 26 carryover S25-002)

## Scope
- **In scope**: d-test coverage for the TD-067c Layer 7 open-time diagnostic in `.github/workflows/label-check.yml` (sister-pattern to TD-067b Layer 6 closed-event diagnostic).
- **Out of scope**: Implementation of the diagnostic itself (developer lane STORY-S25-001), issue-surface observability bonus (STORY-S25-003 deferred), root-cause confirmation of strip mechanism (Sprint 27+ investigation track per design §Open questions Q3).

## Doctrinal home

- **Issue #931** — TD-067c P1 sister-finding from PR #928 (live instance: PR #933 `cc:product-manager` + `cc:tester` stripped between 12:32Z and 12:40:53Z)
- **Issue #941** — Sprint 26 Kickoff umbrella (refers cmt 4927095731 phantom ref)
- **Issue #927** — TD-067b Part 2 parent issue (squash @ 4975c22)
- **PR #938** — TD-067b Part 2 IMPL (Layer 6 closed-event diagnostic, sister-pattern)
- **PR #946** — TD-067c design contract (arch-authored, in review, needs-architect-review label set)
- **docs/designs/TD-067c-open-time-design.md** — canonical design contract (parser-readable YAML companion to PR #946)
- **docs/decisions/ADR-0071-td-067c-open-diagnostic.md** — ADR (proposed, awaits approval with PR #946)
- **STORY-S25-002** — backlog entry (1.5sp, tester, P1, Sprint 25+ Wave 1 carryover → Sprint 26)
- **Issue #943** — Sprint 26 d-test gap-closure tracking issue (umbrella, includes S25-002 as one tracked scope row)

## Acceptance criteria

**AC1** — d-test at `scripts/tests/d067c-open-time-label-strip.sh` (NEW) with **9 TCs per ADR-0049 ≥5 baseline + dev review additions**:
- **TC1**: `pull_request` (NOT `pull_request_target`) trigger with `opened|reopened` types — open-time entry point per ADR-0044 RED-first + design §AC1
- **TC2**: `issues: [opened, reopened, labeled, unlabeled]` trigger preserved (baseline non-regression + surface unification)
- **TC3**: `pull_request: synchronize` (push) trigger — R2 false-positive gate precursor per design §R2 mitigation
- **TC4**: `<!-- adr-0071-open-diagnostic -->` comment marker present (idempotency dedup, sister to TD-067b's `<!-- adr-0070-closed-diagnostic -->`) + closed-diagnostic preserved (sister non-regression)
- **TC5**: Maintainer actor check — `atilcan65` + `github-actions[bot]` info-downgrade per design §R3 mitigation (dev review TC5 + TC8 — both actor classes distinct)
- **TC6**: Synchronize no-op diff-gate sentinel — step-level `if: synchronize` + diff-comparison logic (no comment when diff preserves 4-cat, comment when diff breaks 4-cat)
- **TC7**: Concurrency group parameterized for PR + Issue surfaces (`pull_request.number || issue.number` per design §Concurrency group design R1 mitigation, arch review cmt 4927052273 clarification #1)
- **TC8**: SHA-pinning preserved on all `actions/*` usages (full 40-char hex after `@` per ADR-0027 + ADR-0043 §lens h)
- **TC9**: Open-time 4-cat baseline check — `status !== done` (NOT-done check, sister-distinguishing from Layer 6's `== done`) + `agent/cc` PRESENCE check (sister-distinguishing from Layer 6's ABSENCE check) per design §Data model

**AC2** — d-test REFERENCES d-test INDEX.md entry with Cadence Rule 1 atomic (ADR-0055 §1).

**AC3** — d-test covers all 4 known instances from Issue #931 §Evidence stack:
- Instance 1: Issue #927 (agent + 4 cc labels stripped during PR #926 merge window) — covered by Layer 6 (TD-067b, already shipped); regression guard preserved in TC4.
- Instance 2: PR #928 (cc:product-manager stripped during OPEN review window) — covered by TC5 (open-time trigger catches open-state strip).
- Instance 3: PR #933 (cc:product-manager + cc:tester stripped between 12:32Z and 12:40:53Z) — covered by TC5 + TC9 (4-cat baseline check catches cc:label absence).
- Instance 4: Unstaged — covered by TC1+TC2 general triggers (any open-time event on PR or Issue surface).

**AC4** — d-test ships as PR with `agent:tester` + `cc:developer` + `cc:architect` + `cc:orchestrator` + `cc:human` (per ADR-0012 4-cat label invariant).

**AC5** — d-test runs in CI on PR open to `scripts/tests/d067c-*` and exits 0 on GREEN, non-zero on RED. Test result posted as PR check (CI integration deferred to follow-up PR per d058/d296/d320 CI integration sequencing pattern).

**AC6** — d-test runs RED on master pre-impl and GREEN post-impl per ADR-0044 RED-first TDD.

## Test case details

### TC1: pull_request open-time trigger
- **Setup**: Inspect `.github/workflows/label-check.yml` `on:` block
- **Method**: PyYAML parse + JSON roundtrip (per d068-td067-combined.sh sister pattern) → extract `pull_request.types` → verify `opened` AND `reopened` present
- **Expected pre-impl**: FAIL (workflow has only `pull_request_target: closed` for Layer 6; no `pull_request:` block)
- **Expected post-impl**: PASS (`pull_request: [opened, reopened, labeled, unlabeled, synchronize]` added)

### TC2: issues trigger surface unification
- **Setup**: Same parse flow → extract `issues.types`
- **Method**: Verify all 4 required types (`opened`, `reopened`, `labeled`, `unlabeled`) present
- **Expected pre-impl + post-impl**: PASS (already exists in workflow from initial ADR-0012 implementation; non-regression baseline)
- **Anti-pattern caught**: Removing issues trigger would regress Issue-surface unification (Issue #931 R1 design risk)

### TC3: pull_request synchronize trigger (R2 false-positive gate)
- **Setup**: Same parse flow → check `pull_request.types` for `synchronize`
- **Method**: grep `synchronize` in `pull_request.types` array
- **Expected pre-impl**: FAIL
- **Expected post-impl**: PASS (`synchronize` added; enables TC6 diff-gate entry)

### TC4: open-diagnostic marker + closed-diagnostic preservation
- **Setup**: Raw text grep on workflow body
- **Method**: `grep -E "adr-[0-9]+-open-diagnostic"` for presence, `grep -E "adr-[0-9]+-closed-diagnostic"` for sister non-regression
- **Expected pre-impl**: open-diagnostic FAIL, closed-diagnostic PASS
- **Expected post-impl**: Both PASS (impl adds `<!-- adr-0071-open-diagnostic -->` marker; Layer 6 marker preserved from PR #938)
- **Adversarial probe**: If impl accidentally uses `<!-- adr-0070-open-diagnostic -->` (typo: 0070 instead of 0071), TC4 still PASSes (regex is flexible to `adr-NNNN-open-diagnostic`). Sister-pattern intent: any unique marker per ADR.

### TC5: Maintainer actor info-downgrade (R3 mitigation)
- **Setup**: Raw text grep + word-boundary patterns to avoid URL/mention false positives
- **Method**: 
  - bot_check: `grep -qE "github-actions\[bot\]|github_actions_bot|'github-actions\.bot'"`
  - owner_check: `grep -qE "github\.actor\s*[!=]==\s*['\"]atilcan65['\"]|context\.payload\.sender.*atilcan65"` (NOT just `atilcan65` mention — that gives false-positive from URL refs)
- **Expected pre-impl**: FAIL (no actor check at all in workflow)
- **Expected post-impl**: PASS (impl adds `if (github.actor === 'github-actions[bot]' || github.actor === 'atilcan65')` check before 4-cat baseline)
- **Dev review notes (PR #946 cmt 4665103514)**: TC5 covers bot actor; owner actor gets its own coverage (TC8 in original numbering) since they're separate concerns (owner = sprint-planning authority, bot = automation-driven strip)

### TC6: Synchronize diff-gate sentinel (R2 mitigation)
- **Setup**: Raw text grep on workflow body
- **Method**: 
  - diff_gate_ok: `grep -qE "if:.*synchronize|action.*==.*synchronize"` for step-level if:
  - diff_compare_ok: `grep -qE "diff|labelDiff|labelsDiff|compareLabels|labels.*before|labels.*after"` for diff logic
- **Expected pre-impl**: FAIL (no synchronize handling at step level)
- **Expected post-impl**: PASS (impl adds synchronize-specific step with diff computation, fires deviation comment ONLY on 4-cat break)
- **Critical adversarial probe**: If impl drops the diff-comparison logic and fires comment on every push, TC6 FAILs ("comment noise spam"). d-test catches implementation shortcut.

### TC7: Concurrency group parameterized for PR + Issue (R1 mitigation)
- **Setup**: Raw text grep
- **Method**: 
  - has_concurrency: `grep -qE "^concurrency:|^\s+concurrency:"` for block presence
  - has_param: `grep -qE "pull_request\.number.*\|\|.*issue\.number"` for PR||Issue form
- **Expected pre-impl + post-impl**: PASS (already parameterized from PR #938 retrofit; non-regression baseline)
- **R1 risk caught**: If impl accidentally narrows concurrency group to PR-only, Issue events would serialize into single global queue (catastrophic bottleneck, 50+ issues firing sequentially)

### TC8: SHA-pinning preserved (ADR-0027 + ADR-0043 §lens h)
- **Setup**: grep workflow for `uses: actions/` lines
- **Method**: For each `uses:` line, verify `@[a-f0-9]{40}` (full 40-char SHA) — NOT moving tag like `@v7` or `@main`
- **Expected pre-impl + post-impl**: PASS (existing workflow pins `actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b`)
- **L8 governance**: Pre-PR grep attestation `grep -E 'uses:.*@(v[0-9]+|main|latest)$' .github/workflows/label-check.yml` returns empty

### TC9: Open-time 4-cat baseline (NOT-done + PRESENCE)
- **Setup**: Word-bounded raw text grep to avoid `success` → `ccess` false-positive trap
- **Method**:
  - has_not_done_status: `grep -qE "\bstatus\b\s*!==\s*['\"]done['\"]|!\s*===\s*['\"]done['\"]"`
  - has_presence_check: `grep -qE "\bagentLabels\.length|\bccLabels\.length|hasAgent\(|hasCc\("`
- **Expected pre-impl**: FAIL (Layer 6 has `statusLabels[0] !== 'status:done'` checking ABSENCE; Layer 7 needs NOT-done PRESENCE distinction)
- **Expected post-impl**: PASS (impl adds `if (statusLabel !== 'status:done') { ... validate agent/cc presence ... }` block)
- **Sister-distinguishing intent**: Layer 6 expects PR closed + labels cleaned (status:done present, agent/cc absent). Layer 7 expects PR open + labels present (status NOT-done, agent/cc present). TC9 catches accidental Layer 6 copy-paste.

## Adversarial probes

- **PR #933 sister-instance re-trigger**: Simulate the `cc:product-manager` + `cc:tester` strip → verify TC9 fires (4-cat baseline catches cc presence rule)
- **Owner actor fake reset**: Script-level attempt by `atilcan65` to strip labels during sprint planning → verify TC5 info-downgrade path (no comment spam)
- **Push event spam**: 50 consecutive `git push` to test PR → verify TC6 diff-gate (only 1 comment if any 4-cat break, not 50)
- **Issue event vs PR event concurrency**: Open 5 Issues + 5 PRs in parallel → verify TC7 parameterized concurrency (each issue/PR has independent group, not serialized into one global queue)
- **Bot auto-format action**: `github-actions[bot]` adds label via Probot → verify TC5 info-downgrade (no alarm on legitimate automation)
- **Mixed status:done + status:in-review**: Verify TC9 doesn't fire false-positive (already-merged PRs are Layer 6 scope, not Layer 7)

## Performance concerns

- **TC1+TC2+TC3 trigger parse**: O(N) PyYAML parse of 987-line workflow — ~50ms (acceptable)
- **TC4+TC5+TC6 grep**: O(N) text grep — ~10ms each
- **TC7 grep**: O(N) text grep — ~5ms
- **TC8 SHA validation**: O(M) where M = `uses:` lines count — ~5ms (typically M=10-20)
- **TC9 word-bounded grep**: O(N) text grep with regex — ~15ms
- **Total d-test runtime**: ~100-150ms (well within 5s budget per ADR-0049 framework policy)

## Regression risk

- **PR #938 squash @ 4975c22 (TD-067b Layer 6)**: TC4 verifies closed-diagnostic marker preserved
- **PR #932 squash @ 85b69e0 (TD-067b d-test, 7 TCs)**: sister-test pattern, no overlap with d067c (TD-067c handles open-time axis only)
- **PR #926 squash @ fb18c25 (TD-067 Part 1 TRANSIENT_REGEX narrowing)**: Sister-pattern in Issue #922, TC1+TC2 trigger changes may interact — verify TRANSIENT_REGEX still excludes auto-label events correctly post-Layer-7 addition
- **PR #938 concurrency-group retrofit**: TC7 verifies R1 mitigation preserved post-Layer-7 addition

## Sister-pattern lineage

| Cluster | PR | Sister to d067c |
|---|---|---|
| TD-067 Part 1 (TRANSIENT_REGEX narrowing) | PR #926 | parent fix (close-time) — TC1+TC2 trigger changes interact |
| TD-067b design (closed-diagnostic contract) | PR #928 | design contract (close-time) |
| TD-067b d-test (RED-first, 7 TCs) | PR #932 | d-test (close-time) — DIRECT structural-pattern sister |
| TD-067b Part 2 IMPL (Layer 6) | PR #938 | impl (close-time) — TC4 + TC7 verify non-regression |
| TD-067c design (open-diagnostic contract) | PR #946 | design contract (open-time) — this PR's primary dependency |
| **TD-067c d-test (RED-first, 9 TCs)** | **PR (this)** | **test RED-first (open-time)** |
| TD-067c IMPL (Layer 7) | PR (S25-001, dev lane, BLOCKED on this d-test per ADR-0044) | impl (open-time) |

## Cross-references

- **ADR-0012** — 4-cat invariant being protected (Layer 7 catch point)
- **ADR-0015** — atomic 4-flag handoff (sister-pattern consistency)
- **ADR-0027** — Deploy automation contract (SHA-pinning requirement)
- **ADR-0043** — §lens h workflow YAML SHA pin
- **ADR-0044** — RED-first TDD (tester d-test BEFORE impl lands)
- **ADR-0045** — 9-Lens pre-publish (all 10 lenses attested in design doc)
- **ADR-0049** — d-test framework, ≥5 TCs baseline (d067c = 9 TCs)
- **ADR-0055 §1** — Cadence Rule 1 atomic (d-test + INDEX entry same commit)
- **ADR-0057** — Closes vs Refs anchor intent rule
- **d068-td067-combined.sh** — direct sister d-test (closed-axis, 7 TCs, same workflow)
- **d127-td-067-transient-regex-preserve.sh** — TD-067 Part 1 TRANSIENT_REGEX sister
- **Issue #113** — label-authority (labels > body text; d067c is 4-cat complete via PR labels)

## Metrics of success

- **Leading**: d-test PR opens within 2 cycles of STORY-S25-002 spike completion
- **Lagging**: Zero label-strip open-time regressions observed post-merge (d-test catches all 4 instances from Issue #931 evidence stack, no manual fixes needed)
- **DoD (Sprint 26)**: TD-067c d-test GREEN + impl GREEN + no new P0/P1 bugs filed within 24h post-merge

## Sprint

Sprint 26 Wave 1 carryover from Sprint 25+ (STORY-S25-002)

## Priority

P1 (d-test coverage for P1 impl, dev impl PR BLOCKED on this per ADR-0044)

## Story points (proposed by PM, joint sizing TBD)

1.5sp — 9 TC definitions + structural pattern authoring + INDEX.md entry + CI wiring (ADR-0049 + ADR-0055 §1 + ADR-0044). Sister-pattern to d068-td067-combined.sh authoring (5sp, 7 TCs); d067c is lighter because dev already provided semantic TC contract from PR #946 design review.

— @tester, STORY-S25-002 d-test plan, 2026-07-09 (TDD RED-first per ADR-0044)
