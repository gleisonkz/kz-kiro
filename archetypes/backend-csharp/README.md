# Archetype: Backend C#

> **Archetype | backend-csharp | Versão: 0.2.0**
>
> Configurações Kiro para projetos de serviços de domínio (backend) com .NET/C#.
>
> Baseado em: RFC-001 (Padrões arquiteturais), RFC-002 (Steering File para backend), RFC-003 (Outbox/Inbox), ADR-001 (Comunicação entre serviços), Guia de Padrões de Nomeação

---

## Propósito

Os serviços de domínio são responsáveis por encapsular **regras de negócio**, persistência de dados e operações de domínio. Eles são consumidos pelos BFFs e por outros serviços internos, expondo APIs REST e comunicando-se via mensageria (coreografia).

Cada serviço de domínio é **independente**, possui seu próprio banco de dados PostgreSQL (Database per Service) e é deployado de forma autônoma — preferencialmente como AWS Lambda.

---

## Estrutura

```
archetypes/backend-csharp/
├── README.md
├── agents/
│   └── README.md
├── hooks/
│   ├── README.md
│   ├── kiro-doctor.kiro.hook
│   ├── build-after-agent.kiro.hook
│   ├── run-tests-after-task.kiro.hook
│   ├── review-domain-boundaries.kiro.hook
│   └── review-endpoint-quality.kiro.hook
├── mcp/
│   └── mcp.json
├── skills/
│   ├── README.md
│   ├── generate-module.md
│   ├── generate-endpoint.md
│   └── generate-repository.md
└── steering/
    ├── README.md
    ├── architecture.md
    ├── ci-cd.md
    ├── naming-conventions.md
    └── stack-and-tooling.md
```

---

## Stack

- **Runtime:** .NET 8+ LTS
- **Linguagem:** C# 12 (nullable reference types enabled)
- **Framework Web:** ASP.NET Core Minimal APIs
- **ORM:** Entity Framework Core 8+ + PostgreSQL
- **Validação:** FluentValidation
- **CQRS:** MediatR
- **Messaging/Outbox:** Wolverine (RabbitMQ/Kafka)
- **Testes:** xUnit + Moq + FluentAssertions
- **Documentação API:** Swagger/OpenAPI (Swashbuckle)
- **Observabilidade:** Serilog + AWS CloudWatch + AWS X-Ray
- **Deploy:** AWS Lambda (ARM64) + API Gateway
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Containerização:** Docker (quando ECS Fargate)

---

## Como usar

Para aplicar este archetype em um novo projeto backend C#:

```bash
./scripts/bootstrap.sh --project-type backend-csharp --target <caminho-do-projeto>
```

O bootstrap aplica automaticamente o baseline global, o archetype e os powers necessários.

---

## Princípios Arquiteturais

1. **Serviço por bounded context** — cada serviço encapsula um domínio de negócio coeso.
2. **Database per Service** — PostgreSQL próprio, sem compartilhamento.
3. **Clean Architecture / Vertical Sliced / Hexagonal** — conforme complexidade (RFC-001).
4. **Domain-Driven Design** — entidades ricas, value objects, aggregates e eventos.
5. **CQRS** — separação entre Commands (escrita) e Queries (leitura).
6. **Mensageria coreografada** (ADR-001) — comunicação assíncrona via broker.
7. **Outbox/Inbox** (RFC-003) — transações financeiras confiáveis e idempotentes.
8. **Serverless-first** (RFC-002) — Lambda como deploy preferido, EC2 evitado.
9. **Contratos explícitos** — documentação OpenAPI gerada automaticamente.
10. **Observabilidade** — logs estruturados, tracing distribuído, métricas.

---

## Referências

- [ADR-001 – Padrão arquitetural de comunicação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517)
- [RFC-001 – Padrões arquiteturais de projetos](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/181731331)
- [RFC-002 – Padrão Steering File para backend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/192806913)
- [RFC-003 – Outbox/Inbox para transações financeiras](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/227082241)
- [Guia de Padrões de Nomeação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/122191873)
- [Wolverine Framework](https://wolverinefx.net/)

---

*Versão: 0.2.0 | Última revisão: 2026-05*
