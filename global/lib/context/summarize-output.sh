#!/bin/bash
# summarize-output.sh - Summarize verbose tool outputs to reduce token usage
#
# Usage:
#   some-command 2>&1 | ./summarize-output.sh
#   ./summarize-output.sh < output.txt
#   ./summarize-output.sh --type=test < output.txt
#
# Options:
#   --type=TYPE    Force output type detection (test, lint, build, git, generic)
#   --max-lines=N  Maximum lines in summary (default: 30)
#   --verbose      Show detection info

set -e

# Bypass if verbose mode requested
if [ "${VERBOSE_OUTPUT:-0}" = "1" ]; then
  cat
  exit 0
fi

# Default settings
MAX_LINES=30
OUTPUT_TYPE=""
VERBOSE=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --type=*)
      OUTPUT_TYPE="${arg#*=}"
      ;;
    --max-lines=*)
      MAX_LINES="${arg#*=}"
      ;;
    --verbose)
      VERBOSE=true
      ;;
  esac
done

# Read input
INPUT=$(cat)

# Count original lines and estimate tokens
ORIGINAL_LINES=$(echo "$INPUT" | wc -l | tr -d ' ')
ORIGINAL_CHARS=$(echo "$INPUT" | wc -c | tr -d ' ')
ESTIMATED_TOKENS=$((ORIGINAL_CHARS / 4))

# Auto-detect output type if not specified
if [ -z "$OUTPUT_TYPE" ]; then
  if echo "$INPUT" | grep -qE "(PASS|FAIL|passed|failed).*test|Test Suites:|Tests:|vitest|jest|pytest|✓.*test|✗.*test"; then
    OUTPUT_TYPE="test"
  elif echo "$INPUT" | grep -qE "error TS[0-9]+|warning TS[0-9]+|tsc --noEmit"; then
    OUTPUT_TYPE="typescript"
  elif echo "$INPUT" | grep -qE "ESLint|eslint|biome|lint|Linting|✖.*problems?"; then
    OUTPUT_TYPE="lint"
  elif echo "$INPUT" | grep -qE "Build|build|compiled|webpack|vite|turbo|esbuild|rollup|bundle"; then
    OUTPUT_TYPE="build"
  elif echo "$INPUT" | grep -qE "^commit [a-f0-9]+|^Author:|^Date:|^diff --git|files? changed"; then
    OUTPUT_TYPE="git"
  elif echo "$INPUT" | grep -qE "^\#[0-9]+|pull request|issue|PR|gh pr|gh issue"; then
    OUTPUT_TYPE="github"
  else
    OUTPUT_TYPE="generic"
  fi
fi

if [ "$VERBOSE" = true ]; then
  echo "[Detected type: $OUTPUT_TYPE, Original: $ORIGINAL_LINES lines, ~$ESTIMATED_TOKENS tokens]"
  echo ""
fi

