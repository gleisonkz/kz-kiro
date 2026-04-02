# Plano de Rollout — Adoção do Kiro na MonteBravo

> **Objetivo:** Definir as fases, marcos, critérios de sucesso e responsáveis para a adoção progressiva e sustentável do Kiro em toda a organização.

---

## Sumário

1. [Visão Geral do Rollout](#visão-geral-do-rollout)
2. [Fase 0 — Fundação](#fase-0--fundação)
3. [Fase 1 — Piloto](#fase-1--piloto)
4. [Fase 2 — Expansão](#fase-2--expansão)
5. [Fase 3 — Consolidação](#fase-3--consolidação)
6. [Critérios de Sucesso](#critérios-de-sucesso)
7. [Riscos e Mitigações](#riscos-e-mitigações)
8. [Comunicação e Engajamento](#comunicação-e-engajamento)

---

## Visão Geral do Rollout

O rollout é dividido em 4 fases progressivas, cada uma com critérios de entrada, saída e marco de validação. A abordagem é **incremental e baseada em feedback**, garantindo que os padrões evoluam junto com a experiência real dos times.

```
Fase 0: Fundação → Fase 1: Piloto → Fase 2: Expansão → Fase 3: Consolidação
```

---

## Fase 0 — Fundação

**Duração estimada:** TODO (ex.: 2-4 semanas)
**Status:** Em andamento

### Objetivos

- Criar e validar a estrutura base do repositório `mb-kiro`.
- Definir o baseline global inicial (versão 0.1.0).
- Criar archetypes iniciais para backend-nest e frontend-react-next.
- Criar scripts bootstrap, sync e doctor com estrutura funcional mínima.
- Documentar onboarding, governança e arquitetura.

### Critério de Saída

- [ ] Repositório `mb-kiro` criado com estrutura completa.
- [ ] Baseline global v0.1.0 definido e aprovado pelos mantenedores.
- [ ] Ao menos 1 archetype funcional e testado manualmente.
- [ ] Scripts com estrutura funcional mínima.
- [ ] Documentação base revisada e aprovada.

### Responsáveis

> TODO: Nomear responsáveis por esta fase.

---

## Fase 1 — Piloto

**Duração estimada:** TODO (ex.: 4-6 semanas)
**Status:** Não iniciado

### Objetivos

- Selecionar **1-2 projetos piloto** de diferentes stacks para aplicar os padrões.
- Executar bootstrap em ambiente real e coletar feedback detalhado.
- Identificar gaps nos archetypes e no baseline global.
- Refinar scripts com base nos problemas encontrados.
- Validar o processo de sync e doctor.

### Critério de Entrada

- Fase 0 concluída com todos os critérios de saída atendidos.

### Critério de Saída

- [ ] Bootstrap executado com sucesso em 2+ projetos.
- [ ] Feedback coletado e documentado.
- [ ] Issues identificadas prorizadas e parcialmente resolvidas.
- [ ] NPS interno dos times piloto ≥ TODO.

### Responsáveis

> TODO: Nomear Tech Leads dos times piloto e responsáveis pelo mb-kiro nesta fase.

---

## Fase 2 — Expansão

**Duração estimada:** TODO (ex.: 8-12 semanas)
**Status:** Não iniciado

### Objetivos

- Expandir adoção para todos os projetos ativos da organização.
- Executar sync em projetos existentes para alinhar com o baseline.
- Criar archetypes adicionais conforme necessidade identificada na Fase 1.
- Treinar todos os Tech Leads e engenheiros sênior.
- Integrar `doctor.sh` em pipelines de CI/CD dos projetos.

### Critério de Entrada

- Fase 1 concluída com todos os critérios de saída atendidos.
- Pelo menos 1 rodada de refinamento do baseline e archetypes.

### Critério de Saída

- [ ] ≥ 80% dos projetos ativos com baseline e archetype instalados.
- [ ] `doctor.sh` integrado em ≥ 50% dos pipelines de CI/CD.
- [ ] Todos os Tech Leads treinados.
- [ ] Processo de governança rodando com cadência regular.

### Responsáveis

> TODO: Nomear responsáveis e definir coordenador de rollout.

---

## Fase 3 — Consolidação

**Duração estimada:** TODO (ex.: ongoing)
**Status:** Não iniciado

### Objetivos

- Atingir 100% de cobertura nos projetos ativos.
- Estabelecer ciclo de revisão semestral do baseline.
- Automatizar completamente o sync via CI/CD.
- Publicar powers via Kiro Registry (quando disponível).
- Medir e reportar métricas de conformidade mensalmente.

### Critério de Entrada

- Fase 2 concluída com todos os critérios de saída atendidos.

### Critério de Saída

> Esta fase é contínua — não tem critério de saída, apenas métricas de maturidade.

---

## Critérios de Sucesso

| Métrica | Meta | Como Medir |
|---|---|---|
| Cobertura de projetos com baseline | 100% projetos ativos | Script doctor.sh + inventário |
| Tempo de bootstrap de projeto novo | < TODO minutos | Cronometrar execução do bootstrap.sh |
| Conformidade com baseline global | ≥ 95% | Relatório mensal do doctor.sh |
| NPS interno do Kiro | ≥ TODO | Pesquisa trimestral com engenheiros |
| Tempo médio para sync de atualização | < TODO minutos | Cronometrar execução do sync.sh |

> TODO: Definir as metas numéricas após a Fase 1.

---

## Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Resistência dos times à adoção | Média | Alto | Comunicação clara, envolvimento precoce dos Tech Leads, mostrar valor concreto |
| Baseline muito restritivo | Alta | Médio | Processo de exceções claro e ágil, revisões periódicas |
| Scripts com bugs em ambiente real | Alta | Alto | Testes em ambiente isolado antes de Fase 1, rollback documentado |
| Falta de mantenedores | Baixa | Alto | Documentação detalhada, onboarding de novos mantenedores desde a Fase 0 |
| Mudanças breaking no Kiro (upstream) | Média | Alto | Versionamento semântico, testes de compatibilidade antes de atualizar |

---

## Comunicação e Engajamento

> TODO: Definir o plano de comunicação para cada fase, incluindo:
> - Canais de comunicação (Slack, e-mail, etc.)
> - Cadência de updates para a liderança
> - Sessões de treinamento e demo
> - Processo de coleta de feedback
> - Página/wiki de status do rollout

---

*Documento em evolução — contribuições são bem-vindas via Pull Request.*
