#!/usr/bin/env bats
# =============================================================================
# Property 6: Consistência de versão nos READMEs
# Feature: archetype-mobile-flutter, Property 6: Consistência de versão nos READMEs
# =============================================================================
# Para qualquer arquivo README.md dentro do archetype mobile-flutter
# (raiz, steering/, hooks/, agents/, skills/), o conteúdo SHALL referenciar
# a mesma versão, garantindo consistência interna entre todos os documentos.
#
# **Validates: Requirements 13.3, 13.4**
# 100 iterações por property test.

setup() {
  load '../helpers/setup'
  load '../helpers/generators'
  load '../helpers/assertions'
  load '../lib/bats-assert/load'
  load '../lib/bats-support/load'
}

teardown() {
  cleanup_fixtures
}

# --- Constantes ---
ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"
README_LOCATIONS=("" "steering" "hooks" "agents" "skills")

# --- Função de validação de consistência de versão ---
# Extrai todas as referências de versão (padrão "Versão: X.Y.Z") dos READMEs
# e verifica que todas são idênticas.
# Retorna 0 se todas consistentes, 1 se qualquer divergência.
validate_version_consistency() {
  local archetype_dir="$1"
  local versions_found=()
  local loc readme_path

  for loc in "${README_LOCATIONS[@]}"; do
    if [[ -z "$loc" ]]; then
      readme_path="${archetype_dir}/README.md"
    else
      readme_path="${archetype_dir}/${loc}/README.md"
    fi

    # Se o README não existe, falha
    if [[ ! -f "$readme_path" ]]; then
      return 1
    fi

    # Extrair versões referenciadas (padrões: "Versão: X.Y.Z", "v0.1.0", ou standalone "0.1.0")
    # O padrão principal nos READMEs do archetype é "Versão: X.Y.Z"
    local file_versions
    file_versions=$(grep -oE 'Versão: [0-9]+\.[0-9]+\.[0-9]+' "$readme_path" 2>/dev/null | sed 's/Versão: //' | sort -u)

    if [[ -z "$file_versions" ]]; then
      # Nenhuma referência de versão encontrada — inconsistente
      return 1
    fi

    # Coletar todas as versões únicas deste arquivo
    while IFS= read -r v; do
      versions_found+=("$v")
    done <<< "$file_versions"
  done

  # Verificar que todas as versões encontradas são idênticas
  if [[ ${#versions_found[@]} -eq 0 ]]; then
    return 1
  fi

  local first_version="${versions_found[0]}"
  local v
  for v in "${versions_found[@]}"; do
    if [[ "$v" != "$first_version" ]]; then
      return 1
    fi
  done

  return 0
}

# --- Gerador: cria estrutura de archetype com versão CONSISTENTE em todos os READMEs ---
gen_valid_version_dir() {
  local archetype_dir
  archetype_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-version-XXXXXX")"
  echo "${archetype_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # Gerar uma versão aleatória consistente
  local version
  version="$(gen_semver)"

  # README raiz
  cat > "${archetype_dir}/README.md" <<EOF
# Archetype: Mobile Flutter

> **Archetype | mobile-flutter | Versão: ${version}**
>
> Configurações Kiro para projetos Flutter mobile.

---

## Estrutura

Archetype de teste.

---

*Versão: ${version} | Última revisão: 2026-04*
EOF

  # steering/README.md
  mkdir -p "${archetype_dir}/steering"
  cat > "${archetype_dir}/steering/README.md" <<EOF
# Steering — Archetype Mobile Flutter

> **Steering File | Archetype: mobile-flutter | Versão: ${version}**
>
> Steering files para projetos Flutter mobile.

---

## Conteúdo

Steering files de teste.

---

*Versão: ${version} | Última revisão: 2026-04*
EOF

  # hooks/README.md
  mkdir -p "${archetype_dir}/hooks"
  cat > "${archetype_dir}/hooks/README.md" <<EOF
# Hooks — Archetype Mobile Flutter

> **Hooks | Archetype: mobile-flutter | Versão: ${version}**
>
> Hooks do Kiro para projetos Flutter mobile.

---

## Conteúdo

Hooks de teste.

---

*Versão: ${version} | Última revisão: 2026-04*
EOF

  # agents/README.md
  mkdir -p "${archetype_dir}/agents"
  cat > "${archetype_dir}/agents/README.md" <<EOF
# Agents — Archetype Mobile Flutter

> **Agents | Archetype: mobile-flutter | Versão: ${version}**
>
> Agentes customizados para projetos Flutter mobile.

---

## Status

Nenhum agente definido.

---

*Versão: ${version} | Última revisão: 2026-04*
EOF

  # skills/README.md
  mkdir -p "${archetype_dir}/skills"
  cat > "${archetype_dir}/skills/README.md" <<EOF
# Skills — Archetype Mobile Flutter

> **Skills | Archetype: mobile-flutter | Versão: ${version}**
>
> Skills do Kiro para projetos Flutter mobile.

---

## Status

Nenhuma skill definida.

---

*Versão: ${version} | Última revisão: 2026-04*
EOF

  echo "${archetype_dir}"
}

# --- Gerador: cria estrutura com ao menos 1 README referenciando versão DIFERENTE ---
gen_invalid_version_dir() {
  local archetype_dir
  archetype_dir="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/test-version-inv-XXXXXX")"
  echo "${archetype_dir}" >> "${_TEST_TEMP_DIRS_FILE}"

  # Versão base
  local base_version
  base_version="$(gen_semver)"

  # Versão diferente (garantir que é diferente)
  local alt_version
  alt_version="$(gen_semver)"
  while [[ "$alt_version" == "$base_version" ]]; do
    alt_version="$(gen_semver)"
  done

  # Escolher aleatoriamente qual README terá versão diferente
  local divergent_idx
  divergent_idx=$(_rand_int 0 4)

  local locations=("" "steering" "hooks" "agents" "skills")
  local titles=("Archetype: Mobile Flutter" "Steering — Archetype Mobile Flutter" "Hooks — Archetype Mobile Flutter" "Agents — Archetype Mobile Flutter" "Skills — Archetype Mobile Flutter")
  local tags=("Archetype | mobile-flutter" "Steering File | Archetype: mobile-flutter" "Hooks | Archetype: mobile-flutter" "Agents | Archetype: mobile-flutter" "Skills | Archetype: mobile-flutter")

  local i
  for (( i = 0; i < 5; i++ )); do
    local loc="${locations[$i]}"
    local title="${titles[$i]}"
    local tag="${tags[$i]}"
    local version

    if [[ $i -eq $divergent_idx ]]; then
      version="$alt_version"
    else
      version="$base_version"
    fi

    local dir_path
    if [[ -z "$loc" ]]; then
      dir_path="${archetype_dir}"
    else
      dir_path="${archetype_dir}/${loc}"
      mkdir -p "$dir_path"
    fi

    cat > "${dir_path}/README.md" <<EOF
# ${title}

> **${tag} | Versão: ${version}**
>
> Conteúdo de teste.

---

## Conteúdo

Texto de teste.

---

*Versão: ${version} | Última revisão: 2026-04*
EOF
  done

  echo "${archetype_dir}"
}

# =============================================================================
# Property Test: versões consistentes DEVEM ser aceitas (100 iterações)
# =============================================================================
@test "Property 6a: archetype mobile-flutter com versão consistente em todos READMEs é aceito (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_valid_version_dir)"

    if ! validate_version_consistency "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: versão consistente rejeitada"
      echo "READMEs:"
      for loc in "${README_LOCATIONS[@]}"; do
        local p
        if [[ -z "$loc" ]]; then p="${archetype_dir}/README.md"; else p="${archetype_dir}/${loc}/README.md"; fi
        echo "  ${p}:"
        grep -n 'Versão:' "$p" 2>/dev/null || echo "    (sem referência de versão)"
      done
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação rejeitou ${failures}/100 conjuntos consistentes de versão"
}

# =============================================================================
# Property Test: versões inconsistentes DEVEM ser rejeitadas (100 iterações)
# =============================================================================
@test "Property 6b: archetype mobile-flutter com versão inconsistente em algum README é rejeitado (100 iterações)" {
  local failures=0
  local i

  for (( i = 0; i < 100; i++ )); do
    local archetype_dir
    archetype_dir="$(gen_invalid_version_dir)"

    if validate_version_consistency "${archetype_dir}"; then
      echo "FALHA na iteração ${i}: versão inconsistente aceita"
      echo "READMEs:"
      for loc in "${README_LOCATIONS[@]}"; do
        local p
        if [[ -z "$loc" ]]; then p="${archetype_dir}/README.md"; else p="${archetype_dir}/${loc}/README.md"; fi
        echo "  ${p}:"
        grep -n 'Versão:' "$p" 2>/dev/null || echo "    (sem referência de versão)"
      done
      failures=$((failures + 1))
    fi
  done

  [[ ${failures} -eq 0 ]] || fail "Validação aceitou ${failures}/100 conjuntos inconsistentes de versão"
}

# =============================================================================
# Property Test: o archetype REAL passa a validação de consistência de versão
# =============================================================================
@test "Property 6c: archetype mobile-flutter real referencia versão 0.1.0 em todos READMEs" {
  # Verificar que o archetype real existe
  [[ -d "${ARCHETYPE_DIR}" ]] || skip "Archetype mobile-flutter não encontrado em ${ARCHETYPE_DIR}"

  # Verificar consistência geral
  run validate_version_consistency "${ARCHETYPE_DIR}"
  assert_success

  # Verificar que a versão é especificamente 0.1.0
  local loc readme_path
  for loc in "${README_LOCATIONS[@]}"; do
    if [[ -z "$loc" ]]; then
      readme_path="${ARCHETYPE_DIR}/README.md"
    else
      readme_path="${ARCHETYPE_DIR}/${loc}/README.md"
    fi

    # Verificar que contém "Versão: 0.1.0"
    run grep -c 'Versão: 0.1.0' "$readme_path"
    assert_success
    # Deve ter ao menos 1 referência
    [[ "${output}" -ge 1 ]] || fail "README em ${loc:-raiz} não referencia Versão: 0.1.0"

    # Verificar que NÃO contém outra versão além de 0.1.0
    local other_versions
    other_versions=$(grep -oE 'Versão: [0-9]+\.[0-9]+\.[0-9]+' "$readme_path" 2>/dev/null | grep -v 'Versão: 0.1.0' || true)
    [[ -z "$other_versions" ]] || fail "README em ${loc:-raiz} referencia versão diferente de 0.1.0: ${other_versions}"
  done
}
