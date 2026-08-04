# Requirements Document

## Introduction

A feature "Baseline User Scope" migra a instalação dos artefatos do baseline global do nível workspace (`.kiro/` de cada projeto) para o nível do usuário (`~/.kiro/`), mantendo apenas artefatos do archetype no workspace. Atualmente, o `bootstrap.sh` copia tudo (baseline + archetype) para `.kiro/` do projeto, causando duplicação quando desenvolvedores participam de múltiplos projetos e conflitos em workspaces multi-root. A separação de escopos resolve estes problemas e cria uma distinção clara entre configuração organizacional (user-level) e configuração de stack/projeto (workspace-level).

## Glossary

- **Baseline_Global**: Conjunto de artefatos (steering files, MCP config e hooks) que compõem a configuração mínima obrigatória organizacional, localizado em `baselines/global/` no repositório mb-kiro.
- **User_Kiro_Dir**: Diretório `~/.kiro/` no home do usuário onde o Kiro armazena configuração de nível global do desenvolvedor (steering, hooks, settings, skills, powers).
- **Workspace_Kiro_Dir**: Diretório `.kiro/` na raiz de cada projeto, contendo configuração específica do workspace (archetype, specs, agents).
- **Prefixo_MB**: Prefixo `mb--` obrigatório para todos os artefatos do baseline instalados no User_Kiro_Dir, evitando conflito com artefatos pessoais do desenvolvedor.
- **Steering_File**: Documento markdown injetado pelo Kiro como contexto nas interações com o agente.
- **Hook_Global**: Hook Kiro distribuído como parte do baseline que automatiza verificações ou ações.
- **MCP_Config**: Arquivo JSON (`mcp.json`) que declara servidores MCP disponíveis.
- **Baseline_Version_File**: Arquivo `~/.kiro/mb-baseline-version` no User_Kiro_Dir contendo a versão do baseline instalada.
- **Kiro_Manifest**: Arquivo `kiro-manifest.json` na raiz do projeto que declara archetype, powers e exceções.
- **Script_Bootstrap**: Script `bootstrap.sh` responsável pela instalação inicial, agora com suporte a `--scope user|workspace`.
- **Script_Sync**: Script `sync.sh` responsável pela atualização incremental, agora com suporte a `--scope user|workspace`.
- **Script_Doctor**: Script `doctor.sh` responsável pelo diagnóstico de conformidade em ambos os níveis.
- **Archetype**: Conjunto de artefatos específicos de stack tecnológica (steering, hooks, skills, agents) que residem no Workspace_Kiro_Dir.
- **Scope_User**: Escopo de instalação que aplica artefatos do baseline no User_Kiro_Dir (`~/.kiro/`).
- **Scope_Workspace**: Escopo de instalação que aplica artefatos do archetype no Workspace_Kiro_Dir (`.kiro/` do projeto).
- **CI_Environment**: Ambiente de integração contínua onde `~/.kiro/` não está disponível e uma alternativa é necessária.

## Requirements

### Requirement 1: Instalação de Baseline no Escopo User

**User Story:** Como desenvolvedor da MonteBravo, eu quero instalar o baseline global uma única vez na minha máquina, para que todos os meus projetos compartilhem as mesmas diretrizes organizacionais sem duplicação.

#### Acceptance Criteria

