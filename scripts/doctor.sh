#!/usr/bin/env bash
# =============================================================================
# doctor.sh — Diagnóstico do Ambiente Kiro (MonteBravo)
# =============================================================================
# Verifica o estado do Kiro em um projeto e/ou no escopo do usuário,
# reportando inconsistências, componentes ausentes ou desatualizados.
#
# Uso:
#   ./scripts/doctor.sh --scope user [--output text|json] [--verbose]
#   ./scripts/doctor.sh --scope workspace --target <caminho> [--output text|json] [--verbose]
#   ./scripts/doctor.sh --target <caminho> [--output text|json] [--verbose]
#
# Opções:
#   --scope <user|workspace> Escopo do diagnóstico (opcional se --target informado)
#   --target <caminho>       Caminho para o diretório do projeto a diagnosticar
#   --output <formato>       Formato do relatório: text (padrão) | json
#   --verbose                Exibe detalhes adicionais nos warnings (diffs, listas de arquivos)
#   --help                   Exibe esta mensagem de ajuda
#
# Notas:
#   - Sem --scope + com --target: executa ambos escopos e consolida
#   - Em CI ($CI=true): pula verificação user-level automaticamente
#
# Exemplos:
#   ./scripts/doctor.sh --scope user
#   ./scripts/doctor.sh --scope workspace --target ../meu-projeto
#   ./scripts/doctor.sh --target ../meu-projeto
#   ./scripts/doctor.sh --target ../meu-projeto --verbose
#   ./scripts/doctor.sh --target ../meu-projeto --output json
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configurações globais
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Importar funções compartilhadas
source "${SCRIPT_DIR}/lib/common.sh"

# Contadores de diagnóstico
CHECKS_PASSED=0
CHECKS_WARNED=0
CHECKS_FAILED=0
CHECKS_INFO=0

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# JSON output
JSON_RESULTS="[]"
OUTPUT_FORMAT="text"
VERBOSE=false

# -----------------------------------------------------------------------------
# Funções de utilidade
# -----------------------------------------------------------------------------

