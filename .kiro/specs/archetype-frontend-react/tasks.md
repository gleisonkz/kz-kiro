# Implementation Plan: Archetype Frontend React

## Overview

Este plano cobre as tarefas de validação e teste do archetype `frontend-react` — um archetype já implementado. O foco é garantir conformidade com os requisitos via testes de propriedade, unitários e de integração usando bats-core, seguindo o mesmo padrão da spec `baseline-global`. Não há implementação de funcionalidades novas; apenas validação estrutural, testes automatizados e documentação de gaps.

## Tasks

- [x] 1. Validar conformidade estrutural do archetype existente
  - [x] 1.1 Validar estrutura de diretórios e artefatos obrigatórios
    - Verificar que `steering/`, `hooks/`, `agents/`, `skills/`, `mcp/` existem com artefatos funcionais + README.md
    - Verificar que `VERSION` e `CHANGELOG.md` estão na raiz do archetype
    - Documentar gaps encontrados (artefatos ausentes ou extras vs design)
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_
  - [x] 1.2 Validar conformidade do VERSION e CHANGELOG.md
    - Verificar formato semver no VERSION (sem prefixo `v`, sem espaços, sem trailing newline)
    - Verificar que CHANGELOG.md tem entrada correspondente à versão do VERSION
    - Verificar formato de cabeçalho `## MAJOR.MINOR.PATCH (YYYY-MM-DD)` e seções válidas
    - _Requisitos: 1.6, 1.7, 10.1, 10.2, 10.3, 10.4_
  - [x] 1.3 Validar frontmatter de todos os steering files
    - Verificar `stack-and-tooling.md`: `inclusion: auto`
    - Verificar `naming-conventions.md`: `inclusion: auto`
    - Verificar `architecture.md`: `inclusion: fileMatch` com `fileMatchPattern` contendo `**/modules/**` e `**/src/app/**`
    - Verificar `design-system.md`: `inclusion: fileMatch` com `fileMatchPattern` contendo `**/*.tsx`, `**/shared/ui/**`, `**/*.variants.ts`
    - Verificar `ci-cd.md`: `inclusion: fileMatch` com `fileMatchPattern` contendo `**/.github/**`, `**/turbo.json`, `**/Dockerfile*`
    - _Requisitos: 2.6, 2.7, 2.8, 2.9, 2.10_
  - [x] 1.4 Validar conformidade dos hooks (schema JSON)
    - Verificar que todos os 8 hooks têm `enabled: true`, schema válido
    - Verificar triggers corretos: `agentStop` para hooks de qualidade e revisão, `postTaskExecution` para ciclo, `userTriggered` para doctor
    - Verificar tipos de ação corretos: `askAgent` ou `runCommand` conforme requisitos
    - _Requisitos: 3.2, 3.4, 4.4, 5.1, 5.2, 6.1_
  - [x] 1.5 Validar conformidade dos agents (frontmatter e seções)
    - Verificar que 4 agents têm frontmatter com `name` e `description`
    - Verificar presença de seção `## Referências` em cada agent
    - _Requisitos: 7.5, 7.6_
  - [x] 1.6 Validar conformidade das skills (frontmatter)
    - Verificar que 7 skills têm frontmatter com `name`, `description` e `inclusion: manual`
    - _Requisitos: 8.8_
  - [x] 1.7 Validar conformidade do mcp.json
    - Verificar schema: `_comment`, `_version` (semver), `mcpServers` com `chrome-devtools`
    - Verificar `chrome-devtools`: `command: "npx"`, `args: ["-y", "chrome-devtools-mcp@latest"]`, `disabled: false`, `autoApprove: []`
    - _Requisitos: 9.1, 9.2, 9.3, 9.4_

- [x] 2. Checkpoint — Validação estrutural completa
  - Garantir que todos os artefatos estão conformes, perguntar ao usuário se surgirem dúvidas.

