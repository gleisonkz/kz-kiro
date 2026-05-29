# Arquitetura do Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos de serviços de domínio .NET/C#.
> Ele define a arquitetura interna, padrões de comunicação e fronteiras de responsabilidade.
>
> Baseado em: ADR-001 (Comunicação entre serviços distribuídos), RFC-001 (Padrões arquiteturais), RFC-003 (Outbox/Inbox)

---

## Papel Arquitetural do Serviço de Domínio

O serviço de domínio encapsula regras de negócio e persistência de um bounded context:

```
┌─────────────────┐     ┌──────────────────────┐     ┌──────────────────┐
│  BFFs           │────▶│  Serviço de Domínio   │────▶│  Banco de Dados  │
│  (Fastify)      │◀────│  (.NET/C#)            │     │  (PostgreSQL)    │
└─────────────────┘     └──────────────────────┘     └──────────────────┘
                              │         ▲
                              ▼         │
                        ┌─────────────────────┐
                        │  Message Broker      │
                        │  (SQS/EventBridge/   │
                        │   RabbitMQ/Kafka)     │
                        └─────────────────────┘
                              │         ▲
                              ▼         │
                        ┌─────────────────────┐
                        │  Outros Serviços    │
                        │  (coreografados)    │
                        └─────────────────────┘
```

### Princípios fundamentais

1. **Bounded Context isolado**: cada serviço encapsula um domínio de negócio coeso e autônomo.
2. **Database per Service**: cada serviço possui seu próprio banco de dados (PostgreSQL) — sem compartilhamento.
3. **Comunicação via mensageria** (ADR-001): serviços se comunicam de forma assíncrona via Message Broker, seguindo o padrão de coreografia (não orquestração).
4. **Outbox/Inbox para transações financeiras** (RFC-003): garantir ACID em ambiente distribuído usando Outbox Pattern (envio confiável) e Inbox Pattern (processamento idempotente).
5. **CQRS**: separação entre operações de leitura (Queries) e escrita (Commands).
6. **Dependency Rule**: dependências sempre apontam para dentro — Domain não conhece nada externo.
7. **Contratos explícitos**: toda API possui documentação OpenAPI gerada automaticamente.
8. **Independência de deploy**: cada serviço pode ser deployado, escalado e versionado separadamente.

---

## Padrões Arquiteturais Aceitos (RFC-001)

A RFC-001 define três padrões arquiteturais aceitos para projetos backend. A escolha depende do contexto e complexidade do serviço:

### 1. Clean Architecture (padrão principal)

Separação em camadas com Dependency Rule rigorosa:

```
┌─────────────────────────────────────────────────────┐
│                   Presentation (Api)                  │  ← Entry point, endpoints, middleware
├─────────────────────────────────────────────────────┤
│                   Application                        │  ← Use cases, commands, queries, DTOs
├─────────────────────────────────────────────────────┤
│                     Domain                           │  ← Entidades, value objects, regras
├─────────────────────────────────────────────────────┤
│                  Infrastructure                      │  ← EF Core, clients HTTP, messaging
└─────────────────────────────────────────────────────┘
```

**Dependency Rule:**
```
Domain      -> Não possui nenhuma dependência
Application -> Dependência com o projeto Domain
Persistence -> Dependência com o projeto Application
WebApi      -> Dependência com o projeto Application e Persistence
```

**Quando usar:** Serviços com domínio complexo, múltiplas entidades e regras de negócio elaboradas.

### 2. Vertical Sliced Architecture

Organização por funcionalidades (features) em vez de camadas:

```
src/Features/
├── CreateOrder/
│   ├── CreateOrderCommand.cs
│   ├── CreateOrderHandler.cs
│   ├── CreateOrderValidator.cs
│   └── CreateOrderEndpoint.cs
├── GetPositions/
│   ├── GetPositionsQuery.cs
│   ├── GetPositionsHandler.cs
│   └── GetPositionsEndpoint.cs
└── ...
```

