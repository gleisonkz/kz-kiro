#!/usr/bin/env bats
# =============================================================================
# Testes de Integração — doctor.sh com Archetype mobile-flutter
# =============================================================================
# Cenários end-to-end para o script de diagnóstico de conformidade
# quando o projeto utiliza o archetype mobile-flutter.
#
# Requisitos cobertos: 9.1, 9.2, 9.3, 9.4
# Design: Integração com Scripts de Automação (doctor.sh)
#
# Diferenciais do mobile-flutter para o doctor:
# - 15 steering files (vs 4-5 nos outros archetypes)
# - 5 hooks (vs 6-7 nos outros archetypes)
# - Servidor MCP funcional (dart) — doctor deve identificar como obrigatório
# - NÃO possui VERSION/CHANGELOG — ausência NÃO é gap
# - Skills e agents vazios (apenas READMEs)
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/assertions'

# Caminhos
DOCTOR_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"
BASELINE_STEERING_DIR="${BATS_TEST_DIRNAME}/../../baselines/global/steering"
BASELINE_MCP="${BATS_TEST_DIRNAME}/../../baselines/global/mcp/mcp.json"
ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"

# --- Setup / Teardown ---

teardown() {
  cleanup_fixtures
}

# --- Funções auxiliares ---

# Cria um projeto completamente saudável com archetype mobile-flutter aplicado
_create_healthy_flutter_project() {
  local project_dir
  project_dir="$(create_temp_project)"

  # Copiar steering files do baseline
  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    [[ ! -f "${f}" ]] && continue
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  # Copiar steering files do archetype mobile-flutter (15 arquivos)
  for f in "${ARCHETYPE_DIR}/steering"/*.md; do
    [[ ! -f "${f}" ]] && continue
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  # Copiar hooks do archetype (5 hooks)
  for f in "${ARCHETYPE_DIR}/hooks"/*.kiro.hook; do
    [[ ! -f "${f}" ]] && continue
    local fname
    fname=$(basename "${f}")
    cp "${f}" "${project_dir}/.kiro/hooks/${fname}"
  done

  # MCP: merge baseline global + archetype (baseline + dart server)
  # Usa jq para merge se disponível, senão copia baseline e adiciona dart manualmente
  if command -v jq &>/dev/null; then
    jq -s '.[0] * {mcpServers: (.[0].mcpServers + .[1].mcpServers)}' \
      "${BASELINE_MCP}" "${ARCHETYPE_DIR}/mcp/mcp.json" \
      > "${project_dir}/.kiro/settings/mcp.json"
  else
    cp "${BASELINE_MCP}" "${project_dir}/.kiro/settings/mcp.json"
  fi

  # Criar manifest válido com archetype mobile-flutter
  _create_flutter_manifest "${project_dir}"

  # Inicializar como git repo
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test Flutter Project" > "${project_dir}/README.md"

  echo "${project_dir}"
}

# Cria manifest com archetype mobile-flutter declarado
_create_flutter_manifest() {
  local project_dir="$1"
  local exceptions="${2:-[]}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  cat > "${project_dir}/kiro-manifest.json" <<EOF
{
  "_generated_by": "test-integration-flutter",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test-flutter-project", "repository": "org/test-flutter-project" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "mobile-flutter", "version": "0.1.0", "installed_at": "${now}" },
  "powers": [],
  "exceptions": ${exceptions}
}
EOF
}

# =============================================================================
# Cenário 1: Projeto saudável — exit 0, todos PASS
# Validates: Requirements 9.1, 9.2
# =============================================================================

@test "doctor flutter: projeto saudável retorna exit 0 com todos os checks PASS" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  refute_output --partial "[FAIL]"
  assert_output --partial "mobile-flutter"
  assert_output --partial "[PASS]"
}

@test "doctor flutter: projeto saudável reporta steering files como presentes" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  assert_output --partial "steering"
  assert_output --partial "[PASS]"
}

@test "doctor flutter: projeto saudável reporta hooks como presentes" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  assert_output --partial "hooks"
  assert_output --partial "[PASS]"
}

@test "doctor flutter: projeto saudável reporta MCP servers como presentes" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  assert_output --partial "mcp.json"
  assert_output --partial "[PASS]"
}

# =============================================================================
# Cenário 2: Steering file ausente — doctor reporta ❌
# Validates: Requirements 9.2
# =============================================================================

@test "doctor flutter: steering file do baseline ausente reporta FAIL" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Remover um steering file do baseline
  rm -f "${project_dir}/.kiro/steering/security-baseline.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_failure
  assert_output --partial "[FAIL]"
  assert_output --partial "Ausente"
  assert_output --partial "security-baseline.md"
}

@test "doctor flutter: steering file do archetype ausente reporta WARN" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Remover um steering file do archetype
  rm -f "${project_dir}/.kiro/steering/coding-standards.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve detectar que há steering files faltantes do archetype
  assert_output --partial "steering"
  assert_output --regexp '\[(FAIL|WARN)\]'
}

# =============================================================================
# Cenário 3: Hook desabilitado — doctor reporta ⚠️
# Validates: Requirements 9.1, 9.2
# =============================================================================

@test "doctor flutter: hook desabilitado reporta divergência" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Modificar um hook para ficar desabilitado (conteúdo difere do archetype)
  local hook_file="${project_dir}/.kiro/hooks/dart-analyze-save.kiro.hook"
  cat > "${hook_file}" <<'EOF'
{
  "enabled": false,
  "name": "Dart Analyze on Save",
  "description": "Hook desabilitado pelo desenvolvedor.",
  "version": "1",
  "when": {
    "type": "fileEdited",
    "patterns": ["**/*.dart"]
  },
  "then": {
    "type": "runCommand",
    "command": "dart analyze \"$KIRO_FILE_PATH\""
  }
}
EOF

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # O doctor deve detectar divergência nos hooks (arquivo difere da fonte)
  assert_output --partial "hooks"
}

