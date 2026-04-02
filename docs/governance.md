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
7. [Auditoria e Conformidade](#auditoria-e-conformidade)
8. [Revisão Periódica deste Documento](#revisão-periódica-deste-documento)

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

## Auditoria e Conformidade

> TODO: Definir como será feita a auditoria de conformidade dos projetos com o baseline (ex.: script doctor.sh automatizado em CI, revisões periódicas manuais).

- O script `doctor.sh` pode ser executado manualmente ou em pipelines de CI para verificar conformidade.
- Relatórios de conformidade devem ser gerados **mensalmente** e revisados pelos mantenedores.

---

## Revisão Periódica deste Documento

Este documento deve ser revisado **a cada 6 meses** ou sempre que houver mudança significativa na estrutura organizacional ou na ferramenta Kiro.

> TODO: Agendar a próxima revisão e designar responsável.

---

*Documento em evolução — contribuições são bem-vindas via Pull Request.*
