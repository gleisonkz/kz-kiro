---
inclusion: fileMatch
fileMatchPattern: "**/src/modules/**,**/src/app.module.ts,**/src/main.ts,**/src/helpers/**"
---

# Arquitetura da API NestJS

> **Steering File | Archetype: api-nest | Versão: 0.1.0**
>
> Define a arquitetura interna, dual database pattern, vision scope e
> organização de módulos para a API REST do CRM MonteBravo.

---

## Papel Arquitetural

A API é a camada REST que serve o frontend e orquestra domínio:

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  Frontend / BFF │────▶│  API (NestJS REST)   │────▶│  PostgreSQL     │
│  (HTTP + JWT)   │◀────│  Swagger + Guards    │     │  (Kysely+TypeORM)│
└─────────────────┘     └──────────────────────┘     └─────────────────┘
                              │           │
                              ▼           ▼
                        ┌──────────┐  ┌──────────────┐
                        │ RabbitMQ │  │ AWS S3        │
                        │ Services │  │ (files)       │
                        └──────────┘  └──────────────┘
```

---

## Organização Interna

```
src/
├── app.module.ts              # Módulo raiz, env validation (Joi), middlewares
├── main.ts                    # Bootstrap, Swagger, filters/pipes globais
├── data-mappers/              # Mapeamento de colunas SQL (legado)
├── decorators/                # @ApiOkResponsePaginated, @ClientSideCacheRenew
├── dtos/                      # DTOs genéricos (batch responses)
├── filters/                   # AllExceptionsFilter, TypeOrmExceptionFilter
├── helpers/                   # RolesGuard, user-vision-scope, SSRM-engine, utils
├── interceptors/              # ClientSideCacheInterceptor
├── middlewares/               # Authentication, HttpLogger, Timeout
├── models/                    # Modelos de domínio
├── pipes/                     # ParseCpfCnpj, ParseSerializedObject, etc.
├── types/                     # Express augmentation, PaginationResult
└── modules/
    ├── api/                   # HUB CENTRAL — importa todos os módulos de domínio
    ├── database/
    │   ├── database.module.ts # TypeORM setup
    │   ├── type-orm.extensions.ts  # Extensões WithoutEmptyForeignEntities
    │   └── kysely/            # KyselyService + schemas + SSRM-engine
    └── {domain}/              # Módulos de domínio (~55 módulos)
        ├── {domain}.module.ts
        ├── {domain}.controller.ts
        ├── {domain}.service.ts
        ├── {domain}-queries.service.ts   # queries Kysely complexas (opcional)
        ├── {domain}-permission.service.ts # autorização (opcional)
        ├── entities/          # *.view.entity.ts (TypeORM views)
        ├── dtos/incoming/     # Request DTOs
        ├── dtos/outgoing/     # Response DTOs
        ├── queries/           # Query builders Kysely reutilizáveis
        └── *.spec.ts
```

**Central API Hub:** `src/modules/api/` importa todos os módulos de domínio e os expõe através do `ApiController`.

---

## Dual Database Pattern

### Kysely (preferido para novo código)

Type-safe query builder com schemas auto-gerados.

```ts
@Injectable()
export class KyselyService extends Kysely<Database> {
  constructor(config: ConfigService) {
    super({
      dialect: new PostgresDialect({ pool: new Pool({ connectionString: ... }) }),
      plugins: [new CamelCasePlugin()],
    })
  }
}
```

- Schemas em `schemas/public/` (main) e `schemas/dw/` (data warehouse)
- `Database` type = `PublicSchema & WithSchemaPrefix<DwSchema, 'dw'>`
- Gerar tipos: `npm run db:generate` (após mudanças no schema do DB)

### TypeORM (legado — apenas view entities)

**REGRA CRÍTICA:** ESLint proíbe métodos TypeORM nativos. Use sempre as variantes customizadas:

```ts
// ❌ ERRADO — ESLint bloqueia
const results = await repository.find({ where: { ... } })

