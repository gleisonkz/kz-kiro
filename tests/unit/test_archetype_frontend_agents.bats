#!/usr/bin/env bats
# Testes unitários para agents do archetype frontend-react.
# Valida existência, nomes e cobertura de conteúdo dos 4 agents especializados.
# Requisitos: 7.1, 7.2, 7.3, 7.4

setup() {
  load '../helpers/assertions'
  AGENTS_DIR="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react/agents"
}

# --- Existência dos 4 agents ---

@test "agents: diretório agents/ existe" {
  [ -d "${AGENTS_DIR}" ]
}

@test "agents: accessibility-reviewer.md existe" {
  [ -f "${AGENTS_DIR}/accessibility-reviewer.md" ]
}

@test "agents: architecture-reviewer.md existe" {
  [ -f "${AGENTS_DIR}/architecture-reviewer.md" ]
}

@test "agents: code-reviewer.md existe" {
  [ -f "${AGENTS_DIR}/code-reviewer.md" ]
}

@test "agents: performance-reviewer.md existe" {
  [ -f "${AGENTS_DIR}/performance-reviewer.md" ]
}

# --- accessibility-reviewer: cobertura de conteúdo (Req 7.1) ---

@test "accessibility-reviewer: cobre semântica HTML" {
  run grep -i "semântica" "${AGENTS_DIR}/accessibility-reviewer.md"
  assert_success
}

@test "accessibility-reviewer: cobre ARIA" {
  run grep -i "aria" "${AGENTS_DIR}/accessibility-reviewer.md"
  assert_success
}

@test "accessibility-reviewer: cobre navegação por teclado" {
  run grep -i "teclado" "${AGENTS_DIR}/accessibility-reviewer.md"
  assert_success
}

@test "accessibility-reviewer: cobre contraste" {
  run grep -i "contraste" "${AGENTS_DIR}/accessibility-reviewer.md"
  assert_success
}

@test "accessibility-reviewer: cobre formulários" {
  run grep -i "formulários" "${AGENTS_DIR}/accessibility-reviewer.md"
  assert_success
}

@test "accessibility-reviewer: cobre imagens" {
  run grep -i "imagens" "${AGENTS_DIR}/accessibility-reviewer.md"
  assert_success
}

# --- architecture-reviewer: cobertura de conteúdo (Req 7.2) ---

@test "architecture-reviewer: cobre fronteiras entre módulos" {
  run grep -i "fronteiras" "${AGENTS_DIR}/architecture-reviewer.md"
  assert_success
}

@test "architecture-reviewer: cobre FSD" {
  run grep -i "fsd" "${AGENTS_DIR}/architecture-reviewer.md"
  assert_success
}

@test "architecture-reviewer: cobre gerenciamento de estado" {
  run grep -i "estado" "${AGENTS_DIR}/architecture-reviewer.md"
  assert_success
}

@test "architecture-reviewer: cobre anti-padrões" {
  run grep -i "anti-padr" "${AGENTS_DIR}/architecture-reviewer.md"
  assert_success
}

# --- code-reviewer: 3 níveis de severidade (Req 7.3) ---

@test "code-reviewer: organiza em severidade bloqueante" {
  run grep -i "bloqueante" "${AGENTS_DIR}/code-reviewer.md"
  assert_success
}

@test "code-reviewer: organiza em severidade importante" {
  run grep -i "importante" "${AGENTS_DIR}/code-reviewer.md"
  assert_success
}

@test "code-reviewer: organiza em severidade sugestao" {
  run grep -i "sugestão" "${AGENTS_DIR}/code-reviewer.md"
  assert_success
}

# --- performance-reviewer: cobertura de conteúdo (Req 7.4) ---

@test "performance-reviewer: cobre re-renders" {
  run grep -i "re-render" "${AGENTS_DIR}/performance-reviewer.md"
  assert_success
}

@test "performance-reviewer: cobre memoização" {
  run grep -i "memoiza" "${AGENTS_DIR}/performance-reviewer.md"
  assert_success
}

@test "performance-reviewer: cobre bundle size" {
  run grep -i "bundle" "${AGENTS_DIR}/performance-reviewer.md"
  assert_success
}

@test "performance-reviewer: cobre RTK Query" {
  run grep -i "rtk query" "${AGENTS_DIR}/performance-reviewer.md"
  assert_success
}
