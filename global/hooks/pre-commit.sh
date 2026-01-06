#!/usr/bin/env bash
# Hook: pre-commit
# Event: PreToolUse (Bash tool with git commit commands)
# Purpose: Verification before commits - check for issues, enforce standards

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize hook
init_hook "pre-commit"

# ============================================================================
# CONFIGURATION
# ============================================================================

# Files that should never be committed
BLOCKED_FILES=(
    ".env"
    ".env.local"
    ".env.production"
    "credentials.json"
    "secrets.json"
    "*.pem"
    "*.key"
    "id_rsa"
    "id_ed25519"
    ".npmrc"  # May contain auth tokens
)

# Patterns that indicate sensitive content
SENSITIVE_PATTERNS=(
    "password="
    "api_key="
    "apikey="
    "secret="
    "token="
    "private_key"
    "AWS_ACCESS_KEY"
    "AWS_SECRET"
    "GITHUB_TOKEN"
    "OPENAI_API_KEY"
    "ANTHROPIC_API_KEY"
)

# Required commit message components
MIN_MESSAGE_LENGTH=10
MAX_MESSAGE_LENGTH=500

# ============================================================================
# FUNCTIONS
# ============================================================================

# Check if command is a git commit
is_git_commit() {
    local command="$1"
    echo "$command" | grep -qE "git\s+commit" 2>/dev/null
}

# Check if command is a git add
is_git_add() {
    local command="$1"
    echo "$command" | grep -qE "git\s+add" 2>/dev/null
}

# Extract commit message from command
extract_commit_message() {
    local command="$1"

    # Try to extract -m "message" or -m 'message'
    local message
    message=$(echo "$command" | grep -oE '\-m\s+["\047][^"\047]+["\047]' | sed 's/-m\s*["\047]\(.*\)["\047]/\1/' || echo "")

    if [[ -z "$message" ]]; then
        # Try heredoc format
        message=$(echo "$command" | grep -oE "<<['\"]?EOF.*EOF" | head -1 || echo "")
    fi

    echo "$message"
}

# Check for blocked files in staged changes
check_blocked_files() {
    local blocked_found=""

    # Get list of staged files
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null || echo "")

    if [[ -z "$staged_files" ]]; then
        return 0
    fi

    for pattern in "${BLOCKED_FILES[@]}"; do
        local matches
        matches=$(echo "$staged_files" | grep -E "$pattern" 2>/dev/null || echo "")
        if [[ -n "$matches" ]]; then
            blocked_found+="$matches\n"
        fi
    done

    if [[ -n "$blocked_found" ]]; then
        echo -e "$blocked_found"
        return 1
    fi

    return 0
}

# Check for sensitive content in staged changes
check_sensitive_content() {
    local sensitive_found=""

    # Get staged diff
    local diff_content
    diff_content=$(git diff --cached 2>/dev/null || echo "")

    if [[ -z "$diff_content" ]]; then
        return 0
    fi

    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if echo "$diff_content" | grep -qiE "$pattern" 2>/dev/null; then
            sensitive_found+="Potential sensitive content: $pattern\n"
        fi
    done

    if [[ -n "$sensitive_found" ]]; then
        echo -e "$sensitive_found"
        return 1
    fi

    return 0
}

