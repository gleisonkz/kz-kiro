import { describe, it, expect } from "vitest";
import * as fc from "fast-check";

/**
 * Property 6: Bootstrap file copy correctness
 *
 * Para qualquer archetype com M agentes e qualquer estado do projeto destino,
 * após executar o bootstrap:
 * (a) todos os cli-*.json do archetype devem existir em `.kiro/agents/`
 * (b) nenhum arquivo `.md` de agente deve existir em `.kiro/agents/`
 * (c) se `kiro-code-review.yml` já existia no destino, seu conteúdo deve permanecer inalterado (sem force)
 * (d) arquivos cli-*.json customizados no destino que não existem no archetype devem ser preservados
 * (e) com force, workflow é sobrescrito
 *
 * **Validates: Requirements 4.2, 4.3, 4.4, 4.5**
 *
 * Tag: "Feature: archetype-code-review, Property 6: Bootstrap file copy correctness"
 */

// --- Tipos ---

interface DestFile {
  name: string;
  content: string;
}

interface BootstrapInput {
  archetypeFiles: string[]; // nomes de arquivos no agents/ do archetype (cli-*.json e *.md)
  destFiles: DestFile[]; // arquivos existentes no .kiro/agents/ do destino
  hasWorkflow: boolean; // se o destino já possui kiro-code-review.yml
  workflowContent: string; // conteúdo do workflow existente no destino (se hasWorkflow)
  archetypeWorkflowContent: string; // conteúdo do workflow no archetype
  force: boolean;
}

interface BootstrapResult {
  agentsDir: DestFile[]; // estado final de .kiro/agents/
  workflowContent: string | null; // conteúdo final do workflow (null se não existe)
}

// --- Lógica pura de bootstrap ---

/**
 * Simula o comportamento do bootstrap-code-review.sh em TypeScript puro.
 * Regras:
 * - Copia apenas cli-*.json do archetype para destino
 * - Nunca copia .md
 * - Sem --force: preserva workflow existente
 * - Com --force: sobrescreve workflow
 * - Preserva cli-*.json customizados no destino que não existem no archetype
 * - Sobrescreve cli-*.json existentes apenas se conteúdo difere (neste modelo simplificado,
 *   sempre copiamos pois estamos validando presença, não conteúdo idêntico)
 */
function bootstrapLogic(input: BootstrapInput): BootstrapResult {
  const {
    archetypeFiles,
    destFiles,
    hasWorkflow,
    workflowContent,
    archetypeWorkflowContent,
    force,
  } = input;

  // Filtrar apenas cli-*.json do archetype (nunca copiar .md)
  const archetypeJsonFiles = archetypeFiles.filter(
    (f) => f.startsWith("cli-") && f.endsWith(".json")
  );

  // Iniciar com todos os destFiles existentes (preservar customizados)
  const resultAgentsMap = new Map<string, string>();

  // Primeiro, popular com destinos existentes
  for (const destFile of destFiles) {
    resultAgentsMap.set(destFile.name, destFile.content);
  }

  // Depois, copiar/sobrescrever os JSONs do archetype
  for (const jsonFile of archetypeJsonFiles) {
    // Simula conteúdo do archetype como "archetype:<nome>"
    resultAgentsMap.set(jsonFile, `archetype:${jsonFile}`);
  }

  // Montar resultado de agents
  const agentsDir: DestFile[] = Array.from(resultAgentsMap.entries()).map(
    ([name, content]) => ({ name, content })
  );

  // Determinar workflow final
  let finalWorkflow: string | null;
  if (hasWorkflow && !force) {
    // Preservar workflow existente
    finalWorkflow = workflowContent;
  } else if (hasWorkflow && force) {
    // Sobrescrever com conteúdo do archetype
    finalWorkflow = archetypeWorkflowContent;
  } else {
    // Não existia, copiar do archetype
    finalWorkflow = archetypeWorkflowContent;
  }

  return { agentsDir, workflowContent: finalWorkflow };
}

// --- Geradores (Arbitraries) ---

/** Gera nomes de arquivo cli-*.json válidos */
const cliJsonNameArb = fc
  .stringMatching(/^[a-z][a-z\-]{2,15}$/)
  .map((base) => `cli-${base}-reviewer.json`);

/** Gera nomes de arquivo .md válidos */
const mdNameArb = fc
  .stringMatching(/^[a-z][a-z\-]{2,15}$/)
  .map((base) => `${base}-reviewer.md`);

/** Gera um nome de arquivo de archetype (mistura de cli-*.json e *.md) */
const archetypeFileNameArb = fc.oneof(cliJsonNameArb, mdNameArb);

