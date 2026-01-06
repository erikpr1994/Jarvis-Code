#!/bin/bash
# =============================================================================
# Jarvis Error Recovery System
# =============================================================================
# Central error handling with four-level recovery strategy:
# L1: Retry with backoff
# L2: Alternative approach
# L3: Graceful degradation
# L4: User escalation
# =============================================================================

set -o pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
JARVIS_LOG_DIR="${JARVIS_LOG_DIR:-$HOME/.claude/logs}"
JARVIS_STATE_DIR="${JARVIS_STATE_DIR:-$HOME/.claude/state}"
JARVIS_ERROR_LOG="${JARVIS_LOG_DIR}/errors.log"
JARVIS_HEALTH_FILE="${JARVIS_STATE_DIR}/health.json"

# Retry configuration
DEFAULT_MAX_RETRIES=3
DEFAULT_INITIAL_BACKOFF=1
DEFAULT_MAX_BACKOFF=30
DEFAULT_BACKOFF_MULTIPLIER=2

# Timeout configuration
DEFAULT_HOOK_TIMEOUT=5
DEFAULT_AGENT_TIMEOUT=60

# Notification configuration
JARVIS_NOTIFICATIONS_ENABLED="${JARVIS_NOTIFICATIONS_ENABLED:-true}"
JARVIS_NOTIFICATION_SOUND="${JARVIS_NOTIFICATION_SOUND:-true}"

# Degradation thresholds (from spec)
THRESHOLD_HOOK_FAILURES_L1=3
THRESHOLD_HOOK_FAILURES_L2=5
THRESHOLD_AGENT_TIMEOUTS_L1=2
THRESHOLD_AGENT_TIMEOUTS_L2=4
THRESHOLD_CONTEXT_USAGE_L1=80
THRESHOLD_CONTEXT_USAGE_L2=90
THRESHOLD_REPEATED_FAILURES_L3=10

# Current session counters
SESSION_HOOK_FAILURES=0
SESSION_AGENT_TIMEOUTS=0
SESSION_REPEATED_FAILURES=0
CURRENT_DEGRADATION_LEVEL=0

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

init_error_system() {
  mkdir -p "$JARVIS_LOG_DIR" "$JARVIS_STATE_DIR"

  # Initialize health file if not exists
  if [[ ! -f "$JARVIS_HEALTH_FILE" ]]; then
    cat > "$JARVIS_HEALTH_FILE" << 'EOF'
{
  "current_level": 0,
  "hook_failures_session": 0,
  "agent_timeouts_session": 0,
  "last_degradation": null,
  "errors": {}
}
EOF
  fi

  # Load current state
  load_health_state
}

load_health_state() {
  if [[ -f "$JARVIS_HEALTH_FILE" ]]; then
    CURRENT_DEGRADATION_LEVEL=$(jq -r '.current_level // 0' "$JARVIS_HEALTH_FILE" 2>/dev/null || echo 0)
    SESSION_HOOK_FAILURES=$(jq -r '.hook_failures_session // 0' "$JARVIS_HEALTH_FILE" 2>/dev/null || echo 0)
    SESSION_AGENT_TIMEOUTS=$(jq -r '.agent_timeouts_session // 0' "$JARVIS_HEALTH_FILE" 2>/dev/null || echo 0)
  fi
}

save_health_state() {
  local tmp_file="${JARVIS_HEALTH_FILE}.tmp"
  jq --arg level "$CURRENT_DEGRADATION_LEVEL" \
     --arg hook_failures "$SESSION_HOOK_FAILURES" \
     --arg agent_timeouts "$SESSION_AGENT_TIMEOUTS" \
     '.current_level = ($level | tonumber) |
      .hook_failures_session = ($hook_failures | tonumber) |
      .agent_timeouts_session = ($agent_timeouts | tonumber)' \
     "$JARVIS_HEALTH_FILE" > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$JARVIS_HEALTH_FILE"
}

# -----------------------------------------------------------------------------
# Logging & Diagnostics
# -----------------------------------------------------------------------------