**Vantagens:**
- Alta coesão — todo código de uma feature em um único lugar.
- Navegação rápida e fácil.
- Cada slice pode usar a abordagem mais adequada (EF Core para um, Dapper para outro).
- Minimiza acoplamento entre features.

**Quando usar:** Serviços com muitas features independentes, APIs CRUD-heavy, equipes que preferem velocidade de desenvolvimento.

### 3. Hexagonal Architecture (Ports & Adapters)

Núcleo isolado com portas (interfaces) e adaptadores (implementações):

```
Domain (Core)    -> Totalmente independente
Application      -> Dependente de Domain, independente de frameworks/DB/UI
Infrastructure   -> Dependente de Domain, contém adaptadores
UI/Presentation  -> Dependente de Application
```

**Quando usar:** Serviços que precisam de alta portabilidade entre tecnologias externas ou que integram com muitos sistemas externos.

---

## Comunicação entre Serviços (ADR-001)

### Padrão: Mensageria Coreografada

A ADR-001 define que a comunicação entre serviços distribuídos internos deve usar **mensageria com coreografia**:

- Serviços publicam eventos no Message Broker sem conhecer os consumidores.
- Baixo acoplamento entre serviços.
- Alta escalabilidade e resiliência.
- Processamento assíncrono (fire and forget).

### Coreografia vs Orquestração

| Aspecto | Coreografia (adotado) | Orquestração (evitar) |
|---|---|---|
| Acoplamento | Baixo | Alto |
| Comunicação | Assíncrona | Geralmente síncrona |
| Ponto de falha | Distribuído | Orquestrador centralizado |
| Escalabilidade | Alta | Limitada pelo orquestrador |
| Rastreabilidade | Requer observabilidade centralizada | Mais fácil de rastrear |

### Quando usar HTTP síncrono

HTTP direto (REST) é aceito apenas para:
- Consultas que precisam de resposta imediata (queries do BFF).
- Health checks e endpoints de status.
- Operações onde a latência da mensageria é inaceitável.

### Comparação rápida (ADR-001)

| Feature | REST API | Message Broker |
|---|---|---|
| Comunicação | Síncrono | Assíncrono |
| Acoplamento | Mais acoplado | Menos acoplado |
| Confiabilidade | Falha se receptor inativo | Mensagens persistem na fila |
| Performance | Rápido para requests individuais | Melhor em alto volume |
| Complexidade | Fácil de construir | Maior esforço de setup |

---

## Outbox/Inbox Pattern (RFC-003)

### Quando aplicar

**Obrigatório** para:
- Transações financeiras (ordens, transferências, pagamentos).
- Integrações com serviços externos.
- Qualquer operação que precisa garantir consistência entre banco de dados e mensageria.

### Outbox Pattern (envio confiável)

Resolve o problema do **Dual Write** — garante que dados são salvos no banco E o evento é publicado atomicamente:

```
1. Aplicação salva dados + evento na mesma transação (ACID)
2. Worker/Framework lê eventos da tabela outbox
3. Publica no Message Broker
4. Marca como enviado
```

**Características:**
- Resolve Dual Write (dados salvos + evento publicado atomicamente).
- Alta confiabilidade — eventos persistidos antes do envio.
- Desacoplamento entre aplicação e mensageria.
- Auditoria e rastreabilidade de eventos.

### Inbox Pattern (processamento confiável)

Garante processamento **idempotente** de mensagens recebidas:

```
1. Mensagem chega do broker
2. Verifica se já foi processada (deduplicação por ID)
3. Se nova: processa e registra na tabela inbox
4. Se duplicada: ignora
```

**Características:**
- Idempotência — evita processamento duplicado.
- Reprocessamento seguro em caso de falha.
- Complementa o Outbox (envio confiável + processamento confiável).
- Suporte a consistência eventual.

### Framework recomendado: Wolverine

