# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## 0.4.0 (2026-08-04)

### Funcionalidades

- Ativar steering de changeset por file match condicional

## 0.3.0 (2026-08-03)

### Funcionalidades

- Adicionar steering de diretrizes para changesets em monorepos

## 0.2.0 (2026-06-19)

### Funcionalidades

- Documentar serialização de mensagens e taxonomia de tópicos Kafka (ADR-002)
- Documentar padrões de autenticação, autorização e gestão de segredos (ADR 004)

## [0.1.0] - 2025-06-15

### Added

- Steering files: engineering-principles, security-baseline, specs-policy, documentation-baseline, pinned-dependencies
- Configuração MCP com servidor Atlassian Rovo homologado
- Hook global kiro-doctor para diagnóstico de conformidade
- Scripts de automação: bootstrap.sh, sync.sh, doctor.sh
- Arquivo VERSION com versionamento semântico
- Mecanismo de exceções no doctor.sh
