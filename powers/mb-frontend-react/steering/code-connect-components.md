# Code Connect — Conectar Componentes ao Figma

## Visão Geral

Workflow para conectar componentes do Figma às implementações no código via Code Connect. Analisa a estrutura do design, busca componentes correspondentes no código e estabelece mapeamentos.

## Pré-requisitos

- Figma MCP server conectado e acessível
- URL do Figma com `node-id`: `https://figma.com/design/:fileKey/:fileName?node-id=1-2`
- **Componente deve estar publicado** em uma team library no Figma
- Code Connect requer plano Organization ou Enterprise

## Workflow Obrigatório

**Seguir em ordem. Não pular etapas.**

### Passo 1: Obter Sugestões de Code Connect

Extrair `fileKey` e `nodeId` da URL. Converter formato do node ID: URL usa hífens (`node-id=1-2`), a tool espera dois-pontos (`nodeId=1:2`).

```
get_code_connect_suggestions(fileKey=":fileKey", nodeId="1:2")
```

**Respostas possíveis:**
- "No published components found" → informar o usuário e parar. O componente precisa ser publicado na team library.
- "All components already connected" → informar que já está mapeado.
- Lista de componentes não mapeados com: nome, node ID, properties e thumbnail.

### Passo 2: Buscar Componentes no Código

Para cada componente não mapeado, buscar correspondência no código.

**Onde buscar (nesta ordem de prioridade):**

1. `packages/design-system/` ou `@monte-bravo/design-system-web` — componentes do DS
2. `src/shared/ui/` — componentes reutilizáveis globais
3. `src/modules/<module>/shared/ui/` — componentes reutilizáveis do módulo
4. `src/modules/<module>/features/*/ui/` — componentes de features
5. `src/modules/<module>/widgets/*/ui/` — widgets

**Critérios de match:**
- Nome do componente (match exato ou similar)
- Props que correspondam às properties do Figma (variants, tamanhos, estados)
- Propósito funcional equivalente

Se houver múltiplos candidatos, apresentar os 2 mais próximos com explicação das diferenças.

### Passo 3: Apresentar Matches ao Usuário

Apresentar as correspondências encontradas:

```
Componentes encontrados:
- [Button](src/shared/ui/Button/Button.tsx) → Button no Figma (node 42:15)
- [Card](src/modules/portfolio/shared/ui/Card/Card.tsx) → ProductCard no Figma (node 10:51)

Sem correspondência:
- CustomWidget (10:53) — nenhum componente equivalente encontrado no código

Deseja conectar esses componentes? Pode aceitar todos, selecionar específicos, ou pular.
```

Se nenhum match for encontrado, sugerir:
- Criar o componente e depois conectar
- Indicar o caminho manualmente
- Pular o mapeamento

### Passo 4: Criar Mapeamentos

Após confirmação do usuário, executar `send_code_connect_mappings` com os mapeamentos aceitos.

```
send_code_connect_mappings(
  fileKey=":fileKey",
  nodeId="1:2",
  mappings=[
    { nodeId: "42:15", componentName: "Button", source: "src/shared/ui/Button/Button.tsx", label: "React" },
    { nodeId: "10:51", componentName: "Card", source: "src/modules/portfolio/shared/ui/Card/Card.tsx", label: "React" }
  ]
)
```

**Observações:**
- O `label` é sempre `"React"` nos projetos MonteBravo
- O `source` é relativo à raiz do projeto
- O `componentName` deve corresponder ao export do componente

**Após execução, apresentar resumo:**

```
Code Connect — Resumo:
✓ Conectados: 2
  - Button (42:15) → src/shared/ui/Button/Button.tsx
  - Card (10:51) → src/modules/portfolio/shared/ui/Card/Card.tsx
✗ Não conectados: 1
  - CustomWidget (10:53) — sem correspondência no código
```

## Erros Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| "No published components found" | Componente não publicado na library | Publicar na team library do Figma |
| "CODE_CONNECT_MAPPING_ALREADY_EXISTS" | Mapeamento já existe | Informar que já está conectado |
| "CODE_CONNECT_ASSET_NOT_FOUND" | Caminho do source incorreto | Verificar se o path e componentName estão corretos |
| "CODE_CONNECT_INSUFFICIENT_PERMISSIONS" | Sem permissão de edição no Figma | Solicitar acesso ao owner do arquivo |
| URL sem `node-id` | Parâmetro obrigatório ausente | Pedir ao usuário a URL completa com node-id |
