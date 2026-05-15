# Arquitetura do BFF Fastify

> **Steering File | Archetype: bff-fastify | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos BFF Fastify da MonteBravo.
> Ele define a arquitetura interna, padrões de comunicação e fronteiras de responsabilidade.
>
> Baseado em: RFC-0013 (Framework padrão para BFFs), RFC-0014 (Estrutura e Organização dos BFFs), ADR-0003, ADR-0011

---

## Papel Arquitetural do BFF

O BFF é uma camada de **composição** entre as aplicações frontend e os serviços de domínio:

```
┌─────────────────┐     ┌─────────────────┐     ┌──────────────────────┐
│  Apps Frontend  │────▶│  BFF            │────▶│  Serviços de Domínio │
│  (Web, Mobile)  │◀────│  (Fastify)      │◀────│  (NestJS, etc.)      │
└─────────────────┘     └─────────────────┘     └──────────────────────┘
                              │
                              ▼
                        Composição
                        Orquestração
                        Transformação
                        Normalização
```

### Princípios fundamentais

1. **BFF por vertical de negócio**: cada vertical (cliente, assessor) possui um BFF dedicado, independente do canal de consumo.
2. **Multi-canal**: um único BFF atende web, mobile e outros consumers da mesma vertical.
3. **Repositório próprio**: BFFs vivem fora do monorepo frontend, em repositório(s) dedicado(s).
4. **Ownership compartilhado**: BFFs são responsabilidade conjunta de times de frontend (web e mobile) e backend.
5. **Espelhamento modular**: a modularidade do BFF reflete os bounded contexts das aplicações da vertical.
6. **Ownership por módulo**: cada time é dono do seu módulo no BFF.
7. **Zero regras de negócio**: BFFs orquestram, transformam e adaptam — nunca decidem.
8. **Contratos explícitos**: toda rota possui schema de entrada e saída, com validação via Zod.
9. **Consistência via convenção**: a estrutura é padronizada e enforçada por linting e templates.

---

## Posicionamento no Repositório

Os BFFs vivem em **repositório(s) próprio(s)**, fora do monorepo frontend:

```
bff-cliente (repo)/                       # BFF da vertical cliente (web + mobile + ...)
├── src/
│   ├── app/
│   ├── modules/
│   └── shared/
├── package.json
└── tsconfig.json

bff-assessor (repo)/                      # BFF da vertical assessor (web + mobile + ...)
├── src/
│   ├── app/
│   ├── modules/
│   └── shared/
├── package.json
└── tsconfig.json
```

---

## Arquitetura Interna: Monólito Modular

A organização interna segue módulos alinhados aos bounded contexts da vertical de negócio:

```
src/modules/
├── portfolio/          # Carteira, posições, rentabilidade
├── trading/            # Ordens, execução
├── onboarding/         # Cadastro, KYC, abertura de conta
├── profile/            # Dados do usuário
└── notifications/      # Notificações e alertas
```

Cada módulo do BFF corresponde a um bounded context de negócio da vertical e agrupa todas as rotas, schemas, serviços e transformações relacionadas a um domínio, atendendo todos os canais.

---

## Definição de Módulo no BFF

Um módulo no BFF corresponde a um **bounded context da vertical de negócio**.

### Critérios para identificar um módulo

- Corresponde a um **bounded context** de negócio da vertical.
- Agrupa rotas de um **mesmo domínio funcional**.
- Possui **ownership** claro de um time.
- Pode evoluir de forma relativamente **independente**.

### Módulo como Plugin Fastify

Cada módulo é registrado como um **plugin Fastify**, aproveitando o mecanismo de **encapsulation** do framework para isolamento.

O `index.ts` de cada módulo é a **API pública** do módulo no BFF:

```ts
// src/modules/portfolio/index.ts
import { FastifyPluginAsync } from 'fastify';
import { portfolioRoutes } from './routes';

const portfolioModule: FastifyPluginAsync = async (fastify) => {
  fastify.register(portfolioRoutes, { prefix: '/portfolio' });
};

export default portfolioModule;
```

---

## Anatomia de um Módulo

```
modules/{domain}/
├── routes/
│   ├── get-positions.ts           # Endpoint específico
│   ├── get-summary.ts
│   └── index.ts                   # Registro das rotas do módulo
├── schemas/
│   ├── get-positions.schema.ts    # Contrato Zod (request/response)
│   └── get-summary.schema.ts
├── services/
│   ├── {domain}.service.ts        # Orquestração e composição
│   └── {domain}.mapper.ts         # Transformação de payloads
└── index.ts                       # Plugin Fastify do módulo (API pública)
```

