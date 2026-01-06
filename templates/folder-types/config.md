# Config Directory

> Inherits from: parent CLAUDE.md
> Level: L2 (.github/, .husky/, config/)
> Token budget: ~300 tokens

## Purpose

Configuration files for CI/CD, git hooks, linting, and development tooling.

## Common Config Locations

```
project/
├── .github/
│   ├── workflows/           # GitHub Actions
│   │   ├── ci.yml
│   │   └── deploy.yml
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── .husky/
│   ├── pre-commit
│   └── pre-push
├── .vscode/
│   ├── settings.json
│   └── extensions.json
└── config/                  # App configuration
    ├── env.ts
    └── constants.ts
```

## GitHub Actions Patterns

### CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test
```

### Deploy Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pnpm build
      - run: pnpm deploy
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

## Git Hooks (Husky)

### Pre-commit

```bash
#!/bin/sh
# .husky/pre-commit

pnpm lint-staged
```

### Pre-push

```bash
#!/bin/sh
# .husky/pre-push

pnpm typecheck
pnpm test --run
```

### lint-staged config

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

## VSCode Settings

```json
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

## CODEOWNERS

```
# .github/CODEOWNERS

# Default owners
* @team-lead

# Specific paths
/packages/ui/ @design-team
/apps/admin/ @admin-team
/.github/ @devops-team
```

## Key Rules

### Workflow Files

- Use specific action versions (not `@latest`)
- Cache dependencies for speed
- Fail fast on critical checks
- Use secrets for sensitive values

### Git Hooks

- Keep hooks fast (< 10 seconds)
- Only run relevant checks (lint-staged)
- Allow bypass with `--no-verify` for emergencies
- Document hook purposes

### Config Files

- Comment non-obvious settings
- Use environment variables for secrets
- Version control all config
- Keep configs DRY (extend base configs)

## DO NOT

- Commit secrets (use GitHub Secrets)
- Skip CI checks on main branch
- Make hooks too slow (blocks commits)
- Use `latest` tags in Actions
- Forget to update CODEOWNERS when team changes

## Testing Config Changes

```bash
# Test workflow locally with act
act -n  # Dry run
act     # Run locally

# Test hooks
.husky/pre-commit  # Run hook directly
```
