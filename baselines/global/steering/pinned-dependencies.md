# Dependências Pinadas — Regra Global Obrigatória

Esta regra é **inegociável** e se aplica a **todos** os projetos, independentemente do archetype, stack ou linguagem.

## Regra

Toda dependência adicionada a qualquer projeto **DEVE** usar versão exata (pinada). Nunca use ranges, tildes ou carets.

## O que é proibido

- `^1.2.3` (caret range)
- `~1.2.3` (tilde range)
- `>=1.0.0` (range aberto)
- `*` ou `latest`
- `1.x` ou `1.2.x`

## O que é obrigatório

- `1.2.3` (versão exata, sem prefixo)

## Exemplos

### package.json (Node.js / npm / yarn / pnpm)

```json
// ❌ ERRADO
{
  "dependencies": {
    "express": "^4.18.2",
    "lodash": "~4.17.21"
  }
}

// ✅ CORRETO
{
  "dependencies": {
    "express": "4.18.2",
    "lodash": "4.17.21"
  }
}
```

## Aplicação

- Ao instalar dependências via CLI, use flags que garantam versão exata:
  - npm: `npm install pacote@versao --save-exact` ou configure `.npmrc` com `save-exact=true`
  - yarn: `yarn add pacote@versao --exact`
  - pnpm: `pnpm add pacote@versao --save-exact`
- Ao sugerir ou gerar código que adicione dependências, **sempre** use a versão exata disponível no momento.
- Se não souber a versão exata mais recente, pesquise antes de adicionar.

## Justificativa

Versões pinadas garantem builds reproduzíveis, eliminam surpresas com breaking changes em patches/minors e facilitam auditoria de segurança. Lockfiles complementam, mas não substituem, a pinagem explícita no manifesto.