1. WHEN o Script_Bootstrap é executado com `--scope user`, THE Script_Bootstrap SHALL copiar cada Steering_File de `baselines/global/steering/` (exceto `README.md`) para `~/.kiro/steering/` renomeando o arquivo com o Prefixo_MB (formato: `mb--<nome-original>.md`).
2. WHEN o Script_Bootstrap é executado com `--scope user`, THE Script_Bootstrap SHALL copiar cada Hook_Global de `baselines/global/hooks/` para `~/.kiro/hooks/` renomeando o arquivo com o Prefixo_MB (formato: `mb--<nome-original>.kiro.hook`).
3. WHEN o Script_Bootstrap é executado com `--scope user`, THE Script_Bootstrap SHALL mergear os servidores MCP de `baselines/global/mcp/mcp.json` no arquivo `~/.kiro/settings/mcp.json`, preservando servidores pessoais já existentes do desenvolvedor (servidores cuja chave não existe no baseline).
4. WHEN o Script_Bootstrap é executado com `--scope user` e o arquivo `~/.kiro/settings/mcp.json` já possui um servidor com a mesma chave do baseline, THE Script_Bootstrap SHALL sobrescrever a configuração do servidor com a versão do baseline e exibir mensagem de WARNING em stderr indicando qual servidor foi atualizado (o merge MCP não é afetado pela flag `--force`).
5. WHEN o Script_Bootstrap é executado com `--scope user`, THE Script_Bootstrap SHALL criar o arquivo `~/.kiro/mb-baseline-version` contendo a versão do baseline no formato `MAJOR.MINOR.PATCH` (lida de `baselines/global/VERSION`).
6. IF o User_Kiro_Dir (`~/.kiro/`) não existir, THEN THE Script_Bootstrap SHALL criar a estrutura de diretórios necessária (`~/.kiro/steering/`, `~/.kiro/hooks/`, `~/.kiro/settings/`).
7. IF um arquivo com Prefixo_MB já existe em `~/.kiro/steering/` ou `~/.kiro/hooks/` e a flag `--force` não foi informada, THEN THE Script_Bootstrap SHALL pular o arquivo e exibir mensagem de WARNING em stderr indicando que o arquivo já existe e sugerindo o uso de `--force` para sobrescrever.
8. WHEN a flag `--dry-run` é informada com `--scope user`, THE Script_Bootstrap SHALL listar em stdout cada operação que seria realizada (cópia, merge, criação) sem criar ou modificar nenhum arquivo no User_Kiro_Dir.
9. IF o arquivo `baselines/global/VERSION` não existir ou não contiver uma versão válida no formato `MAJOR.MINOR.PATCH`, THEN THE Script_Bootstrap SHALL encerrar a execução com exit code 1 e exibir mensagem de erro indicando que o arquivo VERSION é obrigatório e deve conter versão semântica.
10. WHEN o Script_Bootstrap com `--scope user` conclui a instalação com sucesso, THE Script_Bootstrap SHALL encerrar com exit code 0 e exibir um resumo em stdout contendo a quantidade de arquivos copiados, arquivos pulados e servidores MCP mergeados.

### Requirement 2: Instalação de Archetype no Escopo Workspace

**User Story:** Como Tech Lead iniciando um projeto novo, eu quero que o bootstrap do workspace instale apenas os artefatos do archetype, para que o projeto contenha somente configurações específicas da sua stack sem duplicar o baseline.

#### Acceptance Criteria

1. WHEN o Script_Bootstrap é executado com `--scope workspace`, `--target` e `--project-type`, THE Script_Bootstrap SHALL copiar artefatos do archetype (steering, skills, hooks, agents) para os subdiretórios respectivos em `<projeto>/.kiro/` (`steering/`, `skills/`, `hooks/`, `agents/`), sem copiar artefatos do Baseline_Global.
2. WHEN o Script_Bootstrap é executado com `--scope workspace`, THE Script_Bootstrap SHALL gerar um `mcp.json` em `<projeto>/.kiro/settings/mcp.json` contendo apenas os servidores MCP do archetype (lidos de `archetypes/<project-type>/mcp/mcp.json`), sem mergear com o baseline.
3. WHEN o Script_Bootstrap é executado com `--scope workspace`, THE Script_Bootstrap SHALL gerar um Kiro_Manifest na raiz do projeto contendo: o nome e versão do archetype (lidos de `archetypes/<project-type>/VERSION`), a lista de powers instalados (array vazio caso o archetype não declare powers), um array de exceções vazio, e o campo `baseline.scope` com valor `"user"` indicando que o baseline está no nível do usuário.
4. IF o `--project-type` informado não corresponde a nenhum archetype disponível no diretório `archetypes/`, THEN THE Script_Bootstrap SHALL encerrar a execução com código de saída diferente de zero e exibir mensagem de erro listando os tipos válidos.
5. WHEN a flag `--dry-run` é informada com `--scope workspace`, THE Script_Bootstrap SHALL simular a execução sem criar ou modificar nenhum arquivo no Workspace_Kiro_Dir.
6. WHEN o Script_Bootstrap é executado com `--scope workspace`, THE Script_Bootstrap SHALL validar que Git está instalado no ambiente antes de iniciar, encerrando com código de saída diferente de zero caso o pré-requisito não seja atendido.
7. IF o argumento `--scope` não for informado, THEN THE Script_Bootstrap SHALL exibir mensagem de erro indicando que o argumento é obrigatório e listar os valores válidos (`user`, `workspace`).
8. IF o argumento `--target` não for informado com `--scope workspace`, ou o caminho informado não existir ou não for um diretório, THEN THE Script_Bootstrap SHALL encerrar com código de saída diferente de zero e exibir mensagem de erro indicando que `--target` deve apontar para um diretório existente.
9. IF o Workspace_Kiro_Dir (`<projeto>/.kiro/`) já existir no `--target` informado e a flag `--force` não estiver presente, THEN THE Script_Bootstrap SHALL encerrar com código de saída diferente de zero e exibir mensagem de erro indicando que o workspace já foi inicializado, sugerindo uso de `--force` para sobrescrever ou `sync.sh --scope workspace` para atualizar.
10. WHEN o Script_Bootstrap é executado com `--scope workspace` e a flag `--force` está presente e o Workspace_Kiro_Dir já existe, THE Script_Bootstrap SHALL sobrescrever os artefatos do archetype existentes no Workspace_Kiro_Dir preservando arquivos que não pertencem ao archetype (como `specs/`).

