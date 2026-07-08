import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import {
  copyWithConflictPolicy,
  FileEntry,
} from "./copy-with-conflict-policy.js";

/**
 * Property 1: Bootstrap copia com política de conflito
 *
 * Para qualquer conjunto de arquivos no diretório workflows/ de um archetype
 * e qualquer estado inicial do diretório .github/workflows/ do projeto destino:
 * sem a flag --force, arquivos já existentes no destino não devem ser modificados
 * e arquivos novos devem ser copiados; com --force, todos os arquivos devem ser
 * sobrescritos com o conteúdo do archetype.
 *
 * **Validates: Requirements 1.2, 9.1, 9.2**
 *
 * Tag: "Feature: archetype-code-review, Property 1: Bootstrap copia com política de conflito"
 */

/**
 * Gerador de caminho relativo válido (simula paths de workflow).
 */
const filePathArb = fc
  .stringMatching(/^[a-z][a-z0-9\-_]{1,20}(\.[a-z]{2,4})?$/)
  .map((name) => {
    // Garante extensão em alguns casos para simular .yml, .sh etc
    if (!name.includes(".")) return `${name}.yml`;
    return name;
  });

/**
 * Gerador de conteúdo de arquivo não-vazio.
 */
const fileContentArb = fc.string({ minLength: 1, maxLength: 200 });

/**
 * Gerador de FileEntry com path e conteúdo.
 */
const fileEntryArb: fc.Arbitrary<FileEntry> = fc.record({
  path: filePathArb,
  content: fileContentArb,
});

/**
 * Gerador de lista de FileEntry com paths únicos.
 */
const uniqueFileListArb = (
  minLength = 0,
  maxLength = 10
): fc.Arbitrary<FileEntry[]> =>
  fc
    .uniqueArray(fileEntryArb, {
      minLength,
      maxLength,
      comparator: (a, b) => a.path === b.path,
    });

describe("Feature: archetype-code-review, Property 1: Bootstrap copia com política de conflito", () => {
  describe("Sem force: arquivos existentes no destino são pulados (skipped)", () => {
    it("arquivos com path que existem em destFiles devem estar em skipped, não em copied ou overwritten", () => {
      fc.assert(
        fc.property(
          uniqueFileListArb(1, 10),
          uniqueFileListArb(0, 10),
          (sourceFiles, destFiles) => {
            const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

            const destPaths = new Set(destFiles.map((f) => f.path));

            for (const file of result.skipped) {
              expect(destPaths.has(file.path)).toBe(true);
            }

            // Nenhum arquivo existente no destino pode aparecer em copied
            for (const file of result.copied) {
              expect(destPaths.has(file.path)).toBe(false);
            }
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Sem force: arquivos novos (não existentes no destino) são copiados", () => {
    it("arquivos com path que NÃO existem em destFiles devem estar em copied", () => {
      fc.assert(
        fc.property(
          uniqueFileListArb(1, 10),
          uniqueFileListArb(0, 10),
          (sourceFiles, destFiles) => {
            const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

            const destPaths = new Set(destFiles.map((f) => f.path));

            for (const file of result.copied) {
              expect(destPaths.has(file.path)).toBe(false);
            }

            // Todo arquivo source que não existe no dest deve estar em copied
            const newSourceFiles = sourceFiles.filter(
              (sf) => !destPaths.has(sf.path)
            );
            expect(result.copied.length).toBe(newSourceFiles.length);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Com force: arquivos existentes no destino são sobrescritos com conteúdo fonte", () => {
    it("arquivos com path em destFiles devem estar em overwritten com conteúdo da fonte", () => {
      fc.assert(
        fc.property(
          uniqueFileListArb(1, 10),
          uniqueFileListArb(0, 10),
          (sourceFiles, destFiles) => {
            const result = copyWithConflictPolicy(sourceFiles, destFiles, true);

            const destPaths = new Set(destFiles.map((f) => f.path));
            const sourceByPath = new Map(
              sourceFiles.map((f) => [f.path, f.content])
            );

            for (const file of result.overwritten) {
              // Deve existir no destino
              expect(destPaths.has(file.path)).toBe(true);
              // Conteúdo deve ser o da fonte
              expect(file.content).toBe(sourceByPath.get(file.path));
            }
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Com force: arquivos novos (não existentes no destino) são copiados", () => {
    it("arquivos com path que NÃO existem em destFiles devem estar em copied", () => {
      fc.assert(
        fc.property(
          uniqueFileListArb(1, 10),
          uniqueFileListArb(0, 10),
          (sourceFiles, destFiles) => {
            const result = copyWithConflictPolicy(sourceFiles, destFiles, true);

            const destPaths = new Set(destFiles.map((f) => f.path));

            for (const file of result.copied) {
              expect(destPaths.has(file.path)).toBe(false);
            }

            const newSourceFiles = sourceFiles.filter(
              (sf) => !destPaths.has(sf.path)
            );
            expect(result.copied.length).toBe(newSourceFiles.length);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Invariante: copied + skipped + overwritten === sourceFiles.length", () => {
    it("a soma de todas as categorias deve ser igual ao total de arquivos fonte", () => {
      fc.assert(
        fc.property(
          uniqueFileListArb(0, 10),
          uniqueFileListArb(0, 10),
          fc.boolean(),
          (sourceFiles, destFiles, force) => {
            const result = copyWithConflictPolicy(sourceFiles, destFiles, force);

            expect(
              result.copied.length +
                result.skipped.length +
                result.overwritten.length
            ).toBe(sourceFiles.length);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Sem force: overwritten é sempre vazio", () => {
    it("sem force, nenhum arquivo deve aparecer em overwritten", () => {
      fc.assert(
        fc.property(
          uniqueFileListArb(0, 10),
          uniqueFileListArb(0, 10),
          (sourceFiles, destFiles) => {
            const result = copyWithConflictPolicy(sourceFiles, destFiles, false);

            expect(result.overwritten).toHaveLength(0);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Com force: skipped é sempre vazio", () => {
    it("com force, nenhum arquivo deve aparecer em skipped", () => {
      fc.assert(
        fc.property(
          uniqueFileListArb(0, 10),
          uniqueFileListArb(0, 10),
          (sourceFiles, destFiles) => {
            const result = copyWithConflictPolicy(sourceFiles, destFiles, true);

            expect(result.skipped).toHaveLength(0);
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
