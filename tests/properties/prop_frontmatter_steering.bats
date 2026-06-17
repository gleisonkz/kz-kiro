#!/usr/bin/env bats
# =============================================================================
# Property 3: Frontmatter de steering files
# Feature: archetype-frontend-react, Property 3: Frontmatter de steering files
# =============================================================================
# Para qualquer steering file do archetype, o frontmatter YAML SHALL conter o
# campo inclusion com valor exatamente auto, fileMatch ou manual, e QUANDO
# inclusion é fileMatch, o campo fileMatchPattern SHALL estar presente com um
# valor string não-vazio contendo padrões glob separados por vírgula.
#
# **Validates: Requirements 2.6, 2.7, 2.8, 2.9, 2.10**
# Mínimo 20 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
}

teardown() {
  cleanup_fixtures
}

# --- Função de validação de frontmatter de steering files ---
# Implementa a lógica de validação conforme Property 3 do design document.
# Recebe conteúdo markdown como argumento.
# Retorna 0 se válido, 1 se inválido.
validate_steering_frontmatter() {
  local content="$1"

  # Verificar se começa com delimitador de frontmatter (---)
  local first_line
  first_line="$(echo "$content" | head -n 1)"
  if [[ "$first_line" != "---" ]]; then
    return 1
  fi

  # Verificar se o frontmatter foi fechado (segundo --- encontrado)
  local closing_delimiter
  closing_delimiter="$(echo "$content" | sed -n '2,$p' | grep -n '^---$' | head -n 1)"
  if [[ -z "$closing_delimiter" ]]; then
    return 1
  fi

  # Extrair bloco frontmatter: tudo entre o primeiro e segundo ---
  local frontmatter
  frontmatter="$(echo "$content" | sed -n '2,/^---$/p' | sed '$d')"

  # Extrair valor do campo inclusion
  local inclusion
  inclusion="$(echo "$frontmatter" | grep -E '^inclusion:\s*' | sed 's/^inclusion:\s*//' | tr -d '[:space:]')"

  # Verificar se inclusion está presente
  if [[ -z "$inclusion" ]]; then
    return 1
  fi

  # Verificar se inclusion tem valor válido (auto, fileMatch ou manual)
  if [[ "$inclusion" != "auto" && "$inclusion" != "fileMatch" && "$inclusion" != "manual" ]]; then
    return 1
  fi

  # Quando inclusion é fileMatch, fileMatchPattern deve estar presente e não-vazio
  if [[ "$inclusion" == "fileMatch" ]]; then
    local pattern_line
    pattern_line="$(echo "$frontmatter" | grep -E '^fileMatchPattern:' || true)"

    # Campo ausente
    if [[ -z "$pattern_line" ]]; then
      return 1
    fi

    # Extrair valor após "fileMatchPattern:"
    local pattern_value
    pattern_value="$(echo "$pattern_line" | sed 's/^fileMatchPattern:\s*//')"

    # Remover aspas simples e duplas ao redor do valor
    pattern_value="$(echo "$pattern_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"

    # Remover espaços internos para verificar se contém conteúdo real
    local trimmed_value
    trimmed_value="$(echo "$pattern_value" | tr -d '[:space:]')"

    # Verificar se está vazio ou contém apenas espaços
    if [[ -z "$trimmed_value" ]]; then
      return 1
    fi
  fi

  return 0
}

# --- Geradores específicos para steering files do archetype ---

