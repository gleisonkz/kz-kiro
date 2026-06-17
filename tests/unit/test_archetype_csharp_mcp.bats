#!/usr/bin/env bats
# Testes unitários para validar o arquivo mcp.json do archetype backend-csharp.
# Valida: Requisitos 9.1, 9.2

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp"
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

@test "mcp.json: _comment menciona backend-csharp" {
  local comment
  comment="$(jq -r '._comment' "${MCP_FILE}")"
  [[ "${comment}" == *"backend-csharp"* ]]
}

@test "mcp.json: _comment menciona merge com baseline" {
  local comment
  comment="$(jq -r '._comment' "${MCP_FILE}")"
  [[ "${comment}" =~ [Bb]aseline ]]
}

@test "mcp.json: _version está em formato semver (MAJOR.MINOR.PATCH)" {
  local version
  version="$(jq -r '._version' "${MCP_FILE}")"
  [[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

# --- Requisito 9.2: mcpServers é objeto vazio ---

@test "mcp.json: mcpServers existe e é objeto" {
  local type
  type="$(jq -r '.mcpServers | type' "${MCP_FILE}")"
  [ "${type}" = "object" ]
}

@test "mcp.json: mcpServers é objeto vazio sem servidores MCP adicionais" {
  local count
  count="$(jq '.mcpServers | keys | length' "${MCP_FILE}")"
  [ "${count}" -eq 0 ]
}
