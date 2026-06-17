#!/usr/bin/env bats
# Testes unitários para steering files do archetype frontend-react.
# Valida existência, estrutura e conteúdo dos 5 steering files.
# Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react"
  STEERING_DIR="${ARCHETYPE_DIR}/steering"
}

# --- Existência dos 5 steering files ---

@test "steering: existem exatamente 5 arquivos de steering (excluindo README)" {
  local count
  count=$(find "${STEERING_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
  [ "$count" -eq 5 ]
}

@test "steering: stack-and-tooling.md existe" {
  [ -f "${STEERING_DIR}/stack-and-tooling.md" ]
}

@test "steering: architecture.md existe" {
  [ -f "${STEERING_DIR}/architecture.md" ]
}

@test "steering: design-system.md existe" {
  [ -f "${STEERING_DIR}/design-system.md" ]
}

@test "steering: naming-conventions.md existe" {
  [ -f "${STEERING_DIR}/naming-conventions.md" ]
}

@test "steering: ci-cd.md existe" {
  [ -f "${STEERING_DIR}/ci-cd.md" ]
}

# --- stack-and-tooling.md: seções obrigatórias (Req 2.1) ---

@test "stack-and-tooling: contém seção de stack base obrigatória" {
  run grep -i "Stack Base" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona React 19" {
  run grep -i "React.*19" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona TypeScript strict" {
  run grep -i "TypeScript.*strict" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Vite" {
  run grep -i "Vite" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Vitest" {
  run grep -i "Vitest" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Turborepo" {
  run grep -i "Turborepo" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona TailwindCSS 4" {
  run grep -i "TailwindCSS.*4" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Redux Toolkit" {
  run grep -i "Redux Toolkit" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona RTK Query" {
  run grep -iE "(RTK Query|Redux Toolkit Query)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona TanStack Router" {
  run grep -i "TanStack Router" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona pnpm" {
  run grep -i "pnpm" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém seção de organização do monorepo" {
  run grep -iE "(Organização.*Monorepo|Monorepo)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contém seção de tecnologias descartadas" {
  run grep -iE "(Tecnologias Descartadas|Descartadas)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

# --- architecture.md: seções obrigatórias (Req 2.2) ---

@test "architecture: contém seção sobre monolito modular" {
  run grep -i "Monolito Modular" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém seção sobre Feature-Sliced Design (FSD)" {
  run grep -iE "(Feature-Sliced Design|FSD)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém seção sobre regras de fronteira entre módulos" {
  run grep -iE "(Fronteira|Fronteiras)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contém seção sobre gerenciamento de estado" {
  run grep -iE "(Gerenciamento de Estado|Estado)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona layer app/" {
  run grep -E "app/" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona layer pages/" {
  run grep -E "pages/" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona layer widgets/" {
  run grep -E "widgets/" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona layer features/" {
  run grep -E "features/" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona layer entities/" {
  run grep -E "entities/" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona layer shared/" {
  run grep -E "shared/" "${STEERING_DIR}/architecture.md"
  assert_success
}

# --- design-system.md: seções obrigatórias (Req 2.3) ---

@test "design-system: contém seção sobre arquitetura token-first" {
  run grep -i "Token-first" "${STEERING_DIR}/design-system.md"
  assert_success
}

@test "design-system: contém seção sobre Base UI" {
  run grep -i "Base UI" "${STEERING_DIR}/design-system.md"
  assert_success
}

@test "design-system: contém seção sobre Storybook" {
  run grep -i "Storybook" "${STEERING_DIR}/design-system.md"
  assert_success
}

@test "design-system: contém seção sobre Changesets e SemVer" {
  run grep -i "Changesets" "${STEERING_DIR}/design-system.md"
  assert_success
}

@test "design-system: contém pelo menos 5 requisitos de qualidade" {
  # Conta ocorrências de headers numerados nos requisitos de qualidade
  local count
  count=$(grep -cE "^### [0-9]+\." "${STEERING_DIR}/design-system.md" || echo "0")
  [ "$count" -ge 5 ]
}

@test "design-system: requisitos incluem acessibilidade" {
  run grep -i "acessibilidade" "${STEERING_DIR}/design-system.md"
  assert_success
}

@test "design-system: requisitos incluem determinismo" {
  run grep -i "determinismo" "${STEERING_DIR}/design-system.md"
  assert_success
}

@test "design-system: requisitos incluem testabilidade ou identificação para teste" {
  run grep -iE "(testabilidade|teste|testável)" "${STEERING_DIR}/design-system.md"
  assert_success
}

# --- naming-conventions.md: tabela com ≥10 sufixos (Req 2.4) ---

@test "naming-conventions: contém tabela de sufixos de arquivo" {
  run grep -i "Sufixo" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: tabela contém pelo menos 10 sufixos mapeados" {
  # Conta linhas da tabela de sufixos (linhas com | que contêm um sufixo .xxx)
  local count
  count=$(grep -cE '^\|.*\.\w+' "${STEERING_DIR}/naming-conventions.md" || echo "0")
  [ "$count" -ge 10 ]
}

@test "naming-conventions: menciona sufixo .page.tsx" {
  run grep '\.page\.tsx' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .api.ts" {
  run grep '\.api\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .test.ts" {
  run grep '\.test\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .slice.ts" {
  run grep '\.slice\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .selectors.ts" {
  run grep '\.selectors\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .hook.ts" {
  run grep '\.hook\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .context.tsx" {
  run grep '\.context\.tsx' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .provider.tsx" {
  run grep '\.provider\.tsx' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .stories.tsx" {
  run grep '\.stories\.tsx' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona sufixo .types.ts" {
  run grep '\.types\.ts' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona prefixo use para hooks" {
  run grep -iE "prefixo.*use|use.*hook" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona prefixo select para selectors" {
  run grep -iE "prefixo.*select|select.*selector" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona kebab-case para diretórios" {
  run grep -i "kebab-case" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

# --- ci-cd.md: seções obrigatórias (Req 2.5) ---

@test "ci-cd: contém seção sobre estratégia de pipelines" {
  run grep -iE "(Estratégia.*Pipeline|Pipeline)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: menciona orquestração por impacto via Turborepo" {
  run grep -i "Turborepo" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contém seção sobre deploy independente por aplicação" {
  run grep -iE "(Deploy.*independente|independente.*deploy|Deploy por ambiente)" "${STEERING_DIR}/ci-cd.md"
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

@test "ci-cd: contém pipeline do Design System" {
  run grep -iE "(Design System.*Pipeline|Pipeline.*Design System)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}
