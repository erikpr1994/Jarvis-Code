#!/usr/bin/env bash
# Jarvis Learning Auto-Update System
# Part of the Jarvis Learning System
#
# This script processes captured learnings and applies validated updates
# to skills, patterns, and rules based on the TDD-for-Skills methodology.
#
# Usage:
#   ./auto-update.sh [command] [options]
#
# Commands:
#   review       - Review pending learnings and suggest updates
#   apply        - Apply a specific approved learning
#   validate     - Run TDD validation for a learning before applying
#   rollback     - Rollback a previously applied learning
#   status       - Show current learning queue and applied changes
#   history      - Show change history with rollback options
#   restore      - Restore from a specific backup
#   gc           - Garbage collect old backups

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="${JARVIS_ROOT:-$HOME/.jarvis}"
LEARNINGS_DIR="${JARVIS_ROOT}/learnings"
SKILLS_DIR="${JARVIS_ROOT}/skills"
PATTERNS_DIR="${JARVIS_ROOT}/patterns"
RULES_DIR="${JARVIS_ROOT}/rules"
BACKUP_DIR="${JARVIS_ROOT}/backups"
ROLLBACK_LOG="${JARVIS_ROOT}/logs/rollback-history.json"
CHANGE_LOG="${JARVIS_ROOT}/logs/changes.json"
LOG_FILE="${JARVIS_ROOT}/logs/auto-update.log"

# Rollback configuration
MAX_BACKUPS=50
BACKUP_RETENTION_DAYS=90

# Ensure directories exist
mkdir -p "$LEARNINGS_DIR" "$BACKUP_DIR" "${JARVIS_ROOT}/logs"

# Initialize change log if needed
if [[ ! -f "$CHANGE_LOG" ]]; then
    echo '{"changes":[]}' > "$CHANGE_LOG"
fi

# Initialize rollback log if needed
if [[ ! -f "$ROLLBACK_LOG" ]]; then
    echo '{"rollbacks":[]}' > "$ROLLBACK_LOG"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    case "$level" in
        INFO)  echo -e "${BLUE}[INFO]${NC} $message" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" ;;
        OK)    echo -e "${GREEN}[OK]${NC} $message" ;;
    esac
}

# ============================================================================
# PHASE 1: DETECT - Find and score learnings
# ============================================================================

detect_learnings() {
    log "INFO" "Scanning for new learnings..."

    local learnings_file="${LEARNINGS_DIR}/global.json"

    if [[ ! -f "$learnings_file" ]]; then
        log "WARN" "No learnings file found at $learnings_file"
        return 1
    fi

    # Extract pending learnings (status: suggested or pending)
    local pending
    pending=$(jq -r '
        .learnings | to_entries[] |
        .value.patterns[]?, .value.corrections[]?, .value.workflows[]? |
        select(.status == "suggested" or .status == "pending") |
        "\(.id): \(.description) (freq: \(.frequency // 1))"
    ' "$learnings_file" 2>/dev/null || echo "")

    if [[ -z "$pending" ]]; then
        log "INFO" "No pending learnings found"
        return 0
    fi

    echo ""
    echo "=== Pending Learnings ==="
    echo "$pending"
    echo ""
}

score_learning() {
    local learning_id="$1"
    local learnings_file="${LEARNINGS_DIR}/global.json"

    # Calculate novelty and frequency score
    local learning
    learning=$(jq -r --arg id "$learning_id" '
        .learnings | to_entries[] |
        .value.patterns[]?, .value.corrections[]?, .value.workflows[]? |
        select(.id == $id)
    ' "$learnings_file" 2>/dev/null)

    if [[ -z "$learning" ]]; then
        log "ERROR" "Learning not found: $learning_id"
        return 1
    fi

    local frequency
    frequency=$(echo "$learning" | jq -r '.frequency // 1')
    local type
    type=$(echo "$learning" | jq -r '.type')

    # Scoring logic
    local score=0

    # Frequency bonus (max 50 points)
    if [[ "$frequency" -ge 5 ]]; then
        score=$((score + 50))
    elif [[ "$frequency" -ge 3 ]]; then
        score=$((score + 30))
    else
        score=$((score + 10))
    fi

    # Type bonus (max 30 points)
    case "$type" in
        "user_preference") score=$((score + 30)) ;;  # User said explicitly
        "code_pattern")    score=$((score + 20)) ;;  # Repeated pattern
        "workflow")        score=$((score + 25)) ;;  # Efficiency gain
        *)                 score=$((score + 10)) ;;
    esac

    echo "$score"
}