### Requirement 3: Prefixo Obrigatório para Artefatos do Baseline

**User Story:** Como desenvolvedor, eu quero que artefatos do baseline sejam claramente identificados com um prefixo, para que não conflitem com meus steerings e hooks pessoais em `~/.kiro/`.

#### Acceptance Criteria

1. WHEN o Script_Bootstrap é executado com `--scope user`, THE Script_Bootstrap SHALL renomear cada Steering_File do baseline para o formato `mb--<nome-original>.md` ao copiar para `~/.kiro/steering/`, onde `<nome-original>` é o nome do arquivo fonte sem extensão e sem modificação de caixa ou caracteres.
2. WHEN o Script_Bootstrap é executado com `--scope user`, THE Script_Bootstrap SHALL renomear cada Hook_Global do baseline para o formato `mb--<nome-original>.kiro.hook` ao copiar para `~/.kiro/hooks/`, onde `<nome-original>` é o nome do arquivo fonte sem a extensão `.kiro.hook` e sem modificação de caixa ou caracteres.
3. IF um arquivo em `~/.kiro/steering/` ou `~/.kiro/hooks/` possui o Prefixo_MB (`mb--`) no nome do arquivo, THEN THE Script_Sync e Script_Doctor SHALL incluir o arquivo nas operações de comparação, atualização e verificação de conformidade com a fonte do baseline, e SHALL excluí-lo de qualquer proteção aplicada a arquivos pessoais.
4. THE Script_Bootstrap e Script_Sync SHALL não modificar o conteúdo, não renomear e não remover nenhum arquivo em `~/.kiro/steering/` e `~/.kiro/hooks/` cujo nome não inicie com o Prefixo_MB (`mb--`) durante qualquer operação de instalação, atualização ou limpeza de órfãos.
5. IF um arquivo com Prefixo_MB em `~/.kiro/steering/` ou `~/.kiro/hooks/` não foi instalado pelo Script_Bootstrap ou Script_Sync (criado manualmente pelo usuário), THEN THE Script_Sync SHALL tratar o arquivo como gerenciado e sobrescrevê-lo caso exista correspondente no baseline, ou removê-lo como órfão caso não exista correspondente.

### Requirement 4: Sincronização no Escopo User

**User Story:** Como desenvolvedor, eu quero manter o baseline atualizado na minha máquina, para que todos os meus projetos reflitam as diretrizes organizacionais mais recentes.

#### Acceptance Criteria

