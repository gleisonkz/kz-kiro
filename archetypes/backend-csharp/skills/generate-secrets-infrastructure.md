---
name: "Gerar Infraestrutura de Secrets"
description: "Gera boilerplate para integração com AWS Secrets Manager: DI, typed accessor, RdsAuthInterceptor e DbContext rotation-aware."
inclusion: manual
---

# Gerar Infraestrutura de Secrets

## Quando usar

Quando o desenvolvedor precisar integrar um serviço com AWS Secrets Manager, gerando toda a infraestrutura de resolução, cache, tipagem e (opcionalmente) rotação de credenciais de banco de dados — seguindo os padrões obrigatórios de segurança da MonteBravo.

## Inputs esperados

- **Nome do serviço** (obrigatório): nome em PascalCase do serviço (ex.: `Transfers`, `Portfolio`). Usado para nomear classes e namespaces.
- **Nome do secret** (obrigatório): friendly name do secret no AWS Secrets Manager (ex.: `meu-servico/database-credentials`). Nunca usar ARN completo.
- **TTL do cache em segundos** (opcional, default: 3600): tempo de vida do cache em memória. Range válido: 60 a 86400 segundos.
- **Opção de database context** (opcional, default: false): se `true`, gera `RdsAuthInterceptor` e configuração de DbContext rotation-aware para PostgreSQL.

## Regras de geração

### Referências obrigatórias

- **Steering:** `../steering/secure-development.md` — padrões obrigatórios de gestão de secrets, logging seguro e RdsAuthInterceptor.

### Dependências de pacotes

Usar **exclusivamente** os seguintes pacotes NuGet:

| Pacote | Uso |
|---|---|
| `AWSSDK.SecretsManager` | SDK base para acesso ao Secrets Manager |
| `AWSSDK.SecretsManager.Caching` | Cache em memória com TTL configurável |

Nenhuma outra dependência de secrets deve ser adicionada.

### Regras obrigatórias

1. **SecretsManagerCache como singleton**: registrar uma única instância do cache no DI container.
2. **Resolução por friendly name**: nunca usar ARN completo para resolver secrets.
3. **TTL configurável**: o TTL deve ser lido de configuração (`appsettings.json` seção `SecretsManager`), com validação de range (60-86400s).
4. **XML documentation**: todo membro público (classe, método, propriedade) deve ter XML docs em pt-BR.
5. **Logging seguro**: logar apenas friendly name do secret, version ID e duração da operação. Nunca logar valores do secret.
6. **Exceções tipadas**: em caso de falha na resolução, lançar exceções tipadas que indicam a razão sem expor o valor do secret.
7. **Preservar cache anterior**: quando a resolução falhar, manter a credencial cacheada anteriormente (se disponível).
8. **Single retry no RdsAuthInterceptor**: ao detectar erro de autenticação (28P01/28000), invalidar cache e tentar uma única vez. Se o retry falhar, propagar a exceção.
9. **Condicionalidade**: componentes de banco (`RdsAuthInterceptor`, DbContext config) são gerados apenas se `database = true`.

## Outputs gerados

### 1. Interface `ISecretsProvider`

Localização: `src/{ServiceName}.Domain/Abstractions/ISecretsProvider.cs`

```csharp
namespace {ServiceName}.Domain.Abstractions;

/// <summary>
/// Abstração para resolução de secrets gerenciados.
/// </summary>
public interface ISecretsProvider
{
    /// <summary>
    /// Resolve o valor de um secret pelo seu friendly name.
    /// </summary>
    /// <param name="secretId">Friendly name do secret no AWS Secrets Manager.</param>
    /// <param name="cancellationToken">Token de cancelamento.</param>
    /// <returns>Valor do secret como string JSON.</returns>
    /// <exception cref="SecretResolutionException">Quando a resolução falha por erro de rede ou secret não encontrado.</exception>
    /// <exception cref="SecretAccessDeniedException">Quando o acesso ao secret é negado.</exception>
    Task<string> GetSecretAsync(string secretId, CancellationToken cancellationToken = default);
}
```

### 2. `SecretsManagerProvider`

Localização: `src/{ServiceName}.Infrastructure/Security/SecretsManagerProvider.cs`

