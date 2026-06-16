# Implementation Plan: Baseline Global

## Overview

Este plano cobre as tarefas remanescentes para completar a feature baseline-global. Os scripts principais (bootstrap.sh, sync.sh, doctor.sh) já estão implementados, assim como os artefatos estáticos (VERSION, CHANGELOG, hooks, mcp.json, steering files com frontmatter). O foco é: configurar o framework de testes bats-core, implementar testes de propriedade e integração, e adicionar a lógica de exceções ao doctor.sh.

## Tasks

- [x] 1. Configurar framework de testes bats-core
  - [x] 1.1 Criar estrutura de diretórios e instalar bats-core
    - Criar `tests/unit/`, `tests/integration/`, `tests/properties/`, `tests/helpers/`
    - Adicionar bats-core, bats-support e bats-assert como submódulos git em `tests/lib/`
    - Criar script `tests/run_tests.sh` que executa todas as suítes
    - _Requisitos: Design — Testing Strategy_
  - [x] 1.2 Criar helpers de teste — generators.bash
    - Implementar funções geradoras de dados aleatórios: `gen_semver`, `gen_invalid_semver`, `gen_frontmatter`, `gen_invalid_frontmatter`, `gen_mcp_json`, `gen_invalid_mcp_json`, `gen_exception`, `gen_invalid_exception`
    - Cada gerador deve produzir dados válidos e inválidos para property testing
    - Implementar `gen_steering_file`, `gen_hook_json`, `gen_project_type`
    - _Requisitos: Design — Testing Strategy, Correctness Properties 1-10_
  - [x] 1.3 Criar helpers de teste — setup.bash e assertions.bash
    - `setup.bash`: funções `create_temp_project`, `create_baseline_fixture`, `cleanup_fixtures`, `setup_manifest`
    - `assertions.bash`: funções `assert_file_identical`, `assert_json_valid`, `assert_exit_code`, `assert_no_fs_changes`, `assert_json_field`
    - Integrar com bats-assert para mensagens de erro descritivas
    - _Requisitos: Design — Testing Strategy_

- [x] 2. Implementar lógica de exceções no doctor.sh
  - [x] 2.1 Adicionar função de verificação de exceções ao doctor.sh
    - Implementar função `check_exception()` que recebe o nome do artefato e verifica se existe exceção válida no manifest
    - Verificar campos obrigatórios: `rule`, `reason` (20-500 chars), `approved_by` (não-vazio), `approved_at` (ISO 8601), `review_date` (ISO 8601, max 90 dias de approved_at)
    - Quando exceção válida é encontrada: reportar INFO em vez de FAIL/WARN
    - Quando exceção expirada (`review_date` < data corrente): reportar WARN indicando expiração
    - Integrar a verificação em `check_baseline()` e `check_archetype()`
    - _Requisitos: 9.1, 9.3, 9.4, 9.5_
  - [x] 2.2 Adicionar validação de schema de exceções no doctor.sh
    - Implementar função `validate_exceptions()` que verifica cada exceção no array `exceptions` do manifest
    - Validar: `rule` no formato `<componente>.<nome>`, `reason` com 20-500 caracteres, `approved_by` não-vazio, `approved_at` ISO 8601 válida, `review_date` não excede 90 dias de `approved_at`
    - Reportar WARN para exceções com schema inválido
    - Integrar na seção `check_manifest()` do doctor.sh
    - _Requisitos: 9.1, 9.3_

- [x] 3. Checkpoint — Verificar que doctor.sh funciona com exceções
  - Garantir que os testes passam, perguntar ao usuário se surgirem dúvidas.

