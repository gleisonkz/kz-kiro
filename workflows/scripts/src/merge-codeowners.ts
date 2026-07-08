/**
 * Módulo de merge para arquivos CODEOWNERS.
 * Combina entradas de um archetype com um arquivo CODEOWNERS existente,
 * preservando entradas existentes e adicionando apenas path patterns novos.
 */

/**
 * Representa uma entrada parseada de um arquivo CODEOWNERS.
 */
interface CodeownersEntry {
  /** Path pattern (primeiro token não-comentário da linha) */
  pathPattern: string;
  /** Linha completa original */
  rawLine: string;
}

/**
 * Faz merge de dois arquivos CODEOWNERS, preservando todas as entradas existentes
 * e adicionando entradas do archetype cujos path patterns não existam no arquivo atual.
 *
 * Regras de merge:
 * 1. Todas as linhas do existingContent são preservadas (comentários, linhas vazias, entradas)
 * 2. Entradas do archetypeContent com path patterns novos são adicionadas ao final
 * 3. Entradas com path patterns já presentes no existingContent NÃO são duplicadas
 * 4. Os owners do existingContent são preservados (nunca sobrescritos)
 *
 * @param archetypeContent - Conteúdo bruto do CODEOWNERS do archetype (fonte)
 * @param existingContent - Conteúdo bruto do CODEOWNERS existente no projeto destino
 * @returns Conteúdo mergeado do CODEOWNERS
 */
export function mergeCODEOWNERS(archetypeContent: string, existingContent: string): string {
  const existingPatterns = extractPathPatterns(existingContent);
  const archetypeEntries = parseEntries(archetypeContent);

  // Identificar entradas do archetype com path patterns novos
  const newEntries = archetypeEntries.filter(
    (entry) => !existingPatterns.has(entry.pathPattern)
  );

  if (newEntries.length === 0) {
    return existingContent;
  }

  // Garantir que o conteúdo existente termina com newline antes de adicionar
  const base = existingContent.endsWith("\n") ? existingContent : existingContent + "\n";

  const newLines = newEntries.map((entry) => entry.rawLine).join("\n");

  return base + newLines + "\n";
}

/**
 * Extrai todos os path patterns presentes no conteúdo de um CODEOWNERS.
 * Ignora linhas de comentário e linhas vazias.
 */
function extractPathPatterns(content: string): Set<string> {
  const patterns = new Set<string>();
  const lines = content.split("\n");

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) {
      continue;
    }
    const pathPattern = extractPathPattern(trimmed);
    if (pathPattern) {
      patterns.add(pathPattern);
    }
  }

  return patterns;
}

/**
 * Parseia o conteúdo de um CODEOWNERS e retorna apenas as entradas válidas
 * (linhas com path pattern + owners, ignorando comentários e linhas vazias).
 */
function parseEntries(content: string): CodeownersEntry[] {
  const entries: CodeownersEntry[] = [];
  const lines = content.split("\n");

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) {
      continue;
    }
    const pathPattern = extractPathPattern(trimmed);
    if (pathPattern) {
      entries.push({ pathPattern, rawLine: line });
    }
  }

  return entries;
}

/**
 * Extrai o path pattern (primeiro token) de uma linha de CODEOWNERS.
 * Retorna null se a linha não contiver um token válido.
 */
function extractPathPattern(line: string): string | null {
  const tokens = line.split(/\s+/);
  return tokens.length > 0 ? tokens[0] : null;
}
