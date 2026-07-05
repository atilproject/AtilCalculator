# Glossary — AtilCalculator Project Terms

> **Source of truth for product vocabulary.** PM-owned, lane-appropriate (`docs/product/` = @product-manager per file ownership matrix).
> **PM Hard Rule**: "Maintain a `docs/glossary.md` of product terms" — this document closes that gap (identified in cycle ~#7478 local-state audit, authored cycle ~#7480).
> **Author**: @product-manager (cycle ~#7480, 2026-07-05T06:43Z).
> **Update cadence**: as-needed when new terms enter the project vocabulary; sister-pattern to ONBOARDING.md, vision.md, personas.md.
> **Cross-refs**: [`docs/product/vision.md`](./vision.md), [`docs/product/personas.md`](./personas.md), [`docs/product/ONBOARDING.md`](./ONBOARDING.md), [`docs/decisions/INDEX.md`](../decisions/INDEX.md), [`.claude/CLAUDE.md`](../../.claude/CLAUDE.md).

## §Product terms (AtilCalculator-specific)

### Calculator domain

| Term | Definition | Source |
|---|---|---|
| **Expression** | A calculation input string (e.g., `0.1 + 0.2`, `sin(π / 4)`). The engine parses + evaluates expressions; history stores them. | vision.md §Core Problem |
| **Engine** | The pure-Python module (`src/atilcalc/engine/`) that parses + evaluates expressions. **Architecture rule**: pure functions, no I/O, no UI deps; CLI / HTTP / WASM surfaces wrap the engine, never the reverse. | ADR-0017, vision.md §Top-3-to-5 |
| **Decimal precision** | Use of Python stdlib `decimal.Decimal` for arithmetic. Solves IEEE-754 float-error class (`0.1 + 0.2 = 0.3` exact). Acceptance test M1. | vision.md M1, ADR-0017 |
| **IEEE 754** | The binary floating-point standard the OS calculator uses. Source of `0.1 + 0.2 ≠ 0.3` surprise. The product's reason for being. | vision.md §Core Problem |
| **Scientific functions** | Beyond four ops: parentheses, exponent (`^`), percent (`%`), square root (`√`), factorial (`!`), trigonometry (`sin/cos/tan` + rad/deg), logarithm (`log/ln`), constants (`e`, `π`). | vision.md §Top-3-to-5 |
| **DomainError** | Exception raised by engine when math domain violated (e.g., `√(-1)`, `log(0)`). Distinguishes from general `Exception` for cleaner error handling. | STORY-011 (issue #16 extension) |
| **Keyboard-first** | UX doctrine: all routine operations (digit entry, operators, equals, clear, delete, history nav) reachable using keyboard only. Acceptance M3 + Playwright E2E. | vision.md M3 |
| **History** | Persistent, cross-device record of every completed expression + result. Substring search, click-to-load. Backend-stored (NOT browser `localStorage`). | vision.md M5, vision.md §Top-3-to-5 |
| **Skin** | Theming via CSS-variable-set files. ≥3 ready skins in v1 (Dark, Light, Retro/terminal-green). Adding a skin = adding one file (developer-side). | vision.md M4, vision.md §Top-3-to-5 |
| **LAN** | Local Area Network. The product is self-hosted on the owner's LAN (Ubuntu 24.04 LTS VM at `192.168.1.199`). LAN access without auth is **out of MVP** (P2 future epic). | personas.md P1, vision.md §Out-of-Scope |
| **Always-open tab** | The owner's primary use pattern: calculator stays open in a browser tab; never has to launch a separate app. | personas.md P1, vision.md §Core Problem |

### Acceptance metrics (vision.md M1-M5)

| Term | Definition | Source |
|---|---|---|
| **M1 (Accuracy)** | Zero float errors in MVP; `0.1 + 0.2 == 0.3` exact; broader parametrised regression suite covers decimal precision edge cases. | vision.md M1 |
| **M2 (Daily-use stickiness)** | Owner uses ≥5 times/day for 7 consecutive days (proxy: ≥35 history records/week). | vision.md M2 |
| **M3 (Keyboard-only)** | All basic operations reachable keyboard-only (verified by Playwright E2E). | vision.md M3 |
| **M4 (Skin transition)** | Switching between ≥3 built-in skins completes in <500ms with no visual flicker; preference persists across sessions + LAN devices. | vision.md M4 |
| **M5 (History performance)** | History view opens in <100ms with 1,000+ records; substring search; click-to-load. | vision.md M5 |

## §Personas

| ID | Persona | Profile | Status |
|---|---|---|---|
| **P1** | **"Atil"** (owner-operator) | Software/infrastructure professional; Proxmox + Docker + systemd + nginx; keyboard-intensive; 5-20 calcs/day; VM at `192.168.1.199` (Ubuntu 24.04 LTS); sudo account `atilcan`. Turkish self-describing, English working language. | **MVP persona** (active) |
| **P2** | **"Home guest"** | Anyone on the LAN with a browser. Family, roommate, visiting friend. **NOT authenticated** (per vision's non-goals). Shared history namespace (intentional). | **NOT in MVP** (future epic — gated on owner asking for partner/flatmate access) |

> **PM anti-pattern check**: No third persona invented. Personas map 1:1 to "Target Users" in vision-intake form (Issue #4). Future P2 explicitly marked out-of-MVP, not slipped into scope.

## §Sprint / Process terms

| Term | Definition | Source |
|---|---|---|
| **Sprint** | 2-week (10 working days) iteration. Kickoff Monday W1; retro + close Friday W2. | `.claude/CLAUDE.md §Sprint cadence` |
| **Wave** | Sequencing within a sprint. Wave 1 = foundation; Wave 2 = feature; Wave 3 = polish. PM owns the wave plan. | `.claude/CLAUDE.md §Sprint cadence §Wave sequencing` |
| **Standup** | Daily 09:00 Europe/Istanbul auto-trigger. Schedule, NOT work-hours gate — agents operate 24/7. | `.claude/CLAUDE.md §Process`, Issue #238 |
| **Retro / RETRO-NNN** | Sprint retrospective document. Codifies lessons learned, watchlist items, doctrine amendments. Lives in `docs/sprints/sprint-NN/RETRO-NNN.md`. | `.claude/CLAUDE.md` |
| **close.md** | Sprint close-out document. Authored by orchestrator lane, owner-squashed. Lives in `docs/sprints/sprint-NN/close.md`. | `.claude/CLAUDE.md` |
| **Definition of Done** | 6-point checklist: AC tests green, code merged to main, CI green post-merge, docs updated, board card moved to Done, no P0/P1 bugs within 24h. | `.claude/CLAUDE.md §Definition of Done` |
| **Story points** | Sizing unit for sprint planning. PM NEVER estimates alone — requires architect + developer + tester joint sizing. | `.claude/agents/product-manager.md §Sprint planning` |
| **INVEST format** | Story acceptance: Independent, Negotiable, Valuable, Estimable, Small, Testable. | `.claude/agents/product-manager.md §INVEST format` |
| **AC (Acceptance Criteria)** | Given/When/Then (Gherkin style) conditions that must hold for a story to be done. Non-negotiable once ratified. | `.claude/agents/product-manager.md §Acceptance criteria` |

## §Doc / Doctrinal terms (multi-agent dev-studio framework)

| Term | Definition | Source |
|---|---|---|
| **ADR (Architectural Decision Record)** | Numbered, immutable, append-only decisions in `docs/decisions/ADR-NNNN-<slug>.md`. Architect owns; all others reference. | `.claude/CLAUDE.md §ADR` |
| **d-test** | Doctrinal test for AGENTS (not the product). ≥5 TCs each per ADR-0049. Lives in `scripts/tests/`. Sister-pattern to the product's pytest suite. | ADR-0049 |
| **D2.2 (pr_labeled query path)** | GitHub-native wake mechanism: when a PR gets a `needs-tester-signoff` or `needs-architect-review` label added, the peer's `agent-watch.sh` fires. Primary wake path since D2.2 (ADR-0009 §10.5.4). | `.claude/CLAUDE.md §Wake labels` |
| **4-cat invariant** | Every issue/PR must carry 4 label categories: `type:*`, `status:*`, `agent:*`, `cc:*`. Missing = CI fail (label-check.yml) + board lane "No Status". | ADR-0012 |
| **Atomic 4-flag handoff** | When handing off from agent A to agent B: `gh issue edit N --add-label agent:B --add-label cc:B --remove-label cc:A --remove-label agent:A`. Order matters: add 2 BEFORE remove 2 (invariant stays full). | ADR-0015 |
| **Owner merge gate** | Only the human owner squash-merges PRs to `main`. No agent self-merge. | ADR-0031 |
| **Auto-Ping Hard-Rule** | Never ask the human to relay messages between agents. Use `scripts/notify.sh` or `scripts/peer-poke.sh` directly. | `.claude/CLAUDE.md §Auto-Ping Hard-Rule` |
| **Dual-Channel Peer-Poke** | Waking a peer agent requires BOTH (a) Telegram message AND (b) tmux pane wake. Telegram-only is broken. `scripts/peer-poke.sh` bakes the correct invocation. | ADR-0033 |
| **Auto-Claim Protocol** | Atomic claim helper `scripts/claim-next-ready.sh`. Picks highest-priority `agent:<role> AND status:ready` issue, flips to `status:in-progress`, audit log. WIP cap per role. | ADR-0038 |
| **RED-first TDD** | Tester authors d-test PR FIRST (RED on main), then dev authors impl PR (GREEN). d-test + impl = sister-pair PRs, NOT bundled. | ADR-0044 |
| **9-Lens pre-publish gate** | Architect review checklist with 9 lenses. Pre-publish gate for any PR with architectural impact. | ADR-0045 |
| **verdict-by** | Convention for deadline timestamp on PR labels. Format: `verdict-by:2026-07-08T15:00:00Z`. ADR-0024 + Layer 5 j.4. | ADR-0024 |
| **Closes #N vs Refs #N** | PR body anchor format. `Closes #N` triggers auto-close on merge; `Refs #N` is informational only. Strict format per ADR-0057. | ADR-0057 |
| **cluster-squash** | Precedent of grouping N PRs into a cluster for coordinated squash. ADR-0059 doctrine. | ADR-0059 |
| **Lane discipline** | Convention limiting which docs paths each agent owns + which PRs each agent is cc'd on. PM = docs/{sprints,product,backlog,agents}/**, NOT scripts/ refactors (Sprint 13+ LOCKED). | `.claude/CLAUDE.md §PM lane definition` |
| **WIP cap** | Per-role work-in-progress limit (default 2). Enforced by `claim-next-ready.sh`. | ADR-0038 |
| **Katman 1 (Tier 1)** | "Take OTHER queue items" doctrine. When one item is blocked (e.g., waiting on dependency), don't idle — work on other queue items or local-only work. | Issue #238 §no-self-standby |
| **§no-self-standby** | Doctrine forbidding agents from inventing "standby", "work hours", "office hours" pauses. Only valid pause reasons: (a) explicit human instruction, (b) explicit dependency block in issue/PR, (c) heartbeat/REPRIME SOP step. | Issue #238 |
| **§Dispatch Discipline** | PM verdict pre-flight: re-query ground truth within 30s of verdict post, verify comments+reviews both, label freshness, CI status, cross-peer consensus. | Issue #414 |
| **§Pre-verdict cross-check** | Before posting verdict, verify BOTH `comments[]` AND `reviews[]`. Issue #430 codification; sister-pattern to §Dispatch Discipline. | Issue #430, `docs/CLAUDE.md` |
| **§Post-verdict cross-watchdog** | Second-pass peer flag ack. Even when MY cross-check passes, MUST identify immediately-prior peer verdict and either echo flag or defer explicitly. | Issue #682, `docs/CLAUDE.md` |
| **silent-drop** | Issue #806 bug class: `gh issue list --label X --json ...` silently misses items with non-trivial labels. 75% PM miss rate measured. Fixed by PR #808 (REST `gh api` migration). | Issue #806, PR #808 |
| **REPRIME** | Post-compaction context restoration protocol. Re-read doctrine + re-query ground truth + one-line ACK + resume. | `.claude/CLAUDE.md §REPRIME` |
| **PM-DISPATCH-PROTOCOL** | PM-authored reference doc codifying 5-step Wave Promotion Checklist (lane + sizing + sister-pattern + deps + cc) + §Dual-Listing Rule + §PM ACK Discipline + §Pre-Dispatch Lint. v0.2 docs-only; v0.3 silent-drop migration. | `docs/backlog/PM-DISPATCH-PROTOCOL.md` |
| **Lane accountability** | Author / Validator / Sign-off / Merge roles on a work item. Test plan lane accountability for Issue #836: Author=PM, Validator=PM, Sign-off=tester, Merge=owner. | Issue #836 body §Lane accountability |
| **STORY-S21-NNN** | Sprint 21 story numbering convention. Subsequent sprints use STORY-S{NN}-NNN. Documents `docs/backlog/STORY-*.md`. | `docs/backlog/STORY-*.md`, backlog.json |
| **PR-carrying issue** | Project convention: PRs are tracked with the same number as their associated issue/PR-tracking entity. `gh api /issues/N` returns unified data for both PR and issue interpretation. | Issue #816 + #836 observed pattern |

## §Tech stack terms (source: ADR-0017)

| Term | Definition |
|---|---|
| **Python 3.11+** | Language. Required for new-style type hints, `tomllib`, etc. |
| **pyproject.toml (PEP 621)** | Package metadata source. Installed via `pip install -e .[dev]`. |
| **pytest** | Test framework. Parametrised; mirrors `src/` layout. |
| **ruff** | Lint + format (replaces flake8 + black + isort in one tool). |
| **mypy --strict** | Type checker. Applied to the pure-function engine module only (`src/atilcalc/engine/`). |
| **typer** | CLI scaffolding (built on Click; declarative, type-hint driven). |
| **Decimal (stdlib)** | Numeric precision. Replaces IEEE-754 floats for engine arithmetic. |
| **Pure-function engine module** | Architecture rule: `src/atilcalc/engine/` has NO I/O, NO UI deps. CLI / HTTP / WASM wrap the engine; engine wraps nothing. |
| **CI (GitHub Actions)** | Runs ruff → mypy → pytest on ubuntu-latest. Pyproject-detected. |
| **systemd user-service** | Runtime infra (only if HTTP surface lands). Aligned with ADR-0010. |
| **Deferred** | Stack choices NOT made yet: front-end framework, persistence, distribution mode (PyInstaller / PyPI-only), HTTP API (FastAPI candidate), telemetry. |

## §Communication convention terms

| Term | Definition | Source |
|---|---|---|
| **Auto-Ping format** | `[FROM→TO] ≤80 char reason; PR/Issue link; ≤2 satır context`. | `.claude/CLAUDE.md §Auto-Ping Hard-Rule` |
| **Verdict template** | `🤖 Verdict: [🟢\|🟡\|🔴] ... Ack <prior-peer>: ... [body] Cross-watchdog: re-queried ...` Per Issue #682 codification. | `docs/CLAUDE.md §Dispatch Discipline` |
| **Layer 5 j.4** | `.github/workflows/label-check.yml` §Auto-Verdict-By hook. Auto-adds `verdict-by:*` paired with `cc:<peer>` triggers; detects VACUOUS-PASS for type:docs PRs. | ADR-0024, ADR-0068 amendment |
| **Heartbeat file** | Per-role liveness file at `/var/log/dev-studio/<project>/<role>.heartbeat`. Append a line on every action. | `.claude/agents/<role>.md` §Heartbeat |
| **Wake-nudge** | `agent-watch.sh` JSON output's `wake_nudge` field. Fires when queue non-empty but no NEW events (Katman 1 idle signal). | `scripts/agent-watch.sh`, Issue #238 |
| **Cycle note** | Per-role journal file `/var/log/dev-studio/<project>/<role>.cycle-<N>-<slug>.md`. Noteworthy actions tracked for audit. | `.claude/agents/<role>.md` |
| **claim-next-ready.sh exit codes** | 0 = claimed; 1 = nothing to claim; 2 = usage error; 3 = WIP limit reached; 4 = gh API error. | `scripts/claim-next-ready.sh` header |

## §Version history

- **v0.1** (2026-07-05T06:43Z, cycle ~#7480) — initial authoring. PM Hard Rule "Maintain a `docs/glossary.md` of product terms" gap closure (identified cycle ~#7478 local-state audit). Author @product-manager. Sources: `docs/product/{vision,personas,ONBOARDING}.md`, `docs/decisions/INDEX.md`, `.claude/CLAUDE.md`, `.claude/agents/product-manager.md`, `docs/backlog/PM-DISPATCH-PROTOCOL.md`, `docs/CLAUDE.md`, ADR-0012/0015/0024/0031/0033/0038/0044/0045/0049/0050/0057/0059/0064/0068.

> Next update candidates: HTTP surface terms (when FastAPI lands), CI workflow terms (when workflows diverge), additional persona terms (when P2 epic opens).

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
