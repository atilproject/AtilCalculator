# Sprint 34 — AtilCalculator → template/launcher forward-port (audit gap-closing)

> **Source-of-truth:** [`docs/sprints/sprint-34/00-audit-template-launcher.md`](./00-audit-template-launcher.md) (PR #1218 SQUASH-MERGED 2026-07-24T17:34:14Z sha `44246b4`, 3/3 reviewer consensus, 132 lines)
> **Mode:** Read-only audit (✅ done) → scoped gap-closing sprint
> **Direction:** AtilCalculator → dev-studio-template + dev-studio-launcher (single-direction; reverse propagation explicitly out-of-scope per audit line 5)
> **Scope-lock (owner directive 2026-07-24, supersedes 2026-07-21T09:55Z Sprint 34-forbidden directive):** Sprint 34 = audit gap-closing sequence steps 2-8 ONLY. **No other work this sprint.**

## Why this sprint exists

PR #1218 audit (Sprint 34 step 1) established that the "100% ready" state is **not proven**:

- `dev-studio-template` is public; no private-template bootstrap evidence
- Template workflows request `[self-hosted, Linux, X64, atilproject]` but the only visible runner is `[self-hosted, Linux, X64, atilcan]` — **label mismatch**
- Launcher CI runs on GitHub-hosted `ubuntu-latest` — no private generated-project self-hosted run proven
- Parity with Sprint 33 doctrine requires exact source-to-destination classification (NOT blind copy)

Sprint 34 closes this gap in 7 stories (audit steps 2-8), grouped into 3 waves.

## Sprint 34 scope-lock (owner directive 2026-07-24)

> "tum bu işler sprint 34e yapılacak, başka iş yapılmayacak bu sprinte"

- ✅ Sprint 34 = 7 stories (S34-001 through S34-007) derived from audit steps 2-8
- ❌ Any story outside audit gap-closing sequence = **deferred or rejected**, even if PM/arch/dev lanes surface incidental work
- ❌ Sprint 34-framing of carry-over items from Sprint 33 = rejected per scope-lock
- ✅ Owner approval required for any scope change (per file ownership matrix scope-change = owner gate)

## Story inventory (7 stories, 3 waves)

| Story | Audit step | Wave | Title | Lane | Sizing |
|---|---|---|---|---|---|
| **S34-001** | 2 | W1 | Parity matrix construction (artifact-by-artifact classification) | architect (matrix) + PM (user-impact classification) | L |
| **S34-002** | 3 | W2 | Template forward-port impl (per parity matrix approved rows) | developer + architect (9-Lens) + tester (Lane 3 d-test sign-off per cycle ~#3642H) | XL (multi-PR cluster) |
| **S34-003** | 4 | W2 | Launcher forward-port impl (version contract + tests + docs) | developer + architect (9-Lens) + tester (Lane 3 d-test sign-off) | XL (multi-PR cluster) |
| **S34-004** | 5 | W2 | Disposable bootstrap test infra (public + private repo verification) | developer + owner (private-repo authorization gate) | M |
| **S34-005** | 6 | W3 | Runner tuple resolution (`atilcan` → `atilproject` mismatch) | owner (decision) + developer (config updates after decision) | S |
| **S34-006** | 7 | W3 | Verified `new-project-steps` canonical doc (derived from executed bootstrap) | PM (author) + architect (9-Lens) + tester (factual verify) + owner (final approval) | M |
| **S34-007** | 8 | W3 | Sprint 34 close ceremony + retro | orchestrator (close.md + RETRO-NNN) | S |

**Sizing total:** L + XL + XL + M + S + M + S ≈ 25-30 SP (rough, depends on parity matrix size — concrete count after S34-001 lands)

## Wave sequencing

```
W1 (Foundation) ───────► W2 (Feature) ───────► W3 (Polish)
[2026-07-27..08-02]     [2026-07-03..08-09]   [2026-07-10..14]

S34-001 (matrix)        S34-002 (template)     S34-005 (runner)
                        S34-003 (launcher)     S34-006 (verified doc)
                        S34-004 (bootstrap)    S34-007 (close)
```

**WIP cap (ADR-0038 §Auto-Claim):** Per-role WIP ≤ 2/2. Cross-lane verification enforces via Wave boundaries:
- W1 unblocks W2 (matrix gates impl scope)
- W2 unblocks W3 (impl + bootstrap + runner gate verified doc + close)
- Cluster-squash cadence per ADR-0059 (60s owner-squash window for multi-PR clusters)

## Story details

### S34-001 — Parity matrix construction (architect-led, L effort)

**As** orchestrator coordinating template/launcher parity,
**I want** an artifact-by-artifact parity matrix covering all AtilCalculator reusable surfaces,
**So that** dev lane has scoped, gated impl PRs without blind-copy mistakes.

**AC1** — Matrix covers: `.claude/*.tmpl`, agent soul templates, `scripts/` + `scripts/tests/` behavior, `scripts/tests/INDEX.md`, `docs/decisions/` ADR index, process/operations/context/peer-poke documents, workflow + workflow-template behavior, systemd/install assets, runner + watcher + task-list + reprime + label + stall-detection changes, launcher-facing setup documentation.

**AC2** — Each artifact classified as ONE of: `equivalent` / `divergent` / `missing` / `calculator-only` / `unknown` (per audit "must not be copied" filter — runtime state files and calculator product code explicitly excluded).

**AC3** — Matrix published as `docs/decisions/ADR-NNNN-template-launcher-parity-matrix.md` (architect lane) + appended to `docs/sprints/sprint-34/01-parity-matrix.md` snapshot.

**AC4** — Lane 2 docs verdict chain (arch PRIMARY + tester Lane 3 d-test-only sign-off per cycle ~#3642H + PM Lane 1 acceptance) + owner squash per ADR-0031.

**Out of scope** — Implementation work (matrix is the gating artifact, NOT impl).

**Dependencies** — None (entry point).

### S34-002 — Template forward-port impl (developer-led, XL effort)

**As** downstream consumer of `dev-studio-template`,
**I want** Sprint 33 doctrine + scripts + d-tests + ADRs synced from AtilCalculator per parity matrix `equivalent`/`divergent` rows,
**So that** template remains the source of truth for new project bootstrap.

**AC1** — Each `equivalent`/`divergent` row from S34-001 matrix becomes one PR (Cadence Rule 1 atomic per ADR-0055 §1 — d-test ≥6 TCs + INDEX.md row + CHANGELOG entry single commit).

**AC2** — Each PR passes Lane 2 docs verdict chain (arch 9-Lens per ADR-0045) + Lane 3 d-test-only sign-off per cycle ~#3642H + owner squash.

**AC3** — Cluster-squash cadence per ADR-0059 (60s owner-squash window for multi-PR clusters; sister-pattern to Sprint 33 P1/P2/P3 clusters which shipped cluster-squash 1/2/3/4/5/6/7/8/9).

**AC4** — Per-PR cycle ~#3679 1-sec-lag `Closes #N` auto-close verified (Issue #1210/#1211 sister-pattern).

**Out of scope** — `scripts/dev-studio-init.sh` template engine changes (architect lane, deferred unless parity matrix flags specific gap).

**Dependencies** — S34-001 matrix approved + scoped.

### S34-003 — Launcher forward-port impl (developer-led, XL effort)

**As** operator of `dev-studio-launcher`,
**I want** parity with template version + launcher-owned tests + version contract + docs,
**So that** new project bootstrap is verified E2E on the target runner.

**AC1** — Launcher version bump PR (e.g. `v0.4.0` → `v0.5.0`) per parity matrix + launcher-owned d-test additions (≥6 TCs per ADR-0049 baseline + cycle ~#3471 ≥6 refinement).

**AC2** — `new-project.sh` self-hosted tuple patch + fallback warning preserved per audit line 56-58 (do NOT regress the existing patch).

**AC3** — `docs/new-project-steps.md` synced from template + `README.md` updated to reflect Sprint 34 forward-port state.

**AC4** — Each PR passes Lane 2 verdict chain + Lane 3 d-test-only sign-off + owner squash.

**AC5** — Bootstrap E2E evidence captured (per S34-004 infra) — disposable generated project runs cleanly on target runner.

**Out of scope** — Launcher multi-language refactor (out-of-scope per audit).

**Dependencies** — S34-001 matrix + S34-002 template baseline landed.

### S34-004 — Disposable bootstrap test infra (developer-led, M effort)

**As** orchestrator verifying template→project bootstrap claims,
**I want** a disposable test harness (public + private repo generation, runner routing, evidence capture, teardown),
**So that** audit Q1/Q5/Q6 ("private-ready", "production-ready", "verified detailed document") have authoritative evidence.

**AC1** — Workflow script (`.github/workflows/disposable-bootstrap-test.yml`) that:
- Creates a disposable public repo from `dev-studio-template`
- Initializes + renders + labels (per launcher flow)
- Captures: repo URL, commit SHA, workflow runs, runner labels, rendered file tree, full log
- Destroys the disposable repo on completion
- (Optional, gated on owner auth) Disposable private repo with secret rotation

**AC2** — Owner authorization gate for private-repo bootstrap (secrets, Actions billing, organization permissions per audit Q1 acceptance criteria).

**AC3** — D-test ≥6 TCs covering: TC1 public-repo bootstrap, TC2 runner label match, TC3 rendered tree SHA, TC4 workflow run success, TC5 teardown cleanliness, TC6 evidence capture JSON validity.

**AC4** — Lane 2 verdict chain + Lane 3 d-test-only sign-off + owner squash.

**Out of scope** — Permanent CI workflow change (architect + owner decision per file ownership matrix `.github/workflows/` = human-only territory).

**Dependencies** — S34-002 template baseline landed (matrix + impl).

### S34-005 — Runner tuple resolution (owner-gated, S effort)

**As** owner of `atilcan65/AtilCalculator` self-hosted runner infrastructure,
**I want** the `atilcan` → `atilproject` runner label mismatch resolved before template-self-hosted runs are claimed green,
**So that** the audit's "self-hosted 100% ready" claim has a basis.

**AC1** — Owner decision documented (relabel existing runner vs provision new runner with `[self-hosted, Linux, X64, atilproject]` tuple) — captured as `docs/decisions/ADR-NNNN-runner-tuple-resolution.md`.

**AC2** — Workflow `runs-on` updated to match runner labels (template + launcher + AtilCalculator workflows).

**AC3** — Verification run: template-self-hosted run + generated-project-self-hosted run BOTH green on the resolved runner tuple.

**Out of scope** — Runner infrastructure provisioning (owner direct execution, NOT a script).

**Dependencies** — Owner decision (gate) + S34-002/003 baselines landed.

### S34-006 — Verified `new-project-steps` canonical doc (PM-led, M effort)

**As** downstream developer bootstrapping a new project,
**I want** a verified canonical setup doc derived from the executed bootstrap (per S34-004 + S34-005),
**So that** my bootstrap matches the authoritative sequence and the audit Q6 "detailed document" claim is substantiated.

**AC1** — Doc authored in `dev-studio-template/docs/new-project-steps.md` (canonical home) + mirrored in `dev-studio-launcher/README.md` (operator home).

**AC2** — Each command in the doc has a corresponding evidence artifact from S34-004 execution: bootstrap log excerpt, workflow run link, rendered file SHA, runner label match confirmation.

**AC3** — Lane 2 docs verdict chain (arch PRIMARY 9-Lens + tester Lane 3 N/A doc-only per cycle ~#3642H + PM Lane 1 acceptance as author) + owner squash per ADR-0031.

**AC4** — Doc passes "reproducibility test": a fresh developer (or CI) can run the doc commands and reach the documented end-state without ambiguity.

**Out of scope** — Adding tutorial/introductory content (separate doc, deferred).

**Dependencies** — S34-004 (bootstrap harness) + S34-005 (runner resolved).

### S34-007 — Sprint 34 close ceremony + retro (orchestrator-led, S effort)

**As** PM/owner reviewing Sprint 34 outcome,
**I want** closeout doc capturing what shipped, what deferred, and what new doctrine emerged,
**So that** Sprint 35+ inherits a clean handoff and lessons are codified.

**AC1** — `docs/sprints/sprint-34/close.md` authored with: shipped PRs (template + launcher + calc), deferred items, capacity used vs planned, doctrine lessons.

**AC2** — `RETRO-NNN.md` filed capturing: parity matrix feedback, forward-port cadence observations, runner-resolution lessons (if S34-005 landed), audit-cycle retrospective.

**AC3** — Cluster-squash ratification: all S34-001 through S34-006 stories reach terminal state (squash-merged + Closes anchor wired) OR explicitly deferred to Sprint 35+ with owner approval.

**Out of scope** — Sprint 35 planning (separate event).

**Dependencies** — S34-001 through S34-006 all merged OR explicitly deferred.

## Out-of-scope (explicit, locked)

Per audit's "Explicitly not done" section + owner scope-lock:

- ❌ Target repo edits in `dev-studio-template` or `dev-studio-launcher` for any item NOT in S34-001 parity matrix `equivalent`/`divergent` rows
- ❌ Private repo creation outside S34-004 owner-authorization gate
- ❌ Runner relabeling/provisioning outside S34-005 owner gate
- ❌ Release/tag creation outside S34-003 launcher version bump scope
- ❌ Implementation work for items outside audit gap-closing sequence
- ❌ Sprint 33 carry-over work (already TERMINAL ✅ per cycle ~#3968Q+310)

## Cross-cutting doctrine applied

- **ADR-0012** — 4-cat label invariant on every Issue/PR (enforced by `.github/workflows/label-check.yml`)
- **ADR-0015** — atomic 4-flag handoff (always `add add remove remove` order)
- **ADR-0017** — Python 3.11+ stack unchanged
- **ADR-0031** — owner squash gate (all PRs flow through owner squash)
- **ADR-0033** — dual-channel peer-poke (Telegram + tmux pane wake)
- **ADR-0038** — `claim-next-ready.sh` WIP cap (per-role ≤ 2/2)
- **ADR-0044** — RED-first TDD (tester d-test BEFORE impl lands)
- **ADR-0045** — 9-Lens pre-publish gate (architect Lane 2 PRIMARY)
- **ADR-0049** — d-test framework (≥5 TCs baseline + cycle ~#3471 ≥6 refinement)
- **ADR-0055** — Cadence Rule 1 atomic (d-number allocation + INDEX.md row single commit)
- **ADR-0057** — `Closes #N` strict format anchor
- **ADR-0059** — cluster-squash cadence (60s owner-squash window)
- **cycle ~#3642H** — Lane 3 N/A on doc-only PRs
- **cycle ~#3968Q+186** — 2-lane ack pattern scope: CLUSTER DOCS ONLY (single-file audit exempt)
- **cycle ~#3968Q+226** — 600s productive-idleness storm-watch baseline
- **cycle ~#3968Q+244** — arch verdict cc: auto-pair skipped (orchestrator 2-flag atomic fix post-verdict)
- **cycle ~#3968Q+277** — 4h+ idle escalation matrix (0-2h standby, 2-4h re-cross-check, 4h+ soft ping, 6h+ escalate, 8h+ cross-lane)
- **cycle ~#3968Q+313** — owner scope authority (newer directive supersedes; Sprint 34 framing NOW valid per 2026-07-24 owner directive)
- **cycle ~#3968Q+3921Q+/~#3922Q** — post-verdict commit doctrine (verdict-by preserved as historical evidence)

## Sister-patterns

- **Sprint 33 P1 cluster** (PR #1206/1207/1208/1209/1212/1213) — d-stall-detect cluster, cluster-squash #4-#6 — same WIP cap + cluster-squash cadence
- **Sprint 33 P2 cluster** (PR #1214/1215) — d-stall-detect-pr-driven + agent-watch stall wiring, cluster-squash #7 — same Lane 1+2+3 verdict chain
- **Sprint 33 P3 cluster** (PR #1216 + launcher#15) — close ceremony + cross-repo cluster-squash #8-#9 — same 2-lane ack scope-corrected pattern
- **RETRO-024** (Issue #1027) — work-done-elsewhere 4-cat exception (N/A here; Sprint 34 = active work, NOT work-done)
- **RETRO-033** (Sprint 33 closeout retro) — 19 NEW doctrine lessons + 13 carry-over items inherited by Sprint 34
- **PR #1216** (Sprint 33 close ceremony) — current main HEAD before #1218 squash; sister-pattern for Sprint 34 close.md structure
- **PR #1218** (Sprint 34 audit) — single-file audit precedent, 9-Lens 9/9 GREEN, cycle ~#3968Q+186 2-lane ack scope-corrected disposition

## Sprint 34 success metrics

- **Leading:** Parity matrix published (S34-001) with 100% of reusable AtilCalculator artifacts classified
- **Leading:** All `equivalent`/`divergent` rows have corresponding cluster-squash PRs (S34-002/003)
- **Leading:** Disposable bootstrap E2E run captured (S34-004) with public + private evidence
- **Leading:** Runner tuple resolved (S34-005) with verification run on target runner
- **Leading:** Verified `new-project-steps` doc published (S34-006) with reproducibility test PASS
- **Lagging:** All 7 stories reach terminal state by sprint close
- **Lagging:** RETRO-NNN filed capturing Sprint 34 doctrine lessons
- **Lagging:** No Sprint 34 scope creep (owner scope-lock honored)

## Sprint cadence

- **Length:** 2 weeks (10 working days) per CLAUDE.md §Sprint cadence
- **Kickoff:** 2026-07-27 Monday W1 (orchestrator opens `[Sprint 34] Kickoff` issue, owner approves) — **kickoff issue filing in this launch**
- **Daily standup:** 09:00 Europe/Istanbul (orchestrator posts `[Sprint 34] Daily Standup` issue)
- **Retro + close:** 2026-07-14 Friday W2 (close.md + RETRO-NNN)
- **Wave sequencing:** W1 foundation → W2 feature → W3 polish (PM wave plan authority; orchestrator WIP cap enforcement)

## Lane ownership matrix (per file ownership matrix)

| Path | Owner | Sprint 34 lane |
|---|---|---|
| `docs/sprints/sprint-34/` | @orchestrator | 00-plan.md (this), close.md |
| `docs/decisions/ADR-NNNN-parity-matrix.md` | @architect | S34-001 |
| `dev-studio-template/**` (impl PRs) | @developer (writes), @architect (reviews) | S34-002 |
| `dev-studio-launcher/**` (impl PRs) | @developer (writes), @architect (reviews) | S34-003 |
| `.github/workflows/disposable-bootstrap-test.yml` | @architect + @owner (workflows = human-only territory) | S34-004 |
| Runner config | @owner (decision) + @developer (config after decision) | S34-005 |
| `dev-studio-template/docs/new-project-steps.md` | @product-manager (author) + @architect (review) + @tester (factual verify) + @owner (final approval) | S34-006 |
| `docs/sprints/sprint-34/close.md` | @orchestrator | S34-007 |

## PM lane clarification (LOCKED Sprint 13+)

PM is **cc'd on docs/sprints/** PRs (Sprint 34 plan, retro, close), `.claude/agents/**` PRs (soul files), `docs/product/**` PRs (vision/personas), `docs/backlog/**` PRs (STORY-*.md files).

PM is **NOT cc'd** on `dev-studio-template/**`, `dev-studio-launcher/**`, `scripts/**`, `src/**`, `tests/**`, `.github/workflows/**`, `docs/decisions/**` PRs (sister-pattern RETRO-007 watchlist entry #9).

For Sprint 34:
- ✅ PM cc'd on: S34-001 matrix ADR PR, S34-007 close.md PR
- ❌ PM NOT cc'd on: S34-002/003 impl PRs (dev lane), S34-004 workflow PR (arch+owner lane), S34-005 runner config PR (owner gate), S34-006 verified doc PR (PM IS author, no separate cc needed)

## Owner gate summary

Per ADR-0031 (owner squash gate) + file ownership matrix:

| Story | Owner gate type |
|---|---|
| S34-001 matrix ADR | Squash (docs/decisions/ = architect lane, owner merge) |
| S34-002 template impl PRs | Squash per PR (cluster-squash cadence per ADR-0059) |
| S34-003 launcher impl PRs | Squash per PR (cluster-squash cadence) |
| S34-004 workflow | Squash (`.github/workflows/` = human-only territory; arch+tester draft, owner merges) |
| S34-005 runner | Direct decision (runner relabel/provisioning is owner-only execution, NOT a PR) + squash for config PRs |
| S34-006 verified doc | Squash (PM-authored, Lane 1+2 verdict chain, owner merge) |
| S34-007 close.md | Squash (docs/sprints/ = orchestrator lane, owner merge) |

---

🤖 Generated with [Claude Code](https://claude.com/claude-code) — orchestrator-seeded draft for PM Lane 1 review + amendment per cadence rule "PM owns the wave plan"
