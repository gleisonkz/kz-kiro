# Implementation Plan: Archetype Mobile Flutter

## Overview

Este plano cobre as tarefas de validação e teste do archetype `mobile-flutter` — um archetype já implementado. O foco é garantir conformidade com os requisitos via testes de propriedade, unitários e de integração usando bats-core, seguindo o mesmo padrão das specs `archetype-backend-csharp` e `archetype-bff-fastify`. Não há implementação de funcionalidades novas; apenas validação estrutural, testes automatizados e documentação de gaps.

**Diferenciais deste archetype:**
- 15 steering files com frontmatter YAML (vs blockquote nos outros)
- Hooks com triggers `fileEdited` e `fileCreated` (vs `agentStop` nos outros)
- Servidor MCP funcional (dart mcp-server) — não vazio
- NÃO tem VERSION nem CHANGELOG
- Skills e agents VAZIOS (apenas READMEs)
- 6 steering files de contratos de API

## Tasks

- [x] 1. Validar conformidade estrutural do archetype existente
  - [x] 1.1 Validar estrutura de diretórios e artefatos obrigatórios
    - Verificar que `steering/`, `hooks/`, `agents/`, `skills/` e `mcp/` existem
    - Verificar que `steering/` contém exatamente 15 arquivos `.md` (excluindo README.md) com nomes esperados
    - Verificar que `hooks/` contém exatamente 5 arquivos `.kiro.hook` com nomes esperados
    - Verificar que `agents/` contém apenas `README.md` — nenhum agent funcional
    - Verificar que `skills/` contém apenas `README.md` — nenhuma skill funcional
    - Verificar que `mcp/` contém um `mcp.json`
    - Verificar que `README.md` existe na raiz e em cada diretório de categoria (steering, hooks, agents, skills)
    - Verificar que NÃO existe `VERSION` nem `CHANGELOG.md` na raiz
    - Documentar gaps encontrados (artefatos ausentes ou extras vs design)
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 11.2, 12.2, 13.1, 13.2_
  - [x] 1.2 Validar conformidade dos steering files (frontmatter YAML)
    - Verificar que todos os 15 steering files possuem frontmatter YAML válido com delimitadores `---`
    - Verificar campo `inclusion` obrigatório com valor válido (`always`, `fileMatch`, `auto`, `manual`)
    - Verificar campos `name` e `description` presentes quando `inclusion` é `auto` ou `manual`
    - Verificar campo `fileMatchPattern` presente quando `inclusion` é `fileMatch`
    - Verificar mapeamento correto: `coding-standards.md` e `flutter-lints-security.md` → `always`; `flutter_best_practices.md`, `flutter-testing-patterns.md`, `dependency-management.md` → `fileMatch`; contratos API + `clean-architecture.md` + `flutter-clean-architecture.md` + `design-system.md` → `auto`; `code-review.md` → `manual`
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_
  - [x] 1.3 Validar conformidade dos hooks (schema JSON)
    - Verificar que todos os 5 hooks têm `enabled: true`, `version: "1"`, schema JSON válido
    - Verificar triggers corretos: `fileEdited` para `dart-analyze-save` e `check-relative-imports`; `fileCreated` para `barrel-export-reminder` e `scaffold-test-file`; `userTriggered` para `kiro-doctor`
    - Verificar tipos de ação: `runCommand` para dart-analyze-save e check-relative-imports; `askAgent` para barrel-export-reminder, scaffold-test-file e kiro-doctor
    - Verificar patterns corretos: `["**/*.dart"]` para fileEdited hooks; patterns de pages/routes/widgets para barrel; patterns de usecases/datasources/repositories/providers para scaffold
    - _Requisitos: 5.1, 6.1, 7.1, 8.1, 9.1_
  - [x] 1.4 Validar conformidade do mcp.json (servidor Dart funcional)
    - Verificar schema: `_comment` não-vazio mencionando archetype mobile-flutter e merge com baseline
    - Verificar `_version` em formato semver (`0.1.0`)
    - Verificar `mcpServers.dart` com `command: "dart"`, `args: ["mcp-server"]`, `disabled: false`, `autoApprove: []`
    - Verificar que mcpServers NÃO é vazio (diferente dos outros archetypes)
    - _Requisitos: 10.1, 10.2, 10.3_
  - [x] 1.5 Validar conformidade dos diretórios agents/ e skills/ (placeholders)
    - Verificar que `agents/README.md` lista 3 candidatos futuros (arquitetura Clean Architecture, acessibilidade mobile, performance Flutter)
    - Verificar que `skills/README.md` lista 5 candidatas futuras (feature completa, use case, datasource+mock, provider Riverpod, página+rota)
    - Verificar que não existem arquivos funcionais além de README.md em ambos
    - _Requisitos: 11.1, 11.2, 12.1, 12.2_
  - [x] 1.6 Validar consistência de versão nos READMEs
    - Verificar que README.md raiz referencia versão `0.1.0`
    - Verificar que READMEs internos (steering, hooks, agents, skills) referenciam mesma versão `0.1.0`
    - _Requisitos: 13.3, 13.4_

