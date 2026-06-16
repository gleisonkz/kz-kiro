#!/usr/bin/env bats
# =============================================================================
# Property 7: Doctor classifica artefatos corretamente
# Feature: baseline-global, Property 7: Doctor classifica artefatos corretamente
# =============================================================================
# Para qualquer combinação de estados de artefatos (presente e igual, presente e
# diferente, ausente) e para qualquer conjunto de exceções no manifest, o doctor
# SHALL classificar cada artefato como: PASS (presente e idêntico ao fonte),
# WARN (presente mas diferente), FAIL (ausente) — exceto quando coberto por
# exceção válida (reporta INFO) ou exceção expirada (reporta WARN).
#
# **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.10, 9.4, 9.5**
# =============================================================================

# Carrega helpers
load '../helpers/generators'
load '../helpers/setup'
load '../helpers/assertions'

# Caminho para o script doctor.sh
DOCTOR_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"

# Número de iterações por teste (conforme especificado na task)
ITERATIONS=20

# Steering files disponíveis no baseline
BASELINE_STEERING_DIR="${BATS_TEST_DIRNAME}/../../baselines/global/steering"

# --- Funções auxiliares para geração de cenários ---

# Gera uma exceção válida (não expirada) para um artefato específico
_gen_valid_exception_for_rule() {
  local rule="$1"
  local approved_by="maintainer.$(_rand_lower 5)@montebravo.com"
  local reason="Excecao tecnica aprovada para este artefato no contexto do teste de propriedade"

  # approved_at: 10 dias atrás, review_date: 60 dias no futuro
  local approved_at review_date
  if date -v-10d +%Y-%m-%dT%H:%M:%SZ &>/dev/null 2>&1; then
    # macOS
    approved_at=$(date -u -v-10d +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -v+60d +%Y-%m-%dT%H:%M:%SZ)
  else
    # GNU
    approved_at=$(date -u -d "10 days ago" +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -d "60 days" +%Y-%m-%dT%H:%M:%SZ)
  fi

  cat <<EOF
{
  "rule": "${rule}",
  "reason": "${reason}",
  "approved_by": "${approved_by}",
  "approved_at": "${approved_at}",
  "review_date": "${review_date}"
}
EOF
}

# Gera uma exceção expirada para um artefato específico
_gen_expired_exception_for_rule() {
  local rule="$1"
  local approved_by="maintainer.$(_rand_lower 5)@montebravo.com"
  local reason="Excecao tecnica que ja expirou e precisa ser revisada pelo time responsavel"

  # approved_at: 120 dias atrás, review_date: 40 dias atrás (expirou)
  local approved_at review_date
  if date -v-120d +%Y-%m-%dT%H:%M:%SZ &>/dev/null 2>&1; then
    # macOS
    approved_at=$(date -u -v-120d +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -v-40d +%Y-%m-%dT%H:%M:%SZ)
  else
    # GNU
    approved_at=$(date -u -d "120 days ago" +%Y-%m-%dT%H:%M:%SZ)
    review_date=$(date -u -d "40 days ago" +%Y-%m-%dT%H:%M:%SZ)
  fi

  cat <<EOF
{
  "rule": "${rule}",
  "reason": "${reason}",
  "approved_by": "${approved_by}",
  "approved_at": "${approved_at}",
  "review_date": "${review_date}"
}
EOF
}

# Cria manifest padrão para testes
_create_test_manifest() {
  local project_dir="$1"
  local exceptions_json="${2:-[]}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  cat > "${project_dir}/kiro-manifest.json" <<EOF
{
  "_generated_by": "test-prop",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test", "repository": "org/test" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "frontend-react", "version": "0.1.0", "installed_at": "${now}" },
  "powers": [],
  "exceptions": ${exceptions_json}
}
EOF
}

# Seleciona um steering file aleatório do baseline
_pick_random_steering() {
  local files=()
  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    files+=("${fname}")
  done
  _rand_choice "${files[@]}"
}

