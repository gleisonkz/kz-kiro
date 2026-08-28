---
inclusion: fileMatch
fileMatchPattern: "**/.github/workflows/**"
---

# CI/CD — Frontend Angular

> **Steering File | Archetype: frontend-angular | Versão: 0.1.0**

---

## Pipeline de Qualidade (Quality Check)

Trigger: push/PR para `dev`

```
lint → prettier → build → test → audit
```

- `lint`: `npm run lint`
- `prettier`: `npx prettier --check "{src,projects}/**/*.{ts,js,json}"`
- `build`: cria `environment.production.ts` → `npm run build` (NODE_OPTIONS=--max_old_space_size=4096)
- `test`: `npm run test`
- `audit`: `npm audit --audit-level=critical` (critical porque `xlsx` tem vulnerabilidades sem fix)

Node 18.20.0, `npm ci`. Autenticação NPM via `NPM_TOKEN_RO`.

---

## Deploy (por ambiente)

Trigger: push para branch do ambiente (`dev`, `stg`, `beta`, `main`)

```
checkout → AWS credentials → cria environment.production.ts (com secrets) →
cache node_modules → setup Node → npm ci --legacy-peer-deps →
build (injeta commit SHA) → S3 sync → CloudFront invalidation
```

### Detalhes

1. **environment.production.ts** gerado em runtime com secrets (Cognito, Firebase)
2. **Build**: injeta commit SHA no `main.ts`, `npm run build`
3. **Deploy S3**: `aws s3 sync dist/pt s3://{bucket} --delete`
4. **CloudFront**: `aws cloudfront create-invalidation --paths "/*"`

### Secrets (GitHub Secrets)

- `DEV_AWS_USER_POOL_ID`, `DEV_AWS_USER_POOL_CLIENT_ID`
- `DEV_FIREBASE_API_KEY`, `PROJECT_ID`, `APP_ID`, `MEASUREMENT_ID`
- `DEPLOY_AWS_ACCESS_KEY_ID`, `DEPLOY_AWS_SECRET_ACCESS_KEY`
- `DEV_CLOUDFRONT_DISTRIBUTION_ID`

---

## Diferenças de deploy vs Backend

| Aspecto | Frontend | Backend (api/service) |
|---------|----------|----------------------|
| Artefato | Estático (S3 + CloudFront) | Docker (ECR + ECS) |
| Build | Angular AOT | NestJS build |
| Config | environment.*.ts em runtime | env vars + Secrets Manager |
| Node | 18.20.0 | 20/22 |

---

## Ambientes

| Ambiente | Branch | Bucket S3 |
|----------|--------|-----------|
| Development | `dev` | `mb-frontend-crm-development` |
| Staging | `stg` | `mb-frontend-crm-staging` |
| Beta | `beta` | `mb-frontend-crm-beta` |
| Production | `main` | `mb-frontend-crm-production` |

---

## Notas

- `npm ci --legacy-peer-deps --include=optional` (peer deps do Angular 14 + libs recentes)
- Cache de `node_modules` por hash do `package-lock.json`
- `postinstall` roda `ngcc` (Angular View Engine compat)

---

*Versão: 0.1.0 | Criado em: 2026-08*