1. WHEN o Script_Sync é executado com `--scope user`, THE Script_Sync SHALL comparar byte a byte cada arquivo com Prefixo_MB em `~/.kiro/steering/` com a versão correspondente em `baselines/global/steering/`, e cada arquivo com Prefixo_MB em `~/.kiro/hooks/` com a versão correspondente em `baselines/global/hooks/`.
2. WHEN um Steering_File ou Hook_Global do baseline possui conteúdo diferente da versão instalada com Prefixo_MB em `~/.kiro/steering/` ou `~/.kiro/hooks/` respectivamente, THE Script_Sync SHALL sobrescrever o arquivo com Prefixo_MB com a versão atualizada do baseline.
3. WHEN um novo Steering_File ou Hook_Global é adicionado ao baseline e não existe correspondente com Prefixo_MB no subdiretório respectivo de `~/.kiro/`, THE Script_Sync SHALL copiar o arquivo com o Prefixo_MB para o subdiretório correspondente (`steering/` ou `hooks/`).
4. WHEN o Script_Sync é executado com `--scope user`, THE Script_Sync SHALL atualizar o Baseline_Version_File (`~/.kiro/mb-baseline-version`) com a versão corrente de `baselines/global/VERSION`.
5. WHEN o Script_Sync é executado com `--scope user`, THE Script_Sync SHALL re-mergear os servidores MCP de `baselines/global/mcp/mcp.json` em `~/.kiro/settings/mcp.json`, adicionando servidores com chaves inexistentes e sobrescrevendo servidores com chaves já presentes no baseline, sem remover servidores cujas chaves não existem em `baselines/global/mcp/mcp.json`.
6. WHEN a flag `--dry-run` é informada com `--scope user`, THE Script_Sync SHALL simular a execução sem modificar nenhum arquivo no User_Kiro_Dir e exibir a lista de ações que seriam executadas (arquivos que seriam criados, atualizados ou removidos).
7. WHEN a sincronização no escopo user é concluída sem `--dry-run`, THE Script_Sync SHALL exibir um resumo contendo a quantidade de steering files novos, atualizados e sem mudança, hooks novos, atualizados e sem mudança, e servidores MCP adicionados ou atualizados.
8. IF um arquivo com Prefixo_MB em `~/.kiro/steering/` ou `~/.kiro/hooks/` não possui correspondente no baseline (arquivo removido do baseline), THEN THE Script_Sync SHALL remover o arquivo órfão e exibir mensagem informando a remoção com o nome do arquivo original.
9. IF o User_Kiro_Dir (`~/.kiro/`) não existir quando o Script_Sync é executado com `--scope user`, THEN THE Script_Sync SHALL encerrar com código de saída diferente de zero e exibir mensagem de erro indicando que o baseline não foi instalado e sugerindo executar `bootstrap.sh --scope user`.
10. IF o diretório `baselines/global/` não estiver acessível ou não existir quando o Script_Sync é executado com `--scope user`, THEN THE Script_Sync SHALL encerrar com código de saída diferente de zero e exibir mensagem de erro indicando que a fonte do baseline não foi encontrada.

### Requirement 5: Sincronização no Escopo Workspace

**User Story:** Como desenvolvedor de um projeto existente, eu quero atualizar apenas os artefatos do archetype no meu workspace, para que as customizações do projeto evoluam independentemente do baseline.

#### Acceptance Criteria

1. WHEN o Script_Sync é executado com `--scope workspace` e `--target`, THE Script_Sync SHALL comparar cada artefato do archetype (steering, skills, hooks, agents) com a versão correspondente no Workspace_Kiro_Dir, sobrescrevendo arquivos com conteúdo diferente, adicionando arquivos novos, e removendo arquivos que não existem mais no archetype fonte, sem tocar artefatos do baseline no User_Kiro_Dir.
2. WHEN o Script_Sync é executado com `--scope workspace` e `--target`, THE Script_Sync SHALL re-mergear os servidores MCP de `archetypes/<archetype>/mcp/mcp.json` em `<projeto>/.kiro/settings/mcp.json`, adicionando novos servidores e atualizando existentes, sem incluir servidores do baseline e sem remover servidores adicionados manualmente pelo desenvolvedor que não existem no archetype.
3. IF o Kiro_Manifest não existir no projeto alvo, THEN THE Script_Sync com `--scope workspace` SHALL encerrar com código de saída diferente de zero e exibir mensagem indicando que o Script_Bootstrap deve ser executado primeiro.
4. IF o argumento `--scope` não for informado ao Script_Sync, THEN THE Script_Sync SHALL exibir mensagem de erro indicando que o argumento é obrigatório e listar os valores válidos (`user`, `workspace`).
5. IF o argumento `--target` não for informado com `--scope workspace`, THEN THE Script_Sync SHALL encerrar com código de saída diferente de zero e exibir mensagem de erro indicando que `--target` é obrigatório para o escopo workspace.
6. WHEN a flag `--dry-run` é informada com `--scope workspace`, THE Script_Sync SHALL simular a execução sem criar, modificar ou remover nenhum arquivo no Workspace_Kiro_Dir, exibindo a lista de ações que seriam realizadas.
7. WHEN a sincronização no escopo workspace é concluída sem `--dry-run`, THE Script_Sync SHALL exibir um resumo contendo a quantidade de arquivos novos, atualizados, removidos e sem mudança.

