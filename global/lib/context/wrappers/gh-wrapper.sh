#!/bin/bash
# gh-wrapper.sh - GitHub CLI wrapper with compressed output
#
# Reduces token usage from verbose gh command outputs while preserving
# essential information for Claude Code sessions.
#
# Usage:
#   ./gh-wrapper.sh pr list
#   ./gh-wrapper.sh issue list
#   ./gh-wrapper.sh pr view 123
#   ./gh-wrapper.sh run list
#
# Environment:
#   GH_WRAPPER_VERBOSE=1  Show full output instead of compressed

set -e

# Check if gh is available
if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) not found. Install from https://cli.github.com"
  exit 1
fi

# Pass through if verbose mode requested
if [ "${GH_WRAPPER_VERBOSE:-0}" = "1" ]; then
  exec gh "$@"
fi

# Get the subcommand
SUBCOMMAND="${1:-}"
ACTION="${2:-}"

# Run the command and capture output
OUTPUT=$(gh "$@" 2>&1)
EXIT_CODE=$?

# If command failed, show error concisely
if [ $EXIT_CODE -ne 0 ]; then
  echo "gh $* failed:"
  echo "$OUTPUT" | head -5
  exit $EXIT_CODE
fi

# Compress output based on command type
case "$SUBCOMMAND" in
  pr)
    case "$ACTION" in
      list)
        # Count PRs and show summary
        PR_COUNT=$(echo "$OUTPUT" | grep -c "^#\|^[0-9]" || echo "0")
        if [ "$PR_COUNT" = "0" ]; then
          echo "No open pull requests"
        else
          echo "Pull Requests ($PR_COUNT):"
          echo ""
          # Show compact format: number, title, author, status
          echo "$OUTPUT" | head -20
          if [ "$PR_COUNT" -gt 20 ]; then
            echo ""
            echo "[... and $((PR_COUNT - 20)) more PRs]"
          fi
        fi
        ;;
      view)
        # Extract key PR info
        TITLE=$(echo "$OUTPUT" | grep -E "^title:" | head -1 || echo "$OUTPUT" | head -1)
        STATE=$(echo "$OUTPUT" | grep -E "^state:" | head -1 || echo "")
        AUTHOR=$(echo "$OUTPUT" | grep -E "^author:" | head -1 || echo "")
        CHECKS=$(echo "$OUTPUT" | grep -E "checks:|CI" | head -1 || echo "")

        echo "PR: $TITLE"
        [ -n "$STATE" ] && echo "$STATE"
        [ -n "$AUTHOR" ] && echo "$AUTHOR"
        [ -n "$CHECKS" ] && echo "$CHECKS"
        echo ""
        # Show body (truncated)
        echo "$OUTPUT" | grep -A 20 "^--$\|^body:" | head -25
        ;;
      checks)
        # Summarize CI checks
        PASSED=$(echo "$OUTPUT" | grep -c "pass\|success\|✓" || echo "0")
        FAILED=$(echo "$OUTPUT" | grep -c "fail\|error\|✗" || echo "0")
        PENDING=$(echo "$OUTPUT" | grep -c "pending\|running\|○" || echo "0")

        if [ "$FAILED" = "0" ] && [ "$PENDING" = "0" ]; then
          echo "All $PASSED checks passed"
        elif [ "$FAILED" = "0" ]; then
          echo "Checks: $PASSED passed, $PENDING pending"
        else
          echo "Checks: $PASSED passed, $FAILED failed, $PENDING pending"
          echo ""
          echo "Failed checks:"
          echo "$OUTPUT" | grep -E "fail|error|✗" | head -10
        fi
        ;;
      *)
        # Default: show first 30 lines
        echo "$OUTPUT" | head -30
        TOTAL_LINES=$(echo "$OUTPUT" | wc -l | tr -d ' ')
        if [ "$TOTAL_LINES" -gt 30 ]; then
          echo "[... $((TOTAL_LINES - 30)) more lines]"
        fi
        ;;
    esac
    ;;

  issue)
    case "$ACTION" in
      list)
        ISSUE_COUNT=$(echo "$OUTPUT" | grep -c "^#\|^[0-9]" || echo "0")
        if [ "$ISSUE_COUNT" = "0" ]; then
          echo "No open issues"
        else
          echo "Issues ($ISSUE_COUNT):"
          echo ""
          echo "$OUTPUT" | head -20
          if [ "$ISSUE_COUNT" -gt 20 ]; then
            echo ""
            echo "[... and $((ISSUE_COUNT - 20)) more issues]"
          fi
        fi
        ;;
      view)
        # Similar to PR view
        echo "$OUTPUT" | head -40
        TOTAL_LINES=$(echo "$OUTPUT" | wc -l | tr -d ' ')
        if [ "$TOTAL_LINES" -gt 40 ]; then
          echo "[... $((TOTAL_LINES - 40)) more lines]"
        fi
        ;;
      *)
        echo "$OUTPUT" | head -30
        ;;
    esac
    ;;

  run)
    case "$ACTION" in
      list)
        # Summarize workflow runs
        RUN_COUNT=$(echo "$OUTPUT" | grep -c "completed\|in_progress\|queued" || echo "0")
        SUCCESS=$(echo "$OUTPUT" | grep -c "success\|completed" || echo "0")
        FAILED=$(echo "$OUTPUT" | grep -c "failure\|failed" || echo "0")

        echo "Workflow Runs: $RUN_COUNT total ($SUCCESS success, $FAILED failed)"
        echo ""
        # Show recent runs
        echo "$OUTPUT" | head -15
        ;;
      view)
        # Show run summary
        STATUS=$(echo "$OUTPUT" | grep -E "^status:|^conclusion:" | head -2)
        echo "$STATUS"
        echo ""
        # Show job summaries
        echo "$OUTPUT" | grep -E "^[✓✗○]|completed|failed|running" | head -20
        ;;
      *)
        echo "$OUTPUT" | head -30
        ;;
    esac
    ;;

  repo)
    case "$ACTION" in
      list)
        REPO_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')
        echo "Repositories ($REPO_COUNT):"
        echo ""
        echo "$OUTPUT" | head -20
        if [ "$REPO_COUNT" -gt 20 ]; then
          echo "[... and $((REPO_COUNT - 20)) more repos]"
        fi
        ;;
      *)
        echo "$OUTPUT" | head -30
        ;;
    esac
    ;;

  api)
    # API calls can be very verbose - limit output
    TOTAL_LINES=$(echo "$OUTPUT" | wc -l | tr -d ' ')
    if [ "$TOTAL_LINES" -gt 50 ]; then
      echo "$OUTPUT" | head -50
      echo ""
      echo "[API response truncated: $TOTAL_LINES total lines]"
      echo "[Use GH_WRAPPER_VERBOSE=1 for full output]"
    else
      echo "$OUTPUT"
    fi
    ;;

  *)
    # Unknown command - show limited output
    echo "$OUTPUT" | head -40
    TOTAL_LINES=$(echo "$OUTPUT" | wc -l | tr -d ' ')
    if [ "$TOTAL_LINES" -gt 40 ]; then
      echo "[... $((TOTAL_LINES - 40)) more lines]"
    fi
    ;;
esac

exit $EXIT_CODE
