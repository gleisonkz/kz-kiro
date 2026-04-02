# mb-kiro

> Repositório central de governança e distribuição de padrões Kiro para a organização MonteBravo.

---

## Propósito

Este repositório é a **fonte da verdade** para tudo que diz respeito à adoção, padronização e evolução do Kiro dentro da organização. Ele concentra:

- **Baseline global** — princípios, políticas de engenharia, segurança e documentação que valem para todos os projetos.
- **Archetypes** — configurações pré-moldadas de Kiro por tipo de projeto (ex.: backend NestJS, frontend React/Next.js), prontas para serem aplicadas como ponto de partida.
- **Powers** — extensões reutilizáveis de Kiro empacotadas para instalação em projetos específicos.
- **Scripts** — automações de bootstrap, sincronização e diagnóstico do ambiente Kiro.
- **Documentação** — onboarding, governança, arquitetura e plano de rollout.

---

## Visão Geral da Arquitetura

```
mb-kiro/
├── baselines/          # Diretrizes e políticas globais (aplicadas a todos os projetos)
│   └── global/
│       └── steering/   # Arquivos .md de steering que o Kiro lê como contexto de projeto
├── archetypes/         # Templates de configuração Kiro por tipo de projeto
│   ├── backend-nest/
│   └── frontend-react-next/
├── powers/             # Powers reutilizáveis empacotados para instalação via Kiro
│   ├── mb-kiro-manager/
│   ├── mb-backend-nest/
│   ├── mb-frontend-react-next/
│   └── mb-monorepo-nx/
├── scripts/            # Ferramentas de linha de comando para bootstrap, sync e doctor
├── examples/           # Exemplos de manifesto e estrutura de projeto
└── docs/               # Documentação de onboarding, governança e arquitetura
```

---

## Baseline Global vs. Archetypes vs. Powers

| Conceito | O que é | Quando usar |
|---|---|---|
| **Baseline Global** | Conjunto de steering files e políticas aplicáveis a **qualquer** projeto da organização | Sempre — é o mínimo obrigatório |
| **Archetype** | Configuração completa de Kiro para um tipo específico de stack (steering + hooks + agents + skills) | No início de um projeto novo, para partir de um template alinhado com os padrões da organização |
| **Power** | Extensão modular do Kiro com funcionalidades específicas, instalável em qualquer projeto | Quando um projeto precisa de capacidades extras sem reescrever do zero |

---

## Scripts: Bootstrap, Sync e Doctor

| Script | Finalidade |
|---|---|
| `scripts/bootstrap.sh` | Configura um projeto novo com o archetype e baseline adequados |
| `scripts/sync.sh` | Atualiza um projeto existente com a versão mais recente do baseline/archetype/powers |
| `scripts/doctor.sh` | Diagnostica o estado atual do Kiro em um projeto e aponta inconsistências |

---

## Como Usar Este Repositório

### Time novo iniciando um projeto

1. Clone este repositório localmente ou acesse via script remoto.
2. Execute `scripts/bootstrap.sh` informando o tipo de projeto e o nome do repositório destino.
3. O script aplicará o archetype correto e o baseline global no projeto.

### Time existente sincronizando padrões

1. Execute `scripts/sync.sh` na raiz do projeto alvo.
2. O script verificará qual versão do baseline/archetype está instalada e atualizará se necessário.

### Diagnóstico de um projeto

1. Execute `scripts/doctor.sh` na raiz do projeto alvo.
2. O script listará configurações ausentes, desatualizadas ou inconsistentes.

### Contribuindo com este repositório

- Abra uma issue descrevendo a mudança proposta.
- Crie um branch `feat/`, `fix/` ou `docs/` a partir de `main`.
- Abra um Pull Request e aguarde revisão de pelo menos um mantenedor.
- Versionamento segue [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH` por componente (baseline, archetype, power).

---

## Versionamento

Cada componente deste repositório evolui de forma independente usando versionamento semântico:

- `baselines/global` — versionado em `baselines/global/VERSION`
- `archetypes/<nome>` — versionado em `archetypes/<nome>/VERSION`
- `powers/<nome>` — versionado em `powers/<nome>/VERSION`

Mudanças **breaking** incrementam o `MAJOR`. Novas funcionalidades compatíveis incrementam o `MINOR`. Correções incrementam o `PATCH`.

---

## Próximos Passos

- [ ] Preencher conteúdo dos steering files no baseline global
- [ ] Definir conteúdo completo dos archetypes backend-nest e frontend-react-next
- [ ] Implementar scripts bootstrap.sh, sync.sh e doctor.sh
- [ ] Publicar powers via Kiro Registry (quando disponível)
- [ ] Definir processo de aprovação para mudanças no baseline global

---

## Mantenedores

> TODO: Listar os mantenedores responsáveis por este repositório.

---

*Última atualização: 2026-04 | Organização: MonteBravo*
