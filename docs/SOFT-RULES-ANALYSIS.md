# Soft Rules Analysis: From Prompt to Enforcement

**Goal:** Remove text-based instructions from the agent's context window by replacing them with technical enforcement mechanisms.

> *"If something can be enforced by a tool, it shouldn't be in the prompt. This saves context, increases reliability, and turns 'please do X' into 'X is the only option.'"*

---

## Executive Summary

| Category | Soft Rules Found | Already Enforced | Can Be Enforced | Must Stay as Prompt |
|----------|------------------|------------------|-----------------|---------------------|
| **Git/VCS** | 12 | 6 | 4 | 2 |
| **Code Quality** | 18 | 2 | 14 | 2 |
| **Testing** | 11 | 1 | 8 | 2 |
| **Security** | 6 | 0 | 5 | 1 |
| **Process** | 8 | 2 | 4 | 2 |
| **TOTAL** | **55** | **11** | **35** | **9** |

**Potential context savings:** ~35 soft rules can be removed from prompts = **~8,000 tokens saved**

---

## Already Enforced (Remove from Prompts) ✅

These are already enforced by hooks/tools but still repeated in rules. **Remove the text.**

| Soft Rule | Current Location | Existing Enforcement |
|-----------|------------------|----------------------|
| "Don't use `git reset --hard`" | `global.md`, `git-workflow.md` | `git-safety-guard.sh` hook |
| "Don't use `git push --force`" | `global.md`, `git-workflow.md` | `git-safety-guard.sh` hook |
| "Don't use `rm -rf`" | `global.md` | `git-safety-guard.sh` hook |
| "Don't use `git checkout --`" | `git-workflow.md` | `git-safety-guard.sh` hook |
| "Don't use `git clean -f`" | `git-workflow.md` | `git-safety-guard.sh` hook |
| "Don't use `git branch -D`" | `git-workflow.md` | `git-safety-guard.sh` hook |
| "Use submit-pr skill for PRs" | `global/CLAUDE.md` | `block-direct-submit.sh` hook |
| "Don't modify main branch directly" | `git-workflow.md` | `require-isolation.sh` hook |
| "Follow skill recommendations" | `global/CLAUDE.md` | `skill-activation.sh` hook |
| "Capture learnings" | `global.md` | `learning-capture.sh` hook |
| "Use pre-commit verification" | `global.md` | `pre-commit.sh` hook |

**Action:** Delete these sections from rules files. They're already enforced.

---

## Can Be Enforced (Build These) 🔧

### Tier 1: High Impact, Easy to Implement

#### 1. Conventional Commits
**Soft Rule:** "Use conventional commit format: `<type>(<scope>): <description>`"
**Location:** `git-workflow.md`, `global.md`

**Enforcement:**
```bash
# Hook: pre-commit.sh enhancement
# Tool: commitlint + husky

# Implementation:
npm install -D @commitlint/{cli,config-conventional} husky

# .commitlintrc.js
module.exports = { extends: ['@commitlint/config-conventional'] };

# .husky/commit-msg
npx --no -- commitlint --edit "$1"
```

**Claude Code Hook:**
```bash
# Hook: conventional-commit.sh
# Event: PreToolUse (Bash with git commit)
# Block non-conventional commit messages
if echo "$COMMAND" | grep -qE 'git\s+commit'; then
    MSG=$(echo "$COMMAND" | grep -oP '(?<=-m\s+["\x27])[^"\x27]+')
    if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|chore|ci)(\([^)]+\))?: .+'; then
        block_command "Commit message must follow conventional format"
    fi
fi
```

---

#### 2. No `any` Types in TypeScript
**Soft Rule:** "NO `any` TYPES IN PRODUCTION CODE"
**Location:** `global.md`, `code-quality.md`

**Enforcement:**
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true
  }
}

// eslint.config.js
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unsafe-assignment": "error",
    "@typescript-eslint/no-unsafe-call": "error",
    "@typescript-eslint/no-unsafe-member-access": "error",
    "@typescript-eslint/no-unsafe-return": "error"
  }
}
```

**Claude Code Hook:**
```bash
# Hook: type-check.sh
# Event: PreToolUse (Bash with git commit)
# Block if TypeScript has any errors
if echo "$COMMAND" | grep -qE 'git\s+commit'; then
    if ! npx tsc --noEmit 2>/dev/null; then
        block_command "TypeScript errors found. Run 'npx tsc --noEmit' to see issues."
    fi
