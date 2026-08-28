# Archetype: API NestJS

> **Archetype | api-nest | Versão: 0.1.0**
>
> Configurações Kiro para APIs REST com NestJS, TypeORM (legado) + Kysely, Swagger e controle de acesso por vision scope.

---

## Propósito

A API é a camada **REST exposta ao frontend** (e a BFFs). Concentra os módulos de domínio do CRM, expõe endpoints documentados com Swagger, aplica autenticação via JWT Cognito e controle de acesso row-level via **Vision Scope**. Comunica-se com microserviços de domínio via RabbitMQ.

---

## Estrutura

```
archetypes/api-nest/
├── README.md
├── VERSION
├── CHANGELOG.md
├── agents/
│   └── README.md
├── hooks/
│   ├── README.md
│   ├── kiro-doctor.kiro.hook
│   ├── build-after-agent.kiro.hook
│   └── run-tests-after-task.kiro.hook
├── mcp/
│   └── mcp.json
├── skills/
│   ├── README.md
│   ├── generate-module.md
│   ├── generate-endpoint.md
│   └── generate-kysely-query.md
└── steering/
    ├── README.md
    ├── architecture.md
    ├── stack-and-tooling.md
    ├── naming-conventions.md
    └── ci-cd.md
```

---

## Stack

- **Runtime:** Node.js 22 LTS
- **Framework:** NestJS 11.x (modules, DI, guards, interceptors, pipes)
- **Linguagem:** TypeScript 4.9.x (strict mode)
- **Banco de dados:** PostgreSQL — dual pattern:
  - **Kysely** (preferido para novo código) — type-safe query builder
  - **TypeORM** (legado) — apenas para view entities read-only
- **Documentação:** Swagger (@nestjs/swagger)
- **Validação:** class-validator + class-transformer
- **Mensageria:** RabbitMQ via @nestjs/microservices
- **Storage:** AWS S3
- **Testes:** Jest + ts-jest
- **Linting:** ESLint + Prettier
- **Pacotes:** npm

---

## Princípios Arquiteturais

1. **Feature-based modules** — cada domínio é um módulo NestJS auto-contido.
2. **Dual database pattern** — Kysely para novo código, TypeORM apenas para views legadas.
3. **Vision Scope (row-level security)** — controle de acesso por role: GlobalVision, MirroredVision, OwnVision.
4. **Contratos explícitos** — DTOs com class-validator, Swagger em todos os endpoints.
5. **Central API hub** — módulo `api/` agrega e expõe todos os módulos de domínio.
6. **SSRM Engine** — engine customizado para filtro/ordenação/paginação server-side (AG Grid).
7. **Autenticação Cognito** — JWT decodificado em middleware, roles via `cognito:groups`.
8. **Autorização declarativa** — `@AllowedRoles()` + `RolesGuard` global.

---

## Dual Database Pattern

| Padrão | Uso | Regra |
|--------|-----|-------|
| **Kysely** | Todo código novo | Type-safe, schemas auto-gerados via `db:generate` |
| **TypeORM** | Apenas view entities existentes | ESLint proíbe métodos nativos; usar variantes `WithoutEmptyForeignEntities` |

---

## Como usar

```bash
./scripts/bootstrap.sh --project-type api-nest --target <caminho-do-projeto>
```

---

*Versão: 0.1.0 | Criado em: 2026-08*
