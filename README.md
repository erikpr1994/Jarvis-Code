# Jarvis - AI Assistant for Claude Code

Jarvis is an advanced AI assistant system that enhances Claude Code CLI with intelligent skills, agents, commands, and automation hooks.

## Features

- **Smart Skill Activation** - Automatically suggests and activates relevant skills based on context
- **Specialized Agents** - Pre-configured agents for code review, test generation, and more
- **Custom Commands** - Slash commands for common workflows
- **Pattern Library** - Indexed library of reusable patterns and solutions
- **Session Tracking** - Track progress across sessions with learning capture
- **Hooks System** - Event-driven automations for various Claude actions

## Requirements

### Required

- **Git** - Version control (for project analysis)
- **Bash 4+** - Shell scripting support

### Recommended

- **Claude CLI** - Claude Code command line interface (https://claude.ai/code)
- **Node.js 18+** - Required for some hooks and utilities

## Installation

### Quick Install

```bash
cd jarvis
./install.sh
```

### Installation Options

```bash
# Standard installation
./install.sh

# Force installation without prompts
./install.sh --force

# Show help
./install.sh --help
```

### What Gets Installed

The installer creates the following structure at `~/.claude/`:

```
~/.claude/
├── settings.json           # Global settings
├── skill-rules.json        # Skill activation rules
├── hooks.json              # Hooks configuration
├── agents/                 # Shared agents
│   ├── core/              # Core agents (always available)
│   ├── code-reviewer.md   # Code review agent
│   └── test-generator.md  # TDD/test generation agent
├── skills/                 # Skill definitions
│   ├── meta/              # Meta-skills (skill usage)
│   ├── process/           # Process skills (TDD, debugging)
│   └── domain/            # Domain skills (git, patterns)
├── commands/              # Custom slash commands
│   └── init.md           # Project initialization command
├── hooks/                 # Event-driven automations
│   └── lib/              # Hook utilities
├── patterns/             # Pattern library
│   ├── index.json        # Pattern index
│   └── full/             # Full pattern files
├── rules/                # Global behavior rules
└── lib/                  # Shared utilities
    └── skills-core.js    # Skill discovery library
```

## Usage

### Getting Started

1. **Install Jarvis** (see Installation above)

2. **Navigate to a project**
   ```bash
   cd your-project
   ```

3. **Start Claude CLI**
   ```bash
   claude
   ```

4. **Initialize Jarvis in the project**
   ```
   /init
   ```

### Available Commands

| Command | Description |
|---------|-------------|
| `/init` | Initialize Jarvis in the current project |
| `/init nextjs` | Initialize with framework hint |

### Available Agents

| Agent | Description | Trigger Examples |
|-------|-------------|------------------|
| `code-reviewer` | Comprehensive multi-file code review | "review my changes", "check this PR" |
| `test-generator` | TDD and test generation | "write tests", "add test coverage" |

### Using Skills

Skills are automatically suggested based on your conversation context. The skill system detects keywords and intents to recommend relevant skills.

**Skill Categories:**

- **Meta Skills** - How to use and write skills
- **Process Skills** - TDD, debugging, verification workflows
- **Domain Skills** - Git workflows, design patterns

## Configuration

### Global Settings

Edit `~/.claude/settings.json` to customize global behavior:

```json
{
  "features": {
    "skillActivation": true,
    "sessionTracking": true,
    "learningCapture": true,
    "patternMatching": true
  },
  "skills": {
    "autoActivate": true
  }
}
```

### Skill Rules

Edit `~/.claude/skill-rules.json` to customize skill triggers:

```json
{
  "rules": [
    {
      "id": "tdd-process",
      "skill": "process/tdd",
      "triggers": {
        "keywords": ["test first", "TDD"],
        "intents": ["new-feature"]
      }
    }
  ]
}
```

### Preserving Customizations

Add the following comment to any file you've customized to prevent it from being overwritten during updates:

```
# JARVIS-USER-MODIFIED
```

## Updating

To update Jarvis to the latest version:

1. Pull the latest changes from the repository
2. Re-run the installer:
   ```bash
   ./install.sh
   ```

The installer is idempotent and will:
- Create a backup of existing configuration
- Preserve files marked with `# JARVIS-USER-MODIFIED`
- Update changed files
- Skip unchanged files

## Uninstallation

### Standard Uninstall

```bash
./uninstall.sh
```

This will:
- Create a backup of your configuration
- Remove all Jarvis files
- Preserve user files and backups

### Uninstall Options

```bash
# Standard uninstall with prompts
./uninstall.sh

# Skip confirmation prompts
./uninstall.sh --force

# Remove everything including backups (dangerous)
./uninstall.sh --purge

# Show help
./uninstall.sh --help
```

### Restoring from Backup

After uninstalling, you can restore from the backup:

```bash
cp -R ~/.claude/uninstall-backup-YYYYMMDD_HHMMSS/* ~/.claude/
```

## Project Structure

```
/
├── install.sh              # Main installer script
├── uninstall.sh            # Uninstaller script
├── README.md               # This file
├── global/                 # Files to install to ~/.claude/
│   ├── settings.json       # Global settings
│   ├── skill-rules.json    # Skill activation rules
│   ├── agents/             # Agent definitions
│   ├── skills/             # Skill definitions
│   ├── commands/           # Command definitions
│   ├── hooks/              # Hook scripts
│   ├── patterns/           # Pattern library
│   ├── rules/              # Behavior rules
│   └── lib/                # Utility libraries
├── init/                   # First-run initialization
└── templates/              # Project templates
    └── project-types/      # Framework-specific templates
```

## Troubleshooting

### Claude CLI not found

The installer will continue without Claude CLI, but you'll need to install it before using Jarvis:

1. Visit https://claude.ai/code
2. Follow the installation instructions
3. Verify with `claude --version`

### Permission denied

Make the scripts executable:

```bash
chmod +x install.sh uninstall.sh
```

### Backup location

Backups are stored in:
- Installation backups: `~/.claude/backups/`
- Uninstall backups: `~/.claude/uninstall-backup-YYYYMMDD_HHMMSS/`

### Conflicts with existing configuration

If you have an existing `~/.claude/` directory:

1. The installer automatically creates a backup
2. Jarvis files are merged with existing files
3. Files marked `# JARVIS-USER-MODIFIED` are preserved

## Contributing

To add new features to Jarvis:

1. **New Skill**: Add to `global/skills/[category]/skill-name.md`
2. **New Agent**: Add to `global/agents/agent-name.md`
3. **New Command**: Add to `global/commands/command-name.md`
4. **New Pattern**: Add to `global/patterns/full/` and update `index.json`

## License

MIT License - See LICENSE file for details.

## Support

For issues and feature requests, please open an issue on the repository.
