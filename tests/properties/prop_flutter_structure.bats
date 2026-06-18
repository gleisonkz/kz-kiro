#!/usr/bin/env bats
# =============================================================================
# Property 1: Completude estrutural do archetype
# Feature: archetype-mobile-flutter, Property 1: Completude estrutural do archetype
# =============================================================================
# Para qualquer estrutura de archetype mobile-flutter válida, os diretórios
# steering/, hooks/, agents/, skills/ e mcp/ SHALL existir, cada um contendo
# um README.md (exceto mcp/), e além disso:
# - steering/ SHALL conter exatamente 15 arquivos .md (excl. README)
# - hooks/ SHALL conter exatamente 5 arquivos .kiro.hook
# - agents/ SHALL conter apenas README.md (sem artefatos funcionais)
# - skills/ SHALL conter apenas README.md (sem artefatos funcionais)
# - mcp/ SHALL conter um mcp.json com entrada "dart"
# - A raiz SHALL NÃO conter VERSION nem CHANGELOG.md
#
# **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 11.2, 12.2, 13.1, 13.2**
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

# --- Diretórios de categoria do archetype mobile-flutter ---
CATEGORY_DIRS=("steering" "hooks" "agents" "skills" "mcp")

# --- Nomes esperados dos 15 steering files funcionais ---
EXPECTED_STEERING_FILES=(
  "coding-standards.md"
  "flutter_best_practices.md"
  "clean-architecture.md"
  "flutter-clean-architecture.md"
  "flutter-lints-security.md"
  "flutter-testing-patterns.md"
  "dependency-management.md"
  "design-system.md"
  "code-review.md"
  "auth-api.md"
  "forgot-password-api.md"
  "home-api.md"
  "notifications-api.md"
  "profile-api.md"
  "settings-api.md"
)

# --- Nomes esperados dos 5 hooks ---
EXPECTED_HOOKS=(
  "dart-analyze-save.kiro.hook"
  "check-relative-imports.kiro.hook"
  "barrel-export-reminder.kiro.hook"
  "scaffold-test-file.kiro.hook"
  "kiro-doctor.kiro.hook"
)

# --- Função de validação de completude estrutural para mobile-flutter ---
# Regras específicas do mobile-flutter:
#   - steering/: README.md + exatamente 15 .md funcionais
#   - hooks/: README.md + exatamente 5 .kiro.hook
#   - agents/: apenas README.md (sem artefatos funcionais)
#   - skills/: apenas README.md (sem artefatos funcionais)
#   - mcp/: mcp.json com entrada "dart" (sem README.md obrigatório)
#   - raiz: README.md presente, VERSION e CHANGELOG.md AUSENTES
# Retorna 0 se válido, 1 se inválido.
validate_flutter_archetype_structure() {
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

  # --- README.md na raiz ---
  if [[ ! -f "${archetype_dir}/README.md" ]]; then
    return 1
  fi

  # --- Ausência obrigatória de VERSION e CHANGELOG.md ---
  if [[ -f "${archetype_dir}/VERSION" ]]; then
    return 1
  fi
  if [[ -f "${archetype_dir}/CHANGELOG.md" ]]; then
    return 1
  fi

  # --- steering/: README.md + exatamente 15 .md funcionais ---
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
  if [[ ${steering_count} -ne 15 ]]; then
    return 1
  fi

  # --- hooks/: README.md + exatamente 5 .kiro.hook ---
  if [[ ! -f "${archetype_dir}/hooks/README.md" ]]; then
    return 1
  fi
  local hooks_count=0
  for file in "${archetype_dir}/hooks/"*.kiro.hook; do
    [[ ! -f "$file" ]] && continue
    hooks_count=$((hooks_count + 1))
  done
  if [[ ${hooks_count} -ne 5 ]]; then
    return 1
  fi

  # --- agents/: apenas README.md (sem artefatos funcionais) ---
  if [[ ! -f "${archetype_dir}/agents/README.md" ]]; then
    return 1
  fi
  local agents_extra=0
  for file in "${archetype_dir}/agents/"*.md; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "README.md" ]] && continue
    agents_extra=$((agents_extra + 1))
  done
  if [[ ${agents_extra} -ne 0 ]]; then
    return 1
  fi

  # --- skills/: apenas README.md (sem artefatos funcionais) ---
  if [[ ! -f "${archetype_dir}/skills/README.md" ]]; then
    return 1
  fi
  local skills_extra=0
  for file in "${archetype_dir}/skills/"*.md; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "README.md" ]] && continue
    skills_extra=$((skills_extra + 1))
  done
  if [[ ${skills_extra} -ne 0 ]]; then
    return 1
  fi

  # --- mcp/: mcp.json com entrada "dart" ---
  if [[ ! -f "${archetype_dir}/mcp/mcp.json" ]]; then
    return 1
  fi
  # Verificar que mcpServers contém entrada "dart"
  if ! command -v jq &>/dev/null; then
    # Fallback: verificar via grep
    if ! grep -q '"dart"' "${archetype_dir}/mcp/mcp.json"; then
      return 1
    fi
  else
    local dart_entry
    dart_entry="$(jq -r '.mcpServers.dart' "${archetype_dir}/mcp/mcp.json" 2>/dev/null)"
    if [[ "$dart_entry" == "null" || -z "$dart_entry" ]]; then
      return 1
    fi
  fi

  return 0
}

