import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { detectMissingTests } from "./detect-missing-tests.js";

/**
 * Property 7: Detecção de testes faltantes
 *
 * Para qualquer lista de arquivos de código-fonte adicionados/modificados em um PR,
 * se um arquivo está em um caminho que requer teste e não existe um arquivo de teste
 * correspondente no mesmo PR, a detecção deve reportar missing_tests para esse arquivo.
 *
 * **Validates: Requirements 4.1, 5.1, 6.1**
 *
 * Tag: "Feature: archetype-code-review, Property 7: Detecção de testes faltantes"
 */

// ============================================================
// Geradores auxiliares
// ============================================================

/** Gera um nome de classe C# válido (PascalCase) */
const csharpClassNameArb = fc
  .stringMatching(/^[A-Z][a-zA-Z0-9]{2,20}$/)
  .filter((s) => !s.endsWith("Test") && !s.endsWith("Tests"));

/** Gera caminhos C# que REQUEREM teste (com /Application/ ou /Domain/ no caminho) */
const csharpFileRequiringTestArb = fc
  .tuple(
    fc.constantFrom(
      "src/Application/Services/",
      "src/Application/UseCases/",
      "src/Domain/Entities/",
      "src/Domain/ValueObjects/",
      "MyProject/Application/Handlers/",
      "MyProject/Domain/Aggregates/"
    ),
    csharpClassNameArb
  )
  .map(([dir, name]) => `${dir}${name}.cs`);

/** Gera nome de arquivo de teste C# correspondente */
const csharpTestFileArb = (baseName: string) =>
  fc.constantFrom(`${baseName}Tests.cs`, `${baseName}Test.cs`);

/** Gera um nome de módulo BFF válido */
const bffModuleNameArb = fc.stringMatching(/^[a-z][a-z0-9\-]{1,15}$/);

/** Gera um nome de arquivo TS válido (sem extensão) */
const bffFileNameArb = fc.stringMatching(/^[a-z][a-z0-9\-]{1,15}$/);

/** Gera caminhos BFF que REQUEREM teste (routes/ ou services/) */
const bffFileRequiringTestArb = fc
  .tuple(
    bffModuleNameArb,
    fc.constantFrom("routes", "services"),
    bffFileNameArb
  )
  .map(([mod, folder, name]) => `src/modules/${mod}/${folder}/${name}.ts`);

/** Gera nome de arquivo de teste BFF correspondente */
const bffTestFileArb = (filePath: string) => {
  const baseName = filePath.replace(/\.ts$/, "");
  return fc.constantFrom(`${baseName}.spec.ts`, `${baseName}.test.ts`);
};

/** Gera um nome de componente React válido (PascalCase) */
const reactComponentNameArb = fc.stringMatching(/^[A-Z][a-zA-Z0-9]{2,15}$/);

/** Gera um nome de hook React válido (camelCase com prefixo use) */
const reactHookNameArb = fc
  .stringMatching(/^[A-Z][a-zA-Z0-9]{2,15}$/)
  .map((s) => `use${s}`);

/** Gera um nome de util válido (camelCase) */
const reactUtilNameArb = fc.stringMatching(/^[a-z][a-zA-Z0-9]{2,15}$/);

/** Gera caminhos React que REQUEREM teste */
const reactFileRequiringTestArb = fc.oneof(
  // Componentes: src/**/components/**/*.tsx
  fc
    .tuple(
      fc.constantFrom("src/features", "src/app", "src/shared"),
      reactComponentNameArb
    )
    .map(([prefix, name]) => `${prefix}/components/${name}.tsx`),
  // Hooks: src/**/hooks/**/*.ts
  fc
    .tuple(
      fc.constantFrom("src/features", "src/app", "src/shared"),
      reactHookNameArb
    )
    .map(([prefix, name]) => `${prefix}/hooks/${name}.ts`),
  // Utils: src/**/utils/**/*.ts
  fc
    .tuple(
      fc.constantFrom("src/features", "src/app", "src/shared"),
      reactUtilNameArb
    )
    .map(([prefix, name]) => `${prefix}/utils/${name}.ts`)
);

/** Gera nome de arquivo de teste React correspondente */
const reactTestFileArb = (filePath: string) => {
  const baseName = filePath.replace(/\.(tsx?|ts)$/, "");
  return fc.constantFrom(
    `${baseName}.test.tsx`,
    `${baseName}.test.ts`,
    `${baseName}.spec.tsx`,
    `${baseName}.spec.ts`
  );
};

// ============================================================
// Testes de propriedade
// ============================================================

