---
inclusion: fileMatch
fileMatchPattern: "**/*.tsx, **/shared/ui/**, **/*.variants.ts"
---

# Design System — Arquitetura, Componentes e Qualidade

> **Steering File | Archetype: frontend-react | Versão: 0.1.0**
>
> Este arquivo é injetado como contexto pelo Kiro em projetos frontend React da MonteBravo.
> Ele define a arquitetura do Design System, biblioteca base, documentação e requisitos de qualidade.
>
> Baseado em: ADR-0005, ADR-0008, RFC-0005, RFC-0006, RFC-0007, RFC-0008, RFC-0009

---

## Arquitetura Fundamental

O Design System da MonteBravo é construído sobre os seguintes pilares:

### Token-first

- Tokens semânticos como fundação (cores, tipografia, spacing, etc.).
- Tokens exportados para utilização e intellisense nos projetos consumidores.
- Estilos (como cores) nunca são hardcoded em componentes — componentes consomem apenas tokens.

### Atomic Design (dentro do Design System)

O Design System organiza seus componentes em hierarquia Atomic Design:

- **Átomos**: componentes primitivos indivisíveis (Button, Input, Icon).
- **Moléculas**: compostos por átomos (SearchBar, FormField).
- **Organismos**: compostos por moléculas e átomos (Header, Sidebar, DataTable).

> Atomic Design se aplica à organização interna do repositório do Design System. Nas aplicações, a organização de componentes segue FSD (segmento `ui/` dentro de slices) conforme ADR-0011.

### Composition over Inheritance

- Componentes complexos são compostos por primitivos menores.
- Padrão de composição com namespace quando aplicável:

```tsx
<Modal.Root>
  <Modal.Trigger>Abrir</Modal.Trigger>
  <Modal.Content>
    <Modal.Title>Título</Modal.Title>
    <Modal.Body>Conteúdo</Modal.Body>
  </Modal.Content>
</Modal.Root>
```

### Acessibilidade

- WCAG 2.1 AA como requisito mínimo obrigatório.
- Navegação por teclado e foco corretos em componentes interativos.
- Papel semântico correto conforme tipo do componente.
- Nome/label acessível quando aplicável.
- Mensagens de erro não podem depender apenas de cor.

---

## Biblioteca Base: Base UI

O Design System utiliza **Base UI** como fundação para componentes primitivos:

- Componentes unstyled (apenas lógica e comportamento, sem estilos visuais).
- Estilização via TailwindCSS 4 + sistema de tokens.
- Acessibilidade WCAG 2.1 AA já implementada (navegação por teclado, ARIA, screen readers).
- Compatível com React 19, TypeScript strict e TailwindCSS 4.
- Tree-shaking para imports granulares.

> Componentes que não existem no Base UI são desenvolvidos internamente seguindo os mesmos padrões de acessibilidade.

### Tecnologias descartadas para biblioteca base

| Tecnologia | Motivo |
|---|---|
| Radix UI | Manutenção desacelerada, menor número de componentes, API mais complexa |
| Headless UI | Menor número de primitivos, foco muito específico em Tailwind |
| Desenvolvimento do zero | Alto custo de implementação de acessibilidade correta |
| UI Kits completos (MUI, Chakra) | Não seguem abordagem token-first, dificultam controle de tokens |

---

## Documentação: Storybook

O Storybook é a ferramenta principal de documentação técnica e apresentação:

- Abordagem **code-first**: stories em TypeScript/React/MDX como fonte de verdade.
- Integração com Figma via `@storybook/addon-designs` e Storybook Connect.
- Validação de acessibilidade com `@storybook/addon-a11y`.
- Customização de theming para identidade visual MonteBravo.
- Self-hosted em infraestrutura controlada.
- Integração com CI/CD para build e deploy automatizados.

### Documentação obrigatória por componente

- Story com casos de uso e estados interativos.
- Link para protótipo no Figma (quando aplicável).
- Props, variantes e comportamento documentados.

