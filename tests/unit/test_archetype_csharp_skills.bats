#!/usr/bin/env bats
# Testes unitários para validar os skills do archetype backend-csharp.
# Valida: Requisitos 8.1, 8.2, 8.3, 8.4, 8.5, 8.6

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp"
  SKILLS_DIR="${ARCHETYPE_DIR}/skills"
}

# --- Existência das 5 skills com nomes corretos ---

@test "skills: diretório skills/ existe" {
  [ -d "${SKILLS_DIR}" ]
}

@test "skills: generate-module.md existe" {
  [ -f "${SKILLS_DIR}/generate-module.md" ]
}

@test "skills: generate-endpoint.md existe" {
  [ -f "${SKILLS_DIR}/generate-endpoint.md" ]
}

@test "skills: generate-repository.md existe" {
  [ -f "${SKILLS_DIR}/generate-repository.md" ]
}

@test "skills: generate-data-model.md existe" {
  [ -f "${SKILLS_DIR}/generate-data-model.md" ]
}

@test "skills: generate-validation-package.md existe" {
  [ -f "${SKILLS_DIR}/generate-validation-package.md" ]
}

@test "skills: contém exatamente 5 skills (excluindo README.md)" {
  local count
  count="$(find "${SKILLS_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')"
  [ "${count}" -eq 5 ]
}

# --- Requisito 8.1: generate-module documenta 4 camadas Clean Architecture ---

@test "generate-module: documenta camada Api (Endpoints)" {
  run grep -i 'Endpoints' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Application (Commands)" {
  run grep -i 'Commands' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Application (Queries)" {
  run grep -i 'Queries' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Application (Handlers)" {
  run grep -i 'Handler' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Application (Validators)" {
  run grep -i 'Validator' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Domain (Entities)" {
  run grep -i 'Entities' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Domain (Events)" {
  run grep -i 'Events' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Domain (Repositories/Interfaces)" {
  run grep -i 'Repository\|Interfaces' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Infrastructure (Persistence)" {
  run grep -i 'Persistence' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-module: documenta camada Infrastructure (Configurations)" {
  run grep -i 'Configuration' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

# --- Requisito 8.2: generate-endpoint documenta padrões Minimal API ---

@test "generate-endpoint: documenta Map()" {
  run grep 'Map(' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta ISender" {
  run grep 'ISender' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta WithName" {
  run grep 'WithName' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta WithTags" {
  run grep 'WithTags' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta Produces" {
  run grep 'Produces' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta RequireAuthorization" {
  run grep 'RequireAuthorization' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta CancellationToken" {
  run grep 'CancellationToken' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta nomenclatura {Verb}{Resource}Endpoint.cs" {
  run grep '{Verb}{Resource}Endpoint\.cs\|Verb}{Resource}Endpoint' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-endpoint: documenta rota /api/v1/ kebab-case" {
  run grep '/api/v1/' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

# --- Requisito 8.3: generate-repository documenta interface + implementação ---

@test "generate-repository: documenta interface I{Entity}Repository no Domain" {
  run grep 'I{Entity}Repository\|IOrderRepository' "${SKILLS_DIR}/generate-repository.md"
  assert_success
}

@test "generate-repository: documenta implementação EF Core no Infrastructure" {
  run grep 'Infrastructure' "${SKILLS_DIR}/generate-repository.md"
  assert_success
}

@test "generate-repository: documenta Entity Configuration" {
  run grep 'Configuration' "${SKILLS_DIR}/generate-repository.md"
  assert_success
}

@test "generate-repository: documenta interface no Domain" {
  run grep 'Domain' "${SKILLS_DIR}/generate-repository.md"
  assert_success
}

@test "generate-repository: documenta CancellationToken nos métodos" {
  run grep 'CancellationToken' "${SKILLS_DIR}/generate-repository.md"
  assert_success
}

# --- Requisito 8.4: generate-data-model documenta padrões chapter ---

@test "generate-data-model: documenta entidades de dominio" {
  run grep -i 'Entidades\|Entity\|Entities' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

@test "generate-data-model: documenta configurations com snake_case" {
  run grep 'snake_case' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

@test "generate-data-model: documenta prefixos de natureza" {
  run grep -i 'prefixo.*natureza\|natureza.*prefixo\|prefixos' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

@test "generate-data-model: documenta migration" {
  run grep -i 'migration' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

@test "generate-data-model: documenta DDL" {
  run grep -i 'DDL\|ddl\.sql' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

@test "generate-data-model: documenta dicionario de dados" {
  run grep -i 'data-dictionary\|dicion' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

@test "generate-data-model: documenta diagrama ER" {
  run grep -i 'er-diagram\|diagrama ER\|erDiagram' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

# --- Requisito 8.5: generate-validation-package documenta 4 artefatos ---

@test "generate-validation-package: documenta ddl.sql" {
  run grep 'ddl\.sql' "${SKILLS_DIR}/generate-validation-package.md"
  assert_success
}

@test "generate-validation-package: documenta data-dictionary.md" {
  run grep 'data-dictionary\.md' "${SKILLS_DIR}/generate-validation-package.md"
  assert_success
}

@test "generate-validation-package: documenta er-diagram.md" {
  run grep 'er-diagram\.md' "${SKILLS_DIR}/generate-validation-package.md"
  assert_success
}

@test "generate-validation-package: documenta validation-checklist.md" {
  run grep 'validation-checklist\.md' "${SKILLS_DIR}/generate-validation-package.md"
  assert_success
}

# --- Requisito 8.6: Frontmatter YAML com campos obrigatórios ---

@test "generate-module: frontmatter contém inclusion: manual" {
  run grep 'inclusion: manual\|inclusion:manual' "${SKILLS_DIR}/generate-module.md"
  assert_success
}

@test "generate-endpoint: frontmatter contém inclusion: manual" {
  run grep 'inclusion: manual\|inclusion:manual' "${SKILLS_DIR}/generate-endpoint.md"
  assert_success
}

@test "generate-repository: frontmatter contém inclusion: manual" {
  run grep 'inclusion: manual\|inclusion:manual' "${SKILLS_DIR}/generate-repository.md"
  assert_success
}

@test "generate-data-model: frontmatter contém inclusion: manual" {
  run grep 'inclusion: manual\|inclusion:manual' "${SKILLS_DIR}/generate-data-model.md"
  assert_success
}

@test "generate-validation-package: frontmatter contém inclusion: manual" {
  run grep 'inclusion: manual\|inclusion:manual' "${SKILLS_DIR}/generate-validation-package.md"
  assert_success
}
