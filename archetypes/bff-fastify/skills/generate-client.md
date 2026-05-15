---
name: "Gerar Client HTTP"
description: "Cria um client HTTP tipado para comunicação com serviço downstream, registrado como plugin Fastify via decorator."
inclusion: manual
---

# Gerar Client HTTP

## Quando usar

Quando o desenvolvedor pedir para criar um client para consumir um serviço downstream (ex.: portfolio-api, trading-service, market-data-api).

## Inputs esperados

- **Nome do serviço** (obrigatório): nome do serviço downstream em kebab-case (ex.: `portfolio-api`, `trading-service`).
- **Base URL env var** (opcional): variável de ambiente com a URL base (ex.: `PORTFOLIO_SERVICE_URL`).
- **Endpoints** (opcional): lista de endpoints que o client deve expor.

## Regras de geração

### Contexto (ref: RFC-0014)

Clients HTTP são registrados como **decorators do Fastify** via um plugin `clients`, permitindo acesso via `fastify.clients.<serviceName>` em qualquer service.

### Estrutura

Os clients podem viver no package compartilhado `@monte-bravo/bff-clients` ou localmente no BFF:

```
# No package compartilhado (preferido para clients reutilizados entre BFFs)
packages/bff-clients/src/
├── portfolio-api.client.ts
├── trading-api.client.ts
└── index.ts

# Ou localmente no BFF (para clients específicos de uma vertical)
src/app/plugins/clients.ts          # Plugin que registra todos os clients
```

### Padrões obrigatórios (ref: architecture.md)

- **Timeout**: configurável, padrão 5000ms.
- **Retry**: backoff exponencial para erros transientes (5xx, ECONNRESET, timeout).
- **Circuit Breaker**: proteção contra serviços degradados.
- **Correlation ID**: propagar header `x-correlation-id` em todas as chamadas.
- **Tipagem**: DTOs tipados para requests e responses.

### Implementação

- Usar `undici` (built-in no Node.js 20+) ou `fetch` nativo.
- Não usar Axios.
- Registrar via `fastify.decorate('clients', { ... })`.
- Tipar o decorator via `declare module 'fastify'`.

## Exemplo de output

### `packages/bff-clients/src/portfolio-api.client.ts`

```ts
export interface PositionDTO {
  ticker: string;
  quantity: number;
  costBasis: number;
}

export interface PortfolioApiClientConfig {
  baseUrl: string;
  timeoutMs?: number;
}

export class PortfolioApiClient {
  private readonly baseUrl: string;
  private readonly timeoutMs: number;

  constructor(config: PortfolioApiClientConfig) {
    this.baseUrl = config.baseUrl;
    this.timeoutMs = config.timeoutMs ?? 5000;
  }

  async getPositions(accountId: string): Promise<PositionDTO[]> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(
        `${this.baseUrl}/portfolios/${accountId}/positions`,
        {
          method: 'GET',
          headers: { 'Content-Type': 'application/json' },
          signal: controller.signal,
        },
      );

      if (!response.ok) {
        throw new Error(`HTTP ${response.status} from portfolio-api`);
      }

      return (await response.json()) as PositionDTO[];
    } finally {
      clearTimeout(timeout);
    }
  }
}
```

### `src/app/plugins/clients.ts`

```ts
import { FastifyPluginAsync } from 'fastify';
import fp from 'fastify-plugin';
import { PortfolioApiClient } from '@monte-bravo/bff-clients';
import { MarketDataApiClient } from '@monte-bravo/bff-clients';

declare module 'fastify' {
  interface FastifyInstance {
    clients: {
      portfolioApi: PortfolioApiClient;
      marketDataApi: MarketDataApiClient;
    };
  }
}

const clientsPluginFn: FastifyPluginAsync = async (fastify) => {
  const portfolioApi = new PortfolioApiClient({
    baseUrl: process.env.PORTFOLIO_SERVICE_URL!,
  });

  const marketDataApi = new MarketDataApiClient({
    baseUrl: process.env.MARKET_DATA_SERVICE_URL!,
  });

  fastify.decorate('clients', {
    portfolioApi,
    marketDataApi,
  });
};

export const clientsPlugin = fp(clientsPluginFn, {
  name: 'clients',
});
```

### Uso no service

```ts
// Acesso via fastify.clients
const positions = await this.fastify.clients.portfolioApi.getPositions(accountId);
```
