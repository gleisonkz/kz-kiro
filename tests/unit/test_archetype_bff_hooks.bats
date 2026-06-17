#!/usr/bin/env bats
# Testes unitários para hooks do archetype bff-fastify.
# Valida existência, schema, conteúdo e comportamento dos 6 hooks.
# Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 5.1, 6.1, 6.2, 6.3, 6.4

setup() {
  load '../helpers/assertions'
  HOOKS_DIR="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify/hooks"
}

# --- Existência dos 6 hooks ---

@test "hooks: diretório hooks/ existe" {
  [ -d "${HOOKS_DIR}" ]
}

@test "hooks: lint-after-agent.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/lint-after-agent.kiro.hook" ]
}

@test "hooks: typecheck-on-save.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/typecheck-on-save.kiro.hook" ]
}

@test "hooks: review-route-quality.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-route-quality.kiro.hook" ]
}

@test "hooks: review-bff-boundaries.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-bff-boundaries.kiro.hook" ]
}

@test "hooks: run-tests-after-task.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/run-tests-after-task.kiro.hook" ]
}

@test "hooks: kiro-doctor.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/kiro-doctor.kiro.hook" ]
}

@test "hooks: existem exatamente 6 hooks (excluindo README)" {
  local count
  count=$(find "${HOOKS_DIR}" -maxdepth 1 -name '*.kiro.hook' | wc -l | tr -d ' ')
  [ "$count" -eq 6 ]
}

# --- JSON válido em todos os hooks ---

@test "hooks: lint-after-agent é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/lint-after-agent.kiro.hook"
}

@test "hooks: typecheck-on-save é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/typecheck-on-save.kiro.hook"
}

@test "hooks: review-route-quality é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-route-quality.kiro.hook"
}

@test "hooks: review-bff-boundaries é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
}

@test "hooks: run-tests-after-task é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/run-tests-after-task.kiro.hook"
}

@test "hooks: kiro-doctor é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/kiro-doctor.kiro.hook"
}

# --- lint-after-agent: conteúdo (Req 3.1, 3.2) ---

@test "lint-after-agent: contém comando pnpm lint no prompt" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/lint-after-agent.kiro.hook"
  assert_success
  assert_output --partial 'pnpm lint'
}

@test "lint-after-agent: tem trigger agentStop" {
  assert_json_field "${HOOKS_DIR}/lint-after-agent.kiro.hook" '.when.type' 'agentStop'
}

@test "lint-after-agent: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/lint-after-agent.kiro.hook" '.then.type' 'askAgent'
}

@test "lint-after-agent: enabled é true" {
  assert_json_field "${HOOKS_DIR}/lint-after-agent.kiro.hook" '.enabled' 'true'
}

@test "lint-after-agent: versão é 2" {
  assert_json_field "${HOOKS_DIR}/lint-after-agent.kiro.hook" '.version' '2'
}

@test "lint-after-agent: prompt verifica escrita antes de executar" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/lint-after-agent.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

# --- typecheck-on-save: conteúdo (Req 3.3, 3.4) ---

@test "typecheck-on-save: contém comando pnpm typecheck no prompt" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/typecheck-on-save.kiro.hook"
  assert_success
  assert_output --partial 'pnpm typecheck'
}

@test "typecheck-on-save: tem trigger agentStop" {
  assert_json_field "${HOOKS_DIR}/typecheck-on-save.kiro.hook" '.when.type' 'agentStop'
}

@test "typecheck-on-save: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/typecheck-on-save.kiro.hook" '.then.type' 'askAgent'
}

@test "typecheck-on-save: enabled é true" {
  assert_json_field "${HOOKS_DIR}/typecheck-on-save.kiro.hook" '.enabled' 'true'
}

@test "typecheck-on-save: versão é 2" {
  assert_json_field "${HOOKS_DIR}/typecheck-on-save.kiro.hook" '.version' '2'
}

@test "typecheck-on-save: prompt verifica escrita antes de executar" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/typecheck-on-save.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

# --- review-route-quality: conteúdo (Req 4.1, 4.3, 4.4) ---

@test "review-route-quality: tem trigger agentStop" {
  assert_json_field "${HOOKS_DIR}/review-route-quality.kiro.hook" '.when.type' 'agentStop'
}

@test "review-route-quality: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/review-route-quality.kiro.hook" '.then.type' 'askAgent'
}

@test "review-route-quality: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-route-quality.kiro.hook" '.enabled' 'true'
}

@test "review-route-quality: versão é 2" {
  assert_json_field "${HOOKS_DIR}/review-route-quality.kiro.hook" '.version' '2'
}

@test "review-route-quality: prompt verifica escrita antes de agir" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

@test "review-route-quality: revisa schemas Zod" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial 'SCHEMAS ZOD'
}

@test "review-route-quality: revisa separação de responsabilidades" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial 'SEPARAÇÃO'
}

@test "review-route-quality: revisa plugin pattern" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial 'PLUGIN PATTERN'
}

@test "review-route-quality: revisa error handling" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial 'ERROR HANDLING'
}

@test "review-route-quality: revisa nomenclatura" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial 'NOMENCLATURA'
}

