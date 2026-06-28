# Requirements Document

## Introduction

Migração do modelo de distribuição de powers do repositório `mb-kiro` — atualmente baseado em cópia manual de arquivos via scripts bash — para o mecanismo nativo de instalação de Powers do Kiro. O objetivo é habilitar ativação dinâmica por keywords, economia de contexto, integração com o painel de Powers do IDE e mecanismo de updates nativo, eliminando a abordagem de "espalhar steering files" nos projetos.

## Glossary

- **Power**: Extensão modular do Kiro empacotada com POWER.md (obrigatório), mcp.json (opcional) e steering files (opcional), instalável nativamente no Kiro IDE
- **Bootstrap_Script**: Script `bootstrap.sh` que configura projetos novos com baseline, archetype e powers
- **Sync_Script**: Script `sync.sh` que atualiza projetos existentes a partir do manifest
- **Doctor_Script**: Script `doctor.sh` que diagnostica o estado de conformidade do Kiro em um projeto
- **Publish_Script**: Removido — powers são instalados diretamente do clone local do mb-kiro
- **Kiro_Manifest**: Arquivo `kiro-manifest.json` na raiz do projeto que registra archetype, baseline e powers instalados com versões e datas
- **Power_Structure**: Estrutura de diretórios de um power nativo do Kiro (POWER.md + mcp.json + steering/)
- **Native_Installation**: Instalação de um power via mecanismo nativo do Kiro (importar de pasta local), que registra o power no painel do IDE e habilita ativação dinâmica por keywords
- **MCP_Server**: Model Context Protocol server declarado no mcp.json de um power, que fornece ferramentas ao Kiro
- **Steering_File**: Arquivo markdown dentro de um power que fornece orientações contextuais ao agente Kiro
- **Placeholder_Power**: Power que existe na estrutura do repositório mas não possui funcionalidade implementada (ex: mb-mobile-flutter, mb-monorepo-nx)

## Requirements

### Requirement 1: Estrutura de Powers compatível com instalação nativa

**User Story:** Como mantenedor do mb-kiro, eu quero que cada power do repositório possua a estrutura completa exigida pelo Kiro nativo, para que possam ser instalados via mecanismo nativo de importação.

#### Acceptance Criteria

1. THE Power_Structure SHALL conter um arquivo POWER.md na raiz do diretório do power com frontmatter YAML válido incluindo os campos: name (string, identificador único do power), displayName (string, até 80 caracteres), description (string, até 300 caracteres), keywords (array com no mínimo 1 e no máximo 20 strings para ativação dinâmica) e author (string)
2. IF um power possuir MCP servers, THEN THE Power_Structure SHALL conter um arquivo mcp.json na raiz com um objeto "mcpServers" onde cada server é configurado como {"command": "...", "args": [...]} para processos locais ou {"type": "http", "url": "..."} para servers remotos
3. IF um power possuir steering files, THEN THE Power_Structure SHALL conter um diretório steering/ na raiz com pelo menos 1 arquivo markdown (.md) contendo instruções de orientação para o Kiro
4. THE Power_Structure SHALL ser auto-contida, sem referências a arquivos ou caminhos fora do diretório raiz do power, permitindo importação direta via "Import power from a folder" do Kiro IDE sem dependências de outros diretórios do repositório

### Requirement 2: Instalação de powers a partir do repositório local mb-kiro

**User Story:** Como desenvolvedor da MonteBravo, eu quero instalar powers diretamente a partir do clone local do repositório mb-kiro, para não depender de publicação em repositórios GitHub separados.

#### Acceptance Criteria

1. THE Power_Structure de cada power no repositório mb-kiro SHALL estar pronta para importação direta via "Import power from a folder" do Kiro IDE, apontando para o subdiretório `powers/<power-name>/` do clone local
2. WHEN o Bootstrap_Script instalar powers, THE Bootstrap_Script SHALL exibir o caminho absoluto do subdiretório do power no clone local do mb-kiro como caminho para importação nativa no Kiro IDE
3. THE Bootstrap_Script SHALL registrar no Kiro_Manifest o campo `source_path` com o caminho relativo do power no repositório mb-kiro (ex: `powers/mb-frontend-react`) para referência futura
4. WHEN o desenvolvedor precisar atualizar um power, THE Developer SHALL executar `git pull` no clone local do mb-kiro e usar "Check for updates" no painel de Powers do Kiro IDE

### Requirement 3: Adaptação do bootstrap para instalação nativa

**User Story:** Como desenvolvedor da MonteBravo, eu quero que o bootstrap registre quais powers o projeto precisa e me instrua a instalá-los nativamente, para que eu tenha acesso a ativação dinâmica por keywords e ao painel de Powers do IDE.

#### Acceptance Criteria

