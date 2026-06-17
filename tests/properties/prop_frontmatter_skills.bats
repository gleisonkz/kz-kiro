#!/usr/bin/env bats
# =============================================================================
# Property: Frontmatter de skills
# Feature: archetype-frontend-react, Property 6: Frontmatter de skills
# Feature: archetype-bff-fastify, Property 4: Frontmatter de skills
# Feature: archetype-backend-csharp, Property 4: Frontmatter de skills
# =============================================================================
# Para qualquer arquivo .md no diretório skills/ (excluindo README.md), o
# frontmatter YAML SHALL conter exatamente os campos name (string não-vazia),
# description (string não-vazia) e inclusion com valor "manual".
#
# **Validates: Requirements 8.8 (frontend-react), Requirements 7.4 (bff-fastify), Requirements 8.6 (backend-csharp)**
# Mínimo 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
  load '../lib/bats-assert/load'
  load '../lib/bats-support/load'
}

teardown() {
  cleanup_fixtures
}

# --- Função de validação de frontmatter de skills ---
# Implementa a lógica de validação conforme Property 6 do design document.
# Recebe conteúdo markdown como argumento.
# Retorna 0 se válido, 1 se inválido.
validate_skill_frontmatter() {
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

  # Extrair valor do campo name (suporta aspas duplas ao redor)
  local name_line name_value
  name_line="$(echo "$frontmatter" | grep -E '^name:' || true)"
  if [[ -z "$name_line" ]]; then
    return 1
  fi
  name_value="$(echo "$name_line" | sed 's/^name:[[:space:]]*//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"
  # Verificar que name não está vazio
  local trimmed_name
  trimmed_name="$(echo "$name_value" | tr -d '[:space:]')"
  if [[ -z "$trimmed_name" ]]; then
    return 1
  fi

  # Extrair valor do campo description (suporta aspas duplas ao redor)
  local desc_line desc_value
  desc_line="$(echo "$frontmatter" | grep -E '^description:' || true)"
  if [[ -z "$desc_line" ]]; then
    return 1
  fi
  desc_value="$(echo "$desc_line" | sed 's/^description:[[:space:]]*//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"
  # Verificar que description não está vazio
  local trimmed_desc
  trimmed_desc="$(echo "$desc_value" | tr -d '[:space:]')"
  if [[ -z "$trimmed_desc" ]]; then
    return 1
  fi

  # Extrair valor do campo inclusion
  local inclusion_line inclusion_value
  inclusion_line="$(echo "$frontmatter" | grep -E '^inclusion:' || true)"
  if [[ -z "$inclusion_line" ]]; then
    return 1
  fi
  inclusion_value="$(echo "$inclusion_line" | sed 's/^inclusion:[[:space:]]*//' | tr -d '[:space:]')"
  # Verificar que inclusion é exatamente "manual"
  if [[ "$inclusion_value" != "manual" ]]; then
    return 1
  fi

  return 0
}

# --- Gerador de frontmatter válido de skill ---
_gen_valid_skill_frontmatter() {
  local name description body_title

  # Gerar nome exibível realista em português
  name=$(_rand_choice \
    "Gerar Componente React" \
    "Gerar Hook Customizado" \
    "Gerar Redux Slice" \
    "Gerar Endpoint API" \
    "Gerar Página React" \
    "Gerar Módulo FSD" \
    "Gerar Context Provider" \
    "Gerar Formulário" \
    "Gerar Serviço" \
    "Gerar Teste Unitário")

  # Gerar descrição realista
  description=$(_rand_choice \
    "Cria um componente React seguindo padrões FSD e tipagem strict." \
    "Gera hook customizado com testes e nomenclatura padronizada." \
    "Cria slice Redux com selectors, testes e barrel export." \
    "Gera endpoint RTK Query com tipagem completa e cache." \
    "Cria página com tratamento de 4 estados e landmarks semânticos." \
    "Gera estrutura completa de módulo com diretórios FSD." \
    "Cria React Context com Provider tipado e hook de leitura." \
    "Gera formulário acessível com validação e testes." \
    "Cria serviço com interface tipada e testes unitários." \
    "Gera suite de testes para componente ou hook existente.")

  body_title="$(_rand_alpha "$(_rand_int 8 20)")"

  cat <<EOF
---
name: "${name}"
description: "${description}"
inclusion: manual
---

# ${body_title}

## Quando usar

Conteúdo gerado para teste de propriedade.

## Inputs esperados

- Parâmetro $(_rand_alpha 5)

## Regras de geração

Regras $(_rand_alpha "$(_rand_int 10 30)")
EOF
}

