/**
 * Jarvis Commitlint Configuration
 * 
 * Enforces conventional commit format: <type>(<scope>): <description>
 * 
 * Install dependencies:
 *   npm install -D @commitlint/{cli,config-conventional}
 * 
 * Setup husky (if not already):
 *   npm install -D husky
 *   npx husky init
 *   echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
 */

/** @type {import('@commitlint/types').UserConfig} */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Type must be one of these
    'type-enum': [2, 'always', [
      'feat',     // New feature
      'fix',      // Bug fix
      'docs',     // Documentation only
      'style',    // Formatting, whitespace (no code change)
      'refactor', // Code change, no feature/fix
      'perf',     // Performance improvement
      'test',     // Adding/fixing tests
      'chore',    // Maintenance, dependencies
      'ci',       // CI/CD changes
      'build',    // Build system changes
      'revert',   // Revert previous commit
    ]],
    
    // Type is required and must be lowercase
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    
    // Scope is optional but must be lowercase if present
    'scope-case': [2, 'always', 'lower-case'],
    
    // Subject (description) rules
    'subject-case': [2, 'always', 'lower-case'],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'subject-max-length': [2, 'always', 72],
    
    // Header (type + scope + subject) max length
    'header-max-length': [2, 'always', 100],
    
    // Body rules
    'body-leading-blank': [2, 'always'],
    'body-max-line-length': [2, 'always', 100],
    
    // Footer rules
    'footer-leading-blank': [2, 'always'],
    'footer-max-line-length': [2, 'always', 100],
  },
  
  // Help text shown on error
  helpUrl: 'https://www.conventionalcommits.org/',
};
