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

## Baseline Global vs. Archetypes vs. Powers

| Conceito | O que é | Quando usar |
|---|---|---|
| **Baseline Global** | Conjunto de steering files, hooks e políticas aplicáveis a **qualquer** projeto da organização | Sempre — é o mínimo obrigatório |
| **Archetype** | Configuração completa de Kiro para um tipo específico de stack (steering + hooks + agents + skills) | No início de um projeto novo, para partir de um template alinhado com os padrões da organização |
| **Power** | Extensão modular do Kiro com funcionalidades específicas, instalável nativamente via Kiro IDE | Quando um projeto precisa de capacidades extras sem reescrever do zero |

---

## Scripts: Bootstrap, Sync e Doctor

| Script | Finalidade |
|---|---|
| `scripts/bootstrap.sh` | Configura um projeto novo com o archetype, baseline e registra powers no manifest |
| `scripts/sync.sh` | Atualiza um projeto existente com a versão mais recente do baseline/archetype/powers |
| `scripts/sync.sh --migrate-powers` | Migra powers legados (steering copiado) para instalação nativa do Kiro |
| `scripts/doctor.sh` | Diagnostica o estado atual do Kiro em um projeto e aponta inconsistências |

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

### Time novo iniciando um projeto

1. Clone este repositório localmente (se ainda não fez):
   ```bash
   git clone git@github.com:MonteBravo/mb-kiro.git ~/projects/mb-kiro
   ```

2. Execute o bootstrap informando o tipo de projeto:
   ```bash
   ./scripts/bootstrap.sh --project-type frontend-react --target ../meu-projeto
   ```

3. O script aplica o baseline + archetype e **registra os powers no manifest** (sem copiar arquivos).

4. **Instale os powers nativamente no Kiro IDE:**
   - Abra o projeto no Kiro
   - Abra o painel de Powers (ícone na barra lateral)
   - Clique em **"Import power from a folder"**
   - Aponte para o caminho exibido no terminal, ex:
     ```
     ~/projects/mb-kiro/powers/mb-frontend-react/
     ```
   - Repita para cada power listado no output do bootstrap

5. Valide a configuração:
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

### Migrando projetos existentes (legado → nativo)

Projetos que usavam o modelo antigo (steering files copiados para `.kiro/steering/powers/`) podem migrar para a instalação nativa:

```bash
./scripts/sync.sh --target ../meu-projeto --migrate-powers
```

O que a migração faz para cada power:
1. Cria backup em `.kiro/.migration-backup/<power>/`
2. Remove os steering files legados de `.kiro/steering/powers/<power>/`
3. Remove os MCP servers do power do `.kiro/settings/mcp.json` do projeto
4. Atualiza o manifest com `installation_method: "native"`

Após a migração, instale os powers via "Import power from a folder" no Kiro IDE (instruções exibidas no terminal).

Em caso de falha, o backup é restaurado automaticamente. É possível simular antes com `--dry-run`:

```bash
./scripts/sync.sh --target ../meu-projeto --migrate-powers --dry-run
```

### Time existente sincronizando padrões

```bash
./scripts/sync.sh --target ../meu-projeto
```

O sync opera em **dual-mode** para powers:

| Situação | Comportamento |
|---|---|
| Power com `installation_method: "native"` | Compara versão e avisa se há atualização disponível |
| Power com `installation_method: "legacy"` | Executa sync legado + avisa para migrar |
| Power movido para `_drafts/` | Remove referência do manifest automaticamente |

### Diagnóstico de um projeto

```bash
./scripts/doctor.sh --target ../meu-projeto
```

O doctor verifica o estado de conformidade do Kiro no projeto, incluindo:

- **Manifest**: existência e validade do `kiro-manifest.json`
- **Baseline**: steering files presentes e atualizados
- **Archetype**: hooks, skills e steerings do archetype aplicados
- **Powers**: validação de cada power declarado no manifest:
  - Existência do power no repositório mb-kiro (não está em `_drafts/`)
  - POWER.md com frontmatter válido e keywords (obrigatórias para ativação dinâmica)
  - Versão atualizada (compara manifest vs `VERSION` file)
  - Detecção de instalação legada residual (steering em `.kiro/steering/powers/`)
  - Detecção de instalação duplicada (nativo + legado simultâneo)

Para cada problema detectado, o doctor exibe instruções de resolução e links para o wiki Confluence de troubleshooting.

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
