# Requirements Document

## Introduction

O Baseline Global é a configuração mínima obrigatória que todos os projetos da organização MonteBravo devem adotar, independentemente de stack tecnológica. Ele fornece steering files que o Kiro injeta como contexto em todas as interações, servidores MCP homologados e hooks globais, garantindo coerência organizacional em princípios de engenharia, segurança, documentação, especificações e gestão de dependências. O baseline é versionado independentemente, distribuído via scripts de automação (bootstrap/sync), verificado via diagnóstico (doctor) e governado por um processo formal de aprovação com exceções documentadas.

## Glossary

- **Baseline_Global**: Conjunto de artefatos (steering files, configuração MCP e hooks) que compõem a configuração mínima obrigatória para qualquer projeto da organização, localizado em `baselines/global/`.
- **Steering_File**: Documento markdown injetado pelo Kiro como contexto nas interações com o agente, contendo diretrizes, políticas ou princípios organizacionais.
- **MCP_Config**: Arquivo JSON (`mcp.json`) que declara os servidores MCP homologados pela organização para uso em todos os projetos.
- **Hook_Global**: Hook Kiro distribuído como parte do baseline que automatiza verificações ou ações aplicáveis a qualquer projeto.
- **Projeto_Alvo**: Repositório de produto que consome o baseline global e deve manter conformidade com suas diretrizes.
- **Kiro_Manifest**: Arquivo `kiro-manifest.json` na raiz do Projeto_Alvo que declara versões instaladas, archetype, powers e exceções.
- **VERSION_File**: Arquivo texto na raiz de `baselines/global/` contendo a versão atual no formato `MAJOR.MINOR.PATCH`.
- **Script_Bootstrap**: Script `bootstrap.sh` responsável por aplicar o baseline global e archetype em um projeto novo.
- **Script_Sync**: Script `sync.sh` responsável por atualizar o baseline e demais componentes em projetos existentes.
- **Script_Doctor**: Script `doctor.sh` responsável por diagnosticar conformidade de um projeto com o baseline.
- **Mantenedor**: Pessoa com permissão para aprovar mudanças no baseline global via Pull Request.
- **Exceção**: Desvio aprovado de uma diretriz do baseline, documentado no Kiro_Manifest do Projeto_Alvo.

## Requirements

### Requirement 1: Composição do Baseline Global

**User Story:** Como mantenedor da plataforma, eu quero que o baseline global tenha uma estrutura bem definida de artefatos, para que todos os projetos recebam um conjunto consistente e completo de diretrizes organizacionais.

#### Acceptance Criteria

1. THE Baseline_Global SHALL conter um diretório `steering/` com Steering_Files em formato markdown que o Kiro injeta como contexto nas interações.
2. THE Baseline_Global SHALL conter um diretório `mcp/` com um arquivo `mcp.json` declarando os servidores MCP homologados pela organização, contendo um objeto `mcpServers` com ao menos um servidor configurado.
3. THE Baseline_Global SHALL conter um diretório `hooks/` com Hook_Globals aplicáveis a qualquer projeto, onde cada hook é um arquivo com extensão `.kiro.hook` contendo JSON válido com as propriedades `name`, `when` e `then`.
4. THE Baseline_Global SHALL conter um VERSION_File na raiz com exatamente uma linha contendo a versão atual no formato Semantic Versioning `MAJOR.MINOR.PATCH` (valores numéricos sem zeros à esquerda, separados por ponto).
5. THE Baseline_Global SHALL conter um arquivo `CHANGELOG.md` documentando o histórico de mudanças por versão, com ao menos uma entrada correspondente à versão declarada no VERSION_File.
6. WHEN um novo Steering_File é adicionado ao Baseline_Global, THE Steering_File SHALL incluir um cabeçalho YAML frontmatter com a propriedade `inclusion` definindo o modo de injeção pelo Kiro, cujo valor deve ser exatamente `manual`, `auto` ou `fileMatch`.
7. IF a propriedade `inclusion` de um Steering_File possui o valor `fileMatch`, THEN THE Steering_File SHALL incluir no frontmatter a propriedade `fileMatchPattern` com um glob pattern válido indicando quais arquivos do projeto ativam a injeção.

