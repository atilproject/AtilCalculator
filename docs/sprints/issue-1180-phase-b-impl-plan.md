# Issue #1180 Phase B impl — work breakdown (dev lane)

> Created 2026-07-23T08:55:00Z by dev lane pickup. Cross-repo: AtilCalc#1180 (tracker) → dev-studio-template#162 (impl target, sister, closed prematurely per cycle ~#2919).
>
> Worktree: `/home/atilcan/projects/issue-1180-phase-b/` on branch `dev/s33-p1-issue-1180-phase-b-impl` (tracking `origin/main` @ a89611c, base = PR #1209 squash).

## Status

- **Pickup comment**: cmt 5056360795 @ 2026-07-23T08:55:00Z on AtilCalc#1180
- **d-stall-detect audit**: cmt 5056373219 @ 2026-07-23T08:58:00Z on AtilCalc#1180 (sister-pattern gap documented, follow-up Issue recommended)
- **Branch**: `dev/s33-p1-issue-1180-phase-b-impl` created
- **WIP**: 1/2 (AtilCalc dev lane, Issue #1180 only, slot 2 free for additional cluster claims)

## AC breakdown

Per Issue #1180 body + d-s32-024 d-test (PR #196, 4/8 PASS + 4/8 RED pre-impl):

### AC1 — dry-run invocation + project bootstrap
- **What**: `scripts/dev-studio-dryrun.sh` (new) — sourced-mode + FIXTURE_* pattern per d001-launcher sister
- **Sub-steps**:
  1. `gh repo create atilcan65/sprint-32-dryrun --template atilproject/dev-studio-template --private` (sister-pattern: dev-studio-launcher/new-project.sh)
  2. Clone to `/tmp/sprint-32-dryrun`
  3. `git checkout v1.1.0` (sister: S32-019 Issue #159)
  4. `bash init.sh` (renders .tmpl → final .md, sister: Issue #185/186)
  5. `bash bootstrap-labels.sh` (creates 14 critical labels, sister: ADR-0012)
  6. Verify: TC5 (4/8 RED) → GREEN (8/8 PASS)
- **d-test coverage**: extends d-s32-024 TC4, TC5, TC6, TC7 to GREEN
- **Risk**: live `gh repo create` requires orchestrator/owner coordination (Telegram ping) per cycle ~#3442
- **Size**: M (3-4 hours, multi-file)

### AC4 — PM claim path
- **What**: `docs/sprints/issue-1180-phase-b-pm-claim-path.md` (new) + `scripts/dev-studio-dryrun.sh --pm-claim` (new flag)
- **Sub-steps**:
  1. Dry-run files a Vision Intake issue (`gh issue create --label type:vision --label agent:product-manager`)
  2. PM lane claims (manual, but scripted: `gh issue edit --add-label agent:product-manager`)
  3. First story sized + claimed by developer (scripted: `gh issue create + edit`)
  4. Document the path in the impl doc
- **d-test coverage**: d-s32-024 TC5 (Vision Intake issue exists) + TC6 (PM claim label)
- **Risk**: live `gh issue create` requires repo write access
- **Size**: S (1-2 hours, mostly docs + scripted gh calls)

### AC5 — in-dry-run merge — ABOLISHED
- **Disposition**: Per cycle ~#3968Q+71+terminal, AC5 24h soak ABOLISHED. Sister-pattern applies to Issue #1180.
- **Doc**: One-line disposition in `docs/sprints/issue-1180-phase-b-impl-plan.md` (this file)

### AC6 — close-the-loop
- **What**: `scripts/dev-studio-dryrun.sh --verify-4cat` (new flag) + `scripts/tests/d-s32-024-new-project-bootstrap-dry-run.sh` amendment
- **Sub-steps**:
  1. Verify 4-cat labels per ADR-0012 (14 critical labels present, agent:* + cc:* invariant)
  2. Apply `verdict-by:tester` + `verdict-by:architect` (cycle ~#3968Q+180 atomic pairing)
  3. Document owner squash-merge per ADR-0031
  4. Close Issue #1180 + sister tmpl#162 hygiene
- **d-test coverage**: extend d-s32-024 TC7 (4-cat verification)
- **Risk**: owner squash requires human action (gate per ADR-0031)
- **Size**: S (1-2 hours, mostly scripts + d-test amendment)

## Sister-pattern lineage

Per ADR-0049 ≥3 sister-pattern required:
- d-s32-024-new-project-bootstrap-dry-run.sh (DIRECT, extends 4 RED TCs to GREEN)
- d-smoke-bootstrap-v110.sh (Sprint 32 sister, content-blob SHA v3 amendment per cycle ~#3940Q+9)
- d-verify-portage-diff-engine.sh (TRAP cleanup + REST + bash -n pattern)
- d001-launcher-self-hosted-runner-patch.sh (sourced-mode + FIXTURE_* pattern for AC1)
- e2e-pilot.sh (T1-T7 e2e new-project bootstrap pattern, sister to AC1+AC2)

## Cadence Rule 1 atomic (per ADR-0055 §1)

All Phase B work MUST be in single commits per AC, with:
- Helper / impl script
- d-test amendment
- INDEX.md row (if new d-test)
- CHANGELOG.md entry

## Cross-repo coordination (per cycle ~#3968Q+213)

- **PR body anchor**: `Closes atilproject/AtilCalculator#1180` (cross-repo Closes per ADR-0057)
- **Refs**: atilproject/dev-studio-template#162 (sister, closed+status:in-progress inconsistent)
- **Cluster-squash eligible**: STANDALONE per cycle ~#3258 (single PR), no pair required
- **Owner squash gate**: @atilcan65 per ADR-0031

## Follow-up sister issues (recommended, not blockers)

1. **d-stall-detect detection rule gap** (tester lane, ADR-0044 RED-first):
   - Issue: detection rule uses `issue.updatedAt` which is reset by auto-claim comments
   - Fix: filter out auto-claim comments OR use PR-driven only signal
   - Sister-d-test: `scripts/tests/d-stall-detect-detection-rule.sh` (≥5 TCs, sister to d-stall-detect)

2. **agent-watch.sh stall integration audit** (orchestrator lane):
   - Issue: agent-watch.sh may not be invoking d-stall-detect (per agent-stall-detect.sh line 220 comment)
   - Fix: wire d-stall-detect into agent-watch.sh's poll cycle
   - Sister-d-test: `scripts/tests/d-agent-watch-stall-integration.sh` (≥5 TCs, sister to d-wake-nudge-audit)

## handoff

Next pickup cycle (or another dev lane agent):
1. cd /home/atilcan/projects/issue-1180-phase-b/
2. git status (should be clean on dev/s33-p1-issue-1180-phase-b-impl)
3. Read this file + Issue #1180 body + d-s32-024 d-test
4. Start with AC1: write `scripts/dev-studio-dryrun.sh` per sister-pattern d001-launcher
5. Coordinate live `gh repo create` with orchestrator/owner via Telegram
6. d-test extension per ADR-0044 RED-first
7. PR with Closes atilproject/AtilCalculator#1180
