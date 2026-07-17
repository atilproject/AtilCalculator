# New Project Setup Steps — `dev-studio-template` Bootstrap

> **Doc version:** 2026-07-17 (Sprint 31 fresh write — supersedes any Sprint 30 / Sprint 29 version)
> **Audience:** A new project owner who wants to bootstrap a fresh GitHub project from `atilproject/dev-studio-template`
> **Prerequisites:** `gh` CLI authenticated, GitHub PAT with `repo` + `project` scopes, Linux or macOS host
> **Time estimate:** 30–60 minutes for a clean bootstrap; +1–2 hours if you also wire up self-hosted runners + Projects v2 board
> **Sprint 31 audit ref:** [Q6 deliverable](../audits/2026-07-17-sprint-31-audit.md)

---

## TL;DR — Happy Path

```bash
# 1. Clone the launcher (single bootstrap script)
git clone https://github.com/atilproject/dev-studio-launcher.git ~/projects/dev-studio-launcher
cd ~/projects/dev-studio-launcher

# 2. Run the bootstrap (creates new GitHub repo + clones template + runs init)
./new-project.sh my-new-project --org atilproject --private

# 3. Inside the new project: render .tmpl → final, bootstrap labels + board, start agents
cd ~/projects/my-new-project
./scripts/dev-studio-init.sh
./scripts/bootstrap-labels.sh
./scripts/bootstrap-project-board.sh   # requires PROJECT_TOKEN
./scripts/dev-studio-start.sh          # launches 5 tmux panes (one per agent)

# 4. Open the first sprint kickoff issue (orchestrator does this on first wake)
```

After step 4, the 5 agents (orchestrator / product-manager / architect / developer / tester) are polling GitHub for work, and the new project is operational.

---

## Step 1 — Pre-flight (do this BEFORE running the launcher)

### 1.1 Verify `gh` CLI auth

```bash
gh auth status
```

Expected output: `Logged in to github.com as <your-username> (oauth_token)` with scopes including `repo`, `workflow`, `project`, `admin:org` (for `--org` flag).

If not authenticated:

```bash
gh auth login --scopes repo,workflow,project,admin:org
```

### 1.2 Verify org membership

```bash
gh api orgs/atilproject/members | jq '.[].login'
```

Your GitHub username must appear in the output. If you're not in the org, ask the org owner to add you.

### 1.3 Get a `PROJECT_TOKEN` (only needed if you'll bootstrap a Projects v2 board)

The launcher will clone the template, but **board sync requires a classic PAT** (the default `GITHUB_TOKEN` cannot mutate Projects v2, see ADR-0014).

```bash
# Create a PAT at https://github.com/settings/tokens/new
# Required scopes: repo, project, admin:org
# Save the token, then:
export PROJECT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
gh secret set PROJECT_TOKEN --repo atilproject/<your-new-project>
```

### 1.4 Pick a self-hosted runner strategy

You have 3 options:

| Option | Use case | Setup cost |
|--------|----------|------------|
| **A. Use shared `atilproject/*` runners** | Public org runners (8 VMs, labels `[self-hosted, Linux, X64, atilproject]`) — works for any repo under `atilproject` org | 0 minutes |
| **B. Deploy your own org runner** | Private runners with org-wide labels | 30 min (run `scripts/deploy-runner.sh` on a fresh VM) |
| **C. Use GitHub-hosted runners** | Default `ubuntu-latest` (no self-hosted label) | 0 minutes, but slower + rate-limited |

**Default recommendation**: Option A (shared org runners) for `atilproject/*` repos. The launcher will auto-patch workflow files to add the `runs-on: [self-hosted, Linux, X64, atilproject]` label tuple on bootstrap (S29-013 patch).

---

## Step 2 — Run the launcher

### 2.1 Clone the launcher

```bash
git clone https://github.com/atilproject/dev-studio-launcher.git ~/projects/dev-studio-launcher
cd ~/projects/dev-studio-launcher
```

(If you prefer `git clone` to a different path, substitute `~/projects/dev-studio-launcher` accordingly.)

### 2.2 Run `new-project.sh`

```bash
./new-project.sh my-new-project \
  --org atilproject \
  --private \
  --runner-label "self-hosted,Linux,X64,atilproject"
```

**Flags**:

