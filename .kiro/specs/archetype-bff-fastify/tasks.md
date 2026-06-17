# Implementation Plan: Archetype BFF Fastify

## Overview

Este plano cobre as tarefas de validação e teste do archetype `bff-fastify` — um archetype já implementado. O foco é garantir conformidade com os requisitos via testes de propriedade, unitários e de integração usando bats-core, seguindo o mesmo padrão da spec `archetype-frontend-react`. Não há implementação de funcionalidades novas; apenas validação estrutural, testes automatizados e documentação de gaps.

## Tasks

- [x] 1. Validar conformidade estrutural do archetype existente
  - [x] 1.1 Validar estrutura de diretórios e artefatos obrigatórios
    - Verificar que `steering/`, `hooks/`, `agents/`, `skills/` e `mcp/` existem com artefatos funcionais + README.md
    - Verificar que `VERSION` e `CHANGELOG.md` estão na raiz do archetype
    - Verificar que `README.md` existe na raiz e em cada diretório de categoria
    - Documentar gaps encontrados (artefatos ausentes ou extras vs design)
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_
  - [x] 1.2 Validar conformidade do VERSION e CHANGELOG.md
    - Verificar formato semver no VERSION (sem prefixo `v`, sem espaços, sem trailing newline)
    - Verificar que CHANGELOG.md tem entrada correspondente à versão do VERSION
    - Verificar formato de cabeçalho `## MAJOR.MINOR.PATCH (YYYY-MM-DD)` e seções válidas
    - _Requisitos: 1.6, 1.7, 10.1, 10.2_
  - [x] 1.3 Validar conformidade dos steering files (sem frontmatter)
    - Verificar que `stack-and-tooling.md`, `architecture.md`, `naming-conventions.md`, `ci-cd.md` e `README.md` existem em `steering/`
    - Verificar que steering files NÃO possuem frontmatter YAML (diferente do frontend-react)
    - Verificar blockquote de identificação no topo: `Steering File | Archetype: bff-fastify | Versão: X.Y.Z`
    - _Requisitos: 1.1, 2.1, 2.2, 2.3, 2.4, 2.5_
  - [x] 1.4 Validar conformidade dos hooks (schema JSON)
    - Verificar que todos os 6 hooks têm `enabled: true`, schema válido
    - Verificar triggers corretos: `agentStop` para lint/typecheck/review hooks, `postTaskExecution` para run-tests, `userTriggered` para doctor
    - Verificar tipos de ação corretos: `askAgent` ou `runCommand` conforme requisitos
    - Verificar versões: `"2"` para hooks com verificação condicional, `"1"` para run-tests e doctor
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 5.1, 6.1_
  - [x] 1.5 Validar conformidade das skills (frontmatter)
    - Verificar que 3 skills têm frontmatter com `name`, `description` e `inclusion: manual`
    - Verificar que `generate-module.md`, `generate-client.md` e `generate-plugin.md` existem
    - _Requisitos: 7.1, 7.2, 7.3, 7.4_
  - [x] 1.6 Validar conformidade do mcp.json
    - Verificar schema: `_comment` não-vazio, `_version` em formato semver, `mcpServers` objeto vazio (`{}`)
    - _Requisitos: 8.1, 8.2_
  - [x] 1.7 Validar conformidade do diretório agents/
    - Verificar que apenas `README.md` existe em `agents/` — nenhum agent funcional
    - Verificar que README lista agents planejados (bff-architect, api-designer, resilience-reviewer, test-writer)
    - _Requisitos: 9.1, 9.2_

- [x] 2. Checkpoint — Validação estrutural completa
  - Garantir que todos os artefatos estão conformes, perguntar ao usuário se surgirem dúvidas.

