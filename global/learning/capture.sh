#!/usr/bin/env bash
# Jarvis Learning Capture Processor
# Purpose: Process learning inbox and validate captured patterns
#
# This script:
# - Reads learnings from the inbox directory
# - Validates captured patterns against novelty and frequency criteria
# - Proposes skill/rule updates based on validated learnings
# - Requires confirmation before applying changes
#
# Usage:
#   ./capture.sh [command] [options]
#
# Commands:
#   process      Process all pending learnings in inbox
#   validate     Validate a specific learning
#   propose      Generate skill/rule proposals
#   confirm      Confirm and queue learning for application
#   reject       Reject a learning
#   status       Show inbox status

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="${JARVIS_ROOT:-$HOME/.jarvis}"
LEARNING_INBOX="${SCRIPT_DIR}/inbox"
LEARNING_ARCHIVE="${SCRIPT_DIR}/archive"
LEARNINGS_DIR="${JARVIS_ROOT}/learnings"
PROPOSALS_DIR="${LEARNINGS_DIR}/proposals"
LOG_FILE="${JARVIS_ROOT}/logs/capture.log"

# Memory tier configuration
WARM_PROMOTION_FREQUENCY=3
COLD_DEMOTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$LEARNING_INBOX" "$LEARNING_ARCHIVE" "$PROPOSALS_DIR" "${JARVIS_ROOT}/logs"

# ============================================================================
# LOGGING
# ============================================================================

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
# INBOX PROCESSING
# ============================================================================

