---
name: "Gerar Módulo"
description: "Cria a estrutura completa de um módulo (bounded context) seguindo a arquitetura modular + FSD da MonteBravo."
inclusion: manual
---

# Gerar Módulo

## Quando usar

Quando o desenvolvedor pedir para criar um novo módulo/domínio na aplicação (ex.: portfolio, trading, onboarding).

## Inputs esperados

- **Nome do módulo** (obrigatório): nome do bounded context em kebab-case (ex.: `portfolio`, `trading`, `onboarding`).
- **Entities** (opcional): entidades de negócio do domínio.
- **Features** (opcional): interações/funcionalidades do módulo.
- **Páginas** (opcional): quais páginas criar.

## Regras de geração

### O que é um módulo (ref: architecture.md — ADR-0011)

Um módulo é um bounded context frontend. Não é apenas um agrupamento de arquivos. Ele representa uma unidade funcional maior da aplicação, com identidade própria dentro do domínio do produto.

### Nomenclatura (ref: naming-conventions.md)

- Diretório do módulo: `kebab-case`, orientado a domínio.
- Nomes curtos e específicos: `portfolio`, `trading`, `onboarding`, `profile`.
- Proibidos: `misc`, `helpers`, `common2`, `temp`, `general`.

### Estrutura FSD dentro do módulo (ref: architecture.md)

```
modules/{module-name}/
├── pages/                    # Páginas e telas do módulo
│   └── {page-name}/
│       ├── index.ts
│       └── ui/
│           └── PageName.tsx
├── widgets/                  # Blocos grandes e autossuficientes de UI (quando necessário)
├── features/                 # Interações reutilizáveis com valor para o usuário
│   └── {feature-name}/
│       ├── index.ts
│       ├── ui/
│       ├── model/
│       │   ├── {feature}.slice.ts
│       │   └── {feature}.selectors.ts
│       ├── api/
│       │   └── {feature}.api.ts
│       └── lib/
├── entities/                 # Entidades de negócio do domínio
│   └── {entity-name}/
│       ├── index.ts
│       ├── model/
│       │   ├── {entity}.types.ts
│       │   └── {entity}.schema.ts
│       └── ui/
├── shared/                   # Capacidades reutilizáveis dentro do módulo
│   ├── ui/
│   ├── lib/
│   └── config/
└── index.ts                  # API pública do módulo
```

### Regras de FSD

- Imports só podem ocorrer de uma layer para outra estritamente abaixo: pages → widgets → features → entities → shared.
- Slices da mesma layer não devem depender umas das outras.
- Consumo entre slices via public API (`index.ts`), não imports diretos.
- Segmentos por propósito técnico: `ui`, `api`, `model`, `lib`, `config`.

### API pública do módulo

O `index.ts` na raiz do módulo é a API pública. Deve exportar apenas o que pode ser consumido externamente:

```ts
// modules/portfolio/index.ts
export { PortfolioOverviewPage } from './pages/portfolio-overview';
export { useGetPortfolioQuery } from './features/portfolio-summary/api/portfolio.api';
export type { PortfolioAsset } from './entities/asset';
```

### O que gerar

1. Estrutura de diretórios FSD.
2. Entities com tipos base do domínio.
3. Features com slice/api — se funcionalidades foram solicitadas.
4. Páginas — se páginas foram solicitadas.
5. API pública (`index.ts`).

### O que NÃO gerar automaticamente

- Widgets — criar sob demanda.
- Componentes de UI específicos — criar sob demanda com a skill "Gerar Componente".
- Shared do módulo — criar sob demanda conforme necessidade.

## Exemplo de output

Para `portfolio` com entity `asset`, feature `portfolio-summary` e página `portfolio-overview`:

```
modules/portfolio/
├── pages/
│   └── portfolio-overview/
│       ├── index.ts
│       └── ui/
│           └── PortfolioOverviewPage.tsx
├── features/
│   └── portfolio-summary/
│       ├── index.ts
│       ├── model/
│       │   ├── portfolio-summary.slice.ts
│       │   └── portfolio-summary.selectors.ts
│       └── api/
│           └── portfolio.api.ts
├── entities/
│   └── asset/
│       ├── index.ts
│       └── model/
│           ├── asset.types.ts
│           └── asset.schema.ts
├── widgets/
├── shared/
└── index.ts
```

### `index.ts` (API pública)

```ts
// Pages
export { PortfolioOverviewPage } from './pages/portfolio-overview';

// Features
export { useGetPortfolioQuery } from './features/portfolio-summary';

// Entities
export type { PortfolioAsset } from './entities/asset';
```
