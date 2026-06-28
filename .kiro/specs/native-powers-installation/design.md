# Technical Design: Native Powers Installation

## Overview

Migração do modelo de distribuição de powers do repositório `mb-kiro` para instalação nativa via Kiro IDE. O modelo atual (scripts copiam steering files e fazem merge de mcp.json) é substituído por um modelo onde o desenvolvedor instala powers diretamente do clone local do mb-kiro via "Import power from a folder".

## Architecture

Migração do modelo de distribuição de powers do repositório `mb-kiro` para instalação nativa via Kiro IDE. O modelo atual (scripts copiam steering files e fazem merge de mcp.json) é substituído por um modelo onde o desenvolvedor instala powers diretamente do clone local do mb-kiro via "Import power from a folder".

### Modelo Atual (Legado)

```
mb-kiro/powers/<power>/        Scripts copiam →     projeto/.kiro/steering/powers/<power>/
                                                    projeto/.kiro/settings/mcp.json (merge)
```

### Modelo Novo (Nativo)

```
mb-kiro/powers/<power>/        Dev importa →        Kiro IDE gerencia internamente
  POWER.md                     via painel
  mcp.json                     "Import from folder"
  steering/
  VERSION
```

**Fluxo:**
1. `bootstrap.sh` aplica baseline + archetype (como antes)
2. `bootstrap.sh` registra powers no manifest e exibe instruções
3. Dev abre Kiro IDE → Powers panel → "Import power from a folder"
4. Dev aponta para `<mb-kiro-clone>/powers/<power-name>/`
5. Kiro ativa dinamicamente por keywords

## Components and Interfaces

### bootstrap.sh — `install_powers()`

**Interface:** Recebe lista de powers a instalar (determinada pelo project-type + extras via `--powers`)

**Responsabilidades:**
- Filtrar powers em `powers/_drafts/` (ignorar)
- Validar POWER.md de cada power (frontmatter com name e keywords)
- Ler versão do arquivo VERSION
- Registrar no manifest com campos: name, version, source_path, installation_method="native", installed_at
- Exibir instruções de instalação nativa com caminhos absolutos

**Não faz mais:**
- Copiar steerings para `.kiro/steering/powers/`
- Merge de mcp.json de powers no `.kiro/settings/mcp.json`

### sync.sh — `sync_powers()` (dual-mode)

**Interface:** Lê manifest, determina installation_method de cada power

**Modo "native":**
- Compara version no manifest com VERSION file no mb-kiro
- Se diferente: exibe aviso + instrução "git pull + Check for updates"

**Modo "legacy" (compatibilidade):**
- Emite aviso sugerindo `--migrate-powers`
- Executa sync legado (copiar steerings + merge mcp.json)

### sync.sh — `migrate_powers()` (nova)

**Interface:** Flag `--migrate-powers` ativa esta função

**Passos por power:**
1. Backup em `.kiro/.migration-backup/<power>/`
2. Remove `.kiro/steering/powers/<power>/`
3. Identifica MCP servers do power (lê `mcp.json` do power no mb-kiro)
4. Remove esses servers do `.kiro/settings/mcp.json` do projeto
5. Atualiza manifest: installation_method="native", migrated_at=timestamp
6. Em caso de erro: restaura backup

**Identificação de MCP servers:**
```bash
# Ler keys de mcpServers do power
power_servers=$(jq -r '.mcpServers | keys[]' "${REPO_ROOT}/powers/${power}/mcp.json")
# Remover apenas essas keys do mcp.json do projeto
```

### doctor.sh — `check_powers()` (adaptada)

**Verificações por power:**
1. Existe em `powers/<name>/` no mb-kiro? (FAIL se não)
2. POWER.md tem frontmatter com keywords? (FAIL se não)
3. Versão manifest < VERSION file? (WARN)
4. Steering legado em `.kiro/steering/powers/<name>/`? (WARN)
5. Duplicado (legado + native)? (WARN)

### Estrutura de diretórios do repositório (atualizada)

```
powers/
  mb-atlassian-rovo/
    POWER.md          ← com frontmatter completo + Instalação + Troubleshooting
    mcp.json          ← {"mcpServers": {"atlassian-mcp-server": {...}}}
    VERSION           ← "1.0.0"
  mb-frontend-react/
    POWER.md          ← com frontmatter completo + Instalação + Troubleshooting
    mcp.json          ← {"mcpServers": {"figma": {...}}}
    steering/         ← workflow files
    VERSION           ← "1.0.0"
  mb-kiro-manager/
    POWER.md          ← com frontmatter + keywords + Instalação + Troubleshooting
    steering/         ← governance.md (sem inclusion: auto)
    VERSION           ← "1.0.0"
  _drafts/
    mb-mobile-flutter/  ← placeholder, ignorado por scripts
    mb-monorepo-nx/     ← placeholder, ignorado por scripts
```

