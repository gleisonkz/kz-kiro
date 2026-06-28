# Steering — Power mb-frontend-react

> **Power: mb-frontend-react | Versão: 1.0.0**

Steering files que orientam o Kiro na integração Figma → código para projetos frontend React da MonteBravo.

---

## Arquivos Disponíveis

| Arquivo | Propósito | Inclusão |
|---------|-----------|----------|
| `implement-design.md` | Workflow completo para traduzir design Figma em código seguindo as convenções MonteBravo | Carregado via POWER.md |
| `code-connect-components.md` | Workflow para conectar componentes Figma ao código via Code Connect | Carregado via POWER.md |
| `create-design-system-rules.md` | Gerar regras de design system específicas por aplicação | Carregado via POWER.md |
| `design-system-usage.md` | Guia prático de consumo do Design System (tokens, CVA, composição) | `fileMatch: **/*.tsx, **/*.variants.ts` |
| `debugging-guide.md` | Estratégias de debug com Chrome DevTools MCP, React DevTools e Redux DevTools | `manual` (sob demanda) |

## Relação com Archetype `frontend-react`

Este power **complementa** os steerings do archetype, que definem:

- `architecture.md` — Arquitetura FSD, módulos, fronteiras
- `design-system.md` — Arquitetura do DS, Base UI, requisitos de qualidade
- `stack-and-tooling.md` — Stack base, monorepo, ferramentas
- `naming-conventions.md` — Convenções de nomenclatura
- `ci-cd.md` — Pipelines e deploy

Os steerings deste power focam especificamente no **workflow de integração Figma → código** e no **uso prático do Design System** durante a implementação.

---

*Versão: 1.0.0 | Última revisão: 2026-06*
