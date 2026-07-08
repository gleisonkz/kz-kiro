import type { Violation } from "./types.js";

/**
 * Verifica se um arquivo TypeScript é um arquivo de teste.
 */
function isTsTestFile(filePath: string): boolean {
  return (
    filePath.endsWith(".spec.ts") ||
    filePath.endsWith(".test.ts") ||
    filePath.includes("__tests__/")
  );
}

/**
 * Gera nomes esperados de arquivos de teste para BFF Fastify.
 * Ex: "user.routes.ts" → ["user.routes.spec.ts", "user.routes.test.ts"]
 */
function getExpectedBffTestFiles(filePath: string): string[] {
  const baseName = filePath.replace(/\.ts$/, "");
  return [`${baseName}.spec.ts`, `${baseName}.test.ts`];
}

/**
 * Verifica se um arquivo BFF Fastify requer teste.
 * Arquivos em src/modules/(qualquer)/routes/ ou src/modules/(qualquer)/services/ requerem testes.
 */
function bffFileRequiresTest(filePath: string): boolean {
  const routesPattern = /src\/modules\/.+\/routes\/[^/]+\.ts$/;
  const servicesPattern = /src\/modules\/.+\/services\/[^/]+\.ts$/;

  return routesPattern.test(filePath) || servicesPattern.test(filePath);
}

/**
 * Verifica se um arquivo C# está em camada Application ou Domain
 * e requer teste unitário correspondente.
 */
function csharpFileRequiresTest(filePath: string): boolean {
  const normalizedPath = filePath.replace(/\\/g, "/");

  // Deve ser arquivo .cs
  if (!normalizedPath.endsWith(".cs")) {
    return false;
  }

  // Não deve ser um arquivo de teste
  if (normalizedPath.endsWith("Tests.cs") || normalizedPath.endsWith("Test.cs")) {
    return false;
  }

  // Deve estar em camada Application/ ou Domain/
  return normalizedPath.includes("/Application/") || normalizedPath.includes("/Domain/");
}

/**
 * Extrai o nome base de um arquivo C# (sem extensão e sem caminho).
 * Ex: "src/Application/Services/UserService.cs" → "UserService"
 */
function getCsharpBaseFileName(filePath: string): string {
  const normalizedPath = filePath.replace(/\\/g, "/");
  const parts = normalizedPath.split("/");
  const fileName = parts[parts.length - 1];
  return fileName.replace(/\.cs$/, "");
}

/**
 * Verifica se existe um arquivo de teste C# correspondente no PR.
 * Aceita testes com nome `<BaseName>Tests.cs` ou `<BaseName>Test.cs`
 * em qualquer localização dentro do allFilesInPR.
 */
function hasCsharpCorrespondingTest(
  sourceFile: string,
  allFilesInPR: string[]
): boolean {
  const baseName = getCsharpBaseFileName(sourceFile);
  const expectedTestNames = [`${baseName}Tests.cs`, `${baseName}Test.cs`];

  return allFilesInPR.some((file) => {
    const normalizedFile = file.replace(/\\/g, "/");
    const parts = normalizedFile.split("/");
    const fileName = parts[parts.length - 1];
    return expectedTestNames.includes(fileName);
  });
}

/**
 * Detecta arquivos sem testes correspondentes em um PR com base no archetype.
 *
 * Para cada archetype, verifica caminhos específicos que requerem teste:
 * - backend-csharp: Application/ e Domain/ (.cs exceto Tests.cs e Test.cs)
 * - bff-fastify: src/modules/.../routes/ e src/modules/.../services/
 * - frontend-react: src/.../components/, src/.../hooks/, src/.../utils/
 *
 * @param changedFiles - Arquivos modificados/adicionados no PR
 * @param allFilesInPR - Todos os arquivos presentes no PR (incluindo já existentes)
 * @param archetype - Identificador do archetype ("backend-csharp", "bff-fastify", "frontend-react")
 * @returns Lista de violações para arquivos sem teste correspondente
 */
export function detectMissingTests(
  changedFiles: string[],
  allFilesInPR: string[],
  archetype: string
): Violation[] {
  switch (archetype) {
    case "backend-csharp":
      return detectMissingTestsCsharp(changedFiles, allFilesInPR);
    case "bff-fastify":
      return detectMissingTestsBff(changedFiles, allFilesInPR);
    case "frontend-react":
      return detectMissingTestsReact(changedFiles, allFilesInPR);
    default:
      return [];
  }
}

/**
 * Detecção de testes faltantes para backend-csharp.
 * Verifica arquivos em Application/ ou Domain/ sem teste correspondente.
 */
function detectMissingTestsCsharp(
  changedFiles: string[],
  allFilesInPR: string[]
): Violation[] {
  const violations: Violation[] = [];

  for (const file of changedFiles) {
    if (!csharpFileRequiresTest(file)) {
      continue;
    }

    if (!hasCsharpCorrespondingTest(file, allFilesInPR)) {
      const baseName = getCsharpBaseFileName(file);
      violations.push({
        rule_id: "missing_tests",
        severity: "error",
        file,
        message: `Arquivo '${baseName}.cs' em camada Application/Domain requer teste unitário correspondente (${baseName}Tests.cs ou ${baseName}Test.cs)`,
      });
    }
  }

  return violations;
}

