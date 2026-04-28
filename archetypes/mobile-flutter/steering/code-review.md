---
inclusion: manual
---

# Code Review

Systematic code review checklist for Flutter/Dart projects using Riverpod, go_router, and Clean Architecture.

---

## When Uncertain

- **Do not invent or assume** — do not flag something as wrong based on guesswork
- State clearly what is unclear and ask for more context before proceeding
- Prioritize accuracy over coverage; a missed comment is better than a wrong one

---

## Comment Policy

- All comments in English
- Comments must be brief, short, and objective
- Skip comments when the variable/function name is self-explanatory
- Only comment non-obvious intent, trade-offs, or constraints
- Never narrate what code does (`// returns the user`) — explain WHY if needed

---

## Review Checklist

### Architecture
- [ ] Domain layer has zero Flutter/external imports
- [ ] Data layer only depends on domain (not presentation)
- [ ] Presentation only depends on domain (not data directly)
- [ ] Use cases have single responsibility
- [ ] Repository interfaces live in domain, implementations in data
- [ ] No business logic in widgets or pages

### Dart Quality
- [ ] No unused imports
- [ ] All imports are absolute `package:` (no relative imports)
- [ ] Prefer `const` constructors where possible
- [ ] Use `final` for local variables
- [ ] Trailing commas on multi-line arguments
- [ ] Single quotes for strings
- [ ] Proper null safety (no unnecessary `!` operators)
- [ ] No `print()` statements (use logging)

### Riverpod
- [ ] Providers are properly scoped
- [ ] `ref.watch` in build, `ref.read` for callbacks
- [ ] State classes are immutable with `copyWith`
- [ ] Avoid `ref.read` inside build methods
- [ ] Dispose resources properly

### Naming
- [ ] Classes: `PascalCase`
- [ ] Files: `snake_case`
- [ ] Variables/methods: `camelCase`
- [ ] Private members: `_prefixed`
- [ ] Providers: `<n>Provider` suffix
- [ ] Use cases: `<Action>UseCase`

### go_router
- [ ] Routes defined in feature's `routes.dart`
- [ ] Use `context.go()` for replacement, `context.push()` for stack
- [ ] No hardcoded route strings in widgets

### Widgets
- [ ] No private `_build*` methods that return `Widget`
- [ ] Widget constructor is `const` when all fields are immutable
- [ ] Each extracted widget lives in its own file
- [ ] No `Container` used only for padding/color
- [ ] Widget files are lean (~100 lines max)

### Testing
- [ ] Every Notifier has unit tests
- [ ] Repository mocks use mocktail
- [ ] Test file mirrors source file structure
- [ ] No business logic tested through widget tests
- [ ] Mocks centralized in `test/mocks/`, not inline

### Performance
- [ ] No heavy computation in `build()`
- [ ] Lists use `ListView.builder`
- [ ] Images use `cached_network_image`
- [ ] No unnecessary rebuilds (use `select()` with Riverpod)

---

## Review Output Format

For each issue found:

- **File:** `path/to/file.dart`
- **Line:** line number
- **Severity:** `critical` | `warning` | `suggestion`
- **Issue:** what is wrong
- **Fix:** what to do instead

At the end, summarize: `X critical, Y warnings, Z suggestions.`
