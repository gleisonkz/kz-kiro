#!/usr/bin/env bash
# =============================================================================
# sync.sh — Sincronização de Padrões Kiro (MonteBravo)
# =============================================================================
# Atualiza um projeto existente com a versão mais recente do baseline global,
# archetype e/ou powers declarados no kiro-manifest.json do projeto.
#
# Uso:
#   ./scripts/sync.sh [opções]
#
# Opções:
#   --target <caminho>      Caminho para o diretório do projeto destino
#   --component <nome>      Sincronizar apenas um componente: baseline | archetype | powers | all (padrão: all)
#   --dry-run               Simula a execução sem aplicar mudanças
#   --help                  Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/sync.sh --target ../meu-projeto
#   ./scripts/sync.sh --target ../meu-projeto --component baseline
#   ./scripts/sync.sh --target ../meu-projeto --dry-run
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configurações globais
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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

  if ! command -v git &>/dev/null; then
    log_error "Git não encontrado."
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    log_warn "jq não encontrado. Leitura do manifest será limitada."
  fi

  log_success "Pré-requisitos validados."
}

# -----------------------------------------------------------------------------
# Validação de argumentos
# -----------------------------------------------------------------------------

TARGET_DIR=""
COMPONENT="all"
DRY_RUN=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)     TARGET_DIR="$2"; shift 2 ;;
      --component)  COMPONENT="$2"; shift 2 ;;
      --dry-run)    DRY_RUN=true; shift ;;
      --help|-h)    print_help ;;
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

  local valid_components=("all" "baseline" "archetype" "powers")
  local valid=false
  for c in "${valid_components[@]}"; do
    [[ "${COMPONENT}" == "${c}" ]] && valid=true && break
  done

  if [[ "${valid}" == false ]]; then
    log_error "Componente inválido: ${COMPONENT}"
    log_error "Componentes válidos: ${valid_components[*]}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Leitura do manifest
# -----------------------------------------------------------------------------

read_manifest() {
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ ! -f "${manifest_path}" ]]; then
    log_error "kiro-manifest.json não encontrado em: ${TARGET_DIR}"
    log_error "Execute o bootstrap primeiro: ./scripts/bootstrap.sh --target ${TARGET_DIR} --project-type <tipo>"
    exit 1
  fi

  log_info "Manifest encontrado: ${manifest_path}"

  # TODO: Usar jq para extrair versões e componentes do manifest
  # INSTALLED_BASELINE=$(jq -r '.baseline.version' "${manifest_path}")
  # INSTALLED_ARCHETYPE=$(jq -r '.archetype.name' "${manifest_path}")
  # INSTALLED_ARCHETYPE_VERSION=$(jq -r '.archetype.version' "${manifest_path}")

  log_warn "TODO: Implementar leitura estruturada do manifest via jq."
}

# -----------------------------------------------------------------------------
# Funções de sincronização
# -----------------------------------------------------------------------------

sync_baseline() {
  log_info "Sincronizando baseline global..."

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Verificaria versão instalada vs. disponível do baseline global."
    log_warn "[DRY-RUN] Atualizaria steering files se necessário."
    return
  fi

  # TODO: Implementar lógica de comparação de versões e atualização do baseline
  # 1. Ler versão instalada do manifest
  # 2. Comparar com versão disponível neste repositório
  # 3. Se diferente, copiar novos steering files e atualizar manifest

  log_warn "TODO: Implementar sincronização do baseline global."
  log_success "Baseline sincronizado (placeholder)."
}

sync_archetype() {
  log_info "Sincronizando archetype..."

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Verificaria versão instalada vs. disponível do archetype."
    return
  fi

  # TODO: Implementar lógica de sincronização do archetype
  # Atenção: mudanças no archetype podem sobrescrever customizações locais.
  # Implementar modo de merge com preservação de customizações.

  log_warn "TODO: Implementar sincronização do archetype."
  log_success "Archetype sincronizado (placeholder)."
}

sync_powers() {
  log_info "Sincronizando powers..."

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Verificaria versões instaladas de todos os powers."
    return
  fi

  # TODO: Implementar lógica de sincronização de powers
  # Iterar sobre os powers declarados no manifest e atualizar cada um.

  log_warn "TODO: Implementar sincronização de powers."
  log_success "Powers sincronizados (placeholder)."
}

update_manifest_after_sync() {
  log_info "Atualizando kiro-manifest.json com data de sincronização..."

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Atualizaria o campo last_synced_at no manifest."
    return
  fi

  # TODO: Implementar atualização do manifest com jq
  # jq --arg ts "${TIMESTAMP}" '.last_synced_at = $ts' manifest.json > tmp && mv tmp manifest.json

  log_warn "TODO: Implementar atualização do manifest após sync."
  log_success "Manifest atualizado (placeholder)."
}

# -----------------------------------------------------------------------------
# Fluxo principal
# -----------------------------------------------------------------------------

main() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Sync — MonteBravo"
  echo "============================================"
  echo ""

  parse_args "$@"
  validate_prerequisites
  read_manifest

  log_info "Destino:    ${TARGET_DIR}"
  log_info "Componente: ${COMPONENT}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  echo ""

  case "${COMPONENT}" in
    all)
      sync_baseline
      sync_archetype
      sync_powers
      ;;
    baseline)  sync_baseline ;;
    archetype) sync_archetype ;;
    powers)    sync_powers ;;
  esac

  update_manifest_after_sync

  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "Sincronização simulada (dry-run) concluída."
  else
    log_success "Sincronização concluída com sucesso!"
    log_info "Execute o doctor para validar: ./scripts/doctor.sh --target ${TARGET_DIR}"
  fi
  echo "============================================"
  echo ""
}

main "$@"
