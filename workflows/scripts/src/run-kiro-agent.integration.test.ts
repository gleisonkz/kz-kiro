import { describe, it, expect, beforeEach, afterEach } from "vitest";
import {
  mkdtempSync,
  rmSync,
  writeFileSync,
  readFileSync,
  mkdirSync,
  existsSync,
} from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { execSync } from "child_process";

/**
 * Testes de integração para o run-kiro-agent.sh.
 * Cada teste cria um diretório temporário isolado e executa o script real.
 *
 * Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5
 */

const REPO_ROOT = join(import.meta.dirname, "..");
const SCRIPT_PATH = join(REPO_ROOT, "run-kiro-agent.sh");

/**
 * Executa o run-kiro-agent.sh com as variáveis de ambiente fornecidas.
 */
function runScript(env: Record<string, string>): {
  stdout: string;
  stderr: string;
  exitCode: number;
} {
  try {
    const stdout = execSync(`bash "${SCRIPT_PATH}"`, {
      encoding: "utf-8",
      env: { ...process.env, ...env, NO_COLOR: "1" },
    });
    return { stdout, stderr: "", exitCode: 0 };
  } catch (error: unknown) {
    const execError = error as {
      stdout?: string;
      stderr?: string;
      status?: number;
    };
    return {
      stdout: execError.stdout ?? "",
      stderr: execError.stderr ?? "",
      exitCode: execError.status ?? 1,
    };
  }
}

