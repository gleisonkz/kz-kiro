#!/usr/bin/env bats
# Testes unitários para hooks do archetype backend-csharp.
# Valida existência, schema, conteúdo e comportamento dos 7 hooks.
# Requisitos: 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 7.1, 7.2, 7.3, 7.4

setup() {
  load '../helpers/assertions'
  HOOKS_DIR="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/hooks"
}

# --- Existência dos 7 hooks ---

@test "hooks: diretório hooks/ existe" {
  [ -d "${HOOKS_DIR}" ]
}

@test "hooks: build-after-agent.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/build-after-agent.kiro.hook" ]
}

@test "hooks: review-domain-boundaries.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-domain-boundaries.kiro.hook" ]
}

@test "hooks: review-endpoint-quality.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-endpoint-quality.kiro.hook" ]
}

@test "hooks: review-data-model.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/review-data-model.kiro.hook" ]
}

@test "hooks: migration-reminder.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/migration-reminder.kiro.hook" ]
}

@test "hooks: run-tests-after-task.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/run-tests-after-task.kiro.hook" ]
}

@test "hooks: kiro-doctor.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/kiro-doctor.kiro.hook" ]
}

@test "hooks: existem exatamente 7 hooks (excluindo README)" {
  local count
  count=$(find "${HOOKS_DIR}" -maxdepth 1 -name '*.kiro.hook' | wc -l | tr -d ' ')
  [ "$count" -eq 7 ]
}

# --- JSON válido em todos os hooks ---

@test "hooks: build-after-agent é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/build-after-agent.kiro.hook"
}

@test "hooks: review-domain-boundaries é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
}

@test "hooks: review-endpoint-quality é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
}

@test "hooks: review-data-model é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/review-data-model.kiro.hook"
}

@test "hooks: migration-reminder é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/migration-reminder.kiro.hook"
}

@test "hooks: run-tests-after-task é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/run-tests-after-task.kiro.hook"
}

@test "hooks: kiro-doctor é JSON válido" {
  assert_json_valid "${HOOKS_DIR}/kiro-doctor.kiro.hook"
}

# --- build-after-agent: conteúdo (Req 3.1, 3.2) ---

@test "build-after-agent: contém comando dotnet build --no-restore no prompt" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/build-after-agent.kiro.hook"
  assert_success
  assert_output --partial 'dotnet build --no-restore'
}

@test "build-after-agent: tem trigger agentStop" {
  assert_json_field "${HOOKS_DIR}/build-after-agent.kiro.hook" '.when.type' 'agentStop'
}

@test "build-after-agent: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/build-after-agent.kiro.hook" '.then.type' 'askAgent'
}

@test "build-after-agent: enabled é true" {
  assert_json_field "${HOOKS_DIR}/build-after-agent.kiro.hook" '.enabled' 'true'
}

@test "build-after-agent: versão é 2" {
  assert_json_field "${HOOKS_DIR}/build-after-agent.kiro.hook" '.version' '2'
}

@test "build-after-agent: prompt verifica escrita de .cs antes de executar" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/build-after-agent.kiro.hook"
  assert_success
  assert_output --partial '.cs'
}

@test "build-after-agent: prompt contém verificação condicional (não faça nada)" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/build-after-agent.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

# --- review-domain-boundaries: conteúdo (Req 4.1, 4.3, 4.4) ---

@test "review-domain-boundaries: tem trigger agentStop" {
  assert_json_field "${HOOKS_DIR}/review-domain-boundaries.kiro.hook" '.when.type' 'agentStop'
}

@test "review-domain-boundaries: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/review-domain-boundaries.kiro.hook" '.then.type' 'askAgent'
}

@test "review-domain-boundaries: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-domain-boundaries.kiro.hook" '.enabled' 'true'
}

@test "review-domain-boundaries: versão é 2" {
  assert_json_field "${HOOKS_DIR}/review-domain-boundaries.kiro.hook" '.version' '2'
}

@test "review-domain-boundaries: prompt verifica escrita antes de agir" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

@test "review-domain-boundaries: revisa Domain sem dependências externas" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'Domain'
  assert_output --partial 'pacotes externos'
}

@test "review-domain-boundaries: revisa Application sem Infrastructure" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'Application'
  assert_output --partial 'Infrastructure'
}

@test "review-domain-boundaries: revisa Infrastructure sem regras de negócio" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'Infrastructure'
  assert_output --partial 'regras de negócio'
}

@test "review-domain-boundaries: revisa Api com MediatR/ISender" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'MediatR'
  assert_output --partial 'ISender'
}

@test "review-domain-boundaries: revisa CancellationToken propagado" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'CancellationToken'
}

@test "review-domain-boundaries: revisa entidades com construtores privados e factory methods" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial 'construtores privados'
  assert_output --partial 'factory methods'
}

@test "review-domain-boundaries: verifica .cs em src/" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-domain-boundaries.kiro.hook"
  assert_success
  assert_output --partial '.cs'
  assert_output --partial 'src/'
}

# --- review-endpoint-quality: conteúdo (Req 4.2, 4.3, 4.4) ---

@test "review-endpoint-quality: tem trigger agentStop" {
  assert_json_field "${HOOKS_DIR}/review-endpoint-quality.kiro.hook" '.when.type' 'agentStop'
}

@test "review-endpoint-quality: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/review-endpoint-quality.kiro.hook" '.then.type' 'askAgent'
}

@test "review-endpoint-quality: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-endpoint-quality.kiro.hook" '.enabled' 'true'
}

@test "review-endpoint-quality: versão é 2" {
  assert_json_field "${HOOKS_DIR}/review-endpoint-quality.kiro.hook" '.version' '2'
}

