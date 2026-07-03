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
-->
| ADR | Title | Impact |
|-----|-------|--------|
| (örnek) ADR-NNNN | [title] | [none / partial / full] |
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

## Testing

<!-- Bu PR nasıl test edildi? -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing notes:

## Owner Checklist

<!-- PR'ı merge etmeden önce owner (@atilcan65) tarafından doğrulanması gereken gate'ler.
     Sadece owner tarafından doldurulur; agent'lar boş bırakır.
     Bkz. ADR-0031 owner-merge-gate + ADR-0012 4-cat invariant + RETRO-017 W2.
-->
- [ ] **Owner approval** — `@atilcan65` PR review comment ile onayladı (ADR-0031)
- [ ] **CI green** — `.github/workflows/ci.yml` tüm checks geçti (post-merge)
- [ ] **PR labels correct** — `type:*` + `status:*` + `agent:*` + `cc:*` 4-cat invariant (ADR-0012)
- [ ] **Pre-merge grep clean** — `grep -nE '\]\(\./|\]\(\.\./' <changed-files>` (RETRO-017 W2)
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