# Gera um frontmatter válido de steering file com padrões realistas do archetype
_gen_valid_steering_frontmatter() {
  local scenario
  scenario=$(( RANDOM % 3 ))

  case ${scenario} in
    0)
      # inclusion: auto (como stack-and-tooling.md e naming-conventions.md)
      printf '%b\n' "---\ninclusion: auto\n---\n\n# $(_rand_alpha "$(_rand_int 8 20)")\n\nConteúdo do steering file."
      ;;
    1)
      # inclusion: fileMatch com padrões glob separados por vírgula
      local patterns
      patterns=$(_rand_choice \
        "**/modules/**, **/src/app/**" \
        "**/*.tsx, **/shared/ui/**, **/*.variants.ts" \
        "**/.github/**, **/turbo.json, **/Dockerfile*" \
        "**/*.ts, **/src/**" \
        "**/components/**, **/hooks/**" \
        "**/api/**, **/services/**")
      printf '%b\n' "---\ninclusion: fileMatch\nfileMatchPattern: \"${patterns}\"\n---\n\n# $(_rand_alpha "$(_rand_int 8 20)")\n\nConteúdo com fileMatch."
      ;;
    2)
      # inclusion: manual (válido para steering, embora não usado no archetype)
      printf '%b\n' "---\ninclusion: manual\n---\n\n# $(_rand_alpha "$(_rand_int 8 20)")\n\nConteúdo manual."
      ;;
  esac
}

# Gera um frontmatter INVÁLIDO para steering file
_gen_invalid_steering_frontmatter() {
  local strategy
  strategy=$(( RANDOM % 7 ))

  case ${strategy} in
    0)
      # Sem frontmatter (sem delimitadores ---)
      echo "# Título sem frontmatter"
      echo ""
      echo "Conteúdo sem YAML frontmatter."
      ;;
    1)
      # inclusion com valor inválido
      local invalid_val
      invalid_val=$(_rand_choice "always" "never" "automatic" "file-match" "Auto" "FileMatch" "MANUAL" "on" "off" "$(_rand_alpha 5)")
      printf '%b\n' "---\ninclusion: ${invalid_val}\n---\n\n# Teste"
      ;;
    2)
      # fileMatch sem fileMatchPattern
      printf '%b\n' "---\ninclusion: fileMatch\n---\n\n# Teste sem pattern"
      ;;
    3)
      # fileMatch com fileMatchPattern vazio
      printf '%b\n' "---\ninclusion: fileMatch\nfileMatchPattern: \"\"\n---\n\n# Teste"
      ;;
    4)
      # Campo inclusion ausente
      printf '%b\n' "---\ntitle: $(_rand_alpha 10)\ndescription: alguma coisa\n---\n\n# Teste sem inclusion"
      ;;
    5)
      # Delimitador de abertura sem fechamento
      printf '%b\n' "---\ninclusion: auto\n\n# Sem fechamento de frontmatter"
      ;;
    6)
      # fileMatch com fileMatchPattern contendo apenas espaços
      printf '%b\n' "---\ninclusion: fileMatch\nfileMatchPattern: \"   \"\n---\n\n# Teste com espaços"
      ;;
  esac
}

# =============================================================================
# Property Test 3a: frontmatter válido de steering DEVE ser aceito (20 iter.)
# =============================================================================
@test "Property 3a: frontmatter válido de steering file é aceito (20 iterações)" {
  local i=0
  local failures=0

  for (( i = 0; i < 20; i++ )); do
    local content
    content="$(_gen_valid_steering_frontmatter)"

    if ! validate_steering_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter válido rejeitado"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]]
}

# =============================================================================
# Property Test 3b: frontmatter inválido de steering DEVE ser rejeitado (20 iter.)
# =============================================================================
@test "Property 3b: frontmatter inválido de steering file é rejeitado (20 iterações)" {
  local i=0
  local failures=0

  for (( i = 0; i < 20; i++ )); do
    local content
    content="$(_gen_invalid_steering_frontmatter)"

    if validate_steering_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter inválido aceito"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]]
}