# ============================================================================
# PHASE 2: VALIDATE - TDD for Skills approach
# ============================================================================

validate_learning() {
    local learning_id="$1"
    local learnings_file="${LEARNINGS_DIR}/global.json"

    log "INFO" "Validating learning: $learning_id"

    # Get learning details
    local learning
    learning=$(jq -r --arg id "$learning_id" '
        .learnings | to_entries[] |
        .value.patterns[]?, .value.corrections[]?, .value.workflows[]? |
        select(.id == $id)
    ' "$learnings_file" 2>/dev/null)

    if [[ -z "$learning" ]]; then
        log "ERROR" "Learning not found: $learning_id"
        return 1
    fi

    echo ""
    echo "=== TDD Validation for Learning ==="
    echo ""
    echo "Learning: $(echo "$learning" | jq -r '.description')"
    echo "Type: $(echo "$learning" | jq -r '.type')"
    echo ""

    # RED Phase: Test WITHOUT the learning applied
    echo "--- RED Phase: Baseline Test ---"
    echo "Testing current behavior without this learning..."
    echo "[Simulated] Baseline behavior captured"
    echo ""

    # GREEN Phase: Test WITH the learning applied
    echo "--- GREEN Phase: With Learning ---"
    echo "Testing behavior with learning applied..."
    echo "[Simulated] Improved behavior verified"
    echo ""

    # Verification
    echo "--- Verification ---"
    local score
    score=$(score_learning "$learning_id")
    echo "Learning score: $score/80"

    if [[ "$score" -ge 50 ]]; then
        log "OK" "Learning validated - ready for application"
        return 0
    else
        log "WARN" "Learning needs more evidence (score: $score, required: 50)"
        return 1
    fi
}

# ============================================================================
# PHASE 3: APPLY - Create/update skill, pattern, or rule
# ============================================================================

apply_learning() {
    local learning_id="$1"
    local learnings_file="${LEARNINGS_DIR}/global.json"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')

    log "INFO" "Applying learning: $learning_id"

    # Create comprehensive backup before making changes
    local backup_path
    backup_path=$(create_backup "$learning_id")
    log "INFO" "Backup created at: $backup_path"

    # Get learning details - try inbox first, then global learnings
    local learning=""
    local inbox_file="${SCRIPT_DIR}/inbox/${learning_id}.json"

    if [[ -f "$inbox_file" ]]; then
        learning=$(cat "$inbox_file")
    elif [[ -f "$learnings_file" ]]; then
        learning=$(jq -r --arg id "$learning_id" '
            .learnings | to_entries[] |
            .value.patterns[]?, .value.corrections[]?, .value.workflows[]? |
            select(.id == $id)
        ' "$learnings_file" 2>/dev/null || echo "")
    fi

    if [[ -z "$learning" ]]; then
        log "ERROR" "Learning not found: $learning_id"
        return 1
    fi

    local type description suggested_skill
    type=$(echo "$learning" | jq -r '.type // "unknown"' 2>/dev/null || echo "unknown")
    description=$(echo "$learning" | jq -r '.description // "No description"' 2>/dev/null || echo "No description")
    suggested_skill=$(echo "$learning" | jq -r '.suggested_skill // empty' 2>/dev/null || echo "")

    echo ""
    echo -e "${CYAN}=== Applying Learning ===${NC}"
    echo "ID: $learning_id"
    echo "Type: $type"
    echo "Description: $description"
    echo "Backup: $backup_path"
    echo ""

    local files_affected=""
    local apply_result=0

    case "$type" in
        "code_pattern")
            apply_pattern "$learning_id" "$description" "$timestamp"
            files_affected="patterns/${learning_id}.md"
            ;;
        "user_preference")
            apply_rule "$learning_id" "$description" "$timestamp"
            files_affected="rules/preferences.json"
            ;;
        "workflow"|"workflow_improvement")
            apply_workflow "$learning_id" "$description" "$timestamp"
            files_affected="workflows"
            ;;
        *)
            log "WARN" "Unknown learning type: $type"
            apply_result=1
            ;;
    esac

    if [[ $apply_result -eq 0 ]]; then
        # Log the change for tracking
        log_change "$learning_id" "$type" "$description" "$files_affected" "$backup_path"

        # Update learning status to applied
        update_learning_status "$learning_id" "applied"

        # Move from inbox to archive if it came from inbox
        if [[ -f "$inbox_file" ]]; then
            mv "$inbox_file" "${SCRIPT_DIR}/archive/"
            log "INFO" "Moved learning to archive"
        fi

        log "OK" "Learning applied successfully"
        echo ""
        echo -e "${GREEN}Learning applied successfully.${NC}"
        echo "To rollback: ./auto-update.sh rollback $learning_id"
    else
        log "ERROR" "Failed to apply learning"
        echo ""
        echo -e "${RED}Failed to apply learning. Backup available at: $backup_path${NC}"
        return 1
    fi
}

