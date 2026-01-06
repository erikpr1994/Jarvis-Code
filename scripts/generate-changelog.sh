#!/usr/bin/env bash
# Changelog Generator for Jarvis
# Generates changelog from git commits following conventional commits format
#
# Usage:
#   ./generate-changelog.sh [options]
#
# Options:
#   --from <tag>     Start from tag (default: previous tag)
#   --to <ref>       End at ref (default: HEAD)
#   --output <file>  Output file (default: stdout)
#   --format <type>  Output format: markdown, json (default: markdown)
#   --append         Append to existing changelog instead of replacing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Configuration
FROM_TAG=""
TO_REF="HEAD"
OUTPUT_FILE=""
OUTPUT_FORMAT="markdown"
APPEND_MODE=false

# Categories for conventional commits
declare -A CATEGORIES
CATEGORIES["feat"]="Features"
CATEGORIES["fix"]="Bug Fixes"
CATEGORIES["docs"]="Documentation"
CATEGORIES["style"]="Styles"
CATEGORIES["refactor"]="Refactoring"
CATEGORIES["perf"]="Performance"
CATEGORIES["test"]="Tests"
CATEGORIES["build"]="Build"
CATEGORIES["ci"]="CI/CD"
CATEGORIES["chore"]="Chores"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from)
            FROM_TAG="$2"
            shift 2
            ;;
        --to)
            TO_REF="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --format|-f)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --append)
            APPEND_MODE=true
            shift
            ;;
        --help|-h)
            echo "Changelog Generator for Jarvis"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --from <tag>     Start from tag (default: previous tag)"
            echo "  --to <ref>       End at ref (default: HEAD)"
            echo "  --output <file>  Output file (default: stdout)"
            echo "  --format <type>  Output format: markdown, json"
            echo "  --append         Append to existing changelog"
            echo "  --help           Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Get previous tag if not specified
if [[ -z "$FROM_TAG" ]]; then
    FROM_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

# Get current version
VERSION=""
if [[ -f "${PROJECT_ROOT}/VERSION" ]]; then
    VERSION=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '[:space:]')
fi

# Get commit range
COMMIT_RANGE=""
if [[ -n "$FROM_TAG" ]]; then
    COMMIT_RANGE="${FROM_TAG}..${TO_REF}"
else
    COMMIT_RANGE="$TO_REF"
fi

# Parse commits into categories
declare -A COMMIT_GROUPS

parse_commits() {
    local line type scope subject hash

    while IFS='|' read -r hash subject; do
        # Skip empty lines
        [[ -z "$subject" ]] && continue

        # Parse conventional commit format: type(scope): subject
        if [[ "$subject" =~ ^([a-z]+)(\(([^)]+)\))?:\ (.+)$ ]]; then
            type="${BASH_REMATCH[1]}"
            scope="${BASH_REMATCH[3]:-}"
            subject="${BASH_REMATCH[4]}"

            # Add to category
            local category="${CATEGORIES[$type]:-Other}"
            local entry="- ${subject}"
            if [[ -n "$scope" ]]; then
                entry="- **${scope}**: ${subject}"
            fi
            entry="${entry} (${hash:0:7})"

            if [[ -z "${COMMIT_GROUPS[$category]:-}" ]]; then
                COMMIT_GROUPS[$category]="$entry"
            else
                COMMIT_GROUPS[$category]="${COMMIT_GROUPS[$category]}"$'\n'"$entry"
            fi
        else
            # Non-conventional commit
            local entry="- ${subject} (${hash:0:7})"
            if [[ -z "${COMMIT_GROUPS[Other]:-}" ]]; then
                COMMIT_GROUPS[Other]="$entry"
            else
                COMMIT_GROUPS[Other]="${COMMIT_GROUPS[Other]}"$'\n'"$entry"
            fi
        fi
    done < <(git log "$COMMIT_RANGE" --pretty=format:'%H|%s' 2>/dev/null || echo "")
}

