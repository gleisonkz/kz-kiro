---
inclusion: fileMatch
fileMatchPattern: "**/*Configuration.cs,**/*DbContext.cs,**/Migrations/**,**/*Entity*.cs"
---

# Governança de Dados — Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 2.0.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos de serviços de domínio .NET/C#.
> Ele define os padrões de modelagem de dados exigidos pelo chapter de dados da Monte Bravo.
>
> Baseado em: Governança de Dados (Confluence), Regras de Nomenclatura, Modelagem Transacional

---

## Princípio Fundamental: Duas Camadas, Duas Convenções

O código C# e o banco de dados possuem convenções distintas. O EF Core faz a ponte entre elas.

| Camada | Convenção | Exemplo |
|---|---|---|
| Código C# (propriedades, classes) | `PascalCase` (.NET standard) | `CustomerId`, `BirthDate`, `TotalAmount` |
| Banco de dados (tabelas e colunas) | `snake_case` com sufixo de natureza (ISO/IEC 11179) | `customer_id`, `birth_date`, `total_amount_brl` |

---

## Nomenclatura de Databases

| Aspecto | Regra |
|---|---|
| Padrão | `{produto}_{termo}` |
| Exemplo | `financial_transfer` |
| Banco recomendado (AWS) | Aurora PostgreSQL / PostgreSQL |

---

## Nomenclatura de Tabelas

| Aspecto | Regra |
|---|---|
| Idioma | Inglês |
| Número | Plural (preferencialmente) |
| Case | `snake_case` |
| Termos | 1 a 3 termos, privilegiando clareza |
| Exemplo (transacional) | `customers`, `invoices`, `tax_invoices`, `fixed_incomes` |

### Tabelas Dimensionais (referência — escopo do time de dados)

| Tipo | Padrão | Exemplo |
|---|---|---|
| Fato | `fact_{name}_{name}` | `fact_customers` |
| Dimensão | `dim_{name}_{name}` | `dim_cities` |
| OBT | `obt_{name}_{name}_{name}` | `obt_performance_advisors` |

---

## Nomenclatura de Colunas (ISO/IEC 11179)

Na Monte Bravo o nome das colunas deve estar em inglês, no singular. Mínimo de 2 termos privilegiando clareza. O **sufixo** obrigatório é o `representation_term` (natureza).

| Aspecto | Regra |
|---|---|
| Idioma | Inglês |
| Case | `snake_case` |
| Sufixo de natureza | Obrigatório |
| Formato | `{name}_{name}_{representation_term}` |
| Exemplo | `birth_date`, `customer_name`, `total_amount_brl` |

---

## Termos de Natureza — Sufixos Obrigatórios (Representation Terms)

### 1. Identificadores e Chaves

| Sufixo | Significado | Usar quando | Exemplos |
|---|---|---|---|
| `_id` | Identifier | Chaves primárias e estrangeiras (UUID, numérico) | `customer_id`, `product_id` |
| `_code` | Code | Códigos legíveis ou chaves de negócio de sistemas externos | `flight_code`, `iso_currency_code` |
| `_number` | Number | Identificadores numéricos de negócio (não entram em cálculos) | `invoice_number`, `document_number` |

### 2. Textos e Descrições

| Sufixo | Significado | Usar quando | Exemplos |
|---|---|---|---|
| `_name` | Name | Nome próprio de entidades, pessoas, produtos | `first_name`, `company_name` |
| `_description` | Description | Textos descritivos longos ou explicações | `product_description`, `error_description` |
| `_text` | Text | Conteúdos textuais genéricos, notas, corpos de mensagem | `comment_text`, `internal_note_text` |

### 3. Temporais (Datas e Horas)

| Sufixo | Significado | Usar quando | Exemplos |
|---|---|---|---|
| `_date` | Date | Apenas data de calendário (ano, mês, dia) | `birth_date`, `expiration_date` |
| `_time` | Time | Apenas horário ou duração | `start_time`, `duration_time` |
| `_at` / `_timestamp` | Timestamp | Momento exato (data + hora + timezone). `_at` preferido para auditoria | `created_at`, `updated_at`, `login_timestamp` |

### 4. Valores Quantitativos e Métricas

| Sufixo | Significado | Usar quando | Exemplos |
|---|---|---|---|
| `_amount` | Amount/Value | Valores monetários ou financeiros (requer moeda ISO 4217) | `total_amount_brl`, `discount_amount_usd` |
| `_quantity` | Quantity | Contagem numérica de unidades ou itens | `item_quantity`, `stock_quantity` |
| `_percentage` / `_rate` | Percentage/Rate | Valores percentuais, taxas ou proporções | `tax_percentage`, `interest_rate` |
| `_measure` | Measure/Unit | Grandezas físicas (peso, altura, volume) | `package_weight_measure`, `package_weight_kg` |

