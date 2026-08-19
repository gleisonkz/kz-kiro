---
inclusion: fileMatch
fileMatchPattern: "**/*.cs,**/*.csproj,**/*.sln"
---

# Desenvolvimento Seguro — Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 1.0.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos de serviços de domínio .NET/C#.
> Ele define os padrões obrigatórios de segurança exigidos pela MonteBravo.
>
> Baseado em: [Desenvolvimento Seguro (Confluence)](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/desenvolvimento-seguro)

---

## Gestão de Secrets

### Padrões Obrigatórios

| Padrão | Regra | Detalhe |
|---|---|---|
| Provider aprovado | AWS Secrets Manager | Via `SecretsManagerCache` do SDK |
| Registro no DI | **Singleton** | Uma única instância do cache por processo |
| Resolução | Por **friendly name** | Nunca por ARN completo |
| TTL do cache | Default **3600s** | Mínimo 300s, máximo 86400s |
| Identidade | **IRSA** (IAM Roles for Service Accounts) | Pods EKS autenticam sem credenciais estáticas |
| Rede | **VPC Endpoint** | Todo tráfego ao Secrets Manager via rede privada — zero internet pública |

#### Providers Aprovados

| Provider | Uso |
|---|---|
| AWS Secrets Manager | Secrets de produção (senhas, tokens, chaves API, connection strings) |
| SSM Parameter Store | Parâmetros de configuração não-sensíveis ou semi-sensíveis |
| dotnet user-secrets | Apenas desenvolvimento local — nunca em ambientes remotos |

#### Registro do SecretsManagerCache (Singleton)

```csharp
// Infrastructure/DependencyInjection/SecretsManagerExtensions.cs
public static class SecretsManagerExtensions
{
    public static IServiceCollection AddSecretsManager(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var options = configuration
            .GetSection("SecretsManager")
            .Get<SecretsManagerOptions>()
            ?? new SecretsManagerOptions();

        var cacheConfig = new SecretCacheConfiguration
        {
            CacheItemTTL = (uint)options.CacheTtlSeconds // default: 3600
        };

        var cache = new SecretsManagerCache(cacheConfig);

        services.AddSingleton<ISecretsManagerCache>(cache);
        services.AddSingleton<ISecretsProvider, SecretsManagerProvider>();

        return services;
    }
}
```

#### Resolução por Friendly Name

```csharp
// Correto: resolução por friendly name
var secretValue = await _cache.GetSecretString("meu-servico/database-credentials");

// PROIBIDO: resolução por ARN completo
var secretValue = await _cache.GetSecretString("arn:aws:secretsmanager:us-east-1:123456789:secret:meu-servico/database-credentials-AbCdEf");
```

### Padrões Proibidos

| Padrão Proibido | Severidade | Motivo |
|---|---|---|
| Secrets hardcoded no código-fonte | **Critical** | Exposição em repositório e histórico Git |
| Secrets em `appsettings.json` commitado | **Critical** | Arquivo versionado; secret exposto no Git |
| Secrets em variáveis de ambiente (`Environment.GetEnvironmentVariable`) | **High** | Visível em process dumps, logs de infra, dashboards de orquestração |
| Secrets em Kubernetes Secrets manifests (YAML) | **Critical** | Base64 não é criptografia; manifest versionado no Git |
| Secrets no histórico do Git | **Critical** | Mesmo após remoção do HEAD, persiste em commits anteriores |
| Instanciação direta de `AmazonSecretsManagerClient` (`new AmazonSecretsManagerClient()`) | **High** | Deve usar DI com `SecretsManagerCache` singleton |

### RdsAuthInterceptor — Rotação de Credenciais de Banco

O `RdsAuthInterceptor` permite que o serviço reaja à rotação de secrets do banco de dados sem necessidade de redeploy. Ele intercepta erros de autenticação do PostgreSQL e força refresh do cache.