# Generate markdown output
generate_markdown() {
    local date
    date=$(date '+%Y-%m-%d')

    echo "# Changelog"
    echo ""
    echo "All notable changes to Jarvis will be documented in this file."
    echo ""
    echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
    echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
    echo ""

    # Current version section
    if [[ -n "$VERSION" ]]; then
        echo "## [$VERSION] - $date"
    else
        echo "## [Unreleased]"
    fi
    echo ""

    # Output by category in preferred order
    local order=("Features" "Bug Fixes" "Performance" "Refactoring" "Documentation" "Tests" "Build" "CI/CD" "Styles" "Chores" "Other")

    for category in "${order[@]}"; do
        if [[ -n "${COMMIT_GROUPS[$category]:-}" ]]; then
            echo "### $category"
            echo ""
            echo "${COMMIT_GROUPS[$category]}"
            echo ""
        fi
    done

    # Add comparison link if we have a from tag
    if [[ -n "$FROM_TAG" ]]; then
        echo "---"
        echo ""
        echo "**Full Changelog**: \`$FROM_TAG..${TO_REF}\`"
    fi
}

# Generate JSON output
generate_json() {
    local date
    date=$(date '+%Y-%m-%d')

    echo "{"
    echo "  \"version\": \"${VERSION:-unreleased}\","
    echo "  \"date\": \"$date\","
    echo "  \"from_tag\": \"${FROM_TAG:-null}\","
    echo "  \"to_ref\": \"$TO_REF\","
    echo "  \"changes\": {"

    local first=true
    local order=("Features" "Bug Fixes" "Performance" "Refactoring" "Documentation" "Tests" "Build" "CI/CD" "Styles" "Chores" "Other")

    for category in "${order[@]}"; do
        if [[ -n "${COMMIT_GROUPS[$category]:-}" ]]; then
            if [[ "$first" != true ]]; then
                echo ","
            fi
            first=false

            echo -n "    \"$category\": ["

            local items=()
            while IFS= read -r line; do
                # Extract commit message (remove "- " prefix and hash suffix)
                local msg
                msg=$(echo "$line" | sed 's/^- //' | sed 's/ ([a-f0-9]\{7\})$//')
                items+=("\"$msg\"")
            done <<< "${COMMIT_GROUPS[$category]}"

            local IFS=','
            echo -n "${items[*]}"
            echo -n "]"
        fi
    done

    echo ""
    echo "  }"
    echo "}"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    # Parse commits
    parse_commits

    # Check if we have any commits
    if [[ ${#COMMIT_GROUPS[@]} -eq 0 ]]; then
        echo "No commits found in range: $COMMIT_RANGE" >&2
        exit 0
    fi

    # Generate output
    local output
    case "$OUTPUT_FORMAT" in
        markdown|md)
            output=$(generate_markdown)
            ;;
        json)
            output=$(generate_json)
            ;;
        *)
            echo "Unknown format: $OUTPUT_FORMAT" >&2
            exit 1
            ;;
    esac

    # Write output
    if [[ -n "$OUTPUT_FILE" ]]; then
        if [[ "$APPEND_MODE" == true && -f "$OUTPUT_FILE" ]]; then
            # Append after header
            local header existing_content new_section
            header=$(head -n 7 "$OUTPUT_FILE" 2>/dev/null || echo "")
            existing_content=$(tail -n +8 "$OUTPUT_FILE" 2>/dev/null || echo "")

            # Get just the new version section (skip header)
            new_section=$(echo "$output" | tail -n +8)

            {
                echo "$header"
                echo ""
                echo "$new_section"
                echo ""
                echo "$existing_content"
            } > "$OUTPUT_FILE"
        else
            echo "$output" > "$OUTPUT_FILE"
        fi
        echo "Changelog written to: $OUTPUT_FILE" >&2
    else
        echo "$output"
    fi
}

main
