# Context Optimization (Tool Output Compression)

> Part of the [Jarvis Specification](./README.md)

## 12. Context Optimization (Tool Output Compression)

### 12.1 The Problem

Claude Code consumes excessive context when running bash tools like tests, linting, and builds. A typical test run can add 5-10k tokens of noise:

```
# BAD: Verbose output (5000+ tokens)
✓ src/components/Button.test.tsx (12 tests) 45ms
✓ src/components/Card.test.tsx (8 tests) 32ms
✓ src/components/Modal.test.tsx (15 tests) 67ms
... (200 more lines)

Test Suites: 45 passed, 45 total
Tests:       312 passed, 312 total
Snapshots:   0 total
Time:        12.345s
```

```
# GOOD: Compressed output (~20 tokens)
✅ All 312 tests passed (12.3s)
```

### 12.2 Solution Architecture

Three complementary strategies:

| Strategy | Description | Best For |
|----------|-------------|----------|
| **Output Wrappers** | Shell scripts that parse and compress tool output | Direct CLI usage |
| **MCP Servers** | Language-specific servers with optimized output | IDE integration |
| **QA Subagent** | Dedicated agent for running validations | Complex pipelines |

### 12.3 Output Wrappers (TypeScript/Node.js)

#### 12.3.1 Wrapper Design Principles

1. **Success = Minimal**: If everything passes, return one line
2. **Failure = Focused**: Stop at first failure, return only relevant info
3. **Progressive Detail**: Add context only when needed
4. **Exit Codes Preserved**: Maintain proper exit codes for CI

#### 12.3.2 Test Wrapper (Vitest/Jest)

```bash
#!/bin/bash
# ~/.claude/wrappers/test-wrapper.sh

OUTPUT=$(pnpm test "$@" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  # Extract summary only
  TESTS=$(echo "$OUTPUT" | grep -oP '\d+ passed' | head -1)
  TIME=$(echo "$OUTPUT" | grep -oP 'Time:\s*[\d.]+s' | head -1)
  echo "✅ All tests passed: $TESTS ($TIME)"
else
  # Extract only failing test info
  echo "❌ Test failure detected:"
  echo ""
  # Show failed test name and assertion
  echo "$OUTPUT" | grep -A 20 "FAIL\|AssertionError\|Expected\|Received" | head -30
  echo ""
  echo "Run 'pnpm test' for full output"
fi

exit $EXIT_CODE
```

#### 12.3.3 TypeScript Wrapper (tsc)

```bash
#!/bin/bash
# ~/.claude/wrappers/tsc-wrapper.sh

OUTPUT=$(pnpm tsc --noEmit 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ TypeScript: No errors"
else
  # Count errors and show first 3
  ERROR_COUNT=$(echo "$OUTPUT" | grep -c "error TS")
  echo "❌ TypeScript: $ERROR_COUNT errors"
  echo ""
  echo "$OUTPUT" | grep -A 2 "error TS" | head -15

  if [ $ERROR_COUNT -gt 3 ]; then
    echo ""
    echo "... and $((ERROR_COUNT - 3)) more errors"
    echo "Run 'pnpm tsc --noEmit' for full output"
  fi
fi

exit $EXIT_CODE
```

#### 12.3.4 Lint Wrapper (ESLint/Biome)

```bash
#!/bin/bash
# ~/.claude/wrappers/lint-wrapper.sh

OUTPUT=$(pnpm lint "$@" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ Lint: No issues"
else
  # Count and categorize
  ERRORS=$(echo "$OUTPUT" | grep -c "error")
  WARNINGS=$(echo "$OUTPUT" | grep -c "warning")

  echo "❌ Lint: $ERRORS errors, $WARNINGS warnings"
  echo ""

  # Show only errors (not warnings)
  echo "$OUTPUT" | grep -B 1 "error" | head -20

  if [ $ERRORS -gt 5 ]; then
    echo ""
    echo "... showing first 5 of $ERRORS errors"
    echo "Run 'pnpm lint' for full output"
  fi
fi

exit $EXIT_CODE
```

#### 12.3.5 Build Wrapper (Turbo/Next.js)

```bash
#!/bin/bash
# ~/.claude/wrappers/build-wrapper.sh

OUTPUT=$(pnpm build 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  # Extract build stats
  DURATION=$(echo "$OUTPUT" | grep -oP 'compiled.*in\s*[\d.]+\s*[ms]+' | tail -1)
  echo "✅ Build succeeded: $DURATION"
else
  echo "❌ Build failed:"
  echo ""
  # Show the actual error, not the full trace
  echo "$OUTPUT" | grep -A 5 "Error:\|error:\|Failed to compile" | head -20
fi

exit $EXIT_CODE
```

