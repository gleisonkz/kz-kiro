#!/usr/bin/env bats
# =============================================================================
# Property 5: Frontmatter de agents
# Feature: archetype-frontend-react, Property 5: Frontmatter de agents
# =============================================================================
# Para qualquer arquivo .md no diretório agents/ (excluindo README.md), o
# frontmatter YAML SHALL conter os campos name (string não-vazia) e description
# (string não-vazia), e o corpo SHALL conter uma seção ## Referências.
#
# **Validates: Requirements 7.5, 7.6**
# Mínimo 20 iterações por property test.

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

# --- Função de validação de frontmatter de agents ---
# Implementa a lógica de validação conforme Property 5 do design document.
# Recebe conteúdo markdown como argumento.
# Retorna 0 se válido, 1 se inválido.
validate_agent_frontmatter() {
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

  # Extrair valor do campo name
  local name_line
  name_line="$(echo "$frontmatter" | grep -E '^name:\s*' || true)"

  # Campo name ausente
  if [[ -z "$name_line" ]]; then
    return 1
  fi

  # Extrair valor de name (removendo aspas)
  local name_value
  name_value="$(echo "$name_line" | sed 's/^name:\s*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"

  # Verificar se name não é vazio
  if [[ -z "$name_value" ]]; then
    return 1
  fi

  # Extrair valor do campo description
  local desc_line
  desc_line="$(echo "$frontmatter" | grep -E '^description:\s*' || true)"

  # Campo description ausente
  if [[ -z "$desc_line" ]]; then
    return 1
  fi

  # Extrair valor de description (removendo aspas)
  local desc_value
  desc_value="$(echo "$desc_line" | sed 's/^description:\s*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")"

  # Verificar se description não é vazio
  if [[ -z "$desc_value" ]]; then
    return 1
  fi

  # Verificar presença de seção ## Referências no corpo (após o frontmatter)
  local body
  body="$(echo "$content" | sed '1,/^---$/!d' | wc -l)"
  # Pegar conteúdo após o segundo ---
  local after_frontmatter
  after_frontmatter="$(echo "$content" | sed -n '/^---$/,$ p' | sed -n '2,$ p' | sed -n '/^---$/,$ p' | sed -n '2,$ p')"

  # Verificar se ## Referências existe no corpo
  if ! echo "$after_frontmatter" | grep -q '^## Referências'; then
    return 1
  fi

  return 0
}

# --- Geradores específicos para agents ---

# Gera um frontmatter válido de agent com seção ## Referências
_gen_valid_agent_frontmatter() {
  local scenario
  scenario=$(( RANDOM % 4 ))

  local name description body

  case ${scenario} in
    0)
      # Estilo accessibility-reviewer
      name="Revisor de Acessibilidade $(_rand_alpha 4)"
      description="Agente especializado em $(_rand_alpha "$(_rand_int 10 30)") para revisão de conformidade."
      body="## Papel\n\nVocê é um especialista em $(_rand_alpha 10).\n\n## O que revisar\n\n- Item $(_rand_alpha 5)\n- Item $(_rand_alpha 5)\n\n## Referências\n\n- [steering/architecture.md](../steering/architecture.md)\n- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)"
      ;;
    1)
      # Estilo architecture-reviewer
      name="$(_rand_alpha "$(_rand_int 5 15)")"
      description="$(_rand_alpha "$(_rand_int 20 60)")"
      body="## Contexto\n\n$(_rand_alpha 30)\n\n## Formato de resposta\n\nTabela com campos.\n\n## Referências\n\n- [Link relevante](url)"
      ;;
    2)
      # Nome e descrição curtos mas válidos
      name="$(_rand_alpha "$(_rand_int 3 8)")"
      description="$(_rand_alpha "$(_rand_int 5 15)")"
      body="# Título\n\n## Papel\n\nTexto.\n\n## Referências\n\n- Ref 1"
      ;;
    3)
      # Descrição longa (>200 chars, válido mas gera warning)
      name="Revisor de $(_rand_alpha 8)"
      description="$(_rand_alpha 210)"
      body="## O que revisar\n\n$(_rand_alpha 50)\n\n## Referências\n\n- [steering/stack-and-tooling.md](../steering/stack-and-tooling.md)"
      ;;
  esac

  printf '%b\n' "---\nname: \"${name}\"\ndescription: \"${description}\"\n---\n\n${body}"
}

