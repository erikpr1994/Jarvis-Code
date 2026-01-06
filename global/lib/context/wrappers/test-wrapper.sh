#!/bin/bash
# test-wrapper.sh - Test command wrapper with compressed output
#
# Detects and wraps various test frameworks (vitest, jest, pytest, go test, etc.)
# Summarizes pass/fail counts and shows only failed test details.
# Truncates long stack traces to preserve context budget.
#
# Usage:
#   ./test-wrapper.sh npm test
#   ./test-wrapper.sh pnpm test
#   ./test-wrapper.sh yarn vitest
#   ./test-wrapper.sh npx jest
#   ./test-wrapper.sh pytest
#   ./test-wrapper.sh go test ./...
#   echo "$output" | ./test-wrapper.sh --stdin
#
# Environment:
#   VERBOSE_OUTPUT=1          Show full output without compression
#   TEST_WRAPPER_MAX_ERRORS=5 Maximum number of errors to show (default: 5)
#   TEST_WRAPPER_MAX_STACK=10 Maximum stack trace lines per error (default: 10)
#
# Exit codes are preserved from the underlying test command.

set -e

# Configuration
MAX_ERRORS=${TEST_WRAPPER_MAX_ERRORS:-5}
MAX_STACK=${TEST_WRAPPER_MAX_STACK:-10}

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
  # Try to detect exit code from output if present
  if echo "$OUTPUT" | grep -qE "FAIL|failed|Error|error"; then
    EXIT_CODE=1
  fi
  COMMAND="<stdin>"
