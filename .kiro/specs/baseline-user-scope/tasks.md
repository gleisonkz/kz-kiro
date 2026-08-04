# Implementation Plan: Baseline User Scope

## Overview

Migração do baseline global do nível workspace para o nível do usuário (`~/.kiro/`), mantendo apenas artefatos do archetype no workspace. Implementação em 16 tasks com dependências claras.

## Tasks

- [x] 1. Criar módulo lib/common.sh com funções compartilhadas
  - Criar arquivo `scripts/lib/common.sh` com funções de utilidade compartilhadas
  - Implementar funções de logging: `log_info`, `log_success`, `log_warn`, `log_error` com cores
  - Implementar `is_ci_environment()` que retorna 0 se `$CI` == "true" (case-insensitive via regex `^[Tt][Rr][Uu][Ee]$`)
  - Implementar `validate_semver()` que valida formato `MAJOR.MINOR.PATCH`
  - Implementar `validate_scope()` que aceita apenas `user` ou `workspace`
  - Implementar `validate_target()` que verifica se path existe e é diretório
  - Implementar `add_prefix()` que transforma `file.md` → `mb--file.md`
  - Implementar `strip_prefix()` que transforma `mb--file.md` → `file.md`
  - Implementar `has_prefix()` que retorna 0 se nome começa com `mb--`
  - Implementar `copy_with_prefix()` que copia arquivo aplicando prefixo `mb--`
  - Implementar `sync_file()` que compara byte-a-byte e copia se diferente
  - Implementar `find_orphans()` que lista arquivos com prefixo sem correspondente na fonte
  - Implementar `merge_mcp_servers()` usando jq para merge JSON preservando servidores pessoais
  - Implementar `remove_mcp_servers()` que remove servidores por lista de chaves
  - **Requirements:** 1, 3, 4, 12
  - **Design:** Components and Interfaces §2

- [x] 2. Refatorar bootstrap.sh — adicionar --scope e extrair common
  - Adicionar `source "${SCRIPT_DIR}/lib/common.sh"` no início do bootstrap.sh
  - Adicionar parsing do argumento `--scope user|workspace` na seção de args
  - Se `--scope` não for informado, exibir erro com mensagem e exit 1
  - Manter a lógica existente do bootstrap atual como base para `--scope workspace`
  - No `--scope workspace`: remover cópia de artefatos do baseline (não copiar `baselines/global/steering/`)
  - No `--scope workspace`: gerar MCP apenas com servidores do archetype (sem merge com baseline)
  - No `--scope workspace`: gerar manifest v2 com campo `baseline.scope: "user"` e `schema_version: "2.0.0"`
  - No `--scope workspace`: validar --target (existe + é diretório), exibir erro se inválido
  - No `--scope workspace`: se `.kiro/` já existe sem --force, exit 1 com sugestão
  - No `--scope workspace`: com --force e `.kiro/` existente, sobrescrever preservando `specs/`
  - **Requirements:** 2, 8.3
  - **Design:** Components and Interfaces §1 (bootstrap.sh v2)

- [x] 3. Implementar bootstrap.sh --scope user
  - No `--scope user`: verificar se é CI_Environment, se sim exibir WARNING e exit 0
  - Validar `baselines/global/VERSION` existe e contém semver válido, exit 1 se inválido
  - Se `~/.kiro/` não existir, criar `~/.kiro/steering/`, `~/.kiro/hooks/`, `~/.kiro/settings/`
  - Iterar sobre `baselines/global/steering/*.md` (exceto README.md), copiar para `~/.kiro/steering/mb--<nome>.md`
  - Se arquivo `mb--<nome>` já existe e sem --force: skip + WARNING em stderr
  - Iterar sobre `baselines/global/hooks/*.kiro.hook`, copiar para `~/.kiro/hooks/mb--<nome>.kiro.hook`
  - Mergear servidores de `baselines/global/mcp/mcp.json` em `~/.kiro/settings/mcp.json`
  - Se servidor MCP com mesma chave já existe, sobrescrever + WARNING em stderr
  - Criar `~/.kiro/mb-baseline-version` com conteúdo de `baselines/global/VERSION`
  - Exibir resumo: arquivos copiados, pulados, servidores mergeados
  - Suportar --dry-run: listar operações sem executar
  - **Requirements:** 1, 3.1, 3.2, 10.4
  - **Design:** Diagrama de Fluxo — Bootstrap com Scope (ramo user)

