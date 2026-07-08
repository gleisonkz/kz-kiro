import { describe, it, expect } from "vitest";
import { filterRules } from "./filter-rules.js";
import type { ReviewRulesConfig } from "./types.js";

/**
 * Helper para criar uma ReviewRulesConfig de teste.
 */
function makeConfig(
  rules: Record<string, { severity: "error" | "warn" | "disabled"; description?: string }>
): ReviewRulesConfig {
  return {
    version: "1.0",
    archetype: "backend-csharp",
    rules,
  };
}

describe("filterRules", () => {
  const archetypeRules = [
    "missing_tests",
    "security_violation",
    "breaking_change_without_note",
    "no_async_usage",
    "coverage_below_threshold",
  ];

  describe("filtragem de regras disabled", () => {
    it("deve excluir regras com severity='disabled' do resultado", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error", description: "Testes faltantes" },
        security_violation: { severity: "disabled", description: "Segurança" },
        no_async_usage: { severity: "warn", description: "Async" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.activeRules).toHaveProperty("missing_tests");
      expect(result.activeRules).toHaveProperty("no_async_usage");
      expect(result.activeRules).not.toHaveProperty("security_violation");
      expect(result.errors).toHaveLength(0);
    });

    it("deve retornar erro quando todas as regras estão disabled", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "disabled" },
        security_violation: { severity: "disabled" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.activeRules).toEqual({});
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0]).toContain("todas as regras estão desabilitadas");
    });

    it("deve manter regras com severity='error' como ativas", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error", description: "Desc" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.activeRules["missing_tests"]).toEqual({
        severity: "error",
        description: "Desc",
      });
    });

    it("deve manter regras com severity='warn' como ativas", () => {
      // Arrange
      const config = makeConfig({
        no_async_usage: { severity: "warn", description: "Sem async" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.activeRules["no_async_usage"]).toEqual({
        severity: "warn",
        description: "Sem async",
      });
    });
  });

  describe("tolerância a regras inexistentes no archetype", () => {
    it("deve gerar warning para regra que não existe no archetype", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error" },
        regra_inventada: { severity: "warn", description: "Não existe" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.warnings).toHaveLength(1);
      expect(result.warnings[0]).toContain("regra_inventada");
      expect(result.warnings[0]).toContain("não existe no archetype");
      expect(result.activeRules).not.toHaveProperty("regra_inventada");
      expect(result.activeRules).toHaveProperty("missing_tests");
    });

    it("deve gerar múltiplos warnings para múltiplas regras inexistentes", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error" },
        foo: { severity: "error" },
        bar: { severity: "warn" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.warnings).toHaveLength(2);
      expect(result.warnings.some((w) => w.includes("foo"))).toBe(true);
      expect(result.warnings.some((w) => w.includes("bar"))).toBe(true);
    });

    it("não deve gerar warning para regras disabled que não existem no archetype", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error" },
        regra_fantasma: { severity: "disabled" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      // Regras disabled são ignoradas antes da verificação de existência
      expect(result.warnings).toHaveLength(0);
      expect(result.activeRules).toHaveProperty("missing_tests");
    });

    it("não deve alterar o status final por causa de regras inexistentes", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error" },
        regra_invalida: { severity: "warn" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.errors).toHaveLength(0);
      expect(result.activeRules).toHaveProperty("missing_tests");
    });
  });

  describe("cenários combinados", () => {
    it("deve funcionar com config vazia (apenas disabled) e regras inexistentes", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "disabled" },
        regra_invalida: { severity: "disabled" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.activeRules).toEqual({});
      expect(result.errors).toHaveLength(1);
      // Regras disabled não geram warning de inexistência
      expect(result.warnings).toHaveLength(0);
    });

    it("deve preservar descrição original da regra no resultado", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error", description: "Código sem testes" },
        security_violation: { severity: "warn", description: "Vuln detectada" },
      });

      // Act
      const result = filterRules(config, archetypeRules);

      // Assert
      expect(result.activeRules["missing_tests"].description).toBe("Código sem testes");
      expect(result.activeRules["security_violation"].description).toBe("Vuln detectada");
    });

    it("deve funcionar com archetypeRules vazio (todas inexistentes)", () => {
      // Arrange
      const config = makeConfig({
        missing_tests: { severity: "error" },
        security_violation: { severity: "warn" },
      });

      // Act
      const result = filterRules(config, []);

      // Assert
      expect(result.activeRules).toEqual({});
      expect(result.warnings).toHaveLength(2);
      expect(result.errors).toHaveLength(0);
    });
  });
});