A RFC-003 recomenda o framework [Wolverine](https://wolverinefx.net/) para implementação de Outbox/Inbox, com suporte a:
- RabbitMQ e Kafka como brokers.
- Integração com EF Core para transações atômicas.
- .NET Aspire para orquestração local.

---

## CQRS com MediatR

### Commands (escrita)

Commands representam intenções de mudança de estado:

```csharp
public record CreateOrderCommand(
    string AccountId,
    string Ticker,
    decimal Quantity,
    OrderType Type) : IRequest<CreateOrderResponse>;

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

### Queries (leitura)

Queries representam consultas sem side effects. Podem usar EF Core ou Dapper conforme a necessidade:

```csharp
public record GetPositionsQuery(string AccountId) : IRequest<GetPositionsResponse>;

public class GetPositionsQueryHandler : IRequestHandler<GetPositionsQuery, GetPositionsResponse>
{
    private readonly IPositionRepository _repository;

    public GetPositionsQueryHandler(IPositionRepository repository)
    {
        _repository = repository;
    }

    public async Task<GetPositionsResponse> Handle(
        GetPositionsQuery request,
        CancellationToken cancellationToken)
    {
        var positions = await _repository.GetByAccountAsync(
            request.AccountId, cancellationToken);

        return new GetPositionsResponse(
            positions.Select(p => new PositionDto(p.Ticker, p.Quantity, p.CurrentValue)).ToList());
    }
}
```

---

## Domain-Driven Design

### Entidades

Entidades possuem identidade e comportamento (nunca anêmicas):

```csharp
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
        if (quantity <= 0)
            throw new OrderDomainException("Quantidade deve ser maior que zero.");

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

    public void Confirm()
    {
        if (Status != OrderStatus.Pending)
            throw new OrderDomainException("Apenas ordens pendentes podem ser confirmadas.");

        Status = OrderStatus.Confirmed;
        AddDomainEvent(new OrderConfirmedEvent(Id));
    }
}
```

### Value Objects

Value objects são imutáveis e comparados por valor. Para valores monetários, **sempre usar `decimal`** (nunca float/double):

```csharp
public record Money
{
    public decimal Amount { get; }
    public string Currency { get; }

