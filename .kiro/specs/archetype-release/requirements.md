# Requirements Document

## Introduction

Hook manual (`userTriggered`) para o repositório de governança Kiro que automatiza o processo de release de componentes versionáveis. O hook identifica mudanças não commitadas, gera commits seguindo Conventional Commits, atualiza versionamento semântico e mantém changelogs atualizados para cada componente independente do repositório.

## Glossary

- **Release_Hook**: Hook Kiro do tipo `userTriggered` responsável por orquestrar o processo de release de componentes versionáveis.
- **Componente_Versionável**: Diretório de primeiro nível dentro de `archetypes/`, `baselines/`, ou `powers/` que possui versionamento semântico independente. Todos os subdiretórios de primeiro nível dessas pastas são considerados componentes versionáveis (ex: `archetypes/backend-csharp/`, `archetypes/agents/`, `powers/mb-frontend-react/`, `baselines/global/`). Futuramente, outros diretórios como `docs/` e `scripts/` podem ser adicionados ao escopo.
- **VERSION_File**: Arquivo texto na raiz de cada Componente_Versionável contendo a versão atual no formato `MAJOR.MINOR.PATCH`.
- **CHANGELOG_File**: Arquivo markdown na raiz de cada Componente_Versionável documentando o histórico de mudanças por versão.
- **Conventional_Commit**: Padrão de mensagem de commit estruturado com tipo, escopo opcional e descrição (ex: `feat(backend-csharp): descrição`).
- **Bump_Type**: Classificação do incremento de versão: `major` (breaking changes), `minor` (novas funcionalidades), ou `patch` (correções e ajustes).
- **Agente**: Instância do agente Kiro que executa as instruções do hook.
- **Git_Tag**: Tag git no formato `<nome-componente>@<versão>` criada após o commit de release.

## Requirements

### Requirement 1: Detecção de Mudanças por Componente

**User Story:** Como mantenedor do repositório de governança, eu quero que o hook identifique automaticamente quais componentes versionáveis possuem mudanças não commitadas, para que eu saiba exatamente o que será incluído na release.

#### Acceptance Criteria

1. WHEN o Release_Hook é acionado, THE Agente SHALL executar `git status` e agrupar os arquivos com estado modified, added, deleted ou untracked por Componente_Versionável, considerando tanto mudanças staged quanto unstaged.
2. WHEN o Release_Hook é acionado, THE Agente SHALL considerar como Componente_Versionável cada diretório de primeiro nível dentro de `archetypes/`, `baselines/` e `powers/`.
3. IF nenhum Componente_Versionável possuir mudanças pendentes, THEN THE Agente SHALL informar "Nenhuma mudança encontrada para release" e encerrar a execução.
4. WHEN mudanças são detectadas, THE Agente SHALL apresentar ao usuário um resumo listando cada Componente_Versionável afetado e a quantidade de arquivos alterados (modified, added, deleted ou untracked) em cada um.
5. IF existirem arquivos modificados fora dos diretórios de Componentes_Versionáveis (ex: arquivos na raiz do repositório ou em diretórios não versionáveis), THEN THE Agente SHALL ignorá-los no processo de release e informar ao usuário quais arquivos foram excluídos da análise.
6. THE Agente SHALL ignorar silenciosamente arquivos soltos (não-diretórios) dentro de `archetypes/`, `baselines/` ou `powers/` que não pertencem a nenhum subdiretório de primeiro nível (ex: `powers/mb-atlassian-rovo.zip`).

### Requirement 2: Análise Semântica e Classificação de Mudanças

**User Story:** Como mantenedor do repositório de governança, eu quero que o hook analise semanticamente as mudanças para determinar o tipo de commit e o bump de versão corretos, para que o versionamento reflita a natureza real das alterações.

#### Acceptance Criteria

