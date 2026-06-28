#!/usr/bin/env bats
# =============================================================================
# Testes de Integração — Native Powers Installation
# =============================================================================
# Cenários end-to-end para o novo comportamento de powers nativos:
#   - Bootstrap: registra powers no manifest com installation_method="native"
#   - Bootstrap: NÃO copia steerings de powers nem faz merge de mcp.json de powers
#   - Bootstrap: ignora powers em _drafts/
#   - Sync nativo: compara versão, reporta atualização disponível
#   - Migrate: cria backup, remove legado, atualiza manifest
#   - Doctor: detecta instalação legada e duplicada, valida POWER.md
#
# **Validates: Requirements 2.3, 3.1, 3.2, 3.3, 3.4, 4.1, 5.3, 5.5, 6.2, 6.3, 8.2**
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/assertions'

# Caminhos dos scripts
BOOTSTRAP_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/bootstrap.sh"
SYNC_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/sync.sh"
DOCTOR_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"
REPO_ROOT="${BATS_TEST_DIRNAME}/../.."

teardown() {
  cleanup_fixtures
}

# --- Funções auxiliares ---

# Cria um manifest na raiz do projeto com powers configurados
_create_manifest_with_powers() {
  local project_dir="$1"
  local powers_json="${2:-[]}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  cat > "${project_dir}/kiro-manifest.json" <<EOF
{
  "_generated_by": "test-native-powers",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test-project", "repository": "org/test-project" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "frontend-react", "version": "0.1.0", "installed_at": "${now}" },
  "powers": ${powers_json},
  "exceptions": []
}
EOF
}

# =============================================================================
# SEÇÃO 1: Bootstrap — Novo comportamento (registra no manifest, não copia)
# Validates: Requirements 3.1, 3.2, 3.3, 3.4
# =============================================================================

@test "bootstrap powers: manifest contém powers com installation_method=native" {
  [[ -f "${BOOTSTRAP_SCRIPT}" ]] || skip "bootstrap.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP_SCRIPT}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  assert_success

  local manifest="${project_dir}/kiro-manifest.json"
  assert [ -f "${manifest}" ]
  assert_json_valid "${manifest}"

  # Verificar que há powers registrados
  local power_count
  power_count="$(jq '.powers | length' "${manifest}")"
  [[ "${power_count}" -ge 1 ]]

  # Verificar campos obrigatórios de cada power
  local all_native
  all_native="$(jq '[.powers[] | .installation_method] | all(. == "native")' "${manifest}")"
  [[ "${all_native}" == "true" ]]
}

