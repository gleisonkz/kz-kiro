# Skill: Gerar Component Store (NgRx)

## Objetivo

Criar um NgRx ComponentStore seguindo o padrão do projeto (state, selectors, updaters, effects).

## Parâmetros

- **feature** (obrigatório): Feature que receberá a store
- **entidade** (obrigatório): Entidade principal gerenciada

## Regras

1. Estender `ComponentStore<{Feature}State>`
2. State inclui `requestState: LoadingState | ErrorState`
3. Enum `LoadingState`: INIT, LOADING, LOADED, UPDATED
4. Selectors via `this.select()`, sufixo `$`
5. Updaters via `this.updater()` — sempre imutáveis (spread)
6. Effects via `this.effect()` com `tapResponse()` e `switchMap`/`exhaustMap`
7. Service injetado no constructor
8. `@Injectable()` (providedIn root ou module-scoped)

## Template

```ts
import { Injectable } from '@angular/core';
import { ComponentStore, tapResponse } from '@ngrx/component-store';
import { Observable, switchMap, tap } from 'rxjs';
import { {Feature}Service } from './{feature}.service';
import { {Entity} } from './{feature}.types';

export const enum LoadingState {
    INIT = 'INIT', LOADING = 'LOADING', LOADED = 'LOADED', UPDATED = 'UPDATED',
}
export interface ErrorState { errorMessage: string }
export type RequestState = LoadingState | ErrorState;

export interface {Feature}State {
    data: {Entity}[];
    requestState: RequestState;
}

const INITIAL_STATE: {Feature}State = { data: [], requestState: LoadingState.INIT };

function getError(rs: RequestState): string | null {
    return (rs as ErrorState).errorMessage !== undefined ? (rs as ErrorState).errorMessage : null;
}

@Injectable()
export class {Feature}Store extends ComponentStore<{Feature}State> {
    constructor(private service: {Feature}Service) { super(INITIAL_STATE); }

    readonly data$ = this.select((state) => state.data);
    readonly loading$ = this.select((s) => s.requestState === LoadingState.LOADING);
    readonly error$ = this.select((s) => getError(s.requestState));

    readonly setLoading = this.updater((state, l: LoadingState) => ({ ...state, requestState: l }));
    readonly setError = this.updater((state, errorMessage: string) => ({ ...state, requestState: { errorMessage } }));
    readonly setData = this.updater((state, data: {Entity}[]) => ({
        ...state, data, requestState: LoadingState.LOADED,
    }));

    readonly load = this.effect<void>((trigger$) =>
        trigger$.pipe(
            tap(() => this.setLoading(LoadingState.LOADING)),
            switchMap(() =>
                this.service.getData().pipe(
                    tapResponse(this.setData, ({ message }: { message: string }) => this.setError(message)),
                ),
            ),
        ),
    );
}
```