```csharp
using System.Diagnostics;
using Amazon.SecretsManager.Extensions.Caching;
using Microsoft.Extensions.Logging;
using {ServiceName}.Domain.Abstractions;

namespace {ServiceName}.Infrastructure.Security;

/// <summary>
/// Implementação de <see cref="ISecretsProvider"/> utilizando AWS Secrets Manager com cache singleton.
/// </summary>
public sealed class SecretsManagerProvider : ISecretsProvider
{
    private readonly SecretsManagerCache _cache;
    private readonly ILogger<SecretsManagerProvider> _logger;

    /// <summary>
    /// Inicializa o provider com o cache singleton e logger.
    /// </summary>
    /// <param name="cache">Instância singleton do cache de secrets.</param>
    /// <param name="logger">Logger para registro de operações.</param>
    public SecretsManagerProvider(
        SecretsManagerCache cache,
        ILogger<SecretsManagerProvider> logger)
    {
        _cache = cache;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<string> GetSecretAsync(string secretId, CancellationToken cancellationToken = default)
    {
        var stopwatch = Stopwatch.StartNew();

        try
        {
            var result = await _cache.GetSecretString(secretId);
            stopwatch.Stop();

            _logger.LogInformation(
                "Secret {SecretName} resolvido com sucesso. Duração: {DurationMs}ms",
                secretId,
                stopwatch.ElapsedMilliseconds);

            return result;
        }
        catch (Amazon.SecretsManager.Model.ResourceNotFoundException ex)
        {
            stopwatch.Stop();
            _logger.LogError(
                "Secret {SecretName} não encontrado. Duração: {DurationMs}ms",
                secretId,
                stopwatch.ElapsedMilliseconds);

            throw new SecretResolutionException(secretId, "Secret não encontrado no Secrets Manager.", ex);
        }
        catch (Amazon.SecretsManager.Model.AccessDeniedException ex)
        {
            stopwatch.Stop();
            _logger.LogError(
                "Acesso negado ao secret {SecretName}. Duração: {DurationMs}ms",
                secretId,
                stopwatch.ElapsedMilliseconds);

            throw new SecretAccessDeniedException(secretId, ex);
        }
        catch (Exception ex) when (ex is not SecretResolutionException and not SecretAccessDeniedException)
        {
            stopwatch.Stop();
            _logger.LogError(
                "Falha ao resolver secret {SecretName}. Motivo: {ErrorType}. Duração: {DurationMs}ms",
                secretId,
                ex.GetType().Name,
                stopwatch.ElapsedMilliseconds);

            throw new SecretResolutionException(secretId, "Falha na resolução do secret.", ex);
        }
    }
}
```

### 3. DI Registration Extension Method

Localização: `src/{ServiceName}.Infrastructure/DependencyInjection/SecretsManagerExtensions.cs`

```csharp
using Amazon.SecretsManager.Extensions.Caching;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using {ServiceName}.Domain.Abstractions;
using {ServiceName}.Infrastructure.Security;

namespace {ServiceName}.Infrastructure.DependencyInjection;

/// <summary>
/// Extensões para registro da infraestrutura de Secrets Manager no container de DI.
/// </summary>
public static class SecretsManagerExtensions
{
    /// <summary>
    /// Registra o SecretsManagerCache como singleton e o provider de secrets no container de DI.
    /// </summary>
    /// <param name="services">Coleção de serviços do DI.</param>
    /// <param name="configuration">Configuração da aplicação.</param>
    /// <returns>A coleção de serviços para encadeamento.</returns>
    /// <exception cref="ArgumentOutOfRangeException">Quando o TTL está fora do range permitido (60-86400 segundos).</exception>
    public static IServiceCollection AddSecretsManager(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var options = configuration
            .GetSection("SecretsManager")
            .Get<SecretsManagerOptions>()
            ?? new SecretsManagerOptions();

        if (options.CacheTtlSeconds < 60 || options.CacheTtlSeconds > 86400)
        {
            throw new ArgumentOutOfRangeException(
                nameof(options.CacheTtlSeconds),
                options.CacheTtlSeconds,
                "TTL do cache deve estar entre 60 e 86400 segundos.");
        }

        var cacheConfig = new SecretCacheConfiguration
        {
            CacheItemTTL = (uint)options.CacheTtlSeconds
        };

        var cache = new SecretsManagerCache(cacheConfig);

        services.AddSingleton(cache);
        services.AddSingleton<ISecretsProvider, SecretsManagerProvider>();

        return services;
    }
}
```

