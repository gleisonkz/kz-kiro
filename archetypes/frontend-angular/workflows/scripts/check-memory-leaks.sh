#!/usr/bin/env bash
set -euo pipefail

# check-memory-leaks.sh — Detecta subscriptions sem gerenciamento de ciclo de vida
# em componentes Angular (risco de memory leak).
# Uso: ./check-memory-leaks.sh <arquivo-com-lista-de-arquivos-alterados> [diretorio-resultados]
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

while IFS= read -r file; do
  # Ignorar linhas vazias
  [ -z "$file" ] && continue

  # Verificar apenas componentes/diretivas TypeScript
  if [[ "$file" != *.component.ts && "$file" != *.directive.ts && "$file" != *.page.ts && "$file" != *.view.ts ]]; then
    continue
  fi

  # Ignorar testes
  if [[ "$file" == *.spec.ts ]]; then
    continue
  fi

  # Verificar se o arquivo existe
  if [ ! -f "$file" ]; then
    continue
  fi

  # O arquivo usa .subscribe(...)?
  if ! grep -qE '\.subscribe\(' "$file"; then
    continue
  fi

  # Heurística de gerenciamento de ciclo de vida: takeUntil, destroy$, async pipe,
  # take(1)/first(), ou coleta manual em Subscription.
  HAS_LIFECYCLE=false
  if grep -qE 'takeUntil|destroy\$|takeUntilDestroyed|\.add\(|take\(1\)|first\(\)' "$file"; then
    HAS_LIFECYCLE=true
  fi

  if [ "$HAS_LIFECYCLE" = false ]; then
    # Localizar a primeira linha com subscribe para reportar
    LINE_NUM=$(grep -nE '\.subscribe\(' "$file" | head -1 | cut -d: -f1)
    VIOLATION=$(jq -n \
      --arg rule_id "memory_leak_risk" \
      --arg severity "error" \
      --arg file "$file" \
      --argjson line "${LINE_NUM:-0}" \
      --arg message "Subscription sem gerenciamento de ciclo de vida (takeUntil/destroy\$/async pipe)." \
      --arg suggestion "Use o padrão destroy\$ com takeUntil, ou prefira o async pipe no template." \
      '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
    VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
  fi
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
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/memory-leaks.json"

echo "✓ check-memory-leaks.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