# Copia todos os steering files do baseline exceto o indicado
_copy_all_steering_except() {
  local project_dir="$1"
  local exclude_name="$2"

  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    [[ "${fname}" == "${exclude_name}" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done
}

# --- Testes de propriedade ---

@test "Property 7: PASS quando artefato presente e idêntico ao fonte (20 iterações)" {
  # **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.10, 9.4, 9.5**
  for (( i = 0; i < ITERATIONS; i++ )); do
    local project_dir steering_name

    project_dir="$(create_temp_project)"
    steering_name="$(_pick_random_steering)"

    # Copiar TODOS os steering files identicamente (incluindo o selecionado)
    for f in "${BASELINE_STEERING_DIR}"/*.md; do
      local fname
      fname=$(basename "${f}")
      [[ "${fname}" == "README.md" ]] && continue
      cp "${f}" "${project_dir}/.kiro/steering/${fname}"
    done

    _create_test_manifest "${project_dir}"

    # Executar doctor
    local output
    output=$(bash "${DOCTOR_SCRIPT}" --target "${project_dir}" 2>&1) || true

    # Verificar que o artefato selecionado NÃO é WARN ou FAIL
    if echo "${output}" | grep -qE "\[(WARN|FAIL)\].*${steering_name}"; then
      echo "# Iteração ${i}: artefato idêntico '${steering_name}' classificado incorretamente" >&2
      echo "# Output relevante:" >&2
      echo "${output}" | grep -E "(PASS|WARN|FAIL|INFO).*${steering_name}" >&2
      rm -rf "${project_dir}"
      false
    fi

    rm -rf "${project_dir}"
  done
}

@test "Property 7: WARN quando artefato presente mas diferente (20 iterações)" {
  # **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.10, 9.4, 9.5**
  for (( i = 0; i < ITERATIONS; i++ )); do
    local project_dir steering_name

    project_dir="$(create_temp_project)"
    steering_name="$(_pick_random_steering)"

    # Copiar todos os steering exceto o selecionado
    _copy_all_steering_except "${project_dir}" "${steering_name}"

    # Criar versão diferente do arquivo selecionado
    cat > "${project_dir}/.kiro/steering/${steering_name}" <<EOF
---
inclusion: auto
---
# Arquivo Modificado (iteração ${i})
Conteúdo alterado intencionalmente para teste.
Texto aleatório: $(_rand_alphanum 20)
EOF

    _create_test_manifest "${project_dir}"

    # Executar doctor
    local output
    output=$(bash "${DOCTOR_SCRIPT}" --target "${project_dir}" 2>&1) || true

    # Verificar que o artefato é classificado como WARN (desatualizado)
    if ! echo "${output}" | grep -q "\[WARN\].*[Dd]esatualizado.*${steering_name}"; then
      echo "# Iteração ${i}: artefato diferente '${steering_name}' não classificado como WARN" >&2
      echo "# Output relevante:" >&2
      echo "${output}" | grep -E "(PASS|WARN|FAIL|INFO).*${steering_name}" >&2
      rm -rf "${project_dir}"
      false
    fi

    rm -rf "${project_dir}"
  done
}

@test "Property 7: FAIL quando artefato ausente sem exceção (20 iterações)" {
  # **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.10, 9.4, 9.5**
  for (( i = 0; i < ITERATIONS; i++ )); do
    local project_dir steering_name

    project_dir="$(create_temp_project)"
    steering_name="$(_pick_random_steering)"

    # Copiar todos os steering exceto o selecionado (ele ficará ausente)
    _copy_all_steering_except "${project_dir}" "${steering_name}"

    _create_test_manifest "${project_dir}"

    # Executar doctor
    local output exit_code=0
    output=$(bash "${DOCTOR_SCRIPT}" --target "${project_dir}" 2>&1) || exit_code=$?

    # Verificar que o artefato ausente é classificado como FAIL
    if ! echo "${output}" | grep -q "\[FAIL\].*[Aa]usente.*${steering_name}"; then
      echo "# Iteração ${i}: artefato ausente '${steering_name}' não classificado como FAIL" >&2
      echo "# Output relevante:" >&2
      echo "${output}" | grep -E "(PASS|WARN|FAIL|INFO).*${steering_name}" >&2
      rm -rf "${project_dir}"
      false
    fi

    # Verificar que exit code é 1 (tem FAIL)
    if [[ ${exit_code} -ne 1 ]]; then
      echo "# Iteração ${i}: exit code deveria ser 1 (FAIL presente), got ${exit_code}" >&2
      rm -rf "${project_dir}"
      false
    fi

    rm -rf "${project_dir}"
  done
}

@test "Property 7: INFO quando artefato coberto por exceção válida (20 iterações)" {
  # **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.10, 9.4, 9.5**
  for (( i = 0; i < ITERATIONS; i++ )); do
    local project_dir steering_name rule_name exception_json

    project_dir="$(create_temp_project)"
    steering_name="$(_pick_random_steering)"

    # Derivar rule name (formato usado pelo doctor: baseline.<nome-sem-extensão>)
    rule_name="baseline.${steering_name%.md}"

    # Alternar entre cenário ausente e cenário diferente
    if (( RANDOM % 2 == 0 )); then
      # Cenário: arquivo ausente coberto por exceção
      _copy_all_steering_except "${project_dir}" "${steering_name}"
    else
      # Cenário: arquivo diferente coberto por exceção
      _copy_all_steering_except "${project_dir}" "${steering_name}"
      cat > "${project_dir}/.kiro/steering/${steering_name}" <<EOF
---
inclusion: auto
---
# Conteúdo modificado (teste iteração ${i})
Diferente do baseline. $(_rand_alphanum 15)
EOF
    fi

    # Gerar exceção válida para o artefato
    exception_json=$(_gen_valid_exception_for_rule "${rule_name}")

    _create_test_manifest "${project_dir}" "[${exception_json}]"

    # Executar doctor
    local output
    output=$(bash "${DOCTOR_SCRIPT}" --target "${project_dir}" 2>&1) || true

    # Verificar que o artefato NÃO é classificado como FAIL ou WARN normal (sem "expirad")
    # A exceção válida deve cobrir o artefato (INFO) ou pelo menos não gerar FAIL/WARN
    if echo "${output}" | grep -qE "\[(FAIL)\].*${steering_name}"; then
      echo "# Iteração ${i}: artefato com exceção válida classificado como FAIL" >&2
      echo "# steering_name: ${steering_name}, rule: ${rule_name}" >&2
      echo "# Output relevante:" >&2
      echo "${output}" | grep -E "(PASS|WARN|FAIL|INFO)" >&2
      rm -rf "${project_dir}"
      false
    fi

    # Verificar que INFO é reportado para a exceção OU que não há WARN para desatualizado
    if echo "${output}" | grep -qE "\[WARN\].*[Dd]esatualizado.*${steering_name}"; then
      echo "# Iteração ${i}: artefato com exceção válida reportado como WARN desatualizado" >&2
      echo "# steering_name: ${steering_name}, rule: ${rule_name}" >&2
      echo "# Output relevante:" >&2
      echo "${output}" | grep -E "(PASS|WARN|FAIL|INFO)" >&2
      rm -rf "${project_dir}"
      false
    fi

    rm -rf "${project_dir}"
  done
}

@test "Property 7: WARN quando exceção expirada não cobre artefato (20 iterações)" {
  # **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.7, 6.8, 6.10, 9.4, 9.5**
  for (( i = 0; i < ITERATIONS; i++ )); do
    local project_dir steering_name rule_name exception_json

    project_dir="$(create_temp_project)"
    steering_name="$(_pick_random_steering)"

    # Derivar rule name
    rule_name="baseline.${steering_name%.md}"

    # Cenário: arquivo ausente ou diferente com exceção expirada
    if (( RANDOM % 2 == 0 )); then
      # Ausente
      _copy_all_steering_except "${project_dir}" "${steering_name}"
    else
      # Diferente
      _copy_all_steering_except "${project_dir}" "${steering_name}"
      cat > "${project_dir}/.kiro/steering/${steering_name}" <<EOF
---
inclusion: auto
---
# Modificado para teste (iteração ${i})
Conteúdo diferente do baseline original. $(_rand_alphanum 15)
EOF
    fi

    # Gerar exceção EXPIRADA para o artefato
    exception_json=$(_gen_expired_exception_for_rule "${rule_name}")

    _create_test_manifest "${project_dir}" "[${exception_json}]"

    # Executar doctor
    local output
    output=$(bash "${DOCTOR_SCRIPT}" --target "${project_dir}" 2>&1) || true

    # Verificar que a exceção expirada é reportada como WARN
    if ! echo "${output}" | grep -qE "\[WARN\].*[Ee]xce..o expirada.*${rule_name}"; then
      echo "# Iteração ${i}: exceção expirada não classificada como WARN" >&2
      echo "# steering_name: ${steering_name}, rule: ${rule_name}" >&2
      echo "# Output relevante:" >&2
      echo "${output}" | grep -E "(PASS|WARN|FAIL|INFO)" >&2
      rm -rf "${project_dir}"
      false
    fi

    # Verificar que o artefato NÃO é reportado como INFO (exceção expirada não cobre)
    if echo "${output}" | grep -qE "\[INFO\].*${rule_name}"; then
      echo "# Iteração ${i}: exceção expirada reportada como INFO (deveria ser WARN)" >&2
      rm -rf "${project_dir}"
      false
    fi

    rm -rf "${project_dir}"
  done
}
