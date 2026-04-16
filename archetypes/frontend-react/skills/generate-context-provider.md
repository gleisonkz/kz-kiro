---
name: "Gerar Context e Provider"
description: "Cria um React Context com Provider e hook de leitura seguindo os padrões MonteBravo."
inclusion: manual
---

# Gerar Context e Provider

## Quando usar

Quando o desenvolvedor pedir para criar um Context React para compartilhar dados/configurações (tema, autenticação de sessão, configurações locais). Não usar para estado global complexo — para isso, usar Redux Toolkit.

## Inputs esperados

- **Nome do contexto** (obrigatório): nome do domínio (ex.: `Theme`, `Auth`, `Sidebar`).
- **Dados do contexto** (opcional): quais dados e ações o contexto expõe.
- **Localização** (opcional): caminho onde criar.

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Context: `PascalCase` + sufixo `Context` — `ThemeContext`, `AuthContext`.
- Provider: `PascalCase` + sufixo `Provider` — `ThemeProvider`, `AuthProvider`.
- Hook de leitura: `use` + nome — `useTheme`, `useAuth`.
- Arquivo context: `{nome}.context.tsx` (ex.: `theme.context.tsx`).
- Arquivo provider: `{nome}.provider.tsx` (ex.: `theme.provider.tsx`).
- Teste: `{nome}.provider.test.tsx`.

### Estrutura de arquivos

Providers globais ficam em `app/providers/`:

```
src/app/providers/
├── theme.context.tsx
├── theme.provider.tsx
└── theme.provider.test.tsx
```

Contextos locais de módulo ficam na slice correspondente dentro do módulo.

### Implementação (ref: stack-and-tooling.md, architecture.md)

- TypeScript strict.
- Context com valor default `null` e type guard no hook.
- Hook de leitura que lança erro se usado fora do Provider.
- Provider como componente wrapper com children.

## Exemplo de output

### `theme.context.tsx`

```tsx
import { createContext, useContext } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextValue {
  theme: Theme;
  toggleTheme: () => void;
}

export const ThemeContext = createContext<ThemeContextValue | null>(null);

export function useTheme(): ThemeContextValue {
  const context = useContext(ThemeContext);

  if (!context) {
    throw new Error('useTheme deve ser usado dentro de um ThemeProvider');
  }

  return context;
}
```

### `theme.provider.tsx`

```tsx
import { useCallback, useMemo, useState, type ReactNode } from 'react';
import { ThemeContext } from './theme.context';

type Theme = 'light' | 'dark';

interface ThemeProviderProps {
  defaultTheme?: Theme;
  children: ReactNode;
}

export function ThemeProvider({ defaultTheme = 'light', children }: ThemeProviderProps) {
  const [theme, setTheme] = useState<Theme>(defaultTheme);

  const toggleTheme = useCallback(() => {
    setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  }, []);

  const value = useMemo(() => ({ theme, toggleTheme }), [theme, toggleTheme]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}
```

### `theme.provider.test.tsx`

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import { useTheme } from './theme.context';
import { ThemeProvider } from './theme.provider';

function TestConsumer() {
  const { theme, toggleTheme } = useTheme();
  return (
    <div>
      <span data-testid="theme">{theme}</span>
      <button onClick={toggleTheme}>Toggle</button>
    </div>
  );
}

describe('ThemeProvider', () => {
  it('deve fornecer o tema padrão', () => {
    render(
      <ThemeProvider>
        <TestConsumer />
      </ThemeProvider>,
    );

    expect(screen.getByTestId('theme')).toHaveTextContent('light');
  });

  it('deve alternar o tema', async () => {
    render(
      <ThemeProvider>
        <TestConsumer />
      </ThemeProvider>,
    );

    await userEvent.click(screen.getByRole('button'));
    expect(screen.getByTestId('theme')).toHaveTextContent('dark');
  });

  it('deve lançar erro se useTheme for usado fora do Provider', () => {
    expect(() => render(<TestConsumer />)).toThrow(
      'useTheme deve ser usado dentro de um ThemeProvider',
    );
  });
});
```
