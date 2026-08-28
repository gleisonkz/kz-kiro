---
inclusion: fileMatch
fileMatchPattern: "**/src/app/**,**/projects/**"
---

# Arquitetura do Frontend Angular

> **Steering File | Archetype: frontend-angular | Versão: 0.1.0**
>
> Define a arquitetura de componentes, gerenciamento de estado e organização
> de módulos para a SPA do CRM MonteBravo (Angular + Nx).

---

## Workspace Nx

Monorepo Nx com o app principal (`crm-app`) e bibliotecas compartilhadas em `projects/`:

```
projects/
├── components/        # Libs de componentes (atoms, cards, forms, modals, speech-to-text)
├── extensions/        # Extensões de framework (formly)
├── mb/                # Design System interno
└── playground/        # Ambiente de desenvolvimento
```

- Path aliases via `tsconfig.base.json`: `@env/`, `@mb-frontend-crm/*`, `@services/*`, `@features/*`, `mb`
- App code em `src/app/`; libs em `projects/`

---

## Organização da Aplicação (src/app/)

Estrutura alvo (arquitetura coesa por domínio):

```
src/app/
├── core/              # Singletons: analytics, auth, guards, http-interceptors, sentry
├── features/          # Módulos de domínio (com components/, pages/, store/)
├── layout/            # header, nav, footer
├── shared/            # Componentes reutilizáveis, pipes, services (sem regra de negócio)
│   └── externals/     # Wrappers de libs externas (ag-grid, formly)
├── views/             # Componentes simples de rota (forbidden, not-found)
├── app-routing.module.ts
└── app.module.ts
```

---

## Tipos de Módulo

| Tipo | Regras |
|------|--------|
| **Core** | Apenas injectables singletons essenciais. Guards, interceptors, auth. |
| **Layout** | Componentes de composição do layout (header, sidebar). |
| **Views** | Componentes simples de rota raiz (ex: 404). |
| **Shared** | Constructos para compor UI. Sem lógica de negócio. Não depende de nada fora dele. |
| **Feature** | Conjunto de módulos de um domínio. |

### Estrutura de uma Feature

```
features/{feature}/
├── components/        # Componentes apresentacionais da feature
├── pages/             # Smart containers / views (destino de rota)
├── store/             # ComponentStore, service, types
├── {feature}-routing.module.ts   # Rotas (só router + guards, sem declarations)
├── {feature}.module.ts           # Declarations + providers
└── index.ts                      # Barrel export (API pública)
```

### Convenção de módulos por feature

- `*.module.ts` — declarations e providers da feature
- `*-routing.module.ts` — declara rotas, exporta router, provê guards (sem declarations)
- `*-store.module.ts` — define providers da store NgRx (opcional)
- `*-widget.module.ts` — funciona como "shared" da feature (não expõe páginas)

---

## Componentes: Burros vs Smart Containers

### Componentes apresentacionais ("burros")

- Única responsabilidade: **apresentar UI**
- Desacoplados de lógica de negócio, requisições e estado
- Recebem dados via `@Input`, emitem eventos via `@Output`
- Extremamente reutilizáveis

### Smart Containers

- Interfaceiam componentes apresentacionais com store e lógica
- Apenas eles acessam e atualizam dados da aplicação
- **Views** (`*.view.ts`) são smart containers destino de rota, com acesso a query/hash params

### Fluxo de dados unidirecional

- Única fonte de verdade
- Componente apresentacional **não** atualiza dados — emite via `@Output`, o smart container atualiza
- Apenas stores conhecem sistemas externos (HTTP), via camada de abstração

---

## Gerenciamento de Estado (NgRx ComponentStore)

Padrão consistente para stores:

```ts
export const enum LoadingState {
    INIT = 'INIT', LOADING = 'LOADING', LOADED = 'LOADED', UPDATED = 'UPDATED',
}
export interface ErrorState { errorMessage: string }
export type RequestState = LoadingState | ErrorState

export interface {Feature}State {
    data: {Entity}[]
    requestState: RequestState
}

@Injectable()
export class {Feature}Store extends ComponentStore<{Feature}State> {
    constructor(private service: {Feature}Service) {
        super(INITIAL_STATE)
    }

    // Selectors
    readonly data$ = this.select((state) => state.data)
    readonly loading$ = this.select((s) => s.requestState === LoadingState.LOADING)

    // Updaters (imutáveis)
    readonly setData = this.updater((state, data: {Entity}[]) => ({
        ...state, data, requestState: LoadingState.LOADED,
    }))

    // Effects
    readonly load = this.effect<Params>((params$) =>
        params$.pipe(
            tap(() => this.setLoading(LoadingState.LOADING)),
            switchMap((params) => this.service.get(params).pipe(
                tapResponse(this.setData, (e) => this.setError(e.message)),
            )),
        )
    )
}
```

**Regras:**
- Selectors via `this.select()`
- Updaters via `this.updater()` (sempre imutáveis, spread)
- Effects via `this.effect()` com `tapResponse()`, `switchMap`/`exhaustMap`
- Service injetado no constructor
- Store é `@Injectable()` (root ou module-scoped)

---

## Roteamento

- Lazy loading via `loadChildren`
- Cada feature tem seu `*-routing.module.ts`
- Guards: `AuthGuard` (login), `RoleGuard` (roles), `FeatureToggleGuard` (feature flags via Remote Config)

---

## Autenticação

- **AWS Cognito** via OAuth2 authorization code flow
- Token JWT em `localStorage('mb-api-crm-auth-token')`
- `InitService` gerencia login (code exchange, validação de token)
- `AuthInterceptor` adiciona Bearer token em requests para URLs confiáveis
- `AuthGuard` verifica `isLoggedIn()`, `RoleGuard` verifica roles

---

## Prevenção de Memory Leaks

Padrão preferido (novo código):

```ts
export class MyComponent implements OnDestroy {
    private destroy$ = new Subject<void>()

    ngOnInit() {
        this.service.getData().pipe(takeUntil(this.destroy$)).subscribe(...)
    }

    ngOnDestroy() {
        this.destroy$.next()
        this.destroy$.complete()
    }
}
```

Legado (`Subscription[]` com unsubscribe manual) — manter se já presente, mas preferir `destroy$`.

---

## Design System e Estilos

- Angular Material com tema customizado MonteBravo (`src/theme/palette.scss`)
- Bootstrap 4 para layout
- SCSS com variáveis em `src/theme/` (palette, colors, typography)
- `styles-design-system.scss` (theming Material completo), `styles-aggrid.scss`
- Componentes de design system nas libs `projects/mb/`, `projects/components/*`

---

*Versão: 0.1.0 | Criado em: 2026-08*