log_info()    { [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${BLUE}[INFO]${NC}  $*"; return 0; }
log_info_check() { ((CHECKS_INFO++)) || true; [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${BLUE}[INFO]${NC}  $*"; return 0; }
log_pass()    { ((CHECKS_PASSED++)) || true; [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${GREEN}[PASS]${NC}  $*"; return 0; }
log_warn()    { ((CHECKS_WARNED++)) || true; [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${YELLOW}[WARN]${NC}  $*"; return 0; }
log_fail()    { ((CHECKS_FAILED++)) || true; [[ "${OUTPUT_FORMAT}" == "text" ]] && echo -e "${RED}[FAIL]${NC}  $*"; return 0; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_detail()  { [[ "${VERBOSE}" == true && "${OUTPUT_FORMAT}" == "text" ]] && echo -e "          $*"; return 0; }

print_help() {
  grep '^#' "${BASH_SOURCE[0]}" | grep -v '#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

add_json_result() {
  local status="$1"
  local category="$2"
  local message="$3"
  local details="${4:-}"
  if command -v jq &>/dev/null; then
    if [[ -n "${details}" && "${VERBOSE}" == true ]]; then
      JSON_RESULTS=$(echo "${JSON_RESULTS}" | jq --arg s "${status}" --arg c "${category}" --arg m "${message}" --arg d "${details}" \
        '. + [{"status": $s, "category": $c, "message": $m, "details": $d}]')
    else
      JSON_RESULTS=$(echo "${JSON_RESULTS}" | jq --arg s "${status}" --arg c "${category}" --arg m "${message}" \
        '. + [{"status": $s, "category": $c, "message": $m}]')
    fi
  fi
}

# -----------------------------------------------------------------------------
# Verificação de exceções
# -----------------------------------------------------------------------------
# check_exception recebe:
#   $1 = rule (formato: <componente>.<nome-da-regra>)
#   $2 = category (para JSON result: baseline, archetype, etc.)
#   $3 = message (mensagem para o relatório quando exceção é válida)
#
# Retorna:
#   0 — exceção válida encontrada (artefato coberto, reporta INFO)
#   1 — nenhuma exceção válida encontrada (continuar verificação normal)
#
# Efeitos colaterais:
#   - Se exceção válida: emite INFO e add_json_result "info"
#   - Se exceção expirada: emite WARN e add_json_result "warn"
#     (e retorna 1 pois exceção expirada não cobre mais o artefato)

check_exception() {
  local rule="$1"
  local category="$2"
  local message="$3"
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  # Pré-requisitos: jq disponível e manifest existente
  if ! command -v jq &>/dev/null; then
    return 1
  fi

  if [[ ! -f "${manifest_path}" ]]; then
    return 1
  fi

  # Buscar exceção com a rule correspondente
  local exception
  exception=$(jq -r --arg rule "${rule}" '
    .exceptions // [] | map(select(.rule == $rule)) | first // empty
  ' "${manifest_path}" 2>/dev/null) || true

  if [[ -z "${exception}" ]]; then
    return 1
  fi

  # Validar campos obrigatórios da exceção
  local exc_rule exc_reason exc_approved_by exc_approved_at exc_review_date
  exc_rule=$(echo "${exception}" | jq -r '.rule // empty' 2>/dev/null)
  exc_reason=$(echo "${exception}" | jq -r '.reason // empty' 2>/dev/null)
  exc_approved_by=$(echo "${exception}" | jq -r '.approved_by // empty' 2>/dev/null)
  exc_approved_at=$(echo "${exception}" | jq -r '.approved_at // empty' 2>/dev/null)
  exc_review_date=$(echo "${exception}" | jq -r '.review_date // empty' 2>/dev/null)

  # Validar rule no formato <componente>.<nome> (aceita múltiplos níveis: archetype.skills.nome)
  if [[ ! "${exc_rule}" =~ ^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$ ]]; then
    return 1
  fi

  # Validar reason (20-500 caracteres)
  local reason_len=${#exc_reason}
  if [[ ${reason_len} -lt 20 || ${reason_len} -gt 500 ]]; then
    return 1
  fi

  # Validar approved_by (não-vazio)
  if [[ -z "${exc_approved_by}" ]]; then
    return 1
  fi

  # Validar approved_at (ISO 8601)
  if [[ ! "${exc_approved_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})?)?$ ]]; then
    return 1
  fi

  # Validar review_date (ISO 8601)
  if [[ ! "${exc_review_date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})?)?$ ]]; then
    return 1
  fi

  # Validar que review_date não excede 90 dias de approved_at
  local approved_epoch review_epoch
  if date --version &>/dev/null 2>&1; then
    # GNU date
    approved_epoch=$(date -d "${exc_approved_at}" +%s 2>/dev/null) || return 1
    review_epoch=$(date -d "${exc_review_date}" +%s 2>/dev/null) || return 1
  else
    # BSD/macOS date
    # Extrair apenas a parte de data para compatibilidade
    local approved_date_part="${exc_approved_at%%T*}"
    local review_date_part="${exc_review_date%%T*}"
    approved_epoch=$(date -j -f "%Y-%m-%d" "${approved_date_part}" +%s 2>/dev/null) || return 1
    review_epoch=$(date -j -f "%Y-%m-%d" "${review_date_part}" +%s 2>/dev/null) || return 1
  fi

  local max_seconds=$((90 * 24 * 60 * 60))
  local diff_seconds=$((review_epoch - approved_epoch))

  if [[ ${diff_seconds} -gt ${max_seconds} ]]; then
    return 1
  fi

  # Verificar se a exceção expirou (review_date < data corrente)
  local current_epoch
  current_epoch=$(date +%s)

  if [[ ${review_epoch} -lt ${current_epoch} ]]; then
    # Exceção expirada — reportar WARN
    log_warn "Exceção expirada para '${rule}': review_date ${exc_review_date} ultrapassada. Revisão necessária."
    add_json_result "warn" "${category}" "Exceção expirada: ${rule} (review_date: ${exc_review_date})"
    return 1
  fi

  # Exceção válida — reportar INFO em vez de FAIL/WARN
  log_info "Exceção válida para '${rule}': ${exc_reason:0:60}..."
  add_json_result "info" "${category}" "${message} (exceção: ${rule})"
  return 0
}

# -----------------------------------------------------------------------------
# Validação de argumentos
# -----------------------------------------------------------------------------

SCOPE=""
TARGET_DIR=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope)   SCOPE="$2"; shift 2 ;;
      --target)  TARGET_DIR="$2"; shift 2 ;;
      --output)  OUTPUT_FORMAT="$2"; shift 2 ;;
      --verbose) VERBOSE=true; shift ;;
      --help|-h) print_help ;;
      *)
        log_error "Argumento desconhecido: $1"
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

  # --scope workspace requer --target
  if [[ "${SCOPE}" == "workspace" && -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    log_error "--target é obrigatório para o escopo workspace."
    exit 1
  fi

  # Sem --scope e sem --target: erro
  if [[ -z "${SCOPE}" && -z "${TARGET_DIR}" ]]; then
    log_error "Argumentos insuficientes."
    log_error "Uso:"
    log_error "  doctor.sh --scope user                           (verifica baseline em ~/.kiro/)"
    log_error "  doctor.sh --scope workspace --target <caminho>   (verifica archetype no projeto)"
    log_error "  doctor.sh --target <caminho>                     (verifica ambos escopos)"
    log_error ""
    log_error "Valores válidos para --scope: user, workspace"
    exit 1
  fi

  # Resolver --target para caminho absoluto se informado
  if [[ -n "${TARGET_DIR}" ]]; then
    TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)" || {
      log_error "Diretório destino não encontrado: ${TARGET_DIR}"
      exit 1
    }
  fi
}

# -----------------------------------------------------------------------------
# Verificações de diagnóstico
# -----------------------------------------------------------------------------

check_manifest() {
  echo ""
  log_info "=== Manifest Kiro ==="

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ -f "${manifest_path}" ]]; then
    log_pass "kiro-manifest.json encontrado."
    add_json_result "pass" "manifest" "kiro-manifest.json encontrado"

    if command -v jq &>/dev/null; then
      if jq '.' "${manifest_path}" > /dev/null 2>&1; then
        log_pass "JSON válido."
        add_json_result "pass" "manifest" "JSON válido"

        # Verificar campos obrigatórios
        local has_baseline has_archetype has_powers
        has_baseline=$(jq -r '.baseline.version // empty' "${manifest_path}" 2>/dev/null)
        has_archetype=$(jq -r '.archetype.name // empty' "${manifest_path}" 2>/dev/null)
        has_powers=$(jq -r '.powers | length' "${manifest_path}" 2>/dev/null)

        if [[ -n "${has_baseline}" ]]; then
          log_pass "Baseline declarado: v${has_baseline}"
          add_json_result "pass" "manifest" "Baseline declarado: v${has_baseline}"
        else
          log_fail "Campo baseline.version ausente no manifest."
          add_json_result "fail" "manifest" "Campo baseline.version ausente"
        fi

        if [[ -n "${has_archetype}" ]]; then
          log_pass "Archetype declarado: ${has_archetype}"
          add_json_result "pass" "manifest" "Archetype declarado: ${has_archetype}"
        else
          log_fail "Campo archetype.name ausente no manifest."
          add_json_result "fail" "manifest" "Campo archetype.name ausente"
        fi

        log_pass "Powers declarados: ${has_powers:-0}"
        add_json_result "pass" "manifest" "Powers declarados: ${has_powers:-0}"

        # Validar schema das exceções
        validate_exceptions
      else
        log_fail "kiro-manifest.json contém JSON inválido."
        add_json_result "fail" "manifest" "JSON inválido"
      fi
    else
      log_warn "jq não disponível — validação estrutural limitada."
      add_json_result "warn" "manifest" "jq não disponível"
    fi
  else
    log_fail "kiro-manifest.json não encontrado. Execute bootstrap.sh primeiro."
    add_json_result "fail" "manifest" "kiro-manifest.json não encontrado"
  fi
}

validate_exceptions() {
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  # Requer jq e manifest existente
  if ! command -v jq &>/dev/null || [[ ! -f "${manifest_path}" ]]; then
    return
  fi

  # Verificar se o array exceptions existe
  local exception_count
  exception_count=$(jq -r '.exceptions | length // 0' "${manifest_path}" 2>/dev/null)

  if [[ "${exception_count}" -eq 0 || "${exception_count}" == "null" ]]; then
    return
  fi

  log_info "Validando schema de ${exception_count} exceção(ões)..."

  local i=0
  while [[ ${i} -lt ${exception_count} ]]; do
    local rule reason approved_by approved_at review_date
    rule=$(jq -r ".exceptions[${i}].rule // empty" "${manifest_path}" 2>/dev/null)
    reason=$(jq -r ".exceptions[${i}].reason // empty" "${manifest_path}" 2>/dev/null)
    approved_by=$(jq -r ".exceptions[${i}].approved_by // empty" "${manifest_path}" 2>/dev/null)
    approved_at=$(jq -r ".exceptions[${i}].approved_at // empty" "${manifest_path}" 2>/dev/null)
    review_date=$(jq -r ".exceptions[${i}].review_date // empty" "${manifest_path}" 2>/dev/null)

    local exception_label="exceptions[${i}]"
    local has_error=false

    # Validar rule: formato <componente>.<nome>
    if [[ -z "${rule}" ]]; then
      log_warn "${exception_label}: campo 'rule' ausente ou vazio"
      add_json_result "warn" "manifest" "${exception_label}: campo 'rule' ausente ou vazio"
      has_error=true
    elif [[ "${rule}" != *.* ]]; then
      log_warn "${exception_label}: campo 'rule' não está no formato <componente>.<nome> (valor: '${rule}')"
      add_json_result "warn" "manifest" "${exception_label}: campo 'rule' formato inválido"
      has_error=true
    fi

    # Validar reason: 20-500 caracteres
    if [[ -z "${reason}" ]]; then
      log_warn "${exception_label}: campo 'reason' ausente ou vazio"
      add_json_result "warn" "manifest" "${exception_label}: campo 'reason' ausente ou vazio"
      has_error=true
    else
      local reason_len=${#reason}
      if [[ ${reason_len} -lt 20 ]]; then
        log_warn "${exception_label}: campo 'reason' muito curto (${reason_len} chars, mínimo 20)"
        add_json_result "warn" "manifest" "${exception_label}: reason muito curto (${reason_len} chars)"
        has_error=true
      elif [[ ${reason_len} -gt 500 ]]; then
        log_warn "${exception_label}: campo 'reason' muito longo (${reason_len} chars, máximo 500)"
        add_json_result "warn" "manifest" "${exception_label}: reason muito longo (${reason_len} chars)"
        has_error=true
      fi
    fi

    # Validar approved_by: não-vazio
    if [[ -z "${approved_by}" ]]; then
      log_warn "${exception_label}: campo 'approved_by' ausente ou vazio"
      add_json_result "warn" "manifest" "${exception_label}: campo 'approved_by' ausente ou vazio"
      has_error=true
    fi

    # Validar approved_at: ISO 8601 (aceita YYYY-MM-DD ou YYYY-MM-DDTHH:MM:SSZ)
    if [[ -z "${approved_at}" ]]; then
      log_warn "${exception_label}: campo 'approved_at' ausente ou vazio"
      add_json_result "warn" "manifest" "${exception_label}: campo 'approved_at' ausente ou vazio"
      has_error=true
    elif ! echo "${approved_at}" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})?)?$'; then
      log_warn "${exception_label}: campo 'approved_at' não é ISO 8601 válido (valor: '${approved_at}')"
      add_json_result "warn" "manifest" "${exception_label}: approved_at não é ISO 8601 válido"
      has_error=true
    fi

    # Validar review_date: ISO 8601 e max 90 dias de approved_at
    if [[ -z "${review_date}" ]]; then
      log_warn "${exception_label}: campo 'review_date' ausente ou vazio"
      add_json_result "warn" "manifest" "${exception_label}: campo 'review_date' ausente ou vazio"
      has_error=true
    elif ! echo "${review_date}" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2}))?$'; then
      log_warn "${exception_label}: campo 'review_date' não é ISO 8601 válido (valor: '${review_date}')"
      add_json_result "warn" "manifest" "${exception_label}: review_date não é ISO 8601 válido"
      has_error=true
    elif [[ -n "${approved_at}" ]] && echo "${approved_at}" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})?)?$'; then
      # Calcular diferença entre review_date e approved_at (max 90 dias)
      local approved_epoch review_epoch
      # Extrair apenas a parte da data para cálculo
      local approved_date_part="${approved_at%%T*}"
      local review_date_part="${review_date%%T*}"

      if date -j -f "%Y-%m-%d" "${approved_date_part}" "+%s" &>/dev/null 2>&1; then
        # macOS date
        approved_epoch=$(date -j -f "%Y-%m-%d" "${approved_date_part}" "+%s" 2>/dev/null)
        review_epoch=$(date -j -f "%Y-%m-%d" "${review_date_part}" "+%s" 2>/dev/null)
      elif date -d "${approved_date_part}" "+%s" &>/dev/null 2>&1; then
        # GNU date
        approved_epoch=$(date -d "${approved_date_part}" "+%s" 2>/dev/null)
        review_epoch=$(date -d "${review_date_part}" "+%s" 2>/dev/null)
      fi

      if [[ -n "${approved_epoch:-}" && -n "${review_epoch:-}" ]]; then
        local diff_days=$(( (review_epoch - approved_epoch) / 86400 ))
        if [[ ${diff_days} -gt 90 ]]; then
          log_warn "${exception_label}: 'review_date' excede 90 dias de 'approved_at' (${diff_days} dias)"
          add_json_result "warn" "manifest" "${exception_label}: review_date excede 90 dias (${diff_days} dias)"
          has_error=true
        fi
      fi
    fi

    if [[ "${has_error}" == false ]]; then
      log_pass "${exception_label}: schema válido (rule: ${rule})"
      add_json_result "pass" "manifest" "${exception_label}: schema válido"
    fi

    ((i++)) || true
  done
}

