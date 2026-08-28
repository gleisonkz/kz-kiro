# Hooks — Service NestJS

| Hook | Trigger | Ação |
|------|---------|------|
| `kiro-doctor` | `userTriggered` | Verifica saúde do projeto (build, lint, test) |
| `build-after-agent` | `agentStop` | Roda build após execução do agente |
| `lint-after-agent` | `agentStop` | Roda lint após execução do agente (se houve edição de .ts) |
| `run-tests-after-task` | `postTaskExecution` | Roda testes após tarefa de spec concluída |
| `review-messaging-patterns` | `preToolUse` | Revisa conformidade com padrões de messaging RabbitMQ |