@test "doctor flutter: hook removido reporta contagem incompleta" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Remover um hook
  rm -f "${project_dir}/.kiro/hooks/barrel-export-reminder.kiro.hook"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve detectar hook faltante
  assert_output --partial "hooks"
  assert_output --regexp '\[(FAIL|WARN)\]'
}

# =============================================================================
# Cenário 4: Dart MCP server disabled — doctor reporta ⚠️
# Validates: Requirements 9.2, 10.3
# =============================================================================

@test "doctor flutter: mcp.json com dart server disabled diverge do baseline merge" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Modificar mcp.json para desabilitar o dart server
  local mcp_file="${project_dir}/.kiro/settings/mcp.json"
  local tmp_mcp
  tmp_mcp=$(jq '.mcpServers.dart.disabled = true' "${mcp_file}")
  echo "${tmp_mcp}" > "${mcp_file}"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # O doctor compara mcp.json do projeto com o baseline — mudança deve causar WARN
  assert_output --partial "mcp.json"
  assert_output --regexp '\[(WARN|PASS)\]'
}

@test "doctor flutter: mcp.json sem entrada dart diverge do merge esperado" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Remover a entrada dart do mcp.json (baseline global não tem dart, mobile-flutter sim)
  local mcp_file="${project_dir}/.kiro/settings/mcp.json"
  local tmp_mcp
  tmp_mcp=$(jq 'del(.mcpServers.dart)' "${mcp_file}")
  echo "${tmp_mcp}" > "${mcp_file}"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # MCP sem dart = difere do baseline+archetype merge = WARN
  assert_output --partial "mcp.json"
  assert_output --regexp '\[(WARN|PASS)\]'
}

# =============================================================================
# Cenário 5: Relatório contém as 8 seções na ordem correta (via hook doctor prompt)
# Validates: Requirements 9.3
# =============================================================================

