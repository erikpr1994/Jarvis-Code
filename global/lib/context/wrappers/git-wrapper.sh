#!/bin/bash
# git-wrapper.sh - Git command wrapper with compressed output
#
# Summarizes large diffs, truncates long file lists, and shows stats for bulk operations.
# Reduces token usage from verbose git outputs while preserving essential information.
#
# Usage:
#   ./git-wrapper.sh log --oneline -20
#   ./git-wrapper.sh diff
#   ./git-wrapper.sh status
#   ./git-wrapper.sh show HEAD
#   echo "$output" | ./git-wrapper.sh --stdin [subcommand]
#
# Environment:
#   VERBOSE_OUTPUT=1          Show full output without compression
#   GIT_WRAPPER_MAX_FILES=20  Maximum files to show in lists (default: 20)
#   GIT_WRAPPER_MAX_DIFF=50   Maximum diff lines per file (default: 50)
#
# Exit codes are preserved from the underlying git command.

set -e

# Configuration
MAX_FILES=${GIT_WRAPPER_MAX_FILES:-20}
MAX_DIFF_LINES=${GIT_WRAPPER_MAX_DIFF:-50}

# Bypass if verbose mode requested
if [ "${VERBOSE_OUTPUT:-0}" = "1" ]; then
  if [ "$1" = "--stdin" ]; then
    cat
  else
    exec git "$@"
  fi
  exit 0
fi

# Handle stdin mode
if [ "$1" = "--stdin" ]; then
  shift
  SUBCOMMAND="${1:-diff}"
  OUTPUT=$(cat)
  EXIT_CODE=0
  COMMAND="git $SUBCOMMAND <stdin>"
