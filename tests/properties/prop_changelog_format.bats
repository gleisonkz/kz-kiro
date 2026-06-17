#!/usr/bin/env bats
# =============================================================================
# Property 6/8: Formato de changelog
# Feature: archetype-bff-fastify, Property 6: Formato de changelog
# Feature: archetype-frontend-react, Property 8: Formato de changelog
# =============================================================================
# Para qualquer arquivo CHANGELOG.md válido do archetype, a primeira entrada
# SHALL seguir o formato `## MAJOR.MINOR.PATCH (YYYY-MM-DD)`, a versão SHALL
# corresponder ao conteúdo do VERSION file, e cada seção de agrupamento SHALL
# usar exclusivamente um dos 7 nomes válidos: Funcionalidades, Correções,
# Documentação, Refatoração, Manutenção, Performance, CI/CD.
#
# **Validates: Requirements 1.7, 10.2, 10.3, 10.4**
# 100 iterações por property test.

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

# --- Constantes ---

# Seções de agrupamento válidas para o changelog (Requirement 10.4)
VALID_SECTIONS=("Funcionalidades" "Correções" "Documentação" "Refatoração" "Manutenção" "Performance" "CI/CD")

# Regex para cabeçalho de release: ## MAJOR.MINOR.PATCH (YYYY-MM-DD)
RELEASE_HEADER_REGEX='^\#\# (0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*) \([0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\)$'

# Regex semver para validar VERSION
SEMVER_REGEX='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

# --- Função de validação de changelog ---
# Recebe:
#   $1: conteúdo do CHANGELOG.md
#   $2: conteúdo do VERSION file (para comparação com primeira entrada)
# Retorna 0 se válido, 1 se inválido.
validate_changelog() {
  local changelog_content="$1"
  local version_content="$2"

  # 1. Deve ter ao menos uma entrada de release (cabeçalho ## X.Y.Z (YYYY-MM-DD))
  local first_release_header=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^##\  && ! "$line" =~ ^###\  ]]; then
      first_release_header="$line"
      break
    fi
  done <<< "$changelog_content"

  if [[ -z "$first_release_header" ]]; then
    return 1
  fi

  # 2. Validar formato do cabeçalho de release
  if [[ ! "$first_release_header" =~ $RELEASE_HEADER_REGEX ]]; then
    return 1
  fi

  # 3. Extrair versão do primeiro cabeçalho e comparar com VERSION
  local header_version=""
  header_version=$(echo "$first_release_header" | sed -E 's/^## ([0-9]+\.[0-9]+\.[0-9]+) \(.+\)$/\1/')
  if [[ -n "$version_content" && "$header_version" != "$version_content" ]]; then
    return 1
  fi

  # 4. Validar seções de agrupamento (### NomeSeção)
  # Todas as linhas que começam com ### devem ter nomes válidos
  while IFS= read -r line; do
    if [[ "$line" =~ ^###\  ]]; then
      local section_name="${line#\#\#\# }"
      local found=false
      local valid_name
      for valid_name in "${VALID_SECTIONS[@]}"; do
        if [[ "$section_name" == "$valid_name" ]]; then
          found=true
          break
        fi
      done
      if [[ "$found" == "false" ]]; then
        return 1
      fi
    fi
  done <<< "$changelog_content"

  return 0
}

# --- Geradores ---

# Gera uma data aleatória válida no formato YYYY-MM-DD
_gen_date() {
  local year month day
  year=$(_rand_int 2024 2026)
  month=$(_rand_int 1 12)
  day=$(_rand_int 1 28)
  printf '%04d-%02d-%02d' "$year" "$month" "$day"
}

# Gera um changelog válido com versão correspondente ao VERSION informado
gen_valid_changelog() {
  local version="$1"
  [[ -z "$version" ]] && version="$(gen_semver)"

  local date
  date="$(_gen_date)"

  # Cabeçalho
  local content="# Changelog\n\n## ${version} (${date})\n"

  # Escolher entre 1 e 4 seções aleatórias (apenas nomes válidos)
  local num_sections
  num_sections=$(_rand_int 1 4)
  local used_sections=()
  local i
  for (( i = 0; i < num_sections; i++ )); do
    local section
    section="$(_rand_choice "${VALID_SECTIONS[@]}")"
    # Evitar seções duplicadas
    local already_used=false
    local s
    for s in "${used_sections[@]}"; do
      if [[ "$s" == "$section" ]]; then
        already_used=true
        break
      fi
    done
    if [[ "$already_used" == "true" ]]; then
      continue
    fi
    used_sections+=("$section")

    content="${content}\n### ${section}\n"
    # Adicionar entre 1 e 3 entradas
    local num_entries
    num_entries=$(_rand_int 1 3)
    local e
    for (( e = 0; e < num_entries; e++ )); do
      content="${content}\n- $(_rand_alpha "$(_rand_int 10 30)")"
    done
    content="${content}\n"
  done

  # Opcionalmente adicionar uma release anterior
  if (( RANDOM % 2 == 0 )); then
    local old_version
    old_version="$(gen_semver)"
    local old_date
    old_date="$(_gen_date)"
    content="${content}\n## ${old_version} (${old_date})\n\n### Funcionalidades\n\n- Entrada anterior\n"
  fi

  printf '%b' "$content"
}

# Gera um changelog INVÁLIDO
gen_invalid_changelog() {
  local strategy
  strategy=$(_rand_int 0 6)

  case "$strategy" in
    0)
      # Cabeçalho de release sem data
      local v
      v="$(gen_semver)"
      printf '# Changelog\n\n## %s\n\n### Funcionalidades\n\n- Algo\n' "$v"
      ;;
    1)
      # Cabeçalho de release com formato de data errado (DD/MM/YYYY)
      local v
      v="$(gen_semver)"
      printf '# Changelog\n\n## %s (%02d/%02d/%04d)\n\n### Funcionalidades\n\n- Algo\n' \
        "$v" "$(_rand_int 1 28)" "$(_rand_int 1 12)" "$(_rand_int 2024 2026)"
      ;;
    2)
      # Seção com nome inválido
      local v
      v="$(gen_semver)"
      local date
      date="$(_gen_date)"
      local invalid_section
      invalid_section="$(_rand_choice "Added" "Fixed" "Changed" "Removed" "Features" "Bug Fixes" "Melhorias")"
      printf '# Changelog\n\n## %s (%s)\n\n### %s\n\n- Algo\n' "$v" "$date" "$invalid_section"
      ;;
    3)
      # Versão com prefixo v no cabeçalho
      local v
      v="$(gen_semver)"
      local date
      date="$(_gen_date)"
      printf '# Changelog\n\n## v%s (%s)\n\n### Funcionalidades\n\n- Algo\n' "$v" "$date"
      ;;
    4)
      # Sem nenhum cabeçalho de release (apenas texto)
      printf '# Changelog\n\nAlgum texto sem entradas de release.\n'
      ;;
    5)
      # Data com mês inválido (13)
      local v
      v="$(gen_semver)"
      printf '# Changelog\n\n## %s (2025-13-01)\n\n### Funcionalidades\n\n- Algo\n' "$v"
      ;;
    6)
      # Data com dia inválido (32)
      local v
      v="$(gen_semver)"
      printf '# Changelog\n\n## %s (2025-01-32)\n\n### Funcionalidades\n\n- Algo\n' "$v"
      ;;
  esac
}

