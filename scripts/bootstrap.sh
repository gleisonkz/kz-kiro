#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Bootstrap de Projeto com Padrões Kiro (MonteBravo)
# =============================================================================
# Configura o ambiente Kiro no escopo user (baseline global em ~/.kiro/) ou
# workspace (archetype em <projeto>/.kiro/).
#
# Uso:
#   ./scripts/bootstrap.sh --scope user [--dry-run] [--force]
#   ./scripts/bootstrap.sh --scope workspace --target <caminho> --project-type <tipo> [--powers <lista>] [--dry-run] [--force]
#
# Opções:
#   --scope <user|workspace> Escopo da instalação (obrigatório)
#   --project-type <tipo>    Tipo de projeto (obrigatório para --scope workspace)
#   --target <caminho>       Caminho do diretório do projeto (obrigatório para --scope workspace)
#   --powers <lista>         Lista de powers adicionais separados por vírgula (opcional)
#   --dry-run                Simula a execução sem aplicar mudanças
#   --force                  Sobrescreve arquivos existentes sem perguntar
#   --help                   Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/bootstrap.sh --scope user
#   ./scripts/bootstrap.sh --scope workspace --project-type backend-csharp --target ../meu-projeto
#   ./scripts/bootstrap.sh --scope workspace --project-type frontend-react --target ../frontend --dry-run
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
FILES_COPIED=0
FILES_SKIPPED=0
MCP_SERVERS_MERGED=0

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

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

validate_prerequisites_workspace() {
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
# Parsing de argumentos
# -----------------------------------------------------------------------------

SCOPE=""
PROJECT_TYPE=""
TARGET_DIR=""
EXTRA_POWERS=""
DRY_RUN=false
FORCE=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope)        SCOPE="$2"; shift 2 ;;
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

  # --scope é obrigatório
  if [[ -z "${SCOPE}" ]]; then
    log_error "Argumento obrigatório ausente: --scope"
    log_error "Valores válidos: user, workspace"
    log_error "Uso: bootstrap.sh --scope <user|workspace> [opções]"
    exit 1
  fi

  # Validar valor do scope
  if ! validate_scope "${SCOPE}"; then
    log_error "Valor inválido para --scope: ${SCOPE}"
    log_error "Valores válidos: user, workspace"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Validação de argumentos para --scope workspace
# -----------------------------------------------------------------------------

