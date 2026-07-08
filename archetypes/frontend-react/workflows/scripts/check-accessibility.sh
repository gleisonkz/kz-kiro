#!/usr/bin/env bash
set -euo pipefail

# check-accessibility.sh — Verifica violações de acessibilidade em arquivos .tsx.
# Busca padrões comuns de violação de acessibilidade (alt ausente, aria-label faltante, etc.)
# Uso: ./check-accessibility.sh [diretorio-resultados]

RESULTS_DIR="${1:-${RESULTS_DIR:-/tmp/review-results}}"
mkdir -p "$RESULTS_DIR"

VIOLATIONS="[]"

# Buscar arquivos .tsx (excluindo node_modules, testes, stories)
FILES=$(find . -name "*.tsx" \
  -not -path "*/node_modules/*" \
  -not -path "*/.next/*" \
  -not -path "*/dist/*" \
  -not -path "*.test.*" \
  -not -path "*.spec.*" \
  -not -path "*.stories.*" \
  2>/dev/null || true)

while IFS= read -r file; do
  [ -z "$file" ] && continue

  # Verificar <img> sem atributo alt
  while IFS=: read -r line_num line_content; do
    [ -z "$line_num" ] && continue
    # Verificar se a tag <img não tem alt= na mesma linha ou próximas
    if ! echo "$line_content" | grep -q 'alt='; then
      VIOLATION=$(jq -n \
        --arg rule_id "accessibility_issue" \
        --arg severity "warn" \
        --arg file "$file" \
        --argjson line "$line_num" \
        --arg message "Tag <img> sem atributo alt. Adicione alt descritivo ou alt=\"\" para imagens decorativas." \
        --arg suggestion "Adicione alt=\"descrição da imagem\" ou alt=\"\" se for decorativa." \
        '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
      VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
    fi
  done < <(grep -n '<img[[:space:]]' "$file" 2>/dev/null | grep -v 'alt=' || true)

  # Verificar <button> sem texto acessível (sem children text e sem aria-label)
  while IFS=: read -r line_num line_content; do
    [ -z "$line_num" ] && continue
    if ! echo "$line_content" | grep -q 'aria-label='; then
      # Verificar se é um botão com apenas ícone (sem texto visível)
      if echo "$line_content" | grep -qE '/>$|>\s*<'; then
        VIOLATION=$(jq -n \
          --arg rule_id "accessibility_issue" \
          --arg severity "warn" \
          --arg file "$file" \
          --argjson line "$line_num" \
          --arg message "Tag <button> sem texto acessível (aria-label ausente). Botões com apenas ícone precisam de aria-label." \
          --arg suggestion "Adicione aria-label=\"descrição da ação\" ao botão." \
          '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
        VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
      fi
    fi
  done < <(grep -n '<button[[:space:]]' "$file" 2>/dev/null || true)

  # Verificar <a> sem href (links inacessíveis)
  while IFS=: read -r line_num line_content; do
    [ -z "$line_num" ] && continue
    VIOLATION=$(jq -n \
      --arg rule_id "accessibility_issue" \
      --arg severity "warn" \
      --arg file "$file" \
      --argjson line "$line_num" \
      --arg message "Tag <a> sem atributo href. Links sem href não são navegáveis via teclado." \
      --arg suggestion "Adicione href ao link ou use <button> se for uma ação interativa." \
      '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
    VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
  done < <(grep -n '<a[[:space:]]' "$file" 2>/dev/null | grep -v 'href=' || true)

  # Verificar elementos interativos com onClick sem role ou tabIndex
  while IFS=: read -r line_num line_content; do
    [ -z "$line_num" ] && continue
    # Ignorar se já é um elemento interativo nativo (button, a, input, select, textarea)
    if echo "$line_content" | grep -qE '<(button|a|input|select|textarea|Button|Link)'; then
      continue
    fi
    if ! echo "$line_content" | grep -qE 'role=|tabIndex='; then
      VIOLATION=$(jq -n \
        --arg rule_id "accessibility_issue" \
        --arg severity "warn" \
        --arg file "$file" \
        --argjson line "$line_num" \
        --arg message "Elemento não-interativo com onClick sem role ou tabIndex. Não é acessível via teclado." \
        --arg suggestion "Adicione role=\"button\" e tabIndex={0}, ou use um <button> nativo." \
        '{rule_id: $rule_id, severity: $severity, file: $file, line: $line, message: $message, suggestion: $suggestion}')
      VIOLATIONS=$(echo "$VIOLATIONS" | jq --argjson v "$VIOLATION" '. + [$v]')
    fi
  done < <(grep -n 'onClick=' "$file" 2>/dev/null || true)

done <<< "$FILES"

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
  '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/accessibility.json"

echo "✓ check-accessibility.sh concluído: $VIOLATION_COUNT violação(ões) encontrada(s)."
