#!/usr/bin/env bash
set -euo pipefail

# check-missing-tests.sh — Verifica se arquivos em Application/ ou Domain/ possuem testes correspondentes.
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

  # Verificar apenas arquivos .cs em Application/ ou Domain/
  if [[ "$file" == *.cs ]] && [[ "$file" == *Application/* || "$file" == *Domain/* ]]; then
    # Ignorar arquivos que já são testes
    if [[ "$file" == *Tests.cs || "$file" == *Test.cs || "$file" == *.Tests/* || "$file" == *.Test/* || "$file" == *Tests/* || "$file" == *Test/* ]]; then
      continue
    fi

    # Ignorar interfaces (IFoo.cs) e abstrações puras
    BASENAME=$(basename "$file" .cs)

    # Gerar possíveis nomes de arquivo de teste
    TEST_FOUND=false
    TEST_PATTERNS=(
      "${BASENAME}Tests.cs"
      "${BASENAME}Test.cs"
      "${BASENAME}_Tests.cs"
      "${BASENAME}_Test.cs"
    )

    for pattern in "${TEST_PATTERNS[@]}"; do
      # Buscar na lista de arquivos alterados
      if echo "$CHANGED_FILES" | grep -q "$pattern"; then
        TEST_FOUND=true
        break
      fi
    done

    # Também buscar no filesystem do repositório
    if [ "$TEST_FOUND" = false ]; then
      SEARCH_RESULTS=$(find . -name "${BASENAME}Tests.cs" -o -name "${BASENAME}Test.cs" 2>/dev/null || true)
      if [ -n "$SEARCH_RESULTS" ]; then
        TEST_FOUND=true
      fi
    fi

    if [ "$TEST_FOUND" = false ]; then
      VIOLATION=$(jq -n \
        --arg rule_id "missing_tests" \
        --arg severity "error" \
        --arg file "$file" \
        --arg message "Arquivo em camada Application/Domain sem teste correspondente: $file" \
        --arg suggestion "Crie um arquivo ${BASENAME}Tests.cs com testes unitários para este código." \
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
