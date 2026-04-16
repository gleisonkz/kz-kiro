# Convenções de Nomenclatura — Frontend React

> **Steering File | Archetype: frontend-react | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos frontend React da MonteBravo.
> Ele define o padrão oficial de nomenclatura para diretórios, arquivos, símbolos de código e artefatos técnicos.
>
> Baseado em: Convenções de Nomenclatura em Aplicações e Pacotes Frontend (Confluence)

---

## Princípios Gerais

- Nomes devem ser claros, previsíveis e consistentes com a responsabilidade do artefato.
- Priorizar legibilidade, busca simples no código e baixo espaço para ambiguidade.
- Não misturar estilos de nomenclatura para o mesmo tipo de artefato.
- O nome deve refletir o artefato nomeado, não uma intenção genérica ou temporária.

### Regra de idioma

- Nomes de arquivos, pastas e símbolos de código: preferir inglês técnico para conceitos de software, APIs, componentes, hooks e convenções do ecossistema React/TypeScript.
- Português pode ser usado em documentação, textos normativos e nomes de domínio de negócio oficialmente adotados no glossário oficial.
- Não misturar português e inglês no mesmo identificador.
- Abreviações apenas quando amplamente consolidadas no ecossistema.
- Em caso de conflito: glossário oficial de domínio prevalece para conceitos de negócio.

---

## Diretórios e Arquivos

### Diretórios

- `kebab-case` sempre.
- Plural quando representam coleção homogênea: `components`, `hooks`, `pages`, `types`, `utils`, `layouts`, `providers`.
- Features: nomes curtos, específicos e orientados a domínio: `portfolio`, `orders`, `authentication`, `notifications`.
- Proibidos: `misc`, `helpers`, `common2`, `temp`, `general`.

### Aplicações e pacotes

- Apps em `apps/*`: `kebab-case`, orientado ao produto — `cliente`, `assessor`, `portal-investimentos`.
- Packages em `packages/*`: `kebab-case`, orientado à responsabilidade — `common`, `eslint-config`, `design-system`, `api-client`.

### Arquivos

- Módulos funcionais: `kebab-case` (ex.: `format-currency.ts`, `auth.api.ts`).
- Componentes React: `PascalCase` (ex.: `Button.tsx`, `PortfolioCard.tsx`).
- O nome do arquivo deve refletir o principal artefato exportado.

### Sufixos de arquivo

| Tipo | Sufixo | Exemplo |
|---|---|---|
| Página | `.page.tsx` | `orders.page.tsx` |
| API | `.api.ts` | `portfolio.api.ts` |
| Teste unitário | `.test.ts` / `.test.tsx` | `Button.test.tsx` |
| Teste E2E | `.e2e.ts` | `login.e2e.ts` |
| Story | `.stories.tsx` / `.stories.mdx` | `Button.stories.tsx` |
| Tipos | `.types.ts` | `order.types.ts` |
| Schema | `.schema.ts` | `login.schema.ts` |
| Mapper | `.mapper.ts` | `currency.mapper.ts` |
| Fixture | `.fixture.ts` | `portfolio.fixture.ts` |
| Slice (Redux) | `.slice.ts` | `portfolio.slice.ts` |
| Selectors | `.selectors.ts` | `portfolio.selectors.ts` |
| Context | `.context.tsx` | `auth.context.tsx` |
| Provider | `.provider.tsx` | `theme.provider.tsx` |
| Hook | `.hook.ts` / `.hook.tsx` | `use-portfolio.hook.ts` |

---

## Componentes React

- `PascalCase` sempre.
- Nome representa a responsabilidade da interface: `Button`, `PortfolioCard`, `OrderSummary`, `LoginForm`.
- Composição com namespace: `Modal.Root`, `Modal.Trigger`, `Modal.Content`.
- Evitar nomes vagos ou excessivamente genéricos.

---

## Hooks

- Prefixo obrigatório `use` em `camelCase`.
- Nome expressa comportamento, consulta ou capacidade: `usePortfolio`, `useOrderFilters`, `useAuthSession`, `useBreakpoint`.
- Proibidos: `useData`, `useHandler`, `useCommon`.

---

## Funções, Variáveis e Constantes

### Funções

