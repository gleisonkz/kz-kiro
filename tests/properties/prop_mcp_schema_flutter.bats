#!/usr/bin/env bats
# =============================================================================
# Property 5: Schema de configuração MCP com servidor Dart
# Feature: archetype-mobile-flutter, Property 5: Schema de configuração MCP
# =============================================================================
# Para qualquer arquivo mcp.json válido do archetype mobile-flutter, ele SHALL
# conter: um campo _comment (string não-vazia), um campo _version (semver
# válido no formato MAJOR.MINOR.PATCH), e um objeto mcpServers contendo ao
# menos a entrada "dart" com campos command (valor "dart"), args (valor
# ["mcp-server"]), disabled (valor false) e autoApprove (array vazio).
#
# Diferença dos demais archetypes: mcpServers NÃO pode ser vazio — DEVE conter
# ao menos a entrada "dart" com os campos exatos acima.
#
# **Validates: Requirements 10.1, 10.2, 10.3**
# 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
  load '../helpers/assertions'
}

teardown() {
  cleanup_fixtures
}

# --- Função de validação de schema MCP para archetype mobile-flutter ---
# Valida os requisitos 10.1, 10.2, 10.3:
# - _comment: string não-vazia (10.1)
# - _version: semver válido MAJOR.MINOR.PATCH (10.2)
# - mcpServers.dart: command="dart", args=["mcp-server"], disabled=false, autoApprove=[] (10.3)
# Retorna 0 se válido, 1 se inválido.
validate_flutter_mcp_schema() {
  local json_content="$1"

  # Verificar se é JSON parseável
  if ! echo "${json_content}" | jq '.' > /dev/null 2>&1; then
    return 1
  fi

  # 1. _comment: string não-vazia (Req 10.1)
  local comment
  comment=$(echo "${json_content}" | jq -r '._comment // empty' 2>/dev/null)
  if [[ -z "${comment}" ]]; then
    return 1
  fi

  # 2. _version: semver válido MAJOR.MINOR.PATCH (Req 10.2)
  local version
  version=$(echo "${json_content}" | jq -r '._version // empty' 2>/dev/null)
  if [[ -z "${version}" ]]; then
    return 1
  fi
  if [[ ! "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    return 1
  fi

  # 3. mcpServers: deve ser um objeto
  local mcp_type
  mcp_type=$(echo "${json_content}" | jq -r '.mcpServers | type' 2>/dev/null)
  if [[ "${mcp_type}" != "object" ]]; then
    return 1
  fi

  # 4. mcpServers.dart: deve existir
  local has_dart
  has_dart=$(echo "${json_content}" | jq -r '.mcpServers | has("dart")' 2>/dev/null)
  if [[ "${has_dart}" != "true" ]]; then
    return 1
  fi

  # 5. mcpServers.dart.command: deve ser "dart"
  local dart_command
  dart_command=$(echo "${json_content}" | jq -r '.mcpServers.dart.command // empty' 2>/dev/null)
  if [[ "${dart_command}" != "dart" ]]; then
    return 1
  fi

  # 6. mcpServers.dart.args: deve ser ["mcp-server"]
  local dart_args
  dart_args=$(echo "${json_content}" | jq -c '.mcpServers.dart.args // null' 2>/dev/null)
  if [[ "${dart_args}" != '["mcp-server"]' ]]; then
    return 1
  fi

  # 7. mcpServers.dart.disabled: deve ser false
  local dart_disabled
  dart_disabled=$(echo "${json_content}" | jq -r '.mcpServers.dart.disabled' 2>/dev/null)
  if [[ "${dart_disabled}" != "false" ]]; then
    return 1
  fi

  # 8. mcpServers.dart.autoApprove: deve ser array vazio
  local dart_auto_approve
  dart_auto_approve=$(echo "${json_content}" | jq -c '.mcpServers.dart.autoApprove // null' 2>/dev/null)
  if [[ "${dart_auto_approve}" != "[]" ]]; then
    return 1
  fi

  return 0
}

# --- Gerador de mcp.json válido para archetype mobile-flutter ---
# Gera JSONs que seguem requisitos 10.1-10.3.
# Sempre inclui mcpServers.dart com os campos obrigatórios.
# Opcionalmente inclui outros servidores (não devem quebrar a validação).
gen_valid_flutter_mcp() {
  local version
  version="$(gen_semver)"

  # Comment aleatório mencionando mobile-flutter
  local comment_suffix
  comment_suffix="$(_rand_alpha "$(_rand_int 5 15)")"
  local comment="MCPs específicos do archetype mobile-flutter - ${comment_suffix}"

  # Decidir se inclui servidores adicionais (50% chance)
  local extra_servers=""
  if (( RANDOM % 2 == 0 )); then
    local num_extra
    num_extra=$(_rand_int 1 3)
    local i
    for (( i = 0; i < num_extra; i++ )); do
      local server_name="$(_rand_lower "$(_rand_int 4 10)")"
      local server_comment="Servidor extra $(_rand_alpha 5)"
      local server_obj

      # Servidor extra pode ser url ou command (variado)
      if (( RANDOM % 2 == 0 )); then
        server_obj=$(cat <<SEOF
    "${server_name}": {
      "_comment": "${server_comment}",
      "url": "https://$(_rand_lower 6).example.com/mcp",
      "disabled": $(_rand_choice "true" "false"),
      "autoApprove": []
    }
SEOF
)
      else
        server_obj=$(cat <<SEOF
    "${server_name}": {
      "_comment": "${server_comment}",
      "command": "$(_rand_lower 4)",
      "args": ["run", "--$(_rand_lower 4)"],
      "disabled": $(_rand_choice "true" "false"),
      "autoApprove": []
    }
SEOF
)
      fi

      extra_servers="${extra_servers},
${server_obj}"
    done
  fi

  cat <<EOF
{
  "_comment": "${comment}",
  "_version": "${version}",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server - $(_rand_alpha 5)",
      "command": "dart",
      "args": ["mcp-server"],
      "disabled": false,
      "autoApprove": []
    }${extra_servers}
  }
}
EOF
}

