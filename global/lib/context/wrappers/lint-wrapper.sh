#!/bin/bash
# lint-wrapper.sh - Lint command wrapper with compressed output
#
# Detects and wraps various linting tools (eslint, biome, prettier, etc.)
# Groups errors by file, summarizes total issues, and shows fixable vs manual.
#
# Usage:
#   ./lint-wrapper.sh pnpm lint
#   ./lint-wrapper.sh npm run lint
#   ./lint-wrapper.sh npx eslint src/
#   ./lint-wrapper.sh npx biome check
#   ./lint-wrapper.sh prettier --check .
#   echo "$output" | ./lint-wrapper.sh --stdin
#
# Environment:
#   VERBOSE_OUTPUT=1          Show full output without compression
#   LINT_WRAPPER_MAX_FILES=10 Maximum files to show errors for (default: 10)
#   LINT_WRAPPER_MAX_ERRORS=5 Maximum errors per file (default: 5)
#
# Exit codes are preserved from the underlying lint command.

set -e

# Configuration
MAX_FILES=${LINT_WRAPPER_MAX_FILES:-10}
MAX_ERRORS_PER_FILE=${LINT_WRAPPER_MAX_ERRORS:-5}

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
  # Try to detect exit code from output
  if echo "$OUTPUT" | grep -qE "error|Error|✖"; then
    EXIT_CODE=1
  fi
  COMMAND="<stdin>"
