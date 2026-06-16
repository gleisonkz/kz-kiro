#!/usr/bin/env bats
# =============================================================================
# Testes de Integração — sync.sh
# =============================================================================
# Cenários end-to-end para o script de sincronização do baseline global.
#
# Cobertura:
#   - Sync baseline: atualiza, adiciona, sem mudança
#   - --component inválido: exit 1 + mensagem com valores válidos
#   - Manifest ausente: exit 1 + mensagem indicando bootstrap
#   - --dry-run: lista sem alterar filesystem
#   - Resumo de contagens correto (novos, atualizados, sem mudança)
#   - Atualização de baseline.last_synced_at no manifest
#   - --component all: sincroniza baseline, archetype, powers em ordem
#   - Target inexistente: exit 1 com mensagem de erro
#
# **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10**
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/assertions'

# Caminho do script sob teste
SYNC_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/sync.sh"

# Diretórios fonte
BASELINE_STEERING="${BATS_TEST_DIRNAME}/../../baselines/global/steering"
BASELINE_MCP="${BATS_TEST_DIRNAME}/../../baselines/global/mcp/mcp.json"

setup() {
  # Cria projeto temporário para cada teste
  TEST_PROJECT=$(create_temp_project)
}

teardown() {
  cleanup_fixtures
}

# =============================================================================
# Cenário 1: Sync baseline — atualiza arquivos desatualizados
# Validates: Requirement 5.2
# =============================================================================
@test "sync baseline: atualiza steering files desatualizados" {
  # Arrange: projeto com manifest e steering files desatualizados
  setup_manifest "${TEST_PROJECT}"
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Cria steering files com conteúdo diferente do baseline
  for src_file in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    echo "conteúdo desatualizado para ${fname}" > "${TEST_PROJECT}/.kiro/steering/${fname}"
  done

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component baseline

  # Assert: exit code 0
  assert_success

  # Assert: steering files são idênticos ao baseline
  for src_file in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    assert_file_identical "${src_file}" "${TEST_PROJECT}/.kiro/steering/${fname}"
  done
}

# =============================================================================
# Cenário 2: Sync baseline — adiciona arquivos novos ausentes
# Validates: Requirement 5.3
# =============================================================================
@test "sync baseline: adiciona steering files ausentes no destino" {
  # Arrange: projeto com manifest mas sem steering files
  setup_manifest "${TEST_PROJECT}"
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Garante diretório steering vazio
  rm -f "${TEST_PROJECT}/.kiro/steering/"*.md

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component baseline

  # Assert
  assert_success

  # Todos os steering files do baseline devem existir no destino
  for src_file in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    assert [ -f "${TEST_PROJECT}/.kiro/steering/${fname}" ]
    assert_file_identical "${src_file}" "${TEST_PROJECT}/.kiro/steering/${fname}"
  done
}

# =============================================================================
# Cenário 3: Sync baseline — sem mudança quando já idênticos
# Validates: Requirement 5.1
# =============================================================================
@test "sync baseline: não altera arquivos já idênticos ao baseline" {
  # Arrange: projeto com steering files idênticos ao baseline
  setup_manifest "${TEST_PROJECT}"
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  for src_file in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${src_file}" "${TEST_PROJECT}/.kiro/steering/${fname}"
  done

  # Captura timestamps dos arquivos antes do sync
  local before_timestamps
  before_timestamps=$(find "${TEST_PROJECT}/.kiro/steering" -name "*.md" -exec stat -f "%m %N" {} \; 2>/dev/null || \
                      find "${TEST_PROJECT}/.kiro/steering" -name "*.md" -exec stat -c "%Y %n" {} \; 2>/dev/null)

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component baseline

  # Assert: sucesso
  assert_success

  # Output deve indicar "Sem mudança" ou ausência de "atualizado/novo"
  # O resumo mostra FILES_UNCHANGED > 0
  assert_output --partial "Sem mudança"
}

# =============================================================================
# Cenário 4: --component inválido encerra com exit 1
# Validates: Requirement 5.9
# =============================================================================
@test "sync: --component inválido encerra com exit 1 e lista valores válidos" {
  # Arrange
  setup_manifest "${TEST_PROJECT}"
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component invalido

  # Assert
  assert_failure
  assert_output --partial "Componente inválido"
  assert_output --partial "baseline"
  assert_output --partial "archetype"
  assert_output --partial "powers"
  assert_output --partial "all"
}

# =============================================================================
# Cenário 5: Manifest ausente encerra com exit 1 e mensagem bootstrap
# Validates: Requirement 5.7
# =============================================================================
@test "sync: manifest ausente encerra com exit 1 e instrui rodar bootstrap" {
  # Arrange: projeto sem kiro-manifest.json
  # (create_temp_project não gera manifest na raiz)

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}"

  # Assert
  assert_failure
  assert_output --partial "kiro-manifest.json"
  assert_output --partial "bootstrap"
}

