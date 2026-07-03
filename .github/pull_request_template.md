## Summary

<!-- Bu PR ne yapıyor? 1-2 cümle. -->

## Related Issues

<!-- Closes #N, Refs #N -->
Closes #

## Doctrine Impact

<!-- Bu PR proje doktrinini (CLAUDE.md, ADRs, lane discipline, d-test framework) etkiliyor mu?
     YES ise: ADR yazılmalı veya güncellenmeli, d-test eklenmeli (ADR-0049), lane discipline not edilmeli.
     NO ise: "no doctrine impact" yaz.
     Bkz. .claude/CLAUDE.md §§File ownership matrix + lane definitions + Required Label Set.
-->
- [ ] **No doctrine change** — Sadece implementasyon / refactor; mevcut ADRs yeterli
- [ ] **Doctrine change** — `docs/decisions/ADR-NNNN-*.md` yeni veya güncellendi (zorunlu, ADR-0017)
- [ ] **Lane discipline** — Hangi agent(lar) PR'da çalıştı? PM/arch/dev/tester/orchestrator (ADR-0012 4-cat invariant)
- [ ] **d-test** — Yeni ADR ise `scripts/tests/dNNN-*.sh` sibling eklendi (ADR-0049 ≥5 TCs)
- [ ] **CLAUDE.md updated** — Doctrine değiştiyse `.claude/CLAUDE.md` veya ilgili soul file güncellendi

## ADR cross-ref

<!-- Bu PR hangi ADR'ları etkiliyor veya referans veriyor?
     ADR'ları tam başlık + path ile listele. Bkz. docs/decisions/INDEX.md
     Tablo AMAÇLI exhaustive DEĞİLDİR — yukarıda listelenmemiş bir ADR'a referans veriyorsanız satır ekleyin.
-->
| ADR | Title | Impact |
|-----|-------|--------|
| ADR-0012 | 4-cat label invariant (type/status/agent/cc) | [none / partial / full] |
| ADR-0015 | atomic 4-flag hand-off (handoff sırası) | [none / partial / full] |
| ADR-0017 | tech stack (Python 3.11+, pytest, ruff, mypy, decimal) | [none / partial / full] |
| ADR-0031 | owner-merge-gate (squash-merge) | [none / partial / full] |
| ADR-0044 | RED-first TDD (tester d-test BEFORE impl) | [none / partial / full] |
| ADR-0049 | d-test framework (≥5 TCs, sister-pattern) | [none / partial / full] |
| ADR-0057 | anchor strict format (Closes #N vs Refs #N) | [none / partial / full] |
| ADR-0064 | cross-user env-var pattern (Sprint 23 RCA-17) | [none / partial / full] |
| RETRO-017 W2 [PRE-DRAFT] | cross-PR markdown link pattern (RETRO-017 PRE-DRAFT) | [none / partial / full] |
| | | |

## Changes

<!-- Ana değişikliklerin bullet listesi -->
-
-
-

## Type of Change

- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Docs
- [ ] Chore (deps, CI, tooling)
- [ ] Incident response

## Test plan

<!-- Bu PR nasıl test edildi? -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] d-test sibling (ADR-0049 ≥5 TCs) — only for ADR-0017 / -0044 / -0064 PRs
- [ ] Manual testing notes:

## Owner Checklist

<!-- PR'ı merge etmeden önce owner (@atilcan65) tarafından doğrulanması gereken gate'ler.
     Sadece owner tarafından doldurulur; agent'lar boş bırakır.
     Bkz. ADR-0031 owner-merge-gate + ADR-0012 4-cat invariant + RETRO-017 W2.
-->
- [ ] **Owner approval** — `@atilcan65` PR review comment ile onayladı (ADR-0031)
- [ ] **CI green** — `.github/workflows/ci.yml` tüm checks geçti (post-merge)
- [ ] **PR labels correct** — `type:*` + `status:*` + `agent:*` + `cc:*` 4-cat invariant (ADR-0012)
- [ ] **Pre-merge grep clean** — RETRO-017 W2 cross-PR markdown link pattern. Run:
      ```bash
      grep -nE '\]\(\./|\]\(\.\./' <changed-files> || echo "clean"
      ```
- [ ] **Conventional commit** — `feat/fix/chore/docs/refactor(scope): ...` format
- [ ] **Squash-merge plan** — Multi-PR docs cluster ise owner squash cascade planlandı

## Agent Checklist

<!-- Agent'ların (PM/arch/dev/tester) kendi AC doğrulamaları.
     Agent'lar kendi AC'lerini işaretler; owner checklist ayrı.
-->
- [ ] Code follows project style
- [ ] Self-reviewed
- [ ] Tests pass locally
- [ ] Documentation updated (if needed)
- [ ] No secrets/credentials committed
- [ ] Conventional commit message used

## Agent Attribution

<!-- Hangi agent(lar) bu PR'ı oluşturdu? -->
- Primary: <!-- developer / architect / etc. -->
- Reviewers: <!-- tester / orchestrator / etc. -->

## Screenshots / Logs

<!-- Varsa ekle -->