# Gera um frontmatter INVÁLIDO para agent
_gen_invalid_agent_frontmatter() {
  local strategy
  strategy=$(( RANDOM % 8 ))

  case ${strategy} in
    0)
      # Sem frontmatter (sem delimitadores ---)
      echo "# Agent sem frontmatter"
      echo ""
      echo "## Referências"
      echo "- Ref"
      ;;
    1)
      # name ausente
      printf '%b\n' "---\ndescription: \"$(_rand_alpha 20)\"\n---\n\n# Agent\n\n## Referências\n\n- Ref"
      ;;
    2)
      # description ausente
      printf '%b\n' "---\nname: \"$(_rand_alpha 10)\"\n---\n\n# Agent\n\n## Referências\n\n- Ref"
      ;;
    3)
      # name vazio
      printf '%b\n' "---\nname: \"\"\ndescription: \"$(_rand_alpha 20)\"\n---\n\n# Agent\n\n## Referências\n\n- Ref"
      ;;
    4)
      # description vazio
      printf '%b\n' "---\nname: \"$(_rand_alpha 10)\"\ndescription: \"\"\n---\n\n# Agent\n\n## Referências\n\n- Ref"
      ;;
    5)
      # Sem seção ## Referências no corpo
      printf '%b\n' "---\nname: \"$(_rand_alpha 10)\"\ndescription: \"$(_rand_alpha 20)\"\n---\n\n# Agent\n\n## Papel\n\nTexto sem referências."
      ;;
    6)
      # Delimitador de abertura sem fechamento
      printf '%b\n' "---\nname: \"$(_rand_alpha 10)\"\ndescription: \"$(_rand_alpha 20)\"\n\n# Agent sem fechar frontmatter\n\n## Referências\n\n- Ref"
      ;;
    7)
      # Ambos name e description ausentes
      printf '%b\n' "---\ninclusion: auto\n---\n\n# Agent\n\n## Referências\n\n- Ref"
      ;;
  esac
}

# =============================================================================
# Property Test 5a: frontmatter válido de agent DEVE ser aceito (20 iterações)
# =============================================================================
@test "Property 5a: frontmatter válido de agent é aceito pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local content
    content="$(_gen_valid_agent_frontmatter)"

    if ! validate_agent_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter válido rejeitado"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/20 agents com frontmatter válido"
}

# =============================================================================
# Property Test 5b: frontmatter inválido de agent DEVE ser rejeitado (20 iterações)
# =============================================================================
@test "Property 5b: frontmatter inválido de agent é rejeitado pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local content
    content="$(_gen_invalid_agent_frontmatter)"

    if validate_agent_frontmatter "$content"; then
      echo "FALHA na iteração ${i}: frontmatter inválido aceito"
      echo "Conteúdo:"
      echo "$content"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 agents com frontmatter inválido"
}

