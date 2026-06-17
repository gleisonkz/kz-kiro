# Requirements Document

## Introduction

O Archetype Frontend React é o pacote de configuração Kiro para projetos frontend com React/Next.js + TypeScript da organização MonteBravo. Ele fornece steering files específicos da stack, hooks de automação, agents especializados de revisão, skills de geração de código e configuração MCP, garantindo que projetos frontend sigam os padrões arquiteturais, de qualidade e de nomenclatura definidos pela organização. O archetype é versionado independentemente, distribuído via bootstrap.sh e sincronizado via sync.sh.

## Glossary

- **Archetype_Frontend_React**: Pacote de configuração Kiro para projetos frontend React/TypeScript, localizado em `archetypes/frontend-react/`, contendo steering files, hooks, agents, skills e configuração MCP.
- **Steering_File**: Documento markdown com frontmatter YAML injetado pelo Kiro como contexto nas interações com o agente, contendo diretrizes técnicas específicas da stack frontend React.
- **Hook**: Arquivo JSON com extensão `.kiro.hook` que define uma automação do Kiro, contendo campos `name`, `when` (trigger) e `then` (ação a executar).
- **Agent**: Documento markdown com frontmatter YAML (`name`, `description`) que define um agente especializado do Kiro para revisões sob demanda.
- **Skill**: Documento markdown com frontmatter YAML (`name`, `description`, `inclusion: manual`) que define um prompt estruturado para geração de código sob demanda.
- **MCP_Config**: Arquivo `mcp.json` no diretório `mcp/` do archetype que declara servidores MCP específicos para projetos frontend React.
- **VERSION_File**: Arquivo texto na raiz do archetype contendo a versão atual no formato `MAJOR.MINOR.PATCH`.
- **CHANGELOG_File**: Arquivo markdown na raiz do archetype documentando o histórico de mudanças por versão.
- **Projeto_Frontend**: Projeto de produto que utiliza o archetype frontend-react como configuração Kiro.
- **FSD**: Feature-Sliced Design — metodologia de organização interna de código por layers e slices adotada dentro de cada módulo.
- **Módulo**: Bounded context frontend — unidade funcional de negócio com fronteiras explícitas e API pública via `index.ts`.

## Requirements

### Requirement 1: Composição e Estrutura do Archetype

**User Story:** Como mantenedor da plataforma, eu quero que o archetype frontend-react tenha uma estrutura bem definida de artefatos organizados por categoria, para que projetos frontend recebam um conjunto completo e consistente de configurações Kiro.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL conter um diretório `steering/` com no mínimo 1 Steering_File em formato markdown (extensão `.md`) cobrindo ao menos os temas de arquitetura e stack/tooling do projeto frontend React.
2. THE Archetype_Frontend_React SHALL conter um diretório `hooks/` com no mínimo 1 Hook em formato JSON (extensão `.kiro.hook`) que automatiza verificações ou ações disparadas por eventos do fluxo de desenvolvimento.
3. THE Archetype_Frontend_React SHALL conter um diretório `agents/` com no mínimo 1 Agent em formato markdown (extensão `.md`) que define um agente especializado de revisão com escopo e instruções de atuação.
4. THE Archetype_Frontend_React SHALL conter um diretório `skills/` com no mínimo 1 Skill em formato markdown (extensão `.md`) que define um prompt estruturado para geração de código.
5. THE Archetype_Frontend_React SHALL conter um diretório `mcp/` com um arquivo `mcp.json` declarando servidores MCP específicos para projetos frontend React.
6. THE Archetype_Frontend_React SHALL conter um VERSION_File na raiz com exatamente uma linha contendo a versão atual no formato Semantic Versioning `MAJOR.MINOR.PATCH` onde MAJOR, MINOR e PATCH são inteiros não-negativos sem zeros à esquerda.
7. THE Archetype_Frontend_React SHALL conter um CHANGELOG_File na raiz documentando o histórico de mudanças por versão, com ao menos uma entrada correspondente à versão declarada no VERSION_File, onde cada entrada contém o número da versão, a data no formato `YYYY-MM-DD` e uma lista de mudanças agrupadas por tipo.
8. THE Archetype_Frontend_React SHALL conter um arquivo `README.md` em cada diretório de categoria (`steering/`, `hooks/`, `agents/`, `skills/`, `mcp/`) documentando os artefatos disponíveis naquela categoria, sua finalidade e instruções de uso.
9. IF qualquer diretório de categoria (`steering/`, `hooks/`, `agents/`, `skills/`, `mcp/`) não contiver nenhum artefato além do `README.md`, THEN THE Archetype_Frontend_React SHALL ser considerado inválido, pois todos os diretórios de categoria devem conter ao menos um artefato funcional para que o archetype seja válido como um todo.

