# Skill: Gerar Módulo de Domínio

## Objetivo

Criar um módulo de domínio completo para a API REST, seguindo os padrões do projeto.

## Parâmetros

- **nome do módulo** (obrigatório): Domínio em kebab-case (ex: `investment-funds`)
- **entidade** (obrigatório): Nome da entidade principal

## Estrutura Gerada

```
src/modules/{nome}/
├── {nome}.module.ts
├── {nome}.controller.ts
├── {nome}.service.ts
├── {nome}-queries.service.ts      (se houver queries complexas)
├── dtos/
│   ├── incoming/
│   │   └── create-{entidade}.dto.ts
│   └── outgoing/
│       └── get-{entidade}.dto.ts
├── queries/
│   └── {entidade}-table.query.ts  (se houver tabela SSRM)
└── {nome}.service.spec.ts
```

## Regras

1. Controller com `@ApiTags`, `@ApiBearerAuth`, `@Controller('{recurso-plural}')`
2. Endpoints documentados com `@ApiOperation` incluindo `@Roles Autorizadas:`
3. Aplicar `@Roles()` ou `@AllowedRoles()` quando restrito
4. Queries de dados de usuário DEVEM aplicar vision scope
5. Novo código de acesso a dados usa **Kysely** (não TypeORM)
6. DTOs de entrada com class-validator; DTOs de saída com `@ApiProperty`
7. Registrar o módulo no `api.module.ts` (hub central)
8. Usar `forwardRef` se houver dependência circular

## Template do Module

```ts
import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { KyselyModule } from '../database/kysely/kysely.module'
import { HttpWrapperModule } from '../http-wrapper/http-wrapper.module'
import { {Nome}Controller } from './{nome}.controller'
import { {Nome}Service } from './{nome}.service'
import { {Nome}QueriesService } from './{nome}-queries.service'

@Module({
    imports: [ConfigModule, KyselyModule, HttpWrapperModule],
    controllers: [{Nome}Controller],
    providers: [{Nome}Service, {Nome}QueriesService],
    exports: [{Nome}Service],
})
export class {Nome}Module {}
```
