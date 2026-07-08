import { describe, it, expect } from "vitest";
import { formatAgentFeedback } from "./format-agent-feedback.js";

describe("formatAgentFeedback", () => {
  describe("entrada vazia ou sem issues", () => {
    it("deve retornar mensagem padrão quando input é string vazia", () => {
      const result = formatAgentFeedback("");

      expect(result).toContain("## 🤖 Revisão via Agent");
      expect(result).toContain("Nenhum feedback produzido pelo agent.");
    });

    it("deve retornar mensagem padrão quando input é apenas espaços", () => {
      const result = formatAgentFeedback("   \n  \n  ");

      expect(result).toContain("Nenhum feedback produzido pelo agent.");
    });

    it("deve retornar mensagem quando não identifica issues no texto", () => {
      const result = formatAgentFeedback(
        "Revisão concluída sem problemas encontrados."
      );

      expect(result).toContain("## 🤖 Revisão via Agent");
      expect(result).toContain("Nenhum problema identificado pelo agent.");
    });
  });

  describe("parsing de severidade", () => {
    it("deve parsear issue com ERROR:", () => {
      const input = "ERROR: Variável não utilizada\nVariável declarada mas nunca usada.";

      const result = formatAgentFeedback(input);

      expect(result).toContain("### 🚫 [Error] Variável não utilizada");
      expect(result).toContain("Variável declarada mas nunca usada.");
    });

    it("deve parsear issue com WARN:", () => {
      const input = "WARN: Complexidade ciclomática alta\nFunção com muitos branches.";

      const result = formatAgentFeedback(input);

      expect(result).toContain("### ⚠️ [Warning] Complexidade ciclomática alta");
      expect(result).toContain("Função com muitos branches.");
    });

    it("deve parsear issue com WARNING:", () => {
      const input = "WARNING: Código duplicado\nTrecho duplicado em dois arquivos.";

      const result = formatAgentFeedback(input);

      expect(result).toContain("### ⚠️ [Warning] Código duplicado");
    });

    it("deve ser case-insensitive no marcador de severidade", () => {
      const input = "error: Problema encontrado\nDetalhes do problema.";

      const result = formatAgentFeedback(input);

      expect(result).toContain("[Error] Problema encontrado");
    });
  });

  describe("parsing de localização", () => {
    it("deve parsear FILE: com formato arquivo:linha", () => {
      const input = [
        "ERROR: Falta de validação",
        "FILE: src/service.ts:42",
        "Input não validado.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("**Localização:** `src/service.ts:42`");
    });

    it("deve parsear FILE: sem número de linha", () => {
      const input = [
        "WARN: Imports não utilizados",
        "FILE: src/utils/helpers.ts",
        "Há imports sem uso.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("**Localização:** `src/utils/helpers.ts`");
    });

    it("deve parsear FILE: com formato arquivo(linha)", () => {
      const input = [
        "ERROR: Tipo incorreto",
        "FILE: src/model.ts(15)",
        "Tipo incompatível.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("**Localização:** `src/model.ts:15`");
    });

    it("deve parsear FILE: com formato 'arquivo line N'", () => {
      const input = [
        "ERROR: Null reference",
        "FILE: src/handler.ts line 99",
        "Possível null reference.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("**Localização:** `src/handler.ts:99`");
    });
  });

  describe("parsing de sugestão", () => {
    it("deve parsear SUGGESTION:", () => {
      const input = [
        "ERROR: SQL Injection",
        "FILE: src/db.ts:10",
        "Query construída com concatenação de string.",
        "SUGGESTION: Use parameterized queries em vez de concatenação.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain(
        "**Sugestão:** Use parameterized queries em vez de concatenação."
      );
    });

    it("deve funcionar sem sugestão", () => {
      const input = [
        "ERROR: Problema genérico",
        "Descrição do problema.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).not.toContain("**Sugestão:**");
    });
  });

  describe("múltiplos issues", () => {
    it("deve formatar múltiplos issues separados por ---", () => {
      const input = [
        "ERROR: Primeiro problema",
        "FILE: src/a.ts:1",
        "Descrição do primeiro.",
        "SUGGESTION: Corrigir A.",
        "WARN: Segundo problema",
        "FILE: src/b.ts:20",
        "Descrição do segundo.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("### 🚫 [Error] Primeiro problema");
      expect(result).toContain("### ⚠️ [Warning] Segundo problema");
      expect(result).toContain("**Localização:** `src/a.ts:1`");
      expect(result).toContain("**Localização:** `src/b.ts:20`");
      expect(result).toContain("---");
    });

    it("deve incluir cabeçalho principal no início", () => {
      const input = [
        "ERROR: Issue 1",
        "Detalhe 1.",
        "WARN: Issue 2",
        "Detalhe 2.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result.startsWith("## 🤖 Revisão via Agent")).toBe(true);
    });
  });

  describe("formato markdown", () => {
    it("deve gerar markdown com estrutura completa para um issue", () => {
      const input = [
        "ERROR: Vulnerabilidade XSS",
        "FILE: src/components/Render.tsx:55",
        "Uso de dangerouslySetInnerHTML sem sanitização.",
        "SUGGESTION: Usar DOMPurify.sanitize() antes de atribuir HTML.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("## 🤖 Revisão via Agent");
      expect(result).toContain("### 🚫 [Error] Vulnerabilidade XSS");
      expect(result).toContain(
        "**Localização:** `src/components/Render.tsx:55`"
      );
      expect(result).toContain(
        "Uso de dangerouslySetInnerHTML sem sanitização."
      );
      expect(result).toContain(
        "**Sugestão:** Usar DOMPurify.sanitize() antes de atribuir HTML."
      );
    });

    it("deve omitir localização quando FILE não está presente", () => {
      const input = [
        "WARN: Complexidade geral alta",
        "O projeto está com complexidade acima do recomendado.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).not.toContain("**Localização:**");
    });
  });

  describe("edge cases", () => {
    it("deve ignorar linhas que não pertencem a nenhum issue", () => {
      const input = [
        "Algumas linhas de contexto antes.",
        "Outra linha aleatória.",
        "ERROR: Issue real",
        "Descrição válida.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("[Error] Issue real");
      expect(result).not.toContain("Algumas linhas de contexto antes");
      expect(result).not.toContain("Outra linha aleatória");
    });

    it("deve tratar issue sem descrição", () => {
      const input = "ERROR: Issue sem detalhes";

      const result = formatAgentFeedback(input);

      expect(result).toContain("[Error] Issue sem detalhes");
    });

    it("deve tratar descrição multi-linha", () => {
      const input = [
        "ERROR: Problema complexo",
        "Primeira linha da descrição.",
        "Segunda linha com mais detalhes.",
        "Terceira linha de conclusão.",
      ].join("\n");

      const result = formatAgentFeedback(input);

      expect(result).toContain("Primeira linha da descrição.");
      expect(result).toContain("Segunda linha com mais detalhes.");
      expect(result).toContain("Terceira linha de conclusão.");
    });
  });
});