### Requirement 2: Conteúdo dos Steering Files

**User Story:** Como engenheiro da organização, eu quero que os steering files cubram todos os aspectos fundamentais de governança técnica, para que o Kiro tenha contexto suficiente para orientar decisões de acordo com os padrões organizacionais.

#### Acceptance Criteria

1. THE Baseline_Global SHALL incluir um Steering_File `engineering-principles.md` contendo, no mínimo, as seguintes seções: princípios fundamentais de engenharia (pelo menos 3 princípios descritos), uma tabela de padrões técnicos obrigatórios e uma seção de anti-padrões a evitar.
2. THE Baseline_Global SHALL incluir um Steering_File `security-baseline.md` contendo, no mínimo, uma seção para cada um dos 5 domínios: autenticação e autorização, gestão de segredos, segurança de dependências, proteção de dados e comunicação segura entre serviços.
3. THE Baseline_Global SHALL incluir um Steering_File `specs-policy.md` contendo, no mínimo, as seguintes seções: princípios de especificação, estrutura padrão (template) de uma especificação, tabela de ciclo de vida com os estados possíveis e suas transições, e definição de onde as especificações devem ser armazenadas.
4. THE Baseline_Global SHALL incluir um Steering_File `documentation-baseline.md` contendo, no mínimo, as seguintes seções: lista de documentação obrigatória por projeto (README, CHANGELOG, pasta docs/), padrões de escrita, padrões de documentação de código e template de ADR.
5. THE Baseline_Global SHALL incluir um Steering_File `pinned-dependencies.md` contendo a regra obrigatória de uso de versões exatas (pinadas) para todas as dependências, com exemplos de formatos proibidos (caret, tilde, range, wildcard) e o formato correto (versão exata sem prefixo).
6. THE Steering_File `pinned-dependencies.md` SHALL usar frontmatter YAML com `inclusion: fileMatch` e `fileMatchPattern: "**/package.json"` para ser injetado apenas quando o contexto envolve arquivos de manifesto de dependências.
7. THE Steering_File `documentation-baseline.md` SHALL usar frontmatter YAML com `inclusion: fileMatch` e `fileMatchPattern: "**/*.md"` para ser injetado quando o contexto envolve arquivos markdown.
8. WHEN um Steering_File do Baseline_Global usa `inclusion: manual`, THE Steering_File SHALL ser injetado no contexto do Kiro apenas mediante ativação explícita pelo engenheiro ou por referência de outro steering file.
9. THE cada Steering_File do Baseline_Global SHALL incluir no frontmatter YAML o campo `inclusion` com um dos valores válidos: `manual`, `fileMatch` ou `always`.

### Requirement 3: Configuração de Servidores MCP Homologados

**User Story:** Como engenheiro da organização, eu quero que o baseline defina os servidores MCP homologados, para que todos os projetos tenham acesso a ferramentas padronizadas e aprovadas pela organização.

#### Acceptance Criteria

1. THE MCP_Config SHALL ser um arquivo JSON válido (parseável sem erros de sintaxe) que declara pelo menos 1 servidor MCP homologado para uso organizacional no campo `mcpServers`.
2. THE MCP_Config SHALL incluir um campo `_comment` no nível raiz contendo uma string não-vazia que identifique o propósito do arquivo (baseline global ou archetype-específico) e sua origem organizacional.
3. THE MCP_Config SHALL incluir um campo `_version` com a versão semântica da configuração no formato MAJOR.MINOR.PATCH (exemplo: "1.0.0").
4. WHEN um servidor MCP é adicionado à MCP_Config, THE MCP_Config SHALL incluir no objeto do servidor: um campo `_comment` com string não-vazia descrevendo a funcionalidade do servidor e o método de autenticação requerido, e um campo de conexão (`url` para servidores HTTP ou `command` com `args` para servidores executados via processo local).
5. THE MCP_Config SHALL definir `autoApprove` como array vazio para cada servidor declarado em `mcpServers`, exigindo aprovação explícita do usuário para cada operação.
6. WHEN um servidor MCP é adicionado à MCP_Config, THE MCP_Config SHALL incluir um campo `disabled` com valor booleano no objeto do servidor, indicando se o servidor está ativo (`false`) ou desativado (`true`) para uso.

