#!/usr/bin/env bats
# Testes unitários para steering files de contratos de API do archetype mobile-flutter.
# Valida existência, frontmatter e conteúdo dos 6 contratos de API.
# Requisitos: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/mobile-flutter"
  STEERING_DIR="${ARCHETYPE_DIR}/steering"
}

# --- Existência dos 6 contratos de API ---

@test "api-contracts: auth-api.md existe" {
  [ -f "${STEERING_DIR}/auth-api.md" ]
}

@test "api-contracts: forgot-password-api.md existe" {
  [ -f "${STEERING_DIR}/forgot-password-api.md" ]
}

@test "api-contracts: home-api.md existe" {
  [ -f "${STEERING_DIR}/home-api.md" ]
}

@test "api-contracts: notifications-api.md existe" {
  [ -f "${STEERING_DIR}/notifications-api.md" ]
}

@test "api-contracts: profile-api.md existe" {
  [ -f "${STEERING_DIR}/profile-api.md" ]
}

@test "api-contracts: settings-api.md existe" {
  [ -f "${STEERING_DIR}/settings-api.md" ]
}

# --- Frontmatter: todos os contratos têm inclusion auto com name e description ---

@test "api-contracts: auth-api.md tem inclusion auto" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/auth-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'inclusion: auto'
}

@test "api-contracts: auth-api.md tem campo name" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/auth-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'name: auth-api'
}

@test "api-contracts: auth-api.md tem campo description" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/auth-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'description:'
}

@test "api-contracts: forgot-password-api.md tem inclusion auto" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/forgot-password-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'inclusion: auto'
}

@test "api-contracts: forgot-password-api.md tem campo name" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/forgot-password-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'name: forgot-password-api'
}

@test "api-contracts: forgot-password-api.md tem campo description" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/forgot-password-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'description:'
}

@test "api-contracts: home-api.md tem inclusion auto" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/home-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'inclusion: auto'
}

@test "api-contracts: home-api.md tem campo name" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/home-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'name: home-api'
}

@test "api-contracts: home-api.md tem campo description" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/home-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'description:'
}

@test "api-contracts: notifications-api.md tem inclusion auto" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/notifications-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'inclusion: auto'
}

@test "api-contracts: notifications-api.md tem campo name" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/notifications-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'name: notifications-api'
}

@test "api-contracts: notifications-api.md tem campo description" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/notifications-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'description:'
}

@test "api-contracts: profile-api.md tem inclusion auto" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/profile-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'inclusion: auto'
}

@test "api-contracts: profile-api.md tem campo name" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/profile-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'name: profile-api'
}

@test "api-contracts: profile-api.md tem campo description" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/profile-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'description:'
}

@test "api-contracts: settings-api.md tem inclusion auto" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/settings-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'inclusion: auto'
}

@test "api-contracts: settings-api.md tem campo name" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/settings-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'name: settings-api'
}

@test "api-contracts: settings-api.md tem campo description" {
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "${STEERING_DIR}/settings-api.md" | sed '1d;$d')"
  echo "${frontmatter}" | grep -q 'description:'
}

# --- auth-api.md: endpoints e interfaces (Req 4.1) ---

@test "auth-api: documenta endpoint POST /auth/login" {
  run grep -iE "POST.*/auth/login" "${STEERING_DIR}/auth-api.md"
  assert_success
}

@test "auth-api: documenta endpoint POST /auth/signup" {
  run grep -iE "POST.*/auth/signup" "${STEERING_DIR}/auth-api.md"
  assert_success
}

@test "auth-api: documenta endpoint POST /auth/logout" {
  run grep -iE "POST.*/auth/logout" "${STEERING_DIR}/auth-api.md"
  assert_success
}

@test "auth-api: documenta endpoint GET /auth/me" {
  run grep -iE "GET.*/auth/me" "${STEERING_DIR}/auth-api.md"
  assert_success
}

@test "auth-api: documenta endpoint POST /auth/validate-token" {
  run grep -iE "POST.*/auth/validate-token" "${STEERING_DIR}/auth-api.md"
  assert_success
}

@test "auth-api: contém interface AuthRemoteDataSource" {
  run grep -i "AuthRemoteDataSource" "${STEERING_DIR}/auth-api.md"
  assert_success
}

@test "auth-api: contém interface AuthRepository" {
  run grep -i "AuthRepository" "${STEERING_DIR}/auth-api.md"
  assert_success
}

# --- forgot-password-api.md: endpoints e interface (Req 4.2) ---

