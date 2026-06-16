#!/usr/bin/env bats
# =============================================================================
# Property 6: Sync torna destino idêntico ao fonte
# Feature: baseline-global, Property 6: Sync torna destino idêntico ao fonte
# =============================================================================
# Para qualquer conjunto de steering files no baseline e qualquer estado inicial
# do diretório destino, após a execução do sync (sem dry-run), cada steering file
# no destino SHALL ser byte-a-byte idêntico à versão correspondente no baseline,
# e todos os steering files do baseline SHALL existir no destino.
#
# **Validates: Requirements 5.1, 5.2, 5.3**
# =============================================================================

# Carrega helpers
load '../helpers/generators'
load '../helpers/setup'
load '../helpers/assertions'

# Caminho do script sob teste
SYNC_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/sync.sh"

# Diretório fonte do baseline (repositório)
BASELINE_STEERING="${BATS_TEST_DIRNAME}/../../baselines/global/steering"

# --- Geradores de estado inicial do destino ---

# Gera um estado aleatório para os steering files no diretório destino.
# Cada arquivo do baseline pode estar: ausente, desatualizado, ou idêntico.
_gen_destination_state() {
  local project_dir="$1"
  local steering_dest="${project_dir}/.kiro/steering"

  mkdir -p "${steering_dest}"

  # Para cada steering file no baseline, escolher estado aleatório
  for src_file in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${src_file}" ]] && continue
    local filename
    filename=$(basename "${src_file}")
    [[ "${filename}" == "README.md" ]] && continue

    local state
    state=$(_rand_int 0 2)

    case "$state" in
      0) # Ausente — não copia nada
        ;;
      1) # Desatualizado — cria versão diferente com conteúdo aleatório
        gen_steering_file > "${steering_dest}/${filename}"
        ;;
      2) # Idêntico — copia o original
        cp "${src_file}" "${steering_dest}/${filename}"
        ;;
    esac
  done

  # Opcionalmente adicionar arquivos extras que não existem no baseline
  if (( RANDOM % 3 == 0 )); then
    local extra_name="extra-$(_rand_lower 5).md"
    gen_steering_file > "${steering_dest}/${extra_name}"
  fi
}

# --- Teste de propriedade ---

@test "Property 6: Sync torna destino idêntico ao fonte (100 iterações)" {
  # Feature: baseline-global, Property 6: Sync torna destino idêntico ao fonte
  # **Validates: Requirements 5.1, 5.2, 5.3**

  local iterations=100
  local i=0

  # Listar steering files do baseline (excluindo README.md)
  local baseline_files=()
  for f in "${BASELINE_STEERING}"/*.md; do
    [[ ! -f "${f}" ]] && continue
    local fname
    fname=$(basename "${f}")
    [[ "${fname}" == "README.md" ]] && continue
    baseline_files+=("${fname}")
  done

  # Verificar que há pelo menos um steering file no baseline para testar
  if [[ ${#baseline_files[@]} -eq 0 ]]; then
    skip "Nenhum steering file encontrado no baseline"
  fi

  while (( i < iterations )); do
    # Criar projeto temporário
    local target_dir
    target_dir=$(create_temp_project)

    # Configurar manifest válido (necessário para sync funcionar)
    setup_manifest "${target_dir}"
    cp "${target_dir}/.kiro/kiro-manifest.json" "${target_dir}/kiro-manifest.json"

    # Gerar estado inicial aleatório do destino
    _gen_destination_state "${target_dir}"

    # Executar sync com --component baseline (sem dry-run)
    bash "${SYNC_SCRIPT}" \
      --target "${target_dir}" \
      --component baseline >/dev/null 2>&1 || {
      echo "FALHA na iteração $((i+1)): sync.sh encerrou com erro"
      echo "  target: ${target_dir}"
      cleanup_fixtures
      return 1
    }

    # Verificar: cada steering file do baseline deve existir no destino
    # e ser byte-a-byte idêntico
    local steering_dest="${target_dir}/.kiro/steering"

    for fname in "${baseline_files[@]}"; do
      local src_file="${BASELINE_STEERING}/${fname}"
      local dest_file="${steering_dest}/${fname}"

      # Verificar existência (Requisito 5.3: novos devem ser copiados)
      if [[ ! -f "${dest_file}" ]]; then
        echo "FALHA na iteração $((i+1)): arquivo ausente no destino após sync"
        echo "  arquivo: ${fname}"
        echo "  destino esperado: ${dest_file}"
        echo "  target: ${target_dir}"
        cleanup_fixtures
        return 1
      fi

      # Verificar identidade byte-a-byte (Requisitos 5.1, 5.2)
      if ! cmp -s "${src_file}" "${dest_file}"; then
        local diff_output
        diff_output="$(diff --unified=3 "${src_file}" "${dest_file}" 2>/dev/null || true)"
        echo "FALHA na iteração $((i+1)): arquivo no destino não é idêntico ao fonte"
        echo "  arquivo: ${fname}"
        echo "  fonte: ${src_file}"
        echo "  destino: ${dest_file}"
        echo "  target: ${target_dir}"
        echo "  diff:"
        echo "${diff_output}"
        cleanup_fixtures
        return 1
      fi
    done

    ((i++))
  done

  # Cleanup
  cleanup_fixtures
}
