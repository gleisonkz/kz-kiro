#!/usr/bin/env bats
# =============================================================================
# Property 9: Ausência de frontmatter YAML nos steering files
# Feature: archetype-backend-csharp, Property 9: Ausência de frontmatter YAML nos steering files
# =============================================================================
# Para qualquer arquivo .md no diretório steering/ do archetype backend-csharp,
# o conteúdo SHALL iniciar diretamente com markdown (cabeçalho de nível 1 `#`)
# sem frontmatter YAML delimitado por `---`.
#
# **Validates: Requirements 2.8**
# Mínimo 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
}

teardown() {
  cleanup_fixtures
}

# --- Função de validação: steering file sem frontmatter YAML ---
# Implementa a regra do requisito 2.8: steering files do backend-csharp
# DEVEM iniciar com cabeçalho markdown (# ...) e NÃO com frontmatter YAML (---).
# Recebe o conteúdo do arquivo como argumento.
# Retorna 0 se válido (sem frontmatter, inicia com #), 1 se inválido.
validate_no_frontmatter() {
  local content="$1"

  # Verificar se o conteúdo está vazio
  if [[ -z "$content" ]]; then
    return 1
  fi

  # Extrair a primeira linha não-vazia
  local first_line
  first_line="$(echo "$content" | head -n 1)"

  # Rejeitar se inicia com delimitador de frontmatter YAML (---)
  if [[ "$first_line" == "---" ]]; then
    return 1
  fi

  # Verificar que inicia com cabeçalho markdown de nível 1 (# ...)
  if [[ "$first_line" =~ ^#[[:space:]] ]]; then
    return 0
  fi

  # Não inicia com # nem com --- — inválido para steering file backend-csharp
  return 1
}

# --- Geradores específicos para steering files do backend-csharp ---

# Gera um steering file válido (sem frontmatter YAML, inicia com # ...)
_gen_valid_steering_no_frontmatter() {
  local scenario
  scenario=$(( RANDOM % 5 ))

  local title
  title="$(_rand_alpha "$(_rand_int 8 25)")"

  case ${scenario} in
    0)
      # Formato padrão com blockquote de identificação (como architecture.md)
      printf '%s\n\n> **Steering File | Archetype: backend-csharp | Versão: %d.%d.%d**\n>\n> %s\n\n## Seção %s\n\nConteúdo.\n' \
        "# ${title}" \
        "$(_rand_int 0 5)" "$(_rand_int 0 20)" "$(_rand_int 0 99)" \
        "$(_rand_alpha "$(_rand_int 20 50)")" \
        "$(_rand_alpha "$(_rand_int 5 12)")"
      ;;
    1)
      # Formato simples: apenas título e conteúdo
      printf '# %s\n\n%s\n\n## %s\n\n%s\n' \
        "${title}" \
        "$(_rand_alpha "$(_rand_int 20 60)")" \
        "$(_rand_alpha "$(_rand_int 5 15)")" \
        "$(_rand_alpha "$(_rand_int 20 40)")"
      ;;
    2)
      # Formato com múltiplas seções (como naming-conventions.md)
      local num_sections
      num_sections=$(_rand_int 2 5)
      local content="# ${title}\n\n"
      local s
      for (( s = 0; s < num_sections; s++ )); do
        content="${content}## $(_rand_alpha "$(_rand_int 5 12)")\n\n$(_rand_alpha "$(_rand_int 20 50)")\n\n"
      done
      printf '%b' "$content"
      ;;
    3)
      # Formato com blockquote e referências a RFCs (como data-governance.md)
      printf '# %s\n\n> **Steering File | Archetype: backend-csharp | Versão: %d.%d.%d**\n>\n> Baseado em: RFC-%03d, ADR-%03d\n\n---\n\n## %s\n\n%s\n' \
        "${title}" \
        "$(_rand_int 0 3)" "$(_rand_int 0 10)" "$(_rand_int 0 5)" \
        "$(_rand_int 1 5)" "$(_rand_int 1 3)" \
        "$(_rand_alpha "$(_rand_int 5 12)")" \
        "$(_rand_alpha "$(_rand_int 30 60)")"
      ;;
    4)
      # Formato mínimo: título e uma linha de conteúdo
      printf '# %s\n\n%s\n' \
        "${title}" \
        "$(_rand_alpha "$(_rand_int 10 30)")"
      ;;
  esac
}

