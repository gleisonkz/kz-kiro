#!/usr/bin/env bats
# Testes unitários para validar o arquivo mcp.json do archetype mobile-flutter.
# Valida: Requisitos 10.1, 10.2, 10.3

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"
  MCP_FILE="${ARCHETYPE_DIR}/mcp/mcp.json"
}

# --- Requisito 10.1: JSON válido com _comment, _version e mcpServers ---

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

@test "mcp.json: _comment menciona mobile-flutter" {
  local comment
  comment="$(jq -r '._comment' "${MCP_FILE}")"
  [[ "${comment}" == *"mobile-flutter"* ]]
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

# --- Requisito 10.2: mcpServers contém entrada "dart" ---

@test "mcp.json: mcpServers existe e é objeto" {
  local type
  type="$(jq -r '.mcpServers | type' "${MCP_FILE}")"
  [ "${type}" = "object" ]
}

@test "mcp.json: mcpServers contém ao menos a entrada 'dart'" {
  local has_dart
  has_dart="$(jq 'has("mcpServers") and (.mcpServers | has("dart"))' "${MCP_FILE}")"
  [ "${has_dart}" = "true" ]
}

@test "mcp.json: mcpServers nao e objeto vazio (diferente dos outros archetypes)" {
  local count
  count="$(jq '.mcpServers | keys | length' "${MCP_FILE}")"
  [ "${count}" -gt 0 ]
}

# --- Requisito 10.3: Configuração do servidor Dart ---

@test "mcp.json: mcpServers.dart.command é 'dart'" {
  assert_json_field "${MCP_FILE}" '.mcpServers.dart.command' 'dart'
}

@test "mcp.json: mcpServers.dart.args é [\"mcp-server\"]" {
  local args
  args="$(jq -c '.mcpServers.dart.args' "${MCP_FILE}")"
  [ "${args}" = '["mcp-server"]' ]
}

@test "mcp.json: mcpServers.dart.disabled é false" {
  local disabled
  disabled="$(jq '.mcpServers.dart.disabled' "${MCP_FILE}")"
  [ "${disabled}" = "false" ]
}

@test "mcp.json: mcpServers.dart.autoApprove é array vazio" {
  local auto_approve
  auto_approve="$(jq -c '.mcpServers.dart.autoApprove' "${MCP_FILE}")"
  [ "${auto_approve}" = '[]' ]
}
