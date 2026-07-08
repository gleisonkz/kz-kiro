import type { ReviewRulesConfig } from "./types.js";

/**
 * Realiza o merge de duas configurações de review-rules.yml.
 *
 * A lógica preserva todas as regras e configurações já existentes no projeto (existingConfig)
 * e adiciona apenas as regras presentes no archetype que estejam faltando, usando os valores
 * padrão do archetype.
 *
 * @param archetypeConfig - Configuração padrão do archetype (fonte de regras faltantes)
 * @param existingConfig - Configuração atual do projeto (tem prioridade na preservação)
 * @returns Configuração mergeada com regras existentes preservadas e faltantes adicionadas
 */
export function mergeReviewRules(
  archetypeConfig: ReviewRulesConfig,
  existingConfig: ReviewRulesConfig
): ReviewRulesConfig {
  const mergedRules = { ...existingConfig.rules };

  for (const [ruleId, ruleConfig] of Object.entries(archetypeConfig.rules)) {
    if (!(ruleId in mergedRules)) {
      mergedRules[ruleId] = { ...ruleConfig };
    }
  }

  return {
    version: existingConfig.version,
    archetype: existingConfig.archetype,
    agent_review: existingConfig.agent_review,
    rules: mergedRules,
  };
}
