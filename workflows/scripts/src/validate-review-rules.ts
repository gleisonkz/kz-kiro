import Ajv, { type ErrorObject } from "ajv";
import * as yaml from "js-yaml";
import type { ReviewRulesConfig } from "./types.js";

/**
 * Resultado da validação do arquivo review-rules.yml.
 */
export interface ValidationResult {
  /** Indica se a validação passou sem erros */
  valid: boolean;
  /** Configuração parseada (presente apenas quando valid=true) */
  config?: ReviewRulesConfig;
  /** Lista de erros encontrados durante a validação */
  errors: ValidationError[];
}

/**
 * Erro individual de validação com indicação de localização.
 */
export interface ValidationError {
  /** Caminho do campo que causou o erro (ex: "/rules/missing_tests/severity") */
  field: string;
  /** Mensagem descritiva do erro */
  message: string;
}

/**
 * JSON Schema para validação do review-rules.yml.
 * Mesmo conteúdo presente em cada archetype (review-rules.schema.json).
 */
const REVIEW_RULES_SCHEMA = {
  $schema: "http://json-schema.org/draft-07/schema#",
  title: "ReviewRulesConfig",
  type: "object",
  required: ["version", "archetype", "rules"],
  properties: {
    version: {
      type: "string",
      enum: ["1.0"],
    },
    archetype: {
      type: "string",
      enum: ["backend-csharp", "bff-fastify", "frontend-react", "mobile-flutter"],
    },
    agent_review: {
      type: "object",
      properties: {
        enabled: { type: "boolean" },
        agent: { type: "string" },
        timeout_seconds: { type: "integer", minimum: 30, maximum: 600 },
      },
      required: ["enabled"],
    },
    rules: {
      type: "object",
      minProperties: 1,
      additionalProperties: {
        type: "object",
        required: ["severity"],
        properties: {
          severity: {
            type: "string",
            enum: ["error", "warn", "disabled"],
          },
          description: { type: "string" },
        },
      },
    },
  },
} as const;

/**
 * Valida o conteúdo YAML de um arquivo review-rules.yml contra o JSON Schema
 * e verifica regras de negócio adicionais (ex: todas as regras disabled).
 *
 * @param yamlContent - Conteúdo bruto do arquivo review-rules.yml
 * @returns Resultado da validação com erros detalhados caso inválido
 */
export function validateReviewRules(yamlContent: string): ValidationResult {
  // 1. Tentar parsear o YAML
  let parsed: unknown;
  try {
    parsed = yaml.load(yamlContent);
  } catch (error) {
    const yamlError = error as yaml.YAMLException;
    const line = yamlError.mark?.line != null ? yamlError.mark.line + 1 : undefined;
    const lineInfo = line ? ` (linha ${line})` : "";
    return {
      valid: false,
      errors: [
        {
          field: "/",
          message: `YAML malformado${lineInfo}: ${yamlError.message}`,
        },
      ],
    };
  }

  // 2. Validar contra JSON Schema usando ajv
  const ajv = new Ajv({ allErrors: true });
  const validate = ajv.compile(REVIEW_RULES_SCHEMA);
  const isValid = validate(parsed);

  if (!isValid) {
    const errors = (validate.errors ?? []).map(mapAjvError);
    return {
      valid: false,
      errors,
    };
  }

  // 3. Verificar regra de negócio: todas as regras disabled
  const config = parsed as ReviewRulesConfig;
  const allDisabled = Object.values(config.rules).every(
    (rule) => rule.severity === "disabled"
  );

  if (allDisabled) {
    return {
      valid: false,
      config,
      errors: [
        {
          field: "/rules",
          message:
            "Erro de configuração: todas as regras estão desabilitadas. Pelo menos uma regra deve ter severidade 'error' ou 'warn'.",
        },
      ],
    };
  }

  return {
    valid: true,
    config,
    errors: [],
  };
}

/**
 * Converte um erro do ajv para o formato ValidationError com campo e mensagem legíveis.
 */
function mapAjvError(error: ErrorObject): ValidationError {
  const field = error.instancePath || "/";
  let message: string;

  switch (error.keyword) {
    case "required":
      message = `Campo obrigatório ausente: '${error.params.missingProperty}'`;
      break;
    case "enum":
      message = `Valor inválido. Valores permitidos: ${JSON.stringify(error.params.allowedValues)}`;
      break;
    case "type":
      message = `Tipo inválido: esperado '${error.params.type}'`;
      break;
    case "minProperties":
      message = `Deve conter ao menos ${error.params.limit} propriedade(s)`;
      break;
    case "minimum":
      message = `Valor deve ser >= ${error.params.limit}`;
      break;
    case "maximum":
      message = `Valor deve ser <= ${error.params.limit}`;
      break;
    default:
      message = error.message ?? "Erro de validação desconhecido";
  }

  return { field, message };
}
