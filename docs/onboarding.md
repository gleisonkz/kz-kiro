# Onboarding — Primeiros Passos com o Kiro na MonteBravo

> **Objetivo:** Guiar qualquer desenvolvedor ou time na adoção do Kiro, partindo do zero até o primeiro projeto configurado e funcionando com os padrões organizacionais.

---

## Sumário

1. [O que é o Kiro](#o-que-é-o-kiro)
2. [Pré-requisitos](#pré-requisitos)
3. [Modelo Dual-Scope](#modelo-dual-scope)
4. [Etapa 1 — Configurando a máquina (Scope User)](#etapa-1--configurando-a-máquina-scope-user)
5. [Etapa 2 — Configurando o projeto (Scope Workspace)](#etapa-2--configurando-o-projeto-scope-workspace)
6. [Entendendo o que foi instalado](#entendendo-o-que-foi-instalado)
7. [Mantendo tudo atualizado](#mantendo-tudo-atualizado)
8. [Próximos passos para o time](#próximos-passos-para-o-time)
9. [Dúvidas frequentes](#dúvidas-frequentes)

---

## O que é o Kiro

O Kiro é uma ferramenta de desenvolvimento assistido por IA que opera diretamente no fluxo de trabalho dos times de engenharia, provendo contexto inteligente, automações e steering configurável por projeto e por organização.

Na MonteBravo, o Kiro é configurado em dois níveis:

- **Nível User (máquina)** — Diretrizes organizacionais que valem para todos os projetos.
- **Nível Workspace (projeto)** — Configurações específicas da stack/tecnologia do projeto.

---

## Pré-requisitos

- [Kiro IDE](https://kiro.dev) instalado
- Acesso ao repositório `MonteBravo/mb-kiro`
- Git configurado com credenciais válidas
- `jq` instalado (`brew install jq` no macOS)

---

## Modelo Dual-Scope

O Kiro na MonteBravo opera com um modelo de **dois escopos**:

| Escopo | Localização | Conteúdo | Frequência de Setup |
|---|---|---|---|
| **User** | `~/.kiro/` | Baseline organizacional (steering, hooks, MCP) | Uma vez por máquina |
| **Workspace** | `<projeto>/.kiro/` | Archetype da stack (steering, skills, hooks, agents) | Uma vez por projeto |

**Precedência:** Artefatos do workspace têm precedência sobre o baseline user. Se um steering file existe em ambos os níveis, o Kiro usa apenas o do workspace.

```
~/.kiro/ (piso organizacional)
  ├── steering/mb--*.md          ← Baseline: princípios e políticas globais
  ├── hooks/mb--*.kiro.hook      ← Hooks organizacionais
  ├── settings/mcp.json          ← Servidores MCP globais
  └── mb-baseline-version        ← Versão do baseline instalado

<projeto>/.kiro/ (configuração da stack)
  ├── steering/*.md              ← Archetype: diretrizes da stack
  ├── skills/*.md                ← Skills especializadas
  ├── hooks/*.kiro.hook          ← Hooks do archetype
  ├── agents/*.md                ← Agents do archetype
  └── settings/mcp.json          ← Servidores MCP do archetype
```

---

## Etapa 1 — Configurando a máquina (Scope User)

> **Quando:** Primeira vez na máquina, ou após atualizar o repositório mb-kiro.

Esta etapa instala o baseline organizacional em `~/.kiro/`. Só precisa ser feita **uma vez por máquina** e todos os projetos herdam automaticamente.

```bash
# 1. Clone o repositório mb-kiro (se ainda não fez)
git clone git@github.com:MonteBravo/mb-kiro.git ~/projects/mb-kiro

# 2. Instale o baseline global na máquina
cd ~/projects/mb-kiro
./scripts/bootstrap.sh --scope user
```

**O que acontece:**

- Cria a estrutura `~/.kiro/steering/`, `~/.kiro/hooks/`, `~/.kiro/settings/`
- Copia steering files do baseline com prefixo `mb--` (ex: `mb--engineering-principles.md`)
- Copia hooks do baseline com prefixo `mb--`
- Mergeia servidores MCP organizacionais em `~/.kiro/settings/mcp.json`
- Cria `~/.kiro/mb-baseline-version` com a versão instalada

> **Nota:** Em ambientes CI, esta etapa é automaticamente ignorada (o baseline user não se aplica a pipelines).

---

## Etapa 2 — Configurando o projeto (Scope Workspace)

> **Quando:** Ao iniciar um projeto novo ou ao configurar um projeto existente com o Kiro.

Esta etapa instala o archetype específico da stack no projeto.

```bash
# Execute o bootstrap indicando o tipo de projeto e o destino
./scripts/bootstrap.sh --scope workspace --project-type backend-csharp --target ../meu-projeto
```

**Archetypes disponíveis:**

| Tipo | Descrição |
|---|---|
| `backend-csharp` | Backend em C# (.NET) |
| `bff-fastify` | BFF com Fastify (Node.js) |
| `frontend-react` | Frontend com React |
| `mobile-flutter` | Aplicativo mobile com Flutter |

**O que acontece:**

- Cria `.kiro/` no projeto com steering, skills, hooks e agents do archetype
- Gera `kiro-manifest.json` na raiz do projeto (formato v2 com `baseline.scope: "user"`)
- Gera `.kiro/settings/mcp.json` apenas com servidores do archetype
- Registra powers no manifest para instalação nativa

**Próximo passo:** Instale os powers no Kiro IDE (o terminal exibirá os caminhos).

---

## Entendendo o que foi Instalado

### No nível User (`~/.kiro/`)

| Diretório | Conteúdo |
|---|---|
| `steering/mb--*.md` | Steering files organizacionais (prefixo `mb--` = gerenciado pelo baseline) |
| `hooks/mb--*.kiro.hook` | Hooks organizacionais |
| `settings/mcp.json` | Servidores MCP da organização |
| `mb-baseline-version` | Versão do baseline instalado |

> Arquivos **sem** o prefixo `mb--` são pessoais e nunca serão tocados pelos scripts.

### No nível Workspace (`<projeto>/.kiro/`)

| Diretório | Conteúdo |
|---|---|
| `steering/*.md` | Steering files do archetype (específicos da stack) |
| `skills/*.md` | Skills do archetype |
| `hooks/*.kiro.hook` | Hooks do archetype |
| `agents/*.md` | Agents do archetype |
| `settings/mcp.json` | Servidores MCP do archetype |

### Manifest do projeto (`kiro-manifest.json`)

O manifest registra metadata do projeto, archetype e powers instalados. O campo `baseline.scope: "user"` indica que o baseline está no nível da máquina (não duplicado no workspace).

---

## Mantendo tudo Atualizado

### Atualizando o baseline (user)

```bash
cd ~/projects/mb-kiro
git pull
./scripts/sync.sh --scope user
```

Isso atualiza todos os steering files, hooks e MCP do baseline em `~/.kiro/` — todos os projetos se beneficiam automaticamente.

### Atualizando o archetype (workspace)

```bash
cd ~/projects/mb-kiro
git pull
./scripts/sync.sh --scope workspace --target ../meu-projeto
```

Isso atualiza apenas artefatos do archetype no projeto.

### Verificando conformidade

```bash
# Verificar tudo (user + workspace)
./scripts/doctor.sh --target ../meu-projeto

# Verificar apenas o baseline da máquina
./scripts/doctor.sh --scope user

# Verificar apenas o archetype do projeto
./scripts/doctor.sh --scope workspace --target ../meu-projeto
```

---

## Próximos Passos para o Time

1. Todos os membros do time executam a **Etapa 1** (bootstrap --scope user) em suas máquinas.
2. O Tech Lead executa a **Etapa 2** (bootstrap --scope workspace) para o projeto.
3. Cada membro instala os powers indicados via painel de Powers no Kiro IDE.
4. Executar `doctor.sh --target ../meu-projeto` para validar que tudo está correto.
5. Agendar uma sessão de nivelamento com o time sobre o uso do Kiro no dia a dia.

---

## Dúvidas Frequentes

**Preciso executar o bootstrap --scope user toda vez que inicio um projeto novo?**
> Não. O bootstrap user é feito **uma vez por máquina**. Novos projetos herdam o baseline automaticamente via `~/.kiro/`.

**Como atualizo o baseline de todos os projetos de uma vez?**
> Execute `sync.sh --scope user`. Como o baseline fica em `~/.kiro/`, todos os projetos se atualizam com um único comando.

**Posso customizar o archetype para o meu projeto?**
> Sim. Após o bootstrap workspace, você pode modificar os steering files em `.kiro/`. Mudanças que devem valer para todos os projetos do mesmo tipo devem ser propostas como atualização no archetype original, via PR no repositório mb-kiro.

**Meu projeto usa o modelo antigo (baseline no workspace). O que fazer?**
> Execute a migração: `./scripts/sync.sh --target ../meu-projeto --migrate-to-user-scope`. Depois instale o baseline na máquina com `./scripts/bootstrap.sh --scope user`. Veja `docs/governance.md` para detalhes do processo de migração.

**O que significa o prefixo `mb--` nos arquivos?**
> Arquivos com prefixo `mb--` em `~/.kiro/` são gerenciados pelo baseline organizacional. Eles são atualizados/removidos automaticamente pelo `sync.sh`. Seus arquivos pessoais (sem prefixo) nunca são tocados.

**Onde reporto problemas com o Kiro ou com os padrões organizacionais?**
> Abra uma issue no repositório `MonteBravo/mb-kiro` ou no canal de engenharia da organização.

---

*Documento em evolução — contribuições são bem-vindas via Pull Request.*
