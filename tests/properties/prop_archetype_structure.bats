#!/usr/bin/env bats
# =============================================================================
# Property 1: Completude estrutural do archetype
# Feature: archetype-frontend-react, Property 1: Completude estrutural do archetype
# =============================================================================
# Para qualquer estrutura de archetype válida, cada diretório de categoria
# (steering/, hooks/, agents/, skills/, mcp/) SHALL conter ao menos 1 artefato
# funcional além do README.md, e um README.md de documentação.
#
# **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.8, 1.9**
# 20 iterações por property test.

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

# --- Diretórios de categoria do archetype frontend-react ---
CATEGORY_DIRS=("steering" "hooks" "agents" "skills" "mcp")

# --- Artefatos funcionais por categoria (excluindo README.md) ---
# steering: arquivos .md (exceto README)
# hooks: arquivos .kiro.hook
# agents: arquivos .md (exceto README)
# skills: arquivos .md (exceto README)
# mcp: mcp.json

# --- Função de validação de completude estrutural ---
# Verifica que cada diretório de categoria contém:
#   1. Um arquivo README.md
#   2. Ao menos 1 artefato funcional além do README.md
# Recebe o caminho raiz do archetype como argumento.
# Retorna 0 se válido, 1 se inválido.
validate_archetype_structure() {
  local archetype_dir="$1"

  # Verificar que o diretório raiz existe
  if [[ ! -d "$archetype_dir" ]]; then
    return 1
  fi

  local category
  for category in "${CATEGORY_DIRS[@]}"; do
    local cat_dir="${archetype_dir}/${category}"

    # Verificar que o diretório de categoria existe
    if [[ ! -d "$cat_dir" ]]; then
      return 1
    fi

    # Verificar presença do README.md
    if [[ ! -f "${cat_dir}/README.md" ]]; then
      return 1
    fi

    # Contar artefatos funcionais (tudo exceto README.md)
    local functional_count=0
    local file
    for file in "${cat_dir}"/*; do
      [[ ! -f "$file" ]] && continue
      local basename
      basename="$(basename "$file")"
      if [[ "$basename" != "README.md" ]]; then
        functional_count=$((functional_count + 1))
      fi
    done

    # Deve ter ao menos 1 artefato funcional
    if [[ ${functional_count} -lt 1 ]]; then
      return 1
    fi
  done

  return 0
}

# --- Gerador: cria uma estrutura de archetype completa (válida) ---
gen_valid_archetype() {
  local archetype_dir
  archetype_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-archetype-XXXXXX")"
  echo "${archetype_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # Criar diretórios de categoria com README e artefatos funcionais
  # steering/
  mkdir -p "${archetype_dir}/steering"
  echo "# Steering Files" > "${archetype_dir}/steering/README.md"
  local num_steering
  num_steering=$(_rand_int 1 5)
  local i
  for (( i = 0; i < num_steering; i++ )); do
    local name="$(_rand_lower "$(_rand_int 5 12)")"
    printf '%b\n' "---\ninclusion: auto\n---\n\n# ${name}" > "${archetype_dir}/steering/${name}.md"
  done

  # hooks/
  mkdir -p "${archetype_dir}/hooks"
  echo "# Hooks" > "${archetype_dir}/hooks/README.md"
  local num_hooks
  num_hooks=$(_rand_int 1 5)
  for (( i = 0; i < num_hooks; i++ )); do
    local hook_name="$(_rand_lower "$(_rand_int 5 12)")"
    cat > "${archetype_dir}/hooks/${hook_name}.kiro.hook" <<HOOKEOF
{
  "enabled": true,
  "name": "${hook_name}",
  "description": "Hook de teste",
  "version": "1",
  "when": { "type": "userTriggered" },
  "then": { "type": "askAgent", "prompt": "test" }
}
HOOKEOF
  done

  # agents/
  mkdir -p "${archetype_dir}/agents"
  echo "# Agents" > "${archetype_dir}/agents/README.md"
  local num_agents
  num_agents=$(_rand_int 1 4)
  for (( i = 0; i < num_agents; i++ )); do
    local agent_name="$(_rand_lower "$(_rand_int 5 12)")"
    printf '%b\n' "---\nname: \"Agent ${agent_name}\"\ndescription: \"Teste\"\n---\n\n# ${agent_name}\n\n## Referências\n- Ref" > "${archetype_dir}/agents/${agent_name}.md"
  done

  # skills/
  mkdir -p "${archetype_dir}/skills"
  echo "# Skills" > "${archetype_dir}/skills/README.md"
  local num_skills
  num_skills=$(_rand_int 1 5)
  for (( i = 0; i < num_skills; i++ )); do
    local skill_name="generate-$(_rand_lower "$(_rand_int 4 10)")"
    printf '%b\n' "---\nname: \"Skill ${skill_name}\"\ndescription: \"Gera algo\"\ninclusion: manual\n---\n\n# ${skill_name}" > "${archetype_dir}/skills/${skill_name}.md"
  done

  # mcp/
  mkdir -p "${archetype_dir}/mcp"
  echo "# MCP Config" > "${archetype_dir}/mcp/README.md"
  cat > "${archetype_dir}/mcp/mcp.json" <<MCPEOF
{
  "_comment": "MCP de teste",
  "_version": "0.1.0",
  "mcpServers": {
    "test-server": {
      "_comment": "Servidor de teste",
      "command": "npx",
      "args": ["-y", "test-mcp@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
MCPEOF

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype e remove artefatos aleatórios para torná-lo inválido ---
# Remove artefatos funcionais de ao menos 1 diretório de categoria,
# deixando apenas o README.md (violando Property 1).
gen_invalid_archetype() {
  local archetype_dir
  archetype_dir="$(gen_valid_archetype)"

  # Escolher estratégia de invalidação
  local strategy
  strategy=$(_rand_int 0 4)

  case ${strategy} in
    0)
      # Remover todos os artefatos funcionais de steering/ (deixando apenas README)
      find "${archetype_dir}/steering" -type f ! -name "README.md" -delete
      ;;
    1)
      # Remover todos os artefatos funcionais de hooks/
      find "${archetype_dir}/hooks" -type f ! -name "README.md" -delete
      ;;
    2)
      # Remover todos os artefatos funcionais de agents/
      find "${archetype_dir}/agents" -type f ! -name "README.md" -delete
      ;;
    3)
      # Remover todos os artefatos funcionais de skills/
      find "${archetype_dir}/skills" -type f ! -name "README.md" -delete
      ;;
    4)
      # Remover mcp.json de mcp/ (deixando apenas README)
      rm -f "${archetype_dir}/mcp/mcp.json"
      ;;
  esac

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype com diretório de categoria ausente ---
gen_archetype_missing_dir() {
  local archetype_dir
  archetype_dir="$(gen_valid_archetype)"

  # Remover um diretório de categoria aleatório
  local target_category
  target_category="$(_rand_choice "steering" "hooks" "agents" "skills" "mcp")"
  rm -rf "${archetype_dir}/${target_category}"

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype com README.md ausente em alguma categoria ---
gen_archetype_missing_readme() {
  local archetype_dir
  archetype_dir="$(gen_valid_archetype)"

  # Remover o README.md de uma categoria aleatória
  local target_category
  target_category="$(_rand_choice "steering" "hooks" "agents" "skills" "mcp")"
  rm -f "${archetype_dir}/${target_category}/README.md"

  echo "${archetype_dir}"
}

# =============================================================================
# Property Test: archetype válido DEVE ser aceito (20 iterações)
# =============================================================================
@test "Property 1a: archetype com estrutura completa é aceito pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_valid_archetype)"

    if ! validate_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype válido rejeitado"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/20 archetypes válidos"
}

# =============================================================================
# Property Test: archetype sem artefatos funcionais DEVE ser rejeitado (20 iter.)
# =============================================================================
@test "Property 1b: archetype sem artefatos funcionais em alguma categoria é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_invalid_archetype)"

    if validate_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype inválido aceito pela validação"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 archetypes inválidos"
}

# =============================================================================
# Property Test: archetype com diretório de categoria ausente DEVE ser rejeitado
# =============================================================================
@test "Property 1c: archetype com diretório de categoria ausente é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_archetype_missing_dir)"

    if validate_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype sem diretório de categoria aceito"
      echo "Estrutura:"
      find "${archetype_dir}" -type d | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 archetypes sem diretório de categoria"
}

# =============================================================================
# Property Test: archetype com README.md ausente em categoria DEVE ser rejeitado
# =============================================================================
@test "Property 1d: archetype com README.md ausente em alguma categoria é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_archetype_missing_readme)"

    if validate_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype sem README.md aceito"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 archetypes sem README.md"
}