# --- Gerador de mcp.json INVÁLIDO para archetype mobile-flutter ---
# Gera JSONs que violam ao menos um dos requisitos 10.1-10.3.
gen_invalid_flutter_mcp() {
  local strategy
  strategy=$(_rand_int 0 9)

  case "$strategy" in
    0) # _comment ausente (viola 10.1)
      cat <<EOF
{
  "_version": "1.0.0",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server",
      "command": "dart",
      "args": ["mcp-server"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    1) # _comment vazio (viola 10.1)
      cat <<EOF
{
  "_comment": "",
  "_version": "1.0.0",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server",
      "command": "dart",
      "args": ["mcp-server"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    2) # _version inválida - não é semver (viola 10.2)
      local invalid_version
      invalid_version=$(_rand_choice "invalid" "v1.0.0" "1.0" "1.0.0.0" "01.0.0" "" "abc")
      cat <<EOF
{
  "_comment": "MCPs mobile-flutter",
  "_version": "${invalid_version}",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server",
      "command": "dart",
      "args": ["mcp-server"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    3) # mcpServers.dart ausente (viola 10.3)
      cat <<EOF
{
  "_comment": "MCPs mobile-flutter",
  "_version": "1.0.0",
  "mcpServers": {
    "other-server": {
      "_comment": "Outro servidor",
      "command": "node",
      "args": ["server.js"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    4) # mcpServers.dart.command errado - não é "dart" (viola 10.3)
      local wrong_cmd
      wrong_cmd=$(_rand_choice "node" "python" "flutter" "npx" "deno")
      cat <<EOF
{
  "_comment": "MCPs mobile-flutter",
  "_version": "1.0.0",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server",
      "command": "${wrong_cmd}",
      "args": ["mcp-server"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    5) # mcpServers.dart.args errado - não é ["mcp-server"] (viola 10.3)
      local wrong_args
      wrong_args=$(_rand_choice '["run","mcp"]' '["server"]' '["mcp-server","--verbose"]' '[]' '["analyze"]')
      cat <<EOF
{
  "_comment": "MCPs mobile-flutter",
  "_version": "1.0.0",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server",
      "command": "dart",
      "args": ${wrong_args},
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    6) # mcpServers.dart.disabled é true (viola 10.3)
      cat <<EOF
{
  "_comment": "MCPs mobile-flutter",
  "_version": "1.0.0",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server",
      "command": "dart",
      "args": ["mcp-server"],
      "disabled": true,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    7) # mcpServers.dart.autoApprove não-vazio (viola 10.3)
      local non_empty_approve
      non_empty_approve=$(_rand_choice '["read"]' '["write","read"]' '["analyze"]' '["*"]')
      cat <<EOF
{
  "_comment": "MCPs mobile-flutter",
  "_version": "1.0.0",
  "mcpServers": {
    "dart": {
      "_comment": "Dart MCP Server",
      "command": "dart",
      "args": ["mcp-server"],
      "disabled": false,
      "autoApprove": ${non_empty_approve}
    }
  }
}
EOF
      ;;
    8) # JSON malformado
      local malformed
      malformed=$(_rand_choice \
        '{"_comment": "test", "_version": "1.0.0", "mcpServers":' \
        '{_comment: "test"}' \
        'not json at all' \
        '{"unclosed": "string' \
        '')
      echo "${malformed}"
      ;;
    9) # mcpServers é objeto vazio — sem entrada dart (viola 10.3)
      cat <<EOF
{
  "_comment": "MCPs mobile-flutter",
  "_version": "1.0.0",
  "mcpServers": {}
}
EOF
      ;;
  esac
}

# =============================================================================
# Property Test 5a: mcp.json válido do Flutter é aceito (100 iterações)
# =============================================================================
@test "Property 5a: mcp.json válido do mobile-flutter é aceito pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_valid_flutter_mcp)"

    if ! validate_flutter_mcp_schema "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON válido rejeitado"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 JSONs válidos"
}

# =============================================================================
# Property Test 5b: mcp.json inválido do Flutter é rejeitado (100 iterações)
# =============================================================================
@test "Property 5b: mcp.json inválido do mobile-flutter é rejeitado pela validação (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local json_content
    json_content="$(gen_invalid_flutter_mcp)"

    if validate_flutter_mcp_schema "${json_content}"; then
      echo "FALHA na iteração ${i}: JSON inválido aceito"
      echo "JSON gerado: ${json_content}"
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 JSONs inválidos"
}

# =============================================================================
# Property Test 5c: mcp.json real do archetype mobile-flutter passa na validação
# =============================================================================
@test "Property 5c: mcp.json real do archetype mobile-flutter passa na validação" {
  local mcp_file="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter/mcp/mcp.json"

  # Verifica que o arquivo existe
  [[ -f "${mcp_file}" ]] || fail "mcp.json não encontrado em ${mcp_file}"

  local json_content
  json_content="$(cat "${mcp_file}")"

  if ! validate_flutter_mcp_schema "${json_content}"; then
    echo "mcp.json real do archetype não passou na validação:"
    echo "${json_content}"
    fail "mcp.json real do archetype mobile-flutter é inválido segundo Property 5"
  fi
}