### 4. Exceções Tipadas

Localização: `src/{ServiceName}.Infrastructure/Security/Exceptions/`

```csharp
// SecretResolutionException.cs
namespace {ServiceName}.Infrastructure.Security.Exceptions;

/// <summary>
/// Exceção lançada quando a resolução de um secret falha por erro de rede ou secret não encontrado.
/// Não expõe o valor do secret na mensagem.
/// </summary>
public sealed class SecretResolutionException : Exception
{
    /// <summary>
    /// Friendly name do secret que falhou na resolução.
    /// </summary>
    public string SecretId { get; }

    /// <summary>
    /// Inicializa a exceção com o identificador do secret e a razão da falha.
    /// </summary>
    /// <param name="secretId">Friendly name do secret.</param>
    /// <param name="reason">Motivo da falha (sem expor valor do secret).</param>
    /// <param name="innerException">Exceção original.</param>
    public SecretResolutionException(string secretId, string reason, Exception? innerException = null)
        : base($"Falha ao resolver secret '{secretId}': {reason}", innerException)
    {
        SecretId = secretId;
    }
}
```

```csharp
// SecretAccessDeniedException.cs
namespace {ServiceName}.Infrastructure.Security.Exceptions;

/// <summary>
/// Exceção lançada quando o acesso a um secret é negado pela política IAM.
/// Não expõe o valor do secret na mensagem.
/// </summary>
public sealed class SecretAccessDeniedException : Exception
{
    /// <summary>
    /// Friendly name do secret cujo acesso foi negado.
    /// </summary>
    public string SecretId { get; }

    /// <summary>
    /// Inicializa a exceção com o identificador do secret.
    /// </summary>
    /// <param name="secretId">Friendly name do secret.</param>
    /// <param name="innerException">Exceção original.</param>
    public SecretAccessDeniedException(string secretId, Exception? innerException = null)
        : base($"Acesso negado ao secret '{secretId}'. Verifique a política IAM do serviço.", innerException)
    {
        SecretId = secretId;
    }
}
```

### 5. Options class

Localização: `src/{ServiceName}.Infrastructure/Security/SecretsManagerOptions.cs`

```csharp
namespace {ServiceName}.Infrastructure.Security;

/// <summary>
/// Opções de configuração para o cache do Secrets Manager.
/// </summary>
public sealed class SecretsManagerOptions
{
    /// <summary>
    /// Seção de configuração no appsettings.json.
    /// </summary>
    public const string SectionName = "SecretsManager";

    /// <summary>
    /// TTL do cache em segundos. Padrão: 3600. Range válido: 60-86400.
    /// </summary>
    public int CacheTtlSeconds { get; set; } = 3600;
}
```

### 6. Typed Secret Accessor

Localização: `src/{ServiceName}.Infrastructure/Security/{SecretName}Accessor.cs`

