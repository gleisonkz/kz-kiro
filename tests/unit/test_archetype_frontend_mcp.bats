#!/usr/bin/env bats
# Testes unitários para validar o arquivo mcp.json do archetype frontend-react.
# Valida: Requisitos 9.1, 9.2, 9.3, 9.4

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react"
  MCP_FILE="${ARCHETYPE_DIR}/mcp/mcp.json"
}

# --- Requisito 9.1: JSON válido com _comment, _version e mcpServers ---

@test "mcp.json: arquivo existe no diretório mcp/" {
  [ -f "${MCP_FILE}" ]
}

@test "mcp.json: é JSON válido" {
  assert_json_valid "${MCP_FILE}"
}

@test "mcp.json: _comment é string não vazia" {
  local comment
  comment="$(jq -r '._comment' "${MCP_FILE}")"
  [ -n "${comment}" ]
  [ "${comment}" != "null" ]
}

@test "mcp.json: _version está em formato semver (MAJOR.MINOR.PATCH)" {
  local version
  version="$(jq -r '._version' "${MCP_FILE}")"
  [[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

@test "mcp.json: mcpServers existe e contém ao menos 1 servidor" {
  local count
  count="$(jq '.mcpServers | keys | length' "${MCP_FILE}")"
  [ "${count}" -ge 1 ]
}

# --- Requisito 9.2: chrome-devtools configurado corretamente ---

@test "mcp.json: chrome-devtools existe em mcpServers" {
  local has_server
  has_server="$(jq 'has("mcpServers") and (.mcpServers | has("chrome-devtools"))' "${MCP_FILE}")"
  [ "${has_server}" = "true" ]
}

@test "mcp.json: chrome-devtools command é 'npx'" {
  assert_json_field "${MCP_FILE}" '.mcpServers["chrome-devtools"].command' 'npx'
}

@test "mcp.json: chrome-devtools args é ['-y', 'chrome-devtools-mcp@latest']" {
  local args
  args="$(jq -c '.mcpServers["chrome-devtools"].args' "${MCP_FILE}")"
  [ "${args}" = '["-y","chrome-devtools-mcp@latest"]' ]
}

@test "mcp.json: chrome-devtools disabled é false" {
  local disabled
  disabled="$(jq '.mcpServers["chrome-devtools"].disabled' "${MCP_FILE}")"
  [ "${disabled}" = "false" ]
}

@test "mcp.json: chrome-devtools autoApprove é array vazio" {
  local auto_approve
  auto_approve="$(jq -c '.mcpServers["chrome-devtools"].autoApprove' "${MCP_FILE}")"
  [ "${auto_approve}" = "[]" ]
}

# --- Requisito 9.3: cada servidor tem _comment não vazio ---

@test "mcp.json: chrome-devtools _comment é string não vazia" {
  local comment
  comment="$(jq -r '.mcpServers["chrome-devtools"]._comment' "${MCP_FILE}")"
  [ -n "${comment}" ]
  [ "${comment}" != "null" ]
}

# --- Requisito 9.4: cada servidor tem autoApprove como array vazio ---

@test "mcp.json: todos os servidores têm autoApprove como array vazio" {
  local servers_with_invalid_auto_approve
  servers_with_invalid_auto_approve="$(jq '[.mcpServers | to_entries[] | select(.value.autoApprove != [])] | length' "${MCP_FILE}")"
  [ "${servers_with_invalid_auto_approve}" -eq 0 ]
}