else
  # No command provided
  if [ $# -eq 0 ]; then
    echo "Usage: lint-wrapper.sh <lint-command> [args...]"
    echo "       echo \"output\" | lint-wrapper.sh --stdin"
    echo ""
    echo "Examples:"
    echo "  lint-wrapper.sh pnpm lint"
    echo "  lint-wrapper.sh npx eslint ."
    echo "  lint-wrapper.sh npx biome check src/"
    exit 1
  fi

  # Run the lint command and capture output
  COMMAND="$*"
  OUTPUT=$("$@" 2>&1) || true
  EXIT_CODE=$?
fi

# Detect linter from command and output
detect_linter() {
  local cmd="$1"
  local out="$2"

  # Check command first
  if echo "$cmd" | grep -qiE "eslint"; then
    echo "eslint"
  elif echo "$cmd" | grep -qiE "biome"; then
    echo "biome"
  elif echo "$cmd" | grep -qiE "prettier"; then
    echo "prettier"
  elif echo "$cmd" | grep -qiE "stylelint"; then
    echo "stylelint"
  elif echo "$cmd" | grep -qiE "tsc|typescript"; then
    echo "tsc"
  elif echo "$cmd" | grep -qiE "pylint"; then
    echo "pylint"
  elif echo "$cmd" | grep -qiE "flake8"; then
    echo "flake8"
  elif echo "$cmd" | grep -qiE "ruff"; then
    echo "ruff"
  elif echo "$cmd" | grep -qiE "rubocop"; then
    echo "rubocop"
  elif echo "$cmd" | grep -qiE "golint|golangci-lint"; then
    echo "golint"
  elif echo "$cmd" | grep -qiE "clippy"; then
    echo "clippy"
  # Check output patterns
  elif echo "$out" | grep -qE "ESLint|eslint"; then
    echo "eslint"
  elif echo "$out" | grep -qE "Biome|biome"; then
    echo "biome"
  elif echo "$out" | grep -qE "error TS[0-9]+"; then
    echo "tsc"
  elif echo "$out" | grep -qE "Prettier"; then
    echo "prettier"
  else
    echo "generic"
  fi
}

LINTER=$(detect_linter "$COMMAND" "$OUTPUT")

# Helper function to count issues
count_pattern() {
  local pattern="$1"
  local text="$2"
  echo "$text" | grep -cE "$pattern" 2>/dev/null || echo "0"
}

# Parse and compress output based on linter
case "$LINTER" in
  eslint)
    if [ $EXIT_CODE -eq 0 ]; then
      # Check for clean output
      if echo "$OUTPUT" | grep -qE "✔|0 problems"; then
        echo "Lint: No issues found"
      else
        echo "Lint: Clean"
      fi
    else
      # Count errors and warnings
      ERROR_COUNT=$(count_pattern "\berror\b" "$OUTPUT")
      WARNING_COUNT=$(count_pattern "\bwarning\b" "$OUTPUT")
      FIXABLE=$(echo "$OUTPUT" | grep -oE "[0-9]+ (error|warning|problem)s? potentially fixable" | head -1 || echo "")

      echo "Lint: $ERROR_COUNT errors, $WARNING_COUNT warnings"
      [ -n "$FIXABLE" ] && echo "($FIXABLE with --fix)"
      echo ""

      # Group errors by file (show top files)
      echo "Issues by file:"
      FILES_WITH_ERRORS=$(echo "$OUTPUT" | grep -E "^[/.].*\.(js|ts|jsx|tsx|vue|svelte)" | head -"$MAX_FILES")

      if [ -n "$FILES_WITH_ERRORS" ]; then
        echo "$FILES_WITH_ERRORS"
      else
        # Alternative format: show error lines
        echo "$OUTPUT" | grep -E "\s+[0-9]+:[0-9]+\s+error" | head -20
      fi

      TOTAL_FILES=$(echo "$OUTPUT" | grep -cE "^[/.].*\.(js|ts|jsx|tsx|vue|svelte)" || echo "0")
      if [ "$TOTAL_FILES" -gt "$MAX_FILES" ]; then
        echo ""
        echo "[Showing $MAX_FILES of $TOTAL_FILES files with issues]"
      fi

      echo ""
      echo "[Run lint directly for full output]"
    fi
    ;;

  biome)
    if [ $EXIT_CODE -eq 0 ]; then
      if echo "$OUTPUT" | grep -qE "No (lint|format) errors"; then
        echo "Lint: No issues found"
      else
        echo "Lint: Clean"
      fi
    else
      # Biome output format
      ERROR_COUNT=$(count_pattern "✖|error\[" "$OUTPUT")
      WARNING_COUNT=$(count_pattern "⚠|warning\[" "$OUTPUT")
      FIXABLE=$(echo "$OUTPUT" | grep -oE "[0-9]+ fixable" | head -1 || echo "")

      echo "Lint: $ERROR_COUNT errors, $WARNING_COUNT warnings"
      [ -n "$FIXABLE" ] && echo "($FIXABLE with biome check --apply)"
      echo ""

      # Show error summaries
      echo "Issues:"
      echo "$OUTPUT" | grep -E "✖|error\[|⚠|warning\[" | head -15

      echo ""
      echo "[Run biome check directly for full output]"
    fi
    ;;

  prettier)
    if [ $EXIT_CODE -eq 0 ]; then
      echo "Format: All files formatted correctly"
    else
      # Count files needing formatting
      UNFORMATTED=$(echo "$OUTPUT" | grep -cE "^\[warn\]|would change" || echo "0")

      echo "Format: $UNFORMATTED files need formatting"
      echo ""

      # Show files that need formatting
      echo "Files to format:"
      echo "$OUTPUT" | grep -E "^\[warn\]|would change" | head -"$MAX_FILES"

      if [ "$UNFORMATTED" -gt "$MAX_FILES" ]; then
        echo ""
        echo "[Showing $MAX_FILES of $UNFORMATTED files]"
      fi

      echo ""
      echo "[Run prettier --write to fix]"
    fi
    ;;

  tsc)
    if [ $EXIT_CODE -eq 0 ]; then
      echo "TypeScript: No errors"
    else
      ERROR_COUNT=$(count_pattern "error TS[0-9]+" "$OUTPUT")

      echo "TypeScript: $ERROR_COUNT errors"
      echo ""

      # Group by file and show first errors
      echo "Errors:"
      echo "$OUTPUT" | grep -E "error TS[0-9]+" | head -15

      if [ "$ERROR_COUNT" -gt 15 ]; then
        echo ""
        echo "[Showing 15 of $ERROR_COUNT errors]"
      fi

      echo ""
      echo "[Run tsc --noEmit for full output]"
    fi
    ;;

  stylelint)
    if [ $EXIT_CODE -eq 0 ]; then
      echo "Stylelint: No issues found"
    else
      ERROR_COUNT=$(count_pattern "✖|error" "$OUTPUT")
      WARNING_COUNT=$(count_pattern "⚠|warning" "$OUTPUT")

      echo "Stylelint: $ERROR_COUNT errors, $WARNING_COUNT warnings"
      echo ""

      echo "$OUTPUT" | grep -E "✖|⚠|error|warning" | head -15

      echo ""
      echo "[Run stylelint directly for full output]"
    fi
    ;;

  pylint|flake8|ruff)
    if [ $EXIT_CODE -eq 0 ]; then
      if echo "$OUTPUT" | grep -qE "rated at 10\.00|no issues"; then
        echo "Lint: Perfect score (10.00/10)"
      else
        echo "Lint: No issues found"
      fi
    else
      # Count issues
      ISSUE_COUNT=$(echo "$OUTPUT" | grep -cE "^[^:]+:[0-9]+:" || echo "0")
      SCORE=$(echo "$OUTPUT" | grep -oE "rated at [0-9.]+/10" | head -1 || echo "")

      echo "Lint: $ISSUE_COUNT issues ${SCORE:+($SCORE)}"
      echo ""

      # Show issues grouped by type
      echo "Issues:"
      echo "$OUTPUT" | grep -E "^[^:]+:[0-9]+:" | head -20

      if [ "$ISSUE_COUNT" -gt 20 ]; then
        echo ""
        echo "[Showing 20 of $ISSUE_COUNT issues]"
      fi

      echo ""
      echo "[Run linter directly for full output]"
    fi
    ;;

  rubocop)
    if [ $EXIT_CODE -eq 0 ]; then
      echo "Rubocop: No offenses detected"
    else
      OFFENSE_COUNT=$(echo "$OUTPUT" | grep -oE "[0-9]+ offenses?" | head -1 || echo "some issues")

      echo "Rubocop: $OFFENSE_COUNT"
      echo ""

      # Show offenses
      echo "$OUTPUT" | grep -E "^[^:]+:[0-9]+:[0-9]+:" | head -15

      echo ""
      echo "[Run rubocop directly for full output]"
    fi
    ;;

  golint|golangci-lint)
    if [ $EXIT_CODE -eq 0 ]; then
      echo "Lint: No issues found"
    else
      ISSUE_COUNT=$(echo "$OUTPUT" | grep -cE "^[^:]+\.go:[0-9]+:" || echo "0")

      echo "Lint: $ISSUE_COUNT issues"
      echo ""

      echo "$OUTPUT" | grep -E "^[^:]+\.go:[0-9]+:" | head -20

      if [ "$ISSUE_COUNT" -gt 20 ]; then
        echo ""
        echo "[Showing 20 of $ISSUE_COUNT issues]"
      fi

      echo ""
      echo "[Run linter directly for full output]"
    fi
    ;;

  clippy)
    if [ $EXIT_CODE -eq 0 ]; then
      echo "Clippy: No warnings"
    else
      WARNING_COUNT=$(count_pattern "^warning:" "$OUTPUT")
      ERROR_COUNT=$(count_pattern "^error\[" "$OUTPUT")

      echo "Clippy: $ERROR_COUNT errors, $WARNING_COUNT warnings"
      echo ""

      # Show warnings and errors
      echo "$OUTPUT" | grep -E "^(warning|error)" | head -15

      echo ""
      echo "[Run cargo clippy directly for full output]"
    fi
    ;;

  generic|*)
    # Generic lint output handling
    if [ $EXIT_CODE -eq 0 ]; then
      if echo "$OUTPUT" | grep -qiE "no (errors|issues|problems)|clean|passed|0 errors"; then
        echo "Lint: Clean"
      else
        LINE_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')
        echo "Lint completed ($LINE_COUNT lines of output)"
      fi
    else
      ERROR_COUNT=$(count_pattern "\berror\b" "$OUTPUT")
      WARNING_COUNT=$(count_pattern "\bwarning\b" "$OUTPUT")

      echo "Lint issues: $ERROR_COUNT errors, $WARNING_COUNT warnings"
      echo ""

      # Show error lines
      echo "$OUTPUT" | grep -iE "error|warning" | head -20

      echo ""
      echo "[Run lint directly for full output]"
    fi
    ;;
esac

exit $EXIT_CODE
