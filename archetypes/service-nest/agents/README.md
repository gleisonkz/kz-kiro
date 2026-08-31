# Agents — Archetype Service NestJS

> **Agents | Archetype: service-nest | Versão: 0.2.0**
>
> Agentes de code review do Kiro para microserviços NestJS (RabbitMQ, Kysely, BullMQ) da MonteBravo.

---

## Propósito

Os agents são revisores especializados usados pelo workflow de code review (`workflows/kiro-code-review.yml`). Cada agente foca em uma dimensão da qualidade e é executado em paralelo no CI.

---

## Agentes Disponíveis

| Agente | Especialidade | Arquivos |
|---|---|---|
| `cli-code-reviewer` | Qualidade, no-floating-promises, Zod, Kysely, testes | `cli-code-reviewer.json` / `code-reviewer.md` |
| `cli-architecture-reviewer` | Mensageria RabbitMQ, módulos, BullMQ, resiliência | `cli-architecture-reviewer.json` / `architecture-reviewer.md` |
| `cli-security-reviewer` | User via RMQ headers, PII em eventos, injection, idempotência | `cli-security-reviewer.json` / `security-reviewer.md` |
| `cli-performance-reviewer` | N+1 Kysely, BullMQ concurrency, Redis lock, pooling | `cli-performance-reviewer.json` / `performance-reviewer.md` |
| `cli-consistency-reviewer` | Padrões aplicados parcialmente, divergências | `cli-consistency-reviewer.json` / `consistency-reviewer.md` |

---

## Configuração

`kiro-review-config.json` define quais agentes rodam no workflow e com qual prompt de contexto. Durante o bootstrap de workflows, esse arquivo é copiado para `.kiro/settings/review-config.json`.

- Arquivos `cli-*.json`: agentes CLI consumidos pelo Kiro CLI no CI.
- Arquivos `*.md`: variantes com frontmatter para uso interativo no Kiro.

---

## Como Aplicar

```bash
./scripts/bootstrap-workflows.sh --project-type service-nest --target ../meu-servico
```

---

*Versão: 0.2.0*
