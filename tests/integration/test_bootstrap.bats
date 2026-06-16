#!/usr/bin/env bats
# =============================================================================
# Testes de Integração: bootstrap.sh
# Feature: baseline-global
#
# Cenários end-to-end para o script bootstrap.sh, verificando:
# - Happy path (bootstrap novo projeto)
# - --dry-run não altera filesystem
# - --force sobrescreve arquivos existentes
# - project-type inválido (exit 1)
# - target inexistente (exit 1)
# - Manifest já existe sem --force (skip com warning)
# - Geração de manifest com campos corretos
# - Merge de mcp.json (baseline + archetype)
#
# **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8**
# =============================================================================

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'
  load '../helpers/generators'

  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)/scripts"
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
  BOOTSTRAP="${SCRIPT_DIR}/bootstrap.sh"
}

teardown() {
  cleanup_fixtures
}

# =============================================================================
# Cenário 1: Happy path — bootstrap novo projeto com sucesso
# Validates: 4.1, 4.2, 4.3, 4.4
# =============================================================================

@test "happy path: bootstrap copia steering files do baseline para .kiro/steering/" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que cada steering file do baseline foi copiado (exceto README.md)
  for file in "${REPO_ROOT}/baselines/global/steering/"*.md; do
    local filename
    filename="$(basename "${file}")"
    [[ "${filename}" == "README.md" ]] && continue
    assert [ -f "${project_dir}/.kiro/steering/${filename}" ]
  done
}

@test "happy path: bootstrap copia artefatos do archetype (steering, skills, hooks, agents)" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Archetype frontend-react deve ter steering files copiados
  local archetype_dir="${REPO_ROOT}/archetypes/frontend-react"

  if [[ -d "${archetype_dir}/steering" ]]; then
    for file in "${archetype_dir}/steering/"*.md; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      [[ "${filename}" == "README.md" ]] && continue
      assert [ -f "${project_dir}/.kiro/steering/${filename}" ]
    done
  fi

  if [[ -d "${archetype_dir}/agents" ]]; then
    for file in "${archetype_dir}/agents/"*.md; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      [[ "${filename}" == "README.md" ]] && continue
      assert [ -f "${project_dir}/.kiro/agents/${filename}" ]
    done
  fi
}

@test "happy path: bootstrap gera mcp.json mergeado em .kiro/settings/" {
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
}

@test "happy path: bootstrap gera kiro-manifest.json no diretório alvo" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"
  assert [ -f "${manifest}" ]
  assert_json_valid "${manifest}"
}

# =============================================================================
# Cenário 2: --dry-run não altera filesystem
# Validates: 4.6
# =============================================================================

@test "dry-run: nenhum arquivo é criado ou modificado" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Capturar estado antes
  local snapshot_before
  snapshot_before="$(find "${project_dir}" -type f -exec md5 -q {} \; 2>/dev/null | sort)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --dry-run </dev/null

  # Capturar estado depois
  local snapshot_after
  snapshot_after="$(find "${project_dir}" -type f -exec md5 -q {} \; 2>/dev/null | sort)"

  [[ "${snapshot_before}" == "${snapshot_after}" ]]
}

@test "dry-run: output mostra o que seria feito sem executar" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --dry-run </dev/null

  [[ "${status}" -eq 0 ]]
  # Output deve conter indicação de dry-run
  [[ "${output}" == *"DRY-RUN"* ]]
}

# =============================================================================
# Cenário 3: --force sobrescreve arquivos existentes
# Validates: 4.5
# =============================================================================

@test "force: sobrescreve steering files existentes" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar um steering file pré-existente com conteúdo diferente
  echo "conteúdo antigo que deve ser sobrescrito" > "${project_dir}/.kiro/steering/engineering-principles.md"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Verificar que o arquivo foi sobrescrito com o conteúdo do baseline
  local baseline_file="${REPO_ROOT}/baselines/global/steering/engineering-principles.md"
  assert_file_identical "${baseline_file}" "${project_dir}/.kiro/steering/engineering-principles.md"
}

@test "force: sobrescreve manifest existente" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar manifest existente
  echo '{"old": "manifest"}' > "${project_dir}/kiro-manifest.json"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  # Manifest deve ter sido regenerado com campos corretos
  local manifest="${project_dir}/kiro-manifest.json"
  assert_json_valid "${manifest}"
  assert_json_field "${manifest}" '.baseline.version' "0.1.0"
}

# =============================================================================
# Cenário 4: project-type inválido resulta em exit 1
# Validates: 4.7
# =============================================================================

@test "project-type inválido: encerra com exit 1" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type tipo-inexistente </dev/null

  [[ "${status}" -ne 0 ]]
}

@test "project-type inválido: mensagem de erro lista tipos válidos" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type tipo-inexistente </dev/null

  [[ "${status}" -ne 0 ]]
  # Output deve mencionar os tipos válidos
  [[ "${output}" == *"bff-fastify"* ]] || [[ "${output}" == *"frontend-react"* ]]
}

# =============================================================================
# Cenário 5: target inexistente resulta em exit 1
# Validates: 4.8 (validação de target)
# =============================================================================

@test "target inexistente: encerra com exit 1" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  run bash "${BOOTSTRAP}" \
    --target "/caminho/que/nao/existe/jamais" \
    --project-type bff-fastify </dev/null

  [[ "${status}" -ne 0 ]]
}

