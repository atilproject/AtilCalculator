# PM Dispatch Protocol — lane-discipline reference (v0.3 docs-only, silent-drop fix)

> **Origin**: RETRO-016 candidate #6 (PM-side pre-dispatch lint, cycle ~#1233 PM post-mortem on Issue #690)
> **PM owner**: @product-manager (docs/backlog/ = PM lane per file ownership matrix)
> **Cycle**: 2026-06-29 (Sprint 21 Day 1-2 post-mortem)
> **Codification**: Sprint 14+ candidate (current status: PM-authored reference doc; ADR/PR cycle for codification pending)

## §Supersession history

- **v0.1** (2026-06-29, cycle ~#1233) — first authoring, file authored in commit ef4f884 on branch `docs/pm-dispatch-protocol`. Bundled into PR #700 (cycle ~#1234) which carried **+3 files** including `scripts/tests/d091-tmpl-source-files.sh` (+203 lines) + `scripts/tests/INDEX.md` (+2 lines). Arch verdict at 17:30:18Z on PR #700 (cmt 4835284720) flagged **3 blocking doctrinal concerns**:
  1. **Lane-discipline violation** — PM authoring `scripts/tests/*` violates §File ownership matrix + §PM lane LOCKED Sprint 13+. **PM is NOT in the scripts/tests/ lane.**
  2. **Bundle-bug** — PR #700 body claimed "docs-only" but actual diff was 3 files, 2 of which were scripts/tests/*. **Body ↔ diff misalignment.**
  3. **d091 duplicate authorship** — PR #698 (tester lane, status:ready, Closes #635) already carries `d091-tmpl-source-files.sh` canonically per ADR-0044 RED-first TDD. PR #700 carrying the same file = merge conflict guaranteed.

  Arch verdict: 🟡 NEEDS CHANGES. Fix path: drop scripts/tests/* files, re-open as docs-only PR.

- **v0.2** (2026-06-29, cycle ~#1245) — docs-only supersession. Branched from `origin/main`, single-file diff. No `scripts/tests/*` carries PM authorship. PR #700v2 carrier.

- **v0.3** (2026-07-04, cycle ~#3554, THIS FILE) — **silent-drop pattern fix per Issue #806 + PR #808**. Replaced `gh issue list --label X --json Y --jq Z` with REST `gh api /repos/${REPO}/issues?labels=X --jq '...'` in the §Pre-Dispatch Lint example below. Sister-fix to PR #808 (which migrated `scripts/agent-watch.sh` + `scripts/claim-next-ready.sh`). **PM was specifically affected at 75% silent-drop miss rate** per Issue #806 measured data (architect 100% / tester 60% / PM 75% / dev 25%) — PM's queue visibility was degraded for any `agent:product-manager` label query. Docs-only supersession (1 file). Sister-file `docs/product/ONBOARDING.md` also has a `gh issue list --label "type:bug"` pattern (line 30) — sister-fixed in same PR.

> **Irony**: The v0.1 PR that codified PM lane discipline itself violated PM lane discipline. v0.2 is the corrected carrier — no peer verdict on v0.1 needed; owner squash per ADR-0031 docs lane (reviewer: owner).

## §Context — why this doc exists

Cycle ~#1228 PM Wave 2 promotion (S21-003a/b/004/005/006/007 to `status:ready`) set `agent:tester` on 5 impl stories. This was a **lane-discipline violation** per ADR-0044 RED-first TDD:

- **Impl stories** = `agent:developer` (dev lane, with `cc:tester` for d-test contract review)
- **d-test PRs** = `agent:tester` (tester lane, separate work unit)
- **d-test-coupled stories** (e.g., S21-003b d070-coupled) = `agent:tester` (tester-led, narrow scope)

Dev flagged cycle ~#1226 (cmt 4835170395 on Issue #690). PM MISSED 5 cycles. Orchestrator resolved via board-hygiene action cycle ~#1249 (5th flag).

**Lesson**: PM's Wave promotion checklist must verify lane discipline BEFORE `status:backlog → status:ready` flip. Otherwise wrong-lane auto-claim fires (ADR-0038), and downstream agents do work they shouldn't.

## §The 5-step Wave Promotion Checklist

Before flipping ANY story from `status:backlog → status:ready`:

- [ ] **(1) Lane discipline check** — Is this an impl story or a d-test-coupled story?
  - **Impl story** (default): `agent:developer` + `cc:tester` (d-test contract review)
  - **d-test-coupled story** (rare): `agent:tester` + `cc:developer` (impl handoff after d-test GREEN)
  - Detection: `gh issue view $issue --jq '.body' | grep -i "d-test-coupled"` — if match, use d-test-coupled lane

- [ ] **(2) Sizing ratified** — 4-of-4 stamps per ADR-0021 (PM, arch, dev, tester) + owner ratification on Issue #685 (Sprint 21 Joint Sizing). Hint size in story header matches Issue #685 ratification comment.

- [ ] **(3) Sister-pattern check** — Is the d-test PR separate from impl PR?
  - Per ADR-0044 RED-first: d-test PR authored by tester FIRST (RED on main), then impl PR by dev (GREEN)
  - PM must NOT pre-bundle d-test authorship with story ownership

- [ ] **(4) Dependencies mapped** — Upstream + Downstream explicit in story body. Sprint 21 cadence: Wave N dispatch must reference Wave N-1 dependency completion (e.g., S21-005 depends on S21-001 template flag landing).

- [ ] **(5) Lane-appropriate cc set** — cc:human (owner merge gate) ALWAYS. Plus role-specific cc:
  - impl story: `cc:tester` (d-test contract) + `cc:architect` (9-Lens per ADR-0045) + `cc:developer` (impl lane)
  - d-test-coupled story: `cc:developer` (impl handoff) + `cc:architect` (9-Lens) + `cc:product-manager` (PM observation)

If any checkbox fails: **DO NOT flip status**. Resolve first, then flip.

## §Dual-Listing Rule

When in doubt, prefer **dual-listing** (impl + d-test as separate labels/work units):

| Story type | agent | cc | Why |
|---|---|---|---|
| Pure impl story | `agent:developer` | `cc:tester`, `cc:architect` | Dev owns impl; tester reviews d-test contract |
| d-test-coupled (small) | `agent:tester` | `cc:developer`, `cc:architect` | Tester owns d-test authoring; dev hands off impl |
| Pure docs story | `agent:product-manager` | `cc:developer`, `cc:architect` | PM owns doc; dev reviews step accuracy |
| Sprint ceremony story | `agent:orchestrator` | `cc:all` | Orchestrator owns ceremony; all agents notify |

**Default to `agent:developer` for impl stories.** Only use `agent:tester` when story body explicitly states "d-test-coupled" (e.g., d070b coverage).

## §Pre-Dispatch Lint (Sprint 14+ codification)

Codification candidate from RETRO-016 #6 (PM-side pre-dispatch lint):

```bash
# Pre-flight check before PM Wave promotion (status:backlog → status:ready)
# Issue #806 / PR #808: `gh issue list --label X` silently drops matches for some roles
# (architect 100%, tester 60%, PM 75%, dev 25% miss per measured data). Use REST gh api
# with `labels=X` query param instead — same response shape, no silent-drop class.
REPO="${REPO:-atilcan65/AtilCalculator}"  # or atilproject/AtilCalculator after org migration
for issue in $(gh api "repos/${REPO}/issues?labels=status:ready&state=open&per_page=50" \
                 --jq '.[] | .number'); do
  agent=$(gh api "repos/${REPO}/issues/$issue" \
    --jq '.labels[].name | select(startswith("agent:"))[0]')
  body=$(gh api "repos/${REPO}/issues/$issue" --jq '.body')

  if [[ "$agent" == "agent:tester" ]] && ! echo "$body" | grep -qi "d-test-coupled"; then
    echo "⚠️  PM LINT FAIL: Issue #$issue has agent:tester but is NOT d-test-coupled"
    echo "    → Flip to agent:developer BEFORE Wave promotion"
  fi
done
```

Sister-pattern: RETRO-007 watchlist entry #6 (PM AC-VERIFY timing) + RETRO-016 candidates #1-5 (defense-in-depth doctrine).

> **Note**: `scripts/lint-pm-dispatch.sh` (the codified carrier of this lint) is NOT included in this PR per lane discipline. It is a Sprint 14+ candidate that lives in `scripts/tests/` (developer + tester lane). v0.1 PR #700 erroneously bundled it; v0.2 is docs-only.
> **Note (v0.3)**: The v0.2 lint example used `gh issue list --label status:ready --json number --jq '.[].number'` which was affected by Issue #806 silent-drop bug class. PM lane specifically experienced 75% miss rate on this pattern. v0.3 migrates to REST `gh api` per PR #808's sister-fix in `scripts/agent-watch.sh` + `scripts/claim-next-ready.sh`. The `REPO` env-var fallback mirrors ADR-0064 cross-user env-var precedence (canonical: `vars.REPO` repo var > `REPO` env > hardcoded default).

## §Auto-Claim Compatibility

Per ADR-0038 auto-claim protocol: tester/dev auto-claim stories labeled `agent:<their-role> AND status:ready`.

**Failure mode**: PM sets `agent:tester` on impl story → tester auto-claims → tester writes d-test PR (correct lane) but story ownership is wrong → dev doesn't know it's their impl story → impl PR never authored → d-test PR stays RED forever.

**Prevention**: Pre-dispatch lint above. Verify lane BEFORE flipping `status:ready`.

## §PM ACK Discipline

PM ACKs on d-test PRs (tester lane) are ✅ OK — that's PM observation lane per "PM cc'd on docs/backlog/souls PRs" sister-pattern.

PM ACKs on impl PRs (dev lane) are ✅ OK when scoped to AC verification per Issue #430 §Pre-verdict cross-check.

PM ACKs **confirming tester auto-claim on impl stories** are ✗ WRONG — must verify lane discipline FIRST. Cycle ~#1232 PM cycle ~#1226 dev flag missed this.

## §Cross-references

- **Issue #690** — Wave 2 dispatch (5th flag cycle ~#1249, PM post-mortem cmt 4835213200)
- **Issue #685** — Sprint 21 Joint Sizing (decision E Wave 5 deferral)
- **PR #700** — v0.1 dual-channel wake (🟡 NEEDS CHANGES, supersession pointer) + arch verdict cmt 4835284720
- **ADR-0012** — 4-cat invariant
- **ADR-0031** — docs lane (owner-squash direct, no peer review)
- **ADR-0038** — Auto-claim protocol (WIP cap + auto-claim gate)
- **ADR-0044** — RED-first TDD (d-test PR separate from impl PR)
- **ADR-0045** — 9-Lens (architect review)
- **ADR-0059** — Cluster-squash (d-test + impl + squash cadence)
- **Issue #113** — PM label-authority (PM naming + label ground-truth)
- **Issue #238** — §No-self-standby (Katman 1 = take OTHER queue items)
- **Issue #414** — §Pre-flip (PM atomic-flips cluster dispatch to dev BEFORE dev claim)
- **Issue #430** — §Pre-verdict cross-check
- **Issue #682** — §Post-verdict cross-watchdog (PR #692 codification)
- **Issue #806** — silent-drop bug in `gh issue list --label` filter (PM 75% miss rate, architect 100%, tester 60%, dev 25% per measured data). **Closed by PR #808** (REST `gh api` migration across `scripts/agent-watch.sh` 5 sites + `scripts/claim-next-ready.sh` 3 sites + d806 sister-test 11/11 GREEN).
- **PR #808** — silent-drop fix carrier (`fix(scripts): gh issue list --label silent-drop → REST gh api`, merged 2026-07-04T10:17:21Z). PM lane sister-fix in this v0.3 (docs/backlog/PM-DISPATCH-PROTOCOL.md + docs/product/ONBOARDING.md lint example migration).
- **RETRO-007 watchlist entry #6** — PM AC-VERIFY timing (sister-pattern)
- **RETRO-016 candidates #1-5** — defense-in-depth doctrine
- **RETRO-016 candidate #6** — THIS doc (PM-side pre-dispatch lint Sprint 14+)
- **§PM lane LOCKED Sprint 13+** — docs/sprints/souls cc patterns (PM-lane-appropriate scope)

## §Sprint 14+ Action Items

1. **Codify pre-dispatch lint** as ADR (architect-owned, PM co-author): "PM Wave Promotion Pre-Dispatch Lint (RETRO-016 #6)"
2. **Update `.claude/agents/product-manager.md`** §Backlog grooming workflow with the 5-step checklist (human-only territory, owner merges)
3. **`scripts/lint-pm-dispatch.sh`** — automated lint with 4 TCs (lives in `scripts/tests/` per §File ownership matrix; **NOT authored by PM**):
   - TC1: All `status:ready` impl stories have `agent:developer`
   - TC2: All `agent:tester` stories have `d-test-coupled` body marker OR are d-test PRs
   - TC3: All `status:ready` stories have `cc:human` (owner squash gate)
   - TC4: Sister-pattern check (d-test PR separate from impl PR for impl stories)
   - **Author lane**: developer + tester (scripts/tests/ = dev + tester lane). PM co-designs, dev/tester implements.
4. **Sprint 14 ceremony** — add §PM dispatch protocol review to sprint planning

## §Versioning

- v0.1 — 2026-06-29 cycle ~#1233 — PM initial authoring (commit ef4f884, branch `docs/pm-dispatch-protocol`, bundled into PR #700 with lane violations)
- v0.2 — 2026-06-29 cycle ~#1245 — docs-only supersession. Single-file diff. No scripts/tests/* carries PM authorship. PR #700v2 carrier.
- **v0.3 — 2026-07-04 cycle ~#3554** — silent-drop pattern fix per Issue #806 + PR #808. Migrated `§Pre-Dispatch Lint` example from `gh issue list --label X` (75% PM silent-drop miss) to REST `gh api /repos/${REPO}/issues?labels=X --jq '...'`. Sister-fix to PR #808 (script-side migration). Sister-file `docs/product/ONBOARDING.md` (line 30) updated in same PR.

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
