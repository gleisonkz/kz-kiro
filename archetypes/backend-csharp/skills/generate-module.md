---
name: "Gerar Módulo Backend C#"
description: "Cria a estrutura completa de um módulo de domínio: endpoint, command/query, handler, validator, entity, repository e testes."
inclusion: manual
---

# Gerar Módulo Backend C#

## Quando usar

Quando o desenvolvedor pedir para criar um novo módulo/domínio no serviço (ex.: Orders, Positions, Accounts).

## Inputs esperados

- **Nome do domínio** (obrigatório): nome do bounded context em PascalCase (ex.: `Orders`, `Positions`, `Accounts`).
- **Operações** (opcional): lista de operações a criar (ex.: `Create`, `GetById`, `GetByAccount`, `Update`).
- **Entidade principal** (opcional): nome da entidade raiz do aggregate.

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Diretórios: `PascalCase`, organizados por domínio dentro de cada camada.
- Commands: `{Verb}{Entity}Command.cs`.
- Queries: `Get{Entity}Query.cs`, `Get{Entity}ByIdQuery.cs`.
- Handlers: `{Command/Query}Handler.cs`.
- Validators: `{Command}Validator.cs`.
- Endpoints: `{Verb}{Entity}Endpoint.cs`.

### Estrutura do módulo (ref: architecture.md)

```
src/
├── {ServiceName}.Api/
│   └── Endpoints/{Domain}/
│       ├── {Domain}Endpoints.cs           # Registro dos endpoints do domínio
│       ├── Create{Entity}Endpoint.cs
│       └── Get{Entity}Endpoint.cs
│
├── {ServiceName}.Application/
│   └── {Domain}/
│       ├── Commands/
│       │   └── Create{Entity}/
│       │       ├── Create{Entity}Command.cs
│       │       ├── Create{Entity}CommandHandler.cs
│       │       └── Create{Entity}CommandValidator.cs
│       └── Queries/
│           └── Get{Entity}/
│               ├── Get{Entity}Query.cs
│               ├── Get{Entity}QueryHandler.cs
│               └── Get{Entity}Response.cs
│
├── {ServiceName}.Domain/
│   └── {Domain}/
│       ├── Entities/
│       │   └── {Entity}.cs
│       ├── Enums/
│       │   └── {Entity}Status.cs
│       ├── Events/
│       │   └── {Entity}CreatedEvent.cs
│       ├── Exceptions/
│       │   └── {Domain}DomainException.cs
│       └── Interfaces/
│           └── I{Entity}Repository.cs
│
└── {ServiceName}.Infrastructure/
    └── Persistence/
        ├── Configurations/
        │   └── {Entity}Configuration.cs
        └── Repositories/
            └── {Entity}Repository.cs

tests/
└── {ServiceName}.UnitTests/
    ├── Domain/{Domain}/
    │   └── {Entity}Tests.cs
    └── Application/{Domain}/
        └── Create{Entity}CommandHandlerTests.cs
```

### Regras de implementação

- **Entity**: com comportamento, construtores privados, factory methods e domain events.
- **Command/Query**: records imutáveis implementando `IRequest<T>`.
- **Handler**: recebe dependências via construtor, usa CancellationToken.
- **Validator**: FluentValidation com regras claras.
- **Endpoint**: Minimal API com documentação OpenAPI completa.
- **Repository**: interface no Domain, implementação no Infrastructure.

## Exemplo de output

Para domínio `Orders` com entidade `Order` e operação `Create`:

### `src/{ServiceName}.Domain/Orders/Entities/Order.cs`

```csharp
using MonteBravo.{ServiceName}.Domain.Common;
using MonteBravo.{ServiceName}.Domain.Orders.Enums;
using MonteBravo.{ServiceName}.Domain.Orders.Events;
using MonteBravo.{ServiceName}.Domain.Orders.Exceptions;

namespace MonteBravo.{ServiceName}.Domain.Orders.Entities;

public class Order : BaseEntity, IAuditableEntity
{
    public string AccountId { get; private set; } = default!;
    public string Ticker { get; private set; } = default!;
    public decimal Quantity { get; private set; }
    public OrderStatus Status { get; private set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    private Order() { } // EF Core

    public static Order Create(string accountId, string ticker, decimal quantity)
    {
        if (string.IsNullOrWhiteSpace(accountId))
            throw new OrdersDomainException("AccountId é obrigatório.");
        if (string.IsNullOrWhiteSpace(ticker))
            throw new OrdersDomainException("Ticker é obrigatório.");
        if (quantity <= 0)
            throw new OrdersDomainException("Quantidade deve ser maior que zero.");

        var order = new Order
        {
            Id = Guid.NewGuid(),
            AccountId = accountId,
            Ticker = ticker,
            Quantity = quantity,
            Status = OrderStatus.Pending
        };

        order.AddDomainEvent(new OrderCreatedEvent(order.Id, accountId, ticker));
        return order;
    }
}
```

### `src/{ServiceName}.Domain/Orders/Interfaces/IOrderRepository.cs`

