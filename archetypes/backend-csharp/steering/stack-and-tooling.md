---
inclusion: fileMatch
fileMatchPattern: "**/*.cs,**/*.csproj,**/*.sln"
---

# Stack Base e Ferramental — Backend C#

> **Steering File | Archetype: backend-csharp | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos de serviços de domínio .NET/C#.
> Ele define a stack base de tecnologias, ferramental e configuração do projeto.
>
> Baseado em: RFC-002 (Padrão Steering File para backend), ADR-001 (Comunicação), RFC-003 (Outbox/Inbox)

---

## Stack Base Obrigatória

| Tecnologia | Versão/Modo | Finalidade |
|---|---|---|
| .NET | 8+ LTS | Runtime e SDK |
| C# | 12 | Linguagem (nullable reference types enabled) |
| ASP.NET Core | 8+ | Framework web |
| Entity Framework Core | 8+ | ORM, migrations, DbContext |
| PostgreSQL | latest | Banco de dados (Database per Service) |
| FluentValidation | latest | Validação de commands e queries |
| Wolverine | latest | Outbox/Inbox, messaging, transações distribuídas |
| Serilog | latest | Logging estruturado (JSON) |
| Serilog.AspNetCore | latest | Integração com ASP.NET Core |
| AWS CloudWatch | - | Destino de logs |
| AWS X-Ray | - | Distributed tracing |
| Swashbuckle.AspNetCore | latest | Documentação OpenAPI/Swagger |
| Confluent.Kafka | latest | Client Kafka para producers e consumers (.NET) |
| Polly | latest | Resiliência (retry, circuit breaker, timeout) |
| xUnit | latest | Framework de testes |
| Moq | latest | Mocking |
| FluentAssertions | latest | Assertions expressivas (opcional) |
| Testcontainers | latest | Testes de integração com containers |
| Docker | latest | Containerização |

---

## Infraestrutura AWS (RFC-002)

### Serviços preferidos

<!-- Baseado em ADR: ADR-001 – Padrão arquitetural de comunicação | Confluence: https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517 -->
<!-- Baseado em ADR: ADR-002 – Padronização de Mensageria, Schemas e Nomenclatura Kafka | Confluence: https://montebravo.atlassian.net/wiki/spaces/MBI/pages/249004095 -->

| Serviço | Uso |
|---|---|
| AWS Lambda (.NET 8, ARM64) | Runtime principal para serviços serverless |
| API Gateway | Exposição de APIs REST |
| PostgreSQL (RDS/Aurora) | Banco de dados relacional |
| S3 | Armazenamento de objetos |
| SQS | Filas de mensagens (cenários de baixo volume) |
| Amazon MSK | Cluster Apache Kafka gerenciado (broker principal para mensageria) |
| MSK Connect | Kafka Connect gerenciado para conectores de integração |
| EventBridge | Barramento de eventos |
| Secrets Manager / SSM Parameter Store | Gerenciamento de segredos |

### Serviços opcionais

| Serviço | Quando usar |
|---|---|
| ECS Fargate | Serviços que não cabem em Lambda (long-running, stateful) |

### Serviços a evitar

| Serviço | Motivo |
|---|---|
| EC2 | Preferir serverless (Lambda) ou containers gerenciados (Fargate) |

### IaC

- **Terraform** (>= 1.6) como ferramenta de Infrastructure as Code.
- Naming: prefixo do recurso = nome do serviço.
- Tags obrigatórias: `environment`, `application`, `owner`.

---

## Por que Wolverine?