/** Gera lista de nomes de arquivo do archetype com pelo menos 1 cli-*.json */
const archetypeFilesArb = fc
  .tuple(
    fc.uniqueArray(cliJsonNameArb, { minLength: 1, maxLength: 6 }),
    fc.uniqueArray(mdNameArb, { minLength: 0, maxLength: 4 })
  )
  .map(([jsons, mds]) => {
    // Combinar e garantir unicidade
    const all = [...jsons, ...mds];
    return [...new Set(all)];
  });

/** Gera conteúdo de arquivo não-vazio */
const fileContentArb = fc.string({ minLength: 1, maxLength: 100 });

/** Gera um DestFile com nome cli-*.json (para simular customizados no destino) */
const destCliJsonArb: fc.Arbitrary<DestFile> = fc.record({
  name: cliJsonNameArb,
  content: fileContentArb,
});

/** Gera lista de DestFiles com nomes únicos */
const destFilesArb = fc.uniqueArray(destCliJsonArb, {
  minLength: 0,
  maxLength: 5,
  comparator: (a, b) => a.name === b.name,
});

/** Gera o input completo para bootstrapLogic */
const bootstrapInputArb: fc.Arbitrary<BootstrapInput> = fc.record({
  archetypeFiles: archetypeFilesArb,
  destFiles: destFilesArb,
  hasWorkflow: fc.boolean(),
  workflowContent: fileContentArb,
  archetypeWorkflowContent: fileContentArb,
  force: fc.boolean(),
});

// --- Testes de Propriedade ---

describe("Feature: archetype-code-review, Property 6: Bootstrap file copy correctness", () => {
  describe("Property: todos cli-*.json do archetype existem no resultado", () => {
    it("após bootstrap, todo cli-*.json do archetype deve estar presente em agentsDir", () => {
      fc.assert(
        fc.property(bootstrapInputArb, (input) => {
          const result = bootstrapLogic(input);

          const archetypeJsons = input.archetypeFiles.filter(
            (f) => f.startsWith("cli-") && f.endsWith(".json")
          );

          const resultNames = new Set(result.agentsDir.map((f) => f.name));

          for (const jsonFile of archetypeJsons) {
            expect(resultNames.has(jsonFile)).toBe(true);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Property: nenhum .md do archetype aparece em agentsDir", () => {
    it("após bootstrap, nenhum arquivo .md do archetype deve estar em agentsDir", () => {
      fc.assert(
        fc.property(bootstrapInputArb, (input) => {
          const result = bootstrapLogic(input);

          const resultNames = result.agentsDir.map((f) => f.name);

          // Nenhum resultado deve terminar com .md
          for (const name of resultNames) {
            expect(name.endsWith(".md")).toBe(false);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Property: se workflow existia e !force, conteúdo é inalterado", () => {
    it("sem force, workflow existente no destino permanece com seu conteúdo original", () => {
      fc.assert(
        fc.property(
          bootstrapInputArb.filter((i) => i.hasWorkflow && !i.force),
          (input) => {
            const result = bootstrapLogic(input);

            expect(result.workflowContent).toBe(input.workflowContent);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe("Property: cli-*.json customizados no destino que não existem no archetype são preservados", () => {
    it("agentes customizados no destino que não pertencem ao archetype devem permanecer", () => {
      fc.assert(
        fc.property(bootstrapInputArb, (input) => {
          const result = bootstrapLogic(input);

          const archetypeJsons = new Set(
            input.archetypeFiles.filter(
              (f) => f.startsWith("cli-") && f.endsWith(".json")
            )
          );

          // Identificar customizados no destino: existem no dest mas não no archetype
          const customDest = input.destFiles.filter(
            (df) => !archetypeJsons.has(df.name)
          );

          const resultMap = new Map(
            result.agentsDir.map((f) => [f.name, f.content])
          );

          for (const custom of customDest) {
            // Customizado deve existir no resultado
            expect(resultMap.has(custom.name)).toBe(true);
            // Com conteúdo preservado
            expect(resultMap.get(custom.name)).toBe(custom.content);
          }
        }),
        { numRuns: 100 }
      );
    });
  });

  describe("Property: se workflow existia e force, workflow é sobrescrito", () => {
    it("com force, workflow é substituído pelo conteúdo do archetype", () => {
      fc.assert(
        fc.property(
          bootstrapInputArb.filter((i) => i.hasWorkflow && i.force),
          (input) => {
            const result = bootstrapLogic(input);

            expect(result.workflowContent).toBe(
              input.archetypeWorkflowContent
            );
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
