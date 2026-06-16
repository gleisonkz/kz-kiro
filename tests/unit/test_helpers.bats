#!/usr/bin/env bats
# Testes unitários para validar que os helpers setup.bash e assertions.bash funcionam corretamente.

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'
}

teardown() {
  cleanup_fixtures
}

# --- setup.bash ---

@test "create_temp_project: cria diretório com estrutura .kiro/" {
  local project_dir
  project_dir="$(create_temp_project)"

  [ -d "${project_dir}" ]
  [ -d "${project_dir}/.kiro/steering" ]
  [ -d "${project_dir}/.kiro/settings" ]
  [ -d "${project_dir}/.kiro/hooks" ]
  [ -d "${project_dir}/.kiro/specs" ]
  [ -d "${project_dir}/.kiro/skills" ]
  [ -d "${project_dir}/.kiro/agents" ]
}

@test "create_baseline_fixture: cria diretório com artefatos do baseline" {
  local baseline_dir
  baseline_dir="$(create_baseline_fixture)"

  [ -d "${baseline_dir}" ]
  [ -f "${baseline_dir}/VERSION" ]
  [ -f "${baseline_dir}/CHANGELOG.md" ]
  [ -f "${baseline_dir}/steering/engineering-principles.md" ]
  [ -f "${baseline_dir}/steering/security-baseline.md" ]
  [ -f "${baseline_dir}/mcp/mcp.json" ]
  [ -f "${baseline_dir}/hooks/kiro-doctor.kiro.hook" ]
}

@test "create_baseline_fixture: VERSION tem formato semver sem newline" {
  local baseline_dir
  baseline_dir="$(create_baseline_fixture)"

  local version
  version="$(cat "${baseline_dir}/VERSION")"
  [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "setup_manifest: gera kiro-manifest.json com campos default" {
  local project_dir
  project_dir="$(create_temp_project)"
  setup_manifest "${project_dir}"

  [ -f "${project_dir}/.kiro/kiro-manifest.json" ]
  assert_json_valid "${project_dir}/.kiro/kiro-manifest.json"
  assert_json_field "${project_dir}/.kiro/kiro-manifest.json" '.schema_version' '1.0.0'
  assert_json_field "${project_dir}/.kiro/kiro-manifest.json" '.baseline.version' '0.1.0'
}

@test "setup_manifest: aceita override de campos via JSON" {
  local project_dir
  project_dir="$(create_temp_project)"
  setup_manifest "${project_dir}" '{"project": {"name": "custom-project"}}'

  assert_json_field "${project_dir}/.kiro/kiro-manifest.json" '.project.name' 'custom-project'
}

@test "cleanup_fixtures: remove diretórios temporários" {
  local project_dir baseline_dir
  project_dir="$(create_temp_project)"
  baseline_dir="$(create_baseline_fixture)"

  [ -d "${project_dir}" ]
  [ -d "${baseline_dir}" ]

  cleanup_fixtures

  [ ! -d "${project_dir}" ]
  [ ! -d "${baseline_dir}" ]
}

# --- assertions.bash ---

@test "assert_file_identical: passa quando arquivos são idênticos" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo "conteúdo teste" > "${project_dir}/file_a.txt"
  cp "${project_dir}/file_a.txt" "${project_dir}/file_b.txt"

  assert_file_identical "${project_dir}/file_a.txt" "${project_dir}/file_b.txt"
}

@test "assert_file_identical: falha quando arquivos são diferentes" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo "conteúdo A" > "${project_dir}/file_a.txt"
  echo "conteúdo B" > "${project_dir}/file_b.txt"

  run assert_file_identical "${project_dir}/file_a.txt" "${project_dir}/file_b.txt"
  assert_failure
  assert_output --partial 'arquivos não são idênticos'
}

@test "assert_json_valid: passa com JSON válido" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo '{"key": "value"}' > "${project_dir}/valid.json"
  assert_json_valid "${project_dir}/valid.json"
}

@test "assert_json_valid: falha com JSON inválido" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo '{invalid json' > "${project_dir}/invalid.json"

  run assert_json_valid "${project_dir}/invalid.json"
  assert_failure
  assert_output --partial 'não contém JSON válido'
}

@test "assert_exit_code: passa com exit code correto" {
  assert_exit_code 0 true
  assert_exit_code 1 false
}

@test "assert_exit_code: falha com exit code incorreto" {
  run assert_exit_code 0 false
  assert_failure
  assert_output --partial 'exit code não corresponde ao esperado'
}

@test "assert_no_fs_changes: passa quando comando não modifica filesystem" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo "test" > "${project_dir}/existing.txt"
  assert_no_fs_changes "${project_dir}" echo "noop"
}

@test "assert_no_fs_changes: falha quando comando modifica filesystem" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo "original" > "${project_dir}/file.txt"

  run assert_no_fs_changes "${project_dir}" bash -c "echo modified > '${project_dir}/file.txt'"
  assert_failure
  assert_output --partial 'filesystem foi modificado'
}

@test "assert_json_field: passa com campo e valor corretos" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo '{"name": "test", "version": "1.0.0"}' > "${project_dir}/data.json"

  assert_json_field "${project_dir}/data.json" '.name' 'test'
  assert_json_field "${project_dir}/data.json" '.version' '1.0.0'
}

@test "assert_json_field: falha com valor incorreto" {
  local project_dir
  project_dir="$(create_temp_project)"

  echo '{"name": "test"}' > "${project_dir}/data.json"

  run assert_json_field "${project_dir}/data.json" '.name' 'wrong'
  assert_failure
  assert_output --partial 'campo JSON não corresponde ao esperado'
}