### Requirement 2: Steering Files — Conteúdo e Cobertura

**User Story:** Como engenheiro frontend, eu quero que os steering files cubram todos os aspectos técnicos relevantes para projetos React/TypeScript, para que o Kiro tenha contexto suficiente para orientar decisões de acordo com os padrões arquiteturais da organização.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um Steering_File `stack-and-tooling.md` localizado em `archetypes/frontend-react/steering/` contendo seções identificáveis que abordem: a definição da stack base obrigatória (React 19, TypeScript strict, Vite, Vitest, Turborepo, ESLint, Prettier, TailwindCSS 4, Redux Toolkit, RTK Query, TanStack Router, pnpm), a organização do monorepo com regras de diretórios e a lista de tecnologias descartadas com justificativa para cada item.
2. THE Archetype_Frontend_React SHALL incluir um Steering_File `architecture.md` localizado em `archetypes/frontend-react/steering/` contendo seções identificáveis que abordem: a definição da arquitetura macro (monolito modular), a arquitetura interna (módulos + FSD), as regras de fronteira entre módulos, a hierarquia de layers FSD com pelo menos as layers app, pages, widgets, features, entities e shared, as regras de gerenciamento de estado (Redux Toolkit + RTK Query) e os princípios arquiteturais.
3. THE Archetype_Frontend_React SHALL incluir um Steering_File `design-system.md` localizado em `archetypes/frontend-react/steering/` contendo seções identificáveis que abordem: a arquitetura do Design System (token-first, Atomic Design, composição), a biblioteca base (Base UI), a documentação via Storybook, o repositório independente com versionamento via Changesets e SemVer, e no mínimo 5 requisitos obrigatórios de qualidade para componentes (incluindo acessibilidade, determinismo e testabilidade).
4. THE Archetype_Frontend_React SHALL incluir um Steering_File `naming-conventions.md` localizado em `archetypes/frontend-react/steering/` contendo seções identificáveis que abordem: as convenções de nomenclatura para diretórios (kebab-case), arquivos (kebab-case para módulos funcionais, PascalCase para componentes React), uma tabela de sufixos obrigatórios por tipo de artefato com no mínimo 10 tipos mapeados, nomenclatura de hooks (prefixo `use`), selectors (prefixo `select`), tipos e interfaces (PascalCase sem prefixos artificiais) e constantes exportadas (SCREAMING_SNAKE_CASE).
5. THE Archetype_Frontend_React SHALL incluir um Steering_File `ci-cd.md` localizado em `archetypes/frontend-react/steering/` contendo seções identificáveis que abordem: a estratégia de pipelines (orquestração por impacto via Turborepo), deploy independente por aplicação com ambientes nomeados, regras de CI separadas por estágio (PR, merge em main, release) com lista explícita de checks por estágio, e a pipeline específica do Design System.
6. THE Steering_File `stack-and-tooling.md` SHALL iniciar com frontmatter YAML contendo exatamente `inclusion: auto` para ser injetado automaticamente em todas as interações do Kiro no projeto.
7. THE Steering_File `naming-conventions.md` SHALL iniciar com frontmatter YAML contendo exatamente `inclusion: auto` para ser injetado automaticamente em todas as interações do Kiro no projeto.
8. THE Steering_File `architecture.md` SHALL iniciar com frontmatter YAML contendo `inclusion: fileMatch` e campo `fileMatchPattern` cujo valor é uma string com padrões separados por vírgula que incluem `**/modules/**` e `**/src/app/**`.
9. THE Steering_File `design-system.md` SHALL iniciar com frontmatter YAML contendo `inclusion: fileMatch` e campo `fileMatchPattern` cujo valor é uma string com padrões separados por vírgula que incluem `**/*.tsx`, `**/shared/ui/**` e `**/*.variants.ts`.
10. THE Steering_File `ci-cd.md` SHALL iniciar com frontmatter YAML contendo `inclusion: fileMatch` e campo `fileMatchPattern` cujo valor é uma string com padrões separados por vírgula que incluem `**/.github/**`, `**/turbo.json` e `**/Dockerfile*`.

