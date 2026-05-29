# Convenções de Nomenclatura — Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos de serviços de domínio .NET/C#.
> Ele define o padrão oficial de nomenclatura para diretórios, arquivos, símbolos de código e banco de dados.
>
> Baseado em: RFC-002 (Padrão Steering File para backend), Guia de Padrões de Nomeação para Serviços Financeiros e Trading

---

## Princípios Gerais

- Seguir as [convenções oficiais do .NET](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions).
- Nomes devem ser claros, previsíveis e consistentes com a responsabilidade do artefato.
- Priorizar legibilidade e busca simples no código.

### Regra de idioma

- Nomes de arquivos, pastas e símbolos de código: **inglês técnico**.
- Documentação e comentários explicativos: **português do Brasil**.
- Não misturar português e inglês no mesmo identificador.
- Usar termos do glossário financeiro padronizado (seção abaixo).

---

## Database Standards (Governança de Dados)

> ⚠️ **Atenção:** As regras de banco de dados seguem o padrão definido pelo chapter de dados.
> Consulte o steering `data-governance.md` para a referência completa.

### Duas camadas, duas convenções

| Camada | Convenção | Exemplo |
|---|---|---|
| Código C# (propriedades, classes) | `PascalCase` (.NET standard) | `BlogId`, `CustomerName`, `BirthDate` |
| Banco de dados (tabelas e colunas) | `snake_case` com prefixo de natureza | `id_blog`, `nm_customer`, `dt_birth` |

### Tabelas

- **`snake_case`**, sempre no **singular**, em **inglês**.
- Exemplos: `customer`, `transfer`, `transfer_item`, `tax_invoice`.

### Colunas

- **`snake_case`** com **prefixo de natureza obrigatório**.
- Formato: `{prefixo_natureza}_{nome}`.
- Exemplos: `id_customer`, `nm_customer`, `vl_amount`, `dt_settlement`, `st_order`.

### Prefixos de natureza

| Prefixo | Significado | Exemplo |
|---|---|---|
| `id` | Identificador | `id_transfer`, `id_account` |
| `nm` | Nome | `nm_customer`, `nm_asset` |
| `cd` | Código | `cd_currency`, `cd_asset` |
| `ds` | Descrição | `ds_observation` |
| `dt` | Data | `dt_settlement`, `dt_birth` |
| `tmp` | Timestamp | `tmp_creation`, `tmp_update` |
| `vl` | Valor monetário | `vl_amount`, `vl_unit_price` |
| `qt` | Quantidade | `qt_asset`, `qt_shares` |
| `st` | Status/Situação | `st_order`, `st_transfer` |
| `pc` | Percentual | `pc_fee`, `pc_tax` |
| `nu` | Número | `nu_sequence` |
| `in` | Indicador | `in_active`, `in_blocked` |

### Regras obrigatórias

- Toda tabela deve conter `tmp_creation` (NOT NULL) e `tmp_update` (nullable) para auditoria.
- Valores monetários: `DECIMAL(18, 8)` — **nunca** `float` ou `double`.
- Índices: `ix_{tabela}_{coluna}` — ex.: `ix_transfer_id_source_account`.
- Foreign keys: `fk_{tabela_origem}_{tabela_destino}` — ex.: `fk_transfer_item_transfer`.
- Primary keys: `pk_{tabela}` — ex.: `pk_transfer`.
- `HasComment()` obrigatório em pt-BR para toda tabela e coluna.

### Exemplos

| Entity | Table Name | Column Examples |
|---|---|---|
| Transfer | `transfer` | `id_transfer`, `id_source_account`, `vl_amount`, `st_transfer` |
| TransferItem | `transfer_item` | `id_transfer_item`, `id_transfer`, `cd_asset`, `qt_asset` |
| Customer | `customer` | `id_customer`, `nm_customer`, `cd_document`, `dt_birth` |
| Account | `account` | `id_account`, `nm_account`, `vl_balance`, `in_blocked` |

---

## Projetos (Solution)

- `PascalCase` com separação por ponto.
- Padrão: `MonteBravo.{ServiceName}.{Layer}`.
- Exemplos:
  - `MonteBravo.Portfolio.Api`
  - `MonteBravo.Portfolio.Application`
  - `MonteBravo.Portfolio.Domain`
  - `MonteBravo.Portfolio.Infrastructure`
  - `MonteBravo.Portfolio.UnitTests`
  - `MonteBravo.Portfolio.IntegrationTests`

---

## Diretórios

- `PascalCase` sempre (convenção .NET).
- Organizados por domínio/feature dentro de cada camada.
- Exemplos: `Endpoints`, `Commands`, `Queries`, `Entities`, `ValueObjects`, `Repositories`.

---

## Arquivos

### Convenção geral

- Um tipo público por arquivo.
- Nome do arquivo = nome do tipo: `Order.cs`, `OrderRepository.cs`.
- `PascalCase` sempre.

### Sufixos de arquivo por camada