- [x] 4. Refatorar sync.sh — adicionar --scope e --migrate-to-user-scope
  - Adicionar `source "${SCRIPT_DIR}/lib/common.sh"` no início do sync.sh
  - Adicionar parsing de `--scope user|workspace` e `--migrate-to-user-scope`
  - Se `--scope` não informado E manifest legado (sem baseline.scope): manter comportamento antigo
  - Se `--scope` não informado E não é legado: exibir erro com valores válidos
  - Redirecionar para função `sync_user_scope()` quando `--scope user`
  - Redirecionar para função `sync_workspace_scope()` quando `--scope workspace`
  - Redirecionar para função `migrate_to_user_scope()` quando `--migrate-to-user-scope`
  - **Requirements:** 4, 5, 8.2, 11
  - **Design:** Components and Interfaces §1 (sync.sh v2)

- [x] 5. Implementar sync.sh --scope user
  - Verificar que `~/.kiro/` existe, exit 1 se não
  - Verificar que `baselines/global/` existe, exit 1 se não
  - Comparar byte-a-byte cada steering do baseline com `~/.kiro/steering/mb--<nome>.md`
  - Sobrescrever arquivos com conteúdo diferente
  - Copiar novos arquivos com prefixo `mb--`
  - Comparar byte-a-byte cada hook do baseline com `~/.kiro/hooks/mb--<nome>.kiro.hook`
  - Sobrescrever hooks com conteúdo diferente, copiar novos com prefixo
  - Re-mergear servidores MCP: adicionar novos, atualizar existentes, NÃO remover pessoais
  - Atualizar `~/.kiro/mb-baseline-version`
  - Chamar `find_orphans()` para steerings e hooks, remover órfãos com mensagem
  - Identificar e remover servidores MCP órfãos do baseline
  - Se falha ao remover órfão: log erro, continuar processando, exit 1 no final
  - Suportar --dry-run
  - Exibir resumo: novos, atualizados, sem mudança, removidos
  - **Requirements:** 4, 12
  - **Design:** Algorithms — Merge MCP, Limpeza de Órfãos

- [x] 6. Implementar sync.sh --scope workspace
  - Validar `--target` informado e é diretório existente
  - Verificar que `kiro-manifest.json` existe no target, exit 1 se não
  - Ler `archetype.name` do manifest para identificar archetype fonte
  - Comparar artefatos do archetype (steering, skills, hooks, agents) com workspace
  - Sobrescrever arquivos com conteúdo diferente, adicionar novos
  - Remover arquivos do workspace que não existem mais no archetype fonte
  - Re-mergear MCP do archetype em `.kiro/settings/mcp.json` sem incluir baseline
  - Suportar --dry-run
  - Exibir resumo: novos, atualizados, removidos, sem mudança
  - Em CI_Environment: executar normalmente sem acessar ~/.kiro/
  - **Requirements:** 5, 10.5
  - **Design:** Components and Interfaces §1 (sync.sh v2)

- [x] 7. Implementar sync.sh --migrate-to-user-scope
  - Verificar que manifest existe, exit 1 se não
  - Se `baseline.scope` já == "user": exit 0 com mensagem informativa
  - Criar diretório backup: `<projeto>/.kiro/.migration-backup/baseline/`
  - Copiar steerings e hooks do baseline do workspace para backup
  - Dentro de TRY: remover steerings cujo nome corresponde a `baselines/global/steering/`
  - Dentro de TRY: remover servidores baseline do `.kiro/settings/mcp.json` preservando archetype
  - Dentro de TRY: atualizar manifest com `baseline.scope: "user"`, remover `baseline.version`, set `schema_version: "2.0.0"`
  - Em caso de falha: restaurar do backup + exit 1 com mensagem da etapa
  - Se `~/.kiro/mb-baseline-version` não existe: exibir instrução para rodar `bootstrap.sh --scope user`
  - Suportar --dry-run: simular sem aplicar
  - Usar trap para garantir rollback em SIGINT/SIGTERM
  - **Requirements:** 11, 8.5
  - **Design:** Algorithms — Migração, Diagrama de Fluxo — Migração

- [x] 8. Refatorar doctor.sh — adicionar --scope
  - Adicionar `source "${SCRIPT_DIR}/lib/common.sh"` no início do doctor.sh
  - Adicionar parsing de `--scope user|workspace`
  - Se `--scope` não informado + `--target` informado: executar ambos escopos e consolidar
  - Redirecionar para `doctor_user_scope()` quando `--scope user`
  - Redirecionar para `doctor_workspace_scope()` quando `--scope workspace`
  - Adaptar output JSON para incluir campo `scope`
  - Adaptar contadores para incluir `info` além de pass/warn/fail
  - **Requirements:** 6, 7
  - **Design:** Components and Interfaces §1 (doctor.sh v2)

