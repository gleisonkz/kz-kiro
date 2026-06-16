#!/usr/bin/env bash
# Script para executar todas as suítes de teste do projeto.
# Uso: ./tests/run_tests.sh [suite]
#   suite: unit | integration | properties | all (padrão: all)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS="${SCRIPT_DIR}/lib/bats-core/bin/bats"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem cor

# Verifica se bats-core está disponível
if [[ ! -x "${BATS}" ]]; then
  echo -e "${RED}Erro: bats-core não encontrado em ${BATS}${NC}"
  echo "Execute: git submodule update --init --recursive"
  exit 1
fi

suite="${1:-all}"
exit_code=0

run_suite() {
  local name="$1"
  local dir="${SCRIPT_DIR}/${name}"

  if [[ ! -d "${dir}" ]]; then
    echo -e "${YELLOW}Aviso: diretório ${dir} não encontrado, pulando.${NC}"
    return 0
  fi

  # Verifica se existem arquivos .bats na suíte
  local bats_files
  bats_files=$(find "${dir}" -name "*.bats" -type f 2>/dev/null)
  if [[ -z "${bats_files}" ]]; then
    echo -e "${YELLOW}Aviso: nenhum teste encontrado em ${dir}, pulando.${NC}"
    return 0
  fi

  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
  echo -e "${GREEN}  Executando suíte: ${name}${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
  echo ""

  if "${BATS}" "${dir}" --recursive; then
    echo -e "${GREEN}✓ Suíte ${name} passou.${NC}"
  else
    echo -e "${RED}✗ Suíte ${name} falhou.${NC}"
    exit_code=1
  fi
  echo ""
}

case "${suite}" in
  unit)
    run_suite "unit"
    ;;
  integration)
    run_suite "integration"
    ;;
  properties)
    run_suite "properties"
    ;;
  all)
    run_suite "unit"
    run_suite "integration"
    run_suite "properties"
    ;;
  *)
    echo -e "${RED}Erro: suíte inválida '${suite}'${NC}"
    echo "Uso: $0 [unit|integration|properties|all]"
    exit 1
    ;;
esac

if [[ ${exit_code} -eq 0 ]]; then
  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
  echo -e "${GREEN}  Todos os testes passaram!${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
else
  echo -e "${RED}═══════════════════════════════════════════${NC}"
  echo -e "${RED}  Alguns testes falharam.${NC}"
  echo -e "${RED}═══════════════════════════════════════════${NC}"
fi

exit ${exit_code}
