---
inclusion: fileMatch
fileMatchPattern: "**/*.dart"
---

# Flutter Best Practices

Rules applied automatically when working with any `.dart` file.

---

## When Uncertain

If you are not sure about an answer or cannot find enough information in the available context:

- **Do not invent, assume, or hallucinate** details (API contracts, class names, file paths, behavior)
- Clearly state what you do not know
- Ask for more context or details to provide a precise answer
- Prioritize accuracy and reliability over always having a response

---

## Absolute Imports (MANDATORY)

**Never** use relative imports (`../`, `./`). Always use absolute `package:` imports.

```dart
// ❌ Wrong
import '../providers/login_providers.dart';
import '../../domain/entities/user.dart';

// ✅ Correct
import 'package:feature_login/presentation/providers/login_providers.dart';
import 'package:feature_login/domain/entities/user.dart';
```

### Import ordering

1. `dart:` libraries
2. `package:flutter/` and Flutter packages
3. `package:` third-party packages
4. `package:ds_monte_bravo_mobile/` (Design System)
5. `package:core/` (shared)
6. `package:feature_*/` (feature packages)

Separate each group with a blank line.

---

## `const`

- Use `const` on constructors and literals when all arguments are compile-time constants
- Prefer `const Text(...)`, `const EdgeInsets...`, `const` lists/maps when immutable
- Enable in the analyzer: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `prefer_const_declarations`

---

## Null Safety — Avoid the `!` Operator

Do not use `!` in new code. Prefer a safe flow:

```dart
// ❌ Bad
final n = user!.name;

// ✅ Better
final n = user?.name ?? '';

// ✅ Or early return
if (user == null) return;
final n = user.name; // promoted, no !
```

After `if (x != null)`, Dart promotes the type — do not add `!`.

In `async` after `await`, use `if (!context.mounted) return;` before using `context`.

---

## Naming

- Classes / enums / typedefs: `PascalCase`
- Variables, parameters, methods: `camelCase`
- Files: `snake_case.dart`
- Private members: `_prefixed`
- Providers: `<n>Provider` suffix
- Use cases: `<Action>UseCase` (e.g., `LoginUseCase`)

---

## Clean Code

- **Single Responsibility**: each class/function does one thing
- **Small functions**: max ~30 lines per method; extract if longer
- **Meaningful names**: no abbreviations (`usr`, `btn`), no generic names (`data`, `info`, `temp`)
- **No magic numbers/strings**: use named constants
- **Immutability**: prefer `final`, `const`, immutable state classes with `copyWith`
- **No `print()`**: use proper logging or remove
- **Trailing commas** on multi-line arguments for clean diffs

---

## Design System — `ds_monte_bravo_mobile`

All generic UI components **must** come from the project's Design System package.

### Rules

- **Never recreate** components that already exist in the DS
- **Always import** from `package:ds_monte_bravo_mobile/` for generic UI components
- Feature-specific components go in `presentation/widgets/`
- If a component might be reused across features, it belongs in the DS

---

## Widgets

- Keep widget files lean (~100 lines max); extract reusable widgets
- Avoid `Container` only for padding/color — prefer `Padding`, `ColoredBox`, `DecoratedBox`
- Split large pages into smaller widgets under `presentation/widgets/`

### Prefer `StatelessWidget` over helper methods

Always prefer a `StatelessWidget` over a builder function or helper method.

**Rules:**
1. Never use private `_build*` methods that return `Widget` — extract a `StatelessWidget`
2. Mark the widget constructor `const` whenever all fields are immutable
3. Each extracted widget lives in its own file (`snake_case.dart`) under `presentation/widgets/`
4. The only acceptable use of a local builder closure is inside framework APIs (e.g., `ListView.builder`)

---

## SOLID in Flutter

### S — Single Responsibility
- **Widget**: compose UI and delegate events
- **Notifier**: orchestrate state and call use cases
- **Repository**: single responsibility for data access

### O — Open/Closed
Extend behavior with abstractions instead of large `if`/`switch` chains.

### L — Liskov Substitution
Implementations must honor the contract.

### I — Interface Segregation
Small, focused interfaces. One repository per bounded context.

### D — Dependency Inversion
Depend on abstractions in domain/presentation, not on concrete data implementations.

---

## Control Flow — Avoid Unnecessary if/else

Prefer early returns (guard clauses) to reduce nesting. Use `switch` expression over `else if` chains.

---

## Mock Data Sources

Every feature datasource must have a **mock implementation** for development and testing without a running backend.

**Rules for mocks:**
- Place alongside real datasource: `data/datasources/<n>_mock_datasource.dart`
- Simulate network latency with `Future.delayed` (500–1000ms)
- Include success and error scenarios
- Wire mock via environment variable (`USE_MOCK`)

---

## Fail Fast — Do Not Assume Missing Information

```dart
// ❌ Bad — guessing behavior
String getUserName(User? user) {
  return user?.name ?? 'Default User';
}

// ✅ Good — fail fast
String getUserName(User? user) {
  if (user == null) throw ArgumentError('User cannot be null');
  return user.name;
}
```
