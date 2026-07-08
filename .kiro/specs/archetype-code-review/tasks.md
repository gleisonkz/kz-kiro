# Implementation Plan: Code Review Automatizado via Kiro CLI

## Overview

Implementação de code review automatizado para Pull Requests usando Kiro CLI headless com agentes especializados por archetype. Os deliverables são: agentes em formato dual (markdown + JSON), workflows GitHub Actions por archetype, script de bootstrap, validação CI e testes de propriedade.

## Tasks

- [x] 1. Definir agentes do archetype frontend-react (JSON)
  - [x] 1.1 Criar `archetypes/frontend-react/agents/cli-code-reviewer.json` a partir do `code-reviewer.md` existente
    - Extrair conteúdo do markdown (sem frontmatter) e montar JSON com campos `name`, `description`, `instructions`
    - O campo `name` deve ser `cli-code-reviewer`, `description` vem do frontmatter, `instructions` é o corpo completo do .md
    - _Requirements: 1.2, 1.4, 1.5_

  - [x] 1.2 Criar `archetypes/frontend-react/agents/cli-architecture-reviewer.json` a partir do `architecture-reviewer.md` existente
    - Mesmo padrão: extrair frontmatter para `description`, corpo para `instructions`
    - _Requirements: 1.2, 1.4, 1.5_

  - [x] 1.3 Criar `archetypes/frontend-react/agents/cli-accessibility-reviewer.json` a partir do `accessibility-reviewer.md` existente
    - _Requirements: 1.2, 1.4, 1.5_

  - [x] 1.4 Criar `archetypes/frontend-react/agents/cli-performance-reviewer.json` a partir do `performance-reviewer.md` existente
    - _Requirements: 1.2, 1.4, 1.5_

