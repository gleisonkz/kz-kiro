#!/usr/bin/env bash
# =============================================================================
# lib/common.sh — Funções utilitárias compartilhadas entre scripts mb-kiro
# =============================================================================
# Módulo de funções reutilizáveis para bootstrap.sh, sync.sh e doctor.sh.
# Inclui logging, validação, operações de prefixo e manipulação de MCP JSON.
#
# Uso:
#   source "${SCRIPT_DIR}/lib/common.sh"
#
# Dependências:
#   - jq (soft dependency — funções de MCP degradam gracefully sem jq)
#
# Convenções:
#   - Prefixo "mb--" identifica artefatos do baseline no user-level
#   - HOME_OVERRIDE permite testes rodarem sem acessar o home real
#   - Todas as funções retornam 0 para sucesso, 1 para falha
# =============================================================================

# Prefixo organizacional para artefatos do baseline
readonly MB_PREFIX="mb--"

# Cores para output (desabilitadas se NO_COLOR ou saída não é terminal)
if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
  readonly _RED='\033[0;31m'
  readonly _GREEN='\033[0;32m'
  readonly _YELLOW='\033[1;33m'
  readonly _BLUE='\033[0;34m'
  readonly _NC='\033[0m'
else
  readonly _RED=''
  readonly _GREEN=''
  readonly _YELLOW=''
  readonly _BLUE=''
  readonly _NC=''
fi

# =============================================================================
# Logging
# =============================================================================

log_info() {
  echo -e "${_BLUE}[INFO]${_NC}  $*"
}

log_success() {
  echo -e "${_GREEN}[OK]${_NC}    $*"
}

log_warn() {
  echo -e "${_YELLOW}[WARN]${_NC}  $*" >&2
}

log_error() {
  echo -e "${_RED}[ERROR]${_NC} $*" >&2
}

# =============================================================================
# Detecção de ambiente
# =============================================================================

# Retorna 0 se estiver em ambiente CI (variável CI == "true", case-insensitive)
is_ci_environment() {
  [[ "${CI:-false}" =~ ^[Tt][Rr][Uu][Ee]$ ]]
}

# Retorna o diretório home efetivo (respeita HOME_OVERRIDE para testes)
get_user_home() {
  echo "${HOME_OVERRIDE:-${HOME}}"
}

# Retorna o caminho do user kiro dir (~/.kiro/)
get_user_kiro_dir() {
  echo "$(get_user_home)/.kiro"
}

# =============================================================================
# Validação
# =============================================================================

