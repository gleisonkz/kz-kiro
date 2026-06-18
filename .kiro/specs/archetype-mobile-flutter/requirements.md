# Requirements Document

## Introduction

O Archetype Mobile Flutter é o pacote de configuração Kiro para projetos mobile com Flutter + Dart da organização MonteBravo. Ele fornece steering files específicos da stack (incluindo padrões arquiteturais, boas práticas, design system e contratos de APIs backend), hooks de automação para qualidade e organização de código, e configuração MCP com servidor Dart integrado. O archetype segue Clean Architecture por feature com Riverpod para state management e go_router para navegação, em um monorepo Melos. Extraído do repositório `mb-customer-app-mobile`, o archetype ainda não possui versionamento formal (VERSION/CHANGELOG), skills ou agents implementados — apenas placeholders documentados para futuras adições.

## Glossary

- **Archetype_Mobile_Flutter**: Pacote de configuração Kiro para projetos Flutter mobile, localizado em `archetypes/mobile-flutter/`, contendo steering files, hooks e configuração MCP.
- **Steering_File**: Documento markdown injetado pelo Kiro como contexto nas interações com o agente, contendo diretrizes técnicas específicas da stack Flutter mobile.
- **Hook**: Arquivo JSON com extensão `.kiro.hook` que define uma automação do Kiro, contendo campos `name`, `when` (trigger) e `then` (ação a executar).
- **Skill**: Documento markdown com frontmatter YAML que define um prompt estruturado para geração de código sob demanda.
- **MCP_Config**: Arquivo `mcp.json` no diretório `mcp/` do archetype que declara servidores MCP específicos para projetos Flutter mobile.
- **Projeto_Flutter_Mobile**: Projeto de produto que utiliza o archetype mobile-flutter como configuração Kiro.
- **Clean_Architecture**: Padrão arquitetural com separação em camadas por feature (presentation → domain ← data) onde Domain não possui dependências externas.
- **Riverpod**: Framework de state management para Flutter utilizado como solução única de gerenciamento de estado no archetype.
- **Melos**: Ferramenta de gerenciamento de monorepo Dart/Flutter que coordena múltiplos packages no workspace.
- **Design_System**: Package `ds_monte_bravo_mobile` que fornece componentes UI reutilizáveis seguindo Atomic Design com prefixo `Mb`.
- **Barrel_File**: Arquivo Dart que re-exporta classes públicas de um package para simplificar imports (ex: `lib/feature_auth.dart`).
- **Core_Package**: Package `core` que centraliza todas as dependências runtime third-party, exportadas via `package:core/core.dart`.
- **Core_Dev_Package**: Package `core_dev` que centraliza ferramentas de desenvolvimento (mocktail, build_runner, linters), importado via `package:core_dev/core_dev.dart`.
- **Contrato_API**: Documento de steering que especifica endpoints, request/response schemas, códigos de status e interfaces de DataSource para um serviço backend consumido pelo app.

## Requirements

### Requirement 1: Composição e Estrutura do Archetype