# --- Gerador: cria uma estrutura de archetype mobile-flutter completa (válida) ---
gen_valid_flutter_archetype() {
  local archetype_dir
  archetype_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-flutter-archetype-XXXXXX")"
  echo "${archetype_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # README.md na raiz
  echo "# Archetype Mobile Flutter v0.1.0" > "${archetype_dir}/README.md"

  # steering/: README + exatamente 15 arquivos .md funcionais
  mkdir -p "${archetype_dir}/steering"
  echo "# Steering Files - v0.1.0" > "${archetype_dir}/steering/README.md"
  local sf
  for sf in "${EXPECTED_STEERING_FILES[@]}"; do
    printf '%b\n' "---\ninclusion: auto\n---\n\n# ${sf}\n\nConteúdo de teste." > "${archetype_dir}/steering/${sf}"
  done

  # hooks/: README + exatamente 5 arquivos .kiro.hook
  mkdir -p "${archetype_dir}/hooks"
  echo "# Hooks - v0.1.0" > "${archetype_dir}/hooks/README.md"
  local hk
  for hk in "${EXPECTED_HOOKS[@]}"; do
    cat > "${archetype_dir}/hooks/${hk}" <<HOOKEOF
{
  "enabled": true,
  "name": "${hk%.kiro.hook}",
  "description": "Hook de teste",
  "version": "1",
  "when": { "type": "userTriggered" },
  "then": { "type": "askAgent", "prompt": "test" }
}
HOOKEOF
  done

  # agents/: apenas README.md
  mkdir -p "${archetype_dir}/agents"
  echo "# Agents - v0.1.0" > "${archetype_dir}/agents/README.md"

  # skills/: apenas README.md
  mkdir -p "${archetype_dir}/skills"
  echo "# Skills - v0.1.0" > "${archetype_dir}/skills/README.md"

  # mcp/: mcp.json com servidor dart funcional
  mkdir -p "${archetype_dir}/mcp"
  cat > "${archetype_dir}/mcp/mcp.json" <<MCPEOF
{
  "_comment": "MCPs específicos do archetype mobile-flutter. Mergeado com o baseline global no bootstrap.",
  "_version": "0.1.0",
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
MCPEOF

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype flutter e remove artefatos para torná-lo inválido ---
# Estratégias de invalidação específicas para mobile-flutter:
#   0 - Remover steering .md até ficar com menos de 15
#   1 - Remover .kiro.hook até ficar com menos de 5
#   2 - Adicionar arquivo funcional .md em agents/ (violação: apenas README.md)
#   3 - Adicionar arquivo funcional .md em skills/ (violação: apenas README.md)
#   4 - Remover mcp.json de mcp/
#   5 - Remover entrada "dart" de mcp.json
#   6 - Remover README.md de steering/
gen_invalid_flutter_archetype() {
  local archetype_dir
  archetype_dir="$(gen_valid_flutter_archetype)"

  local strategy
  strategy=$(_rand_int 0 6)

  case ${strategy} in
    0)
      # Remover steering .md até ficar com menos de 15 (remover 1 a 5 aleatórios)
      local to_remove
      to_remove=$(_rand_int 1 5)
      local count=0
      for file in "${archetype_dir}/steering/"*.md; do
        [[ ! -f "$file" ]] && continue
        [[ "$(basename "$file")" == "README.md" ]] && continue
        if [[ ${count} -lt ${to_remove} ]]; then
          rm -f "$file"
        fi
        count=$((count + 1))
      done
      ;;
    1)
      # Remover .kiro.hook até ficar com menos de 5 (remover 1 a 3 aleatórios)
      local to_remove
      to_remove=$(_rand_int 1 3)
      local count=0
      for file in "${archetype_dir}/hooks/"*.kiro.hook; do
        [[ ! -f "$file" ]] && continue
        if [[ ${count} -lt ${to_remove} ]]; then
          rm -f "$file"
        fi
        count=$((count + 1))
      done
      ;;
    2)
      # Adicionar arquivo funcional .md em agents/ (violação)
      printf '%b\n' "---\nname: agent-ilegal\n---\n\n# Agent Funcional" > "${archetype_dir}/agents/architecture-reviewer.md"
      ;;
    3)
      # Adicionar arquivo funcional .md em skills/ (violação)
      printf '%b\n' "---\nname: skill-ilegal\ninclusion: manual\n---\n\n# Skill Funcional" > "${archetype_dir}/skills/generate-feature.md"
      ;;
    4)
      # Remover mcp.json de mcp/
      rm -f "${archetype_dir}/mcp/mcp.json"
      ;;
    5)
      # Remover entrada "dart" de mcp.json (substituir por mcpServers vazio)
      cat > "${archetype_dir}/mcp/mcp.json" <<MCPEOF
{
  "_comment": "MCPs sem dart server",
  "_version": "0.1.0",
  "mcpServers": {}
}
MCPEOF
      ;;
    6)
      # Remover README.md de steering/
      rm -f "${archetype_dir}/steering/README.md"
      ;;
  esac

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype com diretório de categoria ausente ---
gen_flutter_archetype_missing_dir() {
  local archetype_dir
  archetype_dir="$(gen_valid_flutter_archetype)"

  # Remover um diretório de categoria aleatório
  local target_category
  target_category="$(_rand_choice "steering" "hooks" "agents" "skills" "mcp")"
  rm -rf "${archetype_dir}/${target_category}"

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype com README.md ausente em categoria que requer ---
# (steering, hooks, agents, skills — mcp não requer README)
gen_flutter_archetype_missing_readme() {
  local archetype_dir
  archetype_dir="$(gen_valid_flutter_archetype)"

  # Remover o README.md de uma categoria que requer (não mcp/)
  local target_category
  target_category="$(_rand_choice "steering" "hooks" "agents" "skills")"
  rm -f "${archetype_dir}/${target_category}/README.md"

  echo "${archetype_dir}"
}

# --- Gerador: cria archetype com VERSION ou CHANGELOG.md (proibidos) ---
gen_flutter_archetype_with_version_or_changelog() {
  local archetype_dir
  archetype_dir="$(gen_valid_flutter_archetype)"

  local strategy
  strategy=$(_rand_int 0 2)

  case ${strategy} in
    0)
      # Adicionar VERSION na raiz
      printf '0.1.0' > "${archetype_dir}/VERSION"
      ;;
    1)
      # Adicionar CHANGELOG.md na raiz
      echo "# Changelog" > "${archetype_dir}/CHANGELOG.md"
      ;;
    2)
      # Adicionar ambos VERSION e CHANGELOG.md
      printf '0.1.0' > "${archetype_dir}/VERSION"
      echo "# Changelog" > "${archetype_dir}/CHANGELOG.md"
      ;;
  esac

  echo "${archetype_dir}"
}

