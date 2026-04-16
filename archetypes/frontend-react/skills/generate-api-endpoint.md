---
name: "Gerar API Endpoint (RTK Query)"
description: "Cria um endpoint RTK Query com tipagem, cache e convenções de nomenclatura MonteBravo."
inclusion: manual
---

# Gerar API Endpoint (RTK Query)

## Quando usar

Quando o desenvolvedor pedir para criar um novo endpoint de API usando Redux Toolkit Query.

## Inputs esperados

- **Recurso** (obrigatório): nome do recurso/domínio (ex.: `portfolio`, `orders`).
- **Operações** (opcional): quais operações criar (ex.: `get`, `list`, `create`, `update`, `remove`).
- **Base URL** (opcional): URL base da API.
- **Localização** (opcional): caminho onde criar.

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Arquivo: `{recurso}.api.ts` (ex.: `portfolio.api.ts`).
- Teste: `{recurso}.api.test.ts`.
- Endpoints nomeados com verbos de ação em camelCase: `getPortfolio`, `listOrders`, `createOrder`, `cancelOrder`.
- Verbos coerentes com a operação: `get`, `list`, `create`, `update`, `remove`, `upload`, `download`.
- Tipos de request/response com sufixos claros: `GetPortfolioResponse`, `CreateOrderPayload`.

### Estrutura de arquivos

Dentro de uma feature FSD do módulo:

```
modules/{module}/features/{feature}/
├── api/
│   ├── {feature}.api.ts
│   └── {feature}.api.test.ts
├── index.ts
└── ...
```

Tipos de request/response específicos do endpoint podem ficar no próprio arquivo `.api.ts` quando forem exclusivos. Tipos de domínio ficam na entity correspondente.

### Implementação (ref: stack-and-tooling.md)

- RTK Query com `createApi` e `fetchBaseQuery`.
- TypeScript strict com tipagem completa de request e response.
- Tags para invalidação de cache.
- Transformação de resposta quando necessário.
- Exportar hooks gerados automaticamente.

### Teste (ref: stack-and-tooling.md)

- Vitest.
- Testar com MSW (Mock Service Worker) ou mock do fetchBaseQuery.
- Testar cenários de sucesso e erro.

## Exemplo de output

### `portfolio.api.ts`

```ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export interface PortfolioAsset {
  id: string;
  ticker: string;
  name: string;
  quantity: number;
  currentValue: number;
  performance: number;
}

export interface PortfolioSummary {
  totalValue: number;
  totalPerformance: number;
  assets: PortfolioAsset[];
}

export interface UpdateAssetPayload {
  assetId: string;
  quantity: number;
}

export const portfolioApi = createApi({
  reducerPath: 'portfolioApi',
  baseQuery: fetchBaseQuery({ baseUrl: '/api' }),
  tagTypes: ['Portfolio'],
  endpoints: (builder) => ({
    getPortfolio: builder.query<PortfolioSummary, void>({
      query: () => '/portfolio',
      providesTags: ['Portfolio'],
    }),

    getAssetDetails: builder.query<PortfolioAsset, string>({
      query: (assetId) => `/portfolio/assets/${assetId}`,
      providesTags: (_result, _error, assetId) => [{ type: 'Portfolio', id: assetId }],
    }),

    updateAsset: builder.mutation<PortfolioAsset, UpdateAssetPayload>({
      query: ({ assetId, ...body }) => ({
        url: `/portfolio/assets/${assetId}`,
        method: 'PATCH',
        body,
      }),
      invalidatesTags: ['Portfolio'],
    }),

    removeAsset: builder.mutation<void, string>({
      query: (assetId) => ({
        url: `/portfolio/assets/${assetId}`,
        method: 'DELETE',
      }),
      invalidatesTags: ['Portfolio'],
    }),
  }),
});

export const {
  useGetPortfolioQuery,
  useGetAssetDetailsQuery,
  useUpdateAssetMutation,
  useRemoveAssetMutation,
} = portfolioApi;
```

### `portfolio.api.test.ts`

```ts
import { describe, expect, it } from 'vitest';
import { portfolioApi } from './portfolio.api';

describe('portfolioApi', () => {
  it('deve ter os endpoints definidos', () => {
    expect(portfolioApi.endpoints.getPortfolio).toBeDefined();
    expect(portfolioApi.endpoints.getAssetDetails).toBeDefined();
    expect(portfolioApi.endpoints.updateAsset).toBeDefined();
    expect(portfolioApi.endpoints.removeAsset).toBeDefined();
  });

  it('deve usar o reducerPath correto', () => {
    expect(portfolioApi.reducerPath).toBe('portfolioApi');
  });
});
```
