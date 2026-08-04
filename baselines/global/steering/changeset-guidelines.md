---
inclusion: fileMatch
fileMatchPattern: "**/.changeset/**/*.md"
---

# Diretrizes para Changesets — MonteBravo

> **Steering File | Baseline Global | Versão: 0.2.0**
>
> Este arquivo define o padrão organizacional para criação de changesets em monorepos da MonteBravo.
> Aplica-se a todos os projetos que utilizam `@changesets/cli` para versionamento.

---

## O que é um Changeset?

Um changeset é um arquivo Markdown com frontmatter YAML que descreve:

1. **Quais packages** foram afetados pela mudança.
2. **O tipo de bump semântico** (major, minor, patch) para cada package.
3. **Um resumo legível** da mudança — que será usado no CHANGELOG gerado.

A descrição do changeset **vira a entrada do CHANGELOG**, que é anexado à GMUD (Gestão de Mudança). Portanto, ela precisa ser legível por qualquer pessoa — não só por quem escreveu o código. Escreva pensando em quem vai ler a mudança no documento de release, não no PR.

O changeset deve ser criado **junto com o PR** (quando a mudança está fresca na memória), e não no momento da release.

---

## Quando criar um Changeset

| Situação | Changeset? |
|---|---|
| Nova funcionalidade | ✅ Obrigatório |
| Correção de bug | ✅ Obrigatório |
| Refatoração com impacto na API pública | ✅ Obrigatório |
| Refatoração interna sem impacto externo | ⚠️ Opcional (recomendado) |
| Atualização de dependências que afeta comportamento | ⚠️ Opcional |
| Mudanças em CI/CD, docs, tooling sem impacto em versão | ❌ Usar `pnpm changeset --empty` |
| Hotfix de deploy (sem mudança de código) | ❌ Não criar changeset |
| Comentário para forçar redeploy | ❌ Não criar changeset |

> **Regra:** Todo PR para `develop` deve incluir pelo menos um changeset. O CI bloqueia PRs sem changeset. Se o PR é puramente interno, use `pnpm changeset --empty`.

---

## Como criar

```sh
pnpm changeset
```

O CLI guia interativamente: selecione packages → tipo de bump → escreva a descrição.
Commite o arquivo `.changeset/*.md` junto com o código.

---

## Formato do Arquivo

```markdown
---
"@montebravo.tech/package-name": minor
---

Descrição da mudança focada no impacto para o consumidor.
```

### Frontmatter (YAML)

- Listar **todos** os packages afetados pela mudança.
- Se o PR altera múltiplos pacotes, o changeset deve listar todos.
- Usar o bump semântico correto (ver seção "Classificação Semântica").

### Resumo (corpo do Markdown)

O resumo será inserido automaticamente no CHANGELOG. Deve seguir estas regras:

---

## Regras da Descrição

1. **Idioma:** português do Brasil.
2. **Forma verbal:** presente, 3ª pessoa — **"Adiciona / Corrige / Remove / Altera / Aumenta …"**.
3. **Foco no impacto:** descreva o que muda para o consumidor do serviço/app ou para a operação, não a mecânica interna do código.
4. **Uma frase objetiva** como resumo principal. Use bullets adicionais somente quando agregam valor de negócio/operacional.
5. **Sinalize entregas simuladas** com "(simulado)" ou "(mock)".

### O que NÃO fazer na descrição

- ❌ **Não use prefixo de commit:** `feat:`, `fix:`, `refactor(onboarding):` — a descrição do changeset não é um commit message.
- ❌ **Não use como sujeito da frase:** nomes de classe/arquivo (`OnboardingClient`, `http-client.ts`), variáveis de ambiente (`CLIENTE_ONBOARDING_SERVICE_URL`), status HTTP (`409`, `502`) ou nomes de serviços/fornecedores internos.
- ❌ **Não escreva descrições vagas:** "update schema", "add task", "changes".
- ❌ **Não escreva em inglês.**
- ❌ **Não crie changesets sem valor de changelog** (ex.: comentário só para forçar redeploy).

---

## Exemplos

### Bom — patch simples

```markdown
---
"@montebravo.tech/mb-cliente-bff": patch
---

Aumenta o tempo limite da integração de KYC para 250s, acomodando o tempo de resposta do provedor de verificação documental.
```

