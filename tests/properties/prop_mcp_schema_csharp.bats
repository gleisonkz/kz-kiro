#!/usr/bin/env bats
# =============================================================================
# Property 5: Schema de configuração MCP
# Feature: archetype-backend-csharp, Property 5: Schema de configuração MCP
# =============================================================================
# Para qualquer arquivo mcp.json válido do archetype backend-csharp, ele SHALL
# conter: um campo _comment (string não-vazia), um campo _version (semver
# válido no formato MAJOR.MINOR.PATCH) e um campo mcpServers (objeto — pode
# estar vazio).
#
# Diferença do baseline: mcpServers={} é VÁLIDO para backend-csharp (não há
# servidores MCP específicos; herda do baseline global via merge no bootstrap).
#
# **Validates: Requirements 9.1, 9.2**
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

# --- Função de validação de schema MCP para archetype backend-csharp ---
# Valida os requisitos 9.1 e 9.2:
# - _comment: string não-vazia (9.1)
# - _version: semver válido MAJOR.MINOR.PATCH (9.1)
# - mcpServers: objeto (pode ser vazio) (9.1, 9.2)
# Retorna 0 se válido, 1 se inválido.
validate_mcp_schema_csharp() {
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

  # 3. mcpServers: deve ser um objeto (pode estar vazio — Req 9.2)
  local mcp_type
  mcp_type=$(echo "${json_content}" | jq -r '.mcpServers | type' 2>/dev/null)
  if [[ "${mcp_type}" != "object" ]]; then
    return 1
  fi

  return 0
}

# --- Gerador de mcp.json válido para archetype backend-csharp ---
# Gera JSONs que seguem requisitos 9.1-9.2.
# mcpServers pode ser vazio ou com servidores (ambos válidos).
gen_valid_mcp_csharp() {
  local version
  version="$(gen_semver)"

  # Decisão: 70% vazio (cenário principal do backend-csharp), 30% com servidores
  local use_empty=$(( RANDOM % 10 ))

  if [[ ${use_empty} -lt 7 ]]; then
    # mcpServers vazio — cenário principal do backend-csharp
    cat <<EOF
{
  "_comment": "MCPs específicos do archetype backend-csharp - $(_rand_alpha 8)",
  "_version": "${version}",
  "mcpServers": {}
}
EOF
  else
    # mcpServers com servidores — também é válido estruturalmente
    local num_servers
    num_servers=$(_rand_int 1 2)
    local servers=""
    local i

    for (( i = 0; i < num_servers; i++ )); do
      local server_name="$(_rand_lower "$(_rand_int 4 10)")-$(_rand_lower "$(_rand_int 3 6)")"
      local comment="Servidor $(_rand_alpha 5) - $(_rand_alpha "$(_rand_int 5 15)")"
      local server_obj

      server_obj=$(cat <<SEOF
    "${server_name}": {
      "_comment": "${comment}",
      "command": "$(_rand_choice "dotnet" "npx" "node")",
      "args": ["run", "--$(_rand_lower 4)"],
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
  "_comment": "MCPs específicos do archetype backend-csharp - $(_rand_alpha 8)",
  "_version": "${version}",
  "mcpServers": {
${servers}
  }
}
EOF
  fi
}

# --- Gerador de mcp.json INVÁLIDO para archetype backend-csharp ---
# Gera JSONs que violam ao menos um dos requisitos 9.1-9.2.
# NOTA: mcpServers={} é VÁLIDO para backend-csharp, diferente do baseline.
gen_invalid_mcp_csharp() {
  local strategy
  strategy=$(_rand_int 0 6)

  case "$strategy" in
    0) # Sem _comment (viola 9.1)
      cat <<EOF
{
  "_version": "1.0.0",
  "mcpServers": {}
}
EOF
      ;;
    1) # _comment vazio (viola 9.1)
      cat <<EOF
{
  "_comment": "",
  "_version": "1.0.0",
  "mcpServers": {}
}
EOF
      ;;
    2) # _version inválida - não é semver (viola 9.1)
      local invalid_version
      invalid_version=$(_rand_choice "invalid" "v1.0.0" "1.0" "1.0.0.0" "01.0.0" "" "abc")
      cat <<EOF
{
  "_comment": "MCPs backend-csharp",
  "_version": "${invalid_version}",
  "mcpServers": {}
}
EOF
      ;;
    3) # mcpServers não é objeto - é array (viola 9.1)
      cat <<EOF
{
  "_comment": "MCPs backend-csharp",
  "_version": "1.0.0",
  "mcpServers": []
}
EOF
      ;;
    4) # mcpServers não é objeto - é string (viola 9.1)
      cat <<EOF
{
  "_comment": "MCPs backend-csharp",
  "_version": "1.0.0",
  "mcpServers": "nao-eh-objeto"
}
EOF
      ;;
    5) # mcpServers ausente (viola 9.1)
      cat <<EOF
{
  "_comment": "MCPs backend-csharp",
  "_version": "1.0.0"
}
EOF
      ;;
    6) # JSON inválido (não parseável)
      echo "{ _comment: sem aspas, versao: invalido }"
      ;;
  esac
}

# =============================================================================
# Property Test 5a: mcp.json válido do backend-csharp é aceito (100 iterações)
# =============================================================================
@test "Property 5a: mcp.json válido do backend-csharp é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_valid_mcp_csharp)"

    if ! validate_mcp_schema_csharp "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON válido rejeitado"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 JSONs válidos"
}

# =============================================================================
# Property Test 5b: mcp.json inválido do backend-csharp é rejeitado (100 iterações)
# =============================================================================
@test "Property 5b: mcp.json inválido do backend-csharp é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_invalid_mcp_csharp)"

    if validate_mcp_schema_csharp "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON inválido aceito"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 JSONs inválidos"
}

# =============================================================================
# Property Test 5c: mcpServers vazio é explicitamente VÁLIDO para backend-csharp (100 iterações)
# =============================================================================
@test "Property 5c: mcpServers vazio é válido para backend-csharp (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local version
    version="$(gen_semver)"
    local json_content
    json_content=$(cat <<EOF
{
  "_comment": "MCPs específicos do archetype backend-csharp - iteração ${i} - $(_rand_alpha 5)",
  "_version": "${version}",
  "mcpServers": {}
}
EOF
)

    if ! validate_mcp_schema_csharp "${json_content}"; then
      echo "FALHA na iteração ${i}: mcpServers vazio rejeitado"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 JSONs com mcpServers vazio"
}

# =============================================================================
# Property Test 5d: mcp.json real do archetype backend-csharp é válido
# =============================================================================
@test "Property 5d: mcp.json real do archetype backend-csharp passa na validação" {
  local mcp_file="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp/mcp/mcp.json"

  # Verifica que o arquivo existe
  [[ -f "${mcp_file}" ]] || fail "mcp.json não encontrado em ${mcp_file}"

  local json_content
  json_content="$(cat "${mcp_file}")"

  if ! validate_mcp_schema_csharp "${json_content}"; then
    echo "mcp.json real do archetype não passou na validação:"
    echo "${json_content}"
    fail "mcp.json real do archetype backend-csharp é inválido segundo Property 5"
  fi
}
