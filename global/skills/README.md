# Jarvis Skills

Skills are Claude Code's native way to provide contextual guidance. Each skill lives in its own folder with a `SKILL.md` file.

## Structure

```
skills/
├── skill-name/
│   ├── SKILL.md           # Required - main skill file
│   ├── examples.md        # Optional - detailed examples
│   ├── reference.md       # Optional - reference material
│   └── scripts/           # Optional - utility scripts
│       └── helper.sh
```

## SKILL.md Format

Only `name` and `description` are required in frontmatter:

```yaml
---
name: skill-name
description: When to use this skill. Keywords help Claude match it to user requests.
---

# Skill Title

Instructions and guidance...
```

## How Skills Work

1. **Discovery**: Claude loads skill names and descriptions at session start
2. **Matching**: Claude matches your request against skill descriptions
3. **Activation**: Claude asks permission to use a matching skill
4. **Execution**: Claude follows the SKILL.md instructions

## Skill Categories

| Category | Skills | Purpose |
|----------|--------|---------|
| Process | tdd-workflow, verification, code-review | How to approach work |
| Domain | typescript-patterns, react-patterns | Technology expertise |
| Meta | writing-skills, using-skills | About the skill system |
| Execution | dispatching-parallel-agents | Multi-agent orchestration |

## Adding a Skill

```bash
# Create skill folder
mkdir skills/my-skill

# Create SKILL.md
cat > skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: Use when doing X. Keywords: x, y, z.
---

# My Skill

Instructions here...
EOF
```

## skill-rules.json

The `skill-rules.json` file provides enhanced activation rules beyond the native system:

- `enforcement`: suggest | always | block
- `priority`: critical | high | medium | low
- `promptTriggers`: keyword and intent pattern matching

This is a Jarvis extension - the native system only uses `name` and `description`.

## Current Skills (46)

### Process Skills
- `brainstorm` - Structured ideation
- `code-review` - Code review process
- `commit-discipline` - Git commit practices
- `execute` - Plan execution
- `git-worktrees` - Git worktree workflow
- `linear` - Plan and track features via Linear issues
- `pr-workflow` - Pull request workflow
- `session` - Session tracking
- `debug` - Debug methodology
- `tdd` / `tdd-workflow` - Test-driven development
- `verification` - Quality verification
- `plan` - Plan creation (markdown-based)

### Domain Skills
- `analytics` - Analytics implementation
- `api-design` - API design patterns
- `browser-debugging` - Browser debugging
- `coderabbit` - CodeRabbit integration
- `database-patterns` - Database patterns
- `frontend-design` - Frontend design
- `git-expert` - Git expertise
- `mcp-integration` - MCP server integration
- `nextjs-patterns` - Next.js patterns
- `payment-processing` - Payment integration
- `react-patterns` - React patterns
- `seo-content-generation` - SEO content
- `supabase-patterns` - Supabase patterns
- `submit-pr` - PR submission
- `testing-patterns` - Testing patterns
- `typescript-patterns` - TypeScript patterns

### Meta Skills
- `improving-jarvis` - Improving Jarvis
- `using-skills` - How to use skills
- `writing-agents` - Creating agents
- `writing-claude-md` - Writing CLAUDE.md
- `writing-commands` - Creating commands
- `writing-hooks` - Creating hooks
- `writing-patterns` - Creating patterns
- `writing-rules` - Creating rules
- `writing-skills` - Creating skills

### Execution Skills
- `dispatching-parallel-agents` - Parallel agent dispatch
- `subagent-driven-development` - Subagent development
