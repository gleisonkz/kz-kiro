#!/usr/bin/env bash
# Helpers de asserção customizados para testes bats.
# Integra com bats-assert para mensagens de erro descritivas.
# Uso: load '../helpers/assertions'

# Carrega bats-support e bats-assert
load "${BATS_TEST_DIRNAME}/../lib/bats-support/load"
load "${BATS_TEST_DIRNAME}/../lib/bats-assert/load"

# Compara dois arquivos byte-a-byte.
# Falha com mensagem descritiva se forem diferentes.
# Uso: assert_file_identical <arquivo_esperado> <arquivo_real>
assert_file_identical() {
  local expected="$1"
  local actual="$2"

  if [[ ! -f "${expected}" ]]; then
    batslib_print_kv_single_or_multi 8 \
      'expected' "${expected}" \
      | batslib_decorate 'arquivo esperado não existe' \
      | fail
    return $?
  fi

  if [[ ! -f "${actual}" ]]; then
    batslib_print_kv_single_or_multi 8 \
      'actual' "${actual}" \
      | batslib_decorate 'arquivo real não existe' \
      | fail
    return $?
  fi

  if ! cmp -s "${expected}" "${actual}"; then
    local diff_output
    diff_output="$(diff --unified=3 "${expected}" "${actual}" 2>/dev/null || true)"
    {
      batslib_print_kv_single_or_multi 8 \
        'expected' "${expected}" \
        'actual'   "${actual}"
      if [[ -n "${diff_output}" ]]; then
        echo "-- diff --"
        echo "${diff_output}"
      fi
    } | batslib_decorate 'arquivos não são idênticos' \
      | fail
    return $?
  fi
}

# Valida que um arquivo contém JSON válido (usa jq).
# Uso: assert_json_valid <caminho_arquivo>
assert_json_valid() {
  local file="$1"

  if [[ ! -f "${file}" ]]; then
    batslib_print_kv_single_or_multi 8 \
      'path' "${file}" \
      | batslib_decorate 'arquivo não existe' \
      | fail
    return $?
  fi

  local jq_error
  if ! jq_error="$(jq '.' "${file}" 2>&1 >/dev/null)"; then
    {
      batslib_print_kv_single_or_multi 8 \
        'path'  "${file}" \
        'error' "${jq_error}"
    } | batslib_decorate 'arquivo não contém JSON válido' \
      | fail
    return $?
  fi
}

# Executa um comando e verifica se o exit code corresponde ao esperado.
# Uso: assert_exit_code <expected_code> <command> [args...]
assert_exit_code() {
  local expected_code="$1"
  shift
  local actual_code=0

  # Executa o comando capturando o exit code
  "$@" >/dev/null 2>&1 || actual_code=$?

  if [[ "${actual_code}" -ne "${expected_code}" ]]; then
    {
      batslib_print_kv_single_or_multi 8 \
        'command'  "$*" \
        'expected' "${expected_code}" \
        'actual'   "${actual_code}"
    } | batslib_decorate 'exit code não corresponde ao esperado' \
      | fail
    return $?
  fi
}

# Verifica que um comando não modifica o filesystem.
# Tira snapshot antes, executa o comando, compara depois.
# Uso: assert_no_fs_changes <diretório_monitorado> <command> [args...]
assert_no_fs_changes() {
  local watch_dir="$1"
  shift

  if [[ ! -d "${watch_dir}" ]]; then
    batslib_print_kv_single_or_multi 8 \
      'directory' "${watch_dir}" \
      | batslib_decorate 'diretório monitorado não existe' \
      | fail
    return $?
  fi

  # Snapshot antes: lista recursiva com checksums
  local snapshot_before snapshot_after
  snapshot_before="$(find "${watch_dir}" -type f -exec md5sum {} \; 2>/dev/null | sort)"

  # Executa o comando (ignora exit code)
  "$@" >/dev/null 2>&1 || true

  # Snapshot depois
  snapshot_after="$(find "${watch_dir}" -type f -exec md5sum {} \; 2>/dev/null | sort)"

  if [[ "${snapshot_before}" != "${snapshot_after}" ]]; then
    local diff_output
    diff_output="$(diff <(echo "${snapshot_before}") <(echo "${snapshot_after}") 2>/dev/null || true)"
    {
      batslib_print_kv_single_or_multi 8 \
        'directory' "${watch_dir}" \
        'command'   "$*"
      if [[ -n "${diff_output}" ]]; then
        echo "-- mudanças detectadas --"
        echo "${diff_output}"
      fi
    } | batslib_decorate 'filesystem foi modificado quando não deveria' \
      | fail
    return $?
  fi
}

# Valida que um arquivo JSON possui um campo com valor específico (usa jq).
# Uso: assert_json_field <caminho_arquivo> <jq_path> <valor_esperado>
#   jq_path: expressão jq (ex: '.baseline.version', '.summary.passed')
#   valor_esperado: valor esperado como string (jq raw output)
assert_json_field() {
  local file="$1"
  local jq_path="$2"
  local expected_value="$3"

  if [[ ! -f "${file}" ]]; then
    batslib_print_kv_single_or_multi 8 \
      'path' "${file}" \
      | batslib_decorate 'arquivo não existe' \
      | fail
    return $?
  fi

  local actual_value
  actual_value="$(jq -r "${jq_path}" "${file}" 2>/dev/null)"
  local jq_exit=$?

  if [[ ${jq_exit} -ne 0 ]]; then
    {
      batslib_print_kv_single_or_multi 8 \
        'path'     "${file}" \
        'jq_path'  "${jq_path}"
    } | batslib_decorate 'erro ao executar jq no arquivo' \
      | fail
    return $?
  fi

  if [[ "${actual_value}" != "${expected_value}" ]]; then
    {
      batslib_print_kv_single_or_multi 8 \
        'path'     "${file}" \
        'jq_path'  "${jq_path}" \
        'expected' "${expected_value}" \
        'actual'   "${actual_value}"
    } | batslib_decorate 'campo JSON não corresponde ao esperado' \
      | fail
    return $?
  fi
}
