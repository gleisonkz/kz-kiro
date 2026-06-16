#!/usr/bin/env bash
# Helpers de setup para testes bats.
# Fornece funções para criar projetos temporários, fixtures de baseline e cleanup.
# Uso: load '../helpers/setup'

# Carrega bats-support para funções auxiliares
load "${BATS_TEST_DIRNAME}/../lib/bats-support/load"

# Arquivo para rastrear diretórios temporários criados durante os testes.
# Necessário porque create_temp_project/create_baseline_fixture são chamados
# via $() (subshell), o que impede persistência de variáveis no shell pai.
_TEST_TEMP_DIRS_FILE="${BATS_TEST_TMPDIR:-/tmp}/.bats_temp_dirs_$$"
: > "${_TEST_TEMP_DIRS_FILE}"

# Cria um diretório temporário simulando um projeto com estrutura .kiro/
# Retorna o caminho do diretório via stdout
create_temp_project() {
  local project_dir
  project_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-project-XXXXXX")"

  mkdir -p "${project_dir}/.kiro/steering"
  mkdir -p "${project_dir}/.kiro/settings"
  mkdir -p "${project_dir}/.kiro/hooks"
  mkdir -p "${project_dir}/.kiro/specs"
  mkdir -p "${project_dir}/.kiro/skills"
  mkdir -p "${project_dir}/.kiro/agents"

  echo "${project_dir}" >> "${_TEST_TEMP_DIRS_FILE}"
  echo "${project_dir}"
}

# Cria um diretório temporário com arquivos de baseline mimicking baselines/global/
# Retorna o caminho do diretório via stdout
create_baseline_fixture() {
  local baseline_dir
  baseline_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-baseline-XXXXXX")"

  # Estrutura de diretórios do baseline
  mkdir -p "${baseline_dir}/steering"
  mkdir -p "${baseline_dir}/mcp"
  mkdir -p "${baseline_dir}/hooks"

  # VERSION — semver sem prefixo v, sem newline final
  printf '0.1.0' > "${baseline_dir}/VERSION"

  # CHANGELOG.md — formato Keep a Changelog
  cat > "${baseline_dir}/CHANGELOG.md" << 'CHANGELOG'
# Changelog

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

## [0.1.0] - 2025-01-01

### Added
- Configuração inicial do baseline global
- Steering files de segurança, documentação e princípios
- MCP servers homologados (Atlassian, GitHub, Context7)
- Hook kiro-doctor para diagnóstico in-IDE
CHANGELOG

  # Steering files com frontmatter válido
  cat > "${baseline_dir}/steering/engineering-principles.md" << 'EOF'
---
inclusion: auto
---
# Princípios de Engenharia
Diretrizes de engenharia da organização.
EOF

  cat > "${baseline_dir}/steering/security-baseline.md" << 'EOF'
---
inclusion: auto
---
# Security Baseline
Práticas de segurança obrigatórias.
EOF

  # mcp.json com schema válido
  cat > "${baseline_dir}/mcp/mcp.json" << 'EOF'
{
  "_comment": "MCPs homologados (fixture de teste)",
  "_version": "0.1.0",
  "mcpServers": {
    "atlassian": {
      "_comment": "Atlassian Rovo MCP",
      "url": "https://mcp.atlassian.com/v1/mcp",
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF

  # Hook global
  cat > "${baseline_dir}/hooks/kiro-doctor.kiro.hook" << 'EOF'
{
  "enabled": true,
  "name": "Kiro Doctor",
  "description": "Diagnóstico de conformidade do projeto.",
  "version": "1",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Analise as configurações do Kiro neste projeto."
  }
}
EOF

  echo "${baseline_dir}" >> "${_TEST_TEMP_DIRS_FILE}"
  echo "${baseline_dir}"
}

# Remove todos os diretórios temporários criados durante o teste
cleanup_fixtures() {
  if [[ -f "${_TEST_TEMP_DIRS_FILE}" ]]; then
    while IFS= read -r dir; do
      if [[ -n "${dir}" && -d "${dir}" ]]; then
        rm -rf "${dir}"
      fi
    done < "${_TEST_TEMP_DIRS_FILE}"
    : > "${_TEST_TEMP_DIRS_FILE}"
  fi
}

# Gera um kiro-manifest.json no diretório de projeto fornecido.
# Uso: setup_manifest <project_dir> [json_override]
#   project_dir: caminho do projeto (deve ter .kiro/)
#   json_override: JSON parcial para sobrescrever campos default (opcional, requer jq)
setup_manifest() {
  local project_dir="$1"
  local override="${2:-}"
  local manifest_path="${project_dir}/.kiro/kiro-manifest.json"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local default_manifest
  default_manifest=$(cat << EOF
{
  "_generated_by": "test-setup",
  "_generated_at": "${now}",
  "schema_version": "1.0.0",
  "project": {
    "name": "test-project",
    "repository": "org/test-project"
  },
  "baseline": {
    "version": "0.1.0",
    "source": "mb/kiro",
    "installed_at": "${now}",
    "last_synced_at": "${now}"
  },
  "archetype": {
    "name": "frontend-react",
    "version": "0.1.0",
    "installed_at": "${now}"
  },
  "powers": [],
  "exceptions": []
}
EOF
)

  if [[ -n "${override}" ]] && command -v jq &>/dev/null; then
    echo "${default_manifest}" | jq --argjson override "${override}" '. * $override' > "${manifest_path}"
  else
    echo "${default_manifest}" > "${manifest_path}"
  fi
}
