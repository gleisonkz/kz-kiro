import { describe, it, expect } from "vitest";
import { validateReviewRules } from "./validate-review-rules.js";

describe("validateReviewRules", () => {
  describe("YAML válido e aderente ao schema", () => {
    it("deve retornar valid=true para configuração completa e válida", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: true
  agent: code-reviewer
  timeout_seconds: 300
rules:
  missing_tests:
    severity: error
    description: "Código novo sem testes correspondentes"
  security_violation:
    severity: warn
    description: "Vulnerabilidade em dependências"
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
      expect(result.config).toBeDefined();
      expect(result.config!.version).toBe("1.0");
      expect(result.config!.archetype).toBe("backend-csharp");
    });

    it("deve retornar valid=true sem agent_review (campo opcional)", () => {
      const yamlContent = `
version: "1.0"
archetype: bff-fastify
rules:
  missing_tests:
    severity: error
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });
  });

  describe("YAML malformado", () => {
    it("deve retornar erro com indicação de linha para YAML inválido", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
rules:
  missing_tests:
    severity: error
    description: "teste
  sem fechar aspas
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].field).toBe("/");
      expect(result.errors[0].message).toContain("YAML malformado");
    });

    it("deve retornar erro para YAML com indentação inválida", () => {
      const yamlContent = `
version: "1.0"
  archetype: backend-csharp
rules:
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors[0].message).toContain("YAML malformado");
    });
  });

  describe("violações do JSON Schema", () => {
    it("deve retornar erro quando campo obrigatório 'version' está ausente", () => {
      const yamlContent = `
archetype: backend-csharp
rules:
  missing_tests:
    severity: error
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors.some((e) => e.message.includes("version"))).toBe(true);
    });

    it("deve retornar erro quando campo obrigatório 'rules' está ausente", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors.some((e) => e.message.includes("rules"))).toBe(true);
    });

    it("deve retornar erro para valor de enum inválido em version", () => {
      const yamlContent = `
version: "2.0"
archetype: backend-csharp
rules:
  missing_tests:
    severity: error
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors.some((e) => e.field === "/version")).toBe(true);
    });

    it("deve retornar erro para archetype inválido", () => {
      const yamlContent = `
version: "1.0"
archetype: invalid-archetype
rules:
  missing_tests:
    severity: error
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors.some((e) => e.field === "/archetype")).toBe(true);
    });

    it("deve retornar erro para severity inválida em uma regra", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
rules:
  missing_tests:
    severity: critical
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(
        result.errors.some((e) => e.field.includes("severity"))
      ).toBe(true);
    });

    it("deve retornar erro quando rules está vazio (minProperties=1)", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
rules: {}
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(
        result.errors.some((e) => e.message.includes("propriedade"))
      ).toBe(true);
    });

    it("deve retornar erro quando severity está ausente na regra", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
rules:
  missing_tests:
    description: "sem severity"
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors.some((e) => e.message.includes("severity"))).toBe(true);
    });
  });

  describe("todas as regras disabled", () => {
    it("deve retornar erro de configuração quando todas as regras estão disabled", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
rules:
  missing_tests:
    severity: disabled
  security_violation:
    severity: disabled
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(false);
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].field).toBe("/rules");
      expect(result.errors[0].message).toContain("desabilitadas");
    });

    it("deve retornar valid=true quando ao menos uma regra não está disabled", () => {
      const yamlContent = `
version: "1.0"
archetype: backend-csharp
rules:
  missing_tests:
    severity: disabled
  security_violation:
    severity: warn
`;
      const result = validateReviewRules(yamlContent);

      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });
  });
});
