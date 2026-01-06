# Verification & Quality Gates

> Part of the [Jarvis Specification](./README.md)

## 15. Verification & Quality Gates

### 15.1 Verification Levels

| Level | Checks | When |
|-------|--------|------|
| **Quick** | Lint, types | During development |
| **Standard** | + Unit tests | Before commit |
| **Full** | + Integration, E2E, review | Before PR |
| **Release** | + Performance, security audit | Before deploy |

### 15.2 Full Verification Pipeline

```
1. AUTOMATED CHECKS
   ├── TypeScript compilation (tsc --noEmit)
   ├── Linting (eslint, biome)
   ├── Formatting (prettier)
   └── Unit tests (vitest)

2. CODE REVIEW (Parallel)
   ├── code-reviewer (Opus) - Quality & CLAUDE.md compliance
   ├── spec-reviewer (Sonnet) - Specification alignment
   ├── security-reviewer - Vulnerabilities
   ├── accessibility-auditor - WCAG compliance
   └── performance-reviewer - Optimization

3. INTEGRATION CHECKS
   ├── Integration tests
   ├── E2E tests (playwright)
   └── Build verification

4. HUMAN CONFIRMATION
   └── Explicit user approval
```

### 15.3 Review Agent Configuration

```yaml
# submit-pr skill review configuration
review_agents:
  - agent: code-reviewer
    model: opus
    parallel_group: 1
    required: true

  - agent: spec-reviewer
    model: sonnet
    parallel_group: 1
    required: true

  - agent: security-reviewer
    model: sonnet
    parallel_group: 2
    required: false

  - agent: accessibility-auditor
    model: sonnet
    parallel_group: 2
    required: false

  - agent: performance-reviewer
    model: sonnet
    parallel_group: 2
    required: false

# Group 1 runs first (blocking)
# Group 2 runs in parallel (non-blocking)
```