**User Story:** Como mantenedor da plataforma, eu quero que o archetype mobile-flutter tenha uma estrutura bem definida de artefatos organizados por categoria, para que projetos Flutter mobile recebam um conjunto completo e consistente de configurações Kiro.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL conter um diretório `steering/` com exatamente 15 Steering_Files em formato markdown (extensão `.md`) cobrindo os temas de padrões de código (`coding-standards.md`), boas práticas Flutter (`flutter_best_practices.md`), Clean Architecture genérica (`clean-architecture.md`), Clean Architecture Flutter (`flutter-clean-architecture.md`), lints e segurança (`flutter-lints-security.md`), padrões de teste (`flutter-testing-patterns.md`), gerenciamento de dependências (`dependency-management.md`), design system (`design-system.md`), code review (`code-review.md`) e 6 contratos de API (`auth-api.md`, `forgot-password-api.md`, `home-api.md`, `notifications-api.md`, `profile-api.md`, `settings-api.md`).
2. THE Archetype_Mobile_Flutter SHALL conter um diretório `hooks/` com exatamente 5 Hooks em formato JSON (extensão `.kiro.hook`) que automatizam verificações e ações disparadas por eventos do fluxo de desenvolvimento Flutter.
3. THE Archetype_Mobile_Flutter SHALL conter um diretório `agents/` com apenas um arquivo `README.md` documentando o propósito do diretório e os agents candidatos futuros, sem nenhum agent funcional implementado.
4. THE Archetype_Mobile_Flutter SHALL conter um diretório `skills/` com apenas um arquivo `README.md` documentando o propósito do diretório e as skills candidatas futuras, sem nenhuma skill funcional implementada.
5. THE Archetype_Mobile_Flutter SHALL conter um diretório `mcp/` com um arquivo `mcp.json` declarando a configuração MCP específica para projetos Flutter mobile.
6. THE Archetype_Mobile_Flutter SHALL conter um arquivo `README.md` na raiz do archetype documentando propósito, origem, estrutura, stack, instruções de uso e versão.
7. THE Archetype_Mobile_Flutter SHALL conter um arquivo `README.md` em cada diretório de categoria (`steering/`, `hooks/`, `agents/`, `skills/`) documentando os artefatos disponíveis naquela categoria, sua finalidade e status.
8. THE Archetype_Mobile_Flutter SHALL NÃO conter arquivo `VERSION` nem arquivo `CHANGELOG.md` na raiz, refletindo o estado atual de archetype sem versionamento formal implementado.

### Requirement 2: Steering Files — Padrões Técnicos Flutter

**User Story:** Como engenheiro Flutter mobile, eu quero que os steering files cubram padrões de código, arquitetura, lints, segurança, testes, dependências e design system, para que o Kiro tenha contexto suficiente para orientar decisões de acordo com os padrões arquiteturais do projeto.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `coding-standards.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: always`, abordando: regras de Clean Architecture (domain sem Flutter/imports externos, data depende apenas de domain, presentation depende apenas de domain), Riverpod como solução única de state management (ref.watch em build, ref.read para callbacks, estado imutável com copyWith), navegação via go_router (rotas definidas em `routes.dart` da feature, sem strings hardcoded em widgets), política de comentários (nunca narrar o que o código faz, apenas intenção não-óbvia, inglês, breves), regras de performance (sem computação pesada em build, ListView.builder, cached_network_image, select com Riverpod) e tabela de anti-patterns com alternativas corretas.
2. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `flutter_best_practices.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: fileMatch` e `fileMatchPattern: "**/*.dart"`, abordando: regra de incerteza (não inventar/assumir informações), imports absolutos obrigatórios `package:` (nunca relativos `../` ou `./`) com ordenação por grupo, uso de `const`, proibição do operador `!` (preferir null-safe flows e promoção de tipo), convenções de nomenclatura (PascalCase para classes, camelCase para variáveis/métodos, snake_case para arquivos, _prefixed para privados, sufixo Provider para providers, sufixo UseCase para use cases), regras de clean code (single responsibility, funções de max ~30 linhas, nomes significativos, sem magic numbers, imutabilidade, sem print), uso obrigatório do Design System `ds_monte_bravo_mobile`, regras de widgets (max ~100 linhas, preferir StatelessWidget a helper methods, nunca _build* methods), SOLID em Flutter e mock data sources com simulação de latência.
3. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `flutter-lints-security.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: always`, abordando: uso de `flutter_lints` em dev_dependencies com include no analysis_options.yaml, regras extras recomendadas (always_use_package_imports, avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, avoid_dynamic_calls, unnecessary_null_checks, prefer_single_quotes, require_trailing_commas) e políticas de segurança (nunca commitar tokens/API keys/senhas, usar variáveis de ambiente não-versionadas com .env.example, flavors para builds distintos).
4. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `flutter-testing-patterns.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: fileMatch` e `fileMatchPattern` para arquivos `*_test.dart` e `test/**/*.dart`, abordando: estrutura centralizada de mocks em `test/mocks/` (proibido inline mocks, usar mocktail via core_dev, barrel `mocks.dart`), fixtures em `test/fixtures/` (classes estáticas, barrel `fixtures.dart`), estrutura de testes espelhando `lib/`, convenções de nomenclatura (mock_<class>.dart, <context>_fixtures.dart, <file>_test.dart), padrões de teste por camada (use case testa lógica mockando repository, repository testa mapeamento mockando datasource, provider testa transições de estado mockando use cases, widget testa UI com override de providers), e uso de mocktail importado exclusivamente via `package:core_dev/core_dev.dart`.
5. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `dependency-management.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: fileMatch` e `fileMatchPattern: "**/pubspec.yaml"`, abordando: centralização de dependências runtime no Core_Package (proibido adicionar third-party diretamente em feature packages), procedimento para adicionar nova dependência (adicionar ao core/pubspec.yaml, exportar em core/lib/dependencies.dart, melos bootstrap), centralização de dev dependencies no Core_Dev_Package, regras de utilities compartilhadas (checar antes de criar, funções puras, testes obrigatórios), e uso obrigatório de barrel files do core (nunca importar sub-files `package:core/src/...`).
6. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `design-system.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: design-system` e `description` relacionada a componentes UI, abordando: package `ds_monte_bravo_mobile` como fonte obrigatória de componentes genéricos, golden rule (nunca criar componente genérico dentro de feature), workflow de lookup (buscar no DS → encontrou: usar → não encontrou: seguir protocolo), protocolo de componente não encontrado (classificar em Atomic Design como Atom/Molecule/Organism, sugerir nome com prefixo Mb, apresentar decisão ao dev, aguardar aprovação), convenção de nomes com prefixo `Mb`, tabela de localização de componentes (DS para genéricos, feature/widgets para específicos) e lista de proibições (nunca recriar componente do DS, nunca hardcodar design tokens).
7. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `code-review.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: manual`, fornecendo checklist completo de revisão de código com seções de Architecture, Dart Quality, Riverpod, Naming, go_router, Widgets, Testing e Performance, política de incerteza (não assumir/inventar, perguntar por contexto), política de comentários e formato de output (File, Line, Severity, Issue, Fix).
8. THE cada Steering_File do archetype mobile-flutter que utiliza frontmatter YAML SHALL iniciar com delimitadores `---` contendo campos de metadados (`inclusion`, opcionalmente `name`, `description`, `fileMatchPattern`) que controlam quando o steering é carregado pelo Kiro (always, fileMatch, auto ou manual).

