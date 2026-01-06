# Tool Output Compression Wrappers

> Part of the Jarvis Context Optimization System

## Overview

Tool wrappers reduce token consumption from verbose CLI outputs while preserving essential information. This is critical for maintaining efficient context usage in Claude Code sessions.

## Design Principles

1. **Success = Minimal**: If everything passes, return one line
2. **Failure = Focused**: Stop at first failure, return only relevant info
3. **Progressive Detail**: Add context only when needed
4. **Exit Codes Preserved**: Maintain proper exit codes for CI compatibility
5. **Bypassable**: All wrappers can be bypassed with `VERBOSE_OUTPUT=1`

## Available Wrappers

| Wrapper | Location | Purpose |
|---------|----------|---------|
| `test-wrapper.sh` | `./wrappers/test-wrapper.sh` | Test runners (vitest, jest, pytest, go test, cargo test, etc.) |
| `lint-wrapper.sh` | `./wrappers/lint-wrapper.sh` | Linters (eslint, biome, prettier, pylint, etc.) |
| `build-wrapper.sh` | `./wrappers/build-wrapper.sh` | Build tools (vite, webpack, turbo, cargo, go, etc.) |
| `git-wrapper.sh` | `./wrappers/git-wrapper.sh` | Git commands (diff, log, status, etc.) |
| `gh-wrapper.sh` | `./wrappers/gh-wrapper.sh` | GitHub CLI (pr, issue, run, etc.) |
| `test-runner.sh` | `./wrappers/test-runner.sh` | Legacy test runner (use test-wrapper.sh) |
| `summarize-output.sh` | `./summarize-output.sh` | Generic output summarizer (fallback) |
| `token-counter.sh` | `./token-counter.sh` | Token estimation utility |

## Usage

### Direct Usage

```bash
# Test wrapper
./wrappers/test-wrapper.sh npm test
./wrappers/test-wrapper.sh pnpm vitest run
./wrappers/test-wrapper.sh pytest -v

# Lint wrapper
./wrappers/lint-wrapper.sh pnpm lint
./wrappers/lint-wrapper.sh npx eslint src/

# Build wrapper
./wrappers/build-wrapper.sh pnpm build
./wrappers/build-wrapper.sh npx vite build

# Git wrapper
./wrappers/git-wrapper.sh diff HEAD~5
./wrappers/git-wrapper.sh log --oneline -20

# GitHub CLI wrapper
./wrappers/gh-wrapper.sh pr list
./wrappers/gh-wrapper.sh issue list
```

### Stdin Mode (for piping output)

All wrappers support `--stdin` mode for processing existing output:

```bash
# Pipe test output through wrapper
npm test 2>&1 | ./wrappers/test-wrapper.sh --stdin

# Pipe lint output
npx eslint . 2>&1 | ./wrappers/lint-wrapper.sh --stdin

# Pipe git diff with subcommand hint
git diff HEAD~10 2>&1 | ./wrappers/git-wrapper.sh --stdin diff
```

### Generic Summarization

```bash
# Pipe any command through summarizer
some-verbose-command 2>&1 | ./summarize-output.sh

# Force specific output type
some-command 2>&1 | ./summarize-output.sh --type=test

# Check token count before/after
echo "large output" | ./token-counter.sh
echo "large output" | ./token-counter.sh --detailed
```

### Bypass Compression

All wrappers can be bypassed to show full output:

```bash
# Global bypass
VERBOSE_OUTPUT=1 ./wrappers/test-wrapper.sh npm test

# Wrapper-specific bypass
TEST_WRAPPER_VERBOSE=1 ./wrappers/test-wrapper.sh npm test
GH_WRAPPER_VERBOSE=1 ./wrappers/gh-wrapper.sh pr list
```

## CLAUDE.md Integration

Add this to your project's CLAUDE.md:

```markdown
## Tool Output Compression

Use wrapper commands instead of direct tool calls:

| Instead of | Use |
|------------|-----|
| `npm test` | `~/.claude/lib/context/wrappers/test-wrapper.sh npm test` |
| `pnpm lint` | `~/.claude/lib/context/wrappers/lint-wrapper.sh pnpm lint` |
| `pnpm build` | `~/.claude/lib/context/wrappers/build-wrapper.sh pnpm build` |
| `git diff` | `~/.claude/lib/context/wrappers/git-wrapper.sh diff` |
| `gh pr list` | `~/.claude/lib/context/wrappers/gh-wrapper.sh pr list` |

Or pipe existing output:
| Verbose command | Compressed |
|-----------------|------------|
| `npm test 2>&1` | `npm test 2>&1 \| ~/.claude/lib/context/wrappers/test-wrapper.sh --stdin` |

These wrappers compress output to minimize context usage.
Set `VERBOSE_OUTPUT=1` to bypass compression.
```

