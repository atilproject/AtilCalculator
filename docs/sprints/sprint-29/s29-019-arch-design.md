# S29-019 9-Lens Design + Work Plan

> **Architect lane design attestation for Issue #1078 [S29-019]** — pre-implementation 9-Lens (ADR-0045) + work plan + multi-lane coordination map.
> **Branch:** `architect/issue-1078-s29-019-6-toplevel-docs-tmpl-render`
> **Cycle:** ~#2061+ (W3 ramp, owner directive gap-closing)

---

## 1. Scope Recap

**Issue:** #1078 [S29-019] — 6 top-level docs files `.tmpl` render (Phase 2 NEW)
**Story doc:** `docs/backlog/STORY-S29-019.md`
**Author:** architect (template render doctrine + multi-lane coordination)
**Reviewer:** architect (9-Lens per ADR-0045)
**Tester:** tester (d-test per ADR-0044; admin-level per AC5)
**Owner squash gate:** per ADR-0031 (template-load-bearing)

**Gap:** Template `docs/` has 4 top-level files (2 .tmpl). AtilCalculator `docs/` has 12. Gap = 6 port-worthy files.

---

## 2. 9-Lens Pre-Publish Attestation (ADR-0045)

### L1 Architectural fit 🟢
6 .tmpl files added to template `docs/` per Phase 2 doctrine (Issue #1075 + sister S29-016 render path). Sister-pattern to OPERATIONS.md.tmpl + TROUBLESHOOTING.md.tmpl (existing template `docs/`).

### L2 Contracts 🟢
- Each .tmpl renders to .md at `dev-studio-init.sh` step (auto-pickup via `render_all()` iterating `*.tmpl`)
- USER-GUIDE.md.tmpl ≥ 1-2 sections placeholder (AC2 minimum)
- Multi-lane ownership (CORRECTED cycle ~#2067 per orchestrator cmt 4983524237): PM on USER-GUIDE + glossary (2 files); orchestrator on new-projectsteps + peer-poke-spec (2 files); tester on index-cadence + d1083 d-test (2 deliverables); architect on tech-debt (1 file)
- 6 ACs defined in STORY-S29-019.md (1=files exist, 2=content shape, 3=render path, 4=multi-lane CC, 5=d-test, 6=metrics)

### L3 Dependencies 🟢
- **Upstream:** S29-016 (render path doctrine — `dev-studio-init.sh` updates cascade) ✅ MERGED via PR #105 (template) + PR #1075 (AtilCalculator)
- **Sister:** S29-018 (sub-dir skeletons, OBSOLETED upstream S29-012 absorbed by S29-018)
- **Cross-repo workstream:** RETRO-023 (Issue #1024) — AtilCalculator coordination + template repo PR per ADR-0059 cluster-squash

### L4 Error semantics 🟢
N/A for template scaffolding (no behavioral runtime). Render path failure modes handled by dev-studio-init.sh `verify()` function (line ~499 — unresolved `{{...}}` straggler check) + d070 d-test regression guard.

### L5 Concurrency 🟢
N/A — files are static content. Render path runs once at init (idempotent per dev-studio-init.sh AC3).

### L6 Migration 🟢
Additive only. No existing .tmpl files modified. Existing downstream projects will receive 6 new .md files on next init re-run.

### L7 Security 🟢
No security surface change. .tmpl files are public docs content.

### L8 Test coverage 🟢
d-test slot d1083 (next sequential after d1082) — admin-level per AC5:
- TC0 bash -n syntactic self-check
- TC1 6 .tmpl files exist in template `docs/`
- TC2 Each .tmpl has ≥ 1 section heading (content shape per AC2)
- TC3 USER-GUIDE.md.tmpl has ≥ 1-2 sections (PM-owned content shape)
- TC4 Cadence Rule 1 atomic — INDEX.md has d1083 row (ADR-0055 §1)

5 TCs baseline per ADR-0049 met exactly. ≥3 TCs hygiene/docs baseline per `docs/sprints/current/plan.md` met exactly (TC0 bash -n + TC4 INDEX.md attestation + d-test framework discipline).

### L9 Documentation 🟢
This design doc + STORY-S29-019.md + INDEX.md d1083 row + .tmpl files themselves = full doc attestation chain.

---

## 3. Multi-Lane Coordination Map

| File | Lane owner | Co-CC | Source content |
|---|---|---|---|
| `docs/USER-GUIDE.md.tmpl` | PM (lane-defining) | architect (impl), tester (sign-off) | PM drafts skeleton + placeholder sections per AC2 |
| `docs/glossary.md.tmpl` | **PM** (per file self-header) | architect, tester | Mirror `docs/glossary.md` (AtilCalculator, 17KB) |
| `docs/index-cadence.md.tmpl` | **tester** (per file self-header) | architect, orchestrator | Mirror `docs/index-cadence.md` (AtilCalculator, 9.6KB) |
| `docs/new-projectsteps.md.tmpl` | orchestrator | architect, tester | Mirror `docs/new-projectsteps.md` (AtilCalculator, 18KB; mirrors PR #1008, S29-015) |
| `docs/peer-poke-spec.md.tmpl` | orchestrator | architect, tester (CRITICAL per ADR-0033) | Mirror `docs/peer-poke-spec.md` (AtilCalculator, 12.3KB) |
| `docs/tech-debt.md.tmpl` | architect | orchestrator, tester | Mirror `docs/tech-debt.md` (AtilCalculator, 197KB — key sections only: Overview/Active/Closed-by-Sprint per Issue #1078 open question #1) |

**Open questions resolved by lane owners:**
- Architect: `tech-debt.md.tmpl` content scope = skeleton with 3 key sections (Overview/Active/Closed-by-Sprint) per Issue #1078 OQ #1
- Orchestrator: `peer-poke-spec.md.tmpl` content match with current `peer-poke-spec.md` (sister-pattern ADR-0033 cross-check) per Issue #1078 OQ #2

---

## 4. Sister-PR Coupling (RETRO-023 / ADR-0059)

Two sister PRs in cluster:
- **Template repo PR** (`atilproject/dev-studio-template`): 6 .tmpl files + d1083 + INDEX.md row
- **AtilCalculator PR** (this repo): coordination tracking + 9-Lens design attestation + cross-repo reference

Per ADR-0055 §1 Cadence Rule 1 atomic: d-test file + INDEX.md row + 6 .tmpl files land in same template-side PR cluster. AtilCalculator side can be a single-commit design-doc PR.

---

## 5. Work Plan (Multi-Cycle)

### Cycle ~#2061 (this cycle): Claim + Coordination
- ✅ Claim #1078 (status:in-progress, removed status:backlog mutual exclusion)
- ✅ Branch open: `architect/issue-1078-s29-019-6-toplevel-docs-tmpl-render`
- ✅ Peer-pokes: orchestrator (2 files: new-projectsteps + peer-poke-spec), PM (2 files: USER-GUIDE + glossary), tester (2 deliverables: index-cadence + AC5 d-test) — CORRECTED cycle ~#2067 per orchestrator cmt 4983524237
- ✅ 9-Lens design doc (this file) committed

### Next cycles:
- Clone `atilproject/dev-studio-template` repo (worktree)
- Create 6 .tmpl files in template repo docs/ (lane-owner content drafts)
- Create d1083 d-test + INDEX.md row
- Template-side PR + sister AtilCalculator PR
- Tester sign-off + owner squash (template-side)
- AtilCalculator-side PR is coordination only

---

## 6. Sister-Pattern Lineage

- **S29-016 (Issue #1075) Phase B** — pyproject.toml.tmpl + LICENSE.tmpl + .template-version.tmpl + render path, MERGED via PR #105 (template) + PR #1075 (AtilCalculator). Same cross-repo sister-PR pattern.
- **d1081 (PR #1092) — claim-next-ready RETRO-024 silent-skip guard** — same Cadence Rule 1 atomic + INDEX.md row + d-test same commit.
- **d1082 (PR #1094) — claim-next-ready WIP retry-guard** — same d-test ID slot allocation pattern per Issue #113 (d1083 next).
- **ADR-0059 cluster-squash doctrine** — template-side + AtilCalculator-side land in close cadence.

---

*9-Lens attestation per ADR-0045. Cross-references: Issue #1078 + Issue #113 + ADR-0012 + ADR-0044 + ADR-0049 + ADR-0055 §1 + ADR-0059 + RETRO-023 + PR #105 (S29-016 Phase B sister) + PR #1008 (new-projectsteps.md mirror) + ADR-0033 (peer-poke-spec CRITICAL).*

🤖 Generated with [Claude Code](https://claude.com/claude-code)