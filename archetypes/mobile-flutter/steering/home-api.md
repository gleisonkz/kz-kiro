---
inclusion: auto
name: home-api
description: Use when implementing or modifying home screen features (balance, notices). Contains API contracts and implementation patterns for the home service.
---

# Home API — Endpoint Contracts

> ⚠️ Based on current mocks. Update when backend confirms the final contract.

## Base URL

Configurable via `ApiClient.baseUrl` (currently `http://localhost:8080`).

---

## GET `api/home/balance`

**Auth:** `Authorization: Bearer <token>`

**Response 200:**
```json
{ "balance": 6898256.67 }
```

| Field | Type | Required | Description |
|---|---|---|---|
| `balance` | `number` (double) | yes | Consolidated balance |

---

## GET `api/home/notices`

**Auth:** `Authorization: Bearer <token>`

**Response 200:**
```json
{
  "notices": [
    {
      "id": "1",
      "title": "Bem-vindo ao Monte Bravo",
      "body": "Sua conta foi criada com sucesso.",
      "isRead": true
    }
  ]
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | yes | Unique identifier |
| `title` | `string` | yes | Notice title |
| `body` | `string` | yes | Notice body |
| `isRead` | `bool` | no | Whether it was read (default: `false`) |

---

## DataSource Reference

```dart
abstract class HomeRemoteDataSource {
  Future<double> getBalance();
  Future<List<NoticeModel>> getNotices();
}
```