fi
```

---

#### 3. No `@ts-ignore` Without Justification
**Soft Rule:** "NO `@ts-ignore` WITHOUT DOCUMENTED JUSTIFICATION"
**Location:** `global.md`, `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "@typescript-eslint/ban-ts-comment": ["error", {
      "ts-ignore": "allow-with-description",
      "minimumDescriptionLength": 10
    }]
  }
}
```

**CLI Wrapper:**
```bash
# bin/check-ts-ignore.sh
grep -rn "@ts-ignore" --include="*.ts" --include="*.tsx" src/ | while read line; do
    if ! echo "$line" | grep -qE '@ts-ignore\s+.{10,}'; then
        echo "ERROR: @ts-ignore without justification: $line"
        exit 1
    fi
done
```

---

#### 4. Tests Must Pass Before Commit
**Soft Rule:** "TESTS MUST PASS BEFORE COMMIT"
**Location:** `global.md`, `testing.md`, `code-quality.md`

**Enforcement:**
```bash
# .husky/pre-commit
npm test
npm run type-check
npm run lint
```

**Claude Code Hook:**
```bash
# Hook: pre-commit.sh (enhance existing)
# Event: PreToolUse (Bash with git commit)
if echo "$COMMAND" | grep -qE 'git\s+commit'; then
    # Run tests
    if ! npm test 2>/dev/null; then
        block_command "Tests failing. Fix tests before committing."
    fi
    # Run type check
    if ! npx tsc --noEmit 2>/dev/null; then
        block_command "TypeScript errors. Fix before committing."
    fi
    # Run lint
    if ! npm run lint 2>/dev/null; then
        block_command "Linting errors. Fix before committing."
    fi
fi
```

---

#### 5. PR Size Limit (<300 lines)
**Soft Rule:** "Target: <300 lines changed, Maximum: 500 lines"
**Location:** `git-workflow.md`, `code-quality.md`

**Enforcement:**
```bash
# Hook: pr-size-check.sh
# Event: PreToolUse (Bash with gh pr create or gt submit)

LINES_CHANGED=$(git diff --stat origin/main...HEAD | tail -1 | grep -oE '[0-9]+' | head -1)

if [[ "$LINES_CHANGED" -gt 500 ]]; then
    block_command "PR too large ($LINES_CHANGED lines). Maximum is 500. Split into smaller PRs."
elif [[ "$LINES_CHANGED" -gt 300 ]]; then
    output_context "WARNING: PR is $LINES_CHANGED lines. Consider splitting (<300 is ideal)."
fi
```

---

### Tier 2: Medium Impact, Moderate Effort

#### 6. Function Length Limit (<30 lines)
**Soft Rule:** "Function length: <30 lines"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "max-lines-per-function": ["warn", { "max": 30, "skipBlankLines": true, "skipComments": true }]
  }
}
```

---

#### 7. File Length Limit (<300 lines)
**Soft Rule:** "File length: <300 lines"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "max-lines": ["warn", { "max": 300, "skipBlankLines": true, "skipComments": true }]
  }
}
```

---

#### 8. Cyclomatic Complexity (<10)
**Soft Rule:** "Cyclomatic complexity: <10"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "complexity": ["error", 10]
  }
}
```

---

#### 9. Input Validation at Boundaries
**Soft Rule:** "All user inputs must be validated at system boundaries"
**Location:** `global.md`, `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js - custom rule or plugin
// @typescript-eslint/no-unsafe-argument already helps

// Alternative: Zod or io-ts required at API boundaries
// Custom ESLint rule that requires validation schemas at route handlers
```

**Partial Hook:**
```bash
# Hook: api-validation-check.sh
# Check that API routes use validation
grep -rn "app\.\(get\|post\|put\|delete\|patch\)" --include="*.ts" src/api/ | while read line; do
    FILE=$(echo "$line" | cut -d: -f1)
    LINE_NUM=$(echo "$line" | cut -d: -f2)
    # Check if Zod schema is used within 10 lines
    if ! sed -n "$((LINE_NUM)),$(((LINE_NUM)+10))p" "$FILE" | grep -qE '(schema\.|z\.|validate|parse)'; then
        echo "WARNING: API endpoint without validation: $line"
    fi
done
```

---

#### 10. Parameterized Queries Only (No SQL Injection)
**Soft Rule:** "Use parameterized queries (never string concatenation for SQL)"
**Location:** `global.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "plugins": ["security"],
  "rules": {
    "security/detect-non-literal-fs-filename": "error",
    "security/detect-sql-injection": "error"  // Custom rule
  }
}
```

