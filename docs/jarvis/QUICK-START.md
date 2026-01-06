# Jarvis Quick Start Guide

Get up and running with Jarvis in 5 minutes.

## Prerequisites

- Git installed
- Bash 4+ (macOS/Linux default)
- Claude CLI installed (https://claude.ai/code)

## Installation (2 minutes)

```bash
# Clone or download Jarvis
git clone https://github.com/your-org/jarvis.git
cd jarvis

# Run the installer
./install.sh
```

The installer will:
- Create `~/.claude/` directory structure
- Install skills, agents, commands, and hooks
- Configure the hooks system
- Create backup of any existing configuration

## First Project Setup (3 minutes)

### 1. Navigate to Your Project

```bash
cd your-project
```

### 2. Start Claude CLI

```bash
claude
```

### 3. Initialize Jarvis

Type in Claude:
```
/init
```

This will:
- Detect your tech stack (TypeScript, Python, etc.)
- Create project-specific `.claude/` configuration
- Generate a customized `CLAUDE.md` for your project

## Essential Commands

| Command | What It Does |
|---------|--------------|
| `/init` | Initialize Jarvis in current project |
| `/plan` | Create implementation plan for a task |
| `/execute` | Execute planned tasks with TDD |
| `/status` | Show session progress and metrics |
| `/compact` | Compress context (auto-triggers at limit) |
| `/inbox` | Review learning inbox |
| `/learnings` | Search captured learnings |

## How Skills Work

Jarvis automatically activates relevant skills based on your prompts:

| You Say | Skills Activated |
|---------|-----------------|
| "implement a feature" | session-management, test-driven-development |
| "fix this bug" | systematic-debugging |
| "review this code" | code-review agent |
| "create tests" | test-generator agent |
| "commit these changes" | git-expert |

## Key Concepts

### Skills
Markdown files that teach Claude specific workflows (TDD, debugging, etc.)

### Agents
Specialized sub-agents for complex tasks (code review, test generation)

### Hooks
Automatic actions on events (session start, context compaction)

### Patterns
Reusable code solutions indexed by language and problem type

### Learning System
Captures patterns from your work for future improvement

## Directory Structure

After installation:

```
~/.claude/                    # Global config (shared across projects)
├── skills/                   # Skill definitions
├── agents/                   # Agent templates
├── commands/                 # Slash commands
├── hooks/                    # Event hooks
├── patterns/                 # Pattern library
└── learnings/                # Captured learnings

your-project/.claude/         # Project config (after /init)
├── CLAUDE.md                 # Project instructions
├── skills/                   # Project-specific skills
└── tasks/                    # Session state
```

## Quick Tips

1. **Start sessions with context**
   ```
   I'm working on [feature/bug]. The codebase uses [tech stack].
   ```

2. **Use `/plan` before complex work**
   - Creates structured approach
   - Tracks progress automatically

3. **Let skills activate naturally**
   - Just describe what you want to do
   - Jarvis suggests relevant skills

4. **Check `/status` regularly**
   - Shows session progress
   - Indicates context usage

## Troubleshooting

### Skills not activating?

Check skill-rules.json exists:
```bash
ls ~/.claude/skill-rules.json
```

### Hooks not running?

Verify hooks configuration:
```bash
cat ~/.claude/hooks.json
```

### Need to reinstall?

```bash
./uninstall.sh  # Remove current installation
./install.sh    # Fresh install
```

## Next Steps

- Read [Full Documentation](../README.md) for detailed features
- Explore [Skills Reference](02-skills.md) for all available skills
- Learn about [Agents](04-agents.md) for specialized tasks
- Configure [Hooks](06-hooks.md) for automation

## Getting Help

- `/help` - Built-in help
- GitHub Issues - Report problems
- README.md - Full documentation

---

**Version**: 1.0.0 | [Changelog](../../CHANGELOG.md)