```csharp
namespace MonteBravo.{ServiceName}.Domain.Orders.Interfaces;

public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(Order order, CancellationToken cancellationToken = default);
}
```

### `src/{ServiceName}.Application/Orders/Commands/CreateOrder/CreateOrderCommand.cs`

```csharp
using MediatR;

namespace MonteBravo.{ServiceName}.Application.Orders.Commands.CreateOrder;

public record CreateOrderCommand(
    string AccountId,
    string Ticker,
    decimal Quantity) : IRequest<CreateOrderResponse>;

public record CreateOrderResponse(Guid OrderId);
```

### `src/{ServiceName}.Application/Orders/Commands/CreateOrder/CreateOrderCommandHandler.cs`

```csharp
using MediatR;
using MonteBravo.{ServiceName}.Domain.Orders.Entities;
using MonteBravo.{ServiceName}.Domain.Orders.Interfaces;
using MonteBravo.{ServiceName}.Application.Common.Interfaces;

namespace MonteBravo.{ServiceName}.Application.Orders.Commands.CreateOrder;

public class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, CreateOrderResponse>
{
    private readonly IOrderRepository _repository;
    private readonly IUnitOfWork _unitOfWork;

    public CreateOrderCommandHandler(IOrderRepository repository, IUnitOfWork unitOfWork)
    {
        _repository = repository;
        _unitOfWork = unitOfWork;
    }

    public async Task<CreateOrderResponse> Handle(
        CreateOrderCommand request,
        CancellationToken cancellationToken)
    {
        var order = Order.Create(request.AccountId, request.Ticker, request.Quantity);
        await _repository.AddAsync(order, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new CreateOrderResponse(order.Id);
    }
}
```

### `src/{ServiceName}.Application/Orders/Commands/CreateOrder/CreateOrderCommandValidator.cs`

```csharp
using FluentValidation;

namespace MonteBravo.{ServiceName}.Application.Orders.Commands.CreateOrder;

public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderCommandValidator()
    {
        RuleFor(x => x.AccountId)
            .NotEmpty().WithMessage("AccountId é obrigatório.");

        RuleFor(x => x.Ticker)
            .NotEmpty().WithMessage("Ticker é obrigatório.")
            .MaximumLength(10).WithMessage("Ticker deve ter no máximo 10 caracteres.");

        RuleFor(x => x.Quantity)
            .GreaterThan(0).WithMessage("Quantidade deve ser maior que zero.");
    }
}
```

### `src/{ServiceName}.Api/Endpoints/Orders/CreateOrderEndpoint.cs`

```csharp
using MediatR;
using MonteBravo.{ServiceName}.Application.Orders.Commands.CreateOrder;

namespace MonteBravo.{ServiceName}.Api.Endpoints.Orders;

public static class CreateOrderEndpoint
{
    public static void Map(IEndpointRouteBuilder app)
    {
        app.MapPost("/api/v1/orders", Handle)
            .WithName("CreateOrder")
            .WithTags("Orders")
            .Produces<CreateOrderResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem()
            .ProducesProblem(StatusCodes.Status500InternalServerError)
            .RequireAuthorization();
    }

    private static async Task<IResult> Handle(
        CreateOrderCommand command,
        ISender sender,
        CancellationToken cancellationToken)
    {
        var result = await sender.Send(command, cancellationToken);
        return Results.Created($"/api/v1/orders/{result.OrderId}", result);
    }
}
```

### `src/{ServiceName}.Api/Endpoints/Orders/OrdersEndpoints.cs`

```csharp
namespace MonteBravo.{ServiceName}.Api.Endpoints.Orders;

public static class OrdersEndpoints
{
    public static void MapOrdersEndpoints(this IEndpointRouteBuilder app)
    {
        CreateOrderEndpoint.Map(app);
        // Adicionar outros endpoints aqui
    }
}
```

### `src/{ServiceName}.Infrastructure/Persistence/Configurations/OrderConfiguration.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MonteBravo.{ServiceName}.Domain.Orders.Entities;

namespace MonteBravo.{ServiceName}.Infrastructure.Persistence.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("Orders");

        builder.HasKey(o => o.Id);

        builder.Property(o => o.AccountId)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(o => o.Ticker)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(o => o.Quantity)
            .HasPrecision(18, 8);

        builder.Property(o => o.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.HasIndex(o => o.AccountId);
    }
}
```

### `src/{ServiceName}.Infrastructure/Persistence/Repositories/OrderRepository.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using MonteBravo.{ServiceName}.Domain.Orders.Entities;
using MonteBravo.{ServiceName}.Domain.Orders.Interfaces;

namespace MonteBravo.{ServiceName}.Infrastructure.Persistence.Repositories;

public class OrderRepository : IOrderRepository
{
    private readonly AppDbContext _context;

    public OrderRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Orders.FindAsync(new object[] { id }, cancellationToken);
    }

    public async Task AddAsync(Order order, CancellationToken cancellationToken = default)
    {
        await _context.Orders.AddAsync(order, cancellationToken);
    }
}
```

### Registro no Program.cs

```csharp
// Após configurar o app:
app.MapOrdersEndpoints();
```
