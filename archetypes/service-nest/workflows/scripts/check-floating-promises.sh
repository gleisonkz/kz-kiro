#!/usr/bin/env bash
set -euo pipefail

# check-floating-promises.sh — Heurística para detectar possíveis floating promises em
# services/controllers NestJS (viola @typescript-eslint/no-floating-promises).
# Uso: ./check-floating-promises.sh <arquivo-com-lista-de-arquivos-alterados> [diretorio-resultados]
# Se o primeiro argumento não for fornecido, lê de stdin.
#
# Nota: a verificação autoritativa é o ESLint (no-floating-promises: error). Este script é
# um sinalizador leve para o CI destacar pontos suspeitos rapidamente.

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

# Métodos comuns que retornam Promise e cujo resultado não deve ser descartado
PROMISE_CALLS=(
  "\.emit\("
  "\.send\("
  "\.publish\("
  "\.add\("
  "\.save\("
  "\.execute\("
  "\.executeTakeFirst\("
)

while IFS= read -r file; do
  # Ignorar linhas vazias
  [ -z "$file" ] && continue

  # Apenas services e controllers TS (não .d.ts, não testes, não schemas gerados)
  if [[ "$file" != *.service.ts && "$file" != *.controller.ts && "$file" != *.processor.ts ]]; then
    continue
  fi
  if [[ "$file" == *.spec.ts || "$file" == *"/kysely/schemas/"* ]]; then
    continue
  fi
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

    # Ignorar linhas que já tratam a Promise (await, return, void, atribuição, encadeamento)
    if echo "$line" | grep -qE '(await |return |void |=\s*|\.then\(|\.catch\()'; then
      continue
    fi

    for pattern in "${PROMISE_CALLS[@]}"; do
      # A linha começa (após indentação) com uma chamada que retorna Promise, sem tratamento
      if echo "$TRIMMED" | grep -qE "^[a-zA-Z_][a-zA-Z0-9_.]*${pattern}"; then
        DISPLAY=$(echo "$pattern" | sed 's/\\(/(/g; s/\\//g')
        VIOLATION=$(jq -n \
          --arg rule_id "no_floating_promises" \
          --arg severity "error" \
          --arg file "$file" \
          --argjson line "$LINE_NUM" \
          --arg message "Possível floating promise: chamada '${DISPLAY}' sem await/void/return." \
          --arg suggestion "Use await, return, void ou trate com .catch(). Confirme com o ESLint (no-floating-promises)." \
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
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/floating-promises.json"

echo "✓ check-floating-promises.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
