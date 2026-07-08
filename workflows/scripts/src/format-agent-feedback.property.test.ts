import { describe, it, expect } from "vitest";
import * as fc from "fast-check";
import { formatAgentFeedback } from "./format-agent-feedback.js";

/**
 * Property 10: Feedback de agent formatado corretamente
 *
 * Para qualquer saída de texto produzida por um Review_Agent, o PR_Comment gerado
 * deve conter: título da seção, severidade de cada item, localização no código
 * (quando disponível) e sugestão de correção — formatados em markdown válido.
 *
 * **Validates: Requirements 7.3**
 *
 * Tag: "Feature: archetype-code-review, Property 10: Feedback de agent formatado corretamente"
 */

/** Gera um nome de arquivo válido para marcador FILE: */
const filePathArb = fc
  .stringMatching(/^[a-z][a-z0-9/\-_.]{1,40}\.[a-z]{1,4}$/)
  .filter((s) => !s.includes("..") && !s.endsWith("/"));

/** Gera um número de linha válido */
const lineNumberArb = fc.integer({ min: 1, max: 9999 });

/** Gera uma localização FILE: em um dos formatos suportados */
const fileLocationArb = fc.oneof(
  // formato arquivo:linha
  fc.tuple(filePathArb, lineNumberArb).map(([f, l]) => `${f}:${l}`),
  // formato arquivo(linha)
  fc.tuple(filePathArb, lineNumberArb).map(([f, l]) => `${f}(${l})`),
  // formato arquivo line N
  fc.tuple(filePathArb, lineNumberArb).map(([f, l]) => `${f} line ${l}`),
  // formato somente arquivo (sem linha)
  filePathArb
);

/** Gera texto de título (sem caracteres que confundam os marcadores) */
const titleArb = fc
  .string({ minLength: 1, maxLength: 80 })
  .filter((s) => !/^(ERROR|WARN|WARNING|FILE|SUGGESTION):/i.test(s.trim()))
  .filter((s) => s.trim().length > 0);

/** Gera texto de sugestão (sem marcadores internos) */
const suggestionArb = fc
  .string({ minLength: 1, maxLength: 120 })
  .filter((s) => !/^(ERROR|WARN|WARNING|FILE|SUGGESTION):/i.test(s.trim()))
  .filter((s) => s.trim().length > 0);

/** Gera texto de descrição (linhas sem marcadores) */
const descriptionLineArb = fc
  .string({ minLength: 1, maxLength: 100 })
  .filter((s) => !/^(ERROR|WARN|WARNING|FILE|SUGGESTION):/i.test(s.trim()))
  .filter((s) => s.trim().length > 0);

/** Tipo de severidade (ERROR ou WARN) */
const severityMarkerArb = fc.constantFrom("ERROR", "WARN");

/** Gera um issue estruturado com todos os campos possíveis */
const fullIssueArb = fc.record({
  severity: severityMarkerArb,
  title: titleArb,
  file: fc.option(fileLocationArb, { nil: undefined }),
  description: fc.array(descriptionLineArb, { minLength: 0, maxLength: 3 }),
  suggestion: fc.option(suggestionArb, { nil: undefined }),
});

/** Converte um issue record em string textual no formato esperado pelo parser */
function issueToString(issue: {
  severity: string;
  title: string;
  file?: string;
  description: string[];
  suggestion?: string;
}): string {
  const lines: string[] = [];
  lines.push(`${issue.severity}: ${issue.title}`);
  if (issue.file) {
    lines.push(`FILE: ${issue.file}`);
  }
  for (const d of issue.description) {
    lines.push(d);
  }
  if (issue.suggestion) {
    lines.push(`SUGGESTION: ${issue.suggestion}`);
  }
  return lines.join("\n");
}

/** Gera input de agent com pelo menos um marcador ERROR ou WARN */
const agentOutputWithIssuesArb = fc
  .array(fullIssueArb, { minLength: 1, maxLength: 5 })
  .map((issues) => issues.map(issueToString).join("\n"));

/** Gera input de agent com pelo menos um issue que tem FILE: */
const agentOutputWithFileArb = fc
  .tuple(
    fc.array(fullIssueArb, { minLength: 0, maxLength: 2 }),
    fc.record({
      severity: severityMarkerArb,
      title: titleArb,
      file: fileLocationArb.map((f) => f as string | undefined),
      description: fc.array(descriptionLineArb, { minLength: 0, maxLength: 2 }),
      suggestion: fc.option(suggestionArb, { nil: undefined }),
    }),
    fc.array(fullIssueArb, { minLength: 0, maxLength: 2 })
  )
  .map(([before, withFile, after]) => {
    const all = [...before, withFile, ...after];
    return all.map(issueToString).join("\n");
  });

