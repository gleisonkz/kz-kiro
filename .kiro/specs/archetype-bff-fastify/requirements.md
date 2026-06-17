# Requirements Document

## Introduction

O Archetype BFF Fastify é o pacote de configuração Kiro para projetos BFF (Backend for Frontend) com Fastify + TypeScript da organização MonteBravo. Ele fornece steering files específicos da stack, hooks de automação, skills de geração de código e configuração MCP, garantindo que projetos BFF sigam os padrões arquiteturais definidos nas RFC-0013 (Framework padrão para BFFs) e RFC-0014 (Estrutura e Organização dos BFFs). O archetype é versionado independentemente, distribuído via bootstrap.sh e sincronizado via sync.sh.

## Glossary

- **Archetype_BFF_Fastify**: Pacote de configuração Kiro para projetos BFF Fastify/TypeScript, localizado em `archetypes/bff-fastify/`, contendo steering files, hooks, skills e configuração MCP.
- **Steering_File**: Documento markdown injetado pelo Kiro como contexto nas interações com o agente, contendo diretrizes técnicas específicas da stack BFF Fastify.
- **Hook**: Arquivo JSON com extensão `.kiro.hook` que define uma automação do Kiro, contendo campos `name`, `when` (trigger) e `then` (ação a executar).
- **Skill**: Documento markdown com frontmatter YAML (`name`, `description`, `inclusion: manual`) que define um prompt estruturado para geração de código sob demanda.
- **MCP_Config**: Arquivo `mcp.json` no diretório `mcp/` do archetype que declara servidores MCP específicos para projetos BFF Fastify.
- **VERSION_File**: Arquivo texto na raiz do archetype contendo a versão atual no formato `MAJOR.MINOR.PATCH`.
- **CHANGELOG_File**: Arquivo markdown na raiz do archetype documentando o histórico de mudanças por versão.
- **Projeto_BFF**: Projeto de produto que utiliza o archetype bff-fastify como configuração Kiro.
- **Módulo_BFF**: Bounded context registrado como plugin Fastify com encapsulamento, agrupando rotas, schemas, services e mappers de um domínio da vertical de negócio.
- **Vertical_de_Negócio**: Segmento organizacional (ex.: cliente, assessor) que possui seu próprio BFF dedicado, atendendo múltiplos canais.

## Requirements

### Requirement 1: Composição e Estrutura do Archetype

**User Story:** Como mantenedor da plataforma, eu quero que o archetype bff-fastify tenha uma estrutura bem definida de artefatos organizados por categoria, para que projetos BFF recebam um conjunto completo e consistente de configurações Kiro.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL conter um diretório `steering/` com no mínimo 4 Steering_Files em formato markdown (extensão `.md`) cobrindo os temas de arquitetura, stack/tooling, convenções de nomenclatura e CI/CD.
2. THE Archetype_BFF_Fastify SHALL conter um diretório `hooks/` com no mínimo 1 Hook em formato JSON (extensão `.kiro.hook`) que automatiza verificações ou ações disparadas por eventos do fluxo de desenvolvimento.
3. THE Archetype_BFF_Fastify SHALL conter um diretório `agents/` com um arquivo `README.md` documentando o propósito do diretório e os agents planejados, mesmo quando nenhum agent funcional estiver implementado.
4. THE Archetype_BFF_Fastify SHALL conter um diretório `skills/` com no mínimo 1 Skill em formato markdown (extensão `.md`) que define um prompt estruturado para geração de código.
5. THE Archetype_BFF_Fastify SHALL conter um diretório `mcp/` com um arquivo `mcp.json` declarando a configuração MCP específica para projetos BFF Fastify.
6. THE Archetype_BFF_Fastify SHALL conter um VERSION_File na raiz com exatamente uma linha contendo a versão atual no formato Semantic Versioning `MAJOR.MINOR.PATCH` onde MAJOR, MINOR e PATCH são inteiros não-negativos sem zeros à esquerda.
7. THE Archetype_BFF_Fastify SHALL conter um CHANGELOG_File na raiz documentando o histórico de mudanças por versão, com ao menos uma entrada correspondente a uma versão do archetype.
8. THE Archetype_BFF_Fastify SHALL conter um arquivo `README.md` na raiz do archetype documentando propósito, estrutura, stack, princípios arquiteturais e instruções de uso.
9. THE Archetype_BFF_Fastify SHALL conter um arquivo `README.md` em cada diretório de categoria (`steering/`, `hooks/`, `agents/`, `skills/`) documentando os artefatos disponíveis naquela categoria, sua finalidade e status.

