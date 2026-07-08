/**
 * Formata a saída textual de um Review Agent em markdown estruturado
 * para publicação como PR Comment.
 *
 * Heurísticas de parsing:
 * - Linhas com "ERROR:" ou "WARN:" indicam início de um novo issue
 * - Linhas com "FILE:" indicam localização no código
 * - Linhas com "SUGGESTION:" indicam sugestão de correção
 * - Texto entre marcadores é tratado como descrição do problema
 */

/** Severidades reconhecidas pelo parser */
type Severity = "error" | "warn";

/** Issue individual extraído do output do agent */
interface AgentIssue {
  severity: Severity;
  title: string;
  file?: string;
  line?: number;
  description: string;
  suggestion?: string;
}

/** Ícone de severidade para markdown */
const SEVERITY_ICONS: Record<Severity, string> = {
  error: "🚫",
  warn: "⚠️",
};

/** Labels legíveis para severidade */
const SEVERITY_LABELS: Record<Severity, string> = {
  error: "Error",
  warn: "Warning",
};

/**
 * Extrai o número da linha de uma referência de arquivo.
 * Suporta formatos: "arquivo.ts:42", "arquivo.ts(42)", "arquivo.ts line 42"
 */
function parseFileLocation(raw: string): { file: string; line?: number } {
  // Formato "arquivo.ts:42"
  const colonMatch = raw.match(/^(.+):(\d+)$/);
  if (colonMatch) {
    return { file: colonMatch[1].trim(), line: parseInt(colonMatch[2], 10) };
  }

  // Formato "arquivo.ts(42)"
  const parenMatch = raw.match(/^(.+)\((\d+)\)$/);
  if (parenMatch) {
    return { file: parenMatch[1].trim(), line: parseInt(parenMatch[2], 10) };
  }

  // Formato "arquivo.ts line 42"
  const lineMatch = raw.match(/^(.+)\s+line\s+(\d+)$/i);
  if (lineMatch) {
    return { file: lineMatch[1].trim(), line: parseInt(lineMatch[2], 10) };
  }

  return { file: raw.trim() };
}

/**
 * Faz o parsing do output textual do agent em uma lista de issues estruturados.
 */
function parseAgentOutput(agentOutput: string): AgentIssue[] {
  const lines = agentOutput.split("\n");
  const issues: AgentIssue[] = [];
  let current: Partial<AgentIssue> | null = null;
  let descriptionLines: string[] = [];

  const flushCurrent = () => {
    if (current && current.severity && current.title) {
      issues.push({
        severity: current.severity,
        title: current.title,
        file: current.file,
        line: current.line,
        description: descriptionLines.join("\n").trim(),
        suggestion: current.suggestion,
      });
    }
    current = null;
    descriptionLines = [];
  };

  for (const rawLine of lines) {
    const line = rawLine.trim();

    // Detectar início de novo issue com ERROR: ou WARN:
    const errorMatch = line.match(/^ERROR:\s*(.+)$/i);
    if (errorMatch) {
      flushCurrent();
      current = { severity: "error", title: errorMatch[1].trim() };
      continue;
    }

    const warnMatch = line.match(/^WARN(?:ING)?:\s*(.+)$/i);
    if (warnMatch) {
      flushCurrent();
      current = { severity: "warn", title: warnMatch[1].trim() };
      continue;
    }

    // Se não estamos dentro de um issue, ignorar a linha
    if (!current) {
      continue;
    }

    // Detectar localização de arquivo
    const fileMatch = line.match(/^FILE:\s*(.+)$/i);
    if (fileMatch) {
      const location = parseFileLocation(fileMatch[1].trim());
      current.file = location.file;
      current.line = location.line;
      continue;
    }

    // Detectar sugestão
    const suggestionMatch = line.match(/^SUGGESTION:\s*(.+)$/i);
    if (suggestionMatch) {
      current.suggestion = suggestionMatch[1].trim();
      continue;
    }

    // Qualquer outra linha é parte da descrição
    if (line.length > 0) {
      descriptionLines.push(line);
    }
  }

  // Flush do último issue
  flushCurrent();

  return issues;
}

/**
 * Formata um único issue como seção markdown.
 */
function formatIssue(issue: AgentIssue): string {
  const icon = SEVERITY_ICONS[issue.severity];
  const label = SEVERITY_LABELS[issue.severity];
  const parts: string[] = [];

  parts.push(`### ${icon} [${label}] ${issue.title}`);
  parts.push("");

  if (issue.file) {
    const locationStr = issue.line
      ? `\`${issue.file}:${issue.line}\``
      : `\`${issue.file}\``;
    parts.push(`**Localização:** ${locationStr}`);
    parts.push("");
  }

  if (issue.description) {
    parts.push(issue.description);
    parts.push("");
  }

  if (issue.suggestion) {
    parts.push(`**Sugestão:** ${issue.suggestion}`);
    parts.push("");
  }

  return parts.join("\n");
}

/**
 * Formata a saída do Review Agent como markdown estruturado para PR Comment.
 *
 * @param agentOutput - Texto livre produzido pelo Review Agent
 * @returns Markdown formatado com seções de issues encontrados
 */
export function formatAgentFeedback(agentOutput: string): string {
  if (!agentOutput || agentOutput.trim().length === 0) {
    return "## 🤖 Revisão via Agent\n\nNenhum feedback produzido pelo agent.";
  }

  const issues = parseAgentOutput(agentOutput);

  if (issues.length === 0) {
    return "## 🤖 Revisão via Agent\n\nNenhum problema identificado pelo agent.";
  }

  const sections = issues.map(formatIssue);
  const separator = "---\n\n";

  return `## 🤖 Revisão via Agent\n\n${sections.join(separator)}`.trimEnd();
}
