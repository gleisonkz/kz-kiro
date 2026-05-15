# Steering — Archetype BFF Fastify

> **Steering File | Archetype: bff-fastify | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos que utilizam o archetype bff-fastify.
> Ele complementa o baseline global com diretrizes específicas para projetos BFF (Backend for Frontend) com Fastify.
>
> Baseado em: RFC-0013 (Framework padrão para BFFs), RFC-0014 (Estrutura e Organização dos BFFs)

---

## Propósito deste Arquivo

Este steering file define as diretrizes específicas para projetos BFF construídos com Fastify na MonteBravo. O Kiro deve usar este contexto ao:

- Sugerir estrutura de pastas e módulos do BFF
- Revisar código TypeScript/Fastify
- Propor abordagens para agregação de dados, orquestração e transformação
- Gerar scaffolding de routes, schemas, services e plugins

---

## O que é o BFF

O BFF (Backend for Frontend) é uma camada intermediária entre o frontend e os serviços de domínio (backends). Cada **vertical de negócio** (cliente, assessor) possui seu próprio BFF, construído como **monólito modular** — espelhando a modularidade das aplicações frontend.

### Responsabilidades do BFF

- **Composição e orquestração** de chamadas a serviços de domínio.
- **Transformação e adaptação** de payloads para o frontend.
- **Normalização** de respostas e erros.
- **Aplicação de concerns técnicos** compartilhados (auth, observabilidade, rate limiting).

### O que o BFF NÃO deve fazer

- Conter **regras de negócio de domínio** — essa responsabilidade é dos serviços de domínio.
- Persistir dados — o BFF é stateless.
- Implementar validações de domínio — apenas validação de contrato (schema).
- Substituir um API Gateway — o BFF é específico para uma vertical de negócio.

### Modelo: BFF por vertical de negócio (multi-canal)

- Um único BFF por vertical atende **múltiplos canais** (web, mobile, etc.).
- Endpoints são flexíveis e parametrizados para atender diferentes consumers.
- Ownership é **compartilhado** entre times de frontend e backend.

---

## Stack Padrão

| Tecnologia | Versão Mínima | Obrigatório | Observação |
|---|---|---|---|
| Node.js | 20 LTS | Sim | LTS mais recente |
| Fastify | 5.x | Sim | Framework HTTP principal |
| TypeScript | 5.x | Sim | Strict mode ativado |
| Zod | latest | Sim | Validação e definição de schemas |
| fastify-type-provider-zod | latest | Sim | Integração Zod + Fastify (inferência de tipos) |
| fastify-plugin (fp) | latest | Sim | Encapsulamento de plugins |
| @fastify/cors | latest | Sim | CORS configurável por ambiente |
| @fastify/helmet | latest | Sim | Headers de segurança |
| @fastify/rate-limit | latest | Sim | Rate limiting por rota/IP |
| @fastify/swagger | latest | Sim | Documentação OpenAPI automática |
| @fastify/swagger-ui | latest | Sim | UI para documentação |
| Pino | built-in | Sim | Logger estruturado (incluso no Fastify) |
| Vitest | latest | Sim | Testes unitários e de integração |
| ESLint + Prettier | latest | Sim | Linting e formatação |
| tsx | latest | Sim | Execução TypeScript em dev |
| tsup | latest | Sim | Build para produção |

---

## Estrutura de Pastas Padrão

```
bff-{vertical}/
├── src/
│   ├── app/
│   │   ├── server.ts              # Criação e configuração do Fastify
│   │   ├── plugins/               # Plugins globais (auth, cors, error handler, logger)
│   │   └── config/                # Configuração de ambiente e variáveis
│   │
│   ├── modules/                   # Módulos de domínio (bounded contexts da vertical)
│   │   └── <domain>/
│   │       ├── routes/
│   │       │   ├── get-<resource>.ts
│   │       │   ├── create-<resource>.ts
│   │       │   └── index.ts       # Registro das rotas do módulo
│   │       ├── schemas/
│   │       │   ├── get-<resource>.schema.ts
│   │       │   └── create-<resource>.schema.ts
│   │       ├── services/
│   │       │   ├── <domain>.service.ts
│   │       │   └── <domain>.mapper.ts
│   │       └── index.ts           # Plugin Fastify do módulo (API pública)
│   │
│   └── shared/                    # Recursos compartilhados internos
│       ├── errors/                # Error model padronizado
│       ├── schemas/               # Schemas reutilizáveis (pagination, etc.)
│       ├── hooks/                 # Hooks Fastify compartilhados
│       └── types/                 # Tipos compartilhados internos
│
├── test/
│   ├── modules/
│   │   ├── portfolio/
│   │   └── trading/
│   └── helpers/
│
├── package.json
└── tsconfig.json
```