### Requirement 2: Steering Files — Conteúdo e Cobertura

**User Story:** Como engenheiro de BFF, eu quero que os steering files cubram todos os aspectos técnicos relevantes para projetos BFF Fastify, para que o Kiro tenha contexto suficiente para orientar decisões de acordo com os padrões arquiteturais da organização.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL incluir um Steering_File `stack-and-tooling.md` localizado em `archetypes/bff-fastify/steering/` contendo seções identificáveis que abordem: a definição da stack base obrigatória (Node.js 20 LTS, Fastify 5.x, TypeScript 5.x strict, Zod, fastify-type-provider-zod, fastify-plugin, @fastify/cors, @fastify/helmet, @fastify/rate-limit, @fastify/swagger, @fastify/swagger-ui, Pino, Vitest, ESLint + Prettier, tsx, tsup, pnpm), a justificativa da escolha do Fastify (RFC-0013), a justificativa da escolha do Zod (RFC-0014), os padrões de módulo ESM-first, a configuração TypeScript, os scripts padrão do package.json, os packages compartilhados entre BFFs (`bff-core`, `bff-clients`, `bff-contracts`, `bff-test-utils`), a configuração de ambiente (variáveis obrigatórias), a configuração Docker (Dockerfile multi-stage) e a lista de tecnologias descartadas com justificativa (Express, Hono, NestJS, Next.js Route Handlers, TypeBox, class-validator, Axios, Jest, CommonJS).
2. THE Archetype_BFF_Fastify SHALL incluir um Steering_File `architecture.md` localizado em `archetypes/bff-fastify/steering/` contendo seções identificáveis que abordem: o papel arquitetural do BFF (composição, orquestração, transformação, normalização), os princípios fundamentais (BFF por vertical, multi-canal, repositório próprio, ownership compartilhado, espelhamento modular, ownership por módulo, zero regras de negócio, contratos explícitos, consistência via convenção), o posicionamento no repositório, a arquitetura interna (monólito modular com módulos alinhados a bounded contexts), a definição de módulo como plugin Fastify, a anatomia de um módulo (routes, schemas, services, mapper, index.ts), o fluxo de uma request, os padrões de agregação (paralela, com degradação graciosa, sequencial), as regras de fronteira entre módulos, os padrões de resiliência (circuit breaker, timeout por camada), observabilidade (logs estruturados, métricas, tracing), health checks (liveness e readiness) e versionamento de API (prefixo `/api/v1/`).
3. THE Archetype_BFF_Fastify SHALL incluir um Steering_File `naming-conventions.md` localizado em `archetypes/bff-fastify/steering/` contendo seções identificáveis que abordem: princípios gerais de nomenclatura, regra de idioma (inglês para código, português para documentação), diretórios em `kebab-case`, arquivos em `kebab-case` com tabela de sufixos por tipo (`.schema.ts`, `.service.ts`, `.mapper.ts`, `.types.ts`, `.config.ts`, `.test.ts`, `.fixture.ts`, `.constants.ts`, `.plugin.ts`), nomenclatura de módulos, rotas (URLs em kebab-case com prefixo `/api/v1/`), schemas Zod, funções (camelCase), classes (PascalCase com sufixos `Service` e `Client`), variáveis e constantes (camelCase e SCREAMING_SNAKE_CASE), tipos e interfaces (PascalCase sem prefixos, sufixos `DTO`, `Response`, `Config`, `Options`), plugins Fastify (sufixo `Plugin`) e variáveis de ambiente (SCREAMING_SNAKE_CASE com prefixos por contexto).
4. THE Archetype_BFF_Fastify SHALL incluir um Steering_File `ci-cd.md` localizado em `archetypes/bff-fastify/steering/` contendo seções identificáveis que abordem: princípios de CI/CD (deploy independente, imutabilidade, rollback rápido, zero downtime), estratégia de pipeline com checks por estágio (PR: lint, format, typecheck, testes unitários, testes de integração, build, audit de dependências; merge em main: build Docker, push para registry, deploy automático para `dev`; release: deploy para `hml` e `prod` com aprovação), ambientes (dev, hml, prod) com políticas de deploy, container e infraestrutura (imagem Docker node:20-alpine multi-stage, orquestração via ECS/Kubernetes, mínimo 2 réplicas em produção, auto-scaling), variáveis de ambiente via secrets manager e monitoramento pós-deploy (taxa de erro < 1%, latência p99, health check, rollback automático).
5. THE Archetype_BFF_Fastify SHALL incluir um Steering_File `README.md` localizado em `archetypes/bff-fastify/steering/` que define o propósito dos steering files, o que é o BFF (responsabilidades e anti-responsabilidades), o modelo de BFF por vertical multi-canal, a stack padrão em formato de tabela, a estrutura de pastas padrão, os packages compartilhados, os padrões de comunicação com serviços downstream (timeout, retry, circuit breaker, correlation ID), o error model padronizado, os padrões de código (módulos como plugins, rotas, schemas Zod, services, mappers, registro no servidor), as regras de fronteira entre módulos, padrões de teste e o checklist do que o Kiro deve verificar.

