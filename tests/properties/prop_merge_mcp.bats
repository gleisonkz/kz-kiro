#!/usr/bin/env bats
# =============================================================================
# Property Test 4: Merge de mcp.json preserva todos os servidores
# Feature: baseline-global
# Property 4: Merge de mcp.json preserva todos os servidores
#
# Para quaisquer dois objetos mcp.json válidos (baseline e archetype), o merge
# SHALL produzir um objeto contendo todos os servidores de ambos, e quando uma
# chave existe em ambos, o valor do archetype tem precedência sobre o baseline.
#
# **Validates: Requirements 4.3**
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/generators'
load '../helpers/assertions'
load '../lib/bats-assert/load'
load '../lib/bats-support/load'

# --- Função de merge de mcp.json ---
# Reproduz a lógica de merge do bootstrap.sh:
#   jq -s '.[0].mcpServers * .[1].mcpServers'
# Onde o segundo argumento (archetype) tem precedência sobre o primeiro (baseline).
# Retorna o JSON mergeado via stdout.
merge_mcp_json() {
  local baseline_json="$1"
  local archetype_json="$2"

  jq -s '
    {
      "_comment": "MCPs mergeados para teste",
      "_version": "0.1.0",
      "mcpServers": (.[0].mcpServers * .[1].mcpServers)
    }
  ' <(echo "${baseline_json}") <(echo "${archetype_json}")
}

# --- Testes de propriedade ---

@test "Property 4: merge de mcp.json contém todos os servidores de ambas as fontes (100 iterações)" {
  # bats test_tags=property, merge-mcp
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local baseline_json archetype_json merged_json
    baseline_json="$(gen_mcp_json)"
    archetype_json="$(gen_mcp_json)"

    merged_json="$(merge_mcp_json "${baseline_json}" "${archetype_json}")"

    # Verificar que o merge produziu JSON válido
    if ! echo "${merged_json}" | jq '.' > /dev/null 2>&1; then
      echo "FALHA na iteração ${i}: merge não produziu JSON válido"
      echo "Baseline: ${baseline_json}"
      echo "Archetype: ${archetype_json}"
      failures=$((failures + 1))
      continue
    fi

    # Extrair chaves de servidores de cada fonte
    local baseline_keys archetype_keys merged_keys
    baseline_keys=$(echo "${baseline_json}" | jq -r '.mcpServers | keys[]' 2>/dev/null | sort)
    archetype_keys=$(echo "${archetype_json}" | jq -r '.mcpServers | keys[]' 2>/dev/null | sort)
    merged_keys=$(echo "${merged_json}" | jq -r '.mcpServers | keys[]' 2>/dev/null | sort)

    # Todas as chaves do baseline devem estar no merge
    while IFS= read -r key; do
      [[ -z "${key}" ]] && continue
      if ! echo "${merged_keys}" | grep -qxF "${key}"; then
        echo "FALHA na iteração ${i}: servidor '${key}' do baseline ausente no merge"
        echo "Baseline keys: ${baseline_keys}"
        echo "Merged keys: ${merged_keys}"
        failures=$((failures + 1))
        break
      fi
    done <<< "${baseline_keys}"

    # Todas as chaves do archetype devem estar no merge
    while IFS= read -r key; do
      [[ -z "${key}" ]] && continue
      if ! echo "${merged_keys}" | grep -qxF "${key}"; then
        echo "FALHA na iteração ${i}: servidor '${key}' do archetype ausente no merge"
        echo "Archetype keys: ${archetype_keys}"
        echo "Merged keys: ${merged_keys}"
        failures=$((failures + 1))
        break
      fi
    done <<< "${archetype_keys}"
  done

  [[ ${failures} -eq 0 ]] || fail "Merge falhou em ${failures}/100 iterações"
}

@test "Property 4: archetype tem precedência sobre baseline em caso de conflito de chaves (100 iterações)" {
  # bats test_tags=property, merge-mcp
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    # Gerar um nome de servidor compartilhado (conflito intencional)
    local shared_server="_server_$(_rand_lower 4)"

    # Gerar baseline com o servidor compartilhado
    local baseline_json
    baseline_json=$(cat <<EOF
{
  "_comment": "Baseline com servidor compartilhado - iteração ${i}",
  "_version": "$(gen_semver)",
  "mcpServers": {
    "${shared_server}": {
      "_comment": "Versão BASELINE do servidor",
      "url": "https://baseline.example.com/mcp",
      "disabled": false,
      "autoApprove": []
    },
    "_server_only_baseline_$(_rand_lower 3)": {
      "_comment": "Servidor exclusivo do baseline",
      "command": "baseline-cmd",
      "args": ["--run"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
)

    # Gerar archetype com o mesmo servidor compartilhado (valores diferentes)
    local archetype_json
    archetype_json=$(cat <<EOF
{
  "_comment": "Archetype com servidor compartilhado - iteração ${i}",
  "_version": "$(gen_semver)",
  "mcpServers": {
    "${shared_server}": {
      "_comment": "Versão ARCHETYPE do servidor",
      "url": "https://archetype.example.com/mcp",
      "disabled": true,
      "autoApprove": []
    },
    "_server_only_archetype_$(_rand_lower 3)": {
      "_comment": "Servidor exclusivo do archetype",
      "command": "archetype-cmd",
      "args": ["--start"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
)

    local merged_json
    merged_json="$(merge_mcp_json "${baseline_json}" "${archetype_json}")"

    # Verificar que o merge produziu JSON válido
    if ! echo "${merged_json}" | jq '.' > /dev/null 2>&1; then
      echo "FALHA na iteração ${i}: merge não produziu JSON válido"
      failures=$((failures + 1))
      continue
    fi

    # Verificar precedência: o valor do servidor compartilhado deve ser o do archetype
    local merged_comment merged_url merged_disabled
    merged_comment=$(echo "${merged_json}" | jq -r ".mcpServers[\"${shared_server}\"]._comment" 2>/dev/null)
    merged_url=$(echo "${merged_json}" | jq -r ".mcpServers[\"${shared_server}\"].url" 2>/dev/null)
    merged_disabled=$(echo "${merged_json}" | jq -r ".mcpServers[\"${shared_server}\"].disabled" 2>/dev/null)

    if [[ "${merged_comment}" != "Versão ARCHETYPE do servidor" ]]; then
      echo "FALHA na iteração ${i}: _comment deveria ser do archetype, mas é '${merged_comment}'"
      failures=$((failures + 1))
      continue
    fi

    if [[ "${merged_url}" != "https://archetype.example.com/mcp" ]]; then
      echo "FALHA na iteração ${i}: url deveria ser do archetype, mas é '${merged_url}'"
      failures=$((failures + 1))
      continue
    fi

    if [[ "${merged_disabled}" != "true" ]]; then
      echo "FALHA na iteração ${i}: disabled deveria ser true (archetype), mas é '${merged_disabled}'"
      failures=$((failures + 1))
      continue
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Precedência falhou em ${failures}/100 iterações"
}
