#!/usr/bin/env bats
# =============================================================================
# Property 3: Hooks habilitados e schema válido
# Feature: archetype-bff-fastify, Property 3: Hooks habilitados e schema válido
# =============================================================================
# Para qualquer arquivo .kiro.hook no diretório hooks/ do archetype bff-fastify,
# o conteúdo SHALL ser JSON válido contendo os campos obrigatórios:
# - enabled (com valor true)
# - name (string não-vazia)
# - version (string "1" ou "2")
# - when.type (um de agentStop, postTaskExecution, userTriggered)
# - then.type (um de askAgent, runCommand)
# - then.prompt presente quando then.type é askAgent
# - then.command presente quando then.type é runCommand
#
# **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 5.1, 6.1**
# Mínimo 100 iterações por property test.

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

# --- Função de validação completa do schema de hook BFF ---
# Verifica se um JSON de hook atende TODOS os requisitos do schema:
# 1. JSON parseável
# 2. enabled é booleano true
# 3. name é string não-vazia
# 4. version é "1" ou "2"
# 5. when.type é um de: agentStop, postTaskExecution, userTriggered
# 6. then.type é um de: askAgent, runCommand
# 7. Se then.type == askAgent, then.prompt deve ser string não-vazia
# 8. Se then.type == runCommand, then.command deve ser string não-vazia
#
# Recebe o conteúdo JSON como argumento.
# Retorna 0 se válido, 1 se inválido.
validate_hook_schema() {
  local json_content="$1"

  # 1. JSON parseável
  if ! echo "${json_content}" | jq '.' > /dev/null 2>&1; then
    return 1
  fi

  # 2. enabled deve ser booleano true
  local enabled_type enabled_value
  enabled_type=$(echo "${json_content}" | jq -r '.enabled | type' 2>/dev/null)
  enabled_value=$(echo "${json_content}" | jq -r '.enabled' 2>/dev/null)
  if [[ "${enabled_type}" != "boolean" || "${enabled_value}" != "true" ]]; then
    return 1
  fi

  # 3. name deve ser string não-vazia
  local name_type name_value
  name_type=$(echo "${json_content}" | jq -r '.name | type' 2>/dev/null)
  name_value=$(echo "${json_content}" | jq -r '.name' 2>/dev/null)
  if [[ "${name_type}" != "string" || -z "${name_value}" ]]; then
    return 1
  fi

  # 4. version deve ser string "1" ou "2"
  local version_type version_value
  version_type=$(echo "${json_content}" | jq -r '.version | type' 2>/dev/null)
  version_value=$(echo "${json_content}" | jq -r '.version' 2>/dev/null)
  if [[ "${version_type}" != "string" ]]; then
    return 1
  fi
  if [[ "${version_value}" != "1" && "${version_value}" != "2" ]]; then
    return 1
  fi

  # 5. when.type deve ser um dos valores válidos
  local when_type_type when_type_value
  when_type_type=$(echo "${json_content}" | jq -r '.when.type | type' 2>/dev/null)
  when_type_value=$(echo "${json_content}" | jq -r '.when.type' 2>/dev/null)
  if [[ "${when_type_type}" != "string" ]]; then
    return 1
  fi
  case "${when_type_value}" in
    agentStop|postTaskExecution|userTriggered) ;;
    *) return 1 ;;
  esac

  # 6. then.type deve ser um dos valores válidos
  local then_type_type then_type_value
  then_type_type=$(echo "${json_content}" | jq -r '.then.type | type' 2>/dev/null)
  then_type_value=$(echo "${json_content}" | jq -r '.then.type' 2>/dev/null)
  if [[ "${then_type_type}" != "string" ]]; then
    return 1
  fi
  case "${then_type_value}" in
    askAgent|runCommand) ;;
    *) return 1 ;;
  esac

  # 7. Se then.type == askAgent, then.prompt deve ser string não-vazia
  if [[ "${then_type_value}" == "askAgent" ]]; then
    local prompt_type prompt_value
    prompt_type=$(echo "${json_content}" | jq -r '.then.prompt | type' 2>/dev/null)
    prompt_value=$(echo "${json_content}" | jq -r '.then.prompt' 2>/dev/null)
    if [[ "${prompt_type}" != "string" || -z "${prompt_value}" ]]; then
      return 1
    fi
  fi

  # 8. Se then.type == runCommand, then.command deve ser string não-vazia
  if [[ "${then_type_value}" == "runCommand" ]]; then
    local command_type command_value
    command_type=$(echo "${json_content}" | jq -r '.then.command | type' 2>/dev/null)
    command_value=$(echo "${json_content}" | jq -r '.then.command' 2>/dev/null)
    if [[ "${command_type}" != "string" || -z "${command_value}" ]]; then
      return 1
    fi
  fi

  return 0
}

# --- Gerador de hook BFF com schema completamente válido ---
gen_valid_bff_hook() {
  local name version when_type then_type prompt_or_command

  name="$(_rand_alpha "$(_rand_int 5 15)")"
  version=$(_rand_choice "1" "2")
  when_type=$(_rand_choice "agentStop" "postTaskExecution" "userTriggered")
  then_type=$(_rand_choice "askAgent" "runCommand")

  if [[ "$then_type" == "askAgent" ]]; then
    prompt_or_command="\"prompt\": \"$(_rand_alpha "$(_rand_int 10 40)")\""
  else
    prompt_or_command="\"command\": \"$(_rand_lower 4) $(_rand_lower 4)\""
  fi

  cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook de teste: $(_rand_alpha "$(_rand_int 10 30)")",
  "version": "${version}",
  "when": {
    "type": "${when_type}"
  },
  "then": {
    "type": "${then_type}",
    ${prompt_or_command}
  }
}
EOF
}

