---
inclusion: manual
---

# Baseline de Segurança — MonteBravo

> **Steering File | Baseline Global | Versão: 0.2.0**
>
> Este arquivo é injetado como contexto pelo Kiro em todos os projetos da organização.
> Ele define os requisitos mínimos de segurança que todo projeto deve atender.

---

## Propósito deste Arquivo

Este steering file define o baseline de segurança da MonteBravo. O Kiro deve usar estas diretrizes ao:

- Revisar código em busca de vulnerabilidades
- Sugerir implementações de autenticação e autorização
- Avaliar dependências e bibliotecas de terceiros
- Gerar código que lida com dados sensíveis

---

## Requisitos Mínimos de Segurança

### Autenticação e Autorização

<!-- Baseado em ADR: ADR 004 - Autenticação | Confluence: https://montebravo.atlassian.net/wiki/spaces/MBI/pages/335151112 -->

A plataforma utiliza o **AuthCube (Dinamo)** como Identity Provider (IdP) único para todos os públicos. Todos os tokens finais são emitidos e assinados pelo AuthCube via HSM, garantindo não-repúdio.

**Domínios de identidade:**

| Público | IdP | Federação | Protocolo | Token storage |
|---|---|---|---|---|
| Clientes (web/mobile) | AuthCube | — | OIDC + PKCE | Cookie httpOnly (BFF) / Secure storage (mobile) |
| Funcionários (backoffice) | AuthCube | Azure AD via SAML 2.0 | OIDC + PKCE | Cookie httpOnly (BFF) |
| Serviços (M2M) | AuthCube | — | Client Credentials | Memória + cache Redis |

**Requisitos obrigatórios:**

- [x] Toda API exposta externamente deve exigir autenticação.
- [x] IdP único: **AuthCube (Dinamo)** centraliza a emissão de tokens para todos os públicos.
- [x] Protocolo padrão para clientes: **OIDC + PKCE** (Authorization Code Flow com PKCE).
- [x] Protocolo padrão para service-to-service: **Client Credentials** (OAuth2).
- [x] Federação de backoffice: **Azure AD (Entra ID) via SAML 2.0** diretamente no AuthCube.
- [x] Tokens de curta duração: access token 5–15 min, refresh token rotativo.
- [x] **Tokens nunca no localStorage** no front web — sempre cookie httpOnly via BFF.
- [x] Assinatura de tokens via **HSM** (Dinamo) — não-repúdio garantido.
- [x] **MFA obrigatório** em operações sensíveis (saque, alteração de dados bancários, ordens acima de limite).
- [x] **Step-up authentication** — re-autenticação para ações de alto risco mesmo com sessão ativa.
- [x] **API Gateway (KONG)** valida JWT na borda (issuer único = AuthCube).

**Validação de JWT nos serviços:**
- Issuer único: `https://authcube.montebravo.com.br`
- Audience: configurável por serviço (ex: `mb-api`)
- Diferenciação entre cliente e backoffice via claim `realm` (não por scheme).
- `RoleClaimType = "groups"` para mapeamento de permissões.

**Políticas de autorização:**
- `BackofficeOnly`: requer claim `realm = internos`.
- `ClientesOnly`: requer claim `realm = clientes`.
- Autorização por recurso via roles mapeadas de grupos Azure AD (para backoffice).

**Comunicação entre serviços:**
- Cada serviço possui `client_id`/`client_secret` próprio (armazenado no AWS Secrets Manager).
- Scopes mínimos necessários (princípio do menor privilégio).
- Tokens M2M cacheados em Redis com TTL inferior ao tempo de expiração.

### Gestão de Segredos

<!-- Baseado em ADR: ADR 004 - Autenticação | Confluence: https://montebravo.atlassian.net/wiki/spaces/MBI/pages/335151112 -->

- [x] Nunca commitar segredos no repositório.
- [x] Gerenciador de segredos aprovado: **AWS Secrets Manager** (produção) e **SSM Parameter Store** (configurações não-sensíveis).
- [x] Client secrets, credenciais FIX, tokens de integração e certificados devem residir exclusivamente no AWS Secrets Manager ou HSM (Dinamo).
- [ ] TODO: Definir processo de rotação de segredos (frequência, automação).

### Segurança de Dependências

> TODO: Definir as políticas de gestão de dependências de terceiros.

- [ ] Usar apenas versões com suporte ativo (LTS quando aplicável).
- [ ] TODO: Definir ferramenta de análise de vulnerabilidades em dependências (ex.: Dependabot, Snyk).
- [ ] TODO: Definir SLA para correção de vulnerabilidades por severidade.

### Proteção de Dados

> TODO: Definir as políticas de proteção de dados pessoais e sensíveis, alinhadas com LGPD.

- [ ] Dados pessoais devem ser criptografados em repouso e em trânsito.
- [ ] TODO: Definir política de retenção de dados.
- [ ] TODO: Definir processo de DSAR (Data Subject Access Request).
- [ ] TODO: Definir processo de resposta a incidentes de dados.

### Comunicação Segura

<!-- Baseado em ADR: ADR-001 – Padrão arquitetural de comunicação - Serviços distribuídos internos | Confluence: https://montebravo.atlassian.net/wiki/spaces/MBI/pages/219840517 -->

A comunicação entre serviços distribuídos internos utiliza mensageria assíncrona via Message Broker (Kafka/RabbitMQ). Os requisitos de segurança para esse modelo são:

- [x] Toda comunicação entre serviços deve usar TLS 1.2+.
- [x] O Message Broker deve operar em cluster com múltiplos nós para alta disponibilidade.
- [ ] TODO: Definir política de certificados (emissão, renovação, revogação).
- [ ] TODO: Definir política de mutual TLS para serviços internos.
- [ ] TODO: Definir política de autenticação de producers/consumers no broker (SASL, ACLs).

**Transações financeiras:**
- Operações financeiras e integrações com serviços externos devem implementar o padrão **Outbox** para garantir atomicidade (ACID) em ambiente distribuído.
- A integridade das mensagens deve ser verificável (idempotência obrigatória nos consumers).

### Controle de Acesso ao Repositório

> TODO: Definir as políticas de acesso ao código-fonte.

- [ ] Repositórios privados por padrão.
- [ ] TODO: Definir política de acesso para colaboradores externos.
- [ ] Branches protegidas com revisão obrigatória.

---

## Categorias de Vulnerabilidades a Evitar

> TODO: Listar as categorias de vulnerabilidades que o Kiro deve identificar e alertar (ex.: OWASP Top 10, CWE Top 25).

| Categoria | Referência | Prioridade |
|---|---|---|
| Injeção (SQL, NoSQL, OS, etc.) | OWASP A03:2021 | Crítica |
| Autenticação quebrada | OWASP A07:2021 | Crítica |
| Exposição de dados sensíveis | OWASP A02:2021 | Alta |
| TODO | TODO | TODO |

---

## Processo de Resposta a Incidentes

> TODO: Descrever o processo de resposta a incidentes de segurança (ou link para o documento de resposta a incidentes).

---

## Referências

> TODO: Adicionar links para políticas de segurança internas, LGPD, frameworks de segurança relevantes.

---

*Versão: 0.3.0 | Última revisão: 2026-06-18 | Próxima revisão: TODO*
