#!/usr/bin/env bash
set -euo pipefail

# check-missing-tests.sh — BFF Fastify
# Detecta arquivos .ts em src/modules/**/routes/ ou src/modules/**/services/
# sem teste correspondente (.spec.ts ou .test.ts) no mesmo PR.
#
# Entrada: lista de arquivos alterados via stdin (um por linha)
# Saída: JSON ReviewResult para stdout
# Requirement: 5.1

# Ler arquivos alterados da stdin
CHANGED_FILES=()
while IFS= read -r file; do
  [[ -n "$file" ]] && CHANGED_FILES+=("$file")
done

# Se não há arquivos, retornar resultado vazio
if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
  cat <<EOF
{
  "step": "archetype_rules",
  "status": "pass",
  "violations": []
}
EOF
  exit 0
fi

# Filtrar arquivos de código em routes/ ou services/ (excluindo testes)
SOURCE_FILES=()
for file in "${CHANGED_FILES[@]}"; do
  # Verificar se é .ts em routes/ ou services/ dentro de src/modules/
  if [[ "$file" =~ ^src/modules/.+/(routes|services)/.+\.ts$ ]] && \
     [[ ! "$file" =~ \.(spec|test)\.ts$ ]]; then
    SOURCE_FILES+=("$file")
  fi
done

# Se não há arquivos fonte relevantes, retornar resultado vazio
if [[ ${#SOURCE_FILES[@]} -eq 0 ]]; then
  cat <<EOF
{
  "step": "archetype_rules",
  "status": "pass",
  "violations": []
}
EOF
  exit 0
fi

# Verificar quais arquivos de código não possuem teste correspondente
VIOLATIONS="[]"
for src_file in "${SOURCE_FILES[@]}"; do
  # Gerar possíveis nomes de teste
  base_name="${src_file%.ts}"
  spec_file="${base_name}.spec.ts"
  test_file="${base_name}.test.ts"

  # Verificar se algum teste correspondente existe na lista de arquivos alterados
  has_test=false
  for changed in "${CHANGED_FILES[@]}"; do
    if [[ "$changed" == "$spec_file" ]] || [[ "$changed" == "$test_file" ]]; then
      has_test=true
      break
    fi
  done

  # Verificar também se o arquivo de teste já existe no filesystem
  if [[ "$has_test" == "false" ]]; then
    if [[ -f "$spec_file" ]] || [[ -f "$test_file" ]]; then
      has_test=true
    fi
  fi

  if [[ "$has_test" == "false" ]]; then
    VIOLATION=$(cat <<EOF
{
  "rule_id": "missing_tests",
  "severity": "error",
  "file": "$src_file",
  "message": "Arquivo em routes/services sem teste correspondente (.spec.ts ou .test.ts)",
  "suggestion": "Crie um arquivo ${base_name}.spec.ts com testes para este módulo"
}
EOF
    )

    if [[ "$VIOLATIONS" == "[]" ]]; then
      VIOLATIONS="[$VIOLATION]"
    else
      # Remover ] final e adicionar nova violação
      VIOLATIONS="${VIOLATIONS%]}, $VIOLATION]"
    fi
  fi
done

# Determinar status
if [[ "$VIOLATIONS" == "[]" ]]; then
  STATUS="pass"
else
  STATUS="fail"
fi

# Gerar saída JSON
cat <<EOF
{
  "step": "archetype_rules",
  "status": "$STATUS",
  "violations": $VIOLATIONS
}
EOF
