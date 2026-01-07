# Jarvis - AI Assistant Enhancement System for Claude Code

Jarvis is an advanced system that enhances [Claude Code CLI](https://claude.ai/code) with intelligent skills, safety hooks, automated workflows, and productivity features.

## Features

### Safety & Protection
- **Git Safety Guard** - Blocks destructive commands (`git reset --hard`, `git push --force`, `rm -rf`)
- **PR Workflow Enforcement** - Ensures proper PR submission process with code review
- **Worktree Isolation** - Optional protection against editing files on main branch

### Productivity
- **Smart Skill Activation** - Automatically suggests relevant skills based on context
- **Custom Status Line** - Shows git info, context usage, cost tracking in terminal
- **Session Tracking** - Maintains context across conversations
- **Learning Capture** - Learns from successful patterns

### Customization
- **Configurable Rules** - Toggle TDD, worktree isolation, pre-commit tests
- **Specialized Agents** - Code reviewer, test generator, and more
- **Custom Commands** - Slash commands for common workflows
- **Pattern Library** - Reusable solutions indexed by context

## Requirements

- **Claude Code CLI** - https://claude.ai/code
- **Git** - Version control
- **Bash 4+** - Shell scripting
- **jq** - JSON processing (for config management)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/erikpr1994/claude-code-tools.git
cd claude-code-tools

# Install globally
./install.sh

# Start Claude Code in any project
cd your-project
claude

# Initialize Jarvis for this project
/init
```

## Installation

### Standard Install

```bash
./install.sh
```

### Installation Options

```bash
./install.sh              # Interactive install with preferences setup
./install.sh --skip-config # Install with default preferences
./install.sh --force      # Skip version prompts
./install.sh --help       # Show help
```

The installer will prompt you to configure which hooks and rules you want enabled.

### What Gets Installed

```
~/.claude/
├── settings.json          # Claude Code settings (hooks, statusline)
├── config/
│   ├── preferences.json   # Your rules & hooks preferences
│   └── defaults.json      # Default preference values
├── statusline.sh          # Custom status bar script
├── hooks/                 # Event-driven automations
│   ├── git-safety-guard.sh    # Blocks destructive git commands
│   ├── block-direct-submit.sh # Enforces PR workflow
│   ├── require-isolation.sh   # Worktree/branch protection
│   ├── skill-activation.sh    # Smart skill suggestions
│   ├── pre-commit.sh          # Pre-commit verification
│   └── lib/common.sh          # Shared hook utilities
├── skills/                # Skill definitions
├── commands/              # Slash commands
├── agents/                # Specialized agents
├── rules/                 # Coding standards
├── patterns/              # Pattern library
└── lib/                   # Utilities
```

## Commands

| Command | Description |
|---------|-------------|
| `/init` | Initialize Jarvis in current project |
| `/update` | Update Jarvis from repo |
| `/config` | Configure preferences interactively |
| `/plan` | Create implementation plan |
| `/review` | Run code review |
| `/test` | Run tests with TDD guidance |
| `/commit` | Smart commit with verification |
| `/skills` | List available skills |

## Configuration

### Interactive Setup

During installation, you'll be prompted to configure your preferences. You can reconfigure anytime with `/config`.

### Preferences File

Edit `~/.claude/config/preferences.json` or use `/config`:

```json
{
  "version": "1.0.0",
  "rules": {
    "tdd": { "enabled": false, "severity": "warning" },
    "conventionalCommits": { "enabled": true, "severity": "warning" },
    "codeQuality": { "enabled": true, "severity": "info" },
    "documentation": { "enabled": true, "severity": "info" }
  },
  "hooks": {
    "gitSafetyGuard": { "enabled": true, "bypassable": true },
    "requireIsolation": { "enabled": false, "bypassable": true },
    "preCommitTests": { "enabled": false, "bypassable": true },
    "skillActivation": { "enabled": true, "bypassable": false },
    "learningCapture": { "enabled": true, "bypassable": false }
  }
}
```

### Rules vs Hooks

| Type | Purpose | Effect |
|------|---------|--------|
| **Rules** | Soft guidelines for Claude | Suggestions, warnings |
| **Hooks** | Hard enforcement mechanisms | Block actions, require steps |

### Severity Levels

- `error` - Block the action
- `warning` - Allow with caution message
- `info` - Suggest, don't enforce

### Safety Hooks

The git-safety-guard blocks dangerous commands:

| Blocked | Safe Alternative |
|---------|------------------|
| `git reset --hard` | `git stash` first |
| `git push --force` | `--force-with-lease` |
| `git checkout -- files` | `git stash` first |
| `git clean -f` | `git clean -n` first |
| `git branch -D` | `git branch -d` |
| `rm -rf` | Ask user to run manually |

**Bypass:** Set `CLAUDE_ALLOW_DESTRUCTIVE=1` for legitimate use.

### Status Line

Custom terminal status showing:
- Project name and git branch
- File changes (+added/-removed)
- Context window usage (%)
- Session cost ($)

Configured in `settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## Updating

```bash
# Pull latest changes
cd claude-code-tools
git pull

# Update installation
/update              # Or run from Claude Code
./install.sh         # Or run installer directly
```

Updates preserve your customizations:
- Files with `# JARVIS-USER-MODIFIED` header are never overwritten
- `rules` section in `jarvis.json` is preserved
- `<!-- USER CUSTOMIZATIONS -->` sections in CLAUDE.md are kept

## Skills System

Skills are automatically suggested based on conversation context.

### Skill Categories

| Category | Examples |
|----------|----------|
| **Process** | TDD, debugging, verification |
| **Domain** | Git workflow, API design, database |
| **Meta** | Writing skills, patterns |

### Skill Activation

When you see `SKILL ACTIVATION CHECK`, invoke the recommended skills:

```
SKILL ACTIVATION CHECK

CRITICAL SKILLS (REQUIRED):
  -> test-driven-development
  -> session-management
```

Use the Skill tool: `skill: "tdd"`

## Hooks System

Hooks run automatically on Claude Code events:

| Event | Hook | Purpose |
|-------|------|---------|
| `PreToolUse:Bash` | git-safety-guard | Block destructive commands |
| `PreToolUse:Bash` | block-direct-submit | Enforce PR workflow |
| `PreToolUse:Edit` | require-isolation | Worktree protection |
| `UserPromptSubmit` | skill-activation | Suggest relevant skills |
| `SessionStart` | session-start | Initialize session |
| `PostToolUse` | learning-capture | Capture patterns |

## Project Structure

```
claude-code-tools/
├── install.sh              # Installer
├── uninstall.sh            # Uninstaller
├── README.md               # This file
├── VERSION                 # Current version
├── global/                 # Files installed to ~/.claude/
│   ├── settings.json       # Claude Code settings
│   ├── jarvis.json         # Jarvis config
│   ├── statusline.sh       # Status bar script
│   ├── hooks/              # Hook scripts
│   ├── skills/             # Skill definitions
│   ├── commands/           # Slash commands
│   ├── agents/             # Agent definitions
│   ├── rules/              # Coding standards
│   ├── patterns/           # Pattern library
│   └── lib/                # Utilities
├── init/                   # First-run setup
└── templates/              # Project templates
```

## Troubleshooting

### Hook not working
Restart Claude Code after changing `settings.json`.

### Permission denied
```bash
chmod +x install.sh ~/.claude/hooks/*.sh
```

### jq not found
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

### Restore from backup
Backups are in `~/.claude/backups/`:
```bash
cp -R ~/.claude/backups/YYYYMMDD_HHMMSS/* ~/.claude/
```

## Contributing

1. **New Hook**: Add to `global/hooks/` and update `settings.json`
2. **New Skill**: Add to `global/skills/[category]/`
3. **New Command**: Add to `global/commands/`
4. **New Pattern**: Add to `global/patterns/full/` and update `index.json`

## License

MIT License - See LICENSE file for details.

## Acknowledgments

- Git safety guard inspired by [Dicklesworthstone's hooks](https://github.com/Dicklesworthstone/misc_coding_agent_tips_and_scripts)
- Built for [Claude Code](https://claude.ai/code) by Anthropic