else
  # No command provided
  if [ $# -eq 0 ]; then
    echo "Usage: git-wrapper.sh <git-subcommand> [args...]"
    echo "       echo \"output\" | git-wrapper.sh --stdin [subcommand]"
    echo ""
    echo "Examples:"
    echo "  git-wrapper.sh status"
    echo "  git-wrapper.sh log --oneline -20"
    echo "  git-wrapper.sh diff HEAD~5"
    exit 1
  fi

  # Run the git command and capture output
  SUBCOMMAND="$1"
  COMMAND="git $*"
  OUTPUT=$(git "$@" 2>&1) || true
  EXIT_CODE=$?
fi

# Helper function to count items
count_lines() {
  echo "$1" | wc -l | tr -d ' '
}

# Helper to summarize a diff block
summarize_diff_block() {
  local diff="$1"
  local max_lines="$2"

  local total_lines
  total_lines=$(count_lines "$diff")

  if [ "$total_lines" -le "$max_lines" ]; then
    echo "$diff"
  else
    echo "$diff" | head -"$max_lines"
    echo "    ... ($((total_lines - max_lines)) more lines)"
  fi
}

# Parse and compress output based on git subcommand
case "$SUBCOMMAND" in
  status)
    if [ -z "$OUTPUT" ] || echo "$OUTPUT" | grep -qE "nothing to commit"; then
      echo "Status: Clean working directory"
    else
      # Count changes
      STAGED=$(echo "$OUTPUT" | grep -c "Changes to be committed" || echo "0")
      MODIFIED=$(echo "$OUTPUT" | grep -cE "^\s+modified:" || echo "0")
      UNTRACKED=$(echo "$OUTPUT" | grep -cE "^\s+\S+$" || echo "0")
      DELETED=$(echo "$OUTPUT" | grep -cE "^\s+deleted:" || echo "0")
      NEW=$(echo "$OUTPUT" | grep -cE "^\s+new file:" || echo "0")

      echo "Status: $MODIFIED modified, $NEW new, $DELETED deleted, $UNTRACKED untracked"
      echo ""

      # Show files (limited)
      FILE_LIST=$(echo "$OUTPUT" | grep -E "^\s+(modified|deleted|new file|renamed):" | head -"$MAX_FILES")
      if [ -n "$FILE_LIST" ]; then
        echo "Changed files:"
        echo "$FILE_LIST"

        TOTAL_CHANGED=$((MODIFIED + DELETED + NEW))
        if [ "$TOTAL_CHANGED" -gt "$MAX_FILES" ]; then
          echo "  ... and $((TOTAL_CHANGED - MAX_FILES)) more files"
        fi
      fi

      # Show untracked (limited)
      UNTRACKED_LIST=$(echo "$OUTPUT" | grep -A 100 "Untracked files:" | grep -E "^\s+\S+$" | head -10)
      if [ -n "$UNTRACKED_LIST" ]; then
        echo ""
        echo "Untracked:"
        echo "$UNTRACKED_LIST"
        if [ "$UNTRACKED" -gt 10 ]; then
          echo "  ... and $((UNTRACKED - 10)) more"
        fi
      fi
    fi
    ;;

  diff)
    if [ -z "$OUTPUT" ]; then
      echo "Diff: No changes"
    else
      # Count files and lines changed
      FILES_CHANGED=$(echo "$OUTPUT" | grep -c "^diff --git" || echo "0")
      INSERTIONS=$(echo "$OUTPUT" | grep -c "^+" || echo "0")
      DELETIONS=$(echo "$OUTPUT" | grep -c "^-" || echo "0")
      # Subtract header lines
      INSERTIONS=$((INSERTIONS > 0 ? INSERTIONS - FILES_CHANGED : 0))
      DELETIONS=$((DELETIONS > 0 ? DELETIONS - FILES_CHANGED : 0))

      echo "Diff: $FILES_CHANGED files, +$INSERTIONS/-$DELETIONS lines"
      echo ""

      if [ "$FILES_CHANGED" -le 5 ]; then
        # Show full diff for small changes (but truncate long blocks)
        CURRENT_FILE=""
        while IFS= read -r line; do
          if echo "$line" | grep -qE "^diff --git"; then
            CURRENT_FILE=$(echo "$line" | sed 's/diff --git a\/\(.*\) b\/.*/\1/')
            echo "--- $CURRENT_FILE ---"
          elif echo "$line" | grep -qE "^@@"; then
            echo "$line"
          elif echo "$line" | grep -qE "^[+-]"; then
            echo "$line"
          fi
        done <<< "$OUTPUT" | head -100

        TOTAL_LINES=$(count_lines "$OUTPUT")
        if [ "$TOTAL_LINES" -gt 100 ]; then
          echo ""
          echo "[Diff truncated: $TOTAL_LINES total lines]"
        fi
      else
        # Summarize files changed
        echo "Files changed:"
        echo "$OUTPUT" | grep "^diff --git" | sed 's/diff --git a\/\(.*\) b\/.*/  \1/' | head -"$MAX_FILES"

        if [ "$FILES_CHANGED" -gt "$MAX_FILES" ]; then
          echo "  ... and $((FILES_CHANGED - MAX_FILES)) more files"
        fi

        echo ""
        echo "[Run 'git diff' directly for full output]"
      fi
    fi
    ;;

  log)
    if [ -z "$OUTPUT" ]; then
      echo "Log: No commits"
    else
      COMMIT_COUNT=$(echo "$OUTPUT" | grep -cE "^commit [a-f0-9]+|^[a-f0-9]+ " || echo "0")
      TOTAL_LINES=$(count_lines "$OUTPUT")

      echo "Log: $COMMIT_COUNT commits"
      echo ""

      # Check if it's oneline format
      if echo "$OUTPUT" | head -1 | grep -qE "^[a-f0-9]+ "; then
        # Oneline format - show as is but limited
        echo "$OUTPUT" | head -"$MAX_FILES"
        if [ "$COMMIT_COUNT" -gt "$MAX_FILES" ]; then
          echo "... and $((COMMIT_COUNT - MAX_FILES)) more commits"
        fi
      else
        # Full format - show summary
        echo "$OUTPUT" | grep -E "^commit |^Author:|^Date:|^    " | head -60

        if [ "$COMMIT_COUNT" -gt 10 ]; then
          echo ""
          echo "[Showing first ~10 of $COMMIT_COUNT commits]"
        fi
      fi
    fi
    ;;

  show)
    if [ -z "$OUTPUT" ]; then
      echo "Show: No output"
    else
      # Extract commit info
      COMMIT=$(echo "$OUTPUT" | grep -E "^commit " | head -1 || echo "")
      AUTHOR=$(echo "$OUTPUT" | grep -E "^Author:" | head -1 || echo "")
      DATE=$(echo "$OUTPUT" | grep -E "^Date:" | head -1 || echo "")
      MESSAGE=$(echo "$OUTPUT" | grep -E "^    " | head -3 || echo "")

      # Count diff stats
      FILES_CHANGED=$(echo "$OUTPUT" | grep -c "^diff --git" || echo "0")

      echo "$COMMIT"
      echo "$AUTHOR"
      echo "$DATE"
      echo ""
      echo "$MESSAGE"
      echo ""
      echo "Changes: $FILES_CHANGED files"

      # Show truncated diff
      if [ "$FILES_CHANGED" -gt 0 ]; then
        echo ""
        echo "$OUTPUT" | grep -E "^diff --git|^@@|^[+-]" | head -50
        TOTAL_LINES=$(echo "$OUTPUT" | grep -cE "^[+-]" || echo "0")
        if [ "$TOTAL_LINES" -gt 50 ]; then
          echo ""
          echo "[Diff truncated: $TOTAL_LINES total lines]"
        fi
      fi
    fi
    ;;

  blame)
    if [ -z "$OUTPUT" ]; then
      echo "Blame: No output"
    else
      LINE_COUNT=$(count_lines "$OUTPUT")

      if [ "$LINE_COUNT" -le 50 ]; then
        echo "$OUTPUT"
      else
        echo "Blame: $LINE_COUNT lines"
        echo ""
        echo "$OUTPUT" | head -50
        echo ""
        echo "[Blame truncated: $LINE_COUNT total lines]"
      fi
    fi
    ;;

  branch)
    if [ -z "$OUTPUT" ]; then
      echo "Branches: None"
    else
      BRANCH_COUNT=$(count_lines "$OUTPUT")
      CURRENT=$(echo "$OUTPUT" | grep "^\*" | sed 's/\* //' || echo "")

      echo "Branches: $BRANCH_COUNT total, current: $CURRENT"
      echo ""

      echo "$OUTPUT" | head -"$MAX_FILES"

      if [ "$BRANCH_COUNT" -gt "$MAX_FILES" ]; then
        echo "... and $((BRANCH_COUNT - MAX_FILES)) more branches"
      fi
    fi
    ;;

  stash)
    if echo "$COMMAND" | grep -qE "list"; then
      STASH_COUNT=$(count_lines "$OUTPUT")
      if [ -z "$OUTPUT" ] || [ "$STASH_COUNT" -eq 0 ]; then
        echo "Stash: Empty"
      else
        echo "Stash: $STASH_COUNT entries"
        echo ""
        echo "$OUTPUT" | head -10

        if [ "$STASH_COUNT" -gt 10 ]; then
          echo "... and $((STASH_COUNT - 10)) more"
        fi
      fi
    else
      # Other stash commands - show as is
      echo "$OUTPUT"
    fi
    ;;

  remote)
    if [ -z "$OUTPUT" ]; then
      echo "Remotes: None"
    else
      REMOTE_COUNT=$(count_lines "$OUTPUT")
      echo "Remotes: $REMOTE_COUNT"
      echo ""
      echo "$OUTPUT"
    fi
    ;;

  fetch|pull|push)
    if [ $EXIT_CODE -eq 0 ]; then
      if [ -z "$OUTPUT" ] || echo "$OUTPUT" | grep -qE "Already up to date|Everything up-to-date"; then
        echo "${SUBCOMMAND^}: Already up to date"
      else
        # Show summary
        echo "${SUBCOMMAND^}: Success"
        echo ""
        echo "$OUTPUT" | grep -E "Unpacking|Resolving|Writing|Counting|\->" | head -10
      fi
    else
      echo "${SUBCOMMAND^}: Failed"
      echo ""
      echo "$OUTPUT" | head -20
    fi
    ;;

  clone)
    if [ $EXIT_CODE -eq 0 ]; then
      REPO=$(echo "$OUTPUT" | grep -oE "'[^']+'" | head -1 || echo "repository")
      echo "Clone: Success - $REPO"
    else
      echo "Clone: Failed"
      echo ""
      echo "$OUTPUT" | head -10
    fi
    ;;

  add|reset|checkout|restore)
    if [ $EXIT_CODE -eq 0 ]; then
      if [ -z "$OUTPUT" ]; then
        echo "${SUBCOMMAND^}: Done"
      else
        LINE_COUNT=$(count_lines "$OUTPUT")
        if [ "$LINE_COUNT" -le 10 ]; then
          echo "$OUTPUT"
        else
          echo "${SUBCOMMAND^}: $LINE_COUNT items affected"
          echo ""
          echo "$OUTPUT" | head -10
          echo "... and $((LINE_COUNT - 10)) more"
        fi
      fi
    else
      echo "${SUBCOMMAND^}: Failed"
      echo ""
      echo "$OUTPUT" | head -10
    fi
    ;;

  commit)
    if [ $EXIT_CODE -eq 0 ]; then
      # Extract commit info
      COMMIT_INFO=$(echo "$OUTPUT" | grep -E "^\[|files? changed|insertion|deletion" | head -3)
      echo "Commit: Success"
      echo "$COMMIT_INFO"
    else
      echo "Commit: Failed"
      echo ""
      echo "$OUTPUT" | head -10
    fi
    ;;

  merge|rebase)
    if [ $EXIT_CODE -eq 0 ]; then
      if echo "$OUTPUT" | grep -qE "Already up to date|is up to date"; then
        echo "${SUBCOMMAND^}: Already up to date"
      else
        echo "${SUBCOMMAND^}: Success"
        echo ""
        echo "$OUTPUT" | grep -E "Fast-forward|Merge made|Successfully" | head -5
      fi
    else
      echo "${SUBCOMMAND^}: Conflict or error"
      echo ""
      echo "$OUTPUT" | grep -E "CONFLICT|error|fatal" | head -10

      echo ""
      echo "[Resolve conflicts and continue]"
    fi
    ;;

  *)
    # Generic git output handling
    if [ $EXIT_CODE -eq 0 ]; then
      LINE_COUNT=$(count_lines "$OUTPUT")

      if [ "$LINE_COUNT" -le 30 ]; then
        echo "$OUTPUT"
      else
        echo "git $SUBCOMMAND: $LINE_COUNT lines of output"
        echo ""
        echo "$OUTPUT" | head -30
        echo ""
        echo "[Output truncated]"
      fi
    else
      echo "git $SUBCOMMAND: Failed (exit code: $EXIT_CODE)"
      echo ""
      echo "$OUTPUT" | head -20
    fi
    ;;
esac

exit $EXIT_CODE