---

## Repositório e Versionamento

### Repositório independente

- Design System em repositório próprio (isolamento de permissões para times externos).
- Publicado em npm registry interno (GitHub Packages).
- Instalado no monorepo como dependência compartilhada.

### Versionamento com Changesets + SemVer

- **Major (X.0.0)**: breaking changes (remoção de componentes/props, mudanças incompatíveis em APIs, alterações fundamentais em tokens).
- **Minor (0.X.0)**: novas funcionalidades backward-compatible (novos componentes, props, variantes, tokens).
- **Patch (0.0.X)**: bug fixes backward-compatible (correções, ajustes de acessibilidade, atualizações de deps).

### Fluxo de release

1. Desenvolvedor cria branch e executa `changeset` ao finalizar.
2. PR com changeset revisado junto com o código.
3. Merge em `main`.
4. `changeset version` calcula próxima versão, atualiza package.json e CHANGELOG.
5. CI/CD detecta mudança de versão e publica no registry.
6. Apps atualizam: `pnpm update @monte-bravo/design-system-web@latest`.

### Depreciação

- Ciclo: Depreciar → Documentar → Comunicar → Definir deadline → Remover.
- Deadline padrão: trimestral, salvo exceções justificadas.
- Governança compartilhada entre DesignOps e Engenharia.

---

## Requisitos Obrigatórios de Qualidade

Todo componente do Design System deve atender:

### 1. Identificação estável para teste

- Todo componente interativo deve expor identificador estável para automação.
- Identificadores não podem depender de texto visível, posição ou classe CSS.

### 2. Acessibilidade técnica mínima

- Papel semântico correto.
- Nome/label acessível.
- Estados de acessibilidade expostos: `disabled`, `selected/checked`, `expanded/collapsed`.
- Navegação por teclado e foco corretos.

### 3. Contrato de estados

- Estados obrigatórios (quando aplicáveis): `default`, `loading`, `empty`, `error`, `success`, `disabled`.
- Cada estado deve ser detectável por automação.
- Estados inválidos devem ser prevenidos ou tratados.

### 4. Determinismo

- Sem IDs ou valores aleatórios durante execução normal.
- Animações e transições devem poder ser desativadas em contexto de teste.
- Timers, delays e debounce com comportamento previsível e configurável.

### 5. Form controls

- Inputs com identificador único e label acessível.
- Mensagens de erro associadas corretamente ao campo.
- Estados de formulário claros: `valid`, `invalid`, `submitting`.

### 6. Testes

- Cada componente deve ter testes unitários próprios.
- Componentes compostos: composição também testada.
- Estados principais com cobertura automatizada.

### 7. Segurança

- Não expor dados sensíveis na interface.
- Não vazar detalhes técnicos em mensagens de erro.
- Suporte a masking para dados sensíveis.
- Logs sem dados pessoais.

### 8. Critério de aceite

Um componente só é considerado pronto se for: testável, acessível, determinístico, seguro e previsível.

---

## Fluxo de Desenvolvimento de Componentes

1. Proposta de Design
2. Aprovação conjunta (DesignOps + Engenharia)
3. Implementação
4. Testes automatizados + validação de acessibilidade
5. Documentação no Storybook
6. PR Review + Chromatic
7. Versionamento automático (Changesets)
8. Publicação

---

## Referências

- [ADR-0005 - Design System: Arquitetura](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757464)
- [ADR-0008 - Design System: Documentação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757219)
- [RFC-0005 - Design System Arquitetura](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757464)
- [RFC-0006 - Design System Biblioteca Base](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757501)
- [RFC-0007 - Design System Repositório](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757526)
- [RFC-0008 - Design System Documentação](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757555)
- [RFC-0009 - Design System Requisitos de Qualidade](https://montebravo.atlassian.net/wiki/spaces/MBI/pages/108757605)

---

*Versão: 0.1.0 | Última revisão: 2026-04 | Próxima revisão: TODO*
