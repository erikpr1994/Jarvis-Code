# Jarvis Interview Questions Template

> This document defines the interview questions used during Jarvis initialization.
> Questions are grouped by category and include metadata for processing.

## Overview

The interview phase collects user preferences that cannot be auto-detected:
- Project type and goals
- Development workflow preferences
- Testing strategy
- Documentation structure

## Question Format

Each question follows this structure:

```yaml
id: unique-identifier
category: category-name
question: "Question text"
options:
  - value: option-value
    label: "Display label"
    description: "Optional description"
default: default-value
affects:
  - component: what-this-affects
    how: description-of-effect
condition: optional-condition-for-showing
```

---

## Questions

### Q1: Confirm Detection

```yaml
id: confirm-detection
category: detection
question: "We detected the following configuration. Is this correct?"
display:
  - "Tech Stack: ${detected.stack}"
  - "Project Type: ${detected.project_type}"
  - "Template: ${detected.suggested_template}"
options:
  - value: "yes"
    label: "Yes, this is correct"
  - value: "no"
    label: "No, let me adjust"
default: "yes"
affects:
  - component: detection
    how: "If no, allows manual override of detected values"
```

### Q2: Project Type

```yaml
id: project-type
category: project
question: "What type of project is this?"
options:
  - value: "saas"
    label: "SaaS Product"
    description: "User accounts, billing, dashboard, multi-tenant"
  - value: "client"
    label: "Client Project"
    description: "Defined requirements, external stakeholder, deadline-driven"
  - value: "oss"
    label: "Open Source"
    description: "Community-driven, public contributions, documentation-heavy"
  - value: "internal"
    label: "Internal Tool"
    description: "Company use, limited audience, rapid iteration"
  - value: "personal"
    label: "Personal/Learning"
    description: "Experimentation, learning, no external stakeholders"
default: "saas"
affects:
  - component: agents
    how: "Determines specialist agents (e.g., SaaS includes billing specialist)"
  - component: workflow
    how: "Affects workflow strictness (client > SaaS > personal)"
  - component: documentation
    how: "Determines documentation depth requirements"
```

### Q3: Git Workflow

```yaml
id: git-workflow
category: workflow
question: "How do you manage git branches?"
options:
  - value: "graphite"
    label: "Graphite (stacked PRs)"
    description: "Small, focused PRs that stack on each other"
    detection: "command -v gt"
  - value: "github-flow"
    label: "GitHub Flow"
    description: "Feature branches off main, PR to merge"
  - value: "gitflow"
    label: "GitFlow"
    description: "develop/release/hotfix branches structure"
  - value: "trunk"
    label: "Trunk-based"
    description: "Direct commits to main with feature flags"
default: "github-flow"
default_if:
  - condition: "graphite-cli-detected"
    value: "graphite"
affects:
  - component: skills
    how: "Activates git-expert skill with appropriate workflow"
  - component: hooks
    how: "Configures pre-commit/pre-push hooks for workflow"
  - component: commands
    how: "Customizes /commit and /pr commands"
```

### Q4: Code Review Integration

```yaml
id: code-review
category: workflow
question: "What code review tools do you use?"
options:
  - value: "coderabbit"
    label: "CodeRabbit"
    description: "AI-powered automated review"
  - value: "github"
    label: "GitHub Reviews only"
    description: "Manual review through GitHub PRs"
  - value: "both"
    label: "CodeRabbit + GitHub"
    description: "AI review followed by human review"
  - value: "none"
    label: "None"
    description: "Solo project, no formal review"
default: "github"
affects:
  - component: skills
    how: "Activates coderabbit skill if using CodeRabbit"
  - component: hooks
    how: "Adds coderabbit-review hook"
  - component: agents
    how: "Configures review agent priorities"
```

### Q5: TDD Strictness

```yaml
id: tdd-strictness
category: testing
question: "How strict should TDD enforcement be?"
options:
  - value: "iron-law"
    label: "Iron Law"
    description: "No exceptions - write tests first ALWAYS"
    rules:
      - "NEVER write implementation without tests first"
      - "Coverage must not decrease"
      - "All PRs blocked until tests pass"
  - value: "strong"
    label: "Strong"
    description: "Tests required, but can explore first"
    rules:
      - "Tests required before commit"
      - "Exploratory code allowed during development"
      - "Coverage should improve"
  - value: "flexible"
    label: "Flexible"
    description: "Tests encouraged but not required"
    rules:
      - "Tests for critical paths"
      - "No coverage enforcement"
      - "Documentation can substitute for simple utilities"
default: "strong"
affects:
  - component: skills
    how: "Configures test-driven-development skill strictness"
  - component: hooks
    how: "Sets up verification gates"
  - component: rules
    how: "Generates TDD rules in CLAUDE.md"
```

### Q6: Test Types

