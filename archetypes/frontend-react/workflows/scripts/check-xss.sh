#!/usr/bin/env bash
set -euo pipefail

# check-xss.sh — Detecta uso de dangerouslySetInnerHTML sem sanitização.
# Seguro se:
#   1. A linha anterior contém o comentário `// @safe-html`
#   2. O valor passa por DOMPurify.sanitize() ou sanitize() na mesma expressão
# Caso contrário: reporta xss_vulnerability (severity: error)
# Uso: ./check-xss.sh [diretorio-resultados]

RESULTS_DIR="${1:-${RESULTS_DIR:-/tmp/review-results}}"
mkdir -p "$RESULTS_DIR"

VIOLATIONS="[]"

# Buscar ocorrências de dangerouslySetInnerHTML em .tsx/.ts
while IFS= read -r match; do
  [ -z "$match" ] && continue

  FILE=$(echo "$match" | cut -d: -f1)
  LINE_NUM=$(echo "$match" | cut -d: -f2)
  LINE_CONTENT=$(echo "$match" | cut -d: -f3-)

  IS_SAFE=false

  # Verificar se a linha anterior tem o comentário // @safe-html
  if [ "$LINE_NUM" -gt 1 ]; then
    PREV_LINE_NUM=$((LINE_NUM - 1))
    PREV_LINE=$(sed -n "${PREV_LINE_NUM}p" "$FILE" 2>/dev/null || true)
    if echo "$PREV_LINE" | grep -q '// @safe-html'; then
      IS_SAFE=true
    fi
  fi

  # Verificar se o valor passa por sanitização (DOMPurify.sanitize, sanitize(), sanitizeHtml())
  if [ "$IS_SAFE" = false ]; then
    # Verificar na mesma linha e nas próximas 3 linhas (para expressões multi-linha)
    CONTEXT_END=$((LINE_NUM + 3))
    CONTEXT=$(sed -n "${LINE_NUM},${CONTEXT_END}p" "$FILE" 2>/dev/null || true)

    if echo "$CONTEXT" | grep -qE 'DOMPurify\.sanitize|sanitize\(|sanitizeHtml\(|xss\(|purify\('; then
      IS_SAFE=true
    fi
  fi

  if [ "$IS_SAFE" = false ]; then
    VIOLATION=$(jq -n \
      --arg rule_id "xss_vulnerability" \
      --arg severity "error" \
      --arg file "$FILE" \
      --argjson line "$LINE_NUM" \
      --arg message "Uso de dangerouslySetInnerHTML sem sanitização detectado. Risco de XSS." \
      --arg suggestion "Use DOMPurify.sanitize() para sanitizar o HTML, ou adicione '// @safe-html' na linha anterior se o conteúdo for confiável." \
      '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
    VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
  fi

done < <(grep -rn --include="*.tsx" --include="*.ts" \
  --exclude-dir="node_modules" \
  --exclude-dir=".next" \
  --exclude-dir="dist" \
  --exclude="*.test.*" \
  --exclude="*.spec.*" \
  'dangerouslySetInnerHTML' . 2>/dev/null || true)

# Determinar status
VIOLATION_COUNT=$(echo "$VIOLATIONS" | jq 'length')
if [ "$VIOLATION_COUNT" -gt 0 ]; then
  STATUS="fail"
else
  STATUS="pass"
fi

# Gerar resultado JSON
jq -n \
  --arg step "archetype_rules" \
  --arg status "$STATUS" \
  --argjson violations "$VIOLATIONS" \
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/xss.json"

echo "✓ check-xss.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
