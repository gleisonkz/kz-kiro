#!/usr/bin/env bats
# =============================================================================
# Property Test 5: Dry-run não modifica filesystem
# Feature: baseline-global
# Property 5: Dry-run não modifica filesystem
#
# Para qualquer estado do filesystem e qualquer combinação válida de argumentos
# com --dry-run, a execução do script (bootstrap ou sync) SHALL não criar,
# modificar ou deletar nenhum arquivo no diretório alvo.
#
# **Validates: Requirements 4.6, 5.6**
# =============================================================================

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'
  load '../helpers/generators'

  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)/scripts"
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
}

teardown() {
  cleanup_fixtures
}

# --- Funções auxiliares ---

# Captura um snapshot completo do filesystem de um diretório.
# Inclui: listagem recursiva de arquivos + checksum MD5 de cada arquivo.
# Retorna uma string determinística e ordenada representando o estado completo.
capture_fs_snapshot() {
  local dir="$1"

  if [[ ! -d "${dir}" ]]; then
    echo ""
    return
  fi

  # Lista todos os arquivos e diretórios com metadados relevantes
  # Formato: tipo|caminho_relativo|checksum (para arquivos)
  {
    # Listar diretórios
    find "${dir}" -type d | sort | while IFS= read -r d; do
      local rel="${d#${dir}}"
      echo "d|${rel:-/}"
    done

    # Listar arquivos com checksums
    find "${dir}" -type f | sort | while IFS= read -r f; do
      local rel="${f#${dir}}"
      local checksum
      checksum=$(md5 -q "${f}" 2>/dev/null || md5sum "${f}" 2>/dev/null | awk '{print $1}')
      echo "f|${rel}|${checksum}"
    done

    # Listar symlinks
    find "${dir}" -type l | sort | while IFS= read -r l; do
      local rel="${l#${dir}}"
      local target
      target=$(readlink "${l}" 2>/dev/null || echo "?")
      echo "l|${rel}|${target}"
    done
  } | sort
}

# Gera um estado de diretório aleatório para simular um projeto existente.
# Cria arquivos e subdiretórios aleatórios dentro do diretório fornecido.
generate_random_dir_state() {
  local dir="$1"

  # Quantidade aleatória de arquivos existentes (0-5)
  local num_files
  num_files=$(_rand_int 0 5)

  local i
  for (( i = 0; i < num_files; i++ )); do
    local subdir
    # Aleatoriamente colocar em subdiretórios
    case $(( RANDOM % 4 )) in
      0) subdir=".kiro/steering" ;;
      1) subdir=".kiro/settings" ;;
      2) subdir=".kiro/hooks" ;;
      3) subdir=".kiro/skills" ;;
    esac

    mkdir -p "${dir}/${subdir}"

    local filename="$(_rand_lower "$(_rand_int 4 10)").md"
    # Conteúdo aleatório para cada arquivo
    _rand_alphanum "$(_rand_int 20 200)" > "${dir}/${subdir}/${filename}"
  done
}

# Gera argumentos aleatórios válidos para bootstrap.sh com --dry-run
generate_bootstrap_args() {
  local target_dir="$1"

  # Tipos válidos conforme bootstrap.sh
  local project_type
  project_type=$(_rand_choice "bff-fastify" "frontend-react" "mobile-flutter")

  local args="--target ${target_dir} --project-type ${project_type} --dry-run"

  # Aleatoriamente adicionar --force
  if (( RANDOM % 2 == 0 )); then
    args="${args} --force"
  fi

  echo "${args}"
}

# Gera argumentos aleatórios válidos para sync.sh com --dry-run
generate_sync_args() {
  local target_dir="$1"

  local component
  component=$(_rand_choice "all" "baseline" "archetype" "powers")

  echo "--target ${target_dir} --component ${component} --dry-run"
}

# --- Testes de propriedade ---

@test "Property 5 — bootstrap.sh com --dry-run não modifica filesystem (100 iterações)" {
  # Pré-requisito: git e scripts devem existir
  [[ -f "${SCRIPT_DIR}/bootstrap.sh" ]] || skip "bootstrap.sh não encontrado"
  command -v git &>/dev/null || skip "git não instalado"

  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    # Criar diretório temporário com estado aleatório
    local project_dir
    project_dir="$(create_temp_project)"

    # Gerar estado aleatório no diretório do projeto
    generate_random_dir_state "${project_dir}"

    # Gerar argumentos aleatórios com --dry-run
    local args
    args="$(generate_bootstrap_args "${project_dir}")"

    # Capturar snapshot ANTES da execução
    local snapshot_before
    snapshot_before="$(capture_fs_snapshot "${project_dir}")"

    # Executar bootstrap.sh com --dry-run (ignorar exit code — pode falhar por
    # razões legítimas como archetype não encontrado, o importante é não modificar)
    bash "${SCRIPT_DIR}/bootstrap.sh" ${args} </dev/null >/dev/null 2>&1 || true

    # Capturar snapshot DEPOIS da execução
    local snapshot_after
    snapshot_after="$(capture_fs_snapshot "${project_dir}")"

    # Comparar snapshots — devem ser idênticos
    if [[ "${snapshot_before}" != "${snapshot_after}" ]]; then
      echo "FALHA na iteração ${i}: filesystem modificado com --dry-run" >&2
      echo "Args: ${args}" >&2
      echo "--- ANTES ---" >&2
      echo "${snapshot_before}" | head -20 >&2
      echo "--- DEPOIS ---" >&2
      echo "${snapshot_after}" | head -20 >&2
      echo "--- DIFF ---" >&2
      diff <(echo "${snapshot_before}") <(echo "${snapshot_after}") >&2 || true
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Dry-run do bootstrap modificou filesystem em ${failures}/100 iterações"
}

