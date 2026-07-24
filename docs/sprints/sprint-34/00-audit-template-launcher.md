# Sprint 34 audit — AtilCalculator → dev-studio-template / dev-studio-launcher

**Date:** 2026-07-24  
**Mode:** Read-only evidence collection; no target-repository changes, runner changes, private smoke repository, or release action performed.  
**Direction:** AtilCalculator → template/launcher only. Reverse propagation is out of scope.

## Executive answer

The requested “100% ready” state is **not proven**. Several prerequisites are demonstrably incomplete or contradictory:

- `dev-studio-template` is public, not private; private-template usability was not exercised in this audit.
- The template has no repository-registered self-hosted runner, although its workflows request `[self-hosted, Linux, X64, atilproject]`.
- The visible AtilCalculator runner is labeled `[self-hosted, Linux, X64, atilcan]`, which does not match the template/launcher `atilproject` tuple. No relabeling or provisioning was authorized or performed.
- `dev-studio-launcher` has successful recent CI, but that CI runs on GitHub-hosted `ubuntu-latest`; this does not prove a private generated project can run on the intended self-hosted runner.
- The launcher contains a self-hosted patch and a fallback warning. The existence of that code is not end-to-end proof.
- A broad reusable platform surface already exists in the template, but parity with all newer AtilCalculator Sprint 33 doctrine and artifacts has not been proven. The exact gap matrix is therefore required before implementation.

## Ground truth captured

Sources were queried from GitHub on 2026-07-24 using `gh repo view`, `gh api`, `gh run list`, `gh pr list`, and remote tree/blob queries. Old preparation files and agent reports were not treated as evidence.

| Repository | Visibility | Open PRs | Recent remote state | Registered repo runners |
|---|---|---:|---|---:|
| `atilproject/dev-studio-template` | PUBLIC | 0 | main pushed 2026-07-21 | 0 |
| `atilproject/dev-studio-launcher` | PUBLIC | 0 | main pushed 2026-07-24 | 0 |
| `atilproject/AtilCalculator` | PUBLIC | 0 | main pushed 2026-07-24 | 1 |

The AtilCalculator runner reported by the API is `atiltestweb-atilcan`, online and idle, with labels `[self-hosted, Linux, X64, atilcan]`.

### CI observations

- Template recent runs include successful `CI` and `Lint & Test (d-tests)` runs, but also failed `Deploy to production`, `Post-Squash Cluster-Lag Detector`, and `Label Check` runs. The latest result set is not uniformly green.
- Launcher recent `CI` runs returned success, but its workflow uses `ubuntu-latest`.
- No observed run in this audit proves a private repository created from the template ran on an `atilproject`-labeled self-hosted runner.

### Template contents observed

The remote tree contains:

- `.claude/CLAUDE.md.tmpl` and five agent soul templates.
- `.github/workflows/` including CI, lint/test, deploy, label, cross-repo, secret-canary, status-board, and post-squash workflows.
- `docs/decisions/` through ADR-0073, with an index and porting notes.
- `scripts/` for initialization, agent watch/wake/state, labels, board bootstrap, claiming, cross-repo operations, deployment/runner support, systemd installation, restart/reprime, and d-tests.
- `docs/new-project-steps.md`.

This demonstrates substantial template capability, not complete parity.

### Launcher contents observed

The launcher contains `new-project.sh`, README/CHANGELOG, `.github/workflows/ci.yml`, and d-tests in both `tests/` and `scripts/tests/`.

`new-project.sh`:

- references `atilproject/dev-studio-template`;
- supports `--public` and `--private`;
- invokes template initialization/label bootstrapping;
- contains a self-hosted tuple patch for `[self-hosted, Linux, X64, atilproject]`;
- emits a warning and preserves a fallback when no matching runner is found.

The launcher therefore appears structurally capable of bootstrapping, but private access, runner routing, and a complete end-to-end run remain unverified.

## Answers to the seven questions

### 1. Is the template private-ready and tested?

**Not proven.** The repository is currently public. Template CI has passed runs, but the audit found no private bootstrap transcript, no private generated repository, no matching registered template runner, and no end-to-end private Actions run. Organization permissions, template eligibility for private repositories, Actions billing/limits, and secret availability require explicit API/owner verification.