## Data Models

### kiro-manifest.json — Schema atualizado para powers

```json
{
  "powers": [
    {
      "name": "mb-frontend-react",
      "version": "1.0.0",
      "source_path": "powers/mb-frontend-react",
      "installation_method": "native",
      "installed_at": "2026-06-25T10:00:00Z",
      "migrated_at": null
    }
  ]
}
```

**Campos por power entry:**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| name | string | Sim | Identificador único do power |
| version | string | Sim | Versão instalada (SemVer) |
| source_path | string | Sim | Caminho relativo no mb-kiro |
| installation_method | string | Sim | "native" ou "legacy" |
| installed_at | string (ISO 8601) | Sim | Data de registro |
| migrated_at | string (ISO 8601) | Não | Data da migração legado→nativo |
| status | string | Não | "active" (default) ou "removed" |

### VERSION file

Arquivo texto simples na raiz de cada power funcional. Contém apenas a versão SemVer:

```
1.0.0
```

Incrementado manualmente pelo mantenedor ao fazer mudanças no power.

### POWER.md frontmatter (obrigatório)

```yaml
---
name: "power-identifier"
displayName: "Nome Legível"
description: "Descrição até 300 chars"
keywords: ["keyword1", "keyword2"]
author: "MonteBravo"
---
```

## Error Handling

### bootstrap.sh

| Cenário | Comportamento |
|---------|--------------|
| Power não encontrado em `powers/` | Aviso + pula (não falha) |
| Power em `_drafts/` | Ignora silenciosamente |
| POWER.md ausente ou sem frontmatter | Aviso + pula |
| VERSION file ausente | Usa "0.0.0" como fallback |

### sync.sh --migrate-powers

| Cenário | Comportamento |
|---------|--------------|
| Erro ao remover steering legado | Restaura backup, reporta erro, continua com próximo |
| Erro ao manipular mcp.json | Restaura backup, reporta erro, continua |
| Power sem steering legado | Aviso "já migrado ou sem instalação legada", pula |
| jq não disponível | Erro fatal (jq necessário para manipular mcp.json) |

### doctor.sh

| Cenário | Comportamento |
|---------|--------------|
| mb-kiro repo não acessível | WARN "Não foi possível verificar powers no repositório" |
| Power no manifest mas não no repo | FAIL com instrução de remoção |
| POWER.md sem keywords | FAIL "Keywords obrigatórias para ativação dinâmica" |

## Correctness Properties

### Property 1: Idempotência do bootstrap
**Validates: Requirements 3.5**
Executar bootstrap múltiplas vezes com --force produz o mesmo manifest (sem entries duplicadas de powers).

### Property 2: Segurança da migração
**Validates: Requirements 6.2, 6.8**
Migração cria backup antes de qualquer operação destrutiva; falha em qualquer etapa restaura estado anterior completo.

### Property 3: Compatibilidade retroativa
**Validates: Requirements 4.3, 4.4**
Projetos com installation_method="legacy" continuam funcionando sem alteração até migração explícita via --migrate-powers.

### Property 4: Isolamento de MCP
**Validates: Requirements 6.4**
Remoção de MCP servers durante migração afeta apenas servers que existem no mcp.json do power (comparação explícita por key name). Servers de baseline e archetype são preservados.

### Property 5: Consistência de versão
**Validates: Requirements 4.1, 5.4**
VERSION file é a fonte de verdade para versão de um power; manifest registra snapshot no momento da instalação/sync.

## Testing Strategy

### Testes unitários (scripts)

- `bootstrap.sh --dry-run`: verificar que NÃO copia steerings nem faz merge mcp de powers
- `bootstrap.sh`: verificar manifest gerado com campos novos (source_path, installation_method)
- `sync.sh --migrate-powers --dry-run`: verificar operações planejadas sem executar
- `doctor.sh`: verificar detecção de legado, duplicado, desatualizado

### Testes de integração

- Bootstrap novo projeto → doctor passa → dev instala power → keywords ativam
- Migração de projeto legado → backup criado → legado removido → doctor passa
- Sync com power removido (em _drafts) → referência removida do manifest

### Smoke test manual

1. `bootstrap.sh --project-type frontend-react --target ./test-project`
2. Abrir test-project no Kiro
3. Import power from folder → `powers/mb-frontend-react/`
4. Digitar "implementar design do figma" → power ativa
