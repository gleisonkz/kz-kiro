#!/usr/bin/env bash
# =============================================================================
# validate-agents.sh — Validação CI de Agent_Markdown e Agent_JSON
# =============================================================================
# Verifica a estrutura de todos os Agent_Markdown (*-reviewer.md) e Agent_JSON
# (cli-*.json) nos archetypes, validando frontmatter, seções obrigatórias e
# conformidade com o schema.
#
# Uso:
#   ./scripts/validate-agents.sh
#
# Exit codes:
#   0 — Todos os arquivos válidos
#   1 — Uma ou mais falhas de validação encontradas
#
# Requirements: 1.8
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configurações globais
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Contadores
ERRORS=0
FILES_CHECKED=0

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

log_error() {
  ((ERRORS++)) || true
  echo -e "${RED}[ERRO]${NC}  $*" >&2
}

log_pass() {
  echo -e "${GREEN}[OK]${NC}    $*"
}

log_info() {
  echo -e "${YELLOW}[INFO]${NC}  $*"
}

# -----------------------------------------------------------------------------
# Validação de Agent_Markdown (*-reviewer.md)
# -----------------------------------------------------------------------------

validate_agent_markdown() {
  local file="$1"
  local relative_path="${file#${REPO_ROOT}/}"
  local has_error=false

  ((FILES_CHECKED++)) || true

  # --- Verificar presença de frontmatter YAML ---
  local first_line
  first_line=$(head -1 "$file")

  if [[ "$first_line" != "---" ]]; then
    log_error "${relative_path}: Frontmatter YAML ausente (arquivo deve iniciar com '---')"
    return
  fi

  # Extrair frontmatter (conteúdo entre primeiro e segundo '---')
  local frontmatter
  frontmatter=$(sed -n '2,/^---$/p' "$file" | sed '$d')

  if [[ -z "$frontmatter" ]]; then
    log_error "${relative_path}: Frontmatter YAML vazio ou mal-formado"
    return
  fi

  # --- Verificar campo 'name' no frontmatter ---
  if ! echo "$frontmatter" | grep -qE '^name:'; then
    log_error "${relative_path}: Campo 'name' ausente no frontmatter"
    has_error=true
  else
    local name_value
    name_value=$(echo "$frontmatter" | grep -E '^name:' | sed 's/^name:[[:space:]]*//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
    if [[ -z "$name_value" ]]; then
      log_error "${relative_path}: Campo 'name' está vazio no frontmatter"
      has_error=true
    fi
  fi

  # --- Verificar campo 'description' no frontmatter ---
  if ! echo "$frontmatter" | grep -qE '^description:'; then
    log_error "${relative_path}: Campo 'description' ausente no frontmatter"
    has_error=true
  else
    local desc_value
    desc_value=$(echo "$frontmatter" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
    if [[ -z "$desc_value" ]]; then
      log_error "${relative_path}: Campo 'description' está vazio no frontmatter"
      has_error=true
    fi
  fi

  # --- Verificar seções obrigatórias no corpo ---
  local body
  body=$(sed -n '/^---$/,/^---$/!p' "$file" | tail -n +2)
  # Alternativa mais robusta: pegar tudo após o segundo '---'
  body=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$file")

  local required_sections=("## Papel" "## Contexto" "## O que revisar" "## Formato de resposta")

  for section in "${required_sections[@]}"; do
    if ! grep -qF "$section" "$file"; then
      log_error "${relative_path}: Seção obrigatória ausente: '${section}'"
      has_error=true
    fi
  done

  # --- Resultado ---
  if [[ "$has_error" == false ]]; then
    log_pass "${relative_path}"
  fi
}

# -----------------------------------------------------------------------------
# Validação de Agent_JSON (cli-*.json)
# -----------------------------------------------------------------------------

validate_agent_json() {
  local file="$1"
  local relative_path="${file#${REPO_ROOT}/}"
  local has_error=false

  ((FILES_CHECKED++)) || true

  # --- Verificar se é JSON válido ---
  if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    # Fallback sem python3: tentar validação básica
    if command -v jq &>/dev/null; then
      if ! jq '.' "$file" > /dev/null 2>&1; then
        log_error "${relative_path}: JSON inválido (parse error)"
        return
      fi
    else
      # Validação mínima sem jq nem python3
      if ! grep -q '"name"' "$file"; then
        log_error "${relative_path}: Não parece ser JSON válido e nenhum parser disponível (jq/python3)"
        return
      fi
    fi
  fi

  # --- Extrair campos usando grep/sed (sem dependência de jq) ---
  local name_value description_value instructions_value

  # Extrair 'name' (primeira ocorrência de "name": "...")
  name_value=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$file" | head -1 | sed 's/.*:[[:space:]]*"//' | sed 's/"$//')

  # Extrair 'description' (primeira ocorrência de "description": "...")
  description_value=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$file" | head -1 | sed 's/.*:[[:space:]]*"//' | sed 's/"$//')

  # Para instructions, precisamos verificar existência e comprimento
  # Como o campo pode ser muito longo e conter newlines, usamos python3 ou jq
  local instructions_length=0

  if command -v python3 &>/dev/null; then
    instructions_length=$(python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
print(len(data.get('instructions', '')))
" 2>/dev/null || echo "0")
  elif command -v jq &>/dev/null; then
    instructions_length=$(jq -r '.instructions // "" | length' "$file" 2>/dev/null || echo "0")
  else
    # Fallback: verificar se o campo existe pelo menos
    if grep -q '"instructions"' "$file"; then
      # Estimar comprimento pela presença do campo (assume válido se existe)
      instructions_length=100
    fi
  fi

  # --- Validar campo 'name' ---
  if [[ -z "$name_value" ]]; then
    log_error "${relative_path}: Campo 'name' ausente ou vazio"
    has_error=true
  elif [[ ! "$name_value" =~ ^cli- ]]; then
    log_error "${relative_path}: Campo 'name' deve iniciar com prefixo 'cli-' (valor: '${name_value}')"
    has_error=true
  fi

  # --- Validar campo 'description' ---
  if [[ -z "$description_value" ]]; then
    log_error "${relative_path}: Campo 'description' ausente ou vazio"
    has_error=true
  else
    local desc_length=${#description_value}
    if [[ $desc_length -lt 10 ]]; then
      log_error "${relative_path}: Campo 'description' muito curto (${desc_length} chars, mínimo: 10)"
      has_error=true
    elif [[ $desc_length -gt 200 ]]; then
      log_error "${relative_path}: Campo 'description' muito longo (${desc_length} chars, máximo: 200)"
      has_error=true
    fi
  fi

  # --- Validar campo 'instructions' ---
  if [[ "$instructions_length" -eq 0 ]]; then
    log_error "${relative_path}: Campo 'instructions' ausente ou vazio"
    has_error=true
  elif [[ "$instructions_length" -lt 100 ]]; then
    log_error "${relative_path}: Campo 'instructions' muito curto (${instructions_length} chars, mínimo: 100)"
    has_error=true
  fi

  # --- Resultado ---
  if [[ "$has_error" == false ]]; then
    log_pass "${relative_path}"
  fi
}

# -----------------------------------------------------------------------------
# Execução principal
# -----------------------------------------------------------------------------

main() {
  echo "=============================================="
  echo " Validação de Agentes — Archetypes MonteBravo"
  echo "=============================================="
  echo ""

  # --- Validar Agent_Markdown ---
  echo "--- Agent Markdown (*-reviewer.md) ---"
  echo ""

  local md_files=()
  while IFS= read -r -d '' f; do
    md_files+=("$f")
  done < <(find "${REPO_ROOT}/archetypes" -path "*/agents/*-reviewer.md" -type f -print0 2>/dev/null | sort -z)

  if [[ ${#md_files[@]} -eq 0 ]]; then
    log_info "Nenhum arquivo *-reviewer.md encontrado em archetypes/*/agents/"
  else
    for md_file in "${md_files[@]}"; do
      validate_agent_markdown "$md_file"
    done
  fi

  echo ""
  echo "--- Agent JSON (cli-*.json) ---"
  echo ""

  # --- Validar Agent_JSON ---
  local json_files=()
  while IFS= read -r -d '' f; do
    json_files+=("$f")
  done < <(find "${REPO_ROOT}/archetypes" -path "*/agents/cli-*.json" -type f -print0 2>/dev/null | sort -z)

  if [[ ${#json_files[@]} -eq 0 ]]; then
    log_info "Nenhum arquivo cli-*.json encontrado em archetypes/*/agents/"
  else
    for json_file in "${json_files[@]}"; do
      validate_agent_json "$json_file"
    done
  fi

  # --- Resumo ---
  echo ""
  echo "=============================================="
  echo " Resumo"
  echo "=============================================="
  echo ""
  echo "  Arquivos verificados: ${FILES_CHECKED}"

  if [[ $ERRORS -eq 0 ]]; then
    echo -e "  Resultado: ${GREEN}✓ Todos os agentes válidos${NC}"
    echo ""
    exit 0
  else
    echo -e "  Resultado: ${RED}✗ ${ERRORS} erro(s) encontrado(s)${NC}"
    echo ""
    exit 1
  fi
}

main "$@"
