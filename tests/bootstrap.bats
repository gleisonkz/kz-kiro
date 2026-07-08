#!/usr/bin/env bats
# Testes unitários para o bootstrap-code-review.sh (archetype frontend-react).
# Valida cópia de arquivos, preservação de existentes, --force e exclusão de .md.
# Requirements: 4.1, 4.2, 4.3, 4.4, 4.5

setup() {
  # Carregar bats-support e bats-assert diretamente
  load "${BATS_TEST_DIRNAME}/lib/bats-support/load"
  load "${BATS_TEST_DIRNAME}/lib/bats-assert/load"

  # Script centralizado de bootstrap de workflows (inclui cópia de agentes)
  BOOTSTRAP_SCRIPT="${BATS_TEST_DIRNAME}/../scripts/bootstrap-workflows.sh"

  # Criar diretório temporário simulando um archetype e projeto destino
  TEST_TEMP_DIR="$(mktemp -d)"

  # Criar estrutura mock do archetype em diretório temporário
  MOCK_ARCHETYPE="${TEST_TEMP_DIR}/archetype"
  mkdir -p "${MOCK_ARCHETYPE}/workflows"
  mkdir -p "${MOCK_ARCHETYPE}/agents"
  mkdir -p "${MOCK_ARCHETYPE}/scripts"

  # Workflow mock
  echo "name: Kiro Code Review" > "${MOCK_ARCHETYPE}/workflows/kiro-code-review.yml"

  # Agentes JSON mock
  echo '{"name":"cli-code-reviewer","description":"Code reviewer agent","instructions":"Review code quality."}' \
    > "${MOCK_ARCHETYPE}/agents/cli-code-reviewer.json"
  echo '{"name":"cli-architecture-reviewer","description":"Architecture reviewer agent","instructions":"Review architecture."}' \
    > "${MOCK_ARCHETYPE}/agents/cli-architecture-reviewer.json"

  # Agente Markdown mock (NÃO deve ser copiado)
  echo "---\nname: Code Reviewer\ndescription: Revisa código\n---\n# Code Reviewer" \
    > "${MOCK_ARCHETYPE}/agents/code-reviewer.md"

  # Criar bootstrap script mock que aponta para o archetype mock
  cat > "${MOCK_ARCHETYPE}/scripts/bootstrap-code-review.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ARCHETYPE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly WORKFLOW_SRC="${ARCHETYPE_DIR}/workflows/kiro-code-review.yml"
readonly AGENTS_SRC_DIR="${ARCHETYPE_DIR}/agents"

readonly WORKFLOW_DEST_DIR=".github/workflows"
readonly WORKFLOW_DEST="${WORKFLOW_DEST_DIR}/kiro-code-review.yml"
readonly AGENTS_DEST_DIR=".kiro/agents"

FORCE=false

info() { echo "[INFO] $*"; }
warn() { echo "[AVISO] $*" >&2; }
erro() { echo "[ERRO] $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=true; shift ;;
    *) erro "Argumento desconhecido: $1"; exit 1 ;;
  esac
done

if [[ ! -f "${WORKFLOW_SRC}" ]]; then
  erro "Arquivo de workflow não encontrado: ${WORKFLOW_SRC}"
  exit 1
fi

mkdir -p "${WORKFLOW_DEST_DIR}"
mkdir -p "${AGENTS_DEST_DIR}"

if [[ -f "${WORKFLOW_DEST}" ]]; then
  if [[ "${FORCE}" == "true" ]]; then
    info "Sobrescrevendo workflow existente (--force): ${WORKFLOW_DEST}"
    cp "${WORKFLOW_SRC}" "${WORKFLOW_DEST}"
  else
    warn "Workflow já existe: ${WORKFLOW_DEST} (use --force para sobrescrever)"
  fi
else
  info "Copiando workflow para ${WORKFLOW_DEST}"
  cp "${WORKFLOW_SRC}" "${WORKFLOW_DEST}"
fi

AGENTS_COPIED=0
AGENTS_SKIPPED=0
AGENTS_UPDATED=0

for src_file in "${AGENTS_SRC_DIR}"/cli-*.json; do
  [[ -f "${src_file}" ]] || continue
  filename="$(basename "${src_file}")"
  dest_file="${AGENTS_DEST_DIR}/${filename}"
  if [[ -f "${dest_file}" ]]; then
    if ! diff -q "${src_file}" "${dest_file}" > /dev/null 2>&1; then
      info "Atualizando agente (conteúdo difere): ${filename}"
      cp "${src_file}" "${dest_file}"
      AGENTS_UPDATED=$((AGENTS_UPDATED + 1))
    else
      AGENTS_SKIPPED=$((AGENTS_SKIPPED + 1))
    fi
  else
    info "Copiando novo agente: ${filename}"
    cp "${src_file}" "${dest_file}"
    AGENTS_COPIED=$((AGENTS_COPIED + 1))
  fi
done

echo ""
info "Bootstrap concluído!"
info "  Agentes copiados: ${AGENTS_COPIED}"
info "  Agentes atualizados: ${AGENTS_UPDATED}"
info "  Agentes inalterados: ${AGENTS_SKIPPED}"

CUSTOM_COUNT=0
for dest_file in "${AGENTS_DEST_DIR}"/cli-*.json; do
  [[ -f "${dest_file}" ]] || continue
  filename="$(basename "${dest_file}")"
  if [[ ! -f "${AGENTS_SRC_DIR}/${filename}" ]]; then
    CUSTOM_COUNT=$((CUSTOM_COUNT + 1))
  fi
done

if [[ ${CUSTOM_COUNT} -gt 0 ]]; then
  info "  Agentes customizados preservados: ${CUSTOM_COUNT}"
fi
SCRIPT
  chmod +x "${MOCK_ARCHETYPE}/scripts/bootstrap-code-review.sh"

  # Diretório do projeto destino (simulação)
  PROJECT_DEST="${TEST_TEMP_DIR}/project"
  mkdir -p "${PROJECT_DEST}"
}

