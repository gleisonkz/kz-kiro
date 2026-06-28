# Criar Regras de Design System

## Visão Geral

Workflow para gerar e manter regras de design system específicas do projeto, que orientam a tradução consistente de designs Figma para código. No contexto MonteBravo, essas regras complementam os steerings existentes com configurações específicas por aplicação.

## Quando Usar

- Configurando uma nova aplicação no monorepo que vai consumir designs do Figma
- Atualizando convenções após mudanças no Design System
- Refinando regras que não estão gerando código consistente

## Workflow

### Passo 1: Gerar Template Base

Executar a tool do Figma MCP:

```
create_design_system_rules(clientLanguages="typescript", clientFrameworks="react")
```

Isso retorna um template base e orientações para personalização.

### Passo 2: Analisar o Projeto

Identificar as configurações específicas da aplicação:

- **Qual app?** (`apps/web-cliente`, `apps/web-assessor`, etc.)
- **Tokens customizados?** Verificar se a app tem extensões de tema além dos tokens padrão
- **Componentes locais?** Listar componentes em `src/shared/ui/` que complementam o DS
- **Módulos existentes?** Entender quais bounded contexts existem

### Passo 3: Gerar Regras Contextualizadas

As regras devem ser salvas como steering file em `.kiro/steering/` do projeto (não em `CLAUDE.md`).

Estrutura recomendada do arquivo:

```markdown
---
inclusion: fileMatch
fileMatchPattern: "**/*.tsx, **/*.variants.ts"
---

# Regras de Design System — [Nome da App]

## Componentes Disponíveis

### Design System (`@monte-bravo/design-system-web`)
- [Listar componentes disponíveis no DS]

### Componentes Locais (`src/shared/ui/`)
- [Listar componentes locais reutilizáveis]

## Tokens do Projeto

### Cores
- [Listar tokens de cor semânticos disponíveis]

### Spacing
- [Listar escala de spacing]

### Tipografia
- [Listar classes tipográficas]

## Regras de Tradução Figma → Código

- Output do Figma (React + Tailwind) é referência de design, não código final
- Substituir classes Tailwind genéricas por tokens semânticos do projeto
- Reutilizar componentes do DS antes de criar novos
- Variantes visuais via CVA (`component.variants.ts`)
- Nunca hardcodar valores — sempre tokens

## Convenções da App

- [Convenções específicas desta aplicação]
```

### Passo 4: Salvar e Validar

1. Salvar o arquivo em `.kiro/steering/design-system-rules.md` do projeto
2. Testar implementando um componente simples do Figma
3. Verificar se as regras estão sendo seguidas corretamente
4. Iterar conforme necessário

## Notas

- Este workflow complementa os steerings do archetype `frontend-react` (que já definem arquitetura, stack e convenções globais)
- As regras geradas aqui são **específicas por aplicação** — cada app pode ter configurações diferentes
- Manter as regras atualizadas quando o Design System receber major updates