# =============================================================================
# Property Test 3c: inclusion aceita somente auto, fileMatch ou manual (20 iter.)
# =============================================================================
@test "Property 3c: inclusion aceita somente auto, fileMatch ou manual (20 iterações)" {
  local valid_values=("auto" "fileMatch" "manual")
  local i=0
  local failures=0

  for (( i = 0; i < 20; i++ )); do
    local is_valid_case=$(( RANDOM % 2 ))

    if [[ ${is_valid_case} -eq 1 ]]; then
      # Caso válido: usar um dos valores válidos
      local val="${valid_values[$(( RANDOM % 3 ))]}"
      local content

      if [[ "$val" == "fileMatch" ]]; then
        local pat
        pat=$(_rand_choice "**/*.ts" "**/modules/**" "**/.github/**, **/turbo.json" "**/*.tsx, **/shared/ui/**")
        content="---
inclusion: fileMatch
fileMatchPattern: \"${pat}\"
---

# Test ${i}"
      else
        content="---
inclusion: ${val}
---

# Test ${i}"
      fi

      if ! validate_steering_frontmatter "$content"; then
        echo "FALHA iteração ${i}: valor válido '${val}' rejeitado"
        failures=$((failures + 1))
      fi
    else
      # Caso inválido: gerar valor que NÃO é válido
      local invalid_val
      invalid_val="$(_rand_choice "always" "never" "automatic" "file-match" "Manual" "AUTO" "FileMatch" "FILEMATCH" "$(_rand_alpha 5)")"
      local content="---
inclusion: ${invalid_val}
---

# Test ${i}"

      if validate_steering_frontmatter "$content"; then
        echo "FALHA iteração ${i}: valor inválido '${invalid_val}' aceito"
        failures=$((failures + 1))
      fi
    fi
  done

  [[ ${failures} -eq 0 ]]
}

# =============================================================================
# Property Test 3d: fileMatch exige fileMatchPattern presente e não-vazio (20 iter.)
# =============================================================================
@test "Property 3d: fileMatch exige fileMatchPattern presente e não-vazio (20 iterações)" {
  local patterns=(
    "**/modules/**, **/src/app/**"
    "**/*.tsx, **/shared/ui/**, **/*.variants.ts"
    "**/.github/**, **/turbo.json, **/Dockerfile*"
    "**/*.ts"
    "**/components/**"
    "**/api/**, **/services/**"
  )
  local i=0
  local failures=0

  for (( i = 0; i < 20; i++ )); do
    local scenario=$(( RANDOM % 5 ))

    case ${scenario} in
      0)
        # fileMatch COM pattern válido (com vírgulas separando globs) → aceito
        local pat="${patterns[$(( RANDOM % ${#patterns[@]} ))]}"
        local content="---
inclusion: fileMatch
fileMatchPattern: \"${pat}\"
---

# Test ${i}"

        if ! validate_steering_frontmatter "$content"; then
          echo "FALHA iteração ${i}: fileMatch com pattern '${pat}' rejeitado"
          failures=$((failures + 1))
        fi
        ;;
      1)
        # fileMatch SEM fileMatchPattern → rejeitado
        local content="---
inclusion: fileMatch
---

# Test ${i}"

        if validate_steering_frontmatter "$content"; then
          echo "FALHA iteração ${i}: fileMatch sem pattern aceito"
          failures=$((failures + 1))
        fi
        ;;
      2)
        # fileMatch com fileMatchPattern vazio → rejeitado
        local content="---
inclusion: fileMatch
fileMatchPattern: \"\"
---

# Test ${i}"

        if validate_steering_frontmatter "$content"; then
          echo "FALHA iteração ${i}: fileMatch com pattern vazio aceito"
          failures=$((failures + 1))
        fi
        ;;
      3)
        # auto SEM fileMatchPattern → aceito (não requer pattern)
        local content="---
inclusion: auto
---

# Test ${i}"

        if ! validate_steering_frontmatter "$content"; then
          echo "FALHA iteração ${i}: 'auto' sem pattern rejeitado"
          failures=$((failures + 1))
        fi
        ;;
      4)
        # manual SEM fileMatchPattern → aceito (não requer pattern)
        local content="---
inclusion: manual
---

# Test ${i}"

        if ! validate_steering_frontmatter "$content"; then
          echo "FALHA iteração ${i}: 'manual' sem pattern rejeitado"
          failures=$((failures + 1))
        fi
        ;;
    esac
  done

  [[ ${failures} -eq 0 ]]
}
