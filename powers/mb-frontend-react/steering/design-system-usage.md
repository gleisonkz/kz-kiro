---
name: "Uso do Design System"
description: "Orienta o Kiro sobre como consumir o Design System MonteBravo no dia a dia: importar componentes, usar tokens, criar variantes."
inclusion: fileMatch
fileMatchPattern: "**/*.tsx, **/*.variants.ts, **/shared/ui/**"
---

# Uso do Design System — Guia Prático

## Importando Componentes

O Design System é instalado como dependência npm:

```bash
pnpm add @monte-bravo/design-system-web
```

Importar componentes via named imports:

```tsx
import { Button, Input, Modal } from '@monte-bravo/design-system-web';
```

Nunca importar de caminhos internos do pacote — usar apenas a API pública.

## Usando Tokens

Tokens semânticos estão disponíveis via TailwindCSS. Usar classes de token em vez de valores hardcoded:

```tsx
// Correto — usa token semântico
<div className="bg-surface text-foreground p-spacing-md">

// Errado — valor hardcoded
<div className="bg-white text-gray-900 p-4">
```

### Tokens disponíveis (referência)

- Cores: `bg-primary`, `bg-secondary`, `bg-surface`, `bg-muted`, `text-foreground`, `text-muted`, `border-border`
- Spacing: `p-spacing-xs`, `p-spacing-sm`, `p-spacing-md`, `p-spacing-lg`, `p-spacing-xl`
- Typography: classes de tipografia definidas no Design System

> **Fonte de verdade para tokens**: sempre consultar o arquivo instalado localmente em `node_modules/@monte-bravo/design-system-web/dist/tokens.css`. Não usar repositório remoto ou Storybook como referência — pode haver drift entre o que está publicado e o que está de fato instalado no projeto.

## Criando Variantes com CVA

Quando um componente precisa de variantes visuais, usar `cva` (class-variance-authority):

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
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  },
);
```

```tsx
// Button.tsx
import { buttonVariants } from './button.variants';

export function Button({ variant, size, className, ...props }: ButtonProps) {
  return (
    <button className={buttonVariants({ variant, size, className })} {...props} />
  );
}
```

Arquivo de variants fica no mesmo diretório do componente: `Component.tsx` + `component.variants.ts`.

### Quando usar `cn` vs passar `className` direto no `cva`

- **Com `cva`**: passar `className` direto na chamada do `cva`. Ele já faz o merge internamente de forma eficiente, sem necessidade de `cn`.
- **Sem `cva`**: usar `cn()` para compor classes manualmente (condicionais, composição de múltiplas fontes de classes, etc.).

## Composição de Componentes

Componentes compostos usam padrão de namespace:

```tsx
import { Modal } from '@monte-bravo/design-system-web';

<Modal.Root>
  <Modal.Trigger asChild>
    <Button>Abrir</Button>
  </Modal.Trigger>
  <Modal.Content>
    <Modal.Title>Confirmação</Modal.Title>
    <Modal.Body>Tem certeza?</Modal.Body>
    <Modal.Footer>
      <Button variant="ghost">Cancelar</Button>
      <Button>Confirmar</Button>
    </Modal.Footer>
  </Modal.Content>
</Modal.Root>
```

## Contribuindo com Novos Componentes

Fluxo para adicionar componente ao Design System:

1. Proposta de Design (Figma).
2. Aprovação conjunta (DesignOps + Engenharia).
3. Implementação no repositório do Design System.
4. Testes automatizados + validação de acessibilidade.
5. Documentação no Storybook (story + casos de uso).
6. PR Review + Chromatic (visual regression).
7. Changeset para versionamento.
8. Publicação automática via CI.
9. Atualizar dependência no monorepo: `pnpm update @monte-bravo/design-system-web`.

## Atualizando o Design System

```bash
# Ver versão atual
pnpm list @monte-bravo/design-system-web

# Atualizar para última versão
pnpm update @monte-bravo/design-system-web

# Verificar changelog antes de atualizar
# Consultar o CHANGELOG.md no repositório do Design System
```

### Breaking changes

- Verificar CHANGELOG antes de atualizar major versions.
- Breaking changes têm deadline trimestral de migração.
- Componentes deprecated são documentados com guia de migração.
