# Fallback Strategies

> Documentation for the Jarvis Error Recovery System

## Overview

The Jarvis error recovery system implements a four-level fallback strategy designed to maintain system functionality even when components fail. This document describes each fallback strategy and when to apply them.

## The Four-Level Recovery Strategy

```
L1: Retry with Backoff
    |
    v (if retries exhausted)
L2: Alternative Approach
    |
    v (if alternatives fail)
L3: Graceful Degradation
    |
    v (if degradation insufficient)
L4: User Escalation
```

---

## L1: Retry with Exponential Backoff

### When to Use

- Transient errors (network timeouts, temporary service unavailability)
- Rate limiting responses
- Intermittent connectivity issues

### Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_retries` | 3 | Maximum retry attempts |
| `initial_backoff` | 1s | Initial wait time |
| `max_backoff` | 30s | Maximum wait time |
| `multiplier` | 2 | Backoff multiplier |

### Backoff Sequence Example

```
Attempt 1: Immediate
Attempt 2: Wait 1s
Attempt 3: Wait 2s
Attempt 4: Wait 4s (capped at max_backoff)
```

### Usage

```bash
source /path/to/lib/error-handler.sh

# Basic retry
retry_with_backoff "curl -s https://api.example.com/data"

# Custom configuration
retry_with_backoff "command" 5 2 60 2
#                   cmd    retries initial max multiplier
```

### Best Practices

- Use for idempotent operations only
- Log each retry attempt for debugging
- Set reasonable max_backoff to avoid blocking

---

## L2: Alternative Approach

### When to Use

- Primary approach consistently fails
- Multiple valid methods exist for the same goal
- Fallback tools or commands are available

### Strategy Types

#### Tool Alternatives

```bash
# Example: File search with alternatives
try_alternatives \
  "fd 'pattern' /path" \
  "find /path -name 'pattern'" \
  "ls -la /path | grep pattern"
```

#### Model Alternatives

```yaml
# Agent model fallback chain
primary: claude-opus-4-5-20251101
alternatives:
  - claude-sonnet-4-20250514    # Faster, cheaper
  - claude-haiku                # Minimal fallback
```

#### Service Alternatives

```bash
# API endpoint alternatives
try_alternatives \
  "curl -s https://primary-api.com/data" \
  "curl -s https://backup-api.com/data" \
  "cat /cache/data.json"
```

### Usage

```bash
source /path/to/lib/error-handler.sh

# Try multiple approaches
try_alternatives \
  "primary_command" \
  "alternative_1" \
  "alternative_2"

# Returns output of first successful command
# Returns 1 if all fail
```

### Selection Criteria

| Scenario | Alternative Strategy |
|----------|---------------------|
| Hook timeout | Use simpler/faster hook |
| Agent timeout | Switch to faster model |
| API failure | Use cached data or backup API |
| Tool missing | Use equivalent system tool |

---

## L3: Graceful Degradation

### Degradation Levels

| Level | Name | Active Features | Disabled Features |
|-------|------|-----------------|-------------------|
| **0** | Full System | All hooks, agents, skills, full verification | None |
| **1** | Reduced | Core hooks, core agents, essential skills, quick verification | Non-essential hooks, parallel reviews |
| **2** | Minimal | Session-start hook, single-agent mode, basic TDD | All other hooks, skill loading, parallel agents |
| **3** | Emergency | Direct Claude responses only | All hooks, agents, skills |

### Automatic Triggers

#### Level 1 Triggers

```yaml
triggers:
  - hook_failures: >= 3
  - agent_timeouts: >= 2
  - context_usage: >= 80%
```

#### Level 2 Triggers

```yaml
triggers:
  - hook_failures: >= 5
  - agent_timeouts: >= 4
  - context_usage: >= 90%
```

#### Level 3 Triggers

```yaml
triggers:
  - system_unresponsive: >= 30s
  - repeated_failures: >= 10
```

### Feature Availability by Level

```bash
# Check if a feature is available
source /path/to/lib/error-handler.sh

if is_feature_enabled "parallel_agents"; then
  # Run parallel agent workflow
else
  # Fall back to sequential
fi
```

| Feature | L0 | L1 | L2 | L3 |
|---------|----|----|----|----|
| All hooks | Yes | No | No | No |
| Core hooks | Yes | Yes | No | No |
| Session-start hook | Yes | Yes | Yes | No |
| All agents | Yes | Yes | No | No |
| Core agents | Yes | Yes | Yes | No |
| Parallel agents | Yes | Yes | No | No |
| Skills | Yes | Yes | No | No |
| Full verification | Yes | No | No | No |

### Recovery from Degradation

Degradation automatically resets at:
- Session start (new conversation)
- Manual reset via `/jarvis reset`
- Successful completion of 10 operations without errors

---

## Strategy Selection Matrix

| Error Type | L1 Retry | L2 Alternative | L3 Degrade | L4 Escalate |
|------------|----------|----------------|------------|-------------|
| Network timeout | Yes | If cached data exists | - | After exhausted |
| Hook failure | - | Try simpler hook | After 3-5 failures | After 5 failures |
| Agent timeout | - | Try faster model | After 2-4 timeouts | If critical |
| Skill not found | - | Use default behavior | - | - |
| Validation failure | Once | - | - | If repeated |
| Context overflow | - | Emergency compaction | Immediate | - |
| Security issue | - | - | - | Immediate |
| Data corruption | - | - | - | Immediate |
| Agent refusal | - | - | - | Immediate |

---

## Implementation Examples

### Complete Error Handling Flow

```bash
source /path/to/lib/error-handler.sh

run_with_recovery() {
  local primary="$1"
  local alternative="$2"
  local context="$3"

  # L1: Try primary with retries
  if retry_with_backoff "$primary" 3; then
    return 0
  fi

  # L2: Try alternative
  if [[ -n "$alternative" ]]; then
    if eval "$alternative"; then
      return 0
    fi
  fi

  # L3/L4: Handle through unified handler
  handle_error "operation_failed" "$primary" "$context" "$alternative"
}
```

### Hook Execution with Fallback

```bash
source /path/to/lib/error-handler.sh

# Safe hook execution with automatic fallback
output=$(run_hook_safely "/path/to/hook.sh" "$input" 5)

# Hook is bypassed if it fails, execution continues
```

### Agent Execution with Fallback

```bash
source /path/to/lib/error-handler.sh

# Try primary agent, fall back to simpler one
if ! run_agent_safely "complex-agent --full-analysis" 60; then
  # Try simpler approach
  run_agent_safely "simple-agent --quick" 30
fi
```

---

## Monitoring and Debugging

### Check Current State

```bash
source /path/to/lib/error-handler.sh

# Full diagnostics
run_diagnostics

# Get degradation level
level=$(get_degradation_level)
echo "Current level: $level"

# Check health status
get_health_status | jq .
```

### Error Log Analysis

```bash
# View recent errors
get_error_summary 20

# Full error log
cat ~/.claude/logs/errors.log

# Health file
cat ~/.claude/state/health.json | jq .
```

---

## Best Practices

1. **Order matters**: Always try L1 before L2, L2 before L3
2. **Log everything**: Each fallback should be logged for debugging
3. **Fail gracefully**: Never let errors crash the system silently
4. **Preserve context**: Capture error details for escalation
5. **Notify users**: Always inform when operating in degraded mode
6. **Reset when stable**: Clear degradation after successful recovery