## Hook Integration

The `compress-output.sh` hook automatically detects command types and provides
compression context. Located at `~/.claude/hooks/compress-output.sh`.

Supported command types:
- **test**: vitest, jest, pytest, go test, cargo test, mocha, etc.
- **lint**: eslint, biome, prettier, pylint, flake8, ruff, etc.
- **build**: vite, webpack, turbo, next, cargo build, go build, etc.
- **git**: All git commands
- **gh**: GitHub CLI commands
- **install**: npm install, pip install, etc.

## Expected Token Savings

| Scenario | Before | After | Reduction |
|----------|--------|-------|-----------|
| All tests pass (300 tests) | ~5,000 | ~20 | 99.6% |
| 1 test failure | ~5,000 | ~200 | 96% |
| TypeScript clean | ~500 | ~10 | 98% |
| 5 TypeScript errors | ~2,000 | ~150 | 92.5% |
| Lint clean | ~300 | ~10 | 96.7% |
| 10 lint errors | ~1,000 | ~100 | 90% |
| Build success | ~3,000 | ~20 | 99.3% |
| Build failure | ~3,000 | ~150 | 95% |
| `git diff` (20 files) | ~2,000 | ~100 | 95% |
| `git log` (50 commits) | ~3,000 | ~200 | 93% |
| `gh pr list` (50 PRs) | ~3,000 | ~500 | 83% |
| `gh issue list` (100 issues) | ~5,000 | ~600 | 88% |

## Creating Custom Wrappers

Template for new wrappers:

```bash
#!/bin/bash
# Custom wrapper template
# Supports both direct execution and stdin mode

set -e

# Bypass if verbose mode requested
if [ "${VERBOSE_OUTPUT:-0}" = "1" ]; then
  if [ "$1" = "--stdin" ]; then
    cat
  else
    exec "$@"
  fi
  exit 0
fi

# Handle stdin mode
if [ "$1" = "--stdin" ]; then
  OUTPUT=$(cat)
  EXIT_CODE=0
  # Try to detect exit code from output patterns
  if echo "$OUTPUT" | grep -qE "error|Error|FAIL"; then
    EXIT_CODE=1
  fi
else
  OUTPUT=$("$@" 2>&1) || true
  EXIT_CODE=$?
fi

if [ $EXIT_CODE -eq 0 ]; then
  # Success: extract minimal summary
  echo "Success: [summary here]"
else
  # Failure: extract relevant error info
  echo "Failed:"
  echo ""
  echo "$OUTPUT" | grep -A 5 "error\|Error\|FAIL" | head -20
  echo ""
  echo "[Run command directly for full output]"
fi

exit $EXIT_CODE
```

## Utility Scripts

### summarize-output.sh

Generic summarizer that:
- Auto-detects output type (test, lint, build, typescript, git, github)
- Extracts key metrics (pass/fail counts, timing, file counts)
- Truncates to essential information (default: 30 lines max)
- Supports forced type detection with `--type=TYPE`
- Bypassable with `VERBOSE_OUTPUT=1`

Usage:
```bash
# Auto-detect and summarize
some-command 2>&1 | ./summarize-output.sh

# Force type
some-command 2>&1 | ./summarize-output.sh --type=test

# Verbose detection info
some-command 2>&1 | ./summarize-output.sh --verbose
```

### token-counter.sh

Estimates token count to help:
- Decide when summarization is needed
- Measure compression effectiveness
- Track context budget usage
- Detect code vs text content

Usage:
```bash
# Simple count
echo "text" | ./token-counter.sh

# Detailed breakdown
echo "text" | ./token-counter.sh --detailed

# JSON output
echo "text" | ./token-counter.sh --format=json

# Custom warning threshold
echo "text" | ./token-counter.sh --warn=10000
```

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `VERBOSE_OUTPUT` | Bypass all compression | `0` |
| `JARVIS_DISABLE_COMPRESS` | Disable compress-output hook | `0` |
| `TEST_WRAPPER_MAX_ERRORS` | Max errors shown in test output | `5` |
| `TEST_WRAPPER_MAX_STACK` | Max stack trace lines per error | `10` |
| `LINT_WRAPPER_MAX_FILES` | Max files shown in lint output | `10` |
| `LINT_WRAPPER_MAX_ERRORS` | Max errors per file | `5` |
| `BUILD_WRAPPER_MAX_ERRORS` | Max errors shown in build output | `5` |
| `GIT_WRAPPER_MAX_FILES` | Max files in git file lists | `20` |
| `GIT_WRAPPER_MAX_DIFF` | Max diff lines per file | `50` |