---

## Packages Compartilhados entre BFFs

Para evitar duplicação e garantir consistência entre BFFs de diferentes verticais:

| Package | Responsabilidade |
|---|---|
| `bff-core` | Plugins base (auth, error handler, logger, health check), configuração compartilhada, hooks comuns |
| `bff-clients` | Clients HTTP tipados para serviços de domínio, DTOs, configuração de transporte |
| `bff-contracts` | Schemas compartilhados (pagination, error model, common types) |
| `bff-test-utils` | Helpers de teste, factories, mocks de serviços |

---

## Comunicação com Serviços Downstream

O BFF se comunica com serviços de domínio via HTTP/REST (padrão principal).

### Padrões obrigatórios para clients HTTP

- **Timeout**: configurável por client/rota (padrão: 5s).
- **Retry**: com backoff exponencial para erros transientes (5xx, timeout).
- **Circuit Breaker**: para proteger contra serviços degradados.
- **Correlation ID**: propagar em todas as chamadas downstream.
- **Request ID**: gerar no BFF e propagar para rastreabilidade.

### Chamadas paralelas

Quando uma rota precisa agregar dados de múltiplos serviços, usar `Promise.all` ou `Promise.allSettled`:
- Executar chamadas em paralelo.
- Tratar falhas parciais (degradação graciosa).
- Retornar dados disponíveis mesmo se um serviço falhar.

---

## Error Model Padronizado

Todas as respostas de erro seguem um formato consistente:

```json
{
  "statusCode": 400,
  "code": "VALIDATION_ERROR",
  "message": "Invalid request parameters",
  "details": [
    {
      "field": "accountId",
      "message": "must be a string"
    }
  ]
}
```

### Códigos de erro padronizados

| Código | Uso |
|---|---|
| `VALIDATION_ERROR` | Falha de validação de schema |
| `NOT_FOUND` | Recurso não encontrado no serviço de domínio |
| `UPSTREAM_ERROR` | Falha em serviço de domínio |
| `UNAUTHORIZED` | Token inválido ou ausente |
| `FORBIDDEN` | Sem permissão para o recurso |
| `INTERNAL_ERROR` | Erro inesperado |
| `TIMEOUT` | Timeout na chamada a serviço de domínio |

---

## Padrões de Código

### Módulos como Plugins Fastify

Cada módulo é registrado como um **plugin Fastify**, aproveitando o mecanismo de **encapsulation** para isolamento:

```ts
// src/modules/portfolio/index.ts
import { FastifyPluginAsync } from 'fastify';
import { portfolioRoutes } from './routes';

const portfolioModule: FastifyPluginAsync = async (fastify) => {
  fastify.register(portfolioRoutes, { prefix: '/portfolio' });
};

export default portfolioModule;
```

### Rotas

Cada arquivo em `routes/` define um endpoint específico com schema de validação e handler:

```ts
// src/modules/portfolio/routes/get-positions.ts
import { FastifyPluginAsync } from 'fastify';
import { getPositionsSchema } from '../schemas/get-positions.schema';
import { PortfolioService } from '../services/portfolio.service';

const getPositions: FastifyPluginAsync = async (fastify) => {
  fastify.get(
    '/positions',
    { schema: getPositionsSchema },
    async (request, reply) => {
      const { accountId } = request.query as { accountId: string };
      const service = new PortfolioService(fastify);
      const positions = await service.getPositions(accountId);
      return positions;
    }
  );
};

export { getPositions };
```

### Schemas com Zod

Schemas definem o contrato da rota usando **Zod**, integrados com o **Zod Type Provider** do Fastify:

```ts
// src/modules/portfolio/schemas/get-positions.schema.ts
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
```

### Services (Orquestração)

