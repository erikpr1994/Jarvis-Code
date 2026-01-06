#!/usr/bin/env bash
#
# Jarvis Confidence Scoring
# =========================
# Calculates confidence scores for code changes based on verification results.
#
# Usage:
#   source confidence.sh
#   calculate_confidence "$verification_json"
#
# Returns:
#   JSON with confidence score and breakdown

set -euo pipefail

# =============================================================================
# CONFIDENCE CALCULATION
# =============================================================================

# Calculate overall confidence score (0-100)
calculate_confidence() {
    local verification_json="${1:-{}}"

    local base_score=50  # Start at 50%
    local score=$base_score

    # Parse verification results
    local type_check=$(echo "$verification_json" | jq -r '.checks.TypeScript.status // "skip"')
    local lint_check=$(echo "$verification_json" | jq -r '.checks["Biome lint"].status // .checks.ESLint.status // "skip"')
    local format_check=$(echo "$verification_json" | jq -r '.checks.Prettier.status // .checks["Biome format"].status // "skip"')
    local unit_tests=$(echo "$verification_json" | jq -r '.checks["Unit tests"].status // .checks.Vitest.status // .checks.Jest.status // "skip"')
    local integration=$(echo "$verification_json" | jq -r '.checks["Integration tests"].status // "skip"')
    local e2e=$(echo "$verification_json" | jq -r '.checks["E2E tests"].status // .checks["Playwright E2E"].status // "skip"')
    local build=$(echo "$verification_json" | jq -r '.checks.Build.status // "skip"')
    local security=$(echo "$verification_json" | jq -r '.checks["Security audit"].status // "skip"')

    # Type checking (+15 for pass, -10 for fail)
    case "$type_check" in
        pass) ((score += 15)) ;;
        fail) ((score -= 10)) ;;
    esac

    # Linting (+10 for pass, -5 for fail, +5 for warn)
    case "$lint_check" in
        pass) ((score += 10)) ;;
        fail) ((score -= 5)) ;;
        warn) ((score += 5)) ;;
    esac

    # Formatting (+5 for pass)
    case "$format_check" in
        pass) ((score += 5)) ;;
    esac

    # Unit tests (+15 for pass, -15 for fail)
    case "$unit_tests" in
        pass) ((score += 15)) ;;
        fail) ((score -= 15)) ;;
    esac

    # Integration tests (+10 for pass, -10 for fail)
    case "$integration" in
        pass) ((score += 10)) ;;
        fail) ((score -= 10)) ;;
    esac

    # E2E tests (+10 for pass, -10 for fail)
    case "$e2e" in
        pass) ((score += 10)) ;;
        fail) ((score -= 10)) ;;
    esac

    # Build (+10 for pass, -20 for fail)
    case "$build" in
        pass) ((score += 10)) ;;
        fail) ((score -= 20)) ;;
    esac

    # Security (+5 for pass, -5 for warn)
    case "$security" in
        pass) ((score += 5)) ;;
        warn) ((score -= 5)) ;;
    esac

    # Clamp to 0-100
    [[ $score -lt 0 ]] && score=0
    [[ $score -gt 100 ]] && score=100

    # Determine confidence level
    local level
    if [[ $score -ge 90 ]]; then
        level="high"
    elif [[ $score -ge 70 ]]; then
        level="medium"
    elif [[ $score -ge 50 ]]; then
        level="low"
    else
        level="very-low"
    fi

    # Generate recommendation
    local recommendation
    if [[ $score -ge 90 ]]; then
        recommendation="Ready for merge. All quality gates passed."
    elif [[ $score -ge 70 ]]; then
        recommendation="Generally safe to merge. Consider addressing remaining issues."
    elif [[ $score -ge 50 ]]; then
        recommendation="Review carefully before merge. Significant issues present."
    else
        recommendation="Not ready for merge. Major issues must be resolved."
    fi

    # Output JSON
    jq -n \
        --argjson score "$score" \
        --arg level "$level" \
        --arg recommendation "$recommendation" \
        --arg types "$type_check" \
        --arg lint "$lint_check" \
        --arg format "$format_check" \
        --arg unit "$unit_tests" \
        --arg integration "$integration" \
        --arg e2e "$e2e" \
        --arg build "$build" \
        --arg security "$security" \
        '{
            confidence: {
                score: $score,
                level: $level,
                recommendation: $recommendation
            },
            breakdown: {
                type_check: $types,
                lint: $lint,
                format: $format,
                unit_tests: $unit,
                integration_tests: $integration,
                e2e_tests: $e2e,
                build: $build,
                security: $security
            }
        }'
}

# Get confidence badge (for display)
get_confidence_badge() {
    local score="$1"

    if [[ $score -ge 90 ]]; then
        echo "🟢 High ($score%)"
    elif [[ $score -ge 70 ]]; then
        echo "🟡 Medium ($score%)"
    elif [[ $score -ge 50 ]]; then
        echo "🟠 Low ($score%)"
    else
        echo "🔴 Very Low ($score%)"
    fi
}

# Print confidence report
print_confidence_report() {
    local confidence_json="$1"

    local score=$(echo "$confidence_json" | jq -r '.confidence.score')
    local level=$(echo "$confidence_json" | jq -r '.confidence.level')
    local recommendation=$(echo "$confidence_json" | jq -r '.confidence.recommendation')

    echo ""
    echo "━━━ Confidence Score ━━━"
    echo ""
    echo "Score: $(get_confidence_badge "$score")"
    echo "Level: $level"
    echo ""
    echo "Recommendation: $recommendation"
    echo ""
}

# =============================================================================
# STANDALONE EXECUTION
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $(basename "$0") <verification_json_file>"
        echo ""
        echo "Example:"
        echo "  $(basename "$0") /tmp/verification-results.json"
        exit 1
    fi

    verification_json=$(cat "$1")
    confidence_result=$(calculate_confidence "$verification_json")
    print_confidence_report "$confidence_result"
    echo ""
    echo "Full JSON:"
    echo "$confidence_result"
fi
