# Arquitetura de Aplicações Frontend

> **Steering File | Archetype: frontend-react | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos frontend React da MonteBravo.
> Ele define a arquitetura interna das aplicações, organização modular e fronteiras arquiteturais.
>
> Baseado em: ADR-0003 (Monolito Modular), ADR-0011 (Arquitetura das Aplicações Frontend), RFC-0003, RFC-0011

---

## Arquitetura Macro: Monolito Modular

As aplicações frontend da MonteBravo seguem a arquitetura de **monolito modular** (ADR-0003).

### Quando reavaliar microfrontends

- Crescimento consolidado de 5+ squads autônomas.
- Gargalos recorrentes e documentados nos fluxos de entrega.
- Necessidade frequente de releases totalmente independentes por domínio.
- Conflitos constantes de merge e coordenação entre squads.
- Custo de coordenação supera o custo de gestão de microfrontends.

---

## Arquitetura Interna: Módulos + Feature-Sliced Design (FSD)

A arquitetura interna opera em duas camadas complementares (ADR-0011):

1. **Camada de módulos**: define as fronteiras macro de domínio. Cada módulo é um bounded context frontend.
2. **FSD dentro de cada módulo**: define a organização interna por responsabilidade e granularidade.

**Módulos definem fronteiras de domínio. FSD define organização interna.**

### Estrutura de referência

```
src/
  app/                        # Entrypoint, providers globais, rotas, store, estilos
    entrypoint/
    providers/
    routes/
    store/
    styles/
  modules/                    # Bounded contexts de negócio
    <module-name>/
      app/                    # Setup específico do módulo (se necessário)
      pages/                  # Páginas e telas do módulo
      widgets/                # Blocos grandes e autossuficientes de UI
      features/               # Interações reutilizáveis com valor para o usuário
      entities/               # Entidades de negócio do domínio
      shared/                 # Capacidades reutilizáveis dentro do módulo
      index.ts                # API pública do módulo
  shared/                     # Recursos transversais globais
    ui/
    api/
    lib/
    config/
```

### Exemplos de módulos

- `modules/portfolio/` → gestão de carteira, posições, rentabilidade
- `modules/trading/` → ordens, execução, book de ofertas
- `modules/onboarding/` → cadastro, KYC, abertura de conta
- `modules/profile/` → dados pessoais, preferências, documentos

---

## Definição de Módulo

Um módulo é um **bounded context frontend**, não apenas um agrupamento de arquivos.

Um módulo normalmente:
- possui responsabilidade de negócio clara
- concentra fluxos relacionados entre si
- pode conter pages, widgets, features, entities e estado próprios
- possui contratos de entrada e saída bem definidos
- pode, no futuro, ser candidato à extração para microfrontend

### Critérios para identificar um módulo

- Possui vocabulário de negócio próprio.
- Concentra um fluxo funcional completo ou conjunto de fluxos intimamente relacionados.
- Possui relevância arquitetural no produto.
- Pode evoluir com relativa independência.
- Exige fronteiras explícitas para minimizar dependências cruzadas.

---

## Feature-Sliced Design (FSD) dentro do Módulo

Layers oficiais adotadas:

| Layer | Propósito |
|---|---|
| `app/` | Entrypoints, providers, rotas, store global, estilos globais |
| `pages/` | Páginas e telas da aplicação |
| `widgets/` | Blocos grandes e autossuficientes de UI |
| `features/` | Interações reutilizáveis com valor para o usuário |
| `entities/` | Entidades de negócio do domínio |
| `shared/` | Capacidades reutilizáveis e transversais |

`processes/` não é adotada (deprecated na documentação oficial).

As layers `app/` e `shared/` não possuem slices. As demais são organizadas em slices de domínio e segmentos por propósito técnico: `ui`, `api`, `model`, `lib`, `config`.

### Regras de imports do FSD

