# Commands

Custom slash commands available in all projects.

## Structure

```
commands/
├── jarvis-init.md      # Initialize a new project with Jarvis
├── jarvis-config.md    # Configure Jarvis preferences
├── jarvis-review.md    # Comprehensive code review
├── status.md           # Show current session status
├── skills.md           # List and manage skills
└── ...
```

## Command Format

Each command is defined in a markdown file:

```markdown
---
name: command-name
description: Brief description
aliases: [alias1, alias2]
---

# /command-name

## Description
What this command does.

## Usage
/command-name [options]

## Options
- `--option1`: Description

## Examples
/command-name --option1 value
```

## Built-in Commands

These are the core commands that should be available:

| Command | Description |
|---------|-------------|
| `/jarvis-init` | Initialize Jarvis in current project |
| `/status` | Show session and task status |
| `/skills` | List available skills |
| `/resume` | Resume previous session |
| `/learn` | Capture new pattern or learning |

## Creating Commands

Commands are simple markdown files that Claude reads when invoked.
They can reference skills and trigger specific behaviors.
