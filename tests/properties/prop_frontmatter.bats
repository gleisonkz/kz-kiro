#!/usr/bin/env bats
# =============================================================================
# Property 2: Validação de frontmatter de steering file
# Feature: baseline-global, Property 2: Validação de frontmatter de steering file
# =============================================================================
# Para qualquer conteúdo markdown, a função de validação de steering file SHALL
# aceitar se e somente se o arquivo contiver um bloco YAML frontmatter com o
# campo inclusion cujo valor é exatamente manual, auto ou fileMatch, e quando
# inclusion é fileMatch, o campo fileMatchPattern deve estar presente e não-vazio.
#
# **Validates: Requirements 1.6, 1.7, 2.9**
# Mínimo 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
}

teardown() {
  cleanup_fixtures
}

# --- Função de validação de frontmatter ---
# Implementa a lógica de validação conforme Property 2 do design document.
# Recebe o conteúdo markdown via stdin ou como argumento (caminho do arquivo).
# Retorna 0 se válido, 1 se inválido.
validate_frontmatter() {
  local content="$1"

  # Verificar se começa com delimitador de frontmatter (---)
  local first_line
  first_line="$(echo "$content" | head -n 1)"
  if [[ "$first_line" != "---" ]]; then
    return 1
  fi

  # Extrair bloco frontmatter: tudo entre o primeiro e segundo ---
  local frontmatter
  frontmatter="$(echo "$content" | sed -n '2,/^---$/p' | sed '$d')"

  # Verificar se o frontmatter foi fechado (segundo --- encontrado)
  local closing_delimiter
  closing_delimiter="$(echo "$content" | sed -n '2,$p' | grep -n '^---$' | head -n 1)"
  if [[ -z "$closing_delimiter" ]]; then
    return 1
  fi

  # Extrair valor do campo inclusion
  local inclusion
  inclusion="$(echo "$frontmatter" | grep -E '^inclusion:\s*' | sed 's/^inclusion:\s*//' | tr -d '[:space:]')"

  # Verificar se inclusion está presente
  if [[ -z "$inclusion" ]]; then
    return 1
  fi

  # Verificar se inclusion tem valor válido
  if [[ "$inclusion" != "manual" && "$inclusion" != "auto" && "$inclusion" != "fileMatch" ]]; then
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

    # Verificar se está vazio após remoção de aspas
    if [[ -z "$pattern_value" ]]; then
      return 1
    fi
  fi

  return 0
}

# =============================================================================
# Property Test: frontmatter válido DEVE ser aceito (100 iterações)
# =============================================================================
@test "Property 2a: frontmatter válido é aceito pela validação (100 iterações)" {
  local i=0
  local failures=0

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(gen_frontmatter)"

    if ! validate_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: conteúdo gerado por gen_frontmatter rejeitado"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]]
}

# =============================================================================
# Property Test: frontmatter inválido DEVE ser rejeitado (100 iterações)
# =============================================================================
@test "Property 2b: frontmatter inválido é rejeitado pela validação (100 iterações)" {
  local i=0
  local failures=0

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(gen_invalid_frontmatter)"

    if validate_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: conteúdo inválido aceito pela validação"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]]
}

# =============================================================================
# Property Test: inclusion só aceita valores manual|auto|fileMatch (100 iter.)
# =============================================================================
@test "Property 2c: inclusion aceita somente manual, auto ou fileMatch (100 iterações)" {
  local valid_values=("manual" "auto" "fileMatch")
  local i=0
  local failures=0

  for (( i = 0; i < 100; i++ )); do
    # Gerar um valor aleatório para inclusion (válido ou inválido)
    local is_valid_case=$(( RANDOM % 2 ))

    if [[ ${is_valid_case} -eq 1 ]]; then
      # Caso válido: usar um dos valores válidos
      local val="${valid_values[$(( RANDOM % 3 ))]}"
      local content="---
inclusion: ${val}
---

# Test"

      # Se for fileMatch, precisa de fileMatchPattern
      if [[ "$val" == "fileMatch" ]]; then
        content="---
inclusion: fileMatch
fileMatchPattern: \"**/*.ts\"
---

# Test"
      fi

      if ! validate_frontmatter "$content"; then
        echo "FALHA iteração ${i}: valor válido '${val}' rejeitado"
        failures=$((failures + 1))
      fi
    else
      # Caso inválido: gerar valor aleatório que NÃO é válido
      local invalid_val
      invalid_val="$(_rand_choice "always" "never" "automatic" "file-match" "Manual" "AUTO" "FileMatch" "$(_rand_alpha 5)")"
      local content="---
inclusion: ${invalid_val}
---

# Test"

      if validate_frontmatter "$content"; then
        echo "FALHA iteração ${i}: valor inválido '${invalid_val}' aceito"
        failures=$((failures + 1))
      fi
    fi
  done

  [[ ${failures} -eq 0 ]]
}

# =============================================================================
# Property Test: fileMatch requer fileMatchPattern não-vazio (100 iterações)
# =============================================================================
@test "Property 2d: fileMatch exige fileMatchPattern presente e não-vazio (100 iterações)" {
  local patterns=("**/*.ts" "**/*.md" "**/package.json" "src/**/*.js" "**/*.yaml" "**/*.py" "docs/**/*.rst")
  local i=0
  local failures=0

  for (( i = 0; i < 100; i++ )); do
    local scenario=$(( RANDOM % 4 ))

    case ${scenario} in
      0)
        # fileMatch COM pattern válido → aceito
        local pat="${patterns[$(( RANDOM % ${#patterns[@]} ))]}"
        local content="---
inclusion: fileMatch
fileMatchPattern: \"${pat}\"
---

# Test ${i}"

        if ! validate_frontmatter "$content"; then
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

        if validate_frontmatter "$content"; then
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

        if validate_frontmatter "$content"; then
          echo "FALHA iteração ${i}: fileMatch com pattern vazio aceito"
          failures=$((failures + 1))
        fi
        ;;
      3)
        # manual ou auto SEM fileMatchPattern → aceito (não requer pattern)
        local val
        val="$(_rand_choice "manual" "auto")"
        local content="---
inclusion: ${val}
---

# Test ${i}"

        if ! validate_frontmatter "$content"; then
          echo "FALHA iteração ${i}: '${val}' sem pattern rejeitado"
          failures=$((failures + 1))
        fi
        ;;
    esac
  done

  [[ ${failures} -eq 0 ]]
}
