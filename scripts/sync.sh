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
#   --migrate-powers        Migra powers legados para instalação nativa (com backup)
#   --dry-run               Simula a execução sem aplicar mudanças
#   --help                  Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/sync.sh --target ../meu-projeto
#   ./scripts/sync.sh --target ../meu-projeto --component baseline
#   ./scripts/sync.sh --target ../meu-projeto --migrate-powers
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
MIGRATE_POWERS=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)          TARGET_DIR="$2"; shift 2 ;;
      --component)       COMPONENT="$2"; shift 2 ;;
      --migrate-powers)  MIGRATE_POWERS=true; shift ;;
      --dry-run)         DRY_RUN=true; shift ;;
      --help|-h)         print_help ;;
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

  local power_count
  power_count=$(jq -r '.powers | length' "${manifest_path}" 2>/dev/null)

  if [[ "${power_count}" -eq 0 || -z "${power_count}" ]]; then
    log_info "Nenhum power declarado no manifest."
    return
  fi

  local i=0
  while [[ ${i} -lt ${power_count} ]]; do
    local power
    local installation_method
    local manifest_version

    power=$(jq -r ".powers[${i}].name" "${manifest_path}" 2>/dev/null)
    installation_method=$(jq -r ".powers[${i}].installation_method // \"legacy\"" "${manifest_path}" 2>/dev/null)
    manifest_version=$(jq -r ".powers[${i}].version // \"0.0.0\"" "${manifest_path}" 2>/dev/null)

    # Pular entries marcadas como "removed"
    local status
    status=$(jq -r ".powers[${i}].status // \"active\"" "${manifest_path}" 2>/dev/null)
    if [[ "${status}" == "removed" ]]; then
      ((i++)) || true
      continue
    fi

    # --- Tratamento de powers em _drafts/ ---
    if [[ -d "${REPO_ROOT}/powers/_drafts/${power}" && ! -d "${REPO_ROOT}/powers/${power}" ]]; then
      log_info "  Power '${power}' movido para _drafts/ (placeholder). Removendo referências..."

      if [[ "${DRY_RUN}" == true ]]; then
        log_warn "[DRY-RUN] Removeria entry do power '${power}' do manifest e limparia steering legado."
      else
        # Remover steering legado se existir
        local legacy_steering="${TARGET_DIR}/.kiro/steering/powers/${power}"
        if [[ -d "${legacy_steering}" ]]; then
          rm -rf "${legacy_steering}"
          log_info "    Steering legado removido: .kiro/steering/powers/${power}/"
        fi

        # Marcar como "removed" no manifest
        local tmp_manifest
        tmp_manifest=$(mktemp)
        jq --argjson idx "${i}" '.powers[$idx].status = "removed"' "${manifest_path}" > "${tmp_manifest}"
        mv "${tmp_manifest}" "${manifest_path}"
        log_info "    Power '${power}' marcado como 'removed' no manifest."
      fi

      ((i++)) || true
      continue
    fi

    # --- Power não encontrado (nem em powers/ nem em _drafts/) ---
    local power_dir="${REPO_ROOT}/powers/${power}"
    if [[ ! -d "${power_dir}" ]]; then
      log_warn "Power '${power}' não encontrado em powers/ nem em _drafts/. Marcando como 'removed'."

      if [[ "${DRY_RUN}" != true ]]; then
        local tmp_manifest
        tmp_manifest=$(mktemp)
        jq --argjson idx "${i}" '.powers[$idx].status = "removed"' "${manifest_path}" > "${tmp_manifest}"
        mv "${tmp_manifest}" "${manifest_path}"
      fi

      ((i++)) || true
      continue
    fi

    # --- Modo "native" ---
    if [[ "${installation_method}" == "native" ]]; then
      log_info "  Power: ${power} (nativo)"

      # Comparar versão do manifest com VERSION file no repositório
      local repo_version="0.0.0"
      if [[ -f "${power_dir}/VERSION" ]]; then
        repo_version=$(cat "${power_dir}/VERSION" | tr -d '[:space:]')
      fi

      if [[ "${manifest_version}" != "${repo_version}" ]]; then
        log_warn "  ⚠ Power '${power}' desatualizado: manifest=${manifest_version}, disponível=${repo_version}"
        log_warn "    → Execute 'git pull' no mb-kiro e use 'Check for updates' no painel de Powers do Kiro IDE."
      else
        log_success "  ✓ Power '${power}' atualizado (v${manifest_version})"
      fi

      ((i++)) || true
      continue
    fi

    # --- Modo "legacy" (ou installation_method ausente) ---
    log_info "  Power: ${power} (legado)"
    log_warn "  ⚠ Power '${power}' utiliza instalação legada."
    log_warn "    → Migre para instalação nativa com: ./scripts/sync.sh --target ${TARGET_DIR} --migrate-powers"

    # Executar sync legado: copiar steerings + merge mcp.json
    if [[ -d "${power_dir}/steering" ]]; then
      sync_files "${power_dir}/steering" "${TARGET_DIR}/.kiro/steering/powers/${power}" "*.md"
    fi

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

    ((i++)) || true
  done

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Powers sincronizados."
  fi
}

