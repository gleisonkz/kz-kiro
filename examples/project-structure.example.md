# Estrutura de Projeto Exemplo — Backend NestJS

> Este arquivo ilustra a estrutura esperada de um projeto que foi configurado com o archetype `backend-nest` e o baseline global do mb-kiro.

---

## Estrutura de Diretórios

```
meu-projeto-backend/
│
├── kiro-manifest.json          # Manifesto Kiro do projeto (gerado pelo bootstrap)
│
├── .kiro/                      # Configurações do Kiro (gerado pelo bootstrap)
│   ├── steering/               # Steering files ativos no projeto
│   │   ├── engineering-principles.md    # Do baseline global
│   │   ├── security-baseline.md         # Do baseline global
│   │   ├── specs-policy.md              # Do baseline global
│   │   ├── documentation-baseline.md    # Do baseline global
│   │   └── nest-stack.md                # Do archetype backend-nest
│   ├── hooks/                  # Hooks ativos no projeto
│   └── agents/                 # Agents ativos no projeto
│
├── src/                        # Código-fonte da aplicação
│   ├── main.ts
│   ├── app.module.ts
│   ├── config/
│   │   ├── configuration.ts
│   │   └── validation.schema.ts
│   ├── common/
│   │   ├── filters/
│   │   │   └── global-exception.filter.ts
│   │   ├── guards/
│   │   │   └── auth.guard.ts
│   │   ├── interceptors/
│   │   │   └── logging.interceptor.ts
│   │   └── decorators/
│   └── modules/
│       └── orders/             # Exemplo de módulo de domínio
│           ├── orders.module.ts
│           ├── orders.controller.ts
│           ├── orders.controller.spec.ts
│           ├── orders.service.ts
│           ├── orders.service.spec.ts
│           ├── dto/
│           │   ├── create-order.dto.ts
│           │   └── update-order.dto.ts
│           └── entities/
│               └── order.entity.ts
│
├── test/                       # Testes e2e
│   ├── app.e2e-spec.ts
│   └── jest-e2e.json
│
├── docs/                       # Documentação técnica do projeto
│   ├── architecture.md         # Visão geral da arquitetura
│   ├── api.md                  # Ou swagger.json / openapi.yaml
│   └── adr/                   # Architecture Decision Records
│       └── ADR-0001-use-nestjs.md
│
├── .env.example                # Variáveis de ambiente necessárias (sem valores reais)
├── README.md                   # Documentação principal do projeto
├── CHANGELOG.md                # Histórico de mudanças
├── package.json
├── tsconfig.json
└── .eslintrc.js
```

---

## O que o Bootstrap Cria Automaticamente

Quando você executa `./scripts/bootstrap.sh --project-type backend-nest --target <seu-projeto>`, os seguintes arquivos são criados/atualizados automaticamente:

| Arquivo/Diretório | Origem | Observação |
|---|---|---|
| `kiro-manifest.json` | Gerado pelo bootstrap | Não editar manualmente — use o sync |
| `.kiro/steering/*.md` | Copiado do baseline + archetype | Pode ser customizado localmente |
| `.kiro/hooks/` | Copiado do archetype | Pode ser customizado localmente |

---

## Arquivos que Você Deve Criar/Manter

| Arquivo | Responsabilidade |
|---|---|
| `README.md` | **Sua responsabilidade** — seguir o template do documentation-baseline |
| `CHANGELOG.md` | **Sua responsabilidade** — atualizar a cada release |
| `docs/architecture.md` | **Sua responsabilidade** — documentar decisões arquiteturais |
| `docs/adr/` | **Sua responsabilidade** — registrar ADRs importantes |
| `.env.example` | **Sua responsabilidade** — listar todas as variáveis sem valores |

---

## Próximos Passos após o Bootstrap

1. Revise o `kiro-manifest.json` e confirme as versões.
2. Execute `./scripts/doctor.sh --target .` para validar a configuração.
3. Preencha o `README.md` com informações do projeto.
4. Configure as variáveis de ambiente em `.env` (baseado em `.env.example`).
5. Crie o primeiro módulo de domínio com `./scripts/bootstrap.sh` (TODO: skill de geração de módulo).

---

*Este é um documento de referência — o conteúdo exato pode variar conforme o projeto e as customizações locais.*
