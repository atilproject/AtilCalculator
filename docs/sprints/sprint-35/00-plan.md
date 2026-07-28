# Sprint 35 — New-Project Bootstrap Preflight Audit

> **Author**: @orchestrator (seeded from owner directive 2026-07-27T18:45+03:00, cycle ~#3968Q+10XX)
> **Reviewer**: @product-manager (Lane 1 amendment expected post-seed)
> **Owner merge gate**: @atilcan65 per ADR-0031
> **Trigger**: Owner directive "Sprint 35 — New-Project Bootstrap Preflight Audit (owner asıl proje green-light gate)"

## Outcome target

**Owner opens a NEW PRIVATE project as the primary work project (post-AtilCalculator focus). Before `new-project.sh` invocation, owner requires full pre-flight audit sprint to guarantee: hiçbir aktif feature template'de eksik değil, yeni proje 5-agent soul + panels + watchdog + reprime + task-list + stall-detect + tüm Sprint 30-34 doctrine ile birlikte açılacak.**

## Mode

🟡 **SPRINT 35 EXECUTE — AUDIT-FIRST + SURGICAL-FIX-SECOND** (READ-ONLY-VERIFICATION-FIRST + gap-closing second)

- **Owner-ratified**: 2026-07-27T18:45+03:00
- **Owner GO signal**: post-issue-filing (immediate)
- **Duration target**: 3-5 days elapsed (owner-paced, agent-executed)
- **Scope boundary**: audit-first → gap table → owner-gated surgical patches → live smoke → owner sign-off → green-light. OUT: any new feature, any calc-only surface change, any parallel new sprint.
- **Sister-repo triple-sync**: template = source of truth, calc = mirror (frozen during sprint), launcher = doc-only mirror per S34 doctrine
- **Sprint DoD**: disposable bootstrap test GREEN + live smoke test (private disposable) 30-min soak GREEN + owner explicit "go" for asıl proje

---

## Sprint 34 residual context

- Sprint 34 CLOSED 2026-07-26 (close.md PR #1232 merged, RETRO-034 filed)
- 23/23 forward-port SHIPPED across 3 repos
- S34-002 umbrella #1222 STILL OPEN (terminal Closes anchor RESERVED for row 280 same-repo PR per RETRO-024)
- RETRO-034: 19 lessons, 5 NEW DOCTRINE carry-overs to Sprint 35

## Story inventory (7 stories, 4 waves)

### WAVE 1 — Sprint 34 residual close-out (audit health check)

#### Story S35-001: Sprint 34 residual verification

**AC1**: Verify S34-002 umbrella #1222 status — either close via RETRO-024 owner-directive OR document why deferred
**AC2**: Verify RETRO-034 5 NEW DOCTRINE carry-overs — spawn ADR drafts (or file as backlog issues) per lesson
**AC3**: Verify NO Sprint 34 story left in "in_progress" state anywhere (issue label audit)
**Owner lane**: PM Lane 1
**Story-issue labels**: `sprint-35`, `type:audit`

#### Story S35-002: Parity matrix (ADR-0075) execution audit

**AC1**: Re-run `scripts/cross-repo-scan.sh` + `scripts/audit-project-refs.sh` fresh output → save to `docs/sprints/sprint-35/00-parity-refresh.json`
**AC2**: For each ADR-0075 row classified as equivalent — verify calc file SHA == template file SHA (dual `gh api .sha` fetch). Report drift.
**AC3**: For each divergent row — verify template has all Sprint 33+34 patches applied (grep for expected patterns in template content).
**AC4**: For each missing row from §B.2 (9 scripts) + §C (~150 d-tests) + §D (~14 ADRs) — verify STILL missing OR now forward-ported (compare against Sprint 34 PR list #210-#225).
**AC5**: Publish `docs/sprints/sprint-35/01-parity-audit-report.md` with GAP TABLE (rows where actual state ≠ ADR-0075 claim).
**Owner lane**: architect PRIMARY + tester Lane 3 (INDEX.md d-test row)
**Story-issue labels**: `sprint-35`, `type:audit`, `type:doctrine`

**⛔ OWNER GATE 1**: Owner reviews S35-002 gap table → go / no-go per row-group BEFORE Wave 2 patches begin.

---

### WAVE 2 — Gap patches (only-if-needed)

#### Story S35-003: Divergent + missing gap-closing surgical patches

**Depends on**: S35-002 gap table

**AC1**: For each GAP row from S35-002 AC5 → open impl PR to template (or launcher if launcher-scoped)
**AC2**: Byte-equivalence claim (equivalent rows) + patch-forward (divergent) + create (missing) — follow ADR-0075 forward-port sister-pattern from Sprint 34 S34-002
**AC3**: Cluster-squash windows per ADR-0059 (Sprint 34 W4 precedent). Max 5 PRs per cluster.
**AC4**: Update ADR-0075 status column for each closed row (PROPOSED → APPLIED-2026-07-XX + PR ref)

**Owner gate BEFORE impl**: S35-002 gap table must be human-reviewed + owner "go" per row-group

**Owner lane**: developer + reviewer (architect)
**Story-issue labels**: `sprint-35`, `type:feat`, `type:test`

#### Story S35-004: Disposable bootstrap workflow execution (S34-004 activation)

**AC1**: Trigger `.github/workflows/disposable-bootstrap-test.yml` via `gh workflow run` (workflow_dispatch, self-hosted runner atilcan) with private-repo bootstrap flag
**AC2**: Workflow GREEN → attach full run log to Sprint 35 close.md as evidence
**AC3**: If workflow RED → RCA per ADR-0078 pattern, fix underlying script/template, re-run until GREEN
**AC4**: Verify test project artifacts inside runner: 5 role tmpls rendered, 11 workflows deployed, 34 labels seeded, systemd unit files placed, `state/tasklists/` dir exists
**Owner lane**: tester PRIMARY + developer for RCA
**Story-issue labels**: `sprint-35`, `type:test`, `type:audit`

**⛔ OWNER GATE 2**: Owner reviews S35-004 disposable bootstrap GREEN evidence BEFORE Wave 3 live smoke.

---

### WAVE 3 — Live smoke (real disposable private project)

#### Story S35-005: Live smoke — disposable PRIVATE project 30-min soak

**AC1**: Invoke `new-project.sh preflight-smoke-$(date +%Y%m%d-%H%M) --private --dir /tmp` — real repo creation
**AC2**: Verify all 5 phases of `docs/new-project-steps.md` execute clean (or `new-projectsteps.md` in AtilCalc for §5 evidence anchors)
**AC3**: Start tmux session, 5 panes come up, agent-context-monitor + agent-watch + reprime systemd units active
**AC4**: Seed a simple task (owner-provided prompt to orchestrator: "list files in scripts/") → verify orchestrator dispatches to developer → verify task completion within 10 min
**AC5**: 30-min soak — monitor watchdog journal: NO `stuck_override` false-positives (per ADR-0072 tuning), task-list snapshot persists across at least 1 `/compact` cycle
**AC6**: Cleanup — `gh repo delete atilproject/preflight-smoke-* --yes` + `rm -rf /tmp/preflight-smoke-*` + `systemctl --user stop 'dev-studio-*@preflight-smoke-*'`
**AC7**: Publish `docs/sprints/sprint-35/02-live-smoke-report.md` with:
- tmux capture-pane snapshots (5 panes at t=5min, t=15min, t=30min)
- watchdog journal grep for `cleared|compacted|stuck_override`
- Task-list snapshot content evolution
- PASS/FAIL verdict per AC

**Owner participation**: Owner must be physically present for tmux session — verifies agent behavior manually. Agent orchestrator can prepare pre-conditions.

**Owner lane**: OWNER-DRIVEN + tester documents
**Story-issue labels**: `sprint-35`, `type:test`, `type:audit`, `owner-required`

**⛔ OWNER GATE 3**: Owner reviews S35-005 live smoke report BEFORE Wave 4 green-light walkthrough.

---

### WAVE 4 — Green-light + Sprint 35 close

#### Story S35-006: Green-light gate — new-project-steps.md final review

**AC1**: Owner walks through `new-project-steps.md` in `dev-studio-launcher/docs/new-project-steps.md` step-by-step
**AC2**: For each step → ✅ works / ❌ needs fix (with issue link)
**AC3**: All ❌ items → S35-007 backlog OR immediate patch (owner decides per item)
**AC4**: Publish `docs/sprints/sprint-35/03-green-light-checklist.md` with final owner sign-off
**Owner lane**: OWNER + PM Lane 1 documents
**Story-issue labels**: `sprint-35`, `type:audit`, `owner-required`

#### Story S35-007: Sprint 35 close ceremony + RETRO-035

**AC1**: `docs/sprints/sprint-35/close.md` — all 7 stories ledger
**AC2**: `docs/sprints/sprint-35/RETRO-035.md` — lessons learned
**AC3**: `docs/sprints/current/plan.md` pointer updated to Sprint 36 (or transitional pointer if owner opens new project mid-sprint)
**AC4**: Owner explicit "go" for asıl proje — Sprint 35 does NOT close until owner writes verbatim `SPRINT 35 CLOSED — NEW PROJECT GREEN-LIGHT` in a Sprint 35 close issue comment
**Owner lane**: orchestrator + owner squash
**Story-issue labels**: `sprint-35`, `type:process`, `owner-required`

---

## Constraints (bind orchestrator + all agents)

- **Direct push to main FORBIDDEN** — PR-only (owner verbatim, ADR-0031)
- **No self-merge** (ADR-0031) — reviewer + owner approval each PR
- **Cluster-squash allowed** (ADR-0059) — Sprint 34 W4 precedent, max 5 PRs per cluster
- **ADR-0044 RED-first TDD** — d-tests RED first, then impl, then GREEN
- **ADR-0055 §1 Cadence Rule 1** — atomic d-test + impl + INDEX.md same commit
- **ADR-0012 label birth contract** — 4-cat labels (type + status + agent + cc) on every ADR + story issue
- **ADR-0072** — task-list persistence + watchdog tuning (already in production)
- **File ownership matrix** — soul files (`.claude/agents/*.md`, `.claude/CLAUDE.md`) READ-ONLY for this sprint; template soul tmpls (`.claude/*.tmpl`) only touchable via architect lane
- **Sister-repo triple-sync** — template = source of truth, calc = mirror, launcher = doc-only mirror per S34 doctrine
- **ADR slug collision guard** — ADR-0076 first: verify empty in BOTH calc + template before file birth (S32 doctrine)
- **owner-required label** — stories S35-005, S35-006, S35-007 MUST NOT proceed without owner interaction per AC

## Non-fabrication guard (owner directive verbatim, immutable)

- **"uydurma sakın bana bak"** — hiçbir file/issue/PR/commit numarası hayal ürünü olmayacak, hepsi `gh api` ile verify
- **"katıp karıştırma"** — belirsizlik varsa DUR ve sor, extrapolate etme
- **"çalışan şeyi bozmayalım"** — S35-003 gap patches surgical + owner-gated per row-group
- **"ground truth çekip öyle ver"** — her ADR/PR/story reference verify edilmiş olacak
- **"yine kararları beraber alalım"** — owner-required label bearing stories owner explicit input olmadan ilerlemez
- **"template için adam gibi standard neyse o olsun"** — Sprint 35 exit criteria = template IS source of truth, byte-equivalent to AtilCalc except for calculator-only surfaces (per ADR-0075 §A-E)

---

## Sequence (agent execution order)

1. **Ground truth verify** — parity matrix ADR-0075 fresh read, Sprint 34 close.md state, RETRO-034 carry-overs
2. **S35-001** (residual close-out) ∥ **S35-002** (parity audit) — Wave 1 parallel
3. ⛔ **STOP 1**: Owner reviews S35-002 gap table — go / no-go per row-group
4. **S35-003** (gap patches) ∥ **S35-004** (disposable bootstrap workflow) — Wave 2 parallel
5. ⛔ **STOP 2**: Owner reviews S35-004 disposable bootstrap GREEN evidence
6. **S35-005** (live smoke) — Wave 3, owner-driven session
7. ⛔ **STOP 3**: Owner reviews S35-005 live smoke report
8. **S35-006** (green-light gate) — Wave 4, owner-driven walkthrough
9. **S35-007** (close ceremony) — orchestrator lane, awaits owner "SPRINT 35 CLOSED — NEW PROJECT GREEN-LIGHT" verbatim
10. **Post-close**: owner invokes `new-project.sh <asıl-proje-adı> --private` for real

---

## Reporting cadence

- Every S35-XXX PR opened → orchestrator posts link in Sprint 35 close issue thread
- Every AC met → orchestrator posts progress comment
- Every blocker → escalate immediately (do NOT self-pause per Issue #238)
- Wave completion → 1 summary message to owner
- Owner-required stories → orchestrator MUST await owner presence, do NOT autopilot

---

## Deliverables inventory (Sprint 35 exit state)

- `docs/sprints/sprint-35/00-plan.md` (this file — PM Lane 1 seed + amendment)
- `docs/sprints/sprint-35/00-parity-refresh.json` (S35-002 evidence)
- `docs/sprints/sprint-35/01-parity-audit-report.md` (S35-002 gap table)
- `docs/sprints/sprint-35/02-live-smoke-report.md` (S35-005 30-min soak evidence)
- `docs/sprints/sprint-35/03-green-light-checklist.md` (S35-006 owner sign-off)
- `docs/sprints/sprint-35/close.md` (S35-007)
- `docs/sprints/sprint-35/RETRO-035.md` (S35-007)
- Impl PRs per gap row (S35-003) — count TBD from S35-002 gap table
- ADR-0076+ if new doctrine emerges from Sprint 35

---

## What Sprint 35 EXPLICITLY does NOT do

- No new features (audit + surgical fix only)
- No calculator-only surface changes (calc = frozen mirror during sprint)
- No changes to `.claude/CLAUDE.md` soul file (READ-ONLY)
- No parallel new sprint (Sprint 36 charter deferred until owner opens asıl proje)
- No automated live smoke (S35-005 is owner-driven, no bot)

---

## Cross-refs

- **Owner directive**: 2026-07-27T18:45+03:00
- **ADR-0075**: `docs/decisions/ADR-0075-template-launcher-parity-matrix.md`
- **Sprint 34 close**: `docs/sprints/sprint-34/close.md` (post-PR #1232)
- **RETRO-034**: `docs/sprints/sprint-34/RETRO-034.md`
- **#1222**: S34-002 umbrella (OPEN, RETRO-024 reservation)
- **`.github/workflows/disposable-bootstrap-test.yml`**: template workflow_dispatch
- **Sister-patterns**: ADR-0012, ADR-0024, ADR-0031, ADR-0038, ADR-0044, ADR-0049, ADR-0055, ADR-0059, ADR-0072, ADR-0075, RETRO-024

---

*Owner merge gate pending. PM Lane 1 amendment window opens immediately after plan seed.*