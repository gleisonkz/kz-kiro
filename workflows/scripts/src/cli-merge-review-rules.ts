#!/usr/bin/env tsx
/**
 * CLI entry point para merge de review-rules.yml.
 * Usado pelo bootstrap-workflows.sh para merge de configurações.
 *
 * Uso: tsx cli-merge-review-rules.ts <archetype-rules-path> <existing-rules-path>
 */
import { readFileSync, writeFileSync } from "fs";
import * as yaml from "js-yaml";
import { mergeReviewRules } from "./merge-review-rules.js";
import type { ReviewRulesConfig } from "./types.js";

const archetypePath = process.argv[2];
const existingPath = process.argv[3];

if (!archetypePath || !existingPath) {
  console.error("Uso: tsx cli-merge-review-rules.ts <archetype-rules> <existing-rules>");
  process.exit(1);
}

const archetypeConfig = yaml.load(
  readFileSync(archetypePath, "utf-8")
) as ReviewRulesConfig;
const existingConfig = yaml.load(
  readFileSync(existingPath, "utf-8")
) as ReviewRulesConfig;

const merged = mergeReviewRules(archetypeConfig, existingConfig);
const output = yaml.dump(merged, { lineWidth: -1, quotingType: '"', forceQuotes: false });

writeFileSync(existingPath, output, "utf-8");
