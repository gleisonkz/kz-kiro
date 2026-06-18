#!/usr/bin/env bats
# =============================================================================
# Property 2: Frontmatter YAML válido nos steering files
# Feature: archetype-mobile-flutter, Property 2: Frontmatter YAML válido
# =============================================================================
# Para qualquer arquivo .md no diretório steering/ do archetype mobile-flutter
# (excluindo README.md), o conteúdo SHALL iniciar com delimitadores --- contendo
# frontmatter YAML válido que inclui obrigatoriamente o campo inclusion com
# valor pertencente ao conjunto {always, fileMatch, auto, manual}. Quando
# inclusion é auto, os campos name (string não-vazia) e description
# (string não-vazia) SHALL estar presentes. Quando inclusion é fileMatch, o
# campo fileMatchPattern (string ou array de strings) SHALL estar presente.
#
# **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8**
# 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
  load '../helpers/assertions'
}

teardown() {
  cleanup_fixtures
}

# --- Caminho do archetype real ---
ARCHETYPE_STEERING_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter/steering"

# --- Valores válidos para o campo inclusion ---
VALID_INCLUSIONS=("always" "fileMatch" "auto" "manual")

# --- Função de validação de frontmatter para mobile-flutter ---
# Regras:
#   1. Arquivo começa com --- (primeira linha)
#   2. Tem um delimitador de fechamento ---
#   3. Tem campo inclusion com valor em {always, fileMatch, auto, manual}
#   4. Quando inclusion é auto: name e description não-vazios presentes
#   5. Quando inclusion é fileMatch: fileMatchPattern não-vazio presente
# Recebe conteúdo como argumento.
# Retorna 0 se válido, 1 se inválido.
validate_flutter_frontmatter() {
  local content="$1"

  # 1. Verificar que a primeira linha é exatamente ---
  local first_line
  first_line="$(echo "$content" | head -n 1)"
  if [[ "$first_line" != "---" ]]; then
    return 1
  fi

  # 2. Verificar delimitador de fechamento --- (a partir da linha 2)
  local closing_delimiter
  closing_delimiter="$(echo "$content" | sed -n '2,$p' | grep -n '^---$' | head -n 1)"
  if [[ -z "$closing_delimiter" ]]; then
    return 1
  fi

  # Extrair bloco frontmatter: tudo entre o primeiro e segundo ---
  local frontmatter
  frontmatter="$(echo "$content" | sed -n '2,/^---$/p' | sed '$d')"

  # 3. Extrair valor do campo inclusion
  local inclusion
  inclusion="$(echo "$frontmatter" | grep -E '^inclusion:\s*' | sed 's/^inclusion:\s*//' | tr -d '[:space:]')"

  # Verificar se inclusion está presente
  if [[ -z "$inclusion" ]]; then
    return 1
  fi

  # Verificar se inclusion tem valor válido: always, fileMatch, auto, manual
  if [[ "$inclusion" != "always" && "$inclusion" != "fileMatch" && "$inclusion" != "auto" && "$inclusion" != "manual" ]]; then
    return 1
  fi

  # 4. Quando inclusion é auto: name e description devem estar presentes
  #    (auto requer identificação para carregamento contextual pelo Kiro;
  #     manual é ativado explicitamente pelo usuário sem necessidade de metadata)
  if [[ "$inclusion" == "auto" ]]; then
    local name_line
    name_line="$(echo "$frontmatter" | grep -E '^name:\s*' || true)"
    if [[ -z "$name_line" ]]; then
      return 1
    fi
    # Extrair valor de name
    local name_value
    name_value="$(echo "$name_line" | sed 's/^name:\s*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"
    if [[ -z "$name_value" ]]; then
      return 1
    fi

    local desc_line
    desc_line="$(echo "$frontmatter" | grep -E '^description:\s*' || true)"
    if [[ -z "$desc_line" ]]; then
      return 1
    fi
    # Extrair valor de description
    local desc_value
    desc_value="$(echo "$desc_line" | sed 's/^description:\s*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"
    if [[ -z "$desc_value" ]]; then
      return 1
    fi
  fi

  # 5. Quando inclusion é fileMatch: fileMatchPattern deve estar presente e não-vazio
  if [[ "$inclusion" == "fileMatch" ]]; then
    local pattern_line
    pattern_line="$(echo "$frontmatter" | grep -E '^fileMatchPattern:' || true)"
    if [[ -z "$pattern_line" ]]; then
      return 1
    fi
    local pattern_value
    pattern_value="$(echo "$pattern_line" | sed 's/^fileMatchPattern:\s*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"
    if [[ -z "$pattern_value" ]]; then
      return 1
    fi
  fi

  return 0
}

