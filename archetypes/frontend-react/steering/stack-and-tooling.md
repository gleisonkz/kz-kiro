---
inclusion: auto
---

# Stack Base e Ferramental — Frontend React

> **Steering File | Archetype: frontend-react | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos frontend React da MonteBravo.
> Ele define a stack base de tecnologias, ferramental e organização de repositório.
>
> Baseado em: ADR-0001 (Stack Base), RFC-0001, RFC-0002 (Repositórios)

---

## Stack Base Obrigatória

Todos os projetos frontend da MonteBravo devem utilizar:

| Tecnologia | Versão/Modo | Finalidade |
|---|---|---|
| React | 19 | Biblioteca principal de UI |
| TypeScript | strict mode | Tipagem em todo o monorepo |
| Vite | latest stable | SPAs e aplicações internas (produtividade e velocidade) |
| Vitest | latest stable | Testes automatizados |
| Turborepo | latest stable | Orquestração de builds, testes, pipelines e scripts |
| ESLint + Prettier | latest stable | Linting e padronização de código |
| TailwindCSS | 4 | Estilização e CSS |
| Redux Toolkit | latest stable | Gerenciamento de estado global |
| Redux Toolkit Query | latest stable | Server state (dados assíncronos, cache, revalidação) |
| TanStack Router | latest stable | Roteamento principal das aplicações SPA |
| pnpm | latest stable | Gerenciador de pacotes e workspaces |

### Padrões de módulo

- ESM-first em todo o código.
- Não usar CommonJS em código novo.

---

## Organização do Monorepo

O frontend é organizado em monorepo com a seguinte estrutura:

```
frontend/
├── apps/
│   ├── web-cliente/          # App SPA autenticado para clientes
│   └── web-assessor/         # App SPA autenticado para assessores
│
├── packages/
│   ├── eslint-config/        # Configuração centralizada de ESLint
│   ├── common/               # Utils, hooks e abstrações compartilhadas
│   └── .../                  # Demais pacotes compartilhados
│
├── package.json
├── pnpm-workspace.yaml
└── turbo.json
```

### Regras do monorepo

- Aplicações ficam em `apps/*`, nomeadas em kebab-case orientado ao produto (ex.: `web-cliente`, `web-assessor`).
- Pacotes compartilhados ficam em `packages/*`, nomeados em kebab-case orientado à responsabilidade (ex.: `common`, `eslint-config`, `api-client`).
- Ferramental de qualidade (ESLint, Prettier, TypeScript config) é centralizado no workspace — uma única fonte de verdade.
- Todos os pacotes internos em `packages/*` são versionados e publicados no Package Registry (GitHub Packages ou NPM), podendo ser consumidos dentro e fora do monorepo.
- pnpm workspaces para gerenciamento de dependências.
- Turborepo para orquestração de builds, testes e scripts.

### Design System

- O Design System é construído como projeto independente em repositório próprio.
- É empacotado e publicado em npm registry interno (GitHub Packages).
- É instalado no monorepo como dependência compartilhada.
- Versionamento via Changesets + SemVer.

---

## Ferramentas Obrigatórias

### Testes

- Vitest como runner principal (unitários e de componente).
- Padrão AAA (Arrange, Act, Assert).
- Cobertura mínima de 80% para código crítico.
- Sufixo `.test.ts` ou `.test.tsx` para testes unitários.
- Sufixo `.e2e.ts` para testes end-to-end (ferramenta E2E a definir em RFC específica).

### Linting e formatação

- ESLint com configuração centralizada em `packages/eslint-config`.
- Prettier para formatação automática.
- Configuração compartilhada entre todas as apps e packages.

### Build e orquestração

- Turborepo para orquestração inteligente (executa apenas o que mudou).
- Cache inteligente de builds habilitado.
- Cada app e package possui seu próprio processo de build.

---

## Tecnologias Descartadas (e por quê)

O Kiro deve alertar se encontrar uso dessas tecnologias em código novo:

| Tecnologia | Motivo da rejeição |
|---|---|
| Zustand | Pouco opinado, risco de divergência de padrões entre squads |
| React Context API (para estado global complexo) | Problemas de performance com re-renders, sem middleware nativo |
| TanStack Query | Sobreposição com RTK Query que já está na stack |
| Axios/Fetch direto como padrão de server state | Sem cache, revalidação ou padronização estruturada |
| CSS Modules / Styled Components / Emotion | Overhead de manutenção em escala, dificulta tokenização |
| Jest | Vitest é superior em performance, ESM e integração com Vite |
| CommonJS | ESM-first é o padrão |

> React Context API continua válido para providers específicos (tema, configurações), mas não como solução principal de estado global.

---

## Plano de Opt-out do Monorepo

Se uma aplicação crescer exponencialmente e exigir isolamento:

1. Gatilhos objetivos: conflitos recorrentes entre squads, gargalos de pipeline/deploy, necessidade de releases totalmente independentes.
2. Pacotes compartilhados já são desacoplados por contrato e distribuídos via Package Registry.
3. Criar novo repositório para a app alvo, preservando CI/CD e qualidade.
4. Migrar por fases com janela de transição e rollback definido.

---

## Referências

- [ADR-0001 - Stack Base de Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757089)
- [RFC-0001 - Stack Base de Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757283)
- [RFC-0002 - Repositórios para produtos Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757323)

---

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