# --- Gerador de hook BFF com exatamente um campo inválido ---
# Rota por estratégia (0-7) garantindo cobertura de todos os campos.
gen_invalid_bff_hook() {
  local strategy
  strategy=$(_rand_int 0 7)

  local name version when_type then_type
  name="$(_rand_alpha "$(_rand_int 5 15)")"
  version=$(_rand_choice "1" "2")
  when_type=$(_rand_choice "agentStop" "postTaskExecution" "userTriggered")
  then_type=$(_rand_choice "askAgent" "runCommand")

  case "$strategy" in
    0) # enabled não é true (false, string, null, numérico)
      local bad_enabled
      bad_enabled=$(_rand_choice "false" '"true"' "null" "1" '"yes"')
      cat <<EOF
{
  "enabled": ${bad_enabled},
  "name": "${name}",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test prompt" }
}
EOF
      ;;
    1) # name vazio ou ausente
      local bad_name_strategy
      bad_name_strategy=$(_rand_int 0 2)
      if [[ ${bad_name_strategy} -eq 0 ]]; then
        # name vazio
        cat <<EOF
{
  "enabled": true,
  "name": "",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test prompt" }
}
EOF
      elif [[ ${bad_name_strategy} -eq 1 ]]; then
        # name ausente
        cat <<EOF
{
  "enabled": true,
  "description": "Hook sem name",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test prompt" }
}
EOF
      else
        # name não é string
        cat <<EOF
{
  "enabled": true,
  "name": 123,
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test prompt" }
}
EOF
      fi
      ;;
    2) # version inválida (não "1" nem "2")
      local bad_version
      bad_version=$(_rand_choice '"3"' '"0"' '"v1"' '1' '"latest"' '""')
      cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook inválido",
  "version": ${bad_version},
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test prompt" }
}
EOF
      ;;
    3) # when.type inválido
      local bad_when
      bad_when=$(_rand_choice '"fileEdited"' '"promptSubmit"' '"manual"' '"onSave"' '""' '"fileCreated"')
      cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": ${bad_when} },
  "then": { "type": "askAgent", "prompt": "test prompt" }
}
EOF
      ;;
    4) # then.type inválido
      local bad_then
      bad_then=$(_rand_choice '"execute"' '"notify"' '"log"' '""' '"shell"' '"agent"')
      cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": ${bad_then}, "prompt": "test" }
}
EOF
      ;;
    5) # askAgent sem prompt (ou prompt vazio)
      local bad_prompt_strategy
      bad_prompt_strategy=$(_rand_int 0 1)
      if [[ ${bad_prompt_strategy} -eq 0 ]]; then
        # prompt ausente
        cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent" }
}
EOF
      else
        # prompt vazio
        cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "" }
}
EOF
      fi
      ;;
    6) # runCommand sem command (ou command vazio)
      local bad_cmd_strategy
      bad_cmd_strategy=$(_rand_int 0 1)
      if [[ ${bad_cmd_strategy} -eq 0 ]]; then
        # command ausente
        cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "runCommand" }
}
EOF
      else
        # command vazio
        cat <<EOF
{
  "enabled": true,
  "name": "${name}",
  "description": "Hook inválido",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "runCommand", "command": "" }
}
EOF
      fi
      ;;
    7) # JSON mal-formado (não parseável)
      echo '{ "enabled": true, "name": "broken", invalid json }'
      ;;
  esac
}

# =============================================================================
# Property Test: hooks válidos DEVEM ser aceitos (100 iterações)
# =============================================================================
@test "Property 3a: hook com schema válido é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_valid_bff_hook)"

    if ! validate_hook_schema "${json_content}"; then
      echo "FALHA na iteração ${i}: hook válido rejeitado"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 hooks com schema válido"
}

# =============================================================================
# Property Test: hooks inválidos DEVEM ser rejeitados (100 iterações)
# =============================================================================
@test "Property 3b: hook com schema inválido é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_invalid_bff_hook)"

    if validate_hook_schema "${json_content}"; then
      echo "FALHA na iteração ${i}: hook inválido aceito"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 hooks com schema inválido"
}

# =============================================================================
# Property Test: todos os 6 hooks reais do archetype bff-fastify passam validação
# =============================================================================
@test "Property 3c: todos os hooks do archetype bff-fastify possuem schema válido" {
  local hooks_dir="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify/hooks"
  local failures=0
  local hook_count=0

  # Percorrer todos os .kiro.hook no diretório do archetype
  for hook_file in "${hooks_dir}"/*.kiro.hook; do
    [[ -f "${hook_file}" ]] || continue
    hook_count=$((hook_count + 1))

    local json_content
    json_content="$(cat "${hook_file}")"

    if ! validate_hook_schema "${json_content}"; then
      echo "FALHA: ${hook_file##*/} não passa na validação de schema"
      failures=$((failures + 1))
    fi
  done

  # Verificar que encontramos ao menos 6 hooks
  [[ ${hook_count} -ge 6 ]] || fail "Esperados ao menos 6 hooks, encontrados ${hook_count}"
  [[ ${failures} -eq 0 ]] || fail "${failures}/${hook_count} hooks do archetype não passam na validação de schema"
}