describe("Feature: archetype-code-review, Property 7: Detecção de testes faltantes", () => {
  describe("backend-csharp", () => {
    it("arquivo em Application/Domain sem teste correspondente → reporta missing_tests", () => {
      fc.assert(
        fc.property(csharpFileRequiringTestArb, (sourceFile) => {
          // Arrange: arquivo que requer teste, sem teste correspondente no PR
          const changedFiles = [sourceFile];
          const allFilesInPR = [sourceFile];

          // Act
          const violations = detectMissingTests(changedFiles, allFilesInPR, "backend-csharp");

          // Assert: deve reportar violação missing_tests
          expect(violations.length).toBeGreaterThanOrEqual(1);
          const violation = violations.find((v) => v.file === sourceFile);
          expect(violation).toBeDefined();
          expect(violation!.rule_id).toBe("missing_tests");
          expect(violation!.severity).toBe("error");
        }),
        { numRuns: 100 }
      );
    });

    it("arquivo em Application/Domain COM teste correspondente → sem violação", () => {
      fc.assert(
        fc.property(
          csharpFileRequiringTestArb.chain((sourceFile) => {
            const parts = sourceFile.split("/");
            const fileName = parts[parts.length - 1];
            const baseName = fileName.replace(/\.cs$/, "");
            return csharpTestFileArb(baseName).map((testFile) => ({
              sourceFile,
              testFile: `tests/${testFile}`,
            }));
          }),
          ({ sourceFile, testFile }) => {
            // Arrange: arquivo que requer teste + teste correspondente presente
            const changedFiles = [sourceFile];
            const allFilesInPR = [sourceFile, testFile];

            // Act
            const violations = detectMissingTests(changedFiles, allFilesInPR, "backend-csharp");

            // Assert: não deve reportar violação para este arquivo
            const violation = violations.find((v) => v.file === sourceFile);
            expect(violation).toBeUndefined();
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("bff-fastify", () => {
    it("arquivo em routes/services sem teste correspondente → reporta missing_tests", () => {
      fc.assert(
        fc.property(bffFileRequiringTestArb, (sourceFile) => {
          // Arrange: arquivo que requer teste, sem teste correspondente
          const changedFiles = [sourceFile];
          const allFilesInPR = [sourceFile];

          // Act
          const violations = detectMissingTests(changedFiles, allFilesInPR, "bff-fastify");

          // Assert: deve reportar violação
          expect(violations.length).toBeGreaterThanOrEqual(1);
          const violation = violations.find((v) => v.file === sourceFile);
          expect(violation).toBeDefined();
          expect(violation!.rule_id).toBe("missing_tests");
          expect(violation!.severity).toBe("error");
        }),
        { numRuns: 100 }
      );
    });

    it("arquivo em routes/services COM teste correspondente → sem violação", () => {
      fc.assert(
        fc.property(
          bffFileRequiringTestArb.chain((sourceFile) =>
            bffTestFileArb(sourceFile).map((testFile) => ({
              sourceFile,
              testFile,
            }))
          ),
          ({ sourceFile, testFile }) => {
            // Arrange: arquivo + teste correspondente presente
            const changedFiles = [sourceFile];
            const allFilesInPR = [sourceFile, testFile];

            // Act
            const violations = detectMissingTests(changedFiles, allFilesInPR, "bff-fastify");

            // Assert: não deve reportar violação
            const violation = violations.find((v) => v.file === sourceFile);
            expect(violation).toBeUndefined();
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("frontend-react", () => {
    it("componente/hook/util sem teste correspondente → reporta missing_tests", () => {
      fc.assert(
        fc.property(reactFileRequiringTestArb, (sourceFile) => {
          // Arrange: arquivo que requer teste, sem teste correspondente
          const changedFiles = [sourceFile];
          const allFilesInPR = [sourceFile];

          // Act
          const violations = detectMissingTests(changedFiles, allFilesInPR, "frontend-react");

          // Assert: deve reportar violação
          expect(violations.length).toBeGreaterThanOrEqual(1);
          const violation = violations.find((v) => v.file === sourceFile);
          expect(violation).toBeDefined();
          expect(violation!.rule_id).toBe("missing_tests");
          expect(violation!.severity).toBe("error");
        }),
        { numRuns: 100 }
      );
    });

    it("componente/hook/util COM teste correspondente → sem violação", () => {
      fc.assert(
        fc.property(
          reactFileRequiringTestArb.chain((sourceFile) =>
            reactTestFileArb(sourceFile).map((testFile) => ({
              sourceFile,
              testFile,
            }))
          ),
          ({ sourceFile, testFile }) => {
            // Arrange: arquivo + teste correspondente
            const changedFiles = [sourceFile];
            const allFilesInPR = [sourceFile, testFile];

            // Act
            const violations = detectMissingTests(changedFiles, allFilesInPR, "frontend-react");

            // Assert: não deve reportar violação
            const violation = violations.find((v) => v.file === sourceFile);
            expect(violation).toBeUndefined();
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("todas as violações têm severity error", () => {
    it("backend-csharp: violações sempre com severity error", () => {
      fc.assert(
        fc.property(
          fc.array(csharpFileRequiringTestArb, { minLength: 1, maxLength: 5 }),
          (sourceFiles) => {
            const violations = detectMissingTests(sourceFiles, sourceFiles, "backend-csharp");

            for (const violation of violations) {
              expect(violation.severity).toBe("error");
            }
          }
        ),
        { numRuns: 100 }
      );
    });

    it("bff-fastify: violações sempre com severity error", () => {
      fc.assert(
        fc.property(
          fc.array(bffFileRequiringTestArb, { minLength: 1, maxLength: 5 }),
          (sourceFiles) => {
            const violations = detectMissingTests(sourceFiles, sourceFiles, "bff-fastify");

            for (const violation of violations) {
              expect(violation.severity).toBe("error");
            }
          }
        ),
        { numRuns: 100 }
      );
    });

    it("frontend-react: violações sempre com severity error", () => {
      fc.assert(
        fc.property(
          fc.array(reactFileRequiringTestArb, { minLength: 1, maxLength: 5 }),
          (sourceFiles) => {
            const violations = detectMissingTests(sourceFiles, sourceFiles, "frontend-react");

            for (const violation of violations) {
              expect(violation.severity).toBe("error");
            }
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