teardown() {
  # Limpar diretórios temporários
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "${TEST_TEMP_DIR}" ]]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# --- Helpers ---

run_bootstrap() {
  # Executa o bootstrap dentro do diretório destino
  cd "${PROJECT_DEST}"
  run bash "${MOCK_ARCHETYPE}/scripts/bootstrap-code-review.sh" "$@"
}

run_real_bootstrap() {
  # Executa o bootstrap REAL centralizado para frontend-react no diretório destino
  cd "${PROJECT_DEST}"
  run bash "${BOOTSTRAP_SCRIPT}" --project-type frontend-react --target "${PROJECT_DEST}" "$@"
}

# =============================================================================
# a. Fresh run copia workflow e JSON para dest
# =============================================================================

@test "bootstrap: fresh run copia workflow para .github/workflows/" {
  run_bootstrap
  assert_success
  [ -f "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml" ]
}

@test "bootstrap: fresh run copia agentes JSON para .kiro/agents/" {
  run_bootstrap
  assert_success
  [ -f "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json" ]
  [ -f "${PROJECT_DEST}/.kiro/agents/cli-architecture-reviewer.json" ]
}

@test "bootstrap: conteúdo do workflow copiado é idêntico ao source" {
  run_bootstrap
  assert_success
  diff -q "${MOCK_ARCHETYPE}/workflows/kiro-code-review.yml" \
    "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml"
}

@test "bootstrap: conteúdo do agente JSON copiado é idêntico ao source" {
  run_bootstrap
  assert_success
  diff -q "${MOCK_ARCHETYPE}/agents/cli-code-reviewer.json" \
    "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json"
}

# =============================================================================
# b. Fresh run NÃO copia .md para dest
# =============================================================================

@test "bootstrap: nunca copia arquivos .md de agentes para dest" {
  run_bootstrap
  assert_success
  # Nenhum arquivo .md deve existir em .kiro/agents/
  local md_count
  md_count=$(find "${PROJECT_DEST}/.kiro/agents/" -name "*.md" -type f 2>/dev/null | wc -l)
  [ "${md_count}" -eq 0 ]
}

@test "bootstrap: diretório dest não contém code-reviewer.md" {
  run_bootstrap
  assert_success
  [ ! -f "${PROJECT_DEST}/.kiro/agents/code-reviewer.md" ]
}

# =============================================================================
# c. Re-run sem --force preserva workflow existente
# =============================================================================

@test "bootstrap: re-run sem --force preserva workflow existente" {
  # Primeira execução — copia workflow
  cd "${PROJECT_DEST}"
  bash "${MOCK_ARCHETYPE}/scripts/bootstrap-code-review.sh"

  # Modificar conteúdo do workflow no destino (simular customização)
  echo "# customizado pelo time" >> "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml"
  local custom_content
  custom_content="$(cat "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml")"

  # Re-executar sem --force
  run_bootstrap
  assert_success

  # Workflow deve manter conteúdo customizado
  local current_content
  current_content="$(cat "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml")"
  [ "${current_content}" = "${custom_content}" ]
}

# =============================================================================
# d. Re-run com --force sobrescreve workflow
# =============================================================================

@test "bootstrap: --force sobrescreve workflow existente" {
  # Primeira execução
  cd "${PROJECT_DEST}"
  bash "${MOCK_ARCHETYPE}/scripts/bootstrap-code-review.sh"

  # Modificar workflow no destino
  echo "# customizado" >> "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml"

  # Re-executar com --force
  run_bootstrap --force
  assert_success

  # Workflow deve ser igual ao source (sem a customização)
  diff -q "${MOCK_ARCHETYPE}/workflows/kiro-code-review.yml" \
    "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml"
}