### 2. Has all reusable AtilCalculator process/doctrine/script/agent material transferred?

**Cannot honestly claim 100%.** The template already contains a large reusable platform surface, but newer AtilCalculator artifacts and Sprint 33 changes require exact source-to-destination classification. The required comparison must cover:

- `.claude/*.tmpl` and agent soul templates;
- `scripts/` and `scripts/tests/` behavior plus indexes;
- `docs/decisions/` and ADR index;
- process/operations/context/peer-poke documents;
- workflow and workflow-template behavior;
- systemd/install assets;
- runner, watcher, task-list, reprime, label, and stall-detection changes;
- launcher-facing setup documentation.

Runtime state files and calculator product code must not be copied. Product-specific ADRs and docs must be classified rather than blindly ported.

### 3. Is self-hosted migration 100% complete?

**No.** The label mismatch is concrete: target workflows request `atilproject`, while the only visible runner reports `atilcan`. The launcher’s own CI is GitHub-hosted. No private generated project was run and no matching template runner was observed. Relabeling/provisioning is an owner decision and has not been performed.

### 4. What may remain for the template?

The answer requires the parity matrix. Known audit work includes exact parity classification for recent Sprint 33 changes, template-source preservation, workflow/runner contract, d-test coverage, ADR/index/doc synchronization, and canonical new-project instructions. No implementation gap is being declared complete from tree presence alone.

### 5. Is the launcher ready for new projects?

**Bootstrap path exists; production readiness is unverified.** The script references the correct template, supports private mode, initializes/render labels, and has runner preflight/patch logic. The unresolved private-template access, runner tuple mismatch, fallback semantics, version contract, and E2E evidence prevent a 100% claim.

### 6. Detailed `new projectsteps` document

The template currently has `docs/new-project-steps.md`; the launcher README also documents the flow. Their command-by-command accuracy must be re-derived from a verified bootstrap. The requested canonical detailed document will be produced only after the owner approves the audit gap list and the flow is exercised; otherwise it would be an unverified procedure.

### 7. Was the 1.0.1 update completed?

**Unknown/not proven from the current evidence.** Remote exact tags, releases, commit SHAs, and version files must be reconciled separately for both repositories. Conflicting reports about launcher version/tag/workflow state were deliberately rejected until the remote API and blobs agree. No 1.0.1 release or update action was performed during this audit.

## Proposed gap-closing sequence (requires owner approval)

1. Approve this evidence baseline and resolve the runner-label/private-template decisions.
2. Build and review the complete parity matrix; classify every transferable artifact as equivalent, divergent, missing, calculator-only, or unknown.
3. Open implementation issues/PRs in `dev-studio-template` for approved reusable material only.
4. Open implementation issues/PRs in `dev-studio-launcher` for launcher-owned behavior, tests, versioning, and documentation only.
5. With explicit authorization, run disposable public/private bootstrap tests and capture repository, commit, workflow, runner, rendered-file, and log evidence.
6. Resolve the runner tuple only through the approved owner path, then repeat template and generated-project self-hosted runs.
7. Publish the verified detailed setup document and have architect, tester, PM, and owner review the full chain.
8. Close Sprint 34 only when all approved gaps have merged PRs in the correct repositories and no unknown is represented as complete.

## Explicitly not done

- No target repository was edited.
- No issue or PR was opened in `dev-studio-template` or `dev-studio-launcher`.
- No private repository was created.
- No runner was relabeled or provisioned.
- No release/tag was created.
- No implementation was started.

## Evidence commands

- `gh repo view <owner/repo> --json ...`
- `gh pr list --repo <owner/repo> --state open ...`
- `gh run list --repo <owner/repo> ...`
- `gh api repos/<owner/repo>/actions/runners`
- `gh api repos/<owner/repo>/git/trees/<branch>?recursive=1`
- `gh api repos/<owner/repo>/contents/<path>`

The next action is owner review of this audit and explicit approval of the gap list/runner decision—not automatic implementation.
