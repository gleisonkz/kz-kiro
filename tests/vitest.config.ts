import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Mínimo 100 iterações para testes de propriedade (fast-check)
    fuzz: {
      numRuns: 100,
    },
    // Configuração global para incluir arquivos .test.ts e .spec.ts
    include: ["**/*.{test,spec}.ts"],
    // Timeout generoso para property tests com muitas iterações
    testTimeout: 30000,
  },
});
