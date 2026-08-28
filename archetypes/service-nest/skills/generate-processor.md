---
name: "Gerar Processor BullMQ"
description: "Cria a estrutura completa de um módulo BullMQ processor: batch module, batch service (FlowProducer) e processor com retry exponencial."
inclusion: manual
---

# Gerar Processor BullMQ

## Quando usar

Quando o desenvolvedor pedir para criar um processor de jobs assíncronos (BullMQ) para processamento em batch, tarefas demoradas ou operações com retry.

## Inputs esperados

- **Nome do processor** (obrigatório): nome em kebab-case (ex.: `report`, `notification`, `sync-tasks`).
- **Domínio pai** (obrigatório): módulo de domínio onde o processor será criado (ex.: `report`, `notification`).
- **Campos do job** (opcional): dados que cada job recebe.
- **Estratégia** (opcional): `single` (jobs individuais) ou `batch` (parent/child com FlowProducer). Default: `batch`.

## Regras de geração

### Nomenclatura (ref: naming-conventions.md)

- Diretório: `modules/{domain}/batch-processing/`.
- Batch Module: `{name}-batch.module.ts`.
- Batch Service: `{name}-batch.service.ts`.
- Processor: `{name}.processor.ts`.
- Queue names: `kebab-case` — `report-batch`, `notification-dispatch`.
- Job names: `kebab-case` — `report-item`, `send-notification`.

### Estrutura

```
src/modules/{domain}/batch-processing/
├── {name}-batch.module.ts      # Registra queue + processor + service
├── {name}-batch.service.ts     # Enfileira jobs (FlowProducer para batch)
└── {name}.processor.ts         # Processa jobs individuais
```

### Regras de implementação

- **Batch Module**: registra BullModule.forRoot/forFeature, FlowProducer, processor e service.
- **Batch Service**: injeta FlowProducer, cria flows com parent/child jobs.
- **Processor**: `@Processor` decorator, `@Process` handler, retry com backoff exponencial.
- **Retry**: `attempts: 3`, `backoff: { type: 'exponential', delay: 1000 }`.
- **Logging**: `MbLogger` em todo processor para rastreabilidade.

### O que gerar

1. `{name}-batch.module.ts` — módulo NestJS com BullMQ config.
2. `{name}-batch.service.ts` — service que enfileira jobs.
3. `{name}.processor.ts` — processor que executa jobs.

### O que NÃO gerar automaticamente

- Configuração Redis global — deve existir no AppModule ou config global.
- Dashboard de monitoramento (Bull Board) — configurar separadamente.
- Alertas Discord — configurar no módulo de observabilidade.

## Exemplo de output

Para processor `report` no domínio `report` (estratégia batch):

### `src/modules/report/batch-processing/report-batch.module.ts`

```ts
import { Module } from '@nestjs/common'
import { BullModule } from '@nestjs/bull'
import { ReportBatchService } from './report-batch.service'
import { ReportProcessor } from './report.processor'

@Module({
    imports: [
        BullModule.registerQueue(
            { name: 'report-batch' },
            { name: 'report-items' },
        ),
    ],
    providers: [ReportBatchService, ReportProcessor],
    exports: [ReportBatchService],
})
export class ReportBatchModule {}
```

### `src/modules/report/batch-processing/report-batch.service.ts`

```ts
import { Injectable, Inject } from '@nestjs/common'
import { FlowProducer } from 'bullmq'
import { MbLogger } from '@montebravo.tech/mb-telemetry'

export interface ReportItem {
    reportId: string
    userId: string
    startDate: string
    endDate: string
}

@Injectable()
export class ReportBatchService {
    private readonly logger = new MbLogger(ReportBatchService.name)

    constructor(
        @Inject('REPORT_FLOW_PRODUCER')
        private readonly flowProducer: FlowProducer,
    ) {}

    async enqueueBatch(items: ReportItem[]): Promise<void> {
        this.logger.log(`Enqueuing batch of ${items.length} report items`)

        await this.flowProducer.add({
            name: 'report-batch-parent',
            queueName: 'report-batch',
            data: { totalItems: items.length, enqueuedAt: new Date().toISOString() },
            children: items.map((item) => ({
                name: 'report-item',
                queueName: 'report-items',
                data: item,
                opts: {
                    attempts: 3,
                    backoff: { type: 'exponential', delay: 1000 },
                    removeOnComplete: true,
                    removeOnFail: 100,
                },
            })),
        })

        this.logger.log(`Batch enqueued successfully`)
    }

    async enqueueSingle(item: ReportItem): Promise<void> {
        await this.flowProducer.add({
            name: 'report-item',
            queueName: 'report-items',
            data: item,
            opts: {
                attempts: 3,
                backoff: { type: 'exponential', delay: 1000 },
            },
        })
    }
}
```

### `src/modules/report/batch-processing/report.processor.ts`

```ts
import { Process, Processor } from '@nestjs/bull'
import { Job } from 'bullmq'
import { MbLogger } from '@montebravo.tech/mb-telemetry'
import { ReportItem } from './report-batch.service'

@Processor('report-items')
export class ReportProcessor {
    private readonly logger = new MbLogger(ReportProcessor.name)

    @Process('report-item')
    async processReportItem(job: Job<ReportItem>): Promise<void> {
        const { reportId, userId, startDate, endDate } = job.data

        this.logger.log(`Processing report item: ${reportId} for user ${userId}`)

        try {
            // Lógica de geração do relatório
            // 1. Buscar dados no período
            // 2. Processar/agregar dados
            // 3. Salvar resultado

            this.logger.log(`Report item ${reportId} processed successfully`)
        } catch (error) {
            this.logger.error(`Failed to process report item ${reportId}: ${error.message}`)
            throw error // BullMQ fará retry automático com backoff exponencial
        }
    }
}
```

### Registro no módulo pai

Após criar o batch processing, importá-lo no módulo de domínio:

```ts
// src/modules/report/report.module.ts
import { Module } from '@nestjs/common'
import { ReportController } from './report.controller'
import { ReportService } from './report.service'
import { ReportBatchModule } from './batch-processing/report-batch.module'

@Module({
    imports: [ReportBatchModule],
    controllers: [ReportController],
    providers: [ReportService],
    exports: [ReportService],
})
export class ReportModule {}
```

### Uso no service do domínio

```ts
// No report.service.ts
@Injectable()
export class ReportService {
    constructor(private readonly reportBatchService: ReportBatchService) {}

    async generateBatchReports(userIds: string[], period: { start: string; end: string }): Promise<void> {
        const items: ReportItem[] = userIds.map((userId) => ({
            reportId: randomUUID(),
            userId,
            startDate: period.start,
            endDate: period.end,
        }))

        await this.reportBatchService.enqueueBatch(items)
    }
}
```