### Requirement 3: Hooks de Qualidade de Código

**User Story:** Como engenheiro de BFF, eu quero que hooks automáticos garantam lint e type-checking contínuos durante o fluxo de desenvolvimento, para que problemas de formatação e tipagem sejam detectados rapidamente sem intervenção manual.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL incluir um Hook `lint-after-agent.kiro.hook` com trigger `agentStop` e ação `askAgent` que verifica se houve criação ou edição de arquivos `.ts` dentro de `src/` na sessão e, em caso positivo, executa o comando `pnpm lint` e reporta apenas erros.
2. THE Hook `lint-after-agent.kiro.hook` SHALL ter o campo `enabled` definido como `true`, versão `"2"`, e o prompt condicional que instrui o agente a não fazer nada e não comentar caso nenhum arquivo `.ts` dentro de `src/` tenha sido criado ou editado na sessão.
3. THE Archetype_BFF_Fastify SHALL incluir um Hook `typecheck-on-save.kiro.hook` com trigger `agentStop` e ação `askAgent` que verifica se houve criação ou edição de arquivos `.ts` dentro de `src/` na sessão e, em caso positivo, executa o comando `pnpm typecheck` e reporta apenas erros de tipo.
4. THE Hook `typecheck-on-save.kiro.hook` SHALL ter o campo `enabled` definido como `true`, versão `"2"`, e o prompt condicional que instrui o agente a não fazer nada e não comentar caso nenhum arquivo `.ts` dentro de `src/` tenha sido criado ou editado na sessão.
5. IF nenhum arquivo `.ts` dentro de `src/` tiver sido criado ou editado na sessão, THEN THE Hook (`lint-after-agent.kiro.hook` ou `typecheck-on-save.kiro.hook`) SHALL não ser ativado, não executar nenhum comando e não produzir nenhuma saída ao usuário.

### Requirement 4: Hooks de Revisão Arquitetural

**User Story:** Como engenheiro de BFF, eu quero que hooks inteligentes revisem automaticamente a qualidade das rotas e as fronteiras arquiteturais do BFF, para que violações de padrões sejam identificadas proativamente.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL incluir um Hook `review-route-quality.kiro.hook` com trigger `agentStop`, campo `enabled` definido como `true`, versão `"2"` e ação `askAgent` que verifica se houve escrita em arquivos `.ts` dentro de `src/modules/**/routes/` ou `src/modules/**/schemas/` e, em caso positivo, revisa: schemas Zod para toda rota (querystring, params, body, response com tipos inferidos via z.infer), separação de responsabilidades (handlers delegam para services sem lógica de orquestração direta), plugin pattern (rotas exportadas como FastifyPluginAsync e registradas via fastify.register()), error handling (sem try/catch genérico que engole erros), nomenclatura (arquivo de rota como `<verbo>-<recurso>.ts`, schema como `<route-name>.schema.ts`) e prefixo de módulo.
2. THE Archetype_BFF_Fastify SHALL incluir um Hook `review-bff-boundaries.kiro.hook` com trigger `agentStop`, campo `enabled` definido como `true`, versão `"2"` e ação `askAgent` que verifica se houve escrita em arquivos `.ts` dentro de `src/modules/` e, em caso positivo, revisa as fronteiras arquiteturais baseado na RFC-0014: o BFF não deve conter regras de negócio de domínio (apenas composição, orquestração e transformação), services devem apenas orquestrar chamadas a clients via `fastify.clients.*` e aplicar mappers, mappers devem ser funções puras sem side effects, rotas não devem conter lógica de orquestração, não deve haver acesso direto a banco de dados (BFF stateless), validações devem ser apenas de contrato (schema Zod), módulos não devem importar implementações internas de outros módulos, e comunicação entre módulos deve ocorrer via contratos explícitos ou composição na camada `app/`.
3. WHEN um Hook de revisão arquitetural identifica violações, THE Hook SHALL instruir o agente a sugerir correções específicas para cada violação encontrada.
4. WHEN nenhum arquivo relevante (conforme os padrões de cada hook) tiver sido criado ou editado na sessão, THE Hook de revisão arquitetural SHALL simplesmente não ser ativado, sem enviar instruções ao agente.

