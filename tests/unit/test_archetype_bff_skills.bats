#!/usr/bin/env bats
# Testes unitários para validar os skills do archetype bff-fastify.
# Valida: Requisitos 7.1, 7.2, 7.3, 7.4

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify"
  SKILLS_DIR="${ARCHETYPE_DIR}/skills"
}

# --- Existência das 3 skills com nomes corretos ---

@test "skills: diretório skills/ existe" {
  [ -d "${SKILLS_DIR}" ]
}

@test "skills: generate-module.md existe" {
  [ -f "${SKILLS_DIR}/generate-module.md" ]
}

@test "skills: generate-client.md existe" {
  [ -f "${SKILLS_DIR}/generate-client.md" ]
}

@test "skills: generate-plugin.md existe" {
  [ -f "${SKILLS_DIR}/generate-plugin.md" ]
}

@test "skills: contém exatamente 3 skills (excluindo README.md)" {
  local count
  count="$(find "${SKILLS_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')"
  [ "${count}" -eq 3 ]
}

# --- Requisito 7.1: generate-module documenta 6 artefatos ---

@test "generate-module: documenta artefato index.ts (plugin)" {
  run grep 'index\.ts' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta artefato routes/index.ts" {
  run grep 'routes/index\.ts' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta arquivo de rota (verbo-recurso)" {
  run grep '<verbo>-<recurso>\.ts' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta schema Zod" {
  run grep '\.schema\.ts' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta service de orquestração" {
  run grep '\.service\.ts' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta mapper de transformação" {
  run grep '\.mapper\.ts' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

# --- Requisito 7.2: generate-client documenta padrões de resiliência ---

@test "generate-client: documenta timeout" {
  run grep -i 'timeout' "${SKILLS_DIR}/generate-client.md"
  assert_success
}

@test "generate-client: documenta retry" {
  run grep -i 'retry' "${SKILLS_DIR}/generate-client.md"
  assert_success
}

@test "generate-client: documenta circuit breaker" {
  run grep -i 'circuit breaker' "${SKILLS_DIR}/generate-client.md"
  assert_success
}

@test "generate-client: documenta correlation ID" {
  run grep -i 'correlation.id\|x-correlation-id' "${SKILLS_DIR}/generate-client.md"
  assert_success
}

@test "generate-client: documenta undici ou fetch" {
  run grep -i 'undici\|fetch' "${SKILLS_DIR}/generate-client.md"
  assert_success
}

# --- Requisito 7.3: generate-plugin documenta padrões Fastify ---

@test "generate-plugin: documenta localização em plugins/" {
  run grep 'plugins/' "${SKILLS_DIR}/generate-plugin.md"
  assert_success
}

@test "generate-plugin: documenta sufixo Plugin" {
  run grep 'Plugin' "${SKILLS_DIR}/generate-plugin.md"
  assert_success
}

@test "generate-plugin: documenta uso de fp (fastify-plugin)" {
  run grep 'fp\|fastify-plugin' "${SKILLS_DIR}/generate-plugin.md"
  assert_success
}

@test "generate-plugin: documenta declare module" {
  run grep 'declare module' "${SKILLS_DIR}/generate-plugin.md"
  assert_success
}

@test "generate-plugin: documenta JSDoc" {
  run grep -i 'JSDoc' "${SKILLS_DIR}/generate-plugin.md"
  assert_success
}
