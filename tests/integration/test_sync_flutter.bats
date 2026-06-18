#!/usr/bin/env bats
# =============================================================================
# Testes de Integração — sync.sh (Archetype mobile-flutter)
# =============================================================================
# Cenários end-to-end para sincronização do archetype mobile-flutter.
#
# Cobertura:
#   - Sync archetype: atualiza steering file desatualizado
#   - Sync archetype: adiciona hook novo ausente no projeto
#   - Sync archetype: mantém inalterado o que já está correto
#   - Sync archetype: atualiza last_synced_at no manifest
#   - Sync archetype: atualiza hook desatualizado
#   - Sync archetype: steering files com frontmatter são copiados integralmente
#   - Sync archetype: dry-run não modifica arquivos
#
# **Validates: Design — Integração com Scripts de Automação (sync.sh)**
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/assertions'
load '../helpers/generators'

# Caminhos
SYNC_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/sync.sh"
REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"

setup() {
  [[ -f "${SYNC_SCRIPT}" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  # Cria projeto temporário com manifest indicando archetype mobile-flutter
  TEST_PROJECT=$(create_temp_project)
  setup_manifest "${TEST_PROJECT}" '{"archetype": {"name": "mobile-flutter", "version": "0.1.0"}}'
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"
}

teardown() {
  cleanup_fixtures
}

# =============================================================================
# Cenário 1: Sync archetype — atualiza steering file desatualizado
# Validates: Design — sync.sh sobrescreve arquivos desatualizados
# =============================================================================
@test "sync archetype mobile-flutter: atualiza steering file desatualizado" {
  # Arrange: cria steering files com conteúdo diferente do archetype
  for src_file in "${ARCHETYPE_DIR}/steering/"*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    echo "conteúdo desatualizado de ${fname}" > "${TEST_PROJECT}/.kiro/steering/${fname}"
  done

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert: exit code 0
  assert_success

  # Assert: steering files são agora idênticos ao archetype
  for src_file in "${ARCHETYPE_DIR}/steering/"*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    assert_file_identical "${src_file}" "${TEST_PROJECT}/.kiro/steering/${fname}"
  done
}

# =============================================================================
# Cenário 2: Sync archetype — adiciona hooks ausentes no projeto
# Validates: Design — sync.sh adiciona novos artefatos
# =============================================================================
@test "sync archetype mobile-flutter: adiciona hooks ausentes no projeto" {
  # Arrange: projeto sem nenhum hook do archetype
  rm -f "${TEST_PROJECT}/.kiro/hooks/"*.kiro.hook 2>/dev/null || true

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert
  assert_success

  # Todos os hooks do archetype devem existir no destino
  for src_file in "${ARCHETYPE_DIR}/hooks/"*.kiro.hook; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    assert [ -f "${TEST_PROJECT}/.kiro/hooks/${fname}" ]
    assert_file_identical "${src_file}" "${TEST_PROJECT}/.kiro/hooks/${fname}"
  done
}

# =============================================================================
# Cenário 3: Sync archetype — mantém inalterado o que já está correto
# Validates: Design — sync.sh não altera arquivos idênticos
# =============================================================================
@test "sync archetype mobile-flutter: não altera arquivos já idênticos" {
  # Arrange: copia todos os artefatos do archetype para o projeto (idênticos)
  for src_file in "${ARCHETYPE_DIR}/steering/"*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${src_file}" "${TEST_PROJECT}/.kiro/steering/${fname}"
  done

  for src_file in "${ARCHETYPE_DIR}/hooks/"*.kiro.hook; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    cp "${src_file}" "${TEST_PROJECT}/.kiro/hooks/${fname}"
  done

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert: sucesso
  assert_success

  # Output deve indicar "Sem mudança" (contagem sem mudança > 0 no resumo)
  assert_output --partial "Sem mudança"
}

# =============================================================================
# Cenário 4: Sync archetype — atualiza last_synced_at no manifest
# Validates: Design — sync.sh atualiza last_synced_at
# =============================================================================
@test "sync archetype mobile-flutter: atualiza last_synced_at no manifest" {
  # Arrange: manifest com data de sync antiga
  local old_date="2020-01-01T00:00:00Z"
  setup_manifest "${TEST_PROJECT}" '{"baseline": {"last_synced_at": "2020-01-01T00:00:00Z"}, "archetype": {"name": "mobile-flutter", "version": "0.1.0"}}'
  cp "${TEST_PROJECT}/.kiro/kiro-manifest.json" "${TEST_PROJECT}/kiro-manifest.json"

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert
  assert_success

  # last_synced_at deve ter sido atualizado (não é mais a data antiga)
  local new_sync_date
  new_sync_date=$(jq -r '.baseline.last_synced_at' "${TEST_PROJECT}/kiro-manifest.json")

  assert [ "${new_sync_date}" != "${old_date}" ]
  # Deve ser uma data ISO 8601 recente
  assert [ -n "${new_sync_date}" ]
  [[ "${new_sync_date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# =============================================================================
# Cenário 5: Sync archetype — atualiza hook desatualizado
# Validates: Design — sync.sh sobrescreve hooks com conteúdo divergente
# =============================================================================
@test "sync archetype mobile-flutter: atualiza hook desatualizado" {
  # Arrange: cria um hook com conteúdo diferente do archetype
  local first_hook
  first_hook=$(find "${ARCHETYPE_DIR}/hooks" -maxdepth 1 -name "*.kiro.hook" -type f | head -1)
  [[ -n "${first_hook}" ]] || skip "Nenhum hook encontrado no archetype"

  local hook_name
  hook_name=$(basename "${first_hook}")
  echo '{"enabled": false, "name": "desatualizado"}' > "${TEST_PROJECT}/.kiro/hooks/${hook_name}"

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert
  assert_success

  # Hook deve ter sido atualizado para o conteúdo do archetype
  assert_file_identical "${first_hook}" "${TEST_PROJECT}/.kiro/hooks/${hook_name}"
}

# =============================================================================
# Cenário 6: Sync archetype — steering files com frontmatter preservado
# Validates: Design — sync.sh copia frontmatter YAML integralmente
# Diferencial do mobile-flutter: steering files possuem frontmatter YAML
# (inclusion, name, description, fileMatchPattern) que deve ser preservado.
# =============================================================================
@test "sync archetype mobile-flutter: frontmatter YAML é preservado na cópia" {
  # Arrange: steering files desatualizados (sem frontmatter)
  for src_file in "${ARCHETYPE_DIR}/steering/"*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue
    echo "# Conteúdo sem frontmatter" > "${TEST_PROJECT}/.kiro/steering/${fname}"
  done

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert
  assert_success

  # Verificar que steering files com frontmatter foram copiados byte-a-byte
  # (frontmatter YAML preservado integralmente)
  for src_file in "${ARCHETYPE_DIR}/steering/"*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local fname
    fname=$(basename "${src_file}")
    [[ "${fname}" == "README.md" ]] && continue

    # Verificar que o destino é idêntico à fonte (inclui frontmatter)
    assert_file_identical "${src_file}" "${TEST_PROJECT}/.kiro/steering/${fname}"

    # Verificar que o frontmatter está presente (começa com ---)
    local first_line
    first_line=$(head -1 "${TEST_PROJECT}/.kiro/steering/${fname}")
    assert [ "${first_line}" == "---" ]
  done
}

# =============================================================================
# Cenário 7: Sync archetype — verifica que todos os 15 steering files
#             do mobile-flutter são sincronizados
# Validates: Design — sync.sh copia todos artefatos do archetype
# =============================================================================
@test "sync archetype mobile-flutter: sincroniza todos os 15 steering files" {
  # Arrange: projeto sem nenhum steering file do archetype
  rm -f "${TEST_PROJECT}/.kiro/steering/"*.md 2>/dev/null || true

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert
  assert_success

  # Contar steering files sincronizados (excluindo README.md)
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

  for fname in "${expected_files[@]}"; do
    assert [ -f "${TEST_PROJECT}/.kiro/steering/${fname}" ]
    assert_file_identical "${ARCHETYPE_DIR}/steering/${fname}" "${TEST_PROJECT}/.kiro/steering/${fname}"
  done
}

# =============================================================================
# Cenário 8: Sync archetype — sincroniza todos os 5 hooks
# Validates: Design — sync.sh copia hooks do archetype
# =============================================================================
@test "sync archetype mobile-flutter: sincroniza todos os 5 hooks" {
  # Arrange: projeto sem hooks
  rm -f "${TEST_PROJECT}/.kiro/hooks/"*.kiro.hook 2>/dev/null || true

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype

  # Assert
  assert_success

  # Verificar que todos os 5 hooks foram sincronizados
  local expected_hooks=(
    "dart-analyze-save.kiro.hook"
    "check-relative-imports.kiro.hook"
    "barrel-export-reminder.kiro.hook"
    "scaffold-test-file.kiro.hook"
    "kiro-doctor.kiro.hook"
  )

  for fname in "${expected_hooks[@]}"; do
    assert [ -f "${TEST_PROJECT}/.kiro/hooks/${fname}" ]
    assert_file_identical "${ARCHETYPE_DIR}/hooks/${fname}" "${TEST_PROJECT}/.kiro/hooks/${fname}"
  done
}

# =============================================================================
# Cenário 9: Sync archetype — dry-run não modifica arquivos
# Validates: Design — sync.sh com --dry-run não aplica mudanças
# =============================================================================
@test "sync archetype mobile-flutter: dry-run não modifica arquivos" {
  # Arrange: cria steering file desatualizado
  local first_steering
  first_steering=$(find "${ARCHETYPE_DIR}/steering" -maxdepth 1 -name "*.md" -not -name "README.md" -type f | head -1)
  [[ -n "${first_steering}" ]] || skip "Nenhum steering file encontrado no archetype"

  local steering_name
  steering_name=$(basename "${first_steering}")
  echo "conteúdo antigo" > "${TEST_PROJECT}/.kiro/steering/${steering_name}"

  # Snapshot do filesystem antes
  local snapshot_before
  snapshot_before=$(find "${TEST_PROJECT}" -type f -exec md5 -r {} \; 2>/dev/null | sort || \
                    find "${TEST_PROJECT}" -type f -exec md5sum {} \; 2>/dev/null | sort)

  # Act
  run bash "${SYNC_SCRIPT}" --target "${TEST_PROJECT}" --component archetype --dry-run

  # Assert
  assert_success
  assert_output --partial "DRY-RUN"

  # Filesystem deve estar inalterado
  local snapshot_after
  snapshot_after=$(find "${TEST_PROJECT}" -type f -exec md5 -r {} \; 2>/dev/null | sort || \
                   find "${TEST_PROJECT}" -type f -exec md5sum {} \; 2>/dev/null | sort)

  assert_equal "${snapshot_before}" "${snapshot_after}"
}
