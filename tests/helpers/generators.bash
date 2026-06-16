#!/usr/bin/env bash
# generators.bash — Geradores de dados aleatórios para property-based testing
# Este arquivo é sourced pelos testes bats, não executado diretamente.
#
# Cada gerador produz dados válidos ou inválidos para validação de propriedades.
# Usa $RANDOM e /dev/urandom para aleatoriedade.

# --- Utilitários internos ---

# Gera inteiro aleatório entre min e max (inclusive)
_rand_int() {
  local min="${1:-0}"
  local max="${2:-100}"
  echo $(( (RANDOM % (max - min + 1)) + min ))
}

# Gera string alfanumérica aleatória de comprimento N
_rand_alphanum() {
  local len="${1:-8}"
  LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$len"
}

# Gera string alfabética aleatória de comprimento N
_rand_alpha() {
  local len="${1:-8}"
  LC_ALL=C tr -dc 'a-zA-Z' < /dev/urandom | head -c "$len"
}

# Gera string lowercase aleatória de comprimento N
_rand_lower() {
  local len="${1:-8}"
  LC_ALL=C tr -dc 'a-z' < /dev/urandom | head -c "$len"
}

# Escolhe item aleatório de uma lista de argumentos
_rand_choice() {
  local items=("$@")
  local idx=$(( RANDOM % ${#items[@]} ))
  echo "${items[$idx]}"
}

# --- Geradores de semver ---

# Gera uma versão semver válida: MAJOR.MINOR.PATCH
# Sem prefixo v, sem zeros à esquerda, sem espaços
gen_semver() {
  local major minor patch

  # Primeiro segmento: 0 ou 1-99 (sem zeros à esquerda)
  if (( RANDOM % 5 == 0 )); then
    major=0
  else
    major=$(_rand_int 1 99)
  fi

  if (( RANDOM % 5 == 0 )); then
    minor=0
  else
    minor=$(_rand_int 1 99)
  fi

  if (( RANDOM % 5 == 0 )); then
    patch=0
  else
    patch=$(_rand_int 1 99)
  fi

  echo "${major}.${minor}.${patch}"
}

# Gera uma string que NÃO é semver válida
gen_invalid_semver() {
  local strategy
  strategy=$(_rand_int 0 8)

  case "$strategy" in
    0) # Prefixo v
      echo "v$(gen_semver)"
      ;;
    1) # Zero à esquerda no major
      echo "01.$(_rand_int 0 99).$(_rand_int 0 99)"
      ;;
    2) # Zero à esquerda no minor
      echo "$(_rand_int 0 99).01.$(_rand_int 0 99)"
      ;;
    3) # Zero à esquerda no patch
      echo "$(_rand_int 0 99).$(_rand_int 0 99).01"
      ;;
    4) # Apenas dois segmentos
      echo "$(_rand_int 0 99).$(_rand_int 0 99)"
      ;;
    5) # Quatro segmentos
      echo "$(_rand_int 0 99).$(_rand_int 0 99).$(_rand_int 0 99).$(_rand_int 0 99)"
      ;;
    6) # Com espaços
      echo " $(_rand_int 0 9).$(_rand_int 0 9).$(_rand_int 0 9) "
      ;;
    7) # Letras no meio
      echo "$(_rand_int 0 99).abc.$(_rand_int 0 99)"
      ;;
    8) # String vazia ou aleatória
      _rand_alpha "$(_rand_int 1 10)"
      ;;
  esac
}

# --- Geradores de frontmatter ---

# Gera conteúdo markdown com frontmatter YAML válido
gen_frontmatter() {
  local inclusion
  inclusion=$(_rand_choice "manual" "auto" "fileMatch")

  local frontmatter="---\ninclusion: ${inclusion}"

  if [[ "$inclusion" == "fileMatch" ]]; then
    local pattern
    pattern=$(_rand_choice "**/*.ts" "**/*.md" "**/package.json" "src/**/*.js" "**/*.yaml")
    frontmatter="${frontmatter}\nfileMatchPattern: \"${pattern}\""
  fi

  frontmatter="${frontmatter}\n---"

  # Adiciona corpo markdown aleatório
  local title
  title="$(_rand_alpha "$(_rand_int 5 20)")"

  printf '%b\n\n# %s\n\nConteúdo gerado para teste.\n' "$frontmatter" "$title"
}