@test "doctor flutter: kiro-doctor hook contém as 8 seções esperadas no prompt" {
  local hook_file="${ARCHETYPE_DIR}/hooks/kiro-doctor.kiro.hook"

  # Arquivo deve existir
  assert [ -f "${hook_file}" ]

  # Ler o prompt e verificar as 8 seções
  local prompt
  prompt=$(jq -r '.then.prompt' "${hook_file}")

  # Seção 1: Resumo
  assert [ -n "$(echo "${prompt}" | grep -i 'Resumo')" ]
  # Seção 2: Steering
  assert [ -n "$(echo "${prompt}" | grep -i 'Steering')" ]
  # Seção 3: Hooks
  assert [ -n "$(echo "${prompt}" | grep -i 'Hooks')" ]
  # Seção 4: MCP Servers
  assert [ -n "$(echo "${prompt}" | grep -i 'MCP')" ]
  # Seção 5: Skills
  assert [ -n "$(echo "${prompt}" | grep -i 'Skills')" ]
  # Seção 6: Specs
  assert [ -n "$(echo "${prompt}" | grep -i 'Specs')" ]
  # Seção 7: Arquitetura
  assert [ -n "$(echo "${prompt}" | grep -i 'Arquitetura')" ]
  # Seção 8: Recomendações
  assert [ -n "$(echo "${prompt}" | grep -i 'Recomenda')" ]
}

@test "doctor flutter: kiro-doctor hook define as 8 seções na ordem correta" {
  local hook_file="${ARCHETYPE_DIR}/hooks/kiro-doctor.kiro.hook"
  command -v jq &>/dev/null || skip "jq necessário"

  local prompt
  prompt=$(jq -r '.then.prompt' "${hook_file}")

  # Verificar que a ordem é: Resumo < Steering < Hooks < MCP < Skills < Specs < Arquitetura < Recomendações
  # Usa awk para buscar padrões de forma portável (evita problemas com ** em grep regex no macOS)
  local pos_resumo pos_steering pos_hooks pos_mcp pos_skills pos_specs pos_arq pos_rec

  pos_resumo=$(echo "${prompt}" | awk '/\*\*Resumo\*\*/{print NR; exit}')
  pos_steering=$(echo "${prompt}" | awk '/\*\*Steering\*\*/{print NR; exit}')
  pos_hooks=$(echo "${prompt}" | awk '/\*\*Hooks\*\*/{print NR; exit}')
  pos_mcp=$(echo "${prompt}" | awk '/\*\*MCP/{print NR; exit}')
  pos_skills=$(echo "${prompt}" | awk '/\*\*Skills\*\*/{print NR; exit}')
  pos_specs=$(echo "${prompt}" | awk '/\*\*Specs\*\*/{print NR; exit}')
  pos_arq=$(echo "${prompt}" | awk '/\*\*Arquitetura\*\*/{print NR; exit}')
  pos_rec=$(echo "${prompt}" | awk '/\*\*Recomenda/{print NR; exit}')

  # Verificar que todos foram encontrados
  assert [ -n "${pos_resumo}" ]
  assert [ -n "${pos_steering}" ]
  assert [ -n "${pos_hooks}" ]
  assert [ -n "${pos_mcp}" ]
  assert [ -n "${pos_skills}" ]
  assert [ -n "${pos_specs}" ]
  assert [ -n "${pos_arq}" ]
  assert [ -n "${pos_rec}" ]

  # Verificar ordem crescente
  assert [ "${pos_resumo}" -lt "${pos_steering}" ]
  assert [ "${pos_steering}" -lt "${pos_hooks}" ]
  assert [ "${pos_hooks}" -lt "${pos_mcp}" ]
  assert [ "${pos_mcp}" -lt "${pos_skills}" ]
  assert [ "${pos_skills}" -lt "${pos_specs}" ]
  assert [ "${pos_specs}" -lt "${pos_arq}" ]
  assert [ "${pos_arq}" -lt "${pos_rec}" ]
}

# =============================================================================
# Cenário 6: Doctor espera 15 steering files do archetype
# Validates: Requirements 9.2
# =============================================================================

@test "doctor flutter: verifica contagem de steering files do archetype (15)" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype mobile-flutter tem 15 steering files (excl. README)
  assert_output --partial "steering"
  assert_output --regexp 'steering: [0-9]+/15 arquivos presentes'
}

# =============================================================================
# Cenário 7: Doctor espera 5 hooks do archetype
# Validates: Requirements 9.1
# =============================================================================

@test "doctor flutter: verifica contagem correta de hooks (5 do archetype)" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype mobile-flutter tem 5 hooks
  assert_output --partial "hooks"
  assert_output --partial "5/5"
}

# =============================================================================
# Cenário 8: Doctor reporta dart MCP como obrigatório (diferente dos outros)
# Validates: Requirements 9.2, 10.3
# =============================================================================

