#!/bin/bash
# Jarvis Weekly Summary Generator
# Aggregates daily metrics and generates a weekly summary report

set -e

METRICS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAILY_DIR="${METRICS_DIR}/daily"
TODAY=$(date +%Y-%m-%d)
WEEK_START=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d)

# Output file
OUTPUT_FILE="${METRICS_DIR}/weekly-summary-${TODAY}.md"

# Initialize aggregates
TOTAL_FEATURES=0
TOTAL_COMMITS=0
TOTAL_PRS=0
TOTAL_BUGS=0
TOTAL_TOKENS=0
TOTAL_COMPACTIONS=0
TOTAL_PATTERNS=0
DAYS_COUNT=0
COVERAGE_SUM=0
REVIEW_SUM=0
ALL_SKILLS=""

# Collect weekly data
collect_weekly_data() {
    echo "Collecting data from ${WEEK_START} to ${TODAY}..."

    for file in "${DAILY_DIR}"/*.json; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        local file_date=$(basename "$file" .json)

        # Check if date is within range
        if [[ "$file_date" < "$WEEK_START" ]]; then
            continue
        fi

        if [[ "$file_date" > "$TODAY" ]]; then
            continue
        fi

        DAYS_COUNT=$((DAYS_COUNT + 1))

        # Aggregate productivity
        local features=$(jq -r '.productivity.features_completed // 0' "$file")
        local commits=$(jq -r '.productivity.commits // 0' "$file")
        local prs=$(jq -r '.productivity.prs_merged // 0' "$file")

        TOTAL_FEATURES=$((TOTAL_FEATURES + features))
        TOTAL_COMMITS=$((TOTAL_COMMITS + commits))
        TOTAL_PRS=$((TOTAL_PRS + prs))

        # Aggregate quality
        local coverage=$(jq -r '.quality.test_coverage // 0' "$file")
        local review=$(jq -r '.quality.review_score_avg // 0' "$file")
        local bugs=$(jq -r '.quality.bugs_found // 0' "$file")

        COVERAGE_SUM=$(echo "$COVERAGE_SUM + $coverage" | bc)
        REVIEW_SUM=$(echo "$REVIEW_SUM + $review" | bc)
        TOTAL_BUGS=$((TOTAL_BUGS + bugs))

        # Aggregate learning
        local skills=$(jq -r '.learning.skills_invoked // []' "$file")
        local patterns=$(jq -r '.learning.patterns_matched // 0' "$file")

        ALL_SKILLS="${ALL_SKILLS} ${skills}"
        TOTAL_PATTERNS=$((TOTAL_PATTERNS + patterns))

        # Aggregate context
        local tokens=$(jq -r '.context.tokens_used // 0' "$file")
        local compactions=$(jq -r '.context.compactions // 0' "$file")

        TOTAL_TOKENS=$((TOTAL_TOKENS + tokens))
        TOTAL_COMPACTIONS=$((TOTAL_COMPACTIONS + compactions))
    done
}

# Calculate averages
calculate_averages() {
    if [[ $DAYS_COUNT -gt 0 ]]; then
        AVG_COMMITS=$(echo "scale=1; $TOTAL_COMMITS / $DAYS_COUNT" | bc)
        AVG_FEATURES=$(echo "scale=1; $TOTAL_FEATURES / $DAYS_COUNT" | bc)
        AVG_COVERAGE=$(echo "scale=1; $COVERAGE_SUM / $DAYS_COUNT" | bc)
        AVG_REVIEW=$(echo "scale=1; $REVIEW_SUM / $DAYS_COUNT" | bc)
        AVG_TOKENS=$(echo "scale=0; $TOTAL_TOKENS / $DAYS_COUNT" | bc)
    else
        AVG_COMMITS=0
        AVG_FEATURES=0
        AVG_COVERAGE=0
        AVG_REVIEW=0
        AVG_TOKENS=0
    fi
}

# Get unique skills
get_unique_skills() {
    UNIQUE_SKILLS=$(echo "$ALL_SKILLS" | tr ',' '\n' | tr -d '[]"' | tr ' ' '\n' | sort -u | grep -v '^$' | head -10)
    SKILLS_COUNT=$(echo "$UNIQUE_SKILLS" | grep -c . || echo "0")
}

# Calculate trend indicator
get_trend() {
    local current=$1
    local previous=$2

    if [[ $(echo "$current > $previous" | bc) -eq 1 ]]; then
        echo "^"
    elif [[ $(echo "$current < $previous" | bc) -eq 1 ]]; then
        echo "v"
    else
        echo "="
    fi
}

# Generate recommendations
generate_recommendations() {
    RECOMMENDATIONS=""

    # Low commit rate
    if [[ $(echo "$AVG_COMMITS < 5" | bc) -eq 1 ]]; then
        RECOMMENDATIONS="${RECOMMENDATIONS}\n- Consider breaking work into smaller, more frequent commits"
    fi

    # Low test coverage
    if [[ $(echo "$AVG_COVERAGE < 70" | bc) -eq 1 ]]; then
        RECOMMENDATIONS="${RECOMMENDATIONS}\n- Focus on improving test coverage this week"
    fi

    # High token usage
    if [[ $(echo "$AVG_TOKENS > 50000" | bc) -eq 1 ]]; then
        RECOMMENDATIONS="${RECOMMENDATIONS}\n- Consider using more targeted context to reduce token usage"
    fi

    # Few skills used
    if [[ $SKILLS_COUNT -lt 3 ]]; then
        RECOMMENDATIONS="${RECOMMENDATIONS}\n- Explore additional skills to enhance productivity"
    fi

    if [[ -z "$RECOMMENDATIONS" ]]; then
        RECOMMENDATIONS="\n- Great week! Keep up the good work"
    fi
}

# Generate markdown report
generate_report() {
    cat <<EOF
# Weekly Metrics Summary

**Period:** ${WEEK_START} to ${TODAY}
**Days Tracked:** ${DAYS_COUNT}

---

## Productivity

| Metric | Total | Daily Average |
|--------|-------|---------------|
| Features Completed | ${TOTAL_FEATURES} | ${AVG_FEATURES} |
| Commits | ${TOTAL_COMMITS} | ${AVG_COMMITS} |
| PRs Merged | ${TOTAL_PRS} | - |

---

## Quality

| Metric | Value |
|--------|-------|
| Average Test Coverage | ${AVG_COVERAGE}% |
| Average Review Score | ${AVG_REVIEW}/10 |
| Total Bugs Found | ${TOTAL_BUGS} |

---

## Learning

### Skills Used (${SKILLS_COUNT} unique)
$(echo "$UNIQUE_SKILLS" | while read skill; do
    if [[ -n "$skill" ]]; then
        echo "- ${skill}"
    fi
done)

| Metric | Value |
|--------|-------|
| Patterns Matched | ${TOTAL_PATTERNS} |

---

## Context Usage

| Metric | Total | Daily Average |
|--------|-------|---------------|
| Tokens Used | ${TOTAL_TOKENS} | ${AVG_TOKENS} |
| Compactions | ${TOTAL_COMPACTIONS} | - |

---

## Recommendations
$(echo -e "$RECOMMENDATIONS")

---

*Generated on $(date +"%Y-%m-%d %H:%M:%S")*
EOF
}

# Main execution
main() {
    echo "Generating weekly summary..."
    echo ""

    # Collect and process data
    collect_weekly_data
    calculate_averages
    get_unique_skills
    generate_recommendations

    # Generate report
    generate_report > "$OUTPUT_FILE"

    echo "Weekly summary saved to ${OUTPUT_FILE}"
    echo ""

    # Also output to console
    cat "$OUTPUT_FILE"
}

# Run main function
main "$@"