### Requirement 4: Distribuição via Bootstrap

**User Story:** Como Tech Lead iniciando um projeto novo, eu quero que o baseline global seja aplicado automaticamente durante o bootstrap, para que o projeto já comece em conformidade com os padrões organizacionais.

#### Acceptance Criteria

1. WHEN o Script_Bootstrap é executado com `--target` e `--project-type`, THE Script_Bootstrap SHALL copiar todos os Steering_Files (arquivos `*.md`, excluindo `README.md`) do Baseline_Global para `<projeto>/.kiro/steering/`.
2. WHEN o Script_Bootstrap é executado com `--target` e `--project-type`, THE Script_Bootstrap SHALL copiar os arquivos do archetype correspondente (steering, skills, hooks e agents) para os subdiretórios respectivos em `<projeto>/.kiro/`.
3. WHEN o Script_Bootstrap é executado, THE Script_Bootstrap SHALL gerar um `mcp.json` mergeado (baseline + archetype) em `<projeto>/.kiro/settings/mcp.json`, onde as entradas do archetype têm precedência sobre o baseline em caso de conflito de chaves.
4. WHEN o Script_Bootstrap é executado, THE Script_Bootstrap SHALL gerar um Kiro_Manifest na raiz do Projeto_Alvo contendo: a versão do baseline instalada, o nome e versão do archetype, a lista de powers instalados e um array de exceções vazio.
5. IF um arquivo de destino já existe e a flag `--force` não foi informada, THEN THE Script_Bootstrap SHALL pular o arquivo e exibir uma mensagem de log com nível WARNING indicando o nome do arquivo pulado.
6. WHEN a flag `--dry-run` é informada, THE Script_Bootstrap SHALL simular a execução sem criar ou modificar nenhum arquivo no Projeto_Alvo, exibindo a lista de arquivos que seriam copiados e os merges que seriam realizados.
7. IF o `--project-type` informado não corresponde a nenhum archetype disponível, THEN THE Script_Bootstrap SHALL encerrar a execução com código de saída diferente de zero e exibir mensagem de erro listando os tipos válidos.
8. THE Script_Bootstrap SHALL validar que Git está instalado no ambiente antes de iniciar a aplicação do baseline, encerrando com código de saída diferente de zero e mensagem de erro caso o pré-requisito não seja atendido.

### Requirement 5: Atualização via Sync

**User Story:** Como engenheiro de um projeto existente, eu quero manter o baseline atualizado com a versão mais recente, para que meu projeto evolua junto com os padrões organizacionais sem perder customizações locais.

#### Acceptance Criteria

