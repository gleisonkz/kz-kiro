#!/usr/bin/env bats
# =============================================================================
# Testes de Integração: validate-agents.sh
# Feature: archetype-code-review
#
# Cenários para o script de validação CI de Agent_Markdown e Agent_JSON:
# - Agent .md válido (frontmatter + seções) → exit 0
# - Agent .md sem frontmatter → exit 1
# - Agent .md sem campo 'name' no frontmatter → exit 1
# - Agent .md sem campo 'description' no frontmatter → exit 1
# - Agent .md sem seção "## Papel" → exit 1
# - Agent .md sem seção "## O que revisar" → exit 1
# - Agent .json válido → exit 0
# - Agent .json com name sem prefixo 'cli-' → exit 1
# - Agent .json com description muito curta (<10 chars) → exit 1
# - Agent .json com instructions muito curtas (<100 chars) → exit 1
#
# **Validates: Requirements 1.8**
# =============================================================================

setup() {
  # Carregar bats-support e bats-assert diretamente (teste na raiz de tests/)
  load "${BATS_TEST_DIRNAME}/lib/bats-support/load"
  load "${BATS_TEST_DIRNAME}/lib/bats-assert/load"

  # Localizar o script sob teste
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
  VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate-agents.sh"

  # Criar diretório temporário simulando a estrutura de archetypes
  TEST_TMPDIR="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-validate-agents-XXXXXX")"

  # Criar estrutura mínima de archetypes
  mkdir -p "${TEST_TMPDIR}/archetypes/test-archetype/agents"
  mkdir -p "${TEST_TMPDIR}/scripts"

  # Copiar o script de validação para o diretório temporário
  # (o script usa REPO_ROOT baseado na sua própria localização)
  cp "${VALIDATE_SCRIPT}" "${TEST_TMPDIR}/scripts/validate-agents.sh"
  chmod +x "${TEST_TMPDIR}/scripts/validate-agents.sh"
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# =============================================================================
# Helpers
# =============================================================================

# Cria um Agent_Markdown válido com todos os campos e seções obrigatórias
create_valid_agent_md() {
  local file="$1"
  cat > "${file}" << 'EOF'
---
name: "Revisor de Código"
description: "Agente especializado em revisão de qualidade de código."
---

# Revisor de Código

## Papel

Revisar código fonte com foco em qualidade, legibilidade e manutenibilidade.

## Contexto

Stack: TypeScript, React, Fastify. Organização: MonteBravo.

## O que revisar

- Legibilidade e clareza do código
- Padrões de nomenclatura
- Tratamento de erros

## Formato de resposta

Categorizar findings por severidade: bloqueante, importante, sugestão.
EOF
}

# Cria um Agent_JSON válido com todos os campos respeitando o schema
create_valid_agent_json() {
  local file="$1"
  local instructions
  # Gerar instructions com mais de 100 chars
  instructions="Você é um revisor de código especializado. Analise os arquivos alterados no PR com foco em qualidade, legibilidade, manutenibilidade e aderência aos padrões da organização."
  cat > "${file}" << EOF
{
  "name": "cli-code-reviewer",
  "description": "Agente de revisão de qualidade de código para PRs.",
  "instructions": "${instructions}"
}
EOF
}

# =============================================================================
# Cenário A: Agent .md válido (todos os campos e seções) → exit 0
# =============================================================================

@test "validate-agents: agent .md válido com todos os campos e seções retorna exit 0" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"

  create_valid_agent_md "${TEST_TMPDIR}/archetypes/test-archetype/agents/code-reviewer.md"

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_success
}

# =============================================================================
# Cenário B: Agent .md sem frontmatter → exit 1, mensagem menciona arquivo
# =============================================================================

@test "validate-agents: agent .md sem frontmatter retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"

  # Criar .md sem frontmatter (não começa com ---)
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/code-reviewer.md" << 'EOF'
# Revisor de Código

## Papel

Revisar código.

## Contexto

Stack TypeScript.

## O que revisar

- Qualidade

## Formato de resposta

Markdown.
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  # A mensagem de erro deve mencionar o arquivo
  assert_output --partial "code-reviewer.md"
}

# =============================================================================
# Cenário C: Agent .md sem 'name' no frontmatter → exit 1
# =============================================================================

@test "validate-agents: agent .md sem campo 'name' no frontmatter retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"

  # Criar .md com frontmatter mas sem campo 'name'
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/code-reviewer.md" << 'EOF'
---
description: "Agente de revisão de código."
---

# Revisor de Código

## Papel

Revisar código.

## Contexto

Stack TypeScript.

