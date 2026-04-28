# Arquitetura — Estrutura e Decisões de Design do mb-kiro

> **Objetivo:** Documentar a arquitetura do repositório mb-kiro, as decisões de design tomadas e as razões por trás de cada escolha estrutural.

---

## Sumário

1. [Visão Geral](#visão-geral)
2. [Componentes Principais](#componentes-principais)
3. [Baseline Global](#baseline-global)
4. [Archetypes](#archetypes)
5. [Powers](#powers)
6. [Scripts de Automação](#scripts-de-automação)
7. [Manifesto de Projeto](#manifesto-de-projeto)
8. [Decisões de Design](#decisões-de-design)
9. [Diagrama de Dependências](#diagrama-de-dependências)
10. [Evolução Futura](#evolução-futura)

---

## Visão Geral

O `mb-kiro` é um repositório de plataforma — ele não contém código de produto, mas provê a infraestrutura de configuração e padrões que todos os projetos de produto consomem. A metáfora é a de um **"cookiecutter organizacional"** para configurações Kiro.

```
Projeto de Produto
       │
       ▼
  kiro-manifest.json ──► baseline global (versionado)
       │
       ├──► archetype (versionado por stack)
       │
       └──► powers (versionados individualmente)
```

---

## Componentes Principais

### `baselines/global/`

Contém os **steering files globais** — documentos que o Kiro injeta como contexto em todas as interações, independentemente do projeto. São as "regras da casa" que valem para todos.

Estrutura:
```
baselines/global/
└── steering/
    ├── engineering-principles.md     # Princípios de engenharia
    ├── security-baseline.md          # Diretrizes de segurança
    ├── specs-policy.md               # Política de especificações
    └── documentation-baseline.md    # Padrão de documentação
```

### `archetypes/`

Templates completos de configuração Kiro por tipo de stack. Um archetype inclui steering files específicos da stack, hooks, agents e skills pré-configurados.

### `powers/`

Extensões modulares do Kiro instaláveis em qualquer projeto. Cada power é um pacote autocontido com seu próprio `POWER.md`, `mcp.json` e steering files.

### `scripts/`

Ferramentas de linha de comando para operações do ciclo de vida: bootstrap, sync e doctor.

---

## Baseline Global

O baseline global representa o **mínimo obrigatório** para qualquer projeto da organização. Ele é versionado de forma independente e qualquer mudança passa pelo processo formal de governança.

### Steering Files do Baseline

| Arquivo | Propósito |
|---|---|
| `engineering-principles.md` | Princípios de engenharia que guiam decisões técnicas |
| `security-baseline.md` | Requisitos mínimos de segurança para qualquer projeto |
| `specs-policy.md` | Como escrever e manter especificações de produto/técnicas |
| `documentation-baseline.md` | Padrão de documentação esperado em todos os projetos |

---

## Archetypes

Um archetype é um "pacote de configuração Kiro" para um tipo específico de projeto. Ele deve ser aplicado **uma única vez** no início do projeto, via `bootstrap.sh`.

### Estrutura Interna de um Archetype

```
archetypes/<nome>/
├── steering/    # Steering files específicos desta stack
├── hooks/       # Hooks do Kiro para esta stack
├── agents/      # Agents customizados para esta stack
└── skills/      # Skills customizadas para esta stack
```

### Archetypes Disponíveis

| Archetype | Stack | Status |
|---|---|---|
| `backend-nest` | NestJS + TypeScript | Em desenvolvimento |
| `frontend-react` | React + Next.js + TypeScript | Em desenvolvimento |
| `mobile-flutter` | Flutter + Dart (Clean Architecture + Riverpod) | Em desenvolvimento |

---

## Powers

Powers são extensões modulares que podem ser instaladas em **qualquer projeto**, independentemente do archetype. Eles estendem as capacidades do Kiro com funcionalidades específicas.

### Powers Disponíveis

| Power | Propósito | Status |
|---|---|---|
| `mb-kiro-manager` | Gerenciamento central de instalação e atualização dos padrões Kiro | Em desenvolvimento |
| `mb-backend-nest` | Capacidades Kiro específicas para projetos NestJS | Em desenvolvimento |
| `mb-frontend-react` | Capacidades Kiro específicas para projetos React/Next.js | Em desenvolvimento |
| `mb-mobile-flutter` | Capacidades Kiro específicas para projetos Flutter mobile | Em desenvolvimento |
| `mb-monorepo-nx` | Capacidades Kiro para monorepos com Nx | Em desenvolvimento |

### Estrutura Interna de um Power

```
powers/<nome>/
├── POWER.md     # Documentação e instruções de instalação do power
├── mcp.json     # Configuração MCP do power (servidores, ferramentas)
└── steering/    # Steering files específicos deste power
```

---

## Scripts de Automação

### `bootstrap.sh`

Responsável por:
1. Validar pré-requisitos do ambiente.
2. Aplicar o baseline global no projeto destino.
3. Aplicar o archetype correspondente ao tipo de projeto.
4. Instalar os powers solicitados.
5. Gerar o `kiro-manifest.json` no projeto.

### `sync.sh`

Responsável por:
1. Ler o `kiro-manifest.json` do projeto.
2. Verificar versões instaladas vs. versões disponíveis.
3. Atualizar componentes desatualizados.
4. Registrar o histórico de sincronização.

### `doctor.sh`

Responsável por:
1. Verificar se o `kiro-manifest.json` existe e está válido.
2. Verificar se todos os componentes declarados estão presentes.
3. Detectar steering files ausentes ou desatualizados.
4. Produzir um relatório de saúde do projeto.

---

## Manifesto de Projeto

Cada projeto que usa os padrões mb-kiro deve ter um `kiro-manifest.json` na raiz com:
- Versão do baseline global instalado.
- Archetype utilizado e sua versão.
- Lista de powers instalados com versões.
- Exceções aprovadas ao baseline.

Veja `examples/kiro-manifest.example.json` para um exemplo completo.

---

## Decisões de Design

### Por que um repositório separado para padrões Kiro?

> Centralizar os padrões evita duplicação, facilita auditoria e permite evolução coordenada sem acoplamento aos repositórios de produto.

### Por que versionamento semântico por componente?

> Permite que projetos atualizem componentes de forma seletiva e rastreável, sem risco de mudanças breaking inesperadas.

### Por que scripts bash em vez de uma ferramenta mais sofisticada?

> TODO: Documentar a decisão aqui. Considerar se scripts bash são suficientes a longo prazo ou se uma CLI dedicada seria mais adequada.

---

## Diagrama de Dependências

> TODO: Adicionar diagrama visual mostrando a relação entre baseline, archetypes, powers e projetos de produto.

---

## Evolução Futura

> TODO: Documentar o roadmap de evolução da arquitetura, incluindo:
> - Kiro Registry para distribuição de powers
> - CLI dedicada para substituir os scripts bash
> - Integração com pipelines de CI/CD
> - Suporte a múltiplos baselines (ex.: por área de negócio)

---

*Documento em evolução — contribuições são bem-vindas via Pull Request.*
