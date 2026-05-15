# Hooks — Archetype BFF Fastify

> **Hooks | Archetype: bff-fastify | Versão: 0.1.0**
>
> Este diretório contém os hooks do Kiro para projetos BFF Fastify.

---

## Hooks Disponíveis

| Hook | Trigger | Ação | Descrição |
|---|---|---|---|
| `kiro-doctor` | userTriggered | askAgent | Diagnóstico completo das configurações Kiro |
| `lint-after-agent` | agentStop | runCommand | Executa lint após o agente parar |
| `typecheck-on-save` | agentStop | askAgent | Valida tipos TypeScript após edições |
| `run-tests-after-task` | postTaskExecution | runCommand | Executa testes após conclusão de task |
| `review-route-quality` | fileCreated | askAgent | Revisa qualidade de rotas criadas |
| `review-bff-boundaries` | preToolUse (write) | askAgent | Verifica se o BFF não contém lógica de negócio |

---

*Versão: 0.1.0 | Última revisão: 2026-05*