### Requirement 6: Diagnóstico no Escopo User

**User Story:** Como desenvolvedor, eu quero verificar se o baseline está corretamente instalado na minha máquina, para garantir que todos os meus projetos herdam as diretrizes organizacionais.

#### Acceptance Criteria

1. WHEN o Script_Doctor é executado com `--scope user`, THE Script_Doctor SHALL verificar que o Baseline_Version_File (`~/.kiro/mb-baseline-version`) existe e contém uma versão válida no formato `MAJOR.MINOR.PATCH` (onde cada componente é um inteiro não-negativo sem zeros à esquerda), classificando como `[PASS]` se válido ou `[FAIL]` se o arquivo estiver ausente ou o conteúdo não corresponder ao formato.
2. WHEN o Script_Doctor é executado com `--scope user`, THE Script_Doctor SHALL comparar byte a byte cada Steering_File do baseline (em `baselines/global/steering/`) com seu correspondente com Prefixo_MB em `~/.kiro/steering/`, classificando como `[PASS]` (presente e idêntico), `[WARN]` (presente mas com conteúdo diferente) ou `[FAIL]` (ausente).
3. WHEN o Script_Doctor é executado com `--scope user`, THE Script_Doctor SHALL comparar byte a byte cada Hook_Global do baseline (em `baselines/global/hooks/`) com seu correspondente com Prefixo_MB em `~/.kiro/hooks/`, classificando como `[PASS]` (presente e idêntico), `[WARN]` (presente mas com conteúdo diferente) ou `[FAIL]` (ausente).
4. WHEN o Script_Doctor é executado com `--scope user`, THE Script_Doctor SHALL verificar que cada servidor MCP do baseline (definido em `baselines/global/mcp/mcp.json`) está presente em `~/.kiro/settings/mcp.json` com a mesma chave de servidor, reportando `[PASS]` se a chave existe ou `[WARN]` se a chave está ausente.
5. WHEN a flag `--output json` é informada com `--scope user`, THE Script_Doctor SHALL produzir o relatório em formato JSON estruturado com campos `timestamp`, `target` (valor `"~/.kiro"`), `scope` (valor `"user"`), `summary` (contendo contadores de pass, warn e fail) e `results` (array de objetos com `check`, `status` e `detail` para cada verificação).
6. IF ao menos 1 resultado `[FAIL]` é registrado durante a verificação com `--scope user`, THEN THE Script_Doctor SHALL encerrar com exit code 1; IF apenas resultados `[PASS]` ou `[WARN]` são registrados, THEN THE Script_Doctor SHALL encerrar com exit code 0.
7. IF o User_Kiro_Dir não existir, THEN THE Script_Doctor com `--scope user` SHALL reportar `[FAIL]` indicando que o baseline não foi instalado e sugerir executar `bootstrap.sh --scope user`.

### Requirement 7: Diagnóstico no Escopo Workspace

**User Story:** Como Tech Lead, eu quero verificar a conformidade do workspace com o archetype, incluindo a verificação de que o baseline está delegado ao nível do usuário.

#### Acceptance Criteria

