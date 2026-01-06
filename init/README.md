# Jarvis Initialization System

The initialization system sets up Jarvis in a project directory by auto-detecting the tech stack, running an optional interview, and generating the appropriate configuration files.

## Overview

```
jarvis/init/
├── init.sh       # Main initialization orchestrator
├── detect.sh     # Project type and stack detection
├── interview.md  # Interview questions template
└── README.md     # This documentation
```

## Quick Start

```bash
# Navigate to your project
cd /path/to/your/project

# Run initialization (interactive)
/path/to/jarvis/init/init.sh

# Or with a specific template (skip interview)
/path/to/jarvis/init/init.sh --template web-fullstack
```

## Scripts

### init.sh

The main orchestrator that runs the five-phase initialization process:

1. **Auto-Detection Phase**: Scans project for tech stack, frameworks, and tools
2. **Interview Phase**: Collects user preferences (can be skipped with `--template`)
3. **Template Selection Phase**: Chooses appropriate template based on detection + answers
4. **Generation Phase**: Creates `.claude/` directory and configuration files
5. **Validation Phase**: Verifies all components installed correctly

#### Usage

```bash
# Full interactive initialization
./init.sh

# Quick init with specific template
./init.sh --template web-fullstack

# Re-initialize preserving customizations
./init.sh --refresh

# Generate only CLAUDE.md (skip other files)
./init.sh --claude-md-only

# Initialize a different directory
./init.sh --dir /path/to/project
```

#### Options

| Option | Description |
|--------|-------------|
| `--template NAME` | Use specific template, skip interview |
| `--refresh` | Re-initialize while preserving customizations |
| `--claude-md-only` | Only generate/regenerate CLAUDE.md |
| `--dir PATH` | Target directory (default: current) |
| `-h, --help` | Show help message |

#### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Detection failed |
| 4 | Template not found |
| 5 | Permission denied |

### detect.sh

Standalone detection script that can be sourced or run directly.

#### Usage

```bash
# Run detection and output JSON
./detect.sh /path/to/project

# Source and use function
source detect.sh
result=$(detect_project /path/to/project)
```

#### Output Format

```json
{
  "project_type": "next-app",
  "stack": ["typescript", "next.js", "react", "tailwind", "supabase"],
  "frameworks": {
    "testing": "vitest",
    "e2e": "playwright",
    "ui": "shadcn",
    "state": "zustand"
  },
  "tools": {
    "package_manager": "pnpm",
    "linting": "eslint",
    "ci": "github-actions"
  },
  "suggested_template": "web-fullstack",
  "has_existing_claude": false
}
```

#### Detection Capabilities

**Project Types:**
- `next-app` - Next.js application
- `react-app` - Standalone React app
- `flutter-app` - Flutter mobile app
- `ios-app` - iOS/Swift application
- `python-package` - Python package/application
- `rust-package` - Rust crate
- `go-module` - Go module
- `node-api` - Node.js API server
- `monorepo` - Multi-package repository
- `library` - Standalone library
- `standalone` - Default/unknown

**Tech Stack Detection:**
- Languages: TypeScript, Python, Dart, Rust, Go, Swift
- Frontend: Next.js, React, Vue, Svelte
- CSS: Tailwind, styled-components
- Backend: Express, Fastify, Hono, FastAPI, Django, Flask
- Database: Supabase, Prisma, Drizzle
- Mobile: Flutter, Firebase

**Framework Detection:**
- Testing: Vitest, Jest, Mocha, Pytest
- E2E: Playwright, Cypress
- UI: Radix, Chakra, MUI, Shadcn
- State: Zustand, Redux, Jotai
- Auth: NextAuth, Clerk
- Payments: Polar, Stripe
- Analytics: Umami, Vercel Analytics

**Tools Detection:**
- Package managers: pnpm, yarn, bun, npm
- Linting: ESLint, Biome
- Formatting: Prettier
- CI/CD: GitHub Actions, GitLab CI, CircleCI
- Monorepo: Turborepo, Nx, Lerna

### interview.md

Template document defining all interview questions. Used as reference for the interactive interview in `init.sh`.

#### Question Categories