### Requirement 5: Hook de Execução de Testes

**User Story:** Como engenheiro de BFF, eu quero que testes sejam executados automaticamente após a conclusão de tasks de spec, para que a qualidade do código seja mantida continuamente.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL incluir um Hook `run-tests-after-task.kiro.hook` com trigger `postTaskExecution`, campo `enabled` definido como `true` por padrão (podendo ser desabilitado pelo desenvolvedor quando necessário durante debugging), versão `"1"` e ação do tipo `runCommand` que executa o comando `pnpm test` automaticamente após a conclusão de uma task de spec.

### Requirement 6: Hook de Diagnóstico (Kiro Doctor)

**User Story:** Como engenheiro de BFF, eu quero ter um hook de diagnóstico disponível no Kiro para verificar a conformidade do meu projeto com o archetype e o baseline, para identificar desvios sem sair do IDE.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL incluir um arquivo `kiro-doctor.kiro.hook` no diretório `hooks/` com formato JSON válido contendo os campos: `enabled` com valor `true`, `name` com valor `"Kiro Doctor"`, `description` (string descritiva), `version` com valor `"1"`, `when.type` com valor `"userTriggered"` e `then.type` com valor `"askAgent"` com campo `prompt` contendo as instruções de análise.
2. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a executar as seguintes etapas: (a) ler a estrutura `.kiro/` do projeto (steering, hooks, settings/mcp.json, specs, skills, agents), (b) comparar com as baselines esperadas em `baselines/global/`, (c) identificar o archetype do projeto (bff-fastify) e comparar com os artefatos esperados em `archetypes/bff-fastify/`, (d) verificar specs existentes em `.kiro/specs/` listando status, (e) validar aderência arquitetural do código-fonte contra os steering files e (f) gerar o relatório markdown.
3. THE relatório gerado pelo Hook de diagnóstico SHALL incluir 8 seções na seguinte ordem: (1) Resumo com indicadores visuais ✅ OK, ⚠️ Atenção e ❌ Problema, (2) Steering com arquivos presentes, ausentes e extras, (3) Hooks com status configurado, habilitado e ausente, (4) MCP Servers com configurados vs baseline global, (5) Skills com presentes vs esperados, (6) Specs com listagem e status, (7) Arquitetura com desvios identificados e (8) Recomendações com ações sugeridas.
4. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a salvar o relatório com o nome `kiro-doctor-report.md` na raiz do diretório do projeto do usuário.

### Requirement 7: Skills de Geração de Código

**User Story:** Como engenheiro de BFF, eu quero ter skills disponíveis para gerar código padronizado sob demanda, para que módulos, clients HTTP e plugins Fastify sejam criados seguindo todos os padrões do archetype automaticamente.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL incluir um arquivo `generate-module.md` no diretório `skills/` que instrui a geração da estrutura completa de um módulo BFF com todos os seguintes artefatos: plugin Fastify do módulo (`index.ts`), registro de rotas (`routes/index.ts`), arquivo(s) de rota com handler (`routes/<verbo>-<recurso>.ts`), schema(s) Zod com tipos inferidos (`schemas/<route-name>.schema.ts`), service de orquestração (`services/<domain>.service.ts`) e mapper de transformação (`services/<domain>.mapper.ts`), seguindo os padrões de nomenclatura em kebab-case, separação de responsabilidades (rotas delegam para services, services orquestram clients e aplicam mappers, mappers são funções puras) e a estrutura definida na RFC-0014. A skill é considerada válida apenas quando capaz de gerar o conjunto completo de artefatos.
2. THE Archetype_BFF_Fastify SHALL incluir um arquivo `generate-client.md` no diretório `skills/` que instrui a geração de um client HTTP tipado para comunicação com serviço downstream, com os seguintes padrões: timeout configurável (padrão 5000ms), retry com backoff exponencial para erros transientes, circuit breaker para proteção contra serviços degradados, propagação de correlation ID via header `x-correlation-id`, DTOs tipados, uso de `undici` ou `fetch` nativo (não Axios), registro como decorator Fastify via `fastify.decorate('clients', {...})` com tipagem via `declare module 'fastify'`, e localização no package compartilhado `@monte-bravo/bff-clients` (preferido) ou localmente em `src/app/plugins/clients.ts`.
3. THE Archetype_BFF_Fastify SHALL incluir um arquivo `generate-plugin.md` no diretório `skills/` que instrui a geração de um plugin Fastify encapsulado, com os seguintes padrões que devem ser refletidos tanto na documentação da skill quanto no código gerado: localização em `src/app/plugins/`, nomenclatura do arquivo pela responsabilidade em kebab-case, função exportada em camelCase com sufixo `Plugin`, uso de `fastify-plugin` (`fp`) para plugins globais que devem ser acessíveis fora do escopo de encapsulamento, tipagem de decorators via `declare module 'fastify'`, documentação via JSDoc e testabilidade via `fastify.inject()`.
4. THE cada arquivo de Skill no diretório `skills/` SHALL iniciar com frontmatter YAML delimitado por `---` contendo exatamente os campos `name` (string com nome exibível em português), `description` (string descrevendo o que a skill gera) e `inclusion` com valor `"manual"`.

