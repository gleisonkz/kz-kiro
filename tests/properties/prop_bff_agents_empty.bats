#!/usr/bin/env bats
# =============================================================================
# Property 8: Ausência de agents funcionais
# Feature: archetype-bff-fastify, Property 8: Ausência de agents funcionais
# =============================================================================
# Para qualquer arquivo no diretório agents/ do archetype bff-fastify, se o
# arquivo não for README.md, então ele SHALL não existir (ou seja, o único
# arquivo permitido é README.md).
#
# **Validates: Requirements 9.1, 9.2**
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

# --- Função de validação: ausência de agents funcionais ---
# Regras:
#   - Diretório agents/ deve existir
#   - README.md deve existir em agents/
#   - Nenhum outro arquivo deve existir em agents/ (apenas README.md é permitido)
# Retorna 0 se válido (apenas README.md), 1 se inválido (extra files existem).
validate_agents_empty() {
  local agents_dir="$1"

  # Diretório agents/ deve existir
  if [[ ! -d "$agents_dir" ]]; then
    return 1
  fi

  # README.md deve existir em agents/
  if [[ ! -f "${agents_dir}/README.md" ]]; then
    return 1
  fi

  # Nenhum outro arquivo deve existir além de README.md
  local file_count=0
  local file
  for file in "${agents_dir}/"*; do
    [[ ! -e "$file" ]] && continue
    if [[ "$(basename "$file")" != "README.md" ]]; then
      file_count=$((file_count + 1))
    fi
  done

  if [[ ${file_count} -gt 0 ]]; then
    return 1
  fi

  return 0
}

# --- Gerador: cria diretório agents/ válido (apenas README.md) ---
gen_valid_agents_dir() {
  local agents_dir
  agents_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-agents-XXXXXX")"
  echo "${agents_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # Apenas README.md — conteúdo similar ao real
  cat > "${agents_dir}/README.md" <<'EOF'
# Agents

Diretório de agents especializados do archetype bff-fastify.

## Agents Planejados

| Agent | Especialidade | Status |
|-------|--------------|--------|
| bff-architect | Design de módulos e padrões de agregação | Não implementado |
| bff-api-designer | Design de contratos e DX para frontend | Não implementado |
| bff-resilience-reviewer | Circuit breakers, timeouts, retry, logs, tracing | Não implementado |
| bff-test-writer | Geração de testes unitários e de integração | Não implementado |
EOF

  echo "${agents_dir}"
}

# --- Gerador: cria diretório agents/ inválido (README.md + arquivos extras) ---
# Estratégias de invalidação:
#   0 - Adicionar arquivos .md extras (simulando agents funcionais)
#   1 - Adicionar arquivos .yaml
#   2 - Adicionar arquivos com extensões aleatórias
#   3 - Adicionar múltiplos arquivos extras de tipos variados
gen_invalid_agents_dir() {
  local agents_dir
  agents_dir="$(gen_valid_agents_dir)"

  local strategy
  strategy=$(_rand_int 0 3)

  case ${strategy} in
    0)
      # Adicionar 1-3 arquivos .md extras (simulando agents funcionais)
      local num_extras
      num_extras=$(_rand_int 1 3)
      local i
      for (( i = 0; i < num_extras; i++ )); do
        local agent_name="$(_rand_lower "$(_rand_int 5 15)")-agent"
        cat > "${agents_dir}/${agent_name}.md" <<AGENTEOF
---
name: "${agent_name}"
description: "Agent funcional de teste"
inclusion: auto
---

# ${agent_name}

Agent de teste que não deveria existir.
AGENTEOF
      done
      ;;
    1)
      # Adicionar 1-2 arquivos .yaml
      local num_yaml
      num_yaml=$(_rand_int 1 2)
      local i
      for (( i = 0; i < num_yaml; i++ )); do
        local yaml_name="$(_rand_lower "$(_rand_int 4 10)")"
        echo "config: true" > "${agents_dir}/${yaml_name}.yaml"
      done
      ;;
    2)
      # Adicionar 1-3 arquivos com extensões aleatórias
      local num_rand
      num_rand=$(_rand_int 1 3)
      local i
      for (( i = 0; i < num_rand; i++ )); do
        local ext
        ext=$(_rand_choice "txt" "json" "ts" "js" "toml" "cfg" "hook")
        local fname="$(_rand_lower "$(_rand_int 3 10)").${ext}"
        echo "conteudo $(_rand_alphanum 10)" > "${agents_dir}/${fname}"
      done
      ;;
    3)
      # Adicionar múltiplos arquivos extras de tipos variados
      local agent_name="$(_rand_lower "$(_rand_int 5 10)")-reviewer"
      cat > "${agents_dir}/${agent_name}.md" <<AGENTEOF
---
name: "${agent_name}"
description: "Reviewer funcional"
inclusion: auto
---
# ${agent_name}
AGENTEOF
      echo "extra: config" > "${agents_dir}/config.yaml"
      echo "{}" > "${agents_dir}/settings.json"
      ;;
  esac

  echo "${agents_dir}"
}

# =============================================================================
# Property Test 8a: agents/ com apenas README.md é aceito (100 iterações)
# =============================================================================
@test "Property 8a: agents/ com apenas README.md é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local agents_dir
    agents_dir="$(gen_valid_agents_dir)"

    if ! validate_agents_empty "${agents_dir}"; then
      echo "FALHA na iteração ${i}: agents/ válido rejeitado"
      echo "Conteúdo:"
      ls -la "${agents_dir}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 diretórios agents/ válidos"
}

# =============================================================================
# Property Test 8b: agents/ com arquivos extras é rejeitado (100 iterações)
# =============================================================================
@test "Property 8b: agents/ com arquivos extras é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local agents_dir
    agents_dir="$(gen_invalid_agents_dir)"

    if validate_agents_empty "${agents_dir}"; then
      echo "FALHA na iteração ${i}: agents/ com extras aceito pela validação"
      echo "Conteúdo:"
      ls -la "${agents_dir}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 diretórios agents/ inválidos"
}

# =============================================================================
# Verificação real: diretório agents/ do archetype bff-fastify
# =============================================================================
@test "Property 8 (real): diretório agents/ do archetype bff-fastify contém apenas README.md" {
  local real_agents_dir="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify/agents"

  # Verificar que o diretório real existe
  [[ -d "${real_agents_dir}" ]] || fail "Diretório agents/ não encontrado em ${real_agents_dir}"

  # Deve passar a validação
  run validate_agents_empty "${real_agents_dir}"
  assert_success
}