# Valida formato semver MAJOR.MINOR.PATCH (inteiros não-negativos, sem zeros à esquerda)
# Uso: validate_semver "1.2.3"
validate_semver() {
  local version="${1:-}"
  [[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

# Valida que scope é "user" ou "workspace"
# Uso: validate_scope "user"
validate_scope() {
  local scope="${1:-}"
  [[ "${scope}" == "user" || "${scope}" == "workspace" ]]
}

# Valida que o path existe e é um diretório
# Uso: validate_target "/path/to/dir"
validate_target() {
  local target="${1:-}"
  [[ -n "${target}" && -d "${target}" ]]
}

# =============================================================================
# Operações de prefixo
# =============================================================================

# Adiciona prefixo mb-- ao nome do arquivo
# Uso: add_prefix "file.md" → "mb--file.md"
add_prefix() {
  local filename="${1:-}"
  echo "${MB_PREFIX}${filename}"
}

# Remove prefixo mb-- do nome do arquivo
# Uso: strip_prefix "mb--file.md" → "file.md"
strip_prefix() {
  local filename="${1:-}"
  echo "${filename#"${MB_PREFIX}"}"
}

# Retorna 0 se o nome começa com prefixo mb--
# Uso: has_prefix "mb--file.md" && echo "tem prefixo"
has_prefix() {
  local filename="${1:-}"
  [[ "${filename}" == "${MB_PREFIX}"* ]]
}

# =============================================================================
# Operações de arquivo
# =============================================================================

# Copia arquivo aplicando prefixo mb-- ao nome no destino
# Uso: copy_with_prefix "source/file.md" "/dest/dir"
copy_with_prefix() {
  local src_file="${1:-}"
  local dest_dir="${2:-}"

  if [[ ! -f "${src_file}" ]]; then
    log_error "Arquivo fonte não encontrado: ${src_file}"
    return 1
  fi

  if [[ ! -d "${dest_dir}" ]]; then
    log_error "Diretório destino não encontrado: ${dest_dir}"
    return 1
  fi

  local filename
  filename="$(basename "${src_file}")"
  local dest_file="${dest_dir}/${MB_PREFIX}${filename}"

  cp "${src_file}" "${dest_file}"
}

# Compara byte-a-byte dois arquivos e copia se forem diferentes
# Retorna: 0 se copiou (era diferente), 1 se iguais (nada a fazer), 2 se erro
# Uso: sync_file "source.md" "dest.md"
sync_file() {
  local src_file="${1:-}"
  local dest_file="${2:-}"

  if [[ ! -f "${src_file}" ]]; then
    log_error "Arquivo fonte não encontrado: ${src_file}"
    return 2
  fi

  # Se destino não existe, copiar diretamente
  if [[ ! -f "${dest_file}" ]]; then
    cp "${src_file}" "${dest_file}"
    return 0
  fi

  # Comparar byte-a-byte usando cmp (silencioso)
  if cmp -s "${src_file}" "${dest_file}"; then
    return 1
  fi

  cp "${src_file}" "${dest_file}"
  return 0
}

# Lista arquivos com prefixo mb-- que não possuem correspondente na fonte
# Imprime em stdout um nome de arquivo órfão por linha
# Uso: find_orphans "/user/.kiro/steering" "/baselines/global/steering"
find_orphans() {
  local installed_dir="${1:-}"
  local source_dir="${2:-}"

  if [[ ! -d "${installed_dir}" || ! -d "${source_dir}" ]]; then
    return 0
  fi

  for installed_file in "${installed_dir}"/${MB_PREFIX}*; do
    [[ ! -f "${installed_file}" ]] && continue

    local installed_name
    installed_name="$(basename "${installed_file}")"

    # Derivar nome original removendo prefixo
    local original_name
    original_name="$(strip_prefix "${installed_name}")"

    # Verificar se existe correspondente na fonte
    if [[ ! -f "${source_dir}/${original_name}" ]]; then
      echo "${installed_name}"
    fi
  done
}

# =============================================================================
# MCP merge (requer jq)
# =============================================================================

# Mergea servidores MCP do baseline em um arquivo mcp.json destino,
# preservando servidores pessoais (chaves que não existem no baseline).
# Servidores com mesma chave são sobrescritos pela versão do baseline.
#
# Uso: merge_mcp_servers "baseline_mcp.json" "user_mcp.json"
# Retorna: 0 se sucesso, 1 se jq não disponível ou erro
merge_mcp_servers() {
  local baseline_mcp="${1:-}"
  local user_mcp="${2:-}"

  if ! command -v jq &>/dev/null; then
    log_error "jq é necessário para merge de MCP servers."
    return 1
  fi

  if [[ ! -f "${baseline_mcp}" ]]; then
    log_error "Arquivo MCP baseline não encontrado: ${baseline_mcp}"
    return 1
  fi

  # Se user_mcp não existe, criar com estrutura base copiando o baseline
  if [[ ! -f "${user_mcp}" ]]; then
    local dest_dir
    dest_dir="$(dirname "${user_mcp}")"
    mkdir -p "${dest_dir}"
    cp "${baseline_mcp}" "${user_mcp}"
    return 0
  fi

  # Merge: baseline sobrescreve chaves existentes, preserva pessoais
  local tmp_merged
  tmp_merged="$(mktemp)"

  if jq -s '
    {
      "mcpServers": (.[0].mcpServers * .[1].mcpServers)
    }
  ' "${user_mcp}" "${baseline_mcp}" > "${tmp_merged}" 2>/dev/null; then
    mv "${tmp_merged}" "${user_mcp}"
    return 0
  else
    rm -f "${tmp_merged}"
    log_error "Falha ao mergear MCP servers."
    return 1
  fi
}

# Remove servidores MCP por lista de chaves de um arquivo mcp.json
# Uso: remove_mcp_servers "target_mcp.json" "key1" "key2" "key3"
# Retorna: 0 se sucesso, 1 se jq não disponível ou erro
remove_mcp_servers() {
  local target_mcp="${1:-}"
  shift

  if ! command -v jq &>/dev/null; then
    log_error "jq é necessário para remover MCP servers."
    return 1
  fi

  if [[ ! -f "${target_mcp}" ]]; then
    log_error "Arquivo MCP não encontrado: ${target_mcp}"
    return 1
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  # Construir filtro jq para deletar todas as chaves de uma vez
  local jq_filter="."
  for key in "$@"; do
    jq_filter="${jq_filter} | del(.mcpServers[\"${key}\"])"
  done

  if jq "${jq_filter}" "${target_mcp}" > "${tmp_file}" 2>/dev/null; then
    mv "${tmp_file}" "${target_mcp}"
    return 0
  else
    rm -f "${tmp_file}"
    log_error "Falha ao remover MCP servers."
    return 1
  fi
}
