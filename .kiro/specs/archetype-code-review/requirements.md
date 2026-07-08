# Requirements Document

## Introduction

Esta funcionalidade provê **code review automatizado via Kiro CLI headless** com agentes especializados para cada archetype da MonteBravo. Cada archetype define seus próprios agentes de revisão (em formato markdown para documentação e JSON para execução CLI), um workflow GitHub Actions que executa os agentes em paralelo em Pull Requests, e um script de bootstrap que provisiona o workflow e agentes no projeto destino.

Escopo explícito: esta feature NÃO inclui lint, type check, scans de segurança de dependências ou scripts de validação customizados — essas responsabilidades pertencem aos pipelines de CI/CD do time de arquitetura.

## Glossary

- **Archetype**: Template de configuração Kiro contendo hooks, skills, steering, agents e workflows para um tipo específico de projeto da MonteBravo.
- **Kiro_CLI**: Interface de linha de comando do Kiro que executa agentes em modo headless via `kiro-cli chat --no-interactive`.
- **Review_Agent**: Agente especializado configurado para revisar código de PRs seguindo padrões específicos do archetype.
- **Agent_Markdown**: Arquivo `.md` com frontmatter YAML contendo a definição do agente em formato legível para humanos (revisão e documentação).
- **Agent_JSON**: Arquivo `.json` compatível com `kiro-cli --agent=` para execução headless no CI.
- **Code_Review_Workflow**: GitHub Actions workflow que orquestra a execução paralela dos agentes de revisão em Pull Requests.
- **PR_Comment**: Comentário consolidado gerado automaticamente no Pull Request com o resultado de todos os agentes.
- **Comment_Marker**: Tag HTML invisível (`<!-- kiro-code-review-bot -->`) usada para identificar e atualizar o comentário do Kiro.
- **Bootstrap_Script**: Script que copia o workflow e os agentes CLI para o projeto destino.
- **KIRO_API_KEY**: Secret do GitHub necessário para autenticação do Kiro CLI no workflow.

## Requirements

### Requirement 1: Definição de Agentes por Archetype

**User Story:** Como engenheiro de plataforma, eu quero que cada archetype defina seus agentes de revisão especializados em dois formatos (markdown e JSON), para que tenhamos documentação legível e execução automatizada.

#### Acceptance Criteria

1. THE Archetype SHALL incluir um diretório `agents/` contendo ao menos um Agent_Markdown para cada especialidade de revisão do archetype.
2. THE Archetype SHALL incluir arquivos Agent_JSON nomeados com prefixo `cli-` (ex: `cli-code-reviewer.json`) para cada agente que participa do workflow de code review automatizado.
3. WHEN um Agent_Markdown for criado ou atualizado, THE Agent_Markdown SHALL conter frontmatter YAML com campos `name` e `description`, seguido do corpo com seções: Papel, Contexto, O que revisar e Formato de resposta.
4. WHEN um Agent_JSON for criado, THE Agent_JSON SHALL conter uma estrutura compatível com o parâmetro `--agent` do Kiro_CLI, permitindo execução headless sem modificações.
5. THE Archetype frontend-react SHALL definir os agentes: code-reviewer, architecture-reviewer, accessibility-reviewer e performance-reviewer.
6. THE Archetype backend-csharp SHALL definir os agentes: code-reviewer, architecture-reviewer, security-reviewer e performance-reviewer.
7. THE Archetype bff-fastify SHALL definir os agentes: code-reviewer, architecture-reviewer, api-contract-reviewer e performance-reviewer.
8. IF um Agent_Markdown não contiver os campos de frontmatter obrigatórios (`name`, `description`) ou as seções obrigatórias (Papel, Contexto, O que revisar, Formato de resposta), THEN THE CI validation SHALL reportar um erro e bloquear o PR.

### Requirement 2: Workflow GitHub Actions de Code Review

**User Story:** Como desenvolvedor, eu quero que um workflow execute agentes de revisão automaticamente quando eu abrir ou atualizar um Pull Request contra develop, para que eu receba feedback especializado sem esperar revisores humanos.

