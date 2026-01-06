# Escalation Guide

> When and how to escalate issues to the user

## Overview

Escalation (L4) is the final level of the error recovery strategy. It should be used when:
- Automated recovery has failed
- Human judgment is required
- Security or data integrity is at risk
- The system cannot determine the correct course of action

## Escalation Principles

### 1. Escalate Early for Critical Issues

Some issues should bypass L1-L3 and escalate immediately:

| Issue Type | Reason | Action |
|------------|--------|--------|
| Security vulnerability | User data at risk | Immediate escalation |
| Data corruption | Potential data loss | Immediate escalation |
| Agent refusal | Ethical/policy concern | Immediate escalation |
| Infinite loop detected | System stability | Immediate escalation |

### 2. Escalate Late for Recoverable Issues

For non-critical issues, exhaust recovery options first:

```
Transient error
  -> L1: Retry 3 times
    -> L2: Try alternatives
      -> L3: Degrade functionality
        -> L4: Escalate only if still failing
```

### 3. Provide Actionable Information

Every escalation must include:
- **What happened**: Clear description of the error
- **What was tried**: Recovery attempts made
- **Impact**: What functionality is affected
- **Options**: What the user can do

---

## When to Escalate

### Immediate Escalation (Always)

```bash
# These should ALWAYS escalate, regardless of retry count
escalation_required_immediately() {
  local error_type="$1"

  case $error_type in
    "security")           return 0 ;;  # Security issues
    "data_loss")          return 0 ;;  # Potential data loss
    "data_corruption")    return 0 ;;  # Data integrity issues
    "agent_refusal")      return 0 ;;  # Agent refuses task
    "infinite_loop")      return 0 ;;  # Detected loop
    "authentication")     return 0 ;;  # Auth failures
    *)                    return 1 ;;  # Not immediate
  esac
}
```

### Conditional Escalation

| Condition | Threshold | Escalation Trigger |
|-----------|-----------|-------------------|
| Repeated failures | >= 5 | Same error 5+ times |
| Hook failures | >= 5 | After L3 degradation |
| Agent timeouts | >= 4 | After L3 degradation |
| Validation failures | >= 3 | After 3 failed retries |
| Unknown errors | >= 2 | Cannot categorize error |

### Decision Flow

```
                    Error Occurs
                         |
                         v
              Is it a critical error?
                    /         \
                  Yes          No
                   |            |
                   v            v
           IMMEDIATE       Try L1-L3
           ESCALATION          |
                               v
                      Recovery successful?
                          /         \
                        Yes          No
                         |            |
                         v            v
                     Continue    Check threshold
                                      |
                                      v
                              Threshold exceeded?
                                 /         \
                               Yes          No
                                |            |
                                v            v
                           ESCALATE    Continue degraded
```

---

## How to Escalate

### Escalation Message Format

```
============================================================
[ATTENTION REQUIRED] {Issue Type}
============================================================

Context: {What the user was trying to do}

What happened:
  {Clear description of the error}

What was attempted:
  - {Recovery attempt 1}
  - {Recovery attempt 2}
  - {Recovery attempt 3}

Impact:
  {What functionality is affected}

Suggested actions:
  1. {Most likely solution}
  2. {Alternative solution}
  3. {Diagnostic command}

Options:
  - Run '/jarvis doctor' for full diagnostics
  - Check logs: ~/.claude/logs/errors.log
  - Reset system: '/jarvis reset'
============================================================
```

### Example Escalations

#### Security Issue

```
============================================================
[ATTENTION REQUIRED] Security Concern Detected
============================================================

Context: Attempting to execute hook 'pre-commit.sh'

What happened:
  The hook script attempted to access credentials outside
  the project directory. This behavior is unexpected and
  potentially dangerous.

What was attempted:
  - Hook execution was blocked
  - No credentials were exposed

Impact:
  Pre-commit hook is disabled for this session.

Suggested actions:
  1. Review the hook script: /path/to/pre-commit.sh
  2. Check if the hook was modified recently
  3. Verify the source of the hook

Options:
  - Run '/jarvis doctor' for full diagnostics
  - Check logs: ~/.claude/logs/errors.log
  - Disable hook: '/jarvis disable hook pre-commit'
============================================================
```

#### Repeated Failure

