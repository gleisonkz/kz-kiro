#!/usr/bin/env bash
set -euo pipefail

# check-coverage.sh — Verifica se a cobertura de código está acima de 80%.
# Uso: ./check-coverage.sh [diretorio-resultados]
# Executa `dotnet test` com coleta de cobertura e verifica o threshold.

RESULTS_DIR="${1:-${RESULTS_DIR:-/tmp/review-results}}"
mkdir -p "$RESULTS_DIR"

COVERAGE_THRESHOLD=80

# Executar testes com coleta de cobertura
echo "Executando testes com coleta de cobertura..."
COVERAGE_OUTPUT_DIR="/tmp/coverage-results"
rm -rf "$COVERAGE_OUTPUT_DIR"
mkdir -p "$COVERAGE_OUTPUT_DIR"

TEST_EXIT=0
dotnet test \
  --collect:"XPlat Code Coverage" \
  --results-directory "$COVERAGE_OUTPUT_DIR" \
  --no-build \
  2>&1 | tee /tmp/test-output.txt || TEST_EXIT=$?

# Se os testes falharem por erro de build/execução (não por cobertura)
if [ $TEST_EXIT -ne 0 ]; then
  # Verificar se é falha de teste ou erro de infraestrutura
  if grep -q "No test is available" /tmp/test-output.txt; then
    echo "⚠️ Nenhum teste encontrado para executar."
    jq -n \
      --arg step "archetype_rules" \
      --arg status "pass" \
      '{step: $step, status: $status, violations: []}' > "$RESULTS_DIR/coverage.json"
    echo "✓ check-coverage.sh concluído: sem testes para avaliar cobertura."
    exit 0
  fi
fi

# Buscar arquivo de cobertura (formato Cobertura XML)
COVERAGE_FILE=$(find "$COVERAGE_OUTPUT_DIR" -name "coverage.cobertura.xml" -type f 2>/dev/null | head -1)

if [ -z "$COVERAGE_FILE" ]; then
  echo "⚠️ Arquivo de cobertura não encontrado. Verifique se o projeto tem testes configurados."
  jq -n \
    --arg step "archetype_rules" \
    --arg status "error" \
    --argjson violations '[{"rule_id": "coverage_below_threshold", "severity": "error", "message": "Não foi possível coletar dados de cobertura. Verifique a configuração de testes.", "suggestion": "Certifique-se de que o projeto possui testes unitários e o pacote coverlet.collector está instalado."}]' \
    '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/coverage.json"
  echo "✓ check-coverage.sh concluído: erro ao coletar cobertura."
  exit 0
fi

echo "Arquivo de cobertura encontrado: $COVERAGE_FILE"

# Extrair porcentagem de cobertura de linha do XML Cobertura
# O atributo line-rate está no elemento <coverage> raiz e é um valor entre 0 e 1
LINE_RATE=$(grep -oP 'line-rate="\K[^"]+' "$COVERAGE_FILE" | head -1 || echo "0")

if [ -z "$LINE_RATE" ] || [ "$LINE_RATE" = "0" ]; then
  # Fallback: tentar com xmllint se disponível
  if command -v xmllint &> /dev/null; then
    LINE_RATE=$(xmllint --xpath "string(/coverage/@line-rate)" "$COVERAGE_FILE" 2>/dev/null || echo "0")
  fi
fi

# Converter rate (0-1) para porcentagem
if command -v bc &> /dev/null; then
  COVERAGE_PERCENT=$(echo "$LINE_RATE * 100" | bc -l | xargs printf "%.1f")
else
  # Fallback sem bc: multiplicar por 100 usando awk
  COVERAGE_PERCENT=$(echo "$LINE_RATE" | awk '{printf "%.1f", $1 * 100}')
fi

echo "Cobertura de linha: ${COVERAGE_PERCENT}% (threshold: ${COVERAGE_THRESHOLD}%)"

# Comparar com threshold
BELOW_THRESHOLD=false
if command -v bc &> /dev/null; then
  if [ "$(echo "$COVERAGE_PERCENT < $COVERAGE_THRESHOLD" | bc -l)" -eq 1 ]; then
    BELOW_THRESHOLD=true
  fi
else
  if [ "$(echo "$COVERAGE_PERCENT $COVERAGE_THRESHOLD" | awk '{print ($1 < $2)}')" -eq 1 ]; then
    BELOW_THRESHOLD=true
  fi
fi

if [ "$BELOW_THRESHOLD" = true ]; then
  jq -n \
    --arg step "archetype_rules" \
    --arg status "fail" \
    --arg coverage "$COVERAGE_PERCENT" \
    --arg threshold "$COVERAGE_THRESHOLD" \
    --argjson violations "[{\"rule_id\": \"coverage_below_threshold\", \"severity\": \"error\", \"message\": \"Cobertura de código em ${COVERAGE_PERCENT}%, abaixo do threshold de ${COVERAGE_THRESHOLD}%.\", \"suggestion\": \"Adicione testes unitários para aumentar a cobertura acima de ${COVERAGE_THRESHOLD}%.\"}]" \
    '{step: $step, status: $status, violations: $violations}' > "$RESULTS_DIR/coverage.json"
else
  jq -n \
    --arg step "archetype_rules" \
    --arg status "pass" \
    '{step: $step, status: $status, violations: []}' > "$RESULTS_DIR/coverage.json"
fi

echo "✓ check-coverage.sh concluído: cobertura ${COVERAGE_PERCENT}% (threshold: ${COVERAGE_THRESHOLD}%)."
