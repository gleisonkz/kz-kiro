# Agents — Archetype Frontend React

> **Agents | Archetype: frontend-react | Versão: 0.1.0**
>
> Agentes especializados do Kiro para revisão e análise de código em projetos React MonteBravo.

---

## Agents Disponíveis

| Agent | Arquivo | Especialidade |
|---|---|---|
| Revisor de Acessibilidade | `accessibility-reviewer.md` | WCAG 2.1 AA, ARIA, navegação por teclado, contraste |
| Revisor de Arquitetura | `architecture-reviewer.md` | Fronteiras entre features, organização modular, acoplamento |
| Revisor de Performance | `performance-reviewer.md` | Re-renders, bundle size, lazy loading, cache RTK Query |
| Revisor de Código | `code-reviewer.md` | Code review generalista: tipagem, padrões, testes, segurança |

---

## Como usar

Estes agents podem ser invocados quando o desenvolvedor pedir revisões especializadas:

- "Revise a acessibilidade deste componente" → `accessibility-reviewer`
- "Revise a arquitetura desta feature" → `architecture-reviewer`
- "Tem algum problema de performance aqui?" → `performance-reviewer`
- "Faça um code review deste PR" → `code-reviewer`

Cada agent tem contexto especializado sobre os padrões MonteBravo e produz feedback estruturado com localização, problema, sugestão e severidade.

---

## Relação com hooks

Alguns hooks do archetype ativam revisões similares automaticamente:

- `review-component-quality.json` → versão automática e leve do revisor de acessibilidade
- `review-feature-boundaries.json` → versão automática e leve do revisor de arquitetura

Os agents são mais profundos e completos — use-os para revisões detalhadas sob demanda.

---

*Versão: 0.1.0 | Última revisão: 2026-04*
