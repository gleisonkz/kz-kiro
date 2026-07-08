#!/usr/bin/env bash
set -euo pipefail

# check-missing-tests.sh — Verifica se componentes (.tsx), hooks (use*.ts) e utils (.ts) possuem testes.
# Uso: ./check-missing-tests.sh [diretorio-resultados]
# Busca arquivos no repositório local que não possuem teste correspondente.

RESULTS_DIR="${1:-${RESULTS_DIR:-/tmp/review-results}}"
mkdir -p "$RESULTS_DIR"

VIOLATIONS="[]"

# Buscar componentes em components/ sem teste correspondente
while IFS= read -r file; do
  [ -z "$file" ] && continue

  # Ignorar arquivos de teste, stories, estilos e index
  if [[ "$file" == *.test.* || "$file" == *.spec.* || "$file" == *.stories.* || "$file" == *.styles.* || "$file" == */index.ts || "$file" == */index.tsx ]]; then
    continue
  fi

  BASENAME=$(basename "$file")
  NAME="${BASENAME%.*}"
  DIR=$(dirname "$file")

  # Buscar teste correspondente
  TEST_FOUND=false
  TEST_PATTERNS=(
    "${DIR}/${NAME}.test.tsx"
    "${DIR}/${NAME}.test.ts"
    "${DIR}/${NAME}.spec.tsx"
    "${DIR}/${NAME}.spec.ts"
    "${DIR}/__tests__/${NAME}.test.tsx"
    "${DIR}/__tests__/${NAME}.test.ts"
    "${DIR}/__tests__/${NAME}.spec.tsx"
    "${DIR}/__tests__/${NAME}.spec.ts"
  )

  for pattern in "${TEST_PATTERNS[@]}"; do
    if [ -f "$pattern" ]; then
      TEST_FOUND=true
      break
    fi
  done

  if [ "$TEST_FOUND" = false ]; then
    VIOLATION=$(jq -n \
      --arg rule_id "missing_tests" \
      --arg severity "error" \
      --arg file "$file" \
      --arg message "Componente sem teste correspondente: $file" \
      --arg suggestion "Crie um arquivo ${NAME}.test.tsx com testes para este componente." \
      '{rule_id: $rule_id, severity: $severity, file: $file, message: $message, suggestion: $suggestion}')
    VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
  fi
done < <(find . -path "*/components/*.tsx" -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*" 2>/dev/null || true)

# Buscar hooks (arquivos começando com "use" ou em diretório hooks/) sem teste
while IFS= read -r file; do
  [ -z "$file" ] && continue

  if [[ "$file" == *.test.* || "$file" == *.spec.* ]]; then
    continue
  fi

  BASENAME=$(basename "$file")
  NAME="${BASENAME%.*}"
  DIR=$(dirname "$file")

  TEST_FOUND=false
  TEST_PATTERNS=(
    "${DIR}/${NAME}.test.ts"
    "${DIR}/${NAME}.test.tsx"
    "${DIR}/${NAME}.spec.ts"
    "${DIR}/${NAME}.spec.tsx"
    "${DIR}/__tests__/${NAME}.test.ts"
    "${DIR}/__tests__/${NAME}.test.tsx"
    "${DIR}/__tests__/${NAME}.spec.ts"
    "${DIR}/__tests__/${NAME}.spec.tsx"
  )

  for pattern in "${TEST_PATTERNS[@]}"; do
    if [ -f "$pattern" ]; then
      TEST_FOUND=true
      break
    fi
  done

  if [ "$TEST_FOUND" = false ]; then
    VIOLATION=$(jq -n \
      --arg rule_id "missing_tests" \
      --arg severity "error" \
      --arg file "$file" \
      --arg message "Hook sem teste correspondente: $file" \
      --arg suggestion "Crie um arquivo ${NAME}.test.ts com testes para este hook." \
      '{rule_id: $rule_id, severity: $severity, file: $file, message: $message, suggestion: $suggestion}')
    VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
  fi
done < <(find . -path "*/hooks/*.ts" -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*" 2>/dev/null; find . -name "use*.ts" -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*" -not -path "*/hooks/*" 2>/dev/null || true)

# Buscar utils (.ts em utils/) sem teste
while IFS= read -r file; do
  [ -z "$file" ] && continue

  if [[ "$file" == *.test.* || "$file" == *.spec.* || "$file" == */index.ts ]]; then
    continue
  fi

  BASENAME=$(basename "$file")
  NAME="${BASENAME%.*}"
  DIR=$(dirname "$file")

  TEST_FOUND=false
  TEST_PATTERNS=(
    "${DIR}/${NAME}.test.ts"
    "${DIR}/${NAME}.spec.ts"
    "${DIR}/__tests__/${NAME}.test.ts"
    "${DIR}/__tests__/${NAME}.spec.ts"
  )

  for pattern in "${TEST_PATTERNS[@]}"; do
    if [ -f "$pattern" ]; then
      TEST_FOUND=true
      break
    fi
  done

  if [ "$TEST_FOUND" = false ]; then
    VIOLATION=$(jq -n \
      --arg rule_id "missing_tests" \
      --arg severity "error" \
      --arg file "$file" \
      --arg message "Função utilitária sem teste correspondente: $file" \
      --arg suggestion "Crie um arquivo ${NAME}.test.ts com testes para esta utilidade." \
      '{rule_id: $rule_id, severity: $severity, file: $file, message: $message, suggestion: $suggestion}')
    VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
  fi
done < <(find . -path "*/utils/*.ts" -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*" 2>/dev/null || true)

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
