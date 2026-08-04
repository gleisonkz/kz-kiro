#!/usr/bin/env bash
# =============================================================================
# sync.sh — Sincronização de Padrões Kiro (MonteBravo)
# =============================================================================
# Atualiza artefatos do baseline (user-level) ou archetype (workspace-level)
# com a versão mais recente da fonte. Suporta migração de projetos legados.
#
# Uso:
#   ./scripts/sync.sh --scope user [--dry-run]
#   ./scripts/sync.sh --scope workspace --target <caminho> [--dry-run]
#   ./scripts/sync.sh --target <caminho> --migrate-to-user-scope [--dry-run]
#   ./scripts/sync.sh --target <caminho> [--component <nome>] [--dry-run]  (legado)
#
# Opções:
#   --scope <user|workspace>     Escopo da sincronização
#   --target <caminho>           Caminho para o diretório do projeto destino
#   --migrate-to-user-scope      Migra projeto legado para o modelo dual-scope
#   --component <nome>           (Legado) baseline | archetype | powers | all
#   --migrate-powers             (Legado) Migra powers legados para instalação nativa
#   --dry-run                    Simula a execução sem aplicar mudanças
#   --help                       Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/sync.sh --scope user
#   ./scripts/sync.sh --scope workspace --target ../meu-projeto
#   ./scripts/sync.sh --target ../meu-projeto --migrate-to-user-scope
#   ./scripts/sync.sh --target ../meu-projeto  (legado: sincroniza tudo no workspace)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configurações globais
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Carregar funções compartilhadas
source "${SCRIPT_DIR}/lib/common.sh"

# Contadores
FILES_UPDATED=0
FILES_ADDED=0
FILES_UNCHANGED=0
FILES_REMOVED=0
MCP_SERVERS_MERGED=0

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

