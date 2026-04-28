# Hooks — Archetype Mobile Flutter

> **Hooks | Archetype: mobile-flutter | Versão: 0.1.0**
>
> Hooks do Kiro que automatizam verificações e ações no fluxo de desenvolvimento Flutter mobile.

---

## Hooks Disponíveis

| Hook | Trigger | Ação | Descrição |
|---|---|---|---|
| Dart Analyze on Save | `fileEdited` (*.dart) | `runCommand` | Executa `dart analyze` ao salvar |
| Check Relative Imports | `fileEdited` (*.dart) | `runCommand` | Verifica imports relativos e alerta para usar `package:` |
| Barrel Export Reminder | `fileCreated` (pages/, routes/, widgets/) | `askAgent` | Lembra de exportar no barrel file da feature |
| Scaffold Test File | `fileCreated` (usecases/, datasources/, repositories/, providers/) | `askAgent` | Cria arquivo de teste espelhando a estrutura |

---

## Categorias

### Qualidade de código (automáticos)
- `dart-analyze-save.kiro.hook` — feedback imediato de erros e warnings
- `check-relative-imports.kiro.hook` — garante imports absolutos `package:`

### Organização de código (agente)
- `barrel-export-reminder.kiro.hook` — lembra de exportar classes públicas no barrel
- `scaffold-test-file.kiro.hook` — cria infraestrutura de teste automaticamente

---

## Notas

- Hooks de `runCommand` executam comandos no terminal e podem falhar se as dependências não estiverem instaladas.
- Hooks de `askAgent` consomem contexto do agente — são ações inteligentes, não apenas lint.
- O hook de scaffold de testes segue o padrão centralizado de mocks (`test/mocks/`) e fixtures (`test/fixtures/`).

---

*Versão: 0.1.0 | Última revisão: 2026-04*
