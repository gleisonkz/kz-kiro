# Archetype: Frontend Angular

> **Archetype | frontend-angular | Versão: 0.1.0**
>
> Configurações Kiro para aplicações frontend Angular em workspace Nx, com NgRx ComponentStore, AG Grid e Design System MonteBravo.

---

## Propósito

O Frontend é a **SPA do CRM** construída em Angular sobre um workspace Nx (monorepo). Segue arquitetura baseada em componentes com separação clara entre componentes apresentacionais ("burros") e smart containers, gerenciamento de estado reativo via NgRx ComponentStore, e fluxo de dados unidirecional.

---

## Estrutura

```
archetypes/frontend-angular/
├── README.md
├── VERSION
├── CHANGELOG.md
├── agents/
│   └── README.md
├── hooks/
│   ├── README.md
│   ├── kiro-doctor.kiro.hook
│   ├── lint-after-agent.kiro.hook
│   └── run-tests-after-task.kiro.hook
├── mcp/
│   └── mcp.json
├── skills/
│   ├── README.md
│   ├── generate-feature.md
│   ├── generate-component-store.md
│   └── generate-shared-component.md
└── steering/
    ├── README.md
    ├── architecture.md
    ├── stack-and-tooling.md
    ├── naming-conventions.md
    └── ci-cd.md
```

---

## Stack

- **Runtime:** Node.js 18 LTS (compatível com 22)
- **Framework:** Angular 14.x
- **Monorepo:** Nx 17.x
- **Linguagem:** TypeScript 4.8.x
- **Estado:** NgRx ComponentStore
- **UI:** Angular Material + Bootstrap 4 + Design System MonteBravo
- **Tabelas:** AG Grid Enterprise
- **Formulários:** ngx-formly
- **Gráficos:** Highcharts
- **Auth:** AWS Cognito (OAuth2 authorization code flow)
- **Observabilidade:** Sentry + Firebase Analytics + Smartlook
- **Testes:** Jest (jest-preset-angular)
- **Storybook:** 6.5
- **Linting:** ESLint + Prettier
- **Pacotes:** npm

---

## Princípios Arquiteturais

1. **Módulos coesos e auto-contidos** — organizados por domínio (feature), facilitando localização e onboarding.
2. **Tipos de módulo bem definidos** — Core, Layout, Views, Shared, Feature.
3. **Componentes apresentacionais vs smart containers** — componentes "burros" apenas apresentam UI; smart containers interfaceiam com store e lógica.
4. **Fluxo de dados unidirecional** — única fonte de verdade, estado gerenciado por stores.
5. **NgRx ComponentStore** — estado reativo, imutável, isolado por feature.
6. **Camada de abstração de dados** — apenas stores conhecem sistemas externos (HTTP).
7. **Lazy loading** — features carregadas sob demanda via `loadChildren`.
8. **Design System** — componentes reutilizáveis nas libs `projects/`.

---

## Tipos de Módulo

| Tipo | Responsabilidade |
|------|------------------|
| **Core** | Injectables singletons essenciais: guards, interceptors, autenticação |
| **Layout** | Componentes de composição do layout: header, sidebar, nav |
| **Views** | Componentes simples não ligados a feature (ex: 404) |
| **Shared** | Constructos usados por features para compor UI (sem regra de negócio) |
| **Feature** | Conjunto de módulos de um mesmo domínio (com store, pages, components) |

---

## Como usar

```bash
./scripts/bootstrap.sh --project-type frontend-angular --target <caminho-do-projeto>
```

---

*Versão: 0.1.0 | Criado em: 2026-08*