- [x] 9. Implementar doctor.sh --scope user
  - Se `~/.kiro/` não existe: reportar FAIL + sugestão bootstrap
  - Verificar `~/.kiro/mb-baseline-version`: PASS se semver válido, FAIL se ausente/inválido
  - Comparar cada steering do baseline com `~/.kiro/steering/mb--<nome>.md`: PASS/WARN/FAIL
  - Comparar cada hook do baseline com `~/.kiro/hooks/mb--<nome>.kiro.hook`: PASS/WARN/FAIL
  - Verificar servidores MCP do baseline em `~/.kiro/settings/mcp.json`: PASS/WARN
  - Se --output json: produzir JSON com timestamp, target="~/.kiro", scope="user", summary, results
  - Exit code 1 se algum FAIL, exit code 0 se apenas PASS/WARN
  - **Requirements:** 6
  - **Design:** Data Models — Relatório Doctor JSON

- [x] 10. Implementar doctor.sh --scope workspace
  - Validar --target informado e existe
  - Se manifest não existe: FAIL + sugestão bootstrap
  - Verificar campo `baseline.scope` no manifest: WARN se ausente (legado)
  - Se `baseline.scope: "user"` e NÃO é CI: verificar `~/.kiro/mb-baseline-version`, WARN se ausente
  - Em CI_Environment: pular verificação de ~/.kiro/, reportar INFO
  - Comparar artefatos do archetype (steering, skills, hooks, agents): PASS/WARN/FAIL
  - Detectar overrides: steering/hook do workspace que corresponde a baseline → INFO
  - Se --output json: produzir JSON com scope="workspace"
  - Exit code 1 se algum FAIL, 0 caso contrário
  - Modelo legado: verificação completa baseline + archetype no workspace + INFO recomendando migração
  - **Requirements:** 7, 8.1, 9.4, 9.5, 10.1, 10.2
  - **Design:** Algorithms — Detecção de Override

- [x] 11. Implementar compatibilidade retroativa no sync.sh
  - Detectar modelo legado: manifest existe MAS não tem campo `baseline.scope`
  - Quando legado + sem --scope: sincronizar baseline + archetype juntos no workspace (comportamento original)
  - Quando legado + sem --scope: exibir INFO recomendando migração com comando
  - Garantir que sync legado não acessa `~/.kiro/`
  - Se projeto não tem manifest: exit 1 com instrução bootstrap
  - **Requirements:** 8.2, 8.4
  - **Design:** Correctness Properties — Property 10

- [x] 12. Testes unitários — lib/common.sh
  - Criar `tests/unit/test_prefix_operations.bats` com testes para add_prefix, strip_prefix, has_prefix
  - Criar `tests/unit/test_scope_validation.bats` com testes para validate_scope, is_ci_environment
  - Criar `tests/unit/test_merge_mcp_user.bats` com testes para merge_mcp_servers
  - Testar edge cases: arquivos com nome já contendo "mb--", mcp.json vazio, mcp.json inexistente
  - **Requirements:** 1, 3, 4
  - **Design:** Testing Strategy — Unit tests

- [x] 13. Testes de integração — bootstrap com scope
  - Criar `tests/integration/test_bootstrap_user_scope.bats`
  - Cenário: bootstrap --scope user em diretório limpo (cria tudo)
  - Cenário: bootstrap --scope user com steerings existentes sem --force (skip + warn)
  - Cenário: bootstrap --scope user com --force (sobrescreve)
  - Cenário: bootstrap --scope user com --dry-run (não modifica)
  - Cenário: bootstrap --scope user em CI (skip + exit 0)
  - Cenário: bootstrap --scope user com VERSION inválido (exit 1)
  - Criar `tests/integration/test_bootstrap_workspace.bats`
  - Cenário: bootstrap --scope workspace cria apenas archetype (sem baseline)
  - Cenário: bootstrap --scope workspace com .kiro/ existente sem --force (exit 1)
  - Cenário: bootstrap --scope workspace com --force preserva specs/
  - Cenário: bootstrap sem --scope (exit 1 com mensagem)
  - **Requirements:** 1, 2, 8.3, 10.4
  - **Design:** Testing Strategy — Integration tests

