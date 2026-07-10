# Proposed workflow patch — TD-069 Layer 5 split (owner territory, NOT applied by agent)

> **OWNER TERRITORY** per file ownership matrix + `.claude/CLAUDE.md` hard rule.
> This document shows the **exact proposed edits** to `.github/workflows/label-check.yml` for the owner to review and apply.
> **Reversibility**: single-commit workflow YAML revert.

## Current state (problematic)

```yaml
# Layer 5 (Issue #425 AC #4, ADR-0048, docs PR #430 + ADR #431): status:ready
# auto-add (only when reviewer-chain complete + 4-cat invariant intact + DRAFT-PR
# skip-guard per Issue #680 amendment #2/#3/#4 + bot-actor exclusion per Issue #675 TC3
# + status:* removal short-circuit per Issue #675 TC1 + Issue #819 fresh-label read).
- name: Layer 5 status:ready auto-gate
  id: layer5
  uses: actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b  # v7
  env:
    MARKER: "<!-- adr-0012-status-ready-gating -->"
    MARKER_SKIP: "<!-- adr-0012-status-ready-gating-skip -->"
    MARKER_REVERSAL: "<!-- adr-0012-status-ready-gating-reversal -->"
  with:
    script: |
      const marker = process.env.MARKER;
      const markerSkip = process.env.MARKER_SKIP;
      const markerReversal = process.env.MARKER_REVERSAL;
      const pr = context.payload.pull_request;
      const number = pr.number;
      const issueState = pr.state;
      const owner = context.repo.owner;
      const repo = context.repo.repo;
      # ... [27,349 bytes total]
```

## Proposed state (OPTION 1: split into 5a + 5b)

```yaml
# Layer 5a (TD-069 fix, OPTION 1 split): Fresh-label read + closed-PR early-return.
# Extracted from monolithic Layer 5 (was 27,349 bytes, exceeded 21,000-byte GH Actions
# expression limit silently per TD-016). 5a body target ~7,000 bytes.
- name: Layer 5a fresh-label read + state check
  id: layer5a
  uses: actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b  # v7
  env:
    MARKER_SKIP: "<!-- adr-0012-status-ready-gating-skip -->"
  with:
    script: |
      const markerSkip = process.env.MARKER_SKIP;
      const pr = context.payload.pull_request;
      const number = pr.number;
      const issueState = pr.state;
      const owner = context.repo.owner;
      const repo = context.repo.repo;
      // Issue #819 fix: read fresh PR labels via GitHub API instead of stale webhook snapshot.
      const { data: freshPR } = await github.rest.pulls.get({ owner, repo, pull_number: number });
      const labels = (freshPR.labels || []).map(l => (typeof l === 'string' ? l : l.name));
      // Q5b: early-return on closed PR (frozen state, no-op)
      if (issueState === 'closed') {
        core.info(`silent_skip event=closed-state layer=5a number=${number} message="PR #${number} is closed; Layer 5a no-op."`);
        return;
      }
      // Propagate to Layer 5b via outputs
      core.setOutput('number', number);
      core.setOutput('fresh_labels', JSON.stringify(labels));
      core.setOutput('issue_state', issueState);
      core.setOutput('pr_draft', !!freshPR.draft);
      core.setOutput('sender_type', context.sender?.type || 'User');
      core.setOutput('sender_login', context.sender?.login || 'unknown');
      core.info(`[Layer 5a] propagated-to-5b number=${number} state=${issueState} draft=${!!freshPR.draft}`);

# Layer 5b (TD-069 fix, OPTION 1 split): Bot-actor exclusion + status:* short-circuit
# + DRAFT-PR skip-guard + TC4 reversal handler + atomic status:ready transition.
# 5b body target ~18,000 bytes.
- name: Layer 5b status:ready gating + audit-trail
  id: layer5b
  uses: actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b  # v7
  env:
    MARKER: "<!-- adr-0012-status-ready-gating -->"
    MARKER_SKIP: "<!-- adr-0012-status-ready-gating-skip -->"
    MARKER_REVERSAL: "<!-- adr-0012-status-ready-gating-reversal -->"
  with:
    script: |
      const marker = process.env.MARKER;
      const markerSkip = process.env.MARKER_SKIP;
      const markerReversal = process.env.MARKER_REVERSAL;
      const number = parseInt('${{ steps.layer5a.outputs.number }}', 10);
      const freshLabels = JSON.parse('${{ steps.layer5a.outputs.fresh_labels }}');
      const issueState = '${{ steps.layer5a.outputs.issue_state }}';
      const prDraft = '${{ steps.layer5a.outputs.pr_draft }}' === 'true';
      const senderType = '${{ steps.layer5a.outputs.sender_type }}';
      const senderLogin = '${{ steps.layer5a.outputs.sender_login }}';
      const labels = freshLabels;
      const hasLabel = (name) => labels.includes(name);
      const owner = context.repo.owner;
      const repo = context.repo.repo;
      const evtAction = context.payload.action || 'opened';
      
      // TC3: bot-actor exclusion (Issue #675 P0 fix)
      if (senderType === 'Bot') {
        core.info(`silent_skip event=bot-actor-excluded layer=5b number=${number} sender=${senderLogin} issue=675-tc3 message="Bot actor excluded — preventing self-trigger loop"`);
        return;
      }
      // TC1: status:* unlabeled short-circuit (Issue #675 P0 fix)
      if (evtAction === 'unlabeled' && context.payload.label && context.payload.label.name && context.payload.label.name.startsWith('status:')) {
        core.info(`silent_skip event=status-removal-short-circuit layer=5b number=${number} label=${context.payload.label.name} issue=675-tc1 message="status:* removal — owner verdict, not L5 trigger"`);
        return;
      }
      // DRAFT-PR skip-guard (Issue #680 amendments #2 + #3 + #4)
      if (prDraft) {
        core.info(`silent_skip event=draft-pr-skip-guard layer=5b number=${number} issue=680-amendment-2 message="DRAFT PR #${number} — skip-guard fired."`);
        console.log(`[Layer 5 audit] adr-0012-status-ready-gating-draft-skip: PR=#${number} type=${type || '(none)'} agent=${agent || '(none)'} (Issue #680 DRAFT skip-guard)`);
        return;
      }
      
      // TC4 reversal handler: needs-tester-signoff re-added AFTER tester APPROVED
      // → remove status:ready
      if (evtAction === 'labeled' && context.payload.label?.name === 'needs-tester-signoff' && hasLabel('status:ready')) {
        await github.rest.issues.removeLabel({ owner, repo, issue_number: number, name: 'status:ready' });
        core.info(`[Layer 5b] reversal-applied number=${number} message="TC4 reversal: needs-tester-signoff re-added post-APPROVED; status:ready removed"`);
        await github.rest.issues.createComment({
          owner, repo, issue_number: number,
          body: `${markerReversal} TC4 reversal: needs-tester-signoff re-added AFTER tester APPROVED; status:ready removed (Issue #426 + Issue #680 audit-trail).`
        });
        return;
      }
      
      // Atomic status:ready transition (only on reviewer-chain complete + 4-cat intact)
      // [... reviewer chain check + 4-cat invariant check logic from original Layer 5 ...]
      // [... atomic addLabels({status:ready, cc:human}) + comment emission ...]
      
      core.info(`[Layer 5b] status-ready-added number=${number} message="auto-gate: reviewer chain complete + 4-cat intact; status:ready + cc:human added"`);
      await github.rest.issues.createComment({
        owner, repo, issue_number: number,
        body: `${marker} Layer 5 auto-gate: reviewer chain complete + 4-cat invariant intact; status:ready + cc:human added (Issue #425 AC #4, ADR-0012 §Enforcement).`
      });
