---
inclusion: fileMatch
fileMatchPattern: "**/src/**/*.ts,**/projects/**/*.ts"
---

# Convenções de Nomenclatura — Frontend Angular

> **Steering File | Archetype: frontend-angular | Versão: 0.1.0**

---

## Arquivos

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Módulo de feature | `{feature}.module.ts` | `pipeline.module.ts` |
| Routing module | `{feature}-routing.module.ts` | `pipeline-routing.module.ts` |
| Store module | `{feature}-store.module.ts` | `pipeline-store.module.ts` |
| Component Store | `{feature}.store.ts` | `pipeline.store.ts` |
| Service | `{feature}.service.ts` | `pipeline.service.ts` |
| Types | `{feature}.types.ts` ou `{feature}.type.ts` | `pipeline.types.ts` |
| Componente | `{nome}.component.ts/html/scss` | `pipeline-table.component.ts` |
| Guard | `{nome}.guard.ts` | `auth.guard.ts` |
| Interceptor | `{nome}-interceptor.ts` | `auth-interceptor.ts` |
| Pipe | `{nome}.pipe.ts` | `cpf-cnpj.pipe.ts` |
| Barrel export | `index.ts` | `index.ts` |
| Teste | `{nome}.component.spec.ts` | `fee-based-badge.component.spec.ts` |

---

## Classes

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Module | `{Feature}Module` | `PipelineModule` |
| Component | `{Nome}Component` | `PipelineTableComponent` |
| Store | `{Feature}Store` | `PipelineStore` |
| Service | `{Feature}Service` | `PipelineService` |
| Guard | `{Nome}Guard` | `AuthGuard`, `RoleGuard` |
| Interceptor | `{Nome}Interceptor` | `AuthInterceptor` |
| Pipe | `{Nome}Pipe` | `CpfCnpjPipe` |

---

## Seletores (ESLint enforça)

- Componente: prefixo `app`, **kebab-case**, tipo `element`
  - Ex: `app-pipeline-table`, `app-fee-based-badge`
- Diretiva: prefixo `app`, **camelCase**, tipo `attribute`

---

## Estado (ComponentStore)

| Elemento | Padrão | Exemplo |
|----------|--------|---------|
| State interface | `{Feature}State` | `PipelineState` |
| Selector | `{nome}$` (Observable) | `tableData$`, `loading$` |
| Updater | `set{Nome}` / `update{Nome}` | `setTableData`, `updateMarkAsRead` |
| Effect | verbo descritivo | `loadData`, `updatePipeline` |
| Loading enum | `LoadingState` | `INIT`, `LOADING`, `LOADED`, `UPDATED` |

---

## Variáveis e Constantes

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Variável / propriedade | camelCase | `feeBasedService`, `accountCode` |
| Constante de módulo | UPPER_SNAKE_CASE | `INITIAL_SSRM_PARAMS`, `NOTIFICATIONS_PAGE_SIZE` |
| Enum (nome e valores) | PascalCase | `FeeBasedStatusEnum.Active` |
| Observable | sufixo `$` | `destroy$`, `data$` |

---

## Path Aliases

| Alias | Aponta para |
|-------|-------------|
| `@env/environment` | `src/environments/environment` |
| `@mb-frontend-crm/*` | libs em `projects/` |
| `@services/*` | `src/app/services/*` |
| `@features/*` | `src/app/features/*` |
| `mb` | `projects/mb/src/public-api` |

---

## Pastas

- Sempre **kebab-case**: `fee-based-badge/`, `pipeline-store/`, `http-interceptors/`
- Dentro de feature: `components/`, `pages/`, `store/`

---

*Versão: 0.1.0 | Criado em: 2026-08*
