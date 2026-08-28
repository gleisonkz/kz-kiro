# Skill: Gerar Query Builder Kysely

## Objetivo

Criar um query builder Kysely reutilizável, compatível com o SSRM Engine e com vision scope.

## Parâmetros

- **módulo** (obrigatório): Módulo que receberá a query
- **entidade** (obrigatório): Tabela/entidade base
- **tipo** (obrigatório): `table` (listagem SSRM) ou `detail` (registro único)

## Regras

1. Query builder é uma função pura que recebe `db: Kysely<Database>` e retorna um `SelectQueryBuilder`
2. Para tabelas SSRM, definir base query + mapa de colunas (`AliasColumnMap`)
3. Aplicar vision scope via `buildViewScopeFilter(eb, FOREIGN_KEYS, scope)`
4. Usar `ResultType<ReturnType<typeof query>>` para tipar o retorno
5. Definir `MAP_SSRM_COLUMNS_TO_SQL_COLUMNS_FILTER_MODEL` e `_SORT_MODEL`
6. Colunas do data warehouse usam prefixo `dw.`
7. Preferir `jsonBuildObject` / `jsonBuildNullableObject` para objetos aninhados

## Template (table query)

```ts
import { Kysely } from 'kysely'
import { AliasColumnMap, ResultType } from '../../database/kysely/SSRM-engine/alias-column-map.types'
import Database from '../../database/kysely/schemas/Database'

export type {Entity}TableRow = ResultType<ReturnType<typeof {entity}TableBaseQuery>>

export function {entity}TableBaseQuery(db: Kysely<Database>) {
    return db
        .selectFrom('{table} as {alias}')
        .leftJoin('advisors as assessor', 'assessor.username', '{alias}.assessorUsername')
        .select((eb) => [
            '{alias}.uid',
            '{alias}.name',
            // ...
        ])
}

export const MAP_SSRM_COLUMNS_TO_SQL_COLUMNS_FILTER_MODEL = {
    name: '{alias}.name',
    // ...
} as const satisfies AliasColumnMap<typeof {entity}TableBaseQuery>

export const MAP_SSRM_COLUMNS_TO_SQL_COLUMNS_SORT_MODEL = {
    ...MAP_SSRM_COLUMNS_TO_SQL_COLUMNS_FILTER_MODEL,
    uid: '{alias}.uid',
} as const satisfies AliasColumnMap<typeof {entity}TableBaseQuery>
```

## Uso no service (com vision scope + paginação)

```ts
const query = {entity}TableBaseQuery(this.db)
    .where((eb) => buildViewScopeFilter(eb, {ENTITY}_SCOPE_FKS, scope))
const filtered = generateSSRMQueryFilter(query, filterModel, MAP_..._FILTER_MODEL)
const sorted = generateSSRMOrderByCondition(filtered, sortModel, MAP_..._SORT_MODEL)
return executeWithPagination(sorted, { type: 'range', startRow, endRow })
```