# List all pending learnings in inbox
list_inbox() {
    echo ""
    echo -e "${CYAN}=== Learning Inbox ===${NC}"
    echo ""

    local count=0
    for file in "$LEARNING_INBOX"/*.json; do
        if [[ -f "$file" ]]; then
            $1=$(($1 + 1))
            local id type description frequency status
            if command -v jq &>/dev/null; then
                id=$(jq -r '.id // "unknown"' "$file" 2>/dev/null)
                type=$(jq -r '.type // "unknown"' "$file" 2>/dev/null)
                description=$(jq -r '.description // "No description"' "$file" 2>/dev/null)
                frequency=$(jq -r '.frequency // 0' "$file" 2>/dev/null)
                status=$(jq -r '.status // "pending"' "$file" 2>/dev/null)
            else
                id=$(basename "$file" .json)
                type="unknown"
                description="(jq required for details)"
                frequency="?"
                status="pending"
            fi

            local status_color="$YELLOW"
            case "$status" in
                validated) status_color="$GREEN" ;;
                rejected) status_color="$RED" ;;
                proposed) status_color="$CYAN" ;;
            esac

            echo -e "  ${BLUE}$count.${NC} [$id]"
            echo -e "     Type: $type | Frequency: $frequency | Status: ${status_color}$status${NC}"
            echo -e "     ${description:0:60}..."
            echo ""
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "  No pending learnings in inbox"
    else
        echo -e "  Total: ${CYAN}$count${NC} learnings"
    fi
    echo ""
}

# Process all learnings in inbox
process_inbox() {
    log "INFO" "Processing learning inbox..."

    local processed=0
    local validated=0
    local rejected=0

    for file in "$LEARNING_INBOX"/*.json; do
        if [[ -f "$file" ]]; then
            $1=$(($1 + 1))

            local learning_id
            learning_id=$(basename "$file" .json)

            # Validate the learning
            if validate_learning "$file"; then
                $1=$(($1 + 1))
                log "INFO" "Learning validated: $learning_id"
            else
                $1=$(($1 + 1))
                log "INFO" "Learning rejected: $learning_id"
            fi
        fi
    done

    echo ""
    echo -e "${CYAN}=== Processing Complete ===${NC}"
    echo -e "  Processed: $processed"
    echo -e "  Validated: ${GREEN}$validated${NC}"
    echo -e "  Rejected: ${YELLOW}$rejected${NC}"
    echo ""
}

# ============================================================================
# VALIDATION
# ============================================================================

# Validate a learning against criteria
validate_learning() {
    local file="$1"
    local learning_id
    learning_id=$(basename "$file" .json)

    if [[ ! -f "$file" ]]; then
        log "ERROR" "Learning file not found: $file"
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        log "WARN" "jq not available, skipping detailed validation"
        return 0
    fi

    local type frequency status
    type=$(jq -r '.type // "unknown"' "$file" 2>/dev/null)
    frequency=$(jq -r '.frequency // 0' "$file" 2>/dev/null)
    status=$(jq -r '.status // "pending"' "$file" 2>/dev/null)

    # Skip already processed
    if [[ "$status" == "validated" || "$status" == "rejected" || "$status" == "applied" ]]; then
        return 0
    fi

    echo ""
    echo -e "${CYAN}Validating: $learning_id${NC}"

    # Validation checks
    local passed=true
    local reasons=()

    # 1. Novelty Check - Is this already captured?
    if check_duplicate "$file"; then
        reasons+=("Duplicate of existing learning")
        passed=false
    else
        echo -e "  ${GREEN}[PASS]${NC} Novelty check - not a duplicate"
    fi

    # 2. Frequency Check - Has this occurred enough?
    if [[ "$frequency" -ge "$WARM_PROMOTION_FREQUENCY" ]]; then
        echo -e "  ${GREEN}[PASS]${NC} Frequency check - occurred $frequency times (threshold: $WARM_PROMOTION_FREQUENCY)"
    else
        reasons+=("Frequency too low: $frequency (need $WARM_PROMOTION_FREQUENCY)")
        # Don't fail for low frequency, just note it
        echo -e "  ${YELLOW}[NOTE]${NC} Low frequency - $frequency occurrences (consider waiting)"
    fi

    # 3. Type Check - Is the type valid?
    case "$type" in
        code_pattern|user_preference|workflow_improvement|skill_gap)
            echo -e "  ${GREEN}[PASS]${NC} Type check - valid type: $type"
            ;;
        *)
            reasons+=("Unknown learning type: $type")
            echo -e "  ${YELLOW}[WARN]${NC} Unknown type: $type"
            ;;
    esac

    # 4. Context Check - Does it have sufficient context?
    local has_context
    has_context=$(jq -r '.context // empty' "$file" 2>/dev/null)
    if [[ -n "$has_context" ]]; then
        echo -e "  ${GREEN}[PASS]${NC} Context check - context provided"
    else
        echo -e "  ${YELLOW}[NOTE]${NC} Missing context information"
    fi

    # Update status based on validation
    if [[ "$passed" == true && "$frequency" -ge "$WARM_PROMOTION_FREQUENCY" ]]; then
        update_learning_status "$file" "validated"
        return 0
    elif [[ "$passed" == true ]]; then
        # Passed but low frequency - keep as pending
        echo -e "  ${YELLOW}[PENDING]${NC} Waiting for more occurrences"
        return 0
    else
        update_learning_status "$file" "rejected"
        for reason in "${reasons[@]}"; do
            echo -e "  ${RED}[FAIL]${NC} $reason"
        done
        return 1
    fi
}

# Check if learning is duplicate of existing
check_duplicate() {
    local file="$1"
    local pattern_key
    pattern_key=$(jq -r '.pattern_key // .description // ""' "$file" 2>/dev/null)

    if [[ -z "$pattern_key" ]]; then
        return 1  # Not a duplicate if no key
    fi

    # Check global learnings
    local global_file="${LEARNINGS_DIR}/global.json"
    if [[ -f "$global_file" ]]; then
        local match
        match=$(jq -r --arg key "$pattern_key" '
            .learnings | to_entries[] |
            .value.patterns[]? |
            select(.pattern_key == $key or .description == $key) |
            .id
        ' "$global_file" 2>/dev/null || echo "")

        if [[ -n "$match" ]]; then
            return 0  # Is duplicate
        fi
    fi

    return 1  # Not duplicate
}

# Update learning status in file
update_learning_status() {
    local file="$1"
    local new_status="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if command -v jq &>/dev/null; then
        local updated
        updated=$(jq --arg status "$new_status" --arg ts "$timestamp" '
            .status = $status |
            .last_updated = $ts
        ' "$file" 2>/dev/null)

        if [[ -n "$updated" ]]; then
            echo "$updated" > "$file"
        fi
    fi
}

# ============================================================================
# PROPOSAL GENERATION
# ============================================================================

# Generate proposals for validated learnings
generate_proposals() {
    log "INFO" "Generating proposals for validated learnings..."

    local count=0

    for file in "$LEARNING_INBOX"/*.json; do
        if [[ -f "$file" ]]; then
            local status
            status=$(jq -r '.status // "pending"' "$file" 2>/dev/null || echo "pending")

            if [[ "$status" == "validated" ]]; then
                generate_proposal "$file"
                $1=$(($1 + 1))
            fi
        fi
    done

    echo ""
    echo -e "${CYAN}Generated $count proposals${NC}"
    echo "Review proposals in: $PROPOSALS_DIR"
    echo ""
}

# Generate a single proposal
generate_proposal() {
    local file="$1"
    local learning_id
    learning_id=$(basename "$file" .json)
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if ! command -v jq &>/dev/null; then
        log "WARN" "jq required for proposal generation"
        return 1
    fi

    local type description pattern_key frequency
    type=$(jq -r '.type // "unknown"' "$file" 2>/dev/null)
    description=$(jq -r '.description // "No description"' "$file" 2>/dev/null)
    pattern_key=$(jq -r '.pattern_key // ""' "$file" 2>/dev/null)
    frequency=$(jq -r '.frequency // 0' "$file" 2>/dev/null)

    # Determine proposal type
    local proposal_type="pattern"
    local proposal_action="create"

    case "$type" in
        code_pattern)
            proposal_type="pattern"
            ;;
        user_preference)
            proposal_type="rule"
            ;;
        workflow_improvement)
            proposal_type="workflow"
            ;;
        skill_gap)
            proposal_type="skill"
            ;;
    esac

    # Create proposal file
    local proposal_file="${PROPOSALS_DIR}/${learning_id}-proposal.json"

    cat > "$proposal_file" << EOF
{
    "proposal_id": "prop_${learning_id}",
    "learning_id": "${learning_id}",
    "type": "${proposal_type}",
    "action": "${proposal_action}",
    "description": "$(echo "$description" | sed 's/"/\\"/g')",
    "pattern_key": "${pattern_key}",
    "frequency": ${frequency},
    "status": "pending_confirmation",
    "suggested_changes": {
        "target": "${proposal_type}s",
        "file": "${JARVIS_ROOT}/${proposal_type}s/${learning_id}.md",
        "content_preview": "Will create ${proposal_type} based on: ${description:0:100}"
    },
    "created_at": "${timestamp}",
    "requires_confirmation": true
}
EOF

    echo -e "  ${GREEN}[PROPOSAL]${NC} Generated: ${proposal_file##*/}"

    # Update learning status
    update_learning_status "$file" "proposed"
}

