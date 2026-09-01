# Changelog

## 0.2.1 (2026-09-01)

### CI/CD

- Suportar branch dev e usar base_ref dinamico no workflow de code review

## 0.2.0 (2026-08-28)

### Funcionalidades

- Adicionar agentes de code review: code, architecture, security, performance, consistency
- Adicionar review-rules.yml com regras de validacao estatica
- Adicionar workflow kiro-code-review.yml com agentes em paralelo e quality gate
- Adicionar CODEOWNERS com placeholders para times
- Adicionar scripts de validacao estatica: async-usage, missing-tests, breaking-changes

## 0.1.0 (2026-08-28)

### Funcionalidades

- Adicionar archetype inicial de API NestJS
- Adicionar steering: architecture, stack-and-tooling, naming-conventions, ci-cd
- Adicionar hooks: kiro-doctor, build-after-agent, run-tests-after-task, review-vision-scope
- Adicionar skills: generate-module, generate-endpoint, generate-kysely-query, generate-ssrm-query
- Adicionar configuracao de MCP server
