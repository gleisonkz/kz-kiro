#!/usr/bin/env bash
set -euo pipefail

# run-kiro-agent.sh — Invoca o Kiro Agent para revisão de código no PR.
#
# Verifica se o agent está habilitado no review-rules.yml, executa o Kiro CLI
# em modo headless e gera um ReviewResult JSON para consolidação posterior.
#
# Variáveis de ambiente:
#   REVIEW_RULES_PATH  - Caminho para o review-rules.yml (default: review-rules.yml)
#   RESULTS_DIR        - Diretório para salvar o resultado JSON (default: /tmp/review-results)
#
# Saída: $RESULTS_DIR/agent.json
#
# Requirements: 7.1, 7.2, 7.3, 7.4, 7.5

REVIEW_RULES_PATH="${REVIEW_RULES_PATH:-review-rules.yml}"
RESULTS_DIR="${RESULTS_DIR:-/tmp/review-results}"

mkdir -p "$RESULTS_DIR"

OUTPUT_FILE="$RESULTS_DIR/agent.json"

# ─── Funções auxiliares ───────────────────────────────────────────────────────

# Gera JSON de resultado e salva no arquivo de saída
write_result() {
  local status="$1"
  local message="${2:-}"
  local raw_output="${3:-}"

  if [ -n "$raw_output" ]; then
    jq -n \
      --arg step "agent" \
      --arg status "$status" \
      --arg raw_output "$raw_output" \
      '{step: $step, status: $status, violations: [], raw_output: $raw_output}' > "$OUTPUT_FILE"
  elif [ -n "$message" ]; then
    jq -n \
      --arg step "agent" \
      --arg status "$status" \
      --arg message "$message" \
      '{step: $step, status: $status, violations: [{rule_id: "agent_error", severity: "warn", message: $message}]}' > "$OUTPUT_FILE"
  else
    jq -n \
      --arg step "agent" \
      --arg status "$status" \
      '{step: $step, status: $status, violations: []}' > "$OUTPUT_FILE"
  fi
}

# ─── Utilitário para leitura de YAML ──────────────────────────────────────────

# Extrai um valor do YAML usando python3 (mais portável que yq)
yaml_get() {
  local file="$1"
  local key_path="$2"
  local default_value="${3:-}"

  local result
  result=$(python3 -c "
import yaml, sys
try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    keys = '$key_path'.split('.')
    val = data
    for k in keys:
        if val is None or not isinstance(val, dict):
            val = None
            break
        val = val.get(k)
    if val is None:
        print('$default_value')
    else:
        print(str(val).lower() if isinstance(val, bool) else val)
except Exception:
    print('$default_value')
" 2>/dev/null) || result="$default_value"

  echo "$result"
}

# ─── Verificar se review-rules.yml existe ────────────────────────────────────

if [ ! -f "$REVIEW_RULES_PATH" ]; then
  echo "⚠ Arquivo $REVIEW_RULES_PATH não encontrado. Pulando revisão via agent."
  write_result "skipped"
  exit 0
fi

# ─── Verificar se agent_review está habilitado ────────────────────────────────

AGENT_ENABLED=$(yaml_get "$REVIEW_RULES_PATH" "agent_review.enabled" "false")

if [ "$AGENT_ENABLED" != "true" ]; then
  echo "ℹ Revisão via agent desabilitada em $REVIEW_RULES_PATH."
  write_result "skipped"
  exit 0
fi

# ─── Verificar se o Kiro CLI está disponível ─────────────────────────────────

if ! command -v kiro &>/dev/null; then
  echo "⚠ Kiro CLI não encontrado no PATH. Pulando revisão via agent."
  write_result "skipped"
  exit 0
fi

# ─── Extrair configurações do agent ──────────────────────────────────────────

AGENT_NAME=$(yaml_get "$REVIEW_RULES_PATH" "agent_review.agent" "code-reviewer")
TIMEOUT_SECONDS=$(yaml_get "$REVIEW_RULES_PATH" "agent_review.timeout_seconds" "300")

echo "🤖 Executando Kiro Agent: $AGENT_NAME (timeout: ${TIMEOUT_SECONDS}s)"

# ─── Executar o Kiro Agent ────────────────────────────────────────────────────

# Detectar comando timeout disponível (GNU timeout em Linux, gtimeout em macOS)
TIMEOUT_CMD=""
if command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout"
fi

AGENT_OUTPUT=""
EXIT_CODE=0

if [ -n "$TIMEOUT_CMD" ]; then
  AGENT_OUTPUT=$($TIMEOUT_CMD "${TIMEOUT_SECONDS}s" kiro agent run --no-interactive --agent "$AGENT_NAME" 2>&1) || EXIT_CODE=$?
else
  # Sem comando timeout disponível, executar diretamente (sem proteção de timeout)
  AGENT_OUTPUT=$(kiro agent run --no-interactive --agent "$AGENT_NAME" 2>&1) || EXIT_CODE=$?
fi

# ─── Tratar resultado da execução ────────────────────────────────────────────

# Timeout (exit code 124 do comando timeout)
if [ "$EXIT_CODE" -eq 124 ]; then
  echo "⏱ Kiro Agent excedeu o timeout de ${TIMEOUT_SECONDS}s."
  write_result "error" "Revisão via agent não concluída: timeout de ${TIMEOUT_SECONDS}s excedido."
  exit 0
fi

# Outro erro de execução
if [ "$EXIT_CODE" -ne 0 ]; then
  ERROR_MSG="Revisão via agent falhou com código de saída $EXIT_CODE."
  if [ -n "$AGENT_OUTPUT" ]; then
    # Truncar output muito longo para evitar JSON inválido
    TRUNCATED_OUTPUT=$(echo "$AGENT_OUTPUT" | head -c 2000)
    ERROR_MSG="Revisão via agent falhou (exit $EXIT_CODE): $TRUNCATED_OUTPUT"
  fi
  echo "❌ Erro na execução do Kiro Agent (exit code: $EXIT_CODE)."
  write_result "error" "$ERROR_MSG"
  exit 0
fi

# Sem output (agent executou sem feedback)
if [ -z "$AGENT_OUTPUT" ] || [ -z "$(echo "$AGENT_OUTPUT" | tr -d '[:space:]')" ]; then
  echo "✓ Kiro Agent executou sem feedback. Nenhum problema encontrado."
  write_result "pass"
  exit 0
fi

# Com output (agent produziu feedback para formatação posterior)
echo "📝 Kiro Agent produziu feedback. Salvando para formatação posterior."
write_result "fail" "" "$AGENT_OUTPUT"
exit 0