```csharp
// Infrastructure/Persistence/RdsAuthInterceptor.cs
public class RdsAuthInterceptor : DbConnectionInterceptor
{
    private readonly ISecretsManagerCache _cache;
    private readonly string _secretId;
    private readonly ILogger<RdsAuthInterceptor> _logger;

    public RdsAuthInterceptor(
        ISecretsManagerCache cache,
        string secretId,
        ILogger<RdsAuthInterceptor> logger)
    {
        _cache = cache;
        _secretId = secretId;
        _logger = logger;
    }

    public override async ValueTask<InterceptionResult> ConnectionOpeningAsync(
        DbConnection connection,
        ConnectionEventData eventData,
        InterceptionResult result,
        CancellationToken cancellationToken = default)
    {
        await RefreshConnectionString(connection, cancellationToken);
        return result;
    }

    public override async Task ConnectionFailedAsync(
        DbConnection connection,
        ConnectionErrorEventData eventData,
        CancellationToken cancellationToken = default)
    {
        // PostgreSQL error codes para autenticação falha
        if (eventData.Exception is PostgresException pgEx
            && pgEx.SqlState is "28P01" or "28000")
        {
            _logger.LogWarning(
                "Falha de autenticação no banco (SqlState: {SqlState}). Invalidando cache do secret {SecretName}.",
                pgEx.SqlState,
                _secretId);

            // Invalida cache e tenta refresh uma única vez
            _cache.RefreshNowAsync(_secretId).GetAwaiter().GetResult();
            await RefreshConnectionString(connection, cancellationToken);
        }
    }

    private async Task RefreshConnectionString(
        DbConnection connection,
        CancellationToken cancellationToken)
    {
        var secretJson = await _cache.GetSecretString(_secretId);
        var credentials = JsonSerializer.Deserialize<DatabaseCredentials>(secretJson);

        var builder = new NpgsqlConnectionStringBuilder(connection.ConnectionString)
        {
            Password = credentials!.Password,
            Username = credentials.Username
        };

        connection.ConnectionString = builder.ConnectionString;
    }
}
```

**Regras do RdsAuthInterceptor**:
- Trata error codes `28P01` (password authentication failed) e `28000` (invalid authorization specification)
- Executa no máximo **1 retry** por operação interceptada
- Invalida o cache antes do retry via `RefreshNowAsync`
- Loga apenas o friendly name do secret e o SqlState — nunca o valor do secret

### IRSA — Autenticação de Serviço

- Pods EKS usam **IRSA** para assumir IAM Role sem credenciais estáticas
- A IAM Policy deve seguir **least privilege**: apenas `secretsmanager:GetSecretValue` e `secretsmanager:DescribeSecret` nos secrets específicos do serviço
- Não é aceito uso de access keys estáticas (AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY) em nenhum ambiente

### VPC Endpoint

- Todo acesso ao Secrets Manager deve passar por **VPC Endpoint** (interface endpoint `com.amazonaws.{region}.secretsmanager`)
- Tráfego ao Secrets Manager pela internet pública é proibido
- Security Groups do endpoint devem permitir apenas tráfego das subnets do serviço

---

## Validação de Input

### Regras Obrigatórias

| Regra | Detalhe |
|---|---|
| Framework | **FluentValidation** em todos os Commands e Queries |
| Max length (strings) | **2000 caracteres** por padrão (exceto quando explicitamente overridden com justificativa) |
| Ranges numéricos | Todo campo numérico deve ter **mínimo e máximo explícitos** |
| Abordagem | **Whitelist** (permitir explicitamente) sobre blacklist (proibir) |

### Exemplo de Validator

```csharp
public class CreateTransferCommandValidator : AbstractValidator<CreateTransferCommand>
{
    public CreateTransferCommandValidator()
    {
        RuleFor(x => x.Description)
            .MaximumLength(2000)
            .WithMessage("Descrição deve ter no máximo 2000 caracteres.");

        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .LessThanOrEqualTo(10_000_000)
            .WithMessage("Valor deve estar entre 0,01 e 10.000.000.");

        RuleFor(x => x.SourceAccountId)
            .NotEmpty()
            .WithMessage("Conta de origem é obrigatória.");
    }
}
```

### Anti-Patterns de Validação

- **Não** confiar apenas na validação do frontend
- **Não** usar blacklist de caracteres (ex: bloquear `<script>`)
- **Não** deixar campos string sem limite de tamanho
- **Não** aceitar tipos numéricos sem range explícito

---

## Headers de Segurança

### Configuração Obrigatória

| Header | Valor | Propósito |
|---|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Força HTTPS por 1 ano em todos os subdomínios |
| `X-Content-Type-Options` | `nosniff` | Impede MIME-type sniffing |
| `X-Frame-Options` | `DENY` | Bloqueia embedding em iframes (proteção contra clickjacking) |

### Configuração no ASP.NET

```csharp
// Program.cs ou SecurityHeadersMiddleware
app.UseHsts(); // Configura Strict-Transport-Security

app.Use(async (context, next) =>
{
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Append("X-Frame-Options", "DENY");
    await next();
});
```

---

## Configuração de CORS

### Regras Obrigatórias

| Regra | Detalhe |
|---|---|
| Origens | Devem ser **explicitamente listadas** — nunca usar wildcard `*` com credentials |
| Métodos | Apenas os métodos necessários para a API |
| Headers | Apenas os headers customizados utilizados |
| Credentials | Só habilitar `AllowCredentials()` com origens explícitas |

