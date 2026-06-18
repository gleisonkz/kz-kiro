#!/usr/bin/env bats
# Testes unitários para steering files do archetype mobile-flutter.
# Valida existência, frontmatter YAML e conteúdo dos 15 steering files + README.
# Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"
  STEERING_DIR="${ARCHETYPE_DIR}/steering"
}

# Helper: extrai frontmatter YAML (conteúdo entre os dois primeiros ---)
get_frontmatter() {
  local file="$1"
  sed -n '2,/^---$/p' "$file" | sed '$d'
}

# Helper: extrai valor de um campo simples do frontmatter (sem yq, via grep+sed)
# Funciona para campos simples como "inclusion: always" ou "name: design-system"
# Para campos com valor entre aspas, remove as aspas.
get_frontmatter_field() {
  local file="$1"
  local field="$2"
  local value
  value="$(get_frontmatter "$file" | grep "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^["'"'"']//;s/["'"'"']$//')"
  if [ -z "$value" ]; then
    echo "null"
  else
    echo "$value"
  fi
}

# Helper: extrai valor bruto do campo fileMatchPattern (pode ser string ou array YAML)
get_frontmatter_fileMatchPattern() {
  local file="$1"
  local frontmatter
  frontmatter="$(get_frontmatter "$file")"
  # Tenta primeiro como valor inline (string ou array em uma linha)
  local value
  value="$(echo "$frontmatter" | grep "^fileMatchPattern:" | head -1 | sed 's/^fileMatchPattern:[[:space:]]*//')"
  echo "$value"
}

# =============================================================================
# Existência dos 15 steering files + README
# =============================================================================