/**
 * Detecção de testes faltantes para bff-fastify.
 * Verifica arquivos em routes/ ou services/ sem .spec.ts ou .test.ts correspondente.
 */
function detectMissingTestsBff(
  changedFiles: string[],
  allFilesInPR: string[]
): Violation[] {
  const violations: Violation[] = [];
  const allFilesSet = new Set([...changedFiles, ...allFilesInPR]);

  for (const file of changedFiles) {
    if (isTsTestFile(file)) {
      continue;
    }

    if (!bffFileRequiresTest(file)) {
      continue;
    }

    const expectedTests = getExpectedBffTestFiles(file);
    const hasTest = expectedTests.some((testFile) => allFilesSet.has(testFile));

    if (!hasTest) {
      violations.push({
        rule_id: "missing_tests",
        severity: "error",
        file,
        message: `Arquivo '${file}' não possui teste correspondente (esperado: ${expectedTests.join(" ou ")})`,
      });
    }
  }

  return violations;
}

/**
 * Verifica se um arquivo é de teste ou stories no frontend React.
 */
function isReactTestOrStoriesFile(filePath: string): boolean {
  return (
    filePath.endsWith(".test.ts") ||
    filePath.endsWith(".test.tsx") ||
    filePath.endsWith(".spec.ts") ||
    filePath.endsWith(".spec.tsx") ||
    filePath.endsWith(".stories.ts") ||
    filePath.endsWith(".stories.tsx")
  );
}

/**
 * Verifica se um arquivo é um index que apenas re-exporta (não requer teste).
 */
function isReexportIndex(fileName: string): boolean {
  return fileName === "index.ts" || fileName === "index.tsx";
}

/**
 * Verifica se um arquivo React requer teste.
 * Componentes (.tsx em components/), hooks (.ts em hooks/ ou com prefixo use),
 * e utilitários (.ts em utils/) requerem testes.
 */
function reactFileRequiresTest(filePath: string): boolean {
  // Deve ser .ts ou .tsx
  if (!filePath.endsWith(".ts") && !filePath.endsWith(".tsx")) {
    return false;
  }

  // Não é arquivo de teste ou stories
  if (isReactTestOrStoriesFile(filePath)) {
    return false;
  }

  // Index files que apenas re-exportam não precisam de testes
  const parts = filePath.split("/");
  const fileName = parts[parts.length - 1];
  if (isReexportIndex(fileName)) {
    return false;
  }

  // Componentes: src/**/components/**/*.tsx
  const isComponent = /src\/.*\/components\//.test(filePath) && filePath.endsWith(".tsx");

  // Hooks: src/**/hooks/**/*.ts(x) ou arquivo com prefixo "use" seguido de maiúscula
  const isHook = /src\/.*\/hooks\//.test(filePath) || /\/use[A-Z]/.test(filePath);

  // Utilitários: src/**/utils/**/*.ts(x)
  const isUtil = /src\/.*\/utils\//.test(filePath);

  return isComponent || isHook || isUtil;
}

/**
 * Verifica se existe um teste correspondente para um arquivo React.
 * Aceita testes com sufixo .test.tsx, .test.ts, .spec.tsx ou .spec.ts
 * no mesmo diretório ou em __tests__/ adjacente.
 */
function hasReactCorrespondingTest(
  sourceFile: string,
  allFilesInPR: string[]
): boolean {
  const parts = sourceFile.split("/");
  const fileName = parts[parts.length - 1];
  const dir = parts.slice(0, -1).join("/");

  // Extrai o nome base sem extensão
  const baseName = fileName.replace(/\.(tsx?|ts)$/, "");

  const expectedTestNames = [
    `${baseName}.test.tsx`,
    `${baseName}.test.ts`,
    `${baseName}.spec.tsx`,
    `${baseName}.spec.ts`,
  ];

  return allFilesInPR.some((file) => {
    const fileParts = file.split("/");
    const testFileName = fileParts[fileParts.length - 1];
    const testDir = fileParts.slice(0, -1).join("/");

    if (!expectedTestNames.includes(testFileName)) {
      return false;
    }

    // Aceita teste no mesmo diretório ou em __tests__/ adjacente
    return testDir === dir || testDir === `${dir}/__tests__`;
  });
}

/**
 * Detecção de testes faltantes para frontend-react.
 * Verifica componentes, hooks e funções utilitárias sem teste correspondente.
 */
function detectMissingTestsReact(
  changedFiles: string[],
  allFilesInPR: string[]
): Violation[] {
  const violations: Violation[] = [];
  const allFiles = [...new Set([...changedFiles, ...allFilesInPR])];

  for (const file of changedFiles) {
    if (!reactFileRequiresTest(file)) {
      continue;
    }

    if (!hasReactCorrespondingTest(file, allFiles)) {
      violations.push({
        rule_id: "missing_tests",
        severity: "error",
        file,
        message: `Componente/hook/utilitário sem teste correspondente: ${file}`,
      });
    }
  }

  return violations;
}