# --- Gerador de frontmatter INVÁLIDO de skill ---
_gen_invalid_skill_frontmatter() {
  local strategy
  strategy=$(_rand_int 0 8)

  case ${strategy} in
    0)
      # Sem frontmatter (sem delimitadores ---)
      echo "# Skill sem frontmatter"
      echo ""
      echo "Conteúdo sem YAML frontmatter."
      ;;
    1)
      # Campo name ausente
      printf '%b\n' "---\ndescription: \"Gera algo útil\"\ninclusion: manual\n---\n\n# Teste"
      ;;
    2)
      # Campo description ausente
      printf '%b\n' "---\nname: \"Gerar Algo\"\ninclusion: manual\n---\n\n# Teste"
      ;;
    3)
      # Campo inclusion ausente
      printf '%b\n' "---\nname: \"Gerar Algo\"\ndescription: \"Gera algo útil\"\n---\n\n# Teste"
      ;;
    4)
      # inclusion com valor diferente de manual (auto)
      local invalid_inclusion
      invalid_inclusion=$(_rand_choice "auto" "fileMatch" "automatic" "always" "on" "$(_rand_alpha 5)")
      printf '%b\n' "---\nname: \"Gerar Algo\"\ndescription: \"Gera algo útil\"\ninclusion: ${invalid_inclusion}\n---\n\n# Teste"
      ;;
    5)
      # name vazio
      printf '%b\n' "---\nname: \"\"\ndescription: \"Gera algo útil\"\ninclusion: manual\n---\n\n# Teste"
      ;;
    6)
      # description vazio
      printf '%b\n' "---\nname: \"Gerar Algo\"\ndescription: \"\"\ninclusion: manual\n---\n\n# Teste"
      ;;
    7)
      # Delimitador de abertura sem fechamento
      printf '%b\n' "---\nname: \"Gerar Algo\"\ndescription: \"Gera algo útil\"\ninclusion: manual\n\n# Sem fechamento"
      ;;
    8)
      # name com apenas espaços
      printf '%b\n' "---\nname: \"   \"\ndescription: \"Gera algo útil\"\ninclusion: manual\n---\n\n# Teste"
      ;;
  esac
}

# =============================================================================
# Property Test 6a: frontmatter válido de skill DEVE ser aceito (100 iterações)
# =============================================================================
@test "Property 6a: frontmatter válido de skill é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(_gen_valid_skill_frontmatter)"

    if ! validate_skill_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter válido rejeitado"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 frontmatters válidos de skill"
}

# =============================================================================
# Property Test 6b: frontmatter inválido de skill DEVE ser rejeitado (100 iterações)
# =============================================================================
@test "Property 6b: frontmatter inválido de skill é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local content
    content="$(_gen_invalid_skill_frontmatter)"

    if validate_skill_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter inválido aceito"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 frontmatters inválidos de skill"
}

# =============================================================================
# Property Test 6c: validação exige exatamente name, description e inclusion:manual (100 iterações)
# =============================================================================
@test "Property 6c: validação exige os 3 campos obrigatórios com valores corretos (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local is_valid_case=$(( RANDOM % 2 ))

    if [[ ${is_valid_case} -eq 1 ]]; then
      # Caso válido: todos os campos presentes e corretos
      local content
      content="$(_gen_valid_skill_frontmatter)"

      if ! validate_skill_frontmatter "$content"; then
        echo "FALHA iteração ${i}: frontmatter válido rejeitado"
        echo "Conteúdo:"
        echo "$content"
        failures=$((failures + 1))
      fi
    else
      # Caso inválido: remover ou invalidar um campo aleatoriamente
      local missing_field
      missing_field=$(_rand_choice "name" "description" "inclusion")

      local content
      case "$missing_field" in
        "name")
          content="---
description: \"Gera $(_rand_alpha 8)\"
inclusion: manual
---

# Test ${i}"
          ;;
        "description")
          content="---
name: \"Gerar $(_rand_alpha 8)\"
inclusion: manual
---