- [x] 3. Implementar testes unitários do archetype
  - [x] 3.1 Criar teste unitário para steering files
    - Verificar existência dos 5 arquivos de steering com nomes corretos (4 + README)
    - Verificar conteúdo de `stack-and-tooling.md`: seções de stack base obrigatória (Node.js 20, Fastify 5, TS 5, Zod), justificativas RFC, ESM-first, tsconfig, scripts, packages compartilhados, Docker, tecnologias descartadas
    - Verificar conteúdo de `architecture.md`: seções de papel do BFF, princípios, monólito modular, módulo como plugin, anatomia, fluxo de request, agregação, fronteiras, resiliência, observabilidade, health checks, versionamento API
    - Verificar conteúdo de `naming-conventions.md`: tabela com sufixos mapeados (`.schema.ts`, `.service.ts`, `.mapper.ts`, `.types.ts`, `.config.ts`, `.test.ts`, `.fixture.ts`, `.constants.ts`, `.plugin.ts`)
    - Verificar conteúdo de `ci-cd.md`: seções de princípios, pipeline PR/merge/release, ambientes, container Docker multi-stage, monitoramento
    - Arquivo: `tests/unit/test_archetype_bff_steering.bats`
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5_
  - [x] 3.2 Criar teste unitário para hooks
    - Verificar existência dos 6 hooks com nomes corretos
    - Verificar que `lint-after-agent` contém comando `pnpm lint` no prompt
    - Verificar que `typecheck-on-save` contém comando `pnpm typecheck` no prompt
    - Verificar que `review-route-quality` revisa 6 aspectos: schemas Zod, separação de responsabilidades, plugin pattern, error handling, nomenclatura, prefixo de módulo
    - Verificar que `review-bff-boundaries` revisa 8 regras: zero regras de negócio, services orquestram clients, mappers puros, sem acesso a banco, módulos encapsulados, rotas sem lógica, validações apenas de contrato, comunicação via contratos explícitos
    - Verificar que `run-tests-after-task` tem ação `runCommand` com `pnpm test`
    - Verificar que `kiro-doctor` gera relatório com 8 seções e salva como `kiro-doctor-report.md`
    - Verificar verificação condicional (`.ts` em `src/`) nos hooks de qualidade e revisão
    - Arquivo: `tests/unit/test_archetype_bff_hooks.bats`
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 5.1, 6.1, 6.2, 6.3, 6.4_
  - [x] 3.3 Criar teste unitário para skills
    - Verificar existência das 3 skills com nomes corretos
    - Verificar que `generate-module` documenta 6 artefatos: index.ts (plugin), routes/index.ts, rota, schema, service, mapper
    - Verificar que `generate-client` documenta padrões de resiliência: timeout, retry, circuit breaker, correlation ID, undici/fetch
    - Verificar que `generate-plugin` documenta padrões Fastify: plugins/, sufixo Plugin, fp, declare module, JSDoc
    - Arquivo: `tests/unit/test_archetype_bff_skills.bats`
    - _Requisitos: 7.1, 7.2, 7.3, 7.4_
  - [x] 3.4 Criar teste unitário para mcp.json
    - Verificar campo `_comment` não-vazio mencionando archetype bff-fastify e merge com baseline
    - Verificar campo `_version` em formato semver
    - Verificar que `mcpServers` é objeto vazio `{}`
    - Arquivo: `tests/unit/test_archetype_bff_mcp.bats`
    - _Requisitos: 8.1, 8.2_
  - [x] 3.5 Criar teste unitário para agents
    - Verificar que apenas `README.md` existe em `agents/`
    - Verificar que README menciona agents planejados: bff-architect, api-designer, resilience-reviewer, test-writer
    - Verificar que não há arquivos `.md` com frontmatter de agent funcional
    - Arquivo: `tests/unit/test_archetype_bff_agents.bats`
    - _Requisitos: 9.1, 9.2_

- [x] 4. Implementar testes de propriedade
  - [x] 4.1 Escrever teste de propriedade para completude estrutural
    - **Property 1: Completude estrutural do archetype**
    - **Valida: Requisitos 1.1, 1.2, 1.3, 1.4, 1.5, 1.9**
    - Gerar 20 variações de estado do archetype (removendo artefatos aleatórios)
    - Verificar que a validação falha se qualquer diretório de categoria não contém artefato funcional além do README
    - Verificar que `steering/` requer ao menos 4 `.md` (excl. README), `hooks/` ao menos 1 `.kiro.hook`, `skills/` ao menos 1 `.md` (excl. README), `mcp/` requer `mcp.json`
    - Arquivo: `tests/properties/prop_bff_structure.bats`
  - [x] 4.2 Escrever teste de propriedade para formato semver
    - **Property 2: Formato de versão semântica**
    - **Valida: Requisitos 1.6, 10.1**
    - Gerar 100 strings de versão aleatórias (válidas e inválidas)
    - Verificar que apenas strings no formato `MAJOR.MINOR.PATCH` (inteiros ≥ 0, sem zeros à esquerda) são aceitas
    - Reutilizar/estender `tests/properties/prop_semver.bats` existente
  - [x] 4.3 Escrever teste de propriedade para hooks habilitados e schema válido
    - **Property 3: Hooks habilitados e schema válido**
    - **Valida: Requisitos 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 5.1, 6.1**
    - Gerar 100 variações de hooks JSON com campos obrigatórios aleatórios
    - Verificar que validação requer: `enabled: true`, `name` não-vazio, `version` ("1" ou "2"), `when.type` válido, `then.type` válido, `then.prompt` quando askAgent, `then.command` quando runCommand
    - Arquivo: `tests/properties/prop_bff_hooks_schema.bats`
  - [x] 4.4 Escrever teste de propriedade para frontmatter de skills
    - **Property 4: Frontmatter de skills**
    - **Valida: Requisitos 7.4**
    - Gerar 100 frontmatters aleatórios para skills (com e sem campos obrigatórios)
    - Verificar que validação requer `name` (string não-vazia), `description` (string não-vazia) e `inclusion: manual`
    - Reutilizar/estender `tests/properties/prop_frontmatter_skills.bats` existente
  - [x] 4.5 Escrever teste de propriedade para schema MCP
    - **Property 5: Schema de configuração MCP**
    - **Valida: Requisitos 8.1, 8.2**
    - Gerar 100 variações de mcp.json (válidos e inválidos)
    - Verificar que validação requer `_comment` (string não-vazia), `_version` (semver válido) e `mcpServers` (objeto)
    - Reutilizar/estender `tests/properties/prop_mcp_schema.bats` existente
  - [x] 4.6 Escrever teste de propriedade para formato de changelog
    - **Property 6: Formato de changelog**
    - **Valida: Requisitos 1.7, 10.2**
    - Gerar 100 changelogs aleatórios (válidos e inválidos)
    - Verificar formato `## X.Y.Z (YYYY-MM-DD)`, seções apenas com nomes válidos (Funcionalidades, Correções, Documentação, Refatoração, Manutenção, Performance, CI/CD)
    - Reutilizar/estender `tests/properties/prop_changelog_format.bats` existente
  - [x] 4.7 Escrever teste de propriedade para precedência de version bump
    - **Property 7: Precedência de version bump**
    - **Valida: Requisitos 10.3, 10.4, 10.5, 10.6**
    - Gerar 100 conjuntos aleatórios de mudanças categorizadas (MAJOR, MINOR, PATCH)
    - Verificar que o bump resultante é sempre o de maior precedência (MAJOR > MINOR > PATCH)
    - Reutilizar/estender `tests/properties/prop_version_bump.bats` existente
  - [x] 4.8 Escrever teste de propriedade para ausência de agents funcionais
    - **Property 8: Ausência de agents funcionais**
    - **Valida: Requisitos 9.1, 9.2**
    - Gerar 100 variações do diretório agents/ (com e sem arquivos extras além de README.md)
    - Verificar que a validação falha se qualquer arquivo além de `README.md` existir em `agents/`
    - Arquivo: `tests/properties/prop_bff_agents_empty.bats`

