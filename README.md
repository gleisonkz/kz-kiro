# mb-kiro

> Repositório central de governança e distribuição de padrões Kiro para a organização MonteBravo.

---

## Propósito

Este repositório é a **fonte da verdade** para tudo que diz respeito à adoção, padronização e evolução do Kiro dentro da organização. Ele concentra:

- **Baseline global** — princípios, políticas de engenharia, segurança e documentação que valem para todos os projetos.
- **Archetypes** — configurações pré-moldadas de Kiro por tipo de projeto (ex.: backend C#, frontend React), prontas para serem aplicadas como ponto de partida.
- **Powers** — extensões reutilizáveis de Kiro empacotadas para instalação em projetos específicos.
- **Scripts** — automações de bootstrap, sincronização e diagnóstico do ambiente Kiro.
- **Testes** — suíte de testes automatizados para validar a integridade das configurações.
- **Documentação** — onboarding, governança, arquitetura e plano de rollout.

---

## Visão Geral da Arquitetura

```
mb-kiro/
├── baselines/              # Diretrizes e políticas globais (aplicadas a todos os projetos)
│   └── global/
│       ├── hooks/          # Hooks globais aplicáveis a qualquer projeto
│       ├── mcp/            # MCPs homologados pela organização
│       ├── steering/       # Arquivos .md de steering que o Kiro lê como contexto
│       ├── CHANGELOG.md
│       └── VERSION
├── archetypes/             # Templates de configuração Kiro por tipo de projeto
│   ├── backend-csharp/     # Archetype para backends em C#
│   ├── bff-fastify/        # Archetype para BFFs com Fastify
│   ├── frontend-react/     # Archetype para frontends React
│   ├── mobile-flutter/     # Archetype para apps mobile Flutter
│   ├── agents/             # Agentes compartilhados entre archetypes
│   ├── hooks/              # Hooks compartilhados entre archetypes
│   ├── skills/             # Skills compartilhadas entre archetypes
│   └── steering/           # Steering files compartilhados entre archetypes
├── powers/                 # Powers reutilizáveis empacotados para instalação nativa via Kiro
│   ├── mb-atlassian-rovo/  # Integração com Jira, Confluence e Compass
│   │   ├── POWER.md        # Manifest do power (com frontmatter + keywords)
│   │   ├── mcp.json        # MCP servers do power
│   │   └── VERSION         # Versão SemVer do power
│   ├── mb-frontend-react/  # Power especializado para projetos React
│   │   ├── POWER.md
│   │   ├── mcp.json
│   │   ├── steering/       # Steering files do power
│   │   └── VERSION
│   ├── mb-kiro-manager/    # Gerenciamento e governança do Kiro
│   │   ├── POWER.md
│   │   ├── steering/
│   │   └── VERSION
│   └── _drafts/            # Powers placeholder (não implementados, ignorados por scripts)
│       ├── mb-mobile-flutter/
│       └── mb-monorepo-nx/
├── scripts/                # Ferramentas CLI para bootstrap, sync e doctor
├── tests/                  # Suíte de testes automatizados
│   ├── unit/
│   ├── integration/
│   ├── properties/
│   ├── helpers/
│   ├── lib/
│   └── run_tests.sh
├── examples/               # Exemplos de manifesto e estrutura de projeto
└── docs/                   # Documentação de onboarding, governança e arquitetura
```

---

## Modelo Dual-Scope

O Kiro na MonteBravo opera com separação clara de escopos:

| Escopo | Localização | Conteúdo | Setup |
|---|---|---|---|
| **User** | `~/.kiro/` | Baseline organizacional (steering `mb--*`, hooks `mb--*`, MCP) | Uma vez por máquina |
| **Workspace** | `<projeto>/.kiro/` | Archetype da stack (steering, skills, hooks, agents, MCP) | Uma vez por projeto |

O Kiro aplica **precedência nativa**: artefatos do workspace sobrescrevem os do user-level. O baseline serve como "piso" organizacional e o archetype pode especializar qualquer diretriz.

**Vantagens:**
- Elimina duplicação do baseline em múltiplos projetos
- Um único `sync --scope user` atualiza todos os projetos
- Sem conflitos em workspaces multi-root
- Compatibilidade total com projetos no modelo legado

---

## Baseline Global vs. Archetypes vs. Powers

| Conceito | O que é | Quando usar |
|---|---|---|
| **Baseline Global** | Conjunto de steering files, hooks e políticas aplicáveis a **qualquer** projeto da organização | Sempre — é o mínimo obrigatório |
| **Archetype** | Configuração completa de Kiro para um tipo específico de stack (steering + hooks + agents + skills) | No início de um projeto novo, para partir de um template alinhado com os padrões da organização |
| **Power** | Extensão modular do Kiro com funcionalidades específicas, instalável nativamente via Kiro IDE | Quando um projeto precisa de capacidades extras sem reescrever do zero |

---

## Scripts: Bootstrap, Sync e Doctor

Os scripts operam no modelo **dual-scope**: o baseline organizacional fica na máquina (`~/.kiro/`) e o archetype da stack fica no projeto (`.kiro/`).

| Script | Finalidade |
|---|---|
| `scripts/bootstrap.sh --scope user` | Instala o baseline organizacional em `~/.kiro/` (uma vez por máquina) |
| `scripts/bootstrap.sh --scope workspace` | Configura um projeto com o archetype da stack em `.kiro/` |
| `scripts/sync.sh --scope user` | Atualiza o baseline em `~/.kiro/` com a versão mais recente |
| `scripts/sync.sh --scope workspace` | Atualiza os artefatos do archetype no projeto |
| `scripts/sync.sh --migrate-to-user-scope` | Migra projetos do modelo antigo para o dual-scope |
| `scripts/doctor.sh --scope user` | Diagnostica o baseline na máquina |
| `scripts/doctor.sh --scope workspace` | Diagnostica o archetype no projeto |
| `scripts/doctor.sh --target <caminho>` | Diagnostica ambos os escopos de uma vez |

> Para detalhes sobre migração de projetos existentes, veja `docs/governance.md`.

---

## Testes

O repositório possui uma suíte de testes para garantir a integridade das configurações:

```bash
# Executar todos os testes
./tests/run_tests.sh
```

A estrutura de testes está organizada em:

- `tests/unit/` — testes unitários
- `tests/integration/` — testes de integração
- `tests/properties/` — testes baseados em propriedades

---

## Como Usar Este Repositório

### Pré-requisitos

- Clone deste repositório localmente (ex: `~/projects/mb-kiro`)
- [Kiro IDE](https://kiro.dev) instalado
- `jq` instalado (`brew install jq` no macOS)

### Setup inicial da máquina (uma vez)

```bash
# 1. Clone este repositório
git clone git@github.com:MonteBravo/mb-kiro.git ~/projects/mb-kiro
cd ~/projects/mb-kiro

# 2. Instale o baseline organizacional na máquina
./scripts/bootstrap.sh --scope user
```

Isso configura `~/.kiro/` com as diretrizes organizacionais. Todos os projetos herdam automaticamente.

### Time novo iniciando um projeto

```bash
cd ~/projects/mb-kiro

# Execute o bootstrap informando o tipo de projeto
./scripts/bootstrap.sh --scope workspace --project-type backend-csharp --target ../meu-projeto
```

O script aplica o archetype e **registra os powers no manifest** (sem copiar arquivos).

**Instale os powers nativamente no Kiro IDE:**
- Abra o projeto no Kiro
- Abra o painel de Powers (ícone na barra lateral)
- Clique em **"Import power from a folder"**
- Aponte para o caminho exibido no terminal

**Valide a configuração:**
```bash
./scripts/doctor.sh --target ../meu-projeto
```

### Instalando e atualizando powers

Powers são instalados nativamente via Kiro IDE — os scripts **não copiam** steering files de powers para o projeto.

**Para instalar um power:**

1. Abra o painel de Powers no Kiro IDE
2. Clique em "Import power from a folder"
3. Aponte para `<seu-clone-mb-kiro>/powers/<power-name>/`
4. O power será ativado dinamicamente por keywords no prompt

**Para atualizar um power:**

1. Atualize o clone do mb-kiro:
   ```bash
   cd ~/projects/mb-kiro && git pull
   ```
2. No Kiro IDE, abra o painel de Powers e clique em **"Check for updates"**
3. O Kiro detectará e aplicará as mudanças do power

### Migrando projetos existentes (legado → dual-scope)

Projetos no modelo antigo (baseline copiado no workspace) podem migrar para o novo modelo:

```bash
# Simular antes de aplicar
./scripts/sync.sh --target ../meu-projeto --migrate-to-user-scope --dry-run

# Executar a migração
./scripts/sync.sh --target ../meu-projeto --migrate-to-user-scope

# Instalar o baseline na máquina (se ainda não fez)
./scripts/bootstrap.sh --scope user
```

A migração remove artefatos do baseline do workspace, atualiza o manifest para `baseline.scope: "user"` e é atômica (rollback automático em caso de falha). Veja `docs/governance.md` para detalhes.

### Time existente sincronizando padrões

```bash
# Atualizar baseline da máquina (afeta todos os projetos)
./scripts/sync.sh --scope user

# Atualizar archetype de um projeto específico
./scripts/sync.sh --scope workspace --target ../meu-projeto
```

### Diagnóstico

```bash
# Verificar tudo (user + workspace)
./scripts/doctor.sh --target ../meu-projeto

# Verificar apenas o baseline da máquina
./scripts/doctor.sh --scope user

# Verificar apenas o archetype do projeto
./scripts/doctor.sh --scope workspace --target ../meu-projeto
```

O doctor verifica conformidade em ambos os escopos:

- **Scope user**: baseline instalado e atualizado em `~/.kiro/`
- **Scope workspace**: archetype, manifest, powers e servidores MCP do projeto

Para cada problema detectado, o doctor exibe instruções de resolução.

Opções adicionais:
```bash
# Output em JSON para automação
./scripts/doctor.sh --target ../meu-projeto --output json

# Output detalhado com diffs
./scripts/doctor.sh --target ../meu-projeto --verbose
```

### Diretório `powers/_drafts/`

Powers que ainda não possuem funcionalidade implementada ficam em `powers/_drafts/`. Esses powers são **ignorados silenciosamente** pelos scripts (bootstrap, sync, doctor) e não devem ser instalados.

Quando um power placeholder for implementado, basta movê-lo para `powers/<power-name>/`, adicionar um `VERSION` file e garantir que o `POWER.md` possui frontmatter com keywords.

### Contribuindo com este repositório

- Abra uma issue descrevendo a mudança proposta.
- Crie um branch `feat/`, `fix/` ou `docs/` a partir de `main`.
- Abra um Pull Request e aguarde revisão de pelo menos um mantenedor.
- Versionamento segue [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH` por componente (baseline, archetype, power).

---

## Versionamento

Cada componente deste repositório evolui de forma independente usando versionamento semântico:

- `baselines/global` — versionado em `baselines/global/VERSION`
- `archetypes/<nome>` — versionado em `archetypes/<nome>/VERSION`
- `powers/<nome>` — versionado em `powers/<nome>/VERSION`

Mudanças **breaking** incrementam o `MAJOR`. Novas funcionalidades compatíveis incrementam o `MINOR`. Correções incrementam o `PATCH`.

---

## Arquivos de Relatório

Na raiz do repositório existem relatórios gerados por processos de validação e sincronização:

| Arquivo | Descrição |
|---|---|
| `adr-sync-report.md` | Relatório de sincronização de ADRs |
| `steering-adr-validation.md` | Validação de steering files contra ADRs |
| `steering-updates-summary.md` | Resumo de atualizações nos steering files |

---

## Mantenedores

> TODO: Listar os mantenedores responsáveis por este repositório.

---

*Última atualização: 2026-06 | Organização: MonteBravo*