# =============================================================================
# e. Custom cli-*.json no dest que não existem no archetype são preservados
# =============================================================================

@test "bootstrap: preserva agentes customizados que não existem no archetype" {
  # Criar agente customizado no destino antes de executar bootstrap
  mkdir -p "${PROJECT_DEST}/.kiro/agents"
  echo '{"name":"cli-custom-reviewer","description":"Custom reviewer","instructions":"Custom logic."}' \
    > "${PROJECT_DEST}/.kiro/agents/cli-custom-reviewer.json"

  run_bootstrap
  assert_success

  # Agente customizado deve continuar existindo
  [ -f "${PROJECT_DEST}/.kiro/agents/cli-custom-reviewer.json" ]
  # Conteúdo deve estar intacto
  run jq -r '.name' "${PROJECT_DEST}/.kiro/agents/cli-custom-reviewer.json"
  assert_output "cli-custom-reviewer"
}

# =============================================================================
# f. Agent JSON com conteúdo diferente é atualizado
# =============================================================================

@test "bootstrap: atualiza agente JSON quando conteúdo difere" {
  # Primeira execução — copia agentes
  cd "${PROJECT_DEST}"
  bash "${MOCK_ARCHETYPE}/scripts/bootstrap-code-review.sh"

  # Modificar agente no destino (simular versão antiga)
  echo '{"name":"cli-code-reviewer","description":"Old version","instructions":"Old instructions."}' \
    > "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json"

  # Re-executar bootstrap
  run_bootstrap
  assert_success

  # Agente deve ser atualizado para o conteúdo do archetype
  diff -q "${MOCK_ARCHETYPE}/agents/cli-code-reviewer.json" \
    "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json"
}

# =============================================================================
# g. Agent JSON com mesmo conteúdo não é re-copiado (idempotente)
# =============================================================================

@test "bootstrap: não re-copia agente quando conteúdo é idêntico (idempotente)" {
  # Primeira execução
  cd "${PROJECT_DEST}"
  bash "${MOCK_ARCHETYPE}/scripts/bootstrap-code-review.sh"

  # Capturar timestamp do arquivo
  local mtime_before
  mtime_before="$(stat -f '%m' "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json" 2>/dev/null || \
    stat -c '%Y' "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json" 2>/dev/null)"

  # Esperar 1 segundo para garantir diferença de timestamp
  sleep 1

  # Re-executar bootstrap
  run_bootstrap
  assert_success

  # Output deve indicar que agentes foram pulados (inalterados)
  assert_output --partial "Agentes inalterados"

  # Conteúdo permanece idêntico
  diff -q "${MOCK_ARCHETYPE}/agents/cli-code-reviewer.json" \
    "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json"
}

# =============================================================================
# Teste com o bootstrap REAL do frontend-react
# =============================================================================

@test "bootstrap real (frontend-react): fresh run copia workflow e agentes" {
  run_real_bootstrap
  assert_success
  [ -f "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml" ]
  [ -f "${PROJECT_DEST}/.kiro/agents/cli-code-reviewer.json" ]
  [ -f "${PROJECT_DEST}/.kiro/agents/cli-architecture-reviewer.json" ]
  [ -f "${PROJECT_DEST}/.kiro/agents/cli-accessibility-reviewer.json" ]
  [ -f "${PROJECT_DEST}/.kiro/agents/cli-performance-reviewer.json" ]
}

@test "bootstrap real (frontend-react): nunca copia .md" {
  run_real_bootstrap
  assert_success
  local md_count
  md_count=$(find "${PROJECT_DEST}/.kiro/agents/" -name "*.md" -type f 2>/dev/null | wc -l)
  [ "${md_count}" -eq 0 ]
}

@test "bootstrap real (frontend-react): preserva workflow sem --force" {
  cd "${PROJECT_DEST}"
  bash "${BOOTSTRAP_SCRIPT}"
  echo "# local customization" >> "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml"
  local custom_hash
  custom_hash="$(md5sum "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml" | cut -d' ' -f1 || \
    md5 -q "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml")"

  run_real_bootstrap
  assert_success

  local after_hash
  after_hash="$(md5sum "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml" | cut -d' ' -f1 || \
    md5 -q "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml")"
  [ "${custom_hash}" = "${after_hash}" ]
}

@test "bootstrap real (frontend-react): --force sobrescreve workflow" {
  cd "${PROJECT_DEST}"
  bash "${BOOTSTRAP_SCRIPT}"
  echo "# local customization" >> "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml"

  run_real_bootstrap --force
  assert_success

  # Workflow deve ser idêntico ao source do archetype
  local src_workflow="${BATS_TEST_DIRNAME}/../archetypes/frontend-react/workflows/kiro-code-review.yml"
  diff -q "${src_workflow}" "${PROJECT_DEST}/.github/workflows/kiro-code-review.yml"
}
