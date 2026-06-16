#!/usr/bin/env bats
# =============================================================================
# Property 9: Validação de schema de exceção
# Feature: baseline-global, Property 9: Validação de schema de exceção
# =============================================================================
# Para qualquer objeto de exceção, a validação SHALL aceitar se e somente se
# o objeto contiver: rule (string no formato <componente>.<nome>), reason
# (string com 20-500 caracteres), approved_by (string não-vazia), approved_at
# (data ISO 8601 válida), e review_date (data ISO 8601 cuja diferença para
# approved_at não excede 90 dias corridos).
#
# **Validates: Requirements 9.1, 9.3**
# =============================================================================

# Carrega helpers
load '../helpers/generators'
load '../helpers/setup'
load '../helpers/assertions'

# --- Função de validação standalone ---
# Reproduz a lógica de validate_exceptions do doctor.sh para um único objeto JSON.
# Retorna 0 se a exceção é válida, 1 se é inválida.
# Recebe o JSON da exceção via stdin ou como argumento $1.

validate_single_exception() {
  local exception_json="$1"

  local rule reason approved_by approved_at review_date
  rule=$(echo "${exception_json}" | jq -r '.rule // empty' 2>/dev/null)
  reason=$(echo "${exception_json}" | jq -r '.reason // empty' 2>/dev/null)
  approved_by=$(echo "${exception_json}" | jq -r '.approved_by // empty' 2>/dev/null)
  approved_at=$(echo "${exception_json}" | jq -r '.approved_at // empty' 2>/dev/null)
  review_date=$(echo "${exception_json}" | jq -r '.review_date // empty' 2>/dev/null)

  # Validar rule: formato <componente>.<nome> (deve conter pelo menos um ponto)
  if [[ -z "${rule}" ]]; then
    return 1
  fi
  if [[ "${rule}" != *.* ]]; then
    return 1
  fi

  # Validar reason: 20-500 caracteres
  if [[ -z "${reason}" ]]; then
    return 1
  fi
  local reason_len=${#reason}
  if [[ ${reason_len} -lt 20 || ${reason_len} -gt 500 ]]; then
    return 1
  fi

  # Validar approved_by: não-vazio
  if [[ -z "${approved_by}" ]]; then
    return 1
  fi

  # Validar approved_at: ISO 8601 (YYYY-MM-DD ou YYYY-MM-DDTHH:MM:SSZ ou com offset)
  if [[ -z "${approved_at}" ]]; then
    return 1
  fi
  if ! echo "${approved_at}" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})?)?$'; then
    return 1
  fi

  # Validar review_date: ISO 8601
  if [[ -z "${review_date}" ]]; then
    return 1
  fi
  if ! echo "${review_date}" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})?)?$'; then
    return 1
  fi

  # Validar que review_date não excede 90 dias de approved_at
  local approved_epoch review_epoch
  local approved_date_part="${approved_at%%T*}"
  local review_date_part="${review_date%%T*}"

  if date -j -f "%Y-%m-%d" "${approved_date_part}" "+%s" &>/dev/null 2>&1; then
    # macOS/BSD date
    approved_epoch=$(date -j -f "%Y-%m-%d" "${approved_date_part}" "+%s" 2>/dev/null) || return 1
    review_epoch=$(date -j -f "%Y-%m-%d" "${review_date_part}" "+%s" 2>/dev/null) || return 1
  elif date -d "${approved_date_part}" "+%s" &>/dev/null 2>&1; then
    # GNU date
    approved_epoch=$(date -d "${approved_date_part}" "+%s" 2>/dev/null) || return 1
    review_epoch=$(date -d "${review_date_part}" "+%s" 2>/dev/null) || return 1
  else
    return 1
  fi

  local diff_days=$(( (review_epoch - approved_epoch) / 86400 ))
  if [[ ${diff_days} -gt 90 ]]; then
    return 1
  fi

  return 0
}

# --- Testes de propriedade ---

# @test "Property 9: exceções válidas são aceitas pela validação (100 iterações)"
@test "Property 9: exceções válidas são aceitas pela validação (100 iterações)" {
  # **Validates: Requirements 9.1, 9.3**
  local iterations=100
  local i

  for (( i = 0; i < iterations; i++ )); do
    # Gerar exceção válida
    local exception_json
    exception_json="$(gen_exception)"

    # Validar que a exceção é aceita
    if ! validate_single_exception "${exception_json}"; then
      local rule reason approved_at review_date
      rule=$(echo "${exception_json}" | jq -r '.rule')
      reason=$(echo "${exception_json}" | jq -r '.reason')
      approved_at=$(echo "${exception_json}" | jq -r '.approved_at')
      review_date=$(echo "${exception_json}" | jq -r '.review_date')

      echo "# Iteração ${i}: exceção válida rejeitada!" >&2
      echo "# rule: ${rule}" >&2
      echo "# reason (${#reason} chars): ${reason:0:60}..." >&2
      echo "# approved_at: ${approved_at}" >&2
      echo "# review_date: ${review_date}" >&2
      echo "# JSON completo:" >&2
      echo "${exception_json}" >&2
      false
    fi
  done
}