# Gera conteúdo markdown com frontmatter INVÁLIDO
gen_invalid_frontmatter() {
  local strategy
  strategy=$(_rand_int 0 5)

  case "$strategy" in
    0) # Sem frontmatter (sem delimitadores ---)
      echo "# Título sem frontmatter"
      echo ""
      echo "Conteúdo sem YAML frontmatter."
      ;;
    1) # inclusion com valor inválido
      printf '%b\n' "---\ninclusion: invalid_value\n---\n\n# Teste"
      ;;
    2) # fileMatch sem fileMatchPattern
      printf '%b\n' "---\ninclusion: fileMatch\n---\n\n# Teste sem pattern"
      ;;
    3) # fileMatchPattern vazio com fileMatch
      printf '%b\n' "---\ninclusion: fileMatch\nfileMatchPattern: \"\"\n---\n\n# Teste"
      ;;
    4) # Campo inclusion ausente
      printf '%b\n' "---\ntitle: alguma coisa\n---\n\n# Teste sem inclusion"
      ;;
    5) # Delimitador de abertura sem fechamento
      printf '%b\n' "---\ninclusion: manual\n\n# Sem fechamento de frontmatter"
      ;;
  esac
}

# --- Geradores de mcp.json ---

# Gera um objeto JSON mcp.json válido
gen_mcp_json() {
  local version num_servers
  version="$(gen_semver)"
  num_servers=$(_rand_int 1 3)

  local servers=""
  local i
  for (( i = 0; i < num_servers; i++ )); do
    local server_name="_server_$(_rand_lower "$(_rand_int 3 8)")"
    local comment="Servidor $(_rand_alpha 5) para teste"
    local server_obj

    # url OU command+args (nunca ambos)
    if (( RANDOM % 2 == 0 )); then
      # Servidor HTTP (url)
      server_obj=$(cat <<SEOF
    "${server_name}": {
      "_comment": "${comment}",
      "url": "https://$(_rand_lower 6).example.com/mcp",
      "disabled": $(_rand_choice "true" "false"),
      "autoApprove": []
    }
SEOF
)
    else
      # Servidor processo (command + args)
      server_obj=$(cat <<SEOF
    "${server_name}": {
      "_comment": "${comment}",
      "command": "$(_rand_lower 4)",
      "args": ["run", "--$(_rand_lower 4)"],
      "disabled": $(_rand_choice "true" "false"),
      "autoApprove": []
    }
SEOF
)
    fi

    if [[ -n "$servers" ]]; then
      servers="${servers},
${server_obj}"
    else
      servers="$server_obj"
    fi
  done

  cat <<EOF
{
  "_comment": "MCP config gerado para teste - $(_rand_alpha 8)",
  "_version": "${version}",
  "mcpServers": {
${servers}
  }
}
EOF
}

