#!/usr/bin/env bats
# =============================================================================
# Property 1: Completude estrutural do archetype
# Feature: archetype-bff-fastify, Property 1: Completude estrutural do archetype
# =============================================================================
# Para qualquer estrutura de archetype bff-fastify válida, os diretórios
# steering/, hooks/, agents/, skills/ e mcp/ SHALL existir, cada um contendo
# um README.md (exceto mcp/), e além disso:
# - steering/ SHALL conter ao menos 4 arquivos .md (excl. README)
# - hooks/ SHALL conter ao menos 1 arquivo .kiro.hook
# - skills/ SHALL conter ao menos 1 arquivo .md (excl. README)
# - mcp/ SHALL conter um mcp.json
# - agents/ é caso especial: apenas README.md (sem artefatos funcionais)
#
# **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.9**
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

# --- Diretórios de categoria do archetype bff-fastify ---
CATEGORY_DIRS=("steering" "hooks" "agents" "skills" "mcp")

# --- Função de validação de completude estrutural para bff-fastify ---
# Regras específicas do BFF:
#   - steering/: README.md + ao menos 4 .md funcionais
#   - hooks/: README.md + ao menos 1 .kiro.hook
#   - agents/: apenas README.md (sem artefatos funcionais obrigatórios)
#   - skills/: README.md + ao menos 1 .md funcional
#   - mcp/: mcp.json (sem README.md obrigatório)
# Retorna 0 se válido, 1 se inválido.
validate_bff_archetype_structure() {
  local archetype_dir="$1"

  # Verificar que o diretório raiz existe
  if [[ ! -d "$archetype_dir" ]]; then
    return 1
  fi

  # Verificar que todos os diretórios de categoria existem
  local category
  for category in "${CATEGORY_DIRS[@]}"; do
    if [[ ! -d "${archetype_dir}/${category}" ]]; then
      return 1
    fi
  done

  # --- steering/: README.md + ao menos 4 .md funcionais ---
  if [[ ! -f "${archetype_dir}/steering/README.md" ]]; then
    return 1
  fi
  local steering_count=0
  local file
  for file in "${archetype_dir}/steering/"*.md; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "README.md" ]] && continue
    steering_count=$((steering_count + 1))
  done
  if [[ ${steering_count} -lt 4 ]]; then
    return 1
  fi

  # --- hooks/: README.md + ao menos 1 .kiro.hook ---
  if [[ ! -f "${archetype_dir}/hooks/README.md" ]]; then
    return 1
  fi
  local hooks_count=0
  for file in "${archetype_dir}/hooks/"*.kiro.hook; do
    [[ ! -f "$file" ]] && continue
    hooks_count=$((hooks_count + 1))
  done
  if [[ ${hooks_count} -lt 1 ]]; then
    return 1
  fi

  # --- agents/: apenas README.md (caso especial — sem artefatos funcionais) ---
  if [[ ! -f "${archetype_dir}/agents/README.md" ]]; then
    return 1
  fi

  # --- skills/: README.md + ao menos 1 .md funcional ---
  if [[ ! -f "${archetype_dir}/skills/README.md" ]]; then
    return 1
  fi
  local skills_count=0
  for file in "${archetype_dir}/skills/"*.md; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "README.md" ]] && continue
    skills_count=$((skills_count + 1))
  done
  if [[ ${skills_count} -lt 1 ]]; then
    return 1
  fi

  # --- mcp/: mcp.json (sem README.md obrigatório) ---
  if [[ ! -f "${archetype_dir}/mcp/mcp.json" ]]; then
    return 1
  fi

  return 0
}