- [x] 2. Checkpoint — Validação estrutural completa
  - Garantir que todos os artefatos estão conformes, perguntar ao usuário se surgirem dúvidas.

- [x] 3. Implementar testes unitários do archetype
  - [x] 3.1 Criar teste unitário para steering files — estrutura e frontmatter
    - Verificar existência dos 15 arquivos de steering com nomes corretos (+ README)
    - Verificar frontmatter YAML válido em cada steering file (delimitadores `---`, campo `inclusion`)
    - Verificar `coding-standards.md`: inclusion always, temas de Clean Architecture, Riverpod, go_router, performance, anti-patterns
    - Verificar `flutter_best_practices.md`: inclusion fileMatch com `**/*.dart`, imports absolutos, nomenclatura, clean code, Design System
    - Verificar `flutter-lints-security.md`: inclusion always, flutter_lints, regras extras, segurança
    - Verificar `flutter-testing-patterns.md`: inclusion fileMatch com patterns de test, mocks centralizados, fixtures, mocktail via core_dev
    - Verificar `dependency-management.md`: inclusion fileMatch com `**/pubspec.yaml`, Core_Package, Core_Dev_Package
    - Verificar `design-system.md`: inclusion auto, name design-system, package ds_monte_bravo_mobile, prefixo Mb
    - Verificar `code-review.md`: inclusion manual, checklist de revisão com 8 seções
    - Arquivo: `tests/unit/test_archetype_flutter_steering.bats`
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_
  - [x] 3.2 Criar teste unitário para steering files — contratos de API
    - Verificar existência dos 6 contratos: `auth-api.md`, `forgot-password-api.md`, `home-api.md`, `notifications-api.md`, `profile-api.md`, `settings-api.md`
    - Verificar que todos têm inclusion `auto` com `name` e `description`
    - Verificar `auth-api.md`: endpoints POST /auth/login, POST /auth/signup, POST /auth/logout, GET /auth/me, POST /auth/validate-token, interfaces AuthRemoteDataSource e AuthRepository
    - Verificar `forgot-password-api.md`: endpoints POST forgot-password, POST verify-otp, interface ForgotPasswordRemoteDataSource
    - Verificar `home-api.md`: endpoints GET balance, GET notices, interface HomeRemoteDataSource
    - Verificar `notifications-api.md`: endpoints GET notifications, POST read, POST delete, interface NotificationRemoteDataSource
    - Verificar `profile-api.md`: endpoint GET profile, interface ProfileRemoteDataSource
    - Verificar `settings-api.md`: endpoints GET settings, GET communication-prefs, POST communication-prefs, interface SettingsRemoteDataSource
    - Verificar nota de aviso sobre mocks em todos os contratos exceto `auth-api.md`
    - Arquivo: `tests/unit/test_archetype_flutter_api_contracts.bats`
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_
  - [x] 3.3 Criar teste unitário para hooks
    - Verificar existência dos 5 hooks com nomes corretos
    - Verificar `dart-analyze-save`: trigger fileEdited, patterns `["**/*.dart"]`, runCommand com `dart analyze "$KIRO_FILE_PATH"`
    - Verificar `check-relative-imports`: trigger fileEdited, patterns `["**/*.dart"]`, runCommand com grep de imports relativos
    - Verificar `barrel-export-reminder`: trigger fileCreated, patterns corretos (pages/routes/widgets), askAgent, prompt menciona "Do NOT modify" / não modificar automaticamente
    - Verificar `scaffold-test-file`: trigger fileCreated, patterns corretos (usecases/datasources/repositories/providers), askAgent, prompt exige imports absolutos e mocktail via core_dev
    - Verificar `kiro-doctor`: trigger userTriggered, askAgent, prompt menciona 8 seções e `kiro-doctor-report.md`
    - Arquivo: `tests/unit/test_archetype_flutter_hooks.bats`
    - _Requisitos: 5.1, 5.2, 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 8.1, 8.2, 8.3, 8.4, 9.1, 9.2, 9.3, 9.4_
  - [x] 3.4 Criar teste unitário para mcp.json
    - Verificar campo `_comment` não-vazio mencionando archetype mobile-flutter e merge com baseline
    - Verificar campo `_version` em formato semver (`0.1.0`)
    - Verificar `mcpServers.dart`: command `"dart"`, args `["mcp-server"]`, disabled `false`, autoApprove `[]`
    - Verificar que mcpServers contém ao menos a entrada "dart" (diferente dos outros archetypes com objeto vazio)
    - Arquivo: `tests/unit/test_archetype_flutter_mcp.bats`
    - _Requisitos: 10.1, 10.2, 10.3_
  - [x] 3.5 Criar teste unitário para agents e skills (placeholders)
    - Verificar que `agents/` contém apenas `README.md`
    - Verificar que `agents/README.md` lista 3 candidatos futuros
    - Verificar que `skills/` contém apenas `README.md`
    - Verificar que `skills/README.md` lista 5 candidatas futuras
    - Verificar que não há arquivos `.md` com frontmatter de agent/skill funcional
    - Arquivo: `tests/unit/test_archetype_flutter_placeholders.bats`
    - _Requisitos: 11.1, 11.2, 12.1, 12.2_

