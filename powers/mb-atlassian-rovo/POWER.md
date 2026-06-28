---
name: "mb-atlassian-rovo"
displayName: "Atlassian Rovo MCP"
description: "Integração com Jira, Confluence e Compass via Atlassian Rovo MCP Server. Permite buscar, criar e atualizar issues, páginas e componentes diretamente do seu IDE."
keywords: ["atlassian", "jira", "confluence", "compass", "rovo", "issue", "sprint", "backlog", "kanban", "page", "space", "jsm", "service management"]
author: "MonteBravo"
---

# Atlassian Rovo MCP

## Overview

Este Power fornece integração completa com a plataforma Atlassian Cloud, permitindo interagir com Jira, Confluence, Compass e JSM diretamente do Kiro via linguagem natural.

### Capacidades principais:

1. **Jira** — Buscar, criar, editar e transicionar issues; gerenciar worklogs e comentários
2. **Confluence** — Buscar, criar e atualizar páginas e live docs; gerenciar comentários
3. **Compass** — Gerenciar componentes de software, relacionamentos e campos customizados
4. **Rovo Search** — Busca em linguagem natural unificada no Jira e Confluence
5. **JSM** — Gerenciar alertas de operações e schedules on-call
6. **Teamwork Graph** — Contexto completo de uma issue (PRs, deploys, builds, branches)

## Quando Usar Este Power

Ative este Power quando o usuário:

- Mencionar issues, bugs, tasks, stories, epics ou sprints do Jira
- Quiser criar, buscar ou atualizar páginas no Confluence
- Precisar consultar ou gerenciar componentes no Compass
- Mencionar: "minhas issues", "backlog", "sprint atual", "board", "workflow"
- Fornecer uma issue key (ex: `PROJ-123`) ou URL do Atlassian
- Quiser mover uma issue no workflow ou adicionar comentários
- Precisar buscar informações em linguagem natural no Jira/Confluence

## Autenticação

Na primeira utilização, o Kiro abrirá automaticamente o fluxo OAuth 2.1 no navegador. Autorize o acesso à sua instância Atlassian Cloud e pronto.

Alternativa: autenticação via API token — consulte https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/

## Ferramentas Disponíveis

### Jira

| Ferramenta | Descrição |
|---|---|
| `searchJiraIssuesUsingJql` | Buscar issues usando JQL |
| `getJiraIssue` | Obter detalhes de uma issue por ID ou key |
| `createJiraIssue` | Criar nova issue em um projeto |
| `editJiraIssue` | Atualizar campos de uma issue existente |
| `addCommentToJiraIssue` | Adicionar comentário a uma issue |
| `addWorklogToJiraIssue` | Adicionar worklog de tempo |
| `transitionJiraIssue` | Executar transição de workflow |
| `getTransitionsForJiraIssue` | Listar transições disponíveis |
| `getVisibleJiraProjects` | Listar projetos visíveis |
| `getJiraProjectIssueTypesMetadata` | Listar tipos de issue de um projeto |
| `getJiraIssueTypeMetaWithFields` | Obter metadados de campos para criação |
| `getJiraIssueRemoteIssueLinks` | Listar links remotos de uma issue |
| `lookupJiraAccountId` | Buscar account ID por nome ou email |

### Confluence

| Ferramenta | Descrição |
|---|---|
| `searchConfluenceUsingCql` | Buscar conteúdo usando CQL |
| `getConfluencePage` | Obter página por ID (corpo em Markdown) |
| `createConfluencePage` | Criar nova página ou live doc |
| `updateConfluencePage` | Atualizar página existente |
| `getConfluenceSpaces` | Listar spaces |
| `getPagesInConfluenceSpace` | Listar páginas de um space |
| `getConfluencePageDescendants` | Listar páginas descendentes |
| `createConfluenceFooterComment` | Criar comentário de rodapé |
| `createConfluenceInlineComment` | Criar comentário inline |
| `getConfluencePageFooterComments` | Listar comentários de rodapé |
| `getConfluencePageInlineComments` | Listar comentários inline |

### Compass

| Ferramenta | Descrição |
|---|---|
| `getCompassComponents` | Buscar/listar componentes |
| `getCompassComponent` | Obter detalhes de um componente por ID |
| `createCompassComponent` | Criar componente (service, library, etc.) |
| `deleteCompassComponent` | Deletar componente existente |
| `createCompassComponentRelationship` | Criar relacionamento entre componentes |
| `deleteCompassComponentRelationship` | Remover relacionamento |
| `getCompassComponentActivityEvents` | Listar eventos de atividade |
| `getCompassComponentLabels` | Obter labels de um componente |
| `getCompassComponentTypes` | Listar tipos de componente disponíveis |
| `getCompassComponentsOwnedByMyTeams` | Listar componentes dos meus times |
| `createCompassCustomFieldDefinition` | Criar definição de campo customizado |
| `deleteCompassCustomFieldDefinition` | Deletar campo customizado |
| `getCompassCustomFieldDefinitions` | Listar campos customizados |