**Static Analysis:**
```bash
# Use semgrep for SQL injection detection
semgrep --config "p/sql-injection" src/
```

---

#### 11. Import Order
**Soft Rule:** "Import order: React > External > Internal > Relative"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "plugins": ["import"],
  "rules": {
    "import/order": ["error", {
      "groups": ["builtin", "external", "internal", "parent", "sibling", "index"],
      "pathGroups": [
        { "pattern": "react", "group": "external", "position": "before" },
        { "pattern": "@/**", "group": "internal" }
      ],
      "newlines-between": "always",
      "alphabetize": { "order": "asc" }
    }]
  }
}
```

---

#### 12. Naming Conventions
**Soft Rule:** "Components: PascalCase, Utilities: camelCase, Constants: SCREAMING_SNAKE"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "@typescript-eslint/naming-convention": [
      "error",
      { "selector": "variable", "modifiers": ["const"], "format": ["UPPER_CASE", "camelCase"] },
      { "selector": "function", "format": ["camelCase", "PascalCase"] },
      { "selector": "typeLike", "format": ["PascalCase"] },
      { "selector": "interface", "format": ["PascalCase"] },
      { "selector": "enum", "format": ["PascalCase"] },
      { "selector": "enumMember", "format": ["UPPER_CASE"] }
    ]
  }
}
```

---

#### 13. No Magic Numbers
**Soft Rule:** "No magic numbers (use named constants)"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "no-magic-numbers": ["warn", { 
      "ignore": [0, 1, -1, 2],
      "ignoreArrayIndexes": true,
      "ignoreDefaultValues": true
    }]
  }
}
```

---

#### 14. No Nested Ternaries
**Soft Rule:** "Avoid nested ternaries"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "no-nested-ternary": "error"
  }
}
```

---

#### 15. Use `unknown` Instead of `any`
**Soft Rule:** "Use `unknown` instead of `any` for truly unknown types"
**Location:** `global.md`, `code-quality.md`

**Enforcement:** Same as #2 (no-explicit-any covers this)

---

### Tier 3: Lower Impact or Complex Implementation

#### 16. Worktree Directory is Gitignored
**Soft Rule:** "Always verify worktree directory is gitignored"
**Location:** `git-workflow.md`

**Enforcement:**
```bash
# Hook: worktree-safety.sh
# Event: PreToolUse (Bash with git worktree add)

if echo "$COMMAND" | grep -qE 'git\s+worktree\s+add'; then
    WORKTREE_DIR=$(echo "$COMMAND" | grep -oE '\.(worktrees|worktree)/[^ ]+' | head -1 | cut -d/ -f1)
    if [[ -n "$WORKTREE_DIR" ]]; then
        if ! git check-ignore -q "$WORKTREE_DIR" 2>/dev/null; then
            # Auto-fix or block
            echo "$WORKTREE_DIR" >> .gitignore
            git add .gitignore
            output_context "Added $WORKTREE_DIR to .gitignore"
        fi
    fi
fi
```

---

#### 17. JSDoc for Public Functions
**Soft Rule:** "JSDoc comments for public functions"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// eslint.config.js
{
  "rules": {
    "jsdoc/require-jsdoc": ["warn", {
      "publicOnly": true,
      "require": { "FunctionDeclaration": true, "MethodDefinition": true }
    }]
  }
}
```

---

#### 18. Error Handling for External Calls
**Soft Rule:** "All external calls must have error handling"
**Location:** `global.md`, `code-quality.md`

**Enforcement:**
```javascript
// Custom ESLint rule or semgrep
// Detect fetch/axios calls not wrapped in try-catch

// semgrep rule
rules:
  - id: unhandled-fetch
    patterns:
      - pattern: await fetch(...)
      - pattern-not-inside: |
          try { ... } catch { ... }
    message: "fetch() should be wrapped in try-catch"
```

---

#### 19. Use ripgrep over grep
**Soft Rule:** (Implicit in various agent files)

**Enforcement:**
```bash
# CLI alias wrapper - ~/.bashrc or ~/.zshrc
alias grep='rg'

# Or Claude Code hook
if echo "$COMMAND" | grep -qE '^\s*grep\s'; then
    output_context "TIP: Use 'rg' (ripgrep) instead of grep for faster searching."
