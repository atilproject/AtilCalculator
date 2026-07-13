# New Project Setup Steps — dev-studio-template → atilproject

> **Audience:** atil can (@atilcan65) and any future collaborator spinning up a new
> project from the dev-studio-template + dev-studio-launcher combo.
>
> **Prereq state (as of 2026-07-13 cycle ~1153):** Template HEAD = `43592c2`
> (tag `v1.0.1` still at legacy SHA `81ec0b1`; no v1.0.2 tag). Launcher HEAD =
> `b0d820d` (no v0.3.0 tag yet — see `docs/sprints/sprint-28/01-status-check-2026-07-13.md`).
> Org-level: 8 self-hosted runners online + idle (verified 2026-07-13).
> See [sprint-28 status check](sprints/sprint-28/01-status-check-2026-07-13.md) for full Q1-Q7 answers.
>
> **Output of this runbook:** A new GitHub repo at
> `github.com/atilproject/<project-name>` with the dev-studio scaffold rendered,
> labels bootstrapped, and the 5-agent tmux session ready to launch.

---

## Overview — what you're about to do

```
Step 1: Sanity check tools
Step 2: Choose visibility (public vs private)
Step 3: Run launcher (new-project.sh)
Step 4: Configure secrets + variables
Step 5: Render template via dev-studio-init.sh
Step 6: Bootstrap labels + board
Step 7: Smoke test (d-tests)
Step 8: Commit + push
Step 9: Start 5-agent tmux session
Step 10: Open Vision Intake issue (PM agent picks up)
```

Each step below is verifiable — if any fails, stop and inspect before continuing.

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

# Check PROJECT_TOKEN (needed for --private; optional for --public but recommended for canary)
echo "${PROJECT_TOKEN:-<unset>}" | head -c 8  # first chars; never print full token
```

**Required output:**
- `gh`: at least 2.x, authenticated as you.
- `git`: at least 2.x, user.name + user.email set.
- `jq`: at least 1.6.
- `tmux`: available (you'll need it for Step 9).
- `PROJECT_TOKEN`: present if you ever `--private`-create.

If `gh auth status` says "not logged in", run `gh auth login` first. The launcher
will reject unauthenticated runs.

---

## Step 2 — Choose visibility

**Decision: public vs private?** Default per ADR-0016 = **public**.

| Visibility | When to use | Trade-off |
|---|---|---|
| `public` (default) | Sole developer, open-source intent, no secret internals | Free Actions minutes on public repos. Project_TOKEN canary can run freely. |
| `private` | Real secrets, real prod data, internal-tool only | Actions minutes are **PAID** on private repos. Need billing setup before running canary. |

**If you're not sure,** start with `--public`. You can flip visibility later via
GitHub Settings → General → Danger Zone → "Change repository visibility" (one-way
flip; private→public is reversible, public→private is partial).

---

## Step 3 — Run launcher

From any working directory:

```bash
~/dev-studio-launcher/new-project.sh <project-name> [flags]
```

**Flags:**

| Flag | Default | Effect |
|---|---|---|
| `--owner <login>` | `atilcan65` (or env `GITHUB_OWNER`) | The org or user that owns the new repo. |
| `--dir <parent>` | `~/projects` | Parent directory for the clone. |
| `--public` | ✅ (public) | Make the new repo public. |
| `--private` | (opt-in) | Make the new repo private. WARNING: Actions minutes billing. |
| `--help` | — | Print usage. |

**Concrete examples:**

```bash
# Public repo, default dir, owner=atilcan65
~/dev-studio-launcher/new-project.sh my-cool-thing

# Private repo, custom dir
~/dev-studio-launcher/new-project.sh my-secret-app --private --dir ~/work

# Public repo under a different owner
~/dev-studio-launcher/new-project.sh scratch --owner my-org
```

**What the launcher does (A1 + B1 + C2 = minimal automation, separate repo):**

1. `gh repo create <owner>/<name> [--public|--private] --clone`
2. Clones the freshly-empty repo to `<dir>/<name>`
3. Adds the template as a git remote: `template https://github.com/atilproject/dev-studio-template.git`
4. Pulls the template's `main` into local (preserving origin as the new repo)
5. **Stops here.** The render/labels/commit/push happen manually in Steps 5-8.

**Intentionally manual (you do these):** render `.tmpl` → `.md`,
`bootstrap-labels.sh`, smoke tests, commit, push. Per launcher's design: these
are decisions, not automations.

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