1. WHEN o Script_Sync é executado com `--target` e `--component baseline`, THE Script_Sync SHALL comparar byte a byte cada Steering_File do Baseline_Global com a versão instalada no Projeto_Alvo, excluindo arquivos README.md da comparação.
2. WHEN um Steering_File do Baseline_Global possui conteúdo diferente da versão instalada no Projeto_Alvo, THE Script_Sync SHALL sobrescrever o arquivo no Projeto_Alvo com a versão do Baseline_Global.
3. WHEN um Steering_File novo é adicionado ao Baseline_Global e não existe no Projeto_Alvo, THE Script_Sync SHALL copiar o arquivo para o Projeto_Alvo.
4. WHEN o Script_Sync é executado com `--component all`, THE Script_Sync SHALL sincronizar os componentes na ordem fixa: baseline, archetype e powers.
5. WHEN a sincronização é concluída com sucesso e a flag `--dry-run` não está ativa, THE Script_Sync SHALL atualizar o campo `baseline.last_synced_at` no Kiro_Manifest com o timestamp UTC da execução no formato ISO 8601.
6. WHEN a flag `--dry-run` é informada, THE Script_Sync SHALL simular a execução sem aplicar mudanças no Projeto_Alvo, listando cada arquivo que seria adicionado e cada arquivo que seria atualizado.
7. IF o Kiro_Manifest não existir no Projeto_Alvo, THEN THE Script_Sync SHALL encerrar a execução com código de erro e exibir mensagem indicando que o usuário deve executar o Script_Bootstrap primeiro.
8. WHEN a sincronização é concluída sem a flag `--dry-run`, THE Script_Sync SHALL exibir um resumo contendo a quantidade de arquivos novos, atualizados e sem mudança.
9. IF o valor informado em `--component` não for um dos valores válidos (baseline, archetype, powers, all), THEN THE Script_Sync SHALL encerrar a execução com código de erro e exibir mensagem indicando os valores válidos aceitos.
10. IF o diretório informado em `--target` não existir ou não for acessível, THEN THE Script_Sync SHALL encerrar a execução com código de erro e exibir mensagem indicando que o diretório destino não foi encontrado.

### Requirement 6: Verificação de Conformidade via Doctor

**User Story:** Como mantenedor da plataforma, eu quero verificar se um projeto está em conformidade com o baseline global, para identificar desvios e garantir que os padrões estão sendo seguidos.

#### Acceptance Criteria

1. WHEN o Script_Doctor é executado com `--target`, THE Script_Doctor SHALL verificar se o Kiro_Manifest existe e contém JSON parseável com os campos obrigatórios (`baseline.version`, `archetype.name`), reportando `[FAIL]` para cada campo ausente ou JSON inválido.
2. WHEN o Script_Doctor verifica o baseline, THE Script_Doctor SHALL comparar cada Steering_File presente no diretório `baselines/global/steering/` do repositório mb-kiro (exceto README.md) com a versão instalada em `.kiro/steering/` do Projeto_Alvo, classificando cada arquivo como "atualizado" (`[PASS]`), "desatualizado" (`[WARN]`) ou "ausente" (`[FAIL]`).
3. WHEN um Steering_File está ausente no Projeto_Alvo, THE Script_Doctor SHALL reportar como falha crítica (`[FAIL]`).
4. WHEN um Steering_File está desatualizado (conteúdo difere byte-a-byte da versão no repositório mb-kiro), THE Script_Doctor SHALL reportar como atenção (`[WARN]`).
5. WHEN a flag `--verbose` é informada, THE Script_Doctor SHALL exibir para cada arquivo desatualizado o diff em formato unified (3 linhas de contexto) e para cada diretório com arquivos ausentes a lista nominal dos arquivos faltantes.
6. WHEN a flag `--output json` é informada, THE Script_Doctor SHALL produzir o relatório em formato JSON estruturado com campos `timestamp` (ISO 8601 UTC), `target` (caminho absoluto), `summary` (objeto com `passed`, `warned`, `failed` como inteiros) e `results` (array de objetos contendo `status`, `category` e `message`, e opcionalmente `details` quando verbose).
7. THE Script_Doctor SHALL encerrar com exit code 1 quando houver pelo menos 1 falha crítica (`[FAIL]`) e exit code 0 quando houver apenas warnings ou nenhum problema.
8. THE Script_Doctor SHALL verificar a presença do `mcp.json` em `.kiro/settings/` e comparar os servidores MCP configurados com os declarados no baseline, reportando `[WARN]` quando houver divergência de servidores e `[PASS]` quando estiverem sincronizados.
9. IF o argumento `--target` não é fornecido ou o caminho informado não existe, THEN THE Script_Doctor SHALL exibir mensagem de erro indicando o problema e encerrar com exit code 1 sem executar verificações.
10. WHEN o Script_Doctor verifica o archetype, THE Script_Doctor SHALL comparar os arquivos de cada categoria do archetype declarado no manifest (steering, skills, hooks, agents) com os instalados em `.kiro/` do Projeto_Alvo, reportando `[FAIL]` quando um diretório de categoria está completamente ausente e `[WARN]` quando há arquivos faltantes dentro da categoria.

