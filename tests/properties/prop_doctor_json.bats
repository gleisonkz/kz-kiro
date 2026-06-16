#!/usr/bin/env bats
# =============================================================================
# Property 8: Doctor produz JSON válido com schema correto
# Feature: baseline-global, Property 8: Doctor produz JSON válido com schema correto
# =============================================================================
# Para qualquer estado de verificação (combinação de PASS, WARN, FAIL), quando
# --output json é informado, o doctor SHALL produzir JSON parseável contendo os
# campos timestamp (ISO 8601), target (string), summary (objeto com passed,
# warned, failed como inteiros cuja soma é igual ao comprimento de results), e
# results (array de objetos com status, category, message).
#
# **Validates: Requirements 6.6**
# =============================================================================

# Carrega helpers
load '../helpers/generators'
load '../helpers/setup'
load '../helpers/assertions'

# Caminho para o script doctor.sh
DOCTOR_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"

# --- Funções auxiliares para geração de cenários ---

# Lista de steering files no baseline (excluindo README.md)
BASELINE_STEERING_FILES=(
  "engineering-principles.md"
  "security-baseline.md"
  "specs-policy.md"
  "documentation-baseline.md"
  "pinned-dependencies.md"
)

# Gera um estado de projeto aleatório com combinação de artefatos em diferentes estados.
# Parâmetros:
#   $1 = caminho do projeto (já criado via create_temp_project)
# Cada steering file recebe aleatoriamente um dos estados:
#   0 = idêntico ao baseline (gera PASS)
#   1 = diferente do baseline (gera WARN)
#   2 = ausente (gera FAIL)
_setup_random_verification_state() {
  local project_dir="$1"
  local real_baseline="${BATS_TEST_DIRNAME}/../../baselines/global/steering"

  for fname in "${BASELINE_STEERING_FILES[@]}"; do
    local state
    state=$(_rand_int 0 2)

    case "${state}" in
      0)
        # Idêntico: copiar do baseline
        cp "${real_baseline}/${fname}" "${project_dir}/.kiro/steering/${fname}"
        ;;
      1)
        # Diferente: criar com conteúdo modificado
        cat > "${project_dir}/.kiro/steering/${fname}" <<EOF
---
inclusion: auto
---
# Conteúdo modificado para teste
Texto alterado: $(_rand_alphanum 30)
EOF
        ;;
      2)
        # Ausente: não copiar (arquivo não existe no projeto)
        ;;
    esac
  done
}

# --- Teste de propriedade ---

