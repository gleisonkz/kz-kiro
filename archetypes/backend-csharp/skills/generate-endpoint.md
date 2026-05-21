---
name: "Gerar Endpoint Minimal API"
description: "Cria um endpoint ASP.NET Core Minimal API com documentação OpenAPI, integração MediatR e padrões do archetype."
inclusion: manual
---

# Gerar Endpoint Minimal API

## Quando usar

Quando o desenvolvedor pedir para criar um novo endpoint REST no serviço (ex.: GET /positions, POST /orders, PUT /orders/{id}).

## Inputs esperados

- **Verbo HTTP** (obrigatório): GET, POST, PUT, PATCH ou DELETE.
- **Recurso** (obrigatório): nome do recurso em kebab-case (ex.: `orders`, `positions`).
- **Domínio** (obrigatório): nome do domínio/feature (ex.: `Orders`, `Portfolio`).
- **Parâmetros** (opcional): path params, query params ou body.
- **Requer autenticação** (opcional, padrão: sim).

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Arquivo: `{Verb}{Resource}Endpoint.cs` — `GetPositionsEndpoint.cs`, `CreateOrderEndpoint.cs`.
- Classe: `{Verb}{Resource}Endpoint` — estática.
- Método handler: `Handle` — privado e estático.
- Rota: `/api/v1/{resource}` — kebab-case, plural.

### Padrões obrigatórios

- Classe estática com método `Map(IEndpointRouteBuilder app)`.
- Handler recebe `ISender` (MediatR) para despachar command/query.
- `CancellationToken` como último parâmetro do handler.
- Documentação OpenAPI completa: `WithName`, `WithTags`, `Produces`, `ProducesProblem`.
- `.RequireAuthorization()` por padrão (exceto endpoints públicos explícitos).
- Sem lógica de negócio no handler — apenas extrai dados e despacha.

### Mapeamento de verbos HTTP para padrões

| Verbo | Padrão | Response Code |
|---|---|---|
| GET (coleção) | Query → lista | 200 OK |
| GET (item) | Query → item | 200 OK / 404 Not Found |
| POST | Command → criação | 201 Created |
| PUT | Command → atualização total | 200 OK / 404 Not Found |
| PATCH | Command → atualização parcial | 200 OK / 404 Not Found |
| DELETE | Command → remoção | 204 No Content / 404 Not Found |

## Exemplo de output

### GET (coleção) — `GetPositionsEndpoint.cs`

```csharp
using MediatR;
using MonteBravo.Portfolio.Application.Positions.Queries.GetPositions;

namespace MonteBravo.Portfolio.Api.Endpoints.Positions;

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

### POST — `CreateOrderEndpoint.cs`

```csharp
using MediatR;
using MonteBravo.Trading.Application.Orders.Commands.CreateOrder;

namespace MonteBravo.Trading.Api.Endpoints.Orders;

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

### DELETE — `DeleteOrderEndpoint.cs`

```csharp
using MediatR;
using MonteBravo.Trading.Application.Orders.Commands.DeleteOrder;

namespace MonteBravo.Trading.Api.Endpoints.Orders;

public static class DeleteOrderEndpoint
{
    public static void Map(IEndpointRouteBuilder app)
    {
        app.MapDelete("/api/v1/orders/{orderId:guid}", Handle)
            .WithName("DeleteOrder")
            .WithTags("Orders")
            .Produces(StatusCodes.Status204NoContent)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .RequireAuthorization();
    }

    private static async Task<IResult> Handle(
        Guid orderId,
        ISender sender,
        CancellationToken cancellationToken)
    {
        var command = new DeleteOrderCommand(orderId);
        await sender.Send(command, cancellationToken);
        return Results.NoContent();
    }
}
```

### Registro no grupo de endpoints

```csharp
// src/{ServiceName}.Api/Endpoints/Orders/OrdersEndpoints.cs
namespace MonteBravo.Trading.Api.Endpoints.Orders;

public static class OrdersEndpoints
{
    public static void MapOrdersEndpoints(this IEndpointRouteBuilder app)
    {
        CreateOrderEndpoint.Map(app);
        GetOrderByIdEndpoint.Map(app);
        DeleteOrderEndpoint.Map(app);
    }
}
```