### Requirement 3: Hooks de Qualidade de Código

**User Story:** Como engenheiro frontend, eu quero que hooks automáticos garantam lint e type-checking contínuos durante o fluxo de desenvolvimento, para que problemas de formatação e tipagem sejam detectados rapidamente sem intervenção manual.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um Hook `lint-after-agent.kiro.hook` com trigger `agentStop` que verifica se houve criação ou edição de arquivos `.ts` ou `.tsx` dentro de `src/` na sessão e, em caso positivo, executa o comando de lint via Turborepo (`pnpm turbo lint --affected`).
2. THE Hook `lint-after-agent.kiro.hook` SHALL ter o campo `enabled` definido como `true`, versão `"2"`, ação do tipo `askAgent` com prompt condicional que verifica a ocorrência de escrita antes de executar o lint.
3. THE Archetype_Frontend_React SHALL incluir um Hook `typecheck-on-save.kiro.hook` com trigger `agentStop` que verifica se houve criação ou edição de arquivos `.ts` ou `.tsx` dentro de `src/` na sessão e, em caso positivo, executa verificação de tipos TypeScript (`npx tsc --noEmit --pretty`).
4. THE Hook `typecheck-on-save.kiro.hook` SHALL ter o campo `enabled` definido como `true`, versão `"2"`, ação do tipo `askAgent` com prompt condicional que verifica a ocorrência de escrita antes de executar o type-check.
5. IF nenhum arquivo `.ts` ou `.tsx` dentro de `src/` tiver sido criado ou editado na sessão, THEN THE Hook (`lint-after-agent.kiro.hook` ou `typecheck-on-save.kiro.hook`) SHALL não executar nenhum comando e não produzir nenhuma saída ao usuário.
6. IF o comando de lint ou type-check retornar erros, THEN apenas o Hook que detectou erros SHALL reportá-los ao usuário, sem incluir saída de execução bem-sucedida e sem que o outro hook (que não encontrou erros) produza saída.

### Requirement 4: Hooks de Revisão Arquitetural

