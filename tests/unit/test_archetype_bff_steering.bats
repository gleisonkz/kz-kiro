#!/usr/bin/env bats
# Testes unitários para steering files do archetype bff-fastify.
# Valida existência, estrutura e conteúdo dos 4 steering files + README.
# Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify"
  STEERING_DIR="${ARCHETYPE_DIR}/steering"
}

# --- Existência dos 4 steering files + README ---

@test "steering: existem exatamente 4 arquivos de steering (excluindo README)" {
  local count
  count=$(find "${STEERING_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
  [ "$count" -eq 4 ]
}

@test "steering: stack-and-tooling.md existe" {
  [ -f "${STEERING_DIR}/stack-and-tooling.md" ]
}

@test "steering: architecture.md existe" {
  [ -f "${STEERING_DIR}/architecture.md" ]
}

@test "steering: naming-conventions.md existe" {
  [ -f "${STEERING_DIR}/naming-conventions.md" ]
}

@test "steering: ci-cd.md existe" {
  [ -f "${STEERING_DIR}/ci-cd.md" ]
}

@test "steering: README.md existe" {
  [ -f "${STEERING_DIR}/README.md" ]
}

# --- stack-and-tooling.md: seções obrigatórias (Req 2.1) ---

@test "stack-and-tooling: contém seção de stack base obrigatória" {
  run grep -i "Stack Base" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Node.js 20" {
  run grep -i "Node.js.*20" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Fastify 5" {
  run grep -iE "Fastify.*5" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona TypeScript 5 strict" {
  run grep -iE "TypeScript.*5.*strict" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Zod" {
  run grep -i "Zod" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém justificativa RFC para Fastify" {
  run grep -iE "(RFC-0013|Por que Fastify)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém justificativa RFC para Zod" {
  run grep -iE "(RFC-0014|Por que Zod)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona ESM-first" {
  run grep -iE "ESM" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém configuração TypeScript (tsconfig)" {
  run grep -iE "(tsconfig|Configuração TypeScript|compilerOptions)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém scripts padrão do package.json" {
  run grep -iE "(Scripts Padrão|package.json)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém packages compartilhados" {
  run grep -iE "(Packages Compartilhados|bff-core)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém configuração Docker" {
  run grep -iE "(Docker|Dockerfile)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém seção de tecnologias descartadas" {
  run grep -iE "(Tecnologias Descartadas|Descartadas)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

# --- architecture.md: seções obrigatórias (Req 2.2) ---

@test "architecture: contém seção sobre papel do BFF" {
  run grep -iE "(Papel Arquitetural|Papel.*BFF)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem principios fundamentais" {
  run grep -iE "Princípios fundamentais" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém seção sobre monólito modular" {
  run grep -iE "Monólito Modular" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém seção sobre módulo como plugin Fastify" {
  run grep -iE "(Módulo como Plugin|Plugin Fastify)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém anatomia de um módulo" {
  run grep -iE "Anatomia" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém fluxo de uma request" {
  run grep -iE "Fluxo.*Request" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém padrões de agregação" {
  run grep -iE "(Padrões de Agregação|Agregação)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém regras de fronteira entre módulos" {
  run grep -iE "(Fronteira|Fronteiras)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém seção de resiliência" {
  run grep -iE "Resiliência" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém seção de observabilidade" {
  run grep -iE "Observabilidade" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém health checks" {
  run grep -iE "Health Check" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém versionamento de API" {
  run grep -iE "(Versionamento.*API|/api/v1/)" "${STEERING_DIR}/architecture.md"
  assert_success
}

# --- naming-conventions.md: tabela com sufixos mapeados (Req 2.3) ---

@test "naming-conventions: contém tabela de sufixos de arquivo" {
  run grep -iE "(Sufixo|Sufixos)" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .schema.ts" {
  run grep '\.schema\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .service.ts" {
  run grep '\.service\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .mapper.ts" {
  run grep '\.mapper\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .types.ts" {
  run grep '\.types\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .config.ts" {
  run grep '\.config\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .test.ts" {
  run grep '\.test\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .fixture.ts" {
  run grep '\.fixture\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .constants.ts" {
  run grep '\.constants\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .plugin.ts" {
  run grep '\.plugin\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona kebab-case para diretórios" {
  run grep -i "kebab-case" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

# --- ci-cd.md: seções obrigatórias (Req 2.4) ---

@test "ci-cd: contem secao de principios de CI/CD" {
  run grep -iE "Princípios" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contém regras para PR" {
  run grep -iE "(PR|Pull Request|todo PR)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contém regras para merge em main" {
  run grep -iE "(merge.*main|main)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contém regras para release" {
  run grep -iE "release" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contém seção de ambientes" {
  run grep -iE "Ambientes" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: menciona container Docker multi-stage" {
  run grep -iE "(multi-stage|Docker)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contém seção de monitoramento" {
  run grep -iE "(Monitoramento|Pós-Deploy)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}
