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
#   --component <nome>      Sincronizar apenas: baseline | archetype | powers | all (padrão: all)
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

# Contadores
FILES_UPDATED=0
FILES_ADDED=0
FILES_UNCHANGED=0

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

# Sincroniza arquivos: copia novos e atualiza os que mudaram.
sync_files() {
  local src_dir="$1"
  local dest_dir="$2"
  local file_pattern="${3:-*}"

  if [[ ! -d "${src_dir}" ]]; then
    return
  fi

  local file_count
  file_count=$(find "${src_dir}" -maxdepth 1 -name "${file_pattern}" -not -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [[ "${file_count}" -eq 0 ]]; then
    return
  fi

  mkdir -p "${dest_dir}"

  for file in "${src_dir}"/${file_pattern}; do
    [[ ! -f "${file}" ]] && continue
    local filename
    filename=$(basename "${file}")
    [[ "${filename}" == "README.md" ]] && continue

    local dest_file="${dest_dir}/${filename}"

    if [[ "${DRY_RUN}" == true ]]; then
      if [[ ! -f "${dest_file}" ]]; then
        log_warn "[DRY-RUN] Adicionaria: ${filename}"
      elif ! diff -q "${file}" "${dest_file}" > /dev/null 2>&1; then
        log_warn "[DRY-RUN] Atualizaria: ${filename}"
      fi
      continue
    fi

    if [[ ! -f "${dest_file}" ]]; then
      cp "${file}" "${dest_file}"
      log_success "  + ${filename} (novo)"
      ((FILES_ADDED++)) || true
    elif ! diff -q "${file}" "${dest_file}" > /dev/null 2>&1; then
      cp "${file}" "${dest_file}"
      log_success "  ~ ${filename} (atualizado)"
      ((FILES_UPDATED++)) || true
    else
      ((FILES_UNCHANGED++)) || true
    fi
  done
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

  TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)" || {
    log_error "Diretório destino não encontrado: ${TARGET_DIR}"
    exit 1
  }

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

MANIFEST_ARCHETYPE=""

read_manifest() {
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ ! -f "${manifest_path}" ]]; then
    log_error "kiro-manifest.json não encontrado em: ${TARGET_DIR}"
    log_error "Execute o bootstrap primeiro: ./scripts/bootstrap.sh --target ${TARGET_DIR} --project-type <tipo>"
    exit 1
  fi

  log_info "Manifest encontrado: ${manifest_path}"

  if command -v jq &>/dev/null; then
    MANIFEST_ARCHETYPE=$(jq -r '.archetype.name // empty' "${manifest_path}" 2>/dev/null)
    local manifest_baseline
    manifest_baseline=$(jq -r '.baseline.version // empty' "${manifest_path}" 2>/dev/null)

    log_info "  Archetype: ${MANIFEST_ARCHETYPE:-desconhecido}"
    log_info "  Baseline:  ${manifest_baseline:-desconhecido}"
  else
    # Fallback sem jq: tentar extrair com grep
    MANIFEST_ARCHETYPE=$(grep -o '"name": *"[^"]*"' "${manifest_path}" | head -1 | sed 's/.*: *"\(.*\)"/\1/')
    log_warn "jq não disponível — leitura do manifest limitada."
    log_info "  Archetype (estimado): ${MANIFEST_ARCHETYPE:-desconhecido}"
  fi

  if [[ -z "${MANIFEST_ARCHETYPE}" ]]; then
    log_error "Não foi possível determinar o archetype do projeto."
    log_error "Verifique o kiro-manifest.json."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Funções de sincronização
# -----------------------------------------------------------------------------

sync_baseline() {
  log_info "Sincronizando baseline global..."

  local src="${REPO_ROOT}/baselines/global/steering"
  local dest="${TARGET_DIR}/.kiro/steering"

  sync_files "${src}" "${dest}" "*.md"

  # Sincronizar mcp.json (baseline + archetype mergeados)
  local mcp_baseline="${REPO_ROOT}/baselines/global/mcp/mcp.json"
  local mcp_archetype="${REPO_ROOT}/archetypes/${MANIFEST_ARCHETYPE}/mcp/mcp.json"
  local mcp_dest="${TARGET_DIR}/.kiro/settings/mcp.json"

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Verificaria mcp.json (baseline + archetype)"
  else
    mkdir -p "${TARGET_DIR}/.kiro/settings"

    # Gerar mcp.json mergeado em temp para comparar
    local mcp_merged
    mcp_merged=$(mktemp)

    if command -v jq &>/dev/null && [[ -f "${mcp_baseline}" && -f "${mcp_archetype}" ]]; then
      jq -s '
        {
          "_comment": "MCPs homologados MonteBravo (baseline global + archetype '"${MANIFEST_ARCHETYPE}"'). Gerado por sync.sh.",
          "_version": "0.1.0",
          "mcpServers": (.[0].mcpServers * .[1].mcpServers)
        }
      ' "${mcp_baseline}" "${mcp_archetype}" > "${mcp_merged}"
    elif [[ -f "${mcp_baseline}" ]]; then
      cp "${mcp_baseline}" "${mcp_merged}"
    fi

    if [[ -f "${mcp_merged}" && -s "${mcp_merged}" ]]; then
      if [[ ! -f "${mcp_dest}" ]]; then
        cp "${mcp_merged}" "${mcp_dest}"
        log_success "  + mcp.json (novo — baseline + archetype)"
        ((FILES_ADDED++)) || true
      elif ! diff -q "${mcp_merged}" "${mcp_dest}" > /dev/null 2>&1; then
        cp "${mcp_merged}" "${mcp_dest}"
        log_success "  ~ mcp.json (atualizado — baseline + archetype)"
        ((FILES_UPDATED++)) || true
      else
        ((FILES_UNCHANGED++)) || true
      fi
    fi

    rm -f "${mcp_merged}"
  fi

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Baseline sincronizado."
  fi
}

