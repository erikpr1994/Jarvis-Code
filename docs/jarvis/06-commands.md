# Command System

> Part of the [Jarvis Specification](./README.md)

## 7. Command System

### 7.1 Core Commands

| Command | Purpose | Delegates To |
|---------|---------|--------------|
| **/plan** | Create implementation plan | writing-plans skill |
| **/execute** | Execute plan with verification | executing-plans skill |
| **/brainstorm** | Ideation and options | brainstorming skill |
| **/review** | Trigger code review | submit-pr skill |
| **/debug** | Systematic debugging | systematic-debugging skill |

### 7.2 Scaffold Commands

| Command | Purpose |
|---------|---------|
| **/add-feature** | Scaffold new feature structure |
| **/add-component** | Create component with tests |
| **/add-page** | Create page with layout |
| **/add-test** | Add test files |
| **/add-migration** | Create database migration |

### 7.3 Project Management Commands

| Command | Purpose |
|---------|---------|
| **/inbox** | Manage inbox items (ideas, bugs, notes) |
| **/learnings** | Capture project learnings |
| **/skills** | List available skills |
| **/issues** | GitHub issue management |

### 7.4 Command Design Pattern

```markdown
---
name: command-name
description: What this command does
disable-model-invocation: false  # true if command handles everything
---

# Command Name

[Brief description]

## Process

1. Ask clarifying questions
2. Load relevant skill
3. Execute workflow
4. Report results
```
