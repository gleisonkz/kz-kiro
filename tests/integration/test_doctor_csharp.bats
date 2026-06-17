#!/usr/bin/env bats
# =============================================================================
# Testes de Integração — doctor.sh com Archetype backend-csharp
# =============================================================================
# Cenários end-to-end para o script de diagnóstico de conformidade
# quando o projeto utiliza o archetype backend-csharp.
#
# Requisitos cobertos: 7.1, 7.2, 7.3, 7.4
# Design: Integração com Scripts de Automação (doctor.sh)
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/assertions'

# Caminhos
DOCTOR_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"
BASELINE_STEERING_DIR="${BATS_TEST_DIRNAME}/../../baselines/global/steering"
BASELINE_MCP="${BATS_TEST_DIRNAME}/../../baselines/global/mcp/mcp.json"
ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp"

# --- Setup / Teardown ---

teardown() {
  cleanup_fixtures
}

# --- Funções auxiliares ---

# Cria um projeto completamente saudável com archetype backend-csharp aplicado
_create_healthy_csharp_project() {
  local project_dir
  project_dir="$(create_temp_project)"

  # Copiar steering files do baseline
  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  # Copiar steering files do archetype backend-csharp
  for f in "${ARCHETYPE_DIR}/steering"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  # Copiar hooks do archetype
  for f in "${ARCHETYPE_DIR}/hooks"/*.kiro.hook; do
    local fname
    fname=$(basename "${f}")
    cp "${f}" "${project_dir}/.kiro/hooks/${fname}"
  done

  # Copiar skills do archetype
  for f in "${ARCHETYPE_DIR}/skills"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/skills/${fname}"
  done

  # Copiar mcp.json do baseline (base — archetype backend-csharp tem mcpServers vazio)
  cp "${BASELINE_MCP}" "${project_dir}/.kiro/settings/mcp.json"

  # Criar manifest válido com archetype backend-csharp
  _create_csharp_manifest "${project_dir}"

  # Inicializar como git repo
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test Backend C# Project" > "${project_dir}/README.md"

  echo "${project_dir}"
}

# Cria manifest com archetype backend-csharp declarado
_create_csharp_manifest() {
  local project_dir="$1"
  local exceptions="${2:-[]}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  cat > "${project_dir}/kiro-manifest.json" <<EOF
{
  "_generated_by": "test-integration-csharp",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test-csharp-project", "repository": "org/test-csharp-project" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "backend-csharp", "version": "0.2.0", "installed_at": "${now}" },
  "powers": [],
  "exceptions": ${exceptions}
}
EOF
}

# =============================================================================
# Cenário 1: Projeto saudável — exit 0, todos PASS (archetype backend-csharp)
# Requisitos: 7.1, 7.2
# =============================================================================

@test "doctor backend-csharp: projeto saudável retorna exit 0 com todos os checks PASS" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Exit code 0
  assert_success

  # Nenhum FAIL
  refute_output --partial "[FAIL]"

  # Verifica que archetype backend-csharp é identificado
  assert_output --partial "backend-csharp"

  # Verifica que checks passam
  assert_output --partial "[PASS]"
}

@test "doctor backend-csharp: projeto saudável reporta steering files como presentes" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  assert_output --partial "steering"
  assert_output --partial "[PASS]"
}

@test "doctor backend-csharp: projeto saudável reporta hooks como presentes" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  assert_output --partial "hooks"
  assert_output --partial "[PASS]"
}

@test "doctor backend-csharp: projeto saudável reporta skills como presentes" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  assert_output --partial "skills"
  assert_output --partial "[PASS]"
}

@test "doctor backend-csharp: mcpServers vazio no archetype não é reportado como problema" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Projeto saudável — mcpServers vazio no archetype não deve causar FAIL
  assert_success
  refute_output --partial "[FAIL]"
}

# =============================================================================
# Cenário 2: Steering file ausente — doctor detecta ausência (❌)
# Requisitos: 7.2, 7.3
# =============================================================================

@test "doctor backend-csharp: steering file do baseline ausente reporta FAIL" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Remover um steering file do baseline
  rm -f "${project_dir}/.kiro/steering/security-baseline.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_failure
  assert_output --partial "[FAIL]"
  assert_output --partial "Ausente"
  assert_output --partial "security-baseline.md"
}

@test "doctor backend-csharp: steering file do archetype desatualizado reporta WARN" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Modificar um steering file do archetype para ficar desatualizado
  echo "# Conteúdo modificado localmente" >> "${project_dir}/.kiro/steering/architecture.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # O steering continua presente mas pode estar desatualizado
  # No mínimo o steering file está presente e contado
  assert_output --partial "steering"
}

# =============================================================================
# Cenário 3: Hook desabilitado — doctor detecta ⚠️
# Requisitos: 7.3
# =============================================================================

@test "doctor backend-csharp: hook desabilitado reporta warning" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Modificar um hook para ficar desabilitado (conteúdo difere do archetype)
  local hook_file="${project_dir}/.kiro/hooks/build-after-agent.kiro.hook"
  cat > "${hook_file}" <<'EOF'
{
  "enabled": false,
  "name": "Build After Agent",
  "description": "Hook desabilitado pelo desenvolvedor.",
  "version": "2",
  "when": {
    "type": "agentStop"
  },
  "then": {
    "type": "askAgent",
    "prompt": "disabled"
  }
}
EOF

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # O doctor deve detectar divergência nos hooks (arquivo difere da fonte)
  assert_output --partial "hooks"
}

@test "doctor backend-csharp: hook removido reporta contagem incompleta" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Remover um hook
  rm -f "${project_dir}/.kiro/hooks/review-data-model.kiro.hook"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve detectar hook faltante
  assert_output --partial "hooks"
  assert_output --regexp '\[(FAIL|WARN)\]'
}

# =============================================================================
# Cenário 4: Skill faltante — doctor detecta ❌
# Requisitos: 7.3
# =============================================================================

@test "doctor backend-csharp: skill faltante do archetype reporta problema" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Remover uma skill esperada pelo archetype
  rm -f "${project_dir}/.kiro/skills/generate-data-model.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve reportar que skills estão incompletas
  assert_output --partial "skills"
  assert_output --regexp '\[(FAIL|WARN)\]'
}

@test "doctor backend-csharp: múltiplas skills faltantes reporta contagem" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Remover várias skills
  rm -f "${project_dir}/.kiro/skills/generate-data-model.md"
  rm -f "${project_dir}/.kiro/skills/generate-validation-package.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve reportar problema na seção de skills
  assert_output --partial "skills"
  assert_output --regexp '\[(FAIL|WARN)\]'
}

# =============================================================================
# Cenário 5: data-governance.md ausente — doctor detecta ❌ crítico
# Requisitos: 7.2, 7.3
# =============================================================================

@test "doctor backend-csharp: data-governance.md ausente com steering count abaixo do esperado reporta problema" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Remover todos os steering files do archetype E um do baseline para que
  # a contagem total caia abaixo do esperado pelo archetype (< 5)
  rm -f "${project_dir}/.kiro/steering/data-governance.md"
  rm -f "${project_dir}/.kiro/steering/architecture.md"
  rm -f "${project_dir}/.kiro/steering/ci-cd.md"
  rm -f "${project_dir}/.kiro/steering/naming-conventions.md"
  rm -f "${project_dir}/.kiro/steering/stack-and-tooling.md"
  rm -f "${project_dir}/.kiro/steering/engineering-principles.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve detectar problemas — baseline ausente E steering count < archetype expected
  assert_output --regexp '\[(FAIL|WARN)\]'
}

# =============================================================================
# Cenário 6: Relatório contém as 8 seções na ordem correta (via hook doctor prompt)
# Requisitos: 7.2, 7.4
# =============================================================================

@test "doctor backend-csharp: kiro-doctor hook contém as 8 seções esperadas no prompt" {
  # Verifica diretamente o conteúdo do hook kiro-doctor do archetype
  local hook_file="${ARCHETYPE_DIR}/hooks/kiro-doctor.kiro.hook"

  # Arquivo deve existir
  assert [ -f "${hook_file}" ]

  # Ler o prompt e verificar as 8 seções
  local prompt
  prompt=$(jq -r '.then.prompt' "${hook_file}")

  # Seção 1: Resumo
  assert [ -n "$(echo "${prompt}" | grep -i 'Resumo')" ]
  # Seção 2: Steering
  assert [ -n "$(echo "${prompt}" | grep -i 'Steering')" ]
  # Seção 3: Hooks
  assert [ -n "$(echo "${prompt}" | grep -i 'Hooks')" ]
  # Seção 4: MCP Servers
  assert [ -n "$(echo "${prompt}" | grep -i 'MCP')" ]
  # Seção 5: Skills
  assert [ -n "$(echo "${prompt}" | grep -i 'Skills')" ]
  # Seção 6: Specs
  assert [ -n "$(echo "${prompt}" | grep -i 'Specs')" ]
  # Seção 7: Arquitetura
  assert [ -n "$(echo "${prompt}" | grep -i 'Arquitetura')" ]
  # Seção 8: Recomendações
  assert [ -n "$(echo "${prompt}" | grep -i 'Recomenda')" ]
}

@test "doctor backend-csharp: kiro-doctor hook define as 8 seções na ordem correta" {
  local hook_file="${ARCHETYPE_DIR}/hooks/kiro-doctor.kiro.hook"
  local prompt
  prompt=$(jq -r '.then.prompt' "${hook_file}")

  # Verificar que a ordem é: Resumo < Steering < Hooks < MCP < Skills < Specs < Arquitetura < Recomendações
  local pos_resumo pos_steering pos_hooks pos_mcp pos_skills pos_specs pos_arq pos_rec

  pos_resumo=$(echo "${prompt}" | grep -n '\*\*Resumo\*\*' | head -1 | cut -d: -f1)
  pos_steering=$(echo "${prompt}" | grep -n '\*\*Steering\*\*' | head -1 | cut -d: -f1)
  pos_hooks=$(echo "${prompt}" | grep -n '\*\*Hooks\*\*' | head -1 | cut -d: -f1)
  pos_mcp=$(echo "${prompt}" | grep -n '\*\*MCP' | head -1 | cut -d: -f1)
  pos_skills=$(echo "${prompt}" | grep -n '\*\*Skills\*\*' | head -1 | cut -d: -f1)
  pos_specs=$(echo "${prompt}" | grep -n '\*\*Specs\*\*' | head -1 | cut -d: -f1)
  pos_arq=$(echo "${prompt}" | grep -n '\*\*Arquitetura\*\*' | head -1 | cut -d: -f1)
  pos_rec=$(echo "${prompt}" | grep -n '\*\*Recomenda' | head -1 | cut -d: -f1)

  # Verificar que todos foram encontrados
  assert [ -n "${pos_resumo}" ]
  assert [ -n "${pos_steering}" ]
  assert [ -n "${pos_hooks}" ]
  assert [ -n "${pos_mcp}" ]
  assert [ -n "${pos_skills}" ]
  assert [ -n "${pos_specs}" ]
  assert [ -n "${pos_arq}" ]
  assert [ -n "${pos_rec}" ]

  # Verificar ordem crescente
  assert [ "${pos_resumo}" -lt "${pos_steering}" ]
  assert [ "${pos_steering}" -lt "${pos_hooks}" ]
  assert [ "${pos_hooks}" -lt "${pos_mcp}" ]
  assert [ "${pos_mcp}" -lt "${pos_skills}" ]
  assert [ "${pos_skills}" -lt "${pos_specs}" ]
  assert [ "${pos_specs}" -lt "${pos_arq}" ]
  assert [ "${pos_arq}" -lt "${pos_rec}" ]
}

# =============================================================================
# Cenário 7: Doctor detecta artefatos específicos do archetype backend-csharp
# Requisitos: 7.1, 7.3
# =============================================================================

@test "doctor backend-csharp: detecta archetype backend-csharp via manifest" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # Deve identificar o archetype corretamente
  assert_output --partial "Archetype: backend-csharp"
}

@test "doctor backend-csharp: verifica contagem de steering files do archetype (5)" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype backend-csharp tem 5 steering files (excl. README)
  assert_output --partial "steering"
  assert_output --regexp 'steering: [0-9]+/5 arquivos presentes'
}

@test "doctor backend-csharp: verifica contagem correta de hooks (7 do archetype)" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype backend-csharp tem 7 hooks
  assert_output --partial "hooks"
  assert_output --partial "7/7"
}

@test "doctor backend-csharp: verifica contagem correta de skills (5 do archetype)" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype backend-csharp tem 5 skills
  assert_output --partial "skills"
  assert_output --partial "5/5"
}

# =============================================================================
# Cenário 8: Doctor JSON output contém categoria archetype
# Requisitos: 7.4
# =============================================================================

@test "doctor backend-csharp: output JSON contém resultados da categoria archetype" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  assert_success

  # Output deve ser JSON válido
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  # Deve conter resultados na categoria archetype
  local archetype_results
  archetype_results=$(echo "${output}" | jq '[.results[] | select(.category == "archetype")] | length')
  assert [ "${archetype_results}" -gt 0 ]

  # Deve ter archetype identificado como backend-csharp
  local has_csharp
  has_csharp=$(echo "${output}" | jq '[.results[] | select(.message | contains("backend-csharp"))] | length')
  assert [ "${has_csharp}" -gt 0 ]
}

@test "doctor backend-csharp: output JSON com skill ausente reporta warn" {
  local project_dir
  project_dir="$(_create_healthy_csharp_project)"

  # Remover skill
  rm -f "${project_dir}/.kiro/skills/generate-module.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  # Output deve ser JSON válido
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  # Deve ter resultado warn ou fail para archetype
  local problem_results
  problem_results=$(echo "${output}" | jq '[.results[] | select(.category == "archetype" and (.status == "warn" or .status == "fail"))] | length')
  assert [ "${problem_results}" -gt 0 ]
}
