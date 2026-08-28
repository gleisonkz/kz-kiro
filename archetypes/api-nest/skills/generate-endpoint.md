# Skill: Gerar Endpoint REST

## Objetivo

Adicionar um novo endpoint REST a um controller existente, com Swagger, autorização e vision scope.

## Parâmetros

- **controller** (obrigatório): Controller que receberá o endpoint
- **método HTTP** (obrigatório): GET | POST | PATCH | DELETE
- **rota** (obrigatório): Caminho da rota (ex: `table`, `:uid`)
- **roles** (opcional): Roles autorizadas

## Regras

1. Documentar com `@ApiOperation({ summary: '... @Roles Autorizadas: X' })`
2. Adicionar `@ApiResponse` ou `@ApiOkResponsePaginated` conforme o retorno
3. Aplicar `@Roles()` / `@AllowedRoles()` quando restrito
4. Para dados de usuário: calcular vision scope e/ou checar permissão
5. Paginação: usar `startRow`/`endRow` + `ParseOptionalIntPipe`, retornar `PaginationResult<T>`
6. Filtros SSRM: `filterModel`/`sortModel` via `ParseSerializedObjectPipe`
7. Extrair `req.username` e `req.roles` via `@Req()`

## Template (GET paginado com vision scope)

```ts
@ApiOkResponsePaginated(Get{Entity}TableDto)
@ApiOperation({
    summary: `Retorna {entidades} no escopo do usuário.
        @Roles Autorizadas: Assessor | Prospector`,
})
@Roles(Role.Assessor, Role.Prospector)
@Get('table')
async get{Entities}(
    @Req() req: Express.Request,
    @Query('filterModel', ParseSerializedObjectPipe) filterModel: FilterModel,
    @Query('sortModel', ParseSerializedObjectPipe) sortModel: SortModel,
    @Query('startRow', ParseOptionalIntPipe) startRow?: number,
    @Query('endRow', ParseOptionalIntPipe) endRow?: number,
): Promise<PaginationResult<Get{Entity}TableDto>> {
    const mirroredAdvisors = await this.advisorsService.getMirroredAdvisorsByUser(req.username)
    const userVisionScope = getVisionScope(req.roles, Entity.{Entity}, {
        username: req.username,
        mirroredAdvisors,
    })
    return this.{domain}Service.get{Entities}Table(userVisionScope, { startRow, endRow }, filterModel, sortModel)
}
```
