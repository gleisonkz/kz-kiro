---
name: "mb-frontend-react"
displayName: "Figma — MonteBravo Frontend"
description: "Integração Figma para projetos frontend React da MonteBravo. Implementa designs como código production-ready seguindo a stack e convenções do projeto (FSD, TailwindCSS 4, CVA, tokens semânticos, Design System). Também conecta componentes via Code Connect."
keywords: ["figma", "design", "implement", "component", "ui", "code generation", "design system", "code connect", "mapping", "design to code", "implement design", "implement component", "generate code", "connect component", "build design"]
author: "MonteBravo"
---

# Figma — MonteBravo Frontend

## Visão Geral

Este Power integra o Figma MCP Server ao workflow de desenvolvimento frontend da MonteBravo, traduzindo designs em código que segue as convenções do projeto: Feature-Sliced Design, TailwindCSS 4 com tokens semânticos, CVA para variantes, e Design System próprio.

## Capacidades

1. **Implementar Design** — Traduzir designs do Figma em código production-ready com fidelidade visual, respeitando a arquitetura e padrões do projeto.
2. **Code Connect** — Conectar componentes do Figma às implementações no código via Code Connect.

## Quando Ativar

Ativar este Power quando o usuário:

- Fornecer uma URL do Figma e quiser implementar o design como código
- Mencionar: implementar design, gerar código a partir do Figma, implementar componente, construir a partir do Figma
- Mencionar: code connect, conectar componente ao Figma, mapear componente
- Quiser estabelecer mapeamentos entre designs no Figma e código

## Ferramentas MCP Disponíveis

| Ferramenta | Descrição |
|------------|-----------|
| `get_design_context` | Busca dados estruturados do design (layout, tipografia, cores, spacing, estrutura) |
| `get_metadata` | Retorna representação XML esparsa com propriedades básicas dos layers |
| `get_screenshot` | Captura screenshot visual de uma seleção no Figma |
| `get_variable_defs` | Recupera variáveis e estilos (cores, spacing, tipografia) |
| `get_code_connect_suggestions` | Detecta e sugere mapeamentos Code Connect entre Figma e código |
| `send_code_connect_mappings` | Confirma mapeamentos Code Connect |
| `get_code_connect_map` | Mapeia node IDs do Figma a componentes no código |
| `add_code_connect_map` | Estabelece novos mapeamentos |
| `whoami` | Retorna identidade do usuário autenticado |

## Steering

Carregar o workflow apropriado conforme a intenção do usuário:

- **Implementar um design do Figma como código** → `implement-design.md`
- **Conectar componentes do Figma ao código via Code Connect** → `code-connect-components.md`

## Instalação

### Pré-requisitos

- Kiro IDE instalado e atualizado
- Clone local do repositório `mb-kiro` (`git clone` ou acesso ao repo)
- Figma MCP server acessível (URL: `https://mcp.figma.com/mcp`)
- Projeto com Design System configurado (`@monte-bravo/design-system-web`)

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
5. Selecione o diretório: `<caminho-do-clone>/powers/mb-frontend-react/`
6. Aguarde a confirmação de instalação

### Instalar via URL do repositório GitHub

1. Abra o Kiro IDE no seu projeto
2. Acesse o painel de **Powers**
3. Clique em **"Install from GitHub URL"**
4. Informe a URL do repositório apontando para o subdiretório do power
5. Aguarde a confirmação de instalação

### Verificar instalação

Após instalar, digite no chat algo como "implementar design do Figma" — o power deve ativar automaticamente pelas keywords configuradas.

## Troubleshooting

### Output do Figma truncado

O design é complexo demais para uma resposta. Use `get_metadata` para obter a estrutura de nodes e depois busque nodes específicos com `get_design_context`.

### Assets não carregam

O Figma MCP server serve assets em URLs `localhost`. Use essas URLs diretamente sem modificação. Não importe pacotes de ícones novos nem crie placeholders.

### Nenhum componente publicado encontrado (Code Connect)

Code Connect só funciona com componentes publicados em uma team library no Figma. Disponível apenas em planos Organization e Enterprise.

### Tokens do projeto diferem do Figma

Quando tokens do projeto diferem dos valores no Figma, preferir tokens do projeto para consistência, mas ajustar spacing/sizing para manter fidelidade visual.
