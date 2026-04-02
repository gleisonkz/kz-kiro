# Baseline de Documentação — MonteBravo

> **Steering File | Baseline Global | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em todos os projetos da organização.
> Ele define os padrões e expectativas de documentação para todos os projetos.

---

## Propósito deste Arquivo

Este steering file define o baseline de documentação da MonteBravo. O Kiro deve usar estas diretrizes ao:

- Gerar ou revisar documentação de projetos
- Avaliar se um projeto está adequadamente documentado
- Sugerir melhorias na estrutura e qualidade da documentação
- Identificar documentação ausente ou desatualizada

---

## Documentação Obrigatória por Projeto

Todo projeto da organização deve ter, no mínimo:

### README.md (raiz do projeto)

O README deve conter:
- [ ] Propósito e contexto do projeto
- [ ] Pré-requisitos e dependências
- [ ] Como instalar e configurar o ambiente local
- [ ] Como executar o projeto
- [ ] Como executar os testes
- [ ] Visão geral da arquitetura
- [ ] Links para documentação detalhada
- [ ] Como contribuir
- [ ] Contatos e mantenedores

### CHANGELOG.md

- Deve seguir o formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).
- Deve ser atualizado a cada release.
- Versões seguem [Semantic Versioning](https://semver.org/).

### docs/

Pasta de documentação técnica com:
- `architecture.md` — Visão geral da arquitetura do projeto
- `setup.md` (ou equivalente) — Instruções detalhadas de configuração
- `api.md` ou OpenAPI spec — Documentação de APIs (quando aplicável)

---

## Padrões de Escrita

> TODO: Definir os padrões de escrita para documentação técnica da organização.

- **Idioma**: TODO (definir se é português, inglês ou ambos por contexto).
- **Tom**: Direto, objetivo, sem ambiguidade.
- **Formato**: Markdown preferido para documentação técnica.
- **Comprimento**: Adequado ao conteúdo — nem muito curto (sem contexto) nem muito longo (difícil de manter).

---

## Documentação de Código

> TODO: Definir os padrões de comentários e documentação inline de código.

### Quando comentar código?

- TODO: Definir quando comentários são obrigatórios vs. opcionais.

### Formato de comentários por linguagem

| Linguagem | Formato | Ferramenta de Geração |
|---|---|---|
| TypeScript/JavaScript | JSDoc | TODO |
| TODO | TODO | TODO |

---

## ADRs — Architecture Decision Records

Todo projeto deve manter um log de decisões arquiteturais significativas em `docs/adr/`.

### Formato de ADR

> TODO: Definir o template de ADR preferido pela organização (ex.: MADR, Michael Nygard).

```markdown
# ADR-NNNN: [Título da Decisão]

## Status
[proposed | accepted | deprecated | superseded]

## Contexto
[Descreva o problema ou situação que exigiu uma decisão]

## Decisão
[Descreva a decisão tomada]

## Consequências
[Descreva os impactos positivos e negativos desta decisão]
```

---

## O que o Kiro Deve Verificar

Ao analisar um projeto, o Kiro deve verificar:

- [ ] README.md existe e contém as seções obrigatórias.
- [ ] CHANGELOG.md está atualizado com a última versão.
- [ ] APIs públicas estão documentadas.
- [ ] Funções e classes críticas têm comentários adequados.
- [ ] Decisões arquiteturais significativas têm ADRs.

---

## Referências

> TODO: Adicionar links para guias de escrita técnica, exemplos de boa documentação e ferramentas aprovadas.

---

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