@test "review-route-quality: revisa prefixo de módulo" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial 'PREFIXO'
}

# --- review-bff-boundaries: conteúdo (Req 4.2, 4.3, 4.4) ---

@test "review-bff-boundaries: tem trigger agentStop" {
  assert_json_field "${HOOKS_DIR}/review-bff-boundaries.kiro.hook" '.when.type' 'agentStop'
}

@test "review-bff-boundaries: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/review-bff-boundaries.kiro.hook" '.then.type' 'askAgent'
}

@test "review-bff-boundaries: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-bff-boundaries.kiro.hook" '.enabled' 'true'
}

@test "review-bff-boundaries: versão é 2" {
  assert_json_field "${HOOKS_DIR}/review-bff-boundaries.kiro.hook" '.version' '2'
}

@test "review-bff-boundaries: prompt verifica escrita antes de agir" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

@test "review-bff-boundaries: revisa zero regras de negócio" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'regras de negócio'
}

@test "review-bff-boundaries: revisa services orquestram clients" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'orquestrar chamadas a clients'
}

@test "review-bff-boundaries: revisa mappers puros" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'funções puras'
}

@test "review-bff-boundaries: revisa sem acesso a banco" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'banco de dados'
}

@test "review-bff-boundaries: revisa módulos encapsulados" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'implementações internas de outros módulos'
}

@test "review-bff-boundaries: revisa rotas sem lógica de orquestração" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'Rotas não devem conter lógica de orquestração'
}

@test "review-bff-boundaries: revisa validações apenas de contrato" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'contrato'
}

@test "review-bff-boundaries: revisa contratos explicitos entre modulos" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'contratos explícitos'
}

# --- run-tests-after-task: conteúdo (Req 5.1) ---

@test "run-tests-after-task: tem ação runCommand" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.then.type' 'runCommand'
}

@test "run-tests-after-task: comando é pnpm test" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.then.command' 'pnpm test'
}

@test "run-tests-after-task: tem trigger postTaskExecution" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.when.type' 'postTaskExecution'
}

@test "run-tests-after-task: enabled é true" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.enabled' 'true'
}

@test "run-tests-after-task: versão é 1" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.version' '1'
}

# --- kiro-doctor: conteúdo (Req 6.1, 6.2, 6.3, 6.4) ---

@test "kiro-doctor: tem trigger userTriggered" {
  assert_json_field "${HOOKS_DIR}/kiro-doctor.kiro.hook" '.when.type' 'userTriggered'
}

@test "kiro-doctor: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/kiro-doctor.kiro.hook" '.then.type' 'askAgent'
}

@test "kiro-doctor: enabled é true" {
  assert_json_field "${HOOKS_DIR}/kiro-doctor.kiro.hook" '.enabled' 'true'
}

@test "kiro-doctor: versão é 1" {
  assert_json_field "${HOOKS_DIR}/kiro-doctor.kiro.hook" '.version' '1'
}

@test "kiro-doctor: prompt contém seção Resumo" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'Resumo'
}

@test "kiro-doctor: prompt contém seção Steering" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'Steering'
}

@test "kiro-doctor: prompt contém seção Hooks" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'Hooks'
}

@test "kiro-doctor: prompt contém seção MCP Servers" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'MCP Servers'
}

@test "kiro-doctor: prompt contém seção Skills" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'Skills'
}

@test "kiro-doctor: prompt contém seção Specs" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'Specs'
}

@test "kiro-doctor: prompt contém seção Arquitetura" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'Arquitetura'
}

@test "kiro-doctor: prompt contém seção Recomendações" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'Recomendações'
}

@test "kiro-doctor: prompt tem exatamente 8 seções no relatório" {
  local prompt
  prompt=$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")
  # Conta as seções marcadas com ** no relatório (formato: **Seção**)
  local count
  count=$(echo "$prompt" | grep -oE '\*\*[A-Z][^*]+\*\*' | grep -cE '(Resumo|Steering|Hooks|MCP Servers|Skills|Specs|Arquitetura|Recomendações)')
  [ "$count" -eq 8 ]
}

@test "kiro-doctor: prompt instrui salvar como kiro-doctor-report.md" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook"
  assert_success
  assert_output --partial 'kiro-doctor-report.md'
}

# --- Verificação condicional (.ts em src/) nos hooks de qualidade e revisão ---

@test "hooks condicionais: review-route-quality verifica .ts em src/" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-route-quality.kiro.hook"
  assert_success
  assert_output --partial '.ts'
  assert_output --partial 'src/'
}

@test "hooks condicionais: review-bff-boundaries verifica .ts em src/" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-bff-boundaries.kiro.hook"
  assert_success
  assert_output --partial '.ts'
  assert_output --partial 'src/'
}

@test "hooks condicionais: lint-after-agent verifica .ts em src/" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/lint-after-agent.kiro.hook"
  assert_success
  assert_output --partial '.ts'
  assert_output --partial 'src/'
}

@test "hooks condicionais: typecheck-on-save verifica .ts em src/" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/typecheck-on-save.kiro.hook"
  assert_success
  assert_output --partial '.ts'
  assert_output --partial 'src/'
}
