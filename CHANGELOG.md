# Changelog

All notable changes to this project are recorded here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Sprint 34 S34-005 AC2 sister-PR — atilproject/dev-studio-launcher runner label atilproject → atilcan (Refs atilproject/AtilCalculator#1225, sprint:current).** Sprint 34 W3 forward-port, Sister-PR-A of dev-studio-template PR #214 (squash-merged 2026-07-26T04:23:34Z sha 18e374ca by @atilcan65, cluster-squash #22 TERMINAL ✅). Sister-PR-A dispatch [ORCH→DEV] 2026-07-26T07:37:10Z (cycle ~#3968Q+460 arch verdict option a-decomposed). **Three-file atomic per ADR-0055 §1**: (a) **`new-project.sh` line 63 (MODIFIED atilproject → atilcan)** — `RUNNER_4TUPLE_LABEL_PATTERN="[self-hosted, Linux, X64, atilcan]"` + 2 comment updates (lines 115 + 390) reflecting the atilcan canonical pattern. (b) **`tests/d001-launcher-self-hosted-runner-patch.sh` TC1 update (MODIFIED atilproject → atilcan)** — TC1 grep anchor updated + 6 comment lines updated (lines 9, 10, 21, 40, 44, 134, 135, 136, 139, 220, 222, 228). All 7 TCs verified GREEN locally per cycle ~#3893Q v2 verify-locally-before-verdict. (c) **`tests/INDEX.md` (MODIFIED d001 row S34-005 AC2 marker added)** — d001 row extended with sprint 34 AC2 sister-PR marker. **Companion arch verdict amendment** (separate doc PR per cycle ~#3968Q+460): arch verdict Q1 2026-07-15T08:14:35Z → atilcan canonical. **Doctrinal anchors**: ADR-0044 (RED-first TDD), ADR-0049 (d-test ≥5 baseline — 7 TCs + ≥3 sister), ADR-0055 §1 (Cadence Rule 1 atomic — 3 files same commit), ADR-0057 (Refs anchor — `Refs atilproject/AtilCalculator#1225` per Issue already closed sister work tracks upstream), ADR-0015 (4-flag atomic hand-off — chain 3/3 ACK pattern cycle ~#3968Q+239), ADR-0031 (owner squash gate), ADR-0033 (dual-channel peer-poke), cycle ~#3968Q+414 (PR-self-blocking CI doctrine — UNSTABLE expected per workflow uses self-hosted label), cycle ~#3968Q+311+8 (CONDITIONAL preventive — branch from latest main tip), cycle ~#3258 (STANDALONE cluster-squash cap), cycle ~#3968Q+460 (arch verdict option a-decomposed). **Out-of-scope preserved**: `atilproject/dev-studio-template` org repo path (lines 5, 25, 28, 53, 54, 353) — these are GitHub org/repo paths, NOT self-hosted runner labels. **Sister-cluster**: PR #1230 (AtilCalculator sister-PR, Task #70 closed — cluster-squash #24 candidate STANDALONE). Cluster-squash #23 candidate STANDALONE per cycle ~#3258. Cadence target ≤9h17min squash-gate (cycle ~#3968Q+337 baseline). Cross-refs: PR #214 (sister-PR source — dev-studio-template impl TERMINAL ✅); Issue #1225 (Refs anchor — atilproject/AtilCalculator parent dispatch Issue, CLOSED 2026-07-26T04:31:54Z); arch verdict cycle ~#3968Q+460 (option a-decomposed for launcher ONLY, AtilCalculator sister-PR is verbatim PR #214 mirror).

## [0.4.1] - 2026-07-23

### Added

- **README "Task-list Persistence" section** ([atilproject/dev-studio-launcher#14](https://github.com/atilproject/dev-studio-launcher/issues/14), S32-XXX-D):
  Short explanation of the per-project `state/tasklists/` directory that
  `scripts/dev-studio-init.sh` (template-side) creates at clone time +
  registers in `.gitignore`. Per [ADR-0073](https://github.com/atilproject/dev-studio-template/blob/main/docs/decisions/ADR-0073-tasklist-persistence-and-watchdog-tuning-revision.md)
  (sister: [ADR-0072](https://github.com/atilcan65/AtilCalculator/blob/main/docs/decisions/ADR-0072-tasklist-persistence-and-watchdog-tuning-revision.md)).

- **`new-project.sh` AC2 verify** ([atilproject/dev-studio-launcher#14](https://github.com/atilproject/dev-studio-launcher/issues/14)):
  Documentation comment block at the `running dev-studio-init.sh` step
  noting template-side responsibility for `state/tasklists/` creation.
  No code action — template clone already handles it per ADR-0073.

### Changed

- **Version bump** v0.4.0 → v0.4.1 (README footer + Versioning table).

### Notes

- Owner directive 2026-07-19: "kod mirror yok (template'den geliyor önerin
  uygun). Launcher agent çalıştırmıyor, template referans yeterli."
  Doc-only sync — no scripts/ files mirrored from template.
- Sister-pattern: tmpl#192 (S32-XXX-B impl canonical) + calc#1173
  (S32-XXX-C forward-port mirror). Both merged 2026-07-19.

## [0.4.0] - 2026-07-18

### Added

- **CI workflow** (`#12`, Issue #8 S32-014 + Issue #10 S32-015):
  `.github/workflows/ci.yml` runs `tests/d001-launcher-self-hosted-runner-patch.sh`
  on push + PR. SHA-pinned actions per ADR-0027 (defense-in-depth per
  tmpl#148 sister-pattern). Detect-step pattern (bash-source existence)
  parity with tmpl#147 Python detection. Conventional Commits gate on
  PR titles. Run via `Lint & Test` + `Conventional Commits` jobs.

- **v0.4.0 = "now CI-tested" milestone** (sister-pattern to tmpl v1.1.0
  S32-019). Before v0.4.0 the launcher had d-test coverage but no CI;
  now every push verifies the self-hosted 4-tuple patch and hygiene.

### Changed

- README footer bumped to v0.4.0 (per AC2 of Issue #11 S32-016).

### Notes

- AC5 trust-but-verify (Issue #972): tag `v0.4.0` cut post-merge.
- Sister-pattern: atilproject/dev-studio-template@`tmpl#147` + `tmpl#148`
  (SHA-pin + Python detect → shell-source detect adaptation).

## [0.3.0] - 2026-07-04

### Added

- Public-by-default visibility, `--private` opt-in (ADR-0016, PR #2).

## [0.2.0] - 2026-06-XX

### Added

- Default parent dir `~/projects` (auto-created) (PR #1).

## [0.1.0] - initial

### Added

- A1 + B1 + C2 decision: minimal `new-project.sh` automation (positional
  arg, separate launcher repo, one-time clone + symlink).