**User Story:** Como engenheiro frontend, eu quero que hooks inteligentes revisem automaticamente a qualidade dos componentes, as fronteiras entre módulos e as convenções de nomenclatura, para que violações arquiteturais sejam identificadas proativamente.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um Hook `review-component-quality.kiro.hook` com trigger `agentStop` e ação `askAgent` que verifica se houve escrita em arquivos `.tsx` dentro de `**/ui/` ou `**/components/` e, em caso positivo, revisa acessibilidade (HTML semântico, atributos ARIA, navegação por teclado, não depender apenas de cor), tipagem (interface Props dedicada, TypeScript strict sem `any`), estilização (TailwindCSS com tokens semânticos, sem valores hardcoded), composição (namespace para componentes complexos com sub-componentes), testabilidade (`data-testid` em componentes interativos) e tipo de export (named export, não default export).
2. THE Archetype_Frontend_React SHALL incluir um Hook `review-feature-boundaries.kiro.hook` com trigger `agentStop` e ação `askAgent` que verifica se houve escrita em arquivos `.ts` ou `.tsx` dentro de `src/modules/` e, em caso positivo, revisa se imports entre módulos respeitam fronteiras: sem imports diretos entre `modules/{module-a}/` e `modules/{module-b}/`, consumo exclusivamente via API pública (`index.ts`) do módulo, layers importam apenas de layers estritamente abaixo (hierarquia FSD), slices da mesma layer não dependem entre si, e código compartilhado reside em `src/shared/` ou `packages/*`.
3. THE Archetype_Frontend_React SHALL incluir um Hook `review-naming-conventions.kiro.hook` com trigger `agentStop` e ação `askAgent` que verifica se houve criação de arquivos `.ts` ou `.tsx` dentro de `src/` e, em caso positivo, revisa se os nomes seguem as convenções: PascalCase para componentes React, kebab-case para módulos funcionais, sufixos por tipo (`.test.ts`/`.test.tsx` para testes, `.stories.tsx` para stories, `.api.ts` para API, `.slice.ts` para slices, `.selectors.ts` para selectors, `.hook.ts` para hooks, `.context.tsx` para contexts, `.provider.tsx` para providers, `.page.tsx` para páginas, `.types.ts` para tipos, `.schema.ts` para schemas, `.mapper.ts` para mappers), prefixo `use` em camelCase para hooks, e kebab-case para diretórios.
4. THE Archetype_Frontend_React SHALL definir em cada Hook de revisão arquitetural o campo `enabled` como `true` e incluir no prompt a instrução de não fazer nada e não comentar caso nenhum arquivo relevante tenha sido criado ou editado na sessão.
5. WHEN um Hook de revisão arquitetural identifica violações, THE Archetype_Frontend_React SHALL instruir o agente a sempre sugerir correções específicas para cada violação encontrada (mesmo que genéricas ou incompletas), e a fornecer uma breve confirmação positiva quando todos os itens revisados estiverem em conformidade.

### Requirement 5: Hooks de Ciclo de Desenvolvimento

**User Story:** Como engenheiro frontend, eu quero que hooks automatizem a execução de testes após tarefas de spec e verifiquem a cobertura de testes ao final de sessões, para que a qualidade do código seja mantida continuamente.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um Hook `run-tests-after-task.kiro.hook` com trigger `postTaskExecution`, campo `enabled` definido como `true` e ação do tipo `runCommand` que executa `npx vitest --run --reporter=verbose` automaticamente após a conclusão de uma task de spec.
2. THE Archetype_Frontend_React SHALL incluir um Hook `remind-test-coverage.kiro.hook` com trigger `postTaskExecution`, campo `enabled` definido como `true` e ação do tipo `askAgent` que verifica se os arquivos de código criados ou editados na task possuem testes correspondentes segundo as convenções (componentes `.tsx` em `ui/` com `.test.tsx`, hooks `.hook.ts` em `lib/` com `.hook.test.ts`, slices `.slice.ts` em `model/` com `.slice.test.ts`, selectors `.selectors.ts` em `model/` com `.selectors.test.ts`, APIs `.api.ts` em `api/` com `.api.test.ts`).
3. THE Hook `remind-test-coverage.kiro.hook` SHALL instruir o agente a listar os arquivos específicos que necessitam de testes correspondentes quando houver testes faltantes, e a não comentar quando todos os arquivos criados ou editados já possuem testes correspondentes.

### Requirement 6: Hook de Diagnóstico (Kiro Doctor)

