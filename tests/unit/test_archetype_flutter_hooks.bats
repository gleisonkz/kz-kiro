#!/usr/bin/env bats
# Testes unitários para os 5 hooks do archetype mobile-flutter.
# Valida existência, schema JSON, triggers, patterns, ações e conteúdo dos prompts.
# Requisitos: 5.1, 5.2, 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 8.1, 8.2, 8.3, 8.4, 9.1, 9.2, 9.3, 9.4

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"
  HOOKS_DIR="${ARCHETYPE_DIR}/hooks"
}

# =============================================================================
# Existência dos 5 hooks com nomes corretos
# =============================================================================

@test "hooks: existem exatamente 5 arquivos .kiro.hook" {
  local count
  count=$(find "${HOOKS_DIR}" -maxdepth 1 -name '*.kiro.hook' | wc -l | tr -d ' ')
  [ "$count" -eq 5 ]
}

@test "hooks: dart-analyze-save.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/dart-analyze-save.kiro.hook" ]
}

@test "hooks: check-relative-imports.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/check-relative-imports.kiro.hook" ]
}

@test "hooks: barrel-export-reminder.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/barrel-export-reminder.kiro.hook" ]
}

@test "hooks: scaffold-test-file.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/scaffold-test-file.kiro.hook" ]
}

@test "hooks: kiro-doctor.kiro.hook existe" {
  [ -f "${HOOKS_DIR}/kiro-doctor.kiro.hook" ]
}

# =============================================================================
# Todos os hooks: JSON válido, enabled, version "1"
# =============================================================================

@test "hooks: todos os 5 hooks são JSON válido" {
  local hook
  for hook in "${HOOKS_DIR}"/*.kiro.hook; do
    assert_json_valid "$hook"
  done
}

@test "hooks: todos os 5 hooks têm enabled true" {
  local hook
  for hook in "${HOOKS_DIR}"/*.kiro.hook; do
    local enabled
    enabled="$(jq '.enabled' "$hook")"
    if [ "$enabled" != "true" ]; then
      fail "Hook $(basename "$hook") tem enabled=$enabled (esperado: true)"
    fi
  done
}

@test "hooks: todos os 5 hooks têm version '1'" {
  local hook
  for hook in "${HOOKS_DIR}"/*.kiro.hook; do
    local version
    version="$(jq -r '.version' "$hook")"
    if [ "$version" != "1" ]; then
      fail "Hook $(basename "$hook") tem version=$version (esperado: '1')"
    fi
  done
}

# =============================================================================
# dart-analyze-save: trigger fileEdited, patterns ["**/*.dart"], runCommand
# Requisitos: 5.1, 5.2
# =============================================================================

@test "dart-analyze-save: name é 'Dart Analyze on Save'" {
  assert_json_field "${HOOKS_DIR}/dart-analyze-save.kiro.hook" '.name' 'Dart Analyze on Save'
}

@test "dart-analyze-save: when.type é fileEdited" {
  assert_json_field "${HOOKS_DIR}/dart-analyze-save.kiro.hook" '.when.type' 'fileEdited'
}

@test "dart-analyze-save: patterns contém '**/*.dart'" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/dart-analyze-save.kiro.hook")"
  [[ "$patterns" == '["**/*.dart"]' ]]
}

@test "dart-analyze-save: then.type é runCommand" {
  assert_json_field "${HOOKS_DIR}/dart-analyze-save.kiro.hook" '.then.type' 'runCommand'
}

@test "dart-analyze-save: command executa dart analyze com \$KIRO_FILE_PATH" {
  local command
  command="$(jq -r '.then.command' "${HOOKS_DIR}/dart-analyze-save.kiro.hook")"
  [[ "$command" == *'dart analyze'* ]]
  [[ "$command" == *'$KIRO_FILE_PATH'* ]]
}

# =============================================================================
# check-relative-imports: trigger fileEdited, patterns ["**/*.dart"], runCommand com grep
# Requisitos: 6.1, 6.2, 6.3
# =============================================================================

