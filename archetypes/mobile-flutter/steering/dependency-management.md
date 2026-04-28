---
inclusion: fileMatch
fileMatchPattern: "**/pubspec.yaml"
---

# Dependency & Utility Management

Rules for adding new dependencies and utilities to the Monte Bravo Customer App (Melos monorepo).

---

## Runtime Dependencies (`package:core`)

All third-party runtime libraries (Riverpod, Http, etc.) are exported by `package:core/core.dart`.

- **Rule**: Never add third-party libraries directly to feature packages. Add to `core` and export them
- **Rule**: If a feature needs a new library, add to `packages/core/pubspec.yaml`, export in `packages/core/lib/dependencies.dart`, and run `melos bootstrap`

### How to add a new dependency

1. Add to `packages/core/pubspec.yaml` under `dependencies`
2. Export in `packages/core/lib/dependencies.dart`
3. Run `melos bootstrap` from root to sync
4. Import in features via `import 'package:core/core.dart';`

**PROHIBITED:** Adding external dependencies directly to a feature package's `pubspec.yaml` unless it is a dev dependency or a very specific reason exists (must be approved).

---

## Development Dependencies (`package:core_dev`)

All development tools (build_runner, linters, mocktail) are centralized in `package:core_dev`.

- **Rule**: Every module's `dev_dependencies` must include `core_dev`
- **Rule**: Use `import 'package:core_dev/core_dev.dart'` and `import 'package:flutter_test/flutter_test.dart'` in test files

---

## Shared Utilities

- **Global Utilities**: place in `packages/core/lib/utils/`
- **Feature-Specific Utilities**: place in `widgets/` or `utils/` inside the feature package only if truly unique

### Rules for Utilities

1. **Check First**: before creating, check `packages/core/lib/utils/` to see if it already exists
2. **Pure Logic**: utilities should be pure functions, independent of state
3. **Test Coverage**: all shared utilities must have unit tests in `packages/core/test/utils/`

---

## Core Package Usage

- Features should depend on `core`
- Avoid direct imports of sub-files: never `import 'package:core/src/...';`
- Use barrel files: `package:core/core.dart`
