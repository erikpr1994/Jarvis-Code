# Scripts Directory

> Inherits from: project root CLAUDE.md
> Level: L1 (scripts/)
> Token budget: ~350 tokens

## Purpose

Automation scripts for development, deployment, maintenance, and operational tasks.

## Organization

```
scripts/
├── dev/                     # Development helpers
│   ├── setup.sh             # Initial project setup
│   ├── seed-db.sh           # Database seeding
│   └── reset-db.sh          # Database reset
├── deploy/                  # Deployment scripts
│   ├── build.sh             # Build for production
│   ├── deploy-staging.sh    # Deploy to staging
│   └── deploy-prod.sh       # Deploy to production
├── ci/                      # CI/CD scripts
│   ├── test.sh              # Run test suite
│   ├── lint.sh              # Run linters
│   └── typecheck.sh         # Run type checking
├── migrations/              # Database migration helpers
│   ├── generate.sh          # Generate new migration
│   └── run.sh               # Run pending migrations
└── utils/                   # Utility scripts
    ├── backup-db.sh         # Database backup
    └── clean.sh             # Clean build artifacts
```

## Script Template

```bash
#!/usr/bin/env bash

# ==============================================================================
# Script: {{script-name}}.sh
# Description: Brief description of what this script does
# Usage: ./scripts/{{script-name}}.sh [options]
# ==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check prerequisites
check_requirements() {
  command -v node >/dev/null 2>&1 || { log_error "Node.js is required"; exit 1; }
}

# Main function
main() {
  check_requirements
  log_info "Starting {{task}}..."

  # Script logic here

  log_info "{{Task}} completed successfully"
}

# Run main
main "$@"
```

## Naming Conventions

| Pattern | Purpose |
|---------|---------|
| `setup-*.sh` | Initial setup scripts |
| `run-*.sh` | Execution scripts |
| `deploy-*.sh` | Deployment scripts |
| `test-*.sh` | Testing scripts |
| `clean-*.sh` | Cleanup scripts |
| `generate-*.sh` | Code generation |

## Key Patterns

### Environment Loading

```bash
# Load environment variables
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  set -a
  source "$PROJECT_ROOT/.env"
  set +a
fi

# Require specific env vars
: "${DATABASE_URL:?DATABASE_URL is required}"
: "${API_KEY:?API_KEY is required}"
```

### Argument Parsing

```bash
# Simple args
ENV="${1:-development}"

# With flags
while getopts "e:v" opt; do
  case $opt in
    e) ENV="$OPTARG" ;;
    v) VERBOSE=true ;;
    *) echo "Usage: $0 [-e environment] [-v]" && exit 1 ;;
  esac
done
```

### Confirmation Prompts

```bash
confirm() {
  read -p "Are you sure you want to $1? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Aborted"
    exit 0
  fi
}

# Usage
confirm "reset the database"
```

### Error Handling

```bash
# Cleanup on exit
cleanup() {
  log_info "Cleaning up..."
  # Remove temp files, stop services, etc.
}
trap cleanup EXIT

# Retry logic
retry() {
  local max_attempts=3
  local attempt=1
  until "$@"; do
    if [[ $attempt -ge $max_attempts ]]; then
      log_error "Failed after $max_attempts attempts"
      return 1
    fi
    log_warn "Attempt $attempt failed, retrying..."
    ((attempt++))
    sleep 2
  done
}
```

## Execution

```bash
# Make script executable
chmod +x scripts/my-script.sh

# Run script
./scripts/my-script.sh

# Run with arguments
./scripts/deploy.sh -e staging
```

## DO NOT

- Store secrets in scripts (use environment variables)
- Use absolute paths (use relative from script location)
- Skip error handling (`set -euo pipefail`)
- Forget shebang line (`#!/usr/bin/env bash`)
- Mix bash and sh syntax
- Assume tools are installed (check first)
- Run destructive commands without confirmation
- Hardcode environment-specific values

## Common Tasks

| Task | Script |
|------|--------|
| Project setup | `./scripts/dev/setup.sh` |
| Run tests | `./scripts/ci/test.sh` |
| Deploy | `./scripts/deploy/deploy-{{env}}.sh` |
| Generate migration | `./scripts/migrations/generate.sh {{name}}` |
| Database reset | `./scripts/dev/reset-db.sh` |