- [x] 3. Implementar testes unitários do archetype
  - [x] 3.1 Criar teste unitário para steering files
    - Verificar existência dos 5 arquivos de steering com nomes corretos
    - Verificar conteúdo de `stack-and-tooling.md`: seções de stack base, monorepo, tecnologias descartadas
    - Verificar conteúdo de `architecture.md`: seções de monolito modular, FSD, fronteiras, estado
    - Verificar conteúdo de `design-system.md`: seções de token-first, Base UI, Storybook, qualidade (≥5 requisitos)
    - Verificar conteúdo de `naming-conventions.md`: tabela com ≥10 sufixos mapeados
    - Verificar conteúdo de `ci-cd.md`: seções de pipelines, deploy, estágios
    - Arquivo: `tests/unit/test_archetype_frontend_steering.bats`
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5_
  - [x] 3.2 Criar teste unitário para hooks
    - Verificar existência dos 8 hooks com nomes corretos
    - Verificar que `lint-after-agent` contém comando `pnpm turbo lint --affected` no prompt
    - Verificar que `typecheck-on-save` contém comando `npx tsc --noEmit --pretty` no prompt
    - Verificar que `run-tests-after-task` tem ação `runCommand` com `npx vitest --run --reporter=verbose`
    - Verificar que `kiro-doctor` tem 8 seções no prompt do relatório
    - Verificar versão `"2"` nos hooks com verificação condicional
    - Arquivo: `tests/unit/test_archetype_frontend_hooks.bats`
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4_
  - [x] 3.3 Criar teste unitário para agents
    - Verificar existência dos 4 agents com nomes corretos
    - Verificar que `accessibility-reviewer` cobre: semântica, ARIA, teclado, contraste, formulários, imagens
    - Verificar que `architecture-reviewer` cobre: fronteiras, FSD, estado, anti-padrões
    - Verificar que `code-reviewer` organiza em 3 níveis: bloqueante, importante, sugestão
    - Verificar que `performance-reviewer` cobre: re-renders, memoização, bundle, RTK Query
    - Arquivo: `tests/unit/test_archetype_frontend_agents.bats`
    - _Requisitos: 7.1, 7.2, 7.3, 7.4_
  - [x] 3.4 Criar teste unitário para skills
    - Verificar existência das 7 skills com nomes corretos
    - Verificar que `generate-component` documenta artefatos: `.tsx`, `.test.tsx`, `.stories.tsx`, `index.ts`
    - Verificar que `generate-hook` segue padrão `use-*.hook.ts`
    - Verificar que `generate-redux-slice` gera `.slice.ts`, `.selectors.ts` e testes
    - Verificar que `generate-page` menciona 4 estados (loading, error, empty, success)
    - Arquivo: `tests/unit/test_archetype_frontend_skills.bats`
    - _Requisitos: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_
  - [x] 3.5 Criar teste unitário para mcp.json
    - Verificar campos do `chrome-devtools`: command, args, disabled, autoApprove
    - Verificar `_comment` não vazio e `_version` em formato semver
    - Arquivo: `tests/unit/test_archetype_frontend_mcp.bats`
    - _Requisitos: 9.1, 9.2, 9.3, 9.4_

- [x] 4. Implementar testes de propriedade
  - [x] 4.1 Escrever teste de propriedade para completude estrutural
    - **Property 1: Completude estrutural do archetype**
    - **Valida: Requisitos 1.1, 1.2, 1.3, 1.4, 1.5, 1.8, 1.9**
    - Gerar 20 variações de estado do archetype (removendo artefatos aleatórios)
    - Verificar que a validação falha se qualquer diretório de categoria não contém artefato funcional além do README
    - Arquivo: `tests/properties/prop_archetype_structure.bats`
  - [x] 4.2 Escrever teste de propriedade para frontmatter de steering files
    - **Property 3: Frontmatter de steering files**
    - **Valida: Requisitos 2.6, 2.7, 2.8, 2.9, 2.10**
    - Gerar 20 frontmatters aleatórios (válidos e inválidos)
    - Verificar que inclusão `auto`/`fileMatch`/`manual` é aceita; `fileMatch` requer `fileMatchPattern` não-vazio
    - Reutilizar/estender `tests/properties/prop_frontmatter.bats` se aplicável, ou criar `tests/properties/prop_frontmatter_steering.bats`
  - [x] 4.3 Escrever teste de propriedade para hooks habilitados
    - **Property 4: Hooks habilitados por padrão**
    - **Valida: Requisitos 3.2, 3.4, 4.4, 5.1, 5.2**
    - Gerar 20 variações de hooks JSON com campo `enabled` aleatório
    - Verificar que a validação só aceita hooks com `enabled: true`
    - Arquivo: `tests/properties/prop_hooks_enabled.bats`
  - [x] 4.4 Escrever teste de propriedade para frontmatter de agents
    - **Property 5: Frontmatter de agents**
    - **Valida: Requisitos 7.5, 7.6**
    - Gerar 20 frontmatters aleatórios para agents (com e sem campos obrigatórios)
    - Verificar que validação requer `name` (string não-vazia), `description` (string não-vazia) e seção `## Referências`
    - Arquivo: `tests/properties/prop_frontmatter_agents.bats`
  - [x] 4.5 Escrever teste de propriedade para frontmatter de skills
    - **Property 6: Frontmatter de skills**
    - **Valida: Requisitos 8.8**
    - Gerar 20 frontmatters aleatórios para skills
    - Verificar que validação requer `name`, `description` e `inclusion: manual`
    - Arquivo: `tests/properties/prop_frontmatter_skills.bats`
  - [x] 4.6 Escrever teste de propriedade para schema MCP
    - **Property 7: Schema de configuração MCP**
    - **Valida: Requisitos 9.1, 9.2, 9.3, 9.4**
    - Reutilizar/estender `tests/properties/prop_mcp_schema.bats` existente
    - Verificar `_comment`, `_version`, `mcpServers` com `_comment` não-vazio, `autoApprove: []` por servidor
  - [x] 4.7 Escrever teste de propriedade para formato de changelog
    - **Property 8: Formato de changelog**
    - **Valida: Requisitos 1.7, 10.3, 10.4**
    - Gerar 20 changelogs aleatórios (válidos e inválidos)
    - Verificar formato `## X.Y.Z (YYYY-MM-DD)`, seções apenas com nomes válidos (Funcionalidades, Correções, Documentação, Refatoração, Manutenção, Performance, CI/CD)
    - Arquivo: `tests/properties/prop_changelog_format.bats`
  - [x] 4.8 Escrever teste de propriedade para precedência de version bump
    - **Property 9: Precedência de version bump**
    - **Valida: Requisitos 10.8**
    - Gerar 20 conjuntos aleatórios de mudanças categorizadas
    - Verificar que o bump resultante é sempre o de maior precedência (MAJOR > MINOR > PATCH)
    - Arquivo: `tests/properties/prop_version_bump.bats`