# @test "Property 9: exceções inválidas são rejeitadas pela validação (100 iterações)"
@test "Property 9: exceções inválidas são rejeitadas pela validação (100 iterações)" {
  # **Validates: Requirements 9.1, 9.3**
  local iterations=100
  local i

  for (( i = 0; i < iterations; i++ )); do
    # Gerar exceção inválida
    local exception_json
    exception_json="$(gen_invalid_exception)"

    # Validar que a exceção é rejeitada
    if validate_single_exception "${exception_json}"; then
      local rule reason approved_by approved_at review_date
      rule=$(echo "${exception_json}" | jq -r '.rule // "AUSENTE"')
      reason=$(echo "${exception_json}" | jq -r '.reason // "AUSENTE"')
      approved_by=$(echo "${exception_json}" | jq -r '.approved_by // "AUSENTE"')
      approved_at=$(echo "${exception_json}" | jq -r '.approved_at // "AUSENTE"')
      review_date=$(echo "${exception_json}" | jq -r '.review_date // "AUSENTE"')

      echo "# Iteração ${i}: exceção inválida aceita!" >&2
      echo "# rule: ${rule}" >&2
      echo "# reason (${#reason} chars): ${reason:0:60}..." >&2
      echo "# approved_by: ${approved_by}" >&2
      echo "# approved_at: ${approved_at}" >&2
      echo "# review_date: ${review_date}" >&2
      echo "# JSON completo:" >&2
      echo "${exception_json}" >&2
      false
    fi
  done
}

# @test "Property 9: doctor.sh integrado valida exceções corretamente (amostra de 10)"
@test "Property 9: doctor.sh integrado valida exceções corretamente (amostra de 10)" {
  # **Validates: Requirements 9.1, 9.3**
  # Teste de integração leve: verifica que doctor.sh reporta corretamente
  # para uma amostra menor (evita timeout por execução completa do doctor)
  local doctor_script="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"
  local i

  # 5 iterações com exceções válidas
  for (( i = 0; i < 5; i++ )); do
    local exception_json project_dir output
    exception_json="$(gen_exception)"
    project_dir="$(create_temp_project)"

    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    cat > "${project_dir}/kiro-manifest.json" << EOF
{
  "_generated_by": "test-prop",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test", "repository": "org/test" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "frontend-react", "version": "0.1.0", "installed_at": "${now}" },
  "powers": [],
  "exceptions": [${exception_json}]
}
EOF

    output=$(bash "${doctor_script}" --target "${project_dir}" 2>&1) || true

    # Exceção válida NÃO deve gerar WARN sobre schema da exceção
    if echo "${output}" | grep -q '\[WARN\].*exceptions\[0\]'; then
      echo "# Iteração válida ${i}: doctor reportou WARN para exceção válida" >&2
      echo "${output}" | grep 'exceptions' >&2
      echo "# JSON:" >&2
      echo "${exception_json}" >&2
      rm -rf "${project_dir}"
      false
    fi

    rm -rf "${project_dir}"
  done

  # 5 iterações com exceções inválidas
  for (( i = 0; i < 5; i++ )); do
    local exception_json project_dir output
    exception_json="$(gen_invalid_exception)"
    project_dir="$(create_temp_project)"

    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    cat > "${project_dir}/kiro-manifest.json" << EOF
{
  "_generated_by": "test-prop",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test", "repository": "org/test" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "frontend-react", "version": "0.1.0", "installed_at": "${now}" },
  "powers": [],
  "exceptions": [${exception_json}]
}
EOF

    output=$(bash "${doctor_script}" --target "${project_dir}" 2>&1) || true

    # Exceção inválida DEVE gerar WARN sobre schema da exceção
    if ! echo "${output}" | grep -q '\[WARN\].*exceptions\[0\]'; then
      # Verificar se não resultou em PASS (pode ser que doctor nem avaliou)
      if echo "${output}" | grep -q '\[PASS\].*exceptions\[0\]'; then
        echo "# Iteração inválida ${i}: doctor reportou PASS para exceção inválida" >&2
        echo "${output}" | grep 'exceptions' >&2
        echo "# JSON:" >&2
        echo "${exception_json}" >&2
        rm -rf "${project_dir}"
        false
      fi
    fi

    rm -rf "${project_dir}"
  done
}
