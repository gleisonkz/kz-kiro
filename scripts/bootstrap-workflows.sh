#!/usr/bin/env bash
# =============================================================================
# bootstrap-workflows.sh — Bootstrap de Workflows de Code Review
# =============================================================================
# Aplica workflows de code review, agentes CLI, review-rules.yml e CODEOWNERS
# de um archetype ao projeto destino, com políticas de merge inteligente.
#
# Uso:
#   ./scripts/bootstrap-workflows.sh [opções]
#
# Opções:
#   --project-type <nome>  Tipo de projeto (backend-csharp, bff-fastify, frontend-react, api-nest, frontend-angular)
#   --target <caminho>     Caminho para o diretório do projeto destino
#   --force                Sobrescreve arquivos existentes em .github/workflows/
#   --dry-run              Mostra o que seria feito sem executar
#   --help                 Exibe esta mensagem de ajuda
#
# Exemplos:
#   ./scripts/bootstrap-workflows.sh --project-type backend-csharp --target ../meu-projeto
#   ./scripts/bootstrap-workflows.sh --project-type bff-fastify --target ../bff --dry-run
#   ./scripts/bootstrap-workflows.sh --project-type frontend-react --target ../web --force
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configurações globais
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARCHETYPES_DIR="${REPO_ROOT}/archetypes"
WORKFLOWS_SCRIPTS_DIR="${REPO_ROOT}/workflows/scripts"

# Archetypes válidos
VALID_ARCHETYPES=("backend-csharp" "bff-fastify" "frontend-react" "api-nest" "frontend-angular")

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
FILES_COPIED=0
FILES_SKIPPED=0
ACTIONS_PERFORMED=0

# Argumentos
ARCHETYPE=""
TARGET_DIR=""
FORCE=false
DRY_RUN=false

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[SKIP]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# -----------------------------------------------------------------------------
# show_help — Exibe mensagem de uso
# -----------------------------------------------------------------------------
show_help() {
  cat <<'EOF'
bootstrap-workflows.sh — Bootstrap de Workflows de Code Review

Aplica workflows de code review, agentes CLI, review-rules.yml e CODEOWNERS
de um archetype ao projeto destino, com políticas de merge inteligente.

Uso:
  ./scripts/bootstrap-workflows.sh [opções]

Opções:
  --project-type <nome>  Tipo de projeto (backend-csharp, bff-fastify, frontend-react, api-nest, frontend-angular)
  --target <caminho>     Caminho para o diretório do projeto destino
  --force                Sobrescreve arquivos existentes em .github/workflows/
  --dry-run              Mostra o que seria feito sem executar
  --help                 Exibe esta mensagem de ajuda

Exemplos:
  ./scripts/bootstrap-workflows.sh --project-type backend-csharp --target ../meu-projeto
  ./scripts/bootstrap-workflows.sh --project-type bff-fastify --target ../bff --dry-run
  ./scripts/bootstrap-workflows.sh --project-type frontend-react --target ../web --force
EOF
  exit 0
}

# -----------------------------------------------------------------------------
# validate_archetype — Verifica que o archetype existe e tem workflows/
# -----------------------------------------------------------------------------
validate_archetype() {
  local archetype_dir="${ARCHETYPES_DIR}/${ARCHETYPE}"

  # Verificar se é um archetype válido
  local valid=false
  for a in "${VALID_ARCHETYPES[@]}"; do
    [[ "${ARCHETYPE}" == "${a}" ]] && valid=true && break
  done

  if [[ "${valid}" == false ]]; then
    log_error "Archetype inválido: '${ARCHETYPE}'"
    log_error "Archetypes disponíveis: ${VALID_ARCHETYPES[*]}"
    exit 1
  fi

  # Verificar se diretório do archetype existe
  if [[ ! -d "${archetype_dir}" ]]; then
    log_error "Diretório do archetype não encontrado: ${archetype_dir}"
    log_error "Archetypes disponíveis: ${VALID_ARCHETYPES[*]}"
    exit 1
  fi

  # Verificar se tem diretório workflows/ (no archetype ou compartilhado)
  if [[ ! -d "${archetype_dir}/workflows" && ! -d "${REPO_ROOT}/workflows" ]]; then
    log_error "Nenhum diretório workflows/ encontrado (nem em archetype, nem compartilhado)"
    exit 1
  fi

  log_success "Archetype '${ARCHETYPE}' validado."
}

