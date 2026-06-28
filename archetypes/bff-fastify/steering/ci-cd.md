---
inclusion: fileMatch
fileMatchPattern: "**/.github/**,**/Dockerfile*,**/docker-compose*"
---

# Pipelines e Deploy — BFF Fastify

> **Steering File | Archetype: bff-fastify | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos BFF Fastify da MonteBravo.
> Ele define a estratégia de CI/CD, pipelines e deploy para aplicações BFF.

---

## Princípios de CI/CD

1. **Deploy independente**: o BFF pode ser deployado separadamente dos serviços de domínio e do frontend.
2. **Imutabilidade**: cada build gera um artefato imutável (container image).
3. **Rollback rápido**: deploys devem ser reversíveis em menos de 5 minutos.
4. **Zero downtime**: deploys não devem causar indisponibilidade.

---

## Estratégia de Pipeline

### O que o CI deve executar em todo PR

1. Lint (`eslint`).
2. Formatação (`prettier --check`).
3. Type check (`tsc --noEmit`).
4. Testes unitários (`vitest run`).
5. Testes de integração (`vitest run --project integration`).
6. Build (`tsup`).
7. Análise de segurança de dependências (`pnpm audit`).

### O que o CI deve executar no merge em main

- Tudo acima.
- Build da imagem Docker.
- Push da imagem para container registry.
- Deploy automático para ambiente `dev`.

### O que o CI deve executar para release

- Tudo acima.
- Deploy para `hml` com aprovação.
- Smoke tests no ambiente `hml`.
- Deploy para `prod` com aprovação.

---

## Ambientes

| Ambiente | Propósito | Deploy |
|---|---|---|
| `dev` | Desenvolvimento e integração | Automático no merge em main |
| `hml` | Homologação e testes de aceitação | Manual com aprovação |
| `prod` | Produção | Manual com aprovação |

---

## Container e Infraestrutura

### Imagem Docker

- Base: `node:20-alpine` (multi-stage build).
- Tamanho alvo: < 150MB.
- Sem ferramentas de desenvolvimento na imagem final.
- Health check configurado no Dockerfile.

### Orquestração

- Container orquestrado via ECS/Kubernetes (conforme infraestrutura da organização).
- Mínimo 2 réplicas em produção.
- Auto-scaling baseado em CPU/memória e request count.

### Variáveis de ambiente

- Injetadas via secrets manager (AWS Secrets Manager / Parameter Store).
- Nunca hardcoded na imagem ou no código.
- Rotação de segredos sem restart da aplicação (quando possível).

---

## Monitoramento Pós-Deploy

Após cada deploy em produção, monitorar por 15 minutos:

- Taxa de erro (deve permanecer < 1%).
- Latência p99 (não deve aumentar > 20%).
- Health check respondendo 200.
- Logs sem erros críticos.

Se algum threshold for violado: rollback automático.

---

## Referências

- [ADR-001 – Padrão arquitetural de comunicação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517)

---

*Versão: 0.1.0 | Última revisão: 2026-05 | Próxima revisão: TODO*