- [x] 4. Checkpoint — Testes unitários
  - Garantir que todos os testes unitários passam, perguntar ao usuário se surgirem dúvidas.

- [x] 5. Implementar testes de propriedade
  - [x] 5.1 Escrever teste de propriedade para completude estrutural
    - **Property 1: Completude estrutural do archetype**
    - **Valida: Requisitos 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 11.2, 12.2, 13.1, 13.2**
    - Gerar 100 variações de estado do archetype (removendo artefatos aleatórios)
    - Verificar que `steering/` requer exatamente 15 `.md` (excl. README), `hooks/` requer 5 `.kiro.hook`, `mcp/` requer `mcp.json`, `agents/` e `skills/` requerem apenas `README.md`
    - Verificar ausência obrigatória de VERSION e CHANGELOG.md
    - Arquivo: `tests/properties/prop_flutter_structure.bats`
  - [x] 5.2 Escrever teste de propriedade para frontmatter YAML válido
    - **Property 2: Frontmatter YAML válido nos steering files**
    - **Valida: Requisitos 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8**
    - Gerar 100 variações de frontmatter (válidos e inválidos)
    - Verificar que validação requer: delimitadores `---`, campo `inclusion` com valor válido, `name`/`description` para auto/manual, `fileMatchPattern` para fileMatch
    - Arquivo: `tests/properties/prop_flutter_frontmatter.bats`
  - [x] 5.3 Escrever teste de propriedade para mapeamento de inclusion
    - **Property 3: Mapeamento correto de inclusion por steering file**
    - **Valida: Requisitos 14.1, 14.2, 14.3, 14.4, 14.5, 14.6**
    - Gerar 100 permutações de mapeamento arquivo→inclusion
    - Verificar que apenas o mapeamento esperado é aceito: always (2 files), fileMatch (3 files), auto (10 files), manual (1 file)
    - Arquivo: `tests/properties/prop_flutter_inclusion_map.bats`
  - [x] 5.4 Escrever teste de propriedade para hooks habilitados e schema válido
    - **Property 4: Hooks habilitados e schema válido**
    - **Valida: Requisitos 5.1, 6.1, 7.1, 8.1, 9.1**
    - Gerar 100 variações de hooks JSON com campos obrigatórios aleatórios
    - Verificar que validação requer: `enabled: true`, `name` não-vazio, `description` não-vazio, `version: "1"`, `when.type` válido (fileEdited/fileCreated/userTriggered), `then.type` válido, `then.prompt` quando askAgent, `then.command` quando runCommand, `when.patterns` (array não-vazio) quando fileEdited/fileCreated
    - Arquivo: `tests/properties/prop_flutter_hooks_schema.bats`
  - [x] 5.5 Escrever teste de propriedade para schema MCP com servidor Dart
    - **Property 5: Schema de configuração MCP com servidor Dart**
    - **Valida: Requisitos 10.1, 10.2, 10.3**
    - Gerar 100 variações de mcp.json (válidos e inválidos)
    - Verificar que validação requer: `_comment` string não-vazia, `_version` semver válido, `mcpServers.dart` com command `"dart"`, args `["mcp-server"]`, disabled `false`, autoApprove `[]`
    - Arquivo: `tests/properties/prop_mcp_schema_flutter.bats`
  - [x] 5.6 Escrever teste de propriedade para consistência de versão
    - **Property 6: Consistência de versão nos READMEs**
    - **Valida: Requisitos 13.3, 13.4**
    - Gerar 100 variações de versão nos READMEs (consistentes e inconsistentes)
    - Verificar que todos os READMEs (raiz, steering, hooks, agents, skills) referenciam a mesma versão `0.1.0`
    - Arquivo: `tests/properties/prop_flutter_version_consistency.bats`

