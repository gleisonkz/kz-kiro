# Skill: Gerar Componente Compartilhado (Apresentacional)

## Objetivo

Criar um componente apresentacional ("burro") reutilizável na shared ou em lib do design system.

## Parâmetros

- **nome** (obrigatório): Nome do componente em kebab-case (ex: `status-badge`)
- **local** (obrigatório): `shared` (app) ou `lib` (projects/mb ou projects/components)

## Regras

1. Componente **apresentacional**: apenas apresenta UI, sem lógica de negócio
2. Recebe dados via `@Input`, comunica via `@Output` (EventEmitter)
3. **Não** acessa store, HTTP ou estado global
4. Seletor: prefixo `app`, kebab-case, tipo element
5. Estilos em SCSS com variáveis do design system (`src/theme/`)
6. Se em lib, exportar via `public-api.ts` / `index.ts`
7. Gerar `.spec.ts` com teste básico de criação
8. Se possível, criar `.stories.ts` para Storybook
9. Cleanup de subscriptions com `destroy$` + `takeUntil`

## Template

```ts
import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
    selector: 'app-{nome}',
    templateUrl: './{nome}.component.html',
    styleUrls: ['./{nome}.component.scss'],
})
export class {Nome}Component {
    @Input() value: string | undefined;
    @Input() variant: 'primary' | 'secondary' = 'primary';
    @Output() action = new EventEmitter<void>();

    onClick(): void {
        this.action.emit();
    }
}
```

## Template do Teste

```ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { {Nome}Component } from './{nome}.component';

describe('{Nome}Component', () => {
    let component: {Nome}Component;
    let fixture: ComponentFixture<{Nome}Component>;

    beforeEach(async () => {
        await TestBed.configureTestingModule({
            declarations: [{Nome}Component],
        }).compileComponents();

        fixture = TestBed.createComponent({Nome}Component);
        component = fixture.componentInstance;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
```
