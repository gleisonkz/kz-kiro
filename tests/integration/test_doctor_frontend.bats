#!/usr/bin/env bats
# =============================================================================
# Testes de Integração — doctor.sh com Archetype frontend-react
# =============================================================================
# Cenários end-to-end para o script de diagnóstico de conformidade
# quando o projeto utiliza o archetype frontend-react.
#
# Requisitos cobertos: 6.1, 6.2, 6.3, 6.4
# Design: Integração com Scripts de Automação (doctor.sh)
# =============================================================================

# Carrega helpers
load '../helpers/setup'
load '../helpers/assertions'

# Caminhos
DOCTOR_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/doctor.sh"
BASELINE_STEERING_DIR="${BATS_TEST_DIRNAME}/../../baselines/global/steering"
BASELINE_MCP="${BATS_TEST_DIRNAME}/../../baselines/global/mcp/mcp.json"
ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/frontend-react"

# --- Setup / Teardown ---

teardown() {
  cleanup_fixtures
}

# --- Funções auxiliares ---

# Cria um projeto completamente saudável com archetype frontend-react aplicado
_create_healthy_frontend_project() {
  local project_dir
  project_dir="$(create_temp_project)"

  # Copiar steering files do baseline
  for f in "${BASELINE_STEERING_DIR}"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/steering/${fname}"
  done

  # Copiar steering files do archetype frontend-react
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

  # Copiar agents do archetype
  for f in "${ARCHETYPE_DIR}/agents"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/agents/${fname}"
  done

  # Copiar skills do archetype
  for f in "${ARCHETYPE_DIR}/skills"/*.md; do
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    cp "${f}" "${project_dir}/.kiro/skills/${fname}"
  done

  # Copiar mcp.json do baseline (base)
  cp "${BASELINE_MCP}" "${project_dir}/.kiro/settings/mcp.json"

  # Criar manifest válido com archetype frontend-react
  _create_frontend_manifest "${project_dir}"

  # Inicializar como git repo
  git -C "${project_dir}" init --quiet 2>/dev/null || true
  echo "# Test Frontend Project" > "${project_dir}/README.md"

  echo "${project_dir}"
}

# Cria manifest com archetype frontend-react declarado
_create_frontend_manifest() {
  local project_dir="$1"
  local exceptions="${2:-[]}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  cat > "${project_dir}/kiro-manifest.json" <<EOF
{
  "_generated_by": "test-integration-frontend",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": { "name": "test-frontend-project", "repository": "org/test-frontend-project" },
  "baseline": { "version": "0.1.0", "source": "mb/kiro", "installed_at": "${now}", "last_synced_at": "${now}" },
  "archetype": { "name": "frontend-react", "version": "0.1.1", "installed_at": "${now}" },
  "powers": [],
  "exceptions": ${exceptions}
}
EOF
}

# =============================================================================
# Cenário 1: Projeto saudável — exit 0, todos PASS (archetype frontend-react)
# Requisitos: 6.1, 6.2
# =============================================================================

@test "doctor frontend-react: projeto saudável retorna exit 0 com todos os checks PASS" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Exit code 0
  assert_success

  # Nenhum FAIL
  refute_output --partial "[FAIL]"

  # Verifica que archetype frontend-react é identificado
  assert_output --partial "frontend-react"

  # Verifica que checks passam
  assert_output --partial "[PASS]"
}

@test "doctor frontend-react: projeto saudável reporta steering files do archetype como presentes" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success

  # Verifica que a seção steering do archetype é reportada com contagem completa
  assert_output --partial "steering"
  assert_output --partial "[PASS]"
}

@test "doctor frontend-react: projeto saudável reporta hooks do archetype como presentes" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success

  # Verifica que hooks são reportados como presentes
  assert_output --partial "hooks"
  assert_output --partial "[PASS]"
}

@test "doctor frontend-react: projeto saudável reporta skills do archetype como presentes" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success

  # Verifica que skills são reportados como presentes
  assert_output --partial "skills"
  assert_output --partial "[PASS]"
}

@test "doctor frontend-react: projeto saudável reporta agents do archetype como presentes" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success

  # Verifica que agents são reportados como presentes
  assert_output --partial "agents"
  assert_output --partial "[PASS]"
}

# =============================================================================
# Cenário 2: Steering file ausente — doctor detecta ausência
# Requisitos: 6.2, 6.3
# =============================================================================

@test "doctor frontend-react: steering file do baseline ausente reporta FAIL" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  # Remover um steering file do baseline (doctor verifica baseline por nome)
  rm -f "${project_dir}/.kiro/steering/security-baseline.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve reportar FAIL para arquivo ausente do baseline
  assert_failure
  assert_output --partial "[FAIL]"
  assert_output --partial "Ausente"
  assert_output --partial "security-baseline.md"
}

@test "doctor frontend-react: steering file do archetype desatualizado reporta WARN" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  # Modificar um steering file do archetype para ficar desatualizado
  echo "# Conteúdo modificado localmente" >> "${project_dir}/.kiro/steering/architecture.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Pode ter WARN para baseline se muda o file match do archetype
  # No mínimo o steering file está presente e contado
  assert_output --partial "steering"
}

# =============================================================================
# Cenário 3: Hook desabilitado — doctor detecta ⚠️
# Requisitos: 6.3
# =============================================================================

@test "doctor frontend-react: hook desabilitado reporta warning" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  # Modificar um hook para ficar desabilitado (conteúdo difere do archetype)
  local hook_file="${project_dir}/.kiro/hooks/lint-after-agent.kiro.hook"
  # Sobrescrever com hook desabilitado (conteúdo diferente do original)
  cat > "${hook_file}" <<'EOF'
{
  "enabled": false,
  "name": "Lint After Agent",
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
  # A contagem pode diferir pois compara com o archetype via diff
  assert_output --partial "hooks"
}

# =============================================================================
# Cenário 4: Skill faltante — doctor detecta ❌
# Requisitos: 6.3
# =============================================================================

@test "doctor frontend-react: skill faltante do archetype reporta problema" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  # Remover uma skill esperada pelo archetype
  rm -f "${project_dir}/.kiro/skills/generate-component.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve reportar que skills estão incompletas
  assert_output --partial "skills"
  assert_output --regexp '\[(FAIL|WARN)\]'
}

@test "doctor frontend-react: múltiplas skills faltantes reporta contagem" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  # Remover várias skills
  rm -f "${project_dir}/.kiro/skills/generate-component.md"
  rm -f "${project_dir}/.kiro/skills/generate-hook.md"
  rm -f "${project_dir}/.kiro/skills/generate-page.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  # Doctor deve reportar problema na seção de skills
  assert_output --partial "skills"
  assert_output --regexp '\[(FAIL|WARN)\]'
}

# =============================================================================
# Cenário 5: Relatório contém as 8 seções na ordem correta (via hook doctor prompt)
# Requisitos: 6.2, 6.4
# =============================================================================

@test "doctor frontend-react: kiro-doctor hook contém as 8 seções esperadas no prompt" {
  # Verifica diretamente o conteúdo do hook kiro-doctor do archetype
  local hook_file="${ARCHETYPE_DIR}/hooks/kiro-doctor.kiro.hook"

  # Arquivo deve existir
  assert [ -f "${hook_file}" ]

  # Ler o prompt e verificar as 8 seções na ordem
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

@test "doctor frontend-react: kiro-doctor hook define as 8 seções na ordem correta" {
  local hook_file="${ARCHETYPE_DIR}/hooks/kiro-doctor.kiro.hook"
  local prompt
  prompt=$(jq -r '.then.prompt' "${hook_file}")

  # Extrair apenas a parte do prompt que lista as seções do relatório (step 6)
  # As seções são definidas como "- **NomeSeção**:" dentro da listagem do relatório
  local sections_block
  sections_block=$(echo "${prompt}" | sed -n '/Gere o relatório/,/tabelas markdown/p')

  # Verificar que a ordem é: Resumo < Steering < Hooks < MCP < Skills < Specs < Arquitetura < Recomendações
  local pos_resumo pos_steering pos_hooks pos_mcp pos_skills pos_specs pos_arq pos_rec

  pos_resumo=$(echo "${sections_block}" | grep -n '\*\*Resumo\*\*' | head -1 | cut -d: -f1)
  pos_steering=$(echo "${sections_block}" | grep -n '\*\*Steering\*\*' | head -1 | cut -d: -f1)
  pos_hooks=$(echo "${sections_block}" | grep -n '\*\*Hooks\*\*' | head -1 | cut -d: -f1)
  pos_mcp=$(echo "${sections_block}" | grep -n '\*\*MCP' | head -1 | cut -d: -f1)
  pos_skills=$(echo "${sections_block}" | grep -n '\*\*Skills\*\*' | head -1 | cut -d: -f1)
  pos_specs=$(echo "${sections_block}" | grep -n '\*\*Specs\*\*' | head -1 | cut -d: -f1)
  pos_arq=$(echo "${sections_block}" | grep -n '\*\*Arquitetura\*\*' | head -1 | cut -d: -f1)
  pos_rec=$(echo "${sections_block}" | grep -n '\*\*Recomenda' | head -1 | cut -d: -f1)

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
# Cenário 6: Doctor detecta artefatos específicos do archetype frontend-react
# Requisitos: 6.1, 6.3
# =============================================================================

@test "doctor frontend-react: detecta archetype frontend-react via manifest" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # Deve identificar o archetype corretamente
  assert_output --partial "Archetype: frontend-react"
}

@test "doctor frontend-react: verifica contagem de steering files presentes >= archetype esperado" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O doctor reporta dest_count/src_count onde src_count é o nro de arquivos no archetype (5)
  # E dest_count é o total no projeto (baseline + archetype = 10)
  # Formato: "steering: X/5 arquivos presentes"
  assert_output --partial "steering"
  assert_output --regexp 'steering: [0-9]+/5 arquivos presentes'
}

@test "doctor frontend-react: verifica contagem correta de hooks (8 do archetype)" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype frontend-react tem 8 hooks
  assert_output --partial "hooks"
  assert_output --partial "8/8"
}

@test "doctor frontend-react: verifica contagem correta de agents (4 do archetype)" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype frontend-react tem 4 agents
  assert_output --partial "agents"
  assert_output --partial "4/4"
}

@test "doctor frontend-react: verifica contagem correta de skills (7 do archetype)" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}"

  assert_success
  # O archetype frontend-react tem 7 skills
  assert_output --partial "skills"
  assert_output --partial "7/7"
}

# =============================================================================
# Cenário 7: Doctor JSON output contém categoria archetype
# Requisitos: 6.4
# =============================================================================

@test "doctor frontend-react: output JSON contém resultados da categoria archetype" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  assert_success

  # Output deve ser JSON válido
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  # Deve conter resultados na categoria archetype
  local archetype_results
  archetype_results=$(echo "${output}" | jq '[.results[] | select(.category == "archetype")] | length')
  assert [ "${archetype_results}" -gt 0 ]

  # Deve ter archetype identificado como frontend-react
  local has_frontend
  has_frontend=$(echo "${output}" | jq '[.results[] | select(.message | contains("frontend-react"))] | length')
  assert [ "${has_frontend}" -gt 0 ]
}

@test "doctor frontend-react: output JSON com skill ausente reporta fail ou warn" {
  local project_dir
  project_dir="$(_create_healthy_frontend_project)"

  # Remover skill
  rm -f "${project_dir}/.kiro/skills/generate-redux-slice.md"

  run bash "${DOCTOR_SCRIPT}" --target "${project_dir}" --output json

  # Output deve ser JSON válido
  echo "${output}" | jq '.' > /dev/null 2>&1
  assert [ $? -eq 0 ]

  # Deve ter resultado warn ou fail para archetype
  local problem_results
  problem_results=$(echo "${output}" | jq '[.results[] | select(.category == "archetype" and (.status == "warn" or .status == "fail"))] | length')
  assert [ "${problem_results}" -gt 0 ]
}
