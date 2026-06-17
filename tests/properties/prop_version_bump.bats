#!/usr/bin/env bats
# =============================================================================
# Property 7: Precedência de version bump
# Feature: archetype-bff-fastify, Property 7: Precedência de version bump
# =============================================================================
# Para qualquer conjunto de mudanças em uma release que se enquadram em múltiplas
# categorias de incremento, a função de cálculo de bump SHALL retornar apenas o
# incremento de maior precedência (MAJOR > MINOR > PATCH).
#
# **Validates: Requirements 10.3, 10.4, 10.5, 10.6**
# Mínimo 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
  load '../helpers/assertions'
  load '../lib/bats-assert/load'
  load '../lib/bats-support/load'
}

teardown() {
  cleanup_fixtures
}

# --- Categorias de mudanças e seus bumps correspondentes ---
# Conforme Requisitos 10.3, 10.4, 10.5, 10.6:
# MAJOR: steering file removido, steering file renomeado, hook removido (Req 10.4)
# MINOR: novo steering file adicionado, nova skill, nova diretriz em steering existente (Req 10.3)
# PATCH: correção de texto, refinamento de prompt, ajuste de valor em MCP (Req 10.5)
# Precedência: MAJOR > MINOR > PATCH quando múltiplas categorias na mesma release (Req 10.6)

# --- Função de cálculo de bump ---
# Recebe uma lista de categorias de mudanças (MAJOR, MINOR, PATCH) separadas por espaço.
# Retorna o bump de maior precedência.
calculate_bump() {
  local changes=("$@")
  local has_major=0
  local has_minor=0
  local has_patch=0

  for change in "${changes[@]}"; do
    case "${change}" in
      MAJOR) has_major=1 ;;
      MINOR) has_minor=1 ;;
      PATCH) has_patch=1 ;;
    esac
  done

  if [[ ${has_major} -eq 1 ]]; then
    echo "MAJOR"
  elif [[ ${has_minor} -eq 1 ]]; then
    echo "MINOR"
  elif [[ ${has_patch} -eq 1 ]]; then
    echo "PATCH"
  else
    echo "NONE"
  fi
}

# --- Gerador de conjunto de mudanças categorizadas ---
# Gera um conjunto aleatório de mudanças com 1 a 6 entradas, cada uma categorizada
# como MAJOR, MINOR ou PATCH. Garante que ao menos 2 categorias diferentes estejam presentes.
gen_mixed_changes() {
  local num_changes
  num_changes=$(_rand_int 2 6)

  local categories=("MAJOR" "MINOR" "PATCH")
  local changes=()

  # Garante ao menos 2 categorias distintas
  local cat1 cat2
  cat1="${categories[$(_rand_int 0 2)]}"
  cat2="${categories[$(_rand_int 0 2)]}"
  while [[ "${cat2}" == "${cat1}" ]]; do
    cat2="${categories[$(_rand_int 0 2)]}"
  done
  changes+=("${cat1}" "${cat2}")

  # Preenche as mudanças restantes com categorias aleatórias
  local i
  for (( i = 2; i < num_changes; i++ )); do
    changes+=("${categories[$(_rand_int 0 2)]}")
  done

  echo "${changes[*]}"
}

# --- Gerador de conjunto com MAJOR garantido ---
gen_changes_with_major() {
  local num_changes
  num_changes=$(_rand_int 2 6)
  local changes=("MAJOR")

  local categories=("MAJOR" "MINOR" "PATCH")
  local i
  for (( i = 1; i < num_changes; i++ )); do
    changes+=("${categories[$(_rand_int 0 2)]}")
  done

  echo "${changes[*]}"
}

# --- Gerador de conjunto com MINOR (sem MAJOR) ---
gen_changes_minor_max() {
  local num_changes
  num_changes=$(_rand_int 2 5)
  local changes=("MINOR")

  local categories=("MINOR" "PATCH")
  local i
  for (( i = 1; i < num_changes; i++ )); do
    changes+=("${categories[$(_rand_int 0 1)]}")
  done

  echo "${changes[*]}"
}

# --- Gerador de conjunto somente PATCH ---
gen_changes_patch_only() {
  local num_changes
  num_changes=$(_rand_int 1 5)
  local changes=()

  local i
  for (( i = 0; i < num_changes; i++ )); do
    changes+=("PATCH")
  done

  echo "${changes[*]}"
}

