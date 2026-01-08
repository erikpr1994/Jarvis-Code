// @ts-check
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import eslintPluginImport from 'eslint-plugin-import';

/**
 * Jarvis ESLint Configuration
 * 
 * Enforces code quality rules that were previously "soft rules" in prompts.
 * These rules make violations impossible, saving context tokens.
 * 
 * Install dependencies:
 *   npm install -D eslint typescript-eslint @eslint/js eslint-plugin-import
 */
export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    files: ['**/*.{ts,tsx}'],
    rules: {
      // ═══════════════════════════════════════════════════════════════════════
      // TYPE SAFETY - "No any types in production code"
      // ═══════════════════════════════════════════════════════════════════════
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unsafe-assignment': 'error',
      '@typescript-eslint/no-unsafe-call': 'error',
      '@typescript-eslint/no-unsafe-member-access': 'error',
      '@typescript-eslint/no-unsafe-return': 'error',
      '@typescript-eslint/no-unsafe-argument': 'error',

      // ═══════════════════════════════════════════════════════════════════════
      // TS-IGNORE - "No @ts-ignore without documented justification"
      // ═══════════════════════════════════════════════════════════════════════
      '@typescript-eslint/ban-ts-comment': ['error', {
        'ts-expect-error': 'allow-with-description',
        'ts-ignore': 'allow-with-description',
        'ts-nocheck': 'allow-with-description',
        'minimumDescriptionLength': 10,
      }],

      // ═══════════════════════════════════════════════════════════════════════
      // COMPLEXITY - "Cyclomatic complexity: <10"
      // ═══════════════════════════════════════════════════════════════════════
      'complexity': ['error', 10],

      // ═══════════════════════════════════════════════════════════════════════
      // FUNCTION LENGTH - "Function length: <30 lines"
      // ═══════════════════════════════════════════════════════════════════════
      'max-lines-per-function': ['warn', {
        max: 30,
        skipBlankLines: true,
        skipComments: true,
      }],

      // ═══════════════════════════════════════════════════════════════════════
      // FILE LENGTH - "File length: <300 lines"
      // ═══════════════════════════════════════════════════════════════════════
      'max-lines': ['warn', {
        max: 300,
        skipBlankLines: true,
        skipComments: true,
      }],

      // ═══════════════════════════════════════════════════════════════════════
      // CODE STYLE - Anti-patterns to avoid
      // ═══════════════════════════════════════════════════════════════════════
      'no-nested-ternary': 'error',
      'no-magic-numbers': ['warn', {
        ignore: [0, 1, -1, 2, 100],
        ignoreArrayIndexes: true,
        ignoreDefaultValues: true,
        enforceConst: true,
      }],

      // ═══════════════════════════════════════════════════════════════════════
      // NAMING CONVENTIONS - "Components: PascalCase, Utils: camelCase"
      // ═══════════════════════════════════════════════════════════════════════
      '@typescript-eslint/naming-convention': [
        'error',
        // Variables - camelCase or UPPER_CASE for constants
        {
          selector: 'variable',
          format: ['camelCase', 'UPPER_CASE', 'PascalCase'],
        },
        // Functions - camelCase (PascalCase for React components)
        {
          selector: 'function',
          format: ['camelCase', 'PascalCase'],
        },
        // Types, Interfaces, Classes - PascalCase
        {
          selector: 'typeLike',
          format: ['PascalCase'],
        },
        // Enum members - UPPER_CASE
        {
          selector: 'enumMember',
          format: ['UPPER_CASE'],
        },
      ],

      // ═══════════════════════════════════════════════════════════════════════
      // ERROR HANDLING - Enforce proper error handling
      // ═══════════════════════════════════════════════════════════════════════
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      'no-throw-literal': 'off',
      '@typescript-eslint/only-throw-error': 'error',

      // ═══════════════════════════════════════════════════════════════════════
      // BEST PRACTICES
      // ═══════════════════════════════════════════════════════════════════════
      'eqeqeq': ['error', 'always'],
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'prefer-const': 'error',
      'no-var': 'error',
    },
  },
  {
    // Import ordering - "React > External > Internal > Relative"
    files: ['**/*.{ts,tsx,js,jsx}'],
    plugins: {
      import: eslintPluginImport,
    },
    rules: {
      'import/order': ['error', {
        groups: [
          'builtin',
          'external',
          'internal',
          ['parent', 'sibling'],
          'index',
          'type',
        ],
        pathGroups: [
          { pattern: 'react', group: 'external', position: 'before' },
          { pattern: 'next/**', group: 'external', position: 'before' },
          { pattern: '@/**', group: 'internal', position: 'before' },
        ],
        pathGroupsExcludedImportTypes: ['react'],
        'newlines-between': 'always',
        alphabetize: { order: 'asc', caseInsensitive: true },
      }],
    },
  },
  {
    // Ignore patterns
    ignores: [
      'node_modules/**',
      'dist/**',
      'build/**',
      '.next/**',
      'coverage/**',
      '*.config.{js,ts}',
    ],
  },
);