- [x] 14. Testes de integração — sync com scope
  - Criar `tests/integration/test_sync_user_scope.bats`
  - Cenário: sync --scope user atualiza arquivos desatualizados
  - Cenário: sync --scope user adiciona novos do baseline
  - Cenário: sync --scope user remove órfãos
  - Cenário: sync --scope user preserva arquivos pessoais (sem prefixo mb--)
  - Cenário: sync --scope user com --dry-run (não modifica)
  - Cenário: sync --scope user com ~/.kiro/ ausente (exit 1)
  - Criar `tests/integration/test_sync_workspace.bats`
  - Cenário: sync --scope workspace atualiza archetype
  - Cenário: sync --scope workspace sem manifest (exit 1)
  - Criar `tests/integration/test_migration.bats`
  - Cenário: migração de projeto legado (remove baseline, atualiza manifest)
  - Cenário: migração já feita (exit 0 sem mudanças)
  - Cenário: migração com --dry-run
  - Cenário: migração sem manifest (exit 1)
  - **Requirements:** 4, 5, 11, 12
  - **Design:** Testing Strategy — Integration tests

- [x] 15. Testes de integração — doctor com scope e CI
  - Criar `tests/integration/test_doctor_user_scope.bats`
  - Cenário: tudo instalado e atualizado (todos PASS)
  - Cenário: steering desatualizado (WARN)
  - Cenário: steering ausente (FAIL)
  - Cenário: ~/.kiro/ ausente (FAIL)
  - Cenário: --output json produz JSON válido
  - Criar `tests/integration/test_doctor_workspace.bats`
  - Cenário: archetype conforme (PASS)
  - Cenário: manifest sem baseline.scope (WARN legado)
  - Cenário: override detectado (INFO)
  - Criar `tests/integration/test_ci_environment.bats`
  - Cenário: doctor --scope workspace em CI não acessa ~/.kiro/
  - Cenário: bootstrap --scope user em CI = skip
  - Cenário: sync --scope workspace em CI funciona sem ~/.kiro/
  - Criar `tests/integration/test_legacy_compat.bats`
  - Cenário: sync sem --scope com manifest legado (comportamento antigo)
  - Cenário: doctor com manifest legado (verifica tudo no workspace)
  - **Requirements:** 6, 7, 8, 10
  - **Design:** Testing Strategy — Integration tests

- [x] 16. Atualizar documentação
  - Atualizar `scripts/bootstrap.sh` header com nova documentação de uso incluindo --scope
  - Atualizar `scripts/sync.sh` header com nova documentação incluindo --scope e --migrate-to-user-scope
  - Atualizar `scripts/doctor.sh` header com nova documentação incluindo --scope
  - Atualizar `docs/onboarding.md` com novo fluxo: bootstrap --scope user + bootstrap --scope workspace
  - Atualizar `README.md` do repositório com menção ao modelo dual-scope
  - Criar/atualizar seção em `docs/governance.md` sobre migração de projetos existentes
  - Atualizar `examples/kiro-manifest.example.json` com formato v2 (baseline.scope: "user")
  - **Requirements:** Todos (documentação)
  - **Design:** Overview, Components and Interfaces

## Task Dependency Graph

```json
{
  "waves": [
    {
      "name": "Wave 1 — Fundação",
      "tasks": [1],
      "description": "Módulo de funções compartilhadas (base para tudo)"
    },
    {
      "name": "Wave 2 — Refatoração dos Scripts",
      "tasks": [2, 4, 8],
      "description": "Adicionar --scope parsing e routing nos 3 scripts"
    },
    {
      "name": "Wave 3 — Implementação User Scope",
      "tasks": [3, 5, 9],
      "description": "Implementar lógica --scope user em bootstrap, sync e doctor"
    },
    {
      "name": "Wave 4 — Implementação Workspace Scope",
      "tasks": [6, 10],
      "description": "Implementar lógica --scope workspace em sync e doctor"
    },
    {
      "name": "Wave 5 — Migração e Compatibilidade",
      "tasks": [7, 11],
      "description": "Migração de projetos existentes e retrocompatibilidade"
    },
    {
      "name": "Wave 6 — Testes",
      "tasks": [12, 13, 14, 15],
      "description": "Testes unitários e de integração para todos os cenários"
    },
    {
      "name": "Wave 7 — Documentação",
      "tasks": [16],
      "description": "Atualizar docs, headers e exemplos"
    }
  ]
}
```

## Notes

- Todos os testes usam diretórios temporários para simular `~/.kiro/` e `.kiro/` (isolamento total)
- A variável `HOME_OVERRIDE` permite testes rodarem sem tocar o home real do desenvolvedor
- `jq` é dependência soft — scripts degradam graceful usando grep/sed quando ausente
- A migração usa trap para SIGINT/SIGTERM garantindo rollback mesmo em interrupção
