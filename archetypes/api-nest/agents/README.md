# Agents — Archetype API NestJS

> **Agents | Archetype: api-nest | Versão: 0.2.0**
>
> Agentes de code review do Kiro para projetos de API REST NestJS da MonteBravo.

---

## Propósito

Os agents são revisores especializados usados pelo workflow de code review (`workflows/kiro-code-review.yml`). Cada agente foca em uma dimensão da qualidade e é executado em paralelo no CI.

---

## Agentes Disponíveis

| Agente | Especialidade | Arquivos |
|---|---|---|
| `cli-code-reviewer` | Qualidade de código, TypeScript, Kysely, testes | `cli-code-reviewer.json` / `code-reviewer.md` |
| `cli-architecture-reviewer` | Módulos de domínio, dual database, vision scope | `cli-architecture-reviewer.json` / `architecture-reviewer.md` |
| `cli-security-reviewer` | Cognito, vision scope, injection, secrets, OWASP | `cli-security-reviewer.json` / `security-reviewer.md` |
| `cli-performance-reviewer` | Queries, N+1, async, memory leaks, caching | `cli-performance-reviewer.json` / `performance-reviewer.md` |
| `cli-consistency-reviewer` | Padrões aplicados parcialmente, divergências | `cli-consistency-reviewer.json` |

---

## Configuração

`kiro-review-config.json` define quais agentes rodam no workflow e com qual prompt de contexto. Durante o bootstrap de workflows, esse arquivo é copiado para `.kiro/settings/review-config.json`.

- Arquivos `cli-*.json`: agentes CLI consumidos pelo Kiro CLI no CI.
- Arquivos `*.md`: variantes com frontmatter para uso interativo no Kiro.

---

## Como Aplicar

```bash
./scripts/bootstrap-workflows.sh --project-type api-nest --target ../minha-api
```

---

*Versão: 0.2.0*
