import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { mergeCODEOWNERS } from "./merge-codeowners.js";

/**
 * Property 3: Merge de CODEOWNERS sem duplicatas
 *
 * Para qualquer par de arquivos CODEOWNERS (archetype + projeto existente), após o merge:
 * todas as entradas originais do projeto devem ser preservadas, entradas do archetype com
 * path patterns novos devem ser adicionadas, e nenhum path pattern deve aparecer duplicado
 * no arquivo resultante.
 *
 * **Validates: Requirements 9.6**
 *
 * Tag: "Feature: archetype-code-review, Property 3: Merge de CODEOWNERS sem duplicatas"
 */

/**
 * Gerador de path patterns válidos para CODEOWNERS.
 */
const pathPatternArb = fc.oneof(
  fc.constant("*"),
  fc.constantFrom(
    ".github/",
    "src/",
    "docs/",
    "Dockerfile",
    "Makefile",
    "review-rules.yml",
    "*.ts",
    "*.cs",
    "*.yml",
    "tests/",
    "infra/",
    "config/",
    "scripts/",
    "lib/",
    "packages/"
  ),
  fc
    .stringMatching(/^[a-z][a-z0-9\-_/]{1,20}$/)
    .filter((s) => !s.startsWith("#"))
    .map((s) => (s.endsWith("/") ? s : s + "/"))
);

/**
 * Gerador de owners (times ou usuários GitHub).
 */
const ownerArb = fc.oneof(
  fc.constantFrom(
    "@team/core",
    "@team/platform",
    "@team/leads",
    "@team/frontend",
    "@team/backend",
    "@team/infra",
    "@team/docs"
  ),
  fc.stringMatching(/^@[a-z][a-z0-9\-]{1,15}$/)
);

/**
 * Gerador de lista de owners (1 a 3 owners por linha).
 */
const ownersListArb = fc
  .array(ownerArb, { minLength: 1, maxLength: 3 })
  .map((owners) => owners.join(" "));

/**
 * Gerador de uma entrada CODEOWNERS (path pattern + owners).
 */
const codeownersEntryArb = fc
  .tuple(pathPatternArb, ownersListArb)
  .map(([pattern, owners]) => `${pattern} ${owners}`);

/**
 * Gerador de conteúdo CODEOWNERS com entradas únicas (sem duplicatas de path pattern).
 */
const codeownersContentArb = (minEntries: number, maxEntries: number) =>
  fc
    .uniqueArray(pathPatternArb, { minLength: minEntries, maxLength: maxEntries })
    .chain((patterns) =>
      fc.tuple(...patterns.map(() => ownersListArb)).map((ownersList) =>
        patterns.map((pattern, i) => `${pattern} ${ownersList[i]}`).join("\n") + "\n"
      )
    );

/**
 * Extrai path patterns de um conteúdo CODEOWNERS (ignora comentários e linhas vazias).
 */
function extractPatterns(content: string): string[] {
  return content
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l !== "" && !l.startsWith("#"))
    .map((l) => l.split(/\s+/)[0]);
}

/**
 * Extrai entradas completas (linhas não-vazio, não-comentário).
 */
function extractEntryLines(content: string): string[] {
  return content
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l !== "" && !l.startsWith("#"));
}

describe("Feature: archetype-code-review, Property 3: Merge de CODEOWNERS sem duplicatas", () => {
  describe("Propriedade 1: Todos os path patterns do existingContent são preservados no resultado", () => {
    it("todas as entradas existentes devem estar presentes no resultado do merge", () => {
      fc.assert(
        fc.property(
          codeownersContentArb(1, 5),
          codeownersContentArb(1, 5),
          (existingContent, archetypeContent) => {
            const result = mergeCODEOWNERS(archetypeContent, existingContent);
            const existingPatterns = extractPatterns(existingContent);
            const resultPatterns = extractPatterns(result);

            // Todos os patterns do existente devem estar no resultado
            for (const pattern of existingPatterns) {
              expect(resultPatterns).toContain(pattern);
            }
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Propriedade 2: Novos path patterns do archetypeContent são adicionados ao resultado", () => {
    it("patterns do archetype que não existem no existing devem ser adicionados", () => {
      fc.assert(
        fc.property(
          codeownersContentArb(1, 5),
          codeownersContentArb(1, 5),
          (existingContent, archetypeContent) => {
            const result = mergeCODEOWNERS(archetypeContent, existingContent);
            const existingPatterns = new Set(extractPatterns(existingContent));
            const archetypePatterns = extractPatterns(archetypeContent);
            const resultPatterns = extractPatterns(result);

            // Patterns do archetype que não existem no existing devem estar no resultado
            const newPatterns = archetypePatterns.filter(
              (p) => !existingPatterns.has(p)
            );
            for (const pattern of newPatterns) {
              expect(resultPatterns).toContain(pattern);
            }
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Propriedade 3: Nenhum path pattern aparece mais de uma vez no resultado (sem duplicatas)", () => {
    it("o resultado não deve conter path patterns duplicados", () => {
      fc.assert(
        fc.property(
          codeownersContentArb(1, 5),
          codeownersContentArb(1, 5),
          (existingContent, archetypeContent) => {
            const result = mergeCODEOWNERS(archetypeContent, existingContent);
            const resultPatterns = extractPatterns(result);

            // Nenhum pattern deve aparecer mais de uma vez
            const uniquePatterns = new Set(resultPatterns);
            expect(resultPatterns.length).toBe(uniquePatterns.size);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Propriedade 4: A ordem das entradas existentes é preservada (existentes vêm antes das novas)", () => {
    it("entradas existentes devem aparecer antes das entradas novas no resultado", () => {
      fc.assert(
        fc.property(
          codeownersContentArb(1, 5),
          codeownersContentArb(1, 5),
          (existingContent, archetypeContent) => {
            const result = mergeCODEOWNERS(archetypeContent, existingContent);
            const existingPatterns = extractPatterns(existingContent);
            const existingPatternsSet = new Set(existingPatterns);
            const archetypePatterns = extractPatterns(archetypeContent);
            const resultPatterns = extractPatterns(result);

            // Determinar quais são patterns novos (do archetype, não presentes no existing)
            const newPatterns = new Set(
              archetypePatterns.filter((p) => !existingPatternsSet.has(p))
            );

            if (newPatterns.size === 0) return; // Nada a verificar se não há novos

            // Encontrar o último índice de um pattern existente no resultado
            let lastExistingIndex = -1;
            for (let i = 0; i < resultPatterns.length; i++) {
              if (existingPatternsSet.has(resultPatterns[i])) {
                lastExistingIndex = i;
              }
            }

            // Encontrar o primeiro índice de um pattern novo no resultado
            let firstNewIndex = resultPatterns.length;
            for (let i = 0; i < resultPatterns.length; i++) {
              if (newPatterns.has(resultPatterns[i])) {
                firstNewIndex = i;
                break;
              }
            }

            // Todos os patterns existentes devem vir antes dos novos
            expect(lastExistingIndex).toBeLessThan(firstNewIndex);
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
