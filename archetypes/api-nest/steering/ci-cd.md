---
inclusion: fileMatch
fileMatchPattern: "**/.github/workflows/**,**/Dockerfile"
---

# CI/CD — API NestJS

> **Steering File | Archetype: api-nest | Versão: 0.1.0**

---

## Pipeline de Qualidade (Quality Check)

Trigger: push/PR para `dev`

```
lint → prettier → build → test → audit
```

- `lint`: `npm run lint`
- `prettier`: `npx prettier --check "{src,projects}/**/*.{ts,js,json}"`
- `build`: `npm run build` (NODE_OPTIONS=--max_old_space_size=4096)
- `test`: `npm run test`
- `audit`: `npm audit --audit-level high`

Node 22.16.0, `npm ci`. Autenticação NPM via `NPM_TOKEN_RO`.

---

## Deploy (por ambiente)

Trigger: push para branch do ambiente (`dev`, `stg`, `main`)

```
checkout → set trace flag → AWS credentials → npm auth → ECR login →
Docker build+push → download task definition → get version →
render task definition → deploy ECS (wait for stability)
```

### Environment variables (task definition)

- `APP_ENV`, `DD_VERSION`, `APP_VERSION`, `TZ=America/Sao_Paulo`
- `DB_STATEMENT_TIMEOUT=30000`, `LOGGING_LEVEL=info`
- `DD_SERVICE`, `DD_ENV`, `DD_ENABLE_TRACE`, `NODE_ENV=production`
- `CORE_API_URL`, `FRONTEND_CRM_URL`
- `S3_BUCKET_FILES`, `S3_BUCKET_ACCOUNTS_EXPORT`
- `DATABASE_SSL_CERT_PATH=us-east-1-bundle.pem`
- `NODE_OPTIONS=--max-old-space-size=1230`

### Secrets (AWS Secrets Manager ARNs)

- `RABBITMQ_URL`, `DISCORD_WEBHOOK`
- `CORE_DATABASE_*` (host, port, user, password, name, url)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `BROKER_COGNITO_*`, `SERVICES_COGNITO_*`
- `TABLEAU_*`, `ZIP_CODE_LAMBDA_*`

---

## Sync DB Types

Workflow agendado que introspeciona o DB e abre PR com tipos Kysely atualizados (mesmo padrão do service-nest).

---

## Ambientes

| Ambiente | Branch | Cluster ECS | Node |
|----------|--------|-------------|------|
| Development | `dev` | `mb-cluster-development` | 22.16.0 |
| Staging | `stg` | `mb-cluster-staging` | 22.16.0 |
| Production | `main` | `mb-cluster-production` | 22.16.0 |

Container name: `mb-crm-api` / repositório ECR: `mb-api-crm`.

---

*Versão: 0.1.0 | Criado em: 2026-08*
