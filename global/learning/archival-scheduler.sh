#!/usr/bin/env bash
# Jarvis Auto-Archival Scheduler
# Purpose: Automatically manage memory tier transitions based on age and activity
#
# This script handles:
# - Hot → Warm promotion (patterns with high frequency/confirmation)
# - Warm → Cold demotion (inactive learnings after threshold days)
# - Cold archive compression (quarterly)
# - Capacity enforcement (hot memory limits)
#
# Usage:
#   ./archival-scheduler.sh [command]
#
# Commands:
#   run        Run full archival cycle (default)
#   hot2warm   Process hot → warm promotions only
#   warm2cold  Process warm → cold demotions only
#   compress   Compress cold archives
#   status     Show archival status
#   cron       Output crontab entry for scheduling

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="${JARVIS_ROOT:-$HOME/.jarvis}"
LEARNINGS_DIR="${JARVIS_ROOT}/learnings"
LEARNING_INBOX="${SCRIPT_DIR}/inbox"
WARM_MEMORY_FILE="${LEARNINGS_DIR}/warm-memory.json"
ARCHIVE_ROOT="${JARVIS_ROOT}/archive"
LOG_FILE="${JARVIS_ROOT}/logs/archival.log"
STATE_FILE="${JARVIS_ROOT}/state/archival-state.json"

# Thresholds
HOT_MEMORY_MAX_ITEMS=20
WARM_PROMOTION_FREQUENCY=3
COLD_DEMOTION_DAYS=30
ARCHIVE_COMPRESSION_DAYS=90

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$LEARNINGS_DIR" "$ARCHIVE_ROOT" "${JARVIS_ROOT}/logs" "${JARVIS_ROOT}/state"

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
# STATE MANAGEMENT
# ============================================================================

# Initialize or load state
load_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << 'EOF'
{
    "last_run": null,
    "last_hot2warm": null,
    "last_warm2cold": null,
    "last_compression": null,
    "stats": {
        "total_promotions": 0,
        "total_demotions": 0,
        "total_compressions": 0
    }
}
EOF
    fi
}