# --- Determina o bump esperado analisando diretamente as categorias ---
expected_bump() {
  local changes_str="$1"
  if [[ "${changes_str}" == *"MAJOR"* ]]; then
    echo "MAJOR"
  elif [[ "${changes_str}" == *"MINOR"* ]]; then
    echo "MINOR"
  else
    echo "PATCH"
  fi
}

# =============================================================================
# Property Test 7a: Conjuntos mistos sempre retornam o bump de maior precedência (100 iterações)
# =============================================================================
@test "Property 7a: bump resultante é sempre o de maior precedência em conjuntos mistos (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local changes_str
    changes_str="$(gen_mixed_changes)"

    # Converte string para array
    local -a changes
    IFS=' ' read -r -a changes <<< "${changes_str}"

    local result expected
    result="$(calculate_bump "${changes[@]}")"
    expected="$(expected_bump "${changes_str}")"

    if [[ "${result}" != "${expected}" ]]; then
      echo "FALHA na iteração ${i}: mudanças=[${changes_str}] esperado=${expected} obtido=${result}" >&2
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Precedência violada em ${failures}/100 conjuntos mistos"
}

# =============================================================================
# Property Test 7b: MAJOR sempre vence independentemente de outras categorias (100 iterações)
# =============================================================================
@test "Property 7b: presença de MAJOR sempre resulta em bump MAJOR (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local changes_str
    changes_str="$(gen_changes_with_major)"

    local -a changes
    IFS=' ' read -r -a changes <<< "${changes_str}"

    local result
    result="$(calculate_bump "${changes[@]}")"

    if [[ "${result}" != "MAJOR" ]]; then
      echo "FALHA na iteração ${i}: mudanças=[${changes_str}] esperado=MAJOR obtido=${result}" >&2
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "MAJOR não teve precedência em ${failures}/100 conjuntos"
}

# =============================================================================
# Property Test 7c: MINOR vence PATCH quando não há MAJOR (100 iterações)
# =============================================================================
@test "Property 7c: MINOR vence PATCH quando não há MAJOR presente (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local changes_str
    changes_str="$(gen_changes_minor_max)"

    local -a changes
    IFS=' ' read -r -a changes <<< "${changes_str}"

    local result
    result="$(calculate_bump "${changes[@]}")"

    if [[ "${result}" != "MINOR" ]]; then
      echo "FALHA na iteração ${i}: mudanças=[${changes_str}] esperado=MINOR obtido=${result}" >&2
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "MINOR não teve precedência sobre PATCH em ${failures}/100 conjuntos"
}

# =============================================================================
# Property Test 7d: Somente PATCH resulta em PATCH (100 iterações)
# =============================================================================
@test "Property 7d: conjunto com apenas PATCH resulta em bump PATCH (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local changes_str
    changes_str="$(gen_changes_patch_only)"

    local -a changes
    IFS=' ' read -r -a changes <<< "${changes_str}"

    local result
    result="$(calculate_bump "${changes[@]}")"

    if [[ "${result}" != "PATCH" ]]; then
      echo "FALHA na iteração ${i}: mudanças=[${changes_str}] esperado=PATCH obtido=${result}" >&2
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "PATCH não foi o resultado em ${failures}/100 conjuntos exclusivos de PATCH"
}

# =============================================================================
# Property Test 7e: Ordem das mudanças não afeta o resultado (100 iterações)
# =============================================================================
@test "Property 7e: precedência é independente da ordem das mudanças (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local changes_str
    changes_str="$(gen_mixed_changes)"

    # Converte string para array
    local -a changes
    IFS=' ' read -r -a changes <<< "${changes_str}"

    # Calcula bump na ordem original
    local result_original
    result_original="$(calculate_bump "${changes[@]}")"

    # Embaralha a ordem (sort reverso como proxy de reordenação)
    local -a shuffled
    IFS=$'\n' read -r -d '' -a shuffled < <(printf '%s\n' "${changes[@]}" | sort -R && printf '\0') || true

    # Calcula bump na ordem embaralhada
    local result_shuffled
    result_shuffled="$(calculate_bump "${shuffled[@]}")"

    if [[ "${result_original}" != "${result_shuffled}" ]]; then
      echo "FALHA na iteração ${i}: ordem afetou resultado" >&2
      echo "  Original: [${changes_str}] → ${result_original}" >&2
      echo "  Embaralhado: [${shuffled[*]}] → ${result_shuffled}" >&2
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Ordem afetou o resultado em ${failures}/100 conjuntos"
}
