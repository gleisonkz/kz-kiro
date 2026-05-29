---
name: "Gerar Pacote de Validação"
description: "Gera o pacote completo para submissão ao chapter de dados: DDL com comments, dicionário de dados, diagrama ER e checklist de validação."
inclusion: manual
---

# Gerar Pacote de Validação

## Quando usar

Quando o modelo de dados estiver pronto para submissão ao chapter de dados para validação. Este skill gera todos os artefatos que o chapter espera receber.

## Inputs esperados

- **Domínio** (obrigatório): nome do bounded context (ex.: `Transfers`, `Portfolio`).
- **Caminho das Configurations** (opcional): caminho para os arquivos `*Configuration.cs` do domínio. Se não informado, buscar em `src/{ServiceName}.Infrastructure/Persistence/Configurations/`.

## Regras de geração

### Referências obrigatórias

- **Steering:** `data-governance.md` — regras de nomenclatura e prefixos.
- Ler TODOS os arquivos `*Configuration.cs` do domínio para extrair o modelo.

### Processo

1. Ler todas as Entity Configurations do domínio.
2. Extrair: tabelas, colunas, tipos, comments, constraints, índices.
3. Gerar os 4 artefatos de saída.
4. Validar conformidade com checklist.

## Outputs gerados

### 1. Script DDL (`docs/database/{domain}/ddl.sql`)

Gerar DDL PostgreSQL completo com:

```sql
-- =============================================================================
-- Modelo de Dados: {Domain}
-- Gerado em: {data}
-- Serviço: {ServiceName}
-- =============================================================================

-- Tabela: {nome_tabela}
-- Conceito: {comment da tabela}
CREATE TABLE {nome_tabela} (
    {coluna}    {tipo}    {nullable},
    -- ... demais colunas

    CONSTRAINT pk_{tabela} PRIMARY KEY ({pk_coluna})
);

-- Comments
COMMENT ON TABLE {nome_tabela} IS '{comment em pt-BR}';
COMMENT ON COLUMN {nome_tabela}.{coluna} IS '{comment em pt-BR}';

-- Foreign Keys
ALTER TABLE {tabela_origem}
    ADD CONSTRAINT fk_{origem}_{destino}
    FOREIGN KEY ({coluna_fk}) REFERENCES {tabela_destino} ({coluna_pk});

-- Índices
CREATE INDEX ix_{tabela}_{coluna} ON {tabela} ({coluna});
```

### 2. Dicionário de Dados (`docs/database/{domain}/data-dictionary.md`)

```markdown
# Dicionário de Dados — {Domain}

> Gerado em: {data} | Serviço: {ServiceName}

## {NomeTabela}

**Conceito:** {comment da tabela em pt-BR}

| # | Atributo | Natureza | Tipo | Conceito | Constraint |
|---|---|---|---|---|---|
| 1 | {coluna} | {prefixo} | {tipo} | {comment} | {PK/FK/NOT NULL/—} |
| 2 | ... | ... | ... | ... | ... |

### Índices

| Nome | Colunas | Tipo |
|---|---|---|
| ix_{tabela}_{coluna} | {coluna} | INDEX |

### Relacionamentos

| FK | Tabela Origem | Coluna | Tabela Destino | Coluna |
|---|---|---|---|---|
| fk_{origem}_{destino} | {origem} | {coluna} | {destino} | {coluna} |
```

### 3. Diagrama ER (`docs/database/{domain}/er-diagram.md`)

```markdown
# Diagrama ER — {Domain}

> Gerado em: {data} | Serviço: {ServiceName}

\```mermaid
erDiagram
    {tabela1} ||--o{ {tabela2} : "{relação}"

    {tabela1} {
        {tipo} {coluna} {constraint}
    }
\```
```

### 4. Checklist de Validação (`docs/database/{domain}/validation-checklist.md`)

```markdown
# Checklist de Validação — {Domain}

> Serviço: {ServiceName} | Data: {data}
> Submeter para: chapter de dados (warner.souza@montebravo.com.br)

## Conformidade com Padrões

- [ ] Modelo em 3ª Forma Normal (3FN)
- [ ] Nomenclatura de tabelas: `snake_case`, singular, inglês
- [ ] Nomenclatura de colunas: `{prefixo_natureza}_{nome}` em `snake_case`
- [ ] Conceitos (comments) em pt-BR para todas as tabelas
- [ ] Conceitos (comments) em pt-BR para todas as colunas
- [ ] Chaves primárias (PK) definidas para todas as tabelas
- [ ] Chaves estrangeiras (FK) definidas para todos os relacionamentos
- [ ] Tipos de dados adequados (decimal para monetário, nunca float/double)
- [ ] Campos de auditoria presentes (`tmp_creation`, `tmp_update`)
- [ ] Índices definidos para colunas de busca frequente
- [ ] Constraints nomeadas seguindo padrão (`pk_`, `fk_`, `ix_`, `uk_`)

## Artefatos Incluídos

- [ ] Script DDL (`ddl.sql`)
- [ ] Dicionário de dados (`data-dictionary.md`)
- [ ] Diagrama ER (`er-diagram.md`)

## Observações

{Espaço para observações do desenvolvedor sobre decisões de modelagem}
```

## Instruções pós-geração

Após gerar o pacote, informar ao desenvolvedor:

> **Pacote de validação gerado com sucesso!**
>
> Artefatos criados em `docs/database/{domain}/`:
> - `ddl.sql` — Script DDL para o DBA
> - `data-dictionary.md` — Dicionário de dados
> - `er-diagram.md` — Diagrama ER em Mermaid
> - `validation-checklist.md` — Checklist de validação
>
> **Próximos passos:**
> 1. Revise o checklist de validação
> 2. Envie o pacote para o chapter de dados para validação
> 3. Aguarde aprovação (SLA: 1 semana)
> 4. Após aprovação, solicite execução do DDL ao DBA
>
> **Importante:** As migrations NÃO devem ser executadas automaticamente pelo serviço.
> Elas servem apenas como versionamento do modelo.
