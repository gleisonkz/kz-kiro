# Steering — Archetype Backend NestJS

> **Steering File | Archetype: backend-nest | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos que utilizam o archetype backend-nest.
> Ele complementa o baseline global com diretrizes específicas para projetos NestJS.

---

## Propósito deste Arquivo

Este steering file define as diretrizes específicas para projetos backend construídos com NestJS na MonteBravo. O Kiro deve usar este contexto ao:

- Sugerir estrutura de pastas e módulos NestJS
- Revisar código TypeScript/NestJS
- Propor abordagens para problemas comuns de backend
- Gerar scaffolding de controllers, services, modules e DTOs

---

## Stack Padrão

> TODO: Definir a stack completa e versões mínimas para projetos NestJS.

| Tecnologia | Versão Mínima | Obrigatório | Observação |
|---|---|---|---|
| Node.js | TODO | Sim | LTS mais recente |
| NestJS | TODO | Sim | TODO |
| TypeScript | TODO | Sim | Strict mode ativado |
| ORM/Query Builder | TODO | Sim | TODO (ex.: Prisma, TypeORM, Drizzle) |
| Banco de dados | TODO | Depende | TODO |
| Autenticação | TODO | Sim | TODO (ex.: Passport.js, custom guards) |
| Validação | class-validator + class-transformer | Sim | Usar com ValidationPipe global |
| Documentação de API | Swagger/OpenAPI | Sim | Via @nestjs/swagger |
| Testes | Jest | Sim | Unit + e2e |
| Linter | ESLint + Prettier | Sim | Config compartilhada via TODO |

---

## Estrutura de Pastas Padrão

> TODO: Definir a estrutura de pastas padrão para projetos NestJS da organização.

```
src/
├── main.ts                  # Bootstrap da aplicação
├── app.module.ts            # Módulo raiz
├── config/                  # Configurações e variáveis de ambiente
├── common/                  # Shared: guards, interceptors, decorators, filters
├── modules/                 # Módulos de domínio
│   └── <domain>/
│       ├── <domain>.module.ts
│       ├── <domain>.controller.ts
│       ├── <domain>.service.ts
│       ├── dto/             # Data Transfer Objects
│       ├── entities/        # Entidades de banco de dados
│       └── interfaces/      # Interfaces TypeScript
└── database/                # Migrations, seeds, configuração de banco
```

---

## Padrões de Código

> TODO: Detalhar os padrões de código específicos para NestJS.

### Injeção de Dependência
- Usar sempre injeção de dependência via construtor.
- Evitar instanciação manual de serviços.

### DTOs e Validação
- Usar DTOs tipados com class-validator para toda entrada de dados.
- Ativar `ValidationPipe` globalmente com `whitelist: true` e `forbidNonWhitelisted: true`.

### Error Handling
- Usar exceções HTTP do NestJS (`HttpException`, `NotFoundException`, etc.).
- Criar um `GlobalExceptionFilter` para tratamento centralizado de erros.
- TODO: Definir o formato padrão de resposta de erro da organização.

### Autenticação e Autorização
- TODO: Definir o padrão de guards e decorators para autenticação.
- TODO: Definir o padrão de RBAC utilizado na organização.

---

## Padrões de Teste

> TODO: Definir os padrões de teste para projetos NestJS.

- Cobertura mínima: TODO%
- Testes unitários para services e guards.
- Testes de integração/e2e para controllers e fluxos críticos.
- Usar `@nestjs/testing` para testes unitários de módulos.

---

## O que o Kiro Deve Verificar

Ao analisar código NestJS, o Kiro deve verificar:

- [ ] DTOs com validação adequada em todos os endpoints.
- [ ] Guards de autenticação em rotas protegidas.
- [ ] Tratamento de erros consistente com o padrão da organização.
- [ ] Documentação Swagger atualizada para todos os endpoints.
- [ ] Ausência de segredos hardcoded no código.
- [ ] Cobertura de testes adequada.

---

## Referências

> TODO: Adicionar links para documentação oficial do NestJS, guias internos e exemplos.

---

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
