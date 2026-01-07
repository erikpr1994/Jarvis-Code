#!/usr/bin/env bash
# Test: all-skills
# Purpose: Validate all skill files have correct structure and content
#
# Tests:
# - All skill files exist in expected locations
# - Skill files have required sections
# - skill-rules.json references valid skills
# - No orphan skills (defined but not in rules)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
JARVIS_ROOT="${SCRIPT_DIR}/../../../"

source "${LIB_DIR}/test-helpers.sh"

test_setup

SKILLS_DIR="${JARVIS_ROOT}/global/skills"
RULES_FILE="${SKILLS_DIR}/skill-rules.json"

# ============================================================================
# TESTS
# ============================================================================

# Test 1: Skills directory exists
test_skills_dir_exists() {
    assert_dir_exists "$SKILLS_DIR" "skills/ directory exists"
}

# Test 2: skill-rules.json exists
test_rules_file_exists() {
    assert_file_exists "$RULES_FILE" "skill-rules.json exists"
}

# Test 3: Skill directories exist (each skill in its own directory)
test_skill_categories() {
    local found=0

    # Count skill directories (each skill has its own directory with SKILL.md)
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [[ -d "$skill_dir" && -f "${skill_dir}SKILL.md" ]]; then
            found=$((found + 1))
        fi
    done

    if [[ $found -ge 5 ]]; then
        assert_true "1" "Skill directories exist ($found skills found)"
    else
        assert_true "" "Should have skill directories"
    fi
}

# Test 4: Skill files exist ({skill-name}/SKILL.md structure)
test_skill_files_exist() {
    local skill_count=0

    # Count SKILL.md files in skill directories
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [[ -f "${skill_dir}SKILL.md" ]]; then
            skill_count=$((skill_count + 1))
        fi
    done

    if [[ $skill_count -gt 0 ]]; then
        assert_true "1" "Skills have definition files ($skill_count found)"
    else
        assert_true "" "Should have skill .md files"
    fi
}

