import { describe, it, expect } from "vitest";
import { consolidateResults } from "./consolidate-results.js";
import type { ReviewResult, Violation } from "./types.js";

describe("consolidateResults", () => {
  describe("overall_status", () => {
    it("deve retornar 'approved' quando não há violações", () => {
      const results: ReviewResult[] = [
        { step: "lint", status: "pass", violations: [] },
        { step: "format", status: "pass", violations: [] },
      ];

      const report = consolidateResults(results);

      expect(report.overall_status).toBe("approved");
    });

    it("deve retornar 'blocked' quando há violação com severity=error", () => {
      const results: ReviewResult[] = [
        {
          step: "lint",
          status: "fail",
          violations: [
            {
              rule_id: "no-unused-vars",
              severity: "error",
              message: "Variável não utilizada",
              file: "src/index.ts",
              line: 10,
            },
          ],
        },
      ];

      const report = consolidateResults(results);

      expect(report.overall_status).toBe("blocked");
    });

    it("deve retornar 'blocked' quando há mix de error e warn", () => {
      const results: ReviewResult[] = [
        {
          step: "lint",
          status: "fail",
          violations: [
            {
              rule_id: "no-unused-vars",
              severity: "warn",
              message: "Variável não utilizada",
            },
          ],
        },
        {
          step: "security",
          status: "fail",
          violations: [
            {
              rule_id: "security_violation",
              severity: "error",
              message: "Vulnerabilidade crítica",
            },
          ],
        },
      ];

      const report = consolidateResults(results);

      expect(report.overall_status).toBe("blocked");
    });

    it("deve retornar 'warnings_only' quando todas violações são warn", () => {
      const results: ReviewResult[] = [
        {
          step: "lint",
          status: "fail",
          violations: [
            {
              rule_id: "prefer-const",
              severity: "warn",
              message: "Use const em vez de let",
            },
          ],
        },
        {
          step: "format",
          status: "fail",
          violations: [
            {
              rule_id: "trailing-comma",
              severity: "warn",
              message: "Faltando vírgula final",
            },
          ],
        },
      ];

      const report = consolidateResults(results);

      expect(report.overall_status).toBe("warnings_only");
    });
  });

  describe("contagem de violações", () => {
    it("deve contar total_violations corretamente", () => {
      const results: ReviewResult[] = [
        {
          step: "lint",
          status: "fail",
          violations: [
            { rule_id: "r1", severity: "error", message: "m1" },
            { rule_id: "r2", severity: "warn", message: "m2" },
          ],
        },
        {
          step: "security",
          status: "fail",
          violations: [
            { rule_id: "r3", severity: "error", message: "m3" },
          ],
        },
      ];

      const report = consolidateResults(results);

      expect(report.total_violations).toBe(3);
      expect(report.blocking_violations).toBe(2);
      expect(report.warning_violations).toBe(1);
    });

    it("deve retornar zero para todas contagens quando sem violações", () => {
      const results: ReviewResult[] = [
        { step: "lint", status: "pass", violations: [] },
      ];

      const report = consolidateResults(results);

      expect(report.total_violations).toBe(0);
      expect(report.blocking_violations).toBe(0);
      expect(report.warning_violations).toBe(0);
    });
  });

  describe("agrupamento por seção", () => {
    it("deve incluir todas as 6 seções possíveis mesmo sem violações", () => {
      const results: ReviewResult[] = [];

      const report = consolidateResults(results);

      expect(report.sections).toHaveLength(6);
      const types = report.sections.map((s) => s.type);
      expect(types).toContain("lint");
      expect(types).toContain("format");
      expect(types).toContain("type_check");
      expect(types).toContain("security");
      expect(types).toContain("archetype_rules");
      expect(types).toContain("agent");
    });

    it("deve marcar seção como 'fail' quando tem violações", () => {
      const results: ReviewResult[] = [
        {
          step: "lint",
          status: "fail",
          violations: [
            { rule_id: "r1", severity: "error", message: "m1" },
          ],
        },
      ];

      const report = consolidateResults(results);

      const lintSection = report.sections.find((s) => s.type === "lint");
      expect(lintSection?.status).toBe("fail");
      expect(lintSection?.violations).toHaveLength(1);
    });

    it("deve marcar seção como 'pass' quando não tem violações", () => {
      const results: ReviewResult[] = [
        { step: "lint", status: "pass", violations: [] },
      ];

      const report = consolidateResults(results);

      const lintSection = report.sections.find((s) => s.type === "lint");
      expect(lintSection?.status).toBe("pass");
      expect(lintSection?.violations).toHaveLength(0);
    });

    it("deve agrupar violações de múltiplos results do mesmo step", () => {
      const results: ReviewResult[] = [
        {
          step: "lint",
          status: "fail",
          violations: [
            { rule_id: "r1", severity: "error", message: "m1" },
          ],
        },
        {
          step: "lint",
          status: "fail",
          violations: [
            { rule_id: "r2", severity: "warn", message: "m2" },
          ],
        },
      ];

      const report = consolidateResults(results);

      const lintSection = report.sections.find((s) => s.type === "lint");
      expect(lintSection?.violations).toHaveLength(2);
      expect(lintSection?.status).toBe("fail");
    });

    it("deve usar títulos legíveis nas seções", () => {
      const results: ReviewResult[] = [];

      const report = consolidateResults(results);

      const titles = report.sections.map((s) => s.title);
      expect(titles).toContain("Lint");
      expect(titles).toContain("Formatação");
      expect(titles).toContain("Type Check");
      expect(titles).toContain("Segurança");
      expect(titles).toContain("Regras do Archetype");
      expect(titles).toContain("Revisão via Agent");
    });
  });

  describe("preservação de campos das violações", () => {
    it("deve preservar todos os campos obrigatórios e opcionais das violações", () => {
      const violation: Violation = {
        rule_id: "missing_tests",
        severity: "error",
        file: "src/services/user.ts",
        line: 42,
        message: "Código sem teste correspondente",
        suggestion: "Criar arquivo user.test.ts",
      };

      const results: ReviewResult[] = [
        { step: "archetype_rules", status: "fail", violations: [violation] },
      ];

      const report = consolidateResults(results);

      const section = report.sections.find(
        (s) => s.type === "archetype_rules"
      );
      expect(section?.violations[0]).toEqual(violation);
    });

    it("deve preservar violações com apenas campos obrigatórios", () => {
      const violation: Violation = {
        rule_id: "type_errors",
        severity: "error",
        message: "Erro de tipo detectado",
      };

      const results: ReviewResult[] = [
        { step: "type_check", status: "fail", violations: [violation] },
      ];

      const report = consolidateResults(results);

      const section = report.sections.find((s) => s.type === "type_check");
      expect(section?.violations[0].rule_id).toBe("type_errors");
      expect(section?.violations[0].severity).toBe("error");
      expect(section?.violations[0].message).toBe("Erro de tipo detectado");
      expect(section?.violations[0].file).toBeUndefined();
      expect(section?.violations[0].line).toBeUndefined();
      expect(section?.violations[0].suggestion).toBeUndefined();
    });
  });
});
