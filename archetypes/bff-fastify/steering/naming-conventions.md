---
inclusion: manual
---

# Convenções de Nomenclatura — BFF Fastify

> **Steering File | Archetype: bff-fastify | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos BFF Fastify da MonteBravo.
> Ele define o padrão oficial de nomenclatura para diretórios, arquivos e símbolos de código.
>
> Baseado em: RFC-0014 (Estrutura e Organização dos BFFs)

---

## Princípios Gerais

- Nomes devem ser claros, previsíveis e consistentes com a responsabilidade do artefato.
- Priorizar legibilidade e busca simples no código.
- Não misturar estilos de nomenclatura para o mesmo tipo de artefato.

### Regra de idioma

- Nomes de arquivos, pastas e símbolos de código: inglês técnico.
- Documentação e comentários explicativos: português do Brasil.
- Não misturar português e inglês no mesmo identificador.

---

## Diretórios

- `kebab-case` sempre.
- Módulos: nomes curtos orientados ao domínio da vertical: `portfolio`, `trading`, `onboarding`, `profile`.
- Subdiretórios de módulo: `routes`, `schemas`, `services`.
- Diretórios globais: `app`, `modules`, `shared`, `plugins`, `config`.
- Proibidos: `misc`, `helpers`, `common2`, `temp`, `general`.

---

## Arquivos

### Convenção geral

- Todos os arquivos em `kebab-case`.
- O nome do arquivo deve refletir o principal artefato exportado.

### Arquivos de rota

- Nomeados pela ação: `get-positions.ts`, `create-order.ts`, `get-summary.ts`.
- Padrão: `<verbo>-<recurso>.ts`.
- Arquivo `index.ts` para registro das rotas do módulo.

### Sufixos de arquivo

| Tipo | Sufixo | Exemplo |
|---|---|---|
| Rota (endpoint) | sem sufixo | `get-positions.ts` |
| Registro de rotas | `index.ts` | `routes/index.ts` |
| Schema (Zod) | `.schema.ts` | `get-positions.schema.ts` |
| Service (orquestração) | `.service.ts` | `portfolio.service.ts` |
| Mapper (transformação) | `.mapper.ts` | `portfolio.mapper.ts` |
| Plugin Fastify | `.plugin.ts` ou sem sufixo em `plugins/` | `auth.ts`, `error-handler.ts` |
| Tipos | `.types.ts` | `portfolio.types.ts` |
| Configuração | `.config.ts` | `env.config.ts` |
| Teste unitário | `.test.ts` | `portfolio.mapper.test.ts` |
| Teste de integração | `.test.ts` (em `test/`) | `portfolio.test.ts` |
| Fixture de teste | `.fixture.ts` | `portfolio.fixture.ts` |
| Constantes | `.constants.ts` | `error-codes.constants.ts` |

---

## Módulos

- Diretório: `kebab-case`, orientado ao domínio da vertical.
- `index.ts`: plugin Fastify que registra as rotas (API pública do módulo).
- Exemplos: `portfolio`, `trading`, `onboarding`, `notifications`.

---

## Rotas (URLs)

- `kebab-case` para segmentos de URL.
- Plural para coleções: `/positions`, `/orders`.
- Prefixo de API: `/api/v1/`.
- Cada módulo adiciona seu prefixo: `/api/v1/portfolio/positions`.
- Parâmetros em `camelCase`: `:accountId`, `:orderId`.

---

## Schemas Zod

- Nomeados pela rota + sufixo descritivo: `getPositionsQuerySchema`, `getPositionsResponseSchema`.
- Tipos inferidos: `GetPositionsQuery`, `GetPositionsResponse` (via `z.infer`).
- Arquivo: `<route-name>.schema.ts`.

---

## Funções

- `camelCase`.
- Handlers: implícitos no arquivo de rota (não precisam de nome especial).
- Services: métodos com verbo de ação — `getPositions`, `createOrder`, `getDashboard`.
- Mappers: prefixo `map` — `mapPositionsResponse`, `mapOrderDetails`.

---

## Classes

- `PascalCase`.
- Services: `<Domain>Service` — `PortfolioService`, `TradingService`.
- Clients: `<Service>Client` ou `<Service>Api` — `PortfolioApiClient`.

---

## Variáveis e Constantes

- Variáveis: `camelCase`.
- Constantes exportadas e imutáveis: `SCREAMING_SNAKE_CASE` — `DEFAULT_TIMEOUT_MS`, `MAX_RETRY_ATTEMPTS`.
- Constantes locais: `camelCase`.

---

## Tipos e Interfaces

- `PascalCase`, sem prefixos artificiais.
- DTOs de serviços downstream: sufixo `DTO` — `PositionDTO`, `QuoteDTO`.
- Tipos de resposta do BFF: sem sufixo ou sufixo `Response` — `GetPositionsResponse`.
- Tipos de configuração: sufixo `Config` ou `Options` — `ClientConfig`, `RetryOptions`.

---

## Plugins Fastify

- Arquivo: em `src/app/plugins/`, nomeado pela responsabilidade: `auth.ts`, `error-handler.ts`, `logger.ts`, `clients.ts`.
- Função exportada: `camelCase` com sufixo `Plugin` — `authPlugin`, `errorHandlerPlugin`.
- Usar `fastify-plugin` (`fp`) para plugins que devem ser acessíveis fora do escopo de encapsulamento.

---

## Variáveis de Ambiente

- `SCREAMING_SNAKE_CASE`.
- Prefixo por contexto: `AUTH_`, `PORTFOLIO_SERVICE_`, `TRADING_SERVICE_`.
- Exemplos: `PORT`, `NODE_ENV`, `AUTH_JWT_SECRET`, `PORTFOLIO_SERVICE_URL`.

---

## O que Evitar

- Nomes genéricos: `data`, `item`, `info`, `handler`, `helper`, `service` (sem contexto).
- Nomes temporários: `newFile`, `test2`, `finalVersion`.
- Abreviações obscuras: `prtf` em vez de `portfolio`, `ord` em vez de `order`.
- Misturar singular e plural sem critério.

---

## Exemplos Válidos

| Tipo | Exemplos |
|---|---|
| Diretórios | `modules`, `portfolio`, `trading`, `routes`, `schemas`, `services` |
| Arquivos de rota | `get-positions.ts`, `create-order.ts`, `get-summary.ts` |
| Schemas | `get-positions.schema.ts`, `create-order.schema.ts` |
| Services | `portfolio.service.ts`, `trading.service.ts` |
| Mappers | `portfolio.mapper.ts`, `trading.mapper.ts` |
| Plugins | `auth.ts`, `error-handler.ts`, `clients.ts` |
| Tipos Zod | `getPositionsQuerySchema`, `GetPositionsResponse` |
| Classes | `PortfolioService`, `TradingService` |

---

*Versão: 0.2.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
