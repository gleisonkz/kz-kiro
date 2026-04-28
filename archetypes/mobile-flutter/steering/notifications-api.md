---
inclusion: auto
name: notifications-api
description: Use when implementing or modifying notification features (list, mark as read, delete). Contains API contracts and implementation patterns for the notifications service.
---

# Notifications API — Endpoint Contracts

> ⚠️ Based on current mocks. Update when backend confirms the final contract.

## Base URL

Configurable via `ApiClient.baseUrl` (currently `http://localhost:8080`).

---

## GET `api/notifications`

**Auth:** `Authorization: Bearer <token>`

**Response 200:**
```json
{
  "notifications": [
    {
      "id": "1",
      "title": "CDBs para diferentes objetivos",
      "body": "Descubra como explorar essa categoria de ativos...",
      "isRead": false,
      "category": "investment",
      "occurredAt": "2026-03-30T09:05:00.000"
    }
  ]
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | yes | Unique identifier |
| `title` | `string` | yes | Notification title |
| `body` | `string` | yes | Notification body |
| `isRead` | `bool` | no | Whether it was read (default: `false`) |
| `category` | `string` | no | `investment`, `transfer`, `travel`, `generic` (default: `generic`) |
| `occurredAt` | `string` or `int` | no | ISO 8601 or millisecond timestamp |

---

## POST `api/notifications/{id}/read`

**Auth:** `Authorization: Bearer <token>`
**Path param:** `id` — notification ID
**Request:** `{}` (empty body)
**Response 200:** `{}`

---

## POST `api/notifications/{id}/delete`

**Auth:** `Authorization: Bearer <token>`
**Path param:** `id` — notification ID
**Request:** `{}` (empty body)
**Response 200:** `{}`

---

## DataSource Reference

```dart
abstract class NotificationRemoteDataSource {
  Future<List<NotificationItemModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> delete(String id);
}
```
