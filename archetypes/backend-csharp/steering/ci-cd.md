---
inclusion: fileMatch
fileMatchPattern: "**/.github/**,**/Dockerfile*,**/docker-compose*,**/*.yml,**/terraform/**"
---

# Pipelines e Deploy — Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos de serviços de domínio .NET/C#.
> Ele define a estratégia de CI/CD, pipelines e deploy para serviços backend.
>
> Baseado em: RFC-002 (Padrão Steering File para backend)

---

## Princípios de CI/CD

1. **Deploy independente**: cada serviço pode ser deployado separadamente dos demais.
2. **Imutabilidade**: cada build gera um artefato imutável (container image ou Lambda package).
3. **Rollback rápido**: deploys devem ser reversíveis em menos de 5 minutos.
4. **Zero downtime**: deploys não devem causar indisponibilidade.
5. **Migrations seguras**: migrations de banco devem ser backward-compatible.

---

## Pipeline Preferido (RFC-002)

### Ferramentas

| Prioridade | Ferramenta |
|---|---|
| 1ª opção | GitHub Actions |
| 2ª opção | AWS CodePipeline |

### Steps obrigatórios (RFC-002)

1. **Build** (`dotnet build`).
2. **Test** (`dotnet test`).
3. **Security Scan** (análise de vulnerabilidades em dependências).
4. **Deploy**.

### O que o CI deve executar em todo PR

1. Restore de dependências (`dotnet restore`).
2. Build (`dotnet build --no-restore`).
3. Formatação (`dotnet format --verify-no-changes`).
4. Testes unitários (`dotnet test --filter Category=Unit`).
5. Testes de integração (`dotnet test --filter Category=Integration`).
6. Análise de segurança (`dotnet list package --vulnerable`).
7. Cobertura de código (threshold: 80%).

### O que o CI deve executar no merge em main

- Tudo acima.
- Build do artefato (container image ou Lambda package).
- Push para registry/S3.
- Execução de migrations em ambiente `dev`.
- Deploy automático para ambiente `dev`.

### O que o CI deve executar para release

- Tudo acima.
- Deploy para `hml` com aprovação.
- Smoke tests no ambiente `hml`.
- Deploy para `prod` com aprovação.

---

## Review Rules (RFC-002)

O CI deve **bloquear merge** se:

| Condição | Ação |
|---|---|
| `missing_tests` | Código novo sem testes correspondentes |
| `security_violation` | Vulnerabilidade detectada em dependências |
| `breaking_change_without_note` | Breaking change sem documentação |
| `no_async_usage` | Operação I/O sem async/await |

---

## Ambientes

| Ambiente | Propósito | Deploy |
|---|---|---|
| `dev` | Desenvolvimento e integração | Automático no merge em main |
| `hml` | Homologação e testes de aceitação | Manual com aprovação |
| `prod` | Produção | Manual com aprovação |

---

## Deploy Targets

### AWS Lambda (preferido)

- Runtime: `dotnet8` com ARM64 (RFC-002).
- Package: ZIP ou container image.
- Cold start otimizado com Native AOT quando possível.
- API Gateway como trigger HTTP.

### ECS Fargate (quando Lambda não é viável)

- Para serviços long-running ou stateful.
- Mínimo 2 tasks em produção.
- Auto-scaling baseado em CPU/memória.

---

## Migrations de Banco de Dados

### Regras de segurança para migrations

1. **Backward-compatible**: migrations devem ser compatíveis com a versão anterior do código.
2. **Separar schema de dados**: alterações de schema em uma migration, dados em outra.
3. **Nunca dropar colunas diretamente**: marcar como nullable primeiro, remover em release posterior.
4. **Testar rollback**: toda migration deve ter `Down()` funcional.
5. **Executar antes do deploy**: migrations rodam antes do novo código ser deployado.

### Padrão de migration segura (expand-contract)

```
Release N:   Adicionar nova coluna (nullable)
Release N+1: Código usa nova coluna, popula dados
Release N+2: Remover coluna antiga (se aplicável)
```

---

## Variáveis de Ambiente e Segredos

- Injetados via AWS Secrets Manager ou SSM Parameter Store.
- Connection strings e segredos nunca hardcoded.
- Usar `IOptions<T>` pattern para configuração tipada.
- Tags obrigatórias em recursos AWS: `environment`, `application`, `owner`.

---

## Monitoramento Pós-Deploy

Após cada deploy em produção, monitorar por 15 minutos:

- Taxa de erro (deve permanecer < 1%).
- Latência p99 (não deve aumentar > 20%).
- Health check respondendo 200.
- Logs sem erros críticos (CloudWatch).
- Migrations executadas com sucesso.

Se algum threshold for violado: rollback automático.

---

## Documentação Obrigatória (RFC-002)

Todo projeto deve gerar/manter:

| Documento | Idioma | Descrição |
|---|---|---|
| `README.md` | pt-BR | Como rodar, dependências, variáveis de ambiente |
| `arquitetura.md` | pt-BR | Decisões arquiteturais, diagramas, bounded context |
| `endpoints.md` | pt-BR | Documentação dos endpoints (complementar ao Swagger) |

---

## Referências

- [RFC-002 – Padrão Steering File para backend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/192806913)
- [ADR-001 – Padrão arquitetural de comunicação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517)

---

*Versão: 0.2.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