# ============================================================================
# CONFIRMATION
# ============================================================================

# Confirm a learning for application
confirm_learning() {
    local learning_id="$1"
    local file="${LEARNING_INBOX}/${learning_id}.json"
    local proposal_file="${PROPOSALS_DIR}/${learning_id}-proposal.json"

    if [[ ! -f "$file" ]]; then
        # Try finding by partial match
        file=$(find "$LEARNING_INBOX" -name "*${learning_id}*.json" 2>/dev/null | head -1)
    fi

    if [[ ! -f "$file" ]]; then
        log "ERROR" "Learning not found: $learning_id"
        return 1
    fi

    echo ""
    echo -e "${CYAN}=== Confirming Learning ===${NC}"
    echo ""

    # Show learning details
    if command -v jq &>/dev/null; then
        echo "Details:"
        jq -r '
            "  ID: \(.id // "unknown")",
            "  Type: \(.type // "unknown")",
            "  Description: \(.description // "N/A")",
            "  Frequency: \(.frequency // 0)",
            "  Status: \(.status // "unknown")"
        ' "$file" 2>/dev/null
    fi

    # Show proposal if exists
    if [[ -f "$proposal_file" ]]; then
        echo ""
        echo "Proposal:"
        jq -r '
            "  Action: \(.action // "unknown")",
            "  Target: \(.suggested_changes.target // "unknown")",
            "  File: \(.suggested_changes.file // "N/A")"
        ' "$proposal_file" 2>/dev/null
    fi

    echo ""
    read -p "Confirm this learning for application? [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Update status to confirmed
        update_learning_status "$file" "confirmed"

        if [[ -f "$proposal_file" ]]; then
            local updated
            updated=$(jq '.status = "confirmed" | .confirmed_at = "'"$(date '+%Y-%m-%dT%H:%M:%SZ')"'"' "$proposal_file")
            echo "$updated" > "$proposal_file"
        fi

        log "OK" "Learning confirmed: $learning_id"
        echo -e "${GREEN}Learning confirmed. Run 'auto-update.sh apply $learning_id' to apply.${NC}"
    else
        log "INFO" "Confirmation cancelled for: $learning_id"
        echo -e "${YELLOW}Confirmation cancelled${NC}"
    fi
}

