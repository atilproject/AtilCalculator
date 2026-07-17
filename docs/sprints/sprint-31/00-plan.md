# Sprint 31 — Template & Launcher Portability Gap-Closing

> **Sprint:** 31
> **Dates:** 2026-07-17 → 2026-07-24 (1 week — owner scope-locked)
> **Owner:** @atilcan65
> **Author:** @orchestrator (cycle ~#2773, post-Sprint-30 close cycle ~#2760)
> **Status:** 🟡 **DRAFT — owner go-gate required before any WP starts**
> **Audit ref:** [`docs/audits/2026-07-17-sprint-31-audit.md`](../../audits/2026-07-17-sprint-31-audit.md)
> **Companion doc:** [`docs/new-projectsteps.md`](../../new-projectsteps.md) (Q6 deliverable, fresh write)

---

## Sprint scope (locked by owner 2026-07-17)

> **Owner directive:** "Sprint 31 sadece bu iş olacak, ben go verince sprint 31 ile başlayacak başka bir iş sprint 31 a alınmıcak."
>
> Translation: "Sprint 31 will only be this work; nothing else gets pulled into Sprint 31 until I give the go signal."

**Sprint 31 = ONLY template + launcher portability gap-closing.** No engine code, no new features, no scope drift.

---

## Sprint goals (derived from Q1-Q7 audit verdicts)

| Priority | Goal | Audit Q | Verdict |
|----------|------|---------|---------|
| 🔴 **P0** | Cut v1.0.1 release on `dev-studio-template` | Q7 | Template has 0 releases — consumers cannot pin to v1.0.1 |
| 🔴 **P0** | Cut v0.3.1 release on `dev-studio-launcher` | Q7 | Launcher has 0 releases — `curl ... \| bash` install unreachable |
| 🟡 **P1** | Forward-port critical ADRs (RETRO-024, ADR-0055, ADR-0057, ADR-0059) from AtilCalculator to template | Q2, Q4 | 43 ADRs not in template — sister-pattern drift |
| 🟡 **P1** | Resolve ADR slug-ID collisions (0046, 0047, 0060) between AtilCalculator and template | Q2, Q4 | Same number, different content — confuses cross-repo references |
| 🟡 **P1** | Sync `architect.md.tmpl` — confirm Issue #972 Path-Verify Doctrine block present | Q1, Q4 | Suspected gap (not byte-diffed in audit cycle) |
| 🟢 **P2** | Owner smoke test — create private `atilproject/*` test repo, run full init | Q1 | Private-portability untested |
| 🟢 **P2** | Remove `atiltestweb-atilcan` orphaned repo-level runner (label `atilcan`, defunct repo) | Q3 | Dead weight from `dev-studio-launcher-s29-003` era |

---

## Work Package plan

### WP1 — Cut v1.0.1 release on `dev-studio-template` (P0)

**Audit ref:** Q7
**Lane:** architect (doctrine) + orchestrator (release mechanics)
**Branch:** `arch/sprint-31-wp1-template-v101-release`
**Deliverable:** GitHub release `v1.0.1` on `atilproject/dev-studio-template` with release notes derived from TD-068b patch content + Sprint 30 audit findings.
**Acceptance criteria:**
- AC1: Release tag `v1.0.1` exists at SHA matching current main HEAD (`98ff6af`)
- AC2: Release notes cite TD-068b + 3+ ADR forward-ports (if WP3 happens first)
- AC3: No breakage in `dev-studio-init.sh` re-render smoke test
**Reversibility:** Releases can be deleted; git tag can be moved. ~5 min rollback.

### WP2 — Cut v0.3.1 release on `dev-studio-launcher` (P0)

**Audit ref:** Q7
**Lane:** developer (script) + orchestrator (release mechanics)
**Branch:** `dev/sprint-31-wp2-launcher-v031-release`
**Deliverable:** GitHub release `v0.3.1` on `atilproject/dev-studio-launcher` with notes covering S29-013 self-hosted 4-tuple patch.
**Acceptance criteria:**
- AC1: Release tag `v0.3.1` exists at SHA matching current main HEAD (`2584933`)
- AC2: Release notes cite S29-013 (Refs AtilCalculator#1072) + 1 d-test (`d001-launcher-self-hosted-runner-patch.sh`)
- AC3: `curl -L https://github.com/atilproject/dev-studio-launcher/releases/download/v0.3.1/new-project.sh | bash --version` smoke test (dry-run)
**Reversibility:** Releases can be deleted. ~5 min rollback.

### WP3 — Forward-port critical ADRs (P1)

**Audit ref:** Q2, Q4
**Lane:** architect (doctrine author)
**Branch:** `arch/sprint-31-wp3-adr-forward-port`
**Deliverable:** PR on `dev-studio-template` adding the following ADR files (5–10 ADRs from AtilCalculator, scoped to those without AtilCalculator-specific context):
- `docs/decisions/ADR-0055-cadence-rule-1-atomic.md`
- `docs/decisions/ADR-0057-closes-anchor-strict-format.md`
- `docs/decisions/ADR-0059-cluster-squash-architecture.md`
- `RETRO-024-work-done-elsewhere-4cat-exception.md` (as ADR-like doc)
- (Plus: any other Sprint 28-30 era ADRs architect identifies as template-portable)
**Acceptance criteria:**
- AC1: Each ADR references AtilCalculator's source ADR in a "Source" header
- AC2: PR passes architect 9-Lens review (ADR-0045)
- AC3: `dev-studio-template` ADR count increases by ≥5
**Reversibility:** 1 commit revert per ADR-0055 §1 atomic.

### WP4 — Resolve ADR slug-ID collisions (P1)

**Audit ref:** Q2, Q4
**Lane:** architect (doctrine)
**Branch:** `arch/sprint-31-wp4-adr-slug-reconcile`
**Deliverable:** PR on `dev-studio-template` (or both repos) that:
- Identifies the 3 colliding slugs (0046, 0047, 0060) with their content deltas
- Renumbers one side (architect's call per ADR-0049 — architect authority)
- Updates any cross-references in either repo
**Acceptance criteria:**
- AC1: No duplicate ADR numbers across both repos
- AC2: All cross-references resolve (broken-link check)
- AC3: INDEX.md updated to reflect renumbering
**Reversibility:** ADR renumbering is harder — recommend separate test repo for dry-run first.

### WP5 — Sync `architect.md.tmpl` (P1)

**Audit ref:** Q1, Q4
**Lane:** architect (self)
**Branch:** `arch/sprint-31-wp5-architect-tmpl-sync`
**Deliverable:** PR on `dev-studio-template` updating `architect.md.tmpl` to include the Issue #972 Path-Verify Doctrine block (and any other AtilCalculator-only amendments).
**Acceptance criteria:**
- AC1: `architect.md.tmpl` byte-diffed against AtilCalculator's `architect.md` — gap explicitly enumerated
- AC2: PR closes Issue #972 (or explicitly defers sub-items)
- AC3: 9-Lens review applied (self-review for soul files is allowed for owner approval path)
**Reversibility:** 1 commit revert.

### WP6 — Owner smoke test (P2)

**Audit ref:** Q1
**Lane:** human owner (not agent)
**Branch:** N/A (test repo, ephemeral)
**Deliverable:** A scratch private repo under `atilproject/*` (e.g. `atilproject/dev-studio-smoke-2026-07`) created via `new-project.sh --private`, with full init + label bootstrap + board bootstrap + first agent wake verified.
**Acceptance criteria:**
- AC1: Smoke repo created via launcher without errors
- AC2: `dev-studio-init.sh` renders all `.tmpl` files successfully
- AC3: `bootstrap-labels.sh` creates 30 labels without 422 errors
- AC4: `bootstrap-project-board.sh` creates board with 5 columns
- AC5: `dev-studio-start.sh` launches 5 tmux panes
- AC6: Orchestrator opens `[Sprint 1] Kickoff` issue within 90s of first wake
**Reversibility:** Smoke repo can be deleted; not a production artefact.

### WP7 — Write `docs/new-projectsteps.md` (P2 — already drafted in this PR)

**Audit ref:** Q6
**Lane:** orchestrator (already in flight)
**Branch:** `orch/sprint-31-audit-prep-2026-07-17` (this branch)
**Deliverable:** Fresh-write `docs/new-projectsteps.md` (companion to audit doc).
**Acceptance criteria:**
- AC1: Doc covers 6+ steps (pre-flight, launcher, post-clone init, agent start, kickoff, smoke test)
- AC2: Doc includes troubleshooting section (5+ entries)
- AC3: Doc explicitly states "fresh write, supersedes Sprint 30 version"
**Reversibility:** File-level revert via this PR's history.

### WP8 — Remove orphan runner (P2)

**Audit ref:** Q3
**Lane:** human owner (repo settings UI, not script)
**Branch:** N/A
**Deliverable:** Repo-level runner `atiltestweb-atilcan` (label `atilcan`) removed from `atilproject/dev-studio-launcher-s29-003` repo settings.
**Acceptance criteria:**
- AC1: Runner no longer listed in `gh api repos/atilproject/dev-studio-launcher-s29-003/actions/runners`
**Note:** Repo is defunct (404 via API). May require manual cleanup via web UI if API access fails.
**Reversibility:** Re-registerable if needed (but should NOT be re-added — it's dead weight).

---

## Out of scope (per owner "no drift")

- ❌ Engine code (`src/`, `tests/` AtilCalculator-specific) — not template-portable
- ❌ Sprint 28-29 historical scripts cleanup — already historical
- ❌ Tech-debt items unrelated to template portability
- ❌ Product features (calculator engine work) — wait for Sprint 32+
- ❌ New `dev-studio-template` features beyond what current ADRs cover

---

## Dependencies & sequencing

```
WP7 (already done in this PR)  ─┐
                                 ├─→  Owner review  ─→  WP1 ─→ WP2
                                 │                                │
                                 │                                └─→ WP3 (needs v1.0.1 to reference)
                                 │
WP6 (owner smoke test) ──────────┴─→  WP3 (verify AtilCalculator-only ADRs are template-portable)
                                       │
                                       └─→ WP4 (after WP3 establishes renumbering context)

WP5 (architect.md.tmpl sync) — independent, can run anytime after WP6

WP8 (orphan runner cleanup) — independent, owner-only
```

**Critical path**: WP1 → WP2 → WP3 → WP4.

---

## Risks

| Risk | Mitigation |
|------|-----------|
| Owner cuts release on template with broken `.tmpl` rendering | WP6 smoke test gates WP1 |
| ADR forward-port introduces template-specific behavior not in AtilCalc | Architect reviews each ADR for template-relevance before porting |
| Architect soul file sync misses a subtle amendment | Byte-diff before/after, list every delta in PR body |
| Owner smoke test reveals deeper portability gaps | Document in `docs/audits/` follow-up, not Sprint 32 scope-creep |

---

## Definition of Done (per WP, per ADR-0007)

For each WP:
1. PR merged to target repo's main with squash (owner-only per ADR-0031)
2. CI green on main post-merge
3. Release (if applicable) published + verified installable
4. `docs/sprints/sprint-31/` updated with WP close-out
5. Any new labels or doctrine cross-referenced in INDEX.md

---

## Daily standup plan

- **Schedule:** 09:00 Europe/Istanbul (auto-posted by orchestrator)
- **First standup:** 2026-07-18 (Saturday — owner decides if weekend standup applies, default is yes per CLAUDE.md "agents operate 24/7")
- **Format:** Per `.claude/agents/orchestrator.md` template

---

## Close-out criteria (Sprint 31 retrospective)

- All 7 WPs (WP1–WP7) completed OR explicitly deferred with documented rationale
- Owner smoke test (WP6) passed
- v1.0.1 + v0.3.1 releases verified installable
- ADR forward-port batch (WP3) merged
- Sprint 31 close.md drafted at `docs/sprints/sprint-31/close.md`
- RETRO-025 (if any sprint-specific lessons learned) filed

---

— @orchestrator, 2026-07-17T08:35:00Z (cycle ~#2773, Sprint 31 plan draft, awaiting owner go-gate)