# --- Gerador: cria uma estrutura de archetype bff-fastify completa (válida) ---
gen_valid_archetype() {
  local archetype_dir
  archetype_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-bff-archetype-XXXXXX")"
  echo "${archetype_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # steering/: README + 4-6 arquivos .md funcionais
  mkdir -p "${archetype_dir}/steering"
  echo "# Steering Files" > "${archetype_dir}/steering/README.md"
  local num_steering
  num_steering=$(_rand_int 4 6)
  local i
  for (( i = 0; i < num_steering; i++ )); do
    local name="$(_rand_lower "$(_rand_int 5 12)")"
    echo "# ${name}" > "${archetype_dir}/steering/${name}.md"
  done

  # hooks/: README + 1-6 arquivos .kiro.hook
  mkdir -p "${archetype_dir}/hooks"
  echo "# Hooks" > "${archetype_dir}/hooks/README.md"
  local num_hooks
  num_hooks=$(_rand_int 1 6)
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

  # agents/: apenas README.md (caso especial do bff-fastify)
  mkdir -p "${archetype_dir}/agents"
  echo "# Agents" > "${archetype_dir}/agents/README.md"

  # skills/: README + 1-4 arquivos .md funcionais
  mkdir -p "${archetype_dir}/skills"
  echo "# Skills" > "${archetype_dir}/skills/README.md"
  local num_skills
  num_skills=$(_rand_int 1 4)
  for (( i = 0; i < num_skills; i++ )); do
    local skill_name="generate-$(_rand_lower "$(_rand_int 4 10)")"
    printf '%b\n' "---\nname: \"Skill ${skill_name}\"\ndescription: \"Gera algo\"\ninclusion: manual\n---\n\n# ${skill_name}" > "${archetype_dir}/skills/${skill_name}.md"
  done

  # mcp/: apenas mcp.json (sem README.md obrigatório)
  mkdir -p "${archetype_dir}/mcp"
  cat > "${archetype_dir}/mcp/mcp.json" <<MCPEOF
{
  "_comment": "MCPs específicos do archetype bff-fastify",
  "_version": "0.1.0",
  "mcpServers": {}
}
MCPEOF

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype bff-fastify e remove artefatos para torná-lo inválido ---
# Estratégias de invalidação específicas para bff-fastify:
#   0 - Remover steering .md até ficar com menos de 4
#   1 - Remover todos os .kiro.hook de hooks/
#   2 - Remover todos os .md funcionais de skills/
#   3 - Remover mcp.json de mcp/
#   4 - Remover README.md de steering/
gen_invalid_archetype() {
  local archetype_dir
  archetype_dir="$(gen_valid_archetype)"

  local strategy
  strategy=$(_rand_int 0 4)

  case ${strategy} in
    0)
      # Remover steering .md até ficar com menos de 4 (deixar 0 a 3)
      local keep
      keep=$(_rand_int 0 3)
      local count=0
      for file in "${archetype_dir}/steering/"*.md; do
        [[ ! -f "$file" ]] && continue
        [[ "$(basename "$file")" == "README.md" ]] && continue
        if [[ ${count} -ge ${keep} ]]; then
          rm -f "$file"
        fi
        count=$((count + 1))
      done
      ;;
    1)
      # Remover todos os .kiro.hook de hooks/
      find "${archetype_dir}/hooks" -name "*.kiro.hook" -delete
      ;;
    2)
      # Remover todos os .md funcionais de skills/
      find "${archetype_dir}/skills" -name "*.md" ! -name "README.md" -delete
      ;;
    3)
      # Remover mcp.json de mcp/
      rm -f "${archetype_dir}/mcp/mcp.json"
      ;;
    4)
      # Remover README.md de steering/
      rm -f "${archetype_dir}/steering/README.md"
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

# --- Gerador: cria archetype com README.md ausente em categoria que requer ---
# (steering, hooks, agents, skills — mcp não requer README)
gen_archetype_missing_readme() {
  local archetype_dir
  archetype_dir="$(gen_valid_archetype)"

  # Remover o README.md de uma categoria que requer (não mcp/)
  local target_category
  target_category="$(_rand_choice "steering" "hooks" "agents" "skills")"
  rm -f "${archetype_dir}/${target_category}/README.md"

  echo "${archetype_dir}"
}

# =============================================================================
# Property Test: archetype válido DEVE ser aceito (20 iterações)
# =============================================================================
@test "Property 1a: archetype bff-fastify com estrutura completa é aceito pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_valid_archetype)"

    if ! validate_bff_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype válido rejeitado"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/20 archetypes válidos"
}

# =============================================================================
# Property Test: archetype sem artefatos funcionais suficientes DEVE ser rejeitado
# =============================================================================
@test "Property 1b: archetype bff-fastify sem artefatos funcionais suficientes é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_invalid_archetype)"

    if validate_bff_archetype_structure "${archetype_dir}"; then
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
@test "Property 1c: archetype bff-fastify com diretório de categoria ausente é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_archetype_missing_dir)"

    if validate_bff_archetype_structure "${archetype_dir}"; then
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
@test "Property 1d: archetype bff-fastify com README.md ausente em categoria é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_archetype_missing_readme)"

    if validate_bff_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype sem README.md aceito"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 archetypes sem README.md"
}