#### Acceptance Criteria

1. WHEN um Pull Request for aberto, sincronizado ou reaberto contra a branch `develop`, THE Code_Review_Workflow SHALL ser acionado automaticamente.
2. WHEN o Code_Review_Workflow for acionado, THE Code_Review_Workflow SHALL executar um job de preparação que obtém a lista de arquivos alterados (máximo 50 arquivos, excluindo dotfiles).
3. IF nenhum arquivo elegível for alterado no Pull Request, THEN THE Code_Review_Workflow SHALL encerrar sem executar os agentes de revisão.
4. WHEN arquivos elegíveis forem identificados, THE Code_Review_Workflow SHALL executar cada Review_Agent em um job paralelo independente.
5. WHEN um job de agente for executado, THE Code_Review_Workflow SHALL instalar o Kiro_CLI via `curl -fsSL https://cli.kiro.dev/install | bash` e invocar o agente com `kiro-cli chat --no-interactive --trust-tools=read,grep,glob,code --agent="<agent-name>" "<prompt>"`.
6. WHEN um job de agente completar a execução, THE Code_Review_Workflow SHALL salvar a saída como artifact do GitHub Actions com retenção de 1 dia.
7. IF um job de agente falhar por timeout ou erro de execução, THEN THE Code_Review_Workflow SHALL registrar um warning no workflow e continuar a execução dos demais jobs sem bloquear o pipeline.
8. IF o upload de artifact falhar após execução bem-sucedida do agente, THEN THE Code_Review_Workflow SHALL tratar o job como falho e aplicar o mesmo tratamento de erro do AC7 (warning e continuação).
9. THE Code_Review_Workflow SHALL requerer a permission `contents: read` e `pull-requests: write` para operar.
10. THE Code_Review_Workflow SHALL requerer o secret `KIRO_API_KEY` configurado no repositório para autenticar o Kiro_CLI.

### Requirement 3: Consolidação e Publicação do Resultado

**User Story:** Como desenvolvedor, eu quero receber um único comentário consolidado no PR com o feedback de todos os agentes, para que eu não precise navegar múltiplos comentários dispersos.

#### Acceptance Criteria

1. WHEN todos os jobs de agentes completarem (com sucesso ou falha), THE Code_Review_Workflow SHALL executar um job de consolidação que baixa todos os artifacts de revisão.
2. WHEN os artifacts forem processados, THE Code_Review_Workflow SHALL remover códigos ANSI de escape da saída dos agentes e extrair apenas o conteúdo markdown relevante.
3. THE Code_Review_Workflow SHALL montar um PR_Comment consolidado contendo: título geral, uma seção colapsável (tag `<details>`) por agente, e rodapé com metadata.
4. WHEN o Code_Review_Workflow for publicar o comentário, THE Code_Review_Workflow SHALL incluir o Comment_Marker (`<!-- kiro-code-review-bot -->`) no início do comentário para identificação.
5. IF um PR_Comment com o Comment_Marker já existir no Pull Request, THEN THE Code_Review_Workflow SHALL atualizar o comentário existente via PATCH em vez de criar um novo.
6. IF o Comment_Marker não for encontrado em nenhum comentário existente, THEN THE Code_Review_Workflow SHALL criar um novo comentário no Pull Request.
7. IF um agente não produzir resultado (artifact ausente), THEN THE Code_Review_Workflow SHALL exibir a mensagem "Nenhum resultado disponível" na seção correspondente do PR_Comment.
8. IF THE Code_Review_Workflow falhar ao criar ou atualizar o PR_Comment devido a erros de API, THEN THE Code_Review_Workflow SHALL realizar uma nova tentativa e, caso persista a falha, emitir um erro no log do workflow.

### Requirement 4: Bootstrap de Code Review no Projeto Destino

**User Story:** Como engenheiro de plataforma, eu quero que o bootstrap script provisione o workflow e agentes CLI no projeto destino, para que novos projetos tenham code review automatizado funcionando imediatamente.

