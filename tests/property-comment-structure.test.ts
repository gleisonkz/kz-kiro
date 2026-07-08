import { describe, it, expect } from "vitest";
import * as fc from "fast-check";

/**
 * Property 5: Estrutura do comentário consolidado
 *
 * Para qualquer conjunto de N resultados de agentes (incluindo ausentes),
 * o comentário consolidado deve:
 * (a) iniciar com `<!-- kiro-code-review-bot -->`,
 * (b) conter exatamente N seções `<details>`,
 * (c) conter título "Kiro Code Review",
 * (d) conter rodapé com lista de agentes,
 * (e) para cada agente sem resultado, exibir "Nenhum resultado disponível"
 *
 * **Validates: Requirements 3.3, 3.4, 3.7, 6.4**
 *
 * Tag: "Feature: archetype-code-review, Property 5: Consolidated comment structure"
 */

// --- Tipos ---

interface AgentResult {
  name: string;
  emoji: string;
  title: string;
  content: string | null;
}

// --- Implementação da lógica de montagem do comentário consolidado ---

const COMMENT_MARKER = "<!-- kiro-code-review-bot -->";
const FALLBACK_MESSAGE = "Nenhum resultado disponível";

/**
 * Replica a lógica do workflow de consolidação de comentário.
 * Gera o PR comment consolidado com base nos resultados dos agentes.
 */
function buildConsolidatedComment(agents: AgentResult[]): string {
  const lines: string[] = [];

  // Marker para identificação (idempotência)
  lines.push(COMMENT_MARKER);
  lines.push(`## 🤖 Kiro Code Review`);
  lines.push("");
  lines.push(
    `Revisão automática executada por ${agents.length} agentes especializados.`
  );
  lines.push("");
  lines.push("---");
  lines.push("");

  // Uma seção <details> por agente
  for (const agent of agents) {
    lines.push(`### ${agent.emoji} ${agent.title}`);
    lines.push("");
    lines.push("<details>");
    lines.push(`<summary>Expandir revisão de ${agent.name}</summary>`);
    lines.push("");

    if (agent.content === null) {
      lines.push(`_${FALLBACK_MESSAGE}._`);
    } else {
      lines.push(agent.content);
    }

    lines.push("");
    lines.push("</details>");
    lines.push("");
  }

  // Rodapé com lista de agentes
  lines.push("---");
  const agentNames = agents.map((a) => a.name).join(", ");
  lines.push(
    `*Revisão automática por [Kiro CLI](https://kiro.dev) · agentes: ${agentNames}*`
  );

  return lines.join("\n");
}

// --- Geradores ---

/**
 * Gerador de nomes de agentes válidos (formato kebab-case).
 */
const agentNameArb = fc
  .stringMatching(/^[a-z][a-z\-]{2,20}$/)
  .filter((s) => !s.endsWith("-") && !s.includes("--"));

/**
 * Gerador de emoji (subset representativo de emojis usados nos workflows).
 */
const emojiArb = fc.constantFrom(
  "📝",
  "🏗️",
  "♿",
  "⚡",
  "🔒",
  "📋",
  "🤖",
  "🧪",
  "🎨"
);

/**
 * Gerador de título do agente (texto livre curto).
 */
const titleArb = fc.string({ minLength: 3, maxLength: 30 }).filter((s) => {
  // Evitar caracteres que quebrariam parsing de markdown
  return !s.includes("\n") && !s.includes("<") && !s.includes(">");
});

/**
 * Gerador de conteúdo markdown (pode ser null para simular artifact ausente).
 */
const contentArb = fc.option(
  fc.string({ minLength: 1, maxLength: 500 }).filter((s) => {
    // Evitar strings que conteriam false positives nas assertions
    return !s.includes("<details>") && !s.includes("</details>");
  }),
  { nil: null }
);

/**
 * Gerador de resultado de um agente individual.
 */
const agentResultArb: fc.Arbitrary<AgentResult> = fc.record({
  name: agentNameArb,
  emoji: emojiArb,
  title: titleArb,
  content: contentArb,
});

/**
 * Gerador de array de resultados de agentes (1 a 8 agentes).
 */
const agentResultsArb = fc.array(agentResultArb, {
  minLength: 1,
  maxLength: 8,
});

// --- Testes de Propriedade ---

describe("Feature: archetype-code-review, Property 5: Consolidated comment structure", () => {
  it("comentário inicia com o marker '<!-- kiro-code-review-bot -->'", () => {
    fc.assert(
      fc.property(agentResultsArb, (agents) => {
        const comment = buildConsolidatedComment(agents);
        expect(comment.startsWith(COMMENT_MARKER)).toBe(true);
      }),
      { numRuns: 100 }
    );
  });

  it("comentário contém exatamente N seções <details> (uma por agente)", () => {
    fc.assert(
      fc.property(agentResultsArb, (agents) => {
        const comment = buildConsolidatedComment(agents);
        const detailsOpenCount = (comment.match(/<details>/g) || []).length;
        const detailsCloseCount = (comment.match(/<\/details>/g) || []).length;

        expect(detailsOpenCount).toBe(agents.length);
        expect(detailsCloseCount).toBe(agents.length);
      }),
      { numRuns: 100 }
    );
  });

  it("comentário contém o título 'Kiro Code Review'", () => {
    fc.assert(
      fc.property(agentResultsArb, (agents) => {
        const comment = buildConsolidatedComment(agents);
        expect(comment).toContain("Kiro Code Review");
      }),
      { numRuns: 100 }
    );
  });

  it("comentário contém rodapé com nomes de todos os agentes", () => {
    fc.assert(
      fc.property(agentResultsArb, (agents) => {
        const comment = buildConsolidatedComment(agents);

        // O rodapé deve conter cada nome de agente
        for (const agent of agents) {
          expect(comment).toContain(agent.name);
        }

        // Rodapé segue o padrão esperado
        expect(comment).toContain("agentes:");
        expect(comment).toContain("Kiro CLI");
      }),
      { numRuns: 100 }
    );
  });

  it("para cada agente com content null, a seção contém 'Nenhum resultado disponível'", () => {
    fc.assert(
      fc.property(agentResultsArb, (agents) => {
        const comment = buildConsolidatedComment(agents);
        const nullAgents = agents.filter((a) => a.content === null);
        const fallbackCount = (
          comment.match(/Nenhum resultado disponível/g) || []
        ).length;

        // Deve haver pelo menos tantos fallbacks quantos agentes sem resultado
        expect(fallbackCount).toBeGreaterThanOrEqual(nullAgents.length);
      }),
      { numRuns: 100 }
    );
  });

  it("para cada agente com content presente, o conteúdo aparece na sua seção", () => {
    fc.assert(
      fc.property(agentResultsArb, (agents) => {
        const comment = buildConsolidatedComment(agents);

        for (const agent of agents) {
          if (agent.content !== null) {
            expect(comment).toContain(agent.content);
          }
        }
      }),
      { numRuns: 100 }
    );
  });

  it("cada seção <details> está associada ao título e emoji corretos do agente", () => {
    fc.assert(
      fc.property(agentResultsArb, (agents) => {
        const comment = buildConsolidatedComment(agents);

        for (const agent of agents) {
          // Cada agente deve ter seu título com emoji como heading antes do <details>
          expect(comment).toContain(`### ${agent.emoji} ${agent.title}`);
          // Cada summary deve mencionar o nome do agente
          expect(comment).toContain(
            `<summary>Expandir revisão de ${agent.name}</summary>`
          );
        }
      }),
      { numRuns: 100 }
    );
  });
});