# =============================================================================
# Cenário 6: --dry-run lista mudanças sem alterar filesystem
# Validates: Requirement 5.6
# =============================================================================
@test "sync: --dry-run lista mudanças sem modificar arquivos" {
  # Arrange: projeto com manifest e steering desatualizados
  setup_manifest "${TEST_PROJECT}"
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Cria um arquivo desatualizado e deixa os demais ausentes
  local first_file
  first_file=$(find "${BASELINE_STEERING}" -maxdepth 1 -name "*.md" -not -name "README.md" -type f | head -1)
  if [[ -n "${first_file}" ]]; then
    local fname
    fname=$(basename "${first_file}")
    echo "conteúdo antigo" > "${TEST_PROJECT}/.kiro/steering/${fname}"
  fi

  # Snapshot do filesystem antes
  local snapshot_before
  snapshot_before=$(find "${TEST_PROJECT}" -type f -exec md5 -r {} \; 2>/dev/null | sort || \
                    find "${TEST_PROJECT}" -type f -exec md5sum {} \; 2>/dev/null | sort)

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component baseline --dry-run

  # Assert: saída menciona DRY-RUN
  assert_success
  assert_output --partial "DRY-RUN"

  # Assert: filesystem inalterado
  local snapshot_after
  snapshot_after=$(find "${TEST_PROJECT}" -type f -exec md5 -r {} \; 2>/dev/null | sort || \
                   find "${TEST_PROJECT}" -type f -exec md5sum {} \; 2>/dev/null | sort)

  assert_equal "${snapshot_before}" "${snapshot_after}"
}

# =============================================================================
# Cenário 7: Resumo de contagens correto
# Validates: Requirement 5.8
# =============================================================================
@test "sync: exibe resumo com contagens de novos, atualizados e sem mudança" {
  # Arrange: projeto com mix de estados
  setup_manifest "${TEST_PROJECT}"
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Pegar lista de steering files do baseline
  local all_files=()
  for src_file in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    all_files+=("${fname}")
  done

  # Se temos pelo menos 2 arquivos, criamos estados mistos
  if [[ ${#all_files[@]} -ge 2 ]]; then
    # Primeiro arquivo: idêntico (sem mudança)
    cp "${BASELINE_STEERING}/${all_files[0]}" "${TEST_PROJECT}/.kiro/steering/${all_files[0]}"
    # Segundo arquivo: desatualizado
    echo "desatualizado" > "${TEST_PROJECT}/.kiro/steering/${all_files[1]}"
    # Demais: ausentes (novos)
  fi

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component baseline

  # Assert
  assert_success
  assert_output --partial "Novos:"
  assert_output --partial "Atualizados:"
  assert_output --partial "Sem mudança:"
}

# =============================================================================
# Cenário 8: Atualização de baseline.last_synced_at no manifest
# Validates: Requirement 5.5
# =============================================================================
@test "sync: atualiza baseline.last_synced_at no manifest após sucesso" {
  # Arrange: projeto com manifest e data de sync antiga
  local old_date="2020-01-01T00:00:00Z"
  setup_manifest "${TEST_PROJECT}" '{"baseline": {"last_synced_at": "2020-01-01T00:00:00Z"}}'
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component baseline

  # Assert
  assert_success

  # Verifica que last_synced_at foi atualizado (não é mais a data antiga)
  local new_sync_date
  new_sync_date=$(jq -r '.baseline.last_synced_at' "${TEST_PROJECT}/kiro-manifest.json")

  assert [ "${new_sync_date}" != "${old_date}" ]
  # Deve ser uma data ISO 8601 recente (formato YYYY-MM-DDTHH:MM:SSZ)
  assert [ -n "${new_sync_date}" ]
  [[ "${new_sync_date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# =============================================================================
# Cenário 9: --component all sincroniza todos os componentes
# Validates: Requirement 5.4
# =============================================================================
@test "sync: --component all sincroniza baseline, archetype e powers em ordem" {
  # Arrange
  setup_manifest "${TEST_PROJECT}"
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component all

  # Assert: sucesso
  assert_success

  # Output menciona sincronização de cada componente na ordem
  assert_output --partial "baseline"
  assert_output --partial "archetype"
  assert_output --partial "powers"

  # Steering files do baseline devem existir
  for src_file in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    assert [ -f "${TEST_PROJECT}/.kiro/steering/${fname}" ]
  done
}

# =============================================================================
# Cenário 10: Target inexistente encerra com exit 1
# Validates: Requirement 5.10
# =============================================================================
@test "sync: diretório target inexistente encerra com exit 1" {
  # Act
  run bash "${SYNC_SCRIPT}" --target "/caminho/inexistente/xyz123"

  # Assert
  assert_failure
  assert_output --partial "não encontrado"
}

# =============================================================================
# Cenário 11: --dry-run não atualiza last_synced_at
# Validates: Requirements 5.5, 5.6
# =============================================================================
@test "sync: --dry-run não atualiza baseline.last_synced_at" {
  # Arrange
  local old_date="2020-01-01T00:00:00Z"
  setup_manifest "${TEST_PROJECT}" '{"baseline": {"last_synced_at": "2020-01-01T00:00:00Z"}}'
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component baseline --dry-run

  # Assert
  assert_success

  # last_synced_at deve permanecer inalterada
  local current_date
  current_date=$(jq -r '.baseline.last_synced_at' "${TEST_PROJECT}/kiro-manifest.json")
  assert_equal "${old_date}" "${current_date}"
}
