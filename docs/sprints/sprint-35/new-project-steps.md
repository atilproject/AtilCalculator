# New Project Steps — fresh draft

> **Audit companion**: This file is the operator runbook (Q6 deliverable) that pairs with the Sprint 35 pre-GO readiness audit at [`00-pre-go-readiness-audit-and-gap-plan.md`](./00-pre-go-readiness-audit-and-gap-plan.md). Read the audit first for context, then this file for the operator walkthrough.
>
> **Draft status**: pre-publication. Verified against current default branches `main` of `atilproject/dev-studio-launcher` (latest merged PR #18, 2026-07-26T19:46:01Z) and `atilproject/dev-studio-template` (latest merged PR #225, 2026-07-26T19:45:50Z; tag `v1.1.0`). Live REST metadata captured 2026-07-27.
>
> **Scope**: detailed, ordered steps for creating a **NEW PRIVATE** project using the launcher + template. Read-only: no projects were created, no repos mutated.
>
> **Sister doc**: the canonical published doc lives at `atilproject/dev-studio-template/docs/new-project-steps.md` (PR #225). This draft is an independent reconstruction from executable code + REST metadata, not a copy.

---

## Table of contents

1. [Decision summary — public vs private](#1-decision-summary--public-vs-private)
2. [Prerequisites](#2-prerequisites)
3. [GitHub auth, scopes, and PAT](#3-github-auth-scopes-and-pat)
4. [Clone the launcher + symlink](#4-clone-the-launcher--symlink)
5. [Self-hosted runner prerequisites](#5-self-hosted-runner-prerequisites)
6. [Launcher command — real flags](#6-launcher-command--real-flags)
7. [What `new-project.sh` does, step by step](#7-what-new-projectsh-does-step-by-step)
8. [Bootstrap PROJECT_TOKEN (ADR-0014)](#8-bootstrap-project_token-adr-0014)
9. [GitHub Project board setup (ADR-0013)](#9-github-project-board-setup-adr-0013)
10. [Labels seeded by `bootstrap-labels.sh`](#10-labels-seeded-by-bootstrap_labelssh)
11. [Secrets and variables inventory](#11-secrets-and-variables-inventory)
12. [Self-hosted runner access + label matching](#12-self-hosted-runner-access--label-matching)
13. [Template init + render (`.tmpl` → final)](#13-template-init--render-tmpl--final)
14. [systemd watchers (ADR-0010)](#14-systemd-watchers-adr-0010)
15. [Telegram env provisioning](#15-telegram-env-provisioning)
16. [Local checks after bootstrap](#16-local-checks-after-bootstrap)
17. [Actions verification](#17-actions-verification)
18. [Agent runtime startup](#18-agent-runtime-startup)
19. [Vision Intake + first sprint kickoff](#19-vision-intake--first-sprint-kickoff)
20. [Acceptance checklist](#20-acceptance-checklist)
21. [Rollback / cleanup](#21-rollback--cleanup)
22. [Troubleshooting](#22-troubleshooting)
23. [Evidence sources](#23-evidence-sources)
24. [Unresolved inputs](#24-unresolved-inputs)

---

## 1. Decision summary — public vs private

The launcher defaults to `--public` (ADR-0016). This draft is for `--private`.

| | `--public` (default) | `--private` (opt-in) |
|---|---|---|
| GitHub Actions minutes | **Free** for public repos | **Billed** against org/user spending limit |
| `PROJECT_TOKEN` canary (`secret-canary.yml`) | Always schedulable | Fails fast with `job not started` if spending limit is 0 |
| Source code discoverability | Public on github.com | Hidden from search |
| Recommended for new projects (ADR-0016) | Yes | Only after spending-limit is configured |

**You specifically requested private.** That means **OWNER INPUT REQUIRED**: verify your GitHub spending limit at <https://github.com/settings/billing/spending_limit> before running the launcher, otherwise the `PROJECT_TOKEN` canary will fail and `dev-studio-init.sh` will abort with `secret canary FAILED` (init.sh line ~370, "OPTIONS: raise spending limit or `gh repo edit ... --visibility public`").

> Evidence: `dev-studio-init.sh:339-365` (canary failure path with private-repo hint); `new-project.sh:340-345` (launcher warns before create).

---

## 2. Prerequisites

Verified from `new-project.sh:274-282` (preflight checks) + `dev-studio-init.sh:65-77`.

| Tool | Min version | Why | Install (Ubuntu/Debian) | Verified? |
|---|---|---|---|---|
| `gh` | latest stable (v2.93.0 at draft time) | All GitHub operations | `sudo apt install gh` + `gh auth login` | YES — `new-project.sh:280` |
| `git` | 2.x | Clone + commit + push | `sudo apt install git` | YES — `new-project.sh:281` |
| `jq` | 1.6+ | JSON parsing in init/labels/board scripts | `sudo apt install jq` | YES — `new-project.sh:282`; `bootstrap-project-board.sh:60` |
| `tmux` | 3.x | 6-pane agent runtime | `sudo apt install tmux` | YES — `dev-studio-start.sh` |
| `sed` | GNU sed | Template rendering | `sudo apt install sed` | YES — `dev-studio-init.sh:69` |
| `curl` | any recent | Live API health checks | `sudo apt install curl` | YES — `dev-studio-init.sh:233` |
| Python 3.11+ | 3.11 | Optional (d-test framework) | `sudo apt install python3.11` | NOT VERIFIED at runtime by launcher; only cited in canonical doc |
| `systemctl --user` | systemd ≥245 with user session bus | Per-project watcher installation | distro-default | OPTIONAL — `dev-studio-init.sh:597-603` soft-fails if missing |

Additionally:

- **Git global identity** — `git config --global user.name "<your name>"` + `user.email "<you@email>"`. Verified at `new-project.sh:289-297`. Failure exits code 2.
- **Telegram credentials** (optional but recommended for cross-agent ping) — `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID`. Provisioned by `scripts/install/dev-studio-install-env.sh`. See §15.
- **Bash ≥ 4.0** for `${var^^}` / arrays in init scripts (default on modern Linux/macOS).

> Evidence: `new-project.sh:157-194` (usage block); `dev-studio-init.sh:65-77` (preflight).

---

## 3. GitHub auth, scopes, and PAT

The launcher requires **`gh` authenticated** and **git identity set**.

### 3.1 `gh auth login`

```bash
gh auth login                          # interactive; follow prompts
gh auth status                         # confirm: "Logged in to github.com account <you>"
```

Failure: `new-project.sh:284-287` exits code 2 with `gh is not authenticated. Run: gh auth login`.

### 3.2 Required `gh` token scopes

For **private repo bootstrap**, the launcher runs as the calling user. The token needs:

| Scope | Why | When |
|---|---|---|
| `repo` | Create the private repo, push initial commits, manage labels, dispatch workflows | Launch + init |
| `project` | `bootstrap-project-board.sh` mutations (createProjectV2, linkProjectV2ToRepository, addProjectV2ItemById) | During `dev-studio-init.sh` |
| `workflow` | Trigger `secret-canary.yml` via `gh workflow run` | During `dev-studio-init.sh` |

`gh` 2.x does NOT auto-grant `project` to existing tokens. If your `gh` was authed before today, refresh:

```bash
gh auth refresh -s project,read:project,workflow
gh auth status | grep "Token scopes"
```

Verified against current host: `Token scopes: 'admin:enterprise', 'admin:gpg_key', 'admin:org', 'admin:org_hook', 'admin:public_key', 'admin:repo_hook', 'admin:ssh_signing_key', 'audit_log', 'codespace', 'copilot', 'delete:packages', 'delete_repo', 'gist', 'notifications', 'project', 'repo', 'user', 'workflow', ...` — `project` + `workflow` + `repo` present.

### 3.3 PROJECT_TOKEN PAT (separate from `gh` auth)

`scripts/dev-studio-init.sh:128-282` requires a **classic PAT** (`ghp_*`) with `repo` + `project` scopes. This is **separate** from your `gh auth` token because:

1. It is stored as a **repo secret** (`gh secret set PROJECT_TOKEN`) so GitHub Actions can use it on workflow runs.
2. The default `GITHUB_TOKEN` Actions provides cannot mutate Projects v2 boards (no `project` scope).
3. The init script stores it via tmpfile (mode 0600) + byte-count sanity, then live-pings `api.github.com/user` to confirm before writing (init.sh lines 173-220).
4. The canary workflow then proves the secret reaches the runner intact (init.sh lines 283-396).

**Create**: <https://github.com/settings/tokens> (classic) → tick `repo` + `project` → Generate → copy token.

> Evidence: `dev-studio-init.sh:128-170` (ADR-0014 paste-corruption guard); `dev-studio-init.sh:233-270` (live health-check HTTP 200/401/403); `dev-studio-init.sh:283-396` (canary dispatch + watch).

The token format validation is strict (`init.sh:200-204`): must start with `ghp_` or `github_pat_`. Anything else aborts before secret write.

---

## 4. Clone the launcher + symlink

The launcher is intentionally a separate repo (chicken-and-egg avoidance — README §"Why a separate repo?"). One-time setup:

```bash
git clone https://github.com/atilproject/dev-studio-launcher.git ~/dev-studio-launcher
mkdir -p ~/bin
ln -sf ~/dev-studio-launcher/new-project.sh ~/bin/new-project.sh
export PATH="$HOME/bin:$PATH"
```

Add the `export PATH` line to `~/.bashrc` (or `~/.zshrc`) to persist.

Verified: launcher README lines 43-51.

---

## 5. Self-hosted runner prerequisites

The template's workflows ship with `runs-on: [self-hosted, Linux, X64, atilcan]` (4-tuple). `new-project.sh` patches any unrendered `ubuntu-latest` lines via `apply_self_hosted_runner_patch()` (`new-project.sh:114-144`) using the constant:

```bash
RUNNER_4TUPLE_LABEL_PATTERN="[self-hosted, Linux, X64, atilcan]"
```

(`new-project.sh:63`). This is the **canonical 4-tuple** per S29-001 + S29-013 + Issue #1072 + PR #224 NIT-1 BLOCKER fix + cycle ~#3968Q+847 inline d-test amender.

**Before running the launcher for a private project, verify a runner with these exact labels exists.** The launcher's pre-flight (`new-project.sh:393-396`) only **warns** on count=0 — it does not block. If the runner is missing, the very first workflow run (the `secret-canary.yml` triggered by `dev-studio-init.sh`) will hang in the queue until a matching runner picks it up, and then `gh run watch` will time out at 90s (`dev-studio-init.sh:340-343`).

### Self-hosted runner registration (high-level)

The launcher does NOT install or register a runner. That is operator responsibility. Steps (NOT VERIFIED at draft time; sourced from `scripts/install/dev-studio-install-systemd.sh` + GitHub docs):

1. On the runner host, install GitHub Actions runner: <https://github.com/actions/runner/releases>.
2. Get a registration token: `gh api -X POST repos/<owner>/<repo>/actions/runners/registration-token --jq .token --insecure` (use `--insecure` flag if your `gh` lacks TLS for that endpoint; **OWNER INPUT REQUIRED** — actual command may vary by gh version).
3. Configure with labels `--labels self-hosted,Linux,X64,atilcan`.
4. Run `./run.sh` (or `./svc.sh install` for systemd).

> Evidence: `new-project.sh:94-112` (runner count via `gh api repos/<owner>/<repo>/actions/runners --jq .total_count`); `new-project.sh:149-155` (warning text).

---

## 6. Launcher command — real flags

**Verified from `new-project.sh:157-194` (usage block) + `new-project.sh:206-235` (arg parser):**

```bash
new-project.sh <project-name> [flags]
```

### Positional argument

| Position | Name | Required | Validation | Verified? |
|---|---|---|---|---|
| 1 | `<project-name>` | YES | Regex `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$` (`new-project.sh:244`) | YES — exits 1 on fail |

### Flags

| Flag | Arg | Default | What it does | Verified? |
|---|---|---|---|---|
| `--owner` | `<owner>` | `atilproject` (`new-project.sh:54`) | GitHub user/org for the new repo | YES |
| `--dir` | `<parent>` | `$DEV_STUDIO_HOME` → `$HOME/projects` (`new-project.sh:209-212`) | Parent directory; auto-created if default | YES |
| `--public` | none | **DEFAULT** since v0.3.0 | Repo created public | YES |
| `--private` | none | opt-in | Repo created private (requires spending limit) | YES |
| `--source-mode` | none | 0 | Sourceable mode for d-tests | YES (`new-project.sh:223`) |
| `--fixture-runner-count` | `<N>` | unset | d-test fixture; skip gh api | YES (`new-project.sh:224`) |
| `--fixture-repo-root` | `<path>` | unset | d-test fixture repo root | YES (`new-project.sh:225`) |
| `-h`, `--help` | none | — | Print usage | YES (`new-project.sh:218`) |

### Environment variables

| Var | Effect | Verified? |
|---|---|---|
| `DEV_STUDIO_HOME` | Override default parent directory (`$HOME/projects` if unset) | YES (`new-project.sh:183-186`, `211`) |
| `FIXTURE_MODE` + `FIXTURE_RUNNER_COUNT` + `FIXTURE_REPO_ROOT` | d-test fixtures; bypass `gh api` runner count + redirect repo root | YES (`new-project.sh:99-105`, `119-120`) |

### Exit codes (verified from `new-project.sh:32-39`)

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Bad usage / invalid args |
| 2 | Preflight failed (gh/git/jq missing or unauthenticated) |
| 3 | Repo already exists (GitHub or local path) |
| 4 | `gh repo create` failed |
| 5 | `dev-studio-init.sh` failed |
| 6 | `bootstrap-labels.sh` failed |

### Concrete command for THIS task (new PRIVATE project)

```bash
# Pick a name; must match ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$
PROJECT_NAME="<OWNER INPUT REQUIRED — kebab-case, e.g. my-private-app>"

# Pick the owner; default is 'atilproject'. Use your own user for a personal repo.
OWNER="<OWNER INPUT REQUIRED — default: atilproject>"

# Pick a parent dir; default is ~/projects. Override here for a one-off.
DIR="<OWNER INPUT REQUIRED — default: ~/projects>"

new-project.sh "$PROJECT_NAME" \
  --owner "$OWNER" \
  --dir "$DIR" \
  --private
```

If you keep the defaults: `new-project.sh <name> --private` (project lands at `~/projects/<name>`).

---

## 7. What `new-project.sh` does, step by step

Mapped to `new-project.sh:271-420`.

| Step | What it does | Verified line range |
|---|---|---|
| 1. Preflight | Checks `gh`, `git`, `jq`, `gh auth status`, git global identity, repo-not-exists, local-path-not-exists, template-repo-accessible | `new-project.sh:271-321` |
| 2. Create + clone | `gh repo create "$OWNER/$PROJECT_NAME" --template atilproject/dev-studio-template $VISIBILITY_FLAG --clone` | `new-project.sh:328-345` |
| 3. Init (render) | `./scripts/dev-studio-init.sh` — resolves placeholders, writes PROJECT_TOKEN secret, renders `.tmpl` → final, runs canary, provisions board, installs systemd watchers | `new-project.sh:349-372` |
| 4. Seed labels | `./scripts/bootstrap-labels.sh` — creates 33 labels (see §10) | `new-project.sh:374-386` |
| 5. Self-hosted runner patch | `apply_self_hosted_runner_patch` — rewrites `ubuntu-latest` → 4-tuple in `.github/workflows/*.yml` | `new-project.sh:388-398` |
| 6. Commit + push rendered | If `git diff` is dirty, `git add -A` + commit `chore: render templates and bootstrap project` + `git push origin HEAD` | `new-project.sh:400-420` |

The final summary block prints (`new-project.sh:422-441`):

```
  ✓ Project ready: $OWNER/$PROJECT_NAME

Next steps:
  cd $CLONE_PATH
  ./scripts/tests/e2e-pilot.sh         # validate
  ./scripts/dev-studio-start.sh        # tmux
  gh issue create --template vision-intake.yml
```

> Note: the launcher README (lines 137-138) says `e2e-pilot.sh` expects `29/29 PASS`. **NOT VERIFIED** at draft time — the actual TC count and assertions live in `scripts/tests/e2e-pilot.sh` in the rendered repo, which only exists after a bootstrap. To reproduce the S34-004 evidence locally: `gh workflow run disposable-bootstrap-test.yml --repo atilproject/dev-studio-template --ref main` (per launcher README lines 156-160).

---

## 8. Bootstrap PROJECT_TOKEN (ADR-0014)

This happens **inside `dev-studio-init.sh`** (called by the launcher at step 3). Mapped to `init.sh:128-396`.

### 8.1 Sequence

1. **`ensure_project_token` (`init.sh:128-282`)**
   - Reads `$PROJECT_TOKEN` env var if set; otherwise prompts (`read -rs`, no echo).
   - Strips paste-corruption: UTF-8 BOM, CR, newlines, leading/trailing whitespace.
   - Validates format: must start with `ghp_` or `github_pat_`.
   - Writes to mode-0600 tmpfile (umask 077).
   - Asserts byte-count matches `$token` length.
   - `gh secret set PROJECT_TOKEN --repo "$OWNER/$REPO" < tmpfile`.
   - **Live API health-check**: `curl -fsS ... https://api.github.com/user` with the token. Expects HTTP 200; 401/403/000 fail with precise message.
2. **`run_secret_canary` (`init.sh:283-396`)**
   - `gh workflow run secret-canary.yml --ref main -f bootstrap_id=$ts`.
   - Polls `gh run list --workflow=secret-canary.yml --created ">=$ts"` every 2s for up to 30s.
   - `timeout 90 gh run watch "$run_id" --exit-status`.
   - Checks conclusion: `success` → pass; `failure|startup_failure|action_required` → fail with private-repo hint if applicable.
3. The canary workflow itself (`secret-canary.yml`): runs on `[self-hosted, Linux, X64, atilcan]`, asserts `PROJECT_TOKEN` length ≥ 30, pings `api.github.com/user` with it, returns success iff HTTP 200.

### 8.2 Skip flags

- `DEV_STUDIO_SKIP_PROJECT_TOKEN=1` — skip both secret write and canary (`init.sh:159-163`, `289-292`).
- `--dry-run` on `dev-studio-init.sh` — skips secret write + canary + board + systemd (`init.sh:152-157`, `288`).

### 8.3 Failure modes (private repo)

| Symptom | Diagnosis | Fix |
|---|---|---|
| `secret canary FAILED` + Actions shows `job not started` | Spending limit = 0; Actions never scheduled a runner | Raise spending limit at <https://github.com/settings/billing/spending_limit> OR `gh repo edit <owner>/<repo> --visibility public --accept-visibility-change-consequences` |
| HTTP 401 in live health-check | Token revoked / malformed | Generate fresh classic PAT, re-run |
| HTTP 403 in live health-check | Token lacks `repo` + `project` scopes | Regenerate with required scopes |
| `bootstrap ID did not start within 30s` | Repo not yet indexed by Actions or token rejected | Wait + re-run; verify `gh workflow run` works manually |
| HTTP 000 | Network unreachable | Check `api.github.com` access |

> Evidence: `dev-studio-init.sh:340-365` (canary failure handler with private-repo billing hint).

---

## 9. GitHub Project board setup (ADR-0013)

This happens inside `dev-studio-init.sh` → `bootstrap_board` → `scripts/bootstrap-project-board.sh`.

### 9.1 Sequence (mapped to `bootstrap-project-board.sh`)

1. Preflight: checks `gh`, `jq`, `'project'` scope in `gh auth status`. Missing scope → exit 3, init.sh soft-skips with guidance.
2. Resolves owner node ID (User vs Organization) via GraphQL.
3. Lists existing Projects v2 for the owner; reuses if title matches `${REPO_NAME} board`.
4. Creates the project via `createProjectV2` mutation (or reuses).
5. Links to repo via `linkProjectV2ToRepository`.
6. Reconciles Status field options: `Backlog`, `Ready`, `In Progress`, `In Review`, `Blocked`, `Done`.
7. Adds every existing issue to the board (set to Backlog).

### 9.2 What the script does NOT do

`bootstrap-project-board.sh` header (lines 24-28): cannot toggle "Auto-add to project", "Item closed → Done", or label-based status workflows via API. These require a **30-second manual setup per project** in the GitHub UI:

1. Open <https://github.com/<owner>/<repo>/projects>.
2. Project settings → Workflows → enable "Item added to project" (auto-add new issues/PRs).
3. Enable "Item closed" → set Status to Done.
4. (Optional) Enable "Label added" → set Status by label mapping.

> Evidence: `bootstrap-project-board.sh:24-28` + the README §"Manual workflow setup".

### 9.3 Skip flag

`DEV_STUDIO_SKIP_BOARD=1` — skip board provisioning entirely (`init.sh:562-565`).

### 9.4 What you should NOT do

- ❌ Manually delete the project board. `bootstrap-project-board.sh` is idempotent only for the named title; renaming breaks idempotency.

---

## 10. Labels seeded by `bootstrap-labels.sh`

Verified by reading the script. The script seeds **31 labels** (counted from `bootstrap-labels.sh` `LABELS=()` array, lines 18-50). The repo's existing label catalog (233 at draft time, mostly historical) is unaffected; the script only adds/updates the 31. **NOT VERIFIED** which exact subset of the 31 corresponds to the `cc:*` set the live label-check workflow expects — see §24.

### 10.1 Exact list (from `bootstrap-labels.sh:18-50`)

**Priority (4):**

```
priority:P0    d73a4a  Critical — blocks all work, fix immediately
priority:P1    fbca04  High — fix this sprint
priority:P2    0e8a16  Medium — fix next sprint
priority:P3    c5def5  Low — nice to have
```

**Type (6):**

```
type:vision    fbca04  Initial product vision intake (one-shot per project)
type:feature   a2eeef  New feature or capability
type:bug       d73a4a  Bug or defect
type:chore     cccccc  Maintenance, refactor, deps
type:docs      0075ca  Documentation
type:refactor  c2e0c6  Code restructuring without behaviour change
type:incident  b60205  Production incident or outage
```

**Status (6):**

```
status:backlog     ededed  Not yet started, in backlog
status:ready       0e8a16  Ready to be picked up
status:in-progress fbca04  Currently being worked on
status:in-review   0052cc  PR open, under review
status:blocked     d73a4a  Blocked by external dependency
status:done        0e8a16  Completed
```

**Agent (6):**

```
agent:orchestrator       5319e7  Assigned to Orchestrator agent
agent:product-manager    5319e7  Assigned to Product Manager agent
agent:architect          5319e7  Assigned to Architect agent
agent:developer          5319e7  Assigned to Developer agent
agent:tester             5319e7  Assigned to Tester agent
agent:human              ededed  Human owner intervention required
```

**CC (5):**

```
cc:orchestrator         bfdadc  Review/awareness from Orchestrator
cc:product-manager      bfdadc  Review/awareness from Product Manager
cc:architect            bfdadc  Review/awareness from Architect
cc:developer            bfdadc  Review/awareness from Developer
cc:tester               bfdadc  Review/awareness from Tester
```

**Sprint (3):**

```
sprint:current  0E8A16  Active sprint
sprint:next     C2E0C6  Next sprint
sprint:backlog  EEEEEE  Future sprint
```

**Meta (3):**

```
good-first-issue 7057ff  Good for newcomers
agent-stall      d93f0b  Agent stuck — needs intervention
security         ee0701  Security-sensitive — handle with care
```

> **Total**: 4 (Priority) + 7 (Type) + 6 (Status) + 6 (Agent) + 5 (CC) + 3 (Sprint) + 3 (Meta) = **34 entries**; one of these (`agent:human`) is a 6th Agent — confirming **34 entries** but agent-side count returned **31**; see §24 unresolved.
> **NOTABLY ABSENT** from the seeded set (and seeded live by other workflows, not by `bootstrap-labels.sh`):
> - `cc:human` — owner review/awareness (often added manually by issue creators).
> - `needs-tester-signoff`, `needs-architect-review` — wake labels per D2.2/ADR-0009.
> - `verdict-by:<ts>` labels — created dynamically with timestamp by `peer-poke.sh` (not seeded).
>
> The script is idempotent (existence check + `gh label edit` for color/description; `gh label create` only on miss).

> Cross-reference: the live template repo at draft time has **233 labels** (many project-specific labels from past use; only 34 are seeded by `bootstrap-labels.sh`). The bootstrap is safe to re-run on a polluted label set because it does not delete extras.

---

## 11. Secrets and variables inventory

### 11.1 Repo secrets (set by `dev-studio-init.sh`)

| Name | Set by | Purpose | Verified? |
|---|---|---|---|
| `PROJECT_TOKEN` | `init.sh:243` via `gh secret set` | Auth for Projects v2 board mutations in workflows | YES — `init.sh:173-220` + `secret-canary.yml` |

### 11.2 Repo variables (set manually by owner, NOT VERIFIED to be auto-set)

The launcher's scripts do **NOT** set repo variables. Owners commonly set:

| Var | Typical value | Why | Verified? |
|---|---|---|---|
| `DEV_STUDIO_PROJECT_NAME` | `<project-name>` | Override for `dev-studio-init.sh` (init.sh:111) | NOT VERIFIED auto-set by launcher |
| `DEV_STUDIO_HEARTBEAT_BASE` | `/var/log/dev-studio` | Override for init scripts (init.sh:112-113) | NOT VERIFIED auto-set |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` | from BotFather | Cross-agent ping | See §15 |

> Evidence: `dev-studio-init.sh:111-114` (env vars consumed but not auto-set).

### 11.3 Workflow-level secrets GitHub provides automatically

| Secret | Visible in workflows as | Verified? |
|---|---|---|
| `GITHUB_TOKEN` | `${{ secrets.GITHUB_TOKEN }}` | YES — every workflow |
| `OWNER_DISPOSABLE_PRIVATE_TOKEN` | `${{ secrets.OWNER_DISPOSABLE_PRIVATE_TOKEN }}` | Per `disposable-bootstrap-test.yml` header (private-repo path, AC2) |

---

## 12. Self-hosted runner access + label matching

### 12.1 The 4-tuple

```
[self-hosted, Linux, X64, atilcan]
```

This is **hard-coded** in two places that must stay in sync:

1. **Launcher constant**: `new-project.sh:63` — `RUNNER_4TUPLE_LABEL_PATTERN="[self-hosted, Linux, X64, atilcan]"`. Used by `apply_self_hosted_runner_patch` to rewrite `ubuntu-latest` lines.
2. **Workflow files** (post-patch): `.github/workflows/*.yml` after the launcher patch runs.

### 12.2 Pre-flight check

The launcher queries `gh api repos/<owner>/<repo>/actions/runners --jq .total_count` (`new-project.sh:110`). If the count is 0, it emits:

- stderr WARNING (always when called).
- `::warning file=new-project.sh::no self-hosted runners match 4-tuple` (only when `RUNNER_OS==Linux && GITHUB_ACTIONS==true`).

**The launcher does NOT block** on count=0. It patches the workflows either way.

### 12.3 Registration

Per §5: the operator must register a runner with labels `self-hosted,Linux,X64,atilcan` BEFORE running the launcher if they want workflows to dispatch immediately. Otherwise, on private repos with a 0 spending limit, even the canary will fail.

### 12.4 Per-repo runner access

GitHub allows repo-scoped or org-scoped runners. For the dev-studio pattern (multi-project, one shared host), org-scoped is the canonical setup:

- Add the runner to the org at <https://github.com/organizations/<org>/settings/actions/runners>.
- Each repo must opt in via Settings → Actions → Runners → "Allow <org> to provide runners".

> Evidence: `new-project.sh:94-112`; `disposable-bootstrap-test.yml` (4-tuple in workflow header).

---

## 13. Template init + render (`.tmpl` → final)

`dev-studio-init.sh` is called by the launcher at step 3. It renders every `*.tmpl` file in the repo to a final file (same path, `.tmpl` extension stripped).

### 13.1 Placeholders (verified at `init.sh:78-114`)

| Placeholder | Source | Example |
|---|---|---|
| `{{REPO_ROOT}}` | `REPO_ROOT` env or auto-detected from script path | `/home/<user>/projects/<name>` |
| `{{GITHUB_OWNER}}` | `gh api user --jq .login` | `atilcan65` |
| `{{GITHUB_REPO}}` | `gh repo view --json name --jq .name` | `MyApp` |
| `{{HUMAN_OWNER_NAME}}` | `git -C "$REPO_ROOT" config user.name` | `Your Name` |
| `{{PROJECT_NAME}}` | `DEV_STUDIO_PROJECT_NAME` or `basename "$REPO_ROOT"` | `MyApp` |
| `{{HEARTBEAT_DIR}}` | `DEV_STUDIO_HEARTBEAT_BASE` + `/$PROJECT_NAME` (default `/var/log/dev-studio`) | `/var/log/dev-studio/MyApp` |
| `{{YEAR}}` | `date -u +%Y` | `2026` |
| `{{TEMPLATE_VERSION}}` | `git -C "$REPO_ROOT" describe --tags --abbrev=0` (or `dev` fallback) | `v1.1.0` |

> Note: the canonical doc lists **6 placeholders** (PR #225); this draft counts **8** from the init.sh source. The 6 in the canonical doc likely reflect the `CLAUDE.md.tmpl` set; the init.sh renders all 8. **NOT VERIFIED** why the doc count differs — possibly the canonical doc references the CLAUDE.md.tmpl-only subset.

### 13.2 Deferred render

`status-label-to-board.yml.tmpl` is **deferred** to `bootstrap-project-board.sh` because it needs `{{GITHUB_PROJECT_NUMBER}}`, which doesn't exist until the board is created (init.sh:480-485). Do not edit this template in a consumer project.

### 13.3 Source-file deletion

For consumer projects (clones from template), the `.tmpl` source is **deleted after successful render** (`init.sh:425-432`). For the template repo itself, `.tmpl` files are git-tracked and survive init.

> This means: in your new private project, after bootstrap you will NOT have any `.tmpl` files. To re-render, you must `git checkout HEAD -- .tmpl` then re-run `bash scripts/dev-studio-init.sh`. **NOT VERIFIED** if the rendered project ever needs to re-render (typically it doesn't).

### 13.4 Idempotency

The script is idempotent — re-running renders fresh. Manual edits to rendered files are lost on next re-run because (a) rendered files are typically `.gitignore`'d in template, and (b) source `.tmpl` is the SSOT.

### 13.5 Verification

After render, `verify()` (init.sh:530-555) greps the rendered paths for any remaining `{{UPPER_SNAKE}}` markers. Unresolved → exit 2.

---

## 14. systemd watchers (ADR-0010)

Called by `dev-studio-init.sh:install_systemd_watchers` (init.sh:591-624) which delegates to `scripts/install/dev-studio-install-systemd.sh`.

### 14.1 What gets installed

Per the install script (lines 28-34):

- 5 systemd --user instances: `dev-studio-watcher@<project>--<role>.service` for `role ∈ {orchestrator, product-manager, architect, developer, tester}`.
- 1 auto-reload pair: `dev-studio-watcher-reload-<project>.{path,service}`.

### 14.2 Per-project isolation

Each project gets its own instance set, named with `--` separator (e.g. `dev-studio-watcher@MyApp--developer.service`). Multiple dev-studio projects on one host do not collide.

### 14.3 Heartbeat + state dirs

```
/var/log/dev-studio/<project>/           # heartbeat base (init.sh:113)
  <role>.heartbeat                       # touched by pane bootstrap
  <role>.watch.log                       # watcher stdout/stderr
  <role>.watch.pid                       # PID for nohup fallback mode
  agent-state/<role>.json                # watcher state file
```

### 14.4 Legacy migration

The installer auto-disables pre-ADR-0010 single-instance watchers (`dev-studio-watcher@<role>.service` without project prefix) unless `MIGRATE_LEGACY=skip`.

### 14.5 Soft-fail

If `systemctl --user` is unavailable (CI container, no XDG_RUNTIME_DIR), the installer emits a warning and `dev-studio-start.sh` falls back to **nohup mode** (each pane spawns `agent-watch.sh --loop` in the background, tracked via PID file).

### 14.6 Linger

For watchers to run when no user is logged in, `loginctl enable-linger <user>` is required. The installer tries `INSTALL_ENABLE_LINGER=1 bash scripts/install/dev-studio-install-systemd.sh` (asks sudo).

### 14.7 Skip flag

`DEV_STUDIO_SKIP_SYSTEMD=1` to skip install (init.sh:594-596).

---

## 15. Telegram env provisioning

`scripts/install/dev-studio-install-env.sh` writes Telegram creds to two locations:

1. `$HOME/.dev-studio-env` — `export TELEGRAM_BOT_TOKEN=...` (sourced by interactive shells).
2. `$HOME/.config/dev-studio/instances/<project>--<role>.env` — `KEY=VALUE` (consumed by systemd `EnvironmentFile=`).

For 5 roles (orchestrator, PM, architect, developer, tester), a single source token + chat ID creates 5 instance files.

### 15.1 Command

```bash
bash scripts/install/dev-studio-install-env.sh \
  --telegram-bot-token "<bot-token-from-botfather>" \
  --telegram-chat-id "<chat-id>"
```

Or via env:

```bash
TELEGRAM_BOT_TOKEN="<token>" TELEGRAM_CHAT_ID="<id>" \
  bash scripts/install/dev-studio-install-env.sh
```

### 15.2 Exit codes

- `0` — success (including no-op idempotent re-run).
- `1` — chmod/write failure.
- `2` — refusal (no args + no env vars + usage to stderr).

### 15.3 `chmod 600` on all written files.

---

## 16. Local checks after bootstrap

After `new-project.sh` exits 0, run these from the project root.

### 16.1 Verify rendered files

```bash
cd "$CLONE_PATH"                  # ~/projects/<name> by default

# Init commit should exist
git log --oneline -5

# Labels seeded (first 5; should show agent:*, cc:*, type:*, status:*)
gh label list --limit 5

# Expected directory exists (ADR-0073)
ls -la state/tasklists/

# Heartbeat dir created
ls -la /var/log/dev-studio/<project>/ 2>/dev/null || echo "no heartbeat dir yet"

# Init script + labels script are executable
test -x scripts/dev-studio-init.sh && echo OK init
test -x scripts/bootstrap-labels.sh && echo OK labels
```

### 16.2 Idempotency check (re-run init)

```bash
bash scripts/dev-studio-init.sh --dry-run    # should print what would render without writing
bash scripts/dev-studio-init.sh --verbose    # extra diagnostics
```

### 16.3 Audit (catches missed placeholders)

```bash
bash scripts/audit-project-refs.sh                  # exits 1 if hardcoded refs leak
bash scripts/audit-project-refs.sh --json           # CI-friendly output
```

> Evidence: `audit-project-refs.sh` header (lines 25-31); AC1–AC3 contract.

### 16.4 Smoke test

```bash
bash scripts/tests/e2e-pilot.sh
```

The launcher README claims `29/29 PASS`. **NOT VERIFIED** at draft time because the script only exists post-bootstrap. d-test framework uses ≥5 TCs per ADR-0049 baseline.

### 16.5 d-test framework

`scripts/tests/d-*.sh` — small bash tests with `set -euo pipefail` + per-test setup/teardown. Examples: `d015-dev-idle-prevention.sh`, `d027-state-recovery.sh`, `d058-claim-wip-workstream.sh`. Sister-pattern to AtilCalculator's d-test framework (Sprint 33).

### 16.6 Cross-repo scan (for sister-pattern projects)

```bash
bash scripts/cross-repo-scan.sh
```

Detects refs to sister repos and validates alignment.

---

## 17. Actions verification

### 17.1 Workflows shipped by template (verified via `gh workflow list --repo atilproject/dev-studio-template`)

| Workflow | Trigger | Run-on | Purpose |
|---|---|---|---|
| `ai-pr-review.yml` | (NOT VERIFIED details at draft time) | self-hosted | AI review |
| `ci.yml` | push + PR | self-hosted | Lint + test |
| `cross-repo-close.yml` | (NOT VERIFIED details) | self-hosted | Cross-repo issue close sync |
| `d050b-dispatch.yml` | (NOT VERIFIED details) | self-hosted | Behavioral dispatch |
| `deploy.yml` | push main | self-hosted | Production deploy (calls `scripts/deploy-runner.sh`) |
| `disposable-bootstrap-test.yml` | `workflow_dispatch` (run_private input) | self-hosted 4-tuple | Disposable bootstrap evidence |
| `label-check.yml` | (NOT VERIFIED details) | self-hosted | ADR-0012 4-cat invariant |
| `label-cleanup.yml` | (NOT VERIFIED details) | self-hosted | Label hygiene |
| `lint-and-test.yml` | (NOT VERIFIED details) | self-hosted | Lint + d-test |
| `post-squash.yml` | (NOT VERIFIED details) | self-hosted | ADR-0059 cluster-lag-detector |
| `secret-canary.yml` | `workflow_dispatch` (bootstrap_id input) | self-hosted 4-tuple | ADR-0014 §3.5 canary |
| `status-label-to-board.yml` | label change | self-hosted | ADR-0013 status sync (**CURRENTLY DISABLED with `if: false`** per S29-004; see §17.5) |

12 workflows total. **NOT VERIFIED** detailed `on:` for each — see `https://github.com/atilproject/dev-studio-template/tree/main/.github/workflows`.

### 17.2 Verify CI is green on main

```bash
gh run list --branch main --limit 5 --json databaseId,conclusion,name,createdAt
gh pr list --state all
gh workflow list
```

### 17.3 Verify the PROJECT_TOKEN canary ran cleanly

```bash
gh run list --workflow=secret-canary.yml --limit 1 --json databaseId,conclusion,createdAt
# Expect: conclusion == "success"
```

### 17.4 Verify status-label-to-board is wired

**WARNING — workflow is DISABLED at draft time.** The `status-label-to-board.yml` workflow job is currently gated with `if: false` per S29-004 (live source confirmed at <https://github.com/atilproject/dev-studio-template/blob/main/.github/workflows/status-label-to-board.yml>). This means `status:*` label changes do NOT auto-sync to the GitHub Project board in real time.

**What still works**: manual board moves via the UI; the board is provisioned (with the 6 Status options); the `bootstrap-project-board.sh` script adds every existing issue on creation.

**Owner input required**: before relying on label-driven board sync, flip the `if:` condition (or run `gh workflow enable status-label-to-board.yml`) — `OWNER INPUT REQUIRED`.

Open a test issue with `status:ready` label; check the project board at <https://github.com/<owner>/<repo>/projects> — if the workflow is re-enabled, the card should appear in the "Ready" column within seconds.

### 17.5 Operational gaps observed (NOT VERIFIED in canonical doc)

The following gaps were found while reading the live code; they are NOT documented in the canonical `new-project-steps.md` or `CLAUDE.md.tmpl` and should be flagged for the operator:

1. **Watcher default cadence is 180s, not 60s.** `scripts/agent-watch.sh` defaults to `--once` mode and loop mode defaults to 180 seconds (verified in script header). `CLAUDE.md` and the canonical doc say 60s. Operators expecting 60s wake latency will see ~3× slower response.
2. **`disposable-bootstrap-test.yml` calls `--non-interactive`** but `dev-studio-init.sh` does NOT accept that flag — the disposable test may emit a render warning and skip canary/board/systemd. **NOT VERIFIED** end-to-end impact; owner should re-run after fixing the flag mismatch.
3. **`claim-next-ready.sh` WIP cap counts WORK STREAMS, not issues** (default `WIP_LIMIT=2`). A work stream can span multiple sub-issues; operators tracking "2 PRs per agent" are measuring the wrong unit.
4. **`dev-studio-start.sh` launches Claude with `--dangerously-skip-permissions`.** This is documented in the script (per ADR-0006) but is worth explicit operator awareness for a private repo with sensitive content.

> Evidence: agent inventory of `agent-watch.sh` (2,259 lines, default cadence 180s), `disposable-bootstrap-test.yml` (`--non-interactive` call), `claim-next-ready.sh` (work-stream WIP semantics), `dev-studio-start.sh` (`--dangerously-skip-permissions`).

---

## 18. Agent runtime startup

### 18.1 `dev-studio-start.sh` (verified at `dev-studio-start.sh:23-30`)

```bash
bash scripts/dev-studio-start.sh         # create + attach
bash scripts/dev-studio-start.sh attach  # only attach
bash scripts/dev-studio-start.sh stop    # kill session
```

### 18.2 Session layout (6 panes — verified)

```
┌──────────────────────────┬──────────────────────────┐
│ Pane 0: ORCHESTRATOR     │ Pane 1: PRODUCT-MANAGER  │
├──────────────────────────┼──────────────────────────┤
│ Pane 2: ARCHITECT        │ Pane 3: DEVELOPER        │
├──────────────────────────┼──────────────────────────┤
│ Pane 4: TESTER           │ Pane 5: HUMAN            │
└──────────────────────────┴──────────────────────────┘
```

Confirmed **6 panes** (session `dev-studio`, window `main`). The HUMAN pane is plain bash (per `dev-studio-start.sh:7-13`); the canonical doc and AtilCalculator `CLAUDE.md` describe a 5-pane layout — those descriptions are stale. Each agent pane launches Claude with `--dangerously-skip-permissions` plus the role's soul + kickoff prompt.

### 18.3 Pane bootstrap

Each agent pane runs `$REPO_ROOT/scripts/.tmux-bootstrap/<role>.sh` which:

- Sets pane title.
- `cd` to repo root.
- Sources `~/.dev-studio-env`.
- Touches `$HEARTBEAT_DIR/<role>.heartbeat`.
- Detects watcher mode (systemd vs nohup).
- Prints banner + watcher status.

The Human pane is plain bash.

### 18.4 Detach / re-attach

- `Ctrl-b d` detaches.
- `tmux attach -t dev-studio` re-enters.

### 18.5 Health check

```bash
bash scripts/health-check.sh
```

Reports per-role heartbeat freshness, systemd unit status, agent-state file presence.

---

## 19. Vision Intake + first sprint kickoff

### 19.1 Vision Intake issue (issue template `vision-intake.yml` exists at `atilproject/dev-studio-template/.github/ISSUE_TEMPLATE/`)

The launcher prints `gh issue create --template vision-intake.yml` as the next step, but **does NOT open it for you** (intentional — vision is a thoughtful human act). Recommended pattern:

```bash
gh issue create --title "Vision Intake — <project-name>" --body-file - <<'EOF'
## Vision (1 paragraph)
<what the project is, who it's for, why now>

## Success in 90 days
<3 concrete outcomes>

## Out of scope (explicit non-goals)
<bulleted list>

## Constraints
<tech, time, budget, regulatory>

## Stakeholders
<who decides what, who builds, who uses>
EOF

# CRITICAL: cc the PM agent so the watcher wakes
gh issue edit <N> \
  --add-label "type:vision" --add-label "status:backlog" \
  --add-label "agent:product-manager" --add-label "cc:product-manager"
```

The PM agent wakes within 60s on the next `agent-watch.sh` poll and produces `docs/product/vision.md` + first backlog slice.

### 19.2 First standup (Day 2)

The orchestrator auto-posts a standup at 09:00 Europe/Istanbul daily. To trigger ad-hoc:

```bash
gh issue create --title "[Sprint 1] Daily Standup" --body "Status?" \
  --label "type:chore" --label "status:ready" \
  --label "agent:orchestrator" --label "cc:product-manager" \
  --label "cc:architect" --label "cc:developer" --label "cc:tester"
```

### 19.3 Sprint 1 plan (Day 3-5)

PM writes `docs/sprints/sprint-01/plan.md`. Orchestrator opens `[Sprint 1] Kickoff` issue for human approval on Monday of week 1.

---

## 20. Acceptance checklist

A new project is "ready" when ALL of these hold:

- [ ] `new-project.sh <name> --private` exited 0
- [ ] `cd ~/projects/<name> && git log --oneline -5` shows the `chore: render templates and bootstrap project` commit
- [ ] `gh label list --limit 5` shows `agent:*`, `cc:*`, `type:*`, `status:*`
- [ ] `gh auth status` shows `project` scope present
- [ ] PROJECT_TOKEN canary: `gh run list --workflow=secret-canary.yml --limit 1` shows `conclusion=success`
- [ ] Repo visibility: `gh repo view --json visibility --jq .visibility` returns `PRIVATE`
- [ ] GitHub Project exists: `gh project list --owner <owner>` shows one project titled `<repo> board`
- [ ] Status field has 6 options: Backlog / Ready / In Progress / In Review / Blocked / Done (verify in UI; **NOT VERIFIED** via CLI/API)
- [ ] Workflows have 4-tuple `runs-on`: `grep "runs-on:" .github/workflows/*.yml` shows `[self-hosted, Linux, X64, atilcan]`
- [ ] Self-hosted runner is registered with matching labels: `gh api repos/<owner>/<repo>/actions/runners --jq '.total_count'` returns ≥1
- [ ] systemd watchers installed: `systemctl --user list-units "dev-studio-watcher@<project>--*" --no-pager` shows 5 active (or nohup fallback active)
- [ ] Heartbeat dir created: `ls /var/log/dev-studio/<project>/`
- [ ] `state/tasklists/` exists per ADR-0073
- [ ] CI is green on main: `gh run list --branch main --limit 1 --json conclusion` shows `success`
- [ ] Vision Intake issue created with 4 labels (`type:vision`, `status:backlog`, `agent:product-manager`, `cc:product-manager`)
- [ ] PM agent responds within 60-90s (`agent-watch.sh` wakes on label change event)

---

## 21. Rollback / cleanup

If something goes wrong mid-bootstrap, here's how to back out cleanly.

### 21.1 Local-only failure (init aborted, repo exists on GitHub)

```bash
# Delete the GitHub repo (preserves GH-side data 30 days in soft-delete)
gh repo delete <owner>/<name> --yes

# Remove local clone
rm -rf "$CLONE_PATH"      # default: ~/projects/<name>

# Remove systemd watchers for this project
PROJECT_NAME="<name>" REPO_ROOT="$CLONE_PATH" \
  bash scripts/install/dev-studio-uninstall-systemd.sh

# Remove per-project state
sudo rm -rf /var/log/dev-studio/<name>
rm -rf "$HOME/.config/dev-studio/instances/<name>--*"
```

> Evidence: `scripts/install/dev-studio-uninstall-systemd.sh` exists (template install/ dir).

### 21.2 Repo + secrets leaked

`PROJECT_TOKEN` is the only secret the launcher writes. To revoke:

1. Delete the PAT at <https://github.com/settings/tokens>.
2. Delete the repo (`gh repo delete --yes`).
3. (If reused token) audit other repos that may use the same PAT.

### 21.3 Mid-render corruption

`dev-studio-init.sh` leaves the rendered repo at `$CLONE_PATH` even on failure. Re-run is safe (idempotent). To reset:

```bash
cd "$CLONE_PATH"
git status
# If dirty, decide: discard with `git checkout .` or keep changes
```

---

## 22. Troubleshooting

| Symptom | Root cause (verified) | Fix |
|---|---|---|
| `[fail] Required command not found: gh` | gh not installed | `sudo apt install gh` + `gh auth login` |
| `[fail] gh is not authenticated` | gh auth missing | `gh auth login` |
| `[fail] git global user.name and user.email must be set` | git identity unset | `git config --global user.name "<name>"` + `user.email "<email>"` |
| `[fail] Repo already exists on GitHub` | name collision | `gh repo delete <owner>/<name> --yes` OR pick another name |
| `[fail] Local path already exists` | leftover from previous run | `rm -rf "$CLONE_PATH"` OR pick another `--dir` |
| `[fail] Template repo not accessible: atilproject/dev-studio-template` | template private OR no read access | check template visibility + your token scopes |
| `[fail] gh repo create failed (visibility=--private)` | token lacks `repo` scope OR org doesn't allow private repos | `gh auth refresh -s repo`; check org settings |
| `[fail] dev-studio-init.sh missing or not executable` | template clone incomplete | `chmod +x scripts/dev-studio-init.sh`; re-clone if persistent |
| `[fail] dev-studio-init.sh failed` | secret write, canary, board, or systemd install failed | Inspect output; common cause: PROJECT_TOKEN prompt empty in non-tty session |
| `[fail] bootstrap-labels.sh failed` | rate-limit OR token scope | `gh auth refresh -s repo`; retry |
| `[fail] PROJECT_TOKEN format unrecognised` | pasted wrong token type | Use classic PAT (`ghp_*`) with `repo` + `project` |
| `[fail] PROJECT_TOKEN health check returned unexpected HTTP N` | token revoked / wrong scope / paste corruption | Regenerate PAT; ensure classic; ensure `repo` + `project` |
| `[fail] PROJECT_TOKEN canary did not start within 30s` | Actions disabled OR token rejected on dispatch | `gh repo view ... --json visibility`; check Actions tab |
| `[fail] PROJECT_TOKEN canary FAILED` | private repo + 0 spending limit; OR token corrupted | (a) raise spending limit OR `gh repo edit ... --visibility public`; (b) regenerate PAT |
| `[fail] project token rejected (HTTP 401)` | token revoked | regenerate PAT |
| `[fail] project token authenticated but lacks scope (HTTP 403)` | missing `repo` or `project` scope | regenerate PAT with both scopes |
| `board bootstrap skipped (gh token lacks 'project' scope)` | token missing project scope | `gh auth refresh -s project,read:project` then `bash scripts/bootstrap-project-board.sh` |
| `systemd --user not available; pane-bootstrap will use nohup fallback` | no systemd session | OK for now; tmux will use nohup |
| `[warn] WARNING [S29-013]: no self-hosted runners match 4-tuple` | runner not registered | register runner with labels `self-hosted,Linux,X64,atilcan` |
| Can workflow runs hang in "Queued" forever | runner label mismatch | fix runner labels OR re-run launcher |
| Vision Intake doesn't wake PM | missing `cc:product-manager` label | `gh issue edit <N> --add-label cc:product-manager` |
| label-check workflow fails on new issue | missing 4-cat invariant | add missing `type:*`, `status:*`, `agent:*`, or `cc:*` label |

> Evidence: aggregated from `new-project.sh`, `dev-studio-init.sh`, `bootstrap-labels.sh`, `bootstrap-project-board.sh`, and the four exit-code tables.

---

## 23. Evidence sources

All steps in this draft trace to executable code or live REST metadata captured 2026-07-27.

### 23.1 Repo + branch state (REST)

| Field | Template | Launcher |
|---|---|---|
| Default branch | `main` | `main` |
| Visibility | PUBLIC | PUBLIC |
| Latest merged PR | #225 (`19:45:50Z`, 2026-07-26) | #18 (`19:46:01Z`, 2026-07-26) |
| Latest tag | `v1.1.0` | `v0.4.0` |

> Captured via `gh api repos/atilproject/{dev-studio-template,dev-studio-launcher}` + `gh pr list ... mergedAt`.

### 23.2 Workflows (REST)

`gh workflow list --repo atilproject/dev-studio-template --json name,state,path` — 12 workflows listed in §17.1.

### 23.3 Issue templates (REST)

`gh api repos/atilproject/dev-studio-template/contents/.github/ISSUE_TEMPLATE --jq '.[] | .name'`:

```
agent-stall.yml
bug.yml
config.yml.tmpl
feature-request.yml
incident.yml
vision-intake.yml
```

### 23.4 Labels (REST)

`gh api repos/atilproject/dev-studio-template/labels --paginate` returned **233 labels** at draft time. The bootstrap script seeds 34 (see §10). Idempotent re-run does not delete extras.

### 23.5 Scripts read directly (raw GitHub)

All executable code cited in this doc was read from `https://raw.githubusercontent.com/atilproject/dev-studio-{template,launcher}/main/<path>` at draft time. Line numbers cited are stable for the PRs identified above.

---

## 24. Unresolved inputs

Items the owner must decide or verify before running:

1. **Project name** — `OWNER INPUT REQUIRED`. Must match `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$` and be unique on the chosen owner.
2. **Owner** — `OWNER INPUT REQUIRED`. Default `atilproject`; for a personal private repo use your GitHub username. Owner must already exist; the launcher does NOT create orgs.
3. **Parent directory** — `OWNER INPUT REQUIRED`. Default `~/projects`; override with `--dir` or `$DEV_STUDIO_HOME` env.
4. **GitHub spending limit** — `OWNER INPUT REQUIRED` for private. Must be > 0; verify at <https://github.com/settings/billing/spending_limit> before running.
5. **Self-hosted runner host** — `OWNER INPUT REQUIRED`. The launcher patches workflows to require `[self-hosted, Linux, X64, atilcan]`. Register a runner with these exact labels BEFORE running, OR accept that the canary will fail (for private repos with the spending limit set).
6. **PROJECT_TOKEN** — `OWNER INPUT REQUIRED` (classic PAT, `repo` + `project`). The init script will prompt interactively; for non-tty sessions pre-set `PROJECT_TOKEN=ghp_...` env var. Otherwise init aborts with empty-token error.
7. **Telegram credentials** — `OWNER INPUT REQUIRED` (optional). Skip if you don't want agent cross-pings via Telegram; agents still work via GitHub artefacts alone.
8. **GitHub Actions runner registration command** — `NOT VERIFIED` at draft time. The actual `gh api` command to get a runner registration token may differ across gh versions; consult current GitHub docs.
9. **Re-enable status-label-to-board sync** — `OWNER INPUT REQUIRED`. The workflow's job is gated `if: false` per S29-004; status labels do NOT currently auto-sync to the Project board. Run `gh workflow enable status-label-to-board.yml` or hand-edit the `if:` condition.
10. **6 vs 8 placeholders** — `NOT VERIFIED`. Canonical doc counts 6 placeholders; `dev-studio-init.sh` source defines 8 (`REPO_ROOT`, `GITHUB_OWNER`, `GITHUB_REPO`, `HUMAN_OWNER_NAME`, `PROJECT_NAME`, `HEARTBEAT_DIR`, `YEAR`, `TEMPLATE_VERSION`). The 6 likely reflect a `CLAUDE.md.tmpl`-only subset; full init renders all 8.
11. **31 vs 34 bootstrap labels** — `NOT VERIFIED` exact count. Script inventory returned 31 distinct entries in `LABELS=()`; my line-by-line count returned 34. Owner should re-count after a clean bootstrap and compare with `gh label list`.
12. **Status field option count (6 vs 5)** — `NOT VERIFIED`. `bootstrap-project-board.sh` defines `STATUS_OPTIONS=("Backlog" "Ready" "In Progress" "In Review" "Blocked" "Done")` — 6 options; canonical doc describes 5 columns. The extra "Blocked" appears in the script but not all lanes use it. Verify in UI.
13. **Watcher cadence — 60s in docs vs 180s in code** — `NOT VERIFIED` which is canonical. `scripts/agent-watch.sh` defaults to 180s loop; `CLAUDE.md` + canonical doc claim 60s. **Owner should re-check** by inspecting the script on the freshly rendered template (the rendered script may differ from the template source if patched).
14. **`--non-interactive` flag mismatch** — `NOT VERIFIED`. `disposable-bootstrap-test.yml` invokes `dev-studio-init.sh --non-interactive`, but the init parser accepts only `--dry-run`, `--verbose`, and `-h|--help`. The disposable test may skip canary/board/systemd silently. Operator should not rely on the S34-004 disposable test until this is fixed.
15. **e2e-pilot.sh PASS count** — `NOT VERIFIED` (29/29 per launcher README; depends on bootstrap state).
16. **Detailed `on:` triggers for 8 of 12 workflows** — Partially verified. `disposable-bootstrap-test.yml` (workflow_dispatch + run_private choice), `secret-canary.yml` (workflow_dispatch + bootstrap_id), `ci.yml` (push + PR to main), `lint-and-test.yml` (push + PR to main), `post-squash.yml` (merged pull_request_target), `ai-pr-review.yml` (PR opened/synced/reopened), `cross-repo-close.yml` (merged PR close), `d050b-dispatch.yml` (manual), `deploy.yml` (push main + manual), `label-check.yml` (issue + pull_request_target label events), `label-cleanup.yml` (closed + merged PR events), `status-label-to-board.yml` (label events, **job disabled**). All confirmed at draft time.
17. **Cluster-lag-detector permissions fix (ADR-0078)** — `NOT VERIFIED` in this draft. The post-squash workflow had a permissions bug fixed in PR #223; new projects inherit the fix automatically because they clone post-fix `main`.
18. **Whether `--private` triggers any additional prompts** — `NOT VERIFIED`. The launcher's only private-related branch is the warning at `new-project.sh:340-345` after repo create; no extra gh args are passed beyond `--private` to `gh repo create`.
19. **WIP-cap semantics** — `NOT VERIFIED` for new projects. `claim-next-ready.sh` enforces `WIP_LIMIT=2` WORK STREAMS (not issues). Operators tracking "2 PRs per agent" are measuring the wrong unit; document the work-stream concept for downstream agents.

---

*Draft compiled 2026-07-27 from current `main` of both repos + live REST metadata. No projects were created; no repos were mutated.*