describe("run-kiro-agent.sh — Testes de integração", () => {
  let tempDir: string;
  let resultsDir: string;

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), "kiro-agent-test-"));
    resultsDir = join(tempDir, "results");
    mkdirSync(resultsDir, { recursive: true });
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  describe("Quando review-rules.yml não existe", () => {
    it("deve gerar resultado com status skipped", () => {
      const result = runScript({
        REVIEW_RULES_PATH: join(tempDir, "inexistente.yml"),
        RESULTS_DIR: resultsDir,
      });

      expect(result.exitCode).toBe(0);

      const outputFile = join(resultsDir, "agent.json");
      expect(existsSync(outputFile)).toBe(true);

      const output = JSON.parse(readFileSync(outputFile, "utf-8"));
      expect(output.step).toBe("agent");
      expect(output.status).toBe("skipped");
      expect(output.violations).toEqual([]);
    });
  });

  describe("Quando agent_review.enabled é false", () => {
    it("deve gerar resultado com status skipped", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: false
  agent: code-reviewer
rules:
  missing_tests:
    severity: error
`
      );

      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
      });

      expect(result.exitCode).toBe(0);

      const output = JSON.parse(
        readFileSync(join(resultsDir, "agent.json"), "utf-8")
      );
      expect(output.step).toBe("agent");
      expect(output.status).toBe("skipped");
    });
  });

  describe("Quando agent_review não está presente no YAML", () => {
    it("deve gerar resultado com status skipped (enabled = false por padrão)", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
rules:
  missing_tests:
    severity: error
`
      );

      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
      });

      expect(result.exitCode).toBe(0);

      const output = JSON.parse(
        readFileSync(join(resultsDir, "agent.json"), "utf-8")
      );
      expect(output.step).toBe("agent");
      expect(output.status).toBe("skipped");
    });
  });

  describe("Quando agent está habilitado mas Kiro CLI não está disponível", () => {
    it("deve gerar resultado com status skipped", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: true
  agent: code-reviewer
  timeout_seconds: 300
rules:
  missing_tests:
    severity: error
`
      );

      // Executar com PATH vazio para garantir que kiro não será encontrado
      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
        PATH: "/usr/bin:/bin",
      });

      expect(result.exitCode).toBe(0);

      const output = JSON.parse(
        readFileSync(join(resultsDir, "agent.json"), "utf-8")
      );
      expect(output.step).toBe("agent");
      expect(output.status).toBe("skipped");
    });
  });

  describe("Quando agent está habilitado e Kiro CLI é um mock que retorna output", () => {
    it("deve gerar resultado com status fail e raw_output", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: true
  agent: code-reviewer
  timeout_seconds: 300
rules:
  missing_tests:
    severity: error
`
      );

      // Criar mock do kiro que produz output
      const binDir = join(tempDir, "bin");
      mkdirSync(binDir);
      writeFileSync(
        join(binDir, "kiro"),
        `#!/usr/bin/env bash
echo "ERROR: Código sem tratamento de erros"
echo "FILE: src/service.ts:42"
echo "SUGGESTION: Adicione try/catch"
`
      );
      execSync(`chmod +x "${join(binDir, "kiro")}"`);

      // Criar mock do timeout que simplesmente executa o comando (ignora o tempo)
      writeFileSync(
        join(binDir, "timeout"),
        `#!/usr/bin/env bash
# Mock timeout: ignora o primeiro arg (tempo) e executa o resto
shift
exec "$@"
`
      );
      execSync(`chmod +x "${join(binDir, "timeout")}"`);

      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
        PATH: `${binDir}:/usr/bin:/bin`,
      });

      expect(result.exitCode).toBe(0);

      const output = JSON.parse(
        readFileSync(join(resultsDir, "agent.json"), "utf-8")
      );
      expect(output.step).toBe("agent");
      expect(output.status).toBe("fail");
      expect(output.raw_output).toContain("ERROR: Código sem tratamento de erros");
      expect(output.violations).toEqual([]);
    });
  });

  describe("Quando agent está habilitado e Kiro CLI não produz output", () => {
    it("deve gerar resultado com status pass e violations vazio", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: true
  agent: code-reviewer
  timeout_seconds: 300
rules:
  missing_tests:
    severity: error
`
      );

      // Criar mock do kiro que não produz output
      const binDir = join(tempDir, "bin");
      mkdirSync(binDir);
      writeFileSync(
        join(binDir, "kiro"),
        `#!/usr/bin/env bash
exit 0
`
      );
      execSync(`chmod +x "${join(binDir, "kiro")}"`);

      // Criar mock do timeout que simplesmente executa o comando
      writeFileSync(
        join(binDir, "timeout"),
        `#!/usr/bin/env bash
shift
exec "$@"
`
      );
      execSync(`chmod +x "${join(binDir, "timeout")}"`);

      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
        PATH: `${binDir}:/usr/bin:/bin`,
      });

      expect(result.exitCode).toBe(0);

      const output = JSON.parse(
        readFileSync(join(resultsDir, "agent.json"), "utf-8")
      );
      expect(output.step).toBe("agent");
      expect(output.status).toBe("pass");
      expect(output.violations).toEqual([]);
      expect(output.raw_output).toBeUndefined();
    });
  });

  describe("Quando agent está habilitado e Kiro CLI falha com erro", () => {
    it("deve gerar resultado com status error e mensagem descritiva", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: true
  agent: code-reviewer
  timeout_seconds: 300
rules:
  missing_tests:
    severity: error
`
      );

      // Criar mock do kiro que falha com erro
      const binDir = join(tempDir, "bin");
      mkdirSync(binDir);
      writeFileSync(
        join(binDir, "kiro"),
        `#!/usr/bin/env bash
echo "Agent initialization failed: config not found" >&2
exit 1
`
      );
      execSync(`chmod +x "${join(binDir, "kiro")}"`);

      // Criar mock do timeout
      writeFileSync(
        join(binDir, "timeout"),
        `#!/usr/bin/env bash
shift
exec "$@"
`
      );
      execSync(`chmod +x "${join(binDir, "timeout")}"`);

      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
        PATH: `${binDir}:/usr/bin:/bin`,
      });

      expect(result.exitCode).toBe(0);

      const output = JSON.parse(
        readFileSync(join(resultsDir, "agent.json"), "utf-8")
      );
      expect(output.step).toBe("agent");
      expect(output.status).toBe("error");
      expect(output.violations.length).toBe(1);
      expect(output.violations[0].rule_id).toBe("agent_error");
      expect(output.violations[0].severity).toBe("warn");
      expect(output.violations[0].message).toContain("exit 1");
    });
  });

  describe("Quando agent está habilitado e Kiro CLI excede timeout", () => {
    it("deve gerar resultado com status error e mensagem de timeout", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: true
  agent: code-reviewer
  timeout_seconds: 2
rules:
  missing_tests:
    severity: error
`
      );

      // Criar mock do kiro que demora
      const binDir = join(tempDir, "bin");
      mkdirSync(binDir);
      writeFileSync(
        join(binDir, "kiro"),
        `#!/usr/bin/env bash
sleep 10
echo "done"
`
      );
      execSync(`chmod +x "${join(binDir, "kiro")}"`);

      // Criar mock do timeout que simula timeout (exit 124)
      writeFileSync(
        join(binDir, "timeout"),
        `#!/usr/bin/env bash
# Simular timeout: exit 124 sem executar o comando
exit 124
`
      );
      execSync(`chmod +x "${join(binDir, "timeout")}"`);

      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
        PATH: `${binDir}:/usr/bin:/bin`,
      });

      expect(result.exitCode).toBe(0);

      const output = JSON.parse(
        readFileSync(join(resultsDir, "agent.json"), "utf-8")
      );
      expect(output.step).toBe("agent");
      expect(output.status).toBe("error");
      expect(output.violations.length).toBe(1);
      expect(output.violations[0].message).toContain("timeout");
    }, 10000);
  });

  describe("Quando agent_review usa valores padrão para agent e timeout", () => {
    it("deve usar code-reviewer e 300s como defaults", () => {
      const rulesPath = join(tempDir, "review-rules.yml");
      writeFileSync(
        rulesPath,
        `version: "1.0"
archetype: backend-csharp
agent_review:
  enabled: true
rules:
  missing_tests:
    severity: error
`
      );

      // Criar mock do kiro que verifica os argumentos
      const binDir = join(tempDir, "bin");
      mkdirSync(binDir);
      writeFileSync(
        join(binDir, "kiro"),
        `#!/usr/bin/env bash
# Verificar argumentos passados
echo "ARGS: $@"
exit 0
`
      );
      execSync(`chmod +x "${join(binDir, "kiro")}"`);

      // Criar mock do timeout
      writeFileSync(
        join(binDir, "timeout"),
        `#!/usr/bin/env bash
shift
exec "$@"
`
      );
      execSync(`chmod +x "${join(binDir, "timeout")}"`);

      const result = runScript({
        REVIEW_RULES_PATH: rulesPath,
        RESULTS_DIR: resultsDir,
        PATH: `${binDir}:/usr/bin:/bin`,
      });

      expect(result.exitCode).toBe(0);
      // O stdout deve conter referência ao agent code-reviewer
      expect(result.stdout).toContain("code-reviewer");
    });
  });
});