@test "review-endpoint-quality: prompt verifica escrita antes de agir" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

@test "review-endpoint-quality: revisa documentação OpenAPI (WithName)" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'WithName'
}

@test "review-endpoint-quality: revisa documentação OpenAPI (WithTags)" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'WithTags'
}

@test "review-endpoint-quality: revisa documentação OpenAPI (Produces)" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'Produces'
}

@test "review-endpoint-quality: revisa documentação OpenAPI (ProducesProblem)" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'ProducesProblem'
}

@test "review-endpoint-quality: revisa uso de ISender" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'ISender'
}

@test "review-endpoint-quality: revisa CancellationToken" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'CancellationToken'
}

@test "review-endpoint-quality: revisa RequireAuthorization" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'RequireAuthorization'
}

@test "review-endpoint-quality: revisa nomenclatura {Verb}{Resource}Endpoint.cs" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial '{Verb}{Resource}Endpoint'
}

@test "review-endpoint-quality: revisa rota /api/v1/ kebab-case" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial '/api/v1/'
  assert_output --partial 'kebab-case'
}

@test "review-endpoint-quality: revisa FluentValidation no handler" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-endpoint-quality.kiro.hook"
  assert_success
  assert_output --partial 'FluentValidation'
}

# --- review-data-model: conteúdo (Req 5.1, 5.3) ---

@test "review-data-model: tem trigger preToolUse" {
  assert_json_field "${HOOKS_DIR}/review-data-model.kiro.hook" '.when.type' 'preToolUse'
}

@test "review-data-model: tem toolTypes write" {
  run jq -r '.when.toolTypes[0]' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output 'write'
}

@test "review-data-model: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/review-data-model.kiro.hook" '.then.type' 'askAgent'
}

@test "review-data-model: enabled é true" {
  assert_json_field "${HOOKS_DIR}/review-data-model.kiro.hook" '.enabled' 'true'
}

@test "review-data-model: versão é 1" {
  assert_json_field "${HOOKS_DIR}/review-data-model.kiro.hook" '.version' '1'
}

@test "review-data-model: valida ToTable snake_case" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'ToTable'
  assert_output --partial 'snake_case'
}

@test "review-data-model: valida HasComment na tabela em pt-BR" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'HasComment'
  assert_output --partial 'pt-BR'
}

@test "review-data-model: valida HasColumnName com prefixo de natureza" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'HasColumnName'
  assert_output --partial 'prefixo'
}

@test "review-data-model: valida HasPrecision(18, 8) para monetários" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'HasPrecision(18, 8)'
}

@test "review-data-model: valida campos de auditoria tmp_creation e tmp_update" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'tmp_creation'
  assert_output --partial 'tmp_update'
}

@test "review-data-model: valida PK com pk_" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'pk_'
}

@test "review-data-model: valida FK com fk_" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'fk_'
}

@test "review-data-model: valida indices com ix_" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'ix_'
}

@test "review-data-model: valida HasComment em colunas pt-BR" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'HasComment'
  assert_output --partial 'coluna'
}

@test "review-data-model: prompt permite operação sem comentários quando não é Configuration" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/review-data-model.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

# --- migration-reminder: conteúdo (Req 5.2, 5.4) ---

@test "migration-reminder: tem trigger postToolUse" {
  assert_json_field "${HOOKS_DIR}/migration-reminder.kiro.hook" '.when.type' 'postToolUse'
}

@test "migration-reminder: tem toolTypes write" {
  run jq -r '.when.toolTypes[0]' "${HOOKS_DIR}/migration-reminder.kiro.hook"
  assert_success
  assert_output 'write'
}

@test "migration-reminder: tem ação askAgent" {
  assert_json_field "${HOOKS_DIR}/migration-reminder.kiro.hook" '.then.type' 'askAgent'
}

@test "migration-reminder: enabled é true" {
  assert_json_field "${HOOKS_DIR}/migration-reminder.kiro.hook" '.enabled' 'true'
}

@test "migration-reminder: versão é 1" {
  assert_json_field "${HOOKS_DIR}/migration-reminder.kiro.hook" '.version' '1'
}

@test "migration-reminder: cita gerar migration (dotnet ef migrations add)" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/migration-reminder.kiro.hook"
  assert_success
  assert_output --partial 'dotnet ef migrations add'
}

@test "migration-reminder: cita gerar pacote de validação (generate-validation-package)" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/migration-reminder.kiro.hook"
  assert_success
  assert_output --partial 'generate-validation-package'
}

@test "migration-reminder: cita submeter ao chapter de dados" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/migration-reminder.kiro.hook"
  assert_success
  assert_output --partial 'chapter de dados'
}

@test "migration-reminder: prompt não faz nada quando não é Configuration" {
  run jq -r '.then.prompt' "${HOOKS_DIR}/migration-reminder.kiro.hook"
  assert_success
  assert_output --partial 'não faça nada'
}

# --- run-tests-after-task: conteúdo (Req 6.1) ---

@test "run-tests-after-task: tem ação runCommand" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.then.type' 'runCommand'
}

@test "run-tests-after-task: comando é dotnet test" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.then.command' 'dotnet test'
}

@test "run-tests-after-task: tem trigger postTaskExecution" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.when.type' 'postTaskExecution'
}

@test "run-tests-after-task: enabled é true" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.enabled' 'true'
}

@test "run-tests-after-task: versão é 2" {
  assert_json_field "${HOOKS_DIR}/run-tests-after-task.kiro.hook" '.version' '2'
}

# --- kiro-doctor: conteúdo (Req 7.1, 7.2, 7.3, 7.4) ---

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
