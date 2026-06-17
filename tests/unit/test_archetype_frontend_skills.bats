#!/usr/bin/env bats
# Testes unitários para validar os skills do archetype frontend-react.
# Valida: Requisitos 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react"
  SKILLS_DIR="${ARCHETYPE_DIR}/skills"
}

# --- Existência das 7 skills com nomes corretos ---

@test "skills: diretório skills/ existe" {
  [ -d "${SKILLS_DIR}" ]
}

@test "skills: generate-component.md existe" {
  [ -f "${SKILLS_DIR}/generate-component.md" ]
}

@test "skills: generate-hook.md existe" {
  [ -f "${SKILLS_DIR}/generate-hook.md" ]
}

@test "skills: generate-redux-slice.md existe" {
  [ -f "${SKILLS_DIR}/generate-redux-slice.md" ]
}

@test "skills: generate-api-endpoint.md existe" {
  [ -f "${SKILLS_DIR}/generate-api-endpoint.md" ]
}

@test "skills: generate-page.md existe" {
  [ -f "${SKILLS_DIR}/generate-page.md" ]
}

@test "skills: generate-module.md existe" {
  [ -f "${SKILLS_DIR}/generate-module.md" ]
}

@test "skills: generate-context-provider.md existe" {
  [ -f "${SKILLS_DIR}/generate-context-provider.md" ]
}

@test "skills: contém exatamente 7 skills (excluindo README.md)" {
  local count
  count="$(find "${SKILLS_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')"
  [ "${count}" -eq 7 ]
}

# --- Requisito 8.1: generate-component documenta artefatos ---

@test "generate-component: documenta artefato .tsx" {
  grep -q '\.tsx' "${SKILLS_DIR}/generate-component.md"
}

@test "generate-component: documenta artefato .test.tsx" {
  grep -q '\.test\.tsx' "${SKILLS_DIR}/generate-component.md"
}

@test "generate-component: documenta artefato .stories.tsx" {
  grep -q '\.stories\.tsx' "${SKILLS_DIR}/generate-component.md"
}

@test "generate-component: documenta artefato index.ts" {
  grep -q 'index\.ts' "${SKILLS_DIR}/generate-component.md"
}

# --- Requisito 8.2: generate-hook segue padrão use-*.hook.ts ---

@test "generate-hook: documenta padrão use-*.hook.ts" {
  grep -q 'use-.*\.hook\.ts' "${SKILLS_DIR}/generate-hook.md"
}

@test "generate-hook: menciona prefixo 'use' obrigatório" {
  grep -qi 'prefixo.*use\|use.*prefixo\|prefixo obrigatório.*use' "${SKILLS_DIR}/generate-hook.md"
}

@test "generate-hook: documenta teste use-*.hook.test.ts" {
  grep -q 'use-.*\.hook\.test\.ts' "${SKILLS_DIR}/generate-hook.md"
}

# --- Requisito 8.3: generate-redux-slice gera .slice.ts, .selectors.ts e testes ---

@test "generate-redux-slice: documenta artefato .slice.ts" {
  grep -q '\.slice\.ts' "${SKILLS_DIR}/generate-redux-slice.md"
}

@test "generate-redux-slice: documenta artefato .selectors.ts" {
  grep -q '\.selectors\.ts' "${SKILLS_DIR}/generate-redux-slice.md"
}

@test "generate-redux-slice: documenta teste do slice (.slice.test.ts)" {
  grep -q '\.slice\.test\.ts' "${SKILLS_DIR}/generate-redux-slice.md"
}

@test "generate-redux-slice: documenta teste dos selectors (.selectors.test.ts)" {
  grep -q '\.selectors\.test\.ts' "${SKILLS_DIR}/generate-redux-slice.md"
}

@test "generate-redux-slice: menciona prefixo 'select' para selectors" {
  grep -qi 'select' "${SKILLS_DIR}/generate-redux-slice.md"
}

# --- Requisito 8.5: generate-page menciona 4 estados ---

@test "generate-page: menciona estado loading" {
  grep -qi 'loading' "${SKILLS_DIR}/generate-page.md"
}

@test "generate-page: menciona estado error" {
  grep -qi 'error' "${SKILLS_DIR}/generate-page.md"
}

@test "generate-page: menciona estado empty" {
  grep -qi 'empty' "${SKILLS_DIR}/generate-page.md"
}

@test "generate-page: menciona estado success" {
  grep -qi 'success' "${SKILLS_DIR}/generate-page.md"
}

# --- Requisito 8.6: generate-module gera estrutura FSD ---

@test "generate-module: documenta diretório pages/" {
  grep -q 'pages/' "${SKILLS_DIR}/generate-module.md"
}

@test "generate-module: documenta diretório features/" {
  grep -q 'features/' "${SKILLS_DIR}/generate-module.md"
}

@test "generate-module: documenta diretório entities/" {
  grep -q 'entities/' "${SKILLS_DIR}/generate-module.md"
}

@test "generate-module: documenta diretório shared/" {
  grep -q 'shared/' "${SKILLS_DIR}/generate-module.md"
}

@test "generate-module: documenta barrel export index.ts" {
  grep -q 'index\.ts' "${SKILLS_DIR}/generate-module.md"
}

# --- Requisito 8.7: generate-context-provider gera Provider + hook ---

@test "generate-context-provider: documenta Provider" {
  grep -qi 'provider' "${SKILLS_DIR}/generate-context-provider.md"
}

@test "generate-context-provider: documenta hook de leitura com prefixo 'use'" {
  grep -q 'use' "${SKILLS_DIR}/generate-context-provider.md"
}

@test "generate-context-provider: documenta .context.tsx" {
  grep -q '\.context\.tsx' "${SKILLS_DIR}/generate-context-provider.md"
}

@test "generate-context-provider: documenta .provider.tsx" {
  grep -q '\.provider\.tsx' "${SKILLS_DIR}/generate-context-provider.md"
}

# --- Requisito 8.4: generate-api-endpoint gera .api.ts e teste ---

@test "generate-api-endpoint: documenta artefato .api.ts" {
  grep -q '\.api\.ts' "${SKILLS_DIR}/generate-api-endpoint.md"
}

@test "generate-api-endpoint: documenta teste .api.test.ts" {
  grep -q '\.api\.test\.ts' "${SKILLS_DIR}/generate-api-endpoint.md"
}

@test "generate-api-endpoint: menciona RTK Query" {
  grep -qi 'RTK Query\|createApi\|fetchBaseQuery' "${SKILLS_DIR}/generate-api-endpoint.md"
}

@test "generate-api-endpoint: menciona cache/tags" {
  grep -qi 'tag\|cache\|invalidat' "${SKILLS_DIR}/generate-api-endpoint.md"
}
