# Archetype: Service NestJS

> **Archetype | service-nest | Versão: 0.1.0**
>
> Configurações Kiro para microserviços de domínio com NestJS, Kysely, RabbitMQ e BullMQ.

---

## Propósito

O Service é um **microserviço de domínio** que encapsula regras de negócio específicas de um bounded context. Comunica-se com outros serviços exclusivamente via **mensageria** (RabbitMQ) e **filas de processamento** (BullMQ/Redis). Não expõe endpoints HTTP para o frontend — apenas para health checks e comunicação entre serviços.

---

## Estrutura

```
archetypes/service-nest/
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
│   ├── generate-message-handler.md
│   └── generate-batch-processor.md
└── steering/
    ├── README.md
    ├── architecture.md
    ├── stack-and-tooling.md
    ├── naming-conventions.md
    └── ci-cd.md
```

---

## Stack

- **Runtime:** Node.js 20 LTS
- **Framework:** NestJS 10.x (microservices, modules, DI)
- **Linguagem:** TypeScript 5.x (strict mode)
- **Banco de dados:** PostgreSQL via Kysely (type-safe query builder)
- **Mensageria:** RabbitMQ (PubSub + Direct queues) via @nestjs/microservices
- **Filas:** BullMQ + Redis (batch processing, jobs com retry)
- **Validação:** Zod + nestjs-zod (DTOs tipados)
- **Testes:** Jest + ts-jest
- **Linting:** ESLint + Prettier
- **Pacotes:** npm

---

## Princípios Arquiteturais

1. **Microserviço por bounded context** — cada serviço é dono de suas entidades e regras de negócio.
2. **Comunicação assíncrona** — RabbitMQ para eventos (PubSub) e commands (Direct queues).
3. **Zero exposição HTTP ao frontend** — apenas health checks e comunicação machine-to-machine.
4. **Validação com Zod** — DTOs tipados, validation pipe global, schemas gerados para DB.
5. **Banco de dados próprio** — cada serviço tem seu schema/database isolado.
6. **Idempotência** — handlers devem ser idempotentes para suportar retries.
7. **Observabilidade** — tracing (Datadog), logging estruturado (Winston/Pino), métricas.
8. **Feature flags** — via variáveis de ambiente para habilitar/desabilitar features.

---

## Como usar

Para aplicar este archetype em um novo projeto de microserviço:

```bash
./scripts/bootstrap.sh --project-type service-nest --target <caminho-do-projeto>
```

---

*Versão: 0.1.0 | Criado em: 2026-08*