validate_workspace_args() {
  # --target é obrigatório para workspace
  if [[ -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    log_error "--target deve apontar para um diretório existente ao usar --scope workspace."
    exit 1
  fi

  # Validar que --target existe e é diretório
  if ! validate_target "${TARGET_DIR}"; then
    log_error "Target inválido: '${TARGET_DIR}' não existe ou não é um diretório."
    log_error "--target deve apontar para um diretório existente."
    exit 1
  fi

  # Resolver path absoluto
  TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)"

  # --project-type é obrigatório para workspace
  if [[ -z "${PROJECT_TYPE}" ]]; then
    log_error "Argumento obrigatório ausente: --project-type"
    log_error "Tipos disponíveis: $(list_available_archetypes)"
    exit 1
  fi

  # Validar que o archetype existe
  if [[ ! -d "${REPO_ROOT}/archetypes/${PROJECT_TYPE}" ]]; then
    log_error "Tipo de projeto inválido: ${PROJECT_TYPE}"
    log_error "Tipos disponíveis: $(list_available_archetypes)"
    exit 1
  fi
}

# Lista archetypes disponíveis no diretório archetypes/
list_available_archetypes() {
  local types=()
  for dir in "${REPO_ROOT}"/archetypes/*/; do
    [[ ! -d "${dir}" ]] && continue
    local name
    name="$(basename "${dir}")"
    # Ignorar diretórios genéricos que não são archetypes completos
    if [[ -f "${dir}/VERSION" || -d "${dir}/steering" ]]; then
      types+=("${name}")
    fi
  done
  echo "${types[*]}"
}

# -----------------------------------------------------------------------------
# Verificação de workspace existente (--scope workspace)
# -----------------------------------------------------------------------------

check_existing_workspace() {
  local kiro_dir="${TARGET_DIR}/.kiro"

  if [[ -d "${kiro_dir}" && "${FORCE}" == false ]]; then
    log_error "O workspace já foi inicializado: ${kiro_dir}"
    log_error "Use --force para sobrescrever ou execute sync.sh --scope workspace --target ${TARGET_DIR} para atualizar."
    exit 1
  fi

  # Com --force e .kiro/ existente: preparar para sobrescrita preservando specs/
  if [[ -d "${kiro_dir}" && "${FORCE}" == true ]]; then
    log_warn "Modo --force: sobrescrevendo .kiro/ existente (preservando specs/)..."
    if [[ "${DRY_RUN}" == false ]]; then
      # Preservar specs/ movendo para temp
      local specs_backup=""
      if [[ -d "${kiro_dir}/specs" ]]; then
        specs_backup="$(mktemp -d)"
        cp -R "${kiro_dir}/specs" "${specs_backup}/specs"
      fi

      # Remover conteúdo do .kiro/ (exceto specs/)
      find "${kiro_dir}" -mindepth 1 -maxdepth 1 -not -name "specs" -exec rm -rf {} +

      # Restaurar specs/ se havia
      if [[ -n "${specs_backup}" && -d "${specs_backup}/specs" ]]; then
        # specs/ já ficou intacto no find acima (excluído via -not -name "specs")
        rm -rf "${specs_backup}"
      fi
    fi
  fi
}

# -----------------------------------------------------------------------------
# Funções de bootstrap — Scope Workspace
# -----------------------------------------------------------------------------

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
    copy_files "${archetype_dir}/hooks" "${TARGET_DIR}/.kiro/hooks" "*.kiro.hook"
  fi

  # Agents
  if [[ -d "${archetype_dir}/agents" ]]; then
    log_info "  Copiando agents..."
    copy_files "${archetype_dir}/agents" "${TARGET_DIR}/.kiro/agents" "*.md"
    copy_files "${archetype_dir}/agents" "${TARGET_DIR}/.kiro/agents" "*.json"
  fi

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Archetype ${PROJECT_TYPE} aplicado."
  fi
}

generate_mcp_workspace() {
  log_info "Gerando MCP config (apenas archetype)..."

  local mcp_archetype="${REPO_ROOT}/archetypes/${PROJECT_TYPE}/mcp/mcp.json"
  local mcp_dest="${TARGET_DIR}/.kiro/settings/mcp.json"

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Geraria mcp.json em ${mcp_dest} (apenas servidores do archetype)"
    return
  fi

  mkdir -p "${TARGET_DIR}/.kiro/settings"

  if [[ -f "${mcp_archetype}" ]]; then
    cp "${mcp_archetype}" "${mcp_dest}"
    log_success "  mcp.json gerado (servidores do archetype)"
    ((FILES_COPIED++)) || true
  else
    # Criar mcp.json vazio se archetype não define MCP
    echo '{ "mcpServers": {} }' > "${mcp_dest}"
    log_success "  mcp.json gerado (vazio — archetype sem MCP)"
    ((FILES_COPIED++)) || true
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

  log_info "Registrando powers para instalação nativa..."

  local powers_json="["
  local first=true
  local installed_powers=()

  for power in "${default_powers[@]}"; do
    local power_dir="${REPO_ROOT}/powers/${power}"

    # Filtro: ignorar powers em _drafts/ silenciosamente
    if [[ -d "${REPO_ROOT}/powers/_drafts/${power}" ]]; then
      continue
    fi

    # Power não encontrado
    if [[ ! -d "${power_dir}" ]]; then
      log_warn "Power não encontrado: ${power} (pulando)"
      continue
    fi

    # Validar POWER.md existe
    if [[ ! -f "${power_dir}/POWER.md" ]]; then
      log_warn "Power ${power}: POWER.md ausente (pulando)"
      continue
    fi

    # Validar frontmatter com name e keywords
    local has_frontmatter=false
    local has_name=false
    local has_keywords=false

    if head -1 "${power_dir}/POWER.md" | grep -q '^---$'; then
      has_frontmatter=true
      local frontmatter
      frontmatter=$(sed -n '2,/^---$/p' "${power_dir}/POWER.md" | sed '$d')

      if echo "${frontmatter}" | grep -q '^name:'; then
        has_name=true
      fi
      if echo "${frontmatter}" | grep -q '^keywords:'; then
        has_keywords=true
      fi
    fi

    if [[ "${has_frontmatter}" == false || "${has_name}" == false || "${has_keywords}" == false ]]; then
      log_warn "Power ${power}: POWER.md sem frontmatter válido (name e keywords obrigatórios) — pulando"
      continue
    fi

    # Ler versão do arquivo VERSION (fallback: "0.0.0")
    local version="0.0.0"
    if [[ -f "${power_dir}/VERSION" ]]; then
      version=$(tr -d '[:space:]' < "${power_dir}/VERSION")
    fi

    if [[ "${DRY_RUN}" == true ]]; then
      log_warn "[DRY-RUN] Registraria power: ${power} (v${version})"
      continue
    fi

    log_success "  Power registrado: ${power} (v${version})"
    installed_powers+=("${power}")

    if [[ "${first}" == true ]]; then
      first=false
    else
      powers_json+=","
    fi
    powers_json+="\n    { \"name\": \"${power}\", \"version\": \"${version}\", \"source_path\": \"powers/${power}\", \"installation_method\": \"native\", \"installed_at\": \"${TIMESTAMP}\" }"
  done

  powers_json+="\n  ]"
  POWERS_JSON="${powers_json}"

  if [[ "${DRY_RUN}" == false ]]; then
    log_success "Powers registrados no manifest."
  fi

  INSTALLED_POWERS=("${installed_powers[@]+"${installed_powers[@]}"}")
}

generate_manifest_v2() {
  log_info "Gerando kiro-manifest.json (v2)..."

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "[DRY-RUN] Geraria manifest v2 em: ${manifest_path}"
    return
  fi

  local project_name
  project_name=$(basename "${TARGET_DIR}")

  # Ler versão do archetype
  local archetype_version="0.0.0"
  local archetype_version_file="${REPO_ROOT}/archetypes/${PROJECT_TYPE}/VERSION"
  if [[ -f "${archetype_version_file}" ]]; then
    archetype_version=$(tr -d '[:space:]' < "${archetype_version_file}")
  fi

  cat > "${manifest_path}" <<EOF
{
  "_generated_by": "bootstrap.sh --scope workspace",
  "_generated_at": "${TIMESTAMP}",
  "schema_version": "2.0.0",
  "project": {
    "name": "${project_name}",
    "repository": "MonteBravo/${project_name}"
  },
  "baseline": {
    "scope": "user",
    "source": "github.com/montebravo/mb-kiro"
  },
  "archetype": {
    "name": "${PROJECT_TYPE}",
    "version": "${archetype_version}",
    "installed_at": "${TIMESTAMP}",
    "last_synced_at": "${TIMESTAMP}"
  },
  "powers": $(echo -e "${POWERS_JSON}"),
  "exceptions": []
}
EOF

  # Validar JSON se jq estiver disponível
  if command -v jq &>/dev/null; then
    if jq '.' "${manifest_path}" > /dev/null 2>&1; then
      log_success "kiro-manifest.json (v2) gerado e validado."
    else
      log_warn "kiro-manifest.json gerado mas com possível erro de formatação."
    fi
  else
    log_success "kiro-manifest.json (v2) gerado."
  fi
}

# -----------------------------------------------------------------------------
# Fluxo principal — Scope Workspace
# -----------------------------------------------------------------------------

bootstrap_workspace() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Bootstrap — Scope Workspace"
  echo "============================================"
  echo ""

  validate_workspace_args
  validate_prerequisites_workspace
  check_existing_workspace

  log_info "Projeto tipo:  ${PROJECT_TYPE}"
  log_info "Destino:       ${TARGET_DIR}"
  log_info "Powers extras: ${EXTRA_POWERS:-nenhum}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  [[ "${FORCE}" == true ]] && log_warn "Modo --force ativado — arquivos existentes serão sobrescritos."
  echo ""

  POWERS_JSON="[]"
  INSTALLED_POWERS=()

  apply_archetype
  echo ""
  generate_mcp_workspace
  echo ""
  install_powers
  echo ""
  generate_manifest_v2

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
    log_info "  1. Instale o baseline global: ./scripts/bootstrap.sh --scope user"
    log_info "  2. Abra o projeto no Kiro"
    log_info "  3. Instale os powers via painel de Powers usando \"Import power from a folder\":"

    if [[ ${#INSTALLED_POWERS[@]} -gt 0 ]]; then
      for power in "${INSTALLED_POWERS[@]}"; do
        log_info "     → ${REPO_ROOT}/powers/${power}/"
      done
    fi

    log_info "  4. Execute o doctor para validar: ./scripts/doctor.sh --scope workspace --target ${TARGET_DIR}"
  fi
  echo "============================================"
  echo ""
}

# -----------------------------------------------------------------------------
# Fluxo principal — Scope User
# -----------------------------------------------------------------------------

bootstrap_user() {
  echo ""
  echo "============================================"
  echo "  mb-kiro Bootstrap — Scope User"
  echo "============================================"
  echo ""

  # Em CI, skip com WARNING e exit 0
  if is_ci_environment; then
    log_warn "Ambiente CI detectado. Instalação user-level é desnecessária em CI."
    log_warn "Encerrando sem modificar ~/.kiro/."
    exit 0
  fi

  # Validar VERSION
  local version_file="${REPO_ROOT}/baselines/global/VERSION"
  if [[ ! -f "${version_file}" ]]; then
    log_error "Arquivo VERSION não encontrado: ${version_file}"
    log_error "O arquivo baselines/global/VERSION é obrigatório e deve conter versão semântica (MAJOR.MINOR.PATCH)."
    exit 1
  fi

  local baseline_version
  baseline_version="$(tr -d '[:space:]' < "${version_file}")"

  if ! validate_semver "${baseline_version}"; then
    log_error "Versão inválida em ${version_file}: '${baseline_version}'"
    log_error "O arquivo baselines/global/VERSION deve conter versão semântica válida (MAJOR.MINOR.PATCH)."
    exit 1
  fi

  local user_kiro_dir
  user_kiro_dir="$(get_user_kiro_dir)"

  log_info "Baseline versão: ${baseline_version}"
  log_info "Destino:         ${user_kiro_dir}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  [[ "${FORCE}" == true ]] && log_warn "Modo --force ativado — arquivos existentes serão sobrescritos."
  echo ""

  # Criar estrutura de diretórios se necessário
  if [[ ! -d "${user_kiro_dir}" ]]; then
    if [[ "${DRY_RUN}" == true ]]; then
      log_info "[DRY-RUN] Criaria diretórios: ${user_kiro_dir}/{steering,hooks,settings}"
    else
      mkdir -p "${user_kiro_dir}/steering"
      mkdir -p "${user_kiro_dir}/hooks"
      mkdir -p "${user_kiro_dir}/settings"
      log_success "Estrutura de diretórios criada: ${user_kiro_dir}/"
    fi
  else
    # Garantir subdiretórios existem
    if [[ "${DRY_RUN}" == false ]]; then
      mkdir -p "${user_kiro_dir}/steering"
      mkdir -p "${user_kiro_dir}/hooks"
      mkdir -p "${user_kiro_dir}/settings"
    fi
  fi

  # Copiar steering files com prefixo mb--
  local steering_dir="${REPO_ROOT}/baselines/global/steering"
  log_info "Copiando steering files..."
  if [[ -d "${steering_dir}" ]]; then
    for file in "${steering_dir}"/*.md; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"

      # Pular README.md
      [[ "${filename}" == "README.md" ]] && continue

      local dest_file="${user_kiro_dir}/steering/$(add_prefix "${filename}")"

      if [[ "${DRY_RUN}" == true ]]; then
        log_info "  [DRY-RUN] Copiaria: ${filename} → $(add_prefix "${filename}")"
        ((FILES_COPIED++)) || true
        continue
      fi

      if [[ -f "${dest_file}" && "${FORCE}" == false ]]; then
        log_warn "Arquivo já existe (pulando): $(add_prefix "${filename}"). Use --force para sobrescrever."
        ((FILES_SKIPPED++)) || true
      else
        cp "${file}" "${dest_file}"
        log_success "  ${filename} → $(add_prefix "${filename}")"
        ((FILES_COPIED++)) || true
      fi
    done
  fi

  # Copiar hooks com prefixo mb--
  local hooks_dir="${REPO_ROOT}/baselines/global/hooks"
  echo ""
  log_info "Copiando hooks..."
  if [[ -d "${hooks_dir}" ]]; then
    for file in "${hooks_dir}"/*.kiro.hook; do
      [[ ! -f "${file}" ]] && continue
      local filename
      filename="$(basename "${file}")"

      local dest_file="${user_kiro_dir}/hooks/$(add_prefix "${filename}")"

      if [[ "${DRY_RUN}" == true ]]; then
        log_info "  [DRY-RUN] Copiaria: ${filename} → $(add_prefix "${filename}")"
        ((FILES_COPIED++)) || true
        continue
      fi

      if [[ -f "${dest_file}" && "${FORCE}" == false ]]; then
        log_warn "Arquivo já existe (pulando): $(add_prefix "${filename}"). Use --force para sobrescrever."
        ((FILES_SKIPPED++)) || true
      else
        cp "${file}" "${dest_file}"
        log_success "  ${filename} → $(add_prefix "${filename}")"
        ((FILES_COPIED++)) || true
      fi
    done
  fi

  # Mergear MCP servers
  local baseline_mcp="${REPO_ROOT}/baselines/global/mcp/mcp.json"
  local user_mcp="${user_kiro_dir}/settings/mcp.json"
  echo ""
  log_info "Mergeando servidores MCP..."

  if [[ "${DRY_RUN}" == true ]]; then
    if [[ -f "${baseline_mcp}" ]]; then
      if command -v jq &>/dev/null; then
        local server_keys
        server_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"
        for key in ${server_keys}; do
          log_info "  [DRY-RUN] Mergearia servidor: ${key}"
          ((MCP_SERVERS_MERGED++)) || true
        done
      else
        log_info "  [DRY-RUN] Mergearia servidores de ${baseline_mcp}"
        ((MCP_SERVERS_MERGED++)) || true
      fi
    fi
  else
    if [[ -f "${baseline_mcp}" ]]; then
      # Emitir warnings para servidores que serão sobrescritos
      if [[ -f "${user_mcp}" ]] && command -v jq &>/dev/null; then
        local baseline_keys
        baseline_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"
        for key in ${baseline_keys}; do
          if jq -e ".mcpServers[\"${key}\"]" "${user_mcp}" &>/dev/null; then
            log_warn "Servidor MCP '${key}' já existe — será atualizado com versão do baseline."
          fi
          ((MCP_SERVERS_MERGED++)) || true
        done
      else
        # Contar servidores do baseline para o resumo
        if command -v jq &>/dev/null; then
          local count
          count="$(jq -r '.mcpServers | keys | length' "${baseline_mcp}" 2>/dev/null)"
          MCP_SERVERS_MERGED="${count}"
        else
          ((MCP_SERVERS_MERGED++)) || true
        fi
      fi

      merge_mcp_servers "${baseline_mcp}" "${user_mcp}"
      log_success "  Servidores MCP mergeados em ${user_mcp}"
    else
      log_warn "Arquivo MCP baseline não encontrado: ${baseline_mcp}"
    fi
  fi

  # Criar mb-baseline-version
  echo ""
  log_info "Registrando versão do baseline..."
  if [[ "${DRY_RUN}" == true ]]; then
    log_info "  [DRY-RUN] Criaria: ${user_kiro_dir}/mb-baseline-version com conteúdo '${baseline_version}'"
  else
    printf '%s' "${baseline_version}" > "${user_kiro_dir}/mb-baseline-version"
    log_success "  ${user_kiro_dir}/mb-baseline-version → ${baseline_version}"
  fi

  # Resumo
  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_warn "Bootstrap simulado (dry-run) concluído."
    echo ""
    log_info "  Arquivos que seriam copiados: ${FILES_COPIED}"
    log_info "  Servidores MCP que seriam mergeados: ${MCP_SERVERS_MERGED}"
  else
    log_success "Bootstrap user-scope concluído!"
    echo ""
    log_info "  Arquivos copiados:       ${FILES_COPIED}"
    [[ ${FILES_SKIPPED} -gt 0 ]] && log_warn "  Arquivos pulados:        ${FILES_SKIPPED} (já existiam, use --force para sobrescrever)"
    log_info "  Servidores MCP mergeados: ${MCP_SERVERS_MERGED}"
  fi
  echo "============================================"
  echo ""
}

# -----------------------------------------------------------------------------
# Entrypoint
# -----------------------------------------------------------------------------

main() {
  parse_args "$@"

  case "${SCOPE}" in
    workspace) bootstrap_workspace ;;
    user)      bootstrap_user ;;
  esac
}

main "$@"