- [x] 2. Definir agentes do archetype backend-csharp (Markdown + JSON)
  - [x] 2.1 Criar `archetypes/backend-csharp/agents/code-reviewer.md` com frontmatter e seções obrigatórias
    - Frontmatter: `name`, `description` em pt-BR
    - Seções: Papel, Contexto (C#/.NET, Clean Architecture, DDD), O que revisar (padrões C#, async/await, DI, SOLID, testes), Formato de resposta
    - _Requirements: 1.1, 1.3, 1.6_

  - [x] 2.2 Criar `archetypes/backend-csharp/agents/architecture-reviewer.md`
    - Foco: Clean Architecture, DDD boundaries, CQRS, camadas
    - _Requirements: 1.1, 1.3, 1.6_

  - [x] 2.3 Criar `archetypes/backend-csharp/agents/security-reviewer.md`
    - Foco: autenticação, autorização, injection, secrets, OWASP
    - _Requirements: 1.1, 1.3, 1.6_

  - [x] 2.4 Criar `archetypes/backend-csharp/agents/performance-reviewer.md`
    - Foco: async/await, allocations, EF Core queries, caching, N+1
    - _Requirements: 1.1, 1.3, 1.6_

  - [x] 2.5 Criar `archetypes/backend-csharp/agents/cli-code-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.6_

  - [x] 2.6 Criar `archetypes/backend-csharp/agents/cli-architecture-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.6_

  - [x] 2.7 Criar `archetypes/backend-csharp/agents/cli-security-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.6_

  - [x] 2.8 Criar `archetypes/backend-csharp/agents/cli-performance-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.6_

- [x] 3. Definir agentes do archetype bff-fastify (Markdown + JSON)
  - [x] 3.1 Criar `archetypes/bff-fastify/agents/code-reviewer.md` com frontmatter e seções obrigatórias
    - Contexto: Fastify, TypeScript, BFF pattern, integração com backends
    - _Requirements: 1.1, 1.3, 1.7_

  - [x] 3.2 Criar `archetypes/bff-fastify/agents/architecture-reviewer.md`
    - Foco: separação BFF, bounded contexts, routes, plugins
    - _Requirements: 1.1, 1.3, 1.7_

  - [x] 3.3 Criar `archetypes/bff-fastify/agents/api-contract-reviewer.md`
    - Foco: schemas Zod/JSON Schema, versionamento, backward compatibility, response types
    - _Requirements: 1.1, 1.3, 1.7_

  - [x] 3.4 Criar `archetypes/bff-fastify/agents/performance-reviewer.md`
    - Foco: async patterns, connection pooling, payload size, caching, serialization
    - _Requirements: 1.1, 1.3, 1.7_

  - [x] 3.5 Criar `archetypes/bff-fastify/agents/cli-code-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.7_

  - [x] 3.6 Criar `archetypes/bff-fastify/agents/cli-architecture-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.7_

  - [x] 3.7 Criar `archetypes/bff-fastify/agents/cli-api-contract-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.7_

  - [x] 3.8 Criar `archetypes/bff-fastify/agents/cli-performance-reviewer.json`
    - _Requirements: 1.2, 1.4, 1.7_

- [x] 4. Checkpoint - Validar agentes
  - Ensure all tests pass, ask the user if questions arise.
  - Verificar que todos os Agent_JSON seguem o schema (name com prefixo `cli-`, description 10-200 chars, instructions ≥ 100 chars)
  - Verificar que todos os Agent_Markdown possuem frontmatter e seções obrigatórias

- [x] 5. Criar workflows GitHub Actions por archetype
  - [x] 5.1 Criar `archetypes/frontend-react/workflows/kiro-code-review.yml` adaptando o workflow de referência (`kiro-code-review.yml` na raiz)
    - Jobs: prepare, review-code, review-architecture, review-accessibility, review-performance, post-review
    - Adaptar prompts conforme especialidade de cada agente frontend
    - Manter padrão de resiliência (`set -eo pipefail`, `KIRO_EXIT`, `::warning::`)
    - Consolidação com `extract_review()`, ANSI strip, comment marker, retry
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 6.1_

  - [x] 5.2 Criar `archetypes/backend-csharp/workflows/kiro-code-review.yml`
    - Jobs: prepare, review-code, review-architecture, review-security, review-performance, post-review
    - Adaptar prompts para contexto C#/.NET (menção a segurança em vez de acessibilidade)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 6.2_

  - [x] 5.3 Criar `archetypes/bff-fastify/workflows/kiro-code-review.yml`
    - Jobs: prepare, review-code, review-architecture, review-api-contract, review-performance, post-review
    - Adaptar prompts para contexto BFF/Fastify (contrato de API em vez de acessibilidade)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 6.3_

- [x] 6. Criar bootstrap script por archetype
  - [x] 6.1 Criar `archetypes/frontend-react/scripts/bootstrap-code-review.sh`
    - Aceitar flag `--force` para sobrescrever workflow existente
    - Copiar `kiro-code-review.yml` para `.github/workflows/` (criar diretório se necessário)
    - Copiar `cli-*.json` para `.kiro/agents/` (criar diretório se necessário)
    - Preservar workflow existente sem `--force`; sobrescrever JSON apenas se conteúdo difere
    - Nunca copiar arquivos `.md` de agentes
    - Preservar `cli-*.json` customizados no destino que não existem no archetype
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [x] 6.2 Criar `archetypes/backend-csharp/scripts/bootstrap-code-review.sh`
    - Mesmo comportamento do 6.1, adaptado para paths do archetype backend-csharp
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [x] 6.3 Criar `archetypes/bff-fastify/scripts/bootstrap-code-review.sh`
    - Mesmo comportamento do 6.1, adaptado para paths do archetype bff-fastify
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 7. Checkpoint - Validar workflows e bootstrap
  - Ensure all tests pass, ask the user if questions arise.
  - Executar `actionlint` nos workflows criados
  - Verificar que bootstrap scripts são executáveis e possuem tratamento de erro

- [x] 8. Criar script de validação CI para Agent Markdown
  - [x] 8.1 Criar `scripts/validate-agents.sh` que verifica a estrutura de todos os Agent_Markdown
    - Validar presença de frontmatter YAML com campos `name` e `description`
    - Validar existência das seções obrigatórias: "Papel", "Contexto", "O que revisar", "Formato de resposta"
    - Validar Agent_JSON contra schema (name com prefixo `cli-`, description entre 10-200 chars, instructions ≥ 100 chars)
    - Emitir mensagem de erro indicando qual arquivo e qual campo/seção está faltando
    - Exit code 0 se tudo válido, 1 se alguma falha
    - _Requirements: 1.8_

- [x] 9. Criar testes de propriedade (fast-check)
  - [x] 9.1 Configurar infraestrutura de testes: `package.json` com dependências de dev (fast-check, vitest, typescript) e `tsconfig.json`
    - Criar em `tests/` na raiz do monorepo
    - _Requirements: Design — Testing Strategy_

  - [x] 9.2 Implementar Property 3: Filtragem de arquivos alterados
    - **Property 3: File filtering invariant**
    - Gerar listas arbitrárias de filenames, aplicar filtragem (excluir dotfiles, limitar a 50), validar invariantes
    - **Validates: Requirements 2.2**

  - [x] 9.3 Implementar Property 4: Remoção completa de escape sequences ANSI
    - **Property 4: ANSI stripping completeness**
    - Gerar strings com escape sequences ANSI arbitrárias, aplicar strip (regex perl), validar que nenhuma sequence permanece
    - **Validates: Requirements 3.2**

  - [x] 9.4 Implementar Property 5: Estrutura do comentário consolidado
    - **Property 5: Consolidated comment structure**
    - Gerar conjuntos arbitrários de N resultados de agentes (incluindo ausentes), montar comentário, validar: marker, N sections `<details>`, título, rodapé, fallback para ausentes
    - **Validates: Requirements 3.3, 3.4, 3.7, 6.4**

  - [x] 9.5 Implementar Property 6: Bootstrap copia apenas JSON e preserva workflow existente
    - **Property 6: Bootstrap file copy correctness**
    - Simular estados arbitrários de diretório destino, executar lógica de bootstrap, validar: JSON copiados, nenhum .md copiado, workflow preservado, customizados preservados
    - **Validates: Requirements 4.2, 4.3, 4.4, 4.5**

- [x] 10. Criar testes bash (bats-core) para bootstrap e consolidação
  - [x] 10.1 Criar `tests/bootstrap.bats` com testes unitários do bootstrap script
    - Testar cópia correta de arquivos para diretório temporário
    - Testar preservação de workflow existente sem `--force`
    - Testar sobrescrita com `--force`
    - Testar preservação de agentes customizados no destino
    - Testar que .md nunca são copiados
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [x] 10.2 Criar `tests/validate-agents.bats` com testes do script de validação CI
    - Testar validação de frontmatter válido/inválido
    - Testar detecção de seções obrigatórias ausentes
    - Testar validação de Agent_JSON contra schema
    - _Requirements: 1.8_

- [x] 11. Checkpoint final - Validação completa
  - Ensure all tests pass, ask the user if questions arise.
  - Verificar que cada archetype tem: todos os agentes .md + .json, workflow kiro-code-review.yml, bootstrap script
  - Executar validate-agents.sh em todos os archetypes
  - Executar testes bats e property tests

## Notes

- Tasks marcadas com `*` são opcionais e podem ser puladas para um MVP mais rápido
- O workflow de referência `kiro-code-review.yml` (raiz) já está validado e funcional — servir como base para os 3 archetypes
- Frontend-react já tem 4 agentes .md prontos — apenas criar equivalentes JSON
- Backend-csharp e bff-fastify precisam de agentes criados do zero (md + json)
- bats-core para testes bash, fast-check + vitest para property tests em TypeScript
- Nenhuma dependência Node.js no workflow CI em si (apenas em dev/testing)
- Todos os prompts e conteúdos de agentes devem estar em pt-BR

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "2.1", "2.2", "2.3", "2.4", "3.1", "3.2", "3.3", "3.4"] },
    { "id": 1, "tasks": ["2.5", "2.6", "2.7", "2.8", "3.5", "3.6", "3.7", "3.8"] },
    { "id": 2, "tasks": ["5.1", "5.2", "5.3", "8.1", "9.1"] },
    { "id": 3, "tasks": ["6.1", "6.2", "6.3"] },
    { "id": 4, "tasks": ["9.2", "9.3", "9.4", "9.5", "10.1", "10.2"] }
  ]
}
```
