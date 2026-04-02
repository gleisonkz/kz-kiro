# Steering — Archetype Frontend React/Next.js

> **Steering File | Archetype: frontend-react-next | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos que utilizam o archetype frontend-react-next.
> Ele complementa o baseline global com diretrizes específicas para projetos React/Next.js.

---

## Propósito deste Arquivo

Este steering file define as diretrizes específicas para projetos frontend construídos com React e Next.js na MonteBravo. O Kiro deve usar este contexto ao:

- Sugerir estrutura de pastas e componentes React/Next.js
- Revisar código TypeScript/React
- Propor abordagens para problemas comuns de frontend
- Gerar scaffolding de pages, components, hooks e contexts

---

## Stack Padrão

> TODO: Definir a stack completa e versões mínimas para projetos frontend.

| Tecnologia | Versão Mínima | Obrigatório | Observação |
|---|---|---|---|
| Node.js | TODO | Sim | LTS mais recente |
| React | TODO | Sim | TODO |
| Next.js | TODO | Sim | App Router preferido |
| TypeScript | TODO | Sim | Strict mode ativado |
| Gerenciador de estado | TODO | Depende | TODO (ex.: Zustand, Redux Toolkit, Jotai) |
| Data fetching | TODO | Sim | TODO (ex.: TanStack Query, SWR) |
| Estilização | TODO | Sim | TODO (ex.: Tailwind CSS, CSS Modules, Styled Components) |
| Design System | TODO | Depende | TODO |
| Formulários | TODO | Depende | TODO (ex.: React Hook Form + Zod) |
| Testes | Jest + Testing Library | Sim | Unit + e2e (Playwright/Cypress) |
| Linter | ESLint + Prettier | Sim | Config compartilhada via TODO |

---

## Estrutura de Pastas Padrão

> TODO: Definir a estrutura de pastas padrão para projetos Next.js da organização.

```
src/
├── app/                     # App Router (Next.js 13+)
│   ├── layout.tsx           # Root layout
│   ├── page.tsx             # Home page
│   └── [routes]/            # Rotas da aplicação
├── components/              # Componentes reutilizáveis
│   ├── ui/                  # Componentes de UI genéricos
│   └── [feature]/           # Componentes de feature específica
├── hooks/                   # Custom hooks reutilizáveis
├── lib/                     # Utilitários, helpers, configs
├── services/                # Camada de acesso a APIs externas
├── store/                   # Gerenciamento de estado global
├── types/                   # Tipos e interfaces TypeScript
└── styles/                  # Estilos globais
```

---

## Padrões de Código

> TODO: Detalhar os padrões de código específicos para React/Next.js.

### Componentes

- Preferir **function components** com hooks.
- Usar **TypeScript** para todos os componentes com props tipadas.
- TODO: Definir padrão de nomenclatura de componentes.

### Server vs. Client Components (Next.js App Router)

- TODO: Definir as diretrizes de quando usar Server Components vs. Client Components.
- Preferir Server Components por padrão; usar `'use client'` apenas quando necessário.

### Gerenciamento de Estado

- TODO: Definir o padrão de gerenciamento de estado local vs. global.

### Data Fetching

- TODO: Definir os padrões de data fetching, cache e revalidação.

---

## Padrões de Teste

> TODO: Definir os padrões de teste para projetos React/Next.js.

- Cobertura mínima: TODO%
- Testes unitários para hooks customizados e utilitários.
- Testes de componente com React Testing Library.
- Testes e2e com TODO (ex.: Playwright, Cypress) para fluxos críticos.

---

## Performance e Acessibilidade

> TODO: Definir os padrões mínimos de performance (Core Web Vitals) e acessibilidade (WCAG).

- Core Web Vitals: LCP < TODO ms, FID < TODO ms, CLS < TODO.
- Acessibilidade: WCAG TODO nível TODO.

---

## O que o Kiro Deve Verificar

Ao analisar código React/Next.js, o Kiro deve verificar:

- [ ] Componentes com props tipadas corretamente.
- [ ] Ausência de uso desnecessário de `'use client'`.
- [ ] Validação de formulários com schema tipado.
- [ ] Tratamento adequado de estados de loading e erro.
- [ ] Ausência de hard-coded credentials ou URLs de ambiente.
- [ ] Cobertura de testes adequada.
- [ ] Acessibilidade básica (alt text, aria-labels, etc.).

---

## Referências

> TODO: Adicionar links para documentação oficial do Next.js, guias internos e exemplos.

---

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
