# Hooks — Archetype Frontend React

> **Hooks | Archetype: frontend-react | Versão: 0.1.0**
>
> Hooks do Kiro que automatizam verificações e ações no fluxo de desenvolvimento frontend.

---

## Hooks Disponíveis

| Hook | Trigger | Ação | Descrição |
|---|---|---|---|
| Lint on Save | `fileEdited` (*.ts, *.tsx) | `runCommand` | Executa ESLint --fix ao salvar |
| Type Check on Save | `fileEdited` (*.ts, *.tsx) | `runCommand` | Executa tsc --noEmit ao salvar |
| Revisar Nomenclatura | `fileCreated` (*.ts, *.tsx) | `askAgent` | Verifica convenções de nomenclatura em arquivos novos |
| Revisar Qualidade de Componente | `fileCreated` (**/ui/**/*.tsx, **/components/**/*.tsx) | `askAgent` | Verifica acessibilidade, tipagem, tokens e composição |
| Revisar Fronteiras de Módulo | `preToolUse` (write) | `askAgent` | Verifica se imports respeitam fronteiras entre módulos |
| Executar Testes Após Task | `postTaskExecution` | `runCommand` | Roda vitest após conclusão de task de spec |
| Lembrar Cobertura de Testes | `agentStop` | `askAgent` | Verifica se arquivos criados/editados têm testes |

---

## Categorias

### Qualidade de código (automáticos)
- `lint-on-save.json` — garante padrões ESLint a cada save
- `typecheck-on-save.json` — detecta erros de tipo rapidamente

### Revisão arquitetural (agente)
- `review-naming-conventions.json` — convenções de nomenclatura MonteBravo
- `review-component-quality.json` — padrões do Design System
- `review-feature-boundaries.json` — fronteiras entre módulos (bounded contexts)

### Ciclo de desenvolvimento
- `run-tests-after-task.json` — testes após cada task de spec
- `remind-test-coverage.json` — lembrete de cobertura ao finalizar sessão

---

## Notas

- Hooks de `runCommand` executam comandos no terminal e podem falhar se as dependências não estiverem instaladas.
- Hooks de `askAgent` consomem contexto do agente — são revisões inteligentes, não apenas lint.
- O hook de fronteiras (`preToolUse` write) verifica imports antes de escrever arquivos, prevenindo violações arquiteturais.

---

*Versão: 0.1.0 | Última revisão: 2026-04*