@test "Property 5 — sync.sh com --dry-run não modifica filesystem (100 iterações)" {
  # Pré-requisito: scripts devem existir
  [[ -f "${SCRIPT_DIR}/sync.sh" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário para sync.sh"

  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    # Criar diretório temporário com estado aleatório
    local project_dir
    project_dir="$(create_temp_project)"

    # Gerar estado aleatório no diretório do projeto
    generate_random_dir_state "${project_dir}"

    # Criar manifest necessário para sync.sh funcionar
    # Usar archetype aleatório válido (que exista no repositório)
    local archetype
    archetype=$(_rand_choice "bff-fastify" "frontend-react" "mobile-flutter")

    setup_manifest "${project_dir}" "{\"archetype\": {\"name\": \"${archetype}\"}}"

    # Gerar argumentos aleatórios com --dry-run
    local args
    args="$(generate_sync_args "${project_dir}")"

    # Capturar snapshot ANTES da execução
    local snapshot_before
    snapshot_before="$(capture_fs_snapshot "${project_dir}")"

    # Executar sync.sh com --dry-run (ignorar exit code)
    bash "${SCRIPT_DIR}/sync.sh" ${args} </dev/null >/dev/null 2>&1 || true

    # Capturar snapshot DEPOIS da execução
    local snapshot_after
    snapshot_after="$(capture_fs_snapshot "${project_dir}")"

    # Comparar snapshots — devem ser idênticos
    if [[ "${snapshot_before}" != "${snapshot_after}" ]]; then
      echo "FALHA na iteração ${i}: filesystem modificado com --dry-run (sync)" >&2
      echo "Args: ${args}" >&2
      echo "--- ANTES ---" >&2
      echo "${snapshot_before}" | head -20 >&2
      echo "--- DEPOIS ---" >&2
      echo "${snapshot_after}" | head -20 >&2
      echo "--- DIFF ---" >&2
      diff <(echo "${snapshot_before}") <(echo "${snapshot_after}") >&2 || true
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Dry-run do sync modificou filesystem em ${failures}/100 iterações"
}

# --- Testes de borda ---

@test "Property 5 — borda: bootstrap --dry-run em diretório vazio não cria nada" {
  [[ -f "${SCRIPT_DIR}/bootstrap.sh" ]] || skip "bootstrap.sh não encontrado"

  local project_dir
  project_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-empty-XXXXXX")"
  mkdir -p "${project_dir}"
  echo "${project_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  local snapshot_before
  snapshot_before="$(capture_fs_snapshot "${project_dir}")"

  bash "${SCRIPT_DIR}/bootstrap.sh" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --dry-run </dev/null >/dev/null 2>&1 || true

  local snapshot_after
  snapshot_after="$(capture_fs_snapshot "${project_dir}")"

  [[ "${snapshot_before}" == "${snapshot_after}" ]] || {
    echo "Filesystem foi modificado em diretório vazio com --dry-run" >&2
    diff <(echo "${snapshot_before}") <(echo "${snapshot_after}") >&2 || true
    return 1
  }
}

@test "Property 5 — borda: sync --dry-run com manifest existente não altera nada" {
  [[ -f "${SCRIPT_DIR}/sync.sh" ]] || skip "sync.sh não encontrado"
  command -v jq &>/dev/null || skip "jq necessário"

  local project_dir
  project_dir="$(create_temp_project)"
  setup_manifest "${project_dir}" '{"archetype": {"name": "bff-fastify"}}'

  # Adicionar arquivos pré-existentes para simular projeto real
  echo "conteúdo original" > "${project_dir}/.kiro/steering/test-file.md"
  echo '{"test": true}' > "${project_dir}/.kiro/settings/custom.json"

  local snapshot_before
  snapshot_before="$(capture_fs_snapshot "${project_dir}")"

  bash "${SCRIPT_DIR}/sync.sh" \
    --target "${project_dir}" \
    --component all \
    --dry-run </dev/null >/dev/null 2>&1 || true

  local snapshot_after
  snapshot_after="$(capture_fs_snapshot "${project_dir}")"

  [[ "${snapshot_before}" == "${snapshot_after}" ]] || {
    echo "Sync --dry-run modificou arquivos existentes" >&2
    diff <(echo "${snapshot_before}") <(echo "${snapshot_after}") >&2 || true
    return 1
  }
}

@test "Property 5 — borda: bootstrap --dry-run com --force também não modifica" {
  [[ -f "${SCRIPT_DIR}/bootstrap.sh" ]] || skip "bootstrap.sh não encontrado"

  local project_dir
  project_dir="$(create_temp_project)"

  # Criar manifest existente (situação de conflito)
  setup_manifest "${project_dir}"

  # Adicionar steering files existentes
  echo "arquivo que não deveria ser sobrescrito" > "${project_dir}/.kiro/steering/existing.md"

  local snapshot_before
  snapshot_before="$(capture_fs_snapshot "${project_dir}")"

  bash "${SCRIPT_DIR}/bootstrap.sh" \
    --target "${project_dir}" \
    --project-type bff-fastify \
    --dry-run \
    --force </dev/null >/dev/null 2>&1 || true

  local snapshot_after
  snapshot_after="$(capture_fs_snapshot "${project_dir}")"

  [[ "${snapshot_before}" == "${snapshot_after}" ]] || {
    echo "Bootstrap --dry-run --force modificou filesystem" >&2
    diff <(echo "${snapshot_before}") <(echo "${snapshot_after}") >&2 || true
    return 1
  }
}