### Bom — feature com contexto

```markdown
---
"@montebravo.tech/mb-one-bff": minor
---

Adiciona a consulta de detalhes do cliente, expondo os dados fornecidos pelo serviço de clientes.
```

### Bom — módulo com mock

```markdown
---
"@montebravo.tech/mb-one-bff": minor
---

Adiciona o módulo de notificações (com rotas simuladas).
```

### Bom — fix com contexto do "por quê"

```markdown
---
"@montebravo.tech/mb-cliente-bff": patch
---

Corrige o tratamento de indisponibilidade do serviço de onboarding: falhas de rede passam a retornar erro de serviço indisponível em vez de erro interno genérico.
```

### Bom — feature com detalhamento (quando múltiplas mudanças agregam valor)

```markdown
---
"@montebravo.tech/mb-one-web": minor
---

Implementa a tela de detalhe de grupo com navegação por abas.

- Exibe patrimônio consolidado do grupo no header
- Permite navegar entre membros familiares e empresariais via abas
- Lista horizontal de cards com scroll por arrasto
- Redireciona para aba familiar por padrão

Refs: AS-167
```

### Bom — multi-package

```markdown
---
"@montebravo.tech/mb-one-bff": minor
"@montebravo.tech/bff-clients": minor
---

Adiciona endpoint de consulta da timeline de atividades do onboarding.
```

### Bom — breaking change

```markdown
---
"@montebravo.tech/mb-one-bff": major
---

Remove os endpoints de ativação de conta do módulo de onboarding.

Os endpoints não estavam conectados a nenhum serviço real e não possuíam consumidores ativos. Consumidores que dependiam desses endpoints devem migrar para o fluxo via serviço de domínio.
```

### Bom — correção de Docker/infra que afeta deploy

```markdown
---
"@montebravo.tech/mb-cliente-bff": patch
"@montebravo.tech/mb-one-bff": patch
---

Corrige a construção das imagens Docker das aplicações, garantindo que o pacote de clients compartilhados seja copiado e compilado antes do build.
```

### Ruim → Bom (tabela de transformação)

| ❌ Ruim | ✅ Bom |
|---|---|
| `feat: add customer module with GET /customer/:id endpoint … Includes CustomerClient …` | Adiciona a consulta de detalhes do cliente, expondo os dados fornecidos pelo serviço de clientes. |
| `fix(kyc): increase KycApiClient timeout to 250s` | Aumenta o tempo limite da integração de KYC para 250s, acomodando o tempo de resposta do provedor de verificação documental. |
| `update order schema` | Atualiza o contrato de ordens, incluindo o campo de data programada de envio. |
| `add task` | Adiciona a criação de tarefas manuais com possibilidade de registro já concluído. |
| `chore(mb-one-bff): add innocuous comment so we can redeploy` | *(não gerar changeset — sem valor de changelog)* |
| `Changes in opportunities mock` | Atualiza os dados simulados de oportunidades para refletir o design atual. |
| `Refactor fixtures to ensure data consistency` | Centraliza os dados simulados para manter consistência entre módulos. |

---

## Classificação Semântica (Bump)

| Tipo de mudança | Bump | Exemplo |
|---|---|---|
| Novo módulo, endpoint, componente ou página | `minor` | Novo módulo de consolidação |
| Nova funcionalidade em módulo existente | `minor` | Novo endpoint de timeline |
| Novo campo ou capacidade compatível | `minor` | Campo `displayStatus` na listagem |
| Correção de bug | `patch` | Fix de timeout, fix de schema |
| Ajuste de contrato sem breaking | `patch` | Relaxar validação de resposta |
| Refatoração sem impacto externo | `patch` | Reorganizar mappers internos |
| Melhoria de performance | `patch` | Otimizar query, cache |
| Fix de infraestrutura (Docker, CI) | `patch` | Corrigir Dockerfile |
| Remoção de funcionalidade publicada | `major` | Remover endpoint, remover componente |
| Mudança incompatível de contrato | `major` | Alterar formato de request/response |

> **Nota:** Mudanças que não pertencem a um pacote publicável (pipeline de CI, config de raiz) normalmente **não** devem gerar bump de aplicação.

---

## Regras de Nomenclatura do Arquivo

