---
inclusion: fileMatch
fileMatchPattern: "**/package.json,**/tsconfig.json,**/jest.config.*,**/.eslintrc.*,**/.prettierrc*"
---

# Stack e Tooling — API NestJS

> **Steering File | Archetype: api-nest | Versão: 0.1.0**

---

## Runtime e Linguagem

| Item | Versão |
|------|--------|
| Node.js | 22.16.0 (via Volta) |
| TypeScript | 4.9.5 (strict mode) |

---

## Framework e Dependências Principais

| Dependência | Uso |
|-------------|-----|
| `@nestjs/common`, `core`, `microservices`, `platform-express` | Framework base |
| `@nestjs/config` | Configuração com validação Joi |
| `@nestjs/swagger` | Documentação automática da API |
| `@nestjs/typeorm` + `typeorm` | ORM legado (view entities) |
| `kysely` | Query builder type-safe (código novo) |
| `knex` + `nestjs-knex` | Queries raw legadas |
| `pg` | Driver PostgreSQL |
| `class-validator` + `class-transformer` | Validação de DTOs |
| `@aws-sdk/client-s3`, `lib-storage`, `s3-request-presigner` | Storage S3 |
| `nestjs-cls` | Continuation-local storage |
| `amqp-connection-manager` + `amqplib` | RabbitMQ |
| `@montebravo.tech/mb-kysely` | Introspecção Kysely |
| `@montebravo.tech/mb-rmq-transport` | Transport RabbitMQ |
| `@montebravo.tech/mb-telemetry` | Tracing e logging |
| `helmet` | Segurança HTTP headers |
| `jwt-decode` | Decodificação de JWT Cognito |
| `winston` + `nest-winston` | Logger estruturado |
| `date-fns`, `moment-timezone` | Datas |
| `exceljs` | Geração de planilhas |

---

## Banco de Dados — Dual Pattern

### Kysely (novo código)

```bash
npm run db:generate       # Introspect DB → schemas Kysely + Zod
npm run postdb:generate   # Prettier nos schemas gerados
```

- Schemas em `src/modules/database/kysely/schemas/{public,dw}/`
- `CamelCasePlugin` ativo (snake_case → camelCase)

### TypeORM (legado)

- Apenas view entities read-only (`*.view.entity.ts`)
- Extensões customizadas em `type-orm.extensions.ts`
- Config em `database.module.ts` com SSL para produção

---

## Testes

| Item | Config |
|------|--------|
| Runner | Jest 28 |
| Transform | ts-jest |
| Ambiente | node |
| Padrão | `*.spec.ts` co-locado; `*.e2e-spec.ts` para E2E |
| E2E config | `test/jest-e2e.json` |

### Padrão de teste

```ts
const module = await Test.createTestingModule({
  providers: [
    LeadsService,
    { provide: getRepositoryToken(LeadEntity), useValue: mockRepository },
    { provide: KyselyService, useValue: mockKysely },
    { provide: getKnexConnectionToken('core'), useValue: mock },
    { provide: 'MICROSERVICE_CLIENT', useValue: mock },
  ],
}).compile()
```

- Mock todas as dependências com `{ provide, useValue }`
- `getRepositoryToken()` para entidades TypeORM
- `getKnexConnectionToken('core')` para Knex
- Property-based testing com `fast-check`

---

## Linting e Formatação

### ESLint

```js
plugins: ['@typescript-eslint/eslint-plugin', 'import'],
rules: {
  '@typescript-eslint/no-explicit-any': 'off',
  'max-len': ['warn', { code: 120 }],
  '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
  // Proíbe métodos TypeORM nativos:
  'no-restricted-properties': [2,
    { property: 'find', message: 'Use findWithoutEmptyForeignEntities instead.' },
    { property: 'findOne', message: 'Use findOneWithoutEmptyForeignEntities instead.' },
    { property: 'getMany', message: 'Use getManyWithoutEmptyForeignEntities instead.' },
    // ...
  ],
}
```

### Prettier

```json
{
  "printWidth": 120,
  "tabWidth": 4,
  "semi": false,
  "singleQuote": true,
  "trailingComma": "all"
}
```

---

## Docker

```dockerfile
FROM node:22.16.0-bookworm-slim AS builder
WORKDIR /app
COPY . .
RUN npm install
ENV NODE_ENV=production
RUN npm run build

FROM node:22.16.0-bookworm-slim AS final
ENV NODE_ENV=production
WORKDIR /app
COPY --from=builder ./app/dist ./dist
COPY package-lock.json package.json .npmrc us-east-1-bundle.pem ./
RUN npm ci --omit=dev
CMD ["node", "dist/main"]
```

---

## Comandos

| Comando | Descrição |
|---------|-----------|
| `npm run start:dev` | Watch mode |
| `npm run start:debug` | Debug (porta 9229) |
| `npm run build` | Build produção |
| `npm test` | Testes unitários |
| `npm run test:cov` | Cobertura |
| `npm run test:e2e` | Testes E2E |
| `npm run lint` | ESLint |
| `npm run lint:dev` | ESLint com fix |
| `npm run db:generate` | Gerar tipos Kysely |

---

*Versão: 0.1.0 | Criado em: 2026-08*