fi
```

---

#### 20. Test Coverage >80%
**Soft Rule:** "Test coverage: >80%"
**Location:** `code-quality.md`

**Enforcement:**
```javascript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80
      }
    }
  }
})
```

**Hook:**
```bash
# Block commit if coverage below threshold
npm run test -- --coverage --reporter=json
COVERAGE=$(jq '.total.lines.pct' coverage/coverage-summary.json)
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
    block_command "Coverage is ${COVERAGE}%, minimum is 80%"
fi
```

---

## Must Stay as Prompts (Cannot Be Automated) 📝

These require human judgment and cannot be enforced mechanically:

| Soft Rule | Reason It Can't Be Automated |
|-----------|------------------------------|
| "TDD: See test fail before implementing" | Temporal order cannot be verified by static analysis |
| "Explain WHY in commit body, not just WHAT" | Semantic content requires human judgment |
| "Delete code and start over if wrote before test" | Agent behavior cannot be externally verified |
| "Ask for guidance on architectural decisions" | Context-dependent judgment call |
| "Research before implementation for complex tasks" | Complexity classification is subjective |
| "Understand requirements fully before coding" | Comprehension cannot be verified |
| "Code reviewed by self before commit" | Mental process, not verifiable |
| "Keep PRs small and focused" | "Focused" is subjective (size can be enforced) |
| "Acknowledge what's done well in reviews" | Tone/style is subjective |

**These remain in prompts but should be MINIMAL and high-signal.**

---

## Implementation Roadmap

### Phase 1: Quick Wins (1-2 hours)
1. ✅ Delete soft rules that already have hooks (11 rules)
2. Add `@commitlint/config-conventional` + husky
3. Add ESLint rules: `no-explicit-any`, `complexity`, `max-lines-per-function`

### Phase 2: Core Enforcement (1 day)
4. Create `conventional-commit.sh` hook
5. Create `type-check-pre-commit.sh` hook  
6. Create `pr-size-check.sh` hook
7. Enhance `pre-commit.sh` to block on test/lint/type failures

### Phase 3: Extended Rules (2-3 days)
8. Add full ESLint config with all rules above
9. Create `worktree-safety.sh` hook
10. Create `api-validation-check.sh` hook (semgrep)
11. Set up coverage thresholds

### Phase 4: Documentation Cleanup (1 day)
12. Remove all enforced rules from `global.md`, `code-quality.md`, etc.
13. Replace with links to enforcement mechanisms
14. Slim down agent prompts to essentials only

---

## Estimated Context Savings

| File | Current Tokens | After Cleanup | Savings |
|------|----------------|---------------|---------|
| `global.md` | ~2,500 | ~800 | 1,700 |
| `code-quality.md` | ~3,200 | ~1,200 | 2,000 |
| `git-workflow.md` | ~2,800 | ~1,000 | 1,800 |
| `testing.md` | ~2,400 | ~1,400 | 1,000 |
| Agent files (total) | ~4,000 | ~2,500 | 1,500 |
| **TOTAL** | **~15,000** | **~7,000** | **~8,000** |

**~53% reduction in rule-related context usage.**

---

## New Architecture

```
BEFORE:
┌─────────────────────────────────────────────────┐
│  CLAUDE.md / Rules                              │
│  ┌───────────────────────────────────────────┐  │
│  │ "Use conventional commits"                │  │
│  │ "No any types"                            │  │  ← 15,000 tokens
│  │ "Tests must pass"                         │  │    of instructions
│  │ "PR < 300 lines"                          │  │
│  │ ... 50+ more rules ...                    │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘

AFTER:
┌─────────────────────────────────────────────────┐
│  Enforcement Layer (hooks, linters, git hooks)  │
│  ┌───────────────────────────────────────────┐  │
│  │ commitlint → conventional commits         │  │
│  │ ESLint → no-any, complexity, etc.         │  │  ← Impossible
│  │ pre-commit.sh → tests, types, lint        │  │    to break
│  │ pr-size-check.sh → line limit             │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│  CLAUDE.md / Rules (minimal)                    │
│  ┌───────────────────────────────────────────┐  │
│  │ "Follow TDD: see test fail first"         │  │
│  │ "Explain WHY in commits"                  │  │  ← 7,000 tokens
│  │ "Ask before architectural changes"        │  │    (essentials only)
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## Next Steps

1. **Review this analysis** - Any rules I missed? Any enforcement ideas you prefer?
2. **Prioritize** - Which tier should we tackle first?
3. **Execute** - I can implement any of these hooks/configs

The goal: **Zero soft rules that could be hard rules.**
