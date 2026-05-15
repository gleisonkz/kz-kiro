# Stack Base e Ferramental — BFF Fastify

> **Steering File | Archetype: bff-fastify | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos BFF Fastify da MonteBravo.
> Ele define a stack base de tecnologias, ferramental e configuração do projeto.
>
> Baseado em: RFC-0013 (Framework padrão para BFFs), RFC-0014 (Estrutura e Organização dos BFFs)

---

## Stack Base Obrigatória

| Tecnologia | Versão/Modo | Finalidade |
|---|---|---|
| Node.js | 20 LTS | Runtime |
| Fastify | 5.x | Framework HTTP (plugins, encapsulation, schema-based) |
| TypeScript | 5.x strict | Tipagem em todo o projeto |
| Zod | latest | Validação e definição de schemas |
| fastify-type-provider-zod | latest | Integração Zod + Fastify (inferência de tipos a partir de schemas) |
| fastify-plugin (fp) | latest | Encapsulamento de plugins compartilhados |
| @fastify/cors | latest | CORS |
| @fastify/helmet | latest | Headers de segurança |
| @fastify/rate-limit | latest | Rate limiting |
| @fastify/swagger | latest | Geração de OpenAPI spec |
| @fastify/swagger-ui | latest | UI de documentação |
| Pino | built-in | Logger estruturado (incluso no Fastify) |
| Vitest | latest | Testes unitários e de integração |
| ESLint + Prettier | latest | Linting e formatação |
| tsx | latest | Execução TS em desenvolvimento |
| tsup | latest | Build para produção (ESM) |
| pnpm | latest | Gerenciador de pacotes |

### Por que Fastify?

Conforme RFC-0013, Fastify foi escolhido por oferecer:

- **Arquitetura orientada a plugins** — ideal para monólito modular.
- **Encapsulation** — isolamento estrutural entre módulos.
- **Abordagem schema-based** — validação e serialização integradas.
- **Type Providers** — inferência de tipos em TypeScript a partir de schemas.
- **Baixa fricção** para times de frontend em TypeScript.
- **Estrutura suficiente** sem excesso de cerimônia.

### Por que Zod (e não TypeBox)?

Conforme RFC-0014, Zod foi escolhido como biblioteca de schemas por:

- Integração com Fastify via `fastify-type-provider-zod`.
- Inferência de tipos TypeScript nativa (`z.infer<typeof schema>`).
- API expressiva e familiar para times TypeScript.
- Conversão automática para JSON Schema (compatível com Swagger).

### Padrões de módulo

- ESM-first em todo o código (`"type": "module"` no package.json).
- Não usar CommonJS em código novo.
- Target de compilação: `ES2022` ou superior.

---

## Configuração TypeScript

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

---

## Scripts Padrão (package.json)

```json
{
  "scripts": {
    "dev": "tsx watch src/app/server.ts",
    "build": "tsup src/app/server.ts --format esm --dts",
    "start": "node dist/server.js",
    "lint": "eslint src/ --ext .ts",
    "lint:fix": "eslint src/ --ext .ts --fix",
    "format": "prettier --write src/",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  }
}
```

---

## Packages Compartilhados

Os BFFs de diferentes verticais compartilham packages comuns:

| Package | Responsabilidade |
|---|---|
| `@monte-bravo/bff-core` | Plugins base (auth, error handler, logger, health check), configuração compartilhada |
| `@monte-bravo/bff-clients` | Clients HTTP tipados para serviços de domínio, DTOs |
| `@monte-bravo/bff-contracts` | Schemas compartilhados (pagination, error model, common types) |
| `@monte-bravo/bff-test-utils` | Helpers de teste, factories, mocks |

### Exemplo: Error Handler do bff-core

```ts
// packages/bff-core/src/plugins/error-handler.ts
import { FastifyPluginAsync } from 'fastify';
import fp from 'fastify-plugin';

export interface AppError {
  statusCode: number;
  code: string;
  message: string;
  details?: unknown;
}

const errorHandler: FastifyPluginAsync = async (fastify) => {
  fastify.setErrorHandler((error, request, reply) => {
    const statusCode = error.statusCode ?? 500;
    const response: AppError = {
      statusCode,
      code: error.code ?? 'INTERNAL_ERROR',
      message: statusCode >= 500 ? 'Internal server error' : error.message,
      details: statusCode < 500 ? error.validation ?? undefined : undefined,
    };

    request.log.error({ err: error, requestId: request.id }, 'Request error');
    reply.status(statusCode).send(response);
  });
};

export const errorHandlerPlugin = fp(errorHandler, {
  name: 'error-handler',
});
```

---

## Configuração de Ambiente

### Variáveis de ambiente

- `.env` — variáveis locais (nunca commitado).
- `.env.example` — template com todas as variáveis necessárias (commitado).
- `.env.test` — variáveis para testes (commitado, sem segredos reais).

### Variáveis obrigatórias

```
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# Serviços downstream
PORTFOLIO_SERVICE_URL=http://localhost:4001
TRADING_SERVICE_URL=http://localhost:4002
MARKET_DATA_SERVICE_URL=http://localhost:4003

# Auth
AUTH_JWT_SECRET=...
AUTH_JWT_ISSUER=...
```

---

## Docker

### Dockerfile padrão

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health/live || exit 1
CMD ["node", "dist/server.js"]
```

---

## Tecnologias Descartadas (e por quê)

O Kiro deve alertar se encontrar uso dessas tecnologias em código novo:

| Tecnologia | Motivo da rejeição |
|---|---|
| Express | Performance inferior, sem schema validation nativo, sem TypeScript-first |
| Hono | Menos indicado que Fastify para padrão corporativo de BFF modular (RFC-0013) |
| NestJS | Maior cerimônia e boilerplate, menos aderente ao objetivo de BFFs simples e leves (RFC-0013) |
| Next.js Route Handlers | Mistura camada de app e BFF, não cabe em SPAs sem Next.js (RFC-0013) |
| TypeBox | Zod é o padrão definido na RFC-0014 para schemas dos BFFs |
| class-validator | Padrão NestJS, não se aplica ao Fastify |
| Axios | Usar `undici` (built-in no Node.js 20+) ou fetch nativo |
| Jest | Vitest é superior em performance e integração ESM |
| CommonJS | ESM-first é o padrão |

---

## Referências

- [RFC-0013 – Framework padrão para BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777601)
- [RFC-0014 – Estrutura e Organização dos BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777613)
- [Fastify Documentation](https://fastify.dev/docs/latest/)
- [Fastify Type Providers – Zod](https://fastify.dev/docs/latest/Reference/Type-Providers/#zod)
- [tsup Documentation](https://tsup.egoist.dev/)
- [Vitest Documentation](https://vitest.dev/)

---

*Versão: 0.2.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