### 5. Estados, Classificações e Lógicas

| Sufixo | Significado | Usar quando | Exemplos |
|---|---|---|---|
| `_status` | Status/State | Etapa ou estado atual em um fluxo de trabalho | `order_status`, `user_status` |
| `_type` | Type/Category | Classificação ou categorização de registro | `payment_type`, `customer_type` |
| `is_` / `has_` (prefixo) | Indicator/Boolean | Campos binários (verdadeiro/falso) | `is_active`, `has_delivery`, `is_verified` |

---

## Valores Monetários — ISO 4217

**Regra absoluta:** Nunca usar `float` ou `double` para valores monetários.

Atributos monetários **devem** estar associados a um identificador de moeda no padrão ISO 4217:
- Como sufixo no nome da coluna: `total_amount_brl`, `discount_amount_usd`
- Ou como atributo separado indicando a moeda de todos os valores do registro

| Contexto | Tipo | Precisão |
|---|---|---|
| Código C# | `decimal` | — |
| Banco de dados | `DECIMAL(18, 8)` | `HasPrecision(18, 8)` |

Moedas comuns: `BRL`, `USD`, `EUR`, `JPY`, `GBP`, `AUD`, `CAD`, `CHF`, `CNY`, `HKD`, `NZD`

---

## Campos de Auditoria Obrigatórios

Toda tabela **deve** conter os seguintes campos de auditoria:

| Campo | Tipo | Obrigatório | Conceito |
|---|---|---|---|
| `created_at` | TIMESTAMP | NOT NULL | Momento de criação do registro na tabela |
| `updated_at` | TIMESTAMP | NULL | Momento de alteração do registro na tabela |
| `deleted_at` | TIMESTAMP | NULL | Momento da exclusão lógica do registro (quando aplicável) |
| `is_deleted` | BOOLEAN | NOT NULL | Indicador de registro excluído logicamente. Campo calculado |

### Deleção Lógica

Quando a tabela utiliza deleção lógica, `is_deleted` deve ser um campo **calculado** com base em `deleted_at`:

```sql
-- PostgreSQL
is_deleted boolean NOT NULL GENERATED ALWAYS AS (deleted_at IS NOT NULL) STORED
```

Em EF Core, configurar como computed column:

```csharp
builder.Property(e => e.IsDeleted)
    .HasColumnName("is_deleted")
    .HasComputedColumnSql("deleted_at IS NOT NULL", stored: true)
    .HasComment("Indicador de registro excluído logicamente. Campo calculado em relação ao preenchimento do atributo deleted_at.");
```

---

## Comments Obrigatórios (pt-BR)

Toda tabela e coluna **deve** ter um comment/conceito em português do Brasil usando `HasComment()`:

```csharp
builder.ToTable("transfers")
    .HasComment("Transferências financeiras entre contas de clientes.");

builder.Property(t => t.TotalAmount)
    .HasColumnName("total_amount_brl")
    .HasComment("Valor total da transferência em reais (BRL)");
```

O comment deve responder:
- O que é?
- Para que serve?
- Regras de negócio específicas (quando aplicável)

---

## Convenções de Constraints e Índices

| Artefato | Padrão de nomenclatura | Exemplo |
|---|---|---|
| Primary Key | `pk_{tabela}` | `pk_transfers` |
| Foreign Key | `fk_{tabela_origem}_{tabela_destino}` | `fk_transfer_items_transfers` |
| Índice | `ix_{tabela}_{coluna(s)}` | `ix_transfers_customer_id` |
| Unique | `uk_{tabela}_{coluna(s)}` | `uk_customers_document_number` |
| Alternate Key | `ak_{tabela}_{coluna(s)}` | `ak_accounts_external_code` |

---

## Propagação de Atributos Equivalentes

Atributos que se repetem em tabelas diferentes dentro de um mesmo banco de dados **devem** manter o mesmo padrão:
- Mesmo datatype e tamanho
- Mesma definição no metadado "Comment"
- Mesma formatação (quando aplicável)

O processo de validação verifica ocorrência de repetições e aponta falta de padronização.

Exemplos de atributos padronizados que devem ser propagados:

| Nome | Datatype | Descrição (Comment) | Formatação |
|---|---|---|---|
| `reference_month` | varchar(7) | Mês de referência \<complemento\>. | YYYY-MM |
| `created_at` | timestamp | Momento de criação do registro na tabela. | — |
| `updated_at` | timestamp | Momento de alteração do registro na tabela. | — |
| `deleted_at` | timestamp | Momento da exclusão lógica do registro na tabela. | — |
| `is_deleted` | boolean | Indicador de registro excluído logicamente. Campo calculado em relação ao preenchimento do atributo "deleted_at". | — |