@test "check-relative-imports: name é 'Check Relative Imports'" {
  assert_json_field "${HOOKS_DIR}/check-relative-imports.kiro.hook" '.name' 'Check Relative Imports'
}

@test "check-relative-imports: when.type é fileEdited" {
  assert_json_field "${HOOKS_DIR}/check-relative-imports.kiro.hook" '.when.type' 'fileEdited'
}

@test "check-relative-imports: patterns contém '**/*.dart'" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/check-relative-imports.kiro.hook")"
  [[ "$patterns" == '["**/*.dart"]' ]]
}

@test "check-relative-imports: then.type é runCommand" {
  assert_json_field "${HOOKS_DIR}/check-relative-imports.kiro.hook" '.then.type' 'runCommand'
}

@test "check-relative-imports: command usa grep para detectar imports relativos" {
  local command
  command="$(jq -r '.then.command' "${HOOKS_DIR}/check-relative-imports.kiro.hook")"
  [[ "$command" == *'grep'* ]]
  [[ "$command" == *'import'* ]]
}

@test "check-relative-imports: command referencia \$KIRO_FILE_PATH" {
  local command
  command="$(jq -r '.then.command' "${HOOKS_DIR}/check-relative-imports.kiro.hook")"
  [[ "$command" == *'$KIRO_FILE_PATH'* ]]
}

# =============================================================================
# barrel-export-reminder: trigger fileCreated, patterns pages/routes/widgets, askAgent
# Requisitos: 7.1, 7.2, 7.3
# =============================================================================

@test "barrel-export-reminder: name é 'Barrel Export Reminder'" {
  assert_json_field "${HOOKS_DIR}/barrel-export-reminder.kiro.hook" '.name' 'Barrel Export Reminder'
}

@test "barrel-export-reminder: when.type é fileCreated" {
  assert_json_field "${HOOKS_DIR}/barrel-export-reminder.kiro.hook" '.when.type' 'fileCreated'
}

@test "barrel-export-reminder: patterns inclui pages/*.dart" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/barrel-export-reminder.kiro.hook")"
  [[ "$patterns" == *'pages'* ]]
  [[ "$patterns" == *'.dart'* ]]
}

@test "barrel-export-reminder: patterns inclui routes/*.dart" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/barrel-export-reminder.kiro.hook")"
  [[ "$patterns" == *'routes'* ]]
}

@test "barrel-export-reminder: patterns inclui widgets/*.dart" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/barrel-export-reminder.kiro.hook")"
  [[ "$patterns" == *'widgets'* ]]
}

@test "barrel-export-reminder: then.type é askAgent" {
  assert_json_field "${HOOKS_DIR}/barrel-export-reminder.kiro.hook" '.then.type' 'askAgent'
}

@test "barrel-export-reminder: prompt menciona pubspec.yaml" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/barrel-export-reminder.kiro.hook")"
  [[ "$prompt" == *'pubspec.yaml'* ]]
}

@test "barrel-export-reminder: prompt menciona barrel file" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/barrel-export-reminder.kiro.hook")"
  [[ "$prompt" == *'barrel'* ]]
}

@test "barrel-export-reminder: prompt instrui nao modificar automaticamente (Do NOT modify)" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/barrel-export-reminder.kiro.hook")"
  [[ "$prompt" == *'Do NOT modify'* ]] || [[ "$prompt" == *'NOT modify'* ]] || [[ "$prompt" == *'not modify'* ]] || [[ "$prompt" == *'Do NOT'* ]]
}

# =============================================================================
# scaffold-test-file: trigger fileCreated, patterns usecases/datasources/repositories/providers, askAgent
# Requisitos: 8.1, 8.2, 8.3, 8.4
# =============================================================================

@test "scaffold-test-file: name é 'Scaffold Test File'" {
  assert_json_field "${HOOKS_DIR}/scaffold-test-file.kiro.hook" '.name' 'Scaffold Test File'
}

