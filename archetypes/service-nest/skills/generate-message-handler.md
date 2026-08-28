# Skill: Gerar Message Handler

## Objetivo

Adicionar um novo handler de mensagem RabbitMQ a um módulo existente.

## Parâmetros

- **módulo** (obrigatório): Nome do módulo que receberá o handler
- **pattern** (obrigatório): Pattern RabbitMQ (ex: `create-appointment`)
- **tipo** (obrigatório): `message` (request-reply) ou `event` (fire-and-forget)

## Regras

1. Usar `@MessagePattern` para request-reply, `@EventPattern` para fire-and-forget
2. Extrair user com `@User()` decorator quando necessário
3. Criar DTO Zod para o payload de entrada
4. Adicionar log com `MbLogger.log({ eventKind: '...', data: {...} })`
5. Se usar guard de permissão, aplicar `@UseGuards()`

## Template

```ts
@MessagePattern('{pattern}')
async handle{Action}(@User() user: AuthenticatedUser, @Body() dto: {Action}Dto) {
    MbLogger.log({
        eventKind: '{ACTION_UPPER}',
        data: { user, dto },
    })
    return this.{service}.{action}(dto, user)
}
```
