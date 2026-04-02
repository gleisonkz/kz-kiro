#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Bootstrap de Projeto com Padrões Kiro (MonteBravo)
# =============================================================================
# Configura um projeto novo (ou existente sem configuração Kiro) com o
# baseline global, o archetype correto e os powers necessários.
#
# Uso:
#   ./scripts/bootstrap.sh [opções]
#
# Opções:
#   --project-type <tipo>   Tipo de projeto: backend-nest | frontend-react-next
#   --target <caminho>      Caminho para o diretório do projeto destino
#   --powers <lista>        Lista de powers adicionais separados por vírgula (opcional)
#   --dry-run               Simula a execução sem aplicar mudanças
#   --help                  Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/bootstrap.sh --project-type backend-nest --target ../meu-projeto
#   ./scripts/bootstrap.sh --project-type frontend-react-next --target ../frontend --dry-run
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configurações globais
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BASELINE_VERSION="0.1.0"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

print_help() {
  grep '^#' "${BASH_SOURCE[0]}" | grep -v '#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

# -----------------------------------------------------------------------------
# Validação de pré-requisitos
# -----------------------------------------------------------------------------

validate_prerequisites() {
  log_info "Validando pré-requisitos..."

  # TODO: Verificar se o Kiro CLI está instalado e na versão correta
  # if ! command -v kiro &>/dev/null; then
  #   log_error "Kiro CLI não encontrado. Instale via: TODO"
  #   exit 1
  # fi

  # Verificar se git está disponível
  if ! command -v git &>/dev/null; then
    log_error "Git não encontrado. Git é obrigatório para o bootstrap."
    exit 1
  fi

  # Verificar se jq está disponível (para manipulação de JSON)
  if ! command -v jq &>/dev/null; then
    log_warn "jq não encontrado. Algumas funcionalidades podem ser limitadas."
    log_warn "Instale com: sudo apt-get install jq  |  brew install jq"
  fi

  log_success "Pré-requisitos validados."
}

# -----------------------------------------------------------------------------
# Validação de argumentos
# -----------------------------------------------------------------------------

PROJECT_TYPE=""
TARGET_DIR=""
EXTRA_POWERS=""
DRY_RUN=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-type) PROJECT_TYPE="$2"; shift 2 ;;
      --target)       TARGET_DIR="$2"; shift 2 ;;
      --powers)       EXTRA_POWERS="$2"; shift 2 ;;
      --dry-run)      DRY_RUN=true; shift ;;
      --help|-h)      print_help ;;
      *)
        log_error "Argumento desconhecido: $1"
        log_error "Use --help para ver os argumentos disponíveis."
        exit 1
        ;;
    esac
  done

  # Validar argumentos obrigatórios
  if [[ -z "${PROJECT_TYPE}" ]]; then
    log_error "Argumento obrigatório ausente: --project-type"
    log_error "Tipos disponíveis: backend-nest, frontend-react-next"
    exit 1
  fi

  if [[ -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    exit 1
  fi

  # Validar tipo de projeto
  local valid_types=("backend-nest" "frontend-react-next")
  local valid=false
  for t in "${valid_types[@]}"; do
    [[ "${PROJECT_TYPE}" == "${t}" ]] && valid=true && break
  done

  if [[ "${valid}" == false ]]; then
    log_error "Tipo de projeto inválido: ${PROJECT_TYPE}"
    log_error "Tipos disponíveis: ${valid_types[*]}"
    exit 1
  fi

  # Verificar se o diretório destino existe
  if [[ ! -d "${TARGET_DIR}" ]]; then
    log_error "Diretório destino não encontrado: ${TARGET_DIR}"
    exit 1
  fi

  # Verificar se o archetype existe
  if [[ ! -d "${REPO_ROOT}/archetypes/${PROJECT_TYPE}" ]]; then
    log_error "Archetype não encontrado: ${PROJECT_TYPE}"
    log_error "Archetypes disponíveis em: ${REPO_ROOT}/archetypes/"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Funções de bootstrap
# -----------------------------------------------------------------------------

apply_baseline_global() {
  log_info "Aplicando baseline global (v${BASELINE_VERSION})..."

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Copiaria steering files de: ${REPO_ROOT}/baselines/global/steering/"
    log_warn "[DRY-RUN] Para: ${TARGET_DIR}/.kiro/steering/"
    return
  fi

  # TODO: Implementar cópia dos steering files do baseline global para o projeto destino
  # mkdir -p "${TARGET_DIR}/.kiro/steering"
  # cp -r "${REPO_ROOT}/baselines/global/steering/"* "${TARGET_DIR}/.kiro/steering/"

  log_warn "TODO: Implementar cópia do baseline global para o projeto."
  log_success "Baseline global aplicado (placeholder)."
}

apply_archetype() {
  log_info "Aplicando archetype: ${PROJECT_TYPE}..."

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Aplicaria archetype de: ${REPO_ROOT}/archetypes/${PROJECT_TYPE}/"
    log_warn "[DRY-RUN] Para: ${TARGET_DIR}/.kiro/"
    return
  fi

  # TODO: Implementar aplicação do archetype no projeto destino
  # Incluir steering files, hooks, agents e skills do archetype

  log_warn "TODO: Implementar aplicação do archetype ${PROJECT_TYPE}."
  log_success "Archetype aplicado (placeholder)."
}

install_default_powers() {
  log_info "Instalando power padrão: mb-kiro-manager..."

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Instalaria power: mb-kiro-manager"
    if [[ -n "${EXTRA_POWERS}" ]]; then
      log_warn "[DRY-RUN] Powers adicionais: ${EXTRA_POWERS}"
    fi
    return
  fi

  # TODO: Implementar instalação de powers no projeto destino

  log_warn "TODO: Implementar instalação de powers."
  log_success "Powers instalados (placeholder)."
}

generate_manifest() {
  log_info "Gerando kiro-manifest.json..."

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Geraria manifest em: ${manifest_path}"
    return
  fi

  # TODO: Implementar geração real do manifest com jq
  # Por ora, cria um manifest mínimo de referência
  cat > "${manifest_path}" <<EOF
{
  "_generated_by": "mb-kiro bootstrap.sh",
  "_generated_at": "${TIMESTAMP}",
  "schema_version": "0.1.0",
  "baseline": {
    "version": "${BASELINE_VERSION}",
    "source": "MonteBravo/mb-kiro"
  },
  "archetype": {
    "name": "${PROJECT_TYPE}",
    "version": "0.1.0"
  },
  "powers": [
    { "name": "mb-kiro-manager", "version": "0.1.0" }
  ],
  "exceptions": []
}
EOF

  log_success "kiro-manifest.json gerado em: ${manifest_path}"
}

# -----------------------------------------------------------------------------
# Fluxo principal
# -----------------------------------------------------------------------------

main() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Bootstrap — MonteBravo"
  echo "============================================"
  echo ""

  parse_args "$@"
  validate_prerequisites

  log_info "Projeto tipo:  ${PROJECT_TYPE}"
  log_info "Destino:       ${TARGET_DIR}"
  log_info "Powers extras: ${EXTRA_POWERS:-nenhum}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  echo ""

  apply_baseline_global
  apply_archetype
  install_default_powers
  generate_manifest

  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "Bootstrap simulado (dry-run) concluído."
  else
    log_success "Bootstrap concluído com sucesso!"
    log_info "Próximos passos:"
    log_info "  1. Revise o kiro-manifest.json em: ${TARGET_DIR}/kiro-manifest.json"
    log_info "  2. Execute o doctor para validar: ./scripts/doctor.sh --target ${TARGET_DIR}"
    log_info "  3. Leia o onboarding em: docs/onboarding.md"
  fi
  echo "============================================"
  echo ""
}

main "$@"