O CLI gera nomes aleatórios como `beige-days-press.md`. Isso é aceito. Para changesets criados manualmente, prefira nomes descritivos:

| Padrão | Quando usar | Exemplo |
|---|---|---|
| `<ação>-<descrição>.md` | Mudanças com contexto claro | `add-consolidation-module.md` |
| `<ação>-<ticket>-<descrição>.md` | Features e fixes com ticket | `feat-lc-560-onboarding-client.md` |
| `fix-<descrição>.md` | Correções | `fix-kyc-client-timeout.md` |
| Nome aleatório do CLI | Criado via `pnpm changeset` | `beige-days-press.md` |

### Regras para nomes

- Usar kebab-case.
- Máximo de 50 caracteres no nome do arquivo (sem extensão).
- Incluir referência ao ticket quando aplicável.

---

## Referência a Tickets

Quando a mudança está associada a um ticket, incluir referência no final do corpo:

```
Refs: AS-167
Refs: LC-560
```

- Usar o prefixo do projeto Jira (`AS-` para Assessoria, `LC-` para Life Cycle, `RV-` para Renda Variável, etc.).
- Não é necessário incluir link completo.

---

## Boas Práticas

### Faça

- ✅ Crie o changeset **junto com o PR** — quando a mudança está fresca.
- ✅ Descreva o **impacto para o consumidor** — o que mudou do ponto de vista de quem consome.
- ✅ Use **listas** para resumos com múltiplas mudanças que agregam valor de negócio.
- ✅ Inclua o **"por quê"** quando a mudança não é óbvia.
- ✅ Um changeset por **unidade lógica** de mudança — mesmo que afete múltiplos packages.
- ✅ Revise o changeset no code review junto com o código.
- ✅ Sinalize entregas simuladas/mock explicitamente.

### Não faça

- ❌ Não use prefixo Conventional Commits (`feat:`, `fix:`) na descrição.
- ❌ Não use nomes técnicos como sujeito (classes, variáveis, HTTP status).
- ❌ Não escreva em inglês.
- ❌ Não combine mudanças não relacionadas em um único changeset.
- ❌ Não crie changeset para mudanças sem valor de changelog.
- ❌ Não use `major` sem justificativa de breaking change real.
- ❌ Não repita a mecânica do diff — descreva a intenção e o impacto.
- ❌ Não escreva descrições vagas ("update schema", "add task", "changes").

---

## Configuração de Referência

### config.json

```json
{
  "$schema": "https://unpkg.com/@changesets/config@3.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "restricted",
  "baseBranch": "develop",
  "updateInternalDependencies": "patch",
  "ignore": []
}
```

| Campo | Descrição |
|---|---|
| `baseBranch` | Branch base para detecção de mudanças. Definida por projeto (`develop`, `main`, etc.). |
| `access` | `restricted` para packages privados (padrão MonteBravo). |
| `commit` | `false` — changesets não geram commits automaticamente. |
| `updateInternalDependencies` | `patch` — atualiza dependências internas automaticamente. |

---

## Checklist para Code Review

Ao revisar um PR com changeset, verificar:

- [ ] O changeset está presente (CI bloqueia PRs sem changeset).
- [ ] O bump semântico está correto (patch/minor/major).
- [ ] Todos os packages afetados estão listados no frontmatter.
- [ ] A descrição está em português, na 3ª pessoa do presente.
- [ ] A descrição foca no impacto, não na mecânica do código.
- [ ] Não contém prefixo Conventional Commits (`feat:`, `fix:`).
- [ ] Não usa nomes técnicos como sujeito (classes, variáveis).
- [ ] Entregas simuladas/mock estão sinalizadas.
- [ ] O nível de detalhe é adequado (nem genérico, nem excessivo).
- [ ] Referência ao ticket está presente (quando aplicável).

---

## Referências

- [Changesets — Documentação Oficial](https://github.com/changesets/changesets)
- [Semantic Versioning](https://semver.org/)

> **Nota:** Cada projeto pode manter documentação complementar específica (fluxo de release, packages disponíveis, etc.) em seu próprio `docs/`. Este steering define apenas as regras de escrita e formato que são transversais a todos os monorepos.

---

*Versão: 0.2.0 | Última revisão: 2026-08 | Próxima revisão: TODO*