1. WHEN o Script_Doctor é executado com `--scope workspace` e `--target`, THE Script_Doctor SHALL comparar cada artefato do archetype (steering, skills, hooks, agents) com a versão correspondente no diretório fonte do archetype, classificando como `[PASS]` (presente e idêntico), `[WARN]` (presente e desatualizado) ou `[FAIL]` (ausente no Workspace_Kiro_Dir).
2. WHEN o Script_Doctor é executado com `--scope workspace`, THE Script_Doctor SHALL verificar que o Kiro_Manifest contém o campo `baseline.scope` com valor `"user"`, reportando `[WARN]` caso o campo esteja ausente (indicando projeto no modelo legado).
3. WHEN o Script_Doctor é executado com `--scope workspace` e o Kiro_Manifest indica `baseline.scope: "user"`, THE Script_Doctor SHALL verificar que `~/.kiro/mb-baseline-version` existe, reportando `[WARN]` caso ausente com mensagem indicando executar `bootstrap.sh --scope user`.
4. IF o argumento `--scope` não for informado ao Script_Doctor e `--target` é informado, THEN THE Script_Doctor SHALL executar verificação em ambos os escopos (user e workspace) sequencialmente, consolidando os resultados em um único relatório.
5. WHEN a flag `--output json` é informada com `--scope workspace`, THE Script_Doctor SHALL produzir o relatório em formato JSON estruturado com campos `timestamp`, `target` (caminho do projeto), `scope` (valor `"workspace"`), `summary` e `results`.
6. THE Script_Doctor com `--scope workspace` SHALL encerrar com exit code 1 quando houver pelo menos 1 resultado `[FAIL]` e exit code 0 quando houver apenas warnings ou nenhum problema.
7. IF o Kiro_Manifest não existir no projeto alvo, THEN THE Script_Doctor com `--scope workspace` SHALL reportar `[FAIL]` indicando que o projeto não foi inicializado e sugerir executar `bootstrap.sh --scope workspace`.
8. IF o argumento `--target` não for informado com `--scope workspace`, THEN THE Script_Doctor SHALL encerrar com código de saída diferente de zero e exibir mensagem de erro indicando que `--target` é obrigatório para o escopo workspace.

### Requirement 8: Compatibilidade Retroativa

**User Story:** Como desenvolvedor de um projeto existente no modelo antigo, eu quero que meu projeto continue funcionando sem mudanças obrigatórias imediatas, para que a migração ocorra no meu ritmo.

#### Acceptance Criteria

1. IF um projeto possui Kiro_Manifest sem o campo `baseline.scope`, THEN THE Script_Doctor SHALL tratar o projeto como modelo legado e executar a verificação completa (baseline + archetype) no Workspace_Kiro_Dir, exibindo mensagem `[INFO]` que inclua a recomendação de migração e o comando `sync.sh --migrate-to-user-scope` como referência.
2. IF um projeto possui Kiro_Manifest sem o campo `baseline.scope`, THEN THE Script_Sync executado sem `--scope` SHALL sincronizar baseline e archetype juntos no Workspace_Kiro_Dir (mesmo comportamento do modelo antigo: copiar steering files do baseline e archetype, mergear MCP de ambos, copiar hooks de ambos) e encerrar com exit code 0.
3. IF o Script_Bootstrap é executado sem o argumento `--scope`, THEN THE Script_Bootstrap SHALL encerrar com exit code diferente de zero e exibir mensagem de erro indicando que `--scope` é obrigatório, listando os valores válidos (`user`, `workspace`).
4. IF um projeto não possui Kiro_Manifest (arquivo inexistente), THEN THE Script_Doctor e Script_Sync SHALL tratar o projeto como não inicializado e encerrar com código de erro, exibindo mensagem indicando que `bootstrap.sh` deve ser executado primeiro.
5. WHEN o Script_Sync é executado com `--migrate-to-user-scope` em um projeto no modelo legado (Kiro_Manifest sem campo `baseline.scope`), THE Script_Sync SHALL remover artefatos do baseline do Workspace_Kiro_Dir, atualizar o Kiro_Manifest adicionando `baseline.scope: "user"`, e exibir instrução para executar `bootstrap.sh --scope user`.
6. IF o Script_Sync é executado com `--migrate-to-user-scope` em um projeto que já possui `baseline.scope: "user"` no Kiro_Manifest, THEN THE Script_Sync SHALL encerrar com exit code 0 e exibir mensagem informando que o projeto já está no modelo novo, sem aplicar mudanças.

### Requirement 9: Precedência de Configuração

**User Story:** Como desenvolvedor, eu quero que configurações do workspace (archetype) tenham precedência sobre o baseline global, para que projetos possam especializar ou sobrescrever diretrizes quando necessário.

#### Acceptance Criteria

