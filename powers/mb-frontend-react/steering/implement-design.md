# Implementar Design do Figma

## Visão Geral

Workflow estruturado para traduzir designs do Figma em código production-ready seguindo as convenções da MonteBravo: Feature-Sliced Design, TailwindCSS 4 com tokens semânticos, CVA para variantes, e reutilização do Design System (`@monte-bravo/design-system-web`).

## Pré-requisitos

- Figma MCP server conectado e acessível
- URL do Figma no formato: `https://figma.com/design/:fileKey/:fileName?node-id=1-2`
- Design System instalado no projeto (`@monte-bravo/design-system-web`)

## Workflow Obrigatório

**Seguir estes passos em ordem. Não pular etapas.**

### Passo 1: Extrair File Key e Node ID

A partir da URL do Figma, extrair:

- **File key:** segmento após `/design/`
- **Node ID:** valor do parâmetro `node-id`

**Exemplo:**
- URL: `https://figma.com/design/kL9xQn2VwM8pYrTb4ZcHjF/DesignSystem?node-id=42-15`
- File key: `kL9xQn2VwM8pYrTb4ZcHjF`
- Node ID: `42-15`

### Passo 2: Buscar Contexto do Design

Executar `get_design_context` com file key e node ID.

```
get_design_context(fileKey=":fileKey", nodeId="1-2")
```

Retorna: layout (Auto Layout, constraints, sizing), tipografia, cores/tokens, estrutura de componentes, spacing e padding.

**Se a resposta for truncada:**
1. Executar `get_metadata(fileKey=":fileKey", nodeId="1-2")` para obter o mapa de nodes
2. Identificar os child nodes necessários
3. Buscar individualmente com `get_design_context`

### Passo 3: Capturar Referência Visual

```
get_screenshot(fileKey=":fileKey", nodeId="1-2")
```

Este screenshot é a fonte de verdade para validação visual. Mantê-lo acessível durante toda a implementação.

### Passo 4: Baixar Assets

Baixar imagens, ícones e SVGs retornados pelo Figma MCP.

**Regras de assets:**
- Se o Figma MCP retornar uma URL `localhost` para imagem/SVG, usar diretamente
- **NÃO** importar pacotes de ícones novos — todos os assets devem vir do payload do Figma
- **NÃO** criar placeholders se uma URL localhost foi fornecida
- Armazenar assets baixados em `src/shared/assets/` ou no diretório de assets do módulo

### Passo 5: Traduzir para Convenções MonteBravo

Esta é a etapa mais importante. O output do Figma (geralmente React + Tailwind genérico) deve ser traduzido para as convenções do projeto.

#### Design System primeiro

Antes de criar qualquer componente novo, verificar se já existe no Design System:

```tsx
// Verificar se o componente existe no DS
import { Button, Input, Modal } from '@monte-bravo/design-system-web';
```

Se o componente existe no `@monte-bravo/design-system-web`, **usar ele**. Não recriar.

#### Tokens semânticos (obrigatório)

Nunca usar valores hardcoded. Usar tokens semânticos via TailwindCSS:

```tsx
// CORRETO — token semântico
<div className="bg-surface text-foreground p-spacing-md">

// ERRADO — valor hardcoded
<div className="bg-white text-gray-900 p-4">
```

Tokens disponíveis:
- Cores: `bg-primary`, `bg-secondary`, `bg-surface`, `bg-muted`, `text-foreground`, `text-muted`, `border-border`
- Spacing: `p-spacing-xs`, `p-spacing-sm`, `p-spacing-md`, `p-spacing-lg`, `p-spacing-xl`
- Tipografia: classes definidas no Design System

> Fonte de verdade para tokens: `node_modules/@monte-bravo/design-system-web/dist/tokens.css`

#### Variantes com CVA

Quando o componente tem variantes visuais (tamanhos, estilos), usar `cva`:

```tsx
// button.variants.ts
import { cva } from 'class-variance-authority';

export const buttonVariants = cva(
  'rounded font-medium transition-colors',
  {
    variants: {
      variant: {
        primary: 'bg-primary text-white hover:bg-primary/90',
        secondary: 'bg-secondary text-white hover:bg-secondary/90',
        ghost: 'bg-transparent hover:bg-muted',
      },
      size: {
        sm: 'px-3 py-1.5 text-sm',
        md: 'px-4 py-2 text-base',
        lg: 'px-6 py-3 text-lg',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  },
);
```

Arquivo de variants no mesmo diretório do componente: `Component.tsx` + `component.variants.ts`.

#### Organização de arquivos (FSD)

Onde colocar o componente implementado:

| Tipo | Local |
|------|-------|
| Componente reutilizável global | `src/shared/ui/` |
| Componente de feature específica | `src/modules/<module>/features/<feature>/ui/` |
| Widget (bloco grande autossuficiente) | `src/modules/<module>/widgets/<widget>/ui/` |
| Página | `src/modules/<module>/pages/<page>/ui/` |

#### Estado e dados

- Estado global de domínio: Redux Toolkit (slice no segmento `model/`)
- Dados assíncronos: RTK Query (no segmento `api/`)
- Estado local de UI: `useState`/`useReducer`
- Não usar React Context para estado global de domínio

### Passo 6: Garantir Fidelidade Visual 1:1

Validar contra o screenshot do Passo 3:

- Layout (spacing, alinhamento, sizing)
- Tipografia (fonte, tamanho, peso, line-height)
- Cores — devem ser exatas (via tokens)
- Estados interativos (hover, active, disabled, focus)
- Comportamento responsivo conforme constraints do Figma
- Assets renderizando corretamente
- Acessibilidade (WCAG 2.1 AA): roles, labels, navegação por teclado

### Passo 7: Validação Final

Antes de marcar como completo:

- [ ] Componentes do DS reutilizados onde possível
- [ ] Nenhum valor hardcoded — tudo via tokens
- [ ] Variants extraídas para `.variants.ts` quando aplicável
- [ ] Arquivo no diretório correto conforme FSD
- [ ] Props tipadas com TypeScript
- [ ] Acessibilidade atendida (roles, labels, keyboard nav)
- [ ] Visual 1:1 com screenshot do Figma

## Regras de Implementação

### Prioridades (em ordem)

1. Reutilizar componente do Design System (`@monte-bravo/design-system-web`)
2. Estender componente existente com nova variante
3. Criar componente novo seguindo as convenções

### Proibições

- **NÃO** usar CSS Modules, styled-components ou Emotion
- **NÃO** usar Zustand, TanStack Query ou Axios direto
- **NÃO** criar componentes em `src/components/` (não existe esse diretório na arquitetura)
- **NÃO** usar CommonJS (`require`/`module.exports`)
- **NÃO** hardcodar cores, spacing ou tipografia

### Composição de componentes

Componentes compostos usam padrão de namespace:

```tsx
<Modal.Root>
  <Modal.Trigger asChild>
    <Button>Abrir</Button>
  </Modal.Trigger>
  <Modal.Content>
    <Modal.Title>Título</Modal.Title>
    <Modal.Body>Conteúdo</Modal.Body>
  </Modal.Content>
</Modal.Root>
```

## Problemas Comuns

### Output do Figma muito grande/truncado

Usar `get_metadata` para obter estrutura, depois buscar nodes específicos individualmente.

### Tokens do projeto diferem do Figma

Preferir tokens do projeto para consistência. Ajustar spacing/sizing minimamente para manter fidelidade visual.

### Conflito entre DS existente e design novo

Se o design pede algo que o DS não suporta, implementar como componente local e abrir issue para avaliar inclusão no DS.
