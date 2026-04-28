---
inclusion: auto
name: profile-api
description: Use when implementing or modifying user profile features (profile data, bank accounts). Contains API contracts and implementation patterns for the profile service.
---

# Profile API — Endpoint Contracts

> ⚠️ Based on current mocks. Update when backend confirms the final contract.

## Base URL

Configurable via `ApiClient.baseUrl` (currently `http://localhost:8080`).

---

## GET `api/profile`

**Auth:** `Authorization: Bearer <token>`

**Response 200:**
```json
{
  "name": "Thabata",
  "cpf": "000.000.000-00",
  "accountNumber": "12345-6",
  "email": "thabata@email.com",
  "phone": "",
  "accounts": [
    {
      "type": "Conta Investimento",
      "bankCode": "102",
      "bankName": "SP Banco Nubank",
      "agency": "0001",
      "accountNumber": "3242424-2"
    }
  ]
}
```

**Profile fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | yes | User name |
| `cpf` | `string` | yes | Formatted CPF |
| `accountNumber` | `string` | yes | Main account number |
| `email` | `string` | no | Email (default: `""`) |
| `phone` | `string` | no | Phone (default: `""`) |
| `accounts` | `array` | no | Bank accounts list (default: `[]`) |

---

## DataSource Reference

```dart
abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
}
```
