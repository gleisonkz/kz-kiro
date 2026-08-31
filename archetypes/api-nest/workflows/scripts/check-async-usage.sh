#!/usr/bin/env bash
set -euo pipefail

# check-async-usage.sh — Detecta anti-padrões de async em arquivos TypeScript (NestJS).
# Uso: ./check-async-usage.sh <arquivo-com-lista-de-arquivos-alterados> [diretorio-resultados]
# Se o primeiro argumento não for fornecido, lê de stdin.

RESULTS_DIR="${2:-${RESULTS_DIR:-/tmp/review-results}}"
mkdir -p "$RESULTS_DIR"

# Ler lista de arquivos alterados
if [ -n "${1:-}" ] && [ -f "$1" ]; then
  CHANGED_FILES=$(cat "$1")
elif [ ! -t 0 ]; then
  CHANGED_FILES=$(cat)
else
  echo "Erro: forneça um arquivo com a lista de arquivos alterados ou passe via stdin." >&2
  exit 1
fi

VIOLATIONS="[]"

# Anti-padrões de async/Promise em TypeScript que indicam problema
SYNC_IO_PATTERNS=(
  "readFileSync"
  "writeFileSync"
  "existsSync"
  "execSync"
  "\.end\(\)\.then"
  "new Promise\(async"
)

while IFS= read -r file; do
  # Ignorar linhas vazias
  [ -z "$file" ] && continue

  # Verificar apenas arquivos .ts (não .d.ts)
  if [[ "$file" != *.ts ]] || [[ "$file" == *.d.ts ]]; then
    continue
  fi

  # Ignorar arquivos de teste
  if [[ "$file" == *.spec.ts || "$file" == *.e2e-spec.ts || "$file" == */test/* ]]; then
    continue
  fi

  # Ignorar schemas Kysely gerados
  if [[ "$file" == *"/kysely/schemas/"* ]]; then
    continue
  fi

  # Verificar se o arquivo existe
  if [ ! -f "$file" ]; then
    continue
  fi

  LINE_NUM=0
  while IFS= read -r line; do
    LINE_NUM=$((LINE_NUM + 1))

    # Ignorar comentários
    TRIMMED=$(echo "$line" | sed 's/^[[:space:]]*//')
    if [[ "$TRIMMED" == //* ]] || [[ "$TRIMMED" == \** ]]; then
      continue
    fi

    for pattern in "${SYNC_IO_PATTERNS[@]}"; do
      if echo "$line" | grep -qE "$pattern"; then
        DISPLAY_PATTERN=$(echo "$pattern" | sed 's/\\//g')
        VIOLATION=$(jq -n \
          --arg rule_id "no_async_usage" \
          --arg severity "error" \
          --arg file "$file" \
          --argjson line "$LINE_NUM" \
          --arg message "Anti-padrão de I/O síncrono/async detectado: $DISPLAY_PATTERN" \
          --arg suggestion "Prefira a variante assíncrona (ex: fs/promises) e use async/await corretamente." \
          '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
        VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
        break
      fi
    done
  done < "$file"
done <<< "$CHANGED_FILES"

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
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/async-usage.json"

echo "✓ check-async-usage.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