### Requirement 3: Steering Files — Clean Architecture

**User Story:** Como engenheiro Flutter mobile, eu quero que os steering files detalhem a Clean Architecture por feature adotada pelo projeto, para que o Kiro guie a criação de features seguindo as regras de dependência e organização correta das camadas.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `clean-architecture.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: clean-architecture` e `description` relacionada a criação de features e organização de camadas, abordando: visão geral da dependency rule (presentation → domain ← data, domain sem dependências externas), estrutura de camadas com diretórios específicos (presentation: pages, widgets, providers; domain: entities, repositories abstratos, usecases; data: models/DTOs, repositories concretos, datasources), procedimento completo para criação de nova feature (12 passos incluindo criar package, pubspec.yaml com resolution workspace, analysis_options, barrel export, camadas domain/data/presentation, routes.dart com GoRoute, registro no app_router, adicionar ao workspace, testes), diferença entre Entity e Model (localização, propósito, dependências, serialização), padrão de Use Case (single method, single responsibility), padrão de Repository (interface em domain, implementação em data), organização de Riverpod providers por camada (data → domain → presentation), barrel exports expondo apenas o necessário, e critérios para decisão de criar novo package.
2. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `flutter-clean-architecture.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: flutter-clean-architecture` e `description` relacionada a Clean Architecture e dependências, abordando: organização por feature (não por camada global), estrutura padrão de módulo (data, domain, presentation), regras de dependência em formato tabela (presentation depende de domain, data depende de domain, domain depende apenas de pure Dart), regra de que presentation nunca conhece data e data implementa contratos de domain, e diagrama de fluxo de dependências em Mermaid.

### Requirement 4: Steering Files — Contratos de API