    public Money(decimal amount, string currency)
    {
        if (amount < 0)
            throw new DomainException("Valor monetário não pode ser negativo.");

        Amount = amount;
        Currency = currency.ToUpperInvariant();
    }
}
```

### Eventos de Domínio

Eventos comunicam mudanças de estado entre aggregates e são publicados via Outbox:

```csharp
public record OrderCreatedEvent(Guid OrderId, string AccountId, string Ticker) : IDomainEvent;
public record OrderConfirmedEvent(Guid OrderId) : IDomainEvent;
```

---

## Persistência com Entity Framework Core + PostgreSQL

### Governança de Dados (Chapter de Dados)

> ⚠️ Para a referência completa de nomenclatura e regras, consulte o steering `data-governance.md`.

**Resumo das regras:**
- Tabelas: `snake_case`, **singular**, inglês — `transfer`, `transfer_item`, `customer`.
- Colunas: `snake_case` com **prefixo de natureza** — `id_transfer`, `nm_customer`, `vl_amount`.
- Toda tabela deve conter `tmp_creation` (NOT NULL) e `tmp_update` (nullable).
- Valores monetários: `DECIMAL(18, 8)` com `HasPrecision(18, 8)` — nunca float/double.
- `HasComment()` obrigatório em pt-BR para toda tabela e coluna.
- Constraints nomeadas: `pk_{tabela}`, `fk_{origem}_{destino}`, `ix_{tabela}_{coluna}`.

### Migrations como Versionamento

As migrations do EF Core servem como **versionamento** do modelo de dados, não como mecanismo de deploy:

```
Dev gera migration → Submete para validação → Chapter aprova → DBA executa no banco
```

- Migrations **NÃO são executadas automaticamente** pelo serviço.
- Manter migrations no repositório como histórico de alterações.
- Usar como insumo para o DBA na criação/alteração de objetos.
- Gerar pacote de validação (DDL + Dicionário + Diagrama ER) antes de submeter ao chapter.

### Entity Configuration (mapeamento com governança de dados)

```csharp
public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("order")
            .HasComment("Ordem de compra ou venda de ativos financeiros.");

        builder.HasKey(o => o.Id)
            .HasName("pk_order");

        builder.Property(o => o.Id)
            .HasColumnName("id_order")
            .HasComment("Identificador único da ordem");

        builder.Property(o => o.AccountId)
            .HasColumnName("id_account")
            .IsRequired()
            .HasMaxLength(50)
            .HasComment("Identificador da conta do cliente");

        builder.Property(o => o.Ticker)
            .HasColumnName("cd_ticker")
            .IsRequired()
            .HasMaxLength(10)
            .HasComment("Código do ativo negociado");

        builder.Property(o => o.Quantity)
            .HasColumnName("qt_asset")
            .HasPrecision(18, 8)
            .HasComment("Quantidade de ativos na ordem");

        builder.Property(o => o.Status)
            .HasColumnName("st_order")
            .HasConversion<int>()
            .HasComment("Situação da ordem: 1=Pendente, 2=Confirmada, 3=Executada, 4=Cancelada");

        builder.Property(o => o.CreatedAt)
            .HasColumnName("tmp_creation")
            .IsRequired()
            .HasComment("Data e hora da criação do registro");

        builder.Property(o => o.UpdatedAt)
            .HasColumnName("tmp_update")
            .HasComment("Data e hora da última atualização do registro");

        builder.HasIndex(o => o.AccountId)
            .HasDatabaseName("ix_order_id_account");

        builder.HasIndex(o => new { o.AccountId, o.Status })
            .HasDatabaseName("ix_order_id_account_st_order");
    }
}
```

---

## Resiliência

### Retry com Polly

```csharp
services.AddHttpClient<IExternalServiceClient, ExternalServiceClient>()
    .AddTransientHttpErrorPolicy(p =>
        p.WaitAndRetryAsync(3, attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt))))
    .AddTransientHttpErrorPolicy(p =>
        p.CircuitBreakerAsync(5, TimeSpan.FromSeconds(30)));
```

### Timeouts

| Camada | Timeout padrão |
|---|---|
| Request total (BFF → Serviço) | 10s |
| Operação de banco | 5s |
| Client HTTP externo | 5s |

---

## Observabilidade

### Logs estruturados (CloudWatch)

- Formato JSON estruturado.
- Incluir em todo log: `CorrelationId`, `RequestId`, `UserId`.
- AWS CloudWatch como destino.

### Tracing

- AWS X-Ray para distributed tracing.
- Propagar trace context para serviços downstream.

### Métricas

- Latência por endpoint (p50, p95, p99).
- Taxa de erro por endpoint.
- Contadores de operações de domínio.

---

## Health Checks

```csharp
builder.Services.AddHealthChecks()
    .AddNpgSql(connectionString, name: "database")
    .AddCheck("self", () => HealthCheckResult.Healthy());

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Name == "self"
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = _ => true
});
```

---

## Glossário de Termos Financeiros (Guia de Nomeação)

Para consistência no código, usar os seguintes termos padronizados:

| Conceito | Termo padrão | Evitar |
|---|---|---|
| Cotação de mercado | `price` | `valor`, `cotacao` |
| Soma financeira | `amount` ou `value` | `price` (para somas) |
| Compra/Venda | Enum `Side` com `BUY`/`SELL` | `type`, `direction` |
| Ativo | `asset` ou `instrument` | `product` |
| Código do ativo | `symbol` ou `ticker` | `code`, `name` |

---

## Referências

- [ADR-001 – Padrão arquitetural de comunicação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517)
- [RFC-001 – Padrões arquiteturais de projetos](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/181731331)
- [RFC-002 – Padrão Steering File para backend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/192806913)
- [RFC-003 – Outbox/Inbox para transações financeiras](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/227082241)
- [Guia de Padrões de Nomeação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/122191873)
- [Wolverine Framework](https://wolverinefx.net/)

---

*Versão: 0.2.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