### Rovo / Plataforma

| Ferramenta | Descrição |
|---|---|
| `search` | Busca em linguagem natural no Jira e Confluence |
| `fetch` | Buscar conteúdo por ARI (Atlassian Resource Identifier) |
| `atlassianUserInfo` | Obter dados do usuário atual |
| `getAccessibleAtlassianResources` | Listar sites Atlassian acessíveis |

### Jira Service Management

| Ferramenta | Descrição |
|---|---|
| `getJsmOpsAlerts` | Buscar alertas de operações |
| `updateJsmOpsAlert` | Ações em alertas (acknowledge, close, escalate) |
| `getJsmOpsScheduleInfo` | Listar schedules on-call |
| `getJsmOpsTeamInfo` | Listar times de operações |

### Teamwork Graph

| Ferramenta | Descrição |
|---|---|
| `getTeamworkGraphContext` | Contexto completo de uma issue (PRs, deploys, builds, branches) |
| `getTeamworkGraphObject` | Dados detalhados de objetos por ARI ou URL |

## Workflows Comuns

### Buscar issues atribuídas a mim

```
searchJiraIssuesUsingJql com JQL:
assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC
```

### Criar uma página no Confluence

Use `createConfluencePage` informando o spaceId, título e corpo em Markdown.

### Mover uma issue no workflow

1. Use `getTransitionsForJiraIssue` para listar transições disponíveis
2. Use `transitionJiraIssue` com o ID da transição desejada

### Busca em linguagem natural (Rovo Search)

Use `search` para buscas como:
- "Encontre todos os bugs críticos do último sprint"
- "Páginas sobre arquitetura de microserviços"
- "Issues bloqueadas no projeto X"

### Obter contexto completo de uma issue

Use `getTeamworkGraphContext` para ver PRs, deploys, builds e branches associados a uma issue.

## Instalação

### Pré-requisitos

- Kiro IDE instalado e atualizado
- Clone local do repositório `mb-kiro` (`git clone` ou acesso ao repo)
- Conta Atlassian Cloud com acesso aos produtos desejados (Jira, Confluence, Compass)
- Navegador disponível para fluxo OAuth 2.1 (ou API token configurado)

### Instalar via pasta local

1. Clone ou atualize o repositório `mb-kiro`:
   ```bash
   git clone <repo-url> ~/mb-kiro
   # ou, se já clonado:
   cd ~/mb-kiro && git pull
   ```
2. Abra o Kiro IDE no seu projeto
3. Acesse o painel de **Powers** (ícone de Powers na barra lateral)
4. Clique em **"Import power from a folder"**
5. Selecione o diretório: `<caminho-do-clone>/powers/mb-atlassian-rovo/`
6. Aguarde a confirmação de instalação

### Instalar via URL do repositório GitHub

1. Abra o Kiro IDE no seu projeto
2. Acesse o painel de **Powers**
3. Clique em **"Install from GitHub URL"**
4. Informe a URL do repositório apontando para o subdiretório do power
5. Aguarde a confirmação de instalação

### Verificar instalação

Após instalar, mencione algo relacionado ao Jira ou Confluence no chat (ex: "listar minhas issues") — o power deve ativar automaticamente pelas keywords configuradas. Na primeira utilização, o fluxo OAuth será iniciado no navegador.

## Troubleshooting

### Erro de autenticação OAuth

- Verifique se o navegador completou o fluxo de autorização
- Tente reconectar o servidor MCP pelo painel de Powers do Kiro
- Se o token expirou, reconecte para gerar um novo

### Ferramentas do Compass não funcionam

- Compass requer autenticação OAuth 2.1 (API token não é suportado)

### Ferramentas do JSM não aparecem

- JSM tools só funcionam com autenticação via API token
- O admin da organização precisa habilitar essa opção nas configurações do Rovo MCP Server

### Servidor não conecta

- Verifique se a URL está correta: `https://mcp.atlassian.com/v1/mcp`
- A URL antiga `/v1/sse` será descontinuada após 30 de junho de 2026

## Segurança

- O servidor atua como proxy e não armazena dados
- Todas as ações respeitam as permissões do seu usuário Atlassian
- Use o princípio do menor privilégio ao executar ações de escrita
- Revise ações de alto impacto (delete, transition) antes de confirmar

## Referências

- Documentação oficial: https://support.atlassian.com/atlassian-rovo-mcp-server/docs/use-atlassian-rovo-mcp-server/
- Autenticação via API token: https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/
