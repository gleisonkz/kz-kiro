#!/usr/bin/env bash
set -euo pipefail

# check-bff-boundaries.sh — BFF Fastify
# Detecta violações de fronteira no BFF: acesso direto a banco de dados,
# validações de domínio além de Zod, e lógica de negócio complexa.
#
# Entrada: lista de arquivos alterados via stdin (um por linha)
# Saída: JSON ReviewResult para stdout
# Requirement: 5.4

# Padrões de import de ORM/banco de dados (acesso direto a DB)
DB_PATTERNS=(
  "from ['\"]typeorm"
  "from ['\"]prisma"
  "from ['\"]@prisma/client"
  "from ['\"]knex"
  "from ['\"]sequelize"
  "from ['\"]mongoose"
  "from ['\"]pg['\"]"
  "from ['\"]mysql"
  "from ['\"]better-sqlite"
  "require\\(['\"]typeorm"
  "require\\(['\"]prisma"
  "require\\(['\"]knex"
  "require\\(['\"]sequelize"
  "require\\(['\"]mongoose"
)

# Padrões de lógica de negócio complexa
BUSINESS_LOGIC_PATTERNS=(
  "class-validator"
  "class-transformer"
  "from ['\"]joi['\"]"
  "from ['\"]yup['\"]"
)

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

# Filtrar arquivos .ts no src/ (excluindo testes, configs e types)
SOURCE_FILES=()
for file in "${CHANGED_FILES[@]}"; do
  if [[ "$file" =~ ^src/.+\.ts$ ]] && \
     [[ ! "$file" =~ \.(spec|test|d)\.ts$ ]] && \
     [[ ! "$file" =~ /config/ ]] && \
     [[ ! "$file" =~ /types/ ]]; then
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

# Verificar violações em cada arquivo
VIOLATIONS="[]"

add_violation() {
  local rule_id="$1"
  local severity="$2"
  local file="$3"
  local line="$4"
  local message="$5"
  local suggestion="$6"

  local VIOLATION
  if [[ -n "$line" ]]; then
    VIOLATION=$(cat <<EOF
{
  "rule_id": "$rule_id",
  "severity": "$severity",
  "file": "$file",
  "line": $line,
  "message": "$message",
  "suggestion": "$suggestion"
}
EOF
    )
  else
    VIOLATION=$(cat <<EOF
{
  "rule_id": "$rule_id",
  "severity": "$severity",
  "file": "$file",
  "message": "$message",
  "suggestion": "$suggestion"
}
EOF
    )
  fi

  if [[ "$VIOLATIONS" == "[]" ]]; then
    VIOLATIONS="[$VIOLATION]"
  else
    VIOLATIONS="${VIOLATIONS%]}, $VIOLATION]"
  fi
}

for src_file in "${SOURCE_FILES[@]}"; do
  # Verificar se o arquivo existe no filesystem
  if [[ ! -f "$src_file" ]]; then
    continue
  fi

  # Verificar imports de banco de dados
  for pattern in "${DB_PATTERNS[@]}"; do
    line_match=$(grep -nE "$pattern" "$src_file" 2>/dev/null | head -1 || true)
    if [[ -n "$line_match" ]]; then
      line_num=$(echo "$line_match" | cut -d: -f1)
      add_violation \
        "business_logic_in_bff" \
        "warn" \
        "$src_file" \
        "$line_num" \
        "Acesso direto a banco de dados detectado no BFF. O BFF deve delegar ao backend." \
        "Mova a lógica de acesso a dados para o serviço backend e use um client HTTP no BFF"
      break
    fi
  done

  # Verificar validações de domínio além de Zod
  for pattern in "${BUSINESS_LOGIC_PATTERNS[@]}"; do
    line_match=$(grep -nE "$pattern" "$src_file" 2>/dev/null | head -1 || true)
    if [[ -n "$line_match" ]]; then
      line_num=$(echo "$line_match" | cut -d: -f1)
      add_violation \
        "business_logic_in_bff" \
        "warn" \
        "$src_file" \
        "$line_num" \
        "Biblioteca de validação de domínio detectada. BFF deve usar apenas Zod para validação de contrato." \
        "Use Zod para validação de request/response e delegue validações de negócio ao backend"
      break
    fi
  done

  # Verificar lógica de negócio complexa (muitos if/else aninhados)
  # Conta blocos if/else em sequência — padrão heurístico
  if_count=$(grep -cE '\b(if|else if|else)\s*(\(|{)' "$src_file" 2>/dev/null || echo "0")
  if_count=$(echo "$if_count" | tr -d '[:space:]')
  if [[ "$if_count" -ge 5 ]]; then
    add_violation \
      "business_logic_in_bff" \
      "warn" \
      "$src_file" \
      "" \
      "Arquivo com lógica condicional complexa ($if_count blocos if/else). Possível lógica de negócio no BFF." \
      "Considere mover regras de negócio para o backend, mantendo no BFF apenas composição e orquestração"
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
