# Skills — Archetype Frontend React

> **Skills | Archetype: frontend-react | Versão: 0.1.0**
>
> Skills são prompts estruturados que o Kiro ativa sob demanda para gerar código seguindo os padrões MonteBravo.

---

## Skills Disponíveis

| Skill | Arquivo | O que gera |
|---|---|---|
| Gerar Componente React | `generate-component.md` | Componente + tipos + teste + story + index |
| Gerar Custom Hook | `generate-hook.md` | Hook + teste |
| Gerar Redux Slice | `generate-redux-slice.md` | Slice + selectors + tipos + testes + index |
| Gerar API Endpoint | `generate-api-endpoint.md` | Endpoint RTK Query + tipos + teste |
| Gerar Página | `generate-page.md` | Página dentro de um módulo FSD com tratamento de estados |
| Gerar Módulo | `generate-module.md` | Estrutura completa de módulo/bounded context com FSD |
| Gerar Context/Provider | `generate-context-provider.md` | Context + Provider + hook de leitura + teste |

---

## Como usar

Todas as skills têm `inclusion: manual`, ou seja, são ativadas quando o desenvolvedor pede algo que se encaixa no escopo da skill (ex.: "crie um componente Button", "gere um slice de portfolio").

O Kiro identifica a skill relevante, carrega as instruções e gera o código seguindo todos os padrões definidos nos steering files do archetype.

---

## Padrões aplicados

Todas as skills seguem os padrões definidos em:

- `steering/stack-and-tooling.md` — tecnologias e ferramentas
- `steering/architecture.md` — organização modular e fronteiras
- `steering/design-system.md` — acessibilidade, tokens, qualidade
- `steering/naming-conventions.md` — nomenclatura de arquivos, componentes, hooks, etc.

---

*Versão: 0.1.0 | Última revisão: 2026-04*
