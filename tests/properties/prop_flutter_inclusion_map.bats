#!/usr/bin/env bats
# =============================================================================
# Property 3: Mapeamento correto de inclusion por steering file
# Feature: archetype-mobile-flutter, Property 3: Mapeamento correto de inclusion
# =============================================================================
# Para qualquer steering file do archetype mobile-flutter, o valor do campo
# `inclusion` no frontmatter SHALL corresponder ao mapeamento esperado:
# - always (2 files): coding-standards.md, flutter-lints-security.md
# - fileMatch (3 files): flutter_best_practices.md, flutter-testing-patterns.md,
#                        dependency-management.md
# - auto (9 files): clean-architecture.md, flutter-clean-architecture.md,
#                   design-system.md, auth-api.md, forgot-password-api.md,
#                   home-api.md, notifications-api.md, profile-api.md,
#                   settings-api.md
# - manual (1 file): code-review.md
#
# **Validates: Requirements 14.1, 14.2, 14.3, 14.4, 14.5, 14.6**
# Mínimo 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
  load '../helpers/assertions'
}

teardown() {
  cleanup_fixtures
}

# --- Mapeamento esperado (source of truth) ---
# Função que retorna o inclusion esperado para um dado filename
# Abordagem sem associative arrays para compatibilidade com bash 3.x
get_expected_inclusion() {
  local filename="$1"
  case "${filename}" in
    coding-standards.md)          echo "always" ;;
    flutter-lints-security.md)    echo "always" ;;
    flutter_best_practices.md)    echo "fileMatch" ;;
    flutter-testing-patterns.md)  echo "fileMatch" ;;
    dependency-management.md)     echo "fileMatch" ;;
    clean-architecture.md)        echo "auto" ;;
    flutter-clean-architecture.md) echo "auto" ;;
    design-system.md)             echo "auto" ;;
    auth-api.md)                  echo "auto" ;;
    forgot-password-api.md)       echo "auto" ;;
    home-api.md)                  echo "auto" ;;
    notifications-api.md)         echo "auto" ;;
    profile-api.md)               echo "auto" ;;
    settings-api.md)              echo "auto" ;;
    code-review.md)               echo "manual" ;;
    *) echo "" ;;
  esac
}

# Lista de todos os arquivos (15)
STEERING_FILES=(
  "coding-standards.md"
  "flutter-lints-security.md"
  "flutter_best_practices.md"
  "flutter-testing-patterns.md"
  "dependency-management.md"
  "clean-architecture.md"
  "flutter-clean-architecture.md"
  "design-system.md"
  "auth-api.md"
  "forgot-password-api.md"
  "home-api.md"
  "notifications-api.md"
  "profile-api.md"
  "settings-api.md"
  "code-review.md"
)

# Valores válidos de inclusion
VALID_INCLUSIONS=("always" "fileMatch" "auto" "manual")

