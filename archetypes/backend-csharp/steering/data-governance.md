---
inclusion: fileMatch
fileMatchPattern: "**/*Configuration.cs,**/*DbContext.cs,**/Migrations/**,**/*Entity*.cs"
---

# Governança de Dados — Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 1.0.0**
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
| Código C# (propriedades, classes) | `PascalCase` (.NET standard) | `BlogId`, `CustomerName`, `BirthDate` |
| Banco de dados (tabelas e colunas) | `snake_case` com prefixo de natureza | `id_blog`, `nm_customer`, `dt_birth` |

---

## Nomenclatura de Tabelas

| Aspecto | Regra |
|---|---|
| Idioma | Inglês |
| Número | Singular |
| Case | `snake_case` |
| Exemplo | `customer`, `tax_invoice`, `transfer_item` |

---

## Nomenclatura de Colunas

| Aspecto | Regra |
|---|---|
| Idioma | Inglês |
| Case | `snake_case` |
| Prefixo de natureza | Obrigatório |
| Formato | `{prefixo_natureza}_{nome}` |
| Exemplo | `nm_customer`, `dt_birth`, `vl_amount`, `id_transfer` |

---

## Tabela de Naturezas (Prefixos Obrigatórios)

| Prefixo | Significado | Usar quando | Tipos comuns |
|---|---|---|---|
| `nm` | Nome | Valores que nomeiam (pessoa, produto) | varchar |
| `cd` | Código | Códigos numéricos ou string | int, varchar |
| `ds` | Descrição | Valores descritivos longos | varchar(max) |
| `dt` | Data | Valores de data (sem hora) | date |
| `hr` | Hora | Valores de hora (sem data) | time |
| `tmp` | Timestamp | Data e hora combinados | timestamp |
| `vl` | Valor | Valores monetários | decimal |
| `qt` | Quantidade | Valores quantitativos | float, decimal |
| `pc` | Percentual | Valores percentuais | float, decimal |
| `id` | Identificador | IDs sistêmicos, PKs, FKs | integer, uuid |
| `st` | Situação/Status | Status com até 9 valores distintos | integer |
| `nu` | Número | Numéricos não decimais | integer |
| `in` | Indicador | Valores discretos (flags, enums curtos) | integer, char |
| `sk` | Surrogate Key | Chaves em dimensões (modelo dimensional) | integer |

---

## Campos de Auditoria Obrigatórios

Toda tabela **deve** conter os seguintes campos de auditoria:

| Campo | Tipo | Obrigatório | Conceito |
|---|---|---|---|
| `tmp_creation` | TIMESTAMP | NOT NULL | Data e hora da criação do registro |
| `tmp_update` | TIMESTAMP | NULL | Data e hora da última atualização do registro |

---

## Comments Obrigatórios (pt-BR)

Toda tabela e coluna **deve** ter um comment/conceito em português do Brasil usando `HasComment()`:

```csharp
builder.ToTable("transfer")
    .HasComment("Transferência financeira entre contas de clientes.");

builder.Property(t => t.Amount)
    .HasColumnName("vl_amount")
    .HasComment("Valor total da transferência em reais");
```

O comment deve responder:
- O que é?
- Para que serve?
- Regras de negócio específicas (quando aplicável)

---

## Convenções de Constraints e Índices

| Artefato | Padrão de nomenclatura | Exemplo |
|---|---|---|
| Primary Key | `pk_{tabela}` | `pk_transfer` |
| Foreign Key | `fk_{tabela_origem}_{tabela_destino}` | `fk_transfer_item_transfer` |
| Índice | `ix_{tabela}_{coluna(s)}` | `ix_transfer_id_source_account` |
| Unique | `uk_{tabela}_{coluna(s)}` | `uk_customer_cd_document` |
| Alternate Key | `ak_{tabela}_{coluna(s)}` | `ak_account_cd_external` |

---

## Valores Monetários

**Regra absoluta:** Nunca usar `float` ou `double` para valores monetários.

| Contexto | Tipo | Precisão |
|---|---|---|
| Código C# | `decimal` | — |
| Banco de dados | `DECIMAL(18, 8)` | `HasPrecision(18, 8)` |

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
        builder.ToTable("transfer")
            .HasComment("Transferência financeira entre contas de clientes.");

        builder.HasKey(t => t.Id)
            .HasName("pk_transfer");

        builder.Property(t => t.Id)
            .HasColumnName("id_transfer")
            .HasComment("Identificador único da transferência");

        builder.Property(t => t.SourceAccountId)
            .HasColumnName("id_source_account")
            .IsRequired()
            .HasComment("Identificador da conta de origem da transferência");

        builder.Property(t => t.TargetAccountId)
            .HasColumnName("id_target_account")
            .IsRequired()
            .HasComment("Identificador da conta de destino da transferência");

        builder.Property(t => t.Amount)
            .HasColumnName("vl_amount")
            .HasPrecision(18, 8)
            .HasComment("Valor total da transferência em reais");

        builder.Property(t => t.Status)
            .HasColumnName("st_transfer")
            .HasConversion<int>()
            .HasComment("Situação da transferência: 1=Pendente, 2=Aprovada, 3=Executada, 4=Cancelada");

        builder.Property(t => t.CreatedAt)
            .HasColumnName("tmp_creation")
            .IsRequired()
            .HasComment("Data e hora da criação do registro");

        builder.Property(t => t.UpdatedAt)
            .HasColumnName("tmp_update")
            .HasComment("Data e hora da última atualização do registro");

        // Foreign Keys
        builder.HasMany(t => t.Items)
            .WithOne(i => i.Transfer)
            .HasForeignKey(i => i.TransferId)
            .HasConstraintName("fk_transfer_item_transfer");

        // Índices
        builder.HasIndex(t => t.SourceAccountId)
            .HasDatabaseName("ix_transfer_id_source_account");

        builder.HasIndex(t => t.TargetAccountId)
            .HasDatabaseName("ix_transfer_id_target_account");
    }
}
```

---

## Processo de Validação

Antes de solicitar execução ao DBA, o modelo deve ser validado pelo chapter de dados:

1. Gerar o pacote de validação (DDL + Dicionário + Diagrama ER + Checklist)
2. Enviar para validação do chapter de dados
3. SLA de validação: 1 semana
4. Após aprovação, DBA executa o DDL no banco

---

## Referências

- [Governança de Dados - Confluence](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/239271938)
- [Regras de Nomenclatura](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/273219626)
- [Modelagem de Dados Transacional](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/273383425)
- [Processo de Validação de Modelo de Dados](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/273219644)

---

*Versão: 1.0.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
