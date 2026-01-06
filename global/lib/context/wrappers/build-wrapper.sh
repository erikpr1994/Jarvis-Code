#!/bin/bash
# build-wrapper.sh - Build command wrapper with compressed output
#
# Detects and wraps various build tools (vite, webpack, turbo, next, etc.)
# Shows only errors/warnings, summarizes build stats, truncates verbose output.
#
# Usage:
#   ./build-wrapper.sh pnpm build
#   ./build-wrapper.sh npm run build
#   ./build-wrapper.sh npx vite build
#   ./build-wrapper.sh npx turbo build
#   ./build-wrapper.sh cargo build
#   echo "$output" | ./build-wrapper.sh --stdin
#
# Environment:
#   VERBOSE_OUTPUT=1           Show full output without compression
#   BUILD_WRAPPER_MAX_ERRORS=5 Maximum errors to show (default: 5)
#
# Exit codes are preserved from the underlying build command.

set -e

# Configuration
MAX_ERRORS=${BUILD_WRAPPER_MAX_ERRORS:-5}

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
  if echo "$OUTPUT" | grep -qiE "error|Error|failed|FAILED"; then
    EXIT_CODE=1
  fi
  COMMAND="<stdin>"
else
  # No command provided
  if [ $# -eq 0 ]; then
    echo "Usage: build-wrapper.sh <build-command> [args...]"
    echo "       echo \"output\" | build-wrapper.sh --stdin"
    echo ""
    echo "Examples:"
    echo "  build-wrapper.sh pnpm build"
    echo "  build-wrapper.sh npx vite build"
    echo "  build-wrapper.sh cargo build --release"
    exit 1
  fi

  # Run the build command and capture output
  COMMAND="$*"
  OUTPUT=$("$@" 2>&1) || true
  EXIT_CODE=$?
fi

# Detect build tool from command and output
detect_builder() {
  local cmd="$1"
  local out="$2"

  # Check command first
  if echo "$cmd" | grep -qiE "\bvite\b"; then
    echo "vite"
  elif echo "$cmd" | grep -qiE "\bwebpack\b"; then
    echo "webpack"
  elif echo "$cmd" | grep -qiE "\bturbo\b|turbopack"; then
    echo "turbo"
  elif echo "$cmd" | grep -qiE "\bnext\b"; then
    echo "next"
  elif echo "$cmd" | grep -qiE "\besbuild\b"; then
    echo "esbuild"
  elif echo "$cmd" | grep -qiE "\brollup\b"; then
    echo "rollup"
  elif echo "$cmd" | grep -qiE "\bparcel\b"; then
    echo "parcel"
  elif echo "$cmd" | grep -qiE "\bcargo build\b"; then
    echo "cargo"
  elif echo "$cmd" | grep -qiE "\bgo build\b"; then
    echo "go"
  elif echo "$cmd" | grep -qiE "\bgcc\b|\bg\+\+\b|\bclang\b"; then
    echo "c"
  elif echo "$cmd" | grep -qiE "\bdocker build\b"; then
    echo "docker"
  elif echo "$cmd" | grep -qiE "\bgradle\b"; then
    echo "gradle"
  elif echo "$cmd" | grep -qiE "\bmaven\b|\bmvn\b"; then
    echo "maven"
  # Check output patterns
  elif echo "$out" | grep -qE "vite v|VITE"; then
    echo "vite"
  elif echo "$out" | grep -qE "webpack.*compiled|asset.*\.js"; then
    echo "webpack"
  elif echo "$out" | grep -qE "turbo|Tasks:.*successful"; then
    echo "turbo"
  elif echo "$out" | grep -qE "next.*build|Creating an optimized"; then
    echo "next"
  elif echo "$out" | grep -qE "Compiling\.\.\.|Finished.*release"; then
    echo "cargo"
  else
    echo "generic"
  fi
}

BUILDER=$(detect_builder "$COMMAND" "$OUTPUT")

# Helper to extract build timing
extract_time() {
  local out="$1"
  # Try various time formats
  echo "$out" | grep -oE "([0-9.]+\s*(ms|s|seconds?|minutes?))" | tail -1 || \
  echo "$out" | grep -oE "in [0-9.]+s" | tail -1 || \
  echo "$out" | grep -oE "took [0-9.]+s" | tail -1 || \
  echo ""
}

# Helper to extract bundle/output size
extract_size() {
  local out="$1"
  echo "$out" | grep -oE "([0-9.]+\s*(KB|MB|kB|mB|KiB|MiB|bytes))" | tail -1 || echo ""
}

# Parse and compress output based on builder
case "$BUILDER" in
  vite)
    if [ $EXIT_CODE -eq 0 ]; then
      TIME=$(extract_time "$OUTPUT")
      SIZE=$(echo "$OUTPUT" | grep -oE "dist/.*\s+[0-9.]+\s*[kKmM]B" | wc -l | tr -d ' ')

      echo "Build succeeded ${TIME:+($TIME)}"
      [ "$SIZE" -gt 0 ] && echo "Generated $SIZE files"

      # Show bundle summary if available
      if echo "$OUTPUT" | grep -qE "dist/"; then
        echo ""
        echo "Output:"
        echo "$OUTPUT" | grep -E "dist/.*\.(js|css)" | head -5
      fi
    else
      echo "Build failed"
      echo ""

      # Show errors
      echo "Errors:"
      echo "$OUTPUT" | grep -A 3 -E "error|Error|✗" | head -20

      echo ""
      echo "[Run build directly for full output]"
    fi
    ;;

  webpack)
    if [ $EXIT_CODE -eq 0 ]; then
      TIME=$(echo "$OUTPUT" | grep -oE "compiled.*in [0-9.]+ [ms]+" | head -1 || echo "")
      ASSETS=$(echo "$OUTPUT" | grep -c "asset\s" || echo "0")
      WARNINGS=$(echo "$OUTPUT" | grep -c "WARNING" || echo "0")

      echo "Build succeeded: $TIME"
      echo "Generated $ASSETS assets ${WARNINGS:+($WARNINGS warnings)}"

      # Show bundle summary
      if [ "$ASSETS" -gt 0 ]; then
        echo ""
        echo "Bundles:"
        echo "$OUTPUT" | grep -E "asset\s+\S+\.(js|css)" | head -5
      fi
    else
      ERROR_COUNT=$(echo "$OUTPUT" | grep -c "ERROR\|error" || echo "0")

      echo "Build failed: $ERROR_COUNT errors"
      echo ""

      echo "Errors:"
      echo "$OUTPUT" | grep -A 5 "ERROR\|Module build failed" | head -25

      echo ""
      echo "[Run webpack directly for full output]"
    fi
    ;;

  turbo)
    if [ $EXIT_CODE -eq 0 ]; then
      # Turbo summary
      TASKS=$(echo "$OUTPUT" | grep -oE "Tasks:\s+[0-9]+ successful" | head -1 || echo "")
      CACHED=$(echo "$OUTPUT" | grep -oE "[0-9]+ cached" | head -1 || echo "")
      TIME=$(echo "$OUTPUT" | grep -oE "Duration:\s+[0-9.]+[ms]+" | head -1 || echo "")

      echo "Build succeeded: ${TASKS:-all tasks} ${CACHED:+($CACHED)} ${TIME:+$TIME}"
    else
      echo "Build failed"
      echo ""

      # Show which task failed
      echo "$OUTPUT" | grep -E "FAIL|error|Error" | head -10

      echo ""
      echo "[Run turbo build directly for full output]"
    fi
    ;;

  next)
    if [ $EXIT_CODE -eq 0 ]; then
      # Next.js build summary
      PAGES=$(echo "$OUTPUT" | grep -c "^[○●λ]" || echo "0")
      TIME=$(echo "$OUTPUT" | grep -oE "in [0-9.]+s" | tail -1 || echo "")
      SIZE=$(echo "$OUTPUT" | grep -oE "First Load JS.*[0-9.]+ kB" | head -1 || echo "")

      echo "Build succeeded: $PAGES routes ${TIME:+$TIME}"
      [ -n "$SIZE" ] && echo "$SIZE"
    else
      echo "Build failed"
      echo ""

      # Show build errors
      echo "Errors:"
      echo "$OUTPUT" | grep -A 5 "Error:\|error\|Failed to compile" | head -25

      echo ""
      echo "[Run next build directly for full output]"
    fi
    ;;

  esbuild)
    if [ $EXIT_CODE -eq 0 ]; then
      TIME=$(extract_time "$OUTPUT")
      FILES=$(echo "$OUTPUT" | grep -c "\.js\|\.css" || echo "0")

      echo "Build succeeded ${TIME:+($TIME)} - $FILES files generated"
    else
      echo "Build failed"
      echo ""

      echo "$OUTPUT" | grep -E "✘|error" | head -10

      echo ""
      echo "[Run esbuild directly for full output]"
    fi
    ;;

  rollup)
    if [ $EXIT_CODE -eq 0 ]; then
      BUNDLES=$(echo "$OUTPUT" | grep -c "created\|→" || echo "0")
      TIME=$(extract_time "$OUTPUT")

      echo "Build succeeded: $BUNDLES bundles ${TIME:+($TIME)}"

      # Show generated files
      echo "$OUTPUT" | grep -E "→|created" | head -5
    else
      echo "Build failed"
      echo ""

      echo "$OUTPUT" | grep -E "Error:|error\[" | head -10

      echo ""
      echo "[Run rollup directly for full output]"
    fi
    ;;

  cargo)
    if [ $EXIT_CODE -eq 0 ]; then
      # Check if release build
      if echo "$COMMAND$OUTPUT" | grep -q "release"; then
        MODE="release"
      else
        MODE="debug"
      fi

      TIME=$(echo "$OUTPUT" | grep -oE "Finished.*in [0-9.]+s" | head -1 || echo "")
      WARNINGS=$(echo "$OUTPUT" | grep -c "^warning:" || echo "0")

      echo "Build succeeded ($MODE) ${TIME:+$TIME}"
      [ "$WARNINGS" -gt 0 ] && echo "$WARNINGS warnings"
    else
      ERROR_COUNT=$(echo "$OUTPUT" | grep -c "^error\[" || echo "0")

      echo "Build failed: $ERROR_COUNT errors"
      echo ""

      echo "Errors:"
      echo "$OUTPUT" | grep -A 3 "^error\[" | head -25

      echo ""
      echo "[Run cargo build directly for full output]"
    fi
    ;;

  go)
    if [ $EXIT_CODE -eq 0 ]; then
      echo "Build succeeded"

      # Show output binary if mentioned
      echo "$OUTPUT" | grep -E "^[^:]+$" | head -3
    else
      echo "Build failed"
      echo ""

      echo "$OUTPUT" | grep -E "^#|error:" | head -15

      echo ""
      echo "[Run go build directly for full output]"
    fi
    ;;

  docker)
    if [ $EXIT_CODE -eq 0 ]; then
      IMAGE=$(echo "$OUTPUT" | grep -oE "naming to docker\.io/[^ ]+" | head -1 || echo "")
      LAYERS=$(echo "$OUTPUT" | grep -c "^#[0-9]" || echo "0")

      echo "Build succeeded: $LAYERS steps"
      [ -n "$IMAGE" ] && echo "Image: $IMAGE"
    else
      echo "Build failed"
      echo ""

      echo "$OUTPUT" | grep -E "^#[0-9]+.*ERROR|error:|Error:" | head -10

      echo ""
      echo "[Run docker build directly for full output]"
    fi
    ;;

  gradle)
    if [ $EXIT_CODE -eq 0 ]; then
      TIME=$(echo "$OUTPUT" | grep -oE "BUILD SUCCESSFUL in [0-9]+[ms]+" | head -1 || echo "")
      echo "Build succeeded ${TIME:+$TIME}"
    else
      FAILED=$(echo "$OUTPUT" | grep -oE "[0-9]+ actionable task.*failed" | head -1 || echo "")
      echo "Build failed ${FAILED:+($FAILED)}"
      echo ""

      echo "$OUTPUT" | grep -A 5 "FAILURE:\|error:" | head -20

      echo ""
      echo "[Run gradle build directly for full output]"
    fi
    ;;

  maven)
    if [ $EXIT_CODE -eq 0 ]; then
      TIME=$(echo "$OUTPUT" | grep -oE "Total time:.*" | head -1 || echo "")
      echo "Build succeeded ${TIME:+($TIME)}"
    else
      echo "Build failed"
      echo ""

      echo "$OUTPUT" | grep -A 3 "\[ERROR\]" | head -20

      echo ""
      echo "[Run mvn directly for full output]"
    fi
    ;;

  generic|*)
    # Generic build output handling
    if [ $EXIT_CODE -eq 0 ]; then
      TIME=$(extract_time "$OUTPUT")
      SIZE=$(extract_size "$OUTPUT")
      LINE_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')

      echo "Build succeeded ${TIME:+($TIME)} ${SIZE:+- $SIZE}"
      if [ "$LINE_COUNT" -gt 5 ]; then
        echo "($LINE_COUNT lines of output)"
      fi
    else
      ERROR_COUNT=$(echo "$OUTPUT" | grep -ciE "error" || echo "0")

      echo "Build failed: $ERROR_COUNT errors"
      echo ""

      # Show error lines
      echo "Errors:"
      echo "$OUTPUT" | grep -iE "error|fail" | head -15

      # Show context
      echo "$OUTPUT" | grep -B 2 -A 3 -iE "error" | head -25

      echo ""
      echo "[Run build directly for full output]"
    fi
    ;;
esac

exit $EXIT_CODE
