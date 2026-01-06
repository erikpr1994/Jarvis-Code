# {{APP_NAME}} - Application

> Inherits from: project root CLAUDE.md > apps/CLAUDE.md
> Level: L2 (apps/{{APP_NAME}})
> Token budget: ~500 tokens

## Purpose

{{APP_DESCRIPTION}}

## Tech Stack

```yaml
framework: {{FRAMEWORK}}
styling: {{STYLING}}
state: {{STATE_MANAGEMENT}}
testing: {{TEST_FRAMEWORK}}
```

## Project Structure

```
{{APP_NAME}}/
├── {{SOURCE_DIR}}/
{{FOLDER_STRUCTURE}}
├── public/              # Static assets
├── {{CONFIG_FILES}}
└── package.json
```

## Key Patterns

### Routing

{{ROUTING_PATTERNS}}

### Data Fetching

{{DATA_FETCHING_PATTERNS}}

### State Management

{{STATE_PATTERNS}}

## Dependencies

### Internal Packages Used

{{INTERNAL_DEPS}}

### Key External Dependencies

{{EXTERNAL_DEPS}}

## Environment Variables

```bash
# Required
{{REQUIRED_ENV_VARS}}

# Optional
{{OPTIONAL_ENV_VARS}}
```

## Testing

```bash
# Unit tests
{{UNIT_TEST_CMD}}

# E2E tests
{{E2E_TEST_CMD}}

# All tests
{{ALL_TEST_CMD}}
```

## Common Commands

```bash
# Development
{{DEV_CMD}}

# Build
{{BUILD_CMD}}

# Start production
{{START_CMD}}

# Lint
{{LINT_CMD}}

# Type check
{{TYPECHECK_CMD}}
```

## Deployment

{{DEPLOYMENT_INFO}}

## DO NOT

- Import from other apps (use shared packages)
- Duplicate code that should be in shared packages
- Commit environment secrets
- Skip testing before pushing changes
- Modify shared package code directly from here

## Feature Boundaries

| Feature | Location |
|---------|----------|
{{FEATURE_LOCATIONS}}