log_error() {
  local error_type="$1"
  local component="$2"
  local details="${3:-}"
  local recovery="${4:-none}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Log to error file
  echo "[$timestamp] [$error_type] component=$component recovery=$recovery details=$details" >> "$JARVIS_ERROR_LOG"

  # Update health file with error
  local tmp_file="${JARVIS_HEALTH_FILE}.tmp"
  jq --arg ts "$timestamp" \
     --arg type "$error_type" \
     --arg comp "$component" \
     --arg det "$details" \
     --arg rec "$recovery" \
     '.errors[$ts] = {
        "type": $type,
        "component": $comp,
        "details": $det,
        "recovery": $rec,
        "timestamp": $ts
      }' "$JARVIS_HEALTH_FILE" > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$JARVIS_HEALTH_FILE"
}

log_diagnostic() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$timestamp] [DIAG:$level] $message" >> "$JARVIS_ERROR_LOG"
}

get_error_summary() {
  local count="${1:-10}"
  if [[ -f "$JARVIS_ERROR_LOG" ]]; then
    tail -n "$count" "$JARVIS_ERROR_LOG"
  else
    echo "No errors logged"
  fi
}

get_health_status() {
  if [[ -f "$JARVIS_HEALTH_FILE" ]]; then
    cat "$JARVIS_HEALTH_FILE"
  else
    echo '{"status": "unknown", "message": "Health file not initialized"}'
  fi
}

# -----------------------------------------------------------------------------
# L1: Retry with Exponential Backoff
# -----------------------------------------------------------------------------

retry_with_backoff() {
  local cmd="$1"
  local max_retries="${2:-$DEFAULT_MAX_RETRIES}"
  local initial_backoff="${3:-$DEFAULT_INITIAL_BACKOFF}"
  local max_backoff="${4:-$DEFAULT_MAX_BACKOFF}"
  local multiplier="${5:-$DEFAULT_BACKOFF_MULTIPLIER}"

  local attempt=0
  local backoff=$initial_backoff
  local output
  local exit_code

  while (( attempt < max_retries )); do
    ((attempt++))
    log_diagnostic "INFO" "Attempt $attempt/$max_retries: $cmd"

    output=$(eval "$cmd" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
      echo "$output"
      return 0
    fi

    if (( attempt < max_retries )); then
      log_diagnostic "WARN" "Attempt $attempt failed (exit $exit_code), retrying in ${backoff}s"
      sleep "$backoff"

      # Exponential backoff with cap
      backoff=$((backoff * multiplier))
      if (( backoff > max_backoff )); then
        backoff=$max_backoff
      fi
    fi
  done

  log_error "retry_exhausted" "$cmd" "Failed after $max_retries attempts" "escalate"
  echo "$output"
  return 1
}

# -----------------------------------------------------------------------------
# L2: Alternative Approach Execution
# -----------------------------------------------------------------------------

try_alternatives() {
  local -a alternatives=("$@")
  local output
  local exit_code
  local attempt=0

  for alt in "${alternatives[@]}"; do
    ((attempt++))
    log_diagnostic "INFO" "Trying alternative $attempt/${#alternatives[@]}: $alt"

    output=$(eval "$alt" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
      log_diagnostic "INFO" "Alternative $attempt succeeded"
      echo "$output"
      return 0
    fi

    log_diagnostic "WARN" "Alternative $attempt failed (exit $exit_code)"
  done

  log_error "alternatives_exhausted" "${alternatives[0]}" "All ${#alternatives[@]} alternatives failed" "degrade"
  return 1
}

# -----------------------------------------------------------------------------
# L3: Graceful Degradation
# -----------------------------------------------------------------------------

check_degradation_triggers() {
  local new_level=$CURRENT_DEGRADATION_LEVEL

  # Check for Level 3 triggers (most severe - check first)
  if (( SESSION_REPEATED_FAILURES >= THRESHOLD_REPEATED_FAILURES_L3 )); then
    new_level=3
  # Check for Level 2 triggers
  elif (( SESSION_HOOK_FAILURES >= THRESHOLD_HOOK_FAILURES_L2 )) || \
       (( SESSION_AGENT_TIMEOUTS >= THRESHOLD_AGENT_TIMEOUTS_L2 )); then
    new_level=2
  # Check for Level 1 triggers
  elif (( SESSION_HOOK_FAILURES >= THRESHOLD_HOOK_FAILURES_L1 )) || \
       (( SESSION_AGENT_TIMEOUTS >= THRESHOLD_AGENT_TIMEOUTS_L1 )); then
    new_level=1
  fi

  if (( new_level > CURRENT_DEGRADATION_LEVEL )); then
    trigger_degradation "$new_level"
  fi

  echo "$CURRENT_DEGRADATION_LEVEL"
}

trigger_degradation() {
  local target_level="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  CURRENT_DEGRADATION_LEVEL=$target_level

  # Update health file
  local tmp_file="${JARVIS_HEALTH_FILE}.tmp"
  jq --arg level "$target_level" \
     --arg ts "$timestamp" \
     '.current_level = ($level | tonumber) | .last_degradation = $ts' \
     "$JARVIS_HEALTH_FILE" > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$JARVIS_HEALTH_FILE"

  log_error "degradation_triggered" "system" "Degraded to level $target_level" "automatic"

  # Notify user
  notify_degradation "$target_level"
}

notify_degradation() {
  local level="$1"

  # Send desktop notification
  notify_degradation_desktop "$level"

  # Console output
  case $level in
    1)
      echo "[!] Switched to reduced verification mode due to multiple failures."
      echo "    Core functionality remains active. Full features resume next session."
      ;;
    2)
      echo "[!!] Switched to minimal system mode."
      echo "     Single-agent mode active. Run '/jarvis doctor' to diagnose."
      ;;
    3)
      echo "[!!!] EMERGENCY MODE - All enhancements disabled."
      echo "      Direct Claude responses only. Please check system health."
      ;;
  esac
}