1. THE Bootstrap_Script SHALL deixar de copiar steering files de powers para `.kiro/steering/powers/<power-name>/`
2. THE Bootstrap_Script SHALL deixar de fazer merge do mcp.json de powers no `.kiro/settings/mcp.json` do projeto
3. WHEN o Bootstrap_Script concluir com pelo menos um power associado ao projeto, THE Bootstrap_Script SHALL exibir instruções contendo: o caminho absoluto de cada power no clone local do mb-kiro (`<mb-kiro-path>/powers/<power-name>/`), e a orientação para usar o menu "Import power from a folder" do Kiro IDE
4. THE Kiro_Manifest SHALL registrar cada power associado ao projeto com os campos: name, version, source_path (caminho relativo no mb-kiro), installed_at, e installation_method com valor "native"
5. IF o Bootstrap_Script for executado com a flag --force E já existirem powers registrados no manifest, THEN THE Bootstrap_Script SHALL atualizar as entradas existentes no manifest

### Requirement 4: Adaptação do sync para powers nativos

**User Story:** Como desenvolvedor da MonteBravo, eu quero que o sync identifique o estado dos powers e me oriente sobre como mantê-los atualizados, para manter o projeto alinhado com as versões mais recentes.

#### Acceptance Criteria

1. WHEN o Sync_Script detectar um power cujo campo `installation_method` no Kiro_Manifest é "native", THE Sync_Script SHALL comparar a versão registrada no manifest com a versão disponível no repositório mb-kiro e reportar se há atualização disponível
2. WHEN houver atualização disponível para um power nativo, THE Sync_Script SHALL exibir instrução para o desenvolvedor usar "Check for updates" no painel de Powers do Kiro IDE (após `git pull` no mb-kiro)
3. WHEN o Sync_Script detectar um power cujo campo `installation_method` no Kiro_Manifest é "legacy" ou ausente, THE Sync_Script SHALL emitir um aviso em stdout indicando o nome do power e a instrução para migrar via flag `--migrate-powers`
4. WHEN o Sync_Script detectar um power com `installation_method` "legacy" ou ausente, THE Sync_Script SHALL continuar executando a sincronização legada (copiar steering para `.kiro/steering/powers/<power-name>/` e fazer merge do mcp.json) sem interromper a execução
5. IF o diretório fonte de um power declarado no Kiro_Manifest não existir no repositório mb-kiro, THEN THE Sync_Script SHALL emitir um aviso em stdout indicando o nome do power não encontrado e prosseguir com os demais powers sem interromper a execução

### Requirement 5: Adaptação do doctor para validar instalação nativa

**User Story:** Como desenvolvedor da MonteBravo, eu quero que o doctor verifique se os powers estão corretamente configurados e me oriente sobre problemas, para identificar e resolver questões de configuração.

#### Acceptance Criteria

1. WHEN o Doctor_Script verificar powers, THE Doctor_Script SHALL validar que cada power declarado no Kiro_Manifest existe no repositório mb-kiro e possui um POWER.md válido com frontmatter completo (name, keywords, description)
2. IF um power declarado no Kiro_Manifest não existir no repositório mb-kiro, THEN THE Doctor_Script SHALL reportar status FAIL e indicar que o power foi removido ou renomeado
3. IF um power possuir steering files em `.kiro/steering/powers/<power-name>/`, THEN THE Doctor_Script SHALL reportar status WARN indicando instalação legada detectada e exibir o comando de migração (`--migrate-powers`) com instruções para concluir a instalação nativa via Kiro IDE
4. WHEN o Doctor_Script verificar a versão de um power, THE Doctor_Script SHALL comparar o campo version registrado no Kiro_Manifest com a versão disponível no repositório mb-kiro (arquivo VERSION do power) e reportar status WARN quando a versão local for inferior
5. IF o Doctor_Script detectar que um power está simultaneamente instalado via método legado (steering em `.kiro/steering/powers/`) e registrado como "native" no manifest, THEN THE Doctor_Script SHALL reportar status WARN indicando instalação duplicada e sugerir remoção dos arquivos legados

### Requirement 6: Migração de projetos existentes

**User Story:** Como desenvolvedor da MonteBravo, eu quero um processo claro para migrar meu projeto do método legado (steering copiado) para instalação nativa de powers, para obter os benefícios de ativação dinâmica.

#### Acceptance Criteria