@test "Property 8: Doctor produz JSON válido com schema correto (100 iterações)" {
  # **Validates: Requirements 6.6**
  local iterations=100
  local i

  for (( i = 0; i < iterations; i++ )); do
    local project_dir json_output exit_code=0

    project_dir="$(create_temp_project)"

    # Criar manifest válido
    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    cat > "${project_dir}/kiro-manifest.json" <<EOF
{
  "_generated_by": "test-prop-json",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test-${i}", "repository": "org/test-${i}" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "frontend-react", "version": "0.1.0", "installed_at": "${now}" },
  "powers": [],
  "exceptions": []
}
EOF

    # Configurar estado aleatório dos artefatos
    _setup_random_verification_state "${project_dir}"

    # Executar doctor com --output json
    json_output=$(bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json 2>/dev/null) || exit_code=$?

    # 1. Verificar que a saída é JSON parseável
    if ! echo "${json_output}" | jq '.' > /dev/null 2>&1; then
      echo "# Iteração ${i}: saída não é JSON válido" >&2
      echo "# Output (primeiros 500 chars): ${json_output:0:500}" >&2
      rm -rf "${project_dir}"
      false
    fi

    # 2. Verificar campo timestamp (ISO 8601 UTC)
    local timestamp
    timestamp=$(echo "${json_output}" | jq -r '.timestamp')
    if [[ "${timestamp}" == "null" || -z "${timestamp}" ]]; then
      echo "# Iteração ${i}: campo 'timestamp' ausente ou null" >&2
      rm -rf "${project_dir}"
      false
    fi
    # Validar formato ISO 8601: YYYY-MM-DDTHH:MM:SSZ
    if [[ ! "${timestamp}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
      echo "# Iteração ${i}: timestamp não está em formato ISO 8601 UTC" >&2
      echo "# timestamp: ${timestamp}" >&2
      rm -rf "${project_dir}"
      false
    fi

    # 3. Verificar campo target (string, caminho absoluto)
    local target
    target=$(echo "${json_output}" | jq -r '.target')
    if [[ "${target}" == "null" || -z "${target}" ]]; then
      echo "# Iteração ${i}: campo 'target' ausente ou null" >&2
      rm -rf "${project_dir}"
      false
    fi
    # Target deve ser caminho absoluto (começar com /)
    if [[ "${target}" != /* ]]; then
      echo "# Iteração ${i}: campo 'target' não é caminho absoluto" >&2
      echo "# target: ${target}" >&2
      rm -rf "${project_dir}"
      false
    fi

    # 4. Verificar campo summary (objeto com passed, warned, failed como inteiros)
    local summary_type
    summary_type=$(echo "${json_output}" | jq -r '.summary | type')
    if [[ "${summary_type}" != "object" ]]; then
      echo "# Iteração ${i}: campo 'summary' não é objeto (type: ${summary_type})" >&2
      rm -rf "${project_dir}"
      false
    fi

    local passed warned failed
    passed=$(echo "${json_output}" | jq '.summary.passed')
    warned=$(echo "${json_output}" | jq '.summary.warned')
    failed=$(echo "${json_output}" | jq '.summary.failed')

    # Verificar que são inteiros (não null, não string)
    if [[ "${passed}" == "null" ]] || ! [[ "${passed}" =~ ^[0-9]+$ ]]; then
      echo "# Iteração ${i}: summary.passed não é inteiro válido (${passed})" >&2
      rm -rf "${project_dir}"
      false
    fi
    if [[ "${warned}" == "null" ]] || ! [[ "${warned}" =~ ^[0-9]+$ ]]; then
      echo "# Iteração ${i}: summary.warned não é inteiro válido (${warned})" >&2
      rm -rf "${project_dir}"
      false
    fi
    if [[ "${failed}" == "null" ]] || ! [[ "${failed}" =~ ^[0-9]+$ ]]; then
      echo "# Iteração ${i}: summary.failed não é inteiro válido (${failed})" >&2
      rm -rf "${project_dir}"
      false
    fi

    # 5. Verificar campo results (array)
    local results_type results_length
    results_type=$(echo "${json_output}" | jq -r '.results | type')
    if [[ "${results_type}" != "array" ]]; then
      echo "# Iteração ${i}: campo 'results' não é array (type: ${results_type})" >&2
      rm -rf "${project_dir}"
      false
    fi

    results_length=$(echo "${json_output}" | jq '.results | length')

    # 6. Verificar que soma de summary == comprimento de results
    local summary_sum=$(( passed + warned + failed ))
    if [[ ${summary_sum} -ne ${results_length} ]]; then
      echo "# Iteração ${i}: soma do summary (${summary_sum}) != length de results (${results_length})" >&2
      echo "# passed=${passed}, warned=${warned}, failed=${failed}" >&2
      rm -rf "${project_dir}"
      false
    fi

    # 7. Verificar que cada elemento de results tem status, category, message
    local invalid_result
    invalid_result=$(echo "${json_output}" | jq -r '
      .results | to_entries[] |
      select(
        (.value.status == null) or
        (.value.category == null) or
        (.value.message == null) or
        (.value.status | type) != "string" or
        (.value.category | type) != "string" or
        (.value.message | type) != "string"
      ) | .key
    ')

    if [[ -n "${invalid_result}" ]]; then
      echo "# Iteração ${i}: resultado(s) com campos ausentes ou inválidos nos índices: ${invalid_result}" >&2
      echo "# Resultados completos:" >&2
      echo "${json_output}" | jq '.results' >&2
      rm -rf "${project_dir}"
      false
    fi

    # 8. Verificar que os status nos results são consistentes com o summary
    local count_pass count_warn count_fail
    count_pass=$(echo "${json_output}" | jq '[.results[] | select(.status == "pass")] | length')
    count_warn=$(echo "${json_output}" | jq '[.results[] | select(.status == "warn")] | length')
    count_fail=$(echo "${json_output}" | jq '[.results[] | select(.status == "fail")] | length')

    if [[ ${count_pass} -ne ${passed} ]]; then
      echo "# Iteração ${i}: contagem pass nos results (${count_pass}) != summary.passed (${passed})" >&2
      rm -rf "${project_dir}"
      false
    fi
    if [[ ${count_warn} -ne ${warned} ]]; then
      echo "# Iteração ${i}: contagem warn nos results (${count_warn}) != summary.warned (${warned})" >&2
      rm -rf "${project_dir}"
      false
    fi
    if [[ ${count_fail} -ne ${failed} ]]; then
      echo "# Iteração ${i}: contagem fail nos results (${count_fail}) != summary.failed (${failed})" >&2
      rm -rf "${project_dir}"
      false
    fi

    # 9. Verificar que category é um dos valores esperados
    local invalid_category
    invalid_category=$(echo "${json_output}" | jq -r '
      .results[] |
      select(.category | IN("manifest", "baseline", "archetype", "powers", "health") | not) |
      .category
    ')

    if [[ -n "${invalid_category}" ]]; then
      echo "# Iteração ${i}: category inválida encontrada: ${invalid_category}" >&2
      rm -rf "${project_dir}"
      false
    fi

    rm -rf "${project_dir}"
  done
}
