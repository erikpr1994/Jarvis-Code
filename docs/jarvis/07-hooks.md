# Hook System

> Part of the [Jarvis Specification](./README.md)

## 8. Hook System

### 8.1 Hook Types

| Hook Type | Trigger | Purpose |
|-----------|---------|---------|
| **SessionStart** | New session | Context loading, skill injection |
| **PreToolUse** | Before tool execution | Enforcement, validation |
| **PostToolUse** | After tool execution | Learning capture, metrics |
| **PreCompact** | Before context compaction | Session preservation |

### 8.2 Core Hooks

| Hook | Type | Purpose |
|------|------|---------|
| **session-start.sh** | SessionStart | Load using-skills, detect continuation |
| **skill-activation-prompt.sh** | SessionStart/UserPromptSubmit | Recommend skills based on keywords |
| **require-isolation.sh** | PreToolUse (Edit/Write) | Enforce worktree/Conductor isolation |
| **block-direct-submit.sh** | PreToolUse (Bash) | Require submit-pr skill for PRs |
| **coderabbit-review.sh** | PreToolUse (Bash) | Integrate CodeRabbit |
| **learning-capture.sh** | PostToolUse | Capture patterns for auto-learning |

### 8.3 Hook Configuration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "script": "~/.claude/hooks/session-start.sh",
        "runInBackground": false
      },
      {
        "script": "~/.claude/hooks/skill-activation-prompt.sh",
        "runInBackground": false
      }
    ],
    "PreToolUse": [
      {
        "script": "~/.claude/hooks/require-isolation.sh",
        "tools": ["Edit", "Write", "NotebookEdit"],
        "runInBackground": false
      },
      {
        "script": "~/.claude/hooks/block-direct-submit.sh",
        "tools": ["Bash"],
        "runInBackground": false
      }
    ],
    "PostToolUse": [
      {
        "script": "~/.claude/hooks/learning-capture.sh",
        "runInBackground": true
      }
    ]
  }
}
```

### 8.4 Hook Design Pattern

```bash
#!/bin/bash
# Hook: hook-name
# Trigger: HookType
# Purpose: What this hook does

# Read input (for PreToolUse)
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input')

# Logic here...

# Output (for blocking hooks)
# Exit 0 = allow, Exit 1 = block
# Can output JSON for additionalContext or user message
```

---

### 8.5 Hook Consolidation Analysis (COMPLETE)

#### 8.5.1 All Hooks Inventory

**CodeFast (1 hook):**
- skill-activation-prompt.mjs (UserPromptSubmit) - Node.js, keyword/intent matching

**Superpowers (1 hook):**
- session-start.sh (SessionStart) - Injects using-superpowers skill

**Peak-Health (5 hooks):**
- session-start.sh (SessionStart) - Injects using-skills skill
- session-start-update-main.sh (SessionStart) - Updates main branch context
- require-isolation.sh (PreToolUse: Edit/Write) - Blocks main branch modifications
- block-direct-submit.sh (PreToolUse: Bash) - Blocks direct gh pr create
- coderabbit-review.sh (PreToolUse: Bash) - Runs CodeRabbit before submit

**TOTAL: 7 hooks from source systems**

---

#### 8.5.2 Unified Hook Architecture

##### SESSION START HOOKS

| Hook | Purpose | Source | Decision |
|------|---------|--------|----------|
| **session-start.sh** | Load using-skills + detect continuation | All | **MERGE** |

**Combined session-start.sh:**
```bash
#!/bin/bash
# Hook: session-start
# Event: SessionStart
# Purpose: Initialize session with skills, detect continuation, set context

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Load using-skills content (always)
SKILLS_CONTENT=$(cat ~/.claude/skills/using-skills/SKILL.md 2>/dev/null || echo "")

# 2. Detect session continuation
SESSION_FILE=$(find .claude/tasks -name "session-*.md" -mmin -240 2>/dev/null | head -1)
if [ -n "$SESSION_FILE" ]; then
  SESSION_MODE="continue"
  CONTEXT="Continuing session. Active: $SESSION_FILE"
else
  SESSION_MODE="fresh"
  CONTEXT="Starting fresh session"
fi

# 3. Output JSON with context
escape_for_json() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g'
}

