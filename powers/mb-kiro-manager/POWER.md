---
name: "mb-kiro-manager"
displayName: "Kiro Manager MonteBravo"
description: "Power de governança do ecossistema Kiro da MonteBravo. Instrui o Kiro sobre verificação de conformidade com padrões organizacionais, manutenção do kiro-manifest.json e processos de atualização via sync/doctor/bootstrap."
keywords: ["governança", "governance", "padrões", "standards", "kiro-manifest", "baseline", "archetype", "conformidade", "sync", "doctor", "bootstrap"]
author: "MonteBravo"
---

# mb-kiro-manager

> **Power | mb-kiro-manager | Versão: 1.0.0**

## Visão Geral

O `mb-kiro-manager` é o power de governança do ecossistema Kiro da MonteBravo. Ele instrui o Kiro sobre como verificar conformidade do projeto com os padrões organizacionais, sugerir atualizações e manter o `kiro-manifest.json` consistente.

## Capacidades

Quando instalado, o Kiro passa a:

- Conhecer a estrutura de padrões MonteBravo (baseline, archetype, powers).
- Verificar se o projeto está em conformidade com o baseline global.
- Sugerir execução do `sync.sh` quando detectar desatualização.
- Orientar sobre o processo de exceções ao baseline.
- Auxiliar na manutenção do `kiro-manifest.json`.

## Instalação

### Pré-requisitos

- Kiro IDE instalado e configurado
- Clone local do repositório `mb-kiro` atualizado (`git pull`)

### Instalar via pasta local

1. Abra o Kiro IDE no seu projeto.
2. Acesse o painel de **Powers** (ícone na barra lateral).
3. Clique em **"Import power from a folder"**.
4. Navegue até o diretório do power no clone local do mb-kiro:
   ```
   <caminho-do-mb-kiro>/powers/mb-kiro-manager/
   ```
5. Confirme a importação. O power será registrado e ativado por keywords automaticamente.

### Instalar via URL do repositório GitHub

1. Abra o Kiro IDE no seu projeto.
2. Acesse o painel de **Powers**.
3. Clique em **"Import power from GitHub"**.
4. Insira a URL do repositório:
   ```
   https://github.com/MonteBravo/mb-kiro
   ```
5. Selecione o subdiretório `powers/mb-kiro-manager/`.
6. Confirme a importação.

## Troubleshooting

### Power não ativa ao mencionar governança ou padrões

**Sintoma:** Ao digitar prompts com termos como "conformidade", "padrões" ou "governança", o Kiro não carrega o steering de governança.

**Resolução:**
1. Verifique se o power está listado no painel de Powers do Kiro IDE como instalado.
2. Caso não esteja, reinstale via "Import power from a folder" apontando para `<caminho-do-mb-kiro>/powers/mb-kiro-manager/`.
3. Se o power aparece mas não ativa, verifique se o clone local do mb-kiro está atualizado (`git pull`) e use "Check for updates" no painel de Powers.
4. Reinicie o Kiro IDE se o problema persistir.

---

*Versão: 1.0.0 | Última atualização: 2026-06*
