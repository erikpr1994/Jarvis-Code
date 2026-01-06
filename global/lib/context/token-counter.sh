#!/bin/bash
# token-counter.sh - Estimate token counts for text input
#
# Uses a simple heuristic: ~4 characters per token (GPT/Claude average)
# More accurate counting would require tiktoken or similar
#
# Usage:
#   echo "some text" | ./token-counter.sh
#   ./token-counter.sh < file.txt
#   ./token-counter.sh --detailed < file.txt
#   cat file.txt | ./token-counter.sh --format=json
#
# Options:
#   --detailed     Show breakdown by line type
#   --format=json  Output in JSON format
#   --warn=N       Warn if tokens exceed N (default: 5000)

set -e

# Bypass if verbose mode requested (just count, no processing)
# Note: For token-counter, verbose mode means detailed output, not bypass

# Default settings
DETAILED=false
FORMAT="text"
WARN_THRESHOLD=5000

# Parse arguments
for arg in "$@"; do
  case $arg in
    --detailed)
      DETAILED=true
      ;;
    --format=*)
      FORMAT="${arg#*=}"
      ;;
    --warn=*)
      WARN_THRESHOLD="${arg#*=}"
      ;;
  esac
done

# Read input
INPUT=$(cat)

# Basic counts
CHARS=$(echo "$INPUT" | wc -c | tr -d ' ')
WORDS=$(echo "$INPUT" | wc -w | tr -d ' ')
LINES=$(echo "$INPUT" | wc -l | tr -d ' ')

# Token estimation using character-based heuristic
# Claude/GPT average ~4 chars per token for English text
# Code tends to be ~3-3.5 chars per token due to punctuation
TOKENS_CHAR_METHOD=$((CHARS / 4))

# Word-based estimation (roughly 1.3 tokens per word)
TOKENS_WORD_METHOD=$((WORDS * 13 / 10))

# Use average of both methods
TOKENS=$(( (TOKENS_CHAR_METHOD + TOKENS_WORD_METHOD) / 2 ))

# Determine if this is likely code or text
CODE_CHARS=$(echo "$INPUT" | grep -o '[{}();=<>]' | wc -l | tr -d ' ')
CODE_RATIO=$((CODE_CHARS * 100 / (CHARS + 1)))

if [ "$CODE_RATIO" -gt 5 ]; then
  CONTENT_TYPE="code"
  # Adjust for code (more tokens per character due to punctuation)
  TOKENS=$((CHARS / 3))
else
  CONTENT_TYPE="text"
fi

# Warning check
if [ "$TOKENS" -gt "$WARN_THRESHOLD" ]; then
  OVER_THRESHOLD=true
else
  OVER_THRESHOLD=false
fi

# Output based on format
if [ "$FORMAT" = "json" ]; then
  cat << EOF
{
  "tokens": $TOKENS,
  "characters": $CHARS,
  "words": $WORDS,
  "lines": $LINES,
  "content_type": "$CONTENT_TYPE",
  "exceeds_threshold": $OVER_THRESHOLD,
  "threshold": $WARN_THRESHOLD
}
EOF
elif [ "$DETAILED" = true ]; then
  echo "Token Estimation Report"
  echo "======================="
  echo ""
  echo "Content Analysis:"
  echo "  Characters: $CHARS"
  echo "  Words:      $WORDS"
  echo "  Lines:      $LINES"
  echo "  Type:       $CONTENT_TYPE"
  echo ""
  echo "Token Estimates:"
  echo "  Char-based:  $TOKENS_CHAR_METHOD tokens"
  echo "  Word-based:  $TOKENS_WORD_METHOD tokens"
  echo "  Combined:    $TOKENS tokens (recommended)"
  echo ""

  if [ "$OVER_THRESHOLD" = true ]; then
    echo "WARNING: Exceeds threshold of $WARN_THRESHOLD tokens"
    echo "Consider using summarize-output.sh to reduce context"
  else
    echo "Status: Within threshold ($TOKENS / $WARN_THRESHOLD)"
  fi

  echo ""
  echo "Breakdown by line length:"
  echo "$INPUT" | awk '
    {
      len = length($0)
      if (len == 0) empty++
      else if (len < 40) short++
      else if (len < 80) medium++
      else if (len < 120) long++
      else verylong++
    }
    END {
      print "  Empty lines:     " empty+0
      print "  Short (<40):     " short+0
      print "  Medium (40-80):  " medium+0
      print "  Long (80-120):   " long+0
      print "  Very long (120+):" verylong+0
    }
  '
else
  # Simple output
  if [ "$OVER_THRESHOLD" = true ]; then
    echo "$TOKENS tokens (~$CHARS chars) [WARN: exceeds $WARN_THRESHOLD]"
  else
    echo "$TOKENS tokens (~$CHARS chars)"
  fi
fi