@test "target inexistente: mensagem de erro indica o problema" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  run bash "${BOOTSTRAP}" \
    --target "/caminho/que/nao/existe/jamais" \
    --project-type bff-fastify </dev/null

  [[ "${status}" -ne 0 ]]
  # Output deve indicar que o diretório não foi encontrado
  [[ "${output}" == *"não encontrado"* ]] || [[ "${output}" == *"not found"* ]] || [[ "${output}" == *"Diretório"* ]] || [[ "${output}" == *"destino"* ]]
}

# =============================================================================
# Cenário 6: manifest já existe sem --force (skip com warning)
# Validates: 4.5
# =============================================================================

@test "manifest existe sem --force: bootstrap exibe warning e não sobrescreve" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar manifest existente
  echo '{"existing": "manifest"}' > "${project_dir}/kiro-manifest.json"

  # Sem --force, com stdin em /dev/null (responde 'N' ao prompt, causando exit 0)
  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify </dev/null

  # O script exibe warning sobre o manifest existente
  [[ "${output}" == *"kiro-manifest.json"* ]] || [[ "${output}" == *"WARN"* ]]
}

# =============================================================================
# Cenário 7: manifest gerado contém campos corretos
# Validates: 4.4
# =============================================================================

@test "manifest: contém baseline.version com semver correto" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"
  assert_json_field "${manifest}" '.baseline.version' "0.1.0"
}

@test "manifest: contém archetype.name com tipo correto" {
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
  assert_json_field "${manifest}" '.archetype.name' "frontend-react"
}

@test "manifest: contém baseline.source, installed_at e last_synced_at" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  # baseline.source deve ser preenchido
  local source
  source="$(jq -r '.baseline.source' "${manifest}")"
  [[ -n "${source}" && "${source}" != "null" ]]

  # baseline.installed_at deve ser ISO 8601
  local installed_at
  installed_at="$(jq -r '.baseline.installed_at' "${manifest}")"
  [[ "${installed_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]

  # baseline.last_synced_at deve ser ISO 8601
  local last_synced
  last_synced="$(jq -r '.baseline.last_synced_at' "${manifest}")"
  [[ "${last_synced}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "manifest: contém exceptions como array vazio" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  # exceptions deve ser array vazio
  local exceptions_length
  exceptions_length="$(jq '.exceptions | length' "${manifest}")"
  [[ "${exceptions_length}" -eq 0 ]]
}

@test "manifest: contém schema_version e _generated_by" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para validação"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local manifest="${project_dir}/kiro-manifest.json"

  # schema_version deve existir
  local schema_version
  schema_version="$(jq -r '.schema_version' "${manifest}")"
  [[ -n "${schema_version}" && "${schema_version}" != "null" ]]

  # _generated_by deve indicar o bootstrap
  local generated_by
  generated_by="$(jq -r '._generated_by' "${manifest}")"
  [[ "${generated_by}" == *"bootstrap"* ]]
}

# =============================================================================
# Cenário 8: merge de mcp.json (baseline + archetype)
# Validates: 4.3
# =============================================================================

@test "mcp.json merge: contém servidores do baseline" {
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

  # Servidores do baseline devem estar presentes
  local has_atlassian has_github has_context7
  has_atlassian="$(jq 'has("mcpServers") and (.mcpServers | has("atlassian"))' "${mcp_dest}")"
  has_github="$(jq 'has("mcpServers") and (.mcpServers | has("github"))' "${mcp_dest}")"
  has_context7="$(jq 'has("mcpServers") and (.mcpServers | has("context7"))' "${mcp_dest}")"

  [[ "${has_atlassian}" == "true" ]]
  [[ "${has_github}" == "true" ]]
  [[ "${has_context7}" == "true" ]]
}

@test "mcp.json merge: contém servidores do archetype" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  # frontend-react tem chrome-devtools no mcp.json
  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"
  assert [ -f "${mcp_dest}" ]

  # Servidor do archetype frontend-react deve estar presente
  local has_chrome_devtools
  has_chrome_devtools="$(jq '.mcpServers | has("chrome-devtools")' "${mcp_dest}")"
  [[ "${has_chrome_devtools}" == "true" ]]
}

@test "mcp.json merge: archetype tem precedência sobre baseline em caso de conflito" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  # Usar frontend-react pois tem servidor próprio (chrome-devtools)
  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"

  # O merge deve conter ambos: baseline (atlassian, github, context7)
  # e archetype (chrome-devtools)
  local total_servers
  total_servers="$(jq '.mcpServers | keys | length' "${mcp_dest}")"
  [[ "${total_servers}" -ge 4 ]]
}

@test "mcp.json merge: resultado é JSON válido com _comment e _version" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"
  command -v jq &>/dev/null || skip "jq necessário para merge"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --force </dev/null

  [[ "${status}" -eq 0 ]]

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"
  assert_json_valid "${mcp_dest}"

  # Deve ter _comment e _version no nível raiz
  local comment version
  comment="$(jq -r '._comment' "${mcp_dest}")"
  version="$(jq -r '._version' "${mcp_dest}")"

  [[ -n "${comment}" && "${comment}" != "null" ]]
  [[ -n "${version}" && "${version}" != "null" ]]
}

# =============================================================================
# Cenários extras: validação de pré-requisitos
# Validates: 4.8
# =============================================================================

@test "sem --project-type: encerra com exit 1" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP}" \
    --target "${project_dir}" </dev/null

  [[ "${status}" -ne 0 ]]
}

@test "sem --target: encerra com exit 1" {
  [[ -f "${BOOTSTRAP}" ]] || skip "bootstrap.sh não encontrado"

  run bash "${BOOTSTRAP}" \
    --project-type bff-fastify </dev/null

  [[ "${status}" -ne 0 ]]
}
