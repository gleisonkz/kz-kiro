#!/usr/bin/env bats
# Testes unitários para agents do archetype bff-fastify.
# Valida que agents/ é um placeholder com apenas README.md e nenhum agent funcional.
# Requisitos: 9.1, 9.2

setup() {
  load '../helpers/assertions'
  AGENTS_DIR="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify/agents"
}

# --- Existência do diretório e README ---

@test "agents: diretório agents/ existe" {
  [ -d "${AGENTS_DIR}" ]
}

@test "agents: README.md existe" {
  [ -f "${AGENTS_DIR}/README.md" ]
}

# --- Apenas README.md existe (placeholder) ---

@test "agents: apenas README.md existe no diretório (count=1)" {
  run find "${AGENTS_DIR}" -maxdepth 1 -type f | wc -l
  # Deve conter exatamente 1 arquivo (README.md)
  local file_count
  file_count=$(find "${AGENTS_DIR}" -maxdepth 1 -type f | wc -l | tr -d ' ')
  [ "${file_count}" -eq 1 ]
}

@test "agents: não há arquivos .md além de README.md" {
  local extra_files
  extra_files=$(find "${AGENTS_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' -type f | wc -l | tr -d ' ')
  [ "${extra_files}" -eq 0 ]
}

@test "agents: nenhum arquivo possui frontmatter de agent funcional" {
  # Verifica que nenhum arquivo em agents/ (exceto README) começa com --- (frontmatter YAML)
  local files_with_frontmatter=0
  for file in "${AGENTS_DIR}"/*.md; do
    if [[ "$(basename "${file}")" == "README.md" ]]; then
      continue
    fi
    if head -1 "${file}" 2>/dev/null | grep -q '^---$'; then
      files_with_frontmatter=$((files_with_frontmatter + 1))
    fi
  done
  [ "${files_with_frontmatter}" -eq 0 ]
}

# --- README menciona agents planejados ---

@test "agents: README menciona bff-architect" {
  run grep -i "bff-architect" "${AGENTS_DIR}/README.md"
  assert_success
}

@test "agents: README menciona api-designer" {
  run grep -i "api-designer" "${AGENTS_DIR}/README.md"
  assert_success
}

@test "agents: README menciona resilience-reviewer" {
  run grep -i "resilience-reviewer" "${AGENTS_DIR}/README.md"
  assert_success
}

@test "agents: README menciona test-writer" {
  run grep -i "test-writer" "${AGENTS_DIR}/README.md"
  assert_success
}