#### Acceptance Criteria

1. WHEN o Bootstrap_Script for executado para um archetype, THE Bootstrap_Script SHALL copiar o arquivo `kiro-code-review.yml` do archetype para `.github/workflows/kiro-code-review.yml` do projeto destino, criando o diretório caso não exista.
2. WHEN o Bootstrap_Script for executado, THE Bootstrap_Script SHALL copiar todos os arquivos `cli-*.json` do diretório `agents/` do archetype para `.kiro/agents/` do projeto destino.
3. IF o projeto destino já possuir `.github/workflows/kiro-code-review.yml`, THEN THE Bootstrap_Script SHALL preservar o arquivo existente sem sobrescrevê-lo, evitando perda de customizações locais.
4. IF o projeto destino já possuir algum arquivo `cli-*.json` em `.kiro/agents/`, THEN THE Bootstrap_Script SHALL sobrescrever apenas os agentes cujo conteúdo difere do archetype, preservando agentes customizados que não existem no archetype.
5. THE Bootstrap_Script SHALL manter os arquivos Agent_Markdown apenas no repositório do archetype para documentação e revisão, sem copiá-los ao projeto destino.

### Requirement 5: Prompt e Contexto dos Agentes

**User Story:** Como engenheiro de plataforma, eu quero que cada agente receba a lista de arquivos alterados e instruções claras de formato, para que o feedback seja relevante, categorizado por severidade e acionável.

#### Acceptance Criteria

1. WHEN o Code_Review_Workflow invocar um Review_Agent, THE Code_Review_Workflow SHALL passar a lista de arquivos alterados no prompt do agente.
2. WHEN o Code_Review_Workflow invocar um Review_Agent, THE Code_Review_Workflow SHALL instruir o agente a ler os arquivos alterados e revisá-los conforme suas instruções de agente.
3. WHEN o Code_Review_Workflow invocar um Review_Agent, THE Code_Review_Workflow SHALL instruir o agente a categorizar findings por severidade usando os níveis definidos no agente (ex: bloqueante/importante/sugestão, alto/médio/baixo, ou crítico/alto/médio/baixo conforme a especialidade).
4. WHEN o Code_Review_Workflow invocar um Review_Agent, THE Code_Review_Workflow SHALL instruir o agente a formatar a saída como markdown.
5. THE Code_Review_Workflow SHALL conceder ao agente acesso ao repositório completo para contexto via tools `read`, `grep`, `glob` e `code`.
6. WHEN um agente de especialidade não aplicável ao PR for executado (ex: accessibility-reviewer sem componentes UI alterados), THE Review_Agent SHALL confirmar brevemente a não-aplicabilidade sem produzir feedback detalhado.
7. IF o Review_Agent detectar que há arquivos relevantes à sua especialidade nos arquivos alterados, THEN THE Review_Agent SHALL produzir revisão completa em vez de confirmar não-aplicabilidade.

### Requirement 6: Adaptabilidade do Workflow por Archetype

**User Story:** Como engenheiro de plataforma, eu quero que o workflow seja adaptável ao conjunto de agentes de cada archetype, para que cada stack receba revisão relevante à sua natureza.

#### Acceptance Criteria

1. THE Code_Review_Workflow do archetype frontend-react SHALL executar os jobs: review-code, review-architecture, review-accessibility e review-performance em paralelo.
2. THE Code_Review_Workflow do archetype backend-csharp SHALL executar os jobs: review-code, review-architecture, review-security e review-performance em paralelo.
3. THE Code_Review_Workflow do archetype bff-fastify SHALL executar os jobs: review-code, review-architecture, review-api-contract e review-performance em paralelo.
4. WHEN o PR_Comment consolidado for montado, THE Code_Review_Workflow SHALL incluir seções correspondentes apenas aos agentes configurados para o archetype.
5. THE Code_Review_Workflow SHALL ser um arquivo YAML independente por archetype, permitindo que cada archetype customize nomes de jobs, prompts e configurações sem afetar os demais.
