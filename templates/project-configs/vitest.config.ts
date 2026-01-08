import { defineConfig } from 'vitest/config';

/**
 * Jarvis Vitest Configuration
 * 
 * Enforces test coverage thresholds that were previously "soft rules" in prompts.
 * 
 * Install dependencies:
 *   npm install -D vitest @vitest/coverage-v8
 */
export default defineConfig({
  test: {
    // ═══════════════════════════════════════════════════════════════════════════
    // GLOBALS - Enable describe, it, expect without imports
    // ═══════════════════════════════════════════════════════════════════════════
    globals: true,

    // ═══════════════════════════════════════════════════════════════════════════
    // ENVIRONMENT
    // ═══════════════════════════════════════════════════════════════════════════
    environment: 'node', // or 'jsdom' for browser/React

    // ═══════════════════════════════════════════════════════════════════════════
    // COVERAGE - "Test coverage: >80%"
    // ═══════════════════════════════════════════════════════════════════════════
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.config.{js,ts}',
        '**/*.d.ts',
        '**/types/**',
        '**/test/**',
        '**/__tests__/**',
        '**/__mocks__/**',
      ],
      // Enforce minimum thresholds - builds will fail if not met
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },

    // ═══════════════════════════════════════════════════════════════════════════
    // REPORTERS
    // ═══════════════════════════════════════════════════════════════════════════
    reporters: ['default'],

    // ═══════════════════════════════════════════════════════════════════════════
    // INCLUDE/EXCLUDE PATTERNS
    // ═══════════════════════════════════════════════════════════════════════════
    include: ['src/**/*.{test,spec}.{js,ts,jsx,tsx}'],
    exclude: ['node_modules', 'dist', 'build'],

    // ═══════════════════════════════════════════════════════════════════════════
    // WATCH MODE
    // ═══════════════════════════════════════════════════════════════════════════
    watch: false,

    // ═══════════════════════════════════════════════════════════════════════════
    // TIMEOUTS
    // ═══════════════════════════════════════════════════════════════════════════
    testTimeout: 10000,
    hookTimeout: 10000,
  },
});