get_degradation_level() {
  echo "$CURRENT_DEGRADATION_LEVEL"
}

is_feature_enabled() {
  local feature="$1"
  local level=$CURRENT_DEGRADATION_LEVEL

  case $feature in
    "hooks")
      [[ $level -lt 3 ]]
      ;;
    "non_essential_hooks")
      [[ $level -lt 1 ]]
      ;;
    "agents")
      [[ $level -lt 3 ]]
      ;;
    "parallel_agents")
      [[ $level -lt 2 ]]
      ;;
    "skills")
      [[ $level -lt 2 ]]
      ;;
    "full_verification")
      [[ $level -lt 1 ]]
      ;;
    *)
      [[ $level -lt 1 ]]
      ;;
  esac
}

reset_degradation() {
  CURRENT_DEGRADATION_LEVEL=0
  SESSION_HOOK_FAILURES=0
  SESSION_AGENT_TIMEOUTS=0
  SESSION_REPEATED_FAILURES=0
  save_health_state
  log_diagnostic "INFO" "Degradation level reset to 0"
}

# -----------------------------------------------------------------------------
# Desktop Notifications (Cross-Platform)
# -----------------------------------------------------------------------------

# Send desktop notification (macOS, Linux, fallback to console)
send_notification() {
  local title="$1"
  local message="$2"
  local urgency="${3:-normal}"  # low, normal, critical
  local sound="${4:-}"

  # Skip if notifications disabled
  if [[ "$JARVIS_NOTIFICATIONS_ENABLED" != "true" ]]; then
    return 0
  fi

  # macOS
  if [[ "$(uname)" == "Darwin" ]]; then
    local script="display notification \"$message\" with title \"$title\""

    # Add sound for critical notifications
    if [[ "$urgency" == "critical" ]] && [[ "$JARVIS_NOTIFICATION_SOUND" == "true" ]]; then
      script="$script sound name \"Basso\""
    elif [[ -n "$sound" ]] && [[ "$JARVIS_NOTIFICATION_SOUND" == "true" ]]; then
      script="$script sound name \"$sound\""
    fi

    osascript -e "$script" 2>/dev/null || true
    return 0
  fi

  # Linux (notify-send)
  if command -v notify-send &>/dev/null; then
    local notify_urgency
    case "$urgency" in
      critical) notify_urgency="critical" ;;
      low) notify_urgency="low" ;;
      *) notify_urgency="normal" ;;
    esac

    notify-send -u "$notify_urgency" "$title" "$message" 2>/dev/null || true
    return 0
  fi

  # WSL/Windows (powershell toast notification)
  if [[ -f /proc/version ]] && grep -qi "microsoft" /proc/version 2>/dev/null; then
    powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; \$template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02; \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(\$template); \$text = \$xml.GetElementsByTagName('text'); \$text[0].AppendChild(\$xml.CreateTextNode('$title')); \$text[1].AppendChild(\$xml.CreateTextNode('$message')); \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml); [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Jarvis').Show(\$toast)" 2>/dev/null || true
    return 0
  fi

  # Fallback: console only (already handled by caller)
  return 1
}

