#!/usr/bin/env bash
set -euo pipefail

# check-async-usage.sh — Detecta operações de I/O sem async/await em arquivos C#.
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

# Padrões de I/O que devem ser usados com async/await
IO_PATTERNS=(
  "HttpClient"
  "DbContext"
  "\.SaveChanges\b"
  "\.ExecuteAsync\b"
  "\.SendAsync\b"
  "\.GetAsync\b"
  "\.PostAsync\b"
  "\.PutAsync\b"
  "\.DeleteAsync\b"
  "File\."
  "Stream\."
  "\.ReadAsync\b"
  "\.WriteAsync\b"
  "\.FlushAsync\b"
  "SqlConnection"
  "\.ExecuteReader\b"
  "\.ExecuteNonQuery\b"
  "\.ExecuteScalar\b"
  "\.Open\b"
)

# Padrões síncronos de I/O que indicam problema
SYNC_IO_PATTERNS=(
  "\.GetStringAsync\b"
  "\.Result\b"
  "\.Wait()\b"
  "\.GetAwaiter().GetResult()"
  "File\.ReadAllText\b"
  "File\.WriteAllText\b"
  "File\.ReadAllLines\b"
  "File\.WriteAllLines\b"
  "File\.ReadAllBytes\b"
  "File\.WriteAllBytes\b"
  "\.ExecuteReader\b"
  "\.ExecuteNonQuery\b"
  "\.ExecuteScalar\b"
  "\.SaveChanges()\b"
)

while IFS= read -r file; do
  # Ignorar linhas vazias
  [ -z "$file" ] && continue

  # Verificar apenas arquivos .cs
  if [[ "$file" != *.cs ]]; then
    continue
  fi

  # Ignorar arquivos de teste
  if [[ "$file" == *Tests.cs || "$file" == *Test.cs || "$file" == *.Tests/* || "$file" == *Tests/* ]]; then
    continue
  fi

  # Verificar se o arquivo existe
  if [ ! -f "$file" ]; then
    continue
  fi

  # Buscar padrões síncronos de I/O no arquivo
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
        # Verificar se a linha ou o método está marcado como async
        # Buscar declaração do método (simplificado: verifica se existe "async" antes no contexto)
        METHOD_CONTEXT=$(head -n "$LINE_NUM" "$file" | tail -20 | grep -c "async" || true)
        
        # Se usa .Result, .Wait() ou .GetAwaiter().GetResult() é anti-pattern mesmo em contexto async
        if echo "$line" | grep -qE '\.Result\b|\.Wait\(\)|\.GetAwaiter\(\)\.GetResult\(\)'; then
          VIOLATION=$(jq -n \
            --arg rule_id "no_async_usage" \
            --arg severity "error" \
            --arg file "$file" \
            --argjson line "$LINE_NUM" \
            --arg message "Uso síncrono de operação I/O detectado: bloqueio via .Result/.Wait()/.GetResult()" \
            --arg suggestion "Use 'await' em vez de .Result/.Wait()/.GetResult() para evitar deadlocks." \
            '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
          VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
          break
        fi

        # Se usa variante síncrona de File/DB sem estar em método async
        if [ "${METHOD_CONTEXT:-0}" -eq 0 ]; then
          # Limpar pattern para exibição (remover regex)
          DISPLAY_PATTERN=$(echo "$pattern" | sed 's/\\[bB]//g; s/\\//g; s/^\.//')
          VIOLATION=$(jq -n \
            --arg rule_id "no_async_usage" \
            --arg severity "error" \
            --arg file "$file" \
            --argjson line "$LINE_NUM" \
            --arg message "Operação de I/O sem async/await detectada: $DISPLAY_PATTERN" \
            --arg suggestion "Marque o método como 'async Task' e use a variante assíncrona da operação." \
            '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
          VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
          break
        fi
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
