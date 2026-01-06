#!/bin/bash
# Jarvis Metrics Collection Script
# Collects daily metrics from various sources and outputs to daily metrics file

set -e

METRICS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAILY_DIR="${METRICS_DIR}/daily"
TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="${DAILY_DIR}/${TODAY}.json"

# Initialize counters
FEATURES_COMPLETED=0
COMMITS=0
PRS_MERGED=0
TEST_COVERAGE=0
REVIEW_SCORE_AVG=0
BUGS_FOUND=0
SKILLS_INVOKED="[]"
PATTERNS_MATCHED=0
TOKENS_USED=0
COMPACTIONS=0

# Get git metrics if in a git repository
collect_git_metrics() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        # Count commits made today
        COMMITS=$(git log --since="midnight" --oneline 2>/dev/null | wc -l | tr -d ' ')

        # Count merged PRs (check for merge commits today)
        PRS_MERGED=$(git log --since="midnight" --merges --oneline 2>/dev/null | wc -l | tr -d ' ')

        # Estimate features from commit messages containing 'feat', 'feature', 'add', 'implement'
        FEATURES_COMPLETED=$(git log --since="midnight" --oneline 2>/dev/null | grep -iE '(feat|feature|add|implement)' | wc -l | tr -d ' ')
    fi
}

# Get test coverage if available
collect_test_metrics() {
    # Check for common coverage report locations
    local coverage_file=""

    if [[ -f "coverage/coverage-summary.json" ]]; then
        coverage_file="coverage/coverage-summary.json"
    elif [[ -f "coverage.json" ]]; then
        coverage_file="coverage.json"
    elif [[ -f ".coverage" ]]; then
        # Python coverage
        if command -v coverage >/dev/null 2>&1; then
            TEST_COVERAGE=$(coverage report 2>/dev/null | grep TOTAL | awk '{print $NF}' | tr -d '%' || echo "0")
        fi
        return
    fi

    if [[ -n "$coverage_file" && -f "$coverage_file" ]]; then
        # Try to extract coverage percentage
        TEST_COVERAGE=$(cat "$coverage_file" 2>/dev/null | grep -oE '"pct":\s*[0-9.]+' | head -1 | grep -oE '[0-9.]+' || echo "0")
    fi
}

# Get skills invoked from today's session log
collect_learning_metrics() {
    local skills_log="${METRICS_DIR}/../learning/skills-log.json"
    local patterns_log="${METRICS_DIR}/../patterns/matches.log"

    if [[ -f "$skills_log" ]]; then
        # Extract skills invoked today
        SKILLS_INVOKED=$(cat "$skills_log" 2>/dev/null | \
            grep "\"date\": \"${TODAY}\"" -A1 2>/dev/null | \
            grep -oE '"skill": "[^"]+"' | \
            cut -d'"' -f4 | \
            sort -u | \
            jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    fi

    if [[ -f "$patterns_log" ]]; then
        PATTERNS_MATCHED=$(grep "${TODAY}" "$patterns_log" 2>/dev/null | wc -l | tr -d ' ')
    fi
}

# Get context metrics from session data
collect_context_metrics() {
    local context_log="${METRICS_DIR}/../learning/context-usage.log"

    if [[ -f "$context_log" ]]; then
        # Sum tokens used today
        TOKENS_USED=$(grep "${TODAY}" "$context_log" 2>/dev/null | \
            awk -F',' '{sum += $2} END {print sum}' || echo "0")

        # Count compactions today
        COMPACTIONS=$(grep "${TODAY}" "$context_log" 2>/dev/null | \
            grep -c "compaction" || echo "0")
    fi
}

# Load existing metrics if file exists (to preserve manual entries)
load_existing_metrics() {
    if [[ -f "$OUTPUT_FILE" ]]; then
        local existing=$(cat "$OUTPUT_FILE")

        # Preserve review scores and bugs (these are often manually entered)
        REVIEW_SCORE_AVG=$(echo "$existing" | jq -r '.quality.review_score_avg // 0')
        BUGS_FOUND=$(echo "$existing" | jq -r '.quality.bugs_found // 0')

        # Merge skills arrays
        local existing_skills=$(echo "$existing" | jq -r '.learning.skills_invoked // []')
        if [[ "$existing_skills" != "[]" && "$SKILLS_INVOKED" != "[]" ]]; then
            SKILLS_INVOKED=$(echo "$existing_skills $SKILLS_INVOKED" | jq -s 'add | unique')
        elif [[ "$existing_skills" != "[]" ]]; then
            SKILLS_INVOKED="$existing_skills"
        fi
    fi
}

# Generate the metrics JSON
generate_metrics_json() {
    cat <<EOF
{
  "date": "${TODAY}",
  "productivity": {
    "features_completed": ${FEATURES_COMPLETED:-0},
    "commits": ${COMMITS:-0},
    "prs_merged": ${PRS_MERGED:-0}
  },
  "quality": {
    "test_coverage": ${TEST_COVERAGE:-0},
    "review_score_avg": ${REVIEW_SCORE_AVG:-0},
    "bugs_found": ${BUGS_FOUND:-0}
  },
  "learning": {
    "skills_invoked": ${SKILLS_INVOKED:-[]},
    "patterns_matched": ${PATTERNS_MATCHED:-0}
  },
  "context": {
    "tokens_used": ${TOKENS_USED:-0},
    "compactions": ${COMPACTIONS:-0}
  }
}
EOF
}

# Main execution
main() {
    # Ensure daily directory exists
    mkdir -p "$DAILY_DIR"

    echo "Collecting metrics for ${TODAY}..."

    # Collect from various sources
    collect_git_metrics
    collect_test_metrics
    collect_learning_metrics
    collect_context_metrics

    # Load and merge with existing metrics
    load_existing_metrics

    # Generate and save metrics
    generate_metrics_json | jq '.' > "$OUTPUT_FILE"

    echo "Metrics saved to ${OUTPUT_FILE}"

    # Output summary
    echo ""
    echo "=== Daily Metrics Summary ==="
    echo "Productivity:"
    echo "  - Features completed: ${FEATURES_COMPLETED:-0}"
    echo "  - Commits: ${COMMITS:-0}"
    echo "  - PRs merged: ${PRS_MERGED:-0}"
    echo ""
    echo "Quality:"
    echo "  - Test coverage: ${TEST_COVERAGE:-0}%"
    echo "  - Review score avg: ${REVIEW_SCORE_AVG:-0}"
    echo "  - Bugs found: ${BUGS_FOUND:-0}"
    echo ""
    echo "Learning:"
    echo "  - Skills invoked: ${SKILLS_INVOKED:-[]}"
    echo "  - Patterns matched: ${PATTERNS_MATCHED:-0}"
    echo ""
    echo "Context:"
    echo "  - Tokens used: ${TOKENS_USED:-0}"
    echo "  - Compactions: ${COMPACTIONS:-0}"
}

# Run main function
main "$@"