# =============================================================================
# Property Test 8a: changelog válido DEVE ser aceito (100 iterações)
# =============================================================================
@test "Property 8a: changelog com formato válido é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local version
    version="$(gen_semver)"

    local changelog
    changelog="$(gen_valid_changelog "$version")"

    if ! validate_changelog "$changelog" "$version"; then
      echo "FALHA na iteração ${i}: changelog válido rejeitado"
      echo "VERSION: ${version}"
      echo "CHANGELOG:"
      echo "$changelog"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 changelogs válidos"
}

# =============================================================================
# Property Test 8b: changelog inválido DEVE ser rejeitado (100 iterações)
# =============================================================================
@test "Property 8b: changelog com formato inválido é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local changelog
    changelog="$(gen_invalid_changelog)"

    if validate_changelog "$changelog" ""; then
      echo "FALHA na iteração ${i}: changelog inválido aceito"
      echo "CHANGELOG:"
      echo "$changelog"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 changelogs inválidos"
}

# =============================================================================
# Property Test 8c: versão do changelog DEVE corresponder ao VERSION (100 iterações)
# =============================================================================
@test "Property 8c: changelog cuja versão não corresponde ao VERSION é rejeitado (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    # Gerar changelog com uma versão
    local changelog_version
    changelog_version="$(gen_semver)"
    local changelog
    changelog="$(gen_valid_changelog "$changelog_version")"

    # Gerar uma versão diferente para o VERSION file
    local version_file
    version_file="$(gen_semver)"
    # Garantir que são diferentes
    while [[ "$version_file" == "$changelog_version" ]]; do
      version_file="$(gen_semver)"
    done

    if validate_changelog "$changelog" "$version_file"; then
      echo "FALHA na iteração ${i}: changelog com versão divergente foi aceito"
      echo "VERSION file: ${version_file}"
      echo "Versão no CHANGELOG: ${changelog_version}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 changelogs com versão divergente"
}

# =============================================================================
# Testes de borda
# =============================================================================

@test "Property 8 — borda: changelog com todas as 7 seções válidas é aceito" {
  local version="1.0.0"
  local changelog="# Changelog

## 1.0.0 (2025-06-15)

### Funcionalidades

- Nova feature

### Correções

- Bug fix

### Documentação

- Atualizar docs

### Refatoração

- Refatorar módulo

### Manutenção

- Atualizar deps

### Performance

- Melhorar performance

### CI/CD

- Ajustar pipeline"

  validate_changelog "$changelog" "$version"
}

@test "Property 8 — borda: changelog com seção 'Added' (inglês) é rejeitado" {
  local changelog="# Changelog

## 1.0.0 (2025-06-15)

### Added

- Something"

  ! validate_changelog "$changelog" "1.0.0"
}

@test "Property 8 — borda: changelog com data inválida (mês 00) é rejeitado" {
  local changelog="# Changelog

## 1.0.0 (2025-00-15)

### Funcionalidades

- Algo"

  ! validate_changelog "$changelog" "1.0.0"
}

@test "Property 8 — borda: changelog com versão com zeros à esquerda é rejeitado" {
  local changelog="# Changelog

## 01.0.0 (2025-06-15)

### Funcionalidades

- Algo"

  ! validate_changelog "$changelog" "01.0.0"
}

@test "Property 8 — borda: changelog vazio é rejeitado" {
  ! validate_changelog "" "1.0.0"
}

@test "Property 8 — borda: changelog sem entradas de release é rejeitado" {
  local changelog="# Changelog

Nenhuma release ainda."

  ! validate_changelog "$changelog" "1.0.0"
}