# Summarize based on type
case "$OUTPUT_TYPE" in
  test)
    # Check for success/failure
    if echo "$INPUT" | grep -qE "passed.*0 failed|All tests passed|Tests:.*passed.*total"; then
      PASSED=$(echo "$INPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "all")
      TIME=$(echo "$INPUT" | grep -oE "Time:?\s*[0-9.]+\s*[ms]+" | head -1 || echo "")
      echo "All tests passed: $PASSED ${TIME:+($TIME)}"
    else
      echo "Test failures detected:"
      echo ""
      # Extract failed test info
      echo "$INPUT" | grep -E "FAIL|failed|Error|AssertionError" | head -10
      echo ""
      # Show assertion details
      echo "$INPUT" | grep -A 3 "Expected\|Received\|AssertionError" | head -15
      echo ""
      FAILED_COUNT=$(echo "$INPUT" | grep -oE "[0-9]+ failed" | head -1 || echo "some")
      echo "[$FAILED_COUNT tests failed - run tests directly for full output]"
    fi
    ;;

  typescript)
    ERROR_COUNT=$(echo "$INPUT" | grep -c "error TS" || echo "0")
    WARNING_COUNT=$(echo "$INPUT" | grep -c "warning TS" || echo "0")

    if [ "$ERROR_COUNT" = "0" ] && [ "$WARNING_COUNT" = "0" ]; then
      echo "TypeScript: No errors or warnings"
    elif [ "$ERROR_COUNT" = "0" ]; then
      echo "TypeScript: $WARNING_COUNT warnings (no errors)"
      echo ""
      echo "$INPUT" | grep "warning TS" | head -5
    else
      echo "TypeScript: $ERROR_COUNT errors, $WARNING_COUNT warnings"
      echo ""
      echo "$INPUT" | grep -B 1 "error TS" | head -20
      if [ "$ERROR_COUNT" -gt 5 ]; then
        echo ""
        echo "[... and $((ERROR_COUNT - 5)) more errors]"
      fi
    fi
    ;;

  lint)
    ERROR_COUNT=$(echo "$INPUT" | grep -cE "\berror\b" || echo "0")
    WARNING_COUNT=$(echo "$INPUT" | grep -cE "\bwarning\b" || echo "0")

    if [ "$ERROR_COUNT" = "0" ] && [ "$WARNING_COUNT" = "0" ]; then
      echo "Lint: No issues found"
    else
      echo "Lint: $ERROR_COUNT errors, $WARNING_COUNT warnings"
      echo ""
      # Show errors first
      echo "$INPUT" | grep -E "\berror\b" | head -10
      if [ "$ERROR_COUNT" -gt 10 ]; then
        echo "[... and $((ERROR_COUNT - 10)) more errors]"
      fi
    fi
    ;;

  build)
    if echo "$INPUT" | grep -qE "error|Error|failed|FAILED"; then
      echo "Build failed:"
      echo ""
      echo "$INPUT" | grep -A 5 -E "error|Error|failed" | head -20
    else
      DURATION=$(echo "$INPUT" | grep -oE "in [0-9.]+\s*[ms]+" | tail -1 || echo "")
      SIZE=$(echo "$INPUT" | grep -oE "[0-9.]+\s*[kKmM][bB]" | tail -1 || echo "")
      echo "Build succeeded ${DURATION:+$DURATION }${SIZE:+(size: $SIZE)}"
    fi
    ;;

  git)
    # Summarize git log or diff output
    COMMIT_COUNT=$(echo "$INPUT" | grep -c "^commit " || echo "0")
    if [ "$COMMIT_COUNT" -gt 0 ]; then
      echo "Git log: $COMMIT_COUNT commits"
      echo ""
      echo "$INPUT" | grep -E "^commit |^Author:|^    " | head -$MAX_LINES
    else
      # Assume it's a diff
      FILES_CHANGED=$(echo "$INPUT" | grep -c "^diff --git" || echo "0")
      INSERTIONS=$(echo "$INPUT" | grep -oE "[0-9]+ insertion" | grep -oE "[0-9]+" | paste -sd+ - | bc 2>/dev/null || echo "0")
      DELETIONS=$(echo "$INPUT" | grep -oE "[0-9]+ deletion" | grep -oE "[0-9]+" | paste -sd+ - | bc 2>/dev/null || echo "0")
      echo "Diff: $FILES_CHANGED files, +$INSERTIONS/-$DELETIONS lines"
    fi
    ;;

  github)
    # Count items (PRs, issues, etc.)
    ITEM_COUNT=$(echo "$INPUT" | grep -cE "^\#[0-9]+|^[0-9]+\s+" || echo "0")
    echo "GitHub: $ITEM_COUNT items"
    echo ""
    # Show first few items with key info
    echo "$INPUT" | head -$MAX_LINES
    if [ "$ORIGINAL_LINES" -gt "$MAX_LINES" ]; then
      echo ""
      echo "[... and $((ORIGINAL_LINES - MAX_LINES)) more lines]"
    fi
    ;;

  generic|*)
    # Generic summarization: show head + stats
    if [ "$ORIGINAL_LINES" -le "$MAX_LINES" ]; then
      echo "$INPUT"
    else
      echo "$INPUT" | head -$((MAX_LINES - 3))
      echo ""
      echo "[... truncated $((ORIGINAL_LINES - MAX_LINES + 3)) lines]"
      echo "[Original: $ORIGINAL_LINES lines, ~$ESTIMATED_TOKENS tokens]"
    fi
    ;;
esac
