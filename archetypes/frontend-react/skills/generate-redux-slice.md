---
name: "Gerar Redux Slice"
description: "Cria um slice Redux Toolkit com selectors, tipagem e testes seguindo os padrões MonteBravo."
inclusion: manual
---

# Gerar Redux Slice

## Quando usar

Quando o desenvolvedor pedir para criar um novo slice de estado global com Redux Toolkit.

## Inputs esperados

- **Nome do domínio** (obrigatório): nome do domínio em camelCase (ex.: `portfolio`, `orders`, `auth`).
- **Estado inicial** (opcional): campos do estado.
- **Localização** (opcional): caminho onde criar.

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Slice: `{dominio}.slice.ts` (ex.: `portfolio.slice.ts`).
- Selectors: `{dominio}.selectors.ts` (ex.: `portfolio.selectors.ts`).
- Tipos: `{dominio}.types.ts` (ex.: `portfolio.types.ts`).
- Teste do slice: `{dominio}.slice.test.ts`.
- Teste dos selectors: `{dominio}.selectors.test.ts`.
- Nome do slice em camelCase orientado a domínio.
- Selectors com prefixo `select`: `selectPortfolio`, `selectActiveOrder`, `selectIsSubmitting`.

### Estrutura de arquivos

Dentro de uma feature FSD do módulo:

```
modules/{module}/features/{feature}/
├── model/
│   ├── {feature}.slice.ts
│   ├── {feature}.slice.test.ts
│   ├── {feature}.selectors.ts
│   └── {feature}.selectors.test.ts
├── index.ts
└── ...
```

Tipos do domínio ficam na entity correspondente:

```
modules/{module}/entities/{entity}/
├── model/
│   ├── {entity}.types.ts
│   └── {entity}.schema.ts
└── index.ts
```

> O slice importa tipos da entity. A entity é a fonte de verdade de tipos do domínio.

### Implementação (ref: stack-and-tooling.md, architecture.md)

- Redux Toolkit com TypeScript strict.
- Estado tipado com interface dedicada.
- Reducers com PayloadAction tipado.
- Selectors tipados com RootState.
- Exportar actions, reducer e selectors como named exports.

### Teste (ref: stack-and-tooling.md)

- Vitest.
- Testar estado inicial.
- Testar cada reducer/action.
- Testar selectors com estado mockado.

## Exemplo de output

### `portfolio.types.ts`

```ts
export interface PortfolioAsset {
  id: string;
  ticker: string;
  name: string;
  quantity: number;
  currentValue: number;
  performance: number;
}

export interface PortfolioState {
  assets: PortfolioAsset[];
  isLoading: boolean;
  error: string | null;
  selectedAssetId: string | null;
}
```

### `portfolio.slice.ts`

```ts
import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { PortfolioAsset, PortfolioState } from '../../entities/asset';

const initialState: PortfolioState = {
  assets: [],
  isLoading: false,
  error: null,
  selectedAssetId: null,
};

export const portfolioSlice = createSlice({
  name: 'portfolio',
  initialState,
  reducers: {
    setAssets(state, action: PayloadAction<PortfolioAsset[]>) {
      state.assets = action.payload;
    },
    setLoading(state, action: PayloadAction<boolean>) {
      state.isLoading = action.payload;
    },
    setError(state, action: PayloadAction<string | null>) {
      state.error = action.payload;
    },
    selectAsset(state, action: PayloadAction<string | null>) {
      state.selectedAssetId = action.payload;
    },
  },
});

export const { setAssets, setLoading, setError, selectAsset } = portfolioSlice.actions;
export const portfolioReducer = portfolioSlice.reducer;
```

### `portfolio.selectors.ts`

```ts
import type { RootState } from '@/app/store';

export const selectPortfolioAssets = (state: RootState) => state.portfolio.assets;
export const selectPortfolioIsLoading = (state: RootState) => state.portfolio.isLoading;
export const selectPortfolioError = (state: RootState) => state.portfolio.error;
export const selectSelectedAssetId = (state: RootState) => state.portfolio.selectedAssetId;

export const selectSelectedAsset = (state: RootState) => {
  const { assets, selectedAssetId } = state.portfolio;
  return assets.find((asset) => asset.id === selectedAssetId) ?? null;
};

export const selectPortfolioTotalValue = (state: RootState) =>
  state.portfolio.assets.reduce((total, asset) => total + asset.currentValue, 0);
```

### `portfolio.slice.test.ts`

```ts
import { describe, expect, it } from 'vitest';
import {
  portfolioReducer,
  selectAsset,
  setAssets,
  setError,
  setLoading,
} from './portfolio.slice';
import type { PortfolioState } from '../../entities/asset';

const initialState: PortfolioState = {
  assets: [],
  isLoading: false,
  error: null,
  selectedAssetId: null,
};

describe('portfolioSlice', () => {
  it('deve retornar o estado inicial', () => {
    expect(portfolioReducer(undefined, { type: 'unknown' })).toEqual(initialState);
  });

  it('deve setar assets', () => {
    const assets = [{ id: '1', ticker: 'PETR4', name: 'Petrobras', quantity: 100, currentValue: 3500, performance: 5.2 }];
    const state = portfolioReducer(initialState, setAssets(assets));
    expect(state.assets).toEqual(assets);
  });

  it('deve setar loading', () => {
    const state = portfolioReducer(initialState, setLoading(true));
    expect(state.isLoading).toBe(true);
  });

  it('deve setar erro', () => {
    const state = portfolioReducer(initialState, setError('Falha ao carregar'));
    expect(state.error).toBe('Falha ao carregar');
  });

  it('deve selecionar um asset', () => {
    const state = portfolioReducer(initialState, selectAsset('1'));
    expect(state.selectedAssetId).toBe('1');
  });
});
```

### `index.ts`

```ts
export { portfolioReducer, selectAsset, setAssets, setError, setLoading } from './portfolio.slice';
export {
  selectPortfolioAssets,
  selectPortfolioError,
  selectPortfolioIsLoading,
  selectPortfolioTotalValue,
  selectSelectedAsset,
  selectSelectedAssetId,
} from './portfolio.selectors';
export type { PortfolioAsset, PortfolioState } from '../../entities/asset';
```
