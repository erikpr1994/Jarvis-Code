---
name: jarvis-config
description: Configure Jarvis preferences - rules, features, and behavior settings
disable-model-invocation: false
---

# /jarvis-config - Jarvis Configuration

> **Note:** Use `/config` for Claude Code's built-in settings UI.

Manage your Jarvis preferences interactively.

## Usage

```
/jarvis-config              # Show all config and offer to change
/jarvis-config rules        # Configure rule preferences
/jarvis-config features     # Configure feature toggles
/jarvis-config reset        # Reset to defaults
```

## Process

### 1. Read Current Config

Read the current configuration from `~/.claude/config/jarvis.json`:

```bash
cat ~/.claude/config/jarvis.json
```

### 2. Present Options with AskUserQuestion

Based on the scope ($ARGUMENTS), use the AskUserQuestion tool to let the user configure:

#### For `rules` or no argument:

Ask about each rule preference:

**Question 1: TDD Requirement**
- Header: "TDD"
- Question: "Should Claude follow strict Test-Driven Development (write tests before code)?"
- Options:
  - "Yes - Require TDD" (description: "Claude must write failing tests before implementation")
  - "No - TDD optional" (description: "Testing encouraged but not enforced as TDD")

**Question 2: Worktree Isolation**
- Header: "Isolation"
- Question: "Require worktree/branch isolation before editing files on main?"
- Options:
  - "Yes - Block main edits" (description: "Prevent direct modifications to main/master branch")
  - "No - Allow main edits" (description: "Allow editing files on any branch")

**Question 3: Pre-commit Tests**
- Header: "Pre-commit"
- Question: "Require tests to pass before allowing commits?"
- Options:
  - "Yes - Tests required" (description: "Block commits if tests fail")
  - "No - Allow commits" (description: "Commits allowed regardless of test status")

**Question 4: Commit Format**
- Header: "Commits"
- Question: "Enforce conventional commit message format?"
- Options:
  - "Yes - Conventional" (description: "Require feat:, fix:, chore: prefixes")
  - "No - Freeform" (description: "Any commit message format allowed")

### 3. Update Config

After collecting answers, update `~/.claude/config/jarvis.json`:

```bash
# Read current config
config=$(cat ~/.claude/config/jarvis.json)

# Update rules section based on answers
# Use jq to modify the JSON
```

Example update:
```bash
jq '.rules.requireTDD = false | .rules.requireWorktreeIsolation = true' \
  ~/.claude/config/jarvis.json > /tmp/jarvis.json && \
  mv /tmp/jarvis.json ~/.claude/config/jarvis.json
```

### 4. Confirm Changes

Show the updated configuration:

```markdown
## Configuration Updated

| Setting | Value |
|---------|-------|
| Require TDD | No |
| Require Worktree Isolation | Yes |
| Tests Before Commit | Yes |
| Conventional Commits | Yes |

Changes saved to `~/.claude/config/jarvis.json`

**Note:** Restart Claude Code for hook changes to take effect.
```

## Reset to Defaults

For `/jarvis-config reset`:

```json
{
  "rules": {
    "requireTDD": false,
    "requireWorktreeIsolation": false,
    "requireTestsBeforeCommit": true,
    "requireConventionalCommits": true,
    "strictTypeScript": true
  }
}
```

## Examples

**Configure everything interactively:**
```
/jarvis-config
```

**Just configure rules:**
```
/jarvis-config rules
```

**Reset to defaults:**
```
/jarvis-config reset
```