| Camada | Tipo | Sufixo | Exemplo |
|---|---|---|---|
| Api | Endpoint | `Endpoint` | `GetPositionsEndpoint.cs` |
| Api | Middleware | `Middleware` | `ExceptionHandlerMiddleware.cs` |
| Application | Command | `Command` | `CreateOrderCommand.cs` |
| Application | Command Handler | `CommandHandler` | `CreateOrderCommandHandler.cs` |
| Application | Command Validator | `CommandValidator` | `CreateOrderCommandValidator.cs` |
| Application | Query | `Query` | `GetPositionsQuery.cs` |
| Application | Query Handler | `QueryHandler` | `GetPositionsQueryHandler.cs` |
| Application | Response DTO | `Response` | `GetPositionsResponse.cs` |
| Application | Behavior | `Behavior` | `ValidationBehavior.cs` |
| Application | Interface | `I{Name}` | `IOrderRepository.cs` |
| Domain | Entity | sem sufixo | `Order.cs` |
| Domain | Value Object | sem sufixo | `Money.cs`, `Address.cs` |
| Domain | Enum | sem sufixo | `OrderStatus.cs` |
| Domain | Domain Event | `Event` | `OrderCreatedEvent.cs` |
| Domain | Domain Exception | `Exception` | `OrderDomainException.cs` |
| Domain | Repository Interface | `I{Name}Repository` | `IOrderRepository.cs` |
| Infrastructure | Repository | `Repository` | `OrderRepository.cs` |
| Infrastructure | DbContext | `DbContext` | `PortfolioDbContext.cs` |
| Infrastructure | EF Configuration | `Configuration` | `OrderConfiguration.cs` |
| Infrastructure | External Client | `Client` | `MarketDataClient.cs` |
| Infrastructure | Message Handler | `Handler` | `OrderCreatedHandler.cs` |
| Tests | Teste | `Tests` | `OrderTests.cs` |

---

## Namespaces (RFC-002)

- `PascalCase`.
- Espelham a estrutura de diretórios.
- Padrão: `MonteBravo.{ServiceName}.{Layer}.{Feature}`.

---

## Classes e Records (RFC-002)

- `PascalCase`.
- Entidades: nome do conceito de domínio — `Order`, `Position`, `Account`.
- Records para DTOs e value objects imutáveis.
- Classes de serviço com sufixo descritivo: `OrderManager`, `PortfolioService`, `MarketDataStreamer`.

---

## Interfaces

- Prefixo `I` + `PascalCase`.
- Exemplos: `IOrderRepository`, `IUnitOfWork`, `IMarketDataClient`.

---

## Métodos (RFC-002)

- `PascalCase` (convenção .NET/C#).
- Verbos de ação: `Create`, `Get`, `Update`, `Delete`, `Calculate`, `Validate`.
- Métodos assíncronos: sufixo `Async` — `GetByIdAsync`, `SaveChangesAsync`.
- Handlers: `Handle` (convenção MediatR).

### Exemplos do domínio financeiro (Guia de Nomeação)

- `CalculateNetWorth()` — retorna patrimônio líquido.
- `ValidateOrderMargin()` — checa saldo/margem antes de enviar ordem.
- `CancelAllPendingOrders()` — ação em massa.
- `FetchHistoricalPrices()` — busca dados passados.

---

## Propriedades

- `PascalCase`.
- Exemplos: `AccountId`, `Ticker`, `Quantity`, `Status`.

---

## Campos Privados (RFC-002)

- `_camelCase` (underscore prefix + camelCase).
- Exemplos: `_repository`, `_unitOfWork`, `_logger`.

---

## Parâmetros e Variáveis Locais

- `camelCase`.
- Exemplos: `accountId`, `cancellationToken`, `order`.

---

## Constantes

- `PascalCase` para constantes públicas (convenção .NET).
- Exemplos: `MaxRetryAttempts`, `DefaultTimeoutMs`.

---

## Enums

- `PascalCase` para o tipo e membros. Singular para o nome.
- Para compra/venda, usar enum `Side` com valores `Buy`/`Sell` (Guia de Nomeação).

```csharp
public enum OrderStatus { Pending, Confirmed, Cancelled, Executed }
public enum Side { Buy, Sell }
```

---

## Endpoints (URLs)

- `kebab-case` para segmentos de URL.
- Plural para coleções: `/portfolios`, `/orders`.
- Prefixo de API: `/api/v1/`.
- Parâmetros em `camelCase` no path: `{accountId}`, `{orderId}`.

---

## Glossário de Termos Financeiros (Guia de Nomeação)

| Conceito | Termo padrão no código | Evitar |
|---|---|---|
| Cotação de mercado | `price` | `valor`, `cotacao` |
| Soma financeira | `amount` ou `value` | `price` (para somas) |
| Compra/Venda | Enum `Side` (`Buy`/`Sell`) | `type`, `direction` |
| Ativo | `asset` ou `instrument` | `product` |
| Código do ativo | `symbol` ou `ticker` | `code`, `name` |
| Patrimônio/Ação | `equity` | `patrimonio` |
| Ordem | `order` | `pedido`, `solicitacao` |

---

## Tipagem para Valores Financeiros

**Regra absoluta:** Nunca usar `float` ou `double` para valores monetários.

| Contexto | Tipo |
|---|---|
| Código C# | `decimal` |
| Banco de dados | `DECIMAL(18, 8)` |
| JSON serialization | `string` ou `number` (com precisão) |

---

## Testes

- Classe de teste: `{ClassUnderTest}Tests` — `OrderTests`, `CreateOrderCommandHandlerTests`.
- Métodos de teste: `{Method}_{Scenario}_{ExpectedResult}`:
  - `Create_WithValidData_ReturnsOrder`
  - `Create_WithNegativeQuantity_ThrowsDomainException`
  - `Handle_WhenOrderNotFound_ReturnsNotFound`

---

## O que Evitar

- Nomes genéricos sem contexto: `Data`, `Info`, `Manager`, `Helper`.
- Abreviações obscuras: `Prtf` em vez de `Portfolio`, `Ord` em vez de `Order`.
- Prefixos húngaros: `strName`, `intCount`.
- Sufixo `Impl`: usar nome descritivo.
- Misturar português e inglês no mesmo identificador.
- `float`/`double` para valores monetários.

---

## Referências

- [RFC-002 – Padrão Steering File para backend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/192806913)
- [Guia de Padrões de Nomeação para Serviços Financeiros e Trading](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/122191873)
- [Microsoft – C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)

---

*Versão: 0.2.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
