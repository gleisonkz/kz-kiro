/**
 * Módulo de lógica de cópia com política de conflito.
 *
 * Determina quais arquivos devem ser copiados, pulados ou sobrescritos
 * com base na existência no destino e na flag `force`.
 * Esta é uma função pura (sem I/O de filesystem).
 */

/**
 * Representa um arquivo com seu caminho relativo e conteúdo.
 */
export interface FileEntry {
  /** Caminho relativo do arquivo */
  path: string;
  /** Conteúdo do arquivo */
  content: string;
}

/**
 * Resultado da operação de cópia com política de conflito.
 */
export interface CopyResult {
  /** Arquivos novos que serão copiados (não existiam no destino) */
  copied: FileEntry[];
  /** Arquivos existentes que foram pulados (sem --force) */
  skipped: FileEntry[];
  /** Arquivos existentes que foram sobrescritos (com --force) */
  overwritten: FileEntry[];
}

/**
 * Determina a ação de cópia para cada arquivo fonte com base na política de conflito.
 *
 * - Sem `force`: arquivos já existentes no destino são pulados, novos são copiados.
 * - Com `force`: todos os arquivos são copiados (existentes são sobrescritos).
 *
 * @param sourceFiles - Arquivos disponíveis na fonte (archetype)
 * @param destFiles - Arquivos já existentes no destino (projeto)
 * @param force - Se true, sobrescreve arquivos existentes
 * @returns Resultado categorizado em copied, skipped e overwritten
 */
export function copyWithConflictPolicy(
  sourceFiles: FileEntry[],
  destFiles: FileEntry[],
  force: boolean
): CopyResult {
  const destPaths = new Set(destFiles.map((f) => f.path));

  const copied: FileEntry[] = [];
  const skipped: FileEntry[] = [];
  const overwritten: FileEntry[] = [];

  for (const sourceFile of sourceFiles) {
    const existsInDest = destPaths.has(sourceFile.path);

    if (!existsInDest) {
      copied.push({ path: sourceFile.path, content: sourceFile.content });
    } else if (force) {
      overwritten.push({ path: sourceFile.path, content: sourceFile.content });
    } else {
      skipped.push({ path: sourceFile.path, content: sourceFile.content });
    }
  }

  return { copied, skipped, overwritten };
}
