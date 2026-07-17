# New Project — Step-by-Step Setup from dev-studio-template

> **Author**: @orchestrator (2026-07-17, Sprint 30 audit per owner directive)
> **Status**: DRAFT — pending owner review (per owner directive "kararlar birlikte alınacak")
> **Purpose**: End-to-end procedure for opening a new project using `atilproject/dev-studio-launcher` and `atilproject/dev-studio-template`. Will migrate into `dev-studio-template/docs/OPERATIONS.md` during Sprint 30.
> **Pre-flight verification**: smoke tested end-to-end via `atilproject/dev-studio-template-smoke` (private instantiation, `visibility:private`, 74 ADRs, 11/11 self-hosted workflows, byte-identical scripts to AtilCalculator local).

---

## 0. Pre-requisites — what must exist on host BEFORE first invocation

| Tool | Version | Why | Verify |
|---|---|---|---|
| `git` | ≥ 2.30 | Repo creation + branch ops + pre-push hooks | `git --version` |
| `gh` | ≥ 2.40 | GitHub API + repo creation + labels | `gh --version` |
| `jq` | ≥ 1.6 | All `scripts/*.sh` use jq (peer-poke, agent-watch, claim) | `jq --version` |
| `bash` | ≥ 5.0 | Launcher uses bash 5 features (associative arrays, `${var,,}`) | `bash --version` |
| `python3` | ≥ 3.11 | AtilCalculator-style projects use Python 3.11+ (per ADR-0017) | `python3 --version` |
| `curl` | ≥ 7.0 | Health checks + webhook calls | `curl --version` |
| `tmux` | ≥ 3.0 | Multi-agent runtime (5 panes) | `tmux -V` |
| GitHub PAT in `gh auth` | classic PAT, scopes: `repo`, `project`, `admin:org` (for label creation) | Repo creation + label ops + Projects v2 | `gh auth status` |
| Self-hosted runner live | label `[self-hosted, Linux, X64, atilproject]` registered at `atilproject` org level | CI must NOT hit Action quota limits for private repos | `gh api repos/<owner>/<repo>/actions/runners --jq '.total_count'` |

**WHY this list matters**: Each entry maps to a runtime dependency discovered during the Sprint 29 cluster-squash wave. `bash 5+` is non-negotiable because `new-project.sh` uses bash 5 string-lowering (`${var,,}`) for label normalization. `gh` PAT with `admin:org` scope is required for label creation across the org (label creation without it returns 403).

---

## 1. Launcher invocation — `new-project.sh`

### 1.1 Basic invocation (recommended)

```bash
# From any directory — launcher script is the only entrypoint
bash /path/to/dev-studio-launcher/new-project.sh \
  --org atilproject \
  --repo-name my-new-project \
  --visibility private \
  --description "My new project's one-liner" \
  --no-confirm
```

**Argument reference**:

| Flag | Required | Default | Meaning |
|---|---|---|---|
| `--org` | yes | — | GitHub org to create repo under (`atilproject` or owner-org) |
| `--repo-name` | yes | — | Repo slug (`my-new-project` → URL `github.com/atilproject/my-new-project`) |
| `--visibility` | yes | — | `private` (recommended) / `public` / `internal` |
| `--description` | yes | — | One-liner (used as repo About + Vision Intake issue body) |
| `--no-confirm` | no | (interactive prompt) | Skip "are you sure?" prompt for CI/automation |
| `--branch` | no | `main` | Default branch name |
| `--dry-run` | no | (executes) | Print commands without executing |
| `--local-only` | no | (creates remote) | Skip GitHub API calls; assume repo exists locally |

### 1.2 What `new-project.sh` does — internal sequence

**Step 1: Repo creation from template** (lines 89-122):
```bash
gh repo create "${ORG}/${REPO}" \
  --template atilproject/dev-studio-template \
  --"${VISIBILITY}" \
  --description "${DESCRIPTION}" \
  --clone
```