1. THE Kiro SHALL aplicar a seguinte ordem de precedência ao carregar artefatos: artefatos do User_Kiro_Dir (baseline com Prefixo_MB) como piso e artefatos do Workspace_Kiro_Dir (archetype) com precedência superior, onde um artefato do workspace com nome equivalente substitui completamente o artefato correspondente do baseline (o artefato do baseline não é carregado quando existe equivalente no workspace).
2. THE Kiro SHALL continuar carregando normalmente todos os artefatos do baseline (steering files e hooks com Prefixo_MB) que não possuem equivalente no Workspace_Kiro_Dir.
3. WHEN um servidor MCP com a mesma chave de identificação existe tanto em `~/.kiro/settings/mcp.json` (baseline) quanto em `<projeto>/.kiro/settings/mcp.json` (archetype), THE Kiro SHALL usar exclusivamente a configuração completa do servidor definida no workspace, ignorando todos os campos do servidor de mesma chave no baseline.
4. WHEN o Script_Doctor detecta um steering file no Workspace_Kiro_Dir cujo nome de arquivo (sem extensão) corresponde ao nome de um steering file do baseline após remoção do Prefixo_MB (exemplo: workspace `architecture.md` corresponde a baseline `mb--architecture.md`), THE Script_Doctor SHALL reportar `[INFO]` indicando que o arquivo do workspace está sobrescrevendo o correspondente do baseline.
5. WHEN o Script_Doctor detecta um hook no Workspace_Kiro_Dir cujo nome de arquivo (sem extensão `.kiro.hook`) corresponde ao nome de um Hook_Global do baseline após remoção do Prefixo_MB, THE Script_Doctor SHALL reportar `[INFO]` indicando que o hook do workspace está sobrescrevendo o correspondente do baseline.

### Requirement 10: Suporte a CI/CD

**User Story:** Como engenheiro de plataforma, eu quero que pipelines CI/CD funcionem sem depender de `~/.kiro/`, para que verificações automatizadas não falhem por ausência do diretório do usuário.

#### Acceptance Criteria

1. WHEN o Script_Doctor é executado em CI_Environment com `--scope workspace`, THE Script_Doctor SHALL verificar apenas artefatos do workspace sem acessar o User_Kiro_Dir e SHALL encerrar com exit code 0 quando todos os artefatos do archetype estiverem conformes.
2. WHEN o Script_Doctor é executado em CI_Environment com `--scope workspace` e o Kiro_Manifest indica `baseline.scope: "user"`, THE Script_Doctor SHALL pular a verificação de `~/.kiro/mb-baseline-version` e reportar `[INFO]` indicando que a verificação do baseline user-scope foi omitida por ambiente CI.
3. IF a variável de ambiente `CI` está definida com valor case-insensitive `true` (aceitando `true`, `TRUE`, `True`), THEN THE Script_Doctor, Script_Sync e Script_Bootstrap SHALL detectar o ambiente como CI_Environment.
4. WHEN o Script_Bootstrap é executado com `--scope user` em CI_Environment, THE Script_Bootstrap SHALL exibir mensagem de WARNING indicando que a instalação user-level é desnecessária em CI e encerrar com exit code 0 sem criar ou modificar arquivos no User_Kiro_Dir.
5. WHEN o Script_Sync é executado em CI_Environment com `--scope workspace`, THE Script_Sync SHALL sincronizar apenas artefatos do archetype no Workspace_Kiro_Dir sem acessar o User_Kiro_Dir e sem falhar por ausência de `~/.kiro/`.

### Requirement 11: Migração de Projetos Existentes

**User Story:** Como desenvolvedor de um projeto no modelo antigo, eu quero um comando claro para migrar meu projeto para o novo modelo de escopos, para que a transição seja segura e reversível.

#### Acceptance Criteria