```
============================================================
[ATTENTION REQUIRED] Repeated Operation Failure
============================================================

Context: Running code analysis agent

What happened:
  The code-analysis agent has failed 5 times in succession.
  Last error: "Model returned invalid JSON response"

What was attempted:
  - L1: Retried 3 times with backoff
  - L2: Tried alternative model (haiku)
  - L3: Degraded to minimal analysis mode

Impact:
  Full code analysis is unavailable. Basic linting only.

Suggested actions:
  1. Check API status at status.anthropic.com
  2. Verify API key is valid and has quota
  3. Try again in a few minutes

Options:
  - Run '/jarvis doctor' for full diagnostics
  - Check logs: ~/.claude/logs/errors.log
  - Reset system: '/jarvis reset'
============================================================
```

#### Agent Refusal

```
============================================================
[ATTENTION REQUIRED] Agent Refused Task
============================================================

Context: Requested code modification

What happened:
  The agent declined to perform the requested modification,
  citing potential security concerns with the approach.

Agent response:
  "I cannot modify authentication logic in this way as it
   would bypass security checks. Please review the approach."

What was attempted:
  - No automatic recovery attempted (refusal requires review)

Impact:
  The requested modification was not made.

Suggested actions:
  1. Review the requested change for security implications
  2. Provide additional context about why this approach is safe
  3. Consider an alternative implementation approach

Options:
  - Provide more context and retry
  - Use a different approach
  - Override with explicit confirmation (not recommended)
============================================================
```

---

## User Response Handling

### Expected User Actions

After escalation, users typically will:

1. **Investigate**: Review logs and diagnostics
2. **Fix root cause**: Address the underlying issue
3. **Retry**: Attempt the operation again
4. **Override**: Force continue despite warnings
5. **Abort**: Stop the current operation

### Jarvis Commands for Recovery

| Command | Description |
|---------|-------------|
| `/jarvis doctor` | Run full system diagnostics |
| `/jarvis reset` | Reset degradation level and counters |
| `/jarvis logs` | View recent error logs |
| `/jarvis disable hook <name>` | Disable problematic hook |
| `/jarvis status` | Show current system status |

---

## Escalation API

### Using escalate_to_user()

```bash
source /path/to/lib/error-handler.sh

# Basic escalation
escalate_to_user \
  "Hook Failure" \
  "The pre-commit hook failed after multiple retries"

# With suggestions
escalate_to_user \
  "Agent Timeout" \
  "Code review agent timed out on large file set" \
  "Split the review into smaller batches
Try with --quick flag for faster review
Use local linter instead"
```

### Using should_escalate()

```bash
source /path/to/lib/error-handler.sh

# Check if escalation is warranted
if should_escalate "repeated_failure" 5; then
  escalate_to_user "Operation Failed" "Details here"
fi

# Security issues always escalate
if should_escalate "security" 1; then
  # This will return true
  escalate_to_user "Security Issue" "Details here"
fi
```

### Using handle_error() (Unified)

```bash
source /path/to/lib/error-handler.sh

# Unified handler that manages L1-L4 automatically
handle_error \
  "agent_timeout" \
  "code-review-agent" \
  "Reviewing 50 files, timed out after 60s" \
  "quick-review-agent,lint-only"
```

---

## Escalation Severity Levels

| Severity | Visual | Use When |
|----------|--------|----------|
| INFO | `[i]` | Informational, user awareness only |
| WARNING | `[!]` | Action recommended but not required |
| ERROR | `[!!]` | Action required to continue |
| CRITICAL | `[!!!]` | Immediate action required |

### Severity Selection

```bash
# INFO: Degradation notice
echo "[i] Switched to reduced verification mode"

# WARNING: Feature disabled
echo "[!] Hook 'skill-activation' disabled due to repeated failures"

# ERROR: Operation blocked
echo "[!!] Cannot proceed with commit - review required"

# CRITICAL: Security/data issue
echo "[!!!] SECURITY: Unexpected credential access detected"
```

---

## Best Practices

### Do

- Provide clear, actionable messages
- Include all relevant context
- Suggest specific next steps
- Log all escalations for analysis
- Allow users to make informed decisions

### Don't

- Escalate too frequently (escalation fatigue)
- Use technical jargon without explanation
- Provide vague error messages
- Escalate without attempting recovery first
- Block user progress without alternatives

### Message Quality Checklist

- [ ] Is the issue clearly described?
- [ ] Is the impact explained?
- [ ] Are recovery attempts documented?
- [ ] Are actionable suggestions provided?
- [ ] Are relevant commands/logs mentioned?
- [ ] Is the severity appropriate?