**User Story:** Como engenheiro Flutter mobile, eu quero que os steering files documentem os contratos de APIs backend consumidas pelo app, para que o Kiro conheça endpoints, schemas de request/response, códigos de erro e interfaces de DataSource ao gerar ou modificar código de integração.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `auth-api.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: auth-api` e `description` relacionada a fluxos de autenticação, documentando: base URL por ambiente (dev: `https://auth-service.api.dev.ctvm.montebravo.com.br`), endpoints POST /auth/login (request com email/password, response 200 com email/accessToken, response 401), POST /auth/signup (request com email/password, response 201 vazio, response 400), POST /auth/logout (header Bearer, response 200 vazio, response 401), GET /auth/me (header Bearer, response 200 com email, response 401) e POST /auth/validate-token (header Bearer, response 200/401 vazios), formatos de erro (Problem Details RFC 9110 para 401/403/500, validation errors 400 com map de errors), e interfaces de referência AuthRemoteDataSource e AuthRepository com métodos tipados.
2. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `forgot-password-api.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: forgot-password-api` e `description` relacionada a reset de senha e OTP, documentando: base URL configurável via ApiClient.baseUrl, endpoints POST api/auth/forgot-password (sem auth, request com email, response 200 vazio) e POST api/auth/verify-otp (sem auth, request com email/otp, response 200 vazio), e interface de referência ForgotPasswordRemoteDataSource com métodos sendResetEmail e verifyOtp.
3. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `home-api.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: home-api` e `description` relacionada a home screen (balance, notices), documentando: base URL configurável, endpoints GET api/home/balance (auth Bearer, response 200 com campo balance tipo number) e GET api/home/notices (auth Bearer, response 200 com array notices contendo id, title, body, isRead), tabelas de campos com tipo/required/description, e interface de referência HomeRemoteDataSource com métodos getBalance e getNotices.
4. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `notifications-api.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: notifications-api` e `description` relacionada a notificações, documentando: base URL configurável, endpoints GET api/notifications (auth Bearer, response 200 com array notifications contendo id, title, body, isRead, category, occurredAt), POST api/notifications/{id}/read (auth Bearer, body vazio, response 200) e POST api/notifications/{id}/delete (auth Bearer, body vazio, response 200), e interface de referência NotificationRemoteDataSource com métodos getNotifications, markAsRead e delete.
5. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `profile-api.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: profile-api` e `description` relacionada a perfil de usuário e contas bancárias, documentando: base URL configurável, endpoint GET api/profile (auth Bearer, response 200 com campos name, cpf, accountNumber, email, phone e array accounts com type, bankCode, bankName, agency, accountNumber), tabela de campos com tipo/required/description, e interface de referência ProfileRemoteDataSource com método getProfile.
6. THE Archetype_Mobile_Flutter SHALL incluir um Steering_File `settings-api.md` localizado em `archetypes/mobile-flutter/steering/` com frontmatter YAML contendo `inclusion: auto`, `name: settings-api` e `description` relacionada a configurações e preferências de comunicação, documentando: base URL configurável, endpoints GET api/settings (auth Bearer, response 200 com name, email, phone), GET api/settings/communication-prefs (auth Bearer, response 200 com 6 campos booleanos de preferências) e POST api/settings/communication-prefs (auth Bearer, request com 6 booleanos obrigatórios, response 200 vazio), e interface de referência SettingsRemoteDataSource com métodos getSettings, getCommunicationPrefs e updateCommunicationPrefs.
7. THE cada Steering_File de Contrato_API SHALL conter uma nota de aviso indicando que o contrato é baseado em mocks atuais e deve ser atualizado quando o backend confirmar o contrato final (exceto `auth-api.md` que documenta URLs reais de ambiente).

### Requirement 5: Hook de Análise Estática Dart

**User Story:** Como engenheiro Flutter mobile, eu quero que `dart analyze` seja executado automaticamente ao salvar qualquer arquivo Dart, para que erros e warnings sejam detectados imediatamente sem consumir créditos de agente.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um Hook `dart-analyze-save.kiro.hook` com campo `enabled` definido como `true`, `name` com valor `"Dart Analyze on Save"`, `version` com valor `"1"`, trigger `when.type` com valor `"fileEdited"`, patterns `["**/*.dart"]` e ação `then.type` com valor `"runCommand"` executando o comando `dart analyze "$KIRO_FILE_PATH"`.
2. WHEN um arquivo `.dart` é editado e salvo, THE Hook `dart-analyze-save.kiro.hook` SHALL executar `dart analyze` no arquivo salvo e exibir o resultado ao desenvolvedor.

### Requirement 6: Hook de Verificação de Imports Relativos

