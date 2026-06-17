#!/usr/bin/env bats
# =============================================================================
# Property 1: Completude estrutural do archetype
# Feature: archetype-backend-csharp, Property 1: Completude estrutural do archetype
# =============================================================================
# Para qualquer estrutura de archetype backend-csharp válida, os diretórios
# steering/, hooks/, agents/, skills/ e mcp/ SHALL existir, cada um contendo
# um README.md (exceto mcp/), e além disso:
# - steering/ SHALL conter exatamente 5 arquivos .md (excl. README)
# - hooks/ SHALL conter exatamente 7 arquivos .kiro.hook
# - skills/ SHALL conter exatamente 5 arquivos .md (excl. README)
# - mcp/ SHALL conter um mcp.json
# - agents/ é caso especial: apenas README.md (sem artefatos funcionais)
#
# **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.9, 10.1, 10.2**
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

# --- Diretórios de categoria do archetype backend-csharp ---
CATEGORY_DIRS=("steering" "hooks" "agents" "skills" "mcp")

# --- Função de validação de completude estrutural para backend-csharp ---
# Regras específicas do backend-csharp:
#   - steering/: README.md + exatamente 5 .md funcionais
#   - hooks/: README.md + exatamente 7 .kiro.hook
#   - agents/: apenas README.md (sem artefatos funcionais obrigatórios)
#   - skills/: README.md + exatamente 5 .md funcionais
#   - mcp/: mcp.json (sem README.md obrigatório)
# Retorna 0 se válido, 1 se inválido.
validate_csharp_archetype_structure() {
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

  # --- steering/: README.md + exatamente 5 .md funcionais ---
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
  if [[ ${steering_count} -ne 5 ]]; then
    return 1
  fi

  # --- hooks/: README.md + exatamente 7 .kiro.hook ---
  if [[ ! -f "${archetype_dir}/hooks/README.md" ]]; then
    return 1
  fi
  local hooks_count=0
  for file in "${archetype_dir}/hooks/"*.kiro.hook; do
    [[ ! -f "$file" ]] && continue
    hooks_count=$((hooks_count + 1))
  done
  if [[ ${hooks_count} -ne 7 ]]; then
    return 1
  fi

  # --- agents/: apenas README.md (caso especial — sem artefatos funcionais) ---
  if [[ ! -f "${archetype_dir}/agents/README.md" ]]; then
    return 1
  fi
  # Verificar que não há outros arquivos além de README.md
  local agents_extra=0
  for file in "${archetype_dir}/agents/"*; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "README.md" ]] && continue
    agents_extra=$((agents_extra + 1))
  done
  if [[ ${agents_extra} -ne 0 ]]; then
    return 1
  fi

  # --- skills/: README.md + exatamente 5 .md funcionais ---
  if [[ ! -f "${archetype_dir}/skills/README.md" ]]; then
    return 1
  fi
  local skills_count=0
  for file in "${archetype_dir}/skills/"*.md; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "README.md" ]] && continue
    skills_count=$((skills_count + 1))
  done
  if [[ ${skills_count} -ne 5 ]]; then
    return 1
  fi

  # --- mcp/: mcp.json (sem README.md obrigatório) ---
  if [[ ! -f "${archetype_dir}/mcp/mcp.json" ]]; then
    return 1
  fi

  return 0
}

