---
inclusion: manual
---

# GitHub Actions Workflows - Padrão CI/CD

Este steering documenta a estrutura padrão de workflows GitHub Actions utilizada nos projetos .NET da equipe. Use como referência ao criar ou configurar workflows em novos repositórios.

**Repositório de referência:** [ope-custodia-financial-balance-api](https://github.com/montebravo-corretora/ope-custodia-financial-balance-api)

---

## Regra Principal (sobrepõe todas as demais)

> **Se não souber, não inventa. Pergunte ao desenvolvedor.**

Aplicação neste steering:
- Se não souber o nome do serviço ECS/ECR: **pergunte**
- Se não souber quais secrets o serviço precisa: **pergunte**
- Se não souber quais variáveis de ambiente são necessárias: **pergunte**
- Se não souber o ARN do secret no Secrets Manager: **pergunte**
- Se não souber se o serviço tem integrações externas (tokens, APIs): **pergunte**
- Se não souber o nome da solution (.sln): **pergunte**
- Se não souber se há variáveis que conflitam entre env vars e secrets: **pergunte**
- Nunca invente ARNs, nomes de secrets, ou configurações de ambiente

---

## Perguntas Obrigatórias Antes de Configurar Workflows

Antes de criar os workflows para um novo projeto, **obrigatoriamente** colete as seguintes informações:

### Informações do Projeto

| # | Pergunta | Exemplo de Resposta |
|---|----------|---------------------|
| 1 | Qual o nome do serviço ECS/ECR? | `mb-ope-custodia-financial-balance-api` |
| 2 | Qual o nome do arquivo .sln? | `Ope.Custodia.Financial.Balance.sln` |
| 3 | Qual a versão do .NET? | `10.0` |
| 4 | O projeto já tem `Directory.Build.props` com `<GmudVersion>`? | Sim / Não (criar) |

### Informações de Secrets e Variáveis

| # | Pergunta | Exemplo de Resposta |
|---|----------|---------------------|
| 5 | Quais secrets do serviço existem no AWS Secrets Manager? (ARNs por ambiente) | `mb/mb-cluster/development/ope-custodia-...` |
| 6 | Quais chaves dentro do secret precisam ser injetadas? | `inoa_token`, `inoa_base_url` |
| 7 | O serviço usa KEYCLOAK_OPENID_CONFIGURATION_URL? | Sim (secrets GitHub: `DEV_`/`STG_`/`PRD_` prefix) |
| 8 | Há variáveis de ambiente específicas do serviço (além das padrão)? | `Inoa__ClientBalancePath`, `Inoa__TimeoutSeconds` |
| 9 | Existe conflito entre env vars e secrets que precisa de cleanup step? | Sim — `Inoa__BaseUrl` gerenciada por secret |

### Informações de Infraestrutura

| # | Pergunta | Exemplo de Resposta |
|---|----------|---------------------|
| 10 | O AWS Account ID é `471112832676`? | Sim / Outro |
| 11 | O cluster segue o padrão `mb-ctvm-cluster-{environment}`? | Sim / Outro |
| 12 | A porta exposta no container é `80`? | Sim / Outra |

> **Se qualquer resposta não estiver disponível, NÃO prossiga. Pergunte ao desenvolvedor.**

---

## Visão Geral

O pipeline é composto por **6 workflows**:

| Arquivo | Trigger | Propósito |
|---------|---------|-----------|
| `ci.yml` | PR para `dev`, `release/*`, `main` | Build, testes e validação de code coverage |
| `deploy-dev.yml` | Push em `dev` | Deploy no ambiente development |
| `deploy-stg.yml` | Push em `release/*` | Deploy no ambiente staging |
| `deploy-prd.yml` | Push em `main` | Deploy no ambiente production |
| `gmud.yml` | Manual (workflow_dispatch) | Abertura de GMUD: calcula versão, cria branches, atualiza versão, abre PR |
| `release.yml` | PR fechada em `release/*` | Cria tag, GitHub Release e PRs automáticas (main + dev sync) |

---

## Branching Strategy

```
dev ──────────────────────────────────────────────────────────────
 │                                    ▲
 │ (gmud.yml cria branch)            │ (release.yml abre PR sync)
 ▼                                    │
gmud/v{versão} ──── PR ───► release/{data} ──── PR ───► main
                                 │
                                 ▼
                          deploy staging
                          (push trigger)
```

- `dev` → ambiente de development (desenvolvimento contínuo)
- `release/{YYYY-MM-DD}` → ambiente de staging (branch temporária por GMUD)
- `main` → ambiente de production
- `gmud/v{versão}` → branch de trabalho da GMUD (derivada de dev)

### Convenção de versionamento

- **Formato:** `v{YYYY-MM.X}` onde X é o número sequencial no mês
- **Exemplos:** `v2026-07.1`, `v2026-07.2`, `v2026-08.1`
- A versão é definida no `Directory.Build.props` na tag `<GmudVersion>`
- A versão é **calculada automaticamente** pelo workflow GMUD a partir das tags existentes
- Tags seguem o mesmo formato: `v2026-07.1`

---

## CI Workflow (`ci.yml`)

Executado em **Pull Requests** para `dev`, `release/*` e `main`. Valida build, testes e cobertura de código.

### Trigger

```yaml
on:
  pull_request:
    branches:
      - dev
      - 'release/*'
      - main
```

### Jobs

| Job | Depends On | Propósito |
|-----|-----------|-----------|
| `build` | — | Restore + build Release |
| `test` | build | Testes com cobertura (XPlat Code Coverage) |
| `code-quality` | test | Validação do threshold de cobertura (80%) |

### Estrutura completa

```yaml
name: CI

on:
  pull_request:
    branches:
      - dev
      - 'release/*'
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - run: dotnet restore
      - run: dotnet build --no-restore --configuration Release

  test:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - run: dotnet restore
      - run: dotnet build --no-restore --configuration Release
      - name: Test with coverage
        run: |
          dotnet test --no-build --configuration Release \
            --collect:"XPlat Code Coverage" \
            --results-directory ./coverage
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-results
          path: ./coverage/**/coverage.cobertura.xml

  code-quality:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - uses: actions/download-artifact@v4
        with:
          name: coverage-results
          path: ./coverage
      - name: Install ReportGenerator
        run: dotnet tool install --global dotnet-reportgenerator-globaltool
      - name: Validate coverage threshold
        run: |
          reportgenerator \
            -reports:./coverage/**/coverage.cobertura.xml \
            -targetdir:./coverage/report \
            -reporttypes:TextSummary

          LINE_COVERAGE=$(grep "Line coverage" ./coverage/report/Summary.txt | grep -oP '[\d.]+')
          echo "Line coverage: ${LINE_COVERAGE}%"

          if (( $(echo "$LINE_COVERAGE < 80" | bc -l) )); then
            echo "❌ Coverage ${LINE_COVERAGE}% is below the 80% threshold"
            exit 1
          fi
          echo "✅ Coverage ${LINE_COVERAGE}% meets the 80% threshold"
```

### Required Status Checks (Ruleset)

Os nomes dos jobs no CI **devem** coincidir com os checks exigidos pelo branch ruleset.

---

## Deploy Workflows (dev/stg/prd)

Todos seguem o mesmo padrão, variando apenas os valores por ambiente.

### Estrutura comum

```yaml
name: Deploy to {environment} environment
concurrency: {environment}_environment

on:
  push:
    branches:
      - {branch_pattern}
  workflow_dispatch:
    inputs:
      enable_trace:
        description: "Enable tracing for {Environment} (true or false)"
        required: false
        default: "{default_trace}"
```

### Concurrency

Cada deploy usa `concurrency: {environment}_environment` para garantir que apenas um deploy por ambiente seja executado simultaneamente.

### Job: deploy

Sequência de steps (todos os ambientes):

1. **Checkout** (`actions/checkout@v4`)
2. **Setup .NET** (`actions/setup-dotnet@v4` com `10.x`)
3. **Run tests** (`dotnet test {solution} --configuration Release`)
4. **Set DD_ENABLE_TRACE** (condicional por workflow_dispatch vs push)
5. **Configure AWS credentials** (`aws-actions/configure-aws-credentials@v4`)
6. **Login to Amazon ECR** (`aws-actions/amazon-ecr-login@v2`)
7. **Ensure ECR repository exists** (describe || create)
8. **Get Image Tag** (formato: `YYYY-MM-DD-{runNumber}-{environment}`)
9. **Build, tag, and push image to Amazon ECR**
10. **Download task definition** (describe-task-definition do ECS)
11. **Remove conflicting env vars** (se necessário — apenas dev no exemplo)
12. **Render task definition** (`montebravo-corretora/amazon-ecs-render-task-definition@v1`)
13. **Deploy ECS** (`aws-actions/amazon-ecs-deploy-task-definition@v1`)

### Valores por ambiente

| Variável | dev | stg | prd |
|----------|-----|-----|-----|
| Branch trigger | `dev` | `release/*` | `main` |
| Concurrency | `development_environment` | `staging_environment` | `production_environment` |
| ECS Cluster | `mb-ctvm-cluster-development` | `mb-ctvm-cluster-staging` | `mb-ctvm-cluster-production` |
| Task definition | `{service}-development` | `{service}-staging` | `{service}-production` |
| Image tag | `YYYY-MM-DD-{run}-development` | `YYYY-MM-DD-{run}-staging` | `YYYY-MM-DD-{run}-production` |
| ASPNETCORE_ENVIRONMENT | `Development` | `Staging` | `Production` |
| DD_ENV | `development` | `staging` | `production` |
| DD_ENABLE_TRACE default | `false` | `false` | `true` |
| KEYCLOAK secret prefix | `DEV_` | `STG_` | `PRD_` |

### Variáveis de ambiente padrão (todos os deploys)

```yaml
environment-variables: |
  ASPNETCORE_ENVIRONMENT={Environment}
  Kestrel__Endpoints__Main__Url=http://0.0.0.0:80
  DD_SERVICE={service-name}
  DD_ENV={environment}
  DD_VERSION=${{ env.IMAGE_TAG }}
  DD_ENABLE_TRACE=${{ env.DD_ENABLE_TRACE }}
  TZ=America/Sao_Paulo
  KEYCLOAK_OPENID_CONFIGURATION_URL=${{ secrets.{PREFIX}_KEYCLOAK_OPENID_CONFIGURATION_URL }}
```

### Secrets (injetados via ARN do Secrets Manager)

```yaml
secrets: |
  {VarName}=arn:aws:secretsmanager:us-east-1:{account_id}:secret:{secret-path}:{key}::
```

**Formato do ARN:** `arn:aws:secretsmanager:us-east-1:{account_id}:secret:{secret-path}-{suffix}:{key}::`

> ⚠️ O sufixo aleatório do ARN (ex: `-QTmfUF`) é **específico por secret e ambiente**. Nunca invente — consulte o Secrets Manager ou pergunte ao desenvolvedor.

### Step: Remove conflicting environment variables (quando necessário)

Se uma variável de ambiente está definida TANTO na task definition base quanto nos secrets, o valor da env var tem precedência sobre o secret. Nesse caso, adicionar um step para limpar a env var conflitante:

```yaml
- name: Remove conflicting environment variables managed by secrets
  run: |
    jq '.containerDefinitions[0].environment = [.containerDefinitions[0].environment[] | select(.name != "{VarName}")]' \
      task-definition.json > task-definition-clean.json
    mv task-definition-clean.json task-definition.json
```

### Step: Ensure ECR repository exists

```yaml
- name: Ensure ECR repository exists
  run: |
    aws ecr describe-repositories --repository-names "{service-name}" --region us-east-1 \
      || aws ecr create-repository --repository-name "{service-name}" --region us-east-1
```

---

## GMUD Workflow (`gmud.yml`)

Workflow de **dispatch manual** que inicia o processo formal de GMUD. Calcula automaticamente a próxima versão a partir das tags existentes, cria branches e abre PR.

### Trigger

```yaml
on:
  workflow_dispatch:
    inputs:
      release_date:
        description: 'Data de lançamento (YYYY-MM-DD)'
        required: true
```

> **Nota:** A versão NÃO é informada pelo usuário. É calculada automaticamente pelo job `resolve_version`.

### Jobs

| Job | Depends On | Propósito |
|-----|-----------|-----------|
| `resolve_version` | — | Calcula próxima versão a partir das tags git |
| `setup_branches` | resolve_version | Cria `release/{data}` e `gmud/v{versão}` |
| `update_version` | resolve_version, setup_branches | Atualiza `Directory.Build.props` |
| `create_pr` | resolve_version, update_version | Abre PR gmud → release |

### Job: resolve_version

Calcula automaticamente a próxima versão sequencial do mês corrente:

```yaml
- name: Calculate next version
  id: version
  run: |
    YEAR_MONTH=$(date +'%Y-%m')
    
    # Find the latest tag for the current month
    LATEST_TAG=$(git tag --list "v${YEAR_MONTH}.*" --sort=-v:refname | head -n 1)
    
    if [ -z "$LATEST_TAG" ]; then
      NEXT_SEQ=1
    else
      CURRENT_SEQ=$(echo "$LATEST_TAG" | sed -E "s/v${YEAR_MONTH}\.([0-9]+)/\1/")
      NEXT_SEQ=$((CURRENT_SEQ + 1))
    fi
    
    VERSION="${YEAR_MONTH}.${NEXT_SEQ}"
    echo "version=${VERSION}" >> $GITHUB_OUTPUT
```

> Requer `fetch-depth: 0` no checkout para acessar todas as tags.

### Job: update_version

Atualiza a versão no `Directory.Build.props`:

```yaml
- name: Update version in Directory.Build.props
  run: |
    sed -i 's|<GmudVersion>.*</GmudVersion>|<GmudVersion>${{ env.VERSION }}</GmudVersion>|' Directory.Build.props
```

### Job: create_pr

```bash
gh pr create \
  --base "release/${{ env.RELEASE_DATE }}" \
  --head "gmud/v${{ env.VERSION }}" \
  --title "Release HML (${{ env.RELEASE_DATE }}) v${{ env.VERSION }}" \
  --body "<template GMUD>"
```

---

## Release Workflow (`release.yml`)

Disparado automaticamente quando uma **PR é fechada (merged)** em qualquer branch `release/*`. Verifica se a PR veio de uma branch `gmud/*` e executa o fluxo de release.

### Trigger

```yaml
on:
  pull_request:
    branches:
      - 'release/*'
    types:
      - closed
```

### Jobs

| Job | Depends On | Propósito |
|-----|-----------|-----------|
| `check_merge` | — | Verifica se PR foi merged e veio de `gmud/*` |
| `create_tag` | check_merge | Cria tag `v{versão}` a partir do `Directory.Build.props` |
| `create_release` | create_tag | Cria GitHub Release com release notes automáticas |
| `create_pr_main` | create_release | Abre PR `release/{data}` → `main` |
| `create_pr_dev` | create_release | Abre PR `release/{data}` → `dev` (sync) |

### Job: check_merge

```yaml
- name: Verify PR was merged from gmud branch
  run: |
    if [ "${{ github.event.pull_request.merged }}" == "true" ] && \
       [[ "${{ github.event.pull_request.head.ref }}" =~ ^gmud/ ]]; then
      echo "merged=true" >> $GITHUB_OUTPUT
    else
      echo "merged=false" >> $GITHUB_OUTPUT
    fi

- name: Get version from Directory.Build.props
  run: |
    VERSION=$(grep -oP '(?<=<GmudVersion>).*(?=</GmudVersion>)' Directory.Build.props)
    echo "version=${VERSION}" >> $GITHUB_OUTPUT
```

### Job: create_tag

```yaml
- name: Create and push tag
  run: |
    git tag "v${{ env.VERSION }}"
    git push origin "v${{ env.VERSION }}"
```

### Job: create_release

```yaml
- uses: ncipollo/release-action@v1
  with:
    tag: "v${{ env.VERSION }}"
    name: "Release v${{ env.VERSION }}"
    draft: false
    prerelease: false
    generateReleaseNotes: true
```

### Jobs: create_pr_main e create_pr_dev

```bash
# PR para main (produção)
gh pr create --base main --head "release/${RELEASE_DATE}" \
  --title "Release (${RELEASE_DATE}) v${VERSION}"

# PR para dev (sync)
gh pr create --base dev --head "release/${RELEASE_DATE}" \
  --title "Sync Release (${RELEASE_DATE}) v${VERSION}"
```

---

## Fluxo Completo da GMUD (Sequência)

```
1. Dev dispara gmud.yml (manual) com data de release
     │
     ├── resolve_version calcula versão automaticamente (ex: 2026-07.2)
     ├── Cria branch release/{data} ← main
     ├── Cria branch gmud/v{versão} ← dev
     ├── Atualiza versão no Directory.Build.props
     └── Abre PR: gmud/v{versão} → release/{data}
              │
2. Push em release/{data} dispara deploy-stg.yml
     │ (deploy automático em staging)
     │
3. Time valida em staging, aprova e mergeia a PR
     │
4. Merge dispara release.yml automaticamente
     │
     ├── Verifica se PR veio de gmud/*
     ├── Cria tag v{versão}
     ├── Cria GitHub Release
     ├── Abre PR: release/{data} → main
     └── Abre PR: release/{data} → dev (sync)
              │
5. Time aprova PR para main → merge
     │
6. Push em main dispara deploy-prd.yml
     │ (deploy automático em production)
     │
7. Time aprova PR sync para dev → merge
     (dev fica sincronizada com a versão liberada)
```