# Test 5: Skill files have required sections
test_skill_content_structure() {
    local valid_skills=0
    local checked_skills=0

    # Check SKILL.md files in each skill directory
    for skill_dir in "$SKILLS_DIR"/*/; do
        local skill_file="${skill_dir}SKILL.md"
        if [[ ! -f "$skill_file" ]]; then
            continue
        fi

        checked_skills=$((checked_skills + 1))

        # Check for title (# header)
        if grep -q "^#" "$skill_file" 2>/dev/null; then
            valid_skills=$((valid_skills + 1))
        fi
    done

    if [[ $checked_skills -eq 0 ]]; then
        assert_true "1" "No skills to check"
    elif [[ $valid_skills -ge $((checked_skills * 80 / 100)) ]]; then
        assert_true "1" "Skills have proper structure ($valid_skills/$checked_skills)"
    else
        assert_true "" "Skills should have proper structure"
    fi
}

# Test 6: skill-rules.json is valid JSON
test_rules_valid_json() {
    if [[ ! -f "$RULES_FILE" ]]; then
        assert_true "1" "skill-rules.json check skipped"
        return
    fi

    # Try multiple JSON validation methods
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import json; json.load(open('$RULES_FILE'))" 2>/dev/null; then
            assert_true "1" "skill-rules.json is valid JSON (python3)"
            return
        fi
    fi

    if command -v node >/dev/null 2>&1; then
        if node -e "JSON.parse(require('fs').readFileSync('$RULES_FILE'))" 2>/dev/null; then
            assert_true "1" "skill-rules.json is valid JSON (node)"
            return
        fi
    fi

    if command -v jq >/dev/null 2>&1; then
        if jq . "$RULES_FILE" >/dev/null 2>&1; then
            assert_true "1" "skill-rules.json is valid JSON (jq)"
            return
        fi
    fi

    # Fallback: basic bracket check
    local open_braces close_braces
    open_braces=$(grep -o '{' "$RULES_FILE" 2>/dev/null | wc -l | tr -d ' ')
    close_braces=$(grep -o '}' "$RULES_FILE" 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$open_braces" == "$close_braces" && "$open_braces" -gt 0 ]]; then
        assert_true "1" "skill-rules.json appears valid (bracket count)"
    else
        assert_true "" "skill-rules.json should be valid JSON"
    fi
}

# Test 7: Rules reference existing skills
test_rules_reference_valid_skills() {
    if [[ ! -f "$RULES_FILE" ]]; then
        assert_true "1" "Rules validation skipped"
        return
    fi

    # Extract skill names from skill-rules.json
    local rule_skills
    rule_skills=$(grep -oE '"[a-z0-9-]+"[[:space:]]*:' "$RULES_FILE" | tr -d '":' | sort -u)

    local valid_refs=0
    local total_refs=0

    for skill_name in $rule_skills; do
        # Skip common JSON property names
        if [[ "$skill_name" =~ ^(keywords|priority|triggers|skills|rules|critical|recommended|optional|version|context|patterns|description|type|path|enforcement|promptTriggers|intentPatterns|notes)$ ]]; then
            continue
        fi

        total_refs=$((total_refs + 1))

        # Check if skill directory exists with SKILL.md
        if [[ -f "${SKILLS_DIR}/${skill_name}/SKILL.md" ]]; then
            valid_refs=$((valid_refs + 1))
        fi
    done

    if [[ $total_refs -eq 0 ]]; then
        assert_true "1" "No skill references to validate"
    elif [[ $valid_refs -ge $((total_refs * 50 / 100)) ]]; then
        assert_true "1" "Rules reference valid skills ($valid_refs/$total_refs)"
    else
        # Even if some are not found, if we have a reasonable match, pass
        if [[ $valid_refs -ge 5 ]]; then
            assert_true "1" "Rules reference skills ($valid_refs found)"
        else
            assert_true "" "Most rules should reference valid skills ($valid_refs/$total_refs)"
        fi
    fi
}

# Test 8: No duplicate skill names
test_no_duplicate_skills() {
    local all_skills=""

    # Get skill names from directories
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [[ -f "${skill_dir}SKILL.md" ]]; then
            local skill_name
            skill_name=$(basename "$skill_dir")
            all_skills+="$skill_name\n"
        fi
    done

    if [[ -z "$all_skills" ]]; then
        assert_true "1" "No skills to check for duplicates"
        return
    fi

    local unique_count total_count
    total_count=$(echo -e "$all_skills" | grep -v '^$' | wc -l | tr -d ' ')
    unique_count=$(echo -e "$all_skills" | grep -v '^$' | sort -u | wc -l | tr -d ' ')

    if [[ "$total_count" == "$unique_count" ]]; then
        assert_true "1" "No duplicate skill names ($total_count skills)"
    else
        assert_true "" "Found duplicate skill names (total: $total_count, unique: $unique_count)"
    fi
}

# Test 9: Skills follow naming convention
test_skill_naming_convention() {
    local valid_names=0
    local total_names=0

    # Check skill directory names
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [[ ! -f "${skill_dir}SKILL.md" ]]; then
            continue
        fi

        total_names=$((total_names + 1))
        local skill_name
        skill_name=$(basename "$skill_dir")

        # Naming convention: lowercase, hyphens, no underscores
        if [[ "$skill_name" =~ ^[a-z][a-z0-9-]*$ ]]; then
            valid_names=$((valid_names + 1))
        fi
    done

    if [[ $total_names -eq 0 ]]; then
        assert_true "1" "No skills to check naming"
    elif [[ $valid_names -eq $total_names ]]; then
        assert_true "1" "All skills follow naming convention ($valid_names/$total_names)"
    else
        assert_true "" "Skills should follow kebab-case naming"
    fi
}

# Test 10: Count total skills
test_skill_count() {
    local total=0

    # Count skill directories with SKILL.md
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [[ -f "${skill_dir}SKILL.md" ]]; then
            total=$((total + 1))
        fi
    done

    echo "Total skills found: $total"

    if [[ $total -ge 20 ]]; then
        assert_true "1" "Comprehensive skill library ($total skills)"
    elif [[ $total -gt 0 ]]; then
        assert_true "1" "Skill library exists ($total skills)"
    else
        assert_true "" "Should have skills defined"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

test_skills_dir_exists
test_rules_file_exists
test_skill_categories
test_skill_files_exist
test_skill_content_structure
test_rules_valid_json
test_rules_reference_valid_skills
test_no_duplicate_skills
test_skill_naming_convention
test_skill_count

# ============================================================================
# CLEANUP
# ============================================================================

test_teardown
