# Skills

Knowledge and process skills that enhance Claude's capabilities.

## Structure

```
skills/
├── meta/               # Meta-skills (skills about skills)
│   ├── using-skills.md # How to discover and use skills
│   └── writing-*.md    # How to write various components
├── process/            # Development process skills
│   ├── tdd.md          # Test-driven development
│   ├── verification.md # Verification checkpoints
│   └── debugging.md    # Debugging methodology
└── domain/             # Domain-specific skills
    ├── git.md          # Git workflow patterns
    └── patterns.md     # Design patterns library
```

## Skill Categories

### Meta Skills (`meta/`)
Skills about skills - how to use, discover, and write skills and other components.

### Process Skills (`process/`)
Development methodology skills - TDD, verification, debugging, refactoring.

### Domain Skills (`domain/`)
Domain-specific knowledge - git, patterns, frameworks, languages.

## Skill Format

Each skill is defined in a markdown file with:

1. **Frontmatter** - Skill metadata
2. **Description** - What the skill provides
3. **When to Use** - Trigger conditions
4. **Instructions** - How to apply the skill
5. **Examples** - Usage examples
6. **Checklist** - Verification steps

## Skill Activation

Skills are activated via `skill-rules.json` which maps:
- Keywords to skills
- Intents to skills
- Priority levels (critical, high, medium, low)

See `meta/using-skills` for the complete activation system.