**Step 2: Local clone + enter** (lines 124-148):
- Clones the newly-created repo to `./${REPO}/`
- `cd` into the repo directory

**Step 3: Template rendering** (`dev-studio-init.sh` — RETRO-005 codification):
- Reads `.template-version` (= `1.0.1`)
- Renders all `.tmpl` files → final form:
  - `.template-version.tmpl` → `.template-version`
  - `pyproject.toml.tmpl` → `pyproject.toml`
  - `.claude/CLAUDE.md.tmpl` → `.claude/CLAUDE.md`
  - `.claude/agents/*.md.tmpl` → `.claude/agents/*.md`
  - `.claude/commands/*.md.tmpl` → `.claude/commands/*.md`
  - `.github/workflows/deploy.yml.tmpl` → `.github/workflows/deploy.yml`
  - `.github/ISSUE_TEMPLATE/config.yml.tmpl` → `.github/ISSUE_TEMPLATE/config.yml`
  - `LICENSE.tmpl` → `LICENSE`
  - `README.md.tmpl` → `README.md`
  - `CODEOWNERS.tmpl` → `CODEOWNERS`
  - `systemd/dev-studio-*.service.tmpl` → `systemd/dev-studio-*.service`
  - `scripts/kickoff/*.txt.tmpl` → `scripts/kickoff/*.txt`
  - `scripts/peer-poke.sh.tmpl` → `scripts/peer-poke.sh`
- Removes `.tmpl` source files (clean working tree after init)

**Step 4: Bootstrap labels** (`bootstrap-labels.sh`):
- Creates all 4-cat category labels (`type:*`, `status:*`, `agent:*`, `cc:*`)
- Creates wake labels (`needs-tester-signoff`, `needs-architect-review`)
- Creates sprint labels (`sprint:current`, `sprint:next`)
- Uses `scripts/lint-notify-invocations.sh` if `Notify.sh` usage present

**Step 5: Projects v2 board bootstrap** (`bootstrap-project-board.sh`):
- Creates a Projects v2 board named "${REPO} Board"
- Adds 5 columns: Backlog → Ready → In Progress → In Review → Done
- Maps `status:*` labels → Status field (ADR-0013)

