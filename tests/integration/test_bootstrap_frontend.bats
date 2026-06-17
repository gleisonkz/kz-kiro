#!/usr/bin/env bats
# =============================================================================
# Testes de Integração: bootstrap.sh com archetype frontend-react
# Feature: archetype-frontend-react
#
# Cenários end-to-end para o script bootstrap.sh com --project-type frontend-react:
# - Steering files do archetype são copiados para .kiro/steering/
# - Hooks do archetype são copiados para .kiro/hooks/
# - Agents do archetype são copiados para .kiro/agents/
# - Skills do archetype são copiados para .kiro/skills/
# - Merge de mcp.json (baseline global + archetype frontend-react)
# - Manifest gerado com archetype.name "frontend-react" e versão correta
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
  ARCHETYPE_DIR="${REPO_ROOT}/archetypes/frontend-react"
}

teardown() {
  cleanup_fixtures
}

# =============================================================================
# Cenário 1: Steering files do archetype frontend-react são copiados
# =============================================================================

@test "bootstrap frontend-react: copia todos os steering files do archetype para .kiro/steering/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que cada steering file do archetype (exceto README) foi copiado
  local expected_files=("stack-and-tooling.md" "architecture.md" "design-system.md" "naming-conventions.md" "ci-cd.md")

  for filename in "${expected_files[@]}"; do
    assert [ -f "${project_dir}/.kiro/steering/${filename}" ]
  done
}

@test "bootstrap frontend-react: steering files copiados são idênticos aos do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
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

@test "bootstrap frontend-react: README.md do steering nao e copiado para o projeto" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Remover o README que o create_temp_project pode ter criado
  rm -f "${project_dir}/.kiro/steering/README.md"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # README.md do archetype nao deve ser copiado para o projeto
  assert [ ! -f "${project_dir}/.kiro/steering/README.md" ]
}

# =============================================================================
# Cenário 2: Hooks do archetype frontend-react são copiados
# =============================================================================

@test "bootstrap frontend-react: copia todos os hooks do archetype para .kiro/hooks/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que todos os 8 hooks do archetype foram copiados
  local expected_hooks=(
    "kiro-doctor.kiro.hook"
    "lint-after-agent.kiro.hook"
    "remind-test-coverage.kiro.hook"
    "review-component-quality.kiro.hook"
    "review-feature-boundaries.kiro.hook"
    "review-naming-conventions.kiro.hook"
    "run-tests-after-task.kiro.hook"
    "typecheck-on-save.kiro.hook"
  )

  for hook in "${expected_hooks[@]}"; do
    assert [ -f "${project_dir}/.kiro/hooks/${hook}" ]
  done
}

@test "bootstrap frontend-react: hooks copiados são idênticos aos do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
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
# Cenário 3: Agents do archetype frontend-react são copiados
# =============================================================================

@test "bootstrap frontend-react: copia todos os agents do archetype para .kiro/agents/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que todos os 4 agents do archetype foram copiados
  local expected_agents=(
    "accessibility-reviewer.md"
    "architecture-reviewer.md"
    "code-reviewer.md"
    "performance-reviewer.md"
  )

  for agent in "${expected_agents[@]}"; do
    assert [ -f "${project_dir}/.kiro/agents/${agent}" ]
  done
}

@test "bootstrap frontend-react: agents copiados são idênticos aos do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  for file in "${ARCHETYPE_DIR}/agents/"*.md; do
    [[ ! -f "${file}" ]] && continue
    local filename
    filename="$(basename "${file}")"
    [[ "${filename}" == "README.md" ]] && continue
    assert_file_identical "${file}" "${project_dir}/.kiro/agents/${filename}"
  done
}

# =============================================================================
# Cenário 4: Skills do archetype frontend-react são copiados
# =============================================================================

@test "bootstrap frontend-react: copia todas as skills do archetype para .kiro/skills/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que todas as 7 skills do archetype foram copiadas
  local expected_skills=(
    "generate-api-endpoint.md"
    "generate-component.md"
    "generate-context-provider.md"
    "generate-hook.md"
    "generate-module.md"
    "generate-page.md"
    "generate-redux-slice.md"
  )

  for skill in "${expected_skills[@]}"; do
    assert [ -f "${project_dir}/.kiro/skills/${skill}" ]
  done
}

@test "bootstrap frontend-react: skills copiadas são idênticas às do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  for file in "${ARCHETYPE_DIR}/skills/"*.md; do
    [[ ! -f "${file}" ]] && continue
    local filename
    filename="$(basename "${file}")"
    [[ "${filename}" == "README.md" ]] && continue
    assert_file_identical "${file}" "${project_dir}/.kiro/skills/${filename}"
  done
}

# =============================================================================
# Cenário 5: Merge de mcp.json (baseline global + archetype frontend-react)
# =============================================================================

@test "bootstrap frontend-react: mcp.json mergeado contém servidores do baseline global" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
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

@test "bootstrap frontend-react: mcp.json mergeado contém chrome-devtools do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"
  assert [ -f "${mcp_dest}" ]

  # chrome-devtools do archetype deve estar presente
  local has_chrome_devtools
  has_chrome_devtools="$(jq '.mcpServers | has("chrome-devtools")' "${mcp_dest}")"
  [[ "${has_chrome_devtools}" == "true" ]]

  # Verificar campos do chrome-devtools
  local command_val args_val disabled_val
  command_val="$(jq -r '.mcpServers["chrome-devtools"].command' "${mcp_dest}")"
  args_val="$(jq -c '.mcpServers["chrome-devtools"].args' "${mcp_dest}")"
  disabled_val="$(jq '.mcpServers["chrome-devtools"].disabled' "${mcp_dest}")"

  [[ "${command_val}" == "npx" ]]
  [[ "${args_val}" == '["-y","chrome-devtools-mcp@latest"]' ]]
  [[ "${disabled_val}" == "false" ]]
}

@test "bootstrap frontend-react: mcp.json mergeado contém ao menos 4 servidores (3 baseline + 1 archetype)" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"
  local total_servers
  total_servers="$(jq '.mcpServers | keys | length' "${mcp_dest}")"

  [[ "${total_servers}" -ge 4 ]]
}

@test "bootstrap frontend-react: mcp.json mergeado possui _comment e _version" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
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
# Cenário 6: Manifest gerado com archetype.name "frontend-react" e versão correta
# =============================================================================

@test "bootstrap frontend-react: manifest contém archetype.name 'frontend-react'" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"
  assert [ -f "${manifest}" ]
  assert_json_valid "${manifest}"
  assert_json_field "${manifest}" '.archetype.name' "frontend-react"
}

@test "bootstrap frontend-react: manifest contém archetype.version com semver válido" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  # Verificar que archetype.version é um semver válido
  local arch_version
  arch_version="$(jq -r '.archetype.version' "${manifest}")"
  [[ "${arch_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "bootstrap frontend-react: manifest contém baseline.version '0.1.0'" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"
  assert_json_field "${manifest}" '.baseline.version' "0.1.0"
}

@test "bootstrap frontend-react: manifest contém _generated_by com 'bootstrap'" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  local generated_by
  generated_by="$(jq -r '._generated_by' "${manifest}")"
  [[ "${generated_by}" == *"bootstrap"* ]]
}

@test "bootstrap frontend-react: manifest contém installed_at em formato ISO 8601" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  local installed_at
  installed_at="$(jq -r '.archetype.installed_at' "${manifest}")"
  [[ "${installed_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}