# Reject a learning
reject_learning() {
    local learning_id="$1"
    local reason="${2:-User rejected}"
    local file="${LEARNING_INBOX}/${learning_id}.json"

    if [[ ! -f "$file" ]]; then
        file=$(find "$LEARNING_INBOX" -name "*${learning_id}*.json" 2>/dev/null | head -1)
    fi

    if [[ ! -f "$file" ]]; then
        log "ERROR" "Learning not found: $learning_id"
        return 1
    fi

    # Update status and add rejection reason
    if command -v jq &>/dev/null; then
        local updated
        updated=$(jq --arg reason "$reason" '
            .status = "rejected" |
            .rejection_reason = $reason |
            .rejected_at = "'"$(date '+%Y-%m-%dT%H:%M:%SZ')"'"
        ' "$file")
        echo "$updated" > "$file"
    fi

    # Move to archive
    mv "$file" "$LEARNING_ARCHIVE/"

    log "OK" "Learning rejected and archived: $learning_id"
    echo -e "${GREEN}Learning rejected: $learning_id${NC}"
    echo -e "Reason: $reason"
}

# ============================================================================
# MEMORY TIER OPERATIONS
# ============================================================================

# Promote learning to warm memory
promote_to_warm() {
    local learning_id="$1"
    local file="${LEARNING_INBOX}/${learning_id}.json"
    local warm_file="${LEARNINGS_DIR}/warm-memory.json"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if [[ ! -f "$file" ]]; then
        log "ERROR" "Learning not found: $learning_id"
        return 1
    fi

    # Initialize warm memory if needed
    if [[ ! -f "$warm_file" ]]; then
        echo '{"warm_memory":{"preferences":[],"patterns":[],"workflows":[]}}' > "$warm_file"
    fi

    if ! command -v jq &>/dev/null; then
        log "ERROR" "jq required for memory tier promotion"
        return 1
    fi

    local type
    type=$(jq -r '.type // "unknown"' "$file" 2>/dev/null)
    local learning_data
    learning_data=$(jq '. + {"tier": "warm", "promoted_at": "'"$timestamp"'"}' "$file" 2>/dev/null)

    # Determine target array based on type
    local target_array="patterns"
    case "$type" in
        user_preference) target_array="preferences" ;;
        workflow_improvement) target_array="workflows" ;;
    esac

    # Add to warm memory
    local updated
    updated=$(jq --argjson learning "$learning_data" --arg array "$target_array" '
        .warm_memory[$array] += [$learning]
    ' "$warm_file" 2>/dev/null)

    if [[ -n "$updated" ]]; then
        echo "$updated" > "$warm_file"
        update_learning_status "$file" "promoted_to_warm"
        log "OK" "Learning promoted to warm memory: $learning_id"
    fi
}

# Demote learning to cold storage
demote_to_cold() {
    local learning_id="$1"
    local archive_dir="${JARVIS_ROOT}/archive/$(date '+%Y-Q')$((( $(date +%-m) - 1) / 3 + 1))"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    mkdir -p "$archive_dir"

    # Find and move the learning
    local file="${LEARNING_INBOX}/${learning_id}.json"
    if [[ ! -f "$file" ]]; then
        file=$(find "$LEARNING_INBOX" "$LEARNINGS_DIR" -name "*${learning_id}*.json" 2>/dev/null | head -1)
    fi

    if [[ -f "$file" ]]; then
        # Update status and move
        if command -v jq &>/dev/null; then
            local updated
            updated=$(jq '. + {"tier": "cold", "demoted_at": "'"$timestamp"'"}' "$file" 2>/dev/null)
            echo "$updated" > "${archive_dir}/${learning_id}.json"
        else
            cp "$file" "${archive_dir}/${learning_id}.json"
        fi

        rm -f "$file"
        log "OK" "Learning demoted to cold storage: $learning_id"
    fi
}

