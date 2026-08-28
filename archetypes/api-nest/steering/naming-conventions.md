---
inclusion: fileMatch
fileMatchPattern: "**/src/**/*.ts"
---

# Convenções de Nomenclatura — API NestJS

> **Steering File | Archetype: api-nest | Versão: 0.1.0**

---

## Arquivos

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Módulo | `{domain}.module.ts` | `leads.module.ts` |
| Controller | `{domain}.controller.ts` | `leads.controller.ts` |
| Service | `{domain}.service.ts` | `leads.service.ts` |
| Query service | `{domain}-queries.service.ts` | `leads-queries.service.ts` |
| Permission service | `{domain}-permission.service.ts` | `customers-permission.service.ts` |
| View entity (TypeORM) | `entities/{nome}.view.entity.ts` | `lead-details.view.entity.ts` |
| Query builder (Kysely) | `queries/{nome}.query.ts` | `leads-table.query.ts` |
| DTO (entrada) | `dtos/incoming/{action}-{entity}.dto.ts` | `create-lead.dto.ts` |
| DTO (saída) | `dtos/outgoing/{action}-{entity}.dto.ts` | `get-lead-details.dto.ts` |
| Schema Kysely (gerado) | `schemas/{public,dw}/{PascalCase}.ts` | `Leads.ts` |
| Teste | `{domain}.service.spec.ts` | `leads.service.spec.ts` |

---

## Classes e Interfaces

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Module | `{Domain}Module` | `LeadsModule` |
| Controller | `{Domain}Controller` | `LeadsController` |
| Service | `{Domain}Service` | `LeadsService` |
| Query service | `{Domain}QueriesService` | `LeadsQueriesService` |
| View Entity | `{Entity}ViewEntity` | `LeadDetailsViewEntity` |
| DTO (entrada) | `{Action}{Entity}Dto` | `CreateLeadDto` |
| DTO (saída) | `Get{Entity}Dto` | `GetLeadDetailsDto` |
| Guard | `{Purpose}Guard` | `RolesGuard` |
| Pipe | `Parse{Type}Pipe` | `ParseCpfCnpjPipe` |
| Interceptor | `{Purpose}Interceptor` | `ClientSideCacheInterceptor` |
| Filter | `{Scope}ExceptionsFilter` | `AllExceptionsFilter` |

---

## View Entities (TypeORM)

- Views no DB: `snake_case`
- TypeScript: `PascalCase` + sufixo `.view.entity.ts`
- Exemplo: `AccountsTableViewEntity`, `LeadDetailsViewEntity`
- Use `@NullableForeignEntity()` para marcar objetos aninhados que devem virar `null` quando vazios

---

## Rotas (REST)

- Prefixo do controller: recurso no plural, kebab-case
- Exemplo: `@Controller('leads')`, `@Controller('account-transfers')`
- Sub-rotas: `@Get('table')`, `@Get(':uid')`, `@Get('table/export')`

---

## Swagger

- `@ApiTags('{Domínio}')` — no controller
- `@ApiBearerAuth()` — no controller (endpoints autenticados)
- `@ApiOperation({ summary: '... @Roles Autorizadas: X | Y' })` — documenta roles
- `@ApiOkResponsePaginated(Dto)` — para respostas paginadas

---

## Variáveis, Constantes e Enums

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Variável local | camelCase | `userVisionScope`, `filterModel` |
| Constante | UPPER_SNAKE_CASE | `LEAD_SQL_FOREIGN_KEYS`, `MAX_PAGE_SIZE` |
| Enum | PascalCase (nome e valores) | `Role.Assessor`, `Entity.Lead` |
| Env var | UPPER_SNAKE_CASE | `CORE_DATABASE_URL`, `RABBITMQ_URL` |

---

## Pastas

- Sempre **kebab-case**: `data-mappers/`, `account-transfers/`, `fee-based/`
- Módulos de domínio no plural: `leads/`, `accounts/`, `tasks/`

---

*Versão: 0.1.0 | Criado em: 2026-08*
