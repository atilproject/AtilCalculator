# Sprint 30 — Plan (2026-07-17+)

> **Author**: @orchestrator (cycle ~#2746, 2026-07-17)
> **Reviewer**: @architect + @human (owner "go" gate)
> **Status**: DRAFT — pending owner sign-off per directive "ben go verince sprint 30 ile başlayacak"
> **Trigger**: PR #TBD (Sprint 30 audit) — owner approval of `00-audit-template-portability.md`
> **Sister-cluster**: PURE Sprint 30 scope per [[sprint-29-to-sprint-30-boundary-cycle-2741]] (cycle ~#2741 owner directive)

---

## Mode

🟡 **SPRINT 30 PENDING — OWNER GO GATE NOT YET GIVEN**

- **Scope-lock**: 9 WPs from audit (`00-audit-template-portability.md`). NO drift.
- **Capacity cap**: NONE (per Sprint 29 doctrine: "completion, not velocity")
- **Sister-repo**: atilproject/dev-studio-template + atilproject/dev-studio-launcher (cross-repo coordination per RETRO-023)
- **Cross-agent cadence**: AtilCalc-side (this repo) handles WP3, WP6, WP8; tmpl-side handles WP4, WP5; launcher-side handles WP2; human tasks WP1, WP7

---

## §Sprint goal

**Close all audit findings in `00-audit-template-portability.md` such that the next new-project instantiation (`new-project.sh`) gets byte-identical capability to AtilCalculator's running instance.**

Success criteria: launch a 4th project from `dev-studio-template` post-Sprint-30 and confirm it has:
- ✅ All 11/11 self-hosted workflows (already done in Sprint 29 cluster)
- ✅ At least 47 ADR amendments ported to template (or documented rationale for non-port)
- ✅ v1.0.1 release for both template + launcher (publishable, not draft)
- ✅ Branch protection enabled via `--enable-branch-protection` flag
- ✅ `e2e-pilot.sh` baseline-check available as `new-project.sh` recommendation
- ✅ At most 3 ADR slug-ID collisions documented (with cross-repo ADR-number uniqueness note)

---

## §Work package inventory (9 WPs, sized)

### WP1 — Publish template v1.0.1 (5 min, human)

| Attribute | Value |
|---|---|
| Owner | @human (manual GitHub click) |
| Repo | atilproject/dev-studio-template |
| Action | Edit v1.0.1 draft release → set `draft:false` + add release notes |
| Release notes source | `CHANGELOG.md` lines for v1.0.1 (read at template root) |
| Blocked by | — |
| Blocks | WP4, WP5, WP8, WP9 |

**Acceptance criteria**:
- [ ] `gh api repos/atilproject/dev-studio-template/releases --jq '.[] | {tag, draft, published_at}'` shows `v1.0.1 draft:false published_at:<not-null>`
- [ ] Release is the "latest" release (visible at repo root)

### WP2 — Tag + release launcher v1.0.1 (5 min, human)

| Attribute | Value |
|---|---|
| Owner | @human (manual GitHub click) |
| Repo | atilproject/dev-studio-launcher |
| Action | Tag HEAD as v1.0.1 → create release |
| Note | Launcher HEAD has S29-013 self-hosted 4-tuple patch (commit 2026-07-15) — that IS v1.0.1 content |
| Blocked by | — |
| Blocks | WP3 (developer needs tag for testing) |

**Acceptance criteria**:
- [ ] `gh api repos/atilproject/dev-studio-launcher/tags --jq '.[] | .name'` includes `v1.0.1`
- [ ] `gh api repos/atilproject/dev-studio-launcher/releases` shows v1.0.1 (not draft)

### WP3 — Add `--enable-branch-protection` flag to launcher (1-2h, developer)

| Attribute | Value |
|---|---|
| Owner | @developer |
| Repo | atilproject/dev-studio-launcher |
| File | `new-project.sh` |
| Change | Add `--enable-branch-protection` flag; when set, calls `gh api ... /branches/main/protection --method PUT --input <JSON>` |
| Blocked by | WP2 (tests reference v1.0.1 tag) |
| Blocks | WP7 (flag works on smoke repo first) |

**Acceptance criteria**:
- [ ] Flag accepted; `--help` documents it
- [ ] When flag used on smoke repo, `gh api repos/.../branches/main/protection` returns 200 (not 404)
- [ ] D-test added: `d-launcher-enable-branch-protection.sh` (≥3 TCs per ADR-0049)
- [ ] `d-test INDEX.md` row added per ADR-0055 §1 Cadence Rule 1 atomic

### WP4 — Backport 47 ADR amendments to template (1-2 days, architect)

| Attribute | Value |
|---|---|
| Owner | @architect |
| Repo | atilproject/dev-studio-template |
| Files | `docs/decisions/ADR-NNNN-*.md` |
| Strategy | Diff-driven backport: copy 47 AtilCalc-only files to template, preserving dates |
| Edge case | 3 ADR slug-ID collisions need reconciliation first (WP5) |
| Blocked by | WP5 (slug rename first to avoid duplicate slugs in template) |
| Blocks | WP9 (CHANGELOG update needs accurate file count) |

**Acceptance criteria**:
- [ ] Template ADR count goes from 31 → ≥74 (matching AtilCalc + WP5 new slugs)
- [ ] ADR INDEX.md updated with new rows
- [ ] No duplicate slugs within template (after WP5)
- [ ] Peer check: each new ADR is referenced by at least one sibling ADR or wiki page (anti-hallucination check per cycle ~#2259)

### WP5 — Reconcile 3 ADR slug-ID collisions (1 day, architect)

| Attribute | Value |
|---|---|
| Owner | @architect |
| Repo | atilproject/dev-studio-template |
| Files | `ADR-0046-d-test-convention.md` + `ADR-0047-deploy-automation-pattern.md` + `ADR-0060-claude-code-2.1.207-agent-flag.md` |
| Strategy | Rename to free IDs (use ADR-0100, 0101, 0102 to keep them separate from AtilCalc's numbers) |
| Documentation | Add a note to ADR-0001: "ADR numbers are NOT globally unique across repos; refer by full path" |
| Blocked by | — |
| Blocks | WP4 (backport must happen after slug reconciliation) |

**Acceptance criteria**:
- [ ] Template no longer has `ADR-0046-d-test-convention.md`, `ADR-0047-deploy-automation-pattern.md`, `ADR-0060-claude-code-2.1.207-agent-flag.md`
- [ ] All 3 renamed to `ADR-0NNN-<slug>.md` with NNN not used by AtilCalculator (use 0100/0101/0102)
- [ ] Cross-repo ADR-0001 amended: "ADR numbers non-unique across org" note

### WP6 — Port `e2e-pilot.sh` to template (2-3h, developer)

| Attribute | Value |
|---|---|
| Owner | @developer |
| Source | atilproject/AtilCalculator `scripts/e2e-pilot.sh` |
| Target | atilproject/dev-studio-template `scripts/e2e-pilot.sh` |
| Strategy | Copy + generalize (e2e-pilot.sh has AtilCalc-specific assertions — must abstract to env-vars) |
| Blocked by | — |
| Blocks | — (independent) |

**Acceptance criteria**:
- [ ] `scripts/e2e-pilot.sh` exists at template root
- [ ] When launched against smoke repo (`/path/to/smoke`), runs and reports ≥29/29 PASS
- [ ] No AtilCalc-specific imports / hardcoded paths (use env-vars)

### WP7 — Enable branch protection on 3 main repos (10 min, human + PAT)

| Attribute | Value |
|---|---|
| Owner | @human (or @orchestrator via PERSONAL PAT, not CI PAT) |
| Repos | atilproject/AtilCalculator, dev-studio-template, dev-studio-launcher |
| Action | GitHub Settings → Branches → Add rule for `main` |
| Rule body | JSON: required_status_checks (label-check + ci + lint-and-test), enforce_admins=true, required_pull_request_reviews=1, dismiss_stale=true |
| Blocked by | WP3 (flag works first) |
| Blocks | — |

**Acceptance criteria**:
- [ ] All 3 repos: `gh api repos/.../branches/main/protection` returns 200 (not 404)
- [ ] Attempt to push directly to main in any of 3 fails with "branch protected"

### WP8 — Migrate `new-projectsteps.md` to template docs (1h, orchestrator)

| Attribute | Value |
|---|---|
| Owner | @orchestrator |
| Source | AtilCalculator root: `new-projectsteps.md` (this PR) |
| Target | atilproject/dev-studio-template `docs/OPERATIONS.md` |
| Strategy | Copy content + replace AtilCalculator-specific examples with template-generic ones |
| Blocked by | WP1 (template published first to ensure consumers see latest docs) |
| Blocks | WP9 |

**Acceptance criteria**:
- [ ] `atilproject/dev-studio-template/docs/OPERATIONS.md` exists, content is ≥5 sections
- [ ] AtilCalculator-root `new-projectsteps.md` deleted (now lives in template)
- [ ] Cross-link from `template README.md` → `docs/OPERATIONS.md`

### WP9 — Update CHANGELOG.md across 3 repos (30 min, orchestrator)

| Attribute | Value |
|---|---|
| Owner | @orchestrator |
| Repos | AtilCalculator, dev-studio-template, dev-studio-launcher |
| Files | `CHANGELOG.md` in each |
| Action | Add Sprint 30 entry to each repo's CHANGELOG |
| Blocked by | WP1, WP2, WP8 |

**Acceptance criteria**:
- [ ] 3 `CHANGELOG.md` files have `## Sprint 30` section
- [ ] At least 9 bullets across 3 files (one per WP)

---

## §Sister-cluster cadence (tmpl-side + launcher-side, owner "go" parallel)

After owner signals "go" on Sprint 30:

```
WP1 (human 5min) ──┐
                   ├─→ WP3 (dev, launcher PR) ─→ WP7 (human, branch protection on 3 repos)
WP2 (human 5min) ──┘
WP4 (arch, tmpl PR — after WP5)
WP5 (arch, tmpl PR)
WP6 (dev, tmpl PR)
WP8 (orch, tmpl PR — after WP1 publish)
WP9 (orch, 3 PRs — after WP1, WP2)
```

**Critical path**: WP1 + WP2 (human manual) → WP3 + WP4 + WP5 + WP6 (parallel agent work) → WP7 + WP8 + WP9 (sequential cleanup)

**Owner check-in**: at WP1 + WP2 + WP7 boundaries (3 manual steps).

---

## §Acceptance criteria (Sprint 30 close)

| AC | Description | Owner verification |
|---|---|---|
| AC1 | Template v1.0.1 published (not draft) | `gh api ... /releases` shows `v1.0.1 draft:false` |
| AC2 | Launcher v1.0.1 tagged + released | `gh api ... /tags` includes `v1.0.1` |
| AC3 | `--enable-branch-protection` flag works | Smoke repo's main branch protected post-flag |
| AC4 | All 3 main repos have GitHub-side branch protection | `gh api ... /branches/main/protection` 200 on all 3 |
| AC5 | Template has ≥74 ADRs (matching AtilCalc) | `gh api ... /contents/docs/decisions` count |
| AC6 | ADR slug-ID collisions documented or fixed | No `tmpl ADR-0046/0047/0060` overlap with AtilCalc |
| AC7 | `e2e-pilot.sh` ported to template, runs ≥29/29 PASS on smoke | manual run |
| AC8 | `new-projectsteps.md` migrated to template `docs/OPERATIONS.md` | file exists in template |
| AC9 | 3 `CHANGELOG.md` have Sprint 30 entry | grep |

---

## §Out of scope (Sprint 30 — explicit do-NOT-do)

- ❌ Do NOT add new features to `new-project.sh` beyond WP3 + WP4-related changes.
- ❌ Do NOT change `.claude/CLAUDE.md.tmpl` (owner-only territory per file ownership matrix).
- ❌ Do NOT modify `.github/workflows/` files (owner-only territory). Architect + tester draft, owner merges.
- ❌ Do NOT merge PRs to atilcan65/AtilCalculator main except via cluster-squash wave (per ADR-0059).
- ❌ Do NOT drift into Sprint 29 carry-over work (Issue #1081, #1045, #1097, #1102 — Sprint 31+ per [[sprint-29-to-sprint-30-boundary-cycle-2741]]).

---

## §Sister-pattern + doctrine references

- ADR-0031 (owner-merge-gate, currently local-only)
- ADR-0010 (per-project systemd watchers)
- ADR-0027 (auto-deploy pattern)
- ADR-0030 (self-hosted runner)
- ADR-0047 (deploy automation pattern, template form)
- ADR-0049 (d-test framework, ≥5 TCs)
- ADR-0055 (Cadence Rule 1 atomic)
- ADR-0059 (cluster-squash doctrine)
- ADR-0060 (Claude Code 2.1.207 agent flag)
- RETRO-005 (org-wide ambiguity doctrine)
- RETRO-023 (cross-repo workstream doctrine)
- RETRO-024 (work-done-elsewhere terminal state)
- Memory: `[[sprint-29-to-sprint-30-boundary-cycle-2741]]`
- Memory: `[[atilcalc-repo-owner-atilproject-not-atilcan65]]`

---

## §Sign-off

- [ ] @architect 9-Lens review per ADR-0045
- [ ] @human owner sign-off + "go" signal (triggers actual Sprint 30 execution)
- [ ] Sprint 30 Kickoff issue NOT opened until "go" signal

---

*Drafted by @orchestrator cycle ~#2746 for owner review. PR link TBD pending commit + push.*
