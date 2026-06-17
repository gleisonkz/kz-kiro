#!/usr/bin/env bats
# =============================================================================
# Property 4: Hooks habilitados por padrão
# Feature: archetype-frontend-react, Property 4: Hooks habilitados por padrão
# =============================================================================
# Para qualquer arquivo .kiro.hook no diretório hooks/ do archetype, o campo
# enabled SHALL ser true. A validação aceita hooks somente quando enabled é
# exatamente true (booleano JSON).
#
# **Validates: Requirements 3.2, 3.4, 4.4, 5.1, 5.2**
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

# --- Função de validação de hook enabled ---
# Verifica se um JSON de hook possui o campo enabled com valor exatamente true (booleano).
# Recebe o conteúdo JSON como argumento.
# Retorna 0 se enabled é booleano true, 1 caso contrário.
validate_hook_enabled() {
  local json_content="$1"

  # Verificar se é JSON parseável
  if ! echo "${json_content}" | jq '.' > /dev/null 2>&1; then
    return 1
  fi

  # Verificar se o campo enabled existe, é do tipo booleano e tem valor true
  # Usa jq type check para distinguir booleano true de string "true"
  local enabled_type enabled_value
  enabled_type=$(echo "${json_content}" | jq -r '.enabled | type' 2>/dev/null)
  enabled_value=$(echo "${json_content}" | jq -r '.enabled' 2>/dev/null)

  if [[ "${enabled_type}" != "boolean" || "${enabled_value}" != "true" ]]; then
    return 1
  fi

  return 0
}

# --- Gerador de hook com enabled: true (sempre válido) ---
gen_hook_enabled_true() {
  local name description version when_type then_type prompt_or_command

  name="$(_rand_alpha "$(_rand_int 5 15)")"
  description="Hook de teste: $(_rand_alpha "$(_rand_int 10 30)")"
  version="$(_rand_choice "1" "2")"
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
  "description": "${description}",
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

# --- Gerador de hook com enabled != true (sempre inválido) ---
gen_hook_enabled_invalid() {
  local strategy
  strategy=$(_rand_int 0 5)

  local name description version when_type
  name="$(_rand_alpha "$(_rand_int 5 15)")"
  description="Hook inválido: $(_rand_alpha "$(_rand_int 10 20)")"
  version="$(_rand_choice "1" "2")"
  when_type=$(_rand_choice "agentStop" "postTaskExecution" "userTriggered")

  case "$strategy" in
    0) # enabled: false
      cat <<EOF
{
  "enabled": false,
  "name": "${name}",
  "description": "${description}",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test" }
}
EOF
      ;;
    1) # enabled: string "true" (não booleano)
      cat <<EOF
{
  "enabled": "true",
  "name": "${name}",
  "description": "${description}",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test" }
}
EOF
      ;;
    2) # enabled: null
      cat <<EOF
{
  "enabled": null,
  "name": "${name}",
  "description": "${description}",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "runCommand", "command": "echo test" }
}
EOF
      ;;
    3) # enabled ausente
      cat <<EOF
{
  "name": "${name}",
  "description": "${description}",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test" }
}
EOF
      ;;
    4) # enabled: 1 (numérico, não booleano)
      cat <<EOF
{
  "enabled": 1,
  "name": "${name}",
  "description": "${description}",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "askAgent", "prompt": "test" }
}
EOF
      ;;
    5) # enabled: "yes" (string inválida)
      cat <<EOF
{
  "enabled": "yes",
  "name": "${name}",
  "description": "${description}",
  "version": "${version}",
  "when": { "type": "${when_type}" },
  "then": { "type": "runCommand", "command": "npm test" }
}
EOF
      ;;
  esac
}

# =============================================================================
# Property Test: hooks com enabled: true DEVEM ser aceitos (20 iterações)
# =============================================================================
@test "Property 4a: hook com enabled true é aceito pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local json_content
    json_content="$(gen_hook_enabled_true)"

    if ! validate_hook_enabled "${json_content}"; then
      echo "FALHA na iteração ${i}: hook com enabled:true rejeitado"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/20 hooks com enabled:true"
}

# =============================================================================
# Property Test: hooks com enabled != true DEVEM ser rejeitados (20 iterações)
# =============================================================================
@test "Property 4b: hook com enabled diferente de true é rejeitado pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local json_content
    json_content="$(gen_hook_enabled_invalid)"

    if validate_hook_enabled "${json_content}"; then
      echo "FALHA na iteração ${i}: hook com enabled inválido aceito"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 hooks com enabled inválido"
}

# =============================================================================
# Property Test: validação distingue true booleano de variantes (20 iterações)
# =============================================================================
@test "Property 4c: validação aceita apenas booleano true, rejeita variantes (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local is_valid_case=$(( RANDOM % 2 ))

    if [[ ${is_valid_case} -eq 1 ]]; then
      # Caso válido: enabled é exatamente true (booleano JSON)
      local json_content
      json_content="$(gen_hook_enabled_true)"

      if ! validate_hook_enabled "${json_content}"; then
        echo "FALHA iteração ${i}: enabled true rejeitado"
        echo "JSON: ${json_content}"
        failures=$((failures + 1))
      fi
    else
      # Caso inválido: enabled é algo que NÃO é booleano true
      local invalid_enabled
      invalid_enabled=$(_rand_choice "false" '"true"' '"false"' "null" "1" "0" '"yes"' '"on"')
      local name
      name="$(_rand_alpha 8)"
      local json_content="{
  \"enabled\": ${invalid_enabled},
  \"name\": \"${name}\",
  \"description\": \"Hook teste\",
  \"version\": \"2\",
  \"when\": { \"type\": \"agentStop\" },
  \"then\": { \"type\": \"askAgent\", \"prompt\": \"test\" }
}"

      if validate_hook_enabled "${json_content}"; then
        echo "FALHA iteração ${i}: enabled=${invalid_enabled} aceito"
        echo "JSON: ${json_content}"
        failures=$((failures + 1))
      fi
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação falhou em ${failures}/20 iterações"
}

# =============================================================================
# Property Test: todos os hooks reais do archetype TÊM enabled: true
# =============================================================================
@test "Property 4d: todos os hooks do archetype frontend-react possuem enabled: true" {
  local hooks_dir="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react/hooks"
  local failures=0

  # Percorrer todos os .kiro.hook no diretório do archetype
  for hook_file in "${hooks_dir}"/*.kiro.hook; do
    [[ -f "${hook_file}" ]] || continue

    local json_content
    json_content="$(cat "${hook_file}")"

    if ! validate_hook_enabled "${json_content}"; then
      echo "FALHA: ${hook_file##*/} não tem enabled: true"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "${failures} hooks do archetype não possuem enabled: true"
}
