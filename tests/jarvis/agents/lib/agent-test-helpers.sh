#!/usr/bin/env bash
#
# Agent Test Helpers
# ==================
# Utility functions for agent testing.

# Extract section content from markdown
extract_section() {
    local file="$1"
    local section="$2"

    awk -v section="$section" '
        /^## / { in_section = ($0 ~ section) }
        in_section && /^## / && !($0 ~ section) { exit }
        in_section { print }
    ' "$file"
}

# Count words in a section
count_section_words() {
    local content="$1"
    echo "$content" | wc -w | tr -d ' '
}

# Check for code blocks
has_code_blocks() {
    local file="$1"
    grep -q '```' "$file"
}

# Check for examples
has_examples() {
    local file="$1"
    grep -qiE '(example|sample|e\.g\.|for instance)' "$file"
}

# Check for constraints
has_constraints() {
    local file="$1"
    grep -qiE '(never|always|must|should not|avoid|do not)' "$file"
}

# Calculate readability score (simplified Flesch-Kincaid approximation)
calculate_readability() {
    local file="$1"
    local word_count
    local sentence_count
    local syllable_count

    word_count=$(cat "$file" | wc -w | tr -d ' ')
    sentence_count=$(grep -c '[.!?]' "$file" 2>/dev/null || echo 1)
    [[ $sentence_count -eq 0 ]] && sentence_count=1

    # Simplified syllable count (words with >6 chars are ~2 syllables)
    syllable_count=$(cat "$file" | tr ' ' '\n' | awk 'length > 6 { count += 2 } length <= 6 { count++ } END { print count }')
    [[ -z "$syllable_count" ]] && syllable_count=$word_count

    # Simplified Flesch-Kincaid grade level
    local asl=$((word_count / sentence_count))
    local asw=$((syllable_count / word_count))
    local grade=$((asl * 4 / 10 + asw * 12 / 10 - 15 / 10))

    echo "$grade"
}

# Validate prompt quality
validate_prompt_quality() {
    local file="$1"
    local quality_score=0
    local max_score=10

    # Has clear role (+2)
    if grep -qE "(You are|Your role|Act as)" "$file"; then
        ((quality_score += 2))
    fi

    # Has capabilities section (+2)
    if grep -q "## Capabilities" "$file"; then
        ((quality_score += 2))
    fi

    # Has output format (+2)
    if grep -qiE "(output format|response format|template)" "$file"; then
        ((quality_score += 2))
    fi

    # Has examples (+2)
    if has_examples "$file"; then
        ((quality_score += 2))
    fi

    # Has constraints (+2)
    if has_constraints "$file"; then
        ((quality_score += 2))
    fi

    echo "$quality_score/$max_score"
}

# Generate quality report
generate_quality_report() {
    local file="$1"
    local agent_name=$(basename "$file" .md)

    echo "Quality Report: $agent_name"
    echo "=============================="
    echo ""
    echo "Prompt Quality: $(validate_prompt_quality "$file")"
    echo "Word Count: $(cat "$file" | wc -w | tr -d ' ')"
    echo "Has Code Blocks: $(has_code_blocks "$file" && echo "Yes" || echo "No")"
    echo "Has Examples: $(has_examples "$file" && echo "Yes" || echo "No")"
    echo "Has Constraints: $(has_constraints "$file" && echo "Yes" || echo "No")"
    echo ""
}
