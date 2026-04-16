---
name: "Gerar Componente React"
description: "Cria um componente React seguindo os padrões MonteBravo: FSD, tipagem, testes, story e convenções de nomenclatura."
inclusion: manual
---

# Gerar Componente React

## Quando usar

Quando o desenvolvedor pedir para criar um novo componente React.

## Inputs esperados

- **Nome do componente** (obrigatório): nome em PascalCase (ex.: `PortfolioCard`, `OrderSummary`).
- **Localização** (obrigatório ou inferido): onde o componente se encaixa no FSD — segmento `ui/` de qual layer e slice (ex.: `modules/portfolio/features/portfolio-summary/ui/`, `modules/portfolio/entities/asset/ui/`, `src/shared/ui/`).
- **Composição** (opcional): se o componente deve usar o padrão de composição com namespace (ex.: `Modal.Root`, `Modal.Content`).

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Arquivo do componente: `PascalCase.tsx` (ex.: `PortfolioCard.tsx`).
- Arquivo de teste: `PascalCase.test.tsx` (ex.: `PortfolioCard.test.tsx`).
- Arquivo de story: `PascalCase.stories.tsx` (ex.: `PortfolioCard.stories.tsx`).
- Arquivo de variants (se usar cva): `pascal-case.variants.ts` (ex.: `portfolio-card.variants.ts`).

### Estrutura de arquivos (FSD)

Componentes vivem no segmento `ui/` dentro de slices FSD:

```
modules/{module}/features/{feature}/ui/
├── ComponentName.tsx
├── ComponentName.test.tsx
├── ComponentName.stories.tsx
├── component-name.variants.ts    # Opcional, se usar cva
└── index.ts                      # Re-export
```

Exemplos de localização:

- Feature de um módulo: `modules/portfolio/features/portfolio-summary/ui/PortfolioCard.tsx`
- Entity de um módulo: `modules/portfolio/entities/asset/ui/AssetBadge.tsx`
- Widget de um módulo: `modules/portfolio/widgets/portfolio-dashboard/ui/PortfolioDashboard.tsx`
- Shared global: `src/shared/ui/Button.tsx`
- Shared do módulo: `modules/portfolio/shared/ui/PortfolioIcon.tsx`

### Componente (ref: design-system.md, stack-and-tooling.md)

- React 19 com TypeScript strict.
- Props tipadas com interface `ComponentNameProps`.
- Estilização com TailwindCSS 4 e tokens semânticos (nunca hardcoded).
- Usar `cn()` ou equivalente para composição de classes condicionais.
- Exportar como named export (não default export).
- Se componente composto, usar padrão de namespace:

```tsx
export const Modal = {
  Root: ModalRoot,
  Trigger: ModalTrigger,
  Content: ModalContent,
};
```

### Acessibilidade (ref: design-system.md)

- Papel semântico correto (usar elementos HTML semânticos quando possível).
- Atributos ARIA quando necessário.
- Navegação por teclado para componentes interativos.
- Não depender apenas de cor para transmitir informação.

### Identificação para teste (ref: design-system.md — requisitos de qualidade)

- Componentes interativos devem expor `data-testid` estável.
- Identificadores não dependem de texto visível, posição ou classe CSS.

### Teste unitário (ref: stack-and-tooling.md)

- Vitest + React Testing Library.
- Padrão AAA (Arrange, Act, Assert).
- Testar renderização, interações e estados principais.
- Testar acessibilidade básica (role, label).

### Story (ref: design-system.md)

- Storybook com TypeScript.
- Story default com todos os estados relevantes.
- Usar `satisfies Meta<typeof ComponentName>` para tipagem.
- Documentar props via argTypes quando necessário.

## Exemplo de output

### `Button/Button.tsx`

```tsx
import { type ButtonHTMLAttributes } from 'react';
import { cn } from '@/shared/utils/cn';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

export function Button({
  variant = 'primary',
  size = 'md',
  className,
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded font-medium transition-colors',
        {
          'bg-primary text-white hover:bg-primary/90': variant === 'primary',
          'bg-secondary text-white hover:bg-secondary/90': variant === 'secondary',
          'bg-transparent hover:bg-muted': variant === 'ghost',
          'border border-border bg-transparent hover:bg-muted': variant === 'outline',
        },
        {
          'px-3 py-1.5 text-sm': size === 'sm',
          'px-4 py-2 text-base': size === 'md',
          'px-6 py-3 text-lg': size === 'lg',
        },
        className,
      )}
      {...props}
    >
      {children}
    </button>
  );
}
```

### `Button/Button.test.tsx`

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { Button } from './Button';

describe('Button', () => {
  it('deve renderizar com texto', () => {
    render(<Button>Clique aqui</Button>);
    expect(screen.getByRole('button', { name: 'Clique aqui' })).toBeInTheDocument();
  });

  it('deve chamar onClick ao clicar', async () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Ação</Button>);
    await userEvent.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledOnce();
  });

  it('deve estar desabilitado quando disabled', () => {
    render(<Button disabled>Desabilitado</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

### `Button/Button.stories.tsx`

```tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta = {
  title: 'Shared/Button',
  component: Button,
  tags: ['autodocs'],
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {
  args: { children: 'Button', variant: 'primary' },
};

export const Secondary: Story = {
  args: { children: 'Button', variant: 'secondary' },
};

export const Disabled: Story = {
  args: { children: 'Desabilitado', disabled: true },
};
```

### `Button/index.ts`

```ts
export { Button, type ButtonProps } from './Button';
```