**User Story:** Como engenheiro Flutter mobile, eu quero que imports relativos (`../` ou `./`) sejam detectados automaticamente ao salvar um arquivo Dart, para que a regra obrigatória de imports absolutos `package:` seja reforçada continuamente.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um Hook `check-relative-imports.kiro.hook` com campo `enabled` definido como `true`, `name` com valor `"Check Relative Imports"`, `version` com valor `"1"`, trigger `when.type` com valor `"fileEdited"`, patterns `["**/*.dart"]` e ação `then.type` com valor `"runCommand"` executando um comando grep que busca imports relativos no arquivo salvo.
2. WHEN um arquivo `.dart` contém imports relativos (iniciando com `../` ou `./`), THE Hook `check-relative-imports.kiro.hook` SHALL reportar as linhas com imports relativos e exibir mensagem de erro instruindo o uso de imports absolutos `package:`.
3. IF nenhum import relativo for encontrado no arquivo salvo, THEN THE Hook `check-relative-imports.kiro.hook` SHALL encerrar sem erro e sem produzir saída ao usuário.

### Requirement 7: Hook de Lembrete de Barrel Export

**User Story:** Como engenheiro Flutter mobile, eu quero ser lembrado de exportar novos arquivos públicos no barrel file da feature quando crio arquivos em pages/, routes/ ou widgets/, para que o encapsulamento e a API pública do package sejam mantidos corretamente.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um Hook `barrel-export-reminder.kiro.hook` com campo `enabled` definido como `true`, `name` com valor `"Barrel Export Reminder"`, `version` com valor `"1"`, trigger `when.type` com valor `"fileCreated"`, patterns `["**/lib/**/pages/*.dart", "**/lib/**/routes/*.dart", "**/lib/**/widgets/*.dart"]` e ação `then.type` com valor `"askAgent"`.
2. WHEN um novo arquivo `.dart` é criado dentro de `lib/**/pages/`, `lib/**/routes/` ou `lib/**/widgets/`, THE Hook `barrel-export-reminder.kiro.hook` SHALL instruir o agente a: determinar o package root (ancestral com pubspec.yaml), ler o pubspec.yaml para obter o nome do package, identificar o barrel file em `lib/<package_name>.dart`, verificar se o arquivo já está exportado, e caso NÃO esteja, lembrar o desenvolvedor com mensagem clara indicando o path do arquivo e a linha de export sugerida.
3. THE Hook `barrel-export-reminder.kiro.hook` SHALL NÃO modificar o barrel file automaticamente — apenas lembrar o desenvolvedor da necessidade de exportação.

### Requirement 8: Hook de Scaffold de Arquivo de Teste

**User Story:** Como engenheiro Flutter mobile, eu quero que a infraestrutura de teste seja criada automaticamente quando crio um novo arquivo em usecases/, datasources/, repositories/ ou providers/, para que a estrutura centralizada de mocks e fixtures seja mantida consistentemente.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um Hook `scaffold-test-file.kiro.hook` com campo `enabled` definido como `true`, `name` com valor `"Scaffold Test File"`, `version` com valor `"1"`, trigger `when.type` com valor `"fileCreated"`, patterns `["**/lib/**/usecases/*.dart", "**/lib/**/datasources/*.dart", "**/lib/**/repositories/*.dart", "**/lib/**/providers/*.dart"]` e ação `then.type` com valor `"askAgent"`.
2. WHEN um novo arquivo `.dart` é criado dentro de `lib/**/usecases/`, `lib/**/datasources/`, `lib/**/repositories/` ou `lib/**/providers/`, THE Hook `scaffold-test-file.kiro.hook` SHALL instruir o agente a: determinar o package root, computar o path relativo de lib/ e espelhar sob test/, criar o arquivo de teste com imports de `package:core_dev/core_dev.dart` (mocktail), `package:flutter_test/flutter_test.dart`, o arquivo fonte com import absoluto `package:`, e o barrel de mocks, incluir classe Mock para a dependência primária, main() com setUp() e test() placeholder.
3. THE Hook `scaffold-test-file.kiro.hook` SHALL instruir o agente a criar o arquivo de mock em `test/mocks/` (se não existir) e atualizar o barrel `test/mocks/mocks.dart` para exportar o novo mock e `package:core_dev/core_dev.dart`.
4. THE Hook `scaffold-test-file.kiro.hook` SHALL exigir que o código gerado siga as regras: imports absolutos `package:` (nunca relativos exceto para barrels internos de test como mocks/mocks.dart), mocktail via core_dev exclusivamente, estrutura de test espelhando lib/, nomenclatura `<original_file>_test.dart` e `mock_<class_name_snake_case>.dart`, mocks centralizados (nunca inline), prefer_single_quotes e trailing commas.