# Notify on degradation with desktop notification
notify_degradation_desktop() {
  local level="$1"

  case $level in
    1)
      send_notification "Jarvis: Reduced Mode" \
        "Switched to reduced verification mode due to multiple failures." \
        "normal" "Submarine"
      ;;
    2)
      send_notification "Jarvis: Minimal Mode" \
        "Single-agent mode active. Run '/jarvis doctor' to diagnose." \
        "critical" "Sosumi"
      ;;
    3)
      send_notification "Jarvis: Emergency Mode" \
        "All enhancements disabled! Please check system health." \
        "critical" "Basso"
      ;;
  esac
}

# Notify on user escalation with desktop notification
notify_escalation_desktop() {
  local issue_type="$1"
  local context="$2"

  send_notification "Jarvis: Attention Required" \
    "$issue_type - $context" \
    "critical" "Basso"
}

# Notify on task completion (optional positive notification)
notify_completion() {
  local message="$1"
  local sound="${2:-Glass}"

  send_notification "Jarvis: Complete" "$message" "low" "$sound"
}

# Notify on warning (non-critical)
notify_warning() {
  local message="$1"

  send_notification "Jarvis: Warning" "$message" "normal" "Tink"
}

# Test notification system
test_notifications() {
  echo "Testing notification system..."
  echo ""

  echo "1. Testing low urgency notification..."
  send_notification "Jarvis Test" "Low urgency notification" "low"
  sleep 1

  echo "2. Testing normal urgency notification..."
  send_notification "Jarvis Test" "Normal urgency notification" "normal" "Submarine"
  sleep 1

  echo "3. Testing critical urgency notification..."
  send_notification "Jarvis Test" "Critical urgency notification" "critical" "Basso"
  sleep 1

  echo ""
  echo "Notification test complete!"
  echo "If you didn't see notifications, check:"
  echo "  - JARVIS_NOTIFICATIONS_ENABLED is set to 'true'"
  echo "  - Your system supports notifications"
  echo "  - Notification permissions are granted"
}

# -----------------------------------------------------------------------------
# L4: User Escalation
# -----------------------------------------------------------------------------

escalate_to_user() {
  local issue_type="$1"
  local context="$2"
  local suggestions="${3:-}"

  log_error "user_escalation" "$issue_type" "$context" "escalated"

  # Send desktop notification for critical escalation
  notify_escalation_desktop "$issue_type" "$context"

  echo ""
  echo "============================================================"
  echo "[ATTENTION REQUIRED] $issue_type"
  echo "============================================================"
  echo ""
  echo "Context: $context"
  echo ""

  if [[ -n "$suggestions" ]]; then
    echo "Suggested actions:"
    echo "$suggestions" | while IFS= read -r line; do
      echo "  - $line"
    done
    echo ""
  fi

  echo "Options:"
  echo "  1. Run '/jarvis doctor' for full diagnostics"
  echo "  2. Check logs: $JARVIS_ERROR_LOG"
  echo "  3. Reset system: '/jarvis reset'"
  echo "============================================================"
}

