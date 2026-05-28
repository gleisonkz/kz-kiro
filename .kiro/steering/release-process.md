---
inclusion: manual
---

# Processo de Release de Componentes Versionáveis

Este documento define o processo padronizado de release para componentes versionáveis do repositório de governança Kiro.

## Componentes Versionáveis

São considerados componentes versionáveis todos os **subdiretórios de primeiro nível** dentro de:

- `archetypes/` — ex: `archetypes/backend-csharp/`, `archetypes/bff-fastify/`, `archetypes/frontend-react/`, `archetypes/agents/`, `archetypes/hooks/`, `archetypes/mobile-flutter/`, `archetypes/skills/`, `archetypes/steering/`
- `baselines/` — ex: `baselines/global/`
- `powers/` — ex: `powers/mb-frontend-react/`, `powers/mb-atlassian-rovo/`, `powers/mb-kiro-manager/`, `powers/mb-mobile-flutter/`, `powers/mb-monorepo-nx/`

### O que NÃO é componente versionável

- Arquivos na raiz do repositório (`README.md`, `.gitignore`, etc.)
- Diretórios fora do escopo (`docs/`, `scripts/`, `examples/`, `.github/`, `.kiro/`)
- Arquivos soltos dentro de `archetypes/`, `baselines/` ou `powers/` que não pertencem a um subdiretório (ex: `powers/mb-atlassian-rovo.zip`, `archetypes/.DS_Store`)

> **Nota:** Futuramente, `docs/` e `scripts/` podem ser adicionados ao escopo de componentes versionáveis.

## Formato do VERSION File

Cada componente versionável possui um arquivo `VERSION` na sua raiz.

### Regras

- Contém apenas a string de versão no formato `MAJOR.MINOR.PATCH`
- Cada segmento é um número inteiro não-negativo
- Sem prefixo `v`
- Sem espaços ou quebras de linha ao final
- Primeira release de componente novo: sempre `0.1.0` (independente do tipo de mudança)

### Exemplo

```
1.2.0
```

### Localização

```
archetypes/backend-csharp/VERSION
baselines/global/VERSION
powers/mb-frontend-react/VERSION
```

## Formato do CHANGELOG.md

Cada componente versionável possui um arquivo `CHANGELOG.md` na sua raiz.

### Estrutura

```markdown
# Changelog

## 1.2.0 (2026-05-28)

### Funcionalidades

- Adicionar hook de revisão consolidada para fronteiras
- Implementar detecção condicional de mudanças

### Correções

- Corrigir pattern de arquivos no hook de lint

### Manutenção

- Atualizar trigger de lint para execução condicional

## 1.1.0 (2026-05-15)

### Funcionalidades

- Adicionar skill de geração de módulo
```

### Regras

- Versão mais recente sempre no topo
- Cabeçalho de versão: `## MAJOR.MINOR.PATCH (YYYY-MM-DD)`
- Seções agrupadas por tipo com heading `###`
- Seções sem entradas são omitidas
- Cada entrada é um item de lista markdown (`- `)
- Descrição em português do Brasil, máximo 100 caracteres por entrada
- Ao atualizar, inserir nova versão após `# Changelog`, preservando histórico anterior

### Seções (em ordem)

| Seção | Tipo de commit |
|-------|---------------|
| `### Funcionalidades` | `feat` |
| `### Correções` | `fix` |
| `### Documentação` | `docs` |
| `### Refatoração` | `refactor` |
| `### Manutenção` | `chore` |
| `### Performance` | `perf` |
| `### CI/CD` | `ci` |

## Formato das Tags Git

### Regras

- Formato: `<nome-componente>@<versão>`
- Tipo: tag anotada (`git tag -a`)
- Mensagem de anotação: `Release <nome-componente>@<versão>`
- Sem prefixo `v` na versão

### Exemplos

```
backend-csharp@1.2.0
global@2.0.0
mb-frontend-react@0.3.0
agents@0.1.0
```