print_help() {
  grep '^#' "${BASH_SOURCE[0]}" | grep -v '#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

# Sincroniza arquivos: copia novos e atualiza os que mudaram.
# (Mantida para compatibilidade com fluxo legado)
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
# Parsing de argumentos
# -----------------------------------------------------------------------------

SCOPE=""
TARGET_DIR=""
COMPONENT="all"
DRY_RUN=false
MIGRATE_POWERS=false
MIGRATE_TO_USER_SCOPE=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope)                  SCOPE="$2"; shift 2 ;;
      --target)                 TARGET_DIR="$2"; shift 2 ;;
      --component)              COMPONENT="$2"; shift 2 ;;
      --migrate-powers)         MIGRATE_POWERS=true; shift ;;
      --migrate-to-user-scope)  MIGRATE_TO_USER_SCOPE=true; shift ;;
      --dry-run)                DRY_RUN=true; shift ;;
      --help|-h)                print_help ;;
      *)
        log_error "Argumento desconhecido: $1"
        log_error "Use --help para ver os argumentos disponíveis."
        exit 1
        ;;
    esac
  done

  # Validar --scope se informado
  if [[ -n "${SCOPE}" ]]; then
    if ! validate_scope "${SCOPE}"; then
      log_error "Valor inválido para --scope: ${SCOPE}"
      log_error "Valores válidos: user, workspace"
      exit 1
    fi
  fi

  # --migrate-to-user-scope requer --target
  if [[ "${MIGRATE_TO_USER_SCOPE}" == true && -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    log_error "--target é obrigatório ao usar --migrate-to-user-scope."
    exit 1
  fi

  # --scope workspace requer --target
  if [[ "${SCOPE}" == "workspace" && -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    log_error "--target é obrigatório para o escopo workspace."
    exit 1
  fi

  # Validar --target se informado
  if [[ -n "${TARGET_DIR}" ]]; then
    TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)" || {
      log_error "Diretório destino não encontrado: ${TARGET_DIR}"
      exit 1
    }
  fi
}

# -----------------------------------------------------------------------------
# Detecção de modelo legado
# -----------------------------------------------------------------------------

# Verifica se o manifest do projeto é legado (sem campo baseline.scope)
# Retorna 0 se legado, 1 se não
is_legacy_manifest() {
  local manifest_path="${1:-${TARGET_DIR}/kiro-manifest.json}"

  if [[ ! -f "${manifest_path}" ]]; then
    return 1
  fi

  if command -v jq &>/dev/null; then
    local scope_value
    scope_value="$(jq -r '.baseline.scope // empty' "${manifest_path}" 2>/dev/null)"
    [[ -z "${scope_value}" ]]
  else
    # Fallback sem jq: verificar presença do campo "scope" dentro de baseline
    ! grep -q '"scope"' "${manifest_path}" 2>/dev/null
  fi
}

# -----------------------------------------------------------------------------
# Funções de sincronização — Scope User (stub para task 5)
# -----------------------------------------------------------------------------

sync_user_scope() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Sync — Scope User"
  echo "============================================"
  echo ""

  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  echo ""

  local user_kiro_dir
  user_kiro_dir="$(get_user_kiro_dir)"

  # Verificar que ~/.kiro/ existe
  if [[ ! -d "${user_kiro_dir}" ]]; then
    log_error "Diretório ${user_kiro_dir} não encontrado."
    log_error "O baseline não foi instalado. Execute: bootstrap.sh --scope user"
    exit 1
  fi

  # Verificar que baselines/global/ existe
  local baseline_dir="${REPO_ROOT}/baselines/global"
  if [[ ! -d "${baseline_dir}" ]]; then
    log_error "Fonte do baseline não encontrada: ${baseline_dir}"
    log_error "Verifique se o repositório mb-kiro está íntegro."
    exit 1
  fi

  # Flag para erros não-fatais (ex: falha ao remover órfão)
  local had_errors=false

  # ------------------------------------------------------------------
  # Sincronizar steering files
  # ------------------------------------------------------------------
  local steering_src="${baseline_dir}/steering"
  local steering_dest="${user_kiro_dir}/steering"

  log_info "Sincronizando steering files..."

  if [[ -d "${steering_src}" ]]; then
    mkdir -p "${steering_dest}"

    for file in "${steering_src}"/*.md; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"

      # Pular README.md
      [[ "${filename}" == "README.md" ]] && continue

      local dest_file="${steering_dest}/$(add_prefix "${filename}")"

      if [[ "${DRY_RUN}" == true ]]; then
        if [[ ! -f "${dest_file}" ]]; then
          log_info "  [DRY-RUN] Adicionaria: $(add_prefix "${filename}")"
          ((FILES_ADDED++)) || true
        elif ! cmp -s "${file}" "${dest_file}"; then
          log_info "  [DRY-RUN] Atualizaria: $(add_prefix "${filename}")"
          ((FILES_UPDATED++)) || true
        else
          ((FILES_UNCHANGED++)) || true
        fi
        continue
      fi

      if [[ ! -f "${dest_file}" ]]; then
        cp "${file}" "${dest_file}"
        log_success "  + $(add_prefix "${filename}") (novo)"
        ((FILES_ADDED++)) || true
      elif ! cmp -s "${file}" "${dest_file}"; then
        cp "${file}" "${dest_file}"
        log_success "  ~ $(add_prefix "${filename}") (atualizado)"
        ((FILES_UPDATED++)) || true
      else
        ((FILES_UNCHANGED++)) || true
      fi
    done
  fi

  # ------------------------------------------------------------------
  # Sincronizar hooks
  # ------------------------------------------------------------------
  local hooks_src="${baseline_dir}/hooks"
  local hooks_dest="${user_kiro_dir}/hooks"

  echo ""
  log_info "Sincronizando hooks..."

  if [[ -d "${hooks_src}" ]]; then
    mkdir -p "${hooks_dest}"

    for file in "${hooks_src}"/*.kiro.hook; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"

      local dest_file="${hooks_dest}/$(add_prefix "${filename}")"

      if [[ "${DRY_RUN}" == true ]]; then
        if [[ ! -f "${dest_file}" ]]; then
          log_info "  [DRY-RUN] Adicionaria: $(add_prefix "${filename}")"
          ((FILES_ADDED++)) || true
        elif ! cmp -s "${file}" "${dest_file}"; then
          log_info "  [DRY-RUN] Atualizaria: $(add_prefix "${filename}")"
          ((FILES_UPDATED++)) || true
        else
          ((FILES_UNCHANGED++)) || true
        fi
        continue
      fi

      if [[ ! -f "${dest_file}" ]]; then
        cp "${file}" "${dest_file}"
        log_success "  + $(add_prefix "${filename}") (novo)"
        ((FILES_ADDED++)) || true
      elif ! cmp -s "${file}" "${dest_file}"; then
        cp "${file}" "${dest_file}"
        log_success "  ~ $(add_prefix "${filename}") (atualizado)"
        ((FILES_UPDATED++)) || true
      else
        ((FILES_UNCHANGED++)) || true
      fi
    done
  fi

  # ------------------------------------------------------------------
  # Mergear servidores MCP
  # ------------------------------------------------------------------
  local baseline_mcp="${baseline_dir}/mcp/mcp.json"
  local user_mcp="${user_kiro_dir}/settings/mcp.json"

  echo ""
  log_info "Mergeando servidores MCP..."

  if [[ -f "${baseline_mcp}" ]]; then
    if [[ "${DRY_RUN}" == true ]]; then
      if command -v jq &>/dev/null; then
        local server_keys
        server_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"
        for key in ${server_keys}; do
          if [[ -f "${user_mcp}" ]] && jq -e ".mcpServers[\"${key}\"]" "${user_mcp}" &>/dev/null; then
            log_info "  [DRY-RUN] Atualizaria servidor: ${key}"
          else
            log_info "  [DRY-RUN] Adicionaria servidor: ${key}"
          fi
          ((MCP_SERVERS_MERGED++)) || true
        done
      else
        log_info "  [DRY-RUN] Mergearia servidores de ${baseline_mcp}"
      fi
    else
      mkdir -p "${user_kiro_dir}/settings"

      # Emitir warnings para servidores que serão atualizados
      if [[ -f "${user_mcp}" ]] && command -v jq &>/dev/null; then
        local baseline_keys
        baseline_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"
        for key in ${baseline_keys}; do
          if jq -e ".mcpServers[\"${key}\"]" "${user_mcp}" &>/dev/null; then
            log_warn "Servidor MCP '${key}' já existe — atualizando com versão do baseline."
          fi
          ((MCP_SERVERS_MERGED++)) || true
        done
      else
        if command -v jq &>/dev/null; then
          local count
          count="$(jq -r '.mcpServers | keys | length' "${baseline_mcp}" 2>/dev/null)"
          MCP_SERVERS_MERGED="${count}"
        fi
      fi

      merge_mcp_servers "${baseline_mcp}" "${user_mcp}"
      log_success "  Servidores MCP mergeados."
    fi
  else
    log_warn "Arquivo MCP baseline não encontrado: ${baseline_mcp}"
  fi

  # ------------------------------------------------------------------
  # Atualizar mb-baseline-version
  # ------------------------------------------------------------------
  local version_file="${baseline_dir}/VERSION"

  echo ""
  log_info "Atualizando versão do baseline..."

  if [[ -f "${version_file}" ]]; then
    local baseline_version
    baseline_version="$(tr -d '[:space:]' < "${version_file}")"

    if [[ "${DRY_RUN}" == true ]]; then
      log_info "  [DRY-RUN] Atualizaria mb-baseline-version → ${baseline_version}"
    else
      printf '%s' "${baseline_version}" > "${user_kiro_dir}/mb-baseline-version"
      log_success "  mb-baseline-version → ${baseline_version}"
    fi
  else
    log_warn "Arquivo VERSION não encontrado: ${version_file}"
  fi

  # ------------------------------------------------------------------
  # Limpeza de órfãos — steering files
  # ------------------------------------------------------------------
  echo ""
  log_info "Verificando órfãos..."

  local orphan_steerings
  orphan_steerings="$(find_orphans "${steering_dest}" "${steering_src}")"

  if [[ -n "${orphan_steerings}" ]]; then
    while IFS= read -r orphan; do
      local original_name
      original_name="$(strip_prefix "${orphan}")"

      if [[ "${DRY_RUN}" == true ]]; then
        log_info "  [DRY-RUN] Removeria steering órfão: ${original_name}"
        ((FILES_REMOVED++)) || true
      else
        if rm -f "${steering_dest}/${orphan}" 2>/dev/null; then
          log_success "  - ${original_name} (steering órfão removido)"
          ((FILES_REMOVED++)) || true
        else
          log_error "  Falha ao remover steering órfão: ${orphan}"
          had_errors=true
        fi
      fi
    done <<< "${orphan_steerings}"
  fi

  # ------------------------------------------------------------------
  # Limpeza de órfãos — hooks
  # ------------------------------------------------------------------
  local orphan_hooks
  orphan_hooks="$(find_orphans "${hooks_dest}" "${hooks_src}")"

  if [[ -n "${orphan_hooks}" ]]; then
    while IFS= read -r orphan; do
      local original_name
      original_name="$(strip_prefix "${orphan}")"

      if [[ "${DRY_RUN}" == true ]]; then
        log_info "  [DRY-RUN] Removeria hook órfão: ${original_name}"
        ((FILES_REMOVED++)) || true
      else
        if rm -f "${hooks_dest}/${orphan}" 2>/dev/null; then
          log_success "  - ${original_name} (hook órfão removido)"
          ((FILES_REMOVED++)) || true
        else
          log_error "  Falha ao remover hook órfão: ${orphan}"
          had_errors=true
        fi
      fi
    done <<< "${orphan_hooks}"
  fi

  # ------------------------------------------------------------------
  # Limpeza de órfãos — servidores MCP
  # ------------------------------------------------------------------
  if [[ -f "${user_mcp}" && -f "${baseline_mcp}" ]] && command -v jq &>/dev/null; then
    # Identificar servidores no user_mcp que são do baseline (existiam na versão anterior)
    # mas não existem mais no baseline atual
    local user_keys baseline_keys_current

    user_keys="$(jq -r '.mcpServers | keys[]' "${user_mcp}" 2>/dev/null)"
    baseline_keys_current="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"

    # Precisamos identificar quais servidores no user_mcp são do baseline.
    # Estratégia: servidores com chave que existiam no baseline anterior mas não no atual.
    # Como não temos histórico, usamos heurística: se a chave NÃO está no baseline atual
    # E corresponde a um padrão do baseline (checamos com mb-baseline-version existente).
    # Na prática, precisamos de um registro de quais chaves o baseline já provisionou.
    # Usamos a abordagem: se o servidor existia E NÃO está mais no baseline → pode ser pessoal.
    # Para ser conservador e seguir o design, removemos apenas chaves que estavam no baseline
    # anterior. Como não temos esse registro, usamos a abordagem de "baseline keys tracking":
    # Se existe um campo _baseline_keys ou se inferimos pela presença anterior.
    #
    # Abordagem simplificada (conforme design): comparar chaves no user_mcp com chaves
    # no baseline atual. Chaves no user que NÃO estão no baseline atual E que
    # NÃO são pessoais (foram provisionadas pelo baseline em algum momento).
    # Como não há tracking explícito, usamos a versão anterior do mcp para comparar.
    # Fallback: sem tracking, pulamos remoção de MCP órfãos (requer implementação futura).
    #
    # NOTA: O design diz "identificar servidores MCP presentes em ~/.kiro/settings/mcp.json
    # cuja chave corresponda a um servidor anteriormente provisionado pelo baseline e que
    # não exista mais em baselines/global/mcp/mcp.json".
    # Sem tracking de chaves, não há como saber com certeza quais são do baseline.
    # Implementação conservadora: não remover MCP órfãos sem tracking.
    # Isso será coberto quando houver um mecanismo de tracking (ex: _baseline_managed_keys).

    :  # placeholder — sem tracking, não removemos MCP órfãos automaticamente
  fi

  # ------------------------------------------------------------------
  # Resumo final
  # ------------------------------------------------------------------
  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "Sincronização simulada (dry-run) concluída."
    echo ""
    log_info "  Novos:       ${FILES_ADDED}"
    log_info "  Atualizados: ${FILES_UPDATED}"
    log_info "  Sem mudança: ${FILES_UNCHANGED}"
    log_info "  Removidos:   ${FILES_REMOVED}"
    log_info "  MCP servers: ${MCP_SERVERS_MERGED}"
  else
    log_success "Sincronização user-scope concluída!"
    echo ""
    log_info "  Novos:       ${FILES_ADDED}"
    log_info "  Atualizados: ${FILES_UPDATED}"
    log_info "  Sem mudança: ${FILES_UNCHANGED}"
    log_info "  Removidos:   ${FILES_REMOVED}"
    log_info "  MCP servers: ${MCP_SERVERS_MERGED}"
  fi
  echo "============================================"
  echo ""

  # Exit code 1 se houve erro ao remover órfão
  if [[ "${had_errors}" == true ]]; then
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Funções de sincronização — Scope Workspace
# -----------------------------------------------------------------------------

# Sincroniza um diretório de artefatos do archetype com o workspace.
# Adiciona novos, atualiza diferentes, remove órfãos.
# Uso: sync_archetype_dir <src_dir> <dest_dir> <file_pattern> <label>
sync_archetype_dir() {
  local src_dir="$1"
  local dest_dir="$2"
  local file_pattern="$3"
  local label="$4"

  if [[ ! -d "${src_dir}" ]]; then
    return
  fi

  # Verificar se há arquivos correspondentes ao pattern
  local file_count
  file_count=$(find "${src_dir}" -maxdepth 1 -name "${file_pattern}" -not -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [[ "${file_count}" -eq 0 ]]; then
    return
  fi

  mkdir -p "${dest_dir}"

  # Adicionar/atualizar arquivos do archetype
  for file in "${src_dir}"/${file_pattern}; do
    [[ ! -f "${file}" ]] && continue
    local filename
    filename="$(basename "${file}")"

    # Pular README.md
    [[ "${filename}" == "README.md" ]] && continue

    local dest_file="${dest_dir}/${filename}"

    if [[ "${DRY_RUN}" == true ]]; then
      if [[ ! -f "${dest_file}" ]]; then
        log_info "  [DRY-RUN] Adicionaria ${label}: ${filename}"
        ((FILES_ADDED++)) || true
      elif ! cmp -s "${file}" "${dest_file}"; then
        log_info "  [DRY-RUN] Atualizaria ${label}: ${filename}"
        ((FILES_UPDATED++)) || true
      else
        ((FILES_UNCHANGED++)) || true
      fi
      continue
    fi

    if [[ ! -f "${dest_file}" ]]; then
      cp "${file}" "${dest_file}"
      log_success "  + ${filename} (novo)"
      ((FILES_ADDED++)) || true
    elif ! cmp -s "${file}" "${dest_file}"; then
      cp "${file}" "${dest_file}"
      log_success "  ~ ${filename} (atualizado)"
      ((FILES_UPDATED++)) || true
    else
      ((FILES_UNCHANGED++)) || true
    fi
  done

  # Remover arquivos do workspace que não existem mais no archetype
  for dest_file in "${dest_dir}"/${file_pattern}; do
    [[ ! -f "${dest_file}" ]] && continue
    local filename
    filename="$(basename "${dest_file}")"

    # Pular README.md
    [[ "${filename}" == "README.md" ]] && continue

    # Verificar se existe correspondente na fonte
    if [[ ! -f "${src_dir}/${filename}" ]]; then
      if [[ "${DRY_RUN}" == true ]]; then
        log_info "  [DRY-RUN] Removeria ${label} órfão: ${filename}"
        ((FILES_REMOVED++)) || true
      else
        if rm -f "${dest_file}" 2>/dev/null; then
          log_success "  - ${filename} (removido — não existe mais no archetype)"
          ((FILES_REMOVED++)) || true
        else
          log_error "  Falha ao remover ${label} órfão: ${filename}"
          WORKSPACE_SYNC_ERRORS=true
        fi
      fi
    fi
  done
}

sync_workspace_scope() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Sync — Scope Workspace"
  echo "============================================"
  echo ""

  log_info "Destino: ${TARGET_DIR}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  echo ""

  # Flag para erros não-fatais
  WORKSPACE_SYNC_ERRORS=false

  # ------------------------------------------------------------------
  # Validar que manifest existe no target
  # ------------------------------------------------------------------
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ ! -f "${manifest_path}" ]]; then
    log_error "kiro-manifest.json não encontrado em: ${TARGET_DIR}"
    log_error "Execute o bootstrap primeiro: ./scripts/bootstrap.sh --scope workspace --target ${TARGET_DIR} --project-type <tipo>"
    exit 1
  fi

  # ------------------------------------------------------------------
  # Ler archetype.name do manifest
  # ------------------------------------------------------------------
  local archetype_name=""

  if command -v jq &>/dev/null; then
    archetype_name="$(jq -r '.archetype.name // empty' "${manifest_path}" 2>/dev/null)"
  else
    # Fallback sem jq
    archetype_name="$(grep -o '"name": *"[^"]*"' "${manifest_path}" | head -1 | sed 's/.*: *"\(.*\)"/\1/')"
  fi

  if [[ -z "${archetype_name}" ]]; then
    log_error "Não foi possível determinar o archetype do projeto a partir do manifest."
    log_error "Verifique o campo archetype.name em: ${manifest_path}"
    exit 1
  fi

  local archetype_dir="${REPO_ROOT}/archetypes/${archetype_name}"

  if [[ ! -d "${archetype_dir}" ]]; then
    log_error "Archetype não encontrado: ${archetype_name}"
    log_error "Diretório esperado: ${archetype_dir}"
    exit 1
  fi

  log_info "Archetype: ${archetype_name}"
  log_info "Fonte:     ${archetype_dir}"
  echo ""

  # ------------------------------------------------------------------
  # Diretório workspace .kiro/
  # ------------------------------------------------------------------
  local workspace_kiro="${TARGET_DIR}/.kiro"

  # ------------------------------------------------------------------
  # Sincronizar steering files
  # ------------------------------------------------------------------
  log_info "Sincronizando steering files..."
  sync_archetype_dir \
    "${archetype_dir}/steering" \
    "${workspace_kiro}/steering" \
    "*.md" \
    "steering"

  # ------------------------------------------------------------------
  # Sincronizar skills
  # ------------------------------------------------------------------
  echo ""
  log_info "Sincronizando skills..."
  sync_archetype_dir \
    "${archetype_dir}/skills" \
    "${workspace_kiro}/skills" \
    "*.md" \
    "skill"

  # ------------------------------------------------------------------
  # Sincronizar hooks
  # ------------------------------------------------------------------
  echo ""
  log_info "Sincronizando hooks..."
  sync_archetype_dir \
    "${archetype_dir}/hooks" \
    "${workspace_kiro}/hooks" \
    "*.kiro.hook" \
    "hook"

  # ------------------------------------------------------------------
  # Sincronizar agents (*.md e *.json)
  # ------------------------------------------------------------------
  echo ""
  log_info "Sincronizando agents..."
  sync_archetype_dir \
    "${archetype_dir}/agents" \
    "${workspace_kiro}/agents" \
    "*.md" \
    "agent"
  sync_archetype_dir \
    "${archetype_dir}/agents" \
    "${workspace_kiro}/agents" \
    "*.json" \
    "agent"

  # ------------------------------------------------------------------
  # Re-mergear servidores MCP do archetype (sem baseline)
  # ------------------------------------------------------------------
  local archetype_mcp="${archetype_dir}/mcp/mcp.json"
  local workspace_mcp="${workspace_kiro}/settings/mcp.json"

  echo ""
  log_info "Mergeando servidores MCP do archetype..."

  if [[ -f "${archetype_mcp}" ]]; then
    if [[ "${DRY_RUN}" == true ]]; then
      if command -v jq &>/dev/null; then
        local server_keys
        server_keys="$(jq -r '.mcpServers | keys[]' "${archetype_mcp}" 2>/dev/null)"
        for key in ${server_keys}; do
          if [[ -f "${workspace_mcp}" ]] && jq -e ".mcpServers[\"${key}\"]" "${workspace_mcp}" &>/dev/null; then
            log_info "  [DRY-RUN] Atualizaria servidor: ${key}"
          else
            log_info "  [DRY-RUN] Adicionaria servidor: ${key}"
          fi
          ((MCP_SERVERS_MERGED++)) || true
        done
      else
        log_info "  [DRY-RUN] Mergearia servidores de ${archetype_mcp}"
      fi
    else
      mkdir -p "${workspace_kiro}/settings"

      # Emitir info para servidores que serão atualizados
      if [[ -f "${workspace_mcp}" ]] && command -v jq &>/dev/null; then
        local archetype_keys
        archetype_keys="$(jq -r '.mcpServers | keys[]' "${archetype_mcp}" 2>/dev/null)"
        for key in ${archetype_keys}; do
          if jq -e ".mcpServers[\"${key}\"]" "${workspace_mcp}" &>/dev/null; then
            log_info "  Atualizando servidor: ${key}"
          else
            log_info "  Adicionando servidor: ${key}"
          fi
          ((MCP_SERVERS_MERGED++)) || true
        done
      else
        if command -v jq &>/dev/null; then
          local count
          count="$(jq -r '.mcpServers | keys | length' "${archetype_mcp}" 2>/dev/null)"
          MCP_SERVERS_MERGED="${count}"
        fi
      fi

      merge_mcp_servers "${archetype_mcp}" "${workspace_mcp}"
      log_success "  Servidores MCP do archetype mergeados."
    fi
  else
    log_info "  Arquivo MCP do archetype não encontrado. Pulando."
  fi

  # ------------------------------------------------------------------
  # Atualizar last_synced_at no manifest
  # ------------------------------------------------------------------
  if [[ "${DRY_RUN}" != true ]]; then
    if command -v jq &>/dev/null; then
      local tmp_manifest
      tmp_manifest="$(mktemp)"
      if jq --arg ts "${TIMESTAMP}" '.archetype.last_synced_at = $ts' "${manifest_path}" > "${tmp_manifest}" 2>/dev/null; then
        mv "${tmp_manifest}" "${manifest_path}"
      else
        rm -f "${tmp_manifest}"
      fi
    fi
  fi

  # ------------------------------------------------------------------
  # Resumo final
  # ------------------------------------------------------------------
  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "Sincronização workspace simulada (dry-run) concluída."
    echo ""
    log_info "  Novos:       ${FILES_ADDED}"
    log_info "  Atualizados: ${FILES_UPDATED}"
    log_info "  Sem mudança: ${FILES_UNCHANGED}"
    log_info "  Removidos:   ${FILES_REMOVED}"
    log_info "  MCP servers: ${MCP_SERVERS_MERGED}"
  else
    log_success "Sincronização workspace concluída!"
    echo ""
    log_info "  Novos:       ${FILES_ADDED}"
    log_info "  Atualizados: ${FILES_UPDATED}"
    log_info "  Sem mudança: ${FILES_UNCHANGED}"
    log_info "  Removidos:   ${FILES_REMOVED}"
    log_info "  MCP servers: ${MCP_SERVERS_MERGED}"
  fi
  echo "============================================"
  echo ""

  # Exit code 1 se houve erros não-fatais
  if [[ "${WORKSPACE_SYNC_ERRORS}" == true ]]; then
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Migração para user-scope
# -----------------------------------------------------------------------------

# Variável global para controle de rollback em caso de interrupção
_MIGRATION_BACKUP_DIR=""
_MIGRATION_IN_PROGRESS=false
_MIGRATION_STEP=""

# Handler para SIGINT/SIGTERM — garante rollback se migração estiver em andamento
_migration_cleanup() {
  if [[ "${_MIGRATION_IN_PROGRESS}" == true && -n "${_MIGRATION_BACKUP_DIR}" ]]; then
    echo ""
    log_warn "Interrupção detectada durante migração. Executando rollback..."
    _migration_rollback
    log_error "Migração interrompida na etapa: ${_MIGRATION_STEP}"
    exit 1
  fi
}

# Restaura estado do workspace a partir do backup
_migration_rollback() {
  local workspace_kiro="${TARGET_DIR}/.kiro"
  local backup_dir="${_MIGRATION_BACKUP_DIR}"

  # Restaurar steerings do backup
  if [[ -d "${backup_dir}/steering" ]]; then
    for file in "${backup_dir}/steering/"*; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      cp "${file}" "${workspace_kiro}/steering/${filename}" 2>/dev/null || true
    done
    log_info "  Steerings restaurados do backup."
  fi

  # Restaurar hooks do backup
  if [[ -d "${backup_dir}/hooks" ]]; then
    for file in "${backup_dir}/hooks/"*; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      cp "${file}" "${workspace_kiro}/hooks/${filename}" 2>/dev/null || true
    done
    log_info "  Hooks restaurados do backup."
  fi

  # Restaurar MCP servers removidos
  if [[ -f "${backup_dir}/mcp-servers-removed.json" ]]; then
    local workspace_mcp="${workspace_kiro}/settings/mcp.json"
    if [[ -f "${workspace_mcp}" ]] && command -v jq &>/dev/null; then
      local tmp_restored
      tmp_restored="$(mktemp)"
      # Merge os servidores removidos de volta no mcp.json
      if jq -s '{ "mcpServers": (.[0].mcpServers * .[1].mcpServers) }' \
        "${workspace_mcp}" "${backup_dir}/mcp-servers-removed.json" > "${tmp_restored}" 2>/dev/null; then
        mv "${tmp_restored}" "${workspace_mcp}"
        log_info "  Servidores MCP restaurados do backup."
      else
        rm -f "${tmp_restored}"
        log_warn "  Falha ao restaurar MCP via jq. Tentando restaurar backup completo..."
      fi
    fi
  fi

  # Restaurar manifest original (se existir backup)
  if [[ -f "${backup_dir}/kiro-manifest.json.bak" ]]; then
    cp "${backup_dir}/kiro-manifest.json.bak" "${TARGET_DIR}/kiro-manifest.json" 2>/dev/null || true
    log_info "  Manifest restaurado do backup."
  fi
}

migrate_to_user_scope() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Sync — Migração para User Scope"
  echo "============================================"
  echo ""

  log_info "Destino: ${TARGET_DIR}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  echo ""

  # ------------------------------------------------------------------
  # 1. Verificar que manifest existe
  # ------------------------------------------------------------------
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ ! -f "${manifest_path}" ]]; then
    log_error "kiro-manifest.json não encontrado em: ${TARGET_DIR}"
    log_error "O projeto não foi inicializado. Execute primeiro:"
    log_error "  ./scripts/bootstrap.sh --scope workspace --target ${TARGET_DIR} --project-type <tipo>"
    exit 1
  fi

  # ------------------------------------------------------------------
  # 2. Verificar se já está migrado (idempotência)
  # ------------------------------------------------------------------
  if command -v jq &>/dev/null; then
    local current_scope
    current_scope="$(jq -r '.baseline.scope // empty' "${manifest_path}" 2>/dev/null)"

    if [[ "${current_scope}" == "user" ]]; then
      log_success "Projeto já está no modelo de escopo user."
      log_info "Nenhuma ação necessária."
      exit 0
    fi
  else
    # Fallback sem jq: verificar presença de "scope": "user"
    if grep -q '"scope"[[:space:]]*:[[:space:]]*"user"' "${manifest_path}" 2>/dev/null; then
      log_success "Projeto já está no modelo de escopo user."
      log_info "Nenhuma ação necessária."
      exit 0
    fi
  fi

  # ------------------------------------------------------------------
  # Verificar jq para operações de migração (obrigatório)
  # ------------------------------------------------------------------
  if ! command -v jq &>/dev/null; then
    log_error "jq é necessário para a migração (manipulação de JSON)."
    log_error "Instale com: brew install jq (macOS) ou apt install jq (Linux)"
    exit 1
  fi

  # ------------------------------------------------------------------
  # Configurações da migração
  # ------------------------------------------------------------------
  local workspace_kiro="${TARGET_DIR}/.kiro"
  local baseline_dir="${REPO_ROOT}/baselines/global"
  local backup_dir="${workspace_kiro}/.migration-backup/baseline"

  # ------------------------------------------------------------------
  # DRY-RUN: simular migração sem aplicar
  # ------------------------------------------------------------------
  if [[ "${DRY_RUN}" == true ]]; then
    log_info "Simulando migração..."
    echo ""

    # Listar steerings que seriam removidos
    log_info "Steerings que seriam removidos:"
    if [[ -d "${baseline_dir}/steering" ]]; then
      for file in "${baseline_dir}/steering/"*.md; do
        [[ ! -f "${file}" ]] && continue
        local filename
        filename="$(basename "${file}")"
        [[ "${filename}" == "README.md" ]] && continue
        local target_file="${workspace_kiro}/steering/${filename}"
        if [[ -f "${target_file}" ]]; then
          log_info "  [DRY-RUN] Removeria: steering/${filename}"
        fi
      done
    fi

    # Listar hooks que seriam removidos
    if [[ -d "${baseline_dir}/hooks" ]]; then
      for file in "${baseline_dir}/hooks/"*.kiro.hook; do
        [[ ! -f "${file}" ]] && continue
        local filename
        filename="$(basename "${file}")"
        local target_file="${workspace_kiro}/hooks/${filename}"
        if [[ -f "${target_file}" ]]; then
          log_info "  [DRY-RUN] Removeria: hooks/${filename}"
        fi
      done
    fi

    # Listar servidores MCP que seriam removidos
    echo ""
    log_info "Servidores MCP que seriam removidos:"
    local baseline_mcp="${baseline_dir}/mcp/mcp.json"
    if [[ -f "${baseline_mcp}" ]]; then
      local baseline_keys
      baseline_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"
      for key in ${baseline_keys}; do
        log_info "  [DRY-RUN] Removeria servidor: ${key}"
      done
    fi

    # Alterações no manifest
    echo ""
    log_info "Alterações no manifest:"
    log_info "  [DRY-RUN] Adicionaria: baseline.scope = \"user\""
    log_info "  [DRY-RUN] Removeria: baseline.version"
    log_info "  [DRY-RUN] Removeria: baseline.installed_at"
    log_info "  [DRY-RUN] Removeria: baseline.last_synced_at"
    log_info "  [DRY-RUN] Atualizaria: schema_version = \"2.0.0\""

    echo ""
    echo "============================================"
    log_warn "Migração simulada (dry-run) concluída."
    log_info "Nenhuma mudança foi aplicada."
    echo "============================================"
    echo ""
    return
  fi

  # ------------------------------------------------------------------
  # 3. Criar backup
  # ------------------------------------------------------------------
  log_info "Criando backup dos artefatos do baseline..."

  mkdir -p "${backup_dir}/steering"
  mkdir -p "${backup_dir}/hooks"

  # Backup dos steerings do baseline presentes no workspace
  if [[ -d "${baseline_dir}/steering" ]]; then
    for file in "${baseline_dir}/steering/"*.md; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      [[ "${filename}" == "README.md" ]] && continue
      local target_file="${workspace_kiro}/steering/${filename}"
      if [[ -f "${target_file}" ]]; then
        cp "${target_file}" "${backup_dir}/steering/${filename}"
      fi
    done
  fi

  # Backup dos hooks do baseline presentes no workspace
  if [[ -d "${baseline_dir}/hooks" ]]; then
    for file in "${baseline_dir}/hooks/"*.kiro.hook; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      local target_file="${workspace_kiro}/hooks/${filename}"
      if [[ -f "${target_file}" ]]; then
        cp "${target_file}" "${backup_dir}/hooks/${filename}"
      fi
    done
  fi

  # Backup do manifest original
  cp "${manifest_path}" "${backup_dir}/kiro-manifest.json.bak"

  log_success "  Backup criado em: .kiro/.migration-backup/baseline/"

  # ------------------------------------------------------------------
  # Configurar trap para rollback em SIGINT/SIGTERM
  # ------------------------------------------------------------------
  _MIGRATION_BACKUP_DIR="${backup_dir}"
  _MIGRATION_IN_PROGRESS=true
  trap _migration_cleanup SIGINT SIGTERM

  # ------------------------------------------------------------------
  # 4. TRY: Remover steerings do baseline
  # ------------------------------------------------------------------
  echo ""
  _MIGRATION_STEP="remover steerings do baseline"
  log_info "Removendo steerings do baseline do workspace..."

  if [[ -d "${baseline_dir}/steering" ]]; then
    for file in "${baseline_dir}/steering/"*.md; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      [[ "${filename}" == "README.md" ]] && continue
      local target_file="${workspace_kiro}/steering/${filename}"
      if [[ -f "${target_file}" ]]; then
        if ! rm -f "${target_file}"; then
          log_error "Falha ao remover: steering/${filename}"
          log_error "Restaurando backup..."
          _migration_rollback
          _MIGRATION_IN_PROGRESS=false
          exit 1
        fi
        log_success "  - steering/${filename}"
      fi
    done
  fi

  # ------------------------------------------------------------------
  # 5. TRY: Remover hooks do baseline
  # ------------------------------------------------------------------
  _MIGRATION_STEP="remover hooks do baseline"
  log_info "Removendo hooks do baseline do workspace..."

  if [[ -d "${baseline_dir}/hooks" ]]; then
    for file in "${baseline_dir}/hooks/"*.kiro.hook; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"
      local target_file="${workspace_kiro}/hooks/${filename}"
      if [[ -f "${target_file}" ]]; then
        if ! rm -f "${target_file}"; then
          log_error "Falha ao remover: hooks/${filename}"
          log_error "Restaurando backup..."
          _migration_rollback
          _MIGRATION_IN_PROGRESS=false
          exit 1
        fi
        log_success "  - hooks/${filename}"
      fi
    done
  fi

  # ------------------------------------------------------------------
  # 6. TRY: Remover servidores baseline do MCP preservando archetype
  # ------------------------------------------------------------------
  _MIGRATION_STEP="remover servidores baseline do MCP"
  local workspace_mcp="${workspace_kiro}/settings/mcp.json"
  local baseline_mcp="${baseline_dir}/mcp/mcp.json"

  echo ""
  log_info "Removendo servidores baseline do MCP..."

  if [[ -f "${workspace_mcp}" && -f "${baseline_mcp}" ]]; then
    # Salvar servidores que serão removidos para backup
    local baseline_keys
    baseline_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"

    # Criar JSON com servidores que serão removidos (para possível rollback)
    local removed_servers
    removed_servers="$(mktemp)"
    echo '{"mcpServers":{}}' > "${removed_servers}"

    for key in ${baseline_keys}; do
      # Verificar se o servidor existe no workspace mcp
      if jq -e ".mcpServers[\"${key}\"]" "${workspace_mcp}" &>/dev/null; then
        # Salvar servidor removido para backup
        local tmp_removed
        tmp_removed="$(mktemp)"
        if jq --arg k "${key}" '.mcpServers[$k] as $v | . * {"mcpServers": {($k): $v}}' \
          "${workspace_mcp}" > "${tmp_removed}" 2>/dev/null; then
          # Merge no arquivo de servidores removidos
          local tmp_merge
          tmp_merge="$(mktemp)"
          jq -s '{"mcpServers": (.[0].mcpServers * .[1].mcpServers)}' \
            "${removed_servers}" "${tmp_removed}" > "${tmp_merge}" 2>/dev/null
          mv "${tmp_merge}" "${removed_servers}"
          rm -f "${tmp_removed}"
        else
          rm -f "${tmp_removed}"
        fi
      fi
    done

    # Salvar backup dos servidores removidos
    cp "${removed_servers}" "${backup_dir}/mcp-servers-removed.json"
    rm -f "${removed_servers}"

    # Remover servidores baseline do workspace mcp
    local keys_array=()
    for key in ${baseline_keys}; do
      keys_array+=("${key}")
    done

    if [[ ${#keys_array[@]} -gt 0 ]]; then
      if ! remove_mcp_servers "${workspace_mcp}" "${keys_array[@]}"; then
        log_error "Falha ao remover servidores baseline do MCP."
        log_error "Restaurando backup..."
        _migration_rollback
        _MIGRATION_IN_PROGRESS=false
        exit 1
      fi
      for key in "${keys_array[@]}"; do
        log_success "  - servidor MCP: ${key}"
      done
    fi
  else
    log_info "  Sem MCP para limpar (arquivo não encontrado)."
  fi

  # ------------------------------------------------------------------
  # 7. TRY: Atualizar manifest
  # ------------------------------------------------------------------
  _MIGRATION_STEP="atualizar manifest"
  echo ""
  log_info "Atualizando manifest..."

  local tmp_manifest
  tmp_manifest="$(mktemp)"

  if ! jq '
    .schema_version = "2.0.0" |
    .baseline.scope = "user" |
    .baseline.source = "github.com/montebravo/mb-kiro" |
    del(.baseline.version) |
    del(.baseline.installed_at) |
    del(.baseline.last_synced_at)
  ' "${manifest_path}" > "${tmp_manifest}" 2>/dev/null; then
    rm -f "${tmp_manifest}"
    log_error "Falha ao atualizar manifest."
    log_error "Restaurando backup..."
    _migration_rollback
    _MIGRATION_IN_PROGRESS=false
    exit 1
  fi

  mv "${tmp_manifest}" "${manifest_path}"
  log_success "  Manifest atualizado:"
  log_info "    schema_version → 2.0.0"
  log_info "    baseline.scope → user"
  log_info "    baseline.version → removido"

  # ------------------------------------------------------------------
  # Migração concluída com sucesso
  # ------------------------------------------------------------------
  _MIGRATION_IN_PROGRESS=false
  trap - SIGINT SIGTERM

  # ------------------------------------------------------------------
  # 8. Verificar se baseline user-level já foi instalado
  # ------------------------------------------------------------------
  echo ""
  local user_kiro_dir
  user_kiro_dir="$(get_user_kiro_dir)"
  local version_file="${user_kiro_dir}/mb-baseline-version"

  if [[ ! -f "${version_file}" ]]; then
    echo "============================================"
    log_warn "Baseline user-level não detectado."
    log_info "Para completar a migração, execute:"
    log_info ""
    log_info "  ./scripts/bootstrap.sh --scope user"
    log_info ""
    log_info "Isso instalará o baseline em ~/.kiro/ (uma vez por máquina)."
    echo "============================================"
  fi

  # ------------------------------------------------------------------
  # Resumo final
  # ------------------------------------------------------------------
  echo ""
  echo "============================================"
  log_success "Migração para user-scope concluída!"
  echo ""
  log_info "  Backup:  .kiro/.migration-backup/baseline/"
  log_info "  Modelo:  dual-scope (baseline em ~/.kiro/, archetype em .kiro/)"
  echo "============================================"
  echo ""
}

# -----------------------------------------------------------------------------
# Leitura do manifest (fluxo legado)
# -----------------------------------------------------------------------------

MANIFEST_ARCHETYPE=""

read_manifest() {
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ ! -f "${manifest_path}" ]]; then
    log_error "kiro-manifest.json não encontrado em: ${TARGET_DIR}"
    log_error "Execute o bootstrap primeiro: ./scripts/bootstrap.sh --scope workspace --target ${TARGET_DIR} --project-type <tipo>"
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
# Funções de sincronização legada (comportamento original)
# -----------------------------------------------------------------------------

sync_baseline_legacy() {
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

sync_archetype_legacy() {
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

sync_powers_legacy() {
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
        local legacy_steering="${TARGET_DIR}/.kiro/steering/powers/${power}"
        if [[ -d "${legacy_steering}" ]]; then
          rm -rf "${legacy_steering}"
          log_info "    Steering legado removido: .kiro/steering/powers/${power}/"
        fi

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
# Migração de powers legados (comportamento original)
# -----------------------------------------------------------------------------

migrate_powers_legacy() {
  log_info "Iniciando migração de powers para instalação nativa..."
  echo ""

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"
  local backup_base="${TARGET_DIR}/.kiro/.migration-backup"

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

    if [[ "${status}" == "removed" ]]; then
      ((i++)) || true
      continue
    fi

    if [[ "${installation_method}" == "native" ]]; then
      ((i++)) || true
      continue
    fi

    log_info "Processando power: ${power}..."

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

    local migration_ok=true
    local backup_dir="${backup_base}/${power}"

    mkdir -p "${backup_dir}"

    if [[ -d "${legacy_steering}" ]]; then
      cp -R "${legacy_steering}" "${backup_dir}/steering"
      log_info "  Backup criado: .kiro/.migration-backup/${power}/steering/"
    fi

    local mcp_dest="${TARGET_DIR}/.kiro/settings/mcp.json"
    if [[ -f "${mcp_dest}" ]]; then
      cp "${mcp_dest}" "${backup_dir}/mcp.json.bak"
      log_info "  Backup criado: .kiro/.migration-backup/${power}/mcp.json.bak"
    fi

    if ! rm -rf "${legacy_steering}"; then
      log_error "  Erro ao remover steering legado de '${power}'."
      migration_ok=false
    else
      log_success "  Steering legado removido: .kiro/steering/powers/${power}/"
    fi

    if [[ "${migration_ok}" == true ]]; then
      local power_dir="${REPO_ROOT}/powers/${power}"
      if [[ -f "${power_dir}/mcp.json" && -f "${mcp_dest}" ]]; then
        local power_servers
        power_servers=$(jq -r '.mcpServers | keys[]' "${power_dir}/mcp.json" 2>/dev/null)

        if [[ -n "${power_servers}" ]]; then
          local tmp_mcp
          tmp_mcp=$(mktemp)
          local mcp_current="${mcp_dest}"
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

    if [[ "${migration_ok}" == false ]]; then
      log_error "  Falha na migração de '${power}'. Restaurando backup..."

      if [[ -d "${backup_dir}/steering" ]]; then
        mkdir -p "$(dirname "${legacy_steering}")"
        cp -R "${backup_dir}/steering" "${legacy_steering}"
        log_info "  Steering restaurado de backup."
      fi

      if [[ -f "${backup_dir}/mcp.json.bak" ]]; then
        cp "${backup_dir}/mcp.json.bak" "${mcp_dest}"
        log_info "  mcp.json restaurado de backup."
      fi

      failed_powers+=("${power}")
    else
      migrated_powers+=("${power}")
      local powers_steering_dir="${TARGET_DIR}/.kiro/steering/powers"
      if [[ -d "${powers_steering_dir}" ]] && [[ -z "$(ls -A "${powers_steering_dir}" 2>/dev/null)" ]]; then
        rmdir "${powers_steering_dir}" 2>/dev/null || true
      fi
    fi

    echo ""
    ((i++)) || true
  done

  # Resumo da migração de powers
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

# -----------------------------------------------------------------------------
# Atualização da data de sync no manifest (legado)
# -----------------------------------------------------------------------------

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
# Fluxo legado — sincronização baseline + archetype no workspace
# -----------------------------------------------------------------------------

sync_legacy() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Sync — Modo Legado"
  echo "============================================"
  echo ""

  read_manifest

  log_info "Destino:    ${TARGET_DIR}"
  log_info "Componente: ${COMPONENT}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  [[ "${MIGRATE_POWERS}" == true ]] && log_info "Modo migração de powers ativado."
  echo ""

  log_info "Projeto no modelo legado (sem baseline.scope no manifest)."
  log_info "Recomendação: migre para o modelo dual-scope com:"
  log_info "  ./scripts/sync.sh --target ${TARGET_DIR} --migrate-to-user-scope"
  echo ""

  # Se --migrate-powers foi passado, executar migração e sair
  if [[ "${MIGRATE_POWERS}" == true ]]; then
    migrate_powers_legacy
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
      sync_baseline_legacy
      echo ""
      sync_archetype_legacy
      echo ""
      sync_powers_legacy
      ;;
    baseline)  sync_baseline_legacy ;;
    archetype) sync_archetype_legacy ;;
    powers)    sync_powers_legacy ;;
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
    log_info "Execute: ./scripts/doctor.sh --scope workspace --target ${TARGET_DIR}"
  fi
  echo "============================================"
  echo ""
}

# -----------------------------------------------------------------------------
# Entrypoint
# -----------------------------------------------------------------------------

main() {
  parse_args "$@"

  # Caso 1: --migrate-to-user-scope (operação explícita de migração)
  if [[ "${MIGRATE_TO_USER_SCOPE}" == true ]]; then
    migrate_to_user_scope
    return
  fi

  # Caso 2: --scope informado — usar novo modelo
  if [[ -n "${SCOPE}" ]]; then
    case "${SCOPE}" in
      user)      sync_user_scope ;;
      workspace) sync_workspace_scope ;;
    esac
    return
  fi

  # Caso 3: --scope NÃO informado — verificar modelo do projeto
  # Requer --target para identificar o manifest
  if [[ -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --scope ou --target"
    log_error "Uso:"
    log_error "  sync.sh --scope <user|workspace> [opções]"
    log_error "  sync.sh --target <caminho> (modo legado)"
    log_error ""
    log_error "Valores válidos para --scope: user, workspace"
    exit 1
  fi

  # Verificar manifest
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ ! -f "${manifest_path}" ]]; then
    log_error "kiro-manifest.json não encontrado em: ${TARGET_DIR}"
    log_error "Execute o bootstrap primeiro: ./scripts/bootstrap.sh --scope workspace --target ${TARGET_DIR} --project-type <tipo>"
    exit 1
  fi

  # Verificar se é modelo legado (sem baseline.scope)
  if is_legacy_manifest "${manifest_path}"; then
    # Modelo legado: manter comportamento antigo (baseline + archetype no workspace)
    sync_legacy
  else
    # Modelo novo mas sem --scope: exibir erro com valores válidos
    log_error "Argumento obrigatório ausente: --scope"
    log_error "Este projeto utiliza o modelo dual-scope (baseline.scope definido no manifest)."
    log_error "Valores válidos para --scope: user, workspace"
    log_error ""
    log_error "Uso:"
    log_error "  sync.sh --scope user                          (atualiza baseline em ~/.kiro/)"
    log_error "  sync.sh --scope workspace --target <caminho>  (atualiza archetype no projeto)"
    exit 1
  fi
}

main "$@"
