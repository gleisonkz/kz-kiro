---
name: "Gerar Custom Hook"
description: "Cria um custom hook React seguindo os padrões MonteBravo: tipagem, testes e convenções de nomenclatura."
inclusion: manual
---

# Gerar Custom Hook

## Quando usar

Quando o desenvolvedor pedir para criar um novo custom hook React.

## Inputs esperados

- **Nome do hook** (obrigatório): com prefixo `use` em camelCase (ex.: `usePortfolioFilters`, `useAuthSession`).
- **Localização** (opcional): caminho onde criar. Se não informado, inferir pelo contexto (feature ou shared).
- **Descrição** (opcional): o que o hook faz.

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Prefixo obrigatório `use` em camelCase.
- Arquivo: `use-nome.hook.ts` ou `use-nome.hook.tsx` (kebab-case com sufixo `.hook`).
- Teste: `use-nome.hook.test.ts` ou `use-nome.hook.test.tsx`.
- Nome expressa comportamento, consulta ou capacidade.
- Proibidos: `useData`, `useHandler`, `useCommon`.

### Estrutura de arquivos

Dentro de uma feature ou entity FSD do módulo:

```
modules/{module}/features/{feature}/lib/
├── use-feature-filters.hook.ts
└── use-feature-filters.hook.test.ts
```

Ou no shared do módulo para hooks reutilizáveis dentro do domínio:

```
modules/{module}/shared/lib/
├── use-module-breakpoint.hook.ts
└── use-module-breakpoint.hook.test.ts
```

Ou no shared global para hooks transversais:

```
src/shared/lib/
├── use-breakpoint.hook.ts
└── use-breakpoint.hook.test.ts
```

### Implementação (ref: stack-and-tooling.md)

- TypeScript strict.
- Tipar retorno explicitamente quando não trivial.
- Tipar parâmetros com interface ou type dedicado se houver mais de 2 parâmetros.
- Exportar como named export.

### Teste (ref: stack-and-tooling.md)

- Vitest + `@testing-library/react` (renderHook).
- Padrão AAA (Arrange, Act, Assert).
- Testar estados iniciais, transições e edge cases.

## Exemplo de output

### `use-portfolio-filters.hook.ts`

```ts
import { useCallback, useState } from 'react';

interface PortfolioFilters {
  search: string;
  category: string | null;
  sortBy: 'name' | 'value' | 'performance';
}

const DEFAULT_FILTERS: PortfolioFilters = {
  search: '',
  category: null,
  sortBy: 'name',
};

export function usePortfolioFilters(initialFilters?: Partial<PortfolioFilters>) {
  const [filters, setFilters] = useState<PortfolioFilters>({
    ...DEFAULT_FILTERS,
    ...initialFilters,
  });

  const updateFilter = useCallback(
    <K extends keyof PortfolioFilters>(key: K, value: PortfolioFilters[K]) => {
      setFilters((prev) => ({ ...prev, [key]: value }));
    },
    [],
  );

  const resetFilters = useCallback(() => {
    setFilters({ ...DEFAULT_FILTERS, ...initialFilters });
  }, [initialFilters]);

  return { filters, updateFilter, resetFilters };
}
```

### `use-portfolio-filters.hook.test.ts`

```ts
import { act, renderHook } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { usePortfolioFilters } from './use-portfolio-filters.hook';

describe('usePortfolioFilters', () => {
  it('deve inicializar com filtros padrão', () => {
    const { result } = renderHook(() => usePortfolioFilters());

    expect(result.current.filters).toEqual({
      search: '',
      category: null,
      sortBy: 'name',
    });
  });

  it('deve atualizar um filtro específico', () => {
    const { result } = renderHook(() => usePortfolioFilters());

    act(() => {
      result.current.updateFilter('search', 'PETR4');
    });

    expect(result.current.filters.search).toBe('PETR4');
  });

  it('deve resetar filtros para o estado inicial', () => {
    const { result } = renderHook(() => usePortfolioFilters());

    act(() => {
      result.current.updateFilter('search', 'PETR4');
      result.current.resetFilters();
    });

    expect(result.current.filters.search).toBe('');
  });
});
```