- [x] 4. Implementar testes de propriedade
  - [x] 4.1 Escrever teste de propriedade para validação de semver
    - **Property 1: Validação de formato semver**
    - **Valida: Requisitos 1.4, 3.3, 8.1, 8.5**
    - Gerar 20 strings aleatórias válidas e inválidas
    - Verificar que a regex/função aceita apenas `MAJOR.MINOR.PATCH` sem zeros à esquerda, sem prefixo `v`, sem espaços
    - Arquivo: `tests/properties/prop_semver.bats`
  - [x] 4.2 Escrever teste de propriedade para validação de frontmatter
    - **Property 2: Validação de frontmatter de steering file**
    - **Valida: Requisitos 1.6, 1.7, 2.9**
    - Gerar 20 conteúdos markdown aleatórios com e sem frontmatter válido
    - Verificar campo `inclusion` (manual|auto|fileMatch) e `fileMatchPattern` quando fileMatch
    - Arquivo: `tests/properties/prop_frontmatter.bats`
  - [x] 4.3 Escrever teste de propriedade para validação de schema mcp.json
    - **Property 3: Validação de schema mcp.json**
    - **Valida: Requisitos 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**
    - Gerar 20 objetos JSON aleatórios válidos e inválidos
    - Verificar `_comment`, `_version` (semver), `mcpServers` com ao menos 1 servidor, cada servidor com `_comment`, `disabled`, `autoApprove: []`, e `url` XOR (`command` + `args`)
    - Arquivo: `tests/properties/prop_mcp_schema.bats`
  - [x] 4.4 Escrever teste de propriedade para merge de mcp.json
    - **Property 4: Merge de mcp.json preserva todos os servidores**
    - **Valida: Requisitos 4.3**
    - Gerar 20 pares de objetos mcp.json e verificar que o merge contém todos os servidores
    - Verificar precedência do archetype sobre baseline em caso de conflito de chaves
    - Arquivo: `tests/properties/prop_merge_mcp.bats`
  - [x] 4.5 Escrever teste de propriedade para dry-run imutável
    - **Property 5: Dry-run não modifica filesystem**
    - **Valida: Requisitos 4.6, 5.6**
    - Gerar 20 combinações de estados de diretório e argumentos com `--dry-run`
    - Capturar snapshot do filesystem antes e depois e verificar identidade byte-a-byte
    - Arquivo: `tests/properties/prop_dry_run.bats`
  - [x] 4.6 Escrever teste de propriedade para sync tornar destino idêntico
    - **Property 6: Sync torna destino idêntico ao fonte**
    - **Valida: Requisitos 5.1, 5.2, 5.3**
    - Gerar 20 estados iniciais de steering files no destino (ausentes, desatualizados, idênticos)
    - Após sync, verificar que cada arquivo no destino é byte-a-byte idêntico ao fonte
    - Arquivo: `tests/properties/prop_sync_idempotent.bats`
  - [x] 4.7 Escrever teste de propriedade para classificação do doctor
    - **Property 7: Doctor classifica artefatos corretamente**
    - **Valida: Requisitos 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.10, 9.4, 9.5**
    - Gerar 20 combinações de estados de artefatos e exceções
    - Verificar classificação: PASS (idêntico), WARN (diferente), FAIL (ausente), INFO (exceção válida), WARN (exceção expirada)
    - Arquivo: `tests/properties/prop_doctor_classify.bats`
  - [x] 4.8 Escrever teste de propriedade para JSON output do doctor
    - **Property 8: Doctor produz JSON válido com schema correto**
    - **Valida: Requisitos 6.6**
    - Gerar 20 estados de verificação e executar com `--output json`
    - Verificar JSON parseável, campos `timestamp`, `target`, `summary` (inteiros cujas somas batem), `results` (array)
    - Arquivo: `tests/properties/prop_doctor_json.bats`
  - [x] 4.9 Escrever teste de propriedade para validação de exceções
    - **Property 9: Validação de schema de exceção**
    - **Valida: Requisitos 9.1, 9.3**
    - Gerar 20 objetos de exceção válidos e inválidos
    - Verificar: `rule` formato `<componente>.<nome>`, `reason` 20-500 chars, `approved_by` não-vazio, `approved_at` ISO 8601, `review_date` max 90 dias
    - Arquivo: `tests/properties/prop_exception_schema.bats`
  - [x] 4.10 Escrever teste de propriedade para inputs inválidos
    - **Property 10: Inputs inválidos resultam em falha**
    - **Valida: Requisitos 4.7, 5.9**
    - Gerar 20 valores aleatórios para `--project-type` e `--component` que não são válidos
    - Verificar exit code != 0 para cada caso
    - Arquivo: `tests/properties/prop_invalid_inputs.bats`