# =============================================================================
# Property Test 5c: validação exige name E description não-vazios (20 iterações)
# =============================================================================
@test "Property 5c: validação exige name e description não-vazios (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local is_valid_case=$(( RANDOM % 2 ))

    if [[ ${is_valid_case} -eq 1 ]]; then
      # Caso válido: ambos name e description são strings não-vazias + ## Referências
      local name="$(_rand_alpha "$(_rand_int 3 20)")"
      local desc="$(_rand_alpha "$(_rand_int 10 50)")"
      local content
      content="$(printf '%b\n' "---\nname: \"${name}\"\ndescription: \"${desc}\"\n---\n\n# Agent ${name}\n\n## Referências\n\n- Ref")"

      if ! validate_agent_frontmatter "$content"; then
        echo "FALHA iteração ${i}: name='${name}' desc='${desc}' rejeitado"
        failures=$((failures + 1))
      fi
    else
      # Caso inválido: name ou description é vazio/ausente
      local invalid_scenario=$(( RANDOM % 4 ))
      local content

      case ${invalid_scenario} in
        0) # name vazio
          content="$(printf '%b\n' "---\nname: \"\"\ndescription: \"$(_rand_alpha 15)\"\n---\n\n# Agent\n\n## Referências\n\n- Ref")"
          ;;
        1) # description vazio
          content="$(printf '%b\n' "---\nname: \"$(_rand_alpha 10)\"\ndescription: \"\"\n---\n\n# Agent\n\n## Referências\n\n- Ref")"
          ;;
        2) # name ausente
          content="$(printf '%b\n' "---\ndescription: \"$(_rand_alpha 15)\"\n---\n\n# Agent\n\n## Referências\n\n- Ref")"
          ;;
        3) # description ausente
          content="$(printf '%b\n' "---\nname: \"$(_rand_alpha 10)\"\n---\n\n# Agent\n\n## Referências\n\n- Ref")"
          ;;
      esac

      if validate_agent_frontmatter "$content"; then
        echo "FALHA iteração ${i}: frontmatter com campo vazio/ausente aceito"
        echo "Conteúdo: $content"
        failures=$((failures + 1))
      fi
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação falhou em ${failures}/20 iterações"
}

# =============================================================================
# Property Test 5d: validação exige seção ## Referências no corpo (20 iterações)
# =============================================================================
@test "Property 5d: validação exige seção Referências no corpo (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local has_refs=$(( RANDOM % 2 ))
    local name="$(_rand_alpha "$(_rand_int 5 15)")"
    local desc="$(_rand_alpha "$(_rand_int 10 40)")"

    if [[ ${has_refs} -eq 1 ]]; then
      # Com ## Referências → deve ser aceito
      local content
      content="$(printf '%b\n' "---\nname: \"${name}\"\ndescription: \"${desc}\"\n---\n\n# Agent ${name}\n\n## Papel\n\nTexto.\n\n## Referências\n\n- [Link](url)")"

      if ! validate_agent_frontmatter "$content"; then
        echo "FALHA iteração ${i}: agent com ## Referências rejeitado"
        failures=$((failures + 1))
      fi
    else
      # Sem ## Referências → deve ser rejeitado
      local content
      content="$(printf '%b\n' "---\nname: \"${name}\"\ndescription: \"${desc}\"\n---\n\n# Agent ${name}\n\n## Papel\n\nTexto sem referências.\n\n## Contexto\n\nOutra seção.")"

      if validate_agent_frontmatter "$content"; then
        echo "FALHA iteração ${i}: agent sem ## Referências aceito"
        failures=$((failures + 1))
      fi
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação falhou em ${failures}/20 iterações"
}

# =============================================================================
# Property Test 5e: todos os agents reais do archetype SÃO válidos
# =============================================================================
@test "Property 5e: todos os agents do archetype frontend-react possuem frontmatter válido" {
  local agents_dir="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react/agents"
  local failures=0

  # Percorrer todos os .md no diretório de agents (excluindo README.md)
  for agent_file in "${agents_dir}"/*.md; do
    [[ -f "${agent_file}" ]] || continue
    [[ "$(basename "${agent_file}")" == "README.md" ]] && continue

    local content
    content="$(cat "${agent_file}")"

    if ! validate_agent_frontmatter "${content}"; then
      echo "FALHA: ${agent_file##*/} não possui frontmatter válido de agent"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "${failures} agents do archetype não possuem frontmatter válido"
}
