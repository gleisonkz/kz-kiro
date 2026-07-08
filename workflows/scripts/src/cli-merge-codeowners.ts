#!/usr/bin/env tsx
/**
 * CLI entry point para merge de CODEOWNERS.
 * Usado pelo bootstrap-workflows.sh para merge de CODEOWNERS.
 *
 * Uso: tsx cli-merge-codeowners.ts <archetype-codeowners-path> <existing-codeowners-path>
 */
import { readFileSync, writeFileSync } from "fs";
import { mergeCODEOWNERS } from "./merge-codeowners.js";

const archetypePath = process.argv[2];
const existingPath = process.argv[3];

if (!archetypePath || !existingPath) {
  console.error("Uso: tsx cli-merge-codeowners.ts <archetype-codeowners> <existing-codeowners>");
  process.exit(1);
}

const archetypeContent = readFileSync(archetypePath, "utf-8");
const existingContent = readFileSync(existingPath, "utf-8");

const merged = mergeCODEOWNERS(archetypeContent, existingContent);
writeFileSync(existingPath, merged, "utf-8");
