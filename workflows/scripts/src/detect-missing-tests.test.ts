import { describe, it, expect } from "vitest";
import { detectMissingTests } from "./detect-missing-tests.js";

describe("detectMissingTests - bff-fastify", () => {
  const archetype = "bff-fastify";

  describe("detecção em routes/", () => {
    it("deve reportar violação para arquivo de rota sem teste correspondente", () => {
      // Arrange
      const changedFiles = ["src/modules/users/routes/user.routes.ts"];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].rule_id).toBe("missing_tests");
      expect(violations[0].severity).toBe("error");
      expect(violations[0].file).toBe("src/modules/users/routes/user.routes.ts");
    });

    it("não deve reportar violação se existe .spec.ts correspondente em changedFiles", () => {
      // Arrange
      const changedFiles = [
        "src/modules/users/routes/user.routes.ts",
        "src/modules/users/routes/user.routes.spec.ts",
      ];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violação se existe .test.ts correspondente em changedFiles", () => {
      // Arrange
      const changedFiles = [
        "src/modules/users/routes/user.routes.ts",
        "src/modules/users/routes/user.routes.test.ts",
      ];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violação se existe teste em allFilesInPR", () => {
      // Arrange
      const changedFiles = ["src/modules/users/routes/user.routes.ts"];
      const allFilesInPR = ["src/modules/users/routes/user.routes.spec.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve detectar múltiplas rotas sem testes", () => {
      // Arrange
      const changedFiles = [
        "src/modules/users/routes/user.routes.ts",
        "src/modules/auth/routes/login.routes.ts",
      ];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(2);
      expect(violations[0].file).toBe("src/modules/users/routes/user.routes.ts");
      expect(violations[1].file).toBe("src/modules/auth/routes/login.routes.ts");
    });

    it("deve funcionar com rotas em subpastas profundas", () => {
      // Arrange
      const changedFiles = [
        "src/modules/admin/settings/routes/config.routes.ts",
      ];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].file).toBe("src/modules/admin/settings/routes/config.routes.ts");
    });
  });

  describe("detecção em services/", () => {
    it("deve reportar violação para arquivo de serviço sem teste correspondente", () => {
      // Arrange
      const changedFiles = ["src/modules/users/services/user.service.ts"];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].rule_id).toBe("missing_tests");
      expect(violations[0].severity).toBe("error");
      expect(violations[0].file).toBe("src/modules/users/services/user.service.ts");
    });

    it("não deve reportar violação se existe .spec.ts correspondente", () => {
      // Arrange
      const changedFiles = ["src/modules/users/services/user.service.ts"];
      const allFilesInPR = ["src/modules/users/services/user.service.spec.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violação se existe .test.ts correspondente", () => {
      // Arrange
      const changedFiles = ["src/modules/users/services/user.service.ts"];
      const allFilesInPR = ["src/modules/users/services/user.service.test.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("exclusões", () => {
    it("não deve reportar para arquivos já com sufixo .spec.ts", () => {
      // Arrange
      const changedFiles = ["src/modules/users/routes/user.routes.spec.ts"];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar para arquivos já com sufixo .test.ts", () => {
      // Arrange
      const changedFiles = ["src/modules/users/routes/user.routes.test.ts"];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar para arquivos em __tests__/", () => {
      // Arrange
      const changedFiles = ["src/modules/users/routes/__tests__/user.routes.ts"];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar para arquivos fora de routes/ e services/", () => {
      // Arrange
      const changedFiles = [
        "src/modules/users/schemas/user.schema.ts",
        "src/modules/users/types/user.types.ts",
        "src/config/app.ts",
        "src/plugins/auth.ts",
      ];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar para arquivos que não terminam em .ts", () => {
      // Arrange
      const changedFiles = [
        "src/modules/users/routes/README.md",
        "src/modules/users/services/data.json",
      ];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("cenários combinados", () => {
    it("deve reportar apenas para arquivos sem teste quando há mix de routes e services", () => {
      // Arrange
      const changedFiles = [
        "src/modules/users/routes/user.routes.ts",
        "src/modules/users/services/user.service.ts",
        "src/modules/auth/routes/login.routes.ts",
      ];
      const allFilesInPR = [
        "src/modules/users/routes/user.routes.spec.ts",
        "src/modules/auth/routes/login.routes.test.ts",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].file).toBe("src/modules/users/services/user.service.ts");
    });

    it("deve incluir mensagem com os nomes dos testes esperados", () => {
      // Arrange
      const changedFiles = ["src/modules/users/routes/user.routes.ts"];
      const allFilesInPR: string[] = [];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations[0].message).toContain("user.routes.spec.ts");
      expect(violations[0].message).toContain("user.routes.test.ts");
    });
  });
});

describe("detectMissingTests - frontend-react", () => {
  const archetype = "frontend-react";

  describe("componentes (src/**/components/**/*.tsx)", () => {
    it("deve reportar violation quando componente não tem teste", () => {
      // Arrange
      const changedFiles = ["src/features/auth/components/LoginForm.tsx"];
      const allFilesInPR = ["src/features/auth/components/LoginForm.tsx"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].rule_id).toBe("missing_tests");
      expect(violations[0].severity).toBe("error");
      expect(violations[0].file).toBe("src/features/auth/components/LoginForm.tsx");
    });

    it("não deve reportar violation quando componente tem .test.tsx correspondente", () => {
      // Arrange
      const changedFiles = ["src/features/auth/components/LoginForm.tsx"];
      const allFilesInPR = [
        "src/features/auth/components/LoginForm.tsx",
        "src/features/auth/components/LoginForm.test.tsx",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation quando componente tem .spec.tsx correspondente", () => {
      // Arrange
      const changedFiles = ["src/features/dashboard/components/Chart.tsx"];
      const allFilesInPR = [
        "src/features/dashboard/components/Chart.tsx",
        "src/features/dashboard/components/Chart.spec.tsx",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation quando componente tem .test.ts correspondente", () => {
      // Arrange
      const changedFiles = ["src/features/dashboard/components/Chart.tsx"];
      const allFilesInPR = [
        "src/features/dashboard/components/Chart.tsx",
        "src/features/dashboard/components/Chart.test.ts",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation para arquivos .test.tsx", () => {
      // Arrange
      const changedFiles = ["src/features/auth/components/LoginForm.test.tsx"];
      const allFilesInPR = ["src/features/auth/components/LoginForm.test.tsx"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation para arquivos .stories.tsx", () => {
      // Arrange
      const changedFiles = ["src/features/auth/components/LoginForm.stories.tsx"];
      const allFilesInPR = ["src/features/auth/components/LoginForm.stories.tsx"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation para index.tsx em components", () => {
      // Arrange
      const changedFiles = ["src/features/auth/components/index.tsx"];
      const allFilesInPR = ["src/features/auth/components/index.tsx"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("hooks (src/**/hooks/**/*.ts ou arquivos com use*)", () => {
    it("deve reportar violation quando hook não tem teste", () => {
      // Arrange
      const changedFiles = ["src/features/auth/hooks/useAuth.ts"];
      const allFilesInPR = ["src/features/auth/hooks/useAuth.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].rule_id).toBe("missing_tests");
      expect(violations[0].file).toBe("src/features/auth/hooks/useAuth.ts");
    });

    it("não deve reportar violation quando hook tem .test.ts correspondente", () => {
      // Arrange
      const changedFiles = ["src/features/auth/hooks/useAuth.ts"];
      const allFilesInPR = [
        "src/features/auth/hooks/useAuth.ts",
        "src/features/auth/hooks/useAuth.test.ts",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve detectar hook pelo prefixo 'use' mesmo fora de diretório hooks/", () => {
      // Arrange
      const changedFiles = ["src/shared/useDebounce.ts"];
      const allFilesInPR = ["src/shared/useDebounce.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].file).toBe("src/shared/useDebounce.ts");
    });

    it("não deve reportar para hook com prefixo 'use' quando tem teste", () => {
      // Arrange
      const changedFiles = ["src/shared/useDebounce.ts"];
      const allFilesInPR = [
        "src/shared/useDebounce.ts",
        "src/shared/useDebounce.test.ts",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation para index.ts em hooks", () => {
      // Arrange
      const changedFiles = ["src/features/auth/hooks/index.ts"];
      const allFilesInPR = ["src/features/auth/hooks/index.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("utilitários (src/**/utils/**/*.ts)", () => {
    it("deve reportar violation quando utilitário não tem teste", () => {
      // Arrange
      const changedFiles = ["src/shared/utils/formatDate.ts"];
      const allFilesInPR = ["src/shared/utils/formatDate.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].rule_id).toBe("missing_tests");
      expect(violations[0].file).toBe("src/shared/utils/formatDate.ts");
    });

    it("não deve reportar violation quando utilitário tem .test.ts correspondente", () => {
      // Arrange
      const changedFiles = ["src/shared/utils/formatDate.ts"];
      const allFilesInPR = [
        "src/shared/utils/formatDate.ts",
        "src/shared/utils/formatDate.test.ts",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation para index.ts em utils", () => {
      // Arrange
      const changedFiles = ["src/shared/utils/index.ts"];
      const allFilesInPR = ["src/shared/utils/index.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violation para arquivos de teste em utils", () => {
      // Arrange
      const changedFiles = ["src/shared/utils/formatDate.test.ts"];
      const allFilesInPR = ["src/shared/utils/formatDate.test.ts"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("teste em __tests__/ adjacente", () => {
    it("deve aceitar teste em subdiretório __tests__/", () => {
      // Arrange
      const changedFiles = ["src/features/auth/components/LoginForm.tsx"];
      const allFilesInPR = [
        "src/features/auth/components/LoginForm.tsx",
        "src/features/auth/components/__tests__/LoginForm.test.tsx",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("múltiplos arquivos", () => {
    it("deve reportar violations para cada arquivo sem teste", () => {
      // Arrange
      const changedFiles = [
        "src/features/auth/components/LoginForm.tsx",
        "src/features/auth/hooks/useAuth.ts",
        "src/shared/utils/formatDate.ts",
      ];
      const allFilesInPR = [...changedFiles];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(3);
      expect(violations.every((v) => v.rule_id === "missing_tests")).toBe(true);
      expect(violations.every((v) => v.severity === "error")).toBe(true);
    });

    it("deve reportar apenas para arquivos sem teste quando mix existe", () => {
      // Arrange
      const changedFiles = [
        "src/features/auth/components/LoginForm.tsx",
        "src/features/auth/hooks/useAuth.ts",
      ];
      const allFilesInPR = [
        "src/features/auth/components/LoginForm.tsx",
        "src/features/auth/components/LoginForm.test.tsx",
        "src/features/auth/hooks/useAuth.ts",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].file).toBe("src/features/auth/hooks/useAuth.ts");
    });
  });

  describe("arquivos que não requerem teste", () => {
    it("não deve reportar para arquivos fora de components/hooks/utils", () => {
      // Arrange
      const changedFiles = [
        "src/features/auth/types.ts",
        "src/features/auth/constants.ts",
        "src/styles/theme.ts",
      ];
      const allFilesInPR = [...changedFiles];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar para arquivos não-TypeScript", () => {
      // Arrange
      const changedFiles = [
        "src/features/auth/components/LoginForm.css",
        "package.json",
        "README.md",
      ];
      const allFilesInPR = [...changedFiles];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });
});

describe("detectMissingTests - backend-csharp", () => {
  const archetype = "backend-csharp";

  describe("detecção de arquivos que requerem teste", () => {
    it("deve reportar violação para arquivo em Application/ sem teste correspondente", () => {
      // Arrange
      const changedFiles = ["src/Application/Services/UserService.cs"];
      const allFilesInPR = ["src/Application/Services/UserService.cs"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].rule_id).toBe("missing_tests");
      expect(violations[0].severity).toBe("error");
      expect(violations[0].file).toBe("src/Application/Services/UserService.cs");
      expect(violations[0].message).toContain("UserService.cs");
    });

    it("deve reportar violação para arquivo em Domain/ sem teste correspondente", () => {
      // Arrange
      const changedFiles = ["src/Domain/Entities/Order.cs"];
      const allFilesInPR = ["src/Domain/Entities/Order.cs"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].rule_id).toBe("missing_tests");
      expect(violations[0].file).toBe("src/Domain/Entities/Order.cs");
    });

    it("deve reportar múltiplas violações para múltiplos arquivos sem teste", () => {
      // Arrange
      const changedFiles = [
        "src/Application/Services/UserService.cs",
        "src/Domain/Entities/Order.cs",
        "src/Application/Commands/CreateUserCommand.cs",
      ];
      const allFilesInPR = [...changedFiles];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(3);
      expect(violations.every((v) => v.rule_id === "missing_tests")).toBe(true);
      expect(violations.every((v) => v.severity === "error")).toBe(true);
    });
  });

  describe("arquivos com teste correspondente", () => {
    it("não deve reportar violação quando existe arquivo Tests.cs correspondente", () => {
      // Arrange
      const changedFiles = ["src/Application/Services/UserService.cs"];
      const allFilesInPR = [
        "src/Application/Services/UserService.cs",
        "tests/Application/Services/UserServiceTests.cs",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("não deve reportar violação quando existe arquivo Test.cs correspondente", () => {
      // Arrange
      const changedFiles = ["src/Domain/Entities/Order.cs"];
      const allFilesInPR = [
        "src/Domain/Entities/Order.cs",
        "tests/Domain/Entities/OrderTest.cs",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve aceitar testes em qualquer localização (diretório Tests/)", () => {
      // Arrange
      const changedFiles = ["src/Application/Services/PaymentService.cs"];
      const allFilesInPR = [
        "src/Application/Services/PaymentService.cs",
        "Tests/Unit/PaymentServiceTests.cs",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve aceitar testes em diretório diferente da fonte", () => {
      // Arrange
      const changedFiles = ["src/Application/Handlers/CreateOrderHandler.cs"];
      const allFilesInPR = [
        "src/Application/Handlers/CreateOrderHandler.cs",
        "project.Tests/Handlers/CreateOrderHandlerTests.cs",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("arquivos que não requerem teste", () => {
    it("deve ignorar arquivos que já são testes (sufixo Tests.cs)", () => {
      // Arrange
      const changedFiles = ["tests/Application/Services/UserServiceTests.cs"];
      const allFilesInPR = ["tests/Application/Services/UserServiceTests.cs"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve ignorar arquivos que já são testes (sufixo Test.cs)", () => {
      // Arrange
      const changedFiles = ["tests/Domain/Entities/OrderTest.cs"];
      const allFilesInPR = ["tests/Domain/Entities/OrderTest.cs"];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve ignorar arquivos fora de Application/ e Domain/", () => {
      // Arrange
      const changedFiles = [
        "src/Infrastructure/Repositories/UserRepository.cs",
        "src/Api/Controllers/UserController.cs",
        "src/Presentation/Views/HomePage.cs",
      ];
      const allFilesInPR = [...changedFiles];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve ignorar arquivos não .cs", () => {
      // Arrange
      const changedFiles = [
        "src/Application/Services/readme.md",
        "src/Domain/appsettings.json",
      ];
      const allFilesInPR = [...changedFiles];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });
  });

  describe("cenários de borda", () => {
    it("deve lidar com listas vazias de arquivos", () => {
      // Arrange & Act
      const violations = detectMissingTests([], [], archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve lidar com caminhos usando backslash (Windows)", () => {
      // Arrange
      const changedFiles = ["src\\Application\\Services\\UserService.cs"];
      const allFilesInPR = [
        "src\\Application\\Services\\UserService.cs",
        "tests\\Application\\Services\\UserServiceTests.cs",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(0);
    });

    it("deve considerar apenas o nome do arquivo para matching de teste", () => {
      // Arrange - mesmo nome de classe em diretórios diferentes
      const changedFiles = [
        "src/Application/Services/UserService.cs",
        "src/Domain/Services/UserService.cs",
      ];
      // Apenas um teste existe
      const allFilesInPR = [
        ...changedFiles,
        "tests/UserServiceTests.cs",
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      // Ambos devem ser satisfeitos pelo mesmo teste (match por nome)
      expect(violations).toHaveLength(0);
    });

    it("deve reportar quando arquivo de teste tem nome parcialmente similar mas não exato", () => {
      // Arrange
      const changedFiles = ["src/Application/Services/User.cs"];
      const allFilesInPR = [
        "src/Application/Services/User.cs",
        "tests/UserServiceTests.cs", // UserServiceTests != UserTests
      ];

      // Act
      const violations = detectMissingTests(changedFiles, allFilesInPR, archetype);

      // Assert
      expect(violations).toHaveLength(1);
      expect(violations[0].file).toBe("src/Application/Services/User.cs");
    });
  });
});

describe("detectMissingTests - archetype desconhecido", () => {
  it("deve retornar array vazio para archetype não suportado", () => {
    // Arrange
    const changedFiles = ["src/main.ts"];
    const allFilesInPR = ["src/main.ts"];

    // Act
    const violations = detectMissingTests(changedFiles, allFilesInPR, "unknown-archetype");

    // Assert
    expect(violations).toHaveLength(0);
  });
});
