---
inclusion: fileMatch
fileMatchPattern: "**/src/**/*.ts"
---

# Convenções de Nomenclatura — Service NestJS

> **Steering File | Archetype: service-nest | Versão: 0.1.0**

---

## Arquivos

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Módulo | `{domain}.module.ts` | `tasks.module.ts` |
| Controller | `{domain}.controller.ts` | `tasks.controller.ts` |
| Service | `{domain}.service.ts` | `tasks.service.ts` |
| Guard | `{domain}-permissions.guard.ts` | `task-permissions.guard.ts` |
| Permission service | `{domain}-permissions.service.ts` | `task-permissions.service.ts` |
| DTO (entrada) | `types/dtos/incoming/{action}-{entity}.dto.ts` | `create-task.dto.ts` |
| DTO (saída) | `types/dtos/outgoing/{action}-{entity}.dto.ts` | `get-task-details.dto.ts` |
| Entidade compartilhada | `types/shared/{entity}-entity.ts` | `task-entity.ts` |
| Config tipada | `{domain}.config.ts` | `tasks.config.ts` |
| Teste | `{domain}.spec.ts` | `activity-record.spec.ts` |
| Batch processor | `batch-processing/{action}-{entity}.processor.ts` | `create-task.processor.ts` |
| Batch service | `batch-processing/{domain}-batch.service.ts` | `tasks-batch.service.ts` |
| Schema Kysely (gerado) | `schemas/public/{PascalCase}.ts` | `Tasks.ts` |

---

## Classes e Interfaces

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Module | `{Domain}Module` | `TasksModule` |
| Controller | `{Domain}Controller` | `TasksController` |
| Service | `{Domain}Service` | `TasksService` |
| Guard | `{Domain}PermissionsGuard` | `TaskPermissionsGuard` |
| DTO Schema (Zod) | `{Action}{Entity}DtoSchema` | `CreateTaskDtoSchema` |
| DTO Class | `{Action}{Entity}Dto` | `CreateTaskDto` |
| Entity Schema (Zod) | `{Entity}EntitySchema` | `TaskEntitySchema` |
| Entity Type | `{Entity}Entity` | `TaskEntity` |
| Processor | `{Action}{Entity}Processor` | `CreateTaskProcessor` |
| Interceptor | `{Purpose}Interceptor` | `UserToClsInterceptor` |
| Config type | `{Domain}Config` | `TasksConfig` |

---

## Variáveis e Constantes

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Variável local | camelCase | `taskUpdate`, `userVisionScope` |
| Constante | UPPER_SNAKE_CASE | `CREATE_TASK_PROCESSOR_NAME` |
| Enum value | PascalCase | `TasksCategoryEnum.WelcomeCall` |
| RabbitMQ pattern | kebab-case | `'create-task'`, `'update-task'` |
| Exchange name | kebab-case | `'activity-service-events'` |
| Queue name | kebab-case | `'activity-service'` |
| Env var | UPPER_SNAKE_CASE | `RABBITMQ_URL`, `DATABASE_URL` |

---

## Message Patterns (RabbitMQ)

Formato: `{verbo}-{entidade}` (kebab-case)

```
create-task
update-task
delete-task
get-activity-records-by-account
add-permissions-to-tasks
```

## Event Patterns (PubSub)

Formato: `{domínio}.{contexto}.{ação}` (dot-separated)

```
tasks.welcome_call.created
tasks.operador_journey.schedule_first_meeting.closed.successfully
appointment_updated
appointment_deleted
```

---

## Pastas

- Sempre **kebab-case**: `batch-processing/`, `clients-wrapper/`, `http-wrapper/`
- Módulos de domínio no plural quando representam coleções: `tasks/`, `appointments/`
- Módulos utilitários no singular: `health/`, `auth/`

---

*Versão: 0.1.0 | Criado em: 2026-08*