## Formato de Commits (Conventional Commits)

### Regras

- Formato: `<tipo>(<escopo>): <descrição>`
- Escopo: nome do diretório do componente versionável
- Linha de assunto completa: máximo 72 caracteres
- Descrição em português do Brasil, verbo no infinitivo
- Breaking changes: usar `!` após tipo ou `BREAKING CHANGE:` no footer

### Tipos válidos

| Tipo | Descrição |
|------|-----------|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `docs` | Documentação |
| `refactor` | Refatoração sem mudança funcional |
| `chore` | Manutenção (deps, configs) |
| `perf` | Melhoria de performance |
| `ci` | Mudanças em CI/CD |

### Exemplos

```
feat(backend-csharp): adicionar hook de revisão de fronteiras
fix(bff-fastify): corrigir pattern de arquivos no lint
docs(frontend-react): atualizar README com instruções de setup
refactor(global): reorganizar estrutura de steering files
chore(mb-frontend-react): atualizar versão do MCP server
feat(backend-csharp)!: remover skill obsoleta de geração
```

### Commit de Release

Após todos os commits de mudança de um componente, criar commit de release:

```
chore(backend-csharp): release v1.2.0
```

Este commit contém apenas as atualizações do `VERSION` e `CHANGELOG.md`.

## Classificação Semântica de Mudanças

### Tabela de Classificação

| Tipo de Mudança | Classificação | Bump |
|-----------------|---------------|------|
| Novo hook, steering, skill, agent | `feat` | minor |
| Novo arquivo de configuração (mcp.json, etc.) | `feat` | minor |
| Nova funcionalidade em hook existente | `feat` | minor |
| Correção de bug em hook/steering/skill | `fix` | patch |
| Atualização de README ou documentação | `docs` | patch |
| Reestruturação sem mudança funcional | `refactor` | patch |
| Atualização de versão/dependência | `chore` | patch |
| Melhoria de performance em prompt | `perf` | patch |
| Mudança em CI/CD configs | `ci` | patch |
| Remoção de hook/steering/skill existente | `feat!` (breaking) | major |
| Renomeação de arquivo público | `refactor!` (breaking) | major |
| Alteração de interface/contrato consumido | `feat!` (breaking) | major |

### Regras de Bump

- `feat` → bump `minor`
- `fix`, `docs`, `refactor`, `chore`, `perf`, `ci` → bump `patch`
- Qualquer tipo com `!` ou `BREAKING CHANGE:` → bump `major`
- Múltiplos commits no mesmo componente: usar o bump de maior precedência (`major` > `minor` > `patch`)

### Critérios de Breaking Change

Uma mudança é considerada breaking quando:

1. Remove um hook, steering, skill ou agent existente
2. Renomeia um arquivo que é referenciado por outros projetos
3. Altera a estrutura de um hook de forma incompatível (ex: muda o schema do prompt)
4. Remove ou renomeia configurações de MCP server
5. Altera contratos/interfaces consumidos por projetos downstream

## Fluxo de Execução

### Ordem obrigatória por componente

1. **Análise semântica** — classificar mudanças e determinar commits
2. **Commits das mudanças** — `git add` + `git commit` para cada grupo
3. **Atualização do VERSION** — escrever nova versão no arquivo
4. **Atualização do CHANGELOG** — gerar/atualizar com entradas da release
5. **Commit de release** — `git add VERSION CHANGELOG.md` + `git commit`
6. **Criação da tag** — `git tag -a`

### Regras de agrupamento de commits

- Mudanças do **mesmo tipo** e **mesmo propósito** → um único commit
- Mudanças de **tipos distintos** ou **propósitos independentes** → commits separados
- Exemplo: editar 3 hooks para adicionar condição de execução = 1 commit `feat`
- Exemplo: adicionar novo hook + corrigir bug em outro = 2 commits (`feat` + `fix`)
