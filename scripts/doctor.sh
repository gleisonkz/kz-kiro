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
#   --fix                   Tenta corrigir automaticamente problemas encontrados (experimental)
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

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_pass()    { echo -e "${GREEN}[PASS]${NC}  $*"; ((CHECKS_PASSED++)) || true; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; ((CHECKS_WARNED++)) || true; }
log_fail()    { echo -e "${RED}[FAIL]${NC}  $*"; ((CHECKS_FAILED++)) || true; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

print_help() {
  grep '^#' "${BASH_SOURCE[0]}" | grep -v '#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

# -----------------------------------------------------------------------------
# Validação de argumentos
# -----------------------------------------------------------------------------

TARGET_DIR=""
OUTPUT_FORMAT="text"
AUTO_FIX=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)  TARGET_DIR="$2"; shift 2 ;;
      --output)  OUTPUT_FORMAT="$2"; shift 2 ;;
      --fix)     AUTO_FIX=true; shift ;;
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

  if [[ ! -d "${TARGET_DIR}" ]]; then
    log_error "Diretório destino não encontrado: ${TARGET_DIR}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Verificações de diagnóstico
# -----------------------------------------------------------------------------

check_manifest() {
  echo ""
  log_info "=== Verificando Manifest Kiro ==="

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ -f "${manifest_path}" ]]; then
    log_pass "kiro-manifest.json encontrado."

    # TODO: Validar schema do manifest
    # if command -v jq &>/dev/null; then
    #   if jq '.' "${manifest_path}" &>/dev/null; then
    #     log_pass "kiro-manifest.json é um JSON válido."
    #   else
    #     log_fail "kiro-manifest.json contém JSON inválido."
    #   fi
    # fi

    log_warn "TODO: Implementar validação estrutural do manifest."
  else
    log_fail "kiro-manifest.json não encontrado. Execute bootstrap.sh primeiro."
    if [[ "${AUTO_FIX}" == true ]]; then
      log_info "  [--fix] TODO: Tentar executar bootstrap automaticamente."
    fi
  fi
}

check_baseline() {
  echo ""
  log_info "=== Verificando Baseline Global ==="

  # TODO: Verificar se os steering files do baseline global estão presentes no projeto
  # e se as versões coincidem com o manifest.

  local kiro_steering_dir="${TARGET_DIR}/.kiro/steering"

  if [[ -d "${kiro_steering_dir}" ]]; then
    log_pass "Diretório .kiro/steering/ encontrado."

    # TODO: Verificar steering files específicos do baseline
    local required_files=(
      "engineering-principles.md"
      "security-baseline.md"
      "specs-policy.md"
      "documentation-baseline.md"
    )

    for f in "${required_files[@]}"; do
      if [[ -f "${kiro_steering_dir}/${f}" ]]; then
        log_pass "Steering file presente: ${f}"
      else
        log_warn "Steering file ausente: ${f}"
      fi
    done
  else
    log_fail "Diretório .kiro/steering/ não encontrado. Baseline global não aplicado."
  fi

  log_warn "TODO: Implementar verificação de versão do baseline."
}

check_archetype() {
  echo ""
  log_info "=== Verificando Archetype ==="

  # TODO: Ler o archetype declarado no manifest e verificar se os arquivos correspondentes estão presentes.

  log_warn "TODO: Implementar verificação de archetype."
  log_warn "  - Verificar se o archetype declarado no manifest existe."
  log_warn "  - Verificar se os hooks, agents e skills do archetype estão instalados."
  log_warn "  - Verificar se a versão instalada está atualizada."
}

check_powers() {
  echo ""
  log_info "=== Verificando Powers ==="

  # TODO: Ler os powers declarados no manifest e verificar se estão instalados.

  log_warn "TODO: Implementar verificação de powers."
  log_warn "  - Verificar se cada power declarado está instalado."
  log_warn "  - Verificar se as versões estão atualizadas."
  log_warn "  - Verificar se os mcp.json dos powers são válidos."
}

check_general_health() {
  echo ""
  log_info "=== Verificações Gerais de Saúde ==="

  # Verificar se é um repositório git
  if git -C "${TARGET_DIR}" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    log_pass "Repositório Git detectado."
  else
    log_warn "Diretório não é um repositório Git."
  fi

  # Verificar se o README.md existe
  if [[ -f "${TARGET_DIR}/README.md" ]]; then
    log_pass "README.md presente."
  else
    log_warn "README.md ausente no projeto."
  fi

  # TODO: Verificar se o CHANGELOG.md existe
  # TODO: Verificar se há testes configurados
  # TODO: Verificar se há pipeline de CI configurado
}

# -----------------------------------------------------------------------------
# Geração do relatório
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
    log_error "Foram encontrados ${CHECKS_FAILED} problema(s) crítico(s). Revise os itens [FAIL] acima."
    echo ""
    exit 1
  elif [[ ${CHECKS_WARNED} -gt 0 ]]; then
    echo ""
    log_warn "${CHECKS_WARNED} item(ns) requerem atenção. Revise os itens [WARN] acima."
    echo ""
    exit 0
  else
    echo ""
    log_pass "Projeto em conformidade com os padrões Kiro!"
    echo ""
    exit 0
  fi
}

# TODO: Implementar output em formato JSON para integração com CI/CD
# print_json_report() { ... }

# -----------------------------------------------------------------------------
# Fluxo principal
# -----------------------------------------------------------------------------

main() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Doctor — MonteBravo"
  echo "============================================"

  parse_args "$@"

  log_info "Diagnosticando: ${TARGET_DIR}"
  [[ "${AUTO_FIX}" == true ]] && log_warn "Modo --fix ativado (experimental)."

  check_manifest
  check_baseline
  check_archetype
  check_powers
  check_general_health

  print_summary
}

main "$@"