@test "bootstrap powers: manifest contém source_path e version para cada power" {
  [[ -f "${BOOTSTRAP_SCRIPT}" ]] || skip "bootstrap.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP_SCRIPT}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  assert_success

  local manifest="${project_dir}/kiro-manifest.json"

  # Verificar que cada power tem source_path e version preenchidos
  local invalid_entries
  invalid_entries="$(jq '[.powers[] | select(.source_path == null or .source_path == "" or .version == null or .version == "")] | length' "${manifest}")"
  [[ "${invalid_entries}" -eq 0 ]]

  # Verificar source_path no formato esperado: powers/<name>
  local first_source
  first_source="$(jq -r '.powers[0].source_path' "${manifest}")"
  [[ "${first_source}" == powers/* ]]
}

@test "bootstrap powers: nao copia steering files de powers para .kiro/steering/powers/" {
  [[ -f "${BOOTSTRAP_SCRIPT}" ]] || skip "bootstrap.sh não encontrado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP_SCRIPT}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  assert_success

  # Diretório .kiro/steering/powers/ NÃO deve existir
  assert [ ! -d "${project_dir}/.kiro/steering/powers" ]
}

@test "bootstrap powers: nao faz merge de mcp.json de powers no projeto" {
  [[ -f "${BOOTSTRAP_SCRIPT}" ]] || skip "bootstrap.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP_SCRIPT}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  assert_success

  local mcp_dest="${project_dir}/.kiro/settings/mcp.json"

  # mcp.json do projeto NÃO deve conter servers de powers (ex: figma do mb-frontend-react)
  # Deve conter apenas baseline + archetype
  if [[ -f "${mcp_dest}" ]]; then
    local has_figma
    has_figma="$(jq '.mcpServers | has("figma")' "${mcp_dest}" 2>/dev/null)"
    [[ "${has_figma}" != "true" ]]
  fi
}

@test "bootstrap powers: exibe instruções de instalação nativa no output" {
  [[ -f "${BOOTSTRAP_SCRIPT}" ]] || skip "bootstrap.sh não encontrado"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP_SCRIPT}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  assert_success

  # Output deve conter instrução de instalação nativa
  assert_output --partial "Import power from a folder"
  # Output deve conter caminho absoluto do power
  assert_output --partial "powers/"
}

# =============================================================================
# SEÇÃO 2: Bootstrap — _drafts ignorado
# Validates: Requirements 8.2
# =============================================================================

@test "bootstrap powers: ignora powers em powers/_drafts/" {
  [[ -f "${BOOTSTRAP_SCRIPT}" ]] || skip "bootstrap.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  # Usar mobile-flutter como extra power (que está em _drafts)
  run bash "${BOOTSTRAP_SCRIPT}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --powers "mb-mobile-flutter" \
    --force </dev/null

  assert_success

  local manifest="${project_dir}/kiro-manifest.json"
  assert [ -f "${manifest}" ]

  # mb-mobile-flutter NÃO deve aparecer no manifest (está em _drafts)
  local has_flutter
  has_flutter="$(jq '[.powers[] | select(.name == "mb-mobile-flutter")] | length' "${manifest}")"
  [[ "${has_flutter}" -eq 0 ]]
}

@test "bootstrap powers: registra mb-kiro-manager mesmo sem mcp.json" {
  [[ -f "${BOOTSTRAP_SCRIPT}" ]] || skip "bootstrap.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  run bash "${BOOTSTRAP_SCRIPT}" \
    --target "${project_dir}" \
    --project-type frontend-react \
    --force </dev/null

  assert_success

  local manifest="${project_dir}/kiro-manifest.json"

  # mb-kiro-manager deve estar registrado (power sem mcp.json)
  local has_manager
  has_manager="$(jq '[.powers[] | select(.name == "mb-kiro-manager")] | length' "${manifest}")"
  [[ "${has_manager}" -eq 1 ]]
}

# =============================================================================
# SEÇÃO 3: Sync nativo — compara versão, reporta atualização
# Validates: Requirements 4.1, 4.2, 4.3
# =============================================================================

@test "sync powers nativo: power atualizado mostra sucesso" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar manifest com power na versão correta (1.0.0)
  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "native", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Copiar steering do baseline para evitar falhas
  for f in "${REPO_ROOT}/baselines/global/steering/"*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --component powers

  assert_success
  # Deve indicar que o power está atualizado
  assert_output --partial "atualizado"
}

@test "sync powers nativo: power desatualizado reporta aviso com instrução" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar manifest com power em versão anterior
  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "0.1.0", "source_path": "powers/mb-frontend-react", "installation_method": "native", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --component powers

  assert_success
  # Deve reportar que há versão nova disponível
  assert_output --partial "desatualizado"
  # Deve instruir a usar "Check for updates"
  assert_output --partial "Check for updates"
}

@test "sync powers legado: emite aviso sugerindo migrate" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar manifest com power em modo legado
  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Criar steering legado para que o sync legado funcione
  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# test" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/test.md"

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --component powers

  assert_success
  # Deve sugerir migração
  assert_output --partial "--migrate-powers"
  assert_output --partial "legad"
}

# =============================================================================
# SEÇÃO 4: Migrate com backup
# Validates: Requirements 6.2, 6.3, 6.4, 6.5
# =============================================================================

@test "migrate powers: cria backup antes de remover legado" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar manifest com power legado
  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Criar steering legado que será migrado
  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# Steering legado de teste" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/test-steering.md"

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --migrate-powers

  assert_success

  # Backup deve ter sido criado
  assert [ -d "${project_dir}/.kiro/.migration-backup/mb-frontend-react" ]
  assert [ -d "${project_dir}/.kiro/.migration-backup/mb-frontend-react/steering" ]
}

@test "migrate powers: remove steering legado após backup" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# Legado" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/old.md"

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --migrate-powers

  assert_success

  # Steering legado deve ter sido removido
  assert [ ! -d "${project_dir}/.kiro/steering/powers/mb-frontend-react" ]
}

@test "migrate powers: atualiza manifest com installation_method=native e migrated_at" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# Old" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/file.md"

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --migrate-powers

  assert_success

  local manifest="${project_dir}/kiro-manifest.json"
  assert_json_valid "${manifest}"

  # installation_method deve ser "native" agora
  local method
  method="$(jq -r '.powers[0].installation_method' "${manifest}")"
  [[ "${method}" == "native" ]]

  # migrated_at deve ser ISO 8601
  local migrated_at
  migrated_at="$(jq -r '.powers[0].migrated_at' "${manifest}")"
  [[ "${migrated_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "migrate powers: remove MCP servers do power no mcp.json do projeto" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Criar steering legado
  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# Old" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/f.md"

  # Criar mcp.json com server do power (figma) + server do baseline (atlassian)
  mkdir -p "${project_dir}/.kiro/settings"
  cat > "${project_dir}/.kiro/settings/mcp.json" <<EOF
{
  "_comment": "Test MCP",
  "_version": "0.1.0",
  "mcpServers": {
    "atlassian": { "url": "https://mcp.atlassian.com/v1/mcp" },
    "figma": { "command": "npx", "args": ["-y", "figma-developer-mcp", "--stdio"] }
  }
}
EOF

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --migrate-powers

  assert_success

  local mcp="${project_dir}/.kiro/settings/mcp.json"
  assert [ -f "${mcp}" ]

  # Figma (server do power) deve ter sido removido
  local has_figma
  has_figma="$(jq '.mcpServers | has("figma")' "${mcp}")"
  [[ "${has_figma}" == "false" ]]

  # Atlassian (server do baseline) deve permanecer
  local has_atlassian
  has_atlassian="$(jq '.mcpServers | has("atlassian")' "${mcp}")"
  [[ "${has_atlassian}" == "true" ]]
}

@test "migrate powers: exibe instruções de instalação nativa após migração" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# Old" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/f.md"

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --migrate-powers

  assert_success

  # Deve exibir instrução de instalação nativa
  assert_output --partial "Import power from a folder"
  assert_output --partial "powers/mb-frontend-react"
}

@test "migrate powers: pula power já migrado (sem steering legado)" {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # NÃO criar steering legado — simula power já migrado

  run bash "${SYNC_SCRIPT}" --target "${project_dir}" --migrate-powers

  assert_success
  # Deve avisar que já está migrado
  assert_output --partial "já migrado"
}

# =============================================================================
# SEÇÃO 5: Doctor — detecta legado e duplicada, valida POWER.md
# Validates: Requirements 5.1, 5.3, 5.4, 5.5
# =============================================================================

@test "doctor powers: valida POWER.md com keywords presentes" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "native", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Copiar steering do baseline para projeto saudável
  for f in "${REPO_ROOT}/baselines/global/steering/"*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done
  cp "${REPO_ROOT}/baselines/global/mcp/mcp.json" "${project_dir}/.kiro/settings/mcp.json"
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test" > "${project_dir}/README.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Deve reportar POWER.md válido
  assert_output --partial "POWER.md"
  assert_output --partial "[PASS]"
}

@test "doctor powers: detecta instalação legada residual" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "legacy", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Criar steering legado (simula instalação antiga)
  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# Legado" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/old.md"

  # Copiar baseline para evitar outros failures
  for f in "${REPO_ROOT}/baselines/global/steering/"*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done
  cp "${REPO_ROOT}/baselines/global/mcp/mcp.json" "${project_dir}/.kiro/settings/mcp.json"
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test" > "${project_dir}/README.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Deve reportar WARN sobre instalação legada
  assert_output --partial "[WARN]"
  assert_output --partial "legad"
  assert_output --partial "--migrate-powers"
}

@test "doctor powers: detecta instalação duplicada (native + legado)" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  # Power com installation_method=native MAS com steering legado residual
  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "1.0.0", "source_path": "powers/mb-frontend-react", "installation_method": "native", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Steering legado residual (deveria ter sido removido durante migração)
  mkdir -p "${project_dir}/.kiro/steering/powers/mb-frontend-react"
  echo "# Residual" > "${project_dir}/.kiro/steering/powers/mb-frontend-react/leftover.md"

  # Copiar baseline
  for f in "${REPO_ROOT}/baselines/global/steering/"*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done
  cp "${REPO_ROOT}/baselines/global/mcp/mcp.json" "${project_dir}/.kiro/settings/mcp.json"
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test" > "${project_dir}/README.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Deve reportar WARN sobre instalação duplicada
  assert_output --partial "[WARN]"
  assert_output --partial "duplicada"
}

@test "doctor powers: reporta versão desatualizada" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"

  # Power com versão anterior à do VERSION file
  _create_manifest_with_powers "${project_dir}" '[
    {"name": "mb-frontend-react", "version": "0.1.0", "source_path": "powers/mb-frontend-react", "installation_method": "native", "installed_at": "2024-01-01T00:00:00Z"}
  ]'

  # Copiar baseline
  for f in "${REPO_ROOT}/baselines/global/steering/"*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done
  cp "${REPO_ROOT}/baselines/global/mcp/mcp.json" "${project_dir}/.kiro/settings/mcp.json"
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test" > "${project_dir}/README.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Deve reportar WARN sobre versão desatualizada
  assert_output --partial "[WARN]"
  assert_output --partial "0.1.0"
  assert_output --partial "1.0.0"
}
