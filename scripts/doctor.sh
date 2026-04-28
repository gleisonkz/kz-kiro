#!/usr/bin/env bash
# =============================================================================
# doctor.sh — Diagnóstico do Ambiente Kiro (MonteBravo)
# =============================================================================
# Verifica o estado do Kiro em um projeto e reporta inconsistências,
# componentes ausentes ou desatualizados.
#
# Uso:
#   ./scripts/doctor.sh [opções]
#
# Opções:
#   --target <caminho>      Caminho para o diretório do projeto a diagnosticar
#   --output <formato>      Formato do relatório: text (padrão) | json
#   --help                  Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/doctor.sh --target ../meu-projeto
#   ./scripts/doctor.sh --target ../meu-projeto --output json
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configurações globais
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Contadores de diagnóstico
CHECKS_PASSED=0
CHECKS_WARNED=0
CHECKS_FAILED=0

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# JSON output
JSON_RESULTS="[]"
OUTPUT_FORMAT="text"

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

log_info()    { [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${BLUE}[INFO]${NC}  $*"; return 0; }
log_pass()    { ((CHECKS_PASSED++)) || true; [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${GREEN}[PASS]${NC}  $*"; return 0; }
log_warn()    { ((CHECKS_WARNED++)) || true; [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${YELLOW}[WARN]${NC}  $*"; return 0; }
log_fail()    { ((CHECKS_FAILED++)) || true; [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${RED}[FAIL]${NC}  $*"; return 0; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

print_help() {
  grep '^#' "${BASH_SOURCE[0]}" | grep -v '#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

add_json_result() {
  local status="$1"
  local category="$2"
  local message="$3"
  if command -v jq &>/dev/null; then
    JSON_RESULTS=$(echo "${JSON_RESULTS}" | jq --arg s "${status}" --arg c "${category}" --arg m "${message}" \
      '. + [{"status": $s, "category": $c, "message": $m}]')
  fi
}

# -----------------------------------------------------------------------------
# Validação de argumentos
# -----------------------------------------------------------------------------

TARGET_DIR=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)  TARGET_DIR="$2"; shift 2 ;;
      --output)  OUTPUT_FORMAT="$2"; shift 2 ;;
      --help|-h) print_help ;;
      *)
        log_error "Argumento desconhecido: $1"
        exit 1
        ;;
    esac
  done

  if [[ -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    exit 1
  fi

  TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)" || {
    log_error "Diretório destino não encontrado: ${TARGET_DIR}"
    exit 1
  }
}

# -----------------------------------------------------------------------------
# Verificações de diagnóstico
# -----------------------------------------------------------------------------

check_manifest() {
  echo ""
  log_info "=== Manifest Kiro ==="

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ -f "${manifest_path}" ]]; then
    log_pass "kiro-manifest.json encontrado."
    add_json_result "pass" "manifest" "kiro-manifest.json encontrado"

    if command -v jq &>/dev/null; then
      if jq '.' "${manifest_path}" > /dev/null 2>&1; then
        log_pass "JSON válido."
        add_json_result "pass" "manifest" "JSON válido"

        # Verificar campos obrigatórios
        local has_baseline has_archetype has_powers
        has_baseline=$(jq -r '.baseline.version // empty' "${manifest_path}" 2>/dev/null)
        has_archetype=$(jq -r '.archetype.name // empty' "${manifest_path}" 2>/dev/null)
        has_powers=$(jq -r '.powers | length' "${manifest_path}" 2>/dev/null)

        if [[ -n "${has_baseline}" ]]; then
          log_pass "Baseline declarado: v${has_baseline}"
          add_json_result "pass" "manifest" "Baseline declarado: v${has_baseline}"
        else
          log_fail "Campo baseline.version ausente no manifest."
          add_json_result "fail" "manifest" "Campo baseline.version ausente"
        fi

        if [[ -n "${has_archetype}" ]]; then
          log_pass "Archetype declarado: ${has_archetype}"
          add_json_result "pass" "manifest" "Archetype declarado: ${has_archetype}"
        else
          log_fail "Campo archetype.name ausente no manifest."
          add_json_result "fail" "manifest" "Campo archetype.name ausente"
        fi

        log_pass "Powers declarados: ${has_powers:-0}"
        add_json_result "pass" "manifest" "Powers declarados: ${has_powers:-0}"
      else
        log_fail "kiro-manifest.json contém JSON inválido."
        add_json_result "fail" "manifest" "JSON inválido"
      fi
    else
      log_warn "jq não disponível — validação estrutural limitada."
      add_json_result "warn" "manifest" "jq não disponível"
    fi
  else
    log_fail "kiro-manifest.json não encontrado. Execute bootstrap.sh primeiro."
    add_json_result "fail" "manifest" "kiro-manifest.json não encontrado"
  fi
}

check_baseline() {
  echo ""
  log_info "=== Baseline Global ==="

  local kiro_steering_dir="${TARGET_DIR}/.kiro/steering"

  if [[ -d "${kiro_steering_dir}" ]]; then
    log_pass "Diretório .kiro/steering/ encontrado."
    add_json_result "pass" "baseline" "Diretório .kiro/steering/ encontrado"

    local baseline_dir="${REPO_ROOT}/baselines/global/steering"
    local required_files=()

    # Descobrir arquivos do baseline dinamicamente
    if [[ -d "${baseline_dir}" ]]; then
      while IFS= read -r -d '' f; do
        local fname
        fname=$(basename "${f}")
        [[ "${fname}" == "README.md" ]] && continue
        required_files+=("${fname}")
      done < <(find "${baseline_dir}" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
    fi

    for f in "${required_files[@]}"; do
      if [[ -f "${kiro_steering_dir}/${f}" ]]; then
        # Verificar se está atualizado
        if [[ -f "${baseline_dir}/${f}" ]]; then
          if diff -q "${baseline_dir}/${f}" "${kiro_steering_dir}/${f}" > /dev/null 2>&1; then
            log_pass "Atualizado: ${f}"
            add_json_result "pass" "baseline" "Atualizado: ${f}"
          else
            log_warn "Desatualizado: ${f} (difere da versão no mb-kiro)"
            add_json_result "warn" "baseline" "Desatualizado: ${f}"
          fi
        else
          log_pass "Presente: ${f}"
          add_json_result "pass" "baseline" "Presente: ${f}"
        fi
      else
        log_fail "Ausente: ${f}"
        add_json_result "fail" "baseline" "Ausente: ${f}"
      fi
    done
  else
    log_fail "Diretório .kiro/steering/ não encontrado. Baseline não aplicado."
    add_json_result "fail" "baseline" "Diretório .kiro/steering/ não encontrado"
  fi
}

check_archetype() {
  echo ""
  log_info "=== Archetype ==="

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"
  local archetype_name=""

  if command -v jq &>/dev/null && [[ -f "${manifest_path}" ]]; then
    archetype_name=$(jq -r '.archetype.name // empty' "${manifest_path}" 2>/dev/null)
  fi

  if [[ -z "${archetype_name}" ]]; then
    log_warn "Não foi possível determinar o archetype (jq ausente ou manifest incompleto)."
    add_json_result "warn" "archetype" "Archetype não determinado"
    return
  fi

  local archetype_dir="${REPO_ROOT}/archetypes/${archetype_name}"

  if [[ ! -d "${archetype_dir}" ]]; then
    log_fail "Archetype '${archetype_name}' não encontrado no repositório mb-kiro."
    add_json_result "fail" "archetype" "Archetype ${archetype_name} não encontrado"
    return
  fi

  log_pass "Archetype: ${archetype_name}"
  add_json_result "pass" "archetype" "Archetype: ${archetype_name}"

  # Verificar steering files do archetype
  local check_dirs=("steering:*.md" "skills:*.md" "hooks:*.json" "agents:*.md")

  for entry in "${check_dirs[@]}"; do
    local dir_name="${entry%%:*}"
    local pattern="${entry##*:}"
    local src_dir="${archetype_dir}/${dir_name}"
    local dest_dir="${TARGET_DIR}/.kiro/${dir_name}"

    if [[ ! -d "${src_dir}" ]]; then
      continue
    fi

    local src_count
    src_count=$(find "${src_dir}" -maxdepth 1 -name "${pattern}" -not -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "${src_count}" -eq 0 ]]; then
      continue
    fi

    if [[ -d "${dest_dir}" ]]; then
      local dest_count
      dest_count=$(find "${dest_dir}" -maxdepth 1 -name "${pattern}" -not -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

      if [[ "${dest_count}" -ge "${src_count}" ]]; then
        log_pass "${dir_name}: ${dest_count}/${src_count} arquivos presentes"
        add_json_result "pass" "archetype" "${dir_name}: ${dest_count}/${src_count}"
      else
        log_warn "${dir_name}: ${dest_count}/${src_count} arquivos (faltam $(( src_count - dest_count )))"
        add_json_result "warn" "archetype" "${dir_name}: ${dest_count}/${src_count} (incompleto)"
      fi
    else
      log_fail "${dir_name}: diretório .kiro/${dir_name}/ não encontrado"
      add_json_result "fail" "archetype" "${dir_name}: diretório ausente"
    fi
  done
}

check_powers() {
  echo ""
  log_info "=== Powers ==="

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if ! command -v jq &>/dev/null; then
    log_warn "jq necessário para verificar powers."
    add_json_result "warn" "powers" "jq não disponível"
    return
  fi

  if [[ ! -f "${manifest_path}" ]]; then
    log_warn "Manifest não encontrado — verificação de powers pulada."
    return
  fi

  local power_count
  power_count=$(jq -r '.powers | length' "${manifest_path}" 2>/dev/null)

  if [[ "${power_count}" -eq 0 || "${power_count}" == "null" ]]; then
    log_info "Nenhum power declarado no manifest."
    return
  fi

  local power_names
  power_names=$(jq -r '.powers[]?.name // empty' "${manifest_path}" 2>/dev/null)

  while IFS= read -r power; do
    [[ -z "${power}" ]] && continue

    if [[ -d "${REPO_ROOT}/powers/${power}" ]]; then
      log_pass "Power disponível: ${power}"
      add_json_result "pass" "powers" "Power disponível: ${power}"
    else
      log_warn "Power declarado mas não encontrado no mb-kiro: ${power}"
      add_json_result "warn" "powers" "Power não encontrado: ${power}"
    fi
  done <<< "${power_names}"
}

check_general_health() {
  echo ""
  log_info "=== Saúde Geral ==="

  # Git
  if git -C "${TARGET_DIR}" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log_pass "Repositório Git detectado."
    add_json_result "pass" "health" "Repositório Git"
  else
    log_warn "Diretório não é um repositório Git."
    add_json_result "warn" "health" "Não é repositório Git"
  fi

  # README
  if [[ -f "${TARGET_DIR}/README.md" ]]; then
    log_pass "README.md presente."
    add_json_result "pass" "health" "README.md presente"
  else
    log_warn "README.md ausente."
    add_json_result "warn" "health" "README.md ausente"
  fi

  # .kiro directory
  if [[ -d "${TARGET_DIR}/.kiro" ]]; then
    log_pass "Diretório .kiro/ presente."
    add_json_result "pass" "health" ".kiro/ presente"

    # Contar arquivos
    local steering_count skills_count hooks_count agents_count
    steering_count=$(find "${TARGET_DIR}/.kiro/steering" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    skills_count=$(find "${TARGET_DIR}/.kiro/skills" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    hooks_count=$(find "${TARGET_DIR}/.kiro/hooks" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
    agents_count=$(find "${TARGET_DIR}/.kiro/agents" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    log_info "  Steering files: ${steering_count}"
    log_info "  Skills:         ${skills_count}"
    log_info "  Hooks:          ${hooks_count}"
    log_info "  Agents:         ${agents_count}"
  else
    log_fail "Diretório .kiro/ não encontrado. Execute bootstrap.sh."
    add_json_result "fail" "health" ".kiro/ ausente"
  fi

  # MCP config
  local mcp_path="${TARGET_DIR}/.kiro/settings/mcp.json"
  if [[ -f "${mcp_path}" ]]; then
    log_pass "mcp.json presente."
    add_json_result "pass" "health" "mcp.json presente"

    if command -v jq &>/dev/null; then
      local server_count
      server_count=$(jq -r '.mcpServers | keys | length' "${mcp_path}" 2>/dev/null)
      log_info "  MCP servers configurados: ${server_count:-0}"

      # Verificar se está atualizado com o baseline
      local mcp_baseline="${REPO_ROOT}/baselines/global/mcp/mcp.json"
      if [[ -f "${mcp_baseline}" ]]; then
        if diff -q "${mcp_baseline}" "${mcp_path}" > /dev/null 2>&1; then
          log_pass "mcp.json atualizado com baseline."
          add_json_result "pass" "health" "mcp.json atualizado"
        else
          log_warn "mcp.json difere do baseline (pode ter customizações locais)."
          add_json_result "warn" "health" "mcp.json difere do baseline"
        fi
      fi
    fi
  else
    log_warn "mcp.json ausente em .kiro/settings/. MCPs homologados não configurados."
    add_json_result "warn" "health" "mcp.json ausente"
  fi
}

# -----------------------------------------------------------------------------
# Relatório
# -----------------------------------------------------------------------------

print_summary() {
  local total=$((CHECKS_PASSED + CHECKS_WARNED + CHECKS_FAILED))

  echo ""
  echo "============================================"
  echo "  Resumo do Diagnóstico"
  echo "  Executado em: ${TIMESTAMP}"
  echo "  Projeto: ${TARGET_DIR}"
  echo "============================================"
  echo -e "  ${GREEN}Passou:${NC}    ${CHECKS_PASSED}/${total}"
  echo -e "  ${YELLOW}Atenção:${NC}   ${CHECKS_WARNED}/${total}"
  echo -e "  ${RED}Falhou:${NC}    ${CHECKS_FAILED}/${total}"
  echo "============================================"

  if [[ ${CHECKS_FAILED} -gt 0 ]]; then
    echo ""
    log_error "${CHECKS_FAILED} problema(s) crítico(s). Revise os itens [FAIL] acima."
    echo ""
    exit 1
  elif [[ ${CHECKS_WARNED} -gt 0 ]]; then
    echo ""
    log_warn "${CHECKS_WARNED} item(ns) requerem atenção."
    echo ""
    exit 0
  else
    echo ""
    log_pass "Projeto em conformidade com os padrões Kiro!"
    echo ""
    exit 0
  fi
}

print_json_report() {
  if command -v jq &>/dev/null; then
    echo "${JSON_RESULTS}" | jq '{
      timestamp: "'"${TIMESTAMP}"'",
      target: "'"${TARGET_DIR}"'",
      summary: {
        passed: '"${CHECKS_PASSED}"',
        warned: '"${CHECKS_WARNED}"',
        failed: '"${CHECKS_FAILED}"'
      },
      results: .
    }'
  else
    log_error "jq necessário para output JSON."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Fluxo principal
# -----------------------------------------------------------------------------

main() {
  parse_args "$@"

  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then
    echo ""
    echo "============================================"
    echo "  mb-kiro Doctor — MonteBravo"
    echo "============================================"
    log_info "Diagnosticando: ${TARGET_DIR}"
  fi

  check_manifest
  check_baseline
  check_archetype
  check_powers
  check_general_health

  if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
    print_json_report
  else
    print_summary
  fi
}

main "$@"