- [x] 5. Checkpoint — Testes de propriedade
  - Garantir que todos os testes de propriedade passam, perguntar ao usuário se surgirem dúvidas.

- [x] 6. Implementar testes de integração
  - [x] 6.1 Escrever testes de integração para bootstrap do archetype frontend-react
    - Cenários: bootstrap com `--project-type frontend-react` copia todos os artefatos do archetype
    - Verificar que steering, hooks, agents, skills são copiados para `.kiro/`
    - Verificar merge de mcp.json (baseline global + archetype frontend-react)
    - Verificar geração de manifest com `archetype.name: "frontend-react"` e versão correta
    - Arquivo: `tests/integration/test_bootstrap_frontend.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (bootstrap.sh)_
  - [x] 6.2 Escrever testes de integração para sync do archetype frontend-react
    - Cenários: sync atualiza steering file desatualizado, adiciona hook novo, mantém inalterado o que já está correto
    - Verificar que artefatos do archetype frontend-react são sincronizados corretamente
    - Verificar atualização do `last_synced_at` no manifest
    - Arquivo: `tests/integration/test_sync_frontend.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (sync.sh)_
  - [x] 6.3 Escrever testes de integração para doctor com archetype frontend-react
    - Cenários: projeto saudável (✅ em tudo), steering ausente (❌), hook desabilitado (⚠️), skill faltante (❌)
    - Verificar que doctor detecta artefatos específicos do archetype frontend-react
    - Verificar que relatório contém as 8 seções na ordem correta
    - Arquivo: `tests/integration/test_doctor_frontend.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (doctor.sh), 6.1, 6.2, 6.3, 6.4_

- [x] 7. Checkpoint final — Executar suíte completa de testes
  - Executar `./tests/run_tests.sh` e garantir que todos os testes passam.
  - Perguntar ao usuário se surgirem dúvidas.

## Notes

- Este é um spec retroativo — o archetype já está implementado, foco é em validação e testes
- Cada task referencia requisitos específicos para rastreabilidade
- Checkpoints garantem validação incremental
- Testes de propriedade validam propriedades universais de correção (20 iterações cada, conforme padrão do projeto)
- Testes unitários verificam conteúdo específico dos artefatos existentes
- Testes de integração validam interação do archetype com bootstrap/sync/doctor
- O projeto usa bash + jq para scripts, bats-core para testes
- Helpers existentes em `tests/helpers/` (assertions.bash, generators.bash, setup.bash) devem ser reutilizados
- Testes de propriedade existentes (`prop_frontmatter.bats`, `prop_mcp_schema.bats`, `prop_semver.bats`) podem ser estendidos ou referenciados

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
