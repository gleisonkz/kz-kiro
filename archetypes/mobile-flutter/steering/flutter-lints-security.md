---
inclusion: always
---

# Lints and Security

---

## `flutter_lints`

Keep `flutter_lints: ^<recent version>` in `dev_dependencies` and `include: package:flutter_lints/flutter.yaml` in the root `analysis_options.yaml` of the package/app (propagate via `include:` in monorepo packages).

---

## Extra recommended rules

In `analysis_options.yaml`, under `linter: rules:`, align the project with:

- `always_use_package_imports`
- `avoid_print`
- `prefer_const_constructors`
- `prefer_const_literals_to_create_immutables`
- `avoid_unnecessary_containers`
- `avoid_dynamic_calls`
- `unnecessary_null_checks`
- `prefer_single_quotes`
- `require_trailing_commas`

When editing `analysis_options.yaml` or `pubspec.yaml`, keep these policies aligned across workspace packages.

---

## Security

- **Never** commit tokens, API keys, certificates or passwords
- Use **environment variables** (non-versioned `.env` + `.env.example`) and **flavors** for distinct builds
- Do not embed secrets in code, versioned assets or comments