### Requirement 9: Hook de Diagnóstico (Kiro Doctor)

**User Story:** Como engenheiro Flutter mobile, eu quero ter um hook de diagnóstico disponível no Kiro para verificar a conformidade do meu projeto com o archetype e o baseline, para identificar desvios sem sair do IDE.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um arquivo `kiro-doctor.kiro.hook` no diretório `hooks/` com formato JSON válido contendo os campos: `enabled` com valor `true`, `name` com valor `"Kiro Doctor"`, `description` (string descritiva em português), `version` com valor `"1"`, `when.type` com valor `"userTriggered"` e `then.type` com valor `"askAgent"` com campo `prompt` contendo as instruções de análise.
2. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a executar as seguintes etapas: (a) ler a estrutura `.kiro/` do projeto (steering, hooks, settings/mcp.json, specs, skills, agents), (b) comparar com as baselines esperadas em `baselines/global/`, (c) identificar o archetype do projeto (mobile-flutter) e comparar com os artefatos esperados em `archetypes/mobile-flutter/`, (d) verificar specs existentes em `.kiro/specs/` listando status, (e) validar aderência arquitetural do código-fonte contra os steering files e (f) gerar o relatório markdown.
3. THE relatório gerado pelo Hook de diagnóstico SHALL incluir 8 seções na seguinte ordem: (1) Resumo com indicadores visuais ✅ OK, ⚠️ Atenção e ❌ Problema, (2) Steering com arquivos presentes, ausentes e extras, (3) Hooks com status configurado, habilitado e ausente, (4) MCP Servers com configurados vs baseline global, (5) Skills com presentes vs esperados, (6) Specs com listagem e status, (7) Arquitetura com desvios identificados e (8) Recomendações com ações sugeridas.
4. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a salvar o relatório com o nome `kiro-doctor-report.md` na raiz do diretório do projeto do usuário.

### Requirement 10: Configuração MCP

**User Story:** Como engenheiro Flutter mobile, eu quero que o archetype defina a configuração MCP com o servidor Dart integrado, para que o arquivo seja mergeado com o baseline global no bootstrap e o Kiro tenha acesso a análise estática e refactoring Dart.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL incluir um arquivo `mcp.json` no diretório `mcp/` que seja um JSON válido contendo: um campo `_comment` (string identificando o propósito como MCPs específicos do archetype mobile-flutter e indicando que é mergeado com o baseline global no bootstrap), um campo `_version` com versão semântica no formato `MAJOR.MINOR.PATCH` e um objeto `mcpServers` contendo ao menos um servidor configurado.
2. THE objeto `mcpServers` do arquivo `mcp.json` do archetype mobile-flutter SHALL conter uma entrada `"dart"` com campo `command` com valor `"dart"`, campo `args` com valor `["mcp-server"]`, campo `disabled` com valor `false` e campo `autoApprove` com array vazio, representando o Dart MCP Server para análise estática, completions e refactoring Dart/Flutter.
3. THE configuração MCP do archetype mobile-flutter SHALL diferir dos archetypes backend-csharp e bff-fastify por conter um servidor MCP funcional (dart mcp-server) em vez de um objeto `mcpServers` vazio, refletindo a disponibilidade nativa do MCP server no ecossistema Dart.

### Requirement 11: Diretório de Agents (Placeholder)

**User Story:** Como mantenedor da plataforma, eu quero que o diretório de agents exista com documentação adequada mesmo sem agents implementados, para que a estrutura esteja pronta para futuras adições e os agents candidatos sejam visíveis.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL conter um diretório `agents/` com um arquivo `README.md` que documenta o propósito dos agents, indica que nenhum agente customizado está definido para este archetype, e lista os candidatos futuros (agente de revisão de arquitetura Clean Architecture, agente de revisão de acessibilidade mobile, agente de revisão de performance Flutter).
2. THE diretório `agents/` SHALL não conter nenhum arquivo de agent funcional (extensão `.md` com frontmatter de agent) na versão atual do archetype, apenas o `README.md` de documentação.

