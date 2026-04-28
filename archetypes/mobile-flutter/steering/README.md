# Steering — Archetype Mobile Flutter

> **Steering File | Archetype: mobile-flutter | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos que utilizam o archetype mobile-flutter.
> Ele complementa o baseline global com diretrizes específicas para projetos Flutter mobile.

---

## Steering Files Disponíveis

### Sempre carregados (`always`)

| Arquivo | Conteúdo |
|---|---|
| `coding-standards.md` | Arquitetura Clean, Riverpod, go_router, comentários, anti-patterns |
| `flutter-lints-security.md` | Regras de lint e políticas de segurança |

### Carregados por tipo de arquivo (`fileMatch`)

| Arquivo | Trigger |
|---|---|
| `flutter_best_practices.md` | Qualquer `**/*.dart` |
| `flutter-testing-patterns.md` | Qualquer `**/*_test.dart` ou `**/test/**/*.dart` |
| `dependency-management.md` | Qualquer `**/pubspec.yaml` |

### Carregados automaticamente por contexto (`auto`)

| Nome | Descrição |
|---|---|
| `clean-architecture` | Criação de features, organização de camadas |
| `design-system` | Componentes UI, widgets, telas, Atomic Design |
| `auth-api` | Login, signup, logout, token |
| `home-api` | Balance, notices |
| `notifications-api` | Lista de notificações, marcar como lido, deletar |
| `profile-api` | Dados de perfil, contas bancárias |
| `settings-api` | Configurações do usuário, preferências de comunicação |
| `forgot-password-api` | Reset de senha, verificação OTP |

### Carregados sob demanda (`manual`)

| Comando no chat | Propósito |
|---|---|
| `#code-review` | Checklist completo para revisão de código Flutter/Dart |

---

## Relação com o Baseline Global

Estes steering files complementam (não substituem) o baseline global:

- `engineering-principles.md` — princípios gerais de engenharia
- `security-baseline.md` — requisitos mínimos de segurança
- `specs-policy.md` — política de especificações
- `documentation-baseline.md` — padrão de documentação

---

## Fontes

Conteúdo extraído do repositório `mb-customer-app-mobile` (configurações Kiro do projeto mobile).

---

*Versão: 0.1.0 | Última revisão: 2026-04*
