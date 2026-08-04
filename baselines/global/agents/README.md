# Agents — Baseline Global

> **Agents | Baseline: global | Versão: 0.1.0**
>
> Este diretório contém os agents de review transversais a todos os projetos MonteBravo.

---

## Propósito

Agents globais aplicam-se a todos os archetypes e projetos. São revisores que verificam padrões organizacionais comuns — independente da stack ou tecnologia.

---

## Agents Disponíveis

| Agent | Especialidade | Descrição |
|---|---|---|
| `cli-changeset-reviewer` | 📦 Changeset | Revisa changesets em PRs: presença, bump semântico, cobertura de packages, qualidade da descrição (pt-BR, impacto, sem prefixos de commit) e referência a tickets. |

---

## Integração com Archetypes

Os agents globais são adicionados aos `kiro-review-config.json` de cada archetype como uma dimensão adicional de review. Isso garante que todo PR — independente do archetype — passe pela revisão de changeset.

### Archetypes integrados

- `bff-fastify`
- `backend-csharp`
- `frontend-react`

---

## Referências

- [Steering: changeset-guidelines.md](../steering/changeset-guidelines.md) — Diretrizes completas de escrita de changesets.

---

*Versão: 0.1.0 | Última revisão: 2026-08*
