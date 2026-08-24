# Implementation Plan

## Overview

Implementação dos artefatos de desenvolvimento seguro no archetype `backend-csharp` do mb-kiro: steering file holístico, atualização do security reviewer agent, hook de validação de secrets em tempo real, e skill de geração de boilerplate de Secrets Manager.

## Tasks

- [x] 1. Criar steering file `secure-development.md`
  - Criar arquivo `archetypes/backend-csharp/steering/secure-development.md` com frontmatter YAML (`inclusion: fileMatch`, `fileMatchPattern: "**/*.cs,**/*.csproj,**/*.sln"`)
  - Adicionar header com versão 1.0.0 no formato `Steering File | Archetype: backend-csharp | Versão: 1.0.0`
  - Criar seção Gestão de Secrets com padrões obrigatórios (SecretsManagerCache singleton, resolução por friendly name, TTL 3600s), padrões proibidos, IRSA, VPC Endpoint, e exemplos de código do RdsAuthInterceptor
  - Criar seção Validação de Input com FluentValidation, max 2000 chars, ranges numéricos
  - Criar seção Headers de Segurança com HSTS 31536000s, X-Content-Type-Options nosniff, X-Frame-Options DENY
  - Criar seção CORS com origens explícitas e anti-patterns
  - Criar seção Logging Seguro com Serilog, nunca logar secrets, metadata permitida
  - Criar seção Proteção de Dados com criptografia, decimal para dinheiro, PII
  - Criar seção Consciência de Dependências/SCA com Snyk operado pelo time de segurança
  - Criar seção Referências com link do Confluence hub
- [x] 2. Atualizar `security-reviewer.md` com seção de Gestão de Secrets
  - Adicionar seção "Gestão de Secrets (Política Corporativa)" dentro de "O que revisar"
  - Adicionar regra: validar SecretsManagerCache singleton (Critical)
  - Adicionar regra: resolução por friendly name não ARN (High)
  - Adicionar regra: RdsAuthInterceptor em DbContext (High)
  - Adicionar regra: flaggar connection strings hardcoded (Critical)
  - Adicionar regra: flaggar secrets em logs/responses/exceptions (Critical)
  - Adicionar regra: flaggar Environment.GetEnvironmentVariable para secrets (High com recomendação de migração)
  - Adicionar nota de referência ao steering file
- [x] 3. Criar hook `review-secrets-usage.kiro.hook`
  - Criar arquivo JSON em `archetypes/backend-csharp/hooks/review-secrets-usage.kiro.hook`
  - Configurar `enabled: true`, `name: "Revisar Uso de Secrets"`, `version: "1"`
  - Configurar `when.type: "preToolUse"` e `when.toolTypes: ["write"]`
  - Escrever prompt askAgent com lógica de validação para arquivos `.cs`
  - Incluir detecção de: instanciação direta de AmazonSecretsManagerClient, ARNs do Secrets Manager, connection strings hardcoded, Environment.GetEnvironmentVariable para secrets
  - Incluir instruções de permitir sem comentário quando não há patterns e listar violations com sugestões quando detectados
- [x] 4. Criar skill `generate-secrets-infrastructure.md`
  - Criar arquivo em `archetypes/backend-csharp/skills/generate-secrets-infrastructure.md` com frontmatter manual
  - Criar seção de inputs: nome do serviço, TTL, opção database, nome do secret
  - Criar regras de geração referenciando steering
  - Definir outputs: ISecretsProvider interface, SecretsManagerProvider com cache singleton, DI registration extension method
  - Definir outputs: Typed Secret Accessor, RdsAuthInterceptor condicional com tratamento 28P01/28000 e single retry
  - Definir outputs: DbContext config condicional com resolução dinâmica, exceções tipadas sem expor valores
  - Incluir XML docs em pt-BR e dependências limitadas a AWSSDK.SecretsManager e AWSSDK.SecretsManager.Caching
- [x] 5. Validar consistência cross-artefato e atualizar CHANGELOG
  - Validar prohibited patterns alinhados entre steering, hook e agent
  - Validar approved providers alinhados entre steering e skill
  - Validar fileMatchPattern cobrindo .cs
  - Validar JSON do hook parseable
  - Atualizar CHANGELOG.md com entrada documentando os 4 artefatos adicionados

## Task Dependency Graph

```json
{
  "waves": [
    {"tasks": ["1"]},
    {"tasks": ["2", "3", "4"]},
    {"tasks": ["5"]}
  ]
}
```

## Notes

- Task 1 é o hub central: todas as demais dependem dela pois agent, hook e skill referenciam o steering como fonte de verdade.
- Tasks 2, 3 e 4 podem ser executadas em paralelo após a conclusão da task 1.
- Task 5 é a validação final de consistência e fechamento do release.
- Snyk não é configurado por nós (responsabilidade do time de segurança); apenas mencionado como consciência contextual.
- O steering usa `fileMatch` amplo (`**/*.cs`) para que qualquer código C# receba contexto de segurança automaticamente.