## O que revisar

- Qualidade

## Formato de resposta

Markdown.
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  assert_output --partial "name"
}

# =============================================================================
# Cenário D: Agent .md sem 'description' no frontmatter → exit 1
# =============================================================================

@test "validate-agents: agent .md sem campo 'description' no frontmatter retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"

  # Criar .md com frontmatter mas sem campo 'description'
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/code-reviewer.md" << 'EOF'
---
name: "Revisor de Código"
---

# Revisor de Código

## Papel

Revisar código.

## Contexto

Stack TypeScript.

## O que revisar

- Qualidade

## Formato de resposta

Markdown.
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  assert_output --partial "description"
}

# =============================================================================
# Cenário E: Agent .md sem seção "## Papel" → exit 1
# =============================================================================

@test "validate-agents: agent .md sem seção '## Papel' retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"

  # Criar .md válido mas sem a seção "## Papel"
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/code-reviewer.md" << 'EOF'
---
name: "Revisor de Código"
description: "Agente de revisão de código."
---

# Revisor de Código

## Contexto

Stack TypeScript.

## O que revisar

- Qualidade

## Formato de resposta

Markdown.
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  assert_output --partial "Papel"
}

# =============================================================================
# Cenário F: Agent .md sem seção "## O que revisar" → exit 1
# =============================================================================

@test "validate-agents: agent .md sem seção '## O que revisar' retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"

  # Criar .md válido mas sem a seção "## O que revisar"
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/code-reviewer.md" << 'EOF'
---
name: "Revisor de Código"
description: "Agente de revisão de código."
---

# Revisor de Código

## Papel

Revisar código.

## Contexto

Stack TypeScript.

## Formato de resposta

Markdown.
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  assert_output --partial "O que revisar"
}

# =============================================================================
# Cenário G: Agent .json válido (schema completo) → exit 0
# =============================================================================

@test "validate-agents: agent .json válido retorna exit 0" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"
  command -v python3 &>/dev/null || command -v jq &>/dev/null || skip "python3 ou jq necessário"

  create_valid_agent_json "${TEST_TMPDIR}/archetypes/test-archetype/agents/cli-code-reviewer.json"

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_success
}

# =============================================================================
# Cenário H: Agent .json com name sem prefixo 'cli-' → exit 1
# =============================================================================

@test "validate-agents: agent .json com name sem prefixo 'cli-' retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"
  command -v python3 &>/dev/null || command -v jq &>/dev/null || skip "python3 ou jq necessário"

  # Criar JSON com name inválido (sem prefixo cli-)
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/cli-code-reviewer.json" << 'EOF'
{
  "name": "code-reviewer",
  "description": "Agente de revisão de qualidade de código para PRs.",
  "instructions": "Você é um revisor de código especializado. Analise os arquivos alterados no PR com foco em qualidade, legibilidade, manutenibilidade e aderência aos padrões da organização."
}
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  assert_output --partial "cli-"
}

# =============================================================================
# Cenário I: Agent .json com description muito curta (<10 chars) → exit 1
# =============================================================================

@test "validate-agents: agent .json com description curta (<10 chars) retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"
  command -v python3 &>/dev/null || command -v jq &>/dev/null || skip "python3 ou jq necessário"

  # Criar JSON com description muito curta (menos de 10 caracteres)
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/cli-code-reviewer.json" << 'EOF'
{
  "name": "cli-code-reviewer",
  "description": "Curta",
  "instructions": "Você é um revisor de código especializado. Analise os arquivos alterados no PR com foco em qualidade, legibilidade, manutenibilidade e aderência aos padrões da organização."
}
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  assert_output --partial "description"
}

# =============================================================================
# Cenário J: Agent .json com instructions muito curtas (<100 chars) → exit 1
# =============================================================================

@test "validate-agents: agent .json com instructions curtas (<100 chars) retorna exit 1" {
  [[ -f "${VALIDATE_SCRIPT}" ]] || skip "validate-agents.sh não encontrado"
  command -v python3 &>/dev/null || command -v jq &>/dev/null || skip "python3 ou jq necessário"

  # Criar JSON com instructions muito curtas (menos de 100 caracteres)
  cat > "${TEST_TMPDIR}/archetypes/test-archetype/agents/cli-code-reviewer.json" << 'EOF'
{
  "name": "cli-code-reviewer",
  "description": "Agente de revisão de qualidade de código para PRs.",
  "instructions": "Revisar código."
}
EOF

  run bash "${TEST_TMPDIR}/scripts/validate-agents.sh"

  assert_failure
  assert_output --partial "instructions"
}
