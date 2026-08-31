#!/usr/bin/env bash
set -euo pipefail

# check-breaking-changes.sh — Detecta breaking changes em contratos públicos (controllers, DTOs)
# sem documentação no CHANGELOG.
# Uso: ./check-breaking-changes.sh <arquivo-com-lista-de-arquivos-alterados> [diretorio-resultados]
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

# Verificar se CHANGELOG foi alterado no PR
CHANGELOG_MODIFIED=false
if echo "$CHANGED_FILES" | grep -qi "changelog"; then
  CHANGELOG_MODIFIED=true
fi

while IFS= read -r file; do
  # Ignorar linhas vazias
  [ -z "$file" ] && continue

  # Contratos públicos: controllers e DTOs
  if [[ "$file" != *.controller.ts && "$file" != *.dto.ts ]]; then
    continue
  fi

  # Ignorar testes
  if [[ "$file" == *.spec.ts || "$file" == *.e2e-spec.ts ]]; then
    continue
  fi

  # Se o CHANGELOG não foi modificado, verificar mudanças que indicam breaking change
  if [ "$CHANGELOG_MODIFIED" = false ]; then
    HAS_BREAKING=false

    if [ -f "$file" ]; then
      DIFF_OUTPUT=$(git diff HEAD~1 -- "$file" 2>/dev/null || git diff --cached -- "$file" 2>/dev/null || echo "")

      if [ -n "$DIFF_OUTPUT" ]; then
        # Remoção/alteração de rota, método público ou campo de DTO
        if echo "$DIFF_OUTPUT" | grep -qE '^\-[^-].*@(Get|Post|Put|Delete|Patch)\('; then
          HAS_BREAKING=true
        elif echo "$DIFF_OUTPUT" | grep -qE '^\-[^-].*(public |async )[a-zA-Z]+\('; then
          HAS_BREAKING=true
        elif echo "$DIFF_OUTPUT" | grep -qE '^\-[^-].*@ApiProperty'; then
          HAS_BREAKING=true
        fi
      else
        # Sem acesso ao diff, considerar alteração em contrato público como potencial breaking change
        HAS_BREAKING=true
      fi
    else
      # Arquivo removido — breaking change
      HAS_BREAKING=true
    fi

    if [ "$HAS_BREAKING" = true ]; then
      VIOLATION=$(jq -n \
        --arg rule_id "breaking_change_without_note" \
        --arg severity "error" \
        --arg file "$file" \
        --arg message "Breaking change em contrato público sem entrada no CHANGELOG: $file" \
        --arg suggestion "Adicione uma entrada no CHANGELOG.md documentando a alteração no contrato (endpoint/DTO)." \
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
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/breaking-changes.json"

echo "✓ check-breaking-changes.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