1. WHEN o Script_Sync é executado com `--target` e `--migrate-to-user-scope`, THE Script_Sync SHALL criar backup dos artefatos do baseline presentes no Workspace_Kiro_Dir em `<projeto>/.kiro/.migration-backup/baseline/`.
2. WHEN o Script_Sync executa `--migrate-to-user-scope`, THE Script_Sync SHALL remover do Workspace_Kiro_Dir todos os steering files cujo nome de arquivo (sem extensão) corresponde a um arquivo presente em `baselines/global/steering/` (comparação por nome de arquivo).
3. WHEN o Script_Sync executa `--migrate-to-user-scope`, THE Script_Sync SHALL remover do `<projeto>/.kiro/settings/mcp.json` os servidores cuja chave existe em `baselines/global/mcp/mcp.json`, preservando servidores cuja chave existe apenas no archetype.
4. WHEN o Script_Sync executa `--migrate-to-user-scope`, THE Script_Sync SHALL atualizar o Kiro_Manifest adicionando o campo `baseline.scope` com valor `"user"` e removendo o campo `baseline.version` (pois a versão agora está em `~/.kiro/mb-baseline-version`).
5. WHEN a migração é concluída com sucesso, THE Script_Sync SHALL encerrar com exit code 0 e exibir mensagem indicando que a migração foi concluída, incluindo a instrução para executar `bootstrap.sh --scope user` caso o arquivo `~/.kiro/mb-baseline-version` não exista.
6. WHEN a flag `--dry-run` é informada com `--migrate-to-user-scope`, THE Script_Sync SHALL simular a migração sem aplicar mudanças, exibindo a lista de arquivos que seriam removidos e as alterações no manifest.
7. IF a migração falhar em qualquer etapa, THEN THE Script_Sync SHALL restaurar os arquivos a partir do backup em `<projeto>/.kiro/.migration-backup/baseline/`, exibir mensagem de erro indicando a etapa em que ocorreu a falha, e encerrar com exit code 1.
8. IF o Kiro_Manifest do projeto alvo já contém o campo `baseline.scope` com valor `"user"`, THEN THE Script_Sync SHALL encerrar com exit code 0 e exibir mensagem indicando que o projeto já está no modelo de escopo user, sem aplicar mudanças.
9. IF o Kiro_Manifest não existir no projeto alvo ao executar `--migrate-to-user-scope`, THEN THE Script_Sync SHALL encerrar com exit code diferente de zero e exibir mensagem de erro indicando que o projeto não possui manifest e orientando executar o Script_Bootstrap primeiro.

### Requirement 12: Limpeza de Artefatos Órfãos

**User Story:** Como desenvolvedor, eu quero que artefatos do baseline removidos da fonte sejam automaticamente limpos do meu `~/.kiro/`, para que não acumule configuração obsoleta.

#### Acceptance Criteria

1. WHEN o Script_Sync é executado com `--scope user`, THE Script_Sync SHALL identificar arquivos com Prefixo_MB em `~/.kiro/steering/` que não possuem correspondente em `baselines/global/steering/` (arquivo fonte removido), determinando a correspondência pela remoção do prefixo `mb--` do nome do arquivo instalado.
2. WHEN um artefato órfão com Prefixo_MB é identificado em `~/.kiro/steering/` ou `~/.kiro/hooks/`, THE Script_Sync SHALL remover o arquivo e exibir mensagem em stdout informando a remoção com o nome do arquivo original (sem Prefixo_MB).
3. WHEN o Script_Sync é executado com `--scope user`, THE Script_Sync SHALL identificar hooks com Prefixo_MB em `~/.kiro/hooks/` que não possuem correspondente em `baselines/global/hooks/` e removê-los, exibindo mensagem de remoção para cada hook.
4. WHEN o Script_Sync é executado com `--scope user`, THE Script_Sync SHALL identificar servidores MCP presentes em `~/.kiro/settings/mcp.json` cuja chave corresponda a um servidor anteriormente provisionado pelo baseline e que não exista mais em `baselines/global/mcp/mcp.json`, removendo-os do arquivo do usuário e preservando todos os servidores pessoais (não provisionados pelo baseline).
5. WHEN a flag `--dry-run` é informada com `--scope user`, THE Script_Sync SHALL listar em stdout cada artefato órfão (steering, hook ou servidor MCP) que seria removido, indicando tipo e nome, sem efetuar nenhuma remoção ou modificação de arquivo.
6. IF a remoção de um artefato órfão falhar (por erro de permissão ou indisponibilidade do arquivo), THEN THE Script_Sync SHALL exibir mensagem de erro indicando o arquivo que não pôde ser removido e o motivo, continuar processando os demais artefatos, e encerrar com exit code diferente de zero.
7. IF o arquivo `~/.kiro/settings/mcp.json` não existir quando a limpeza de servidores MCP órfãos é executada, THEN THE Script_Sync SHALL pular a verificação de servidores MCP órfãos sem reportar erro.
