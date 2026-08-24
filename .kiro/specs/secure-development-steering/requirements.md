# Requirements Document

## Introduction

Este documento define os requisitos para a criação de artefatos de desenvolvimento seguro no archetype `backend-csharp` do mb-kiro. O objetivo é codificar as práticas do hub "Desenvolvimento Seguro" do Confluence da MonteBravo em artefatos Kiro (steering file, hook, skill e atualização de agent), permitindo que os desenvolvedores recebam orientação prescritiva e validação em tempo de escrita.

Os artefatos cobrem: gestão de secrets em runtime via AWS Secrets Manager, validação de input, headers de segurança, CORS, logging seguro, proteção de dados e consciência sobre dependências seguras (SCA como gate de pipeline gerido pelo time de segurança).

## Glossary

- **Steering_File**: arquivo markdown injetado automaticamente pelo Kiro como contexto em projetos, com regras prescritivas e padrões técnicos
- **Hook**: artefato Kiro que executa validações automáticas em eventos do IDE (pré-escrita, pós-escrita, pós-sessão)
- **Skill**: artefato Kiro que gera código boilerplate quando acionado manualmente pelo desenvolvedor
- **Agent**: artefato Kiro que realiza code review automatizado com foco em um domínio específico
- **Secrets_Manager**: serviço AWS Secrets Manager usado como vault centralizado para secrets da MonteBravo
- **IRSA**: IAM Roles for Service Accounts — mecanismo de identidade para pods EKS acessarem serviços AWS sem credenciais estáticas
- **VPC_Endpoint**: interface de rede privada que permite acesso ao Secrets Manager sem tráfego pela internet pública
- **SecretsManagerCache**: classe do pacote AWSSDK.SecretsManager.Caching que mantém cache em memória com TTL configurável
- **RdsAuthInterceptor**: interceptor de DbContext que detecta erros de autenticação (28P01/28000) e força refresh do secret em cache
- **Rotation_Aware**: capacidade de código reagir à rotação de secrets sem necessidade de redeploy
- **SCA**: Software Composition Analysis — análise automatizada de vulnerabilidades em dependências (operada pelo time de segurança via Snyk)
- **Archetype**: template de configuração Kiro específico para um tipo de projeto (backend-csharp, bff-fastify, etc.)

## Requirements

### Requirement 1: Steering File de Desenvolvimento Seguro

**User Story:** As a backend developer, I want a steering file that prescribes secure development practices, so that Kiro provides security guidance as context whenever I write code.

#### Acceptance Criteria

1. THE Steering_File SHALL be created at `archetypes/backend-csharp/steering/secure-development.md` with YAML frontmatter specifying `inclusion: fileMatch` and `fileMatchPattern: "**/*.cs,**/*.csproj,**/*.sln"`
2. WHEN the Steering_File is injected, THE Steering_File SHALL provide sections with enforceable rules, code examples, and tables covering secrets management, input validation, security headers, CORS configuration, secure logging, data protection, and dependency awareness
3. THE Steering_File SHALL define the mandatory pattern for secrets consumption: SecretsManagerCache as singleton in DI container, resolution by friendly name, in-memory caching with configurable TTL (default 3600 seconds, minimum 300 seconds, maximum 86400 seconds)
4. THE Steering_File SHALL define the mandatory RdsAuthInterceptor pattern for database credential rotation without redeploy, handling PostgreSQL error codes 28P01 and 28000
5. THE Steering_File SHALL explicitly prohibit hardcoded secrets in source code, Git history, environment variables, Kubernetes Secrets manifests, and appsettings.json files
6. THE Steering_File SHALL mandate IRSA as the identity mechanism for service-to-Secrets_Manager authentication with least privilege IAM policies
7. THE Steering_File SHALL mandate VPC_Endpoint for all Secrets_Manager traffic, ensuring zero public internet exposure
8. THE Steering_File SHALL prescribe secure logging rules: structured logging via Serilog, secret values excluded from log output, and only non-sensitive metadata (secret friendly name, rotation timestamp, access success or failure status) permitted in log entries related to secret operations
9. THE Steering_File SHALL prescribe security headers configuration: HSTS with max-age of at least 31536000 seconds and includeSubDomains enabled, X-Content-Type-Options set to nosniff, X-Frame-Options set to DENY, and restrictive CORS policies limited to explicitly listed origins
10. THE Steering_File SHALL prescribe input validation rules: FluentValidation on all Commands and Queries, maximum length of 2000 characters on string properties unless explicitly overridden, range validation on numeric fields requiring explicit minimum and maximum bounds per property, and whitelist approach over blacklist
11. THE Steering_File SHALL state that SCA scanning is operated by the security team via Snyk as a pipeline gate, providing contextual awareness without ownership responsibility for developers
12. THE Steering_File SHALL reference the Confluence hub page as authoritative source for policy updates, including the page URL in the References section of the file

