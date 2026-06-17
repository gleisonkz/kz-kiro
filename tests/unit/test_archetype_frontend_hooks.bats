#!/usr/bin/env bats
# Testes unitários para hooks do archetype frontend-react.
# Valida existência, schema, conteúdo e comportamento dos 8 hooks.
# Requisitos: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4

setup() {
  load '../helpers/assertions'
  HOOKS_DIR="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react/hooks"
}

# --- Existência dos 8 hooks ---

@test "hooks: diretório hooks/ existe" {
  [ -d "${HOOKS_DIR}" ]
}

@test "hooks: lint-after-agent.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/lint-after-agent.kiro.hook" ]
}

@test "hooks: typecheck-on-save.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/typecheck-on-save.kiro.hook" ]
}

@test "hooks: review-component-quality.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-component-quality.kiro.hook" ]
}

@test "hooks: review-feature-boundaries.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-feature-boundaries.kiro.hook" ]
}

@test "hooks: review-naming-conventions.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-naming-conventions.kiro.hook" ]
}

@test "hooks: run-tests-after-task.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/run-tests-after-task.kiro.hook" ]
}

@test "hooks: remind-test-coverage.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/remind-test-coverage.kiro.hook" ]
}

@test "hooks: kiro-doctor.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/kiro-doctor.kiro.hook" ]
}

@test "hooks: existem exatamente 8 hooks (excluindo README)" {
  local count
  count=$(find "${HOOKS_DIR}" -maxdepth 1 -name '*.kiro.hook' | wc -l | tr -d ' ')
  [ "$count" -eq 8 ]
}

# --- JSON válido em todos os hooks ---

@test "hooks: lint-after-agent é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/lint-after-agent.kiro.hook"
}

@test "hooks: typecheck-on-save é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/typecheck-on-save.kiro.hook"
}

@test "hooks: review-component-quality é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-component-quality.kiro.hook"
}

@test "hooks: review-feature-boundaries é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-feature-boundaries.kiro.hook"
}

@test "hooks: review-naming-conventions é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-naming-conventions.kiro.hook"
}

@test "hooks: run-tests-after-task é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/run-tests-after-task.kiro.hook"
}

@test "hooks: remind-test-coverage é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/remind-test-coverage.kiro.hook"
}

@test "hooks: kiro-doctor é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/kiro-doctor.kiro.hook"
}

# --- lint-after-agent: conteúdo (Req 3.1, 3.2) ---

@test "lint-after-agent: contém comando pnpm turbo lint --affected no prompt" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/lint-after-agent.kiro.hook"
  assert_success
  assert_output --partial 'pnpm turbo lint --affected'
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

@test "typecheck-on-save: contém comando npx tsc --noEmit --pretty no prompt" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/typecheck-on-save.kiro.hook"
  assert_success
  assert_output --partial 'npx tsc --noEmit --pretty'
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

# --- run-tests-after-task: conteúdo (Req 5.1) ---

@test "run-tests-after-task: tem ação runCommand" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.then.type' 'runCommand'
}

@test "run-tests-after-task: comando é npx vitest --run --reporter=verbose" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.then.command' 'npx vitest --run --reporter=verbose'
}

@test "run-tests-after-task: tem trigger postTaskExecution" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.when.type' 'postTaskExecution'
}

@test "run-tests-after-task: enabled é true" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.enabled' 'true'
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

# --- Versão "2" nos hooks com verificação condicional ---

@test "hooks condicionais: review-component-quality tem versão 2" {
  assert_json_field "${HOOKS_DIR}/review-component-quality.kiro.hook" '.version' '2'
}

@test "hooks condicionais: review-feature-boundaries tem versão 2" {
  assert_json_field "${HOOKS_DIR}/review-feature-boundaries.kiro.hook" '.version' '2'
}

@test "hooks condicionais: review-naming-conventions tem versão 2" {
  assert_json_field "${HOOKS_DIR}/review-naming-conventions.kiro.hook" '.version' '2'
}

@test "hooks condicionais: remind-test-coverage tem versão 2" {
  assert_json_field "${HOOKS_DIR}/remind-test-coverage.kiro.hook" '.version' '2'
}

# --- Hooks de revisão arquitetural: enabled e instrução condicional (Req 4.4) ---

@test "review-component-quality: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-component-quality.kiro.hook" '.enabled' 'true'
}

@test "review-component-quality: prompt verifica escrita antes de agir" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-component-quality.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

@test "review-feature-boundaries: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-feature-boundaries.kiro.hook" '.enabled' 'true'
}

@test "review-feature-boundaries: prompt verifica escrita antes de agir" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-feature-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

@test "review-naming-conventions: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-naming-conventions.kiro.hook" '.enabled' 'true'
}

@test "review-naming-conventions: prompt verifica escrita antes de agir" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-naming-conventions.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

# --- remind-test-coverage (Req 5.2, 5.3) ---

@test "remind-test-coverage: tem trigger postTaskExecution" {
  assert_json_field "${HOOKS_DIR}/remind-test-coverage.kiro.hook" '.when.type' 'postTaskExecution'
}

@test "remind-test-coverage: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/remind-test-coverage.kiro.hook" '.then.type' 'askAgent'
}

@test "remind-test-coverage: enabled é true" {
  assert_json_field "${HOOKS_DIR}/remind-test-coverage.kiro.hook" '.enabled' 'true'
}

@test "remind-test-coverage: prompt menciona convenção componente .test.tsx" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/remind-test-coverage.kiro.hook"
  assert_success
  assert_output --partial '.test.tsx'
}

@test "remind-test-coverage: prompt menciona convenção hook .hook.test.ts" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/remind-test-coverage.kiro.hook"
  assert_success
  assert_output --partial '.hook.test.ts'
}

@test "remind-test-coverage: prompt menciona convenção slice .slice.test.ts" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/remind-test-coverage.kiro.hook"
  assert_success
  assert_output --partial '.slice.test.ts'
}

@test "remind-test-coverage: prompt menciona convenção selectors .selectors.test.ts" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/remind-test-coverage.kiro.hook"
  assert_success
  assert_output --partial '.selectors.test.ts'
}

@test "remind-test-coverage: prompt menciona convenção api .api.test.ts" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/remind-test-coverage.kiro.hook"
  assert_success
  assert_output --partial '.api.test.ts'
}
