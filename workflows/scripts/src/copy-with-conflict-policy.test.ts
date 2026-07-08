import { describe, it, expect } from "vitest";
import {
  copyWithConflictPolicy,
  FileEntry,
  CopyResult,
} from "./copy-with-conflict-policy.js";

describe("copyWithConflictPolicy", () => {
  describe("sem force (preserva existentes)", () => {
    it("deve copiar todos os arquivos quando destino está vazio", () => {
      const sourceFiles: FileEntry[] = [
        { path: "code-review.yml", content: "workflow content" },
        { path: "CODEOWNERS", content: "owners content" },
      ];
      const destFiles: FileEntry[] = [];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

      expect(result.copied).toHaveLength(2);
      expect(result.skipped).toHaveLength(0);
      expect(result.overwritten).toHaveLength(0);
      expect(result.copied[0].path).toBe("code-review.yml");
      expect(result.copied[1].path).toBe("CODEOWNERS");
    });

    it("deve pular arquivos que já existem no destino", () => {
      const sourceFiles: FileEntry[] = [
        { path: "code-review.yml", content: "new content" },
      ];
      const destFiles: FileEntry[] = [
        { path: "code-review.yml", content: "existing content" },
      ];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

      expect(result.copied).toHaveLength(0);
      expect(result.skipped).toHaveLength(1);
      expect(result.overwritten).toHaveLength(0);
      expect(result.skipped[0].path).toBe("code-review.yml");
    });

    it("deve copiar novos e pular existentes ao mesmo tempo", () => {
      const sourceFiles: FileEntry[] = [
        { path: "code-review.yml", content: "workflow v2" },
        { path: "security-scan.yml", content: "security workflow" },
      ];
      const destFiles: FileEntry[] = [
        { path: "code-review.yml", content: "workflow v1 customizado" },
      ];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

      expect(result.copied).toHaveLength(1);
      expect(result.copied[0].path).toBe("security-scan.yml");
      expect(result.skipped).toHaveLength(1);
      expect(result.skipped[0].path).toBe("code-review.yml");
      expect(result.overwritten).toHaveLength(0);
    });

    it("deve preservar o conteúdo original do arquivo fonte no resultado", () => {
      const sourceFiles: FileEntry[] = [
        { path: "new-file.yml", content: "conteúdo fonte" },
      ];
      const destFiles: FileEntry[] = [];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

      expect(result.copied[0].content).toBe("conteúdo fonte");
    });
  });

  describe("com force (sobrescreve existentes)", () => {
    it("deve sobrescrever arquivos existentes quando force=true", () => {
      const sourceFiles: FileEntry[] = [
        { path: "code-review.yml", content: "new content" },
      ];
      const destFiles: FileEntry[] = [
        { path: "code-review.yml", content: "old content" },
      ];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, true);

      expect(result.copied).toHaveLength(0);
      expect(result.skipped).toHaveLength(0);
      expect(result.overwritten).toHaveLength(1);
      expect(result.overwritten[0].path).toBe("code-review.yml");
      expect(result.overwritten[0].content).toBe("new content");
    });

    it("deve copiar novos e sobrescrever existentes com force=true", () => {
      const sourceFiles: FileEntry[] = [
        { path: "code-review.yml", content: "workflow v2" },
        { path: "security-scan.yml", content: "security" },
      ];
      const destFiles: FileEntry[] = [
        { path: "code-review.yml", content: "workflow v1" },
      ];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, true);

      expect(result.copied).toHaveLength(1);
      expect(result.copied[0].path).toBe("security-scan.yml");
      expect(result.overwritten).toHaveLength(1);
      expect(result.overwritten[0].path).toBe("code-review.yml");
      expect(result.skipped).toHaveLength(0);
    });

    it("deve copiar todos quando destino está vazio mesmo com force=true", () => {
      const sourceFiles: FileEntry[] = [
        { path: "a.yml", content: "a" },
        { path: "b.yml", content: "b" },
      ];
      const destFiles: FileEntry[] = [];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, true);

      expect(result.copied).toHaveLength(2);
      expect(result.overwritten).toHaveLength(0);
      expect(result.skipped).toHaveLength(0);
    });
  });

  describe("edge cases", () => {
    it("deve retornar resultado vazio quando sourceFiles está vazio", () => {
      const sourceFiles: FileEntry[] = [];
      const destFiles: FileEntry[] = [
        { path: "existing.yml", content: "content" },
      ];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

      expect(result.copied).toHaveLength(0);
      expect(result.skipped).toHaveLength(0);
      expect(result.overwritten).toHaveLength(0);
    });

    it("deve retornar resultado vazio quando ambos estão vazios", () => {
      const result = copyWithConflictPolicy([], [], false);

      expect(result.copied).toHaveLength(0);
      expect(result.skipped).toHaveLength(0);
      expect(result.overwritten).toHaveLength(0);
    });

    it("deve tratar paths com diretórios corretamente", () => {
      const sourceFiles: FileEntry[] = [
        { path: "scripts/check-tests.sh", content: "#!/bin/bash" },
        { path: "scripts/check-format.sh", content: "#!/bin/bash" },
      ];
      const destFiles: FileEntry[] = [
        { path: "scripts/check-tests.sh", content: "#!/bin/bash custom" },
      ];

      const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

      expect(result.copied).toHaveLength(1);
      expect(result.copied[0].path).toBe("scripts/check-format.sh");
      expect(result.skipped).toHaveLength(1);
      expect(result.skipped[0].path).toBe("scripts/check-tests.sh");
    });

    it("deve garantir que a soma de copied + skipped + overwritten = sourceFiles.length", () => {
      const sourceFiles: FileEntry[] = [
        { path: "a.yml", content: "a" },
        { path: "b.yml", content: "b" },
        { path: "c.yml", content: "c" },
      ];
      const destFiles: FileEntry[] = [
        { path: "b.yml", content: "b-old" },
      ];

      const resultNoForce = copyWithConflictPolicy(sourceFiles, destFiles, false);
      expect(
        resultNoForce.copied.length +
          resultNoForce.skipped.length +
          resultNoForce.overwritten.length
      ).toBe(sourceFiles.length);

      const resultForce = copyWithConflictPolicy(sourceFiles, destFiles, true);
      expect(
        resultForce.copied.length +
          resultForce.skipped.length +
          resultForce.overwritten.length
      ).toBe(sourceFiles.length);
    });
  });
});
