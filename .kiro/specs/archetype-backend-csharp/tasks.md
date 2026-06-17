# Implementation Plan: Archetype Backend C#

## Overview

Este plano cobre as tarefas de validação e teste do archetype `backend-csharp` — um archetype já implementado. O foco é garantir conformidade com os requisitos via testes de propriedade, unitários e de integração usando bats-core, seguindo o mesmo padrão das specs `archetype-frontend-react` e `archetype-bff-fastify`. Não há implementação de funcionalidades novas; apenas validação estrutural, testes automatizados e documentação de gaps.

## Tasks

- [x] 1. Validar conformidade estrutural do archetype existente
  - [x] 1.1 Validar estrutura de diretórios e artefatos obrigatórios
    - Verificar que `steering/`, `hooks/`, `agents/`, `skills/` e `mcp/` existem com artefatos funcionais + README.md (exceto `mcp/`)
    - Verificar que `VERSION` e `CHANGELOG.md` estão na raiz do archetype
    - Verificar que `README.md` existe na raiz e em cada diretório de categoria (`steering/`, `hooks/`, `agents/`, `skills/`)
    - Verificar contagens: 5 steering `.md` (excl. README), 7 hooks `.kiro.hook`, 5 skills `.md` (excl. README), 1 `mcp.json`, agents apenas com README
    - Documentar gaps encontrados (artefatos ausentes ou extras vs design)
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_
  - [x] 1.2 Validar conformidade do VERSION e CHANGELOG.md
    - Verificar formato semver no VERSION (sem prefixo `v`, sem espaços, sem trailing newline)
    - Verificar que CHANGELOG.md tem entrada correspondente à versão do VERSION
    - Verificar formato de cabeçalho `## MAJOR.MINOR.PATCH (YYYY-MM-DD)` e seções válidas
    - _Requisitos: 1.6, 1.7, 11.1, 11.2_
  - [x] 1.3 Validar conformidade dos steering files (sem frontmatter YAML)
    - Verificar que `stack-and-tooling.md`, `architecture.md`, `naming-conventions.md`, `ci-cd.md`, `data-governance.md` e `README.md` existem em `steering/`
    - Verificar que steering files NÃO possuem frontmatter YAML (iniciam com `#`, não com `---`)
    - Verificar blockquote de identificação no topo: `Steering File | Archetype: backend-csharp | Versão: X.Y.Z`
    - Verificar que `data-governance.md` é exclusivo (não existe em bff-fastify nem frontend-react)
    - _Requisitos: 1.1, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_
  - [x] 1.4 Validar conformidade dos hooks (schema JSON e triggers)
    - Verificar que todos os 7 hooks têm `enabled: true`, schema JSON válido
    - Verificar triggers: `agentStop` para build/domain-boundaries/endpoint-quality, `preToolUse` para review-data-model, `postToolUse` para migration-reminder, `postTaskExecution` para run-tests, `userTriggered` para doctor
    - Verificar `toolTypes: ["write"]` nos hooks preToolUse e postToolUse
    - Verificar tipos de ação: `askAgent` (6 hooks) e `runCommand` (run-tests)
    - Verificar versões: `"2"` para hooks agentStop e postTaskExecution, `"1"` para preToolUse/postToolUse/userTriggered
    - _Requisitos: 3.1, 4.1, 4.2, 5.1, 5.2, 6.1, 7.1_
  - [x] 1.5 Validar conformidade das skills (frontmatter YAML)
    - Verificar que 5 skills têm frontmatter com `name` (string não-vazia, pt-BR), `description` (string não-vazia) e `inclusion: manual`
    - Verificar que `generate-module.md`, `generate-endpoint.md`, `generate-repository.md`, `generate-data-model.md` e `generate-validation-package.md` existem
    - _Requisitos: 1.4, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_
  - [x] 1.6 Validar conformidade do mcp.json
    - Verificar schema: `_comment` não-vazio mencionando archetype backend-csharp e merge com baseline, `_version` em formato semver, `mcpServers` objeto vazio (`{}`)
    - _Requisitos: 9.1, 9.2_
  - [x] 1.7 Validar conformidade do diretório agents/
    - Verificar que apenas `README.md` existe em `agents/` — nenhum agent funcional
    - Verificar que README lista 5 agents planejados: domain-modeler, architecture-reviewer, api-designer, test-writer, migration-reviewer
    - _Requisitos: 10.1, 10.2, 10.3_

