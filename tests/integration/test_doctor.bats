#!/usr/bin/env bats
# =============================================================================
# Testes de Integração — doctor.sh
# =============================================================================
# Cenários end-to-end para o script de diagnóstico de conformidade.
#
# Requisitos cobertos: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10,
#                      9.4, 9.5
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/assertions'

# Caminhos
DOCTOR_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"
BASELINE_STEERING_DIR="${BATS_TEST_DIRNAME}/../../baselines/global/steering"
BASELINE_MCP="${BATS_TEST_DIRNAME}/../../baselines/global/mcp/mcp.json"

# --- Setup / Teardown ---

teardown() {
  cleanup_fixtures
}

# --- Funções auxiliares ---

# Cria um projeto completamente saudável (todos os steering files idênticos ao baseline)
_create_healthy_project() {
  local project_dir
  project_dir="$(create_temp_project)"

  # Copiar todos os steering files do baseline
  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  # Copiar mcp.json do baseline
  cp "${BASELINE_MCP}" "${project_dir}/.kiro/settings/mcp.json"

  # Criar manifest válido
  _create_manifest "${project_dir}" "[]"

  # Inicializar como git repo (check_general_health verifica)
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test" > "${project_dir}/README.md"

  echo "${project_dir}"
}

# Cria manifest no formato que o doctor.sh espera (na raiz do projeto, não em .kiro/)
_create_manifest() {
  local project_dir="$1"
  local exceptions="${2:-[]}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  cat > "${project_dir}/kiro-manifest.json" <<EOF
{
  "_generated_by": "test-integration",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test-project", "repository": "org/test-project" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "frontend-react", "version": "0.1.0", "installed_at": "${now}" },
  "powers": [],
  "exceptions": ${exceptions}
}
EOF
}

# Gera exceção válida (não expirada)
_gen_valid_exception() {
  local rule="$1"
  local approved_at review_date

  if date -v-10d +%Y-%m-%dT%H:%M:%SZ &>/dev/null 2>&1; then
    approved_at=$(date -u -v-10d +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -v+60d +%Y-%m-%dT%H:%M:%SZ)
  else
    approved_at=$(date -u -d "10 days ago" +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -d "60 days" +%Y-%m-%dT%H:%M:%SZ)
  fi

  cat <<EOF
{
  "rule": "${rule}",
  "reason": "Excecao tecnica aprovada para este artefato no contexto de integracao",
  "approved_by": "admin@montebravo.com",
  "approved_at": "${approved_at}",
  "review_date": "${review_date}"
}
EOF
}

# Gera exceção expirada
_gen_expired_exception() {
  local rule="$1"
  local approved_at review_date

  if date -v-120d +%Y-%m-%dT%H:%M:%SZ &>/dev/null 2>&1; then
    approved_at=$(date -u -v-120d +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -v-40d +%Y-%m-%dT%H:%M:%SZ)
  else
    approved_at=$(date -u -d "120 days ago" +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -d "40 days ago" +%Y-%m-%dT%H:%M:%SZ)
  fi

  cat <<EOF
{
  "rule": "${rule}",
  "reason": "Excecao tecnica que expirou e precisa ser revisada pelo time responsavel",
  "approved_by": "admin@montebravo.com",
  "approved_at": "${approved_at}",
  "review_date": "${review_date}"
}
EOF
}

# =============================================================================
# Cenário 1: Projeto saudável — exit 0, todos PASS
# Requisitos: 6.1, 6.2, 6.7
# =============================================================================

@test "doctor: projeto saudável retorna exit 0 com todos os checks PASS" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Exit code 0
  assert_success

  # Nenhum FAIL
  refute_output --partial "[FAIL]"

  # Verifica que steering files são reportados como atualizados
  assert_output --partial "[PASS]"
  assert_output --partial "Atualizado"
}

# =============================================================================
# Cenário 2: Steering file ausente — FAIL, exit 1
# Requisitos: 6.2, 6.3, 6.7
# =============================================================================

@test "doctor: steering file ausente reporta FAIL e exit 1" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Remover um steering file
  rm -f "${project_dir}/.kiro/steering/security-baseline.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Exit code 1 (tem FAIL)
  assert_failure

  # Reporta FAIL para o arquivo ausente
  assert_output --partial "[FAIL]"
  assert_output --partial "Ausente"
  assert_output --partial "security-baseline.md"
}

