import { describe, it, expect } from "vitest";
import { mergeCODEOWNERS } from "./merge-codeowners.js";

describe("mergeCODEOWNERS", () => {
  describe("preservação de entradas existentes", () => {
    it("deve preservar todas as linhas do conteúdo existente intactas", () => {
      const existing = `# Projeto X
* @team/core
.github/ @team/platform
`;
      const archetype = `# Archetype
* @team/default
`;

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result).toContain("# Projeto X");
      expect(result).toContain("* @team/core");
      expect(result).toContain(".github/ @team/platform");
    });

    it("deve preservar comentários e linhas vazias do existente", () => {
      const existing = `# Header comment

# Section comment
* @team/core

.github/ @team/platform
`;
      const archetype = `* @team/default
`;

      const result = mergeCODEOWNERS(archetype, existing);

      // Deve começar com o conteúdo existente preservado
      expect(result.startsWith("# Header comment\n")).toBe(true);
      expect(result).toContain("\n# Section comment\n");
    });

    it("deve preservar owners existentes quando path pattern já existe", () => {
      const existing = `* @team/custom-owners
.github/ @team/custom-platform
`;
      const archetype = `* @team/default
.github/ @team/platform
`;

      const result = mergeCODEOWNERS(archetype, existing);

      // Deve manter os owners originais, não os do archetype
      expect(result).toContain("* @team/custom-owners");
      expect(result).toContain(".github/ @team/custom-platform");
      expect(result).not.toContain("@team/default");
      expect(result).not.toContain("@team/platform");
    });
  });

  describe("adição de entradas novas do archetype", () => {
    it("deve adicionar entradas do archetype com path patterns novos", () => {
      const existing = `* @team/core
`;
      const archetype = `* @team/default
Dockerfile @team/platform
review-rules.yml @team/leads
`;

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result).toContain("Dockerfile @team/platform");
      expect(result).toContain("review-rules.yml @team/leads");
    });

    it("deve adicionar entradas ao final do conteúdo existente", () => {
      const existing = `# Existing
* @team/core
`;
      const archetype = `* @team/default
Dockerfile @team/platform
`;

      const result = mergeCODEOWNERS(archetype, existing);

      const lines = result.split("\n");
      const dockerfileLine = lines.findIndex((l) => l.includes("Dockerfile"));
      const coreLine = lines.findIndex((l) => l.includes("@team/core"));

      // Dockerfile deve vir depois de @team/core
      expect(dockerfileLine).toBeGreaterThan(coreLine);
    });
  });

  describe("prevenção de duplicatas", () => {
    it("não deve duplicar linhas com mesmo path pattern", () => {
      const existing = `* @team/core
.github/ @team/platform
Dockerfile @team/infra
`;
      const archetype = `* @team/default
.github/ @team/platform-arch
Dockerfile @team/platform-arch
review-rules.yml @team/leads
`;

      const result = mergeCODEOWNERS(archetype, existing);

      // Contar ocorrências de cada path pattern
      const lines = result.split("\n").filter((l) => l.trim() && !l.trim().startsWith("#"));
      const patterns = lines.map((l) => l.trim().split(/\s+/)[0]);

      const starCount = patterns.filter((p) => p === "*").length;
      const githubCount = patterns.filter((p) => p === ".github/").length;
      const dockerfileCount = patterns.filter((p) => p === "Dockerfile").length;

      expect(starCount).toBe(1);
      expect(githubCount).toBe(1);
      expect(dockerfileCount).toBe(1);
    });

    it("deve adicionar apenas o path pattern que não existe no existente", () => {
      const existing = `* @team/core
.github/ @team/platform
`;
      const archetype = `* @team/default
.github/ @team/platform
Dockerfile @team/platform
`;

      const result = mergeCODEOWNERS(archetype, existing);

      const entryLines = result
        .split("\n")
        .filter((l) => l.trim() && !l.trim().startsWith("#"));

      expect(entryLines).toHaveLength(3); // *, .github/, Dockerfile
    });
  });

  describe("conteúdo existente vazio", () => {
    it("deve retornar todas as entradas do archetype quando existente está vazio", () => {
      const existing = "";
      const archetype = `# Archetype CODEOWNERS
* @team/default
.github/ @team/platform
`;

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result).toContain("* @team/default");
      expect(result).toContain(".github/ @team/platform");
    });

    it("deve retornar entradas do archetype quando existente tem apenas comentários", () => {
      const existing = `# Only comments here
# No actual entries
`;
      const archetype = `* @team/default
.github/ @team/platform
`;

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result).toContain("# Only comments here");
      expect(result).toContain("* @team/default");
      expect(result).toContain(".github/ @team/platform");
    });
  });

  describe("archetype vazio ou sem entradas novas", () => {
    it("deve retornar conteúdo existente inalterado quando archetype está vazio", () => {
      const existing = `* @team/core
.github/ @team/platform
`;
      const archetype = "";

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result).toBe(existing);
    });

    it("deve retornar conteúdo existente inalterado quando não há patterns novos", () => {
      const existing = `* @team/core
.github/ @team/platform
`;
      const archetype = `* @team/default
.github/ @team/other
`;

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result).toBe(existing);
    });
  });

  describe("edge cases", () => {
    it("deve lidar com placeholders {{ }} do archetype", () => {
      const existing = `* @team/core
`;
      const archetype = `* {{ team_default }}
.github/ {{ team_platform }}
Dockerfile {{ team_platform }}
review-rules.yml {{ team_leads }}
`;

      const result = mergeCODEOWNERS(archetype, existing);

      // * já existe, não deve adicionar. Os demais são novos.
      expect(result).toContain(".github/ {{ team_platform }}");
      expect(result).toContain("Dockerfile {{ team_platform }}");
      expect(result).toContain("review-rules.yml {{ team_leads }}");
    });

    it("deve lidar com múltiplos owners por linha", () => {
      const existing = `* @team/core @team/leads
`;
      const archetype = `* @team/default
docs/ @team/docs @team/leads
`;

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result).toContain("docs/ @team/docs @team/leads");
      // * não deve ser duplicado
      const entryLines = result
        .split("\n")
        .filter((l) => l.trim() && !l.trim().startsWith("#"));
      const starEntries = entryLines.filter((l) => l.trim().startsWith("*"));
      expect(starEntries).toHaveLength(1);
    });

    it("deve preservar trailing newline no resultado", () => {
      const existing = `* @team/core
`;
      const archetype = `* @team/default
docs/ @team/docs
`;

      const result = mergeCODEOWNERS(archetype, existing);

      expect(result.endsWith("\n")).toBe(true);
    });

    it("deve lidar com espaçamento variado entre path e owners", () => {
      const existing = `*    @team/core
.github/     @team/platform
`;
      const archetype = `* @team/default
.github/ @team/arch-platform
Dockerfile @team/platform
`;

      const result = mergeCODEOWNERS(archetype, existing);

      // * e .github/ já existem (mesmo com espaçamento diferente)
      expect(result).toContain("Dockerfile @team/platform");
      const entryLines = result
        .split("\n")
        .filter((l) => l.trim() && !l.trim().startsWith("#"));
      expect(entryLines).toHaveLength(3);
    });
  });
});