### Requirement 7: Governança e Processo de Mudança

**User Story:** Como mantenedor da plataforma, eu quero que mudanças no baseline sigam um processo formal de aprovação, para garantir qualidade, consenso e rastreabilidade das decisões.

#### Acceptance Criteria

1. WHEN uma mudança no Baseline_Global é proposta, THE Mantenedor SHALL abrir uma issue descrevendo a mudança, motivação e impacto esperado nos projetos consumidores.
2. WHEN uma issue de mudança no Baseline_Global é aberta, THE Mantenedor SHALL aguardar um período mínimo de discussão de 5 dias úteis antes de aprovar o Pull Request.
3. WHEN um Pull Request de mudança no Baseline_Global é aberto, THE Pull_Request SHALL requerer aprovação de ao menos 2 Mantenedores para merge.
4. THE Baseline_Global SHALL seguir Conventional Commits para mensagens de commit, usando o escopo `global` (ex: `feat(global): descrição`) e restringindo os tipos permitidos a: `feat`, `fix`, `docs`, `refactor`, `chore`, `perf` e `ci`.
5. WHEN um Pull Request é mergeado com mudanças no Baseline_Global, THE Mantenedor SHALL incrementar o VERSION_File seguindo versionamento semântico (MAJOR para mudanças incompatíveis com projetos consumidores, MINOR para adições retrocompatíveis, PATCH para correções que não alteram comportamento) e atualizar o CHANGELOG com tipo de mudança, descrição e data no formato AAAA-MM-DD.
6. IF uma mudança no Baseline_Global é classificada como hotfix crítico, THEN THE Mantenedor SHALL requerer aprovação express de ao menos 1 Mantenedor, sem exigência do período de 5 dias úteis, e registrar a justificativa de urgência na issue correspondente.
7. IF o período de discussão de 5 dias úteis se encerrar sem consenso entre os Mantenedores, THEN THE Mantenedor proponente SHALL registrar os pontos de divergência na issue e escalar a decisão para votação entre todos os Mantenedores ativos, com aprovação por maioria simples.

### Requirement 8: Versionamento Semântico

**User Story:** Como engenheiro de um projeto consumidor, eu quero que o baseline use versionamento semântico, para que eu saiba quando uma atualização pode quebrar algo e possa planejar migrações.

#### Acceptance Criteria

1. THE Baseline_Global SHALL usar versionamento semântico no formato `MAJOR.MINOR.PATCH`, onde cada segmento é um inteiro não-negativo sem zeros à esquerda, registrado no VERSION_File.
2. WHEN um Steering_File é removido ou renomeado, ou uma diretriz obrigatória existente é removida, THE Mantenedor SHALL incrementar o dígito MAJOR da versão e redefinir MINOR e PATCH para 0.
3. WHEN um novo Steering_File é adicionado ou uma nova diretriz é incluída em arquivo existente sem alterar nem remover diretrizes existentes, THE Mantenedor SHALL incrementar o dígito MINOR da versão e redefinir PATCH para 0.
4. WHEN uma correção de texto, typo ou melhoria de documentação é aplicada sem mudança de diretriz, THE Mantenedor SHALL incrementar o dígito PATCH da versão.
5. THE VERSION_File SHALL conter apenas a string de versão sem prefixo `v`, sem espaços adicionais e sem quebra de linha ao final.
6. IF uma release contém mudanças que se enquadram em mais de uma categoria de incremento, THEN THE Mantenedor SHALL aplicar apenas o incremento de maior precedência (MAJOR > MINOR > PATCH).