# Update state after operation
update_state() {
    local operation="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if command -v jq &>/dev/null; then
        local updated
        updated=$(jq --arg op "$operation" --arg ts "$timestamp" '
            .["last_" + $op] = $ts |
            .last_run = $ts
        ' "$STATE_FILE" 2>/dev/null)

        if [[ -n "$updated" ]]; then
            echo "$updated" > "$STATE_FILE"
        fi
    fi
}

# Increment stats counter
increment_stat() {
    local stat="$1"
    local amount="${2:-1}"

    if command -v jq &>/dev/null && [[ -f "$STATE_FILE" ]]; then
        local updated
        updated=$(jq --arg stat "$stat" --argjson amt "$amount" '
            .stats[$stat] = ((.stats[$stat] // 0) + $amt)
        ' "$STATE_FILE" 2>/dev/null)

        if [[ -n "$updated" ]]; then
            echo "$updated" > "$STATE_FILE"
        fi
    fi
}

# ============================================================================
# HOT → WARM PROMOTION
# ============================================================================

process_hot_to_warm() {
    log "INFO" "Processing Hot → Warm promotions..."

    local promoted=0
    local skipped=0
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    # Initialize warm memory if needed
    if [[ ! -f "$WARM_MEMORY_FILE" ]]; then
        echo '{"warm_memory":{"preferences":[],"patterns":[],"workflows":[]},"metadata":{"created":"'"$timestamp"'","version":"1.0"}}' > "$WARM_MEMORY_FILE"
    fi

    if ! command -v jq &>/dev/null; then
        log "ERROR" "jq required for hot → warm processing"
        return 1
    fi

    # Process confirmed learnings in inbox that meet criteria
    for file in "$LEARNING_INBOX"/*.json; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        local learning_id status frequency type tier
        learning_id=$(jq -r '.id // "unknown"' "$file" 2>/dev/null)
        status=$(jq -r '.status // "pending"' "$file" 2>/dev/null)
        frequency=$(jq -r '.frequency // 0' "$file" 2>/dev/null)
        type=$(jq -r '.type // "unknown"' "$file" 2>/dev/null)
        tier=$(jq -r '.tier // "hot"' "$file" 2>/dev/null)

        # Skip already promoted or non-confirmed
        if [[ "$tier" == "warm" || "$tier" == "cold" ]]; then
            continue
        fi

        # Criteria for promotion:
        # 1. Confirmed status OR validated with high frequency
        # 2. Frequency >= threshold
        local should_promote=false

        if [[ "$status" == "confirmed" ]]; then
            should_promote=true
        elif [[ "$status" == "validated" && "$frequency" -ge "$WARM_PROMOTION_FREQUENCY" ]]; then
            should_promote=true
        fi

        if [[ "$should_promote" == true ]]; then
            # Add to warm memory
            local learning_data
            learning_data=$(jq '. + {"tier": "warm", "promoted_at": "'"$timestamp"'"}' "$file" 2>/dev/null)

            # Determine target array
            local target_array="patterns"
            case "$type" in
                user_preference) target_array="preferences" ;;
                workflow_improvement|workflow) target_array="workflows" ;;
            esac

            # Add to warm memory
            local updated
            updated=$(jq --argjson learning "$learning_data" --arg array "$target_array" '
                .warm_memory[$array] += [$learning]
            ' "$WARM_MEMORY_FILE" 2>/dev/null)

            if [[ -n "$updated" ]]; then
                echo "$updated" > "$WARM_MEMORY_FILE"

                # Update original file status
                local file_updated
                file_updated=$(jq '.tier = "warm" | .promoted_at = "'"$timestamp"'" | .status = "promoted_to_warm"' "$file" 2>/dev/null)
                echo "$file_updated" > "$file"

                log "OK" "Promoted to warm: $learning_id"
                ((promoted++))
            fi
        else
            ((skipped++))
        fi
    done

    # Enforce hot memory capacity
    enforce_hot_capacity

    log "INFO" "Hot → Warm complete: $promoted promoted, $skipped skipped"
    increment_stat "total_promotions" "$promoted"
    update_state "hot2warm"

    echo "$promoted"
}

# Enforce maximum items in hot memory (inbox)
enforce_hot_capacity() {
    local hot_count=0
    local files=()

    # Count and collect hot tier items sorted by age
    for file in "$LEARNING_INBOX"/*.json; do
        if [[ -f "$file" ]]; then
            local tier
            tier=$(jq -r '.tier // "hot"' "$file" 2>/dev/null || echo "hot")
            if [[ "$tier" == "hot" ]]; then
                files+=("$file")
                ((hot_count++))
            fi
        fi
    done

    # If over capacity, force demote oldest
    if [[ $hot_count -gt $HOT_MEMORY_MAX_ITEMS ]]; then
        local excess=$((hot_count - HOT_MEMORY_MAX_ITEMS))
        log "WARN" "Hot memory over capacity ($hot_count > $HOT_MEMORY_MAX_ITEMS), demoting $excess items"

        # Sort by created_at and demote oldest
        local sorted_files=()
        while IFS= read -r line; do
            sorted_files+=("$line")
        done < <(for f in "${files[@]}"; do
            local created
            created=$(jq -r '.created_at // "1970-01-01"' "$f" 2>/dev/null)
            echo "$created|$f"
        done | sort | head -n "$excess" | cut -d'|' -f2)

        for file in "${sorted_files[@]}"; do
            local learning_id
            learning_id=$(jq -r '.id // "unknown"' "$file" 2>/dev/null)
            demote_single_to_cold "$learning_id" "$file" "capacity_overflow"
        done
    fi
}

# ============================================================================
# WARM → COLD DEMOTION
# ============================================================================

process_warm_to_cold() {
    log "INFO" "Processing Warm → Cold demotions (threshold: $COLD_DEMOTION_DAYS days)..."

    local demoted=0
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if ! command -v jq &>/dev/null; then
        log "ERROR" "jq required for warm → cold processing"
        return 1
    fi

    if [[ ! -f "$WARM_MEMORY_FILE" ]]; then
        log "INFO" "No warm memory file exists"
        return 0
    fi

    # Calculate cutoff date
    local cutoff_date
    if [[ "$(uname)" == "Darwin" ]]; then
        cutoff_date=$(date -v-${COLD_DEMOTION_DAYS}d '+%Y-%m-%dT00:00:00Z')
    else
        cutoff_date=$(date -d "${COLD_DEMOTION_DAYS} days ago" '+%Y-%m-%dT00:00:00Z')
    fi

    log "INFO" "Cutoff date: $cutoff_date"

    # Get current quarter for archive path
    local year quarter archive_dir
    year=$(date '+%Y')
    quarter=$(( ($(date +%-m) - 1) / 3 + 1 ))
    archive_dir="${ARCHIVE_ROOT}/${year}-Q${quarter}"
    mkdir -p "$archive_dir"

    # Process each type of warm memory
    for array_type in "patterns" "preferences" "workflows"; do
        # Get items older than cutoff
        local items_to_demote
        items_to_demote=$(jq -r --arg cutoff "$cutoff_date" --arg type "$array_type" '
            .warm_memory[$type] // [] |
            to_entries |
            map(select(
                (.value.last_accessed // .value.promoted_at // .value.created_at // "9999") < $cutoff
            )) |
            .[].value.id // empty
        ' "$WARM_MEMORY_FILE" 2>/dev/null || echo "")

        if [[ -z "$items_to_demote" ]]; then
            continue
        fi

        # Demote each item
        while IFS= read -r learning_id; do
            if [[ -z "$learning_id" || "$learning_id" == "null" ]]; then
                continue
            fi

            # Extract and archive the learning
            local learning_data
            learning_data=$(jq --arg id "$learning_id" --arg type "$array_type" '
                .warm_memory[$type] | map(select(.id == $id)) | .[0] // empty
            ' "$WARM_MEMORY_FILE" 2>/dev/null)

            if [[ -n "$learning_data" && "$learning_data" != "null" ]]; then
                # Add demotion metadata and save to cold storage
                local cold_data
                cold_data=$(echo "$learning_data" | jq '. + {
                    "tier": "cold",
                    "demoted_at": "'"$timestamp"'",
                    "demotion_reason": "inactivity"
                }' 2>/dev/null)

                echo "$cold_data" > "${archive_dir}/${learning_id}.json"

                # Remove from warm memory
                local updated
                updated=$(jq --arg id "$learning_id" --arg type "$array_type" '
                    .warm_memory[$type] = [.warm_memory[$type][] | select(.id != $id)]
                ' "$WARM_MEMORY_FILE" 2>/dev/null)

                if [[ -n "$updated" ]]; then
                    echo "$updated" > "$WARM_MEMORY_FILE"
                fi

                log "OK" "Demoted to cold: $learning_id → $archive_dir"
                ((demoted++))
            fi
        done <<< "$items_to_demote"
    done

    log "INFO" "Warm → Cold complete: $demoted demoted"
    increment_stat "total_demotions" "$demoted"
    update_state "warm2cold"

    echo "$demoted"
}

# Demote a single item directly to cold
demote_single_to_cold() {
    local learning_id="$1"
    local file="$2"
    local reason="${3:-manual}"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    # Get archive directory
    local year quarter archive_dir
    year=$(date '+%Y')
    quarter=$(( ($(date +%-m) - 1) / 3 + 1 ))
    archive_dir="${ARCHIVE_ROOT}/${year}-Q${quarter}"
    mkdir -p "$archive_dir"

    if [[ -f "$file" ]]; then
        # Update and move to cold
        local updated
        updated=$(jq '. + {
            "tier": "cold",
            "demoted_at": "'"$timestamp"'",
            "demotion_reason": "'"$reason"'"
        }' "$file" 2>/dev/null)

        if [[ -n "$updated" ]]; then
            echo "$updated" > "${archive_dir}/${learning_id}.json"
            rm -f "$file"
            log "OK" "Demoted directly to cold: $learning_id (reason: $reason)"
        fi
    fi
}

# ============================================================================
# COLD ARCHIVE COMPRESSION
# ============================================================================

compress_cold_archives() {
    log "INFO" "Compressing old cold archives..."

    local compressed=0
    local current_quarter
    current_quarter=$(date '+%Y-Q')$(( ($(date +%-m) - 1) / 3 + 1 ))

    for archive_dir in "$ARCHIVE_ROOT"/*/; do
        if [[ ! -d "$archive_dir" ]]; then
            continue
        fi

        local quarter_name
        quarter_name=$(basename "$archive_dir")

        # Don't compress current quarter
        if [[ "$quarter_name" == "$current_quarter" ]]; then
            continue
        fi

        # Check if already compressed
        if [[ -f "${ARCHIVE_ROOT}/${quarter_name}.tar.gz" ]]; then
            continue
        fi

        # Count files
        local file_count
        file_count=$(find "$archive_dir" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')

        if [[ "$file_count" -gt 0 ]]; then
            # Compress the archive
            tar -czf "${ARCHIVE_ROOT}/${quarter_name}.tar.gz" -C "$ARCHIVE_ROOT" "$quarter_name" 2>/dev/null

            if [[ -f "${ARCHIVE_ROOT}/${quarter_name}.tar.gz" ]]; then
                # Remove original directory
                rm -rf "$archive_dir"
                log "OK" "Compressed archive: $quarter_name ($file_count files)"
                ((compressed++))
            fi
        fi
    done

    log "INFO" "Compression complete: $compressed archives compressed"
    increment_stat "total_compressions" "$compressed"
    update_state "compression"

    echo "$compressed"
}

# ============================================================================
# COLD → WARM RECALL
# ============================================================================

# Recall a cold learning back to warm (manual operation)
recall_from_cold() {
    local learning_id="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')

    if ! command -v jq &>/dev/null; then
        log "ERROR" "jq required for recall"
        return 1
    fi

    # Search in cold archives
    local found_file=""

    # First check uncompressed directories
    for archive_dir in "$ARCHIVE_ROOT"/*/; do
        if [[ -d "$archive_dir" ]]; then
            local file="${archive_dir}${learning_id}.json"
            if [[ -f "$file" ]]; then
                found_file="$file"
                break
            fi
        fi
    done

    # If not found, search compressed archives
    if [[ -z "$found_file" ]]; then
        for archive in "$ARCHIVE_ROOT"/*.tar.gz; do
            if [[ -f "$archive" ]]; then
                if tar -tzf "$archive" 2>/dev/null | grep -q "${learning_id}.json"; then
                    # Extract the specific file
                    local temp_dir
                    temp_dir=$(mktemp -d)
                    tar -xzf "$archive" -C "$temp_dir" --wildcards "*/${learning_id}.json" 2>/dev/null
                    found_file=$(find "$temp_dir" -name "${learning_id}.json" 2>/dev/null | head -1)
                    break
                fi
            fi
        done
    fi

    if [[ -z "$found_file" || ! -f "$found_file" ]]; then
        log "ERROR" "Learning not found in cold storage: $learning_id"
        return 1
    fi

    # Recall to warm memory
    local type
    type=$(jq -r '.type // "code_pattern"' "$found_file" 2>/dev/null)
    local target_array="patterns"
    case "$type" in
        user_preference) target_array="preferences" ;;
        workflow_improvement|workflow) target_array="workflows" ;;
    esac

    # Update learning data
    local learning_data
    learning_data=$(jq '. + {
        "tier": "warm",
        "recalled_at": "'"$timestamp"'",
        "recall_count": ((.recall_count // 0) + 1)
    }' "$found_file" 2>/dev/null)

    # Add to warm memory
    local updated
    updated=$(jq --argjson learning "$learning_data" --arg array "$target_array" '
        .warm_memory[$array] += [$learning]
    ' "$WARM_MEMORY_FILE" 2>/dev/null)

    if [[ -n "$updated" ]]; then
        echo "$updated" > "$WARM_MEMORY_FILE"
        rm -f "$found_file"
        log "OK" "Recalled from cold: $learning_id → warm/$target_array"
        return 0
    fi

    return 1
}

# ============================================================================
# STATUS
# ============================================================================

show_status() {
    echo ""
    echo -e "${CYAN}=== Archival Scheduler Status ===${NC}"
    echo ""

    load_state

    # Show last run times
    if command -v jq &>/dev/null && [[ -f "$STATE_FILE" ]]; then
        echo "Last Operations:"
        jq -r '
            "  Full run:    \(.last_run // "never")",
            "  Hot→Warm:    \(.last_hot2warm // "never")",
            "  Warm→Cold:   \(.last_warm2cold // "never")",
            "  Compression: \(.last_compression // "never")"
        ' "$STATE_FILE" 2>/dev/null
        echo ""
        echo "Statistics:"
        jq -r '
            "  Total promotions:   \(.stats.total_promotions // 0)",
            "  Total demotions:    \(.stats.total_demotions // 0)",
            "  Total compressions: \(.stats.total_compressions // 0)"
        ' "$STATE_FILE" 2>/dev/null
    fi
    echo ""

    # Hot memory (inbox) status
    local hot_count=0
    local hot_pending=0
    local hot_validated=0
    local hot_confirmed=0

    for file in "$LEARNING_INBOX"/*.json; do
        if [[ -f "$file" ]]; then
            ((hot_count++))
            local status
            status=$(jq -r '.status // "pending"' "$file" 2>/dev/null || echo "pending")
            case "$status" in
                pending) ((hot_pending++)) ;;
                validated) ((hot_validated++)) ;;
                confirmed) ((hot_confirmed++)) ;;
            esac
        fi
    done

    echo "Hot Memory (Inbox):"
    echo -e "  Total: ${CYAN}$hot_count${NC} / $HOT_MEMORY_MAX_ITEMS max"
    echo -e "  Pending: $hot_pending | Validated: $hot_validated | Confirmed: $hot_confirmed"
    echo ""

    # Warm memory status
    if [[ -f "$WARM_MEMORY_FILE" ]] && command -v jq &>/dev/null; then
        local warm_patterns warm_prefs warm_workflows
        warm_patterns=$(jq '.warm_memory.patterns | length' "$WARM_MEMORY_FILE" 2>/dev/null || echo "0")
        warm_prefs=$(jq '.warm_memory.preferences | length' "$WARM_MEMORY_FILE" 2>/dev/null || echo "0")
        warm_workflows=$(jq '.warm_memory.workflows | length' "$WARM_MEMORY_FILE" 2>/dev/null || echo "0")

        echo "Warm Memory:"
        echo -e "  Patterns: $warm_patterns | Preferences: $warm_prefs | Workflows: $warm_workflows"
    else
        echo "Warm Memory: Not initialized"
    fi
    echo ""

    # Cold storage status
    local cold_dirs=0
    local cold_compressed=0
    local cold_total_files=0

    for item in "$ARCHIVE_ROOT"/*; do
        if [[ -d "$item" ]]; then
            ((cold_dirs++))
            local count
            count=$(find "$item" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
            cold_total_files=$((cold_total_files + count))
        elif [[ -f "$item" && "$item" == *.tar.gz ]]; then
            ((cold_compressed++))
        fi
    done

    echo "Cold Storage:"
    echo -e "  Active quarters: $cold_dirs ($cold_total_files files)"
    echo -e "  Compressed archives: $cold_compressed"
    echo ""

    # Configuration
    echo "Configuration:"
    echo "  Hot capacity: $HOT_MEMORY_MAX_ITEMS items"
    echo "  Warm promotion: $WARM_PROMOTION_FREQUENCY occurrences"
    echo "  Cold demotion: $COLD_DEMOTION_DAYS days inactivity"
    echo ""
}

# ============================================================================
# CRON SETUP
# ============================================================================

show_cron_entry() {
    local script_path
    script_path=$(realpath "$0" 2>/dev/null || echo "$0")

    echo ""
    echo "To schedule automatic archival, add this to your crontab (crontab -e):"
    echo ""
    echo "# Jarvis Learning Archival - runs daily at 2 AM"
    echo "0 2 * * * JARVIS_ROOT=\"$JARVIS_ROOT\" $script_path run >> \"${JARVIS_ROOT}/logs/archival-cron.log\" 2>&1"
    echo ""
    echo "Or for weekly archival (Sundays at 3 AM):"
    echo "0 3 * * 0 JARVIS_ROOT=\"$JARVIS_ROOT\" $script_path run >> \"${JARVIS_ROOT}/logs/archival-cron.log\" 2>&1"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

run_full_cycle() {
    log "INFO" "Starting full archival cycle..."

    load_state

    local promoted demoted compressed

    # 1. Process hot → warm
    promoted=$(process_hot_to_warm)

    # 2. Process warm → cold
    demoted=$(process_warm_to_cold)

    # 3. Compress old archives
    compressed=$(compress_cold_archives)

    log "INFO" "Archival cycle complete: +$promoted warm, -$demoted cold, $compressed compressed"

    echo ""
    echo -e "${GREEN}=== Archival Cycle Complete ===${NC}"
    echo "  Promoted to warm: $promoted"
    echo "  Demoted to cold: $demoted"
    echo "  Archives compressed: $compressed"
    echo ""
}

main() {
    local command="${1:-run}"
    shift || true

    case "$command" in
        run)
            run_full_cycle
            ;;
        hot2warm)
            load_state
            process_hot_to_warm
            ;;
        warm2cold)
            load_state
            process_warm_to_cold
            ;;
        compress)
            load_state
            compress_cold_archives
            ;;
        recall)
            if [[ -z "${1:-}" ]]; then
                echo "Usage: archival-scheduler.sh recall <learning_id>"
                exit 1
            fi
            recall_from_cold "$1"
            ;;
        status)
            show_status
            ;;
        cron)
            show_cron_entry
            ;;
        help|--help|-h)
            echo "Jarvis Auto-Archival Scheduler"
            echo ""
            echo "Usage: archival-scheduler.sh [command]"
            echo ""
            echo "Commands:"
            echo "  run        Run full archival cycle (default)"
            echo "  hot2warm   Process hot → warm promotions only"
            echo "  warm2cold  Process warm → cold demotions only"
            echo "  compress   Compress cold archives"
            echo "  recall <id> Recall learning from cold to warm"
            echo "  status     Show archival status"
            echo "  cron       Output crontab entry for scheduling"
            echo "  help       Show this help"
            ;;
        *)
            log "ERROR" "Unknown command: $command"
            echo "Run 'archival-scheduler.sh help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