# -----------------------------------------------------------------------------
# Migração de powers legados para instalação nativa
# -----------------------------------------------------------------------------

migrate_powers() {
  log_info "Iniciando migração de powers para instalação nativa..."
  echo ""

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"
  local backup_base="${TARGET_DIR}/.kiro/.migration-backup"

  # Verificar jq disponível (necessário para manipular mcp.json)
  if ! command -v jq &>/dev/null; then
    log_error "jq é necessário para migração de powers (manipulação de mcp.json)."
    log_error "Instale com: brew install jq (macOS) ou apt install jq (Linux)"
    exit 1
  fi

  local power_count
  power_count=$(jq -r '.powers | length' "${manifest_path}" 2>/dev/null)

  if [[ "${power_count}" -eq 0 || -z "${power_count}" ]]; then
    log_info "Nenhum power declarado no manifest."
    return
  fi

  # Coletar powers elegíveis para migração
  local migrated_powers=()
  local skipped_powers=()
  local failed_powers=()

  local i=0
  while [[ ${i} -lt ${power_count} ]]; do
    local power
    local installation_method
    local status

    power=$(jq -r ".powers[${i}].name" "${manifest_path}" 2>/dev/null)
    installation_method=$(jq -r ".powers[${i}].installation_method // \"legacy\"" "${manifest_path}" 2>/dev/null)
    status=$(jq -r ".powers[${i}].status // \"active\"" "${manifest_path}" 2>/dev/null)

    # Pular powers removidos
    if [[ "${status}" == "removed" ]]; then
      ((i++)) || true
      continue
    fi

    # Pular powers já nativos
    if [[ "${installation_method}" == "native" ]]; then
      ((i++)) || true
      continue
    fi

    log_info "Processando power: ${power}..."

    # Verificar se existe steering legado
    local legacy_steering="${TARGET_DIR}/.kiro/steering/powers/${power}"
    if [[ ! -d "${legacy_steering}" ]]; then
      log_warn "  Power '${power}' já migrado ou sem instalação legada. Pulando."
      skipped_powers+=("${power}")
      ((i++)) || true
      continue
    fi

    if [[ "${DRY_RUN}" == true ]]; then
      log_warn "[DRY-RUN] Migraria power '${power}':"
      log_warn "  - Backup em: .kiro/.migration-backup/${power}/"
      log_warn "  - Removeria: .kiro/steering/powers/${power}/"
      log_warn "  - Removeria MCP servers do power no mcp.json do projeto"
      log_warn "  - Atualizaria manifest: installation_method=native"
      migrated_powers+=("${power}")
      ((i++)) || true
      continue
    fi

    # --- Execução da migração com rollback em caso de erro ---
    local migration_ok=true
    local backup_dir="${backup_base}/${power}"

    # 1. Backup dos arquivos que serão removidos
    mkdir -p "${backup_dir}"

    # Backup do steering legado
    if [[ -d "${legacy_steering}" ]]; then
      cp -R "${legacy_steering}" "${backup_dir}/steering"
      log_info "  Backup criado: .kiro/.migration-backup/${power}/steering/"
    fi

    # Backup da entrada relevante do mcp.json (se existir)
    local mcp_dest="${TARGET_DIR}/.kiro/settings/mcp.json"
    if [[ -f "${mcp_dest}" ]]; then
      cp "${mcp_dest}" "${backup_dir}/mcp.json.bak"
      log_info "  Backup criado: .kiro/.migration-backup/${power}/mcp.json.bak"
    fi

    # 2. Remover steering legado
    if ! rm -rf "${legacy_steering}"; then
      log_error "  Erro ao remover steering legado de '${power}'."
      migration_ok=false
    else
      log_success "  Steering legado removido: .kiro/steering/powers/${power}/"
    fi

    # 3. Remover MCP servers do power no mcp.json do projeto
    if [[ "${migration_ok}" == true ]]; then
      local power_dir="${REPO_ROOT}/powers/${power}"
      if [[ -f "${power_dir}/mcp.json" && -f "${mcp_dest}" ]]; then
        local power_servers
        power_servers=$(jq -r '.mcpServers | keys[]' "${power_dir}/mcp.json" 2>/dev/null)

        if [[ -n "${power_servers}" ]]; then
          local tmp_mcp
          tmp_mcp=$(mktemp)
          local mcp_current="${mcp_dest}"

          # Remover cada server key que pertence ao power
          local remove_failed=false
          for server_key in ${power_servers}; do
            if ! jq --arg key "${server_key}" 'del(.mcpServers[$key])' "${mcp_current}" > "${tmp_mcp}" 2>/dev/null; then
              remove_failed=true
              break
            fi
            cp "${tmp_mcp}" "${mcp_current}"
            log_success "  MCP server removido: ${server_key}"
          done

          rm -f "${tmp_mcp}"

          if [[ "${remove_failed}" == true ]]; then
            log_error "  Erro ao manipular mcp.json para '${power}'."
            migration_ok=false
          fi
        fi
      fi
    fi

    # 4. Atualizar manifest com installation_method="native" e migrated_at
    if [[ "${migration_ok}" == true ]]; then
      local tmp_manifest
      tmp_manifest=$(mktemp)
      if ! jq --argjson idx "${i}" --arg ts "${TIMESTAMP}" \
        '.powers[$idx].installation_method = "native" | .powers[$idx].migrated_at = $ts' \
        "${manifest_path}" > "${tmp_manifest}" 2>/dev/null; then
        log_error "  Erro ao atualizar manifest para '${power}'."
        migration_ok=false
        rm -f "${tmp_manifest}"
      else
        mv "${tmp_manifest}" "${manifest_path}"
        log_success "  Manifest atualizado: installation_method=native, migrated_at=${TIMESTAMP}"
      fi
    fi

    # 5. Rollback em caso de erro
    if [[ "${migration_ok}" == false ]]; then
      log_error "  Falha na migração de '${power}'. Restaurando backup..."

      # Restaurar steering legado
      if [[ -d "${backup_dir}/steering" ]]; then
        mkdir -p "$(dirname "${legacy_steering}")"
        cp -R "${backup_dir}/steering" "${legacy_steering}"
        log_info "  Steering restaurado de backup."
      fi

      # Restaurar mcp.json
      if [[ -f "${backup_dir}/mcp.json.bak" ]]; then
        cp "${backup_dir}/mcp.json.bak" "${mcp_dest}"
        log_info "  mcp.json restaurado de backup."
      fi

      failed_powers+=("${power}")
    else
      migrated_powers+=("${power}")
      # Limpar diretório pai se vazio (steering/powers/)
      local powers_steering_dir="${TARGET_DIR}/.kiro/steering/powers"
      if [[ -d "${powers_steering_dir}" ]] && [[ -z "$(ls -A "${powers_steering_dir}" 2>/dev/null)" ]]; then
        rmdir "${powers_steering_dir}" 2>/dev/null || true
      fi
    fi

    echo ""
    ((i++)) || true
  done

  # --- Resumo final ---
  echo ""
  echo "============================================"
  log_info "Resumo da migração:"
  echo "============================================"

  if [[ ${#migrated_powers[@]} -gt 0 ]]; then
    echo ""
    if [[ "${DRY_RUN}" == true ]]; then
      log_info "Powers que seriam migrados:"
    else
      log_success "Powers migrados com sucesso:"
    fi
    for p in "${migrated_powers[@]}"; do
      echo "    ✓ ${p}"
    done
  fi

  if [[ ${#skipped_powers[@]} -gt 0 ]]; then
    echo ""
    log_warn "Powers pulados (já migrados ou sem instalação legada):"
    for p in "${skipped_powers[@]}"; do
      echo "    - ${p}"
    done
  fi

  if [[ ${#failed_powers[@]} -gt 0 ]]; then
    echo ""
    log_error "Powers com falha na migração (backup restaurado):"
    for p in "${failed_powers[@]}"; do
      echo "    ✗ ${p}"
    done
  fi

  # Instruções de instalação nativa
  if [[ ${#migrated_powers[@]} -gt 0 ]]; then
    echo ""
    echo "============================================"
    log_info "Próximos passos — Instalação Nativa:"
    echo "============================================"
    echo ""
    log_info "Para cada power migrado, instale via Kiro IDE:"
    echo ""
    log_info "  1. Abra o projeto no Kiro IDE"
    log_info "  2. Abra o painel de Powers (ícone na barra lateral)"
    log_info "  3. Clique em 'Import power from a folder'"
    log_info "  4. Aponte para o diretório do power:"
    echo ""
    for p in "${migrated_powers[@]}"; do
      echo "     ${REPO_ROOT}/powers/${p}/"
    done
    echo ""
    log_info "Após importar, o power será ativado dinamicamente por keywords."
    echo ""
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
  [[ "${MIGRATE_POWERS}" == true ]] && log_info "Modo migração de powers ativado."
  echo ""

  # Se --migrate-powers foi passado, executar migração e sair
  if [[ "${MIGRATE_POWERS}" == true ]]; then
    migrate_powers
    update_manifest_sync_date
    echo ""
    echo "============================================"
    if [[ "${DRY_RUN}" == true ]]; then
      log_warn "Migração simulada (dry-run) concluída."
    else
      log_success "Migração concluída!"
    fi
    echo "============================================"
    echo ""
    return
  fi

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
