# Archetype: Mobile Flutter

> **Archetype | mobile-flutter | Versão: 0.1.0**
>
> Configurações Kiro para projetos Flutter mobile seguindo Clean Architecture, Riverpod e Melos monorepo.

---

## Origem

Configurações extraídas do repositório `mb-customer-app-mobile` (Monte Bravo Customer App).

---

## Estrutura

```
archetypes/mobile-flutter/
├── README.md
├── agents/
│   └── README.md
├── hooks/
│   ├── README.md
│   ├── barrel-export-reminder.kiro.hook
│   ├── check-relative-imports.kiro.hook
│   ├── dart-analyze-save.kiro.hook
│   └── scaffold-test-file.kiro.hook
├── mcp/
│   └── mcp.json
├── skills/
│   └── README.md
└── steering/
    ├── README.md
    ├── auth-api.md
    ├── clean-architecture.md
    ├── code-review.md
    ├── coding-standards.md
    ├── dependency-management.md
    ├── design-system.md
    ├── flutter-clean-architecture.md
    ├── flutter-lints-security.md
    ├── flutter-testing-patterns.md
    ├── flutter_best_practices.md
    ├── forgot-password-api.md
    ├── home-api.md
    ├── notifications-api.md
    ├── profile-api.md
    └── settings-api.md
```

---

## Stack

- **Framework:** Flutter (Dart)
- **Arquitetura:** Clean Architecture por feature
- **State Management:** Riverpod
- **Navegação:** go_router
- **Monorepo:** Melos
- **Design System:** ds_monte_bravo_mobile (Atomic Design)
- **Testes:** mocktail via core_dev, padrão centralizado de mocks/fixtures

---

## Como usar

Para aplicar este archetype em um novo projeto Flutter:

```bash
./scripts/bootstrap.sh --project-type mobile-flutter --target <caminho-do-projeto>
```

O bootstrap aplica automaticamente o baseline global, o archetype e os powers necessários.

---

*Versão: 0.1.0 | Última revisão: 2026-04*
