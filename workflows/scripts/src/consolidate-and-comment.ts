#!/usr/bin/env tsx
/**
 * Script CLI de consolidação de resultados de code review e publicação como PR comment.
 *
 * Lê arquivos JSON de /tmp/review-results/*.json (ou RESULTS_DIR),
 * consolida via consolidateResults(), gera markdown formatado e publica
 * como comentário no PR via GitHub API.
 *
 * Variáveis de ambiente:
 * - GITHUB_TOKEN: token para autenticação na API do GitHub
 * - GITHUB_REPOSITORY: owner/repo (ex: "org/repo")
 * - PR_NUMBER: número do PR (alternativa: lido de GITHUB_EVENT_PATH)
 * - GITHUB_EVENT_PATH: caminho para o JSON do evento (fallback para PR_NUMBER)
 * - RESULTS_DIR: diretório com os JSONs de resultado (default: /tmp/review-results)
 */

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { consolidateResults } from "./consolidate-results.js";
import { formatAgentFeedback } from "./format-agent-feedback.js";
import type {
  ReviewResult,
  ConsolidatedReport,
  ReportSection,
  Violation,
} from "./types.js";

// ─── Constantes ──────────────────────────────────────────────────────────────

/** Marcador único para identificar comentários do bot e permitir atualização */
const BOT_COMMENT_MARKER = "<!-- archetype-code-review-bot -->";

/** Títulos das seções no markdown de saída */
const SECTION_TITLES: Record<string, string> = {
  lint: "🧹 Lint",
  format: "🎨 Formatação",
  type_check: "🔍 Type Check",
  security: "🔒 Segurança",
  archetype_rules: "📐 Regras do Archetype",
  agent: "🤖 Revisão via Agent",
};

// ─── Leitura de ambiente ─────────────────────────────────────────────────────

interface EnvConfig {
  githubToken: string;
  owner: string;
  repo: string;
  prNumber: number;
  resultsDir: string;
}

/**
 * Extrai o número do PR a partir do arquivo de evento do GitHub Actions.
 */
function getPrNumberFromEvent(eventPath: string): number | null {
  try {
    const event = JSON.parse(readFileSync(eventPath, "utf-8"));
    const prNumber = event?.pull_request?.number ?? event?.number;
    return typeof prNumber === "number" ? prNumber : null;
  } catch {
    return null;
  }
}

/**
 * Lê e valida as variáveis de ambiente necessárias.
 */
export function loadEnvConfig(): EnvConfig {
  const githubToken = process.env.GITHUB_TOKEN;
  if (!githubToken) {
    throw new Error("Variável GITHUB_TOKEN não definida.");
  }

  const repository = process.env.GITHUB_REPOSITORY;
  if (!repository || !repository.includes("/")) {
    throw new Error(
      "Variável GITHUB_REPOSITORY não definida ou formato inválido (esperado: owner/repo)."
    );
  }

  const [owner, repo] = repository.split("/");

  let prNumber: number | null = null;

  // Tentar PR_NUMBER primeiro
  if (process.env.PR_NUMBER) {
    prNumber = parseInt(process.env.PR_NUMBER, 10);
    if (isNaN(prNumber)) {
      prNumber = null;
    }
  }

  // Fallback: GITHUB_EVENT_PATH
  if (!prNumber && process.env.GITHUB_EVENT_PATH) {
    prNumber = getPrNumberFromEvent(process.env.GITHUB_EVENT_PATH);
  }

  if (!prNumber) {
    throw new Error(
      "Não foi possível determinar o número do PR. Defina PR_NUMBER ou GITHUB_EVENT_PATH."
    );
  }

  const resultsDir = process.env.RESULTS_DIR ?? "/tmp/review-results";

  return { githubToken, owner, repo, prNumber, resultsDir };
}

// ─── Leitura de resultados ───────────────────────────────────────────────────

/**
 * Lê todos os arquivos .json do diretório de resultados e os parseia como ReviewResult.
 */
