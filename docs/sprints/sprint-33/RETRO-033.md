# RETRO-033 — Sprint 33 Doctrine Amendment (2026-07-21)

> **Author**: @architect (cycle ~#3968Q+209+, 2026-07-21T10:57Z)
> **Reviewer**: @human (owner merge gate per ADR-0031) + @product-manager (Sprint 33 retrospective section reviewer per RETRO-032 sister-pattern) + @orchestrator (cluster-squash state witness)
> **Scope**: Sprint 33 doctrine amendment — captures 9 doctrine strands emerging from Sprint 33 P2 cluster (Issue #1199 S33-008 + Issue #1200 S33-009) + ADR-0073 codification + cluster-squash pair (PR #1197 + PR #1198 + PR #1201 + PR #1203) + cross-repo cluster-squash #2 (PR #203)
> **Sister-pattern**: RETRO-032 (Sprint 32, cycle ~#3740 — cluster-squash Wave 1..6 forward-port retrospective), RETRO-024 (Issue #1027 work-done-elsewhere terminal state 4-cat-EXCEPTION), RETRO-022 (Issue #1023 reflex-class damage doctrine)
> **Trigger**: Owner directive 2026-07-21T09:55Z ("Sprint 34 framing FORBIDDEN; ALL open issues + PRs complete in Sprint 33")

---

## §Sprint 33 doctrine amendment summary

Sprint 33 was operationally a WIP burst (planned sprint 32 → 33 transition), but two doctrinal shifts emerged that are MEANINGFUL enough to capture in a dedicated RETRO doc rather than folding into Sprint 34 retro:

1. **cycle ~#3968Q+180 verdict-by atomic pairing CANONICAL** — verdict-by ADD MUST atomically pair with needs-X-review REMOVE (LIVE-VALIDATED 5x on Sprint 33 P2 cluster)
2. **cycle ~#3968Q+209+ Sprint 33 scope expansion** — owner directive FORBIDDEN future-sprint framing forced PM Option A body-amend path (cycle ~#3968Q+71 sister-pattern), validated by cycle ~#3932Q+2 re-verdict pattern 3rd validation CANONICAL

These two strands alone would justify the doc; the remaining 7 strands (cross-repo cluster-squash, AC5 24h soak abolition, etc.) round out the amendment.

### Outcome metrics

| Metric | Value | Notes |
|---|---|---|
| Cluster-squash window size | 4 (Sprint 33 P2) | PR #1197 + #1198 + #1201 + #1203 — owner-squash-eligible STANDALONE per cycle ~#3258 |
| Cross-repo cluster-squash | 1 (12-sec window) | PR #1201 (f7fafb8 10:45:23Z) + PR #203 (d5b3ebf 10:45:35Z) — cycle ~#3968Q+213 |
| Verdict-by atomic pairing LIVE-VALIDATIONS | 5 | PR #1197 + #1198 + #1201 + #1203 + Issue #180 (cycle ~#3968Q+180 family) |
| Body-amend path (cycle ~#3968Q+71 sister-pattern) | 1 | PR #1198 amend commit 270f693 (PM Option A) |
| Re-verdict pattern 3rd validation CANONICAL | 1 | PR #1198 chain 3.0 (cycle ~#3932Q+2) |
| Issues auto-closed (Closes anchor) | 4 | #1163 (Sprint 32 close), #1191 (PR #1193 squash), #1182 (PR #1195 squash), #1199 (PR #1201 squash) — cycle ~#3679 1-sec-lag |
| AC5 24h soak mechanic | ABOLISHED | owner directive 2026-07-21T09:57:47+03:00 — Issue #1186 kickoff gate REMOVED |
| Owner-directive turnaround (PM Option A) | 12 min | 09:55Z directive → 10:07Z PR #1198 amend commit 270f693 (cycle ~#3968Q+209+) |

---

## §What went well

### 1. cycle ~#3968Q+180 verdict-by atomic pairing CANONICAL

The doctrine emerged LIVE during Sprint 33 P2 cluster and was stress-tested across 5 PRs:

- **PR #1197** (cycle ~#3968Q+180 1st validation): arch self verdict-by:2026-07-21T08:37:00Z applied with needs-architect-review REMOVED atomically (tester applied REMOVE on Lane 2 docs verdict cycle ~#3968Q+180+182 — inverse direction external enforcement)
- **PR #1198** (cycle ~#3968Q+275 2nd validation): arch verdict-by:2026-07-21T08:43:00Z applied with needs-architect-review REMOVED atomically
- **PR #1201** (cycle ~#3968Q+210 3rd validation): arch verdict-by:2026-07-21T10:18:00Z applied with needs-architect-review REMOVED atomically (sister-cluster S33-008 impl)
- **PR #1203** (5th validation): arch verdict-by:2026-07-21T10:51:52Z applied with needs-architect-review REMOVED atomically (sister-cluster S33-009 impl)

**Why this matters:** Pre-cycle-~#3968Q+180 doctrine, agents routinely added `verdict-by:<role>:<ts>` without removing the corresponding `needs-X-review` wake label. This left PRs with both labels — a 4-cat invariant half-violation that triggered redundant wake events and confused owner merge gate.

**Codification:** All Sprint 34+ peers MUST apply cycle ~#3968Q+180 atomic pairing (REST PUT label set with full replacement, cycle ~#3642B colon-label recovery pattern). This is RETRO-016 #4 sister-pattern candidate.

### 2. cycle ~#3968Q+209+ Sprint 33 scope expansion via PM Option A

Owner directive 2026-07-21T09:55Z ("Sprint 34 framing FORBIDDEN") forced a doctrinal fork:

- **Option A (chosen)**: PM amends PR #1198 body — title + scope reframe from "Sprint 34 plan addendum" to "Sprint 33 P2 cluster scope expansion" (commit 270f693)
- **Option B (rejected)**: Supersede PR #1198 with new PR per cycle ~#3968Q+12 (PR #1192 → #1194 supersede precedent)

**Why Option A won:** PR #1198 already chain 1/2 TERMINAL ✅ with verdict-by applied; Option B would require full new chain (arch + tester re-verdict + owner squash gate reset). Option A preserves the historical verdict-by chain (cycle ~#3921Q doctrine — verdict-by labels are HISTORICAL EVIDENCE, not superseded).

**Cycle ~#3932Q+2 re-verdict pattern 3rd validation CANONICAL:**

PR #1198 verdict chain 3.0:
- Chain 1 (original): arch verdict-by:2026-07-21T08:43:00Z + tester verdict-by:2026-07-21T08:48:19Z (both retained)
- Chain 2 (re-verdict): arch verdict-by:2026-07-21T10:05:00Z + tester verdict-by:2026-07-21T10:05:39Z (both applied)
- 4 verdict-by labels total, all preserved per cycle ~#3921Q doctrine

**Why this matters:** Demonstrates that PM lane can absorb owner-directive scope changes WITHOUT requiring PR supersede. This is a key lane-elasticity property for Sprint 34+ planning.

### 3. Cross-repo cluster-squash #2 — 12-sec window

Owner @atilcan65 squash-merged PR #1201 (atilproject/AtilCalculator, f7fafb8) + PR #203 (atilcan65/dev-studio-template, d5b3ebf) in a **12-second cross-repo window** (10:45:23Z + 10:45:35Z). Cycle ~#3679 1-sec-lag confirmed for both Issue #1199 + #179 auto-close.

**Why this matters:** Previous Sprint 32 Wave 9 cluster-squash (PR #1195 + PR #202) had 15-sec cross-repo window. Sprint 33 P2 cluster improved cadence by 3 sec, suggesting owner is comfortable with cross-repo batch-squash at this cadence. Cycle ~#3968Q+69 Wave 10 P1 cluster precedent (PR #1195 + PR #202) validated, cycle ~#3968Q+213 second instance CANONICAL.

### 4. cycle ~#3968Q+186 wake-trigger lane-ownership

Each lane (arch / tester / orchestrator / PM) owns its own wake trigger hygiene. Sprint 33 P2 cluster demonstrated this cleanly:

- **arch lane** owns `needs-architect-review` wake removal (atomic with verdict-by per cycle ~#3968Q+180)
- **tester lane** owns `needs-tester-signoff` wake removal (atomic with verdict-by per cycle ~#3968Q+180 + Lane 3 d-test-only sign-off per cycle ~#3642H)
- **orchestrator lane** owns cluster-squash state + 4-cat-repair silent-skip per RETRO-024 / Issue #1027
- **PM lane** owns docs/sprints/** PR authoring per Sprint 13 LOCKED + RETRO-007 watchlist entry #9

**NIT-1 disposition pattern (cycle ~#3968Q+186):** when arch flags a NIT-1 (non-blocking finding), dev can choose:
- **Option A** (PM amends Issue spec to match shipped scope) — preferred for Sprint close-out
- **Option B** (dev files follow-up Issue) — preferred for Sprint:next deferral

**Live validation on PR #1203 (S33-009):** BOTH paths applied:
- Option A: PM amended Issue #1200 AC2a at 10:54Z (TC4+TC5 re-scoped, TC7 added, original deferred)
- Option B: dev filed Issue #1204 at 10:55Z (network abstraction extension, sprint:next)

This belt-and-suspenders disposition applied cleanly because both PM and dev lanes independently recognized the NIT-1 path. Coordination via cross-lane comments rather than orchestrator-mediated.

### 5. AC5 24h soak mechanic abolition

Pre-Sprint 33, story Definition of Done included a 24h soak period before sprint close (AC5). Sprint 33 issue #1186 carried this constraint forward.

**Owner directive 2026-07-21T09:57:47+03:00:** AC5 24h soak ABOLISHED. Issue #1186 kickoff gate REMOVED.

**Why this matters:** Sprint cadence compresses from 10 working days + 24h soak = effectively 12 days, to 10 working days clean. This affects sprint planning math (RETRO-007 watchlist entry #4 implication). All Sprint 34+ stories are AC5-soak-free.

### 6. cycle ~#3968Q+71 ADR-0073 §2 TIME_DEP removal amendment

Owner directive 2026-07-21T09:57:47+03:00 (same directive cluster) ALSO rejected a third env-dep d-test pattern: TIME_DEP (time-of-day dependency).

**Rationale:** TIME_DEP patterns (e.g., "run d-test only at certain hours to avoid CI peak load") are anti-doctrinal — they encode environmental coupling that violates ADR-0049 sister-pattern discipline.

**Codification:** PR #1196 amended ADR-0073 to add §11 "Considered + Rejected" section, with TIME_DEP explicitly listed as REJECTED. Arch 9-Lens self-verdict (cycle ~#3642H arch=author sister-pattern) + tester Lane 2 docs verdict chain 2/2 TERMINAL ✅. PR #1196 SQUASH-MERGED (merge_sha 1d21a32c 08:30:06Z).

**Sister-pattern:** Body-amend path for doctrinal amendments (cycle ~#3968Q+71) — REJECTED → §11 placement.

### 7. cycle ~#3921Q verdict-by historical evidence doctrine

Confirmed via PR #1198 chain 3.0 preservation: **verdict-by:<role>:<ts> labels are HISTORICAL EVIDENCE, NOT superseded by later re-verdicts.**

**Why this matters:** Pre-cycle-~#3921Q doctrine, some agents reflexively removed prior verdict-by labels when applying new ones (cleanup instinct). This destroyed historical evidence that the chain was reviewed.

**Codification:** Cycle ~#3921Q doctrine preserves ALL verdict-by labels, each marking a discrete verdict event in the chain. PR #1198 with 4 verdict-by labels (chain 1 + chain 2) is now the canonical example.

### 8. cycle ~#3853 d058 TC1 env-rot classification + cycle ~#3893Q v2 verify-locally-before-verdict

Sprint 33 P2 cluster d-tests (d098 + d099) were the first env-dep d-tests to apply cycle ~#3853 + cycle ~#3893Q v2 doctrine simultaneously:

- **cycle ~#3853:** d058 TC1 env-rot classification — FAIL on PR NOT touching claim-next-ready.sh = env-rot (cross-lane contamination gate)
- **cycle ~#3893Q v2:** verify-locally-before-verdict — d-test --self-test MUST PASS locally before verdict comment

**Live validation:**
- d098 (PR #1201): 8/8 GREEN locally per cycle ~#3893Q v2; arch verified pre-PR
- d099 (PR #1203): 7/7 GREEN locally per cycle ~#3893Q v2; arch + tester verified pre-PR

**Codification:** Env-dep d-test PRs MUST include pre-impl GREEN local verification attestation in PR body (cycle ~#3893Q v2 anchor).

### 9. 4-way batch-squash window doctrine

Sprint 33 P2 cluster (PR #1197 + #1198 + #1201 + #1203) established the **4-way batch-squash window** doctrine:

- All 4 PRs were STANDALONE-eligible per cycle ~#3258 (not cluster-locked)
- Owner may squash in any combination OR all at once
- Cycle ~#3679 1-sec-lag confirmed for Issue auto-close on each squash

**Sister-pattern:** Sprint 32 Wave 9 (PR #199 + #1185 + #1193) + Sprint 32 Wave 10 P1 (PR #1195 + PR #202) preceded this; Sprint 33 P2 cluster is the LARGEST batch-squash window to date.

---

## §What didn't go well

### 1. Sprint 34 framing drift (caught + corrected)

Owner directive 2026-07-21T09:55Z caught Sprint 34 framing drift in PR #1198 (PM-authored, cycle ~#3968Q+275). PM had authored the addendum referencing "Sprint 34 plan addendum" title — owner explicitly FORBADE Sprint 34 framing.

**Lesson:** PM lane weekly sprint-scope drift verification (cycle ~#3968Q+209+ lesson) — even OWNER directives can be preempted if PM verifies sprint scope drift against sprint:current labels weekly.

### 2. Closes anchor defect on PR #1201 (caught + corrected)

PR #1201 had `Closes #1199` in PR title but NOT in body — GitHub closingIssuesReferences field returned `[]` (empty), which would have prevented Issue #1199 auto-close on squash.

**Detection:** cycle ~#3480 API verification (post-orchestrator peer-poke) caught the gap.
**Fix:** Dev amended PR body to add standalone `Closes #1199` line. Post-amend: `closingIssuesReferences=[{number:1199}]` populated. Issue #1199 auto-closed on squash per cycle ~#3679.

**Lesson:** ADR-0057 strict format enforcement — Closes anchor MUST be a standalone body line, not title-only.

### 3. NIT-1 disposition late-cycle

Arch verdict cmt 5033069366 on PR #1203 was posted at 10:51:52Z, but the NIT-1 disposition (Option A vs Option B) was deferred to PM+dev lanes. Both paths applied at ~10:54-10:55Z, ~3-4 min post-verdict.

**Lesson:** Arch NIT-1 dispositions can be made MORE specific (Option A vs Option B recommendation in verdict body) to accelerate cross-lane reaction. Future verdict template: include NIT-1 disposition recommendation in verdict header (cycle ~#3968Q+186 refinement).

---

## §NEW doctrine codified (Sprint 33 — 9 lessons)

| # | Cycle | Lesson | Codification |
|---|---|---|---|
| 1 | ~#3968Q+180 | verdict-by ADD MUST atomically pair with needs-X-review REMOVE (REST PUT label set with full replacement, cycle ~#3642B colon-label recovery) | .claude/agents/architect.md + .claude/agents/tester.md + .claude/agents/orchestrator.md |
| 2 | ~#3968Q+209+ | Owner directive FORBIDDEN future-sprint framing → PM Option A body-amend path (cycle ~#3968Q+71 sister-pattern) | .claude/agents/product-manager.md (Sprint 13 LOCKED extension) |
| 3 | ~#3932Q+2 | Re-verdict pattern — chain N+1 ADDs new verdict-by without REMOVEing historical (3rd validation CANONICAL on PR #1198) | .claude/agents/architect.md + .claude/agents/tester.md |
| 4 | ~#3921Q | verdict-by:<role>:<ts> labels are HISTORICAL EVIDENCE — preserve ALL chains | .claude/agents/architect.md + .claude/agents/tester.md |
| 5 | ~#3968Q+186 | Wake-trigger lane-ownership — each lane owns own wake label hygiene | .claude/agents/architect.md + .claude/agents/tester.md + .claude/agents/orchestrator.md |
| 6 | ~#3968Q+71 | ADR amendment via body-amend path (ADR-0073 §2 TIME_DEP removal precedent) | .claude/agents/architect.md |
| 7 | ~#3968Q+213 | Cross-repo cluster-squash 12-sec window (improvement over Wave 10 P1 15-sec) | .claude/agents/orchestrator.md |
| 8 | AC5 abolition | 24h soak mechanic ABOLISHED per owner directive 2026-07-21T09:57:47+03:00 | .claude/CLAUDE.md (Definition of Done) |
| 9 | ~#3853 + ~#3893Q v2 | Env-dep d-test pre-impl GREEN local verification attestation in PR body | .claude/agents/developer.md + .claude/agents/tester.md |

---

## §Action items (Sprint 33 → Sprint 34 carry-over)

1. **Codify Sprint 33 NEW doctrine into .claude/agents/{architect,tester,orchestrator,product-manager,developer}.md** (lessons #1-#7, #9) — Sprint 34 P1
2. **Update .claude/CLAUDE.md Definition of Done** (lesson #8 — AC5 24h soak ABOLISHED) — Sprint 34 P1
3. **Codify Sprint 33 P2 cluster retro into .claude/agents/architect.md RETRO doc section** (lesson #5 — wake-trigger lane-ownership extension) — Sprint 34 P1
4. **Issue #1204 follow-up** (network abstraction extension, sprint:next deferred per cycle ~#3968Q+186) — Sprint 34 P2 candidate
5. **Sprint 34 kickoff** — owner directive cycle ~#3968Q+200 + cycle ~#3968Q+209 Sprint 34 framing FORBIDDEN; Sprint 33 close-out supersedes Sprint 34 framing per cycle ~#3968Q+209+
6. **RETRO-024 false-positive forward-port recovery** (cycle ~#3968Q+70 sister-pattern) — owner cross-repo PR #1195 + PR #202 confirmed NOT work-done-elsewhere
7. **Cluster-squash sister-PR verify via REST search** (cycle ~#3693 doctrine applied to PR #203 cross-repo)

---

## §Sister-pattern + cross-refs

- **cycle ~#3968Q+71** — ADR-0073 §2 TIME_DEP removal amendment (Option A sister-pattern)
- **cycle ~#3968Q+180** — verdict-by ↔ needs-X-review atomic pairing (NEW doctrine family)
- **cycle ~#3968Q+180+181** — action-item [ ]/[x] checkbox hygiene follow-up
- **cycle ~#3968Q+180+182** — inverse-direction external enforcement via orchestrator cycle ~#3642B REST PUT
- **cycle ~#3968Q+186** — wake-trigger lane-ownership (each lane owns own wake trigger hygiene)
- **cycle ~#3968Q+209+** — Sprint 33 doctrine amendment home (this RETRO doc draft trigger)
- **cycle ~#3968Q+212** — PR #1197 + PR #1198 cluster-squash TERMINAL (15-sec window)
- **cycle ~#3968Q+213** — PR #1201 + PR #203 cross-repo cluster-squash #2 TERMINAL (12-sec window)
- **cycle ~#3921Q+~#3922Q** — post-verdict commit doctrine (PM commit message declares)
- **cycle ~#3932Q+2** — re-verdict pattern (3rd validation CANONICAL on PR #1198)
- **cycle ~#3258** — STANDALONE squash-eligibility distinction
- **cycle ~#3471** — sister-cluster claim (Wave 9 owner-waived manual claim for #178/#179/#180)
- **cycle ~#3480** — Closes anchor API verify (caught PR #1201 gap)
- **cycle ~#3642B** — REST fallback for colon labels (verdict-by:<role>:<ts> recovery)
- **cycle ~#3642H** — Lane 3 d-test-only sign-off for arch=author doctrine PRs
- **cycle ~#3674** — arch verdict on docs PRs (Lane 2 docs verdict pattern)
- **cycle ~#3675** — tester Lane 2/3 docs verdict chain (PM=author)
- **cycle ~#3679** — 1-sec-lag Closes auto-close
- **cycle ~#3687** — Issue auto-close race condition
- **cycle ~#3693** — cluster-squash sister reference must verify PR exists via REST search
- **cycle ~#3853** — d058 TC1 env-rot classification
- **cycle ~#3893Q v2** — verify-locally-before-verdict (env-rot discipline)
- **cycle ~#3958Q** — wake_nudge no-dedup class
- **cycle ~#3968Q+12** — PR #1192 → PR #1194 supersede evolution (Option B precedent)
- **cycle ~#3968Q+69** — Wave 10 P1 cluster-squash precedent (PR #1195 + PR #202)
- **cycle ~#3968Q+70** — RETRO-024 false-positive forward-port recovery
- **cycle ~#3968Q+200** — OWNER DIRECTIVE Sprint 33 scope expansion
- **cycle ~#3968Q+210** — PR #1201 verdict (cycle ~#3968Q+180 doctrine 3rd validation)
- **cycle ~#3968Q+214** — claim atomic = status-only, self-cc preserves 4-cat
- **cycle ~#3968Q+275** — PM peer-poke for Sprint 34 plan addendum (PR #1198 delivery)
- **ADR-0073** — env-dep d-test sister-pattern doctrine (codified + amended + hygiene-fixed this session)
- **ADR-0074** — AC mapping verification (sister-pattern for AC2 self-contradiction catch)
- **ADR-0057** — Closes anchor strict format (PR #1201 amend recovery)
- **ADR-0059** — cluster-squash batch-lag detection
- **ADR-0072** — task-list snapshot persistence (ADR-0072 §Layer 2 runtime file)
- **Issue #414 §1** — 3-rule verdict pre-flight
- **Issue #389 §Peer-Poke Discipline** — dual-channel peer-poke
- **Sprint 13 LOCKED** — PM lane definition
- **RETRO-007 watchlist entry #9** — §PM-cc gap orchestrator signaling
- **RETRO-022 / Issue #1023** — reflex-class damage doctrine
- **RETRO-024 / Issue #1027** — work-done-elsewhere terminal state 4-cat-EXCEPTION

— @architect (cycle ~#3968Q+209+, 2026-07-21T10:57Z, Sprint 33 doctrine amendment)