# =============================================================================
# Property Test: archetype válido DEVE ser aceito (20 iterações)
# =============================================================================
@test "Property 1a: archetype mobile-flutter com estrutura completa é aceito pela validação (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_valid_flutter_archetype)"

    if ! validate_flutter_archetype_structure "${archetype_dir}"; then
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
@test "Property 1b: archetype mobile-flutter sem artefatos funcionais suficientes é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_invalid_flutter_archetype)"

    if validate_flutter_archetype_structure "${archetype_dir}"; then
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
@test "Property 1c: archetype mobile-flutter com diretório de categoria ausente é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_flutter_archetype_missing_dir)"

    if validate_flutter_archetype_structure "${archetype_dir}"; then
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
@test "Property 1d: archetype mobile-flutter com README.md ausente em categoria é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_flutter_archetype_missing_readme)"

    if validate_flutter_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype sem README.md aceito"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 archetypes sem README.md"
}

# =============================================================================
# Property Test: archetype com VERSION ou CHANGELOG.md DEVE ser rejeitado
# =============================================================================
@test "Property 1e: archetype mobile-flutter com VERSION ou CHANGELOG.md é rejeitado (20 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 20; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_flutter_archetype_with_version_or_changelog)"

    if validate_flutter_archetype_structure "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: archetype com VERSION/CHANGELOG.md aceito"
      echo "Estrutura:"
      find "${archetype_dir}" -type f | sort
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/20 archetypes com VERSION ou CHANGELOG.md"
}