1. WHEN um desenvolvedor executar o Sync_Script com a flag `--migrate-powers`, THE Sync_Script SHALL identificar todos os powers declarados no `kiro-manifest.json` cujo método de instalação atual não seja "native" e executar a migração para cada um deles
2. WHEN a migração for iniciada para um power, THE Sync_Script SHALL criar um backup dos arquivos que serão removidos em um diretório `.kiro/.migration-backup/<power-name>/` antes de executar qualquer operação destrutiva
3. WHEN a migração for executada para um power, THE Sync_Script SHALL remover os steering files legados do diretório `.kiro/steering/powers/<power-name>/`
4. WHEN a migração for executada para um power, THE Sync_Script SHALL identificar as entradas de MCP servers originárias desse power (comparando com o `mcp.json` do power no repositório mb-kiro) e removê-las do `.kiro/settings/mcp.json`, preservando as entradas de baseline e archetype
5. WHEN a migração for concluída com sucesso para um power, THE Sync_Script SHALL atualizar a entrada correspondente no array `powers` do `kiro-manifest.json` adicionando o campo `installation_method` com valor "native" e registrando a data em `migrated_at`
6. WHEN a migração for concluída com sucesso, THE Sync_Script SHALL exibir no terminal a lista de powers migrados e a instrução para o desenvolvedor usar "Import power from a folder" no Kiro IDE apontando para o subdiretório correspondente no clone local do mb-kiro
7. IF um power declarado no manifest não possuir steering files legados em `.kiro/steering/powers/<power-name>/`, THEN THE Sync_Script SHALL exibir um aviso indicando que o power já está migrado ou não possui instalação legada, e pular a migração desse power
8. IF ocorrer um erro durante a migração de um power, THEN THE Sync_Script SHALL restaurar os arquivos do backup em `.kiro/.migration-backup/<power-name>/`, exibir mensagem de erro indicando qual power falhou, e continuar a migração dos powers restantes

### Requirement 7: Tratamento de powers sem MCP

**User Story:** Como mantenedor do mb-kiro, eu quero que powers sem MCP servers (como mb-kiro-manager) funcionem corretamente via instalação nativa, para que toda a frota de powers use o mesmo mecanismo.

#### Acceptance Criteria

1. WHEN um power não possuir MCP servers, THE Power_Structure SHALL omitir o arquivo mcp.json do diretório raiz do power
2. THE Native_Installation SHALL funcionar corretamente para powers que possuem apenas POWER.md e steering files, sem erros de arquivo ausente ou falha por ausência de servidores MCP
3. WHEN um power sem MCP for instalado nativamente, THE Power_Structure SHALL ativar quando o prompt do usuário contiver ao menos uma das keywords definidas no frontmatter do POWER.md, e carregar os steering files associados somente após essa ativação
4. THE Power_Structure de um power sem MCP SHALL possuir keywords no frontmatter do POWER.md para habilitar ativação dinâmica; THE Doctor_Script SHALL reportar status FAIL se keywords estiverem ausentes

### Requirement 8: Remoção de powers placeholder

**User Story:** Como mantenedor do mb-kiro, eu quero remover powers placeholder que não possuem funcionalidade implementada, para evitar confusão e manter o repositório limpo.

#### Acceptance Criteria

1. WHEN um power não possuir nenhuma capacidade implementada (zero steering files com conteúdo funcional além de README.md, e nenhum mcp.json com servers válidos), THE Power_Structure SHALL ser movida para o diretório `powers/_drafts/<power-name>/` no repositório mb-kiro
2. IF um power estiver em `powers/_drafts/`, THEN THE Bootstrap_Script SHALL ignorar esse power durante a instalação e NÃO registrá-lo no Kiro_Manifest
3. IF um power placeholder estiver registrado no Kiro_Manifest de projetos existentes, THEN THE Sync_Script SHALL remover a entrada do power do array `powers` no kiro-manifest.json, remover o diretório `.kiro/steering/powers/<power-name>/` caso exista, e emitir um log informando quais referências foram removidas
4. THE Kiro_Manifest SHALL suportar um campo `status` em cada entrada do array `powers` com valores permitidos: "active" (padrão quando ausente) e "removed" (indica power que foi removido durante sync)
5. IF o Sync_Script não encontrar o diretório de um power declarado no manifest em `powers/<power-name>/` (nem em `powers/_drafts/`), THEN THE Sync_Script SHALL marcar o power como "removed" no manifest e emitir aviso

### Requirement 9: Documentação e onboarding

**User Story:** Como desenvolvedor da MonteBravo, eu quero documentação clara sobre como instalar, atualizar e diagnosticar powers nativos, para que eu possa manter meu projeto alinhado aos padrões sem precisar de suporte.

#### Acceptance Criteria

1. THE Bootstrap_Script SHALL exibir na seção "Próximos passos" instruções contendo: (a) como abrir o projeto no Kiro, (b) como instalar os powers listados no manifest via o painel de Powers do IDE usando "Import power from a folder", e (c) como executar o doctor.sh para validar a configuração
2. WHEN um novo power for adicionado ao repositório mb-kiro, THE Power_Structure SHALL conter no POWER.md uma seção "## Instalação" com: (a) pré-requisitos necessários, (b) passos para instalar via pasta local, e (c) passos para instalar via URL do repositório GitHub
3. IF o Doctor_Script detectar um problema relacionado a um power (ausente, desatualizado ou com erro de configuração), THEN THE Doctor_Script SHALL exibir junto ao diagnóstico um link para a página de troubleshooting correspondente no wiki Confluence da organização
4. THE Power_Structure SHALL conter no POWER.md uma seção "## Troubleshooting" com no mínimo 1 cenário documentado de problema conhecido e sua resolução