# Validate commit message format
validate_commit_message() {
    local message="$1"
    local issues=""

    if [[ -z "$message" ]]; then
        echo "Could not extract commit message for validation"
        return 0  # Allow - might be using --amend or other format
    fi

    # Check minimum length
    if [[ ${#message} -lt $MIN_MESSAGE_LENGTH ]]; then
        issues+="Commit message too short (min $MIN_MESSAGE_LENGTH chars)\n"
    fi

    # Check maximum length
    if [[ ${#message} -gt $MAX_MESSAGE_LENGTH ]]; then
        issues+="Commit message too long (max $MAX_MESSAGE_LENGTH chars)\n"
    fi

    # Check for generic messages
    local generic_patterns=("fix" "update" "change" "wip" "test" "asdf" "temp")
    local message_lower
    message_lower=$(echo "$message" | tr '[:upper:]' '[:lower:]')

    for pattern in "${generic_patterns[@]}"; do
        if [[ "$message_lower" == "$pattern" ]]; then
            issues+="Commit message too generic: '$message'\n"
            break
        fi
    done

    if [[ -n "$issues" ]]; then
        echo -e "$issues"
        return 1
    fi

    return 0
}

# Check if committing to protected branch
check_protected_branch() {
    local current_branch
    current_branch=$(get_current_branch)

    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        # Allow if bypass is enabled
        if bypass_enabled "JARVIS_ALLOW_MAIN_COMMITS"; then
            log_info "Main branch commit allowed via bypass"
            return 0
        fi

        # Allow if in worktree or conductor session
        if is_worktree || is_conductor_session; then
            return 0
        fi

        echo "Direct commits to $current_branch branch are discouraged. Use a feature branch."
        return 1
    fi

    return 0
}

# Run project-specific pre-commit hooks if they exist
run_project_hooks() {
    local project_hook=".claude/hooks/pre-commit.sh"

    if [[ -f "$project_hook" && -x "$project_hook" ]]; then
        log_info "Running project-specific pre-commit hook"
        if ! "$project_hook"; then
            echo "Project pre-commit hook failed"
            return 1
        fi
    fi

    # Also check for standard git hooks
    local git_hook=".git/hooks/pre-commit"
    if [[ -f "$git_hook" && -x "$git_hook" ]]; then
        log_info "Git pre-commit hook exists (will run on actual commit)"
    fi

    return 0
}

# Generate pre-commit summary
generate_summary() {
    local warnings=""
    local errors=""

    # Check for uncommitted changes summary
    local staged_count
    local unstaged_count
    staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    unstaged_count=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')

    echo "Pre-commit Check Summary:"
    echo "  Staged files: $staged_count"
    echo "  Unstaged changes: $unstaged_count"

    if [[ $unstaged_count -gt 0 ]]; then
        warnings+="Warning: $unstaged_count files with unstaged changes will not be committed\n"
    fi

    # Return warnings if any
    if [[ -n "$warnings" ]]; then
        echo -e "\n$warnings"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "Pre-commit verification started"

    # Read input from stdin
    local input
    input=$(cat)

    if [[ -z "$input" ]]; then
        log_debug "No input received"
        exit 0
    fi

    # Parse command from input
    local command
    command=$(parse_command "$input")

    if [[ -z "$command" ]]; then
        log_debug "No command in input"
        exit 0
    fi

    # Check if this is a git commit command
    if ! is_git_commit "$command"; then
        # Not a commit command, allow
        log_debug "Not a git commit command, passing through"
        exit 0
    fi

    log_info "Git commit detected, running verification"

    local all_issues=""
    local has_blocking_issues=false

    # 1. Check protected branch
    local branch_check
    if ! branch_check=$(check_protected_branch); then
        all_issues+="BRANCH PROTECTION:\n$branch_check\n\n"
        # This is a warning, not blocking
    fi

    # 2. Check for blocked files
    local blocked_files
    if ! blocked_files=$(check_blocked_files); then
        all_issues+="BLOCKED FILES DETECTED:\n$blocked_files\n"
        all_issues+="These files should not be committed. Remove them from staging.\n\n"
        has_blocking_issues=true
    fi

    # 3. Check for sensitive content
    local sensitive_content
    if ! sensitive_content=$(check_sensitive_content); then
        all_issues+="SENSITIVE CONTENT WARNING:\n$sensitive_content\n"
        all_issues+="Review staged changes for potential secrets.\n\n"
        # Warning only, not blocking
    fi

    # 4. Validate commit message
    local commit_message
    commit_message=$(extract_commit_message "$command")
    local message_issues
    if ! message_issues=$(validate_commit_message "$commit_message"); then
        all_issues+="COMMIT MESSAGE ISSUES:\n$message_issues\n"
        # Warning only, not blocking
    fi

    # 5. Run project hooks
    local project_hook_result
    if ! project_hook_result=$(run_project_hooks); then
        all_issues+="PROJECT HOOK FAILED:\n$project_hook_result\n\n"
        has_blocking_issues=true
    fi

    # Output results
    if [[ -n "$all_issues" ]]; then
        if [[ "$has_blocking_issues" == true ]]; then
            log_warn "Blocking issues found in pre-commit check"
            output_block "Pre-commit verification failed:\n\n$all_issues"
            finalize_hook 1
            exit 1
        else
            # Just output warnings as context
            log_info "Pre-commit warnings found (non-blocking)"
            echo "Pre-commit Verification Warnings:"
            echo "=================================="
            echo -e "$all_issues"
            echo "Proceeding with commit..."
        fi
    else
        log_info "Pre-commit verification passed"
        generate_summary
    fi

    finalize_hook 0
    exit 0
}

# Run main function
main