- [x] 5. Checkpoint — Executar testes de propriedade
  - Garantir que todos os testes passam, perguntar ao usuário se surgirem dúvidas.

- [x] 6. Implementar testes de integração
  - [x] 6.1 Escrever testes de integração para bootstrap.sh
    - Cenários: bootstrap novo projeto (happy path), --dry-run não altera filesystem, --force sobrescreve, project-type inválido (exit 1), target inexistente (exit 1), manifest já existe sem --force (skip com warning)
    - Verificar geração de manifest com campos corretos
    - Verificar merge de mcp.json (baseline + archetype)
    - Arquivo: `tests/integration/test_bootstrap.bats`
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_
  - [x] 6.2 Escrever testes de integração para sync.sh
    - Cenários: sync baseline (atualiza, adiciona, sem mudança), --component inválido (exit 1), manifest ausente (exit 1 + mensagem bootstrap), --dry-run lista sem alterar, resumo de contagens correto
    - Verificar atualização de `baseline.last_synced_at` no manifest
    - Arquivo: `tests/integration/test_sync.bats`
    - _Requisitos: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10_
  - [x] 6.3 Escrever testes de integração para doctor.sh
    - Cenários: projeto saudável (exit 0), steering ausente (FAIL, exit 1), steering desatualizado (WARN), --verbose mostra diffs, --output json produz JSON válido, exceção válida (INFO), exceção expirada (WARN), mcp divergente (WARN)
    - Verificar tratamento de exceções integrado
    - Arquivo: `tests/integration/test_doctor.bats`
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 9.4, 9.5_

- [x] 7. Validar artefatos estáticos do baseline
  - [x] 7.1 Validar conformidade do VERSION file
    - Verificar formato exato: uma linha, semver sem prefixo `v`, sem espaços, sem newline final (`0.1.0`)
    - Corrigir se necessário (trailing newline detectado no arquivo atual)
    - _Requisitos: 1.4, 8.1, 8.5_
  - [x] 7.2 Validar conformidade do CHANGELOG.md
    - Verificar que segue Keep a Changelog: título, seção por versão com data, tipos de mudança
    - Verificar que a versão `0.1.0` declarada no VERSION tem entrada correspondente no CHANGELOG
    - _Requisitos: 1.5_
  - [x] 7.3 Validar conformidade do kiro-doctor.kiro.hook
    - Verificar schema: `enabled` (boolean), `name` (string), `description` (string), `version` (string), `when.type` = `userTriggered`, `then.type` = `askAgent`, `then.prompt` (string)
    - _Requisitos: 10.1, 10.2, 10.3, 10.4_
  - [x] 7.4 Validar conformidade do mcp.json
    - Verificar schema: `_comment` (string não-vazia), `_version` (semver), `mcpServers` com ao menos 1 servidor
    - Cada servidor: `_comment`, `disabled` (boolean), `autoApprove: []`, e `url` XOR (`command` + `args`)
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 8. Checkpoint final — Garantir conformidade completa
  - Executar `./tests/run_tests.sh` e garantir que todos os testes passam.
  - Executar `./scripts/doctor.sh --target .` para auto-diagnóstico.
  - Perguntar ao usuário se surgirem dúvidas.

## Notes

- Tasks marcadas com `*` são opcionais e podem ser puladas para um MVP mais rápido
- Cada task referencia requisitos específicos para rastreabilidade
- Checkpoints garantem validação incremental
- Testes de propriedade validam propriedades universais de correção (20 iterações cada)
- Testes de integração validam cenários end-to-end específicos
- O projeto usa bash + jq para scripts, bats-core para testes
- Este é um spec retroativo — scripts já existem, foco é em testes e lógica de exceções

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3"] },
    { "id": 2, "tasks": ["2.1", "2.2", "7.1", "7.2", "7.3", "7.4"] },
    { "id": 3, "tasks": ["4.1", "4.2", "4.3", "4.9", "4.10"] },
    { "id": 4, "tasks": ["4.4", "4.5", "4.6", "4.7", "4.8"] },
    { "id": 5, "tasks": ["6.1", "6.2", "6.3"] }
  ]
}
```
