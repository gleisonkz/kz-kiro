#!/usr/bin/env bats
# =============================================================================
# Property Test 3: Validação de schema mcp.json
# Feature: baseline-global
# Property 3: Validação de schema mcp.json
#
# Para qualquer objeto JSON, a função de validação de mcp.json SHALL aceitar
# se e somente se o objeto contiver: um campo _comment (string não-vazia),
# um campo _version (semver válido), e um campo mcpServers (objeto com ao menos
# 1 servidor onde cada servidor possui _comment string não-vazia, disabled
# booleano, autoApprove array vazio, e um campo de conexão url string OU
# command string com args array).
#
# **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/generators'
load '../helpers/assertions'
load '../lib/bats-assert/load'
load '../lib/bats-support/load'

# --- Função de validação de schema mcp.json ---
# Implementa a validação conforme Property 3 do design document.
# Retorna 0 se válido, 1 se inválido.
validate_mcp_schema() {
  local json_content="$1"

  # Verificar se é JSON parseável
  if ! echo "${json_content}" | jq '.' > /dev/null 2>&1; then
    return 1
  fi

  # 1. _comment: string não-vazia
  local comment
  comment=$(echo "${json_content}" | jq -r '._comment // empty' 2>/dev/null)
  if [[ -z "${comment}" ]]; then
    return 1
  fi

  # 2. _version: semver válido (MAJOR.MINOR.PATCH sem zeros à esquerda, sem prefixo v)
  local version
  version=$(echo "${json_content}" | jq -r '._version // empty' 2>/dev/null)
  if [[ -z "${version}" ]]; then
    return 1
  fi
  if [[ ! "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    return 1
  fi

  # 3. mcpServers: objeto com ao menos 1 servidor
  local server_count
  server_count=$(echo "${json_content}" | jq -r '.mcpServers | keys | length' 2>/dev/null)
  if [[ -z "${server_count}" || "${server_count}" -lt 1 ]]; then
    return 1
  fi

  # 4. Validar cada servidor individualmente
  local server_names
  server_names=$(echo "${json_content}" | jq -r '.mcpServers | keys[]' 2>/dev/null)

  while IFS= read -r server_name; do
    [[ -z "${server_name}" ]] && continue

    local server_json
    server_json=$(echo "${json_content}" | jq -c ".mcpServers[\"${server_name}\"]" 2>/dev/null)

    # 4a. _comment: string não-vazia
    local srv_comment
    srv_comment=$(echo "${server_json}" | jq -r '._comment // empty' 2>/dev/null)
    if [[ -z "${srv_comment}" ]]; then
      return 1
    fi

    # 4b. disabled: booleano
    local disabled_type
    disabled_type=$(echo "${server_json}" | jq -r '.disabled | type' 2>/dev/null)
    if [[ "${disabled_type}" != "boolean" ]]; then
      return 1
    fi

    # 4c. autoApprove: array vazio
    local auto_approve_type auto_approve_len
    auto_approve_type=$(echo "${server_json}" | jq -r '.autoApprove | type' 2>/dev/null)
    if [[ "${auto_approve_type}" != "array" ]]; then
      return 1
    fi
    auto_approve_len=$(echo "${server_json}" | jq -r '.autoApprove | length' 2>/dev/null)
    if [[ "${auto_approve_len}" -ne 0 ]]; then
      return 1
    fi

    # 4d. Conexão: url XOR (command + args)
    local has_url has_command has_args
    has_url=$(echo "${server_json}" | jq -r 'has("url")' 2>/dev/null)
    has_command=$(echo "${server_json}" | jq -r 'has("command")' 2>/dev/null)
    has_args=$(echo "${server_json}" | jq -r 'has("args")' 2>/dev/null)

    if [[ "${has_url}" == "true" && "${has_command}" == "true" ]]; then
      # Ambos presentes — inválido (violação XOR)
      return 1
    elif [[ "${has_url}" == "true" ]]; then
      # Validar que url é string não-vazia
      local url_val
      url_val=$(echo "${server_json}" | jq -r '.url // empty' 2>/dev/null)
      if [[ -z "${url_val}" ]]; then
        return 1
      fi
    elif [[ "${has_command}" == "true" ]]; then
      # Validar command é string não-vazia e args é array
      local cmd_val
      cmd_val=$(echo "${server_json}" | jq -r '.command // empty' 2>/dev/null)
      if [[ -z "${cmd_val}" ]]; then
        return 1
      fi
      if [[ "${has_args}" != "true" ]]; then
        return 1
      fi
      local args_type
      args_type=$(echo "${server_json}" | jq -r '.args | type' 2>/dev/null)
      if [[ "${args_type}" != "array" ]]; then
        return 1
      fi
    else
      # Nem url nem command — inválido
      return 1
    fi
  done <<< "${server_names}"

  return 0
}

# --- Testes de propriedade ---

# @test — JSONs válidos gerados por gen_mcp_json DEVEM ser aceitos
@test "Property 3: mcp.json válido é aceito pela validação (100 iterações)" {
  # bats test_tags=property, mcp-schema
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_mcp_json)"

    if ! validate_mcp_schema "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON válido rejeitado"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 JSONs válidos"
}

# @test — JSONs inválidos gerados por gen_invalid_mcp_json DEVEM ser rejeitados
@test "Property 3: mcp.json inválido é rejeitado pela validação (100 iterações)" {
  # bats test_tags=property, mcp-schema
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_invalid_mcp_json)"

    if validate_mcp_schema "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON inválido aceito"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 JSONs inválidos"
}
