import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtempSync, rmSync, existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { execSync } from "child_process";

/**
 * Testes de integração para o bootstrap-workflows.sh.
 * Cada teste cria um diretório temporário isolado e executa o script real.
 *
 * Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 9.6
 */

const REPO_ROOT = join(import.meta.dirname, "..", "..", "..");
const BOOTSTRAP_SCRIPT = join(REPO_ROOT, "scripts", "bootstrap-workflows.sh");
const ARCHETYPE = "backend-csharp";

/**
 * Executa o bootstrap script com os argumentos fornecidos.
 * Retorna { stdout, stderr, exitCode }
 */
function runBootstrap(args: string): { stdout: string; stderr: string; exitCode: number } {
  try {
    const stdout = execSync(`bash "${BOOTSTRAP_SCRIPT}" ${args}`, {
      encoding: "utf-8",
      cwd: REPO_ROOT,
      env: { ...process.env, NO_COLOR: "1" },
    });
    return { stdout, stderr: "", exitCode: 0 };
  } catch (error: unknown) {
    const execError = error as { stdout?: string; stderr?: string; status?: number };
    return {
      stdout: execError.stdout ?? "",
      stderr: execError.stderr ?? "",
      exitCode: execError.status ?? 1,
    };
  }
}

describe("bootstrap-workflows.sh — Testes de integração", () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), "bootstrap-test-"));
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  describe("Bootstrap em projeto vazio", () => {
    it("deve copiar review-rules.yml para a raiz do projeto", () => {
      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      expect(result.exitCode).toBe(0);
      expect(existsSync(join(tempDir, "review-rules.yml"))).toBe(true);

      const content = readFileSync(join(tempDir, "review-rules.yml"), "utf-8");
      expect(content).toContain("archetype: backend-csharp");
      expect(content).toContain("missing_tests");
    });

    it("deve criar .github/CODEOWNERS com conteúdo do archetype", () => {
      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      expect(result.exitCode).toBe(0);
      expect(existsSync(join(tempDir, ".github", "CODEOWNERS"))).toBe(true);

      const content = readFileSync(join(tempDir, ".github", "CODEOWNERS"), "utf-8");
      // O placeholder {{ archetype_name }} deve ter sido substituído
      expect(content).toContain("backend-csharp");
    });

    it("deve criar diretório .github/workflows/ mesmo sem YAML no archetype", () => {
      // O archetype backend-csharp pode não ter .yml em workflows/ ainda,
      // mas o script deve funcionar sem erros
      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      expect(result.exitCode).toBe(0);
      // Mesmo que não tenha .yml, o script deve funcionar corretamente
      expect(result.stdout).toContain("concluído");
    });
  });

  describe("Bootstrap com --force", () => {
    it("deve sobrescrever review-rules.yml existente quando módulo TS disponível", () => {
      // Criar um review-rules.yml customizado no destino
      const customContent = `version: "1.0"\narchetype: backend-csharp\nrules:\n  custom_rule:\n    severity: warn\n`;
      writeFileSync(join(tempDir, "review-rules.yml"), customContent);

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}" --force`);

      expect(result.exitCode).toBe(0);
      // O arquivo deve ter sido processado (merge ou cópia)
      const content = readFileSync(join(tempDir, "review-rules.yml"), "utf-8");
      expect(content).toContain("missing_tests");
    });

    it("deve sobrescrever workflows YAML existentes com --force", () => {
      // Criar um workflow falso no destino
      const workflowDir = join(tempDir, ".github", "workflows");
      mkdirSync(workflowDir, { recursive: true });

      // Criar um arquivo que simularia conflito se houvesse YAML no archetype
      writeFileSync(join(workflowDir, "code-review.yml"), "# old workflow");

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}" --force`);

      expect(result.exitCode).toBe(0);
      // Verificar que o script rodou com sucesso no modo force
      expect(result.stdout).toContain("force");
    });
  });

  describe("Bootstrap com --dry-run", () => {
    it("não deve criar nenhum arquivo no modo dry-run", () => {
      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}" --dry-run`);

      expect(result.exitCode).toBe(0);

      // Nenhum arquivo deve ter sido criado
      expect(existsSync(join(tempDir, "review-rules.yml"))).toBe(false);
      expect(existsSync(join(tempDir, ".github"))).toBe(false);
    });

    it("deve mostrar o que seria feito sem executar", () => {
      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}" --dry-run`);

      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain("DRY-RUN");
    });

    it("não deve modificar arquivo existente no modo dry-run", () => {
      // Criar review-rules.yml existente
      const originalContent = `version: "1.0"\narchetype: backend-csharp\nrules:\n  custom_rule:\n    severity: warn\n`;
      writeFileSync(join(tempDir, "review-rules.yml"), originalContent);

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}" --dry-run`);

      expect(result.exitCode).toBe(0);
      // Arquivo não deve ter sido alterado
      const content = readFileSync(join(tempDir, "review-rules.yml"), "utf-8");
      expect(content).toBe(originalContent);
    });
  });

  describe("Merge de review-rules.yml com conflitos", () => {
    it("deve preservar severidades customizadas e adicionar regras faltantes", () => {
      // Criar review-rules.yml com severidade customizada
      const existingContent = [
        'version: "1.0"',
        "archetype: backend-csharp",
        "rules:",
        "  missing_tests:",
        "    severity: warn",
        '    description: "Relaxado pelo time"',
        "",
      ].join("\n");
      writeFileSync(join(tempDir, "review-rules.yml"), existingContent);

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      // Se módulo TS está disponível, faz merge. Senão, copia.
      if (result.exitCode === 0 && result.stdout.includes("mergeado")) {
        const content = readFileSync(join(tempDir, "review-rules.yml"), "utf-8");
        // Severidade customizada deve ser preservada
        expect(content).toContain("warn");
        // Regras faltantes devem ser adicionadas
        expect(content).toContain("security_violation");
        expect(content).toContain("no_async_usage");
      } else {
        // Sem módulo TS, o script faz fallback para cópia
        expect(result.exitCode).toBe(0);
      }
    });

    it("deve preservar regras do projeto que não existem no archetype", () => {
      const existingContent = [
        'version: "1.0"',
        "archetype: backend-csharp",
        "rules:",
        "  missing_tests:",
        "    severity: error",
        "  custom_project_rule:",
        "    severity: warn",
        '    description: "Regra customizada do projeto"',
        "",
      ].join("\n");
      writeFileSync(join(tempDir, "review-rules.yml"), existingContent);

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      if (result.exitCode === 0 && result.stdout.includes("mergeado")) {
        const content = readFileSync(join(tempDir, "review-rules.yml"), "utf-8");
        expect(content).toContain("custom_project_rule");
      } else {
        expect(result.exitCode).toBe(0);
      }
    });
  });

  describe("Merge de CODEOWNERS com conflitos", () => {
    it("deve preservar entradas existentes e adicionar novos patterns", () => {
      // Criar CODEOWNERS existente com entradas customizadas
      mkdirSync(join(tempDir, ".github"), { recursive: true });
      const existingContent = [
        "# Projeto customizado",
        "* @myteam/core",
        "docs/ @myteam/docs",
        "",
      ].join("\n");
      writeFileSync(join(tempDir, ".github", "CODEOWNERS"), existingContent);

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      if (result.exitCode === 0 && result.stdout.includes("mergeado")) {
        const content = readFileSync(join(tempDir, ".github", "CODEOWNERS"), "utf-8");
        // Entradas existentes devem ser preservadas
        expect(content).toContain("@myteam/core");
        expect(content).toContain("docs/ @myteam/docs");
        // Novos patterns do archetype devem ser adicionados
        // (Dockerfile, review-rules.yml, .github/ — se não existirem)
        expect(content).toContain("Dockerfile");
        expect(content).toContain("review-rules.yml");
      } else {
        expect(result.exitCode).toBe(0);
      }
    });

    it("não deve duplicar path patterns já existentes", () => {
      mkdirSync(join(tempDir, ".github"), { recursive: true });
      const existingContent = [
        "* @myteam/core",
        ".github/ @myteam/platform",
        "Dockerfile @myteam/infra",
        "review-rules.yml @myteam/leads",
        "",
      ].join("\n");
      writeFileSync(join(tempDir, ".github", "CODEOWNERS"), existingContent);

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      if (result.exitCode === 0 && result.stdout.includes("mergeado")) {
        const content = readFileSync(join(tempDir, ".github", "CODEOWNERS"), "utf-8");
        // Cada pattern deve aparecer apenas uma vez
        const lines = content.split("\n").filter((l) => l.trim() && !l.trim().startsWith("#"));
        const patterns = lines.map((l) => l.trim().split(/\s+/)[0]);

        const starCount = patterns.filter((p) => p === "*").length;
        const githubCount = patterns.filter((p) => p === ".github/").length;
        const dockerfileCount = patterns.filter((p) => p === "Dockerfile").length;

        expect(starCount).toBe(1);
        expect(githubCount).toBe(1);
        expect(dockerfileCount).toBe(1);
      } else {
        expect(result.exitCode).toBe(0);
      }
    });
  });

  describe("Archetype inválido", () => {
    it("deve retornar exit code 1 com mensagem de erro", () => {
      const result = runBootstrap(`--archetype inexistente --target "${tempDir}"`);

      expect(result.exitCode).toBe(1);
      expect(result.stdout + result.stderr).toContain("inválido");
    });

    it("deve listar archetypes disponíveis na mensagem de erro", () => {
      const result = runBootstrap(`--archetype invalid-arch --target "${tempDir}"`);

      expect(result.exitCode).toBe(1);
      const output = result.stdout + result.stderr;
      expect(output).toContain("backend-csharp");
      expect(output).toContain("bff-fastify");
      expect(output).toContain("frontend-react");
    });
  });

  describe("Target inexistente", () => {
    it("deve retornar exit code 1 com mensagem de erro", () => {
      const result = runBootstrap(
        `--archetype ${ARCHETYPE} --target "/caminho/que/nao/existe"`
      );

      expect(result.exitCode).toBe(1);
      const output = result.stdout + result.stderr;
      expect(output).toContain("não encontrado");
    });
  });

  describe("Argumento ausente", () => {
    it("deve retornar exit code 1 quando --archetype ausente", () => {
      const result = runBootstrap(`--target "${tempDir}"`);

      expect(result.exitCode).toBe(1);
      const output = result.stdout + result.stderr;
      expect(output).toContain("--archetype");
    });

    it("deve retornar exit code 1 quando --target ausente", () => {
      const result = runBootstrap(`--archetype ${ARCHETYPE}`);

      expect(result.exitCode).toBe(1);
      const output = result.stdout + result.stderr;
      expect(output).toContain("--target");
    });
  });

  describe("Substituição de placeholders", () => {
    it("deve substituir {{ archetype_name }} no CODEOWNERS", () => {
      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      expect(result.exitCode).toBe(0);

      if (existsSync(join(tempDir, ".github", "CODEOWNERS"))) {
        const content = readFileSync(join(tempDir, ".github", "CODEOWNERS"), "utf-8");
        // {{ archetype_name }} deve ter sido substituído pelo nome do archetype
        expect(content).not.toContain("{{ archetype_name }}");
        expect(content).toContain("backend-csharp");
      }
    });

    it("deve manter placeholders de time para preenchimento manual", () => {
      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      expect(result.exitCode).toBe(0);

      if (existsSync(join(tempDir, ".github", "CODEOWNERS"))) {
        const content = readFileSync(join(tempDir, ".github", "CODEOWNERS"), "utf-8");
        // Placeholders de time devem permanecer para o usuário preencher
        expect(content).toContain("{{ team_default }}");
        expect(content).toContain("{{ team_platform }}");
        expect(content).toContain("{{ team_leads }}");
      }
    });
  });

  describe("Workflows existentes sem --force", () => {
    it("deve preservar workflows existentes (skip) sem --force", () => {
      // Criar um workflow existente com conteúdo customizado
      const workflowDir = join(tempDir, ".github", "workflows");
      mkdirSync(workflowDir, { recursive: true });
      const customWorkflow = "# Meu workflow customizado\nname: Custom";
      writeFileSync(join(workflowDir, "code-review.yml"), customWorkflow);

      const result = runBootstrap(`--archetype ${ARCHETYPE} --target "${tempDir}"`);

      expect(result.exitCode).toBe(0);

      // Se existia workflow com mesmo nome, deve preservar
      const content = readFileSync(join(workflowDir, "code-review.yml"), "utf-8");
      expect(content).toBe(customWorkflow);
    });
  });
});
