import { describe, it, expect } from "vitest";
import * as fc from "fast-check";

/**
 * Property 4: ANSI stripping completeness
 *
 * Para qualquer string contendo escape sequences ANSI arbitrárias,
 * após aplicar a função de strip (perl regex), o resultado não deve conter
 * nenhum escape sequence ANSI (padrão \e[...m, \e]...\a, \e[?...).
 *
 * **Validates: Requirements 3.2**
 *
 * Tag: "Feature: archetype-code-review, Property 4: ANSI stripping completeness"
 */

// ============================================================================
// Implementação da função stripAnsi que replica a regex perl do workflow:
// perl -pe 's/\e\[[0-9;]*[mGKHJF]//g; s/\e\][^\a]*\a//g; s/\e\[[\?]?[0-9;]*[a-zA-Z]//g; s/\x1b[^[]*//g; s/\r//g'
// ============================================================================

/**
 * Remove escape sequences ANSI de uma string, replicando o comportamento
 * da cadeia de regexes perl usada no workflow de code review.
 */
function stripAnsi(input: string): string {
  let result = input;

  // 1. s/\e\[[0-9;]*[mGKHJF]//g — CSI sequences comuns (cores, cursor)
  result = result.replace(/\x1b\[[0-9;]*[mGKHJF]/g, "");

  // 2. s/\e\][^\a]*\a//g — OSC sequences (Operating System Command)
  result = result.replace(/\x1b\][^\x07]*\x07/g, "");

  // 3. s/\e\[[\?]?[0-9;]*[a-zA-Z]//g — CSI sequences genéricas (inclui ?-prefixed)
  result = result.replace(/\x1b\[\??[0-9;]*[a-zA-Z]/g, "");

  // 4. s/\x1b[^[]*//g — Qualquer ESC restante seguido de não-'['
  //    Nota: Em perl, [^[] significa qualquer char exceto '['. O * é greedy.
  //    Isso captura sequences como ESC seguido de texto até encontrar '[' ou fim.
  result = result.replace(/\x1b[^[]*/g, "");

  // 5. s/\r//g — Remove carriage returns
  result = result.replace(/\r/g, "");

  return result;
}

// ============================================================================
// Geradores (Arbitraries) para strings com escape sequences ANSI
// ============================================================================

/** Gera um código de escape CSI comum: ESC[<params><letra> */
const csiSequenceArb = fc
  .tuple(
    fc.array(fc.integer({ min: 0, max: 107 }), { minLength: 0, maxLength: 5 }),
    fc.constantFrom(
      "m", "G", "K", "H", "J", "F", "A", "B", "C", "D", "E",
      "f", "h", "l", "n", "r", "s", "u"
    ),
    fc.boolean() // com ou sem '?' prefix
  )
  .map(([params, letter, hasQuestion]) => {
    const prefix = hasQuestion ? "?" : "";
    return `\x1b[${prefix}${params.join(";")}${letter}`;
  });

/** Gera uma OSC sequence: ESC]<conteúdo>BEL */
const oscSequenceArb = fc
  .string({ minLength: 0, maxLength: 20 })
  .filter((s) => !s.includes("\x07")) // sem BEL no conteúdo
  .map((content) => `\x1b]${content}\x07`);

/** Gera ESC seguido de chars que não são '[' (capturado pela regex 4) */
const escOtherArb = fc
  .string({ minLength: 1, maxLength: 10 })
  .filter((s) => !s.includes("[") && !s.includes("\x1b"))
  .map((content) => `\x1b${content}`);

/** Gera qualquer tipo de escape sequence ANSI */
const ansiSequenceArb = fc.oneof(
  csiSequenceArb,
  oscSequenceArb,
  escOtherArb
);

/** Gera texto puro sem ESC nem \r */
const plainTextArb = fc
  .string({ minLength: 0, maxLength: 30 })
  .filter((s) => !s.includes("\x1b") && !s.includes("\r"));

/** Gera uma string com texto puro intercalado com escape sequences ANSI */
const stringWithAnsiArb = fc
  .array(
    fc.oneof(
      { weight: 3, arbitrary: plainTextArb },
      { weight: 2, arbitrary: ansiSequenceArb },
      { weight: 1, arbitrary: fc.constant("\r") }
    ),
    { minLength: 1, maxLength: 15 }
  )
  .map((parts) => parts.join(""));

// ============================================================================
// Testes de propriedade
// ============================================================================

describe("Feature: archetype-code-review, Property 4: ANSI stripping completeness", () => {
  it("após stripping, resultado não contém caractere ESC (\\x1B)", () => {
    fc.assert(
      fc.property(stringWithAnsiArb, (input) => {
        const result = stripAnsi(input);
        expect(result).not.toContain("\x1b");
      }),
      { numRuns: 100 }
    );
  });

  it("após stripping, resultado não contém caractere \\r", () => {
    fc.assert(
      fc.property(stringWithAnsiArb, (input) => {
        const result = stripAnsi(input);
        expect(result).not.toContain("\r");
      }),
      { numRuns: 100 }
    );
  });

  it("texto puro (sem ANSI sequences) passa inalterado pelo strip", () => {
    fc.assert(
      fc.property(plainTextArb, (input) => {
        const result = stripAnsi(input);
        expect(result).toBe(input);
      }),
      { numRuns: 100 }
    );
  });
});