### Responsabilidades por camada

| Camada | Responsabilidade | NÃO deve |
|---|---|---|
| `routes/` | Definir endpoint, schema e handler | Conter lógica de orquestração |
| `schemas/` | Definir contratos Zod (entrada/saída) | Conter lógica |
| `services/` | Orquestrar clients, compor respostas | Conter regras de negócio |
| `services/*.mapper.ts` | Transformar DTOs (funções puras) | Ter side effects |

---

## Fluxo de uma Request

```
Request → Route (schema validation) → Handler → Service → Client(s) → Serviço(s) Downstream
                                                              ↓
                                                           Mapper(s)
                                                              ↓
                                                           Response
```

1. **Route**: define o endpoint e aplica validação de schema Zod automaticamente.
2. **Handler**: extrai dados validados da request, instancia service, retorna response.
3. **Service**: orquestra chamadas a clients (paralelas quando possível), aplica mappers.
4. **Client**: faz a chamada HTTP ao serviço downstream.
5. **Mapper**: transforma DTOs do serviço para o formato esperado pelo frontend.

---

## Padrões de Agregação

### Agregação paralela (múltiplos serviços)

```ts
async getPositions(accountId: string) {
  const [positions, quotes] = await Promise.all([
    this.fastify.clients.portfolioApi.getPositions(accountId),
    this.fastify.clients.marketDataApi.getQuotes(accountId),
  ]);

  return mapPositionsResponse(positions, quotes);
}
```

### Agregação com degradação graciosa

```ts
async getDashboard(accountId: string) {
  const [positionsResult, alertsResult] = await Promise.allSettled([
    this.fastify.clients.portfolioApi.getPositions(accountId),
    this.fastify.clients.alertsApi.getActive(accountId),
  ]);

  return mapDashboard({
    positions: positionsResult.status === 'fulfilled' ? positionsResult.value : [],
    alerts: alertsResult.status === 'fulfilled' ? alertsResult.value : [],
  });
}
```

### Agregação sequencial (dependência entre chamadas)

```ts
async getOrderDetails(orderId: string) {
  const order = await this.fastify.clients.tradingApi.getById(orderId);
  const asset = await this.fastify.clients.assetsApi.getByTicker(order.ticker);
  return mapOrderDetails(order, asset);
}
```

---

## Regras de Fronteira entre Módulos

- Módulos **não devem importar** implementações internas de outros módulos.
- Comunicação entre módulos, quando necessária, deve ocorrer via **contratos explícitos** ou composição na camada `app/`.
- Cada módulo é **encapsulado** pelo mecanismo de plugin do Fastify.
- Dependências entre módulos devem ser **raras, intencionais e visíveis**.

---

## Resiliência

### Circuit Breaker

Cada client deve implementar circuit breaker:

| Parâmetro | Valor padrão |
|---|---|
| Threshold de falhas | 5 falhas consecutivas |
| Timeout do circuit | 30 segundos |
| Requests em half-open | 3 |

### Timeout por camada

| Camada | Timeout padrão |
|---|---|
| Request total (frontend → BFF) | 15s |
| Client individual | 5s |
| Client com retry | 10s (total com retries) |

---

## Observabilidade

### Logs estruturados (Pino)

- Logger built-in do Fastify (Pino).
- Formato JSON estruturado.
- Incluir em todo log: `correlationId`, `requestId`, `userId` (quando autenticado).

### Métricas

- Latência por rota (p50, p95, p99).
- Taxa de erro por rota e por serviço downstream.
- Circuit breaker state changes.

### Tracing

- OpenTelemetry para distributed tracing.
- Propagar trace context para serviços downstream.

---

## Health Checks

- `GET /health/live` — liveness (o processo está rodando).
- `GET /health/ready` — readiness (dependências estão acessíveis).

---

## Versionamento de API

- Prefixo de rota: `/api/v1/`.
- Todas as rotas de módulos sob este prefixo.
- Manter compatibilidade backward por pelo menos 1 versão.

---

## Referências

- [RFC-0013 – Framework padrão para BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777601)
- [RFC-0014 – Estrutura e Organização dos BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777613)
- [ADR-0003 – Monolito Modular vs Microfrontends](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757151)
- [ADR-0011 – Arquitetura das Aplicações Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/132349958)
- [Fastify Documentation](https://fastify.dev/docs/latest/)
- [Fastify Plugins – Encapsulation](https://fastify.dev/docs/latest/Reference/Plugins/)
- [BFF Pattern - Sam Newman](https://samnewman.io/patterns/architectural/bff/)

---

*Versão: 0.2.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