- [x] 5. Checkpoint — Testes de propriedade
  - Garantir que todos os testes de propriedade passam, perguntar ao usuário se surgirem dúvidas.

- [x] 6. Implementar testes de integração
  - [x] 6.1 Escrever testes de integração para bootstrap do archetype bff-fastify
    - Cenários: bootstrap com `--project-type bff-fastify` copia todos os artefatos do archetype
    - Verificar que steering files (sem README) são copiados para `.kiro/steering/`
    - Verificar que hooks são copiados para `.kiro/hooks/`
    - Verificar que agents/ (apenas README.md) é copiado para `.kiro/agents/`
    - Verificar que skills são copiadas para `.kiro/skills/`
    - Verificar merge de mcp.json (baseline global + archetype bff-fastify com mcpServers vazio = baseline)
    - Verificar geração de manifest com `archetype.name: "bff-fastify"` e versão correta
    - Arquivo: `tests/integration/test_bootstrap_bff.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (bootstrap.sh)_
  - [x] 6.2 Escrever testes de integração para sync do archetype bff-fastify
    - Cenários: sync atualiza steering file desatualizado, adiciona hook novo, mantém inalterado o que já está correto
    - Verificar que artefatos do archetype bff-fastify são sincronizados corretamente
    - Verificar atualização do `last_synced_at` no manifest
    - Arquivo: `tests/integration/test_sync_bff.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (sync.sh)_
  - [x] 6.3 Escrever testes de integração para doctor com archetype bff-fastify
    - Cenários: projeto saudável (✅ em tudo), steering ausente (❌), hook desabilitado (⚠️), skill faltante (❌)
    - Verificar que doctor detecta artefatos específicos do archetype bff-fastify
    - Verificar que relatório contém as 8 seções na ordem correta
    - Verificar que doctor identifica mcpServers vazio como correto (não é gap)
    - Arquivo: `tests/integration/test_doctor_bff.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (doctor.sh), 6.1, 6.2, 6.3, 6.4_

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
- Testes de propriedade existentes (`prop_frontmatter_skills.bats`, `prop_mcp_schema.bats`, `prop_semver.bats`, `prop_changelog_format.bats`, `prop_version_bump.bats`) podem ser reutilizados quando genéricos — criar novos apenas para propriedades específicas do bff-fastify
- Diferença do frontend-react: steering files sem frontmatter YAML, agents sem implementação funcional, mcpServers vazio, 6 hooks (vs 8), 3 skills (vs 7)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7"] },
    { "id": 1, "tasks": ["3.1", "3.3", "3.4", "3.5"] },
    { "id": 2, "tasks": ["3.2", "4.1", "4.2", "4.3"] },
    { "id": 3, "tasks": ["4.4", "4.5", "4.6", "4.7", "4.8"] },
    { "id": 4, "tasks": ["6.1", "6.2", "6.3"] }
  ]
}
```