---

## Normalização

- Modelos transacionais devem estar em **3ª Forma Normal (3FN)**.
- Desnormalização é aceita apenas com justificativa documentada e aprovação do chapter.

---

## Migrations como Versionamento

As migrations do EF Core servem como **versionamento** do modelo de dados:

- Migrations **NÃO são executadas automaticamente** pelo serviço.
- O fluxo correto é:

```
Dev gera migration → Submete para validação → Chapter aprova → DBA executa no banco
```

- Manter migrations no repositório como histórico de alterações.
- Usar como insumo para o DBA na criação/alteração de objetos.

---

## Escopo: Apenas Modelo Transacional

O archetype `backend-csharp` foca **apenas no modelo transacional**. Modelos dimensionais
(fato, dimensão, OBT) são responsabilidade do time de dados/analytics.

---

## Exemplo Completo de Entity Configuration

```csharp
public class TransferConfiguration : IEntityTypeConfiguration<Transfer>
{
    public void Configure(EntityTypeBuilder<Transfer> builder)
    {
        builder.ToTable("transfers")
            .HasComment("Transferências financeiras entre contas de clientes.");

        builder.HasKey(t => t.Id)
            .HasName("pk_transfers");

        builder.Property(t => t.Id)
            .HasColumnName("transfer_id")
            .HasComment("Identificador único da transferência");

        builder.Property(t => t.SourceAccountId)
            .HasColumnName("source_account_id")
            .IsRequired()
            .HasComment("Identificador da conta de origem da transferência");

        builder.Property(t => t.TargetAccountId)
            .HasColumnName("target_account_id")
            .IsRequired()
            .HasComment("Identificador da conta de destino da transferência");

        builder.Property(t => t.TotalAmount)
            .HasColumnName("total_amount_brl")
            .HasPrecision(18, 8)
            .HasComment("Valor total da transferência em reais (BRL)");

        builder.Property(t => t.Status)
            .HasColumnName("transfer_status")
            .HasConversion<string>()
            .HasComment("Situação da transferência: Pending, Approved, Executed, Cancelled");

        builder.Property(t => t.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired()
            .HasComment("Momento de criação do registro na tabela");

        builder.Property(t => t.UpdatedAt)
            .HasColumnName("updated_at")
            .HasComment("Momento de alteração do registro na tabela");

        builder.Property(t => t.DeletedAt)
            .HasColumnName("deleted_at")
            .HasComment("Momento da exclusão lógica do registro na tabela");

        builder.Property(t => t.IsDeleted)
            .HasColumnName("is_deleted")
            .HasComputedColumnSql("deleted_at IS NOT NULL", stored: true)
            .HasComment("Indicador de registro excluído logicamente. Campo calculado.");

        // Foreign Keys
        builder.HasMany(t => t.Items)
            .WithOne(i => i.Transfer)
            .HasForeignKey(i => i.TransferId)
            .HasConstraintName("fk_transfer_items_transfers");

        // Índices
        builder.HasIndex(t => t.SourceAccountId)
            .HasDatabaseName("ix_transfers_source_account_id");

        builder.HasIndex(t => t.TargetAccountId)
            .HasDatabaseName("ix_transfers_target_account_id");
    }
}
```

---

## Processo de Validação

A validação deve ser solicitada através da abertura de chamado no Jira com tipo de serviço **"Validação de Modelo de Dados"**.

### O que é validado em um modelo transacional?

- Normalização do modelo em 3ª Forma Normal
- Nomenclatura de tabelas (entidades) e colunas (atributos) conforme regras de nomenclatura
- Clareza de comentários (conceitos) de tabelas e colunas
- Chaves PK, FK, AK e UK
- Propagação de atributos equivalentes

### Artefatos a anexar no chamado

| Artefato | Obrigatoriedade |
|---|---|
| Script DDL | Obrigatório |
| Diagrama de dados (DrawSQL, DBeaver ou DrawIO) | Opcional (para apoio na análise) |

### SLA

1/2 Sprint — 1 Semana

Pode ser solicitada reunião para apresentação do modelo ou esclarecimento de dúvidas durante o processo de validação.

---

## Referências

- [Governança de Dados - Confluence](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/239271938)
- [Regras de Nomenclatura](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/273219626)
- [Modelagem de Dados Transacional](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/273383425)
- [Processo de Validação de Modelo de Dados](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/273219644)

---

*Versão: 2.0.0 | Última revisão: 2026-08 | Próxima revisão: TODO*
