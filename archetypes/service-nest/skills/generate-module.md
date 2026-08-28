# Skill: Gerar Módulo de Domínio

## Objetivo

Criar um módulo de domínio completo para o microserviço, seguindo os padrões arquiteturais do projeto.

## Parâmetros

- **nome do módulo** (obrigatório): Nome do domínio em kebab-case (ex: `appointments`)
- **message patterns** (opcional): Lista de patterns RabbitMQ que o módulo irá expor

## Estrutura Gerada

```
src/modules/{nome}/
├── {nome}.module.ts
├── {nome}.controller.ts
├── {nome}.service.ts
├── {nome}.config.ts
├── {nome}.spec.ts
└── types/
    ├── dtos/
    │   └── incoming/
    │       └── create-{entidade}.dto.ts
    └── shared/
        └── {entidade}-entity.ts
```

## Regras

1. O controller usa `@MessagePattern` (não `@Get/@Post`)
2. DTOs são definidos com Zod schemas + `createZodDto`
3. O service injeta `KyselyService` diretamente (sem repository)
4. Config usa `registerAs` com schema Zod
5. Exportar o service no module para uso por outros módulos
6. Importar `KyselyModule`, `ConfigModule.forFeature`, `HttpWrapperModule`
7. Registrar o módulo no `app.module.ts`

## Template do Module

```ts
import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { HttpWrapperModule } from '../http-wrapper/http-wrapper.module'
import { KyselyModule } from '../kysely/kysely.module'
import {nome}Config from './{nome}.config'
import { {Nome}Controller } from './{nome}.controller'
import { {Nome}Service } from './{nome}.service'

@Module({
    imports: [
        ConfigModule.forFeature({nome}Config),
        HttpWrapperModule,
        KyselyModule,
    ],
    controllers: [{Nome}Controller],
    providers: [{Nome}Service],
    exports: [{Nome}Service],
})
export class {Nome}Module {}
```

## Template do Controller

```ts
import { Body, Controller } from '@nestjs/common'
import { MessagePattern } from '@nestjs/microservices'
import { AuthenticatedUser, User } from '../auth/decorators/user.decorator'
import { {Nome}Service } from './{nome}.service'

@Controller()
export class {Nome}Controller {
    constructor(private readonly {nome}Service: {Nome}Service) {}

    @MessagePattern('get-{nome}')
    async get{Nome}(@User() user: AuthenticatedUser, @Body() data: any) {
        return await this.{nome}Service.get(data)
    }
}
```