### Requirement 2: Atualização do Security Reviewer Agent

**User Story:** As a tech lead, I want the security reviewer agent to validate secrets management patterns during code review, so that non-compliant secrets usage is caught before merge.

#### Acceptance Criteria

1. THE Agent SHALL include a dedicated "Secrets Management" section containing validation rules for each of the following patterns: SecretsManagerCache as singleton in DI, secret resolution by friendly name, RdsAuthInterceptor for database credentials, prohibition of hardcoded secrets, prohibition of secret exposure in logs or responses, and prohibition of environment variables for secret values
2. WHEN reviewing code that registers, injects, or reads from SecretsManagerCache, ISecretsManagerCache, or AWS Secrets Manager SDK classes, THE Agent SHALL validate that SecretsManagerCache is registered as singleton in the DI container
3. WHEN reviewing code that registers, injects, or reads from SecretsManagerCache, ISecretsManagerCache, or AWS Secrets Manager SDK classes, THE Agent SHALL validate that secrets are resolved by friendly name and not by full ARN
4. WHEN reviewing code that configures or instantiates a DbContext, THE Agent SHALL validate that the DbContext uses the RdsAuthInterceptor pattern for database credentials instead of static connection strings with embedded passwords
5. WHEN reviewing code that accesses secrets, THE Agent SHALL flag any static connection string containing credentials, any string literal matching secret patterns (passwords, API keys, tokens), or any hardcoded credential as a Critical severity finding
6. WHEN reviewing code that accesses secrets, THE Agent SHALL flag any occurrence of secret values being written to ILogger calls, included in API response objects, or concatenated into exception messages as a Critical severity finding
7. IF the Agent detects an environment variable (via Environment.GetEnvironmentVariable or IConfiguration binding to environment variables) being used for a value classified as a secret (database passwords, API keys, tokens, certificates, or connection strings containing credentials), THEN THE Agent SHALL flag it as High severity with a recommendation to migrate the value to AWS Secrets Manager using the SecretsManagerCache pattern

### Requirement 3: Hook de Validação de Secrets em Tempo de Escrita

**User Story:** As a developer, I want real-time validation when I write code that consumes secrets, so that I receive immediate feedback on pattern compliance without waiting for code review.

#### Acceptance Criteria

1. THE Hook SHALL be created at `archetypes/backend-csharp/hooks/review-secrets-usage.kiro.hook` with preToolUse event type targeting write operations
2. WHEN a write operation involves a C# file (`.cs`) that contains at least one of the following patterns: `AmazonSecretsManagerClient`, `SecretsManagerCache`, `Environment.GetEnvironmentVariable`, `arn:aws:secretsmanager:`, `ConnectionString`, `Password=`, `ApiKey`, `Secret`, or `Token` as string literals, THE Hook SHALL validate the file content against criteria 3 through 6
3. THE Hook SHALL detect and flag direct instantiation of `AmazonSecretsManagerClient` (via `new AmazonSecretsManagerClient`) instead of using the DI-registered `SecretsManagerCache`
4. THE Hook SHALL detect and flag string literals that match the Secrets Manager ARN prefix pattern (`arn:aws:secretsmanager:`)
5. THE Hook SHALL detect and flag string literals that resemble connection strings (containing keywords such as `Server=`, `Host=`, `Data Source=`, `Password=`, `User Id=`, `Database=`) or credential values assigned directly in source code rather than retrieved through configuration or Secrets Manager
6. THE Hook SHALL detect and flag usage of `Environment.GetEnvironmentVariable` where the variable name contains any of the following terms: `PASSWORD`, `SECRET`, `TOKEN`, `API_KEY`, `CONNECTION_STRING`, or `CREDENTIAL`
7. WHEN the Hook detects one or more violations of criteria 3 through 6, THE Hook SHALL list each violation with the offending code pattern and suggest the compliant alternative (DI-injected `SecretsManagerCache` or `IConfiguration`) before allowing the write operation
8. IF the file being written does not match any of the trigger patterns defined in criterion 2, THEN THE Hook SHALL allow the operation without commentary

