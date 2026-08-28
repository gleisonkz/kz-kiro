# Skill: Gerar Query SSRM (AG Grid)

## Objetivo

Gerar uma query SSRM-compatible com Kysely que implementa filter, sort e pagination para AG Grid Server-Side Row Model.

## Parâmetros

- **módulo** (obrigatório): Nome do módulo que receberá a query
- **tabela/view** (obrigatório): Nome da tabela ou view no PostgreSQL
- **colunas** (obrigatório): Lista de colunas disponíveis para filtro/sort
- **com vision scope** (padrão: true): Se deve aplicar vision scope

## Estrutura

A query SSRM é implementada no `{modulo}-queries.service.ts` com os seguintes métodos:

- `getSsrm(request: SsrmRequestDto, user: AuthenticatedUser)` — método principal
- `buildBaseQuery()` — query base com selects
- `applyFilters(query, filterModel)` — aplica filtros AG Grid
- `applySorting(query, sortModel)` — aplica ordenação
- `applyVisionScope(query, user)` — aplica row-level security

## Regras

1. Sempre aplicar vision scope ANTES dos filtros do usuário
2. Filtros AG Grid suportados: text, number, date, set
3. Operadores text: `contains`, `equals`, `notEqual`, `startsWith`, `endsWith`
4. Operadores number/date: `equals`, `greaterThan`, `lessThan`, `inRange`
5. Set filter: usa `IN (...)` com array de values
6. Pagination via `startRow` / `endRow` (offset/limit)
7. Retornar `{ rows, lastRow }` onde `lastRow` é -1 se há mais dados
8. `lastRow` é o total de registros quando não há mais páginas

## Template Completo

```ts
import { Injectable } from '@nestjs/common'
import { KyselyService } from '../kysely/kysely.service'
import { AuthenticatedUser } from '../../types/authenticated-user'
import { VisionScope } from '../../types/enums'
import { SsrmRequestDto, FilterModel, SortModel } from '../../types/ssrm-request.dto'
import { SsrmResponseDto } from '../../types/ssrm-response.dto'

@Injectable()
export class {Nome}QueriesService {
    constructor(private readonly kysely: KyselyService) {}

    async getSsrm(request: SsrmRequestDto, user: AuthenticatedUser): Promise<SsrmResponseDto<any>> {
        const { startRow, endRow, filterModel, sortModel } = request
        const limit = endRow - startRow

        let query = this.buildBaseQuery()
        query = this.applyVisionScope(query, user)
        query = this.applyFilters(query, filterModel)
        query = this.applySorting(query, sortModel)

        // Contar total para lastRow
        const countQuery = query
        const [{ count }] = await this.kysely
            .selectFrom(query.as('filtered'))
            .select(this.kysely.fn.countAll().as('count'))
            .execute()

        const totalCount = Number(count)

        // Aplicar paginação
        const rows = await query
            .offset(startRow)
            .limit(limit)
            .execute()

        const lastRow = startRow + rows.length >= totalCount ? totalCount : -1

        return { rows, lastRow }
    }

    private buildBaseQuery() {
        return this.kysely
            .selectFrom('{tabela}_view')
            .select([
                'id',
                'name',
                // ... colunas do módulo
            ])
    }

    private applyVisionScope(query: any, user: AuthenticatedUser) {
        if (user.visionScope === VisionScope.GLOBAL) return query
        if (user.visionScope === VisionScope.MIRRORED) {
            return query.where('advisor_id', 'in', user.mirroredAdvisorIds)
        }
        return query.where('advisor_id', '=', user.advisorId)
    }

    private applyFilters(query: any, filterModel: FilterModel) {
        if (!filterModel) return query

        for (const [column, filter] of Object.entries(filterModel)) {
            query = this.applyColumnFilter(query, column, filter)
        }

        return query
    }

    private applyColumnFilter(query: any, column: string, filter: any) {
        switch (filter.filterType) {
            case 'text':
                return this.applyTextFilter(query, column, filter)
            case 'number':
                return this.applyNumberFilter(query, column, filter)
            case 'date':
                return this.applyDateFilter(query, column, filter)
            case 'set':
                return query.where(column, 'in', filter.values)
            default:
                return query
        }
    }

    private applyTextFilter(query: any, column: string, filter: any) {
        const { type, filter: value } = filter

        switch (type) {
            case 'contains':
                return query.where(column, 'ilike', `%${value}%`)
            case 'equals':
                return query.where(column, '=', value)
            case 'notEqual':
                return query.where(column, '!=', value)
            case 'startsWith':
                return query.where(column, 'ilike', `${value}%`)
            case 'endsWith':
                return query.where(column, 'ilike', `%${value}`)
            default:
                return query
        }
    }

    private applyNumberFilter(query: any, column: string, filter: any) {
        const { type, filter: value, filterTo } = filter

        switch (type) {
            case 'equals':
                return query.where(column, '=', value)
            case 'greaterThan':
                return query.where(column, '>', value)
            case 'lessThan':
                return query.where(column, '<', value)
            case 'inRange':
                return query.where(column, '>=', value).where(column, '<=', filterTo)
            default:
                return query
        }
    }

    private applyDateFilter(query: any, column: string, filter: any) {
        const { type, dateFrom, dateTo } = filter

        switch (type) {
            case 'equals':
                return query.where(column, '=', dateFrom)
            case 'greaterThan':
                return query.where(column, '>', dateFrom)
            case 'lessThan':
                return query.where(column, '<', dateFrom)
            case 'inRange':
                return query.where(column, '>=', dateFrom).where(column, '<=', dateTo)
            default:
                return query
        }
    }

    private applySorting(query: any, sortModel: SortModel[]) {
        if (!sortModel || sortModel.length === 0) {
            return query.orderBy('id', 'asc')
        }

        for (const { colId, sort } of sortModel) {
            query = query.orderBy(colId, sort)
        }

        return query
    }
}
```

## Uso no Controller

```ts
@Post('ssrm')
@AllowedRoles(Role.ADMIN, Role.ADVISOR)
@ApiOperation({ summary: 'SSRM query para AG Grid' })
async getSsrm(
    @Body() body: SsrmRequestDto,
    @AuthUser() user: AuthenticatedUser,
): Promise<SsrmResponseDto<Get{Entidade}Dto>> {
    return this.{nome}QueriesService.getSsrm(body, user)
}
```

## SsrmRequestDto (referência)

```ts
export class SsrmRequestDto {
    @ApiProperty() startRow: number
    @ApiProperty() endRow: number
    @ApiPropertyOptional() filterModel?: FilterModel
    @ApiPropertyOptional() sortModel?: SortModel[]
    @ApiPropertyOptional() groupKeys?: string[]
}

export interface SortModel {
    colId: string
    sort: 'asc' | 'desc'
}

export type FilterModel = Record<string, TextFilter | NumberFilter | DateFilter | SetFilter>
```
