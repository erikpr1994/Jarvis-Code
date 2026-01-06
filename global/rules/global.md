---
name: global-rules
category: critical
confidence: 0.9
description: Core rules that apply to ALL development work, regardless of project or technology
---

# Global Rules

## Overview

These rules are non-negotiable across all projects, technologies, and contexts. They represent foundational principles that ensure code quality, maintainability, and correctness.

## The Iron Laws

```
1. NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
2. NO `any` TYPES IN PRODUCTION CODE
3. NO `@ts-ignore` WITHOUT DOCUMENTED JUSTIFICATION
4. TESTS MUST PASS BEFORE COMMIT
5. WORKSPACE ISOLATION IS MANDATORY
```

## Rule Categories

| Category | Purpose | Confidence Threshold |
|----------|---------|----------------------|
| **Critical** | Bugs, security, data loss | 90% |
| **Quality** | Code standards, patterns | 80% |
| **Style** | Formatting, naming | 70% |
| **Suggestion** | Improvements, optimizations | 60% |

## Priority Order

When trade-offs arise, follow this priority:

```
Correctness > Maintainability > Performance > Brevity
```

## Core Principles

### 1. Test-Driven Development

Every feature, bug fix, or behavior change must follow TDD:

```
Write test -> Watch it fail -> Write minimal code -> Watch it pass -> Refactor
```

**Exception requires explicit human approval:**
- Throwaway prototypes
- Generated code (e.g., Prisma client)
- Configuration files

### 2. Type Safety

```typescript
// GOOD: Explicit types
interface UserInput {
  email: string;
  name: string;
}

function createUser(input: UserInput): Promise<User> {
  // Implementation
}

// BAD: any type
function createUser(input: any): Promise<any> {
  // No type safety
}
```

**Rules:**
- Enable strict mode in all TypeScript configurations
- Use `unknown` instead of `any` for truly unknown types
- Use type guards for runtime type checking
- Never cast without runtime validation

### 3. Error Handling

All external calls and operations that can fail must have error handling:

```typescript
// GOOD: Proper error handling
try {
  const result = await externalService.call(data);
  return { success: true, data: result };
} catch (error) {
  logger.error('External service failed', { error });
  return { success: false, error: 'Service unavailable' };
}

// BAD: Unhandled errors
const result = await externalService.call(data);
return result;
```

### 4. Input Validation

All user inputs must be validated at system boundaries:

```typescript
// GOOD: Validated input
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

const validatedData = schema.parse(input);

// BAD: Trust user input
const { email, password } = input;
```

### 5. Security Defaults

- Use parameterized queries (never string concatenation for SQL)
- Verify both authentication AND authorization before sensitive operations
- Sanitize all user inputs for display
- Use HTTPS in production

## Workspace Isolation

Every significant implementation work uses isolated workspaces:

```bash
# Create isolated worktree
git worktree add .worktrees/feature-name -b feature/feature-name

# Work in isolation
cd .worktrees/feature-name

# Clean up after merge
git worktree remove .worktrees/feature-name
```

**Benefits:**
- Work on multiple features simultaneously
- No interference between branches
- Clean git status
- Easy parallel development

## Commit Requirements

Before any commit:

1. All tests pass
2. No TypeScript errors
3. No linting errors
4. No `any` types added
5. No `@ts-ignore` without justification

```bash
# Verify before commit
npm test && npm run type-check && npm run lint
```

## Research Before Implementation

For complex tasks:

1. **Classify complexity:** Trivial, Moderate, Complex
2. **Match effort:** Don't over-engineer trivial tasks, don't under-plan complex ones
3. **Gather context:** Read relevant files, check existing patterns
4. **Verify paths:** Check 3+ examples before assuming import paths

## Integration Safety

Before modifying any feature:

1. Identify all downstream consumers
2. Validate changes against all consumers
3. Test integration points
4. Check for data format/API contract changes

## Self-Correction Protocol

- Fix syntax errors immediately without asking
- For low-level errors, correct and continue
- For architectural decisions, ask for guidance

## Red Flags - STOP and Ask

- About to use `any` type
- About to add `@ts-ignore`
- Tests are failing
- Can't explain why code works
- "Just this once" rationalization
- Skipping TDD "because it's simple"
- Destructive operations without confirmation

## Quick Reference

| Rule | Enforcement | Action on Violation |
|------|-------------|---------------------|
| TDD | Block | Delete code, start over |
| No `any` | Block | Add proper types |
| No `@ts-ignore` | Block | Fix underlying issue |
| Tests pass | Block | Fix tests |
| Workspace isolation | Warn | Create worktree |
| Conventional commits | Warn | Reformat message |
| <300 line PRs | Warn | Split PR |

## Rationale

These rules exist because:

1. **TDD prevents bugs** - Seeing tests fail proves they test something
2. **Type safety catches errors** - At compile time, not runtime
3. **Error handling prevents crashes** - Graceful degradation
4. **Input validation prevents attacks** - XSS, SQL injection, etc.
5. **Workspace isolation enables parallel work** - No branch conflicts
6. **Commit requirements ensure quality** - Never commit broken code