export function readResults(resultsDir: string): ReviewResult[] {
  if (!existsSync(resultsDir)) {
    console.warn(`Diretório de resultados não encontrado: ${resultsDir}`);
    return [];
  }

  const files = readdirSync(resultsDir).filter((f) => f.endsWith(".json"));

  if (files.length === 0) {
    console.warn(`Nenhum arquivo .json encontrado em: ${resultsDir}`);
    return [];
  }

  const results: ReviewResult[] = [];

  for (const file of files) {
    const filePath = join(resultsDir, file);
    try {
      const content = readFileSync(filePath, "utf-8");
      const parsed = JSON.parse(content) as ReviewResult;
      results.push(parsed);
    } catch (err) {
      console.error(`Erro ao ler/parsear ${filePath}:`, err);
    }
  }

  return results;
}

// ─── Geração de Markdown ─────────────────────────────────────────────────────

/**
 * Formata uma violação individual como linha de tabela markdown.
 */
function formatViolationRow(violation: Violation): string {
  const location = violation.file
    ? violation.line
      ? `\`${violation.file}:${violation.line}\``
      : `\`${violation.file}\``
    : "—";

  const severity = violation.severity === "error" ? "🚫 Error" : "⚠️ Warning";
  const suggestion = violation.suggestion ?? "—";

  return `| ${severity} | ${location} | ${violation.message} | ${suggestion} |`;
}

/**
 * Formata uma seção do relatório com violações como tabela markdown.
 */
function formatSection(section: ReportSection): string {
  const title = SECTION_TITLES[section.type] ?? section.title;

  if (section.violations.length === 0) {
    return `### ${title}\n\n✅ Nenhum problema encontrado.\n`;
  }

  const header = `### ${title}\n\n| Severidade | Localização | Mensagem | Sugestão |\n|---|---|---|---|`;
  const rows = section.violations.map(formatViolationRow).join("\n");

  return `${header}\n${rows}\n`;
}

/**
 * Gera o markdown completo do PR comment a partir do relatório consolidado.
 * Usa formatAgentFeedback() para a seção do agent quando há violações nela.
 */
export function generateMarkdown(
  report: ConsolidatedReport,
  agentRawOutput?: string
): string {
  const parts: string[] = [];

  // Marcador para identificação do comentário do bot
  parts.push(BOT_COMMENT_MARKER);
  parts.push("");

  // Header
  parts.push("## 🔍 Code Review Automatizado");
  parts.push("");

  // Status geral
  switch (report.overall_status) {
    case "approved":
      parts.push("✅ **Todas as verificações passaram!**");
      parts.push("");
      break;
    case "blocked":
      parts.push("❌ **Merge bloqueado**");
      parts.push("");
      parts.push(
        `> ${report.blocking_violations} erro(s) bloqueante(s) e ${report.warning_violations} aviso(s) encontrados.`
      );
      parts.push("");
      break;
    case "warnings_only":
      parts.push("⚠️ **Avisos encontrados**");
      parts.push("");
      parts.push(
        `> ${report.warning_violations} aviso(s) encontrados. O merge não está bloqueado.`
      );
      parts.push("");
      break;
  }

  // Seções detalhadas (apenas se não for approved)
  if (report.overall_status !== "approved") {
    for (const section of report.sections) {
      // Se é a seção de agent e temos raw output, usar formatAgentFeedback
      if (section.type === "agent" && agentRawOutput) {
        parts.push(formatAgentFeedback(agentRawOutput));
        parts.push("");
        continue;
      }

      // Apenas exibir seções que têm violações
      if (section.violations.length > 0) {
        parts.push(formatSection(section));
      }
    }
  }

  // Resumo
  parts.push("---");
  parts.push("");
  parts.push(
    `📊 **Resumo:** ${report.total_violations} violação(ões) | ${report.blocking_violations} bloqueante(s) | ${report.warning_violations} aviso(s)`
  );

  return parts.join("\n");
}