Services encapsulam a lógica de orquestração: chamam serviços de domínio, compõem respostas e aplicam transformações.

```ts
// src/modules/portfolio/services/portfolio.service.ts
import { FastifyInstance } from 'fastify';
import { mapPositionsResponse } from './portfolio.mapper';

export class PortfolioService {
  constructor(private readonly fastify: FastifyInstance) {}

  async getPositions(accountId: string) {
    const [positions, quotes] = await Promise.all([
      this.fastify.clients.portfolioApi.getPositions(accountId),
      this.fastify.clients.marketDataApi.getQuotes(accountId),
    ]);

    return mapPositionsResponse(positions, quotes);
  }
}
```

### Mappers (Transformação)

Funções puras que transformam DTOs dos serviços de domínio para o formato esperado pelo frontend:

```ts
// src/modules/portfolio/services/portfolio.mapper.ts
import type { PositionDTO, QuoteDTO } from '@monte-bravo/bff-clients';

export function mapPositionsResponse(positions: PositionDTO[], quotes: QuoteDTO[]) {
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

---

## Registro de Módulos no Servidor

```ts
// src/app/server.ts
import Fastify from 'fastify';
import portfolioModule from '../modules/portfolio';
import tradingModule from '../modules/trading';
import onboardingModule from '../modules/onboarding';
import { authPlugin } from './plugins/auth';
import { errorHandlerPlugin } from './plugins/error-handler';
import { loggerPlugin } from './plugins/logger';
import { clientsPlugin } from './plugins/clients';

export async function buildServer() {
  const fastify = Fastify({ logger: true });

  // Plugins globais
  await fastify.register(loggerPlugin);
  await fastify.register(authPlugin);
  await fastify.register(errorHandlerPlugin);
  await fastify.register(clientsPlugin);

  // Módulos de domínio — cada um registrado com seu prefixo
  await fastify.register(portfolioModule, { prefix: '/api/v1' });
  await fastify.register(tradingModule, { prefix: '/api/v1' });
  await fastify.register(onboardingModule, { prefix: '/api/v1' });

  return fastify;
}
```

---

## Regras de Fronteira entre Módulos

- Módulos não devem importar implementações internas de outros módulos.
- Comunicação entre módulos, quando necessária, deve ocorrer via contratos explícitos ou composição na camada `app/`.
- Cada módulo é encapsulado pelo mecanismo de plugin do Fastify.
- Dependências entre módulos devem ser raras, intencionais e visíveis.

---

## Padrões de Teste

- Cobertura mínima: 80% para código crítico (services, mappers).
- Testes unitários para mappers e services.
- Testes de integração para rotas (usando `fastify.inject()`).
- Vitest como runner.
- Padrão AAA (Arrange, Act, Assert).

---

## O que o Kiro Deve Verificar

Ao analisar código do BFF Fastify, o Kiro deve verificar:

- [ ] Schemas Zod em todas as rotas (query, params, body, response).
- [ ] Ausência de lógica de negócio no BFF (apenas orquestração/transformação).
- [ ] Módulos registrados como plugins Fastify com encapsulamento.
- [ ] Clients com timeout, retry e circuit breaker configurados.
- [ ] Correlation ID propagado em todas as chamadas downstream.
- [ ] Error handling consistente com o error model padronizado.
- [ ] Logs estruturados com contexto adequado.
- [ ] Documentação Swagger gerada automaticamente via schemas.
- [ ] Ausência de segredos hardcoded.
- [ ] Cobertura de testes adequada.
- [ ] Chamadas paralelas quando possível (Promise.all/allSettled).
- [ ] Fronteiras entre módulos respeitadas (sem imports cruzados).

---

## Referências

- [RFC-0013 – Framework padrão para BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777601)
- [RFC-0014 – Estrutura e Organização dos BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777613)
- [ADR-0003 – Monolito Modular vs Microfrontends](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757151)
- [ADR-0011 – Arquitetura das Aplicações Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/132349958)
- [Fastify Documentation](https://fastify.dev/docs/latest/)
- [Fastify Plugins – Encapsulation](https://fastify.dev/docs/latest/Reference/Plugins/)
- [Fastify Type Providers – Zod](https://fastify.dev/docs/latest/Reference/Type-Providers/#zod)

---

*Versão: 0.2.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
