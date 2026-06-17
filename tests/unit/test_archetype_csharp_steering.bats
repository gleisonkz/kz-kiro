#!/usr/bin/env bats
# Testes unitarios para steering files do archetype backend-csharp.
# Valida existencia, estrutura e conteudo dos 5 steering files + README.
# Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8

setup() {
  load '../helpers/setup'
  load '../helpers/assertions'

  ARCHETYPE_DIR="${BATS_TEST_DIRNAME}/../../archetypes/backend-csharp"
  STEERING_DIR="${ARCHETYPE_DIR}/steering"
}

# --- Existencia dos 5 steering files + README ---

@test "steering: existem exatamente 5 arquivos de steering (excluindo README)" {
  local count
  count=$(find "${STEERING_DIR}" -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
  [ "$count" -eq 5 ]
}

@test "steering: stack-and-tooling.md existe" {
  [ -f "${STEERING_DIR}/stack-and-tooling.md" ]
}

@test "steering: architecture.md existe" {
  [ -f "${STEERING_DIR}/architecture.md" ]
}

@test "steering: naming-conventions.md existe" {
  [ -f "${STEERING_DIR}/naming-conventions.md" ]
}

@test "steering: ci-cd.md existe" {
  [ -f "${STEERING_DIR}/ci-cd.md" ]
}

@test "steering: data-governance.md existe" {
  [ -f "${STEERING_DIR}/data-governance.md" ]
}

@test "steering: README.md existe" {
  [ -f "${STEERING_DIR}/README.md" ]
}

# --- stack-and-tooling.md: secoes obrigatorias (Req 2.1) ---

@test "stack-and-tooling: contem secao de stack base obrigatoria" {
  run grep -i "Stack Base" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona .NET 8" {
  run grep -iE "\.NET.*8" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona C# 12" {
  run grep -iE "C#.*12" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Minimal APIs" {
  run grep -i "Minimal APIs" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Entity Framework Core 8" {
  run grep -iE "Entity Framework Core.*8" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona PostgreSQL" {
  run grep -i "PostgreSQL" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona FluentValidation" {
  run grep -i "FluentValidation" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona MediatR" {
  run grep -i "MediatR" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Wolverine" {
  run grep -i "Wolverine" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Serilog" {
  run grep -i "Serilog" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona Polly" {
  run grep -i "Polly" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona xUnit" {
  run grep -i "xUnit" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem secao de infra AWS com Lambda ARM64" {
  run grep -iE "Lambda.*ARM64" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona API Gateway" {
  run grep -i "API Gateway" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: menciona RDS ou Aurora" {
  run grep -iE "(RDS|Aurora)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem justificativa para Minimal APIs" {
  run grep -iE "(Por que Minimal APIs|Minimal APIs)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem justificativa para Wolverine Outbox RFC-003" {
  run grep -iE "(Por que Wolverine|RFC-003)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem configuracao .csproj com TreatWarningsAsErrors" {
  run grep -iE "(\.csproj|TreatWarningsAsErrors)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem configuracao Program.cs" {
  run grep -iE "Program\.cs" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem configuracao Docker" {
  run grep -iE "(Docker|Dockerfile)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem secao de seguranca RFC-002" {
  run grep -iE "(Seguran|RFC-002)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

@test "stack-and-tooling: contem secao de tecnologias descartadas" {
  run grep -iE "(Tecnologias Descartadas|Descartadas)" "${STEERING_DIR}/stack-and-tooling.md"
  assert_success
}

# --- architecture.md: secoes obrigatorias (Req 2.2) ---

@test "architecture: contem secao sobre papel do servico de dominio" {
  run grep -iE "(Papel Arquitetural|Papel.*Servi)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem principios fundamentais" {
  run grep -iE "Princ.pios fundamentais" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona Bounded Context" {
  run grep -i "Bounded Context" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona Database per Service" {
  run grep -i "Database per Service" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona comunicacao via mensageria" {
  run grep -iE "(mensageria|Message Broker)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona Outbox Inbox" {
  run grep -iE "Outbox.*Inbox" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona CQRS" {
  run grep -i "CQRS" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: menciona Dependency Rule" {
  run grep -i "Dependency Rule" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem padroes arquiteturais RFC-001" {
  run grep -iE "(RFC-001|Padr.es Arquiteturais Aceitos)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem comunicacao entre servicos ADR-001" {
  run grep -iE "(ADR-001|Comunica.*Servi)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem Outbox Inbox Pattern RFC-003" {
  run grep -iE "(RFC-003|Outbox.*Inbox.*Pattern)" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem CQRS com MediatR" {
  run grep -iE "CQRS.*MediatR" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem Domain-Driven Design" {
  run grep -iE "Domain-Driven Design" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem persistencia EF Core com PostgreSQL" {
  run grep -iE "(Entity Framework Core|EF Core).*PostgreSQL" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem secao de resiliencia com Polly" {
  run grep -iE "Resili" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem secao de observabilidade" {
  run grep -iE "Observabilidade" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem health checks" {
  run grep -iE "Health Check" "${STEERING_DIR}/architecture.md"
  assert_success
}

@test "architecture: contem glossario de termos financeiros" {
  run grep -iE "(Gloss.rio.*Financeiro|Termos Financeiros)" "${STEERING_DIR}/architecture.md"
  assert_success
}

# --- naming-conventions.md: secoes obrigatorias (Req 2.3) ---

@test "naming-conventions: contem tabela de prefixos de natureza com id" {
  run grep -E '\| `id` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo nm" {
  run grep -E '\| `nm` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo cd" {
  run grep -E '\| `cd` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo ds" {
  run grep -E '\| `ds` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo dt" {
  run grep -E '\| `dt` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo tmp" {
  run grep -E '\| `tmp` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo vl" {
  run grep -E '\| `vl` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo qt" {
  run grep -E '\| `qt` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo pc" {
  run grep -E '\| `pc` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo st" {
  run grep -E '\| `st` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo nu" {
  run grep -E '\| `nu` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem prefixo in" {
  run grep -E '\| `in` \|' "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: contem tabela de sufixos de arquivo com 20+ tipos" {
  local count
  count=$(grep -c 'Endpoint\|Middleware\|Command\b\|CommandHandler\|CommandValidator\|Query\b\|QueryHandler\|Response\|Behavior\|Interface\|Value Object\|Enum\|Event\|Exception\|Repository\|DbContext\|Configuration\|Client\|Handler\|Tests' "${STEERING_DIR}/naming-conventions.md" || true)
  [ "$count" -ge 20 ]
}

@test "naming-conventions: menciona snake_case para banco" {
  run grep -i "snake_case" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona PascalCase para C#" {
  run grep -i "PascalCase" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona _camelCase para campos privados" {
  run grep -i "_camelCase" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

@test "naming-conventions: menciona kebab-case para endpoints" {
  run grep -i "kebab-case" "${STEERING_DIR}/naming-conventions.md"
  assert_success
}

# --- ci-cd.md: secoes obrigatorias (Req 2.4) ---

@test "ci-cd: contem secao de principios de CI/CD" {
  run grep -iE "Princ.pios" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: menciona GitHub Actions" {
  run grep -i "GitHub Actions" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: menciona CodePipeline" {
  run grep -i "CodePipeline" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contem steps para PR" {
  run grep -iE "(PR|Pull Request|todo PR)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contem steps para merge em main" {
  run grep -iE "(merge.*main|main)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contem steps para release" {
  run grep -iE "release" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contem review rules bloqueantes" {
  run grep -iE "(missing_tests|security_violation|breaking_change_without_note|no_async_usage)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contem secao de ambientes dev/hml/prod" {
  run grep -iE "Ambientes" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: menciona Lambda ARM64" {
  run grep -i "ARM64" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: menciona ECS Fargate" {
  run grep -i "ECS Fargate" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: menciona migrations backward-compatible" {
  run grep -iE "backward-compatible" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

@test "ci-cd: contem secao de monitoramento pos-deploy" {
  run grep -iE "(Monitoramento|Deploy)" "${STEERING_DIR}/ci-cd.md"
  assert_success
}

# --- data-governance.md: secoes obrigatorias (Req 2.5) ---

@test "data-governance: contem principio de duas camadas duas convencoes" {
  run grep -iE "(Duas Camadas|Duas Conven)" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo nm" {
  run grep -E '\| `nm` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo cd" {
  run grep -E '\| `cd` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo ds" {
  run grep -E '\| `ds` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo dt" {
  run grep -E '\| `dt` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo hr" {
  run grep -E '\| `hr` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo tmp" {
  run grep -E '\| `tmp` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo vl" {
  run grep -E '\| `vl` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo qt" {
  run grep -E '\| `qt` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo pc" {
  run grep -E '\| `pc` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo id" {
  run grep -E '\| `id` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo st" {
  run grep -E '\| `st` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo nu" {
  run grep -E '\| `nu` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo in" {
  run grep -E '\| `in` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: contem tabela de naturezas com prefixo sk" {
  run grep -E '\| `sk` \|' "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona auditoria tmp_creation" {
  run grep -i "tmp_creation" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona auditoria tmp_update" {
  run grep -i "tmp_update" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona HasComment em pt-BR" {
  run grep -i "HasComment" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona constraint pk_" {
  run grep "pk_" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona constraint fk_" {
  run grep "fk_" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona constraint ix_" {
  run grep "ix_" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona constraint uk_" {
  run grep "uk_" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona constraint ak_" {
  run grep "ak_" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona decimal 18 8 ou HasPrecision 18 8" {
  run grep -iE "(DECIMAL\(18.*8\)|HasPrecision\(18.*8\))" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona 3FN ou terceira forma normal" {
  run grep -iE "(3FN|3.*Forma Normal)" "${STEERING_DIR}/data-governance.md"
  assert_success
}

@test "data-governance: menciona processo chapter de dados com SLA 1 semana" {
  run grep -iE "(chapter de dados|SLA.*1 semana|1 semana)" "${STEERING_DIR}/data-governance.md"
  assert_success
}

# --- Exclusividade de data-governance.md (Req 2.7) ---

@test "data-governance: NAO existe em archetypes bff-fastify steering" {
  [ ! -f "${BATS_TEST_DIRNAME}/../../archetypes/bff-fastify/steering/data-governance.md" ]
}

@test "data-governance: NAO existe em archetypes frontend-react steering" {
  [ ! -f "${BATS_TEST_DIRNAME}/../../archetypes/frontend-react/steering/data-governance.md" ]
}

# --- Ausencia de frontmatter YAML (Req 2.8) ---

@test "steering: stack-and-tooling.md inicia com # (sem frontmatter YAML)" {
  local first_line
  first_line=$(head -1 "${STEERING_DIR}/stack-and-tooling.md")
  [[ "$first_line" == "#"* ]]
}

@test "steering: architecture.md inicia com # (sem frontmatter YAML)" {
  local first_line
  first_line=$(head -1 "${STEERING_DIR}/architecture.md")
  [[ "$first_line" == "#"* ]]
}

@test "steering: naming-conventions.md inicia com # (sem frontmatter YAML)" {
  local first_line
  first_line=$(head -1 "${STEERING_DIR}/naming-conventions.md")
  [[ "$first_line" == "#"* ]]
}

@test "steering: ci-cd.md inicia com # (sem frontmatter YAML)" {
  local first_line
  first_line=$(head -1 "${STEERING_DIR}/ci-cd.md")
  [[ "$first_line" == "#"* ]]
}

@test "steering: data-governance.md inicia com # (sem frontmatter YAML)" {
  local first_line
  first_line=$(head -1 "${STEERING_DIR}/data-governance.md")
  [[ "$first_line" == "#"* ]]
}
