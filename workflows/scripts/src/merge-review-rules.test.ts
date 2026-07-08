import { describe, it, expect } from "vitest";
import { mergeReviewRules } from "./merge-review-rules.js";
import type { ReviewRulesConfig } from "./types.js";

describe("mergeReviewRules", () => {
  const baseArchetypeConfig: ReviewRulesConfig = {
    version: "1.0",
    archetype: "backend-csharp",
    agent_review: {
      enabled: true,
      agent: "code-reviewer",
      timeout_seconds: 300,
    },
    rules: {
      missing_tests: {
        severity: "error",
        description: "Código novo sem testes correspondentes",
      },
      security_violation: {
        severity: "error",
        description: "Vulnerabilidade detectada em dependências",
      },
      no_async_usage: {
        severity: "error",
        description: "Operação I/O sem async/await",
      },
    },
  };

  describe("preservação de regras existentes", () => {
    it("deve preservar severidades já customizadas no projeto", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        agent_review: { enabled: false },
        rules: {
          missing_tests: {
            severity: "warn",
            description: "Customizado pelo time",
          },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(result.rules.missing_tests.severity).toBe("warn");
      expect(result.rules.missing_tests.description).toBe("Customizado pelo time");
    });

    it("deve preservar version do existingConfig", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "error" },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(result.version).toBe("1.0");
    });

    it("deve preservar archetype do existingConfig", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "error" },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(result.archetype).toBe("backend-csharp");
    });

    it("deve preservar agent_review do existingConfig", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        agent_review: {
          enabled: false,
          agent: "custom-agent",
          timeout_seconds: 120,
        },
        rules: {
          missing_tests: { severity: "error" },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(result.agent_review).toEqual({
        enabled: false,
        agent: "custom-agent",
        timeout_seconds: 120,
      });
    });

    it("deve preservar regras com severity disabled do projeto", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "disabled" },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(result.rules.missing_tests.severity).toBe("disabled");
    });
  });

  describe("adição de regras faltantes", () => {
    it("deve adicionar regras do archetype que não existem no projeto", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "warn" },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(result.rules.security_violation).toEqual({
        severity: "error",
        description: "Vulnerabilidade detectada em dependências",
      });
      expect(result.rules.no_async_usage).toEqual({
        severity: "error",
        description: "Operação I/O sem async/await",
      });
    });

    it("deve adicionar todas as regras quando projeto está vazio", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {},
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(Object.keys(result.rules)).toHaveLength(3);
      expect(result.rules.missing_tests.severity).toBe("error");
      expect(result.rules.security_violation.severity).toBe("error");
      expect(result.rules.no_async_usage.severity).toBe("error");
    });

    it("não deve adicionar nenhuma regra quando todas já existem", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "warn" },
          security_violation: { severity: "disabled" },
          no_async_usage: { severity: "error" },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(Object.keys(result.rules)).toHaveLength(3);
      expect(result.rules.missing_tests.severity).toBe("warn");
      expect(result.rules.security_violation.severity).toBe("disabled");
      expect(result.rules.no_async_usage.severity).toBe("error");
    });
  });

  describe("imutabilidade", () => {
    it("não deve modificar o existingConfig original", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "warn" },
        },
      };

      const originalRulesCount = Object.keys(existingConfig.rules).length;
      mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(Object.keys(existingConfig.rules)).toHaveLength(originalRulesCount);
    });

    it("não deve modificar o archetypeConfig original", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "warn" },
        },
      };

      const originalRulesCount = Object.keys(baseArchetypeConfig.rules).length;
      mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(Object.keys(baseArchetypeConfig.rules)).toHaveLength(originalRulesCount);
    });
  });

  describe("regras extras no projeto", () => {
    it("deve preservar regras do projeto que não existem no archetype", () => {
      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "backend-csharp",
        rules: {
          missing_tests: { severity: "error" },
          custom_project_rule: {
            severity: "warn",
            description: "Regra customizada do projeto",
          },
        },
      };

      const result = mergeReviewRules(baseArchetypeConfig, existingConfig);

      expect(result.rules.custom_project_rule).toEqual({
        severity: "warn",
        description: "Regra customizada do projeto",
      });
      expect(Object.keys(result.rules)).toHaveLength(4);
    });
  });

  describe("cenário completo", () => {
    it("deve mesclar corretamente com regras parcialmente sobrepostas", () => {
      const archetypeConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "bff-fastify",
        agent_review: { enabled: true, agent: "code-reviewer", timeout_seconds: 300 },
        rules: {
          missing_tests: { severity: "error", description: "Testes faltando" },
          security_violation: { severity: "error", description: "Vulnerabilidade" },
          type_errors: { severity: "error", description: "Erros de tipo" },
          missing_route_schema: { severity: "warn", description: "Schema faltando" },
        },
      };

      const existingConfig: ReviewRulesConfig = {
        version: "1.0",
        archetype: "bff-fastify",
        agent_review: { enabled: false },
        rules: {
          missing_tests: { severity: "warn", description: "Relaxado pelo time" },
          security_violation: { severity: "error", description: "Vulnerabilidade custom" },
        },
      };

      const result = mergeReviewRules(archetypeConfig, existingConfig);

      // Preservadas do projeto
      expect(result.rules.missing_tests.severity).toBe("warn");
      expect(result.rules.missing_tests.description).toBe("Relaxado pelo time");
      expect(result.rules.security_violation.description).toBe("Vulnerabilidade custom");

      // Adicionadas do archetype
      expect(result.rules.type_errors.severity).toBe("error");
      expect(result.rules.missing_route_schema.severity).toBe("warn");

      // Metadata preservada do projeto
      expect(result.agent_review).toEqual({ enabled: false });
      expect(result.archetype).toBe("bff-fastify");
    });
  });
});
