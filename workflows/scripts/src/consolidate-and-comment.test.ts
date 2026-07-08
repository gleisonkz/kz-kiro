import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { readResults, generateMarkdown, loadEnvConfig } from "./consolidate-and-comment.js";
import { consolidateResults } from "./consolidate-results.js";
import type { ReviewResult, ConsolidatedReport } from "./types.js";

describe("consolidate-and-comment", () => {
  describe("readResults", () => {
    let tempDir: string;

    beforeEach(() => {
      tempDir = mkdtempSync(join(tmpdir(), "review-results-"));
    });

    afterEach(() => {
      rmSync(tempDir, { recursive: true, force: true });
    });

    it("deve ler múltiplos arquivos JSON do diretório", () => {
      const result1: ReviewResult = {
        step: "lint",
        status: "fail",
        violations: [
          {
            rule_id: "no-unused-vars",
            severity: "error",
            file: "src/index.ts",
            line: 10,
            message: "Variável não utilizada",
          },
        ],
      };

      const result2: ReviewResult = {
        step: "format",
        status: "pass",
        violations: [],
      };

      writeFileSync(join(tempDir, "lint.json"), JSON.stringify(result1));
      writeFileSync(join(tempDir, "format.json"), JSON.stringify(result2));

      const results = readResults(tempDir);
      expect(results).toHaveLength(2);
      expect(results.find((r) => r.step === "lint")).toBeDefined();
      expect(results.find((r) => r.step === "format")).toBeDefined();
    });

    it("deve retornar array vazio se diretório não existe", () => {
      const results = readResults("/tmp/nonexistent-dir-12345");
      expect(results).toEqual([]);
    });

    it("deve retornar array vazio se não há arquivos .json", () => {
      writeFileSync(join(tempDir, "readme.txt"), "not a json");
      const results = readResults(tempDir);
      expect(results).toEqual([]);
    });

    it("deve ignorar arquivos com JSON inválido", () => {
      writeFileSync(join(tempDir, "valid.json"), JSON.stringify({
        step: "lint",
        status: "pass",
        violations: [],
      }));
      writeFileSync(join(tempDir, "invalid.json"), "not valid json {{{");

      const results = readResults(tempDir);
      expect(results).toHaveLength(1);
      expect(results[0].step).toBe("lint");
    });
  });

  describe("generateMarkdown", () => {
    it("deve gerar markdown de aprovação quando status é approved", () => {
      const report: ConsolidatedReport = {
        overall_status: "approved",
        total_violations: 0,
        blocking_violations: 0,
        warning_violations: 0,
        sections: [
          { type: "lint", title: "Lint", status: "pass", violations: [] },
          { type: "format", title: "Formatação", status: "pass", violations: [] },
          { type: "type_check", title: "Type Check", status: "pass", violations: [] },
          { type: "security", title: "Segurança", status: "pass", violations: [] },
          { type: "archetype_rules", title: "Regras do Archetype", status: "pass", violations: [] },
          { type: "agent", title: "Revisão via Agent", status: "pass", violations: [] },
        ],
      };

      const md = generateMarkdown(report);

      expect(md).toContain("## 🔍 Code Review Automatizado");
      expect(md).toContain("✅ **Todas as verificações passaram!**");
      expect(md).toContain("<!-- archetype-code-review-bot -->");
    });

    it("deve gerar markdown de bloqueio quando status é blocked", () => {
      const report: ConsolidatedReport = {
        overall_status: "blocked",
        total_violations: 2,
        blocking_violations: 1,
        warning_violations: 1,
        sections: [
          {
            type: "lint",
            title: "Lint",
            status: "fail",
            violations: [
              {
                rule_id: "no-unused-vars",
                severity: "error",
                file: "src/index.ts",
                line: 10,
                message: "Variável não utilizada",
                suggestion: "Remover a variável",
              },
            ],
          },
          {
            type: "security",
            title: "Segurança",
            status: "fail",
            violations: [
              {
                rule_id: "vuln-dep",
                severity: "warn",
                message: "Dependência desatualizada",
              },
            ],
          },
          { type: "format", title: "Formatação", status: "pass", violations: [] },
          { type: "type_check", title: "Type Check", status: "pass", violations: [] },
          { type: "archetype_rules", title: "Regras do Archetype", status: "pass", violations: [] },
          { type: "agent", title: "Revisão via Agent", status: "pass", violations: [] },
        ],
      };

      const md = generateMarkdown(report);

      expect(md).toContain("❌ **Merge bloqueado**");
      expect(md).toContain("1 erro(s) bloqueante(s) e 1 aviso(s) encontrados.");
      expect(md).toContain("🧹 Lint");
      expect(md).toContain("`src/index.ts:10`");
      expect(md).toContain("Variável não utilizada");
      expect(md).toContain("Remover a variável");
      expect(md).toContain("🔒 Segurança");
    });

    it("deve gerar markdown de warnings quando status é warnings_only", () => {
      const report: ConsolidatedReport = {
        overall_status: "warnings_only",
        total_violations: 1,
        blocking_violations: 0,
        warning_violations: 1,
        sections: [
          {
            type: "lint",
            title: "Lint",
            status: "fail",
            violations: [
              {
                rule_id: "prefer-const",
                severity: "warn",
                file: "src/utils.ts",
                message: "Usar const em vez de let",
              },
            ],
          },
          { type: "format", title: "Formatação", status: "pass", violations: [] },
          { type: "type_check", title: "Type Check", status: "pass", violations: [] },
          { type: "security", title: "Segurança", status: "pass", violations: [] },
          { type: "archetype_rules", title: "Regras do Archetype", status: "pass", violations: [] },
          { type: "agent", title: "Revisão via Agent", status: "pass", violations: [] },
        ],
      };

      const md = generateMarkdown(report);

      expect(md).toContain("⚠️ **Avisos encontrados**");
      expect(md).toContain("1 aviso(s) encontrados. O merge não está bloqueado.");
      expect(md).toContain("Usar const em vez de let");
    });

    it("deve usar formatAgentFeedback quando agentRawOutput é fornecido", () => {
      const report: ConsolidatedReport = {
        overall_status: "blocked",
        total_violations: 1,
        blocking_violations: 1,
        warning_violations: 0,
        sections: [
          { type: "lint", title: "Lint", status: "pass", violations: [] },
          { type: "format", title: "Formatação", status: "pass", violations: [] },
          { type: "type_check", title: "Type Check", status: "pass", violations: [] },
          { type: "security", title: "Segurança", status: "pass", violations: [] },
          { type: "archetype_rules", title: "Regras do Archetype", status: "pass", violations: [] },
          {
            type: "agent",
            title: "Revisão via Agent",
            status: "fail",
            violations: [
              {
                rule_id: "agent-issue",
                severity: "error",
                message: "Problema encontrado",
              },
            ],
          },
        ],
      };

      const agentOutput = "ERROR: Problema de arquitetura\nFILE: src/service.ts:42\nSUGGESTION: Separar responsabilidades";

      const md = generateMarkdown(report, agentOutput);

      // Deve usar formatAgentFeedback em vez da tabela padrão
      expect(md).toContain("🤖 Revisão via Agent");
      expect(md).toContain("Problema de arquitetura");
      expect(md).toContain("src/service.ts:42");
    });

    it("deve exibir localização sem linha quando apenas file é fornecido", () => {
      const report: ConsolidatedReport = {
        overall_status: "warnings_only",
        total_violations: 1,
        blocking_violations: 0,
        warning_violations: 1,
        sections: [
          {
            type: "format",
            title: "Formatação",
            status: "fail",
            violations: [
              {
                rule_id: "prettier",
                severity: "warn",
                file: "src/app.ts",
                message: "Formatação incorreta",
              },
            ],
          },
          { type: "lint", title: "Lint", status: "pass", violations: [] },
          { type: "type_check", title: "Type Check", status: "pass", violations: [] },
          { type: "security", title: "Segurança", status: "pass", violations: [] },
          { type: "archetype_rules", title: "Regras do Archetype", status: "pass", violations: [] },
          { type: "agent", title: "Revisão via Agent", status: "pass", violations: [] },
        ],
      };

      const md = generateMarkdown(report);
      expect(md).toContain("`src/app.ts`");
    });

    it("deve exibir '—' para localização quando file não está presente", () => {
      const report: ConsolidatedReport = {
        overall_status: "warnings_only",
        total_violations: 1,
        blocking_violations: 0,
        warning_violations: 1,
        sections: [
          {
            type: "security",
            title: "Segurança",
            status: "fail",
            violations: [
              {
                rule_id: "vuln",
                severity: "warn",
                message: "Dependência vulnerável",
              },
            ],
          },
          { type: "lint", title: "Lint", status: "pass", violations: [] },
          { type: "format", title: "Formatação", status: "pass", violations: [] },
          { type: "type_check", title: "Type Check", status: "pass", violations: [] },
          { type: "archetype_rules", title: "Regras do Archetype", status: "pass", violations: [] },
          { type: "agent", title: "Revisão via Agent", status: "pass", violations: [] },
        ],
      };

      const md = generateMarkdown(report);
      // Localização deve ser "—" quando não há file
      expect(md).toMatch(/\| — \|/);
    });

    it("deve sempre incluir o marcador do bot no início", () => {
      const report: ConsolidatedReport = {
        overall_status: "approved",
        total_violations: 0,
        blocking_violations: 0,
        warning_violations: 0,
        sections: [],
      };

      const md = generateMarkdown(report);
      expect(md.startsWith("<!-- archetype-code-review-bot -->")).toBe(true);
    });
  });

  describe("loadEnvConfig", () => {
    const originalEnv = { ...process.env };

    afterEach(() => {
      process.env = { ...originalEnv };
    });

    it("deve lançar erro se GITHUB_TOKEN não está definido", () => {
      delete process.env.GITHUB_TOKEN;
      expect(() => loadEnvConfig()).toThrow("GITHUB_TOKEN");
    });

    it("deve lançar erro se GITHUB_REPOSITORY não está definido", () => {
      process.env.GITHUB_TOKEN = "token123";
      delete process.env.GITHUB_REPOSITORY;
      expect(() => loadEnvConfig()).toThrow("GITHUB_REPOSITORY");
    });

    it("deve lançar erro se PR_NUMBER não é determinável", () => {
      process.env.GITHUB_TOKEN = "token123";
      process.env.GITHUB_REPOSITORY = "org/repo";
      delete process.env.PR_NUMBER;
      delete process.env.GITHUB_EVENT_PATH;
      expect(() => loadEnvConfig()).toThrow("PR");
    });

    it("deve carregar config completa com PR_NUMBER", () => {
      process.env.GITHUB_TOKEN = "token123";
      process.env.GITHUB_REPOSITORY = "org/repo";
      process.env.PR_NUMBER = "42";
      process.env.RESULTS_DIR = "/custom/dir";

      const config = loadEnvConfig();
      expect(config.githubToken).toBe("token123");
      expect(config.owner).toBe("org");
      expect(config.repo).toBe("repo");
      expect(config.prNumber).toBe(42);
      expect(config.resultsDir).toBe("/custom/dir");
    });

    it("deve usar default /tmp/review-results se RESULTS_DIR não definido", () => {
      process.env.GITHUB_TOKEN = "token123";
      process.env.GITHUB_REPOSITORY = "org/repo";
      process.env.PR_NUMBER = "1";
      delete process.env.RESULTS_DIR;

      const config = loadEnvConfig();
      expect(config.resultsDir).toBe("/tmp/review-results");
    });

    it("deve extrair PR number de GITHUB_EVENT_PATH", () => {
      const tempDir = mkdtempSync(join(tmpdir(), "event-"));
      const eventFile = join(tempDir, "event.json");
      writeFileSync(eventFile, JSON.stringify({ pull_request: { number: 99 } }));

      process.env.GITHUB_TOKEN = "token123";
      process.env.GITHUB_REPOSITORY = "org/repo";
      delete process.env.PR_NUMBER;
      process.env.GITHUB_EVENT_PATH = eventFile;

      const config = loadEnvConfig();
      expect(config.prNumber).toBe(99);

      rmSync(tempDir, { recursive: true, force: true });
    });
  });

  describe("integração: readResults + consolidateResults + generateMarkdown", () => {
    let tempDir: string;

    beforeEach(() => {
      tempDir = mkdtempSync(join(tmpdir(), "review-integration-"));
    });

    afterEach(() => {
      rmSync(tempDir, { recursive: true, force: true });
    });

    it("deve consolidar e gerar markdown corretamente end-to-end", () => {
      // Simular resultados de vários steps
      const lintResult: ReviewResult = {
        step: "lint",
        status: "fail",
        violations: [
          {
            rule_id: "no-console",
            severity: "error",
            file: "src/handler.ts",
            line: 5,
            message: "Uso de console.log proibido",
            suggestion: "Use um logger adequado",
          },
        ],
      };

      const formatResult: ReviewResult = {
        step: "format",
        status: "pass",
        violations: [],
      };

      const securityResult: ReviewResult = {
        step: "security",
        status: "fail",
        violations: [
          {
            rule_id: "vuln-critical",
            severity: "warn",
            message: "lodash@4.17.20 com vulnerabilidade conhecida",
          },
        ],
      };

      writeFileSync(join(tempDir, "lint.json"), JSON.stringify(lintResult));
      writeFileSync(join(tempDir, "format.json"), JSON.stringify(formatResult));
      writeFileSync(join(tempDir, "security.json"), JSON.stringify(securityResult));

      const results = readResults(tempDir);
      const report = consolidateResults(results);
      const md = generateMarkdown(report);

      expect(report.overall_status).toBe("blocked");
      expect(report.total_violations).toBe(2);
      expect(md).toContain("❌ **Merge bloqueado**");
      expect(md).toContain("Uso de console.log proibido");
      expect(md).toContain("lodash@4.17.20");
    });
  });
});
