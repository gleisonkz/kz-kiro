#!/usr/bin/env bats
# Testes unitários para agents e skills (placeholders) do archetype mobile-flutter.
# Valida que agents/ e skills/ contêm apenas README.md com candidatos documentados.
# Requisitos: 11.1, 11.2, 12.1, 12.2

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"
  AGENTS_DIR="${ARCHETYPE_DIR}/agents"
  SKILLS_DIR="${ARCHETYPE_DIR}/skills"
}

# --- agents/: diretório e README existem ---

@test "agents: diretório agents/ existe" {
  [ -d "${AGENTS_DIR}" ]
}

@test "agents: README.md existe" {
  [ -f "${AGENTS_DIR}/README.md" ]
}

# --- agents/: apenas README.md existe (placeholder) ---

@test "agents: contém apenas 1 arquivo (README.md)" {
  local file_count
  file_count=$(find "${AGENTS_DIR}" -maxdepth 1 -type f | wc -l | tr -d ' ')
  [ "${file_count}" -eq 1 ]
}

@test "agents: não há arquivos .md além de README.md" {
  local extra_files
  extra_files=$(find "${AGENTS_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' -type f | wc -l | tr -d ' ')
  [ "${extra_files}" -eq 0 ]
}

# --- agents/README.md lista 3 candidatos futuros ---

@test "agents: README menciona agente de revisão de arquitetura Clean Architecture" {
  run grep -i "arquitetura Clean Architecture" "${AGENTS_DIR}/README.md"
  assert_success
}

@test "agents: README menciona agente de revisão de acessibilidade mobile" {
  run grep -i "acessibilidade mobile" "${AGENTS_DIR}/README.md"
  assert_success
}

@test "agents: README menciona agente de revisão de performance Flutter" {
  run grep -i "performance Flutter" "${AGENTS_DIR}/README.md"
  assert_success
}

# --- agents/: nenhum arquivo com frontmatter de agent funcional ---

@test "agents: nenhum arquivo possui frontmatter de agent funcional" {
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

# --- skills/: diretório e README existem ---

@test "skills: diretório skills/ existe" {
  [ -d "${SKILLS_DIR}" ]
}

@test "skills: README.md existe" {
  [ -f "${SKILLS_DIR}/README.md" ]
}

# --- skills/: apenas README.md existe (placeholder) ---

@test "skills: contém apenas 1 arquivo (README.md)" {
  local file_count
  file_count=$(find "${SKILLS_DIR}" -maxdepth 1 -type f | wc -l | tr -d ' ')
  [ "${file_count}" -eq 1 ]
}

@test "skills: não há arquivos .md além de README.md" {
  local extra_files
  extra_files=$(find "${SKILLS_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' -type f | wc -l | tr -d ' ')
  [ "${extra_files}" -eq 0 ]
}

# --- skills/README.md lista 5 candidatas futuras ---

@test "skills: README menciona Gerar feature (Clean Architecture completa)" {
  run grep -i "Gerar feature" "${SKILLS_DIR}/README.md"
  assert_success
}

@test "skills: README menciona Gerar use case" {
  run grep -i "Gerar use case" "${SKILLS_DIR}/README.md"
  assert_success
}

@test "skills: README menciona Gerar datasource + mock" {
  run grep -i "Gerar datasource" "${SKILLS_DIR}/README.md"
  assert_success
}

@test "skills: README menciona Gerar provider Riverpod" {
  run grep -i "Gerar provider Riverpod" "${SKILLS_DIR}/README.md"
  assert_success
}

@test "skills: README menciona Gerar página com rota go_router" {
  run grep -i "rota go_router" "${SKILLS_DIR}/README.md"
  assert_success
}

# --- skills/: nenhum arquivo com frontmatter de skill funcional ---

@test "skills: nenhum arquivo possui frontmatter de skill funcional" {
  local files_with_frontmatter=0
  for file in "${SKILLS_DIR}"/*.md; do
    if [[ "$(basename "${file}")" == "README.md" ]]; then
      continue
    fi
    if head -1 "${file}" 2>/dev/null | grep -q '^---$'; then
      files_with_frontmatter=$((files_with_frontmatter + 1))
    fi
  done
  [ "${files_with_frontmatter}" -eq 0 ]
}
