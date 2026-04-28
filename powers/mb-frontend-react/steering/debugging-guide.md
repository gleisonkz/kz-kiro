---
name: "Guia de Debugging Frontend"
description: "Orienta o Kiro sobre como auxiliar no debugging de aplicações React com as ferramentas da stack MonteBravo."
inclusion: manual
---

# Guia de Debugging — Frontend React

## Ferramentas Disponíveis

### Chrome DevTools MCP

O projeto tem o Chrome DevTools MCP configurado. Use-o para:

- Inspecionar elementos e DOM ao vivo.
- Monitorar requisições de rede (XHR, fetch).
- Avaliar JavaScript no console do browser.
- Capturar screenshots para análise visual.
- Coletar métricas de performance (Core Web Vitals).

Para usar: o Chrome deve estar aberto com remote debugging habilitado.

### React DevTools

- Inspecionar árvore de componentes e props.
- Identificar re-renders desnecessários via Profiler.
- Verificar estado de hooks e context.

### Redux DevTools

- Inspecionar store global e histórico de actions.
- Time-travel debugging (navegar entre estados).
- Verificar estado de RTK Query (cache, loading, errors).
- Exportar/importar estado para reproduzir bugs.

## Estratégias de Debug por Tipo de Problema

### Componente não renderiza ou renderiza errado

1. Verificar props recebidas (React DevTools).
2. Verificar estado local e hooks.
3. Verificar se o componente está dentro do Provider correto.
4. Verificar imports (barrel exports podem mascarar erros).

### Dados não carregam (RTK Query)

1. Verificar aba Network no Chrome DevTools — a request está saindo?
2. Verificar Redux DevTools — o endpoint RTK Query está no store?
3. Verificar tags de cache — invalidação está correta?
4. Verificar se o `baseQuery` tem a URL correta.
5. Verificar se o reducer do API está registrado no store.

### Performance lenta

1. React Profiler — identificar componentes que re-renderizam demais.
2. Chrome DevTools Performance tab — identificar long tasks.
3. Verificar bundle size — imports desnecessários?
4. Verificar se listas grandes usam virtualização.
5. Verificar se há fetches duplicados (RTK Query deduplica, mas verificar uso).

### Erro de estado inconsistente

1. Redux DevTools — verificar sequência de actions.
2. Verificar se selectors retornam referências estáveis.
3. Verificar se há race conditions em efeitos assíncronos.
4. Verificar se estado de domínio está no módulo correto (não vazando entre módulos).

### Erro de acessibilidade

1. Chrome DevTools Accessibility tab.
2. Storybook addon-a11y para componentes isolados.
3. Verificar roles, labels e navegação por teclado.
4. Testar com screen reader (VoiceOver no macOS).