1. WHEN mudanças são detectadas em um Componente_Versionável, THE Agente SHALL analisar o diff (`git diff`) dos arquivos modificados e o conteúdo completo dos arquivos untracked (novos) para classificar cada grupo de mudanças como `feat`, `fix`, `docs`, `refactor`, `chore`, `perf` ou `ci`.
8. IF o Agente encontrar arquivos untracked (novos) em um Componente_Versionável, THEN THE Agente SHALL analisar o conteúdo completo do arquivo e apresentar ao usuário a classificação proposta para confirmação antes de prosseguir.
2. WHEN a classificação é determinada, THE Agente SHALL inferir o Bump_Type: `feat` resulta em bump `minor`, `fix`/`docs`/`refactor`/`chore`/`perf`/`ci` resultam em bump `patch`.
3. IF uma mudança contém alteração incompatível com versões anteriores (remoção ou renomeação de arquivos públicos, remoção de configurações existentes, ou alteração de interfaces/contratos consumidos por outros componentes), THEN THE Agente SHALL classificar o Bump_Type como `major`.
4. WHEN múltiplos arquivos de um Componente_Versionável possuem mudanças do mesmo tipo de classificação (ex: todos `feat` ou todos `fix`) e estão relacionados à mesma funcionalidade ou correção, THE Agente SHALL agrupá-los em um único commit.
5. WHEN múltiplos arquivos de um Componente_Versionável possuem tipos de classificação distintos ou pertencem a funcionalidades independentes, THE Agente SHALL separá-los em commits individuais por agrupamento lógico.
6. WHEN múltiplos commits são gerados para um mesmo Componente_Versionável, THE Agente SHALL usar o Bump_Type de maior precedência (major > minor > patch) para o incremento de versão.
7. IF o Agente não conseguir determinar com confiança o tipo de classificação de uma mudança, THEN THE Agente SHALL apresentar o diff ao usuário e solicitar a classificação manual antes de prosseguir.

### Requirement 3: Geração de Commits

**User Story:** Como mantenedor do repositório de governança, eu quero que os commits sejam gerados automaticamente seguindo Conventional Commits com escopo do componente, para manter o histórico git padronizado e rastreável.

#### Acceptance Criteria

1. THE Agente SHALL gerar mensagens de commit no formato `<tipo>(<escopo>): <descrição>` onde o escopo é o nome do Componente_Versionável e a linha de assunto completa (tipo + escopo + descrição) não excede 72 caracteres.
2. WHEN um commit é gerado, THE Agente SHALL incluir apenas os arquivos pertencentes ao Componente_Versionável correspondente no staging (`git add`).
3. THE Agente SHALL redigir a descrição do commit em português do Brasil, utilizando verbo no infinitivo.
4. IF um commit representa uma breaking change, THEN THE Agente SHALL incluir o marcador `BREAKING CHANGE:` no footer do commit ou usar `!` após o tipo (ex: `feat(backend-csharp)!: descrição`).
5. WHEN todos os commits de um Componente_Versionável são criados, THE Agente SHALL criar um commit adicional de release contendo as atualizações do VERSION_File e CHANGELOG_File com a mensagem `chore(<escopo>): release v<nova-versão>`.
6. IF a execução de `git add` ou `git commit` falhar, THEN THE Agente SHALL informar o erro ao usuário indicando o comando que falhou e o Componente_Versionável afetado, e interromper o processamento daquele componente.

### Requirement 4: Atualização de Versionamento

**User Story:** Como mantenedor do repositório de governança, eu quero que o arquivo VERSION seja atualizado automaticamente com o incremento correto, para que a versão do componente reflita as mudanças realizadas.

#### Acceptance Criteria

1. IF o Componente_Versionável possui um VERSION_File com conteúdo válido no formato `MAJOR.MINOR.PATCH`, THEN THE Agente SHALL ler a versão atual e aplicar o incremento conforme o Bump_Type determinado.
2. IF o Componente_Versionável não possui um VERSION_File, THEN THE Agente SHALL criar o arquivo com a versão `0.1.0` independente do Bump_Type determinado (primeira release é sempre `0.1.0`).
3. WHEN o Bump_Type é `patch`, THE Agente SHALL incrementar o terceiro dígito (ex: `1.2.3` → `1.2.4`).
4. WHEN o Bump_Type é `minor`, THE Agente SHALL incrementar o segundo dígito e zerar o terceiro (ex: `1.2.3` → `1.3.0`).
5. WHEN o Bump_Type é `major`, THE Agente SHALL incrementar o primeiro dígito e zerar os demais (ex: `1.2.3` → `2.0.0`).
6. THE VERSION_File SHALL conter apenas a string de versão no formato `MAJOR.MINOR.PATCH` onde cada segmento é um número inteiro não-negativo, sem prefixo `v`, sem espaços e sem quebra de linha ao final.
7. IF o VERSION_File existe mas seu conteúdo não corresponde ao formato `MAJOR.MINOR.PATCH` com segmentos numéricos inteiros não-negativos, THEN THE Agente SHALL informar ao usuário que o arquivo possui formato inválido e solicitar orientação antes de prosseguir.