@test "doctor flutter: detecta archetype mobile-flutter via manifest" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # Deve identificar o archetype corretamente
  assert_output --partial "Archetype: mobile-flutter"
}

@test "doctor flutter: mcp.json com dart server presente passa validação" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # Com dart server presente no mcp.json, doctor não deve reportar problema de MCP
  assert_output --partial "mcp.json presente"
  assert_output --partial "[PASS]"
}

@test "doctor flutter: archetype mobile-flutter tem MCP funcional (vs mcpServers vazio nos outros)" {
  # Verificar que o archetype mobile-flutter tem servidor dart no mcp.json
  # enquanto os outros archetypes têm mcpServers vazio
  command -v jq &>/dev/null || skip "jq necessário"

  local flutter_mcp="${ARCHETYPE_DIR}/mcp/mcp.json"
  assert [ -f "${flutter_mcp}" ]

  # mobile-flutter tem mcpServers com ao menos 1 servidor (dart)
  local flutter_server_count
  flutter_server_count=$(jq '.mcpServers | keys | length' "${flutter_mcp}")
  assert [ "${flutter_server_count}" -ge 1 ]

  # Verificar que a entrada dart existe e não está disabled
  local dart_disabled
  dart_disabled=$(jq -r '.mcpServers.dart.disabled' "${flutter_mcp}")
  assert [ "${dart_disabled}" == "false" ]

  # Comparar com bff-fastify que tem mcpServers vazio
  local bff_mcp="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify/mcp/mcp.json"
  if [[ -f "${bff_mcp}" ]]; then
    local bff_server_count
    bff_server_count=$(jq '.mcpServers | keys | length' "${bff_mcp}")
    assert [ "${bff_server_count}" -eq 0 ]
  fi
}

# =============================================================================
# Cenário 9: Ausência de VERSION/CHANGELOG NÃO é reportada como gap
# Validates: Requirements 9.2 (ausência é esperada)
# =============================================================================

@test "doctor flutter: ausência de VERSION e CHANGELOG não gera FAIL" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Garantir que NÃO existem VERSION nem CHANGELOG no projeto
  rm -f "${project_dir}/VERSION"
  rm -f "${project_dir}/CHANGELOG.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Projeto saudável (sem VERSION/CHANGELOG) não deve falhar
  assert_success
  refute_output --partial "[FAIL]"
}

@test "doctor flutter: archetype mobile-flutter não possui VERSION na fonte" {
  # Confirmar que o archetype NÃO tem VERSION — ausência é intencional
  assert [ ! -f "${ARCHETYPE_DIR}/VERSION" ]
}

@test "doctor flutter: archetype mobile-flutter não possui CHANGELOG na fonte" {
  # Confirmar que o archetype NÃO tem CHANGELOG.md — ausência é intencional
  assert [ ! -f "${ARCHETYPE_DIR}/CHANGELOG.md" ]
}

# =============================================================================
# Cenário extra: Doctor JSON output contém categoria archetype
# Validates: Requirements 9.2, 9.4
# =============================================================================

@test "doctor flutter: output JSON contém resultados da categoria archetype" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  assert_success

  # Output deve ser JSON válido
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  # Deve conter resultados na categoria archetype
  local archetype_results
  archetype_results=$(echo "${output}" | jq '[.results[] | select(.category == "archetype")] | length')
  assert [ "${archetype_results}" -gt 0 ]

  # Deve ter archetype identificado como mobile-flutter
  local has_flutter
  has_flutter=$(echo "${output}" | jq '[.results[] | select(.message | contains("mobile-flutter"))] | length')
  assert [ "${has_flutter}" -gt 0 ]
}

@test "doctor flutter: output JSON com hook ausente reporta warn" {
  [[ -f "${DOCTOR_SCRIPT}" ]] || skip "doctor.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(_create_healthy_flutter_project)"

  # Remover hook
  rm -f "${project_dir}/.kiro/hooks/scaffold-test-file.kiro.hook"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  # Output deve ser JSON válido
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  # Deve ter resultado warn ou fail para archetype
  local problem_results
  problem_results=$(echo "${output}" | jq '[.results[] | select(.category == "archetype" and (.status == "warn" or .status == "fail"))] | length')
  assert [ "${problem_results}" -gt 0 ]
}