# --- Gerador: cria uma estrutura de archetype backend-csharp completa (válida) ---
gen_valid_archetype() {
  local archetype_dir
  archetype_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-csharp-archetype-XXXXXX")"
  echo "${archetype_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # steering/: README + exatamente 5 arquivos .md funcionais
  mkdir -p "${archetype_dir}/steering"
  echo "# Steering Files" > "${archetype_dir}/steering/README.md"
  local steering_names=("architecture" "ci-cd" "data-governance" "naming-conventions" "stack-and-tooling")
  local i
  for i in "${steering_names[@]}"; do
    echo "# ${i}" > "${archetype_dir}/steering/${i}.md"
  done

  # hooks/: README + exatamente 7 arquivos .kiro.hook
  mkdir -p "${archetype_dir}/hooks"
  echo "# Hooks" > "${archetype_dir}/hooks/README.md"
  local hook_names=("build-after-agent" "kiro-doctor" "migration-reminder" "review-data-model" "review-domain-boundaries" "review-endpoint-quality" "run-tests-after-task")
  for i in "${hook_names[@]}"; do
    cat > "${archetype_dir}/hooks/${i}.kiro.hook" <<HOOKEOF
{
  "enabled": true,
  "name": "${i}",
  "description": "Hook de teste",
  "version": "1",
  "when": { "type": "userTriggered" },
  "then": { "type": "askAgent", "prompt": "test" }
}
HOOKEOF
  done

  # agents/: apenas README.md (caso especial do backend-csharp)
  mkdir -p "${archetype_dir}/agents"
  echo "# Agents" > "${archetype_dir}/agents/README.md"

  # skills/: README + exatamente 5 arquivos .md funcionais
  mkdir -p "${archetype_dir}/skills"
  echo "# Skills" > "${archetype_dir}/skills/README.md"
  local skill_names=("generate-data-model" "generate-endpoint" "generate-module" "generate-repository" "generate-validation-package")
  for i in "${skill_names[@]}"; do
    printf '%b\n' "---\nname: \"Skill ${i}\"\ndescription: \"Gera algo\"\ninclusion: manual\n---\n\n# ${i}" > "${archetype_dir}/skills/${i}.md"
  done

  # mcp/: apenas mcp.json (sem README.md obrigatório)
  mkdir -p "${archetype_dir}/mcp"
  cat > "${archetype_dir}/mcp/mcp.json" <<MCPEOF
{
  "_comment": "MCPs específicos do archetype backend-csharp. Mergeado com o baseline global no bootstrap.",
  "_version": "0.1.0",
  "mcpServers": {}
}
MCPEOF

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype backend-csharp e remove artefatos para torná-lo inválido ---
# Estratégias de invalidação específicas para backend-csharp:
#   0 - Remover steering .md até ficar com menos de 5
#   1 - Remover .kiro.hook de hooks/ até ficar com menos de 7
#   2 - Remover .md funcionais de skills/ até ficar com menos de 5
#   3 - Remover mcp.json de mcp/
#   4 - Remover README.md de steering/
#   5 - Adicionar arquivo extra em agents/ (viola "apenas README.md")
#   6 - Adicionar steering extra (viola contagem exata de 5)
gen_invalid_archetype() {
  local archetype_dir
  archetype_dir="$(gen_valid_archetype)"

  local strategy
  strategy=$(_rand_int 0 6)

  case ${strategy} in
    0)
      # Remover steering .md até ficar com menos de 5 (deixar 0 a 4)
      local keep
      keep=$(_rand_int 0 4)
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
      # Remover .kiro.hook de hooks/ até ficar com menos de 7 (deixar 0 a 6)
      local keep
      keep=$(_rand_int 0 6)
      local count=0
      for file in "${archetype_dir}/hooks/"*.kiro.hook; do
        [[ ! -f "$file" ]] && continue
        if [[ ${count} -ge ${keep} ]]; then
          rm -f "$file"
        fi
        count=$((count + 1))
      done
      ;;
    2)
      # Remover .md funcionais de skills/ até ficar com menos de 5 (deixar 0 a 4)
      local keep
      keep=$(_rand_int 0 4)
      local count=0
      for file in "${archetype_dir}/skills/"*.md; do
        [[ ! -f "$file" ]] && continue
        [[ "$(basename "$file")" == "README.md" ]] && continue
        if [[ ${count} -ge ${keep} ]]; then
          rm -f "$file"
        fi
        count=$((count + 1))
      done
      ;;
    3)
      # Remover mcp.json de mcp/
      rm -f "${archetype_dir}/mcp/mcp.json"
      ;;
    4)
      # Remover README.md de steering/
      rm -f "${archetype_dir}/steering/README.md"
      ;;
    5)
      # Adicionar arquivo extra em agents/ (viola "apenas README.md")
      local extra_name="$(_rand_lower "$(_rand_int 5 10)")"
      echo "# Extra agent" > "${archetype_dir}/agents/${extra_name}.md"
      ;;
    6)
      # Adicionar steering extra (viola contagem exata de 5)
      local extra_name="$(_rand_lower "$(_rand_int 5 10)")"
      echo "# Extra steering" > "${archetype_dir}/steering/${extra_name}.md"
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
@test "Property 1a: archetype backend-csharp com estrutura completa é aceito pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_valid_archetype)"

    if ! validate_csharp_archetype_structure "${archetype_dir}"; then
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
@test "Property 1b: archetype backend-csharp sem artefatos funcionais suficientes é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_invalid_archetype)"

    if validate_csharp_archetype_structure "${archetype_dir}"; then
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
@test "Property 1c: archetype backend-csharp com diretório de categoria ausente é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_archetype_missing_dir)"

    if validate_csharp_archetype_structure "${archetype_dir}"; then
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
@test "Property 1d: archetype backend-csharp com README.md ausente em categoria é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_archetype_missing_readme)"

    if validate_csharp_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype sem README.md aceito"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 archetypes sem README.md"
}