- Imports só podem ocorrer de uma layer para outra estritamente abaixo.
- Slices da mesma layer não devem depender umas das outras.
- Consumo entre slices deve ocorrer via public API (`index.ts`), não por imports diretos da estrutura interna.

---

## Regras de Fronteira entre Módulos

- Módulos não devem depender de implementações internas de outros módulos.
- Integrações entre módulos devem ocorrer apenas por contratos explícitos.
- Imports profundos entre módulos devem ser evitados.
- Detalhes internos de um módulo não devem vazar para a aplicação inteira.
- Um módulo deve ser consumido como unidade, não como coleção aberta de arquivos.
- Dependências entre módulos devem ser raras, intencionais e visíveis.

### API pública do módulo

Todo módulo deve possuir uma API pública explícita via `index.ts`:
- Ponto oficial de consumo externo do módulo.
- Reforça encapsulamento e impede acoplamento estrutural.
- Facilita futura extração para microfrontend.

---

## Shared Global vs Shared do Módulo

### Shared global deve conter apenas:
- Recursos técnicos realmente transversais.
- Utilitários genéricos.
- Infraestrutura comum.
- Componentes visuais neutros (ou referências ao Design System).
- Abstrações que não pertençam a nenhum domínio específico.

### Shared do módulo deve conter:
- Recursos reutilizáveis apenas dentro daquele domínio.
- Abstrações que ainda não são globais.
- Elementos internos que não devem ser promovidos prematuramente.

**Regra de decisão:** Se um recurso pertence claramente a um domínio, ele deve permanecer dentro do módulo.

> Componentes reutilizados entre aplicações devem ser criados no Design System. Código reutilizado entre aplicações deve ser extraído para pacotes compartilhados.

---

## Gerenciamento de Estado

### Redux Toolkit + RTK Query

- Store global centralizado em `app/store/`.
- Estado de domínio localizado no segmento `model/` dentro do módulo correspondente.
- Estado transversal entre módulos deve ser tratado com critério e justificativa explícita.
- Selectors para leitura de estado desacoplada da UI.
- RTK Query para cache, revalidação e ciclo de vida de dados assíncronos.

### Estrutura de estado

```
app/
  store/
    store.ts
    root-reducer.ts

modules/
  <module>/
    features/<feature>/
      model/
        <feature>.slice.ts
        <feature>.selectors.ts
      api/
        <feature>.api.ts
    entities/<entity>/
      model/
        <entity>.types.ts
        <entity>.schema.ts
```

### Quando usar React Context

- Providers globais em `app/providers/`.
- Contextos estritamente locais na slice correspondente.
- Não usar Context para estado global de domínio.
- Evitar árvore excessiva de providers aninhados.

---

## Convenções Essenciais

### Variants (cva)

`Component.tsx` + `component.variants.ts` no mesmo diretório.

### Testes, lint e quality gates

- Unit tests: Vitest + Testing Library.
- Integration tests para fluxos críticos.
- E2E tests em caminhos principais.
- Lint e typecheck centralizados: Husky + ESLint + lint-staged.
- Regras de boundary via ESLint (eslint-plugin-boundaries / no-restricted-imports).

---

## Princípios Arquiteturais

1. **Simplicidade sobre complexidade**: resolver problemas reais, não antecipar escala.
2. **Fronteiras explícitas**: módulos com responsabilidades claras e baixo acoplamento.
3. **Reversibilidade**: decisões devem ser reversíveis.
4. **Consistência técnica**: padrões uniformes entre squads.
5. **Governança centralizada**: facilita compliance, auditoria e rastreabilidade.

---

## Referências

- [ADR-0003 - Monolito Modular vs Microfrontends](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757151)
- [ADR-0011 - Arquitetura das Aplicações Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/132349958)
- [RFC-0011 - Arquitetura das aplicações Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/131956760)
- [Feature-Sliced Design](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/131825676)

---

*Versão: 0.2.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