/** Gera input de agent com pelo menos um issue que tem SUGGESTION: */
const agentOutputWithSuggestionArb = fc
  .tuple(
    fc.array(fullIssueArb, { minLength: 0, maxLength: 2 }),
    fc.record({
      severity: severityMarkerArb,
      title: titleArb,
      file: fc.option(fileLocationArb, { nil: undefined }),
      description: fc.array(descriptionLineArb, { minLength: 0, maxLength: 2 }),
      suggestion: suggestionArb,
    }),
    fc.array(fullIssueArb, { minLength: 0, maxLength: 2 })
  )
  .map(([before, withSuggestion, after]) => {
    const all = [...before, withSuggestion, ...after];
    return all.map(issueToString).join("\n");
  });

describe("Feature: archetype-code-review, Property 10: Feedback de agent formatado corretamente", () => {
  it("output com issues deve conter heading com label de severidade", () => {
    fc.assert(
      fc.property(agentOutputWithIssuesArb, (agentOutput) => {
        const result = formatAgentFeedback(agentOutput);

        // Deve conter ao menos um heading com label de severidade [Error] ou [Warning]
        const hasSeverityHeading =
          result.includes("[Error]") || result.includes("[Warning]");
        expect(hasSeverityHeading).toBe(true);

        // Cada heading de severidade deve estar em formato ### com ícone
        const headingPattern = /### [🚫⚠️]+ \[(Error|Warning)\]/;
        expect(headingPattern.test(result)).toBe(true);
      }),
      { numRuns: 100 }
    );
  });

  it("quando FILE: presente no input, o output contém '**Localização:**' com referência ao arquivo", () => {
    fc.assert(
      fc.property(agentOutputWithFileArb, (agentOutput) => {
        const result = formatAgentFeedback(agentOutput);

        // Deve conter a seção de localização
        expect(result).toContain("**Localização:**");

        // A localização deve conter referência em backticks (formato code)
        const localizacaoPattern = /\*\*Localização:\*\*\s+`[^`]+`/;
        expect(localizacaoPattern.test(result)).toBe(true);
      }),
      { numRuns: 100 }
    );
  });

  it("quando SUGGESTION: presente no input, o output contém '**Sugestão:**'", () => {
    fc.assert(
      fc.property(agentOutputWithSuggestionArb, (agentOutput) => {
        const result = formatAgentFeedback(agentOutput);

        expect(result).toContain("**Sugestão:**");
      }),
      { numRuns: 100 }
    );
  });

  it("output sempre começa com '## 🤖 Revisão via Agent'", () => {
    // Testa com qualquer string arbitrária — incluindo strings sem marcadores
    fc.assert(
      fc.property(fc.string({ minLength: 0, maxLength: 500 }), (agentOutput) => {
        const result = formatAgentFeedback(agentOutput);

        expect(result.startsWith("## 🤖 Revisão via Agent")).toBe(true);
      }),
      { numRuns: 100 }
    );
  });

  it("output é markdown válido — sem formatação bold/italic não fechada", () => {
    // Para esta propriedade, usamos conteúdo sem caracteres especiais de markdown
    // pois a função não escapa conteúdo do usuário (design intencional).
    // Testamos que a *estrutura* gerada pela função é markdown válido.
    const safeTextArb = fc
      .stringMatching(/^[a-zA-Z0-9 .,;:!?\-()]{1,80}$/)
      .filter((s) => s.trim().length > 0)
      .filter((s) => !/^(ERROR|WARN|WARNING|FILE|SUGGESTION):/i.test(s.trim()));

    const safeIssueArb = fc.record({
      severity: severityMarkerArb,
      title: safeTextArb,
      file: fc.option(fileLocationArb, { nil: undefined }),
      description: fc.array(safeTextArb, { minLength: 0, maxLength: 3 }),
      suggestion: fc.option(safeTextArb, { nil: undefined }),
    });

    const safeAgentOutputArb = fc
      .array(safeIssueArb, { minLength: 1, maxLength: 5 })
      .map((issues) => issues.map(issueToString).join("\n"));

    fc.assert(
      fc.property(safeAgentOutputArb, (agentOutput) => {
        const result = formatAgentFeedback(agentOutput);

        // Verificar que não há ** não-fechados (bold)
        // Conta ocorrências de ** — deve ser par
        const boldMarkers = result.match(/\*\*/g) || [];
        expect(boldMarkers.length % 2).toBe(0);

        // Verificar que não há backticks não-fechados (inline code)
        // Conta ocorrências de ` (desconsiderando ```) — deve ser par
        const resultWithoutTriple = result.replace(/```/g, "");
        const backtickMarkers = resultWithoutTriple.match(/`/g) || [];
        expect(backtickMarkers.length % 2).toBe(0);

        // Headings devem começar em início de linha
        const lines = result.split("\n");
        for (const line of lines) {
          if (line.includes("###") || line.includes("##")) {
            const trimmed = line.trimStart();
            if (trimmed.startsWith("#")) {
              // Heading correto: # seguido de espaço
              expect(trimmed).toMatch(/^#{1,6}\s/);
            }
          }
        }
      }),
      { numRuns: 100 }
    );
  });
});