```csharp
using System.Text.Json;
using Microsoft.Extensions.Logging;
using {ServiceName}.Domain.Abstractions;

namespace {ServiceName}.Infrastructure.Security;

/// <summary>
/// Accessor tipado para desserialização do secret '{SecretFriendlyName}'.
/// Resolve o secret por friendly name e retorna um record fortemente tipado.
/// </summary>
public sealed class {SecretName}Accessor
{
    private readonly ISecretsProvider _provider;
    private readonly ILogger<{SecretName}Accessor> _logger;
    private readonly string _secretId;
    private {SecretName}Secret? _cachedSecret;

    /// <summary>
    /// Inicializa o accessor com o provider de secrets e o friendly name.
    /// </summary>
    /// <param name="provider">Provider de secrets.</param>
    /// <param name="logger">Logger para registro de operações.</param>
    /// <param name="secretId">Friendly name do secret no Secrets Manager.</param>
    public {SecretName}Accessor(
        ISecretsProvider provider,
        ILogger<{SecretName}Accessor> logger,
        string secretId)
    {
        _provider = provider;
        _logger = logger;
        _secretId = secretId;
    }

    /// <summary>
    /// Resolve e desserializa o secret em um record tipado.
    /// Em caso de falha, preserva o valor cacheado anteriormente se disponível.
    /// </summary>
    /// <param name="cancellationToken">Token de cancelamento.</param>
    /// <returns>Record tipado com os valores do secret.</returns>
    public async Task<{SecretName}Secret> GetSecretAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var json = await _provider.GetSecretAsync(_secretId, cancellationToken);
            var secret = JsonSerializer.Deserialize<{SecretName}Secret>(json)
                ?? throw new SecretResolutionException(_secretId, "Desserialização retornou null.");

            _cachedSecret = secret;
            return secret;
        }
        catch (Exception ex) when (_cachedSecret is not null
            && ex is SecretResolutionException or SecretAccessDeniedException)
        {
            _logger.LogWarning(
                "Falha ao resolver secret {SecretName}. Usando valor cacheado anteriormente. Motivo: {ErrorType}",
                _secretId,
                ex.GetType().Name);

            return _cachedSecret;
        }
    }
}

/// <summary>
/// Record que representa a estrutura do secret '{SecretFriendlyName}'.
/// Adapte as propriedades conforme o JSON do secret no Secrets Manager.
/// </summary>
public sealed record {SecretName}Secret
{
    /// <summary>
    /// Nome de usuário para autenticação.
    /// </summary>
    public required string Username { get; init; }

    /// <summary>
    /// Senha para autenticação.
    /// </summary>
    public required string Password { get; init; }

    // Adicione outras propriedades conforme o JSON do secret.
}
```

### 7. `RdsAuthInterceptor` (condicional: database = true)

Localização: `src/{ServiceName}.Infrastructure/Persistence/RdsAuthInterceptor.cs`

> Gerado apenas quando o input `database` = `true`.

```csharp
using System.Text.Json;
using Amazon.SecretsManager.Extensions.Caching;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace {ServiceName}.Infrastructure.Persistence;

/// <summary>
/// Interceptor de conexão que gerencia rotação de credenciais do banco de dados via AWS Secrets Manager.
/// Ao detectar erro de autenticação PostgreSQL (28P01 ou 28000), invalida o cache e tenta um único retry.
/// </summary>
public sealed class RdsAuthInterceptor : DbConnectionInterceptor
{
    private readonly SecretsManagerCache _cache;
    private readonly string _secretId;
    private readonly ILogger<RdsAuthInterceptor> _logger;
    private bool _isRetrying;

    /// <summary>
    /// Inicializa o interceptor com o cache de secrets e o friendly name do secret de credenciais.
    /// </summary>
    /// <param name="cache">Instância singleton do cache de secrets.</param>
    /// <param name="secretId">Friendly name do secret de credenciais do banco.</param>
    /// <param name="logger">Logger para registro de operações.</param>
    public RdsAuthInterceptor(
        SecretsManagerCache cache,
        string secretId,
        ILogger<RdsAuthInterceptor> logger)
    {
        _cache = cache;
        _secretId = secretId;
        _logger = logger;
    }

    /// <inheritdoc />
    public override async ValueTask<InterceptionResult> ConnectionOpeningAsync(
        DbConnection connection,
        ConnectionEventData eventData,
        InterceptionResult result,
        CancellationToken cancellationToken = default)
    {
        await RefreshConnectionString(connection, cancellationToken);
        return result;
    }

    /// <inheritdoc />
    public override async Task ConnectionFailedAsync(
        DbConnection connection,
        ConnectionErrorEventData eventData,
        CancellationToken cancellationToken = default)
    {
        if (_isRetrying)
            return;

        if (eventData.Exception is PostgresException pgEx
            && pgEx.SqlState is "28P01" or "28000")
        {
            _logger.LogWarning(
                "Falha de autenticação no banco (SqlState: {SqlState}). Invalidando cache do secret {SecretName}.",
                pgEx.SqlState,
                _secretId);

            _isRetrying = true;

            try
            {
                // Invalida cache e tenta refresh uma única vez
                await _cache.RefreshNowAsync(_secretId);
                await RefreshConnectionString(connection, cancellationToken);
            }
            finally
            {
                _isRetrying = false;
            }
        }
    }

    private async Task RefreshConnectionString(
        DbConnection connection,
        CancellationToken cancellationToken)
    {
        var secretJson = await _cache.GetSecretString(_secretId);
        var credentials = JsonSerializer.Deserialize<DatabaseCredentials>(secretJson);

        if (credentials is null)
        {
            _logger.LogError("Falha ao desserializar credenciais do secret {SecretName}.", _secretId);
            throw new SecretResolutionException(_secretId, "Desserialização de credenciais retornou null.");
        }

        var builder = new NpgsqlConnectionStringBuilder(connection.ConnectionString)
        {
            Password = credentials.Password,
            Username = credentials.Username
        };

        connection.ConnectionString = builder.ConnectionString;
    }
}

/// <summary>
/// Representa as credenciais do banco de dados armazenadas no Secrets Manager.
/// </summary>
internal sealed record DatabaseCredentials
{
    /// <summary>
    /// Nome de usuário do banco de dados.
    /// </summary>
    public required string Username { get; init; }

    /// <summary>
    /// Senha do banco de dados.
    /// </summary>
    public required string Password { get; init; }
}
```