### 12.4 Wrapper Integration

#### 12.4.1 Hook-Based Wrapper Selection

```bash
#!/bin/bash
# ~/.claude/hooks/compress-output.sh
# Trigger: PreToolUse (Bash)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Detect commands that need compression
case "$COMMAND" in
  *"pnpm test"*|*"vitest"*|*"jest"*)
    # Replace with wrapped version
    WRAPPED_CMD=$(echo "$COMMAND" | sed 's/pnpm test/~\/.claude\/wrappers\/test-wrapper.sh/')
    echo "{\"command\": \"$WRAPPED_CMD\"}"
    ;;
  *"tsc"*|*"pnpm typecheck"*)
    WRAPPED_CMD="~/.claude/wrappers/tsc-wrapper.sh"
    echo "{\"command\": \"$WRAPPED_CMD\"}"
    ;;
  *"pnpm lint"*|*"eslint"*|*"biome"*)
    WRAPPED_CMD=$(echo "$COMMAND" | sed 's/pnpm lint/~\/.claude\/wrappers\/lint-wrapper.sh/')
    echo "{\"command\": \"$WRAPPED_CMD\"}"
    ;;
  *"pnpm build"*|*"turbo build"*)
    WRAPPED_CMD="~/.claude/wrappers/build-wrapper.sh"
    echo "{\"command\": \"$WRAPPED_CMD\"}"
    ;;
  *)
    # No modification needed
    ;;
esac
```

#### 12.4.2 CLAUDE.md Aliases

```markdown
# Tool Output Compression

Use wrapper commands instead of direct tool calls:

| Instead of | Use |
|------------|-----|
| `pnpm test` | `~/.claude/wrappers/test-wrapper.sh` |
| `pnpm tsc --noEmit` | `~/.claude/wrappers/tsc-wrapper.sh` |
| `pnpm lint` | `~/.claude/wrappers/lint-wrapper.sh` |
| `pnpm build` | `~/.claude/wrappers/build-wrapper.sh` |

These wrappers compress output to minimize context usage while preserving essential information.
```

### 12.5 QA Subagent Strategy

For complex validation pipelines, use a dedicated QA subagent:

```markdown
# QA Subagent Pattern

Instead of running validations in the main context:

1. Spawn QA subagent with Haiku model (fast, cheap)
2. Subagent runs all validations
3. Subagent returns compressed summary
4. Main context receives only: pass/fail + issues

Benefits:
- Validation output never enters main context
- Parallel execution of multiple checks
- Specialized agent can interpret errors better
- Lower token cost (Haiku vs Sonnet/Opus)
```

#### 12.5.1 QA Agent Definition

```markdown
---
name: qa-validator
description: Runs validation pipeline and returns compressed results
model: haiku
---

# QA Validator Agent

Run all project validations and return compressed summary.

## Process

1. Run validations in order (fail-fast):
   - TypeScript compilation
   - Linting
   - Unit tests
   - Build check

2. Return compressed report:

### If all pass:
```
✅ All validations passed
- TypeScript: clean
- Lint: clean
- Tests: 312 passed (12s)
- Build: success (45s)
```

### If any fail:
```
❌ Validation failed at: [stage]

[First error details - max 10 lines]

Subsequent stages skipped.
```
```

### 12.6 Language-Specific MCP Servers

For deeper integration, consider language-specific MCP servers:

| Language | MCP Server | Features |
|----------|------------|----------|
| **TypeScript** | typescript-mcp (future) | Type checking, go-to-definition, smart diagnostics |
| **Dart** | dart-mcp | Analysis, tests, code actions |
| **Go** | gopls-mcp | Type info, tests, diagnostics |
| **Rust** | rust-analyzer-mcp | Cargo integration, diagnostics |

These provide optimized output by default and integrate better with the language's tooling.

### 12.7 Expected Impact

| Scenario | Before (tokens) | After (tokens) | Reduction |
|----------|-----------------|----------------|-----------|
| All tests pass (300 tests) | ~5,000 | ~20 | 99.6% |
| 1 test failure | ~5,000 | ~200 | 96% |
| TypeScript clean | ~500 | ~10 | 98% |
| 5 TypeScript errors | ~2,000 | ~150 | 92.5% |
| Lint clean | ~300 | ~10 | 96.7% |
| Build success | ~3,000 | ~20 | 99.3% |

### 12.8 Implementation Priority

1. **Phase 1** (MVP): Add wrapper scripts to ~/.claude/wrappers/
2. **Phase 2**: Create PreToolUse hook for automatic wrapper selection
3. **Phase 3**: Implement QA subagent for complex pipelines
4. **Phase 4**: Investigate/build TypeScript MCP server
