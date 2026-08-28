---
inclusion: fileMatch
fileMatchPattern: "**/package.json,**/tsconfig*.json,**/jest.config.*,**/.eslintrc*,**/.prettierrc*,**/angular.json,**/nx.json"
---

# Stack e Tooling — Frontend Angular

> **Steering File | Archetype: frontend-angular | Versão: 0.1.0**

---

## Runtime e Linguagem

| Item | Versão |
|------|--------|
| Node.js | 18.20.x (via Volta; engines: `^18.20 || ^22`) |
| npm | 10.x |
| Angular | 14.3.0 |
| Nx | 17.1.3 |
| TypeScript | 4.8.x |

---

## Dependências Principais

| Dependência | Uso |
|-------------|-----|
| `@angular/*` | Framework (core, common, forms, router, material, cdk) |
| `@ngrx/component-store` | Gerenciamento de estado reativo |
| `@nrwl/angular` / `@nx/*` | Monorepo tooling |
| `ag-grid-angular`, `ag-grid-enterprise` | Tabelas de dados |
| `@ngx-formly/core`, `material` | Formulários dinâmicos |
| `highcharts`, `highcharts-angular` | Gráficos |
| `@angular/fire` + `firebase` | Analytics + Remote Config |
| `@sentry/angular` | Error tracking |
| `smartlook-client` | Session recording |
| `@ngneat/cashew` | HTTP caching |
| `ngx-mask`, `ngx-quill`, `ngx-file-drop` | Inputs e editores |
| `date-fns` | Datas |
| `jwt-decode` | Decodificação JWT Cognito |
| `dexie` | IndexedDB wrapper |

---

## Workspace Nx

- App principal: `crm-app` (`defaultProject`)
- `workspaceLayout`: apps e libs em `projects/`
- Cache Nx **desabilitado** por padrão (`cli.cache.enabled: false`)
- Scripts usam `--skip-nx-cache` para builds frescos
- `npmScope`: `mb-frontend-crm`

---

## Configurações de Build (angular.json)

Ambientes via file replacement:

| Configuração | environment |
|--------------|-------------|
| `production` | `environment.production.ts` |
| `local` | `environment.local.ts` (BFF em localhost:7001) |
| `dev` | `environment.ts` |
| `stg` | `environment.stg.ts` |

- i18n: locale `pt`
- `stylePreprocessorOptions.includePaths: ["src/theme"]`
- Budgets: initial 10mb (warning) / 25mb (error)

---

## Testes

| Item | Config |
|------|--------|
| Runner | Jest (`jest-preset-angular`) |
| Setup | `setup-jest.ts` (zone.js + TestBed) |
| Padrão | `*.spec.ts` co-locado |
| Ambiente | jsdom |
| Mocks | `src/__mocks__/` para libs compartilhadas |

```ts
// setup-jest.ts
import { setupZoneTestEnv } from 'jest-preset-angular/setup-env/zone'
setupZoneTestEnv()
```

Padrão de teste: `TestBed.configureTestingModule`, jest mocks, `of()` para observables. `fast-check` disponível para property-based testing.

---

## Storybook 6.5

- Builder Webpack 5
- Stories em `src/**/*.stories.ts`
- Addons: actions, backgrounds, controls, interactions, links, toolbars, viewport
- Comandos: `npm run storybook`, `npm run build-storybook`

---

## Linting e Formatação

### ESLint

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@angular-eslint/recommended",
    "plugin:@angular-eslint/template/process-inline-templates"
  ],
  "rules": {
    "prettier/prettier": "error",
    "@angular-eslint/component-selector": ["error", { "prefix": "app", "style": "kebab-case", "type": "element" }],
    "@angular-eslint/directive-selector": ["error", { "prefix": "app", "style": "camelCase", "type": "attribute" }],
    "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_|^[A-Z][a-zA-Z]*" }]
  }
}
```

### Prettier

```js
{
  trailingComma: 'es5',
  tabWidth: 4,
  semi: true,          // NOTA: frontend USA semicolons (diferente dos backends)
  singleQuote: true,
  arrowParens: 'always',
  endOfLine: 'lf',
  htmlWhitespaceSensitivity: 'ignore',
}
```

> ⚠️ Diferença importante: o frontend usa `semi: true` e `trailingComma: es5`, enquanto os archetypes de backend (api-nest, service-nest) usam `semi: false` e `trailingComma: all`.

---

## Comandos

| Comando | Descrição |
|---------|-----------|
| `npm run start:dev` | Serve com ambiente dev |
| `npm run start:local` | Serve com BFF local (localhost:7001) |
| `npm run build` | Build produção |
| `npm test` | Testes |
| `npm run lint` | Lint (nx lint) |
| `npm run storybook` | Storybook |

---

*Versão: 0.1.0 | Criado em: 2026-08*
