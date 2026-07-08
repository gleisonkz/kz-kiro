import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { filterRules } from "./filter-rules.js";
import type { ReviewRulesConfig, RuleConfig } from "./types.js";

/**
 * Property 9: Tolerância a regras inexistentes
 *
 * Para qualquer review-rules.yml que referencia identificadores de regra que não existem
 * no archetype do projeto, o sistema deve: gerar um alerta para cada regra desconhecida,
 * continuar a execução aplicando apenas as regras válidas, e não alterar o status final
 * por causa de regras inexistentes.
 *
 * **Validates: Requirements 8.7**
 *
 * Tag: "Feature: archetype-code-review, Property 9: Tolerância a regras inexistentes"
 */

const VALID_ARCHETYPES = [
  "backend-csharp",
  "bff-fastify",
  "frontend-react",
  "mobile-flutter",
] as const;

const VALID_SEVERITIES = ["error", "warn", "disabled"] as const;
const ACTIVE_SEVERITIES = ["error", "warn"] as const;

/**
 * Gerador de nomes de regra válidos (snake_case alfanumérico).
 */
const ruleNameArb = fc
  .stringMatching(/^[a-z][a-z0-9_]{2,30}$/)
  .filter((s) => !s.endsWith("_"));

/**
 * Gerador de RuleConfig válido com severidade ativa (não-disabled).
 */
const activeRuleConfigArb = fc.record({
  severity: fc.constantFrom(...ACTIVE_SEVERITIES) as fc.Arbitrary<
    "error" | "warn" | "disabled"
  >,
  description: fc.option(fc.string({ minLength: 1, maxLength: 80 }), {
    nil: undefined,
  }),
});

/**
 * Gerador de RuleConfig com qualquer severidade.
 */
const anyRuleConfigArb = fc.record({
  severity: fc.constantFrom(...VALID_SEVERITIES),
  description: fc.option(fc.string({ minLength: 1, maxLength: 80 }), {
    nil: undefined,
  }),
});


/**
 * Gera um cenário com um mix de regras conhecidas (existem no archetype) e desconhecidas.
 * Garante pelo menos 1 regra desconhecida ativa (não-disabled).
 */
const mixedRulesScenarioArb = fc
  .tuple(
    // Nomes de regras que existem no archetype
    fc.uniqueArray(ruleNameArb, { minLength: 1, maxLength: 5 }),
    // Nomes de regras desconhecidas (não existem no archetype)
    fc.uniqueArray(ruleNameArb, { minLength: 1, maxLength: 5 })
  )
  .filter(([known, unknown]) => {
    // Garantir que não há sobreposição entre conhecidas e desconhecidas
    const knownSet = new Set(known);
    return unknown.every((name) => !knownSet.has(name));
  })
  .chain(([knownNames, unknownNames]) =>
    fc
      .tuple(
        // Configs para regras conhecidas (ativas para que apareçam em activeRules)
        fc.tuple(...knownNames.map(() => activeRuleConfigArb)),
        // Configs para regras desconhecidas (ativas para gerar warnings)
        fc.tuple(...unknownNames.map(() => activeRuleConfigArb))
      )
      .map(([knownConfigs, unknownConfigs]) => {
        const rules: Record<string, RuleConfig> = {};
        knownNames.forEach((name, i) => {
          rules[name] = knownConfigs[i];
        });
        unknownNames.forEach((name, i) => {
          rules[name] = unknownConfigs[i];
        });

        const config: ReviewRulesConfig = {
          version: "1.0",
          archetype: "backend-csharp",
          rules,
        };

        return {
          config,
          knownNames,
          unknownNames,
          archetypeRules: knownNames, // Somente as regras "conhecidas" existem no archetype
        };
      })
  );

/**
 * Gera cenário com regras desconhecidas mixed com disabled e active.
 */