@test "forgot-password-api: documenta endpoint POST forgot-password" {
  run grep -iE "POST.*forgot-password" "${STEERING_DIR}/forgot-password-api.md"
  assert_success
}

@test "forgot-password-api: documenta endpoint POST verify-otp" {
  run grep -iE "POST.*verify-otp" "${STEERING_DIR}/forgot-password-api.md"
  assert_success
}

@test "forgot-password-api: contém interface ForgotPasswordRemoteDataSource" {
  run grep -i "ForgotPasswordRemoteDataSource" "${STEERING_DIR}/forgot-password-api.md"
  assert_success
}

# --- home-api.md: endpoints e interface (Req 4.3) ---

@test "home-api: documenta endpoint GET balance" {
  run grep -iE "GET.*balance" "${STEERING_DIR}/home-api.md"
  assert_success
}

@test "home-api: documenta endpoint GET notices" {
  run grep -iE "GET.*notices" "${STEERING_DIR}/home-api.md"
  assert_success
}

@test "home-api: contém interface HomeRemoteDataSource" {
  run grep -i "HomeRemoteDataSource" "${STEERING_DIR}/home-api.md"
  assert_success
}

# --- notifications-api.md: endpoints e interface (Req 4.4) ---

@test "notifications-api: documenta endpoint GET notifications" {
  run grep -iE "GET.*notifications" "${STEERING_DIR}/notifications-api.md"
  assert_success
}

@test "notifications-api: documenta endpoint POST read" {
  run grep -iE "POST.*read" "${STEERING_DIR}/notifications-api.md"
  assert_success
}

@test "notifications-api: documenta endpoint POST delete" {
  run grep -iE "POST.*delete" "${STEERING_DIR}/notifications-api.md"
  assert_success
}

@test "notifications-api: contém interface NotificationRemoteDataSource" {
  run grep -i "NotificationRemoteDataSource" "${STEERING_DIR}/notifications-api.md"
  assert_success
}

# --- profile-api.md: endpoint e interface (Req 4.5) ---

@test "profile-api: documenta endpoint GET profile" {
  run grep -iE "GET.*profile" "${STEERING_DIR}/profile-api.md"
  assert_success
}

@test "profile-api: contém interface ProfileRemoteDataSource" {
  run grep -i "ProfileRemoteDataSource" "${STEERING_DIR}/profile-api.md"
  assert_success
}

# --- settings-api.md: endpoints e interface (Req 4.6) ---

@test "settings-api: documenta endpoint GET settings" {
  run grep -iE "GET.*api/settings" "${STEERING_DIR}/settings-api.md"
  assert_success
}

@test "settings-api: documenta endpoint GET communication-prefs" {
  run grep -iE "GET.*communication-prefs" "${STEERING_DIR}/settings-api.md"
  assert_success
}

@test "settings-api: documenta endpoint POST communication-prefs" {
  run grep -iE "POST.*communication-prefs" "${STEERING_DIR}/settings-api.md"
  assert_success
}

@test "settings-api: contém interface SettingsRemoteDataSource" {
  run grep -i "SettingsRemoteDataSource" "${STEERING_DIR}/settings-api.md"
  assert_success
}

# --- Nota de aviso sobre mocks em todos os contratos exceto auth-api.md (Req 4.7) ---

@test "api-contracts: forgot-password-api.md contém nota de aviso sobre mocks" {
  run grep -iE "(Based on current mocks|baseado em mocks)" "${STEERING_DIR}/forgot-password-api.md"
  assert_success
}

@test "api-contracts: home-api.md contém nota de aviso sobre mocks" {
  run grep -iE "(Based on current mocks|baseado em mocks)" "${STEERING_DIR}/home-api.md"
  assert_success
}

@test "api-contracts: notifications-api.md contém nota de aviso sobre mocks" {
  run grep -iE "(Based on current mocks|baseado em mocks)" "${STEERING_DIR}/notifications-api.md"
  assert_success
}

@test "api-contracts: profile-api.md contém nota de aviso sobre mocks" {
  run grep -iE "(Based on current mocks|baseado em mocks)" "${STEERING_DIR}/profile-api.md"
  assert_success
}

@test "api-contracts: settings-api.md contém nota de aviso sobre mocks" {
  run grep -iE "(Based on current mocks|baseado em mocks)" "${STEERING_DIR}/settings-api.md"
  assert_success
}

@test "api-contracts: auth-api.md nao contem nota de aviso sobre mocks (usa URLs reais)" {
  run grep -iE "(Based on current mocks|baseado em mocks)" "${STEERING_DIR}/auth-api.md"
  assert_failure
}