- [x] 2. Checkpoint — Validação estrutural completa
  - Garantir que todos os artefatos estão conformes, perguntar ao usuário se surgirem dúvidas.

- [x] 3. Implementar testes unitários do archetype
  - [x] 3.1 Criar teste unitário para steering files
    - Verificar existência dos 5 arquivos de steering + README com nomes corretos
    - Verificar conteúdo de `stack-and-tooling.md`: seções de stack base obrigatória (.NET 8, C# 12, Minimal APIs, EF Core 8, PostgreSQL, FluentValidation, MediatR, Wolverine, Serilog, Polly, xUnit), infra AWS (Lambda ARM64, API Gateway, RDS), justificativa Minimal APIs, justificativa Wolverine/Outbox RFC-003, .csproj config, Program.cs, Docker, segurança RFC-002, tecnologias descartadas
    - Verificar conteúdo de `architecture.md`: seções de papel do serviço de domínio, princípios (Bounded Context, Database per Service, mensageria, Outbox/Inbox, CQRS, Dependency Rule), padrões RFC-001, comunicação ADR-001, Outbox/Inbox RFC-003, CQRS MediatR, DDD, persistência EF Core + PostgreSQL, resiliência Polly, observabilidade, health checks, glossário financeiro
    - Verificar conteúdo de `naming-conventions.md`: tabela com 14+ prefixos de natureza (id, nm, cd, ds, dt, hr, tmp, vl, qt, pc, st, nu, in, sk), tabela de sufixos com 20+ tipos, regras de banco snake_case, regras C# PascalCase, campos _camelCase, endpoints kebab-case
    - Verificar conteúdo de `ci-cd.md`: seções de princípios, pipeline GitHub Actions/CodePipeline, steps PR/merge/release, review rules bloqueantes, ambientes dev/hml/prod, Lambda ARM64/ECS Fargate, migrations backward-compatible, monitoramento pós-deploy
    - Verificar conteúdo de `data-governance.md`: duas camadas/convenções, tabela de naturezas completa (14 prefixos), auditoria (tmp_creation/tmp_update), HasComment pt-BR, constraints (pk_/fk_/ix_/uk_/ak_), decimal(18,8), 3FN, processo chapter de dados (SLA 1 semana)
    - Verificar que `data-governance.md` NÃO existe em `archetypes/bff-fastify/steering/` nem `archetypes/frontend-react/steering/`
    - Arquivo: `tests/unit/test_archetype_csharp_steering.bats`
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_
  - [x] 3.2 Criar teste unitário para hooks
    - Verificar existência dos 7 hooks com nomes corretos
    - Verificar que `build-after-agent` contém `dotnet build --no-restore` no prompt e verificação condicional de `.cs`
    - Verificar que `review-domain-boundaries` revisa fronteiras Clean Architecture: Domain sem dependências externas, Application sem Infrastructure, Infrastructure sem regras de negócio, Api com MediatR/ISender, CancellationToken propagado, entidades com construtores privados e factory methods
    - Verificar que `review-endpoint-quality` revisa 7 aspectos: OpenAPI (WithName/WithTags/Produces/ProducesProblem), ISender, CancellationToken, RequireAuthorization, nomenclatura {Verb}{Resource}Endpoint.cs, rota /api/v1/ kebab-case, FluentValidation no handler
    - Verificar que `review-data-model` é `preToolUse` com `toolTypes: ["write"]` e valida 10 regras: ToTable snake_case, HasComment tabela pt-BR, HasColumnName com prefixo de natureza, HasComment colunas pt-BR, HasPrecision(18,8) monetários, auditoria tmp_creation/tmp_update, PK pk_, FK fk_, índices ix_
    - Verificar que `migration-reminder` é `postToolUse` com `toolTypes: ["write"]` e cita 3 passos: gerar migration, gerar pacote validação, submeter ao chapter
    - Verificar que `run-tests-after-task` tem ação `runCommand` com `dotnet test`
    - Verificar que `kiro-doctor` gera relatório com 8 seções e salva como `kiro-doctor-report.md`
    - Arquivo: `tests/unit/test_archetype_csharp_hooks.bats`
    - _Requisitos: 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 7.1, 7.2, 7.3, 7.4_
  - [x] 3.3 Criar teste unitário para skills
    - Verificar existência das 5 skills com nomes corretos
    - Verificar que `generate-module` documenta geração em 4 camadas Clean Architecture: Api (Endpoints), Application (Commands/Queries/Handlers/Validators), Domain (Entities/Events/Repositories), Infrastructure (Persistence/Configurations)
    - Verificar que `generate-endpoint` documenta padrões Minimal API: Map(), ISender, WithName/WithTags/Produces, RequireAuthorization, CancellationToken, {Verb}{Resource}Endpoint.cs, /api/v1/ kebab-case
    - Verificar que `generate-repository` documenta interface I{Entity}Repository no Domain + implementação EF Core no Infrastructure + Entity Configuration
    - Verificar que `generate-data-model` documenta padrões chapter: entidades, configurations com nomenclatura snake_case e prefixos, migration, DDL, dicionário, diagrama ER
    - Verificar que `generate-validation-package` documenta 4 artefatos: ddl.sql, data-dictionary.md, er-diagram.md, validation-checklist.md
    - Arquivo: `tests/unit/test_archetype_csharp_skills.bats`
    - _Requisitos: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_
  - [x] 3.4 Criar teste unitário para mcp.json
    - Verificar campo `_comment` não-vazio mencionando archetype backend-csharp e merge com baseline
    - Verificar campo `_version` em formato semver
    - Verificar que `mcpServers` é objeto vazio `{}`
    - Arquivo: `tests/unit/test_archetype_csharp_mcp.bats`
    - _Requisitos: 9.1, 9.2_
  - [x] 3.5 Criar teste unitário para agents
    - Verificar que apenas `README.md` existe em `agents/`
    - Verificar que README menciona 5 agents planejados: domain-modeler, architecture-reviewer, api-designer, test-writer, migration-reviewer
    - Verificar que não há arquivos `.md` com frontmatter de agent funcional
    - Arquivo: `tests/unit/test_archetype_csharp_agents.bats`
    - _Requisitos: 10.1, 10.2, 10.3_

- [x] 4. Implementar testes de propriedade
  - [x] 4.1 Escrever teste de propriedade para completude estrutural
    - **Property 1: Completude estrutural do archetype**
    - **Valida: Requisitos 1.1, 1.2, 1.3, 1.4, 1.5, 1.9, 10.1, 10.2**
    - Gerar 20 variações de estado do archetype backend-csharp (removendo artefatos aleatórios)
    - Verificar que a validação falha se qualquer diretório de categoria não contém artefato funcional além do README
    - Verificar contagens exatas: `steering/` requer 5 `.md` (excl. README), `hooks/` requer 7 `.kiro.hook`, `skills/` requer 5 `.md` (excl. README), `mcp/` requer `mcp.json`, `agents/` requer apenas `README.md`
    - Arquivo: `tests/properties/prop_csharp_structure.bats`
  - [x] 4.2 Escrever teste de propriedade para formato semver
    - **Property 2: Formato de versão semântica**
    - **Valida: Requisitos 1.6, 11.1**
    - Gerar 100 strings de versão aleatórias (válidas e inválidas)
    - Verificar que apenas strings no formato `MAJOR.MINOR.PATCH` (inteiros ≥ 0, sem zeros à esquerda) são aceitas
    - Reutilizar/estender `tests/properties/prop_semver.bats` existente
  - [x] 4.3 Escrever teste de propriedade para hooks habilitados e schema válido
    - **Property 3: Hooks habilitados e schema válido**
    - **Valida: Requisitos 3.1, 4.1, 4.2, 5.1, 5.2, 6.1, 7.1**
    - Gerar 100 variações de hooks JSON com campos obrigatórios aleatórios
    - Verificar que validação requer: `enabled: true`, `name` não-vazio, `version` ("1" ou "2"), `when.type` válido (agentStop, postTaskExecution, userTriggered, preToolUse, postToolUse), `then.type` válido (askAgent, runCommand), `then.prompt` quando askAgent, `then.command` quando runCommand, `when.toolTypes` presente quando preToolUse ou postToolUse
    - Arquivo: `tests/properties/prop_csharp_hooks_schema.bats`
  - [x] 4.4 Escrever teste de propriedade para frontmatter de skills
    - **Property 4: Frontmatter de skills**
    - **Valida: Requisitos 8.6**
    - Gerar 100 frontmatters aleatórios para skills (com e sem campos obrigatórios)
    - Verificar que validação requer `name` (string não-vazia), `description` (string não-vazia) e `inclusion: manual`
    - Reutilizar/estender `tests/properties/prop_frontmatter_skills.bats` existente
  - [x] 4.5 Escrever teste de propriedade para schema MCP
    - **Property 5: Schema de configuração MCP**
    - **Valida: Requisitos 9.1, 9.2**
    - Gerar 100 variações de mcp.json (válidos e inválidos)
    - Verificar que validação requer `_comment` (string não-vazia), `_version` (semver válido) e `mcpServers` (objeto)
    - Reutilizar/estender `tests/properties/prop_mcp_schema.bats` existente
  - [x] 4.6 Escrever teste de propriedade para formato de changelog
    - **Property 6: Formato de changelog**
    - **Valida: Requisitos 1.7, 11.2**
    - Gerar 100 changelogs aleatórios (válidos e inválidos)
    - Verificar formato `## X.Y.Z (YYYY-MM-DD)`, seções apenas com nomes válidos (Funcionalidades, Correções, Documentação, Refatoração, Manutenção, Performance, CI/CD)
    - Reutilizar/estender `tests/properties/prop_changelog_format.bats` existente
  - [x] 4.7 Escrever teste de propriedade para precedência de version bump
    - **Property 7: Precedência de version bump**
    - **Valida: Requisitos 11.3, 11.4, 11.5, 11.6**
    - Gerar 100 conjuntos aleatórios de mudanças categorizadas (MAJOR, MINOR, PATCH)
    - Verificar que o bump resultante é sempre o de maior precedência (MAJOR > MINOR > PATCH)
    - Reutilizar/estender `tests/properties/prop_version_bump.bats` existente
  - [x] 4.8 Escrever teste de propriedade para ausência de agents funcionais
    - **Property 8: Ausência de agents funcionais**
    - **Valida: Requisitos 10.1, 10.2**
    - Gerar 100 variações do diretório agents/ (com e sem arquivos extras além de README.md)
    - Verificar que a validação falha se qualquer arquivo além de `README.md` existir em `agents/`
    - Arquivo: `tests/properties/prop_csharp_agents_empty.bats`
  - [x] 4.9 Escrever teste de propriedade para ausência de frontmatter YAML nos steering files
    - **Property 9: Ausência de frontmatter YAML nos steering files**
    - **Valida: Requisitos 2.8**
    - Gerar 100 variações de steering files (com e sem frontmatter YAML `---`)
    - Verificar que a validação falha se qualquer steering file iniciar com `---` em vez de `#`
    - Arquivo: `tests/properties/prop_csharp_steering_no_frontmatter.bats`

- [x] 5. Checkpoint — Testes unitários e de propriedade
  - Garantir que todos os testes unitários e de propriedade passam, perguntar ao usuário se surgirem dúvidas.

- [x] 6. Implementar testes de integração
  - [x] 6.1 Escrever testes de integração para bootstrap do archetype backend-csharp
    - Cenários: bootstrap com `--project-type backend-csharp` copia todos os artefatos do archetype
    - Verificar que steering files (sem README) são copiados para `.kiro/steering/`
    - Verificar que 7 hooks são copiados para `.kiro/hooks/`
    - Verificar que agents/ (apenas README.md) é copiado para `.kiro/agents/`
    - Verificar que 5 skills são copiadas para `.kiro/skills/`
    - Verificar merge de mcp.json (baseline global + archetype backend-csharp com mcpServers vazio = baseline)
    - Verificar geração de manifest com `archetype.name: "backend-csharp"` e versão correta
    - Arquivo: `tests/integration/test_bootstrap_csharp.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (bootstrap.sh)_
  - [x] 6.2 Escrever testes de integração para sync do archetype backend-csharp
    - Cenários: sync atualiza steering file desatualizado, adiciona hook novo, mantém inalterado o que já está correto
    - Verificar que artefatos do archetype backend-csharp são sincronizados corretamente
    - Verificar atualização do `last_synced_at` no manifest
    - Arquivo: `tests/integration/test_sync_csharp.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (sync.sh)_
  - [x] 6.3 Escrever testes de integração para doctor com archetype backend-csharp
    - Cenários: projeto saudável (✅ em tudo), steering ausente (❌), hook desabilitado (⚠️), skill faltante (❌), data-governance.md ausente (❌ crítico)
    - Verificar que doctor detecta artefatos específicos do archetype backend-csharp (7 hooks, 5 steering, 5 skills)
    - Verificar que relatório contém as 8 seções na ordem correta (Resumo, Steering, Hooks, MCP, Skills, Specs, Arquitetura, Recomendações)
    - Verificar que doctor identifica mcpServers vazio como correto (não é gap)
    - Verificar que doctor marca `data-governance.md` ausente como ❌ crítico
    - Arquivo: `tests/integration/test_doctor_csharp.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (doctor.sh), 7.1, 7.2, 7.3, 7.4_

- [x] 7. Checkpoint final — Executar suíte completa de testes
  - Executar `./tests/run_tests.sh` e garantir que todos os testes passam.
  - Perguntar ao usuário se surgirem dúvidas.

## Notes

- Este é um spec retroativo — o archetype já está implementado, foco é em validação e testes
- Cada task referencia requisitos específicos para rastreabilidade
- Checkpoints garantem validação incremental
- Testes de propriedade validam propriedades universais de correção (100 iterações cada, conforme design)
- Testes unitários verificam conteúdo específico dos artefatos existentes
- Testes de integração validam interação do archetype com bootstrap/sync/doctor
- O projeto usa bash + jq para scripts, bats-core para testes
- Helpers existentes em `tests/helpers/` (assertions.bash, generators.bash, setup.bash) devem ser reutilizados
- Testes de propriedade existentes (`prop_semver.bats`, `prop_frontmatter_skills.bats`, `prop_mcp_schema.bats`, `prop_changelog_format.bats`, `prop_version_bump.bats`) podem ser reutilizados quando genéricos — criar novos apenas para propriedades específicas do backend-csharp
- Diferenciais vs bff-fastify: steering file exclusivo `data-governance.md`, hooks com preToolUse/postToolUse (review-data-model e migration-reminder), 5 skills (vs 3), 7 hooks (vs 6), steering files sem frontmatter YAML (markdown puro com blockquote de identificação)
- Diferenciais vs frontend-react: steering files sem frontmatter YAML, agents sem implementação funcional, mcpServers vazio, 7 hooks (vs 8), 5 skills (vs 7)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7"] },
    { "id": 1, "tasks": ["3.1", "3.3", "3.4", "3.5"] },
    { "id": 2, "tasks": ["3.2", "4.1", "4.2", "4.5"] },
    { "id": 3, "tasks": ["4.3", "4.4", "4.6", "4.7", "4.8", "4.9"] },
    { "id": 4, "tasks": ["6.1", "6.2", "6.3"] }
  ]
}
```