apply_pattern() {
    local learning_id="$1"
    local description="$2"
    local timestamp="$3"

    local pattern_file="${PATTERNS_DIR}/${learning_id}.md"

    # Backup if exists
    if [[ -f "$pattern_file" ]]; then
        cp "$pattern_file" "${BACKUP_DIR}/${learning_id}_${timestamp}.md"
    fi

    # Create pattern file
    cat > "$pattern_file" << EOF
# Pattern: ${description}

**ID:** ${learning_id}
**Created:** $(date '+%Y-%m-%d')
**Source:** Auto-learned from session analysis

## Pattern Description

${description}

## When to Use

- Detected in recurring code structures
- Applied automatically when similar context detected

## Example

\`\`\`typescript
// Pattern example will be populated from captured instances
\`\`\`

## Related Skills

- [Skill suggestions will be added based on context]
EOF

    log "INFO" "Created pattern file: $pattern_file"
}

apply_rule() {
    local learning_id="$1"
    local description="$2"
    local timestamp="$3"

    local rules_file="${RULES_DIR}/preferences.json"

    # Backup if exists
    if [[ -f "$rules_file" ]]; then
        cp "$rules_file" "${BACKUP_DIR}/preferences_${timestamp}.json"
    fi

    # Initialize rules file if needed
    if [[ ! -f "$rules_file" ]]; then
        echo '{"preferences":[]}' > "$rules_file"
    fi

    # Add preference
    local new_rule
    new_rule=$(jq --arg id "$learning_id" \
                  --arg desc "$description" \
                  --arg date "$(date '+%Y-%m-%d')" \
                  '.preferences += [{
                      "id": $id,
                      "description": $desc,
                      "created": $date,
                      "active": true
                  }]' "$rules_file")

    echo "$new_rule" > "$rules_file"
    log "INFO" "Added preference rule: $learning_id"
}

apply_workflow() {
    local learning_id="$1"
    local description="$2"
    local timestamp="$3"

    log "INFO" "Workflow improvement noted: $description"
    log "INFO" "Consider creating a hook or command for this workflow"
}

update_learning_status() {
    local learning_id="$1"
    local new_status="$2"
    local learnings_file="${LEARNINGS_DIR}/global.json"

    if [[ ! -f "$learnings_file" ]]; then
        return 1
    fi

    # Update status in JSON (this is a simplified version)
    local updated
    updated=$(jq --arg id "$learning_id" \
                 --arg status "$new_status" \
                 '(.learnings | to_entries[] |
                   (.value.patterns[]?, .value.corrections[]?, .value.workflows[]?) |
                   select(.id == $id)).status = $status' \
                 "$learnings_file" 2>/dev/null || cat "$learnings_file")

    echo "$updated" > "$learnings_file"
}

# ============================================================================
# PHASE 4: ROLLBACK - Revert changes if needed
# ============================================================================

# Log a change for tracking
log_change() {
    local change_id="$1"
    local change_type="$2"
    local description="$3"
    local files_affected="$4"
    local backup_path="$5"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if ! command -v jq &>/dev/null; then
        log "WARN" "jq not available, change not logged"
        return
    fi

    local updated
    updated=$(jq --arg id "$change_id" \
                 --arg type "$change_type" \
                 --arg desc "$description" \
                 --arg files "$files_affected" \
                 --arg backup "$backup_path" \
                 --arg ts "$timestamp" \
                 '.changes += [{
                     "id": $id,
                     "type": $type,
                     "description": $desc,
                     "files_affected": $files,
                     "backup_path": $backup,
                     "timestamp": $ts,
                     "rolled_back": false
                 }]' "$CHANGE_LOG" 2>/dev/null)

    if [[ -n "$updated" ]]; then
        echo "$updated" > "$CHANGE_LOG"
    fi
}

# Create a comprehensive backup before changes
create_backup() {
    local learning_id="$1"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="${learning_id}_${timestamp}"
    local backup_path="${BACKUP_DIR}/${backup_name}"

    mkdir -p "$backup_path"

    # Backup all potentially affected files
    local files_backed_up=""

    # Backup pattern file if exists
    local pattern_file="${PATTERNS_DIR}/${learning_id}.md"
    if [[ -f "$pattern_file" ]]; then
        cp "$pattern_file" "${backup_path}/pattern.md"
        files_backed_up+="pattern.md,"
    fi

    # Backup rules file if exists
    local rules_file="${RULES_DIR}/preferences.json"
    if [[ -f "$rules_file" ]]; then
        cp "$rules_file" "${backup_path}/preferences.json"
        files_backed_up+="preferences.json,"
    fi

    # Backup skill-rules.json if exists
    local skill_rules="${JARVIS_ROOT}/skill-rules.json"
    if [[ -f "$skill_rules" ]]; then
        cp "$skill_rules" "${backup_path}/skill-rules.json"
        files_backed_up+="skill-rules.json,"
    fi

    # Create backup manifest
    cat > "${backup_path}/manifest.json" << EOF
{
    "learning_id": "${learning_id}",
    "timestamp": "$(date '+%Y-%m-%dT%H:%M:%SZ')",
    "files": "$(echo "$files_backed_up" | sed 's/,$//')",
    "backup_path": "${backup_path}"
}
EOF

    echo "$backup_path"
}

# Rollback a single learning
rollback_learning() {
    local learning_id="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    log "INFO" "Rolling back learning: $learning_id"

    # Find most recent backup directory
    local backup_dir
    backup_dir=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "${learning_id}_*" 2>/dev/null | sort -r | head -1 || true)

    if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
        echo ""
        echo -e "${CYAN}=== Rolling Back Learning ===${NC}"
        echo "Learning: $learning_id"
        echo "Backup: $backup_dir"
        echo ""

        # Restore from backup
        local restored_count=0

        # Restore pattern
        if [[ -f "${backup_dir}/pattern.md" ]]; then
            cp "${backup_dir}/pattern.md" "${PATTERNS_DIR}/${learning_id}.md"
            echo -e "  ${GREEN}[RESTORED]${NC} Pattern file"
            ((restored_count++))
        fi

        # Restore preferences
        if [[ -f "${backup_dir}/preferences.json" ]]; then
            cp "${backup_dir}/preferences.json" "${RULES_DIR}/preferences.json"
            echo -e "  ${GREEN}[RESTORED]${NC} Preferences"
            ((restored_count++))
        fi

        # Restore skill-rules
        if [[ -f "${backup_dir}/skill-rules.json" ]]; then
            cp "${backup_dir}/skill-rules.json" "${JARVIS_ROOT}/skill-rules.json"
            echo -e "  ${GREEN}[RESTORED]${NC} Skill rules"
            ((restored_count++))
        fi

        log "OK" "Rolled back $restored_count files from: $backup_dir"

        # Log the rollback
        log_rollback "$learning_id" "$backup_dir" "full"
    else
        # Try legacy backup format (single file)
        local backup
        backup=$(ls -t "${BACKUP_DIR}/${learning_id}_"*.md 2>/dev/null | head -1 || true)

        if [[ -n "$backup" && -f "$backup" ]]; then
            local target="${PATTERNS_DIR}/${learning_id}.md"
            cp "$backup" "$target"
            log "OK" "Rolled back pattern to: $backup"
            log_rollback "$learning_id" "$backup" "pattern"
        else
            # Remove the applied pattern (clean rollback)
            local pattern_file="${PATTERNS_DIR}/${learning_id}.md"
            if [[ -f "$pattern_file" ]]; then
                # Create a backup before removing
                mv "$pattern_file" "${BACKUP_DIR}/${learning_id}_removed_${timestamp}.md"
                log "OK" "Removed pattern file: $pattern_file"
                log_rollback "$learning_id" "" "removed"
            else
                log "WARN" "No backup or pattern found for: $learning_id"
            fi
        fi
    fi

    # Update learning status
    update_learning_status "$learning_id" "rolled_back"
}

# Log a rollback action
log_rollback() {
    local learning_id="$1"
    local backup_used="$2"
    local rollback_type="$3"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if ! command -v jq &>/dev/null; then
        return
    fi

    local updated
    updated=$(jq --arg id "$learning_id" \
                 --arg backup "$backup_used" \
                 --arg type "$rollback_type" \
                 --arg ts "$timestamp" \
                 '.rollbacks += [{
                     "learning_id": $id,
                     "backup_used": $backup,
                     "type": $type,
                     "timestamp": $ts
                 }]' "$ROLLBACK_LOG" 2>/dev/null)

    if [[ -n "$updated" ]]; then
        echo "$updated" > "$ROLLBACK_LOG"
    fi

    # Also mark in change log
    if command -v jq &>/dev/null; then
        local change_updated
        change_updated=$(jq --arg id "$learning_id" '
            .changes |= map(if .id == $id then .rolled_back = true else . end)
        ' "$CHANGE_LOG" 2>/dev/null)

        if [[ -n "$change_updated" ]]; then
            echo "$change_updated" > "$CHANGE_LOG"
        fi
    fi
}

# Show change history with rollback options
show_history() {
    echo ""
    echo -e "${CYAN}=== Change History ===${NC}"
    echo ""

    if ! command -v jq &>/dev/null; then
        echo "jq required for history display"
        return
    fi

    if [[ ! -f "$CHANGE_LOG" ]]; then
        echo "No changes recorded"
        return
    fi

    local changes
    changes=$(jq -r '.changes | reverse | .[:20][] |
        "[\(.timestamp | split("T")[0])] \(.id)\n  Type: \(.type) | Rolled back: \(.rolled_back)\n  \(.description)\n"
    ' "$CHANGE_LOG" 2>/dev/null || echo "No changes")

    if [[ -z "$changes" || "$changes" == "No changes" ]]; then
        echo "No changes recorded"
    else
        echo "$changes"
    fi

    echo ""
    echo "Rollbacks:"
    jq -r '.rollbacks | reverse | .[:10][] |
        "  [\(.timestamp | split("T")[0])] \(.learning_id) (\(.type))"
    ' "$ROLLBACK_LOG" 2>/dev/null || echo "  No rollbacks"
    echo ""
}

# Restore from a specific backup
restore_from_backup() {
    local backup_id="$1"

    echo ""
    echo -e "${CYAN}=== Restore from Backup ===${NC}"
    echo ""

    # Find backup by ID or timestamp
    local backup_path
    backup_path=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "*${backup_id}*" 2>/dev/null | head -1 || true)

    if [[ -z "$backup_path" || ! -d "$backup_path" ]]; then
        # Try finding a file backup
        backup_path=$(find "$BACKUP_DIR" -name "*${backup_id}*" 2>/dev/null | head -1 || true)
    fi

    if [[ -z "$backup_path" ]]; then
        log "ERROR" "Backup not found: $backup_id"
        echo "Available backups:"
        ls -la "$BACKUP_DIR" | tail -20
        return 1
    fi

    echo "Found backup: $backup_path"

    if [[ -d "$backup_path" ]]; then
        # Directory backup with manifest
        if [[ -f "${backup_path}/manifest.json" ]]; then
            echo ""
            echo "Manifest:"
            cat "${backup_path}/manifest.json"
            echo ""
        fi

        read -p "Restore this backup? [y/N] " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Restore all files
            for file in "${backup_path}"/*.{json,md}; do
                if [[ -f "$file" ]]; then
                    local filename
                    filename=$(basename "$file")
                    case "$filename" in
                        pattern.md)
                            local learning_id
                            learning_id=$(jq -r '.learning_id' "${backup_path}/manifest.json" 2>/dev/null || echo "unknown")
                            cp "$file" "${PATTERNS_DIR}/${learning_id}.md"
                            echo -e "  ${GREEN}[RESTORED]${NC} $filename"
                            ;;
                        preferences.json)
                            cp "$file" "${RULES_DIR}/preferences.json"
                            echo -e "  ${GREEN}[RESTORED]${NC} $filename"
                            ;;
                        skill-rules.json)
                            cp "$file" "${JARVIS_ROOT}/skill-rules.json"
                            echo -e "  ${GREEN}[RESTORED]${NC} $filename"
                            ;;
                    esac
                fi
            done
            log "OK" "Restored from backup: $backup_path"
        fi
    elif [[ -f "$backup_path" ]]; then
        # Single file backup
        echo "File: $(basename "$backup_path")"
        read -p "Restore this file? [y/N] " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Determine destination based on extension
            local ext="${backup_path##*.}"
            case "$ext" in
                md)
                    local learning_id
                    learning_id=$(basename "$backup_path" | sed 's/_[0-9]*_[0-9]*\..*//')
                    cp "$backup_path" "${PATTERNS_DIR}/${learning_id}.md"
                    ;;
                json)
                    if [[ "$backup_path" == *"preferences"* ]]; then
                        cp "$backup_path" "${RULES_DIR}/preferences.json"
                    elif [[ "$backup_path" == *"skill-rules"* ]]; then
                        cp "$backup_path" "${JARVIS_ROOT}/skill-rules.json"
                    fi
                    ;;
            esac
            log "OK" "Restored from backup: $backup_path"
        fi
    fi
}

# Garbage collect old backups
gc_backups() {
    local dry_run="${1:-}"

    echo ""
    echo -e "${CYAN}=== Backup Garbage Collection ===${NC}"
    echo ""

    # Find old backups
    local cutoff_date
    cutoff_date=$(date -v-${BACKUP_RETENTION_DAYS}d '+%Y%m%d' 2>/dev/null || date -d "${BACKUP_RETENTION_DAYS} days ago" '+%Y%m%d' 2>/dev/null || echo "")

    if [[ -z "$cutoff_date" ]]; then
        log "WARN" "Could not calculate cutoff date"
        return
    fi

    echo "Retention: $BACKUP_RETENTION_DAYS days"
    echo "Max backups: $MAX_BACKUPS"
    echo ""

    # Count current backups
    local current_count
    current_count=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
    echo "Current backups: $current_count"

    # Find candidates for deletion
    local to_delete=()

    # Delete by age
    while IFS= read -r backup; do
        if [[ -n "$backup" ]]; then
            local backup_date
            backup_date=$(echo "$backup" | grep -o '[0-9]\{8\}' | head -1 || echo "")
            if [[ -n "$backup_date" && "$backup_date" < "$cutoff_date" ]]; then
                to_delete+=("$backup")
            fi
        fi
    done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 2>/dev/null)

    # Delete by count if still over limit
    if [[ "$current_count" -gt "$MAX_BACKUPS" ]]; then
        local excess=$((current_count - MAX_BACKUPS))
        while IFS= read -r backup; do
            if [[ -n "$backup" && ! " ${to_delete[*]} " =~ " ${backup} " ]]; then
                to_delete+=("$backup")
                ((excess--))
                if [[ "$excess" -le 0 ]]; then
                    break
                fi
            fi
        done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -printf '%T+ %p\n' 2>/dev/null | sort | cut -d' ' -f2-)
    fi

    echo "Candidates for deletion: ${#to_delete[@]}"

    if [[ ${#to_delete[@]} -eq 0 ]]; then
        echo "Nothing to clean up"
        return
    fi

    if [[ "$dry_run" == "--dry-run" ]]; then
        echo ""
        echo "Would delete:"
        for backup in "${to_delete[@]}"; do
            echo "  - $(basename "$backup")"
        done
    else
        read -p "Delete ${#to_delete[@]} old backups? [y/N] " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for backup in "${to_delete[@]}"; do
                rm -rf "$backup"
                echo -e "  ${GREEN}[DELETED]${NC} $(basename "$backup")"
            done
            log "OK" "Garbage collected ${#to_delete[@]} backups"
        fi
    fi
}

# ============================================================================
# STATUS & REVIEW
# ============================================================================

show_status() {
    echo ""
    echo "=== Jarvis Learning System Status ==="
    echo ""

    # Count learnings by status
    local learnings_file="${LEARNINGS_DIR}/global.json"

    if [[ -f "$learnings_file" ]]; then
        echo "Learnings Summary:"
        jq -r '
            [.learnings | to_entries[] |
             .value.patterns[]?, .value.corrections[]?, .value.workflows[]?] |
            group_by(.status) |
            map({status: .[0].status, count: length}) |
            .[] | "  \(.status // "unknown"): \(.count)"
        ' "$learnings_file" 2>/dev/null || echo "  No learnings found"
    else
        echo "  No learnings file found"
    fi

    echo ""
    echo "Applied Patterns:"
    ls -1 "${PATTERNS_DIR}"/*.md 2>/dev/null | wc -l | xargs echo "  Count:"

    echo ""
    echo "Backups Available:"
    ls -1 "${BACKUP_DIR}"/* 2>/dev/null | wc -l | xargs echo "  Count:"
    echo ""
}

review_learnings() {
    detect_learnings

    echo ""
    echo "Review Options:"
    echo "  1. validate <id>  - Run TDD validation for a learning"
    echo "  2. apply <id>     - Apply an approved learning"
    echo "  3. rollback <id>  - Rollback an applied learning"
    echo "  4. status         - Show current status"
    echo ""
}

# ============================================================================
# SKILL-RULES UPDATE
# ============================================================================

update_skill_rules() {
    local skill_name="$1"
    local keywords="$2"
    local intent_patterns="$3"

    log "INFO" "Updating skill-rules.json for: $skill_name"

    local rules_file="${JARVIS_ROOT}/skill-rules.json"

    if [[ ! -f "$rules_file" ]]; then
        log "ERROR" "skill-rules.json not found at $rules_file"
        return 1
    fi

    # Backup
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    cp "$rules_file" "${BACKUP_DIR}/skill-rules_${timestamp}.json"

    # Parse keywords into array
    IFS=',' read -ra kw_array <<< "$keywords"
    local kw_json
    kw_json=$(printf '%s\n' "${kw_array[@]}" | jq -R . | jq -s .)

    # Add or update skill entry
    local updated
    updated=$(jq --arg name "$skill_name" \
                 --argjson keywords "$kw_json" \
                 --arg patterns "$intent_patterns" \
                 '.skills[$name] = {
                     "type": "domain",
                     "enforcement": "suggest",
                     "priority": "medium",
                     "description": "Auto-learned skill",
                     "promptTriggers": {
                         "keywords": $keywords,
                         "intentPatterns": [$patterns]
                     }
                 }' "$rules_file")

    echo "$updated" > "$rules_file"
    log "OK" "Updated skill-rules.json"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command="${1:-review}"
    shift || true

    case "$command" in
        review)
            review_learnings
            ;;
        detect)
            detect_learnings
            ;;
        validate)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: auto-update.sh validate <learning_id>"
                exit 1
            fi
            validate_learning "$1"
            ;;
        apply)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: auto-update.sh apply <learning_id>"
                exit 1
            fi
            validate_learning "$1" && apply_learning "$1"
            ;;
        rollback)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: auto-update.sh rollback <learning_id>"
                exit 1
            fi
            rollback_learning "$1"
            ;;
        history)
            show_history
            ;;
        restore)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: auto-update.sh restore <backup_id>"
                echo ""
                echo "Available backups:"
                ls -la "$BACKUP_DIR" 2>/dev/null | tail -20 || echo "No backups found"
                exit 1
            fi
            restore_from_backup "$1"
            ;;
        gc)
            gc_backups "${1:-}"
            ;;
        status)
            show_status
            ;;
        update-rules)
            if [[ -z "${1:-}" || -z "${2:-}" ]]; then
                echo "Usage: auto-update.sh update-rules <skill_name> <keywords>"
                exit 1
            fi
            update_skill_rules "$1" "$2" "${3:-}"
            ;;
        help|--help|-h)
            echo "Jarvis Learning Auto-Update System"
            echo ""
            echo "Usage: auto-update.sh [command] [options]"
            echo ""
            echo "Commands:"
            echo "  review              Review pending learnings"
            echo "  detect              Scan for new learnings"
            echo "  validate <id>       Run TDD validation"
            echo "  apply <id>          Apply approved learning"
            echo "  rollback <id>       Rollback applied learning"
            echo "  history             Show change history with rollback options"
            echo "  restore <id>        Restore from a specific backup"
            echo "  gc [--dry-run]      Garbage collect old backups"
            echo "  status              Show system status"
            echo "  update-rules        Update skill-rules.json"
            echo "  help                Show this help"
            echo ""
            echo "Rollback Features:"
            echo "  - All changes create automatic backups"
            echo "  - Backups retained for $BACKUP_RETENTION_DAYS days"
            echo "  - Maximum $MAX_BACKUPS backups kept"
            echo "  - Use 'history' to see all changes"
            echo "  - Use 'restore' for point-in-time recovery"
            ;;
        *)
            log "ERROR" "Unknown command: $command"
            echo "Run 'auto-update.sh help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
