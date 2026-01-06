# Jarvis Verification System

Automated multi-stage verification pipeline for ensuring code quality.

## Components

### pipeline.sh

Main verification orchestrator that runs checks at configurable depth levels.

**Levels:**
- `quick` - Lint, types, formatting (default)
- `standard` - + Unit tests
- `full` - + Integration, E2E, build, agent reviews
- `release` - + Performance, security audit, bundle analysis

**Usage:**
```bash
./pipeline.sh quick
./pipeline.sh standard --fail-fast
./pipeline.sh full --path src/
./pipeline.sh release --json
```

**Options:**
- `--path PATH` - Check specific path only
- `--parallel` - Run checks in parallel where possible
- `--json` - Output results as JSON
- `--fail-fast` - Stop on first failure
- `--no-agents` - Skip agent review suggestions
- `--timeout MIN` - Timeout in minutes (default: 10)

### confidence.sh

Calculates confidence scores based on verification results.

**Usage:**
```bash
source confidence.sh
calculate_confidence "$verification_json"
```

**Score Ranges:**
- 90-100: High confidence (🟢)
- 70-89: Medium confidence (🟡)
- 50-69: Low confidence (🟠)
- 0-49: Very low confidence (🔴)

## Integration

### With /verify Command

The pipeline integrates with the `/verify` slash command:

```
/verify quick    → Runs Phase 1
/verify standard → Runs Phase 1 + 2
/verify full     → Runs Phase 1 + 2 + 3 + Agent suggestions
/verify release  → Runs all phases
```

### With Git Hooks

```bash
# .husky/pre-commit
/verify standard

# .husky/pre-push
/verify full
```

### With CI/CD

```yaml
# .github/workflows/verify.yml
- name: Run verification
  run: |
    ./global/lib/verification/pipeline.sh release --json
```

## Phases

### Phase 1: Quick Checks
- TypeScript compilation (`tsc --noEmit`)
- Linting (ESLint/Biome)
- Formatting (Prettier/Biome)

### Phase 2: Standard Checks
- Unit tests (Vitest/Jest)

### Phase 3: Full Checks
- Integration tests
- E2E tests (Playwright/Cypress)
- Build verification
- Agent review suggestions

### Phase 4: Release Checks
- Security audit (`npm audit`)
- Bundle analysis
- Performance benchmarks
- License compliance

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | Required check failed |
| 2 | Warning (optional check failed) |
| 3 | Timeout |
| 4 | Configuration error |

## Configuration

Configure in `settings.json`:

```json
{
  "verification": {
    "default_level": "standard",
    "fail_on_warnings": false,
    "parallel_agents": true,
    "timeout_minutes": 10,
    "required_agents": ["code-reviewer", "spec-reviewer"],
    "optional_agents": ["security-reviewer", "accessibility-auditor"]
  }
}
```
