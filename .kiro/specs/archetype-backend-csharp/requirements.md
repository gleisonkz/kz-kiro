# Requirements Document

## Introduction

O Archetype Backend C# é o pacote de configuração Kiro para projetos de serviços de domínio (backend) com .NET/C# da organização MonteBravo. Ele fornece steering files específicos da stack, hooks de automação, skills de geração de código e configuração MCP, garantindo que projetos backend C# sigam os padrões arquiteturais definidos nas RFC-001 (Padrões arquiteturais), RFC-002 (Steering File para backend), RFC-003 (Outbox/Inbox), ADR-001 (Comunicação entre serviços) e Guia de Padrões de Nomeação. O archetype é versionado independentemente, distribuído via bootstrap.sh e sincronizado via sync.sh.

## Glossary

- **Archetype_Backend_CSharp**: Pacote de configuração Kiro para projetos backend .NET/C#, localizado em `archetypes/backend-csharp/`, contendo steering files, hooks, skills e configuração MCP.
- **Steering_File**: Documento markdown injetado pelo Kiro como contexto nas interações com o agente, contendo diretrizes técnicas específicas da stack backend C#/.NET.
- **Hook**: Arquivo JSON com extensão `.kiro.hook` que define uma automação do Kiro, contendo campos `name`, `when` (trigger) e `then` (ação a executar).
- **Skill**: Documento markdown com frontmatter YAML (`name`, `description`, `inclusion: manual`) que define um prompt estruturado para geração de código sob demanda.
- **MCP_Config**: Arquivo `mcp.json` no diretório `mcp/` do archetype que declara servidores MCP específicos para projetos backend C#.
- **VERSION_File**: Arquivo texto na raiz do archetype contendo a versão atual no formato `MAJOR.MINOR.PATCH`.
- **CHANGELOG_File**: Arquivo markdown na raiz do archetype documentando o histórico de mudanças por versão.
- **Projeto_Backend_CSharp**: Projeto de produto que utiliza o archetype backend-csharp como configuração Kiro.
- **Clean_Architecture**: Padrão arquitetural com separação em camadas (Api, Application, Domain, Infrastructure) e Dependency Rule rigorosa.
- **CQRS**: Command Query Responsibility Segregation — separação entre operações de leitura (Queries) e escrita (Commands) via MediatR.
- **Bounded_Context**: Domínio de negócio coeso e autônomo encapsulado por um serviço de domínio, com banco de dados próprio.
- **Chapter_de_Dados**: Órgão de governança interno da MonteBravo responsável por validar e aprovar modelos de dados antes da execução pelo DBA.
- **Outbox_Inbox_Pattern**: Padrão para garantir consistência entre banco de dados e mensageria em transações distribuídas, implementado via Wolverine.

## Requirements

### Requirement 1: Composição e Estrutura do Archetype

**User Story:** Como mantenedor da plataforma, eu quero que o archetype backend-csharp tenha uma estrutura bem definida de artefatos organizados por categoria, para que projetos backend C# recebam um conjunto completo e consistente de configurações Kiro.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL conter um diretório `steering/` com exatamente 5 Steering_Files em formato markdown (extensão `.md`) cobrindo os temas de arquitetura (`architecture.md`), stack e ferramental (`stack-and-tooling.md`), convenções de nomenclatura (`naming-conventions.md`), CI/CD (`ci-cd.md`) e governança de dados (`data-governance.md`).
2. THE Archetype_Backend_CSharp SHALL conter um diretório `hooks/` com exatamente 7 Hooks em formato JSON (extensão `.kiro.hook`) que automatizam verificações e ações disparadas por eventos do fluxo de desenvolvimento.
3. THE Archetype_Backend_CSharp SHALL conter um diretório `agents/` com um arquivo `README.md` documentando o propósito do diretório e os agents planejados, mesmo quando nenhum agent funcional estiver implementado.
4. THE Archetype_Backend_CSharp SHALL conter um diretório `skills/` com exatamente 5 Skills em formato markdown (extensão `.md`) que definem prompts estruturados para geração de código.
5. THE Archetype_Backend_CSharp SHALL conter um diretório `mcp/` com um arquivo `mcp.json` declarando a configuração MCP específica para projetos backend C#.
6. THE Archetype_Backend_CSharp SHALL conter um VERSION_File na raiz com exatamente uma linha contendo a versão atual no formato Semantic Versioning `MAJOR.MINOR.PATCH` onde MAJOR, MINOR e PATCH são inteiros não-negativos sem zeros à esquerda.
7. THE Archetype_Backend_CSharp SHALL conter um CHANGELOG_File na raiz documentando o histórico de mudanças por versão, com ao menos uma entrada correspondente a uma versão do archetype.
8. THE Archetype_Backend_CSharp SHALL conter um arquivo `README.md` na raiz do archetype documentando propósito, estrutura, stack, princípios arquiteturais, instruções de uso e referências.
9. THE Archetype_Backend_CSharp SHALL conter um arquivo `README.md` em cada diretório de categoria (`steering/`, `hooks/`, `agents/`, `skills/`) documentando os artefatos disponíveis naquela categoria, sua finalidade e status.

