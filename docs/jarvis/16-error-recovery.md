# Error Recovery

> Part of the [Jarvis Specification](./README.md)

## 18. Error Recovery

### 18.1 Error Categories

| Category | Severity | Example | Recovery Strategy |
|----------|----------|---------|-------------------|
| **Hook Failure** | High | Hook script crashes | Bypass hook, warn user |
| **Agent Timeout** | Medium | Agent takes too long | Kill agent, use fallback |
| **Skill Not Found** | Low | Skill file missing | Use default behavior |
| **Validation Failure** | Medium | Tests fail unexpectedly | Retry once, then ask user |
| **Context Overflow** | High | Token limit reached | Emergency compaction |
| **External Service** | Variable | GitHub/Supabase down | Queue action, retry later |

### 18.2 Hook Failure Recovery

```bash
#!/bin/bash
# Hook execution wrapper with recovery

run_hook_safely() {
  local hook="$1"
  local input="$2"
  local timeout="${3:-5}"  # Default 5 second timeout

  # Run with timeout and capture exit code
  OUTPUT=$(timeout "$timeout" "$hook" <<< "$input" 2>&1)
  EXIT_CODE=$?

  case $EXIT_CODE in
    0)
      echo "$OUTPUT"
      return 0
      ;;
    124)
      # Timeout - hook took too long
      echo "⚠️ Hook timed out: $hook (bypassing)"
      log_error "hook_timeout" "$hook"
      return 0  # Continue without hook
      ;;
    *)
      # Hook crashed
      echo "⚠️ Hook failed: $hook (bypassing)"
      log_error "hook_failure" "$hook" "$OUTPUT"
      return 0  # Continue without hook
      ;;
  esac
}
```

### 18.3 Agent Failure Recovery

| Failure Type | Detection | Recovery |
|--------------|-----------|----------|
| **Timeout** | No response in 60s | Kill, use simpler agent or skip |
| **Invalid Output** | Output doesn't match expected format | Retry with clearer prompt |
| **Refusal** | Agent refuses to complete task | Log reason, ask user for guidance |
| **Infinite Loop** | Same output repeated 3+ times | Force stop, escalate to user |

### 18.4 Graceful Degradation Levels

```
LEVEL 0: Full System
├── All hooks active
├── All agents available
├── All skills loaded
└── Full verification pipeline

LEVEL 1: Reduced Verification
├── Core hooks only (isolation, blocking)
├── Core agents only (implementer, reviewer)
├── Essential skills only
└── Quick verification (no parallel reviews)

LEVEL 2: Minimal System
├── Session-start hook only
├── No sub-agents (single-agent mode)
├── No skill loading
└── Basic TDD only

LEVEL 3: Emergency Mode
├── No hooks
├── No agents
├── No skills
└── Direct Claude responses only
```

### 18.5 Automatic Degradation Triggers

```yaml
degradation_rules:
  level_1:
    triggers:
      - hook_failures: 3          # 3+ hook failures in session
      - agent_timeouts: 2         # 2+ agent timeouts
      - context_usage: 80%        # Context nearing limit
    actions:
      - disable_non_essential_hooks
      - use_haiku_for_reviews     # Faster, cheaper
      - compress_skill_loading

  level_2:
    triggers:
      - hook_failures: 5
      - agent_timeouts: 4
      - context_usage: 90%
    actions:
      - disable_all_hooks_except_core
      - disable_parallel_agents
      - emergency_context_compaction

  level_3:
    triggers:
      - system_unresponsive: 30s
      - repeated_failures: 10
    actions:
      - disable_all_enhancements
      - notify_user_of_degraded_mode
```

### 18.6 Error Logging & Reporting

```json
{
  "errors": {
    "2026-01-04T10:30:00Z": {
      "type": "hook_timeout",
      "component": "skill-activation-prompt.sh",
      "context": "Large prompt with 50+ keywords",
      "recovery": "bypassed",
      "impact": "Skills not auto-suggested",
      "user_notified": true
    }
  },
  "health": {
    "current_level": 0,
    "hook_failures_session": 0,
    "agent_timeouts_session": 0,
    "last_degradation": null
  }
}
```

### 18.7 User Communication

When errors occur:

```markdown
## Transparent Notification
⚠️ Hook `skill-activation.sh` timed out. Continuing without skill suggestions.

## Degradation Notice
⚡ Switched to reduced verification mode due to multiple agent timeouts.
Full verification will resume next session.

## Recovery Suggestion
🔧 The skill-activation hook has failed 3 times. Consider:
1. Run `/jarvis doctor` to diagnose
2. Check hook logs: `~/.claude/logs/hooks.log`
3. Temporarily disable: `jarvis disable hook skill-activation`
```

### 18.8 Self-Healing Mechanisms

```yaml
self_healing:
  # Automatic fixes for known issues
  patterns:
    - pattern: "hook_timeout"
      frequency: 3
      action: "increase_timeout"
      params:
        increase_by: 5s
        max: 30s

    - pattern: "skill_not_found"
      action: "regenerate_skill_index"

    - pattern: "context_overflow"
      action: "aggressive_compaction"
      params:
        preserve: ["active_task", "last_decision", "current_file"]

    - pattern: "agent_quality_drop"
      frequency: 5
      action: "switch_to_opus"
      fallback: "ask_user"
```
