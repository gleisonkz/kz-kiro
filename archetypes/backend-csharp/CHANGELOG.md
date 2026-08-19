# Changelog

## 0.7.0 (2026-08-19)

### Funcionalidades

- Reescrever steering de governança de dados v2.0 com padrão ISO/IEC 11179
- Adicionar steering de desenvolvimento seguro com padrões de secrets, validação e headers
- Adicionar seção de gestão de secrets no agent security-reviewer
- Adicionar hook de validação de uso de secrets em tempo real
- Adicionar skill de geração de infraestrutura de AWS Secrets Manager

## 0.6.0 (2026-08-04)

### Funcionalidades

- Adicionar dimensão de review de changeset no config de agents

## 0.5.1 (2026-08-03)

### Refatoração

- Remover MediatR da stack e padronizar CQRS com Wolverine handlers

## 0.5.0 (2026-07-10)

### Funcionalidades

- Adicionar front-matter fileMatch nos steerings

### Documentação

- Atualizar versões mínimas da stack para 8+

## 0.4.0 (2026-07-08)

### Funcionalidades

- Adicionar sistema de code review automatizado via Kiro CLI

### Documentação

- Atualizar stack de mensageria com Kafka e MSK

## 0.3.0 (2026-06-19)

### Funcionalidades

- Documentar padrões de mensageria e Kafka conforme ADR-002
- Documentar padrões de autenticação e autorização conforme ADR 004

## 0.2.0 (2026-05-29)

### Funcionalidades

- Adicionar artefatos de governança de dados

### Refatoração

- Adequar artefatos ao padrão de governança de dados

## 0.1.0 (2026-05-28)

### Refatoração

- Migrar hooks para trigger agentStop com verificação condicional
