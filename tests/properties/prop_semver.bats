#!/usr/bin/env bats
# =============================================================================
# Property Test: Validação de formato semver
# Feature: baseline-global
# Property 1: Validação de formato semver
#
# Para qualquer string, a função de validação de semver SHALL aceitar se e
# somente se a string seguir o formato MAJOR.MINOR.PATCH onde cada segmento é
# um inteiro não-negativo sem zeros à esquerda, sem prefixo v, sem espaços e
# sem quebra de linha.
#
# **Validates: Requirements 1.4, 3.3, 8.1, 8.5**
# =============================================================================

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'
  load '../helpers/generators'

  # Regex de validação semver conforme design document
  SEMVER_REGEX='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
}

teardown() {
  cleanup_fixtures
}

# Função auxiliar: valida semver usando a regex do design document
validate_semver() {
  local input="$1"
  [[ "${input}" =~ ${SEMVER_REGEX} ]]
}

# --- Property 1: Strings válidas DEVEM ser aceitas ---

# @test com 100 iterações de semver válido
@test "Property 1 — semver válido: gen_semver() DEVE ser aceito pela regex (100 iterações)" {
  local i
  for (( i = 0; i < 100; i++ )); do
    local version
    version="$(gen_semver)"

    if ! validate_semver "${version}"; then
      echo "Iteração ${i}: '${version}' deveria ser aceito mas foi rejeitado" >&2
      return 1
    fi

    # Verificações adicionais de formato:
    # Sem prefixo v
    [[ "${version}" != v* ]] || {
      echo "Iteração ${i}: '${version}' tem prefixo v" >&2
      return 1
    }

    # Sem espaços
    [[ "${version}" != *" "* ]] || {
      echo "Iteração ${i}: '${version}' contém espaços" >&2
      return 1
    }

    # Exatamente 3 segmentos separados por ponto
    local segment_count
    segment_count=$(echo "${version}" | tr -cd '.' | wc -c | tr -d ' ')
    [[ "${segment_count}" -eq 2 ]] || {
      echo "Iteração ${i}: '${version}' não tem exatamente 2 pontos (tem ${segment_count})" >&2
      return 1
    }

    # Cada segmento sem zeros à esquerda (exceto "0" isolado)
    local major minor patch
    IFS='.' read -r major minor patch <<< "${version}"

    for seg_name in major minor patch; do
      local seg_value="${!seg_name}"
      if [[ "${#seg_value}" -gt 1 && "${seg_value}" == 0* ]]; then
        echo "Iteração ${i}: '${version}' — segmento ${seg_name}='${seg_value}' tem zero à esquerda" >&2
        return 1
      fi
    done
  done
}

# --- Property 1: Strings inválidas DEVEM ser rejeitadas ---

@test "Property 1 — semver inválido: gen_invalid_semver() DEVE ser rejeitado pela regex (100 iterações)" {
  local i
  for (( i = 0; i < 100; i++ )); do
    local invalid
    invalid="$(gen_invalid_semver)"

    if validate_semver "${invalid}"; then
      echo "Iteração ${i}: '${invalid}' deveria ser rejeitado mas foi aceito" >&2
      return 1
    fi
  done
}

# --- Property 1: Casos específicos de borda ---

@test "Property 1 — borda: '0.0.0' é semver válido" {
  validate_semver "0.0.0"
}

@test "Property 1 — borda: versões com segmentos grandes são válidas" {
  validate_semver "999.999.999"
  validate_semver "100.200.300"
}

@test "Property 1 — borda: strings com prefixo v são rejeitadas" {
  ! validate_semver "v1.0.0"
  ! validate_semver "v0.1.0"
}

@test "Property 1 — borda: strings com zeros à esquerda são rejeitadas" {
  ! validate_semver "01.0.0"
  ! validate_semver "0.01.0"
  ! validate_semver "0.0.01"
  ! validate_semver "00.0.0"
}