# --- Função de validação do mapeamento de inclusion ---
# Recebe um diretório contendo .md files com frontmatter YAML.
# Para cada .md file (excluindo README.md), extrai o campo inclusion
# e compara contra o mapeamento esperado (EXPECTED_INCLUSION_MAP).
# Retorna 0 se TODOS os mapeamentos estão corretos, 1 se algum está errado.
validate_inclusion_map() {
  local dir="$1"

  if [[ ! -d "${dir}" ]]; then
    return 1
  fi

  for file in "${dir}"/*.md; do
    [[ -f "${file}" ]] || continue
    local basename
    basename="$(basename "${file}")"

    # Pular README.md
    [[ "${basename}" == "README.md" ]] && continue

    # Verificar se o arquivo está no mapeamento esperado
    local expected_inclusion
    expected_inclusion="$(get_expected_inclusion "${basename}")"
    if [[ -z "${expected_inclusion}" ]]; then
      # Arquivo não esperado no mapeamento → inválido
      return 1
    fi

    # Extrair inclusion do frontmatter
    local actual_inclusion=""
    local in_frontmatter=0
    local line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))
      if [[ ${line_num} -eq 1 && "${line}" == "---" ]]; then
        in_frontmatter=1
        continue
      fi
      if [[ ${in_frontmatter} -eq 1 && "${line}" == "---" ]]; then
        break
      fi
      if [[ ${in_frontmatter} -eq 1 ]]; then
        # Extrair campo inclusion
        if [[ "${line}" =~ ^inclusion:[[:space:]]*(.+)$ ]]; then
          actual_inclusion="${BASH_REMATCH[1]}"
          # Remover espaços à direita
          actual_inclusion="${actual_inclusion%"${actual_inclusion##*[![:space:]]}"}"
        fi
      fi
    done < "${file}"

    # Sem frontmatter ou sem inclusion → inválido
    if [[ -z "${actual_inclusion}" ]]; then
      return 1
    fi

    # Comparar com esperado
    if [[ "${actual_inclusion}" != "${expected_inclusion}" ]]; then
      return 1
    fi
  done

  # Verificar que todos os 15 arquivos existem
  local count=0
  for file in "${dir}"/*.md; do
    [[ -f "${file}" ]] || continue
    local basename
    basename="$(basename "${file}")"
    [[ "${basename}" == "README.md" ]] && continue
    count=$((count + 1))
  done

  if [[ ${count} -ne 15 ]]; then
    return 1
  fi

  return 0
}

# --- Gerador de diretório com mapeamento VÁLIDO ---
# Cria um diretório temporário com 15 .md files, cada um com frontmatter
# contendo o inclusion correto conforme o mapeamento esperado.
gen_valid_inclusion_dir() {
  local dir
  dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-inclusion-valid-XXXXXX")"
  echo "${dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  for filename in "${STEERING_FILES[@]}"; do
    local inclusion
    inclusion="$(get_expected_inclusion "${filename}")"

    # Gerar arquivo minimal com frontmatter correto
    printf '%s\n' "---" "inclusion: ${inclusion}" "---" "" "# Test File" "" "Content for ${filename}." > "${dir}/${filename}"
  done

  echo "${dir}"
}

# --- Gerador de diretório com mapeamento INVÁLIDO ---
# Cria um diretório temporário com 15 .md files mas SWAPS pelo menos um
# arquivo para um inclusion incorreto.
gen_invalid_inclusion_dir() {
  local dir
  dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-inclusion-invalid-XXXXXX")"
  echo "${dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # Escolher aleatoriamente qual arquivo terá inclusion errado (1 swap para velocidade)
  local total=${#STEERING_FILES[@]}
  local swap_idx=$(( RANDOM % total ))

  local i
  for (( i = 0; i < total; i++ )); do
    local filename="${STEERING_FILES[$i]}"
    local inclusion
    inclusion="$(get_expected_inclusion "${filename}")"

    if [[ ${i} -eq ${swap_idx} ]]; then
      # Trocar para um inclusion DIFERENTE do esperado
      local wrong_inclusion="${inclusion}"
      while [[ "${wrong_inclusion}" == "${inclusion}" ]]; do
        local idx=$(( RANDOM % 4 ))
        wrong_inclusion="${VALID_INCLUSIONS[$idx]}"
      done
      inclusion="${wrong_inclusion}"
    fi

    # Gerar arquivo minimal (sem chamadas desnecessárias a _rand)
    printf '%s\n' "---" "inclusion: ${inclusion}" "---" "" "# Test" "" "Content." > "${dir}/${filename}"
  done

  echo "${dir}"
}

# =============================================================================
# Property Test 3a: diretório com mapeamento correto é aceito (100 iterações)
# =============================================================================
@test "Property 3a: diretório com mapeamento de inclusion correto é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local dir
    dir="$(gen_valid_inclusion_dir)"

    if ! validate_inclusion_map "${dir}"; then
      echo "FALHA na iteração ${i}: diretório com mapeamento válido foi rejeitado"
      echo "Diretório: ${dir}"
      failures=$((failures + 1))
    fi

    # Cleanup inline para não acumular dirs
    rm -rf "${dir}"
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 diretórios com mapeamento correto"
}

# =============================================================================
# Property Test 3b: diretório com mapeamento incorreto é rejeitado (100 iterações)
# =============================================================================
@test "Property 3b: diretório com mapeamento de inclusion incorreto é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local dir
    dir="$(gen_invalid_inclusion_dir)"

    if validate_inclusion_map "${dir}"; then
      echo "FALHA na iteração ${i}: diretório com mapeamento inválido foi aceito"
      echo "Diretório: ${dir}"
      # Mostrar conteúdo para debug
      for f in "${dir}"/*.md; do
        echo "  $(basename "$f"): $(head -2 "$f" | tail -1)"
      done
      failures=$((failures + 1))
    fi

    # Cleanup inline
    rm -rf "${dir}"
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 diretórios com mapeamento incorreto"
}

# =============================================================================
# Property Test 3c: o archetype real mobile-flutter passa a validação de mapeamento
# =============================================================================
@test "Property 3c: os steering files reais do archetype mobile-flutter possuem mapeamento de inclusion correto" {
  local steering_dir="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter/steering"

  # Verificar que o diretório existe
  [[ -d "${steering_dir}" ]] || fail "Diretório de steering não encontrado: ${steering_dir}"

  # Validar mapeamento
  if ! validate_inclusion_map "${steering_dir}"; then
    # Detalhar qual arquivo falhou
    for file in "${steering_dir}"/*.md; do
      [[ -f "${file}" ]] || continue
      local basename
      basename="$(basename "${file}")"
      [[ "${basename}" == "README.md" ]] && continue

      local expected
      expected="$(get_expected_inclusion "${basename}")"
      local actual=""
      local in_fm=0
      local ln=0
      while IFS= read -r line; do
        ln=$((ln + 1))
        if [[ ${ln} -eq 1 && "${line}" == "---" ]]; then
          in_fm=1; continue
        fi
        if [[ ${in_fm} -eq 1 && "${line}" == "---" ]]; then
          break
        fi
        if [[ ${in_fm} -eq 1 && "${line}" =~ ^inclusion:[[:space:]]*(.+)$ ]]; then
          actual="${BASH_REMATCH[1]}"
          actual="${actual%"${actual##*[![:space:]]}"}"
        fi
      done < "${file}"

      if [[ "${actual}" != "${expected}" ]]; then
        echo "MISMATCH: ${basename} — esperado '${expected}', encontrado '${actual}'"
      fi
    done

    fail "O archetype real mobile-flutter falhou na validação de mapeamento de inclusion"
  fi
}
