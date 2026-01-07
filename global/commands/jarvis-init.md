---
name: jarvis-init
description: Initialize Jarvis in a new project - sets up CLAUDE.md, skills, agents, and project configuration
disable-model-invocation: false
---

# /jarvis-init - Project Initialization

> **Note:** Use `/init` for Claude Code's built-in CLAUDE.md generator.

Initialize Jarvis AI assistant in your project with intelligent configuration based on your codebase.

## What It Does

1. **Analyzes your project** - Detects framework, language, and existing patterns
2. **Creates CLAUDE.md** - Project-specific instructions tailored to your codebase
3. **Sets up .claude folder** - Skills, agents, commands, and hooks structure
4. **Configures integrations** - Git hooks, linting rules, and CI/CD awareness
5. **Captures learnings** - Seeds the learning system with initial project context

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `$ARGUMENTS` | Project type hint (e.g., "nextjs", "python", "rust") | Auto-detect |

## Process

### Phase 1: Project Analysis

**Use the native Explore subagent** for efficient codebase analysis:

```
Task(subagent_type='Explore', thoroughness='medium', prompt='
  Analyze this project to determine:
  1. Project type (package.json, Cargo.toml, pyproject.toml, go.mod)
  2. Framework (Next.js, React, FastAPI, etc.)
  3. Testing framework (Vitest, Jest, pytest, etc.)
  4. Directory structure and conventions
  5. Monorepo vs single project
  6. Existing .claude/ configuration
')
```

1. **Detect project type and framework**
   - Scan for package.json, Cargo.toml, pyproject.toml, go.mod, etc.
   - Identify primary language and framework
   - Detect testing framework in use
   - Find existing linting/formatting configuration

2. **Analyze codebase structure**
   - Map directory structure and conventions
   - Identify source, test, and config directories
   - Detect monorepo vs single project
   - Find existing documentation

3. **Extract existing patterns**
   - Naming conventions (files, functions, components)
   - Import patterns and module organization
   - Error handling approaches
   - Testing patterns in use

### Phase 2: Configuration Generation

4. **Generate CLAUDE.md**
   - Project overview and purpose
   - Technology stack and key dependencies
   - Coding conventions extracted from codebase
   - Build, test, and deployment commands
   - Important files and directories

5. **Create .claude structure**
   ```
   .claude/
   ├── commands/       # Project-specific commands
   ├── skills/         # Reusable workflow skills
   ├── agents/         # Specialized agent definitions
   ├── hooks/          # Event-triggered automations
   ├── context/        # Rules, examples, and patterns
   └── tasks/          # Session and task management
   ```

6. **Install relevant skills**
   - Select skills based on detected tech stack
   - Configure skill activation triggers
   - Set up skill-rules.json

### Phase 3: User Preferences

7. **Ask for rule preferences using AskUserQuestion tool**

   Present configuration options to the user:

   **Question 1: TDD Requirement**
   - Header: "TDD"
   - Question: "Should Claude follow strict Test-Driven Development?"
   - Options:
     - "No - TDD optional (Recommended)" - Testing encouraged but not enforced
     - "Yes - Require TDD" - Must write failing tests before implementation

   **Question 2: Worktree Isolation**
   - Header: "Isolation"
   - Question: "Require branch isolation before editing on main?"
   - Options:
     - "No - Allow main edits (Recommended)" - Edit files on any branch
     - "Yes - Block main edits" - Must create branch/worktree first

   **Question 3: Pre-commit Tests**
   - Header: "Pre-commit"
   - Question: "Require tests to pass before commits?"
   - Options:
     - "Yes - Tests required (Recommended)" - Block commits if tests fail
     - "No - Allow commits" - Commits allowed regardless

8. **Save preferences to jarvis.json**

   Create `~/.claude/config/jarvis.json` with user's choices:
   ```bash
   mkdir -p ~/.claude/config
   # Write config based on answers
   ```

### Phase 4: Integration Setup

9. **Configure Git integration**
   - Add .claude to .gitignore (if sensitive)
   - Set up commit message templates
   - Configure pre-commit awareness

10. **Set up project-specific commands**
    - Add build, test, lint commands based on detection
    - Configure deployment commands if applicable

11. **Initialize learning system**
   - Create learnings.md with initial observations
   - Set up pattern documentation

### Phase 5: Verification

12. **Validate configuration**
    - Test detected commands work
    - Verify CLAUDE.md is accurate
    - Confirm all paths are correct

13. **Present summary to user**
    - Show detected configuration
    - Highlight any manual steps needed
    - Offer to customize further

## Output

After initialization, present:

```markdown
## Jarvis Initialized

**Project**: [detected name]
**Type**: [framework/language]
**Structure**: [monorepo/single]

### Configuration Created
- CLAUDE.md with [X] sections
- [Y] skills activated
- [Z] commands configured

### Detected Patterns
- Naming: [convention]
- Testing: [framework]
- Build: [command]

### Next Steps
1. Review CLAUDE.md and adjust as needed
2. Run `/skills` to see available skills
3. Use `/plan` to start your first task
```

## Examples

**Basic initialization:**
```
/jarvis-init
```

**With framework hint:**
```
/jarvis-init nextjs
```

**For a Python project:**
```
/jarvis-init python-fastapi
```

## Notes

- Run this once per project at the root directory
- Re-running will prompt to update or overwrite existing configuration
- Use `$ARGUMENTS` to provide hints if auto-detection fails
- The initialization respects existing .claude configurations
