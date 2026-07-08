import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { mergeReviewRules } from "./merge-review-rules.js";
import type { ReviewRulesConfig, RuleConfig } from "./types.js";

/**
 * Property 2: Merge de review-rules preserva existentes e adiciona faltantes
 *
 * Para qualquer par de configurações review-rules.yml (archetype + projeto existente),
 * após o merge: todas as regras previamente presentes no projeto devem manter seus
 * valores de severidade inalterados, e todas as regras presentes no archetype mas ausentes
 * no projeto devem ser adicionadas com seus valores padrão.
 *
 * **Validates: Requirements 9.4**
 *
 * Tag: "Feature: archetype-code-review, Property 2: Merge de review-rules preserva existentes e adiciona faltantes"
 */

const VALID_ARCHETYPES = [
  "backend-csharp",
  "bff-fastify",
  "frontend-react",
  "mobile-flutter",
] as const;

const VALID_SEVERITIES: RuleConfig["severity"][] = ["error", "warn", "disabled"];

/**
 * Gerador de nomes de regra válidos (snake_case alfanumérico).
 */
const ruleNameArb = fc
  .stringMatching(/^[a-z][a-z0-9_]{2,30}$/)
  .filter((s) => !s.endsWith("_"));

/**
 * Gerador de RuleConfig válido.
 */
const ruleConfigArb: fc.Arbitrary<RuleConfig> = fc.record({
  severity: fc.constantFrom(...VALID_SEVERITIES),
  description: fc.option(fc.string({ minLength: 1, maxLength: 80 }), {
    nil: undefined,
  }),
});

/**
 * Gerador de mapa de regras com pelo menos 1 entrada.
 */
const rulesMapArb = (minLength = 1, maxLength = 6) =>
  fc
    .uniqueArray(ruleNameArb, { minLength, maxLength })
    .chain((names) =>
      fc.tuple(...names.map(() => ruleConfigArb)).map((configs) => {
        const rules: Record<string, RuleConfig> = {};
        names.forEach((name, i) => {
          rules[name] = configs[i];
        });
        return rules;
      })
    );

/**
 * Gerador de agent_review válido (opcional).
 */
const agentReviewArb = fc.option(
  fc.record({
    enabled: fc.boolean(),
    agent: fc.option(fc.string({ minLength: 1, maxLength: 30 }), {
      nil: undefined,
    }),
    timeout_seconds: fc.option(fc.integer({ min: 30, max: 600 }), {
      nil: undefined,
    }),
  }),
  { nil: undefined }
);

/**
 * Gerador de ReviewRulesConfig arbitrária.
 */
const reviewRulesConfigArb = (
  minRules = 1,
  maxRules = 6
): fc.Arbitrary<ReviewRulesConfig> =>
  fc
    .tuple(
      fc.constant("1.0"),
      fc.constantFrom(...VALID_ARCHETYPES),
      agentReviewArb,
      rulesMapArb(minRules, maxRules)
    )
    .map(([version, archetype, agentReview, rules]) => {
      const config: ReviewRulesConfig = { version, archetype, rules };
      if (agentReview !== undefined) {
        config.agent_review = {
          enabled: agentReview.enabled,
          ...(agentReview.agent !== undefined && { agent: agentReview.agent }),
          ...(agentReview.timeout_seconds !== undefined && {
            timeout_seconds: agentReview.timeout_seconds,
          }),
        };
      }
      return config;
    });

describe("Feature: archetype-code-review, Property 2: Merge de review-rules preserva existentes e adiciona faltantes", () => {
  describe("Regras existentes mantêm seus valores exatos no resultado mergeado", () => {
    it("todas as regras de existingConfig preservam severity e description após merge", () => {
      fc.assert(
        fc.property(
          reviewRulesConfigArb(1, 5),
          reviewRulesConfigArb(1, 5),
          (archetypeConfig, existingConfig) => {
            const result = mergeReviewRules(archetypeConfig, existingConfig);

            for (const [ruleId, ruleConfig] of Object.entries(
              existingConfig.rules
            )) {
              expect(result.rules[ruleId]).toBeDefined();
              expect(result.rules[ruleId].severity).toBe(ruleConfig.severity);
              expect(result.rules[ruleId].description).toBe(
                ruleConfig.description
              );
            }
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Regras do archetype ausentes no existingConfig são adicionadas com valores do archetype", () => {
    it("regras do archetypeConfig que NÃO estão no existingConfig são adicionadas com valores do archetype", () => {
      fc.assert(
        fc.property(
          reviewRulesConfigArb(1, 5),
          reviewRulesConfigArb(1, 5),
          (archetypeConfig, existingConfig) => {
            const result = mergeReviewRules(archetypeConfig, existingConfig);

            for (const [ruleId, ruleConfig] of Object.entries(
              archetypeConfig.rules
            )) {
              if (!(ruleId in existingConfig.rules)) {
                expect(result.rules[ruleId]).toBeDefined();
                expect(result.rules[ruleId].severity).toBe(
                  ruleConfig.severity
                );
                expect(result.rules[ruleId].description).toBe(
                  ruleConfig.description
                );
              }
            }
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Resultado contém a união dos identificadores de regra de ambas as configs", () => {
    it("o resultado mergeado contém todas as regras de ambas as configs (union)", () => {
      fc.assert(
        fc.property(
          reviewRulesConfigArb(1, 5),
          reviewRulesConfigArb(1, 5),
          (archetypeConfig, existingConfig) => {
            const result = mergeReviewRules(archetypeConfig, existingConfig);

            const expectedKeys = new Set([
              ...Object.keys(archetypeConfig.rules),
              ...Object.keys(existingConfig.rules),
            ]);

            const resultKeys = new Set(Object.keys(result.rules));

            expect(resultKeys).toEqual(expectedKeys);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Metadata (version, archetype, agent_review) do existingConfig é preservada", () => {
    it("version, archetype e agent_review do existingConfig são mantidos no resultado", () => {
      fc.assert(
        fc.property(
          reviewRulesConfigArb(1, 5),
          reviewRulesConfigArb(1, 5),
          (archetypeConfig, existingConfig) => {
            const result = mergeReviewRules(archetypeConfig, existingConfig);

            expect(result.version).toBe(existingConfig.version);
            expect(result.archetype).toBe(existingConfig.archetype);
            expect(result.agent_review).toEqual(existingConfig.agent_review);
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