# ============================================================================
# SEARCH
# ============================================================================

# Search learnings across all tiers
search_learnings() {
    local query="$1"
    local tier="${2:-all}"  # all, hot, warm, cold

    echo ""
    echo -e "${CYAN}=== Searching for: $query ===${NC}"
    echo ""

    if ! command -v jq &>/dev/null; then
        log "ERROR" "jq required for search"
        return 1
    fi

    local found=0

    # Search inbox (hot tier candidates)
    if [[ "$tier" == "all" || "$tier" == "hot" ]]; then
        echo -e "${YELLOW}--- Inbox (pending) ---${NC}"
        for file in "$LEARNING_INBOX"/*.json; do
            if [[ -f "$file" ]]; then
                local match
                match=$(jq -r --arg q "$query" '
                    select(.description | ascii_downcase | contains($q | ascii_downcase)) |
                    "[\(.id)] \(.description)"
                ' "$file" 2>/dev/null || echo "")

                if [[ -n "$match" ]]; then
                    echo "  $match"
                    $1=$(($1 + 1))
                fi
            fi
        done
    fi

    # Search warm memory
    if [[ "$tier" == "all" || "$tier" == "warm" ]]; then
        local warm_file="${LEARNINGS_DIR}/warm-memory.json"
        if [[ -f "$warm_file" ]]; then
            echo ""
            echo -e "${GREEN}--- Warm Memory ---${NC}"

            local matches
            matches=$(jq -r --arg q "$query" '
                .warm_memory | to_entries[] |
                .value[] |
                select(.description | ascii_downcase | contains($q | ascii_downcase)) |
                "[\(.id)] \(.description)"
            ' "$warm_file" 2>/dev/null || echo "")

            if [[ -n "$matches" ]]; then
                echo "$matches" | while read -r line; do
                    echo "  $line"
                    $1=$(($1 + 1))
                done
            fi
        fi
    fi

    # Search global learnings
    local global_file="${LEARNINGS_DIR}/global.json"
    if [[ -f "$global_file" ]]; then
        echo ""
        echo -e "${BLUE}--- Global Learnings ---${NC}"

        local matches
        matches=$(jq -r --arg q "$query" '
            .learnings | to_entries[] |
            .value | (.patterns // []) + (.corrections // []) + (.workflows // []) |
            .[] |
            select(.description | ascii_downcase | contains($q | ascii_downcase)) |
            "[\(.id)] [\(.type // "unknown")] \(.description)"
        ' "$global_file" 2>/dev/null || echo "")

        if [[ -n "$matches" ]]; then
            echo "$matches" | while read -r line; do
                echo "  $line"
                $1=$(($1 + 1))
            done
        fi
    fi

    # Search cold storage
    if [[ "$tier" == "all" || "$tier" == "cold" ]]; then
        echo ""
        echo -e "${CYAN}--- Cold Archive ---${NC}"
        for archive_dir in "${JARVIS_ROOT}/archive"/*; do
            if [[ -d "$archive_dir" ]]; then
                for file in "$archive_dir"/*.json; do
                    if [[ -f "$file" ]]; then
                        local match
                        match=$(jq -r --arg q "$query" '
                            select(.description | ascii_downcase | contains($q | ascii_downcase)) |
                            "[\(.id)] \(.description)"
                        ' "$file" 2>/dev/null || echo "")

                        if [[ -n "$match" ]]; then
                            echo "  [$(basename "$archive_dir")] $match"
                            $1=$(($1 + 1))
                        fi
                    fi
                done
            fi
        done
    fi

    echo ""
    if [[ $found -eq 0 ]]; then
        echo -e "${YELLOW}No learnings found matching: $query${NC}"
    else
        echo -e "${GREEN}Found matches in search${NC}"
    fi
    echo ""
}

# ============================================================================
# STATUS
# ============================================================================

show_status() {
    echo ""
    echo -e "${CYAN}=== Learning Capture Status ===${NC}"
    echo ""

    # Inbox stats
    local inbox_count=0
    local validated_count=0
    local proposed_count=0
    local confirmed_count=0

    for file in "$LEARNING_INBOX"/*.json; do
        if [[ -f "$file" ]]; then
            $1=$(($1 + 1))
            local status
            status=$(jq -r '.status // "pending"' "$file" 2>/dev/null || echo "pending")
            case "$status" in
                validated) $1=$(($1 + 1)) ;;
                proposed) $1=$(($1 + 1)) ;;
                confirmed) $1=$(($1 + 1)) ;;
            esac
        fi
    done

    echo "Inbox:"
    echo -e "  Total: ${CYAN}$inbox_count${NC}"
    echo -e "  Validated: ${GREEN}$validated_count${NC}"
    echo -e "  Proposed: ${YELLOW}$proposed_count${NC}"
    echo -e "  Confirmed: ${GREEN}$confirmed_count${NC}"
    echo ""

    # Archive stats
    local archive_count=0
    for file in "$LEARNING_ARCHIVE"/*.json; do
        if [[ -f "$file" ]]; then
            $1=$(($1 + 1))
        fi
    done
    echo "Archive: $archive_count learnings"

    # Proposal stats
    local proposal_count=0
    for file in "$PROPOSALS_DIR"/*.json; do
        if [[ -f "$file" ]]; then
            $1=$(($1 + 1))
        fi
    done
    echo "Proposals: $proposal_count pending"
    echo ""

    # Memory tier stats
    echo "Memory Tiers:"
    local warm_file="${LEARNINGS_DIR}/warm-memory.json"
    if [[ -f "$warm_file" ]] && command -v jq &>/dev/null; then
        local warm_patterns warm_prefs
        warm_patterns=$(jq '.warm_memory.patterns | length' "$warm_file" 2>/dev/null || echo "0")
        warm_prefs=$(jq '.warm_memory.preferences | length' "$warm_file" 2>/dev/null || echo "0")
        echo "  Warm: $warm_patterns patterns, $warm_prefs preferences"
    fi

    local cold_count=0
    for dir in "${JARVIS_ROOT}/archive"/*; do
        if [[ -d "$dir" ]]; then
            local dir_count
            dir_count=$(find "$dir" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
            cold_count=$((cold_count + dir_count))
        fi
    done
    echo "  Cold: $cold_count archived"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command="${1:-status}"
    shift || true

    case "$command" in
        list|inbox)
            list_inbox
            ;;
        search)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: capture.sh search <query> [tier]"
                echo "Tiers: all (default), hot, warm, cold"
                exit 1
            fi
            search_learnings "$1" "${2:-all}"
            ;;
        process)
            process_inbox
            ;;
        validate)
            if [[ -n "${1:-}" ]]; then
                validate_learning "${LEARNING_INBOX}/${1}.json"
            else
                process_inbox
            fi
            ;;
        propose|proposals)
            generate_proposals
            ;;
        confirm)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: capture.sh confirm <learning_id>"
                exit 1
            fi
            confirm_learning "$1"
            ;;
        reject)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: capture.sh reject <learning_id> [reason]"
                exit 1
            fi
            reject_learning "$1" "${2:-}"
            ;;
        promote)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: capture.sh promote <learning_id>"
                exit 1
            fi
            promote_to_warm "$1"
            ;;
        demote)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: capture.sh demote <learning_id>"
                exit 1
            fi
            demote_to_cold "$1"
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            echo "Jarvis Learning Capture Processor"
            echo ""
            echo "Usage: capture.sh [command] [options]"
            echo ""
            echo "Commands:"
            echo "  list, inbox       List all learnings in inbox"
            echo "  search <q> [tier] Search learnings (tiers: all, hot, warm, cold)"
            echo "  process           Process all pending learnings"
            echo "  validate [id]     Validate a specific learning"
            echo "  propose           Generate proposals for validated learnings"
            echo "  confirm <id>      Confirm a learning for application"
            echo "  reject <id>       Reject a learning"
            echo "  promote <id>      Promote learning to warm memory"
            echo "  demote <id>       Demote learning to cold storage"
            echo "  status            Show capture system status"
            echo "  help              Show this help"
            ;;
        *)
            log "ERROR" "Unknown command: $command"
            echo "Run 'capture.sh help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
