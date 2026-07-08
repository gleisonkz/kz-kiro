#!/usr/bin/env bash
set -euo pipefail

# check-route-schemas.sh — BFF Fastify
# Verifica se cada arquivo de rota em src/modules/**/routes/ possui
# um schema Zod correspondente em src/modules/**/schemas/.
#
# Entrada: lista de arquivos alterados via stdin (um por linha)
# Saída: JSON ReviewResult para stdout
# Requirement: 5.3

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

# Filtrar arquivos de rota (excluindo testes e index)
ROUTE_FILES=()
for file in "${CHANGED_FILES[@]}"; do
  if [[ "$file" =~ ^src/modules/.+/routes/.+\.ts$ ]] && \
     [[ ! "$file" =~ \.(spec|test)\.ts$ ]] && \
     [[ ! "$file" =~ /index\.ts$ ]]; then
    ROUTE_FILES+=("$file")
  fi
done

# Se não há arquivos de rota relevantes, retornar resultado vazio
if [[ ${#ROUTE_FILES[@]} -eq 0 ]]; then
  cat <<EOF
{
  "step": "archetype_rules",
  "status": "pass",
  "violations": []
}
EOF
  exit 0
fi

# Verificar se cada rota possui schema correspondente
VIOLATIONS="[]"
for route_file in "${ROUTE_FILES[@]}"; do
  # Extrair módulo e nome da rota
  # Exemplo: src/modules/users/routes/get-users.ts → src/modules/users/schemas/get-users.schema.ts
  module_path=$(echo "$route_file" | sed -E 's|/routes/[^/]+$||')
  route_basename=$(basename "$route_file" .ts)
  schema_file="${module_path}/schemas/${route_basename}.schema.ts"

  # Verificar se o schema existe na lista de arquivos alterados ou no filesystem
  has_schema=false
  for changed in "${CHANGED_FILES[@]}"; do
    if [[ "$changed" == "$schema_file" ]]; then
      has_schema=true
      break
    fi
  done

  if [[ "$has_schema" == "false" ]] && [[ -f "$schema_file" ]]; then
    has_schema=true
  fi

  if [[ "$has_schema" == "false" ]]; then
    VIOLATION=$(cat <<EOF
{
  "rule_id": "missing_route_schema",
  "severity": "warn",
  "file": "$route_file",
  "message": "Rota sem schema Zod correspondente em schemas/${route_basename}.schema.ts",
  "suggestion": "Crie ${schema_file} com validação de request (body, querystring ou params) e response"
}
EOF
    )

    if [[ "$VIOLATIONS" == "[]" ]]; then
      VIOLATIONS="[$VIOLATION]"
    else
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
