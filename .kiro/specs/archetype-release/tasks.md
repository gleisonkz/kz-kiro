# Implementation Plan

## Overview

Implementação do hook `release-components` para automatizar o processo de release de componentes versionáveis no repositório de governança Kiro. O plano consiste em 3 tasks: criar o steering de referência, criar o hook com prompt completo, e validar o fluxo.

## Tasks

- [x] 1. Criar steering file de referência do processo de release
  - Criar `.kiro/steering/release-process.md` com front-matter `inclusion: manual`
  - Documentar a lista de diretórios versionáveis (`archetypes/*`, `baselines/*`, `powers/*`)
  - Documentar o formato do VERSION file (apenas `MAJOR.MINOR.PATCH`, sem prefixo, sem newline)
  - Documentar o formato do CHANGELOG.md com exemplo completo
  - Documentar o formato das tags git (`<componente>@<versão>`)
  - Documentar a tabela de classificação semântica (tipo → bump)
  - Documentar o formato de Conventional Commits com escopo e limite de 72 chars
  - Documentar regras de breaking changes para este repositório
  - Documentar o fluxo ordenado de execução (detecção → análise → commits → version → changelog → release commit → tag)

- [x] 2. Criar o hook release-components
  - Criar `.kiro/hooks/release-components.kiro.hook` com `when.type: userTriggered`
  - Definir `then.type: askAgent` com prompt completo que instrui o agente a:
  - Executar `git status --porcelain` para detectar mudanças
  - Agrupar arquivos por componente versionável (subdiretórios de `archetypes/`, `baselines/`, `powers/`)
  - Ignorar arquivos fora de componentes versionáveis e arquivos soltos
  - Apresentar resumo dos componentes afetados e solicitar confirmação
  - Processar componentes em ordem alfabética
  - Analisar diffs e conteúdo de arquivos novos para classificação semântica
  - Questionar o usuário sobre classificação de arquivos untracked
  - Agrupar mudanças correlacionadas em commits únicos
  - Gerar commits no formato Conventional Commits com escopo (max 72 chars)
  - Ler/criar VERSION file e aplicar bump semver (primeira release = 0.1.0)
  - Gerar/atualizar CHANGELOG.md com formato definido no steering
  - Criar commit de release com VERSION + CHANGELOG
  - Criar tag anotada no formato `<componente>@<versão>`
  - Tratar erros e conflitos de tag com opções para o usuário
  - Apresentar resumo final com componentes, versões, commits e tags
  - Referenciar o steering `release-process.md` no prompt

- [ ] 3. Validar hook com execução em componentes com mudanças pendentes
  - Verificar que o hook aparece na lista de hooks disponíveis (userTriggered)
  - Acionar o hook e verificar detecção correta de componentes com mudanças
  - Verificar que o resumo lista corretamente os componentes afetados
  - Verificar que arquivos fora de componentes são reportados como excluídos
  - Verificar que o agente solicita confirmação antes de processar
  - Verificar que commits seguem Conventional Commits com escopo correto
  - Verificar que VERSION file é criado/atualizado corretamente
  - Verificar que CHANGELOG.md é gerado com formato correto
  - Verificar que tag anotada é criada no formato esperado
  - Verificar que o resumo final contém todas as informações esperadas

## Task Dependency Graph

```json
{
  "waves": [
    ["1. Criar steering file de referência do processo de release"],
    ["2. Criar o hook release-components"],
    ["3. Validar hook com execução em componentes com mudanças pendentes"]
  ]
}
```

Task 2 depende de Task 1 porque o hook referencia o steering para detalhes de formato.
Task 3 depende de Task 2 porque valida o hook criado.

## Notes

- O hook não executa `git push` — o push fica a cargo do usuário após revisar os resultados.
- A validação (Task 3) será feita com as mudanças reais pendentes no repositório no momento da execução.
- Futuramente, `docs/` e `scripts/` podem ser adicionados como componentes versionáveis editando o steering.