// ─── GitHub API ──────────────────────────────────────────────────────────────

/**
 * Busca comentário existente do bot no PR para atualização.
 */
async function findExistingComment(
  owner: string,
  repo: string,
  prNumber: number,
  token: string
): Promise<number | null> {
  const url = `https://api.github.com/repos/${owner}/${repo}/issues/${prNumber}/comments?per_page=100`;

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.github.v3+json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });

  if (!response.ok) {
    console.error(
      `Erro ao buscar comentários: ${response.status} ${response.statusText}`
    );
    return null;
  }

  const comments = (await response.json()) as Array<{
    id: number;
    body?: string;
  }>;
  const existing = comments.find((c) =>
    c.body?.includes(BOT_COMMENT_MARKER)
  );

  return existing?.id ?? null;
}

/**
 * Cria ou atualiza o comentário do bot no PR.
 */
async function postOrUpdateComment(
  owner: string,
  repo: string,
  prNumber: number,
  token: string,
  body: string
): Promise<void> {
  const existingId = await findExistingComment(owner, repo, prNumber, token);

  if (existingId) {
    // Atualizar comentário existente
    const url = `https://api.github.com/repos/${owner}/${repo}/issues/comments/${existingId}`;
    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github.v3+json",
        "Content-Type": "application/json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      body: JSON.stringify({ body }),
    });

    if (!response.ok) {
      throw new Error(
        `Erro ao atualizar comentário: ${response.status} ${response.statusText}`
      );
    }

    console.log(`Comentário atualizado (id: ${existingId}).`);
  } else {
    // Criar novo comentário
    const url = `https://api.github.com/repos/${owner}/${repo}/issues/${prNumber}/comments`;
    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github.v3+json",
        "Content-Type": "application/json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      body: JSON.stringify({ body }),
    });

    if (!response.ok) {
      throw new Error(
        `Erro ao criar comentário: ${response.status} ${response.statusText}`
      );
    }

    console.log("Novo comentário criado no PR.");
  }
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  try {
    const config = loadEnvConfig();

    console.log(
      `Consolidando resultados de: ${config.resultsDir}`
    );
    console.log(
      `PR: ${config.owner}/${config.repo}#${config.prNumber}`
    );

    // Ler resultados
    const results = readResults(config.resultsDir);

    if (results.length === 0) {
      console.log(
        "Nenhum resultado encontrado. Publicando comentário de aprovação."
      );
    }

    // Consolidar
    const report = consolidateResults(results);

    // Buscar raw output do agent (se disponível) para formatação especial
    let agentRawOutput: string | undefined;
    const agentResultFile = join(config.resultsDir, "agent.json");
    if (existsSync(agentResultFile)) {
      try {
        const agentData = JSON.parse(readFileSync(agentResultFile, "utf-8"));
        agentRawOutput = agentData.raw_output;
      } catch {
        // Se não tiver raw_output, usa formatação padrão por tabela
      }
    }

    // Gerar markdown
    const markdown = generateMarkdown(report, agentRawOutput);

    // Publicar no PR
    await postOrUpdateComment(
      config.owner,
      config.repo,
      config.prNumber,
      config.githubToken,
      markdown
    );

    // Definir exit code baseado no status
    switch (report.overall_status) {
      case "blocked":
        console.log("❌ Status: blocked — exit code 1");
        process.exit(1);
        break;
      case "warnings_only":
        console.log("⚠️ Status: warnings_only — exit code 0");
        process.exit(0);
        break;
      case "approved":
        console.log("✅ Status: approved — exit code 0");
        process.exit(0);
        break;
    }
  } catch (err) {
    console.error("Erro fatal:", err);
    process.exit(1);
  }
}

// Executa main() apenas quando chamado diretamente (não durante import em testes)
const isDirectExecution =
  process.argv[1] &&
  (process.argv[1].endsWith("consolidate-and-comment.ts") ||
    process.argv[1].endsWith("consolidate-and-comment.js"));

if (isDirectExecution) {
  main();
}
