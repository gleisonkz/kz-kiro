import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { filterRules } from "./filter-rules.js";
import type { ReviewRulesConfig, RuleConfig } from "./types.js";

/**
 * Property 8: Filtragem de regras disabled
 *
 * Para qualquer ReviewRulesConfig onde pelo menos uma regra tem severidade diferente de "disabled":
 * regras com severity = "disabled" devem ser ignoradas (não geram violações nem alertas).
 * Se todas as regras estiverem "disabled", o sistema deve retornar erro de configuração.
 *
 * **Validates: Requirements 8.2**
 *
 * Tag: "Feature: archetype-code-review, Property 8: Filtragem de regras disabled"
 */

const VALID_ARCHETYPES = [
  "backend-csharp",
  "bff-fastify",
  "frontend-react",
  "mobile-flutter",
] as const;

const VALID_SEVERITIES = ["error", "warn", "disabled"] as const;

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
  description: fc.option(fc.string({ minLength: 1, maxLength: 100 }), {
    nil: undefined,
  }),
});

/**
 * Gerador de mapa de regras com pelo menos 1 entrada.
 */
const rulesMapArb = fc
  .uniqueArray(ruleNameArb, { minLength: 1, maxLength: 8 })
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
 * Gerador de ReviewRulesConfig completa.
 */
const configArb: fc.Arbitrary<ReviewRulesConfig> = fc
  .tuple(
    fc.constantFrom(...VALID_ARCHETYPES),
    rulesMapArb
  )
  .map(([archetype, rules]) => ({
    version: "1.0",
    archetype,
    rules,
  }));

/**
 * Gerador de config que garante pelo menos uma regra não-disabled.
 */
const configWithActiveRulesArb = configArb.filter((config) =>
  Object.values(config.rules).some((r) => r.severity !== "disabled")
);

/**
 * Gerador de config onde TODAS as regras são disabled.
 */
const allDisabledConfigArb = fc
  .tuple(
    fc.constantFrom(...VALID_ARCHETYPES),
    fc.uniqueArray(ruleNameArb, { minLength: 1, maxLength: 8 })
  )
  .map(([archetype, names]): ReviewRulesConfig => ({
    version: "1.0",
    archetype,
    rules: Object.fromEntries(
      names.map((name) => [name, { severity: "disabled" as const }])
    ),
  }));

describe("Feature: archetype-code-review, Property 8: Filtragem de regras disabled", () => {
  describe("Regras disabled não aparecem em activeRules", () => {
    it("qualquer regra com severity='disabled' NÃO deve aparecer em activeRules", () => {
      fc.assert(
        fc.property(configArb, (config) => {
          // archetypeRules inclui todas as regras da config para não interferir com warnings
          const archetypeRules = Object.keys(config.rules);
          const result = filterRules(config, archetypeRules);

          const disabledRuleIds = Object.entries(config.rules)
            .filter(([, rule]) => rule.severity === "disabled")
            .map(([id]) => id);

          for (const ruleId of disabledRuleIds) {
            expect(result.activeRules).not.toHaveProperty(ruleId);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Regras com severity 'error' ou 'warn' existentes no archetype aparecem em activeRules", () => {
    it("regras ativas que existem no archetypeRules devem aparecer em activeRules", () => {
      fc.assert(
        fc.property(configWithActiveRulesArb, (config) => {
          // archetypeRules inclui todas as regras da config
          const archetypeRules = Object.keys(config.rules);
          const result = filterRules(config, archetypeRules);

          const activeRuleIds = Object.entries(config.rules)
            .filter(([, rule]) => rule.severity !== "disabled")
            .map(([id]) => id);

          for (const ruleId of activeRuleIds) {
            expect(result.activeRules).toHaveProperty(ruleId);
            expect(result.activeRules[ruleId].severity).toBe(
              config.rules[ruleId].severity
            );
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Todas as regras disabled → errors contém mensagem de erro", () => {
    it("se TODAS as regras são 'disabled', errors deve conter mensagem de erro de configuração", () => {
      fc.assert(
        fc.property(allDisabledConfigArb, (config) => {
          const archetypeRules = Object.keys(config.rules);
          const result = filterRules(config, archetypeRules);

          expect(result.errors.length).toBeGreaterThan(0);
          expect(
            result.errors.some(
              (e) =>
                e.toLowerCase().includes("desabilitada") ||
                e.toLowerCase().includes("disabled") ||
                e.toLowerCase().includes("erro de configuração")
            )
          ).toBe(true);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Ao menos uma regra não-disabled → errors vazio (em relação a disabled check)", () => {
    it("se ao menos uma regra NÃO é disabled, errors NÃO deve conter erro de 'todas disabled'", () => {
      fc.assert(
        fc.property(configWithActiveRulesArb, (config) => {
          // archetypeRules inclui todas as regras para evitar warnings de regras inexistentes
          const archetypeRules = Object.keys(config.rules);
          const result = filterRules(config, archetypeRules);

          // Não deve haver erros sobre "todas desabilitadas"
          const allDisabledErrors = result.errors.filter(
            (e) =>
              e.toLowerCase().includes("desabilitada") ||
              e.toLowerCase().includes("disabled")
          );
          expect(allDisabledErrors).toHaveLength(0);
        }),
        { numRuns: 100 }
      );
    });
  });
});
