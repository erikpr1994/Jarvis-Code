---
name: issues
description: View and manage project issues from GitHub/GitLab/Jira
disable-model-invocation: false
---

# /issues - Manage Project Issues

View, create, and manage issues from your project's issue tracker.

## What It Does

1. **Lists issues** - Shows open issues from connected tracker
2. **Filters & searches** - Find specific issues
3. **Creates issues** - Add new issues with proper formatting
4. **Updates status** - Change issue state and assignees

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Filter, issue number, or action | "open", "#123", "create" |

## Process

### Phase 1: Detection

1. **Identify issue tracker**
   - Check for GitHub remote
   - Check for GitLab remote
   - Check for Jira configuration
   - Check for Linear configuration

2. **Get authentication**
   - Use `gh` CLI for GitHub
   - Use configured tokens for others

### Phase 2: Fetch Issues

3. **Retrieve issues**

For GitHub:
```bash
gh issue list --state open
```

For GitLab:
```bash
glab issue list --state opened
```

### Phase 3: Display

4. **Show issues summary**

```markdown
## Open Issues (23)

### High Priority (3)
| # | Title | Labels | Assignee | Age |
|---|-------|--------|----------|-----|
| #45 | Fix auth token refresh | bug, critical | @alice | 2d |
| #42 | Database connection timeout | bug | @bob | 5d |
| #38 | API rate limiting needed | feature | - | 1w |

### Medium Priority (8)
| # | Title | Labels | Assignee | Age |
|---|-------|--------|----------|-----|
| #44 | Add dark mode support | feature | @charlie | 1d |
| #41 | Improve error messages | enhancement | - | 3d |
...

### Recently Updated
- #45 Fix auth token refresh (updated 2h ago)
- #44 Add dark mode support (updated 5h ago)
- #42 Database connection timeout (updated 1d ago)

### My Issues
- #44 Add dark mode support
- #39 Refactor user service
```

## Usage Modes

### View all open issues
```
/issues
/issues open
```

### View closed issues
```
/issues closed
```

### View specific issue
```
/issues #45
/issues 45
```

### Filter by label
```
/issues bug
/issues --label feature
```

### Filter by assignee
```
/issues --mine
/issues --assignee alice
```

### Search issues
```
/issues search "authentication"
```

### Create new issue
```
/issues create
```
Opens interactive issue creation.

```
/issues create "Fix login button" --label bug
```
Creates issue with title and label.

### Update issue
```
/issues close 45
/issues assign 45 @alice
/issues label 45 bug
```

## Interactive Issue Creation

When using `/issues create`:

```markdown
## Create New Issue

**Title:** Fix authentication token refresh

**Description:**
The authentication token is not being refreshed properly when it expires.

**Steps to reproduce:**
1. Log in to the application
2. Wait for token to expire (1 hour)
3. Try to make an API call
4. Observe 401 error

**Expected:** Token should auto-refresh
**Actual:** User is logged out

**Labels:** bug, auth
**Assignee:** (optional)
**Milestone:** v2.0

---
Create this issue? [y/n]
```

## Examples

**View open issues:**
```
/issues
```

**View my assigned issues:**
```
/issues --mine
```

**View specific issue:**
```
/issues #45
```

**Search for issues:**
```
/issues search "performance"
```

**View bugs only:**
```
/issues --label bug
```

**Create new issue:**
```
/issues create "Add user avatar upload"
```

**Close an issue:**
```
/issues close 45 --comment "Fixed in #abc123"
```

**Add comment:**
```
/issues comment 45 "Working on this now"
```

## Issue Actions

| Action | Command | Description |
|--------|---------|-------------|
| List | `/issues` | Show open issues |
| View | `/issues #N` | Show issue details |
| Create | `/issues create` | Create new issue |
| Close | `/issues close N` | Close issue |
| Reopen | `/issues reopen N` | Reopen issue |
| Assign | `/issues assign N @user` | Assign to user |
| Label | `/issues label N label` | Add label |
| Comment | `/issues comment N "text"` | Add comment |

## Supported Platforms

| Platform | CLI Tool | Detection |
|----------|----------|-----------|
| GitHub | `gh` | `.git/config` remote |
| GitLab | `glab` | `.git/config` remote |
| Jira | `jira-cli` | `.jira.d/` config |
| Linear | `linear` | `.linear/` config |

## Output Formats

### Default (table)
```
/issues
```

### Detailed
```
/issues --verbose
```

### JSON
```
/issues --json
```

### Markdown
```
/issues --md
```

## Configuration

Configure in `settings.json`:

```json
{
  "issues": {
    "default_labels": ["needs-triage"],
    "auto_assign": true,
    "show_closed_days": 7
  }
}
```
