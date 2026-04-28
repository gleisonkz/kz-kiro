---
inclusion: auto
name: settings-api
description: Use when implementing or modifying settings features (user settings, communication preferences). Contains API contracts and implementation patterns for the settings service.
---

# Settings API — Endpoint Contracts

> ⚠️ Based on current mocks. Update when backend confirms the final contract.

## Base URL

Configurable via `ApiClient.baseUrl` (currently `http://localhost:8080`).

---

## GET `api/settings`

**Auth:** `Authorization: Bearer <token>`

**Response 200:**
```json
{
  "name": "João Silva",
  "email": "joao.silva@email.com",
  "phone": "(11) 99999-9999"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | yes | User name |
| `email` | `string` | yes | Email |
| `phone` | `string` | no | Phone (default: `""`) |

---

## GET `api/settings/communication-prefs`

**Auth:** `Authorization: Bearer <token>`

**Response 200:**
```json
{
  "emailMarketing": true,
  "emailTransactional": true,
  "smsMarketing": false,
  "smsTransactional": true,
  "whatsappMarketing": false,
  "whatsappTransactional": false
}
```

---

## POST `api/settings/communication-prefs`

**Auth:** `Authorization: Bearer <token>`

**Request:** All 6 boolean fields are required in the body.

**Response 200:** `{}`

---

## DataSource Reference

```dart
abstract class SettingsRemoteDataSource {
  Future<UserSettingsModel> getSettings();
  Future<CommunicationPrefsModel> getCommunicationPrefs();
  Future<void> updateCommunicationPrefs(CommunicationPrefsModel prefs);
}
```