check_baseline() {
  echo ""
  log_info "=== Baseline Global ==="

  local kiro_steering_dir="${TARGET_DIR}/.kiro/steering"

  if [[ -d "${kiro_steering_dir}" ]]; then
    log_pass "Diretório .kiro/steering/ encontrado."
    add_json_result "pass" "baseline" "Diretório .kiro/steering/ encontrado"

    local baseline_dir="${REPO_ROOT}/baselines/global/steering"
    local required_files=()

    # Descobrir arquivos do baseline dinamicamente
    if [[ -d "${baseline_dir}" ]]; then
      while IFS= read -r -d '' f; do
        local fname
        fname=$(basename "${f}")
        [[ "${fname}" == "README.md" ]] && continue
        required_files+=("${fname}")
      done < <(find "${baseline_dir}" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
    fi

    for f in "${required_files[@]}"; do
      # Derivar rule name para exceções: baseline.<nome-sem-extensão>
      local rule_name="baseline.${f%.md}"

      if [[ -f "${kiro_steering_dir}/${f}" ]]; then
        # Verificar se está atualizado
        if [[ -f "${baseline_dir}/${f}" ]]; then
          if diff -q "${baseline_dir}/${f}" "${kiro_steering_dir}/${f}" > /dev/null 2>&1; then
            log_pass "Atualizado: ${f}"
            add_json_result "pass" "baseline" "Atualizado: ${f}"
          else
            # Verificar se há exceção válida cobrindo este artefato
            if check_exception "${rule_name}" "baseline" "Desatualizado com exceção: ${f}"; then
              continue
            fi
            log_warn "Desatualizado: ${f} (difere da versão no mb-kiro)"
            local diff_output
            diff_output=$(diff --unified=3 "${baseline_dir}/${f}" "${kiro_steering_dir}/${f}" 2>/dev/null || true)
            add_json_result "warn" "baseline" "Desatualizado: ${f}" "${diff_output}"
            if [[ "${VERBOSE}" == true ]]; then
              log_detail "Diferenças em ${f}:"
              diff --unified=3 "${baseline_dir}/${f}" "${kiro_steering_dir}/${f}" 2>/dev/null | while IFS= read -r line; do
                log_detail "  ${line}"
              done
            fi
          fi
        else
          log_pass "Presente: ${f}"
          add_json_result "pass" "baseline" "Presente: ${f}"
        fi
      else
        # Verificar se há exceção válida cobrindo este artefato ausente
        if check_exception "${rule_name}" "baseline" "Ausente com exceção: ${f}"; then
          continue
        fi
        log_fail "Ausente: ${f}"
        add_json_result "fail" "baseline" "Ausente: ${f}"
      fi
    done
  else
    log_fail "Diretório .kiro/steering/ não encontrado. Baseline não aplicado."
    add_json_result "fail" "baseline" "Diretório .kiro/steering/ não encontrado"
  fi
}

check_archetype() {
  echo ""
  log_info "=== Archetype ==="

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"
  local archetype_name=""

  if command -v jq &>/dev/null && [[ -f "${manifest_path}" ]]; then
    archetype_name=$(jq -r '.archetype.name // empty' "${manifest_path}" 2>/dev/null)
  fi

  if [[ -z "${archetype_name}" ]]; then
    log_warn "Não foi possível determinar o archetype (jq ausente ou manifest incompleto)."
    add_json_result "warn" "archetype" "Archetype não determinado"
    return
  fi

  local archetype_dir="${REPO_ROOT}/archetypes/${archetype_name}"

  if [[ ! -d "${archetype_dir}" ]]; then
    log_fail "Archetype '${archetype_name}' não encontrado no repositório mb-kiro."
    add_json_result "fail" "archetype" "Archetype ${archetype_name} não encontrado"
    return
  fi

  log_pass "Archetype: ${archetype_name}"
  add_json_result "pass" "archetype" "Archetype: ${archetype_name}"

  # Verificar steering files do archetype
  local check_dirs=("steering:*.md" "skills:*.md" "hooks:*.json" "hooks:*.kiro.hook" "agents:*.md")

  for entry in "${check_dirs[@]}"; do
    local dir_name="${entry%%:*}"
    local pattern="${entry##*:}"
    local src_dir="${archetype_dir}/${dir_name}"
    local dest_dir="${TARGET_DIR}/.kiro/${dir_name}"

    if [[ ! -d "${src_dir}" ]]; then
      continue
    fi

    local src_count
    src_count=$(find "${src_dir}" -maxdepth 1 -name "${pattern}" -not -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "${src_count}" -eq 0 ]]; then
      continue
    fi

    if [[ -d "${dest_dir}" ]]; then
      local dest_count
      dest_count=$(find "${dest_dir}" -maxdepth 1 -name "${pattern}" -not -name "README.md" -type f 2>/dev/null | wc -l | tr -d ' ')

      if [[ "${dest_count}" -ge "${src_count}" ]]; then
        log_pass "${dir_name}: ${dest_count}/${src_count} arquivos presentes"
        add_json_result "pass" "archetype" "${dir_name}: ${dest_count}/${src_count}"
      else
        # Verificar se cada arquivo ausente está coberto por exceção
        local missing_files=""
        local all_covered=true
        for src_file in "${src_dir}"/${pattern}; do
          [[ ! -f "${src_file}" ]] && continue
          local src_fname
          src_fname=$(basename "${src_file}")
          [[ "${src_fname}" == "README.md" ]] && continue
          if [[ ! -f "${dest_dir}/${src_fname}" ]]; then
            local archetype_rule="archetype.${dir_name}.${src_fname%.*}"
            if check_exception "${archetype_rule}" "archetype" "Ausente com exceção: ${dir_name}/${src_fname}"; then
              continue
            fi
            missing_files="${missing_files}${src_fname}, "
            all_covered=false
          fi
        done
        missing_files="${missing_files%, }"

        if [[ "${all_covered}" == true ]]; then
          # Todos os ausentes cobertos por exceções — já reportados como INFO
          :
        else
          log_warn "${dir_name}: ${dest_count}/${src_count} arquivos (faltam $(( src_count - dest_count )))"
          add_json_result "warn" "archetype" "${dir_name}: ${dest_count}/${src_count} (incompleto)" "Ausentes: ${missing_files}"
          if [[ "${VERBOSE}" == true ]]; then
            log_detail "Arquivos ausentes em .kiro/${dir_name}/:"
            IFS=', ' read -ra missing_arr <<< "${missing_files}"
            for mf in "${missing_arr[@]}"; do
              [[ -n "${mf}" ]] && log_detail "  - ${mf}"
            done
          fi
        fi
      fi
    else
      # Verificar se há exceção válida cobrindo o diretório inteiro
      local dir_rule="archetype.${dir_name}"
      if check_exception "${dir_rule}" "archetype" "Diretório ausente com exceção: ${dir_name}"; then
        continue
      fi
      log_fail "${dir_name}: diretório .kiro/${dir_name}/ não encontrado"
      add_json_result "fail" "archetype" "${dir_name}: diretório ausente"
    fi
  done
}

