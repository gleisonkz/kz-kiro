---
name: "Gerar Repository"
description: "Cria um repository com interface no Domain e implementação EF Core no Infrastructure, incluindo entity configuration."
inclusion: manual
---

# Gerar Repository

## Quando usar

Quando o desenvolvedor pedir para criar um repository para uma entidade de domínio (ex.: OrderRepository, PositionRepository).

## Inputs esperados

- **Entidade** (obrigatório): nome da entidade em PascalCase (ex.: `Order`, `Position`, `Account`).
- **Domínio** (obrigatório): nome do bounded context (ex.: `Orders`, `Portfolio`).
- **Operações** (opcional): lista de operações além do CRUD básico (ex.: `GetByAccount`, `GetPending`).

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Interface: `I{Entity}Repository` — no Domain.
- Implementação: `{Entity}Repository` — no Infrastructure.
- Configuration: `{Entity}Configuration` — no Infrastructure.

### Padrões obrigatórios

- Interface no Domain (sem dependência de EF Core).
- Implementação no Infrastructure usando `DbContext`.
- `CancellationToken` em todos os métodos assíncronos.
- Entity Configuration separada (Fluent API, não Data Annotations).
- Não expor `IQueryable` na interface — retornar coleções materializadas.

### Operações padrão

Todo repository deve ter pelo menos:

| Operação | Assinatura |
|---|---|
| GetById | `Task<T?> GetByIdAsync(Guid id, CancellationToken ct)` |
| Add | `Task AddAsync(T entity, CancellationToken ct)` |
| Update | `void Update(T entity)` |
| Delete | `void Delete(T entity)` |

## Exemplo de output

### `src/{ServiceName}.Domain/Orders/Interfaces/IOrderRepository.cs`

```csharp
using MonteBravo.{ServiceName}.Domain.Orders.Entities;

namespace MonteBravo.{ServiceName}.Domain.Orders.Interfaces;

public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Order>> GetByAccountAsync(string accountId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Order>> GetPendingAsync(CancellationToken cancellationToken = default);
    Task AddAsync(Order order, CancellationToken cancellationToken = default);
    void Update(Order order);
    void Delete(Order order);
}
```

### `src/{ServiceName}.Infrastructure/Persistence/Repositories/OrderRepository.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using MonteBravo.{ServiceName}.Domain.Orders.Entities;
using MonteBravo.{ServiceName}.Domain.Orders.Enums;
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

    public async Task<IReadOnlyList<Order>> GetByAccountAsync(
        string accountId, CancellationToken cancellationToken = default)
    {
        return await _context.Orders
            .Where(o => o.AccountId == accountId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Order>> GetPendingAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Orders
            .Where(o => o.Status == OrderStatus.Pending)
            .OrderBy(o => o.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(Order order, CancellationToken cancellationToken = default)
    {
        await _context.Orders.AddAsync(order, cancellationToken);
    }

    public void Update(Order order)
    {
        _context.Orders.Update(order);
    }

    public void Delete(Order order)
    {
        _context.Orders.Remove(order);
    }
}
```

### `src/{ServiceName}.Infrastructure/Persistence/Configurations/OrderConfiguration.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MonteBravo.{ServiceName}.Domain.Orders.Entities;
using MonteBravo.{ServiceName}.Domain.Orders.Enums;

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

        builder.Property(o => o.CreatedAt)
            .IsRequired();

        // Índices
        builder.HasIndex(o => o.AccountId)
            .HasDatabaseName("IX_Orders_AccountId");

        builder.HasIndex(o => new { o.AccountId, o.Status })
            .HasDatabaseName("IX_Orders_AccountId_Status");
    }
}
```

### Registro no DI (Infrastructure/DependencyInjection.cs)

```csharp
// Adicionar ao método AddInfrastructure:
services.AddScoped<IOrderRepository, OrderRepository>();
```