# --- Gerador: frontmatter válido para mobile-flutter ---
# Gera frontmatter aleatório respeitando todas as regras de validação.
gen_valid_flutter_frontmatter() {
  local inclusion
  inclusion="$(_rand_choice "always" "fileMatch" "auto" "manual")"

  local content="---\ninclusion: ${inclusion}"

  case "$inclusion" in
    always)
      # Apenas inclusion, sem campos extras obrigatórios
      ;;
    fileMatch)
      local pattern
      pattern="$(_rand_choice "**/*.dart" "**/*_test.dart" "**/pubspec.yaml" "**/*.md" "src/**/*.ts" "**/lib/**/*.dart")"
      content="${content}\nfileMatchPattern: \"${pattern}\""
      ;;
    auto)
      local name
      name="$(_rand_lower "$(_rand_int 4 12)")-$(_rand_lower "$(_rand_int 3 8)")"
      local desc
      desc="Use when working with $(_rand_alpha "$(_rand_int 10 30)") and related patterns"
      content="${content}\nname: ${name}\ndescription: ${desc}"
      ;;
    manual)
      # manual não requer name/description (ativação explícita pelo usuário)
      # Opcionalmente pode ou não ter esses campos
      if (( RANDOM % 2 == 0 )); then
        local name
        name="$(_rand_lower "$(_rand_int 4 12)")-$(_rand_lower "$(_rand_int 3 8)")"
        local desc
        desc="Checklist for $(_rand_alpha "$(_rand_int 8 20)") review process"
        content="${content}\nname: ${name}\ndescription: ${desc}"
      fi
      ;;
  esac

  content="${content}\n---\n\n# $(_rand_alpha "$(_rand_int 5 15)")\n\nConteúdo gerado para teste.\n"

  printf '%b' "$content"
}

# --- Gerador: frontmatter inválido para mobile-flutter ---
# Estratégias de invalidação:
#   0 - Sem delimitadores ---
#   1 - Campo inclusion ausente
#   2 - Valor de inclusion inválido
#   3 - auto sem name
#   4 - auto sem description
#   5 - fileMatch sem fileMatchPattern
#   6 - fileMatchPattern vazio com fileMatch
#   7 - Sem delimitador de fechamento ---
gen_invalid_flutter_frontmatter() {
  local strategy
  strategy=$(_rand_int 0 7)

  case "$strategy" in
    0) # Sem delimitadores ---
      printf '%b' "inclusion: auto\nname: test\ndescription: test desc\n\n# Título sem frontmatter"
      ;;
    1) # Campo inclusion ausente
      printf '%b' "---\nname: $(_rand_lower 6)\ndescription: algo descritivo\n---\n\n# Sem inclusion"
      ;;
    2) # Valor de inclusion inválido
      local invalid_val
      invalid_val="$(_rand_choice "alwayss" "file_match" "automatic" "manuall" "ALWAYS" "FileMatch" "never" "$(_rand_alpha "$(_rand_int 3 8)")")"
      printf '%b' "---\ninclusion: ${invalid_val}\n---\n\n# Inclusion inválido"
      ;;
    3) # auto sem name
      printf '%b' "---\ninclusion: auto\ndescription: Alguma descricao valida\n---\n\n# Sem name"
      ;;
    4) # auto sem description
      printf '%b' "---\ninclusion: auto\nname: $(_rand_lower 6)-$(_rand_lower 4)\n---\n\n# Sem description"
      ;;
    5) # fileMatch sem fileMatchPattern
      printf '%b' "---\ninclusion: fileMatch\n---\n\n# Sem fileMatchPattern"
      ;;
    6) # fileMatchPattern vazio com fileMatch
      printf '%b' "---\ninclusion: fileMatch\nfileMatchPattern: \"\"\n---\n\n# Pattern vazio"
      ;;
    7) # Sem delimitador de fechamento ---
      printf '%b' "---\ninclusion: always\n\n# Sem fechamento de frontmatter"
      ;;
  esac
}

# =============================================================================
# Property Test: 100 frontmatters válidos DEVEM ser aceitos
# =============================================================================
@test "Property 2a: frontmatter válido do mobile-flutter é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(gen_valid_flutter_frontmatter)"

    if ! validate_flutter_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter válido rejeitado"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 frontmatters válidos"
}

# =============================================================================
# Property Test: 100 frontmatters inválidos DEVEM ser rejeitados
# =============================================================================
@test "Property 2b: frontmatter inválido do mobile-flutter é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(gen_invalid_flutter_frontmatter)"

    if validate_flutter_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter inválido aceito pela validação"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 frontmatters inválidos"
}

# =============================================================================
# Property Test: Todos os 15 steering files reais DEVEM passar na validação
# =============================================================================
@test "Property 2c: todos os 15 steering files reais do archetype mobile-flutter passam na validação" {
  local failures=0
  local expected_files=(
    "coding-standards.md"
    "flutter_best_practices.md"
    "clean-architecture.md"
    "flutter-clean-architecture.md"
    "flutter-lints-security.md"
    "flutter-testing-patterns.md"
    "dependency-management.md"
    "design-system.md"
    "code-review.md"
    "auth-api.md"
    "forgot-password-api.md"
    "home-api.md"
    "notifications-api.md"
    "profile-api.md"
    "settings-api.md"
  )

  local file
  for file in "${expected_files[@]}"; do
    local filepath="${ARCHETYPE_STEERING_DIR}/${file}"

    if [[ ! -f "$filepath" ]]; then
      echo "FALHA: arquivo ${file} não encontrado em ${ARCHETYPE_STEERING_DIR}"
      failures=$((failures + 1))
      continue
    fi

    local content
    content="$(cat "$filepath")"

    if ! validate_flutter_frontmatter "$content"; then
      echo "FALHA: steering file real '${file}' rejeitado pela validação"
      echo "Primeiras 6 linhas:"
      head -n 6 "$filepath"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/15 steering files reais"
}
