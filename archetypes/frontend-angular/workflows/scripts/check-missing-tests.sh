#!/usr/bin/env bash
set -euo pipefail

# check-missing-tests.sh — Verifica se components/services/stores alterados possuem testes (*.spec.ts).
# Uso: ./check-missing-tests.sh <arquivo-com-lista-de-arquivos-alterados> [diretorio-resultados]
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

  # Verificar components, services e stores
  if [[ "$file" == *.component.ts || "$file" == *.service.ts || "$file" == *.store.ts ]]; then
    # Ignorar arquivos que já são testes
    if [[ "$file" == *.spec.ts ]]; then
      continue
    fi

    # Derivar caminho do teste co-locado: foo.component.ts -> foo.component.spec.ts
    BASE="${file%.ts}"
    SPEC_FILE="${BASE}.spec.ts"

    TEST_FOUND=false

    # Buscar na lista de arquivos alterados
    if echo "$CHANGED_FILES" | grep -qF "$SPEC_FILE"; then
      TEST_FOUND=true
    fi

    # Buscar no filesystem do repositório
    if [ "$TEST_FOUND" = false ]; then
      if [ -f "$SPEC_FILE" ]; then
        TEST_FOUND=true
      fi
    fi

    if [ "$TEST_FOUND" = false ]; then
      SPEC_BASENAME=$(basename "$SPEC_FILE")
      VIOLATION=$(jq -n \
        --arg rule_id "missing_tests" \
        --arg severity "error" \
        --arg file "$file" \
        --arg message "Component/service/store sem teste correspondente: $file" \
        --arg suggestion "Crie um arquivo $SPEC_BASENAME co-locado com testes (TestBed.configureTestingModule)." \
        '{rule_id: $rule_id, severity: $severity, file: $file, message: $message, suggestion: $suggestion}')
      VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
    fi
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
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/missing-tests.json"

echo "✓ check-missing-tests.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