| Flag | Required? | Default | Meaning |
|------|-----------|---------|---------|
| `--org <org>` | Yes | (none) | GitHub org where the new repo will live |
| `--private` | No | (public) | Create a private repo (omit for public) |
| `--public` | No | public | Explicit public |
| `--runner-label "<csv>" | No | `self-hosted,Linux,X64,atilproject` | Comma-separated runner labels to inject into workflows |
| `--no-self-hosted` | No | self-hosted patching on | Skip the S29-013 self-hosted label patch (use GitHub-hosted runners) |
| `--help` | No | — | Show all flags |

### 2.3 What the launcher does (4 phases)

1. **Phase 1: GitHub repo creation** — `gh repo create` (with `--${private|public}` flag)
2. **Phase 2: Template clone + init** — `git clone atilproject/dev-studio-template.git <new-project-dir>` → `cd <new-project-dir> && ./scripts/dev-studio-init.sh`
3. **Phase 3: Self-hosted runner label patch** — sed-injects the runner-label tuple into `.github/workflows/*.yml` (S29-013 patch)
4. **Phase 4: First commit + push** — commits the rendered template to the new repo's main branch

**Total time**: ~30 seconds for Phase 1+2+4; Phase 3 is sub-second.

### 2.4 Verify post-launch

```bash
cd ~/projects/my-new-project
ls -la
# Expect: CLAUDE.md, .claude/, .github/, scripts/, docs/, pyproject.toml, README.md, LICENSE

git log --oneline -3
# Expect: at least 1 commit (the init render)

gh repo view atilproject/my-new-project --json defaultBranch
# Expect: {"defaultBranch":"main"}
```

---

## Step 3 — Post-clone init (inside the new project)

### 3.1 Re-render the `.tmpl` files

The launcher runs `dev-studio-init.sh` once during Phase 2. If you change any `.tmpl` file later, re-run it:

```bash
cd ~/projects/my-new-project
./scripts/dev-studio-init.sh
```

This renders all `.md.tmpl` → `.md`, `.sh.tmpl` → `.sh`, etc., substituting the 6 placeholders (per ADR-0013):
- `<REPO_PATH>` → `/home/atilcan/projects/my-new-project` (or wherever you cloned)
- `<GITHUB_OWNER>` → `atilproject`
- `<GITHUB_REPO>` → `my-new-project`
- `<HUMAN_NAME>` → your name
- `<HUMAN_HANDLE>` → your GitHub username
- `<LOG_DIR>` → `/var/log/dev-studio/my-new-project`

### 3.2 Bootstrap labels (4-cat invariant per ADR-0012)

```bash
./scripts/bootstrap-labels.sh
```

This creates the canonical label set:
- `type:*` (7 labels: vision, feature, bug, docs, chore, refactor, incident)
- `status:*` (6 labels: backlog, ready, in-progress, in-review, blocked, done)
- `agent:*` (6 labels: orchestrator, product-manager, architect, developer, tester, human)
- `cc:*` (same 6 labels)
- Wake labels: `needs-tester-signoff`, `needs-architect-review`
- `priority:*` (P0–P3)
- `sprint:*` (sprint:current, sprint:N-archived)
- `verdict-by:*` (timestamp labels per ADR-0024)

Total: ~30 labels. Verify with `gh label list --repo atilproject/my-new-project | wc -l` (expect ~30).

### 3.3 Bootstrap the Projects v2 board (optional but recommended)

```bash
export PROJECT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
./scripts/bootstrap-project-board.sh
```

This creates a "Project Board" with columns: Backlog → Ready → In Progress → In Review → Done. Each new issue/PR auto-syncs via the `status-label-to-board.yml` workflow (ADR-0013).

**Skip this step** if you only need the 4-cat label discipline + agent autonomy, and you're OK tracking board state manually via `gh issue list --label status:*`.

---

## Step 4 — Start the 5 agents

```bash
./scripts/dev-studio-start.sh
```

This launches a `tmux` session named `dev-studio` with 5 panes:
- Pane 0: `@orchestrator`
- Pane 1: `@product-manager`
- Pane 2: `@architect`
- Pane 3: `@developer`
- Pane 4: `@tester`

Each pane has the agent's soul file loaded + Claude Code REPL started. **You don't need to manually wake them** — `agent-watch.sh <role>` polls GitHub every 60s.

**First-run auto-wake**: On the first `agent-watch.sh` cycle, the orchestrator will discover it's a fresh project and open a `[Sprint 1 Kickoff]` issue. From there, the team self-organizes.

**If `tmux` is not installed**:

```bash
# Linux (Debian/Ubuntu)
sudo apt install tmux

# macOS
brew install tmux
```

---

## Step 5 — First sprint kickoff (manual if you want to skip the wait)

If you don't want to wait for the orchestrator's first auto-wake (60-90s typical), you can drive the kickoff manually:

```bash
gh issue create --title "[Sprint 1] Kickoff" --body "..." \
  --label "type:chore" --label "status:ready" \
  --label "agent:orchestrator" --label "cc:product-manager"
```

The 4-cat invariant (ADR-0012) is enforced by `.github/workflows/label-check.yml` — if any category is missing, the check fails and a comment is posted.

---

## Step 6 — Verify the system end-to-end

### 6.1 Trigger a test PR (developer lane smoke test)

```bash
# In a worktree
git checkout -b chore/smoke-test
echo "# Smoke test" > SMOKE.md
git add SMOKE.md
git commit -m "chore: smoke test"
git push -u origin chore/smoke-test

# Open draft PR
gh pr create --draft --title "chore: smoke test" \
  --body "First PR for end-to-end smoke test." \
  --label "type:chore" --label "status:in-review" \
  --label "agent:developer" --label "cc:tester" \
  --label "needs-tester-signoff"
```

### 6.2 Expected flow

1. CI runs on the self-hosted runner (~30s for a Python project)
2. Tester agent wakes (via `pr_labeled` event on `needs-tester-signoff` label)
3. Tester posts APPROVED verdict + adds `verdict-by:<ts>` label
4. Architect agent wakes (via `pr_labeled` event on `needs-architect-review` if design impact)
5. Orchestrator flips `status:ready` + `cc:human` for owner merge gate
6. Owner squash-merges (ADR-0031)

If any step is missing, check:
- `agent-watch.sh <role>` is running in the tmux pane (look for `[INFO] ... queue empty` log)
- The relevant label exists (per Step 3.2)
- The runner is online: `gh api orgs/atilproject/actions/runners --jq '.runners[] | "\(.name) \(.status)"'`

---

## Troubleshooting

### T1: `dev-studio-init.sh` fails with "permission denied"

```bash
chmod +x scripts/*.sh scripts/**/*.sh
```

### T2: `bootstrap-labels.sh` fails on existing labels

The script uses `--force` on `gh label create`. If you see HTTP 422 on a label with a 100-char description (cycle ~#2414 incident), pre-shorten the description in the script's `LABEL_DESCRIPTIONS` array.

### T3: `bootstrap-project-board.sh` fails with "PROJECT_TOKEN not set"

```bash
export PROJECT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
gh secret set PROJECT_TOKEN --repo atilproject/<your-project>
```

### T4: Self-hosted runner not picking up jobs

1. Verify runner is online: `gh api orgs/atilproject/actions/runners --jq '.runners[] | "\(.name) \(.status)"'`
2. Verify workflow has the right `runs-on` labels: `grep -r "runs-on:" .github/workflows/`
3. Verify runner labels match: `gh api orgs/atilproject/actions/runners/<runner-id> --jq '.labels[].name'`

### T5: Agent tmux pane doesn't wake on label change

1. Verify `agent-watch.sh <role>` is running in the pane
2. Verify the label flip was on a real PR/issue (not a closed one — `label-check.yml` ignores closed items per RETRO-024 silent-skip)
3. Check the state file: `cat /var/log/dev-studio/<your-project>/agent-state/<role>.json | jq '.last_seen_utc'`

---

## What comes next?

After a successful Sprint 1 kickoff, the team operates autonomously:

- **Sprint cadence**: 2-week sprints, Monday kickoff, Friday retro
- **Daily standup**: 09:00 Europe/Istanbul (auto-posted by orchestrator)
- **PRs**: Always draft, conventional commits, 4-cat labels per ADR-0012
- **Verdicts**: Tester = APPROVED/NEEDS CHANGES/NEEDS DISCUSSION; Architect = 🟢/🟡/🔴
- **Owner gate**: Only human squash-merges (ADR-0031)

For day-to-day workflows, see:
- `CLAUDE.md` (project root, rendered from `CLAUDE.md.tmpl`)
- `.claude/CLAUDE.md` (full doctrine, rendered)
- `.claude/agents/<role>.md` (each agent's soul file)

---

— @orchestrator, 2026-07-17T08:30:00Z (cycle ~#2773, Sprint 31 WP7 deliverable, awaiting owner review)