should_escalate() {
  local error_type="$1"
  local failure_count="${2:-1}"

  case $error_type in
    "security"|"data_loss"|"corruption")
      return 0  # Always escalate
      ;;
    "repeated_failure")
      [[ $failure_count -ge 5 ]]
      ;;
    "agent_refusal")
      return 0  # Always escalate refusals
      ;;
    "infinite_loop")
      return 0  # Always escalate loops
      ;;
    *)
      [[ $failure_count -ge $THRESHOLD_REPEATED_FAILURES_L3 ]]
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Hook Execution Wrapper (from spec 18.2)
# -----------------------------------------------------------------------------

run_hook_safely() {
  local hook="$1"
  local input="${2:-}"
  local timeout_secs="${3:-$DEFAULT_HOOK_TIMEOUT}"
  local output
  local exit_code

  # Check if hooks are enabled at current degradation level
  if ! is_feature_enabled "hooks"; then
    log_diagnostic "INFO" "Hooks disabled at degradation level $CURRENT_DEGRADATION_LEVEL"
    return 0
  fi

  # Check if hook exists and is executable
  if [[ ! -x "$hook" ]]; then
    log_error "hook_not_found" "$hook" "Hook does not exist or is not executable" "bypassed"
    return 0
  fi

  # Run with timeout
  if [[ -n "$input" ]]; then
    output=$(timeout "$timeout_secs" "$hook" <<< "$input" 2>&1)
  else
    output=$(timeout "$timeout_secs" "$hook" 2>&1)
  fi
  exit_code=$?

  case $exit_code in
    0)
      echo "$output"
      return 0
      ;;
    124)
      # Timeout
      ((SESSION_HOOK_FAILURES++))
      save_health_state
      log_error "hook_timeout" "$hook" "Timed out after ${timeout_secs}s" "bypassed"
      echo "[!] Hook timed out: $(basename "$hook") (bypassing)"
      check_degradation_triggers > /dev/null
      return 0
      ;;
    *)
      # Hook crashed
      ((SESSION_HOOK_FAILURES++))
      save_health_state
      log_error "hook_failure" "$hook" "Exit code $exit_code: $output" "bypassed"
      echo "[!] Hook failed: $(basename "$hook") (bypassing)"
      check_degradation_triggers > /dev/null
      return 0
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Agent Execution Wrapper
# -----------------------------------------------------------------------------

run_agent_safely() {
  local agent_cmd="$1"
  local timeout_secs="${2:-$DEFAULT_AGENT_TIMEOUT}"
  local retry_on_invalid="${3:-true}"
  local output
  local exit_code

  # Check if agents are enabled
  if ! is_feature_enabled "agents"; then
    log_diagnostic "INFO" "Agents disabled at degradation level $CURRENT_DEGRADATION_LEVEL"
    escalate_to_user "Agent Required" "Agents are disabled but operation requires one" \
      "Reset degradation level with '/jarvis reset'\nCheck system health with '/jarvis doctor'"
    return 1
  fi

  output=$(timeout "$timeout_secs" bash -c "$agent_cmd" 2>&1)
  exit_code=$?

  case $exit_code in
    0)
      echo "$output"
      return 0
      ;;
    124)
      # Timeout
      ((SESSION_AGENT_TIMEOUTS++))
      save_health_state
      log_error "agent_timeout" "$agent_cmd" "Timed out after ${timeout_secs}s" "killed"
      check_degradation_triggers > /dev/null
      return 1
      ;;
    *)
      log_error "agent_failure" "$agent_cmd" "Exit code $exit_code: $output" "failed"
      return 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Self-Healing Mechanisms (from spec 18.8)
# -----------------------------------------------------------------------------

