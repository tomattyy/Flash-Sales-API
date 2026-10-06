// @ts-check
import js from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig({
  // Aplica a configuração apenas a arquivos JavaScript e TypeScript
  files: ['**/*.{js,ts}'],

  // Ignora explicitamente pastas que não devem ser analisadas
  ignores: ['dist/**', 'node_modules/**'],

  // Configurações recomendadas do ESLint e do typescript-eslint
  extends: [
    js.configs.recommended,
    tseslint.configs.recommended,
    tseslint.configs.stylistic,
  ],
});