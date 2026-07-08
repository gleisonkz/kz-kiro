import type { ReviewRulesConfig, RuleConfig } from "./types.js";

/**
 * Resultado da filtragem de regras do review-rules.yml.
 */
export interface FilterResult {
  /** Regras ativas (não-disabled) que existem no archetype */
  activeRules: Record<string, RuleConfig>;
  /** Avisos sobre regras referenciadas que não existem no archetype */
  warnings: string[];
  /** Erros de configuração (ex: todas as regras disabled) */
  errors: string[];
}

/**
 * Filtra regras de uma configuração review-rules.yml com base na lista de regras
 * válidas do archetype. Remove regras disabled, detecta regras inexistentes no
 * archetype e valida que ao menos uma regra permanece ativa.
 *
 * @param config - Configuração de review-rules já validada
 * @param archetypeRules - Lista de identificadores de regras válidas do archetype
 * @returns Resultado com regras ativas, warnings e errors
 */
export function filterRules(
  config: ReviewRulesConfig,
  archetypeRules: string[]
): FilterResult {
  const activeRules: Record<string, RuleConfig> = {};
  const warnings: string[] = [];
  const errors: string[] = [];

  const archetypeRuleSet = new Set(archetypeRules);

  for (const [ruleId, ruleConfig] of Object.entries(config.rules)) {
    // Regras disabled são ignoradas completamente
    if (ruleConfig.severity === "disabled") {
      continue;
    }

    // Regras que não existem no archetype geram warning
    if (!archetypeRuleSet.has(ruleId)) {
      warnings.push(
        `Regra desconhecida: '${ruleId}' não existe no archetype`
      );
      continue;
    }

    // Regra válida e ativa
    activeRules[ruleId] = ruleConfig;
  }

  // Se todas as regras estão disabled, reportar erro de configuração
  const allDisabled = Object.values(config.rules).every(
    (rule) => rule.severity === "disabled"
  );

  if (allDisabled) {
    errors.push(
      "Erro de configuração: todas as regras estão desabilitadas. Pelo menos uma regra deve ter severidade 'error' ou 'warn'."
    );
  }

  return { activeRules, warnings, errors };
}