attempt_self_heal() {
  local pattern="$1"
  local frequency="${2:-1}"

  case $pattern in
    "hook_timeout")
      if (( frequency >= 3 )); then
        # Increase timeout for future hooks
        local new_timeout=$((DEFAULT_HOOK_TIMEOUT + 5))
        if (( new_timeout <= 30 )); then
          DEFAULT_HOOK_TIMEOUT=$new_timeout
          log_diagnostic "INFO" "Self-heal: Increased hook timeout to ${new_timeout}s"
          return 0
        fi
      fi
      ;;
    "skill_not_found")
      log_diagnostic "INFO" "Self-heal: Regenerating skill index"
      # Trigger skill index regeneration (implementation-specific)
      return 0
      ;;
    "context_overflow")
      log_diagnostic "INFO" "Self-heal: Triggering aggressive compaction"
      # Signal for context compaction (implementation-specific)
      return 0
      ;;
    *)
      return 1
      ;;
  esac

  return 1
}

# -----------------------------------------------------------------------------
# Unified Error Handler
# -----------------------------------------------------------------------------

handle_error() {
  local error_type="$1"
  local component="$2"
  local context="${3:-}"
  local alternatives="${4:-}"  # Comma-separated list of alternative commands

  ((SESSION_REPEATED_FAILURES++))

  # L1: Retry with backoff (for transient errors)
  if [[ "$error_type" == "transient" ]] || [[ "$error_type" == "network" ]]; then
    log_diagnostic "INFO" "L1: Attempting retry with backoff for $component"
    if retry_with_backoff "$component" 3; then
      ((SESSION_REPEATED_FAILURES--))
      return 0
    fi
  fi

  # L2: Try alternatives
  if [[ -n "$alternatives" ]]; then
    log_diagnostic "INFO" "L2: Trying alternative approaches"
    IFS=',' read -ra alt_array <<< "$alternatives"
    if try_alternatives "${alt_array[@]}"; then
      ((SESSION_REPEATED_FAILURES--))
      return 0
    fi
  fi

  # Attempt self-healing
  attempt_self_heal "$error_type" "$SESSION_REPEATED_FAILURES"

  # L3: Check for degradation
  local new_level
  new_level=$(check_degradation_triggers)
  if (( new_level > 0 )); then
    log_diagnostic "WARN" "L3: System degraded to level $new_level"
  fi

  # L4: Escalate if necessary
  if should_escalate "$error_type" "$SESSION_REPEATED_FAILURES"; then
    log_diagnostic "ERROR" "L4: Escalating to user"
    escalate_to_user "$error_type" "$context" \
      "Check component: $component\nReview error logs\nConsider disabling problematic feature"
    return 1
  fi

  log_error "$error_type" "$component" "$context" "degraded"
  return 1
}

# -----------------------------------------------------------------------------
# Diagnostic Commands
# -----------------------------------------------------------------------------

run_diagnostics() {
  echo "============================================================"
  echo "Jarvis System Diagnostics"
  echo "============================================================"
  echo ""
  echo "Current State:"
  echo "  Degradation Level: $CURRENT_DEGRADATION_LEVEL"
  echo "  Hook Failures (session): $SESSION_HOOK_FAILURES"
  echo "  Agent Timeouts (session): $SESSION_AGENT_TIMEOUTS"
  echo "  Repeated Failures: $SESSION_REPEATED_FAILURES"
  echo ""
  echo "Thresholds:"
  echo "  L1: Hook failures >= $THRESHOLD_HOOK_FAILURES_L1, Agent timeouts >= $THRESHOLD_AGENT_TIMEOUTS_L1"
  echo "  L2: Hook failures >= $THRESHOLD_HOOK_FAILURES_L2, Agent timeouts >= $THRESHOLD_AGENT_TIMEOUTS_L2"
  echo "  L3: Repeated failures >= $THRESHOLD_REPEATED_FAILURES_L3"
  echo ""
  echo "Feature Status:"
  for feature in hooks non_essential_hooks agents parallel_agents skills full_verification; do
    if is_feature_enabled "$feature"; then
      echo "  $feature: ENABLED"
    else
      echo "  $feature: DISABLED"
    fi
  done
  echo ""
  echo "Recent Errors:"
  get_error_summary 5
  echo ""
  echo "============================================================"
}

# -----------------------------------------------------------------------------
# Initialize on source
# -----------------------------------------------------------------------------

init_error_system
