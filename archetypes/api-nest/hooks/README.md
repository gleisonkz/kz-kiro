# Hooks — API NestJS

| Hook | Trigger | Ação |
|------|---------|------|
| `kiro-doctor` | `userTriggered` | Verifica saúde do projeto (build, lint, test) |
| `build-after-agent` | `agentStop` | Roda build após execução do agente |
| `run-tests-after-task` | `postTaskExecution` | Roda testes após tarefa de spec concluída |
| `review-vision-scope` | `fileEdited` | Revisa aplicação de vision scope em queries |
