# Pipelines e Deploy — Frontend React

> **Steering File | Archetype: frontend-react | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos frontend React da MonteBravo.
> Ele define a estratégia de CI/CD, pipelines e deploy para aplicações frontend.
>
> Baseado em: RFC-0004 (Pipelines e Deploy)
>
> **Nota:** RFC-0004 está em status de rascunho. Este steering file reflete a direção proposta.

---

## Princípios de CI/CD

1. **Deploy independente por aplicação**: cada app pode ser deployada separadamente em qualquer ambiente.
2. **Isolamento de falhas**: erro em uma app não bloqueia deploy de outra.
3. **Builds orquestrados por impacto**: Turborepo detecta o que mudou e executa apenas builds e testes relevantes.
4. **Build pode ser compartilhado; deploy nunca é compartilhado**: packages compartilhados podem ter builds em comum, mas cada app é deployada separadamente.

---

## Estratégia de Pipelines

### Orquestração por impacto (Turborepo)

- CI/CD detecta quais packages/apps foram alterados.
- Executa apenas builds e testes relevantes.
- Cache inteligente habilitado para evitar rebuilds desnecessários.

### Builds isolados

- Cada aplicação e package possui seu próprio processo de build.
- Builds são independentes e podem ser executados em paralelo.

### Deploy por ambiente

- Ambientes: `dev`, `hml` (homologação), `prod`.
- Cada aplicação pode ser deployada independentemente em qualquer ambiente.
- Deploys nunca são sincronizados entre aplicações — cada uma tem seu próprio ciclo de vida.

---

## Regras de Pipeline

### O que o CI deve executar em todo PR

- Lint (ESLint + Prettier check).
- Type check (TypeScript).
- Testes unitários (Vitest).
- Build das apps/packages afetados.

### O que o CI deve executar no merge em main

- Tudo acima.
- Deploy automático para ambiente `dev` (quando configurado).

### O que o CI deve executar para release

- Tudo acima.
- Deploy para `hml` com aprovação.
- Deploy para `prod` com aprovação.

---

## Design System — Pipeline Específico

O Design System tem pipeline próprio no seu repositório independente:

1. PR: lint, type check, testes, build, Chromatic (visual regression).
2. Merge em main: acumula changesets.
3. Release: `changeset version` → atualiza versão → CI publica no registry.
4. Apps atualizam a dependência no monorepo.

---

## Estratégias Descartadas

| Estratégia | Motivo |
|---|---|
| Pipeline único para todo o monorepo | Deploy de uma app afeta todas, erro bloqueia tudo, custo excessivo |
| Deploys sempre sincronizados | Perda de autonomia, dificulta hotfixes, atrasa releases |
| Microfrontends com deploy independente | Complexidade de infra excessiva para estágio atual |

---

## Referências

- [RFC-0004 - Pipelines e Deploy](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757425)

---

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
