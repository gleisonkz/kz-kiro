#!/usr/bin/env bats
# =============================================================================
# Testes de Integração: bootstrap.sh com archetype mobile-flutter
# Feature: archetype-mobile-flutter
#
# Cenários end-to-end para o script bootstrap.sh com --project-type mobile-flutter:
# - 15 steering files do archetype (sem README) são copiados para .kiro/steering/
# - 5 hooks do archetype são copiados para .kiro/hooks/
# - Agents do archetype (apenas README.md — nenhum copiado, bootstrap pula READMEs)
# - Skills do archetype (apenas README.md — nenhum copiado, bootstrap pula READMEs)
# - Merge de mcp.json (baseline global + archetype mobile-flutter com dart server = baseline + dart)
# - Manifest gerado com archetype.name "mobile-flutter" e versão 0.1.0
#
# **Validates: Design — Integração com Scripts de Automação (bootstrap.sh)**
# =============================================================================

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'
  load '../helpers/generators'

  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)/scripts"
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
  BOOTSTRAP="${SCRIPT_DIR}/bootstrap.sh"
  ARCHETYPE_DIR="${REPO_ROOT}/archetypes/mobile-flutter"
}

teardown() {
  cleanup_fixtures
}

# =============================================================================
# Cenário 1: Steering files do archetype mobile-flutter são copiados (15 sem README)
# =============================================================================

@test "bootstrap mobile-flutter: copia todos os 15 steering files do archetype para .kiro/steering/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que cada steering file do archetype (exceto README) foi copiado
  local expected_files=(
    "coding-standards.md"
    "flutter_best_practices.md"
    "clean-architecture.md"
    "flutter-clean-architecture.md"
    "flutter-lints-security.md"
    "flutter-testing-patterns.md"
    "dependency-management.md"
    "design-system.md"
    "code-review.md"
    "auth-api.md"
    "forgot-password-api.md"
    "home-api.md"
    "notifications-api.md"
    "profile-api.md"
    "settings-api.md"
  )

  for filename in "${expected_files[@]}"; do
    assert [ -f "${project_dir}/.kiro/steering/${filename}" ]
  done
}

@test "bootstrap mobile-flutter: steering files copiados são idênticos aos do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar conteúdo idêntico byte a byte
  for file in "${ARCHETYPE_DIR}/steering/"*.md; do
    [[ ! -f "${file}" ]] && continue
    local filename
    filename="$(basename "${file}")"
    [[ "${filename}" == "README.md" ]] && continue
    assert_file_identical "${file}" "${project_dir}/.kiro/steering/${filename}"
  done
}

@test "bootstrap mobile-flutter: README.md do steering nao e copiado para o projeto" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Remover o README que o create_temp_project pode ter criado
  rm -f "${project_dir}/.kiro/steering/README.md"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # README.md do archetype nao deve ser copiado para o projeto
  assert [ ! -f "${project_dir}/.kiro/steering/README.md" ]
}

@test "bootstrap mobile-flutter: exatamente 15 steering files copiados (excluindo baseline)" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Contar steering files do archetype no destino (excluindo os do baseline)
  # O archetype tem 15 steering files; baseline tem 2 (engineering-principles, security-baseline)
  # Total esperado: 15 + 2 = 17, mas vamos verificar que os 15 do archetype estão presentes
  local archetype_count=0
  local expected_files=(
    "coding-standards.md"
    "flutter_best_practices.md"
    "clean-architecture.md"
    "flutter-clean-architecture.md"
    "flutter-lints-security.md"
    "flutter-testing-patterns.md"
    "dependency-management.md"
    "design-system.md"
    "code-review.md"
    "auth-api.md"
    "forgot-password-api.md"
    "home-api.md"
    "notifications-api.md"
    "profile-api.md"
    "settings-api.md"
  )

  for filename in "${expected_files[@]}"; do
    if [[ -f "${project_dir}/.kiro/steering/${filename}" ]]; then
      ((archetype_count++)) || true
    fi
  done

  [[ "${archetype_count}" -eq 15 ]]
}

# =============================================================================
# Cenário 2: Hooks do archetype mobile-flutter são copiados (5 hooks)
# =============================================================================

@test "bootstrap mobile-flutter: copia todos os 5 hooks do archetype para .kiro/hooks/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que todos os 5 hooks do archetype foram copiados
  local expected_hooks=(
    "dart-analyze-save.kiro.hook"
    "check-relative-imports.kiro.hook"
    "barrel-export-reminder.kiro.hook"
    "scaffold-test-file.kiro.hook"
    "kiro-doctor.kiro.hook"
  )

  for hook in "${expected_hooks[@]}"; do
    assert [ -f "${project_dir}/.kiro/hooks/${hook}" ]
  done
}

@test "bootstrap mobile-flutter: hooks copiados são idênticos aos do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  for file in "${ARCHETYPE_DIR}/hooks/"*.kiro.hook; do
    [[ ! -f "${file}" ]] && continue
    local filename
    filename="$(basename "${file}")"
    assert_file_identical "${file}" "${project_dir}/.kiro/hooks/${filename}"
  done
}

# =============================================================================
# Cenário 3: Agents do archetype mobile-flutter (apenas README.md — nenhum copiado)
# =============================================================================

@test "bootstrap mobile-flutter: nenhum agent funcional e copiado para .kiro/agents/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # mobile-flutter agents/ tem apenas README.md no archetype, e bootstrap pula READMEs.
  # Portanto nenhum arquivo de agent funcional deve ser copiado.
  local agent_count
  agent_count=$(find "${project_dir}/.kiro/agents/" -name "*.md" ! -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  [[ "${agent_count}" -eq 0 ]]
}