# =============================================================================
# Cenário 3: Steering file desatualizado — WARN
# Requisitos: 6.2, 6.4
# =============================================================================

@test "doctor: steering file desatualizado reporta WARN" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Modificar um steering file para ficar desatualizado
  echo "# Conteúdo modificado localmente" >> "${project_dir}/.kiro/steering/engineering-principles.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Pode ser exit 0 (apenas warnings) — verificamos presença do WARN
  assert_output --partial "[WARN]"
  assert_output --partial "Desatualizado"
  assert_output --partial "engineering-principles.md"
}

# =============================================================================
# Cenário 4: --verbose mostra diffs para arquivos desatualizados
# Requisitos: 6.5
# =============================================================================

@test "doctor: --verbose mostra diff para steering file desatualizado" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Modificar conteúdo para gerar diff
  echo "# Linha extra para gerar diff" >> "${project_dir}/.kiro/steering/specs-policy.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --verbose

  # Deve mostrar output com detalhes de diff
  assert_output --partial "Desatualizado"
  assert_output --partial "specs-policy.md"
  # Verbose mostra diferenças (indicação de linhas do diff)
  assert_output --partial "Diferenças"
}

@test "doctor: --verbose lista arquivos ausentes" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Remover steering file
  rm -f "${project_dir}/.kiro/steering/pinned-dependencies.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --verbose

  assert_output --partial "[FAIL]"
  assert_output --partial "pinned-dependencies.md"
}

# =============================================================================
# Cenário 5: --output json produz JSON válido com schema correto
# Requisitos: 6.6
# =============================================================================

@test "doctor: --output json produz JSON válido com schema correto" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  assert_success

  # Output deve ser JSON parseável
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  # Verificar campos obrigatórios do schema
  local timestamp target summary_passed summary_warned summary_failed results_len

  timestamp=$(echo "${output}" | jq -r '.timestamp')
  assert [ "${timestamp}" != "null" ]
  assert [ -n "${timestamp}" ]

  target=$(echo "${output}" | jq -r '.target')
  assert [ "${target}" != "null" ]
  assert [ -n "${target}" ]

  summary_passed=$(echo "${output}" | jq -r '.summary.passed')
  summary_warned=$(echo "${output}" | jq -r '.summary.warned')
  summary_failed=$(echo "${output}" | jq -r '.summary.failed')

  # Todos devem ser inteiros
  assert [ "${summary_passed}" -ge 0 ]
  assert [ "${summary_warned}" -ge 0 ]
  assert [ "${summary_failed}" -ge 0 ]

  # Soma dos contadores deve ser igual ao comprimento de results
  results_len=$(echo "${output}" | jq '.results | length')
  local sum=$(( summary_passed + summary_warned + summary_failed ))
  assert [ "${sum}" -eq "${results_len}" ]

  # Cada result deve ter status, category, message
  local invalid_results
  invalid_results=$(echo "${output}" | jq '[.results[] | select(.status == null or .category == null or .message == null)] | length')
  assert [ "${invalid_results}" -eq 0 ]
}

@test "doctor: --output json com projeto com falhas reporta failed > 0" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Remover steering file para gerar FAIL
  rm -f "${project_dir}/.kiro/steering/documentation-baseline.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  # JSON mode produz output válido (exit code depende da implementação)
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  local failed_count
  failed_count=$(echo "${output}" | jq '.summary.failed')
  assert [ "${failed_count}" -ge 1 ]

  # Verifica que o resultado contém a falha específica
  local has_fail_result
  has_fail_result=$(echo "${output}" | jq '[.results[] | select(.status == "fail")] | length')
  assert [ "${has_fail_result}" -ge 1 ]
}

# =============================================================================
# Cenário 6: Exceção válida cobre arquivo ausente/desatualizado — INFO
# Requisitos: 9.4
# =============================================================================

