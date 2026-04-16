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
#   --project-type <tipo>   Tipo de projeto: backend-nest | frontend-react
#   --target <caminho>      Caminho para o diretório do projeto destino
#   --powers <lista>        Lista de powers adicionais separados por vírgula (opcional)
#   --dry-run               Simula a execução sem aplicar mudanças
#   --force                 Sobrescreve arquivos existentes sem perguntar
#   --help                  Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/bootstrap.sh --project-type backend-nest --target ../meu-projeto
#   ./scripts/bootstrap.sh --project-type frontend-react --target ../frontend --dry-run
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
NC='\033[0m'

# Contadores
FILES_COPIED=0
FILES_SKIPPED=0

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

# Copia arquivos de um diretório fonte para destino.
# Pula READMEs do archetype. Respeita --dry-run e --force.
copy_files() {
  local src_dir="$1"
  local dest_dir="$2"
  local file_pattern="${3:-*}"

  if [[ ! -d "${src_dir}" ]]; then
    log_warn "Diretório fonte não encontrado: ${src_dir}"
    return
  fi

  # Contar arquivos disponíveis (excluindo README.md)
  local file_count
  file_count=$(find "${src_dir}" -maxdepth 1 -name "${file_pattern}" -not -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [[ "${file_count}" -eq 0 ]]; then
    log_warn "Nenhum arquivo encontrado em: ${src_dir}"
    return
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Copiaria ${file_count} arquivo(s) de ${src_dir} para ${dest_dir}"
    return
  fi

  mkdir -p "${dest_dir}"

  for file in "${src_dir}"/${file_pattern}; do
    [[ ! -f "${file}" ]] && continue
    local filename
    filename=$(basename "${file}")

    # Pular READMEs do archetype
    [[ "${filename}" == "README.md" ]] && continue

    local dest_file="${dest_dir}/${filename}"

    if [[ -f "${dest_file}" && "${FORCE}" == false ]]; then
      log_warn "Arquivo já existe (pulando): ${dest_file}"
      ((FILES_SKIPPED++)) || true
    else
      cp "${file}" "${dest_file}"
      log_success "  ${filename}"
      ((FILES_COPIED++)) || true
    fi
  done
}

# -----------------------------------------------------------------------------
# Validação de pré-requisitos
# -----------------------------------------------------------------------------

validate_prerequisites() {
  log_info "Validando pré-requisitos..."

  if ! command -v git &>/dev/null; then
    log_error "Git não encontrado. Git é obrigatório para o bootstrap."
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    log_warn "jq não encontrado. O manifest será gerado sem validação JSON."
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
FORCE=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-type) PROJECT_TYPE="$2"; shift 2 ;;
      --target)       TARGET_DIR="$2"; shift 2 ;;
      --powers)       EXTRA_POWERS="$2"; shift 2 ;;
      --dry-run)      DRY_RUN=true; shift ;;
      --force)        FORCE=true; shift ;;
      --help|-h)      print_help ;;
      *)
        log_error "Argumento desconhecido: $1"
        log_error "Use --help para ver os argumentos disponíveis."
        exit 1
        ;;
    esac
  done

  if [[ -z "${PROJECT_TYPE}" ]]; then
    log_error "Argumento obrigatório ausente: --project-type"
    log_error "Tipos disponíveis: backend-nest, frontend-react"
    exit 1
  fi

  if [[ -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    exit 1
  fi

  # Resolver path absoluto
  TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)" || {
    log_error "Diretório destino não encontrado: ${TARGET_DIR}"
    exit 1
  }

  local valid_types=("backend-nest" "frontend-react")
  local valid=false
  for t in "${valid_types[@]}"; do
    [[ "${PROJECT_TYPE}" == "${t}" ]] && valid=true && break
  done

  if [[ "${valid}" == false ]]; then
    log_error "Tipo de projeto inválido: ${PROJECT_TYPE}"
    log_error "Tipos disponíveis: ${valid_types[*]}"
    exit 1
  fi

  if [[ ! -d "${REPO_ROOT}/archetypes/${PROJECT_TYPE}" ]]; then
    log_error "Archetype não encontrado: ${PROJECT_TYPE}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Verificação de bootstrap existente
# -----------------------------------------------------------------------------

check_existing_bootstrap() {
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ -f "${manifest_path}" && "${FORCE}" == false ]]; then
    log_warn "Este projeto já possui um kiro-manifest.json."
    log_warn "Use --force para sobrescrever ou execute sync.sh para atualizar."
    echo ""
    read -r -p "Deseja continuar mesmo assim? [s/N] " response
    case "${response}" in
      [sS]) log_info "Continuando..." ;;
      *)    log_info "Bootstrap cancelado."; exit 0 ;;
    esac
  fi
}

# -----------------------------------------------------------------------------
# Funções de bootstrap
# -----------------------------------------------------------------------------

apply_baseline_global() {
  log_info "Aplicando baseline global (v${BASELINE_VERSION})..."

  local src="${REPO_ROOT}/baselines/global/steering"
  local dest="${TARGET_DIR}/.kiro/steering"

  copy_files "${src}" "${dest}" "*.md"

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Baseline global aplicado."
  fi
}

