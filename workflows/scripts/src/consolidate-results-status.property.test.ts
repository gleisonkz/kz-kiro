import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { consolidateResults } from "./consolidate-results.js";
import type { ReviewResult, Violation } from "./types.js";

/**
 * Property 5: Determinação correta de status final
 *
 * Para qualquer conjunto de violações:
 * - Se ao menos uma violação possui severity="error", então overall_status deve ser "blocked"
 * - Se todas possuem severity="warn", então overall_status deve ser "warnings_only"
 * - Se não há violações, então overall_status deve ser "approved"
 *
 * **Validates: Requirements 3.2, 3.3, 2.6**
 *
 * Tag: "Feature: archetype-code-review, Property 5: Determinação correta de status final"
 */

const VALID_STEPS = [
  "lint",
  "format",
  "type_check",
  "security",
  "archetype_rules",
  "agent",
] as const;

type StepType = (typeof VALID_STEPS)[number];

const VALID_STATUSES = ["pass", "fail", "error", "skipped"] as const;

/**
 * Gerador de uma violação com severity="error".
 */
const errorViolationArb: fc.Arbitrary<Violation> = fc.record({
  rule_id: fc.stringMatching(/^[a-z][a-z0-9_]{2,20}$/),
  severity: fc.constant("error" as const),
  file: fc.option(fc.stringMatching(/^src\/[a-z]+\.[a-z]+$/), {
    nil: undefined,
  }),
  line: fc.option(fc.integer({ min: 1, max: 1000 }), { nil: undefined }),
  message: fc.string({ minLength: 5, maxLength: 100 }),
  suggestion: fc.option(fc.string({ minLength: 5, maxLength: 80 }), {
    nil: undefined,
  }),
});

/**
 * Gerador de uma violação com severity="warn".
 */
const warnViolationArb: fc.Arbitrary<Violation> = fc.record({
  rule_id: fc.stringMatching(/^[a-z][a-z0-9_]{2,20}$/),
  severity: fc.constant("warn" as const),
  file: fc.option(fc.stringMatching(/^src\/[a-z]+\.[a-z]+$/), {
    nil: undefined,
  }),
  line: fc.option(fc.integer({ min: 1, max: 1000 }), { nil: undefined }),
  message: fc.string({ minLength: 5, maxLength: 100 }),
  suggestion: fc.option(fc.string({ minLength: 5, maxLength: 80 }), {
    nil: undefined,
  }),
});

/**
 * Gerador de ReviewResult com violações personalizáveis.
 */
function reviewResultArb(
  violationsArb: fc.Arbitrary<Violation[]>
): fc.Arbitrary<ReviewResult> {
  return fc.record({
    step: fc.constantFrom(...VALID_STEPS),
    status: fc.constantFrom(...VALID_STATUSES),
    violations: violationsArb,
  });
}

/**
 * Gerador de ReviewResult[] sem nenhuma violação.
 */
const resultsNoViolationsArb: fc.Arbitrary<ReviewResult[]> = fc.array(
  reviewResultArb(fc.constant([])),
  { minLength: 0, maxLength: 6 }
);

/**
 * Gerador de ReviewResult[] onde TODAS as violações têm severity="warn"
 * e há pelo menos uma violação.
 */
const resultsAllWarnArb: fc.Arbitrary<ReviewResult[]> = fc
  .array(
    reviewResultArb(fc.array(warnViolationArb, { minLength: 0, maxLength: 3 })),
    { minLength: 1, maxLength: 6 }
  )
  .filter((results) => results.some((r) => r.violations.length > 0));

/**
 * Gerador de ReviewResult[] onde ao menos uma violação tem severity="error".
 * Pode conter também violações "warn" misturadas.
 */
const resultsWithAtLeastOneErrorArb: fc.Arbitrary<ReviewResult[]> = fc
  .tuple(
    // Pelo menos um result com ao menos uma violação "error"
    reviewResultArb(
      fc.array(errorViolationArb, { minLength: 1, maxLength: 3 })
    ),
    // Resultados adicionais opcionais (podem ter warn ou error)
    fc.array(
      reviewResultArb(
        fc.array(
          fc.oneof(errorViolationArb, warnViolationArb),
          { minLength: 0, maxLength: 3 }
        )
      ),
      { minLength: 0, maxLength: 5 }
    )
  )
  .map(([mustHaveError, rest]) => [mustHaveError, ...rest]);

describe("Feature: archetype-code-review, Property 5: Determinação correta de status final", () => {
  describe("Cenário 1: ao menos uma violação com severity='error' → overall_status='blocked'", () => {
    it("deve retornar 'blocked' quando há pelo menos uma violação com severity='error'", () => {
      fc.assert(
        fc.property(resultsWithAtLeastOneErrorArb, (results) => {
          const report = consolidateResults(results);

          expect(report.overall_status).toBe("blocked");
          expect(report.blocking_violations).toBeGreaterThan(0);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Cenário 2: todas as violações com severity='warn' → overall_status='warnings_only'", () => {
    it("deve retornar 'warnings_only' quando todas as violações têm severity='warn' e há pelo menos uma", () => {
      fc.assert(
        fc.property(resultsAllWarnArb, (results) => {
          const report = consolidateResults(results);

          expect(report.overall_status).toBe("warnings_only");
          expect(report.blocking_violations).toBe(0);
          expect(report.warning_violations).toBeGreaterThan(0);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Cenário 3: nenhuma violação → overall_status='approved'", () => {
    it("deve retornar 'approved' quando não há violações em nenhum resultado", () => {
      fc.assert(
        fc.property(resultsNoViolationsArb, (results) => {
          const report = consolidateResults(results);

          expect(report.overall_status).toBe("approved");
          expect(report.total_violations).toBe(0);
          expect(report.blocking_violations).toBe(0);
          expect(report.warning_violations).toBe(0);
        }),
        { numRuns: 100 }
      );
    });
  });
});