### Requirement 8: Configuração MCP

**User Story:** Como engenheiro de BFF, eu quero que o archetype defina a configuração MCP base para projetos BFF Fastify, para que o arquivo seja mergeado com o baseline global no bootstrap.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL incluir um arquivo `mcp.json` no diretório `mcp/` que seja um JSON válido contendo: um campo `_comment` (string identificando o propósito como MCPs específicos do archetype bff-fastify e indicando que é mergeado com o baseline global no bootstrap), um campo `_version` com versão semântica no formato `MAJOR.MINOR.PATCH` e um objeto `mcpServers` (que pode estar vazio quando não há servidores MCP específicos para a stack).
2. THE objeto `mcpServers` do arquivo `mcp.json` do archetype bff-fastify SHALL estar vazio (`{}`), indicando que não há servidores MCP específicos adicionais além dos definidos no baseline global.

### Requirement 9: Diretório de Agents (Placeholder)

**User Story:** Como mantenedor da plataforma, eu quero que o diretório de agents exista com documentação adequada mesmo sem agents implementados, para que a estrutura esteja pronta para futuras adições e os agents planejados sejam visíveis.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL conter um diretório `agents/` com um arquivo `README.md` que documenta o propósito dos agents, lista os agents planejados com nome, especialidade e status (marcados como "Não implementado"), e mantém a estrutura preparada para adições futuras.
2. THE diretório `agents/` SHALL não conter nenhum arquivo de agent funcional (extensão `.md` com frontmatter de agent) na versão atual do archetype, apenas o `README.md` de documentação.

### Requirement 10: Versionamento e Changelog

**User Story:** Como mantenedor da plataforma, eu quero que o archetype bff-fastify siga versionamento semântico com changelog documentado, para que projetos consumidores saibam quando uma atualização pode impactar sua configuração.

#### Acceptance Criteria

1. THE Archetype_BFF_Fastify SHALL manter um arquivo `VERSION` na raiz do diretório do archetype contendo a versão no formato `MAJOR.MINOR.PATCH`, onde cada segmento é um inteiro não-negativo (0 ou maior) sem zeros à esquerda (exceto o próprio 0), validado como inteiro numérico não-negativo.
2. THE Archetype_BFF_Fastify SHALL manter um arquivo `CHANGELOG.md` na raiz do diretório do archetype, organizado com a versão mais recente no topo do arquivo.
3. WHEN um novo Steering_File é adicionado ao archetype, uma nova Skill é adicionada ou uma nova diretriz é incluída em um Steering_File existente sem alterar nem remover diretrizes existentes, THE Mantenedor SHALL incrementar o dígito MINOR em 1 e redefinir PATCH para 0, mantendo MAJOR inalterado.
4. WHEN um Steering_File é removido, um Steering_File é renomeado ou um Hook é removido do archetype, THE Mantenedor SHALL incrementar o dígito MAJOR em 1 e redefinir MINOR e PATCH para 0.
5. WHEN uma correção de texto em steering/skills, refinamento de prompt em hooks ou ajuste de valor em configuração MCP é aplicado sem adicionar, remover ou alterar diretrizes comportamentais, THE Mantenedor SHALL incrementar o dígito PATCH em 1, mantendo MAJOR e MINOR inalterados.
6. IF uma release contém mudanças que se enquadram em mais de uma categoria de incremento (ex: adicionar um steering file e remover outro na mesma release), THEN THE Mantenedor SHALL aplicar apenas o incremento de maior precedência (MAJOR > MINOR > PATCH).
