---
inclusion: always
---

# Coding Standards

Rules Kiro must follow when generating, editing, or suggesting any code in this project.

---

## Architecture — Clean Architecture

- Domain layer has zero Flutter/external imports
- Data layer depends only on domain, never on presentation
- Presentation depends only on domain, never on data directly
- Use cases have single responsibility
- Repository interfaces live in domain; implementations live in data
- No business logic in widgets or pages

---

## State Management — Riverpod

- Riverpod is the sole state management solution
- Providers are properly scoped (not global when feature-specific)
- Use `ref.watch` in build, `ref.read` for callbacks
- State classes are immutable with `copyWith`
- Avoid `ref.read` inside build methods
- Dispose resources properly

---

## Navigation — go_router

- Routes defined in feature's `routes.dart`
- Use `context.go()` for replacement, `context.push()` for stack
- No hardcoded route strings in widgets — use constants or the routes file

---

## Comments

- Never narrate what the code does (e.g., avoid `// returns the user`)
- Only comment non-obvious intent, trade-offs, or constraints
- If the variable or function name is self-explanatory, no comment needed
- All comments in English
- Comments must be brief, short, and objective

---

## Performance

- No heavy computation inside `build()`
- Lists use `ListView.builder`, never `ListView` with fixed children
- Images use `cached_network_image`
- Avoid unnecessary rebuilds — use `select()` with Riverpod

---

## Anti-Patterns

| Anti-pattern | Do this instead |
|---|---|
| God widget (500+ lines) | Split into smaller widgets |
| Business logic in UI | Move to use case |
| Direct API calls from widget | Use repository + data source |
| `setState` for complex state | Use Riverpod provider |
| Catching generic `Exception` | Catch specific types |
| Mutable state in entities | Use immutable classes with `copyWith` |
| Hardcoded route strings in widgets | Use constants or route file |
| `print()` for logging | Use proper logging solution |