```yaml
id: test-types
category: testing
question: "Which test types should be enforced?"
multiple: true
options:
  - value: "unit"
    label: "Unit tests"
    description: "Isolated function/component tests"
  - value: "integration"
    label: "Integration tests"
    description: "API, database, service integration"
  - value: "e2e"
    label: "E2E tests"
    description: "Full user flow testing (Playwright/Cypress)"
  - value: "visual"
    label: "Visual regression"
    description: "Screenshot comparison tests"
  - value: "performance"
    label: "Performance tests"
    description: "Load testing, benchmarks"
default: ["unit", "integration"]
affects:
  - component: verification
    how: "Determines which tests run in verification pipeline"
  - component: agents
    how: "Activates appropriate testing specialists"
```

### Q7: Documentation Structure

```yaml
id: docs-structure
category: documentation
question: "How should project documentation be organized?"
options:
  - value: "full"
    label: "Full Lifecycle"
    description: "specs/ -> plans/ -> design/ -> decisions/"
    creates:
      - "docs/specs/"
      - "docs/plans/"
      - "docs/design/"
      - "docs/decisions/"
      - "docs/api/"
  - value: "simple"
    label: "Simple"
    description: "Just README and docs folder"
    creates:
      - "docs/"
  - value: "minimal"
    label: "Minimal"
    description: "README only"
    creates: []
default: "simple"
affects:
  - component: folders
    how: "Creates documentation folder structure"
  - component: skills
    how: "Activates spec-writing and planning skills"
  - component: commands
    how: "Adds /spec and /plan commands for full lifecycle"
```

### Q8: AI Assistance Level (Optional)

```yaml
id: ai-assistance
category: preferences
question: "How much AI assistance do you prefer?"
options:
  - value: "proactive"
    label: "Proactive"
    description: "AI suggests improvements, catches issues, offers alternatives"
  - value: "responsive"
    label: "Responsive"
    description: "AI responds to requests, minimal unsolicited suggestions"
  - value: "minimal"
    label: "Minimal"
    description: "AI only does exactly what's asked"
default: "proactive"
condition: "advanced-mode"
affects:
  - component: agents
    how: "Configures agent verbosity and proactivity"
  - component: hooks
    how: "Enables/disables suggestion hooks"
```

---

## Conditional Questions

These questions only appear based on previous answers or detection results.

### Q-COND-1: Monorepo Structure

```yaml
id: monorepo-structure
category: architecture
question: "How is your monorepo organized?"
condition: "detected.project_type == 'monorepo'"
options:
  - value: "apps-packages"
    label: "apps/ + packages/"
    description: "Applications in apps/, shared code in packages/"
  - value: "packages-only"
    label: "packages/ only"
    description: "All workspaces in packages/"
  - value: "custom"
    label: "Custom structure"
    description: "Non-standard organization"
default: "apps-packages"
affects:
  - component: templates
    how: "Generates CLAUDE.md for each workspace"
  - component: rules
    how: "Sets up cross-package import rules"
```

### Q-COND-2: Database ORM

```yaml
id: database-orm
category: stack
question: "Which database ORM/client do you prefer?"
condition: "detected.stack.includes('supabase') || detected.stack.includes('prisma') || detected.stack.includes('drizzle')"
options:
  - value: "prisma"
    label: "Prisma"
    description: "Type-safe ORM with migrations"
  - value: "drizzle"
    label: "Drizzle"
    description: "Lightweight TypeScript ORM"
  - value: "supabase-js"
    label: "Supabase JS Client"
    description: "Direct Supabase client usage"
  - value: "raw"
    label: "Raw SQL"
    description: "Direct SQL queries"
default: "detected-value"
affects:
  - component: skills
    how: "Activates database-specific skills"
  - component: rules
    how: "Sets up query patterns and migration rules"
```

---

## Output Format

After completing the interview, generate a JSON configuration:

```json
{
  "project": {
    "name": "project-name",
    "type": "saas|client|oss|internal|personal",
    "template": "detected-or-selected-template"
  },
  "workflow": {
    "git": "graphite|github-flow|gitflow|trunk",
    "review": "coderabbit|github|both|none",
    "tdd": "iron-law|strong|flexible",
    "test_types": ["unit", "integration", "e2e"]
  },
  "documentation": {
    "level": "full|simple|minimal"
  },
  "preferences": {
    "ai_assistance": "proactive|responsive|minimal"
  },
  "detection": {
    "stack": ["typescript", "next.js", "supabase"],
    "frameworks": {},
    "tools": {},
    "confirmed": true
  }
}
```

---

## Usage in Claude

When running `/init`, present questions conversationally:

```markdown
Let me help you set up Jarvis for this project.

I detected:
- **Tech Stack**: TypeScript, Next.js, Supabase, Tailwind
- **Project Type**: Next.js application
- **Suggested Template**: web-fullstack

Is this detection correct? [Y/n]

Great! A few more questions to customize your setup:

**What type of project is this?**
1. SaaS Product (user accounts, billing)
2. Client Project (external stakeholder)
3. Open Source (community contributions)
4. Internal Tool (company use)
5. Personal/Learning

Select [1-5]:
```

This conversational approach makes the interview feel natural while collecting all necessary configuration data.