### 8. DbContext Configuration (condicional: database = true)

Localização: `src/{ServiceName}.Infrastructure/Persistence/{ServiceName}DbContextFactory.cs`

> Gerado apenas quando o input `database` = `true`.

```csharp
using Amazon.SecretsManager.Extensions.Caching;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace {ServiceName}.Infrastructure.Persistence;

/// <summary>
/// Extensões para configuração do DbContext com resolução dinâmica de credenciais via Secrets Manager.
/// A connection string é atualizada a cada nova conexão, suportando rotação transparente.
/// </summary>
public static class DbContextExtensions
{
    /// <summary>
    /// Registra o DbContext com interceptor de rotação de credenciais.
    /// </summary>
    /// <param name="services">Coleção de serviços do DI.</param>
    /// <param name="configuration">Configuração da aplicação.</param>
    /// <param name="secretId">Friendly name do secret de credenciais do banco.</param>
    /// <returns>A coleção de serviços para encadeamento.</returns>
    public static IServiceCollection AddRotationAwareDbContext<TContext>(
        this IServiceCollection services,
        IConfiguration configuration,
        string secretId)
        where TContext : DbContext
    {
        services.AddDbContext<TContext>((serviceProvider, options) =>
        {
            var connectionString = configuration.GetConnectionString("Default")
                ?? throw new InvalidOperationException("Connection string 'Default' não configurada.");

            var cache = serviceProvider.GetRequiredService<SecretsManagerCache>();
            var logger = serviceProvider.GetRequiredService<ILogger<RdsAuthInterceptor>>();

            var interceptor = new RdsAuthInterceptor(cache, secretId, logger);

            options.UseNpgsql(connectionString)
                   .AddInterceptors(interceptor);
        });

        return services;
    }
}
```

## Configuração esperada no appsettings.json

```json
{
  "SecretsManager": {
    "CacheTtlSeconds": 3600
  },
  "ConnectionStrings": {
    "Default": "Host=meu-rds.cluster-xyz.us-east-1.rds.amazonaws.com;Database=meu_banco;Port=5432"
  }
}
```

> **Nota**: A connection string base não deve conter `Password=` ou `Username=`. Essas credenciais são resolvidas dinamicamente pelo `RdsAuthInterceptor`.

## Checklist pós-geração

Após gerar a infraestrutura, verificar:

- [ ] `SecretsManagerCache` registrado como singleton
- [ ] Resolução de secrets apenas por friendly name (nunca ARN)
- [ ] TTL dentro do range 60-86400 segundos
- [ ] XML docs em pt-BR em toda classe, método e propriedade pública
- [ ] Logging seguro: apenas nome, versão e duração logados
- [ ] Valores de secrets nunca expostos em logs, exceptions ou responses
- [ ] Exceções tipadas (`SecretResolutionException`, `SecretAccessDeniedException`) sem valores sensíveis
- [ ] Cache anterior preservado quando resolução falha
- [ ] Dependências limitadas a `AWSSDK.SecretsManager` e `AWSSDK.SecretsManager.Caching`
- [ ] (Se database=true) `RdsAuthInterceptor` trata 28P01 e 28000 com single retry
- [ ] (Se database=true) DbContext com resolução dinâmica de credenciais
- [ ] Referência ao steering `../steering/secure-development.md` respeitada
