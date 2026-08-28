# Skill: Gerar Feature Module

## Objetivo

Criar um feature module completo e auto-contido para o CRM Angular, seguindo os padrões arquiteturais do projeto.

## Parâmetros

- **nome da feature** (obrigatório): Nome da feature em kebab-case (ex: `tasks`, `pipeline`)
- **entidade principal** (obrigatório): Nome da entidade de domínio (ex: `Task`, `Client`)
- **com AG Grid** (opcional): Se a feature usa tabela AG Grid (default: false)

## Estrutura Gerada

```
src/app/features/{nome}/
├── {nome}.module.ts
├── {nome}-routing.module.ts
├── {nome}.store.ts
├── {nome}.service.ts
├── {nome}.type.ts
└── components/
    ├── {nome}-list/
    │   ├── {nome}-list.component.ts
    │   ├── {nome}-list.component.html
    │   ├── {nome}-list.component.scss
    │   └── {nome}-list.component.spec.ts
    └── {nome}-detail/
        ├── {nome}-detail.component.ts
        ├── {nome}-detail.component.html
        └── {nome}-detail.component.scss
```

## Regras

1. O module é um NgModule (não standalone)
2. O routing module define rotas internas da feature
3. O store usa NgRx ComponentStore com `LoadingState` enum
4. O service faz chamadas HTTP ao BFF/API
5. Types define interfaces, enums e modelos da feature
6. Componente list é smart (injeta store), detail pode ser smart ou dumb
7. Lazy loading: registrar rota no `app-routing.module.ts`
8. Importar `SharedModule` para componentes reutilizáveis

## Template do Module

```ts
import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { SharedModule } from '../../shared/shared.module';
import { {Nome}RoutingModule } from './{nome}-routing.module';
import { {Nome}ListComponent } from './components/{nome}-list/{nome}-list.component';
import { {Nome}DetailComponent } from './components/{nome}-detail/{nome}-detail.component';

@NgModule({
    declarations: [
        {Nome}ListComponent,
        {Nome}DetailComponent,
    ],
    imports: [
        CommonModule,
        SharedModule,
        {Nome}RoutingModule,
    ],
})
export class {Nome}Module {}
```

## Template do Routing Module

```ts
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { {Nome}ListComponent } from './components/{nome}-list/{nome}-list.component';
import { {Nome}DetailComponent } from './components/{nome}-detail/{nome}-detail.component';

const routes: Routes = [
    { path: '', component: {Nome}ListComponent },
    { path: ':id', component: {Nome}DetailComponent },
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule],
})
export class {Nome}RoutingModule {}
```

## Template do Store

```ts
import { Injectable } from '@angular/core';
import { ComponentStore, tapResponse } from '@ngrx/component-store';
import { switchMap, tap } from 'rxjs/operators';
import { LoadingState } from '../../shared/types/loading-state.enum';
import { {Nome}Service } from './{nome}.service';
import { {Entidade}, {Nome}Filters } from './{nome}.type';

interface {Nome}State {
    items: {Entidade}[];
    loadingState: LoadingState;
    error: string | null;
    filters: {Nome}Filters;
}

@Injectable()
export class {Nome}Store extends ComponentStore<{Nome}State> {
    constructor(private {nome}Service: {Nome}Service) {
        super({
            items: [],
            loadingState: LoadingState.INIT,
            error: null,
            filters: {},
        });
    }

    // Selectors
    readonly items$ = this.select(state => state.items);
    readonly loading$ = this.select(state => state.loadingState === LoadingState.LOADING);
    readonly error$ = this.select(state => state.error);

    // Updaters
    readonly setItems = this.updater((state, items: {Entidade}[]) => ({
        ...state,
        items,
        loadingState: LoadingState.LOADED,
    }));

    readonly setFilters = this.updater((state, filters: {Nome}Filters) => ({
        ...state,
        filters,
    }));

    // Effects
    readonly loadItems = this.effect<{Nome}Filters>(filters$ =>
        filters$.pipe(
            tap(() => this.patchState({ loadingState: LoadingState.LOADING })),
            switchMap(filters =>
                this.{nome}Service.getAll(filters).pipe(
                    tapResponse(
                        items => this.setItems(items),
                        (error: any) => this.patchState({
                            loadingState: LoadingState.ERROR,
                            error: error?.message ?? 'Erro ao carregar dados',
                        }),
                    ),
                ),
            ),
        ),
    );
}
```

## Template do Service

```ts
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { {Entidade}, {Nome}Filters } from './{nome}.type';

@Injectable({ providedIn: 'root' })
export class {Nome}Service {
    private readonly baseUrl = `${environment.apiUrl}/{nome}`;

    constructor(private http: HttpClient) {}

    getAll(filters?: {Nome}Filters): Observable<{Entidade}[]> {
        return this.http.get<{Entidade}[]>(this.baseUrl, { params: filters as any });
    }

    getById(id: string): Observable<{Entidade}> {
        return this.http.get<{Entidade}>(`${this.baseUrl}/${id}`);
    }

    create(data: Partial<{Entidade}>): Observable<{Entidade}> {
        return this.http.post<{Entidade}>(this.baseUrl, data);
    }

    update(id: string, data: Partial<{Entidade}>): Observable<{Entidade}> {
        return this.http.patch<{Entidade}>(`${this.baseUrl}/${id}`, data);
    }
}
```

## Template do Type

```ts
export interface {Entidade} {
    id: string;
    // TODO: definir campos da entidade
    createdAt: string;
    updatedAt: string;
}

export interface {Nome}Filters {
    search?: string;
    page?: number;
    pageSize?: number;
}
```

## Após gerar

1. Registrar lazy route no `app-routing.module.ts`
2. Verificar imports no `SharedModule` (se precisa de Material modules)
3. Rodar `npx nx lint crm-app` para validar