- [x] 6. Checkpoint — Testes de propriedade
  - Garantir que todos os testes de propriedade passam, perguntar ao usuário se surgirem dúvidas.

- [x] 7. Implementar testes de integração
  - [x] 7.1 Escrever testes de integração para bootstrap do archetype mobile-flutter
    - Cenários: bootstrap com `--project-type mobile-flutter` copia todos os artefatos do archetype
    - Verificar que 15 steering files (sem README) são copiados para `.kiro/steering/`
    - Verificar que 5 hooks são copiados para `.kiro/hooks/`
    - Verificar que agents/ (apenas README.md) é copiado para `.kiro/agents/`
    - Verificar que skills/ (apenas README.md) é copiado para `.kiro/skills/`
    - Verificar merge de mcp.json (baseline global + archetype mobile-flutter com dart server = baseline + dart)
    - Verificar que `settings/mcp.json` resultante contém servidores do baseline E entrada `dart`
    - Verificar geração de manifest com `archetype.name: "mobile-flutter"` e versão `0.1.0`
    - Arquivo: `tests/integration/test_bootstrap_flutter.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (bootstrap.sh)_
  - [x] 7.2 Escrever testes de integração para sync do archetype mobile-flutter
    - Cenários: sync atualiza steering file desatualizado, adiciona hook novo, mantém inalterado o que já está correto
    - Verificar que artefatos do archetype mobile-flutter são sincronizados corretamente
    - Verificar atualização do `last_synced_at` no manifest
    - Verificar que steering files com frontmatter são copiados integralmente (frontmatter preservado)
    - Arquivo: `tests/integration/test_sync_flutter.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (sync.sh)_
  - [x] 7.3 Escrever testes de integração para doctor com archetype mobile-flutter
    - Cenários: projeto saudável (✅ em tudo), steering ausente (❌), hook desabilitado (⚠️), MCP dart disabled (⚠️)
    - Verificar que doctor detecta artefatos específicos do archetype mobile-flutter (15 steering, 5 hooks)
    - Verificar que relatório contém as 8 seções na ordem correta
    - Verificar que doctor identifica dart MCP server como obrigatório (diferente dos outros archetypes)
    - Verificar que doctor reporta ausência de VERSION/CHANGELOG como esperado (não é gap)
    - Arquivo: `tests/integration/test_doctor_flutter.bats`
    - _Requisitos: Design — Integração com Scripts de Automação (doctor.sh), 9.1, 9.2, 9.3, 9.4_

- [x] 8. Checkpoint final — Executar suíte completa de testes
  - Executar `./tests/run_tests.sh` e garantir que todos os testes passam.
  - Perguntar ao usuário se surgirem dúvidas.

## Notes

- Este é um spec retroativo — o archetype já está implementado, foco é em validação e testes
- Cada task referencia requisitos específicos para rastreabilidade
- Checkpoints garantem validação incremental
- Testes de propriedade validam propriedades universais de correção (100 iterações cada, conforme design)
- Testes unitários verificam conteúdo específico dos artefatos existentes
- Testes de integração validam interação do archetype com bootstrap/sync/doctor
- O projeto usa bash + bats-core para testes, jq para JSON, yq para YAML
- Helpers existentes em `tests/helpers/` (assertions.bash, generators.bash, setup.bash) devem ser reutilizados
- Testes de propriedade existentes genéricos (`prop_frontmatter.bats`, `prop_mcp_schema.bats`, `prop_semver.bats`, `prop_hooks_enabled.bats`) podem ser reutilizados — criar novos apenas para propriedades específicas do mobile-flutter
- **Diferenças do bff-fastify/backend-csharp:**
  - Steering files COM frontmatter YAML (não blockquote)
  - Hooks com `fileEdited`/`fileCreated` triggers (não `agentStop`/`preToolUse`/`postToolUse`)
  - MCP com servidor funcional `dart` (não `mcpServers: {}` vazio)
  - NÃO tem VERSION/CHANGELOG — ausência é o comportamento correto
  - Skills e agents são placeholders puros (apenas README.md)
  - 6 contratos de API como steering files — categoria exclusiva

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5", "1.6"] },
    { "id": 1, "tasks": ["3.1", "3.2", "3.4", "3.5"] },
    { "id": 2, "tasks": ["3.3", "5.1", "5.2", "5.3"] },
    { "id": 3, "tasks": ["5.4", "5.5", "5.6"] },
    { "id": 4, "tasks": ["7.1", "7.2", "7.3"] }
  ]
}
```
