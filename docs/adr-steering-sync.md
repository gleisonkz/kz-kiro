# Sincronização ADRs × Steering Files

> **Objetivo:** Manter os steering files deste repositório alinhados com as ADRs (Architecture Decision Records) aprovadas no Confluence.

---

## Por que isso existe?

Os steering files definem os padrões organizacionais que o Kiro usa como contexto. As ADRs no Confluence registram decisões arquiteturais aprovadas pelo time. Se uma ADR é aprovada e o steering não é atualizado, o Kiro opera com informação desatualizada.

Este processo garante que:
- Decisões aprovadas sejam refletidas nos steerings
- Contradições entre steerings e ADRs sejam identificadas
- O repositório de governança evolua junto com as decisões do time

---

## Escopo: O que entra e o que não entra

Nem toda ADR deve virar steering. Os hooks filtram automaticamente, mas é importante entender a lógica:

| Tipo de ADR | Exemplo | Entra no steering? |
|---|---|---|
| **Organizacional/Transversal** | Stack base de frontend, monorepo vs multi-repo, design system | ✅ Sim |
| **Domínio/Produto Específico** | Arquitetura do serviço de KYC, integração com Neoway | ❌ Não |

**Regra prática:** Se a decisão vale para múltiplos projetos/times, ela é organizacional. Se vale só para um serviço específico, é de domínio.

---

## Hooks Disponíveis

Os hooks ficam em `.kiro/hooks/` e são acionados manualmente pela seção **Agent Hooks** no explorer do Kiro.

### 1. Sincronizar ADRs do Confluence

**Arquivo:** `sync-adrs-confluence.kiro.hook`

**Quando usar:**
- Periodicamente (sugestão: a cada 2 semanas ou início de sprint)
- Quando souber que ADRs novas foram aprovadas no Confluence

**O que faz:**
1. Busca todas as ADRs no Confluence via CQL
2. Filtra apenas ADRs organizacionais (exclui domínio específico)
3. Correlaciona com os steerings locais
4. Gera `adr-sync-report.md` na raiz com gaps e recomendações

**Resultado esperado:** Um relatório mostrando quais ADRs já estão refletidas e quais têm gaps.

---

### 2. Validar Steering contra ADRs

**Arquivo:** `validate-steering-adrs.kiro.hook`

**Quando usar:**
- Antes de abrir PR que altera steerings
- Quando quiser auditar a conformidade geral

**O que faz:**
1. Busca ADRs aceitas no Confluence
2. Filtra apenas organizacionais
3. Compara cada ADR com o conteúdo dos steerings
4. Identifica contradições, informações parciais e ausências
5. Gera `steering-adr-validation.md` com score de conformidade

**Resultado esperado:** Um relatório detalhado com status por steering e plano de ação.

---

### 3. Propor Atualização de Steering

**Arquivo:** `propose-steering-updates.kiro.hook`

**Quando usar:**
- Após identificar gaps no relatório de sync
- Quando quiser que o Kiro aplique as alterações automaticamente

**O que faz:**
1. Busca ADRs dos últimos 90 dias no Confluence
2. Filtra apenas organizacionais aceitas
3. Mapeia cada ADR para o steering correto
4. Aplica as alterações diretamente nos arquivos
5. Gera `steering-updates-summary.md` com o que foi feito

**Resultado esperado:** Steerings atualizados + resumo para revisão humana antes do commit.

---

## Fluxo Recomendado

```
┌─────────────────────────────────────────────────────────┐
│                  PROCESSO MANUAL                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Rodar "Sincronizar ADRs do Confluence"              │
│     → Gera adr-sync-report.md                           │
│     → Verificar se há gaps                              │
│                                                         │
│  2. Se há gaps, rodar "Validar Steering contra ADRs"    │
│     → Gera steering-adr-validation.md                   │
│     → Entender o que precisa mudar                      │
│                                                         │
│  3. Rodar "Propor Atualização de Steering"              │
│     → Aplica alterações nos steerings                   │
│     → Gera steering-updates-summary.md                  │
│                                                         │
│  4. Revisar as alterações (git diff)                    │
│     → Validar se faz sentido                            │
│     → Ajustar manualmente se necessário                 │
│                                                         │
│  5. Commitar e abrir PR                                 │
│     → Seguir processo de aprovação do governance.md     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Checklist para PR de Atualização de Steering

Ao abrir PR com alterações em steerings baseadas em ADRs:

- [ ] Rodei "Sincronizar ADRs do Confluence" — relatório sem gaps críticos
- [ ] Rodei "Validar Steering contra ADRs" — sem contradições
- [ ] Alterações possuem comentário HTML referenciando a ADR de origem
- [ ] Data de "Última revisão" atualizada no rodapé do steering
- [ ] Relatórios temporários removidos (`adr-sync-report.md`, `steering-adr-validation.md`, `steering-updates-summary.md`)

---

## Cadência Sugerida

| Frequência | Ação |
|---|---|
| A cada 2 semanas | Rodar sync e verificar gaps |
| Após aprovação de ADR | Rodar sync + propose |
| Antes de PR em steerings | Rodar validate |
| Mensal | Revisão completa (sync + validate + propose) |

---

## Troubleshooting

**O hook trouxe ADRs de domínio específico (ex: KYC, Pagamentos)**
- Os hooks filtram automaticamente, mas se algo escapar, ignore no relatório
- Se for recorrente, ajuste os critérios de exclusão no prompt do hook

**O MCP Atlassian não conecta**
- Verifique se o MCP está habilitado em `.kiro/settings/mcp.json`
- A autenticação OAuth é feita no primeiro uso — pode precisar reautenticar

**O hook não aparece no explorer**
- Verifique se o arquivo está em `.kiro/hooks/` com extensão `.kiro.hook`
- Verifique se `"enabled": true` no JSON do hook

---

## Arquivos Gerados (temporários)

Os hooks geram relatórios na raiz do projeto. Eles são para consumo durante o processo e **não devem ser commitados**:

| Arquivo | Gerado por |
|---|---|
| `adr-sync-report.md` | Sincronizar ADRs |
| `steering-adr-validation.md` | Validar Steering |
| `steering-updates-summary.md` | Propor Atualização |

Considere adicioná-los ao `.gitignore`.

---

*Documento criado em 2026-05-06 — Atualizar conforme o processo evoluir.*