# Gera um steering file INVÁLIDO (com frontmatter YAML ou sem cabeçalho #)
_gen_invalid_steering_with_frontmatter() {
  local strategy
  strategy=$(( RANDOM % 7 ))

  local title
  title="$(_rand_alpha "$(_rand_int 8 20)")"

  case ${strategy} in
    0)
      # Frontmatter com inclusion: auto (como frontend-react steering)
      printf '%b\n' "---\ninclusion: auto\n---\n\n# ${title}\n\nConteúdo com frontmatter."
      ;;
    1)
      # Frontmatter com inclusion: fileMatch e fileMatchPattern
      local pattern
      pattern=$(_rand_choice "**/*.cs" "**/src/**" "**/*.csproj" "**/Persistence/**")
      printf '%b\n' "---\ninclusion: fileMatch\nfileMatchPattern: \"${pattern}\"\n---\n\n# ${title}\n\nConteúdo com fileMatch."
      ;;
    2)
      # Frontmatter com inclusion: manual
      printf '%b\n' "---\ninclusion: manual\n---\n\n# ${title}\n\nConteúdo com manual."
      ;;
    3)
      # Frontmatter com campos arbitrários
      printf '%b\n' "---\ntitle: ${title}\nauthor: $(_rand_alpha 8)\ndate: 2024-01-15\n---\n\n# ${title}\n\nConteúdo com frontmatter custom."
      ;;
    4)
      # Frontmatter vazio (apenas delimitadores)
      printf '%b\n' "---\n---\n\n# ${title}\n\nConteúdo com frontmatter vazio."
      ;;
    5)
      # Frontmatter com campos do steering de outros archetypes
      printf '%b\n' "---\ninclusion: auto\nfileMatchPattern: \"**/*.ts\"\ncategory: architecture\n---\n\n# ${title}\n\nConteúdo."
      ;;
    6)
      # Apenas --- na primeira linha sem fechar (frontmatter malformado)
      printf '%b\n' "---\ninclusion: auto\n\n# ${title}\n\nSem fechamento."
      ;;
  esac
}

# Gera conteúdo que não inicia com # (inválido por não ser heading markdown)
_gen_invalid_steering_no_heading() {
  local strategy
  strategy=$(( RANDOM % 4 ))

  case ${strategy} in
    0)
      # Inicia com texto normal (sem cabeçalho)
      echo "$(_rand_alpha "$(_rand_int 20 50)")"
      echo ""
      echo "## $(_rand_alpha "$(_rand_int 5 12)")"
      ;;
    1)
      # Inicia com cabeçalho de nível 2
      printf '## %s\n\n%s\n' \
        "$(_rand_alpha "$(_rand_int 8 15)")" \
        "$(_rand_alpha "$(_rand_int 20 40)")"
      ;;
    2)
      # Conteúdo vazio (string vazia)
      echo ""
      ;;
    3)
      # Inicia com blockquote sem cabeçalho
      printf '> %s\n\n# %s\n' \
        "$(_rand_alpha "$(_rand_int 10 30)")" \
        "$(_rand_alpha "$(_rand_int 8 15)")"
      ;;
  esac
}

# =============================================================================
# Property Test 9a: steering file válido (sem frontmatter, inicia com #) é aceito
# =============================================================================
@test "Property 9a: steering file sem frontmatter YAML e com heading # é aceito (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(_gen_valid_steering_no_frontmatter)"

    if ! validate_no_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: steering válido rejeitado"
      echo "Conteúdo (primeiras 3 linhas):"
      echo "$content" | head -n 3
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 steering files válidos"
}

# =============================================================================
# Property Test 9b: steering file com frontmatter YAML (---) é rejeitado
# =============================================================================
@test "Property 9b: steering file com frontmatter YAML (---) é rejeitado (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(_gen_invalid_steering_with_frontmatter)"

    if validate_no_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: steering com frontmatter aceito"
      echo "Conteúdo (primeiras 3 linhas):"
      echo "$content" | head -n 3
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 steering files com frontmatter"
}

# =============================================================================
# Property Test 9c: steering file sem heading de nível 1 é rejeitado
# =============================================================================
@test "Property 9c: steering file sem heading nivel 1 é rejeitado (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(_gen_invalid_steering_no_heading)"

    if validate_no_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: steering sem heading # aceito"
      echo "Conteúdo (primeiras 3 linhas):"
      echo "$content" | head -n 3
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 steering files sem heading"
}

# =============================================================================
# Property Test 9d: steering files reais do archetype backend-csharp são válidos
# =============================================================================
@test "Property 9d: todos os steering files reais do archetype backend-csharp passam na validação" {
  local archetype_steering_dir="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/steering"
  local failures=0
  local file

  for file in "${archetype_steering_dir}/"*.md; do
    [[ ! -f "$file" ]] && continue

    local content
    content="$(cat "$file")"
    local basename_file
    basename_file="$(basename "$file")"

    if ! validate_no_frontmatter "$content"; then
      echo "FALHA: ${basename_file} não passou na validação (inicia com frontmatter ou sem heading #)"
      echo "Primeira linha: $(head -n 1 "$file")"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "${failures} steering files reais falharam na validação"
}
