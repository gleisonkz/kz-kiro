# Implementation Plan: Native Powers Installation

## Overview

Migração do modelo de distribuição de powers via scripts (cópia de steerings + merge de mcp.json) para instalação nativa via Kiro IDE ("Import power from a folder"). Os scripts passam a apenas registrar quais powers o projeto precisa e instruir o dev a instalar nativamente.

## Tasks

- [x] 1. Criar VERSION files para powers funcionais
  - Criar `powers/mb-frontend-react/VERSION` com conteúdo `1.0.0`
  - Criar `powers/mb-atlassian-rovo/VERSION` com conteúdo `1.0.0`
  - Criar `powers/mb-kiro-manager/VERSION` com conteúdo `1.0.0`
- [x] 2. Mover powers placeholder para `_drafts/`
  - Criar diretório `powers/_drafts/`
  - Mover `powers/mb-mobile-flutter/` para `powers/_drafts/mb-mobile-flutter/`
  - Mover `powers/mb-monorepo-nx/` para `powers/_drafts/mb-monorepo-nx/`
- [x] 3. Ajustar POWER.md do mb-kiro-manager para instalação nativa
  - Adicionar frontmatter com keywords ao POWER.md
  - Remover `inclusion: auto` do frontmatter do `steering/governance.md`
  - Remover arquivo `mcp.json`
  - Adicionar seções "Instalação" e "Troubleshooting" ao POWER.md
- [x] 4. Adicionar seções obrigatórias aos POWER.md existentes
  - Adicionar seção "Instalação" ao `powers/mb-frontend-react/POWER.md`
  - Verificar/ajustar seção "Troubleshooting" no `powers/mb-frontend-react/POWER.md`
  - Adicionar seção "Instalação" ao `powers/mb-atlassian-rovo/POWER.md`
  - Verificar/ajustar seção "Troubleshooting" no `powers/mb-atlassian-rovo/POWER.md`
- [x] 5. Reescrever `install_powers()` no bootstrap.sh
  - Remover lógica de cópia de steering files para `.kiro/steering/powers/`
  - Remover lógica de merge de mcp.json do power no `.kiro/settings/mcp.json`
  - Adicionar filtro para ignorar powers em `powers/_drafts/`
  - Adicionar validação de POWER.md com frontmatter e keywords
  - Gerar entradas no manifest com campos: name, version, source_path, installation_method, installed_at
  - Exibir instruções de instalação nativa ao final
- [x] 6. Adaptar `sync_powers()` no sync.sh para dual-mode
  - Ler campo `installation_method` de cada power no manifest
  - Powers "native": comparar version e exibir aviso se desatualizado
  - Powers "legacy": emitir aviso sugerindo migrate, executar sync legado
  - Tratar powers em `_drafts/`: remover do manifest e limpar steering legado
- [x] 7. Implementar flag `--migrate-powers` no sync.sh
  - Adicionar `--migrate-powers` ao parse_args
  - Implementar backup em `.kiro/.migration-backup/<power>/`
  - Remover steering legado e MCP servers do power no mcp.json do projeto
  - Atualizar manifest com installation_method="native" e migrated_at
  - Implementar rollback em caso de erro
  - Exibir resumo final com instruções de instalação nativa
- [x] 8. Adaptar `check_powers()` no doctor.sh
  - Verificar existência do power no repo mb-kiro (não em _drafts)
  - Validar POWER.md tem frontmatter com keywords
  - Comparar versão manifest vs VERSION file
  - Detectar instalação legada residual e duplicada
  - Exibir instruções de resolução para cada problema
- [x] 9. Atualizar README.md do repositório
  - Atualizar seção "Como Usar" com novo fluxo de powers nativos
  - Documentar `--migrate-powers` e `powers/_drafts/`
- [x] 10. Atualizar testes
  - Ajustar testes do bootstrap para novo comportamento
  - Adicionar testes para: _drafts ignorado, sync nativo, migrate com backup, doctor detecta legado

## Task Dependency Graph

```json
{
  "waves": [
    {"tasks": ["1", "2", "3", "4"]},
    {"tasks": ["5"]},
    {"tasks": ["6", "8"]},
    {"tasks": ["7"]},
    {"tasks": ["9"]},
    {"tasks": ["10"]}
  ]
}
```

- Wave 1 (Tasks 1-4): Preparação do repositório — independentes entre si
- Wave 2 (Task 5): Bootstrap reescrito — depende dos powers estarem prontos
- Wave 3 (Tasks 6, 8): Sync dual-mode e Doctor — dependem do novo manifest format
- Wave 4 (Task 7): Migrate flag — depende do sync estar adaptado
- Wave 5 (Task 9): README — depende de tudo funcionar
- Wave 6 (Task 10): Testes — valida o conjunto

## Notes

- Powers são instalados pelo dev via "Import power from a folder" no Kiro IDE — não há CLI programática
- O clone local do mb-kiro é a fonte de verdade; `git pull` + "Check for updates" é o mecanismo de atualização
- Compatibilidade retroativa mantida: sync continua funcionando no modo legado para projetos não migrados
- Backup automático durante migração garante reversibilidade
