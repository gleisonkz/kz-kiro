---
inclusion: auto
name: auth-api
description: Use when implementing or modifying authentication flows (login, signup, logout, token validation, current user). Contains API contracts, error formats, and implementation patterns for the auth service.
---

# Auth Service API

## Base URL

| Environment | URL |
|---|---|
| Dev | `https://auth-service.api.dev.ctvm.montebravo.com.br` |

The `ApiClient` `baseUrl` must be set to this value. Paths in datasource calls start with `auth/` (no leading slash).

---

## Endpoints

### POST /auth/login

**Request body**
```json
{ "email": "user@example.com", "password": "secret123" }
```

**Response 200**
```json
{ "email": "user@example.com", "accessToken": "<jwt>" }
```

**Response 401** — invalid credentials (Problem Details format)

---

### POST /auth/signup

**Request body**
```json
{ "email": "user@example.com", "password": "secret123" }
```

**Response 201** — empty body on success

**Response 400** — validation errors

---

### POST /auth/logout

**Headers** `Authorization: Bearer <accessToken>`

**Response 200** — empty body

**Response 401** — token invalid or missing

---

### GET /auth/me

**Headers** `Authorization: Bearer <accessToken>`

**Response 200**
```json
{ "email": "user@example.com" }
```

**Response 401** — token invalid or missing (empty body)

---

### POST /auth/validate-token

**Headers** `Authorization: Bearer <accessToken>`

**Response 200** — token is valid (empty body)

**Response 401** — token invalid or missing (empty body)

---

## Error Formats

### Problem Details (RFC 9110) — 401, 403, 500

Extract message from `detail` (falls back to `title`).

### Validation Errors — 400

Extract field errors from `errors` map.

---

## Clean Architecture Reference

### DataSource interface

```dart
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> signup({required String email, required String password});
  Future<void> logout();
  Future<UserModel> getMe();
  Future<void> validateToken();
}
```

### Repository interface (domain)

```dart
abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<void> signup({required String email, required String password});
  Future<void> logout();
  Future<User> getMe();
  Future<void> validateToken();
}
```

### Correct path format

| Endpoint | Path string |
|---|---|
| POST /auth/login | `'auth/login'` |
| POST /auth/signup | `'auth/signup'` |
| POST /auth/logout | `'auth/logout'` |
| GET /auth/me | `'auth/me'` |
| POST /auth/validate-token | `'auth/validate-token'` |