@test "Property 1 — borda: strings com espaços são rejeitadas" {
  ! validate_semver " 1.0.0"
  ! validate_semver "1.0.0 "
  ! validate_semver " 1.0.0 "
  ! validate_semver "1. 0.0"
}

@test "Property 1 — borda: strings com newline são rejeitadas" {
  local with_newline=$'1.0.0\n'
  ! validate_semver "${with_newline}"
}

@test "Property 1 — borda: strings com segmentos insuficientes são rejeitadas" {
  ! validate_semver "1.0"
  ! validate_semver "1"
  ! validate_semver ""
}

@test "Property 1 — borda: strings com segmentos extras são rejeitadas" {
  ! validate_semver "1.0.0.0"
  ! validate_semver "1.0.0-alpha"
  ! validate_semver "1.0.0+build"
}

@test "Property 1 — borda: strings não-numéricas são rejeitadas" {
  ! validate_semver "abc"
  ! validate_semver "a.b.c"
  ! validate_semver "1.x.0"
}

# =============================================================================
# Property 2: Formato de versão semântica — archetype backend-csharp
# Feature: archetype-backend-csharp
#
# Valida que o arquivo VERSION do archetype backend-csharp contém exatamente
# uma versão semver válida (MAJOR.MINOR.PATCH), sem prefixo v, sem espaços,
# sem trailing newline extra.
#
# **Validates: Requirements 1.6, 11.1**
# =============================================================================

# --- Property 2: VERSION do archetype backend-csharp ---

@test "Property 2 — archetype backend-csharp: VERSION contém semver válido" {
  local version_file="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/VERSION"

  # Arquivo deve existir
  [[ -f "${version_file}" ]] || {
    echo "Arquivo VERSION não encontrado: ${version_file}" >&2
    return 1
  }

  # Lê conteúdo bruto (sem strip de newline do bash)
  local content
  content="$(cat "${version_file}")"

  # Deve ser semver válido
  if ! validate_semver "${content}"; then
    echo "VERSION do backend-csharp '${content}' não é semver válido" >&2
    return 1
  fi
}

@test "Property 2 — archetype backend-csharp: VERSION não tem prefixo v" {
  local version_file="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/VERSION"
  local content
  content="$(cat "${version_file}")"

  [[ "${content}" != v* ]] || {
    echo "VERSION '${content}' tem prefixo v" >&2
    return 1
  }
}

@test "Property 2 — archetype backend-csharp: VERSION não tem espaços" {
  local version_file="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/VERSION"
  local content
  content="$(cat "${version_file}")"

  [[ "${content}" != *" "* ]] || {
    echo "VERSION '${content}' contém espaços" >&2
    return 1
  }
}

@test "Property 2 — archetype backend-csharp: VERSION não tem trailing newline extra" {
  local version_file="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/VERSION"

  # Verifica que o último byte não é uma segunda newline
  # (bash `cat` strip de trailing newline é normal, mas queremos verificar
  # que não há linhas extras)
  local line_count
  line_count=$(wc -l < "${version_file}" | tr -d ' ')

  [[ "${line_count}" -le 1 ]] || {
    echo "VERSION tem ${line_count} linhas — esperado no máximo 1" >&2
    return 1
  }
}

@test "Property 2 — semver válido + inválido combinado: 100 iterações com proporção mista (backend-csharp)" {
  # Gera mix de 50 válidos e 50 inválidos, verificando classificação correta
  local i
  for (( i = 0; i < 50; i++ )); do
    local valid
    valid="$(gen_semver)"
    if ! validate_semver "${valid}"; then
      echo "Iteração ${i}: válido '${valid}' rejeitado incorretamente" >&2
      return 1
    fi
  done

  for (( i = 0; i < 50; i++ )); do
    local invalid
    invalid="$(gen_invalid_semver)"
    if validate_semver "${invalid}"; then
      echo "Iteração ${i}: inválido '${invalid}' aceito incorretamente" >&2
      return 1
    fi
  done
}
