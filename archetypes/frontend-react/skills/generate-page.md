---
name: "Gerar Página"
description: "Cria uma página React (Vite SPA) seguindo os padrões MonteBravo: organização por feature, tipagem e convenções."
inclusion: manual
---

# Gerar Página

## Quando usar

Quando o desenvolvedor pedir para criar uma nova página na aplicação.

## Inputs esperados

- **Nome da página** (obrigatório): nome descritivo (ex.: `OrdersPage`, `PortfolioDetailsPage`).
- **Feature** (opcional): a qual feature/domínio pertence.
- **Rota** (opcional): path da rota (ex.: `/orders`, `/portfolio/:id`).

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Componente de página: `PascalCase` com sufixo `Page` — `OrdersPage`, `PortfolioDetailsPage`.
- Arquivo: `{nome}.page.tsx` (ex.: `orders.page.tsx`).
- Layout: `PascalCase` com sufixo `Layout` — `DashboardLayout`, `AuthLayout`.

### Estrutura de arquivos

Dentro de um módulo FSD:

```
modules/{module}/pages/
├── {page-name}/
│   ├── index.ts              # Public API da page
│   └── ui/
│       ├── PageName.tsx
│       └── PageName.test.tsx
```

### Implementação (ref: architecture.md, stack-and-tooling.md)

- Página é um componente que orquestra a feature — conecta estado, dados e componentes.
- Lógica de negócio em hooks e slices, não na página.
- Dados via RTK Query hooks.
- Estado local mínimo na página.
- Tratar estados: loading, error, empty e success.
- Exportar como named export.

### Acessibilidade

- Título da página definido (via `document.title` ou hook dedicado).
- Landmarks semânticos (`<main>`, `<nav>`, `<header>`).
- Heading hierarchy correta (`h1` → `h2` → `h3`).

## Exemplo de output

### `orders.page.tsx`

```tsx
import { useGetOrdersQuery } from '../api/orders.api';
import { OrdersTable } from '../components/OrdersTable';
import { OrdersFilters } from '../components/OrdersFilters';
import { useOrderFilters } from '../hooks/use-order-filters.hook';
import { PageHeader } from '@/shared/components/PageHeader';
import { ErrorState } from '@/shared/components/ErrorState';
import { LoadingState } from '@/shared/components/LoadingState';
import { EmptyState } from '@/shared/components/EmptyState';

export function OrdersPage() {
  const { filters, updateFilter, resetFilters } = useOrderFilters();
  const { data: orders, isLoading, error } = useGetOrdersQuery(filters);

  if (isLoading) {
    return <LoadingState message="Carregando ordens..." />;
  }

  if (error) {
    return <ErrorState message="Erro ao carregar ordens." onRetry={() => {}} />;
  }

  if (!orders?.length) {
    return <EmptyState message="Nenhuma ordem encontrada." />;
  }

  return (
    <main>
      <PageHeader title="Ordens" />
      <OrdersFilters
        filters={filters}
        onFilterChange={updateFilter}
        onReset={resetFilters}
      />
      <OrdersTable orders={orders} />
    </main>
  );
}
```