@test "steering: existem exatamente 15 arquivos de steering (excluindo README)" {
  local count
  count=$(find "${STEERING_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
  [ "$count" -eq 15 ]
}

@test "steering: README.md existe" {
  [ -f "${STEERING_DIR}/README.md" ]
}

@test "steering: coding-standards.md existe" {
  [ -f "${STEERING_DIR}/coding-standards.md" ]
}

@test "steering: flutter_best_practices.md existe" {
  [ -f "${STEERING_DIR}/flutter_best_practices.md" ]
}

@test "steering: clean-architecture.md existe" {
  [ -f "${STEERING_DIR}/clean-architecture.md" ]
}

@test "steering: flutter-clean-architecture.md existe" {
  [ -f "${STEERING_DIR}/flutter-clean-architecture.md" ]
}

@test "steering: flutter-lints-security.md existe" {
  [ -f "${STEERING_DIR}/flutter-lints-security.md" ]
}

@test "steering: flutter-testing-patterns.md existe" {
  [ -f "${STEERING_DIR}/flutter-testing-patterns.md" ]
}

@test "steering: dependency-management.md existe" {
  [ -f "${STEERING_DIR}/dependency-management.md" ]
}

@test "steering: design-system.md existe" {
  [ -f "${STEERING_DIR}/design-system.md" ]
}

@test "steering: code-review.md existe" {
  [ -f "${STEERING_DIR}/code-review.md" ]
}

@test "steering: auth-api.md existe" {
  [ -f "${STEERING_DIR}/auth-api.md" ]
}

@test "steering: forgot-password-api.md existe" {
  [ -f "${STEERING_DIR}/forgot-password-api.md" ]
}

@test "steering: home-api.md existe" {
  [ -f "${STEERING_DIR}/home-api.md" ]
}

@test "steering: notifications-api.md existe" {
  [ -f "${STEERING_DIR}/notifications-api.md" ]
}

@test "steering: profile-api.md existe" {
  [ -f "${STEERING_DIR}/profile-api.md" ]
}

@test "steering: settings-api.md existe" {
  [ -f "${STEERING_DIR}/settings-api.md" ]
}

# =============================================================================
# Frontmatter YAML válido em cada steering file
# =============================================================================

@test "steering: todos os 15 arquivos possuem frontmatter com delimitadores ---" {
  local file
  for file in "${STEERING_DIR}"/*.md; do
    [[ "$(basename "$file")" == "README.md" ]] && continue
    local first_line
    first_line="$(head -n 1 "$file")"
    if [ "$first_line" != "---" ]; then
      fail "Arquivo $(basename "$file") não inicia com --- (frontmatter ausente)"
    fi
  done
}

@test "steering: todos os 15 arquivos possuem campo inclusion no frontmatter" {
  local file
  for file in "${STEERING_DIR}"/*.md; do
    [[ "$(basename "$file")" == "README.md" ]] && continue
    local inclusion
    inclusion="$(get_frontmatter_field "$file" "inclusion")"
    if [ "$inclusion" = "null" ] || [ -z "$inclusion" ]; then
      fail "Arquivo $(basename "$file") não possui campo inclusion no frontmatter"
    fi
  done
}

@test "steering: todos os campos inclusion possuem valor válido (always|fileMatch|auto|manual)" {
  local file
  for file in "${STEERING_DIR}"/*.md; do
    [[ "$(basename "$file")" == "README.md" ]] && continue
    local inclusion
    inclusion="$(get_frontmatter_field "$file" "inclusion")"
    case "$inclusion" in
      always|fileMatch|auto|manual) ;;
      *) fail "Arquivo $(basename "$file") tem inclusion inválido: '$inclusion'" ;;
    esac
  done
}

# =============================================================================
# coding-standards.md: inclusion always, temas obrigatórios
# =============================================================================

@test "coding-standards: inclusion é always" {
  local inclusion
  inclusion="$(get_frontmatter_field "${STEERING_DIR}/coding-standards.md" "inclusion")"
  [ "$inclusion" = "always" ]
}

@test "coding-standards: aborda Clean Architecture" {
  run grep -i "Clean Architecture" "${STEERING_DIR}/coding-standards.md"
  assert_success
}

@test "coding-standards: aborda Riverpod" {
  run grep -i "Riverpod" "${STEERING_DIR}/coding-standards.md"
  assert_success
}

@test "coding-standards: aborda go_router" {
  run grep -i "go_router" "${STEERING_DIR}/coding-standards.md"
  assert_success
}

@test "coding-standards: aborda performance" {
  run grep -iE "(Performance|build\(\)|ListView\.builder)" "${STEERING_DIR}/coding-standards.md"
  assert_success
}

@test "coding-standards: aborda anti-patterns" {
  run grep -iE "(anti.?pattern|avoid|prohibited|never)" "${STEERING_DIR}/coding-standards.md"
  assert_success
}

# =============================================================================
# flutter_best_practices.md: inclusion fileMatch com **/*.dart
# =============================================================================

@test "flutter_best_practices: inclusion é fileMatch" {
  local inclusion
  inclusion="$(get_frontmatter_field "${STEERING_DIR}/flutter_best_practices.md" "inclusion")"
  [ "$inclusion" = "fileMatch" ]
}

@test "flutter_best_practices: fileMatchPattern contém **/*.dart" {
  local pattern
  pattern="$(get_frontmatter_field "${STEERING_DIR}/flutter_best_practices.md" "fileMatchPattern")"
  [[ "$pattern" == *"**/*.dart"* ]]
}

@test "flutter_best_practices: aborda imports absolutos" {
  run grep -iE "(absolute.*import|package:|never.*relative)" "${STEERING_DIR}/flutter_best_practices.md"
  assert_success
}

@test "flutter_best_practices: aborda nomenclatura" {
  run grep -iE "(PascalCase|camelCase|snake_case)" "${STEERING_DIR}/flutter_best_practices.md"
  assert_success
}

@test "flutter_best_practices: aborda clean code" {
  run grep -iE "(clean code|single responsibility|magic number|immutab)" "${STEERING_DIR}/flutter_best_practices.md"
  assert_success
}

@test "flutter_best_practices: aborda Design System" {
  run grep -iE "(Design System|ds_monte_bravo)" "${STEERING_DIR}/flutter_best_practices.md"
  assert_success
}

# =============================================================================
# flutter-lints-security.md: inclusion always, flutter_lints, regras extras, segurança
# =============================================================================

@test "flutter-lints-security: inclusion é always" {
  local inclusion
  inclusion="$(get_frontmatter_field "${STEERING_DIR}/flutter-lints-security.md" "inclusion")"
  [ "$inclusion" = "always" ]
}

@test "flutter-lints-security: menciona flutter_lints" {
  run grep -i "flutter_lints" "${STEERING_DIR}/flutter-lints-security.md"
  assert_success
}

@test "flutter-lints-security: contém regras extras recomendadas" {
  run grep -i "always_use_package_imports" "${STEERING_DIR}/flutter-lints-security.md"
  assert_success
}

@test "flutter-lints-security: aborda segurança" {
  run grep -iE "(Security|segurança|token|API key|senha|password)" "${STEERING_DIR}/flutter-lints-security.md"
  assert_success
}

# =============================================================================
# flutter-testing-patterns.md: inclusion fileMatch com patterns de test
# =============================================================================

@test "flutter-testing-patterns: inclusion é fileMatch" {
  local inclusion
  inclusion="$(get_frontmatter_field "${STEERING_DIR}/flutter-testing-patterns.md" "inclusion")"
  [ "$inclusion" = "fileMatch" ]
}

@test "flutter-testing-patterns: fileMatchPattern inclui patterns de test" {
  local pattern
  pattern="$(get_frontmatter_fileMatchPattern "${STEERING_DIR}/flutter-testing-patterns.md")"
  [[ "$pattern" == *"_test.dart"* ]] || [[ "$pattern" == *"test/"* ]]
}

@test "flutter-testing-patterns: aborda mocks centralizados" {
  run grep -iE "(centralized.*mock|mock.*centraliz|test/mocks/)" "${STEERING_DIR}/flutter-testing-patterns.md"
  assert_success
}

@test "flutter-testing-patterns: aborda fixtures" {
  run grep -iE "(fixture|test/fixtures/)" "${STEERING_DIR}/flutter-testing-patterns.md"
  assert_success
}

@test "flutter-testing-patterns: menciona mocktail via core_dev" {
  run grep -iE "(mocktail|core_dev)" "${STEERING_DIR}/flutter-testing-patterns.md"
  assert_success
}

# =============================================================================
# dependency-management.md: inclusion fileMatch com **/pubspec.yaml
# =============================================================================

@test "dependency-management: inclusion é fileMatch" {
  local inclusion
  inclusion="$(get_frontmatter_field "${STEERING_DIR}/dependency-management.md" "inclusion")"
  [ "$inclusion" = "fileMatch" ]
}

@test "dependency-management: fileMatchPattern contém **/pubspec.yaml" {
  local pattern
  pattern="$(get_frontmatter_field "${STEERING_DIR}/dependency-management.md" "fileMatchPattern")"
  [[ "$pattern" == *"pubspec.yaml"* ]]
}

@test "dependency-management: menciona Core_Package (package:core)" {
  run grep -iE "(package:core|Core_Package|core/pubspec)" "${STEERING_DIR}/dependency-management.md"
  assert_success
}

@test "dependency-management: menciona Core_Dev_Package" {
  run grep -iE "(core_dev|Core_Dev|dev.depend)" "${STEERING_DIR}/dependency-management.md"
  assert_success
}

# =============================================================================
# design-system.md: inclusion auto, name design-system, ds_monte_bravo_mobile, prefixo Mb
# =============================================================================

@test "design-system: inclusion é auto" {
  local inclusion
  inclusion="$(get_frontmatter_field "${STEERING_DIR}/design-system.md" "inclusion")"
  [ "$inclusion" = "auto" ]
}

@test "design-system: name é design-system" {
  local name
  name="$(get_frontmatter_field "${STEERING_DIR}/design-system.md" "name")"
  [ "$name" = "design-system" ]
}

@test "design-system: menciona package ds_monte_bravo_mobile" {
  run grep -i "ds_monte_bravo_mobile" "${STEERING_DIR}/design-system.md"
  assert_success
}

@test "design-system: menciona prefixo Mb" {
  run grep -E "\bMb\b" "${STEERING_DIR}/design-system.md"
  assert_success
}

# =============================================================================
# code-review.md: inclusion manual, checklist com 8 seções
# =============================================================================

@test "code-review: inclusion é manual" {
  local inclusion
  inclusion="$(get_frontmatter_field "${STEERING_DIR}/code-review.md" "inclusion")"
  [ "$inclusion" = "manual" ]
}

@test "code-review: contém seção Architecture" {
  run grep -E "^### Architecture" "${STEERING_DIR}/code-review.md"
  assert_success
}

@test "code-review: contém seção Dart Quality" {
  run grep -E "^### Dart Quality" "${STEERING_DIR}/code-review.md"
  assert_success
}

@test "code-review: contém seção Riverpod" {
  run grep -E "^### Riverpod" "${STEERING_DIR}/code-review.md"
  assert_success
}

@test "code-review: contém seção Naming" {
  run grep -E "^### Naming" "${STEERING_DIR}/code-review.md"
  assert_success
}

@test "code-review: contém seção go_router" {
  run grep -E "^### go_router" "${STEERING_DIR}/code-review.md"
  assert_success
}

@test "code-review: contém seção Widgets" {
  run grep -E "^### Widgets" "${STEERING_DIR}/code-review.md"
  assert_success
}

@test "code-review: contém seção Testing" {
  run grep -E "^### Testing" "${STEERING_DIR}/code-review.md"
  assert_success
}

@test "code-review: contém seção Performance" {
  run grep -E "^### Performance" "${STEERING_DIR}/code-review.md"
  assert_success
}