# Test ${i}"
          ;;
        "inclusion")
          content="---
name: \"Gerar $(_rand_alpha 8)\"
description: \"Gera $(_rand_alpha 8) seguindo padrões\"
---

# Test ${i}"
          ;;
      esac

      if validate_skill_frontmatter "$content"; then
        echo "FALHA iteração ${i}: frontmatter sem campo '${missing_field}' aceito"
        echo "Conteúdo:"
        echo "$content"
        failures=$((failures + 1))
      fi
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação falhou em ${failures}/100 iterações"
}

# =============================================================================
# Property Test 6d: todos os skills reais do archetype TÊM frontmatter válido
# =============================================================================
@test "Property 6d: todos os skills do archetype frontend-react possuem frontmatter válido" {
  local skills_dir="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react/skills"
  local failures=0

  # Percorrer todos os .md no diretório de skills (excluindo README.md)
  for skill_file in "${skills_dir}"/*.md; do
    [[ -f "${skill_file}" ]] || continue

    local filename
    filename="$(basename "${skill_file}")"
    # Pular README.md
    [[ "${filename}" == "README.md" ]] && continue

    local content
    content="$(cat "${skill_file}")"

    if ! validate_skill_frontmatter "${content}"; then
      echo "FALHA: ${filename} não possui frontmatter válido (name + description + inclusion: manual)"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "${failures} skills do archetype não possuem frontmatter válido"
}


# =============================================================================
# Property Test 4 (bff-fastify): todos os skills do archetype bff-fastify possuem frontmatter válido
# **Validates: Requirements 7.4**
# =============================================================================
@test "Property 4 (bff-fastify): todos os skills do archetype bff-fastify possuem frontmatter válido" {
  local skills_dir="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify/skills"
  local failures=0
  local skill_count=0

  # Percorrer todos os .md no diretório de skills (excluindo README.md)
  for skill_file in "${skills_dir}"/*.md; do
    [[ -f "${skill_file}" ]] || continue

    local filename
    filename="$(basename "${skill_file}")"
    # Pular README.md
    [[ "${filename}" == "README.md" ]] && continue

    skill_count=$((skill_count + 1))

    local content
    content="$(cat "${skill_file}")"

    if ! validate_skill_frontmatter "${content}"; then
      echo "FALHA: ${filename} não possui frontmatter válido (name + description + inclusion: manual)"
      failures=$((failures + 1))
    fi
  done

  # Verificar que ao menos 3 skills existem (generate-module, generate-client, generate-plugin)
  [[ ${skill_count} -ge 3 ]] || fail "Esperado ao menos 3 skills no archetype bff-fastify, encontrado: ${skill_count}"
  [[ ${failures} -eq 0 ]] || fail "${failures}/${skill_count} skills do archetype bff-fastify não possuem frontmatter válido"
}


# =============================================================================
# Property Test 4 (backend-csharp): todos os skills do archetype backend-csharp possuem frontmatter válido
# **Validates: Requirements 8.6**
# =============================================================================
@test "Property 4 (backend-csharp): todos os skills do archetype backend-csharp possuem frontmatter válido" {
  local skills_dir="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/skills"
  local failures=0
  local skill_count=0

  # Percorrer todos os .md no diretório de skills (excluindo README.md)
  for skill_file in "${skills_dir}"/*.md; do
    [[ -f "${skill_file}" ]] || continue

    local filename
    filename="$(basename "${skill_file}")"
    # Pular README.md
    [[ "${filename}" == "README.md" ]] && continue

    skill_count=$((skill_count + 1))

    local content
    content="$(cat "${skill_file}")"

    if ! validate_skill_frontmatter "${content}"; then
      echo "FALHA: ${filename} não possui frontmatter válido (name + description + inclusion: manual)"
      failures=$((failures + 1))
    fi
  done

  # Verificar que ao menos 5 skills existem (generate-module, generate-endpoint, generate-repository, generate-data-model, generate-validation-package)
  [[ ${skill_count} -ge 5 ]] || fail "Esperado ao menos 5 skills no archetype backend-csharp, encontrado: ${skill_count}"
  [[ ${failures} -eq 0 ]] || fail "${failures}/${skill_count} skills do archetype backend-csharp não possuem frontmatter válido"
}