### Requirement 12: Diretório de Skills (Placeholder)

**User Story:** Como mantenedor da plataforma, eu quero que o diretório de skills exista com documentação adequada mesmo sem skills implementadas, para que a estrutura esteja pronta para futuras adições e as skills candidatas sejam visíveis.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL conter um diretório `skills/` com um arquivo `README.md` que documenta o propósito das skills, indica que nenhuma skill está definida para este archetype, e lista as candidatas futuras (gerar feature Clean Architecture completa, gerar use case, gerar datasource + mock, gerar provider Riverpod, gerar página com rota go_router).
2. THE diretório `skills/` SHALL não conter nenhum arquivo de skill funcional (extensão `.md` com frontmatter YAML de skill) na versão atual do archetype, apenas o `README.md` de documentação.

### Requirement 13: Estado de Versionamento

**User Story:** Como mantenedor da plataforma, eu quero que o estado atual de versionamento do archetype mobile-flutter esteja documentado, para que fique claro que o archetype ainda não possui versionamento formal independente e que a versão é referenciada apenas no README e nos READMEs internos.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL NÃO conter um arquivo `VERSION` na raiz do diretório do archetype no estado atual da implementação, diferenciando-se dos archetypes backend-csharp e bff-fastify que possuem versionamento formal.
2. THE Archetype_Mobile_Flutter SHALL NÃO conter um arquivo `CHANGELOG.md` na raiz do diretório do archetype no estado atual da implementação.
3. THE arquivo `README.md` na raiz do archetype SHALL referenciar a versão `0.1.0` como indicação de estado inicial, servindo como referência informal de versão até que o versionamento formal seja implementado.
4. THE cada arquivo `README.md` interno (steering, hooks, agents, skills) SHALL referenciar a mesma versão `0.1.0` e data de última revisão, mantendo consistência interna entre os documentos do archetype.

### Requirement 14: Modos de Injeção dos Steering Files

**User Story:** Como engenheiro Flutter mobile, eu quero que os steering files sejam injetados pelo Kiro no momento correto (sempre, por tipo de arquivo, automaticamente por contexto ou sob demanda), para que o agente tenha contexto relevante sem sobrecarga desnecessária.

#### Acceptance Criteria

1. THE Archetype_Mobile_Flutter SHALL configurar os Steering_Files `coding-standards.md` e `flutter-lints-security.md` com `inclusion: always`, garantindo que sejam carregados em toda interação com o agente independentemente do contexto.
2. THE Archetype_Mobile_Flutter SHALL configurar o Steering_File `flutter_best_practices.md` com `inclusion: fileMatch` e `fileMatchPattern: "**/*.dart"`, garantindo carregamento apenas quando o contexto envolve arquivos Dart.
3. THE Archetype_Mobile_Flutter SHALL configurar o Steering_File `flutter-testing-patterns.md` com `inclusion: fileMatch` e `fileMatchPattern` para `**/*_test.dart` e `**/test/**/*.dart`, garantindo carregamento apenas quando o contexto envolve arquivos de teste.
4. THE Archetype_Mobile_Flutter SHALL configurar o Steering_File `dependency-management.md` com `inclusion: fileMatch` e `fileMatchPattern: "**/pubspec.yaml"`, garantindo carregamento apenas quando o contexto envolve gerenciamento de dependências.
5. THE Archetype_Mobile_Flutter SHALL configurar os Steering_Files `clean-architecture.md`, `flutter-clean-architecture.md`, `design-system.md`, `auth-api.md`, `forgot-password-api.md`, `home-api.md`, `notifications-api.md`, `profile-api.md` e `settings-api.md` com `inclusion: auto`, garantindo carregamento automático quando o Kiro identifica que o contexto da conversa é relevante para o tema do steering.
6. THE Archetype_Mobile_Flutter SHALL configurar o Steering_File `code-review.md` com `inclusion: manual`, garantindo carregamento apenas quando o desenvolvedor solicita explicitamente via comando no chat.