ESCAPED_SKILLS=$(escape_for_json "$SKILLS_CONTENT")
ESCAPED_CONTEXT=$(escape_for_json "$CONTEXT")

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${ESCAPED_SKILLS}\n\n${ESCAPED_CONTEXT}"
  }
}
EOF
```

##### USER PROMPT SUBMIT HOOKS

| Hook | Purpose | Source | Decision |
|------|---------|--------|----------|
| **skill-activation.sh** | Recommend skills based on keywords | CodeFast | **KEEP (ADAPT)** |

##### PRE-TOOL-USE HOOKS (Enforcement)

| Hook | Tools | Purpose | Source | Decision |
|------|-------|---------|--------|----------|
| **require-isolation.sh** | Edit, Write, NotebookEdit | Block main branch/workspace | Peak-Health | **KEEP** |
| **block-direct-submit.sh** | Bash | Require submit-pr skill | Peak-Health | **KEEP** |
| **compress-output.sh** | Bash | Compress test/lint output | NEW | **CREATE** |

##### PRE-TOOL-USE HOOKS (Integration)

| Hook | Tools | Purpose | Source | Decision |
|------|-------|---------|--------|----------|
| **coderabbit-review.sh** | Bash | Run CodeRabbit before submit | Peak-Health | **KEEP** |

##### POST-TOOL-USE HOOKS (Learning)

| Hook | Tools | Purpose | Source | Decision |
|------|-------|---------|--------|----------|
| **learning-capture.sh** | * | Capture patterns for auto-learning | NEW | **CREATE** |

##### PRE-COMPACT HOOKS (Preservation)

| Hook | Purpose | Source | Decision |
|------|---------|--------|----------|
| **pre-compact-preserve.sh** | Save session state before compaction | NEW | **CREATE** |

---

#### 8.5.3 Final Hook Count

| Event | Count | Hooks |
|-------|-------|-------|
| **SessionStart** | 1 | session-start.sh |
| **UserPromptSubmit** | 1 | skill-activation.sh |
| **PreToolUse (Enforce)** | 3 | require-isolation, block-direct-submit, compress-output |
| **PreToolUse (Integrate)** | 1 | coderabbit-review |
| **PostToolUse** | 1 | learning-capture |
| **PreCompact** | 1 | pre-compact-preserve |
| **TOTAL** | 8 | Unified architecture |

---

#### 8.5.4 Unified Hook Configuration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "script": "~/.claude/hooks/session-start.sh",
        "runInBackground": false
      }
    ],
    "UserPromptSubmit": [
      {
        "script": "~/.claude/hooks/skill-activation.sh",
        "runInBackground": false
      }
    ],
    "PreToolUse": [
      {
        "script": "~/.claude/hooks/require-isolation.sh",
        "tools": ["Edit", "Write", "NotebookEdit"],
        "runInBackground": false
      },
      {
        "script": "~/.claude/hooks/block-direct-submit.sh",
        "tools": ["Bash"],
        "runInBackground": false
      },
      {
        "script": "~/.claude/hooks/compress-output.sh",
        "tools": ["Bash"],
        "runInBackground": false
      },
      {
        "script": "~/.claude/hooks/coderabbit-review.sh",
        "tools": ["Bash"],
        "runInBackground": false
      }
    ],
    "PostToolUse": [
      {
        "script": "~/.claude/hooks/learning-capture.sh",
        "runInBackground": true
      }
    ],
    "PreCompact": [
      {
        "script": "~/.claude/hooks/pre-compact-preserve.sh",
        "runInBackground": false
      }
    ]
  }
}
```

---

#### 8.5.5 Hook Bypass Mechanisms

| Hook | Bypass Method | Use Case |
|------|---------------|----------|
| **require-isolation** | `CLAUDE_ALLOW_MAIN_MODIFICATIONS=1` | Emergency fixes |
| **require-isolation** | `CONDUCTOR_ROOT_PATH` set | Conductor sessions |
| **require-isolation** | Worktree detected (.git is file) | Normal workflow |
| **block-direct-submit** | `CLAUDE_SUBMIT_PR_SKILL=1` | submit-pr skill active |
| **coderabbit-review** | `SKIP_CODERABBIT=1` | Manual override |
| **compress-output** | `VERBOSE_OUTPUT=1` | Debugging |

---

#### 8.5.6 Hook Library (Shared Utilities)

```bash
# ~/.claude/hooks/lib/common.sh

# JSON parsing without jq dependency
parse_tool_name() {
  echo "$1" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | \
    sed 's/.*: *"//' | sed 's/"$//'
}

parse_file_path() {
  echo "$1" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | \
    sed 's/.*: *"//' | sed 's/"$//'
}

parse_command() {
  echo "$1" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | \
    sed 's/.*: *"//' | sed 's/"$//'
}

# Output helpers
output_block() {
  cat << EOF
{"decision": "block", "reason": "$1"}
EOF
}

output_context() {
  cat << EOF
{"hookSpecificOutput": {"additionalContext": "$1"}}
EOF
}
```

---

#### 8.5.7 Skill Activation Hook (skill-rules.json)

```json
{
  "skills": {
    "test-driven-development": {
      "priority": "critical",
      "keywords": ["implement", "feature", "fix", "bug", "add function"],
      "patterns": ["(add|create|build|implement).*", "test.*first"],
      "enforcement": "suggest"
    },
    "git-expert": {
      "priority": "high",
      "keywords": ["commit", "push", "branch", "PR", "merge", "git"],
      "patterns": ["submit.*review", "ready.*PR"],
      "enforcement": "suggest"
    },
    "debug": {
      "priority": "high",
      "keywords": ["debug", "error", "failing", "broken", "not working"],
      "patterns": ["why.*fail", "investigate.*issue"],
      "enforcement": "suggest"
    }
  }
}
```