**User Story:** Como engenheiro frontend, eu quero ter um hook de diagnóstico disponível no Kiro para verificar a conformidade do meu projeto com o archetype e o baseline, para identificar desvios sem sair do IDE.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um arquivo `kiro-doctor.kiro.hook` no diretório `hooks/` com formato JSON válido contendo os campos: `enabled` (boolean), `name` (string), `description` (string), `version` (string), `when.type` com valor `"userTriggered"` e `then.type` com valor `"askAgent"` com campo `prompt` contendo as instruções de análise.
2. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a executar as seguintes etapas na ordem: (a) ler a estrutura `.kiro/` do projeto (steering, hooks, settings/mcp.json, specs, skills, agents), (b) comparar com o baseline global em `baselines/global/`, (c) identificar o archetype do projeto e comparar com os artefatos esperados em `archetypes/{archetype}/`, (d) verificar specs existentes em `.kiro/specs/` listando status (completas, em progresso, pendentes), (e) validar aderência arquitetural do código-fonte contra os steering files e (f) gerar o relatório markdown.
3. THE relatório gerado pelo Hook de diagnóstico SHALL incluir exatamente 8 seções na seguinte ordem, sem seções adicionais e sem alteração de ordem (o relatório é inválido se a estrutura divergir): (1) Resumo com indicadores visuais ✅ OK, ⚠️ Atenção e ❌ Problema, (2) Steering com arquivos presentes, ausentes e extras comparados ao archetype, (3) Hooks com status configurado, habilitado e ausente comparado ao archetype, (4) MCP Servers com configurados vs baseline global, (5) Skills com presentes vs esperados pelo archetype, (6) Specs com listagem e status individual, (7) Arquitetura com desvios identificados nos steering files e (8) Recomendações com ações sugeridas.
4. THE campo `then.prompt` do Hook `kiro-doctor.kiro.hook` SHALL instruir o agente a salvar o relatório com o nome `kiro-doctor-report.md` na raiz do diretório do projeto do usuário.

### Requirement 7: Agents Especializados de Revisão

**User Story:** Como engenheiro frontend, eu quero ter agentes especializados disponíveis para revisões detalhadas sob demanda, para que eu possa obter feedback profundo sobre acessibilidade, arquitetura, qualidade de código e performance quando necessário.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um arquivo `accessibility-reviewer.md` no diretório `agents/` que define escopo de revisão cobrindo: semântica HTML (elementos semânticos, landmarks, heading hierarchy), atributos ARIA (aria-label, aria-live, roles), navegação por teclado (foco, tab order, focus trapping), contraste de cores (mínimo 4.5:1 para texto normal, 3:1 para texto grande), formulários (labels, mensagens de erro, campos obrigatórios) e imagens (alt descritivo, alt vazio para decorativas), produzindo feedback com 5 campos: localização (arquivo e linha), problema, critério WCAG 2.1 AA violado, correção sugerida e severidade (crítico, alto, médio, baixo).
2. THE Archetype_Frontend_React SHALL incluir um arquivo `architecture-reviewer.md` no diretório `agents/` que define escopo de revisão cobrindo: fronteiras entre módulos (imports cruzados proibidos, API pública via index.ts), FSD interno (hierarquia de layers, slices independentes, segmentos por propósito), organização de diretórios (bounded context, kebab-case), shared global vs shared de módulo, gerenciamento de estado (Redux Toolkit, RTK Query, Context), acoplamento/coesão e anti-padrões arquiteturais, produzindo feedback com 5 campos: localização (arquivo/diretório), problema, princípio violado, sugestão de correção e impacto (alto, médio, baixo).
3. THE Archetype_Frontend_React SHALL incluir um arquivo `code-reviewer.md` no diretório `agents/` que define escopo de revisão cobrindo: TypeScript (strict, sem `any`, props tipadas), React (named exports, hooks, responsabilidade única), estilização (TailwindCSS com tokens semânticos, `cn()`), testes (AAA, comportamento, cobertura de estados), nomenclatura (kebab-case para módulos, PascalCase para componentes, sufixos corretos), segurança (sem segredos, inputs sanitizados) e boas práticas (funções pequenas, sem magic numbers, sem código morto), organizando feedback em 3 níveis de severidade: bloqueante (bloqueia merge), importante (deve corrigir) e sugestão (melhoria opcional).
4. THE Archetype_Frontend_React SHALL incluir um arquivo `performance-reviewer.md` no diretório `agents/` que define escopo de revisão cobrindo: re-renders desnecessários (objetos inline, callbacks não memoizados, Context providers), memoização (considerando React 19 + React Compiler, memoização manual apenas quando compilador não resolve), bundle size (imports granulares, tree-shaking, lazy loading), data fetching via RTK Query (cache, tags, prefetching) e renderização (virtualização para listas grandes, keys estáveis, debounce), produzindo feedback com 5 campos: localização (arquivo e trecho), problema, impacto estimado (alto, médio, baixo), correção sugerida e como medir a melhoria.
5. THE cada arquivo de Agent no diretório `agents/` SHALL iniciar com frontmatter YAML delimitado por `---` contendo obrigatoriamente os campos `name` (string com nome exibível em português) e `description` (string descrevendo a especialidade do agente, idealmente até 200 caracteres — valores acima são permitidos mas geram um warning de recomendação de encurtamento). Arquivos sem ambos os campos são rejeitados como inválidos.
6. THE cada arquivo de Agent no diretório `agents/` SHALL incluir uma seção `## Referências` listando os steering files e documentações externas relevantes para sua especialidade.

