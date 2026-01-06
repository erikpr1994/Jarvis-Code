# Hooks

Event-driven automations triggered by Claude actions.

## Structure

```
hooks/
├── lib/                    # Shared utilities
│   └── common.sh           # Common hook functions
├── session-start.sh        # Triggered on session start
├── skill-activation.sh     # Triggered for skill matching
├── pre-tool-use/           # Before tool execution
│   ├── require-isolation.sh
│   ├── block-direct-submit.sh
│   └── coderabbit-review.sh
└── post-tool-use/          # After tool execution
    └── learning-capture.sh
```

## Hook Types

### Session Hooks
- `session-start` - Load context, detect continuation
- `session-end` - Archive session, capture learnings

### Skill Hooks
- `skill-activation` - Match prompts to skills, recommend skills

### Tool Hooks
- `pre-tool-use` - Validate before tool execution
- `post-tool-use` - Process after tool execution

## Hook Format

Hooks can be shell scripts or JavaScript files:

```bash
#!/bin/bash
# hook: pre-tool-use
# tool: git_push
# description: Ensure isolation before push

source "$(dirname "$0")/lib/common.sh"

# Hook logic here
if ! check_isolation; then
  echo "ERROR: Must use worktree for changes"
  exit 1
fi
```

## Key Hooks

### require-isolation.sh
Enforces worktree/Conductor usage for code changes.

### block-direct-submit.sh
Prevents direct PR submission - must use submit-pr skill.

### coderabbit-review.sh
Integrates automated code review.

### learning-capture.sh
Captures new patterns and learnings after execution.

## Hook Library (`lib/`)

Shared utilities for hooks:
- `common.sh` - Bash utilities
- `git-helpers.sh` - Git-related functions
- `validation.sh` - Validation helpers