1. **Detection Confirmation** - Verify auto-detected values
2. **Project Type** - SaaS, client, OSS, internal, personal
3. **Git Workflow** - Graphite, GitHub Flow, GitFlow, trunk-based
4. **Code Review** - CodeRabbit, GitHub, both, none
5. **TDD Strictness** - Iron law, strong, flexible
6. **Test Types** - Unit, integration, E2E, visual, performance
7. **Documentation** - Full lifecycle, simple, minimal

## Generated Files

After initialization, the following structure is created:

```
project/
├── CLAUDE.md                    # Project instructions for Claude
└── .claude/
    ├── settings.json            # Project configuration
    ├── agents/                   # Project-specific agents
    ├── skills/                   # Project-specific skills
    ├── commands/
    │   └── init.md              # Re-initialization command
    ├── hooks/
    │   └── session-start.sh     # Session startup hook
    ├── rules/                    # Project-specific rules
    └── tasks/
        └── session-current.md   # Current session tracking
```

### settings.json

```json
{
  "project": {
    "name": "my-project",
    "type": "saas",
    "template": "web-fullstack",
    "initialized": "2026-01-04T10:00:00Z"
  },
  "stack": {
    "detected": ["typescript", "next.js", "supabase"],
    "confirmed": true
  },
  "workflow": {
    "git": "github-flow",
    "review": "github",
    "tdd": "strong",
    "test_types": ["unit", "integration"]
  },
  "agents": {
    "core": ["implementer", "code-reviewer"],
    "domain": ["frontend-specialist"],
    "review": []
  },
  "skills": {
    "always": ["test-driven-development", "verification-before-completion", "git-expert"],
    "domain": ["frontend-design"]
  },
  "hooks": {
    "active": ["session-start", "skill-activation-prompt"],
    "disabled": []
  }
}
```

## Templates

Available templates are stored in `jarvis/templates/project-types/`:

| Template | Description | Stack |
|----------|-------------|-------|
| `web-fullstack` | Full-stack web app | Next.js, Supabase, Tailwind |
| `web-nextjs` | Next.js app without Supabase | Next.js, Tailwind |
| `web-react` | Standalone React app | React, Vite |
| `mobile-flutter` | Cross-platform mobile | Flutter, Dart |
| `mobile-ios` | Native iOS app | Swift, iOS SDK |
| `backend-node` | Node.js API server | Express/Fastify/Hono |
| `backend-python` | Python backend | FastAPI/Django/Flask |
| `monorepo` | Multi-package repo | Turborepo/Nx |
| `library` | Reusable library | TypeScript |
| `minimal` | Basic setup | Any |

## Dependencies

The initialization system requires:

- **bash** (4.0+) - Shell interpreter
- **jq** - JSON processor (install with `brew install jq`)

## Customization

### Adding Detection Rules

Edit `detect.sh` to add new detection patterns:

```bash
# In detect_tech_stack()
if echo "$pkg_json" | jq -e '.dependencies["your-package"]' > /dev/null 2>&1; then
    stack=$(echo "$stack" | jq '. + ["your-tech"]')
fi
```

### Adding Interview Questions

Edit `interview.md` to add new questions, then update `interview_interactive()` in `init.sh` to handle them.

### Adding Templates

Create a new YAML file in `jarvis/templates/project-types/`:

```yaml
name: your-template
description: Description of template

detection:
  requires_all:
    - some-file.json
  requires_any:
    - other-file.ts

agents:
  core:
    - implementer
    - code-reviewer
  domain:
    - your-specialist

skills:
  always:
    - test-driven-development
  domain:
    - your-skill

hooks:
  - session-start

rules:
  - your-rules
```

## Troubleshooting

### Detection Not Working

1. Ensure `jq` is installed: `which jq`
2. Check file permissions: `ls -la detect.sh`
3. Run detection manually: `./detect.sh .`

### Interview Skipped Unexpectedly

Check if `.claude/settings.json` exists - the interview offers to reuse existing settings.

### Template Not Found

1. Check available templates: `ls jarvis/templates/project-types/`
2. Use `minimal` as fallback: `./init.sh --template minimal`

### Permission Denied

Make scripts executable:

```bash
chmod +x jarvis/init/*.sh
```

## Integration with Claude

After initialization, start a Claude session in the project directory. Claude will automatically read:

1. `CLAUDE.md` - Project-specific instructions
2. `.claude/settings.json` - Configuration
3. `.claude/tasks/session-current.md` - Current session context

The session-start hook runs automatically to set up the environment.