- `camelCase`.
- Nome representa ação, transformação, cálculo ou validação: `formatCurrency`, `buildChartSeries`, `getPortfolioSummary`, `validateCpf`.

### Variáveis

- `camelCase`.

### Constantes

- Escopo local: `camelCase`.
- Exportadas e imutáveis de domínio: `SCREAMING_SNAKE_CASE` quando representam configuração estática, chave institucional ou mapa de constantes.

---

## Tipos, Interfaces, Enums e Generics

- Tipos e interfaces: `PascalCase`, sem prefixos artificiais — `User`, `PortfolioSummary`, `OrderStatus`.
- Props: sufixo `Props` — `ButtonProps`, `ModalProps`.
- Opções/parâmetros: sufixos `Options`, `Params`, `Input`, `Payload` conforme contrato.
- Respostas: sufixo `Response` quando aplicável.
- Enums: `PascalCase`, membros em `PascalCase` ou `SCREAMING_SNAKE_CASE` (consistente dentro do mesmo enum).
- Generics: nomes curtos e semânticos — `TData`, `TError`, `TValue`, `TKey`.

---

## Classes

- `PascalCase`.
- Nome representa papel explícito: `HttpClient`, `SessionStorageAdapter`, `PortfolioPresenter`.
- Proibidos: `BaseClass`, `MainService`, `DefaultManager`.

---

## Context, Provider e Store

### Context e Provider

- Context: `PascalCase` + sufixo `Context` — `ThemeContext`, `AuthContext`.
- Provider: `PascalCase` + sufixo `Provider` — `ThemeProvider`, `AuthProvider`.
- Hook de leitura: `use` + contexto — `useTheme`, `useAuth`.

### Redux (Slices, Selectors, RTK Query)

- Slices: `camelCase` orientado a domínio — `portfolioSlice`, `ordersSlice`, `authSlice`.
- Selectors: prefixo `select` — `selectPortfolio`, `selectActiveOrder`, `selectIsSubmitting`.
- Endpoints RTK Query: verbos de ação em `camelCase` — `getPortfolio`, `listOrders`, `createOrder`, `cancelOrder`.

---

## API, Clients, Services e Adapters

- Módulos de API: nomeados por recurso — `orders.api.ts`, `portfolio.api.ts`, `auth.api.ts`.
- Funções de acesso a dados: verbos coerentes — `get`, `list`, `create`, `update`, `remove`, `upload`, `download`.
- Clientes externos: sufixos `Client`, `Gateway` ou `Adapter`.

---

## Páginas, Layouts e Templates

- Páginas: `PascalCase` — `OrdersPage`, `PortfolioDetailsPage`.
- Layouts: `PascalCase` + sufixo `Layout` — `DashboardLayout`, `AuthLayout`.
- Templates: sufixo `Template` quando adotado.

---

## Testes e Automação

- Arquivos de teste refletem exatamente o artefato testado.
- Identificadores de automação: convenção única, previsível e desacoplada de texto visível, posição ou classe CSS.

---

## O que Evitar

- Nomes genéricos sem contexto: `data`, `item`, `info`, `handler`, `helper`, `service`, `manager`, `util`.
- Nomes temporários: `newFile`, `test2`, `finalVersion`, `componentUpdated`.
- Misturar singular e plural sem critério para o mesmo tipo de diretório.
- Siglas locais difíceis de entender fora do contexto imediato.
- Nomes que refletem implementação incidental em vez de responsabilidade funcional.

---

## Exemplos Válidos

| Tipo | Exemplos |
|---|---|
| Diretórios | `modules`, `shared`, `portfolio-details`, `api-client` |
| Componentes | `Button`, `PortfolioCard`, `OrdersTable` |
| Hooks | `useAuth`, `usePortfolioFilters`, `useBreakpoint` |
| Tipos | `ButtonProps`, `PortfolioSummary`, `CreateOrderPayload` |
| Arquivos | `orders.api.ts`, `portfolio.page.tsx`, `currency.mapper.ts`, `auth.context.tsx` |
| Selectors/Slices | `selectCurrentUser`, `portfolioSlice` |

---

## Referências

- [Convenções de Nomenclatura em Aplicações e Pacotes Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757628)

---

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
