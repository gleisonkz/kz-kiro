# mb-kiro-manager

> **Power | mb-kiro-manager | Versão: 0.1.0**

## Visão Geral

O `mb-kiro-manager` é o power central de gestão do ecossistema Kiro da MonteBravo. Ele é o ponto de entrada para instalação, bootstrap, sincronização e atualização de todos os padrões Kiro em qualquer projeto da organização.

Pense nele como o "gerenciador de pacotes" dos padrões Kiro — ele orquestra a instalação do baseline global, dos archetypes e dos demais powers.

---

## Responsabilidades

- **Bootstrapping**: Inicializa um projeto com os padrões Kiro corretos para o tipo de stack.
- **Sincronização**: Atualiza um projeto existente com novas versões de baseline, archetype e powers.
- **Diagnóstico**: Verifica o estado atual do Kiro no projeto e reporta inconsistências.
- **Inventário**: Mantém o `kiro-manifest.json` do projeto atualizado e válido.
- **Atualização**: Provê mecanismo para atualização controlada dos padrões, com suporte a rollback.

---

## Instalação

> TODO: Documentar o processo de instalação do power mb-kiro-manager em um projeto.

```bash
# TODO: Adicionar o comando de instalação via Kiro quando disponível
# Exemplo hipotético:
# kiro power install mb-kiro-manager
```

---

## Comandos Disponíveis

> TODO: Detalhar os comandos/ações que este power expõe via Kiro.

| Comando | Descrição | Status |
|---|---|---|
| `manager:bootstrap` | Inicializa um projeto com os padrões organizacionais | Não implementado |
| `manager:sync` | Sincroniza o projeto com a versão mais recente dos padrões | Não implementado |
| `manager:doctor` | Diagnostica o estado do Kiro no projeto | Não implementado |
| `manager:status` | Exibe as versões instaladas de baseline, archetype e powers | Não implementado |
| `manager:rollback` | Reverte para uma versão anterior dos padrões | Não implementado |

---

## Integração com Scripts

Este power complementa (mas não substitui) os scripts bash da pasta `scripts/`:

| Script | Relação com o Power |
|---|---|
| `scripts/bootstrap.sh` | Pode chamar `manager:bootstrap` quando o Kiro estiver disponível |
| `scripts/sync.sh` | Pode chamar `manager:sync` quando o Kiro estiver disponível |
| `scripts/doctor.sh` | Pode chamar `manager:doctor` quando o Kiro estiver disponível |

---

## Configuração

> TODO: Documentar as opções de configuração deste power via `mcp.json`.

Veja `mcp.json` para a estrutura de configuração MCP deste power.

---

## Dependências

> TODO: Listar as dependências deste power (outros powers, ferramentas externas, etc.).

---

## Limitações Conhecidas

> TODO: Documentar limitações e comportamentos esperados edge cases.

---

## Roadmap

- [ ] Implementar `manager:bootstrap` com suporte a todos os archetypes disponíveis
- [ ] Implementar `manager:sync` com detecção de conflitos e modo dry-run
- [ ] Implementar `manager:doctor` com relatório estruturado de saúde
- [ ] Adicionar suporte a rollback com histórico de versões
- [ ] Integrar com Kiro Registry quando disponível

---

*Versão: 0.1.0 | Última atualização: 2026-04*
