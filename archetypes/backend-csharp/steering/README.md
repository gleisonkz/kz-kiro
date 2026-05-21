# Steering — Archetype Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos de serviços de domínio com .NET/C#.
> Ele complementa o baseline global com diretrizes específicas para backends C#.
>
> Baseado em: RFC-001 (Padrões arquiteturais), RFC-002 (Steering File para backend), RFC-003 (Outbox/Inbox), ADR-001 (Comunicação), Guia de Padrões de Nomeação

---

## Propósito deste Arquivo

Este steering file define as diretrizes específicas para serviços de domínio construídos com .NET/C# na MonteBravo. O Kiro deve usar este contexto ao:

- Sugerir estrutura de pastas e camadas do serviço
- Revisar código C#/.NET
- Propor abordagens para modelagem de domínio, persistência e APIs
- Gerar scaffolding de endpoints, services, repositories e entidades

---

## O que é um Serviço de Domínio

O serviço de domínio é a camada que encapsula **regras de negócio**, persistência e operações de um bounded context específico. Ele é consumido pelos BFFs e por outros serviços internos.

### Responsabilidades do Serviço de Domínio

- **Regras de negócio** — validações, cálculos e decisões de domínio.
- **Persistência** — gerenciamento do ciclo de vida de entidades e aggregates.
- **Exposição de API** — endpoints REST bem definidos com contratos OpenAPI.
- **Eventos de domínio** — publicação de eventos para comunicação assíncrona.
- **Observabilidade** — logs, métricas e tracing de todas as operações.

### O que o Serviço de Domínio NÃO deve fazer

- Conter lógica de **apresentação** ou formatação para frontend — isso é responsabilidade do BFF.
- Acessar banco de dados de **outro serviço** — cada serviço possui seu próprio banco.
- Implementar **orquestração de múltiplos serviços** — isso é responsabilidade do BFF ou de um orquestrador.
- Expor dados em formato específico para um **canal** (web, mobile) — a API é genérica.

---

## Stack Padrão (RFC-002)

| Tecnologia | Versão Mínima | Obrigatório | Observação |
|---|---|---|---|
| .NET | 8 LTS | Sim | Runtime e SDK |
| C# | 12 | Sim | Nullable reference types enabled |
| ASP.NET Core | 8 | Sim | Framework web (Minimal APIs) |
| Entity Framework Core | 8 | Sim | ORM e migrations |
| PostgreSQL | latest | Sim | Banco de dados (Database per Service) |
| FluentValidation | latest | Sim | Validação de requests |
| MediatR | latest | Sim | Mediator pattern (CQRS) |
| Wolverine | latest | Sim | Outbox/Inbox, messaging (RFC-003) |
| Serilog | latest | Sim | Logging estruturado |
| AWS CloudWatch | - | Sim | Destino de logs |
| AWS X-Ray | - | Sim | Distributed tracing |
| Swashbuckle | latest | Sim | Documentação OpenAPI/Swagger |
| Polly | latest | Sim | Resiliência (retry, circuit breaker) |
| xUnit | latest | Sim | Framework de testes |
| Moq | latest | Sim | Mocking (RFC-002) |
| FluentAssertions | latest | Recomendado | Assertions expressivas |
| Testcontainers | latest | Recomendado | Testes de integração com containers |
| Docker | latest | Sim | Containerização |
| Terraform | >= 1.6 | Sim | Infrastructure as Code (RFC-002) |

---

## Estrutura de Pastas Padrão (Clean Architecture)

```
src/
├── {ServiceName}.Api/                    # Camada de apresentação (host)
│   ├── Program.cs                        # Entry point e configuração
│   ├── Endpoints/                        # Minimal API endpoints agrupados por domínio
│   │   └── {Domain}/
│   │       ├── {Domain}Endpoints.cs      # Registro dos endpoints
│   │       ├── Get{Resource}Endpoint.cs
│   │       └── Create{Resource}Endpoint.cs
│   ├── Middleware/                        # Middlewares customizados
│   ├── Filters/                          # Exception filters
│   └── appsettings.json
│
├── {ServiceName}.Application/            # Camada de aplicação (use cases)
│   ├── {Domain}/
│   │   ├── Commands/
│   │   │   ├── Create{Resource}/
│   │   │   │   ├── Create{Resource}Command.cs
│   │   │   │   ├── Create{Resource}CommandHandler.cs
│   │   │   │   └── Create{Resource}CommandValidator.cs
│   │   │   └── Update{Resource}/
│   │   └── Queries/
│   │       └── Get{Resource}/
│   │           ├── Get{Resource}Query.cs
│   │           ├── Get{Resource}QueryHandler.cs
│   │           └── Get{Resource}Response.cs
│   ├── Common/
│   │   ├── Behaviors/                    # Pipeline behaviors (validation, logging)
│   │   ├── Interfaces/                   # Abstrações de infraestrutura
│   │   └── Mappings/                     # Profiles de mapeamento
│   └── DependencyInjection.cs
│
├── {ServiceName}.Domain/                 # Camada de domínio (entidades, regras)
│   ├── {Domain}/
│   │   ├── Entities/
│   │   │   └── {Entity}.cs
│   │   ├── ValueObjects/
│   │   │   └── {ValueObject}.cs
│   │   ├── Events/
│   │   │   └── {Domain}{Action}Event.cs
│   │   ├── Enums/
│   │   └── Exceptions/
│   │       └── {Domain}Exception.cs
│   ├── Common/
│   │   ├── BaseEntity.cs
│   │   ├── IAuditableEntity.cs
│   │   └── IDomainEvent.cs
│   └── Interfaces/
│       └── I{Domain}Repository.cs
│
└── {ServiceName}.Infrastructure/         # Camada de infraestrutura
    ├── Persistence/
    │   ├── {ServiceName}DbContext.cs
    │   ├── Configurations/               # EF Core entity configurations (snake_case mapping)
    │   │   └── {Entity}Configuration.cs
    │   ├── Migrations/
    │   └── Repositories/
    │       └── {Domain}Repository.cs
    ├── Messaging/                         # Wolverine handlers, outbox/inbox
    │   └── Handlers/
    ├── Services/                          # Implementações de serviços externos
    │   └── {ExternalService}Client.cs
    └── DependencyInjection.cs

tests/
├── {ServiceName}.UnitTests/
│   ├── Domain/
│   └── Application/
├── {ServiceName}.IntegrationTests/
│   ├── Endpoints/
│   └── Persistence/
└── {ServiceName}.ArchitectureTests/
    └── ArchitectureTests.cs
```