O framework [Wolverine](https://wolverinefx.net/) foi escolhido (RFC-003) por oferecer:

- **Outbox/Inbox integrado** com EF Core — transações ACID em ambiente distribuído.
- **Suporte a RabbitMQ e Kafka** como brokers.
- **Integração com .NET Aspire** para desenvolvimento local.
- **Handlers tipados** com messaging integrado.
- **Retry e dead letter** configuráveis.

---

## Configuração do Projeto (.csproj)

### Projeto Api (host)

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
```

### Projeto Domain (class library)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
  <!-- Domain NÃO deve ter dependências de pacotes externos (exceto abstrações) -->
</Project>
```

### Projeto Application (class library)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ServiceName}.Domain\{ServiceName}.Domain.csproj" />
    <PackageReference Include="FluentValidation" Version="*" />
    <PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="*" />
  </ItemGroup>
</Project>
```

### Projeto Infrastructure (class library)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ServiceName}.Application\{ServiceName}.Application.csproj" />
    <ProjectReference Include="..\{ServiceName}.Domain\{ServiceName}.Domain.csproj" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.*" />
    <PackageReference Include="WolverineFx" Version="*" />
    <PackageReference Include="WolverineFx.RabbitMQ" Version="*" />
    <PackageReference Include="Polly" Version="*" />
  </ItemGroup>
</Project>
```

---

## Configuração Padrão (Program.cs)

```csharp
var builder = WebApplication.CreateBuilder(args);

// Serilog
builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration));

// Wolverine (messaging + outbox)
builder.Host.UseWolverine(opts =>
{
    opts.UseRabbitMq(rabbit =>
    {
        rabbit.HostName = builder.Configuration["RabbitMQ:Host"];
    });

    opts.Policies.UseDurableOutboxOnAllSendingEndpoints();
    opts.Policies.UseDurableInboxOnAllListeners();
});

// Camadas
builder.Services
    .AddApplication()       // FluentValidation, Behaviors
    .AddInfrastructure(builder.Configuration);  // EF Core, Repositories, Clients

// OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Health Checks
builder.Services.AddHealthChecks()
    .AddNpgSql(builder.Configuration.GetConnectionString("DefaultConnection")!);

var app = builder.Build();

// Middleware
app.UseSerilogRequestLogging();
app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Health Checks
app.MapHealthChecks("/health/live", new() { Predicate = c => c.Name == "self" });
app.MapHealthChecks("/health/ready");

// Endpoints
app.MapOrdersEndpoints();

app.Run();
```

---

## Scripts e Comandos Padrão

```bash
# Desenvolvimento
dotnet run --project src/{ServiceName}.Api

# Build
dotnet build

# Testes
dotnet test

# Testes com cobertura
dotnet test --collect:"XPlat Code Coverage"

# Migrations
dotnet ef migrations add {MigrationName} --project src/{ServiceName}.Infrastructure --startup-project src/{ServiceName}.Api
dotnet ef database update --project src/{ServiceName}.Infrastructure --startup-project src/{ServiceName}.Api

# Formatação
dotnet format

# Análise estática
dotnet format --verify-no-changes

# Vulnerabilidades
dotnet list package --vulnerable
```

---

## Configuração de Ambiente

### Variáveis de ambiente (RFC-002)

- `appsettings.json` — configuração base (commitado).
- `appsettings.Development.json` — configuração local (commitado, sem segredos).
- User Secrets — segredos locais (`dotnet user-secrets`).
- AWS Secrets Manager / SSM Parameter Store — segredos em produção.

### Configuração obrigatória

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database={ServiceName};Username=...;Password=..."
  },
  "RabbitMQ": {
    "Host": "localhost",
    "Port": 5672
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft.AspNetCore": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning"
      }
    }
  },
  "AWS": {
    "Region": "us-east-1"
  }
}
```

---

## Docker

### Dockerfile padrão

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.sln .
COPY src/*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p src/${file%.*} && mv $file src/${file%.*}/; done
RUN dotnet restore

COPY src/ src/
RUN dotnet publish src/{ServiceName}.Api/{ServiceName}.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health/live || exit 1
ENTRYPOINT ["dotnet", "{ServiceName}.Api.dll"]
```

---

## Segurança (RFC-002)

| Regra | Descrição |
|---|---|
| `no_hardcoded_secrets` | Nunca hardcodar segredos no código |
| `use_https_only` | Toda comunicação via HTTPS |
| `encrypt_at_rest` | Dados criptografados em repouso |
| `encrypt_in_transit` | Dados criptografados em trânsito |
| `least_privilege` | IAM com menor privilégio possível |

---

## Tecnologias Descartadas (e por quê)

O Kiro deve alertar se encontrar uso dessas tecnologias em código novo:

| Tecnologia | Motivo da rejeição |
|---|---|
| NHibernate | EF Core é o padrão da organização |
| Autofac | DI nativo do .NET é suficiente |
| NSubstitute | Moq é o padrão definido na RFC-002 |
| NUnit / MSTest | xUnit é o padrão |
| Newtonsoft.Json | System.Text.Json é o padrão no .NET 8+ |
| RestSharp | HttpClientFactory + Polly é o padrão |
| log4net / NLog | Serilog é o padrão |
| SQL Server | PostgreSQL é o banco padrão (RFC-002) |
| EC2 | Preferir Lambda ou ECS Fargate |
| float/double para dinheiro | Usar `decimal` sempre (Guia de Nomeação) |

---

## Análise Estática e Qualidade

### Analyzers obrigatórios (RFC-002)

- `dotnet_analyzers` habilitado.
- `nullable_reference_types: enabled`.
- `TreatWarningsAsErrors` em todos os projetos.

### Convenções de código (RFC-002)

- `use_async_suffix: true` — métodos assíncronos com sufixo `Async`.
- `async_methods_only: true` — preferir async em toda operação I/O.

---

## Referências

- [RFC-002 – Padrão Steering File para backend](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/192806913)
- [ADR-001 – Padrão arquitetural de comunicação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517)
- [RFC-003 – Outbox/Inbox para transações financeiras](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/227082241)
- [Wolverine Framework](https://wolverinefx.net/)
- [Microsoft – Entity Framework Core](https://learn.microsoft.com/en-us/ef/core/)

---

*Versão: 0.3.0 | Última revisão: 2026-07-08 | Próxima revisão: TODO*
