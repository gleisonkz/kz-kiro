# Onboarding — Primeiros Passos com o Kiro na MonteBravo

> **Objetivo:** Guiar qualquer desenvolvedor ou time na adoção do Kiro, partindo do zero até o primeiro projeto configurado e funcionando com os padrões organizacionais.

---

## Sumário

1. [O que é o Kiro](#o-que-é-o-kiro)
2. [Pré-requisitos](#pré-requisitos)
3. [Configurando seu ambiente](#configurando-seu-ambiente)
4. [Iniciando um projeto com Bootstrap](#iniciando-um-projeto-com-bootstrap)
5. [Entendendo o que foi instalado](#entendendo-o-que-foi-instalado)
6. [Próximos passos para o time](#próximos-passos-para-o-time)
7. [Dúvidas frequentes](#dúvidas-frequentes)

---

## O que é o Kiro

> TODO: Descrever brevemente o Kiro — o que ele é, qual problema resolve e por que a MonteBravo o adotou.

O Kiro é uma ferramenta de desenvolvimento assistido por IA que opera diretamente no fluxo de trabalho dos times de engenharia, provendo contexto inteligente, automações e steering configurável por projeto e por organização.

---

## Pré-requisitos

> TODO: Listar as dependências e versões mínimas necessárias para usar o Kiro (ex.: Node.js, versão do Kiro CLI, acesso ao repositório mb-kiro).

- [ ] Kiro CLI instalado (versão mínima: `TODO`)
- [ ] Acesso ao repositório `MonteBravo/mb-kiro`
- [ ] Git configurado com credenciais válidas
- [ ] Acesso aos repositórios de destino

---

## Configurando seu Ambiente

> TODO: Descrever o processo de instalação e configuração inicial do Kiro no ambiente local do desenvolvedor.

```bash
# TODO: Adicionar comandos de instalação do Kiro CLI

# Clone este repositório para referência local (opcional)
git clone git@github.com:MonteBravo/mb-kiro.git
```

---

## Iniciando um Projeto com Bootstrap

Para configurar um projeto novo com os padrões organizacionais:

```bash
# Clone este repositório (se ainda não tiver feito)
git clone git@github.com:MonteBravo/mb-kiro.git

# Execute o script de bootstrap informando o tipo de projeto
cd mb-kiro
./scripts/bootstrap.sh --project-type backend-nest --target ../meu-projeto-backend
```

> TODO: Documentar todos os parâmetros disponíveis do bootstrap.sh e os archetypes suportados.

---

## Entendendo o que foi Instalado

Após o bootstrap, o projeto destino terá:

- **Baseline global** aplicado: princípios de engenharia, segurança e documentação padrão.
- **Archetype** correspondente ao tipo de projeto: hooks, agents e skills pré-configurados.
- **Manifesto Kiro** (`kiro-manifest.json`) registrando a versão do baseline e archetype instalados.

> TODO: Detalhar a estrutura gerada em um projeto após o bootstrap e o significado de cada parte.

---

## Próximos Passos para o Time

1. Revisar os steering files instalados e adaptar ao contexto específico do projeto.
2. Adicionar membros do time como colaboradores no repositório do projeto.
3. Executar `scripts/doctor.sh` para validar que tudo está correto.
4. Agendar uma sessão de nivelamento com o time sobre o uso do Kiro no dia a dia.
5. Registrar o projeto no inventário organizacional (TODO: link para o processo).

---

## Dúvidas Frequentes

**Como atualizo o baseline de um projeto existente?**
> Execute `scripts/sync.sh` na raiz do projeto. Veja a documentação do script para opções de atualização seletiva.

**Posso customizar o archetype para o meu projeto?**
> Sim. Após o bootstrap, você pode modificar os steering files locais. Porém, mudanças que devem valer para todos os projetos do mesmo tipo devem ser propostas como atualização no archetype original, via PR neste repositório.

**Onde reporto problemas com o Kiro ou com os padrões organizacionais?**
> TODO: Adicionar canal oficial e processo de reporte de problemas.

---

*Documento em evolução — contribuições são bem-vindas via Pull Request.*
