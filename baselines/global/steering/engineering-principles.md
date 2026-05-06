# Princípios de Engenharia — MonteBravo

> **Steering File | Baseline Global | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em todos os projetos da organização.
> Ele descreve os princípios de engenharia que devem guiar decisões técnicas, arquiteturais e de processo.

---

## Propósito deste Arquivo

Este steering file define os princípios fundamentais de engenharia da MonteBravo. O Kiro deve usar estes princípios como referência ao:

- Sugerir abordagens arquiteturais
- Revisar código e propor melhorias
- Tomar decisões sobre trade-offs técnicos
- Gerar scaffolding e boilerplate de código

---

## Princípios Fundamentais

> TODO: Definir e detalhar os princípios de engenharia da organização. Sugestões de tópicos:

### 1. Simplicidade sobre Complexidade

> TODO: Descrever como a organização valoriza soluções simples e diretas, evitando over-engineering.

### 2. Qualidade é Responsabilidade do Time

> TODO: Descrever o modelo de ownership de qualidade — testes, revisão de código, observabilidade.

### 3. APIs como Produtos

> TODO: Descrever a abordagem API-first e como as interfaces devem ser tratadas como contratos estáveis.

### 4. Comunicação Assíncrona entre Serviços

<!-- Baseado em ADR: ADR-001 – Padrão arquitetural de comunicação - Serviços distribuídos internos | Confluence: https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517 -->

A comunicação entre serviços distribuídos internos deve seguir o padrão de **mensageria assíncrona com coreografia**, utilizando um Message Broker como intermediário. Essa decisão visa atender os requisitos de segurança, escalabilidade, elasticidade e alta disponibilidade.

**Princípios:**
- Serviços se comunicam de forma assíncrona via Message Broker (fire-and-forget).
- Padrão coreografado: serviços publicam eventos sem depender de um orquestrador central.
- Comunicação síncrona (REST) é aceitável apenas para consultas simples e de baixa latência onde não há necessidade de resiliência a falhas do receptor.
- Transações financeiras e integrações com serviços externos devem implementar o padrão **Outbox** para garantir ACID em ambiente distribuído.

**Brokers aprovados:**
- Apache Kafka (preferido para alto throughput e event sourcing)
- RabbitMQ (aceitável para cenários de menor volume com round-robin)

**Requisitos obrigatórios:**
- O Message Broker deve operar em cluster com múltiplos nós (alta disponibilidade).
- Observabilidade centralizada (logs, métricas, tracing) é obrigatória para rastreabilidade de mensagens assíncronas.
- Toda comunicação entre serviços deve usar TLS 1.2+.

### 5. Observabilidade por Padrão

<!-- Baseado em ADR: ADR-001 – Padrão arquitetural de comunicação - Serviços distribuídos internos | Confluence: https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517 -->

Todos os serviços devem implementar observabilidade estruturada e centralizada. Em arquiteturas com mensageria assíncrona, a rastreabilidade é crítica para troubleshooting.

**Expectativas mínimas:**
- Logs estruturados (JSON) com correlation ID propagado entre serviços.
- Métricas de latência, throughput e tamanho de filas expostas.
- Distributed tracing para acompanhar o fluxo de mensagens entre serviços.
- Alertas configurados para filas com crescimento anormal ou consumers com lag.

### 6. Segurança Integrada (Shift Left)

> TODO: Descrever como segurança deve ser considerada desde o design, não como afterthought.

### 7. Revisão de Código como Ferramenta de Aprendizado

> TODO: Descrever as expectativas de code review — foco em conhecimento compartilhado, não em gatekeeping.

### 8. Documentação como Código

> TODO: Descrever as expectativas de documentação — README, ADRs, changelogs, comentários de código.

### 9. Evoluir sem Quebrar

> TODO: Descrever as expectativas de compatibilidade, versionamento e migração de APIs e schemas.

---

## Padrões Técnicos Obrigatórios

> TODO: Listar os padrões técnicos que se aplicam a todos os projetos (ex.: linguagens suportadas, versões mínimas, frameworks aprovados).

| Categoria | Padrão | Versão Mínima | Observação |
|---|---|---|---|
| Linguagem principal | TODO | TODO | TODO |
| Gerenciador de pacotes | TODO | TODO | TODO |
| Versionamento | Git + Conventional Commits | - | Obrigatório |
| Testes | TODO | TODO | Cobertura mínima: TODO% |
| CI/CD | TODO | TODO | TODO |

---

## Anti-Padrões a Evitar

> TODO: Listar os anti-padrões que o Kiro deve identificar e alertar, com justificativa para cada um.

---

## Referências

> TODO: Adicionar links para documentos internos, ADRs fundacionais e referências externas relevantes.

---

*Versão: 0.2.0 | Última revisão: 2026-05-06 | Próxima revisão: TODO*
