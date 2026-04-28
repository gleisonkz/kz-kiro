---
inclusion: auto
name: clean-architecture
description: Use when creating new features, organizing code layers, or enforcing dependency rules in the Flutter monorepo
---

# Clean Architecture

## Overview

Each feature is an independent Dart package following the dependency rule: **presentation -> domain <- data**. Domain has zero external dependencies.

---

## Layer Rules

```
presentation/     depends on: domain (NEVER data)
  ├── pages/      Flutter widgets (screens)
  ├── widgets/    Feature-specific reusable widgets
  └── providers/  Riverpod state management

domain/           depends on: nothing (pure Dart)
  ├── entities/   Business objects
  ├── repositories/  Abstract interfaces
  └── usecases/   Single-responsibility business logic

data/             depends on: domain (NEVER presentation)
  ├── models/     DTOs with JSON serialization (extend entities)
  ├── repositories/  Concrete implementations
  └── datasources/   Remote/local data access
```

---

## Creating a New Feature

1. Create package: `packages/features/<feature_name>/`
2. Add `pubspec.yaml` with `resolution: workspace` and dependency on `core`
3. Add `analysis_options.yaml` including `../../../analysis_options.yaml`
4. Create barrel export: `lib/feature_<name>.dart`
5. Create domain entities, repository interface, use case
6. Create data models, repository impl, data source
7. Create presentation providers, state, pages
8. Create `lib/routes.dart` with `GoRoute`
9. Register routes in `apps/main_app/lib/router/app_router.dart`
10. Add package path to root `pubspec.yaml` workspace list
11. Write tests mirroring `lib/` structure under `test/`

---

## Entity vs Model

| | Entity | Model |
|---|---|---|
| Location | `domain/entities/` | `data/models/` |
| Purpose | Business object | Data transfer object |
| Dependencies | None | May import entity, JSON libs |
| Serialization | No | `fromJson` / `toJson` |
| Mutability | Immutable | Immutable |

---

## Use Case Pattern

Single method, single responsibility. Name = verb + noun.

---

## Repository Pattern

Interface in domain, implementation in data.

---

## Riverpod Provider Organization

```dart
// Data layer
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) { ... });
final authRepositoryProvider = Provider<AuthRepository>((ref) { ... });

// Domain layer
final loginUseCaseProvider = Provider<LoginUseCase>((ref) { ... });

// Presentation layer
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) { ... });
```

---

## Barrel Exports

Each package exposes only what consumers need:

```dart
// lib/feature_login.dart
library feature_login;
export 'presentation/pages/login_page.dart';
export 'routes.dart';
```

---

## When to Create a New Package

| Situation | Decision |
|---|---|
| Feature has its own screen/route | New package |
| Shared utility used by 2+ features | Add to `core` |
| Widget used by only one feature | Keep in feature's `widgets/` |
| Widget used by 2+ features | Consider a shared UI package |
