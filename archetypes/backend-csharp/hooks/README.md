# Hooks — Archetype Backend C#

> **Hooks | Archetype: backend-csharp | Versão: 0.1.0**
>
> Este diretório contém os hooks do Kiro para projetos de serviços de domínio .NET/C#.

---

## Hooks Disponíveis

| Hook | Trigger | Ação | Descrição |
|---|---|---|---|
| `kiro-doctor` | userTriggered | askAgent | Diagnóstico completo das configurações Kiro |
| `build-after-agent` | agentStop | runCommand | Executa build após o agente parar |
| `run-tests-after-task` | postTaskExecution | runCommand | Executa testes após conclusão de task |
| `review-domain-boundaries` | preToolUse (write) | askAgent | Verifica se as fronteiras de camada são respeitadas |
| `review-endpoint-quality` | fileCreated | askAgent | Revisa qualidade de endpoints criados |

---

*Versão: 0.1.0 | Última revisão: 2026-05*