# Gera um objeto JSON mcp.json INVÁLIDO
gen_invalid_mcp_json() {
  local strategy
  strategy=$(_rand_int 0 6)

  case "$strategy" in
    0) # Sem _comment
      cat <<EOF
{
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "_comment": "test",
      "url": "https://example.com/mcp",
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    1) # _comment vazio
      cat <<EOF
{
  "_comment": "",
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "_comment": "test",
      "url": "https://example.com/mcp",
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    2) # _version inválida (não-semver)
      cat <<EOF
{
  "_comment": "test config",
  "_version": "invalid",
  "mcpServers": {
    "server1": {
      "_comment": "test",
      "url": "https://example.com/mcp",
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    3) # mcpServers vazio (zero servidores)
      cat <<EOF
{
  "_comment": "test config",
  "_version": "1.0.0",
  "mcpServers": {}
}
EOF
      ;;
    4) # Servidor com url E command (ambos — violação)
      cat <<EOF
{
  "_comment": "test config",
  "_version": "1.0.0",
  "mcpServers": {
    "bad_server": {
      "_comment": "servidor inválido",
      "url": "https://example.com/mcp",
      "command": "node",
      "args": ["server.js"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    5) # Servidor sem url nem command
      cat <<EOF
{
  "_comment": "test config",
  "_version": "1.0.0",
  "mcpServers": {
    "no_conn": {
      "_comment": "sem conexão",
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
      ;;
    6) # autoApprove não-vazio
      cat <<EOF
{
  "_comment": "test config",
  "_version": "1.0.0",
  "mcpServers": {
    "server1": {
      "_comment": "test",
      "url": "https://example.com/mcp",
      "disabled": false,
      "autoApprove": ["read"]
    }
  }
}
EOF
      ;;
  esac
}

# --- Geradores de exceção ---

# Gera um objeto de exceção válido (JSON)
gen_exception() {
  local component rule_name reason approved_by approved_at review_date
  component=$(_rand_choice "baseline" "archetype" "steering" "mcp" "hooks")
  rule_name=$(_rand_choice "missing-file" "outdated-config" "version-mismatch" "custom-rule" "schema-violation")

  # reason: 20-500 chars
  local base_reason="Justificativa tecnica para excecao do baseline "
  local extra_len
  extra_len=$(_rand_int 1 40)
  reason="${base_reason}$(_rand_alphanum "$extra_len")"

  approved_by="$(_rand_alpha 3).$(_rand_alpha 5)@montebravo.com"

  # approved_at: data ISO 8601 recente (últimos 30 dias)
  local days_ago
  days_ago=$(_rand_int 1 30)
  if command -v gdate &>/dev/null; then
    approved_at=$(gdate -u -d "${days_ago} days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
  elif date -u -d "${days_ago} days ago" +%Y-%m-%dT%H:%M:%SZ &>/dev/null; then
    approved_at=$(date -u -d "${days_ago} days ago" +%Y-%m-%dT%H:%M:%SZ)
  else
    # macOS fallback
    approved_at=$(date -u -v-${days_ago}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
  fi

  # review_date: max 90 dias de approved_at (geramos entre 30 e 89 dias após approved_at)
  local review_days
  review_days=$(_rand_int 30 89)
  if command -v gdate &>/dev/null; then
    review_date=$(gdate -u -d "${days_ago} days ago + ${review_days} days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
  elif date -u -d "${days_ago} days ago + ${review_days} days" +%Y-%m-%dT%H:%M:%SZ &>/dev/null; then
    review_date=$(date -u -d "${days_ago} days ago + ${review_days} days" +%Y-%m-%dT%H:%M:%SZ)
  else
    # macOS fallback
    local net_days=$(( review_days - days_ago ))
    if (( net_days >= 0 )); then
      review_date=$(date -u -v+${net_days}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    else
      review_date=$(date -u -v${net_days}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    fi
  fi

  cat <<EOF
{
  "rule": "${component}.${rule_name}",
  "reason": "${reason}",
  "approved_by": "${approved_by}",
  "approved_at": "${approved_at}",
  "review_date": "${review_date}"
}
EOF
}

# Gera um objeto de exceção INVÁLIDO (JSON)
gen_invalid_exception() {
  local strategy
  strategy=$(_rand_int 0 6)

  case "$strategy" in
    0) # rule sem formato componente.nome (sem ponto)
      cat <<EOF
{
  "rule": "regra_sem_ponto",
  "reason": "Justificativa com mais de vinte caracteres para teste",
  "approved_by": "admin@montebravo.com",
  "approved_at": "2024-01-15T10:00:00Z",
  "review_date": "2024-03-15T10:00:00Z"
}
EOF
      ;;
    1) # reason muito curta (< 20 chars)
      cat <<EOF
{
  "rule": "baseline.missing-file",
  "reason": "curta",
  "approved_by": "admin@montebravo.com",
  "approved_at": "2024-01-15T10:00:00Z",
  "review_date": "2024-03-15T10:00:00Z"
}
EOF
      ;;
    2) # approved_by vazio
      cat <<EOF
{
  "rule": "steering.outdated",
  "reason": "Justificativa tecnica valida com mais de vinte chars",
  "approved_by": "",
  "approved_at": "2024-01-15T10:00:00Z",
  "review_date": "2024-03-15T10:00:00Z"
}
EOF
      ;;
    3) # approved_at não é ISO 8601
      cat <<EOF
{
  "rule": "mcp.schema-violation",
  "reason": "Justificativa tecnica valida com mais de vinte chars",
  "approved_by": "admin@montebravo.com",
  "approved_at": "15/01/2024 10:00",
  "review_date": "2024-03-15T10:00:00Z"
}
EOF
      ;;
    4) # review_date excede 90 dias de approved_at
      cat <<EOF
{
  "rule": "hooks.custom-rule",
  "reason": "Justificativa tecnica valida com mais de vinte chars",
  "approved_by": "admin@montebravo.com",
  "approved_at": "2024-01-01T10:00:00Z",
  "review_date": "2024-07-01T10:00:00Z"
}
EOF
      ;;
    5) # Campo rule ausente
      cat <<EOF
{
  "reason": "Justificativa tecnica valida com mais de vinte chars",
  "approved_by": "admin@montebravo.com",
  "approved_at": "2024-01-15T10:00:00Z",
  "review_date": "2024-03-15T10:00:00Z"
}
EOF
      ;;
    6) # reason com mais de 500 chars
      local long_reason
      long_reason="$(_rand_alphanum 501)"
      cat <<EOF
{
  "rule": "baseline.version-mismatch",
  "reason": "${long_reason}",
  "approved_by": "admin@montebravo.com",
  "approved_at": "2024-01-15T10:00:00Z",
  "review_date": "2024-03-15T10:00:00Z"
}
EOF
      ;;
  esac
}

# --- Geradores de steering file ---

# Gera um arquivo markdown completo com frontmatter válido
gen_steering_file() {
  local inclusion
  inclusion=$(_rand_choice "manual" "auto" "fileMatch")

  local content="---\ninclusion: ${inclusion}"

  if [[ "$inclusion" == "fileMatch" ]]; then
    local pattern
    pattern=$(_rand_choice "**/*.ts" "**/*.md" "**/package.json" "src/**/*.js" "**/*.yaml" "**/*.py")
    content="${content}\nfileMatchPattern: \"${pattern}\""
  fi

  content="${content}\n---\n"

  # Gera corpo markdown com seções aleatórias
  local title num_sections
  title="$(_rand_alpha "$(_rand_int 8 20)")"
  num_sections=$(_rand_int 1 4)

  content="${content}\n# ${title}\n"

  local s
  for (( s = 0; s < num_sections; s++ )); do
    local section_title
    section_title="$(_rand_alpha "$(_rand_int 5 15)")"
    content="${content}\n## ${section_title}\n\n$(_rand_alpha "$(_rand_int 20 60)")\n"
  done

  printf '%b' "$content"
}

# --- Geradores de hook JSON ---

# Gera um JSON de hook válido (.kiro.hook)
gen_hook_json() {
  local name description version when_type then_type prompt_or_command

  name="$(_rand_alpha "$(_rand_int 5 15)")"
  description="Hook de teste: $(_rand_alpha "$(_rand_int 10 30)")"
  version="$(_rand_int 1 5)"
  when_type=$(_rand_choice "userTriggered" "fileEdited" "fileCreated" "promptSubmit")
  then_type=$(_rand_choice "askAgent" "runCommand")

  if [[ "$then_type" == "askAgent" ]]; then
    prompt_or_command="\"prompt\": \"$(_rand_alpha "$(_rand_int 10 40)")\""
  else
    prompt_or_command="\"command\": \"$(_rand_lower 4) $(_rand_lower 4)\""
  fi

  cat <<EOF
{
  "enabled": $(_rand_choice "true" "false"),
  "name": "${name}",
  "description": "${description}",
  "version": "${version}",
  "when": {
    "type": "${when_type}"
  },
  "then": {
    "type": "${then_type}",
    ${prompt_or_command}
  }
}
EOF
}

# --- Geradores de project type ---

# Retorna um archetype válido aleatório
gen_project_type() {
  _rand_choice "backend-csharp" "bff-fastify" "frontend-react"
}
