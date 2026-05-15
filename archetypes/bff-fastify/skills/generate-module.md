---
name: "Gerar Módulo BFF"
description: "Cria a estrutura completa de um módulo BFF Fastify: routes, schemas Zod, services, mappers e plugin de registro."
inclusion: manual
---

# Gerar Módulo BFF

## Quando usar

Quando o desenvolvedor pedir para criar um novo módulo/domínio no BFF (ex.: portfolio, trading, onboarding).

## Inputs esperados

- **Nome do módulo** (obrigatório): nome do domínio em kebab-case (ex.: `portfolio`, `trading`, `onboarding`).
- **Endpoints** (opcional): lista de endpoints a criar (ex.: `GET /positions`, `POST /orders`).
- **Serviços downstream** (opcional): quais serviços o módulo consome.

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Diretório do módulo: `kebab-case`, orientado ao domínio da vertical.
- Subdiretórios: `routes/`, `schemas/`, `services/`.
- Arquivos de rota: `<verbo>-<recurso>.ts`.
- Schemas: `<route-name>.schema.ts`.
- Services: `<domain>.service.ts`.
- Mappers: `<domain>.mapper.ts`.

### Estrutura do módulo (ref: architecture.md, RFC-0014)

```
src/modules/{module-name}/
├── routes/
│   ├── get-{resource}.ts          # Endpoint específico
│   ├── create-{resource}.ts
│   └── index.ts                   # Registro das rotas do módulo
├── schemas/
│   ├── get-{resource}.schema.ts   # Contrato Zod (request/response)
│   └── create-{resource}.schema.ts
├── services/
│   ├── {module}.service.ts        # Orquestração e composição
│   └── {module}.mapper.ts         # Transformação de payloads
└── index.ts                       # Plugin Fastify do módulo (API pública)
```

### Regras de implementação

- **index.ts**: plugin Fastify que registra as rotas com prefixo do módulo.
- **routes/**: cada arquivo define um endpoint com schema e handler.
- **schemas/**: definir com Zod, exportar tipos via `z.infer`.
- **services/**: orquestrar clients via `fastify.clients.*`, aplicar mappers.
- **mappers/**: funções puras, sem side effects.

### O que gerar

1. `index.ts` — plugin Fastify do módulo.
2. `routes/index.ts` — registro de rotas.
3. Arquivo(s) de rota com handler.
4. Schema(s) Zod para cada rota.
5. Service com orquestração.
6. Mapper com transformação.

### O que NÃO gerar automaticamente

- Clients HTTP — usar a skill `generate-client` separadamente.
- Plugins globais — usar a skill `generate-plugin` separadamente.
- Lógica de negócio — o BFF não deve conter lógica de negócio.

## Exemplo de output

Para módulo `portfolio` com endpoint `GET /positions`:

### `src/modules/portfolio/index.ts`

```ts
import { FastifyPluginAsync } from 'fastify';
import { portfolioRoutes } from './routes';

const portfolioModule: FastifyPluginAsync = async (fastify) => {
  fastify.register(portfolioRoutes, { prefix: '/portfolio' });
};

export default portfolioModule;
```

### `src/modules/portfolio/routes/index.ts`

```ts
import { FastifyPluginAsync } from 'fastify';
import { getPositions } from './get-positions';

export const portfolioRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.register(getPositions);
};
```

### `src/modules/portfolio/routes/get-positions.ts`

```ts
import { FastifyPluginAsync } from 'fastify';
import { getPositionsSchema } from '../schemas/get-positions.schema';
import { PortfolioService } from '../services/portfolio.service';

const getPositions: FastifyPluginAsync = async (fastify) => {
  fastify.get(
    '/positions',
    { schema: getPositionsSchema },
    async (request) => {
      const { accountId } = request.query as { accountId: string };
      const service = new PortfolioService(fastify);
      return service.getPositions(accountId);
    },
  );
};

export { getPositions };
```

### `src/modules/portfolio/schemas/get-positions.schema.ts`

```ts
import { z } from 'zod';

export const getPositionsQuerySchema = z.object({
  accountId: z.string(),
});

export const positionSchema = z.object({
  ticker: z.string(),
  quantity: z.number(),
  currentValue: z.number(),
  profitLoss: z.number(),
});

export const getPositionsResponseSchema = z.object({
  positions: z.array(positionSchema),
  totalValue: z.number(),
});

export type GetPositionsQuery = z.infer<typeof getPositionsQuerySchema>;
export type GetPositionsResponse = z.infer<typeof getPositionsResponseSchema>;

export const getPositionsSchema = {
  querystring: getPositionsQuerySchema,
  response: {
    200: getPositionsResponseSchema,
  },
};
```

### `src/modules/portfolio/services/portfolio.service.ts`

```ts
import { FastifyInstance } from 'fastify';
import { mapPositionsResponse } from './portfolio.mapper';
import type { GetPositionsResponse } from '../schemas/get-positions.schema';

export class PortfolioService {
  constructor(private readonly fastify: FastifyInstance) {}

  async getPositions(accountId: string): Promise<GetPositionsResponse> {
    const [positions, quotes] = await Promise.all([
      this.fastify.clients.portfolioApi.getPositions(accountId),
      this.fastify.clients.marketDataApi.getQuotes(accountId),
    ]);

    return mapPositionsResponse(positions, quotes);
  }
}
```

### `src/modules/portfolio/services/portfolio.mapper.ts`

```ts
import type { GetPositionsResponse } from '../schemas/get-positions.schema';

interface PositionDTO {
  ticker: string;
  quantity: number;
  costBasis: number;
}

interface QuoteDTO {
  ticker: string;
  price: number;
}

export function mapPositionsResponse(
  positions: PositionDTO[],
  quotes: QuoteDTO[],
): GetPositionsResponse {
  const quotesMap = new Map(quotes.map((q) => [q.ticker, q]));

  const mapped = positions.map((pos) => {
    const quote = quotesMap.get(pos.ticker);
    const currentValue = (quote?.price ?? 0) * pos.quantity;
    return {
      ticker: pos.ticker,
      quantity: pos.quantity,
      currentValue,
      profitLoss: currentValue - pos.costBasis,
    };
  });

  const totalValue = mapped.reduce((sum, p) => sum + p.currentValue, 0);
  return { positions: mapped, totalValue };
}
```

### Registro no servidor

Após criar o módulo, registrá-lo em `src/app/server.ts`:

```ts
import portfolioModule from '../modules/portfolio';

// Dentro de buildServer():
await fastify.register(portfolioModule, { prefix: '/api/v1' });
```