### Requirement 4: Skill de Geração de Infraestrutura de Secrets

**User Story:** As a developer, I want to generate boilerplate code for Secrets Manager integration, so that I follow the organizational pattern without memorizing the implementation details.

#### Acceptance Criteria

1. THE Skill SHALL be created at `archetypes/backend-csharp/skills/generate-secrets-infrastructure.md` with manual inclusion mode
2. WHEN invoked, THE Skill SHALL generate a DI registration for SecretsManagerCache as singleton with a TTL parameter defaulting to 3600 seconds (valid range: 60 to 86400 seconds), including service interface, concrete implementation, and options binding from configuration
3. WHEN invoked, THE Skill SHALL generate a typed secret accessor class that resolves secrets by their Secrets Manager SecretId with deserialization into strongly-typed records
4. WHEN invoked with database context option, THE Skill SHALL generate the RdsAuthInterceptor implementation handling PostgreSQL error codes 28P01 and 28000 with automatic cache invalidation and a single retry attempt (maximum 1 retry per intercepted operation)
5. WHEN invoked with database context option, THE Skill SHALL generate a DbContext configuration that resolves credentials from the SecretsManagerCache on each new connection
6. THE Skill SHALL generate code that uses only the packages AWSSDK.SecretsManager and AWSSDK.SecretsManager.Caching as dependencies
7. THE Skill SHALL generate code with secure logging: operations log secret name, secret version ID, and request duration, but exclude secret values from all log output
8. THE Skill SHALL include inline XML documentation comments in pt-BR on every public class, public method, and public property of each generated component
9. IF secret resolution fails due to network error, access denied, or secret not found, THEN THE Skill SHALL generate code that throws a typed exception indicating the failure reason without exposing the secret value, and preserves the previous cached credential when available

### Requirement 5: Integração e Consistência entre Artefatos

**User Story:** As a tech lead, I want all secure development artifacts to be consistent and cross-referenced, so that developers receive a unified experience regardless of which artifact activates.

#### Acceptance Criteria

1. THE Steering_File SHALL contain a dedicated "Secrets Management" section defining the authoritative patterns for secrets consumption, including: prohibited patterns (hardcoded secrets, secrets in appsettings.json commitado), approved providers (AWS Secrets Manager, SSM Parameter Store, dotnet user-secrets for local development), and validation rules for detecting violations
2. THE Agent SHALL include in its "Exposição de Secrets" review criteria the same prohibited patterns and approved providers listed in the Steering_File "Secrets Management" section, referencing the Steering_File by its relative path within the archetype
3. THE Hook SHALL validate modified files against the prohibited patterns defined in the Steering_File "Secrets Management" section, triggering only on file types specified in the Steering_File's inclusion metadata (fileMatchPattern)
4. WHEN the Skill generates code that consumes secrets, THE Skill SHALL use exclusively the approved providers listed in the Steering_File "Secrets Management" section and SHALL NOT produce code containing any of the prohibited patterns defined in that section
5. WHEN patterns in the Steering_File "Secrets Management" section are updated, THE Agent, Hook, and Skill SHALL reference the Steering_File by relative path rather than duplicating pattern definitions, so that a single edit propagates to all artifacts without requiring individual updates
6. THE Steering_File SHALL include a versioning header in the format `Steering File | Archetype: {archetype-name} | Versão: X.Y.Z` within the first 5 lines of the file, where X.Y.Z follows semantic versioning (MAJOR for breaking changes, MINOR for new patterns, PATCH for corrections)
