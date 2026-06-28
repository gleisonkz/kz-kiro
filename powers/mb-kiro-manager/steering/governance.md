---
name: "Governança Kiro MonteBravo"
description: "Instrui o Kiro sobre a estrutura de padrões organizacionais e como verificar conformidade."
---

# Governança Kiro — MonteBravo

## Estrutura de Padrões

Este projeto utiliza o ecossistema de padrões Kiro da MonteBravo, gerenciado pelo repositório `mb-kiro`. A estrutura é:

- **Baseline global**: steering files obrigatórios para todos os projetos (princípios de engenharia, segurança, documentação, specs).
- **Archetype**: configuração Kiro específica da stack (steering, skills, hooks, agents).
- **Powers**: extensões modulares com capacidades extras.
- **kiro-manifest.json**: registro das versões instaladas de cada componente.

## Verificação de Conformidade

Quando o desenvolvedor perguntar sobre conformidade ou padrões do projeto:

1. Verificar se `kiro-manifest.json` existe na raiz do projeto.
2. Verificar se os steering files do baseline estão presentes em `.kiro/steering/`.
3. Verificar se os hooks do archetype estão ativos em `.kiro/hooks/`.
4. Sugerir execução de `./scripts/doctor.sh --target .` para diagnóstico completo.

## Processo de Exceções

Se o desenvolvedor precisar desviar de um padrão do baseline:

1. Documentar a exceção no `kiro-manifest.json` (campo `exceptions`).
2. Incluir justificativa técnica.
3. Comunicar os mantenedores do mb-kiro via issue ou PR.
4. Rever a exceção a cada 3 meses.

## Atualização de Padrões

Para atualizar os padrões do projeto:

```bash
# No diretório do mb-kiro
./scripts/sync.sh --target <caminho-do-projeto>
```

Para verificar o que mudaria antes de aplicar:

```bash
./scripts/sync.sh --target <caminho-do-projeto> --dry-run
```