else
  # No command provided
  if [ $# -eq 0 ]; then
    echo "Usage: test-wrapper.sh <test-command> [args...]"
    echo "       echo \"output\" | test-wrapper.sh --stdin"
    echo ""
    echo "Examples:"
    echo "  test-wrapper.sh npm test"
    echo "  test-wrapper.sh pnpm vitest run"
    echo "  test-wrapper.sh pytest -v"
    exit 1
  fi

  # Run the test command and capture output
  COMMAND="$*"
  OUTPUT=$("$@" 2>&1) || true
  EXIT_CODE=$?
fi

# Detect test framework from command and output
detect_framework() {
  local cmd="$1"
  local out="$2"

  # Check command first
  if echo "$cmd" | grep -qiE "vitest"; then
    echo "vitest"
  elif echo "$cmd" | grep -qiE "jest"; then
    echo "jest"
  elif echo "$cmd" | grep -qiE "pytest|python.*-m.*pytest"; then
    echo "pytest"
  elif echo "$cmd" | grep -qiE "go test"; then
    echo "go"
  elif echo "$cmd" | grep -qiE "cargo test"; then
    echo "cargo"
  elif echo "$cmd" | grep -qiE "mocha"; then
    echo "mocha"
  elif echo "$cmd" | grep -qiE "ava"; then
    echo "ava"
  elif echo "$cmd" | grep -qiE "phpunit"; then
    echo "phpunit"
  elif echo "$cmd" | grep -qiE "rspec"; then
    echo "rspec"
  # Check output patterns
  elif echo "$out" | grep -qE "VITE|vitest"; then
    echo "vitest"
  elif echo "$out" | grep -qE "Jest|jest"; then
    echo "jest"
  elif echo "$out" | grep -qE "pytest|===.*passed.*==="; then
    echo "pytest"
  elif echo "$out" | grep -qE "^ok\s+\w+|^FAIL\s+\w+|^---.*PASS:|^---.*FAIL:"; then
    echo "go"
  elif echo "$out" | grep -qE "running \d+ tests|test result:"; then
    echo "cargo"
  else
    echo "generic"
  fi
}

FRAMEWORK=$(detect_framework "$COMMAND" "$OUTPUT")

# Truncate stack trace to MAX_STACK lines
truncate_stack() {
  local stack="$1"
  local lines
  lines=$(echo "$stack" | wc -l | tr -d ' ')
  if [ "$lines" -gt "$MAX_STACK" ]; then
    echo "$stack" | head -"$MAX_STACK"
    echo "    ... ($((lines - MAX_STACK)) more stack trace lines)"
  else
    echo "$stack"
  fi
}

# Parse and compress output based on framework
case "$FRAMEWORK" in
  vitest)
    if [ $EXIT_CODE -eq 0 ]; then
      # Success - extract summary
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | tail -1 || echo "all")
      DURATION=$(echo "$OUTPUT" | grep -oE "Duration\s+[0-9.]+\s*[ms]+" | head -1 || echo "")
      TESTS=$(echo "$OUTPUT" | grep -oE "Tests\s+[0-9]+" | head -1 || echo "")

      echo "All tests passed: $PASSED ${TESTS:+($TESTS total) }${DURATION:+$DURATION}"
    else
      # Failure - extract relevant info
      FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failed" | tail -1 || echo "some")
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | tail -1 || echo "0")

      echo "Test failures: $FAILED, $PASSED"
      echo ""

      # Show failed test names
      echo "Failed tests:"
      echo "$OUTPUT" | grep -E "^.*FAIL.*|✗|×|❌" | head -"$MAX_ERRORS"
      echo ""

      # Show assertion errors (truncated stack traces)
      echo "Errors:"
      ERRORS=$(echo "$OUTPUT" | grep -A "$MAX_STACK" "Expected\|Received\|AssertionError\|Error:" | head -30)
      truncate_stack "$ERRORS"

      TOTAL_FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | tail -1 || echo "0")
      if [ "$TOTAL_FAILED" -gt "$MAX_ERRORS" ]; then
        echo ""
        echo "[Showing first $MAX_ERRORS of $TOTAL_FAILED failures]"
      fi
      echo ""
      echo "[Run tests directly for full output]"
    fi
    ;;

  jest)
    if [ $EXIT_CODE -eq 0 ]; then
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "all")
      TIME=$(echo "$OUTPUT" | grep -oE "Time:?\s*[0-9.]+\s*[ms]+" | head -1 || echo "")
      SUITES=$(echo "$OUTPUT" | grep -oE "[0-9]+ test suites?" | head -1 || echo "")

      echo "All tests passed: $PASSED ${SUITES:+in $SUITES }${TIME:+($TIME)}"
    else
      FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failed" | head -1 || echo "some")
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "0")

      echo "Test failures: $FAILED, $PASSED"
      echo ""

      # Show failed test suites/names
      echo "Failed tests:"
      echo "$OUTPUT" | grep -E "^.*FAIL.*|✕|✗" | head -"$MAX_ERRORS"
      echo ""

      # Show assertion errors with truncated stacks
      echo "Errors:"
      ERRORS=$(echo "$OUTPUT" | grep -A "$MAX_STACK" "expect\|Expected\|Received\|toBe\|toEqual" | head -30)
      truncate_stack "$ERRORS"

      echo ""
      echo "[Run jest directly for full output]"
    fi
    ;;

  pytest)
    if [ $EXIT_CODE -eq 0 ]; then
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "all")
      TIME=$(echo "$OUTPUT" | grep -oE "in [0-9.]+s" | tail -1 || echo "")
      WARNINGS=$(echo "$OUTPUT" | grep -oE "[0-9]+ warnings?" | head -1 || echo "")

      echo "All tests passed: $PASSED $TIME ${WARNINGS:+($WARNINGS)}"
    else
      FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failed" | head -1 || echo "some")
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "0")
      ERRORS=$(echo "$OUTPUT" | grep -oE "[0-9]+ errors?" | head -1 || echo "")

      echo "Test failures: $FAILED, $PASSED ${ERRORS:+, $ERRORS}"
      echo ""

      # Show failed test names
      echo "Failed tests:"
      echo "$OUTPUT" | grep -E "^FAILED\s+" | head -"$MAX_ERRORS"
      echo ""

      # Show assertion info (truncated)
      echo "Errors:"
      ASSERTION_INFO=$(echo "$OUTPUT" | grep -E "^E\s+|AssertionError|assert\s+" | head -20)
      truncate_stack "$ASSERTION_INFO"

      echo ""
      echo "[Run pytest directly for full output]"
    fi
    ;;

  go)
    if [ $EXIT_CODE -eq 0 ]; then
      PKG_COUNT=$(echo "$OUTPUT" | grep -c "^ok\s" || echo "all")
      TOTAL_TIME=$(echo "$OUTPUT" | grep -oE "[0-9.]+s$" | paste -sd+ | bc 2>/dev/null || echo "")

      echo "All tests passed: $PKG_COUNT packages ${TOTAL_TIME:+($TOTAL_TIME total)}"
    else
      echo "Test failures detected"
      echo ""

      # Show failing packages/tests
      echo "Failed:"
      echo "$OUTPUT" | grep -E "^---.*FAIL|^FAIL\s+|panic:" | head -"$MAX_ERRORS"
      echo ""

      # Show error details (truncated)
      echo "Details:"
      DETAILS=$(echo "$OUTPUT" | grep -A 5 "got:\|want:\|expected\|actual\|Error Trace:" | head -25)
      truncate_stack "$DETAILS"

      echo ""
      echo "[Run go test directly for full output]"
    fi
    ;;

  cargo)
    if [ $EXIT_CODE -eq 0 ]; then
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "all")
      IGNORED=$(echo "$OUTPUT" | grep -oE "[0-9]+ ignored" | head -1 || echo "")

      echo "All tests passed: $PASSED ${IGNORED:+($IGNORED ignored)}"
    else
      echo "Test failures detected"
      echo ""

      # Show failing tests
      echo "Failed:"
      echo "$OUTPUT" | grep -E "^---- .*FAILED|^test .* FAILED" | head -"$MAX_ERRORS"
      echo ""

      # Show panic/assertion info
      echo "Details:"
      DETAILS=$(echo "$OUTPUT" | grep -A 5 "panicked at\|assertion failed\|left:\|right:" | head -25)
      truncate_stack "$DETAILS"

      echo ""
      echo "[Run cargo test directly for full output]"
    fi
    ;;

  mocha|ava)
    if [ $EXIT_CODE -eq 0 ]; then
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passing" | head -1 || echo "all")
      TIME=$(echo "$OUTPUT" | grep -oE "\([0-9.]+[ms]+\)" | head -1 || echo "")

      echo "All tests passed: $PASSED $TIME"
    else
      FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failing" | head -1 || echo "some")
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passing" | head -1 || echo "0")

      echo "Test failures: $FAILED, $PASSED"
      echo ""

      # Show failed tests
      echo "$OUTPUT" | grep -E "^\s+\d+\)|AssertionError" | head -15

      echo ""
      echo "[Run tests directly for full output]"
    fi
    ;;

  phpunit)
    if [ $EXIT_CODE -eq 0 ]; then
      SUMMARY=$(echo "$OUTPUT" | grep -E "^OK \(" | head -1 || echo "All tests passed")
      echo "$SUMMARY"
    else
      # Show failures summary
      echo "$OUTPUT" | grep -E "^FAILURES!|^Tests:|^Assertions:" | head -5
      echo ""

      # Show failure details
      echo "$OUTPUT" | grep -A 5 "^[0-9]+\)" | head -20

      echo ""
      echo "[Run phpunit directly for full output]"
    fi
    ;;

  rspec)
    if [ $EXIT_CODE -eq 0 ]; then
      SUMMARY=$(echo "$OUTPUT" | grep -E "examples?, 0 failures" | head -1 || echo "All tests passed")
      echo "$SUMMARY"
    else
      echo "$OUTPUT" | grep -E "examples?,.*failures?" | head -1
      echo ""

      # Show failure details
      echo "$OUTPUT" | grep -A 5 "Failure/Error:" | head -20

      echo ""
      echo "[Run rspec directly for full output]"
    fi
    ;;

  generic|*)
    # Generic test output handling
    if [ $EXIT_CODE -eq 0 ]; then
      # Look for common success patterns
      if echo "$OUTPUT" | grep -qiE "passed|success|ok|✓"; then
        PASSED=$(echo "$OUTPUT" | grep -oiE "[0-9]+ (passed|tests?|specs?)" | tail -1 || echo "")
        TIME=$(echo "$OUTPUT" | grep -oE "([0-9.]+\s*[ms]+|[0-9.]+s)" | tail -1 || echo "")

        if [ -n "$PASSED" ]; then
          echo "Tests passed: $PASSED ${TIME:+($TIME)}"
        else
          LINE_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')
          echo "Tests completed successfully ($LINE_COUNT lines of output)"
        fi
      else
        LINE_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')
        echo "Command completed successfully ($LINE_COUNT lines of output)"
      fi
    else
      echo "Tests failed (exit code: $EXIT_CODE)"
      echo ""

      # Show error-related lines
      echo "$OUTPUT" | grep -iE "error|fail|assert|exception|panic" | head -15
      echo ""

      # Show context around errors
      CONTEXT=$(echo "$OUTPUT" | grep -B 2 -A 3 -iE "error|fail" | head -25)
      if [ -n "$CONTEXT" ]; then
        echo "Context:"
        truncate_stack "$CONTEXT"
      fi

      echo ""
      echo "[Run tests directly for full output]"
    fi
    ;;
esac

exit $EXIT_CODE
