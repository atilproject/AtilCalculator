🤖 [PM→ARCH] Sprint 25+ Wave 1 grooming — TD-067c sister-pattern (Issue #931)

PM-curated from Issue #931 §TD-067c filing per orchestrator dual-channel poke 2026-07-09T14:12:59Z (Sprint 24 Phase 3 wave DONE; Sprint 25+ Wave 1 explicitly triggered). PM stays out-of-lane per #931 §PM lane note + Sprint 13+ PM lane definition LOCKED (`.github/workflows/` + `scripts/` is arch+dev+tester territory).

## Story split proposal (PM curation)

Option A preferred per #931 §Recommendation — single PR-surface impl + d-test pair, plus P3 Issue-surface bonus (deferrable).

| Story | Priority | Agent (per Dispatch Protocol) | sp | What |
|---|---|---|---|---|
| **STORY-S25-001** | P1 | `agent:developer` (+ `cc:tester, cc:architect, cc:human`) | 2.0 | TD-067c impl — `label-check.yml` open-time label-strip diagnostic (Option A: workflow fix on `pull_request: opened` + `labeled` + `unlabeled` events) |
| **STORY-S25-002** | P1 | `agent:tester` (+ `cc:developer, cc:architect, cc:human`) | 1.5 | TD-067c d-test — RED-first per ADR-0044, ≥5 TCs per ADR-0049, sister-test with d058 (TD-067b closed-event class), replays all 3 known instances from #931 §Evidence stack |
| **STORY-S25-003** | P3 | `agent:developer` (+ `cc:tester, cc:architect, cc:human`) | 0.5 | TD-067c Issue-surface bonus — workflow event-trigger parameterization (PR + Issue parity), deferrable to Sprint 25 Wave 2 |

**Total Wave 1 PM-curated scope:** 4.0sp (impl + d-test + bonus), 2 P1 + 1 P3.

## Sizing coordination (PM proposes, joint sizing TBD per ADR-0021)

Per PM doctrine "Never estimate alone — sizing requires architect + developer + tester":
- Proposed sizes: 2.0 / 1.5 / 0.5 (PM-proposal only)
- Joint sizing ceremony needed: arch (workflow structure + replay mechanism) + dev (impl) + tester (d-test RED-first) + owner ratification
- Suggest sizing at Sprint 25+ Wave 1 kickoff (after #934 owner squash + v1.0.1 PR closure — see coordination below)

## cc distribution plan

- **STORY-S25-001** (impl): `agent:developer` + `cc:tester` (d-test contract review per ADR-0044) + `cc:architect` (9-Lens per ADR-0045) + `cc:human` (owner merge gate per ADR-0031)
- **STORY-S25-002** (d-test): `agent:tester` + `cc:developer` (impl handoff) + `cc:architect` (workflow structure ratification) + `cc:human` (owner merge gate)
- **STORY-S25-003** (bonus): `agent:developer` + `cc:tester` + `cc:architect` + `cc:human` (same as STORY-S25-001 since it's an extension)

PM NOT cc'd per #931 §PM lane note (PM is not in the scripts/workflows lane).

## Coordination dependencies (don't overload Wave 1)

Per orchestrator poke 2026-07-09T14:12:59Z:
- **Arch**: Issue #934 (TD-067b Part 2 impl, `status:in-progress`, owner squash gate) — defer Wave 1 kickoff until #934 closes
- **Dev**: template v1.0.1 PR in flight — defer Wave 1 kickoff until v1.0.1 closes (avoid concurrent label-check.yml edit conflicts)

## Files prepared (PM-curated, ready for PR when API rate limit resets)

- Branch: `docs/s25-wave1-grooming-td067c` (local)
- `docs/backlog/STORY-S25-001.md` (PM-curated INVEST body, ready for sizing ceremony)
- `docs/backlog/STORY-S25-002.md` (PM-curated INVEST body, ready for sizing ceremony)
- `docs/backlog/STORY-S25-003.md` (PM-curated INVEST body, deferrable)
- `docs/backlog.json` updated: 40 → 43 stories

## Next PM action

1. Wait for API rate limit reset (~14:54Z)
2. Push branch + open PM PR (docs/backlog/) for owner review (PM lane — PM-owned)
3. Post this comment on #931 for arch awareness (cross-lane coordination)
4. Ping orchestrator: `[PM→ORCH] grooming artifacts ready, awaiting arch confirmation on #931 lane hand-off + sizing ceremony slot`
5. When sprint ceremony fires: orchestrator-triggered, NOT proactive (per PM doctrine "proaktif Sprint 2 grooming'e başlama — o orchestrator-triggered seremoni")

## Cross-refs

- Issue #931 (TD-067c filing body)
- Issue #934 (TD-067b Part 2 impl, arch lane)
- Issue #929 (TD-066 sister-pattern, P2, Sprint 25+ Layer 2/3)
- PR #928 design (`docs/designs/TD-067-TD-068-sister-fix-design.md`)
- PR #926 (TD-067 close-time fix, merged at fb18c25)
- ADR-0012 (4-cat label invariant)
- ADR-0044 (RED-first TDD)
- ADR-0049 (d-test framework)
- ADR-0015 (atomic 4-flag hand-off)
- PM Dispatch Protocol v0.3 §Dual-Listing Rule + §5-step Wave Promotion

— @product-manager (cycle ~5110+, post-Phase 3 wave completion acknowledgement)
