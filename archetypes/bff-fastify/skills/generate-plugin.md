---
name: "Gerar Plugin Fastify"
description: "Cria um plugin Fastify encapsulado seguindo os padrões do archetype BFF, usando fastify-plugin (fp)."
inclusion: manual
---

# Gerar Plugin Fastify

## Quando usar

Quando o desenvolvedor pedir para criar um plugin Fastify global (ex.: autenticação, rate limiting customizado, request context, health check).

## Inputs esperados

- **Nome do plugin** (obrigatório): nome descritivo em kebab-case (ex.: `auth`, `request-context`, `error-handler`, `health-check`).
- **Descrição** (opcional): o que o plugin faz.
- **Escopo** (opcional): global (registrado no app via `fp`) ou encapsulado (sem `fp`).

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Arquivo: em `src/app/plugins/`, nomeado pela responsabilidade: `auth.ts`, `error-handler.ts`.
- Função exportada: `camelCase` com sufixo `Plugin` — `authPlugin`, `errorHandlerPlugin`.

### Estrutura

```
src/app/plugins/
├── auth.ts
├── error-handler.ts
├── logger.ts
├── clients.ts
└── health-check.ts
```

### Padrões obrigatórios (ref: RFC-0014)

- Usar `fastify-plugin` (`fp`) para plugins que devem ser acessíveis fora do escopo de encapsulamento (a maioria dos plugins globais).
- Tipar decorators adicionados ao Fastify via `declare module 'fastify'`.
- Documentar o propósito do plugin com JSDoc.
- Testar com `fastify.inject()`.

### Quando usar `fp` (fastify-plugin)

- **Com `fp`**: plugins que adicionam decorators, hooks ou funcionalidades que devem ser visíveis em toda a aplicação (auth, clients, error handler).
- **Sem `fp`**: plugins que devem ser encapsulados em um escopo específico (raro para plugins globais).

## Exemplo de output

### `src/app/plugins/auth.ts`

```ts
import { FastifyPluginAsync, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';

declare module 'fastify' {
  interface FastifyRequest {
    userId: string;
    correlationId: string;
  }
}

/**
 * Plugin de autenticação.
 * Valida JWT e adiciona userId e correlationId à request.
 */
const authPluginFn: FastifyPluginAsync = async (fastify) => {
  fastify.decorateRequest('userId', '');
  fastify.decorateRequest('correlationId', '');

  fastify.addHook('onRequest', async (request) => {
    // Gerar/propagar correlation ID
    request.correlationId =
      (request.headers['x-correlation-id'] as string) ?? crypto.randomUUID();

    // Rotas públicas (health check)
    if (request.url.startsWith('/health')) return;

    // Validar token
    const authHeader = request.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw fastify.httpErrors.unauthorized('Token ausente');
    }

    const token = authHeader.slice(7);
    // TODO: validar JWT e extrair userId
    request.userId = 'extracted-from-token';
  });

  fastify.addHook('onSend', async (request, reply) => {
    reply.header('x-correlation-id', request.correlationId);
  });
};

export const authPlugin = fp(authPluginFn, {
  name: 'auth',
  fastify: '5.x',
});
```

### `src/app/plugins/health-check.ts`

```ts
import { FastifyPluginAsync } from 'fastify';
import fp from 'fastify-plugin';

/**
 * Plugin de health check.
 * Expõe /health/live (liveness) e /health/ready (readiness).
 */
const healthCheckPluginFn: FastifyPluginAsync = async (fastify) => {
  fastify.get('/health/live', async () => ({ status: 'ok' }));

  fastify.get('/health/ready', async () => {
    // TODO: verificar conectividade com serviços downstream críticos
    return { status: 'ok', timestamp: new Date().toISOString() };
  });
};

export const healthCheckPlugin = fp(healthCheckPluginFn, {
  name: 'health-check',
  fastify: '5.x',
});
```

### Registro no servidor

```ts
// src/app/server.ts
import { authPlugin } from './plugins/auth';
import { healthCheckPlugin } from './plugins/health-check';

// Dentro de buildServer():
await fastify.register(healthCheckPlugin);
await fastify.register(authPlugin);
```
