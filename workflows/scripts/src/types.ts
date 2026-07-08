/**
 * Configuração de regras de code review lida do arquivo review-rules.yml.
 * Cada archetype define suas regras específicas com severidade configurável.
 */
export interface ReviewRulesConfig {
  /** Versão do schema de configuração */
  version: string;
  /** Identificador do archetype */
  archetype: string;
  /** Configuração opcional de revisão via Kiro Agent */
  agent_review?: {
    enabled: boolean;
    agent?: string;
    timeout_seconds?: number;
  };
  /** Mapa de regras identificadas por nome único */
  rules: Record<string, RuleConfig>;
}

/**
 * Configuração individual de uma regra de review.
 */
export interface RuleConfig {
  /** Severidade da regra: error bloqueia merge, warn alerta, disabled ignora */
  severity: "error" | "warn" | "disabled";
  /** Descrição legível da regra */
  description?: string;
}

/**
 * Resultado de execução de um step do workflow de review.
 */
export interface ReviewResult {
  /** Identificador do step executado */
  step: "lint" | "format" | "type_check" | "security" | "archetype_rules" | "agent";
  /** Status final do step */
  status: "pass" | "fail" | "error" | "skipped";
  /** Lista de violações encontradas */
  violations: Violation[];
}

/**
 * Violação individual detectada durante o review.
 */
export interface Violation {
  /** Identificador da regra violada */
  rule_id: string;
  /** Severidade da violação */
  severity: "error" | "warn";
  /** Caminho relativo do arquivo com a violação */
  file?: string;
  /** Número da linha no arquivo */
  line?: number;
  /** Mensagem descritiva da violação */
  message: string;
  /** Sugestão de correção */
  suggestion?: string;
}

/**
 * Relatório consolidado gerado após todas as verificações do workflow.
 */
export interface ConsolidatedReport {
  /** Status geral: approved (sem violações), blocked (erro), warnings_only (apenas avisos) */
  overall_status: "approved" | "blocked" | "warnings_only";
  /** Total de violações encontradas */
  total_violations: number;
  /** Quantidade de violações bloqueantes (severity=error) */
  blocking_violations: number;
  /** Quantidade de violações de aviso (severity=warn) */
  warning_violations: number;
  /** Seções agrupadas por tipo de verificação */
  sections: ReportSection[];
}

/**
 * Seção do relatório consolidado, agrupada por tipo de verificação.
 */
export interface ReportSection {
  /** Tipo da verificação (lint, format, type_check, security, archetype_rules, agent) */
  type: string;
  /** Título legível da seção */
  title: string;
  /** Status da seção */
  status: "pass" | "fail";
  /** Violações encontradas nesta seção */
  violations: Violation[];
}
