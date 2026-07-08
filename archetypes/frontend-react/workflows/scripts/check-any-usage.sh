#!/usr/bin/env bash
set -euo pipefail

# check-any-usage.sh — Detecta uso de `any` em TypeScript (.ts/.tsx).
# Padrões buscados: `: any`, `as any`, `<any>`
# Exclui: node_modules, .d.ts, arquivos de teste
# Uso: ./check-any-usage.sh [diretorio-resultados]

RESULTS_DIR="${1:-${RESULTS_DIR:-/tmp/review-results}}"
mkdir -p "$RESULTS_DIR"

VIOLATIONS="[]"

# Buscar padrões de uso de `any` em arquivos .ts e .tsx
# Exclui node_modules, arquivos de declaração (.d.ts), dist, .next
while IFS= read -r match; do
  [ -z "$match" ] && continue

  # Formato do grep: arquivo:linha:conteudo
  FILE=$(echo "$match" | cut -d: -f1)
  LINE_NUM=$(echo "$match" | cut -d: -f2)
  LINE_CONTENT=$(echo "$match" | cut -d: -f3-)

  # Determinar qual padrão foi encontrado
  if echo "$LINE_CONTENT" | grep -qE ':\s*any\b'; then
    PATTERN=": any"
  elif echo "$LINE_CONTENT" | grep -q 'as any'; then
    PATTERN="as any"
  elif echo "$LINE_CONTENT" | grep -q '<any>'; then
    PATTERN="<any>"
  else
    PATTERN="any"
  fi

  VIOLATION=$(jq -n \
    --arg rule_id "typescript_any_usage" \
    --arg severity "warn" \
    --arg file "$FILE" \
    --argjson line "$LINE_NUM" \
    --arg message "Uso de '$PATTERN' detectado. Prefira tipos específicos para melhor type safety." \
    --arg suggestion "Substitua 'any' por um tipo mais específico (unknown, Record<string, unknown>, ou um tipo dedicado)." \
    '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
  VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')

done < <(grep -rn --include="*.ts" --include="*.tsx" \
  --exclude-dir="node_modules" \
  --exclude-dir=".next" \
  --exclude-dir="dist" \
  --exclude="*.d.ts" \
  --exclude="*.test.*" \
  --exclude="*.spec.*" \
  -E ':\s*any\b|as any\b|<any>' . 2>/dev/null || true)

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
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/any-usage.json"

echo "✓ check-any-usage.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
