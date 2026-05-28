# Technical Design Document

## Overview

Este design descreve a implementação do hook `release-components` — um hook Kiro do tipo `userTriggered` que automatiza o processo de release de componentes versionáveis no repositório de governança. O hook é implementado como um arquivo `.kiro.hook` com um prompt `askAgent` que instrui o agente a executar o fluxo completo de release usando comandos git nativos e capacidades de leitura/escrita de arquivos.

## Architecture

### Abordagem: Prompt-Driven Agent Hook

Não há scripts externos, CLIs ou dependências adicionais. O agente usa comandos git nativos e suas capacidades de leitura/escrita de arquivos para executar todo o fluxo.

## Components and Interfaces

### 1. Hook File (`.kiro/hooks/release-components.kiro.hook`)

Arquivo JSON seguindo o schema de hooks Kiro:

```json
{
  "enabled": true,
  "name": "Release Components",
  "version": "1",
  "description": "Detecta componentes com mudanças, gera commits, versiona e cria changelog.",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "<prompt detalhado com instruções completas>"
  }
}
```

**Interface:** Acionado manualmente pelo usuário via painel de hooks do Kiro.

### 2. Steering File (`.kiro/steering/release-process.md`)

Documento de referência com front-matter `inclusion: manual` contendo:
- Definição dos diretórios versionáveis
- Regras de classificação semântica
- Formatos de VERSION, CHANGELOG, tags e commits
- Exemplos de cada artefato

**Interface:** Referenciado pelo prompt do hook via `#[[file:.kiro/steering/release-process.md]]` ou incluído manualmente pelo usuário.

### 3. Artefatos por Componente (gerados pelo hook)

Para cada Componente_Versionável processado:

| Artefato | Caminho | Formato |
|----------|---------|---------|
| VERSION | `<componente>/VERSION` | `MAJOR.MINOR.PATCH` (texto puro) |
| CHANGELOG | `<componente>/CHANGELOG.md` | Markdown com seções por versão |
| Git Commits | Histórico git | Conventional Commits com escopo |
| Git Tag | Referência git | `<componente>@<versão>` (anotada) |

### Fluxo de Execução

```
Usuário aciona hook
        │
        ▼
┌─ Fase 1: Detecção ─────────────────────────────┐
│ git status --porcelain                          │
│ Agrupar arquivos por componente                 │
│ Filtrar: apenas archetypes/*, baselines/*,      │
│          powers/* (subdiretórios)               │
│ Ignorar: arquivos soltos, raiz, docs/, etc.     │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─ Fase 2: Resumo + Confirmação ──────────────────┐
│ Apresentar componentes afetados                  │
│ Listar arquivos excluídos (se houver)            │
│ Solicitar confirmação do usuário                 │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─ Fase 3: Loop por Componente (alfabético) ──────┐
│  3a: git diff → análise semântica               │
│  3b: git add + git commit (mudanças agrupadas)  │
│  3c: Escrever VERSION + CHANGELOG               │
│  3d: git add + git commit (release)             │
│  3e: git tag -a (anotada)                       │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─ Fase 4: Resumo Final ─────────────────────────┐
│ Componentes processados + versões               │
│ Componentes com falha + etapa                   │
│ Total de commits + tags                         │
└─────────────────────────────────────────────────┘
```

## Data Models

### VERSION File

```
1.2.0
```

- Apenas a string semver sem prefixo `v`, sem espaços, sem newline trailing
- Cada segmento é um número inteiro não-negativo
- Primeira release de componente novo: sempre `0.1.0`

### CHANGELOG.md

```markdown
# Changelog

## 1.2.0 (2026-05-28)

### Funcionalidades

- Adicionar hook de revisão consolidada para fronteiras

### Manutenção

- Atualizar trigger de lint para execução condicional

## 1.1.0 (2026-05-15)

### Funcionalidades

- Adicionar skill de geração de módulo
```

### Git Tag

- Formato: `<nome-componente>@<versão>`
- Tipo: anotada (`git tag -a`)
- Mensagem: `Release <nome-componente>@<versão>`
- Exemplos: `backend-csharp@1.2.0`, `global@2.0.0`, `mb-frontend-react@0.3.0`

### Tabela de Classificação Semântica

| Tipo de Mudança | Classificação | Bump |
|-----------------|---------------|------|
| Novo hook, steering, skill, agent | `feat` | minor |
| Novo arquivo de configuração | `feat` | minor |
| Correção de bug em hook/steering | `fix` | patch |
| Atualização de README, docs | `docs` | patch |
| Reestruturação sem mudança funcional | `refactor` | patch |
| Atualização de versão/dependência | `chore` | patch |
| Melhoria de performance em prompt | `perf` | patch |
| Mudança em CI/CD configs | `ci` | patch |
| Remoção de hook/steering/skill existente | breaking (`feat!`) | major |
| Renomeação de arquivo público | breaking (`refactor!`) | major |

## Error Handling

| Cenário | Comportamento |
|---------|---------------|
| `git status` falha | Informar erro, encerrar execução |
| `git add` falha | Informar erro + componente, parar componente, perguntar se continua |
| `git commit` falha | Informar erro + componente, parar componente, perguntar se continua |
| `git tag` conflito | Apresentar opções ao usuário (sobrescrever/ignorar/abortar) |
| VERSION inválido | Informar formato inválido, solicitar orientação |
| Classificação incerta | Apresentar diff, solicitar classificação manual |
| Nenhuma mudança | Informar "Nenhuma mudança encontrada para release", encerrar |

## Correctness Properties

### Property 1: Atomicidade por componente
Cada componente é processado completamente antes do próximo. Se falhar no meio, commits já feitos são preservados (não há rollback automático).

**Validates: Requirements 7.1, 7.4**

### Property 2: Idempotência parcial
Se executado novamente após release parcial, detecta apenas componentes com mudanças restantes.

**Validates: Requirements 1.1**

### Property 3: Sem push automático
O hook NÃO executa `git push`. O push fica a cargo do usuário.

**Validates: Requirements 7.2**

### Property 4: Confirmação obrigatória
O agente sempre solicita confirmação antes de iniciar commits.

**Validates: Requirements 7.3**

### Property 5: Classificação verificável
Para arquivos untracked, o agente sempre confirma a classificação com o usuário.

**Validates: Requirements 2.8**

## Testing Strategy

A validação é manual dado que o hook é um prompt para o agente:

1. **Cenário: Componente único com mudanças simples** — Verificar detecção, classificação, commit, VERSION, CHANGELOG e tag.
2. **Cenário: Múltiplos componentes** — Verificar ordem alfabética e processamento sequencial.
3. **Cenário: Nenhuma mudança** — Verificar mensagem de encerramento.
4. **Cenário: Arquivos fora de componentes** — Verificar que são ignorados e reportados.
5. **Cenário: Primeira release (sem VERSION)** — Verificar criação com `0.1.0`.
6. **Cenário: Breaking change** — Verificar bump major e marcador no commit.
7. **Cenário: Tag conflitante** — Verificar apresentação de opções ao usuário.

## Constraints

1. **Sem dependências externas**: Não requer semantic-release, standard-version ou ferramentas similares.
2. **Limite de 72 caracteres**: Mensagens de commit na linha de assunto.
3. **Português do Brasil**: Descrições de commits e entradas de changelog em pt-BR.
4. **Git nativo**: Apenas comandos git padrão (`status`, `diff`, `add`, `commit`, `tag`).