check_powers() {
  echo ""
  log_info "=== Powers ==="

  local manifest_path="${TARGET_DIR}/kiro-manifest.json"
  local confluence_base="https://montebravo.atlassian.net/wiki/spaces/KIRO/pages/powers-troubleshooting"

  if ! command -v jq &>/dev/null; then
    log_warn "jq necessário para verificar powers."
    add_json_result "warn" "powers" "jq não disponível"
    return
  fi

  if [[ ! -f "${manifest_path}" ]]; then
    log_warn "Manifest não encontrado — verificação de powers pulada."
    return
  fi

  # Verificar se o repositório mb-kiro está acessível
  if [[ ! -d "${REPO_ROOT}/powers" ]]; then
    log_warn "Não foi possível verificar powers no repositório (diretório powers/ não acessível)."
    add_json_result "warn" "powers" "Não foi possível verificar powers no repositório"
    return
  fi

  local power_count
  power_count=$(jq -r '.powers | length' "${manifest_path}" 2>/dev/null)

  if [[ "${power_count}" -eq 0 || "${power_count}" == "null" ]]; then
    log_info "Nenhum power declarado no manifest."
    return
  fi

  local i=0
  while [[ ${i} -lt ${power_count} ]]; do
    local power_name power_version power_method power_status
    power_name=$(jq -r ".powers[${i}].name // empty" "${manifest_path}" 2>/dev/null)
    power_version=$(jq -r ".powers[${i}].version // empty" "${manifest_path}" 2>/dev/null)
    power_method=$(jq -r ".powers[${i}].installation_method // \"legacy\"" "${manifest_path}" 2>/dev/null)
    power_status=$(jq -r ".powers[${i}].status // \"active\"" "${manifest_path}" 2>/dev/null)

    ((i++)) || true

    [[ -z "${power_name}" ]] && continue
    # Pular powers removidos
    [[ "${power_status}" == "removed" ]] && continue

    log_info "Verificando power: ${power_name}"

    # --- Verificação 1: Existe em powers/<name>/ (não em _drafts) ---
    if [[ -d "${REPO_ROOT}/powers/_drafts/${power_name}" ]]; then
      log_fail "Power '${power_name}' foi movido para _drafts/ (placeholder/descontinuado)."
      log_info "  → Remova a entrada do manifest ou execute sync.sh para limpeza automática."
      log_info "  → Troubleshooting: ${confluence_base}#power-em-drafts"
      add_json_result "fail" "powers" "Power em _drafts: ${power_name}"
      continue
    fi

    if [[ ! -d "${REPO_ROOT}/powers/${power_name}" ]]; then
      log_fail "Power '${power_name}' não encontrado no repositório mb-kiro. O power pode ter sido removido ou renomeado."
      log_info "  → Remova a entrada do manifest com: jq 'del(.powers[] | select(.name == \"${power_name}\"))' kiro-manifest.json > tmp && mv tmp kiro-manifest.json"
      log_info "  → Troubleshooting: ${confluence_base}#power-nao-encontrado"
      add_json_result "fail" "powers" "Power não encontrado: ${power_name}"
      continue
    fi

    log_pass "Power disponível no repositório: ${power_name}"
    add_json_result "pass" "powers" "Power disponível: ${power_name}"

    # --- Verificação 2: POWER.md tem frontmatter com keywords ---
    local power_md="${REPO_ROOT}/powers/${power_name}/POWER.md"
    if [[ ! -f "${power_md}" ]]; then
      log_fail "Power '${power_name}': POWER.md ausente. Necessário para instalação nativa."
      log_info "  → Troubleshooting: ${confluence_base}#power-md-ausente"
      add_json_result "fail" "powers" "POWER.md ausente: ${power_name}"
      continue
    fi

    # Extrair frontmatter e verificar keywords
    local has_keywords=false
    if head -1 "${power_md}" | grep -q '^---$'; then
      local frontmatter
      frontmatter=$(sed -n '2,/^---$/p' "${power_md}" | sed '$d')
      if echo "${frontmatter}" | grep -qE '^keywords:'; then
        has_keywords=true
      fi
    fi

    if [[ "${has_keywords}" == false ]]; then
      log_fail "Power '${power_name}': Keywords obrigatórias para ativação dinâmica (ausentes no frontmatter do POWER.md)."
      log_info "  → Adicione 'keywords: [\"keyword1\", \"keyword2\"]' ao frontmatter do POWER.md"
      log_info "  → Troubleshooting: ${confluence_base}#keywords-ausentes"
      add_json_result "fail" "powers" "Keywords ausentes: ${power_name}"
    else
      log_pass "Power '${power_name}': POWER.md com frontmatter e keywords válidos."
      add_json_result "pass" "powers" "POWER.md válido: ${power_name}"
    fi

    # --- Verificação 3: Versão manifest < VERSION file ---
    local version_file="${REPO_ROOT}/powers/${power_name}/VERSION"
    if [[ -f "${version_file}" ]]; then
      local repo_version
      repo_version=$(tr -d '[:space:]' < "${version_file}")

      if [[ -n "${power_version}" && -n "${repo_version}" && "${power_version}" != "${repo_version}" ]]; then
        # Comparação simplificada de versão (string compare para SemVer básico)
        # Usa sort -V para ordenar versões e verifica se a do manifest é a menor
        local sorted_first
        sorted_first=$(printf '%s\n%s\n' "${power_version}" "${repo_version}" | sort -V | head -1)
        if [[ "${sorted_first}" == "${power_version}" && "${power_version}" != "${repo_version}" ]]; then
          log_warn "Power '${power_name}': versão local (${power_version}) inferior à disponível (${repo_version})."
          log_info "  → Execute 'git pull' no mb-kiro e use 'Check for updates' no painel de Powers do Kiro IDE."
          log_info "  → Troubleshooting: ${confluence_base}#power-desatualizado"
          add_json_result "warn" "powers" "Versão desatualizada: ${power_name} (${power_version} → ${repo_version})"
        else
          log_pass "Power '${power_name}': versão atualizada (${power_version})."
          add_json_result "pass" "powers" "Versão OK: ${power_name} (${power_version})"
        fi
      else
        log_pass "Power '${power_name}': versão atualizada (${power_version:-0.0.0})."
        add_json_result "pass" "powers" "Versão OK: ${power_name}"
      fi
    else
      log_info "Power '${power_name}': arquivo VERSION ausente no repositório (usando 0.0.0 como fallback)."
    fi

    # --- Verificação 4: Steering legado em .kiro/steering/powers/<name>/ ---
    local legacy_steering_dir="${TARGET_DIR}/.kiro/steering/powers/${power_name}"
    local has_legacy_steering=false
    if [[ -d "${legacy_steering_dir}" ]]; then
      has_legacy_steering=true
    fi

    # --- Verificação 5: Duplicado (legado + native) ---
    if [[ "${has_legacy_steering}" == true && "${power_method}" == "native" ]]; then
      log_warn "Power '${power_name}': instalação duplicada detectada (native + legado residual)."
      log_info "  → Arquivos legados em: ${legacy_steering_dir}"
      log_info "  → Remova os arquivos legados: rm -rf \"${legacy_steering_dir}\""
      log_info "  → Ou execute: ./scripts/sync.sh --target \"${TARGET_DIR}\" --migrate-powers"
      log_info "  → Troubleshooting: ${confluence_base}#instalacao-duplicada"
      add_json_result "warn" "powers" "Instalação duplicada: ${power_name} (native + legado)"
    elif [[ "${has_legacy_steering}" == true ]]; then
      log_warn "Power '${power_name}': instalação legada detectada em .kiro/steering/powers/${power_name}/."
      log_info "  → Migre para instalação nativa: ./scripts/sync.sh --target \"${TARGET_DIR}\" --migrate-powers"
      log_info "  → Após migrar, instale via Kiro IDE: Import power from a folder → ${REPO_ROOT}/powers/${power_name}/"
      log_info "  → Troubleshooting: ${confluence_base}#instalacao-legada"
      add_json_result "warn" "powers" "Instalação legada: ${power_name}"
    fi

  done
}

