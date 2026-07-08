import { describe, it, expect } from "vitest";
import * as fc from "fast-check";

/**
 * Property 3: File filtering invariant
 *
 * Para qualquer lista de nomes de arquivos (output de git diff), após aplicar a filtragem
 * do job prepare, o resultado deve conter no máximo 50 arquivos e nenhum arquivo cujo
 * caminho inicie com `.` (dotfile).
 *
 * **Validates: Requirements 2.2**
 *
 * Tag: "Feature: archetype-code-review, Property 3: File filtering invariant"
 */

// Constante para o limite máximo de arquivos
const MAX_FILES = 50;

/**
 * Implementação da lógica de filtragem de arquivos alterados
 * (mesma lógica do workflow: excluir arquivos começando com '.', limitar a 50)
 *
 * Equivalente bash:
 *   git diff --name-only ... | grep -v '^\.' | head -50
 */
function filterChangedFiles(files: string[]): string[] {
  return files.filter((file) => !file.startsWith(".")).slice(0, MAX_FILES);
}

/**
 * Gerador de nomes de arquivo normais (não-dotfiles).
 * Gera caminhos como "src/utils/helper.ts", "README.md", etc.
 */
const normalFilenameArb = fc
  .array(
    fc.stringMatching(/^[a-zA-Z_][a-zA-Z0-9_.-]{0,20}$/),
    { minLength: 1, maxLength: 4 }
  )
  .map((parts) => parts.join("/"));

/**
 * Gerador de dotfiles — arquivos que começam com '.' no caminho.
 * Gera caminhos como ".eslintrc", ".gitignore", ".github/workflows/ci.yml"
 */
const dotfileArb = fc.oneof(
  // Dotfiles simples na raiz
  fc.constantFrom(
    ".eslintrc",
    ".gitignore",
    ".prettierrc",
    ".env",
    ".editorconfig",
    ".npmrc",
    ".dockerignore",
    ".babelrc"
  ),
  // Diretórios que começam com ponto
  fc.constantFrom(
    ".github/workflows/ci.yml",
    ".vscode/settings.json",
    ".kiro/agents/cli-code-reviewer.json",
    ".husky/pre-commit"
  ),
  // Dotfile genérico gerado
  fc
    .stringMatching(/^[a-z][a-z0-9_.-]{0,15}$/)
    .map((name) => `.${name}`)
);

/**
 * Gerador de listas mistas de filenames (normais + dotfiles).
 */
const fileListArb = fc.array(
  fc.oneof(
    { weight: 3, arbitrary: normalFilenameArb },
    { weight: 1, arbitrary: dotfileArb }
  ),
  { minLength: 0, maxLength: 200 }
);

describe("Feature: archetype-code-review, Property 3: File filtering invariant", () => {
  describe("Resultado tem no máximo 50 arquivos", () => {
    it("para qualquer lista de arquivos, o resultado filtrado deve ter no máximo 50 itens", () => {
      fc.assert(
        fc.property(fileListArb, (files) => {
          const result = filterChangedFiles(files);
          expect(result.length).toBeLessThanOrEqual(MAX_FILES);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Nenhum arquivo no resultado começa com '.'", () => {
    it("para qualquer lista de arquivos, nenhum arquivo filtrado deve iniciar com ponto", () => {
      fc.assert(
        fc.property(fileListArb, (files) => {
          const result = filterChangedFiles(files);
          for (const file of result) {
            expect(file.startsWith(".")).toBe(false);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Todos os arquivos no resultado estavam na lista original", () => {
    it("para qualquer lista de arquivos, todo arquivo no resultado deve existir na lista original", () => {
      fc.assert(
        fc.property(fileListArb, (files) => {
          const result = filterChangedFiles(files);
          for (const file of result) {
            expect(files).toContain(file);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Ordem preservada após filtragem", () => {
    it("a ordem relativa dos arquivos no resultado deve ser a mesma da lista original", () => {
      fc.assert(
        fc.property(fileListArb, (files) => {
          const result = filterChangedFiles(files);

          // Verificar que a ordem relativa é mantida
          let lastIndex = -1;
          for (const file of result) {
            const currentIndex = files.indexOf(file, lastIndex + 1);
            expect(currentIndex).toBeGreaterThan(lastIndex);
            lastIndex = currentIndex;
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Lista vazia retorna lista vazia", () => {
    it("se a lista de arquivos estiver vazia, o resultado deve ser vazio", () => {
      const result = filterChangedFiles([]);
      expect(result).toHaveLength(0);
    });
  });

  describe("Lista com apenas dotfiles retorna lista vazia", () => {
    it("para qualquer lista contendo somente dotfiles, o resultado deve ser vazio", () => {
      fc.assert(
        fc.property(
          fc.array(dotfileArb, { minLength: 1, maxLength: 100 }),
          (files) => {
            const result = filterChangedFiles(files);
            expect(result).toHaveLength(0);
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
