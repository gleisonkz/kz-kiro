---
inclusion: fileMatch
fileMatchPattern: "**/package.json,**/tsconfig.json,**/jest.config.*,**/.eslintrc.*,**/.prettierrc*"
---

# Stack e Tooling — Service NestJS

> **Steering File | Archetype: service-nest | Versão: 0.1.0**

---

## Runtime e Linguagem

| Item | Versão |
|------|--------|
| Node.js | 20.16.0 (via Volta) |
| npm | 10.8.1 |
| TypeScript | 5.x (strict mode) |

---

## Framework e Dependências Principais

| Dependência | Uso |
|-------------|-----|
| `@nestjs/common`, `core`, `microservices` | Framework base |
| `@nestjs/config` | Configuração tipada com Joi/Zod |
| `@nestjs/schedule` | Cron jobs |
| `@nestjs/bullmq` | Filas de processamento |
| `@nestjs/axios` | HTTP client para comunicação entre serviços |
| `kysely` | Query builder type-safe para PostgreSQL |
| `pg` | Driver PostgreSQL |
| `nestjs-zod` | Integração Zod com NestJS (validation pipe, serializer) |
| `zod` | Validação e tipagem de DTOs |
| `nestjs-cls` | Continuation-local storage (request context) |
| `bullmq` + `ioredis` | Job queues com Redis |
| `amqp-connection-manager` + `amqplib` | RabbitMQ |
| `@montebravo.tech/mb-nest-core` | Lib interna (PubSubServerRMQ, MbLogger, RedisTryLock) |
| `@montebravo.tech/mb-telemetry` | Tracing e logging (Datadog) |
| `winston` + `nest-winston` | Logger estruturado |
| `date-fns` | Manipulação de datas |
| `lodash` | Utilitários |
| `serialize-error` | Serialização de erros para logging |

---

## Banco de Dados (Kysely)

### Setup

```ts
@Injectable()
export class KyselyService extends Kysely<Database> {
  constructor(config: ConfigService) {
    super({
      dialect: new PostgresDialect({
        pool: new Pool({ connectionString: config.get('DATABASE_URL') })
      }),
      plugins: [new CamelCasePlugin()],
    })
  }
}
```

### Geração de Tipos

```bash
npm run db:generate       # Introspect DB → gera schemas Kysely + Zod
npm run postdb:generate   # Prettier nos schemas gerados
```

Usa `@montebravo.tech/mb-kysely` + Kanel + kanel-kysely + kanel-zod.

Schema gerado inclui:
- Table interface (ColumnType)
- Selectable / Insertable / Updateable types
- Zod schemas (parsers + initializers + mutators)

---

## Testes

| Item | Config |
|------|--------|
| Runner | Jest 29 |
| Transform | ts-jest |
| Ambiente | node |
| Padrão | `*.spec.ts` co-locado com source |
| Module mapper | `src/` → `<rootDir>/src/` |

### Convenções de teste

- Testes unitários puros de lógica de negócio (sem mocks de DB)
- Padrão AAA (Arrange, Act, Assert)
- Property-based testing com `fast-check` quando aplicável

---

## Linting e Formatação

### ESLint

```js
rules: {
  '@typescript-eslint/no-floating-promises': 'error',
  '@typescript-eslint/no-explicit-any': 'off',
  '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
  'max-len': ['warn', { code: 120 }],
}
```

### Prettier

```json
{
  "printWidth": 120,
  "tabWidth": 4,
  "semi": false,
  "singleQuote": true,
  "trailingComma": "all",
  "endOfLine": "lf"
}
```

---

## Docker

```dockerfile
FROM node:20.16.0-alpine AS builder
WORKDIR /app
COPY . .
RUN npm install
ENV NODE_ENV production
RUN npm run build

FROM node:20.16.0-alpine AS final
ENV NODE_ENV production
WORKDIR /app
COPY --from=builder ./app/dist ./dist
COPY package-lock.json package.json .npmrc us-east-1-bundle.pem ./
RUN npm ci --omit=dev
CMD ["node", "dist/main"]
```

---

## Docker Compose (desenvolvimento local)

```yaml
services:
  postgres: debezium/postgres:13
  rabbitmq: rabbitmq:3-management
  redis: redis
  debezium: debezium/server:2.4 (CDC)
```

---

## Comandos

| Comando | Descrição |
|---------|-----------|
| `npm run start:dev` | Watch mode |
| `npm run start:debug` | Debug (porta 9229) |
| `npm run build` | Build produção |
| `npm test` | Testes unitários |
| `npm run test:cov` | Testes com cobertura |
| `npm run lint` | ESLint com fix |
| `npm run db:generate` | Gerar tipos Kysely |

---

*Versão: 0.1.0 | Criado em: 2026-08*