### Requirement 8: Skills de Geração de Código

**User Story:** Como engenheiro frontend, eu quero ter skills disponíveis para gerar código padronizado sob demanda, para que componentes, hooks, slices, endpoints, páginas, módulos e contexts sejam criados seguindo todos os padrões do archetype automaticamente.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um arquivo `generate-component.md` no diretório `skills/` que instrui a geração de um componente React com os seguintes artefatos: arquivo do componente (`PascalCase.tsx`), teste (`PascalCase.test.tsx`), story (`PascalCase.stories.tsx`), variants opcionais (`kebab-case.variants.ts` quando usar cva) e barrel export (`index.ts`), seguindo padrões de acessibilidade, tipagem strict, estilização com tokens semânticos TailwindCSS e localização no segmento `ui/` da estrutura FSD.
2. THE Archetype_Frontend_React SHALL incluir um arquivo `generate-hook.md` no diretório `skills/` que instrui a geração de um custom hook React com os seguintes artefatos: arquivo do hook (`use-nome.hook.ts`) e teste (`use-nome.hook.test.ts`), seguindo convenções de nomenclatura (prefixo `use` em camelCase, arquivo em kebab-case com sufixo `.hook`) e localização no segmento `lib/` da estrutura FSD.
3. THE Archetype_Frontend_React SHALL incluir um arquivo `generate-redux-slice.md` no diretório `skills/` que instrui a geração de um Redux slice com os seguintes artefatos: slice (`nome.slice.ts`), selectors (`nome.selectors.ts`), testes do slice e dos selectors, e barrel export (`index.ts`), seguindo convenções de nomenclatura (selectors com prefixo `select`) e localização no segmento `model/` da estrutura FSD.
4. THE Archetype_Frontend_React SHALL incluir um arquivo `generate-api-endpoint.md` no diretório `skills/` que instrui a geração de um endpoint RTK Query com os seguintes artefatos: arquivo de API (`nome.api.ts`) e teste (`nome.api.test.ts`), seguindo convenções de nomenclatura (verbos de ação para endpoints), tipagem completa de request/response e configuração de cache com tags no segmento `api/` da estrutura FSD.
5. THE Archetype_Frontend_React SHALL incluir um arquivo `generate-page.md` no diretório `skills/` que instrui a geração de uma página React dentro de um módulo FSD com tratamento de 4 estados (loading, error, empty, success), landmarks semânticos HTML (`<main>`, heading hierarchy) e orquestração de dados via hooks customizados (sem lógica de negócio na página).
6. THE Archetype_Frontend_React SHALL incluir um arquivo `generate-module.md` no diretório `skills/` que instrui a geração da estrutura completa de um módulo (bounded context) com diretórios FSD (`pages/`, `widgets/`, `features/`, `entities/`, `shared/`), barrel export público via `index.ts` na raiz do módulo e criação opcional de entities e features iniciais quando solicitadas pelo desenvolvedor.
7. THE Archetype_Frontend_React SHALL incluir um arquivo `generate-context-provider.md` no diretório `skills/` que instrui a geração de um React Context com os seguintes artefatos: Provider com value tipado, hook de leitura (`use` + nome em camelCase) com type guard que lança erro se usado fora do Provider, e teste do provider, organizados em `app/providers/` para contexts globais ou no segmento `lib/` do módulo para contexts locais.
8. THE cada arquivo de Skill no diretório `skills/` SHALL iniciar com frontmatter YAML delimitado por `---` contendo exatamente os campos `name` (string com nome exibível em português), `description` (string descrevendo o que a skill gera) e `inclusion` com valor `"manual"`.

