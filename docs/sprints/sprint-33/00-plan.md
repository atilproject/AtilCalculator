# Sprint 33 Plan — Doctrine Refresh + Wave 8+ Close-out

> **Plan author:** @product-manager (cycle ~#3964Q, 2026-07-20T19:35+03:00)
> **Plan source:** Issue #1171 cmt 5024533756 [ORCH→PM Sprint scope expansion 2026-07-20T19:23+03:00] + RETRO-032 §Action items #1-6 + RETRO-032 §Wave 8+ evolution capture (cycles ~#3889Q → ~#3962Q)
> **Plan target files:** `atilcan65/AtilCalculator` (primary, this repo) + `atilproject/dev-studio-template` + `atilproject/AtilCalculator` (sister cross-repo doctrine propagation per Cadence Rule 2)
> **Plan cadence:** 2 weeks / 10 working days (Sprint 33 = 2026-07-21 → 2026-08-01, conditional on AC5 24h soak GREEN at 2026-07-21T16:07:23Z)
> **Trigger:** Owner directive cycle ~#3962Q ("bu sprinte yapacağız") + RETRO-032 §didn't-go-well lesson #6 fix (PM lane SHOULD author Sprint 33 plan DURING Sprint 32 final wave — was deprioritized last cycle)
> **Sister-pattern:** Sprint 28 `00-audit-baseline.md` (PM-authored plan during Sprint 27 final wave, cycle ~772)

---

## §Context — why this sprint exists

Sprint 32 close ceremony (Issue #1171, closed 2026-07-19T11:36:50Z, MERGED sha f033991b) plus Wave 8+ extension (cycles ~#3889Q → ~#3962Q) accumulated **14 NEW doctrine lessons** codified in `docs/sprints/sprint-32/RETRO-032.md` §NEW doctrine + **5 additional Wave 8+ delta lessons** (lessons #15-19). Net: **19 lessons currently sitting in RETRO-032 with codification paths marked `(TBD)`** — they need to land in `.claude/agents/{orchestrator,tester,architect}.md` AND the corresponding sister-repo `.claude/agents/*.md` (Cross-Repo cadencing per Cadence Rule 2).

Additionally:
1. **AC5 24h soak** (PR #194+#195+#196+#1179 cluster) split-deferred per cycle ~#3962Q owner directive (a) — Sprint 33 must verify post-soak stability before declaring main green for Sprint 34 planning.
2. **tmpl#162 premature-close** flagged (Issue #1180) — PR #196 used `Closes #162` anchor with PR body explicit "Phase A only; Phase B impl needed". Sprint 33 follow-up needed.
3. **Env-dep d-test decoupling** (Issue #1182) — Sprint 32 d-test sweep AC4 NOT MET (4 env-dep regressions, cycle ~#3471). Pattern codification needed.
4. **Dev-pane stall detection** (Issue #1183) — Sprint 32 lesson #2 didn't-go-well (37min stall post-cycle-#3731 peer-poke). Automated detection needed.
5. **wake_nudge polling-loop audit** (Issue #1184) — cross-cutting impact assessment needed (was tested only against orchestrator role per PR #1178 fix).

### Outcome

After Sprint 33, `.claude/agents/{orchestrator,tester,architect}.md` carry all 19 NEW doctrine lessons (refs to cycle-anchored evidence), `scripts/agent-watch.sh` includes stall detection + wake_nudge dedup-class coverage, the env-dep d-test pattern is codified in a sister-ADR, Issue #1180 (tmpl#162 Phase B) reaches terminal state, Issue #1181 (24h soak) closes GREEN, and the project can enter Sprint 34 with stable main + clean doctrine references.

---

## §0 — Sprint Goal (North Star)

**All 19 RETRO-032 NEW doctrine lessons land in their target soul files + d-test framework, Issue #1181 AC5 24h soak verification passes GREEN, Issue #1180 tmpl#162 Phase B reaches terminal state, and Sprint 33 RETRO-033 captures the E10/E11 doctrine hardening outcomes.**

Sprint DoD success criterion:
- All 3 sprint amendment PRs (`feature/soul-amend-s33`, `feature/d-test-wake-nudge`, `feature/orphan-link-lint`) merge to main with tester Lane 2 docs verdict chain + owner squash gate.
- `scripts/agent-watch.sh` includes `scripts/tests/d-wake-nudge-audit.sh` GREEN (≥5 TCs per ADR-0044 RED-first).
- `docs/decisions/ADR-NNNN-env-dep-dtest-decoupling.md` ratified by architect + tester.
- Issue #1180, #1181 closed via Closes anchor from their respective PRs.
- RETRO-033.md drafted per sister-pattern to RETRO-032 cadence.

Sprint boundary:
- **IN scope**: 6 STORIES (STORY-S33-001..006, 16 SP total), doctrine codification, env-dep d-test pattern, AC5 soak verification, orphan-link lint, dev-pane stall detector, RETRO-033.
- **OUT of scope**: new feature work, Sprint 34 planning, additional cluster-squash work, scope expansion past owner-directive.

---

## §1 — Owner Decisions Ratified

> **Source**: Cycle ~#3962Q owner directive + Issue #1171 cmt 5024533756 ack

| # | Topic | Decision | Implementation |
|---|---|---|---|
| 1 | Sprint 33 scope | 6 STORIES (S33-001..006) = 16 SP, doctrine refresh only | This plan; no feature work |
| 2 | tmpl#162 Phase B follow-up | Sprint 33 STORY-S33-001 (Issue #1180) P1 3sp | Test lane + arch lane co-owned |
| 3 | AC5 24h soak | Sprint 33 STORY-S33-002 (Issue #1181) P1 1sp | Orch lane (verification protocol) |
| 4 | Env-dep d-test decoupling | Sprint 33 STORY-S33-003 (Issue #1182) P2 3sp | Arch lane (pattern ADR) + dev lane (Issue #1108 impl) |
| 5 | Dev-pane stall detection | Sprint 33 STORY-S33-004 (Issue #1183) P2 3sp | Dev lane (impl) + orch lane (Lane 2) |
| 6 | wake_nudge cross-role audit | Sprint 33 STORY-S33-005 (Issue #1184) P1 3sp | Orch lane (audit) + each role (soul amendment) |
| 7 | Soul codifications (lessons #1-14) | Sprint 33 STORY-S33-006 P1 3sp | Each role proposes own soul amendment per ADR-0059 |
| 8 | Cross-repo propagation | Cadence Rule 2 cumulative NO-OP if calc-only changes; sister-repo PR opened ONLY if tmpl/launcher impacted | Per file ownership matrix `.claude/` = human-only, but calc-side stories can sister-port per Cadence Rule 2 |
| 9 | Cluster-squash cadence | ADR-0059's 3-4 PR cluster pattern preserved (Sprint 32 Wave 8+ validation) | All 6 stories thread into 1-2 cluster PRs at W1 close |
| 10 | Sprint 33 plan authoring | PM lane, DURING Sprint 32 final wave per RETRO-032 lesson #6 fix | THIS document authored cycle ~#3964Q |
| 11 | Conventional Commits linter agent-prefix whitelist (Issue #1191, ref:pr-1188) | Sprint 33 P1 carry-over #8 of Issue #1171 / PR #1188 tester soul amend. Owner-ratification-gated per cycle ~#3968Q+3 owner directive. Architect lane (CI config) + tester lane (d-test coverage). | Carry-over chain reference added cycle ~#3968Q+3 (PR #1189 NIT #3 active remediation pending orchestrator Option A/B/C choice). |

---

## §2 — Sprint Composition (Wave Plan)

### Wave 1 — Foundation (week 1, 2026-07-21 → 2026-07-25)

Focus: cluster-squash close-out (S33-001 + S33-002) + soul amendment cluster (S33-005 + S33-006 per Cadence Rule 1 atomic)

| Story | Title | Owner | Co-CC | SP | Wave | Status |
|---|---|---|---|---|---|---|
| STORY-S33-001 | tmpl#162 Phase B follow-up (Issue #1180) | tester | arch + PM + human | 3 | W1 | `status:ready` after PR open |
| STORY-S33-002 | AC5 24h soak verification (Issue #1181) | orchestrator | PM + human | 1 | W1 | Soak-bound, terminal at 2026-07-21T16:07:23Z |
| STORY-S33-005 | wake_nudge 5-role audit (Issue #1184) | orchestrator | arch + tester + dev + PM | 3 | W1 cluster | Cadence Rule 1 atomic with S33-006 |
| STORY-S33-006 | Soul codifications (RETRO-032 lessons #1-14) | developer (orch.md) + tester + arch | PM (cross-track) | 3 | W1 cluster | Cadence Rule 1 atomic with S33-005 |

**W1 cadence target**: 1-2 cluster-squash PRs (S33-001 single-PR + S33-005/S33-006 single cluster-PR per Cadence Rule 1 atomic S33-005+S33-006 = 6 PRs in one cluster).

### Wave 2 — Feature (week 2 early, 2026-07-28 → 2026-07-30)

Focus: env-dep d-test pattern (S33-003) + dev-pane stall detection (S33-004)

| Story | Title | Owner | Co-CC | SP | Wave | Status |
|---|---|---|---|---|---|---|
| STORY-S33-003 | Env-dep d-test decoupling pattern (Issue #1182) | architect | tester + dev + PM | 3 | W2 | Lane 2 docs chain for ADR |
| STORY-S33-004 | Dev-pane pickup stall detection (Issue #1183) | developer | orch + PM | 3 | W2 | Lane 2 design alignment |

**W2 cadence target**: 2 PRs (S33-003 ADR + d-test; S33-004 stall detection script + d-test).

### Wave 3 — Polish (week 2 late, 2026-07-30 → 2026-08-01)

Focus: RETRO-033 authoring + Sprint 34 kickoff prep

| Item | Title | Owner | Co-CC | SP | Wave | Status |
|---|---|---|---|---|---|---|
| RETRO-033 | Sprint 33 retrospective | PM | orch + human | 1 | W3 | Authored by PM, ratified by orch |
| Sprint 34 prep | Backlog refresh + plan authoring | PM + orch | human | TBD | W3 | OUT of Sprint 33 scope, prep only |

**W3 cadence target**: 0 PRs from PM (docs only); RETRO-033 + Sprint 33 close ceremony.

---

## §3 — Story Detail Links

All 6 STORY files authored by PM in this wave (cycle ~#3964Q):
- `docs/backlog/STORY-S33-001.md` — tmpl#162 Phase B follow-up
- `docs/backlog/STORY-S33-002.md` — AC5 24h soak verification
- `docs/backlog/STORY-S33-003.md` — Env-dep d-test decoupling pattern
- `docs/backlog/STORY-S33-004.md` — Dev-pane pickup stall detection
- `docs/backlog/STORY-S33-005.md` — wake_nudge 5-role audit
- `docs/backlog/STORY-S33-006.md` — Soul codifications (RETRO-032 lessons)
- **Issue #1191** — Conventional Commits CI linter agent-prefix whitelist (carry-over #8 of Issue #1171 / PR #1188). Carry-over reference added cycle ~#3968Q+3 per [ORCH→PM] Issue #1191 wake.

`docs/backlog.json` updated (sprint_33_groomed_at + sprint_33_source + 6 STORY entries) — `updated_at: 2026-07-20T19:35:00Z`.

---

## §4 — Cross-Cutting Discipline

### §4.1 Cadence Rule 1 atomic

Per ADR-0055 §1: any "Sprint NN close ceremony" MUST land close.md + RETRO-NN.md + CHANGELOG.md in **single commit** (Sprint 32 sister-pattern cycle ~#3748). Sprint 33 W3 will apply this on RETRO-033 + close.md.

### §4.2 Cadence Rule 2 cumulative

Per ADR-0055 §2: any d-test co-authored with INDEX.md MUST register row in **same commit** (Sprint 28 cycle ~772 sister-pattern). Sprint 33 W2 (S33-003 d-test) will apply this on `scripts/tests/d-s33-XXX-env-dep-decoupling.sh` + INDEX.md.

### §4.3 §4-cat Invariant Repair Silent-Skip Rule

Per RETRO-024 (Issue #1027): any 4-cat-repair script MUST silent-skip when issue matches `type:<*> + status:ready + cc:human + (no agent:*)`. Sprint 33 STORIES (S33-001..006) all have `agent:*` set so this rule does NOT apply to Sprint 33 work. **Live instance watch**: Sprint 33 PRs for orphan-link-lint (S33-001) must NOT reflexively re-add `agent:*` to Issues #1180, #1181, #1182, #1183, #1184 if those Issues have reached work-done-elsewhere terminal state per sister-repo strategy.

### §4.4 Lane 2 docs verdict chain (per Issue #414 + Issue #430 + Issue #682)

All Sprint 33 PRs to `docs/sprints/**`, `docs/decisions/**`, `.claude/agents/**` MUST go through:
1. Architect 9-Lens (ADR-0045) per doc-impact surface
2. Tester Lane 2 docs verdict (ADR-0024 verdict-by:<role>:<ts>)
3. PM acceptance (Issue #430 §Pre-verdict cross-check + Issue #682 §Post-verdict cross-watchdog)

**Lane 2 chain also applies to Issue #1191 carry-over** (Conventional Commits linter agent-prefix whitelist, ref:pr-1188): any soul amend PR using `tester(soul):` / `orch(soul):` / `arch(soul):` prefix MUST route through this Lane 2 chain AND the linter fix MUST be ratified by owner before the agent-prefix whitelist extension ships.

### §4.5 Owner squash gate (per ADR-0031)

All Sprint 33 PRs — even after Lane 2 docs verdict chain — MUST go through human squash gate (`.claude/` soul file amendments, `docs/sprints/**`, `docs/decisions/**` are human-only territory per file ownership matrix).

---

## §5 — Risks + Open Questions

### Risks

- **R1**: AC5 24h soak may surface unexpected main-branch regressions → Sprint 33 closes with retry AC5 on the new soak window. Mitigated by Issue #1181 RETRO-033 entry.
- **R2**: tmpl#162 Phase B implementation may surface gap in d-test framework hardening (pre-impl sister-tests may need to land first). Mitigated by deferring scope in W2 if W1 closes late.
- **R3**: wake_nudge audit (5-role audit) may surface additional polling-loop bugs needing immediate fix (out of Sprint 33 scope). Documented as RETRO-033 §Watchlist carry-over to Sprint 34.

### Open Questions (PM-owned initial triage)

- **Q1**: arch lane — confirm whether env-dep d-test pattern (S33-003) is full ADR vs lightweight design note (RETRO-032 carries-forward codification preference for ADR). Owner default per cycle ~#3962Q.
- **Q2**: dev lane — confirm Issue #1108 (FAKE_FLIPPED_FILE fixture seed pin) impl scope (just fixture pin vs full env-decoupling middleware).
- **Q3**: orch lane — confirm whether 5-role soul amendment (S33-005) is single-cluster PR or 5 separate PRs (Cadence Rule 1 atomic suggests single cluster).
- **Q4**: tester lane — confirm whether AC5 24h soak verification (S33-002) warrants P1 priority or defer to P2 (Sprint 33 W1 must close before Sprint 34 prep).

---

## §6 — Sprint 33 Close Ceremony Anchor

- Sprint 33 close ceremony expected: 2026-08-01 Friday (per Sprint cadence §10 working days)
- Close ceremony docs: `docs/sprints/sprint-33/close.md` + `RETRO-033.md` + `CHANGELOG.md` (Cadence Rule 1 atomic single commit)
- Pre-close gates: all 6 stories terminal + AC5 soak GREEN + RETRO-033 drafted
- Post-close handoff: Sprint 34 plan author = PM (Sprint 34 in-flight via cycle ~#3964Q+)

---

— @product-manager (cycle ~#3964Q, 2026-07-20T19:35+03:00, DURING Sprint 32 final wave per RETRO-032 lesson #6 fix)
— Carry-over #8 (Issue #1191, Conventional Commits linter agent-prefix whitelist) annotated cycle ~#3968Q+3 by @product-manager per [ORCH→PM] Issue #1191 wake (2026-07-20T19:55+03:00). PR #1189 NIT #3 authoring-gap remediation pending orchestrator Option A/B/C choice.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