# -----------------------------------------------------------------------------
# copy_workflows — Copia workflows/ → .github/workflows/
# Fontes: templates compartilhados em ${REPO_ROOT}/workflows/ +
#          workflows específicos do archetype em ${ARCHETYPES_DIR}/${ARCHETYPE}/workflows/
# -----------------------------------------------------------------------------
copy_workflows() {
  local shared_src="${REPO_ROOT}/workflows"
  local archetype_src="${ARCHETYPES_DIR}/${ARCHETYPE}/workflows"
  local dest_dir="${TARGET_DIR}/.github/workflows"

  log_info "Copiando workflows para ${dest_dir}..."

  # Coletar YAMLs de ambas as fontes (shared primeiro, archetype depois)
  local yaml_files=()

  # 1. Templates compartilhados (repo root workflows/)
  if [[ -d "${shared_src}" ]]; then
    while IFS= read -r -d '' file; do
      yaml_files+=("${file}")
    done < <(find "${shared_src}" -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null)
  fi

  # 2. Workflows específicos do archetype (se existirem)
  if [[ -d "${archetype_src}" ]]; then
    while IFS= read -r -d '' file; do
      yaml_files+=("${file}")
    done < <(find "${archetype_src}" -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null)
  fi

  if [[ ${#yaml_files[@]} -eq 0 ]]; then
    log_warn "Nenhum arquivo de workflow (.yml/.yaml) encontrado"
    return
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    for file in "${yaml_files[@]}"; do
      local filename
      filename=$(basename "${file}")
      if [[ -f "${dest_dir}/${filename}" && "${FORCE}" == false ]]; then
        log_warn "[DRY-RUN] Pularia (já existe): ${dest_dir}/${filename}"
      elif [[ -f "${dest_dir}/${filename}" && "${FORCE}" == true ]]; then
        log_info "[DRY-RUN] Sobrescreveria: ${dest_dir}/${filename}"
      else
        log_info "[DRY-RUN] Copiaria: ${file} → ${dest_dir}/${filename}"
      fi
    done
    return
  fi

  mkdir -p "${dest_dir}"

  for file in "${yaml_files[@]}"; do
    local filename
    filename=$(basename "${file}")
    local dest_file="${dest_dir}/${filename}"

    if [[ -f "${dest_file}" && "${FORCE}" == false ]]; then
      log_warn "Workflow já existe (pulando): ${filename}"
      ((FILES_SKIPPED++)) || true
    else
      cp "${file}" "${dest_file}"
      log_success "Workflow copiado: ${filename}"
      ((FILES_COPIED++)) || true
      ((ACTIONS_PERFORMED++)) || true
    fi
  done
}

# -----------------------------------------------------------------------------
# copy_agents — Copia cli-*.json → .kiro/agents/ e review-config → .kiro/settings/
# -----------------------------------------------------------------------------
copy_agents() {
  local src_dir="${ARCHETYPES_DIR}/${ARCHETYPE}/agents"
  local dest_dir="${TARGET_DIR}/.kiro/agents"
  local settings_dir="${TARGET_DIR}/.kiro/settings"

  log_info "Copiando agentes CLI para ${dest_dir}..."

  if [[ ! -d "${src_dir}" ]]; then
    log_warn "Archetype '${ARCHETYPE}' não possui diretório agents/ (pulando)"
    return
  fi

  # Buscar cli-*.json (agentes) separadamente de kiro-review-config.json (config de review)
  local json_files=()
  while IFS= read -r -d '' file; do
    json_files+=("${file}")
  done < <(find "${src_dir}" -maxdepth 1 -type f -name "cli-*.json" -print0 2>/dev/null | sort -z)

  # Copiar kiro-review-config.json para .kiro/settings/review-config.json
  local review_config="${src_dir}/kiro-review-config.json"
  if [[ -f "${review_config}" ]]; then
    mkdir -p "${settings_dir}"
    local dest_review="${settings_dir}/review-config.json"
    if [[ "${DRY_RUN}" == true ]]; then
      if [[ -f "${dest_review}" ]]; then
        if ! diff -q "${review_config}" "${dest_review}" > /dev/null 2>&1; then
          log_info "[DRY-RUN] Atualizaria review-config: review-config.json"
        else
          log_warn "[DRY-RUN] Pularia review-config (conteúdo idêntico)"
        fi
      else
        log_info "[DRY-RUN] Copiaria: kiro-review-config.json → ${settings_dir}/review-config.json"
      fi
    else
      if [[ -f "${dest_review}" ]]; then
        if ! diff -q "${review_config}" "${dest_review}" > /dev/null 2>&1; then
          cp "${review_config}" "${dest_review}"
          log_success "Review config atualizado: review-config.json"
          ((ACTIONS_PERFORMED++)) || true
        fi
      else
        cp "${review_config}" "${dest_review}"
        log_success "Review config copiado: review-config.json"
        ((FILES_COPIED++)) || true
        ((ACTIONS_PERFORMED++)) || true
      fi
    fi
    # Remover versão antiga em .kiro/agents/ se existir (migração)
    if [[ -f "${dest_dir}/kiro-review-config.json" ]]; then
      rm -f "${dest_dir}/kiro-review-config.json"
      log_info "Removido kiro-review-config.json de .kiro/agents/ (migrado para .kiro/settings/)"
    fi
  fi

  if [[ ${#json_files[@]} -eq 0 ]]; then
    log_warn "Nenhum arquivo cli-*.json encontrado em ${src_dir}"
    return
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    for file in "${json_files[@]}"; do
      local filename
      filename=$(basename "${file}")
      if [[ -f "${dest_dir}/${filename}" ]]; then
        if ! diff -q "${file}" "${dest_dir}/${filename}" > /dev/null 2>&1; then
          log_info "[DRY-RUN] Atualizaria (conteúdo difere): ${filename}"
        else
          log_warn "[DRY-RUN] Pularia (conteúdo idêntico): ${filename}"
        fi
      else
        log_info "[DRY-RUN] Copiaria: ${filename} → ${dest_dir}/"
      fi
    done
    return
  fi

  mkdir -p "${dest_dir}"

  local agents_copied=0
  local agents_updated=0
  local agents_skipped=0

  for file in "${json_files[@]}"; do
    local filename
    filename=$(basename "${file}")
    local dest_file="${dest_dir}/${filename}"

    if [[ -f "${dest_file}" ]]; then
      # Sobrescrever apenas se conteúdo difere
      if ! diff -q "${file}" "${dest_file}" > /dev/null 2>&1; then
        cp "${file}" "${dest_file}"
        log_success "Agente atualizado (conteúdo difere): ${filename}"
        ((agents_updated++)) || true
        ((ACTIONS_PERFORMED++)) || true
      else
        ((agents_skipped++)) || true
      fi
    else
      cp "${file}" "${dest_file}"
      log_success "Agente copiado: ${filename}"
      ((agents_copied++)) || true
      ((FILES_COPIED++)) || true
      ((ACTIONS_PERFORMED++)) || true
    fi
  done

  # Resumo de agentes
  [[ ${agents_copied} -gt 0 ]] && log_info "  Agentes novos copiados: ${agents_copied}"
  [[ ${agents_updated} -gt 0 ]] && log_info "  Agentes atualizados: ${agents_updated}"
  [[ ${agents_skipped} -gt 0 ]] && log_info "  Agentes inalterados: ${agents_skipped}"

  # Contar agentes customizados preservados
  local custom_count=0
  for dest_file in "${dest_dir}"/cli-*.json; do
    [[ -f "${dest_file}" ]] || continue
    local dest_filename
    dest_filename=$(basename "${dest_file}")
    if [[ ! -f "${src_dir}/${dest_filename}" ]]; then
      ((custom_count++)) || true
    fi
  done
  [[ ${custom_count} -gt 0 ]] && log_info "  Agentes customizados preservados: ${custom_count}"
}

# -----------------------------------------------------------------------------
# merge_review_rules — Gera/merge review-rules.yml usando módulo TypeScript
# -----------------------------------------------------------------------------
merge_review_rules() {
  local archetype_rules="${ARCHETYPES_DIR}/${ARCHETYPE}/review-rules.yml"
  local dest_rules="${TARGET_DIR}/review-rules.yml"

  log_info "Processando review-rules.yml..."

  if [[ ! -f "${archetype_rules}" ]]; then
    log_warn "Archetype '${ARCHETYPE}' não possui review-rules.yml (pulando)"
    return
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    if [[ -f "${dest_rules}" ]]; then
      log_info "[DRY-RUN] Faria merge de review-rules.yml (preservando existentes, adicionando faltantes)"
    else
      log_info "[DRY-RUN] Copiaria review-rules.yml do archetype para ${dest_rules}"
    fi
    return
  fi

  if [[ -f "${dest_rules}" ]]; then
    # Merge usando módulo TypeScript via tsx
    if [[ -x "${WORKFLOWS_SCRIPTS_DIR}/node_modules/.bin/tsx" ]]; then
      if "${WORKFLOWS_SCRIPTS_DIR}/node_modules/.bin/tsx" \
        "${WORKFLOWS_SCRIPTS_DIR}/src/cli-merge-review-rules.ts" \
        "${archetype_rules}" "${dest_rules}" 2>/dev/null; then
        log_success "review-rules.yml mergeado (regras existentes preservadas, faltantes adicionadas)"
        ((ACTIONS_PERFORMED++)) || true
      else
        log_error "Falha ao executar merge de review-rules.yml"
        log_error "Arquivo original preservado: ${dest_rules}"
        exit 1
      fi
    else
      # Fallback: copiar sem merge se módulo TypeScript não disponível
      log_warn "Módulo TypeScript não disponível (node_modules ausente). Copiando sem merge."
      cp "${archetype_rules}" "${dest_rules}"
      log_success "review-rules.yml copiado do archetype"
      ((FILES_COPIED++)) || true
      ((ACTIONS_PERFORMED++)) || true
    fi
  else
    # Não existe destino: copiar direto
    cp "${archetype_rules}" "${dest_rules}"
    log_success "review-rules.yml copiado do archetype"
    ((FILES_COPIED++)) || true
    ((ACTIONS_PERFORMED++)) || true
  fi
}

# -----------------------------------------------------------------------------
# merge_codeowners — Copia/merge CODEOWNERS para .github/
# -----------------------------------------------------------------------------
merge_codeowners() {
  local archetype_codeowners="${ARCHETYPES_DIR}/${ARCHETYPE}/workflows/CODEOWNERS"
  local dest_dir="${TARGET_DIR}/.github"
  local dest_codeowners="${dest_dir}/CODEOWNERS"

  log_info "Processando CODEOWNERS..."

  if [[ ! -f "${archetype_codeowners}" ]]; then
    log_warn "Archetype '${ARCHETYPE}' não possui workflows/CODEOWNERS (pulando)"
    return
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    if [[ -f "${dest_codeowners}" ]]; then
      log_info "[DRY-RUN] Faria merge de CODEOWNERS (preservando existentes, adicionando novos patterns)"
    else
      log_info "[DRY-RUN] Copiaria CODEOWNERS para ${dest_codeowners}"
    fi
    return
  fi

  mkdir -p "${dest_dir}"

  if [[ -f "${dest_codeowners}" ]]; then
    # Merge usando módulo TypeScript via tsx
    if [[ -x "${WORKFLOWS_SCRIPTS_DIR}/node_modules/.bin/tsx" ]]; then
      if "${WORKFLOWS_SCRIPTS_DIR}/node_modules/.bin/tsx" \
        "${WORKFLOWS_SCRIPTS_DIR}/src/cli-merge-codeowners.ts" \
        "${archetype_codeowners}" "${dest_codeowners}" 2>/dev/null; then
        log_success "CODEOWNERS mergeado (entradas existentes preservadas, novos patterns adicionados)"
        ((ACTIONS_PERFORMED++)) || true
      else
        log_error "Falha ao executar merge de CODEOWNERS"
        log_error "Arquivo original preservado: ${dest_codeowners}"
        exit 1
      fi
    else
      # Fallback: copiar sem merge
      log_warn "Módulo TypeScript não disponível (node_modules ausente). Copiando sem merge."
      cp "${archetype_codeowners}" "${dest_codeowners}"
      log_success "CODEOWNERS copiado do archetype"
      ((FILES_COPIED++)) || true
      ((ACTIONS_PERFORMED++)) || true
    fi
  else
    # Não existe: copiar direto
    cp "${archetype_codeowners}" "${dest_codeowners}"
    log_success "CODEOWNERS copiado do archetype"
    ((FILES_COPIED++)) || true
    ((ACTIONS_PERFORMED++)) || true
  fi
}

# -----------------------------------------------------------------------------
# substitute_placeholders — Substitui {{ archetype_name }} no CODEOWNERS
# -----------------------------------------------------------------------------
substitute_placeholders() {
  local dest_codeowners="${TARGET_DIR}/.github/CODEOWNERS"

  if [[ ! -f "${dest_codeowners}" ]]; then
    return
  fi

  log_info "Processando placeholders em CODEOWNERS..."

  if [[ "${DRY_RUN}" == true ]]; then
    if grep -qE '\{\{\s*archetype_name\s*\}\}' "${dest_codeowners}" 2>/dev/null; then
      log_info "[DRY-RUN] Substituiria {{ archetype_name }} → ${ARCHETYPE}"
    fi
    # Listar outros placeholders que o usuário precisa preencher
    local other_placeholders
    other_placeholders=$(grep -oE '\{\{\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\}\}' "${dest_codeowners}" 2>/dev/null \
      | grep -v 'archetype_name' | sort -u || true)
    if [[ -n "${other_placeholders}" ]]; then
      log_info "[DRY-RUN] Placeholders restantes (preenchimento manual):"
      echo "${other_placeholders}" | while read -r placeholder; do
        log_warn "[DRY-RUN]   ${placeholder}"
      done
    fi
    return
  fi

  # Substituir {{ archetype_name }} pelo nome do archetype
  if grep -qE '\{\{\s*archetype_name\s*\}\}' "${dest_codeowners}" 2>/dev/null; then
    sed -i.bak "s|{{[[:space:]]*archetype_name[[:space:]]*}}|${ARCHETYPE}|g" "${dest_codeowners}"
    rm -f "${dest_codeowners}.bak"
    log_success "Placeholder substituído: {{ archetype_name }} → ${ARCHETYPE}"
    ((ACTIONS_PERFORMED++)) || true
  fi

  # Listar outros placeholders para o usuário preencher manualmente
  local remaining_placeholders
  remaining_placeholders=$(grep -oE '\{\{\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\}\}' "${dest_codeowners}" 2>/dev/null | sort -u || true)

  if [[ -n "${remaining_placeholders}" ]]; then
    log_warn "CODEOWNERS contém placeholders para preenchimento manual:"
    echo "${remaining_placeholders}" | while read -r placeholder; do
      log_warn "  ${placeholder} — edite .github/CODEOWNERS com os times do projeto"
    done
  fi
}

# -----------------------------------------------------------------------------
# parse_args — Parsing de argumentos
# -----------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-type|--archetype)
        if [[ $# -lt 2 ]]; then
          log_error "Argumento $1 requer um valor."
          exit 1
        fi
        ARCHETYPE="$2"
        shift 2
        ;;
      --target)
        if [[ $# -lt 2 ]]; then
          log_error "Argumento --target requer um valor."
          exit 1
        fi
        TARGET_DIR="$2"
        shift 2
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --help|-h)
        show_help
        ;;
      *)
        log_error "Argumento desconhecido: $1"
        log_error "Use --help para ver as opções disponíveis."
        exit 1
        ;;
    esac
  done

  # Validar argumentos obrigatórios
  if [[ -z "${ARCHETYPE}" ]]; then
    log_error "Argumento obrigatório ausente: --project-type"
    log_error "Tipos disponíveis: ${VALID_ARCHETYPES[*]}"
    exit 1
  fi

  if [[ -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    exit 1
  fi

  # Resolver path absoluto do target
  if [[ ! -d "${TARGET_DIR}" ]]; then
    log_error "Diretório destino não encontrado: ${TARGET_DIR}"
    exit 1
  fi

  TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

  # Verificar permissão de escrita no destino
  if [[ ! -w "${TARGET_DIR}" ]]; then
    log_error "Sem permissão de escrita no diretório destino: ${TARGET_DIR}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# main — Fluxo principal
# -----------------------------------------------------------------------------
main() {
  echo ""
  echo "============================================"
  echo "  bootstrap-workflows — MonteBravo"
  echo "============================================"
  echo ""

  parse_args "$@"
  validate_archetype

  log_info "Archetype:  ${ARCHETYPE}"
  log_info "Destino:    ${TARGET_DIR}"
  [[ "${DRY_RUN}" == true ]] && log_warn "Modo DRY-RUN ativado — nenhuma mudança será aplicada."
  [[ "${FORCE}" == true ]] && log_warn "Modo --force ativado — workflows existentes serão sobrescritos."
  echo ""

  copy_workflows
  echo ""
  copy_agents
  echo ""
  merge_review_rules
  echo ""
  merge_codeowners
  echo ""
  substitute_placeholders

  echo ""
  echo "============================================"
  if [[ "${DRY_RUN}" == true ]]; then
    log_info "Simulação (dry-run) concluída. Nenhuma mudança foi aplicada."
  else
    log_success "Bootstrap de workflows concluído!"
    echo ""
    log_info "  Arquivos copiados:  ${FILES_COPIED}"
    [[ ${FILES_SKIPPED} -gt 0 ]] && log_warn "  Arquivos pulados:   ${FILES_SKIPPED} (já existiam, use --force)"
    log_info "  Ações realizadas:   ${ACTIONS_PERFORMED}"
    echo ""
    log_info "Próximos passos:"
    log_info "  1. Revise o arquivo review-rules.yml e ajuste as severidades conforme necessário"
    log_info "  2. Edite .github/CODEOWNERS preenchendo os placeholders {{ }} com os times corretos"
    log_info "  3. Configure o secret KIRO_API_KEY no repositório GitHub"
    log_info "  4. Faça commit e push das alterações"
  fi
  echo "============================================"
  echo ""
}

main "$@"
