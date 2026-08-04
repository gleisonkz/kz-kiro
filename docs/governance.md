# Governança — Modelo de Gestão dos Padrões Kiro

> **Objetivo:** Definir as responsabilidades, processos de decisão, ciclo de vida e políticas que regem a evolução dos padrões Kiro na organização MonteBravo.

---

## Sumário

1. [Princípios de Governança](#princípios-de-governança)
2. [Estrutura de Responsabilidades](#estrutura-de-responsabilidades)
3. [Processo de Proposta e Aprovação](#processo-de-proposta-e-aprovação)
4. [Ciclo de Vida dos Componentes](#ciclo-de-vida-dos-componentes)
5. [Política de Versionamento](#política-de-versionamento)
6. [Política de Exceções](#política-de-exceções)
7. [Migração de Projetos Existentes (Legado → Dual-Scope)](#migração-de-projetos-existentes-legado--dual-scope)
8. [Auditoria e Conformidade](#auditoria-e-conformidade)
9. [Revisão Periódica deste Documento](#revisão-periódica-deste-documento)

---

## Princípios de Governança

> TODO: Definir os princípios que guiam as decisões sobre os padrões Kiro (ex.: autonomia dos times com coerência organizacional, evolução incremental, transparência nas decisões).

- **Autonomia com alinhamento**: Times têm liberdade para adaptar configurações locais, mas o baseline global é de adoção obrigatória.
- **Evolução incremental**: Mudanças são pequenas, reversíveis e bem documentadas.
- **Transparência**: Todas as decisões sobre baseline, archetypes e powers são discutidas abertamente via PRs e issues.
- **Responsabilidade compartilhada**: Qualquer time pode propor melhorias; mantenedores são responsáveis pela qualidade.

---

## Estrutura de Responsabilidades

| Papel | Responsabilidades |
|---|---|
| **Mantenedores do mb-kiro** | Revisar e aprovar PRs, garantir qualidade e consistência, conduzir revisões periódicas |
| **Tech Leads de Produto** | Propor adaptações de archetype para seus contextos, validar que o baseline atende ao time |
| **Engenheiros** | Usar os padrões definidos, reportar inconsistências, contribuir com melhorias |
| **Segurança/Compliance** | Revisar e aprovar mudanças no security-baseline.md |

> TODO: Mapear os nomes das pessoas em cada papel e o processo de sucessão/substituição.

---

## Processo de Proposta e Aprovação

### Mudanças no Baseline Global

1. Abrir uma **issue** descrevendo a mudança, motivação e impacto esperado.
2. Discussão mínima de **5 dias úteis** com abertura para comentários da organização.
3. Abertura de **Pull Request** com as mudanças e link para a issue.
4. Aprovação por **ao menos 2 mantenedores**.
5. Merge em `main` com mensagem de commit seguindo o padrão Conventional Commits.

### Mudanças em Archetypes ou Powers

1. Abrir uma **issue** ou PR diretamente com a proposta.
2. Revisão por **ao menos 1 mantenedor** e pelo Tech Lead da stack correspondente.
3. Aprovação e merge.

### Hotfixes (correções urgentes)

1. Criar branch `fix/` e PR com descrição do problema e solução.
2. Aprovação express por **ao menos 1 mantenedor**.
3. Comunicar a correção nos canais relevantes.

> TODO: Definir qual ferramenta/canal é usado para comunicação (Slack, Teams, etc.).

---

## Ciclo de Vida dos Componentes

```
Proposta → Revisão → Aprovação → Publicação → Adoção → Deprecação → Remoção
```

| Fase | Descrição |
|---|---|
| **Proposta** | Issue ou draft PR com a ideia |
| **Revisão** | Discussão técnica e de impacto |
| **Aprovação** | Aprovação formal pelos mantenedores |
| **Publicação** | Merge em main com bump de versão |
| **Adoção** | Times aplicam via sync ou bootstrap |
| **Deprecação** | Componente marcado como deprecated com prazo de migração |
| **Remoção** | Remoção após prazo + comunicação |

---

## Política de Versionamento

Seguimos [Semantic Versioning](https://semver.org/) com a seguinte interpretação:

| Tipo de mudança | Versão afetada |
|---|---|
| Remoção de campo obrigatório, renomeação breaking | `MAJOR` |
| Nova feature compatível com versões anteriores | `MINOR` |
| Correção de bug, typo, melhoria de documentação | `PATCH` |

Cada componente (baseline, archetype, power) tem seu próprio arquivo `VERSION` e pode evoluir de forma independente.

---

## Política de Exceções

Times que precisam desviar do baseline global devem:

1. Documentar a exceção no `kiro-manifest.json` do projeto (`exceptions` array).
2. Justificar tecnicamente a necessidade.
3. Comunicar os mantenedores via issue ou PR neste repositório.
4. Rever a exceção a cada **3 meses** para verificar se ainda é necessária.

> TODO: Definir processo formal de aprovação de exceções e quem tem autoridade para aprová-las.

---

## Migração de Projetos Existentes (Legado → Dual-Scope)

Projetos configurados antes da adoção do modelo dual-scope possuem o baseline copiado diretamente no workspace (`.kiro/`). Esses projetos funcionam normalmente (retrocompatibilidade garantida), mas devem ser migrados para o novo modelo quando conveniente.

### Por que migrar?

- **Elimina duplicação**: O baseline não precisa existir em cada projeto.
- **Atualização centralizada**: Um único `sync.sh --scope user` atualiza todos os projetos.
- **Menos conflitos**: Em workspaces multi-root, não há conflito entre baselines de projetos diferentes.
- **Clareza**: Separação nítida entre "o que é organizacional" e "o que é da stack".

### Como identificar um projeto legado

Um projeto está no modelo legado quando seu `kiro-manifest.json` **não possui** o campo `baseline.scope`. O `doctor.sh` reporta `[WARN]` indicando que o projeto usa o modelo antigo e recomenda migração.

### Processo de migração

```bash
# 1. Simular a migração (sem aplicar mudanças)
./scripts/sync.sh --target ../meu-projeto --migrate-to-user-scope --dry-run

# 2. Executar a migração
./scripts/sync.sh --target ../meu-projeto --migrate-to-user-scope

# 3. Instalar o baseline na máquina (se ainda não fez)
./scripts/bootstrap.sh --scope user
```

**O que a migração faz:**

1. Cria backup em `<projeto>/.kiro/.migration-backup/baseline/`
2. Remove steering files do baseline do workspace (mantém os do archetype)
3. Remove servidores MCP do baseline do `mcp.json` do workspace (mantém os do archetype)
4. Atualiza o manifest para `baseline.scope: "user"` e `schema_version: "2.0.0"`

**Segurança:**

- A migração é **atômica**: se falhar em qualquer etapa, o backup é restaurado automaticamente.
- É possível verificar o resultado antes com `--dry-run`.
- Projetos já migrados são detectados e o comando encerra sem mudanças.

### Cronograma recomendado

| Fase | Ação | Prazo sugerido |
|---|---|---|
| 1 | Todos os devs executam `bootstrap.sh --scope user` | Imediato |
| 2 | Novos projetos usam `bootstrap.sh --scope workspace` | A partir de agora |
| 3 | Projetos existentes migram com `--migrate-to-user-scope` | Até próxima revisão trimestral |
| 4 | Modelo legado deprecado | Após migração de todos |

### Rollback

Se necessário reverter a migração de um projeto:

1. O backup está em `<projeto>/.kiro/.migration-backup/baseline/`
2. Copie os steering files de volta para `<projeto>/.kiro/steering/`
3. Remova o campo `baseline.scope` do manifest
4. Revert o `schema_version` para o valor anterior

---

## Auditoria e Conformidade

- O script `doctor.sh` pode ser executado manualmente ou em pipelines de CI para verificar conformidade.
- Em CI, o doctor verifica apenas artefatos do workspace (o baseline user-scope não se aplica).
- Relatórios de conformidade devem ser gerados **mensalmente** e revisados pelos mantenedores.
- Use `--output json` para integração com ferramentas de monitoramento.

---

## Revisão Periódica deste Documento

Este documento deve ser revisado **a cada 6 meses** ou sempre que houver mudança significativa na estrutura organizacional ou na ferramenta Kiro.

> TODO: Agendar a próxima revisão e designar responsável.

---

*Documento em evolução — contribuições são bem-vindas via Pull Request.*