### Requirement 9: Configuração MCP

**User Story:** Como engenheiro frontend, eu quero que o archetype defina servidores MCP específicos para desenvolvimento frontend, para que projetos React tenham acesso a ferramentas relevantes para a stack.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL incluir um arquivo `mcp.json` no diretório `mcp/` que seja um JSON válido contendo: um campo `_comment` (string identificando o propósito como MCPs do archetype frontend-react), um campo `_version` com versão semântica no formato `MAJOR.MINOR.PATCH` e um objeto `mcpServers` com ao menos 1 servidor declarado.
2. THE arquivo `mcp.json` do archetype SHALL incluir o servidor `chrome-devtools` configurado com os campos: `command` com valor `"npx"`, `args` com valor `["-y", "chrome-devtools-mcp@latest"]`, `disabled` com valor `false` e `autoApprove` com valor `[]` (array vazio).
3. THE cada servidor declarado no objeto `mcpServers` do arquivo `mcp.json` SHALL incluir um campo `_comment` (string não vazia) descrevendo a funcionalidade do servidor e seus pré-requisitos de execução.
4. THE cada servidor declarado no objeto `mcpServers` do arquivo `mcp.json` SHALL definir o campo `autoApprove` como array vazio (`[]`), exigindo aprovação explícita do usuário para cada operação MCP.

### Requirement 10: Versionamento e Changelog

**User Story:** Como mantenedor da plataforma, eu quero que o archetype frontend-react siga versionamento semântico com changelog documentado, para que projetos consumidores saibam quando uma atualização pode impactar sua configuração.

#### Acceptance Criteria

1. THE Archetype_Frontend_React SHALL manter um arquivo `VERSION` na raiz do diretório do archetype contendo a versão no formato `MAJOR.MINOR.PATCH`, onde cada segmento é um inteiro não-negativo (0 ou maior) sem zeros à esquerda (exceto o próprio 0).
2. THE arquivo `VERSION` SHALL conter exclusivamente a string de versão sem prefixo `v`, sem espaços antes ou depois e sem caractere de quebra de linha ao final (trailing newline).
3. THE Archetype_Frontend_React SHALL manter um arquivo `CHANGELOG.md` na raiz do diretório do archetype, organizado com a versão mais recente no topo do arquivo, usando cabeçalho de nível 2 no formato `## MAJOR.MINOR.PATCH (YYYY-MM-DD)` para cada release.
4. THE cada entrada de release no `CHANGELOG.md` SHALL agrupar mudanças em seções com cabeçalho de nível 3, utilizando apenas os seguintes nomes: `### Funcionalidades` (feat), `### Correções` (fix), `### Documentação` (docs), `### Refatoração` (refactor), `### Manutenção` (chore), `### Performance` (perf) e `### CI/CD` (ci), omitindo seções que não possuem entradas na release.
5. WHEN um novo Steering_File é adicionado ao archetype ou uma nova diretriz é incluída em um Steering_File existente sem alterar nem remover diretrizes existentes, THE Mantenedor SHALL incrementar o dígito MINOR em 1 e redefinir PATCH para 0, mantendo MAJOR inalterado.
6. WHEN um Steering_File é removido, um Steering_File é renomeado ou um Hook é removido do archetype, THE Mantenedor SHALL incrementar o dígito MAJOR em 1 e redefinir MINOR e PATCH para 0.
7. WHEN uma correção de texto em steering/agents/skills, refinamento de prompt em hooks ou ajuste de valor em configuração MCP é aplicado sem adicionar, remover ou alterar diretrizes comportamentais, THE Mantenedor SHALL incrementar o dígito PATCH em 1, mantendo MAJOR e MINOR inalterados.
8. IF uma release contém mudanças que se enquadram em mais de uma categoria de incremento (ex: adicionar um steering file e remover outro na mesma release), THEN THE Mantenedor SHALL aplicar apenas o incremento de maior precedência (MAJOR > MINOR > PATCH).
