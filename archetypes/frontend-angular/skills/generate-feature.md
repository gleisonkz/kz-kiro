# Skill: Gerar Feature Module

## Objetivo

Criar um módulo de feature completo seguindo a arquitetura por domínio do projeto.

## Parâmetros

- **nome da feature** (obrigatório): Domínio em kebab-case (ex: `account-transfer`)
- **rota** (opcional): Path da rota lazy-loaded
- **com store** (opcional): Se deve gerar ComponentStore

## Estrutura Gerada

```
features/{feature}/
├── components/                    # Componentes apresentacionais
├── pages/                         # Smart containers (destino de rota)
│   └── {feature}.component.ts
├── store/                         # (se com store)
│   ├── {feature}.store.ts
│   ├── {feature}.service.ts
│   └── {feature}.types.ts
├── {feature}-routing.module.ts
├── {feature}.module.ts
└── index.ts
```

## Regras

1. `{feature}.module.ts` — declarations + providers (store + service)
2. `{feature}-routing.module.ts` — só rotas, exporta RouterModule, provê guards (sem declarations)
3. Página é smart container; componentes em `components/` são apresentacionais
4. Componente apresentacional não acessa store — recebe `@Input`, emite `@Output`
5. Rota registrada com lazy loading no módulo pai (`loadChildren`)
6. Barrel export em `index.ts` para API pública
7. Seletor de componente: prefixo `app`, kebab-case

## Template do Module

```ts
import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { SharedModule } from '../../shared/shared.module';
import { {Feature}RoutingModule } from './{feature}-routing.module';
import { {Feature}Component } from './pages/{feature}.component';
import { {Feature}Store } from './store/{feature}.store';
import { {Feature}Service } from './store/{feature}.service';

@NgModule({
    declarations: [{Feature}Component],
    imports: [CommonModule, SharedModule, {Feature}RoutingModule],
    providers: [{Feature}Store, {Feature}Service],
})
export class {Feature}Module {}
```

## Template do Routing Module

```ts
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { {Feature}Component } from './pages/{feature}.component';

const routes: Routes = [{ path: '', component: {Feature}Component }];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule],
})
export class {Feature}RoutingModule {}
```
