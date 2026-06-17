#!/usr/bin/env bats
# =============================================================================
# Property 7: Schema de configuração MCP
# Feature: archetype-frontend-react, Property 7: Schema de configuração MCP
# =============================================================================
# Para qualquer objeto JSON mcp.json válido do archetype, ele SHALL conter:
# um campo _comment (string não-vazia), um campo _version (semver válido),
# e um campo mcpServers (objeto com ao menos 1 servidor onde cada servidor
# possui _comment string não-vazia e autoApprove como array vazio).
#
# **Validates: Requirements 9.1, 9.2, 9.3, 9.4**
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

# --- Função de validação de schema MCP para archetype frontend-react ---
# Valida os requisitos 9.1-9.4 específicos:
# - _comment: string não-vazia (9.1)
# - _version: semver válido MAJOR.MINOR.PATCH (9.1)
# - mcpServers: objeto com ao menos 1 servidor (9.1)
# - Cada servidor tem _comment string não-vazia (9.3)
# - Cada servidor tem autoApprove: [] (array vazio) (9.4)
# Retorna 0 se válido, 1 se inválido.
validate_mcp_schema_frontend() {
  local json_content="$1"

  # Verificar se é JSON parseável
  if ! echo "${json_content}" | jq '.' > /dev/null 2>&1; then
    return 1
  fi

  # 1. _comment: string não-vazia (Req 9.1)
  local comment
  comment=$(echo "${json_content}" | jq -r '._comment // empty' 2>/dev/null)
  if [[ -z "${comment}" ]]; then
    return 1
  fi

  # 2. _version: semver válido MAJOR.MINOR.PATCH (Req 9.1)
  local version
  version=$(echo "${json_content}" | jq -r '._version // empty' 2>/dev/null)
  if [[ -z "${version}" ]]; then
    return 1
  fi
  if [[ ! "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    return 1
  fi

  # 3. mcpServers: objeto com ao menos 1 servidor (Req 9.1)
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

    # 4a. _comment: string não-vazia por servidor (Req 9.3)
    local srv_comment
    srv_comment=$(echo "${server_json}" | jq -r '._comment // empty' 2>/dev/null)
    if [[ -z "${srv_comment}" ]]; then
      return 1
    fi

    # 4b. autoApprove: array vazio (Req 9.4)
    local auto_approve_type auto_approve_len
    auto_approve_type=$(echo "${server_json}" | jq -r '.autoApprove | type' 2>/dev/null)
    if [[ "${auto_approve_type}" != "array" ]]; then
      return 1
    fi
    auto_approve_len=$(echo "${server_json}" | jq -r '.autoApprove | length' 2>/dev/null)
    if [[ "${auto_approve_len}" -ne 0 ]]; then
      return 1
    fi
  done <<< "${server_names}"

  return 0
}

# --- Gerador de mcp.json válido para archetype frontend-react ---
# Gera JSONs que seguem todos os requisitos 9.1-9.4
gen_valid_mcp_frontend() {
  local version num_servers
  version="$(gen_semver)"
  num_servers=$(_rand_int 1 3)

  local servers=""
  local i
  for (( i = 0; i < num_servers; i++ )); do
    local server_name="$(_rand_lower "$(_rand_int 4 10)")-$(_rand_lower "$(_rand_int 3 6)")"
    local comment="Servidor $(_rand_alpha 5) - $(_rand_alpha "$(_rand_int 5 15)")"
    local server_obj

    # Gera servidor com command+args (padrão frontend-react)
    server_obj=$(cat <<SEOF
    "${server_name}": {
      "_comment": "${comment}",
      "command": "$(_rand_choice "npx" "node" "pnpm")",
      "args": ["-y", "$(_rand_lower 5)-mcp@latest"],
      "disabled": $(_rand_choice "true" "false"),
      "autoApprove": []
    }
SEOF
)

    if [[ -n "$servers" ]]; then
      servers="${servers},
${server_obj}"
    else
      servers="$server_obj"
    fi
  done

  cat <<EOF
{
  "_comment": "MCPs do archetype frontend-react - $(_rand_alpha 8)",
  "_version": "${version}",
  "mcpServers": {
${servers}
  }
}
EOF
}

# --- Gerador de mcp.json INVÁLIDO para archetype frontend-react ---
# Gera JSONs que violam ao menos um dos requisitos 9.1-9.4
gen_invalid_mcp_frontend() {
  local strategy
  strategy=$(_rand_int 0 6)

  case "$strategy" in
    0) # Sem _comment no root (viola 9.1)
      cat <<EOF
{
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "_comment": "Servidor teste",
      "command": "npx",
      "args": ["-y", "mcp@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    1) # _comment vazio no root (viola 9.1)
      cat <<EOF
{
  "_comment": "",
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "_comment": "Servidor teste",
      "command": "npx",
      "args": ["-y", "mcp@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    2) # _version inválida - não é semver (viola 9.1)
      local invalid_version
      invalid_version=$(_rand_choice "invalid" "v1.0.0" "1.0" "1.0.0.0" "01.0.0")
      cat <<EOF
{
  "_comment": "MCPs frontend-react",
  "_version": "${invalid_version}",
  "mcpServers": {
    "server1": {
      "_comment": "Servidor teste",
      "command": "npx",
      "args": ["-y", "mcp@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    3) # mcpServers vazio - zero servidores (viola 9.1)
      cat <<EOF
{
  "_comment": "MCPs frontend-react",
  "_version": "1.0.0",
  "mcpServers": {}
}
EOF
      ;;
    4) # Servidor sem _comment (viola 9.3)
      cat <<EOF
{
  "_comment": "MCPs frontend-react",
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "command": "npx",
      "args": ["-y", "mcp@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    5) # Servidor com _comment vazio (viola 9.3)
      cat <<EOF
{
  "_comment": "MCPs frontend-react",
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "_comment": "",
      "command": "npx",
      "args": ["-y", "mcp@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    6) # autoApprove não-vazio (viola 9.4)
      cat <<EOF
{
  "_comment": "MCPs frontend-react",
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "_comment": "Servidor teste",
      "command": "npx",
      "args": ["-y", "mcp@latest"],
      "disabled": false,
      "autoApprove": ["read", "write"]
    }
  }
}
EOF
      ;;
  esac
}

# =============================================================================
# Property Test 7a: mcp.json válido é aceito pela validação (20 iterações)
# =============================================================================
@test "Property 7a: mcp.json válido do frontend-react é aceito pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local json_content
    json_content="$(gen_valid_mcp_frontend)"

    if ! validate_mcp_schema_frontend "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON válido rejeitado"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/20 JSONs válidos"
}

# =============================================================================
# Property Test 7b: mcp.json inválido é rejeitado pela validação (20 iterações)
# =============================================================================
@test "Property 7b: mcp.json inválido do frontend-react é rejeitado pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local json_content
    json_content="$(gen_invalid_mcp_frontend)"

    if validate_mcp_schema_frontend "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON inválido aceito"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 JSONs inválidos"
}

# =============================================================================
# Property Test 7c: validação distingue _comment e autoApprove (20 iterações)
# =============================================================================
@test "Property 7c: validação aceita _comment não-vazio e autoApprove vazio, rejeita variantes (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local is_valid_case=$(( RANDOM % 2 ))

    if [[ ${is_valid_case} -eq 1 ]]; then
      # Caso válido: JSON com _comment não-vazio e autoApprove []
      local json_content
      json_content="$(gen_valid_mcp_frontend)"

      if ! validate_mcp_schema_frontend "${json_content}"; then
        echo "FALHA iteração ${i}: JSON válido rejeitado"
        echo "JSON: ${json_content}"
        failures=$((failures + 1))
      fi
    else
      # Caso inválido: autoApprove não-vazio OU _comment vazio no servidor
      local invalid_variant
      invalid_variant=$(( RANDOM % 2 ))
      local json_content

      if [[ ${invalid_variant} -eq 0 ]]; then
        # autoApprove com itens
        json_content=$(cat <<EOF
{
  "_comment": "MCPs frontend-react teste",
  "_version": "$(gen_semver)",
  "mcpServers": {
    "test-server": {
      "_comment": "Servidor de teste",
      "command": "npx",
      "args": ["-y", "test-mcp@latest"],
      "disabled": false,
      "autoApprove": ["$(_rand_lower 4)"]
    }
  }
}
EOF
)
      else
        # _comment vazio no servidor
        json_content=$(cat <<EOF
{
  "_comment": "MCPs frontend-react teste",
  "_version": "$(gen_semver)",
  "mcpServers": {
    "test-server": {
      "_comment": "",
      "command": "npx",
      "args": ["-y", "test-mcp@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
)
      fi

      if validate_mcp_schema_frontend "${json_content}"; then
        echo "FALHA iteração ${i}: JSON inválido aceito (variante=${invalid_variant})"
        echo "JSON: ${json_content}"
        failures=$((failures + 1))
      fi
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação falhou em ${failures}/20 iterações"
}

# =============================================================================
# Property Test 7d: mcp.json real do archetype frontend-react é válido
# =============================================================================
@test "Property 7d: mcp.json real do archetype frontend-react passa na validação" {
  local mcp_file="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react/mcp/mcp.json"

  # Verifica que o arquivo existe
  [[ -f "${mcp_file}" ]] || fail "mcp.json não encontrado em ${mcp_file}"

  local json_content
  json_content="$(cat "${mcp_file}")"

  if ! validate_mcp_schema_frontend "${json_content}"; then
    echo "mcp.json real do archetype não passou na validação:"
    echo "${json_content}"
    fail "mcp.json real do archetype frontend-react é inválido segundo Property 7"
  fi
}
