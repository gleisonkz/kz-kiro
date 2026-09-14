# Changelog

## 0.2.2 (2026-09-14)

### Correções

- Corrigir detecção de findings bloqueantes no quality gate do code review: a análise passa a ser por seção (bloco sob o header "## Bloqueante"/"## Crítico") em vez de grep no texto inteiro, e o guard de negação reconhece português e inglês (ex.: "None."). Elimina o falso positivo em que o header de severidade sem findings bloqueava a PR indevidamente, e o falso negativo em que uma negação em outra parte do texto anulava um finding real.

## 0.2.1 (2026-09-01)

### CI/CD

- Suportar branch dev e usar base_ref dinamico no workflow de code review

## 0.2.0 (2026-08-28)

### Funcionalidades

- Adicionar workflow kiro-code-review.yml com agentes em paralelo e quality gate
- Adicionar CODEOWNERS com placeholders para times
- Adicionar review-rules.schema.json para validacao do review-rules
- Adicionar scripts de validacao estatica: floating-promises, missing-tests, breaking-changes, coverage

### Correções

- Corrigir review-rules.schema.json que estava vazio (conteudo estava em arquivo .tmp)

## 0.1.0 (2026-08-28)

### Funcionalidades

- Adicionar archetype inicial de servico NestJS
- Adicionar steering: architecture, stack-and-tooling, naming-conventions, ci-cd
- Adicionar hooks: kiro-doctor, build-after-agent, lint-after-agent, run-tests-after-task, review-messaging-patterns
- Adicionar skills: generate-module, generate-message-handler, generate-processor
- Adicionar agentes de code review: code, architecture, security, performance, consistency
- Adicionar configuracao de MCP server
