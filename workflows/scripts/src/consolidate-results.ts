import type {
  ReviewResult,
  ConsolidatedReport,
  ReportSection,
  Violation,
} from "./types.js";

/**
 * Mapa de nomes legíveis para cada tipo de step.
 */
const STEP_TITLES: Record<string, string> = {
  lint: "Lint",
  format: "Formatação",
  type_check: "Type Check",
  security: "Segurança",
  archetype_rules: "Regras do Archetype",
  agent: "Revisão via Agent",
};

/**
 * Lista ordenada dos steps possíveis para garantir seções consistentes.
 */
const ALL_STEPS = [
  "lint",
  "format",
  "type_check",
  "security",
  "archetype_rules",
  "agent",
] as const;

/**
 * Determina o overall_status do relatório consolidado com base nas violações.
 * - Alguma violação com severity="error" → "blocked"
 * - Todas com severity="warn" → "warnings_only"
 * - Nenhuma violação → "approved"
 */
function determineOverallStatus(
  violations: Violation[]
): ConsolidatedReport["overall_status"] {
  if (violations.length === 0) {
    return "approved";
  }

  const hasError = violations.some((v) => v.severity === "error");
  if (hasError) {
    return "blocked";
  }

  return "warnings_only";
}

/**
 * Consolida resultados de múltiplos steps do workflow em um relatório único.
 *
 * Agrupa violações por step, calcula contagens e determina o status geral.
 * Inclui seções para todos os steps possíveis, mesmo sem violações.
 */
export function consolidateResults(
  results: ReviewResult[]
): ConsolidatedReport {
  // Agrupar violações por step
  const violationsByStep = new Map<string, Violation[]>();

  for (const step of ALL_STEPS) {
    violationsByStep.set(step, []);
  }

  for (const result of results) {
    const existing = violationsByStep.get(result.step) ?? [];
    existing.push(...result.violations);
    violationsByStep.set(result.step, existing);
  }

  // Construir seções do relatório
  const sections: ReportSection[] = ALL_STEPS.map((step) => {
    const violations = violationsByStep.get(step) ?? [];
    return {
      type: step,
      title: STEP_TITLES[step] ?? step,
      status: violations.length > 0 ? "fail" : "pass",
      violations,
    };
  });

  // Coletar todas as violações para contagem
  const allViolations = results.flatMap((r) => r.violations);

  const blockingViolations = allViolations.filter(
    (v) => v.severity === "error"
  ).length;
  const warningViolations = allViolations.filter(
    (v) => v.severity === "warn"
  ).length;

  return {
    overall_status: determineOverallStatus(allViolations),
    total_violations: allViolations.length,
    blocking_violations: blockingViolations,
    warning_violations: warningViolations,
    sections,
  };
}
