# Baseline de Segurança — MonteBravo

> **Steering File | Baseline Global | Versão: 0.1.0**
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

> TODO: Definir os padrões obrigatórios de autenticação (ex.: OAuth2, JWT, SSO corporativo) e autorização (ex.: RBAC, ABAC).

- [ ] Toda API exposta externamente deve exigir autenticação.
- [ ] TODO: Definir provedor de identidade padrão.
- [ ] TODO: Definir política de expiração de tokens.
- [ ] TODO: Definir política de autorização por recurso.

### Gestão de Segredos

> TODO: Definir como segredos (senhas, chaves de API, certificados) devem ser gerenciados.

- [ ] Nunca commitar segredos no repositório.
- [ ] TODO: Definir o gerenciador de segredos aprovado (ex.: AWS Secrets Manager, HashiCorp Vault, Azure Key Vault).
- [ ] TODO: Definir processo de rotação de segredos.

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

> TODO: Definir os padrões de comunicação segura entre serviços.

- [ ] Toda comunicação entre serviços deve usar TLS 1.2+.
- [ ] TODO: Definir política de certificados (emissão, renovação, revogação).
- [ ] TODO: Definir política de mutual TLS para serviços internos.

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

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