### Requirement 2: Steering Files — Conteúdo e Cobertura

**User Story:** Como engenheiro backend C#, eu quero que os steering files cubram todos os aspectos técnicos relevantes para projetos .NET/C#, para que o Kiro tenha contexto suficiente para orientar decisões de acordo com os padrões arquiteturais da organização.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um Steering_File `stack-and-tooling.md` localizado em `archetypes/backend-csharp/steering/` contendo seções identificáveis que abordem: a definição da stack base obrigatória (.NET 8 LTS, C# 12 com nullable reference types, ASP.NET Core Minimal APIs, Entity Framework Core 8, PostgreSQL, FluentValidation, MediatR, Wolverine, Serilog, AWS CloudWatch, AWS X-Ray, Swashbuckle, Polly, xUnit, Moq, FluentAssertions, Testcontainers, Docker), a infraestrutura AWS preferida (Lambda ARM64, API Gateway, RDS/Aurora, S3, SQS, EventBridge, Secrets Manager), a justificativa da escolha de Minimal APIs, a justificativa da escolha de Wolverine para Outbox/Inbox (RFC-003), a configuração dos projetos .csproj (nullable enable, TreatWarningsAsErrors), a configuração padrão do Program.cs, os scripts e comandos padrão, a configuração de ambiente e Docker, as regras de segurança (RFC-002) e a lista de tecnologias descartadas com justificativa (Controllers MVC, NHibernate, Autofac, NSubstitute, NUnit/MSTest, Newtonsoft.Json, RestSharp, log4net/NLog, SQL Server, EC2, float/double para dinheiro).
2. THE Archetype_Backend_CSharp SHALL incluir um Steering_File `architecture.md` localizado em `archetypes/backend-csharp/steering/` contendo seções identificáveis que abordem: o papel arquitetural do serviço de domínio (encapsular regras de negócio, persistência e eventos), os princípios fundamentais (Bounded Context isolado, Database per Service, comunicação via mensageria, Outbox/Inbox, CQRS, Dependency Rule, contratos explícitos, independência de deploy), os padrões arquiteturais aceitos pela RFC-001 (Clean Architecture, Vertical Sliced Architecture, Hexagonal Architecture) com critérios de escolha, a comunicação entre serviços via mensageria coreografada (ADR-001), o Outbox/Inbox Pattern (RFC-003) com Wolverine, o padrão CQRS com MediatR (Commands e Queries), Domain-Driven Design (entidades com comportamento, value objects, eventos de domínio), a persistência com EF Core + PostgreSQL incluindo referência ao steering de governança de dados, resiliência com Polly, observabilidade (logs estruturados, tracing, métricas), health checks e glossário de termos financeiros.
3. THE Archetype_Backend_CSharp SHALL incluir um Steering_File `naming-conventions.md` localizado em `archetypes/backend-csharp/steering/` contendo seções identificáveis que abordem: princípios gerais de nomenclatura seguindo convenções oficiais do .NET, regra de idioma (inglês para código, português para documentação), padrões de banco de dados (duas camadas — PascalCase para C# e snake_case com prefixo de natureza para banco), nomenclatura de tabelas (snake_case, singular, inglês) e colunas (snake_case com prefixo obrigatório), tabela de prefixos de natureza (id, nm, cd, ds, dt, hr, tmp, vl, qt, pc, st, nu, in), nomenclatura de projetos/solution (PascalCase com pontos: `MonteBravo.{ServiceName}.{Layer}`), diretórios (PascalCase), arquivos (PascalCase com tabela de sufixos por camada com no mínimo 20 tipos mapeados), namespaces, classes e records, interfaces (prefixo `I`), métodos (PascalCase com sufixo Async), propriedades, campos privados (_camelCase), parâmetros e variáveis locais (camelCase), constantes (PascalCase), enums (PascalCase singular), endpoints/URLs (kebab-case com prefixo `/api/v1/`), glossário de termos financeiros, tipagem para valores financeiros (decimal obrigatório, nunca float/double) e convenções de testes.
4. THE Archetype_Backend_CSharp SHALL incluir um Steering_File `ci-cd.md` localizado em `archetypes/backend-csharp/steering/` contendo seções identificáveis que abordem: princípios de CI/CD (deploy independente, imutabilidade, rollback rápido, zero downtime, migrations seguras), pipeline preferido (GitHub Actions como 1ª opção, AWS CodePipeline como 2ª), steps obrigatórios por estágio (PR: restore, build, format, testes unitários, testes de integração, análise de segurança, cobertura 80%; merge em main: build de artefato, push para registry, deploy automático para dev; release: deploy para hml e prod com aprovação), review rules que bloqueiam merge (missing_tests, security_violation, breaking_change_without_note, no_async_usage), ambientes (dev, hml, prod), deploy targets (AWS Lambda ARM64 como preferido, ECS Fargate como alternativa), regras de migrations de banco (backward-compatible, expand-contract pattern), variáveis de ambiente e segredos (AWS Secrets Manager/SSM), monitoramento pós-deploy (taxa de erro < 1%, latência p99, health check, rollback automático) e documentação obrigatória (README.md, arquitetura.md, endpoints.md).
5. THE Archetype_Backend_CSharp SHALL incluir um Steering_File `data-governance.md` localizado em `archetypes/backend-csharp/steering/` contendo seções identificáveis que abordem: o princípio fundamental de duas camadas e duas convenções (PascalCase para C#, snake_case com prefixo para banco), nomenclatura de tabelas (snake_case, singular, inglês), nomenclatura de colunas (snake_case com prefixo de natureza obrigatório no formato `{prefixo}_{nome}`), tabela completa de naturezas/prefixos obrigatórios (nm, cd, ds, dt, hr, tmp, vl, qt, pc, id, st, nu, in, sk) com significado e tipos comuns, campos de auditoria obrigatórios (`tmp_creation` NOT NULL e `tmp_update` nullable), comments obrigatórios em pt-BR via `HasComment()` para toda tabela e coluna, convenções de constraints e índices (pk_, fk_, ix_, uk_, ak_), regra absoluta de valores monetários (`decimal` em C#, `DECIMAL(18,8)` em banco, nunca float/double), normalização em 3ª Forma Normal (3FN), migrations como versionamento (não execução automática, fluxo dev→chapter→DBA), escopo limitado a modelo transacional, exemplo completo de Entity Configuration e processo de validação pelo chapter de dados (SLA 1 semana).
6. THE Archetype_Backend_CSharp SHALL incluir um Steering_File `README.md` localizado em `archetypes/backend-csharp/steering/` que define o propósito dos steering files, o que é um serviço de domínio (responsabilidades e anti-responsabilidades), a stack padrão em formato de tabela (RFC-002), a estrutura de pastas padrão em Clean Architecture e alternativa Vertical Sliced, padrões de código (Minimal API endpoints, Commands e Queries com MediatR, Domain Entities), regras de fronteira entre camadas, padrões de teste, checklist do que o Kiro deve verificar e referências.
7. THE Steering_File `data-governance.md` SHALL ser um arquivo distinto e exclusivo do archetype backend-csharp que não existe nos demais archetypes, refletindo a necessidade específica de governança de dados exigida pelo Chapter_de_Dados para serviços com persistência própria em PostgreSQL.
8. THE cada Steering_File do archetype backend-csharp SHALL iniciar diretamente com o conteúdo markdown (cabeçalho de nível 1) sem frontmatter YAML, diferenciando-se de archetypes que usam frontmatter para controle de injeção automática.

### Requirement 3: Hook de Build Automático

**User Story:** Como engenheiro backend C#, eu quero que o build seja executado automaticamente após o agente parar quando houve escrita em arquivos C#, para que erros de compilação sejam detectados imediatamente.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um Hook `build-after-agent.kiro.hook` com trigger `agentStop`, campo `enabled` definido como `true`, versão `"2"` e ação `askAgent` que verifica se houve criação ou edição de arquivos `.cs` nesta sessão e, em caso positivo, executa o comando `dotnet build --no-restore` reportando apenas erros de compilação.
2. IF nenhum arquivo `.cs` tiver sido criado ou editado na sessão, THEN THE Hook `build-after-agent.kiro.hook` SHALL não executar nenhum comando e não produzir nenhuma saída ao usuário.

### Requirement 4: Hooks de Revisão Arquitetural

**User Story:** Como engenheiro backend C#, eu quero que hooks inteligentes revisem automaticamente as fronteiras da Clean Architecture e a qualidade dos endpoints, para que violações de padrões sejam identificadas proativamente.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um Hook `review-domain-boundaries.kiro.hook` com trigger `agentStop`, campo `enabled` definido como `true`, versão `"2"` e ação `askAgent` que verifica se houve criação ou edição de arquivos `.cs` dentro de `src/` na sessão e, em caso positivo, revisa as fronteiras da Clean Architecture: Domain sem dependências externas e sem imports de Application/Infrastructure/Api, Application sem referência a Infrastructure ou Api e sem acesso direto a DbContext, Infrastructure sem regras de negócio de domínio, Api sem lógica de negócio e usando MediatR/ISender para despachar commands/queries, propagação de CancellationToken em operações assíncronas, interfaces em Application/Domain com implementações em Infrastructure, e entidades com construtores privados e factory methods.
2. THE Archetype_Backend_CSharp SHALL incluir um Hook `review-endpoint-quality.kiro.hook` com trigger `agentStop`, campo `enabled` definido como `true`, versão `"2"` e ação `askAgent` que verifica se houve criação ou edição de arquivos que contenham `Endpoint` ou `Endpoints` no nome (*.cs) na sessão e, em caso positivo, revisa: documentação OpenAPI completa (WithName, WithTags, Produces, ProducesProblem), separação de responsabilidades (handler apenas extrai dados e despacha via ISender), CancellationToken recebido e propagado, RequireAuthorization presente (exceto endpoints públicos), nomenclatura correta ({Verb}{Resource}Endpoint.cs), rota seguindo padrão `/api/v1/{resource}` com kebab-case e plural, e validação via FluentValidation no handler (via ValidationBehavior) e não no endpoint.
3. WHEN um Hook de revisão arquitetural identifica violações, THE Hook SHALL instruir o agente a sugerir correções específicas para cada violação encontrada.
4. WHEN nenhum arquivo relevante (conforme os padrões de cada hook) tiver sido criado ou editado na sessão, THE Hook de revisão arquitetural SHALL não fazer nada e não comentar.

### Requirement 5: Hooks de Governança de Dados

**User Story:** Como engenheiro backend C#, eu quero que hooks automáticos validem Entity Configurations contra os padrões do chapter de dados e lembrem de gerar o pacote de validação, para que o modelo de dados esteja sempre em conformidade com a governança.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um Hook `review-data-model.kiro.hook` com trigger `preToolUse` e `toolTypes` `["write"]`, campo `enabled` definido como `true`, versão `"1"` e ação `askAgent` que verifica se a operação de escrita envolve um arquivo que termina com `Configuration.cs` dentro de um diretório `Configurations/` ou `Persistence/` e, em caso positivo, valida o conteúdo contra os padrões do chapter de dados: tabela em snake_case singular inglês com ToTable(), HasComment na tabela em pt-BR, colunas com HasColumnName usando prefixo de natureza obrigatório ({prefixo}_{nome}), HasComment em pt-BR para toda coluna, valores monetários com HasPrecision(18, 8), campos de auditoria tmp_creation e tmp_update, chave primária com HasName("pk_{tabela}"), foreign keys com HasConstraintName("fk_{origem}_{destino}"), e índices com HasDatabaseName("ix_{tabela}_{coluna}").
2. THE Archetype_Backend_CSharp SHALL incluir um Hook `migration-reminder.kiro.hook` com trigger `postToolUse` e `toolTypes` `["write"]`, campo `enabled` definido como `true`, versão `"1"` e ação `askAgent` que verifica se a operação de escrita envolveu um arquivo que termina com `Configuration.cs` dentro de `Configurations/` ou `Persistence/` e, em caso positivo, lembra o desenvolvedor de: gerar a migration via `dotnet ef migrations add`, gerar o pacote de validação usando a skill `generate-validation-package`, e submeter para validação do chapter de dados antes de solicitar execução ao DBA.
3. IF a operação de escrita não envolve um arquivo de Entity Configuration, THEN THE Hook `review-data-model.kiro.hook` SHALL permitir a operação sem comentários.
4. IF a operação de escrita não envolve um arquivo de Entity Configuration, THEN THE Hook `migration-reminder.kiro.hook` SHALL não fazer nada e não comentar.

### Requirement 6: Hook de Execução de Testes

**User Story:** Como engenheiro backend C#, eu quero que testes sejam executados automaticamente após a conclusão de tasks de spec, para que a qualidade do código seja mantida continuamente.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um Hook `run-tests-after-task.kiro.hook` com trigger `postTaskExecution`, campo `enabled` definido como `true`, versão `"2"` e ação do tipo `runCommand` que executa o comando `dotnet test` automaticamente após a conclusão de uma task de spec.

### Requirement 7: Hook de Diagnóstico (Kiro Doctor)

**User Story:** Como engenheiro backend C#, eu quero ter um hook de diagnóstico disponível no Kiro para verificar a conformidade do meu projeto com o archetype e o baseline, para identificar desvios sem sair do IDE.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um arquivo `kiro-doctor.kiro.hook` no diretório `hooks/` com formato JSON válido contendo os campos: `enabled` com valor `true`, `name` com valor `"Kiro Doctor"`, `description` (string descritiva), `version` com valor `"1"`, `when.type` com valor `"userTriggered"` e `then.type` com valor `"askAgent"` com campo `prompt` contendo as instruções de análise.
2. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a executar as seguintes etapas: (a) ler a estrutura `.kiro/` do projeto (steering, hooks, settings/mcp.json, specs, skills, agents), (b) comparar com as baselines esperadas em `baselines/global/`, (c) identificar o archetype do projeto (backend-csharp) e comparar com os artefatos esperados em `archetypes/backend-csharp/`, (d) verificar specs existentes em `.kiro/specs/` listando status, (e) validar aderência arquitetural do código-fonte contra os steering files (Clean Architecture, Dependency Rule, entidades com comportamento) e (f) gerar o relatório markdown.
3. THE relatório gerado pelo Hook de diagnóstico SHALL incluir 8 seções na seguinte ordem: (1) Resumo com indicadores visuais ✅ OK, ⚠️ Atenção e ❌ Problema, (2) Steering com arquivos presentes, ausentes e extras, (3) Hooks com status configurado, habilitado e ausente, (4) MCP Servers com configurados vs baseline global, (5) Skills com presentes vs esperados, (6) Specs com listagem e status, (7) Arquitetura com desvios identificados (Clean Architecture, CQRS, DDD) e (8) Recomendações com ações sugeridas.
4. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a salvar o relatório com o nome `kiro-doctor-report.md` na raiz do diretório do projeto do usuário.

### Requirement 8: Skills de Geração de Código

**User Story:** Como engenheiro backend C#, eu quero ter skills disponíveis para gerar código padronizado sob demanda, para que módulos, endpoints, repositories, modelos de dados e pacotes de validação sejam criados seguindo todos os padrões do archetype automaticamente.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um arquivo `generate-module.md` no diretório `skills/` que instrui a geração da estrutura completa de um módulo de domínio com os seguintes artefatos distribuídos nas camadas da Clean Architecture: endpoint Minimal API com documentação OpenAPI (`{Verb}{Entity}Endpoint.cs` em Api/Endpoints/{Domain}/), registro de endpoints do domínio (`{Domain}Endpoints.cs`), command/query como records imutáveis implementando `IRequest<T>` (em Application/{Domain}/Commands/ ou Queries/), handler com dependências via construtor e CancellationToken (em Application/{Domain}/), validator FluentValidation (em Application/{Domain}/), entidade com comportamento, construtores privados, factory methods e domain events (em Domain/{Domain}/Entities/), enum de status, domain exception, domain events, interface de repository (em Domain/{Domain}/), Entity Configuration com governança de dados e implementação de repository EF Core (em Infrastructure/Persistence/), e testes unitários para domain e application.
2. THE Archetype_Backend_CSharp SHALL incluir um arquivo `generate-endpoint.md` no diretório `skills/` que instrui a geração de um endpoint ASP.NET Core Minimal API com os seguintes padrões: classe estática com método `Map(IEndpointRouteBuilder app)`, handler privado e estático recebendo ISender (MediatR) e CancellationToken, documentação OpenAPI completa (WithName, WithTags, Produces, ProducesProblem), RequireAuthorization por padrão, rota no padrão `/api/v1/{resource}` com kebab-case e plural, nomenclatura `{Verb}{Resource}Endpoint.cs`, mapeamento de verbos HTTP para response codes (GET→200, POST→201, PUT→200, DELETE→204) e separação de responsabilidades (handler apenas extrai dados e despacha).
3. THE Archetype_Backend_CSharp SHALL incluir um arquivo `generate-repository.md` no diretório `skills/` que instrui a geração de um repository com interface no Domain (`I{Entity}Repository`) e implementação EF Core no Infrastructure (`{Entity}Repository`), incluindo: operações padrão (GetByIdAsync, AddAsync, Update, Delete) com CancellationToken, Entity Configuration separada usando Fluent API (não Data Annotations), sem expor IQueryable na interface (retornar coleções materializadas), e registro no container de DI.
4. THE Archetype_Backend_CSharp SHALL incluir um arquivo `generate-data-model.md` no diretório `skills/` que instrui a geração de um modelo de dados completo aderente aos padrões do Chapter_de_Dados, com os seguintes outputs: entidades de domínio com comportamento e factory methods (em Domain/{Domain}/Entities/), Entity Configurations com nomenclatura snake_case, prefixos de natureza obrigatórios, HasComment em pt-BR para toda tabela e coluna, HasPrecision(18,8) para monetários, campos de auditoria tmp_creation e tmp_update, constraints nomeadas (pk_, fk_, ix_) (em Infrastructure/Persistence/Configurations/), comando para gerar migration, script DDL PostgreSQL com COMMENT ON para o DBA (em docs/database/{domain}/ddl.sql), dicionário de dados em markdown (em docs/database/{domain}/data-dictionary.md) e diagrama ER em Mermaid (em docs/database/{domain}/er-diagram.md).
5. THE Archetype_Backend_CSharp SHALL incluir um arquivo `generate-validation-package.md` no diretório `skills/` que instrui a geração do pacote completo para submissão ao Chapter_de_Dados contendo: script DDL PostgreSQL com CREATE TABLE, COMMENT ON TABLE, COMMENT ON COLUMN, constraints e índices (em docs/database/{domain}/ddl.sql), dicionário de dados em markdown com tabela de atributos incluindo natureza, tipo, conceito e constraints (em docs/database/{domain}/data-dictionary.md), diagrama ER em Mermaid (em docs/database/{domain}/er-diagram.md) e checklist de validação com itens de conformidade (em docs/database/{domain}/validation-checklist.md), instruindo o desenvolvedor a enviar para o chapter de dados (SLA 1 semana) e aguardar aprovação antes de solicitar execução ao DBA.
6. THE cada arquivo de Skill no diretório `skills/` SHALL iniciar com frontmatter YAML delimitado por `---` contendo exatamente os campos `name` (string com nome exibível em português), `description` (string descrevendo o que a skill gera) e `inclusion` com valor `"manual"`.

### Requirement 9: Configuração MCP

**User Story:** Como engenheiro backend C#, eu quero que o archetype defina a configuração MCP base para projetos backend C#, para que o arquivo seja mergeado com o baseline global no bootstrap.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL incluir um arquivo `mcp.json` no diretório `mcp/` que seja um JSON válido contendo: um campo `_comment` (string identificando o propósito como MCPs específicos do archetype backend-csharp e indicando que é mergeado com o baseline global no bootstrap), um campo `_version` com versão semântica no formato `MAJOR.MINOR.PATCH` e um objeto `mcpServers` (que pode estar vazio quando não há servidores MCP específicos para a stack).
2. THE objeto `mcpServers` do arquivo `mcp.json` do archetype backend-csharp SHALL estar vazio (`{}`), indicando que não há servidores MCP específicos adicionais além dos definidos no baseline global.

### Requirement 10: Diretório de Agents (Placeholder)

**User Story:** Como mantenedor da plataforma, eu quero que o diretório de agents exista com documentação adequada mesmo sem agents implementados, para que a estrutura esteja pronta para futuras adições e os agents planejados sejam visíveis.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL conter um diretório `agents/` com um arquivo `README.md` que documenta o propósito dos agents, lista os agents planejados com nome, especialidade, capacidades e status (marcados como "Não implementado"), e mantém a estrutura preparada para adições futuras.
2. THE diretório `agents/` SHALL não conter nenhum arquivo de agent funcional (extensão `.md` com frontmatter de agent) na versão atual do archetype, apenas o `README.md` de documentação.
3. THE arquivo `README.md` do diretório `agents/` SHALL listar ao menos 5 agents planejados: `domain-modeler` (modelagem de domínio DDD), `architecture-reviewer` (revisão de Clean Architecture), `api-designer` (design de APIs REST), `test-writer` (geração de testes) e `migration-reviewer` (revisão de migrations).

### Requirement 11: Versionamento e Changelog

**User Story:** Como mantenedor da plataforma, eu quero que o archetype backend-csharp siga versionamento semântico com changelog documentado, para que projetos consumidores saibam quando uma atualização pode impactar sua configuração.

#### Acceptance Criteria

1. THE Archetype_Backend_CSharp SHALL manter um arquivo `VERSION` na raiz do diretório do archetype contendo a versão no formato `MAJOR.MINOR.PATCH`, onde cada segmento é um inteiro não-negativo (0 ou maior) sem zeros à esquerda (exceto o próprio 0).
2. THE Archetype_Backend_CSharp SHALL manter um arquivo `CHANGELOG.md` na raiz do diretório do archetype, organizado com a versão mais recente no topo do arquivo, usando cabeçalho de nível 2 no formato `## MAJOR.MINOR.PATCH (YYYY-MM-DD)` para cada release, com mudanças agrupadas em seções de nível 3 utilizando os nomes: `### Funcionalidades` (feat), `### Correções` (fix), `### Documentação` (docs), `### Refatoração` (refactor), `### Manutenção` (chore), `### Performance` (perf) e `### CI/CD` (ci).
3. WHEN um novo Steering_File é adicionado ao archetype, uma nova Skill é adicionada ou uma nova diretriz é incluída em um Steering_File existente sem alterar nem remover diretrizes existentes, THE Mantenedor SHALL incrementar o dígito MINOR em 1 e redefinir PATCH para 0, mantendo MAJOR inalterado.
4. WHEN um Steering_File é removido, um Steering_File é renomeado ou um Hook é removido do archetype, THE Mantenedor SHALL incrementar o dígito MAJOR em 1 e redefinir MINOR e PATCH para 0.
5. WHEN uma correção de texto em steering/skills, refinamento de prompt em hooks ou ajuste de valor em configuração MCP é aplicado sem adicionar, remover ou alterar diretrizes comportamentais, THE Mantenedor SHALL incrementar o dígito PATCH em 1, mantendo MAJOR e MINOR inalterados.
6. IF uma release contém mudanças que se enquadram em mais de uma categoria de incremento (ex: adicionar um steering file e remover outro na mesma release), THEN THE Mantenedor SHALL aplicar apenas o incremento de maior precedência (MAJOR > MINOR > PATCH).
