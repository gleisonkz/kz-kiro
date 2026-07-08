import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { consolidateResults } from "./consolidate-results.js";
import type { ReviewResult, Violation } from "./types.js";

/**
 * Property 4: Consolidação agrupa por tipo e contém campos obrigatórios
 *
 * Para qualquer ReviewResult[], o report deve agrupar por section.type e conter
 * rule_id, severity, message em cada violação.
 *
 * **Validates: Requirements 2.4, 2.5, 4.6, 6.6**
 *
 * Tag: "Feature: archetype-code-review, Property 4: Consolidação agrupa por tipo e contém campos obrigatórios"
 */

const VALID_STEPS = [
  "lint",
  "format",
  "type_check",
  "security",
  "archetype_rules",
  "agent",
] as const;

const VALID_SEVERITIES = ["error", "warn"] as const;

/**
 * Gerador de Violation válida com campos obrigatórios.
 */
const violationArb: fc.Arbitrary<Violation> = fc.record({
  rule_id: fc.stringMatching(/^[a-z][a-z0-9_]{2,30}$/).filter((s) => !s.endsWith("_")),
  severity: fc.constantFrom(...VALID_SEVERITIES),
  message: fc.string({ minLength: 1, maxLength: 200 }),
  file: fc.option(fc.stringMatching(/^src\/[a-z][a-z0-9/\-_.]{1,50}$/), { nil: undefined }),
  line: fc.option(fc.integer({ min: 1, max: 10000 }), { nil: undefined }),
  suggestion: fc.option(fc.string({ minLength: 1, maxLength: 200 }), { nil: undefined }),
});

/**
 * Gerador de ReviewResult válido.
 */
const reviewResultArb: fc.Arbitrary<ReviewResult> = fc.record({
  step: fc.constantFrom(...VALID_STEPS),
  status: fc.constantFrom("pass", "fail", "error", "skipped") as fc.Arbitrary<ReviewResult["status"]>,
  violations: fc.array(violationArb, { minLength: 0, maxLength: 5 }),
});

/**
 * Gerador de lista de ReviewResult[].
 */
const reviewResultsArb = fc.array(reviewResultArb, { minLength: 0, maxLength: 10 });

describe("Feature: archetype-code-review, Property 4: Consolidação agrupa por tipo e contém campos obrigatórios", () => {
  it("todas as violações estão presentes no report consolidado agrupadas por step/section.type", () => {
    fc.assert(
      fc.property(reviewResultsArb, (results) => {
        const report = consolidateResults(results);

        // Para cada resultado de entrada, verificar que suas violações aparecem na seção correspondente
        for (const result of results) {
          const section = report.sections.find((s) => s.type === result.step);
          expect(section).toBeDefined();

          // Cada violação do input deve estar presente na seção correspondente
          for (const violation of result.violations) {
            const found = section!.violations.some(
              (v) =>
                v.rule_id === violation.rule_id &&
                v.severity === violation.severity &&
                v.message === violation.message
            );
            expect(found).toBe(true);
          }
        }
      }),
      { numRuns: 100 }
    );
  });

  it("cada violação no report contém os campos obrigatórios: rule_id, severity, message", () => {
    fc.assert(
      fc.property(reviewResultsArb, (results) => {
        const report = consolidateResults(results);

        for (const section of report.sections) {
          for (const violation of section.violations) {
            // Campos obrigatórios devem existir e ser strings/valores válidos
            expect(violation.rule_id).toBeDefined();
            expect(typeof violation.rule_id).toBe("string");
            expect(violation.rule_id.length).toBeGreaterThan(0);

            expect(violation.severity).toBeDefined();
            expect(["error", "warn"]).toContain(violation.severity);

            expect(violation.message).toBeDefined();
            expect(typeof violation.message).toBe("string");
            expect(violation.message.length).toBeGreaterThan(0);
          }
        }
      }),
      { numRuns: 100 }
    );
  });

  it("total_violations equivale à soma de todas as violações de todos os resultados de entrada", () => {
    fc.assert(
      fc.property(reviewResultsArb, (results) => {
        const report = consolidateResults(results);

        const expectedTotal = results.reduce(
          (sum, r) => sum + r.violations.length,
          0
        );

        expect(report.total_violations).toBe(expectedTotal);
      }),
      { numRuns: 100 }
    );
  });
});