@test "bootstrap mobile-flutter: README.md de agents nao e copiado (bootstrap pula READMEs)" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Remover qualquer README.md pré-existente em agents/
  rm -f "${project_dir}/.kiro/agents/README.md"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # bootstrap.sh pula READMEs — como mobile-flutter só tem README.md em agents/,
  # nenhum arquivo deve ser copiado para .kiro/agents/
  assert [ ! -f "${project_dir}/.kiro/agents/README.md" ]
}

# =============================================================================
# Cenário 4: Skills do archetype mobile-flutter (apenas README.md — nenhum copiado)
# =============================================================================

@test "bootstrap mobile-flutter: nenhuma skill funcional e copiada para .kiro/skills/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # mobile-flutter skills/ tem apenas README.md no archetype, e bootstrap pula READMEs.
  # Portanto nenhum arquivo de skill funcional deve ser copiado.
  local skill_count
  skill_count=$(find "${project_dir}/.kiro/skills/" -name "*.md" ! -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  [[ "${skill_count}" -eq 0 ]]
}

@test "bootstrap mobile-flutter: README.md de skills nao e copiado (bootstrap pula READMEs)" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Remover qualquer README.md pré-existente em skills/
  rm -f "${project_dir}/.kiro/skills/README.md"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # bootstrap.sh pula READMEs — como mobile-flutter só tem README.md em skills/,
  # nenhum arquivo deve ser copiado para .kiro/skills/
  assert [ ! -f "${project_dir}/.kiro/skills/README.md" ]
}

# =============================================================================
# Cenário 5: Merge de mcp.json (baseline global + archetype mobile-flutter com dart server)
# =============================================================================

@test "bootstrap mobile-flutter: mcp.json mergeado contém servidores do baseline global" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"
  assert [ -f "${mcp_dest}" ]
  assert_json_valid "${mcp_dest}"

  # Servidores do baseline global devem estar presentes
  local has_atlassian has_github has_context7
  has_atlassian="$(jq '.mcpServers | has("atlassian")' "${mcp_dest}")"
  has_github="$(jq '.mcpServers | has("github")' "${mcp_dest}")"
  has_context7="$(jq '.mcpServers | has("context7")' "${mcp_dest}")"

  [[ "${has_atlassian}" == "true" ]]
  [[ "${has_github}" == "true" ]]
  [[ "${has_context7}" == "true" ]]
}

@test "bootstrap mobile-flutter: mcp.json mergeado contém servidor dart do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"
  assert [ -f "${mcp_dest}" ]

  # Servidor dart do archetype mobile-flutter deve estar presente
  local has_dart
  has_dart="$(jq '.mcpServers | has("dart")' "${mcp_dest}")"
  [[ "${has_dart}" == "true" ]]

  # Verificar campos do dart server
  local command_val args_val disabled_val
  command_val="$(jq -r '.mcpServers.dart.command' "${mcp_dest}")"
  args_val="$(jq -c '.mcpServers.dart.args' "${mcp_dest}")"
  disabled_val="$(jq '.mcpServers.dart.disabled' "${mcp_dest}")"

  [[ "${command_val}" == "dart" ]]
  [[ "${args_val}" == '["mcp-server"]' ]]
  [[ "${disabled_val}" == "false" ]]
}

@test "bootstrap mobile-flutter: mcp.json mergeado contém ao menos 4 servidores (3 baseline + 1 dart)" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"
  local total_servers
  total_servers="$(jq '.mcpServers | keys | length' "${mcp_dest}")"

  # baseline (atlassian, github, context7) + archetype (dart) = 4
  [[ "${total_servers}" -ge 4 ]]
}

@test "bootstrap mobile-flutter: mcp.json mergeado possui _comment e _version" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"

  local comment version
  comment="$(jq -r '._comment' "${mcp_dest}")"
  version="$(jq -r '._version' "${mcp_dest}")"

  [[ -n "${comment}" && "${comment}" != "null" ]]
  [[ -n "${version}" && "${version}" != "null" ]]
}

# =============================================================================
# Cenário 6: Manifest gerado com archetype.name "mobile-flutter" e versão 0.1.0
# =============================================================================

@test "bootstrap mobile-flutter: manifest contém archetype.name 'mobile-flutter'" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"
  assert [ -f "${manifest}" ]
  assert_json_valid "${manifest}"
  assert_json_field "${manifest}" '.archetype.name' "mobile-flutter"
}

@test "bootstrap mobile-flutter: manifest contém archetype.version '0.1.0'" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  # Verificar que archetype.version é 0.1.0
  local arch_version
  arch_version="$(jq -r '.archetype.version' "${manifest}")"
  [[ "${arch_version}" == "0.1.0" ]]
}

@test "bootstrap mobile-flutter: manifest contém baseline.version '0.1.0'" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"
  assert_json_field "${manifest}" '.baseline.version' "0.1.0"
}

@test "bootstrap mobile-flutter: manifest contém _generated_by com 'bootstrap'" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  local generated_by
  generated_by="$(jq -r '._generated_by' "${manifest}")"
  [[ "${generated_by}" == *"bootstrap"* ]]
}

@test "bootstrap mobile-flutter: manifest contém installed_at em formato ISO 8601" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type mobile-flutter \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  local installed_at
  installed_at="$(jq -r '.archetype.installed_at' "${manifest}")"
  [[ "${installed_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}