const mixedWithDisabledScenarioArb = fc
  .tuple(
    fc.uniqueArray(ruleNameArb, { minLength: 1, maxLength: 4 }),
    fc.uniqueArray(ruleNameArb, { minLength: 1, maxLength: 4 }),
    fc.constantFrom(...VALID_ARCHETYPES)
  )
  .filter(([known, unknown]) => {
    const knownSet = new Set(known);
    return unknown.every((name) => !knownSet.has(name));
  })
  .chain(([knownNames, unknownNames, archetype]) =>
    fc
      .tuple(
        fc.tuple(...knownNames.map(() => anyRuleConfigArb)),
        fc.tuple(...unknownNames.map(() => anyRuleConfigArb))
      )
      .map(([knownConfigs, unknownConfigs]) => {
        const rules: Record<string, RuleConfig> = {};
        knownNames.forEach((name, i) => {
          rules[name] = knownConfigs[i];
        });
        unknownNames.forEach((name, i) => {
          rules[name] = unknownConfigs[i];
        });

        const config: ReviewRulesConfig = {
          version: "1.0",
          archetype,
          rules,
        };

        return {
          config,
          knownNames,
          unknownNames,
          archetypeRules: knownNames,
        };
      })
  );

describe("Feature: archetype-code-review, Property 9: Tolerância a regras inexistentes", () => {
  describe("Regras desconhecidas geram warnings", () => {
    it("cada regra ativa que não existe no archetype deve gerar exatamente um warning", () => {
      fc.assert(
        fc.property(mixedRulesScenarioArb, (scenario) => {
          const { config, unknownNames, archetypeRules } = scenario;
          const result = filterRules(config, archetypeRules);

          // Cada regra desconhecida ativa deve gerar exatamente um warning
          for (const unknownName of unknownNames) {
            const warningsForRule = result.warnings.filter((w) =>
              w.includes(unknownName)
            );
            expect(warningsForRule).toHaveLength(1);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Regras desconhecidas NÃO aparecem em activeRules", () => {
    it("nenhuma regra desconhecida deve estar presente em activeRules", () => {
      fc.assert(
        fc.property(mixedRulesScenarioArb, (scenario) => {
          const { config, unknownNames, archetypeRules } = scenario;
          const result = filterRules(config, archetypeRules);

          for (const unknownName of unknownNames) {
            expect(result.activeRules).not.toHaveProperty(unknownName);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Regras válidas permanecem em activeRules", () => {
    it("regras conhecidas e não-disabled devem aparecer em activeRules", () => {
      fc.assert(
        fc.property(mixedRulesScenarioArb, (scenario) => {
          const { config, knownNames, archetypeRules } = scenario;
          const result = filterRules(config, archetypeRules);

          for (const knownName of knownNames) {
            const ruleConfig = config.rules[knownName];
            if (ruleConfig.severity !== "disabled") {
              expect(result.activeRules).toHaveProperty(knownName);
              expect(result.activeRules[knownName]).toEqual(ruleConfig);
            }
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Regras desconhecidas NÃO causam erros", () => {
    it("a presença de regras desconhecidas não deve adicionar itens ao array de errors", () => {
      fc.assert(
        fc.property(mixedWithDisabledScenarioArb, (scenario) => {
          const { config, unknownNames, knownNames, archetypeRules } = scenario;
          const result = filterRules(config, archetypeRules);

          // Verificar que nenhuma mensagem de erro menciona regras desconhecidas
          for (const unknownName of unknownNames) {
            const errorsForRule = result.errors.filter((e) =>
              e.includes(unknownName)
            );
            expect(errorsForRule).toHaveLength(0);
          }

          // Erros só devem ocorrer por regras de negócio válidas (ex: todas disabled)
          // e nunca por causa de regras inexistentes
          const hasActiveKnownRules = knownNames.some(
            (name) => config.rules[name]?.severity !== "disabled"
          );
          const allRulesDisabled = Object.values(config.rules).every(
            (r) => r.severity === "disabled"
          );

          if (allRulesDisabled) {
            // Se TODAS as regras estão disabled, erro de configuração é esperado
            expect(result.errors.length).toBeGreaterThan(0);
          } else if (hasActiveKnownRules) {
            // Se há regras válidas ativas, não deve haver erros
            expect(result.errors).toHaveLength(0);
          }
        }),
        { numRuns: 100 }
      );
    });
  });
});