apply_archetype() {
  local archetype_dir="${REPO_ROOT}/archetypes/${PROJECT_TYPE}"

  log_info "Aplicando archetype: ${PROJECT_TYPE}..."

  # Steering files
  if [[ -d "${archetype_dir}/steering" ]]; then
    log_info "  Copiando steering files..."
    copy_files "${archetype_dir}/steering" "${TARGET_DIR}/.kiro/steering" "*.md"
  fi

  # Skills
  if [[ -d "${archetype_dir}/skills" ]]; then
    log_info "  Copiando skills..."
    copy_files "${archetype_dir}/skills" "${TARGET_DIR}/.kiro/skills" "*.md"
  fi

  # Hooks
  if [[ -d "${archetype_dir}/hooks" ]]; then
    log_info "  Copiando hooks..."
    copy_files "${archetype_dir}/hooks" "${TARGET_DIR}/.kiro/hooks" "*.json"
  fi

  # Agents
  if [[ -d "${archetype_dir}/agents" ]]; then
    log_info "  Copiando agents..."
    copy_files "${archetype_dir}/agents" "${TARGET_DIR}/.kiro/agents" "*.md"
  fi

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Archetype ${PROJECT_TYPE} aplicado."
  fi
}

install_powers() {
  local power_name="mb-${PROJECT_TYPE}"
  local default_powers=("mb-kiro-manager" "${power_name}")

  # Adicionar powers extras se informados
  if [[ -n "${EXTRA_POWERS}" ]]; then
    IFS=',' read -ra extra_array <<< "${EXTRA_POWERS}"
    for p in "${extra_array[@]}"; do
      default_powers+=("$(echo "${p}" | tr -d ' ')")
    done
  fi

  log_info "Instalando powers..."

  local powers_json="["
  local first=true

  for power in "${default_powers[@]}"; do
    local power_dir="${REPO_ROOT}/powers/${power}"

    if [[ ! -d "${power_dir}" ]]; then
      log_warn "Power não encontrado: ${power} (pulando)"
      continue
    fi

    if [[ "${DRY_RUN}" == true ]]; then
      log_warn "[DRY-RUN] Instalaria power: ${power}"
      continue
    fi

    # Copiar steering files do power
    if [[ -d "${power_dir}/steering" ]]; then
      local power_steering_dest="${TARGET_DIR}/.kiro/steering/powers/${power}"
      copy_files "${power_dir}/steering" "${power_steering_dest}" "*.md"
    fi

    # Copiar mcp.json do power para settings
    if [[ -f "${power_dir}/mcp.json" ]]; then
      mkdir -p "${TARGET_DIR}/.kiro/settings"
      # Merge seria ideal, mas por ora copia como referência
      cp "${power_dir}/mcp.json" "${TARGET_DIR}/.kiro/settings/${power}-mcp.json"
      log_success "  ${power} (mcp.json)"
    fi

    log_success "  Power instalado: ${power}"

    # Construir JSON array para o manifest
    if [[ "${first}" == true ]]; then
      first=false
    else
      powers_json+=","
    fi
    powers_json+="\n    { \"name\": \"${power}\", \"version\": \"0.1.0\", \"installed_at\": \"${TIMESTAMP}\" }"
  done

  powers_json+="\n  ]"
  POWERS_JSON="${powers_json}"

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Powers instalados."
  fi
}

generate_manifest() {
  log_info "Gerando kiro-manifest.json..."

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Geraria manifest em: ${manifest_path}"
    return
  fi

  local project_name
  project_name=$(basename "${TARGET_DIR}")

  cat > "${manifest_path}" <<EOF
{
  "_generated_by": "mb-kiro bootstrap.sh",
  "_generated_at": "${TIMESTAMP}",
  "schema_version": "0.1.0",
  "project": {
    "name": "${project_name}",
    "repository": "MonteBravo/${project_name}"
  },
  "baseline": {
    "version": "${BASELINE_VERSION}",
    "source": "MonteBravo/mb-kiro",
    "installed_at": "${TIMESTAMP}",
    "last_synced_at": "${TIMESTAMP}"
  },
  "archetype": {
    "name": "${PROJECT_TYPE}",
    "version": "0.1.0",
    "installed_at": "${TIMESTAMP}"
  },
  "powers": $(echo -e "${POWERS_JSON}"),
  "exceptions": []
}
EOF

  # Validar JSON se jq estiver disponível
  if command -v jq &>/dev/null; then
    if jq '.' "${manifest_path}" > /dev/null 2>&1; then
      log_success "kiro-manifest.json gerado e validado."
    else
      log_warn "kiro-manifest.json gerado mas com possível erro de formatação."
    fi
  else
    log_success "kiro-manifest.json gerado."
  fi
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
  check_existing_bootstrap

  log_info "Projeto tipo:  ${PROJECT_TYPE}"
  log_info "Destino:       ${TARGET_DIR}"
  log_info "Powers extras: ${EXTRA_POWERS:-nenhum}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  [[ "${FORCE}" == true ]] && log_warn "Modo --force ativado — arquivos existentes serão sobrescritos."
  echo ""

  POWERS_JSON="[]"

  apply_baseline_global
  echo ""
  apply_archetype
  echo ""
  install_powers
  echo ""
  generate_manifest

  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "Bootstrap simulado (dry-run) concluído."
  else
    log_success "Bootstrap concluído!"
    echo ""
    log_info "  Arquivos copiados: ${FILES_COPIED}"
    [[ ${FILES_SKIPPED} -gt 0 ]] && log_warn "  Arquivos pulados:  ${FILES_SKIPPED} (já existiam, use --force para sobrescrever)"
    echo ""
    log_info "Próximos passos:"
    log_info "  1. Abra o projeto no Kiro para validar"
    log_info "  2. Execute: ./scripts/doctor.sh --target ${TARGET_DIR}"
  fi
  echo "============================================"
  echo ""
}

main "$@"
