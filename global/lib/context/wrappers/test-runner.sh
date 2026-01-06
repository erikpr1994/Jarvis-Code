#!/bin/bash
# test-runner.sh - Test runner wrapper with compressed output
#
# Reduces token usage from verbose test outputs while preserving
# essential information about test results.
#
# Usage:
#   ./test-runner.sh npm test
#   ./test-runner.sh pnpm test
#   ./test-runner.sh yarn test
#   ./test-runner.sh npx vitest
#   ./test-runner.sh npx jest
#   ./test-runner.sh pytest
#   ./test-runner.sh go test ./...
#
# Environment:
#   TEST_WRAPPER_VERBOSE=1   Show full output
#   TEST_WRAPPER_MAX_ERRORS=5  Max errors to show (default: 5)

set -e

# Configuration
MAX_ERRORS=${TEST_WRAPPER_MAX_ERRORS:-5}

# Pass through if verbose mode requested
if [ "${TEST_WRAPPER_VERBOSE:-0}" = "1" ]; then
  exec "$@"
fi

# No command provided
if [ $# -eq 0 ]; then
  echo "Usage: test-runner.sh <test-command> [args...]"
  echo "Example: test-runner.sh npm test"
  exit 1
fi

# Run the test command and capture output
OUTPUT=$("$@" 2>&1) || true
EXIT_CODE=$?

# Detect test framework from command and output
detect_framework() {
  local cmd="$1"
  local out="$2"

  if echo "$cmd" | grep -qE "vitest"; then
    echo "vitest"
  elif echo "$cmd" | grep -qE "jest"; then
    echo "jest"
  elif echo "$cmd" | grep -qE "pytest|python.*-m.*pytest"; then
    echo "pytest"
  elif echo "$cmd" | grep -qE "go test"; then
    echo "go"
  elif echo "$cmd" | grep -qE "cargo test"; then
    echo "cargo"
  elif echo "$out" | grep -qE "vitest"; then
    echo "vitest"
  elif echo "$out" | grep -qE "jest"; then
    echo "jest"
  elif echo "$out" | grep -qE "pytest|passed|failed.*second"; then
    echo "pytest"
  else
    echo "generic"
  fi
}

FRAMEWORK=$(detect_framework "$*" "$OUTPUT")

# Parse and compress output based on framework
case "$FRAMEWORK" in
  vitest|jest)
    if [ $EXIT_CODE -eq 0 ]; then
      # Success - extract summary
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "all")
      TIME=$(echo "$OUTPUT" | grep -oE "Time:?\s*[0-9.]+\s*[ms]+" | head -1 || echo "")
      SUITES=$(echo "$OUTPUT" | grep -oE "[0-9]+ (test )?suites?" | head -1 || echo "")

      echo "All tests passed: $PASSED ${SUITES:+in $SUITES }${TIME:+($TIME)}"
    else
      # Failure - extract relevant info
      FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failed" | head -1 || echo "some")
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "0")

      echo "Test failures: $FAILED failed, $PASSED passed"
      echo ""

      # Show failed test names and assertions
      echo "Failed tests:"
      echo "$OUTPUT" | grep -E "^.*FAIL.*|✕|✗" | head -$MAX_ERRORS
      echo ""

      # Show assertion errors
      echo "Errors:"
      echo "$OUTPUT" | grep -A 5 "Expected\|Received\|AssertionError\|Error:" | head -25

      TOTAL_FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1 || echo "0")
      if [ "$TOTAL_FAILED" -gt "$MAX_ERRORS" ]; then
        echo ""
        echo "[Showing first $MAX_ERRORS of $TOTAL_FAILED failures]"
      fi
      echo ""
      echo "[Run tests directly for full output]"
    fi
    ;;

  pytest)
    if [ $EXIT_CODE -eq 0 ]; then
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "all")
      TIME=$(echo "$OUTPUT" | grep -oE "in [0-9.]+s" | head -1 || echo "")
      echo "All tests passed: $PASSED $TIME"
    else
      FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ failed" | head -1 || echo "some")
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "0")

      echo "Test failures: $FAILED failed, $PASSED passed"
      echo ""

      # Show failed test info
      echo "$OUTPUT" | grep -E "^FAILED|^E\s+|AssertionError" | head -20
      echo ""
      echo "[Run pytest directly for full output]"
    fi
    ;;

  go)
    if [ $EXIT_CODE -eq 0 ]; then
      PASSED=$(echo "$OUTPUT" | grep -c "^ok\|PASS" || echo "all")
      TIME=$(echo "$OUTPUT" | grep -oE "[0-9.]+s" | tail -1 || echo "")
      echo "All tests passed: $PASSED packages $TIME"
    else
      echo "Test failures detected:"
      echo ""
      # Show failing tests
      echo "$OUTPUT" | grep -E "^---.*FAIL|^FAIL|panic:|Error" | head -15
      echo ""
      # Show error details
      echo "$OUTPUT" | grep -A 3 "got:\|want:\|expected\|actual" | head -20
      echo ""
      echo "[Run go test directly for full output]"
    fi
    ;;

  cargo)
    if [ $EXIT_CODE -eq 0 ]; then
      PASSED=$(echo "$OUTPUT" | grep -oE "[0-9]+ passed" | head -1 || echo "all")
      echo "All tests passed: $PASSED"
    else
      echo "Test failures detected:"
      echo ""
      echo "$OUTPUT" | grep -E "^---- |^thread.*panicked|^failures:" -A 5 | head -25
      echo ""
      echo "[Run cargo test directly for full output]"
    fi
    ;;

  generic|*)
    # Generic test output handling
    if [ $EXIT_CODE -eq 0 ]; then
      # Look for common success patterns
      if echo "$OUTPUT" | grep -qE "passed|success|ok|PASS"; then
        SUMMARY=$(echo "$OUTPUT" | grep -E "passed|success|ok|PASS|total" | tail -3)
        echo "Tests passed:"
        echo "$SUMMARY"
      else
        # Just show we succeeded
        LINE_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')
        echo "Tests completed successfully ($LINE_COUNT lines of output)"
      fi
    else
      echo "Tests failed (exit code: $EXIT_CODE):"
      echo ""
      # Show error-related lines
      echo "$OUTPUT" | grep -E -i "error|fail|assert|exception|panic" | head -15
      echo ""
      # Show context around errors
      echo "$OUTPUT" | grep -B 2 -A 3 -E -i "error|fail" | head -25
      echo ""
      echo "[Run tests directly for full output]"
    fi
    ;;
esac

exit $EXIT_CODE
