# Archetype: BFF Fastify

> **Archetype | bff-fastify | Versão: 0.2.0**
>
> Configurações Kiro para projetos BFF (Backend for Frontend) com Fastify, Zod e TypeScript.
>
> Baseado em: RFC-0013 (Framework padrão para BFFs), RFC-0014 (Estrutura e Organização dos BFFs)

---

## Propósito

O BFF é uma camada intermediária entre as aplicações frontend e os serviços de domínio. Cada **vertical de negócio** (cliente, assessor) possui seu próprio BFF, construído como **monólito modular** — espelhando a modularidade das aplicações frontend e o ownership dos times por módulo.

Um único BFF por vertical atende **múltiplos canais** (web, mobile, etc.).

---

## Estrutura

```
archetypes/bff-fastify/
├── README.md
├── agents/
│   └── README.md
├── hooks/
│   ├── README.md
│   ├── kiro-doctor.kiro.hook
│   ├── lint-after-agent.kiro.hook
│   ├── typecheck-on-save.kiro.hook
│   ├── run-tests-after-task.kiro.hook
│   ├── review-route-quality.kiro.hook
│   └── review-bff-boundaries.kiro.hook
├── mcp/
│   └── mcp.json
├── skills/
│   ├── README.md
│   ├── generate-module.md
│   ├── generate-client.md
│   └── generate-plugin.md
└── steering/
    ├── README.md
    ├── architecture.md
    ├── ci-cd.md
    ├── naming-conventions.md
    └── stack-and-tooling.md
```

---

## Stack

- **Runtime:** Node.js 20 LTS
- **Framework:** Fastify 5.x (plugins, encapsulation, schema-based)
- **Linguagem:** TypeScript 5.x (strict mode)
- **Validação/Schema:** Zod + fastify-type-provider-zod
- **Testes:** Vitest
- **Build:** tsup (ESM)
- **Linting:** ESLint + Prettier
- **Pacotes:** pnpm

---

## Como usar

Para aplicar este archetype em um novo projeto BFF:

```bash
./scripts/bootstrap.sh --project-type bff-fastify --target <caminho-do-projeto>
```

O bootstrap aplica automaticamente o baseline global, o archetype e os powers necessários.

---

## Princípios Arquiteturais (RFC-0014)

1. **BFF por vertical de negócio** — cada vertical possui um BFF dedicado, independente do canal.
2. **Multi-canal** — um único BFF atende web, mobile e outros consumers da mesma vertical.
3. **Repositório próprio** — BFFs vivem fora do monorepo frontend.
4. **Ownership compartilhado** — responsabilidade conjunta de times de frontend e backend.
5. **Espelhamento modular** — modularidade reflete os bounded contexts da vertical.
6. **Zero regras de negócio** — BFFs orquestram, transformam e adaptam — nunca decidem.
7. **Contratos explícitos** — toda rota possui schema Zod de entrada e saída.
8. **Consistência via convenção** — estrutura padronizada e enforçada por linting e templates.

---

## Referências

- [RFC-0013 – Framework padrão para BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777601)
- [RFC-0014 – Estrutura e Organização dos BFFs](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/186777613)
- [ADR-0003 – Monolito Modular vs Microfrontends](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757151)
- [ADR-0011 – Arquitetura das Aplicações Frontend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/132349958)

---

*Versão: 0.2.0 | Última revisão: 2026-05*
