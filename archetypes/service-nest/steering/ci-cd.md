---
inclusion: fileMatch
fileMatchPattern: "**/.github/workflows/**,**/Dockerfile,**/docker-compose.*"
---

# CI/CD — Service NestJS

> **Steering File | Archetype: service-nest | Versão: 0.1.0**

---

## Pipeline de Qualidade (Quality Check)

Trigger: push/PR para `dev`

```
lint → prettier → build → test → audit
```

Cada step é um job independente (com dependências):
- `lint`: `npm run lint`
- `prettier`: `npx prettier --check "{src,projects}/**/*.{ts,js,json}"`
- `build`: `npm run build` (depende de lint)
- `test`: `npm run test` (depende de build)
- `audit`: `npm audit --audit-level critical`

---

## Deploy (por ambiente)

Trigger: push para branch do ambiente (`dev`, `stg`, `main`)

```
checkout → AWS credentials → npm auth → ECR login → Docker build+push → 
Download task definition → Render task definition → Deploy ECS
```

### Detalhes

1. **Build Docker**: Multi-stage (builder + final), tag `{environment}-latest`
2. **ECR**: Push para registry privado AWS
3. **ECS**: Task definition renderizada com:
   - Environment variables (não-sensíveis)
   - Secrets via AWS Secrets Manager ARNs
4. **Wait for stability**: Aguarda o serviço estabilizar no cluster

### Variáveis de ambiente no task definition

- `APP_ENV`, `DD_VERSION`, `TZ=America/Sao_Paulo`
- `DD_SERVICE`, `DD_ENV`, `NODE_ENV`
- `SHARED_REDIS_HOST`, `CORE_API_URL`
- Feature flags: `FEATURE_FLAG_*=true|false`

### Secrets (AWS Secrets Manager)

- `RABBITMQ_URL`, `DATABASE_URL`
- `DISCORD_WEBHOOK`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `SERVICES_COGNITO_*` (client_id, username, password)

---

## Sync DB Types (Automação)

Workflow agendado (cron: seg-sex 12:30 UTC):

1. Abre Security Group para GitHub Actions IP
2. Conecta no DB de desenvolvimento
3. Roda `npm run db:generate`
4. Revoga acesso no Security Group
5. Abre PR com tipos atualizados

---

## Ambientes

| Ambiente | Branch | Cluster ECS | Node |
|----------|--------|-------------|------|
| Development | `dev` | `mb-cluster-development` | 20.16.0 |
| Staging | `stg` | `mb-cluster-staging` | 20.16.0 |
| Production | `main` | `mb-cluster-production` | 20.16.0 |

---

## Concorrência

Deploy usa `concurrency: {environment}_environment` para evitar deploys simultâneos.

---

*Versão: 0.1.0 | Criado em: 2026-08*
