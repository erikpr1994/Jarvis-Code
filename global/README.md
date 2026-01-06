# Jarvis Global Configuration

This directory serves as a template for `~/.claude/` - the global configuration directory shared across all projects.

## Directory Structure

```
global/
├── settings.json           # Global settings (merged with project settings)
├── agents/                  # Shared agents
│   └── core/               # Core agents (always available)
├── skills/                  # Shared skills
│   ├── meta/               # Meta-skills (using-skills, writing-*)
│   ├── process/            # Process skills (TDD, verification, debugging)
│   └── domain/             # Domain skills (git, patterns)
├── commands/               # Shared slash commands
├── hooks/                   # Shared hooks
│   └── lib/                # Hook utilities
├── patterns/               # Pattern library (indexed)
│   ├── index.json          # Pattern index with summaries
│   └── full/               # Full pattern files
├── rules/                   # Global rules
└── lib/                     # Shared utilities
    └── skills-core.js      # Skill discovery library
```

## Component Descriptions

### agents/
Reusable agent configurations that can be invoked across projects.
- `core/` - Essential agents always loaded (orchestrator, reviewer, etc.)

### skills/
Knowledge and process skills that enhance Claude's capabilities.
- `meta/` - Skills about skills (how to use/write skills)
- `process/` - Development process skills (TDD, debugging, verification)
- `domain/` - Domain-specific skills (git workflows, design patterns)

### commands/
Custom slash commands available in all projects.
Format: `command-name.md` files with command definitions.

### hooks/
Event-driven automations triggered by Claude actions.
- `lib/` - Shared utilities for hook scripts
- Hook types: session-start, pre-tool-use, post-tool-use, etc.

### patterns/
Indexed library of reusable patterns.
- `index.json` - Quick lookup with summaries
- `full/` - Complete pattern documentation

### rules/
Global behavior rules applied across all projects.
Format: `rule-name.md` files with rule definitions.

### lib/
Shared JavaScript/TypeScript utilities.
- `skills-core.js` - Skill discovery and loading library

## Configuration Layering

Priority (highest to lowest):
1. Project `.claude/settings.json`
2. Global `~/.claude/settings.json`
3. Built-in defaults

Merge Strategy:
- Arrays: concatenate (project + global)
- Objects: deep merge (project overrides global)
- Primitives: project wins

## Installation

Copy this directory to your home folder:
```bash
cp -r global/ ~/.claude/
```

Or create a symlink for development:
```bash
ln -s /path/to/jarvis/global ~/.claude
```

## Key Files

- `settings.json` - Global configuration
- `skill-rules.json` - Skill activation rules and triggers
- `patterns/index.json` - Pattern library index