check_general_health() {
  echo ""
  log_info "=== Saúde Geral ==="

  # Git
  if git -C "${TARGET_DIR}" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log_pass "Repositório Git detectado."
    add_json_result "pass" "health" "Repositório Git"
  else
    log_warn "Diretório não é um repositório Git."
    add_json_result "warn" "health" "Não é repositório Git"
  fi

  # README
  if [[ -f "${TARGET_DIR}/README.md" ]]; then
    log_pass "README.md presente."
    add_json_result "pass" "health" "README.md presente"
  else
    log_warn "README.md ausente."
    add_json_result "warn" "health" "README.md ausente"
  fi

  # .kiro directory
  if [[ -d "${TARGET_DIR}/.kiro" ]]; then
    log_pass "Diretório .kiro/ presente."
    add_json_result "pass" "health" ".kiro/ presente"

    # Contar arquivos
    local steering_count skills_count hooks_count agents_count
    steering_count=$(find "${TARGET_DIR}/.kiro/steering" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    skills_count=$(find "${TARGET_DIR}/.kiro/skills" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    hooks_count=$(find "${TARGET_DIR}/.kiro/hooks" \( -name "*.json" -o -name "*.kiro.hook" \) -type f 2>/dev/null | wc -l | tr -d ' ')
    agents_count=$(find "${TARGET_DIR}/.kiro/agents" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    log_info "  Steering files: ${steering_count}"
    log_info "  Skills:         ${skills_count}"
    log_info "  Hooks:          ${hooks_count}"
    log_info "  Agents:         ${agents_count}"
  else
    log_fail "Diretório .kiro/ não encontrado. Execute bootstrap.sh."
    add_json_result "fail" "health" ".kiro/ ausente"
  fi

  # MCP config
  local mcp_path="${TARGET_DIR}/.kiro/settings/mcp.json"
  if [[ -f "${mcp_path}" ]]; then
    log_pass "mcp.json presente."
    add_json_result "pass" "health" "mcp.json presente"

    if command -v jq &>/dev/null; then
      local server_count
      server_count=$(jq -r '.mcpServers | keys | length' "${mcp_path}" 2>/dev/null)
      log_info "  MCP servers configurados: ${server_count:-0}"

      # Verificar se está atualizado com o baseline
      local mcp_baseline="${REPO_ROOT}/baselines/global/mcp/mcp.json"
      if [[ -f "${mcp_baseline}" ]]; then
        if diff -q "${mcp_baseline}" "${mcp_path}" > /dev/null 2>&1; then
          log_pass "mcp.json atualizado com baseline."
          add_json_result "pass" "health" "mcp.json atualizado"
        else
          log_warn "mcp.json difere do baseline (pode ter customizações locais)."
          add_json_result "warn" "health" "mcp.json difere do baseline"
          if [[ "${VERBOSE}" == true ]]; then
            # Mostrar servers que existem no baseline mas faltam no projeto
            local missing_servers
            missing_servers=$(jq -r --slurpfile proj "${mcp_path}" \
              '.mcpServers | keys[] | select(. as $k | $proj[0].mcpServers[$k] == null)' \
              "${mcp_baseline}" 2>/dev/null)
            if [[ -n "${missing_servers}" ]]; then
              log_detail "Servers do baseline ausentes no projeto:"
              while IFS= read -r srv; do
                log_detail "  - ${srv}"
              done <<< "${missing_servers}"
            fi

            # Mostrar servers que existem no projeto mas não no baseline
            local extra_servers
            extra_servers=$(jq -r --slurpfile base "${mcp_baseline}" \
              '.mcpServers | keys[] | select(. as $k | $base[0].mcpServers[$k] == null)' \
              "${mcp_path}" 2>/dev/null)
            if [[ -n "${extra_servers}" ]]; then
              log_detail "Servers adicionais no projeto (não estão no baseline):"
              while IFS= read -r srv; do
                log_detail "  - ${srv}"
              done <<< "${extra_servers}"
            fi

            # Mostrar servers que existem em ambos mas com config diferente
            local common_servers
            common_servers=$(jq -r --slurpfile proj "${mcp_path}" \
              '.mcpServers | keys[] | select(. as $k | $proj[0].mcpServers[$k] != null)' \
              "${mcp_baseline}" 2>/dev/null)
            if [[ -n "${common_servers}" ]]; then
              local modified_list=""
              while IFS= read -r srv; do
                local base_cfg proj_cfg
                base_cfg=$(jq -c ".mcpServers[\"${srv}\"]" "${mcp_baseline}" 2>/dev/null)
                proj_cfg=$(jq -c ".mcpServers[\"${srv}\"]" "${mcp_path}" 2>/dev/null)
                if [[ "${base_cfg}" != "${proj_cfg}" ]]; then
                  modified_list="${modified_list}  - ${srv}\n"
                fi
              done <<< "${common_servers}"
              if [[ -n "${modified_list}" ]]; then
                log_detail "Servers com configuração modificada:"
                echo -e "${modified_list}" | while IFS= read -r line; do
                  [[ -n "${line}" ]] && log_detail "${line}"
                done
              fi
            fi
          fi
        fi
      fi
    fi
  else
    log_warn "mcp.json ausente em .kiro/settings/. MCPs homologados não configurados."
    add_json_result "warn" "health" "mcp.json ausente"
  fi
}

# -----------------------------------------------------------------------------
# Funções de diagnóstico — Scope User (stub para task 9)
# -----------------------------------------------------------------------------

doctor_user_scope() {
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then
    echo ""
    echo "============================================"
    echo "  mb-kiro Doctor — Scope User"
    echo "============================================"
    echo ""
  fi

  local user_kiro_dir
  user_kiro_dir="$(get_user_kiro_dir)"

  log_info "Verificando baseline em: ${user_kiro_dir}"
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi

  # --- Verificação 1: Existência de ~/.kiro/ ---
  if [[ ! -d "${user_kiro_dir}" ]]; then
    log_fail "Diretório ${user_kiro_dir} não encontrado. O baseline não foi instalado."
    add_json_result "fail" "user-scope" "Diretório ~/.kiro/ não encontrado"
    log_info "Execute: bootstrap.sh --scope user"
    return
  fi

  log_pass "Diretório ${user_kiro_dir} encontrado."
  add_json_result "pass" "user-scope" "Diretório ~/.kiro/ encontrado"

  # --- Verificação 2: ~/.kiro/mb-baseline-version ---
  local version_file="${user_kiro_dir}/mb-baseline-version"

  if [[ -f "${version_file}" ]]; then
    local version_content
    version_content="$(tr -d '[:space:]' < "${version_file}")"
    if validate_semver "${version_content}"; then
      log_pass "mb-baseline-version: ${version_content} (semver válido)"
      add_json_result "pass" "user-scope" "mb-baseline-version: ${version_content}"
    else
      log_fail "mb-baseline-version contém valor inválido: '${version_content}' (esperado: MAJOR.MINOR.PATCH)"
      add_json_result "fail" "user-scope" "mb-baseline-version: valor inválido (${version_content})"
    fi
  else
    log_fail "mb-baseline-version ausente em ${user_kiro_dir}"
    add_json_result "fail" "user-scope" "mb-baseline-version ausente"
    log_info "Execute: bootstrap.sh --scope user"
  fi

  # --- Verificação 3: Steering files do baseline ---
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi
  log_info "=== Steering Files (Baseline) ==="

  local baseline_steering_dir="${REPO_ROOT}/baselines/global/steering"

  if [[ -d "${baseline_steering_dir}" ]]; then
    local steering_checked=false

    while IFS= read -r -d '' src_file; do
      local src_name
      src_name="$(basename "${src_file}")"

      # Pular README.md
      [[ "${src_name}" == "README.md" ]] && continue

      steering_checked=true
      local expected_file="${user_kiro_dir}/steering/$(add_prefix "${src_name}")"

      if [[ -f "${expected_file}" ]]; then
        if cmp -s "${src_file}" "${expected_file}"; then
          log_pass "steering/$(add_prefix "${src_name}"): idêntico à fonte"
          add_json_result "pass" "user-scope" "steering/$(add_prefix "${src_name}"): presente e idêntico"
        else
          log_warn "steering/$(add_prefix "${src_name}"): conteúdo difere da fonte"
          add_json_result "warn" "user-scope" "steering/$(add_prefix "${src_name}"): presente mas desatualizado"
          if [[ "${VERBOSE}" == true ]]; then
            log_detail "Diferenças:"
            diff --unified=3 "${src_file}" "${expected_file}" 2>/dev/null | while IFS= read -r line; do
              log_detail "  ${line}"
            done
          fi
        fi
      else
        log_fail "steering/$(add_prefix "${src_name}"): ausente"
        add_json_result "fail" "user-scope" "steering/$(add_prefix "${src_name}"): ausente"
      fi
    done < <(find "${baseline_steering_dir}" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

    if [[ "${steering_checked}" == false ]]; then
      log_info "Nenhum steering file no baseline para verificar."
    fi
  else
    log_warn "Diretório de steering do baseline não encontrado: ${baseline_steering_dir}"
    add_json_result "warn" "user-scope" "Diretório baseline/steering não encontrado"
  fi

  # --- Verificação 4: Hooks do baseline ---
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi
  log_info "=== Hooks (Baseline) ==="

  local baseline_hooks_dir="${REPO_ROOT}/baselines/global/hooks"

  if [[ -d "${baseline_hooks_dir}" ]]; then
    local hooks_checked=false

    while IFS= read -r -d '' src_file; do
      local src_name
      src_name="$(basename "${src_file}")"

      # Pular README.md
      [[ "${src_name}" == "README.md" ]] && continue

      hooks_checked=true
      local expected_file="${user_kiro_dir}/hooks/$(add_prefix "${src_name}")"

      if [[ -f "${expected_file}" ]]; then
        if cmp -s "${src_file}" "${expected_file}"; then
          log_pass "hooks/$(add_prefix "${src_name}"): idêntico à fonte"
          add_json_result "pass" "user-scope" "hooks/$(add_prefix "${src_name}"): presente e idêntico"
        else
          log_warn "hooks/$(add_prefix "${src_name}"): conteúdo difere da fonte"
          add_json_result "warn" "user-scope" "hooks/$(add_prefix "${src_name}"): presente mas desatualizado"
          if [[ "${VERBOSE}" == true ]]; then
            log_detail "Diferenças:"
            diff --unified=3 "${src_file}" "${expected_file}" 2>/dev/null | while IFS= read -r line; do
              log_detail "  ${line}"
            done
          fi
        fi
      else
        log_fail "hooks/$(add_prefix "${src_name}"): ausente"
        add_json_result "fail" "user-scope" "hooks/$(add_prefix "${src_name}"): ausente"
      fi
    done < <(find "${baseline_hooks_dir}" -maxdepth 1 -name "*.kiro.hook" -type f -print0 2>/dev/null)

    if [[ "${hooks_checked}" == false ]]; then
      log_info "Nenhum hook no baseline para verificar."
    fi
  else
    log_warn "Diretório de hooks do baseline não encontrado: ${baseline_hooks_dir}"
    add_json_result "warn" "user-scope" "Diretório baseline/hooks não encontrado"
  fi

  # --- Verificação 5: Servidores MCP do baseline ---
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi
  log_info "=== MCP Servers (Baseline) ==="

  local baseline_mcp="${REPO_ROOT}/baselines/global/mcp/mcp.json"
  local user_mcp="${user_kiro_dir}/settings/mcp.json"

  if [[ ! -f "${baseline_mcp}" ]]; then
    log_warn "Arquivo MCP do baseline não encontrado: ${baseline_mcp}"
    add_json_result "warn" "user-scope" "Arquivo MCP do baseline não encontrado"
  elif ! command -v jq &>/dev/null; then
    log_warn "jq não disponível — verificação de MCP limitada."
    add_json_result "warn" "user-scope" "jq não disponível para verificação MCP"
  elif [[ ! -f "${user_mcp}" ]]; then
    # Reportar WARN para cada servidor ausente (arquivo inteiro ausente)
    local server_keys
    server_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"
    if [[ -n "${server_keys}" ]]; then
      while IFS= read -r key; do
        log_warn "MCP server '${key}': mcp.json ausente em ${user_kiro_dir}/settings/"
        add_json_result "warn" "user-scope" "MCP server '${key}': mcp.json ausente"
      done <<< "${server_keys}"
    fi
  else
    # Verificar cada chave do baseline no user mcp.json
    local server_keys
    server_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"

    if [[ -n "${server_keys}" ]]; then
      while IFS= read -r key; do
        local user_has_key
        user_has_key="$(jq -r --arg k "${key}" '.mcpServers[$k] // empty' "${user_mcp}" 2>/dev/null)"

        if [[ -n "${user_has_key}" ]]; then
          log_pass "MCP server '${key}': presente"
          add_json_result "pass" "user-scope" "MCP server '${key}': presente"
        else
          log_warn "MCP server '${key}': ausente em ${user_kiro_dir}/settings/mcp.json"
          add_json_result "warn" "user-scope" "MCP server '${key}': ausente"
        fi
      done <<< "${server_keys}"
    else
      log_info "Nenhum servidor MCP definido no baseline."
    fi
  fi
}

# -----------------------------------------------------------------------------
# Funções de diagnóstico — Scope Workspace
# -----------------------------------------------------------------------------

doctor_workspace_scope() {
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then
    echo ""
    echo "============================================"
    echo "  mb-kiro Doctor — Scope Workspace"
    echo "============================================"
    echo ""
  fi

  # --- Validação: --target informado e existe ---
  if [[ -z "${TARGET_DIR}" ]]; then
    log_error "Argumento obrigatório ausente: --target"
    log_error "--target é obrigatório para o escopo workspace."
    exit 1
  fi

  if [[ ! -d "${TARGET_DIR}" ]]; then
    log_error "Diretório destino não encontrado: ${TARGET_DIR}"
    exit 1
  fi

  log_info "Diagnosticando workspace: ${TARGET_DIR}"
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi

  # --- Verificação 1: kiro-manifest.json ---
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ ! -f "${manifest_path}" ]]; then
    log_fail "kiro-manifest.json não encontrado em: ${TARGET_DIR}"
    add_json_result "fail" "workspace-scope" "kiro-manifest.json não encontrado"
    log_info "Execute: bootstrap.sh --scope workspace --target ${TARGET_DIR} --project-type <tipo>"
    return
  fi

  log_pass "kiro-manifest.json encontrado."
  add_json_result "pass" "workspace-scope" "kiro-manifest.json encontrado"

  # --- Verificação 2: campo baseline.scope ---
  local baseline_scope=""
  local archetype_name=""

  if command -v jq &>/dev/null; then
    baseline_scope="$(jq -r '.baseline.scope // empty' "${manifest_path}" 2>/dev/null)"
    archetype_name="$(jq -r '.archetype.name // empty' "${manifest_path}" 2>/dev/null)"
  else
    # Fallback sem jq via grep
    baseline_scope="$(grep -o '"scope"[[:space:]]*:[[:space:]]*"[^"]*"' "${manifest_path}" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"/\1/')"
    archetype_name="$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "${manifest_path}" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"/\1/')"
  fi

  if [[ -z "${baseline_scope}" ]]; then
    # Modelo legado — executar verificação completa no workspace
    log_warn "Campo baseline.scope ausente no manifest (modelo legado)."
    add_json_result "warn" "workspace-scope" "Campo baseline.scope ausente (modelo legado)"
    log_info_check "Recomendação: migre para o modelo dual-scope com: ./scripts/sync.sh --target ${TARGET_DIR} --migrate-to-user-scope"
    add_json_result "info" "workspace-scope" "Recomendação: migrar para dual-scope via sync.sh --migrate-to-user-scope"

    # Modelo legado: verificação completa baseline + archetype no workspace
    _doctor_workspace_legacy_baseline "${archetype_name}"
    _doctor_workspace_archetype "${archetype_name}"
    return
  fi

  log_pass "baseline.scope: ${baseline_scope}"
  add_json_result "pass" "workspace-scope" "baseline.scope: ${baseline_scope}"

  # --- Verificação 3: Se baseline.scope == "user", verificar ~/.kiro/mb-baseline-version ---
  if [[ "${baseline_scope}" == "user" ]]; then
    if is_ci_environment; then
      log_info_check "Verificação de ~/.kiro/mb-baseline-version omitida por ambiente CI."
      add_json_result "info" "workspace-scope" "Verificação user-scope omitida por ambiente CI"
    else
      local user_kiro_dir
      user_kiro_dir="$(get_user_kiro_dir)"
      local version_file="${user_kiro_dir}/mb-baseline-version"

      if [[ -f "${version_file}" ]]; then
        local version_content
        version_content="$(tr -d '[:space:]' < "${version_file}")"
        if validate_semver "${version_content}"; then
          log_pass "~/.kiro/mb-baseline-version: ${version_content}"
          add_json_result "pass" "workspace-scope" "~/.kiro/mb-baseline-version: ${version_content}"
        else
          log_warn "~/.kiro/mb-baseline-version contém valor inválido: '${version_content}'"
          add_json_result "warn" "workspace-scope" "~/.kiro/mb-baseline-version: valor inválido"
          log_info "Execute: bootstrap.sh --scope user"
        fi
      else
        log_warn "~/.kiro/mb-baseline-version ausente."
        add_json_result "warn" "workspace-scope" "~/.kiro/mb-baseline-version ausente"
        log_info "Execute: bootstrap.sh --scope user"
      fi
    fi
  fi

  # --- Verificação 4: Artefatos do archetype ---
  _doctor_workspace_archetype "${archetype_name}"

  # --- Verificação 5: Detecção de overrides ---
  if [[ "${baseline_scope}" == "user" ]]; then
    _doctor_workspace_detect_overrides
  fi
}

# Verifica artefatos do archetype no workspace comparando com a fonte
# $1 = archetype_name
_doctor_workspace_archetype() {
  local archetype_name="${1:-}"

  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi
  log_info "=== Archetype ==="

  if [[ -z "${archetype_name}" ]]; then
    log_warn "Não foi possível determinar o archetype (jq ausente ou manifest incompleto)."
    add_json_result "warn" "workspace-scope" "Archetype não determinado"
    return
  fi

  local archetype_dir="${REPO_ROOT}/archetypes/${archetype_name}"

  if [[ ! -d "${archetype_dir}" ]]; then
    log_fail "Archetype '${archetype_name}' não encontrado no repositório mb-kiro."
    add_json_result "fail" "workspace-scope" "Archetype '${archetype_name}' não encontrado"
    return
  fi

  log_pass "Archetype: ${archetype_name}"
  add_json_result "pass" "workspace-scope" "Archetype: ${archetype_name}"

  # Comparar artefatos por categoria
  local check_dirs=("steering:*.md" "skills:*.md" "hooks:*.kiro.hook" "agents:*.md")

  for entry in "${check_dirs[@]}"; do
    local dir_name="${entry%%:*}"
    local pattern="${entry##*:}"
    local src_dir="${archetype_dir}/${dir_name}"
    local dest_dir="${TARGET_DIR}/.kiro/${dir_name}"

    if [[ ! -d "${src_dir}" ]]; then
      continue
    fi

    # Contar arquivos fonte (exceto README.md)
    local src_files=()
    while IFS= read -r -d '' f; do
      local fname
      fname="$(basename "${f}")"
      [[ "${fname}" == "README.md" ]] && continue
      src_files+=("${f}")
    done < <(find "${src_dir}" -maxdepth 1 -name "${pattern}" -type f -print0 2>/dev/null)

    if [[ ${#src_files[@]} -eq 0 ]]; then
      continue
    fi

    if [[ ! -d "${dest_dir}" ]]; then
      # Verificar se há exceção para o diretório inteiro
      local dir_rule="archetype.${dir_name}"
      if check_exception "${dir_rule}" "workspace-scope" "Diretório ausente com exceção: ${dir_name}"; then
        continue
      fi
      log_fail "${dir_name}: diretório .kiro/${dir_name}/ não encontrado"
      add_json_result "fail" "workspace-scope" "${dir_name}: diretório .kiro/${dir_name}/ ausente"
      continue
    fi

    # Verificar cada arquivo individualmente
    for src_file in "${src_files[@]}"; do
      local src_fname
      src_fname="$(basename "${src_file}")"
      local dest_file="${dest_dir}/${src_fname}"

      # Rule para exceções
      local archetype_rule="archetype.${dir_name}.${src_fname%.*}"

      if [[ -f "${dest_file}" ]]; then
        if cmp -s "${src_file}" "${dest_file}"; then
          log_pass "${dir_name}/${src_fname}: idêntico à fonte"
          add_json_result "pass" "workspace-scope" "${dir_name}/${src_fname}: presente e idêntico"
        else
          # Verificar exceção
          if check_exception "${archetype_rule}" "workspace-scope" "Desatualizado com exceção: ${dir_name}/${src_fname}"; then
            continue
          fi
          log_warn "${dir_name}/${src_fname}: conteúdo difere da fonte"
          add_json_result "warn" "workspace-scope" "${dir_name}/${src_fname}: presente mas desatualizado"
          if [[ "${VERBOSE}" == true ]]; then
            log_detail "Diferenças:"
            diff --unified=3 "${src_file}" "${dest_file}" 2>/dev/null | while IFS= read -r line; do
              log_detail "  ${line}"
            done
          fi
        fi
      else
        # Verificar exceção para ausente
        if check_exception "${archetype_rule}" "workspace-scope" "Ausente com exceção: ${dir_name}/${src_fname}"; then
          continue
        fi
        log_fail "${dir_name}/${src_fname}: ausente"
        add_json_result "fail" "workspace-scope" "${dir_name}/${src_fname}: ausente"
      fi
    done
  done
}

# Detecta overrides: steering/hook do workspace que corresponde a artefato do baseline
_doctor_workspace_detect_overrides() {
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi
  log_info "=== Detecção de Overrides ==="

  local workspace_steering_dir="${TARGET_DIR}/.kiro/steering"
  local workspace_hooks_dir="${TARGET_DIR}/.kiro/hooks"
  local baseline_steering_dir="${REPO_ROOT}/baselines/global/steering"
  local baseline_hooks_dir="${REPO_ROOT}/baselines/global/hooks"
  local overrides_found=false

  # Verificar steering overrides
  if [[ -d "${workspace_steering_dir}" && -d "${baseline_steering_dir}" ]]; then
    while IFS= read -r -d '' baseline_file; do
      local baseline_fname
      baseline_fname="$(basename "${baseline_file}")"

      # Pular README.md
      [[ "${baseline_fname}" == "README.md" ]] && continue

      # Verificar se workspace tem arquivo com mesmo nome
      if [[ -f "${workspace_steering_dir}/${baseline_fname}" ]]; then
        log_info_check "Override: steering/${baseline_fname} (workspace sobrescreve baseline mb--${baseline_fname})"
        add_json_result "info" "workspace-scope" "Override: steering/${baseline_fname} sobrescreve baseline mb--${baseline_fname}"
        overrides_found=true
      fi
    done < <(find "${baseline_steering_dir}" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
  fi

  # Verificar hook overrides
  if [[ -d "${workspace_hooks_dir}" && -d "${baseline_hooks_dir}" ]]; then
    while IFS= read -r -d '' baseline_file; do
      local baseline_fname
      baseline_fname="$(basename "${baseline_file}")"

      # Pular README.md
      [[ "${baseline_fname}" == "README.md" ]] && continue

      # Verificar se workspace tem hook com mesmo nome
      if [[ -f "${workspace_hooks_dir}/${baseline_fname}" ]]; then
        log_info_check "Override: hooks/${baseline_fname} (workspace sobrescreve baseline mb--${baseline_fname})"
        add_json_result "info" "workspace-scope" "Override: hooks/${baseline_fname} sobrescreve baseline mb--${baseline_fname}"
        overrides_found=true
      fi
    done < <(find "${baseline_hooks_dir}" -maxdepth 1 -name "*.kiro.hook" -type f -print0 2>/dev/null)
  fi

  if [[ "${overrides_found}" == false ]]; then
    log_info "Nenhum override detectado."
  fi
}

# Verificação do baseline no workspace para modelo legado (baseline + archetype juntos no workspace)
# $1 = archetype_name
_doctor_workspace_legacy_baseline() {
  local archetype_name="${1:-}"

  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then echo ""; fi
  log_info "=== Baseline no Workspace (Modelo Legado) ==="

  local kiro_steering_dir="${TARGET_DIR}/.kiro/steering"
  local baseline_steering_dir="${REPO_ROOT}/baselines/global/steering"

  # Verificar steering files do baseline no workspace
  if [[ -d "${baseline_steering_dir}" ]]; then
    while IFS= read -r -d '' src_file; do
      local src_name
      src_name="$(basename "${src_file}")"

      [[ "${src_name}" == "README.md" ]] && continue

      if [[ -f "${kiro_steering_dir}/${src_name}" ]]; then
        if cmp -s "${src_file}" "${kiro_steering_dir}/${src_name}"; then
          log_pass "baseline/steering/${src_name}: idêntico"
          add_json_result "pass" "workspace-scope" "baseline/steering/${src_name}: atualizado"
        else
          local rule_name="baseline.${src_name%.md}"
          if check_exception "${rule_name}" "workspace-scope" "Desatualizado com exceção: baseline/${src_name}"; then
            continue
          fi
          log_warn "baseline/steering/${src_name}: desatualizado"
          add_json_result "warn" "workspace-scope" "baseline/steering/${src_name}: desatualizado"
          if [[ "${VERBOSE}" == true ]]; then
            log_detail "Diferenças:"
            diff --unified=3 "${src_file}" "${kiro_steering_dir}/${src_name}" 2>/dev/null | while IFS= read -r line; do
              log_detail "  ${line}"
            done
          fi
        fi
      else
        local rule_name="baseline.${src_name%.md}"
        if check_exception "${rule_name}" "workspace-scope" "Ausente com exceção: baseline/${src_name}"; then
          continue
        fi
        log_fail "baseline/steering/${src_name}: ausente no workspace"
        add_json_result "fail" "workspace-scope" "baseline/steering/${src_name}: ausente"
      fi
    done < <(find "${baseline_steering_dir}" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
  fi

  # Verificar hooks do baseline no workspace
  local kiro_hooks_dir="${TARGET_DIR}/.kiro/hooks"
  local baseline_hooks_dir="${REPO_ROOT}/baselines/global/hooks"

  if [[ -d "${baseline_hooks_dir}" ]]; then
    while IFS= read -r -d '' src_file; do
      local src_name
      src_name="$(basename "${src_file}")"

      [[ "${src_name}" == "README.md" ]] && continue

      if [[ -f "${kiro_hooks_dir}/${src_name}" ]]; then
        if cmp -s "${src_file}" "${kiro_hooks_dir}/${src_name}"; then
          log_pass "baseline/hooks/${src_name}: idêntico"
          add_json_result "pass" "workspace-scope" "baseline/hooks/${src_name}: atualizado"
        else
          local rule_name="baseline.hooks.${src_name%.kiro.hook}"
          if check_exception "${rule_name}" "workspace-scope" "Desatualizado com exceção: baseline/hooks/${src_name}"; then
            continue
          fi
          log_warn "baseline/hooks/${src_name}: desatualizado"
          add_json_result "warn" "workspace-scope" "baseline/hooks/${src_name}: desatualizado"
        fi
      else
        local rule_name="baseline.hooks.${src_name%.kiro.hook}"
        if check_exception "${rule_name}" "workspace-scope" "Ausente com exceção: baseline/hooks/${src_name}"; then
          continue
        fi
        log_fail "baseline/hooks/${src_name}: ausente no workspace"
        add_json_result "fail" "workspace-scope" "baseline/hooks/${src_name}: ausente"
      fi
    done < <(find "${baseline_hooks_dir}" -maxdepth 1 -name "*.kiro.hook" -type f -print0 2>/dev/null)
  fi

  # Verificar MCP do baseline no workspace (modelo legado)
  local baseline_mcp="${REPO_ROOT}/baselines/global/mcp/mcp.json"
  local workspace_mcp="${TARGET_DIR}/.kiro/settings/mcp.json"

  if [[ -f "${baseline_mcp}" ]] && command -v jq &>/dev/null; then
    if [[ -f "${workspace_mcp}" ]]; then
      local server_keys
      server_keys="$(jq -r '.mcpServers | keys[]' "${baseline_mcp}" 2>/dev/null)"

      if [[ -n "${server_keys}" ]]; then
        while IFS= read -r key; do
          local ws_has_key
          ws_has_key="$(jq -r --arg k "${key}" '.mcpServers[$k] // empty' "${workspace_mcp}" 2>/dev/null)"

          if [[ -n "${ws_has_key}" ]]; then
            log_pass "baseline/mcp server '${key}': presente"
            add_json_result "pass" "workspace-scope" "baseline/mcp server '${key}': presente"
          else
            log_warn "baseline/mcp server '${key}': ausente no workspace"
            add_json_result "warn" "workspace-scope" "baseline/mcp server '${key}': ausente"
          fi
        done <<< "${server_keys}"
      fi
    else
      log_warn "mcp.json ausente no workspace (.kiro/settings/mcp.json)"
      add_json_result "warn" "workspace-scope" "mcp.json ausente no workspace"
    fi
  fi
}

# -----------------------------------------------------------------------------
# Funções de diagnóstico — Legado (fluxo original para projetos sem baseline.scope)
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

doctor_legacy() {
  # Fluxo original: verifica baseline + archetype no workspace
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then
    echo ""
    echo "============================================"
    echo "  mb-kiro Doctor — MonteBravo (Legado)"
    echo "============================================"
    log_info "Diagnosticando: ${TARGET_DIR}"
    echo ""
  fi

  log_info_check "Projeto no modelo legado (sem baseline.scope no manifest). Recomendação: migre para o modelo dual-scope com:"
  add_json_result "info" "legacy" "Projeto no modelo legado. Recomendação: migrar para dual-scope"
  log_info "  ./scripts/sync.sh --target ${TARGET_DIR} --migrate-to-user-scope"

  check_manifest
  check_baseline
  check_archetype
  check_powers
  check_general_health
}

# -----------------------------------------------------------------------------
# Relatório
# -----------------------------------------------------------------------------

print_summary() {
  local total=$((CHECKS_PASSED + CHECKS_WARNED + CHECKS_FAILED + CHECKS_INFO))
  local scope_label="${SCOPE:-both}"

  echo ""
  echo "============================================"
  echo "  Resumo do Diagnóstico"
  echo "  Executado em: ${TIMESTAMP}"
  if [[ -n "${TARGET_DIR}" ]]; then
    echo "  Projeto: ${TARGET_DIR}"
  fi
  echo "  Escopo: ${scope_label}"
  echo "============================================"
  echo -e "  ${GREEN}Passou:${NC}    ${CHECKS_PASSED}/${total}"
  echo -e "  ${YELLOW}Atenção:${NC}   ${CHECKS_WARNED}/${total}"
  echo -e "  ${RED}Falhou:${NC}    ${CHECKS_FAILED}/${total}"
  echo -e "  ${BLUE}Info:${NC}      ${CHECKS_INFO}/${total}"
  echo "============================================"

  if [[ ${CHECKS_FAILED} -gt 0 ]]; then
    echo ""
    log_error "${CHECKS_FAILED} problema(s) crítico(s). Revise os itens [FAIL] acima."
    echo ""
    exit 1
  elif [[ ${CHECKS_WARNED} -gt 0 ]]; then
    echo ""
    log_warn "${CHECKS_WARNED} item(ns) requerem atenção."
    if [[ "${VERBOSE}" == false ]]; then
      log_info "Use --verbose para ver detalhes dos warnings."
    fi
    echo ""
    exit 0
  else
    echo ""
    log_pass "Projeto em conformidade com os padrões Kiro!"
    echo ""
    exit 0
  fi
}

print_json_report() {
  local scope_label="${SCOPE:-both}"
  local target_label="${TARGET_DIR:-~/.kiro}"

  if command -v jq &>/dev/null; then
    echo "${JSON_RESULTS}" | jq --arg ts "${TIMESTAMP}" --arg tgt "${target_label}" --arg sc "${scope_label}" \
      --argjson passed "${CHECKS_PASSED}" --argjson warned "${CHECKS_WARNED}" \
      --argjson failed "${CHECKS_FAILED}" --argjson info "${CHECKS_INFO}" '{
      timestamp: $ts,
      target: $tgt,
      scope: $sc,
      summary: {
        passed: $passed,
        warned: $warned,
        failed: $failed,
        info: $info
      },
      results: .
    }'
  else
    log_error "jq necessário para output JSON."
    exit 1
  fi

  # Exit code 1 se há falhas, 0 caso contrário
  if [[ ${CHECKS_FAILED} -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

# -----------------------------------------------------------------------------
# Fluxo principal
# -----------------------------------------------------------------------------

main() {
  parse_args "$@"

  # Caso 1: --scope informado — usar novo modelo
  if [[ -n "${SCOPE}" ]]; then
    case "${SCOPE}" in
      user)
        doctor_user_scope
        ;;
      workspace)
        doctor_workspace_scope
        ;;
    esac

    if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
      print_json_report
    else
      print_summary
    fi
    return
  fi

  # Caso 2: --scope NÃO informado + --target informado
  # Verificar se é modelo legado ou executar ambos escopos
  local manifest_path="${TARGET_DIR}/kiro-manifest.json"

  if [[ -f "${manifest_path}" ]] && is_legacy_manifest "${manifest_path}"; then
    # Modelo legado: fluxo original (baseline + archetype no workspace)
    doctor_legacy

    if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
      print_json_report
    else
      print_summary
    fi
    return
  fi

  # Modelo novo ou manifest ausente: executar ambos escopos e consolidar
  if [[ "${OUTPUT_FORMAT}" == "text" ]]; then
    echo ""
    echo "============================================"
    echo "  mb-kiro Doctor — MonteBravo"
    echo "============================================"
    log_info "Diagnosticando ambos escopos (user + workspace)"
    echo ""
  fi

  # Executar escopo user (pula em CI)
  if is_ci_environment; then
    log_info_check "Verificação user-scope omitida por ambiente CI."
    add_json_result "info" "user-scope" "Verificação user-scope omitida por ambiente CI"
  else
    doctor_user_scope
  fi

  # Executar escopo workspace
  doctor_workspace_scope

  if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
    print_json_report
  else
    print_summary
  fi
}

main "$@"
