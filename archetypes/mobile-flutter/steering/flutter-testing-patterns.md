---
inclusion: fileMatch
fileMatchPattern: ["**/*_test.dart", "**/test/**/*.dart"]
---

# Flutter Testing Patterns

---

## General Rule

Always follow **Centralized Mocks and Fixtures** structure: mocks and fixtures centralized per package, with the test tree mirroring `lib/`.

---

## Folder Structure

```
packages/features/<feature_name>/
├── lib/
│   ├── domain/...
│   ├── data/...
│   └── presentation/...
└── test/
    ├── mocks/
    │   ├── mock_<name>_repository.dart
    │   ├── mock_<name>_usecase.dart
    │   └── mocks.dart                    # barrel: exports all mocks + core_dev
    ├── fixtures/
    │   ├── <name>_fixtures.dart
    │   └── fixtures.dart                 # barrel: exports all fixtures + entities
    ├── domain/usecases/
    ├── data/repositories/
    └── presentation/providers/
```

---

## Mandatory Rules

### Mocks (`test/mocks/`)
- **PROHIBITED**: inline mocks inside test files or individual test folders
- Always use `mocktail` re-exported via `package:core_dev/core_dev.dart`
- Each mock in its own file: `mock_<name>.dart`
- `mocks.dart` barrel must export all mocks and `core_dev`

### Fixtures (`test/fixtures/`)
- Fixtures are NOT mocks — they provide ready data (Entities, Models)
- Use static classes: `ProfileFixtures.validUser`
- `fixtures.dart` barrel must export all fixtures and related Entities

### Organization
- Test structure mirrors `lib/` exactly
- Naming: `<original_file>_test.dart`
- Import via barrel files only

### Global Mocks
- Mocks used by multiple features go in `packages/core_dev/lib/mocks/` and exported via `core_dev.dart`

---

## Naming Convention

| Type | Pattern | Example |
|---|---|---|
| Mock file | `mock_<class>.dart` | `mock_home_repository.dart` |
| Fixture file | `<context>_fixtures.dart` | `recommendation_fixtures.dart` |
| Test file | `<file>_test.dart` | `get_balance_usecase_test.dart` |
| Barrels | `mocks.dart` / `fixtures.dart` | — |

---

## Test Patterns by Layer

| Layer | What to test | Mock what |
|---|---|---|
| Use case | Business logic, validation, orchestration | Repository interfaces |
| Repository | Data mapping, error handling | DataSource |
| Provider/Notifier | State transitions, side effects | Use cases |
| Widget | UI rendering, user interactions | Providers (override) |

---

## Conventions

- Use `mocktail` for mocking (imported via `package:core_dev/core_dev.dart`)
- One test file per source file, same relative path under `test/`
- Group related tests with `group()`
- Use `setUp()` for shared initialization
- Name tests: `should [expected behavior] when [condition]`
- Run: `flutter test` or `melos run test`

**CRITICAL**: Do not proceed with test creation without ensuring Mocks and Fixtures are properly centralized and exported by the corresponding barrels.
