#!/usr/bin/env bats
# =============================================================================
# Property 10: Inputs inválidos resultam em falha
# Feature: baseline-global, Property 10: Inputs inválidos resultam em falha
# =============================================================================
# Para qualquer valor de --project-type que não corresponde a um archetype
# existente, ou para qualquer valor de --component que não é baseline,
# archetype, powers ou all, o script SHALL encerrar com exit code diferente
# de zero.
#
# **Validates: Requirements 4.7, 5.9**
# =============================================================================

# Carrega helpers
load '../helpers/generators'
load '../helpers/setup'
load '../helpers/assertions'

# Caminhos dos scripts sob teste
BOOTSTRAP_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/bootstrap.sh"
SYNC_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/sync.sh"

# Valores válidos que devem ser EVITADOS na geração de inputs inválidos
VALID_PROJECT_TYPES=("backend-nest" "bff-fastify" "frontend-react" "mobile-flutter")
VALID_COMPONENTS=("all" "baseline" "archetype" "powers")

# --- Geradores de inputs inválidos ---

# Gera um valor de --project-type que NÃO é válido
_gen_invalid_project_type() {
  local strategy
  strategy=$(_rand_int 0 6)

  case "$strategy" in
    0) # String aleatória lowercase
      _rand_lower "$(_rand_int 4 15)"
      ;;
    1) # Tipo válido com typo (troca uma letra)
      local base
      base=$(_rand_choice "${VALID_PROJECT_TYPES[@]}")
      local pos=$(( RANDOM % ${#base} ))
      local char=$(_rand_lower 1)
      echo "${base:0:pos}${char}${base:pos+1}"
      ;;
    2) # Tipo válido com prefixo
      local base
      base=$(_rand_choice "${VALID_PROJECT_TYPES[@]}")
      echo "$(_rand_lower "$(_rand_int 1 4)")-${base}"
      ;;
    3) # Tipo válido com sufixo
      local base
      base=$(_rand_choice "${VALID_PROJECT_TYPES[@]}")
      echo "${base}-$(_rand_lower "$(_rand_int 1 4)")"
      ;;
    4) # String com espaços
      echo "$(_rand_lower 4) $(_rand_lower 4)"
      ;;
    5) # String vazia (caso especial)
      echo ""
      ;;
    6) # String alfanumérica com números
      echo "$(_rand_lower 3)$(_rand_int 1 99)$(_rand_lower 3)"
      ;;
  esac
}

# Gera um valor de --component que NÃO é válido
_gen_invalid_component() {
  local strategy
  strategy=$(_rand_int 0 6)

  case "$strategy" in
    0) # String aleatória lowercase
      _rand_lower "$(_rand_int 3 12)"
      ;;
    1) # Componente válido com typo
      local base
      base=$(_rand_choice "${VALID_COMPONENTS[@]}")
      local pos=$(( RANDOM % ${#base} ))
      local char=$(_rand_lower 1)
      echo "${base:0:pos}${char}${base:pos+1}"
      ;;
    2) # Componente válido em UPPERCASE
      local base
      base=$(_rand_choice "${VALID_COMPONENTS[@]}")
      echo "${base}" | tr '[:lower:]' '[:upper:]'
      ;;
    3) # Componente válido com prefixo
      local base
      base=$(_rand_choice "${VALID_COMPONENTS[@]}")
      echo "$(_rand_lower 2)_${base}"
      ;;
    4) # Componente válido com sufixo
      local base
      base=$(_rand_choice "${VALID_COMPONENTS[@]}")
      echo "${base}_$(_rand_lower 2)"
      ;;
    5) # Número como string
      echo "$(_rand_int 1 9999)"
      ;;
    6) # String com caracteres especiais
      echo "$(_rand_lower 3)/$(_rand_lower 3)"
      ;;
  esac
}

# Verifica se o valor gerado NÃO é um dos válidos
_is_truly_invalid_project_type() {
  local value="$1"
  for valid in "${VALID_PROJECT_TYPES[@]}"; do
    [[ "${value}" == "${valid}" ]] && return 1
  done
  return 0
}

_is_truly_invalid_component() {
  local value="$1"
  for valid in "${VALID_COMPONENTS[@]}"; do
    [[ "${value}" == "${valid}" ]] && return 1
  done
  return 0
}

# --- Testes de propriedade ---

# @test "Property 10: bootstrap.sh com --project-type inválido retorna exit code != 0 (100 iterações)"
@test "Property 10a: bootstrap.sh rejeita project-type inválido (100 iterações)" {
  # Feature: baseline-global, Property 10: Inputs inválidos resultam em falha
  # **Validates: Requirements 4.7**

  local target_dir
  target_dir=$(create_temp_project)

  local iterations=100
  local i=0

  while (( i < iterations )); do
    local invalid_type
    invalid_type=$(_gen_invalid_project_type)

    # Garantir que o valor gerado é realmente inválido
    if ! _is_truly_invalid_project_type "${invalid_type}"; then
      continue
    fi

    # Executar bootstrap.sh com tipo inválido
    local exit_code=0
    run bash "${BOOTSTRAP_SCRIPT}" --project-type "${invalid_type}" --target "${target_dir}" 2>/dev/null || true

    # O status deve ser != 0
    if [[ "${status}" -eq 0 ]]; then
      echo "FALHA na iteração $((i+1)): --project-type '${invalid_type}' retornou exit code 0 (deveria falhar)"
      return 1
    fi

    ((i++))
  done

  # Cleanup
  cleanup_fixtures
}

# @test "Property 10: sync.sh com --component inválido retorna exit code != 0 (100 iterações)"
@test "Property 10b: sync.sh rejeita component inválido (100 iterações)" {
  # Feature: baseline-global, Property 10: Inputs inválidos resultam em falha
  # **Validates: Requirements 5.9**

  local target_dir
  target_dir=$(create_temp_project)

  # Criar manifest para que sync.sh não falhe por falta de manifest
  setup_manifest "${target_dir}"
  # Mover manifest para a raiz do projeto (sync espera na raiz, não dentro de .kiro)
  if [[ -f "${target_dir}/.kiro/kiro-manifest.json" ]]; then
    cp "${target_dir}/.kiro/kiro-manifest.json" "${target_dir}/kiro-manifest.json"
  fi

  local iterations=100
  local i=0

  while (( i < iterations )); do
    local invalid_component
    invalid_component=$(_gen_invalid_component)

    # Garantir que o valor gerado é realmente inválido
    if ! _is_truly_invalid_component "${invalid_component}"; then
      continue
    fi

    # Executar sync.sh com componente inválido
    run bash "${SYNC_SCRIPT}" --target "${target_dir}" --component "${invalid_component}" 2>/dev/null || true

    # O status deve ser != 0
    if [[ "${status}" -eq 0 ]]; then
      echo "FALHA na iteração $((i+1)): --component '${invalid_component}' retornou exit code 0 (deveria falhar)"
      return 1
    fi

    ((i++))
  done

  # Cleanup
  cleanup_fixtures
}
