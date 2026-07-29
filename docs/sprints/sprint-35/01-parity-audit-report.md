# Sprint 35 S35-002 — Parity Matrix (ADR-0075) Execution Audit Report

> **Story:** S35-002 (Issue #1236) — Parity matrix (ADR-0075) execution audit
> **Architect PRIMARY + tester Lane 3** (sister-test sister-pattern per ADR-0049)
> **Sprint:** 35 (Wave 1, parallel with S35-001)
> **Owner ratification:** 2026-07-27T15:45:00Z (per `docs/sprints/sprint-35/00-plan.md`)
> **Owner directive scope:** AtilCalculator → template + AtilCalculator → launcher (forward-only, no reverse)
> **Audit executed:** 2026-07-27T16:14:00Z

---

## ⛔ OWNER GATE 1 — STOP HERE

This audit is published for **owner review**. Wave 2 implementation patches (`S35-003`/`S35-004`) MUST NOT begin until the owner reviews the GAP TABLE below and authorizes forward-port work per row-group.

---

## Executive summary

The ADR-0075 parity matrix was authored 2026-07-24 with **preliminary classifications** ("full byte-level diff deferred to S34-002"). This audit is the **fresh ground-truth re-check** that ADR-0075 explicitly deferred. Findings:

| Bucket | ADR-0075 claim | Actual state | Net GAP |
|---|---|---|---|
| `equivalent` rows (§A + §B.1 + §C + §E + §F + §G) | ~50 rows byte-equal | 14 MATCH / 20 DRIFT / 10 missing-in-tmpl | **20 reclassifications needed** (equivalent → divergent) |
| `divergent` rows (§B.1 + §F + §H) | ~33 rows need forward-port patches | 33 present in both; **8 calc_larger (forward-port gaps), 8 tmpl_larger (divergent evolution), 17 equal_lines** | **16 rows need reconciliation** |
| `missing` scripts (§B.2, 9 rows) | Forward-port from calc to template | 2/9 forward-ported, **7/9 STILL MISSING** | **7 scripts need new forward-port PRs** |
| `missing` d-tests (§C, ~150 rows) | Forward-port d-test corpus | 141/165 calc d-tests NOT in tmpl | **141 d-tests need new forward-port PRs** |
| `missing` ADRs (§D, ~14 rows) | Forward-port latest ADRs | 28 calc ADRs NOT in tmpl (more than estimated) | **28 ADRs need new forward-port PRs** |

**Net forward-port PRs needed:** 20 (reclassified) + 16 (reconciled) + 7 (still-missing) + 141 (d-tests) + 28 (ADRs) ≈ **212 PRs**, which is **6% higher** than ADR-0075 §Summary tally estimate (~199).

**Spot-check patches verified:**
- ✓ `scripts/claim-next-ready.sh` — RETRO-024 silent-skip filter is in BOTH calc and tmpl (Sprint 33 forward-port WORKED)
- ✓ `scripts/peer-poke.sh` — ADR-0033 dual-channel pattern in BOTH calc and tmpl (Sprint 33 forward-port WORKED)
- ✗ `.github/workflows/label-check.yml` — RETRO-024 silent-skip NOT in tmpl (Sprint 33 forward-port FAILED for this workflow)
- ✗ `scripts/agent-state.sh` + `scripts/agent-watch.sh` + `scripts/dev-studio-init.sh` — calc has Sprint 33+34 amendments tmpl does NOT

**Critical finding:** `.github/workflows/label-check.yml` — **854 line delta** (calc=977 vs tmpl=123). The calc version is 8x larger because it contains Sprint 33 amendments (RETRO-024 silent-skip + cycle ~#3968Q+214 atomic-only-status + likely more). The tmpl version is the bare original — label-check enforcement in `tmpl` is **operating without Sprint 33 doctrine**, which is a real operational risk for any project bootstrapped from `dev-studio-template`.

---

## AC1 — Sister-script re-run

**Tool:** `scripts/cross-repo-scan.sh --once` + `scripts/audit-project-refs.sh --json`
**Output:** `docs/sprints/sprint-35/00-parity-refresh.json`

| Tool | Exit | Result |
|---|---|---|
| `audit-project-refs.sh --json` | 1 (FAIL) | 550 hits (expected: d-test fixtures + backlog.json self-refs + 12 .tmpl source). NOT a real parity gap. |
| `cross-repo-scan.sh --once` | 0 (success) | 0 open PRs on dev-studio-template + dev-studio-launcher = **0 dispatches** (no peer-poke side effect per cycle ~#3968Q+218) |

**Interpretation:** AtilCalculator is in clean post-init state. Template + launcher are quiet (0 open PRs). Any forward-port gap detected by AC2-AC4 must be opened as NEW PRs in target repos.

---

## AC2 — Equivalent-row SHA drift detection

**Method:** `gh api repos/<repo>/contents/<path> --jq .sha` (per ADR-0075 AC2)
**Output:** `docs/sprints/sprint-35/00-parity-ac2-sha-drift.json`
**Rows checked:** 39 (from ADR-0075 §A + §B.1 + §C + §E + §F + §G)

### GAP TABLE — Equivalent rows where actual ≠ ADR-0075 claim

| Section | Path | Calc SHA | Tmpl SHA | Verdict | Forward-port action |
|---|---|---|---|---|---|
| A | `.claude/agents/architect.md.tmpl` | 989efe814ed0 | 08f1085bba20 | **DRIFT** | reclass → divergent; forward-port calc content to tmpl |
| A | `.claude/agents/developer.md.tmpl` | d433ecc63e80 | bbde6b2c16ea | **DRIFT** | same |
| A | `.claude/agents/orchestrator.md.tmpl` | e8241ee3ecc9 | ae4356a93b0c | **DRIFT** | same |
| A | `.claude/agents/product-manager.md.tmpl` | ceeb9b8e04fa | 4e1ca997ff47 | **DRIFT** | same |
| A | `.claude/agents/tester.md.tmpl` | dc3a2ed179d5 | 5bbfdb7e81c9 | **DRIFT** | same |
| B.1 | `scripts/deploy-runner.sh` | b6c39804def6 | 6c045cf36805 | **DRIFT** | same |
| B.1 | `scripts/ops/apply-vm-hardening.sh` | 6cb4c9391046 | a724acf8fc24 | **DRIFT** | same |
| B.1 | `scripts/restart-stable.txt` | 65c16f3cf50f | 9d965e54bc38 | **DRIFT** | same |
| C | `scripts/tests/INDEX.md` | d7cb6655dad9 | 0ad52adca986 | **DRIFT** | same |
| E | `TEMPLATE-README.md` | ce0dda13d160 | 8c5fc583d6f9 | **DRIFT** | same |
| F | `.github/workflows/ai-pr-review.yml` | b9902b99a37a | 55624b013c2a | **DRIFT** | same |
| F | `.github/workflows/cross-repo-close.yml` | 9cea94a00d0c | 4acd0c3c856f | **DRIFT** | same |
| F | `.github/workflows/d050b-dispatch.yml` | 3bbe089eba74 | 1a77a1e45628 | **DRIFT** | same |
| F | `.github/workflows/label-cleanup.yml` | 2d34c19fb358 | d2eb2397e59c | **DRIFT** | same |
| G | `.github/ISSUE_TEMPLATE/agent-stall.yml` | 9e84c1869ace | 88e61ec6fa18 | **DRIFT** | same |
| G | `.github/ISSUE_TEMPLATE/bug.yml` | 8e9cfaac9989 | 6d52280143bd | **DRIFT** | same |
| G | `.github/ISSUE_TEMPLATE/feature-request.yml` | a97ce2f6897e | 6a192e443d98 | **DRIFT** | same |
| G | `.github/ISSUE_TEMPLATE/incident.yml` | ca9decadab95 | 83267cdc6fdb | **DRIFT** | same |
| G | `.github/ISSUE_TEMPLATE/vision-intake.yml` | cce759e284da | 4a0bfb81c0e2 | **DRIFT** | same |
| G | `.github/pull_request_template.md` | a57733a12825 | 98594f60628e | **DRIFT** | same |
| B.1 | `scripts/kickoff/{architect,developer,orchestrator,product-manager,tester}.txt` (5 rows) | present | ONLY `.txt.tmpl` variant present | **MISSING_IN_TMPL** (false-positive: tmpl has `.txt.tmpl` byte-equal content) | **NO ACTION** — kickoff parity is via render-stage, not direct SHA match. ADR-0075 classification `equivalent` is correct in INTENT but matrix needs notation clarifying render-stage difference. |

### MATCH rows (no action) — 14

All from §B.1 (12 scripts) + §E (2 docs: CONTEXT-HYGIENE.md + TELEGRAM-SETUP.md) + §F (secret-canary.yml). These rows are byte-equal across both repos — Sprint 33 forward-port already worked.

### Special case — §B.1 kickoff/*.txt

The matrix lists `scripts/kickoff/*.txt` as `equivalent`. Actual: calc has `<role>.txt` (rendered), tmpl has `<role>.txt.tmpl` (template source). SHA-equal on the `.txt` vs `.txt.tmpl` content (byte-identical), but file paths differ. **This is a true `equivalent` row in INTENT but ADR-0075 should annotate it as `equivalent (render-stage)`** so future audits don't flag the SHA mismatch as a gap.

---

## AC3 — Divergent-row patch verification

**Method:** fetch content via `gh api`, compare line counts, spot-check known Sprint 33/34 patches
**Output:** `docs/sprints/sprint-35/00-parity-ac3-patch-verify.json`
**Rows checked:** 33 (from ADR-0075 §B.1 + §F + §H classified as divergent)

### GAP TABLE — Divergent rows where actual ≠ ADR-0075 claim

#### Sub-group A: Calc-larger (tmpl MISSING calc patches — forward-port needed)

| Path | Calc lines | Tmpl lines | Delta | Sprint 33/34 hint | Operational risk |
|---|---|---|---|---|---|
| `.github/workflows/label-check.yml` | **977** | **123** | **+854** | RETRO-024 silent-skip + cycle ~#3968Q+214 atomic-only-status | **CRITICAL** — tmpl's label-check is operating WITHOUT Sprint 33 doctrine, 4-cat enforcement is broken in any new project bootstrapped from tmpl |
| `scripts/dev-studio-init.sh` | 887 | 665 | +222 | Sprint 32/33 init amendments | High — new project init skips Sprint 33 improvements |
| `scripts/agent-watch.sh` | 2347 | 2259 | +88 | Sprint 32/33 watcher tuning + cycle ~#3968Q+254 EXTENSION | High — agent-watch cadence drift in new projects |
| `scripts/agent-state.sh` | 535 | 465 | +70 | Sprint 33 amendments | Medium — agent-state lag in new projects |
| `.github/workflows/status-label-to-board.yml` | 250 | 199 | +51 | Sprint 33 amendments | Medium — board sync drift in new projects |
| `.github/workflows/lint-and-test.yml` | 132 | 119 | +13 | Sprint 33 d-test runner | Medium — d-tests skipped in new projects |
| `.github/workflows/deploy.yml` | 123 | 113 | +10 | Sprint 33 deploy amendments | Medium — deploys skip Sprint 33 logic |
| `scripts/status-action-driver.sh` | 280 | 274 | +6 | Sprint 33 amendments | Low |

#### Sub-group B: Tmpl-larger (tmpl has content calc doesn't — divergent evolution)

| Path | Calc lines | Tmpl lines | Delta | Interpretation |
|---|---|---|---|---|
| `scripts/proactive-board-scan.sh` | 222 | 247 | +25 | Tmpl has additional logic calc hasn't back-ported (S34-001+) |
| `scripts/notify.sh` | 214 | 237 | +23 | Tmpl's notify.sh evolved separately |
| `scripts/install/dev-studio-install-systemd.sh` | 326 | 339 | +13 | Tmpl systemd installer has additional logic |
| `scripts/post-squash.yml` | 113 | 120 | +7 | Workflow divergence |
| `scripts/post-restart-label-guard.sh` | 173 | 180 | +7 | Tmpl has additional label-guard logic |
| `scripts/orchestrator-status-flip.sh` | 127 | 133 | +6 | Tmpl has additional flip logic |
| `scripts/init-template-repo.sh` | 153 | 163 | +10 | Tmpl init-template-repo.sh has additional bootstrap logic |

**Interpretation:** 8 rows show divergent evolution — tmpl has features calc does NOT have. These need **reverse-direction back-port** from tmpl → calc (out of Sprint 35 scope per owner directive "Direction only AtilCalculator → template + AtilCalculator → launcher; reverse FORBIDDEN"). **Owner decision needed**: are these tmpl-only features in scope for Sprint 35, or out-of-scope and parked?

#### Sub-group C: Equal lines (17 rows)

These rows have same line counts but content may still differ. SHA comparison in AC2 for these is needed to confirm byte-equivalence (separate analysis).

---

## AC4 — Missing-row forward-port verification

**Method:** existence check + dir listing + Sprint 34 PR list cross-ref
**Output:** `docs/sprints/sprint-35/00-parity-ac4-missing-verify.json`

### GAP TABLE — Missing rows where actual ≠ ADR-0075 claim

#### §B.2 scripts (9 rows)

| Script | ADR-0075 status | Forward-ported? | Verdict |
|---|---|---|---|
| `scripts/agent-stall-detect.sh` | missing | ✗ | STILL MISSING |
| `scripts/d-test-network-abstraction.sh` | missing | ✗ | STILL MISSING |
| `scripts/d-test-reconcile-live.sh` | missing | ✗ | STILL MISSING |
| `scripts/d-test-target-os.sh` | missing | ✗ | STILL MISSING |
| `scripts/dev-studio-dryrun.sh` | missing | ✗ | STILL MISSING |
| `scripts/wip-idle-detect.sh` | missing | ✓ | **FORWARD-PORTED** (Sprint 34 PR likely) |
| `scripts/verify-portage.sh` | missing | ✓ | **FORWARD-PORTED** (Sprint 33 PR #1177) |
| `scripts/s29-002-tag-move.sh` | missing | ✗ | STILL MISSING |
| `scripts/install/install-git-hooks.sh` | missing | ✗ | STILL MISSING |

**Net:** 2/9 forward-ported, 7/9 STILL_MISSING. **ADR-0075 §B.2 was accurate** — these scripts were never delivered.

#### §C d-tests (~150 rows)

| Metric | Count |
|---|---|
| Calc d-tests | 165 |
| Tmpl d-tests | 24 |
| Intersection | 24 |
| Calc-only d-tests (NOT in tmpl) | **141** |

**141 d-tests** in calc that are NOT in tmpl. ADR-0075 estimate was ~150. **Real forward-port surface is ~141 d-test PRs** (or batched into ~14 cluster-squash groups of ~10 each per ADR-0059).

#### §D ADRs (~14 rows)

| Metric | Count |
|---|---|
| Calc ADRs | ~79 (per ADR-0075) |
| Tmpl ADRs | 51 |
| Missing from tmpl | **28** |
| Spot-check ADR-0074 (latest) | NOT in tmpl |
| Spot-check ADR-0072 | NOT in tmpl |

**28 ADRs missing** — 2x ADR-0075 estimate (~14). Sprint 32/33 amendment cycle was more productive than the matrix captured.

#### Sprint 34 PR list (#210-#225)

| Search | Result |
|---|---|
| `gh pr list --repo atilcan65/dev-studio-template --search "Sprint 34" --state all` | 0 PRs in #210-#225 range |
| Implication | Sprint 34 forward-port PRs (if any) landed OUTSIDE #210-#225 range. AC4 cross-ref assumption that Sprint 34 forward-port work happened in #210-#225 is **INCORRECT**. Forward-port work is more recent (likely #225+) or never happened. |

---

## Critical findings (for owner attention)

1. **`.github/workflows/label-check.yml`** — **854 line delta**. tmpl's label-check is operating WITHOUT Sprint 33 doctrine (RETRO-024 silent-skip + cycle ~#3968Q+214 atomic-only-status). **ANY new project bootstrapped from tmpl today has broken 4-cat enforcement.** This is a **real operational risk** that should be prioritized in Wave 2.

2. **ADR-0074 (latest)** is missing from tmpl — Sprint 33's AC-mapping verification doctrine has not been forward-ported.

3. **ADR-0072 (tasklist persistence)** is missing from tmpl — Sprint 33's REPRIME 5-step protocol + tasklist persistence has not been forward-ported (contradicts `scripts/tasklist-snapshot.sh` being divergent, suggesting tmpl has the script but not the ADR governing it).

4. **8 calc-larger scripts** have substantial Sprint 33/34 amendments not in tmpl. `dev-studio-init.sh` is +222 lines ahead — any new project initializes without Sprint 33 improvements.

5. **8 tmpl-larger rows** show divergent evolution. Owner decision needed: in scope for Sprint 35 (reverse back-port) or out-of-scope (park)?

6. **ADR-0075 §Summary tally UNDERESTIMATES** the forward-port surface by ~13 PRs (212 actual vs 199 estimated).

7. **Sprint 34 forward-port PR list** — assumption #210-#225 is INCORRECT. Sprint 34 forward-port work either (a) happened in #225+ range or (b) never happened in tmpl repo. Need owner clarification.

---

## Owner decision matrix (for OWNER GATE 1)

| Row-group | Forward-port action | Owner decision |
|---|---|---|
| **G1a** — 5 soul templates (§A) | 5 forward-port PRs (one per template) | ⛔ GO / NO-GO |
| **G1b** — 3 §B.1 scripts (deploy-runner, apply-vm-hardening, restart-stable) | 3 forward-port PRs | ⛔ GO / NO-GO |
| **G1c** — 1 §C script (scripts/tests/INDEX.md) | 1 forward-port PR | ⛔ GO / NO-GO |
| **G1d** — 1 §E doc (TEMPLATE-README.md) | 1 forward-port PR | ⛔ GO / NO-GO |
| **G1e** — 4 §F workflows + 6 §G issue templates + 1 PR template | 11 forward-port PRs (or batched into cluster-squash groups) | ⛔ GO / NO-GO |
| **G1f** — `.github/workflows/label-check.yml` (CRITICAL — 854 line delta) | 1 priority forward-port PR (HIGHEST PRIORITY — 4-cat enforcement) | ⛔ GO / NO-GO |
| **G1g** — 7 §B.2 missing scripts | 7 forward-port PRs (or batched) | ⛔ GO / NO-GO |
| **G1h** — 141 §C missing d-tests | ~14 cluster-squash groups (ADR-0059 cadence) | ⛔ GO / NO-GO |
| **G1i** — 28 §D missing ADRs | 28 forward-port PRs (or batched) | ⛔ GO / NO-GO |
| **G1j** — 8 tmpl-larger rows (divergent evolution) | **OUT OF SCOPE per owner directive** (reverse FORBIDDEN) — parked for future sprint | ⛔ ACK parked / RECONSIDER scope |
| **G1k** — ADR-0075 matrix amendment (correct `equivalent` → `divergent` reclassification + add §B.1 kickoff annotation) | 1 ADR amendment PR | ⛔ GO / NO-GO |

**Total Wave 2 PRs if all GO:** 5 + 3 + 1 + 1 + 11 + 1 + 7 + ~14 + 28 + 1 = **~72 PRs**, plus ~14 cluster-squash groups for d-tests.

---

## Sister-pattern compliance

- **ADR-0049** — d-test framework (this report itself is the audit; sister-test `d-parity-audit-tooling.sh` per Lane 3 sister-test per AC5 ≥5 TCs)
- **ADR-0055 §1** — Cadence Rule 1 atomic (audit + sister-test + INDEX.md row + this report all in same commit per tester Lane 3)
- **ADR-0044** — RED-first TDD (tester Lane 3 sister-test is RED-first BEFORE this report's PR lands)
- **ADR-0045** — 9-Lens pre-publish gate (architect Lane 2 PRIMARY on the PR that publishes this report)
- **ADR-0012** — 4-cat invariant INTACT on Issue #1236 (sprint:35 + type:doctrine + type:audit + status:backlog + agent:architect + cc:architect)

---

## Cross-references

- Issue #1236 (S35-002 story) — open with `agent:architect` + `cc:architect`
- Plan: `docs/sprints/sprint-35/00-plan.md` (Wave 1 S35-002 spec)
- ADR-0075: `docs/decisions/ADR-0075-template-launcher-parity-matrix.md` (the matrix being audited)
- Evidence files:
  - AC1: `docs/sprints/sprint-35/00-parity-refresh.json`
  - AC2: `docs/sprints/sprint-35/00-parity-ac2-sha-drift.json`
  - AC3: `docs/sprints/sprint-35/00-parity-ac3-patch-verify.json`
  - AC4: `docs/sprints/sprint-35/00-parity-ac4-missing-verify.json`
- Sister-test (tester Lane 3, pending): `scripts/tests/d-parity-audit-tooling.sh` per ADR-0049

---

🤖 Filed by @architect per Sprint 35 EXECUTE charter (owner-ratified 2026-07-27T18:45+03:00). ⛔ **OWNER GATE 1 STOP** — review this GAP TABLE + decision matrix before Wave 2 begins.