**Step 6: Self-hosted runner migration** (`apply_self_hosted_runner_patch`, S29-013 lines 280-320):
- Sed-migrates `runs-on: ubuntu-latest` (in any `.yml`) → `runs-on: [self-hosted, Linux, X64, atilproject]`
- Idempotent — safe to re-run
- Skips workflows already on self-hosted 4-tuple (cycle ~#2360 cycle ~#2360 idempotency refile)

**Step 7: Initial commit + push** (lines 330-360):
- `git add -A` (entire rendered tree)
- `git commit -m "feat(init): dev-studio-template v1.0.1 bootstrap"` (conventional commits per CLAUDE.md)
- `git push -u origin main`

**Step 8: Vision Intake issue** (lines 380-410):
- Opens GitHub Issue (default template `vision-intake.yml`) with:
  - Title: `[Vision Intake] ${REPO} — initial scope`
  - Body: From `--description` arg + template prompt
  - Labels: `type:vision + status:backlog + agent:product-manager + cc:product-manager + cc:human`
- This is the kickoff entry for PM to take over

**Step 9: Final report + recommended next steps** (lines 420-432):
- Prints summary: repo URL, 4-cat label count, board URL, vision intake URL
- Recommends: `bash scripts/dev-studio-start.sh` (launch 5 tmux panes)
- Recommends: `bash scripts/e2e-pilot.sh` (29/29 PASS baseline)

### 1.3 Interactive confirmation prompts

If `--no-confirm` is NOT passed, the script prompts at:
1. Before repo creation (PAT scope check)
2. After Step 4 (label count verification)
3. Before push (commit message confirmation)
4. Before opening Vision Intake issue (label state verification)

For automation use `--no-confirm` (CI/cron).

---

## 2. Post-creation — first 10 minutes

### 2.1 Verify CI is green (mandatory gate before any work)

```bash
gh pr checks 0 2>&1 | head  # check status of HEAD commit
# OR
gh api repos/${ORG}/${REPO}/commits/main/check-runs --jq '.check_runs[] | {name, conclusion}'
```

**Expected**: 6/6 checks succeed on `push` event (label-check, secret-canary, ci.yml, lint-and-test, post-squash, status-label-to-board).

If any fails, check `Actions` tab in browser. Common cause: runner offline → label-check and ci.yml both fail with "no matching runner". Restart self-hosted runner.

### 2.2 Open the Vision Intake issue (if not auto-opened)

If step 8 above didn't auto-open (e.g., `--no-confirm` skipped it), manually:

```bash
gh issue create --title "[Vision Intake] ${REPO} — initial scope" \
  --body-file .github/ISSUE_TEMPLATE/vision-intake.md \
  --label "type:vision" --label "status:backlog" \
  --label "agent:product-manager" --label "cc:product-manager" \
  --label "cc:human"
```

### 2.3 Activate the multi-agent runtime (5 tmux panes)

```bash
bash scripts/dev-studio-start.sh
# This launches:
#   tmux pane 1: orchestrator (Claude Code)
#   tmux pane 2: product-manager (Claude Code)
#   tmux pane 3: architect (Claude Code)
#   tmux pane 4: developer (Claude Code)
#   tmux pane 5: tester (Claude Code)
```

**Verify**: 5 panes visible in tmux; each pane shows its soul file header on startup.

### 2.4 (Optional) Install systemd watcher for 24/7 autonomy

```bash
bash scripts/install/install-systemd-watcher.sh --user
# This:
#   - Copies scripts/install/systemd/dev-studio-watcher@.service to ~/.config/systemd/user/
#   - Enables linger (so user-services run when user not logged in)
#   - Starts dev-studio-watcher@orchestrator.service (and 4 more for each role)
```

**Verify**: `systemctl --user status dev-studio-watcher@orchestrator.service` → active.

**Why optional**: If you only use manual tmux invocation, this is redundant. For long-running projects (multi-week), strongly recommended per ADR-0010.

---

## 3. First-week workflow

### 3.1 Sprint 0 (kickoff) — orchestrator-owned

1. Orchestrator opens `[Sprint 0] Kickoff` issue (type:chore, status:ready, agent:orchestrator, cc:human)
2. Vision Intake issue → PM claims via `agent:product-manager + cc:product-manager` (handoff per ADR-0015 atomic 4-flag)
3. PM drafts `docs/product/vision.md` (PM-owned per file ownership matrix)
4. PM drafts `docs/backlog/backlog.json` (Sprint 1 candidate list)

### 3.2 Branch protection — STRONGLY RECOMMENDED GitHub-side

After Sprint 0 kickoff, **the owner should enable GitHub branch protection on `main`**:

```bash
gh api repos/${ORG}/${REPO}/branches/main/protection \
  --method PUT \
  --input - <<EOF
{
  "required_status_checks": {"strict": true, "contexts": ["label-check", "ci", "lint-and-test"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 1, "dismiss_stale_reviews": true},
  "restrictions": null
}
EOF
```

**Why**: ADR-0031 owner-merge-gate is currently enforced only by local pre-push hook + human discipline. Without GitHub-side branch protection, anyone with PAT access can bypass. **Pre-existing gap across 3/3 atilproject org repos** (AtilCalculator, dev-studio-template, dev-studio-launcher — all `Branch not protected` per `gh api ... /branches/main/protection`).

### 3.3 Team kickoff files (PM lane)

PM drafts (or copies from template) these during Sprint 0:
- `docs/sprints/current/plan.md` (pointer to active sprint)
- `docs/sprints/sprint-01/plan.md` (first sprint plan)
- `docs/backlog/STORY-NNN-*.md` files (story files)
- `docs/backlog/backlog.json` (machine-readable index)

---

## 4. Verification checklist (Sprint 0 close)

Before declaring Sprint 0 done, verify:

- [ ] `gh api repos/${ORG}/${REPO}/branches/main/protection` returns 200 (branch protection on)
- [ ] `gh pr list --state all --limit 5` shows at least one PR with `status:ready + cc:human` (test the workflow)
- [ ] `bash scripts/e2e-pilot.sh` returns `29/29 PASS` (all 29 behavioral scripts green)
- [ ] `bash scripts/dev-studio-start.sh` launches 5 panes, all show soul headers
- [ ] Vision Intake issue is open with all 4-cat labels
- [ ] `docs/sprints/current/plan.md` points to a real `sprint-01/plan.md` file
- [ ] `docs/backlog/backlog.json` exists and is valid JSON
- [ ] `cat .template-version` returns `1.0.1` (or current tmpl version)

If any item fails, **Sprint 0 is NOT done**. File blockers in a `BUG:` issue.

---

## 5. Rollback plan — if anything fails

If the new-project becomes unrecoverable within first hour:

```bash
# Option A: Archive + recreate (no git history loss)
gh repo archive ${ORG}/${REPO}
# Then re-run new-project.sh

# Option B: Hard reset to template HEAD
cd /path/to/${REPO}
git remote add upstream https://github.com/atilproject/dev-studio-template.git
git fetch upstream
git reset --hard upstream/main
git push origin main --force-with-lease
```

**Do NOT** do without human approval: anything that drops commits or PRs. Use `--force-with-lease` (never bare `--force`).

---

## 6. Known caveats / gaps inherited from template v1.0.1

Per Sprint 30 audit (2026-07-17):

1. **Branch protection NOT enabled by default** — `new-project.sh` does not call branch-protection API. This is a SECURITY GAP (ADR-0031 currently local-only-enforced). Recommendation: add `--enable-branch-protection` flag to v1.1.0.

2. **47 ADR amendments not in template** — AtilCalculator has 47 amendments (post-v1.0.1 doctrine refinements) that do NOT exist in template v1.0.1. New project instantiates v1.0.1 → loses ~6 weeks of doctrine refinement. Workaround: after instantiation, cherry-pick docs/decisions/ADR-NNNN-*.md from AtilCalculator if needed.

3. **3 ADR slug ID collisions** — Template ADR-0046, 0047, 0060 have different `slug` names than AtilCalculator's (different content with same number). New project should be aware: ADR numbers are NOT globally unique across repos.

4. **Sprint 29 self-hosted runner patch in place** — `apply_self_hosted_runner_patch` runs in step 6. If your runner is offline at push time, all 11/11 workflows fail with "no matching runner".

5. **No release tag for launcher** — `atilproject/dev-studio-launcher` has no v1.0.1 release (only tags v0.2.0, v0.3.0). Pinned launcher invocation is `git clone` only (not `git checkout v1.0.1`). Recommendation: tag launcher at v1.0.1 in Sprint 30.

---

## 7. Sister-pattern reference

- `atilproject/dev-studio-launcher/new-project.sh` (16268 bytes, sha `ab7558886...`, last commit 2026-07-15T11:56:10Z)
- `atilproject/dev-studio-template/dev-studio-init.sh` (template renderer)
- `atilproject/dev-studio-template/bootstrap-labels.sh` (4-cat label creator)
- `atilproject/dev-studio-template/bootstrap-project-board.sh` (Projects v2 board creator)
- `atilproject/dev-studio-template-smoke` (private instantiation reference, 74 ADRs)
- ADR-0059 (cluster-squash), ADR-0060 (Claude Code 2.1.207 agent flag), RETRO-024 (work-done-elsewhere)
- Sprint 30 audit: `docs/sprints/sprint-30/00-audit-template-portability.md`

---

*Drafted by @orchestrator cycle ~#2746 for Sprint 30 template-portability audit. Will migrate to `atilproject/dev-studio-template/docs/OPERATIONS.md` after owner sign-off on Sprint 30 plan.*