### Alternativa: Vertical Sliced Architecture (RFC-001)

Para serviços mais simples ou CRUD-heavy:

```
src/{ServiceName}.Api/
├── Features/
│   ├── CreateOrder/
│   │   ├── CreateOrderCommand.cs
│   │   ├── CreateOrderHandler.cs
│   │   ├── CreateOrderValidator.cs
│   │   └── CreateOrderEndpoint.cs
│   ├── GetPositions/
│   │   ├── GetPositionsQuery.cs
│   │   ├── GetPositionsHandler.cs
│   │   └── GetPositionsEndpoint.cs
│   └── ...
├── Common/
│   ├── Behaviors/
│   └── Middleware/
├── Infrastructure/
│   ├── Persistence/
│   └── Messaging/
└── Program.cs
```

---

## Padrões de Código

### Minimal API Endpoints

```csharp
// src/{ServiceName}.Api/Endpoints/Portfolio/GetPositionsEndpoint.cs
public static class GetPositionsEndpoint
{
    public static void Map(IEndpointRouteBuilder app)
    {
        app.MapGet("/api/v1/portfolios/{accountId}/positions", Handle)
            .WithName("GetPositions")
            .WithTags("Portfolio")
            .Produces<GetPositionsResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .RequireAuthorization();
    }

    private static async Task<IResult> Handle(
        string accountId,
        ISender sender,
        CancellationToken cancellationToken)
    {
        var query = new GetPositionsQuery(accountId);
        var result = await sender.Send(query, cancellationToken);
        return Results.Ok(result);
    }
}
```

### Commands e Queries (CQRS com MediatR)

```csharp
// Command
public record CreateOrderCommand(
    string AccountId,
    string Ticker,
    decimal Quantity,
    OrderType Type) : IRequest<CreateOrderResponse>;

// Query
public record GetPositionsQuery(string AccountId) : IRequest<GetPositionsResponse>;
```

### Domain Entities

```csharp
public class Order : BaseEntity
{
    public string AccountId { get; private set; }
    public string Ticker { get; private set; }
    public decimal Quantity { get; private set; }
    public OrderStatus Status { get; private set; }

    private Order() { } // EF Core

    public static Order Create(string accountId, string ticker, decimal quantity)
    {
        var order = new Order
        {
            AccountId = accountId,
            Ticker = ticker,
            Quantity = quantity,
            Status = OrderStatus.Pending
        };

        order.AddDomainEvent(new OrderCreatedEvent(order.Id));
        return order;
    }

    public void Confirm()
    {
        if (Status != OrderStatus.Pending)
            throw new OrderDomainException("Apenas ordens pendentes podem ser confirmadas.");

        Status = OrderStatus.Confirmed;
        AddDomainEvent(new OrderConfirmedEvent(Id));
    }
}
```

---

## Regras de Fronteira entre Camadas

- **Domain** não referencia nenhuma outra camada (zero dependências externas).
- **Application** referencia apenas Domain.
- **Infrastructure** referencia Application e Domain.
- **Api** referencia Application (e indiretamente Domain via DI).
- Dependências sempre apontam para dentro (Dependency Rule da Clean Architecture).

---

## Padrões de Teste

- Cobertura mínima: 80% para código crítico (Domain e Application).
- Testes unitários para entidades, value objects e handlers.
- Testes de integração para repositories e endpoints (com Testcontainers).
- Testes de arquitetura para validar dependências entre camadas.
- xUnit como runner, NSubstitute para mocks, FluentAssertions para assertions.
- Padrão AAA (Arrange, Act, Assert).

---

## O que o Kiro Deve Verificar

Ao analisar código de backend C#, o Kiro deve verificar:

- [ ] Separação de camadas respeitada (Domain sem dependências externas).
- [ ] Entidades com comportamento (não anêmicas) e encapsulamento adequado.
- [ ] Validação via FluentValidation em todos os commands/queries.
- [ ] Endpoints com documentação OpenAPI (Produces, ProducesProblem, Tags).
- [ ] Uso de CancellationToken em operações assíncronas.
- [ ] Logs estruturados com contexto adequado (correlation ID, request ID).
- [ ] Tratamento de erros consistente via middleware global.
- [ ] Migrations EF Core atualizadas e revisadas.
- [ ] Testes unitários para lógica de domínio e handlers.
- [ ] Ausência de segredos hardcoded.
- [ ] Injeção de dependência correta (interfaces no Application, implementações no Infrastructure).
- [ ] Eventos de domínio para comunicação entre aggregates.

---

## Referências

- [ADR-001 – Padrão arquitetural de comunicação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517)
- [Microsoft – Clean Architecture](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [Microsoft – ASP.NET Core Minimal APIs](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis)
- [MediatR Documentation](https://github.com/jbogard/MediatR)
- [FluentValidation Documentation](https://docs.fluentvalidation.net/)

---

*Versão: 0.1.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