### Requirement 9: Mecanismo de Exceções

**User Story:** Como Tech Lead de um projeto com necessidades específicas, eu quero poder solicitar exceções ao baseline quando justificado tecnicamente, para manter a autonomia do time sem ignorar a governança.

#### Acceptance Criteria

1. WHEN um Projeto_Alvo precisa desviar de uma diretriz do Baseline_Global, THE Tech_Lead SHALL documentar a exceção no array `exceptions` do Kiro_Manifest com um objeto contendo, no mínimo, os campos: `rule` (identificador da diretriz no formato `<componente>.<nome-da-regra>`), `reason` (justificativa técnica com no mínimo 20 caracteres e no máximo 500 caracteres), `approved_by` (identificador do Mantenedor aprovador) e `approved_at` (data de aprovação no formato ISO 8601).
2. WHEN uma Exceção é documentada no Kiro_Manifest, THE Tech_Lead SHALL comunicar os Mantenedores abrindo uma issue no repositório mb-kiro contendo o identificador da regra e a justificativa técnica no prazo de até 5 dias úteis após a inserção da exceção.
3. THE Exceção documentada no Kiro_Manifest SHALL conter o campo `review_date` com a data da próxima revisão obrigatória, que não deve ultrapassar 90 dias corridos a partir da data de `approved_at`.
4. IF o Script_Doctor encontrar um Steering_File ausente ou com conteúdo divergente do Baseline_Global e o arquivo estiver coberto por uma Exceção cujo campo `approved_at` existe, cujo campo `approved_by` não está vazio, e cujo campo `review_date` não ultrapassou a data corrente, THEN THE Script_Doctor SHALL reportar o item como informação (nível INFO) em vez de falha (nível FAIL).
5. IF o Script_Doctor encontrar um Steering_File coberto por uma Exceção cuja `review_date` é anterior à data corrente, THEN THE Script_Doctor SHALL reportar o item como atenção (nível WARN) indicando que a exceção expirou e precisa ser revisada.

### Requirement 10: Hook Global de Diagnóstico

**User Story:** Como engenheiro de um projeto, eu quero ter um hook de diagnóstico disponível diretamente no Kiro, para verificar a conformidade do meu projeto sem sair do IDE.

#### Acceptance Criteria

1. THE Baseline_Global SHALL incluir um Hook_Global `kiro-doctor.kiro.hook` no diretório `baselines/global/hooks/`, do tipo `userTriggered`, com o campo `enabled` definido como `true`.
2. WHEN o Hook_Global de diagnóstico é acionado, THE Hook_Global SHALL instruir o agente Kiro a: ler a estrutura `.kiro/` do Projeto_Alvo (steering, hooks, settings/mcp.json, specs, skills, agents), identificar o archetype aplicável ao projeto, comparar os artefatos presentes com os definidos no Baseline_Global (`baselines/global/`) e no archetype correspondente (`archetypes/{archetype}/`), e gerar um relatório markdown com o resultado da comparação.
3. THE relatório gerado pelo Hook_Global SHALL incluir as seguintes seções, nesta ordem: resumo de saúde (usando indicadores visuais ✅ OK, ⚠️ Atenção e ❌ Problema para cada categoria), steering files (presentes, ausentes e extras em relação ao esperado), hooks (configurados, habilitados/desabilitados e ausentes do archetype), MCP servers (configurados vs baseline, extras ou ausentes), skills (presentes vs esperados pelo archetype), specs (listagem com status: completa, em progresso ou pendente) e recomendações (ações sugeridas para alinhar o projeto com a governança).
4. THE Hook_Global SHALL salvar o relatório como `kiro-doctor-report.md` na raiz do Projeto_Alvo.
5. IF o Projeto_Alvo não possuir o diretório `.kiro/`, THEN THE Hook_Global SHALL gerar o relatório indicando status ❌ Problema no resumo de saúde e incluindo uma recomendação para inicializar a estrutura `.kiro/` no projeto.
