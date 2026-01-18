# Repository Guidelines

## Project Structure & Module Organization
- `global/` holds the versioned Jarvis payload (agents, commands, hooks, rules, patterns, skills, lib) that gets synced into `~/.claude`.
- `init/` contains initialization templates and setup docs for project bootstrapping.
- `scripts/` provides maintenance utilities like updates, changelog generation, and git hook setup.
- `tests/` includes the Bash-based Jarvis test framework (`tests/jarvis/`).
- `docs/` contains the Jarvis specification and architecture documentation.
- `templates/` houses reusable config templates; `archive/` stores legacy material.

## Build, Test, and Development Commands
- `./install.sh` installs Jarvis globally and configures hooks/preferences.
- `./scripts/update.sh` syncs the repo’s `global/` content into `~/.claude`.
- `./scripts/setup-git-hooks.sh` installs local git hooks (e.g., commit-msg validation).
- `./tests/jarvis/test-jarvis.sh` runs the Jarvis test suite; pass `skills`, `hooks`, or `--changed` for targeted runs.

## Coding Style & Naming Conventions
- Bash scripts use `#!/usr/bin/env bash`, `set -euo pipefail`, and readable 4-space indentation (see `scripts/`).
- Keep file names descriptive and kebab-cased for skills/hooks/tests (e.g., `test-<skill-name>.sh`).
- Markdown docs should use clear headings and short, task-focused sections.

## Testing Guidelines
- Tests live in `tests/jarvis/` and are Bash-based with shared helpers in `tests/jarvis/lib/`.
- Naming: `tests/jarvis/skills/test-<skill>.sh`, `tests/jarvis/hooks/test-<hook>.sh`, scenarios under `tests/jarvis/scenarios/<skill-name>/`.
- Run focused tests with `./tests/jarvis/test-jarvis.sh skill:<name>` or `hook:<name>`.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits (e.g., `feat(skills): add linear integration`). This is enforced by `scripts/commit-msg`.
- Include clear PR descriptions, link relevant issues, and note test coverage (e.g., `./tests/jarvis/test-jarvis.sh --changed`).
- If you modify hooks/skills/agents, update or add tests and documentation in `docs/` or `README.md` as needed.

## Codex Integration
- Codex reads `AGENTS.md` in the repo and discovers skills in `.codex/skills/`.
- Sync Jarvis skills into Codex with `./scripts/codex-sync.sh --scope repo --mode copy` (or `--scope user --mode copy`).
- Install the Codex rules template with `./scripts/codex-install-rules.sh` to add guardrails for git pushes/commits.
- Jarvis agents/commands are reference material for Codex; use them through skills or link to `global/agents` and `global/commands` in your guidance.

## Security & Configuration Notes
- Hooks and rules can block destructive operations; respect safety safeguards unless explicitly bypassing for maintenance.
- `global/` is the source of truth for what gets installed into `~/.claude`; keep changes there deliberate and well-tested.