@test "doctor: exceção válida para steering ausente reporta INFO em vez de FAIL" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Remover steering file
  rm -f "${project_dir}/.kiro/steering/security-baseline.md"

  # Criar exceção válida para o arquivo
  local exception
  exception=$(_gen_valid_exception "baseline.security-baseline")
  _create_manifest "${project_dir}" "[${exception}]"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Não deve ter FAIL para o arquivo coberto pela exceção
  refute_output --regexp '\[FAIL\].*security-baseline'

  # Deve reportar INFO para a exceção
  assert_output --partial "[INFO]"
  assert_output --partial "baseline.security-baseline"
}

@test "doctor: exceção válida para steering desatualizado reporta INFO em vez de WARN" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Modificar steering file
  echo "# Customização local aprovada" >> "${project_dir}/.kiro/steering/engineering-principles.md"

  # Criar exceção válida
  local exception
  exception=$(_gen_valid_exception "baseline.engineering-principles")
  _create_manifest "${project_dir}" "[${exception}]"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Não deve reportar WARN de desatualizado para esse arquivo
  refute_output --regexp '\[WARN\].*[Dd]esatualizado.*engineering-principles'

  # Deve reportar INFO para a exceção
  assert_output --partial "[INFO]"
  assert_output --partial "baseline.engineering-principles"
}

# =============================================================================
# Cenário 7: Exceção expirada — WARN indicando expiração
# Requisitos: 9.5
# =============================================================================

@test "doctor: exceção expirada reporta WARN indicando expiração" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Remover steering file
  rm -f "${project_dir}/.kiro/steering/specs-policy.md"

  # Criar exceção expirada
  local exception
  exception=$(_gen_expired_exception "baseline.specs-policy")
  _create_manifest "${project_dir}" "[${exception}]"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Deve reportar WARN sobre exceção expirada
  assert_output --partial "[WARN]"
  assert_output --regexp '[Ee]xce..o expirada'
  assert_output --partial "baseline.specs-policy"

  # Não deve reportar INFO de exceção válida (exceção expirada não cobre o artefato)
  refute_output --regexp '\[INFO\].*[Ee]xce..o válida.*baseline\.specs-policy'
}

# =============================================================================
# Cenário 8: MCP divergente — WARN quando servidores diferem do baseline
# Requisitos: 6.8
# =============================================================================

@test "doctor: mcp.json divergente do baseline reporta WARN" {
  local project_dir
  project_dir="$(_create_healthy_project)"

  # Sobrescrever mcp.json com servidores diferentes
  cat > "${project_dir}/.kiro/settings/mcp.json" <<EOF
{
  "_comment": "MCP customizado - apenas atlassian",
  "_version": "0.1.0",
  "mcpServers": {
    "atlassian": {
      "_comment": "Atlassian Rovo MCP",
      "url": "https://mcp.atlassian.com/v1/mcp",
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Deve reportar WARN para divergência de mcp
  assert_output --partial "[WARN]"
  assert_output --partial "mcp.json"
  assert_output --partial "difere"
}

# =============================================================================
# Cenário 9: --target ausente ou inválido — exit 1 com mensagem de erro
# Requisitos: 6.9
# =============================================================================

@test "doctor: sem argumento --target retorna exit 1 com mensagem de erro" {
  run bash "${DOCTOR_SCRIPT}"

  assert_failure
  assert_output --partial "--target"
}

@test "doctor: --target com diretório inexistente retorna exit 1" {
  run bash "${DOCTOR_SCRIPT}" --target "/caminho/que/nao/existe/xyzzy"

  assert_failure
  assert_output --partial "não encontrado"
}

# =============================================================================
# Cenário 10: Manifest ausente ou JSON inválido — FAIL
# Requisitos: 6.1
# =============================================================================

@test "doctor: manifest ausente reporta FAIL" {
  local project_dir
  project_dir="$(create_temp_project)"

  # Copiar steering files mas NÃO criar manifest
  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_failure
  assert_output --partial "[FAIL]"
  assert_output --partial "kiro-manifest.json"
}

@test "doctor: manifest com JSON inválido reporta FAIL" {
  local project_dir
  project_dir="$(create_temp_project)"

  # Copiar steering files
  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  # Criar manifest com JSON inválido
  echo "{ invalid json content !!!" > "${project_dir}/kiro-manifest.json"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_failure
  assert_output --partial "[FAIL]"
  assert_output --partial "JSON inválido"
}