@test "scaffold-test-file: when.type é fileCreated" {
  assert_json_field "${HOOKS_DIR}/scaffold-test-file.kiro.hook" '.when.type' 'fileCreated'
}

@test "scaffold-test-file: patterns inclui usecases/*.dart" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$patterns" == *'usecases'* ]]
}

@test "scaffold-test-file: patterns inclui datasources/*.dart" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$patterns" == *'datasources'* ]]
}

@test "scaffold-test-file: patterns inclui repositories/*.dart" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$patterns" == *'repositories'* ]]
}

@test "scaffold-test-file: patterns inclui providers/*.dart" {
  local patterns
  patterns="$(jq -c '.when.patterns' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$patterns" == *'providers'* ]]
}

@test "scaffold-test-file: then.type é askAgent" {
  assert_json_field "${HOOKS_DIR}/scaffold-test-file.kiro.hook" '.then.type' 'askAgent'
}

@test "scaffold-test-file: prompt exige imports absolutos package:" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$prompt" == *'absolute'* ]] || [[ "$prompt" == *'package:'* ]]
}

@test "scaffold-test-file: prompt menciona mocktail via core_dev" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$prompt" == *'core_dev'* ]]
  [[ "$prompt" == *'mocktail'* ]]
}

@test "scaffold-test-file: prompt menciona test/mocks/" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$prompt" == *'test/mocks/'* ]] || [[ "$prompt" == *'mocks/'* ]]
}

@test "scaffold-test-file: prompt menciona mocks.dart barrel" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$prompt" == *'mocks.dart'* ]]
}

@test "scaffold-test-file: prompt menciona package:core_dev/core_dev.dart" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/scaffold-test-file.kiro.hook")"
  [[ "$prompt" == *'package:core_dev/core_dev.dart'* ]]
}

# =============================================================================
# kiro-doctor: trigger userTriggered, askAgent, prompt com 8 seções e relatório
# Requisitos: 9.1, 9.2, 9.3, 9.4
# =============================================================================

@test "kiro-doctor: name é 'Kiro Doctor'" {
  assert_json_field "${HOOKS_DIR}/kiro-doctor.kiro.hook" '.name' 'Kiro Doctor'
}

@test "kiro-doctor: when.type é userTriggered" {
  assert_json_field "${HOOKS_DIR}/kiro-doctor.kiro.hook" '.when.type' 'userTriggered'
}

@test "kiro-doctor: then.type é askAgent" {
  assert_json_field "${HOOKS_DIR}/kiro-doctor.kiro.hook" '.then.type' 'askAgent'
}

@test "kiro-doctor: prompt menciona seção Resumo" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'Resumo'* ]]
}

@test "kiro-doctor: prompt menciona seção Steering" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'Steering'* ]]
}

@test "kiro-doctor: prompt menciona seção Hooks" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'Hooks'* ]]
}

@test "kiro-doctor: prompt menciona seção MCP Servers" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'MCP'* ]]
}

@test "kiro-doctor: prompt menciona seção Skills" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'Skills'* ]]
}

@test "kiro-doctor: prompt menciona seção Specs" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'Specs'* ]] || [[ "$prompt" == *'specs'* ]]
}

@test "kiro-doctor: prompt menciona seção Arquitetura" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'Arquitetura'* ]] || [[ "$prompt" == *'arquitetural'* ]]
}

@test "kiro-doctor: prompt menciona seção Recomendações" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'Recomendações'* ]] || [[ "$prompt" == *'recomendações'* ]] || [[ "$prompt" == *'Recomenda'* ]]
}

@test "kiro-doctor: prompt menciona kiro-doctor-report.md" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'kiro-doctor-report.md'* ]]
}

@test "kiro-doctor: prompt menciona indicadores visuais (✅ ⚠️ ❌)" {
  local prompt
  prompt="$(jq -r '.then.prompt' "${HOOKS_DIR}/kiro-doctor.kiro.hook")"
  [[ "$prompt" == *'✅'* ]] || [[ "$prompt" == *'⚠️'* ]] || [[ "$prompt" == *'❌'* ]]
}