sync_archetype() {
  local archetype_dir="${REPO_ROOT}/archetypes/${MANIFEST_ARCHETYPE}"

  if [[ ! -d "${archetype_dir}" ]]; then
    log_error "Archetype não encontrado: ${MANIFEST_ARCHETYPE}"
    return
  fi

  log_info "Sincronizando archetype: ${MANIFEST_ARCHETYPE}..."

  # Steering
  if [[ -d "${archetype_dir}/steering" ]]; then
    log_info "  Steering files..."
    sync_files "${archetype_dir}/steering" "${TARGET_DIR}/.kiro/steering" "*.md"
  fi

  # Skills
  if [[ -d "${archetype_dir}/skills" ]]; then
    log_info "  Skills..."
    sync_files "${archetype_dir}/skills" "${TARGET_DIR}/.kiro/skills" "*.md"
  fi

  # Hooks
  if [[ -d "${archetype_dir}/hooks" ]]; then
    log_info "  Hooks..."
    sync_files "${archetype_dir}/hooks" "${TARGET_DIR}/.kiro/hooks" "*.json"
    sync_files "${archetype_dir}/hooks" "${TARGET_DIR}/.kiro/hooks" "*.kiro.hook"
  fi

  # Agents
  if [[ -d "${archetype_dir}/agents" ]]; then
    log_info "  Agents..."
    sync_files "${archetype_dir}/agents" "${TARGET_DIR}/.kiro/agents" "*.md"
  fi

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Archetype sincronizado."
  fi
}

sync_powers() {
  log_info "Sincronizando powers..."

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if ! command -v jq &>/dev/null; then
    log_warn "jq necessário para sincronizar powers. Pulando."
    return
  fi

  local power_names
  power_names=$(jq -r '.powers[]?.name // empty' "${manifest_path}" 2>/dev/null)

  if [[ -z "${power_names}" ]]; then
    log_info "Nenhum power declarado no manifest."
    return
  fi

  while IFS= read -r power; do
    local power_dir="${REPO_ROOT}/powers/${power}"

    if [[ ! -d "${power_dir}" ]]; then
      log_warn "Power não encontrado no repositório: ${power}"
      continue
    fi

    log_info "  Power: ${power}"

    # Sincronizar steering files do power
    if [[ -d "${power_dir}/steering" ]]; then
      sync_files "${power_dir}/steering" "${TARGET_DIR}/.kiro/steering/powers/${power}" "*.md"
    fi

    # Merge mcp.json do power no mcp.json principal do projeto
    if [[ -f "${power_dir}/mcp.json" ]]; then
      local mcp_dest="${TARGET_DIR}/.kiro/settings/mcp.json"
      mkdir -p "${TARGET_DIR}/.kiro/settings"

      if [[ "${DRY_RUN}" == true ]]; then
        log_warn "[DRY-RUN] Mergearia mcp.json do power: ${power}"
      elif [[ -f "${mcp_dest}" ]]; then
        local tmp_mcp
        tmp_mcp=$(mktemp)
        jq -s '.[0] * { mcpServers: (.[0].mcpServers * .[1].mcpServers) }' \
          "${mcp_dest}" "${power_dir}/mcp.json" > "${tmp_mcp}"
        mv "${tmp_mcp}" "${mcp_dest}"
        log_success "    mcp.json mergeado (power: ${power})"
        ((FILES_UPDATED++)) || true
      else
        cp "${power_dir}/mcp.json" "${mcp_dest}"
        log_success "    mcp.json criado (power: ${power})"
        ((FILES_ADDED++)) || true
      fi
    fi
  done <<< "${power_names}"

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Powers sincronizados."
  fi
}

update_manifest_sync_date() {
  if [[ "${DRY_RUN}" == true ]]; then
    return
  fi

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if command -v jq &>/dev/null; then
    local tmp
    tmp=$(mktemp)
    jq --arg ts "${TIMESTAMP}" '.baseline.last_synced_at = $ts' "${manifest_path}" > "${tmp}"
    mv "${tmp}" "${manifest_path}"
    log_success "Manifest atualizado com data de sincronização."
  fi
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
  read_manifest

  log_info "Destino:    ${TARGET_DIR}"
  log_info "Componente: ${COMPONENT}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  echo ""

  case "${COMPONENT}" in
    all)
      sync_baseline
      echo ""
      sync_archetype
      echo ""
      sync_powers
      ;;
    baseline)  sync_baseline ;;
    archetype) sync_archetype ;;
    powers)    sync_powers ;;
  esac

  echo ""
  update_manifest_sync_date

  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "Sincronização simulada (dry-run) concluída."
  else
    log_success "Sincronização concluída!"
    echo ""
    log_info "  Novos:        ${FILES_ADDED}"
    log_info "  Atualizados:  ${FILES_UPDATED}"
    log_info "  Sem mudança:  ${FILES_UNCHANGED}"
    echo ""
    log_info "Execute: ./scripts/doctor.sh --target ${TARGET_DIR}"
  fi
  echo "============================================"
  echo ""
}

main "$@"