### Exemplo Correto

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("Production", policy =>
    {
        policy
            .WithOrigins(
                "https://app.montebravo.com.br",
                "https://portal.montebravo.com.br")
            .WithMethods("GET", "POST", "PUT", "DELETE")
            .WithHeaders("Authorization", "Content-Type")
            .AllowCredentials();
    });
});
```

### Anti-Patterns de CORS

| Anti-Pattern | Risco |
|---|---|
| `AllowAnyOrigin()` com `AllowCredentials()` | Browsers rejeitam; possibilita CSRF em configs futuras |
| `AllowAnyOrigin()` em produção | Permite qualquer domínio acessar a API |
| `SetIsOriginAllowed(_ => true)` | Equivale a wildcard; bypassa validação |
| Origens `http://` (sem TLS) em produção | Tráfego exposto a interceptação |

---

## Logging Seguro

### Regras Obrigatórias

| Regra | Detalhe |
|---|---|
| Framework | **Serilog** (structured logging) |
| Secrets em logs | **NUNCA** logar valores de secrets, tokens, senhas ou connection strings |
| Metadata permitida | Friendly name do secret, timestamp de rotação, status de acesso (sucesso/falha) |
| PII em logs | Não logar dados pessoais sem mascaramento |

### O que PODE ser logado

```csharp
_logger.LogInformation(
    "Secret {SecretName} resolvido com sucesso. Versão: {VersionId}. Duração: {DurationMs}ms",
    secretFriendlyName,
    versionId,
    elapsed.TotalMilliseconds);

_logger.LogWarning(
    "Falha ao resolver secret {SecretName}. Motivo: {ErrorType}",
    secretFriendlyName,
    exception.GetType().Name);
```

### O que NUNCA pode ser logado

```csharp
// PROIBIDO: logar valor do secret
_logger.LogDebug("Secret value: {SecretValue}", secretValue);

// PROIBIDO: logar connection string completa
_logger.LogInformation("Conectando em {ConnectionString}", connectionString);

// PROIBIDO: incluir secret em mensagem de exception
throw new Exception($"Falha com password: {password}");
```

### Configuração Recomendada do Serilog

```csharp
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithEnvironmentName()
    .Destructure.ByTransforming<DatabaseCredentials>(
        dc => new { dc.Username, Password = "***REDACTED***" })
    .WriteTo.Console(new RenderedCompactJsonFormatter())
    .CreateLogger();
```

---

## Proteção de Dados

### Criptografia

| Contexto | Requisito |
|---|---|
| Em trânsito | TLS 1.2+ obrigatório para todas as comunicações |
| Em repouso | Criptografia habilitada em todos os stores (RDS, S3, DynamoDB) |
| Chaves | Gerenciadas via AWS KMS — nunca hardcoded |

### Valores Monetários

| Contexto | Tipo | Precisão |
|---|---|---|
| Código C# | `decimal` | Nunca `float` ou `double` |
| Banco de dados | `DECIMAL(18, 8)` | `HasPrecision(18, 8)` |

**Regra absoluta**: Nunca usar `float` ou `double` para valores monetários. Vide [Governança de Dados](./data-governance.md) para detalhes.

### Dados Pessoais (PII)

| Regra | Detalhe |
|---|---|
| Minimização | Coletar apenas dados estritamente necessários |
| Mascaramento | PII em logs deve ser mascarado (ex: CPF `***.***.***-XX`) |
| Retenção | Definir TTL de retenção conforme LGPD |
| Acesso | Restringir acesso a PII por IAM e application-level authorization |
| Criptografia | Campos sensíveis (CPF, email, telefone) devem ser criptografados em repouso quando possível |

---

## Consciência de Dependências (SCA)

### Modelo Operacional

| Aspecto | Detalhe |
|---|---|
| Ferramenta | **Snyk** |
| Operação | Time de Segurança (não é responsabilidade do time de desenvolvimento) |
| Integração | Gate de pipeline — PRs com vulnerabilidades críticas são bloqueados |
| Responsabilidade do dev | Manter dependências atualizadas e responder a findings reportados |

### Boas Práticas para Desenvolvedores

- Manter pacotes NuGet atualizados com versões estáveis
- Evitar pacotes abandonados ou com baixa manutenção
- Preferir pacotes oficiais (Microsoft, AWS SDK) sobre alternativas de terceiros quando equivalentes
- Não ignorar warnings do `dotnet list package --vulnerable`
- Responder prontamente a tickets de segurança gerados pelo Snyk

---

## Referências

- [Desenvolvimento Seguro - Confluence Hub](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/desenvolvimento-seguro)
- [OWASP Top 10:2021](https://owasp.org/Top10/)
- [AWS Secrets Manager Caching - NuGet](https://www.nuget.org/packages/AWSSDK.SecretsManager.Caching)
- [FluentValidation Documentation](https://docs.fluentvalidation.net/)
- [Serilog - Structured Logging](https://serilog.net/)
- Steering relacionado: [Governança de Dados](./data-governance.md)

---

*Versão: 1.0.0 | Última revisão: 2025-01 | Próxima revisão: TODO*