### Requirement 5: Geração e Atualização de Changelog

**User Story:** Como mantenedor do repositório de governança, eu quero que um changelog seja gerado ou atualizado automaticamente com as mudanças da release, para documentar o histórico de evolução de cada componente.

#### Acceptance Criteria

1. WHEN uma release é processada, THE Agente SHALL criar ou atualizar o CHANGELOG_File na raiz do Componente_Versionável.
2. THE Agente SHALL organizar o CHANGELOG_File com a versão mais recente no topo, usando o formato de cabeçalho de versão `## <MAJOR.MINOR.PATCH> (<YYYY-MM-DD>)` seguido de seções agrupadas por tipo de mudança com heading `###`.
3. THE Agente SHALL agrupar as entradas do changelog nas seções: `### Funcionalidades` (feat), `### Correções` (fix), `### Documentação` (docs), `### Refatoração` (refactor), `### Manutenção` (chore), `### Performance` (perf), `### CI/CD` (ci), omitindo seções que não possuem entradas na release.
4. WHEN o CHANGELOG_File não existe, THE Agente SHALL criá-lo com um cabeçalho `# Changelog` seguido da primeira entrada de versão.
5. WHEN o CHANGELOG_File já existe, THE Agente SHALL inserir a nova entrada de versão imediatamente após o cabeçalho `# Changelog`, preservando todas as entradas de versões anteriores inalteradas.
6. THE Agente SHALL incluir cada mudança como um item de lista markdown (`- `) contendo a descrição do commit correspondente em português do Brasil, com no máximo 100 caracteres por entrada.

### Requirement 6: Criação de Tags Git

**User Story:** Como mantenedor do repositório de governança, eu quero que tags git sejam criadas para cada release, para facilitar a referência e distribuição de versões específicas dos componentes.

#### Acceptance Criteria

1. WHEN o commit de release é criado com sucesso, THE Agente SHALL criar uma Git_Tag anotada no commit de release, no formato `<nome-componente>@<nova-versão>`, com mensagem de anotação contendo `Release <nome-componente>@<nova-versão>`.
2. THE Agente SHALL usar o nome do diretório do Componente_Versionável como prefixo da tag, seguido de `@` e a versão sem prefixo `v` (ex: `backend-csharp@1.2.0`, `global@2.0.0`, `mb-frontend-react@0.3.0`).
3. IF a Git_Tag já existir, THEN THE Agente SHALL informar ao usuário a tag conflitante e a versão existente, e apresentar as opções: (a) sobrescrever a tag existente, (b) ignorar a criação da tag e continuar, ou (c) abortar o processamento do componente.
4. IF o usuário escolher sobrescrever a tag existente, THEN THE Agente SHALL remover a tag anterior e criar a nova tag apontando para o commit de release atual.

### Requirement 7: Fluxo Completo e Ordenação

**User Story:** Como mantenedor do repositório de governança, eu quero que o hook execute todo o fluxo de release de forma ordenada e previsível, para que eu possa confiar no resultado sem intervenção manual.

#### Acceptance Criteria

1. THE Agente SHALL processar os Componentes_Versionáveis um por vez, em ordem alfabética pelo nome do diretório, completando todo o fluxo de um componente antes de iniciar o próximo.
2. THE Agente SHALL seguir a ordem: (1) análise semântica, (2) commits das mudanças, (3) atualização do VERSION_File, (4) atualização do CHANGELOG_File, (5) commit de release, (6) criação da Git_Tag.
3. WHEN a lista de Componentes_Versionáveis com mudanças é identificada, THE Agente SHALL solicitar confirmação do usuário antes de iniciar o processamento, apresentando a ordem em que os componentes serão processados.
4. IF ocorrer um erro durante o processamento de um componente, THEN THE Agente SHALL informar o erro com identificação do componente e da etapa em que falhou, preservar os commits já realizados para o componente afetado, interromper o processamento desse componente e perguntar ao usuário se deseja continuar com os demais.
5. WHEN todos os componentes são processados, THE Agente SHALL apresentar um resumo final contendo: componentes processados com sucesso (versões anteriores e novas), componentes que falharam (com a etapa de falha), quantidade total de commits gerados e tags criadas.
