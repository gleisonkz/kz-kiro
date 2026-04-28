---
inclusion: auto
name: forgot-password-api
description: Use when implementing or modifying forgot password features (reset password, OTP verification). Contains API contracts for the forgot password service.
---

# Forgot Password API — Endpoint Contracts

> ⚠️ Based on current mocks. Update when backend confirms the final contract.

## Base URL

Configurable via `ApiClient.baseUrl` (currently `http://localhost:8080`).

---

## POST `api/auth/forgot-password`

**Auth:** No

**Request:**
```json
{
  "email": "usuario@email.com"
}
```

**Response 200:** `{}` (app does not read the body on success)

---

## POST `api/auth/verify-otp`

**Auth:** No

**Request:**
```json
{
  "email": "usuario@email.com",
  "otp": "123456"
}
```

**Response 200:** `{}` (app does not read the body on success)

---

## DataSource Reference

```dart
abstract class ForgotPasswordRemoteDataSource {
  Future<void> sendResetEmail({required String email});
  Future<void> verifyOtp({required String email, required String otp});
}
```
