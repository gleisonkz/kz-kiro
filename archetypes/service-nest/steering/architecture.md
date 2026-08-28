---
inclusion: fileMatch
fileMatchPattern: "**/src/modules/**,**/src/app.module.ts,**/src/main.ts"
---

# Arquitetura do Service NestJS

> **Steering File | Archetype: service-nest | Versão: 0.1.0**
>
> Define a arquitetura interna, padrões de mensageria e organização de módulos
> para microserviços de domínio NestJS da MonteBravo.

---

## Papel Arquitetural

O Service é uma camada de **domínio** que encapsula lógica de negócio e persiste estado:

```
┌──────────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  API / BFF           │────▶│  Service             │────▶│  PostgreSQL     │
│  (HTTP requests)     │◀────│  (NestJS + RabbitMQ) │     │  (Kysely)       │
└──────────────────────┘     └──────────────────────┘     └─────────────────┘
                                    │         ▲
                                    ▼         │
                              ┌─────────────────────┐
                              │  Outros Services    │
                              │  (via RabbitMQ)     │
                              └─────────────────────┘
```

---

## Comunicação via RabbitMQ

### Padrões de comunicação

| Padrão | Uso | Decorator |
|--------|-----|-----------|
| **Request-Reply** | Chamadas síncronas entre serviços | `@MessagePattern('pattern')` |
| **Event (Fire-and-forget)** | Notificações de domínio | `@EventPattern('event.name')` |
| **PubSub (Fan-out)** | Broadcast para múltiplos consumers | `PubSubServerRMQ` + exchange |

### Exchanges consumidos

Cada service se conecta a múltiplos exchanges via `PubSubServerRMQ`:

```ts
// main.ts
const EXCHANGES = ['callbox-events', 'ted-service-events', ...]
const QUEUES = ['activity-service', 'collaborator-transfer-events']

for (const exchange of EXCHANGES) {
  app.connectMicroservice({
    strategy: new PubSubServerRMQ({ urls, exchange, queue: CONSUMER_GROUP })
  })
}

for (const queue of QUEUES) {
  app.connectMicroservice({
    transport: Transport.RMQ, options: { urls, queue }
  })
}
```

### Propagação de contexto do usuário

O `ClientRMQWrapper` injeta automaticamente o usuário autenticado nos headers RMQ:

```ts
// Envio
packet.options.headers = { ...headers, user: this.clsService.get('authenticated-user') }

// Recebimento
@User() user: AuthenticatedUser  // decorator extrai do header RMQ
```

O `UserToClsInterceptor` global extrai o user do header e armazena no CLS.

---

## Organização Interna

```
src/
├── app.module.ts              # Módulo raiz, imports globais
├── main.ts                    # Bootstrap, microservices connections
├── filters/                   # Exception filters (RPC)
├── helpers/                   # Utilitários puros
├── types/                     # Tipos base, enums, DTOs compartilhados
└── modules/
    ├── auth/                  # Decorators, interceptors, roles
    ├── kysely/                # KyselyService + schemas gerados
    ├── health/                # Health check endpoint
    ├── http-wrapper/          # Axios com auth token automático
    ├── clients-wrapper/       # ClientRMQ com propagação de user
    ├── discord-logger/        # Logger para Discord (erros)
    ├── cron-jobs/             # Scheduled tasks
    └── {domain}/              # Módulos de domínio
        ├── {domain}.module.ts
        ├── {domain}.controller.ts
        ├── {domain}.service.ts
        ├── {domain}.spec.ts
        ├── types/
        │   ├── dtos/incoming/
        │   ├── dtos/outgoing/  (opcional)
        │   └── shared/
        └── batch-processing/   (se usar BullMQ)
```

---

## Anatomia de um Módulo de Domínio

```ts
// tasks.module.ts
@Module({
  imports: [
    ConfigModule.forFeature(tasksConfig),
    HttpWrapperModule,
    KyselyModule,
    ClientsModule.registerAsync([...]),  // RabbitMQ clients
    TasksBatchModule,                    // BullMQ (opcional)
  ],
  controllers: [TasksController],
  providers: [TasksService, TasksPermissionsService],
  exports: [TasksService],
})
export class TasksModule {}
```

### Controller (Message Handlers)

```ts
@Controller()
export class TasksController {
  @MessagePattern('create-task')
  async createTask(@User() user: AuthenticatedUser, @Body() task: CreateTaskDto) {
    return this.tasksService.createTask(task, user)
  }

  @MessagePattern('update-task')
  @UseGuards(TaskPermissionsGuard)
  async updateTask(@User() user: AuthenticatedUser, @Body() taskUpdate: UpdateTaskDto) {
    return this.tasksService.updateTask(taskUpdate, user)
  }
}
```

### Service (Lógica de Negócio)

- Queries Kysely **diretas** no service (sem repository pattern separado)
- Chamadas HTTP a outros serviços via `HttpWrapperModule`
- Comunicação RabbitMQ via `ClientProxy` injetado

### DTOs (Zod)

```ts
// types/dtos/incoming/create-task.dto.ts
export const CreateTaskDtoSchema = z.object({
  title: z.string(),
  category: z.nativeEnum(TasksCategoryEnum),
  deadlineDate: z.coerce.date(),
  // ...
}).refine(...)

export class CreateTaskDto extends createZodDto(CreateTaskDtoSchema) {}
```

---

## Batch Processing (BullMQ)

Para operações em lote que precisam de retry e paralelismo:

```ts
// batch-processing/tasks-batch.module.ts
@Module({
  imports: [
    BullModule.registerFlowProducer({ name: CREATE_TASK_PROCESSOR_NAME }),
  ],
  providers: [TasksBatchService, CreateTaskProcessor],
})
export class TasksBatchModule {}
```

- `FlowProducer` para parent/child job patterns
- `@Processor` + `WorkerHost` para consumers
- Retry com backoff exponencial (attempts: 5, delay: 5000ms)
- Redis como backend de filas

---

## Autenticação e Autorização

- **Sem auth HTTP próprio** — service confia no user propagado via RabbitMQ headers
- `@User()` decorator extrai `AuthenticatedUser { username, roles }` do contexto RPC
- Guards verificam permissões baseadas em ownership (creator/owner) e roles
- `ClsModule` global para request-scoped storage do user

---

## Configuração Tipada (Zod)

```ts
// tasks.config.ts
const configSchema = z.object({
  CORE_API_URL: z.string().url(),
  RABBITMQ_URL: z.string().url(),
})

export default registerAs('tasks_config', () => configSchema.parse(process.env))
```

---

## Resiliência

- **Retry automático**: BullMQ jobs com exponential backoff
- **Dead letter**: Mensagens que falham após retries vão para DLQ
- **Distributed locking**: `RedisTryLockModule` para operações que precisam de exclusividade
- **Error recovery**: `RecoverableError` schema para erros que podem ser tratados pelo caller
- **Logging de erros**: Discord webhook para alertas em tempo real

---

## Health Check

```
GET /health  →  { status: 'ok' }
```

Único endpoint HTTP exposto pelo service.

---

*Versão: 0.1.0 | Criado em: 2026-08*
