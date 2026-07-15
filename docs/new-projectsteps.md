# New Project Setup Steps — dev-studio-template → atilproject

> **Audience:** Owner (@atilcan65) and any future collaborator spinning up a
> new project from dev-studio-template + dev-studio-launcher on atilproject org.
>
> **Updated:** 2026-07-15 (post-Sprint-29 re-render, S29-015 AC1+AC2+AC4).
> Originally rewritten from scratch 2026-07-13 (cycle ~#1158) per owner
> directive ("Eski hiç bir hazırlık dosyasını kullanma"). This is the
> post-Sprint-29 version: Step 5b removed (auto-applied by S29-013 launcher
> patch), tag discipline updated (v1.0.1 → current HEAD per S29-002),
> Post-Sprint-29 sunset checklist removed (self-aware sunset per arch obs #8).
>
> **Current state (post-Sprint-29 close target 2026-07-27):**
> - Template stock workflows = 100% self-hosted (S29-001 ✅, PR #73 squash-merged
>   14:20:32Z; 4-tuple `[self-hosted, Linux, X64, atilproject]` on all workflows)
> - v1.0.1 tag force-moved to current template HEAD `43592c24` per S29-002;
>   v0.3.0 tag added at launcher HEAD `b0d820da` (both via PR #1008 + sister-PRs)
> - Launcher auto-applies self-hosted 4-tuple at bootstrap (S29-013) — Step 5b
>   manual workaround no longer needed

---

## Overview — what you're about to do

```
Step 1: Sanity check tools
Step 2: Choose visibility (public vs private)
Step 3: Run launcher (new-project.sh)
Step 4: Configure secrets + variables
Step 5: Render template via dev-studio-init.sh (auto via launcher)
Step 6: Bootstrap labels + board
Step 7: Smoke test (d-tests)
Step 8: Commit + push (auto via launcher)
Step 9: Start 5-agent tmux session
Step 10: Open Vision Intake issue (PM agent picks up)
```

> **Sprint 29 simplification:** Step 5b (manual `sed` workaround for stock
> workflow self-hosted migration) is **OBSOLETE** as of S29-013. The launcher
> auto-applies the self-hosted 4-tuple at bootstrap, so private repos no longer
> burn Actions minutes by default. If you see references to Step 5b in older
> docs or runbooks, treat them as superseded by this 10-step flow.

Each step below is **verifiable** — if any fails, stop and inspect before
continuing.

---

## Step 1 — Sanity check tools

The launcher's `new-project.sh` will fail loudly if any of these are missing.

```bash
# Check CLI tools
command -v gh && gh --version
command -v git && git --version
command -v jq && jq --version
command -v tmux && tmux -V

# Check gh auth
gh auth status

# Check git global config (launcher will use these for commits)
git config --global user.name
git config --global user.email

# Check PROJECT_TOKEN (needed for board sync + canary; optional for public)
echo "${PROJECT_TOKEN:-<unset>}" | head -c 8  # first chars; never print full token
```

**Required output:**
- `gh`: at least 2.x, authenticated as you (or as an org member of atilproject)
- `git`: at least 2.x, user.name + user.email set
- `jq`: at least 1.6
- `tmux`: available (you'll need it for Step 9)
- `PROJECT_TOKEN`: present if you'll create a `--private` repo AND want the
  status-label-to-board.yml workflow to sync labels to a Projects v2 board
  (public repos don't strictly need it but it's recommended)

If `gh auth status` says "not logged in", run `gh auth login` first. The
launcher will reject unauthenticated runs.

---

## Step 2 — Choose visibility

**Decision: public vs private?** Default per ADR-0016 = **public**.

| Visibility | When to use | Trade-off |
|---|---|---|
| `public` (default) | Sole developer, open-source intent, no secret internals | Free Actions minutes on public repos. PROJECT_TOKEN canary can run freely. |
| `private` | Real secrets, real prod data, internal-tool only | Actions minutes are **PAID** on private repos. Need billing setup before running canary. **Until S29-001 lands**, template stock workflows run on GitHub-hosted (`ubuntu-latest`) and will burn your free-tier minutes (2,000 min/month). |

**If you're not sure,** start with `--public`. You can flip visibility later
via GitHub Settings → General → Danger Zone → "Change repository visibility"
(one-way flip; private→public is reversible, public→private is partial).

**Self-hosted runner (always available):** The atilproject org has **8
self-hosted runners online** with labels `[self-hosted, Linux, X64, atilproject]`
(verified 2026-07-13, all idle). To use them, your project's workflows
must be configured with the 4-tuple `runs-on: [self-hosted, Linux, X64,
atilproject]`. All template stock workflows now ship with this 4-tuple
(S29-001 done, PR #73 squash-merged 14:20:32Z), and the launcher auto-applies
it on bootstrap (S29-013 done) — no manual `sed` workaround needed.

---

## Step 3 — Run launcher

From any working directory:

```bash
# Default: public, owner=atilcan65, dir=~/projects
~/dev-studio-launcher/new-project.sh <project-name>

# Private repo (Actions will cost minutes on stock workflows):
~/dev-studio-launcher/new-project.sh <project-name> --private

# Different parent dir:
~/dev-studio-launcher/new-project.sh <project-name> --dir ~/work

# Show full options:
~/dev-studio-launcher/new-project.sh --help
```

**Important:** The launcher's `--owner` default is `atilcan65` (the legacy
user account, which GitHub treats as an alias for the org-level repo).
For org-level projects under `atilproject`, you should explicitly pass
`--owner atilproject` to use the canonical org URL.

**Concrete examples:**

```bash
# Public repo at atilproject org
~/dev-studio-launcher/new-project.sh my-cool-thing --owner atilproject

# Private repo (with billing already configured)
~/dev-studio-launcher/new-project.sh secret-app --private --owner atilproject

# Default (legacy owner — works but URL is atilcan65 alias)
~/dev-studio-launcher/new-project.sh scratch
```

**What the launcher does:**

1. Preflight: checks `gh`, `git`, `jq`; verifies `gh auth status`; verifies
   `git config --global user.{name,email}`; verifies target repo doesn't
   already exist on GitHub; verifies template repo is accessible
2. `gh repo create <owner>/<name> --template atilproject/dev-studio-template
   --public/--private --clone`
3. Clones to `<dir>/<name>`
4. Runs `./scripts/dev-studio-init.sh` (renders `.tmpl` placeholders)
5. Runs `./scripts/bootstrap-labels.sh` (seeds 34 labels per ADR-0012)
6. Commits rendered changes + pushes to main

**Intentionally manual (you do these):** secrets/variables config (Step 4),
Projects v2 board bootstrap (Step 6b), smoke test (Step 7), tmux launch
(Step 9), Vision Intake issue (Step 10). Per launcher's design: these are
**decisions**, not automations.

---

## Step 4 — Configure secrets + variables

After Step 3, before Step 5, you need to seed the repo with secrets and
variables that the rendered workflow files will reference.

```bash
cd ~/projects/<your-new-project>
gh repo view  # confirm you're in the right repo
```

### Repo Secrets (Settings → Secrets and variables → Actions)

| Secret | Required? | Purpose | How to set |
|---|---|---|---|
| `PROJECT_TOKEN` | Required for board sync + private Actions | Classic PAT with `repo` + `project` scope | `gh secret set PROJECT_TOKEN` (paste token) |
| `DEPLOY_SSH_KEY` | Optional (skip if not deploying yet) | SSH key for self-hosted runner deploy | see ADR-0027 §Threat model |
| `DEPLOY_HOST`, `DEPLOY_USER` | Optional (deploy SSH alternative) | If using appleboy/ssh-action instead of self-hosted runner | per ADR-0027 §Decision.2 |

### Repo Variables (Settings → Secrets and variables → Actions → Variables tab)

| Variable | Required? | Purpose |
|---|---|---|
| `SERVICE_NAME` | Only for deploy | systemd service name for production deploy |
| `MODULE_PATH` | Only for deploy | Python module path (e.g. `atilcalc.engine`) |
| `DEPLOY_PORT` | Only for deploy | Local port bind for production |
| `HEALTHZ_PATH` | Only for deploy | `/healthz` path for liveness check |
| `PROD_HOSTNAME` | Only for deploy | Public hostname |

**Without PROJECT_TOKEN**, board sync workflow will fail (it's the only
mutation allowed against Projects v2 — see ADR-0014). Template renders
`label-check` without PROJECT_TOKEN need.

---

## Step 5 — Render template via dev-studio-init.sh (mostly auto)

Step 3 already ran `./scripts/dev-studio-init.sh` for you. Verify:

```bash
ls -la .claude/CLAUDE.md              # should exist, no .tmpl suffix
head -10 .claude/CLAUDE.md            # should show your repo name + owner
ls -la docs/sprints/current/plan.md   # should exist (rendered from .tmpl if present)
```

If anything is missing, run manually:

```bash
bash scripts/dev-studio-init.sh
```

**What it does:**
- Walks `.claude/CLAUDE.md.tmpl` and `.claude/agents/*.md.tmpl` + relevant
  workflow `.tmpl` files
- Substitutes `{{GITHUB_OWNER}}`, `{{GITHUB_REPO}}`, `{{HUMAN_OWNER_NAME}}`,
  `{{PROJECT_TOKEN_SECRET_NAME}}`, and a few more
- Writes the rendered files next to their `.tmpl` source (e.g. `CLAUDE.md`
  next to `CLAUDE.md.tmpl`)
- Sets up local repo state (no remote push yet — launcher did that)

---

## Step 6 — Bootstrap labels + board

Step 3 already ran `bootstrap-labels.sh` for you (it seeds 34 labels per
ADR-0012's 4-category invariant). **Step 6b (board) is NOT run by
launcher — you must do it manually.**

```bash
# Step 6a — verify labels (auto from launcher; re-run if any are missing)
bash scripts/bootstrap-labels.sh

# Step 6b — create the Projects v2 board (one project board, six columns)
bash scripts/bootstrap-project-board.sh
```

**Step 6a verifies the label invariant:** 4 categories (`type:*`, `status:*`,
`agent:*`, `cc:*`). If any is missing on a new issue/PR, the CI workflow
`label-check.yml` will reject it (fail the check + post a comment with fix
guidance).

**Step 6b** creates the Projects v2 board via REST + PROJECT_TOKEN. Failure
is normal in `--private` repos if PROJECT_TOKEN can't reach Projects v2
mutation endpoint (private Actions budget exhausted). Re-run after Step 4
secrets are provisioned.

---

## Step 7 — Smoke test (d-tests)

At this point, the scaffold is rendered but untested. Run the d-test
regression suite to verify the bootstrap left the system in a healthy state.

```bash
bash scripts/tests/e2e-pilot.sh       # full e2e smoke
bash scripts/tests/faz5-smoke.sh      # Faz 5 smoke test
bash scripts/tests/state-schema-smoke.sh  # agent-state schema
```

**Expected:** all green. **If anything fails:** STOP. Inspect logs.
`scripts/tests/dreg-post-restart-label-guard.sh` is the most common starter
failure (label invariant break on first sync).

Quick sanity: just check label-check is green.

> **Note on d-test coverage:** The template currently ships ~21 d-tests.
> AtilCalculator has ~131. Sprint 29 (S29-007) plans to forward-port the
> remaining ~80. Until then, e2e-pilot covers the critical ones; the rest
> are AtilCalculator-specific regressions that don't apply to a fresh project.

---

## Step 8 — Commit + push (mostly auto)

Step 3 already committed + pushed the rendered changes. **No manual workflow
patch step needed** — the launcher auto-applies the self-hosted 4-tuple at
bootstrap (S29-013). If you have any other local edits (e.g.,
`docs/product/ONBOARDING.md` placeholder content), commit them now:

```bash
git add -A
git commit -m "chore(init): personal touches post-bootstrap"
git push origin main
```

**First push triggers:** deploy workflow (if rendered) + status-label-to-board
sync (if PROJECT_TOKEN set) + CI lint runs (on self-hosted runner by default).

All template stock workflows run on the org's 8 self-hosted runners
(`[self-hosted, Linux, X64, atilproject]`); no Actions-minutes burn on
private repos. Monitor at `gh api repos/<owner>/<repo>/actions/runs?per_page=10`.

---

## Step 9 — Start 5-agent tmux session

The template's `scripts/dev-studio-start.sh` launches a 5-pane tmux session:
one Claude Code agent per role (orchestrator, product-manager, architect,
developer, tester).

```bash
bash scripts/dev-studio-start.sh
```

**Verify:** `tmux ls` shows one session with 5 panes. Each pane has the
agent's title bar (`<role>: <task> | cycle ~<N> | heartbeat OK`).

**First-launch behavior:** Each agent reads `.claude/CLAUDE.md` and their
own soul file, then polls GitHub via `scripts/agent-watch.sh <role>` every
60s.

**If tmux is unavailable:** Agents can also run as separate Claude Code
processes (no tmux). Just `claude --system-prompt "$(cat .claude/agents/<role>.md)"`
per pane — but the polling loop requires the `agent-state/` log dir.

---

## Step 10 — Open Vision Intake issue (PM agent picks up)

After the session is up, open the **first** issue:

```bash
gh issue create \
  --title "Vision Intake — <your-project>'s product framing" \
  --body "$(cat docs/product/ONBOARDING.md)" \
  --label "type:vision" \
  --label "status:ready" \
  --label "agent:product-manager" \
  --label "cc:product-manager"
```

**This is the FIRST issue of the new project.** It carries `agent:product-manager`
+ `status:ready` per ADR-0012 birth contract. The PM agent's `agent-watch.sh`
will pick it up on its next 60s poll, read `docs/product/ONBOARDING.md`, and
draft the vision + first user stories.

**From here:** standups (09:00 Europe/Istanbul), sprint planning, ceremonies,
defense of design... normal scrum flow as documented in `.claude/CLAUDE.md`.

---

## Self-hosted runner registration — exact label syntax

If you're registering a fresh runner for a different org, or want to
understand the 4-tuple pattern, here's the canonical setup (the one
AtilCalculator uses per `00-audit-baseline.md` R-01):

```yaml
# .github/workflows/ci.yml
runs-on: [self-hosted, Linux, X64, atilproject]
```

The 4-tuple is **required** for the runner to pick up the job. Each label
is matched independently by the runner's `--labels` flag at registration
time:

```bash
# On the runner host (one-time setup):
cd /home/<runner-user>/actions-runner
./config.sh --url https://github.com/atilproject/<repo> \
            --token <RUNNER_TOKEN> \
            --labels self-hosted,Linux,X64,atilproject \
            --name <runner-name> \
            --work _work
```

**Verify runner registration:**

```bash
# Org-level (all repos):
gh api /orgs/atilproject/actions/runners --jq '.runners[] | {name, os, status}'

# Repo-level (this repo only):
gh api /repos/<owner>/<repo>/actions/runners --jq '.runners[] | {name, os, status}'
```

**Common pitfalls:**
- Runner label mismatch = job queues forever (no error, just stuck).
  Verify labels match exactly (case-sensitive).
- Missing `atilproject` label = runner won't pick up `atilproject`-targeted
  jobs (won't match the 4th tuple element).
- Single-runner-per-host: don't run multiple `--labels` configs on same
  machine without unique `--name`.

---

## Troubleshooting quick-ref

| Symptom | Likely cause | Fix |
|---|---|---|
| `gh: not logged in` | gh CLI not authenticated | `gh auth login` |
| `PROJECT_TOKEN canary failed` | Private repo Actions quota exhausted | Top up org Actions budget OR start with `--public` |
| `label-check: missing category` | New issue/PR created without 4 labels | Re-create with all 4 labels; see ADR-0012 |
| `dreg-post-restart-label-guard FAIL` | labels.json out of sync | `bash scripts/post-restart-label-guard.sh --fix` |
| Agent tmux pane unresponsive | Stale vim mode or process hang | `tmux send-keys -t <pane> C-c`, then `bash scripts/agent-watch.sh <role>` in that pane |
| `Cannot find label: agent:*` | `bootstrap-labels.sh` not run | Re-run Step 6a |
| `BOARD lane says "No Status"` | issue missing `status:*` label | Add one (e.g. `status:ready`) |
| Workflow job stuck in queue forever | Runner label mismatch | Verify `runs-on:` matches registered runner labels (4-tuple) |
| `bootstrap-project-board.sh` exits with auth error | PROJECT_TOKEN missing or wrong scope | Re-issue classic PAT with `repo` + `project` scope |

---

## Day-2 ops cheatsheet

After your project is running:

```bash
# Daily standup
bash scripts/dev-studio-start.sh  # if not running already

# Open story (PM lane)
gh issue create --title "STORY-001: <one-liner>" --body "<ACs>" \
  --label "type:feature" --label "status:ready" \
  --label "agent:developer" --label "cc:developer"

# Show kanban board
gh project view <project-number> --owner atilproject  # lists cards by lane

# Replay an agent's last 60s of events
bash scripts/agent-watch.sh developer  # then `state` subcommand

# Force a peer ping
scripts/peer-poke.sh developer "[ORCH→DEV] sprint N ready for pickup"
```

---

## Cross-references

- **dev-studio-template:** https://github.com/atilproject/dev-studio-template
  (HEAD `43592c24`, 2026-07-11; **v1.0.1 tag force-moved to current HEAD
  per S29-002** — pin to v1.0.1 for reproducibility, not to a stale SHA)
- **dev-studio-launcher:** https://github.com/atilproject/dev-studio-launcher
  (HEAD `b0d820da`, 2026-06-17; **v0.3.0 tag added per S29-002**)
- **Audit doc:** `docs/sprints/sprint-28/02-template-launcher-audit-2026-07-13.md`
  (companion to this file; §10.2 now reads "EXECUTED — closing 2026-07-27"
  with plan + verify links per S29-015 AC3)
- **AtilCalculator CLAUDE.md dual-path** (Phase 2 #9 resolution, S29-015 AC5):
  - **Canonical root `CLAUDE.md`** — newer of the two (commit `737b846e`,
    2026-06-29); rendered by `dev-studio-init.sh` (template repo) at downstream
    project root
  - **`.claude/CLAUDE.md`** — kept for symlink-style compatibility; same content
    + Sprint 28 SOUL AMENDs per S29-017 (architect-authored)
  - **Render contract:** template `dev-studio-init.sh` renders BOTH paths
    so downstream projects get a single source of truth + symlink-style
    agent-readable copy
- **Related ADRs (template):** ADR-0012 (4-cat invariant), ADR-0013 (board
  sync), ADR-0014 (PROJECT_TOKEN), ADR-0016 (public-by-default), ADR-0047
  (deploy pattern)

---

— @orchestrator, 2026-07-15T06:08:00+03:00 (cycle ~#1880, S29-015 AC1+AC2+AC4),
post-Sprint-29 re-render. Originally rewritten 2026-07-13 (cycle ~#1158)
from scratch per owner directive. This version: Step 5b removed
(launcher auto-applies per S29-013), tag discipline updated (v1.0.1 +
v0.3.0 live per S29-002), sunset checklist removed (self-aware sunset).
Phase 2 #9 dual-path CLAUDE.md resolution documented in Cross-references;
render-path sister-change in dev-studio-template (cross-repo per RETRO-023).