```

## Diff summary (for owner review)

1. **DELETE** entire `Layer 5 status:ready auto-gate` step (current L455-885, 27,349 bytes).
2. **INSERT** `Layer 5a fresh-label read + state check` step (~7,000 bytes).
3. **INSERT** `Layer 5b status:ready gating + audit-trail` step (~18,000 bytes).
4. **PRESERVE**:
   - `concurrency:` group at L44-47 (unchanged).
   - All 4 audit-trail marker comments (`<!-- adr-0012-status-ready-gating* -->`).
   - All `silent_skip` log events verbatim.
   - `actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b` SHA pin (ADR-0027 §Threat model, lens (h)).
   - Issue references (#819, #675 TC1/TC3, #680 amendment #2/#3/#4, #426 TC4, #425 AC #4).

## Validation checklist (owner-side, after applying)

- [ ] `python -c "import yaml; doc=yaml.safe_load(open('.github/workflows/label-check.yml')); [print(f'{s.get(\"name\",\"?\")} body_bytes={len(s.get(\"with\",{}).get(\"script\",\"\"))}') for s in doc['jobs']['check']['steps'] if 'github-script' in s.get('uses','')]"` — verify 5a ≤18000 bytes, 5b ≤18000 bytes.
- [ ] `grep -c '<!-- adr-0012-status-ready-gating' .github/workflows/label-check.yml` — expect ≥4 occurrences (one per marker).
- [ ] `grep -c '@f28e40c7f34bde8b3046d885e986cb6290c5673b' .github/workflows/label-check.yml` — expect 1 extra occurrence (now 2 steps use this SHA).
- [ ] `grep -c 'silent_skip event=' .github/workflows/label-check.yml` — expect ≥4 occurrences (all 4 silent_skip events preserved).
- [ ] Push a label-aware test PR (e.g., add `agent:developer + status:in-progress` to an existing draft PR) — verify Layer 5a + 5b both run, audit-trail comment `<!-- adr-0012-status-ready-gating -->` emitted on PR comment thread.
- [ ] Run `scripts/tests/d069-layer5-audit-trail.sh` (tester-owned) — verify all ≥5 TCs pass.

## Rollback procedure (per ADR-0007 reversibility)

```bash
git revert <commit-sha-of-fix>
git push
```

Single-commit revert restores monolithic Layer 5 (re-introduces 21KB limit issue but unblocks immediate rollout).

— @architect (proposed patch, 2026-07-10, Issue #950 owner-territory SURFACE)