// ✅ CORRETO — usa extensões customizadas
const results = await repository.findWithoutEmptyForeignEntities({ where: { ... } })
```

Métodos disponíveis (em `type-orm.extensions.ts`):
`findWithoutEmptyForeignEntities`, `findOneWithoutEmptyForeignEntities`, `getManyWithoutEmptyForeignEntities`, `getManyAndCountWithoutEmptyForeignEntities`, etc.

Substituem objetos de entidade estrangeira vazios `{}` por `null`.

---

## Vision Scope (Row-Level Security)

Sistema de controle de acesso que determina quais dados um usuário pode ver, baseado em role.

### Três escopos

| Escopo | Quem | O que vê |
|--------|------|----------|
| **GlobalVision** | Admins | Todos os dados |
| **MirroredVision** | Managers | Próprios dados + advisors espelhados |
| **OwnVision** | Advisors individuais | Apenas próprios dados |

### Aplicação

```ts
// Determinar o escopo do usuário
const userVisionScope = getVisionScope(req.roles, Entity.Lead, {
  username: req.username,
  mirroredAdvisors,
})

// Aplicar filtro na query Kysely
query.where((eb) => buildViewScopeFilter(eb, FOREIGN_KEYS, userVisionScope))
```

**SEMPRE aplique vision scope filters** em queries que retornam dados específicos do usuário. Esquecer isso é uma falha de segurança.

Para checar permissão em endpoints específicos:

```ts
await this.customersPermissionService.checkIfAccountIsInUserVisionScope(
  { username, roles }, accountId, Entity.Account, FOREIGN_KEYS,
)
```

---

## SSRM Engine (Server-Side Row Model)

Engine customizado compatível com AG Grid para filtro/ordenação/paginação de queries Kysely:

- `SSRM-filter-engine.ts` — converte filterModel para WHERE
- `SSRM-sort-engine.ts` — converte sortModel para ORDER BY
- `pagination.ts` — LIMIT/OFFSET (startRow/endRow)
- `query-builder.ts` — vision scope filters

Frontend envia `filterModel` e `sortModel` como JSON serializado (via `ParseSerializedObjectPipe`).

---

## Anatomia de um Endpoint

```ts
@ApiTags('Leads')
@ApiBearerAuth()
@Controller('leads')
export class LeadsController {
  @ApiOkResponsePaginated(GetLeadsTableDto)
  @ApiOperation({ summary: 'Retorna leads. @Roles Autorizadas: Assessor | Prospector' })
  @Roles(Role.Assessor, Role.Prospector)
  @Get('table')
  async getLeads(
    @Req() req: Express.Request,
    @Query('filterModel', ParseSerializedObjectPipe) filterModel: FilterModel,
  ): Promise<PaginationResult<GetLeadsTableDto>> {
    const userVisionScope = getVisionScope(req.roles, Entity.Lead, { ... })
    return this.leadsService.getLeadsTable(userVisionScope, ...)
  }
}
```

### Responsabilidades por camada

| Camada | Responsabilidade |
|--------|------------------|
| `controller` | Endpoint, Swagger, extrai vision scope, checa permissão |
| `service` | Lógica de negócio, orquestração |
| `{domain}-queries.service` | Queries Kysely complexas |
| `queries/*.query.ts` | Query builders reutilizáveis |
| `entities/*.view.entity.ts` | View entities TypeORM (read-only) |
| `dtos/incoming` | Request DTOs (class-validator) |
| `dtos/outgoing` | Response DTOs (Swagger) |

---

## Autenticação e Autorização

### Autenticação (AuthenticationMiddleware)

- JWT do AWS Cognito decodificado no middleware
- `cognito:username` → `req.username`; `cognito:groups` → `req.roles`
- Armazenado em `ClsService` e no request object
- Aplicado globalmente exceto `/health` e `/swagger`

### Autorização (RolesGuard global)

- `@AllowedRoles(Role.X)` ou `@Roles(Role.X)` nos endpoints
- `RolesGuard` como `APP_GUARD` global
- Roles: Assessor, Investor, Operador, LifePlanner, Prospector, Manager, SalesManager, GlobalVision, etc.

---

## Bootstrap (main.ts)

- Tracing opcional (`DD_ENABLE_TRACE`)
- Winston logger (prettyPrint local / JSON prod)
- Swagger auto-gerado + export YAML
- Helmet, JSON body limit, CLS middleware
- Global filters: `AllExceptionsFilter` + `TypeOrmExceptionFilter`
- Global pipes: `ValidationPipe({ transform: true, whitelist: true })`
- Global interceptor: `TracingInterceptor`
- Global guard: `RolesGuard`
- Env validation com Joi no `ConfigModule`

---

## Circular Dependencies

Use `forwardRef(() => ModuleName)` quando houver dependência circular entre módulos (comum entre accounts/leads/tasks).

---

*Versão: 0.1.0 | Criado em: 2026-08*
