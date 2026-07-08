import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import * as yaml from "js-yaml";
import { validateReviewRules } from "./validate-review-rules.js";

/**
 * Property 6: Validação de schema do review-rules.yml
 *
 * Para qualquer YAML válido que adere ao JSON Schema definido, a validação deve retornar sucesso;
 * para qualquer YAML que viola o schema (campo obrigatório faltante, valor de enum inválido,
 * tipo incorreto), a validação deve retornar erro indicando o campo ou localização do problema.
 *
 * **Validates: Requirements 3.1, 3.5, 8.5, 8.6**
 *
 * Tag: "Feature: archetype-code-review, Property 6: Validação de schema do review-rules.yml"
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
const ruleConfigArb = fc.record({
  severity: fc.constantFrom(...VALID_SEVERITIES),
  description: fc.option(fc.string({ minLength: 1, maxLength: 100 }), {
    nil: undefined,
  }),
});

/**
 * Gerador de mapa de regras com pelo menos 1 entrada.
 */
const rulesMapArb = fc
  .uniqueArray(ruleNameArb, { minLength: 1, maxLength: 5 })
  .chain((names) =>
    fc.tuple(...names.map(() => ruleConfigArb)).map((configs) => {
      const rules: Record<string, { severity: string; description?: string }> =
        {};
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
 * Gerador de ReviewRulesConfig completa e válida.
 */
const validConfigArb = fc
  .tuple(
    fc.constant("1.0"),
    fc.constantFrom(...VALID_ARCHETYPES),
    agentReviewArb,
    rulesMapArb
  )
  .map(([version, archetype, agentReview, rules]) => {
    const config: Record<string, unknown> = { version, archetype, rules };
    if (agentReview !== undefined) {
      const ar: Record<string, unknown> = { enabled: agentReview.enabled };
      if (agentReview.agent !== undefined) ar.agent = agentReview.agent;
      if (agentReview.timeout_seconds !== undefined)
        ar.timeout_seconds = agentReview.timeout_seconds;
      config.agent_review = ar;
    }
    return config;
  });

/**
 * Gerador de config válida que garante pelo menos uma regra não-disabled.
 * (Para evitar falha pela regra de negócio "todas disabled".)
 */
const validConfigNotAllDisabledArb = validConfigArb.filter((config) => {
  const rules = config.rules as Record<
    string,
    { severity: string; description?: string }
  >;
  return Object.values(rules).some((r) => r.severity !== "disabled");
});

describe("Feature: archetype-code-review, Property 6: Validação de schema do review-rules.yml", () => {
  describe("Configs válidos → validação retorna sucesso", () => {
    it("qualquer config válido com pelo menos uma regra não-disabled deve passar na validação", () => {
      fc.assert(
        fc.property(validConfigNotAllDisabledArb, (config) => {
          const yamlContent = yaml.dump(config);
          const result = validateReviewRules(yamlContent);

          expect(result.valid).toBe(true);
          expect(result.errors).toHaveLength(0);
          expect(result.config).toBeDefined();
          expect(result.config!.version).toBe(config.version);
          expect(result.config!.archetype).toBe(config.archetype);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Configs inválidos - campo obrigatório faltante → erro com indicação do campo", () => {
    it("remoção de 'version' deve retornar erro indicando campo obrigatório", () => {
      fc.assert(
        fc.property(validConfigNotAllDisabledArb, (config) => {
          const mutated = { ...config };
          delete (mutated as Record<string, unknown>).version;
          const yamlContent = yaml.dump(mutated);
          const result = validateReviewRules(yamlContent);

          expect(result.valid).toBe(false);
          expect(result.errors.length).toBeGreaterThan(0);
          expect(
            result.errors.some(
              (e) =>
                e.message.includes("version") || e.field.includes("version")
            )
          ).toBe(true);
        }),
        { numRuns: 100 }
      );
    });

    it("remoção de 'archetype' deve retornar erro indicando campo obrigatório", () => {
      fc.assert(
        fc.property(validConfigNotAllDisabledArb, (config) => {
          const mutated = { ...config };
          delete (mutated as Record<string, unknown>).archetype;
          const yamlContent = yaml.dump(mutated);
          const result = validateReviewRules(yamlContent);

          expect(result.valid).toBe(false);
          expect(result.errors.length).toBeGreaterThan(0);
          expect(
            result.errors.some(
              (e) =>
                e.message.includes("archetype") ||
                e.field.includes("archetype")
            )
          ).toBe(true);
        }),
        { numRuns: 100 }
      );
    });

    it("remoção de 'rules' deve retornar erro indicando campo obrigatório", () => {
      fc.assert(
        fc.property(validConfigNotAllDisabledArb, (config) => {
          const mutated = { ...config };
          delete (mutated as Record<string, unknown>).rules;
          const yamlContent = yaml.dump(mutated);
          const result = validateReviewRules(yamlContent);

          expect(result.valid).toBe(false);
          expect(result.errors.length).toBeGreaterThan(0);
          expect(
            result.errors.some(
              (e) => e.message.includes("rules") || e.field.includes("rules")
            )
          ).toBe(true);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Configs inválidos - enum inválido → erro com indicação do campo", () => {
    it("version com valor fora do enum deve retornar erro", () => {
      const invalidVersionArb = fc
        .string({ minLength: 1, maxLength: 10 })
        .filter((s) => s !== "1.0");

      fc.assert(
        fc.property(
          validConfigNotAllDisabledArb,
          invalidVersionArb,
          (config, invalidVersion) => {
            const mutated = { ...config, version: invalidVersion };
            const yamlContent = yaml.dump(mutated);
            const result = validateReviewRules(yamlContent);

            expect(result.valid).toBe(false);
            expect(result.errors.length).toBeGreaterThan(0);
            expect(
              result.errors.some(
                (e) =>
                  e.field.includes("version") ||
                  e.message.includes("Valores permitidos")
              )
            ).toBe(true);
          }
        ),
        { numRuns: 100 }
      );
    });

    it("archetype com valor fora do enum deve retornar erro", () => {
      const invalidArchetypeArb = fc
        .string({ minLength: 1, maxLength: 30 })
        .filter(
          (s) =>
            !VALID_ARCHETYPES.includes(
              s as (typeof VALID_ARCHETYPES)[number]
            )
        );

      fc.assert(
        fc.property(
          validConfigNotAllDisabledArb,
          invalidArchetypeArb,
          (config, invalidArchetype) => {
            const mutated = { ...config, archetype: invalidArchetype };
            const yamlContent = yaml.dump(mutated);
            const result = validateReviewRules(yamlContent);

            expect(result.valid).toBe(false);
            expect(result.errors.length).toBeGreaterThan(0);
            expect(
              result.errors.some(
                (e) =>
                  e.field.includes("archetype") ||
                  e.message.includes("Valores permitidos")
              )
            ).toBe(true);
          }
        ),
        { numRuns: 100 }
      );
    });

    it("severity com valor fora do enum deve retornar erro", () => {
      const invalidSeverityArb = fc
        .string({ minLength: 1, maxLength: 20 })
        .filter(
          (s) =>
            !["error", "warn", "disabled"].includes(s)
        );

      fc.assert(
        fc.property(
          validConfigNotAllDisabledArb,
          invalidSeverityArb,
          (config, invalidSeverity) => {
            const rules = config.rules as Record<
              string,
              { severity: string; description?: string }
            >;
            const ruleNames = Object.keys(rules);
            // Mutar a primeira regra com severity inválida
            const mutatedRules = { ...rules };
            mutatedRules[ruleNames[0]] = {
              ...mutatedRules[ruleNames[0]],
              severity: invalidSeverity,
            };
            const mutated = { ...config, rules: mutatedRules };
            const yamlContent = yaml.dump(mutated);
            const result = validateReviewRules(yamlContent);

            expect(result.valid).toBe(false);
            expect(result.errors.length).toBeGreaterThan(0);
            expect(
              result.errors.some(
                (e) =>
                  e.field.includes("severity") ||
                  e.message.includes("Valores permitidos")
              )
            ).toBe(true);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Configs inválidos - tipo errado → erro com indicação do campo", () => {
    it("version com tipo não-string deve retornar erro", () => {
      const nonStringArb = fc.oneof(
        fc.integer(),
        fc.boolean(),
        fc.constant(null)
      );

      fc.assert(
        fc.property(
          validConfigNotAllDisabledArb,
          nonStringArb,
          (config, wrongType) => {
            const mutated = { ...config, version: wrongType };
            const yamlContent = yaml.dump(mutated);
            const result = validateReviewRules(yamlContent);

            expect(result.valid).toBe(false);
            expect(result.errors.length).toBeGreaterThan(0);
            expect(
              result.errors.some(
                (e) =>
                  e.field.includes("version") ||
                  e.message.includes("tipo") ||
                  e.message.includes("Valores permitidos")
              )
            ).toBe(true);
          }
        ),
        { numRuns: 100 }
      );
    });

    it("rules como array ou string deve retornar erro de tipo", () => {
      const wrongTypeRulesArb = fc.oneof(
        fc.constant("not-an-object"),
        fc.array(fc.string(), { minLength: 1, maxLength: 3 }),
        fc.constant(42),
        fc.constant(true)
      );

      fc.assert(
        fc.property(
          validConfigNotAllDisabledArb,
          wrongTypeRulesArb,
          (config, wrongRules) => {
            const mutated = { ...config, rules: wrongRules };
            const yamlContent = yaml.dump(mutated);
            const result = validateReviewRules(yamlContent);

            expect(result.valid).toBe(false);
            expect(result.errors.length).toBeGreaterThan(0);
          }
        ),
        { numRuns: 100 }
      );
    });

    it("agent_review.enabled com tipo não-boolean deve retornar erro", () => {
      const nonBooleanArb = fc.oneof(
        fc.string({ minLength: 1, maxLength: 10 }),
        fc.integer()
      );

      fc.assert(
        fc.property(
          validConfigNotAllDisabledArb,
          nonBooleanArb,
          (config, wrongEnabled) => {
            const mutated = {
              ...config,
              agent_review: { enabled: wrongEnabled },
            };
            const yamlContent = yaml.dump(mutated);
            const result = validateReviewRules(yamlContent);

            expect(result.valid).toBe(false);
            expect(result.errors.length).toBeGreaterThan(0);
            expect(
              result.errors.some(
                (e) =>
                  e.field.includes("enabled") ||
                  e.field.includes("agent_review") ||
                  e.message.includes("tipo") ||
                  e.message.includes("type")
              )
            ).toBe(true);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Regra de negócio: todas as regras disabled → erro de configuração", () => {
    it("config com todas as regras disabled deve retornar erro indicando /rules", () => {
      const allDisabledRulesArb = fc
        .uniqueArray(ruleNameArb, { minLength: 1, maxLength: 5 })
        .map((names) => {
          const rules: Record<string, { severity: string; description?: string }> = {};
          names.forEach((name) => {
            rules[name] = { severity: "disabled" };
          });
          return rules;
        });

      fc.assert(
        fc.property(
          fc.constantFrom(...VALID_ARCHETYPES),
          allDisabledRulesArb,
          (archetype, rules) => {
            const config = { version: "1.0", archetype, rules };
            const yamlContent = yaml.dump(config);
            const result = validateReviewRules(yamlContent);

            expect(result.valid).toBe(false);
            expect(result.errors.length).toBeGreaterThan(0);
            expect(
              result.errors.some(
                (e) =>
                  e.field === "/rules" && e.message.includes("desabilitadas")
              )
            ).toBe(true);
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