### Repo Variables (Settings → Secrets and variables → Actions → Variables tab)

| Variable | Required? | Purpose |
|---|---|---|
| `SERVICE_NAME` | Only for deploy | systemd service name for production deploy |
| `MODULE_PATH` | Only for deploy | Python module path (e.g. `atilcalc.engine`) |
| `DEPLOY_PORT` | Only for deploy | Local port bind for production |
| `HEALTHZ_PATH` | Only for deploy | `/healthz` path for liveness check |
| `PROD_HOSTNAME` | Only for deploy | Public hostname |

**Without PROJECT_TOKEN**, board sync workflow will fail (it's the only mutation
allowed against Projects v2 — see ADR-0014). Template renders `label-check`
without PROJECT_TOKEN need.

### Self-hosted runner (only if using `--private`)

For private repos, template workflows need a self-hosted runner registered.
**Currently (per audit Q3): template workflows default to `ubuntu-latest`,
which costs Actions minutes for private repos.** Either:

(a) Override per-workflow to self-hosted (mirror AtilCalculator's pattern), or
(b) Configure Actions billing on the org.

See `docs/sprints/sprint-28/00-audit-baseline.md` Q3 for the gap state. For
immediate workarounds, see Step 7 below.

### Self-hosted runner registration — exact label syntax

AtilCalculator's runner pattern (the one to mirror per audit Q3 / R-01):

```yaml
# .github/workflows/ci.yml
runs-on: [self-hosted, Linux, X64, atilproject]
```

The 4-tuple is **required** for the runner to pick up the job. Each label is
matched independently by the runner's `--labels` flag at registration time:

```bash
# On the runner host (one-time setup):
cd /home/<runner-user>/actions-runner
./config.sh --url https://github.com/atilproject/<repo> \
            --token <RUNNER_TOKEN> \
            --labels self-hosted,Linux,X64,atilproject \
            --name <runner-name> \
            --work _work
```

Verify runner registration:

```bash
# Org-level (all repos):
gh api /orgs/atilproject/actions/runners --jq '.runners[] | {name, os, status}'

# Repo-level (this repo only):
gh api /repos/<owner>/<repo>/actions/runners --jq '.runners[] | {name, os, status}'
```

**Common pitfalls:**
- Runner label mismatch = job queues forever (no error, just stuck). Verify
  labels match exactly (case-sensitive).
- Missing `atilproject` label = runner won't pick up `atilproject`-targeted jobs.
- Single-runner-per-host: don't run multiple `--labels` configs on same machine
  without unique `--name`.

For an owner-decision: whether to ship template's `runs-on:` as `[self-hosted,
Linux, X64, atilproject]` (org-pinned) vs `[self-hosted, Linux]` (generic
self-hosted, requires every project to register its own). **AtilCalculator uses
the org-pinned 4-tuple.** See audit §15.1 for the full comparison and Sprint 28
R-02 ADR for the recommended default.

---

## Step 5 — Render template via dev-studio-init.sh

The template ships with `.tmpl` placeholders that need real values:

```bash
cd ~/projects/<your-new-project>
bash scripts/dev-studio-init.sh
```

**What it does:**
- Walks `.claude/CLAUDE.md.tmpl` and `.claude/agents/*.md.tmpl` + relevant workflow `.tmpl` files
- Substitutes `{{GITHUB_OWNER}}`, `{{GITHUB_REPO}}`, `{{HUMAN_OWNER_NAME}}`,
  `{{PROJECT_TOKEN_SECRET_NAME}}`, and a few more
- Writes the rendered files next to their `.tmpl` source (e.g. `CLAUDE.md`
  next to `CLAUDE.md.tmpl`)
- Sets up local repo state (no remote push yet)

**Verify:**
```bash
ls -la .claude/CLAUDE.md              # should exist, no .tmpl suffix
head -10 .claude/CLAUDE.md            # should show your repo name + owner
ls -la docs/sprints/current/plan.md   # should exist (rendered from .tmpl if present)
```

---

## Step 6 — Bootstrap labels + board

Two scripts:

```bash
# Step 6a — create the 4-category labels per ADR-0012
bash scripts/bootstrap-labels.sh

# Step 6b — create the Projects v2 board (one project board, six columns)
bash scripts/bootstrap-project-board.sh
```

**Step 6a verifies the label invariant:** 4 categories (`type:*`, `status:*`,
`agent:*`, `cc:*`). If any is missing on a new issue/PR, the CI workflow
`label-check.yml` will reject it (fail the check + post a comment with fix
guidance).

**Step 6b** creates the Projects v2 board via REST + PROJECT_TOKEN. Failure is
normal in `--private` repos if PROJECT_TOKEN can't reach Projects v2 mutation
endpoint (private Actions budget exhausted). Re-run after Step 4 secrets are
provisioned.

---

## Step 7 — Smoke test (d-tests)

**At this point, the scaffold is rendered but untested.** Run the d-test
regression suite to make sure the bootstrap left the system in a healthy state.

```bash
bash scripts/tests/e2e-pilot.sh       # full e2e smoke
bash scripts/tests/faz5-smoke.sh      # Faz 5 smoke test
bash scripts/tests/state-schema-smoke.sh  # agent-state schema
```

**Expected:** all green. **If anything fails:** STOP. Inspect logs.
`scripts/tests/dreg-post-restart-label-guard.sh` is the most common starter
failure (label invariant break on first sync).

Quick sanity: just check label-check is green.

---

## Step 8 — Commit + push

```bash
cd ~/projects/<your-new-project>
git add -A
git commit -m "chore(init): render template + bootstrap labels + board scaffold

- Render .claude/CLAUDE.md + .claude/agents/*.md from .tmpl
- Bootstrap 4-category labels per ADR-0012
- Bootstrap Projects v2 board (Backlog → Ready → In Progress → In Review → Done)
- Smoke tests passing (e2e-pilot, faz5-smoke, state-schema-smoke)"

git push origin main
```

**First push triggers:** deploy workflow + status-label-to-board sync + CI lint
runs. If `runs-on: ubuntu-latest` and `--private`, will burn Actions minutes.

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
own soul file, then polls GitHub via `scripts/agent-watch.sh <role>` every 60s.

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

## Troubleshooting quick-ref

| Symptom | Likely cause | Fix |
|---|---|---|
| `gh: not logged in` | gh CLI not authenticated | `gh auth login` |
| `PROJECT_TOKEN canary failed` | Private repo Actions quota exhausted | Top up org Actions budget OR start with `--public` |
| `label-check: missing category` | New issue/PR created without 4 labels | Re-create with all 4 labels; see ADR-0012 |
| `dreg-post-restart-label-guard FAIL` | labels.json out of sync | `bash scripts/post-restart-label-guard.sh --fix` |
| Agent tmux pane unresponsive | Stale vim mode or process hang | `tmux send-keys -t <pane> C-c`, then `bash scripts/agent-watch.sh <role>` in that pane |
| `Cannot find label: agent:*` | `bootstrap-labels.sh` not run | Re-run Step 6a |
| BOARD lane says "No Status" | issue missing `status:*` label | Add one (e.g. `status:ready`) |

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
gh project view <project-number> --owner atilcan65  # lists cards by lane

# Replay an agent's last 60s of events
bash scripts/agent-watch.sh developer  # then `state` subcommand

# Force a peer ping
scripts/peer-poke.sh developer "[ORCH→DEV] sprint N ready for pickup"
```

---

## Cross-references

- **dev-studio-template**: https://github.com/atilproject/dev-studio-template (HEAD `43592c2` 2026-07-11, tag `v1.0.1` at legacy SHA `81ec0b1`)
- **dev-studio-launcher**: https://github.com/atilproject/dev-studio-launcher (HEAD `b0d820d` 2026-06-17, only `v0.2.0` tag; commit message says "v0.3" but no tag — L-01 pending)
- **Audit baseline**: [`docs/sprints/sprint-28/00-audit-baseline.md`](sprints/sprint-28/00-audit-baseline.md) (comprehensive Sprint 28 audit, merged 2026-07-10)
- **Status check 2026-07-13**: [`docs/sprints/sprint-28/01-status-check-2026-07-13.md`](sprints/sprint-28/01-status-check-2026-07-13.md) (delta check, owner-directive 2026-07-13)
- **Audit baseline (Sprint 28 doc):** [`docs/sprints/sprint-28/00-audit-baseline.md`](sprints/sprint-28/00-audit-baseline.md)
- **Related ADRs in template:** ADR-0012 (4-cat invariant), ADR-0013 (board sync), ADR-0014 (PROJECT_TOKEN), ADR-0016 (public-by-default)
- **CLAUDE.md** (rendered from .tmpl): see your new project's `.claude/CLAUDE.md` after Step 5

---

— @orchestrator, 2026-07-10T20:10+03:00, cycle ~743.
Drafted for owner review before Sprint 28 kickoff.
